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

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// Classic Zombie Attributes
new const zombieclass1_name[] = "Sting Finger"
new const zombieclass1_info[] = "Penetration, High Jump"
new const zombieclass1_models[][] = { "csobc_resident" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/resident/v_knife.mdl" }
const zombieclass1_health = 2500
const Float:zombieclass1_speed = 1.1
const Float:zombieclass1_gravity = 0.9
const Float:zombieclass1_knockback = 1.5

new const sound_zombie_skill1[][] = { "csobc/z/resident/skill1.wav" }
new const sound_zombie_skill2[][] = { "csobc/z/resident/skill2.wav" }
const Float:zombieclass1_gravity1 = 0.5
#define SKILL_TIME 20.0
#define COOLDOWN_TIME 240.0

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

new g_ZombieClassID, Float:g_fCooldown[33], Float:g_fCooldown2[33], g_HudSync
new Array:g_ZC_Skill1Sound, Array:g_ZC_Skill2Sound

public plugin_init()
{
	register_clcmd("radio3", "clcmd_radio")
	register_clcmd("drop", "clcmd_drop")
	g_HudSync = CreateHudSyncObj()
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
		
	g_ZC_Skill1Sound = ArrayCreate(64, 1)
	new player_snd[64]
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "PENETRATION", g_ZC_Skill1Sound)
	if (ArraySize(g_ZC_Skill1Sound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_skill1; index++)
			ArrayPushString(g_ZC_Skill1Sound, sound_zombie_skill1[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "PENETRATION", g_ZC_Skill1Sound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_Skill1Sound); index++)
	{
		ArrayGetString(g_ZC_Skill1Sound, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	
	g_ZC_Skill2Sound = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "HIGH JUMP", g_ZC_Skill2Sound)
	if (ArraySize(g_ZC_Skill2Sound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_skill2; index++)
			ArrayPushString(g_ZC_Skill2Sound, sound_zombie_skill2[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "HIGH JUMP", g_ZC_Skill2Sound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_Skill2Sound); index++)
	{
		ArrayGetString(g_ZC_Skill2Sound, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
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

public clcmd_radio(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown[id]-get_gametime()))
		return PLUGIN_HANDLED
	}

	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0,time=SKILL_TIME*2.0
	new sound[64]
	ArrayGetString(g_ZC_Skill2Sound, random_num(0, ArraySize(g_ZC_Skill2Sound) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_fCooldown[id]=get_gametime()+cd+time
	
	set_user_gravity(id, zombieclass1_gravity1)
	
	set_task(time, "ability_end", id)
	
	play_weapon_animation(id, 9)
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,3.5,4)
	
	return PLUGIN_HANDLED
}

public clcmd_drop(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown2[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown2[id]-get_gametime()))
		return PLUGIN_HANDLED
	}

	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0,time=SKILL_TIME*2.0
	
	new sound[64]
	ArrayGetString(g_ZC_Skill1Sound, random_num(0, ArraySize(g_ZC_Skill1Sound) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	g_fCooldown2[id]=get_gametime()+cd+time
	
	new target, body
	static Float:start[3]
	static Float:aim[3]
	
	pev(id, pev_origin, start)
	fm_get_aim_origin(id, aim)
	
	start[2] += 16.0; // raise
	aim[2] += 16.0; // raise
	get_user_aiming ( id, target, body, 400)
	
	if( is_user_alive( target ) && !zp_core_is_zombie( target ) && !get_user_armor(id))
		zp_core_infect(target, id)
	
	play_weapon_animation(id, 8)
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
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Penetracja^n [Gotowe za %ds]^n[C] - Wysoki Skok^n [Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()), floatround(g_fCooldown2[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Penetracja^n [Gotowe za %ds]^n[C] - Wysoki Skok", floatround(g_fCooldown[id]-get_gametime()))
		return
	} else if(get_gametime()<g_fCooldown2[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Penetracja^n^n[C] - Wysoki Skok^n [Gotowe za %ds]", floatround(g_fCooldown2[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Penetracja^n^n[C] - Wysoki Skok")
}

public ability_end(id)
{
	if(!is_user_connected(id)||!is_user_alive(id)||!zp_core_is_zombie(id))return
	set_user_gravity(id, zombieclass1_gravity)
	play_weapon_animation(id, 10)
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(pev_valid(weapon_ent)) set_pdata_float(weapon_ent,48,3.0,4)
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