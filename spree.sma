#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Spreeeee!"
#define VERSION "0.07"
#define AUTHOR "R3X"
#define MAX_PLAYERS 32
//rozrabiaka
#define PREPARE_HUD() set_hudmessage(42, 255, 42, 0.02, -1.0, 0, 6.0, 6.0,_,_,2)
//koniec szalenstwa
#define PREPARE_HUD2() set_hudmessage(42, 42, 255, 0.62, -1.0, 0, 6.0, 6.0,_,_,1)

//#define DEBUG

new g_points[MAX_PLAYERS+1][2];
new g_pointsThisRound[MAX_PLAYERS+1][2];
new g_cvarLimit,g_cvarEndShow;

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("DeathMsg","onDeath","a");
	register_event("TextMsg", "resetAll", "a", "2&#Game_will_restart_in" );
	register_event("TextMsg", "resetAll", "a", "2&#Game_C");
	register_logevent("onEndRound", 2, "1=Round_End") 
	register_logevent("resetAllThisRound", 2, "1=Round_Start")  
	g_cvarLimit=register_cvar("amx_spree_limit","5");
	g_cvarEndShow=register_cvar("amx_endshow","1");
#if defined DEBUG
	register_concmd("show_points","cmd_show_points",ADMIN_KICK);
#endif
}
reset(id){
	g_points[id][0]=0;
	g_points[id][1]=0;
}
resetRound(id){
	g_pointsThisRound[id][0]=0;
	g_pointsThisRound[id][1]=0;
}
public resetAllThisRound(){
	for(new i=0;i<=MAX_PLAYERS;i++)
		resetRound(i);
}
public resetAll(){
	for(new i=0;i<=MAX_PLAYERS;i++)
		reset(i);
}
public onEndRound(){
	if(get_pcvar_num(g_cvarEndShow))
		set_task(0.3,"podsumowanie");
}
public podsumowanie(){
	new bool:double=false;
	new id=0;
	for(new i=1;i<=MAX_PLAYERS;i++){
		if(g_pointsThisRound[id][0]==g_pointsThisRound[i][0]){
			if(g_pointsThisRound[id][1] == g_pointsThisRound[i][1]){
				double=true;
			}
			else if(g_pointsThisRound[id][1] < g_pointsThisRound[i][1]){
				id=i;
				double=false;
			}
		}
		else if(g_pointsThisRound[id][0] < g_pointsThisRound[i][0]){
			id=i;	
			double=false;
		}
	}
	if(!double && id){
		PREPARE_HUD();
		new szNick[33];
		get_user_name(id,szNick,32);
		show_hudmessage(0, "Najbardziej narozrabial:^n%s^n[%d w tym %d w glowe]",szNick,g_pointsThisRound[id][0],g_pointsThisRound[id][1]);
	}
}
public client_putinserver(id){
	reset(id);
	resetRound(id);
}
public client_disconnect(id){
	reset(id);
	resetRound(id);
}
public onDeath(){
	new kid=read_data(1);
	new vid=read_data(2);
	if(!is_user_connected(kid)){
		reset(vid);
		return PLUGIN_CONTINUE;
	}
	g_points[kid][0]++;
	g_pointsThisRound[kid][0]++;
	
	if(read_data(3)){
		g_points[kid][1]++;
		g_pointsThisRound[kid][1]++;
	}
	if(get_pcvar_num(g_cvarLimit)<=0)
		return PLUGIN_CONTINUE;
	if(g_points[vid][0]>=get_pcvar_num(g_cvarLimit)){
		new szVicNick[33],szKilNick[33];
		get_user_name(vid,szVicNick,32);
		get_user_name(kid,szKilNick,32);
		PREPARE_HUD2();
		show_hudmessage(0, "Szalenstwo zabijania^n%s^n [%d w tym %d w glowe]^n^nzatrzymane przez:^n%s",szVicNick,g_points[vid][0],g_points[vid][1],szKilNick);
	}
	reset(vid);
	return PLUGIN_CONTINUE;
}
#if defined DEBUG
public cmd_show_points(id,level,cid){
	if( !cmd_access(id, level, cid, 1)) 
		return PLUGIN_HANDLED;
	client_print(id,print_console,"----------Points------------");
	new Players[32];
	new playerCount, id2;
	get_players(Players, playerCount);
	for ( new i=0; i<playerCount; i++){
		id2 = Players[i];
		client_print(id,print_console,"[%d] P=%d(%dhs), PTR=%d(%dhs)",id2,g_points[id2][0],g_points[id2][1],g_pointsThisRound[id2][0],g_pointsThisRound[id2][1])
	}
	client_print(id,print_console,"--------------------------");
	return PLUGIN_HANDLED;
}
#endif
