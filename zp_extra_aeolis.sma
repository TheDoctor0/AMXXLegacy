#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zp50_items>
#include <zp50_gamemodes>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define spmg_WEAPONKEY 		807
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

#define WEAPON_NAME		"Aeolis"
#define WEAPON_COST		0

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

#define spmg_RELOAD_TIME	4.5
#define spmg_SHOOT1		1
#define spmg_SHOOT2		2
#define spmg_RELOAD		3
#define spmg_DRAW		4

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/spmg-1.wav" }

new spmg_V_MODEL[64] = "models/v_spmg.mdl"
new spmg_P_MODEL[64] = "models/p_spmg.mdl"
new spmg_W_MODEL[64] = "models/w_spmg.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_spmg, cvar_recoil_spmg, cvar_clip_spmg, cvar_spd_spmg, cvar_spmg_ammo, cvar_dmg_fire, cvar_dmg_afterburn
new g_MaxPlayers, g_orig_event_spmg, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_spmg[33], g_clip_ammo[33], g_spmg_TmpClip[33], oldweap[33], pusss[33], fireammo[33], g_SpecialAmmo[33]
new gmsgWeaponList, g_smokepuff_id, g_itemid

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin("[ZP] Extra item: Aeolis", "1.0", "m4m3ts")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_spmg_AddToPlayer")
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_spmg_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_spmg_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "spmg_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "spmg_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "spmg_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_think("fire", "fw_Fire_Think")
	register_think("fire_burn", "fw_FireBurn_Think")
	register_touch("fire", "*", "fw_Fire_Touch")
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

	cvar_dmg_spmg = register_cvar("zp_spmg_dmg", "1.08")
	cvar_recoil_spmg = register_cvar("zp_spmg_recoil", "1.04")
	cvar_clip_spmg = register_cvar("zp_spmg_clip", "125")
	cvar_spd_spmg = register_cvar("zp_spmg_spd", "0.11")
	cvar_spmg_ammo = register_cvar("zp_spmg_ammo", "200")
	cvar_dmg_fire = register_cvar("zp_fire_dmg", "35")
	cvar_dmg_afterburn = register_cvar("zp_afterburn_dmg", "100")
	
	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	precache_model(spmg_V_MODEL)
	precache_model(spmg_P_MODEL)
	precache_model(spmg_W_MODEL)
	precache_model("sprites/flame_puff01.spr")
	precache_model("sprites/flame_burn01.spr")
	g_smokepuff_id = precache_model("sprites/xsmoke4.spr")
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/spmg_clipin1.wav")
	precache_sound("weapons/spmg_clipin2.wav")
	precache_sound("weapons/spmg_clipin3.wav")
	precache_sound("weapons/spmg_clipout1.wav")
	precache_sound("weapons/spmg_draw.wav")
	precache_sound("weapons/spmg_idle2.wav")
	precache_sound("weapons/flamegun-1.wav")
	precache_sound("weapons/steam.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_generic("sprites/weapon_spmg.txt")
	precache_generic("sprites/640hud106.spr")
	precache_generic("sprites/640hud2.spr")
	
	register_clcmd("weapon_spmg", "weapon_hook")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	
	g_itemid = zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_m249")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M249) return
	
	if(!g_has_spmg[iAttacker]) return

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

public zp_fw_core_cure_post(id, attacker)
{
	remove_spmg(id)
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid != g_itemid)
		return;
		
	give_weapon(id)
}

public zp_fw_core_infect_post(id, attacker) remove_spmg(id)

public client_putinserver(id)
{
	new g_ham_bot
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_spmg = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	remove_spmg(id)
}

public remove_spmg(id)
{
	g_has_spmg[id] = false
	pusss[id] = 0
	fireammo[id] = 0
	g_SpecialAmmo[id] = 0
	update_specialammo(id, g_SpecialAmmo[id], 0)
}

public client_disconnected(id)
{
	remove_spmg(id)
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
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m249", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_spmg[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, spmg_WEAPONKEY)
			
			g_has_spmg[iOwner] = false
			
			entity_set_model(entity, spmg_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public plugin_natives()
	register_native("zp_give_item_aeolis", "give_weapon", 1);
public give_weapon(id)
{
	if(!is_user_alive(id))
		return
		
	drop_weapons(id, 1)
	remove_spmg(id)
	
	g_has_spmg[id] = true
	pusss[id] = 0
	fireammo[id] = 0
	g_SpecialAmmo[id] = 0
	
	fm_give_item(id, "weapon_m249")
	cs_set_user_bpammo (id, CSW_M249, get_pcvar_num(cvar_spmg_ammo))
	
	static weapon
	weapon = fm_get_user_weapon_entity(id, CSW_M249)
	cs_set_weapon_ammo(weapon, get_pcvar_num(cvar_clip_spmg))
	
	update_ammo(id)
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_M249)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_M249)
	write_byte(cs_get_weapon_ammo(weapon_ent))
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(cs_get_user_bpammo(id, CSW_M249))
	message_end()
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_M249 || !g_has_spmg[id])
		return FMRES_IGNORED
		
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK2)
	{
		if(fireammo[id] >= 3 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			static Weapon; Weapon = fm_get_user_weapon_entity(id, CSW_M249)
			UTIL_PlayWeaponAnimation(id, 2)
			
			static Float:Origin[3], Float:TargetOrigin[3]
	
			get_position(id, 40.0, 5.0, -15.0 + 10.0, Origin)
			get_position(id, 40.0 * 100.0, 5.0, -15.0 + 10.0, TargetOrigin)
			create_fire(id, Origin, TargetOrigin, 500.0)
			
			fireammo[id] = fireammo[id] - 2
			if(fireammo[id] <= 0 || fireammo[id] == 1) fireammo[id] = 0
			
			if(fireammo[id] <= 3)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] = 0
				update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
			}
			
			if(fireammo[id] <= 10 && g_SpecialAmmo[id] == 2)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 21 && g_SpecialAmmo[id] == 3)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 32 && g_SpecialAmmo[id] == 4)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 43 && g_SpecialAmmo[id] == 5)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 54 && g_SpecialAmmo[id] == 6)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 65 && g_SpecialAmmo[id] == 7)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 76 && g_SpecialAmmo[id] == 8)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 87 && g_SpecialAmmo[id] == 9)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] --
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			if(fireammo[id] <= 99 && g_SpecialAmmo[id] == 9)
			{
				update_specialammo(id, g_SpecialAmmo[id], 0)
				g_SpecialAmmo[id] = 9
				update_specialammo(id, g_SpecialAmmo[id], 1)
			}
			
			set_weapons_timeidle(id, CSW_M249, 0.11)
			set_player_nextattackx(id, 0.11)
			set_pdata_float(Weapon, m_flTimeWeaponIdle, 0.2, WEAP_LINUX_XTRA_OFF)
		}
	}
		
	return FMRES_HANDLED
}

public fw_spmg_AddToPlayer(spmg, id)
{
	if(entity_get_int(spmg, EV_INT_WEAPONKEY) == spmg_WEAPONKEY)
	{
		g_has_spmg[id] = true
		
		entity_set_int(spmg, EV_INT_WEAPONKEY, 0)
	}

	message_begin(MSG_ONE_UNRELIABLE, gmsgWeaponList, {0,0,0}, id)
	write_string((g_has_spmg[id] == 1 ? "weapon_spmg" : "weapon_m249"))
	write_byte(3)
	write_byte(200)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(4)
	write_byte(CSW_M249)
	message_end()
	
	update_ammo(id)
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_has_spmg[id])
		return
	
	set_pev(id, pev_viewmodel2, spmg_V_MODEL)
	set_pev(id, pev_weaponmodel2, spmg_P_MODEL)
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgWeaponList, {0,0,0}, id)
	write_string((g_has_spmg[id] == 1 ? "weapon_spmg" : "weapon_m249"))
	write_byte(3)
	write_byte(200)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(4)
	write_byte(CSW_M249)
	message_end()
	
	update_ammo(id)
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
}

public CurrentWeapon(id)
{
	if(!is_user_alive(id))
		return	
	
	if(g_has_spmg[id] && (get_user_weapon(id) == CSW_M249 && oldweap[id] != CSW_M249))
	{
		UTIL_PlayWeaponAnimation(id, spmg_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
		
		update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
	} else if(get_user_weapon(id) != CSW_M249 && oldweap[id] == CSW_M249) {
		update_specialammo(id, g_SpecialAmmo[id], 0)
	}
	
	oldweap[id] = get_user_weapon(id)
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M249 || !g_has_spmg[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_spmg_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_spmg[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_spmg) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_spmg_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_spmg[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_spmg),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, spmg_SHOOT1)
		pusss[Player] ++
		if(fireammo[Player] <= 100) fireammo[Player] ++
		
		if(fireammo[Player] == 3)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] = 1
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 11)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 22)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 33)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 44)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 55)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 66)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 77)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 88)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] ++
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		if(fireammo[Player] == 100)
		{
			update_specialammo(Player, g_SpecialAmmo[Player], 0)
			g_SpecialAmmo[Player] = 9
			update_specialammo(Player, g_SpecialAmmo[Player], 1)
		}
		
		if(pusss[Player] == 21)
		{
			emit_sound(Player, CHAN_BODY, "weapons/steam.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			make_fire_smoke(Player)
			pusss[Player] = 0
		}
		set_weapons_timeidle(Player, CSW_M249, get_pcvar_float(cvar_spd_spmg))
		set_player_nextattackx(Player, get_pcvar_float(cvar_spd_spmg))
		set_pdata_float(Weapon, m_flTimeWeaponIdle, 1.0, WEAP_LINUX_XTRA_OFF)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_M249)
		{
			if(g_has_spmg[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_spmg))
		}
	}
}

public create_fire(id, Float:Origin[3], Float:TargetOrigin[3], Float:Speed)
{
	new iEnt = create_entity("env_sprite")
	static Float:vfAngle[3], Float:MyOrigin[3], Float:Velocity[3]
	
	pev(id, pev_angles, vfAngle)
	pev(id, pev_origin, MyOrigin)
	
	vfAngle[2] = float(random(18) * 20)

	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 250.0)
	set_pev(iEnt, pev_fuser1, get_gametime() + 1.0)	// time remove
	set_pev(iEnt, pev_scale, 0.5)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	
	entity_set_string(iEnt, EV_SZ_classname, "fire")
	engfunc(EngFunc_SetModel, iEnt, "sprites/flame_puff01.spr")
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_owner, id)	
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_iuser2, get_user_team(id))

	get_speed_vector(Origin, TargetOrigin, Speed, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)
	
	emit_sound(iEnt, CHAN_BODY, "weapons/flamegun-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)	
}

public fw_Fire_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new Float:fFrame, Float:fScale, Float:fNextThink
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)

	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.015
		fFrame += 1.0
		fScale = floatmax(fScale, 1.75)
		
		if (fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	// effect normal
	else
	{
		fNextThink = 0.045
		fFrame += 1.0
		fFrame = floatmin(21.0, fFrame)
		fScale += 0.2
		fScale = floatmin(fScale, 1.75)
	}

	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, get_gametime() + fNextThink)
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public fw_Fire_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	if(pev_valid(id))
	{
		static Classname[32]
		pev(id, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, "fire")) return
		else if(is_user_alive(id)) 
		{
			if(zp_core_is_zombie(id))
			{
				do_attack(pev(ent, pev_owner), id, 0, get_pcvar_float(cvar_dmg_fire))
				Make_FireBurn(id)
			}
		}
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}

public make_fire_smoke(id)
{
	static Float:Origin[3], TE_FLAG
	get_position(id, 20.0, 13.0, -15.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_smokepuff_id)
	write_byte(7)
	write_byte(24)
	write_byte(TE_FLAG)
	message_end()
}

public Make_FireBurn(id)
{
	static Ent; Ent = fm_find_ent_by_owner(-1, "fire_burn", id)
	if(!pev_valid(Ent))
	{
		new iEnt = create_entity("env_sprite")
		static Float:MyOrigin[3]
		
		pev(id, pev_origin, MyOrigin)
		
		// set info for ent
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
		set_pev(iEnt, pev_rendermode, kRenderTransAdd)
		set_pev(iEnt, pev_renderamt, 250.0)
		set_pev(iEnt, pev_fuser1, get_gametime() + 5.0)	// time remove
		set_pev(iEnt, pev_scale, 1.0)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.5)
		
		entity_set_string(iEnt, EV_SZ_classname, "fire_burn")
		engfunc(EngFunc_SetModel, iEnt, "sprites/flame_burn01.spr")
		set_pev(iEnt, pev_origin, MyOrigin)
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_aiment, id)
		set_pev(iEnt, pev_frame, 0.0)
	}
}

public fw_FireBurn_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame
	pev(iEnt, pev_frame, fFrame)

	// effect exp
	fFrame += 1.0
	if(fFrame > 15.0) fFrame = 0.0

	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	
	static id
	id = pev(iEnt, pev_owner)
	
	if(get_gametime() - 1.0 > pev(iEnt, pev_fuser2))
	{
		ExecuteHam(Ham_TakeDamage, id, 0, id, 0.0, DMG_BURN)
		if((get_user_health(id) - get_pcvar_num(cvar_dmg_afterburn)) > 0)
			set_user_health(id, get_user_health(id) - get_pcvar_num(cvar_dmg_afterburn))
		else
			user_kill(id)
		set_pev(iEnt, pev_fuser2, get_gametime())
	}
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHam(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHam(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_M249)
	{
		if(g_has_spmg[iAttacker])
			set_msg_arg_string(4, "m249")
	}
	return PLUGIN_CONTINUE
}

public update_specialammo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(fireammo[id] == 100 ? 200 : 42) // red
	write_byte(fireammo[id] == 100 ? 0 : 255) // green
	write_byte(fireammo[id] == 100 ? 0 : 42) // blue
	message_end()
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public spmg_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_spmg[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_spmg)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_M249, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public spmg_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_spmg[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_spmg[id])
          iClipExtra = get_pcvar_num(cvar_clip_spmg)

     g_spmg_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_spmg_TmpClip[id] = iClip

     return HAM_IGNORED
}

public spmg_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_spmg[id])
		return HAM_IGNORED

	if (g_spmg_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_spmg_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, spmg_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, spmg_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, spmg_RELOAD)

	return HAM_IGNORED
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != 2)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
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