#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <unixtime>
#include <nvault>

#define PLUGIN "Stats System"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_TIME 6701

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

enum Stats
{
	Name[64],
	Admin,
	Kills,
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

new const commandMenu[][] = { "say /statsmenu", "say_team /statsmenu", "say /statymenu", "say_team /statymenu", "say /menustaty", "say_team /menustaty", "menustaty" };
new const commandTime[][] = { "say /time", "say_team /time", "say /czas", "say_team /czas", "czas" };
new const commandAdminTime[][] = { "say /timeadmin", "say_team /timeadmin", "say /tadmin", "say_team /tadmin", "say /czasadmin", "say_team /czasadmin", "say /cadmin", "say_team /cadmin", "say /adminczas", "say_team /adminczas", "czasadmin" };
new const commandTopTime[][] = { "say /ttop15", "say_team /ttop15", "say /toptime", "say_team /toptime", "say /ctop15", "say_team /ctop15", "say /topczas", "say_team /topczas", "topczas" };
new const commandBestStats[][] = { "say /staty", "say_team /staty", "say /beststats", "say_team /beststats", "say /bstats", "say_team /bstats", "say /najlepszestaty", "say_team /najlepszestaty", "say /nstaty", "say_team /nstaty", "najlepszestaty" };
new const commandTopStats[][] = { "say /stop15", "say_team /stop15", "say /topstats", "say_team /topstats", "say /topstaty", "say_team /topstaty", "topstaty" };
new const commandMedals[][] = { "say /medal", "say_team /medal", "say /medale", "say_team /medale", "say /medals", "say_team /medals", "medale" };
new const commandTopMedals[][] = { "say /mtop15", "say_team /mtop15", "say /topmedals", "say_team /topmedals", "say /topmedale", "say_team /topmedale", "topmedale" };
new const commandSound[][] = { "say /dzwiek", "say_team /dzwiek", "say /dzwieki", "say_team /dzwieki", "say /sound", "say_team /sound", "dzwieki" };

new sBuffer[2048], g_Player[MAX_PLAYERS+1][Stats], g_Loaded[MAX_PLAYERS+1], g_Visit[MAX_PLAYERS+1], g_SqlLoaded, Handle:g_SqlTuple, 
	bool:oneAndOnly, bool:block, round, sounds, soundMayTheForce, soundOneAndOnly, soundPrepare, soundHumiliation, soundLastLeft;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("stats_system_host", "sql.pukawka.pl", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_user", "510128", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_pass", "xvQ5CusRVCVzj83aruWk", FCVAR_SPONLY | FCVAR_PROTECTED);
	register_cvar("stats_system_database", "510128_stats", FCVAR_SPONLY | FCVAR_PROTECTED);

	for(new i; i < sizeof commandMenu; i++) register_clcmd(commandMenu[i], "CmdMenu");
	for(new i; i < sizeof commandTime; i++) register_clcmd(commandTime[i], "CmdTime");
	for(new i; i < sizeof commandAdminTime; i++) register_clcmd(commandAdminTime[i], "CmdTimeAdmin");
	for(new i; i < sizeof commandTopTime; i++) register_clcmd(commandTopTime[i], "CmdTopTime");
	for(new i; i < sizeof commandBestStats; i++) register_clcmd(commandBestStats[i], "CmdStats");
	for(new i; i < sizeof commandTopStats; i++) register_clcmd(commandTopStats[i], "CmdTopStats");
	for(new i; i < sizeof commandMedals; i++) register_clcmd(commandMedals[i], "CmdMedals");
	for(new i; i < sizeof commandTopMedals; i++) register_clcmd(commandTopMedals[i], "CmdTopMedals");
	for(new i; i < sizeof commandSound; i++) register_clcmd(commandSound[i], "CmdSound");

	RegisterHam(Ham_Spawn , "player", "Spawn", 1);
	
	register_message(SVC_INTERMISSION, "MsgIntermission");
	register_message(get_user_msgid("SayText"),"handleSayText");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");

	sounds = nvault_open("stats_sound");
}

public plugin_cfg()
	SqlInit();
	
public plugin_end()
	SQL_FreeHandle(g_SqlTuple);
	
public plugin_natives()
	register_native("stats_add_kill", "native_stats_add_kill");

public plugin_precache()
{
	precache_sound("misc/csr/maytheforce.wav");
	precache_sound("misc/csr/oneandonly.wav");
	precache_sound("misc/csr/prepare.wav");
	precache_sound("misc/csr/humiliation.wav");
	precache_sound("misc/csr/lastleft.wav");
}

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
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `stats_system` (`name` varchar(32) NOT NULL, `admin` int(10) NOT NULL, `kills` int(10) NOT NULL, `time` int(10) NOT NULL, ");
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

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
	
	LoadSounds(id);
	LoadStats(id);
}

public client_authorized(id)
{
	if(get_user_flags(id) & ADMIN_BAN)
		g_Player[id][Admin] = 1;
	else
		g_Player[id][Admin] = 0;
}
	
public client_disconnected(id)
{
	SaveStats(id, 1);
	
	remove_task(id + TASK_TIME);

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
}

public Spawn(id)
{
	if(!is_user_alive(id))
		return;

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

		if(tempFrags > 0 && (tempFrags > bestFrags || (tempFrags == bestFrags && tempDeaths < bestDeaths)))
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
	if(!is_user_connected(victim) || !is_user_connected(killer) || killer == victim)
		return;

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

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
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

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
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

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.5, 0.15);
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
	
	if(g_Visit[id])
		return;
	
	if(!g_Loaded[id])
	{ 
		set_task(3.0, "CheckTime", id + TASK_TIME);
		return;
	}
	
	new iTime = get_systime(), iYear, Year, iMonth, Month, iDay, Day, iHour, iMinute, iSecond;
	
	UnixToTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
	
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Aktualnie jest godzina^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	
	if(g_Player[id][FirstVisit] == g_Player[id][LastVisit])
		client_print_color(id, print_team_red, "^x03[STATY]^x01 To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!" );
	else 
	{
		UnixToTime(g_Player[id][LastVisit], Year, Month, Day, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		if(iYear == Year && iMonth == Month && iDay == Day)
			client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoja ostatnia wizyta miala miejsce^x04 dzisiaj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else if(iYear == Year && iMonth == Month && (iDay - 1) == Day)
			client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoja ostatnia wizyta miala miejsce^x04 wczoraj^x01 o^x04 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
		else
			client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoja ostatnia wizyta:^x04 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, Year);
	}
	
	g_Visit[id] = true;
}

public CmdMenu(id)
{
	new menu = menu_create("\yMenu \yStatystyk\r", "CmdMenu_Handle");
 
	menu_additem(menu, "\wMoj \rCzas \y(/czas)", "1");
	if(get_user_flags(id) & ADMIN_BAN) menu_additem(menu, "\wCzas \rAdminow \y(/adminczas)", "2");
	menu_additem(menu, "\wTop \rCzasu \y(/ctop15)", "3");
	menu_additem(menu, "\wNajlepsze \rStaty \y(/staty)", "4");
	menu_additem(menu, "\wTop \rStatow \y(/stop15)", "5");
	menu_additem(menu, "\wMoje \rMedale \y(/medale)", "6");
	menu_additem(menu, "\wTop \rMedali \y(/mtop15)", "7");
    
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}  
 
public CmdMenu_Handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new itemData[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
    
	new item = str_to_num(itemData);
    
	switch(item)
    { 
		case 1: CmdTime(id);
		case 2: CmdTimeAdmin(id)
		case 3: CmdTopTime(id);
		case 4: CmdStats(id);
		case 5: CmdTopStats(id);
		case 6: CmdMedals(id);
		case 7: CmdTopMedals(id);
	}
	
	menu_destroy(menu);

	return PLUGIN_HANDLED;
} 

public CmdTime(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `time` > '%i' ORDER BY `time` DESC) b", g_Player[id][Time] + get_user_time(id));
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
	
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Spedziles na serwerze lacznie^x04 %i h %i min %i s^x01.", iHours, iMinutes, iSeconds);
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu czasu gry.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopTime(id)
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
	
	new id = Data[0], iPlace = 0, iLen = 0;
	
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

public CmdMedals(id)
{
	new szTemp[256], szName[32], Data[1];
	Data[0] = id;
	
	get_user_name(id, szName, 31);
	replace_all(szName, charsmax(szName), "'", "\'" );
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `stats_system`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `stats_system` WHERE `medals` > '%i' ORDER BY `medals` DESC) b", g_Player[id][Medals]);
	SQL_ThreadQuery(g_SqlTuple, "ShowMedals", szTemp, Data, 1);
}

public ShowMedals(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0) + 1;
	new iPlayers = SQL_ReadResult(Query, 1);
	
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoje medale:^x04 %i Zlote^x01,^x04 %i Srebre^x01,^x04 %i Brazowe^x01.", g_Player[id][Gold], g_Player[id][Silver], g_Player[id][Bronze]);
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu medalowym.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopMedals(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, gold, silver, bronze, medals FROM `stats_system` ORDER BY medals DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowMedalsTop", szTemp, Data, 1);
}

public ShowMedalsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iPlace = 0, iLen = 0;
	
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
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	new iRank = SQL_ReadResult(Query, 0);
	new iPlayers = SQL_ReadResult(Query, 1);
	
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
		client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths]);
	else
		client_print_color(id, print_team_red, "^x03[STATY]^x01 Twoje najlepsze staty to^x04 %i^x01 zabic (w tym^x04 %i^x01 z HS) i^x04 %i^x01 zgonow^x01.", g_Player[id][BestKills], g_Player[id][BestHS], g_Player[id][BestDeaths]);
		
	client_print_color(id, print_team_red, "^x03[STATY]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu najlepszych statystyk.", iRank, iPlayers);
	
	return PLUGIN_HANDLED;
}

public CmdTopStats(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, bestkills, besths, bestdeaths FROM `stats_system` ORDER BY beststats DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowStatsTop", szTemp, Data, 1);

	return PLUGIN_HANDLED;
}

public ShowStatsTop(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0], iPlace = 0, iLen = 0;
	
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
		return PLUGIN_HANDLED;
		
	new szTemp[256], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT name, time FROM `stats_system` WHERE admin = '1' ORDER BY time DESC");
	SQL_ThreadQuery(g_SqlTuple, "ShowTimeAdmin", szTemp, Data, 1);

	return PLUGIN_HANDLED;
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

public handleSayText(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id))
	{
		new szTempMessage[190], szMessage[190], szPrefix[64], szPlayerName[32], iStats[8], iBody[8], iRank;
		
		get_msg_arg_string(2, szTempMessage, charsmax(szTempMessage));
		iRank = get_user_stats(id, iStats, iBody);
		
		if(iRank > 3) return PLUGIN_CONTINUE;
			
		switch(iRank)
		{
			case 1: formatex(szPrefix, charsmax(szPrefix), "^x04[TOP1]");
			case 2: formatex(szPrefix, charsmax(szPrefix), "^x04[TOP2]");
			case 3: formatex(szPrefix, charsmax(szPrefix), "^x04[TOP3]");
		}
		
		if(!equal(szTempMessage, "#Cstrike_Chat_All"))
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), " ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		else
		{
			get_user_name(id, szPlayerName, charsmax(szPlayerName));

			get_msg_arg_string(4, szTempMessage, charsmax(szTempMessage)); 
			set_msg_arg_string(4, "");
	    
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), "^x03 ");
			add(szMessage, charsmax(szMessage), szPlayerName);
			add(szMessage, charsmax(szMessage), "^x01 :  ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		
		set_msg_arg_string(2, szMessage);
	}
	return PLUGIN_CONTINUE;
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
		
	new time = g_Player[id][Time] + get_user_time(id);
		
	new Data[1], szTemp[512], szTemp2[128];
	Data[0] = id;
	
	g_Player[id][CurrentStats] = g_Player[id][CurrentKills]*2 + g_Player[id][CurrentHS] - g_Player[id][CurrentDeaths]*2;
	if(g_Player[id][CurrentStats] > g_Player[id][BestStats])
	{			
		formatex(szTemp2, charsmax(szTemp2), ", `bestkills` = %d, `besths` = %d, `bestdeaths` = %d, `beststats` = %d", 
		g_Player[id][CurrentKills], g_Player[id][CurrentHS], g_Player[id][CurrentDeaths], g_Player[id][CurrentStats]);
	}
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `stats_system` SET `admin` = %i, `kills` = %i, `time` = %i, `lastvisit` = %i%s WHERE name = ^"%s^" AND `time` <= %i", 
	g_Player[id][Admin], g_Player[id][Kills], time, get_systime(), szTemp2, g_Player[id][Name], time);
	
	switch(type)
	{
		case 0, 1: SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp, Data, 1);
		case 2:
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

	if(type) g_Loaded[id] = false;
}

public SaveMedals(id)
{
	new szTemp[512];

	new iMedals = g_Player[id][Gold]*3 + g_Player[id][Silver]*2 + g_Player[id][Bronze];
	formatex(szTemp, charsmax(szTemp), "UPDATE `stats_system` SET `gold` = %d, `silver` = %d, `bronze` = %d, `medals` = %d WHERE name = ^"%s^" AND `medals` <= %i", 
	g_Player[id][Gold], g_Player[id][Silver], g_Player[id][Bronze], iMedals, g_Player[id][Name], iMedals);
	
	new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
	SqlConnection = SQL_Connect(g_SqlTuple, ErrCode, Error, charsmax(Error));

	if (!SqlConnection)
	{
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
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

public IgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED)
		log_to_file("addons/amxmodx/logs/stats_system.txt", "Query failed. [%d] %s", ErrCode, Error);
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

public MsgIntermission() 
{
	new szName[32], szPlayers[32], szBestID[3], szBestFrags[3], szBestDeaths[3], id, iNum, iTempFrags, iTempDeaths, iSwapFrags, iSwapDeaths, iSwapID;
	get_players(szPlayers, iNum, "h");
	
	if(iNum < 1)
		return PLUGIN_CONTINUE;
		
	for(new i = 0; i < iNum; i++)
	{
		id = szPlayers[i];
		
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id))
			continue;

		SaveStats(id, 2);
		
		iTempFrags = get_user_frags(id);
		iTempDeaths = get_user_deaths(id);
		
		if(iTempFrags > szBestFrags[0] || (iTempFrags == szBestFrags[0] && iTempDeaths < szBestDeaths[0]))
		{
			szBestFrags[0] = iTempFrags;
			szBestDeaths[0] = iTempDeaths;
			szBestID[0] = id;

			if(iTempFrags > szBestFrags[1] || (iTempFrags == szBestFrags[1] && iTempDeaths < szBestDeaths[1]))
			{
				iSwapFrags = szBestFrags[1];
				iSwapDeaths = szBestDeaths[1];
				iSwapID = szBestID[1];
				szBestFrags[1] = iTempFrags;
				szBestDeaths[1] = iTempDeaths;
				szBestID[1] = id;
				szBestFrags[0] = iSwapFrags;
				szBestDeaths[0] = iSwapDeaths;
				szBestID[0] = iSwapID;
				
				if(iTempFrags > szBestFrags[2] || (iTempFrags == szBestFrags[2] && iTempDeaths < szBestDeaths[2]))
				{
					iSwapFrags = szBestFrags[2];
					iSwapDeaths = szBestDeaths[2];
					iSwapID = szBestID[2];
					szBestFrags[2] = iTempFrags;
					szBestDeaths[2] = iTempDeaths;
					szBestID[2] = id;
					szBestFrags[1] = iSwapFrags;
					szBestDeaths[1] = iSwapDeaths;
					szBestID[1] = iSwapID;
				}
			}
		}
	}
	
	if(!szBestID[2]) return PLUGIN_CONTINUE;
	
	new const szType[][] = { "Brazowy", "Srebrny", "Zloty" };
	
	client_print_color(0, print_team_red, "^x03[STATY]^x01 Gratulacje dla^x04 Zwyciezcow^x01!");
	
	for(new i = 2; i >= 0; i--)
	{
		switch(i)
		{
			case 0: 
			{
				g_Player[szBestID[i]][Bronze]++;
				SaveMedals(szBestID[i]);
			}
			case 1: 
			{
				g_Player[szBestID[i]][Silver]++;
				SaveMedals(szBestID[i]);
			}
			case 2: 
			{
				g_Player[szBestID[i]][Gold]++;
				SaveMedals(szBestID[i]);
			}
		}
		
		get_user_name(szBestID[i], szName, 31);
		client_print_color(0, print_team_red, "^x03[STATY]^x04 %s^x01 - %s Medal -^x04 %i^x01 Zabojstw.", szName, szType[i], szBestFrags[i]);
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