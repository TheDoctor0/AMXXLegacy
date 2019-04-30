/*================================================================================
	
	----------------------------
	-*- [ZP] Class: Survivor -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
native zp_give_item_m134(id)
native zp_class_human_get_sex(id)

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_survivor_player[][] = { "csobc_male_vip", "csobc_girls_vip" }

new Array:g_models_survivor_player

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

new g_models_survivor_weapon[MODEL_MAX_LENGTH] = "models/v_m249.mdl"


#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define GRENADES_ONLY 4

new g_MaxPlayers
new g_IsSurvivor

new cvar_survivor_health, cvar_survivor_base_health, cvar_survivor_speed, cvar_survivor_gravity
new cvar_survivor_weapon_block

public plugin_init()
{
	register_plugin("[ZP] Class: Survivor", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("drop", "clcmd_drop")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_survivor_health = register_cvar("zp_survivor_health", "0")
	cvar_survivor_base_health = register_cvar("zp_survivor_base_health", "100")
	cvar_survivor_speed = register_cvar("zp_survivor_speed", "0.95")
	cvar_survivor_gravity = register_cvar("zp_survivor_gravity", "1.25")
	cvar_survivor_weapon_block = register_cvar("zp_survivor_weapon_block", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_survivor_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "SURVIVOR", g_models_survivor_player)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_survivor_player) == 0)
	{
		for (index = 0; index < sizeof models_survivor_player; index++)
			ArrayPushString(g_models_survivor_player, models_survivor_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "SURVIVOR", g_models_survivor_player)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_WEAPON SURVIVOR", g_models_survivor_weapon, charsmax(g_models_survivor_weapon)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_WEAPON SURVIVOR", g_models_survivor_weapon)
	
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_survivor_player); index++)
	{
		ArrayGetString(g_models_survivor_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	
	precache_model(g_models_survivor_weapon)
}

public plugin_natives()
{
	register_library("zp50_class_survivor")
	register_native("zp_class_survivor_get", "native_class_survivor_get")
	register_native("zp_class_survivor_set", "native_class_survivor_set")
	register_native("zp_class_survivor_get_count", "native_class_survivor_get_count")
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was survivor before disconnecting)
	flag_unset(g_IsSurvivor, id)
}

public clcmd_drop(id)
{
	// Should survivor stick to his weapon?
	if (flag_get(g_IsSurvivor, id) && get_pcvar_num(cvar_survivor_weapon_block))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	// Should survivor stick to his weapon?
	if (get_pcvar_num(cvar_survivor_weapon_block) && is_user_alive(id) && flag_get(g_IsSurvivor, id))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsSurvivor, attacker))
	{
		SetHamParamInteger(3, 2)
		new origin[3]
		get_user_origin(victim, origin)
	    
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_LAVASPLASH) 
		write_coord(origin[0]) 
		write_coord(origin[1])
		write_coord(origin[2])
		message_end()
	}
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsSurvivor, id))
	{		
		// Remove survivor flag
		flag_unset(g_IsSurvivor, id)
	}
}

public zp_fw_core_infect(id, attacker)
{
	if (flag_get(g_IsSurvivor, id))
	{
		// Remove survivor flag
		flag_unset(g_IsSurvivor, id)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Apply Survivor attributes?
	if (!flag_get(g_IsSurvivor, id) || !is_user_connected(id))
		return;
	
	// Health
	if (get_pcvar_num(cvar_survivor_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_survivor_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_survivor_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_survivor_gravity))
	
	// Speed (if value between 0 and 10, consider it a multiplier)
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_survivor_speed))
	
	// Apply survivor player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_survivor_player, zp_class_human_get_sex(id), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	set_pev(id, pev_body, 0)
	
	// Strip current weapons and give survivor weapon
	strip_weapons(id, PRIMARY_ONLY)
	strip_weapons(id, SECONDARY_ONLY)
	strip_weapons(id, GRENADES_ONLY)
	zp_give_item_m134(id)
}

public native_class_survivor_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsSurvivor, id);
}

public native_class_survivor_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsSurvivor, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a survivor (%d)", id)
		return false;
	}
	
	flag_set(g_IsSurvivor, id)
	zp_core_force_cure(id)
	return true;
}

public native_class_survivor_get_count(plugin_id, num_params)
{
	return GetSurvivorCount();
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Survivor Count -returns alive survivors number-
GetSurvivorCount()
{
	new iSurvivors, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsSurvivor, id))
			iSurvivors++
	}
	
	return iSurvivors;
}

// Strip primary/secondary/grenades
stock strip_weapons(id, stripwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, weaponid
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and drop primaries or secondaries
	for (index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index]
		
		if ((stripwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		|| (stripwhat == GRENADES_ONLY && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			new wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Strip weapon and remove bpammo
			ham_strip_weapon(id, wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock ham_strip_weapon(index, const weapon[])
{
	// Get weapon id
	new weaponid = get_weaponid(weapon)
	if (!weaponid)
		return false;
	
	// Get weapon entity
	new weapon_ent = fm_find_ent_by_owner(-1, weapon, index)
	if (!weapon_ent)
		return false;
	
	// If it's the current weapon, retire first
	new current_weapon_ent = fm_cs_get_current_weapon_ent(index)
	new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	if (current_weapon == weaponid)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent)
	
	// Remove weapon from player
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
		return false;
	
	// Kill weapon entity and fix pev_weapons bitsum
	ExecuteHamB(Ham_Item_Kill, weapon_ent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))
	return true;
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}