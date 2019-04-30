#include <amxmodx>
#include <server_query>
#include <colorchat>

#define PLUGIN "Simple Redirect List"
#define VERSION "1.4"
#define AUTHOR "O'Zone" 

#define UPDATE_SERVERINFO	30.0	

enum _:ServerData { sAddress[64], sHostName[64], sMap[64], iPlayers, iMaxPlayers };
new g_aServerData[256][ServerData], g_iLoadedServersNum, _access, serverId[3], callback, lastIP[64];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /servers", "ServersMenu");
	register_clcmd("say_team /servers", "ServersMenu");
	register_clcmd("say /server", "ServersMenu");
	register_clcmd("say_team /server", "ServersMenu");
	register_clcmd("say /join", "Join");
	register_clcmd("say_team /join", "Join");
	
	register_clcmd("say /serwery", "ServersMenu");
	register_clcmd("say_team /serwery", "ServersMenu");
	register_clcmd("say /serwer", "ServersMenu");
	register_clcmd("say_team /serwer", "ServersMenu");
	register_clcmd("say /dolacz", "Join");
	register_clcmd("say_team /dolacz", "Join");
	register_clcmd("serwer", "ServersMenu");
}

public plugin_cfg()
{
	new buffer[64], fp = fopen("addons/amxmodx/configs/servers.ini", "rt");
	
	if(!fp) set_fail_state("Nie znaleziono pliku ^"addons/amxmodx/configs/servers.ini^"");
	while(!feof(fp))
	{
		fgets(fp, buffer, charsmax(buffer)); trim(buffer);
		if(buffer[0] && buffer[0] != ';')
			g_aServerData[g_iLoadedServersNum++][sAddress] = buffer;
	}
	
	if(!g_iLoadedServersNum) set_fail_state("Nie znaleziono serwerow, sprawdz zawartosc pliku ^"addons/amxmodx/configs/servers.ini^"");
	
	GetServerInfo();
	set_task(UPDATE_SERVERINFO, "GetServerInfo", .flags="b");
}

public ServersMenu(id)
{
	if(IsServersActive())
	{
		static iMenu, iMenuCallback, num[3], szHostName[128];
		iMenu = menu_create("\y[ \rLista Naszych Serwerow \y]^n\wStrona: \r", "ServerMenuHandler");
		iMenuCallback = menu_makecallback("ServerMenuCallback");
		
		for(new i; i < g_iLoadedServersNum; i++)
		{
			formatex(szHostName, charsmax(szHostName), g_aServerData[i][sHostName]);
			replace_all(szHostName, charsmax(szHostName), "Cs-Reload.pl ", "");
			replace_all(szHostName, charsmax(szHostName), " @pukawka.pl", "");
			format(szHostName, charsmax(szHostName), "%s \d[\y%s \d| %s%d/%d\d]", szHostName, g_aServerData[i][sMap], g_aServerData[i][iPlayers] == g_aServerData[i][iMaxPlayers] ? "\r" : "\y", g_aServerData[i][iPlayers], g_aServerData[i][iMaxPlayers]);
			num_to_str(i, num, charsmax(num));
			menu_additem(iMenu, szHostName, num, 0, iMenuCallback);
		}
		
		menu_setprop(iMenu, MPROP_BACKNAME, "Wroc");
		menu_setprop(iMenu, MPROP_NEXTNAME, "Dalej");
		menu_setprop(iMenu, MPROP_EXITNAME, "Wyjdz");
		
		menu_display(id, iMenu, 0);
	}
	else ColorChat(id, GREEN, "[SERWERY]^x01 Brak informacji o naszych serwerach. Sprobuj ponownie pozniej.")
	return PLUGIN_HANDLED;
}

public ServerMenuCallback(id, menu, item)
{
	static ItemStatus, sNewName[96], sId, serverName[64]; ItemStatus = ITEM_ENABLED;
	menu_item_getinfo(menu, item, _access, serverId, charsmax(serverId), serverName, charsmax(serverName), callback);
	if(!g_aServerData[(sId = str_to_num(serverId))][sMap])
	{
		formatex(sNewName, charsmax(sNewName), "\dSerwer %s \r[Nie odpowiada]", g_aServerData[sId][sAddress]);
		menu_item_setname(menu, item, sNewName);
		ItemStatus = ITEM_DISABLED;
	}	
	return ItemStatus;
}

public ServerMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT || item < 0 || item + 1 > g_iLoadedServersNum)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	menu_item_getinfo(menu, item, _access, serverId, charsmax(serverId), _, _, callback);
	formatex(lastIP, charsmax(lastIP), g_aServerData[str_to_num(serverId)][sAddress]);
	
	client_execute(id, "connect %s", g_aServerData[str_to_num(serverId)][sAddress]);
	redirect(id, g_aServerData[str_to_num(serverId)][sAddress]);
	
	new szName[32], szHostName[64], szMessage[128];
	get_user_name(id, szName, charsmax(szName));

	formatex(szHostName, charsmax(szHostName), g_aServerData[str_to_num(serverId)][sHostName]);
	replace_all(szHostName, charsmax(szHostName), "Cs-Reload.pl ", "");
	replace_all(szHostName, charsmax(szHostName), " @pukawka.pl", "");

	formatex(szMessage, charsmax(szMessage), "[SERWERY]^x03 %s^x01 zostal przekierowany na^x04 %s.", szName, szHostName);
	ColorChat(0, GREEN, szMessage);
	formatex(szMessage, charsmax(szMessage), "[SERWERY]^x01 Wpisz^x04 /dolacz^x01, aby dolaczyc do niego.");
	ColorChat(0, GREEN, szMessage);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public Join(id)
{
	if(equal(lastIP, ""))
	{
		ColorChat(id, GREEN, "[SERWERY]^x01 Nikt nie zostal jeszcze przekierowany na zaden serwer.")
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szHostName[64], szMessage[128], serverID;
	get_user_name(id, szName, charsmax(szName));
	
	for(new i = 1; i <= g_iLoadedServersNum; i++)
	{
		if(equal(lastIP, g_aServerData[i][sAddress]))
			serverID = i;
	}
	
	client_execute(id, "connect %s", lastIP);
	redirect(id, lastIP);
	
	formatex(szHostName, charsmax(szHostName), g_aServerData[serverID][sHostName]);
	replace_all(szHostName, charsmax(szHostName), "Cs-Reload.pl ", "");
	replace_all(szHostName, charsmax(szHostName), " @pukawka.pl", "");
	
	formatex(szMessage, charsmax(szMessage), "[SERWERY]^x03 %s^x01 zostal przekierowany na^x04 %s.", szName, szHostName);
	ColorChat(0, GREEN, szMessage);
	formatex(szMessage, charsmax(szMessage), "[SERWERY]^x01 Wpisz^x04 /dolacz^x01, aby dolaczyc do niego.");
	ColorChat(0, GREEN, szMessage);
	
	return PLUGIN_HANDLED;
}

public GetServerInfo()
{
	for(new i; i < g_iLoadedServersNum; i++)
		ServerInfo(g_aServerData[i][sAddress], "cbInfo");
}	

public cbInfo(const szServer[], _A2A_TYPE, const Response[], len, success, latency)
{
	new srvId = GetServer(szServer);
	if(srvId == -1 || !success) return;
	
	static sNoData[128];
	ServerResponseParseInfo(Response, 
		g_aServerData[srvId][sHostName], charsmax(g_aServerData[][sHostName]), 
		g_aServerData[srvId][sMap], charsmax(g_aServerData[][sMap]), 
		sNoData, charsmax(sNoData), sNoData, charsmax(sNoData), 
		g_aServerData[srvId][iPlayers], 
		g_aServerData[srvId][iMaxPlayers]
	);
}

bool:IsServersActive()
{
	for(new i; i < g_iLoadedServersNum; i++)
		if(g_aServerData[i][sMap]) return true;
	return false;	
}

stock GetServer(const sServer[])
{
	for(new i; i < g_iLoadedServersNum; i++)
		if(!strcmp(sServer, g_aServerData[i][sAddress])) return i;
	return -1;
}

stock client_execute(id, const szText[], any:...) 
{
	#pragma unused szText

	new szMessage[256];

	format_args( szMessage ,charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}

stock redirect(id, const sServer[]) client_cmd(id, "wait;wait;wait;wait;wait;^"connect^" %s", sServer);