/*================================================================================
	
	-------------------------
	-*- [ZP] Class: Human -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <cs_weap_restrict_api>
#include <zp50_core>
#include <zp50_colorchat>
#include <zp50_class_human_const>
#include <zp50_gamemodes>
#include <zp50_class_survivor>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

// Human Classes file
new const ZP_HUMANCLASSES_FILE[] = "zp_humanclasses.ini"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64

// Models
new g_model_vknife_human[MODEL_MAX_LENGTH] = "models/v_knife.mdl"

#define MAXPLAYERS 32

#define HUMANS_DEFAULT_NAME "Male"
#define HUMANS_DEFAULT_DESCRIPTION ""
#define HUMANS_DEFAULT_HEALTH 100
#define HUMANS_DEFAULT_SPEED 1.0
#define HUMANS_DEFAULT_GRAVITY 1.0
#define HUMANS_DEFAULT_SEX 0

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// For class list menu handlers
#define MENU_PAGE_CLASS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_HumanClassCount
new Array:g_HumanClassRealName
new Array:g_HumanClassName
new Array:g_HumanClassDesc
new Array:g_HumanClassHealth
new Array:g_HumanClassSpeed
new Array:g_HumanClassGravity
new Array:g_HumanClassSex
new Array:g_HumanClassModelsFile
new Array:g_HumanClassModelsHandle
new Array:g_HumanClassBody
new Array:g_HumanClassVip
new g_HumanClass[MAXPLAYERS+1]
new g_AdditionalMenuText[32]
new g_HudSync
new g_MaxPlayers

native zp_get_user_vip(id);

public plugin_init()
{
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_plugin("[ZP] Class: Human", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("say /hclass", "show_menu_humanclass")
	register_clcmd("say /lklasa", "show_menu_humanclass")
	register_clcmd("say /class", "show_class_menu")
	register_clcmd("say /klasa", "show_class_menu")
	
	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zp_fw_class_human_select_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zp_fw_class_human_select_post", ET_CONTINUE, FP_CELL, FP_CELL)
	
	g_HudSync = CreateHudSyncObj()
	g_MaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	// No classes loaded, add default human class
	if (g_HumanClassCount < 1)
	{
		ArrayPushString(g_HumanClassRealName, HUMANS_DEFAULT_NAME)
		ArrayPushString(g_HumanClassName, HUMANS_DEFAULT_NAME)
		ArrayPushString(g_HumanClassDesc, HUMANS_DEFAULT_DESCRIPTION)
		ArrayPushCell(g_HumanClassHealth, HUMANS_DEFAULT_HEALTH)
		ArrayPushCell(g_HumanClassSpeed, HUMANS_DEFAULT_SPEED)
		ArrayPushCell(g_HumanClassGravity, HUMANS_DEFAULT_GRAVITY)
		ArrayPushCell(g_HumanClassSex, HUMANS_DEFAULT_SEX)
		ArrayPushCell(g_HumanClassModelsFile, false)
		ArrayPushCell(g_HumanClassModelsHandle, Invalid_Array)
		ArrayPushCell(g_HumanClassBody, 0)
		ArrayPushCell(g_HumanClassVip, 0)
		g_HumanClassCount++
	}
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUMAN", g_model_vknife_human, charsmax(g_model_vknife_human)))
	amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUMAN", g_model_vknife_human)
	
	// Precache models
	precache_model(g_model_vknife_human)
	
	precache_sound("csobc/h/f_bhit_flesh-1.wav")
	precache_sound("csobc/h/f_bhit_flesh-2.wav")
	precache_sound("csobc/h/f_bhit_flesh-3.wav")
	
	precache_sound("csobc/h/f_die1.wav")
	precache_sound("csobc/h/f_die2.wav")
	precache_sound("csobc/h/f_die3.wav")
	
	precache_sound("csobc/h/f_headshot1.wav")
	precache_sound("csobc/h/f_headshot2.wav")
	precache_sound("csobc/h/f_headshot3.wav")
	
	precache_sound("csobc/h/hs_f_bhit_flesh-1.wav")
	precache_sound("csobc/h/hs_f_bhit_flesh-2.wav")
	precache_sound("csobc/h/hs_f_bhit_flesh-3.wav")
	
	precache_sound("csobc/h/bhit_flesh-1.wav")
	precache_sound("csobc/h/bhit_flesh-2.wav")
	precache_sound("csobc/h/bhit_flesh-3.wav")
	
	precache_sound("csobc/h/die1.wav")
	precache_sound("csobc/h/die2.wav")
	precache_sound("csobc/h/die3.wav")
	
	precache_sound("csobc/h/headshot1.wav")
	precache_sound("csobc/h/headshot2.wav")
	precache_sound("csobc/h/headshot3.wav")
	
	precache_sound("csobc/h/hs_bhit_flesh-1.wav")
	precache_sound("csobc/h/hs_bhit_flesh-2.wav")
	precache_sound("csobc/h/hs_bhit_flesh-3.wav")
}

public plugin_natives()
{
	register_library("zp50_class_human")
	register_native("zp_class_human_get_current", "native_class_human_get_current")
	register_native("zp_class_human_get_next", "native_class_human_get_next")
	register_native("zp_class_human_set_next", "native_class_human_set_next")
	register_native("zp_class_human_get_max_health", "_class_human_get_max_health")
	register_native("zp_class_human_get_sex", "_class_human_get_sex")
	register_native("zp_class_human_register", "native_class_human_register")
	register_native("zp_class_human_register_model", "_class_human_register_model")
	register_native("zp_class_human_get_id", "native_class_human_get_id")
	register_native("zp_class_human_get_name", "native_class_human_get_name")
	register_native("zp_class_human_get_real_name", "_class_human_get_real_name")
	register_native("zp_class_human_get_desc", "native_class_human_get_desc")
	register_native("zp_class_human_get_count", "native_class_human_get_count")
	register_native("zp_class_human_show_menu", "native_class_human_show_menu")
	register_native("zp_class_human_menu_text_add", "_class_human_menu_text_add")
	
	// Initialize dynamic arrays
	g_HumanClassRealName = ArrayCreate(32, 1)
	g_HumanClassName = ArrayCreate(32, 1)
	g_HumanClassDesc = ArrayCreate(32, 1)
	g_HumanClassHealth = ArrayCreate(1, 1)
	g_HumanClassSpeed = ArrayCreate(1, 1)
	g_HumanClassSex = ArrayCreate(1, 1)
	g_HumanClassGravity = ArrayCreate(1, 1)
	g_HumanClassModelsFile = ArrayCreate(1, 1)
	g_HumanClassModelsHandle = ArrayCreate(1, 1)
	g_HumanClassBody = ArrayCreate(1, 1)
	g_HumanClassVip = ArrayCreate(1, 1)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || zp_core_is_zombie(id))
	return FMRES_IGNORED;
	
	new new_sound[SOUND_MAX_LENGTH]
	
	// Hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		
		if(ArrayGetCell(g_HumanClassSex, g_HumanClass[id]))
		formatex(new_sound, charsmax(new_sound), "csobc/h/f_bhit_flesh-%d.wav",random_num(1,3))
		else formatex(new_sound, charsmax(new_sound), "csobc/h/hs_bhit_flesh-%d.wav",random_num(1,3))
		
		emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
		
		return FMRES_SUPERCEDE;
	}
	
	// Hs hit
	
	if (sample[7] == 'h' && sample[8] == 's' && sample[10] == 'b' && sample[11] == 'h'&& sample[12] == 'i')
	{
		
		if(ArrayGetCell(g_HumanClassSex, g_HumanClass[id]))
		formatex(new_sound, charsmax(new_sound), "csobc/h/hs_f_bhit_flesh-%d.wav",random_num(1,3))
		else formatex(new_sound, charsmax(new_sound), "csobc/h/hs_bhit_flesh-%d.wav",random_num(1,3))
		
		emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
		
		return FMRES_SUPERCEDE;
	}
	
	// Headshot
	if (sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a')
	{
		if(ArrayGetCell(g_HumanClassSex, g_HumanClass[id]))
		formatex(new_sound, charsmax(new_sound), "csobc/h/f_headshot%d.wav",random_num(1,3))
		else formatex(new_sound, charsmax(new_sound), "csobc/h/headshot%d.wav",random_num(1,3))
		
		emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
		
		return FMRES_SUPERCEDE;
	}
	
	// Die
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		if(ArrayGetCell(g_HumanClassSex, g_HumanClass[id]))
		formatex(new_sound, charsmax(new_sound), "csobc/h/f_die%d.wav",random_num(1,3))
		else formatex(new_sound, charsmax(new_sound), "csobc/h/die%d.wav",random_num(1,3))
		
		emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
} 

public client_putinserver(id)
{
	g_HumanClass[id] = 0
}

public client_disconnect(id)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS = 0
}

public show_class_menu(id)
{
	if (!zp_core_is_zombie(id))
	show_menu_humanclass(id)
}

public show_menu_humanclass(id)
{
	static menu[128]
	new menuid, itemdata[2]
	
	if(zp_gamemodes_get_current()==ZP_NO_GAME_MODE){
		formatex(menu, charsmax(menu), "\r[\yWybierz Klase Ludzi\r]^n \wWybierz Plec:")
	} else {
		formatex(menu, charsmax(menu), "\r[\dWybierz Klase Ludzi\r]^n^n\yMozesz wybrac klase tylko \wprzed zarazeniem\y!")
	}
	menuid = menu_create(menu, "menu_humanclass")
	
	if(zp_gamemodes_get_current()==ZP_NO_GAME_MODE){
		formatex(menu, charsmax(menu), "Mezczyzna")
		
		itemdata[0] = 1
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
		
		formatex(menu, charsmax(menu), "Kobieta")
		
		itemdata[0] = 2
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}else{
		formatex(menu, charsmax(menu), "\dMezczyzna")
		
		itemdata[0] = 1
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
		
		formatex(menu, charsmax(menu), "\dKobieta")
		
		itemdata[0] = 2
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "Wyjscie")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_CLASS = min(MENU_PAGE_CLASS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_CLASS)
}

public menu_humanclass(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	if(zp_gamemodes_get_current()!=ZP_NO_GAME_MODE) {
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember class menu page
	MENU_PAGE_CLASS = item / 7
	
	// Retrieve class index
	new itemdata[2], dummy, index
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	index = itemdata[0]
	
	show_menu_humanclass2(id, index)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public show_menu_humanclass2(id, key)
{
	if(zp_gamemodes_get_current()!=ZP_NO_GAME_MODE) return;
	static menu[128], name[32], description[32], transkey[64]
	new menuid, itemdata[2], index
	
	formatex(menu, charsmax(menu), "Wybierz Klase Ludzi\r")
	menuid = menu_create(menu, "menu_humanclass2")
	new sex
	
	for (index = 0; index < g_HumanClassCount; index++)
	{
		sex=ArrayGetCell(g_HumanClassSex, index)+1
		
		if (key!=sex)
		continue;
		
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
		
		// Show class to player?
		if (g_ForwardResult >= ZP_CLASS_DONT_SHOW)
		continue;
		
		ArrayGetString(g_HumanClassName, index, name, charsmax(name))
		ArrayGetString(g_HumanClassDesc, index, description, charsmax(description))
		
		// ML support for class name + description
		formatex(transkey, charsmax(transkey), "HUMANDESC %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(description, charsmax(description), "%L", id, transkey)
		formatex(transkey, charsmax(transkey), "HUMANNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Class available to player?
		if (g_HumanClass[id] == index)
		formatex(menu, charsmax(menu), "\r%s \y%s", name, description)
		// Class is current class?
		else formatex(menu, charsmax(menu), "%s \y%s", name, description)
		
		if(ArrayGetCell(g_HumanClassVip, index))
		{
			if(zp_get_user_vip(id))
				format(menu, charsmax(menu), "%s\y[VIP]", menu)
			else 
				format(menu, charsmax(menu), "\d%s\y[VIP]", menu)
		}

		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No classes to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "Brak dostepnych klas.")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "Wroc")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "Dalej")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "Wyjdz")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_CLASS = min(MENU_PAGE_CLASS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_CLASS)
}

public menu_humanclass2(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember class menu page
	MENU_PAGE_CLASS = item / 7
	
	// Retrieve class index
	new itemdata[2], dummy, index
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	index = itemdata[0]
	
	// Execute class select attempt forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
	
	// Class available to player?
	if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	if(ArrayGetCell(g_HumanClassVip, index) && !zp_get_user_vip(id))
	{
		set_hudmessage(255, 255, 0, -1.0, 0.6, 0, 0.1, 2.0, 0.5, 1.0, -1)
		ShowSyncHudMsg(id, g_HudSync, "Ta klasa jest dostepna tylko dla VIPow")	
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Make selected class next class for player
	g_HumanClass[id] = index
	
	update_info(id)
	
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	if(is_valid_ent(weapon_ent))
		ExecuteHamB(Ham_Item_Deploy,weapon_ent)
	
	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_ForwardResult, id, index)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public zp_fw_core_cure_post(id, attacker)
{	
	// Bots pick class automatically
	if (is_user_bot(id))
	{
		// Try choosing class
		new index, start_index = random_num(0, g_HumanClassCount - 1)
		for (index = start_index + 1; /* no condition */; index++)
		{
			// Start over when we reach the end
			if (index >= g_HumanClassCount)
			index = 0
			
			// Execute class select attempt forward
			ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
			
			// Class available to player?
			if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			{
				g_HumanClass[id] = index
				break;
			}
			
			// Loop completed, no class could be chosen
			if (index == start_index)
			break;
		}
	}
	
	// Apply human player model
	new Array:class_models = ArrayGetCell(g_HumanClassModelsHandle, g_HumanClass[id])
	if (class_models != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_models) - 1)
		new player_model[32]
		ArrayGetString(class_models, index, player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_reset_player_model(id)
	}
	
	set_pev(id, pev_body, ArrayGetCell(g_HumanClassBody, g_HumanClass[id]))
	
	// Set custom knife model
	cs_set_player_view_model(id, CSW_KNIFE, g_model_vknife_human)
	
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	if(is_valid_ent(weapon_ent))
		ExecuteHamB(Ham_Item_Deploy,weapon_ent)
}

public update_info(id)
{
	// Apply human player model
	new Array:class_models = ArrayGetCell(g_HumanClassModelsHandle, g_HumanClass[id])
	if (class_models != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_models) - 1)
		new player_model[32]
		ArrayGetString(class_models, index, player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_reset_player_model(id)
	}
	set_pev(id, pev_body, ArrayGetCell(g_HumanClassBody, g_HumanClass[id]))
}

public zp_fw_core_infect(id, attacker)
{
	// Remove custom knife model
	cs_reset_player_view_model(id, CSW_KNIFE)
}

public native_class_human_get_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	return g_HumanClass[id];
}

public native_class_human_get_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	return g_HumanClass[id];
}

public native_class_human_set_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	g_HumanClass[id] = classid
	return true;
}

public _class_human_get_max_health(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return -1;
	}
	
	return ArrayGetCell(g_HumanClassHealth, classid);
}

public _class_human_get_sex(plugin_id, num_params)
{
	new id = get_param(1), sex
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	if(zp_class_survivor_get(id))
	sex = ArrayGetCell(g_HumanClassSex, g_HumanClass[id])
	if(sex>0) return 4
	return 0
}

public native_class_human_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register human class with an empty name")
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	new index, humanclass_name[32]
	for (index = 0; index < g_HumanClassCount; index++)
	{
		ArrayGetString(g_HumanClassRealName, index, humanclass_name, charsmax(humanclass_name))
		if (equali(name, humanclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Human class already registered (%s)", name)
			return ZP_INVALID_HUMAN_CLASS;
		}
	}
	
	new description[32]
	get_string(2, description, charsmax(description))
	new health = get_param(3)
	new Float:speed = get_param_f(4)
	new Float:gravity = get_param_f(5)
	new body=0
	new vip=0
	
	// Load settings from human classes file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_HumanClassRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_HUMANCLASSES_FILE, real_name, "NAME", name, charsmax(name)))
	amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "NAME", name)
	ArrayPushString(g_HumanClassName, name)
	
	// Description
	if (!amx_load_setting_string(ZP_HUMANCLASSES_FILE, real_name, "INFO", description, charsmax(description)))
	amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "INFO", description)
	ArrayPushString(g_HumanClassDesc, description)
	
	// Models
	new Array:class_models = ArrayCreate(32, 1)
	amx_load_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "MODELS", class_models)
	if (ArraySize(class_models) > 0)
	{
		ArrayPushCell(g_HumanClassModelsFile, true)
		
		// Precache player models
		new index, player_model[32], model_path[128]
		for (index = 0; index < ArraySize(class_models); index++)
		{
			ArrayGetString(class_models, index, player_model, charsmax(player_model))
			formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
			precache_model(model_path)
			// Support modelT.mdl files
			formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
			if (file_exists(model_path)) precache_model(model_path)
		}
	}
	else
	{
		ArrayPushCell(g_HumanClassModelsFile, false)
		ArrayDestroy(class_models)
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "MODELS", "")
	}
	ArrayPushCell(g_HumanClassModelsHandle, class_models)
	
	//body
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "BODY", body))
	amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "BODY", body)
	ArrayPushCell(g_HumanClassBody, body)
	
	// Health
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "HEALTH", health))
	amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "HEALTH", health)
	ArrayPushCell(g_HumanClassHealth, health)
	
	// Speed
	if (!amx_load_setting_float(ZP_HUMANCLASSES_FILE, real_name, "SPEED", speed))
	amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "SPEED", speed)
	ArrayPushCell(g_HumanClassSpeed, speed)
	
	// Gravity
	if (!amx_load_setting_float(ZP_HUMANCLASSES_FILE, real_name, "GRAVITY", gravity))
	amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "GRAVITY", gravity)
	ArrayPushCell(g_HumanClassGravity, gravity)
	
	new sex
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "SEX", sex))
	amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "SEX", sex)
	ArrayPushCell(g_HumanClassSex, sex)
	
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "VIP", vip))
	amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "VIP", vip)
	ArrayPushCell(g_HumanClassVip, vip)
	
	g_HumanClassCount++
	return g_HumanClassCount - 1;
}

public _class_human_register_model(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_HumanClassModelsFile, classid))
	return true;
	
	new player_model[32]
	get_string(2, player_model, charsmax(player_model))
	
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
	
	precache_model(model_path)
	
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
	if (file_exists(model_path)) precache_model(model_path)
	
	new Array:class_models = ArrayGetCell(g_HumanClassModelsHandle, classid)
	
	// No models registered yet?
	if (class_models == Invalid_Array)
	{
		class_models = ArrayCreate(32, 1)
		ArraySetCell(g_HumanClassModelsHandle, classid, class_models)
	}
	ArrayPushString(class_models, player_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "MODELS", class_models)
	
	return true;
}

public native_class_human_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every class
	new index, humanclass_name[32]
	for (index = 0; index < g_HumanClassCount; index++)
	{
		ArrayGetString(g_HumanClassRealName, index, humanclass_name, charsmax(humanclass_name))
		if (equali(real_name, humanclass_name))
		return index;
	}
	
	return ZP_INVALID_HUMAN_CLASS;
}

public native_class_human_get_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_HumanClassName, classid, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public _class_human_get_real_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_class_human_get_desc(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new description[32]
	ArrayGetString(g_HumanClassDesc, classid, description, charsmax(description))
	
	new len = get_param(3)
	set_string(2, description, len)
	return true;
}

public native_class_human_get_count(plugin_id, num_params)
{
	return g_HumanClassCount;
}

public native_class_human_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_humanclass(id)
	return true;
}

public _class_human_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}