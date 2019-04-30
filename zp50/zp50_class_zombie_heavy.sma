/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta_util>
#include <fun>
#include <engine>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <amx_settings_api>
#include <zp50_colorchat>
native zp_class_human_get_sex(id)

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Heavy"
new const zombieclass1_info[] = "Traps"
new const zombieclass1_models[][] = { "csobc_heavy" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/heavy/v_knife.mdl" }
const zombieclass1_health = 5000
const Float:zombieclass1_speed = 0.9
const Float:zombieclass1_gravity = 1.1
const Float:zombieclass1_knockback = 0.5

new const spr_trap_catch[][] = { "sprites/csobc/trap_catch.spr" }

new const zombieclass1_trapmodel[][] = { "models/csobc/z/heavy/w_trap.mdl" }
new const sound_trap_set[][] = { "csobc/z/heavy/trap_set.wav" }
new const sound_trap_catch[][] = { "csobc/z/heavy/zombi_trapped.wav", "csobc/z/heavy/zombi_trapped_female.wav" }
const Float:zombieclass1_speed2 = 0.8

#define COOLDOWN_TIME 10.0

new g_ZombieClassID, g_catched[33], Float:g_fCooldown[33], g_HudSync
new Array:g_ZC_TrapSetSound, Array:g_ZC_TrapCatchSound, Array:g_ZC_TrapCatchSpr

public plugin_init()
{
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1)
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	register_clcmd("drop", "clcmd_drop")
	
	register_touch("heavy trap", "player", "touch")
	register_think("heavy trap", "think")
	
	g_HudSync = CreateHudSyncObj()
}

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Light", ZP_VERSION_STRING, "BlackCat")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
		
	g_ZC_TrapSetSound = ArrayCreate(64, 1)
	new buffer[64]
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP SET", g_ZC_TrapSetSound)
	if (ArraySize(g_ZC_TrapSetSound) == 0)
	{
		for (index = 0; index < sizeof sound_trap_set; index++)
			ArrayPushString(g_ZC_TrapSetSound, sound_trap_set[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP SET", g_ZC_TrapSetSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_TrapSetSound); index++)
	{
		ArrayGetString(g_ZC_TrapSetSound, index, buffer, charsmax(buffer))
		precache_sound(buffer)
	}
	
	g_ZC_TrapCatchSound = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP CATCH", g_ZC_TrapCatchSound)
	if (ArraySize(g_ZC_TrapCatchSound) == 0)
	{
		for (index = 0; index < sizeof sound_trap_catch; index++)
			ArrayPushString(g_ZC_TrapCatchSound, sound_trap_catch[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP CATCH", g_ZC_TrapCatchSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_TrapCatchSound); index++)
	{
		ArrayGetString(g_ZC_TrapCatchSound, index, buffer, charsmax(buffer))
		precache_sound(buffer)
	}
	
	g_ZC_TrapCatchSpr = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP CATCH SPR", g_ZC_TrapCatchSpr)
	if (ArraySize(g_ZC_TrapCatchSpr) == 0)
	{
		for (index = 0; index < sizeof spr_trap_catch; index++)
			ArrayPushString(g_ZC_TrapCatchSpr, spr_trap_catch[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "TRAP CATCH SPR", g_ZC_TrapCatchSpr)
	}
	
	for (index = 0; index < ArraySize(g_ZC_TrapCatchSpr); index++)
	{
		ArrayGetString(g_ZC_TrapCatchSpr, index, buffer, charsmax(buffer))
		precache_model(buffer)
	}
	
	precache_model(zombieclass1_trapmodel[0])
}

public plugin_natives()
{
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

public fw_ResetMaxSpeed_Post(id)
{
	// Dead or not frozen
	if (!is_user_alive(id) || !g_catched[id])
		return;
	
	// Prevent from moving
	set_user_maxspeed(id, 1.0)
}

public fw_PlayerPreThink(id)
{
	// Not alive or not frozen
	if (!is_user_alive(id) || !g_catched[id])
		return;
	
	// Stop motion
	set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
}

public clcmd_drop(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	
	new Float:cd=COOLDOWN_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/1.5
	
	g_fCooldown[id]=get_gametime()+cd
	
	new sound[64]
	ArrayGetString(g_ZC_TrapSetSound, random_num(0, ArraySize(g_ZC_TrapSetSound) - 1), sound, charsmax(sound))	
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	create_trap(id)
	return PLUGIN_HANDLED
}

public create_trap(id)
{
	if(!(pev(id,pev_flags)&FL_ONGROUND)){
		return
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return
	
	set_pev(ent, pev_classname, "heavy trap")
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id) 
	set_pev(ent, pev_iuser1, 0) 
	
	engfunc(EngFunc_SetModel, ent, zombieclass1_trapmodel[0])
	new Float:mins[3] = { -10.0, -10.0, 0.0 }
	new Float:maxs[3] = { 10.0, 10.0, 20.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	origin[2] -= (pev(id,pev_flags) & FL_DUCKING) ? 18.0 : 36.0
	engfunc( EngFunc_SetOrigin, ent, origin )
	
	set_pev( ent, pev_frame, 0.0)
        set_pev(ent, pev_framerate, 1.0)
        set_pev(ent, pev_sequence, 0)
        set_pev(ent, pev_animtime, get_gametime())
	
	fm_set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100)
}
new CatchSpr[33]
public touch(ent, id)
{
	new victim = pev(ent, pev_iuser1) 
	if(victim)return
	if(!is_user_connected(id)||!is_user_alive(id)||zp_core_is_zombie(id)) return

	fm_set_rendering(ent, kRenderFxNone, 0,0,0, kRenderNormal, 255)
	set_pev(ent, pev_nextthink, get_gametime() + 8.2)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_sequence, 1)
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_animtime, get_gametime())
	
	set_pev(ent, pev_iuser1, id) 
	
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	origin[2] +=48.0
	
	new catch_spr[64]
	ArrayGetString(g_ZC_TrapCatchSpr, random_num(0, ArraySize(g_ZC_TrapCatchSpr) - 1), catch_spr, charsmax(catch_spr))
	CatchSpr[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!CatchSpr[id]) return
	engfunc(EngFunc_SetModel, CatchSpr[id], catch_spr)
	set_pev(CatchSpr[id], pev_solid, SOLID_NOT)
	set_pev(CatchSpr[id], pev_movetype, MOVETYPE_FLY)
	engfunc(EngFunc_SetOrigin, CatchSpr[id], origin )
	fm_set_rendering(CatchSpr[id], kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	set_pev(CatchSpr[id], pev_scale, 0.5)
	
	pev(id, pev_origin, origin)
	
	origin[2] -= (pev(id,pev_flags) & FL_DUCKING) ? 18.0 : 36.0
	set_pev(ent, pev_origin, origin)
	
	g_catched[id]=true
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	
	new sound[64], sex
	sex=zp_class_human_get_sex(id)
	ArrayGetString(g_ZC_TrapCatchSound, sex>0?1:0, sound, charsmax(sound))	
	emit_sound(ent, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public think(ent)
{
	new victim = pev(ent, pev_iuser1) 
	
	if(is_user_connected(victim)){
		g_catched[victim]=false
		ExecuteHamB(Ham_Player_ResetMaxSpeed, victim)
		
		engfunc(EngFunc_RemoveEntity, CatchSpr[victim])
		CatchSpr[victim]=0
	}
	
	engfunc(EngFunc_RemoveEntity, ent)
}

public client_disconnect(id){
	engfunc(EngFunc_RemoveEntity, CatchSpr[id])
	CatchSpr[id]=0
	remove_task(id+TASK_SHOWHUD)
}

public zp_fw_core_select_post(id){
	ClearSyncHud(id, g_HudSync)
	if ( zp_class_zombie_get_current(id) == g_ZombieClassID)
		set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
	else remove_task(id+TASK_SHOWHUD)
}

public ShowHUD(taskid)
{
	new id=ID_SHOWHUD
	if(get_gametime()<g_fCooldown[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Pulapka^n[Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Pulapka")
}

public zp_fw_core_cure(id, attacker)
{
	remove_task(id+TASK_SHOWHUD)
	ClearSyncHud(id, g_HudSync)
}
