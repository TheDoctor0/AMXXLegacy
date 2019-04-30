#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat>
#include <unixtime>

#define PLUGIN "Stats System"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_TIME 6701

#define MAX_PLAYERS 32

enum Stats
{
	Name[64],
	Admin,
	Kills,
	Time,
	FirstVisit,
	LastVisit,
	BestStats,
	BestKills,
	BestDeaths,
	BestHS,
	CurrentStats,
	CurrentKills,
	CurrentDeaths,
	CurrentHS,
};

new sBuffer[2048], g_Player[MAX_PLAYERS+1][Stats], g_Loaded[MAX_PLAYERS+1], g_Visit[MAX_PLAYERS+1], g_SqlLoaded, Handle:g_SqlTuple;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("stats_system_host", "sql.pukawka.pl", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_user", "509049", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_pass", "Vd1hRq0EKCe6Mt3", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_database", "509049_stats", FCVAR_SPONLY | FCVAR_PROTECTED);
	
	register_clcmd("say /czas", "CmdTime");
	register_clcmd("sayteam /czas", "CmdTime");
	register_clcmd("say /topczas", "CmdTimeTop")
	register_clcmd("sayteam /topczas", "CmdTimeTop");
	register_clcmd("say /staty", "CmdStats");
	register_clcmd("sayteam /staty", "CmdStats");
	register_clcmd("say /topstaty", "CmdTopStats");
	register_clcmd("sayteam /topstaty", "CmdTopStats");
	register_clcmd("say /czasadmin", "CmdTimeAdmin");
	register_clcmd("sayteam /czasadmin", "CmdTimeAdmin");

	RegisterHam(Ham_Spawn , "player", "Spawn", 1);
	
	register_message(SVC_INTERMISSION, "MsgIntermission");
	
	register_event("DeathMsg", "DeathMsg", "a");
	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
}

public plugin_cfg()
	SqlInit();
	
public plugin_end()
	SQL_FreeHandle(g_SqlTuple);
	
public plugin_natives ()
	register_native("stats_add_kill", "native_stats_add_kill");

public SqlInit()
{
	new szHost[32], szUser[32], szPass[32], szDatabase[32], szTemp[512];
	
	get_cvar_string("stats_system_host", szHost, charsmax(szHost));
	get_cvar_string("stats_system_user", szUser, charsmax(szUser));
	get_cvar_string("stats_system_pass", szPass, charsmax(szPass));
	get_cvar_string("stats_system_database", szDatabase, charsmax(szDatabase));
	
	g_SqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
	
	new Error, szError[128];
	new Handle:g_Connect = SQL_Connect(g_SqlTuple, Error, szError, 127);
	
	if(Error)
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Error: %s", szError);
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `stats_system` (`name` varchar(32) NOT NULL, `admin` int(10) NOT NULL, `kills` int(10) NOT NULL, `time` int(10) NOT NULL, `firstvisit` int(10) NOT NULL, ");
	add(szTemp, charsmax(szTemp), "`lastvisit` int(10) NOT NULL, `bestkills` int(10) NOT NULL, `bestdeaths` int(10) NOT NULL, `besths` int(10) NOT NULL, `beststats` int(10) NOT NULL, PRIMARY KEY (`name`));");
	
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
	g_Player[id][CurrentKills] = 0;
	g_Player[id][CurrentDeaths] = 0;
	g_Player[id][CurrentHS] = 0;
	g_Player[id][CurrentKills] = 0;
	g_Player[id][CurrentDeaths] = 0;
	g_Player[id][CurrentHS] = 0;
	g_Player[id][BestStats] = 0;
	
	LoadStats(id);
}

public client_authorized(id)
{
	if(get_user_flags(id) & ADMIN_BAN)
		g_Player[id][Admin] = 1;
	else
		g_Player[id][Admin] = 0;
}
	
public client_disconnect(id)
{
	SaveStats(id, 0);
	
	remove_task(id + TASK_TIME);
}

public LoadStats(id)
{
	if(!is_user_connected(id) || !g_SqlLoaded)
		return;
		
	new Data[1], szTemp[128];
	Data[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `stats_system` WHERE name = ^"%s^";", g_Player[id][Name]);
	SQL_ThreadQuery(g_SqlTuple, "LoadStatsHandle", szTemp, Data, 1);
}

public LoadStatsHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
		
	new id = Data[0];
	
	if(SQL_NumRows(Query))
	{
		g_Player[id][Kills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "kills"));
		g_Player[id][Time] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "time"));
		g_Player[id][FirstVisit] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "firstvisit"));
		g_Player[id][LastVisit] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lastvisit"));
		g_Player[id][BestStats] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "beststats"));
		g_Player[id][BestKills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bestkills"));
		g_Player[id][BestHS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "besths"));
		g_Player[id][BestDeaths] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bestdeaths"));
	}
	else
	{
		new szTemp[256], iVisit = get_systime();
		formatex(szTemp, charsmax(szTemp), "INSERT IGNORE INTO `stats_system` (`name`, `firstvisit`) VALUES ('%s', '%i');", g_Player[id][Name], iVisit);
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
		
	new Data[1], szTemp[512], szTemp2[128];
	Data[0] = id;
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
	{			
		formatex(szTemp2, charsmax(szTemp2), ", `bestkills` = %d, `besths` = %d, `bestdeaths` = %d, `beststats` = %d", 
		g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths], g_Player[id][CurrentStats]);
	}
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `stats_system` SET `admin` = %i, `kills` = %i, `time` = %i, `lastvisit` = %i%s WHERE name = ^"%s^" AND `time` <= %i", 
	g_Player[id][Admin], g_Player[id][Kills], g_Player[id][Time], get_systime(), szTemp2, g_Player[id][Name], g_Player[id][Time]);
	
	switch(type)
	{
		case 0: SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp, Data, 1);
		case 1:
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(g_SqlTuple, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file("addons/amxmodx/logs/stats_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szTemp);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file("addons/amxmodx/logs/stats_system.txt", "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
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
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED)
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Query failed. [%d] %s", ErrCode, Error);
}

public Spawn(id)
{
	if(!is_user_alive(id))
		return;

	if(!g_Visit[id])
		set_task(3.0, "CheckTime", id + TASK_TIME);
}

public DeathMsg()
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	new iHeadShot = read_data(3);
	
	if(is_user_connected(iVictim))
		g_Player[iVictim][CurrentDeaths]++;

	if(is_user_connected(iKiller) && iKiller != iVictim)
	{
		g_Player[iKiller][CurrentKills]++;
		g_Player[iKiller][Kills]++;
		
		if(iHeadShot)
			g_Player[iKiller][CurrentHS]++;
	}
}

public bomb_explode(planter, defuser) 
	g_Player[planter][Kills] += 3;

public bomb_defused(defuser)
	g_Player[defuser][Kills] += 3;

public hostages_rescued()
{
	new rescuer = get_loguser_index();
	
	g_Player[rescuer][Kills] += 3;
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
	
	ColorChat(id, RED, "[STATY]^x01 Aktualnie jest godzina^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	
	if(g_Player[id][FirstVisit] == g_Player[id][LastVisit])
		ColorChat(id,TEAM_COLOR,"[STATY]^x01 To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!" );
	else 
	{
		UnixToTime(g_Player[id][LastVisit], Year, Month, Day, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		if(iYear == Year && iMonth == Month && iDay == Day)
			ColorChat(id, RED,"[STATY]^x01 Twoja ostatnia wizyta miala miejsce^x04 dzisiaj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else if(iYear == Year && iMonth == Month && (iDay - 1) == Day)
			ColorChat(id, RED,"[STATY]^x01 Twoja ostatnia wizyta miala miejsce^x04 wczoraj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else
			ColorChat(id, RED,"[STATY]^x01 Twoja ostatnia wizyta:^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, Year);
	}
	
	g_Visit[id] = true;
}

public CmdTime(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `time` > '%i' ORDER BY `time` DESC) b", g_Player[id][Time]);
	SQL_ThreadQuery(g_SqlTuple, "ShowTime", szTemp, Data, 1);
}

public ShowTime(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
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
	
	ColorChat(id, RED, "[STATY]^x01 Spedziles na serwerze lacznie^x04 %i h %i min %i s^x01.", iHours, iMinutes, iSeconds);
	ColorChat(id, RED, "[STATY]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu czasu gry.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTimeTop(id)
{
	new szTemp[256], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, time FROM `stats_system` ORDER BY time DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowTimeTop", szTemp, Data, 1);
}

public ShowTimeTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %13s^n", "#", "Nick", "Czas Gry");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iSeconds, iMinutes, iHours;
		iSeconds = 0; iMinutes = 0; iHours = 0;
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
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %1ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %2ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Top15 Czasu Gry");
	
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
		formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b", g_Player[id][BestStats]);
	else
		formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b", g_Player[id][CurrentStats]);
	
	SQL_ThreadQuery(g_SqlTuple, "ShowStats", szTemp, Data, 1);
}

public ShowStats(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0);
	new iPlayers = SQL_ReadResult(Query, 1);
	
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
		ColorChat(id, RED, "[STATY]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths]);
	else
		ColorChat(id, RED, "[STATY]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][BestKills], g_Player[id][BestHS], g_Player[id][BestDeaths]);
		
	ColorChat(id, RED, "[STATY]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu najlepszych statystyk.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopStats(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, bestkills, besths, bestdeaths FROM `stats_system` ORDER BY beststats DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowStatsTop", szTemp, Data, 1);
}

public ShowStatsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
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

public CmdTimeAdmin(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
		return;
		
	new szTemp[256], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, time FROM `stats_system` WHERE admin = '1' ORDER BY time DESC");
	SQL_ThreadQuery(g_SqlTuple, "ShowTimeAdmin", szTemp, Data, 1);
}

public ShowTimeAdmin(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 2047 - iLen, "%1s %-22.22s %13s^n", "#", "Nick", "Czas Gry");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iSeconds, iMinutes, iHours;
		iSeconds = 0; iMinutes = 0; iHours = 0;
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
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %1ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		else
			iLen += format(sBuffer[iLen], 2047 - iLen, "%1i %-22.22s %2ih %1imin %1is^n", iPlace, szName, iHours, iMinutes, iSeconds);
		
		SQL_NextRow(Query);
	}
	
	show_motd(id, sBuffer, "Czas Gry Adminow");
	
	return PLUGIN_HANDLED;
}

public MsgIntermission() 
{
	new szPlayers[32], id, iNum;
	get_players(szPlayers, iNum, "h");
	
	if(iNum < 1)
		return PLUGIN_CONTINUE;
		
	for (new i = 0; i < iNum; i++)
	{
		id = szPlayers[i];
		
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id))
			continue;
		
		SaveStats(id, 1);
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
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Native: Invalid Player (%d)", id);
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