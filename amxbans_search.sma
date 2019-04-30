#include <amxmodx>
#include <sqlx>
#include <colorchat>

#define PLUGIN "AmxBans Active Bans Searcher"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define TASK_CHECK 7031

new cvarHost, cvarUser, cvarPassword, cvarDatabase;

new Handle:hSqlTuple;

new szSearchName[33][33], szSearchIP[33][33], szSearchSteamID[33][35];

new iSearch[33][6];

//native autoupdater_register_plugin();

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	//autoupdater_register_plugin();
	
	register_concmd("amx_search", "SelectPlayer", ADMIN_BAN, "Search for active player bans");
	
	cvarHost = register_cvar("amx_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);  
	cvarUser = register_cvar("amx_sql_user", "262947", FCVAR_SPONLY|FCVAR_PROTECTED); 
	cvarPassword = register_cvar("amx_sql_pass", "gbk#cm@T+SL@zPw", FCVAR_SPONLY|FCVAR_PROTECTED); 
	cvarDatabase = register_cvar("amx_sql_db", "262947_amxbans", FCVAR_SPONLY|FCVAR_PROTECTED);
}

public plugin_cfg()
{
	new szHost[64], szUser[64], szPass[64], szDatabase[64];
	
	get_pcvar_string(cvarHost, szHost, charsmax(szHost));
	get_pcvar_string(cvarUser, szUser, charsmax(szUser));
	get_pcvar_string(cvarPassword, szPass, charsmax(szPass));
	get_pcvar_string(cvarDatabase, szDatabase, charsmax(szDatabase));
	
	hSqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
}

public client_putinserver(id)
	set_task(5.0, "CheckPlayer", id + TASK_CHECK);
	
public client_disconnect(id)
	remove_task(id + TASK_CHECK);
	
public CheckPlayer(id)
{
	id -= TASK_CHECK;
	
	if(!is_user_bot(id) && !is_user_hltv(id) && !(get_user_flags(id) & ADMIN_BAN))
		SearchBan(id, id);
}

public SelectPlayer(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		ColorChat(id, RED, "[AmxBans]^x01 Brak uprawnien!");
		console_print(id, "[AmxBans] Brak uprawnien!");
		return PLUGIN_HANDLED;
	}
	
	new menu = menu_create("\wWybierz \rgracza\w, ktorego chcesz \ysprawdzic\w:", "SelectPlayer_Handler");
	new szName[33], szPlayers[32], szTempID[10], iNum, iPlayer, iPlayers;
	
	get_players(szPlayers, iNum);
	
	for(new i; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		
		if(is_user_connected(iPlayer) && !is_user_bot(iPlayer) && !is_user_hltv(iPlayer) && iPlayer != id && !(get_user_flags(id) & ADMIN_BAN))
		{
			get_user_name(iPlayer, szName, charsmax(szName));
			num_to_str(get_user_userid(iPlayer), szTempID, charsmax(szTempID));
			menu_additem(menu, szName, szTempID);
			iPlayers++;
		}
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, menu);
	
	if(!iPlayers)
		ColorChat(id, RED, "[AmxBans]^x01 Na serwerze^x03 nie ma zadnego gracza^x01, ktorego moglbys^x03 sprawdzic^x01!");

	return PLUGIN_HANDLED;
}

public SelectPlayer_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szName[33], szData[10], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new player = get_user_index(szName);
	new playerID = str_to_num(szData);
	
	if(!is_user_connected(player) || get_user_userid(player) != playerID)
	{
		ColorChat(id, RED, "[AmxBans]^x01 Wybranego gracza nie ma juz na serwerze!");
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu);
	
	iSearch[id][0] = player;
	iSearch[id][1] = playerID;

	SearchBan(id, player);
	
	return PLUGIN_HANDLED;
}

public SearchBan(id, player)
{
	new szQuery[512], szTempName[33], szData[2];
	szData[0] = id;
	szData[1] = player;
	
	get_user_name(player, szSearchName[id], charsmax(szSearchName));
	get_user_ip(player, szSearchIP[id], charsmax(szSearchIP), 1);
	get_user_authid(player, szSearchSteamID[id], charsmax(szSearchSteamID));
	
	mysql_escape_string(szSearchName[id], szTempName, charsmax(szTempName));
	
	format(szQuery, charsmax(szQuery), "SELECT * FROM `amx_bans` WHERE (`player_nick` LIKE '%s' OR `player_ip` = '%s' OR `player_id` = '%s') AND `ban_reason` NOT LIKE 'podszywka' AND `expired` NOT LIKE 1 AND `ban_created` > %d", szTempName, szSearchIP[id], szSearchSteamID[id], get_systime() - 7884000);
	SQL_ThreadQuery(hSqlTuple, "SearchBan_Handle", szQuery, szData, 2);
}

public SearchBan_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	switch(iFailState) 
	{
		case TQUERY_CONNECT_FAILED: { log_amx("Nie udalo sie polaczyc z baza danych (%i): %s", iError, szError); }
		case TQUERY_QUERY_FAILED: { log_amx("Blad podczas wykonywania zapytania (%i): %s", iError, szError); }
	}
	
	new szAuthID[35], szIP[33], szName[33], id, player;
	
	id = szData[0];
	player = szData[1];

	while(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "player_id"), szAuthID, charsmax(szAuthID));
		
		if(equal(szSearchSteamID[id], szAuthID))
			iSearch[id][3]++;
		
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "player_ip"), szIP, charsmax(szIP));
			
		if(equal(szSearchIP[id], szIP))
			iSearch[id][4]++;
			
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "player_nick"), szName, charsmax(szName));
			
		if(equali(szSearchName[id], szName))
			iSearch[id][5]++;
		
		iSearch[id][2]++;
		
		SQL_NextRow(hQuery);
	}
	
	if(!iSearch[id][2] && player != id)
		ColorChat(id, RED, "[AmxBans]^x01 Nie znaleziono^x03 zadnych banow^x01 dla wybranego gracza.");
	else
	{
		if(player != id)	MenuBan(id);
		else	
		{
			log_to_file("addons/amxmodx/logs/AmxBans_Search.log", "Gracz %s <IP:%s><%s> moze grac na aktywnym banie.", szSearchName[id], szSearchIP[id], szSearchSteamID[id]);
			PrintInfo(player);
		}
	}

	return PLUGIN_HANDLED;
}

public MenuBan(id)
{
	if(!is_user_connected(iSearch[id][0]) || get_user_userid(iSearch[id][0]) != iSearch[id][1])
	{
		ColorChat(id, RED, "[AmxBans]^x01 Wybranego gracza nie ma juz na serwerze!");
		return PLUGIN_HANDLED;
	}
	
	new szMenu[256];
	formatex(szMenu, charsmax(szMenu), "\wZnalezione bany: \r%i^n\w- \yO tym samym SteamID: \r%i^n\w- \yO tym samym IP: \r%i^n\w- \yO tym samym/podobnym nicku: \r%i^n^n\wZbanowac \rgracza\w za \yaktywnego bana\w?", iSearch[id][2], iSearch[id][3], iSearch[id][4], iSearch[id][5]);
	
	new menu = menu_create(szMenu, "MenuBan_Handler");

	menu_additem(menu, "Tak");
	menu_additem(menu, "Nie");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu, 0);	
	return PLUGIN_HANDLED;
}

public MenuBan_Handler(id, menu, item)
{
	if(!is_user_connected(iSearch[id][0]) || get_user_userid(iSearch[id][0]) != iSearch[id][1])
	{
		ColorChat(id, RED, "[AmxBans]^x01 Wybranego gracza nie ma juz na serwerze!");
		return PLUGIN_HANDLED;
	}
	
	if(!item)
		client_cmd(id, "amx_ban 0 #%d ^"Aktywny Ban^"", iSearch[id][1]);
	
	return PLUGIN_HANDLED;
}

public PrintInfo(player)
{
	new szName[33], szPlayers[32], iNum, iPlayer;
	
	get_players(szPlayers, iNum);
	get_user_name(player, szName, charsmax(szName));
	
	for(new i; i < iNum; i++)
	{
		iPlayer = szPlayers[i];

		if(is_user_connected(iPlayer) && !is_user_bot(iPlayer) && !is_user_hltv(iPlayer) && iPlayer != player && get_user_flags(iPlayer) & ADMIN_BAN)
			ColorChat(iPlayer, RED, "[AmxBans]^x01 Gracz^x04 %s^x01 moze grac na^x03 aktywnym banie^x01!", szName);
	}
}

stock mysql_escape_string(const szSource[], szDest[], iLen)
{
	copy(szDest, iLen, szSource);
	replace_all(szDest, iLen, "\\","\\\\");
	replace_all(szDest, iLen, "\0","\\0");
	replace_all(szDest, iLen, "\n","\\n");
	replace_all(szDest, iLen, "\r","\\r");
	replace_all(szDest, iLen, "\x1a","\Z");
	replace_all(szDest, iLen, "'","\'");
	replace_all(szDest, iLen, "^"","\^"");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ uc1\\ deff0\\ deflang1045\\ deflangfe1045{\\ fonttbl{\\ f0 Tahoma;}}\n\\ f0{\\ colortbl;}{\\ *\\ generator Wine Riched20 2.0.????;}\\ pard\\ sl-240\\ slmult1\\ li0\\ fi0\\ ri0\\ sa0\\ sb0\\ s-1\\ cfpat0\\ cbpat0\n\\ par}
*/
