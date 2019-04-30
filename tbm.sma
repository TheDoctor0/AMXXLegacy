#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <cvar_stocks>
#include <csstats>

//#define TBM_VIP_IMMUNITY
//#define MANUAL_SWITCH
//#define NO_ROUND_INFO_MOVED
//#define MOD_LVL

#if defined NO_ROUND_INFO_MOVED
	#include <dhudmessage>
#endif

#define PLUGIN "Team Balancer Manager"
#define VERSION "0.9.12"
#define AUTHOR "Sebul"

#pragma semicolon 1

#define MAX_PLAYERS 32
#define MAX_TXT_LEN 127
#define AUTO_TEAM 5

enum _:MAX_TEAMS {
	UNASSIGNED = 0,
	TS,
	CTS,
	SPEC
};

enum _:eCvary {
	CShowInfo = 0,
	CTransferType,
	CImmunitySwitch,
	CImmunityWtj,
	CImmunityFlags,
	CChatPrefix,
	CNoRoundMod
#if defined MOD_LVL
	,CModMaxLvl
#endif
};

enum ePluginCfg {
	bool:TBM_LIMITJOIN,
	bool:TBM_KICK,
	bool:TBM_SWITCH,
	bool:TBM_TELLWTJ,
	bool:TBM_ANNOUNCE,
	bool:TBM_SAYOK,
	bool:TBM_SAYCHECK,
	Float:TBM_MULTIPOINTS,
	Float:TBM_PLAYERFREQ,
	Float:TBM_MULTIRANK,
	TBM_LIMITAFTER,
	TBM_LIMITMIN,
	TBM_MAXCOND,
	TBM_MAXSIZE,
	TBM_MAXDIFF,
	TBM_AUTOROUNDS,
	TBM_WTJAUTO,
	TBM_WTJKICK,
	TBM_SWITCHAFTER,
	TBM_SWITCHMIN,
	TBM_SWITCHFREQ,
	TBM_PLAYERTIME,
	TBM_MAXSTREAK,
	TBM_MAXSCORE,
	TBM_CHECKDEATH,
	TBM_CHECKDEATH_MINSEC
};

enum eValues {
	HamHook:HamHandle,
	bool:MaxSizeTeam,
	TransferingCon,
	RoundNumber,
	ChecksNumber,
	LastSwitchRound,
	LastSwitchCheck,
	MaxPlayers,
	HudSyncObj,
	TeamWinner,
	TeamLoser,
	LenPrefix,
	ChatPrefix[16]
};

enum eTeamData {
	ETValidTargets[MAX_PLAYERS],
	Float:ETKDRatio,
	Float:ETSumKDRatio,
	Float:ETPoints,
	ETNumTargets,
	ETSize,
	ETKills,
	ETDeaths,
	ETWins,
	ETRowWins,
	ETCond
};

enum ePlayerData {
	EPKills,
	EPDeaths,
	Float:EPKDRatio,
	Float:EPBlockTransfer,
	bool:EPTransfering,
	bool:EPNoCheck,
	EPTeam,
	EPWTJCount
};

new const g_cTeamChars[] = {
	'U',
	'T',
	'C',
	'S'
};

new const g_sTeamNums[][] = {
	"0",
	"1",
	"2",
	"3"
};

new g_Players[MAX_PLAYERS+1][ePlayerData],
	g_Teams[MAX_TEAMS][eTeamData];

new g_Wart[eValues],
	g_Cvary[eCvary][EnumCvar];

new g_Config[ePluginCfg] = {
	true, false, true, true, true, true, true,
	2.0, 180.0, 1.0,
	0, 0, 3, 0, 2, 0, 3, 5, 2, 3, 1, 120, 2, 2, 5, 15
};

#if defined MOD_LVL
new g_forward_lvl;
#endif

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_dictionary("tbm.txt");

	AddCvar(g_Cvary[CShowInfo], ValueType_Int, register_cvar("tbm_show_info_type", "1"));
	AddCvar(g_Cvary[CTransferType], ValueType_Int, register_cvar("tbm_transfer_type", "1"));
	AddCvar(g_Cvary[CImmunitySwitch], ValueType_Bool, register_cvar("tbm_immunity_switch", "0"));
	AddCvar(g_Cvary[CImmunityWtj], ValueType_Bool, register_cvar("tbm_immunity_wtj", "0"));
	AddCvar(g_Cvary[CImmunityFlags], ValueType_Flag, register_cvar("tbm_immunity_flags", "d"));
	AddCvar(g_Cvary[CChatPrefix], ValueType_String, register_cvar("tbm_chat_prefix", "TBM"));
	AddCvar(g_Cvary[CNoRoundMod], ValueType_Bool, register_cvar("tbm_no_round_mod", "0"));
#if defined MOD_LVL
	AddCvar(g_Cvary[CModMaxLvl], ValueType_Int, register_cvar("tbm_mod_max_lvl", "201"));

	g_forward_lvl = CreateMultiForward("tbm_get_user_lvl", ET_CONTINUE, FP_CELL);
#endif

	register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "menucmd_TeamSelect");

	register_clcmd("jointeam", "clcmd_JoinTeam");
	//register_clcmd("team_join", "clcmd_TeamJoin");
	register_concmd("amx_tbm", "concmd_AdminTbm", ADMIN_RCON, "- displays TBM options");

	register_event("TeamInfo", "event_TeamInfo", "a");
	register_event("SendAudio", "event_RoundEnd", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw");
	register_event("TeamScore", "event_TeamScore", "a");
	//register_event("TextMsg", "clcmd_TeamJoin", "a", "1=1", "2&Game_join_te", "2&Game_join_ct");
	register_event("TextMsg", "event_GameRestart", "a", "2&#Game_C", "2&#Game_will_restart_in");
	register_event("DeathMsg", "event_DeathMsg", "a", "2>0");

	register_logevent("logevent_RoundStart", 2, "1=Round_Start");

	g_Wart[HudSyncObj] = CreateHudSyncObj();

	g_Wart[MaxPlayers] = get_maxplayers();

	set_task(1.0, "WczytajCfg");
}

public WczytajCfg() {
	new configsDir[64];
	get_configsdir(configsDir, 63);
	server_cmd("exec %s/tbm.cfg", configsDir);
	server_exec();

	WczytajCvary();
}

WczytajCvary() {
	for(new i=0; i<eCvary; ++i) {
		UpdateCvarValue(g_Cvary[i]);
	}

	get_pcvar_string(g_Cvary[CChatPrefix][CvarHandle], g_Wart[ChatPrefix], charsmax(g_Wart[ChatPrefix]));
	g_Wart[LenPrefix] = strlen(g_Wart[ChatPrefix]);
}

public client_connect(id) {
	g_Players[id][EPTransfering] = false;
	g_Players[id][EPNoCheck] = false;
	g_Players[id][EPTeam] = UNASSIGNED;
	g_Players[id][EPWTJCount] = 0;
}

public client_putinserver(id) {
	g_Players[id][EPBlockTransfer] = any:(get_gametime() + float(g_Config[TBM_PLAYERTIME]));

	++g_Teams[UNASSIGNED][ETSize];
}

public client_disconnected(id) {
	g_Players[id][EPKDRatio] = any:(0.0);
	g_Players[id][EPTeam] = UNASSIGNED;

	if(g_Players[id][EPTransfering]) --g_Wart[TransferingCon];

	SetValueForTeams(ETSize, 0);

	for(new i=1; i<=g_Wart[MaxPlayers]; ++i)
		++g_Teams[g_Players[i][EPTeam]][ETSize];
}

public menucmd_TeamSelect(id, key)
	return checkTeamSwitch(id, key+1);

public clcmd_JoinTeam(id) {
	new arg[2]; read_argv(1, arg, 1);
	return checkTeamSwitch(id, str_to_num(arg));
}
/*
public clcmd_TeamJoin() {
	new arg[32]; read_data(3, arg, 31);
	g_Players[get_user_index(arg)][EPBlockTransfer] = g_Config[TBM_PLAYERFREQ];
}*/

public event_RoundEnd() {
	WczytajCvary();

	new param[9];
	read_data(2, param, 8);

	if(param[7] == 'c') {
		param[0] = CTS;
		param[1] = TS;
	}
	else if(param[7] == 't') {
		param[0] = TS;
		param[1] = CTS;
	}
	else
		return;

	set_task(4.4, "actAtEndOfRoundPre", _, param, 2);
}

public actAtEndOfRoundPre(param[]) {
	new winner = param[0];
	new looser = param[1];

	if(g_Teams[winner][ETRowWins] < 1) {
		g_Teams[winner][ETRowWins] = 1;
		g_Teams[looser][ETRowWins] = 0;
	}
	else {
		++g_Teams[winner][ETRowWins];
	}

	if(g_Wart[TransferingCon] > 0)
		return;

	actAtEndOfRoundPost();
}

public event_DeathMsg() {
	new id = read_data(2);
	if(id && is_user_connected(id)) g_Players[id][EPDeaths] = get_user_deaths(id);
	new attacker = read_data(1);
	if(attacker && is_user_connected(attacker)) g_Players[attacker][EPKills] = get_user_frags(attacker);

	static Float:lastCheck = 0.0;
	new Float:cTime = get_gametime();

	if(cTime < lastCheck)
		return;

	lastCheck = cTime + g_Config[TBM_CHECKDEATH_MINSEC];

	static smierc = 0;
	if(++smierc < g_Config[TBM_CHECKDEATH])
		return;

	smierc = 0;

	WczytajCvary();

	if(!g_Cvary[CNoRoundMod][CvarValue])
		return;

	announceStatus();

	if(g_Wart[TransferingCon] > 0)
		return;

	++g_Wart[ChecksNumber];

	actAtEndOfRoundPost();
}

actAtEndOfRoundPost() {
	g_Wart[TransferingCon] = 0;

	GetKDInTeams();
	g_Teams[TS][ETPoints] = any:(Float:g_Teams[TS][ETSumKDRatio] + (g_Teams[TS][ETWins] * Float:g_Config[TBM_MULTIPOINTS]) + (g_Teams[TS][ETRowWins] * Float:g_Config[TBM_MULTIPOINTS]));
	g_Teams[CTS][ETPoints] = any:(Float:g_Teams[CTS][ETSumKDRatio] + (g_Teams[CTS][ETWins] * Float:g_Config[TBM_MULTIPOINTS]) + (g_Teams[CTS][ETRowWins] * Float:g_Config[TBM_MULTIPOINTS]));
	TeamConditions();

	if(!g_Config[TBM_SWITCH])
		return;

	if(!g_Wart[MaxSizeTeam]) {
		if(g_Cvary[CNoRoundMod][CvarValue]) {
			if(g_Wart[ChecksNumber] <= g_Config[TBM_SWITCHAFTER])
				return;

			if(g_Wart[ChecksNumber]-g_Wart[LastSwitchCheck] < g_Config[TBM_SWITCHFREQ])
				return;
		}
		else {
			if(g_Wart[RoundNumber] <= g_Config[TBM_SWITCHAFTER])
				return;

			if(g_Wart[RoundNumber]-g_Wart[LastSwitchRound] < g_Config[TBM_SWITCHFREQ])
				return;
		}
	}

	if(get_playersnospect() < g_Config[TBM_SWITCHMIN])
		return;

	GetValidTargets(TS);
	GetValidTargets(CTS);

	if(g_Config[TBM_SAYCHECK])
		tbm_show_info(0, _, _, "%L", LANG_SERVER, g_Cvary[CNoRoundMod][CvarValue] ? "CHECKING_TEAMS" : "END_ROUND");

	if(g_Wart[TeamWinner]) {
		if(g_Wart[MaxSizeTeam]) {
			doTransfer();
		}
		else {
			switch(g_Cvary[CTransferType][CvarValue]) {
				case 3: {
					if(g_Teams[g_Wart[TeamWinner]][ETSize]+floatround(g_Config[TBM_MAXDIFF]*0.5, floatround_ceil) < g_Teams[g_Wart[TeamLoser]][ETSize])
						doSwitch();
					else
						doTransfer();
				}
				case 2: {
					if(g_Teams[g_Wart[TeamWinner]][ETSize] < g_Teams[g_Wart[TeamLoser]][ETSize])
						doSwitch();
					else
						doTransfer();
				}
				default: {
					if(g_Teams[g_Wart[TeamWinner]][ETSize] <= g_Teams[g_Wart[TeamLoser]][ETSize])
						doSwitch();
					else
						doTransfer();
				}
			}
		}
	}
}

public logevent_RoundStart() {
	announceStatus();

	++g_Wart[RoundNumber];
}

public event_TeamScore() {
	new arg[2]; read_data(1, arg, 1);
	g_Teams[(arg[0] == g_cTeamChars[TS]) ? TS : (arg[0] == g_cTeamChars[CTS]) ? CTS : UNASSIGNED][ETWins] = read_data(2);
}

public event_TeamInfo() {
	new id = read_data(1);

	new sTeam[2], iTeam;
	read_data(2, sTeam, 1);

	for(new i=0; i<MAX_TEAMS; ++i) {
		if(sTeam[0] == g_cTeamChars[i]) {
			iTeam = i;
			break;
		}
	}

	if(g_Players[id][EPTeam] != iTeam) {
		--g_Teams[g_Players[id][EPTeam]][ETSize];
		g_Players[id][EPTeam] = iTeam;
		++g_Teams[iTeam][ETSize];
		g_Players[id][EPNoCheck] = false;
	}
}

public event_GameRestart() {
	WczytajCvary();

	g_Wart[RoundNumber] = 0;
	g_Wart[ChecksNumber] = 0;
	g_Wart[TransferingCon] = 0;

	new i;
	for(i=0; i<MAX_TEAMS; ++i) {
		g_Teams[i][ETKDRatio] = any:(0.0);
		g_Teams[i][ETSumKDRatio] = any:(0.0);
		g_Teams[i][ETPoints] = any:(0.0);
		g_Teams[i][ETNumTargets] = 0;
		g_Teams[i][ETKills] = 0;
		g_Teams[i][ETDeaths] = 0;
		g_Teams[i][ETWins] = 0;
		g_Teams[i][ETRowWins] = 0;
		g_Teams[i][ETCond] = 0;
	}
	//new Float:gameTime = get_gametime();
	for(i=1; i<=g_Wart[MaxPlayers]; ++i) {
		g_Players[i][EPKills] = 0;
		g_Players[i][EPDeaths] = 0;
		g_Players[i][EPKDRatio] = any:(0.0);
		g_Players[i][EPTransfering] = false;
		g_Players[i][EPNoCheck] = false;
		//g_Players[i][EPBlockTransfer] = any:(gameTime + Float:g_Config[TBM_PLAYERTIME]);
		g_Players[i][EPBlockTransfer] = any:(0.0);
		g_Players[i][EPWTJCount] = 0;
	}
}

public SpawnPre(id) {
	if(g_Players[id][EPTransfering] && is_user_connected(id)) {
		transferPlayer(id);
		g_Players[id][EPTransfering] = false;
		--g_Wart[TransferingCon];
		if(g_Wart[TransferingCon] < 1 && g_Wart[HamHandle]) DisableHamForward(g_Wart[HamHandle]);
#if defined NO_ROUND_INFO_MOVED
		if(!g_Cvary[CNoRoundMod][CvarValue])
			return;

		new przerzut[128], slen;
		formatex(przerzut, 127, "%L", id, "YOU_MOVED", (g_Players[id][EPTeam] == TS) ? "Terrorist" : "Counter-Terrorist");
		slen = strlen(przerzut);
		set_task(0.1, "PokazPrzerzut1", id, przerzut, slen);
		set_task(0.3, "PokazPrzerzut2", id, przerzut, slen);
		set_task(0.5, "PokazPrzerzut3", id, przerzut, slen);
#endif
	}
}
#if defined NO_ROUND_INFO_MOVED
public PokazPrzerzut1(tekst[], id) {
	set_dhudmessage(255, 255, 255, -1.0, 0.52, 0, 1.0, 3.0, 0.1, 0.8);
	show_dhudmessage(id, "%s", tekst);
}

public PokazPrzerzut2(tekst[], id) {
	set_dhudmessage(100, 255, 60, -1.0, 0.32, 0, 1.0, 3.0, 0.1, 0.8);
	show_dhudmessage(id, "%s", tekst);
}

public PokazPrzerzut3(tekst[], id) {
	set_dhudmessage(255, 100, 60, -1.0, 0.4, 0, 1.0, 3.0, 0.1, 0.8);
	show_dhudmessage(id, "%s", tekst);
}
#endif
SetValueForTeams(eTeamData:eData, iVal) {
	g_Teams[UNASSIGNED][eData] = g_Teams[TS][eData] = g_Teams[CTS][eData] = g_Teams[SPEC][eData] = iVal;
}

SetValueForTeamsF(eTeamData:eData, Float:fVal) {
	g_Teams[UNASSIGNED][eData] = g_Teams[TS][eData] = g_Teams[CTS][eData] = g_Teams[SPEC][eData] = any:fVal;
}

GetKDInTeams() {
	SetValueForTeams(ETKills, 0);
	SetValueForTeams(ETDeaths, 0);
	SetValueForTeamsF(ETSumKDRatio, 0.0);
#if defined MOD_LVL
	new Float:max_lvl = float((g_Cvary[CModMaxLvl][CvarValue]-1) * 2);
	if(max_lvl < 2.0) max_lvl = 2.0;
#endif
	for(new i=1,Float:ftmp,Float:rank,stats[8],bodyhits[8],Float:max_rank=float(get_statsnum()); i<=g_Wart[MaxPlayers]; ++i) {
		if(!is_user_connected(i))
			continue;

		g_Teams[g_Players[i][EPTeam]][ETKills] += g_Players[i][EPKills];
		g_Teams[g_Players[i][EPTeam]][ETDeaths] += g_Players[i][EPDeaths];

		g_Players[i][EPKDRatio] = any:(float(g_Players[i][EPKills]) / floatmax(float(g_Players[i][EPDeaths]), 0.5));

		if(Float:g_Config[TBM_MULTIRANK] > 1.0 && max_rank > 1) {
			rank = float(get_user_stats(i, stats, bodyhits));
			ftmp = g_Players[i][EPKDRatio] * (Float:g_Config[TBM_MULTIRANK] - rank/max_rank);
			g_Players[i][EPKDRatio] = any:ftmp;
		}

#if defined MOD_LVL
		ExecuteForward(g_forward_lvl, iRetLvl, i);
		if(iRetLvl > 0) {
			ftmp = g_Players[i][EPKDRatio] * (iRetLvl/max_lvl+0.5);
			g_Players[i][EPKDRatio] = any:ftmp;
		}
#endif

		ftmp = Float:g_Teams[g_Players[i][EPTeam]][ETSumKDRatio] + Float:g_Players[i][EPKDRatio];
		g_Teams[g_Players[i][EPTeam]][ETSumKDRatio] = any:ftmp;
	}
	g_Teams[UNASSIGNED][ETKDRatio] = any:(float(g_Teams[UNASSIGNED][ETKills]) / floatmax(float(g_Teams[UNASSIGNED][ETDeaths]), 0.5));
	g_Teams[TS][ETKDRatio] = any:(float(g_Teams[TS][ETKills]) / floatmax(float(g_Teams[TS][ETDeaths]), 0.5));
	g_Teams[CTS][ETKDRatio] = any:(float(g_Teams[CTS][ETKills]) / floatmax(float(g_Teams[CTS][ETDeaths]), 0.5));
	g_Teams[SPEC][ETKDRatio] = any:(float(g_Teams[SPEC][ETKills]) / floatmax(float(g_Teams[SPEC][ETDeaths]), 0.5));
}

GetValidTargets(team, bool:deadonly = false) {
	new num, i, Float:gameTime = get_gametime();
	for(i=1; i<=g_Wart[MaxPlayers]; ++i) {
		if(g_Players[i][EPTeam] != team) continue;
		if(Float:g_Players[i][EPBlockTransfer] > gameTime) continue;
		if(!is_user_connected(i)) continue;

#if defined TBM_VIP_IMMUNITY
		if(cs_get_user_vip(i)) continue;
#endif

		if(g_Cvary[CImmunitySwitch][CvarValue] && (get_user_flags(i) & g_Cvary[CImmunityFlags][CvarValue])) continue;
		if(deadonly && is_user_alive(i)) continue;

		g_Teams[team][ETValidTargets][num++] = i;
	}

	g_Teams[team][ETNumTargets] = num;
}

tbm_show_info(const id, const duration = 5, const rgb[3] = {0, 255, 0}, const string[], any:...) {
	if(!g_Cvary[CShowInfo][CvarValue])
		return;

	new buffer[256];
	vformat(buffer, 255, string, 5);

	if(!id && (g_Cvary[CShowInfo][CvarValue] & 2)) {
		set_hudmessage(rgb[0], rgb[1], rgb[2], 0.05, 0.25, 0, duration*0.5, float(duration), 0.5, 0.15, -1);
		ShowSyncHudMsg(0, g_Wart[HudSyncObj], "%s: %s", g_Wart[ChatPrefix], buffer);
	}
	if(g_Cvary[CShowInfo][CvarValue] & 1) {
		if(!id) server_print("%s: %s", g_Wart[ChatPrefix], buffer);
		buffer[190-(g_Wart[LenPrefix]+1)] = '^0';
		client_print_color(id, id, "%s: %s", g_Wart[ChatPrefix], buffer);
	}
}

transferPlayer(id) {
	if(!isValidTeam(g_Players[id][EPTeam]))
		return;

	new name[48], player_steamid[48], team_pre_transfer[12];
	get_user_name(id, name, 47);
	get_user_authid(id, player_steamid, 47);
	get_user_team(id, team_pre_transfer, 11);

	if(cs_get_user_defuse(id))
		cs_set_user_defuse(id, 0);

	cs_set_user_team(id, (g_Players[id][EPTeam] == TS) ? CTS : TS);
	//cs_reset_user_model(id);

	g_Players[id][EPBlockTransfer] = any:(get_gametime() + Float:g_Config[TBM_PLAYERFREQ]);

	// This logs to hlds logs so Psychostats knows that the player has changed team (PS 3.X)
	//"LAntz69<9><STEAM_0:1:1895474><TERRORIST>" joined team "CT"  //This is how it will be outputted in hlds logs
	log_message("^"%s<%d><%s><%s>^" joined team ^"%s^"", name, get_user_userid(id), player_steamid, team_pre_transfer, (g_Players[id][EPTeam] == TS) ? "CT" : "TERRORIST");
}

TeamConditions() {
	g_Wart[MaxSizeTeam] = false;

	if(g_Teams[TS][ETSize]-g_Teams[CTS][ETSize] > g_Config[TBM_MAXDIFF]) {
		g_Wart[TeamWinner] = TS;
		g_Wart[TeamLoser] = CTS;
		g_Wart[MaxSizeTeam] = true;
		return;
	}
	if(g_Teams[CTS][ETSize]-g_Teams[TS][ETSize] > g_Config[TBM_MAXDIFF]) {
		g_Wart[TeamWinner] = CTS;
		g_Wart[TeamLoser] = TS;
		g_Wart[MaxSizeTeam] = true;
		return;
	}

	SetValueForTeams(ETCond, 0);

	if(g_Teams[TS][ETWins]-g_Teams[CTS][ETWins] > g_Config[TBM_MAXSCORE])
		g_Teams[TS][ETCond] += g_Teams[TS][ETWins]-g_Teams[CTS][ETWins]-g_Config[TBM_MAXSCORE];
	else if(g_Teams[CTS][ETWins]-g_Teams[TS][ETWins] > g_Config[TBM_MAXSCORE])
		g_Teams[CTS][ETCond] += g_Teams[CTS][ETWins]-g_Teams[TS][ETWins]-g_Config[TBM_MAXSCORE];

	if(g_Teams[TS][ETRowWins] > g_Config[TBM_MAXSTREAK])
		g_Teams[TS][ETCond] += g_Teams[TS][ETRowWins]-g_Config[TBM_MAXSTREAK];
	else if(g_Teams[CTS][ETRowWins] > g_Config[TBM_MAXSTREAK])
		g_Teams[CTS][ETCond] += g_Teams[CTS][ETRowWins]-g_Config[TBM_MAXSTREAK];

	if(g_Teams[TS][ETSize] > g_Teams[CTS][ETSize])
		g_Teams[TS][ETCond] += g_Teams[TS][ETSize]-g_Teams[CTS][ETSize];
	else if(g_Teams[CTS][ETSize] > g_Teams[TS][ETSize])
		g_Teams[CTS][ETCond] += g_Teams[CTS][ETSize]-g_Teams[TS][ETSize];

	if(Float:g_Teams[TS][ETKDRatio] > Float:g_Teams[CTS][ETKDRatio])
		++g_Teams[TS][ETCond];
	else if(Float:g_Teams[CTS][ETKDRatio] > Float:g_Teams[TS][ETKDRatio])
		++g_Teams[CTS][ETCond];

	if(Float:g_Teams[TS][ETSumKDRatio] > Float:g_Teams[CTS][ETSumKDRatio])
		++g_Teams[TS][ETCond];
	else if(Float:g_Teams[CTS][ETSumKDRatio] > Float:g_Teams[TS][ETSumKDRatio])
		++g_Teams[CTS][ETCond];

	if(max(g_Teams[TS][ETCond], g_Teams[CTS][ETCond]) > g_Config[TBM_MAXCOND]) {
		if(g_Teams[TS][ETCond] > g_Teams[CTS][ETCond]) {
			g_Wart[TeamWinner] = TS;
			g_Wart[TeamLoser] = CTS;
		}
		else if(g_Teams[TS][ETCond] < g_Teams[CTS][ETCond]) {
			g_Wart[TeamWinner] = CTS;
			g_Wart[TeamLoser] = TS;
		}
		else {
			g_Wart[TeamWinner] = 0;
			g_Wart[TeamLoser] = 0;
		}
	}
	else {
		g_Wart[TeamWinner] = 0;
		g_Wart[TeamLoser] = 0;
	}
}

doSwitch() {
	if(g_Teams[g_Wart[TeamWinner]][ETSize] == 0 || g_Teams[g_Wart[TeamLoser]][ETSize] == 0) {
		tbm_show_info(0, _, _, "%L %L", LANG_SERVER, "NO_SWITCH_PLAYERS", LANG_SERVER, "NEED_PLAYERS");

		return;
	}
	if(g_Teams[g_Wart[TeamWinner]][ETNumTargets] == 0 || g_Teams[g_Wart[TeamLoser]][ETNumTargets] == 0) {
		tbm_show_info(0, _, _, "%L %L", LANG_SERVER, "NO_SWITCH_PLAYERS", LANG_SERVER, "NO_VALID_TARGETS");

		return;
	}

	new Float:closestScore = floatabs(Float:g_Teams[g_Wart[TeamWinner]][ETPoints] - Float:g_Teams[g_Wart[TeamLoser]][ETPoints]);
	new Float:myScore, toLoser, toWinner;
	new winner = 0, loser = 0, w, l;
	for(w=0; w<g_Teams[g_Wart[TeamWinner]][ETNumTargets]; ++w) {
		toLoser = g_Teams[g_Wart[TeamWinner]][ETValidTargets][w];
		for(l=0; l<g_Teams[g_Wart[TeamLoser]][ETNumTargets]; ++l) {
			toWinner = g_Teams[g_Wart[TeamLoser]][ETValidTargets][l];
			myScore = floatabs((Float:g_Teams[g_Wart[TeamWinner]][ETPoints]+Float:g_Players[toWinner][EPKDRatio]-Float:g_Players[toLoser][EPKDRatio]) - (Float:g_Teams[g_Wart[TeamLoser]][ETPoints]+Float:g_Players[toLoser][EPKDRatio]-Float:g_Players[toWinner][EPKDRatio]));
			if(myScore < closestScore) {
				closestScore = myScore;
				winner = toLoser;
				loser = toWinner;
			}
		}
	}
	if(!winner || !loser || !is_user_connected(winner) || !is_user_connected(loser)) {
		tbm_show_info(0, _, _, "%L", LANG_SERVER, "NO_TARGET");

		return;
	}

	g_Wart[TransferingCon] = 2;

	if(g_Wart[HamHandle]) EnableHamForward(g_Wart[HamHandle]);
	else g_Wart[HamHandle] = any:RegisterHam(Ham_Spawn, "player", "SpawnPre", 0);

	g_Wart[LastSwitchRound] = g_Wart[RoundNumber];
	g_Wart[LastSwitchCheck] = g_Wart[ChecksNumber];

	new winnerName[48], loserName[48];
	get_user_name(winner, winnerName, 47);
	get_user_name(loser, loserName, 47);

	g_Players[winner][EPTransfering] = true;
	g_Players[loser][EPTransfering] = true;

	tbm_show_info(0, _, _, "%L", LANG_SERVER, "SWITCH_PLAYERS", winnerName, loserName);
}

doTransfer() {
	if(g_Teams[g_Wart[TeamWinner]][ETSize] <= 1) {
		tbm_show_info(0, _, _, "%L %L", LANG_SERVER, "NO_MOVE_PLAYER", LANG_SERVER, "NEED_PLAYERS_WIN");

		return;
	}
	if(g_Teams[g_Wart[TeamWinner]][ETNumTargets] <= 1) {
		tbm_show_info(0, _, _, "%L %L", LANG_SERVER, "NO_MOVE_PLAYER", LANG_SERVER, "NO_VALID_TARGET_WIN");

		return;
	}

	new Float:closestScore;
	new toLoser, winner, w;

	if(g_Wart[MaxSizeTeam]) {
		closestScore = Float:g_Teams[g_Wart[TeamWinner]][ETPoints];
		for(w=0; w<g_Teams[g_Wart[TeamWinner]][ETNumTargets]; ++w) {
			toLoser = g_Teams[g_Wart[TeamWinner]][ETValidTargets][w];
			if(Float:g_Players[toLoser][EPKDRatio] < closestScore) {
				closestScore = Float:g_Players[toLoser][EPKDRatio];
				winner = toLoser;
			}
		}
	}
	else {
		new Float:myScore;
		closestScore = floatabs(Float:g_Teams[g_Wart[TeamWinner]][ETPoints] - Float:g_Teams[g_Wart[TeamLoser]][ETPoints]);
		for(w=0; w<g_Teams[g_Wart[TeamWinner]][ETNumTargets]; ++w) {
			toLoser = g_Teams[g_Wart[TeamWinner]][ETValidTargets][w];
			myScore = floatabs((Float:g_Teams[g_Wart[TeamWinner]][ETPoints]-Float:g_Players[toLoser][EPKDRatio]) - (Float:g_Teams[g_Wart[TeamLoser]][ETPoints]+Float:g_Players[toLoser][EPKDRatio]));
			if(myScore < closestScore) {
				closestScore = myScore;
				winner = toLoser;
			}
		}
	}
	if(!winner || !is_user_connected(winner)) {
		tbm_show_info(0, _, _, "%L", LANG_SERVER, "NO_TARGET");

		return;
	}

	g_Wart[TransferingCon] = 1;

	if(g_Wart[HamHandle]) EnableHamForward(g_Wart[HamHandle]);
	else g_Wart[HamHandle] = any:RegisterHam(Ham_Spawn, "player", "SpawnPre", 0);

	g_Wart[LastSwitchRound] = g_Wart[RoundNumber];
	g_Wart[LastSwitchCheck] = g_Wart[ChecksNumber];

	new winnerName[48];
	get_user_name(winner, winnerName, 47);

	g_Players[winner][EPTransfering] = true;

	tbm_show_info(0, _, _, "%L", LANG_SERVER, "TRANSFER_PLAYER", winnerName, (g_Wart[TeamWinner] == TS) ? "CT" : "TT");
}

checkTeamSwitch(id, iNewTeam) {
	if(!g_Config[TBM_LIMITJOIN])
		return PLUGIN_CONTINUE;

	if(g_Cvary[CImmunityWtj][CvarValue] && (get_user_flags(id) & g_Cvary[CImmunityFlags][CvarValue]))
		return PLUGIN_CONTINUE;

	if(g_Players[id][EPNoCheck])
		return PLUGIN_CONTINUE;

	if(g_Config[TBM_LIMITAFTER]) {
		if(g_Cvary[CNoRoundMod][CvarValue]) {
			if(g_Wart[ChecksNumber] <= g_Config[TBM_LIMITAFTER])
				return PLUGIN_CONTINUE;
		}
		else if(g_Wart[RoundNumber] <= g_Config[TBM_LIMITAFTER])
			return PLUGIN_CONTINUE;
	}

	if(get_playersnospect() < g_Config[TBM_LIMITMIN])
		return PLUGIN_CONTINUE;

	new iOldTeam = g_Players[id][EPTeam];

	if(isValidTeam(iOldTeam) && isValidTeam(iNewTeam) && Float:g_Players[id][EPBlockTransfer] > get_gametime()) {
		tbm_show_info(id, _, _, "%L", id, "STAY_TEAM");

#if !defined MANUAL_SWITCH
		engclient_cmd(id, "chooseteam");
#endif

		return PLUGIN_HANDLED;
	}

	if(g_Config[TBM_AUTOROUNDS] && iOldTeam == UNASSIGNED && !(get_user_flags(id) & ADMIN_KICK)) {
		if(g_Cvary[CNoRoundMod][CvarValue]) {
			if(g_Wart[ChecksNumber] <= g_Config[TBM_AUTOROUNDS])
				iNewTeam = AUTO_TEAM;
		}
		else if(g_Wart[RoundNumber] <= g_Config[TBM_AUTOROUNDS])
			iNewTeam = AUTO_TEAM;
	}

	if(iNewTeam == iOldTeam) {
		tbm_show_info(id, _, _, "%L", id, "JOIN_THE_SAME_TEAM");

#if !defined MANUAL_SWITCH
		engclient_cmd(id, "chooseteam");
#endif

		return PLUGIN_HANDLED;
	}

	if((iNewTeam == CTS && iOldTeam == TS) || (iNewTeam == TS && iOldTeam == CTS)) {
		if(g_Teams[iNewTeam][ETSize] > 0 && g_Teams[iOldTeam][ETSize] < g_Config[TBM_MAXSIZE] && (iNewTeam == g_Wart[TeamWinner] || g_Teams[iNewTeam][ETSize] >= g_Teams[iOldTeam][ETSize])) {
			new name[48];
			get_user_name(id, name, 47);

			if(++g_Players[id][EPWTJCount] >= g_Config[TBM_WTJKICK] && g_Config[TBM_KICK]) {
				tbm_show_info(0, _, _, "%L", LANG_SERVER, "KICK_WTJ", name, g_Players[id][EPWTJCount], g_Config[TBM_WTJKICK]);
				server_cmd("kick #%d", get_user_userid(id));

				return PLUGIN_HANDLED;
			}
			if(g_Config[TBM_TELLWTJ]) {
				new rgb[3] = {0, 50, 0};
				rgb[0] = (iNewTeam == TS) ? 255 : 0;
				rgb[2] = (iNewTeam == CTS) ? 255 : 0;
				tbm_show_info(0, _, rgb, "%L", LANG_SERVER, "TELL_WTJ", (iNewTeam == CTS) ? "CT" : "TT", name, g_Players[id][EPWTJCount], g_Config[TBM_WTJKICK]);
			}

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}
		if(g_Teams[iNewTeam][ETSize] >= g_Config[TBM_MAXSIZE]) {
			tbm_show_info(id, _, _, "%L", id, "MAX_SIZE_JOIN");

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}
		if(g_Teams[iNewTeam][ETSize]-g_Teams[iOldTeam][ETSize] >= g_Config[TBM_MAXDIFF]) {
			tbm_show_info(id, _, _, "%L", id, "MAX_DIFF_JOIN");

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}

		return PLUGIN_CONTINUE;
	}
	else if(iNewTeam == CTS || iNewTeam == TS) {
		new opposingTeam = (iNewTeam == CTS) ? TS : CTS;
		if(g_Teams[iNewTeam][ETSize] > 0 && g_Teams[opposingTeam][ETSize] < g_Config[TBM_MAXSIZE] && (iNewTeam == g_Wart[TeamWinner] || (!g_Wart[TeamWinner] && g_Teams[iNewTeam][ETSize] > g_Teams[opposingTeam][ETSize]))) {
			new name[48];
			get_user_name(id, name, 47);

			if(++g_Players[id][EPWTJCount] >= g_Config[TBM_WTJKICK] && g_Config[TBM_KICK]) {
				tbm_show_info(0, _, _, "%L", LANG_SERVER, "KICK_WTJ", name, g_Players[id][EPWTJCount], g_Config[TBM_WTJKICK]);
				server_cmd("kick #%d", get_user_userid(id));

				return PLUGIN_HANDLED;
			}
			if(g_Players[id][EPWTJCount] >= g_Config[TBM_WTJAUTO] && is_user_connected(id)) {
				g_Players[id][EPNoCheck] = true;
				engclient_cmd(id, "jointeam", g_sTeamNums[opposingTeam]);

				if(g_Config[TBM_TELLWTJ]) {
					new rgb[3] = {0, 50, 0};
					rgb[0] = (iNewTeam == CTS) ? 255 : 0;
					rgb[2] = (iNewTeam == TS) ? 255 : 0;
					tbm_show_info(0, _, rgb, "%L", LANG_SERVER, "SWITCH_WTJ", name, (iNewTeam == CTS) ? "TT" : "CT", g_Players[id][EPWTJCount], g_Config[TBM_WTJAUTO]);
				}
			}
			else if(g_Config[TBM_TELLWTJ]) {
				new rgb[3] = {0, 50, 0};
				rgb[0] = (iNewTeam == TS) ? 255 : 0;
				rgb[2] = (iNewTeam == CTS) ? 255 : 0;
				tbm_show_info(0, _, rgb, "%L", LANG_SERVER, "TELL_WTJ", (iNewTeam == CTS) ? "CT" : "TT", name, g_Players[id][EPWTJCount], g_Config[TBM_WTJAUTO]);

#if !defined MANUAL_SWITCH
				engclient_cmd(id, "chooseteam");
#endif
			}

			return PLUGIN_HANDLED;
		}
		if(g_Teams[iNewTeam][ETSize] >= g_Config[TBM_MAXSIZE]) {
			tbm_show_info(id, _, _, "%L", id, "MAX_SIZE_JOIN");

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}
		if(g_Teams[iNewTeam][ETSize]-g_Teams[opposingTeam][ETSize] >= g_Config[TBM_MAXDIFF]) {
			tbm_show_info(id, _, _, "%L", id, "MAX_DIFF_JOIN");

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}

		return PLUGIN_CONTINUE;
	}
	else if(iNewTeam == AUTO_TEAM && (iOldTeam == CTS || iOldTeam == TS)) {
		new opposingTeam = (iOldTeam == CTS) ? TS : CTS;
		if(g_Teams[opposingTeam][ETSize] > 0 && (g_Teams[opposingTeam][ETSize] >= g_Config[TBM_MAXSIZE] || iOldTeam == g_Wart[TeamLoser]
		|| (!g_Wart[TeamLoser] && g_Teams[iOldTeam][ETSize] <= g_Teams[opposingTeam][ETSize]) || (g_Teams[opposingTeam][ETSize]-g_Teams[iOldTeam][ETSize] >= g_Config[TBM_MAXDIFF]))) {
			tbm_show_info(id, _, _, "%L", id, "STAY_TEAM");

			return PLUGIN_HANDLED;
		}
		g_Players[id][EPNoCheck] = true;
		engclient_cmd(id, "jointeam", g_sTeamNums[opposingTeam]);

		tbm_show_info(id, _, _, "%L", id, "AUTO_JOIN");

		return PLUGIN_HANDLED;
	}
	else if(iNewTeam == AUTO_TEAM) {
		if(g_Teams[CTS][ETSize] >= g_Config[TBM_MAXSIZE]) iNewTeam = TS;
		else if(g_Teams[TS][ETSize] >= g_Config[TBM_MAXSIZE]) iNewTeam = CTS;
		else if(g_Teams[CTS][ETSize]-g_Teams[TS][ETSize] >= g_Config[TBM_MAXDIFF]) iNewTeam = TS;
		else if(g_Teams[TS][ETSize]-g_Teams[CTS][ETSize] >= g_Config[TBM_MAXDIFF]) iNewTeam = CTS;
		else if(g_Wart[TeamWinner]) iNewTeam = g_Wart[TeamLoser];
		else if(g_Teams[CTS][ETSize] < g_Teams[TS][ETSize]) iNewTeam = CTS;
		else if(g_Teams[TS][ETSize] < g_Teams[CTS][ETSize]) iNewTeam = TS;
		else iNewTeam = (random(50) < 25) ? CTS : TS;

		if(g_Teams[iNewTeam][ETSize] >= g_Config[TBM_MAXSIZE]) {
			tbm_show_info(id, _, _, "%L", id, "MAX_SIZE_JOIN");

#if !defined MANUAL_SWITCH
			engclient_cmd(id, "chooseteam");
#endif

			return PLUGIN_HANDLED;
		}
		g_Players[id][EPNoCheck] = true;
		engclient_cmd(id, "jointeam", g_sTeamNums[iNewTeam]);

		tbm_show_info(id, _, _, "%L", id, "AUTO_JOIN");

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

announceStatus() {
	if(!g_Config[TBM_ANNOUNCE])
		return;

	if(!g_Cvary[CNoRoundMod][CvarValue] && !g_Wart[RoundNumber])
		return;

	if(g_Wart[TeamWinner]) {
		tbm_show_info(0, _, _, "%L", LANG_SERVER, "TEAM_BACKUP", (g_Wart[TeamWinner] == TS) ? "CT" : "TT");
	}
	else if((g_Teams[TS][ETCond] || g_Teams[CTS][ETCond]) && g_Teams[TS][ETCond] != g_Teams[CTS][ETCond]) {
		tbm_show_info(0, _, _, "%L", LANG_SERVER, "TEAM_LOOK", g_Teams[TS][ETCond] > g_Teams[CTS][ETCond] ? "TT" : "CT");
	}
	else if(g_Config[TBM_SAYOK]) {
		tbm_show_info(0, _, _, "%L", LANG_SERVER, "TEAM_OK");
	}
}

displayStatistics(id, bool:toLog = false) {
	new text[MAX_TXT_LEN+1];

	formatex(text, MAX_TXT_LEN, "TBM: Polaczeni gracze: %i", get_playersnum());
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Wielkosc druzyn: CT - %i, TT - %i", g_Teams[CTS][ETSize], g_Teams[TS][ETSize]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Ilosc graczy do transferu: CT - %i, TT - %i", g_Teams[CTS][ETNumTargets], g_Teams[TS][ETNumTargets]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Suma zabic druzyn: CT - %i, TT - %i", g_Teams[CTS][ETKills], g_Teams[TS][ETKills]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Suma smierci druzyn: CT - %i, TT - %i", g_Teams[CTS][ETDeaths], g_Teams[TS][ETDeaths]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: KD druzyn: CT - %.3f, TT - %.3f", Float:g_Teams[CTS][ETKDRatio], Float:g_Teams[TS][ETKDRatio]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Suma KD druzyn: CT - %.3f, TT - %.3f", Float:g_Teams[CTS][ETSumKDRatio], Float:g_Teams[TS][ETSumKDRatio]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Punkty druzyn: CT - %.3f, TT - %.3f", Float:g_Teams[CTS][ETPoints], Float:g_Teams[TS][ETPoints]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	formatex(text, MAX_TXT_LEN, "TBM: Wygrane druzyn: CT - %i, TT - %i", g_Teams[CTS][ETWins], g_Teams[TS][ETWins]);
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);

	if(g_Teams[CTS][ETRowWins] || g_Teams[TS][ETRowWins]) {
		formatex(text, MAX_TXT_LEN, "TBM: Ostatnie %i rund/y zostaly wygrane przez %s.", g_Teams[CTS][ETRowWins] > 0 ? g_Teams[CTS][ETRowWins] : g_Teams[TS][ETRowWins], g_Teams[CTS][ETRowWins] > 0 ? "CT" : "TT");
		if(toLog) log_amx("%s", text);
		console_print(id, "%s", text);
	}

	switch(g_Wart[TeamWinner]) {
		case CTS: formatex(text, MAX_TXT_LEN, "TBM: Druzyna wygrywajaca to CT.");
		case TS: formatex(text, MAX_TXT_LEN, "TBM: Druzyna wygrywajaca to TT.");
		default: formatex(text, MAX_TXT_LEN, "TBM: Druzyny sa zbalansowane.");
	}
	if(toLog) log_amx("%s", text);
	console_print(id, "%s", text);
}

public concmd_AdminTbm(id, level, cid) {
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new cmd[32];

	if(read_argv(1, cmd, 31) == 0) {
		displayStatistics(id);

		return PLUGIN_HANDLED;
	}
	if(equali(cmd, "on") || equal(cmd, "1")) {
		g_Config[TBM_LIMITJOIN] = true;
		g_Config[TBM_SWITCH] = true;
		g_Config[TBM_ANNOUNCE] = true;
		console_print(id, "TBM: Wlaczono wszystkie opcje TBM.");

		return PLUGIN_HANDLED;
	}
	if(equali(cmd, "off") || equal(cmd, "0")) {
		g_Config[TBM_LIMITJOIN] = false;
		g_Config[TBM_SWITCH] = false;
		g_Config[TBM_ANNOUNCE] = false;
		console_print(id, "TBM: Wylaczono wszystkie opcje TBM.");

		return PLUGIN_HANDLED;
	}
	if(equali(cmd, "list") || equali(cmd, "help")) {
		console_print(id, "TBM: Dostepne komendy:");
		console_print(id, "TBM: Team Join Control: ^"limitjoin^", ^"limitafter^", ^"limitmin^", ^"maxsize^", ^"autorounds^",");
		console_print(id, "TBM: ^"maxdiff^", ^"wtjauto^", ^"wtjkick^", ^"kick^"");
		console_print(id, "TBM: Team Balancing Actions: ^"switch^", ^"switchafter^", ^"switchmin^", ^"switchfreq^", ^"playerfreq^",");
		console_print(id, "TBM: Team Strength Limits: ^"maxstreak^", ^"maxscore^", ^"multifrags^", ^"multipoints^", ^"maxincidents^", ^"scaledown^"");
		console_print(id, "TBM: Messages: ^"tellwtj^", ^"announce^", ^"sayok^"");
		console_print(id, "TBM: Misc: ^"status^", ^"list^", ^"help^", ^"on^", ^"off^"");
		console_print(id, "TBM: Aby zobaczyc wszystkie opcje TBM, wpisz ^"amx_tbm status^".");
		console_print(id, "TBM: Aby zobaczy lub zmienic jedna opcje TBM, wpisz ^"amx_tbm <setting> <on|off|value>^".");
		console_print(id, "TBM: Aby zobaczyc statystyki dla TBM, wpisz ^"amx_tbm^".");

		return PLUGIN_HANDLED;
	}
	new arg[16], arglen = read_argv(2, arg, 15);
	new lastcmd, status = equali(cmd, "status");

	// team selection control
	if(status) console_print(id, "TBM: ---------- Team Join Control ----------");

	if((lastcmd = equali(cmd, "limitjoin")) && arglen) g_Config[TBM_LIMITJOIN] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (limitjoin) WTJ jest %s.", g_Config[TBM_LIMITJOIN] ? "WL" : "WYL");

	if((lastcmd = equali(cmd, "limitafter")) && arglen) g_Config[TBM_LIMITAFTER] = check_param_num(arg, 0);
	if(status || lastcmd) console_print(id, "TBM: (limitafter) Ograniczanie zespolow zaczyna sie po %i rundzie.", g_Config[TBM_LIMITAFTER]);

	if((lastcmd = equali(cmd, "limitmin")) && arglen) g_Config[TBM_LIMITMIN] = check_param_num(arg, 0);
	if(status || lastcmd) console_print(id, "TBM: (limitmin) Aby ograniczanie zespolow dzialalo, potrzeba przynajmniej %i graczy.", g_Config[TBM_LIMITMIN]);

	if((lastcmd = equali(cmd, "maxsize")) && arglen) g_Config[TBM_MAXSIZE] = check_param_num(arg, 0);
	if(g_Config[TBM_MAXSIZE] < 1) g_Config[TBM_MAXSIZE] = g_Wart[MaxPlayers]/2 + 1;
	if(status || lastcmd) console_print(id, "TBM: (maxsize) Maksymalna wielkosc druzyny to %i graczy.", g_Config[TBM_MAXSIZE]);

	if((lastcmd = equali(cmd, "maxdiff")) && arglen) g_Config[TBM_MAXDIFF] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (maxdiff) Maksymalna roznica pomiedzy druzynami to %i.", g_Config[TBM_MAXDIFF]);

	if((lastcmd = equali(cmd, "autorounds")) && arglen) g_Config[TBM_AUTOROUNDS] = check_param_num(arg, 0);
	if(status || lastcmd) console_print(id, "TBM: (autorounds) Przez pierwsze %i rund/y gracze sa przydzielani automatycznie do druzyn.", g_Config[TBM_AUTOROUNDS]);

	if((lastcmd = equali(cmd, "wtjauto")) && arglen) g_Config[TBM_WTJAUTO] = check_param_num(arg, 0);
	if(status || lastcmd) console_print(id, "TBM: (wtjauto) Automatycznie przydzielaj do druzyny po %i probach WTJ.", g_Config[TBM_WTJAUTO]);

	if((lastcmd = equali(cmd, "wtjkick")) && arglen) g_Config[TBM_WTJKICK] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (wtjkick) Automatycznie kickuj gracza po %i probach WTJ.", g_Config[TBM_WTJKICK]);

	if((lastcmd = equali(cmd, "kick")) && arglen) g_Config[TBM_KICK] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (kick) Kickowanie za WTJ jest %s.", g_Config[TBM_KICK] ? "WL" : "WYL");


	if(status) console_print(id, "TBM: ---------- Team Balancing Actions ----------");

	if((lastcmd = equali(cmd, "switch")) && arglen) g_Config[TBM_SWITCH] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (switch) Przenoszenie graczy jest %s.", g_Config[TBM_SWITCH] ? "WL" : "WYL");

	if((lastcmd = equali(cmd, "switchafter")) && arglen) g_Config[TBM_SWITCHAFTER] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (switchafter) Przenoszenie graczy zaczyna sie po %i rundzie.", g_Config[TBM_SWITCHAFTER]);

	if((lastcmd = equali(cmd, "switchmin")) && arglen) g_Config[TBM_SWITCHMIN] = check_param_num(arg, 3);
	if(status || lastcmd) console_print(id, "TBM: (switchmin) Aby przenoszenie graczy dzialalo, potrzeba przynajmniej %i graczy.", g_Config[TBM_SWITCHMIN]);

	if((lastcmd = equali(cmd, "playerfreq")) && arglen) g_Config[TBM_PLAYERFREQ] = any:check_param_float(arg, 0.0);
	if(status || lastcmd) console_print(id, "TBM: (playerfreq) Jeden gracz moze byc przenoszony raz na %.1f sekund/y.", Float:g_Config[TBM_PLAYERFREQ]);

	if((lastcmd = equali(cmd, "playertime")) && arglen) g_Config[TBM_PLAYERTIME] = check_param_num(arg, 0);
	if(status || lastcmd) console_print(id, "TBM: (playertime) Gracz moze byc przenoszony %i sekund po wejsciu na serwer.", g_Config[TBM_PLAYERTIME]);

	if((lastcmd = equali(cmd, "switchfreq")) && arglen) g_Config[TBM_SWITCHFREQ] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (switchfreq) Przenoszenie graczy odbywa sie raz na %i rund/y.", g_Config[TBM_SWITCHFREQ]);
	
	if((lastcmd = equali(cmd, "deathswitchfreq")) && arglen) g_Config[TBM_CHECKDEATH] = check_param_num(arg, 3);
	if(status || lastcmd) console_print(id, "TBM: (deathswitchfreq) Przenoszenie graczy odbywa sie raz na %i zgony/ow.", g_Config[TBM_CHECKDEATH]);

	if((lastcmd = equali(cmd, "deathswitchfreq_minsec")) && arglen) g_Config[TBM_CHECKDEATH_MINSEC] = check_param_num(arg, 5);
	if(status || lastcmd) console_print(id, "TBM: (deathswitchfreq_minsec) Ograniczanie przenoszenia graczy raz na %i sekund/y.", g_Config[TBM_CHECKDEATH_MINSEC]);


	if(status) console_print(id, "TBM: ---------- Messages ----------");

	if((lastcmd = equali(cmd, "tellwtj")) && arglen) g_Config[TBM_TELLWTJ] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (tellwtj) Powiadamianie graczy o probach WTJ jest %s.", g_Config[TBM_TELLWTJ] ? "WL" : "WYL");

	if((lastcmd = equali(cmd, "announce")) && arglen) g_Config[TBM_ANNOUNCE] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (announce) Ogloszenia TBM sa %s.", g_Config[TBM_ANNOUNCE] ? "WL" : "WYL");

	if((lastcmd = equali(cmd, "sayok")) && arglen) g_Config[TBM_SAYOK] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (sayok) Ogloszenia mowiace, ze jest ^"OK^" sa %s.", g_Config[TBM_SAYOK] ? "WL" : "WYL");

	if((lastcmd = equali(cmd, "saycheck")) && arglen) g_Config[TBM_SAYCHECK] = check_param_bool(arg);
	if(status || lastcmd) console_print(id, "TBM: (saycheck) Ogloszenie przy sprwadzaniu druzyn jest %s.", g_Config[TBM_SAYCHECK] ? "WL" : "WYL");


	if(status) console_print(id, "TBM: ---------- Team Strength Limits ----------");

	if((lastcmd = equali(cmd, "maxstreak")) && arglen) g_Config[TBM_MAXSTREAK] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (maxstreak) Maksymalna dozwolona ilosc wygranych rund z rzedu to %i.", g_Config[TBM_MAXSTREAK]);

	if((lastcmd = equali(cmd, "maxscore")) && arglen) g_Config[TBM_MAXSCORE] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (maxscore) Maksymalna dozwolona roznica w wygranych rundach to %i.", g_Config[TBM_MAXSCORE]);

	if((lastcmd = equali(cmd, "maxcond")) && arglen) g_Config[TBM_MAXCOND] = check_param_num(arg, 1);
	if(status || lastcmd) console_print(id, "TBM: (maxcond) Maksymalna dozwolona sila druzyny to %i.", g_Config[TBM_MAXCOND]);

	if((lastcmd = equali(cmd, "multipoints")) && arglen) g_Config[TBM_MULTIPOINTS] = any:check_param_float(arg, 2.0);
	if(status || lastcmd) console_print(id, "TBM: (multipoints) Wygrane rundy, itp. beda przemnazane przez %.2f.", Float:g_Config[TBM_MULTIPOINTS]);

	if((lastcmd = equali(cmd, "multirank")) && arglen) g_Config[TBM_MULTIRANK] = any:check_param_float(arg, 1.0);
	if(status || lastcmd) console_print(id, "TBM: (multirank) Punkty gracza beda dodatkowo przemnazane przez (%.2f - POZYCJA_W_RANKINGU / OSTATNIA_POZYCJA_RANKINUG).", Float:g_Config[TBM_MULTIRANK]);


	if(status) {
		console_print(id, "TBM: ---------- Misc ----------");
		console_print(id, "TBM: Aby wlaczyc lub wylaczyc TBM, wpisz ^"amx_tbm <on|1|off|0>^".");
		console_print(id, "TBM: Aby zobaczy lub zmienic jedna opcje TBM, wpisz ^"amx_tbm <setting> <on|off|value>^".");
		console_print(id, "TBM: Aby zobaczyc liste komend, wpisz ^"amx_tbm help^" lub ^"amx_tbm list^".");
		console_print(id, "TBM: Aby zobaczyc statystyki dla TBM, wpisz ^"amx_tbm^".");
	}

	return PLUGIN_HANDLED;
}

stock bool:check_param_bool(const param[])
	return bool:(equali(param, "on") || equal(param, "1"));

stock bool:isValidTeam(team)
	return bool:(UNASSIGNED < team < SPEC);

stock Float:check_param_float(const param[], Float:n) {
	new Float:a = floatstr(param);
	if(a < n) a = n;
	return a;
}

stock check_param_num(const param[], n) {
	new a = str_to_num(param);
	if(a < n) a = n;
	return a;
}

stock get_playersnospect() {
	new playerCnt, i;
	for(i=1; i<=g_Wart[MaxPlayers]; ++i)
		if(isValidTeam(g_Players[i][EPTeam]) && is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i)) ++playerCnt;

	return playerCnt;
}
