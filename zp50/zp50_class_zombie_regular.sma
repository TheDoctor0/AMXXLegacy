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
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#include <cs_maxspeed_api>
#include <amx_settings_api>
#include <zp50_colorchat>

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// Classic Zombie Attributes
new const zombieclass1_name[] = "Regular"
new const zombieclass1_info[] = "Berserk"
new const zombieclass1_models[][] = { "csobc_regular" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/regular/v_knife.mdl" }
const zombieclass1_health = 3500
const Float:zombieclass1_speed = 1.0
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.0

new const sound_zombie_acast[][] = { "csobc/z/regular/zombi_pressure.wav" }
new const sound_zombie_aidle[][] = { "csobc/z/regular/zombi_pre_idle_1.wav" , "csobc/z/regular/zombi_pre_idle_2.wav" }
const Float:zombieclass1_speed2 = 5.0
#define SKILL_TIME 5.0
#define COOLDOWN_TIME 10.0

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

new g_ZombieClassID, Float:g_fCooldown[33], g_HudSync
new Array:g_ZC_ACastSound, Array:g_ZC_AIdleSound

public plugin_init()
{
	register_clcmd("drop", "clcmd_drop")
	g_HudSync = CreateHudSyncObj()
}

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Regular", ZP_VERSION_STRING, "BlackCat")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
		
	g_ZC_ACastSound = ArrayCreate(64, 1)
	new player_snd[64]
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "BERSERK START", g_ZC_ACastSound)
	if (ArraySize(g_ZC_ACastSound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_acast; index++)
			ArrayPushString(g_ZC_ACastSound, sound_zombie_acast[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "BERSERK START", g_ZC_ACastSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_ACastSound); index++)
	{
		ArrayGetString(g_ZC_ACastSound, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	
	g_ZC_AIdleSound = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "BERSERK IDLE", g_ZC_AIdleSound)
	if (ArraySize(g_ZC_AIdleSound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_aidle; index++)
			ArrayPushString(g_ZC_AIdleSound, sound_zombie_aidle[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "BERSERK IDLE", g_ZC_AIdleSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_AIdleSound); index++)
	{
		ArrayGetString(g_ZC_AIdleSound, index, player_snd, charsmax(player_snd))
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

public clcmd_drop(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID) return PLUGIN_CONTINUE
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || zp_class_nemesis_get(id)) return PLUGIN_CONTINUE
	
	if(get_gametime()<g_fCooldown[id]) {
		client_print(id, print_center, "Ladowanie umiejetnosci! Pozostalo %d sekund.", floatround(g_fCooldown[id]-get_gametime()))
		return PLUGIN_HANDLED
	}
	if(get_user_health(id)-500 < 1){
		zp_colored_print(id, "Nie masz wymaganych 500HP!")
		return PLUGIN_HANDLED
	}
	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME,sounds=1
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0,time=SKILL_TIME*2.0,sounds=3
	new sound[64]
	ArrayGetString(g_ZC_ACastSound, random_num(0, ArraySize(g_ZC_ACastSound) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_fCooldown[id]=get_gametime()+cd+time
	set_user_health(id, get_user_health(id)-500)
	cs_reset_player_maxspeed(id)
	cs_set_player_maxspeed_auto(id, zombieclass1_speed2)
	fm_set_rendering(id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 15)
	set_pdata_int(id,363,110,5)
	set_task(3.0, "ability_sound", id+1,_,_,"a",sounds)
	set_task(time, "ability_end", id)
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
	if(get_gametime()<g_fCooldown[id]) {
		set_hudmessage(255, 255, 0, 0.05, 0.7, 0, 0.1, 1.0, 0.02, 0.02, 1)
		ShowSyncHudMsg(id, g_HudSync, "[G] - Furia^n[Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Furia (-500 HP)")
}
public ability_sound(taskid)
{
	new id=taskid-1
	if(!is_user_connected(id))return
	if(!is_user_alive(id)||!zp_core_is_zombie(id))return
	new sound[64]
	ArrayGetString(g_ZC_AIdleSound, random_num(0, ArraySize(g_ZC_AIdleSound) - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public ability_end(id)
{
	if(!is_user_connected(id))return
	fm_set_rendering(id)
	if(!is_user_alive(id)||!zp_core_is_zombie(id))return
	cs_reset_player_maxspeed(id)
	cs_set_player_maxspeed_auto(id, zombieclass1_speed)
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