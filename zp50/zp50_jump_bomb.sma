/*================================================================================
	
	---------------------------------
	-*- [ZP] Item: Infection Bomb -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Infection Bomb"
#define ITEM_COST 20

#include <amxmodx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zp50_items>
#include <zp50_gamemodes>
native zp_class_nemesis_get(id)

#define WEAPONLIST "csobc_jumpbomb"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_grenade_infect_explode[][] = { "csobc/z/zombibomb/zombi_bomb_exp.wav" }
new const sound_bounce[][] = { "csobc/z/zombibomb/zombi_bomb_bounce.wav" }

#define SOUND_MAX_LENGTH 64
#define MODEL_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

new g_sprite_grenade_exp[SPRITE_MAX_LENGTH] = "sprites/csobc/jumpbomb_exp.spr"

new g_pmodel_grenade_jump[MODEL_MAX_LENGTH] = "models/csobc/z/p_jumpbomb.mdl"
new g_wmodel_grenade_jump[MODEL_MAX_LENGTH] = "models/csobc/z/w_jumpbomb.mdl"

new Array:g_sound_grenade_infect_explode

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 240.0

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_JUMP = 1111

new g_wpn_variables[10]

new msgScreenShake, g_expSpr

public plugin_init()
{
	register_plugin("[ZP] Item: Jump Bomb", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "ham_item_addtoplayer")
	
	register_touch("grenade","*","fw_Touch")
	
	msgScreenShake=get_user_msgid("ScreenShake")
	
	register_clcmd(WEAPONLIST, "clcmd_weapon")
}

public ham_item_addtoplayer(weapon_entity,id){
if(zp_core_is_zombie(id))set_weaponlist(id,1)
else set_weaponlist(id)
}

public clcmd_weapon(id){
engclient_cmd(id, "weapon_hegrenade")
return PLUGIN_HANDLED
}

public plugin_precache()
{
	register_message(78, "message_weaponlist")
	
	new tmp[32];formatex(tmp,charsmax(tmp),"sprites/%s.txt",WEAPONLIST)
	precache_generic(tmp)
	
	precache_generic("sprites/csobc/640hud61ex.spr")
	
	// Initialize arrays
	g_sound_grenade_infect_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GRENADE JUMP EXPLO", g_sprite_grenade_exp, charsmax(g_sprite_grenade_exp)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "GRENADE JUMP EXPLO", g_sprite_grenade_exp)
		
	g_expSpr=precache_model(g_sprite_grenade_exp)

	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE JUMP EXPLODE", g_sound_grenade_infect_explode)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_grenade_infect_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_infect_explode; index++)
			ArrayPushString(g_sound_grenade_infect_explode, sound_grenade_infect_explode[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE JUMP EXPLODE", g_sound_grenade_infect_explode)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_grenade_infect_explode); index++)
	{
		ArrayGetString(g_sound_grenade_infect_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "P_ GRENADE JUMP", g_pmodel_grenade_jump, charsmax(g_pmodel_grenade_jump)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "P_ GRENADE JUMP", g_pmodel_grenade_jump)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "W_ GRENADE JUMP", g_wmodel_grenade_jump, charsmax(g_wmodel_grenade_jump)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "W_ GRENADE JUMP", g_wmodel_grenade_jump)
		
	precache_model(g_pmodel_grenade_jump)
	precache_model(g_wmodel_grenade_jump)
	
	precache_sound(sound_bounce[0])
	
	precache_sound("zombi/zombi_bomb_deploy.wav")
	precache_sound("zombi/zombi_bomb_pull_1.wav")
	precache_sound("zombi/zombi_bomb_throw.wav")
	
	precache_sound("zombi/zombi_bomb_idle_1.wav")
	precache_sound("zombi/zombi_bomb_idle_2.wav")
	precache_sound("zombi/zombi_bomb_idle_3.wav")
	precache_sound("zombi/zombi_bomb_idle_4.wav")
	precache_sound("zombi/zombi_bomb_idle_5.wav")
	precache_sound("zombi/zombi_bomb_idle_6.wav")
	precache_sound("zombi/zombi_bomb_idle_7.wav")
	precache_sound("zombi/zombi_bomb_idle_8.wav")
	
}

public message_weaponlist(msg_id,msg_dest,id)if(get_msg_arg_int(8)==CSW_HEGRENADE)for(new i=2;i<=9;i++)g_wpn_variables[i]=get_msg_arg_int(i)

public zp_fw_core_infect_post(id, attacker)
{
	if(zp_class_nemesis_get(id))return
	cs_set_player_weap_model(id, CSW_HEGRENADE, g_pmodel_grenade_jump)
	
	give_item(id, "weapon_hegrenade")
	engclient_cmd(id, "weapon_knife")
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
	
	// Grenade's owner isn't zombie?
	if (!zp_core_is_zombie(pev(entity, pev_owner)))
		return FMRES_IGNORED
	
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_JUMP)
		
		set_pev(entity, pev_sequence, 1)
		set_pev(entity, pev_animtime, 100.0)
		set_pev(entity, pev_framerate, 1.0)
		engfunc(EngFunc_SetModel, entity, g_wmodel_grenade_jump)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	set_pev(entity, pev_animtime, 100.0)
	set_pev(entity, pev_framerate, 1.0)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_JUMP: // Infection Bomb
		{
			infection_explode(entity)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public fw_Touch(w_box)
{
	if (!pev_valid(w_box)) return //HAM_IGNORED
	if (pev(w_box, PEV_NADE_TYPE) != NADE_TYPE_JUMP) return //HAM_IGNORED
	
	
	if(!(pev(w_box, pev_flags)&FL_ONGROUND)){
		emit_sound(w_box, CHAN_WEAPON, sound_bounce[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	//return HAM_HANDLED
}

// Infection Bomb Explosion
infection_explode(ent)
{
	// Round ended
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		// Get rid of the grenade
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	// Get origin
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	// Make the explosion
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]+5)
	write_short(200) // radius
	write_byte(108) // particle color
	write_byte(10) // duration * 10 will be randomized a bit
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]+5)
	write_short(g_expSpr)
	write_byte(25)
	write_byte(35)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	// Infection nade explode sound
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_grenade_infect_explode, random_num(0, ArraySize(g_sound_grenade_infect_explode) - 1), sound, charsmax(sound))
	emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get attacker
	new attacker = pev(ent, pev_owner)
	
	// Infection bomb owner disconnected or not zombie anymore?
	if (!is_user_connected(attacker) || !zp_core_is_zombie(attacker))
	{
		// Get rid of the grenade
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	// Collisions
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		// Only effect alive humans
		if (!is_user_alive(victim))
			continue;
		new i=victim	
		new Float:flVictimOrigin[3]
	        pev(i, pev_origin, flVictimOrigin)
	               
	        new Float:flDistance = get_distance_f (origin, flVictimOrigin)   
	               
	        static Float:flSpeed
		flSpeed = 650.0
	    
	        static Float:flNewSpeed
	        flNewSpeed = flSpeed * (1.0 - (flDistance / 240.0))
	               
	        static Float:flVelocity [3]
	        get_speed_vector(origin, flVictimOrigin, flNewSpeed, flVelocity)
	                       
	        set_pev(i, pev_velocity,flVelocity)
	    
	        message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, i)
	        write_short((1<<12)*4) // amplitude             
	        write_short((1<<12)*10) // duration
	        write_short((1<<12)*10) // frequency
	        message_end()
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
       
	return 1;
}

stock set_weaponlist(id, num=0){
	message_begin(MSG_ONE,get_user_msgid("WeaponList"),_,id)
	write_string(num?WEAPONLIST:"weapon_hegrenade") 
	for(new i=2;i<=9;i++)write_byte(g_wpn_variables[i]) 
	message_end()
}