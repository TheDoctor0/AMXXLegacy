#include <amxmodx>
#include <fun>

#define PLUGIN "HE Block"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_BLOCK 7526

new cvarTime, bool:iBlock, gHUD, gMaxPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon","CurWeapon","be", "1=1");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	
	register_cvar("he_block_time","15")
	
	gHUD = CreateHudSyncObj();
}

public plugin_cfg()
{
	cvarTime = get_cvar_num("he_block_time");
	
	gMaxPlayers = get_maxplayers();
}

public NewRound()
{
	iBlock = true;
	
	remove_task(TASK_BLOCK);
	
	set_task(float(cvarTime), "RemoveBlock", TASK_BLOCK);
}

public RemoveBlock()
{
	iBlock = false;
	
	for(new id = 1; id <= gMaxPlayers; id++)
	{
		if(is_user_alive(id) && user_has_weapon(id, CSW_HEGRENADE))
		{
			set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2);
			ShowSyncHudMsg(id, gHUD, "HE zostal odblokowany!");
		}
	}
}

public CurWeapon(id)
{
	new iWeapon = read_data(2);
	
	if(iWeapon == CSW_HEGRENADE && iBlock)
	{
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2);
		ShowSyncHudMsg(id, gHUD, "HE jest zablokowane przez %i sekund.", cvarTime);
		engclient_cmd(id, "lastinv");
	}
}
