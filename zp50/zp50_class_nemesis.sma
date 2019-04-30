/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Nemesis -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <zp50_colorchat>

new Float:g_fCooldown[33], Float:g_fCooldown2[33], g_HudSync
const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)
#define TASK_ATTACK 1046
#define ID_ATTACK (taskid - TASK_ATTACK)

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_nemesis_player[][] = { "csobc_nemesis" }
new const models_nemesis_claw[][] = { "models/csobc/z/nemesis/v_knife.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_nemesis_player
new Array:g_models_nemesis_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new g_IsNemesis

new cvar_nemesis_health, cvar_nemesis_base_health, cvar_nemesis_speed, cvar_nemesis_gravity
new cvar_nemesis_glow
new cvar_nemesis_aura, cvar_nemesis_aura_color_R, cvar_nemesis_aura_color_G, cvar_nemesis_aura_color_B
new cvar_nemesis_damage, cvar_nemesis_kill_explode
new cvar_nemesis_grenade_frost, cvar_nemesis_grenade_fire
new sprites_trail_index, sprites_exp_index

public plugin_init()
{
	register_plugin("[ZP] Class: Nemesis", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	register_clcmd("radio3", "clcmd_radio")
	register_clcmd("drop", "clcmd_drop")
	
	register_touch("deimos tail", "*", "Touch")
	
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_nemesis_health = register_cvar("zp_nemesis_health", "0")
	cvar_nemesis_base_health = register_cvar("zp_nemesis_base_health", "2000")
	cvar_nemesis_speed = register_cvar("zp_nemesis_speed", "1.05")
	cvar_nemesis_gravity = register_cvar("zp_nemesis_gravity", "0.5")
	cvar_nemesis_glow = register_cvar("zp_nemesis_glow", "1")
	cvar_nemesis_aura = register_cvar("zp_nemesis_aura", "1")
	cvar_nemesis_aura_color_R = register_cvar("zp_nemesis_aura_color_R", "150")
	cvar_nemesis_aura_color_G = register_cvar("zp_nemesis_aura_color_G", "0")
	cvar_nemesis_aura_color_B = register_cvar("zp_nemesis_aura_color_B", "0")
	cvar_nemesis_damage = register_cvar("zp_nemesis_damage", "2.0")
	cvar_nemesis_kill_explode = register_cvar("zp_nemesis_kill_explode", "1")
	cvar_nemesis_grenade_frost = register_cvar("zp_nemesis_grenade_frost", "0")
	cvar_nemesis_grenade_fire = register_cvar("zp_nemesis_grenade_fire", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_nemesis_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_nemesis_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS", g_models_nemesis_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_nemesis_player) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_player; index++)
			ArrayPushString(g_models_nemesis_player, models_nemesis_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "NEMESIS", g_models_nemesis_player)
	}
	if (ArraySize(g_models_nemesis_claw) == 0)
	{
		for (index = 0; index < sizeof models_nemesis_claw; index++)
			ArrayPushString(g_models_nemesis_claw, models_nemesis_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE NEMESIS", g_models_nemesis_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_nemesis_player); index++)
	{
		ArrayGetString(g_models_nemesis_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_nemesis_claw); index++)
	{
		ArrayGetString(g_models_nemesis_claw, index, model, charsmax(model))
		precache_model(model)
	}
	
	sprites_trail_index = precache_model("sprites/laserbeam.spr")
	sprites_exp_index = precache_model("sprites/csobc/deimosexp.spr")
	precache_sound("csobc/z/nemesis/deimos_skill_hit.wav")
	precache_sound("csobc/z/nemesis/deimos_skill_start.wav")
}

public plugin_natives()
{
	register_library("zp50_class_nemesis")
	register_native("zp_class_nemesis_get", "native_class_nemesis_get")
	register_native("zp_class_nemesis_set", "native_class_nemesis_set")
	register_native("zp_class_nemesis_get_count", "native_class_nemesis_get_count")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		remove_task(id+TASK_AURA)
		remove_task(id+TASK_SHOWHUD)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was nemesis before disconnecting)
	flag_unset(g_IsNemesis, id)
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))return HAM_IGNORED
	
	if(task_exists(victim)) SetHamParamFloat(4, damage/2.0)
	
	if (victim == attacker)
		return HAM_IGNORED;
	
	// Nemesis attacking human
	if (flag_get(g_IsNemesis, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore nemesis damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set nemesis damage
			SetHamParamFloat(4, damage * 2.0)
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsNemesis, victim))
	{
		// Nemesis explodes!
		if (get_pcvar_num(cvar_nemesis_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove nemesis aura
		remove_task(victim+TASK_AURA)
		remove_task(victim+TASK_SHOWHUD)
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Nemesis
	if (flag_get(g_IsNemesis, id) && !get_pcvar_num(cvar_nemesis_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		remove_task(id+TASK_AURA)
		remove_task(id+TASK_SHOWHUD)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsNemesis, id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
		
		// Remove nemesis aura
		remove_task(id+TASK_AURA)
		remove_task(id+TASK_SHOWHUD)
		
		// Remove nemesis flag
		flag_unset(g_IsNemesis, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply Nemesis attributes?
	if (!flag_get(g_IsNemesis, id) || !is_user_connected(id))
		return;
	
	// Health
	set_user_health(id, 10000+GetAliveCount()*5000)
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_nemesis_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_nemesis_speed))
	
	// Apply nemesis player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_player, random_num(0, ArraySize(g_models_nemesis_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	set_pev(id, pev_body, random_num(0,1))
	
	// Apply nemesis claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_nemesis_claw, random_num(0, ArraySize(g_models_nemesis_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
}

public native_class_nemesis_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsNemesis, id);
}

public native_class_nemesis_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsNemesis, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a nemesis (%d)", id)
		return false;
	}
	
	flag_set(g_IsNemesis, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_nemesis_get_count(plugin_id, num_params)
{
	return GetNemesisCount();
}

// Nemesis aura task
public nemesis_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(25) // radius
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
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

// Get Nemesis Count -returns alive nemesis number-
GetNemesisCount()
{
	new iNemesis, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsNemesis, id))
			iNemesis++
	}
	
	return iNemesis;
}

public clcmd_radio(id)
{
	if(!flag_get(g_IsNemesis, id))
		return PLUGIN_CONTINUE
		
	if(get_gametime()<g_fCooldown2[id]) {
		zp_colored_print(id, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown2[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	
	g_fCooldown2[id]=get_gametime()+45.0
	
	fm_set_rendering(id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 15)

	set_task(15.0, "ability_end", id)
	
	set_task(0.1, "nemesis_aura", id+TASK_AURA, _, _, "b")
	
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,1.5,4)
	
	return PLUGIN_HANDLED
}

public ShowHUD(taskid)
{
	new id=ID_SHOWHUD
	if (!flag_get(g_IsNemesis, id)){
		remove_task(taskid)
		return
	}
	if(get_gametime()<g_fCooldown[id]&&get_gametime()<g_fCooldown2[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Wstrzas^n [Gotowe za %ds]^n[C] - Szal^n [Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()), floatround(g_fCooldown2[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Wstrzas^n [Gotowe za %ds]^n[C] - Szal", floatround(g_fCooldown[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown2[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Wstrzas^n^n[C] - Szal^n [Gotowe za %ds]", floatround(g_fCooldown2[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Wstrzas^n^n[C] - Szal")
}

public ability_end(id)
{
	if(!is_user_connected(id)||!is_user_alive(id))return
	fm_set_rendering(id)
	remove_task(id+TASK_AURA)
}

public clcmd_drop(id)
{
	if (!flag_get(g_IsNemesis, id)) 
		return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown[id]) {
		zp_colored_print(id, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	
	g_fCooldown[id]=get_gametime()+10.0
	
	set_task(0.5, "launch_light", id+TASK_ATTACK)
	
	entity_set_int(id, EV_INT_sequence, 10)
	
	emit_sound(id, CHAN_VOICE, "csobc/z/nemesis/deimos_skill_start.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	play_weapon_anim(id, 2)
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,3.0,4)
	
	return PLUGIN_HANDLED
}

public launch_light(taskid)
{
	new id = ID_ATTACK

	if (!is_user_alive(id)) return;
	
	new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
	pev(id,pev_angles,vecAngle)
	engfunc(EngFunc_MakeVectors,vecAngle)
	global_get(glb_v_forward,vecForward)
	velocity_by_aim(id,2096,vecVelocity)
	set_pev(ent,pev_origin,vecOrigin)
	set_pev(ent,pev_angles,vecAngle)
	set_pev(ent,pev_classname,"deimos tail")
	set_pev(ent,pev_movetype,MOVETYPE_FLY)
	set_pev(ent,pev_solid,SOLID_BBOX)
	engfunc(EngFunc_SetSize,ent,{-1.0,-1.0,-1.0},{1.0,1.0,1.0})
	engfunc(EngFunc_SetModel,ent,"models/w_hegrenade.mdl")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_velocity,vecVelocity)
	
	set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(sprites_trail_index)
	write_byte(5)
	write_byte(3)
	write_byte(209)
	write_byte(120)
	write_byte(9)
	write_byte(200)
	message_end()
	
	return;
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

play_weapon_anim(player, anim)
{
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

public Touch(ent, victim)
{
	if (!pev_valid(ent)) return;
	
	if (is_user_alive(victim))
	{
		engclient_cmd(victim, "drop")
		
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, victim)
		write_short(UNIT_SECOND)
		write_short(0)
		write_short(FFADE_IN)
		write_byte(209)
		write_byte(120)
		write_byte(9)
		write_byte (255)
		message_end()
	
		message_begin(MSG_ONE, get_user_msgid("ScreenShake"), _, victim)
		write_short(UNIT_SECOND*4)
		write_short(UNIT_SECOND*2)
		write_short(UNIT_SECOND*10)
		message_end()
	}
	
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprites_exp_index)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	emit_sound(ent, CHAN_VOICE, "csobc/z/nemesis/deimos_skill_hit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	remove_entity(ent)
}