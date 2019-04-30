#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_core>

#define PLUGIN "Blood-Dripper"
#define VERSION "1.0"
#define AUTHOR "m4m3ts"

#define CSW_BDRIPPER CSW_MAC10
#define weapon_guillotine "weapon_mac10"
#define old_event "events/mac10.sc"
#define old_w_model "models/w_mac10.mdl"
#define WEAPON_SECRETCODE 1329419

#define WEAPON_NAME		"Blood Dripper"
#define WEAPON_COST		0

#define DEFAULT_AMMO 10
#define DAMAGE 200
#define BDRIP_CLASSNAME "Blood Dripper"
#define WEAPON_ANIMEXT "knife"

#define Get_Ent_Data(%1,%2) get_pdata_int(%1,%2,4)
#define Set_Ent_Data(%1,%2,%3) set_pdata_int(%1,%2,%3,4)

const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

new const v_model[] = "models/v_guillotine.mdl"
new const p_model[] = "models/p_guillotine.mdl"
new const w_model[] = "models/w_guillotine.mdl"
new const KNIFE_MODEL[] = "models/guillotine_projectile.mdl"
new const PECAH_MODEL[] = "models/gibs_guilotine.mdl"
new const hit_wall[] = "weapons/janus9_stone1.wav"
new const hit_wall2[] = "weapons/janus9_stone2.wav"
new const weapon_sound[6][] = 
{
	"weapons/guillotine_catch2.wav",
	"weapons/guillotine_draw.wav",
	"weapons/guillotine_draw_empty.wav",
	"weapons/guillotine_explode.wav",
	"weapons/guillotine_red.wav",
	"weapons/guillotine-1.wav"
}


new const WeaponResource[3][] = 
{
	"sprites/weapon_guillotine.txt",
	"sprites/640hud120.spr",
	"sprites/guillotine_lost.spr"
}

enum
{
	ANIM_IDLE = 0,
	ANIM_IDLE_EMPTY,
	ANIM_SHOOT,
	ANIM_DRAW,
	ANIM_DRAW_EMPTY,
	ANIM_IDLE_SHOOT,
	ANIM_IDLE_SHOOT2,
	ANIM_CATCH,
	ANIM_LOST
}

new g_MsgDeathMsg, g_endround

new g_had_guillotine[33], g_guillotine_ammo[33], shoot_mode[33], shoot_ent_mode[33], g_pecah, headshot_mode[33], ent_sentuh[33], ent_sentuh_balik[33]
new g_old_weapon[33], g_smokepuff_id, m_iBlood[2], guillotine_korban[33], headshot_korban[33], gmsgScoreInfo
new g_itemid

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_think(BDRIP_CLASSNAME, "fw_Think")
	register_touch(BDRIP_CLASSNAME, "*", "fw_touch")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_TraceLine, "fw_traceline", 1)
	register_forward(FM_AddToFullPack, "fm_addtofullpack_post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_guillotine, "fw_guillotineidleanim", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_AddToPlayer, weapon_guillotine, "fw_AddToPlayer_Post", 1)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_clcmd("weapon_guillotine", "hook_weapon")
	
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	gmsgScoreInfo = get_user_msgid("ScoreInfo")
	g_endround = 1
}


public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	precache_model(KNIFE_MODEL)
	g_pecah = precache_model(PECAH_MODEL)
	precache_sound(hit_wall)
	precache_sound(hit_wall2)
	
	for(new i = 0; i < sizeof(weapon_sound); i++) 
		precache_sound(weapon_sound[i])
	
	for(new i = 1; i < sizeof(WeaponResource); i++)
		precache_model(WeaponResource[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, WeaponResource[2])
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	
	g_itemid = zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public zp_fw_core_cure_post(id, attacker)
{
	remove_guillotine(id)
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid != g_itemid)
		return;
		
	get_guillotine(id)
}

public zp_fw_core_infect_post(id, attacker) remove_guillotine(id)

public zp_round_started() g_endround = 0
public zp_round_ended() g_endround = 1

public fw_PlayerKilled(id)
{
	remove_guillotine(id)
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_guillotine)
	return
}

public plugin_natives()
	register_native("zp_give_item_guillotine", "get_guillotine", 1);

public get_guillotine(id)
{
	if(!is_user_alive(id))
		return
	drop_weapons(id, 1)
	g_had_guillotine[id] = 1
	g_guillotine_ammo[id] = DEFAULT_AMMO
	
	give_item(id, weapon_guillotine)
	update_ammo(id)
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_guillotine, id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)
}

public remove_guillotine(id)
{
	g_had_guillotine[id] = 0
}

public refill_guillotine(id)
{	
	if(g_had_guillotine[id]) g_guillotine_ammo[id] = 15
	
	if(get_user_weapon(id) == CSW_BDRIPPER && g_had_guillotine[id]) update_ammo(id)
}
	
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BDRIPPER && g_had_guillotine[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_BDRIPPER && g_had_guillotine[id])
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
		set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
		if(g_old_weapon[id] != CSW_BDRIPPER && g_guillotine_ammo[id] >= 1) set_weapon_anim(id, ANIM_DRAW)
		if(g_old_weapon[id] != CSW_BDRIPPER && g_guillotine_ammo[id] == 0) set_weapon_anim(id, ANIM_DRAW_EMPTY)
		update_ammo(id)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_guillotineidleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_core_is_zombie(id) || !g_had_guillotine[id] || get_user_weapon(id) != CSW_BDRIPPER)
		return HAM_IGNORED;
	
	if(shoot_mode[id] == 0 && g_guillotine_ammo[id] >= 1) 
		return HAM_SUPERCEDE;
	
	if(headshot_mode[id] == 0 && shoot_mode[id] == 1 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		set_weapon_anim(id, ANIM_IDLE_SHOOT)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}
	
	if(headshot_mode[id] == 1 && shoot_mode[id] == 1 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		set_weapon_anim(id, ANIM_IDLE_SHOOT2)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}
	
	if(g_guillotine_ammo[id] == 0 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		set_weapon_anim(id, ANIM_IDLE_EMPTY)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_BDRIPPER || !g_had_guillotine[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_BDRIPPER)
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		if(g_guillotine_ammo[id] == 0)
			return
		if(shoot_mode[id] == 0 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			g_guillotine_ammo[id]--
			update_ammo(id)
			shoot_mode[id] = 1
			FireKnife(id)
			set_weapon_anim(id, ANIM_SHOOT)
			emit_sound(id, CHAN_WEAPON, weapon_sound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_weapons_timeidle(id, CSW_BDRIPPER, 0.7)
			set_player_nextattackx(id, 0.7)
		}
	}
}

public FireKnife(id)
{
	static Float:StartOrigin[3], Float:velocity[3], Float:angles[3], Float:anglestrue[3], Float:jarak_max[3]
	get_position(id, 2.0, 0.0, 0.0, StartOrigin)
	get_position(id, 700.0, 0.0, 0.0, jarak_max)
	
	pev(id,pev_v_angle,angles)
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	anglestrue[0] = 360.0 - angles[0]
	anglestrue[1] = angles[1]
	anglestrue[2] = angles[2]
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_iuser1, id)
	set_pev(Ent, pev_fuser1, get_gametime() + 4.0)
	set_pev(Ent, pev_nextthink, halflife_time() + 0.01)
	
	entity_set_string(Ent, EV_SZ_classname, BDRIP_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, KNIFE_MODEL)
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, anglestrue)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_frame, 1.0)
	set_pev(Ent, pev_framerate, 30.0)
	set_pev(Ent, pev_sequence, 0)
	
	velocity_by_aim( id, 1100, velocity )
	set_pev( Ent, pev_velocity, velocity )
	set_pev(Ent, pev_vuser1, velocity)
	set_pev(Ent, pev_vuser2, jarak_max)
	shoot_ent_mode[id] = 0
	ent_sentuh[id] = 1
	ent_sentuh_balik[id] = 0
}

public fm_addtofullpack_post(es, e, user, host, host_flags, player, p_set)
{
	if(!player)
		return FMRES_IGNORED
		
	if(!is_user_connected(host) || !is_user_alive(user))
		return FMRES_IGNORED
		
	if(!zp_core_is_zombie(user) || headshot_korban[user] != 1)
		return FMRES_IGNORED
		
	if(host == user)
		return FMRES_IGNORED
	
	new Float:PlayerOrigin[3], Float:anglesss[3]
	pev(user, pev_origin, PlayerOrigin)
	
	engfunc(EngFunc_GetBonePosition, user, 8, PlayerOrigin, anglesss)
						
	engfunc(EngFunc_SetOrigin, guillotine_korban[user], PlayerOrigin)
	engfunc(EngFunc_SetOrigin, guillotine_korban[user], PlayerOrigin)

	return FMRES_HANDLED
}

public fw_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return
	
	static Float:pulang[3], Float:StartOriginz[3], pemilix, Float:brangkat[3], Float:jarak_max[3], Float:origin_asli[3], korban
	pemilix = pev(Ent, pev_iuser1)
	pev(Ent, pev_origin, StartOriginz)
	korban = pev(Ent, pev_iuser2)
	
	if(headshot_korban[korban] == 1)
	{
		if(get_gametime() - 0.2 > pev(Ent, pev_fuser3))
		{
			Damage_guillotine(Ent, korban)
			set_pev(Ent, pev_fuser3, get_gametime())
		}
	}
	
	if(ent_sentuh_balik[pemilix] == 0 && shoot_ent_mode[pemilix] == 1)
	{
		ent_sentuh_balik[pemilix] = 1
		pev(pemilix, pev_origin, origin_asli)
		origin_asli[2] += 7.5
	}
	
	if(ent_sentuh[pemilix] == 1)
	{
		ent_sentuh[pemilix] = 0
		pev(Ent, pev_vuser2, jarak_max)
		pev(Ent, pev_vuser1, brangkat)
		get_speed_vector(StartOriginz, origin_asli, 1100.0, pulang)
					
		if(shoot_ent_mode[pemilix] == 1)
		{
			set_pev(Ent, pev_velocity, pulang)
		}
		else set_pev(Ent, pev_velocity, brangkat)
	}
	
	if(shoot_ent_mode[pemilix] == 0 && get_distance_f(StartOriginz, jarak_max) <= 10.0)
	{
		shoot_ent_mode[pemilix] = 1
		ent_sentuh[pemilix] = 1
		set_pev(Ent, pev_owner, 0)
	}
	
	if(shoot_ent_mode[pemilix] == 1 && get_distance_f(StartOriginz, origin_asli) <= 10.0)
	{
		if(is_user_alive(pemilix) && is_user_connected(pemilix) && get_user_weapon(pemilix) == CSW_BDRIPPER && g_had_guillotine[pemilix]) balik(Ent)
		else ancur(Ent)
	}
	else if(headshot_korban[korban] == 1) set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
	else set_pev(Ent, pev_nextthink, halflife_time() + 0.01)
}

public fw_touch(Ent, Id)
{
	// If ent is valid
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
	static classnameptd[32]
	pev(Id, pev_classname, classnameptd, 31)
	if (equali(classnameptd, "func_breakable")) ExecuteHamB( Ham_TakeDamage, Id, 0, 0, 80.0, DMG_GENERIC )
	
	// Get it's origin
	new Float:originF[3], pemilix
	pemilix = pev(Ent, pev_iuser1)
	pev(Ent, pev_origin, originF)
	// Alive...
	
	if(is_user_alive(Id) && zp_core_is_zombie(Id))
	{
		Damage_guillotine(Ent, Id)
		set_pev(Ent, pev_owner, Id)
		ent_sentuh[pemilix] = 1
		create_blood(originF)
		create_blood(originF)
	}
	
	else if(shoot_ent_mode[pemilix] == 1 && Id == pemilix)
	{
		if(is_user_alive(pemilix) && is_user_connected(pemilix) && get_user_weapon(pemilix) == CSW_BDRIPPER && g_had_guillotine[pemilix]) balik(Ent)
		else ancur(Ent)
	}
	
	else if(is_user_alive(Id) && !zp_core_is_zombie(Id))
	{
		set_pev(Ent, pev_owner, Id)
		ent_sentuh[pemilix] = 1
	}
	
	else
	{
		set_pev(Ent, pev_owner, 0)

		if(shoot_ent_mode[pemilix] == 0)
		{
			shoot_ent_mode[pemilix] = 1
			engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, hit_wall, 1.0, ATTN_STATIC, 0, PITCH_NORM)
			ent_sentuh[pemilix] = 1
		}
		else ancur(Ent)
	}
}

public ancur(Ent)
{
	if(!pev_valid(Ent))
		return
	static Float:origin2[3], pemilix, Float:origin3[3]
	pemilix = pev(Ent, pev_iuser1)
	entity_get_vector(Ent, EV_VEC_origin, origin2)
	pev(Ent, pev_origin, origin3)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin2, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, origin2[0])
	engfunc(EngFunc_WriteCoord, origin2[1])
	engfunc(EngFunc_WriteCoord, origin2[2])
	engfunc(EngFunc_WriteCoord, 25)
	engfunc(EngFunc_WriteCoord, 25)
	engfunc(EngFunc_WriteCoord, 25)
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, 5)
	write_byte(5)
	write_short(g_pecah)
	write_byte(10)
	write_byte(17)
	write_byte(0x00)
	message_end()
	
	fake_smokes(origin3)
	engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, hit_wall2, 1.0, ATTN_STATIC, 0, PITCH_NORM)
	shoot_mode[pemilix] = 0
	remove_entity(Ent)
	
	if(!is_user_alive(pemilix) || !is_user_connected(pemilix) || get_user_weapon(pemilix) != CSW_BDRIPPER || !g_had_guillotine[pemilix])
		return
	
	set_weapon_anim(pemilix, ANIM_LOST)
	set_weapons_timeidle(pemilix, CSW_BDRIPPER, 2.5)
	set_player_nextattackx(pemilix, 2.5)
	set_task(1.3, "reload2", pemilix)
	set_task(1.4, "reload", pemilix)
}

public reload(id)
{
	if(!is_user_alive(id) || !is_user_connected(id) || get_user_weapon(id) != CSW_BDRIPPER || !g_had_guillotine[id] || g_guillotine_ammo[id] == 0)
		return
	
	set_weapon_anim(id, ANIM_DRAW)
}

public reload2(id)
{
	if(!is_user_alive(id) || !is_user_connected(id) || get_user_weapon(id) != CSW_BDRIPPER || !g_had_guillotine[id] || g_guillotine_ammo[id] == 0)
		return
	
	set_weapon_anim(id, ANIM_IDLE_SHOOT2)
}

public balik(Ent)
{
	if(!pev_valid(Ent))
		return
	static id
	id = pev(Ent, pev_iuser1)
	set_weapon_anim(id, ANIM_CATCH)
	emit_sound(id, CHAN_WEAPON, weapon_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_weapons_timeidle(id, CSW_BDRIPPER, 1.0)
	set_player_nextattackx(id, 1.0)
	shoot_mode[id] = 0
	g_guillotine_ammo[id]++
	update_ammo(id)
	
	remove_entity(Ent)
}

public Damage_guillotine(Ent, Id)
{
	static Owner; Owner = pev(Ent, pev_iuser1)
	static Attacker; 
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner
	
	if(g_endround)
		return

	new bool:bIsHeadShot; // never make that one static
	new Float:flAdjustedDamage, bool:death
		
	switch( Get_MissileWeaponHitGroup(Ent) ) 
	{
		case HIT_GENERIC: flAdjustedDamage = DAMAGE * 1.0 
		case HIT_STOMACH: flAdjustedDamage = DAMAGE * 1.2 
		case HIT_LEFTLEG, HIT_RIGHTLEG: flAdjustedDamage = DAMAGE * 1.0
		case HIT_LEFTARM, HIT_RIGHTARM: flAdjustedDamage = DAMAGE * 1.0
		case HIT_HEAD, HIT_CHEST:
		{
			flAdjustedDamage = DAMAGE * 3.0
			bIsHeadShot = true
			if(headshot_mode[Owner] == 0) set_task(2.0, "balik_bro", Ent+1858941 )
			headshot_mode[Owner] = 1
			headshot_korban[Id] = 1
			guillotine_korban[Id] = Ent
			set_pev(Ent, pev_iuser2, Id)
			set_pev(Ent, pev_sequence, 1)
			set_pev(Ent, pev_solid, SOLID_NOT)
			set_pev(Ent, pev_fuser3, 0.0)
		}
	}
	if(pev(Id, pev_health) <= flAdjustedDamage) death = true 
	
	if(is_user_alive(Id))
	{
		if( bIsHeadShot && death)
		{
			if(task_exists( Ent+1858941 )) remove_task( Ent + 1858941 )
			set_pev(Ent, pev_sequence, 0)
			headshot_korban[pev(Ent, pev_iuser2)] = 0
			headshot_mode[Owner] = 0
			shoot_ent_mode[Owner] = 1
			ent_sentuh[Owner] = 1
			ent_sentuh_balik[Owner] = 0
			set_pev(Ent, pev_solid, SOLID_BBOX)
			set_pev(Ent, pev_nextthink, halflife_time() + 0.01)
	
			kill(Attacker, Id, 1)
			
			death = false			
		}
		if(death)
		{
			kill(Attacker, Id, 0)
			
			death = false			
		}
		else ExecuteHamB(Ham_TakeDamage, Id, Ent, Attacker, flAdjustedDamage, DMG_BULLET)
	}
}

public balik_bro(Ent)
{
	Ent -= 1858941
	
	if(!pev_valid(Ent))
		return
	
	static pemilix; pemilix = pev(Ent, pev_iuser1)
	set_pev(Ent, pev_sequence, 0)
	headshot_korban[pev(Ent, pev_iuser2)] = 0
	headshot_mode[pemilix] = 0
	shoot_ent_mode[pemilix] = 1
	ent_sentuh[pemilix] = 1
	ent_sentuh_balik[pemilix] = 0
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_nextthink, halflife_time() + 0.01)
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
	
	if(equal(model, old_w_model))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_BDRIPPER)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_guillotine[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_guillotine_ammo[id])
			engfunc(EngFunc_SetModel, entity, w_model)
			
			g_had_guillotine[id] = 0
			g_guillotine_ammo[id] = 0
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_guillotine[id] = 1
		g_guillotine_ammo[id] = pev(ent, pev_iuser4)
		
		set_pev(ent, pev_impulse, 0)
	}			
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string((g_had_guillotine[id] == 1 ? "weapon_guillotine" : "weapon_mac10"))
	write_byte(6)
	write_byte(100)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(13)
	write_byte(CSW_BDRIPPER)
	write_byte(0)
	message_end()
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return

	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BDRIPPER)
	if(!pev_valid(weapon_ent)) return
	
	cs_set_weapon_ammo(weapon_ent, g_guillotine_ammo[id])	
	cs_set_user_bpammo(id, CSW_BDRIPPER, g_guillotine_ammo[id])
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BDRIPPER)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_guillotine_ammo[id])
	message_end()
}

public fw_traceline(Float:v1[3],Float:v2[3],noMonsters,id,ptr)
{
	if(!is_user_alive(id))
		return HAM_IGNORED	
	if(get_user_weapon(id) != CSW_BDRIPPER || !g_had_guillotine[id])
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

public fake_smokes(Float:Origin[3])
{
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_smokepuff_id)
	write_byte(6)
	write_byte(25)
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

stock kill(k, v, headshot)
{
	cs_set_user_money(k, cs_get_user_money(k) + 500)
	
	set_user_frags(k, get_user_frags(k) + 1)
	
	set_msg_block(g_MsgDeathMsg,BLOCK_ONCE)
	set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
	user_kill(v,1)
	
	new kteam = get_user_team(k);
	new vteam = get_user_team(v);
	
	new kfrags = get_user_frags(k);
	new kdeaths = get_user_deaths(k);
	
	new vfrags = get_user_frags(v);
	new vdeaths = get_user_deaths(v);
	
	emessage_begin(MSG_ALL, gmsgScoreInfo);
	ewrite_byte(k);
	ewrite_short(kfrags);
	ewrite_short(kdeaths);
	ewrite_short(0);
	ewrite_short(kteam);
	emessage_end();
	
	emessage_begin(MSG_ALL, gmsgScoreInfo);
	ewrite_byte(v);
	ewrite_short(vfrags);
	ewrite_short(vdeaths);
	ewrite_short(0);
	ewrite_short(vteam);
	emessage_end();
	
	emessage_begin(MSG_BROADCAST, g_MsgDeathMsg)
	ewrite_byte(k)
	ewrite_byte(v)
	ewrite_byte(headshot)
	ewrite_string("Blood Dripper")
	emessage_end()
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

stock Get_MissileWeaponHitGroup( iEnt )
{
	new Float:flStart[ 3 ], Float:flEnd[ 3 ];
	
	pev( iEnt, pev_origin, flStart );
	pev( iEnt, pev_velocity, flEnd );
	xs_vec_add( flStart, flEnd, flEnd );
	
	new ptr = create_tr2();
	engfunc( EngFunc_TraceLine, flStart, flEnd, 0, iEnt, ptr );
	
	new iHitGroup, Owner, nOhead, head
	Owner = pev(iEnt, pev_iuser1)
	nOhead = get_tr2( ptr, TR_iHitgroup )
	head = set_tr2( ptr, TR_iHitgroup, HIT_HEAD )
	
	iHitGroup = headshot_mode[Owner] ? head : nOhead
	
	free_tr2( ptr );
	
	return iHitGroup;
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

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 48, TimeIdle + 0.2, OFFSET_LINUX_WEAPONS)
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
