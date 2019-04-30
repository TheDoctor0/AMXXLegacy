#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <unixtime>
#include <nvault>

#define PLUGIN "Rank System"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

#define TASK_HUD 7501
#define TASK_TIME 6701

#define MAX_RANKS 18

#define STATS 1
#define TEAMRANK 2
#define ENEMYRANK 4
#define ABOVEHEAD 8

enum Stats
{
	Name[64],
	Kills,
	Rank,
	Time,
	FirstVisit,
	LastVisit,
	Bronze,
	Silver,
	Gold,
	Medals,
	BestStats,
	BestKills,
	BestDeaths,
	BestHS,
	CurrentStats,
	CurrentKills,
	CurrentDeaths,
	CurrentHS,
};

new sBuffer[2048], g_Player[MAX_PLAYERS+1][Stats], g_Loaded[MAX_PLAYERS+1], g_Visit[MAX_PLAYERS+1], g_Friend[MAX_PLAYERS+1], 
	szTable[32], g_Sprite[MAX_RANKS], g_SqlLoaded, g_HUD, g_AimHUD, g_PlayerName, Handle:g_SqlTuple, bool:oneAndOnly, 
	bool:block, round, sounds, soundMayTheForce, soundOneAndOnly, soundPrepare, soundHumiliation, soundLastLeft;

new const g_RankName[MAX_RANKS][] = 
{
	"Silver I",
	"Silver II",
	"Silver III",
	"Silver IV",
	"Silver Elite",
	"Silver Elite Master",
	"Gold Nova I",
	"Gold Nova II",
	"Gold Nova III",
	"Gold Nova Master",
	"Master Guardian I",
	"Master Guardian II",
	"Master Guardian Elite",
	"Distinguished Master Guardian",
	"Legendary Eagle",
	"Legendary Eagle Master",
	"Supreme Master First Class",
	"The Global Elite"
};

new const g_RankKills[MAX_RANKS] = 
{
	0,
	25,
	50,
	100,
	250,
	500,
	800,
	1200,
	1800,
	2500,
	3300,
	4100,
	5000,
	6000,
	7000,
	8000,
	9000,
	10000
};

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("rank_system_host", "sql.pukawka.pl", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_user", "298272", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_pass", "fNhrZmHuOortS7C2", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_database", "298272_rank", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_table", "rank_system", FCVAR_SPONLY | FCVAR_PROTECTED);
	
	register_clcmd("say /rangi", "CmdRanks");
	register_clcmd("sayteam /rangi", "CmdRanks");
	register_clcmd("say /ranga", "CmdRank")
	register_clcmd("sayteam /ranga", "CmdRank");
	register_clcmd("say /toprangi", "CmdTopRank")
	register_clcmd("sayteam /toprangi", "CmdTopRank");
	register_clcmd("say /czas", "CmdTime")
	register_clcmd("sayteam /czas", "CmdTime");
	register_clcmd("say /topczas", "CmdTimeTop")
	register_clcmd("sayteam /topczas", "CmdTimeTop");
	register_clcmd("say /medale", "CmdMedals");
	register_clcmd("sayteam /medale", "CmdMedals");
	register_clcmd("say /topmedale", "CmdTopMedals");
	register_clcmd("sayteam /topmedale", "CmdTopMedals");
	register_clcmd("say /staty", "CmdStats");
	register_clcmd("sayteam /staty", "CmdStats");
	register_clcmd("say /topstaty", "CmdTopStats");
	register_clcmd("sayteam /topstaty", "CmdTopStats");
	register_clcmd("say /dzwieki", "CmdSound");
	register_clcmd("sayteam /dzwieki", "CmdSound");
	register_clcmd("say /dzwiek", "CmdSound");
	register_clcmd("sayteam /dzwiek", "CmdSound");
	register_clcmd("say /sound", "CmdSound");
	register_clcmd("sayteam /sound", "CmdSound");

	RegisterHam(Ham_Spawn , "player", "Spawn", 1);
	
	register_message(SVC_INTERMISSION, "MsgIntermission");
	
	register_event("TextMsg", "RoundRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("StatusValue", "SetTeam", "be", "1=1");
	register_event("StatusValue", "ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "HideStatus", "be", "1=1", "2=0");
	
	g_PlayerName = get_xvar_id("PlayerName");
	
	g_HUD = CreateHudSyncObj();
	g_AimHUD = CreateHudSyncObj();

	sounds = nvault_open("stats_sound");
}

public plugin_cfg()
	SqlInit();
	
public plugin_end()
	SQL_FreeHandle(g_SqlTuple);
	
public plugin_natives()
{
	register_native("stats_add_kill", "native_stats_add_kill");
	register_native("stats_get_kills", "native_stats_get_kills");
}
	
public plugin_precache()
{
	new szSpriteFile[32], bool:Error;
	
	for (new i = 0; i < MAX_RANKS; i++)
	{
		szSpriteFile[0] = '^0';
		formatex(szSpriteFile, charsmax(szSpriteFile), "sprites/rank_system/%d.spr", i);
		
		if(!file_exists(szSpriteFile))
		{
			log_to_file("addons/amxmodx/logs/rank_system.txt", "[RANK] Brakujacy plik sprite: ^"%s^"", szSpriteFile);
			Error = true;
		}
		else
			g_Sprite[i] = precache_model(szSpriteFile);
	}
	
	if(Error)
		set_fail_state("Brakuje plikow sprite, zaladowanie pluginu niemozliwe! Sprawdz logi w pliku rank_system.txt!");

	precache_sound("misc/csr/maytheforce.wav");
	precache_sound("misc/csr/oneandonly.wav");
	precache_sound("misc/csr/prepare.wav");
	precache_sound("misc/csr/humiliation.wav");
	precache_sound("misc/csr/lastleft.wav");
}

public SqlInit()
{
	new szHost[32], szUser[32], szPass[32], szDatabase[32], szTemp[512];
	
	get_cvar_string("rank_system_host", szHost, charsmax(szHost));
	get_cvar_string("rank_system_user", szUser, charsmax(szUser));
	get_cvar_string("rank_system_pass", szPass, charsmax(szPass));
	get_cvar_string("rank_system_database", szDatabase, charsmax(szDatabase));
	get_cvar_string("rank_system_table", szTable, charsmax(szTable));
	
	g_SqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
	
	new Error, szError[128];
	new Handle:g_Connect = SQL_Connect(g_SqlTuple, Error, szError, 127);
	
	if(Error)
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "Error: %s", szError);
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `%s` (`name` varchar(32) NOT NULL, `kills` int(10) NOT NULL, `rank` int(10) NOT NULL, `time` int(10) NOT NULL, ", szTable);
	add(szTemp, charsmax(szTemp), "`firstvisit` int(10) NOT NULL, `lastvisit` int(10) NOT NULL, `gold` int(10) NOT NULL, `silver` int(10) NOT NULL, `bronze` int(10) NOT NULL, ");
	add(szTemp, charsmax(szTemp), "`medals` int(10) NOT NULL, `bestkills` int(10) NOT NULL, `bestdeaths` int(10) NOT NULL, `besths` int(10) NOT NULL, `beststats` int(10) NOT NULL, PRIMARY KEY (`name`));");
	
	new Handle:Query = SQL_PrepareQuery(g_Connect, szTemp);
	
	SQL_Execute(Query);
	
	g_SqlLoaded = true;
	
	SQL_FreeHandle(Query);
	SQL_FreeHandle(g_Connect);
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;
		
	get_user_name(id, g_Player[id][Name], 63);
	replace_all(g_Player[id][Name], 63, "'", "\'");
	replace_all(g_Player[id][Name], 63, "`", "\`");
	
	g_Loaded[id] = false;
	g_Visit[id] = false;
	
	g_Player[id][Kills] = 0;
	g_Player[id][Rank] = 0;
	g_Player[id][Time] = 0;
	g_Player[id][FirstVisit] = 0;
	g_Player[id][LastVisit] = 0;
	g_Player[id][Bronze] = 0;
	g_Player[id][Silver] = 0;
	g_Player[id][Gold] = 0;
	g_Player[id][Medals] = 0;
	g_Player[id][CurrentKills] = 0;
	g_Player[id][CurrentDeaths] = 0;
	g_Player[id][CurrentHS] = 0;
	g_Player[id][CurrentKills] = 0;
	g_Player[id][CurrentDeaths] = 0;
	g_Player[id][CurrentHS] = 0;
	g_Player[id][BestStats] = 0;

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
	
	LoadStats(id);
}
	
public client_disconnected(id)
{
	SaveStats(id, 1);
		
	remove_task(id + TASK_HUD);
	remove_task(id + TASK_TIME);

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
}

public LoadStats(id)
{
	if(!is_user_connected(id) || !g_SqlLoaded)
		return;

	new Data[1], szTemp[128];
	Data[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `%s` WHERE name = ^"%s^";", szTable, g_Player[id][Name]);
	SQL_ThreadQuery(g_SqlTuple, "LoadStatsHandle", szTemp, Data, 1);
}

public LoadStatsHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
		
	new id = Data[0];
	
	if(SQL_NumRows(Query))
	{
		g_Player[id][Kills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "kills"));
		g_Player[id][Rank] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "rank"));
		g_Player[id][Time] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "time"));
		g_Player[id][FirstVisit] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "firstvisit"));
		g_Player[id][LastVisit] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lastvisit"));
		g_Player[id][Bronze] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bronze"));
		g_Player[id][Silver] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "silver"));
		g_Player[id][Gold] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "gold"));
		g_Player[id][Medals] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "medals"));
		g_Player[id][BestStats] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "beststats"));
		g_Player[id][BestKills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bestkills"));
		g_Player[id][BestHS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "besths"));
		g_Player[id][BestDeaths] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bestdeaths"));
	}
	else
	{
		new szTemp[256], iVisit = get_systime();
		formatex(szTemp, charsmax(szTemp), "INSERT IGNORE INTO `%s` (`name`, `firstvisit`) VALUES ('%s', '%i');", szTable, g_Player[id][Name], iVisit);
		SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
	}
	
	if(!task_exists(id + TASK_HUD))
		set_task(1.0, "DisplayHUD", id + TASK_HUD, .flags="b");

	g_Loaded[id] = true;
	
	return PLUGIN_HANDLED;
}

public SaveStats(id, type)
{
	if(!g_Loaded[id])
		return;
		
	new time = g_Player[id][Time] + get_user_time(id);
	
	new Data[1], szTemp[512], szTemp2[128];
	Data[0] = id;
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
	{			
		formatex(szTemp2, charsmax(szTemp2), ", `bestkills` = %d, `besths` = %d, `bestdeaths` = %d, `beststats` = %d", 
		g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths], g_Player[id][CurrentStats]);
	}
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `%s` SET `kills` = %i, `rank` = %i, `time` = %i, `lastvisit` = %i%s WHERE name = ^"%s^" AND `time` <= %i", 
	szTable, g_Player[id][Kills], g_Player[id][Rank], time, get_systime(), szTemp2, g_Player[id][Name], time);
	
	switch(type)
	{
		case 0, 1: SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp, Data, 1);
		case 2:
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(g_SqlTuple, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file("addons/amxmodx/logs/rank_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szTemp);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file("addons/amxmodx/logs/rank_system.txt", "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
				SQL_FreeHandle(Query);
				SQL_FreeHandle(SqlConnection);
				return;
			}
	
			SQL_FreeHandle(Query);
			SQL_FreeHandle(SqlConnection);
		}
	}

	if(type) g_Loaded[id] = false;
}

public IgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		log_to_file("addons/amxmodx/logs/rank_system.txt", "Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED)
		log_to_file("addons/amxmodx/logs/rank_system.txt", "Query failed. [%d] %s", ErrCode, Error);
}

public CheckRank(id)
{	
	for (new rank = 0; rank < MAX_RANKS; rank++) 
	{
		if (g_Player[id][Kills] >= g_RankKills[rank])
			g_Player[id][Rank] = rank;
		else 
			break;
	}
}

public DisplayHUD(id) 
{
	id -= TASK_HUD;

	if(is_user_bot(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;

	if(!is_user_alive(id)) 
	{
		new target = pev(id, pev_iuser2);
		
		if(!target || !g_Loaded[target])
			return PLUGIN_CONTINUE;
			
		new iSeconds = (g_Player[target][Time] + get_user_time(target)), iMinutes, iHours;
	
		while(iSeconds >= 60)
		{
			iSeconds -= 60;
			iMinutes++;
		}
		while(iMinutes >= 60)
		{
			iMinutes -= 60;
			iHours++;
		}
		
		set_hudmessage(255, 255, 255, -1.0, 0.7, 0, 0.0, 1.2, 0.0, 0.0, 3);
		
		if(g_Player[target][Rank] == MAX_RANKS - 1)
			ShowSyncHudMsg(id, g_HUD, "[Ranga: %s]^n[Zabicia: %d]^n[Czas Gry: %i h %i min %i s]", g_RankName[g_Player[target][Rank]], g_Player[target][Kills], iHours, iMinutes, iSeconds);
		else
			ShowSyncHudMsg(id, g_HUD, "[Ranga: %s]^n[Zabicia: %d / %d]^n[Czas Gry: %i h %i min %i s]", g_RankName[g_Player[target][Rank]], g_Player[target][Kills], g_RankKills[g_Player[target][Rank] + 1], iHours, iMinutes, iSeconds);
			
		return PLUGIN_CONTINUE;
	}
	
	if(!g_Loaded[id])
		return PLUGIN_CONTINUE;
	
	new iSeconds = (g_Player[id][Time] + get_user_time(id)), iMinutes, iHours;
	
	while(iSeconds >= 60)
	{
		iSeconds -= 60;
		iMinutes++;
	}
	while(iMinutes >= 60)
	{
		iMinutes -= 60;
		iHours++;
	}
		
	set_hudmessage(0, 255, 0, -1.0, 0.8, 0, 0.0, 1.2, 0.0, 0.0, 3);
		
	if(g_Player[id][Rank] == MAX_RANKS - 1)
		ShowSyncHudMsg(id, g_HUD, "[ Ranga: %s ]^n[ Zabicia: %d ]^n[ Czas Gry: %i h %i min %i s ]", g_RankName[g_Player[id][Rank]], g_Player[id][Kills], iHours, iMinutes, iSeconds);
	else
		ShowSyncHudMsg(id, g_HUD, "[ Ranga: %s ]^n[ Zabicia: %d / %d ]^n[ Czas Gry: %i h %i min %i s ]", g_RankName[g_Player[id][Rank]], g_Player[id][Kills], g_RankKills[g_Player[id][Rank] + 1], iHours, iMinutes, iSeconds);
	
	return PLUGIN_CONTINUE;
}

public Spawn(id)
{
	if(!is_user_alive(id))
		return;
		
	if(!task_exists(id + TASK_HUD))
		set_task(1.0, "DisplayHUD", id + TASK_HUD, .flags="b");

	if(!g_Visit[id])
		set_task(3.0, "CheckTime", id + TASK_TIME);

	SaveStats(id, 0);
}

public FirstRound()
	block = false;

public RoundRestart()
	round = 0;

public NewRound()
{
	oneAndOnly = false;

	if(!round)
	{
		set_task(30.0, "FirstRound");

		block = true;
	}

	round++;

	new bestId, bestFrags, tempFrags, bestDeaths, tempDeaths;

	for(new id = 1; id <= MAX_PLAYERS; id++) 
	{
		if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) continue;

		tempFrags = get_user_frags(id);
		tempDeaths = get_user_deaths(id);

		if(tempFrags > 0 && tempFrags > bestFrags)
		{
			bestFrags = tempFrags;
			bestDeaths = tempDeaths;
			bestId = id;
		}
	}

	if(is_user_connected(bestId)) 
	{
		new bestName[64];

		get_user_name(bestId, bestName, charsmax(bestName));

		client_print_color(0, bestId, "** ^x03 %s^x01 prowadzi w grze z^x04 %i^x01 fragami i^x04 %i^x01 zgonami. **", bestName, bestFrags, bestDeaths);
	}
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if(!is_user_connected(victim) || !is_user_connected(killer) || killer == victim) return;

	g_Player[victim][CurrentDeaths]++;

	g_Player[killer][CurrentKills]++;
	g_Player[killer][Kills]++;
		
	if(hitplace == HIT_HEAD)
		g_Player[killer][CurrentHS]++;

	new szName[64];
	get_user_name(killer, szName, charsmax(szName));

	client_print_color(victim, killer, "** Zostales zabity przez^x03 %s^x01, ktoremu zostalo^x04 %i^x01 HP. **", szName, get_user_health(killer));

	if(wpnindex == CSW_KNIFE)
	{
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!is_user_connected(i)) continue;

			if((pev(i, pev_iuser2) == victim || i == victim) && get_bit(i, soundHumiliation)) client_cmd(i, "spk misc/csr/humiliation");
		}
	}

	if(block) return;

	new tCount, ctCount, lastT, lastCT;

	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_alive(i)) continue;

		switch(get_user_team(i))
		{
			case 1: 
			{
				tCount++;
				lastT = i;
			}
			case 2: 
			{
				ctCount++;
				lastCT = i;
			}
		}
	}
	
	if(tCount == 1 && ctCount == 1)
	{
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!is_user_connected(i)) continue;

			if((pev(i, pev_iuser2) == lastT || pev(i, pev_iuser2) == lastCT || i == lastT || i == lastCT) && get_bit(i, soundMayTheForce)) client_cmd(i, "spk misc/csr/maytheforce");
		}

		new nameT[32], nameCT[32];

		get_user_name(lastT, nameT, charsmax(nameT));
		get_user_name(lastCT, nameCT, charsmax(nameCT));

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%s vs. %s", nameT, nameCT);
	}
	if(tCount == 1 && ctCount > 1 && !oneAndOnly)
	{
		oneAndOnly = true;

		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!is_user_connected(i)) continue;

			if(((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 2)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/csr/lastleft");

			if((pev(i, pev_iuser2) == lastT || i == lastT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/csr/oneandonly");
		}

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%i vs %i", tCount, ctCount);
	}
	if(tCount > 1 && ctCount == 1 && !oneAndOnly)
	{
		oneAndOnly = true;

		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!is_user_connected(i)) continue;
			
			if(((is_user_alive(i) && get_user_team(i) == 1) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 1)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/csr/lastleft");

			if((pev(i, pev_iuser2) == lastCT || i == lastCT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/csr/oneandonly");
		}

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%i vs %i", ctCount, tCount);
	}
}

public bomb_planted(planter)
{
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i)) continue;

		if(((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 2)) && get_bit(i, soundPrepare)) client_cmd(i, "spk misc/csr/prepare");
	}
}

public bomb_explode(planter, defuser) 
{
	g_Player[planter][Kills] += 3;
	CheckRank(planter);
}

public bomb_defused(defuser)
{
	g_Player[defuser][Kills] += 3;
	CheckRank(defuser);
}

public hostages_rescued()
{
	new rescuer = get_loguser_index();
	
	g_Player[rescuer][Kills] += 3;
	CheckRank(rescuer);
}

public CheckTime(id)
{
	id -= TASK_TIME;
	
	if(g_Visit[id])
		return;
	
	if(!g_Loaded[id])
	{ 
		set_task(3.0, "CheckTime", id + TASK_TIME);
		return;
	}
	
	g_Visit[id] = true;
	
	new iTime = get_systime(), iYear, Year, iMonth, Month, iDay, Day, iHour, iMinute, iSecond;
	
	UnixToTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
	
	client_print_color(id, id, "^x03[RANK]^x01 Aktualnie jest godzina^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	
	if(g_Player[id][FirstVisit] == g_Player[id][LastVisit])
		client_print_color(id, id, "^x03[RANK]^x01 To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!" );
	else 
	{
		UnixToTime(g_Player[id][LastVisit], Year, Month, Day, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		if(iYear == Year && iMonth == Month && iDay == Day)
			client_print_color(id, id, "^x03[RANK]^x01 Twoja ostatnia wizyta miala miejsce^x04 dzisiaj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else if(iYear == Year && iMonth == Month && (iDay - 1) == Day)
			client_print_color(id, id, "^x03[RANK]^x01 Twoja ostatnia wizyta miala miejsce^x04 wczoraj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else
			client_print_color(id, id, "^x03[RANK]^x01 Twoja ostatnia wizyta:^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, Year);
	}
}

public CmdRanks(id)
	show_motd(id, "ranks.txt", "Lista Dostepnych Rang");

public CmdRank(id)
{
	if(g_Player[id][Rank] == MAX_RANKS - 1)
		client_print_color(id, id, "^x03[RANK]^x01 Twoja aktualna ranga to:^x04 %s^x01.", g_RankName[g_Player[id][Rank]]);
	else
	{
		client_print_color(id, id, "^x03[RANK]^x01 Twoja aktualna ranga to:^x04 %s^x01. ", g_RankName[g_Player[id][Rank]]);
		client_print_color(id, id, "^x03[RANK]^x01 Do kolejnej rangi potrzebujesz^x04 %i^x01 zabic.", g_RankKills[g_Player[id][Rank] + 1] - g_Player[id][Kills]);
	}
}

public CmdTopRank(id)
{
	new szTemp[256], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, kills, rank FROM `%s` ORDER BY kills DESC LIMIT 15", szTable);
	SQL_ThreadQuery(g_SqlTuple, "ShowTopRank", szTemp, Data, 1);
}

public ShowTopRank(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iLen = 0, iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %13s %4s^n", "#", "Nick", "Ranga", "Zabojstwa");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iKills, iRank;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iKills = SQL_ReadResult(Query, 1);
		iRank = SQL_ReadResult(Query, 2);
		
		if(iPlace >= 10)
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %1s %12i^n", iPlace, szName, g_RankName[iRank], iKills);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %2s %12i^n", iPlace, szName, g_RankName[iRank], iKills);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Top15 Rang");
	
	return PLUGIN_HANDLED;
}

public CmdTime(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `%s`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `%s` WHERE `time` > '%i' ORDER BY `time` DESC) b", szTable, szTable, g_Player[id][Time] + get_user_time(id));
	SQL_ThreadQuery(g_SqlTuple, "ShowTime", szTemp, Data, 1);
}

public ShowTime(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0) + 1;
	new iPlayers = SQL_ReadResult(Query, 1);
	new iSeconds = (g_Player[id][Time] + get_user_time(id)), iMinutes, iHours;
	
	while(iSeconds >= 60)
	{
		iSeconds -= 60;
		iMinutes++;
	}
	while(iMinutes >= 60)
	{
		iMinutes -= 60;
		iHours++;
	}
	
	client_print_color(id, id, "^x03[RANK]^x01 Spedziles na serwerze lacznie^x04 %i h %i min %i s^x01.", iHours, iMinutes, iSeconds);
	client_print_color(id, id, "^x03[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu czasu gry.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTimeTop(id)
{
	new szTemp[256], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, time FROM `%s` ORDER BY time DESC LIMIT 15", szTable);
	SQL_ThreadQuery(g_SqlTuple, "ShowTimeTop", szTemp, Data, 1);
}

public ShowTimeTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iLen, iPlace;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %9s^n", "#", "Nick", "Czas Gry");

	iPlace = 0;
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iSeconds, iMinutes, iHours;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iSeconds = SQL_ReadResult(Query, 1);
		iMinutes = 0;
		iHours = 0;
		
		while(iSeconds >= 60)
		{
			iSeconds -= 60;
			iMinutes++;
		}
		while(iMinutes >= 60)
		{
			iMinutes -= 60;
			iHours++;
		}
		
		if(iPlace >= 10)
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %0ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %1ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Top15 Czasu Gry");
	
	return PLUGIN_HANDLED;
}

public CmdMedals(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `%s`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `%s` WHERE `medals` > '%i' ORDER BY `medals` DESC) b", szTable, szTable, g_Player[id][Medals]);
	SQL_ThreadQuery(g_SqlTuple, "ShowMedals", szTemp, Data, 1);
}

public ShowMedals(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0) + 1;
	new iPlayers = SQL_ReadResult(Query, 1);
	
	client_print_color(id, id, "^x03[RANK]^x01 Twoje medale:^x04 %i Zlote^x01,^x04 %i Srebre^x01,^x04 %i Brazowe^x01.", g_Player[id][Gold], g_Player[id][Silver], g_Player[id][Bronze]);
	client_print_color(id, id, "^x03[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu medalowym.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopMedals(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, gold, silver, bronze, medals FROM `%s` ORDER BY medals DESC LIMIT 15", szTable);
	SQL_ThreadQuery(g_SqlTuple, "ShowMedalsTop", szTemp, Data, 1);
}

public ShowMedalsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iLen, iPlace;

	iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %6s %8s %8s %5s^n", "#", "Nick", "Zlote", "Srebrne", "Brazowe", "Suma");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iGold, iSilver, iBronze, iMedals;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iGold = SQL_ReadResult(Query, 1);
		iSilver = SQL_ReadResult(Query, 2);
		iBronze = SQL_ReadResult(Query, 3);
		iMedals = SQL_ReadResult(Query, 4);
		
		if(iPlace >= 10)
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %2d %7d %8d %7d^n", iPlace, szName, iGold, iSilver, iBronze, iMedals);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %3d %7d %8d %7d^n", iPlace, szName, iGold, iSilver, iBronze, iMedals);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Top15 Medali");
	
	return PLUGIN_HANDLED;
}

public CmdStats(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b", 
	g_Player[id][CurrentStats] > g_Player[id][BestStats] ? g_Player[id][CurrentStats] : g_Player[id][BestStats]);
	
	SQL_ThreadQuery(g_SqlTuple, "ShowStats", szTemp, Data, 1);
}

public ShowStats(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0);
	new iPlayers = SQL_ReadResult(Query, 1);
	
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
		client_print_color(id, id, "^x03[RANK]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths]);
	else
		client_print_color(id, id, "^x03[RANK]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][BestKills], g_Player[id][BestHS], g_Player[id][BestDeaths]);
		
	client_print_color(id, id, "^x03[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu najlepszych statystyk.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopStats(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, bestkills, besths, bestdeaths FROM `%s` ORDER BY beststats DESC LIMIT 15", szTable);
	SQL_ThreadQuery(g_SqlTuple, "ShowStatsTop", szTemp, Data, 1);
}

public ShowStatsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iLen, iPlace;

	iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %19s %4s^n", "#", "Nick", "Zabojstwa", "Zgony");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iKills, iHS, iDeaths;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iKills = SQL_ReadResult(Query, 1);
		iHS = SQL_ReadResult(Query, 2);
		iDeaths = SQL_ReadResult(Query, 3);
		
		if(iPlace >= 10)
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %1d (%i HS) %12d^n", iPlace, szName, iKills, iHS, iDeaths);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %2d (%i HS) %12d^n", iPlace, szName, iKills, iHS, iDeaths);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Top15 Statystyk");
	
	return PLUGIN_HANDLED;
}

public SetTeam(id)
	g_Friend[id] = read_data(2);

public HideStatus(id)
{
	if(get_xvar_num(g_PlayerName))
		return;

	ClearSyncHud(id, g_AimHUD);
}

public ShowStatus(id)
{
	new szName[32], iColor[2], Float:iHeight;
	new StatsHUDMessage = get_xvar_num(g_PlayerName);
	new flags = read_flags("abcd");
	new target = read_data(2);
	new iRank = g_Player[target][Rank];

	get_user_name(target, szName, 31);

	if(get_user_team(target) == 1)
		iColor[0] = 255;
	else
		iColor[1] = 255;

	if(flags & ABOVEHEAD)
		iHeight = 0.35;
	else
		iHeight = 0.60;

	if(g_Friend[id] == 1)
	{
		if(flags && !StatsHUDMessage)
		{
			new szWeaponName[32], iWeaponID = get_user_weapon(target);

			if(iWeaponID)
				xmod_get_wpnname(iWeaponID, szWeaponName, 31);

			set_hudmessage(iColor[0], 50, iColor[1], -1.0, iHeight, 1, 0.01, 3.0, 0.01, 0.01);

			if(flags & TEAMRANK)
			{
				if(flags & STATS)
					ShowSyncHudMsg(id, g_AimHUD, "%s : %s^n%d HP | %d AP | %s", szName, g_RankName[iRank], get_user_health(target), get_user_armor(target), szWeaponName);
				else
					ShowSyncHudMsg(id, g_AimHUD, "%s : %s", szName, g_RankName[iRank]);
			}
			else
			{
				if(flags & STATS)
					ShowSyncHudMsg(id, g_AimHUD, "%s^n%d HP | %d AP | %s", szName, get_user_health(target), get_user_armor(target), szWeaponName);
				else
					ShowSyncHudMsg(id, g_AimHUD, "%s", szName);
			}
		}

		Create_TE_PLAYERATTACHMENT(id, target, 55, g_Sprite[iRank], 15);
	}
	else if(flags && !StatsHUDMessage)
	{
		set_hudmessage(iColor[0], 50, iColor[1], -1.0, iHeight, 1, 0.01, 3.0, 0.01, 0.01);

		if(flags & ENEMYRANK)
			ShowSyncHudMsg(id, g_AimHUD, "%s : %s", szName, g_RankName[iRank]);
		else
			ShowSyncHudMsg(id, g_AimHUD, "%s", szName);
	}
}

public MsgIntermission() 
{
	new szTemp[256], szName[32], szPlayers[32], szBestID[3], szBestFrags[3], id, iNum, iTempFrags, iSwapFrags, iSwapID;
	get_players(szPlayers, iNum, "h");
	
	if(iNum < 1)
		return PLUGIN_CONTINUE;
		
	for (new i = 0; i < iNum; i++)
	{
		id = szPlayers[i];
		
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id))
			continue;
		
		SaveStats(id, 2);
		
		iTempFrags = get_user_frags(id);
		
		if(iTempFrags > szBestFrags[0])
		{
			szBestFrags[0] = iTempFrags;
			szBestID[0] = id;
			if(iTempFrags > szBestFrags[1])
			{
				iSwapFrags = szBestFrags[1];
				iSwapID = szBestID[1];
				szBestFrags[1] = iTempFrags;
				szBestID[1] = id;
				szBestFrags[0] = iSwapFrags;
				szBestID[0] = iSwapID;
				
				if(iTempFrags > szBestFrags[2])
				{
					iSwapFrags = szBestFrags[2];
					iSwapID = szBestID[2];
					szBestFrags[2] = iTempFrags;
					szBestID[2] = id;
					szBestFrags[1] = iSwapFrags;
					szBestID[1] = iSwapID;
				}
			}
		}
	}
	
	if(!szBestID[2])
		return PLUGIN_CONTINUE;
	
	new const szType[][] = { "Brazowy", "Srebrny", "Zloty" };
	
	client_print_color(0, szBestID[2], "^x03[RANK]^x01 Gratulacje dla^x04 Zwyciezcow^x01!");
	
	for(new i = 2; i >= 0; i--)
	{
		switch(i)
		{
			case 0: g_Player[szBestID[i]][Bronze]++;
			case 1: g_Player[szBestID[i]][Silver]++;
			case 2: g_Player[szBestID[i]][Gold]++;
		}
		
		get_user_name(szBestID[i], szName, 31);
		client_print_color(0, szBestID[2], "^x03[RANK]^x04 %s^x01 - %s Medal -^x04 %i^x01 Zabojstw.", szName, szType[i], szBestFrags[i]);
		
		new iMedals = g_Player[szBestID[i]][Gold]*3 + g_Player[szBestID[i]][Silver]*2 + g_Player[szBestID[i]][Bronze];
		formatex(szTemp, charsmax(szTemp), "UPDATE `%s` SET `gold` = %d, `silver` = %d, `bronze` = %d, `medals` = %d WHERE name = ^"%s^" AND `medals` <= %i", 
		szTable, g_Player[szBestID[i]][Gold], g_Player[szBestID[i]][Silver], g_Player[szBestID[i]][Bronze], iMedals, g_Player[szBestID[i]][Name], iMedals);
		SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
	}
	
	return PLUGIN_CONTINUE;
}

public SaveSounds(id)
{
	new vaultKey[64], vaultData[16];
	
	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", g_Player[id][Name]);
	formatex(vaultData, charsmax(vaultData), "%d %d %d %d %d", get_bit(id, soundMayTheForce), get_bit(id, soundOneAndOnly), get_bit(id, soundHumiliation), get_bit(id, soundPrepare), get_bit(id, soundLastLeft));
	
	nvault_set(sounds, vaultKey, vaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadSounds(id)
{
	new vaultKey[64], vaultData[16], soundsData[5][5];
	
	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", g_Player[id][Name]);
	
	if(nvault_get(sounds, vaultKey, vaultData, charsmax(vaultData)))
	{
		parse(vaultData, soundsData[0], charsmax(soundsData), soundsData[1], charsmax(soundsData), soundsData[2], charsmax(soundsData), soundsData[3], charsmax(soundsData), soundsData[4], charsmax(soundsData));

		if(str_to_num(soundsData[0])) set_bit(id, soundMayTheForce);
		if(str_to_num(soundsData[1])) set_bit(id, soundOneAndOnly);
		if(str_to_num(soundsData[2])) set_bit(id, soundHumiliation);
		if(str_to_num(soundsData[3])) set_bit(id, soundPrepare);
		if(str_to_num(soundsData[4])) set_bit(id, soundLastLeft);
	}

	return PLUGIN_CONTINUE;
} 

public CmdSound(id)
{
	new menuData[64], menu = menu_create("\yUstawienia \rDzwiekow\w:", "CmdSound_Handle");

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

public CmdSound_Handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	
	switch(item)
	{
		case 0: get_bit(id, soundMayTheForce) ? rem_bit(id, soundMayTheForce) : set_bit(id, soundMayTheForce);
		case 1: get_bit(id, soundOneAndOnly) ? rem_bit(id, soundOneAndOnly) : set_bit(id, soundOneAndOnly);
		case 2: get_bit(id, soundHumiliation) ? rem_bit(id, soundHumiliation) : set_bit(id, soundHumiliation);
		case 3: get_bit(id, soundLastLeft) ? rem_bit(id, soundLastLeft) : set_bit(id, soundLastLeft);
		case 4: get_bit(id, soundPrepare) ? rem_bit(id, soundPrepare) : set_bit(id, soundPrepare);
	}
	
	SaveSounds(id);

	CmdSound(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public native_stats_add_kill(plugin_id, num_params)
{
	if(num_params != 1)
        return PLUGIN_CONTINUE;
		
	new id = get_param(1);
	
	if(!is_user_connected(id))
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "Native: Invalid Player (%d)", id);
		return PLUGIN_CONTINUE;
	}
	
	g_Player[id][CurrentKills]++;
	g_Player[id][Kills]++;
	
	return PLUGIN_CONTINUE;
}

public native_stats_get_kills(plugin_id, num_params)
{
	if(num_params != 1)
        return PLUGIN_CONTINUE;
		
	new id = get_param(1);
	
	if(!is_user_connected(id))
	{
		log_to_file("addons/amxmodx/logs/rank_system.txt", "Native: Invalid Player (%d)", id);
		return PLUGIN_CONTINUE;
	}
	
	return g_Player[id][Kills];
}

stock get_loguser_index()
{
	new szLogUser[80], szName[32];
	read_logargv(0, szLogUser, 79);
	parse_loguser(szLogUser, szName, 31);

	return get_user_index(szName);
}

stock Create_TE_PLAYERATTACHMENT(id, entity, vOffset, iSprite, life)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);
	write_coord(vOffset);
	write_short(iSprite);
	write_short(life);
	message_end();
}