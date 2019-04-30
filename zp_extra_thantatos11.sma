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

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define THANATOS11_WEAPONKEY 1824631
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

#define NAMACLASNYAX "thanatos11"
#define CLASS_BUNDER "bunder"
#define CLASS_MUTER "muter"

#define WEAPON_NAME		"Thanatos 11"
#define WEAPON_COST		0

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flNextSecondaryAttack 		47
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define m_fInSpecialReload 			55
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define DAMAGE_TH 350.0

enum
{
	ANIM_IDLEA = 0,
	ANIM_IDLEB1,
	ANIM_IDLEB2,
	ANIM_IDLEB_EMPTY,
	ANIM_SHOOTA,
	ANIM_SHOOTB,
	ANIM_SHOOTB_EMPTY,
	ANIM_CHANGEA,
	ANIM_CHANGEA_EMPTY,
	ANIM_CHANGEB,
	ANIM_CHANGEB_EMPTY,
	ANIM_INSERT_RELOAD,
	ANIM_AFTER_RELOAD,
	ANIM_START_RELOAD,
	ANIM_DRAW,
	ANIM_IDLEB_RELOAD
}

new const WeaponResource[6][] = 
{
	"sprites/640hud13.spr",
	"sprites/640hud120.spr",
	"sprites/circle.spr",
	"sprites/thanatos_hit.spr",
	"sprites/thanatos11_fire.spr",
	"sprites/thanatos11_scythe.spr"
}

new const weapon_sound[16][] = 
{
	"weapons/thanatos11-1.wav",
	"weapons/thanatos11_after_reload.wav",
	"weapons/thanatos11_changea.wav",
	"weapons/thanatos11_changea_empty.wav",
	"weapons/thanatos11_changeb.wav",
	"weapons/thanatos11_changeb_empty.wav",
	"weapons/thanatos11_count.wav",
	"weapons/thanatos11_count_start.wav",
	"weapons/thanatos11_explode.wav",
	"weapons/thanatos11_idleb_reload.wav",
	"weapons/thanatos11_idleb1.wav",
	"weapons/thanatos11_idleb2.wav",
	"weapons/ksg12_insert.wav",
	"weapons/thanatos11_shootb.wav",
	"weapons/thanatos11_shootb_empty.wav",
	"weapons/thanatos11_shootb_hit.wav"
}

new gmsgWeaponList, sTrail, g_itemid

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new THANATOS11_V_MODEL[64] = "models/v_thanatos11.mdl"
new THANATOS11_P_MODEL[64] = "models/p_thanatos11.mdl"
new THANATOS11_W_MODEL[64] = "models/w_thanatos11.mdl"
new const GRENADE_MODEL[] = "models/thanatos11_scythe.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_recoil_thanatos11, cvar_clip_thanatos11, cvar_thanatos11_ammo, g_has_thanatos11[33], ready[33], g_Ham_Bot, Float:g_scythe[33]

new g_MaxPlayers, g_orig_event_thanatos11, g_IsInPrimaryAttack, sExplo, sExplo2
new Float:cl_pushangle[33][3], m_iBlood[2]
new g_clip_ammo[33], oldweap[33], g_reload[33], thanatos11_mode[33], scythe[33], g_muter[33], g_bunder[33], bisa_ditembak[33], Float:zb_speed[33], Float:StartOrigin2[3]
const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_mp5navy", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("Thanatos-11", "1.0", "m4m3ts")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fw_THANATOS11_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_THANATOS11_Primary")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_THANATOS11_Primary_Post", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "THANATOS11_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "THANATOS11_Reload_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m3", "fw_thanatos11idleanim", 1)
	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_AddToFullPack, "fm_addtofullpack_post", 1)
	
	register_think(NAMACLASNYAX, "fw_Think")
	register_think(CLASS_BUNDER, "fw_Bunder_Think")
	register_think(CLASS_MUTER, "fw_Muter_Think")
	register_touch(NAMACLASNYAX, "*", "fw_touch")

	gmsgWeaponList = get_user_msgid("WeaponList")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	cvar_recoil_thanatos11 = register_cvar("zp_thanatos11_recoil", "0.65")           
	cvar_clip_thanatos11 = register_cvar("zp_thanatos11_clip", "15")
	cvar_thanatos11_ammo = register_cvar("zp_thanatos11_ammo", "64")	
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(THANATOS11_V_MODEL)
	precache_model(THANATOS11_P_MODEL)
	precache_model(THANATOS11_W_MODEL)
			
	for(new i = 0; i < sizeof(weapon_sound); i++) 
		precache_sound(weapon_sound[i])
		
	precache_model(GRENADE_MODEL)
	sTrail = precache_model("sprites/laserbeam.spr")
	sExplo = precache_model("sprites/thanatos11_fire.spr")
	sExplo2 = precache_model("sprites/thanatos_hit.spr")
		
	precache_generic("sprites/weapon_thanatos11.txt")
	precache_sound("weapons/speargun_stone1.wav")
	
	for(new i = 1; i < sizeof(WeaponResource); i++)
		precache_model(WeaponResource[i])
		
	register_clcmd("weapon_thanatos11", "weapon_hook")	
					
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	
	g_itemid = zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public weapon_hook(id)
{
	engclient_cmd(id, "weapon_m3")
	return PLUGIN_HANDLED
}

public zp_fw_core_cure_post(id, attacker)
{
	g_has_thanatos11[id] = false
	update_scythe(id, scythe[id], 0)
	scythe[id] = 0
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid != g_itemid)
		return;
		
	give_thanatos11(id)
}

public plugin_natives()
	register_native("zp_give_item_thanatos11", "give_thanatos11", 1);

public zp_fw_core_infect_post(id, attacker)
{
	g_has_thanatos11[id] = false
	update_scythe(id, scythe[id], 0)
	scythe[id] = 0
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public Player_Spawn(id)
{
	if (is_user_alive(id))
	{
		set_task(0.3, "get_zbspeed", id)
	}
}

public zp_user_infected_post(id)
{
	g_has_thanatos11[id] = false
	update_scythe(id, scythe[id], 0)
	scythe[id] = 0
}

public get_zbspeed(id) zb_speed[id] = get_user_maxspeed(id)

public fw_PlayerKilled(id)
{
	g_has_thanatos11[id] = false
	update_scythe(id, scythe[id], 0)
	scythe[id] = 0
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M3 || !g_has_thanatos11[iAttacker] || thanatos11_mode[iAttacker] == 2)
		return
	
	SetHamParamFloat(3, 30.0)
	
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
		
	if(!is_user_alive(iEnt))
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_short(iAttacker)
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	
	if(thanatos11_mode[iAttacker] == 3)
	{
		get_position(iAttacker, 20.0, 5.0, 5.0, StartOrigin2)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMPOINTS)
		engfunc(EngFunc_WriteCoord, StartOrigin2[0])
		engfunc(EngFunc_WriteCoord, StartOrigin2[1])
		engfunc(EngFunc_WriteCoord, StartOrigin2[2] - 10.0)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_short(sTrail)
		write_byte(0) // start frame
		write_byte(0) // framerate
		write_byte(5) // life
		write_byte(5) // line width
		write_byte(0) // amplitude
		write_byte(220)
		write_byte(88)
		write_byte(0) // blue
		write_byte(255) // brightness
		write_byte(0) // speed
		message_end()
	}
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m3.sc", name))
	{
		g_orig_event_thanatos11 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_thanatos11[id] = false
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
	
	if(equal(model, "models/w_m3.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m3", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_thanatos11[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, THANATOS11_WEAPONKEY)
			
			g_has_thanatos11[iOwner] = false
			
			entity_set_model(entity, THANATOS11_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_thanatos11(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_m3")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_thanatos11))
		cs_set_user_bpammo (id, CSW_M3, get_pcvar_num(cvar_thanatos11_ammo))
		UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
		set_weapons_timeidle(id, CSW_M3, 1.0)
		set_player_nextattackx(id, 1.0)
	}
	g_has_thanatos11[id] = true
	thanatos11_mode[id] = 1
	scythe[id] = 0
	update_scythe(id, scythe[id], 1)
	set_task(1.0, "ready_bung", id+173281 )
	message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
	write_string("weapon_thanatos11")
	write_byte(5)
	write_byte(32)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(5)
	write_byte(21)
	write_byte(0)
	message_end()
}

public fw_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	explode(Ent)
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
	if (equali(classnameptd, "func_breakable")) ExecuteHamB( Ham_TakeDamage, Id, 0, 0, 300.0, DMG_GENERIC )
	
	if(is_user_alive(Id) && zp_core_is_zombie(Id) && bisa_ditembak[Id] == 0)
	{
		set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(Ent, pev_solid, SOLID_NOT)
		set_pev(Ent, pev_aiment, Id)
		
		new Float:originXs[3]
		pev(Ent, pev_origin, originXs)
		bisa_ditembak[Id] = 1
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION) // Temporary entity ID
		engfunc(EngFunc_WriteCoord, originXs[0]) // engfunc because float
		engfunc(EngFunc_WriteCoord, originXs[1])
		engfunc(EngFunc_WriteCoord, originXs[2])
		write_short(sExplo2) // Sprite index
		write_byte(10) // Scale
		write_byte(30) // Framerate
		write_byte(0) // Flags
		message_end()
		
		bunder(Id)
		muter(Id)
		
		set_pev(Ent, pev_nextthink, get_gametime() + 2.0)
		emit_sound(Ent, CHAN_WEAPON, weapon_sound[15], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	else if(is_user_alive(Id) && !zp_core_is_zombie(Id))
	{
		emit_sound(Ent, CHAN_WEAPON, "weapons/speargun_stone1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_RemoveEntity, Ent)
	}
	
	else if(is_user_alive(Id) && zp_core_is_zombie(Id) && bisa_ditembak[Id] == 1)
	{
		engfunc(EngFunc_RemoveEntity, Ent)
	}
	
	else if(!is_user_alive(Id))
	{
		emit_sound(Ent, CHAN_WEAPON, "weapons/speargun_stone1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_RemoveEntity, Ent)
	}
}

public bunder(id)
{
	static playerBar, allocString
	allocString = engfunc(EngFunc_AllocString, "env_sprite")
	
	g_bunder[id] = engfunc(EngFunc_CreateNamedEntity, allocString)
	playerBar = g_bunder[id]
	
	if(pev_valid(playerBar))
	{
		set_pev(playerBar, pev_rendermode, kRenderTransAdd)
		set_pev(playerBar, pev_renderamt, 250.0)
		set_pev(playerBar, pev_fuser1, get_gametime() + 2.0)	// time remove
		set_pev(playerBar, pev_scale, 0.45)
		set_pev(playerBar, pev_nextthink, get_gametime() + 0.1)
		entity_set_string(playerBar, EV_SZ_classname, CLASS_BUNDER)
		engfunc(EngFunc_SetModel, playerBar, WeaponResource[2])
		
		set_pev(playerBar, pev_owner, id)
		set_pev(playerBar, pev_frame, 0.0)
	}	
}

public fw_Bunder_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame
	pev(iEnt, pev_frame, fFrame)

	// effect exp
	fFrame += 1.0
	if(fFrame > 9.0) fFrame = 9.0

	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.25)
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public muter(id)
{
	static playerBar, allocString
	allocString = engfunc(EngFunc_AllocString, "env_sprite")
	
	g_muter[id] = engfunc(EngFunc_CreateNamedEntity, allocString)
	playerBar = g_muter[id]
	
	if(pev_valid(playerBar))
	{
		set_pev(playerBar, pev_rendermode, kRenderTransAdd)
		set_pev(playerBar, pev_renderamt, 250.0)
		set_pev(playerBar, pev_fuser1, get_gametime() + 2.0)	// time remove
		set_pev(playerBar, pev_scale, 0.5)
		set_pev(playerBar, pev_nextthink, get_gametime() + 0.1)
		entity_set_string(playerBar, EV_SZ_classname, CLASS_MUTER)
		engfunc(EngFunc_SetModel, playerBar, WeaponResource[5])
		
		set_pev(playerBar, pev_owner, id)
		set_pev(playerBar, pev_frame, 0.0)
	}	
}

public fw_Muter_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame
	pev(iEnt, pev_frame, fFrame)

	// effect exp
	fFrame += 1.0
	if(fFrame > 5.0) fFrame = 0.0

	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}


public fm_addtofullpack_post(es, e, user, host, host_flags, player, p_set)
{
	if(!player)
		return FMRES_IGNORED
		
	if(!is_user_connected(host) || !is_user_alive(user))
		return FMRES_IGNORED
		
	if(!zp_core_is_zombie(user) || bisa_ditembak[user] != 1)
		return FMRES_IGNORED
		
	if(host == user)
		return FMRES_IGNORED
	
	new Float:PlayerOrigin[3]
	pev(user, pev_origin, PlayerOrigin)
							
	PlayerOrigin[2] += 50.0
						
	engfunc(EngFunc_SetOrigin, g_bunder[user], PlayerOrigin)
	engfunc(EngFunc_SetOrigin, g_muter[user], PlayerOrigin)

	return FMRES_HANDLED
}

public explode(Ent)
{
	new Float:originX[3], TE_FLAG
	pev(Ent, pev_origin, originX)
	// Draw explosion
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, originX[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, originX[1])
	engfunc(EngFunc_WriteCoord, originX[2])
	write_short(sExplo) // Sprite index
	write_byte(6) // Scale
	write_byte(27) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end()
	
	static Owners; Owners = pev(Ent, pev_owner)
	
	engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, weapon_sound[8], 1.0, ATTN_STATIC, 0, PITCH_NORM)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, Ent) > 100.0)
			continue
		if(!zp_core_is_zombie(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, Owners, DAMAGE_TH, DMG_BULLET)
		bisa_ditembak[i] = 0
		set_user_maxspeed(i, 100.0)
		if(task_exists( i+12519 )) remove_task( i + 12519 )
		set_task(3.0, "reset_speed", i+12519 )
	}
			
	remove_entity(Ent)
}

public reset_speed(id)
{
	id -= 12519
	
	if(!is_user_alive(id) || !zp_core_is_zombie(id))
		return
	
	set_user_maxspeed(id, zb_speed[id])
}

public fw_THANATOS11_AddToPlayer(thanatos11, id)
{
	if(!is_valid_ent(thanatos11) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(thanatos11, EV_INT_WEAPONKEY) == THANATOS11_WEAPONKEY)
	{
		g_has_thanatos11[id] = true
		
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_thanatos11")
		write_byte(5)
		write_byte(32)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(5)
		write_byte(21)
		write_byte(0)
		message_end()
		
		entity_set_int(thanatos11, EV_INT_WEAPONKEY, 0)

		return HAM_HANDLED
	}
	return HAM_IGNORED
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
	
	if(weaponid != CSW_M3)
	{
		ready[owner] = 0
		update_scythe(owner, scythe[owner], 0)
	}
	replace_weapon_models(owner, weaponid)
}

public ready_bung(id)
{
	id -= 173281
	
	if(get_user_weapon(id) != CSW_M3 || !g_has_thanatos11[id])
		return
	
	ready[id] = 1
}

public CurrentWeapon(id)
{
	if( read_data(2) != CSW_M3 ) {
		if( g_reload[id] ) {
			g_reload[id] = 0
			remove_task( id + 1331 )
		}
	}
	replace_weapon_models(id, read_data(2))
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M3:
		{
			if(g_has_thanatos11[id])
			{
				set_pev(id, pev_viewmodel2, THANATOS11_V_MODEL)
				set_pev(id, pev_weaponmodel2, THANATOS11_P_MODEL)
				if(oldweap[id] != CSW_M3) 
				{
					thanatos11_mode[id] = 1
					UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
					set_weapons_timeidle(id, CSW_M3, 0.8)
					set_player_nextattackx(id, 0.8)
					update_scythe(id, scythe[id], 1)
					if(task_exists( id+173281 )) remove_task( id + 173281 )
					set_task(1.0, "ready_bung", id+173281 )

					message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
					write_string("weapon_thanatos11")
					write_byte(5)
					write_byte(32)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(5)
					write_byte(CSW_M3)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || get_user_weapon(Player) != CSW_M3 || !g_has_thanatos11[Player])
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_THANATOS11_Primary(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_thanatos11[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_THANATOS11_Primary_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
		
	if(!is_user_alive(Player)|| !g_has_thanatos11[Player] || thanatos11_mode[Player] == 2)
		return

	if (!g_clip_ammo[Player])
		return
			
	g_reload[Player] = 0
	remove_task( Player + 1331 )
	new Float:push[3]
	pev(Player,pev_punchangle,push)
	xs_vec_sub(push,cl_pushangle[Player],push)
	
	xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_thanatos11),push)
	xs_vec_add(push,cl_pushangle[Player],push)
	set_pev(Player,pev_punchangle,push)
	
	emit_sound(Player, CHAN_WEAPON, weapon_sound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(thanatos11_mode[Player] == 2) UTIL_PlayWeaponAnimation(Player, 15)
	else UTIL_PlayWeaponAnimation(Player, ANIM_SHOOTA)
	
	set_weapons_timeidle(Player, CSW_M3, 0.8)
	set_player_nextattackx(Player, 0.8)
}

public fw_CmdStart(id, uc_handle, seed) 
{
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	if (!g_has_thanatos11[id] || weapon != CSW_M3 || !is_user_alive(id))
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_M3)
	if(!pev_valid(ent))
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(get_gametime() - 6.0 > g_scythe[id] && scythe[id] < 3 && ready[id] == 1)
	{
		update_scythe(id, scythe[id], 0)
		scythe[id]++
		update_scythe(id, scythe[id], 1)
		
		if(get_pdata_float(id, 83, 5) >= 0.5 && scythe[id] == 1 && thanatos11_mode[id] == 2) set_player_nextattackx(id, 0.5)
		
		g_scythe[id] = get_gametime()
	}
	
	if(CurButton & IN_ATTACK)
	{
		if(thanatos11_mode[id] != 2)
		{
			new wpn = fm_get_user_weapon_entity(id, get_user_weapon(id))
			
			new Id = pev( wpn, pev_owner ), clip, bpammo
			get_user_weapon( Id, clip, bpammo )
			if( g_has_thanatos11[ Id ] )
			{
				if( clip >= 2 ) {
					if( g_reload[Id] ) {
						remove_task( Id + 1331 )
						g_reload[Id] = 0
						UTIL_PlayWeaponAnimation(Id,ANIM_SHOOTA)
						emit_sound(Id, CHAN_WEAPON, weapon_sound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
						push(id)
						set_weapons_timeidle(id, CSW_M3, 0.7)
						set_player_nextattackx(id, 0.7)
						
						ExecuteHamB(Ham_Weapon_PrimaryAttack, wpn)
					}
				}
				else if( clip == 1 )
				{
					if(get_pdata_float(Id, 83, 4) <= 0.3)
					{
						if( g_reload[Id] ) {
						remove_task( Id + 1331 )
						g_reload[Id] = 0
						UTIL_PlayWeaponAnimation(Id,ANIM_SHOOTA)
						emit_sound(Id, CHAN_WEAPON, weapon_sound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
						push(id)
						set_weapons_timeidle(id, CSW_M3, 0.7)
						set_player_nextattackx(id, 0.7)
						
						ExecuteHamB(Ham_Weapon_PrimaryAttack, wpn)
					}
					}
				}
			}
		}
	}
	
	if(CurButton & IN_ATTACK && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
			return
			
		if(scythe[id] >= 1 && thanatos11_mode[id] == 2)
		{
			if(scythe[id] == 1) UTIL_PlayWeaponAnimation(id, ANIM_SHOOTB_EMPTY)
			else if(scythe[id] >= 2) UTIL_PlayWeaponAnimation(id, ANIM_SHOOTB)
			
			emit_sound(id, CHAN_WEAPON, weapon_sound[13], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			push(id)
			Fire_scythe(id)
			set_weapons_timeidle(id, CSW_M3, 1.03)
			set_player_nextattackx(id, 1.03)
		}
		else if(scythe[id] == 0 && thanatos11_mode[id] == 2)
		{
			set_player_nextattackx(id, 0.5)
		}
	}
	
	else if(CurButton & IN_ATTACK2)
	{
		if(get_pdata_float(id, 83, 5) <= 0.0)
		{
			remove_task(id)
			remove_task( id + 1331 )
			g_reload[id] = 0
			if(thanatos11_mode[id] == 1)
			{
				UTIL_PlayWeaponAnimation(id, ANIM_CHANGEA)
				thanatos11_mode[id] = 2
				set_weapons_timeidle(id, CSW_M3, 2.6)
				set_player_nextattackx(id, 2.6)
			}
			else
			{
				UTIL_PlayWeaponAnimation(id, ANIM_CHANGEB)
				thanatos11_mode[id] = 1
				set_weapons_timeidle(id, CSW_M3, 1.7)
				set_player_nextattackx(id, 1.7)
			}
		}
	}
}

public Fire_scythe(id)
{
	static Float:StartOrigin[3], Float:TargetOrigin[3], Float:angles[3], Float:angles_fix[3]
	get_position(id, 2.0, 0.0, 0.0, StartOrigin)

	pev(id,pev_v_angle,angles)
	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	angles_fix[0] = 360.0 - angles[0]
	angles_fix[1] = angles[1]
	angles_fix[2] = angles[2]

	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_owner, id)
	
	entity_set_string(Ent, EV_SZ_classname, NAMACLASNYAX)
	engfunc(EngFunc_SetModel, Ent, GRENADE_MODEL)
	set_pev(Ent, pev_mins,{ -0.1, -0.1, -0.1 })
	set_pev(Ent, pev_maxs,{ 0.1, 0.1, 0.1 })
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, angles_fix)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_BBOX)
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
	write_byte(210)
	write_byte(255)
	write_byte(100) // Alpha
	message_end()
	
	update_scythe(id, scythe[id], 0)
	scythe[id]--
	update_scythe(id, scythe[id], 1)
}


public fw_thanatos11idleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || !g_has_thanatos11[id] || get_user_weapon(id) != CSW_M3)
		return HAM_IGNORED;
	
	if(thanatos11_mode[id] == 1 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, 0)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}
	
	if(thanatos11_mode[id] == 2 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, ANIM_IDLEB2)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public update_scythe(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(255) // green
	write_byte(42) // blue
	message_end()
}

public push(id)
{
    static Float:vektor[3]
    vektor[0] = -3.0
    vektor[1] = 0.0
    vektor[2] = 0.0    
    
    set_pev(id, pev_punchangle, vektor)        
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_thanatos11) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
		
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public THANATOS11_Reload( wpn ) {
	if(thanatos11_mode[pev( wpn, pev_owner )] == 2)
	      return HAM_SUPERCEDE
		  
	if( g_has_thanatos11[ pev( wpn, pev_owner ) ] ) {
		THANATOS11_Reload_Post( wpn )
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public THANATOS11_Reload_Post(weapon) {
	new id = pev( weapon, pev_owner )
	if(thanatos11_mode[id] == 2)
	      return HAM_SUPERCEDE
	new clip, bpammo
	get_user_weapon(id, clip, bpammo )
	if( g_has_thanatos11[ id ] && clip < get_pcvar_num(cvar_clip_thanatos11) && bpammo > 0 ) {
		if(!task_exists( id+1331 )) set_task( 0.1, "reload", id+1331 )
		}
	return HAM_IGNORED
}

public reload( id ) {
	id -= 1331
	new clip, bpammo, weapon = find_ent_by_owner( -1, "weapon_m3", id )
	get_user_weapon(id, clip, bpammo )
	if(!g_reload[id]) {
			UTIL_PlayWeaponAnimation( id, ANIM_START_RELOAD )
			g_reload[id] = 1
			set_reload_timeidle(id, CSW_M3, 0.2)
			set_task( 0.5, "reload", id+1331 )
			return
	}
	
	if( clip > get_pcvar_num(cvar_clip_thanatos11)-1 || bpammo < 1 ) {
		UTIL_PlayWeaponAnimation(id, ANIM_AFTER_RELOAD)
		g_reload[id] = 0
		set_reload_timeidle(id, CSW_M3, 0.9)
		return
	}
	cs_set_user_bpammo( id, CSW_M3, bpammo - 1 )
	cs_set_weapon_ammo( weapon, clip + 1 )
	set_reload_timeidle(id, CSW_M3, 0.6)
	UTIL_PlayWeaponAnimation(id, ANIM_INSERT_RELOAD)
	set_task( 0.4, "reload", id+1331 )
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
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

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
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

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 47, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 48, TimeIdle + 0.55, WEAP_LINUX_XTRA_OFF)
}

stock set_reload_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, WEAP_LINUX_XTRA_OFF)
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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