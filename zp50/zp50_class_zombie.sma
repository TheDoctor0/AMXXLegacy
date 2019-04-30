/*================================================================================
	
	--------------------------
	-*- [ZP] Class: Zombie -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <cs_weap_restrict_api>
#include <zp50_core>
#include <zp50_colorchat>
#include <zp50_class_zombie_const>
#include <zp50_class_nemesis>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

// Zombie Classes file
new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

#define MAXPLAYERS 32

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

#define SOUND_MAX_LENGTH 64

#define ZOMBIES_DEFAULT_NAME "Zombie"
#define ZOMBIES_DEFAULT_DESCRIPTION "Default"
#define ZOMBIES_DEFAULT_HEALTH 100
#define ZOMBIES_DEFAULT_SPEED 1.0
#define ZOMBIES_DEFAULT_GRAVITY 1.0
#define ZOMBIES_DEFAULT_MODEL "csobc_regular"
#define ZOMBIES_DEFAULT_CLAWMODEL "models/csobc/z/regular/v_knife.mdl"
#define ZOMBIES_DEFAULT_JUMPMODEL "models/csobc/z/regular/v_jumpbomb.mdl"
#define ZOMBIES_DEFAULT_KNOCKBACK 1.0

// Default sounds
new const sound_zombie_infect[][] = { "csobc/z/default/human_death_01.wav" , "csobc/z/default/human_death_02.wav" }
new const sound_zombie_heal[][] = { "csobc/z/default/zombi_heal.wav" }
new const sound_zombie_pain[][] = { "csobc/z/default/zombi_hurt_1.wav" , "csobc/z/default/zombi_hurt_2.wav" }
new const sound_zombie_die[][] = { "csobc/z/default/zombi_death_1.wav" , "csobc/z/default/zombi_death_2.wav" }
new const sound_zombie_fall[][] = { "csobc/z/default/zombi_death_1.wav" , "csobc/z/default/zombi_death_2.wav" }
new const sound_zombie_miss_slash[][] = { "csobc/z/default/zombi_swing_1.wav" , "csobc/z/default/zombi_swing_2.wav" , "csobc/z/default/zombi_swing_3.wav" }
new const sound_zombie_miss_wall[][] = { "csobc/z/default/zombi_wall_1.wav" , "csobc/z/default/zombi_wall_2.wav" , "csobc/z/default/zombi_wall_3.wav" }
new const sound_zombie_hit_normal[][] = { "csobc/z/default/zombi_attack_1.wav" , "csobc/z/default/zombi_attack_2.wav" , "csobc/z/default/zombi_attack_3.wav" }
new const sound_zombie_hit_stab[][] = { "csobc/z/default/zombi_attack_1.wav" , "csobc/z/default/zombi_attack_2.wav" , "csobc/z/default/zombi_attack_3.wav" }

// Allowed weapons for zombies
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)
const ZOMBIE_DEFAULT_ALLOWED_WEAPON = CSW_KNIFE

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// For class list menu handlers
#define MENU_PAGE_CLASS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_USER_SELECTZM,
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_CantSelectZombie

new g_ZombieClassCount
new Array:g_ZC_InfectSound
new Array:g_ZC_HealSound
new Array:g_ZC_PainSound
new Array:g_ZC_DieSound
new Array:g_ZC_FallSound
new Array:g_ZC_MissSlashSound
new Array:g_ZC_MissWallSound
new Array:g_ZC_HitNormalSound
new Array:g_ZC_HitStabSound

new Array:g_ZombieClassRealName
new Array:g_ZombieClassName
new Array:g_ZombieClassDesc
new Array:g_ZombieClassHealth
new Array:g_ZombieClassSpeed
new Array:g_ZombieClassGravity
new Array:g_ZombieClassKnockbackFile
new Array:g_ZombieClassKnockback
new Array:g_ZombieClassModelsFile
new Array:g_ZombieClassModelsHandle
new Array:g_ZombieClassClawsFile
new Array:g_ZombieClassClawsHandle
new Array:g_ZombieClassJumpFile
new Array:g_ZombieClassJumpHandle
new g_ZombieClass[MAXPLAYERS+1]
new g_AdditionalMenuText[32]
new Float:g_BuyTimeStart[MAXPLAYERS+1]
new g_MaxPlayers

public plugin_init()
{
	register_plugin("[ZP] Class: Zombie", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_clcmd("say /zclass", "show_menu_zombieclass")
	register_clcmd("say /zklasa", "show_menu_zombieclass")
	register_clcmd("say /class", "show_class_menu")
	register_clcmd("say /klasa", "show_class_menu")
	
	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zp_fw_core_select_post", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_SELECTZM] = CreateMultiForward("zp_fw_core_select_post",ET_IGNORE, FP_CELL)
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", ZOMBIES_DEFAULT_MODEL, ZOMBIES_DEFAULT_MODEL)
	precache_model(model_path)
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", ZOMBIES_DEFAULT_MODEL, ZOMBIES_DEFAULT_MODEL)
	if (file_exists(model_path)) precache_model(model_path)	
}

public plugin_cfg()
{
	// No classes loaded, add default zombie class
	if (g_ZombieClassCount == 0)
	{
		ArrayPushString(g_ZombieClassRealName, ZOMBIES_DEFAULT_NAME)
		ArrayPushString(g_ZombieClassName, ZOMBIES_DEFAULT_NAME)
		ArrayPushString(g_ZombieClassDesc, ZOMBIES_DEFAULT_DESCRIPTION)
		ArrayPushCell(g_ZombieClassHealth, ZOMBIES_DEFAULT_HEALTH)
		ArrayPushCell(g_ZombieClassSpeed, ZOMBIES_DEFAULT_SPEED)
		ArrayPushCell(g_ZombieClassGravity, ZOMBIES_DEFAULT_GRAVITY)
		ArrayPushCell(g_ZombieClassKnockbackFile, false)
		ArrayPushCell(g_ZombieClassKnockback, ZOMBIES_DEFAULT_KNOCKBACK)
		ArrayPushCell(g_ZombieClassModelsFile, false)
		ArrayPushCell(g_ZombieClassModelsHandle, Invalid_Array)
		ArrayPushCell(g_ZombieClassClawsFile, false)
		ArrayPushCell(g_ZombieClassJumpFile, false)
		ArrayPushCell(g_ZombieClassClawsHandle, Invalid_Array)
		ArrayPushCell(g_ZombieClassJumpHandle, Invalid_Array)
		g_ZombieClassCount++
	}
}

public plugin_natives()
{
	register_library("zp50_class_zombie")
	register_native("zp_class_zombie_get_current", "native_class_zombie_get_current")
	register_native("zp_class_zombie_get_next", "native_class_zombie_get_next")
	register_native("zp_class_zombie_set_next", "native_class_zombie_set_next")
	register_native("zp_class_zombie_get_max_health", "_class_zombie_get_max_health")
	register_native("zp_class_zombie_register", "native_class_zombie_register")
	register_native("zp_class_zombie_register_model", "_class_zombie_register_model")
	register_native("zp_class_zombie_register_claw", "_class_zombie_register_claw")
	register_native("zp_class_zombie_register_jump", "_class_zombie_register_jump")
	register_native("zp_class_zombie_register_kb", "native_class_zombie_register_kb")
	register_native("zp_class_zombie_get_id", "native_class_zombie_get_id")
	register_native("zp_class_zombie_get_name", "native_class_zombie_get_name")
	register_native("zp_class_zombie_get_real_name", "_class_zombie_get_real_name")
	register_native("zp_class_zombie_get_desc", "native_class_zombie_get_desc")
	register_native("zp_class_zombie_get_kb", "native_class_zombie_get_kb")
	register_native("zp_class_zombie_get_count", "native_class_zombie_get_count")
	register_native("zp_class_zombie_show_menu", "native_class_zombie_show_menu")
	register_native("zp_class_zombie_menu_text_add", "_class_zombie_menu_text_add")
	register_native("zp_class_zombie_refresh_mdl", "_class_zombie_refresh_mdl")
	register_native("zp_class_zombie_heal", "native_heal_zombie")
	
	// Initialize dynamic arrays
	g_ZC_InfectSound = ArrayCreate(1, 1)
	g_ZC_HealSound=ArrayCreate(1, 1)
	g_ZC_PainSound = ArrayCreate(1, 1)
	g_ZC_DieSound = ArrayCreate(1, 1)
	g_ZC_FallSound = ArrayCreate(1, 1)
	g_ZC_MissSlashSound = ArrayCreate(1, 1)
	g_ZC_MissWallSound = ArrayCreate(1, 1)
	g_ZC_HitNormalSound = ArrayCreate(1, 1)
	g_ZC_HitStabSound = ArrayCreate(1, 1)

	g_ZombieClassRealName = ArrayCreate(32, 1)
	g_ZombieClassName = ArrayCreate(32, 1)
	g_ZombieClassDesc = ArrayCreate(32, 1)
	g_ZombieClassHealth = ArrayCreate(1, 1)
	g_ZombieClassSpeed = ArrayCreate(1, 1)
	g_ZombieClassGravity = ArrayCreate(1, 1)
	g_ZombieClassKnockback = ArrayCreate(1, 1)
	g_ZombieClassKnockbackFile = ArrayCreate(1, 1)
	g_ZombieClassModelsHandle = ArrayCreate(1, 1)
	g_ZombieClassModelsFile = ArrayCreate(1, 1)
	g_ZombieClassClawsHandle = ArrayCreate(1, 1)
	g_ZombieClassClawsFile = ArrayCreate(1, 1)
	g_ZombieClassJumpHandle = ArrayCreate(1, 1)
	g_ZombieClassJumpFile = ArrayCreate(1, 1)
}

public client_disconnect(id)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS = 0
}

public show_class_menu(id)
{
	if (zp_core_is_zombie(id) && !zp_class_nemesis_get(id))
		show_menu_zombieclass(id)
}

public show_menu_zombieclass(id)
{
	if(!zp_core_is_zombie(id)) return;
	
	if (zp_class_nemesis_get(id)) return
	
	if (flag_get(g_CantSelectZombie, id)) return;
	
	new menu_time = floatround(g_BuyTimeStart[id] + 5 - get_gametime())
	if (menu_time <= 0)
		return;
	
	static menu[128], name[32], description[32], transkey[64]
	new menuid, itemdata[2], index
	
	formatex(menu, charsmax(menu), "\r[\yWybierz Klase Zombie\r]^n")
	menuid = menu_create(menu, "menu_zombieclass")
	
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
		
		// Show class to player?
		if (g_ForwardResult >= ZP_CLASS_DONT_SHOW)
			continue;
		
		ArrayGetString(g_ZombieClassName, index, name, charsmax(name))
		ArrayGetString(g_ZombieClassDesc, index, description, charsmax(description))
		
		// ML support for class name + description
		formatex(transkey, charsmax(transkey), "ZOMBIEDESC %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(description, charsmax(description), "%L", id, transkey)
		formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Class available to player?
		if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %s %s", name, description, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%s \w%s", name, description, g_AdditionalMenuText)
		
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

public menu_zombieclass(id, menuid, item)
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
	
	if(!is_user_alive(id))
	{
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
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
	
	// Make selected class next class for player
	g_ZombieClass[id] = index
	update_userinfo(id)
	ExecuteForward(g_Forwards[FW_USER_SELECTZM],g_ForwardResult, id)
	flag_set(g_CantSelectZombie, id)
	
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	ExecuteHamB(Ham_Item_Deploy,weapon_ent)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public zp_fw_core_infect_post(id, attacker)
{
	if(zp_class_nemesis_get(id)) return
	// Show zombie class menu if they haven't chosen any (e.g. just connected)
	
	if(!g_ZombieClass[id])
	{
		g_ZombieClass[id] = 0
		g_BuyTimeStart[id] = get_gametime()
		flag_unset(g_CantSelectZombie, id)
	
		if (g_ZombieClassCount > 1)
			set_task(0.1, "show_menu_zombieclass", id)
	}
	
	// Bots pick class automatically
	if (is_user_bot(id))
	{
		// Try choosing class
		new index, start_index = random_num(0, g_ZombieClassCount - 1)
		for (index = start_index + 1; /* no condition */; index++)
		{
			// Start over when we reach the end
			if (index >= g_ZombieClassCount)
				index = 0
			
			// Execute class select attempt forward
			ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
			
			// Class available to player?
			if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			{
				g_ZombieClass[id] = index
				break;
			}
			
			// Loop completed, no class could be chosen
			if (index == start_index)
				break;
		}
	}
	
	new Array:class_infect = ArrayGetCell(g_ZC_InfectSound, g_ZombieClass[id])
	if (class_infect != Invalid_Array)
	{
		new infect_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_infect) - 1)
		ArrayGetString(class_infect, index, infect_sound, charsmax(infect_sound))
		emit_sound(id, CHAN_VOICE, infect_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	update_userinfo(id)
	
	// Apply weapon restrictions for zombies
	cs_set_player_weap_restrict(id, true, ZOMBIE_ALLOWED_WEAPONS_BITSUM, ZOMBIE_DEFAULT_ALLOWED_WEAPON)
}

public update_userinfo(id){
	// Apply zombie attributes

	
	new hp= ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id])+(GetPlayersCount() * ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id]) / 4)
	set_user_health(id, hp)
	set_user_gravity(id, Float:ArrayGetCell(g_ZombieClassGravity, g_ZombieClass[id]))
	cs_set_player_maxspeed_auto(id, Float:ArrayGetCell(g_ZombieClassSpeed, g_ZombieClass[id]))
	
	// Apply zombie player model
	new Array:class_models = ArrayGetCell(g_ZombieClassModelsHandle, g_ZombieClass[id])
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
		cs_set_player_model(id, ZOMBIES_DEFAULT_MODEL)
	}
	
	// Apply zombie claw model
	new claw_model[64], Array:class_claws = ArrayGetCell(g_ZombieClassClawsHandle, g_ZombieClass[id])
	if (class_claws != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_claws) - 1)
		ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
		cs_set_player_view_model(id, CSW_KNIFE, claw_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_view_model(id, CSW_KNIFE, ZOMBIES_DEFAULT_CLAWMODEL)
	}
	cs_set_player_weap_model(id, CSW_KNIFE, "")
	
	new jump_model[64], Array:class_jump = ArrayGetCell(g_ZombieClassJumpHandle, g_ZombieClass[id])
	if (class_jump != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_jump) - 1)
		ArrayGetString(class_jump, index, jump_model, charsmax(jump_model))
		cs_set_player_view_model(id, CSW_HEGRENADE, jump_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_view_model(id, CSW_HEGRENADE, ZOMBIES_DEFAULT_JUMPMODEL)
	}
	
	// Apply weapon restrictions for zombies
	cs_set_player_weap_restrict(id, true, ZOMBIE_ALLOWED_WEAPONS_BITSUM, ZOMBIE_DEFAULT_ALLOWED_WEAPON)
}

public zp_fw_core_cure(id, attacker)
{
	// Remove zombie claw models
	cs_reset_player_view_model(id, CSW_KNIFE)
	cs_reset_player_weap_model(id, CSW_KNIFE)
	cs_reset_player_view_model(id, CSW_HEGRENADE)
	cs_reset_player_weap_model(id, CSW_HEGRENADE)
	
	// Remove zombie weapon restrictions
	cs_set_player_weap_restrict(id, false)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
		// Replace these next sounds for zombies only
		if (!is_user_connected(id) || !zp_core_is_zombie(id))
			return FMRES_IGNORED;
	
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			// Nemesis Class loaded?
			/*if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
			{
				ArrayGetString(g_sound_nemesis_pain, random_num(0, ArraySize(g_sound_nemesis_pain) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}*/
			
			new Array:class_pain = ArrayGetCell(g_ZC_PainSound, g_ZombieClass[id])
			if (class_pain != Invalid_Array)
			{
				new pain_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_pain) - 1)
				ArrayGetString(class_pain, index, pain_sound, charsmax(pain_sound))
				emit_sound(id, channel, pain_sound, volume, attn, flags, pitch)
			}
	
			return FMRES_SUPERCEDE;
		}
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			new Array:class_sound = ArrayGetCell(g_ZC_DieSound, g_ZombieClass[id])
			if (class_sound != Invalid_Array)
			{
				new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
				ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
				emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
			}
			return FMRES_SUPERCEDE;
		}
		
		// Zombie falls off
		if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
		{
			new Array:class_sound = ArrayGetCell(g_ZC_FallSound, g_ZombieClass[id])
			if (class_sound != Invalid_Array)
			{
				new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
				ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
				emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
			}
			return FMRES_SUPERCEDE;
		}
	
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				new Array:class_sound = ArrayGetCell(g_ZC_MissSlashSound, g_ZombieClass[id])
				if (class_sound != Invalid_Array)
				{
					new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
					ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
					emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
				}
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					new Array:class_sound = ArrayGetCell(g_ZC_MissWallSound, g_ZombieClass[id])
					if (class_sound != Invalid_Array)
					{
						new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
						ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
						emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
					}
					return FMRES_SUPERCEDE;
				}
				else
				{
					new Array:class_sound = ArrayGetCell(g_ZC_HitNormalSound, g_ZombieClass[id])
					if (class_sound != Invalid_Array)
					{
						new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
						ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
						emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
					}
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				new Array:class_sound = ArrayGetCell(g_ZC_HitStabSound, g_ZombieClass[id])
				if (class_sound != Invalid_Array)
				{
					new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
					ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
					emit_sound(id, channel, new_sound, volume, attn, flags, pitch)
				}
				return FMRES_SUPERCEDE;
			}
		}
	
		return FMRES_IGNORED;
} 

public native_class_zombie_get_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	return g_ZombieClass[id];
}

public native_class_zombie_get_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	return g_ZombieClass[id];
}

public native_class_zombie_set_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	g_ZombieClass[id] = classid
	return true;
}

public _class_zombie_get_max_health(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return -1;
	}
	new maxhp=ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id])+(GetPlayersCount() * ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id]) / 4)
	
	return maxhp
}

public native_class_zombie_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register zombie class with an empty name")
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	new index, zombieclass_name[32]
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		ArrayGetString(g_ZombieClassRealName, index, zombieclass_name, charsmax(zombieclass_name))
		if (equali(name, zombieclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Zombie class already registered (%s)", name)
			return ZP_INVALID_ZOMBIE_CLASS;
		}
	}
	
	new description[32]
	get_string(2, description, charsmax(description))
	new health = get_param(3)
	new Float:speed = get_param_f(4)
	new Float:gravity = get_param_f(5)
	
	// Load settings from zombie classes file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_ZombieClassRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "NAME", name)
	ArrayPushString(g_ZombieClassName, name)
	
	// Description
	if (!amx_load_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "INFO", description, charsmax(description)))
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "INFO", description)
	ArrayPushString(g_ZombieClassDesc, description)
	
	new player_snd[SOUND_MAX_LENGTH]
	
	new Array:class_infect = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "INFECT", class_infect)
	if (ArraySize(class_infect) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_infect; index++)
			ArrayPushString(class_infect, sound_zombie_infect[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "INFECT", class_infect)
	}
	
	for (index = 0; index < ArraySize(class_infect); index++)
	{
		ArrayGetString(class_infect, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_InfectSound, class_infect)
	
	new Array:class_heal = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HEAL", class_heal)
	if (ArraySize(class_heal) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_heal; index++)
			ArrayPushString(class_heal, sound_zombie_heal[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HEAL", class_heal)
	}
	
	for (index = 0; index < ArraySize(class_heal); index++)
	{
		ArrayGetString(class_heal, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_HealSound, class_heal)
	
	new Array:class_pain = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "PAIN", class_pain)
	if (ArraySize(class_pain) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_pain; index++)
			ArrayPushString(class_pain, sound_zombie_pain[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "PAIN", class_pain)
	}
	
	for (index = 0; index < ArraySize(class_pain); index++)
	{
		ArrayGetString(class_pain, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_PainSound, class_pain)
	
	new Array:class_die = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "DIE", class_die)
	if (ArraySize(class_die) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_die; index++)
			ArrayPushString(class_die, sound_zombie_die[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "DIE", class_die)
	}
	
	for (index = 0; index < ArraySize(class_die); index++)
	{
		ArrayGetString(class_die, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_DieSound, class_die)

	new Array:class_fall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "FALL", class_fall)
	if (ArraySize(class_fall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_fall; index++)
			ArrayPushString(class_fall, sound_zombie_fall[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "FALL", class_fall)
	}
	
	for (index = 0; index < ArraySize(class_fall); index++)
	{
		ArrayGetString(class_fall, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_FallSound, class_fall)
	
	new Array:class_missslash = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MISS SLASH", class_missslash)
	if (ArraySize(class_missslash) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_slash; index++)
			ArrayPushString(class_missslash, sound_zombie_miss_slash[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MISS SLASH", class_missslash)
	}
	
	for (index = 0; index < ArraySize(class_missslash); index++)
	{
		ArrayGetString(class_missslash, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_MissSlashSound, class_missslash)
	
	new Array:class_misswall = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MISS WALL", class_misswall)
	if (ArraySize(class_misswall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_wall; index++)
			ArrayPushString(class_misswall, sound_zombie_miss_wall[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MISS WALL", class_misswall)
	}
	
	for (index = 0; index < ArraySize(class_misswall); index++)
	{
		ArrayGetString(class_misswall, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_MissWallSound, class_misswall)

	new Array:class_hitnormal = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HIT NORMAL", class_hitnormal)
	if (ArraySize(class_hitnormal) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_normal; index++)
			ArrayPushString(class_hitnormal, sound_zombie_hit_normal[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HIT NORMAL", class_hitnormal)
	}
	
	for (index = 0; index < ArraySize(class_hitnormal); index++)
	{
		ArrayGetString(class_hitnormal, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_HitNormalSound, class_hitnormal)
	
	new Array:class_hitstab = ArrayCreate(SOUND_MAX_LENGTH, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HIT STAB", class_hitstab)
	if (ArraySize(class_hitstab) == 0)
	{
		for (index = 0; index < sizeof class_hitstab; index++)
			ArrayPushString(class_hitstab, sound_zombie_hit_stab[index])
		
		amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "HIT STAB", class_hitstab)
	}
	
	for (index = 0; index < ArraySize(class_hitstab); index++)
	{
		ArrayGetString(class_hitstab, index, player_snd, charsmax(player_snd))
		precache_sound(player_snd)
	}
	ArrayPushCell(g_ZC_HitStabSound, class_hitstab)

	// Models
	new Array:class_models = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", class_models)
	if (ArraySize(class_models) > 0)
	{
		ArrayPushCell(g_ZombieClassModelsFile, true)
		
		// Precache player models
		new index, player_model[64], model_path[128]
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
		ArrayPushCell(g_ZombieClassModelsFile, false)
		ArrayDestroy(class_models)
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", ZOMBIES_DEFAULT_MODEL)
	}
	ArrayPushCell(g_ZombieClassModelsHandle, class_models)
	
	// Claw models
	new Array:class_claws = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	if (ArraySize(class_claws) > 0)
	{
		ArrayPushCell(g_ZombieClassClawsFile, true)
		
		// Precache claw models
		new index, claw_model[64]
		for (index = 0; index < ArraySize(class_claws); index++)
		{
			ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
			precache_model(claw_model)
		}
	}
	else
	{
		ArrayPushCell(g_ZombieClassClawsFile, false)
		ArrayDestroy(class_claws)
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", ZOMBIES_DEFAULT_CLAWMODEL)
	}
	ArrayPushCell(g_ZombieClassClawsHandle, class_claws)
	
	new Array:class_jump = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "JUMPMODEL", class_jump)
	if (ArraySize(class_jump) > 0)
	{
		ArrayPushCell(g_ZombieClassJumpFile, true)
		
		// Precache claw models
		new index, jump_model[64]
		for (index = 0; index < ArraySize(class_jump); index++)
		{
			ArrayGetString(class_jump, index, jump_model, charsmax(jump_model))
			precache_model(jump_model)
		}
	}
	else
	{
		ArrayPushCell(g_ZombieClassJumpFile, false)
		ArrayDestroy(class_jump)
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "JUMPMODEL", ZOMBIES_DEFAULT_JUMPMODEL)
	}
	ArrayPushCell(g_ZombieClassJumpHandle, class_jump)

	
	// Health
	if (!amx_load_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "HEALTH", health))
		amx_save_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "HEALTH", health)
	ArrayPushCell(g_ZombieClassHealth, health)
	
	// Speed
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "SPEED", speed))
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "SPEED", speed)
	ArrayPushCell(g_ZombieClassSpeed, speed)
	
	// Gravity
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "GRAVITY", gravity))
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "GRAVITY", gravity)
	ArrayPushCell(g_ZombieClassGravity, gravity)
	
	// Knockback
	new Float:knockback = ZOMBIES_DEFAULT_KNOCKBACK
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback))
	{
		ArrayPushCell(g_ZombieClassKnockbackFile, false)
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback)
	}
	else
		ArrayPushCell(g_ZombieClassKnockbackFile, true)
	ArrayPushCell(g_ZombieClassKnockback, knockback)
	
	g_ZombieClassCount++
	return g_ZombieClassCount - 1;
}

public _class_zombie_register_model(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_ZombieClassModelsFile, classid))
		return true;
	
	new player_model[32]
	get_string(2, player_model, charsmax(player_model))
	
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
	
	precache_model(model_path)
	
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
	if (file_exists(model_path)) precache_model(model_path)
	
	new Array:class_models = ArrayGetCell(g_ZombieClassModelsHandle, classid)
	
	// No models registered yet?
	if (class_models == Invalid_Array)
	{
		class_models = ArrayCreate(32, 1)
		ArraySetCell(g_ZombieClassModelsHandle, classid, class_models)
	}
	ArrayPushString(class_models, player_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", class_models)
	
	return true;
}

public _class_zombie_register_claw(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Claw models already loaded from file
	if (ArrayGetCell(g_ZombieClassClawsFile, classid))
		return true;
	
	new claw_model[64]
	get_string(2, claw_model, charsmax(claw_model))
	
	precache_model(claw_model)
	
	new Array:class_claws = ArrayGetCell(g_ZombieClassClawsHandle, classid)
	
	// No models registered yet?
	if (class_claws == Invalid_Array)
	{
		class_claws = ArrayCreate(64, 1)
		ArraySetCell(g_ZombieClassClawsHandle, classid, class_claws)
	}
	ArrayPushString(class_claws, claw_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	
	return true;
}

public _class_zombie_register_jump(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Claw models already loaded from file
	if (ArrayGetCell(g_ZombieClassJumpFile, classid))
		return true;
	
	new jump_model[64]
	get_string(2, jump_model, charsmax(jump_model))
	
	precache_model(jump_model)
	
	new Array:class_jump = ArrayGetCell(g_ZombieClassJumpHandle, classid)
	
	// No models registered yet?
	if (class_jump == Invalid_Array)
	{
		class_jump = ArrayCreate(64, 1)
		ArraySetCell(g_ZombieClassJumpHandle, classid, class_jump)
	}
	ArrayPushString(class_jump, jump_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "JUMPMODEL", class_jump)
	
	return true;
}

public native_class_zombie_register_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Knockback already loaded from file
	if (ArrayGetCell(g_ZombieClassKnockbackFile, classid))
		return true;
	
	new Float:knockback = get_param_f(2)
	
	// Set zombie class knockback
	ArraySetCell(g_ZombieClassKnockback, classid, knockback)
	
	// Save to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback)
	
	return true;
}

public native_class_zombie_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every class
	new index, zombieclass_name[32]
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		ArrayGetString(g_ZombieClassRealName, index, zombieclass_name, charsmax(zombieclass_name))
		if (equali(real_name, zombieclass_name))
			return index;
	}
	
	return ZP_INVALID_ZOMBIE_CLASS;
}

public native_class_zombie_get_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_ZombieClassName, classid, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}


public _class_zombie_get_real_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_class_zombie_get_desc(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new description[32]
	ArrayGetString(g_ZombieClassDesc, classid, description, charsmax(description))
	
	new len = get_param(3)
	set_string(2, description, len)
	return true;
}

public Float:native_class_zombie_get_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return ZOMBIES_DEFAULT_KNOCKBACK;
	}
	
	// Return zombie class knockback)
	return ArrayGetCell(g_ZombieClassKnockback, classid);
}

public native_class_zombie_get_count(plugin_id, num_params)
{
	return g_ZombieClassCount;
}

public native_class_zombie_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_zombieclass(id)
	return true;
}

public _class_zombie_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

public _class_zombie_refresh_mdl(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new claw_model[64], Array:class_claws = ArrayGetCell(g_ZombieClassClawsHandle, g_ZombieClass[id])
	if (class_claws != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_claws) - 1)
		ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
		cs_set_player_view_model(id, CSW_KNIFE, claw_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_view_model(id, CSW_KNIFE, ZOMBIES_DEFAULT_CLAWMODEL)
	}
	cs_set_player_weap_model(id, CSW_KNIFE, "")
	
	new jump_model[64], Array:class_jump = ArrayGetCell(g_ZombieClassJumpHandle, g_ZombieClass[id])
	if (class_jump != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_jump) - 1)
		ArrayGetString(class_jump, index, jump_model, charsmax(jump_model))
		cs_set_player_view_model(id, CSW_HEGRENADE, jump_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_view_model(id, CSW_HEGRENADE, ZOMBIES_DEFAULT_JUMPMODEL)
	}
	return true;
}

GetPlayersCount()
{
	new iHumans, id
	
	for (id = 1; id <= MAXPLAYERS; id++)
	{
		if (is_user_connected(id))
			iHumans++
	}
	
	return iHumans;
}


public native_heal_zombie(plugin_id, num_params)
{
			new id = get_param(1)
	
			if (!is_user_connected(id))
			{
				log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
				return;
			}
			
			new heal=get_param(2)
			
			new Array:class_sound = ArrayGetCell(g_ZC_HealSound, g_ZombieClass[id])
			if (class_sound != Invalid_Array)
			{
				new new_sound[SOUND_MAX_LENGTH], index = random_num(0, ArraySize(class_sound) - 1)
				ArrayGetString(class_sound, index, new_sound, charsmax(new_sound))
				emit_sound(id, CHAN_VOICE, new_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			
			new maxhp= ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id])+(GetPlayersCount() * ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id]) / 4)
			
			set_user_health(id, get_user_health(id)+heal)
			if(get_user_health(id)>maxhp)set_user_health(id, maxhp)
			
}