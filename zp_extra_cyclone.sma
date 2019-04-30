#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <fun>
#include <zp50_items>
#include <zp50_class_survivor>
#include <zp50_core>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define sfpistol_WEAPONKEY 	625
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

#define WEAPON_NAME		"Cyclone"
#define WEAPON_COST		0

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

#define sfpistol_SHOOT1			1
#define sfpistol_SHOOTEND		2
#define sfpistol_RELOAD			3
#define sfpistol_DRAW			4
#define sfpistol_RELOAD_TIME 2.7
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/sfpistol_shoot5.wav", "weapons/sfpistol_shoot5.wav" }
new const MuzzleFlash[] = "sprites/muzzleflash27.spr"
new sfpistol_V_MODEL[64] = "models/v_sfpistol.mdl"
new sfpistol_P_MODEL[64] = "models/p_sfpistol.mdl"
new sfpistol_W_MODEL[64] = "models/w_sfpistol.mdl"

const m_iShotsFired = 64

new cvar_dmg_sfpistol, cvar_clip_sfpistol, cvar_sfpistol_ammo
new g_MaxPlayers, g_orig_event_sfpistol, g_IsInPrimaryAttack, g_iClip, g_smokepuff_id, g_MuzzleFlash_SprId
new Float:cl_pushangle[MAX_PLAYERS + 1][3]
new g_has_sfpistol[33], g_clip_ammo[33], oldweap[33],g_sfpistol_TmpClip[33], zz[33], udah[33]
new gmsgWeaponList, setrum, g_itemid

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_p228", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("Cyclone", "1.0", "m4m3ts")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_p228", "fw_sfpistol_AddToPlayer")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_p228", "sfpistol_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_p228", "sfpistol_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_p228", "sfpistol_Reload_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p228", "fw_sfpistol_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p228", "fw_sfpistol_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_p228", "fw_cycloneidleanim", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	new const weaponIdentifiers[][] = 
	{
		"weapon_p228"
	}
	
	for( new i = 0; i < sizeof weaponIdentifiers; i++ )
	{
		RegisterHam( Ham_Weapon_PrimaryAttack, weaponIdentifiers[ i ], "Pistols_PrimaryAttack_Pre", false )
	}

	cvar_dmg_sfpistol = register_cvar("zp_sfpistol_dmg", "1.0")
	cvar_clip_sfpistol = register_cvar("zp_sfpistol_clip", "50")
	cvar_sfpistol_ammo = register_cvar("zp_sfpistol_ammo", "200")
		
	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	precache_model(sfpistol_V_MODEL)
	precache_model(sfpistol_P_MODEL)
	precache_model(sfpistol_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/sfpistol_clipin.wav")
	precache_sound("weapons/sfpistol_clipout.wav")
	precache_sound("weapons/sfpistol_draw.wav")
	precache_sound("weapons/sfpistol_idle.wav")
	precache_sound("weapons/sfpistol_shoot_end.wav")
	precache_generic("sprites/weapon_sfpistol.txt")
   	precache_generic("sprites/640hud104.spr")
    	precache_generic("sprites/640hud4.spr")
	register_clcmd("weapon_sfpistol", "weapon_hook")
	setrum = precache_model("sprites/laserbeam.spr")
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/ef_smoke_poison.spr")
	g_MuzzleFlash_SprId = engfunc(EngFunc_PrecacheModel, MuzzleFlash)
	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	
	g_itemid = zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public weapon_hook(id)
{
    engclient_cmd(id, "weapon_p228")
    return PLUGIN_HANDLED
}

public client_putinserver(id)
{	
	new g_Ham_Bot

	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack", 1)
}

public Player_Spawn(id)
{
	if (is_user_alive(id))
	{
		g_has_sfpistol[id] = false
		zz[id] = 0
		udah[id] = 0
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_P228) return
	
	if(!g_has_sfpistol[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
}

public Pistols_PrimaryAttack_Pre(weapon)
{
	new Player = get_pdata_cbase(weapon, 41, 4)
	
	if (!g_has_sfpistol[Player])
		return
		
	set_pdata_int( weapon, m_iShotsFired, -1 );
}

public zp_fw_core_cure_post(id, attacker)
{
	g_has_sfpistol[id] = false
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid != g_itemid)
		return;
		
	give_sfpistol(id)
}

public plugin_natives()
	register_native("zp_give_item_cyclone", "give_sfpistol", 1);

public zp_fw_core_infect_post(id, attacker)
{
	g_has_sfpistol[id] = false
	zz[id] = 0
	udah[id] = 0
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/p228.sc", name))
	{
		g_orig_event_sfpistol = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_sfpistol[id] = false
}

public client_disconnected(id)
{
	g_has_sfpistol[id] = false
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
	
	if(equal(model, "models/w_p228.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_p228", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_sfpistol[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, sfpistol_WEAPONKEY)
			
			g_has_sfpistol[iOwner] = false
			
			entity_set_model(entity, sfpistol_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_sfpistol(id)
{
	drop_weapons(id, 2)
	new iWep2 = fm_give_item(id,"weapon_p228")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_sfpistol))
		cs_set_user_bpammo (id, CSW_P228, get_pcvar_num(cvar_sfpistol_ammo))	
		
		set_weapons_timeidle(id, CSW_P228, 1.0)
		set_player_nextattackx(id, 1.0)
		
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_sfpistol")
		write_byte(1)
		write_byte(52)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(3)
		write_byte(CSW_P228)
		message_end()
	}
	g_has_sfpistol[id] = true
	zz[id] = 0
	udah[id] = 0
}

public setrums(id)
{
	new Float:flAim[3]
	fm_get_aim_origin(id, flAim)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMENTPOINT)
	write_short(id | 0x1000)
	engfunc(EngFunc_WriteCoord, flAim[0])
	engfunc(EngFunc_WriteCoord, flAim[1])
	engfunc(EngFunc_WriteCoord, flAim[2])
	write_short(setrum)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // life
	write_byte(12)  // width
	write_byte(0)// noise
	write_byte(120)// r, g, b
	write_byte(238)// r, g, b
	write_byte(3)// r, g, b
	write_byte(255)	// brightness
	write_byte(255)	// speed
	message_end()
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_P228 || !g_has_sfpistol[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_P228)
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, WEAP_LINUX_XTRA_OFF) > 0.0 || get_pdata_float(ent, 47, WEAP_LINUX_XTRA_OFF) > 0.0) 
		return
		
	if(!(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		if(zz[id] && g_clip_ammo[id])
		{
			zz[id] = 0
			udah[id] = 0
			emit_sound(id, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			UTIL_PlayWeaponAnimation(id, sfpistol_SHOOTEND)
			set_weapons_timeidle(id, CSW_P228, 0.5)
			set_player_nextattackx(id, 0.5)
		}
	}
}

public fw_cycloneidleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_core_is_zombie(id) || !g_has_sfpistol[id] || get_user_weapon(id) != CSW_P228)
		return HAM_IGNORED;

	if(get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, 0)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_sfpistol_AddToPlayer(sfpistol, id)
{
	if(!is_valid_ent(sfpistol) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(sfpistol, EV_INT_WEAPONKEY) == sfpistol_WEAPONKEY)
	{
		g_has_sfpistol[id] = true
		
		entity_set_int(sfpistol, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_sfpistol")
		write_byte(9)
		write_byte(52)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)   
		write_byte(3) 
		write_byte(CSW_P228)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_p228")
		write_byte(9)
		write_byte(52)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(3)
		write_byte(CSW_P228)
		message_end()
	}
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(owner, weaponid)
	zz[owner] = 0
	udah[owner] = 0
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))
	 
     if(read_data(2) != CSW_P228 || !g_has_sfpistol[id])
          return
	 
     static Float:iSpeed
     if(g_has_sfpistol[id])
          iSpeed = 0.075
     
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
		case CSW_P228:
		{
			if (zp_core_is_zombie(id) || zp_class_survivor_get(id))
				return
			
			if(g_has_sfpistol[id])
			{
				set_pev(id, pev_viewmodel2, sfpistol_V_MODEL)
				set_pev(id, pev_weaponmodel2, sfpistol_P_MODEL)
				if(oldweap[id] != CSW_P228) 
				{
					UTIL_PlayWeaponAnimation(id, sfpistol_DRAW)
					set_weapons_timeidle(id, CSW_P228, 1.0)
					set_player_nextattackx(id, 1.0)
					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string("weapon_sfpistol")
					write_byte(9)
					write_byte(52)
					write_byte(-1)
					write_byte(-1)
					write_byte(1)
					write_byte(3)
					write_byte(CSW_P228)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_P228 || !g_has_sfpistol[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_sfpistol_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_sfpistol[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	g_iClip = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_sfpistol) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_sfpistol_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if (g_iClip <= cs_get_weapon_ammo(Weapon))
		return

	if(g_has_sfpistol[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,0.0,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		set_weapons_timeidle(Player, CSW_P228, 0.075)
		set_player_nextattackx(Player, 0.075)
		UTIL_PlayWeaponAnimation(Player, sfpistol_SHOOT1)
		Make_Muzzleflash(Player)
		entity_set_int(Player, EV_INT_sequence, 19)
		zz[Player] = 1
		fake_smoke(Player)
		setrums(Player)
		
		if(!udah[Player])
		{
			emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			udah[Player] = 1
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_P228)
		{
			if(g_has_sfpistol[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_sfpistol))
		}
	}
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

public sfpistol_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_sfpistol[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_sfpistol)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_P228);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 
     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_P228, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public sfpistol_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_sfpistol[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_sfpistol[id])
          iClipExtra = get_pcvar_num(cvar_clip_sfpistol)

     g_sfpistol_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_P228)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_sfpistol_TmpClip[id] = iClip

     return HAM_IGNORED
}

public Make_Muzzleflash(id)
{
	static Float:Origin[3], TE_FLAG
	get_position(id, 32.0, 0.0, -18.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_MuzzleFlash_SprId)
	write_byte(2)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()
}

public sfpistol_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_sfpistol[id])
		return HAM_IGNORED

	if (g_sfpistol_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_sfpistol_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_weapons_timeidle(id, CSW_P228, sfpistol_RELOAD_TIME)
	set_player_nextattackx(id, sfpistol_RELOAD_TIME)
	zz[id] = 0
	udah[id] = 0
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, sfpistol_RELOAD)

	return HAM_IGNORED
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 47, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, WEAP_LINUX_XTRA_OFF)
}

stock fake_smoke(id)
{
	static Float:vecEnd[3], TE_FLAG
	
	fm_get_aim_origin(id, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2]-5)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
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

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
