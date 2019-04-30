#include <amxmodx>
#include <amxmisc>
//#include <fakemeta>		// (runtime only)
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <csx>		// Used only for custom_weapon_* functions

#define CSTRIKE

#pragma semicolon 1

// If you really want to same some memory and know you won't have 32 players, you can change this.
#define MAX_PLAYERS		32
#define ADMIN_ACCESS		ADMIN_KICK

#define ANTI_LAGG		7	// Defines max calculations before a flame is spawned without check if on ground
// This is to prevent lag at really narrow ents where you could end up with 400 calculations per flame. Suggested: <= 10

#define MOLOTOV_HARD_LIMIT	10	// Maximum Molotov cocktails this code is capable of handling without bugs (per player)

#define ID_TO_INDEX(%0)		%0 - 1	// Use this macro rather than dim the arrays with 33

#define MOLOTOV_MENU_KEYS MENU_KEY_0|MENU_KEY_1|MENU_KEY_2			// Choices to look for with optional menu

// Task IDs
#define MOLOTOV_TASKID_RESET 	1000						// Set g_bReset to false after a short delay (task is TFC only)
#define MOLOTOV_TASKID_OFFSET	MOLOTOV_HARD_LIMIT
// These task IDs are dynamically set per-Molotov
#define MOLOTOV_TASKID_BASE1	2000						// By default, with 32 players, task ids
#define MOLOTOV_TASKID_BASE2	MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * MAX_PLAYERS) // from 2000 to 2959 can
#define MOLOTOV_TASKID_BASE3	MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * MAX_PLAYERS) // potentially be used used.

#define TEAM_UNASSIGNED 	0
#define TEAM_ONE		1
#define TEAM_TWO		2
#define TEAM_THREE		3
#define TEAM_FOUR		4
#define MC_TFC_PC_CIVILIAN	11	// Temporary workaround for AMXX bug 6042


new const g_PLUGIN[]  = "Molotov";
new const g_AUTHORS[] = "DynamicBits & O'Zone";
new const g_VERSION[] = "3.4";

new pEnabled;				// Pointer to molotov_enabled
new pMlRadius;				// Pointer to molotov_radius
new pFireTime;				// Pointer to molotov_firetime
new pOverride;				// Pointer to molotov_override_he
new pMFF;				// Pointer to molotov_ff
new pFriendlyFire;			// Pointer to mp_friendlyfire
new pFireDmg;				// Pointer to molotov_firedamage
new pMaxMolotovs;			// Pointer to molotov_max
#if defined DOD || defined TFC
new pTeamPlay;				// Pointer to mp_teamplay
#endif
#if defined CSTRIKE
new pBuyZone;				// Pointer to molotov_buyzone
new pMolotovMenu;			// Pointer to molotov_menu
new pPrice;				// Pointer to molotov_price

new g_msgScoreInfo;			// ScoreInfo message ID
#endif
new g_msgDeathMsg;			// DeathMsg message ID

new g_NumMolotov[MAX_PLAYERS];		// How many Molotovs each player has
#if defined CSTRIKE
new bool:g_bRestarted;			// Reset Molotovs after first round restart
#endif
new g_MaxPlayers;			// Max players (calculated at runtime to make loops more efficient)
new g_wpnMolotov;			// Custom weapon ID
new bool:g_bReset;			// Reset and stop explosions after round ends; Stop reset_tasks() from getting called once per player

new g_iFireSprite, g_iSmokeSprite[2];	// Handles to the precached sprites
new g_iMolotovOffset[MAX_PLAYERS];	// Offset used for a player's task ID
new Float:g_GameTime;

// The Pawn compiler does not optimize the DATA section. Any string that appears multiple times should be optimized with a global constant.
//   *Unused* constants do not affect the compiled size, however they create compiler warnings. (#pragma unused is a quick fix for the warnings.)
new const EVENT_ROUND_END[] = "event_round_end";
#if defined CSTRIKE
new const BUY_MOLOTOV[] = "buy_molotov";
new const WEAPON_HEGRENADE[] = "weapon_hegrenade";
#endif
#if defined DOD
new const WEAPON_HANDGRENADE[] = "weapon_handgrenade";
new const WEAPON_STICKGRENADE[] = "weapon_stickgrenade";
#endif
#if defined DOD || defined TFC
new const HUDTEXT[] = "HudText";
#endif
#if defined CSTRIKE || defined TFC
new const TEXTMSG[] = "TextMsg";
#endif

// Check for outdated tfcconst.inc file (and likely outdated AMX Mod X core/modules).
//   My patch for AMXX bug 6042 was accepted, but I think I'll wait for a new final release of AMXX to enable this check.
//   In the meantime, I created the MC_TFC_PC_CIVILIAN define.
//#if defined TFC && TFC_PC_CIVILIAN != 11	// TFC_PC_CIVILIAN was (incorrectly) 10 in older versions
//	#error TFC_PC_CIVILIAN != 11. Update your tfcconst.inc include file. Get the latest AMX Mod X snapshots at www.amxmodx.org/snapshots.php
//#endif


// Initialize the plugin
public plugin_init() {

	register_plugin(g_PLUGIN, g_VERSION, g_AUTHORS);

#if defined CSTRIKE
	register_menucmd(register_menuid("Buy Molotov Cocktail"), MOLOTOV_MENU_KEYS, "giveMolotov");

	#if defined MOLOTOV_DEBUG
	register_clcmd("molotov_menutest", "show_molotov_menu");
	#endif

	register_clcmd("molotov", BUY_MOLOTOV);
	register_clcmd("say /molotov", BUY_MOLOTOV);
	register_clcmd("say /m", BUY_MOLOTOV);
	register_clcmd("say molotov", BUY_MOLOTOV);
#endif
	register_concmd("molotov_give", "molotov_give", ADMIN_ACCESS, "<player|@all|@t|@ct|@al|@ax|@br|@b|@r|@y|@g> - Give free Molotov cocktails");
	register_concmd("molotov_override", "molotov_override", ADMIN_ACCESS, "[0|1] - Enable/disable the standard grenade override (If no arguments, show the status)");
	register_concmd("molotov_cocktail", "molotov_cocktail", ADMIN_ACCESS, "[0|1] - Enable/disable the plugin (If no arguments, show the status)");

	pEnabled = register_cvar("molotov_enabled", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pOverride = register_cvar("molotov_override_he", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pMlRadius = register_cvar("molotov_radius", "125.0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pFireTime = register_cvar("molotov_firetime", "7.0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pFireDmg = register_cvar("molotov_firedamage", "2.0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pMFF = register_cvar("molotov_ff", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pMaxMolotovs = register_cvar("molotov_max", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pFriendlyFire = register_cvar("mp_friendlyfire", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
#if defined CSTRIKE
	pBuyZone = register_cvar("molotov_buyzone", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pMolotovMenu = register_cvar("molotov_menu", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pPrice = register_cvar("molotov_price", "500", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
#endif
#if defined DOD
	pTeamPlay = register_cvar("mp_teamplay", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
#endif
#if defined TFC
	pTeamPlay = register_cvar("mp_teamplay", "21", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
#endif

	register_event("DeathMsg", "event_deathmsg", "a", "2>0");	// For some reason, arg2 (Victim) is sometimes -1 (at least in TFC on Windows HLDS with FoxBot).
#if defined CSTRIKE || defined DOD
	register_event("CurWeapon", "event_curweapon", "be", "1=1");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");	// cstrike/dod new round; So far, I haven't found a TFC equivalent
#endif
#if defined CSTRIKE
	register_event(TEXTMSG, "event_gamerestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
#endif
#if defined DOD
	register_event(HUDTEXT, EVENT_ROUND_END, "b", "1&VICTORY");	// Sent once per player on round end
#endif
#if defined TFC
	// Since TFC doesn't have any generic end of round event/message, specific messages need to be caught for certain maps.
	//   Maps that don't have traditional rounds (2fort, badlands, casbah, crossover2, cz2, ravelin, skate2, well, etc.) don't apply here.
	//   All of the default maps are accounted for. If there is demand for specific custom maps, I will add the appropriate message(s).
	new sCurrentMap[32];
	get_mapname(sCurrentMap, charsmax(sCurrentMap));
	if (!strcmp(sCurrentMap, "avanti")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=#italy_endround_win");		// Was Avanti originally called Italy?
	} else if ((!strcmp(sCurrentMap, "dustbowl")) || (!strcmp(sCurrentMap, "castleargh")) || (!strcmp(sCurrentMap, "castleargh2"))) {
		register_event(TEXTMSG, EVENT_ROUND_END, "b", "2=#dustbowl_blue_secures_one");	// Technically these are "stages," not "rounds"
		register_event(TEXTMSG, EVENT_ROUND_END, "b", "2=#dustbowl_blue_secures_two");
		//register_event(TEXTMSG, "event_round_end", "b", "2=#dustbowl_blue_caps");	// The map ends after this cap
	} else if (!strcmp(sCurrentMap, "epicenter")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=#dblmint_you_capped_flag");	// dblmint?!
	} else if (!strcmp(sCurrentMap, "flagrun")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1&you won this round!");
	} else if (!strcmp(sCurrentMap, "hunted")) {
		register_event(TEXTMSG, EVENT_ROUND_END, "b", "2=#hunted_target_killed");
	} else if (!strcmp(sCurrentMap, "push")) {
		register_event(TEXTMSG, EVENT_ROUND_END, "b", "2&_netname_scores");
	} else if (!strcmp(sCurrentMap, "rock2")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=1 . . .^n");
	} else if (!strcmp(sCurrentMap, "warpath")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=#warpath_red_wins");
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=#warpath_blue_wins");
	// ---------- Custom Maps ----------
	} else if (!strcmp(sCurrentMap, "castleargh3")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1&You have secured");		// This works for all four stages
	} else if (!strcmp(sCurrentMap, "hwguyz2")) {
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1=#2fort_you_capped_flag");
		register_event(HUDTEXT, EVENT_ROUND_END, "b", "1&Time Ran Out");
	}

	//#if defined MOLOTOV_DEBUG
	//register_event(TEXTMSG, "event_textmsg_a", "a");
	//register_event(TEXTMSG, "event_textmsg_b", "b");
	//register_event(HUDTEXT, "event_hudtext_a", "a");
	//register_event(HUDTEXT, "event_hudtext_b", "b");
	//#endif
#endif

#if defined CSTRIKE
	register_logevent(EVENT_ROUND_END, 2, "1=Round_End");
#endif

	register_forward(FM_EmitSound, "fw_emitsound");
#if defined TFC
	register_forward(FM_SetModel, "fw_setmodel_post", 1);
#endif

	g_MaxPlayers = get_maxplayers();

#if defined CSTRIKE
	g_msgScoreInfo = get_user_msgid("ScoreInfo");
#endif
	g_msgDeathMsg = get_user_msgid("DeathMsg");

	g_wpnMolotov = custom_weapon_add("molotov", 0, "molotov");	// I can hardly find any documentation or sample code for this. I have no
									//   idea if I'm using it correctly or not. I'm not even sure what it affects.
}

// These are primarily for catching messages in TFC to add custom round end triggers.
/*
#if defined MOLOTOV_DEBUG
public event_textmsg_a() {
	new sArg2[64];
	read_data(2, sArg2, charsmax(sArg2));
	
	client_print(0, print_chat, "event_textmsg_a 1(%d) 2(%s)", read_data(1), sArg2);
	console_print(0, "event_textmsg_a 1(%d) 2(%s)", read_data(1), sArg2);
}

public event_textmsg_b() {
	new sArg2[64];
	read_data(2, sArg2, charsmax(sArg2));

	client_print(0, print_chat, "event_textmsg_b 1(%d) 2(%s)", read_data(1), sArg2);
	console_print(0, "event_textmsg_b 1(%d) 2(%s)", read_data(1), sArg2);
}

public event_hudtext_a() {
	new sArg1[64];
	read_data(1, sArg1, charsmax(sArg1));

	client_print(0, print_chat, "event_hudtext_a 1(%s) 2(%d)", sArg1, read_data(1));
	console_print(0, "event_hudtext_a 1(%s) 2(%d)", sArg1, read_data(1));
}

public event_hudtext_b() {
	new sArg1[64];
	read_data(1, sArg1, charsmax(sArg1));

	client_print(0, print_chat, "event_hudtext_b 1(%s) 2(%d)", sArg1, read_data(1));
	console_print(0, "event_hudtext_b 1(%s) 2(%d)", sArg1, read_data(1));
}
#endif
*/

// Precache models and sound(s)
public plugin_precache() {

	g_iFireSprite = precache_model("sprites/flame.spr");

	g_iSmokeSprite[0] = precache_model("sprites/black_smoke3.spr");
#if defined DOD
	g_iSmokeSprite[1] = g_iSmokeSprite[0];			// steam1.spr shows a black background in dod
#else
	g_iSmokeSprite[1] = precache_model("sprites/steam1.spr");
#endif

#if defined CSTRIKE || defined DOD
	precache_model("models/molotov_new/p_molotov.mdl");
	precache_model("models/molotov_new/v_molotov.mdl");
#endif
	precache_model("models/molotov_new/w_molotov.mdl");
	precache_model("models/molotov_new/w_broken_molotov.mdl");

	precache_sound("molotov/fire.wav");
	precache_sound("molotov/explode.wav");
	precache_sound("items/9mmclip1.wav");
}

// Reset Molotovs so that a new player doesn't have any
public client_disconnected(id) {
	g_NumMolotov[ID_TO_INDEX(id)] = 0;
}

// Catch the first impact of the Molotov and start the sound/explosion
//   A Molotov cocktail should "explode" on impact, not after a set time.
public fw_emitsound(ent, channel, sample[]) {
#if defined CSTRIKE
	if (equal(sample[8], "he_bounce", 9)) {
#else
	#if defined DOD || defined TFC
	// DOD: debris/bustglass2.wav and debris/bustglass1.wav are played for breaking glass, but ent is not the grenade, so Molotovs "disappear" (This is a bug in this plugin)
	//   A fix would be to use FM_Touch or Ham_Touch or register_touch instead of FM_EmitSound
	if (equal(sample[8], "grenade_hit", 11)) {
	#endif
#endif

		new sModel[64];
		pev(ent, pev_model, sModel, charsmax(sModel));

		// Depending on where the Molotov lands, the EmitSound forward may get called 50+ times.
		// After the first hit, the model is changed to w_broke_molotov, so this code is skipped on successive calls
		if (contain(sModel, "w_molotov.mdl") != -1) {
#if defined TFC
			set_pev(ent, pev_nextthink, 99999.0);		// For TFC, this is about the only way I can stop the explosion.
#endif
			// The glass breaking sound has a low range (ATTN_STATIC) so as not to be overpowering
			emit_sound(ent, CHAN_AUTO, "debris/glass2.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_LOW);

			new Float:fFriction, Float:fVelocity[3];
			pev(ent, pev_friction, fFriction);
			fFriction *= 1.15;				// Increase friction to make it look more realistic
			set_pev(ent, pev_friction, fFriction);

			pev(ent, pev_velocity, fVelocity);
			fVelocity[0] *= 0.3;				// Decrease velocity because friction doesn't do it all
			fVelocity[1] *= 0.3;
			fVelocity[2] *= 0.3;
			set_pev(ent, pev_velocity, fVelocity);

			molotov_explode(ent);				// Replacement for normal grenade explosion

			return FMRES_SUPERCEDE;
		} else if (contain(sModel, "w_broken_molotov.mdl") != -1) {	// "mdl" is truncated because of the array size, which is OK
			return FMRES_SUPERCEDE;			// Don't play any sounds for bounces.
		}
	}
	
	return FMRES_IGNORED;
}

// Since TFC handles grenades differently, this is roughly equivalant to event_curweapon() used by cstrike and dod.
#if defined TFC
public fw_setmodel_post(ent, const model[]) {
	if (!pev_valid(ent)) {			// Check if it's a valid entity to prevent errors
		return FMRES_IGNORED;
	}

	new sClassname[32];
	pev(ent, pev_classname, sClassname, charsmax(sClassname));

	if (!get_pcvar_num(pEnabled) || !equal(sClassname, "normalgrenade")) {
		return FMRES_IGNORED;
	}

	new iOwner = pev(ent, pev_owner);
	if (!g_NumMolotov[ID_TO_INDEX(iOwner)] && !get_pcvar_num(pOverride)) {	// If no Molotovs and override is disabled, return
		return FMRES_IGNORED;
	}
	
	if (g_NumMolotov[ID_TO_INDEX(iOwner)] > 0) {	// Prevent negative values
		g_NumMolotov[ID_TO_INDEX(iOwner)]--;
	}

	set_pev(ent, pev_team, get_user_team(iOwner));
	custom_weapon_shot(g_wpnMolotov, iOwner);

	engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");

	return FMRES_HANDLED;
}
#endif

// When the player changes weapons to the Molotov, update the model
#if defined CSTRIKE || defined DOD
public event_curweapon(id) {

	if (!get_pcvar_num(pEnabled) || !is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}

	if (!g_NumMolotov[ID_TO_INDEX(id)] && !get_pcvar_num(pOverride)) {	// If no Molotovs and override is disabled, return
		return PLUGIN_CONTINUE;
	}

	new iWeaponID = get_user_weapon(id, _, _);
#if defined CSTRIKE
	if (iWeaponID != CSW_HEGRENADE) {
#else							// elseif *should* work, but there is a bug in the compiler
	#if defined DOD
	// current weapon is never set to DODW_MILLS_BOMB in this event; only DODW_HANDGRENADE/DODW_STICKGRENADE
	if ((iWeaponID != DODW_HANDGRENADE) && (iWeaponID != DODW_STICKGRENADE)) {
	#endif
#endif
		return PLUGIN_CONTINUE;
	}

	set_pev(id, pev_viewmodel2, "models/molotov_new/v_molotov.mdl");	// View model (First person)	*model2 doesn't require allocating the string
	set_pev(id, pev_weaponmodel2, "models/molotov_new/p_molotov.mdl");	// Player model (Third person)

#if defined DOD
	// I think 3 is correct, but it looks strange..
	set_pev(id, pev_weaponanim, 3);	// 0: "idle"; 1: "pullpin"; 2: "throw"; 3: "deploy"
#endif

	return PLUGIN_CONTINUE;
}
#endif

// Reset Molotovs on death
public event_deathmsg() {
#if defined MOLOTOV_DEBUG
	log_amx("[MC] ========== DeathMsg ========== K(%d) V(%d)", read_data(1), read_data(2));
#endif
	g_NumMolotov[ID_TO_INDEX(read_data(2))] = 0;
}

// cstrike only
#if defined CSTRIKE
public event_gamerestart() {
#if defined MOLOTOV_DEBUG
	log_amx("[MC] ========== Game Restart ==========");
#endif
	g_bRestarted = true;
}
#endif

// cstrike, dod, and tfc will all call this once per player on round end
public event_round_end() {
#if defined MOLOTOV_DEBUG
	log_amx("[MC] ========== Round End ==========");
#endif

	if (g_bReset == false) {
		reset_tasks();
		g_bReset = true;
#if defined TFC
		set_task(2.0, "cancel_reset", MOLOTOV_TASKID_RESET);	// TFC won't call event_new_round, so do that stuff here instead
#endif
	}
}

// cstrike and dod will call this once per round, but TFC won't.
#if defined CSTRIKE || defined DOD
public event_new_round(id) {
#if defined MOLOTOV_DEBUG
	log_amx("[MC] ========== New Round ==========");
#endif
	g_bReset = false;	// Stop blocking

	g_GameTime = get_gametime();

	if (!get_pcvar_num(pEnabled)) {
		return PLUGIN_CONTINUE;
	}

	reset_tasks();						// This probably isn't needed anymore, but it shouldn't hurt anything

#if defined CSTRIKE
	if (get_pcvar_num(pMolotovMenu)) {
		if (get_pcvar_num(pOverride)) {
			client_print(id, print_center, "Molotov cocktails will replace purchased HE grenades");
		} else {
			show_molotov_menu(id);
		}
	}

	// For cstrike only, make sure the player didn't quickly purchase a Molotov before the first actual round
	if (g_bRestarted) {
		arrayset(g_NumMolotov, 0, sizeof(g_NumMolotov));	// Reset everyone to zero Molotovs
		g_bRestarted = false;
	}
#endif

	if (get_pcvar_num(pOverride)) {
		set_molotovs();
	} else {
		reset_molotovs();
	}

	return PLUGIN_CONTINUE;
}
#endif

// Enable/Disable/Get status of override
public molotov_override(id, level, cid) {

	if (!cmd_access(id, level, cid, 1)) {		// First argument (passed to molotov_override) is optional
		return PLUGIN_HANDLED;
	}

	if (!get_pcvar_num(pEnabled)) {
		return PLUGIN_HANDLED;
	}

	if (read_argc() == 1) {				// No arguments; Display status
		console_print(id, "Override is currently %s.", get_pcvar_num(pOverride) ? "enabled" : "disabled");
		return PLUGIN_HANDLED;
	}

	new sArg[2];
	read_argv(1, sArg, charsmax(sArg));

	new iArg = str_to_num(sArg);

	if ((iArg < 0) || (iArg > 1) || (!isdigit(sArg[0]))) {	// If less than 0 or greater than 1 or not a digit
		console_print(id, "Invalid argument(%s). Valid arguments are ^"0^" and ^"1^".", sArg);
		return PLUGIN_HANDLED;
	}

	if (iArg == get_pcvar_num(pOverride)) {
		console_print(id, "Override is already %s.", iArg ? "enabled" : "disabled");
		return PLUGIN_HANDLED;
	}

	set_pcvar_num(pOverride, iArg);
	console_print(id, "Override was %s.", iArg ? "enabled" : "disabled");

#if defined CSTRIKE || defined DOD
	if (iArg) {					// If plugin is enabled (checked above) and override is enabled, set models to Molotov
		set_molotovs();
	} else {
		reset_molotovs();
	}
#endif

	return PLUGIN_HANDLED;
}

// Enable/Disable/Get status of plugin
public molotov_cocktail(id, level, cid) {
	/*if (!cmd_access(id, level, cid, 1)) {		// First argument (passed to molotov_cocktail) is optional
		return PLUGIN_HANDLED;
	}
	*/
	if (read_argc() == 1) {				// No arguments; Display status
		console_print(id, "Plugin is currently %s. (Override:%d; MFF:%d)", get_pcvar_num(pEnabled) ? "enabled" : "disabled", get_pcvar_num(pOverride), get_pcvar_num(pMFF));
		return PLUGIN_HANDLED;
	}

	new sArg[2];
	read_argv(1, sArg, charsmax(sArg));

	new iArg = str_to_num(sArg);

	if ((iArg < 0) || (iArg > 1) || (!isdigit(sArg[0]))) {	// If less than 0 or greater than 1 or not a digit
		console_print(id, "Invalid argument(%s). Valid arguments are ^"0^" and ^"1^".", sArg);
		return PLUGIN_HANDLED;
	}

	if (iArg == get_pcvar_num(pEnabled)) {
		console_print(id, "Plugin is already %s.", iArg ? "enabled" : "disabled");
		return PLUGIN_HANDLED;
	}

	set_pcvar_num(pEnabled, iArg);
	console_print(id, "Plugin was %s.", iArg ? "enabled" : "disabled");

#if defined CSTRIKE || defined DOD
	if (iArg && get_pcvar_num(pOverride)) {		// If the plugin was enabled and override is enabled, set models to Molotov
		set_molotovs();
	} else {
		reset_molotovs();
	}
#endif

	return PLUGIN_HANDLED;
}

// Handle molotov_give console command
public molotov_give(id, level, cid) {
	/*
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}
	*/

	new sArg1[16], iTarget;
	read_argv(1, sArg1, charsmax(sArg1));
#if defined MOLOTOV_DEBUG
	log_amx("[MC] molotov_give sArg1[0](%s)", sArg1[0]);
#endif
	new sAdmin[32];
	get_user_name(id, sAdmin, charsmax(sAdmin));
	new iGiveAmount = (get_pcvar_num(pMaxMolotovs) < MOLOTOV_HARD_LIMIT ? get_pcvar_num(pMaxMolotovs) : MOLOTOV_HARD_LIMIT);

	if (sArg1[0] == '@') {

		new iTargetTeam, sTeamName[32];
		new Players[MAX_PLAYERS], iNum;

		if (equali(sArg1[1], "all")) {
			iTargetTeam = 0;
		} else if (equali(sArg1[1], "t") || equali(sArg1[1], "al") || equali(sArg1[1], "br") || equali(sArg1[1], "b")) {	// CS_TEAM_T or ALLIES/British or Blue
			iTargetTeam = TEAM_ONE;
		} else if (equali(sArg1[1], "ct") || equali(sArg1[1], "ax") || equali(sArg1[1], "r")) {	// CS_TEAM_CT or AXIS or Red
			iTargetTeam = TEAM_TWO;
#if defined TFC
		} else if (equali(sArg1[1], "y")) {	// Yellow
			iTargetTeam = TEAM_THREE;
		} else if (equali(sArg1[1], "g")) {	// Green
			iTargetTeam = TEAM_FOUR;
#endif
		}

		get_players(Players, iNum, "ach");	// alive, no bots, no HLTV

		for (new i = 0; i < iNum; ++i) {
			iTarget = Players[i];

			if ((iTargetTeam == 0) || (get_user_team(iTarget) == iTargetTeam)) {
				g_NumMolotov[ID_TO_INDEX(iTarget)] = iGiveAmount;

#if defined CSTRIKE
				fm_give_item(iTarget, WEAPON_HEGRENADE);
				cs_set_user_bpammo(iTarget, CSW_HEGRENADE, iGiveAmount);
#endif
#if defined DOD
				// TODO - This sets the count, but it is not immediately updated on the HUD
				switch(get_user_team(iTarget)) {
					case ALLIES: {	// (or British)
						fm_give_item(iTarget, WEAPON_HANDGRENADE);
						dod_set_user_ammo(iTarget, DODW_HANDGRENADE, iGiveAmount);
					}
					case AXIS: {
						fm_give_item(iTarget, WEAPON_STICKGRENADE);
						dod_set_user_ammo(iTarget, DODW_STICKGRENADE, iGiveAmount);
					}
				}
#endif
#if defined TFC
				new iClass = pev(iTarget, pev_playerclass);
				if ((iClass > 0) && (iClass != TFC_PC_SCOUT) && (iClass != MC_TFC_PC_CIVILIAN)) {	// No unselected/spectator, scout, or civilian
					tfc_setbammo(iTarget, TFC_AMMO_NADE1, iGiveAmount);	// Requires 1.8.3-dev-hg185 or newer
				}
#endif
#if defined CSTRIKE
				emit_sound(iTarget, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
#endif
#if defined DOD
				emit_sound(iTarget, CHAN_WEAPON, "items/ammopickup.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);	// "items/weaponpickup.wav" could work too, I suppose
#endif
#if defined TFC
				// Shotgun pumping sound for picking up grenades... That's how TFC does it!
				emit_sound(iTarget, CHAN_WEAPON, "weapons/scock1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);	
#endif
			}
		}

		switch(iTargetTeam) {
			case 0: {
				sTeamName = "everyone";
			}
			case TEAM_ONE: {
#if defined CSTRIKE
				sTeamName = "all terrorists";
#endif
#if defined DOD
				sTeamName = "all allies";	// TODO - Allies or British
#endif
#if defined TFC
				sTeamName = "all blue";		// I *could* pull the team1_name value from the info_tfdetect entity (but only for some maps?)
#endif
			}
			case TEAM_TWO: {
#if defined CSTRIKE
				sTeamName = "all ct's";
#endif
#if defined DOD
				sTeamName = "all axis";
#endif
#if defined TFC
				sTeamName = "all red";
			}
			case TEAM_THREE: {
				sTeamName = "all yellow";
			}
			case TEAM_FOUR: {
				sTeamName = "all green";
#endif
			}
		}
		client_print(0, print_chat, "ADMIN %s has given %s %d Molotov cocktails!", sAdmin, sTeamName, iGiveAmount);

	} else {

		iTarget = cmd_target(id, sArg1, 6);

		if (!is_user_connected(iTarget) || !is_user_alive(iTarget)) {
			return PLUGIN_HANDLED;
		}

		g_NumMolotov[ID_TO_INDEX(iTarget)] = iGiveAmount;

#if defined CSTRIKE
		fm_give_item(iTarget, WEAPON_HEGRENADE);
		cs_set_user_bpammo(iTarget, CSW_HEGRENADE, iGiveAmount);
#endif
#if defined DOD
		switch(get_user_team(iTarget)) {
			case ALLIES: {	// (or British)
				fm_give_item(iTarget, WEAPON_HANDGRENADE);
				dod_set_user_ammo(iTarget, DODW_HANDGRENADE, iGiveAmount);
			}
			case AXIS: {
				fm_give_item(iTarget, WEAPON_STICKGRENADE);
				dod_set_user_ammo(iTarget, DODW_STICKGRENADE, iGiveAmount);
			}
		}
#endif
#if defined TFC
		new iClass = pev(iTarget, pev_playerclass);
		if ((iClass > 0) && (iClass != TFC_PC_SCOUT) && (iClass != MC_TFC_PC_CIVILIAN)) {	// No unselected/spectator, scout, or civilian
			tfc_setbammo(iTarget, TFC_AMMO_NADE1, iGiveAmount);				// Requires 1.8.3-dev-hg185 or newer
		}
#endif
#if defined CSTRIKE
				emit_sound(iTarget, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
#endif
#if defined DOD
				emit_sound(iTarget, CHAN_WEAPON, "items/ammopickup.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);	// "items/weaponpickup.wav" could work too, I suppose
#endif
#if defined TFC
				// Shotgun pumping sound for picking up grenades... That's how TFC does it!
				emit_sound(iTarget, CHAN_WEAPON, "weapons/scock1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);	
#endif

		client_print(iTarget, print_chat, "ADMIN %s has given you %d Molotov cocktails!", sAdmin, iGiveAmount);

	}
	return PLUGIN_HANDLED;
}

// Handle the /molotov command and molotov menu
#if defined CSTRIKE
public buy_molotov(id) {

	if (!get_pcvar_num(pEnabled)) {
		return PLUGIN_HANDLED;
	}

	//if (get_pcvar_num(pOverride)) {
	//	client_print(id, print_center, "Just buy a HE grenade and get Molotov automatically!");
	//	return PLUGIN_HANDLED;
	//}

	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}

	if (!cs_get_user_buyzone(id) && get_pcvar_num(pBuyZone)) {
		client_print(id, print_center, "Nie mozesz kupic molotova poza buyzone.");
		return PLUGIN_HANDLED;
	}

	new Float:buytime = get_cvar_float("mp_buytime") * 60.0;
	new Float:timepassed = get_gametime() - g_GameTime;

	if(floatcmp(timepassed, buytime) == 1)
		return PLUGIN_HANDLED;

	new iMoney = cs_get_user_money(id);

	if (iMoney < get_pcvar_num(pPrice)) {
		client_print(id, print_center, "Nie masz wystarczajaco duzo $, zeby kupic molotova (500$).");
		return PLUGIN_HANDLED;
	}

	// if (!g_NumMolotov[ID_TO_INDEX(id)] && user_has_weapon(id, CSW_HEGRENADE)) {
	// 	if (get_pcvar_num(pOverride)) {
	// 		g_NumMolotov[ID_TO_INDEX(id)] = cs_get_user_bpammo(id, CSW_HEGRENADE);	// If the user buys one from the VGUI menu with the override enabled, this updates g_NumMolotov
	// 	} else {
	// 		client_print(id, print_center, "You already have an HE Grenade.");
	// 		return PLUGIN_HANDLED;
	// 	}
	// }

	if (g_NumMolotov[ID_TO_INDEX(id)] == get_pcvar_num(pMaxMolotovs)) {
		if (g_NumMolotov[ID_TO_INDEX(id)] == 1) {
			client_print(id, print_center, "Juz posiadasz molotova!");
		} else {
			client_print(id, print_center, "You already have %d Molotov cocktails.", g_NumMolotov[ID_TO_INDEX(id)]);
		}
		return PLUGIN_HANDLED;
	}

	cs_set_user_money(id, iMoney - get_pcvar_num(pPrice));
	fm_give_item(id, WEAPON_HEGRENADE);
	cs_set_user_bpammo(id, CSW_HEGRENADE, ++g_NumMolotov[ID_TO_INDEX(id)]);

	//client_print_color(id, id, "^x04[CS:GO]^x01 Kupiles^x03 molotova^x01.");

	emit_sound(id, CHAN_AUTO, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return PLUGIN_HANDLED;
}
#endif

// Just before the grenade is thrown, change the model
#if defined CSTRIKE || defined DOD
public grenade_throw(id, ent, wid) {
#if defined CSTRIKE
	if (!get_pcvar_num(pEnabled) || !is_user_connected(id) || wid != CSW_HEGRENADE) {
#else
	#if defined DOD
	// current weapon can be DODW_MILLS_BOMB in this forward, but not in CurWeapon
	if (!get_pcvar_num(pEnabled) || !is_user_connected(id) || ((wid != DODW_HANDGRENADE) && (wid != DODW_STICKGRENADE) && (wid != DODW_MILLS_BOMB))) {
	#endif
#endif
		return PLUGIN_CONTINUE;
	}

	if (!g_NumMolotov[ID_TO_INDEX(id)] && !get_pcvar_num(pOverride)) {	// If no Molotovs and override is disabled, return
		return PLUGIN_CONTINUE;
	}

	if (g_NumMolotov[ID_TO_INDEX(id)] > 0) {	// Prevent negative values
		g_NumMolotov[ID_TO_INDEX(id)]--;
	}

	engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");
	set_pev(ent, pev_nextthink, 99999.0);

	custom_weapon_shot(g_wpnMolotov, id);

#if defined CSTRIKE	// dod sets the team, cstrike doesn't, TFC sets this in fw_setmodel_post()
	set_pev(ent, pev_team, get_user_team(id));
#endif

#if defined DOD
	//set_pev(id, pev_weaponanim, 0);		// 0:"idle"; 1:"pullpin"; 2:"throw"; 3:"deploy"
#endif

	return PLUGIN_HANDLED;
}
#endif

// Set up the explosion, sound, damage, etc.
molotov_explode(ent) {
	new param[7], iOrigin[3];
	new Float:fOrigin[3];
	new iOwner = pev(ent, pev_owner);
	// The broken bottle may continue to travel, but the fire will be centered around the explosion site, marked by this temporary info_target entity.
	new ent2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	pev(ent, pev_origin, fOrigin);

#if defined MOLOTOV_DEBUG
	log_amx("[MC] molotov_explode ent(%d) owner(%d) ent2(%d) -----", ent, iOwner, ent2);
#endif

	param[0] = ent;
	param[1] = ent2;
	param[2] = iOwner;
	param[3] = pev(ent, pev_team);
	param[4] = iOrigin[0] = floatround(fOrigin[0]);
	param[5] = iOrigin[1] = floatround(fOrigin[1]);
	param[6] = iOrigin[2] = floatround(fOrigin[2]);

	engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_broken_molotov.mdl");

	random_fire(iOrigin, ent2);

	// If the round ends because of damage inflicted by the initial blast (in the previous line of code), skip any further Molotov effects.
	// g_bReset may already be set, so it is safe to check it at this point.
	if (g_bReset == true) {
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);	// Remove the Molotov and later cancel the explosion
		return PLUGIN_HANDLED;
	}

	new Float:FireTime = get_pcvar_float(pFireTime);

	if (++g_iMolotovOffset[ID_TO_INDEX(iOwner)] == MOLOTOV_HARD_LIMIT) {
		g_iMolotovOffset[ID_TO_INDEX(iOwner)] = 0;
	}

	emit_sound(param[1], CHAN_AUTO, "molotov/explode.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_task(0.1, "fire_damage", MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + g_iMolotovOffset[ID_TO_INDEX(iOwner)], param, 7, "a", floatround(FireTime / 0.1, floatround_floor));
	set_task(1.0, "fire_sound", MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + g_iMolotovOffset[ID_TO_INDEX(iOwner)], param, 7, "a", floatround(FireTime) - 1);
	// This task removes the broken Molotov and "info_target" entity once molotov_firetime has expired
	set_task(FireTime, "fire_stop", MOLOTOV_TASKID_BASE3 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + g_iMolotovOffset[ID_TO_INDEX(iOwner)], param, 7);

	return PLUGIN_CONTINUE;
}

// Since there isn't a reliable new round trigger in TFC, a task is created at round end that calls this function after a delay
#if defined TFC
public cancel_reset() {
	g_bReset = false;
}
#endif

// Make fire sounds
public fire_sound(param[]) {
	emit_sound(param[1], CHAN_AUTO, "molotov/fire.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

// Remove Molotov entities
public fire_stop(param[]) {
	if (pev_valid(param[0])) { set_pev(param[0], pev_flags, pev(param[0], pev_flags) | FL_KILLME); }	// Molotov entity
	if (pev_valid(param[1])) { set_pev(param[1], pev_flags, pev(param[1], pev_flags) | FL_KILLME); }	// info_target entity
}

// Call visual effect and damage functions
public fire_damage(param[]) {

	new iOrigin[3], Float:fOrigin[3];
	iOrigin[0] = param[4];
	iOrigin[1] = param[5];
	iOrigin[2] = param[6];

	random_fire(iOrigin, param[1]);	// Visual effect

	IVecFVec(iOrigin, fOrigin);
	radius_damage2(param[2], param[3], fOrigin, get_pcvar_float(pFireDmg), get_pcvar_float(pMlRadius), DMG_BURN, false);	// Actual damage
}

// There is a radius_damage() in engine, so this was renamed.
stock radius_damage2(iAttacker, iAttackerTeam, Float:fOrigin[3], Float:fDamage, Float:fRange, iDmgType, bool:bCalc = true) {

	new Float:pOrigin[3], Float:fDist, Float:fTmpDmg;
	new i, iFF = get_pcvar_num(pMFF);

	if (iFF == -1) {			// Obey mp_friendlyfire
		iFF = get_pcvar_num(pFriendlyFire);
#if defined DOD || defined TFC
	} else if (iFF == -2) {		// Obey mp_teamplay (bit 5)
		new iTeamPlay = get_pcvar_num(pTeamPlay);
		if (iTeamPlay & (1 << 4)) {	// bit 5 (16 = teammates take no damage from explosive weaponfire)
			iFF = 0;
		}
#endif
	}	// else, leave it at 0 or 1

	while (i++ < g_MaxPlayers) {
		if (!is_user_alive(i)) {
			continue;
		}

		if (iAttackerTeam == get_user_team(i)) {
			continue;
		}

		pev(i, pev_origin, pOrigin);
		fDist = get_distance_f(fOrigin, pOrigin);

		if (fDist > fRange) {
			continue;
		}

		if (bCalc) {
			fTmpDmg = fDamage - (fDamage / fRange) * fDist;
		} else {
			fTmpDmg = fDamage;
		}

		if (floatround(fTmpDmg) > 0) {	// This eliminated the "[CSX] Invalid damage 0" error
			custom_weapon_dmg(g_wpnMolotov, iAttacker, i, floatround(fTmpDmg), 0);
		}

		if (pev(i, pev_health) <= fTmpDmg) {
			kill(iAttacker, i, iAttackerTeam);
		} else {
			fm_fakedamage(i, "molotov", fTmpDmg, iDmgType);
		}
	}
	
	// At this point, i is one higher than the highest possible player ID, so this loop only affects non-player entities
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, fOrigin, fRange))) {	// Extra parentheses fix warning 211: possibly unintended assignment
		if (pev(i, pev_takedamage)) {
			if (bCalc) {
				pev(i, pev_origin, pOrigin);
				fTmpDmg = fDamage - (fDamage / fRange) * get_distance_f(fOrigin, pOrigin);
			} else {
				fTmpDmg = fDamage;
			}
			fm_fakedamage(i, "molotov", fTmpDmg, iDmgType);
		}
	}
}

// This stock only creates the visual effect. It does not handle any damage.
// I tried using TE_FIREFIELD, but I can't make it look good in dod.
stock random_fire(Origin[3], ent) {

	static iRange, iOrigin[3], g_g, i;

	iRange = get_pcvar_num(pMlRadius);

	for (i = 1; i <= 5; i++) {

		g_g = 1;

		iOrigin[0] = Origin[0] + random_num(-iRange, iRange);
		iOrigin[1] = Origin[1] + random_num(-iRange, iRange);
		iOrigin[2] = Origin[2];
		iOrigin[2] = ground_z(iOrigin, ent);

		while (get_distance(iOrigin, Origin) > iRange) {		// If iOrigin is too far away, recalculate its position

			iOrigin[0] = Origin[0] + random_num(-iRange, iRange);
			iOrigin[1] = Origin[1] + random_num(-iRange, iRange);
			iOrigin[2] = Origin[2];

			if (++g_g >= ANTI_LAGG) {
				iOrigin[2] = ground_z(iOrigin, ent, 1);
			} else {
				iOrigin[2] = ground_z(iOrigin, ent);
			}
		}

		new rand = random_num(5, 15);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(iOrigin[0]);	// Position
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2] + rand * 5);
		write_short(g_iFireSprite);	// Sprite index
		write_byte(rand);		// Scale
		write_byte(100);		// Brightness
		message_end();
	}

	// One smoke puff for each call to random_fire, regardless of number of flames
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	write_coord(iOrigin[0]);			// Position
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 120);
	write_short(g_iSmokeSprite[random_num(0, 1)]);	// Sprite index
	write_byte(random_num(10, 30));			// Scale
	write_byte(random_num(10, 20));			// Framerate
	message_end();

}

// Stop all visual effect/physical damage tasks
stock reset_tasks() {
#if defined MOLOTOV_DEBUG
	new tmpdbgid;
#endif
	for (new i; i < g_MaxPlayers; i++) {	// for 0..31
		for (new o; o < MOLOTOV_TASKID_OFFSET; o++) {
			if (task_exists(MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * i) + o)) {
				remove_task(MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * i) + o);
#if defined MOLOTOV_DEBUG
				tmpdbgid = MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * i) + o;
				log_amx("[MC] %d exists. ----------==========----------", tmpdbgid);
#endif
			}

			if (task_exists(MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * i) + o)) {
				remove_task(MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * i) + o);
#if defined MOLOTOV_DEBUG
				tmpdbgid = MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * i) + o;
				log_amx("[MC] %d exists. ----------==========----------", tmpdbgid);
#endif
			}
			// The third task for each Molotov is not stopped so it can remove the Molotov/info_target entities.
		}
	}
}

// This function handles the killing and scoring.
//   iKillerTeam is stored because the killer can disconnect before the Molotov kills someone, leading to inaccurate scoring
stock kill(iKiller, iVictim, iKillerTeam) {

//TFC:	DeathMsg, ScoreInfo, ScoreInfo		// One ScoreInfo for killer and one for victim (order varies)
//DOD:	DeathMsg, ScoreShort, Frags		// ScoreShort=victim, Frags=killer
// CS:	DeathMsg, Money, ScoreInfo, ScoreInfo

//	Scoreboard
// CSTRIKE:	Score Deaths
// DMC:		Frags Deaths
// DOD:		Score Kills Deaths
// HL:		Score Deaths
// HLOF:	Kills Deaths
// TFC:		Score Deaths
// Ricochet:	Points
/*				----- Attacker -----		------ Victim ------
				Score	Deaths	Kills		Score	Death	Kills
	CS  kill		+1	-	N/A		-	+1	N/A
	CS  team kill		-1	-	N/A		-	+1	N/A
	CS  suicide		-1	+1	N/A		---------------------
	CS  detonate/defuse	+3	-	N/A		---------------------
	DOD kill		-	-	+1		-	+1	-
	DOD team kill		-	-	-		-	+1	-	(mp_tkpenalty handles punishment)
	DOD suicide		-	+1	-		---------------------
	DOD cap			+1	-	-		---------------------
	TFC kill		+1	-	N/A		-	+1	N/A
	TFC team kill		-1	-	N/A		-	+1	N/A
	TFC suicide		-1	+1	N/A		---------------------
	TFC cap/control		varies	-	N/A		---------------------
*/


// ------------------------------------------------------------------------------------------------- DeathMsg (CS, DOD, TFC)
	// DeathMsg - Triggers HUD message and player console message
	// DOD and CSTRIKE have different formats for DeathMsg; most other mods should be default
	message_begin(MSG_ALL, g_msgDeathMsg, {0,0,0}, 0);
	write_byte(iKiller);		// Killer ID
	write_byte(iVictim);		// Victim ID
#if defined CSTRIKE
	write_byte(0);			// Is Headshot?
#endif	
#if defined DOD
	write_byte(0);			// Weapon ID - These don't match the DODW_* constants, and a custom weapon ID does not work, so we use "world"
#else
	write_string("molotov");	// Truncated Weapon Name
#endif
	message_end();
// ------------------------------------------------------------------------------------------------- /DeathMsg (CS, DOD, TFC)

	// This block of code actually kills the user (silently - DeathMsg was already created)
	new iVictimTeam = get_user_team(iVictim);
	new iMsgBlock = get_msg_block(g_msgDeathMsg);	// Store original block value
	set_msg_block(g_msgDeathMsg, BLOCK_ONCE);	// Start blocking DeathMsg

#if defined CSTRIKE

	new iKillerFrags = get_user_frags(iKiller);
	new iVictimFrags = get_user_frags(iVictim);

	// TFC and CS scoring are mostly the same. See TFC comment. (I did most of my testing with TFC first)
	if (iKiller != iVictim) {
		fm_set_user_frags(iVictim, iVictimFrags + 1);			// Add frag that user_kill() will remove
	}

	if (iKillerTeam != iVictimTeam) {
		iKillerFrags++;							// Killer's Score = Score + 1
	} else {
		iKillerFrags--;							// Killer's Score = Score - 1
	}
	fm_set_user_frags(iKiller, iKillerFrags);

	//	CSTRIKE Results	--------------------------------------------------------------------------------------------------
						//	DeathMsg	ScoreInfoMsg	KScore	KDeath	VScore	VDeath	Internally
	//user_kill(iVictim, 0);		//	Yes		Yes (Victim)	0	0	-1	+1	Everything matches
	//user_kill(iVictim, 1);		//	Yes		Yes (Victim)	0	0	-1	+1	VScore is different internally (unchanged)
	//user_silentkill(iVictim);		// 	No		Yes (Victim)	0	0	-1	+1	VScore is different internally (unchanged)

	//dllfunc(DLLFunc_ClientKill, iVictim);	//	Yes		Yes (Victim)	0	0	-1	+1	Everything matches
	//fm_user_kill(iVictim, 0);		//	Yes		Yes (Victim)	0	0	-1	+1	Everything matches
	//fm_user_kill(iVictim, 1);		//	Yes		Yes (Victim)	0	0	 0	+1	Everything matches (fm_user_kill adds 1 to VScore)

	// user_silentkill() blocks the DeathMsg, but it doesn't update the scoreboard properly
	// fm_user_kill() updates the scoreboard properly, but generates a DeathMsg with Victim=Killer, so we have to block that.
#endif

#if defined TFC
	new iVictimFrags = tfc_get_user_frags(iVictim);

	// TFC treats every type of kill in code as a suicide and takes away 1 frag from the victim.
	//   After *extensive* testing, I found that the easiest solution is to increment the victim frags
	//   (stored in pdata) beforehand and let the game decrement it and send out ScoreInfo messages.
	//   This applies to *victims* of team kills as well as normal kills. Suicides still lose a frag.
	if (iKiller != iVictim) {
		tfc_set_user_frags(iVictim, iVictimFrags + 1);
	}

	if ((iKillerTeam == iVictimTeam) || tfc_is_team_ally(iKillerTeam, iVictimTeam)) {	// TODO: tfc_is_team_ally() is broken in AMX Mod X
		tfc_set_user_frags(iKiller, get_user_frags(iKiller) - 1);	// Killer's Score = Score - 1
	} else {
		tfc_set_user_frags(iKiller, get_user_frags(iKiller) + 1);	// Killer's Score = Score + 1
	}

	//	TFC Results	--------------------------------------------------------------------------
						//	DeathMsg	ScoreInfoMsg	VFrag	Internally
	//user_kill(iVictim, 0);		//	Yes		Yes		-1	Everything matches
	//user_kill(iVictim, 1);		//	Yes		Yes		 0	VFrags doesn't match
	//user_silentkill(iVictim);		// 	No		Yes		 0	VFrags doesn't match

	//dllfunc(DLLFunc_ClientKill, iVictim);	//	Yes		Yes		-1	Everything matches
	//fm_user_kill(iVictim, 0);		//	Yes		Yes		-1	Everything matches
	//fm_user_kill(iVictim, 1);		//	Yes		Yes		-1	Everything matches

#endif

	// DOD just works..
	//	DOD Results	--------------------------------------------------------------------------------------------------
						//	DeathMsg	ScoreShortMsg	FragMsg	KFrag	VDeath	VFrag	Internally
	//user_kill(iVictim, 0);		//	Yes		Yes		N	0	+1	 0	Everything matches
	//user_kill(iVictim, 1);		//	Yes		Yes		N	0	+1	 0	Everything matches
	//user_silentkill(iVictim);		// 	No		Yes		N	0	+1	 0	Everything matches

	//dllfunc(DLLFunc_ClientKill, iVictim);	//	Yes		Yes		N	0	+1	 0	Everything matches
	//fm_user_kill(iVictim, 0);		//	Yes		Yes		N	0	+1	 0	Everything matches
	//fm_user_kill(iVictim, 1);		//	Yes		Yes		N	0	+1	+1	OK, but VFrags shouldn't be changed

	user_kill(iVictim, 0);
	set_msg_block(g_msgDeathMsg, iMsgBlock);		// Stop blocking DeathMsg

	//CSTRIKE client console messages:
	//Kill	"Player1 killed [P0D]M0rbid Desire (2) with molotov"
	//TK	"Player1 killed [POD]Kate_Winslet (2) with molotov"
	//Self	"Player1 killed self with molotov"

	//DOD client console messages: (DOD uses indexes instead of strings and a custom weapon name can't be sent to the player console)
	//Kill	"Player1 killed Sgt.Moving_Target with world"
	//TK	"Player1 killed his teammate Sgt.dontSHOOTiJUSTwannaTALK with world"
	//Self	"Player1 killed self"

	//TFC client console messages:
	//Kill	"Player1 killed [FoX]JesseJames with molotov"
	//TK	"Player1 killed [FoX]Barry with molotov"
	//Self	"Player1 killed self with molotov"


	// I'm not really sure if this does anything, but it seems to match the Valve wiki: https://developer.valvesoftware.com/wiki/HL_Log_Standard
	new sVictim[32], sVictimAuth[35], sVictimTeam[32];
	get_user_name(iVictim, sVictim, charsmax(sVictim));
	get_user_authid(iVictim, sVictimAuth, charsmax(sVictimAuth));
	get_user_team(iVictim, sVictimTeam, charsmax(sVictimTeam));	// TERRORIST, CT, Allies, Axis, #Dustbowl_team1 (Attackers/Blue), #Dustbowl_team2 (Defenders/Red)
	if (iKiller == iVictim) {
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"molotov^"", sVictim, get_user_userid(iVictim), sVictimAuth, sVictimTeam);
	} else if (is_user_connected(iKiller)) {
		new sKiller[32], sKillerAuth[35], sKillerTeam[32];
		get_user_name(iKiller, sKiller, charsmax(sKiller));
		get_user_authid(iKiller, sKillerAuth, charsmax(sKillerAuth));
		get_user_team(iKiller, sKillerTeam, charsmax(sKillerTeam));
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"molotov^"", sKiller, get_user_userid(iKiller), sKillerAuth, sKillerTeam, sVictim, get_user_userid(iVictim), sVictimAuth, sVictimTeam);
	}
	// TODO: There currently isn't a log message for a kill by a disconnected player. The wiki doesn't show the expected format.

// ------------------------------------------------------------------------------------------------- Money (CS)
#if defined CSTRIKE
	new iMoney;
	if (iKillerTeam == iVictimTeam) {
		iMoney = cs_get_user_money(iKiller) - 3300;			// TODO - $1500 hostage kill penalty
		cs_set_user_money(iKiller, iMoney < 0 ? 0 : iMoney);
	} else {
		iMoney = cs_get_user_money(iKiller) + 300;
		cs_set_user_money(iKiller, iMoney > 16000 ? 16000 : iMoney);
	}
#endif
// ------------------------------------------------------------------------------------------------- /Money (CS)
// ------------------------------------------------------------------------------------------------- ScoreInfo (CS and TFC)
	// ScoreInfo - Updates scoreboard on clients (actual values are changed elsewhere)
	// TFC - ScoreInfo messages are sent automatically after killing a player.
	// CS - ScoreInfo is sent automatically for the victim, but not killer.
#if defined CSTRIKE
	message_begin(MSG_ALL, g_msgScoreInfo);		// Killer ScoreInfo
	write_byte(iKiller);
	write_short(iKillerFrags);
	write_short(get_user_deaths(iKiller));
	write_short(0);
	write_short(iKillerTeam);
	message_end();
#endif
// ------------------------------------------------------------------------------------------------- /ScoreInfo (CS and TFC)

#if defined DOD		
// ------------------------------------------------------------------------------------------------- ScoreShort (DOD)
	// ScoreShort is sent by user_kill()
// ------------------------------------------------------------------------------------------------- /ScoreShort (DOD)
// ------------------------------------------------------------------------------------------------- Frags (DOD)
	if (iKillerTeam != iVictimTeam) {	// Only give a frag if the player killed was an enemy (not suicide or TK)
		dod_set_user_kills(iKiller, dod_get_user_kills(iKiller) + 1, 1);	// These natives seem to work properly.
	}
// ------------------------------------------------------------------------------------------------- /Frags (DOD)
#endif
}

// Attempt to drop the passed coordinates to ground level
stock ground_z(iOrigin[3], ent, skip = 0, iRecursion = 0) {

	iOrigin[2] += random_num(5, 80);

	if (!pev_valid(ent)) {
		return iOrigin[2];
	}

	new Float:fOrigin[3];
	IVecFVec(iOrigin, fOrigin);
	set_pev(ent, pev_origin, fOrigin);
	engfunc(EngFunc_DropToFloor, ent);

	if (!skip && !engfunc(EngFunc_EntIsOnFloor, ent)) {
		if (iRecursion >= ANTI_LAGG) {
			skip = 1;
		}

		return ground_z(iOrigin, ent, skip, ++iRecursion);
	}

	pev(ent, pev_origin, fOrigin);

	return floatround(fOrigin[2]);
}

// If plugin or override is disabled, reset Molotov models to original models
#if defined CSTRIKE || defined DOD
stock reset_molotovs() {
	new ent = g_MaxPlayers;
#if defined CSTRIKE
	// TODO - My limited testing showed this code is pointless.
	//   It has no negative effect, so I'm leaving it for the 3.30 release.
	//   (I don't think "model" is a valid parameter.)
	new iOwner;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/molotov_new/w_molotov.mdl"))) {
		iOwner = pev(ent, pev_owner);
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "reset_molotovs - found one Molotov! Owner(%d)", iOwner);
#endif
		// If plugin is disabled or player owns no molotovs, reset their model
		if (!get_pcvar_num(pEnabled) || !g_NumMolotov[ID_TO_INDEX(iOwner)]) {
			engfunc(EngFunc_SetModel, ent, "models/w_hegrenade.mdl");
		}
	}
#endif
#if defined DOD
	new iOwner;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/molotov_new/w_molotov.mdl"))) {
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "reset_molotovs - found one Molotov!");
#endif

		iOwner = pev(ent, pev_owner);
		if (iOwner) {
			switch(get_user_team(iOwner)) {
				case ALLIES: {	// (or British)
					engfunc(EngFunc_SetModel, ent, "models/w_grenade.mdl");		// Mills is the same model, so this is probably fine
				}
				case AXIS: {
					engfunc(EngFunc_SetModel, ent, "models/w_stick.mdl");
				}
			}
		}
	}
#endif

}
#endif

// Mods that show the model before it is thrown need the model set (I think)
#if defined CSTRIKE || defined DOD
stock set_molotovs() {
	new ent = g_MaxPlayers;
#if defined CSTRIKE
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/w_hegrenade.mdl"))) {
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "set_molotovs - found one hegrenade!");
#endif
		engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");
	}
#endif
#if defined DOD
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/w_grenade.mdl"))) {
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "set_molotovs - found one grenade!");
#endif
		engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");
	}
	ent = g_MaxPlayers;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/w_stick.mdl"))) {
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "set_molotovs - found one stick!");
#endif
		engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");
	}
	ent = g_MaxPlayers;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "model", "models/w_mills.mdl"))) {
#if defined MOLOTOV_DEBUG
		client_print(0, print_chat, "set_molotovs - found one Mills!");
#endif
		engfunc(EngFunc_SetModel, ent, "models/molotov_new/w_molotov.mdl");
	}
#endif

}
#endif

// Show optional buy menu
#if defined CSTRIKE
public show_molotov_menu(id) {
	new menu[128];
	formatex(menu, charsmax(menu), "Buy Molotov Cocktail ($%d)?^n^n1. Yes^n2. No^n^n0. Exit", get_pcvar_num(pPrice));

	// This shows the menu for 30 seconds, I tried first with get_cvar_num("mp_buytime")*60 , but it didn't work well
	// when using 0.5 as mp_buytime. If you want to, just change the time below.
	show_menu(id, MOLOTOV_MENU_KEYS, menu, 30);

	return PLUGIN_HANDLED;
}
#endif

// Our menu function will get the player id and the key they pressed
#if defined CSTRIKE
public giveMolotov(id, key) {

	//key will start at zero
	switch(key) {
		case 0: buy_molotov(id);
		//I don't think these messages are necessary.
		//case 1: client_print(id, print_center, "You have chosen not to buy a Molotov cocktail");
		//default: client_print(id, print_center, "You have chosen to exit the Molotov menu");
	}
}
#endif

// Set user frags (score) in TFC
#if defined TFC
stock tfc_set_user_frags(iIndex, iNewFrags) {
	if (is_linux_server()) {
		set_pdata_int(iIndex, 76, iNewFrags);		// real_frags = 76 (on Linux)		Required!
	} else {
		set_pdata_int(iIndex, 77, iNewFrags);		// real_frags = 77 (on Windows)		Required?
	}	// Is there a mac version?

	// As far as I can tell, real_frags is what should be set, and something copies it to m_iClientFrags.
	//set_pdata_int(iIndex, 643, iNewFrags);		// m_iClientFrags = 643 (on Linux/Windows)

	// Sometimes this is required, sometimes it isn't. I think what is happening is that in
	//   the cases it doesn't seem to be required, pev_frags is getting updated internally.
	set_pev(iIndex, pev_frags, float(iNewFrags));

#if defined MOLOTOV_DEBUG
	mydump(iIndex, 65, 85);
	mydump(iIndex, 635, 655);
#endif
}
#endif

// Return a user's frags, and verify that the TFC offsets haven't changed
#if defined TFC
stock tfc_get_user_frags(iIndex) {
	new iOffset = (is_linux_server() ? 76 : 77);	// real_frags = 76 (Linux), 77 (Windows)
	new iFrags = get_user_frags(iIndex);

	// This code is the easiest way to detect a change in the offsets and help prevent annoying troubleshooting.
	// get_user_frags seems to always return the correct value.
	if (iFrags != get_pdata_int(iIndex, iOffset)) {
		client_print(0, print_chat, "OFFSET CHANGED! get_user_frags(%d):%d; get_pdata_int(%d, %d):%d; Contact plugin author!", iIndex, iFrags, iIndex, iOffset, get_pdata_int(iIndex, iOffset));
		console_print(0, "WARNING! get_user_frags != real_frags! Contact plugin author!!!!!!!!!!!!!!!!!!!!");
	}

	return get_pdata_int(iIndex, iOffset);
}
#endif

// This won't be compiled unless MOLOTOV_DEBUG is set (and only for TFC)
#if defined TFC
stock mydump(iIndex, iStart, iEnd) {

	new sLine[512];
	new FILE[] = "addons/amxmodx/logs/pdatadump.log";

	new sClassname[64];
	entity_get_string(iIndex, EV_SZ_classname, sClassname, charsmax(sClassname));
	format(sLine, charsmax(sLine), "Starting dump of entity %s %d", sClassname, iIndex);
	console_print(1, "%s to file %s", sLine, FILE);
	if (!write_file(FILE, sLine)) {
		console_print(1, "Error dumping to %s!", FILE);
		return PLUGIN_HANDLED;
	}

	for (new i = iStart; i <= iEnd; i++) {
		format(sLine, charsmax(sLine), "%s %d: Offset %d:^t%d^t%f", sClassname, iIndex, i, get_pdata_int(iIndex, i), get_pdata_float(iIndex, i));
		if (!write_file(FILE, sLine)) {
			console_print(1, "Error dumping to %s!", FILE);
			return PLUGIN_HANDLED;
		}
	}

	console_print(1, "Dump done. Check %s!", FILE);

	return 1;
}
#endif
