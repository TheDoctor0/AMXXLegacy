#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define PLUGIN "Bosses Voting"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_INFO 888

new MinPlayers, VotesPercent
new AlienVotes, OberonVotes
new bool:Alien_Voted[33], bool:Oberon_Voted[33], bool:MapChanged
new const PausePlugins[][] = {"mapchooser.amxx", "deagsmapmanager.amxx"}

native zl_boss_map()

new MaxPlayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	MinPlayers = register_cvar("bv_minplayers", "12")
	VotesPercent = register_cvar("bv_votespercent", "50")
	
	register_clcmd("say", "CountVotes")
	register_clcmd("say_team", "CountVotes")
	
	MaxPlayers = get_maxplayers()
	
	set_task(240.0, "Info", TASK_INFO, "", 0, "b");
}	

public Info(){
	for(new id = 1; id <= MaxPlayers; id++){
		if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || get_user_team(id) == 0)
			continue;
			
		ColorChat(id, RED, "[BOSS]^x01 Mozliwe jest glosowanie na Bossy:^x04 /alien^x01,^x04 /oberon^x01!")
	}
}

public client_disconnect(id){
	if(Alien_Voted[id])
		AlienVotes--
	if(Oberon_Voted[id])
		OberonVotes--
}
	
public CountVotes(id)
{ 
	static szText[32]
	read_args(szText, 31)
	remove_quotes(szText)
	
	if(szText[0] != '/')
		return PLUGIN_CONTINUE
	
	new szName[33]
	get_user_name(id, szName, 32)

	if(equali(szText, "/alien", 6)){
		if(Alien_Voted[id]){
			ColorChat(id, RED, "[ALIEN]^x01 Juz oddales swoj glos na^x04 Aliena^x01!")
			return PLUGIN_HANDLED
		}
		if(zl_boss_map() > 0){
			ColorChat(id, RED, "[BOSS]^x01 Wlasnie grana jest mapa z^x04 Bossem^x01!")
			return PLUGIN_HANDLED
		}
		
		if(get_playersnum() < get_pcvar_num(MinPlayers)){
			ColorChat(id, RED, "[BOSS]^x01 Zbyt malo graczy na serwerze (Min.^x04 %i^x01)!", get_pcvar_num(MinPlayers))
			return PLUGIN_HANDLED
		}
	
		if(MapChanged){
			ColorChat(id, RED, "[BOSS]^x01 Mapa z^x04 Bossem^x01 zostala juz wybrana!")
			return PLUGIN_HANDLED
		}
		Alien_Voted[id] = true
		AlienVotes++
		new Alien_Left = floatround(float(get_playersnum())*(float(get_pcvar_num(VotesPercent))/100.0))-AlienVotes
		if(Alien_Left > 0){
			ColorChat(0, RED, "[ALIEN]^x04 %s^x01 zaglosowal na^x04 Aliena^x01! Potrzeba jeszcze^x04 %i^x01 glosow.", szName, Alien_Left)
			ColorChat(0, RED, "[ALIEN]^x01 Aby zaglosowac na kolejna mape z^x04 Alienem^x01 wpisz^x04 /alien^x01!")
		}
		else {
			ColorChat(0, RED, "[ALIEN]^x04 Osiagnieto wymagana liczbe glosow! Kolejna mapa:^x04 zl_boss_alien^x01.")
			AlienMap()
		}
		return PLUGIN_HANDLED
	}  
	else if(equali(szText, "/oberon", 7)){
		if(Oberon_Voted[id]){
			ColorChat(id, RED, "[OBERON]^x01 Juz oddales swoj glos na^x04 Oberona^x01!")
			return PLUGIN_HANDLED
		}
		Oberon_Voted[id] = true
		OberonVotes++
		new Oberon_Left = floatround(float(get_playersnum())*(float(get_pcvar_num(VotesPercent))/100.0))-OberonVotes
		if(Oberon_Left > 0){
			ColorChat(0, RED, "[OBERON]^x04 %s^x01 zaglosowal na^x04 Oberona^x01! Potrzeba jeszcze^x04 %i^x01 glosow.", szName, Oberon_Left)
			ColorChat(0, RED, "[OBERON]^x01 Aby zaglosowac na kolejna mape z^x04 Oberonem^x01 wpisz^x04 /oberon^x01!")
		}
		else {
			ColorChat(0, RED, "[OBERON]^x01 Osiagnieto wymagana liczbe glosow! Kolejna mapa:^x04 zl_boss_oberon^x01.")
			OberonMap()
		}
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public AlienMap(){
	MapChanged = true
	server_cmd("amx_nextmap zl_boss_alien")
	for(new i = 0; i < sizeof PausePlugins; i++)
		pause("ac", PausePlugins[i])
}

public OberonMap(){
	MapChanged = true
	server_cmd("amx_nextmap zl_boss_oberon")
	for(new i = 0; i < sizeof PausePlugins; i++)
		pause("ac", PausePlugins[i])
}