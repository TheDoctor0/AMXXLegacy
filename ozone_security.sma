#include <amxmodx>
#include <amxmisc>
#include <regex>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#define PLUGIN  "O'Zone Security"
#define VERSION "1.6"
#define AUTHOR  "O'Zone"

#define KEY_DETECTOR

new const szPatern[] = "[0-9]{1,3}[a-zA-Z-?.!@#%&*()=_+,./\| ;:<>`~'{}]{1,5}[0-9]{1,3}[a-zA-Z-?.!@#%&*()=_+,./\| ;:<>`~'{}]{1,5}[0-9]{2,3}[a-zA-Z-?.!@#%&*()=_+,./\| ;:<>`~'{}]{1,5}[0-9]{1,3}"

new const szBlackList[][] = { "xSteam",  "zareklamuj-sie", "adf.ly", "adf ly", "adf,ly", "adf*ly", "skuteczne reklamy", "xaa.pl" };

new const szWhiteList[][] = { "193.33.177.111", "193.33.177.185", "91.185.185.20", "91.224.117.33", "193.33.176.249", "193.33.176.224", "193.33.177.2", "91.224.117.80", "80.72.41.214", "137.74.1.218"};

enum { DEL, INS, END, PGUP, PGDN, F10, F11, F12 };

new szPlayersIP[MAX_PLAYERS + 1][16], bool:bBanned[MAX_PLAYERS + 1], bool:bChange[MAX_PLAYERS + 1], bool:bSpawned[MAX_PLAYERS + 1];
#if defined KEY_DETECTOR
new bool:bInfoPrinted[MAX_PLAYERS + 1];
#endif

new gmsgSayText, gmsgTextMsg

new const GAME_NAMES[][] = {"CS-Reload.pl", "Najlepsze Serwery", "Counter-Strike"};

new iGameName;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "CBasePlayer_SetUserInfoName");

	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 0);

	register_dictionary("admincmd.txt");

	register_concmd("amx_nick", "ChangeNick", ADMIN_BAN, "<name or #userid> <new nick>");

	register_message(get_user_msgid("SayText"), "Message");
	
	register_clcmd("amx_banid", "CheckBanid");
	register_clcmd("say /banid", "CheckBanid");
	register_clcmd("sayteam /banid", "CheckBanid");
	
	register_clcmd("say /status", "ShowStatusMOTD");
	register_clcmd("say status", "ShowStatus");
	register_clcmd("amx_ip", "ShowStatus");
	
	register_clcmd("say /kontakt", "ShowContactMOTD");
	register_clcmd("say kontakt", "ShowContactMOTD");
	
	register_clcmd("say", "CheckSay");
	register_clcmd("say_team", "CheckSay");

	#if defined KEY_DETECTOR
	register_clcmd("amx_check1", "BindCheck1");
	register_clcmd("amx_check2", "BindCheck2");
	register_clcmd("amx_check3", "BindCheck3");
	register_clcmd("amx_check4", "BindCheck4");
	register_clcmd("amx_check5", "BindCheck5");
	register_clcmd("amx_check6", "BindCheck6");
	register_clcmd("amx_check7", "BindCheck7");
	register_clcmd("amx_check8", "BindCheck8");
	#endif

	set_task(1.0, "ChangeGameName", .flags="b");

	gmsgSayText = get_user_msgid("SayText")
	gmsgTextMsg = get_user_msgid("TextMsg")
}

public ChangeGameName()
	set_member_game(m_GameDesc, GAME_NAMES[iGameName > charsmax(GAME_NAMES) ? (iGameName = 0) : iGameName++]);

public client_disconnected(id)
{
	bChange[id] = false;

	bSpawned[id] = false;

	remove_task(id);

	if(!szPlayersIP[id][0]) return;

	szPlayersIP[id][0] = EOS;
}

#if defined KEY_DETECTOR
public client_authorized(id)
{
	if(!get_user_flags(id) && ADMIN_BAN)
	{
		cmd_execute(id, "bind ^"DEL^" ^"amx_check1^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"DEL^" ^"amx_check1^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"DEL^" ^"amx_check1^"");
		
		cmd_execute(id, "bind ^"INS^" ^"amx_check2^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"INS^" ^"amx_check2^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"INS^" ^"amx_check2^"");
		
		cmd_execute(id, "bind ^"END^" ^"amx_check3^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"END^" ^"amx_check3^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"END^" ^"amx_check3^"");
		
		cmd_execute(id, "bind ^"PGUP^" ^"amx_check4^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"PGUP^" ^"amx_check4^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"PGUP^" ^"amx_check4^"");
		
		cmd_execute(id, "bind ^"PGDN^" ^"amx_check5^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"PGDN^" ^"amx_check5^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"PGDN^" ^"amx_check5^"");
		
		cmd_execute(id, "bind ^"F10^" ^"amx_check6^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"F10^" ^"amx_check6^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"F10^" ^"amx_check6^"");
		
		cmd_execute(id, "bind ^"F11^" ^"amx_check7^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"F11^" ^"amx_check7^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"F11^" ^"amx_check7^"");
		
		cmd_execute(id, "bind ^"F12^" ^"amx_check8^"");
		client_cmd(id, "echo ^"^";^"bind^" ^"F12^" ^"amx_check8^"");
		cmd_execute(id, "echo ^"^";^"bind^" ^"F12^" ^"amx_check8^"");
	}
}
#endif

public client_putinserver(id)
{
	new szName[33], szPlayerIP[32];
	get_user_name(id, szName, charsmax(szName));
	get_user_ip(id, szPlayerIP, charsmax(szPlayerIP), 1);
	
	bBanned[id] = false;
	
	copy(szPlayersIP[id], charsmax(szPlayerIP[]), szPlayerIP);
	
	CheckPhrase(id, szName, 0);
	
	if(equal(szName, "Player") || equal(szName, "unnamed") || equal(szName, "Gracz"))
	{
		server_cmd("amx_nick #%d ^"Gracz | CS-Reload.pl^"", get_user_userid(id));
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public CBasePlayer_SetUserInfoName(const id, infobuffer[], szNewName[])
{
	new szOldName[32];

	get_entvar(id, var_netname, szOldName, charsmax(szOldName));

	if(containi(szNewName, "＃") != -1) 
	{
		replace_all(szNewName, charsmax(szOldName), "＃", "");

		SetHookChainArg(3, ATYPE_STRING, szNewName);
	}

	if(containi(szOldName, "＃") != -1) replace_all(szOldName, charsmax(szOldName), "＃", "");

	if(containi(szNewName, "addon") != -1 || containi(szNewName, "mapcyc") != -1)
	{
		SetHookChainArg(3, ATYPE_STRING, szOldName);

		set_msg_block(get_entvar(id, var_deadflag) != DEAD_NO ? gmsgTextMsg : gmsgSayText, BLOCK_ONCE);
	}
}

public client_infochanged(id)
{
	new szNewName[32], szOldName[32];

	get_user_name(id, szOldName, charsmax(szOldName));
	get_user_info(id, "name", szNewName, charsmax(szNewName));

	if(containi(szNewName, "＃") != -1) 
	{
		replace_all(szNewName, charsmax(szNewName), "＃", "");

		set_user_info(id, "name", szNewName);
		client_cmd(id, "name ^"%s^"", szNewName);

		return PLUGIN_HANDLED;
	}

	if(equal(szOldName, szNewName)) return PLUGIN_CONTINUE;

	if(containi(szOldName, "addon") != -1 || containi(szOldName, "mapcyc") != -1) return PLUGIN_CONTINUE;

	if(containi(szNewName, "addon") != -1 || containi(szNewName, "mapcyc") != -1)
	{
		replace_all(szOldName, charsmax(szOldName), "＃", "");
		set_user_info(id, "name", szOldName);
		client_cmd(id, "name ^"%s^"", szOldName);

		return PLUGIN_HANDLED;
	}

	if(bChange[id])
	{
		bChange[id] = false;

		return PLUGIN_CONTINUE;
	}

	if(bSpawned[id])
	{
		client_print_color(id, id, "^x03[UWAGA]^x01 Zmiana nicku podczas gry jest zablokowana.");

		replace_all(szOldName, charsmax(szOldName), "＃", "");
		set_user_info(id, "name", szOldName);
		client_cmd(id, "name ^"%s^"", szOldName);

		CheckPhrase(id, szNewName, 1);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PlayerSpawn(id)
	set_task(0.1, "BlockNameChange", id);

public BlockNameChange(id)
	bSpawned[id] = true;

public ChangeNick(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3)) return PLUGIN_HANDLED;

	new szArg[32], szArg2[32], szSteamID[32], szName[32], szSteamID2[32], szName2[32];

	read_argv(1, szArg, charsmax(szArg));
	read_argv(2, szArg2, charsmax(szArg2));

	new player = cmd_target(id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
	
	if(!player) return PLUGIN_HANDLED;

	get_user_authid(id, szSteamID, charsmax(szSteamID));
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(player, szSteamID2, charsmax(szSteamID2));
	get_user_name(player, szName2, charsmax(szName2));

	bChange[player] = true;

	set_user_info(player, "name", szArg2);
	client_cmd(player, "name ^"%s^"", szArg2);

	log_amx("Cmd: ^"%s<%d><%s><>^" change nick to ^"%s^" ^"%s<%d><%s><>^"", szName, get_user_userid(id), szSteamID, szArg2, szName2, get_user_userid(player), szSteamID2);

	console_print(id, "[AMXX] %L", id, "CHANGED_NICK", szName2, szArg2);

	return PLUGIN_HANDLED;
}

public GameDesc()
{
	forward_return(FMV_STRING, "CS-Reload.pl"); 
	
	return FMRES_SUPERCEDE; 
}

public Message()
{
	static szMessage[32];
	get_msg_arg_string(2, szMessage, charsmax(szMessage));

	if(containi(szMessage, "name") !=- 1) return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public CheckSay(id)
{ 
	static szMessage[190];
	
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);

	if(contain(szMessage, "#" ) != -1) return PLUGIN_HANDLED;

	if(CheckPhrase(id, szMessage, 2)) return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public CheckPhrase(id, szPhrase[], iMethod)
{
	if(bBanned[id]) return 1;

	for(new i = 0; i < sizeof(szWhiteList); i++) if(containi(szPhrase, szWhiteList[i]) != -1) return 0;

	for(new i = 0; i < sizeof(szBlackList); i++)
	{
		if(containi(szPhrase, szBlackList[i]) != -1 && is_user_connected(id))
		{
			bBanned[id] = true;
			
			server_cmd("amx_kick #%d ^"Zostales ZBANOWANY!^";  wait; addip 5.0 %s", get_user_userid(id), szPlayersIP[id]);
			
			switch(iMethod)
			{
				case 0:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[client_connect] %s - zablokowanana fraza w nicku.", szPhrase);
				case 1:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[client_infochanged] %s - zablokowana fraza w nicku.", szPhrase);
				case 2:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[say] %s - zablokowanna fraza w wiadomosci.", szPhrase);
			}
			
			return 1;
		}
	}
	
	new szError[64], iReturnValue, Regex:rResult = regex_match(szPhrase, szPatern, iReturnValue, szError, charsmax(szError));
	
	switch(rResult) 
	{
		case REGEX_MATCH_FAIL, REGEX_PATTERN_FAIL, REGEX_NO_MATCH: return 0;
		default: 
		{
			bBanned[id] = true;
			
			regex_free(rResult);
			
			if(is_user_connected(id))
			{	
				server_cmd("amx_kick #%d ^"Zostales ZBANOWANY!^";  wait; addip 5.0 %s", get_user_userid(id), szPlayersIP[id]);
			
				switch(iMethod)
				{
					case 0:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[client_connect] %s - zablokowany adres IP w nicku.", szPhrase);
					case 1:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[client_infochanged] %s - zablokowany adres IP w nicku.", szPhrase);
					case 2:	log_to_file("addons/amxmodx/logs/ozone_security.txt", "[say] %s - zablokowany adres IP w wiadomosci.", szPhrase);
				}
			
				return 1;
			}
		}
	}
	
	return 0;
}

#if defined KEY_DETECTOR
public PrintInfo(id, key)
{
	if(bInfoPrinted[id]) return;

	new szPlayerName[32], szKey[32];
	
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	
	switch(key)
	{
		case DEL: formatex(szKey, charsmax(szKey), "DEL");
		case INS: formatex(szKey, charsmax(szKey), "INSERT");
		case END: formatex(szKey, charsmax(szKey), "END");
		case PGUP: formatex(szKey, charsmax(szKey), "PAGEUP");
		case PGDN: formatex(szKey, charsmax(szKey), "PAGEDOWN");
		case F10: formatex(szKey, charsmax(szKey), "F10");
		case F11: formatex(szKey, charsmax(szKey), "F11");
		case F12: formatex(szKey, charsmax(szKey), "F12");
	}
	
	for (new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i) || is_user_bot(i) || !(get_user_flags(i) & ADMIN_BAN)) continue;
		
		client_print_color(i, print_team_red, "^x03[INFO]^x01 Gracz^x04 %s^x01 wlasnie uzyl klawisza^x04 %s^x01.", szPlayerName, szKey);
	}
	
	bInfoPrinted[id] = true;
	
	set_task(0.3, "ResetInfo", id);
}

public ResetInfo(id)
	bInfoPrinted[id] = false;

public BindCheck1(id)
{
	PrintInfo(id, DEL);
	
	return PLUGIN_HANDLED;
}
	
public BindCheck2(id)
{
	PrintInfo(id, INS);
	
	return PLUGIN_HANDLED;
}

public BindCheck3(id)
{
	PrintInfo(id, END);
	
	return PLUGIN_HANDLED;
}

public BindCheck4(id)
{
	PrintInfo(id, PGUP);
	
	return PLUGIN_HANDLED;
}
	
public BindCheck5(id)
{
	PrintInfo(id, PGDN);
	
	return PLUGIN_HANDLED;
}

public BindCheck6(id)
{
	PrintInfo(id, F10);
	
	return PLUGIN_HANDLED;
}
	
public BindCheck7(id)
{
	PrintInfo(id, F11);
	
	return PLUGIN_HANDLED;
}
	
public BindCheck8(id)
{
	PrintInfo(id, F12);
	
	return PLUGIN_HANDLED;
}
#endif
	
public CheckBanid(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN)) 
	{
		console_print(id, "[BANID] Brak uprawnien!");
		
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szTempID[2], szPlayers[32], iNum, iPlayer, menu = menu_create("Wybierz\r Gracza\y, ktorego chcesz sprawdzic na Banid.pl:", "CheckBanid_Handle");
	
	get_players(szPlayers, iNum);
	
	for(new i = 0; i < iNum; i++)
	{
		if(is_user_connected(szPlayers[i]) && !is_user_bot(szPlayers[i]) && !is_user_hltv(szPlayers[i]))
		{
			iPlayer = szPlayers[i];
			
			get_user_name(iPlayer, szName, charsmax(szName));

			num_to_str(iPlayer, szTempID, charsmax(szTempID));
			
			menu_additem(menu, szName, szTempID, 0);
		}
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public CheckBanid_Handle(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szTemp[128], szSteamID[32], szData[2], iPlayer, iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	iPlayer = str_to_num(szData);
	
	get_user_authid(iPlayer, szSteamID, charsmax(szSteamID));
	
	formatex(szTemp, charsmax(szTemp), "http://banid.pl/kto?to=%s", szSteamID);
	
	show_motd(id, szTemp, "Banid.pl");
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public ShowStatus(id)
{	
	new szServerName[64], szServerIP[32], szServerMap[32], szPlayers[32], szName[32], szSteamID[32], szIP[32], iPlayer, iNum;
	
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

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		
		if(is_user_bot(iPlayer) || is_user_hltv(iPlayer)) continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		get_user_ip(iPlayer, szIP, charsmax(szIP), 1);
		if(get_user_flags(iPlayer) & ADMIN_BAN) formatex(szIP, charsmax(szIP), "Ukryte");
		get_user_authid(iPlayer, szSteamID, charsmax(szSteamID));
		
		console_print(id,"#%d  %s  %s  %s  %s  %s", i + 1, i < 10 ? "" : " ", szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
	}
	
	console_print(id, "---------------------------------------------------------------------");
	
	return PLUGIN_HANDLED;
}

public ShowStatusMOTD(id)
{	
	new szBuffer[2048], szPlayers[32], szName[32], szSteamID[32], szIP[32], iPlayer, iNum, iLen;
	
	get_players(szPlayers, iNum);
	
	iLen = format(szBuffer, charsmax(szBuffer), "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "%1s %-25.22s %17s %15s %20s^n", "ID", "Nick", "IP", "SteamID", "Typ");

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = szPlayers[i];
		
		if(is_user_bot(iPlayer) || is_user_hltv(iPlayer)) continue;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		get_user_ip(iPlayer, szIP, charsmax(szIP), 1);
		get_user_authid(iPlayer, szSteamID, charsmax(szSteamID));
		
		if(iPlayer >= 10) iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "#%i %-20.22s %18s %18s %18s^n", iPlayer, szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
		else iLen += format(szBuffer[iLen], charsmax(szBuffer) - iLen, "#%i  %-20.22s %18s %18s %18s^n", iPlayer, szName, szIP, szSteamID, is_user_steam(szSteamID) ? "Steam" : "Non Steam");
	}

	show_motd(id, szBuffer, "Informacje o Graczach");
	
	return PLUGIN_HANDLED;
}

public ShowContactMOTD(id)
	show_motd(id, "kontakt.txt", "Kontakt CS-Reload.pl");

stock bool:is_user_steam(szSteamID[]) 
	return bool:(contain(szSteamID, "STEAM_0:0:") != -1 || contain(szSteamID, "STEAM_0:1:") != -1);

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
		new szMessage[256];

		format_args(szMessage ,charsmax(szMessage), 1);

		message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
		write_byte(strlen(szMessage) + 2);
		write_byte(10);
		write_string(szMessage);
		message_end();
    }
}