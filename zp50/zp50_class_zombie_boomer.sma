/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#include <cs_maxspeed_api>
#include <amx_settings_api>
#include <zp50_colorchat>

native zp_class_zombie_heal(id, heal)

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// Classic Zombie Attributes
new const zombieclass1_name[] = "Boomer"
new const zombieclass1_info[] = "Healing, Hardening"
new const zombieclass1_models[][] = { "csobc_boomer" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/boomer/v_knife.mdl" }
const zombieclass1_health = 4500
const Float:zombieclass1_speed = 0.9
const Float:zombieclass1_gravity = 0.9
const Float:zombieclass1_knockback = 1.5

new const sound_zombie_acast[][] = { "csobc/z/regular/zombi_pressure.wav" }
new const sound_zombie_aidle[][] = { "csobc/z/regular/zombi_pre_idle_1.wav" , "csobc/z/regular/zombi_pre_idle_2.wav" }
new const model_zombie_explode[][]= {"models/csobc/z/boomer/explode.mdl"}
const Float:zombieclass1_speed2 = 5.0
#define SKILL_TIME 5.0
#define COOLDOWN_TIME 25.0

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

new g_ZombieClassID, Float:g_fCooldown[33], Float:g_fCooldown2[33], g_HudSync
new Array:g_ZC_ACastSound, Array:g_ZC_ExplodeModel

public plugin_init()
{
	register_clcmd("drop", "clcmd_drop")
	register_clcmd("radio3", "clcmd_radio")
	g_HudSync = CreateHudSyncObj()
	
	register_think("boomer exp", "fwThink")	
	
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker)||!task_exists(victim))return 
	
	SetHamParamFloat(4, damage/2.0)
}

public fw_PlayerKilled(id, attacker, shouldgib)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return
	
	SetHamParamInteger(3, 2)
	
	exp_effect(id)
}

public exp_effect(id){
	new ent=fm_create_entity("info_target")
	
	if(!ent) return

	set_pev(ent, pev_classname, "boomer exp")	
		
	new Float:Origin[3]
	pev(id, pev_origin, Origin)
		
	set_pev(ent, pev_origin, Origin)
	
	new jump_model[64] 

	ArrayGetString(g_ZC_ExplodeModel, random_num(0, ArraySize(g_ZC_ExplodeModel) - 1), jump_model, charsmax(jump_model))
	
	fm_entity_set_model(ent,jump_model)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_sequence, 1)
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_animtime, get_gametime())
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)

	fm_entity_set_size(ent,Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0})
	
	set_pev(ent, pev_nextthink, get_gametime()+1.0)
	/*
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+90.0)
	write_short(explode_spr)
	write_byte(25)
	write_byte(20)
	write_byte(0)
	message_end()		
	*/
	
	new victim=FM_NULLENT, Float:vOrigin[3], Float:temp, attacker, Float:damage, Float:radius

	attacker=pev(ent, pev_owner)
	
	radius=250.0
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, radius))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			damage=100.0
			
			if(1<=victim<=32)
			{
				if(is_user_alive(victim)&&!zp_core_is_zombie(victim))
				{
					pev(victim, pev_origin, vOrigin)
					
					
					temp=vector_distance(Origin, vOrigin)
					
					xs_vec_normalize(vOrigin, vOrigin)
					xs_vec_mul_scalar(vOrigin, 500.0, vOrigin)
					xs_vec_neg(vOrigin, vOrigin)
					
					vOrigin[2]+=500.0
					
					set_pev(victim, pev_velocity, vOrigin)
		
					if(temp<1.0)temp=1.0
		
					if(temp>radius)temp=radius
						
					damage-=(damage/radius)*temp			

					ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET|DMG_ALWAYSGIB)
				}
			}
			else
				ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET)
		}
	}
}

public fwThink(iEnt){
	if(!pev_valid(iEnt)) 
		return
	
	engfunc(EngFunc_RemoveEntity, iEnt)
}

public plugin_precache()
{
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
		
	g_ZC_ACastSound = ArrayCreate(64, 1)
	new player_snd[64]
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "HARDENING", g_ZC_ACastSound)
	if (ArraySize(g_ZC_ACastSound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_acast; index++)
			ArrayPushString(g_ZC_ACastSound, sound_zombie_acast[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "HARDENING", g_ZC_ACastSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_ACastSound); index++)
	{
		ArrayGetString(g_ZC_ACastSound, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}

	g_ZC_ExplodeModel = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "EXPLODE", g_ZC_ExplodeModel)
	if (ArraySize(g_ZC_ExplodeModel) == 0)
	{
		for (index = 0; index < sizeof model_zombie_explode; index++)
			ArrayPushString(g_ZC_ExplodeModel, model_zombie_explode[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "EXPLODE", g_ZC_ExplodeModel)
	}
	
	for (index = 0; index < ArraySize(g_ZC_ExplodeModel); index++)
	{
		ArrayGetString(g_ZC_ExplodeModel, index, player_snd, charsmax(player_snd))
		precache_model(player_snd)
	}
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

public clcmd_drop(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	if(get_user_health(id) - 500 < 1){
		zp_colored_print(id, "Nie masz wymaganych 500HP!")
		return PLUGIN_HANDLED
	}
	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0,time=SKILL_TIME*2.0
	new sound[64]
	ArrayGetString(g_ZC_ACastSound, random_num(0, ArraySize(g_ZC_ACastSound) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_fCooldown[id]=get_gametime()+cd+time
	
	set_user_health(id, get_user_health(id)-500)

	fm_set_rendering(id, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 15)
	set_pdata_int(id,363,80,5)
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Crosshair"), _, id)
	write_byte(0) 
	message_end()
	set_task(time, "ability_end", id)
	
	play_weapon_animation(id, 2)
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,3.0,4)
	
	return PLUGIN_HANDLED
}

public clcmd_radio(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID)	return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id))	return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown2[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown2[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	if(get_user_health(id) >= 15000){
		zp_colored_print(id, "Osiagnales limit 15000HP!")
		return PLUGIN_HANDLED
	}
	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0,time=SKILL_TIME*2.0
	
	g_fCooldown2[id]=get_gametime()+cd+time
	zp_class_zombie_heal(id, 1000)
	
	play_weapon_animation(id, 2)
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,3.0,4)
	
	return PLUGIN_HANDLED
}

public client_disconnect(id){
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
	if(get_gametime()<g_fCooldown[id]&&get_gametime()<g_fCooldown2[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Hartowanie^n [Gotowe za %ds]^n[C] - Leczenie^n [Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()), floatround(g_fCooldown2[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Hartowanie^n [Gotowe za %ds]^n[C] - Leczenie (+1000 HP)", floatround(g_fCooldown[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown2[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Hartowanie (-500 HP)^n^n[C] - Leczenie^n [Gotowe za %ds]", floatround(g_fCooldown2[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Hartowanie (-500 HP)^n^n[C] - Leczenie (+1000 HP)")
}

public ability_end(id)
{
	if(!is_user_connected(id)||!is_user_alive(id))return
	fm_set_rendering(id)
	set_pdata_int(id,363,90,5)
}

public zp_fw_core_cure(id, attacker)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (task_exists(id)) {
		fm_set_rendering(id)
		remove_task(id)
	}
	
	remove_task(id+TASK_SHOWHUD)
	ClearSyncHud(id, g_HudSync)
}

stock play_weapon_animation(id,sequence)message_begin(MSG_ONE,SVC_WEAPONANIM,_,id),write_byte(sequence),write_byte(0),message_end()