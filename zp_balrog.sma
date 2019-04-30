#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#define TASK_BALROG1 7000

#define CSW_BALROG1 CSW_P228
#define weapon_balrog1 "weapon_p228"

#define CSW_BALROG3 CSW_MP5NAVY
#define weapon_balrog3 "weapon_mp5navy"

#define CSW_BALROG5 CSW_GALIL
#define weapon_balrog5 "weapon_galil"

#define CSW_BALROG7 CSW_M249
#define weapon_balrog7 "weapon_m249"

#define CSW_BALROG9 CSW_KNIFE
#define weapon_balrog9 "weapon_knife"

#define CSW_BALROG11 CSW_XM1014
#define weapon_balrog11 "weapon_xm1014"

#define DAMAGE_BALROG1 0.85
#define DAMAGE_BALROG3 1.04
#define DAMAGE_BALROG5 1.5
#define DAMAGE_BALROG7 1.132
#define DAMAGE_BALROG9 95.0
#define DAMAGE_BALROG11 1.0885

#define DAMAGE_BALROG1_FLAME 25
#define DAMAGE_BALROG7_EXP 120.0
#define DAMAGE_BALROG9_EXP 260.0
#define DAMAGE_BALROG11_FLAME 428.0

enum _:CODE
{
	CODE_BALROG1 = 03062015,
	CODE_BALROG3,
	CODE_BALROG5,
	CODE_BALROG7,
	CODE_BALROG11
}

#define CLASSNAME_1 "balrog11_flame"
#define CLASSNAME_2 "balrog11_flame_sys"
#define CLASSNAME_3 "balrog5_muzzle"
#define CLASSNAME_4 "balrog11_muzzle"
const pev_balrogtype = pev_iuser2

enum _:BALROG
{
	BALROG1 = 0,
	BALROG3,
	BALROG5,
	BALROG7,
	BALROG9,
	BALROG11
}

enum _:Type
{
	BALROG_RED = 0,
	BALROG_BLUE
}

new const P_MODEL[][] =
{
	"models/p_balrog1.mdl",
	"models/p_balrog3.mdl",
	"models/p_balrog5.mdl",
	"models/p_balrog7.mdl",
	"models/p_balrog9.mdl",
	"models/p_balrog11.mdl"
}
new const V_MODEL_RED[][] =
{
	"models/v_balrog1.mdl",
	"models/v_balrog3.mdl",
	"models/v_balrog5.mdl",
	"models/v_balrog7.mdl",
	"models/v_balrog9.mdl",
	"models/v_balrog11.mdl"
}
new const V_MODEL_BLUE[][] =
{
	"models/v_balrog1b.mdl",
	"models/v_balrog3b.mdl",
	"models/v_balrog5b.mdl",
	"models/v_balrog7b.mdl",
	"models/v_balrog9b.mdl",
	"models/v_balrog11b.mdl"
}
new const W_MODEL[][] = { "models/w_balrog_1.mdl", "models/w_balrog_2.mdl" }

new const Shoot_Sounds[][] = 
{
	"weapons/balrog1-1.wav", // 0
	"weapons/balrog1-2.wav",
	
	"weapons/balrig3-1.wav", // 2
	"weapons/balrig3-2.wav",
	
	"weapons/balrog5-1.wav", // 4
	"weapons/balrog5-2.wav",
	"weapons/balrog5-3.wav",
	
	"weapons/balrog7-1.wav", // 7
	"weapons/balrog7-2.wav",
	
	"weapons/balrog11-1.wav", // 9
	"weapons/balrog11-2.wav"
}

new const Balrog9_Sounds[][] = 
{
	"weapons/balrog9_draw.wav", // 0
	"weapons/balrog9_slash1.wav",
	"weapons/balrog9_slash2.wav",
	"weapons/balrog9_hitwall.wav", // 3
	"weapons/balrog9_hit1.wav",
	"weapons/balrog9_hit2.wav",
	"weapons/balrog9_charge_start1.wav", // 6
	"weapons/balrog9_charge_finish1.wav",
	"weapons/balrog9_charge_attack2.wav"
}

new const Weapon_Spr_Red[][] =
{
	"weapon_balrog1",
	"weapon_balrog3",
	"weapon_balrog5",
	"weapon_balrog7",
	"knife_balrog9",
	"weapon_balrog11"
}

new const Weapon_Spr_Blue[][] =
{
	"weapon_balrog1b",
	"weapon_balrog3b",
	"weapon_balrog5b",
	"weapon_balrog7b",
	"knife_balrog9b",
	"weapon_balrog11b"
}

new const Special_Spr[][] =
{
	"sprites/balrog5stack.spr",
	"sprites/balrogcritical.spr",
	"sprites/ef_balrog1.spr",
	"sprites/flame_puff01.spr",
	
	"sprites/balrog5stack_blue.spr",
	"sprites/balrogcritical_blue.spr",
	"sprites/ef_balrog1_blue.spr",
	"sprites/flame_puff01_blue.spr"
}

new const Muzzleflash[][] =
{
	"sprites/muzzleflash20.spr", // red
	"sprites/muzzleflash19.spr", // blue
	"sprites/muzzleflash29.spr",
	"sprites/muzzleflash17.spr"
}

enum _:HIT_RESULT
{
	RESULT_HIT_NONE = 0,
	RESULT_HIT_PLAYER,
	RESULT_HIT_WORLD
}

new g_event[5], g_attack, g_burn[2], g_iSpr[2][4], s_puff, g_iMuzz[2], g_shell
new g_had_balrog[33][6], g_iType[3], oldwpn[33], g_iClip[33], g_mode[33], g_iHold[33], g_iShoot[33]
new g_balrog[2][6], Float:cl_pushangle[33][3], g_clip[33], g_bot, g_iCsWpn[33], g_iMaxClip[33][2]
new g_iVictim[33], g_Shoot[33], g_iSlash[33], g_iCharge[33], Float:g_iTimer[33], g_SpAmmo[33]

public plugin_init()
{
	register_plugin("[ZP] Extra: Balrog-I", "1.0", "Asdian")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon", "CurrentWeapon", "be", "1=1")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_ClientCommand , "fw_ClientCommand")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog1, "fw_AddToPlayer_Post_Bl1", 1)
	RegisterHam(Ham_Item_Deploy, weapon_balrog1, "fw_Deploy", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog1, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog1, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog1, "fw_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog1, "fw_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog1, "fw_Reload_Post", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog3, "fw_AddToPlayer_Post_Bl3", 1)
	RegisterHam(Ham_Item_Deploy, weapon_balrog3, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog3, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog3, "fw_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog5, "fw_AddToPlayer_Post_Bl5", 1)
	RegisterHam(Ham_Item_Deploy, weapon_balrog5, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog5, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog5, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog5, "fw_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog5, "fw_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog5, "fw_Reload_Post", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog7, "fw_AddToPlayer_Post_Bl7", 1)
	RegisterHam(Ham_Item_Deploy, weapon_balrog7, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog7, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog7, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog7, "fw_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog7, "fw_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog7, "fw_Reload_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon_balrog9,  "fw_Deploy_Knife", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog9, "Knife_PostFrame")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog11, "fw_AddToPlayer_Post_Bl11", 1)
	RegisterHam(Ham_Item_Deploy, weapon_balrog11, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog11, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog11, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_balrog11, "Shotgun_Idle")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog11, "Shotgun_Reload")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	g_balrog[0][0] = zp_register_extra_item("Balrog-1 Red", 10, ZP_TEAM_HUMAN)
	g_balrog[0][1] = zp_register_extra_item("Balrog-3 Red", 10, ZP_TEAM_HUMAN)
	g_balrog[0][2] = zp_register_extra_item("Balrog-5 Red", 10, ZP_TEAM_HUMAN)
	g_balrog[0][3] = zp_register_extra_item("Balrog-7 Red", 10, ZP_TEAM_HUMAN)
	g_balrog[0][4] = zp_register_extra_item("Balrog-9 Red", 10, ZP_TEAM_HUMAN)
	g_balrog[0][5] = zp_register_extra_item("Balrog-11 Red", 10, ZP_TEAM_HUMAN)
	
	g_balrog[1][0] = zp_register_extra_item("Balrog-1 Blue", 10, ZP_TEAM_HUMAN)
	g_balrog[1][1] = zp_register_extra_item("Balrog-3 Blue", 10, ZP_TEAM_HUMAN)
	g_balrog[1][2] = zp_register_extra_item("Balrog-5 Blue", 10, ZP_TEAM_HUMAN)
	g_balrog[1][3] = zp_register_extra_item("Balrog-7 Blue", 10, ZP_TEAM_HUMAN)
	g_balrog[1][4] = zp_register_extra_item("Balrog-9 Blue", 10, ZP_TEAM_HUMAN)
	g_balrog[1][5] = zp_register_extra_item("Balrog-11 Blue", 10, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(P_MODEL); i++) engfunc(EngFunc_PrecacheModel, P_MODEL[i])
	for(i = 0; i < sizeof(W_MODEL); i++) engfunc(EngFunc_PrecacheModel, W_MODEL[i])
	for(i = 0; i < sizeof(V_MODEL_RED); i++)
	{
		engfunc(EngFunc_PrecacheModel, V_MODEL_RED[i])
		Stock_PrecacheSound(V_MODEL_RED[i])
	}
	for(i = 0; i < sizeof(V_MODEL_BLUE); i++)
	{
		engfunc(EngFunc_PrecacheModel, V_MODEL_BLUE[i])
		Stock_PrecacheSound(V_MODEL_BLUE[i])
	}
	for(i = 0; i < sizeof(Shoot_Sounds); i++) engfunc(EngFunc_PrecacheSound, Shoot_Sounds[i])
	for(i = 0; i < sizeof(Balrog9_Sounds); i++) engfunc(EngFunc_PrecacheSound, Balrog9_Sounds[i])
	for(i = 0; i < sizeof(Weapon_Spr_Red); i++)
	{
		new iSpr[32]
		format(iSpr, charsmax(iSpr), "sprites/%s.txt", Weapon_Spr_Red[i])
		engfunc(EngFunc_PrecacheGeneric, iSpr)
	}
	for(i = 0; i < sizeof(Weapon_Spr_Blue); i++)
	{
		new iSpr[32]
		format(iSpr, charsmax(iSpr), "sprites/%s.txt", Weapon_Spr_Blue[i])
		engfunc(EngFunc_PrecacheGeneric, iSpr)
	}
	
	g_iMuzz[0] = engfunc(EngFunc_PrecacheModel, Muzzleflash[0])
	g_iMuzz[1] = engfunc(EngFunc_PrecacheModel, Muzzleflash[1])
	engfunc(EngFunc_PrecacheModel, Muzzleflash[2])
	engfunc(EngFunc_PrecacheModel, Muzzleflash[3])
	
	g_iSpr[BALROG_RED][0] = engfunc(EngFunc_PrecacheModel, Special_Spr[0])
	g_iSpr[BALROG_RED][1] = engfunc(EngFunc_PrecacheModel, Special_Spr[1])
	g_iSpr[BALROG_RED][2] = engfunc(EngFunc_PrecacheModel, Special_Spr[2])
	g_iSpr[BALROG_RED][3] = engfunc(EngFunc_PrecacheModel, Special_Spr[3])
	
	g_iSpr[BALROG_BLUE][0] = engfunc(EngFunc_PrecacheModel, Special_Spr[4])
	g_iSpr[BALROG_BLUE][1] = engfunc(EngFunc_PrecacheModel, Special_Spr[5])
	g_iSpr[BALROG_BLUE][2] = engfunc(EngFunc_PrecacheModel, Special_Spr[6])
	g_iSpr[BALROG_BLUE][3] = engfunc(EngFunc_PrecacheModel, Special_Spr[7])
	
	g_shell = engfunc(EngFunc_PrecacheModel, "models/shell_bcs.mdl")
	s_puff = engfunc(EngFunc_PrecacheModel, "sprites/smokepuff.spr")
	g_burn[0] = engfunc(EngFunc_PrecacheModel, "sprites/flame_burn01.spr")
	g_burn[1] = engfunc(EngFunc_PrecacheModel, "sprites/holybomb_burn.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	
	register_clcmd(Weapon_Spr_Red[BALROG1], "weapon_hook")
	register_clcmd(Weapon_Spr_Red[BALROG3], "weapon_hook1")
	register_clcmd(Weapon_Spr_Red[BALROG5], "weapon_hook2")
	register_clcmd(Weapon_Spr_Red[BALROG7], "weapon_hook3")
	register_clcmd(Weapon_Spr_Red[BALROG9], "weapon_hook4")
	register_clcmd(Weapon_Spr_Red[BALROG11], "weapon_hook5")
	
	register_clcmd(Weapon_Spr_Blue[BALROG1], "weapon_hook")
	register_clcmd(Weapon_Spr_Blue[BALROG3], "weapon_hook1")
	register_clcmd(Weapon_Spr_Blue[BALROG5], "weapon_hook2")
	register_clcmd(Weapon_Spr_Blue[BALROG7], "weapon_hook3")
	register_clcmd(Weapon_Spr_Blue[BALROG9], "weapon_hook4")
	register_clcmd(Weapon_Spr_Blue[BALROG11], "weapon_hook5")
}

public zp_extra_item_selected(id, it)
{
	if(it == g_balrog[0][0]) give_bl1(id, BALROG_RED)
	else if(it == g_balrog[0][1]) give_bl3(id, BALROG_RED)
	else if(it == g_balrog[0][2]) give_bl5(id, BALROG_RED)
	else if(it == g_balrog[0][3]) give_bl7(id, BALROG_RED)
	else if(it == g_balrog[0][4]) give_bl9(id, BALROG_RED)
	else if(it == g_balrog[0][5]) give_bl11(id, BALROG_RED)
	
	else if(it == g_balrog[1][0]) give_bl1(id, BALROG_BLUE)
	else if(it == g_balrog[1][1]) give_bl3(id, BALROG_BLUE)
	else if(it == g_balrog[1][2]) give_bl5(id, BALROG_BLUE)
	else if(it == g_balrog[1][3]) give_bl7(id, BALROG_BLUE)
	else if(it == g_balrog[1][4]) give_bl9(id, BALROG_BLUE)
	else if(it == g_balrog[1][5]) give_bl11(id, BALROG_BLUE)
}
public zp_user_infected_post(id) remove_balrog(id)
public zp_user_humanized_post(id) remove_balrog(id)

public weapon_hook(id) engclient_cmd(id, weapon_balrog1)
public weapon_hook1(id) engclient_cmd(id, weapon_balrog3)
public weapon_hook2(id) engclient_cmd(id, weapon_balrog5)
public weapon_hook3(id) engclient_cmd(id, weapon_balrog7)
public weapon_hook4(id)
{
	engclient_cmd(id, weapon_balrog9)
	return PLUGIN_HANDLED // bugfix
}
public weapon_hook5(id) engclient_cmd(id, weapon_balrog11)

public client_putinserver(id)
{
	if(!g_bot && is_user_bot(id))
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack", 1)
}

public fw_TraceAttack(iEnt, attacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !Stock_CheckWeapon(attacker, false))
		return
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(!is_user_alive(iEnt))
	{
		Stock_BulletHole(attacker, flEnd, flDamage)
		Stock_BulletSmoke(attacker, ptr)
	}
}

public Float:WeaponDamage(id)
{
	new Float:fDamage
	if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) fDamage = DAMAGE_BALROG1
	else if(get_user_weapon(id) == CSW_BALROG3 && g_had_balrog[id][BALROG3]) fDamage = DAMAGE_BALROG3 
	else if(get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5]) fDamage = DAMAGE_BALROG5
	else if(get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7]) fDamage = DAMAGE_BALROG7
	else if(get_user_weapon(id) == CSW_BALROG11 && g_had_balrog[id][BALROG11]) fDamage = DAMAGE_BALROG11
	return fDamage
}

public fwPrecacheEvent_Post(type, const name[])
{
	if(equal("events/p228.sc", name)) g_event[0] = get_orig_retval()
	else if(equal("events/mp5n.sc", name)) g_event[1] = get_orig_retval()
	else if(equal("events/galil.sc", name)) g_event[2] = get_orig_retval()
	else if(equal("events/m249.sc", name)) g_event[3] = get_orig_retval()
	else if(equal("events/xm1014.sc", name)) g_event[4] = get_orig_retval()
}

public fw_ClientCommand(id)
{
	new sCmd[32]
	read_argv(0, sCmd, 31)
	
	if(equal(sCmd, "drop")) Update_SpAmmo(id, g_SpAmmo[id], 0)
	return FMRES_IGNORED
}

public fw_SetModel(ent, model[])
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(ent, pev_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(equal(model, "models/w_p228.mdl"))
	{
		static item
		item = fm_find_ent_by_owner(-1, weapon_balrog1, ent)
	
		if(!pev_valid(item))
			return FMRES_IGNORED
	
		if(g_had_balrog[id][BALROG1])
		{
			set_pev(item, pev_impulse, CODE_BALROG1)
			set_pev(item, pev_balrogtype, g_iType[0])
			engfunc(EngFunc_SetModel, ent, W_MODEL[g_iType[0]])
			set_pev(ent, pev_body, 0)
			g_had_balrog[id][BALROG1] = 0
			g_mode[id] = 0
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_mp5.mdl")) {
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_balrog3, ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog[id][BALROG3])
		{
			set_pev(weapon, pev_impulse, CODE_BALROG3)
			set_pev(weapon, pev_balrogtype, g_iType[1])
			engfunc(EngFunc_SetModel, ent, W_MODEL[g_iType[1]])
			set_pev(ent, pev_body, 1)
			
			g_had_balrog[id][BALROG3] = 0
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_galil.mdl")) {
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_balrog5, ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog[id][BALROG5])
		{
			set_pev(weapon, pev_impulse, CODE_BALROG5)
			set_pev(weapon, pev_balrogtype, g_iType[1])
			engfunc(EngFunc_SetModel, ent, W_MODEL[g_iType[1]])
			set_pev(ent, pev_body, 2)
			
			g_had_balrog[id][BALROG5] = 0
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_m249.mdl")) {
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_balrog7, ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog[id][BALROG7])
		{
			set_pev(weapon, pev_impulse, CODE_BALROG7)
			set_pev(weapon, pev_balrogtype, g_iType[1])
			engfunc(EngFunc_SetModel, ent, W_MODEL[g_iType[1]])
			set_pev(ent, pev_body, 3)
			
			g_had_balrog[id][BALROG7] = 0
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_xm1014.mdl")) {
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_balrog11, ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog[id][BALROG11])
		{
			set_pev(weapon, pev_impulse, CODE_BALROG11)
			set_pev(weapon, pev_balrogtype, g_iType[1])
			set_pev(weapon, pev_iuser4, g_SpAmmo[id])
			
			engfunc(EngFunc_SetModel, ent, W_MODEL[g_iType[1]])
			set_pev(ent, pev_body, 4)
			
			g_had_balrog[id][BALROG11] = 0
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_bl1(id, type)
{
	if(!is_user_alive(id))
		return
	
	drop_weapons(id, 2)
	
	g_had_balrog[id][BALROG1] = 1
	g_mode[id] = 0
	g_iType[0] = type
	g_iCsWpn[id] = CSW_BALROG1
	g_iMaxClip[id][0] = 10
	
	fm_give_item(id, weapon_balrog1)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_BALROG1)
	
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, g_iMaxClip[id][0])
	cs_set_user_bpammo(id, CSW_BALROG1, 200)	
	set_weapon_anim(id, 5)
	set_weapon_timeidle(id, CSW_BALROG1, 1.0, 1.0)
	set_nextattack(id, 1.0)
	
	Update_Clip(id, g_iMaxClip[id][0])
}

public give_bl3(id, type)
{
	if(!is_user_alive(id))
		return
	
	drop_weapons(id, 1)
	
	g_had_balrog[id][BALROG3] = 1
	g_iType[1] = type
	g_iShoot[id] = 0
	g_iHold[id] = 0
	g_iCsWpn[id] = CSW_BALROG3
	
	fm_give_item(id, weapon_balrog3)
	
	Update_Clip(id, 30)
	cs_set_user_bpammo(id, CSW_BALROG3, 200)
}

public give_bl5(id, type)
{
	if(!is_user_alive(id))
		return
	
	drop_weapons(id, 1)
	
	g_had_balrog[id][BALROG5] = 1
	g_iType[1] = type
	g_iVictim[id] = 0
	g_Shoot[id] = 0
	g_iCsWpn[id] = CSW_BALROG5
	g_iMaxClip[id][1] = 40
	
	fm_give_item(id, weapon_balrog5)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_BALROG5)
	
	if(!pev_valid(ent))
		return
	
	cs_set_weapon_ammo(ent, g_iMaxClip[id][1])
	cs_set_user_bpammo(id, CSW_BALROG5, 200)	
	set_weapon_anim(id, 5)
	Update_Clip(id, g_iMaxClip[id][1])
}

public give_bl7(id, type)
{
	if(!is_user_alive(id))
		return
	
	drop_weapons(id, 1)
	
	g_had_balrog[id][BALROG7] = 1
	g_iType[1] = type
	g_iShoot[id] = 0
	g_iCsWpn[id] = CSW_BALROG7
	g_iMaxClip[id][1] = 120
	g_iHold[id] = 0
	
	fm_give_item(id, weapon_balrog7)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_BALROG7)
	
	if(!pev_valid(ent))
		return
	
	cs_set_weapon_ammo(ent, g_iMaxClip[id][1])
	cs_set_user_bpammo(id, CSW_BALROG7, 200)
	
	set_weapon_anim(id, 4)
	Update_Clip(id, g_iMaxClip[id][1])
}

public give_bl9(id, type)
{
	if(!is_user_alive(id))
		return
	
	g_had_balrog[id][BALROG9] = 1
	g_iType[2] = type
	g_iSlash[id] = 0
	g_iCharge[id] = 0
	
	fm_give_item(id, weapon_balrog9)
	
	if(get_user_weapon(id) == CSW_BALROG9) 
	{
		Create_P_Model(id, BALROG9, 2)
		set_pev(id, pev_viewmodel2, g_iType[2] == BALROG_RED ? V_MODEL_RED[BALROG9] : V_MODEL_BLUE[BALROG9])
		
		set_weapon_anim(id, 6)
		set_nextattack(id, 1.0)
	} else engclient_cmd(id, weapon_balrog9)
	Stock_WeaponSPR(id, BALROG9, 2, weapon_balrog9, -1, -1, 2, 1, CSW_BALROG9)
}

public give_bl11(id, type)
{
	if(!is_user_alive(id))
		return
	
	drop_weapons(id, 1)
	Update_SpAmmo(id, g_SpAmmo[id], 0)
	
	g_had_balrog[id][BALROG11] = 1
	g_iShoot[id] = 0
	g_SpAmmo[id] = 0
	g_iHold[id] = 0
	g_iType[1] = type
	g_iCsWpn[id] = CSW_BALROG11
	g_iMaxClip[id][1] = 7
	
	fm_give_item(id, weapon_balrog11)
	cs_set_user_bpammo(id, CSW_BALROG11, 56)
	
	Update_Clip(id, g_iMaxClip[id][1])
	Update_SpAmmo(id, g_SpAmmo[id], 1)
}

public remove_balrog(id)
{
	for(new i = 0; i < 6; i++) g_had_balrog[id][i] = 0
	g_mode[id] = 0
	g_iShoot[id] = 0
	g_iHold[id] = 0
	g_iVictim[id] = 0
	g_Shoot[id] = 0
	g_iSlash[id] = 0
	g_SpAmmo[id] = 0
	Update_SpAmmo(id, g_SpAmmo[id], 0)
}

public fw_AddToPlayer_Post_Bl1(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == CODE_BALROG1)
	{
		g_had_balrog[id][BALROG1] = 1
		g_iType[0] = pev(ent, pev_balrogtype)
		g_mode[id] = 0
		set_pev(ent, pev_impulse, 0)
	}
	Stock_WeaponSPR(id, BALROG1, 0, weapon_balrog1, 9, 52, 1, 3, CSW_BALROG1)
}

public fw_AddToPlayer_Post_Bl3(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == CODE_BALROG3)
	{
		g_had_balrog[id][BALROG3] = 1
		g_iType[1] = pev(ent, pev_balrogtype)
		set_pev(ent, pev_impulse, 0)
	}
	Stock_WeaponSPR(id, BALROG3, 1, weapon_balrog3, 10, 120, 0, 7, CSW_BALROG3)
}

public fw_AddToPlayer_Post_Bl5(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == CODE_BALROG5)
	{
		g_had_balrog[id][BALROG5] = 1
		g_iType[1] = pev(ent, pev_balrogtype)
		set_pev(ent, pev_impulse, 0)
	}
	Stock_WeaponSPR(id, BALROG5, 1, weapon_balrog5, 4, 90, 0, 17, CSW_BALROG5)
}

public fw_AddToPlayer_Post_Bl7(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == CODE_BALROG7)
	{
		g_had_balrog[id][BALROG7] = 1
		g_iType[1] = pev(ent, pev_balrogtype)
		set_pev(ent, pev_impulse, 0)
	}
	Stock_WeaponSPR(id, BALROG7, 1, weapon_balrog7, 3, 200, 0, 4, CSW_BALROG7)
}

public fw_AddToPlayer_Post_Bl11(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return
	
	if(pev(ent, pev_impulse) == CODE_BALROG11)
	{
		g_had_balrog[id][BALROG11] = 1
		g_SpAmmo[id] = pev(ent, pev_iuser4)
		g_iType[1] = pev(ent, pev_balrogtype)
		set_pev(ent, pev_impulse, 0)
	}
	Stock_WeaponSPR(id, BALROG11, 1, weapon_balrog11, 5, 32, 0, 12, CSW_BALROG11)
}

public fw_Item_Deploy_Post(ent)
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!pev_valid(id))
		return
	
	if(g_had_balrog[id][BALROG3] && get_user_weapon(id) == CSW_BALROG3)
	{
		Create_P_Model(id, BALROG3, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG3] : V_MODEL_BLUE[BALROG3])
	} else if(g_had_balrog[id][BALROG5] && get_user_weapon(id) == CSW_BALROG5)
	{
		Create_P_Model(id, BALROG5, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG5] : V_MODEL_BLUE[BALROG5])
	} else if(g_had_balrog[id][BALROG7] && get_user_weapon(id) == CSW_BALROG7)
	{
		Create_P_Model(id, BALROG7, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG7] : V_MODEL_BLUE[BALROG7])
	} else if(g_had_balrog[id][BALROG11] && get_user_weapon(id) == CSW_BALROG11)
	{
		Create_P_Model(id, BALROG11, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG11] : V_MODEL_BLUE[BALROG11])
	}
}

public fw_Deploy(ent)  // Bugfix. Because not primary wpn
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!pev_valid(id))
		return
	if(!g_had_balrog[id][BALROG1] || get_user_weapon(id) != CSW_BALROG1)
		return
	
	Create_P_Model(id, BALROG1, 0)
	set_pev(id, pev_viewmodel2, g_iType[0] == BALROG_RED ? V_MODEL_RED[BALROG1] : V_MODEL_BLUE[BALROG1])
}

public fw_Deploy_Knife(ent)  // Bugfix. Because not primary wpn
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!pev_valid(id))
		return
	if(!g_had_balrog[id][BALROG9] || get_user_weapon(id) != CSW_BALROG9)
		return
	
	Create_P_Model(id, BALROG9, 2)
	set_pev(id, pev_viewmodel2, g_iType[2] == BALROG_RED ? V_MODEL_RED[BALROG9] : V_MODEL_BLUE[BALROG9])
}

public CurrentWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	if((get_user_weapon(id) == CSW_BALROG1 && oldwpn[id] != CSW_BALROG1) && g_had_balrog[id][BALROG1])
	{
		Create_P_Model(id, BALROG1, 0)
		set_pev(id, pev_viewmodel2, g_iType[0] == BALROG_RED ? V_MODEL_RED[BALROG1] : V_MODEL_BLUE[BALROG1])
		
		set_pdata_string(id, 492 * 4, "onehanded", -1 , 20)
		g_mode[id] = 0
		set_weapon_anim(id, DrawAnim(id))
	} else if((get_user_weapon(id) == CSW_BALROG3 && oldwpn[id] != CSW_BALROG3) && g_had_balrog[id][BALROG3])
	{
		Create_P_Model(id, BALROG3, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG3] : V_MODEL_BLUE[BALROG3])
		
		set_weapon_anim(id, DrawAnim(id))
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
		
		g_iHold[id] = 0
		g_iShoot[id] = 0
	} else if((get_user_weapon(id) == CSW_BALROG5 && oldwpn[id] != CSW_BALROG5) && g_had_balrog[id][BALROG5])
	{
		Create_P_Model(id, BALROG5, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG5] : V_MODEL_BLUE[BALROG5])
		
		set_weapon_anim(id, DrawAnim(id))
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
		
		g_iVictim[id] = 0
		g_Shoot[id] = 0
	} else if((get_user_weapon(id) == CSW_BALROG7 && oldwpn[id] != CSW_BALROG7) && g_had_balrog[id][BALROG7])
	{
		Create_P_Model(id, BALROG7, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG7] : V_MODEL_BLUE[BALROG7])
		
		set_weapon_anim(id, DrawAnim(id))
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
		
		g_iHold[id] = 0
		g_iShoot[id] = 0
	} else if((get_user_weapon(id) == CSW_BALROG9 && oldwpn[id] != CSW_BALROG9) && g_had_balrog[id][BALROG9])
	{
		Create_P_Model(id, BALROG9, 2)
		set_pev(id, pev_viewmodel2, g_iType[2] == BALROG_RED ? V_MODEL_RED[BALROG9] : V_MODEL_BLUE[BALROG9])
		
		set_pdata_float(id, 83, 1.0, 5)
		set_weapon_anim(id, DrawAnim(id))
		g_iSlash[id] = 0
		g_iCharge[id] = 0
	} else if((get_user_weapon(id) == CSW_BALROG11 && oldwpn[id] != CSW_BALROG11) && g_had_balrog[id][BALROG11])
	{
		Create_P_Model(id, BALROG11, 1)
		set_pev(id, pev_viewmodel2, g_iType[1] == BALROG_RED ? V_MODEL_RED[BALROG11] : V_MODEL_BLUE[BALROG11])
		
		Update_SpAmmo(id, g_SpAmmo[id], 1)
		CancelReload(id, 0)
		set_weapon_anim(id, DrawAnim(id))
	}
	oldwpn[id] = get_user_weapon(id)
}

public Create_P_Model(id, iWpn, num)
{
	set_pev(id, pev_weaponmodel2, P_MODEL[iWpn])
	set_pev(id, pev_skin, g_iType[num])
}

public DrawAnim(id)
{
	new iAnim
	if((get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) || (get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5])) iAnim = 5
	else if(get_user_weapon(id) == CSW_BALROG3 && g_had_balrog[id][BALROG3]) iAnim = 2
	else if(get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7]) iAnim = 4
	else if((get_user_weapon(id) == CSW_BALROG9 && g_had_balrog[id][BALROG9]) || (get_user_weapon(id) == CSW_BALROG11 && g_had_balrog[id][BALROG11])) iAnim = 6
	return iAnim
}

public client_PostThink(id) if(get_user_weapon(id) != CSW_BALROG11) Update_SpAmmo(id, g_SpAmmo[id], 0)
public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	
	if((get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) || (get_user_weapon(id) == CSW_BALROG3 && g_had_balrog[id][BALROG3])
	|| (get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5]) || (get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7])
	|| (get_user_weapon(id) == CSW_BALROG11 && g_had_balrog[id][BALROG11])) set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001) 
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_alive(invoker) || !g_attack)
		return FMRES_IGNORED
	if(!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
	
	if(get_user_weapon(invoker) == CSW_BALROG1 && g_had_balrog[invoker][BALROG1] && eventid == g_event[0]) engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	else if(get_user_weapon(invoker) == CSW_BALROG3 && g_had_balrog[invoker][BALROG3] && eventid == g_event[1]) engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	else if(get_user_weapon(invoker) == CSW_BALROG5 && g_had_balrog[invoker][BALROG5] && eventid == g_event[2]) engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	else if(get_user_weapon(invoker) == CSW_BALROG7 && g_had_balrog[invoker][BALROG7] && eventid == g_event[3]) engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	else if(get_user_weapon(invoker) == CSW_BALROG11 && g_had_balrog[invoker][BALROG11] && eventid == g_event[4]) engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageType)
{	
	if(iVictim != iAttacker && is_user_connected(iAttacker) && Stock_CheckWeapon(iAttacker, false))
	{
		new Float:fDmg = WeaponDamage(iAttacker)
		fDamage *= fDmg
		
		if(get_user_weapon(iAttacker) == CSW_BALROG5 && g_had_balrog[iAttacker][BALROG5])
			fDamage *= SpriteEffect(iAttacker, iVictim)
		
		if(get_user_weapon(iAttacker) == CSW_BALROG3 && g_had_balrog[iAttacker][BALROG3])
		{
			if(g_iShoot[iAttacker] > 15)
			{
				fDamage *= 0.8
				
				static Float:Origin[3], Float:Angles[3]
				engfunc(EngFunc_GetBonePosition, iVictim, 7, Origin, Angles)
				
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
				write_byte(TE_SPRITE)
				engfunc(EngFunc_WriteCoord, Origin[0])
				engfunc(EngFunc_WriteCoord, Origin[1])
				engfunc(EngFunc_WriteCoord, Origin[2] + 20.0)
				write_short(g_iSpr[g_iType[1]][0])
				write_byte(5)
				write_byte(255)
				message_end()
			}
		}
		SetHamParamFloat(4, fDamage)
	}
}

public Float:SpriteEffect(iAttacker, iVictim)
{
	if(iVictim != g_iVictim[iAttacker])
	{
		g_Shoot[iAttacker] = 1
		g_iVictim[iAttacker] = iVictim
		return 1.0
	} else {
		g_Shoot[iAttacker]++
		if(g_Shoot[iAttacker] >= 16)
		{
			static Float:Origin[3], Float:Angles[3]
			engfunc(EngFunc_GetBonePosition, iVictim, 7, Origin, Angles)
			
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2] + 20.0)
			write_short(g_iSpr[g_iType[1]][0])
			write_byte(5)
			write_byte(255)
			message_end()
		}
		
		if(g_Shoot[iAttacker] >= 3)
		{
			if(g_Shoot[iAttacker] <= 16) return 1.0 + (g_Shoot[iAttacker] - 2) * 0.05				
			else return 3.15
		}
	}
	return 1.0
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	static CurButton, OldButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	OldButton = pev(id, pev_oldbuttons)
	
	if((get_user_weapon(id) == CSW_BALROG3 && g_had_balrog[id][BALROG3]) || (get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7])) 
	{
		if(CurButton & IN_ATTACK)
		{
			if(!g_iHold[id]) g_iHold[id] = 1
		} else if((CurButton & IN_ATTACK2) && !(OldButton & IN_ATTACK2)) {
			if(cs_get_user_zoom(id) == 1) cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			else cs_set_user_zoom(id, CS_SET_NO_ZOOM, 1)
		} else if(CurButton & IN_RELOAD)
		{
			if(get_user_weapon(id) == CSW_BALROG3 && g_had_balrog[id][BALROG3])
				cs_set_user_zoom(id, CS_SET_NO_ZOOM, 1)
		} else {
			if(OldButton & IN_ATTACK)
			{
				if(g_iHold[id])
				{
					g_iHold[id] = 0
					g_iShoot[id] = 0
				}
			}
		}
	} else if(get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5])
	{
		if((CurButton & IN_ATTACK2) && !(OldButton & IN_ATTACK2))
		{
			if(cs_get_user_zoom(id) == 1) cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			else cs_set_user_zoom(id, CS_SET_NO_ZOOM, 1)
		}
	} else if(get_user_weapon(id) == CSW_BALROG11 && g_had_balrog[id][BALROG11])
	{
		static ent; ent = fm_get_user_weapon_entity(id, CSW_BALROG11)
		if(!pev_valid(ent)) return FMRES_IGNORED
		
		if(CurButton & IN_ATTACK)
		{
			if(!g_iHold[id]) g_iHold[id] = 1
		} else if(CurButton & IN_ATTACK2) SpecialShoot_Handle(id)
		else if(CurButton & IN_RELOAD)
		{
			if(get_pdata_int(ent, 55) != 0)
			{
				CurButton &= ~IN_RELOAD
				set_uc(uc_handle, UC_Buttons, CurButton)
			}
			return FMRES_SUPERCEDE
		} else {
			if(OldButton & IN_ATTACK)
			{
				if(g_iHold[id])
				{
					g_iHold[id] = 0
					g_iShoot[id] = 0
				}
			}
		}
	}
	return FMRES_IGNORED
}

public fw_PrimaryAttack(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	g_attack = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	g_clip[id] = cs_get_weapon_ammo(ent)
}

public fw_PrimaryAttack_Post(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id) || !g_clip[id])
		return HAM_IGNORED
	
	if(g_attack)
	{
		if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1])
		{
			if(g_mode[id])
			{
				B1_exp(id)
				set_weapon_timeidle(id, CSW_BALROG1, 2.7, 2.7)
				set_nextattack(id, 2.7)
			}
			SetRecoil(id, 1.0)
			Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[g_mode[id]])
			set_weapon_anim(id, g_mode[id] ? 3 : 2)
			if(g_mode[id]) g_mode[id] = 0
		} else if(g_had_balrog[id][BALROG3] && get_user_weapon(id) == CSW_BALROG3) {
			static Float:flNext
			flNext = 0.0775
			Config_Balrog3(id, ent)
			SetRecoil(id, 1.225)
			
			if(g_iShoot[id] > 15)
			{
				set_pdata_float(ent, 46, flNext * 0.67, 4)
				Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[3])
				set_weapon_anim(id, 4)
			} else {
				set_pdata_float(ent, 46, flNext, 4)
				Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[2])
				set_weapon_anim(id, 3)
			}
		} else if(g_had_balrog[id][BALROG5] && get_user_weapon(id) == CSW_BALROG5) {
			if(g_Shoot[id] >= 16)
			{
				Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[6])
				set_weapon_anim(id, 3)
				MakeMuzzleFlash(id, Muzzleflash[g_iType[1]])
			} else {
				Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[random_num(4, 5)])
				set_weapon_anim(id, random_num(1, 2))
			}
			SetRecoil(id, 0.6)
			set_weapon_timeidle(ent, CSW_BALROG7, 0.1207, 1.2)
			set_nextattack(id, 0.1207)
		} else if(g_had_balrog[id][BALROG7] && get_user_weapon(id) == CSW_BALROG7) {
			set_pdata_float(ent, 46, 0.1145, 4)
			PunchAxis(id, random_float(-0.935, 0.935), random_float(-0.935, 0.935))
			
			Config_Balrog7(id)
			set_weapon_anim(id, random_num(1, 2))
		} else if(g_had_balrog[id][BALROG11] && get_user_weapon(id) == CSW_BALROG11) {
			SetRecoil(id, 0.995)
			set_pdata_float(ent, 46, 0.2875, 4)
			
			CancelReload(id, ent)
			set_weapon_anim(id, random_num(1, 2))
			Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[9])
			
			Config_Balrog11(id)
			MakeMuzzleFlash2(id)
		}
	}
	g_attack = 0
	return HAM_IGNORED
}

public SetRecoil(id, Float:Recoil)
{
	new Float:push[3]
	pev(id, pev_punchangle,push)
	xs_vec_sub(push, cl_pushangle[id],push)
	xs_vec_mul_scalar(push, Recoil, push)
	xs_vec_add(push, cl_pushangle[id], push)
	set_pev(id, pev_punchangle, push)
}

public Config_Balrog3(id, iEnt)
{
	static iBpAmmo, iClip
	iBpAmmo = Stock_Config_Bpammo(id, CSW_BALROG3)
	iClip = get_pdata_int(iEnt, 51)
	
	g_iShoot[id]++
	if(g_iShoot[id] > 15 && iBpAmmo)
	{
		set_pdata_int(iEnt, 51, iClip + 1)
		Stock_Config_Bpammo(id, CSW_BALROG3, iBpAmmo - 1, 1)
	}
	if(!iBpAmmo) g_iShoot[id] = 0
}

public Config_Balrog7(id)
{
	g_iShoot[id]++
	if(g_iShoot[id] >= 10)
	{
		g_iShoot[id] = 0
		Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[8])
		
		static vOri[3], Float:fVec[3]
		get_user_origin(id, vOri, 3)
		IVecFVec(vOri, fVec)
		
		Balrog7_Exp(id, fVec, g_iSpr[g_iType[1]][3], g_iSpr[g_iType[1]][1], g_iMuzz[g_iType[1]])
	} else Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[7])
}

public Config_Balrog11(id)
{
	g_iShoot[id]++
	if(g_iShoot[id] >= 4)
	{
		g_iShoot[id] = 0
		if(g_SpAmmo[id] < 7)
		{
			Stock_PlaySound(id, CHAN_ITEM, Balrog9_Sounds[7])
			
			Update_SpAmmo(id, g_SpAmmo[id], 0)
			g_SpAmmo[id]++
			Update_SpAmmo(id, g_SpAmmo[id], 1)
		}
	}
}

public MakeMuzzleFlash(id, data[])
{
	static iMuz
	iMuz = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))

	engfunc(EngFunc_SetModel, iMuz, data)
	set_pev(iMuz, pev_classname, CLASSNAME_3)
	set_pev(iMuz, pev_nextthink, get_gametime() + 0.15)
	set_pev(iMuz, pev_body, 1)
	set_pev(iMuz, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.07)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_solid, SOLID_NOT)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public MakeMuzzleFlash2(id)
{
	static iMuz
	iMuz = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))

	engfunc(EngFunc_SetModel, iMuz, Muzzleflash[3])
	set_pev(iMuz, pev_classname, CLASSNAME_4)
	set_pev(iMuz, pev_nextthink, get_gametime() + 0.15)
	set_pev(iMuz, pev_body, 1)
	set_pev(iMuz, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.1)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_solid, SOLID_NOT)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public Balrog7_Exp(id, Float:vecEnd[3], data1, data2, mFlash)
{
	static TE_FLAG, Float:Origin[3]
	Stock_Get_Postion(id, 7.5, 6.0, -15.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	// Draw Muzzleflash
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(mFlash)
	write_byte(2)
	write_byte(15)
	write_byte(TE_FLAG)
	message_end()
	
	// Draw explosion
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, vecEnd[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] + 10.0)
	write_short(data1) // Sprite index
	write_byte(15) // Scale
	write_byte(30) // Framerate
	write_byte(0) // Flags
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, vecEnd[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] + 30.0)
	write_short(data2) // Sprite index
	write_byte(1) // Scale
	write_byte(6) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, vecEnd[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] + 30.0)
	write_short(data2) // Sprite index
	write_byte(2) // Scale
	write_byte(4) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, vecEnd[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] + 30.0)
	write_short(data2) // Sprite index
	write_byte(3) // Scale
	write_byte(3) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end()
		
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, vecEnd[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] + 30.0)
	write_short(data2) // Sprite index
	write_byte(3) // Scale
	write_byte(1) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end()
	
	Stock_RadiusDamage(vecEnd, id, id, DAMAGE_BALROG7_EXP, 96.0, (1<<24), true, true)
}

public B1_exp(id)
{
	new vOri[3],Float:fVec[3], Float:vOrigin[3], Float:fRadius,Float:fDistance
	fRadius = 180.0
	get_user_origin(id,vOri,3)
	IVecFVec(vOri,fVec)
	
	new victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fVec, fRadius)) != 0)
	{
		if(!pev_valid(victim))
			continue				
		if(victim == id)
			continue
			
		pev(victim, pev_origin, vOrigin)
		fDistance = get_distance_f(fVec, vOrigin)
		
		if(fDistance > fRadius)
			continue
		if(!can_damage(id, victim))
			continue
			
		set_task(1.0, "Task_Balrog1", victim+TASK_BALROG1, "", 0, "a", 10)
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(vOri[0])
	write_coord(vOri[1])
	write_coord(vOri[2])
	write_short(g_iSpr[g_iType[0]][2])
	write_byte(10)
	write_byte(18)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES)
	message_end()
}

public fw_Think(ent)
{
	if(!pev_valid(ent))
		return
		
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if((equal(Classname, CLASSNAME_4)) || (equal(Classname, CLASSNAME_3)))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	} else if(equal(Classname, CLASSNAME_2)) {	
		static Float:fFrame
		pev(ent, pev_frame, fFrame)
		
		fFrame += 1.5
		fFrame = floatmin(21.0, fFrame)
	
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		
		// time remove
		static Float:fTimeRemove, Float:Amount
		pev(ent, pev_fuser1, fTimeRemove)
		pev(ent, pev_renderamt, Amount)
		
		if(get_gametime() >= fTimeRemove) 
		{
			Amount -= 100.0
			set_pev(ent, pev_renderamt, Amount)
			
			if(Amount <= 15.0) engfunc(EngFunc_RemoveEntity, ent)
		}
	} else if(equal(Classname, CLASSNAME_1)) {
		static Float:Origin[3], Float:Scale
		pev(ent, pev_origin, Origin)
		pev(ent, pev_scale, Scale)
		
		Scale += 0.1 
		Scale = floatmin(1.5, Scale)
		set_pev(ent, pev_scale, Scale)

		Create_Fire(pev(ent, pev_owner), Origin, Scale, 0.0)
		set_pev(ent, pev_nextthink, get_gametime() + 0.05)
		
		// time remove
		static Float:fTimeRemove
		pev(ent, pev_fuser1, fTimeRemove)
		if(get_gametime() >= fTimeRemove) engfunc(EngFunc_RemoveEntity, ent)
	}
}

public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	static Classname[32], iOwner
	pev(ent, pev_classname, Classname, sizeof(Classname))
	iOwner = pev(ent, pev_owner)
	
	if(!equal(Classname, CLASSNAME_1))
		return
		
	if(pev_valid(id))
	{
		static Classname2[32]
		pev(id, pev_classname, Classname2, sizeof(Classname2))
		
		if(equal(Classname2, CLASSNAME_1) || equal(Classname2, CLASSNAME_2)) return
		else if(is_user_alive(id))
		{
			if(pev(ent, pev_iuser3) == 1 && cs_get_user_team(id) != CS_TEAM_T) ExecuteHamB(Ham_TakeDamage, id, 0, iOwner, DAMAGE_BALROG11_FLAME, DMG_BULLET)
			else if(pev(ent, pev_iuser3) == 2 && cs_get_user_team(id) != CS_TEAM_CT) ExecuteHamB(Ham_TakeDamage, id, 0, iOwner, DAMAGE_BALROG11_FLAME, DMG_BULLET)
			Stock_Fake_KnockBack(iOwner, id, 0.5) 
			return
		}
		
		if(equali(Classname2, "func_breakable"))
			force_use(ent, id)
	}
	if(iOwner != id) set_pev(ent, pev_solid, SOLID_NOT)
}

public fw_ItemPostFrame(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5), iBpAmmo = Stock_Config_Bpammo(id, g_iCsWpn[id])
	new iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4), CurClip
	
	if(Stock_CheckWeapon(id, true))
	{
		if(fInReload && flNextAttack <= 0.0)
		{
			if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) CurClip = g_iMaxClip[id][0]
			else CurClip = g_iMaxClip[id][1]
			
			new Clip = min(CurClip - iClip, iBpAmmo)
			set_pdata_int(ent, 51, iClip + Clip, 4)
			Stock_Config_Bpammo(id, g_iCsWpn[id], iBpAmmo - Clip, 1)
			set_pdata_int(ent, 54, 0, 4)
			fInReload = 0
		}
	}
	
	if(g_had_balrog[id][BALROG1] && get_user_weapon(id) == CSW_BALROG1)
	{
		if(pev(id, pev_button) & IN_ATTACK2 && flNextAttack <= 0.0)
		{
			set_weapon_anim(id, !g_mode[id] ? 6 : 7)
			g_mode[id] = 1 - g_mode[id]
			set_pdata_float(id, 83, 2.0, 5)
		}
		
		if(get_pdata_float(ent, 48, 4) <= 0.25)
		{
			set_weapon_anim(id, g_mode[id])
			set_pdata_float(ent, 48, 20.0, 4)
			return HAM_SUPERCEDE
		}
	}
	return HAM_IGNORED
}

public fw_Reload(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!Stock_CheckWeapon(id, true))
		return HAM_IGNORED
	
	g_iClip[id] = -1

	new iBpAmmo = Stock_Config_Bpammo(id, g_iCsWpn[id])
	new iClip = get_pdata_int(ent, 51, 4)
	
	static CurClip
	if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) CurClip = g_iMaxClip[id][0]
	else CurClip = g_iMaxClip[id][1]
	
	if(iBpAmmo <= 0 || iClip >= CurClip)
		return HAM_SUPERCEDE
		
	g_iClip[id] = iClip
	return HAM_IGNORED
}

public fw_Reload_Post(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!Stock_CheckWeapon(id, true))
		return HAM_IGNORED
	if(g_iClip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_iClip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	set_pdata_float(ent, 46, TimeReload(id), 4)
	set_pdata_float(ent, 48, TimeReload(id), 4)
	set_weapon_anim(id, Anim(id))
	
	g_mode[id] = 0 // Balrog-1
	cs_set_user_zoom(id, CS_SET_NO_ZOOM, 1)
	return HAM_IGNORED
}

public Float:TimeReload(id)
{
	new Float:Time
	if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) Time = (g_mode[id] ? 3.4 : 2.7)
	else if(get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5]) Time = 2.55
	else if(get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7]) Time = 4.05
	return Time
}

public Anim(id)
{
	new iAnim
	if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog[id][BALROG1]) iAnim = (g_mode[id] ? 8 : 4)
	else if(get_user_weapon(id) == CSW_BALROG5 && g_had_balrog[id][BALROG5]) iAnim = 4
	else if(get_user_weapon(id) == CSW_BALROG7 && g_had_balrog[id][BALROG7]) iAnim = 3
	return iAnim
}

public Shotgun_Reload(iEnt)
{
	static id, iClip, iMaxClip, fInSpecialReload, iBpAmmo
	id = get_pdata_cbase(iEnt, 41)
	iClip = get_pdata_int(iEnt, 51)
	iBpAmmo = Stock_Config_Bpammo(id, CSW_BALROG11)
	fInSpecialReload = get_pdata_int(iEnt, 55)
	iMaxClip = g_iMaxClip[id][1]
	
	if(get_user_weapon(id) != CSW_BALROG11 || !g_had_balrog[id][BALROG11])
		return HAM_IGNORED
	
	ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpecialReload)
	return HAM_SUPERCEDE
}

public Shotgun_Idle(iEnt)
{
	static id, iClip, iMaxClip, fInSpecialReload, iBpAmmo, Float:flTimeWeaponIdle
	id = get_pdata_cbase(iEnt, 41)
	flTimeWeaponIdle = get_pdata_float(iEnt, 48)
	iClip = get_pdata_int(iEnt, 51)
	fInSpecialReload = get_pdata_int(iEnt, 55)
	iBpAmmo = Stock_Config_Bpammo(id, CSW_BALROG11)
	iMaxClip = g_iMaxClip[id][1]

	if(get_user_weapon(id) != CSW_BALROG11 || !g_had_balrog[id][BALROG11])
		return HAM_IGNORED
	
	if(flTimeWeaponIdle <= 0.0)
	{
		if(!iClip && !fInSpecialReload && iBpAmmo) ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpecialReload)
		else if(fInSpecialReload != 0)
		{
			if(iClip != iMaxClip && iBpAmmo) ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpecialReload)
			else
			{
				set_weapon_anim(id, 4)
				set_pdata_int(iEnt, 55, 0)
				set_pdata_float(iEnt, 48, 0.55)
			}
		} else {
			set_weapon_anim(id, 0)
			set_pdata_float(iEnt, 48, 60.0)			
		}
	}
	return HAM_SUPERCEDE
}

public ShotgunReload(iEnt, iMaxClip, iClip, iBpAmmo, id, fInSpecialReload)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return
	if(get_pdata_int(iEnt, 46, 4) > 0.0)
		return
	
	if(!fInSpecialReload)
	{
		set_weapon_anim(id, 5)

		set_pdata_int(iEnt, 55, 1)
		set_nextattack(id, 0.55)
		set_weapon_timeidle(id, CSW_BALROG11, 0.55, 0.55)
	} else if(fInSpecialReload == 1) {
		set_pdata_int(iEnt, 55, 2)
		set_weapon_anim(id, 3)

		set_pdata_float(iEnt, 75, 0.3)
		set_pdata_float(iEnt, 48, 0.3)
	} else {
		set_pdata_int(iEnt, 51, iClip + 1)
		Stock_Config_Bpammo(id, CSW_BALROG11, iBpAmmo - 1, 1)
		set_pdata_int(iEnt, 55, 1)
	}
}

public Knife_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_BALROG9 || !g_had_balrog[id][BALROG9])
		return
	
	new iButton = pev(id, pev_button)
	Sp_Balrog9(id, ent, iButton)
}

public Sp_Balrog9(id, iEnt, iButton)
{
	if(get_pdata_float(iEnt, 46, 4) > 0.0 || get_pdata_float(iEnt, 47, 4) > 0.0)
		return
	
	if(iButton & IN_ATTACK)
	{
		iButton &= ~IN_ATTACK
		set_pev(id, pev_button, iButton)
		
		PunchAxis(id, random_float(-1.0, -2.0), random_float(0.5, 1.5))
		
		g_iSlash[id]++
		if(g_iSlash[id] > 2) g_iSlash[id] = 1
		
		static Random, iAnim
		if(g_iSlash[id] == 1)
		{
			Random = random_num(1, 2)
			switch(Random)
			{
				case 1: iAnim = 1
				case 2: iAnim = 3
			}
		} else if(g_iSlash[id] == 2) {
			Random = random_num(3, 5)
			switch(Random)
			{
				case 3: iAnim = 2
				case 4: iAnim = 4
				case 5: iAnim = 5
			}
		}
		set_weapon_anim(id, iAnim)
		
		new iSound[64]
		new iHitResult = KnifeAttack(id, false, 45.0, DAMAGE_BALROG9)
		switch(iHitResult)
		{
			case RESULT_HIT_PLAYER: format(iSound, charsmax(iSound), Balrog9_Sounds[random_num(4, 5)])
			case RESULT_HIT_WORLD: format(iSound, charsmax(iSound), Balrog9_Sounds[3])
			case RESULT_HIT_NONE: format(iSound, charsmax(iSound), Balrog9_Sounds[random_num(1, 2)])
		}
		Stock_PlaySound(id, CHAN_WEAPON, iSound)
		
		set_weapon_timeidle(id, CSW_BALROG9, iHitResult == RESULT_HIT_NONE ? 0.5 : 0.305, 1.23)
		set_nextattack(id, iHitResult == RESULT_HIT_NONE ? 0.5 : 0.305)
	}
	
	if(iButton & IN_ATTACK2)
	{
		switch(g_iCharge[id])
		{
			case 0:
			{
				set_weapon_anim(id, 7)
				set_weapon_timeidle(id, CSW_BALROG9, 0.74, 0.74)
				set_nextattack(id, 0.74)
				
				g_iCharge[id] = 1
				
			}
			case 1:
			{
				set_weapon_anim(id, 9)
				set_weapon_timeidle(id, CSW_BALROG9, 0.33, 0.33)
				set_nextattack(id, 0.33)
				
				g_iTimer[id] = get_gametime()
				g_iCharge[id] = 2
			}
			case 2:
			{
				set_weapon_anim(id, 9)
				set_weapon_timeidle(id, CSW_BALROG9, 0.33, 0.33)
				set_nextattack(id, 0.33)
				
				g_iCharge[id] = 2
				
				if(get_gametime() > (g_iTimer[id] + 2.0))
				{
					// Draw Muzzleflash
					static Float:Origin[3]
					Stock_Get_Postion(id, 8.0, 5.0, -3.0, Origin)
				
					engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
					write_byte(TE_SPRITE)
					engfunc(EngFunc_WriteCoord, Origin[0])
					engfunc(EngFunc_WriteCoord, Origin[1])
					engfunc(EngFunc_WriteCoord, Origin[2])
					write_short(g_iMuzz[g_iType[2]])
					write_byte(1)
					write_byte(255)
					message_end()
					
					set_weapon_anim(id, 8)
					set_weapon_timeidle(id, CSW_BALROG9, 0.33, 0.33)
					set_nextattack(id, 0.33)
					
					g_iCharge[id] = 3
				}
			}
			case 3:
			{
				set_weapon_anim(id, 10)
				set_weapon_timeidle(id, CSW_BALROG9, 0.33, 0.33)
				set_nextattack(id, 0.33)
				
				g_iCharge[id] = 3
			}
		}
		iButton &= ~IN_ATTACK
		iButton &= ~IN_ATTACK2
		set_pev(id, pev_button, iButton)
	} else {
		set_nextattack(id, 0.0)
		if(g_iCharge[id] == 1 || g_iCharge[id] == 2)
		{
			set_weapon_anim(id, 11)
			g_iCharge[id] = 0
			
			new iSound[64]
			new iHitResult = KnifeAttack(id, false, 45.0, DAMAGE_BALROG9)
			switch(iHitResult)
			{
				case RESULT_HIT_PLAYER: format(iSound, charsmax(iSound), Balrog9_Sounds[random_num(4, 5)])
				case RESULT_HIT_WORLD: format(iSound, charsmax(iSound), Balrog9_Sounds[3])
				case RESULT_HIT_NONE: format(iSound, charsmax(iSound), Balrog9_Sounds[random_num(1, 2)])
			}
			Stock_PlaySound(id, CHAN_WEAPON, iSound)
			
			set_weapon_timeidle(id, CSW_BALROG9, 1.0, 1.63)
			set_nextattack(id, 1.0)
		} else if(g_iCharge[id] == 3) {
			set_weapon_anim(id, 12)
			g_iCharge[id] = 0
			
			Stock_PlaySound(id, CHAN_WEAPON, Balrog9_Sounds[8])
			set_weapon_timeidle(id, CSW_BALROG9, 1.0, 1.63)
			set_nextattack(id, 1.0)
			
			new Float:vecScr[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
			new tr = create_tr2()
			
			GetGunPosition(id, vecScr)
			pev(id, pev_v_angle, v_angle)
			engfunc(EngFunc_MakeVectors, v_angle)
			global_get(glb_v_forward, vecForward)
			xs_vec_mul_scalar(vecForward, 55.0, vecForward)
			xs_vec_add(vecScr, vecForward, vecEnd)
			
			Stock_RadiusDamage(vecEnd, id, id, DAMAGE_BALROG9_EXP, 135.0, (1<<24), true, true)
			engfunc(EngFunc_TraceLine, vecScr, vecEnd, DONT_IGNORE_MONSTERS, id, tr)
				
			new pHit = get_tr2(tr, TR_pHit)
			if(pev_valid(pHit)) Stock_Fake_KnockBack(id, pHit, 120.0)
			free_tr2(tr)
			
			static Float:Origin[3]
			Stock_Get_Postion(id, 36.0, 0.0, 0.0, Origin)
			
			// DLight
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DLIGHT)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_byte(20)
			write_byte(200)
			write_byte(0)
			write_byte(0)
			write_byte(10)
			write_byte(60)
			message_end()
			
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, Origin[0] - 10.0) // engfunc because float
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2] - 10.0)
			write_short(g_iSpr[g_iType[2]][3]) // Sprite index
			write_byte(5) // Scale
			write_byte(35) // Framerate
			write_byte(4) // Flags
			message_end()
			
			// Exp
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(g_iSpr[g_iType[2]][1])	// sprite index
			write_byte(3)	// scale in 0.1's
			write_byte(5)	// framerate
			write_byte(4)	// flags
			message_end()
		}
	}
}

public SpecialShoot_Handle(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(!g_SpAmmo[id])
		return		
	
	const MAX_FIRE = 5
	static Float:StartOrigin[3], Float:EndOrigin[MAX_FIRE][3]
	Stock_Get_Attachment(id, StartOrigin, 40.0)
	
	CancelReload(id, 0)
	set_nextattack(id, 0.35)
	set_weapon_timeidle(id, CSW_BALROG11, 0.35, 0.85)
	Eject_Shell(id, g_shell)
	
	Update_SpAmmo(id, g_SpAmmo[id], 0)
	g_SpAmmo[id]--
	Update_SpAmmo(id, g_SpAmmo[id], 1)
	
	MakeMuzzleFlash(id, Muzzleflash[2])
	set_weapon_anim(id, 7)
	Stock_PlaySound(id, CHAN_WEAPON, Shoot_Sounds[10])
	
	Stock_Get_Postion(id, 512.0, -140.0, 0.0, EndOrigin[0])
	Stock_Get_Postion(id, 512.0, -70.0, 0.0, EndOrigin[1])
	
	Stock_Get_Postion(id, 512.0, 0.0, 0.0, EndOrigin[2])
	
	Stock_Get_Postion(id, 512.0, 70.0, 0.0, EndOrigin[3])
	Stock_Get_Postion(id, 512.0, 140.0, 0.0, EndOrigin[4])	
	
	for(new i = 0; i < MAX_FIRE; i++) Create_System(id, StartOrigin, EndOrigin[i], 700.0)
}

public Create_System(id, Float:StartOrigin[3], Float:EndOrigin[3], Float:Speed)
{
	static iEnt
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 255.0)
	set_pev(iEnt, pev_fuser1, get_gametime() + 0.55)	// time remove
	set_pev(iEnt, pev_scale, 0.1)
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.01)
	set_pev(iEnt, pev_classname, CLASSNAME_1)
	engfunc(EngFunc_SetModel, iEnt, Special_Spr[g_iType[1] == BALROG_RED ? 3 : 7])
	set_pev(iEnt, pev_mins, Float:{-16.0, -16.0, -16.0})
	set_pev(iEnt, pev_maxs, Float:{16.0, 16.0, 16.0})
	set_pev(iEnt, pev_origin, StartOrigin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_frame, 0.0)
	
	static Team
	if(cs_get_user_team(id) == CS_TEAM_T) Team = 1
	else if(cs_get_user_team(id) == CS_TEAM_CT) Team = 2
	set_pev(iEnt, pev_iuser3, Team)
	
	static Float:Velocity[3]
	Stock_GetSpeedVector(StartOrigin, EndOrigin, Speed, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)		
}

public Create_Fire(id, Float:Origin[3], Float:Scale, Float:Frame)
{
	static Ent
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	// set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 255.0)
	set_pev(Ent, pev_fuser1, get_gametime() + 0.07)	// time remove
	set_pev(Ent, pev_scale, Scale)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	set_pev(Ent, pev_classname, CLASSNAME_2)
	engfunc(EngFunc_SetModel, Ent, Special_Spr[g_iType[1] == BALROG_RED ? 3 : 7])
	set_pev(Ent, pev_mins, Float:{-10.0, -10.0, -10.0})
	set_pev(Ent, pev_maxs, Float:{10.0, 10.0, 10.0})
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_owner, id)	
	set_pev(Ent, pev_frame, Frame)
}

public message_DeathMsg()
{
	static attacker, victim
	attacker = get_msg_arg_int(1)
	victim = get_msg_arg_int(2)

	if(!is_user_connected(attacker) || attacker == victim)
		return PLUGIN_CONTINUE
		
	if(get_user_weapon(attacker) == CSW_BALROG1 && g_had_balrog[attacker][BALROG1]) set_msg_arg_string(4, "balrog1")
	else if(get_user_weapon(attacker) == CSW_BALROG3 && g_had_balrog[attacker][BALROG3]) set_msg_arg_string(4, "balrog3")
	else if(get_user_weapon(attacker) == CSW_BALROG5 && g_had_balrog[attacker][BALROG5]) set_msg_arg_string(4, "balrog5")
	else if(get_user_weapon(attacker) == CSW_BALROG7 && g_had_balrog[attacker][BALROG7]) set_msg_arg_string(4, "balrog7")
	else if(get_user_weapon(attacker) == CSW_BALROG9 && g_had_balrog[attacker][BALROG9]) set_msg_arg_string(4, "balrog9")
	else if(get_user_weapon(attacker) == CSW_BALROG11 && g_had_balrog[attacker][BALROG11]) set_msg_arg_string(4, "balrog11")
	return PLUGIN_CONTINUE
}

public Task_Balrog1(iTask)
{
	new id = iTask-TASK_BALROG1
	Create_Buff(id, 25, g_burn[g_iType[0]], 5)
	if(!is_user_alive(id)) remove_task(iTask)
}

stock set_weapon_timeidle(id, Weapon, Float:nextTime, Float:idle)
{
	static ent
	ent = fm_get_user_weapon_entity(id, Weapon)
	
	if(!pev_valid(ent))	
		return
		
	set_pdata_float(ent, 46, nextTime, 4)
	set_pdata_float(ent, 47, nextTime, 4)
	set_pdata_float(ent, 48, idle, 4)
}

stock set_nextattack(id, Float:nextTime) set_pdata_float(id, 83, nextTime, 5)
stock Stock_CheckWeapon(id, bool:IsReload)
{
	if(IsReload == true)
	{
		if((g_had_balrog[id][BALROG1] && get_user_weapon(id) == CSW_BALROG1) || (g_had_balrog[id][BALROG5] && get_user_weapon(id) == CSW_BALROG5)
		|| (g_had_balrog[id][BALROG7] && get_user_weapon(id) == CSW_BALROG7)) return 1
	} else {
		if((g_had_balrog[id][BALROG1] && get_user_weapon(id) == CSW_BALROG1) || (g_had_balrog[id][BALROG3] && get_user_weapon(id) == CSW_BALROG3)
		|| (g_had_balrog[id][BALROG5] && get_user_weapon(id) == CSW_BALROG5) || (g_had_balrog[id][BALROG7] && get_user_weapon(id) == CSW_BALROG7)
		|| (g_had_balrog[id][BALROG11] && get_user_weapon(id) == CSW_BALROG11)) return 1
	}
	return 0
}

stock Stock_Config_Bpammo(id, iCswpn, iAmmo = 0, iSet = 0)
{
	static iOffset
	switch(iCswpn)
	{
		case CSW_BALROG1: iOffset = 385
		case CSW_BALROG3: iOffset = 386
		case CSW_BALROG5: iOffset = 380
		case CSW_BALROG7: iOffset = 379
		case CSW_BALROG11: iOffset = 381
		default: return 0
	}
	if(iSet) set_pdata_int(id, iOffset, iAmmo, 4)
	else return get_pdata_int(id, iOffset, 4)
	return 0
}

public Update_Clip(id, iClip)
{
	if(!is_user_alive(id))
		return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(g_iCsWpn[id])
	write_byte(iClip)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(Stock_Config_Bpammo(id, g_iCsWpn[id]))
	message_end()
}

public Update_SpAmmo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()
}

stock Stock_WeaponSPR(id, type, num, Default[], PriAmmoId, PriAmmoMax, SlotID, NumSlot, Wpn)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_balrog[id][type] == 1 ? (g_iType[num] == BALROG_RED ? Weapon_Spr_Red[type] : Weapon_Spr_Blue[type]) : Default)
	write_byte(PriAmmoId)
	write_byte(PriAmmoMax)
	write_byte(-1)
	write_byte(-1)
	write_byte(SlotID)
	write_byte(NumSlot)
	write_byte(Wpn)
	write_byte(0)
	message_end()
}

stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, bitsDamageType, bool:bSkipAttacker, bool:bCheckTeam)
{
	new pEntity = -1
	new iHitResult = RESULT_HIT_NONE
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	vecSrc[2] += 1.0
	if(!pevAttacker) pevAttacker = pevInflictor

	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
		if(bInWater && !pev(pEntity, pev_waterlevel)) continue
		if(!bInWater && pev(pEntity, pev_waterlevel) == 3) continue
		if(bCheckTeam && IsPlayer(pEntity) && pEntity != pevAttacker) if(!can_damage(pevAttacker, pEntity)) continue
		if(bSkipAttacker && pEntity == pevAttacker) continue
		
		if(pev_valid(pEntity))
		{
			ExecuteHam(Ham_TakeDamage, pEntity, pevInflictor, pevAttacker, Float:flDamage, bitsDamageType)
			iHitResult = RESULT_HIT_PLAYER
		}
	}
	return iHitResult
}

stock Stock_GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock Create_Buff(id, damage, spr, scale)
{
	new Float:vOri[3]
	pev(id, pev_origin, vOri)
		
	if(id < 33 && pev_valid(id))
	{
		if(is_user_alive(id))
		{
			static health
			health = get_user_health(id)
			
			if(health - damage >= 1) fm_set_user_health(id, health - damage)
			else user_kill(id)
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, vOri[0])
			engfunc(EngFunc_WriteCoord, vOri[1])
			engfunc(EngFunc_WriteCoord, vOri[2])
			write_short(spr)
			write_byte(scale)
			write_byte(255)
			message_end()
		}
	}
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1

	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}

stock CancelReload(id, ent)
{
	new iEnt
	iEnt = fm_get_user_weapon_entity(id, CSW_BALROG11)
	
	if(!pev_valid(iEnt))
		return
	
	set_pdata_int(ent ? ent : iEnt, 55, 0)
}

stock set_weapon_anim(id, WeaponAnim)
{
	set_pev(id, pev_weaponanim, WeaponAnim)
    
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(WeaponAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Eject_Shell(id, iShell) // By Dias
{
	static Ent
	Ent = get_pdata_cbase(id, 373, 5)
	
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, iShell, 4)
        set_pdata_float(id, 111, get_gametime())
}

stock fm_cs_get_weapon_ent_owner(ent) return get_pdata_cbase(ent, 41, 4)
stock Stock_PlaySound(id, channel, sound[]) emit_sound(id, channel, sound, 1.0, ATTN_NORM, 0, random_num(95, 120))
stock IsPlayer(pEntity) return is_user_connected(pEntity)

stock IsHostage(pEntity)
{
	new classname[32]
	pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

stock IsAlive(pEntity)
{
	if(pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	// Weapon bitsums
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_DEAGLE)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_FIVESEVEN)
	
	for(i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_BulletHole(id, Float:Origin[3], Float:Damage) // Dias
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Stock_BulletSmoke(id, trace_result)
{
	static Body, Target
	get_user_aiming(id, Target, Body)
	
	if(is_user_connected(Target) || is_user_alive(Target))
		return
	
	static Float:vecSrc[3], Float:vecEnd[3]
	Stock_Get_Attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(s_puff)
	write_byte(2)
	write_byte(50)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

stock Stock_Get_Attachment(id, Float:output[3], Float:fDis = 40.0)
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

stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock Stock_PrecacheSound(const WpnModel[])
{
	new file, i, k
	if((file = fopen(WpnModel, "rt")))
	{
		new SzSoundPath[64]
		new NumSeq, SeqId
		new Event, NumEvents, EventId
		
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqId, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqId + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventId, BLOCK_INT)
			fseek(file, EventId + 176 * i, SEEK_SET)

			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventId + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, SzSoundPath, 64, BLOCK_CHAR)
				if(strlen(SzSoundPath))
				{
					strtolower(SzSoundPath)
					engfunc(EngFunc_PrecacheSound, SzSoundPath)
				}
			}
		}
	}
	fclose(file)
}

stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}

stock PunchAxis(id, Float:x, Float:y)
{
	new Float:vec[3]
	pev(id, pev_punchangle, vec)
	
	vec[0] += x
	vec[1] += y
	set_pev(id, pev_punchangle, vec)
}

public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 400.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.5, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}

stock KnifeAttack(id, bool:bStab, Float:fRange, Float:flDamage)
{
	new Float:vecScr[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecScr)
	
	pev(id, pev_v_angle, v_angle)
	engfunc(EngFunc_MakeVectors, v_angle)
	global_get(glb_v_forward, vecForward)
	xs_vec_mul_scalar(vecForward, fRange, vecForward)
	xs_vec_add(vecScr, vecForward, vecEnd)

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecScr, vecEnd, 0, id, tr)
	
	new Float:flFraction
	get_tr2(tr, TR_flFraction, flFraction)
	
	if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecScr, vecEnd, 0, 3, id, tr)
	new iHitResult = RESULT_HIT_NONE
	
	if(flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit)
		iHitResult = RESULT_HIT_WORLD

		if(pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if(CheckBack(id, pEntity) && bStab) flDamage *= 3.0
			iHitResult = RESULT_HIT_PLAYER
		}

		if(pev_valid(pEntity))
		{
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, DMG_NEVERGIB | DMG_BULLET);
			ExecuteHamB(Ham_TakeDamage, pEntity, id, id, flDamage, DMG_NEVERGIB | DMG_BULLET)
		}
	}
	free_tr2(tr)
	return iHitResult
}

stock CheckBack(iEnemy, id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	
	new Float:angle = anglea[1] - anglev[1] 
	if(angle < -180.0) angle += 360.0
	if(angle <= 45.0 && angle >= -45.0) return 1
	return 0
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
