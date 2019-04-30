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
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <amx_settings_api>
#include <zp50_colorchat>
native zp_class_zombie_refresh_mdl(id)

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Light"
new const zombieclass1_info[] = "Invisibility"
new const zombieclass1_models[][] = { "csobc_light" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/light/v_knife.mdl" }
const zombieclass1_health = 1500
const Float:zombieclass1_speed = 1.3
const Float:zombieclass1_gravity = 0.7
const Float:zombieclass1_knockback = 1.2

new const zombieclass1_jumpmodels1[][] = { "models/csobc/z/light/v_jumpbomb_abil.mdl" }
new const zombieclass1_clawmodels1[][] = { "models/csobc/z/light/v_knife_abil.mdl" }
new const sound_zombie_invis[][] = { "csobc/z/light/zombi_pressure.wav" }
const Float:zombieclass1_speed2 = 0.8
#define SKILL_TIME 10.0
#define COOLDOWN_TIME 20.0

new g_ZombieClassID, Float:g_fCooldown[33]
new Array:g_ZC_InvisSound, Array:g_ZC_InvisJump, Array:g_ZC_InvisKnife, g_HudSync

public plugin_init()
{
	register_clcmd("drop", "clcmd_drop")
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
		
	g_ZC_InvisSound = ArrayCreate(64, 1)
	new player_snd[64]
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "INVIS START", g_ZC_InvisSound)
	if (ArraySize(g_ZC_InvisSound) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_invis; index++)
			ArrayPushString(g_ZC_InvisSound, sound_zombie_invis[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "INVIS START", g_ZC_InvisSound)
	}
	
	for (index = 0; index < ArraySize(g_ZC_InvisSound); index++)
	{
		ArrayGetString(g_ZC_InvisSound, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	
	g_ZC_InvisJump = ArrayCreate(64, 1)
	
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "JUMP ABIL", g_ZC_InvisJump)
	if (ArraySize(g_ZC_InvisJump) == 0)
	{
		for (index = 0; index < sizeof zombieclass1_jumpmodels1; index++)
			ArrayPushString(g_ZC_InvisJump, zombieclass1_jumpmodels1[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "JUMP ABIL", g_ZC_InvisJump)
	}
	new player_mdl1[64]
	for (index = 0; index < ArraySize(g_ZC_InvisJump); index++)
	{
		ArrayGetString(g_ZC_InvisJump, index, player_mdl1, charsmax(player_mdl1))
		precache_model(player_mdl1)
	}
	
	g_ZC_InvisKnife = ArrayCreate(64, 1)
	
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "KNIFE ABIL", g_ZC_InvisKnife)
	if (ArraySize(g_ZC_InvisKnife) == 0)
	{
		for (index = 0; index < sizeof zombieclass1_clawmodels1; index++)
			ArrayPushString(g_ZC_InvisKnife, zombieclass1_clawmodels1[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, zombieclass1_name, "KNIFE ABIL", g_ZC_InvisKnife)
	}
	new player_mdl2[64]
	for (index = 0; index < ArraySize(g_ZC_InvisKnife); index++)
	{
		ArrayGetString(g_ZC_InvisKnife, index, player_mdl2, charsmax(player_mdl2))
		precache_model(player_mdl2)
	}
		
	precache_sound("csobc/z/light/zombi_breath.wav")
	precache_sound("csobc/z/light/zombi_laugh.wav")
	precache_sound("csobc/z/light/zombi_headup.wav")
	precache_sound("csobc/z/light/zombi_headdown.wav")
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
	new Float:cd=COOLDOWN_TIME,Float:time=SKILL_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/1.5,time=SKILL_TIME*1.5
	new sound[64]
	ArrayGetString(g_ZC_InvisSound, random_num(0, ArraySize(g_ZC_InvisSound) - 1), sound, charsmax(sound))
	
	new claw_model[64]
	ArrayGetString(g_ZC_InvisKnife, random_num(0, ArraySize(g_ZC_InvisKnife) - 1), claw_model, charsmax(claw_model))
	cs_set_player_view_model(id, CSW_KNIFE, claw_model)
	
	new jump_model[64]
	ArrayGetString(g_ZC_InvisJump, random_num(0, ArraySize(g_ZC_InvisJump) - 1), jump_model, charsmax(jump_model))
	cs_set_player_view_model(id, CSW_HEGRENADE, jump_model)
	
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_fCooldown[id]=get_gametime()+cd+time
	fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,0)
	cs_reset_player_maxspeed(id)
	cs_set_player_maxspeed_auto(id, zombieclass1_speed2)
	set_pdata_int(id,363,110,5)
	set_user_footsteps(id, 1)
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
		ShowSyncHudMsg(id, g_HudSync, "[G] - Niewidzialnosc^n[Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Niewidzialnosc")
}

public ability_end(id)
{
	if(!is_user_connected(id))return
	fm_set_rendering(id)
	set_user_footsteps(id, 0)
	if(!is_user_alive(id)||!zp_core_is_zombie(id))return
	zp_class_zombie_refresh_mdl(id)
	cs_reset_player_maxspeed(id)
	cs_set_player_maxspeed_auto(id, zombieclass1_speed)
	set_pdata_int(id,363,90,5)
}

public zp_fw_core_cure(id, attacker)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (task_exists(id)) fm_set_rendering(id)

	remove_task(id+TASK_SHOWHUD)
	
	ClearSyncHud(id, g_HudSync)
}