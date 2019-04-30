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

native zp_class_zombie_heal(id, heal)

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// Classic Zombie Attributes
new const zombieclass1_name[] = "Voodoo"
new const zombieclass1_info[] = "Heal"
new const zombieclass1_models[][] = { "csobc_healer" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/healer/v_knife.mdl" }
const zombieclass1_health = 3500
const Float:zombieclass1_speed = 1.0
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.0

#define COOLDOWN_TIME 20.0

new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

new g_ZombieClassID, Float:g_fCooldown[33], g_HudSync

new g_ring_index,g_heal_index

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
	
	g_ring_index=precache_model("sprites/shockwave.spr")
	g_heal_index=precache_model("sprites/csobc/zombihealer.spr")
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

	new Float:cd=COOLDOWN_TIME
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/2.0
	
	g_fCooldown[id]=get_gametime()+cd
	
	new victim=FM_NULLENT, Float:vOrigin[3]

	pev(id, pev_origin, vOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, vOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, vOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, vOrigin[2]) // z
	engfunc(EngFunc_WriteCoord, vOrigin[0]) // x axis
	engfunc(EngFunc_WriteCoord, vOrigin[1]) // y axis
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 450.0) // z axis
	write_short(g_ring_index) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(10) // life
	write_byte(25) // width
	write_byte(0) // noise
	write_byte(10) // red
	write_byte(200) // green
	write_byte(10) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	new Float:victimOrigin[3]
	while((victim=fm_find_ent_in_sphere(victim, vOrigin, 500.0))!=0)
	{	
		if(is_user_alive(victim)&&zp_core_is_zombie(victim))
		{
			zp_class_zombie_heal(victim, 1500)
			
			pev(victim, pev_origin, victimOrigin)
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, victimOrigin[0])
			engfunc(EngFunc_WriteCoord, victimOrigin[1])
			engfunc(EngFunc_WriteCoord, victimOrigin[2]+20.0)
			write_short(g_heal_index)
			write_byte(10)
			write_byte(15)
			write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
			message_end()
		}
	}
  	
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
		ShowSyncHudMsg(id, g_HudSync, "[G] - Leczenie^n[Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Leczenie (+1500 HP)")
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