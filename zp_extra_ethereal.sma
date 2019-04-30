#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define WEAPONKEY 33
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)
const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83
#define RELOAD_TIME 3.0
#define wId CSW_UMP45
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1) 
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const Fire_snd[] = {"weapons/ethereal-1.wav"}
new const went[] ={"weapon_ump45"}
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new ethereal_V_MODEL[64] = "models/v_ethereal.mdl"
new ethereal_P_MODEL[64] = "models/p_ethereal.mdl"
new ethereal_W_MODEL[64] = "models/w_ethereal.mdl"
new cvar_recoil_ethereal, cvar_dmg_ethereal, g_itemid_ethereal, cvar_clip_ethereal, cvar_ethereal_ammo
new g_has_ethereal[33], g_hasZoom[33], Float:g_flNextUseTime[33], g_Reload[33] 
new g_MaxPlayers, g_orig_event_ethereal, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_ethereal_TmpClip[33],g_beamSpr,gmsgWeaponList 
public plugin_init()
{
	register_plugin("[ZP] Extra: Ethereal", "1.0", "Zombie-Panic")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, went, "fw_ethereal_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Item_Deploy, went, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_ethereal_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_ethereal_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, went, "ethereal__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, went, "ethereal__Reload");
	RegisterHam(Ham_Weapon_Reload, went, "ethereal__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	RegisterHam(Ham_Item_Holster, "weapon_ump45", "fw_ethereal_Holster_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")

	cvar_recoil_ethereal = register_cvar("zp_Ethereal_recoil", "0.5")
	cvar_dmg_ethereal = register_cvar("zp_Ethereal_dmg", "10")
	cvar_clip_ethereal = register_cvar("zp_Ethereal_clip", "25")
	cvar_ethereal_ammo = register_cvar("zp_Ethereal_ammo", "100")
	g_itemid_ethereal = zp_register_extra_item("Ethereal", 25, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}
public plugin_precache()
{
	precache_model(ethereal_V_MODEL)
	precache_model(ethereal_P_MODEL)
	precache_model(ethereal_W_MODEL)
	precache_sound(Fire_snd)
	precache_sound(Sound_Zoom)
	precache_sound("weapons/ethereal_draw.wav")
	precache_sound("weapons/ethereal_idle1.wav")
	precache_sound("weapons/ethereal_reload.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	g_beamSpr = precache_model("sprites/zbeam4.spr")
	precache_generic("sprites/weapon_ethereal.txt")
	precache_generic("sprites/640hud2.spr")
	precache_generic("sprites/640hud74.spr")
	precache_generic("sprites/640hud7.spr")
	register_clcmd("weapon_ethereal", "Hook_Select")
}

public Hook_Select(id)
{
    engclient_cmd(id, "weapon_ump45")
    return PLUGIN_HANDLED
}


public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ump45.sc", name))
	{
		g_orig_event_ethereal = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(g_Reload[id])
		return PLUGIN_HANDLED

	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)

		if(szWeapID == CSW_UMP45 && g_has_ethereal[id] && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 0)
			emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
		}
		else if(szWeapID == CSW_UMP45 && g_has_ethereal[id] && g_hasZoom[id])
		{
			g_hasZoom[id] = false
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)	
		}
	}
	return PLUGIN_HANDLED
}

public client_connect(id)
{
	g_has_ethereal[id] = false
}
public client_disconnected(id)
{
	g_has_ethereal[id] = false
}public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_ethereal[id] = false
	}
}
public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	if(equal(model, "models/w_ump45.mdl"))
	{
		static iStoredSVDID
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, went, entity)
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
		if(g_has_ethereal[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, WEAPONKEY)
			g_has_ethereal[iOwner] = false
			entity_set_model(entity, ethereal_W_MODEL)
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public give_ethereal(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,went)
	if( iWep2 > 0 )
	{
	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_ethereal))
	cs_set_user_bpammo (id, wId, get_pcvar_num(cvar_ethereal_ammo))
	}
	g_has_ethereal[id] = true;
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_ethereal)
	{
	give_ethereal(id)
	Sprite(id)
	}
}
public fw_ethereal_AddToPlayer(ethereal, id)
{
	if(!is_valid_ent(ethereal) || !is_user_connected(id))
		return HAM_IGNORED;
	if(entity_get_int(ethereal, EV_INT_WEAPONKEY) == WEAPONKEY)
	{
		g_has_ethereal[id] = true
		entity_set_int(ethereal, EV_INT_WEAPONKEY, 0)
		Sprite(id)
		return HAM_HANDLED;
	}
	if(entity_get_int(ethereal, EV_INT_WEAPONKEY) != WEAPONKEY)
	{
		Sprite1(id)
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public Sprite(id)
{
    
    message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
    write_string("weapon_ethereal")  
    write_byte(6)
    write_byte(100)
    write_byte(-1)
    write_byte(-1)
    write_byte(0)
    write_byte(15)
    write_byte(12)
    write_byte(0)
    message_end()

}

public Sprite1(id)
{
    
    message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
    write_string("weapon_ump45")  
    write_byte(6)
    write_byte(100)
    write_byte(-1)
    write_byte(-1)
    write_byte(0)
    write_byte(15)
    write_byte(12)
    write_byte(0)
    message_end()

}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}
public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(owner, weaponid)
	UTIL_PlayWeaponAnimation(owner,2,2)
}
public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))
}
replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case wId:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			if(g_has_ethereal[id])
			{
				set_pev(id, pev_viewmodel2, ethereal_V_MODEL)
				set_pev(id, pev_weaponmodel2, ethereal_P_MODEL)
			}
		}
	}
}
public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
  if(!is_user_alive(Player) || (get_user_weapon(Player) != wId) || !g_has_ethereal[Player])
  return FMRES_IGNORED
  set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
  return FMRES_HANDLED
}
public fw_ethereal_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	if (!g_has_ethereal[Player])
		return;
	pev(Player,pev_punchangle,cl_pushangle[Player])
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	if(g_clip_ammo[Player]>0)
	UTIL_PlayWeaponAnimation(Player, 5,2)
}
public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_ethereal))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}
public fw_ethereal_PrimaryAttack_Post(Weapon)
{	new Player = get_pdata_cbase(Weapon, 41, 4)
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	if(Player > 0 && Player < 33)
	{
	if(g_has_ethereal[Player])
	{
	if(szClip > 0)emit_sound(Player, CHAN_WEAPON, Fire_snd, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	if(g_has_ethereal[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_ethereal),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		if (!g_clip_ammo[Player])
			return
		//show_tracer_effect(Player)
		make_blood_and_bulletholes(Player)
	}
	}
}
public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if( !is_user_alive(iAttacker) || !g_has_ethereal[iAttacker])
		return
	new iWeapon = get_user_weapon(iAttacker)
	if( iWeapon !=CSW_UMP45 )
		return
	
	new szClip
	get_user_weapon(iAttacker, szClip)
	if(szClip < 1)
	return
	new flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMENTPOINT)
	write_short(iAttacker | 0x1000)
	write_coord_f(flEnd[0]) 
	write_coord_f(flEnd[1]) 
	write_coord_f(flEnd[2]) 
	write_short(g_beamSpr)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // life
	write_byte(5)  // width
	write_byte(0)// noise
	write_byte(255)// r, g, b
	write_byte(0)// r, g, b
	write_byte(0)// r, g, b
	write_byte(255)	// brightness
	write_byte(200)	// speed
	message_end()
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == wId)
		{
			if(g_has_ethereal[attacker])
				SetHamParamFloat(10, damage * get_pcvar_float(cvar_dmg_ethereal))
		}
	}
}
stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}
stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence,body)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(body)//pev(Player, pev_body))
	message_end()
}
stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	if(target > 0 && target <= g_MaxPlayers && zp_get_user_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		velocity_by_aim(id, 64, fVel)
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0]))
		write_coord(floatround(fStart[1]))
		write_coord(floatround(fStart[2]))
		write_short( m_iBlood [ 1 ])
		write_short( m_iBlood [ 0 ] )
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
	}
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			write_short(target)
			message_end()
		}
		else
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			message_end()
		}
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
		message_begin(MSG_ALL, SVC_TEMPENTITY) 
		write_byte(TE_SPARKS)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		message_end()
		message_begin(MSG_ALL, SVC_TEMPENTITY) 
		write_byte(TE_SPARKS)
		write_coord(aimOrigin[0]+2)
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		message_end()
		message_begin(MSG_ALL, SVC_TEMPENTITY) 
		write_byte(TE_SPARKS)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1]+2)
		write_coord(aimOrigin[2])
		message_end()
		message_begin(MSG_ALL, SVC_TEMPENTITY) 
		write_byte(TE_SPARKS)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2]+2)
		message_end()
		
	}
}
public ethereal__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_ethereal[id])
		return HAM_IGNORED;
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF)
	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_ethereal) - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, wId, iBpAmmo-j);
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}
	return HAM_IGNORED;
}
public ethereal__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_ethereal[id])
		return HAM_IGNORED;
	g_ethereal_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
	if (iClip >= get_pcvar_num(cvar_clip_ethereal))
		return HAM_SUPERCEDE;
	UTIL_PlayWeaponAnimation(id, 1,2)
	g_ethereal_TmpClip[id] = iClip;
	return HAM_IGNORED;
}
public ethereal__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_ethereal[id])
		return HAM_IGNORED;
	if (g_ethereal_TmpClip[id] == -1)
		return HAM_IGNORED;
	set_pdata_int(weapon_entity, m_iClip, g_ethereal_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, RELOAD_TIME, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(id, m_flNextAttack, RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	UTIL_PlayWeaponAnimation(id, 1,2)
	return HAM_IGNORED;
}
public fw_ethereal_Holster_Post(weapon_entity)
{
	static Player
	Player = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
	
	g_flNextUseTime[Player] = 0.0

	if(g_has_ethereal[Player])
	{
		cs_set_user_zoom(Player, CS_RESET_ZOOM, 1)
	}
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

stock fm_get_aim_vector(index, forward_distance, Float:forward_origin[3], Float:view_end_origin[3])
{
	new Float:start[3], Float:view_ofs[3]
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:vector[3], Float:temp[3];
	pev(index, pev_v_angle, vector);
	engfunc(EngFunc_MakeVectors, vector);
	global_get(glb_v_forward, vector);
	xs_vec_mul_scalar(vector, float(forward_distance), temp);
	xs_vec_add(start, temp, forward_origin);
	
	new Float:dest[3]
	xs_vec_mul_scalar(vector, 9999.0, temp);
	xs_vec_add(start, temp, dest);
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, view_end_origin);
	
	return 1;
}
