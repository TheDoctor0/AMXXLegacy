#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <nvault>
#include <sqlx>
#include <fun>
#include <unixtime>

#define PLUGIN  "Ultimate Stats"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

#define CSW_SHIELD          2

#define WEAPONS_END         CSW_P90 + 1
#define HIT_END             HIT_RIGHTLEG + 1
#define STATS_END           STATS_RANK + 1
#define KILLER_END          KILLER_DISTANCE + 1

#define MAX_MONEY           16000

#define TASK_TIME           6701
#define TASK_HUD            7834

#define get_bit(%2,%1)      (%1 & (1<<(%2&31)))
#define set_bit(%2,%1)      (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1)      (%1 &= ~(1 <<(%2&31)))

#define is_user_valid(%1)   (1 <= %1 <= MAX_PLAYERS)
#define is_weapon_valid(%1) (0 < %1 < WEAPONS_END)

#define get_elo(%1,%2)      (1.0 / (1.0 + floatpower(10.0, ((%1 - %2) / 400.0))))
#define set_elo(%1,%2,%3)   (%1 + 20.0 * (%2 - %3))

#define stat(%1)            (%1 - HIT_END - 2)

new const body[][] = { "cialo", "glowa", "klatka piersiowa", "brzuch", "lewe ramie", "prawe ramie", "lewa noga", "prawa noga" };

// new const cmdStats[][] = { "stats", "say /stats", "say_team /stats" };
// new const cmdScore[][] = { "score", "say /score", "say_team /score" };
// new const cmdReport[][] = { "report", "say /report", "say_team /report" };
// native add_user_kill(id, weapon = 0);
// rename get_user_total_time to get_user_gametime
// remove stat()

enum _:cmds { CMD_MENU, CMD_HP, CMD_ME, CMD_STATSME, CMD_RANK, CMD_RANKSTATS, CMD_TOP15, CMD_TOPME, CMD_TIME, CMD_TIMEADMIN, CMD_TIMETOP15, CMD_STATS, CMD_STATSTOP15, CMD_MEDALS, CMD_MEDALSTOP15, CMD_SOUNDS };
enum _:forwards { FORWARD_DAMAGE, FORWARD_DEATH, FORWARD_ASSIST, FORWARD_REVENGE, FORWARD_PLANTING, FORWARD_PLANTED, FORWARD_EXPLODE, FORWARD_DEFUSING, FORWARD_DEFUSED, FORWARD_THROW, FORWARD_LOADED };
enum _:statsData { STATS_KILLS = HIT_END, STATS_DEATHS, STATS_HS, STATS_TK, STATS_SHOTS, STATS_HITS, STATS_DAMAGE, STATS_RANK };
enum _:killerData { KILLER_ID = STATS_END, KILLER_HEALTH, KILLER_ARMOR, KILLER_TEAM, KILLER_DISTANCE };
enum _:winers { THIRD, SECOND, FIRST };
enum _:save { NORMAL = -1, ROUND, FINAL, MAP_END };
enum _:types { STATS, ROUND_STATS, WEAPON_STATS, WEAPON_ROUND_STATS, ATTACKER_STATS, VICTIM_STATS };
enum _:formulas { FORMULA_KD, FORMULA_KILLS, FORMULA_KILLS_HS, FORMULA_ELO, FORMULA_TIME };
enum _:playerData{ BOMB_DEFUSIONS = STATS_END, BOMB_DEFUSED, BOMB_PLANTED, BOMB_EXPLODED, ADMIN, SPECT, HUD_INFO, PLAYER_ID,  FIRST_VISIT, LAST_VISIT, TIME, CONNECTS, ASSISTS, REVENGE, REVENGES, ROUNDS, ROUNDS_CT, ROUNDS_T, WIN_CT,
	WIN_T, BRONZE, SILVER, GOLD, MEDALS, BEST_STATS, BEST_KILLS, BEST_DEATHS, BEST_HS, CURRENT_STATS, CURRENT_KILLS, CURRENT_DEATHS, CURRENT_HS, Float:ELO_RANK, NAME[32], SAFE_NAME[64], STEAMID[32], IP[16] };

new const commands[cmds][][] = {
	{ "cmd_menu", "\yMenu \rStatystyk", "menustaty", "say /menustaty", "say_team /menustaty", "say /statsmenu", "say_team /statsmenu", "say /statymenu", "say_team /statymenu", "", "" },
	{ "cmd_hp", "\wHP", "hp", "say /hp", "say_team /hp", "", "", "", "", "", "" },
	{ "cmd_me", "\wMe", "me", "say /me", "say_team /me", "", "", "", "", "", "" },
	{ "cmd_statsme", "\wStats \rMe", "statsme", "say /statsme", "say_team /statsme", "", "", "", "", "", "" },
	{ "cmd_rank", "\wRank", "rank", "say /rank", "say_team /rank", "", "", "", "", "", "" },
	{ "cmd_rankstats", "\wRank \rStats", "rankstats", "say /rankstats", "say_team /rankstats", "", "", "", "", "", "" },
	{ "cmd_top15", "\wTop15", "top15", "say /top15", "say_team /top15", "", "", "", "", "", "" },
	{ "cmd_topme", "\wTop \rMe", "topme", "say /topme", "say_team /topme", "", "", "", "", "", "" },
	{ "cmd_time", "\wCzas \rGry", "czas", "say /czas", "say_team /czas", "say /time", "say_team /time", "", "", "", "" },
	{ "cmd_time_admin", "\wCzas \rAdminow", "czasadmin", "say /czasadmin", "say_team /czasadmin", "say /timeadmin", "say_team /timeadmin", "say /adminczas", "say_team /adminczas", "", "" },
	{ "cmd_time_top15", "\wCzas \rTop15", "czastop15", "say /ctop15", "say_team /ctop15", "say /czastop15", "say_team /czastop15", "say /ttop15", "say_team /ttop15", "say /topczas", "say_team /topczas" },
	{ "cmd_stats", "\wNajlepsze \rStaty", "najlepszestaty", "say /staty", "say_team /staty", "say /beststats", "say_team /beststats", "say /najlepszestaty", "say_team /najlepszestaty", "", "" },
	{ "cmd_stats_top15", "\wStaty \rTop15", "statytop15", "say /stop15", "say_team /stop15", "say /statstop15", "say_team /statstop15", "say /statytop15", "say_team /statytop15", "say /topstaty", "say_team /topstaty" },
	{ "cmd_medals", "\wZdobyte \rMedale", "medale", "say /medal", "say_team /medal", "say /medale", "say_team /medale", "say /medals", "say_team /medals", "", "" },
	{ "cmd_medals_top15", "\wMedale \rTop15", "medaletop15", "say /mtop15", "say_team /mtop15", "say /medalstop15", "say_team /medalstop15", "say /medaletop15", "say_team /medaletop15", "say /topmedale", "say_team /topmedale" },
	{ "cmd_sounds", "\wUstawienia \rDziekow", "dzwieki", "say /dzwiek", "say_team /dzwiek", "say /dzwieki", "say_team /dzwieki", "say /sound", "say_team /sound", "", "" },
};

new playerStats[MAX_PLAYERS + 1][playerData], playerRStats[MAX_PLAYERS + 1][playerData], playerWStats[MAX_PLAYERS + 1][WEAPONS_END][STATS_END], playerWRStats[MAX_PLAYERS + 1][WEAPONS_END][STATS_END],
	playerAStats[MAX_PLAYERS + 1][MAX_PLAYERS + 1][KILLER_END], playerVStats[MAX_PLAYERS + 1][MAX_PLAYERS + 1][KILLER_END], weaponsAmmo[MAX_PLAYERS + 1][WEAPONS_END], statsForwards[forwards], statsNum,
	Handle:sql, Handle:connection, bool:sqlConnection, bool:oneAndOnly, bool:block, bool:mapChange, round, sounds, statsLoaded, weaponStatsLoaded, visit, soundMayTheForce, soundOneAndOnly, soundPrepare,
	soundHumiliation, soundLastLeft, ret, rankSaveType, rankFormula, weaponRankFormula, assistEnabled, revengeEnabled, assistMinDamage, assistMoney, revengeMoney, assistInfoEnabled, revengeInfoEnabled,
	leaderInfoEnabled, killerInfoEnabled, victimInfoEnabled, medalsEnabled, prefixEnabled, xvsxEnabled, soundsEnabled, hpEnabled, meEnabled, statsMeEnabled, rankEnabled, rankStatsEnabled, top15Enabled,
	topMeEnabled, spectRankEnabled, victimHudEnabled, attackerHudEnabled, hsHudEnabled, disruptiveHudEnabled, bestScoreHudEnabled, planter, defuser, hudSpectRank, hudEndRound;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	create_cvar("ultimate_stats_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("ultimate_stats_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("ultimate_stats_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("ultimate_stats_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED);

	bind_pcvar_num(create_cvar("ultimate_stats_rank_save_type", "0"), rankSaveType); // 0 - nick | 1 - steamid | 2 - ip
	bind_pcvar_num(create_cvar("ultimate_stats_rank_formula", "0"), rankFormula); // 0 - kills- deaths - tk | 1 - kills | 2 - kills + hs | 3 - elo rank (skill) | 4 - played time
	bind_pcvar_num(create_cvar("ultimate_stats_weapon_rank_formula", "0"), weaponRankFormula); // 0 - kills- deaths - tk | 1 - kills | 2 - kills + hs
	bind_pcvar_num(create_cvar("ultimate_stats_assist_enabled", "1"), assistEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_revenge_enabled", "0"), revengeEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_assist_min_damage", "65"), assistMinDamage);
	bind_pcvar_num(create_cvar("ultimate_stats_assist_money", "300"), assistMoney);
	bind_pcvar_num(create_cvar("ultimate_stats_revenge_money", "300"), revengeMoney);
	bind_pcvar_num(create_cvar("ultimate_stats_assist_info_enabled", "1"), assistInfoEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_revenge_info_enabled", "1"), revengeInfoEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_leader_info_enabled", "1"), leaderInfoEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_killer_info_enabled", "1"), killerInfoEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_victim_info_enabled", "1"), victimInfoEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_medals_enabled", "1"), medalsEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_prefix_enabled", "1"), soundsEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_xvsx_enabled", "1"), xvsxEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_sounds_enabled", "1"), soundsEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_hp_enabled", "1"), hpEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_me_enabled", "1"), meEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_statsme_enabled", "1"), statsMeEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_rank_enabled", "1"), rankEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_rankstats_enabled", "1"), rankStatsEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_top15_enabled", "1"), top15Enabled);
	bind_pcvar_num(create_cvar("ultimate_stats_topme_enabled", "1"), topMeEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_spectrank_enabled", "1"), spectRankEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_victim_hud_enabled", "1"), victimHudEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_attacker_hud_enabled", "1"), attackerHudEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_hs_hud_enabled", "1"), hsHudEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_disruptive_hud_enabled", "1"), disruptiveHudEnabled);
	bind_pcvar_num(create_cvar("ultimate_stats_bestscore_hud_enabled", "1"), bestScoreHudEnabled);

	for (new i; i < sizeof(commands); i++) {
		for (new j = 2; j < sizeof(commands[]); j++) {
			if (commands[i][j][0]) register_clcmd(commands[i][j], commands[i][0]);
		}
	}

	register_clcmd("say", "weapons_top15_handle");
	register_clcmd("say_team", "weapons_top15_handle");

	statsForwards[FORWARD_DAMAGE] = CreateMultiForward("client_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_DEATH] =  CreateMultiForward("client_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_ASSIST] = CreateMultiForward("client_assist", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_REVENGE] = CreateMultiForward("client_revenge", ET_IGNORE, FP_CELL, FP_CELL);
	statsForwards[FORWARD_PLANTING] = CreateMultiForward("bomb_planting", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_PLANTED] = CreateMultiForward("bomb_planted", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_EXPLODE] = CreateMultiForward("bomb_explode", ET_IGNORE, FP_CELL, FP_CELL);
	statsForwards[FORWARD_DEFUSING] = CreateMultiForward("bomb_defusing", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_DEFUSED] = CreateMultiForward("bomb_defused", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_THROW] = CreateMultiForward("grenade_throw", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_LOADED] = CreateMultiForward("stats_loaded", ET_IGNORE, FP_CELL);

	RegisterHam(Ham_Spawn, "player", "player_spawned", 1);

	register_logevent("round_end", 2, "1=Round_End");
	register_logevent("planted_bomb", 3, "2=Planted_The_Bomb");
	register_logevent("defused_bomb", 3, "2=Defused_The_Bomb");
	register_logevent("defusing_bomb", 3, "2=Begin_Bomb_Defuse_Without_Kit");
	register_logevent("defusing_bomb", 3, "2=Begin_Bomb_Defuse_With_Kit");
	register_logevent("explode_bomb", 6, "3=Target_Bombed");

	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "round_restart", "a", "2&#Game_C", "2&#Game_w");
	register_event("TextMsg", "spectator_mode", "bd", "2&ec_Mod")
	register_event("SendAudio", "win_t" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "win_ct", "a", "2&%!MRAD_ctwin");
	register_event("23", "planted_bomb_no_round", "a", "1=17", "6=-105", "7=17");
	register_event("BarTime", "planting_bomb", "be", "1=3");
	register_event("CurWeapon", "cur_weapon", "b" ,"1=1");
	register_event("Damage", "damage", "b", "2!0");
	register_event("StatusValue", "show_rank", "bd", "1=2");

	register_forward(FM_SetModel, "set_model", true);

	register_message(SVC_INTERMISSION, "message_intermission");
	register_message(get_user_msgid("SayText"), "say_text");

	hudEndRound = CreateHudSyncObj();
	hudSpectRank = CreateHudSyncObj();

	sounds = nvault_open("stats_sound");
}

public plugin_natives()
{
	register_library("ultimatestats");

	register_native("get_statsnum", "native_get_statsnum");
	register_native("get_stats", "native_get_stats");
	register_native("get_stats2", "native_get_stats2");
	register_native("get_user_stats", "native_get_user_stats");
	register_native("get_user_stats2", "native_get_user_stats2");
	register_native("get_user_wstats", "native_get_user_wstats");
	register_native("get_user_rstats", "native_get_user_rstats");
	register_native("get_user_wrstats", "native_get_user_wrstats");
	register_native("get_user_vstats", "native_get_user_vstats");
	register_native("get_user_astats", "native_get_user_astats");
	register_native("get_user_total_time", "native_get_user_total_time");
	register_native("get_user_elo", "native_get_user_elo");
	register_native("add_user_elo", "native_add_user_elo");
	register_native("reset_user_wstats", "native_reset_user_wstats");
}

public plugin_cfg()
{
	new configPath[64];

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/ultimate_stats.cfg", configPath);
	server_exec();

	sql_init();
}

public plugin_precache()
{
	precache_sound("misc/maytheforce.wav");
	precache_sound("misc/oneandonly.wav");
	precache_sound("misc/prepare.wav");
	precache_sound("misc/humiliation.wav");
	precache_sound("misc/lastleft.wav");
}

public plugin_end()
{
	SQL_FreeHandle(sql);
	SQL_FreeHandle(connection);
}

public client_connect(id)
{
	clear_stats(id);

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);

	rem_bit(id, statsLoaded);
	rem_bit(id, weaponStatsLoaded);
	rem_bit(id, visit);
}

public client_authorized(id)
	playerStats[id][ADMIN] = get_user_flags(id) & ADMIN_BAN ? 1 : 0;

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;

	get_user_name(id, playerStats[id][NAME], charsmax(playerStats[][NAME]));
	get_user_authid(id, playerStats[id][STEAMID], charsmax(playerStats[][STEAMID]));
	get_user_ip(id, playerStats[id][IP], charsmax(playerStats[][IP]), 1);

	sql_safe_string(playerStats[id][NAME], playerStats[id][SAFE_NAME], charsmax(playerStats[][SAFE_NAME]));

	set_task(0.1, "load_stats", id);
}

public client_disconnected(id)
{
	remove_task(id);
	remove_task(id + TASK_TIME);

	save_stats(id, mapChange ? MAP_END : FINAL);
}

public amxbans_admin_connect(id)
	client_authorized(id, "");

public player_spawned(id)
	if (!get_bit(id, visit)) set_task(3.0, "check_time", id + TASK_TIME);

public check_time(id)
{
	id -= TASK_TIME;

	if (!get_bit(id, visit)) return;

	if (!get_bit(id, statsLoaded)) {
		set_task(3.0, "check_time", id + TASK_TIME);

		return;
	}

	set_bit(id, visit);

	new time = get_systime(), visitYear, Year, visitMonth, Month, visitDay, Day, visitHour, visitMinutes, visitSeconds;

	UnixToTime(time, visitYear, visitMonth, visitDay, visitHour, visitMinutes, visitSeconds);

	client_print_color(id, id, "* Aktualnie jest godzina^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. *", visitHour, visitMinutes, visitSeconds, visitDay, visitMonth, visitYear);

	if (playerStats[id][FIRST_VISIT] == playerStats[id][LAST_VISIT]) client_print_color(id, id, "* To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry! *");
	else {
		UnixToTime(playerStats[id][LAST_VISIT], Year, Month, Day, visitHour, visitMinutes, visitSeconds);

		if (visitYear == Year && visitMonth == Month && visitDay == Day) client_print_color(id, id, "* Twoja ostatnia wizyta miala miejsce^x03 dzisiaj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry! *", visitHour, visitMinutes, visitSeconds);
		else if (visitYear == Year && visitMonth == Month && (visitDay - 1) == Day) client_print_color(id, id, "* Twoja ostatnia wizyta miala miejsce^x03 wczoraj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry! *", visitHour, visitMinutes, visitSeconds);
		else client_print_color(id, id, "* Twoja ostatnia wizyta:^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry! *", visitHour, visitMinutes, visitSeconds, Day, Month, Year);
	}
}

public round_end()
{
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id)) continue;

		if (get_user_team(id) == 1 || get_user_team(id) == 2) {
			playerStats[id][ROUNDS]++;
			playerStats[id][get_user_team(id) == 1 ? ROUNDS_T : ROUNDS_CT]++;
		}

		save_stats(id, ROUND);
	}

	set_task(0.5, "show_hud_info", TASK_HUD);
}

public first_round()
	block = false;

public round_restart()
	round = 0;

public new_round()
{
	remove_task(TASK_HUD);

	show_hud_info(true);

	clear_stats();

	planter = 0;
	defuser = 0;

	oneAndOnly = false;

	if (!round) {
		set_task(30.0, "first_round");

		block = true;
	}

	round++;

	if (!leaderInfoEnabled) return;

	new bestId, bestFrags, tempFrags, bestDeaths, tempDeaths;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) continue;

		tempFrags = get_user_frags(id);
		tempDeaths = get_user_deaths(id);

		if (tempFrags > 0 && (tempFrags > bestFrags || (tempFrags == bestFrags && tempDeaths < bestDeaths))) {
			bestFrags = tempFrags;
			bestDeaths = tempDeaths;
			bestId = id;
		}
	}

	if (is_user_connected(bestId)) client_print_color(0, bestId, "*^x03 %s^x01 prowadzi w grze z^x04 %i^x01 zabojstwami i^x04 %i^x01 zgonami. *", playerStats[bestId][NAME], bestFrags, bestDeaths);
}

public spectator_mode(id)
{
	new spectData[12];

	read_data(2, spectData, charsmax(spectData));

	playerStats[id][SPECT] = (spectData[10] == '2');
}

public show_rank(id)
{
	if (!spectRankEnabled || !playerStats[id][SPECT]) return;

	new player = read_data(2);

	if (is_user_connected(player)) {
		set_hudmessage(255, 255, 255, 0.02, 0.96, 2, 0.05, 0.1, 0.01, 3.0, -1);

		ShowSyncHudMsg(id, hudSpectRank, "Ranking %s wynosi %d na %d", playerStats[player][NAME], playerStats[player][STATS_RANK], statsNum);
	}
}

public planting_bomb(planter)
	ExecuteForward(statsForwards[FORWARD_PLANTING], ret, planter);

public planted_bomb()
{
	planter = get_loguser_index();

	playerStats[planter][BOMB_PLANTED]++;

	ExecuteForward(statsForwards[FORWARD_PLANTED], ret, planter);

	if (!soundsEnabled) return;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if(!is_user_connected(i)) continue;

		if(((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 2)) && get_bit(i, soundPrepare)) client_cmd(i, "spk misc/prepare");
	}
}

public planted_bomb_no_round(planter)
{
	playerStats[planter][BOMB_PLANTED]++;

	ExecuteForward(statsForwards[FORWARD_PLANTED], ret, planter);
}

public defused_bomb()
{
	defuser = get_loguser_index();

	playerStats[defuser][BOMB_DEFUSED]++;

	ExecuteForward(statsForwards[FORWARD_DEFUSED], ret, defuser);
}

public defusing_bomb()
{
	defuser = get_loguser_index();

	playerStats[defuser][BOMB_DEFUSIONS]++;
}

public explode_bomb()
{
	if (is_user_connected(planter)) playerStats[planter][BOMB_EXPLODED]++;

	ExecuteForward(statsForwards[FORWARD_EXPLODE], ret, planter, defuser);
}

public cur_weapon(id)
{
	static weapon, ammo;

	weapon = read_data(2);
	ammo = read_data(3);

	if (weaponsAmmo[id][weapon] != ammo) {
		if (weaponsAmmo[id][weapon] > ammo) {
			playerStats[id][STATS_SHOTS]++;
			playerRStats[id][STATS_SHOTS]++;
			playerWStats[id][weapon][STATS_SHOTS]++;
			playerWRStats[id][weapon][STATS_SHOTS]++;
		}

		weaponsAmmo[id][weapon] = ammo;
	}
}

public damage(victim)
{
	static damage, inflictor;

	damage = read_data(2);

	inflictor = pev(victim, pev_dmg_inflictor);

	if (!pev_valid(inflictor)) return;

	new attacker, weapon, hitPlace, sameTeam;

	attacker = get_user_attacker(victim, weapon, hitPlace);

	if (!(0 <= attacker <= MAX_PLAYERS)) return;

	sameTeam = get_user_team(victim) == get_user_team(attacker) ? true : false;

	if (!(0 < inflictor <= MAX_PLAYERS)) weapon = CSW_HEGRENADE;

	if (0 <= hitPlace < HIT_END) {
		ExecuteForward(statsForwards[FORWARD_DAMAGE], ret, attacker, victim, damage, weapon, hitPlace, sameTeam);

		playerStats[attacker][STATS_DAMAGE] += damage;
		playerRStats[attacker][STATS_DAMAGE] += damage;
		playerWStats[attacker][weapon][STATS_DAMAGE] += damage;
		playerWRStats[attacker][weapon][STATS_DAMAGE] += damage;
		playerVStats[attacker][victim][STATS_DAMAGE] += damage;
		playerAStats[victim][attacker][STATS_DAMAGE] += damage;
		playerVStats[attacker][0][STATS_DAMAGE] += damage;
		playerAStats[victim][0][STATS_DAMAGE] += damage;

		playerStats[attacker][STATS_HITS]++;
		playerRStats[attacker][STATS_HITS]++;
		playerWStats[attacker][weapon][STATS_HITS]++;
		playerWRStats[attacker][weapon][STATS_HITS]++;
		playerVStats[attacker][victim][STATS_HITS]++;
		playerAStats[victim][attacker][STATS_HITS]++;
		playerVStats[attacker][0][STATS_HITS]++;
		playerAStats[victim][0][STATS_HITS]++;

		playerStats[attacker][HIT_GENERIC]++;
		playerRStats[attacker][HIT_GENERIC]++;
		playerWStats[attacker][weapon][HIT_GENERIC]++;
		playerWRStats[attacker][weapon][HIT_GENERIC]++;
		playerVStats[attacker][victim][HIT_GENERIC]++;
		playerAStats[victim][attacker][HIT_GENERIC]++;
		playerVStats[attacker][0][HIT_GENERIC]++;
		playerAStats[victim][0][HIT_GENERIC]++;

		playerVStats[attacker][victim][STATS_RANK] = weapon;
		playerAStats[victim][attacker][STATS_RANK] = weapon;

		if (hitPlace) {
			playerStats[attacker][hitPlace]++;
			playerRStats[attacker][hitPlace]++;
			playerWStats[attacker][weapon][hitPlace]++;
			playerWRStats[attacker][weapon][hitPlace]++;
			playerVStats[attacker][victim][hitPlace]++;
			playerAStats[victim][attacker][hitPlace]++;
			playerVStats[attacker][0][hitPlace]++;
			playerAStats[victim][0][hitPlace]++;
		}

		if (!is_user_alive(victim)) death(attacker, victim, weapon, hitPlace, sameTeam);
	}
}

public death(killer, victim, weapon, hitPlace, teamKill)
{
	ExecuteForward(statsForwards[FORWARD_DEATH], ret, killer, victim, weapon, hitPlace, teamKill);

	playerStats[victim][CURRENT_DEATHS]++;
	playerStats[victim][STATS_DEATHS]++;
	playerRStats[victim][STATS_DEATHS]++;
	playerWStats[victim][weapon][STATS_DEATHS]++;
	playerWRStats[victim][weapon][STATS_DEATHS]++;

	if (is_user_connected(killer)) playerAStats[victim][0][KILLER_TEAM] = get_user_team(killer);

	save_stats(victim, NORMAL);

	if (is_user_connected(killer) && killer != victim) {
		new killerOrigin[3], victimOrigin[3];

		playerStats[victim][REVENGE] = killer;

		playerStats[killer][ELO_RANK] = _:set_elo(playerStats[killer][ELO_RANK], 1.0, get_elo(playerStats[victim][ELO_RANK], playerStats[killer][ELO_RANK]));
		playerStats[victim][ELO_RANK] = floatmax(1.0, set_elo(playerStats[victim][ELO_RANK], 0.0, get_elo(playerStats[killer][ELO_RANK], playerStats[victim][ELO_RANK])));

		playerAStats[victim][0][KILLER_ID] = killer;
		playerAStats[victim][0][KILLER_HEALTH] = get_user_health(killer);
		playerAStats[victim][0][KILLER_ARMOR] = get_user_armor(killer);

		playerAStats[killer][victim][KILLER_DISTANCE] = playerVStats[victim][0][KILLER_DISTANCE] = get_distance(victimOrigin, killerOrigin);

		playerStats[killer][CURRENT_KILLS]++;
		playerStats[killer][STATS_KILLS]++;
		playerRStats[killer][STATS_KILLS]++;
		playerWStats[killer][weapon][STATS_KILLS]++;
		playerWRStats[killer][weapon][STATS_KILLS]++;
		playerVStats[killer][victim][STATS_KILLS]++;
		playerAStats[victim][killer][STATS_KILLS]++;
		playerVStats[killer][0][STATS_KILLS]++;
		playerAStats[victim][0][STATS_KILLS]++;

		if (hitPlace == HIT_HEAD) {
			playerStats[killer][CURRENT_HS]++;
			playerStats[killer][STATS_HS]++;
			playerRStats[killer][STATS_HS]++;
			playerWStats[killer][weapon][STATS_HS]++;
			playerWRStats[killer][weapon][STATS_HS]++;
			playerVStats[killer][victim][STATS_HS]++;
			playerAStats[victim][killer][STATS_HS]++;
			playerVStats[killer][0][STATS_HS]++;
			playerAStats[victim][0][STATS_HS]++;
		}

		if (teamKill) {
			playerStats[killer][STATS_TK]++;
			playerRStats[killer][STATS_TK]++;
			playerWStats[killer][weapon][STATS_TK]++;
			playerWRStats[killer][weapon][STATS_TK]++;
			playerVStats[killer][victim][STATS_TK]++;
			playerAStats[victim][killer][STATS_TK]++;
			playerVStats[killer][0][STATS_TK]++;
			playerAStats[victim][0][STATS_TK]++;
		}

		save_stats(killer, NORMAL);

		if (killerInfoEnabled) client_print_color(killer, victim, "* Zabiles^x03 %s^x01. *", playerStats[victim][NAME]);
		if (victimInfoEnabled) client_print_color(victim, killer, "* Zostales zabity przez^x03 %s^x01, ktoremu zostalo^x04 %i^x01 HP. *", playerStats[killer][NAME], get_user_health(killer));

		if (assistEnabled) {
			new assistKiller, assistDamage;

			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if(!is_user_connected(i) || i == killer || i == victim) continue;

				if(playerAStats[victim][i][STATS_DAMAGE] >= assistMinDamage && playerAStats[victim][i][STATS_DAMAGE] > assistDamage) {
					assistKiller = i;
					assistDamage = playerAStats[victim][i][STATS_DAMAGE];
				}
			}

			if (assistKiller) {
				playerStats[assistKiller][STATS_KILLS]++;
				playerStats[assistKiller][CURRENT_KILLS]++;
				playerStats[assistKiller][ASSISTS]++;

				ExecuteForward(statsForwards[FORWARD_ASSIST], ret, killer, victim, assistKiller);

				save_stats(assistKiller, NORMAL);

				set_user_frags(assistKiller, get_user_frags(assistKiller) + 1);
				cs_set_user_deaths(assistKiller, cs_get_user_deaths(assistKiller));

				new money = min(cs_get_user_money(assistKiller) + assistMoney, MAX_MONEY);

				cs_set_user_money(assistKiller, money);

				if (is_user_alive(assistKiller)) {
					static msgMoney;

					if (!msgMoney) msgMoney = get_user_msgid("Money");

					message_begin(MSG_ONE_UNRELIABLE, msgMoney, _, assistKiller);
					write_long(money);
					write_byte(1);
					message_end();
				}

				if (assistInfoEnabled) client_print_color(assistKiller, killer, "* Pomogles^x04 %s^x01 w zabiciu^x04 %s^x01. *", playerStats[killer][NAME], playerStats[victim][NAME]);
			}
		}

		if (playerStats[killer][REVENGE] == victim && revengeEnabled) {
			playerStats[killer][STATS_KILLS]++;
			playerStats[killer][CURRENT_KILLS]++;
			playerStats[killer][REVENGES]++;

			playerStats[killer][REVENGE] = 0;

			ExecuteForward(statsForwards[FORWARD_REVENGE], ret, killer, victim);

			save_stats(killer, NORMAL);

			set_user_frags(killer, get_user_frags(killer) + 1);
			cs_set_user_deaths(killer, cs_get_user_deaths(killer));

			new money = min(cs_get_user_money(killer) + revengeMoney, MAX_MONEY);

			cs_set_user_money(killer, money);

			if (is_user_alive(killer)) {
				static msgMoney;

				if (!msgMoney) msgMoney = get_user_msgid("Money");

				message_begin(MSG_ONE_UNRELIABLE, msgMoney, _, killer);
				write_long(money);
				write_byte(1);
				message_end();
			}

			if (revengeInfoEnabled) client_print_color(killer, victim, "* Zemsciles sie zabijajac^x04 %s^x01. *", playerStats[victim][NAME]);
		}
	}

	show_user_hud_info(victim, false);

	if (!soundsEnabled && !xvsxEnabled) return;

	if (weapon == CSW_KNIFE && soundsEnabled) {
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i)) continue;

			if ((pev(i, pev_iuser2) == victim || i == victim) && get_bit(i, soundHumiliation)) client_cmd(i, "spk misc/humiliation");
		}
	}

	if (block) return;

	new tCount, ctCount, lastT, lastCT;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i)) continue;

		switch(get_user_team(i)) {
			case 1: {
				tCount++;
				lastT = i;
			} case 2: {
				ctCount++;
				lastCT = i;
			}
		}
	}

	if (tCount == 1 && ctCount == 1) {
		if (soundsEnabled) {
			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (!is_user_connected(i)) continue;

				if ((pev(i, pev_iuser2) == lastT || pev(i, pev_iuser2) == lastCT || i == lastT || i == lastCT) && get_bit(i, soundMayTheForce)) client_cmd(i, "spk misc/maytheforce");
			}
		}

		if (xvsxEnabled) {
			new nameT[32], nameCT[32];

			get_user_name(lastT, nameT, charsmax(nameT));
			get_user_name(lastCT, nameCT, charsmax(nameCT));

			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
			show_dhudmessage(0, "%s vs. %s", nameT, nameCT);
		}
	}

	if (tCount == 1 && ctCount > 1) {
		if (!oneAndOnly && soundsEnabled) {
			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (!is_user_connected(i)) continue;

				if (((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && pev(i, pev_iuser2) != lastT)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/lastleft");

				if ((pev(i, pev_iuser2) == lastT || i == lastT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/oneandonly");
			}
		}

		oneAndOnly = true;

		if (xvsxEnabled) {
			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
			show_dhudmessage(0, "%i vs %i", tCount, ctCount);
		}
	}

	if (tCount > 1 && ctCount == 1) {
		if (!oneAndOnly && soundsEnabled) {
			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (!is_user_connected(i)) continue;

				if (((is_user_alive(i) && get_user_team(i) == 1) || (!is_user_alive(i) && pev(i, pev_iuser2) != lastCT)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/lastleft");

				if ((pev(i, pev_iuser2) == lastCT || i == lastCT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/oneandonly");
			}
		}

		oneAndOnly = true;

		if (xvsxEnabled) {
			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
			show_dhudmessage(0, "%i vs %i", ctCount, tCount);
		}
	}
}

public win_t()
	round_winner(1);

public win_ct()
	round_winner(2);

public round_winner(team)
{
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || get_user_team(id) != team) continue;

		playerStats[id][team == 1 ? WIN_T : WIN_CT]++;
	}
}

public set_model(ent, model[])
{
	static className[32], id, weapon; id = pev(ent, pev_owner);

	if (!is_user_connected(id)) return FMRES_IGNORED;

	pev(ent, pev_classname, className, charsmax(className));

	if (strcmp(className, "grenade") != 0) return FMRES_IGNORED;

	switch (model[9]) {
		case 'f': weapon = CSW_FLASHBANG;
		case 'h': weapon = CSW_HEGRENADE;
		case 's': weapon = CSW_SMOKEGRENADE;
	}

	ExecuteForward(statsForwards[FORWARD_THROW], ret, id, ent, weapon);

	return FMRES_IGNORED;
}

public message_intermission()
{
	mapChange = true;

	if (medalsEnabled) {
		new playerName[32], winnersId[3], winnersFrags[3], tempFrags, swapFrags, swapId;

		for (new id = 1; id <= MAX_PLAYERS; id++) {
			if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

			tempFrags = get_user_frags(id);

			if (tempFrags > winnersFrags[THIRD]) {
				winnersFrags[THIRD] = tempFrags;
				winnersId[THIRD] = id;

				if (tempFrags > winnersFrags[SECOND]) {
					swapFrags = winnersFrags[SECOND];
					swapId = winnersId[SECOND];
					winnersFrags[SECOND] = tempFrags;
					winnersId[SECOND] = id;
					winnersFrags[THIRD] = swapFrags;
					winnersId[THIRD] = swapId;

					if (tempFrags > winnersFrags[FIRST]) {
						swapFrags = winnersFrags[FIRST];
						swapId = winnersId[FIRST];
						winnersFrags[FIRST] = tempFrags;
						winnersId[FIRST] = id;
						winnersFrags[SECOND] = swapFrags;
						winnersId[SECOND] = swapId;
					}
				}
			}
		}

		if (!winnersId[FIRST]) return PLUGIN_CONTINUE;

		new const medals[][] = { "Brazowy", "Srebrny", "Zloty" };

		client_print_color(0, 0, "* Gratulacje dla^x03 Najlepszych Graczy^x01! *");

		for (new i = 2; i >= 0; i--) {
			switch(i) {
				case THIRD: playerStats[winnersId[i]][BRONZE]++;
				case SECOND: playerStats[winnersId[i]][SILVER]++;
				case FIRST: playerStats[winnersId[i]][GOLD]++;
			}

			save_stats(winnersId[i], FINAL);

			get_user_name(winnersId[i], playerName, charsmax(playerName));

			client_print_color(0, 0, "* ^x03 %s^x01 -^x03 %i^x01 Zabojstw - %s Medal. *", playerName, winnersFrags[i], medals[i]);
		}
	}

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		save_stats(id, FINAL);
	}

	return PLUGIN_CONTINUE;
}

public say_text(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);

	if (is_user_connected(id)) {
		static tempMessage[192], message[192], chatPrefix[16];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		if (playerStats[id][STATS_RANK] > 3 || !prefixEnabled) return PLUGIN_CONTINUE;

		switch (playerStats[id][STATS_RANK]) {
			case 1: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP1]");
			case 2: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP2]");
			case 3: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP3]");
		}

		if (!equal(tempMessage, "#Cstrike_Chat_All")) {
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), " ");
			add(message, charsmax(message), tempMessage);
		} else {
	        get_msg_arg_string(4, tempMessage, charsmax(tempMessage));
	        set_msg_arg_string(4, "");

	        add(message, charsmax(message), chatPrefix);
	        add(message, charsmax(message), "^x03 ");
	        add(message, charsmax(message), playerStats[id][NAME]);
	        add(message, charsmax(message), "^x01 :  ");
	        add(message, charsmax(message), tempMessage);
		}

		set_msg_arg_string(2, message);
	}

	return PLUGIN_CONTINUE;
}

public show_hud_info(start)
{
	static hudInfo[512], hudTemp[256];

	hudInfo = "";

	if (disruptiveHudEnabled) {
		new disruptiveId, disruptiveDamage, disruptiveHits;

		for (new player = 1; player <= MAX_PLAYERS; player++) {
			if (!is_user_connected(player)) continue;

			if (playerRStats[player][STATS_DAMAGE] >= disruptiveDamage && (playerRStats[player][STATS_DAMAGE] > disruptiveDamage || playerRStats[player][STATS_HITS] > disruptiveHits)) {
				disruptiveId = player;
				disruptiveDamage = playerRStats[player][STATS_DAMAGE];
				disruptiveHits = playerRStats[player][STATS_HITS];
			}
		}

		if (disruptiveId) {
			formatex(hudTemp, charsmax(hudTemp), "Najwiecej obrazen: %s^n%d trafien / %d obrazen -- %0.2f%% efe. / %0.2f%% cel.^n", playerStats[disruptiveId][NAME], disruptiveHits, disruptiveDamage,
				effec(playerRStats[disruptiveId][STATS_KILLS], playerRStats[disruptiveId][STATS_DEATHS]), accuracy(playerRStats[disruptiveId][STATS_SHOTS], playerRStats[disruptiveId][STATS_HITS]));

			add(hudInfo, charsmax(hudInfo), hudTemp);
		}
	}

	if (bestScoreHudEnabled) {
		new bestScoreId, bestScoreKills, bestScoreHS;

		for (new player = 1; player <= MAX_PLAYERS; player++) {
			if (!is_user_connected(player)) continue;

			if (playerRStats[player][STATS_KILLS] >= bestScoreKills && (playerRStats[player][STATS_KILLS] > bestScoreKills || playerRStats[player][STATS_HS] > bestScoreHS)) {
				bestScoreId = player;
				bestScoreKills = playerRStats[player][STATS_KILLS];
				bestScoreHS = playerRStats[player][STATS_HS];
			}
		}

		if (bestScoreId) {
			formatex(hudTemp, charsmax(hudTemp), "Najlepszy wynik: %s^n%d zabojstw / %d hs -- %0.2f%% efe. / %0.2f%% cel.^n", playerStats[bestScoreId][NAME], bestScoreKills, bestScoreHS,
				effec(playerRStats[bestScoreId][STATS_KILLS], playerRStats[bestScoreId][STATS_DEATHS]), accuracy(playerRStats[bestScoreId][STATS_SHOTS], playerRStats[bestScoreId][STATS_HITS]));

			add(hudInfo, charsmax(hudInfo), hudTemp);
		}
	}

	if (hudInfo[0]) {
		set_hudmessage(100, 200, 0, 0.05, 0.55, 0, 0.0, 6.0, start ? 0.0 : 1.0, 1.0);
		ShowSyncHudMsg(0, hudEndRound, "%s", hudInfo);
	}

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id)) continue;

		show_user_hud_info(id, start);
	}
}

public show_user_hud_info(id, start)
{
	if (playerStats[id][HUD_INFO]) return;

	static hudInfo[1024], weaponName[32], stats[8], hits[8], length;

	new const victims[] = "Ofiary:^n", attackers[] = "Atakujacy:^n";

	playerStats[id][HUD_INFO] = true;

	if (victimHudEnabled) {
		hudInfo = "";

		copy_stats(id, hits, sizeof(hits), _, VICTIM_STATS, _, 0);
		copy_stats(id, stats, charsmax(stats), HIT_END, VICTIM_STATS, _, 0);

		if (stats[stat(STATS_SHOTS)]) length = formatex(hudInfo, charsmax(hudInfo), "Ofiary -- %0.2f%% cel.:^n", accuracy(stats[stat(STATS_SHOTS)], stats[stat(STATS_HITS)]));
		else length = formatex(hudInfo, charsmax(hudInfo), victims);

		for (new player = 1; player <= MAX_PLAYERS; player++) {
			if (!is_user_connected(player) || is_user_hltv(player)) continue;

			copy_stats(id, hits, sizeof(hits), _, VICTIM_STATS, _, player);

			if (!hits[HIT_GENERIC]) continue;

			copy_stats(id, stats, sizeof(stats), HIT_END, VICTIM_STATS, _, player);

			if (stats[stat(STATS_DEATHS)]) {
				if (stats[stat(STATS_RANK)] > 0) {
					get_weaponname(stats[stat(STATS_RANK)], weaponName, charsmax(weaponName));

					replace_all(weaponName, charsmax(weaponName), "weapon_", "");

					length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen / %s%s^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)], weaponName, (stats[stat(STATS_HS)] && hsHudEnabled) ? " / hs" : "");
				} else length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen%s^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)], (stats[stat(STATS_HS)] && hsHudEnabled) ? " / hs" : "");
			} else length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)]);
		}

		if (strlen(hudInfo) > strlen(victims)) {
			set_hudmessage(0, 80, 220, 0.55, 0.60, 0, 0.0, 6.0, start ? 0.0 : 1.0, 1.0, -1);
			show_hudmessage(id, "%s", hudInfo);
		}
	}

	if (attackerHudEnabled) {
		hudInfo = "";

		copy_stats(id, hits, sizeof(hits), _, ATTACKER_STATS, _, 0);
		copy_stats(id, stats, charsmax(stats), HIT_END, ATTACKER_STATS, _, 0);

		if (stats[stat(STATS_SHOTS)]) length = formatex(hudInfo, charsmax(hudInfo), "Atakujacy -- %0.2f%% cel.:^n", accuracy(stats[stat(STATS_SHOTS)], stats[stat(STATS_HITS)]));
		else length = formatex(hudInfo, charsmax(hudInfo), attackers);

		for (new player = 1; player <= MAX_PLAYERS; player++) {
			if (!is_user_connected(player) || is_user_hltv(player)) continue;

			copy_stats(id, hits, sizeof(hits), _, ATTACKER_STATS, _, player);

			if (!hits[HIT_GENERIC]) continue;

			copy_stats(id, stats, sizeof(stats), HIT_END, ATTACKER_STATS, _, player);

			if (stats[stat(STATS_KILLS)]) {
				if (stats[stat(STATS_RANK)] > 0) {
					get_weaponname(stats[stat(STATS_RANK)], weaponName, charsmax(weaponName));

					replace_all(weaponName, charsmax(weaponName), "weapon_", "");

					length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen / %s%s^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)], weaponName, (stats[stat(STATS_HS)] && hsHudEnabled) ? " / hs" : "");
				} else length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen%s^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)], (stats[stat(STATS_HS)] && hsHudEnabled) ? " / hs" : "");
			} else length += formatex(hudInfo[length], charsmax(hudInfo) - length, "%s -- %d trafien / %d obrazen^n", playerStats[player][NAME], stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)]);
		}

		if (strlen(hudInfo) > strlen(attackers)) {
			set_hudmessage(220, 80, 0, 0.55, 0.35, 0, 0.0, 6.0, start ? 0.0 : 1.0, 1.0, -1);
			show_hudmessage(id, "%s", hudInfo);
		}
	}
}

public cmd_menu(id)
{
	new menuData[64], weaponName[32], weaponCommand[32], menu = menu_create("\yMenu \rStatystyk\w:", "cmd_menu_handle");

	for (new i = 1; i < sizeof(commands); i++) {
		if (i + 1 == CMD_TIMEADMIN && !(get_user_flags(id) & ADMIN_BAN)) continue;

		formatex(menuData, charsmax(menuData), "%s \y(%s)", commands[i][1], commands[i][3]);

		replace_all(menuData, charsmax(menuData), "say ", "");

		menu_additem(menu, menuData, commands[i][2]);
	}

	for (new i = 1; i < WEAPONS_END; i++) {
		if (i == CSW_SHIELD || i == CSW_C4 || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE) continue;

		get_weaponname(i, weaponName, charsmax(weaponName));

		if (i == CSW_HEGRENADE) replace_all(weaponName, charsmax(weaponName), "hegrenade", "he");
		else if (i == CSW_UMP45) replace_all(weaponName, charsmax(weaponName), "mp5navy", "mp5");
		else if (i == CSW_MP5NAVY) replace_all(weaponName, charsmax(weaponName), "ump45", "ump");

		replace_all(weaponName, charsmax(weaponName), "weapon_", "");

		formatex(weaponCommand, charsmax(weaponCommand), "/%stop15", weaponName);

		ucfirst(weaponName);

		formatex(menuData, charsmax(menuData), "%s \rTop15 \y(%s)", weaponName, weaponCommand);

		menu_additem(menu, menuData, weaponCommand);
	}

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public cmd_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[32], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	cmd_execute(id, itemData);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public cmd_hp(id)
{
	if (!hpEnabled) return PLUGIN_CONTINUE;

	new killer = playerAStats[id][0][KILLER_ID];

	static message[192];

	if (killer && killer != id) {
		new weaponName[32], stats[8], hits[8], length;

		copy_stats(id, hits, sizeof(hits), _, ATTACKER_STATS, _, killer);
		copy_stats(id, stats, sizeof(stats), HIT_END, ATTACKER_STATS, _, killer);

		if (stats[stat(STATS_RANK)] > 0) {
			get_weaponname(stats[stat(STATS_RANK)], weaponName, charsmax(weaponName));

			replace_all(weaponName, charsmax(weaponName), "weapon_", "");

			length = formatex(message, charsmax(message), "Zabity przez^x03 %s^x01 z %s z odleglosci %0.0fm (^x04 %d HP^x01,^x04 %d AP^x01). Szczegoly: ", playerStats[killer][NAME], weaponName, distance(playerAStats[id][0][KILLER_DISTANCE]), playerAStats[id][0][KILLER_HEALTH], playerAStats[id][0][KILLER_ARMOR]);
		} else length = formatex(message, charsmax(message), "Zabity przez^x03 %s^x01 z odleglosci %0.0fm (^x04 %d HP^x01,^x04 %d AP^x01). Szczegoly: ", playerStats[killer][NAME], distance(playerAStats[id][0][KILLER_DISTANCE]), playerAStats[id][0][KILLER_HEALTH], playerAStats[id][0][KILLER_ARMOR]);

		if (stats[stat(STATS_HITS)]) {
			for (new i = 1, hit = 0; i < sizeof(hits); i++) {
				if (!hits[i]) continue;

				if (hit) length += formatex(message[length], charsmax(message) - length, ", ");

				length += formatex(message[length], charsmax(message) - length, "%s: %d", body[i], hits[i]);

				hit++;
			}
		} else length += formatex(message[length], charsmax(message) - length, "zadnych trafien");
	} else formatex(message, charsmax(message), "Nie masz zadnego zabojcy");

	client_print_color(id, killer, "* %s. *", message);

	return PLUGIN_HANDLED;
}

public cmd_me(id)
{
	if (!meEnabled) return PLUGIN_CONTINUE;

	static message[192];

	new stats[8], hits[8], length;

	copy_stats(id, hits, sizeof(hits), _, VICTIM_STATS, _, 0);
	copy_stats(id, stats, charsmax(stats), HIT_END, VICTIM_STATS, _, 0);

	length = formatex(message, charsmax(message), "Ostatni rezultat:^x04 %d^x01 trafien,^x04 %d^x01 obrazen. Szczegoly: ", stats[stat(STATS_HITS)], stats[stat(STATS_DAMAGE)]);

	if (stats[stat(STATS_HITS)]) {
		for (new i = 1, hit = 0; i < sizeof(hits); i++) {
			if (!hits[i]) continue;

			if (hit) length += formatex(message[length], charsmax(message) - length, ", ");

			length += formatex(message[length], charsmax(message) - length, "%s: %d", body[i], hits[i]);

			hit++;
		}
	} else length += formatex(message[length], charsmax(message) - length, "zadnych trafien");

	client_print_color(id, id, "* %s. *", message);

	return PLUGIN_HANDLED;
}

public cmd_statsme(id, player)
{
	if (!statsMeEnabled) return PLUGIN_CONTINUE;

	static motdData[2048], weaponName[32], motdLength, target;

	motdLength = 0;

	target = player ? player : id;

	motdLength = formatex(motdData, charsmax(motdData), "<meta charset=utf-8><body bgcolor=#000000><font color=#FFB000><pre>");

	motdLength += formatex(motdData[motdLength], charsmax(motdData) - motdLength, "%16s: %d (%d z HS)^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %0.2f%%^n%16s: %0.2f%%^n^n", "Zabojstwa", playerStats[target][STATS_KILLS], playerStats[target][STATS_HS], "Zgony", playerStats[target][STATS_DEATHS], "Trafienia",
		playerStats[target][STATS_HITS], "Strzaly", playerStats[target][STATS_SHOTS], "Obrazenia", playerStats[target][STATS_DAMAGE], "Efektywnosc", effec(playerStats[target][STATS_KILLS], playerStats[target][STATS_DEATHS]), "Celnosc", accuracy(playerStats[target][STATS_SHOTS], playerStats[target][STATS_HITS]));

	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%8s %6s %7s %2s %6s %4s %4s %4s^n", "Bron", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");

	for (new i = 1; i < WEAPONS_END; i++) {
		if ((i == CSW_SHIELD || i == CSW_C4 || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE) || (!playerWStats[target][i][STATS_SHOTS] && !playerWStats[target][i][STATS_DEATHS])) continue;

		get_weaponname(i, weaponName, charsmax(weaponName));

		replace_all(weaponName, charsmax(weaponName), "weapon_", "");

		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%8s %6d %6d %5d %7d %9d %3.0f%% %3.0f%%^n", weaponName, playerWStats[target][i][STATS_KILLS], playerWStats[target][i][STATS_DEATHS], playerWStats[target][i][STATS_HS],
			playerWStats[target][i][STATS_HITS], playerWStats[target][i][STATS_SHOTS], effec(playerWStats[target][i][STATS_KILLS], playerWStats[target][i][STATS_DEATHS]), accuracy(playerWStats[target][i][STATS_SHOTS], playerWStats[target][i][STATS_HITS]));
	}

	show_motd(id, motdData, playerStats[target][NAME]);

	return PLUGIN_HANDLED;
}

public cmd_rank(id)
{
	if (!rankEnabled) return PLUGIN_CONTINUE;

	client_print_color(id, id, "* Masz^x04 %d^x01 zabojstw,^x04 %d^x01 trafien,^x04 %.2f^x01%% efektywnosci i^x04 %.2f^x01%% celnosci. *", playerStats[id][STATS_KILLS], playerStats[id][STATS_HITS], effec(playerStats[id][STATS_KILLS], playerStats[id][STATS_DEATHS]), accuracy(playerStats[id][STATS_SHOTS], playerStats[id][STATS_HITS]));
	client_print_color(id, id, "* Twoj ranking wynosi^x03 %d^x01 na^x03 %d^x01. *", playerStats[id][STATS_RANK], statsNum);

	return PLUGIN_HANDLED;
}

public cmd_rankstats(id, player)
{
	if (!rankStatsEnabled) return PLUGIN_CONTINUE;

	static motdData[4096], motdLength, target;

	motdLength = 0;

	target = player ? player : id;

	motdLength = formatex(motdData, charsmax(motdData), "<meta charset=utf-8><body bgcolor=#000000><font color=#FFB000><pre>");

	if (player) motdLength += formatex(motdData[motdLength], charsmax(motdData) - motdLength, "Ranking gracza %s wynosi %i na %i^n^n", playerStats[target][NAME], playerStats[target][STATS_RANK], statsNum);
	else motdLength += formatex(motdData[motdLength], charsmax(motdData) - motdLength, "Twoj ranking wynosi %i na %i^n^n", playerStats[target][STATS_RANK], statsNum);

	motdLength += formatex(motdData[motdLength], charsmax(motdData) - motdLength, "%16s: %d (%d z HS)^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %0.2f%%^n%16s: %0.2f%%^n^n", "Zabojstwa", playerStats[target][STATS_KILLS], playerStats[target][STATS_HS], "Zgony", playerStats[target][STATS_DEATHS], "Trafienia",
		playerStats[target][STATS_HITS], "Strzaly", playerStats[target][STATS_SHOTS], "Obrazenia", playerStats[target][STATS_DAMAGE], "Efektywnosc", effec(playerStats[target][STATS_KILLS], playerStats[target][STATS_DEATHS]), "Celnosc", accuracy(playerStats[target][STATS_SHOTS], playerStats[target][STATS_HITS]));

	motdLength += formatex(motdData[motdLength], charsmax(motdData) - motdLength, "TRAFIENIA^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d^n%16s: %d", body[HIT_HEAD], playerStats[target][HIT_HEAD], body[HIT_CHEST], playerStats[target][HIT_CHEST],
		body[HIT_STOMACH], playerStats[target][HIT_STOMACH], body[HIT_LEFTARM], playerStats[target][HIT_LEFTARM], body[HIT_RIGHTARM], playerStats[target][HIT_RIGHTARM], body[HIT_LEFTLEG], playerStats[target][HIT_LEFTLEG], body[HIT_RIGHTLEG], playerStats[target][HIT_RIGHTLEG]);

	show_motd(id, motdData, playerStats[target][NAME]);

	return PLUGIN_HANDLED;
}

public cmd_top15(id)
{
	if (!top15Enabled) return PLUGIN_CONTINUE;

	new queryData[256], queryTemp[96], playerId[1];

	playerId[0] = id;

	get_rank_formula(queryTemp, charsmax(queryTemp), 0);

	formatex(queryData, charsmax(queryData), "SELECT a.name, a.kills, a.deaths, a.hs_kills, a.shots, a.hits, a.elo_rank FROM `ultimate_stats` a ORDER BY %s LIMIT 15", queryTemp);

	SQL_ThreadQuery(sql, "show_top15", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_top15(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Top15 SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], Float:elo, motdLength, place, kills, deaths, hs, shots, hits;

	motdLength = 0, place = 0;

	new id = playerId[0];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");

	if (rankFormula == FORMULA_ELO) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %4s %5s %7s %2s %6s %4s %4s %4s^n", "#", "Nick", "Skill", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");
	else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %5s %7s %2s %6s %4s %4s %4s^n", "#", "Nick", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		kills = SQL_ReadResult(query, 1);
		deaths = SQL_ReadResult(query, 2);
		hs = SQL_ReadResult(query, 3);
		shots = SQL_ReadResult(query, 4);
		hits = SQL_ReadResult(query, 5);

		if (rankFormula == FORMULA_ELO) {
			SQL_ReadResult(query, 6, elo);

			motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2d %-22.22s %4.2f %6d %7d %6d %7d %7d %3.0f%% %3.0f%%^n", place, name, elo, kills, deaths, hs, hits, shots, effec(kills, deaths), accuracy(shots, hits));
		} else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2d %-22.22s %6d %7d %6d %7d %7d %3.0f%% %3.0f%%^n", place, name, kills, deaths, hs, hits, shots, effec(kills, deaths), accuracy(shots, hits));

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15");

	return PLUGIN_HANDLED;
}

public cmd_topme(id)
{
	if (!topMeEnabled) return PLUGIN_CONTINUE;

	new queryData[256], queryTemp[96], playerId[2], start = 0;

	if (playerStats[id][STATS_RANK] > 7) start = playerStats[id][STATS_RANK] - 7;
	else if (playerStats[id][STATS_RANK] + 8 >= statsNum) start = statsNum - 15;

	playerId[0] = id;
	playerId[1] = start;

	get_rank_formula(queryTemp, charsmax(queryTemp), 0);

	formatex(queryData, charsmax(queryData), "SELECT a.name, a.kills, a.deaths, a.hs_kills, a.shots, a.hits, a.elo_rank FROM `ultimate_stats` a ORDER BY %s LIMIT %i, 15", queryTemp, start);

	SQL_ThreadQuery(sql, "show_topme", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_topme(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "TopMe SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], Float:elo, motdLength, kills, deaths, hs, shots, hits;

	motdLength = 0;

	new id = playerId[0], place = playerId[1];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");

	if (rankFormula == FORMULA_ELO) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %4s %5s %7s %2s %6s %4s %4s %4s^n", "#", "Nick", "Skill", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");
	else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %5s %7s %2s %6s %4s %4s %4s^n", "#", "Nick", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		kills = SQL_ReadResult(query, 1);
		deaths = SQL_ReadResult(query, 2);
		hs = SQL_ReadResult(query, 3);
		shots = SQL_ReadResult(query, 4);
		hits = SQL_ReadResult(query, 5);

		if (rankFormula == FORMULA_ELO) {
			SQL_ReadResult(query, 6, elo);

			motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2d %-22.22s %4.2f %6d %7d %6d %7d %7d %3.0f%% %3.0f%%^n", place, name, elo, kills, deaths, hs, hits, shots, effec(kills, deaths), accuracy(shots, hits));
		} else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2d %-22.22s %6d %7d %6d %7d %7d %3.0f%% %3.0f%%^n", place, name, kills, deaths, hs, hits, shots, effec(kills, deaths), accuracy(shots, hits));

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15");

	return PLUGIN_HANDLED;
}

public cmd_weapon_top15(id, weapon)
{
	new queryData[512], weaponName[32], playerId[2];

	get_weaponname(weapon, weaponName, charsmax(weaponName));

	playerId[0] = id;
	playerId[1] = weapon;

	if(weapon == CSW_KNIFE) formatex(queryData, charsmax(queryData), "SELECT a.name, b.kills, b.hs_kills FROM `ultimate_stats` a JOIN `ultimate_stats_weapons` b ON a.id = b.player_id WHERE b.weapon = 'weapon_knife' ORDER BY b.kills DESC, b.hs_kills DESC LIMIT 15");
	else if(weapon == CSW_HEGRENADE) formatex(queryData, charsmax(queryData), "SELECT a.name, b.kills FROM `ultimate_stats` a JOIN `ultimate_stats_weapons` b ON a.id = b.player_id WHERE b.weapon = 'weapon_hegrenade' ORDER BY b.kills DESC LIMIT 15");
	else {
		new queryTemp[96];

		get_rank_formula(queryTemp, charsmax(queryTemp), 0, 1);

		formatex(queryData, charsmax(queryData), "SELECT b.name, a.kills, a.deaths, a.hs_kills, a.shots, a.hits FROM `ultimate_stats` b JOIN `ultimate_stats_weapons` a ON b.id = a.player_id WHERE a.weapon = '%s' ORDER BY %s LIMIT 15", weaponName, queryTemp);
	}

	SQL_ThreadQuery(sql, "show_weapon_top15", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_weapon_top15(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Weapon Top15 SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], topName[64], name[32], motdLength, place, kills, deaths, hs, shots, hits;

	motdLength = 0, place = 0;

	new id = playerId[0], weapon = playerId[1];

	get_weaponname(weapon, topName, charsmax(topName));

	replace_all(topName, charsmax(topName), "weapon_", "");

	ucfirst(topName);

	add(topName, charsmax(topName), " Top15");

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");

	if(weapon == CSW_KNIFE) {
		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %10s %13s^n", "#", "Nick", "Zabojstwa", "HS");

		while (SQL_MoreResults(query)) {
			place++;

			SQL_ReadResult(query, 0, name, charsmax(name));

			replace_all(name, charsmax(name), "<", "");
			replace_all(name, charsmax(name), ">", "");

			kills = SQL_ReadResult(query, 1);
			hs = SQL_ReadResult(query, 2);

			motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %5d %7d^n", place, name, kills, hs);

			SQL_NextRow(query);
		}
	} else if(weapon == CSW_HEGRENADE) {
		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %13s^n", "#", "Nick", "Zabojstwa");

		while (SQL_MoreResults(query)) {
			place++;

			SQL_ReadResult(query, 0, name, charsmax(name));

			replace_all(name, charsmax(name), "<", "");
			replace_all(name, charsmax(name), ">", "");

			kills = SQL_ReadResult(query, 1);

			motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %6d^n", place, name, kills);

			SQL_NextRow(query);
		}
	} else {
		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %5s %7s %2s %6s %4s %4s %4s^n", "#", "Nick", "Zabojstwa", "Zgony", "HS", "Trafienia", "Strzaly", "Efe.", "Cel.");

		while (SQL_MoreResults(query)) {
			place++;

			SQL_ReadResult(query, 0, name, charsmax(name));

			replace_all(name, charsmax(name), "<", "");
			replace_all(name, charsmax(name), ">", "");

			kills = SQL_ReadResult(query, 1);
			deaths = SQL_ReadResult(query, 2);
			hs = SQL_ReadResult(query, 3);
			shots = SQL_ReadResult(query, 4);
			hits = SQL_ReadResult(query, 5);

			motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2d %-22.22s %6d %7d %6d %7d %7d %3.0f%% %3.0f%%^n", place, name, kills, deaths, hs, hits, shots, effec(kills, deaths), accuracy(shots, hits));

			SQL_NextRow(query);
		}
	}

	show_motd(id, motdData, topName);

	return PLUGIN_HANDLED;
}

public cmd_time(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT `rank`, `all` FROM (SELECT COUNT(*) AS `all` FROM `ultimate_stats`) a JOIN (SELECT COUNT(*) + 1 AS `rank` FROM `ultimate_stats` WHERE time > %i ORDER BY time DESC) b", playerStats[id][TIME] + get_user_time(id));

	SQL_ThreadQuery(sql, "show_time", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_time(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Time SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0], rank = SQL_ReadResult(query, 0), players = SQL_ReadResult(query, 1), seconds = (playerStats[id][TIME] + get_user_time(id)), minutes, hours;

	while (seconds >= 60) {
		seconds -= 60;
		minutes++;
	}

	while (minutes >= 60) {
		minutes -= 60;
		hours++;
	}

	client_print_color(id, id, "* Spedziles na serwerze lacznie^x04 %i h %i min %i s^x01. *", hours, minutes, seconds);
	client_print_color(id, id, "* Zajmujesz^x03 %i^x01 na^x03 %i^x01 miejsce w rankingu czasu gry. *", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_time_admin(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	new queryData[128], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, time FROM `ultimate_stats` WHERE admin = 1 ORDER BY time DESC");

	SQL_ThreadQuery(sql, "show_time_admin", queryData, playerId, sizeof(playerId));
}

public show_time_admin(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Time Admin SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], motdLength, place, seconds, minutes, hours;

	motdLength = 0, place = 0;

	new id = playerId[0];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %9s^n", "#", "Nick", "Czas Gry");

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		seconds = SQL_ReadResult(query, 1);
		minutes = 0;
		hours = 0;

		while (seconds >= 60) {
			seconds -= 60;
			minutes++;
		}

		while (minutes >= 60) {
			minutes -= 60;
			hours++;
		}

		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %0ih %1imin %1is^n", place, name, hours, minutes, seconds);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Czas Gry Adminow");

	return PLUGIN_HANDLED;
}

public cmd_time_top15(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, time FROM `ultimate_stats` ORDER BY time DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_time_top15", queryData, playerId, sizeof(playerId));
}

public show_time_top15(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Time Top15 SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], motdLength, place, seconds, minutes, hours;

	motdLength = 0, place = 0;

	new id = playerId[0];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %9s^n", "#", "Nick", "Czas Gry");

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		seconds = SQL_ReadResult(query, 1);
		minutes = 0;
		hours = 0;

		while (seconds >= 60) {
			seconds -= 60;
			minutes++;
		}

		while (minutes >= 60) {
			minutes -= 60;
			hours++;
		}

		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %0ih %1imin %1is^n", place, name, hours, minutes, seconds);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15 Czasu Gry");

	return PLUGIN_HANDLED;
}

public cmd_stats(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	playerStats[id][CURRENT_STATS] = playerStats[id][CURRENT_KILLS] * 2 + playerStats[id][CURRENT_HS] - playerStats[id][CURRENT_DEATHS] * 2;

	formatex(queryData, charsmax(queryData), "SELECT `rank`, `all` FROM (SELECT COUNT(*) AS `all` FROM `ultimate_stats`) a JOIN (SELECT COUNT(*) + 1 AS `rank` FROM `ultimate_stats` WHERE best_stats > %i ORDER BY `best_stats` DESC) b",
	playerStats[id][CURRENT_STATS] > playerStats[id][BEST_STATS] ? playerStats[id][CURRENT_STATS] : playerStats[id][BEST_STATS]);

	SQL_ThreadQuery(sql, "show_stats", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_stats(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Stats SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0], rank = SQL_ReadResult(query, 0), players = SQL_ReadResult(query, 1);

	if (playerStats[id][CURRENT_STATS] > playerStats[id][BEST_STATS]) client_print_color(id, id, "* Twoje najlepsze staty to^x03 %i^x01 zabic (w tym^x03 %i^x01 z HS) i^x03 %i^x01 zgonow^x01. *", playerStats[id][CURRENT_KILLS], playerStats[id][CURRENT_HS], playerStats[id][CURRENT_DEATHS]);
	else client_print_color(id, id, "* Twoje najlepsze staty to^x03 %i^x01 zabic (w tym^x03 %i^x01 z HS) i^x03 %i^x01 zgonow^x01. *", playerStats[id][BEST_KILLS], playerStats[id][BEST_HS], playerStats[id][BEST_DEATHS]);

	client_print_color(id, id, "* Zajmujesz^x03 %i^x01 na^x03  %i^x01 miejsce w rankingu najlepszych statystyk. *", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_stats_top15(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, best_kills, best_hs, best_deaths FROM `ultimate_stats` ORDER BY best_stats DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_stats_top15", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_stats_top15(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Stats Top15 SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], motdLength, place, kills, headShots, deaths;

	motdLength = 0, place = 0;

	new id = playerId[0];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %19s %4s^n", "#", "Nick", "Zabojstwa", "Zgony");

	while (SQL_MoreResults(query))
	{
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		kills = SQL_ReadResult(query, 1);
		headShots = SQL_ReadResult(query, 2);
		deaths = SQL_ReadResult(query, 3);

		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %1d (%i HS) %12d^n", place, name, kills, headShots, deaths);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15 Statystyk");

	return PLUGIN_HANDLED;
}

public cmd_medals(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT `rank`, `all` FROM (SELECT COUNT(*) AS `all` FROM `ultimate_stats`) a JOIN (SELECT COUNT(*) + 1 AS `rank` FROM `ultimate_stats` WHERE medals > %i ORDER BY `medals` DESC) b", playerStats[id][MEDALS]);

	SQL_ThreadQuery(sql, "show_medals", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_medals(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("cssstats.log", "Medals SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0], rank = SQL_ReadResult(query, 0), players = SQL_ReadResult(query, 1);

	client_print_color(id, id, "* Twoje medale:^x04 %i Zlote^x01,^x04 %i Srebre^x01,^x04 %i Brazowe^x01. *", playerStats[id][GOLD], playerStats[id][SILVER], playerStats[id][BRONZE]);
	client_print_color(id, id, "* Zajmujesz^x03 %i^x01 na^x03 %i^x01 miejsce w rankingu medalowym. *", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_medals_top15(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, gold, silver, bronze, medals FROM `ultimate_stats` ORDER BY medals DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_medals_top15", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_medals_top15(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Medals Top15 SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static motdData[2048], name[32], motdLength, place, gold, silver, bronze, medals;

	motdLength = 0, place = 0;

	new id = playerId[0];

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2s %-22.22s %6s %8s %8s %5s^n", "#", "Nick", "Zlote", "Srebrne", "Brazowe", "Suma");

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		gold = SQL_ReadResult(query, 1);
		silver = SQL_ReadResult(query, 2);
		bronze = SQL_ReadResult(query, 3);
		medals = SQL_ReadResult(query, 4);

		motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%2i %-22.22s %2d %7d %8d %7d^n", place, name, gold, silver, bronze, medals);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15 Medali");

	return PLUGIN_HANDLED;
}

public cmd_sounds(id)
{
	if (!soundsEnabled) return PLUGIN_HANDLED;

	new menuData[64], menu = menu_create("\yUstawienia \rDzwiekow\w:", "cmd_sounds_handle");

	formatex(menuData, charsmax(menuData), "\wThe Force Will Be With You \w[\r%s\w]", get_bit(id, soundMayTheForce) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wI Am The One And Only \w[\r%s\w]", get_bit(id, soundOneAndOnly) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wDziabnal Mnie \w[\r%s\w]", get_bit(id, soundHumiliation) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wKici Kici Tas Tas \w[\r%s\w]", get_bit(id, soundLastLeft) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wNie Obijac Sie \w[\r%s\w]", get_bit(id, soundPrepare) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public cmd_sounds_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: get_bit(id, soundMayTheForce) ? rem_bit(id, soundMayTheForce) : set_bit(id, soundMayTheForce);
		case 1: get_bit(id, soundOneAndOnly) ? rem_bit(id, soundOneAndOnly) : set_bit(id, soundOneAndOnly);
		case 2: get_bit(id, soundHumiliation) ? rem_bit(id, soundHumiliation) : set_bit(id, soundHumiliation);
		case 3: get_bit(id, soundLastLeft) ? rem_bit(id, soundLastLeft) : set_bit(id, soundLastLeft);
		case 4: get_bit(id, soundPrepare) ? rem_bit(id, soundPrepare) : set_bit(id, soundPrepare);
	}

	save_sounds(id);

	cmd_sounds(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public weapons_top15_handle(id)
{
	if (!top15Enabled) return PLUGIN_CONTINUE;

	static message[32], command[32], weaponName[32];

	read_argv(1, message, charsmax(message));
	trim(message);

	if (message[0] != '/') return PLUGIN_CONTINUE;

	for (new i = 1; i < WEAPONS_END; i++) {
		if (i == CSW_SHIELD || i == CSW_C4 || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE) continue;

		get_weaponname(i, weaponName, charsmax(weaponName));

		if (i == CSW_HEGRENADE) replace_all(weaponName, charsmax(weaponName), "hegrenade", "he");
		else if (i == CSW_UMP45) replace_all(weaponName, charsmax(weaponName), "mp5navy", "mp5");
		else if (i == CSW_MP5NAVY) replace_all(weaponName, charsmax(weaponName), "ump45", "ump");

		replace_all(weaponName, charsmax(weaponName), "weapon_", "");

		formatex(command, charsmax(command), "/%stop15", weaponName);

		if (equali(message, command)) {
			cmd_weapon_top15(id, i);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], error[128], errorNum;

	get_cvar_string("ultimate_stats_host", host, charsmax(host));
	get_cvar_string("ultimate_stats_user", user, charsmax(user));
	get_cvar_string("ultimate_stats_pass", pass, charsmax(pass));
	get_cvar_string("ultimate_stats_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("ultimate_stats.log", "SQL Query Error: %s", error);

		return;
	}

	new queryData[2048];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `ultimate_stats` (`id` INT(11) AUTO_INCREMENT, `name` VARCHAR(64) NOT NULL, `steamid` VARCHAR(32) NOT NULL, `ip` VARCHAR(16) NOT NULL, `admin` INT NOT NULL DEFAULT 0, `kills` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`deaths` INT NOT NULL DEFAULT 0, `hs_kills` INT NOT NULL DEFAULT 0, `assists` INT NOT NULL DEFAULT 0, `revenges` INT NOT NULL DEFAULT 0, `team_kills` INT NOT NULL DEFAULT 0, `shots` INT NOT NULL DEFAULT 0, `hits` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`damage` INT NOT NULL DEFAULT 0, `rounds` INT NOT NULL DEFAULT 0, `rounds_ct` INT NOT NULL DEFAULT 0, `rounds_t` INT NOT NULL DEFAULT 0, `wins_ct` INT NOT NULL DEFAULT 0, `wins_t` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`connects` INT NOT NULL DEFAULT 0, `time` INT NOT NULL DEFAULT 0, `gold` INT NOT NULL DEFAULT 0, `silver` INT NOT NULL DEFAULT 0, `bronze` INT NOT NULL DEFAULT 0, `medals` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`best_kills` INT NOT NULL DEFAULT 0, `best_deaths` INT NOT NULL DEFAULT 0, `best_hs` INT NOT NULL DEFAULT 0, `best_stats` INT NOT NULL DEFAULT 0, `defusions` INT NOT NULL DEFAULT 0, `defused` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`planted` INT NOT NULL DEFAULT 0, `exploded` INT NOT NULL DEFAULT 0, `elo_rank` DOUBLE NOT NULL DEFAULT 100, `h_0` INT NOT NULL DEFAULT 0, `h_1` INT NOT NULL DEFAULT 0, `h_2` INT NOT NULL DEFAULT 0, `h_3` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`h_4` INT NOT NULL DEFAULT 0, `h_5` INT NOT NULL DEFAULT 0, `h_6` INT NOT NULL DEFAULT 0, `h_7` INT NOT NULL DEFAULT 0, `first_visit` BIGINT NOT NULL DEFAULT 0, `last_visit` BIGINT NOT NULL DEFAULT 0,  PRIMARY KEY(`id`), UNIQUE KEY `name` (`name`));");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `ultimate_stats_weapons` (`player_id` INT(11), `weapon` VARCHAR(32) NOT NULL, `kills` INT NOT NULL DEFAULT 0, `deaths` INT NOT NULL DEFAULT 0, `hs_kills` INT NOT NULL DEFAULT 0, `team_kills` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`shots` INT NOT NULL DEFAULT 0, `hits` INT NOT NULL DEFAULT 0, `damage` INT NOT NULL DEFAULT 0, `h_0` INT NOT NULL DEFAULT 0, `h_1` INT NOT NULL DEFAULT 0, `h_2` INT NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`h_3` INT NOT NULL DEFAULT 0, `h_4` INT NOT NULL DEFAULT 0, `h_5` INT NOT NULL DEFAULT 0, `h_6` INT NOT NULL DEFAULT 0, `h_7` INT NOT NULL DEFAULT 0, PRIMARY KEY(`player_id`, `weapon`));");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "SELECT COUNT(*) FROM `ultimate_stats`");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	if (SQL_NumResults(query)) statsNum = SQL_ReadResult(query, 0);

	SQL_FreeHandle(query);

	sqlConnection = true;
}

public ignore_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState == TQUERY_CONNECT_FAILED) log_to_file("ultimate_stats.log", "Could not connect to SQL database. [%d] %s", errorCode, error);
	else if (failState == TQUERY_QUERY_FAILED) log_to_file("ultimate_stats.log", "Query failed. [%d] %s", errorCode, error);
}

public load_stats(id)
{
	if (!sqlConnection) {
		set_task(1.0, "load_stats", id);

		return;
	}

	static playerId[1], queryData[256], queryTemp[96];

	playerId[0] = id;

	get_rank_formula(queryTemp, charsmax(queryTemp));

	formatex(queryData, charsmax(queryData), "SELECT a.*, (SELECT COUNT(*) FROM `ultimate_stats` WHERE %s) + 1 AS `rank` FROM `ultimate_stats` a WHERE ", queryTemp);

	switch (rankSaveType) {
		case 0: formatex(queryTemp, charsmax(queryTemp), "`name` = ^"%s^"", playerStats[id][SAFE_NAME]);
		case 1: formatex(queryTemp, charsmax(queryTemp), "`steamid` = ^"%s^"", playerStats[id][STEAMID]);
		case 2: formatex(queryTemp, charsmax(queryTemp), "`ip` = ^"%s^"", playerStats[id][IP]);
	}

	add(queryData, charsmax(queryData), queryTemp);

	SQL_ThreadQuery(sql, "load_stats_handle", queryData, playerId, sizeof(playerId));
}

public load_stats_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Load SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_NumResults(query)) {
		playerStats[id][PLAYER_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		playerStats[id][STATS_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
		playerStats[id][STATS_DEATHS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "deaths"));
		playerStats[id][STATS_HS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hs_kills"));
		playerStats[id][STATS_TK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "team_kills"));
		playerStats[id][STATS_SHOTS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "shots"));
		playerStats[id][STATS_HITS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hits"));
		playerStats[id][STATS_DAMAGE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "damage"));
		playerStats[id][STATS_RANK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rank"));
		playerStats[id][HIT_GENERIC] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_0"));
		playerStats[id][HIT_HEAD] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_1"));
		playerStats[id][HIT_CHEST] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_2"));
		playerStats[id][HIT_STOMACH] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_3"));
		playerStats[id][HIT_LEFTARM] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_4"));
		playerStats[id][HIT_RIGHTARM] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_5"));
		playerStats[id][HIT_LEFTLEG] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_6"));
		playerStats[id][HIT_RIGHTLEG] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_7"));
		playerStats[id][BOMB_DEFUSIONS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "defusions"));
		playerStats[id][BOMB_DEFUSED] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "defused"));
		playerStats[id][BOMB_PLANTED] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "planted"));
		playerStats[id][BOMB_EXPLODED] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "exploded"));
		playerStats[id][ROUNDS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rounds"));
		playerStats[id][ROUNDS_CT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rounds_ct"));
		playerStats[id][ROUNDS_T] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rounds_t"));
		playerStats[id][WIN_CT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "wins_ct"));
		playerStats[id][WIN_T] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "wins_t"));
		playerStats[id][TIME] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "time"));
		playerStats[id][CONNECTS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "connects")) + 1;
		playerStats[id][ASSISTS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "assists"));
		playerStats[id][REVENGES] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "revenges"));
		playerStats[id][BRONZE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "bronze"));
		playerStats[id][SILVER] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "silver"));
		playerStats[id][GOLD] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "gold"));
		playerStats[id][MEDALS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "medals"));
		playerStats[id][BEST_STATS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "best_stats"));
		playerStats[id][BEST_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "best_kills"));
		playerStats[id][BEST_HS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "best_hs"));
		playerStats[id][BEST_DEATHS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "best_deaths"));
		playerStats[id][FIRST_VISIT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "first_visit"));
		playerStats[id][LAST_VISIT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "last_visit"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "elo_rank"), playerStats[id][ELO_RANK]);
	} else {
		statsNum++;

		static queryData[256];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `ultimate_stats` (`name`, `steamid`, `ip`, `first_visit`) VALUES (^"%s^", '%s', '%s', UNIX_TIMESTAMP())", playerStats[id][SAFE_NAME], playerStats[id][STEAMID], playerStats[id][IP]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);

		get_rank(id);
	}

	set_bit(id, statsLoaded);

	set_task(0.5, "load_weapons_stats", id);
}

public get_rank(id)
{
	static queryData[256], queryTemp[96], playerId[1];

	playerId[0] = id;

	get_rank_formula(queryTemp, charsmax(queryTemp));

	formatex(queryData, charsmax(queryData), "SELECT (SELECT COUNT(*) FROM `ultimate_stats` WHERE %s) + 1 AS `rank` FROM `ultimate_stats` a WHERE ", queryTemp);

	switch (rankSaveType) {
		case 0: formatex(queryTemp, charsmax(queryTemp), "name = ^"%s^"", playerStats[id][SAFE_NAME]);
		case 1: formatex(queryTemp, charsmax(queryTemp), "steamid = ^"%s^"", playerStats[id][STEAMID]);
		case 2: formatex(queryTemp, charsmax(queryTemp), "ip = ^"%s^"", playerStats[id][IP]);
	}

	add(queryData, charsmax(queryData), queryTemp);

	SQL_ThreadQuery(sql, "get_rank_handle", queryData, playerId, sizeof(playerId));
}

public get_rank_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Get Rank SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_NumResults(query)) playerStats[id][STATS_RANK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rank"));
}

public load_weapons_stats(id)
{
	static queryData[256], queryTemp[96], playerId[1];

	playerId[0] = id;

	if (!playerStats[id][PLAYER_ID]) playerStats[id][PLAYER_ID] = get_player_id(id);

	if (!playerStats[id][PLAYER_ID]) {
		set_task(0.5, "load_weapons_stats", id);

		return;
	}

	get_rank_formula(queryTemp, charsmax(queryTemp));

	formatex(queryData, charsmax(queryData), "SELECT a.*, (SELECT COUNT(*) FROM `ultimate_stats_weapons` WHERE %s AND weapon = a.weapon) + 1 AS `rank` FROM `ultimate_stats_weapons` a WHERE `player_id` = '%i'", queryTemp, playerStats[id][PLAYER_ID]);

	SQL_ThreadQuery(sql, "load_weapons_stats_handle", queryData, playerId, sizeof(playerId));
}

public load_weapons_stats_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("ultimate_stats.log", "Load Weapons SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0], weaponName[32], weapon, ret;

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapon"), weaponName, charsmax(weaponName));

		weapon = get_weaponid(weaponName);

		playerWStats[id][weapon][STATS_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
		playerWStats[id][weapon][STATS_DEATHS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "deaths"));
		playerWStats[id][weapon][STATS_TK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "team_kills"));
		playerWStats[id][weapon][STATS_HS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hs_kills"));
		playerWStats[id][weapon][STATS_SHOTS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "shots"));
		playerWStats[id][weapon][STATS_HITS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hits"));
		playerWStats[id][weapon][STATS_DAMAGE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "damage"));
		playerWStats[id][weapon][STATS_RANK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rank"));
		playerWStats[id][weapon][HIT_GENERIC] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_0"));
		playerWStats[id][weapon][HIT_HEAD] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_1"));
		playerWStats[id][weapon][HIT_CHEST] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_2"));
		playerWStats[id][weapon][HIT_STOMACH] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_3"));
		playerWStats[id][weapon][HIT_LEFTARM] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_4"));
		playerWStats[id][weapon][HIT_RIGHTARM] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_5"));
		playerWStats[id][weapon][HIT_LEFTLEG] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_6"));
		playerWStats[id][weapon][HIT_RIGHTLEG] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "h_7"));

		SQL_NextRow(query);
	}

	set_bit(id, weaponStatsLoaded);

	ExecuteForward(statsForwards[FORWARD_LOADED], ret, id);
}

stock save_stats(id, end = 0)
{
	if (!get_bit(id, statsLoaded)) return;

	static queryData[2048], queryTemp[256];

	formatex(queryData, charsmax(queryData), "UPDATE `ultimate_stats` SET name = ^"%s^", steamid = ^"%s^", ip = ^"%s^", admin = %d, kills = %d, deaths = %d, hs_kills = %d, ",
	playerStats[id][SAFE_NAME], playerStats[id][STEAMID], playerStats[id][IP], playerStats[id][ADMIN], playerStats[id][STATS_KILLS], playerStats[id][STATS_DEATHS], playerStats[id][STATS_HS]);

	formatex(queryTemp, charsmax(queryTemp), "assists = %d, revenges = %d, team_kills = %d, shots = %d, hits = %d, damage = %d, rounds = %d, rounds_ct = %d, rounds_t = %d, ",
	playerStats[id][ASSISTS], playerStats[id][REVENGES], playerStats[id][STATS_TK], playerStats[id][STATS_SHOTS], playerStats[id][STATS_HITS], playerStats[id][STATS_DAMAGE], playerStats[id][ROUNDS], playerStats[id][ROUNDS_CT], playerStats[id][ROUNDS_T]);
	add(queryData, charsmax(queryData), queryTemp);

	formatex(queryTemp, charsmax(queryTemp), "wins_ct = %d, wins_t = %d, connects = %d, time = %d, defusions = %d, defused = %d,  planted = %d, exploded = %d, ",
	playerStats[id][WIN_CT], playerStats[id][WIN_T], playerStats[id][CONNECTS], playerStats[id][TIME] + get_user_time(id), playerStats[id][BOMB_DEFUSIONS], playerStats[id][BOMB_DEFUSED], playerStats[id][BOMB_PLANTED], playerStats[id][BOMB_EXPLODED]);
	add(queryData, charsmax(queryData), queryTemp);

	formatex(queryTemp, charsmax(queryTemp), "elo_rank = %.2f, h_0 = %d, h_1 = %d, h_2 = %d, h_3 = %d, h_4 = %d, h_5 = %d, h_6 = %d, h_7 = %d, last_visit = UNIX_TIMESTAMP()",
	playerStats[id][ELO_RANK], playerStats[id][HIT_GENERIC], playerStats[id][HIT_HEAD], playerStats[id][HIT_CHEST], playerStats[id][HIT_STOMACH], playerStats[id][HIT_RIGHTARM], playerStats[id][HIT_LEFTARM], playerStats[id][HIT_RIGHTLEG], playerStats[id][HIT_LEFTLEG]);
	add(queryData, charsmax(queryData), queryTemp);

	playerStats[id][CURRENT_STATS] = playerStats[id][CURRENT_KILLS] * 2 + playerStats[id][CURRENT_HS] - playerStats[id][CURRENT_DEATHS] * 2;

	if (playerStats[id][CURRENT_STATS] > playerStats[id][BEST_STATS]) {
		formatex(queryTemp, charsmax(queryTemp), ", best_stats = %d, best_kills = %d, best_hs = %d, best_deaths = %d",
		playerStats[id][CURRENT_STATS], playerStats[id][CURRENT_KILLS], playerStats[id][CURRENT_HS], playerStats[id][CURRENT_DEATHS]);
		add(queryData, charsmax(queryData), queryTemp);
	}

	new medals = playerStats[id][GOLD] * 3 + playerStats[id][SILVER] * 2 + playerStats[id][BRONZE];

	if (medals > playerStats[id][MEDALS]) {
		formatex(queryTemp, charsmax(queryTemp), ", gold = %d, silver = %d, bronze = %d, medals = '%d'",
		playerStats[id][GOLD], playerStats[id][SILVER], playerStats[id][BRONZE], medals);
		add(queryData, charsmax(queryData), queryTemp);
	}

	switch(rankSaveType) {
		case 0: formatex(queryTemp, charsmax(queryTemp), " WHERE name = ^"%s^"", playerStats[id][SAFE_NAME]);
		case 1: formatex(queryTemp, charsmax(queryTemp), " WHERE steamid = ^"%s^"", playerStats[id][STEAMID]);
		case 2: formatex(queryTemp, charsmax(queryTemp), " WHERE ip = ^"%s^"", playerStats[id][IP]);
	}

	add(queryData, charsmax(queryData), queryTemp);

	if (end == MAP_END) {
		static error[128], errorNum, Handle:query;

		query = SQL_PrepareQuery(connection, queryData);

		if (!SQL_Execute(query)) {
			errorNum = SQL_QueryError(query, error, charsmax(error));

			log_to_file("ultimate_stats.log", "SQL Query Error. [%d] %s", errorNum, error);
		}

		SQL_FreeHandle(query);
	} else SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (end == ROUND) get_rank(id);

	if (end > 0) rem_bit(id, statsLoaded);

	save_weapons_stats(id, end);
}

stock save_weapons_stats(id, end = 0)
{
	if (!get_bit(id, weaponStatsLoaded)) return;

	static queryData[4096], queryTemp[512], weaponName[32];
	queryData = "";

	for (new i = 1; i < WEAPONS_END; i++) {
		if ((i == CSW_SHIELD || i == CSW_C4 || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE) || (!playerWRStats[id][i][STATS_SHOTS] && !playerWRStats[id][i][STATS_DEATHS])) continue;

		get_weaponname(i, weaponName, charsmax(weaponName));

		formatex(queryTemp, charsmax(queryTemp), "INSERT INTO `ultimate_stats_weapons` VALUES (%d, '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d) ON DUPLICATE KEY UPDATE kills = %d, deaths = %d, hs_kills = %d, team_kills = %d, shots = %d, hits = %d, damage = %d, h_0 = %d, h_1 = %d, h_2 = %d, h_3 = %d, h_4 = %d, h_5 = %d, h_6 = %d, h_7 = %d; ",
		playerStats[id][PLAYER_ID], weaponName, playerWStats[id][i][STATS_KILLS], playerWStats[id][i][STATS_DEATHS], playerWStats[id][i][STATS_HS], playerWStats[id][i][STATS_TK], playerWStats[id][i][STATS_SHOTS], playerWStats[id][i][STATS_HITS], playerWStats[id][i][STATS_DAMAGE], playerWStats[id][i][HIT_GENERIC], playerWStats[id][i][HIT_HEAD], playerWStats[id][i][HIT_CHEST],
		playerWStats[id][i][HIT_STOMACH], playerWStats[id][i][HIT_LEFTARM], playerWStats[id][i][HIT_RIGHTARM], playerWStats[id][i][HIT_LEFTLEG], playerWStats[id][i][HIT_RIGHTLEG], playerWStats[id][i][STATS_KILLS], playerWStats[id][i][STATS_DEATHS], playerWStats[id][i][STATS_HS], playerWStats[id][i][STATS_TK], playerWStats[id][i][STATS_SHOTS], playerWStats[id][i][STATS_HITS],
		playerWStats[id][i][STATS_DAMAGE], playerWStats[id][i][HIT_GENERIC], playerWStats[id][i][HIT_HEAD], playerWStats[id][i][HIT_CHEST], playerWStats[id][i][HIT_STOMACH], playerWStats[id][i][HIT_LEFTARM], playerWStats[id][i][HIT_RIGHTARM], playerWStats[id][i][HIT_LEFTLEG], playerWStats[id][i][HIT_RIGHTLEG]);

		add(queryData, charsmax(queryData), queryTemp);
	}

	if (queryData[0]) {
		if (end == MAP_END) {
			static error[128], errorNum, Handle:query;

			query = SQL_PrepareQuery(connection, queryData);

			if (!SQL_Execute(query)) {
				errorNum = SQL_QueryError(query, error, charsmax(error));

				log_to_file("ultimate_stats.log", "SQL Query Error. [%d] %s", errorNum, error);
			}

			SQL_FreeHandle(query);
		} else SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	if (end > 0) rem_bit(id, weaponStatsLoaded);
}

public load_sounds(id)
{
	if (!soundsEnabled) return;

	new vaultKey[64], vaultData[16], soundsData[5][5];

	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", playerStats[id][NAME]);

	if (nvault_get(sounds, vaultKey, vaultData, charsmax(vaultData))) {
		parse(vaultData, soundsData[0], charsmax(soundsData), soundsData[1], charsmax(soundsData), soundsData[2], charsmax(soundsData), soundsData[3], charsmax(soundsData), soundsData[4], charsmax(soundsData));

		if (str_to_num(soundsData[0])) set_bit(id, soundMayTheForce);
		if (str_to_num(soundsData[1])) set_bit(id, soundOneAndOnly);
		if (str_to_num(soundsData[2])) set_bit(id, soundHumiliation);
		if (str_to_num(soundsData[3])) set_bit(id, soundPrepare);
		if (str_to_num(soundsData[4])) set_bit(id, soundLastLeft);
	}
}

public save_sounds(id)
{
	if (!soundsEnabled) return;

	new vaultKey[64], vaultData[16];

	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", playerStats[id][NAME]);
	formatex(vaultData, charsmax(vaultData), "%d %d %d %d %d", get_bit(id, soundMayTheForce), get_bit(id, soundOneAndOnly), get_bit(id, soundHumiliation), get_bit(id, soundPrepare), get_bit(id, soundLastLeft));

	nvault_set(sounds, vaultKey, vaultData);
}

stock get_player_id(id)
{
	new queryData[128], error[128], Handle:query, errorNum, playerId;

	switch (rankSaveType) {
		case 0: formatex(queryData, charsmax(queryData), "SELECT id FROM `ultimate_stats` WHERE name = ^"%s^"", playerStats[id][SAFE_NAME]);
		case 1: formatex(queryData, charsmax(queryData), "SELECT id FROM `ultimate_stats` WHERE steamid = ^"%s^"", playerStats[id][STEAMID]);
		case 2: formatex(queryData, charsmax(queryData), "SELECT id FROM `ultimate_stats` WHERE ip = ^"%s^"", playerStats[id][IP]);
	}

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) playerId = SQL_ReadResult(query, 0);
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("ultimate_stats.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return playerId;
}

stock get_rank_formula(dest[], length, where = 1, weapon = 0)
{
	new formula = weapon ? weaponRankFormula : rankFormula;

	switch (formula) {
		case FORMULA_KD: formatex(dest, length, "(a.kills - a.deaths - a.team_kills)%s", where ? " < (kills - deaths - team_kills)" : " DESC, a.kills DESC, a.hs_kills DESC");
		case FORMULA_KILLS: formatex(dest, length, "(a.kills)%s", where ? " < (kills)" : " DESC, a.kills, a.hs_kills DESC");
		case FORMULA_KILLS_HS: formatex(dest, length, "(a.kills + a.hs_kills)%s", where ? " < (kills + hs_kills)" : " DESC, a.kills, a.hs_kills DESC");
		case FORMULA_ELO: formatex(dest, length, "(a.elo_rank)%s", where ? " < (elo_rank)" : " DESC, a.kills, a.hs_kills DESC");
		case FORMULA_TIME: formatex(dest, length, "(a.time)%s", where ? " < (time)" : " DESC, a.kills, a.hs_kills DESC");
	}
}

stock clear_stats(player = 0, reset = 0)
{
	new limit = player ? player : MAX_PLAYERS;

	for (new id = player; id <= limit; id++) {
		playerStats[id][HUD_INFO] = false;

		if (player) playerStats[id][ELO_RANK] = _:100.0;

		for (new i = HIT_GENERIC; i <= CURRENT_HS; i++) {
			if (player) playerStats[id][i] = 0;
			if (!reset) playerRStats[id][i] = 0;
		}

		for (new i = 0; i < WEAPONS_END; i++) {
			for (new j = 0; j < STATS_END; j++) {
				if (player) playerWStats[id][i][j] = 0;

				playerWRStats[id][i][j] = 0;
			}
		}

		for (new i = 0; i <= MAX_PLAYERS; i++) {
			for (new j = 0; j < KILLER_END; j++) {
				playerAStats[id][i][j] = 0;
				playerVStats[id][i][j] = 0;
			}
		}
	}
}

stock copy_stats(id, dest[], length, stats = 0, type = 0, weapon = 0, player = 0)
{
	for (new i = 0; i < length; i++) {
		switch (type) {
			case STATS: dest[i] = playerStats[id][i + stats];
			case ROUND_STATS: dest[i] = playerRStats[id][i + stats];
			case WEAPON_STATS: dest[i] = playerWStats[id][weapon][i + stats];
			case WEAPON_ROUND_STATS: dest[i] = playerWRStats[id][weapon][i + stats];
			case ATTACKER_STATS: dest[i] = playerAStats[id][player][i + stats];
			case VICTIM_STATS: dest[i] = playerVStats[id][player][i + stats];
		}
	}
}

stock Float:accuracy(shots, hits)
{
	if (!shots) return (0.0);

	return (100.0 * float(hits) / float(shots));
}

stock Float:effec(kills, deaths)
{
	if (!kills) return (0.0);

	return (100.0 * float(kills) / float(kills + deaths));
}

stock Float:distance(distance)
	return float(distance) * 0.0254;

stock get_loguser_index()
{
	new userLog[96], userName[32];

	read_logargv(0, userLog, charsmax(userLog));
	parse_loguser(userLog, userName, charsmax(userName));

	return get_user_index(userName);
}

stock sql_safe_string(const source[], dest[], length)
{
	copy(dest, length, source);

	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}

stock cmd_execute(id, const text[], any:...)
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(text) + 2);
	write_byte(10);
	write_string(text);
	message_end();

	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}

public native_get_statsnum()
	return statsNum;

public native_get_stats(plugin, params)
{
	if (params < 5) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 5, passed %d.", params);

		return 0;
	} else if (params > 5 && params != 7) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 7, passed %d.", params);

		return 0;
	}

	new index = get_param(1);

	static queryData[256], error[128], queryTemp[96], name[32], steamId[32], stats[8], hits[8], Handle:query, errorNum;

	get_rank_formula(queryTemp, charsmax(queryTemp), 0);

	formatex(queryData, charsmax(queryData), "SELECT kills, deaths, hs_kills, team_kills, shots, hits, damage, assists, h_0, h_1, h_2, h_3, h_4, h_5, h_6, h_7, name, steamid FROM `ultimate_stats` ORDER BY %s LIMIT %d, %d", queryTemp, index, index);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) {
			for (new i = 0; i < 8; i++) stats[i] = SQL_ReadResult(query, i);
			for (new i = 0; i < 8; i++) hits[i] = SQL_ReadResult(query, i + 8);

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), name, charsmax(name));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "steamid"), steamId, charsmax(steamId));
		}
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("ultimate_stats.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	set_array(2, stats, sizeof(stats));
	set_array(3, hits, sizeof(stats));

	set_string(4, name, charsmax(name));

	if (params == 5) set_string(4, steamId, charsmax(steamId));

	return 1;
}

public native_get_stats2(plugin, params)
{
	if (params < 5) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 5, passed %d.", params);

		return 0;
	} else if (params > 5 && params != 7) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 7, passed %d.", params);

		return 0;
	}

	new index = get_param(1);

	static queryData[192], error[128], queryTemp[96], steamId[32], objectives[4], Handle:query, errorNum;

	get_rank_formula(queryTemp, charsmax(queryTemp), 0);

	formatex(queryData, charsmax(queryData), "SELECT defusions, defused, planted, exploded, steamid FROM `ultimate_stats` ORDER BY %s LIMIT %d, %d", queryTemp, index, index);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) {
			for (new i = 0; i < 4; i++) objectives[i] = SQL_ReadResult(query, i);

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "steamid"), steamId, charsmax(steamId));
		}
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("ultimate_stats.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	set_array(2, objectives, sizeof(objectives));

	if (params == 3) set_string(3, steamId, charsmax(steamId));

	return 1;
}

public native_get_user_stats(plugin, params)
{
	if (params < 3) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	static stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, STATS);
	copy_stats(id, stats, sizeof(stats), HIT_END, STATS);

	set_array(2, stats, sizeof(stats));
	set_array(3, hits, sizeof(hits));

	return 1;
}

public native_get_user_stats2(plugin, params)
{
	if (params < 2) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 2, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	static objectives[4];

	copy_stats(id, objectives, sizeof(objectives), STATS_END, STATS);

	set_array(2, objectives, sizeof(objectives));

	return 1;
}

public native_get_user_wstats(plugin, params)
{
	if (params < 4) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d.", params);

		return 0;
	}

	new id = get_param(1), weapon = get_param(2);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	} else if (!is_weapon_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid weapon - %i.", weapon);

		return 0;
	}

	static stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, WEAPON_STATS, weapon);
	copy_stats(id, stats, charsmax(stats), HIT_END, WEAPON_STATS, weapon);

	set_array(3, stats, sizeof(stats));
	set_array(4, hits, sizeof(stats));

	return 1;
}

public native_get_user_rstats(plugin, params)
{
	if (params < 3) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	static stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, ROUND_STATS);
	copy_stats(id, stats, charsmax(stats), HIT_END, ROUND_STATS);

	set_array(2, stats, sizeof(stats));
	set_array(3, hits, sizeof(stats));

	return 1;
}

public native_get_user_wrstats(plugin, params)
{
	if (params < 4) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d.", params);

		return 0;
	}

	new id = get_param(1), weapon = get_param(2);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	} else if (!is_weapon_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid weapon - %i.", weapon);

		return 0;
	}

	static stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, WEAPON_ROUND_STATS, weapon);
	copy_stats(id, stats, charsmax(stats), HIT_END, WEAPON_ROUND_STATS, weapon);

	set_array(3, stats, sizeof(stats));
	set_array(4, hits, sizeof(stats));

	return 1;
}

public native_get_user_astats(plugin, params)
{
	if (params < 4) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d.", params);

		return 0;
	} else if (params > 4 && params < 6) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 6, passed %d.", params);

		return 0;
	}

	new id = get_param(1), player = get_param(2);

	if (!is_user_valid(id) || (!is_user_valid(player) && player != 0)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", is_user_valid(id) ? player : id);

		return 0;
	}

	static weaponName[32], stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, ATTACKER_STATS, _, player);
	copy_stats(id, stats, sizeof(stats), HIT_END, ATTACKER_STATS, _, player);

	set_array(3, stats, sizeof(stats));
	set_array(4, hits, sizeof(hits));

	if (params > 4) {
		get_weaponname(stats[stat(STATS_RANK)], weaponName, charsmax(weaponName));

		set_string(5, weaponName, get_param(6));
	}

	return hits[HIT_GENERIC];
}

public native_get_user_vstats(plugin, params)
{
	if (params < 4) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d.", params);

		return 0;
	} else if (params > 4 && params < 6) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 6, passed %d.", params);

		return 0;
	}

	new id = get_param(1), player = get_param(2);

	if (!is_user_valid(id) || (!is_user_valid(player) && player != 0)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", is_user_valid(id) ? player : id);

		return 0;
	}

	static weaponName[32], stats[8], hits[8];

	copy_stats(id, hits, sizeof(hits), _, VICTIM_STATS, _, player);
	copy_stats(id, stats, sizeof(stats), HIT_END, VICTIM_STATS, _, player);

	set_array(3, stats, sizeof(stats));
	set_array(4, hits, sizeof(hits));

	if (params > 4) {
		get_weaponname(stats[stat(STATS_RANK)], weaponName, charsmax(weaponName));

		set_string(5, weaponName, get_param(6));
	}

	return hits[HIT_GENERIC];
}

public native_get_user_total_time(plugin, params)
{
	if (params < 1) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 1, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	return playerStats[id][TIME] + get_user_time(id);
}

public Float:native_get_user_elo(plugin, params)
{
	if (params < 1) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 1, passed %d.", params);

		return 0.0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0.0;
	}

	return playerStats[id][ELO_RANK];
}

public native_add_user_elo(plugin, params)
{
	if (params < 2) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 2, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	playerStats[id][ELO_RANK] += get_param_f(2);

	save_stats(id, NORMAL);

	return 1;
}

public native_reset_user_wstats(plugin, params)
{
	if (params != 1) {
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 1, passed %d.", params);

		return 0;
	}

	new id = get_param(1);

	if (!is_user_valid(id) || !is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "Invalid player - %i.", id);

		return 0;
	}

	clear_stats(id, 1);

	return 1;
}