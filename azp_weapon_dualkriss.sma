#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <weapon>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define dualkriss_WEAPONKEY 	845
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define dualkriss_RELOAD_TIME 	3.2
#define dualkriss_RELOAD		1
#define dualkriss_DRAW		2
#define dualkriss_SHOOT1		3
#define dualkriss_SHOOT2		4
#define dualkriss_SHOOT3		5

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/dualkriss.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }

new dualkriss_V_MODEL[64] = "models/weapons/v_dualkriss.mdl"
new dualkriss_P_MODEL[64] = "models/p_weapons.mdl"
new dualkriss_W_MODEL[64] = "models/w_weapons.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_dualkriss, cvar_recoil_dualkriss, cvar_clip_dualkriss, cvar_spd_dualkriss, cvar_dualkriss_ammo
new g_MaxPlayers, g_orig_event_dualkriss, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_dualkriss[33], g_clip_ammo[33], g_dualkriss_TmpClip[33], oldweap[33], g_hasZoom[33], Float:g_flNextUseTime[33], g_Reload[33] 
new gmsgWeaponList

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)


public plugin_init()
{
	register_plugin("[ZP] Extra: Dual Kriss Super V", "1.0", "Crock / =) (Poprogun4ik) / LARS-DAY[BR]EAKER")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ump45", "fw_dualkriss_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_dualkriss_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_dualkriss_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_ump45", "dualkriss_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "dualkriss_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "dualkriss_Reload_Post", 1)
	RegisterHam(Ham_Item_Holster, "weapon_ump45", "fw_dualkriss_Holster_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_dualkriss = register_cvar("zp_dualkriss_dmg", "1.2")
	cvar_recoil_dualkriss = register_cvar("zp_dualkriss_recoil", "0.94")
	cvar_clip_dualkriss = register_cvar("zp_dualkriss_clip", "60")
	cvar_spd_dualkriss = register_cvar("zp_dualkriss_spd", "0.98")
	cvar_dualkriss_ammo = register_cvar("zp_dualkriss_ammo", "90")
	
	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	precache_model(dualkriss_V_MODEL)
	precache_model(dualkriss_P_MODEL)
	precache_model(dualkriss_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound(Sound_Zoom)
	precache_sound("weapons/dualkriss_clipin.wav")
	precache_sound("weapons/dualkriss_clipout.wav")
	precache_sound("weapons/dualkriss_draw.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_generic("sprites/weapon_dualkriss.txt")
   	precache_generic("sprites/wpn_sprites/640hud54.spr")
    	precache_generic("sprites/wpn_sprites/640hud7.spr")
	
        register_clcmd("weapon_dualkriss", "weapon_hook")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public plugin_natives()
{
    register_native("give_kriss", "native_give_kriss", 1)
}  

public native_give_kriss(id, player)
{
give_dualkriss(id)        
g_has_dualkriss[player] = true;
}  

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_ump45")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_UMP45) return
	
	if(!g_has_dualkriss[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public zp_user_humanized_post(id)
{
	g_has_dualkriss[id] = false
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ump45.sc", name))
	{
		g_orig_event_dualkriss = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_dualkriss[id] = false
}

public client_disconnect(id)
{
	g_has_dualkriss[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_dualkriss[id] = false
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_ump45.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_ump45", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_dualkriss[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, dualkriss_WEAPONKEY)
			
			g_has_dualkriss[iOwner] = false
			
			entity_set_model(entity, dualkriss_W_MODEL)
			entity_set_int(entity, EV_INT_body, 2)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_dualkriss(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_ump45")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_dualkriss))
		cs_set_user_bpammo (id, CSW_UMP45, get_pcvar_num(cvar_dualkriss_ammo))	
		UTIL_PlayWeaponAnimation(id, dualkriss_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_dualkriss")
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(15)
		write_byte(CSW_UMP45)
		message_end()
	}
	g_has_dualkriss[id] = true
}

public fw_dualkriss_AddToPlayer(dualkriss, id)
{
	if(!is_valid_ent(dualkriss) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(dualkriss, EV_INT_WEAPONKEY) == dualkriss_WEAPONKEY)
	{
		g_has_dualkriss[id] = true
		
		entity_set_int(dualkriss, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_dualkriss")
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(15)
		write_byte(CSW_UMP45)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_ump45")
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(15)
		write_byte(CSW_UMP45)
		message_end()
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_UMP45 || !g_has_dualkriss[id])
          return
     
     static Float:iSpeed
     if(g_has_dualkriss[id])
          iSpeed = get_pcvar_float(cvar_spd_dualkriss)
     
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_UMP45:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_dualkriss[id])
			{
				set_pev(id, pev_viewmodel2, dualkriss_V_MODEL)
				set_pev(id, pev_weaponmodel2, dualkriss_P_MODEL)
				set_pev(id, pev_body, 2)
				if(oldweap[id] != CSW_UMP45) 
				{
					UTIL_PlayWeaponAnimation(id, dualkriss_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

					message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
					write_string("weapon_dualkriss")
					write_byte(6)
					write_byte(100)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(15)
					write_byte(CSW_UMP45)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_UMP45 || !g_has_dualkriss[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_dualkriss_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_dualkriss[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_dualkriss) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || g_Reload[id] || !g_has_dualkriss[id])
		return FMRES_IGNORED
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)

		if(szWeapID == CSW_UMP45 && g_has_dualkriss[id] && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 0)
			emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
		}
		else if(szWeapID == CSW_UMP45 && g_has_dualkriss[id] && g_hasZoom[id])
		{
			g_hasZoom[id] = false
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)	
		}
	}
	return FMRES_IGNORED
}

public fw_dualkriss_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_dualkriss[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_dualkriss),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		new num
		num = random_num(1,2)
		if(num == 1)  UTIL_PlayWeaponAnimation(Player, random_num(dualkriss_SHOOT1,dualkriss_SHOOT3))
		if(num == 2)  UTIL_PlayWeaponAnimation(Player,  dualkriss_SHOOT2)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_UMP45)
		{
			if(g_has_dualkriss[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_dualkriss))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "ump45") && get_user_weapon(iAttacker) == CSW_UMP45)
	{
		if(g_has_dualkriss[iAttacker])
			set_msg_arg_string(4, "ump45")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public dualkriss_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_dualkriss[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_dualkriss)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_UMP45, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
	     g_Reload[id] = 0
     }
     return HAM_IGNORED
}

public dualkriss_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_dualkriss[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_dualkriss[id])
          iClipExtra = get_pcvar_num(cvar_clip_dualkriss)

     g_dualkriss_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_dualkriss_TmpClip[id] = iClip

     return HAM_IGNORED
}

public dualkriss_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_dualkriss[id])
		return HAM_IGNORED

	if (g_dualkriss_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_dualkriss_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, dualkriss_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, dualkriss_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, dualkriss_RELOAD)

	g_Reload[id] = 1

	return HAM_IGNORED
}

public fw_dualkriss_Holster_Post(weapon_entity)
{
	static Player
	Player = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
	
	g_flNextUseTime[Player] = 0.0

	if(g_has_dualkriss[Player])
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