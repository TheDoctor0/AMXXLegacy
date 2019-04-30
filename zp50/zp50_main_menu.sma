/*================================================================================
	
	----------------------
	-*- [ZP] Main Menu -*-
	----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#define LIBRARY_BUYMENUS "zp50_buy_menus"
#include <zp50_buy_menus>
#define LIBRARY_ZOMBIECLASSES "zp50_class_zombie"
#include <zp50_class_zombie>
#define LIBRARY_HUMANCLASSES "zp50_class_human"
#include <zp50_class_human>
#define LIBRARY_ITEMS "zp50_items"
#include <zp50_items>
#define LIBRARY_ADMIN_MENU "zp50_admin_menu"
#include <zp50_admin_menu>
#define LIBRARY_RANDOMSPAWN "zp50_random_spawn"
#include <zp50_random_spawn>
#include <zp50_colorchat>
#include <zp50_level>

native zp_voteban_menu(id)
native donate_show(id)

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_ChooseTeamOverrideActive

public plugin_init()
{
	register_plugin("[ZP] Main Menu", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("chooseteam", "clcmd_chooseteam")
	
	register_clcmd("say /zpmenu", "clcmd_zpmenu")
	register_clcmd("say zpmenu", "clcmd_zpmenu")
	register_clcmd("say /menu", "clcmd_zpmenu")
	
	// Menus
	register_menu("Main Menu", KEYSMENU, "menu_main")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_BUYMENUS) || equal(module, LIBRARY_ZOMBIECLASSES) || equal(module, LIBRARY_HUMANCLASSES) || equal(module, LIBRARY_ITEMS) || equal(module, LIBRARY_ADMIN_MENU) || equal(module, LIBRARY_RANDOMSPAWN))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public clcmd_chooseteam(id)
{
	if (flag_get(g_ChooseTeamOverrideActive, id))
	{
		show_menu_main(id)
		return PLUGIN_HANDLED;
	}
	
	flag_set(g_ChooseTeamOverrideActive, id)
	return PLUGIN_CONTINUE;
}

public clcmd_zpmenu(id)
{
	show_menu_main(id)
}

public client_putinserver(id)
{
	flag_set(g_ChooseTeamOverrideActive, id)
}

// Main Menu
show_menu_main(id)
{
	static menu[512], status[96]
	new len
	
	if(get_user_flags(id) & ADMIN_BAN)  formatex(status, charsmax(status), "\r[ \yAdmin\r ]^n")
	else if(get_user_flags(id) & ADMIN_LEVEL_H) formatex(status, charsmax(status), "\r[ \yVIP\r ]^n")
	else formatex(status, charsmax(status), "\r[ \yGracz\r ]^n")
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yMenu Glowne^n\wTwoj Status: %s^n", status)
	
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w Informacje o VIPie \r[ \yVIP\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w Wybierz Klase \r[ \yCLASS\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w Umiejetnosci \r[ \ySKILLS\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w Oddzialy \r[ \ySQUADS\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w Bossy \r[ \yBOSSES\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w Sklep \r[ \ySHOP\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r7.\w Przekaz AP \r[ \yDONATE\r ]^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r8.\w Odblokuj \r[ \yUNSTUCK\r ]^n")
	if(get_user_flags(id) & ADMIN_BAN)
		len += formatex(menu[len], charsmax(menu) - len, "^n\r9.\y Мenu Admina \r[ \yADMIN\r ]^n")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r9.\w Zawolaj Admina \r[ \yADMIN\r ]^n")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0.\w Wyjscie")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}

// Main Menu
public menu_main(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: 
		{
			show_motd(id, "vip.txt")
		}
		case 1: 
		{
			client_cmd(id, "say /klasa")
		}
		case 2: 
		{
			client_cmd(id, "say /skille")
		}
		case 3: 
		{
			client_cmd(id, "say /oddzial")
		}
		case 4: 
		{
			client_cmd(id, "say /boss")
		}
		case 5: 
		{
			client_cmd(id, "say /sklep")
		}
		case 6: 
		{
			client_cmd(id, "say /przelej")
		}
		case 7:
		{
			if (is_player_stuck(id)) zp_random_spawn_do(id, false)
			else zp_colored_print(id, "Nie jestes zablokowany!")
		}
		case 8:
		{
			if(get_user_flags(id) & ADMIN_BAN)
				zp_admin_menu_show(id)
			else
				client_cmd(id, "say /zawolaj")
		}
	}
	
	return PLUGIN_HANDLED;
}

// Check if a player is stuck (credits to VEN)
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}