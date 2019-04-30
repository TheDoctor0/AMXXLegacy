#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <nvault>
#include <ColorChat>
#include <fun>
#include <cstrike>

#define PLUGIN "Rozgrzewka Nozowa"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define SPAWN_TASKID 565
#define RESTART_TASKID 123
#define ACTIVE_TASKID 124
#define TIME_VOTE 999

new const gszMusic[] = "misc/rozgrzewka.mp3";
new const gszPausePlugins[][] = { "RoundSound.amxx", "ruletka4fun.amxx", "team_semiclip.amxx" };

new g_MaxPlayers;

new const giColor[3] = {0, 200, 200};

new bool:Active = false;
new bool:gbPlay[33];
new bool:Voted;

new chosen[3];

new rozgrzewka;
new SavedChoice;

new Float:fPosition[2];

new pcvarTime, pcvarTimerX, pcvarTimerY, pcvarSpawnDelay, pcvarVoteTime, pcvarFreeze;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	rozgrzewka = nvault_open("rozgrzewka");
	if(rozgrzewka == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku");
	
	register_logevent("Activate", 2, "1=Round_Start")
	register_event("DeathMsg","Death","a");
	register_event("CurWeapon","CurWeapon","be", "1=1");
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	
	pcvarTime = register_cvar("restart_time", "60");
	pcvarTimerX = register_cvar("restart_timer_pozx", "0.01");
	pcvarTimerY = register_cvar("restart_timer_pozy", "0.86");
	pcvarSpawnDelay = register_cvar("restart_spawndelay", "1.0");
	pcvarVoteTime = register_cvar("restart_votetime", "60");
	pcvarFreeze = get_cvar_pointer("mp_freezetime");
	
	g_MaxPlayers = get_maxplayers();
	
	set_task(5.0, "CheckTime", TIME_VOTE, "", 0, "b");
	
	blockBuy();
	
	LoadChoice();
}	

public plugin_precache(){
	precache_sound(gszMusic);
}

public plugin_end()
	nvault_close(rozgrzewka)
	
public CheckTime(){
	if(get_timeleft() < get_pcvar_num(pcvarVoteTime) && get_playersnum() > 1){
		ColorChat(0, RED, "[Rozgrzewka]^x01 Za^x04 10 sekund^x01 rozpocznie sie glosowanie o^x04 rozgrzewke^x01 na kolejnej mapie.");
		set_task(10.0, "start_vote");
		remove_task(TIME_VOTE);
	}
}

public start_vote()
{
	new menu = menu_create("\yCzy chcesz Rozgrzewke na kolejne mapie?", "menu_handler");
	menu_additem(menu, "\wTak", "1", 0);
	menu_additem(menu, "\wNie", "2", 0);

	new players[32], inum;
	get_players(players, inum, "ch");
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
			menu_display(players[i], menu, 0)
	}
	set_task(15.0, "finish_vote", menu);

	chosen[1] = chosen[2];

	return 1;
}

public menu_handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if (item == MENU_EXIT)
	{
		menu_cancel(id)
		return PLUGIN_HANDLED
	}

	new data[6], name[32]
	new access, callback

	menu_item_getinfo(menu, item, access, data, 5, _, _, callback)

	new key = str_to_num(data)
	get_user_name(id, name, 31)

	if(Voted){
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch (key)
	{
		case 1: ColorChat(0, RED, "[Rozgrzewka]^x04 %s^x01 zaglosowal na^x04 tak^x01.", name);
		case 2: ColorChat(0, RED, "[Rozgrzewka]^x04 %s^x01 zaglosowal na^x04 nie^x01.", name);
	}

	++chosen[key];

	menu_cancel(id);
	return PLUGIN_HANDLED;
}

public finish_vote(menu)
{
	show_menu(0, 0, "^n", 1);
	
	if(chosen[1] > chosen[2]){
		ColorChat(0, RED, "[Rozgrzewka]^x01 Wiekszosc graczy zaglosowala za rozgrzewka, wiec^x04 zostanie wlaczona^x01 na kolejnej mapie.");
		SavedChoice = 1;
		SaveChoice();
	}

	else if(chosen[2] >= chosen[1]){
		ColorChat(0, RED, "[Rozgrzewka]^x01 Za rozgrzewka zaglosowala mniejszosc graczy, wiec^x04 nie zostanie wlaczona^x01 na kolejnej mapie.");
		SavedChoice = 0;
		SaveChoice();
	}
	Voted = true;
}

public Activate(){
	if(!SavedChoice)
		return PLUGIN_CONTINUE;
		
	if(Active){
		remove_task(RESTART_TASKID);
		return PLUGIN_CONTINUE;
	}
	
	if(Voted)
		return PLUGIN_CONTINUE;
		
	server_cmd("bf4_badgepowers 0")
	SavedChoice = 0;
	Active = true;
	new iTime = get_pcvar_num(pcvarTime)+get_pcvar_num(pcvarFreeze)+1;
	
	for(new i = 1; i < 33; i++)
		gbPlay[i] = true;

	fPosition[0] = get_pcvar_float(pcvarTimerX);
	fPosition[1] = get_pcvar_float(pcvarTimerY);
	
	new param[1];
	param[0] = iTime;
	
	set_task(3.0, "CountDown", RESTART_TASKID, param, 1);
	
	for(new i = 0; i < sizeof gszPausePlugins; i++)
		pause("ac", gszPausePlugins[i]);
	
	return PLUGIN_CONTINUE;
}

public CountDown(param[1]){
	new iNow = param[0]--;
	switch(iNow){
	case 0:{
			server_cmd("sv_restartround 1");
			
			clearRespawns();
			
			for(new i=1; i<=32; i++){
				if(is_user_connected(i))
					cs_set_user_money(i, 800);
			}
			
			server_cmd("bf4_badgepowers 1");
			
			new param[1];
			param[0] = 0;
			set_task(1.0, "Activation", ACTIVE_TASKID, param, 1);
			
			for(new i = 0; i < sizeof gszPausePlugins; i++)
				unpause("ac", gszPausePlugins[i]);
		}
	case 1:{
			client_cmd(0,"speak one");
		}
	case 2:{
			client_cmd(0,"speak two");
		}
	case 3:{
			client_cmd(0,"speak three");
		}
	}
	if(iNow >= 1)
		set_task(1.0,"CountDown", RESTART_TASKID, param, 1);
	new fx = 0;
	if(iNow <= 5){
		fx = 1;
	}
	set_hudmessage(giColor[0], giColor[1], giColor[2], fPosition[0], fPosition[1], fx, 6.0, 1.0)
	show_hudmessage(0, "Czas rozgrzewki^n%2d:%02d", iNow/60, iNow%60);
}

public Activation(param[1]){
	Active = (param[0]==0) ? false:true;
}

public Death(){
	new vid = read_data(2);
	
	if(Active)
		set_task(get_pcvar_float(pcvarSpawnDelay), "respawn", SPAWN_TASKID+vid);
	return PLUGIN_CONTINUE;
}

public Spawn(id){
	if(Active && is_user_alive(id)){
		if(gbPlay[id]){
			play(id, gszMusic);
			gbPlay[id] = false;
		}
		set_task(0.1, "Usun", id);
	}
}

public CurWeapon(id){
	if(Active){
		if(read_data(2) != CSW_KNIFE)
			set_task(0.1, "Usun", id);
	}
}

public Usun(id){
	if(is_user_alive(id)){
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
	}
}

public respawn(task_id){
	ExecuteHamB(Ham_CS_RoundRespawn, task_id-SPAWN_TASKID);
}

public clearRespawns(){
	for(new i=1; i <= g_MaxPlayers; i++){
		if(task_exists(SPAWN_TASKID+i))
			remove_task(SPAWN_TASKID+i);
	}
}

public SaveChoice()
{
	new vaultkey[64], vaultdata[128];
	formatex(vaultkey, 63, "rozgrzewka");
	formatex(vaultdata, 127, "%d", SavedChoice);
	nvault_set(rozgrzewka, vaultkey, vaultdata);
	
	return PLUGIN_CONTINUE;
}  

public LoadChoice()
{
	new vaultkey[64], vaultdata[128];
	formatex(vaultkey, 63, "rozgrzewka")
	
	if(nvault_get(rozgrzewka, vaultkey, vaultdata, 127)){
		new choice[16];
		parse(vaultdata, choice, 15)
		SavedChoice = str_to_num(choice);
	}
	
	Activate();
	
	return PLUGIN_CONTINUE;
}  

public blockBuy(){
	register_clcmd("cl_setautobuy", "block")
	register_clcmd("cl_autobuy", "block")
	register_clcmd("cl_setrebuy", "block")
	register_clcmd("cl_rebuy", "block")
	register_clcmd("buy", "block")
	register_clcmd("p228", "block");
	register_clcmd("228compact", "block");
	register_clcmd("shield", "block");
	register_clcmd("scout", "block");    
	register_clcmd("hegren", "block");               
	register_clcmd("xm1014", "block");
	register_clcmd("autoshotgun", "block");                   
	register_clcmd("mac10", "block");                
	register_clcmd("aug", "block");
	register_clcmd("bullpup", "block");
	register_clcmd("sgren", "block");   
	register_clcmd("elites", "block");     
	register_clcmd("fn57", "block");
	register_clcmd("fiveseven", "block");  
	register_clcmd("ump45", "block");                
	register_clcmd("sg550", "block");
	register_clcmd("krieg550", "block");   
	register_clcmd("galil", "block");
	register_clcmd("defender", "block");  
	register_clcmd("famas", "block");
	register_clcmd("clarion", "block");   
	register_clcmd("usp", "block");
	register_clcmd("km45", "block");       
	register_clcmd("glock", "block");
	register_clcmd("9x19mm", "block");     
	register_clcmd("awp", "block");
	register_clcmd("magnum", "block");     
	register_clcmd("mp5", "block");
	register_clcmd("smg", "block");       
	register_clcmd("m249", "block");                 
	register_clcmd("m3", "block");
	register_clcmd("12gauge", "block");   
	register_clcmd("m4a1", "block");                 
	register_clcmd("tmp", "block");
	register_clcmd("mp", "block");         
	register_clcmd("g3sg1", "block");
	register_clcmd("d3au1", "block");    
	register_clcmd("flash", "block");                
	register_clcmd("deagle", "block");
	register_clcmd("nighthawk", "block"); 
	register_clcmd("sg552", "block");
	register_clcmd("krieg552", "block");   
	register_clcmd("ak47", "block");
	register_clcmd("cv47", "block");                        
	register_clcmd("p90", "block");
	register_clcmd("c90", "block");
	register_clcmd("primammo", "block");
	register_clcmd("secammo", "block");
	register_clcmd("vest", "block");
	register_clcmd("vesthelm", "block");
	register_clcmd("nvgs", "block");
}

public block(id){
	if(Active){
		client_print(id, print_center, "Kupowanie broni zablokowane!");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

play(id,const sound[])
{
	new end = strlen(sound)-4;
	if(containi(sound,".mp3") == end && end>0)
	client_cmd(id,"mp3 play sound/%s",sound);
	else if(containi(sound,".wav") == end && end>0)
	client_cmd(id, "spk sound/%s",sound);
	else
	client_cmd(id, "speak %s",sound);
}
