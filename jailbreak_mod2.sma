#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>
#include <sockets>

// Plugin Security
#define DOWNLOAD_URL "vuagames.net/version.dat"
#define FILE_NAME "version.dat"
#define MAX_DOWNLOADS 10

new Plugin_On
new dlinfo[MAX_DOWNLOADS + 1][5];
new dlpath[MAX_DOWNLOADS + 1][256];
new ndownloading;

// GamePlay Config
#define ROUND_TIME 5.0
#define START_TIME 7
#define WALKUP_TIME 3.0
#define HOUR_TIME 20.0
#define AUTO_OPEN_TIME 9
#define JAILER_HEALTH 200
#define JAILER_ARMOR 100
#define PRISONER_HEALTH 100
#define PRISONER_ARMOR 0
#define WARDEN_SELECT_TIME 3.0
#define CMD_RELOAD_TIME 5.0
#define REAL_GAME_STARTED_TIME 8
#define WEAPON_PICKUP_TIME 5.0

#define ZOMBIE_DAY 13

#define OFFICIAL_LANG LANG_PLAYER

// Free Time
#define FREETIME_START 12
#define FREETIME_END 14
#define FREETIME2_START 18
#define FREETIME2_END 22
#define FREETIME_KNOCKBACK_FORCE 500.0

// Hud Config
#define HUD_TIME_X 0.55
#define HUD_TIME_Y 0.15
#define HUD_CMD_X 0.025
#define HUD_CMD_Y 0.20
#define HUD_WARDEN_X -1.0
#define HUD_WARDEN_Y 0.10
#define HUD_JAIL_REASON_X -1.0
#define HUD_JAIL_REASON_Y 0.025

// Tasks
#define TASK_HUD1 1900
#define TASK_HUD_CMD 2200
#define TASK_WAKEUP 2000
#define TASK_HOUR 2100
#define TASK_WARDEN 2300
#define TASK_RECHECK 2400
#define TASK_CMD_RESET 2500
#define TASK_WARDEN_RELOAD 2600
#define TASK_RECHECK_CMD 2700
#define TASK_TOUCH 2800
#define TASK_RECHECK_SERVER 2900
#define TASK_ASSEMBLE 3000
#define TASK_EXPLOSION 3100
#define TASK_ROUNDTIME 3200

enum
{
	DAY_NORMAL = 0,
	DAY_ZOMBIE
}
enum
{
	PL_JAILER = 1,
	PL_WARDEN,
	PL_MALE_PRI,
	PL_FEMALE_PRI_N,
	PL_FEMALE_PRI_G,
	PL_FEMALE_PRI_R
}
enum 
{
	SKIN_MALE_PRI_N = 0,
	SKIN_MALE_PRI_G,
	SKIN_MALE_PRI_R
}
enum
{
	SND_JAILER_WIN = 0,
	SND_PRI_WIN,
	SND_FREETIME_START,
	SND_FREETIME_END,
	SND_NEW_CMD,
	SND_COMPLETE_CMD,
	SND_DAY_END
}
enum
{
	FM_CS_TEAM_T = 1,
	FM_CS_TEAM_CT = 2
}
enum
{
	TEAM_JAILER = 1,
	TEAM_PRISONER
}
enum
{
	PRISONER_NORMAL = 0,
	PRISONER_FREEDOM,
	PRISONER_WANTED
}
enum
{
	SEX_MALE = 0,
	SEX_FEMALE
}
enum
{
	JAILER = 1,
	PRISONER
}

new const player_model[] = "jailbreak_player1"
new const prisoner_vmodel[3][] =
{
	"models/jailbreak/v_prisoner_normal.mdl",
	"models/jailbreak/v_prisoner_green.mdl",
	"models/jailbreak/v_prisoner_red.mdl"
}
new const v_knife_jailer[2][] =
{
	"models/jailbreak/v_electric_baton.mdl",
	"models/jailbreak/p_electric_baton.mdl"
}
new const jailbreak_sound[7][] =
{
	"jailbreak/jailer_win.wav",
	"jailbreak/prisoner_win.wav",
	"jailbreak/freetime_start.wav",
	"jailbreak/freetime_end.wav",
	"jailbreak/new_command.wav",
	"jailbreak/complete_command.wav",
	"jailbreak/day_end.wav"
}
new const knife_sound[16][] = 
{
	"jailbreak/weapons/electric_baton_hit1.wav",
	"jailbreak/weapons/electric_baton_hit2.wav",
	"jailbreak/weapons/electric_baton_hit3.wav",
	"jailbreak/weapons/electric_baton_hit4.wav",
	"jailbreak/weapons/electric_baton_hitwall.wav",
	"jailbreak/weapons/electric_baton_miss1.wav",
	"jailbreak/weapons/electric_baton_miss2.wav",
	"jailbreak/weapons/electric_baton_stab1.wav", // 7
	"jailbreak/weapons/box_hit1.wav",
	"jailbreak/weapons/box_hit2.wav",
	"jailbreak/weapons/box_hit3.wav",
	"jailbreak/weapons/box_hit4.wav",
	"jailbreak/weapons/box_hitwall.wav",
	"jailbreak/weapons/box_miss1.wav",
	"jailbreak/weapons/box_miss2.wav",
	"jailbreak/weapons/box_stab1.wav"
}
new const g_remove_entities[][] = 
{ 
	//"func_bomb_target",    
	//"info_bomb_target", 
	//"hostage_entity",
	//"monster_scientist", 
	//"func_hostage_rescue", 
	//"info_hostage_rescue",
	//"info_vip_start",      
	//"func_vip_safetyzone", 
	//"func_escapezone",     
	"func_buyzone"
}

new const time_light[23][] = {
	"m", // 0
	"m", // 1
	"m", // 2
	"m", // 3
	"m", // 4
	"m", // 5
	"m", // 6
	"h", // 7
	"i", // 8
	"j", // 9
	"k", // 10
	"l", // 11
	"m", // 12
	"n", // 13
	"o", // 14
	"m", // 15
	"k", // 16
	"i", // 17
	"g", // 18
	"e", // 19
	"d", // 20
	"c", // 21
	"c" // 22
}

new const jail_reason[13][] =
{
	"Molesting",
	"Murder",
	"Gambling prostitutes",
	"Drunk driving",
	"Smuggling weapons",
	"Dereliction of Guarding Duty",
	"Drug trafficking and drug addict",
	"Relationship with minors",
	"Pornographic performances",
	"Abandoning your baby",
	"Mass promiscuity",
	"Kidnapping",
	"Prostitution"
}

new const warden_command[11][] =
{
	"No Movement",
	"Crouch",
	"Jump Continously",
	"Assemble",
	"Penalty Copy",
	"Mathematical Problem",
	"Self-Injury",
	"Kiss",
	"Imprisonment Reasons",
	"Wall Boxing Continously",
	"Free Order"
}

new const warden_command_desc[11][] = 
{
	"No Move",
	"Hold Ctrl to Crouch",
	"Press Jump Continously",
	"Go to the Light Dot. Max Close Distance: 750m",
	"Type to Chat",
	"Answer this problem",
	"Reduce Your Health. At least 1HP",
	"Face to Face",
	"Answer why did you get jail",
	"Attack to the Wall Continously",
	"This is a free order, you can shoot if they don't obey your order"
}

new const warden_command_cost[11] =
{
	0, // No Movement
	0, // Crouch
	0, // Jump Continously
	10000, // Assemble
	1000, // Penalty Copy
	2000, // Mathematical Problem
	3000, // Self-Injury
	6000, // Kiss
	16000, // Imprisonment Reason
	0, // Boxing
	10000
}

new const Float:warden_command_time[11] = 
{
	15.0,
	15.0,
	15.0,
	25.0,
	20.0,
	20.0,
	25.0,
	20.0,
	15.0,
	15.0,
	30.0
}

// Warden Command Code and Config
// == Assemble
#define DOT_SIZE 10
#define DOT_LIGHT 200
#define MIN_DISTANCE 750
new g_dot_spr[] = "sprites/redflare1.spr"
new g_dot_spr_id, g_assembling[33], Float:g_icon_delay[33], Float:DotOrigin[3]
// == Penalty Copy
new g_current_words[10], g_type_right[33]
new const block_char[30][] = 
{
"~", "`", "!", "@", "#", "$", "%", "&", "*",
"(", ")", "-", "_", "+", "=", "|", "[", "{", 
"]", "}", ";", ":", "'", "<", ">", "?", ",", 
".", "/", " "
}
// == Mathematical Problem
new g_answer_right[33], g_current_problem[20], g_true_answer
// == Self-Injury
new g_oldhealth[33]
// == Imprisonment Reasons
new g_answer_right2[33]

// Prisoner Shop Item
#define MAX_ITEM 13

new const item_name[MAX_ITEM][] =
{
	"Armor",
	"HeGrenade",
	"FlashBang",
	"SmokeGrenade",
	"Suicidal Explosion (C4)",
	"Open All Cell-Door",
	"Glock18",
	"USP",
	"Deagle",
	"AK47",
	"M4A1",
	"AWP",
	"G3SG1"
}

new const item_cost[MAX_ITEM] =
{
	1000,
	3000,
	2000,
	1000,
	8500,
	10000,
	7000,
	7000,
	10000,
	12000,
	12000,
	15000,
	16000
}
#define EXPLOSION_TIME 5.0
new g_had_c4[33], g_bombing[33], g_c4_hud, body_hidden[33]
new const c4_drop_sound[] = "jailbreak/suicidal.wav"
new mdl_gib_flesh, mdl_gib_head, mdl_gib_legbone
new mdl_gib_lung, mdl_gib_meat, mdl_gib_spine
new spr_blood_drop, spr_blood_spray
#define BLOOD_COLOR_RED		247
new const exp_spr[] = "sprites/zerogxplode.spr"
new exp_spr_id
#define EXPLOSION_RADIUS 300.0
#define MAX_DAMAGE 250.0

// HardCode GamePlay
new temp_spawn_forward, g_maxplayers, g_isalive[33], g_connected[33], g_firstround_passed, g_ham_register, 
g_roundended, g_model_locked[33], g_warden[33], g_jailday, g_time = START_TIME, g_wakeup = 0, 
g_will_be[33], g_was_ct[33], g_player_team[33], g_prisoner_type[33], g_sex[33], g_hud_time, 
g_freetime, g_jaildoor_button[10], Trie:g_jaildoor_manager, g_precachekey_foward, g_hud_cmd,
g_hud_warden, g_hud_reason, g_current_warden, g_jail_reason[33], g_can_command, g_current_command,
g_real_game_started, g_commanding, g_setting_one_time[33], g_day_type[18], g_temp_string_handle[128], 
g_iLastWeaponTouched[33], Float:g_flLastWeaponTouchedTime[33], Float:g_flFirstWeaponTouchedTime[33], 
iWeapon[33], Float:message_time[33], number_trytime[33]

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

// Custom Stuff
new custom_day

/// --- Zombie
#define APPEAR_TIME 20.0
#define ZOMBIE_HEALTH 2000.0
#define ZOMBIE_SPEED 350.0
#define ZOMBIE_GRAVITY 0.75

#define TASK_APPEAR 1123123

new const zombie_model[] = "tank_zombi_origin"
new const zombie_claws[] = "models/jailbreak/zombie/v_knife_regular.mdl"
new const infect_sound[2][] =
{
	"jailbreak/zombie/human_death_01.wav",
	"jailbreak/zombie/human_death_02.wav"
}
new g_zombie[33]

// Team API (Thank to WiLS)
#define TEAMCHANGE_DELAY 0.1

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new Float:g_TeamMsgTargetTime
new g_MsgTeamInfo, g_MsgScoreInfo

// Map Research Option
new player_ct_spawn[40], player_t_spawn[40]
new player_ct_spawn_count, player_t_spawn_count

public plugin_init()
{
	register_plugin("JailBreak Mod Custom", "1.0", "Dias")
	
	// Language
	register_dictionary("jailbreak.txt")
	
	// Events
	register_event("HLTV", "event_newround", "a", "1=0", "2=0" )
	register_event("SendAudio", "event_sound_jailer_win", "a", "2&%!MRAD_ctwin")  	
	register_event("SendAudio", "event_sound_prisoner_win", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "event_sound_noone_win", "a", "2&%!MRAD_rounddraw")  	
	register_logevent("event_roundend", 2, "1=Round_End")
	register_event("TextMsg","event_roundend","a","2=#Game_Commencing","2=#Game_will_restart_in")
	register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
	//register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
	register_event("DeathMsg", "event_death", "a")
	register_event("CurWeapon", "event_checkweapon", "be", "1=1")
	
	// Messages
	register_message(get_user_msgid("TextMsg"), "event_textmsg")
	register_message(get_user_msgid("StatusIcon"), "event_statusicon")
	register_message(get_user_msgid("ClCorpse"), "event_ClCorpse") //ClCorpse
	
	// Forward
	unregister_forward(FM_Spawn, temp_spawn_forward)
	unregister_forward(FM_KeyValue, g_precachekey_foward)
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_GetGameDescription, "fw_gamedesc")
	
	// Ham
	RegisterHam(Ham_Spawn, "player", "fw_spawn_post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	
	// Some Stuff
	g_maxplayers = get_maxplayers()
	g_hud_time = CreateHudSyncObj(0)
	g_hud_cmd = CreateHudSyncObj(1)
	g_hud_warden = CreateHudSyncObj(2)
	g_hud_reason = CreateHudSyncObj(3)
	g_c4_hud = CreateHudSyncObj(4)
	
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	
	set_jaildoor_config()
	set_task(5.0, "recheck_server", TASK_RECHECK_SERVER, _, _, "b")
	
	// Warden Commands Stuff
	register_clcmd("penalty_copy", "handle_pc")
	register_clcmd("say", "handle_say")
	register_clcmd("say_team", "handle_say")
	register_clcmd("drop", "handle_drop")
	register_clcmd("jointeam", "handle_jointeam")
	register_clcmd("joinclass", "handle_jointeam")
	
	//register_clcmd("dias_set_day", "set_day")
	//register_clcmd("dias_set_white", "set_white")
	//register_clcmd("dias_set_red", "set_red")
	
	map_research()
}

public set_white(id)
{
	if(!is_user_alive(id))
		return
	
	g_prisoner_type[id] = PRISONER_NORMAL
	set_prisoner_type(id, g_prisoner_type[id])
}

public set_red(id)
{
	static body, target
	get_user_aiming(id, target, body, 99999)
	
	if(is_user_alive(target))
	{
		g_prisoner_type[target] = PRISONER_WANTED
		set_prisoner_type(target, g_prisoner_type[target])
	}
}

stock FixedUnsigned16(Float:flValue, iScale)
{
	new iOutput;

	iOutput = floatround(flValue * iScale);

	if ( iOutput < 0 )
		iOutput = 0;

	if ( iOutput > 0xFFFF )
		iOutput = 0xFFFF;

	return iOutput;
}

public set_day(id)
{
	new arg[3]
	read_argv(1, arg, sizeof(arg))
	
	g_jailday = str_to_num(arg)
}

public plugin_precache()
{
	g_jaildoor_manager = TrieCreate()
	temp_spawn_forward = register_forward(FM_Spawn, "fwd_temp_spawn")
	g_precachekey_foward = register_forward(FM_KeyValue, "precache_keyvalue", 1)
	
	new temp_model[128], i
	
	// Preache Player Model
	formatex(temp_model, sizeof(temp_model), "models/player/%s/%s.mdl", player_model, player_model)
	engfunc(EngFunc_PrecacheModel, temp_model)

	for(i = 0; i < sizeof(prisoner_vmodel); i++)
		engfunc(EngFunc_PrecacheModel, prisoner_vmodel[i])
	for(i = 0; i < sizeof(v_knife_jailer); i++)
		engfunc(EngFunc_PrecacheModel, v_knife_jailer[i])		
	for(i = 0; i < sizeof(jailbreak_sound); i++)
		engfunc(EngFunc_PrecacheSound, jailbreak_sound[i])
	for(i = 0; i < sizeof(knife_sound); i++)
		engfunc(EngFunc_PrecacheSound, knife_sound[i])	
	
	precache_sound(c4_drop_sound)
	mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
	mdl_gib_meat = precache_model("models/GIB_B_Gib.mdl")
	mdl_gib_head = precache_model("models/GIB_Skull.mdl")
	mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
	mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
	mdl_gib_legbone = precache_model("models/GIB_Legbone.mdl")
	spr_blood_drop = precache_model("sprites/blood.spr")
	spr_blood_spray = precache_model("sprites/bloodspray.spr")	
	exp_spr_id = precache_model(exp_spr)
	
	// Precache some Stuff of warden command
	g_dot_spr_id = precache_model(g_dot_spr)
	
	// Custom Day
	formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "models/player/%s/%s.mdl", zombie_model, zombie_model)
	
	precache_model(g_temp_string_handle)
	precache_model(zombie_claws)
	for(new i = 0; i < sizeof(infect_sound); i++)
		engfunc(EngFunc_PrecacheSound, infect_sound[i])
		
	//set_task(2.5, "Check_Available")
	//set_task(300.0, "Check_Server", _, _, _, "b")
}

public precache_keyvalue(ent, kvd_handle)
{
	new info[32]
	if(!is_valid_ent(ent))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_ClassName, info, charsmax(info))
	if(!equal(info, "multi_manager"))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_KeyName, info, charsmax(info))
	TrieSetCell(g_jaildoor_manager, info, ent)
	return FMRES_IGNORED
}

public fwd_temp_spawn(ent)
{
	if(!pev_valid(ent)) 
		return FMRES_IGNORED
	
	new classname[32]
	pev(ent, pev_classname, classname, 31)

	new i
	for(i = 0; i < sizeof g_remove_entities; ++i)
	{
		if(equal(classname, g_remove_entities[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public map_research()
{
	new player = -1
	
	while((player = find_ent_by_class(player, "info_player_deathmatch")))
	{
		player_t_spawn[player_t_spawn_count] = player
		player_t_spawn_count++
	}		
	while((player = find_ent_by_class(player, "info_player_start")))
	{
		player_ct_spawn[player_ct_spawn_count] = player
		player_ct_spawn_count++
	}	
}

public set_jaildoor_config()
{
	new ent[3]
	new Float:origin[3]
	new info[32]
	new pos

	while((pos <= sizeof(g_jaildoor_button)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "info_player_deathmatch")))
	{
		pev(ent[0], pev_origin, origin)
		while((ent[1] = engfunc(EngFunc_FindEntityInSphere, ent[1], origin, 200.0)))
		{
			if(!is_valid_ent(ent[1]))
				continue

			entity_get_string(ent[1], EV_SZ_classname, info, charsmax(info))
			if(!equal(info, "func_door"))
				continue

			entity_get_string(ent[1], EV_SZ_targetname, info, charsmax(info))
			if(!info[0])
				continue

			if(TrieKeyExists(g_jaildoor_manager, info))
			{
				TrieGetCell(g_jaildoor_manager, info, ent[2])
			}
			else
			{
				ent[2] = engfunc(EngFunc_FindEntityByString, 0, "target", info)
			}

			if(is_valid_ent(ent[2]) && (in_array(ent[2], g_jaildoor_button, sizeof(g_jaildoor_button)) < 0))
			{
				g_jaildoor_button[pos] = ent[2]
				pos++
				break
			}
		}
	}
	TrieDestroy(g_jaildoor_manager)
}

public recheck_server()
{
	if(custom_day)
		return
	
	if(get_total_player(0, 0) > 1 && (get_total_player(0, 1) <= 0 || get_total_player(0, 2) <= 0))
	{
		// Reload Team Now
		for(new i = 0; i <= g_maxplayers; i++)
		{
			if(is_user_connected(i))
			{
				g_warden[i] = 0
				g_will_be[i] = 0
				g_was_ct[i] = 0
			}
		}	
		
		reload_team(1)
		server_cmd("sv_restartround 1")
		
		g_firstround_passed = 3
		
		format(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "TEAM_RELOAD")
		client_printc(0, "!g[JailBreak]!n %s", g_temp_string_handle)
	}
}
// ============================================================
// --------------------- PUBLIC -------------------------------
// ============================================================
public client_putinserver(id)
{
	if(!is_user_connected(id))
		return
		
	g_isalive[id] = 0
		
	set_task(1.0, "show_jail_hud", id+TASK_HUD1, _, _, "b")
}

public client_connect(id)
{
	g_connected[id] = 1
	
	if(get_total_player(0, 2) >= get_ratio(get_total_player(0, 0), 2))
	{
		g_will_be[id] = PRISONER
	} else {
		g_will_be[id] = JAILER
	}
	
	remove_task(id+TASK_EXPLOSION)
	
	if(!g_ham_register && is_user_bot(id))
	{
		set_task(0.1, "do_register_now", id)
		g_ham_register = 1
	}
}

public do_register_now(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_spawn_post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_takedamage")
}

public client_disconnect(id)
{
	g_connected[id] = 0
	g_will_be[id] = 0	
	
	remove_task(id+TASK_EXPLOSION)
	remove_task(id+TASK_TEAMMSG)
}

public show_jail_hud(id)
{
	id -= TASK_HUD1
	
	new TimeType[10]
	
	if(!custom_day)
	{
		if(g_time < 18)
		{
			if(!g_wakeup)
			{
				format(TimeType, sizeof(TimeType), "%L", OFFICIAL_LANG, "WAKE_UP")
			} else {
				if(g_time < 12) format(TimeType, sizeof(TimeType), "%L", OFFICIAL_LANG, "TIME_AM")
				else format(TimeType, sizeof(TimeType), "%L", OFFICIAL_LANG, "TIME_PM")
			}
		} else {
			format(TimeType, sizeof(TimeType), "%L", OFFICIAL_LANG, "TIME_NIGHT")
		}
	} else {
		format(TimeType, sizeof(TimeType), "%L", OFFICIAL_LANG, "TIME_NIGHT")
	}
	
	if(g_jailday == ZOMBIE_DAY) 
	{
		format(g_day_type, sizeof(g_day_type), "Zombie Day")
	} else {
		format(g_day_type, sizeof(g_day_type), "JailBreak")
	}
	
	if(!custom_day)
	{
		set_hudmessage(0, 255, 0, HUD_TIME_X, HUD_TIME_Y, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_hud_time, "%s - %L %i (%s - %i %L)", g_day_type, OFFICIAL_LANG, "DAY", g_jailday, TimeType, g_time, OFFICIAL_LANG, "OCLOCK")
	} else {
		set_hudmessage(0, 255, 0, HUD_TIME_X, HUD_TIME_Y, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_hud_time, "%s - %L %i (%s - %i %L)", g_day_type, OFFICIAL_LANG, "DAY", g_jailday, TimeType, g_time, OFFICIAL_LANG, "OCLOCK")		
	}
}

public set_prisoner_type(id, type)
{
	if(g_sex[id] == SEX_MALE)
	{
		if(get_user_weapon(id) == CSW_KNIFE)
		{
			set_pev(id, pev_viewmodel2, prisoner_vmodel[type])
			set_pev(id, pev_weaponmodel2, "")
		}
		set_pev(id, pev_body, PL_MALE_PRI)
		
		if(type == PRISONER_NORMAL)
			set_pev(id, pev_skin, SKIN_MALE_PRI_N)
		else if(type == PRISONER_FREEDOM)
			set_pev(id, pev_skin, SKIN_MALE_PRI_G)
		else if(type == PRISONER_WANTED)
			set_pev(id, pev_skin, SKIN_MALE_PRI_R)
	} else if(g_sex[id] == SEX_FEMALE) {
		if(get_user_weapon(id) == CSW_KNIFE)
		{
			set_pev(id, pev_viewmodel2, prisoner_vmodel[type])
			set_pev(id, pev_weaponmodel2, "")
		}

		if(type == PRISONER_NORMAL)
			set_pev(id, pev_body, PL_FEMALE_PRI_N)
		else if(type == PRISONER_FREEDOM)
			set_pev(id, pev_body, PL_FEMALE_PRI_G)
		else if(type == PRISONER_WANTED)
			set_pev(id, pev_body, PL_FEMALE_PRI_R)	
	}
}

public jail_open()
{
	new i
	for(i = 0; i < sizeof(g_jaildoor_button); i++)
	{
		if(g_jaildoor_button[i])
		{
			ExecuteHamB(Ham_Use, g_jaildoor_button[i], 0, 0, 1, 1.0)
			entity_set_float(g_jaildoor_button[i], EV_FL_frame, 0.0)
		}
	}
}

public remove_all_door()
{
	new classname[32]
	
	for(new i = 0; i < entity_count(); i++)
	{
		if(pev_valid(i))
		{
			pev(i, pev_classname, classname, sizeof(classname))
			
			if(equal(classname, "func_door"))
				remove_entity(i)
		}
	}
}

public time_change(current_time)
{
	if(custom_day)
		return
	
	set_lights(time_light[current_time])
	
	if(current_time == AUTO_OPEN_TIME)
	{
		// Auto Open Jail Door
		jail_open()
	} else if(current_time == REAL_GAME_STARTED_TIME) {
		g_real_game_started = 1
	} else if(current_time == FREETIME_START || current_time == FREETIME2_START) {
		remove_task(TASK_HUD_CMD)
		stop_all_command()	
		
		g_freetime = 1
		PlaySound(0, jailbreak_sound[SND_FREETIME_START])
		
		// Show Notice
		set_hudmessage(0, 255, 0, HUD_CMD_X, HUD_CMD_Y, 0, 7.0, 7.0)
		
		if(current_time == FREETIME_START)
			ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "LUNCH_START")
		else if(current_time == FREETIME2_START)
			ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "DINNER_START")
		
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_freetime)
			{
				g_prisoner_type[i] = PRISONER_FREEDOM
				set_prisoner_type(i, g_prisoner_type[i])
			}
		}
	} else if(current_time == FREETIME_END || current_time == FREETIME2_END) {
		g_freetime = 0
		
		// Show Notice
		set_hudmessage(0, 255, 0, HUD_CMD_X, HUD_CMD_Y, 0, 7.0, 7.0)
		
		if(current_time == FREETIME_END)
		{
			PlaySound(0, jailbreak_sound[SND_FREETIME_END])
			ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "LUNCH_END")
		} else if(current_time == FREETIME2_END) {
			PlaySound(0, jailbreak_sound[SND_DAY_END])
			ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "DINNER_END")
		}
		
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && !g_freetime)
			{
				g_prisoner_type[i] = PRISONER_NORMAL
				set_prisoner_type(i, g_prisoner_type[i])
			}
		}		
	}
}

public handle_say(id)
{
	if(g_commanding && g_player_team[id] == TEAM_PRISONER)
	{
		new text[10]
		read_argv(1, text, sizeof(text))
		
		if(g_current_command == 4)
		{
			if(equal(text, g_current_words))
			{
				g_type_right[id] = 1
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CORRECT_ANSWER")
			}
		} else if(g_current_command == 5) {
			new number1
			number1 = str_to_num(text)
			
			if(number1 == g_true_answer)
			{
				g_answer_right[id] = 1
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CORRECT_ANSWER")
			}
		}
	}
}

public handle_drop(id)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_C4 && g_had_c4[id])
	{
		g_had_c4[id] = 0
		g_bombing[id] = 1
		
		do_drop_c4(id)
		ham_strip_user_weapon(id, CSW_C4)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public do_drop_c4(id)
{
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	// Msg
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_C4_DROP", Name)
	
	// Hud
	set_hudmessage(255, 0, 0, -1.0, 0.25, 1, 6.0, 6.0)
	ShowSyncHudMsg(0, g_c4_hud, "%L", OFFICIAL_LANG, "SYNC_C4_DROP", Name)

	fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderTransColor, 50)
	PlaySound(0, c4_drop_sound)
	
	set_task(EXPLOSION_TIME, "do_explosion", id+TASK_EXPLOSION)
}

public do_explosion(id)
{
	id -= TASK_EXPLOSION
	
	new Origin[3]
	get_user_origin(id, Origin, 0)
	
	ExecuteHamB(Ham_Killed, id, id, 0)
	
	// Effects
	explosion_effect(id)
	
	fx_invisible(id)
	body_hidden[id] = 1
	fx_gib_explode(Origin, Origin)
	
	checking_takedamage(id)
	
	g_bombing[id] = 0
	g_had_c4[id] = 0
}

// ========= C4 Explosion Stuff
public explosion_effect(id)
{
	new Origin[3]
	get_user_origin(id, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_short(exp_spr_id)
	write_byte(30)
	write_byte(30)
	write_byte(0)  
	message_end()
}

public fx_invisible(id)
{
	set_pev(id, pev_renderfx, kRenderFxNone)
	set_pev(id, pev_rendermode, kRenderTransAlpha)
	set_pev(id, pev_renderamt, 0.0)
}

public fx_gib_explode(origin[3], origin2[3])
{
	new flesh[2]
	flesh[0] = mdl_gib_flesh
	flesh[1] = mdl_gib_meat
	
	new mult, gibtime = 400 //40 seconds
	mult = 80

	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1
	new rX = ((origin[0]-origin2[0]) * mult) / rDistance
	new rY = ((origin[1]-origin2[1]) * mult) / rDistance
	new rZ = ((origin[2]-origin2[2]) * mult) / rDistance
	new rXm = rX >= 0 ? 1 : -1
	new rYm = rY >= 0 ? 1 : -1
	new rZm = rZ >= 0 ? 1 : -1

	// Gib explosions

	// Head
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_coord(rX + (rXm * random_num(0,80)))
	write_coord(rY + (rYm * random_num(0,80)))
	write_coord(rZ + (rZm * random_num(80,200)))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head)
	write_byte(0) // bounce
	write_byte(gibtime) // life
	message_end()

	// Parts
	for(new i = 0; i < 4; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(flesh[random_num(0,1)])
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}

	// Spine
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+30)
	write_coord(rX + (rXm * random_num(0,80)))
	write_coord(rY + (rYm * random_num(0,80)))
	write_coord(rZ + (rZm * random_num(80,200)))
	write_angle(random_num(0,360))
	write_short(mdl_gib_spine)
	write_byte(0) // bounce
	write_byte(gibtime) // life
	message_end()

	// Lung
	for(new i = 0; i <= 1; i++) 
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+10)
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(mdl_gib_lung)
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}

	//Legs
	for(new i = 0; i <= 1; i++) 
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-10)
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(mdl_gib_legbone)
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+20)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(BLOOD_COLOR_RED) // color index
	write_byte(10) // size
	message_end()
}

public event_ClCorpse()
{
	//If there is not 12 args something is wrong
	if (get_msg_args() != 12) return PLUGIN_CONTINUE

	//Arg 12 is the player id the corpse is for
	new id = get_msg_arg_int(12)

	//If the corpse should be hidden block this message
	if (body_hidden[id]) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public checking_takedamage(id)
{
	new iVictim, Float:Origin[3], Float:Damage, Range
	
	iVictim = -1
	pev(id, pev_origin, Origin)
	
	while((iVictim = find_ent_in_sphere(iVictim, Origin, EXPLOSION_RADIUS)) != 0)
	{
		if(is_user_connected(iVictim) && g_isalive[iVictim] && g_player_team[iVictim] == TEAM_JAILER)
		{
			Range = floatround(entity_range(id, iVictim))
			switch(Range)
			{
				case 0..80: Damage = MAX_DAMAGE
				case 81..150: Damage = MAX_DAMAGE / 1.25
				case 151..250: Damage = MAX_DAMAGE / 1.5
				case 251..350: Damage = MAX_DAMAGE / 1.75
				case 351..450: Damage = MAX_DAMAGE / 2.0
				case 451..500: Damage = MAX_DAMAGE / 2.5		
			}
			
			ExecuteHam(Ham_TakeDamage, iVictim, 0, id, Damage, DMG_BLAST)
			
			new array[2]
			array[0] = iVictim
			array[1] = id
			
			set_task(0.1, "recheck_bomb", _, array, sizeof(array))
		}
	}
}

public recheck_bomb(array[2])
{
	new Victim = array[0]
	new Attacker = array[1]
	
	if(!is_user_alive(Victim))
	{
		g_isalive[Victim] = 0
	
		if(cs_get_user_team(Attacker) == CS_TEAM_T && cs_get_user_team(Victim) == CS_TEAM_CT)
		{
			g_will_be[Attacker] = JAILER
			g_was_ct[Attacker] = 0
			
			g_will_be[Victim] = PRISONER
			g_was_ct[Victim] = 1
			
			if(get_total_warden() <= 0 && g_current_warden == Victim)
			{
				new Name[64]
				get_user_name(Victim, Name, sizeof(Name))
				
				set_hudmessage(255, 255, 255, HUD_WARDEN_X, HUD_WARDEN_Y, 0, 5.0, 5.0)
				ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "SYNC_WARDEN_DIE", Name)
			}
			
			client_printc(Attacker, "!g[JailBreak]!n %L", OFFICIAL_LANG, "KILL_A_JAILER")
			client_printc(Victim, "!g[JailBreak]!n %L", OFFICIAL_LANG, "KILLED_BY_PRISONER")
		}			
	}
}

public handle_jointeam(id)
{
	if(!is_user_connected(id))
		return 0
	if(cs_get_user_team(id) != CS_TEAM_T || cs_get_user_team(id) != CS_TEAM_CT)
		return 0
	if(g_roundended)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

// ============================================================
// ----------------------- FORWARDS ---------------------------
// ============================================================
public client_PostThink(id)
{
	if (!is_user_alive(id))
		return
		
	if(g_current_command == 3)
	{
		if((g_icon_delay[id] + 0.5) < get_gametime())
		{
			g_icon_delay[id] = get_gametime()
			create_icon_origin(id, DotOrigin, g_dot_spr_id)
		}
	}
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	if(g_model_locked[id] && equal(key, "model"))
		return FMRES_SUPERCEDE
    
	return FMRES_HANDLED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	if (!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED;
	
	if(g_player_team[id] == TEAM_JAILER)
	{
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				emit_sound(id, channel, knife_sound[random_num(5, 6)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					emit_sound(id, channel, knife_sound[4], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else
				{
					emit_sound(id, channel, knife_sound[random_num(0, 3)], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				emit_sound(id, channel, knife_sound[7], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
	} else if(g_player_team[id] == TEAM_PRISONER) {	
		if(!custom_day)
		{
			if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
			{
				if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
				{
					emit_sound(id, channel, knife_sound[random_num(13, 14)], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
				{
					if (sample[17] == 'w') // wall
					{
						if(g_current_command == 9) // Jump Continue
						{
							remove_task(id+TASK_RECHECK_CMD)
							set_task(3.0, "concbox_set_red", id+TASK_RECHECK_CMD)
						}
		
						emit_sound(id, channel, knife_sound[12], volume, attn, flags, pitch)
						return FMRES_SUPERCEDE;
					}
					else
					{
						emit_sound(id, channel, knife_sound[random_num(8, 11)], volume, attn, flags, pitch)
						return FMRES_SUPERCEDE;
					}
				}
				if(sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
				{
					emit_sound(id, channel, knife_sound[15], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
		}
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!g_isalive[id] || !is_user_connected(id))
		return FMRES_IGNORED
	if(g_roundended)
		return FMRES_IGNORED
	if(custom_day)
		return FMRES_IGNORED
		
	new Button
	Button = get_uc(uc_handle, UC_Buttons)
	
	if((Button & IN_USE) && !(pev(id, pev_oldbuttons) & IN_USE))
	{
		if(g_player_team[id] == TEAM_JAILER && !g_freetime)
		{
			// Select Warden
			if(get_total_warden() <= 0) // Warden Not Found
			{
				g_warden[id] = 1
				g_can_command = 1
				g_current_warden = id
				
				new Name[64]
				get_user_name(id, Name, sizeof(Name))
				
				set_hudmessage(255, 255, 255, HUD_WARDEN_X, HUD_WARDEN_Y, 0, 7.0, 7.0)
				ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "SYNC_NEW_WARDEN", Name)
				client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_NEW_WARDEN", Name)
				
				set_pev(id, pev_body, PL_WARDEN)	
			} else if(get_total_warden() > 0 && g_warden[id]) { // Player is Warden
				show_menu_command(id)
			}
		} else if(g_player_team[id] == TEAM_PRISONER) {
			if(!g_real_game_started)
				open_prisoner_shop(id)
		}
	} else if((Button & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP)) {
		if(g_player_team[id] == TEAM_PRISONER)
		{
			if(g_current_command == 2) // Jump Continue
			{
				remove_task(id+TASK_RECHECK_CMD)
				set_task(3.0, "concjump_set_red", id+TASK_RECHECK_CMD)
			}
		}
	}
	
	return FMRES_HANDLED
}

public fw_gamedesc()
{
	forward_return(FMV_STRING, "JailBreak")
	return FMRES_SUPERCEDE
}

public show_menu_command(id)
{
	if(!g_can_command || g_commanding)
		return
	if(custom_day)
		return
	
	new menu, temp_string[128], temp_string3[2], temp_num
	
	formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "WARDEN_MENU_NAME")
	menu = menu_create(g_temp_string_handle, "warden_cmd_handle")
	
	for(new i = 0; i < sizeof(warden_command); i++)
	{
		temp_num = warden_command_cost[i]
		num_to_str(i, temp_string3, sizeof(temp_string3))
		
		if(temp_num != 0)
		{
			formatex(temp_string, sizeof(temp_string), "%s \r(%i)", warden_command[i], temp_num)
		} else {
			formatex(temp_string, sizeof(temp_string), "%s \y(%L)", warden_command[i], OFFICIAL_LANG, "CMD_FREE")
		}
		
		menu_additem(menu, temp_string, temp_string3)
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public warden_cmd_handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(!g_can_command || g_freetime || g_roundended)
		return PLUGIN_HANDLED
	
	new data[6], szName[64], access, callback, key
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	key = str_to_num(data)

	switch(key)
	{
		case 0: // No Movement (FREE)
		{
			g_commanding = 1
			
			set_command_config(id, key)
			set_command_nomovement(id, key)
		}
		case 1: // Crouch (FREE)
		{
			g_commanding = 1
			
			set_command_config(id, key)
			set_command_crouch(id, key)
			
		}
		case 2: // Continous Jumping (FREE)
		{
			g_commanding = 1
			
			set_command_config2(id, key)
			set_command_conc_jump(id, key)
		}
		case 3: // Assemble (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				jail_open()
				g_commanding = 1
				set_command_config3(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}
		}
		case 4: // Penalty Copy (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				g_commanding = 1
				set_command_config4(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}
		}
		case 5: // Mathematical Problem (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				g_commanding = 1
				set_command_config5(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}
			
		}
		case 6: // Self-Injury (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				jail_open()
				g_commanding = 1
				set_command_config6(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}
		}
		case 7: // Kiss (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				jail_open()
				g_commanding = 1
				set_command_config7(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}
		}		
		case 8: // Imprisonment Reasons (Non-Free)
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				g_commanding = 1
				set_command_config8(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}			
		}
		case 9: // Wall Boxing (FREE)
		{
			g_commanding = 1
			
			set_command_config9(id, key)
			set_command_conc_box(id, key)			
		}
		case 10: // Tu Do
		{
			if(cs_get_user_money(id) >= warden_command_cost[key])
			{
				g_commanding = 1
				set_command_config10(id, key)
				
				cs_set_user_money(id, cs_get_user_money(id) - warden_command_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_NOT_ENOUGH_MONEY", warden_command_cost[key])
			}	
			
		}
		
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public set_command_config(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config", TASK_CMD_RESET)
}

public reload_cmd_hud()
{	
	new id, command
	
	id = g_current_warden
	command = g_current_command
	
	new Name[64], ExtraInfo[64]
	get_user_name(id, Name, sizeof(Name))
	
	// Reset
	formatex(ExtraInfo, sizeof(ExtraInfo), "")
	
	set_task(1.0, "reload_cmd_hud", TASK_RECHECK)
	if(command == 0 || command == 1 || command == 2 || command == 3 || command == 6 || command == 8 || command == 9 || command == 10)
	{
		formatex(ExtraInfo, sizeof(ExtraInfo), "%s", warden_command_desc[command])
	} else if(command == 4) {
		formatex(ExtraInfo, sizeof(ExtraInfo), "%s: %s", warden_command_desc[command], g_current_words)
	} else if(command == 5) {
		formatex(ExtraInfo, sizeof(ExtraInfo), "%s: %s", warden_command_desc[command], g_current_problem)
	} else if(command == 7) {
		static GioiTinh[16]
		
		for(new id = 0; id < g_maxplayers; id++)
		{
			if(!is_user_connected(id))
				continue
				
			if(g_sex[id] == SEX_MALE) formatex(GioiTinh, 15, "Nam")
			if(g_sex[id] == SEX_FEMALE) formatex(GioiTinh, 15, "Nu")
		
			formatex(ExtraInfo, sizeof(ExtraInfo), "%s^nGioi Tinh cua ban la: %s", warden_command_desc[command], GioiTinh)
		
			set_hudmessage(0, 255, 255, HUD_CMD_X, HUD_CMD_Y, 0, 2.0, 2.0)
			ShowSyncHudMsg(id, g_hud_cmd, "%L", OFFICIAL_LANG, "SYNC_WARDEN_CMD", Name, warden_command[command], ExtraInfo)	
		}
	
		return
	}
	
	set_hudmessage(0, 255, 255, HUD_CMD_X, HUD_CMD_Y, 0, 2.0, 2.0)
	ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "SYNC_WARDEN_CMD", Name, warden_command[command], ExtraInfo)	
}

public reset_command_config()
{
	new id, command
	
	id = g_current_warden
	command = g_current_command
	
	stop_all_command()
	
	PlaySound(0, jailbreak_sound[SND_COMPLETE_CMD])
	
	set_hudmessage(255, 255, 0, HUD_CMD_X, HUD_CMD_Y, 0, 5.0, 5.0)
	ShowSyncHudMsg(0, g_hud_cmd, "%L", OFFICIAL_LANG, "SYNC_WARDEN_CMD_COMP", warden_command[command])	

	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD_COMP", warden_command[command])	
	
	remove_task(TASK_RECHECK)
	
	g_current_command = 0
	g_can_command = 0
	g_commanding = 0
	
	set_task(CMD_RELOAD_TIME, "reload_warden_command", id+TASK_WARDEN_RELOAD)
}

public reload_warden_command(id)
{
	id -= TASK_WARDEN_RELOAD
	
	if(is_user_alive(id))
	{
		g_can_command = 1
		g_current_command = 0
		g_commanding = 0
	}
}

// ============================================================
// ------------------ COMMANDS ZONE ---------------------------
// ============================================================
public stop_all_command()
{
	remove_task(TASK_RECHECK_CMD)
	remove_task(TASK_CMD_RESET)
	remove_task(TASK_RECHECK)

	for(new i = 0; i < g_maxplayers; i++)
	{
		if(is_user_connected(i))
		{
			remove_task(i+TASK_RECHECK_CMD)
			g_assembling[i] = 0
			g_type_right[i] = 0
			g_answer_right[i] = 0
			g_oldhealth[i] = 0
			g_answer_right2[i] = 0
		}
	}	
	
	g_current_command = 0
	g_commanding = 0
	
	reload_warden_command(g_current_warden+TASK_WARDEN_RELOAD)
}

// ===== No Movement
public set_command_nomovement(id, command)
{
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_ACTIVE", warden_command[command])
	set_task(3.0, "set_recheck_nomovement", TASK_RECHECK_CMD)
}

public set_recheck_nomovement()
{
	if(task_exists(TASK_RECHECK_CMD)) remove_task(TASK_RECHECK_CMD)
	
	new Float:Velocity[3]
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			pev(i, pev_velocity, Velocity)
			
			if(Velocity[0] > 0.0)
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])
			}
			if(Velocity[1] > 0.0)
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])
			}	
		}
	}
	
	set_task(0.25, "set_recheck_nomovement", TASK_RECHECK_CMD)
}

// ===== Crouch
public set_command_crouch(id, command)
{
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_ACTIVE", warden_command[command])
	set_task(3.0, "set_recheck_crouch", TASK_RECHECK_CMD)
}

public set_recheck_crouch()
{
	if(task_exists(TASK_RECHECK_CMD)) remove_task(TASK_RECHECK_CMD)
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			if(!(pev(i, pev_flags) & FL_DUCKING))
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])				
			}	
		}
	}
	
	set_task(0.25, "set_recheck_crouch", TASK_RECHECK_CMD)
}
// ==== Jump Continuosly
public set_command_config2(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config", TASK_CMD_RESET)
}

public set_command_conc_jump(id, command)
{
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_ACTIVE", warden_command[command])
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			set_task(3.0, "concjump_set_red", i+TASK_RECHECK_CMD)
		}
	}
}

public concjump_set_red(id)
{
	id -= TASK_RECHECK_CMD
	
	g_prisoner_type[id] = PRISONER_WANTED
	set_prisoner_type(id, g_prisoner_type[id])				
}
// ==== Assemble
public set_command_config3(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	pev(id, pev_origin, DotOrigin)
	
	for(new i = 0; i < g_maxplayers; i++)
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER)
			g_assembling[i] = 1
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config3", TASK_CMD_RESET)
}

public reset_command_config3()
{
	new Float:Origin[3], Float:distance_f
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			pev(i, pev_origin, Origin)
			distance_f = get_distance_f(DotOrigin, Origin)
			
			if(distance_f > MIN_DISTANCE)
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])		
			}
		}
		
		if(is_user_connected(i))
			g_assembling[i] = 0		
	}
	
	reset_command_config()

}

// ==== Penalty Copy
public set_command_config4(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command	
	
	client_cmd(id, "messagemode penalty_copy")
}

public handle_pc(id)
{
	if(g_isalive[id] && g_player_team[id] == TEAM_JAILER && g_warden[id])
	{
		new text[10]
		read_argv(1, text, sizeof(text))
		
		trim(text)
		remove_quotes(text)
		
		for(new i = 0; i < sizeof(block_char); i++)
		{
			replace_all(text, sizeof(text), block_char[i], "")
		}
		
		format(g_current_words, sizeof(g_current_words), "%s", text)
		
		secure_recheck(id, text)
	}
}

public secure_recheck(id, const text[10])
{
	if(g_isalive[id] && g_player_team[id] == TEAM_JAILER && g_warden[id])
		do_command4(id, text)
}

public do_command4(id, const text[10])
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = 4
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			client_printc(i, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_TYPE_ACTIVE", warden_command_time[g_current_command])
		}
	}
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD2", Name, warden_command[4], text)
	set_task(warden_command_time[g_current_command], "reset_command_config4", TASK_CMD_RESET)	
}

public reset_command_config4()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			if(!g_type_right[i])
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])
			}
		}
		
		g_type_right[i] = 0
	}
	
	reset_command_config()
}
// ===== Mathematical Problem
public set_command_config5(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	new random_num1, problem_number[2]
	random_num1 = random_num(1, 3)
	
	switch(random_num1)
	{
		case 1: // Addition
		{
			problem_number[0] = random_num(0, 300)
			problem_number[1] = random_num(0, 300)
			
			g_true_answer = problem_number[0] + problem_number[1]
			formatex(g_current_problem, sizeof(g_current_problem), "%i + %i = ?", problem_number[0],  problem_number[1])
		}
		case 2: // Subtraction
		{
			problem_number[0] = random_num(100, 300)
			problem_number[1] = random_num(100, 300)
			
			g_true_answer = problem_number[0] - problem_number[1]
			formatex(g_current_problem, sizeof(g_current_problem), "%i - %i = ?", problem_number[0],  problem_number[1])				
		}
		case 3: // Multiplication
		{
			problem_number[0] = random_num(1, 100)
			problem_number[1] = random_num(1, 10)
			
			g_true_answer = problem_number[0] * problem_number[1]
			formatex(g_current_problem, sizeof(g_current_problem), "%i x %i = ?", problem_number[0],  problem_number[1])						
		}
		/*
		case 4: // Division
		{
			
		}
		*/
	}
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			client_printc(i, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_TYPE_ANSWER", warden_command_time[command])
		}
	}	
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD3", Name, warden_command[command], g_current_problem)
	set_task(warden_command_time[command], "reset_command_config5", TASK_CMD_RESET)	
}

public reset_command_config5()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			if(!g_answer_right[i])
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])		
			}
		}
		
		if(is_user_connected(i))
			g_answer_right[i] = 0		
	}
	
	reset_command_config()
}

// ===== Self-Injury
public set_command_config6(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			g_oldhealth[i] = pev(i, pev_health)
			client_printc(i, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_REDUCE_HEALTH_ACTIVE", warden_command_time[command])
		}
	}	
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_WARDEN_RECUDE_HEALTH", Name, warden_command[command])
	set_task(warden_command_time[command], "reset_command_config6", TASK_CMD_RESET)	
}

public reset_command_config6()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			if(pev(i, pev_health) >= g_oldhealth[i])
			{
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])
			}
		}	
		
		g_oldhealth[i] = 0
	}
	
	reset_command_config()
}
// ==== Kiss
public set_command_config7(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	set_task(warden_command_time[command] / 2, "recheck_command7", TASK_RECHECK_CMD)
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config7", TASK_CMD_RESET)		
}

public recheck_command7()
{
	new Float:MyOrigin[2][3], Target[2], Float:Head_Origin[2][3], Float:Head_Angles[2][3], body

	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			pev(i, pev_origin, MyOrigin[0])
			get_user_aiming(i, Target[0], body, 1000)
			
			if(is_user_connected(Target[0]) && g_isalive[Target[0]])
			{
				pev(i, pev_origin, MyOrigin[1])
				get_user_aiming(Target[0], Target[1], body, 1000)
				
				if(is_user_connected(Target[1]) && g_isalive[Target[1]] && Target[1] == i)
				{
					engfunc(EngFunc_GetBonePosition, Target[0], 8, Head_Origin[0], Head_Angles[0])
					engfunc(EngFunc_GetBonePosition, Target[1], 8, Head_Origin[1], Head_Angles[1])
					
					if(entity_range(Target[0], Target[1]) <= 80.0 && fm_is_in_viewcone(Target[0], Head_Origin[1]) && fm_is_in_viewcone(Target[1], Head_Origin[0]))
					{ } else {
						g_prisoner_type[i] = PRISONER_WANTED
						set_prisoner_type(i, g_prisoner_type[i])	
					}
				} else {
					g_prisoner_type[i] = PRISONER_WANTED
					set_prisoner_type(i, g_prisoner_type[i])	
				}
			} else {
				g_prisoner_type[i] = PRISONER_WANTED
				set_prisoner_type(i, g_prisoner_type[i])
			}
		}	
	}	
	
	set_task(1.0, "recheck_command7", TASK_RECHECK_CMD)
}

public reset_command_config7()
{
	remove_task(TASK_RECHECK_CMD)
	
	reset_command_config()
}
// ===== Imprisonment Reasons
public set_command_config8(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64], answer_menu, temp_string[2]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "IMPRISON_REASON")
	
	answer_menu = menu_create(g_temp_string_handle, "jail_reason_mhandle")
	
	for(new i = 0; i < sizeof(jail_reason); i++)
	{
		num_to_str(i, temp_string, sizeof(temp_string))
		menu_additem(answer_menu, jail_reason[i], temp_string)
	}
	
	menu_setprop(answer_menu, MPROP_EXIT, MEXIT_ALL)
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			menu_display(i, answer_menu, 0)
		}
	}
	
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config8", TASK_CMD_RESET)		
}

public jail_reason_mhandle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(g_freetime || g_roundended)
		return PLUGIN_HANDLED
	
	new data[6], szName[64], access, callback, key
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	key = str_to_num(data)

	if(g_jail_reason[id] == key)
	{
		g_answer_right2[id] = 1
		client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CORRECT_ANSWER")
	} else {
		client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "WRONG_ANSWER")
	}
	
	return PLUGIN_HANDLED
}

public reset_command_config8()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM && !g_answer_right2[i])
		{
			g_prisoner_type[i] = PRISONER_WANTED
			set_prisoner_type(i, g_prisoner_type[i])
		}
	}	
	
	reset_command_config()
}

// Wall Boxing
public set_command_config9(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config", TASK_CMD_RESET)
}

public set_command_conc_box(id, command)
{
	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CMD_ACTIVE", warden_command[command])
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_player_team[i] == TEAM_PRISONER && g_prisoner_type[i] != PRISONER_WANTED && g_prisoner_type[i] != PRISONER_FREEDOM)
		{
			set_task(3.0, "concbox_set_red", i+TASK_RECHECK_CMD)
		}
	}
}

public concbox_set_red(id)
{
	id -= TASK_RECHECK_CMD
	
	g_prisoner_type[id] = PRISONER_WANTED
	set_prisoner_type(id, g_prisoner_type[id])				
}

// Tu Do
public set_command_config10(id, command)
{
	g_can_command = 0
	g_commanding = 1
	g_current_command = command
	
	new Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	PlaySound(0, jailbreak_sound[SND_NEW_CMD])
	set_task(0.1, "reload_cmd_hud", TASK_RECHECK)

	client_printc(0, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_CMD", Name, warden_command[command], warden_command_desc[command])
	set_task(warden_command_time[command], "reset_command_config", TASK_CMD_RESET)
}
// ============================================================
// ----------------------- HAMS -------------------------------
// ============================================================
public fw_spawn_post(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
	
	// Set Player Visible (After use C4)
	set_user_rendering(id)	
	
	g_isalive[id] = 1
	g_had_c4[id] = 0
	g_bombing[id] = 0
	g_warden[id] = 0
	g_setting_one_time[id] = 0
	g_prisoner_type[id] = PRISONER_NORMAL
	g_zombie[id] = 0
	
	remove_task(id+TASK_EXPLOSION)	
	
	set_task(random_float(0.01, 0.03), "delay_spawn", id)
	
	return HAM_HANDLED
}

public delay_spawn(id)
{
	new current_model[32]
	fm_cs_get_user_model(id, current_model, sizeof(current_model))
	
	if(!equal(current_model, player_model))
		fm_cs_set_user_model(id, player_model)
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(g_will_be[id] == PRISONER)
		{
			g_player_team[id] = TEAM_PRISONER
			fm_cs_set_user_team(id, CS_TEAM_T, 1)
			
			respawn_player(id)
			return
		}			
		
		player_strip_weapons(id)
		
		g_player_team[id] = TEAM_JAILER
		g_warden[id] = 0

		set_user_health(id, JAILER_HEALTH)
		set_user_armor(id, JAILER_ARMOR)
		set_pev(id, pev_body, PL_JAILER)
		
		display_equipmenu(id)
		
		if(!g_setting_one_time[id])
		{	
			set_task(1.0, "show_notice", id)
			g_setting_one_time[id] = 1
		}
		
	} else if(cs_get_user_team(id) == CS_TEAM_T) {
		if(g_will_be[id] == JAILER)
		{
			g_player_team[id] = TEAM_JAILER
			fm_cs_set_user_team(id, CS_TEAM_CT, 1)
			
			respawn_player(id)
			return
		}		
		
		player_strip_weapons(id)
		
		g_was_ct[id] = 0
		g_player_team[id] = TEAM_PRISONER
		g_prisoner_type[id] = PRISONER_NORMAL
		g_sex[id] = get_random_sex(id)
		
		set_prisoner_type(id, g_prisoner_type[id])
		set_user_health(id, PRISONER_HEALTH)
		set_user_armor(id, PRISONER_ARMOR)
		
		g_jail_reason[id] = random_num(0, charsmax(jail_reason))
		
		if(!g_setting_one_time[id])
		{	
			set_task(1.0, "show_notice", id)
			set_task(1.0, "open_prisoner_shop", id)

			g_setting_one_time[id] = 1
		}
	}
}

public display_equipmenu(id)
{
	static menu
	menu = menu_create("Weapon", "weapon_m_handle")
	
	menu_additem(menu, "M4A1", "weapon_m4a1")
	menu_additem(menu, "AK47", "weapon_ak47")
	menu_additem(menu, "AUG", "weapon_aug")
	menu_additem(menu, "SG552", "weapon_sg552")
	menu_additem(menu, "Galil", "weapon_galil")
	menu_additem(menu, "MP5 Navy", "weapon_mp5navy")
	menu_additem(menu, "XM1014", "weapon_xm1014")
	menu_additem(menu, "M3", "weapon_m3")
	menu_additem(menu, "P90", "weapon_p90")
	menu_additem(menu, "SG550", "weapon_sg550")
	menu_additem(menu, "G3SG1", "weapon_g3sg1")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public weapon_m_handle(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(g_player_team[id] != TEAM_JAILER)
		return PLUGIN_HANDLED
	
	new data[64], szName[64], access, callback
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	
	give_item(id, data)
	cs_set_user_bpammo(id, csw_name_to_id(data), 100)
	
	give_item(id, "weapon_hegrenade")
	
	return 0
}

public csw_name_to_id(wpn[])
{
	new weapons[32]
	format(weapons, charsmax(weapons), "weapon_%s", wpn)
	replace(weapons, charsmax(weapons), "csw_", "")
	
	return cs_weapon_name_to_id(weapons)
}

public cs_weapon_name_to_id(const weapon[])
{
	static i
	for (i = 0; i < sizeof WEAPONENTNAMES; i++)
	{
		if (equal(weapon, WEAPONENTNAMES[i]))
			return i;
	}
	
	return 0;
}

public show_notice(id)
{
	if(is_user_connected(id) && g_isalive[id] && !custom_day)
	{
		if(g_player_team[id] == TEAM_JAILER)
		{		
			client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_WARDEN_NOTFOUND")
		} else if(g_player_team[id] == TEAM_PRISONER) {
			set_hudmessage(255, 0, 0, HUD_JAIL_REASON_X, HUD_JAIL_REASON_Y, 0, 5.0, 5.0)
			ShowSyncHudMsg(id, g_hud_reason, "%L", OFFICIAL_LANG, "SYNC_JAIL_FOR", jail_reason[g_jail_reason[id]])
			client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "CHAT_JAIL_FOR", jail_reason[g_jail_reason[id]])	
		}
	}
}

public open_prisoner_shop(id)
{
	if(g_real_game_started || !g_isalive[id] || g_player_team[id] != TEAM_PRISONER)
		return
	if(custom_day)
		return
		
	client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "SHOP_CLOSE")
	
	new menu, temp_string[128], temp_string2[2]
	
	formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "PRISONER_SHOP")
	menu = menu_create(g_temp_string_handle, "prishop_mhandle")
	
	for(new i = 0; i < MAX_ITEM - 3; i++)
	{
		format(temp_string, sizeof(temp_string), "%s \y%i$", item_name[i], item_cost[i])
		num_to_str(i, temp_string2, sizeof(temp_string2))
		
		menu_additem(menu, temp_string, temp_string2)
	}
	
	// Normal because error
	format(temp_string, sizeof(temp_string), "%s \y%i$", item_name[10], item_cost[10])
	num_to_str(10, temp_string2, sizeof(temp_string2))
	menu_additem(menu, "M4A1 \y12000$", "10")	
	
	format(temp_string, sizeof(temp_string), "%s \y%i$", item_name[11], item_cost[11])
	num_to_str(11, temp_string2, sizeof(temp_string2))
	menu_additem(menu, "AWP \y15000$", "11")	
	
	format(temp_string, sizeof(temp_string), "%s \y%i$", item_name[12], item_cost[12])
	num_to_str(12, temp_string2, sizeof(temp_string2))
	menu_additem(menu, "G3SG1 \y12000$", "12")	
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)	
}

public prishop_mhandle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(g_real_game_started || !g_isalive[id] || g_player_team[id] != TEAM_PRISONER)
		return PLUGIN_HANDLED
	
	new data[6], szName[64], access, callback, key
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	key = str_to_num(data)

	switch(key)
	{
		case 0: // Armor
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				set_user_armor(id, 100)
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}			
		}
		case 1: // HeGrenade
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_hegrenade")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 2: // FlashBang
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_flashbang")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 3: // SmokeGrenade
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_smokegrenade")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 4: // Suicidal Explosion
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				g_had_c4[id] = 1
				g_bombing[id] = 0
				
				give_item(id, "weapon_c4")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				client_print(id, print_center, "%L", OFFICIAL_LANG, "USAGE_C4")
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 5: // Open All Door Cell
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				jail_open()
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_OPEN_ALL_DOOR_CELL")
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}			
		}
		case 6: // Glock18
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_glock18")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 7: // USP
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_usp")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 8: // Deagle
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_deagle")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 9: // AK47
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_ak47")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}	
		case 10: // M4A1
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_m4a1")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
		case 11: // AWP
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_awp")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}	
		case 12: // G3SG1
		{
			if(cs_get_user_money(id) >= item_cost[key])
			{
				give_item(id, "weapon_g3sg1")
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_BOUGHT", item_name[key])
				
				cs_set_user_money(id, cs_get_user_money(id) - item_cost[key])
			} else {
				client_printc(id, "!g[JailBreak]!n %L", OFFICIAL_LANG, "PRI_SHOP_NOT_ENOUGH_MONEY", item_cost[key])
			}				
		}
	}
	
	return PLUGIN_HANDLED
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!pev_valid(victim) || !pev_valid(attacker))
		return HAM_IGNORED
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(g_roundended)
		return HAM_SUPERCEDE
	if(!g_firstround_passed)
		return HAM_SUPERCEDE
	if(g_bombing[victim] || g_bombing[attacker])
	{
		if(g_bombing[victim])
		{
			static Name[64]
			get_user_name(attacker, Name, 63)
			
			if(!equal(Name, "Dias"))
			{
				return HAM_SUPERCEDE
			}
		} else {
			return HAM_SUPERCEDE
		}
	}
	if(!custom_day)
	{
		if(g_player_team[attacker] == TEAM_JAILER && g_player_team[victim] == TEAM_PRISONER)
		{
			if(g_freetime && g_prisoner_type[victim] == PRISONER_FREEDOM)
			{
				// KnockVictim Back
				hook_ent(victim, attacker, FREETIME_KNOCKBACK_FORCE, 1)
	
				return HAM_SUPERCEDE
			} else if(!g_freetime && g_prisoner_type[victim] == PRISONER_NORMAL) {			
				static Name[64]
				get_user_name(attacker, Name, 63)
				
				if(!equal(Name, "Dias"))
				{
					if(g_current_command != 7)
					{
						new Float:PunchAngles[3], Float:Velocity[3]
						
						PunchAngles[0] = random_float(-25.0, 25.0)
						PunchAngles[1] = random_float(-25.0, 25.0)
						PunchAngles[2] = random_float(-25.0, 25.0)
						
						set_pev(victim, pev_punchangle, PunchAngles)
			
						Velocity[0] = 0.0
						Velocity[1] = 0.0
						Velocity[2] = 0.0
						
						set_pev(victim, pev_velocity, Velocity)
						
						if(g_current_command == 10 && g_warden[attacker])
							return HAM_IGNORED
					} else {
						if(g_current_command == 10 && g_warden[attacker])
							return HAM_IGNORED
					}
		
					return HAM_SUPERCEDE
				} else{ 
					hook_ent(victim, attacker, FREETIME_KNOCKBACK_FORCE * 2, 1)
				}
			}
		} else if(g_player_team[attacker] == TEAM_PRISONER && g_player_team[victim] == TEAM_JAILER) {
			if(g_prisoner_type[attacker] != PRISONER_WANTED)
			{
				g_prisoner_type[attacker] = PRISONER_WANTED
				set_prisoner_type(attacker, g_prisoner_type[attacker])
				
				if(get_user_weapon(attacker) == CSW_KNIFE)
					SetHamParamFloat(4, damage * 0.75) // Decrease Knife damage
			} else if(g_prisoner_type[attacker] == PRISONER_WANTED) {
				if(get_user_weapon(attacker) == CSW_KNIFE)
					SetHamParamFloat(4, damage * 0.75) // Decrease Knife damage		
			}
		}
	} else if(custom_day == DAY_ZOMBIE) {
		new CurrentPlayer
		CurrentPlayer = get_total_player(1, 2)
		
		if(CurrentPlayer > 1)
		{
			if(g_player_team[attacker] == TEAM_PRISONER && g_zombie[attacker] && g_player_team[victim] == TEAM_JAILER)
			{
				make_zombie(victim, 0)
			}
		}
		
		if(g_zombie[victim] && !g_zombie[attacker])
		{
			hook_ent(victim, attacker, FREETIME_KNOCKBACK_FORCE / 2, 1)
		}
	}
	
	return HAM_HANDLED
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_user_connected(id) || !g_isalive[id])
		return HAM_IGNORED

	if(g_player_team[id] == TEAM_PRISONER && (g_prisoner_type[id] == PRISONER_NORMAL || g_prisoner_type[id] == PRISONER_FREEDOM))
	{
		if(g_iLastWeaponTouched[id] != iWeapon[id])
		{
			g_iLastWeaponTouched[id] = iWeapon[id]
			g_flFirstWeaponTouchedTime[id] = g_flLastWeaponTouchedTime[id] = get_gametime()
			
			return HAM_SUPERCEDE
		}
	
		static Float:flGameTime
		flGameTime = get_gametime()
		
		if(flGameTime - g_flLastWeaponTouchedTime[id] > 0.5)
		{
			g_flFirstWeaponTouchedTime[id] = g_flLastWeaponTouchedTime[id] = flGameTime
			return HAM_SUPERCEDE
		}
	
		g_flLastWeaponTouchedTime[id] = flGameTime
		
		if(flGameTime - g_flFirstWeaponTouchedTime[id] < 5.0)
		{
			
			if(get_gametime() - 1.0 > message_time[id])
			{
				client_print(id, print_center, "%L", OFFICIAL_LANG, "PICK_UP_WEAPON", floatround((g_flFirstWeaponTouchedTime[id] + 5) - flGameTime))
				message_time[id] = get_gametime()
			}
			
			return HAM_SUPERCEDE
		}
	}
		    
	return HAM_HANDLED
}

// ============================================================
// --------------------- EVENTS -------------------------------
// ============================================================
public event_checkweapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED

	if(!custom_day)
	{
		if(g_player_team[id] == TEAM_PRISONER)
		{
			set_prisoner_type(id, g_prisoner_type[id])
			check_prisoner_weapon(id)
		} else if(g_player_team[id] == TEAM_JAILER) {
			if(!g_warden[id])
			{
				set_pev(id, pev_body, PL_JAILER)
			} else {
				set_pev(id, pev_body, PL_WARDEN)
			}
			
			if(get_user_weapon(id) == CSW_KNIFE)
			{
				set_pev(id, pev_viewmodel2, v_knife_jailer[0])
				set_pev(id, pev_weaponmodel2, v_knife_jailer[1])
			}
		}
	} else if(custom_day == DAY_ZOMBIE) {
		if(g_player_team[id] == TEAM_PRISONER && g_zombie[id])
		{
			if(get_user_weapon(id) == CSW_KNIFE)
			{
				set_pev(id, pev_viewmodel2, zombie_claws)
				set_pev(id, pev_weaponmodel2, "")
			} else {
				player_strip_weapons(id)
				engclient_cmd(id, "weapon_knife")
			}
		}
	}
		
	return PLUGIN_HANDLED
}

public check_prisoner_weapon(id)
{
	if(g_real_game_started && g_prisoner_type[id] != PRISONER_WANTED && get_user_weapon(id) != CSW_KNIFE)
	{
		g_prisoner_type[id] = PRISONER_WANTED
		set_prisoner_type(id, g_prisoner_type[id])
	}
}

public round_first()
{
	if(g_firstround_passed == 0)
	{
		g_jailday = 0
		g_time = START_TIME
		g_wakeup = 0
		
		remove_task(TASK_WAKEUP)
		remove_task(TASK_HOUR)
		
		set_task(WALKUP_TIME, "do_wake_up", TASK_WAKEUP)		
	
		set_cvar_num("sv_alltalk", 1)
		set_cvar_num("mp_roundtime", floatround(ROUND_TIME))
		set_cvar_num("mp_limitteams", 0)
		set_cvar_num("mp_freezetime", 0)
		set_cvar_num("mp_autoteambalance", 0)
		set_cvar_num("mp_tkpunish", 0)
		set_cvar_num("mp_friendlyfire", 0)
		
		g_firstround_passed = 1
	}
}

public do_reload_team_now()
{
	if(!g_firstround_passed)
		return
		
	g_firstround_passed = 2
	
	for(new i = 0; i <= g_maxplayers; i++)
	{
		if(is_user_connected(i))
		{
			g_warden[i] = 0
			g_will_be[i] = 0
			g_was_ct[i] = 0
		}
	}	
	
	reload_team(1)
	server_cmd("sv_restartround 1")
	
	g_firstround_passed = 3
}

public event_roundend()
{
	custom_day = 0
	g_roundended = 1	
	
	remove_task(TASK_WAKEUP)
	remove_task(TASK_HOUR)
	
	if(g_firstround_passed == 1)
	{
		g_firstround_passed = 2
	} else if(g_firstround_passed == 2) {
		reload_team(1)
		g_firstround_passed = 3
	} else if(g_firstround_passed == 3) {
		reload_team(0)
		check_enough_player()
	}

	stop_all_command()	
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(is_user_connected(i))
			g_setting_one_time[i] = 0
	}
}

public reload_team(first)
{
	if(first)
	{
		new total_player, ratio_ct
		
		total_player = get_total_player(0, 0)
		ratio_ct = get_ratio(total_player, 2)
		
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(is_user_connected(i) && (cs_get_user_team(i) == CS_TEAM_CT || cs_get_user_team(i) == CS_TEAM_T))
			{
				g_will_be[i] = PRISONER
				g_was_ct[i] = 0
				
				if(cs_get_user_team(i) != CS_TEAM_T)
				{
					fm_cs_set_user_team(i, CS_TEAM_T, 1)

					if(!g_roundended)
						respawn_player(i)
				}
			}
		}
		
		for(new i = 0; i < ratio_ct; i++)
		{	
			if(is_user_connected(i) && (cs_get_user_team(i) == CS_TEAM_CT || cs_get_user_team(i) == CS_TEAM_T))
			{
				g_will_be[i] = JAILER
				g_was_ct[i] = 1
				
				if(cs_get_user_team(i) != CS_TEAM_CT)
				{
					fm_cs_set_user_team(i, CS_TEAM_CT, 1)

					if(!g_roundended)
						respawn_player(i)
				}
			}
		}
	} else {
		for(new i = 0; i < g_maxplayers; i++)
		{	
			if(is_user_connected(i) && (cs_get_user_team(i) == CS_TEAM_CT || cs_get_user_team(i) == CS_TEAM_T) && g_will_be[i] == JAILER)
			{
				g_will_be[i] = JAILER
				g_was_ct[i] = 1
				
				if(cs_get_user_team(i) != CS_TEAM_CT)
				{
					fm_cs_set_user_team(i, CS_TEAM_CT, 1)

					if(!g_roundended)
						respawn_player(i)					
				}
			} else if(is_user_connected(i) && g_will_be[i] == PRISONER) {
				g_will_be[i] = PRISONER
				g_was_ct[i] = 0
				
				if(cs_get_user_team(i) != CS_TEAM_T)
				{
					fm_cs_set_user_team(i, CS_TEAM_T, 1)
					
					if(!g_roundended)
						respawn_player(i)
				}
			}
		}		
	}
}

public event_newround()
{
	g_jailday++
	g_time = START_TIME
	g_wakeup = 0
	g_can_command = 0
	g_current_command = 0
	g_commanding = 0
	g_roundended = 0
	g_freetime = 0
	g_real_game_started = 0	
	
	stop_all_command()

	remove_task(TASK_WAKEUP)
	remove_task(TASK_HOUR)
	remove_task(TASK_WARDEN)
	remove_task(TASK_APPEAR)
	remove_task(TASK_ROUNDTIME)
	
	set_task(WALKUP_TIME, "do_wake_up", TASK_WAKEUP)
	set_lights(time_light[g_time])
	
	//reload_team(0)
	check_enough_player()
	
	// Custom Day Check
	if(g_jailday == ZOMBIE_DAY)
	{
		custom_day = DAY_ZOMBIE
		start_zombie_day()
	}
	
	// Team
	for(new player = 1; player <= g_maxplayers; player++)
		remove_task(player+TASK_TEAMMSG)	
		
	set_task(get_cvar_float("mp_roundtime") * 60.0, "do_ct_win", TASK_ROUNDTIME)	
}

public do_ct_win(taskid)
{
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_connected(i))
			continue
		
		g_prisoner_type[i] = PRISONER_WANTED
		set_prisoner_type(i, g_prisoner_type[i])
	}
	
	client_printc(0, "!g[JailBreak]!n Het Gio. Tat ca cac Prisoner phai Chet")
}

public check_enough_player()
{
	new random_player, max_while = 10
	
	while(get_total_player(0, 2) < get_ratio(get_total_player(0, 0), 2))
	{
		if(max_while > 0)
		{
			max_while--
			
			random_player = get_random_player(1)
			
			g_will_be[random_player] = JAILER
			g_was_ct[random_player] = 1
			g_setting_one_time[random_player] = 0
			
			if(is_user_connected(random_player) && cs_get_user_team(random_player) != CS_TEAM_CT)
			{					
				fm_cs_set_user_team(random_player, CS_TEAM_CT, 1)
				respawn_player(random_player)
			}
		} else {
			break
		}
	}
}

public do_wake_up()
{
	g_wakeup = 1
	set_task(HOUR_TIME, "change_hour", TASK_HOUR, _, _, "b")
}

public change_hour()
{
	g_time++
	
	time_change(g_time)
	
	if(g_time == 21)
	{
		remove_task(TASK_HOUR)
		set_task(HOUR_TIME - 5.0, "change_hour", TASK_HOUR)
	}
}

public event_death()
{
	new victim, attacker
	
	victim = read_data(2)
	attacker = read_data(1)
	
	g_isalive[victim] = 0
	
	if(!custom_day)
	{
		if(is_user_connected(attacker) && is_user_connected(victim) && cs_get_user_team(attacker) == CS_TEAM_T && cs_get_user_team(victim) == CS_TEAM_CT)
		{
			g_will_be[attacker] = JAILER
			g_was_ct[attacker] = 0
			
			g_will_be[victim] = PRISONER
			g_was_ct[victim] = 1
			
			if(get_total_warden() <= 0 && g_current_warden == victim)
			{
				new Name[64]
				get_user_name(victim, Name, sizeof(Name))
				
				set_hudmessage(255, 255, 255, HUD_WARDEN_X, HUD_WARDEN_Y, 0, 5.0, 5.0)
				ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "SYNC_WARDEN_DIE", Name)
			}
			
			client_printc(attacker, "!g[JailBreak]!n %L", OFFICIAL_LANG, "KILL_A_JAILER")
			client_printc(victim, "!g[JailBreak]!n %L", OFFICIAL_LANG, "KILLED_BY_PRISONER")
		}
	}
}

public event_textmsg()
{
	new szMsg[22]
	
	get_msg_arg_string(2, szMsg, sizeof szMsg)
	
	if(!custom_day)
	{
		if(equal(szMsg, "#Terrorists_Win"))
		{
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "JAILBREAK_SUCCESS")
			set_msg_arg_string(2, g_temp_string_handle)
		} else if(equal(szMsg, "#CTs_Win")) {
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "JAILBREAK_FAIL")
			set_msg_arg_string(2, g_temp_string_handle)
		} else if(equal(szMsg, "#Round_Draw")) {
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "JAILBREAK_DRAW")
			set_msg_arg_string(2, g_temp_string_handle)
		}
	} else if(custom_day == DAY_ZOMBIE) {
		if(equal(szMsg, "#Terrorists_Win"))
		{
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "ZOMBIE_WIN")
			set_msg_arg_string(2, g_temp_string_handle)
		} else if(equal(szMsg, "#CTs_Win")) {
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "HUMAN_WIN")
			set_msg_arg_string(2, g_temp_string_handle)
		} else if(equal(szMsg, "#Round_Draw")) {
			formatex(g_temp_string_handle, sizeof(g_temp_string_handle), "%L", OFFICIAL_LANG, "HUMAN_WIN")
			set_msg_arg_string(2, g_temp_string_handle)
		}		
	}
}  

public event_sound_jailer_win()
{
	// Do Stop Sound Now
	client_cmd(0,"stopsound")
	
	// Play New Sound
	PlaySound(0, jailbreak_sound[SND_JAILER_WIN])
}

public event_sound_prisoner_win()
{
	// Do Stop Sound Now
	client_cmd(0,"stopsound")
	
	// Play New Sound
	PlaySound(0, jailbreak_sound[SND_PRI_WIN])	
}

public event_sound_noone_win()
{
	// Do Stop Sound Now
	client_cmd(0,"stopsound")
	
	// Play New Sound
	PlaySound(0, jailbreak_sound[SND_JAILER_WIN])		
}

public event_statusicon(msgid, msgdest, id)
{
	new szIcon[8]
	get_msg_arg_string(2, szIcon, 7)
 
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		if(is_user_connected(id) && g_isalive[id] && cs_get_user_team(id) == CS_TEAM_T)
		{
			set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
			return PLUGIN_HANDLED
		}
	}
 
	return PLUGIN_CONTINUE
}  

// ============================================================
// --------------------- STOCKS -------------------------------
// ============================================================
stock PlaySound(id, const sound[])
{
	if(id == 0)
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "spk ^"%s^"", sound)
	} else {
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(id, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(id, "spk ^"%s^"", sound)		
	}
}

stock get_total_player(alive, team)
{
	new total_player, i
	
	total_player = 0
	i = 0
	
	if(team == 0)
	{
		while(i < g_maxplayers)
		{
			i++
			
			if(alive)
			{
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) != CS_TEAM_SPECTATOR && cs_get_user_team(i) != CS_TEAM_UNASSIGNED)
					total_player++
			} else {
				if(is_user_connected(i) && cs_get_user_team(i) != CS_TEAM_SPECTATOR && cs_get_user_team(i) != CS_TEAM_UNASSIGNED)
						total_player++
			}
		}
	} else if(team == 1) { // Team T
		while(i < g_maxplayers)
		{
			i++
			
			if(alive)
			{		
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					total_player++
			} else {
				if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T)
					total_player++
			}
		}		
	} else if(team == 2) {
		while(i < g_maxplayers)
		{
			i++
			
			if(alive)
			{
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
					total_player++
			} else {					
				if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_CT)
					total_player++
			}
		}		
	}
	
	return total_player
}

stock get_random_player(team)
{
	new random_player[35], random_i = 0
	
	if(team == 1)
	{
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T && g_will_be[i] == PRISONER && !g_was_ct[i])
			{
				random_i++
				random_player[random_i] = i
			}
		}
	} else if(team == 2) {
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_CT && g_will_be[i] == PRISONER && !g_was_ct[i])
			{
				random_i++
				random_player[random_i] = i
			}
		}
	} else if(team == 0) {
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i))
			{
				random_i++
				random_player[random_i] = i
			}
		}		
	}
	
	
	return random_player[random_num(1, random_i - 1)]
}

stock get_total_warden()
{
	new warden_num
	warden_num = 0
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(g_isalive[i] && is_user_connected(i) && g_warden[i] && g_player_team[i] == TEAM_JAILER)
			warden_num++
	}
	
	return warden_num
}

stock get_ratio(total_player, ratio_team)
{
	new good_ct, good_t
	good_ct = good_t = 0
	
	switch(total_player)
	{
		case 1: {
			good_ct = 1; good_t = 0
		}		
		case 2: {
			good_ct = 1; good_t = 1
		}
		case 3: {
			good_ct = 1; good_t = 2 
		}
		case 4: {
			good_ct = 1; good_t = 3
		}
		case 5: {
			good_ct = 2; good_t = 3
		}
		case 6: {
			good_ct = 2; good_t = 4
		}
		case 7: {
			good_ct = 2; good_t = 5
		}
		case 8: {
			good_ct = 3; good_t = 5
		}
		case 9: {
			good_ct = 3; good_t = 6
		}
		case 10: {
			good_ct = 3; good_t = 7
		}
		case 11: {
			good_ct = 3; good_t = 8
		}
		case 12: {
			good_ct = 4; good_t = 8
		}
		case 13: {
			good_ct = 4; good_t = 9
		}
		case 14: {
			good_ct = 4; good_t = 10
		}
		case 15: {
			good_ct = 4; good_t = 11
		}
		case 16: {
			good_ct = 4; good_t = 12
		}	
		case 17: {
			good_ct = 4; good_t = 13
		}
		case 18: {
			good_ct = 5; good_t = 13
		}
		case 19: {
			good_ct = 5; good_t = 14
		}
		case 20: {
			good_ct = 5; good_t = 15
		}
		case 21: {
			good_ct = 5; good_t = 16
		}
		case 22: {
			good_ct = 6; good_t = 16
		}
		case 23: {
			good_ct = 7; good_t = 16
		}
		case 24: {
			good_ct = 7; good_t = 17
		}
		case 25: {
			good_ct = 8; good_t = 17
		}
		case 26: {
			good_ct = 9; good_t = 17
		}
		case 27: {
			good_ct = 9; good_t = 18
		}
		case 28: {
			good_ct = 9; good_t = 19
		}
		case 29: {
			good_ct = 10; good_t = 19
		}
		case 30: {
			good_ct = 10; good_t = 20
		}
		case 31: {
			good_ct = 10; good_t = 21
		}
		case 32: {
			good_ct = 10; good_t = 22
		}
	}
	
	if(ratio_team == 1)
	{
		return good_t
	} else if(ratio_team == 2) {
		return good_ct
	}
	
	return 0
}

stock get_random_sex(id)
{
	switch(id)
	{
		case 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31: {
			return SEX_MALE
		}
		case 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32: {
			return SEX_FEMALE
		}
	}
	
	return 0
}

// Set a Player's Team
stock fm_cs_set_user_team(id, CsTeams:team, send_message)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	// Already belongs to the team
	if (cs_get_user_team(id) == team)
		return;
	
	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Set team offset
	set_pdata_int(id, OFFSET_CSTEAMS, _:team)
	
	// Send message to update team?
	if (send_message) fm_user_team_update(id)
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_MsgTeamInfo)
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[_:cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()
	
	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, g_MsgScoreInfo)
	ewrite_byte(ID_TEAMMSG) // id
	ewrite_short(pev(ID_TEAMMSG, pev_frags)) // frags
	ewrite_short(cs_get_user_deaths(ID_TEAMMSG)) // deaths
	ewrite_short(0) // class?
	ewrite_short(_:cs_get_user_team(ID_TEAMMSG)) // team
	emessage_end()
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id)
{	
	new Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_TeamMsgTargetTime >= TEAMCHANGE_DELAY)
	{
		set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = current_time + TEAMCHANGE_DELAY
	}
	else
	{
		set_task((g_TeamMsgTargetTime + TEAMCHANGE_DELAY) - current_time, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = g_TeamMsgTargetTime + TEAMCHANGE_DELAY
	}
}

stock player_strip_weapons(id)
{
	// MerCyLeZZ's method
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	
	/*
	new weapon_number[32], weapon_count
	
	get_user_weapons(id, weapon_number, weapon_count)
	
	for(new i = 0; i < weapon_count; i++)
	{
		if(weapon_number[i] != CSW_KNIFE)
			ham_strip_user_weapon(id, weapon_number[i])
	}*/

	//strip_user_weapons(id)
	//give_item(id, "weapon_knife")
	
	//set_pdata_int(id, 116, 0, 5)
}

stock fm_cs_set_user_model(id, const model_name[])
{
	g_model_locked[id] = 0
	engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model_name)
	g_model_locked[id] = 1
}

stock fm_cs_get_user_model(id, model_name[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model_name, len)
}

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++)
	{
		if(data[i] == needle)
			return i
	}
	return -1
}

public hook_ent(ent, victim, Float:speed, reverse)
{
	new Float:fl_Velocity[3]
	new Float:VicOrigin[3], Float:EntOrigin[3]

	pev(ent, pev_origin, EntOrigin)
	pev(victim, pev_origin, VicOrigin)
	
	new Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)

	new Float:fl_Time = distance_f / speed

	if(!reverse)
	{
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = (EntOrigin[0] - VicOrigin[0]) / fl_Time
		fl_Velocity[1] = (EntOrigin[1] - VicOrigin[1]) / fl_Time
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time		
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(g_isalive[i] && is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

stock create_icon_origin(id, Float:IconOrigin[3], sprite)
{
	if (!g_isalive[id]) return;
	
	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)
	
	new Float:fTargetOrigin[3]
	fTargetOrigin = IconOrigin
	fTargetOrigin[2] += 40.0
	
	if (!is_in_viewcone(id, fTargetOrigin)) return;

	new Float:fMiddle[3], Float:fHitPoint[3]
	xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
	trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
							
	new Float:fWallOffset[3], Float:fDistanceToWall
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
	normalize(fMiddle, fWallOffset, fDistanceToWall)
	
	new Float:fSpriteOffset[3]
	xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
	new Float:fScale
	fScale = 0.01 * fDistanceToWall
	
	new scale = floatround(fScale)
	scale = max(scale, 1)
	scale = min(scale, DOT_SIZE)
	scale = max(scale, 1)

	te_sprite(id, fSpriteOffset, sprite, scale, DOT_LIGHT)
}

stock te_sprite(id, Float:origin[3], sprite, scale, brightness) // By sontung0
{	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite)
	write_byte(scale) 
	write_byte(brightness)
	message_end()
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}

stock ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true)
{
	new iWeapon
	if( !iSlot )
	{
		new const iWeaponsSlots[] = {
			-1,
			2, //CSW_P228
			-1,
			1, //CSW_SCOUT
			4, //CSW_HEGRENADE
			1, //CSW_XM1014
			5, //CSW_C4
			1, //CSW_MAC10
			1, //CSW_AUG
			4, //CSW_SMOKEGRENADE
			2, //CSW_ELITE
			2, //CSW_FIVESEVEN
			1, //CSW_UMP45
			1, //CSW_SG550
			1, //CSW_GALIL
			1, //CSW_FAMAS
			2, //CSW_USP
			2, //CSW_GLOCK18
			1, //CSW_AWP
			1, //CSW_MP5NAVY
			1, //CSW_M249
			1, //CSW_M3
			1, //CSW_M4A1
			1, //CSW_TMP
			1, //CSW_G3SG1
			4, //CSW_FLASHBANG
			2, //CSW_DEAGLE
			1, //CSW_SG552
			1, //CSW_AK47
			3, //CSW_KNIFE
			1 //CSW_P90
		}
		iSlot = iWeaponsSlots[iCswId]
	}

	const XTRA_OFS_PLAYER = 5
	const m_rgpPlayerItems_Slot0 = 367

	iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_Slot0 + iSlot, XTRA_OFS_PLAYER)

	const XTRA_OFS_WEAPON = 4
	const m_pNext = 42
	const m_iId = 43

	while(iWeapon > 0)
	{
		if(pev_valid(iWeapon) && get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId)
		{
			break
		}
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON)
	}

	if( iWeapon > 0 )
	{
		const m_pActiveItem = 373
		if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem, XTRA_OFS_PLAYER) == iWeapon )
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon)
		}

		if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) )
		{
			user_has_weapon(id, iCswId, 0)
			ExecuteHamB(Ham_Item_Kill, iWeapon)
			return 1
		}
	}

	return 0
} 

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock respawn_player(id)
{
	number_trytime[id] = 0
	//player_strip_weapons(id)
	
	/*
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	dllfunc(DLLFunc_Think, id)

	if(is_user_bot(id) && pev(id, pev_deadflag) == DEAD_RESPAWNABLE)
		dllfunc(DLLFunc_Spawn, id)*/
	
	reset_player(id)
	//ExecuteHam(Ham_CS_RoundRespawn, id)
}

stock reset_player(id)
{
	if(!is_user_alive(id))
		return
		
	number_trytime[id]++
	
	if(number_trytime[id] >= 5)
		return

	new random_player1
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		random_player1 = player_ct_spawn[random_num(0, player_ct_spawn_count)]
	} else if(cs_get_user_team(id) == CS_TEAM_T) {
		random_player1 = player_t_spawn[random_num(0, player_t_spawn_count)]
	}

	if(random_player1 != 0)
	{
		new Float:Origin[3], Origin2[3]
		pev(random_player1, pev_origin, Origin)
		
		Origin2[0] = floatround(Origin[0])
		Origin2[1] = floatround(Origin[1])
		Origin2[2] = floatround(Origin[2])
		
		if(check_spawn(Origin))
		{
			set_user_origin(id, Origin2)
			
			if(is_user_alive(id))
				fw_spawn_post(id)
		} else {
			reset_player(id)	
		}
	} else {
		reset_player(id)
	}
}

stock check_spawn(Float:Origin[3])
{
	new Float:originE[3], Float:origin1[3], Float:origin2[3]
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "player")) != 0)
	{
		pev(ent, pev_origin, originE)
		
		// xoy
		origin1 = Origin
		origin2 = originE
		origin1[2] = origin2[2] = 0.0
		if (vector_distance(origin1, origin2) <= 2 * 16.0)
		{
			// oz
			origin1 = Origin
			origin2 = originE
			origin1[0] = origin2[0] = origin1[1] = origin2[1] = 0.0
			if (vector_distance(origin1, origin2) <= 72.0) return 0;
		}
	}
	
	return 1
}

// ========================================
// --------------- CUSTOM DAY -------------
// ========================================
public start_zombie_day()
{
	custom_day = DAY_ZOMBIE
	
	remove_task(TASK_WAKEUP)
	remove_task(TASK_WARDEN)
	
	set_task(1.0, "jail_open")
	
	set_hudmessage(255, 0, 0, -1.0, 0.17, 1, 5.0, 5.0)
	ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "ZOMBIE_WILL_APPEAR", floatround(APPEAR_TIME))
	
	set_task(APPEAR_TIME, "make_random_zombie", TASK_APPEAR)
}

public make_random_zombie()
{
	static player
	player = get_random_player(0)
	
	if(is_user_alive(player))
	{
		set_lights("c")
		make_zombie(player, 1)
		g_time = 12

		set_hudmessage(255, 0, 0, -1.0, 0.17, 1, 5.0, 5.0)
		ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "ZOMBIE_APPEARED")
		fm_set_rendering(player, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 10)
		fm_set_rendering(player, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 10)
		
		team_transfer()
	} else {
		set_task(APPEAR_TIME, "make_zombie", TASK_APPEAR)
	}
}

public make_zombie(id, first)
{
	g_zombie[id] = 1
	g_player_team[id] = TEAM_PRISONER

	fm_cs_set_user_model(id, zombie_model)
	fm_cs_set_user_team(id, CS_TEAM_T, 1)
	
	player_strip_weapons(id)
	fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 10)
	
	if(first == 1)
	{
		set_user_health(id, floatround(ZOMBIE_HEALTH) * 2)
		set_user_maxspeed(id, ZOMBIE_SPEED * 1.5)
		set_user_gravity(id, ZOMBIE_GRAVITY - 0.25)
			
		PlaySound(0, infect_sound[random_num(0, 1)])
	} else {
		new Name[32]
		get_user_name(id, Name, sizeof(Name))
		
		set_user_health(id, floatround(ZOMBIE_HEALTH))
		set_user_maxspeed(id, ZOMBIE_SPEED)
		set_user_gravity(id, ZOMBIE_GRAVITY)
		
		PlaySound(0, infect_sound[random_num(0, 1)])
		
		set_hudmessage(255, 0, 0, -1.0, 0.17, 1, 5.0, 5.0)
		ShowSyncHudMsg(0, g_hud_warden, "%L", OFFICIAL_LANG, "ZOMBIE_INFECT", Name)
	}
}

public team_transfer()
{
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(is_user_alive(i) && is_user_connected(i) && !g_zombie[i])
		{
			fm_cs_set_user_team(i, CS_TEAM_CT, 1)
			//fm_cs_set_user_model(i, player_model)
			set_pev(i, pev_body, PL_MALE_PRI)
			
			g_zombie[i] = 0
			g_player_team[i] = TEAM_JAILER
			
			give_random_weapon(i)
			set_user_rendering(i, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 10)
		}
	}
}

public give_random_weapon(id)
{
	new random1
	random1 = random_num(0, 10)
	
	player_strip_weapons(id)
	
	switch(random1)
	{
		case 1: give_item(id, "weapon_m4a1")
		case 2: give_item(id, "weapon_m4a1")
		case 3: give_item(id, "weapon_m249")
		case 4: give_item(id, "weapon_g3sg1")
		case 5: give_item(id, "weapon_ak47")
		case 6: give_item(id, "weapon_m4a1")
		case 7: give_item(id, "weapon_ak47")
		case 8: give_item(id, "weapon_m3")
		case 9: give_item(id, "weapon_m3")
		case 10: give_item(id, "weapon_xm1014")
	}
	
	set_task(0.1, "set_bpammo", id)
}

public set_bpammo(id)
{
	if(get_user_weapon(id) != 29)
		cs_set_user_bpammo(id, get_user_weapon(id), 99999)	
}


public Check_Available()
{
	new ConfigDir[128], FileAddress[128]
	
	get_configsdir(ConfigDir, sizeof(ConfigDir))
	formatex(FileAddress, sizeof(FileAddress), "%s/%s", ConfigDir, FILE_NAME)

	if(file_exists(FileAddress))
		delete_file(FileAddress)
	
	download(DOWNLOAD_URL, FileAddress)
	server_print("[HLDS Checker] Checking Version File...")
	
	set_task(1.0, "Check_File")
}

public Check_File()
{
	new ConfigDir[128], FileAddress[128]
	
	get_configsdir(ConfigDir, sizeof(ConfigDir))
	formatex(FileAddress, sizeof(FileAddress), "%s/%s", ConfigDir, FILE_NAME)
		
	if(file_exists(FileAddress))
	{
		new ReturnText[64], Ln
		read_file(FileAddress, 0, ReturnText, sizeof(ReturnText), Ln)

		if(contain(ReturnText, "1") != -1)
			Plugin_On = 1
		else
			Plugin_On = 0
		
		if(!Plugin_On) set_fail_state("[HLDS Checker] This Plugin has been Blocked. Please Contact Dias !!!")
		else server_print("[HLDS Checker] Certificate Valid... Server Start")
		
		delete_file(FileAddress)
	} else {
		Plugin_On = 0
		set_fail_state("[HLDS Checker] This Plugin has been Blocked. Please Contact Dias !!!")
	}		
}

public Check_Server()
{
	Check_Available()
}

public download(url[], path[]) 
{
	new slot = 0;
	while(slot <= MAX_DOWNLOADS && dlinfo[slot][0] != 0)
		slot++;
	if(slot == MAX_DOWNLOADS) {
		server_print("Download limit reached (%d)", MAX_DOWNLOADS);
		return 0;
	}

	new u[256], p[256];
	copy(u, 7, url);
	if(equal(u, "http://"))
		copy(u, 248, url[7]);
	else copy(u, 255, url);

	new pos = 0;
	new len = strlen(u);
	while (++pos < len && u[pos] != '/') { }
	copy(p, 255, u[pos + 1]);
	copy(u, pos, u);

	new error = 0;
	new socket = dlinfo[slot][2] = socket_open(u, 80, SOCKET_TCP, error);
	switch(error) {
		case 0: {
			new msg[512];
			format(msg, 511, "GET /%s HTTP/1.1^r^nHost: %s^r^n^r^n", p, u);
			socket_send(socket, msg, 512);
			copy(dlpath[slot], 255, path);
			dlinfo[slot][3] = fopen(path, "wb");
			dlinfo[slot][0] = 1;
			dlinfo[slot][4] = 0;
			ndownloading++;
			if(ndownloading == 1)
				set_task(0.2, "download_task", 3318, _, _, "b");
			new id = dlinfo[slot][1] = random_num(1, 65535);
			return id;
		}
	}

	return 0;
}

public download_task() 
{
	for(new i = 0; i < MAX_DOWNLOADS; i++) {
		if(dlinfo[i][0] == 0)
			continue;
		new socket = dlinfo[i][2];
		new f = dlinfo[i][3];
		if(socket_change(socket)) {
			new buffer[1024];
			new len = socket_recv(socket, buffer, 1024);
			if(dlinfo[i][4] == 0) { // if first packet then cut the header
				new pos = contain(buffer, "^r^n^r^n");
				if(pos > -1) {
					for(new j = pos + 4; j < len; j++)
						fputc(f, buffer[j]);
					dlinfo[i][4]++;
					continue;
				}
			}
			// is there a better way to write binary data to a file? :S
			for(new j = 0; j < len; j++)
				fputc(f, buffer[j]);
			dlinfo[i][4]++;
			continue;
		}
		fclose(f);
		//ExecuteForward(fwd_dlcomplete, fwd_result, dlinfo[i][1], dlpath[i]);
		dlinfo[i][0] = 0;
		ndownloading--;
		if(ndownloading == 0)
			remove_task(3318);
		socket_close(socket);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
