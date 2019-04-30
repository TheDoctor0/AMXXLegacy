#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Unlimited Clip Ammo"
#define VERSION "1.0"
#define AUTHOR "-Acid-"

// weapons offsets
#define OFFSET_CLIPAMMO        51
#define OFFSET_LINUX_WEAPONS    4
#define fm_cs_get_weapon_ammo(%1,%2)    set_pdata_int(%1, OFFSET_CLIPAMMO, %2, OFFSET_LINUX_WEAPONS)

// players offsets
#define m_pActiveItem 373

const NOCLIP_WPN_BS    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new const g_MaxClipAmmo[] =
{
    0,
    13, //CSW_P228
    0,
    10, //CSW_SCOUT
    0,  //CSW_HEGRENADE
    7,  //CSW_XM1014
    0,  //CSW_C4
    30,//CSW_MAC10
    30, //CSW_AUG
    0,  //CSW_SMOKEGRENADE
    15,//CSW_ELITE
    20,//CSW_FIVESEVEN
    25,//CSW_UMP45
    30, //CSW_SG550
    35, //CSW_GALIL
    25, //CSW_FAMAS
    12,//CSW_USP
    20,//CSW_GLOCK18
    10, //CSW_AWP
    30,//CSW_MP5NAVY
    100,//CSW_M249
    8,  //CSW_M3
    30, //CSW_M4A1
    30,//CSW_TMP
    20, //CSW_G3SG1
    0,  //CSW_FLASHBANG
    7,  //CSW_DEAGLE
    30, //CSW_SG552
    30, //CSW_AK47
    0,  //CSW_KNIFE
    50//CSW_P90
}

public plugin_init()
{
    register_plugin( PLUGIN , VERSION , AUTHOR );
    register_event("CurWeapon" , "Event_CurWeapon" , "be" , "1=1" );
}

public Event_CurWeapon( id )
{
    new iWeapon = read_data(2)
    if( !( NOCLIP_WPN_BS & (1<<iWeapon) ) )
    {
        fm_cs_get_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , g_MaxClipAmmo[ iWeapon ] )
    }
}