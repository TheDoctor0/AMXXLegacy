#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define PLUGIN "[ZP] Extra: Scar"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7 and Temaker"

#pragma semicolon 1
#pragma ctrlchar '\'

//**********************************************
//* Weapon Settings.                           *
//**********************************************

// Main
#define WEAPON_REFERANCE		"weapon_aug"

#define WEAPON_NAME_C 			"weapon_scar_xx"
#define WEAPON_NAME_S			"weapon_scar_ex_xx"

#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		90

#define WEAPON_MAX_SPEED		230.0

#define WEAPON_MULTIPLIER_DAMAGE 	1.1

#define WEAPON_TIME_NEXT_IDLE 		5.46
#define WEAPON_TIME_NEXT_ATTACK_C 	0.0955
#define WEAPON_TIME_NEXT_ATTACK_S 	0.25

#define WEAPON_TIME_DELAY_DEPLOY 	1.0
#define WEAPON_TIME_DELAY_RELOAD 	3.47
#define WEAPON_TIME_DELAY_SWITCH	5.60

// Extra
#define ZP_ITEM_NAME			"Scar" 
#define ZP_ITEM_COST			40

// Models
#define MODEL_WORLD		"models/xx/w_scar.mdl"
#define MODEL_VIEW		"models/xx/v_scar.mdl"
#define MODEL_PLAYER	"models/xx/p_scar.mdl"
#define MODEL_SHELL		"models/xx/shell762.mdl"

// Sounds
#define SOUND_FIRE_C		"weapons/scar-1.wav"
#define SOUND_FIRE_S		"weapons/scar-2.wav"
#define SOUND_D		        "weapons/scar_change1.wav"
#define SOUND_S		        "weapons/scar_change2.wav"
#define SOUND_A		        "weapons/scar_change3.wav"
#define SOUND_F		        "weapons/scar_clipin.wav"
#define SOUND_G		        "weapons/scar_clipout.wav"
#define SOUND_H		        "weapons/scar_draw.wav"

// Sprites
#define WEAPON_HUD_SPR_C	"sprites/scar/scar.spr"

#define WEAPON_HUD_TXT_C	"sprites/weapon_scar_xx.txt"
#define WEAPON_HUD_TXT_S	"sprites/weapon_scar_ex_xx.txt"

// Animation
#define ANIM_EXTENSION		"carbine"

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_CHANGE,
	
	ANIM_IDLE_EX,
	ANIM_RELOAD_EX,
	ANIM_DRAW_EX,
	ANIM_SHOOT_1_EX,
	ANIM_SHOOT_2_EX,
	ANIM_CHANGE_EX
};

//**********************************************
//* Some macroses.                             *
//**********************************************

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)	engfunc(EngFunc_PrecacheGeneric, %0)

#define PRECACHE_MODEL2(%0)		PrecacheSoundsFromModel(%0)

//**********************************************
//* PvData Offsets.                            *
//**********************************************

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox	34

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42
#define m_iId				43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_fInSpecialReload		55
#define m_iDirection			60
#define m_flLastFire			63
#define m_iShotsFired			64

// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_iHideHUD			361
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

// Redefines
#define m_flApplyMode			m_flLastFire
#define m_iCurrentMode			m_fInSpecialReload

//**********************************************
//* Let's code our weapon.                     *
//**********************************************

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL2(MODEL_VIEW);
	
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_FIRE_C);
	PRECACHE_SOUND(SOUND_FIRE_S);
	PRECACHE_SOUND(SOUND_D);
	
	PRECACHE_SOUND(SOUND_S);
	PRECACHE_SOUND(SOUND_A);
	PRECACHE_SOUND(SOUND_F);
	PRECACHE_SOUND(SOUND_G);
	PRECACHE_SOUND(SOUND_H);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR_C);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT_C);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_S);
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iCurrentMode)
{
	#pragma unused iClip, iAmmoPrimary
	
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}
	
	Weapon_AdjustCrosshair(iPlayer, iCurrentMode);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	Weapon_SendAnim(iPlayer, iCurrentMode ? ANIM_DRAW_EX : ANIM_DRAW);
}

Weapon_OnHolster(iItem, const iPlayer, const iClip, const iAmmoPrimary, const iCurrentMode)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary, iCurrentMode
	
	// Cancel any reload in progress.
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	
	// Cancel mode change.
	set_pdata_float(iItem , m_flApplyMode, 0.0, extra_offset_weapon);
	
	// Restore croshair.
	Weapon_AdjustCrosshair(iPlayer, 0);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iCurrentMode)
{
	#pragma unused iClip, iAmmoPrimary
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	// Time to idle.
	if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	// Adjust crosshair.
	Weapon_AdjustCrosshair(iPlayer, iCurrentMode);
	
	// Send animation.
	Weapon_SendAnim(iPlayer, iCurrentMode ? ANIM_IDLE_EX : ANIM_IDLE);
		
	// Time to next idle.
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iCurrentMode)
{
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}

	if (get_pdata_int(iPlayer, m_iFOV, extra_offset_player) != 90)
	{
		Weapon_OnSecondaryAttack(iItem, iClip, iAmmoPrimary);
	}
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, iCurrentMode ? ANIM_RELOAD_EX : ANIM_RELOAD);
}

Weapon_OnModeSwitch(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iNewMode)
{
	#pragma unused iClip, iAmmoPrimary
	
	// Wait for next attack time.
	if (get_pdata_float(iPlayer, m_flNextAttack, extra_offset_player) > 0.0)
	{
		return;
	}

	// Already switching, ignore.
	if (get_pdata_float(iItem , m_flApplyMode, extra_offset_weapon))
	{
		return;
	}
	
	// Mode is the same, ignore.
	if (get_pdata_int(iItem , m_iCurrentMode, extra_offset_weapon) == iNewMode)
	{
		return;
	}
	

	
	// Change crosshair status.
	Weapon_AdjustCrosshair(iPlayer, iNewMode);
	
	// Play animation.
	Weapon_SendAnim(iPlayer, iNewMode ? ANIM_CHANGE : ANIM_CHANGE_EX);
	
	// Set delays
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_SWITCH, extra_offset_weapon);
	set_pdata_float(iItem, m_flApplyMode, WEAPON_TIME_DELAY_SWITCH + get_gametime() - 0.5, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_SWITCH, extra_offset_player);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iCurrentMode)
{
	#pragma unused iAmmoPrimary
	
	CallOrigFireBullets3(iItem, iPlayer);
	
	if (iClip <= 0)
	{
		return;
	}
	
	static iFlags, iShellModelIndex, Float: vecVelocity[3];
	
	iFlags = pev(iPlayer, pev_flags);
	pev(iPlayer, pev_velocity, vecVelocity);
	
	if (iShellModelIndex || (iShellModelIndex = PRECACHE_MODEL(MODEL_SHELL)))
	{
		EjectBrass(iPlayer, iShellModelIndex, 1, .flForwardScale = 9.0);
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);

	if (iCurrentMode)
	{
		Weapon_SendAnim(iPlayer, random_num(ANIM_SHOOT_1_EX, ANIM_SHOOT_2_EX));
		
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK_S, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK_S, extra_offset_weapon);
		
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE_S, 0.9, ATTN_NORM, 0, PITCH_NORM);
		
		if (xs_vec_len(vecVelocity) > 0)
		{
			Weapon_KickBack(iItem, iPlayer, 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7);
		}
		else if (!(iFlags & FL_ONGROUND))
		{
			Weapon_KickBack(iItem, iPlayer, 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5);
		}
		else if (iFlags & FL_DUCKING)
		{
			Weapon_KickBack(iItem, iPlayer, 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9);
		}
		else
		{
			Weapon_KickBack(iItem, iPlayer, 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8);
		}
	}
	else
	{
		Weapon_SendAnim(iPlayer, random_num(ANIM_SHOOT_1, ANIM_SHOOT_2));
		
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK_C, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK_C, extra_offset_weapon);
		
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE_C, 0.9, ATTN_NORM, 0, PITCH_NORM);
		
		if (xs_vec_len(vecVelocity) > 0)
		{
			Weapon_KickBack(iItem, iPlayer, 1.0, 0.45, 0.28, 0.045, 3.75, 3.0, 7);
		}
		else if (!(iFlags & FL_ONGROUND))
		{
			Weapon_KickBack(iItem, iPlayer, 1.2, 0.5, 0.23, 0.15, 5.5, 3.5, 6);
		}
		else if (iFlags & FL_DUCKING)
		{
			Weapon_KickBack(iItem, iPlayer, 0.6, 0.3, 0.2, 0.0125, 3.25, 2.0, 7);
		}
		else
		{
			Weapon_KickBack(iItem, iPlayer, 0.65, 0.35, 0.25, 0.015, 3.5, 2.25, 7);
		}
	}
}

Weapon_OnSecondaryAttack(const iItem, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.3, extra_offset_weapon);
}

Weapon_AdjustCrosshair(const iPlayer, const iCurrentMode)
{
	#define HIDEHUD_CROSSHAIR ( 1 << 6 )
	
	if (iCurrentMode)
	{
		set_pdata_int(iPlayer, m_iHideHUD, get_pdata_int(iPlayer, m_iHideHUD, extra_offset_player) | HIDEHUD_CROSSHAIR, extra_offset_player);
	}
	else
	{
		set_pdata_int(iPlayer, m_iHideHUD, get_pdata_int(iPlayer, m_iHideHUD, extra_offset_player) & ~HIDEHUD_CROSSHAIR, extra_offset_player);
	}
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define CSW_DUMMY			2
#define MSG_WEAPONLIST			78

#define _CALLFUNC(%0,%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1)),		\
		get_pdata_int(%1, m_iCurrentMode, extra_offset_weapon)	\
	) 

#define STATEMENT_FALLBACK(%0,%1,%2)	public %0()<>{return %1;} public %0()<%2>{return %1;}

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)

//**********************************************
//* Motor!.                                    *
//**********************************************

new g_iszWeaponKey;
new g_iForwardDecalIndex;

#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == g_iszWeaponKey)

public plugin_precache()
{
	Weapon_OnPrecache();
	
	g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME_C);
	g_iForwardDecalIndex = register_forward(FM_DecalIndex, "FakeMeta_DecalIndex_Post", true);
	
	register_clcmd(WEAPON_NAME_C, "Cmd_WeaponSelect");
	register_clcmd(WEAPON_NAME_S, "Cmd_WeaponSelectEx");
	
	register_message(MSG_WEAPONLIST, /*get_user_msgid("WeaponList"),*/ "MsgHook_WeaponList");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn, 		"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,	"func_breakable",	"HamHook_Entity_TraceAttack", false);
	RegisterHam(Ham_TraceAttack,	"hostage_entity",	"HamHook_Entity_TraceAttack", false);
	RegisterHam(Ham_TraceAttack,	"info_target", 		"HamHook_Entity_TraceAttack", false);
	RegisterHam(Ham_TraceAttack,	"player", 		"HamHook_Entity_TraceAttack", false);
	
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer_Post", true);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	RegisterHam(Ham_CS_Item_GetMaxSpeed,	WEAPON_REFERANCE, 	"HamHook_Item_GetMaxSpeed",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE,	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	register_forward(FM_SetModel,		"FakeMeta_SetModel",			false);
	register_forward(FM_TraceLine,		"FakeMeta_TraceLine_Post",		true);
	register_forward(FM_PlaybackEvent,	"FakeMeta_PlaybackEvent",		false);
	register_forward(FM_UpdateClientData,	"FakeMeta_UpdateClientData_Post",	true);
	
	register_message(get_user_msgid("DeathMsg"), "MsgHook_Death");
	register_message(get_user_msgid("CurWeapon"), "MsgHook_CurWeapon");
	
	unregister_forward(FM_DecalIndex, g_iForwardDecalIndex, true);
	ExtraItem_Register();
}

#if defined _DEBUG
	
	ExtraItem_Register()
	{
		register_clcmd(_DEBUG_CMD, "Cmd_WeaponGive");
	}
	
	public Cmd_WeaponGive(const iPlayer)
	{
		Weapon_Give(iPlayer);
	}

#else

	new g_iItemID;

	#if !defined _ZP50
	
		ExtraItem_Register()
		{
			g_iItemID = zp_register_extra_item(ZP_ITEM_NAME, ZP_ITEM_COST, ZP_TEAM_HUMAN);
		}
	
		public zp_extra_item_selected(id, itemid)
		{
			if (itemid == g_iItemID)
			{
				Weapon_Give(id);
			}
		}

	#else
	
		RegisterExtraItem()
		{
			g_iItemID = zp_items_register(ZP_ITEM_NAME, ZP_ITEM_COST);
		}
	
		public zp_fw_items_select_pre(id, itemid, ignorecost)
		{
			if (itemid != g_iItemID)
			{
				return ZP_ITEM_AVAILABLE;
			}
			
			if (zp_core_is_zombie(id))
			{
				return ZP_ITEM_DONT_SHOW;
			}
			
			return ZP_ITEM_AVAILABLE;
		}
		
		public zp_fw_items_select_post(id, itemid, ignorecost)
		{
			if (itemid == g_iItemID)
			{
				Weapon_Give(id);
			}
		}

	#endif
	
#endif

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iItem;
	
	if (CheckItem2(iPlayer, iItem))
	{
		set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	}
}

public HamHook_Item_GetMaxSpeed(const iItem)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return HAM_IGNORED;
	}
	
	SetHamReturnFloat(WEAPON_MAX_SPEED);
	return HAM_OVERRIDE;
}

public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(Deploy, iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(Holster, iItem, iPlayer);
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_CALLFUNC(Idle, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(Reload, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(PrimaryAttack, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iButton, iPlayer, Float: flApplyModeTime;
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	flApplyModeTime = get_pdata_float(iItem, m_flApplyMode, extra_offset_weapon);
	
	// Time to apply new mode.
	if (flApplyModeTime && flApplyModeTime <= get_gametime())
	{
		set_pdata_float(iItem, m_flApplyMode, 0.0, extra_offset_weapon);
		set_pdata_int(iItem, m_iCurrentMode, !get_pdata_int(iItem, m_iCurrentMode, extra_offset_weapon), extra_offset_weapon);
	}
	
	// Complete reload
	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		new iClip		= get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		new iPrimaryAmmoIndex	= PrimaryAmmoIndex(iItem);
		new iAmmoPrimary	= GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		new iAmount		= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}
	
	// Call secondary attack
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 
		&& get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) < 0.0)
	{
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	
	return HAM_IGNORED;
}

//**********************************************
//* Weapon list update.                        *
//**********************************************

public Cmd_WeaponSelect(const iPlayer)
{
	Weapon_ModeSwitch(iPlayer, 0);
	return PLUGIN_HANDLED;
}

public Cmd_WeaponSelectEx(const iPlayer)
{
	Weapon_ModeSwitch(iPlayer, 1);
	return PLUGIN_HANDLED;
}

public HamHook_Item_AddToPlayer_Post(const iItem, const iPlayer)
{
	if (!IsValidPev(iItem) || !IsValidPev(iPlayer))
	{
		return HAM_IGNORED;
	}
	
	MsgHook_WeaponList(MSG_WEAPONLIST, iItem, iPlayer);
	return HAM_IGNORED;
}

public MsgHook_CurWeapon(const iMsgID, const iMsgDest, const iPlayer)
{
	static iItem;
	
	if (CheckItem2(iPlayer, iItem)
		&& get_pdata_int(iItem, m_iId, extra_offset_weapon) == get_msg_arg_int(2))
	{
		MESSAGE_BEGIN(iMsgDest, iMsgID, {0.0, 0.0, 0.0}, iPlayer);
		WRITE_BYTE(get_msg_arg_int(1));
		WRITE_BYTE(CSW_DUMMY);
		WRITE_BYTE(get_msg_arg_int(3));
		MESSAGE_END();
	}
}

public MsgHook_WeaponList(const iMsgID, const iMsgDest, const iMsgEntity)
{
	static arrWeaponListData[8];
	
	if (!iMsgEntity)
	{
		new szWeaponName[32];
		get_msg_arg_string(1, szWeaponName, charsmax(szWeaponName));
		
		if (!strcmp(szWeaponName, WEAPON_REFERANCE))
		{
			for (new i, a = sizeof arrWeaponListData; i < a; i++)
			{
				arrWeaponListData[i] = get_msg_arg_int(i + 2);
			}
		}
		
		return;
	}

	new bool: bIsCustom = IsCustomItem(iMsgDest);
		
	if (!bIsCustom && pev(iMsgDest, pev_impulse))
	{
		return;
	}
		
	MESSAGE_BEGIN(MSG_ONE, iMsgID, {0.0, 0.0, 0.0}, iMsgEntity);
	WRITE_STRING(bIsCustom ? WEAPON_NAME_C : WEAPON_REFERANCE);
	
	for (new i, a = sizeof arrWeaponListData; i < a; i++)
	{
		WRITE_BYTE(arrWeaponListData[i]);
	}
		
	MESSAGE_END();
		
	if (!bIsCustom)
	{
		return;
	}
	
	user_has_weapon(iMsgEntity, CSW_DUMMY, 1);
			
	MESSAGE_BEGIN(MSG_ONE, iMsgID, {0.0, 0.0, 0.0}, iMsgEntity);
	WRITE_STRING(WEAPON_NAME_S);
				
	for (new i, a = sizeof arrWeaponListData; i < a; i++)
	{
		switch (i)
		{
			case 5: WRITE_BYTE(20);
			case 6: WRITE_BYTE(CSW_DUMMY);
						
			default: WRITE_BYTE(arrWeaponListData[i]);
		}
	}
				
	MESSAGE_END();
			
	static msgWeapPickup;
	if (msgWeapPickup || (msgWeapPickup = get_user_msgid("WeapPickup")))
	{
		MESSAGE_BEGIN(MSG_ONE, msgWeapPickup, {0.0, 0.0, 0.0}, iMsgEntity);
		WRITE_BYTE(CSW_DUMMY);
		MESSAGE_END();
	}
}

Weapon_ModeSwitch(const iPlayer, const iNewMode)
{
	if (!IsValidPev(iPlayer))
	{
		return;
	}
	
	new iItem;
	
	if (!CheckItem2(iPlayer, iItem))
	{
		engclient_cmd(iPlayer, WEAPON_REFERANCE);
	}
	else
	{
		Weapon_OnModeSwitch
		(
			iItem, 
			iPlayer,
			
			get_pdata_int(iItem, m_iClip, extra_offset_weapon),
			GetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem)),
			
			iNewMode
		);
	}
}

//**********************************************
//* Fire bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static Float: vecPuncheAngle[3];

	state stFireBullets: Enabled;
	
	pev(iPlayer, pev_punchangle, vecPuncheAngle);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);
	
	state stFireBullets: Disabled;
}

public FakeMeta_TraceLine_Post(const Float: vecTraceStart[3], const Float: vecTraceEnd[3], const fNoMonsters, const iEntToSkip, const iTrace) <stFireBullets: Enabled>
{
	static Float: vecEndPos[3];
	
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	engfunc(EngFunc_TraceLine, vecEndPos, vecTraceStart, fNoMonsters, iEntToSkip, 0);
	
	UTIL_GunshotDecalTrace(0);
	UTIL_GunshotDecalTrace(iTrace, true);
	
	return FMRES_IGNORED;
}
STATEMENT_FALLBACK(FakeMeta_TraceLine_Post, FMRES_IGNORED, stFireBullets: Disabled)

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <stFireBullets: Enabled>
{
	SetHamParamFloat(3, flDamage * WEAPON_MULTIPLIER_DAMAGE);
	return HAM_IGNORED;
}
STATEMENT_FALLBACK(HamHook_Entity_TraceAttack, HAM_IGNORED, stFireBullets: Disabled)

public MsgHook_Death() <stFireBullets: Enabled>
{
	static szTruncatedWeaponName[32];
	
	if (szTruncatedWeaponName[0] == EOS)
	{
		copy(szTruncatedWeaponName, charsmax(szTruncatedWeaponName), WEAPON_NAME_C);
		replace(szTruncatedWeaponName, charsmax(szTruncatedWeaponName), "weapon_", "");
	}
	
	set_msg_arg_string(4, szTruncatedWeaponName);
	return PLUGIN_CONTINUE;
}
STATEMENT_FALLBACK(MsgHook_Death, PLUGIN_CONTINUE, stFireBullets: Disabled)

public FakeMeta_PlaybackEvent() <stFireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}
STATEMENT_FALLBACK(FakeMeta_PlaybackEvent, FMRES_IGNORED, stFireBullets: Disabled)

//**********************************************
//* Weaponbox world model.                     *
//**********************************************

public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) stWeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <stWeaponBox: Enabled>
{
	state stWeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			user_has_weapon(pev(iEntity, pev_owner), CSW_DUMMY, 0);
			
			SET_MODEL(iEntity, MODEL_WORLD);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
STATEMENT_FALLBACK(FakeMeta_SetModel, FMRES_IGNORED, stWeaponBox: Disabled)

//**********************************************
//* Create and check our custom weapon.        *
//**********************************************

new g_bitIsConnected;

#define BitSet(%0,%1) (%0 |= (1 << (%1 - 1))) 
#define BitClear(%0,%1) (%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) (%0 & (1 << (%1 - 1)))

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
}

public client_disconnected(id)
{
	BitClear(g_bitIsConnected, id);
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !BitCheck(g_bitIsConnected, iPlayer))
	{
		return false;
	}
	
	return true;
}

bool: CheckItem2(const iPlayer, &iItem)
{
	if (!BitCheck(g_bitIsConnected, iPlayer) || !IsValidPev(iPlayer))
	{
		return false;
	}
	
	iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	return true;
}

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);
	set_pdata_int(iWeapon, m_iCurrentMode, 0, extra_offset_weapon);

	set_pev(iWeapon, pev_impulse, g_iszWeaponKey);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

//**********************************************
//* Brass ejection.                            *
//**********************************************

EjectBrass(const iPlayer, const iModelIndex, const iBounce, const Float:flUpScale = -9.0, const Float: flForwardScale = 16.0, const Float: flRightScale = 0.0)
{
	static i, msgBrass;
	
	static Float: vecUp[3]; 
	static Float: vecRight[3]; 
	static Float: vecForward[3]; 
	
	static Float: vecAngle[3];
	static Float: vecOrigin[3];
	static Float: vecViewOfs[3];
	static Float: vecVelocity[3];
	
	pev(iPlayer, pev_v_angle, vecAngle);
	pev(iPlayer, pev_punchangle, vecOrigin);
	
	xs_vec_add(vecAngle, vecOrigin, vecOrigin);
	engfunc(EngFunc_MakeVectors, vecOrigin);
	
	pev(iPlayer, pev_origin, vecOrigin);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
	pev(iPlayer, pev_velocity, vecVelocity);
	
	global_get(glb_v_up, vecUp);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_forward, vecForward);
	
	for (i = 0; i < 3; i++)
	{
		vecOrigin[i] = vecOrigin[i] + vecViewOfs[i] + vecForward[i] * flForwardScale + vecUp[i] * flUpScale + vecRight[i] * flRightScale;
		vecVelocity[i] = vecVelocity[i] + vecForward[i] * 25.0 + vecUp[i] * random_float(80.0, 100.0) + vecRight[i] * random_float(50.0, 70.0);
	}
	
	if (msgBrass || (msgBrass = get_user_msgid("Brass")))
	{
		MESSAGE_BEGIN(MSG_PVS, msgBrass, vecOrigin, 0);
		WRITE_BYTE(0 /* dummy */);
		WRITE_COORD(vecOrigin[0]);
		WRITE_COORD(vecOrigin[1]);
		WRITE_COORD(vecOrigin[2]);
		WRITE_COORD(0.0 /* dummy */);
		WRITE_COORD(0.0 /* dummy */);
		WRITE_COORD(0.0 /* dummy */);
		WRITE_COORD(vecVelocity[0]);
		WRITE_COORD(vecVelocity[1]);
		WRITE_COORD(vecVelocity[2]);
		WRITE_ANGLE(vecAngle[1]);
		WRITE_SHORT(iModelIndex);
		WRITE_BYTE(iBounce);
		WRITE_BYTE(0 /* dummy */);
		WRITE_BYTE(iPlayer);
		MESSAGE_END();
	}
}

//**********************************************
//* Kick back.                                 *
//**********************************************

Weapon_KickBack(const iItem, const iPlayer, Float: upBase, Float: lateralBase, const Float: upMod, const Float: lateralMod, Float: upMax, Float: lateralMax, const directionChange)
{
	static iDirection; 
	static iShotsFired; 
	
	static Float: vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	
	if ((iShotsFired = get_pdata_int(iItem, m_iShotsFired, extra_offset_weapon)) != 1)
	{
		upBase += iShotsFired * upMod;
		lateralBase += iShotsFired * lateralMod;
	}
	
	upMax *= -1.0;
	vecPunchangle[0] -= upBase;
 
	if (upMax >= vecPunchangle[0])
	{
		vecPunchangle[0] = upMax;
	}
	
	if ((iDirection = get_pdata_int(iItem, m_iDirection, extra_offset_weapon)))
	{
		vecPunchangle[1] += lateralBase;
		
		if (lateralMax < vecPunchangle[1])
		{
			vecPunchangle[1] = lateralMax;
		}
	}
	else
	{
		lateralMax *= -1.0;
		vecPunchangle[1] -= lateralBase;
		
		if (lateralMax > vecPunchangle[1])
		{
			vecPunchangle[1] = lateralMax;
		}
	}
	
	if (!random_num(0, directionChange))
	{
		set_pdata_int(iItem, m_iDirection, !iDirection, extra_offset_weapon);
	}
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
}

//**********************************************
//* Decals.                                    *
//**********************************************

#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)

new Array: g_hDecals;

public FakeMeta_DecalIndex_Post()
{
	if (!g_hDecals)
	{
		g_hDecals = ArrayCreate(1, 1);
	}
	
	ArrayPushCell(g_hDecals, get_orig_retval());
}

UTIL_GunshotDecalTrace(const iTrace, const bool: bIsGunshot = false)
{
	static iHit;
	static iMessage;
	static iDecalIndex;
	
	static Float: flFraction; 
	static Float: vecEndPos[3];
	
	iHit = INSTANCE(get_tr2(iTrace, TR_pHit));
	
	if (iHit && !IsValidPev(iHit) || (pev(iHit, pev_flags) & FL_KILLME))
	{
		return;
	}
	
	if (pev(iHit, pev_solid) != SOLID_BSP && pev(iHit, pev_movetype) != MOVETYPE_PUSHSTEP)
	{
		return;
	}
	
	iDecalIndex = ExecuteHamB(Ham_DamageDecal, iHit, 0);
	
	if (iDecalIndex < 0 || iDecalIndex >=  ArraySize(g_hDecals))
	{
		return;
	}
	
	iDecalIndex = ArrayGetCell(g_hDecals, iDecalIndex);
	
	get_tr2(iTrace, TR_flFraction, flFraction);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	
	if (iDecalIndex < 0 || flFraction >= 1.0)
	{
		return;
	}
	
	if (bIsGunshot)
	{
		iMessage = TE_GUNSHOTDECAL;
	}
	else
	{
		iMessage = TE_DECAL;
		
		if (iHit != 0)
		{
			if (iDecalIndex > 255)
			{
				iMessage = TE_DECALHIGH;
				iDecalIndex -= 256;
			}
		}
		else
		{
			iMessage = TE_WORLDDECAL;
			
			if (iDecalIndex > 255)
			{
				iMessage = TE_WORLDDECALHIGH;
				iDecalIndex -= 256;
			}
		}
	}
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(iMessage);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	
	if (bIsGunshot)
	{
		WRITE_SHORT(iHit);
		WRITE_BYTE(iDecalIndex);
	}
	else 
	{
		WRITE_BYTE(iDecalIndex);
		
		if (iHit)
		{
			WRITE_SHORT(iHit);
		}
	}
    
	MESSAGE_END();
}

//**********************************************
//* Get and precache sounds from weapon model. *
//**********************************************

PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
				
				// server_print(" * Sound: %s", szSoundPath);
			}
		}
	}
	
	fclose(iFile);
}

//**********************************************
//* Ammo Inventory.                            *
//**********************************************

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}
