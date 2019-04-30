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

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004

#define TASK_FROST_REMOVE 100
#define ID_FROST_REMOVE (taskid - TASK_FROST_REMOVE)

new g_IsFrozen
new g_FrozenRenderingFx[33]
new Float:g_FrozenRenderingColor[33][3]
new g_FrozenRenderingRender[33]
new Float:g_FrozenRenderingAmount[33]

#define TASK_SHOWHUD 1045
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)


// Classic Zombie Attributes
new const zombieclass1_name[] = "Revenant"
new const zombieclass1_info[] = "Ice Ball"
new const zombieclass1_models[][] = { "csobc_revenant" }
new const zombieclass1_clawmodels[][] = { "models/csobc/z/revenant/v_knife.mdl" }
const zombieclass1_health = 1200
const Float:zombieclass1_speed = 0.9
const Float:zombieclass1_gravity = 1.1
const Float:zombieclass1_knockback = 0.5

#define GrenadeModel "models/csobc/z/revenant/ice_ball.mdl"

new g_sprite_grenade_exp[64] = "sprites/csobc/holybomb_exp.spr"

const Float:zombieclass1_speed2 = 0.8

#define COOLDOWN_TIME 60.0

new g_ZombieClassID, Float:g_fCooldown[33], g_HudSync
new g_expSpr

public plugin_init()
{	
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1)
	
	register_clcmd("drop", "clcmd_drop")
	
	register_touch("ice ball", "*", "Touch")
	
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
	
	precache_model(GrenadeModel)
	
	g_expSpr=precache_model(g_sprite_grenade_exp)
	
	precache_sound("warcraft3/frostnova.wav")
	precache_sound("warcraft3/impalehit.wav")
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
	if(zp_core_is_first_zombie(id))cd=COOLDOWN_TIME/1.5
	
	g_fCooldown[id]=get_gametime()+cd
	
	GrenadeAttack(id)
	
	return PLUGIN_HANDLED
}

stock GrenadeAttack(id)
{	
	new Float:Origin[3], Float:AimOrigin[3], Float:Velocity[3], Float:PlayerVelocity[3]

	pev(id, pev_velocity, PlayerVelocity)
	
	new ent=fm_create_entity("info_target")
	
	if(!ent) return

	set_pev(ent, pev_classname, "ice ball")	
	
	set_pev(ent, pev_owner, id)
	
	get_weapon_position(id, Origin, .add_forward=60.0, .add_right=12.0, .add_up=-5.0)
		
	set_pev(ent, pev_origin, Origin)
	
	fm_entity_set_model(ent,GrenadeModel)

	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)

	fm_entity_set_size(ent,Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0})

	set_pev(ent, pev_gravity, 0.8)

	fm_get_aim_origin(id, AimOrigin)

	xs_vec_sub(AimOrigin, Origin, AimOrigin)
	xs_vec_normalize(AimOrigin, Velocity)
	xs_vec_mul_scalar(Velocity, 800.0, Velocity)
	
	vector_to_angle(AimOrigin, AimOrigin)
	 	
	xs_vec_add(Velocity, PlayerVelocity, Velocity)	

	set_pev(ent, pev_angles, AimOrigin)
	set_pev(ent, pev_velocity, Velocity)
}

public Touch(ent, id){
	if(!pev_valid(ent)) return
	
	emit_sound(ent, CHAN_VOICE, "warcraft3/frostnova.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	new victim=FM_NULLENT, Float:Origin[3]

	pev(ent, pev_origin, Origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(350) // radius
	write_byte(244) // particle color
	write_byte(10) // duration * 10 will be randomized a bit
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expSpr)
	write_byte(30)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, 300.0))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			if(1<=victim<=32)
			{
				if(is_user_alive(victim)&&!zp_core_is_zombie(victim))
				{
					 frost(victim)
					 emit_sound(victim, CHAN_VOICE, "warcraft3/impalehit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				}
			}

		}
	}
	engfunc(EngFunc_RemoveEntity, ent)
}

public fw_ResetMaxSpeed_Post(id)
{
	// Dead or not frozen
	if (!is_user_alive(id) || !flag_get(g_IsFrozen, id))
		return;
	
	// Prevent from moving
	set_user_maxspeed(id, 1.0)
}

public frost(id)
{
	flag_set(g_IsFrozen, id)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(FFADE_STAYOUT) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	set_task(3.0, "remove_freeze", id+TASK_FROST_REMOVE)
}

public remove_freeze(taskid)
{	
	flag_unset(g_IsFrozen, ID_FROST_REMOVE)
	
	// Update player's maxspeed
	ExecuteHamB(Ham_Player_ResetMaxSpeed, ID_FROST_REMOVE)

	// Restore rendering
	fm_set_rendering_float(ID_FROST_REMOVE, g_FrozenRenderingFx[ID_FROST_REMOVE], g_FrozenRenderingColor[ID_FROST_REMOVE], g_FrozenRenderingRender[ID_FROST_REMOVE], g_FrozenRenderingAmount[ID_FROST_REMOVE])
	
	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, ID_FROST_REMOVE)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
}

public zp_fw_core_infect_post(id, attacker)
{
	// If frozen, update gravity and rendering
	if (flag_get(g_IsFrozen, id))
	{
		flag_unset(g_IsFrozen, id)
		remove_task(id+TASK_FROST_REMOVE)
	}
}

public client_disconnect(id){
	flag_unset(g_IsFrozen, id)
	remove_task(id+TASK_FROST_REMOVE)
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
		ShowSyncHudMsg(id, g_HudSync, "[G] - Lodowa Kula^n [Gotowe za %ds]", floatround(g_fCooldown[id]-get_gametime()))
		return
	}
	
	set_hudmessage(0, 255, 0, 0.05, 0.7, 0, 0.1, 1.1, 0.02, 0.02, 1)
	ShowSyncHudMsg(id, g_HudSync, "[G] - Lodowa Kula")
}

public zp_fw_core_cure(id, attacker)
{
	remove_task(id+TASK_SHOWHUD)
	ClearSyncHud(id, g_HudSync)
}

// Set entity's rendering type (float parameters version)
stock fm_set_rendering_float(entity, fx = kRenderFxNone, Float:color[3], render = kRenderNormal, Float:amount = 16.0)
{
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, amount)
}

stock get_weapon_position(id, Float:fOrigin[3], Float:add_forward=0.0, Float:add_right=0.0, Float:add_up=0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_v_angle, Angles)
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up,  Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}