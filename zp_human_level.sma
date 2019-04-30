#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zp50_ammopacks>
#include <zp50_core>
#include <zp50_class_human>
#include <zp50_class_nemesis>
#include <zp50_class_survivor>
#include <zp50_ammopacks>

#define COST_HP 250
#define COST_AP 250
#define COST_GRAVITY 250
#define COST_DAMAGE 250

#define ADD_HP 10
#define ADD_AP 10
#define ADD_GRAVITY 25
#define ADD_DAMAGE 2.0

#define MAX_HP 10
#define MAX_AP 10
#define MAX_GRAVITY 10
#define MAX_DAMAGE 10

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

#define MAX_PLAYERS 32

enum Attributes
{
	HP,
	AP,
	GRAVITY,
	DAMAGE
};

new g_Player[MAX_PLAYERS+1][Attributes];
new g_MaxPlayers;

native zp_save(id);

public plugin_init()
{
	register_plugin("ZP Human Attributes System", "1.0", "O'Zone");
	
	register_clcmd("skills", "ShowAttributesMenu");
	register_clcmd("say /skille", "ShowAttributesMenu");
	register_clcmd("say /skills", "ShowAttributesMenu");
	register_clcmd("say /umiejetnosci", "ShowAttributesMenu");
	
	register_clcmd("say_team /skille", "ShowAttributesMenu");
	register_clcmd("say_team /skills", "ShowAttributesMenu");
	register_clcmd("say_team /umiejetnosci", "ShowAttributesMenu");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	
	g_MaxPlayers = get_maxplayers();
}

public plugin_natives()
{
	register_native("zp_level_menu", "native_show_menu");
	
	register_native("zp_hplvl_get", "native_hplevel_get");
	register_native("zp_aplvl_get", "native_aplevel_get");
	register_native("zp_gravitylvl_get", "native_gravitylevel_get");
	register_native("zp_damagelvl_get", "native_damagelevel_get");
	
	register_native("zp_hplvl_set", "native_hplevel_set");
	register_native("zp_aplvl_set", "native_aplevel_set");
	register_native("zp_gravitylvl_set", "native_gravitylevel_set");
	register_native("zp_damagelvl_set", "native_damagelevel_set");
}

public zp_fw_core_cure_post(id, attacker)
	SetAttributes(id);

public zp_fw_class_human_select_post(id)
	SetAttributes(id);

public SetAttributes(id)
{
	if(!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))
		return;

	set_user_armor(id, get_user_armor(id) + g_Player[id][AP]*ADD_AP)
	set_user_health(id, get_user_health(id) + g_Player[id][HP]*ADD_HP);
	set_user_gravity(id, get_user_gravity(id) - float(g_Player[id][GRAVITY] * ADD_GRAVITY)/800.0);
}

public ShowAttributesMenu(id)
{	
	new szMenu[128];
	
	formatex(szMenu, charsmax(szMenu), "\yMenu Umiejetnosci^n\r[Stan AmmoPackow: \y%i\r]", zp_ammopacks_get(id));
	new menu = menu_create(szMenu, "ShowAttributesMenu_Handler");
	formatex(szMenu, charsmax(szMenu), "Zycie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", g_Player[id][HP], MAX_HP, COST_HP+COST_HP*g_Player[id][HP]);
	menu_additem(menu, szMenu, "0");
	formatex(szMenu, charsmax(szMenu), "Kamizelka \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", g_Player[id][AP], MAX_AP, COST_AP+COST_AP*g_Player[id][AP]);
	menu_additem(menu, szMenu, "1");
	formatex(szMenu, charsmax(szMenu), "Grawitacja \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", g_Player[id][GRAVITY], MAX_GRAVITY, COST_GRAVITY+COST_GRAVITY*g_Player[id][GRAVITY]);
	menu_additem(menu, szMenu, "2");
	formatex(szMenu, charsmax(szMenu), "Obrazenia \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", g_Player[id][DAMAGE], MAX_DAMAGE, COST_DAMAGE+COST_DAMAGE*g_Player[id][DAMAGE]);
	menu_additem(menu,szMenu, "3");
	
	menu_setprop(menu, MPROP_NOCOLORS, 1);
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ShowAttributesMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0:
		{
			if(g_Player[id][HP] == MAX_HP)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Osiagnales maksymalny poziom umiejetnosci^x04 Zycie^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = zp_ammopacks_get(id) - (COST_HP+COST_HP*g_Player[id][HP]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Nie masz wystarczajacej ilosci^x04 AmmoPackow^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			g_Player[id][HP]++;
			zp_ammopacks_set(id, iRemaining);
			client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Ulepszyles umiejetnosc^x04 Zycie^x01 na^x04 %i^x01 poziom.", g_Player[id][HP]);
		}
		case 1:
		{
			if(g_Player[id][AP] == MAX_AP)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Osiagnales maksymalny poziom umiejetnosci^x04 Kamizelka^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = zp_ammopacks_get(id) - (COST_AP+COST_AP*g_Player[id][AP]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Nie masz wystarczajacej ilosci^x04 AmmoPackow^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			g_Player[id][AP]++;
			zp_ammopacks_set(id, iRemaining);
			client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Ulepszyles umiejetnosc^x04 Kamizelka^x01 na^x04 %i^x01 poziom.", g_Player[id][AP]);
		}
		case 2:
		{
			if(g_Player[id][GRAVITY] == MAX_GRAVITY)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Osiagnales maksymalny poziom umiejetnosci^x04 Grawitacja^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = zp_ammopacks_get(id) - (COST_GRAVITY+COST_GRAVITY*g_Player[id][GRAVITY]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Nie masz wystarczajacej ilosci^x04 AmmoPackow^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			g_Player[id][GRAVITY]++;
			zp_ammopacks_set(id, iRemaining);
			client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Ulepszyles umiejetnosc^x04 Grawitacja^x01 na^x04 %i^x01 poziom.", g_Player[id][GRAVITY]);
		}
		case 3:
		{
			if(g_Player[id][DAMAGE] == MAX_DAMAGE)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Osiagnales maksymalny poziom umiejetnosci^x04 Obrazenia^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = zp_ammopacks_get(id) - (COST_DAMAGE+COST_DAMAGE*g_Player[id][DAMAGE]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Nie masz wystarczajacej ilosci^x04 AmmoPackow^x01.");
				ShowAttributesMenu(id);
				return PLUGIN_HANDLED;
			}
			
			g_Player[id][DAMAGE]++;
			zp_ammopacks_set(id, iRemaining);
			client_print_color(id, print_team_red, "^x03[SKILLS]^x01 Ulepszyles umiejetnosc^x04 Obrazenia^x01 na^x04 %i^x01 poziom.", g_Player[id][DAMAGE]);
		}
	}
	
	zp_save(id);
	
	ShowAttributesMenu(id);
	
	return PLUGIN_HANDLED;
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:Damage, iBits)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iVictim))
		return HAM_IGNORED;
		
	if(zp_core_is_zombie(iAttacker) || zp_class_nemesis_get(iAttacker) || zp_class_survivor_get(iAttacker))
		return HAM_IGNORED;
	
	if(get_user_team(iVictim) == get_user_team(iAttacker) || !g_Player[iAttacker][DAMAGE])
		return HAM_IGNORED;

	SetHamParamFloat(4, Damage + (ADD_DAMAGE * g_Player[iAttacker][DAMAGE]));
	
	return HAM_IGNORED;
}

public native_show_menu(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return;
	}
	
	ShowAttributesMenu(id);
}

public native_hplevel_get(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	return g_Player[id][HP];
}

public native_aplevel_get(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	return g_Player[id][AP];
}

public native_gravitylevel_get(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	return g_Player[id][GRAVITY];
}

public native_damagelevel_get(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	return g_Player[id][DAMAGE];
}

public native_hplevel_set(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return;
	}
	
	g_Player[id][HP] = get_param(2);
}

public native_aplevel_set(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return;
	}
	
	g_Player[id][AP] = get_param(2);
}

public native_gravitylevel_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return;
	}
	
	g_Player[id][AP] = get_param(2);
}

public native_damagelevel_set(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return;
	}
	
	g_Player[id][AP] = get_param(2);
}
