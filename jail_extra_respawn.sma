#include <amxmodx>
#include <fun>
#include <fakemeta> 

#define PLUGIN "JailBreak: Respawn"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /ozyw", "respawn_menu", ADMIN_KICK);
	register_clcmd("say_team /ozyw", "respawn_menu", ADMIN_KICK);
	register_clcmd("ozyw", "respawn_menu", ADMIN_KICK);
}

public respawn_menu(id)
{
	if(!is_user_connected(id) || !(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED;

	new szTemp[64], szName[32], szData[3];
	
	new menu = menu_create("\wWybierz \rgracza\w do \yozywienia\w:", "respawn_menu_handler");
	
	for(new i = 0; i <= 32; i++)
	{
		if(!is_user_connected(i) || is_user_alive(i) || is_user_hltv(i) || is_user_bot(i) || (get_user_team(id) != 1 && get_user_team(id) != 2)) continue;
		
		get_user_name(i, szName, charsmax(szName));
		
		formatex(szData, charsmax(szData), "%d", i);
		
		formatex(szTemp, charsmax(szTemp), "\w%s \y(\r%s\y)", szName, get_user_team(id) == 1 ? "TT" : "CT");

		menu_additem(menu, szTemp, szData);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Dalej");
	menu_setprop(menu, MPROP_NEXTNAME, "Wroc");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public respawn_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szData[3], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	new player = str_to_num(szData);
	
	if(!is_user_connected(player) || is_user_alive(player)) return PLUGIN_HANDLED;

	new szName[32], szAdminName[32];
	
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_name(player, szName, charsmax(szName));

	set_pev(player, pev_deadflag, DEAD_RESPAWNABLE);
	
	dllfunc(DLLFunc_Think, player);
	dllfunc(DLLFunc_Spawn, player);
	
	strip_user_weapons(player);
	
	give_item(player, "weapon_knife");
	
	log_amx("Admin %s ozywil gracza %s.", szAdminName, szName);
	
	client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ozywiles gracza^x03 %s^x01.", szName);

	menu_destroy(menu);
	
	respawn_menu(id);
	
	return PLUGIN_HANDLED;
}