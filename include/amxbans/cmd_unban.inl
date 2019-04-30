#if defined _cmdunban_included
    #endinput
#endif

#define _cmdunban_included

public cmdUnBan(id, level, cid) 
{
	if(!cmd_access( id, level, cid, 2))
	{
		return PLUGIN_HANDLED
	}
	
	new text[128]
	read_args(text, 127)
	trim(text)
	remove_quotes(text)
	mysql_escape_string(text, 127)
	
	new szQuery[512]
	formatex(szQuery, 511, "SELECT `bid`, `player_nick`, `player_id` FROM `%s%s` WHERE (`player_ip` = '%s' OR `player_id` = '%s') AND `expired` = '0' LIMIT 1;", g_dbPrefix, TBL_BANS, text, text)
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdUnBan] Trying to unban a player: %s", text)
	}
	
	new data[1]
	data[0] = id

	return SQL_ThreadQuery(g_SqlX, "HandleSelectBan", szQuery, data, 1)
}

public HandleNullRoute(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if(failstate)
	{
		return SQL_Error(query, error, errornum, failstate)
	}
	
	return SQL_FreeHandle(query)
}

public HandleSelectBan(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if(failstate)
	{
		return SQL_Error(query, error, errornum, failstate)
	} 
	else 
	{
		new id = data[0]
		
		if(!SQL_NumResults(query)) 
		{
			SQL_FreeHandle(query)
			console_print(id, "[AMXBans] %L", LANG_PLAYER, "PLAYER_NOT_FOUND", g_ident)
		} 
		else 
		{
			if(get_pcvar_num(pcvar_debug) >= 1)
			{
				log_amx("[AMXBans HandleSelectBan] Player found, trying to unban")
			}
			
			new iBanId = SQL_ReadResult(query, 0)
			
			new szQuery[512]
			
#if defined UNBAN_GAME_DEL
			
			formatex(szQuery, 511, "DELETE FROM `%s%s` WHERE `expired` = '0' AND `bid` = '%d' LIMIT 1;", g_dbPrefix, TBL_BANS, iBanId)
			
#else

			formatex(szQuery, 511, "UPDATE `%s%s` SET `expired` = '1' WHERE `bid` = '%d';", g_dbPrefix, TBL_BANS, iBanId)
			
#endif
			
			SQL_ThreadQuery(g_SqlX, "HandleNullRoute", szQuery)
			
			new szAdminIp[16], szAdminName[64] = "Server"
			get_user_ip(id, szAdminIp, 15, 1)
			if(id > 0) get_user_name(id, szAdminName, 63)
			
			new szName[64], szSteamId[64]
			SQL_ReadResult(query, 1, szName, 31)
			SQL_ReadResult(query, 2, szSteamId, 33)
			
			mysql_escape_string(szName, 63)
			mysql_escape_string(szSteamId, 63)
			mysql_escape_string(szAdminName, 63)
			
			SQL_FreeHandle(query)
			
#if defined UNBAN_GAME_DEL
			
			formatex(szQuery, 511, "INSERT INTO `%s_logs` VALUES (NULL, '%d', '%s', '%s', 'In-Game Unban', 'Deleted ban: ID %d (<%s><%s>)')",
				g_dbPrefix, get_systime(get_pcvar_num(pcvar_offset)), szAdminIp, szAdminName, iBanId, szName, szSteamId)
				
#else
			
			formatex(szQuery, 511, "INSERT INTO `%s_logs` VALUES (NULL,'%d','%s', '%s', 'In-Game Unban', 'Set expire ban: ID %d (<%s><%s>)')",
				g_dbPrefix, get_systime(get_pcvar_num(pcvar_offset)), szAdminIp, szAdminName, iBanId, szName, szSteamId)
				
#endif
			
			SQL_ThreadQuery(g_SqlX, "HandleNullRoute", szQuery)
			
			console_print(id, "[AMXBans] ^"%s^" <%s> has been successfully unbanned", szName, szSteamId)
		}
	}
	
	return PLUGIN_HANDLED
}