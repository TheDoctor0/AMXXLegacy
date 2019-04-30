#if defined _cmdban_included
    #endinput
#endif

#define _cmdban_included

#include <amxmodx>
#include <sqlx>

public cmdMenuBan(id) 
{
	new pid, bantime, bantype[3], banip[22], banname[32], bansteamid[34], banreason[128]
	
	pid = banData[id][banPlayer]
	bantime = banData[id][banTime]
	copy(bantype, 2, banData[id][banType])
	copy(banip, 21, banData[id][banIp])
	copy(banname, 31, banData[id][banName])
	copy(bansteamid, 33, banData[id][banSteamid])
	copy(banreason, 127, banData[id][banReason])
	
	if(get_user_state(pid, PDATA_BEING_BANNED)) 
	{
		return ColorChat(id, RED, "%s %L", PREFIX, id, "BLOCKING_DOUBLEBAN", banname)
	}
	
	add_user_state(pid, PDATA_BEING_BANNED)
	
	if(!get_ban_type(bantype, 127, bansteamid, banip)) 
	{
		log_amx("[AMXBans ERROR cmdMenuBan] Steamid / IP Invalid! Bantype: <%s> | Authid: <%s> | IP: <%s>", bantype, bansteamid, banip)
		return remove_user_state(pid, PDATA_BEING_BANNED)
	}
	
	if(get_pcvar_num(pcvar_debug) >= 2) 
	{
		log_amx("[AMXBans cmdMenuBan %d] %d | %s | %s | %s | %s (%d min)", id, pid, banname, bansteamid, banip, banreason, bantime)
	}
	
	new pquery[512]
	
	if(equal(bantype, "S")) 
	{
		formatex(pquery, 511, "SELECT `player_id` FROM `%s%s` WHERE `player_id` = '%s' AND `ban_type` = 'S' AND `expired` = '0';", g_dbPrefix, TBL_BANS, bansteamid)
		if(get_pcvar_num(pcvar_debug) >= 2)
		{
			log_amx("[AMXBans cmdMenuBan] Banned a player by SteamID")
		}
	} 
	else 
	{
		formatex(pquery, 511, "SELECT `player_ip` FROM `%s%s` WHERE `player_ip` = '%s' AND `ban_type` = 'SI' AND `expired` = '0';", g_dbPrefix, TBL_BANS, banip)
		if(get_pcvar_num(pcvar_debug) >= 2)
		{
			log_amx("[AMXBans cmdMenuBan] Banned a player by IP")
		}
	}
	
	new data[256]
	format_ban_data(data, id, pid, bantime, bantype, banip, banname, bansteamid, banreason)
	
	return SQL_ThreadQuery(g_SqlX, "_cmdMenuBan", pquery, data, 255)
}

public _cmdMenuBan(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new id, pid, bantime, nums[3], bantype[3], banip[22], banname[32], bansteamid[34], banreason[128]
	parse_ban_data(data, nums, bantype, banip, banname, bansteamid, banreason)
	
	id = nums[0]
	pid = nums[1]
	bantime = nums[2]

	if(failstate)
	{
		remove_user_state(pid, PDATA_BEING_BANNED)
		return SQL_Error(query, error, errornum, failstate)
	}
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdMenuBan function 2] Playerid: %d", pid)
	}
	
	if(SQL_NumResults(query)) 
	{
		SQL_FreeHandle(query)
		ColorChat(id, RED, "%s %L", PREFIX, id, "ALREADY_BANNED")
		return remove_user_state(pid, PDATA_BEING_BANNED)
	}
	
	new admin_nick[64]
	mysql_get_username_safe(id, admin_nick, 63)
	
	new player_nick[64]
	copy(player_nick, 63, banname)
	mysql_escape_string(player_nick, 63)
	
	new server_name[256]
	mysql_get_servername_safe(server_name, 255)
	
	if(get_pcvar_num(pcvar_add_mapname)) 
	{
		new mapname[32]
		get_mapname(mapname, 31)
		format(server_name, 255, "%s (%s)", server_name, mapname)
	}
	
	new pquery[1024], len
	
#if defined SET_NAMES_UTF8

	len = format(pquery, 1023, "SET NAMES UTF8; INSERT INTO `%s%s` (`player_id`, `player_ip`, `player_nick`, `admin_ip`, `admin_id`, `admin_nick`, `ban_type`, `ban_reason`, `cs_ban_reason`, `ban_created`, `ban_length`, `server_name`, `server_ip`, `expired`) ", g_dbPrefix, TBL_BANS)
	len += format(pquery[len], 1023 - len, "VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(NOW()), '%d', '%s', '%s:%s', '0');", bansteamid, banip, player_nick, playerData[id][playerIp], playerData[id][playerSteamid], admin_nick, bantype, banreason, "See banlist", bantime, server_name, g_ip, g_port)
	
#else

	len = format(pquery, 1023, "INSERT INTO `%s%s` (`player_id`, `player_ip`, `player_nick`, `admin_ip`, `admin_id`, `admin_nick`, `ban_type`, `ban_reason`, `cs_ban_reason`, `ban_created`, `ban_length`, `server_name`, `server_ip`, `expired`) ", g_dbPrefix, TBL_BANS)
	len += format(pquery[len], 1023 - len, "VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(NOW()), '%d', '%s', '%s:%s', '0');", bansteamid, banip, player_nick, playerData[id][playerIp], playerData[id][playerSteamid], admin_nick, bantype, banreason, banreason, bantime, server_name, g_ip, g_port)

#endif

	return SQL_ThreadQuery(g_SqlX, "insert_bandetails", pquery, data, size)
}

public cmdBan(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	{
		return PLUGIN_HANDLED
	}
	
	new pid, bantime, bantype[3], ban_length[10], banip[22], banname[32], bansteamid[34], ind[52], banreason[128], temp2[182], temp[192]
	
	read_args(temp, 191)
	strbreak(temp, ban_length, 9, temp2, 181)
	strbreak(temp2, ind, 51, banreason, 127)
	trim(ban_length)
	trim(ind)
	trim(banreason)
	remove_quotes(banreason)
	
	pid = locate_player(id, bantype, ind)
	
	if(pid == -2)
	{
		return PLUGIN_HANDLED
	}
	
	if(!is_str_num(ban_length) || read_argc() < 3 || pid == -1)
	{
		return client_print(id, print_console, "[AMXBans] %L", LANG_PLAYER, "AMX_BAN_SYNTAX")
	}
	
	bantime = abs(str_to_num(ban_length))

	if(get_user_state(pid, PDATA_BEING_BANNED)) 
	{
		return client_print(id, print_console, "[AMXBans] %L", id, "BLOCKING_DOUBLEBAN")
	}
	
	if(!(get_user_flags(id) & get_higher_ban_time_admin_flag()) && bantime == 0)
	{
		return client_print(id, print_console, "[AMXBans] %L", LANG_PLAYER, "NOT_BAN_PERMANENT")
	}
	
	add_user_state(pid, PDATA_BEING_BANNED)
	
	if(!strlen(banreason)) 
	{
		get_pcvar_string(pcvar_default_banreason, banreason, 127)
	}
	
	new cTimeLength[128]
	if(bantime > 0)
	{
		get_time_length(id, bantime, timeunit_minutes, cTimeLength, 127)
	}
	else
	{
		format(cTimeLength, 127, "%L", LANG_PLAYER, "TIME_ELEMENT_PERMANENTLY")
	}
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdBan function 1] Playerid: %d", pid)
	}

	if(pid)
	{
		copy(bansteamid, 33, playerData[pid][playerSteamid])
		copy(banname, 31, playerData[pid][playerName])
		copy(banip, 21, playerData[pid][playerIp])
	}
	else
	{		
		console_print(id, "[AMXBans] %L", LANG_PLAYER, "PLAYER_NOT_FOUND", ind)

		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans] Player %s could not be found", ind)
		}
		
		return remove_user_state(id, PDATA_BEING_BANNED)
	}

	if(!get_ban_type(bantype, 127, bansteamid, banip)) 
	{
		log_amx("[AMXBans ERROR cmdBan] Steamid / IP Invalid! Bantype: <%s> | Authid: <%s> | IP: <%s>", banreason, bansteamid, banip)
		return remove_user_state(id, PDATA_BEING_BANNED)
	}
	
	new pquery[256]
	
	if(equal(banreason, "S"))
	{
		formatex(pquery, 255, "SELECT `player_id` FROM `%s%s` WHERE `player_id` = '%s' AND `ban_type` = 'S' AND `expired` = '0';", g_dbPrefix, TBL_BANS, bansteamid)
		
		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans cmdBan] Banned a player by SteamID: %s", bansteamid)
		}
	}
	else
	{
		formatex(pquery, 255, "SELECT `player_ip` FROM `%s%s` WHERE `player_ip` = '%s' AND `ban_type` = 'SI' AND `expired` = '0';", g_dbPrefix, TBL_BANS, banip)
		
		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans cmdBan] Banned a player by IP: %s", banip)
		}
	}
	
	new data[256]
	format_ban_data(data, id, pid, bantime, bantype, banip, banname, bansteamid, banreason)
	
	return SQL_ThreadQuery(g_SqlX, "cmd_ban_", pquery, data, 256)
}

public cmd_ban_(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new id, pid, bantime, nums[3], bantype[3], banip[22], banname[32], bansteamid[34], banreason[128]
	parse_ban_data(data, nums, bantype, banip, banname, bansteamid, banreason)

	id = nums[0]
	pid = nums[1]
	bantime = nums[2]
	
	if(failstate)
	{
		remove_user_state(pid, PDATA_BEING_BANNED)
		return SQL_Error(query, error, errornum, failstate)
	}
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmd_ban_ function 2] Playerid: %d", pid)
	}
	
	if(!SQL_NumResults(query))
	{
		SQL_FreeHandle(query)

		new admin_nick[100]
		if(id == 0) get_user_name(id, playerData[id][playerName], 31)
		mysql_get_username_safe(id, admin_nick, 99)
		
		if(id > 0)
		{
			if(get_pcvar_num(pcvar_debug) >= 1)
			{
				log_amx("[AMXBans cmdBan] Adminsteamid: %s, Servercmd: %s", playerData[id][playerSteamid], (id == 0) ? "Yes" : "No")
			}
		}
		else
		{
			copy(playerData[id][playerSteamid], 33, "STEAM_ID_SERVER")
	
			new servernick[100]
			get_pcvar_string(pcvar_server_nick, servernick, 99)
			if(strlen(servernick))
			{
				copy(admin_nick, 99, servernick)
			}
			
			check_reason(banreason, 127, admin_nick, 99)
		}
		
		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans cmdBan] Admin nick: %s, Admin userid: %d", admin_nick, get_user_userid(id))
		}
		
		new server_name[200]
		mysql_get_servername_safe(server_name, 199)
		
		if(get_pcvar_num(pcvar_add_mapname)) 
		{
			new mapname[32]
			get_mapname(mapname, 31)
			format(server_name, 199, "%s (%s)", server_name, mapname)
		}
		
		new player_nick[64]
		copy(player_nick, 63, banname)
		
		mysql_escape_string(player_nick, 99)
		mysql_escape_string(admin_nick, 99)
		
		new pquery[1024], len
		
#if defined SET_NAMES_UTF8		
		
		len = format(pquery, 1023, "SET NAMES UTF8; INSERT INTO `%s%s` (`player_id`, `player_ip`, `player_nick`, `admin_ip`, `admin_id`, `admin_nick`, `ban_type`, `ban_reason`, `cs_ban_reason`, `ban_created`, `ban_length`, `server_name`, `server_ip`, `expired`) ", g_dbPrefix, TBL_BANS)
		len += format(pquery[len], 1023 - len, "VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(NOW()), '%d', '%s', '%s:%s', '0');", bansteamid, banip, player_nick, playerData[id][playerIp], playerData[id][playerSteamid], admin_nick, bantype, banreason, "See banlist", bantime, server_name, g_ip, g_port)
		
#else

		len = format(pquery, 1023, "INSERT INTO `%s%s` (`player_id`, `player_ip`, `player_nick`, `admin_ip`, `admin_id`, `admin_nick`, `ban_type`, `ban_reason`, `cs_ban_reason`, `ban_created`, `ban_length`, `server_name`, `server_ip`, `expired`) ", g_dbPrefix, TBL_BANS)
		len += format(pquery[len], 1023 - len, "VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(NOW()), '%d', '%s', '%s:%s', '0');", bansteamid, banip, player_nick, playerData[id][playerIp], playerData[id][playerSteamid], admin_nick, bantype, banreason, banreason, bantime, server_name, g_ip, g_port)

#endif
			
		new tdata[256]
		format_ban_data(tdata, id, pid, bantime, bantype, banip, banname, bansteamid, banreason)
		
		SQL_ThreadQuery(g_SqlX, "insert_bandetails", pquery, tdata, 255)
	}
	else
	{
		if(id == 0)
		{
			log_amx("[AMXBans] %L", LANG_SERVER, "ALREADY_BANNED", bansteamid, banip)
		}
		else
		{
			client_print(id, print_console, "[AMXBans] %L", LANG_PLAYER, "ALREADY_BANNED", bansteamid, banip)
			remove_user_state(pid, PDATA_BEING_BANNED)
		}
	}
	
	return PLUGIN_HANDLED
}

public insert_bandetails(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new pid, nums[3], banip[22], bansteamid[34], banreason[128]
	parse_ban_data(data, nums, _, banip, _, bansteamid, banreason)

	pid = nums[1]
	
	if(failstate)
	{
		return SQL_Error(query, error, errornum, failstate)
	}
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdBan function 5] Playerid: %d", pid)
	}
	
#if defined SET_NAMES_UTF8	
	
	SQL_FreeHandle(query)
	
	new pquery[1024]
	formatex(pquery, 1023, "SELECT (@bid := (SELECT MAX(`bid`) FROM `%s%s` WHERE (`player_ip` = '%s' AND `ban_type` = 'SI') OR (`player_id` = '%s' AND `ban_type` = 'S'))) AS `bid`; UPDATE `%s%s` SET `cs_ban_reason` = '%s' WHERE `bid` = @bid;", g_dbPrefix, TBL_BANS, banip, bansteamid, g_dbPrefix, TBL_BANS, banreason)

	return SQL_ThreadQuery(g_SqlX, "KocTblJIu_KocTblJIb4uku", pquery, data, size)
}
	
public KocTblJIu_KocTblJIb4uku(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	new id, pid, nums[3]
	parse_ban_data(data, nums)
	
	id = nums[0]
	pid = nums[1]
	
	if(failstate)
	{
		delayed_kick(pid + 200)
		return SQL_Error(query, error, errornum, failstate)
	}
	
	if(!SQL_NumResults(query))
	{
		return SQL_FreeHandle(query)
	}
	
	new bid = SQL_ReadResult(query, 0)
	
#else

	new id = nums[0]
	new bid = SQL_GetInsertId(query)
	
#endif	

	SQL_FreeHandle(query)
	
	new motd[3]
	motd[0] = id
	motd[1] = pid
	motd[2] = bid
	
	if(get_pcvar_num(pcvar_snapshot))
	{
		screen_user(id, pid)
		return set_task(1.5, "select_amxbans_motd", 117811, motd, 3)
	}

	return select_amxbans_motd(motd)
}

public select_amxbans_motd(const data[]) 
{
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdBan function 5] Bid: %d", data[2])
	}

	new pquery[1024]

#if defined SET_NAMES_UTF8
	
	format(pquery, 1023, "SELECT `si`.`amxban_motd`, `ba`.`player_nick`, `ba`.`player_id`, `ba`.`player_ip`, \
		`ba`.`admin_nick`, `ba`.`admin_id`, `ba`.`ban_type`, `ba`.`cs_ban_reason`, `ba`.`ban_length` FROM `%s%s` AS `si`,`%s%s` AS `ba` \
		WHERE `ba`.`bid` = '%d' AND `si`.`address` = '%s:%s';", g_dbPrefix, TBL_SERVERINFO, g_dbPrefix, TBL_BANS, data[2], g_ip, g_port)
		
#else

	format(pquery, 1023, "SELECT `si`.`amxban_motd`, `ba`.`player_nick`, `ba`.`player_id`, `ba`.`player_ip`, \
		`ba`.`admin_nick`, `ba`.`admin_id`, `ba`.`ban_type`, `ba`.`ban_reason`, `ba`.`ban_length` FROM `%s%s` AS `si`,`%s%s` AS `ba` \
		WHERE `ba`.`bid` = '%d' AND `si`.`address` = '%s:%s';", g_dbPrefix, TBL_SERVERINFO, g_dbPrefix, TBL_BANS, data[2], g_ip, g_port)

#endif
	
	return SQL_ThreadQuery(g_SqlX, "_select_amxbans_motd", pquery, data, 3)
}

public _select_amxbans_motd(failstate, Handle:query, const error[], errornum, const data[], size, Float:queuetime)
{
	if(failstate)
	{
		delayed_kick(data[1] + 200)
		return SQL_Error(query, error, errornum, failstate)
	}
	
	new id = data[0]
	new player = data[1]
	new bid = data[2]
	
	if(get_pcvar_num(pcvar_debug) >= 1)
	{
		log_amx("[AMXBans cmdBan function 6] Playerid: %d, Bid: %d", player, bid)
	}
	
	new amxban_motd_url[256]
	new admin_steamid[35], admin_nick[100], pl_steamid[35], pl_nick[100], pl_ip[22]
	new ban_type[32], ban_reason[128], iBanLength
	
	if(!SQL_NumResults(query)) 
	{
		SQL_FreeHandle(query)
		amxban_motd_url[0] = '^0'
		log_amx("[AMXBans cmdBan function 6.1] select_motd without result: %d, Bid: %d", player, bid)

		return set_task(kick_delay, "delayed_kick", player + 200)
	} 
	else 
	{
		SQL_ReadResult(query, 0, amxban_motd_url, 256)
		SQL_ReadResult(query, 1, pl_nick, 99)
		SQL_ReadResult(query, 2, pl_steamid, 34)
		SQL_ReadResult(query, 3, pl_ip, 21)
		SQL_ReadResult(query, 4, admin_nick, 99)
		SQL_ReadResult(query, 5, admin_steamid, 34)
		SQL_ReadResult(query, 6, ban_type, 31)
		SQL_ReadResult(query, 7, ban_reason, 127)
		iBanLength = SQL_ReadResult(query, 8)
		SQL_FreeHandle(query)
	}
	
	new admin_team[11]
	
	get_user_team(id, admin_team, 10)
	
	new cTimeLengthPlayer[128]
	new cTimeLengthServer[128]
		
	if(iBanLength > 0) 
	{
		get_time_length(player, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
		get_time_length(0, iBanLength, timeunit_minutes, cTimeLengthServer, 127)
	} 
	else 
	{
		format(cTimeLengthPlayer, 127, "%L", player, "TIME_ELEMENT_PERMANENTLY")
		format(cTimeLengthServer, 127, "%L", LANG_SERVER, "TIME_ELEMENT_PERMANENTLY")
	}
	
	new show_activity = get_cvar_num("amx_show_activity")
	
	if((get_user_flags(id) & get_admin_mole_access_flag() || id == 0) && (get_pcvar_num(pcvar_show_name_evenif_mole) == 0))
	{
		show_activity = 1
	}
	
	if(player)
	{
		new complain_url[256]
		get_pcvar_string(pcvar_complainurl, complain_url, 255)
			
		client_print(player, print_console, "[AMXBans] ===============================================")
		
		new ban_motd[1400]
		switch(show_activity)
		{
			case 1:
			{
				client_print(player, print_console, "[AMXBans] %L", player, "MSG_1")
				client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
				format(ban_motd, 1399, "%L", player, "MSG_MOTD_1", ban_reason, cTimeLengthPlayer, pl_steamid)
			}
			case 2:
			{
				client_print(player, print_console, "[AMXBans] %L", player, "MSG_6", admin_nick)
				client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
				format(ban_motd, 1399, "%L", player, "MSG_MOTD_2", ban_reason, cTimeLengthPlayer, pl_steamid, admin_nick)
			}
			case 3:
			{
				if(get_user_state(player, PDATA_ADMIN))
				{
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_6", admin_nick)
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
					format(ban_motd, 1399, "%L", player, "MSG_MOTD_2", ban_reason, cTimeLengthPlayer, pl_steamid, admin_nick)
				}
				else
				{
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_1")
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
					format(ban_motd, 1399, "%L", player, "MSG_MOTD_1", ban_reason, cTimeLengthPlayer, pl_steamid)
				}
			}
			case 4:
			{
				if(get_user_state(player, PDATA_ADMIN))
				{
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_6", admin_nick)
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
					format(ban_motd, 1399, "%L", player, "MSG_MOTD_2", ban_reason, cTimeLengthPlayer, pl_steamid, admin_nick)
				}
			}
			case 5:
			{
				if(get_user_state(player, PDATA_ADMIN))
				{
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_1")
					client_print(player, print_console, "[AMXBans] %L", player, "MSG_7", complain_url)
					format(ban_motd, 1399, "%L", player, "MSG_MOTD_1", ban_reason, cTimeLengthPlayer, pl_steamid)
				}
			}
		}
		
		client_print(player, print_console, "[AMXBans] %L", player, "MSG_2", ban_reason)
		client_print(player, print_console, "[AMXBans] %L", player, "MSG_3", cTimeLengthPlayer)
		client_print(player, print_console, "[AMXBans] %L", player, "MSG_4", pl_steamid)
		client_print(player, print_console, "[AMXBans] %L", player, "MSG_5", pl_ip)
		client_print(player, print_console, "[AMXBans] ===============================================")
		
		new msg[1400]
		
		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans cmdBan function 6.2] Bid: %d URL= %s Kickdelay:%f", bid, amxban_motd_url, kick_delay)
		}

		if(contain(amxban_motd_url, "sid=%s&adm=%d&lang=%s") != -1) 
		{
			new bidstr[10],lang[5] 
			formatex(bidstr, 9, "B%d", bid)
			get_user_info(player, "lang", lang, 9)
			
			if(equal(lang, ""))
			{
				get_cvar_string("amx_language", lang, 9)
			}
			
			format(msg, 1399, amxban_motd_url, bidstr, (show_activity == 2) ? 1 : 0, lang)
			if(get_pcvar_num(pcvar_debug) >= 1)
			{
				log_amx("[AMXBans cmdBan function 6.3] Motd: %s", msg)
			}
		} 
		else 
		{
			formatex(msg, 1399, ban_motd)
		}
		
		if(!is_user_disconnected(player)) 
		{
			if(get_user_state(player, PDATA_CONNECTED))
			{
				new ret
				ExecuteForward(MFHandle[Ban_MotdOpen], ret, player)
			
				show_motd(player, msg, "AMXBans Gm 1.5.2")
				set_pev(player, pev_flags, pev(player, pev_flags) | FL_FROZEN)
			}
			
			set_task(kick_delay, "delayed_kick", player + 200)
		}
	} 
	else 
	{
		console_print(id, "[AMXBans] %L", LANG_PLAYER, "PLAYER_NOT_FOUND", g_ident)

		if(get_pcvar_num(pcvar_debug) >= 1)
		{
			log_amx("[AMXBans] Player %s could not be found", g_ident)
		}
		return PLUGIN_HANDLED
		
	}
			
	if(equal(ban_type, "S")) 
	{
		if(id == 0)
		{
			log_message("[AMXBans] %L", LANG_SERVER,"STEAMID_BANNED_SUCCESS_IP_LOGGED", pl_steamid)
		}
		else
		{
			client_print(id, print_console, "[AMXBans] %L", id, "STEAMID_BANNED_SUCCESS_IP_LOGGED", pl_steamid)
		}
	} 
	else 
	{
		if(id == 0)
		{
			log_message("[AMXBans] %L", LANG_SERVER, "STEAMID_IP_BANNED_SUCCESS")
		}
		else
		{
			client_print(id, print_console, "[AMXBans] %L", id,"STEAMID_IP_BANNED_SUCCESS")
		}
	}
	
	if(id == 0)
	{
		admin_steamid[0] = '^0'
		admin_team[0] = '^0'
	}
			
	if(iBanLength > 0) 
	{
		log_amx("%L", LANG_SERVER, "BAN_LOG",admin_nick, get_user_userid(id), admin_steamid, admin_team, \
			pl_nick, pl_steamid, cTimeLengthServer, iBanLength, ban_reason)

		if(get_pcvar_num(pcvar_show_in_hlsw)) 
		{
			log_message("^"%s<%d><%s><%s>^" triggered ^"amx_chat^" (text ^"%L^")", admin_nick, get_user_userid(id), admin_steamid, admin_team, \
				LANG_SERVER, "BAN_CHATLOG", pl_nick, pl_steamid, cTimeLengthServer, iBanLength, ban_reason)
		}
	} 
	else 
	{
		log_amx("%L", LANG_SERVER, "BAN_LOG_PERM", admin_nick, get_user_userid(id), admin_steamid, admin_team, pl_nick, pl_steamid, ban_reason)

		if(get_pcvar_num(pcvar_show_in_hlsw)) 
		{
			log_message("^"%s<%d><%s><%s>^" triggered ^"amx_chat^" (text ^"%L^")", admin_nick, get_user_userid(id), admin_steamid, admin_team, \
				LANG_SERVER, "BAN_CHATLOG_PERM", pl_nick, pl_steamid, ban_reason)
		}
	}
	
	new message[191]
	
	switch(show_activity)
	{
		case 1:
		{
			for(new i = 1; i <= plnum; i++) 
			{
				if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
				
				get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
				
				if(iBanLength > 0)
				{
					format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE", pl_nick, cTimeLengthPlayer, ban_reason)
				}
				else
				{
					format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_PERM", pl_nick, ban_reason)
				}
				
				if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
				{
					set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
					ShowSyncHudMsg(i, g_MyMsgSync, message)
				}
				ColorChat(i, RED, "%s %s", PREFIX, message)
				client_print(i, print_console, message)
			}
		}
		case 2:
		{
			for(new i = 1; i <= plnum; i++) 
			{
				if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
				
				get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
				
				if(iBanLength > 0)
				{
					format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2", pl_nick, cTimeLengthPlayer, ban_reason, admin_nick)
				}
				else
				{
					format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2_PERM", pl_nick, ban_reason, admin_nick)
				}
				
				if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
				{
					set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
					ShowSyncHudMsg(i, g_MyMsgSync, message)
				}

				ColorChat(i, RED, "%s %s", PREFIX, message)
				client_print(i, print_console, "%s", message)
			}
		}
		case 3:
		{
			if(is_user_admin(id))
			{
				for(new i = 1; i <= plnum; i++) 
				{
					if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
					
					get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
					
					if(iBanLength > 0)
					{
						format(message,190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2", pl_nick, cTimeLengthPlayer, ban_reason, admin_nick)
					}
					else
					{
						format(message,190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2_PERM", pl_nick, ban_reason, admin_nick)
					}
					
					if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
					{
						set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
						ShowSyncHudMsg(i, g_MyMsgSync, message)
					}

					ColorChat(i, RED, "%s %s", PREFIX, message)
					client_print(i, print_console, "%s", message)
				}
			}
			else
			{
				for(new i = 1; i <= plnum; i++) 
				{
					if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
					
					get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
					
					if(iBanLength > 0)
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE", pl_nick, cTimeLengthPlayer, ban_reason)
					}
					else
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_PERM", pl_nick, ban_reason)
					}
					
					if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
					{
						set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
						ShowSyncHudMsg(i, g_MyMsgSync, message)
					}

					ColorChat(i, RED, "%s %s", PREFIX, message)
					client_print(i, print_console, "%s", message)
				}
			}
		}
		case 4:
		{
			if(is_user_admin(id))
			{
				for(new i = 1; i <= plnum; i++) 
				{
					if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
					get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
					
					if(iBanLength > 0)
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2", pl_nick, cTimeLengthPlayer, ban_reason, admin_nick)
					}
					else
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_2_PERM", pl_nick, ban_reason, admin_nick)
					}
					if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
					{
						set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
						ShowSyncHudMsg(i, g_MyMsgSync, message)
					}

					ColorChat(i, RED, "%s %s", PREFIX, message)
					client_print(i, print_console, "%s", message)
				}
			}
		}
		case 5:
		{
			if(is_user_admin(id))
			{
				for(new i = 1; i <= plnum; i++) 
				{
					if(get_user_state(i, PDATA_HLTV) || get_user_state(i, PDATA_BOT) || !get_user_state(i, PDATA_CONNECTED)) continue
					
					get_time_length(i, iBanLength, timeunit_minutes, cTimeLengthPlayer, 127)
					
					if(iBanLength > 0)
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE", pl_nick, cTimeLengthPlayer, ban_reason)
					}
					else
					{
						format(message, 190, "%L", i, "PUBLIC_BAN_ANNOUNCE_PERM", pl_nick, ban_reason)
					}
					
					if(get_pcvar_num(pcvar_show_hud_messages) == 1) 
					{
						set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 6.0, 10.0 , 0.5, 0.15, -1)
						ShowSyncHudMsg(i, g_MyMsgSync, message)
					}

					ColorChat(i, RED, "%s %s", PREFIX, message)
					client_print(i, print_console, "%s", message)
				}
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public locate_player(id, output[], const identifier[]) 
{
	new player = find_player("c", identifier)

	if(!player) 
	{
		player = find_player("bl", identifier)
	}
	else
	{
		copy(output, 2, "S")
	}
	
	if(!player) 
	{
		player = find_player("d", identifier)
		if(player)
		{
			copy(output, 2, "SI")
		}
	}

	if(!player && identifier[0]=='#' && identifier[1]) 
	{
		player = find_player("k", str_to_num(identifier[1]))
	}

	if(player) 
	{
		if(get_user_state(player, PDATA_IMMUNITY)) 
		{
			if(id == 0)
			{
				server_print("[AMXBans] Client has immunity")
			}
			else
			{
				console_print(id, "[AMXBans] Client has immunity")
			}
			return -2
		}
	} 
	else
	{
		player = -1
	}
	
	return player
}

public screen_user(id, pid)
{
	if(is_user_disconnected(pid))
	{
		return PLUGIN_CONTINUE
	}
	
	new timestamp[32]
	get_time("%d.%m.%Y - %H:%M:%S", timestamp, 31) 
	ColorChat(pid, RED, "%s Screenshot taken on player ^x03%s^x01 (^x04%s^x01) ^x03%s^x01 by admin ^x04%s", PREFIX, playerData[pid][playerName], playerData[pid][playerIp], timestamp, playerData[id][playerName])
	set_hudmessage(255, 255, 0, -1.0, 0.01, 0, 0.02, 15.0, 0.0, 0.0, -1)
	show_hudmessage(pid, "Player: %s (%s) Time: %s Admin: %s", playerData[pid][playerName], playerData[pid][playerIp], timestamp, playerData[id][playerName])
	
	return set_task(1.0, "get_snapshot", pid + 118911)
}

public get_snapshot(id)
{
	id -= 118911
	return client_cmd(id, "snapshot")
}

stock parse_ban_data(const input[], nums[] = "", bantype[] = "", banip[] = "", banname[] = "", bansteamid[] = "", banreason[] = "")
{
	new sid[5], spid[5], stime[10]
	parse(input, sid, 4, spid, 4, stime, 9, bantype, 2, banip, 21, banname, 31, bansteamid, 33, banreason, 127)
	
	nums[0] = str_to_num(sid)
	nums[1] = str_to_num(spid)
	nums[2] = str_to_num(stime)
	
	return 1
}

stock format_ban_data(output[], id, pid, bantime, const bantype[], const banip[], const banname[], const bansteamid[], const banreason[])
{
	return formatex(output, 255, "^"%d^" ^"%d^" ^"%d^" ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", id, pid, bantime, bantype, banip, banname, bansteamid, banreason)
}