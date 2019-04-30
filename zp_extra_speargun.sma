#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zp50_items>
#include <zp50_gamemodes>

#define PLUGIN "Spear Gun"
#define VERSION "1.0"
#define AUTHOR "m4m3ts"

#define WEAPON_NAME		"Spear Gun"
#define WEAPON_COST		0

const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

new const v_model[] = "models/v_speargun.mdl"
new const p_model[] = "models/p_speargun.mdl"
new const w_model[] = "models/w_speargun.mdl"
new const ARROW_MODEL[] = "models/spear.mdl"
new const GRENADE_EXPLOSION[] = "sprites/fexplo.spr"
new const speargun_wall[] = "weapons/speargun_metal2.wav"
new const speargun_hit[] = "weapons/speargun_stone1.wav"
new const sound[3][] = 
{
	"weapons/speargun-1.wav",
	"weapons/speargun_clipin.wav",
	"weapons/speargun_draw.wav"
}


new const sprite[3][] = 
{
	"sprites/weapon_speargun.txt",
	"sprites/640hud103.spr",
	"sprites/640hud400.spr"
}

enum
{
	IDLE = 0,
	SHOOT,
	RELOAD,
	DRAW,
	DRAW_EMPTY,
	IDLE_EMPTY
}

new sExplo, g_MaxPlayers, Ent, g_ready, g_rightclick
new g_had_speargun[33], g_speargun_ammo[33]
new g_old_weapon[33], g_smokepuff_id, m_iBlood[2]
new sTrail, g_itemid, cvar_dmg1_spear, cvar_dmg2_spear, cvar_ammo_spear

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_forward(FM_SetModel, "fw_SetModel")
	register_touch("spear_arrow", "*", "fw_touch2")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_TraceLine,"fw_traceline",1)
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_galil", "fw_speargunidleanim", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer_Post", 1)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	cvar_dmg1_spear = register_cvar("zp_dmg1_spear", "400.0")
	cvar_dmg2_spear = register_cvar("zp_dmg2_spear", "600.0")
	cvar_ammo_spear = register_cvar("zp_spear_ammo", "40")
	
	register_clcmd("weapon_speargun", "hook_weapon")
	
	g_MaxPlayers = get_maxplayers()	
}


public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	precache_model(ARROW_MODEL)
	precache_sound(speargun_wall)
	precache_sound(speargun_hit)
	
	for(new i = 0; i < sizeof(sound); i++) 
		precache_sound(sound[i])
		
	for(new i = 1; i < sizeof(sprite); i++)
		precache_model(sprite[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	sExplo = precache_model(GRENADE_EXPLOSION)
	sTrail = precache_model("sprites/laserbeam.spr")
	
	g_itemid = zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public zp_fw_core_cure_post(id, attacker)
{
	remove_speargun(id)
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid != g_itemid)
		return;
		
	get_speargun(id)
}

public zp_fw_core_infect_post(id, attacker) remove_speargun(id)

public hook_weapon(id)
{
	engclient_cmd(id, "weapon_galil")
	return
}

public fw_PlayerKilled(id)
{
	remove_speargun(id)
}

public plugin_natives()
	register_native("zp_give_item_speargun", "get_speargun", 1);

public get_speargun(id)
{
	if(!is_user_alive(id))
		return
	drop_weapons(id, 1)
	g_had_speargun[id] = 1
	g_ready = 0
	g_rightclick = 0
	g_speargun_ammo[id] = get_pcvar_num(cvar_ammo_spear)
	
	fm_give_item(id, "weapon_galil")
	update_ammo(id)
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_galil", id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_GALIL)
	{
		if(g_had_speargun[iAttacker])
			set_msg_arg_string(4, "Spear Gun")
	}
                
	return PLUGIN_CONTINUE
}

public remove_speargun(id)
{
	g_had_speargun[id] = 0
	g_speargun_ammo[id] = 0
}
	
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_GALIL && g_had_speargun[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_GALIL && g_had_speargun[id])
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
		remove_task(id)
		if(g_old_weapon[id] != CSW_GALIL && g_speargun_ammo[id] >= 1) set_weapon_anim(id, DRAW)
		if(g_old_weapon[id] != CSW_GALIL && g_speargun_ammo[id] == 0) set_weapon_anim(id, DRAW_EMPTY)
		update_ammo(id)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_speargunidleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_core_is_zombie(id) || !g_had_speargun[id] || get_user_weapon(id) != CSW_GALIL)
		return HAM_IGNORED;

	if(g_speargun_ammo[id] >= 1) 
		return HAM_SUPERCEDE;
	
	if(g_speargun_ammo[id] == 0 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		set_weapon_anim(id, IDLE_EMPTY)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_GALIL || !g_had_speargun[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_GALIL)
	if(!pev_valid(ent))
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
			return
			
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		if(g_speargun_ammo[id] == 0)
			return
		if(get_pdata_float(id, 83, 5) <= 0.0)
		{
			FireArrow_Charge(id)
			g_ready = 1
			g_speargun_ammo[id]--
			update_ammo(id)
			set_weapons_timeidle(id, CSW_GALIL, 2.2)
			set_player_nextattackx(id, 2.2)
			if(g_speargun_ammo[id] >= 1)
			{
				set_weapon_anim(id, SHOOT)
				emit_sound(id, CHAN_WEAPON, sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_task(1.0, "reloadspear", id)
			}
			else
			{
				set_weapon_anim(id, SHOOT)
				emit_sound(id, CHAN_WEAPON, sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		}
	}
	else if(CurButton & IN_ATTACK2)
	{
		if(g_ready)
		{
			CurButton &= ~IN_ATTACK2
			set_uc(uc_handle, UC_Buttons, CurButton)
		
			remove_task(Ent)
			g_rightclick = 1
			explode(Ent)
		}
	}
}


public reloadspear(id)
{
	if(get_user_weapon(id) != CSW_GALIL || !g_had_speargun[id])
		return
	
	set_weapon_anim(id, RELOAD)
}

public FireArrow_Charge(id)
{
	static Float:StartOrigin[3], Float:TargetOrigin[3], Float:angles[3], Float:angles_fix[3]
	get_position(id, 2.0, 0.0, 0.0, StartOrigin)

	pev(id,pev_v_angle,angles)
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	angles_fix[0] = 360.0 - angles[0]
	angles_fix[1] = angles[1]
	angles_fix[2] = angles[2]
	set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(Ent, pev_owner, id)
	
	entity_set_string(Ent, EV_SZ_classname, "spear_arrow")
	engfunc(EngFunc_SetModel, Ent, ARROW_MODEL)
	set_pev(Ent, pev_mins,{ -0.1, -0.1, -0.1 })
	set_pev(Ent, pev_maxs,{ 0.1, 0.1, 0.1 })
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, angles_fix)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_frame, 0.0)
	
	static Float:Velocity[3]
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(StartOrigin, TargetOrigin, 1500.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(Ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(7) // Life
	write_byte(1) // Line width
	write_byte(10)
	write_byte(229)
	write_byte(255)
	write_byte(100) // Alpha
	message_end() 
}

public fw_touch2(Ent, Id)
{
	// If ent is valid
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
		
	static Owner; Owner = pev(Ent, pev_owner)
	
	static classnameptd[32]
	pev(Id, pev_classname, classnameptd, 31)
	if (equali(classnameptd, "func_breakable")) ExecuteHamB( Ham_TakeDamage, Id, 0, 0, 300.0, DMG_GENERIC )
	
	// Get it's origin
	new Float:originF[3]
	pev(Ent, pev_origin, originF)
	// Alive...

	if(is_user_alive(Id) && get_user_team(Id) != get_user_team(Owner))
	{
		set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(Ent, pev_solid, SOLID_NOT)
		set_pev(Ent, pev_aiment, Id)
		create_blood(originF)
		create_blood(originF)
		set_task(1.0, "explode", Ent)
		engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, speargun_hit, 1.0, ATTN_STATIC, 0, PITCH_NORM)
		
		static Float:MyOrigin[3]
		pev(Owner, pev_origin, MyOrigin)
		
		hook_ent2(Id, MyOrigin, 500.0, 2)
	}
	else
	{
		engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, speargun_wall, 1.0, ATTN_STATIC, 0, PITCH_NORM)
		set_pev(Ent, pev_movetype, MOVETYPE_NONE)
		set_pev(Ent, pev_solid, SOLID_NOT)
		make_bullet(Owner, originF)
		fake_smokes(Owner, originF)
		set_task(1.0, "explode", Ent)
	}
}

public explode(Ent)
{
	new Float:originZ[3], Float:originX[3]
	pev(Ent, pev_origin, originX)
	entity_get_vector(Ent, EV_VEC_origin, originZ)
	// Draw explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, originX[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, originX[1])
	engfunc(EngFunc_WriteCoord, originX[2]+30.0)
	write_short(sExplo) // Sprite index
	write_byte(20) // Scale
	write_byte(200) // Framerate
	write_byte(0) // Flags
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originZ, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, originZ[0]) // x
	engfunc(EngFunc_WriteCoord, originZ[1]) // y
	engfunc(EngFunc_WriteCoord, originZ[2]) // z
	write_short(30) // radius
	write_byte(0) // color
	write_byte(1) // duration (will be randomized a bit)
	message_end()
	
	Damage_spear(Ent)
	remove_entity(Ent)
	
	g_ready = 0
}

public Damage_spear(Ent)
{
	static Owner; Owner = pev(Ent, pev_owner)
	static Attacker
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner

	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, Ent) > 100.0)
			continue
		if(get_user_team(i) == get_user_team(Owner))
			continue
		if(!g_rightclick) ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, get_pcvar_float(cvar_dmg1_spear), DMG_BULLET)
		else ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, get_pcvar_float(cvar_dmg2_spear), DMG_BULLET)
		
		static Float:v_Velocity[3], Float:ori_Velocity[3]
		pev(i, pev_velocity, ori_Velocity)
		v_Velocity[0] = ori_Velocity[0]
		v_Velocity[1] = ori_Velocity[1]
		v_Velocity[2] = 230.0
		entity_set_vector(i, EV_VEC_velocity, v_Velocity)
		g_rightclick = 0
	}
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, Ent) > 200.0)
			continue
		if(!g_had_speargun[i])
			continue
		if(i != Owner)
			continue
			
		static Float:v_Velocity[3], Float:ori_Velocity[3]
		pev(i, pev_velocity, ori_Velocity)
		v_Velocity[0] = ori_Velocity[0]
		v_Velocity[1] = ori_Velocity[1]
		v_Velocity[2] = 250.0
		entity_set_vector(i, EV_VEC_velocity, v_Velocity)
	}
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, "models/w_galil.mdl"))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_GALIL)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_speargun[id])
		{
			set_pev(weapon, pev_impulse, 19391)
			set_pev(weapon, pev_iuser4, g_speargun_ammo[id])
			engfunc(EngFunc_SetModel, entity, w_model)
			
			g_had_speargun[id] = 0
			g_speargun_ammo[id] = 0
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == 19391)
	{
		g_had_speargun[id] = 1
		g_speargun_ammo[id] = pev(ent, pev_iuser4)
		
		set_pev(ent, pev_impulse, 0)
	}			
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string((g_had_speargun[id] == 1 ? "weapon_speargun" : "weapon_galil"))
	write_byte(1)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(17)
	write_byte(CSW_GALIL)
	write_byte(0)
	message_end()
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_galil", id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)	
	
	cs_set_user_bpammo(id, CSW_GALIL, 0)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GALIL)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_speargun_ammo[id])
	message_end()
}

public fw_traceline(Float:v1[3],Float:v2[3],noMonsters,id,ptr)
{
	if(!is_user_alive(id))
		return HAM_IGNORED	
	if(get_user_weapon(id) != CSW_GALIL || !g_had_speargun[id])
		return HAM_IGNORED

	// get crosshair aim
	static Float:aim[3];
	get_aim(id,v1,aim);
	
	// do another trace to this spot
	new trace = create_tr2();
	engfunc(EngFunc_TraceLine,v1,aim,noMonsters,id,trace);
	
	// copy ints
	set_tr2(ptr,TR_AllSolid,get_tr2(trace,TR_AllSolid));
	set_tr2(ptr,TR_StartSolid,get_tr2(trace,TR_StartSolid));
	set_tr2(ptr,TR_InOpen,get_tr2(trace,TR_InOpen));
	set_tr2(ptr,TR_InWater,get_tr2(trace,TR_InWater));
	set_tr2(ptr,TR_pHit,get_tr2(trace,TR_pHit));
	set_tr2(ptr,TR_iHitgroup,get_tr2(trace,TR_iHitgroup));

	// copy floats
	get_tr2(trace,TR_flFraction,aim[0]);
	set_tr2(ptr,TR_flFraction,aim[0]);
	get_tr2(trace,TR_flPlaneDist,aim[0]);
	set_tr2(ptr,TR_flPlaneDist,aim[0]);
	
	// copy vecs
	get_tr2(trace,TR_vecEndPos,aim);
	set_tr2(ptr,TR_vecEndPos,aim);
	get_tr2(trace,TR_vecPlaneNormal,aim);
	set_tr2(ptr,TR_vecPlaneNormal,aim);

	// get rid of new trace
	free_tr2(trace);

	return FMRES_IGNORED;
}

get_aim(id,Float:source[3],Float:ret[3])
{
	static Float:vAngle[3], Float:pAngle[3], Float:dir[3], Float:temp[3];

	// get aiming direction from forward global based on view angle and punch angle
	pev(id,pev_v_angle,vAngle);
	pev(id,pev_punchangle,pAngle);
	xs_vec_add(vAngle,pAngle,temp);
	engfunc(EngFunc_MakeVectors,temp);
	global_get(glb_v_forward,dir);
	
	/* vecEnd = vecSrc + vecDir * flDistance; */
	xs_vec_mul_scalar(dir,8192.0,temp);
	xs_vec_add(source,temp,ret);
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
	}
}

public fake_smokes(id, Float:Origin[3])
{
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(80)
	write_byte(TE_FLAG)
	message_end()
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(8)
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	 
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		  
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = 100.0
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
		} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}
	
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
