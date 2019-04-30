/*================================================================================
	
	----------------------------
	-*- [ZP] HUD Information -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <dhudmessage>
#include <zp50_core>
#include <zp50_class_human>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>

#include <zp50_level>

const Float:HUD_SPECT_X = 0.65
const Float:HUD_SPECT_Y = 0.8

const HUD_STATS_SPEC_R = 255
const HUD_STATS_SPEC_G = 255
const HUD_STATS_SPEC_B = 255

#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

const PEV_SPEC_TARGET = pev_iuser2

new g_MsgSync

public plugin_init()
{
	register_plugin("[ZP] HUD Information", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgSync = CreateHudSyncObj()
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_AMMOPACKS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED; 
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;
		
	if (!task_exists(id+TASK_SHOWHUD))
		set_task(2.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b");
}

public client_disconnect(id)
{
	remove_task(id+TASK_SHOWHUD);
}

public ShowHUD(taskid)
{
	new player = ID_SHOWHUD
	
	if(!is_user_connected(player))
	{
		remove_task(player+TASK_SHOWHUD);
		return;
	}
	
	if (!is_user_alive(player))
	{
		player = pev(player, PEV_SPEC_TARGET);
		
		if (!is_user_alive(player))
			return;
	}
	
	if (player != ID_SHOWHUD)
	{
		new player_name[32]
		get_user_name(player, player_name, charsmax(player_name))
		
		set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 6.0, 2.2, 0.0, 0.0, -1)
		
		if(zp_level_get(ID_SHOWHUD)<zp_maxlevel_get())
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "[ %s ]^n[ HP: %d ]^n[ LEVEL: %d ]^n[ EXP: %d / %d ]^n[ AP: %d ]", player_name, get_user_health(player), zp_level_get(player), zp_exp_get(player), zp_nextexp_get(player), zp_ammopacks_get(player))
		else
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "[ %s ]^n[ HP: %d ]^n[ LEVEL: %d ]^n[ EXP: %d ]^n[ AP: %d ]", player_name, get_user_health(player), zp_level_get(player), zp_exp_get(player), zp_ammopacks_get(player))
	} 
	else 
	{
		if(!zp_core_is_zombie(ID_SHOWHUD))
		{
			set_hudmessage( .red = 0, .green = 255, .blue = 0, .x = -1.0, .y = 0.87, .effects = 0, .fxtime = 6.0, .holdtime = 2.2, .fadeintime = 0.1, .fadeouttime = 0.1); 
			if(zp_level_get(ID_SHOWHUD)<zp_maxlevel_get())
				ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "[ LEVEL: %d ]^n[ EXP: %d / %d ]", zp_level_get(ID_SHOWHUD), zp_exp_get(ID_SHOWHUD), zp_nextexp_get(ID_SHOWHUD))
			else 
				ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "[ LEVEL: %d ]^n[ EXP: %d ]", zp_level_get(ID_SHOWHUD), zp_exp_get(ID_SHOWHUD))
		}
		else
		{
			set_hudmessage( .red = 255, .green = 0, .blue = 0, .x = -1.0, .y = 0.87, .effects = 0, .fxtime = 6.0, .holdtime = 1.2, .fadeintime = 0.1, .fadeouttime = 0.1);
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "[ HP: %d ]", get_user_health(ID_SHOWHUD))			
		}
	}
}