#include <amxmodx> 

new g_IsLastRound = 0 
new g_OldTimelimit = 0 

#define TASK_ID_CHECKFORMAPEND 241 
#define TASK_ID_DELAYMAPCHANGE 242 

public plugin_init() 
{ 
	register_plugin("Allow round finish", "1.0.2" ,"EKS & Sn!ff3r") 
    
	register_event("SendAudio","Event_EndRound","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw") 
	set_task(15.0,"Task_MapEnd",TASK_ID_CHECKFORMAPEND,_,_,"d",1) 
}

public Task_MapEnd() 
{ 
	if(get_playersnum()) 
	{ 
		g_IsLastRound = 1 
		g_OldTimelimit = get_cvar_num("mp_timelimit") 
		new nextmap[33] 
		get_cvar_string("amx_nextmap", nextmap, 32)        
		server_cmd("mp_timelimit 0") 
		client_print_color(0, print_team_red, "Czas mapy juz^x04 minal^x01, zmiana mapy na^x03 %s^x01 nastapi po tej rundzie.", nextmap) 
	} 
} 
public Event_EndRound() 
{ 
	if(g_IsLastRound == 1) 
	{ 
		client_print_color(0, print_team_red, "Runda zakonczona, zmiana mapy nastapi w ciagu^x04 5 sekund^x01.") 
		set_task(5.0, "Task_DelayMapEnd", TASK_ID_DELAYMAPCHANGE, _, _, "a", 1) 
	} 
} 
public server_changelevel(map[]) 
{ 
	if(g_IsLastRound == 1) 
		Task_DelayMapEnd() 
} 
public Task_DelayMapEnd() 
{ 
	remove_task(TASK_ID_DELAYMAPCHANGE) 
	g_IsLastRound = 0 
	if(get_cvar_num("mp_timelimit") == 0) 
		server_cmd("mp_timelimit %d", g_OldTimelimit) 
}
