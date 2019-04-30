#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Powody"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new g_iVictim[33], g_iArraySize, Array:g_aJailReasons;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("Powod_Zabicia", "CmdReason");
	register_clcmd("nightvision", "CmdDeny");
	
	register_clcmd("say /powody", "MenuReasons");
	register_clcmd("say_team /powody", "MenuReasons");
	register_clcmd("powody", "MenuReasons");
	
	register_clcmd("say /powod", "MenuReasons");
	register_clcmd("say_team /powod", "MenuReasons");
	register_clcmd("powod", "MenuReasons");
	
	register_event("DeathMsg", "PlayerKilled", "a");

	g_aJailReasons = ArrayCreate(128, 32);

	FileRead();
}

public plugin_end()
	ArrayDestroy(g_aJailReasons);

FileRead()
{
	new szConfigsName[256], szFilename[256];

	get_configsdir(szConfigsName, charsmax(szConfigsName));
	formatex(szFilename, charsmax(szFilename), "%s/jail_powody.ini", szConfigsName);

	new iFilePointer = fopen(szFilename, "rt");
	
	if(iFilePointer)
	{
		new szData[128];
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData));
			trim(szData);
			
			if(szData[0] == EOS || szData[0] == ';') continue;

			ArrayPushString(g_aJailReasons, szData);
		}
		
		g_iArraySize = ArraySize(g_aJailReasons);
		fclose(iFilePointer);
	}
}

public MenuReasons(id)
{
	new szTitle[128], szItem[128], szName[32];
	get_user_name(g_iVictim[id], szName, charsmax(szName));

	if(get_user_team(id) != 2 || !g_iVictim[id]) return PLUGIN_HANDLED;

	formatex(szTitle, charsmax(szTitle), "\wDlaczego \rzabiles \y%s\w?:", szName);

	new menu = menu_create(szTitle, "MenuReasons_Handle");
	
	menu_additem(menu, "\wOzyw \yGracza \r(klawisz 'n')");

	menu_additem(menu, "\wWlasny \yPowod \r(klawisz 't')"); 

	for(new i = 0; i < g_iArraySize; i++)
	{
		ArrayGetString(g_aJailReasons, i, szItem, charsmax(szItem));
		
		ucfirst(szItem);

		menu_additem(menu, szItem, "", 0);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public MenuReasons_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		g_iVictim[id] = 0;

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: CmdDeny(id);
		case 1: client_cmd(id, "messagemode Powod_Zabicia");
		default:
		{
			new szReason[64];

			ArrayGetString(g_aJailReasons, item - 2, szReason, charsmax(szReason));

			ShowReason(id, szReason);
		}
	}
	
	menu_destroy(menu);

	return PLUGIN_HANDLED;
}	

public PlayerKilled()
{
	new iAttacker = read_data(1), iVictim = read_data(2);
	
	if(is_user_connected(iAttacker) && is_user_connected(iVictim) && get_user_team(iAttacker) == 2 && get_user_team(iVictim) == 1)
	{
		g_iVictim[iAttacker] = iVictim;

		if(jail_get_prisoner_last() || jail_get_play_game() || jail_get_poszukiwani()) return;

		DestroyMenu(iAttacker);
		MenuReasons(iAttacker);
	}
}

public CmdDeny(id)
{
	if(get_user_team(id) == 2 && is_user_connected(g_iVictim[id]) && get_user_team(g_iVictim[id]) == 1)
	{
		new szName[32], szName2[32];

		get_user_name(id, szName, charsmax(szName));
		get_user_name(g_iVictim[id], szName2, charsmax(szName2));

		client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 ozywil gracza^x03 %s^x01 i przeprasza.", szName, szName2);

		DestroyMenu(id);
		
		if(!is_user_alive(g_iVictim[id])) ExecuteHamB(Ham_CS_RoundRespawn, g_iVictim[id]);
		
		g_iVictim[id] = 0;

		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdCustom(id)
{
	if(get_user_team(id) == 2 && g_iVictim[id])
	{
		DestroyMenu(id);
		
		client_cmd(id, "messagemode Powod_Zabicia");
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdReason(id)
{
	new szArgs[192];

	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	if(szArgs[0] != EOS) ShowReason(id, szArgs);

	return PLUGIN_HANDLED;
}

ShowReason(id, szReason[])
{
	if(get_user_team(id) == 2 && is_user_connected(g_iVictim[id]) && get_user_team(g_iVictim[id]) == 1)
	{
		new szName[32], szName2[32];

		get_user_name(id, szName, charsmax(szName));
		get_user_name(g_iVictim[id], szName2, charsmax(szName2));

		client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 zabil^x03 %s^x01 za^x04 %s^x01.", szName, szName2, szReason);

		g_iVictim[id] = 0;
	}
}

DestroyMenu(id)
{
	new iNewMenu, iMenu = player_menu_info(id, iMenu, iNewMenu);
	
	if(iMenu) show_menu(id, 0, "^n", 1);
}