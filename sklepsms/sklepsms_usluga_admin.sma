#include <amxmodx>
#include <amxmisc>
#include <sklep_sms>
#include <sqlx>

#define PLUGIN "Sklep-SMS: Usluga Admin"
#define AUTHOR "O'Zone"

#define LOG_FILE "addons/amxmodx/logs/admins_service.log"

new const service_id[MAX_ID] = "admin";

new sName[33][64], bool:bAdmin[33], bool:bSQL, Handle:hSqlHook;

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
{
	set_task(0.1, "sql_init");

	ss_register_service(service_id);
}

public plugin_end()
	SQL_FreeHandle(hSqlHook);

public sql_init()
{
	new sCache[256], sHost[32], sUser[32], sPass[32], sDB[32];

	get_cvar_string("sklepsms_sql_host", sHost, charsmax(sHost));
	get_cvar_string("sklepsms_sql_user", sUser, charsmax(sUser));
	get_cvar_string("sklepsms_sql_pass", sPass, charsmax(sPass));
	get_cvar_string("sklepsms_sql_db", sDB, charsmax(sDB));

	hSqlHook = SQL_MakeDbTuple(sHost, sUser, sPass, sDB);

	formatex(sCache, charsmax(sCache), "CREATE TABLE IF NOT EXISTS ss_admins (id INT(11), name VARCHAR(64), steamid VARCHAR(64), password VARCHAR(64), server INT(11), date INT(11), type VARCHAR(33), PRIMARY KEY (id))");

	SQL_ThreadQuery(hSqlHook, "sql_init_handle", sCache);
}

public sql_init_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState)
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Create - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Create - Query failed. [%d] %s", iError, sError);

		bSQL = false;

		return PLUGIN_CONTINUE;
	}

	bSQL = true;

	return PLUGIN_CONTINUE;
}

public client_connect(id)
{
	bAdmin[id] = false;

	get_user_name(id, sName[id], charsmax(sName[]));

	mysql_escape_string(sName[id], sName[id], charsmax(sName[]));

	set_task(0.1, "check_list", id);
}

public check_list(id)
{
	if(!bSQL)
	{
		set_task(0.1, "check_list", id);

		return;
	}

	new sCache[256], sData[1];

	sData[0] = id;

	formatex(sCache, charsmax(sCache), "SELECT a.date as date, a.type as type, b.name as server FROM ss_admins a JOIN ss_servers b ON a.server = b.id WHERE a.name = '%s'", sName[id]);

	SQL_ThreadQuery(hSqlHook, "check_list_handle", sCache, sData, 1);
}

public check_list_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState)
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Load Admin - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Load Admin - Query failed. [%d] %s", iError, sError);

		return PLUGIN_CONTINUE;
	}

	new sServer[64], sServerName[128], iDate, iType, id = sData[0];

	while(SQL_MoreResults(hQuery))
	{
		iDate = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "date"));

		iType = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "type"));

		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "server"), sServer, charsmax(sServer));

		get_cvar_string("hostname", sServerName, charsmax(sServerName));

		if(containi(sServerName, sServer) != -1)
		{
			if(!iDate)
			{
				bAdmin[id] = true;

				return PLUGIN_CONTINUE;
			}

			if(iType)
			{
				bAdmin[id] = true;

				return PLUGIN_CONTINUE;
			}
		}

		SQL_NextRow(hQuery);
	}

	return PLUGIN_CONTINUE;
}

public ss_service_bought(id, amount)
{
	new sCache[256], sIP[64], sData[1];

	sData[0] = id;

	get_cvar_string("ip", sIP, charsmax(sIP));

	formatex(sCache, charsmax(sCache), "SET @t = UNIX_TIMESTAMP() + 2592000; UPDATE ss_admins a SET a.date = @t JOIN ss_servers b ON a.server = b.id WHERE a.name = '%s' b.ip = '%s'", sName[id], sIP);

	log_to_file(LOG_FILE, sCache);

	SQL_ThreadQuery(hSqlHook, "query_handle", sCache, sData, 1);
}

public query_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState)
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Save - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Save - Query failed. [%d] %s", iError, sError);
	}

	return PLUGIN_CONTINUE;
}

public ss_service_addingtolist(id, flags[])
{
	if(!bAdmin[id]) return ITEM_DISABLED;

	return ITEM_ENABLED;
}

stock mysql_escape_string(const szSource[], szDest[], iLen)
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