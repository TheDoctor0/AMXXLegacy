#include <amxmodx>
#include <server_query>

#define UPDATE_SERVERINFO	30.0	

enum _:ServerData { sAddress[25], sHostName[64], sMap[32], iPlayers, iMaxPlayers };
new g_aServerData[100][ServerData];
new g_iLoadedServersNum;
new _access, serverId[3], callback;

public plugin_init()
{
	register_plugin("Simple Redirect List", "1.3", "O'Zone");
	
	register_clcmd("say /servers", "ServersMenu")
	register_clcmd("say_team /servers", "ServersMenu")
	register_clcmd("say /server", "ServersMenu")
	register_clcmd("say_team /server", "ServersMenu")
	register_clcmd("say /join", "Join")
	register_clcmd("say_team /join", "Join")
	
	register_clcmd("say /serwery", "ServersMenu")
	register_clcmd("say_team /serwery", "ServersMenu")
	register_clcmd("say /serwer", "ServersMenu")
	register_clcmd("say_team /serwer", "ServersMenu")
	register_clcmd("say /dolacz", "Join")
	register_clcmd("say_team /dolacz", "Join")

	register_event("HLTV", "eRoundStart", "a", "1=0", "2=0");
}

public plugin_cfg()
{
	new buffer[25], fp = fopen("addons/amxmodx/configs/servers.ini", "rt");
	
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
		static iMenu, iMenuCallback, num[3];
		iMenu 		= menu_create("\y[ \rLista Naszych Serwerow \y]^n", "ServerMenuHandler");
		iMenuCallback 	= menu_makecallback("ServerMenuCallback");
		
		menu_setprop(iMenu, MPROP_BACKNAME, "Wroc");
		menu_setprop(iMenu, MPROP_NEXTNAME, "Dalej");
		menu_setprop(iMenu, MPROP_EXITNAME, "Wyjdz");
		
		for(new i; i < g_iLoadedServersNum; i++)
		{
			num_to_str(i, num, charsmax(num));
			menu_additem(iMenu, g_aServerData[i][sHostName], num, 0, iMenuCallback);
		}
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
		formatex(sNewName, charsmax(sNewName), "\dSerwer %s \rnie odpowiada", g_aServerData[sId][sAddress]);
		ItemStatus = ITEM_DISABLED;
	}	
	else formatex(sNewName, charsmax(sNewName), "%s \d[\y%s | %d/%d\d]", serverName, g_aServerData[sId][sMap], g_aServerData[sId][iPlayers], g_aServerData[sId][iMaxPlayers]);
	menu_item_setname(menu, item, sNewName);
	return ItemStatus;
}

public ServerMenuHandler(id, menu, item)
{
	if(item != MENU_EXIT) 
	{
		menu_item_getinfo(menu, item, _access, serverId, charsmax(serverId), _, _, callback);
		client_execute(id, "connect %s", g_aServerData[str_to_num(serverId)][sAddress])
		redirect(id, g_aServerData[str_to_num(serverId)][sAddress]);
		
		new szName[32];
		get_user_name(id, szName, charsmax(szName));
		
		new message[128];
		formatex(message, charsmax(message), "[SERWERY]^x03 %s^x01 zostal przekierowany na^x04 %s.", szName, g_aServerData[str_to_num(serverId)][sHostName]);
		ColorChat(0, GREEN, message);
		formatex(message, charsmax(message), "[SERWERY]^x01 Wpisz^x04 /dolacz^x01, aby dolaczyc do niego.");
		ColorChat(0, GREEN, message)
	}
	
	menu_destroy(menu);
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
	
	static sNoData[64];
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

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args( szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}

stock redirect(id, const sServer[]) client_cmd(id, "^"disconnect^";^"wait^";^"wait^";^"wait^";^"connect^" %s", sServer);