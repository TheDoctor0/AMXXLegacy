#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat>
#include <unixtime>

#define PLUGIN "Advanced Rank System"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define MAX_PLAYERS 32

#define TASK_TIME 6701

enum Stats
{
	Name[64],
	Kills,
	HS,
	Deaths,
	Shots,
	Hits,
	HitsHS,
	HitsChest,
	HitsStomach,
	HitsLeftArm,
	HitsRightArm,
	HitsLeftLeg,
	HitsRightLeg,
	RoundHits,
	Damage,
	RoundDamage,
	RoundVictims[MAX_PLAYERS],
	Accuracy,
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
	CurrentHS
};

new sBuffer[2048], sBuffer2[2048], sBuffer3[2048], sBuffer4[2048], gTime, gTime2, gTime3, gTime4;
new g_Player[MAX_PLAYERS+1][Stats], g_Loaded[MAX_PLAYERS+1], g_Visit[MAX_PLAYERS+1], szTable[32], g_SqlLoaded, Handle:g_SqlTuple;
const m_LastHitGroup = 75;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("rank_system_host", "sql.pukawka.pl", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_user", "298272", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_pass", "fNhrZmHuOortS7C2", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_database", "298272_rank", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("rank_system_table", "rank_system", FCVAR_SPONLY | FCVAR_PROTECTED);

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
	register_clcmd("sayteam /topstaty", "CmdTopStats")

	RegisterHam(Ham_Spawn , "player", "Spawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	
	register_message(SVC_INTERMISSION, "MsgIntermission");
	
	register_event("DeathMsg", "DeathMsg", "a");
	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("CurWeapon", "EventShot", "be", "1=1", "3>0", "2!4", "2!6", "2!9", "2!25", "2!29")
}

public plugin_cfg()
	SqlInit();
	
public plugin_end()
	SQL_FreeHandle(g_SqlTuple);
	
public plugin_natives ()
	register_native("stats_add_kill", "native_stats_add_kill", 1);

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
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Error: %s", szError);
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `%s` (`name` varchar(32) NOT NULL, `kills` int(10) NOT NULL, `time` int(10) NOT NULL, ", szTable);
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
	
	LoadStats(id);
}
	
public client_disconnect(id)
{
	SaveStats(id, 0);

	remove_task(id + TASK_TIME);
}

public Spawn(id)
{
	if(!is_user_alive(id))
		return;

	if(!g_Visit[id])
		set_task(3.0, "CheckTime", id + TASK_TIME);
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	if(!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return HAM_IGNORED;
		
	new iHitgroup = get_pdata_int(iVictim, m_LastHitGroup);
	
	switch(iHitgroup)
	{
		case HIT_HEAD: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsHS]++;
		}
		case HIT_CHEST: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsChest]++;
		}
		case HIT_STOMACH: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsStomach]++;
		}
		case HIT_LEFTARM: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsLeftArm]++;
		}
		case HIT_RIGHTARM: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsRightArm]++;
		}
		case HIT_LEFTLEG: 
		{
			g_Player[iAttacker][Hits]++;
			g_Player[iAttacker][HitsLeftLeg]++;
		}
		case HIT_RIGHTLEG: 
		{
			g_Player[iAttacker][Hits]++; 
			g_Player[iAttacker][HitsRightLeg]++;
		}
	}
	
	g_Player[iAttacker][RoundVictims][iVictim] += fDamage;
	g_Player[iAttacker][RoundDamage] += fDamage;
	g_Player[iAttacker][Damage] += fDamage;
	
	return HAM_IGNORED;
}  

public DeathMsg()
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	new iHeadShot = read_data(3);
	
	if(is_user_connected(iVictim))
	{
		g_Player[iVictim][CurrentDeaths]++;
		g_Player[iVictim][Deaths]++;
	}

	if(is_user_connected(iKiller) && iKiller != iVictim)
	{
		g_Player[iKiller][CurrentKills]++;
		g_Player[iKiller][Kills]++;
		
		if(iHeadShot)
		{
			g_Player[iKiller][CurrentHS]++;
			g_Player[iKiller][HS]++;
		}
	}
}

public EventShot(id)
	g_Player[id][Shots]++;

public bomb_explode(planter, defuser) 
	g_Player[planter][Kills] += 3;

public bomb_defused(defuser)
	g_Player[defuser][Kills] += 3;

public hostages_rescued()
{
	new rescuer = get_loguser_index();
	
	g_Player[rescuer][Kills] += 3;
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
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
		
	new id = Data[0];
	
	if(SQL_NumRows(Query))
	{
		g_Player[id][Kills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "kills"));
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

	g_Loaded[id] = true;
	
	return PLUGIN_HANDLED;
}

public SaveStats(id, type)
{
	if(!g_Loaded[id])
		return;
		
	g_Player[id][Time] += get_user_time(id);
		
	new Data[1], szTemp[512], szTemp[128];
	Data[0] = id;
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
	{			
		formatex(szTemp2, charsmax(szTemp2), ", `bestkills` = %d, `besths` = %d, `bestdeaths` = %d, `beststats` = %d", 
		g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths], g_Player[id][CurrentStats]);
	}
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `%s` SET `kills` = %i, `time` = %i, `lastvisit` = %i%s WHERE name = ^"%s^" AND `time` <= %i", 
	szTable, g_Player[id][Kills], g_Player[id][Time], get_systime(), szTemp2, g_Player[id][Name], g_Player[id][Time]);
	
	switch(type)
	{
		case 0: SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp, Data, 1);
		case 1:
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(g_SqlTuple, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szTemp);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
				SQL_FreeHandle(Query);
				SQL_FreeHandle(SqlConnection);
				return;
			}
	
			SQL_FreeHandle(Query);
			SQL_FreeHandle(SqlConnection);
		}
	}

	g_Loaded[id] = false;
}

public IgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED)
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Query failed. [%d] %s", ErrCode, Error);
}

public CheckTime(id)
{
	id -= TASK_TIME;
	
	if(!g_Loaded[id])
	{ 
		set_task(3.0, "CheckTime", id + TASK_TIME);
		return;
	}
	
	new iTime = get_systime(), iYear, Year, iMonth, Month, iDay, Day, iHour, iMinute, iSecond;
	
	UnixToTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
	
	ColorChat(id, RED, "[RANK]^x01 Aktualnie jest godzina^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	
	if(g_Player[id][FirstVisit] == g_Player[id][LastVisit])
		ColorChat(id,TEAM_COLOR,"[RANK]^x01 To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!" );
	else 
	{
		UnixToTime(g_Player[id][LastVisit], Year, Month, Day, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		if(iYear == Year && iMonth == Month && iDay == Day)
			ColorChat(id, RED,"[RANK]^x01 Twoja ostatnia wizyta miala miejsce^x04 dzisiaj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else if(iYear == Year && iMonth == Month && (iDay - 1) == Day)
			ColorChat(id, RED,"[RANK]^x01 Twoja ostatnia wizyta miala miejsce^x04 wczoraj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else
			ColorChat(id, RED,"[RANK]^x01 Twoja ostatnia wizyta:^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, Year);
	}
	
	g_Visit[id] = true;
}

public CmdTime(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `%s`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `%s` WHERE `time` > '%i' ORDER BY `time` DESC) b", szTable, szTable, g_Player[id][Time]);
	SQL_ThreadQuery(g_SqlTuple, "ShowTime", szTemp, Data, 1);
}

public ShowTime(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
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
	
	ColorChat(id, RED, "[RANK]^x01 Spedziles na serwerze lacznie^x04 %i h %i min %i s^x01.", iHours, iMinutes, iSeconds);
	ColorChat(id, RED, "[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu czasu gry.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTimeTop(id)
{
	new szTemp[256], Data[1];
	Data[0] = id;
	
	if(!gTime || gTime + 10.0 > get_gametime())
	{
		gTime = floatround(get_gametime());
		format(szTemp, charsmax(szTemp), "SELECT name, time FROM `%s` ORDER BY time DESC LIMIT 15", szTable);
		SQL_ThreadQuery(g_SqlTuple, "ShowTimeTop", szTemp, Data, 1);
	}
	else
		show_motd(id, sBuffer, "Top15 Czasu Gry");
}

public ShowTimeTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %9s^n", "#", "Nick", "Czas Gry");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iSeconds, iMinutes, iHours;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iSeconds = SQL_ReadResult(Query, 1);
		
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
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0) + 1;
	new iPlayers = SQL_ReadResult(Query, 1);
	
	ColorChat(id, RED, "[RANK]^x01 Twoje medale:^x04 %i Zlote^x01,^x04 %i Srebre^x01,^x04 %i Brazowe^x01.", g_Player[id][Gold], g_Player[id][Silver], g_Player[id][Bronze]);
	ColorChat(id, RED, "[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu medalowym.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopMedals(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	if(!gTime2 || gTime2 + 10.0 > get_gametime())
	{
		gTime2 = floatround(get_gametime());
		format(szTemp, charsmax(szTemp), "SELECT name, gold, silver, bronze, medals FROM `%s` ORDER BY medals DESC LIMIT 15", szTable);
		SQL_ThreadQuery(g_SqlTuple, "ShowMedalsTop", szTemp, Data, 1);
	}
	else
		show_motd(id, sBuffer2, "Top15 Medali");
}

public ShowMedalsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(sBuffer2, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer2[iLen], 2047 - iLen, "%1s %-22.22s %6s %8s %8s %5s^n", "#", "Nick", "Zlote", "Srebrne", "Brazowe", "Suma");
	
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
			iLen += format(sBuffer2[iLen], 2047 - iLen, "%1i %-22.22s %2d %7d %8d %7d^n", iPlace, szName, iGold, iSilver, iBronze, iMedals);
		else
			iLen += format(sBuffer2[iLen], 2047 - iLen, "%1i %-22.22s %3d %7d %8d %7d^n", iPlace, szName, iGold, iSilver, iBronze, iMedals);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer2, "Top15 Medali");
	
	return PLUGIN_HANDLED;
}

public CmdStats(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
		formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `%s`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `%s` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b", szTable, szTable, g_Player[id][BestStats]);
	else
		formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `%s`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `%s` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b", szTable, szTable, g_Player[id][CurrentStats]);
	
	SQL_ThreadQuery(g_SqlTuple, "ShowStats", szTemp, Data, 1);
}

public ShowStats(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0);
	new iPlayers = SQL_ReadResult(Query, 1);
	
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
		ColorChat(id, RED, "[RANK]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths]);
	else
		ColorChat(id, RED, "[RANK]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][BestKills], g_Player[id][BestHS], g_Player[id][BestDeaths]);
		
	ColorChat(id, RED, "[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu najlepszych statystyk.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopStats(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	if(!gTime3 || gTime3 + 10.0 > get_gametime())
	{
		gTime3 = floatround(get_gametime());
		format(szTemp, charsmax(szTemp), "SELECT name, bestkills, besths, bestdeaths FROM `%s` ORDER BY beststats DESC LIMIT 15", szTable);
		SQL_ThreadQuery(g_SqlTuple, "ShowStatsTop", szTemp, Data, 1);
	}
	else
		show_motd(id, sBuffer3, "Top15 Statystyk");
}

public ShowStatsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(sBuffer3, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer3[iLen], 2047 - iLen, "%1s %-22.22s %19s %4s^n", "#", "Nick", "Zabojstwa", "Zgony");
	
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
			iLen += format(sBuffer3[iLen], 2047 - iLen, "%1i %-22.22s %1d (%i HS) %12d^n", iPlace, szName, iKills, iHS, iDeaths);
		else
			iLen += format(sBuffer3[iLen], 2047 - iLen, "%1i %-22.22s %2d (%i HS) %12d^n", iPlace, szName, iKills, iHS, iDeaths);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer3, "Top15 Statystyk");
	
	return PLUGIN_HANDLED;
}

public MsgIntermission() 
{
	new szTemp[256], szName[32], szPlayers[32], szBestID[3], szBestFrags[3], iPlayer, iNum, iTempFrags, iSwapFrags, iSwapID;
	get_players(szPlayers, iNum, "h");
	
	if(iNum < 1)
		return PLUGIN_CONTINUE;
	
	for(new i = 0; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		iTempFrags = get_user_frags(iPlayer);
		
		SaveStats(iPlayer, 1);
		
		if(iTempFrags > szBestFrags[0])
		{
			szBestFrags[0] = iTempFrags;
			szBestID[0] = iPlayer;
			if(iTempFrags > szBestFrags[1])
			{
				iSwapFrags = szBestFrags[1];
				iSwapID = szBestID[1];
				szBestFrags[1] = iTempFrags;
				szBestID[1] = iPlayer;
				szBestFrags[0] = iSwapFrags;
				szBestID[0] = iSwapID;
				
				if(iTempFrags > szBestFrags[2])
				{
					iSwapFrags = szBestFrags[2];
					iSwapID = szBestID[2];
					szBestFrags[2] = iTempFrags;
					szBestID[2] = iPlayer;
					szBestFrags[1] = iSwapFrags;
					szBestID[1] = iSwapID;
				}
			}
		}
	}
	
	if(!szBestID[2])
		return PLUGIN_CONTINUE;
	
	new const szType[][] = { "Zloty", "Srebrny", "Brazowy" };
	
	ColorChat(0, RED, "[RANK]^x01 Gratulacje dla^x04 Zwyciezcow^x01!");
	
	for(new i = 0; i < 3; i++) 
	{
		switch(i)
		{
			case 0: g_Player[szBestID[i]][Bronze]++;
			case 1: g_Player[szBestID[i]][Silver]++;
			case 2: g_Player[szBestID[i]][Gold]++;
		}
		
		get_user_name(szBestID[i], szName, 31);
		ColorChat(0, RED, "[RANK]^x04 %s^x01 - %s Medal -^x04 %i^x01 Zabojstw.", szName, szType[i], szBestID[i]);
		
		new iMedals = g_Player[szBestID[i]][Gold]*3 + g_Player[szBestID[i]][Silver]*2 + g_Player[szBestID[i]][Bronze];
		formatex(szTemp, charsmax(szTemp), "UPDATE `%s` SET `gold` = %d, `silver` = %d, `bronze` = %d, `medals` = %d WHERE name = ^"%s^" AND `medals` <= %i", 
		szTable, g_Player[szBestID[i]][Gold], g_Player[szBestID[i]][Silver], g_Player[szBestID[i]][Bronze], iMedals, g_Player[szBestID[i]][Name], iMedals);
		SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
	}
	
	return PLUGIN_CONTINUE;
}

public native_stats_add_kill(plugin_id, num_params)
{
	if(num_params != 1)
        return PLUGIN_CONTINUE;
		
	new id = get_param(1);
	
	if(!is_user_connected(id))
	{
		log_to_file("addons/amxmodx/logs/advanced_rank_system.txt", "Native: Invalid Player (%d)", id);
		return PLUGIN_CONTINUE;
	}
	
	g_Player[id][CurrentKills]++;
	g_Player[id][Kills]++;
	
	return PLUGIN_CONTINUE;
}

stock get_loguser_index()
{
	new szLogUser[80], szName[32];
	read_logargv(0, szLogUser, 79);
	parse_loguser(szLogUser, szName, 31);

	return get_user_index(szName);
}