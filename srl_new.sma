#include <amxmodx>
#include <amxmisc>
#include <serverquery>

#define PLUGIN "Server Redirect List"
#define VERSION "2.0"
#define AUTHOR "O'Zone & Exolent"

#define TASK_ID_UPDATE   1234
#define UPDATE_DELAY     30.0

new const gCmdMenu[][] = { "serwer", "say /serwer", "say_team /serwer", "say /serwery", "say_team /serwery", "say /server", "say_team /server", "say /servers", "say_team /servers" };
new const gCmdJoin[][] = { "dolacz", "say /dolacz", "say_team /dolacz", "say /join", "say_team /join" };

enum _:Status 
{
	Status_Offline,
	Status_Online
};

enum _:ServerData 
{
	Server_Name[32],
	Server_Address[32],
	Server_Port,
	Server_Status,
	Server_NumPlayers,
	Server_MaxPlayers,
	Server_Map[64]
};

new Array:gServerData;
new gNumServers;

new gUpdateIndex;

new gMenuText[1024];
const PERPAGE = 8;

#define MAX_PLAYERS 32

new gMenuPage[MAX_PLAYERS + 1];
new gSelectedServer[MAX_PLAYERS + 1];

new const gMenuTitleSelect[] = "MenuSelect";
new const gMenuTitleInfo  [] = "MenuInfo";

new gCurrentMap[64];
new gLastServer = -1;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i = 0; i < sizeof gCmdMenu; i++) register_clcmd(gCmdMenu[i], "CmdServer");
	
	for(new i = 0; i < sizeof gCmdJoin; i++) register_clcmd(gCmdJoin[i], "CmdJoin");
	
	register_menu(gMenuTitleSelect, 1023, "MenuSelect");
	register_menu(gMenuTitleInfo, 1023, "MenuInfo");
	
	gServerData = ArrayCreate(ServerData);
	
	LoadServers();
	
	get_mapname(gCurrentMap, charsmax(gCurrentMap));
}

public plugin_end()
	ArrayDestroy(gServerData);

public CmdJoin(id)
{
	if(gLastServer == -1)
	{
		client_print_color(id, print_team_red, "^x03^x04[SRL]^x01 Nikt nie zostal jeszcze przekierowany na zaden serwer.")
		return PLUGIN_HANDLED;
	}
	
	new data[ServerData];
	ArrayGetArray(gServerData, gLastServer, data);

	new name[32];
	get_user_name(id, name, charsmax(name));
	
	client_print_color(0, print_team_red, "^x03^x04[SRL]^x03 %s^x01 zostal przekierowany na^x04 %s^x01 (^x04%s^x01 |^x04 %d/%d^x01).", name, data[Server_Name], data[Server_Map], data[Server_NumPlayers], data[Server_MaxPlayers]);
	client_print_color(0, print_team_red, "^x03^x04[SRL]^x01 Wpisz^x04 /dolacz^x01, aby podazyc za nim.");

	client_execute(id, "connect %s:%d", data[Server_Address], data[Server_Port]);

	client_cmd(id, ";wait;wait;wait;wait;wait;^"Connect^" %s:%d", data[Server_Address], data[Server_Port]);
	
	return PLUGIN_HANDLED;
}

public CmdServer(id) 
{
	if(!gNumServers)
	{
		client_print_color(id, print_team_red, "^x03^x04[SRL]^x01 Brak informacji o naszych serwerach. Sprobuj ponownie pozniej.");
		
		return PLUGIN_HANDLED;
	}
	
	gMenuPage[id] = 0;

	ShowServerList(id);
	
	return PLUGIN_HANDLED;
}

ShowServerList(id) 
{
	gSelectedServer[id] = 0;
	
	new len = copy(gMenuText, charsmax(gMenuText), "\yLista Serwerow \rCS-Reload.pl");
	new keys;
	
	new page = gMenuPage[id];
	new pages = (gNumServers + PERPAGE - 1) / PERPAGE;
	
	if(page < 0) gMenuPage[id] = page = 0;
	else if(page >= pages) gMenuPage[id] = page = pages - 1;
	
	if(pages > 1) len += formatex(gMenuText[len], charsmax(gMenuText) - len, " %d/%d", (page + 1), pages);
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n^n");
	
	new start = page * PERPAGE;
	new stop = start + PERPAGE;
	
	new data[ServerData];
	
	for(new i = start; i < stop; i++) 
	{
		if(i < gNumServers) 
		{
			ArrayGetArray(gServerData, i, data);
			
			len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\r%d. \w%s^n", (i - start + 1), data[Server_Name]);
			
			keys |= (1 << (i - start));
		} 
		else len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n");
	}
	
	if(page > 0) 
	{
		len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r8. \wWroc");
		keys |= MENU_KEY_8;
	} 
	else len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n");
	
	if((page + 1) < pages) 
	{
		len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r9. \wDalej^n");
		keys |= MENU_KEY_9;
	} 
	else len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n^n");
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "\r0. \wWyjscie");
	keys |= MENU_KEY_0;
	
	show_menu(id, keys, gMenuText, _, gMenuTitleSelect);
}

public MenuSelect(id, key) 
{
	switch(++key % 10) 
	{
		case 8: 
		{
			gMenuPage[id]--;
			
			ShowServerList(id);
		}
		case 9: 
		{
			gMenuPage[id]++;
			
			ShowServerList(id);
		}
		case 0: {}
		default: 
		{
			gSelectedServer[id] = (gMenuPage[id] * PERPAGE) + key - 1;
			
			ShowServerInfo(id);
		}
	}
}

ShowServerInfo(id) 
{
	new data[ServerData];
	ArrayGetArray(gServerData, gSelectedServer[id], data);
	
	new len = formatex(gMenuText, charsmax(gMenuText), "\rSerwer: \y%s^n\rIP: \y%s:%d\r^n^n", data[Server_Name], data[Server_Address], data[Server_Port]);
	new keys;
	
	if(data[Server_Status] == Status_Online) 
	{
		len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\r1. \wStatus: \yOnline^n");
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\r2. \wGracze: \y%d/%d^n", data[Server_NumPlayers], data[Server_MaxPlayers]);
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\r3. \wMapa: \y%s^n^n", data[Server_Map]);
		len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\r4. \rDolacz^n");
		
		keys |= MENU_KEY_4;
	} 
	else len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\d1. \wStatus: \wOffline^n");
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r9. \wWroc");
	keys |= MENU_KEY_9;
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r0. \wWyjscie");
	keys |= MENU_KEY_0;
	
	show_menu(id, keys, gMenuText, _, gMenuTitleInfo);
}

public MenuInfo(id, key) 
{
	switch(++key % 10) 
	{
		case 4: 
		{
			new data[ServerData];
			ArrayGetArray(gServerData, gSelectedServer[id], data);
			
			new name[32];
			get_user_name(id, name, charsmax(name));
			
			gLastServer = gSelectedServer[id];
			
			client_print_color(0, print_team_red, "^x03^x04[SRL]^x03 %s^x01 zostal przekierowany na^x04 %s^x01 (^x04%s^x01 |^x04 %d/%d^x01).", name, data[Server_Name], data[Server_Map], data[Server_NumPlayers], data[Server_MaxPlayers]);
			client_print_color(0, print_team_red, "^x03^x04[SRL]^x01 Wpisz^x04 /dolacz^x01, aby podazyc za nim.");
			
			client_execute(id, "connect %s:%d", data[Server_Address], data[Server_Port]);
			
			client_cmd(id, ";wait;wait;wait;wait;wait;^"Connect^" %s:%d", data[Server_Address], data[Server_Port]);
		}
		case 9: ShowServerList(id);
		case 0: gSelectedServer[id] = 0;
	}
}

public UpdateServers() 
{	
	new data[ServerData];
	ArrayGetArray(gServerData, gUpdateIndex, data);
	
	new errcode, error[128];
	while(!sq_query(data[Server_Address], data[Server_Port], SQ_Server, "SQueryResults", errcode)) 
	{
		sq_error(errcode, error, charsmax(error));
		
		data[Server_Status] = Status_Offline;
		
		ArraySetArray(gServerData, gUpdateIndex++, data);
		
		if(gUpdateIndex == gNumServers) 
		{
			gUpdateIndex = 0;
			
			set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
			
			break;
		}
		
		ArrayGetArray(gServerData, gUpdateIndex, data);
	}
}

public SQueryResults(id, type, Trie:buffer, Float:queryTime, bool:failed, _data[], _dataSize) 
{
	new data[ServerData];
	ArrayGetArray(gServerData, gUpdateIndex, data);
	
	if(failed) data[Server_Status] = Status_Offline;
	else 
	{
		data[Server_Status] = Status_Online;
        
		TrieGetString(buffer, "map", data[Server_Map], charsmax(data[Server_Map]));
		TrieGetCell(buffer, "num_players", data[Server_NumPlayers]);
		TrieGetCell(buffer, "max_players", data[Server_MaxPlayers]);
	}
	
	ArraySetArray(gServerData, gUpdateIndex, data);
	
	if(++gUpdateIndex < gNumServers) UpdateServers();
	else 
	{
		gUpdateIndex = 0;
		
		set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
	}
}

LoadServers() 
{
	new file[64];
	get_configsdir(file, charsmax(file));
	add(file, charsmax(file), "/servers.ini");
	
	new szIP[64]; 
	new iPos = get_cvar_string("ip", szIP, 63); 
	szIP[iPos++] = ':'; 
	get_cvar_string("port", szIP[ iPos ], 14);  
	
	new f = fopen(file, "rt");
	
	if(!f) return;
	
	// File format:
	// "Server Name Here" "Address:Port"
	
	new line[256];
	new data[ServerData];
	new pos;
	
	while(!feof(f)) {
		fgets(f, line, charsmax(line));
		trim(line);
		
		if(!line[0] || line[0] == ';' || line[0] == '/' && line[1] == '/') continue;
		
		parse(line, data[Server_Name], charsmax(data[Server_Name]), data[Server_Address], charsmax(data[Server_Address]));
		
		if(equal(data[Server_Address], szIP)) continue;
		
		pos = contain(data[Server_Address], ":");
		
		if(pos > 0) {
			data[Server_Address][pos] = 0;
			data[Server_Port] = str_to_num(data[Server_Address][pos + 1]);
		}
		else data[Server_Port] = 27015;
		
		ArrayPushArray(gServerData, data);
		gNumServers++;
	}
	
	if(gNumServers) set_task(1.0, "UpdateServers");
	
	fclose(f);
}

stock get_logsdir(output[], len)
	return get_localinfo("amxx_logs", output, len);

stock client_execute(id, const szText[], any:...) 
{
	#pragma unused szText

	new szMessage[256];

	format_args(szMessage ,charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}