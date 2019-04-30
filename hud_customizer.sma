#include <amxmodx> 
#include <amxmisc> 

#define PLUGIN "HUD Customizer 0.4" 
#define VERSION "0.4" 
#define AUTHOR "Igoreso" 


// Hides Crosshair, Ammo, Weapons List ( CAL in code ). Players won't be able to switch weapons using list so it's not recommended
#define HUD_HIDE_CAL (1<<0)

// Hides Flashlight, but adds Crosshair ( Flash in code )
#define HUD_HIDE_FLASH (1<<1)

// Hides all. Equal to "hud_draw 0", it removes everything (amx's menus TOO), so it's hardly not recommended.
//#define HUD_HIDE_ALL (1<<2)

// Hides Radar, Health & Armor, but adds Crosshair ( RHA in code )	
#define HUD_HIDE_RHA (1<<3)

// Hides Timer	
#define HUD_HIDE_TIMER (1<<4)

// Hides Money
#define HUD_HIDE_MONEY (1<<5)

// Hides Crosshair ( Cross in code )
#define HUD_HIDE_CROSS (1<<6)

// Draws additional Crosshair, NOT tested.
//#define HUD_DRAW_CROSS (1<<7)



new g_msgHideWeapon
new bool:g_bHideCAL
new bool:g_bHideFlash
//new bool:g_bHideAll
new bool:g_bHideRHA
new bool:g_bHideTimer
new bool:g_bHideMoney
new bool:g_bHideCross
//new bool:g_bDrawCross

new g_cvarHideCAL
new g_cvarHideFlash
//new g_cvarHideAll
new g_cvarHideRHA
new g_cvarHideTimer
new g_cvarHideMoney
new g_cvarHideCross
//new g_cvarDrawCross

public plugin_init() 
{ 
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	g_msgHideWeapon = get_user_msgid("HideWeapon")
	register_event("ResetHUD", "onResetHUD", "b")
	register_message(g_msgHideWeapon, "msgHideWeapon")
	
	g_cvarHideCAL = register_cvar("amx_hud_hide_cross_ammo_weaponlist", "0")
	g_cvarHideFlash = register_cvar("amx_hud_hide_flashlight", "1")
//	g_cvarHideAll = register_cvar("amx_hud_hide_all", "0")	// NOT RECOMMENDED
	g_cvarHideRHA = register_cvar("amx_hud_hide_radar_health_armor", "1")
	g_cvarHideTimer = register_cvar("amx_hud_hide_timer", "1")
	g_cvarHideMoney = register_cvar("amx_hud_hide_money", "0")
	g_cvarHideCross = register_cvar("amx_hud_hide_crosshair", "0")
//	g_cvarDrawCross = register_cvar("amx_hud_draw_newcross", "0")

	HudApplyCVars()
} 

public onResetHUD(id)
{
	HudApplyCVars()
	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
	{
		message_begin(MSG_ONE, g_msgHideWeapon, _, id)
		write_byte(iHideFlags)
		message_end()
	}	
}

public msgHideWeapon()
{
	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags)
}

GetHudHideFlags()
{
	new iFlags

	if( g_bHideCAL )
		iFlags |= HUD_HIDE_CAL
	if( g_bHideFlash )
		iFlags |= HUD_HIDE_FLASH
//	if( g_bHideAll )
//		iFlags |= HUD_HIDE_ALL
	if( g_bHideRHA )
		iFlags |= HUD_HIDE_RHA
	if( g_bHideTimer )
		iFlags |= HUD_HIDE_TIMER
	if( g_bHideMoney )
		iFlags |= HUD_HIDE_MONEY 
	if( g_bHideCross )
		iFlags |= HUD_HIDE_CROSS
//	if( g_bDrawCross )
//		iFlags |= HUD_DRAW_CROSS


	return iFlags
}

HudApplyCVars()
{
	g_bHideCAL = bool:get_pcvar_num(g_cvarHideCAL)
	g_bHideFlash = bool:get_pcvar_num(g_cvarHideFlash)
//	g_bHideAll = bool:get_pcvar_num(g_cvarHideAll)
	g_bHideRHA = bool:get_pcvar_num(g_cvarHideRHA)
	g_bHideTimer = bool:get_pcvar_num(g_cvarHideTimer)
	g_bHideMoney = bool:get_pcvar_num(g_cvarHideMoney)
	g_bHideCross = bool:get_pcvar_num(g_cvarHideCross)
//	g_bDrawCross = bool:get_pcvar_num(g_cvarDrawCross)
}