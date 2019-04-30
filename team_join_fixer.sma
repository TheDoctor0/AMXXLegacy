#include <amxmodx>
#include <colorchat>

#define PLUGIN "Team Join Fixer"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_RESTART 8932
#define TASK_INFO 8933

new g_MaxPlayers;

new szMapName[32], iRestart[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event( "TeamInfo", "JoinTeam", "a");
	
	g_MaxPlayers = get_maxplayers();
}

public plugin_precache()
	get_mapname(szMapName, 31);
	
public client_putinserver(id)
	set_task(5.0, "CheckTeams", id + TASK_INFO, .flags="b");
	
public client_disconnect(id)
{
	remove_task(id + TASK_RESTART);
	remove_task(id + TASK_INFO);
}
	
public CheckTeams(id)
{
	id -= TASK_INFO;
	
	if(CheckPlayers() || iRestart[id])
		return;

	ColorChat(id, RED, "[UWAGA]^x01 Jesli nie mozesz dolaczyc do druzyny poczekaj^x04 45 sekund^x01 na restart mapy!");
	ColorChat(id, RED, "[UWAGA]^x01 Jesli nie mozesz dolaczyc do druzyny poczekaj^x04 45 sekund^x01 na restart mapy!");
	ColorChat(id, RED, "[UWAGA]^x01 Jesli nie mozesz dolaczyc do druzyny poczekaj^x04 45 sekund^x01 na restart mapy!");
	ColorChat(id, RED, "[UWAGA]^x01 Jesli nie mozesz dolaczyc do druzyny poczekaj^x04 45 sekund^x01 na restart mapy!");
	
	set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 5.0, 0.0, 0.0);
	show_hudmessage(id, "Jesli nie mozesz dolaczyc do druzyny poczekaj 45 sekund na restart mapy!");
	
	iRestart[id] = true;
	
	set_task(45.0, "MapChange", id + TASK_RESTART);
}

public MapChange()
{
	if(!CheckPlayers())
		server_cmd("changelevel %s", szMapName);
}

public CheckPlayers()
{
	new g_Players;
	
	for(new i = 1; i <= g_MaxPlayers; i++)
		if(is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i) && (get_user_team(i) == 1 || get_user_team(i) == 2))
			g_Players++;
			
	return g_Players;
}

public JoinTeam()
{    
	new id = read_data(1);
	static user_team[32];
    
	read_data(2, user_team, 31);  
    
	if(!is_user_connected(id))
		return;    
    
	switch(user_team[0])
	{
		case 'C': remove_task(id + TASK_RESTART);
		case 'T': remove_task(id + TASK_RESTART);
	}
}  