#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "O'Zone Ban Config"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define TASK_QUIT 8954
#define TASK_CHECK 3245
#define TASK_KICK 5402
#define TASK_IP 9341

#define MAX_PLAYERS 32

new const szBanReasons[][] = { "Aimbot", "Wallhack", "Aimbot + Wallhack", "Speedhack", "Aktywny Ban" };

new szBanInfo[32], szConfig1[32], szConfig2[32], szConfig3[32], szConfig4[32], szConfig5[32], szConfig6[32], szConfig7[32], szConfig8[32];

new iPlayerID[MAX_PLAYERS + 1], iPlayerUserID[MAX_PLAYERS + 1], bool:bInfo[MAX_PLAYERS + 1], Array:aBannedNames, Array:aBlockedPhrases, Handle:hHookSql, gSyncHud, iMaxPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("cban_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_sql_user", "510128", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_sql_pass", "xvQ5CusRVCVzj83aruWk", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_sql_db", "510128_amxbans", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_info", "_int", FCVAR_SPONLY|FCVAR_PROTECTED);

	register_cvar("cban_ban_cfg1", "models\player\vip\vip", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg2", "config_backup", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg3", "gfx\vgui\xm1014", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg4", "maps\de_dust2", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg5", "maps\zm_inferno", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg6", "resource\UI\Spectator", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg7", "sound\player\volume", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("cban_ban_cfg8", "sound\misc\roundsound", FCVAR_SPONLY|FCVAR_PROTECTED);

	register_concmd("amx_cban", "ConfigBan", ADMIN_BAN, "amx_cban <nick/userid> <powod> - Banuje gracza na config");
	register_concmd("amx_cbanmenu", "ConfigBanMenu", ADMIN_BAN, "Pokazuje menu graczy do zbanowania");
	register_concmd("amx_cunban", "ConfigUnban", ADMIN_BAN, "amx_cunban <id> - Zdejmuje z gracza ban na config");
	register_concmd("amx_cunbanmenu", "ConfigUnbanMenu", ADMIN_BAN, "Pokazuje menu graczy do unbanowania");
	register_concmd("amx_nban", "NameBan", ADMIN_BAN, "amx_nban <nick/userid> <powod> - Banuje gracza na nick");
	register_concmd("amx_nbanmenu", "NameBanMenu", ADMIN_BAN, "Pokazuje menu graczy do zbanowania");

	aBannedNames = ArrayCreate(32, 32);
	aBlockedPhrases = ArrayCreate(32, 32);

	gSyncHud = CreateHudSyncObj();

	iMaxPlayers = get_maxplayers();
}

public plugin_cfg()
{
	new szFile[128];

	get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
	format(szFile, charsmax(szFile), "%s/blocked_phrases.ini", szFile);

	if (!file_exists(szFile)) set_fail_state("[BLOCK] Brak pliku blocked_phrases.ini!");

	new szContent[64], iOpen = fopen(szFile, "r");

	while (!feof(iOpen)) {
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);

		if(szContent[0] == ';' || szContent[0] == '^0') continue;

		ArrayPushString(aBlockedPhrases, szContent);
	}

	fclose(iOpen);

	new szData[4][64];

	get_cvar_string("cban_sql_host", szData[0], charsmax(szData[]));
	get_cvar_string("cban_sql_user", szData[1], charsmax(szData[]));
	get_cvar_string("cban_sql_pass", szData[2], charsmax(szData[]));
	get_cvar_string("cban_sql_db", szData[3], charsmax(szData[]));

	get_cvar_string("cban_ban_info", szBanInfo, charsmax(szBanInfo));
	get_cvar_string("cban_ban_cfg1", szConfig1, charsmax(szConfig1));
	get_cvar_string("cban_ban_cfg2", szConfig2, charsmax(szConfig2));
	get_cvar_string("cban_ban_cfg3", szConfig3, charsmax(szConfig3));
	get_cvar_string("cban_ban_cfg4", szConfig4, charsmax(szConfig4));
	get_cvar_string("cban_ban_cfg5", szConfig5, charsmax(szConfig5));
	get_cvar_string("cban_ban_cfg6", szConfig6, charsmax(szConfig6));
	get_cvar_string("cban_ban_cfg7", szConfig7, charsmax(szConfig7));
	get_cvar_string("cban_ban_cfg8", szConfig8, charsmax(szConfig8))

	hHookSql = SQL_MakeDbTuple(szData[0], szData[1], szData[2], szData[3]);

	new szError[128], iError, Handle:hConn = SQL_Connect(hHookSql, iError, szError, charsmax(szError));

	if(iError)
	{
		format(szError, charsmax(szError), "SQL Connect Error: %s", szError);

		set_fail_state(szError);

		return;
	}

	new szTemp[512];

	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `banconfig` (\
		`ban_id` int(11) NOT NULL AUTO_INCREMENT,\
		`ban_name` varchar(64) DEFAULT NULL,\
		`ban_time` datetime DEFAULT NULL,\
		`ban_admin` varchar(64) DEFAULT NULL,\
		`ban_reason` varchar(64) DEFAULT NULL,\
		`ban_server` varchar(64) DEFAULT NULL,\
		PRIMARY KEY (`ban_id`))");

	new Handle:hQuery = SQL_PrepareQuery(hConn, szTemp);

	SQL_Execute(hQuery);

	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConn);
}

public plugin_end()
{
	ArrayDestroy(aBannedNames);

	SQL_FreeHandle(hHookSql);
}

public client_putinserver(id)
	if(!is_user_bot(id) && !is_user_hltv(id)) set_task(1.0, "CheckBan", id + TASK_CHECK);

public CheckBan(id)
{
	id -= TASK_CHECK;

	new szName[32], szIP[32], szBannedName[32], szBannedID[10];

	get_user_name(id, szName, charsmax(szName));
	get_user_ip(id, szIP, charsmax(szIP), 1);

	for(new i = 0; i < ArraySize(aBlockedPhrases); i++)
	{
		ArrayGetString(aBlockedPhrases, i, szBannedName, charsmax(szBannedName));

		if(containi(szName, szBannedName) != -1) {
			log_to_file("blocked.log", "Wyrzucono gracza: %s (%s)", szName, szIP);

			set_task(1.0, "Kick", id + TASK_KICK);

			return PLUGIN_CONTINUE;
		}
	}

	for(new i = 0; i < ArraySize(aBannedNames); i++)
	{
		ArrayGetString(aBannedNames, i, szBannedName, charsmax(szBannedName));

		if(equal(szName, szBannedName)) {
			log_to_file("blocked.log", "Wyrzucono gracza: %s (%s)", szName, szIP);

			set_task(1.0, "Kick", id + TASK_KICK);

			return PLUGIN_CONTINUE;
		}
	}

	bInfo[id] = false;

	cmd_execute(id, "exec %s.cfg", szConfig1);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig2);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig3);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig4);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig5);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig6);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig7);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	cmd_execute(id, "exec %s.cfg", szConfig8);
	get_user_info(id, szBanInfo, szBannedID, charsmax(szBannedID));

	if(szBannedID[0])
	{
		CheckFoundID(id, szBannedID);

		return PLUGIN_CONTINUE;
	}

	set_task(1.0, "ClearConsole", id);

	return PLUGIN_CONTINUE;
}
public CheckFoundID(id, szBannedID[])
{
	new szTemp[128], szData[1];

	szData[0] = id;

	formatex(szTemp, charsmax(szTemp), "SELECT ban_id, ban_name, ban_reason, ban_admin FROM `banconfig` WHERE ban_id = %d", str_to_num(szBannedID));
	SQL_ThreadQuery(hHookSql, "CheckFoundID_Handle", szTemp, szData, sizeof(szData));
}

public CheckFoundID_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("banconfig.log", "<Query> Error: %s", szError);

		return;
	}

	new id = szData[0];

	if(!is_user_connected(id) || bInfo[id]) return;

	if(SQL_NumResults(hQuery))
	{
		bInfo[id] = true;

		new szName[33], szReason[33], szAdmin[33];

		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_name"), szName, charsmax(szName));
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_reason"), szReason, charsmax(szReason));
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_admin"), szAdmin, charsmax(szAdmin));

		console_print(id, "[CBAN] ========================================");
		console_print(id, "[CBAN] Zostales zbanowany!");
		console_print(id, "[CBAN] Nick: %s", szName);
		console_print(id, "[CBAN] Powod: %s", szReason);
		console_print(id, "[CBAN] Admin, ktory cie zbanowal: %s", szAdmin);
		console_print(id, "[CBAN] Mozesz to wyjasnic na CS-Reload.pl.");
		console_print(id, "[CBAN] ========================================");

		set_task(1.0, "Kick", id + TASK_KICK);
	}
}

public Kick(id)
{
	id -= TASK_KICK;

	if(is_user_connected(id)) server_cmd("kick #%d ^"Zostales ZBANOWANY!^"", get_user_userid(id));
}

public Quit(id)
{
	id -= TASK_QUIT;

	if(is_user_connected(id)) cmd_execute(id, "quit");
}

public ClearConsole(id)
{
	if(is_user_connected(id) && !bInfo[id])
	{
		cmd_execute(id, "clear");
		set_task(90.0, "PrintIP", id + TASK_IP, .flags="a", .repeat = 3);
	}
}

public PrintIP(id)
{
	id -= TASK_IP;

	if(!is_user_connected(id)) return;

	new szIP[64];
	get_user_ip(0, szIP, charsmax(szIP), 0);
	replace_all(szIP, charsmax(szIP), ":27015", "");

	client_print_color(id, id, "^x04Podoba ci sie serwer? Dodaj IP^x03 %s^x04 do ulubionych!", szIP);
}

public BanPlayer(iAdmin, szReason[])
{
	new iPlayer = iPlayerID[iAdmin];

	if(!is_user_connected(iPlayer))
	{
		client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if(iPlayerUserID[iAdmin] != get_user_userid(iPlayerID[iAdmin]))
	{
		client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Unikalne ID gracza nie zgadza sie z zapisanym!");

		return PLUGIN_HANDLED;
	}

	new szCache[1024], szPlayerName[64], szAdminName[64], szServerName[64];

	get_cvar_string("hostname", szServerName, charsmax(szServerName));
	get_user_name(iAdmin, szAdminName, charsmax(szAdminName));
	get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName));

	mysql_escape_string(szAdminName, szAdminName, charsmax(szAdminName));
	mysql_escape_string(szPlayerName, szPlayerName, charsmax(szPlayerName));

	formatex(szCache, charsmax(szCache), "INSERT into `banconfig` (`ban_name`,`ban_reason`, `ban_admin`, `ban_time`, `ban_server`) \
	values ('%s', '%s', '%s', sysdate(), '%s')", szPlayerName, szReason, szAdminName, szServerName);

	new szError[128], iError, Handle:hConn = SQL_Connect(hHookSql, iError, szError, charsmax(szError));

	if(iError)
	{
		log_to_file("banconfig.log", "Error: %s", szError);

		return PLUGIN_CONTINUE;
	}

	new Handle:hQuery = SQL_PrepareQuery(hConn, szCache);

	if(SQL_Execute(hQuery) == 1)
	{
		if(SQL_GetInsertId(hQuery))
		{
			new szBannedID[32];

			num_to_str(SQL_GetInsertId(hQuery), szBannedID, charsmax(szBannedID));

			cmd_execute(iPlayer, "setinfo %s %s", szBanInfo, szBannedID);
			cmd_execute(iPlayer, "writecfg %s", szConfig1);
			cmd_execute(iPlayer, "writecfg %s", szConfig2);
			cmd_execute(iPlayer, "writecfg %s", szConfig3);
			cmd_execute(iPlayer, "writecfg %s", szConfig4);
			cmd_execute(iPlayer, "writecfg %s", szConfig5);
			cmd_execute(iPlayer, "writecfg %s", szConfig6);
			cmd_execute(iPlayer, "writecfg %s", szConfig7);
			cmd_execute(iPlayer, "writecfg %s", szConfig8);

			set_task(1.0, "Quit", iPlayer + TASK_QUIT);
			set_task(1.1, "Kick", iPlayer + TASK_KICK);

			replace_all(szAdminName, charsmax(szAdminName), "\'", "'");
			replace_all(szPlayerName, charsmax(szPlayerName), "\'", "'");

			client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Gracz zostal zbanowany na config!");

			set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1);
			ShowSyncHudMsg(0, gSyncHud, "Gracz %s zostal zbanowany!^nPowod: %s", szPlayerName, szReason);

			log_to_file("banconfig.log", "Gracz %s zostal zbanowany na config przez admina %s z powodem %s", szPlayerName, szAdminName, szReason);
		}
	}
	else
	{
		SQL_QueryError(hQuery, szError, charsmax(szError));

		log_to_file("banconfig.log", "<Execute Query> Error: %s", szError);

		client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Wystapil blad podczas banowania gracza!");
	}

	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConn);

	return PLUGIN_CONTINUE;
}

public ConfigBanMenu(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		console_print(id, "[CBAN] Brak uprawnien!");

		return PLUGIN_HANDLED;
	}

	new szName[33], szTempID[16], iPlayers, menu = menu_create("\wWybierz\r gracza\w, ktorego chcesz \rzbanowac na config\w:", "ConfigBanMenu_Handle");

	for(new iPlayer = 1; iPlayer <= iMaxPlayers; iPlayer++)
	{
		if(iPlayer == id || !is_user_connected(iPlayer) || is_user_bot(iPlayer) || is_user_hltv(iPlayer)) continue;
		{
			iPlayers++;

			get_user_name(iPlayer, szName, charsmax(szName));

			formatex(szTempID, charsmax(szTempID), "%i#%i", iPlayer, get_user_userid(iPlayer));

			menu_additem(menu, szName, szTempID);
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	if(!iPlayers) client_print_color(id, id, "^x03[CBAN]^x01 Na serwerze nie ma gracza, ktorego moglbys zbanowac!");

	return PLUGIN_HANDLED;
}

public ConfigBanMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new szData[16], szTempID[16], szTempUserID[16], iAccess, iCallback;

	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	split(szData, szTempID, charsmax(szTempID), szTempUserID, charsmax(szTempUserID), "#");

	iPlayerID[id] = str_to_num(szTempID);
	iPlayerUserID[id] = str_to_num(szTempUserID);

	if(!is_user_connected(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if(iPlayerUserID[id] != get_user_userid(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Unikalne ID gracza nie zgadza sie z zapisanym!");

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	new menu = menu_create("\wWybierz \rpowod \wbana:", "ConfigBanMenu_Handle2");

	for(new i = 0; i < sizeof(szBanReasons); i++) menu_additem(menu, szBanReasons[i]);

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ConfigBanMenu_Handle2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if(iPlayerUserID[id] != get_user_userid(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Unikalne ID gracza nie zgadza sie z zapisanym!");

		return PLUGIN_HANDLED;
	}

	BanPlayer(id, szBanReasons[item]);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public ConfigBan(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		console_print(id, "[CBAN] Brak uprawnien!");

		return PLUGIN_HANDLED;
	}

	if(read_argc() < 2)
	{
		console_print(id, "[CBAN] Podaj wszystkie argumenty!");

		return PLUGIN_HANDLED;
	}

	new szReason[64], szPlayer[32], iPlayer;

	read_argv(1, szPlayer, charsmax(szPlayer));
	read_argv(2, szReason, charsmax(szReason));

	iPlayer = cmd_target(id, szPlayer, 0);

	if(!iPlayer)
	{
		console_print(id, "[CBAN] Nie znaleziono podanego gracza!");

		return PLUGIN_HANDLED;
	}

	iPlayerID[id] = iPlayer;

	if(!szReason[0])
	{
		console_print(id, "[CBAN] Nie podano powodu bana!");

		return PLUGIN_HANDLED;
	}

	BanPlayer(id, szReason);

	return PLUGIN_HANDLED;
}

public ConfigUnbanMenu(id)
{
	new szTemp[128], szData[1];

	szData[0] = id;

	formatex(szTemp, charsmax(szTemp), "SELECT ban_id, ban_name, ban_reason FROM `banconfig` ORDER BY ban_time DESC LIMIT 50");
	SQL_ThreadQuery(hHookSql, "ConfigUnbanMenu_Handle", szTemp, szData, sizeof(szData));

	return PLUGIN_HANDLED;
}

public ConfigUnbanMenu_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iSize)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_to_file("banconfig.log", "<Query> Error: %s", szError);

		return PLUGIN_HANDLED;
	}

	new id = szData[0];

	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	new szMenu[128], szBanData[128], szReason[64], szName[64], szBanID[10], iPlayers, menu = menu_create("\wWybierz\r gracza\w zbanowanego na config, ktorego chcesz \rodbanowac\w:", "ConfigUnbanMenu_Handle2");

	while(SQL_MoreResults(hQuery))
	{
		iPlayers++;

		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_id"), szBanID, charsmax(szBanID));
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_name"), szName, charsmax(szName));
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ban_reason"), szReason, charsmax(szReason));

		formatex(szMenu, charsmax(szMenu), "\y%s\w - Powod:\r %s", szName, szReason);
		formatex(szBanData, charsmax(szBanData), "%s#%s", szName, szBanID);

		menu_additem(menu, szMenu, szBanData, 0);

		SQL_NextRow(hQuery);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	if(!iPlayers) client_print_color(id, id, "^x03[CBAN]^x01 W bazie nie ma gracza, ktorego moglbys odbanowac!");

	return PLUGIN_HANDLED;
}

public ConfigUnbanMenu_Handle2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new szData[64], szName[64], szBanID[10], iAccess, iCallback;

	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	strtok(szData, szName, charsmax(szName), szBanID, charsmax(szBanID), '#');

	UnbanPlayer(id, szBanID, szName);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public ConfigUnban(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		console_print(id, "[CBAN] Brak uprawnien!");

		return PLUGIN_HANDLED;
	}

	if(read_argc() < 2)
	{
		console_print(id, "[CBAN] Podaj wszystkie argumenty!");

		return PLUGIN_HANDLED;
	}

	new szName[64], szBanID[10];

	read_argv(1, szBanID, charsmax(szBanID));
	read_argv(2, szName, charsmax(szName));

	if(!szBanID[0])
	{
		console_print(id, "[CBAN] Podaj ID bana!");

		return PLUGIN_HANDLED;
	}

	if(!szName[0])
	{
		console_print(id, "[CBAN] Podaj nick bana!");

		return PLUGIN_HANDLED;
	}

	UnbanPlayer(id, szBanID, szName);

	return PLUGIN_HANDLED;
}

public UnbanPlayer(iAdmin, szBanID[], szName[])
{
	new szCache[256], szPlayerName[64], szAdminName[64];

	get_user_name(iAdmin, szAdminName, charsmax(szAdminName));

	mysql_escape_string(szName, szPlayerName, charsmax(szPlayerName));

	formatex(szCache, charsmax(szCache), "DELETE FROM `banconfig` WHERE `ban_id` = '%i' AND `ban_name` = '%s'", str_to_num(szBanID), szPlayerName);

	new szError[128], iError, Handle:hConn = SQL_Connect(hHookSql, iError, szError, charsmax(szError));

	if(iError)
	{
		log_to_file("banconfig.log", "Error: %s", szError);

		return PLUGIN_CONTINUE;
	}

	new Handle:hQuery = SQL_PrepareQuery(hConn, szCache);

	if(SQL_Execute(hQuery) == 1)
	{
		if(SQL_AffectedRows(hQuery) > 0)
		{
			console_print(iAdmin, "[CBAN] Gracz zostal pomyslnie odbanowany!");

			client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Gracz zostal pomyslnie^x04 odbanowany^x01!");

			log_to_file("banconfig.log", "Admin %s odbanowal gracza %s zbanowanego na config.", szAdminName, szName);
		}
		else
		{
			console_print(iAdmin, "[CBAN] Nie znaleziono w bazie gracza o podanym nicku lub bana o podanym ID!");

			client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Nie znaleziono w bazie gracza o podanym nicku lub bana o podanym ID!");
		}
	}
	else
	{
		SQL_QueryError(hQuery, szError, charsmax(szError));

		log_to_file("banconfig.log", "<Execute Query> Error: %s", hQuery);

		client_print(iAdmin, print_chat, "[CBAN] Wystapil blad podczas zdejmowania bana z gracza!");
	}

	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConn);

	return PLUGIN_CONTINUE;
}

public NameBanMenu(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		console_print(id, "[NBAN] Brak uprawnien!");

		return PLUGIN_HANDLED;
	}

	new szName[33], szTempID[10], iPlayers, menu = menu_create("\wWybierz\r gracza\w, ktorego chcesz \rzbanowac na nick\w:", "NameBanMenu_Handle");

	for(new iPlayer = 1; iPlayer <= iMaxPlayers; iPlayer++)
	{
		if(iPlayer != id && is_user_connected(iPlayer) && !is_user_bot(iPlayer) && !is_user_hltv(iPlayer))
		{
			iPlayers++;

			get_user_name(iPlayer, szName, charsmax(szName));
			formatex(szTempID, charsmax(szTempID), "%i#%i", iPlayer, get_user_userid(iPlayer));
			menu_additem(menu, szName, szTempID, 0);
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	if(!iPlayers) client_print_color(id, id, "^x03[CBAN]^x01 Na serwerze nie ma gracza, ktorego moglbys zbanowac!");

	return PLUGIN_HANDLED;
}

public NameBanMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new szData[10], szTempID[5], szTempUserID[5], iAccess, iCallback;

	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	split(szData, szTempID, charsmax(szTempID), szTempUserID, charsmax(szTempUserID), "#");

	iPlayerID[id] = str_to_num(szTempID);
	iPlayerUserID[id] = str_to_num(szTempUserID);

	if(!is_user_connected(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if(iPlayerUserID[id] != get_user_userid(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Unikalne ID gracza nie zgadza sie z zapisanym!");

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	new menu = menu_create("\wWybierz \rpowod \wbana:", "ConfigBanMenu_Handle2");

	for(new i = 0; i < sizeof(szBanReasons); i++) menu_additem(menu, szBanReasons[i]);

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public NameBanMenu_Handle2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if(!is_user_connected(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if(iPlayerUserID[id] != get_user_userid(iPlayerID[id]))
	{
		client_print_color(id, id, "^x03[CBAN]^x01 Unikalne ID gracza nie zgadza sie z zapisanym!");

		return PLUGIN_HANDLED;
	}

	BanName(id, szBanReasons[item]);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public NameBan(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		console_print(id, "[NBAN] Brak uprawnien!");

		return PLUGIN_HANDLED;
	}

	if(read_argc() < 2)
	{
		console_print(id, "[NBAN] Podaj wszystkie argumenty!");

		return PLUGIN_HANDLED;
	}

	new szReason[64], szPlayer[32], iPlayer;

	read_argv(1, szPlayer, charsmax(szPlayer));
	read_argv(2, szReason, charsmax(szReason));

	iPlayer = cmd_target(id, szPlayer, 0);

	if(!iPlayer)
	{
		console_print(id, "[NBAN] Nie znaleziono podanego gracza!");

		return PLUGIN_HANDLED;
	}

	iPlayerID[id] = iPlayer;

	if(!szReason[0])
	{
		console_print(id, "[NBAN] Nie podano powodu bana!");

		return PLUGIN_HANDLED;
	}

	BanName(id, szReason);

	return PLUGIN_HANDLED;
}

public BanName(iAdmin, szReason[])
{
	if(!is_user_connected(iPlayerID[iAdmin]))
	{
		client_print_color(iAdmin, iAdmin, "^x03[CBAN]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	new szPlayerName[32], szAdminName[32];

	get_user_name(iAdmin, szAdminName, charsmax(szAdminName));
	get_user_name(iPlayerID[iAdmin], szPlayerName, charsmax(szPlayerName));

	ArrayPushString(aBannedNames, szPlayerName);

	set_task(1.0, "Quit", iPlayerID[iAdmin] + TASK_QUIT);

	set_task(1.1, "Kick", iPlayerID[iAdmin] + TASK_KICK);

	client_print_color(iAdmin, iAdmin, "^x03[NBAN]^x01 Gracz zostal zbanowany na nick!");

	set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1);
	ShowSyncHudMsg(0, gSyncHud, "Gracz %s zostal zbanowany!^nPowod: %s", szPlayerName, szReason);

	log_to_file("banconfig.log", "Gracz %s zostal zbanowany na nick przez admina %s z powodem %s.", szPlayerName, szAdminName, szReason);

	return PLUGIN_CONTINUE;
}

stock cmd_execute(id, const szText[], any:...)
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szText) + 2);
	write_byte(10);
	write_string(szText);
	message_end();

	#pragma unused szText

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}

stock mysql_escape_string(const szSource[], szDest[], iLen)
{
	copy(szDest, iLen, szSource);

	replace_all(szDest, iLen, "\\", "\\\\");
	replace_all(szDest, iLen, "\", "\\");
	replace_all(szDest, iLen, "\0", "\\0");
	replace_all(szDest, iLen, "\n", "\\n");
	replace_all(szDest, iLen, "\r", "\\r");
	replace_all(szDest, iLen, "\x1a", "\Z");
	replace_all(szDest, iLen, "'", "\'");
	replace_all(szDest, iLen, "`", "\`");
	replace_all(szDest, iLen, "^"", "\^"");
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/