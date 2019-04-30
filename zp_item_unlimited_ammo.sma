#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zp50_items>
#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_class_nemesis>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define ITEM_NAME "Unlimited Ammo"
#define ITEM_COST 50

/*============================================================================*/

// CS Offsets
#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }

new g_ItemID, g_has_unlimited_clip[33]

public plugin_init()
{
	register_plugin("[ZP] Extra: Unlimited Clip", "1.0", "Pro7")
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)	
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End") 
	register_event("CurWeapon", "current_weapon", "be", "1=1")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
}

public current_weapon(id)
{
	if(g_has_unlimited_clip[id])
	{
		new iWeapon = get_user_weapon(id) 
		if(iWeapon == CSW_HEGRENADE)
        {
			give_item(id, "weapon_hegrenade")
			cs_set_user_bpammo(id, CSW_HEGRENADE, 245)
		}
		
		if(iWeapon == CSW_HEGRENADE)
        {
			give_item( id, "weapon_flashbang" )
			cs_set_user_bpammo(id, CSW_FLASHBANG, 245)
		}
		
		if(iWeapon == CSW_HEGRENADE)
        {
			give_item( id, "weapon_smokegrenade" )
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 245)
		}	
	}
}

// Reset flags for all players on newround
public event_round_start()
{
	for (new id; id <= 32; id++) g_has_unlimited_clip[id] = false;
}

public logevent_round_end()
{
	for (new id; id <= 32; id++)
	{
		if(is_user_alive(id) && g_has_unlimited_clip[id])
		{
			ham_strip_weapon(id, "weapon_hegrenade")
			ham_strip_weapon(id, "weapon_flashbang")
			ham_strip_weapon(id, "weapon_smokegrenade")
		}
	}
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
	
	// Unlimited ammo only available to humans
	if (zp_class_nemesis_get(id) || zp_core_is_zombie(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
		return ZP_ITEM_DONT_SHOW;
	
	// Player already has unlimited ammo
	if (g_has_unlimited_clip[id])
		return ZP_ITEM_DONT_SHOW;
	
	return ZP_ITEM_AVAILABLE;
}

// Player buys our upgrade, set the unlimited ammo flag
public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if (itemid != g_ItemID)
		return;
		
	g_has_unlimited_clip[id] = true
}

// Unlimited clip code
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Player doesn't have the unlimited clip upgrade
	if (!g_has_unlimited_clip[msg_entity])
		return;
	
	// Player not alive or not an active weapon
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2) // get weapon ID
	clip = get_msg_arg_int(3) // get weapon clip
	
	// Unlimited Clip Ammo
	if (MAXCLIP[weapon] > 1) // skip grenades
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon]) // HUD should show full clip all the time
		
		if (clip < 2) // refill when clip is nearly empty
		{
			// Get the weapon entity
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)
			
			// Set max clip on weapon
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

// Set Weapon Clip Ammo
stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}

stock ham_strip_weapon(id,weapon[])
{
    if(!equal(weapon,"weapon_",7)) return 0;

    new wId = get_weaponid(weapon);
    if(!wId) return 0;

    new wEnt;
    while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
    if(!wEnt) return 0;

    if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);

    if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
    ExecuteHamB(Ham_Item_Kill,wEnt);

    set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));

    return 1;
}
