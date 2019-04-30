/*================================================================================
	
	--------------------------
	-*- [ZP] Items Manager -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <amx_settings_api>
#include <zp50_colorchat>
#include <zp50_core>
#include <zp50_ammopacks>
#include <zp50_core_const>
#include <zp50_items_const>
#include <zp50_class_nemesis>

// Extra Items file
new const ZP_EXTRAITEMS_FILE[] = "zp_extraitems.ini"

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

#define MAXPLAYERS 32

// For item list menu handlers
#define MENU_PAGE_ITEMS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

// Items data
new Array:g_ItemRealName
new Array:g_ItemName
new Array:g_ItemCost
new Array:g_ItemType
new Array:g_ItemAmmo
new Array:g_ItemVip
new g_ItemCount
new g_AdditionalMenuText[32]

native zp_get_user_vip(id);

public plugin_init()
{
	register_plugin("[ZP] Items Manager", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("say /items", "clcmd_items")
	register_clcmd("say_team /items", "clcmd_items")
	register_clcmd("say items", "clcmd_items")
	
	register_clcmd("say /sklep", "clcmd_items")
	register_clcmd("say_team /sklep", "clcmd_items")
	
	register_clcmd("say /shop", "clcmd_items")
	register_clcmd("say_team /shop", "clcmd_items")
	
	g_Forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("zp_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("zp_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

public plugin_natives()
{
	register_library("zp50_items")
	register_native("zp_items_register", "native_items_register")
	register_native("zp_items_get_id", "native_items_get_id")
	register_native("zp_items_get_name", "native_items_get_name")
	register_native("zp_items_get_real_name", "native_items_get_real_name")
	register_native("zp_items_get_cost", "native_items_get_cost")
	register_native("zp_items_show_menu", "native_items_show_menu")
	register_native("zp_items_force_buy", "native_items_force_buy")
	register_native("zp_items_menu_text_add", "native_items_menu_text_add")
	
	// Initialize dynamic arrays
	g_ItemRealName = ArrayCreate(32, 1)
	g_ItemName = ArrayCreate(32, 1)
	g_ItemCost = ArrayCreate(1, 1)
	g_ItemType=ArrayCreate(1, 1)
	g_ItemAmmo=ArrayCreate(1, 1)
	g_ItemVip=ArrayCreate(1,1)
}

public native_items_register(plugin_id, num_params)
{
	new name[32], cost = get_param(2), type=6, ammo=0, vip=0
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register item with an empty name")
		return ZP_INVALID_ITEM;
	}
	
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(name, item_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Item already registered (%s)", name)
			return ZP_INVALID_ITEM;
		}
	}
	
	// Load settings from extra items file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_ItemRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name, charsmax(name)))
	amx_save_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name)
	ArrayPushString(g_ItemName, name)
	
	// Cost
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost))
	amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost)
	ArrayPushCell(g_ItemCost, cost)
	
	// Type
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "TYPE", type))
	amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "TYPE", type)
	ArrayPushCell(g_ItemType, type)
	
	ammo=0
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "AMMO", ammo))
	amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "AMMO", ammo)
	ArrayPushCell(g_ItemAmmo, ammo)
	
	vip=0
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP", vip))
	amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "VIP", vip)
	ArrayPushCell(g_ItemVip, vip)
	
	g_ItemCount++
	return g_ItemCount - 1;
}

public native_items_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every item
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(real_name, item_name))
		return index;
	}
	
	return ZP_INVALID_ITEM;
}

public native_items_get_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_ItemName, item_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public native_items_get_real_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_ItemRealName, item_id, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_items_get_cost(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemCost, item_id);
}

public native_items_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	clcmd_items(id)
	return true;
}

public native_items_force_buy(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new item_id = get_param(2)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new ignorecost = get_param(3)
	
	buy_item(id, item_id, ignorecost)
	return true;
}

public native_items_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

public client_disconnect(id)
	MENU_PAGE_ITEMS = 0

public clcmd_items(id)
{
	// Player dead
	if (!is_user_alive(id))
	return;
	
	if(get_user_team(id) == 1)
		show_items_menu2(id, 7)
	else 
		show_items_menu(id)
}

public clcmd_buy(id){
	// Player dead
	if (!is_user_alive(id))
	return PLUGIN_CONTINUE
	
	if(get_user_team(id) == 1) 
		show_items_menu2(id, 7)
	else 
		show_items_menu(id)
	
	return PLUGIN_HANDLED
}

show_items_menu(id)
{
	static menu[128]
	new menuid, itemdata[2]
	
	// Title
	formatex(menu, charsmax(menu), "Menu \yExtra Items")
	menuid = menu_create(menu, "menu_extraitems")
	
	formatex(menu, charsmax(menu), "Pistolety")
	itemdata[0] = 1
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Strzelby")
	itemdata[0] = 2
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Karabiny")
	itemdata[0] = 3
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Snajperki")
	itemdata[0] = 4
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Bazooki")
	itemdata[0] = 5
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Karabiny Maszynowe")
	itemdata[0] = 6
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Dodatki i Granaty^n")
	itemdata[0] = 7
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Noze^n")
	itemdata[0] = 8
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Tatuaze^n")
	itemdata[0] = 9
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)
	
	formatex(menu, charsmax(menu), "Wyjscie")
	itemdata[0] = 0
	itemdata[1] = 0
	menu_additem(menuid, menu, itemdata)

	menu_setprop(menuid, MPROP_PERPAGE, 0)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}

// Items Menu
show_items_menu2(id, key)
{
	if(key==0) return

	static menu[128], name[32], cost, type, vip, transkey[64]
	new menuid, index, itemdata[2]
	
	// Title
	//formatex(menu, charsmax(menu), "%L:\r", id, "MENU_EXTRABUY")
	switch(key)
	{
		case 1: formatex(menu, charsmax(menu), "\r[\y Pistolety \r] ")
		case 2: formatex(menu, charsmax(menu), "\r[\y Strzelby \r] ")
		case 3: formatex(menu, charsmax(menu), "\r[\y Karabiny \r] ")
		case 4: formatex(menu, charsmax(menu), "\r[\y Snajperki \r] ")
		case 5: formatex(menu, charsmax(menu), "\r[\y Bazooki \r] ")
		case 6: formatex(menu, charsmax(menu), "\r[\y Karabiny Maszynowe \r] ")
		case 7: formatex(menu, charsmax(menu), "\r[\y Dodatki i Granaty \r] ")
		case 8: formatex(menu, charsmax(menu), "\r[\y Noze \r] ")
		case 9: formatex(menu, charsmax(menu), "\r[\y Tatuaze \r] ")
	}
	menuid = menu_create(menu, "menu_extraitems2")
	
	// Item List
	for (index = 0; index < g_ItemCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		type = ArrayGetCell(g_ItemType, index)
		
		vip = ArrayGetCell(g_ItemVip, index)
		if(type!=key)
		continue;
		
		// Execute item select attempt forward
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, index, 0)
		
		// Show item to player?
		if (g_ForwardResult >= ZP_ITEM_DONT_SHOW)
		continue;
		
		// Add Item Name and Cost
		ArrayGetString(g_ItemName, index, name, charsmax(name))
		cost = ArrayGetCell(g_ItemCost, index)
		
		// ML support for item name
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		if(cost>0) {
			formatex(menu, charsmax(menu), "%s \y[ %d AP ] %s", name, cost, g_AdditionalMenuText)
		}
		else formatex(menu, charsmax(menu), "%s \w%s", name, g_AdditionalMenuText)
		
		if(vip) 
		{
			if(zp_get_user_vip(id))
				format(menu, charsmax(menu), "%s \y[VIP]", menu)
			else
				format(menu, charsmax(menu), "\d%s \y[VIP]", menu)
		}
		
		// Item available to player?
		if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
		format(menu, charsmax(menu), "\d%s", menu)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No items to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_EXTRA_ITEMS")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	if(!zp_core_is_zombie(id) && !zp_class_nemesis_get(id))
	{
		formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
		menu_setprop(menuid, MPROP_BACKNAME, menu)
		formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
		menu_setprop(menuid, MPROP_NEXTNAME, menu)
	}
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}

public menu_extraitems2(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember items menu page
	MENU_PAGE_ITEMS = item / 7
	
	// Dead players are not allowed to buy items
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve item id
	new itemdata[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	itemid = itemdata[0]
	
	// Attempt to buy the item
	buy_item(id, itemid,0)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

// Items Menu
public menu_extraitems(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember items menu page
	MENU_PAGE_ITEMS = item / 7
	
	// Dead players are not allowed to buy items
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve item id
	new itemdata[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	itemid = itemdata[0]
	
	// Attempt to buy the item
	show_items_menu2(id, itemid)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

// Buy Item
buy_item(id, itemid, ignorecost = 0)
{
	new vip = ArrayGetCell(g_ItemVip, itemid)
	if(vip && !zp_get_user_vip(id)) return
	// Execute item select attempt forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, itemid, ignorecost)
	
	new required_cost = ArrayGetCell(g_ItemCost, itemid)
	new current_cost=zp_ammopacks_get(id)
	
	if(current_cost<required_cost) 
	return;
	
	// Item available to player?
	if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
	return;
	
	// Execute item selected forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_POST], g_ForwardResult, id, itemid, ignorecost)
	
	if(required_cost<=0)
	return
	
	zp_ammopacks_set(id, current_cost - required_cost)
}