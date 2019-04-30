#include <amxmodx>

#define PLUGIN "New Status"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /status", "ShowStatus");
	register_clcmd("say status", "ShowStatus");
}

public ShowStatus(id)
{	
	new szBuffer[2048], szServerName[64], szServerIP[32], szServerMap[32], szPlayers[32], szName[32], szSteamID[32], szIP[32], iPlayer, iNum, iLen;
	
	get_players(szPlayers, iNum);
	
	get_cvar_string("hostname", szServerName, charsmax(szServerName)); 
	get_cvar_string("net_address", szServerIP, charsmax(szServerIP));
	get_mapname(szServerMap, charsmax(szServerMap));
	get_players(szPlayers, iNum);
	
	console_print(id, "----------------------Informacje o serwerze---------------------");
	console_print(id, " Serwer: %s", szServerName);
	console_print(id, " IP: %s", szServerIP);
	console_print(id, " Mapa: %s", szServerMap);
	console_print(id, " Gracze: %i / %i ", get_playersnum(), get_maxplayers());
	console_print(id, "----------------------Informacje o graczach---------------------");
	console_print(id, "#ID       Nick           IP             SteamID             Typ");
	
	iLen = format(szBuffer, charsmax(szBuffer), "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "%1s %-25.22s %17s %15s %20s^n", "ID", "Nick", "IP", "SteamID", "Typ");

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		
		if(is_user_bot(iPlayer) || is_user_hltv(iPlayer))
			continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		get_user_ip(iPlayer, szIP, charsmax(szIP), 1);
		get_user_authid(iPlayer, szSteamID, charsmax(szSteamID));
		
		if(iPlayer >= 10)
			iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "#%1i %-20.22s %18s %18s %18s^n", iPlayer, szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
		else
			iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "#%1i %-20.22s %18s %18s %18s^n", iPlayer, szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
		
		console_print(id,"#%d  %s  %s  %s  %s  %s", i + 1, i < 10 ? "" : " ", szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
	}
	console_print(id, "---------------------------------------------------------------------");

	show_motd(id, szBuffer, "Informacje o Graczach");
	
	return PLUGIN_HANDLED;
}

stock bool:is_user_steam(szSteamID[]) 
	return bool:(contain(szSteamID, "STEAM_0:0:") != -1 || contain(szSteamID, "STEAM_0:1:") != -1);
