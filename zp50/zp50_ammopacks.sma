/*================================================================================
	
	-----------------------
	-*- [ZP] Ammo Packs -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_core>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

#define TASK_HIDEMONEY 100
#define ID_HIDEMONEY (taskid - TASK_HIDEMONEY)

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSMONEY = 115

const HIDE_MONEY_BIT = (1<<5)

#define MAXPLAYERS 32

new g_MaxPlayers
new g_AmmoPacks[MAXPLAYERS+1]

new cvar_starting_ammo_packs

public plugin_init()
{
	register_plugin("[ZP] Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MaxPlayers = get_maxplayers()
	
	RegisterHam(Ham_Spawn,"player", "ham_spawn_post",1)
	
	cvar_starting_ammo_packs = register_cvar("zp_starting_ammo_packs", "10")
	
	register_message(get_user_msgid("Money"), "message_money")
}

public plugin_natives()
{
	register_library("zp50_ammopacks")
	register_native("zp_ammopacks_get", "native_ammopacks_get")
	register_native("zp_ammopacks_set", "native_ammopacks_set")
}

public native_ammopacks_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_AmmoPacks[id];
}

public native_ammopacks_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new amount = get_param(2)
	
	g_AmmoPacks[id] = amount
	set_pdata_int(id, OFFSET_CSMONEY, g_AmmoPacks[id])
	message_begin(MSG_ONE, get_user_msgid("Money"), _, id)
	write_long(g_AmmoPacks[id]);
	write_byte(1);
	message_end();
	return true;
}

public client_putinserver(id)
{
	g_AmmoPacks[id] = get_pcvar_num(cvar_starting_ammo_packs)
}

public client_disconnect(id)
{
	remove_task(id+TASK_HIDEMONEY)
}

public ham_spawn_post(id)
{
	//set_pdata_int(id, OFFSET_CSMONEY, g_money[id])
	message_begin(MSG_ONE, get_user_msgid("Money"), _, id)
	write_long(g_AmmoPacks[id]);
	write_byte(0);
	message_end();
}

public message_money(msg_id, msg_dest, msg_entity)
{	
	if (!is_user_connected(msg_entity))
		return;
	
	// If arg 2 = 0, this is CS giving round win money or start money
	//if (get_msg_arg_int(2) == 1)
	//{
	set_msg_arg_int(1, get_msg_argtype(1), g_AmmoPacks[msg_entity])
	//}
}

// Set User Money
stock fm_cs_set_user_money(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSMONEY, value)
}