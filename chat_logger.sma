#include <amxmodx>
#include <sqlx>

#define PLUGIN "Chat Logger"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new Handle:hSqlTuple, szServer[32];

enum
{
	SAY_TEAM,
	SAY,
	SAY_ADMIN,
	SAY_HUD
}

new const szBlock[][] = 
{
	"timeleft", "nextmap", "thetime", "tl"
};

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("chat_logger_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("chat_logger_user", "510128", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("chat_logger_pass", "xvQ5CusRVCVzj83aruWk", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("chat_logger_base", "510128_chat", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("chat_logger_server", "CoDMod", FCVAR_SPONLY|FCVAR_PROTECTED);

	register_clcmd("say", "LogMessage");
	register_clcmd("say_team", "LogMessage");
}

public plugin_cfg()
{
	new szHost[32], szUser[32], szPass[32], szDatabase[32];
	
	get_cvar_string("chat_logger_host", szHost, charsmax(szHost));
	get_cvar_string("chat_logger_user", szUser, charsmax(szUser));
	get_cvar_string("chat_logger_pass", szPass, charsmax(szPass));
	get_cvar_string("chat_logger_base", szDatabase, charsmax(szDatabase));
	get_cvar_string("chat_logger_server", szServer, charsmax(szServer));
	
	hSqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
	
	if(hSqlTuple == Empty_Handle) set_fail_state("Nie mozna utworzyc uchwytu do polaczenia.");
	
	new iError, szError[128], Handle:hConn = SQL_Connect(hSqlTuple, iError, szError, charsmax(szError));
	
	if(iError)
	{
		log_to_file("chat_logger.log", "Error: %s", szError);
		
		return;
	}
	
	new szTemp[1024];
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `server_chat` (\
		`id` int(10) NOT NULL auto_increment,\
		`server` varchar(20) collate utf8_polish_ci NOT NULL,\
		`nick` varchar(64) collate utf8_polish_ci NOT NULL,\
		`sid` varchar(64) collate utf8_polish_ci NOT NULL,\
		`ip` varchar(20) collate utf8_polish_ci NOT NULL,\
		`msg` varchar(192) collate utf8_polish_ci NOT NULL,\
		`ranga` int(1) NOT NULL,\
		`team` int(1) NOT NULL,\
		`data` int(15) NOT NULL,\
		`type` int(1) NOT NULL,\
		PRIMARY KEY  (`id`))");

	new Handle:hQuery = SQL_PrepareQuery(hConn, szTemp);
	
	SQL_Execute(hQuery);
	
	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConn);
}

public plugin_end()
	SQL_FreeHandle(hSqlTuple);

public LogMessage(id) 
{
	new szTemp[512], szMessage[192], szName[33], szAuth[33], szIP[20], szCmd[9], iType;
	
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuth, charsmax(szAuth));
	get_user_ip(id, szIP, charsmax(szIP), 1);
	
	read_args(szMessage, charsmax(szMessage));
	read_argv(0, szCmd, charsmax(szCmd));

	remove_quotes(szMessage);
	trim(szMessage);
	
	if(szMessage[0] == '/' || !szMessage[0] || is_blocked(szMessage)) return;
	
	mysql_escape_string(szMessage, szMessage, charsmax(szMessage));
	mysql_escape_string(szName, szName, charsmax(szName));
	
	if(!szCmd[3])
	{
		if(szMessage[0] == '@') iType = SAY_HUD;
		else iType = SAY;
	}
	else
	{
		if(szMessage[0] == '@') iType = SAY_ADMIN;
		else iType = SAY_TEAM;
	}
	
	formatex(szTemp, charsmax(szTemp), "INSERT INTO `server_chat` VALUES (NULL, '%s', '%s', '%s', '%s', '%s', %d, %d, UNIX_TIMESTAMP(), %d);", szServer, szName, szAuth, szIP, szMessage, (get_user_flags(id) & ADMIN_LEVEL_H) ? ((get_user_flags(id) & ADMIN_BAN) ? 2 : 1) : 0, get_user_team(id), iType);
	SQL_ThreadQuery(hSqlTuple, "HandleIgnore", szTemp);
}

public HandleIgnore(iFailState, Handle:hQuery, szError[], iError, szData[], iSize) 
{
	if(iFailState != TQUERY_SUCCESS) 
	{
		log_to_file("chat_logger.log", "SQL Insert error (%i): %s", iError, szError);
		
		return;
	}
}

stock is_blocked(const szText[]) 
{
	for(new i = 0; i < sizeof(szBlock); i++) if(equali(szText, szBlock[i])) return true;
	
	return false;
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
