#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <fakemeta>
#include <xs>

#define PLUGIN  "Zawolaj Admina"
#define VERSION "2.2"
#define AUTHOR  "O'Zone"

#define PREFIX  "^x04[ADMIN]^x01"
#define OWNREASON "Wlasny Powod"
#define LOGFILE "addons/amxmodx/logs/ZawolajAdmina.log"
#define QUERY "INSERT INTO `zgloszenia` (notification, time) VALUES ('<b><font color=^"green^">(%s)</font> <font color=^"white^">Gracz %s zg&#322asza:</font> <font color=^"red^">%s %s</font></b>', UNIX_TIMESTAMP())"

new const szCommandReport[][] = { "say /report", "say_team /report", "say /zawolaj", "say_team /zawolaj", "say /wezwij", 
"say_team /wezwij", "say /zglos", "say_team /zglos", "say /admin", "say_team /admin", "say /admins", "say_team /admins" };

new iLastMessage[33], iReportedID[33][2];

new cvarHost, cvarUser, cvarPass, cvarDB, cvarServer;

new szHost[16], szUser[20], szPass[32], szDb[32];

new Array:aReasons, Array:aPhrases, Array:aReported;

new Handle:hSqlConnection;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cvarHost = register_cvar("zawolaj_admina_sql_host", "localhost", FCVAR_SPONLY|FCVAR_PROTECTED);
	cvarUser = register_cvar("zawolaj_admina_sql_user", "user", FCVAR_SPONLY|FCVAR_PROTECTED);
	cvarPass = register_cvar("zawolaj_admina_sql_pass", "password", FCVAR_SPONLY|FCVAR_PROTECTED);
	cvarDB = register_cvar("zawolaj_admina_sql_db", "database", FCVAR_SPONLY|FCVAR_PROTECTED);
	cvarServer = register_cvar("zawolaj_admina_server", "Server", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	for(new i; i < sizeof szCommandReport; i++)
		register_clcmd(szCommandReport[i], "SelectPlayer");

	register_clcmd("Wpisz_Powod", "SetReason");
}

public plugin_cfg()
{ 
	get_pcvar_string(cvarHost, szHost, charsmax(szHost));
	get_pcvar_string(cvarUser, szUser, charsmax(szUser));
	get_pcvar_string(cvarPass, szPass, charsmax(szPass));
	get_pcvar_string(cvarDB, szDb, charsmax(szDb));
	
	hSqlConnection = SQL_MakeDbTuple(szHost, szUser, szPass, szDb);
	
	aReasons = ArrayCreate(32, 1);
	
	new szFile[128], szConfigsDir[64]; 
	
	get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
	format(szFile, charsmax(szFile), "%s/za_powody.ini", szFile);
	
	if(!file_exists(szFile))
		set_fail_state("[Zawolaj Admina] Brak pliku z powodami!");
	
	new bool:bOwnReason, szContent[128], iOpen = fopen(szFile, "r");
	
	while(!feof(iOpen))
	{
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
		if(szContent[0] == ';' || szContent[0] == '^0') 
			continue;
		
		if(equali(szContent, OWNREASON))
			bOwnReason = true;
		
		ArrayPushString(aReasons, szContent);
	}

	fclose(iOpen);
	
	if(bOwnReason)
	{
		aPhrases = ArrayCreate(64, 1);
		
		get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
		format(szFile, charsmax(szFile), "%s/za_frazy.ini", szFile);
	
		if(!file_exists(szFile))
			set_fail_state("[Zawolaj Admina] Brak pliku z frazami własnego powodu!");
	
		iOpen = fopen(szFile, "r");
		
		while(!feof(iOpen)) 
		{
			fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
			if(szContent[0] == ';' || szContent[0] == '^0') continue;
		
			ArrayPushString(aPhrases, szContent);
		}
		fclose(iOpen);
	}
	
	aReported = ArrayCreate(32, 1);
	
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	server_cmd("exec %s/amxx.cfg", szConfigsDir);
} 

public plugin_end()
	SQL_FreeHandle(hSqlConnection);

public client_connect(id)
{
	iLastMessage[id] = 0;
	iReportedID[id][0] = 0;
	iReportedID[id][1] = 0;
}

public SelectPlayer(id)
{
	if(iLastMessage[id] + 120.0 > get_gametime() && iLastMessage[id] > 0)
	{
		client_print_color(id, print_team_red, "^x03%s Nie spamuj! Mozesz wyslac wiadomosc raz na^x03 2 minuty^x01.", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	new menu = menu_create("\wWybierz \rgracza\w, ktorego chcesz \yzglosic\w:", "SelectPlayer_Handler");
	new szName[33], szPlayers[32], szTempID[10], iNum, iPlayer, iPlayers;
	
	get_players(szPlayers, iNum);
	
	for(new i; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		
		if(is_user_connected(iPlayer) && !is_user_bot(iPlayer) && !is_user_hltv(iPlayer) && iPlayer != id)
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
	
	if(iPlayers)
	{
		client_print_color(id, print_team_red, "^x03%s Pamietaj, ze ta opcja sluzy do zglaszania^x03 100%% winnych graczy^x01!", PREFIX);
		client_print_color(id, print_team_red, "^x03%s Za uzywanie jej do innych celow lub za bezpodstawne oskarzenia grozi^x03 BAN^x01!", PREFIX);
	}
	else
		client_print_color(id, print_team_red, "^x03%s Na serwerze^x03 nie ma zadnego gracza^x01, ktorego moglbys^x03 zglosic^x01!", PREFIX);
	
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
		client_print_color(id, print_team_red, "^x03%s Wybranego gracza nie ma juz na serwerze!", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	if(CheckReports(player))
	{
		client_print_color(id, print_team_red, "^x03%s Ten gracz zostal juz^x03 zgloszony^x01!", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu);
	
	iReportedID[id][0] = player;
	iReportedID[id][1] = playerID;

	SelectReason(id);
	
	return PLUGIN_HANDLED;
}

public SelectReason(id)
{
	new menu = menu_create("\wWybierz \rpowod \wzgloszenia \ygracza\w:", "SelectReason_Handler");
	new szReason[32];
	
	for(new i; i < ArraySize(aReasons); i++)
	{
		ArrayGetString(aReasons, i, szReason, charsmax(szReason));
		menu_additem(menu, szReason);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public SelectReason_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szReason[32], szData[1], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szReason, charsmax(szReason), iCallback);
	
	if(equali(szReason, OWNREASON))
	{
		client_cmd(id, "messagemode Wpisz_Powod");
		client_print(id, print_center, "Wpisz powod, przez ktory zglaszasz wybranego gracza!");
		client_print_color(id, print_team_red, "^x03%s Wpisz^x03 powod^x01, przez ktory zglaszasz wybranego gracza!", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu);
	
	ReportPlayer(id, szReason);

	return PLUGIN_HANDLED;
}

public SetReason(id)
{
	new szReason[64], szTemp[32];
	read_args(szReason, charsmax(szReason));
	remove_quotes(szReason);
	
	if(!szReason[0])
	{
		client_cmd(id, "messagemode Wpisz_Powod");
		client_print(id, print_center, "Nie wpisano powodu! Wpisz go teraz!");
		client_print_color(id, print_team_red, "^x03%s Nie wpisano^x03 powodu^x01! Wpisz go teraz!", PREFIX);
		return PLUGIN_HANDLED;
	}

	for(new i = 0; i < ArraySize(aPhrases); i++)
	{
		ArrayGetString(aPhrases, i, szTemp, charsmax(szTemp));
		
		if(containi(szReason, szTemp) != -1)
		{
			ReportPlayer(id, szReason);
			return PLUGIN_HANDLED;
		}
	}

	client_print_color(id, print_team_red, "^x03%s Wyglada na to, ze wpisany powod nie jest odpowiedni!", PREFIX);
	
	return PLUGIN_HANDLED;
}

public ReportPlayer(id, const szReason[])
{
	if(iLastMessage[id] + 180.0 > get_gametime() && iLastMessage[id] > 0)
	{
		client_print_color(id, print_team_red, "^x03%s Nie spamuj! Mozesz wyslac wiadomosc raz na^x03 3 minuty^x01.", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	new player = iReportedID[id][0];
	
	if(CheckReports(player))
	{
		client_print_color(id, print_team_red, "^x03%s Ten gracz zostal juz^x03 zgloszony^x01!", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	if(get_user_userid(player) != iReportedID[id][1] || !is_user_connected(player))
	{
		client_print_color(id, print_team_red, "^x03%s Wybranego gracza nie ma już na serwerze!", PREFIX);
		return PLUGIN_HANDLED;
	}

	new szQuery[512], szTempReason[64], szAuthID[35], szSteamID[35], szIP[33], szName[33], szPlayer[33], szServer[33];
	
	get_user_name(player, szPlayer, charsmax(szPlayer));
	get_user_name(id, szName, charsmax(szName));
	get_user_ip(id, szIP, charsmax(szIP), 1);
	get_user_authid(id, szAuthID, charsmax(szAuthID));
	get_user_authid(player, szSteamID, charsmax(szSteamID));
	
	ArrayPushString(aReported, szPlayer);

	for(new player = 1; player < get_maxplayers(); player++)
	{
		if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN)
		{
			client_cmd(id, "say_team @ %s %s", szPlayer, szReason);
			break;
		}
	}
	
	get_pcvar_string(cvarServer, szServer, charsmax(szServer));

	iLastMessage[id] = floatround(get_gametime());
	
	log_to_file(LOGFILE, "Gracz %s <IP:%s><%s> wyslal wiadomosc: %s %s", szName, szIP, szAuthID, szPlayer, szReason);
	
	MySQLString(szReason, szTempReason, charsmax(szTempReason));
	MySQLString(szPlayer, szPlayer, charsmax(szPlayer));
	MySQLString(szName, szName, charsmax(szName));
	
	format(szQuery, charsmax(szQuery), QUERY, szServer, szName, szPlayer, szTempReason);
	SQL_ThreadQuery(hSqlConnection, "Query_Handle", szQuery);
	
	client_print_color(id, print_team_red, "^x03%s Wiadomosc^x03 wyslana^x01! Niedlugo^x03 Admin^x01 powinien pojawic sie na serwerze.", PREFIX);
	
	return PLUGIN_HANDLED;
}

public Query_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	switch(iFailState) 
	{
		case TQUERY_CONNECT_FAILED: { log_to_file(LOGFILE, "Nie udalo sie polaczyc z baza danych (%i): %s", iError, szError); }
		case TQUERY_QUERY_FAILED: { log_to_file(LOGFILE, "Blad podczas tworzenia wpisu w bazie danych (%i): %s", iError, szError); }
	}
}

stock CheckReports(player)
{
	new szName[33], szReported[33];
	get_user_name(player, szName, charsmax(szName));
	
	for(new i = 0; i < ArraySize(aReported); i++)
	{
		ArrayGetString(aReported, i, szReported, charsmax(szReported));

		if(equali(szName, szReported))
			return 1;
	}
	return 0;
}

stock MySQLString(const szSource[], szDest[], iLen)
{
	copy(szDest, iLen, szSource);
	replace_all(szDest, iLen, "\\", "\\\\");
	replace_all(szDest, iLen, "\0", "\\0");
	replace_all(szDest, iLen, "\n", "\\n");
	replace_all(szDest, iLen, "\r", "\\r");
	replace_all(szDest, iLen, "\x1a", "\Z");
	replace_all(szDest, iLen, "'", "\'");
	replace_all(szDest, iLen, "`", "\`");
	replace_all(szDest, iLen, "^"", "\^"");
}