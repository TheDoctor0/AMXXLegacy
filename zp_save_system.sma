#include <amxmodx>
#include <sqlx>
#include <fakemeta>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

native zp_level_set(id, level);
native zp_exp_set(id, exp);
native zp_ammopacks_set(id, ap);
native zp_extra_knife_set(id, knife);
native zp_tattoo_set(id, tattoo);
native zp_class_human_set_next(id, class);
native zp_class_zombie_set_next(id, class);
native zp_hplvl_set(id, level);
native zp_aplvl_set(id, level);
native zp_gravitylvl_set(id, level);
native zp_damagelvl_set(id, level);

native zp_level_get(id);
native zp_exp_get(id);
native zp_ammopacks_get(id);
native zp_extra_knife_get(id);
native zp_tattoo_get(id);
native zp_class_human_get_current(id);
native zp_class_zombie_get_current(id);
native zp_hplvl_get(id);
native zp_aplvl_get(id);
native zp_gravitylvl_get(id);
native zp_damagelvl_get(id);

native zp_show_weapon_menu(id);

new Handle:hookSql;
new g_name[33][36];
new bool:g_loaded[33];
new g_MaxPlayers;

public plugin_init() 
{
	register_plugin("ZP Save System", "1.0", "O'Zone");
	
	register_cvar("zp_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_user", "310529", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_pass", "IzQsAjTnjuPnJu41", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_db", "310529_zp", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	register_forward(FM_ClientDisconnect, "client_disconnect");
	
	register_message(SVC_INTERMISSION, "MsgIntermission");
	
	g_MaxPlayers = get_maxplayers();
	
	sql_init();
}

public plugin_natives()
{
	register_library("zp50_savesystem");
	register_native("zp_save", "native_zp_save");
}

public plugin_end()
	SQL_FreeHandle(hookSql);

public sql_init()
{
	new db_data[4][64];
	get_cvar_string("zp_sql_host", db_data[0], 63); 
	get_cvar_string("zp_sql_user", db_data[1], 63); 
	get_cvar_string("zp_sql_pass", db_data[2], 63); 
	get_cvar_string("zp_sql_db", db_data[3], 63);  
	
	hookSql = SQL_MakeDbTuple(db_data[0], db_data[1], db_data[2], db_data[3]);

	new error, szError[128];
	new Handle:hConn = SQL_Connect(hookSql, error, szError, 127);
	
	if(error)
	{
		log_amx("Error: %s", szError);
		return;
	}
	
	new szTemp[1024];
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `zp_save_system` (name VARCHAR(35), level INT (11), exp INT (11), ap INT (11), knife INT (11), ");
	add(szTemp, charsmax(szTemp), "tattoo INT (11), hclass INT (11), zclass INT (11), hplvl INT (11), aplvl INT (11), gravitylvl INT (11), damagelvl INT (11), PRIMARY KEY(name));");

	new Handle:query = SQL_PrepareQuery(hConn, szTemp);
	SQL_Execute(query);
	SQL_FreeHandle(query);
	SQL_FreeHandle(hConn);
}

public client_putinserver(id)
{
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		g_loaded[id] = false;
		load_sql(id);
	}
}

public client_disconnected(id)
{ 
	if(!is_user_bot(id) && !is_user_hltv(id)) 
		save_stats(id, 1);
}

public load_sql(id)
{
	get_user_name(id, g_name[id], charsmax(g_name[]));
	replace_all(g_name[id], 35, "'", "\'" );
	replace_all(g_name[id], 35, "`", "\`" );  
	replace_all(g_name[id], 35, "\\", "\\\\" );
	replace_all(g_name[id], 35, "^0", "\0");
	replace_all(g_name[id], 35, "^n", "\n");
	replace_all(g_name[id], 35, "^r", "\r");
	replace_all(g_name[id], 35, "^x1a", "\Z"); 
	
	new data[1], szTemp[256];
	data[0] = id;
		
	formatex(szTemp, 255, "SELECT * FROM `zp_save_system` WHERE name = '%s'", g_name[id]);
	SQL_ThreadQuery(hookSql, "load_stats", szTemp, data, 1);
}

public load_stats(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("<Query> Error: %s", error);
		return;
	}
	
	new id = data[0];
	
	if(!is_user_connected(id))
		return;
	
	if(SQL_MoreResults(query))
	{
		new stats[11];
		
		stats[0] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
		stats[1] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "exp"));
		stats[2] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "ap"));
		stats[3] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "knife"));
		stats[4] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "tattoo"));
		stats[5] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hclass"));
		stats[6] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "zclass"));
		stats[7] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "hplvl"));
		stats[8] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "aplvl"));
		stats[9] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "gravitylvl"));
		stats[10] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "damagelvl"));
		
		natives_call(id, stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7], stats[8], stats[9], stats[10]);
	}
	else
	{
		new szTemp[256];
		formatex(szTemp, 255, "INSERT INTO `zp_save_system` (`name`, `level`, `exp`, `ap`, `knife`, `tattoo`, `hclass`, `zclass`, `hplvl`, `aplvl`, `gravitylvl`, `damagelvl`) VALUES ('%s', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0')", g_name[id]);
		SQL_ThreadQuery(hookSql, "load_ignore", szTemp);
		natives_call(id, 1, 0, get_cvar_num("zp_starting_ammo_packs"), 0, 0, 0, 0, 0, 0, 0, 0);
	}
	
	g_loaded[id] = true;
	
	if(is_user_alive(id))
		zp_show_weapon_menu(id);
}

public load_ignore(FailState, Handle:Query, Error[], ErrCode, Data[], Size)
{
	if(FailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/zp_save_system.txt", "Save/Load - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		return;
	}
}

stock natives_call(id, level = 1, exp = 0, ap = 0, knife = 0, tattoo = 0, hclass = 0, zclass = 0, hplvl = 0, aplvl = 0, gravitylvl = 0, damagelvl = 0)
{
	zp_level_set(id, level);
	zp_exp_set(id, exp);
	zp_ammopacks_set(id, ap);
	zp_extra_knife_set(id, knife);
	zp_tattoo_set(id, tattoo);
	zp_class_human_set_next(id, hclass);
	zp_class_zombie_set_next(id, zclass);
	zp_hplvl_set(id, hplvl);
	zp_aplvl_set(id, aplvl);
	zp_gravitylvl_set(id, gravitylvl);
	zp_damagelvl_set(id, damagelvl);
}

public save_stats(id, type)
{
	if(!g_loaded[id])
		return;
		
	if(type)
		g_loaded[id] = false;
		
	new stats[11];

	stats[0] = zp_level_get(id);
	stats[1] = zp_exp_get(id);
	stats[2] = zp_ammopacks_get(id);
	stats[3] = zp_extra_knife_get(id);
	stats[4] = zp_tattoo_get(id);
	stats[5] = zp_class_human_get_current(id);
	stats[6] = zp_class_zombie_get_current(id);
	stats[7] = zp_hplvl_get(id);
	stats[8] = zp_aplvl_get(id);
	stats[9] = zp_gravitylvl_get(id);
	stats[10] = zp_damagelvl_get(id);
	
	new szTemp[256];
	formatex(szTemp, 255, "UPDATE `zp_save_system` SET level=%d, exp=%d, ap=%d, knife=%d, tattoo=%d, hclass=%d, zclass=%d, hplvl=%d, aplvl=%d, gravitylvl=%d, damagelvl=%d WHERE name='%s'", 
	stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7], stats[8], stats[9], stats[10], g_name[id]);
	
	switch(type)
	{
		case 0, 1: SQL_ThreadQuery(hookSql, "load_ignore", szTemp);
		case 2:
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(hookSql, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file("addons/amxmodx/logs/zp_save_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szTemp);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file("addons/amxmodx/logs/zp_save_system.txt", "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
				SQL_FreeHandle(Query);
				SQL_FreeHandle(SqlConnection);
				return;
			}
	
			SQL_FreeHandle(Query);
			SQL_FreeHandle(SqlConnection);
		}
	}
}

public zp_fw_core_infect_post(infected, infector)
	save_stats(infector, 0);

public zp_fw_items_select_post(id, itemid)
	save_stats(id, 0);

public native_zp_save(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	save_stats(id, 0);
	
	return true;
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
		
		save_stats(id, 2);
	}
	
	return PLUGIN_CONTINUE;
}