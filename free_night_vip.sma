#include <amxmodx>
#include <hamsandwich>


#define PLUGIN "Free Night VIP"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_RELOAD 8402
#define TASK_INFO 7614

#define HOUR "00"

native get_user_vip(id);
native set_user_vip(id);

forward amxbans_sql_initialized(info, db);

new bool:bInfo[33], bool:bVIP, cTimeStart, cTimeEnd, iMaxPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
    
	cTimeStart = register_cvar("free_vip_start", "23");
	cTimeEnd = register_cvar("free_vip_end", "10");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	
	iMaxPlayers = get_maxplayers();
}

public client_authorized(id)
{
	new szTime[3], iTime;
	
	get_time("%H", szTime, charsmax(szTime));
	
	iTime = str_to_num(szTime);
    
	if(get_pcvar_num(cTimeStart) <= iTime || iTime < get_pcvar_num(cTimeEnd)) 
	{
		bVIP = true;
		bInfo[id] = false;
		
		if(!is_user_hltv(id))
		{
			set_user_flags(id, get_user_flags(id) | ADMIN_LEVEL_H);
			
			if(!get_user_vip(id)) set_user_vip(id);
		}
	}
}

public PlayerSpawn(id)
	if(bVIP && !bInfo[id]) set_task(3.0, "ShowInfo", id + TASK_INFO);

public ShowInfo(id)
{
	id -= TASK_INFO;
	
	if(!is_user_connected(id) || bInfo[id]) return;
	
	bInfo[id] = true;
	
	set_hudmessage(0, 255, 0, -1.0, 0.35, 2, 3.0, 2.0, 0.2, 0.2);
	show_hudmessage(id, "Dostales darmowego VIPa!");
	
	client_print_color(id, id, "^x03[VIP]^x01 Jest miedzy godzina^x04 %i^x01:^x04%s^x01 a^x04 %i^x01:^x04%s^x01. Dostales darmowego^x04 VIPa^x01!", get_pcvar_num(cTimeStart), HOUR, get_pcvar_num(cTimeEnd), HOUR);
}

public amxbans_sql_initialized(info, db)
	if(bVIP) set_task(1.0, "SetVIP", TASK_RELOAD);

public SetVIP()
{
	for(new id = 1; id < iMaxPlayers; id++)
	{
		if(is_user_connected(id) && !is_user_hltv(id))
		{
			set_user_flags(id, get_user_flags(id) | ADMIN_LEVEL_H);
			
			if(!get_user_vip(id)) set_user_vip(id);
		}
	}
}