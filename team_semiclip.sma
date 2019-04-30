/*================================================================================
 [Plugin Customization]
=================================================================================*/

const Float:CVAR_INTERVAL  = 6.0		/* ¬ 6.0 */
const Float:SPEC_INTERVAL  = 0.2		/* ¬ 0.2 */
const Float:RANGE_INTERVAL = 0.1		/* It's like a 10 FPS server (look RANGE_CHECK_ON_SEMICLIP comment) ¬ 0.1 */

const Float:ANTI_BOOST_DISTANCE = 85.041168	/* ¬ 85.041168 */

#define MAX_HOSTAGE     6	/* Have seen maps with more as 4 hostages ¬ 6 */
#define MAX_PLAYERS     32	/* Server slots ¬ 32 */
#define MAX_CSDM_SPAWNS 60	/* CSDM 2.1.2 value if you have more increase it ¬ 60 */
#define MAX_ENT_ARRAY   128	/* Is for max 4096 entities (128*32=4096) ¬ 128 */

/*	Uncomment the line below to have range check in semiclip start forward maybe most
	useful for surf servers this call any 1/FPS in seconds indeed of RANGE_INTERVAL.
	Use at your own risk, for server with a high 1000 FPS setup (cause lags).
	*/
//#define RANGE_CHECK_ON_SEMICLIP

/*	Uncomment the line below to have player -> hostage semiclip.
	*/
#define HOSTAGE_SEMICLIP

/*	Uncomment the line below to fix entity movement stop.
	*/
#define FIX_MOVING_ENTITIES

/*	Uncomment the line below when you have defined FIX_MOVING_ENTITIES and have any mods
	or plugins they you can grab, change or moving the origins of func_door_rotating.
	Because this Team Semiclip plugin set, calculate and store the real center of
	func_door_rotating (it's a constant origin position without moving) and working
	with that. This have nothing todo with the rotating.
	*/
//#define FIX_DOOR_ROTATING_CENTER

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/* Just a little bit extra, not too much */
#pragma dynamic 8192

#include <amxmodx>

#if AMXX_VERSION_NUM < 182
	#assert AMX Mod X v1.8.2 or later library required!
#endif

#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

/*================================================================================
 [TODO]
 
 ! last 20% from func_door_rotating (after a lot of tests, i think it's not possible ¬.¬)
 ! other entities they stop movement
 
=================================================================================*/

/*================================================================================
 [Constants, Offsets and Defines]
=================================================================================*/

new const PLUGIN_VERSION[]        = "3.0.2"
new const CT_SPAWN_ENTITY_NAME[]  = "info_player_start"
new const TER_SPAWN_ENTITY_NAME[] = "info_player_deathmatch"

const pev_spec_mode     = pev_iuser1
const pev_spec_target   = pev_iuser2
const pev_hostage_index = pev_iuser3 /* hostage: pev_iuser1 and pev_iuser2 get a reset... */
const pev_entity_radius = pev_fuser1
#if !defined FIX_DOOR_ROTATING_CENTER
const pev_real_center   = pev_vuser1
#endif // !FIX_DOOR_ROTATING_CENTER

const m_hObserverTarget  = 447
const m_pPlayer          = 41
const linux_diff         = 5
const mac_diff           = 5	/* the same? (i don't have a mac pc or server) */
const linux_weapons_diff = 4
const mac_weapons_diff   = 4	/* the same? (i don't have a mac pc or server) */
const pdata_safe         = 2

new Ham:Ham_Player_SemiclipStart = Ham_Player_UpdateClientData	/* Ham_Player_UpdateClientData | Ham_Player_PreThink */
new Ham:Ham_Player_SemiclipEnd   = Ham_Item_ItemSlot			/* Ham_Item_ItemSlot | Ham_Player_PostThink */

#if defined FIX_MOVING_ENTITIES
new Ham:Ham_Entity_MovingStart = Ham_SetObjectCollisionBox
new Ham:Ham_Entity_RotateStart = Ham_Item_UpdateItemInfo

new FM_Entity_MovingEnd = FM_UpdateClientData
new FM_Entity_RotateEnd = FM_SetAbsBox
#endif // FIX_MOVING_ENTITIES

enum (+= 35)
{
	TASK_SPECTATOR = 5000,
	TASK_RANGE,
	TASK_DURATION,
	TASK_PREPARATION,
	TASK_CVARS,
	TASK_CZBOTS
}

new const Float:RANDOM_OWN_PLACE[][3] =
{
	{ -32.1,   0.0, 0.0 },
	{  32.1,   0.0, 0.0 },
	{   0.0, -32.1, 0.0 },
	{   0.0,  32.1, 0.0 },
	{ -32.1, -32.1, 0.0 },
	{ -32.1,  32.1, 0.0 },
	{  32.1,  32.1, 0.0 },
	{  32.1, -32.1, 0.0 }
}

/* tsc_set_user_rendering */
enum
{
	SPECIAL_MODE = 0,
	SPECIAL_AMT,
	SPECIAL_FX,
	MAX_SPECIAL
}

enum
{
	COLOR_CT = 0,
	COLOR_TER,
	COLOR_ADMIN_CT,
	COLOR_ADMIN_TER,
	COLOR_HOSTAGE,
	COLOR_VIP,
	MAX_COLORS
}

#if defined FIX_MOVING_ENTITIES
enum
{
	RADIUS_ABS = 1,
	RADIUS_ROTATE,
	RADIUS_VEHICLE
}
#endif

#define OUT_OF_RANGE -1

/*================================================================================
 [Global Variables]
=================================================================================*/

/* Cvar Global */
new cvar_iSemiclip,
	cvar_iSemiclipBlockTeam,
	cvar_iSemiclipEnemies,
	cvar_iSemiclipButton,
	cvar_iSemiclipButtonTrigger,
	cvar_iSemiclipButtonAntiBoost,
	cvar_iSemiclipUnstuck,
	cvar_iSemiclipKnifeTrace,
	cvar_iSemiclipRender,
	cvar_iSemiclipNormalMode,
	cvar_iSemiclipNormalFx,
	cvar_iSemiclipNormalAmt,
	cvar_iSemiclipNormalSpec,
	cvar_iSemiclipFadeMode,
	cvar_iSemiclipFadeFx,
	cvar_iSemiclipFadeSpec,
	cvar_iBotQuota

new cvar_flSemiclipRadius,
	cvar_flSemiclipUnstuckDelay,
	cvar_flSemiclipPreparation,
	cvar_flSemiclipDuration,
	cvar_flSemiclipFadeMin,
	cvar_flSemiclipFadeMax

new cvar_szSemiclipColorFlag,
	cvar_szSemiclipColors[MAX_COLORS]

/* Cvar Cached */
new c_iSemiclip,
	c_iBlockTeam,
	c_iEnemies,
	c_iButton,
	c_iButtonTrigger,
	c_iButtonAntiBoost,
	c_iUnstuck,
	c_iKnifeTrace,
	c_iRender,
	c_iNormalMode,
	c_iNormalFx,
	c_iNormalAmt,
	c_iNormalSpec,
	c_iFadeMode,
	c_iFadeFx,
	c_iFadeSpec,
	c_iColorFlag,
	c_iColors[MAX_COLORS][3]

new Float:c_flRadius,
	Float:c_flUnstuckDelay,
	Float:c_flFadeMin,
	Float:c_flFadeMax

/* Server Global */
new bool:g_bPreparation

new g_iAddToFullPack,
	g_iCmdStart,
	g_iTraceLine,
	g_iBlocked

new g_iMaxPlayers,
	g_iHamCzBots,
	g_iCvarEntity

new g_iSpawnCountCTs,
	g_iSpawnCountTer,
	g_iSpawnCountCSDM

new Float:g_flSpawnsCTs[24][3],
	Float:g_flSpawnsTer[24][3],
	Float:g_flSpawnsCSDM[MAX_CSDM_SPAWNS][3]

/* Client Global */
new g_iTeam[MAX_PLAYERS+1],
	g_iRange[MAX_PLAYERS+1][MAX_PLAYERS+1],
	g_iSpectating[MAX_PLAYERS+1],
	g_iSpectatingTeam[MAX_PLAYERS+1],
	g_iAntiBoost[MAX_PLAYERS+1][MAX_PLAYERS+1]

/* Bitsum */
new bs_IsConnected,
	bs_IsAlive,
	bs_IsBot,
	bs_IsSolid,
	bs_IsAdmin,
	bs_InButton,
	bs_InAntiBoost,
	bs_WasInButton,
	bs_InKnifeSecAtk,
	bs_IsVip,
	bs_IsDying

/* tsc_set_user_rendering */
new bs_RenderSpecial
new g_iRenderSpecial[MAX_PLAYERS+1][MAX_SPECIAL],
	g_iRenderSpecialColor[MAX_PLAYERS+1][MAX_SPECIAL]

#if defined HOSTAGE_SEMICLIP
/* Hostage */
new bs_IsHostage[MAX_ENT_ARRAY],
	bs_HostageIsSolid[MAX_ENT_ARRAY],
	bs_HostageIsRescued[MAX_ENT_ARRAY],
	bs_HostageIsKilled[MAX_ENT_ARRAY]

new cvar_iSemiclipHostage,
	c_iHostage

new g_iHostage[MAX_HOSTAGE],
	g_iHostageRange[MAX_PLAYERS+1][MAX_HOSTAGE],
	g_iHostageCount
#endif // HOSTAGE_SEMICLIP

#if defined FIX_MOVING_ENTITIES
/* Moving Entities */
new g_iEntityRotate

new bs_IsDoorRotating[MAX_ENT_ARRAY],
	bs_IsVehicle[MAX_ENT_ARRAY]

new HamHook:g_iHamFuncDoor,
	HamHook:g_iHamFuncVehicle,
	HamHook:g_iHamFuncTrain,
	HamHook:g_iHamFuncDoorRotating,
	HamHook:g_iHamFuncTrackTrain,
	HamHook:g_iHamFuncRotating

new g_iEntityMovingEnd,
	g_iEntityRotateEnd

new g_iRotateEntity[MAX_PLAYERS+1]
#endif // FIX_MOVING_ENTITIES

/*================================================================================
 [Macros]
=================================================================================*/

#define ID_SPECTATOR	(taskid - TASK_SPECTATOR)
#define ID_RANGE		(taskid - TASK_RANGE)

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#define get_bitsum_array(%1,%2)   (%1[(%2-1)/32] &   (1<<((%2-1)&31)))
#define add_bitsum_array(%1,%2)    %1[(%2-1)/32] |=  (1<<((%2-1)&31))
#define del_bitsum_array(%1,%2)    %1[(%2-1)/32] &= ~(1<<((%2-1)&31))

#define UTIL_Vector_Add(%1,%2,%3)		(%3[0] = %1[0] + %2[0], %3[1] = %1[1] + %2[1], %3[2] = %1[2] + %2[2]);
#define UTIL_Vector_Center(%1,%2,%3,%4)	(%4[0] = %1[0] + (%2[0] + %3[0]) * 0.5, %4[1] = %1[1] + (%2[1] + %3[1]) * 0.5, %4[2] = %1[2] + (%2[2] + %3[2]) * 0.5);
#define UTIL_Vector_Null(%1)			(%1[0] = 0.0, %1[1] = 0.0, %1[2] = 0.0);

#define is_user_valid(%1)			(1 <= %1 <= g_iMaxPlayers)
#define is_user_valid_connected(%1)	(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsConnected, %1))
#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1) && !get_bitsum(bs_IsDying, %1))
#define is_same_team(%1,%2)			(g_iTeam[%1] == g_iTeam[%2])

/*================================================================================
 [Zombie Plague Mod]
=================================================================================*/

native zp_has_round_started()

new bool:g_bZpReallyRunning

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_natives()
{
	/* TODO: maybe more? */
	register_native("tsc_get_user_rendering", "fn_get_user_rendering")
	register_native("tsc_set_user_rendering", "fn_set_user_rendering")
	register_native("tsc_get_user_semiclip", "fn_get_user_semiclip")
	register_native("tsc_get_user_anti_boost", "fn_get_user_anti_boost")
	register_library("cs_team_semiclip")
	
	set_native_filter("native_filter")
}
public native_filter(const name[], index, trap)
{
	if (equal(name, "zp_has_round_started") && trap)
	{
		g_bZpReallyRunning = false
		return PLUGIN_HANDLED
	}
	
	return (!trap) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public plugin_init()
{
	/* Check mod and register plugin */
	CheckMods()
	
	/* AMX Mod X check */
	CheckAmxxVersion()
	
	/* Check max Entities */
	CheckMaxEntities()
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0")
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")
	register_logevent("EventBecameVip", 3, "1=triggered", "2=Became_VIP")
	
	#if defined HOSTAGE_SEMICLIP
	register_event("SendAudio", "EventHostageRescued", "a", "2&%!MRAD_rescued", "2&%!MRAD_escaped")
	register_logevent("EventHostageKilled", 3, "1=triggered", "2=Killed_A_Hostage")
	#endif // HOSTAGE_SEMICLIP
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", false)
	RegisterHam(Ham_Player_SemiclipStart, "player", "fw_PlayerSemiclip_Start", true)
	RegisterHam(Ham_Player_SemiclipEnd, "player", "fw_PlayerSemiclip_End", false)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Knife_PrimaryAttack", false)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Knife_SecondaryAttack", false)
	
	#if defined FIX_MOVING_ENTITIES
	DisableHamForward(g_iHamFuncDoor = RegisterHam(Ham_Entity_MovingStart, "func_door", "fw_EntityMoving_Start", true))
	DisableHamForward(g_iHamFuncVehicle = RegisterHam(Ham_Entity_MovingStart, "func_vehicle", "fw_EntityMoving_Start", true))
	DisableHamForward(g_iHamFuncTrain = RegisterHam(Ham_Entity_MovingStart, "func_train", "fw_EntityMoving_Start", true))
	DisableHamForward(g_iHamFuncDoorRotating = RegisterHam(Ham_Entity_RotateStart, "func_door", "fw_EntityRotate_Start", true))
	DisableHamForward(g_iHamFuncTrackTrain = RegisterHam(Ham_Entity_MovingStart, "func_tracktrain", "fw_EntityMoving_Start", true))
	DisableHamForward(g_iHamFuncRotating = RegisterHam(Ham_Entity_MovingStart, "func_rotating", "fw_EntityMoving_Start", true))
	#endif // FIX_MOVING_ENTITIES
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	
	register_message(get_user_msgid("TeamInfo"), "MessageTeamInfo")
	register_message(get_user_msgid("ClCorpse"), "MessageClCorpse")
	
	/* General */
	cvar_iSemiclip = register_cvar("semiclip", "1")
	cvar_iSemiclipBlockTeam = register_cvar("semiclip_block_team", "0")
	cvar_iSemiclipEnemies = register_cvar("semiclip_enemies", "0")
	cvar_flSemiclipRadius = register_cvar("semiclip_radius", "250.0")
	
	/* Button */
	cvar_iSemiclipButton = register_cvar("semiclip_button", "0")
	cvar_iSemiclipButtonTrigger = register_cvar("semiclip_button_trigger", "32")
	cvar_iSemiclipButtonAntiBoost = register_cvar("semiclip_button_anti_boost", "1")
	
	/* Unstuck */
	cvar_iSemiclipUnstuck = register_cvar("semiclip_unstuck", "1")
	cvar_flSemiclipUnstuckDelay = register_cvar("semiclip_unstuck_delay", "0")
	
	#if defined HOSTAGE_SEMICLIP
	/* Hostage */
	cvar_iSemiclipHostage = register_cvar("semiclip_hostage", "0")
	#endif // HOSTAGE_SEMICLIP
	
	/* Other */
	cvar_iSemiclipKnifeTrace = register_cvar("semiclip_knife_trace", "0")
	cvar_flSemiclipPreparation = register_cvar("semiclip_preparation", "0")
	cvar_flSemiclipDuration = register_cvar("semiclip_duration", "0")
	
	/* Render */
	cvar_iSemiclipRender = register_cvar("semiclip_render", "0")
	
	/* Normal */
	cvar_iSemiclipNormalMode = register_cvar("semiclip_normal_mode", "1")
	cvar_iSemiclipNormalFx   = register_cvar("semiclip_normal_fx", "19")
	cvar_iSemiclipNormalAmt  = register_cvar("semiclip_normal_amt", "4")
	cvar_iSemiclipNormalSpec = register_cvar("semiclip_normal_spec", "0")
	
	/* Fade */
	cvar_iSemiclipFadeMode = register_cvar("semiclip_fade_mode", "2")
	cvar_iSemiclipFadeFx   = register_cvar("semiclip_fade_fx", "0")
	cvar_flSemiclipFadeMin = register_cvar("semiclip_fade_min", "130")
	cvar_flSemiclipFadeMax = register_cvar("semiclip_fade_max", "225")
	cvar_iSemiclipFadeSpec = register_cvar("semiclip_fade_spec", "0")
	
	/* Color */
	cvar_szSemiclipColorFlag = register_cvar("semiclip_color_admin_flag", "b")
	cvar_szSemiclipColors[COLOR_ADMIN_TER] = register_cvar("semiclip_color_admin_ter", "255 63 63")
	cvar_szSemiclipColors[COLOR_ADMIN_CT] = register_cvar("semiclip_color_admin_ct", "153 204 255")
	cvar_szSemiclipColors[COLOR_TER] = register_cvar("semiclip_color_ter", "255 63 63")
	cvar_szSemiclipColors[COLOR_CT] = register_cvar("semiclip_color_ct", "153 204 255")
	cvar_szSemiclipColors[COLOR_HOSTAGE] = register_cvar("semiclip_color_hos", "192 148 32")
	cvar_szSemiclipColors[COLOR_VIP] = register_cvar("semiclip_color_vip", "192 148 32")
	
	#if defined FIX_MOVING_ENTITIES
	/* Check if Hamsandwich 1.4 is installed with Ham_CS_Player_Blind (190) */
	new iHamUpdate = 190
	if (IsHamValid(Ham:iHamUpdate))
		state FixedHamCenter
	#endif // FIX_MOVING_ENTITIES
	
	register_cvar("Team_Semiclip_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Team_Semiclip_version", PLUGIN_VERSION)
	
	cvar_iBotQuota = get_cvar_pointer("bot_quota")
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	new szConfigDir[35]
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	server_cmd("exec %s/cs_team_semiclip.cfg", szConfigDir)
	
	CreateCvarEntityTask()
	
	set_task(1.5, "LoadSpawns")
	
	#if defined HOSTAGE_SEMICLIP
	new iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, "hostage_entity")) != 0)
	{
		g_iHostage[g_iHostageCount] = iEnt
		add_bitsum_array(bs_IsHostage, iEnt)
		set_pev(iEnt, pev_hostage_index, g_iHostageCount)
		
		if (++g_iHostageCount >= MAX_HOSTAGE)
			break
	}
	#endif // HOSTAGE_SEMICLIP
	
	#if defined FIX_MOVING_ENTITIES
	SetEntityRadius("func_door", RADIUS_ABS)
	SetEntityRadius("func_train", RADIUS_ABS)
	SetEntityRadius("func_tracktrain", RADIUS_ABS)
	SetEntityRadius("func_rotating", RADIUS_ABS)
	
	SetEntityRadius("func_door_rotating", RADIUS_ROTATE)
	
	SetEntityRadius("func_vehicle", RADIUS_VEHICLE)
	#endif // FIX_MOVING_ENTITIES
}

/*================================================================================
 [Pause, Unpause]
=================================================================================*/

public plugin_pause()
{
	unregister_forward(FM_AddToFullPack, g_iAddToFullPack, true)
	unregister_forward(FM_CmdStart, g_iCmdStart, true)
	unregister_forward(FM_Blocked, g_iBlocked, false)
	
	#if defined FIX_MOVING_ENTITIES
	if (g_iEntityMovingEnd) unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	if (g_iEntityRotateEnd) unregister_forward(FM_Entity_RotateEnd, g_iEntityRotateEnd, false)
	g_iEntityMovingEnd = g_iEntityRotateEnd = 0
	#endif // FIX_MOVING_ENTITIES
	
	remove_task(TASK_CVARS)
	remove_task(TASK_DURATION)
	remove_task(TASK_PREPARATION)
	
	if (g_iCvarEntity && pev_valid(g_iCvarEntity))
		remove_entity(g_iCvarEntity)
	
	#if defined HOSTAGE_SEMICLIP
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos) || get_bitsum_array(bs_HostageIsKilled, iHos) || get_bitsum_array(bs_HostageIsSolid, iHos))
				continue
			
			set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	#endif // HOSTAGE_SEMICLIP
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			goto Label_Disconnect
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (is_player_stuck(id))
			DoRandomSpawn(id)
		
		Label_Disconnect:
		client_disconnect(id)
	}
}

public plugin_unpause()
{
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	
	bs_IsVip = 0
	
	#if defined HOSTAGE_SEMICLIP
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (!get_bitsum_array(bs_HostageIsRescued, iHos) && pev(iHos, pev_effects) & EF_NODRAW)
			{
				add_bitsum_array(bs_HostageIsRescued, iHos)
			}
			else if (!get_bitsum_array(bs_HostageIsKilled, iHos) && !pev(iHos, pev_health))
			{
				add_bitsum_array(bs_HostageIsKilled, iHos)
			}
			else
			{
				del_bitsum_array(bs_HostageIsRescued, iHos)
				del_bitsum_array(bs_HostageIsKilled, iHos)
				
				set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
				add_bitsum_array(bs_HostageIsSolid, iHos)
				
				continue
			}
			
			set_pev(iHos, pev_solid, SOLID_NOT)
			del_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	#endif // HOSTAGE_SEMICLIP
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		/* disconnected while pausing? */
		if (!is_user_connected(id))
			continue
		
		/* do all other staff */
		client_putinserver(id)
		g_iTeam[id] = _:cs_get_user_team(id)
		
		if (is_user_alive(id))
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsSolid, id)
			
			if (cs_get_user_vip(id))
				add_bitsum(bs_IsVip, id)
		}
		else if (pev(id, pev_deadflag) == DEAD_DYING)
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsDying, id)
		}
	}
	
	CacheCvars(TASK_CVARS)
	CreateCvarEntityTask()
}

/*================================================================================
 [Put in, Disconnect]
=================================================================================*/

public client_authorized(id)
{
	if (is_user_bot(id) && !g_iHamCzBots && cvar_iBotQuota && get_pcvar_num(cvar_iBotQuota))
	{
		set_task(0.1, "StopCzBotForward", TASK_CZBOTS) /* Fake Client? */
		g_iHamCzBots = register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue", false)
	}
}

public client_putinserver(id)
{
	add_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id)
		add_bitsum(bs_InButton, id)
	}
	else set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	
	#if !defined RANGE_CHECK_ON_SEMICLIP
	set_task(RANGE_INTERVAL, "RangeCheck", id+TASK_RANGE, _, _, "b")
	#endif // !RANGE_CHECK_ON_SEMICLIP
}

public client_disconnect(id)
{
	del_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	#if !defined RANGE_CHECK_ON_SEMICLIP
	remove_task(id+TASK_RANGE)
	#endif // !RANGE_CHECK_ON_SEMICLIP
	
	remove_task(id+TASK_SPECTATOR)
}

/*================================================================================
 [Main Events]
=================================================================================*/

/* Hostage is SOLID_NOT and in EF_NODRAW when rescued.
   Hostage have no health when killed. */
public EventRoundStart()
{
	#if defined FIX_MOVING_ENTITIES
	DisableHamForward(g_iHamFuncDoor)
	DisableHamForward(g_iHamFuncVehicle)
	DisableHamForward(g_iHamFuncTrain)
	DisableHamForward(g_iHamFuncDoorRotating)
	DisableHamForward(g_iHamFuncTrackTrain)
	DisableHamForward(g_iHamFuncRotating)
	
	if (g_iEntityMovingEnd) unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	if (g_iEntityRotateEnd) unregister_forward(FM_Entity_RotateEnd, g_iEntityRotateEnd, false)
	g_iEntityMovingEnd = g_iEntityRotateEnd = 0
	#endif // FIX_MOVING_ENTITIES
	
	remove_task(TASK_DURATION)
	remove_task(TASK_PREPARATION)
	
	new Float:flDuration = get_pcvar_float(cvar_flSemiclipDuration)
	new Float:flPreparation = get_pcvar_float(cvar_flSemiclipPreparation)
	
	/* Duration > Preparation */
	if (flDuration >= 0.1)
	{
		set_pcvar_num(cvar_iSemiclip, 1)
		c_iSemiclip = 1
		g_bPreparation = true
		
		set_task(flDuration, "DisableTask", TASK_DURATION)
	}
	
	if (flPreparation >= 0.1)
	{
		g_bPreparation = true
		
		set_task(flPreparation, "DisableTask", TASK_PREPARATION)
	}
}

/* It's dosen't matter if freezetime is 0, all hostage values are already set. thanks valve :) */
public LogEventRoundStart()
{
	#if defined FIX_MOVING_ENTITIES
	EnableHamForward(g_iHamFuncDoor)
	EnableHamForward(g_iHamFuncVehicle)
	EnableHamForward(g_iHamFuncTrain)
	EnableHamForward(g_iHamFuncDoorRotating)
	EnableHamForward(g_iHamFuncTrackTrain)
	EnableHamForward(g_iHamFuncRotating)
	#endif // FIX_MOVING_ENTITIES
	
	#if defined HOSTAGE_SEMICLIP
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			del_bitsum_array(bs_HostageIsRescued, iHos)
			del_bitsum_array(bs_HostageIsKilled, iHos)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
}

public EventHostageRescued()
{
	static id, iHos
	for (id = 0; id < g_iHostageCount; id++)
	{
		iHos = g_iHostage[id]
		
		if (!get_bitsum_array(bs_HostageIsRescued, iHos) && pev(iHos, pev_effects) & EF_NODRAW)
		{
			add_bitsum_array(bs_HostageIsRescued, iHos)
		}
		else continue
		
		set_pev(iHos, pev_solid, SOLID_NOT)
		del_bitsum_array(bs_HostageIsSolid, iHos)
	}
}

public EventHostageKilled()
{
	static id, iHos
	for (id = 0; id < g_iHostageCount; id++)
	{
		iHos = g_iHostage[id]
		
		if (!get_bitsum_array(bs_HostageIsKilled, iHos) && !pev(iHos, pev_health))
		{
			add_bitsum_array(bs_HostageIsKilled, iHos)
		}
		else continue
		
		set_pev(iHos, pev_solid, SOLID_NOT)
		del_bitsum_array(bs_HostageIsSolid, iHos)
	}
}
#else // !HOSTAGE_SEMICLIP
}
#endif // HOSTAGE_SEMICLIP

public EventBecameVip()
{
	bs_IsVip = 0
	
	new szLogUser[80], szName[32]
	read_logargv(0, szLogUser, charsmax(szLogUser))
	parse_loguser(szLogUser, szName, charsmax(szName))
	
	add_bitsum(bs_IsVip, get_user_index(szName))
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeam[id])
		return
	
	remove_task(id+TASK_SPECTATOR)
	
	add_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	add_bitsum(bs_IsSolid, id)
}

public fw_PlayerKilled(id)
{
	add_bitsum(bs_IsDying, id)
	del_bitsum(bs_IsSolid, id)
}

public fw_PlayerSemiclip_Start(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	#if defined RANGE_CHECK_ON_SEMICLIP
	RangeCheck(id+TASK_RANGE)
	#endif // RANGE_CHECK_ON_SEMICLIP
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsSolid, i) || g_iRange[id][i] == OUT_OF_RANGE || !AllowSemiclip(id, i))
			continue
		
		set_pev(i, pev_solid, SOLID_NOT)
		del_bitsum(bs_IsSolid, i)
	}
	
	#if defined HOSTAGE_SEMICLIP
	if (g_iHostageCount && (c_iHostage == 3 || c_iHostage == g_iTeam[id]))
	{
		static iHos
		for (i = 0; i < g_iHostageCount; i++)
		{
			iHos = g_iHostage[i]
			
			if (!get_bitsum_array(bs_HostageIsSolid, iHos) || g_iHostageRange[id][i] == OUT_OF_RANGE)
				continue
			
			set_pev(iHos, pev_solid, SOLID_NOT)
			del_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	#endif // HOSTAGE_SEMICLIP
}

public fw_PlayerSemiclip_End(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || get_bitsum(bs_IsSolid, i))
			continue
		
		set_pev(i, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, i)
	}
	
	#if defined HOSTAGE_SEMICLIP
	if (c_iHostage && g_iHostageCount)
	{
		static iHos
		for (i = 0; i < g_iHostageCount; i++)
		{
			iHos = g_iHostage[i]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos) || get_bitsum_array(bs_HostageIsKilled, iHos) || get_bitsum_array(bs_HostageIsSolid, iHos))
				continue
			
			set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	#endif // HOSTAGE_SEMICLIP
}

/* Slash - 48.0 */
public fw_Knife_PrimaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid(iOwner))
		return
	
	if (!g_iTraceLine)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
}

/* Stab - 32.0 */
public fw_Knife_SecondaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid(iOwner))
		return
	
	if (!g_iTraceLine)
	{
		add_bitsum(bs_InKnifeSecAtk, iOwner)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
	}
}

public fw_TraceLine_Post(Float:vStart[3], Float:vEnd[3], iNoMonsters, id, iTrace)
{
	static Float:flFraction
	get_tr2(iTrace, TR_flFraction, flFraction)
	
	if (flFraction >= 1.0)
		goto Label_Unregister
	
	static pHit
	pHit = get_tr2(iTrace, TR_pHit)
	
	if (!is_user_valid_alive(pHit) || !is_same_team(id, pHit))
		goto Label_Unregister
	
	static Float:flLine[3], Float:flStart[3]
	velocity_by_aim(id, 32, flLine) /* 22.62742 - 42.520584 */
	UTIL_Vector_Add(flLine, vStart, flStart)
	velocity_by_aim(id, get_bitsum(bs_InKnifeSecAtk, id) ? 48 : 64, flLine)
	UTIL_Vector_Add(flLine, vStart, vEnd)
	
	engfunc(EngFunc_TraceLine, flStart, vEnd, iNoMonsters|DONT_IGNORE_MONSTERS, pHit, 0)
	
	pHit = get_tr2(0, TR_pHit)
	
	if (!is_user_valid_alive(pHit) || is_same_team(id, pHit))
		goto Label_Unregister
	
	static Float:flBuffer[3]
	set_tr2(iTrace, TR_AllSolid, get_tr2(0, TR_AllSolid))
	set_tr2(iTrace, TR_StartSolid, get_tr2(0, TR_StartSolid))
	set_tr2(iTrace, TR_InOpen, get_tr2(0, TR_InOpen))
	set_tr2(iTrace, TR_InWater, get_tr2(0, TR_InWater))
	get_tr2(0, TR_flFraction, flFraction); set_tr2(iTrace, TR_flFraction, flFraction)
	get_tr2(0, TR_vecEndPos, flBuffer); set_tr2(iTrace, TR_vecEndPos, flBuffer)
	get_tr2(0, TR_flPlaneDist, flFraction); set_tr2(iTrace, TR_flPlaneDist, flFraction)
	get_tr2(0, TR_vecPlaneNormal, flBuffer); set_tr2(iTrace, TR_vecPlaneNormal, flBuffer)
	set_tr2(iTrace, TR_pHit, pHit)
	set_tr2(iTrace, TR_iHitgroup, get_tr2(0, TR_iHitgroup))
	
	Label_Unregister:
	unregister_forward(FM_TraceLine, g_iTraceLine, true)
	g_iTraceLine = 0
	del_bitsum(bs_InKnifeSecAtk, id)
}

public fw_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	#if defined HOSTAGE_SEMICLIP
	if (!c_iSemiclip)
		return
	
	if (c_iHostage && g_iHostageCount && is_user_valid(host) && get_bitsum_array(bs_IsHostage, ent))
	{
		if (get_bitsum_array(bs_HostageIsRescued, ent) || (c_iHostage != 3 && c_iHostage != g_iSpectatingTeam[host]))
			return
		
		static iEnt
		iEnt = pev(ent, pev_hostage_index)
		
		if (g_iHostageRange[g_iSpectating[host]][iEnt] == OUT_OF_RANGE)
			return
		
		set_es(es_handle, ES_Solid, SOLID_NOT)
		
		switch (c_iRender)
		{
			case 1: /* Normal */
			{
				set_es(es_handle, ES_RenderMode, c_iNormalMode)
				set_es(es_handle, ES_RenderFx, c_iNormalFx)
				set_es(es_handle, ES_RenderAmt, g_iHostageRange[g_iSpectating[host]][iEnt])
				set_es(es_handle, ES_RenderColor, c_iColors[COLOR_HOSTAGE])
			}
			case 2: /* Fade */
			{
				set_es(es_handle, ES_RenderMode, c_iFadeMode)
				set_es(es_handle, ES_RenderFx, c_iFadeFx)
				set_es(es_handle, ES_RenderAmt, g_iHostageRange[g_iSpectating[host]][iEnt])
				set_es(es_handle, ES_RenderColor, c_iColors[COLOR_HOSTAGE])
			}
		}
		return
	}
	
	if (!player)
		return
	#else // !HOSTAGE_SEMICLIP
	if (!c_iSemiclip || !player)
		return
	#endif // HOSTAGE_SEMICLIP
	
	if (g_iTeam[host] == _:CS_TEAM_SPECTATOR)
	{
		if (!c_iRender || get_bitsum(bs_IsBot, host) || !get_bitsum(bs_IsAlive, ent))
			return
		
		static iHost
		iHost = g_iSpectating[host]
		
		if (!get_bitsum(bs_IsAlive, iHost) || g_iRange[iHost][ent] == OUT_OF_RANGE || !AllowSemiclip(iHost, ent))
			return
		
		if ((c_iRender == 2 && !c_iFadeSpec && iHost == ent) || (c_iRender == 1 && !c_iNormalSpec && iHost == ent))
			return
		
		if (get_bitsum(bs_RenderSpecial, ent))
		{
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
		}
		else
		{
			if (c_iRender == 2) /* Fade */
			{
				set_es(es_handle, ES_RenderMode, c_iFadeMode)
				set_es(es_handle, ES_RenderFx, c_iFadeFx)
			}
			else /* Normal */
			{
				set_es(es_handle, ES_RenderMode, c_iNormalMode)
				set_es(es_handle, ES_RenderFx, c_iNormalFx)
			}
			
			set_es(es_handle, ES_RenderAmt, g_iRange[iHost][ent])
			switch (g_iTeam[ent])
			{
				case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_TER]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_TER])
				case 2: get_bitsum(bs_IsVip, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_VIP]) : get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_CT]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_CT])
			}
		}
		return
	}
	
	if (!get_bitsum(bs_IsAlive, host) || !get_bitsum(bs_IsAlive, ent) || g_iRange[host][ent] == OUT_OF_RANGE || !AllowSemiclip(host, ent))
		return
	
	set_es(es_handle, ES_Solid, SOLID_NOT)
	
	if (!c_iRender)
		return
	
	if (get_bitsum(bs_RenderSpecial, ent))
	{
		set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
		set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
		set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
		set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
	}
	else
	{
		if (c_iRender == 2) /* Fade */
		{
			set_es(es_handle, ES_RenderMode, c_iFadeMode)
			set_es(es_handle, ES_RenderFx, c_iFadeFx)
		}
		else /* Normal */
		{
			set_es(es_handle, ES_RenderMode, c_iNormalMode)
			set_es(es_handle, ES_RenderFx, c_iNormalFx)
		}
		
		set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
		switch (g_iTeam[ent])
		{
			case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_TER]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_TER])
			case 2: get_bitsum(bs_IsVip, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_VIP]) : get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_CT]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_CT])
		}
	}
}

public fw_CmdStart_Post(id, handle)
{
	if (!c_iSemiclip || !c_iButton || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || get_bitsum(bs_IsBot, id) || get_bitsum(bs_InAntiBoost, id))
		return
	
	if (get_uc(handle, UC_Buttons) & c_iButtonTrigger)
	{
		add_bitsum(bs_InButton, id)
	}
	else
	{
		if (get_bitsum(bs_InButton, id))
			add_bitsum(bs_WasInButton, id)
		
		del_bitsum(bs_InButton, id)
		
		if (c_iButtonAntiBoost && get_bitsum(bs_WasInButton, id))
			RangeCheck(id+TASK_RANGE)
	}
}

#if defined FIX_MOVING_ENTITIES
public fw_Blocked(iBlocked, iBlocker)
{
	/* This here is only when entity movement fix dosen't work,
	or when func_door_rotating blocked by player and moving
	away, and func_vehicle will do damage to blocker. */
	if (!c_iSemiclip || !is_user_valid(iBlocker))
		return FMRES_IGNORED
	
	return (get_bitsum_array(bs_IsDoorRotating, iBlocked) || get_bitsum_array(bs_IsVehicle, iBlocked)) ? FMRES_IGNORED : FMRES_SUPERCEDE
}
#else // !FIX_MOVING_ENTITIES
public fw_Blocked(iBlocked, iBlocker)
{
	/* This here is only when FIX_MOVING_ENTITIES is not defined, so entities stop movement but don't damages. */
	if (!c_iSemiclip || !is_user_valid(iBlocker))
		return FMRES_IGNORED
	
	return FMRES_SUPERCEDE
}
#endif // FIX_MOVING_ENTITIES

/* Register czero bots */
public fw_SetClientKeyValue(id, infobuffer[], key[], value[])
{
	if (value[0] == '1' && equal(key, "*bot"))
	{
		unregister_forward(FM_SetClientKeyValue, g_iHamCzBots, false)
		remove_task(TASK_CZBOTS)
		
		RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", true)
		RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled", false)
		RegisterHamFromEntity(Ham_Player_SemiclipStart, id, "fw_PlayerSemiclip_Start", true)
		RegisterHamFromEntity(Ham_Player_SemiclipEnd, id, "fw_PlayerSemiclip_End", false)
	}
}

#if defined FIX_MOVING_ENTITIES
/*================================================================================
 [Entity movement fix]
=================================================================================*/

public fw_EntityMoving_Start(ent)
{
	if (!c_iSemiclip)
		return
	
	if (!g_iEntityMovingEnd)
		g_iEntityMovingEnd = register_forward(FM_Entity_MovingEnd, "fw_EntityMoving_End", false)
	
	SharedEntityUnsolid(0, ent, false)
}

public fw_EntityRotate_Start(ent)
{
	if (!c_iSemiclip)
		return
	
	g_iEntityRotateEnd = register_forward(FM_Entity_RotateEnd, "fw_EntityRotate_End", false)
	
	g_iEntityRotate = ent
	SharedEntityUnsolid(0, ent, true)
}

public fw_EntityMoving_End()
{
	unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	g_iEntityMovingEnd = 0
	
	SharedEntitySolid(1, 0, false)
}

public fw_EntityRotate_End(ent)
{
	unregister_forward(FM_Entity_RotateEnd, g_iEntityRotateEnd, false)
	g_iEntityRotateEnd = 0
	
	SharedEntitySolid(1, g_iEntityRotate, true)
}

/*================================================================================
 [Unsolid and solid function]
=================================================================================*/

SharedEntityUnsolid(id, i, const bool:bRotate)
{
	static Float:flCenter[3], Float:flRadius, iEntity
	iEntity = i
	
	#if !defined FIX_DOOR_ROTATING_CENTER
	if (bRotate) pev(iEntity, pev_real_center, flCenter) /* constant */
	#else // FIX_DOOR_ROTATING_CENTER
	if (bRotate) GetRotateCenter(iEntity, flCenter) /* variable */
	#endif // !FIX_DOOR_ROTATING_CENTER
	else GetEntityCenter(iEntity, flCenter)
	
	pev(iEntity, pev_entity_radius, flRadius)
	
	while ((id = find_ent_in_sphere(id, flCenter, flRadius)) != 0)
	{
		if (!is_user_valid(id))
			break
		
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		for (i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!get_bitsum(bs_IsSolid, i) || g_iRange[id][i] == OUT_OF_RANGE || !AllowSemiclip(id, i))
				continue
			
			set_pev(i, pev_solid, SOLID_NOT)
			del_bitsum(bs_IsSolid, i)
			g_iRotateEntity[i] = iEntity
		}
	}
}

#if defined FIX_DOOR_ROTATING_CENTER
GetRotateCenter(const ent, Float:flCenter[3])
{
	static Float:flOrigin[3], Float:flMin[3], Float:flMax[3]
	pev(ent, pev_origin, flOrigin)
	pev(ent, pev_mins, flMin)
	pev(ent, pev_maxs, flMax)
	
	UTIL_Vector_Center(flOrigin, flMin, flMax, flCenter)
	
	/* Set real center (x, y) */
	flCenter[0] = flOrigin[0]
	flCenter[1] = flOrigin[1]
	
	return 1
}
#endif // FIX_DOOR_ROTATING_CENTER

GetEntityCenter(const ent, Float:flCenter[3]) <FixedHamCenter>
{
	/* Only fixed in Hamsandwich 1.4 and it's faster (1 vs 3+UTIL_Vector_Center) */
	ExecuteHam(Ham_Center, ent, flCenter)
	
	return 1
}
GetEntityCenter(const ent, Float:flCenter[3]) <>
{
	/* Hamsandwich 1.4 not installed */
	static Float:flOrigin[3], Float:flMin[3], Float:flMax[3]
	pev(ent, pev_origin, flOrigin)
	pev(ent, pev_mins, flMin)
	pev(ent, pev_maxs, flMax)
	
	UTIL_Vector_Center(flOrigin, flMin, flMax, flCenter)
	
	return 1
}

SharedEntitySolid(id, const ent, const bool:bRotate)
{
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (get_bitsum(bs_IsSolid, id) || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || (bRotate && ent != g_iRotateEntity[id]))
			continue
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, id)
		g_iRotateEntity[id] = 0
	}
}
#endif // FIX_MOVING_ENTITIES

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

CheckMods()
{
	new szModName[8]
	get_modname(szModName, charsmax(szModName))
	if (equal(szModName, "cstrike")) register_plugin("[CS] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	else if (equal(szModName, "czero")) register_plugin("[CZ] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	else
	{
		register_plugin("[??] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
		set_fail_state("Error: This plugin is for cstrike and czero only!")
	}
}

CheckAmxxVersion()
{
	new szBuffer[6]
	get_amxx_verstring(szBuffer, 5)
	
	while (replace(szBuffer, 5, ".", "")) {}
	
	if (str_to_num(szBuffer) < 182)
		set_fail_state("Error: AMX Mod X v1.8.2 or later required!")
}

CheckMaxEntities()
{
	new Float:flValue, iValue
	flValue = float(global_get(glb_maxEntities)) / 32
	iValue = floatround(flValue, floatround_ceil)
	
	if (iValue > MAX_ENT_ARRAY)
	{
		new szError[100]
		format(szError, charsmax(szError), "Error: MAX_ENT_ARRAY is to low! Increase it to: %d and re-compile sma!", iValue)
		set_fail_state(szError)
	}
}

CreateCvarEntityTask()
{
	g_iCvarEntity = create_entity("info_target")
	if (pev_valid(g_iCvarEntity))
	{
		register_think("TSC_CvarEntity", "CacheCvars")
		
		set_pev(g_iCvarEntity, pev_classname, "TSC_CvarEntity")
		set_pev(g_iCvarEntity, pev_nextthink, get_gametime() + 1.0)
	}
	else
	{
		set_task(1.0, "CacheCvars", TASK_CVARS)
		set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
	}
}

public StopCzBotForward()
{
	unregister_forward(FM_SetClientKeyValue, g_iHamCzBots, false)
	g_iHamCzBots = 0
}

public CacheCvars(entity)
{
	c_iSemiclip = !!get_pcvar_num(cvar_iSemiclip)
	c_iBlockTeam = clamp(get_pcvar_num(cvar_iSemiclipBlockTeam), 0, 3)
	c_iEnemies = !!get_pcvar_num(cvar_iSemiclipEnemies)
	c_flRadius = floatclamp(get_pcvar_float(cvar_flSemiclipRadius), 85.041168, 14123.149414)
	
	c_iButton = clamp(get_pcvar_num(cvar_iSemiclipButton), 0, 3)
	c_iButtonTrigger = clamp(get_pcvar_num(cvar_iSemiclipButtonTrigger), 1, 65535)
	c_iButtonAntiBoost = !!get_pcvar_num(cvar_iSemiclipButtonAntiBoost)
	
	c_iUnstuck = clamp(get_pcvar_num(cvar_iSemiclipUnstuck), 0, 3)
	c_flUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiclipUnstuckDelay), 0.0, 3.0)
	
	#if defined HOSTAGE_SEMICLIP
	c_iHostage = clamp(get_pcvar_num(cvar_iSemiclipHostage), 0, 3)
	#endif // HOSTAGE_SEMICLIP
	
	c_iKnifeTrace = !!get_pcvar_num(cvar_iSemiclipKnifeTrace)
	
	c_iRender = clamp(get_pcvar_num(cvar_iSemiclipRender), 0, 2)
	
	c_iNormalMode = clamp(get_pcvar_num(cvar_iSemiclipNormalMode), 0, 5)
	c_iNormalFx = clamp(get_pcvar_num(cvar_iSemiclipNormalFx), 0, 20)
	c_iNormalAmt = clamp(get_pcvar_num(cvar_iSemiclipNormalAmt), 0, 255)
	c_iNormalSpec = !!get_pcvar_num(cvar_iSemiclipNormalSpec)
	
	c_iFadeMode = clamp(get_pcvar_num(cvar_iSemiclipFadeMode), 0, 5)
	c_iFadeFx = clamp(get_pcvar_num(cvar_iSemiclipFadeFx), 0, 20)
	c_flFadeMin = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMin), 0.0, 255.0)
	c_flFadeMax = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMax), 0.0, 255.0)
	c_iFadeSpec = !!get_pcvar_num(cvar_iSemiclipFadeSpec)
	
	static index, szColors[12], szRed[4], szGreen[4], szBlue[4]
	for (index = COLOR_CT; index < MAX_COLORS; index++)
	{
		get_pcvar_string(cvar_szSemiclipColors[index], szColors, 11)
		parse(szColors, szRed, 3, szGreen, 3, szBlue, 3)
		c_iColors[index][0] = clamp(str_to_num(szRed), 0, 255)
		c_iColors[index][1] = clamp(str_to_num(szGreen), 0, 255)
		c_iColors[index][2] = clamp(str_to_num(szBlue), 0, 255)
	}
	
	static szFlags[24]
	get_pcvar_string(cvar_szSemiclipColorFlag, szFlags, charsmax(szFlags))	
	c_iColorFlag = read_flags(szFlags)
	
	for (index = 1; index <= g_iMaxPlayers; index++)
	{
		if (!get_bitsum(bs_IsConnected, index))
			continue
		
		/* amx_reloadadmins ? */
		if (get_user_flags(index) & c_iColorFlag) add_bitsum(bs_IsAdmin, index)
		else del_bitsum(bs_IsAdmin, index)
	}
	
	/* No CSDM spawns found */
	if (!g_iSpawnCountCSDM && c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		c_iUnstuck = 1
	}
	
	if (entity != TASK_CVARS)
	{
		if (!pev_valid(entity)) set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
		else set_pev(entity, pev_nextthink, get_gametime() + CVAR_INTERVAL)
	}
}

public LoadSpawns()
{
	/* Check if Zombie Plague is running */
	if (LibraryExists("zp50_core", LibType_Library))
	{
		Label_FailState:
		plugin_pause()
		set_fail_state("Error: This plugin is not for Zombie Plague Mod")
	}
	else if (get_cvar_pointer("zp_on")) /* Cvar is registered! */
	{
		/* Check if ZP is really running! */
		g_bZpReallyRunning = true
		zp_has_round_started()
		
		if (g_bZpReallyRunning)
			goto Label_FailState
	}
	
	/* Zombie Plague is not running */
	new szConfigDir[32], szMapName[32], szFilePath[100], szLineData[64]
	
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	get_mapname(szMapName, charsmax(szMapName))
	formatex(szFilePath, charsmax(szFilePath), "%s/csdm/%s.spawns.cfg", szConfigDir, szMapName)
	
	if (file_exists(szFilePath))
	{
		new iFile
		if ((iFile = fopen(szFilePath, "rt")) != 0)
		{
			new szDataCSDM[10][6]
			while (!feof(iFile))
			{
				fgets(iFile, szLineData, charsmax(szLineData))
				
				if (!szLineData[0] || str_count(szLineData,' ') < 2)
					continue
				
				parse(szLineData, szDataCSDM[0], 5, szDataCSDM[1], 5, szDataCSDM[2], 5, szDataCSDM[3], 5, szDataCSDM[4], 5, szDataCSDM[5], 5, szDataCSDM[6], 5, szDataCSDM[7], 5, szDataCSDM[8], 5, szDataCSDM[9], 5)
				
				g_flSpawnsCSDM[g_iSpawnCountCSDM][0] = floatstr(szDataCSDM[0])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][1] = floatstr(szDataCSDM[1])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][2] = floatstr(szDataCSDM[2])
				
				if (++g_iSpawnCountCSDM >= MAX_CSDM_SPAWNS)
					break
			}
			fclose(iFile)
			
			goto Label_Collect
		}
	}
	
	if (c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		c_iUnstuck = 1
	}
	
	Label_Collect:
	/* CT */
	new iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, CT_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsCTs[g_iSpawnCountCTs][0] = flOrigin[0]
		g_flSpawnsCTs[g_iSpawnCountCTs][1] = flOrigin[1]
		g_flSpawnsCTs[g_iSpawnCountCTs][2] = flOrigin[2]
		
		if (++g_iSpawnCountCTs >= sizeof g_flSpawnsCTs)
			break
	}
	
	/* TERROR */
	iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, TER_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsTer[g_iSpawnCountTer][0] = flOrigin[0]
		g_flSpawnsTer[g_iSpawnCountTer][1] = flOrigin[1]
		g_flSpawnsTer[g_iSpawnCountTer][2] = flOrigin[2]
		
		if (++g_iSpawnCountTer >= sizeof g_flSpawnsTer)
			break
	}
}

public RandomSpawnDelay(id)
{
	DoRandomSpawn(id)
}

/* credits to MeRcyLeZZ */
DoRandomSpawn(const id)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	static iHull, iSpawnPoint, i
	iHull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	switch (c_iUnstuck)
	{
		case 1: /* Specified team */
		{
			switch (g_iTeam[id])
			{
				case 1: /* TERRORIST */
				{
					if (!g_iSpawnCountTer)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountTer - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountTer)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsTer[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsTer[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
				case 2: /* CT */
				{
					if (!g_iSpawnCountCTs)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountCTs - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountCTs)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsCTs[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsCTs[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
			}
		}
		case 2: /* CSDM */
		{
			if (!g_iSpawnCountCSDM)
				return
			
			iSpawnPoint = random_num(0, g_iSpawnCountCSDM - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= g_iSpawnCountCSDM)
					i = 0
				
				if (is_hull_vacant(g_flSpawnsCSDM[i], iHull))
				{
					engfunc(EngFunc_SetOrigin, id, g_flSpawnsCSDM[i])
					break
				}
				
				if (i == iSpawnPoint)
					break
			}
		}
		case 3: /* Random around own place */
		{
			new Float:flOrigin[3], Float:flOriginZ, Float:flOriginFinal[3], iSize
			pev(id, pev_origin, flOrigin)
			iSize = sizeof(RANDOM_OWN_PLACE)
			
			iSpawnPoint = random_num(0, iSize - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= iSize)
					i = 0
				
				flOriginFinal[0] = flOrigin[0] + RANDOM_OWN_PLACE[i][0]
				flOriginFinal[1] = flOrigin[1] + RANDOM_OWN_PLACE[i][1]
				flOriginFinal[2] = flOriginZ = flOrigin[2] + RANDOM_OWN_PLACE[i][2] - 35.0
				
				new iZ = 0
				do
				{
					if (is_hull_vacant(flOriginFinal, iHull))
					{
						i = iSpawnPoint
						engfunc(EngFunc_SetOrigin, id, flOriginFinal)
						break
					}
					
					flOriginFinal[2] = flOriginZ + (++iZ * 40.0)
				}
				while (iZ < 3)
				
				if (i == iSpawnPoint)
					break
			}
		}
	}
}

public RangeCheck(const taskid)
{
	if (!c_iSemiclip)
		return
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id))
			continue
		
		g_iRange[ID_RANGE][id] = CalculateAmount(ID_RANGE, id)
		
		if (!c_iButtonAntiBoost || ID_RANGE == id)
			continue
		
		/* Anti boosting */
		switch (c_iButton)
		{
			case 3: /* BOTH */
			{
				if (!get_bitsum(bs_InAntiBoost, ID_RANGE) && (get_bitsum(bs_InButton, ID_RANGE) || get_bitsum(bs_WasInButton, ID_RANGE)) && entity_range(ID_RANGE, id) <= ANTI_BOOST_DISTANCE)
				{
					if (!c_iEnemies && !is_same_team(id, ID_RANGE))
						continue
					
					SetBoosting(ID_RANGE, id, true)
				}
				else if (get_bitsum(bs_InAntiBoost, ID_RANGE) && g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
				{
					SetBoosting(ID_RANGE, id, false)
				}
			}
			case 1, 2: /* CT or TERROR */
			{
				if (!get_bitsum(bs_InAntiBoost, ID_RANGE) && (get_bitsum(bs_InButton, ID_RANGE) || get_bitsum(bs_WasInButton, ID_RANGE)) && c_iButton == g_iTeam[ID_RANGE] && c_iButton == g_iTeam[id] && entity_range(ID_RANGE, id) <= ANTI_BOOST_DISTANCE)
				{
					if (c_iEnemies && !is_same_team(id, ID_RANGE))
						continue
					
					SetBoosting(ID_RANGE, id, true)
				}
				else if (get_bitsum(bs_InAntiBoost, ID_RANGE) && g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
				{
					SetBoosting(ID_RANGE, id, false)
				}
			}
			default: continue
		}
	}
	del_bitsum(bs_WasInButton, ID_RANGE)
	
	#if defined HOSTAGE_SEMICLIP
	if (c_iHostage && g_iHostageCount)
	{
		static iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos))
				continue
			
			g_iHostageRange[ID_RANGE][id] = CalculateAmount(ID_RANGE, iHos)
		}
	}
	#endif // HOSTAGE_SEMICLIP
}

SetBoosting(const iBooster, const iOther, const bool:Set)
{
	if (Set)
	{
		add_bitsum(bs_InAntiBoost, iBooster)
		add_bitsum(bs_InButton, iBooster)
		g_iAntiBoost[iBooster][iOther] = 1
		
		add_bitsum(bs_InAntiBoost, iOther)
		add_bitsum(bs_InButton, iOther)
		g_iAntiBoost[iOther][iBooster] = 1
	}
	else
	{
		del_bitsum(bs_InAntiBoost, iBooster)
		g_iAntiBoost[iBooster][iOther] = 0
	}
}

#if defined FIX_MOVING_ENTITIES
SetEntityRadius(const szClassName[], const iType)
{
	static iEnt
	iEnt = -1
	
	while ((iEnt = find_ent_by_class(iEnt, szClassName)) != 0)
	{
		switch (iType)
		{
			case RADIUS_ABS:
			{
				static Float:flAbsMin[3], Float:flAbsMax[3]
				pev(iEnt, pev_absmin, flAbsMin)
				pev(iEnt, pev_absmax, flAbsMax)
				
				/* Set sphere radius */
				set_pev(iEnt, pev_entity_radius, get_distance_f(flAbsMin, flAbsMax) * 0.5 + 1.0)
			}
			case RADIUS_ROTATE:
			{
				/* Disable door damage */
				if (equal(szClassName, "func_door_rotating"))
				{
					add_bitsum_array(bs_IsDoorRotating, iEnt)
					
					set_kvd(0, KV_ClassName, szClassName)
					set_kvd(0, KV_KeyName, "dmg")
					set_kvd(0, KV_Value, "0")
					set_kvd(0, KV_fHandled, 0)
					
					dllfunc(DLLFunc_KeyValue, iEnt, 0)
				}
				
				#if !defined FIX_DOOR_ROTATING_CENTER
				static Float:flMins[3], Float:flMaxs[3]
				pev(iEnt, pev_mins, flMins)
				pev(iEnt, pev_maxs, flMaxs)
				
				static Float:flOrigin[3], Float:flCenter[3]
				pev(iEnt, pev_origin, flOrigin)
				UTIL_Vector_Center(flOrigin, flMins, flMaxs, flCenter)
				
				/* Set real center (constant origin) */
				flOrigin[2] = flCenter[2]
				set_pev(iEnt, pev_real_center, flOrigin)
				#endif // !FIX_DOOR_ROTATING_CENTER
				
				/* Need a delay */
				dllfunc(DLLFunc_Use, iEnt, 0)
				set_task(0.1, "SetEntityRotateRadius", iEnt)
			}
			case RADIUS_VEHICLE:
			{
				add_bitsum_array(bs_IsVehicle, iEnt)
				
				static Float:flAbsMin[3], Float:flAbsMax[3]
				pev(iEnt, pev_absmin, flAbsMin)
				pev(iEnt, pev_absmax, flAbsMax)
				
				/* Set sphere radius */
				set_pev(iEnt, pev_entity_radius, get_distance_f(flAbsMin, flAbsMax) * 0.5 + 1.0)
				
				/* Need a delay */
				set_pev(iEnt, pev_velocity, { 0.0, 0.0, 1.0 })
				set_task(0.1, "SetEntityVehicleRadius", iEnt)
			}
		}
	}
}

public SetEntityRotateRadius(entity)
{
	static Float:flAbsMin[3], Float:flAbsMax[3]
	pev(entity, pev_absmin, flAbsMin)
	pev(entity, pev_absmax, flAbsMax)
	
	/* Set sphere radius */
	set_pev(entity, pev_entity_radius, get_distance_f(flAbsMin, flAbsMax) * 0.5 + 1.0)
}

public SetEntityVehicleRadius(entity)
{
	static Float:flAbsMin[3], Float:flAbsMax[3]
	pev(entity, pev_absmin, flAbsMin)
	pev(entity, pev_absmax, flAbsMax)
	
	static Float:flOldRadius, Float:flNewRadius, Float:flRadius
	pev(entity, pev_entity_radius, flOldRadius)
	flRadius = get_distance_f(flAbsMin, flAbsMax)
	flNewRadius = flRadius * 0.5 + 1.0
	
	/* Set sphere radius */
	if (flNewRadius > flOldRadius) set_pev(entity, pev_entity_radius, flNewRadius) /* func_vehicle with func_vehiclecontrols */
	else set_pev(entity, pev_entity_radius, flRadius) /* func_vehicle without func_vehiclecontrols */
}
#endif // FIX_MOVING_ENTITIES

public SpectatorCheck(const taskid)
{
	if (!c_iSemiclip || get_bitsum(bs_IsAlive, ID_SPECTATOR) || get_bitsum(bs_IsDying, ID_SPECTATOR))
		return
	
	static iTarget
	iTarget = pev(ID_SPECTATOR, pev_spec_target)
	
	if (!is_user_valid(iTarget)) goto Label_FreeLook
	else
	{
		Label_SetTarget:
		g_iSpectating[ID_SPECTATOR] = iTarget
		g_iSpectatingTeam[ID_SPECTATOR] = g_iTeam[iTarget]
		return
	}
	
	Label_FreeLook:
	if (pev(ID_SPECTATOR, pev_spec_mode) != 3)
		return
	
	iTarget = fm_cs_get_free_look_target(ID_SPECTATOR)
	
	if (is_user_valid(iTarget))
		goto Label_SetTarget
}

CalculateAmount(const host, const ent)
{
	/* The same */
	if (host == ent)
		return OUT_OF_RANGE
	
	/* Fade */
	if (c_iRender == 2)
	{
		static Float:flRange
		flRange = entity_range(host, ent)
		
		if (flRange > c_flRadius)
			return OUT_OF_RANGE
		
		static Float:flAmount
		flAmount = flRange / (c_flRadius / (c_flFadeMax - c_flFadeMin))
		
		return floatround((flAmount >= 0.0) ? flAmount + c_flFadeMin : floatabs(flAmount - c_flFadeMax))
	}
	
	return (entity_range(host, ent) <= c_flRadius) ? c_iNormalAmt : OUT_OF_RANGE
}

AllowSemiclip(const host, const ent)
{
	if (g_bPreparation)
		return 1
	
	switch (c_iButton)
	{
		case 3: /* BOTH */
		{
			if (get_bitsum(bs_InButton, host))
			{
				if (!c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		case 1, 2: /* CT or TERROR */
		{
			if (get_bitsum(bs_InButton, host) && c_iButton == g_iTeam[host] && c_iButton == g_iTeam[ent])
			{
				if (c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		default:
		{
			if (QueryEnemies(host, ent))
				return 0
		}
	}
	return 1
}

QueryEnemies(const host, const ent)
{
	if (c_iBlockTeam == 3)
		return 1
	
	switch (c_iEnemies)
	{
		case 1: if (c_iBlockTeam == g_iTeam[ent] && is_same_team(ent, host)) return 1
		case 0: if (!is_same_team(ent, host) || c_iBlockTeam == g_iTeam[ent]) return 1
	}
	
	return 0
}

public DisableTask(const taskid)
{
	if (taskid != TASK_DURATION)
	{
		g_bPreparation = false
		
		new id, bs_IsStucking, iCts, iTerrorists, iTeam, iEnemy
		for (id = 1; id <= g_iMaxPlayers; id++)
		{
			if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || !is_player_stuck(id))
				continue
			
			add_bitsum(bs_IsStucking, id)
			
			switch (g_iTeam[id])
			{
				case 1: iTerrorists++
				case 2: iCts++
			}
		}
		
		if (iCts == iTerrorists) iTeam = random_num(1, 2)
		else if (iTerrorists > iCts) iTeam = 1
		else iTeam = 2
		
		for (id = 1; id <= g_iMaxPlayers; id++)
		{
			if (!get_bitsum(bs_IsStucking, id))
				continue
			
			if (g_iTeam[id] == iTeam)
			{
				if (!get_bitsum(bs_InButton, id) && (c_iButton == iTeam || c_iButton == 3))
					DoRandomSpawn(id)
				
				continue
			}
			
			if (c_iButton)
			{
				if (!c_iEnemies || (iEnemy && !get_bitsum(bs_InButton, id)))
				{
					DoRandomSpawn(id)
					continue
				}
				else if (iEnemy && !get_bitsum(bs_InButton, iEnemy))
					DoRandomSpawn(iEnemy)
				
				iEnemy = id
				continue
			}
			
			if (!c_iEnemies)
				DoRandomSpawn(id)
		}
		return
	}
	
	/* Duration has higher priority as Preparation */
	remove_task(TASK_PREPARATION)
	g_bPreparation = false
	
	set_pcvar_num(cvar_iSemiclip, 0)
	c_iSemiclip = 0
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (is_player_stuck(id))
			DoRandomSpawn(id)
	}
}

TeamInfoUnstuck(const id)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || !is_player_stuck(id))
		return 0
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || g_iRange[id][i] == OUT_OF_RANGE || !is_player_stuck(i))
			continue
		
		if (c_iButton)
		{
			if (c_iEnemies)
			{
				if (!get_bitsum(bs_InButton, id) && c_iButton == g_iTeam[i])
					return 1
				
				return 0
			}
			
			return !is_same_team(id, i)
		}
		
		return QueryEnemies(id, i)
	}
	
	return 0 /* only for compiler */
}

SetUserCvars(const id)
{
	del_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	del_bitsum(bs_IsBot, id)
	del_bitsum(bs_IsVip, id)
	del_bitsum(bs_IsSolid, id)
	del_bitsum(bs_RenderSpecial, id)
	del_bitsum(bs_InKnifeSecAtk, id)
	g_iTeam[id] = _:CS_TEAM_UNASSIGNED
	
	arrayset(g_iAntiBoost[id], 0, MAX_PLAYERS+1)
	arrayset(g_iRange[id], OUT_OF_RANGE, MAX_PLAYERS+1)
	#if defined HOSTAGE_SEMICLIP
	arrayset(g_iHostageRange[id], OUT_OF_RANGE, MAX_HOSTAGE)
	#endif // HOSTAGE_SEMICLIP
	#if defined FIX_MOVING_ENTITIES
	g_iRotateEntity[id] = 0
	#endif // FIX_MOVING_ENTITIES
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

public MessageTeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id, szTeam[2]
	id = get_msg_arg_int(1)
	get_msg_arg_string(2, szTeam, charsmax(szTeam))
	
	switch (szTeam[0])
	{
		case 'T': g_iTeam[id] = _:CS_TEAM_T
		case 'C': g_iTeam[id] = _:CS_TEAM_CT
		case 'S':
		{
			if (get_bitsum(bs_IsDying, id))
			{
				del_bitsum(bs_IsAlive, id)
				del_bitsum(bs_IsDying, id)
				
				g_iSpectatingTeam[id] = g_iTeam[id]
				
				if (!get_bitsum(bs_IsBot, id))
					set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
			}
			else
			{
				#if defined HOSTAGE_SEMICLIP
				g_iSpectatingTeam[id] = c_iHostage
				#else // !HOSTAGE_SEMICLIP
				g_iSpectatingTeam[id] = g_iTeam[id]
				#endif // HOSTAGE_SEMICLIP
			}
			
			g_iSpectating[id] = id
			g_iTeam[id] = _:CS_TEAM_SPECTATOR
			return
		}
		default:
		{
			g_iTeam[id] = _:CS_TEAM_UNASSIGNED
			return
		}
	}
	
	g_iSpectating[id] = id
	g_iSpectatingTeam[id] = g_iTeam[id]
	
	if (TeamInfoUnstuck(id))
	{
		if (c_flUnstuckDelay > 0.0) set_task(c_flUnstuckDelay, "RandomSpawnDelay", id)
		else DoRandomSpawn(id)
	}
}

public MessageClCorpse(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id
	id = get_msg_arg_int(12)
	
	if (get_bitsum(bs_IsDying, id))
	{
		del_bitsum(bs_IsAlive, id)
		del_bitsum(bs_IsDying, id)
		g_iTeam[id] = _:CS_TEAM_SPECTATOR
		
		if (!get_bitsum(bs_IsBot, id))
			set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

/* tsc_get_user_rendering(id) */
public fn_get_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_RenderSpecial, id) ? 1 : 0
}

/* tsc_set_user_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) */
public fn_set_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	switch (get_param(2))
	{
		case 0:
		{
			del_bitsum(bs_RenderSpecial, id)
			
			return 1
		}
		case 1:
		{
			add_bitsum(bs_RenderSpecial, id)
			
			g_iRenderSpecial[id][SPECIAL_FX] = clamp(get_param(3), 0, 20)
			
			g_iRenderSpecialColor[id][0] = clamp(get_param(4), 0, 255)
			g_iRenderSpecialColor[id][1] = clamp(get_param(5), 0, 255)
			g_iRenderSpecialColor[id][2] = clamp(get_param(6), 0, 255)
			
			g_iRenderSpecial[id][SPECIAL_MODE] = clamp(get_param(7), 0, 5)
			g_iRenderSpecial[id][SPECIAL_AMT] = clamp(get_param(8), 0, 255)
			
			return 1
		}
	}
	
	return 0
}

/* tsc_get_user_semiclip(id) */
public fn_get_user_semiclip(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_IsSolid, id) ? 0 : 1
}

/* tsc_get_user_anti_boost(id, other = 0) */
public fn_get_user_anti_boost(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	new other = get_param(2)
	
	if (other == 0) return get_bitsum(bs_InAntiBoost, id) ? 1 : 0
	else if (!is_user_valid_connected(other))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Other player is not in game (%d)", other)
		return -1
	}
	
	return g_iAntiBoost[id][other]
}

/*================================================================================
 [Stocks]
=================================================================================*/

/* credits to VEN */
stock is_player_stuck(const id)
{
	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	engfunc(EngFunc_TraceHull, origin, origin, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

/* credits to VEN */
stock is_hull_vacant(const Float:origin[3], const hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

/* Stock by (probably) Twilight Suzuka -counts number of chars in a string */
stock str_count(const str[], const searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if (str[i] == searchchar)
			count++
	}
	
	return count
}

/* credits to MeRcyLeZZ */
stock ham_cs_get_weapon_ent_owner(const ent)
{
	return (pev_valid(ent) == pdata_safe) ? get_pdata_cbase(ent, m_pPlayer, linux_weapons_diff, mac_weapons_diff) : 0
}

/* credits to me */
stock fm_cs_get_free_look_target(const id)
{
	return (pev_valid(id) == pdata_safe) ? get_pdata_int(id, m_hObserverTarget, linux_diff, mac_diff) : 0
}

/* amxmisc.inc */
stock get_configsdir(name[], const len)
{
	return get_localinfo("amxx_configsdir", name, len)
}
