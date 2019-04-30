#include <amxmodx>
#include <sqlx>
#include <cstrike>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Ranking"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

new szName[33][64], iKills[33], iWishes[33], iTime[33];

new bool:bLoaded[33], bool:Blocked;

new Handle:g_SqlTuple;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("jail_rank_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_rank_user", "511617", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_rank_pass", "Ph5P3FSR4FVOc66A", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_rank_database", "511617_jail", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_rank_table", "jail_rank", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_clcmd("say /ranking", "Ranking");
	register_clcmd("say_team /ranking","Ranking");
	register_clcmd("ranking", "Ranking");
	
	register_clcmd("say /brank", "BRank");
	register_clcmd("say_team /brank", "BRank");
	register_clcmd("brank", "BRank");
	
	register_clcmd("say /zrank", "ZRank");
	register_clcmd("say_team /zrank", "ZRank");
	register_clcmd("zrank", "ZRank");
	
	register_clcmd("say /crank", "CRank");
	register_clcmd("say_team /crank", "CRank");
	register_clcmd("crank", "CRank");
	
	register_clcmd("say /btop15", "BTop15");
	register_clcmd("say_team /btop15", "BTop15");
	register_clcmd("btop15", "BTop15");
	
	register_clcmd("say /ztop15", "ZTop15");
	register_clcmd("say_team /ztop15", "ZTop15");
	register_clcmd("ztop15", "ZTop15");
	
	register_clcmd("say /ctop15", "CTop15");
	register_clcmd("say_team /ctop15", "CTop15");
	register_clcmd("ctop15", "CTop15");
	
	register_clcmd("say /czas", "ShowTime");
	register_clcmd("say_team /czas", "ShowTime");
	register_clcmd("czas", "ShowTime");
}

public plugin_cfg()
	SqlInit();

public plugin_natives()
	register_native("jail_get_user_time", "jail_get_user_time", 1);
	
public SqlInit()
{
	new szHost[32], szUser[32], szPass[32], szszDatabase[32], szTemp[256];
	
	get_cvar_string("jail_rank_host", szHost, charsmax(szHost));
	get_cvar_string("jail_rank_user", szUser, charsmax(szUser));
	get_cvar_string("jail_rank_pass", szPass, charsmax(szPass));
	get_cvar_string("jail_rank_database", szszDatabase, charsmax(szszDatabase));
	
	g_SqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szszDatabase);
	
	new Error, szError[128], Handle:hConn = SQL_Connect(g_SqlTuple, Error, szError, 127);
	
	if(Error)
	{
		log_to_file("addons/amxmodx/logs/jail_ranking.txt", "Error: %s", szError);
		
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `jail_rank` (`name` varchar(32) NOT NULL, `zabicia` int(10) NOT NULL DEFAULT '0', `zyczenia` int(10) NOT NULL DEFAULT '0', `czas` int(10) NOT NULL DEFAULT '0', PRIMARY KEY (`name`));");
	
	new Handle:Query = SQL_PrepareQuery(hConn, szTemp);
	
	SQL_Execute(Query);
	SQL_FreeHandle(Query);
	SQL_FreeHandle(hConn);
}

public plugin_end()
	SQL_FreeHandle(g_SqlTuple);
	
public client_putinserver(id)
{
	if(is_user_hltv(id) || is_user_bot(id)) return PLUGIN_CONTINUE;

	iKills[id] = 0;
	iWishes[id] = 0;
	iTime[id] = 0;

	bLoaded[id] = false;

	new szTemp[128], szData[1];
	
	get_user_name(id, szName[id], charsmax(szName));
	
	replace_all(szName[id], charsmax(szName), "'", "\'");
	replace_all(szName[id], charsmax(szName), "`", "\`");
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `jail_rank` WHERE name = '%s';", szName[id]);
	SQL_ThreadQuery(g_SqlTuple, "LoadStats", szTemp, szData, 1);
	
	return PLUGIN_CONTINUE;
}

public LoadStats(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}

	new id = szData[0];
	
	if(SQL_NumResults(Query))
	{
		iKills[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "zabicia"));
		iWishes[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "zyczenia"));
		iTime[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "czas"));
	}
	else
	{
		new szTemp[128];
		
		formatex(szTemp, charsmax(szTemp), "INSERT IGNORE INTO `jail_rank` (`name`) VALUES ('%s');", szName[id]);
		SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
	}
	
	bLoaded[id] = true;
}

public OnRemoveData()
	Blocked = false;

public OnLastPrisonerWishTaken(id)
{
	Blocked = true;
	
	iWishes[id]++;
	
	new szTemp[128];
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `jail_rank` SET `zyczenia` = (`zyczenia` + 1) WHERE `name` = '%s'", szName[id]);
	SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
}

public DeathMsg()
{
	new Victim = read_data(2), Killer = read_data(1);
	
	if(!is_user_connected(Victim) || !is_user_connected(Killer) || get_user_team(Victim) != 2 || Blocked) return;

	iKills[Killer]++;
	
	new szTemp[128];
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `jail_rank` SET `zabicia` = (`zabicia` + 1) WHERE `name` = '%s'", szName[Killer]);
	SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
}

public ShowTime(id)
{
	new sekundy = (iTime[id] + get_user_time(id)), minuty, godziny;
	
	while(sekundy >= 60)
	{
		sekundy -= 60;
		minuty++;
	}
	while(minuty >= 60)
	{
		minuty -= 60;
		godziny++;
	}
	
	client_print_color(id, id, "^x04[CZAS]^x01 Spedziles na serwerze^x03 %i h %i min %i s^x01.", godziny, minuty, sekundy);
	
	return PLUGIN_HANDLED;
}

public client_disconnected(id)
{
	if(is_user_hltv(id) || is_user_bot(id) || !bLoaded[id]) return PLUGIN_CONTINUE;

	new szTemp[128];
	
	formatex(szTemp, charsmax(szTemp), "UPDATE `jail_rank` SET `czas` = (`czas` + %i) WHERE `name` = '%s'", get_user_time(id), szName[id]);
	SQL_ThreadQuery(g_SqlTuple, "IgnoreHandle", szTemp);
	
	return PLUGIN_CONTINUE;
}

public Ranking(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \rMenu Rankingu", "Ranking_Handler");   
	
	menu_additem(menu, "\wTOP15 \yZyczen \r(/ztop15)");
	menu_additem(menu, "\wTOP15 \yBuntow \r(/btop15)");
	menu_additem(menu, "\wTOP15 \yCzasu \r(/ctop15)");
	menu_additem(menu, "\wTwoje \yZyczenia \r(/zrank)");
	menu_additem(menu, "\wTwoje \yBunty \r(/brank)");
	menu_additem(menu, "\wTwoj \yCzas \r(/crank)");
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public Ranking_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{	
		case 0: ZTop15(id);
		case 1: BTop15(id);
		case 2: CTop15(id);
		case 3: ZRank(id);
		case 4: BRank(id);
		case 5: CRank(id);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
} 

public BRank(id)
{
	new szTemp[256], szData[1];
	
	szData[0] = id;

	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `jail_rank`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `jail_rank` WHERE `zabicia` > '%i' ORDER BY `zabicia` DESC) b", iKills[id]);
	SQL_ThreadQuery(g_SqlTuple, "PobierzBRank", szTemp, szData, 1);
}

public PobierzBRank(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new Rank = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"rank")) + 1, Count = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"count"));
		
		client_print_color(id, id, "^x04[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu z^x04 %i^x01 buntami.", Rank, Count, iKills[id]);
	}
}

public BTop15(id)
{
	new szTemp[128], szData[1];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `jail_rank` ORDER BY `zabicia` DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "PobierzBTop15", szTemp, szData, 1);
}

public PobierzBTop15(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new szBuffer[2048], szName[64], iLen = 0, i = 0;
		
		iLen = copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "<body bgcolor=#FFFFFF><table width=100%% cellpadding=2 cellspacing=0 border=0>");
		iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center bgcolor=#52697B><th width=5%%> # <th width=35%% align=left> Gracz: <th width=20%%> Bunty:");
		
		while(SQL_MoreResults(Query))
		{
			SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"name"), szName, charsmax(szName));
			
			replace_all(szName, charsmax(szName), "<", "&lt;");
			replace_all(szName, charsmax(szName), ">", "&gt;");
			
			iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center%s><td> %i. <td align=left> %s <td> %i", ((i%2)==0)? "" :" bgcolor=#A4BED6", i+1, szName, SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"zabicia")));
			
			i++;
			
			SQL_NextRow(Query);
		}
		
		iLen += copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "</table></body>");
		
		show_motd(id, szBuffer, "Top 15 Buntow");
	}
}

public ZRank(id)
{
	new szTemp[256], szData[1];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `jail_rank`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `jail_rank` WHERE `zyczenia` > '%i' ORDER BY `zyczenia` DESC) b", iWishes[id]);
	SQL_ThreadQuery(g_SqlTuple, "PobierzZRank", szTemp, szData, 1);
}

public PobierzZRank(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new Rank = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"rank")) + 1, Count = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"count"));
		
		client_print_color(id, id, "^x04[RANK]^x01 Zajmujesz^x04 %i/%i^x01 miejsce w rankingu z^x04 %i^x01 zyczeniami.", Rank, Count, iWishes[id]);
	}
}

public ZTop15(id)
{
	new szTemp[128], szData[1];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `jail_rank` ORDER BY `zyczenia` DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "PobierzZTop15", szTemp, szData, 1);
}

public PobierzZTop15(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new szBuffer[2048], szName[64], iLen = 0, i = 0;
		
		iLen = copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "<body bgcolor=#FFFFFF><table width=100%% cellpadding=2 cellspacing=0 border=0>");
		iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center bgcolor=#52697B><th width=5%%> # <th width=35%% align=left> Gracz: <th width=20%%> Zyczenia:");
		
		while(SQL_MoreResults(Query))
		{
			SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"name"), szName, charsmax(szName));
			
			replace_all(szName, charsmax(szName), "<", "&lt;");
			replace_all(szName, charsmax(szName), ">", "&gt;");
			
			iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center%s><td> %i. <td align=left> %s <td> %i", ((i%2)==0)? "" :" bgcolor=#A4BED6", i+1, szName, SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"zyczenia")));
			
			i++;
			
			SQL_NextRow(Query);
		}
		
		iLen += copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "</table></body>");
		
		show_motd(id, szBuffer, "Top 15 Zyczen");
	}
}

public CRank(id)
{
	new szTemp[256], szData[1], iPlayerTime = get_user_time(id) + iTime[id];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `jail_rank`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `jail_rank` WHERE `czas` > '%i' ORDER BY `czas` DESC) b", iPlayerTime);
	SQL_ThreadQuery(g_SqlTuple, "PobierzCRank", szTemp, szData, 1);
}

public PobierzCRank(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new Rank = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"rank")) + 1, Count = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"count"));
		
		new sekundy = (iTime[id] + get_user_time(id)), minuty, godziny;
		
		while(sekundy >= 60)
		{
			sekundy -= 60;
			minuty++;
		}
		while(minuty >= 60)
		{
			minuty -= 60;
			godziny++;
		}
		
		client_print_color(id, id, "^x04[RANK]^x01 Twoj czas gry wynosi^x03 %i h %i min %i s^x01. Zajmujesz^x03 %i/%i^x01 miejsce w rankingu.", godziny, minuty, sekundy, Rank, Count);
	}
}

public CTop15(id)
{
	new szTemp[128], szData[1];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `jail_rank` ORDER BY `czas` DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "PobierzCTop15", szTemp, szData, 1);
}

public PobierzCTop15(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		
		return;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Query failed. [%d] %s", ErrCode, Error);
		
		return;
	}
	
	new id = szData[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_NumResults(Query))
	{
		new szBuffer[2048], szName[64], iLen = 0, i = 0;
		
		iLen = copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "<body bgcolor=#FFFFFF><table width=100%% cellpadding=2 cellspacing=0 border=0>");
		iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center bgcolor=#52697B><th width=5%%> # <th width=35%% align=left> Gracz: <th width=20%%> Czas Gry:");
		
		while(SQL_MoreResults(Query))
		{
			SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"name"), szName, charsmax(szName));
			
			replace_all(szName, charsmax(szName), "<", "&lt;");
			replace_all(szName, charsmax(szName), ">", "&gt;");
			
			new sekundy = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"czas")), minuty, godziny;
			
			while(sekundy >= 60)
			{
				sekundy -= 60;
				minuty++;
			}
			while(minuty >= 60)
			{
				minuty -= 60;
				godziny++;
			}
			
			iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "<tr align=center%s><td> %i. <td align=left> %s <td> %ih %imin %is", ((i%2)==0)? "" :" bgcolor=#A4BED6", i+1, szName, godziny, minuty, sekundy);
			
			i++;
			
			SQL_NextRow(Query);
		}
		
		iLen += copy(szBuffer[iLen], charsmax(szBuffer) - iLen, "</table></body>");
		
		show_motd(id, szBuffer, "Top 15 Czasu Gry");
	}
}

public IgnoreHandle(FailState, Handle:Query, Error[], ErrCode, szData[], szDataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED) log_amx("Could not connect to SQL database.  [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED) log_amx("Query failed. [%d] %s", ErrCode, Error);
}

public jail_get_user_time(id)
	return (iTime[id] + get_user_time(id));