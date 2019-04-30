/*================================================================================
	
	--------------------------
	-*- [ZP] Grenade: Fire -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_grenade_fire_explode[][] = { "zombie_plague/grenade_explode.wav" }
new const sound_grenade_fire_player[][] = { "zombie_plague/zombie_burn3.wav" , "zombie_plague/zombie_burn4.wav" , "zombie_plague/zombie_burn5.wav" , "zombie_plague/zombie_burn6.wav" , "zombie_plague/zombie_burn7.wav" }

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

// Models
new g_model_grenade_fire[MODEL_MAX_LENGTH] = "models/csobc/v_molotov.mdl"
new g_pmodel_grenade_fire[MODEL_MAX_LENGTH] = "models/csobc/p_molotov.mdl"
new g_wmodel_grenade_fire[MODEL_MAX_LENGTH] = "models/csobc/w_molotov.mdl"

// Sprites
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new g_sprite_grenade_fire[SPRITE_MAX_LENGTH] = "sprites/flame.spr"
new g_sprite_grenade_smoke[SPRITE_MAX_LENGTH] = "sprites/black_smoke3.spr"
new g_sprite_grenade_exp[SPRITE_MAX_LENGTH] = "sprites/csobc/flame_puff.spr"

new Array:g_sound_grenade_fire_explode
new Array:g_sound_grenade_fire_player

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 200.0

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_NAPALM = 2222

#define TASK_BURN 100
#define ID_BURN (taskid - TASK_BURN)

#define MAXPLAYERS 32

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_BURN_PRE = 0
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_BurningDuration[MAXPLAYERS+1]

new g_FireEnt[33]

new g_MsgDamage
new g_trailSpr, g_exploSpr, g_flameSpr, g_expSpr, g_smokeSpr

new cvar_grenade_fire_duration, cvar_grenade_fire_damage, cvar_grenade_fire_slowdown, cvar_grenade_fire_hudicon, cvar_grenade_fire_explosion

public plugin_init()
{
	register_plugin("[ZP] Grenade: Fire", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "ham_item_deploy_post",1)
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_hegrenade", "ham_weapon_idle")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "ham_weapon_primaryattack")
	
	register_touch("grenade","*","fw_Touch")
	
	register_think("fire ent","think")
	
	g_MsgDamage = get_user_msgid("Damage")
	
	cvar_grenade_fire_duration = register_cvar("zp_grenade_fire_duration", "10")
	cvar_grenade_fire_damage = register_cvar("zp_grenade_fire_damage", "5")
	cvar_grenade_fire_slowdown = register_cvar("zp_grenade_fire_slowdown", "0.5")
	cvar_grenade_fire_hudicon = register_cvar("zp_grenade_fire_hudicon", "1")
	cvar_grenade_fire_explosion = register_cvar("zp_grenade_fire_explosion", "0")
	
	g_Forwards[FW_USER_BURN_PRE] = CreateMultiForward("zp_fw_grenade_fire_pre", ET_CONTINUE, FP_CELL)
}

public plugin_precache()
{
	// Initialize arrays
	g_sound_grenade_fire_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_grenade_fire_player = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE EXPLODE", g_sound_grenade_fire_explode)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE PLAYER", g_sound_grenade_fire_player)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_grenade_fire_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_fire_explode; index++)
			ArrayPushString(g_sound_grenade_fire_explode, sound_grenade_fire_explode[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE EXPLODE", g_sound_grenade_fire_explode)
	}
	if (ArraySize(g_sound_grenade_fire_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_fire_player; index++)
			ArrayPushString(g_sound_grenade_fire_player, sound_grenade_fire_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE FIRE PLAYER", g_sound_grenade_fire_player)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_ GRENADE FIRE", g_model_grenade_fire, charsmax(g_model_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_ GRENADE FIRE", g_model_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "P_ GRENADE FIRE", g_pmodel_grenade_fire, charsmax(g_pmodel_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "P_ GRENADE FIRE", g_pmodel_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "W_ GRENADE FIRE", g_wmodel_grenade_fire, charsmax(g_wmodel_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "W_ GRENADE FIRE", g_wmodel_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "FIRE", g_sprite_grenade_fire, charsmax(g_sprite_grenade_fire)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "FIRE", g_sprite_grenade_fire)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "SMOKE", g_sprite_grenade_smoke, charsmax(g_sprite_grenade_smoke)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "SMOKE", g_sprite_grenade_smoke)
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_grenade_fire_explode); index++)
	{
		ArrayGetString(g_sound_grenade_fire_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_grenade_fire_player); index++)
	{
		ArrayGetString(g_sound_grenade_fire_player, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GRENADE FIRE EXPLO", g_sprite_grenade_exp, charsmax(g_sprite_grenade_exp)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GRENADE FIRE EXPLO", g_sprite_grenade_exp)
	
	// Precache models
	precache_model(g_model_grenade_fire)
	precache_model(g_pmodel_grenade_fire)
	precache_model(g_wmodel_grenade_fire)
	g_trailSpr = precache_model(g_sprite_grenade_trail)
	g_exploSpr = precache_model(g_sprite_grenade_ring)
	g_flameSpr = precache_model(g_sprite_grenade_fire)
	g_smokeSpr = precache_model(g_sprite_grenade_smoke)
	g_expSpr=precache_model(g_sprite_grenade_exp)
	precache_sound("weapons/molotov_light.wav")
}

public plugin_natives()
{
	register_library("zp50_grenade_fire")
	register_native("zp_grenade_fire_get", "native_grenade_fire_get")
	register_native("zp_grenade_fire_set", "native_grenade_fire_set")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_grenade_fire_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_amx("[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return task_exists(id+TASK_BURN);
}

public native_grenade_fire_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_amx("[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new set = get_param(2)
	
	// End fire
	if (!set)
	{
		// Not burning
		if (!task_exists(id+TASK_BURN))
			return true;
		
		// Get player origin
		static origin[3]
		get_user_origin(id, origin)
		
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		//remove_task(id+TASK_BURN)
		delete_fire_ent(id)
		return true;
	}
	
	// Set on fire
	return set_on_fire(id);
}

public zp_fw_core_cure_post(id, attacker)
{
	// Stop burning
	//remove_task(id+TASK_BURN)
	delete_fire_ent(id)
	g_BurningDuration[id] = 0
	
	// Set custom grenade model
	cs_set_player_view_model(id, CSW_HEGRENADE, g_model_grenade_fire)
	cs_set_player_weap_model(id, CSW_HEGRENADE, g_pmodel_grenade_fire)
}

public zp_fw_core_infect(id, attacker)
{
	// Remove custom grenade model
	cs_reset_player_view_model(id, CSW_HEGRENADE)
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Stop burning
	//remove_task(victim+TASK_BURN)
	delete_fire_ent(victim)
	g_BurningDuration[victim] = 0
}

public client_disconnect(id)
{
	// Stop burning
	//remove_task(id+TASK_BURN)
	delete_fire_ent(id)
	g_BurningDuration[id] = 0
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return FMRES_IGNORED
	
	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return FMRES_IGNORED
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED
	
	// Grenade's owner is zombie?
	if (zp_core_is_zombie(pev(entity, pev_owner)))
		return FMRES_IGNORED
		
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(2) // life
		write_byte(8) // width
		write_byte(255) // r
		write_byte(200) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
		
		engfunc(EngFunc_SetModel, entity, g_wmodel_grenade_fire)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fw_Touch(w_box,other){
	if (!pev_valid(w_box)) return
	if (pev(w_box, PEV_NADE_TYPE) != NADE_TYPE_NAPALM) return
	if(pev(w_box, pev_iuser1) == 1) return
	set_pev(w_box, pev_velocity, {0.0,0.0,0.0})
	set_pev(w_box, pev_iuser1, 1)
	set_pev(w_box, pev_dmgtime, get_gametime()+4.0)
	set_pev(w_box, pev_nextthink, get_gametime()+0.5)
	static Float:origin[3]
	pev(w_box, pev_origin, origin)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]+5)
	write_short(200) // radius
	write_byte(232) // particle color
	write_byte(5) // duration * 10 will be randomized a bit
	message_end()
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(g_expSpr)
	write_byte(25)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	create_blast2(origin)
	fm_set_rendering(w_box,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,0)
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_fire_explode, random_num(0, ArraySize(g_sound_grenade_fire_explode) - 1), sound, charsmax(sound))
	emit_sound(w_box, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

native zp_tattoo_get(id)

public ham_item_deploy_post(weapon_entity) {
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	
	play_weapon_animation(id, 3)
}

public ham_weapon_idle(weapon_entity) {
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	if(get_pdata_float(weapon_entity, 48, 4)>0.0)return
	
	if(get_pdata_float(weapon_entity, 30, 4)>0.0)
		play_weapon_animation(id, 2)
		
	else if(get_pdata_float(weapon_entity, 31, 4)>0.0&&get_pdata_int(weapon_entity, 51, 4))
		play_weapon_animation(id, 3)
}

public ham_weapon_primaryattack(weapon_entity) {
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(get_pdata_float(weapon_entity, 30, 4)>0.0)return
	play_weapon_animation(id, 1)
}

stock play_weapon_animation(id,sequence)message_begin(MSG_ONE,SVC_WEAPONANIM,_,id),write_byte(sequence),write_byte(zp_tattoo_get(id)),message_end()

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Not a napalm grenade
	if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return HAM_IGNORED;
	
	if(pev(entity, pev_iuser1) != 1) return HAM_SUPERCEDE
		
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	fire_explode(entity);
	
	// Keep the original explosion?
	if (get_pcvar_num(cvar_grenade_fire_explosion))
	{
		set_pev(entity, PEV_NADE_TYPE, 0)
		return HAM_IGNORED;
	}
	
	static Float:origin[3]
	pev(entity, pev_origin, origin)
	
	set_pev(entity, pev_nextthink, get_gametime()+0.25)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-80.0, 80.0)) // x
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-80.0, 80.0)) // y
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(20.0, 40.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(7) // scale
	write_byte(255) // brightness
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-100.0, 100.0)) // x
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-100.0, 100.0)) // y
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(20.0, 40.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(7) // scale
	write_byte(200) // brightness
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-100.0, 100.0)) // x
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-100.0, 100.0)) // y
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(20.0, 40.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(7) // scale
	write_byte(255) // brightness
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-100.0, 100.0)) // x
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-100.0, 100.0)) // y
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(20.0, 40.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(7) // scale
	write_byte(200) // brightness
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-50.0, 50.0)) // x
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-50.0, 50.0)) // y
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(20.0, 40.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(7) // scale
	write_byte(255) // brightness
	message_end()
	
	// Get rid of the grenade
	if(dmgtime<get_gametime()){
		engfunc(EngFunc_RemoveEntity, entity)
		return HAM_SUPERCEDE;
	}
	return HAM_SUPERCEDE;
}

// Fire Grenade Explosion
fire_explode(ent)
{
	// Get origin
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	// Collisions
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive zombies
		if (!is_user_alive(victim) || !zp_core_is_zombie(victim))
			continue;
		
		set_on_fire(victim)
	}
}

set_on_fire(victim)
{
	// Allow other plugins to decide whether player should be burned or not
	ExecuteForward(g_Forwards[FW_USER_BURN_PRE], g_ForwardResult, victim)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return false;
	
	// Heat icon?
	if (get_pcvar_num(cvar_grenade_fire_hudicon))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Reduced duration for Nemesis
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(victim))
	{
		// fire duration (nemesis)
		g_BurningDuration[victim] = get_pcvar_num(cvar_grenade_fire_duration)
	}
	else
	{
		// fire duration (zombie)
		g_BurningDuration[victim] = get_pcvar_num(cvar_grenade_fire_duration) * 5
	}
	
	// Set burning task on victim
	//remove_task(victim+TASK_BURN)
	//set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
	set_fire_ent(victim)
	return true;
}

// Burning Flames
public burning_flame(taskid)
{
	// Get player origin and flags
	static origin[3]
	get_user_origin(ID_BURN, origin)
	new flags = pev(ID_BURN, pev_flags)
	
	// In water or burning stopped
	if ((flags & FL_INWATER) || g_BurningDuration[ID_BURN] < 1)
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return;
	}
	
	// Nemesis Class loaded?
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(ID_BURN))
	{
		// Randomly play burning zombie scream sounds
		if (random_num(1, 20) == 1)
		{
			static sound[SOUND_MAX_LENGTH]
			ArrayGetString(g_sound_grenade_fire_player, random_num(0, ArraySize(g_sound_grenade_fire_player) - 1), sound, charsmax(sound))
			emit_sound(ID_BURN, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		// Fire slow down
		if ((flags & FL_ONGROUND) && get_pcvar_float(cvar_grenade_fire_slowdown) > 0.0)
		{
			static Float:velocity[3]
			pev(ID_BURN, pev_velocity, velocity)
			xs_vec_mul_scalar(velocity, get_pcvar_float(cvar_grenade_fire_slowdown), velocity)
			set_pev(ID_BURN, pev_velocity, velocity)
		}
	}
	
	// Get player's health
	new health = get_user_health(ID_BURN)
	
	// Take damage from the fire
	if (health - floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil) > 0)
		set_user_health(ID_BURN, health - floatround(get_pcvar_float(cvar_grenade_fire_damage), floatround_ceil))
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease burning duration counter
	g_BurningDuration[ID_BURN]--
}

// Fire Grenade: Fire Blast
create_blast2(const Float:origin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

set_fire_ent(id){
	if(pev_valid(g_FireEnt[id])) return
	g_FireEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(g_FireEnt[id])) return
	engfunc(EngFunc_SetModel, g_FireEnt[id], g_sprite_grenade_fire)
	set_pev(g_FireEnt[id], pev_classname, "fire ent")
	set_pev(g_FireEnt[id], pev_solid, SOLID_NOT)
	set_pev(g_FireEnt[id], pev_movetype, MOVETYPE_FOLLOW)
	set_pev(g_FireEnt[id], pev_scale, 0.6)
	set_pev(g_FireEnt[id], pev_aiment, id)
	set_pev(g_FireEnt[id], pev_nextthink, get_gametime())
	set_pev(g_FireEnt[id], pev_fuser1, get_gametime())
	set_pev(g_FireEnt[id], pev_fuser2, get_gametime()+5.0)
	fm_set_rendering(g_FireEnt[id], kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
}

delete_fire_ent(id){
	if(pev_valid(g_FireEnt[id])){
		remove_entity(g_FireEnt[id])
		g_FireEnt[id]=0
	}
}

public think(ent){
	if(!pev_valid(ent))
		return;
	new victim=pev(ent, pev_aiment)
	new Float:dmgtime
	pev(ent, pev_fuser1, dmgtime)
	new Float:dmgtime2
	pev(ent, pev_fuser2, dmgtime2)
	
	if(get_gametime()>=dmgtime2)
	{
		remove_entity(g_FireEnt[victim])
		g_FireEnt[victim]=0
	}
	
	if(dmgtime+1.0<get_gametime() && pev_valid(victim) && pev_valid(ent))
	{
		ExecuteHamB(Ham_TakeDamage, victim, ent, victim, 50.0, DMG_BULLET)
		set_pev(ent, pev_fuser1, get_gametime())
	}
	
	new Float:fFrame
	pev(ent, pev_frame, fFrame)
	fFrame += 1.0
	if(fFrame>=7.0) fFrame=0.0
	set_pev(ent, pev_frame, fFrame)
	
	set_pev(ent, pev_nextthink, get_gametime()+0.05)
}