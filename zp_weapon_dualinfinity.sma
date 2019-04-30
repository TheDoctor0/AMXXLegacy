#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombie_plague_advance>
#include <fakemeta_util>
#include <amxmisc>
enum
{
	anim_idle,
	anim_reload,
	anim_draw,
	shoot1,
	shoot2,
	shoot3
}
new g_mode[33]
#define BLOOD_SM_NUM 8
#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define DINFINITY_WEAPONKEY	901
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
#define BLOOD_STREAM_RED	70
#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip		51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83
#define BLOOD_LG_NUM 2
#define DINFINITY_RELOAD_TIME 4.0
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_USP)|(1<<CSW_DEAGLE)|(1<<CSW_GLOCK18)|(1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_sg550", "weapon_fiveseven", "weapon_ump45", "weapon_elite",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_elite", "weapon_knife", "weapon_p90" }
new const Fire_Sounds[][] = { "weapons/infi-1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new DINFINITY_V_MODEL[64] = "models/v_infinity.mdl"
new DINFINITY_V_MODEL2[64] = "models/v_infinity_2.mdl"
new DINFINITY_P_MODEL[64] = "models/p_infinity.mdl"
new DINFINITY_W_MODEL[64] = "models/w_infinity.mdl"
new cvar_dmg_DINFINITY, g_itemid_DINFINITY, cvar_clip_DINFINITY, cvar_DINFINITY_ammo
new g_has_DINFINITY[33]
new g_MaxPlayers, g_orig_event_DINFINITY, g_clip_ammo[33]
new m_iBlood[2]
new g_DINFINITY_TmpClip[33]
new g_Reload[33]
new Offset[8][3] = {{0,0,10},{0,0,30},{-4,-4,16},{-4,-4,16},{4,4,16},{-4,-4,16},{4,4,-12},{-4,-4,-12}}
new blood_small_red[BLOOD_SM_NUM], blood_large_red[BLOOD_LG_NUM]
public plugin_init()
{
	register_plugin("[ZP] Weapon: DInfinity", "1.0", "Crock / =)")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_elite", "fw_DINFINITY_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite", "fw_DINFINITY_PrimaryAttack")
	RegisterHam(Ham_Item_PostFrame, "weapon_elite", "DINFINITY__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_elite", "DINFINITY__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_elite", "DINFINITY__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	cvar_dmg_DINFINITY = register_cvar("zp_DINFINITY_dmg", "50")
	register_event("HLTV", 		"Event_NewRound", 	"a", 	"1=0", "2=0")
	cvar_clip_DINFINITY = register_cvar("zp_DINFINITY_clip", "30")
	cvar_DINFINITY_ammo = register_cvar("zp_DINFINITY_ammo", "120")
	register_forward(FM_CmdStart, "fw_CmdStart")
	//g_itemid_DINFINITY = zp_register_extra_item("DINFINITY", 1, ZP_TEAM_HUMAN)
	blood_large_red = {204,205}
	blood_small_red = {190,191,192,193,194,195,196,197}
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(DINFINITY_V_MODEL)
	precache_model(DINFINITY_P_MODEL)
	precache_model(DINFINITY_V_MODEL2)
	precache_model(DINFINITY_W_MODEL)
	precache_sound(Sound_Zoom)
	precache_sound(Fire_Sounds[0])
	precache_sound("weapons/infi_clipout.wav")
	precache_sound("weapons/infi_clipin.wav")
	precache_sound("weapons/infi_draw.wav")
	precache_sound("weapons/infis_clipout.wav")
	precache_sound("weapons/infis_clipin.wav")
	precache_sound("weapons/infis_foley1.wav")
	precache_sound("weapons/infis_foley2.wav")
	precache_sound("weapons/infis_draw.wav")
	precache_sound(Fire_Sounds[0])
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_model("sprites/640hud5.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}
public plugin_natives()
{
	register_native("give_dinfinity", "native_give_weapon_add", 1)
	register_native("set_infinity_have", "native_give_weapon_add2", 1)
}
public native_give_weapon_add(id)
{
	give_dinfinity(id)
}
public native_give_weapon_add2(id)
{
	g_has_DINFINITY[id] = false
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/elite_right.sc", name))
	{
		g_orig_event_DINFINITY = get_orig_retval()
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}
public Event_NewRound()
{
	for(new i; i <=32; i++)
		g_Reload[i] = 0
}

public client_connect(id)
{
	g_has_DINFINITY[id] = false
}

public client_disconnected(id)
{
	g_has_DINFINITY[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_DINFINITY[id] = false
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
	
	if(equal(model, "models/w_elite.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_elite", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_DINFINITY[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, DINFINITY_WEAPONKEY)
			g_has_DINFINITY[iOwner] = false
			
			entity_set_model(entity, DINFINITY_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	
	return FMRES_IGNORED;
}
public give_dinfinity(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,"weapon_elite")
	if( iWep2 > 0 )
	{
	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_DINFINITY))
	cs_set_user_bpammo (id, CSW_ELITE, get_pcvar_num(cvar_DINFINITY_ammo))
	}
	g_has_DINFINITY[id] = true;
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_DINFINITY)
	{	
	give_dinfinity(id)
	}
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED

	if(g_Reload[id])
		return PLUGIN_HANDLED

	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
		if(szClip > 0)
		{ 
		if(szWeapID == CSW_ELITE && g_has_DINFINITY[id])
		{
		new num
		num = random_num(1,2)
		if(num == 1)  UTIL_PlayWeaponAnimation(id, 8)
		if(num == 2)  UTIL_PlayWeaponAnimation(id, 5)
		make_blood_and_bulletholes(id)
		g_mode[id] = 0
		set_pdata_float(id, m_flNextAttack, 0.3, PLAYER_LINUX_XTRA_OFF)
		new ak = find_ent_by_owner ( -1, "weapon_elite", id )
		set_pdata_int ( ak, 51, szClip - 1, 4 )
		remove_task(id)
		}
		}	
	
	}
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
		if(szWeapID == CSW_ELITE && g_has_DINFINITY[id])
		{
		if(g_mode[id] == 0)
		{
		g_mode[id] = 1
		set_task(0.1,"fire_id",id)
		replace_weapon_models(id,CSW_ELITE)
		}else{
		remove_task(id)
		g_mode[id] = 0
		replace_weapon_models(id,CSW_ELITE)
		}
		}
	
	}
	return PLUGIN_HANDLED
}
public fire_id(id)
{
if(g_mode[id] == 1 && g_Reload[id] == 0 && is_user_alive(id) && !zp_get_user_zombie(id))
{
	
	new szClip, szAmmo
	new szWeapID = get_user_weapon(id, szClip, szAmmo)
	if(szClip > 1 && szWeapID == CSW_ELITE)
	{
		new num
		num = random_num(1,10)
		if(num == 1)  UTIL_PlayWeaponAnimation(id, 2)
		if(num == 2)  UTIL_PlayWeaponAnimation(id, 3)
		if(num == 3)  UTIL_PlayWeaponAnimation(id, 4)
		if(num == 4)  UTIL_PlayWeaponAnimation(id, 5)
		if(num == 5)  UTIL_PlayWeaponAnimation(id, 6)
		if(num == 6)  UTIL_PlayWeaponAnimation(id, 8)
		if(num == 7)  UTIL_PlayWeaponAnimation(id, 9)
		if(num == 8)  UTIL_PlayWeaponAnimation(id, 10)
		if(num == 9)  UTIL_PlayWeaponAnimation(id, 11)
		if(num == 10)  UTIL_PlayWeaponAnimation(id, 12)
		make_blood_and_bulletholes(id)
		new ak = find_ent_by_owner ( -1, "weapon_elite", id )
		set_pdata_int ( ak, 51, szClip - 1, 4 )
	}else if(szClip == 1 && szWeapID == CSW_ELITE)
	{
		new num
		num = random_num(1,2)
		if(num == 1)  UTIL_PlayWeaponAnimation(id, 7)
		if(num == 2)  UTIL_PlayWeaponAnimation(id, 13)
		make_blood_and_bulletholes(id)
		new ak = find_ent_by_owner ( -1, "weapon_elite", id )
		set_pdata_int ( ak, 51, szClip - 1, 4 )
	}else 	if(szClip == 0 && szWeapID == CSW_ELITE)
	{
	UTIL_PlayWeaponAnimation(id, 14)
	}
	set_task(0.1,"fire_id",id)
}
}
public fw_DINFINITY_AddToPlayer(DINFINITY, id)
{
	if(!is_valid_ent(DINFINITY) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(DINFINITY, EV_INT_WEAPONKEY) == DINFINITY_WEAPONKEY)
	{
		g_has_DINFINITY[id] = true
		
		entity_set_int(DINFINITY, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
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
}

public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))
}

replace_weapon_models(id, weaponid)
{
		if(weaponid == CSW_ELITE)
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_DINFINITY[id])
			{
				if(g_mode[id] == 0)
				{
				set_pev(id, pev_viewmodel2, DINFINITY_V_MODEL)
				set_pev(id, pev_weaponmodel2, DINFINITY_P_MODEL)
				}else{
				set_pev(id, pev_viewmodel2, DINFINITY_V_MODEL2)
				set_pev(id, pev_weaponmodel2, DINFINITY_P_MODEL)
				}
				}
				}else{
				g_mode[id] = 0
			}
		if(weaponid != CSW_ELITE) g_Reload[id] = 0
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_ELITE) || !g_has_DINFINITY[Player])
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_DINFINITY_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_DINFINITY[Player])
		return;
	if(Weapon == CSW_ELITE)
	{

		g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_DINFINITY))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_ELITE)
		{
			if(g_has_DINFINITY[attacker])
				SetHamParamFloat(4, get_pcvar_float(cvar_dmg_DINFINITY))
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
	
	if(equal(szTruncatedWeapon, "elite") && get_user_weapon(iAttacker) == CSW_ELITE)
	{
		if(g_has_DINFINITY[iAttacker])
			set_msg_arg_string(4, "elite")
	}
		
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	emit_sound(id, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	new victim = target
	new attacker = id

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
	
		if ( pev(target, pev_health) <= get_pcvar_num(cvar_dmg_DINFINITY))
		{
			kill(id, target)
			client_print(id, print_center,"Health: 0")
		}else{
		new iOrigin[3], iOrigin2[3]
		get_origin_int(victim,iOrigin)
		get_origin_int(attacker,iOrigin2)
		new iHitPlace = random_num(1,5)
		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood_small(iOrigin,8)
		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood_small(iOrigin,4)
		set_user_health(target, get_user_health(target) - get_pcvar_num(cvar_dmg_DINFINITY))
		client_print(id, print_center,"Health: %d",get_user_health(victim))
		}
		
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
	}
}
fx_blood(origin[3],origin2[3],HitPlace)
{
	//Crash Checks
	if (HitPlace < 0 || HitPlace > 7) HitPlace = 0
	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1

	new rX = ((origin[0]-origin2[0]) * 300) / rDistance
	new rY = ((origin[1]-origin2[1]) * 300) / rDistance
	new rZ = ((origin[2]-origin2[2]) * 300) / rDistance

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0]+Offset[HitPlace][0])
	write_coord(origin[1]+Offset[HitPlace][1])
	write_coord(origin[2]+Offset[HitPlace][2])
	write_coord(rX) // x
	write_coord(rY) // y
	write_coord(rZ) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(100,200)) // speed
	message_end()
}
fx_blood_small(origin[3],num)
{
	// Write Large splash decal
	for (new i = 0; i < num; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-50,50))
		write_coord(origin[1]+random_num(-50,50))
		write_coord(origin[2]-36)
		write_byte(blood_large_red[random_num(0,BLOOD_LG_NUM - 1)]) // index
		message_end()
	}
}
stock kill(k, v) {
	set_user_frags(k, get_user_frags(k) + 1)
	new gmsgScoreInfo = get_user_msgid("ScoreInfo")
	new gmsgDeathMsg = get_user_msgid("DeathMsg")

	set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
	set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
	user_kill(v,1)

	//Update killers scorboard with new info
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(k)
	write_short(get_user_frags(k))
	write_short(get_user_deaths(k))
	write_short(0)
	write_short(get_user_team(k))
	message_end()

	//Update victims scoreboard with correct info
	message_begin(MSG_ALL,gmsgScoreInfo)
	write_byte(v)
	write_short(get_user_frags(v))
	write_short(get_user_deaths(v))
	write_short(0)
	write_short(get_user_team(v))
	message_end()

	//Replaced HUD death message
	message_begin(MSG_ALL,gmsgDeathMsg,{0,0,0},0)
	write_byte(k)
	write_byte(v)
	write_byte(0)
	write_string("elite")
	message_end()

	
	zp_set_user_ammo_packs(k, zp_get_user_ammo_packs(k) + 1);
	set_user_frags(k, get_user_frags(k) + 1);
}



public DINFINITY__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
	return HAM_IGNORED;

	if (!g_has_DINFINITY[id])
	return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_ELITE);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_DINFINITY) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_ELITE, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
		g_Reload[id] = 0
	}

	return HAM_IGNORED;
}

public DINFINITY__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_DINFINITY[id])
		return HAM_IGNORED;

	g_DINFINITY_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_ELITE);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_DINFINITY))
		return HAM_SUPERCEDE;


	g_DINFINITY_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public DINFINITY__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_DINFINITY[id])
		return HAM_IGNORED;

	if (g_DINFINITY_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_DINFINITY_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, DINFINITY_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, DINFINITY_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 14)
	remove_task(id)
	g_mode[id] = 0

	g_Reload[id] = 1

	return HAM_IGNORED;
}
public get_origin_int(index, origin[3])
{
	new Float:FVec[3]

	pev(index,pev_origin,FVec)

	origin[0] = floatround(FVec[0])
	origin[1] = floatround(FVec[1])
	origin[2] = floatround(FVec[2])

	return 1
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
