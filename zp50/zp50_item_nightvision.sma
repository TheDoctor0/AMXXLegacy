/*================================================================================
	
	------------------------------
	-*- [ZP] Item: Nightvision -*-
	------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#define ITEM_NAME "Nightvision"
#define ITEM_COST 10

#include <amxmodx>
#include <cstrike>
#include <zp50_items>
#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_class_nemesis>

new g_ItemID

public plugin_init()
{
	register_plugin("[ZP] Item: Nightvision", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
	
	// Nightvision only available to humans
	if (zp_class_nemesis_get(id) || zp_core_is_zombie(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
		return ZP_ITEM_DONT_SHOW;
	
	// Player already has nightvision
	if (cs_get_user_nvg(id))
		return ZP_ITEM_DONT_SHOW;
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_ItemID)
		return;
	
	// Give player nightvision and enable it automatically
	cs_set_user_nvg(id, 1)
	client_cmd(id, "nightvision")
}
