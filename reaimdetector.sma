#include <amxmodx>
#include <reaimdetector>

#pragma semicolon 1

#if !defined MAX_PLAYERS
	#define MAX_PLAYERS	32
#endif

#if defined client_disconnected
	#define player_disconnect client_disconnected
#else
	#define player_disconnect client_disconnect
#endif

#define ENABLE_LOG_FILE					// Включить логирование
#define RELOAD_CMD 		ADMIN_CFG		// Флаг доступа к команде перезагрузки конфига: reaim_reloadcfg
#define MENU_CMD 			ADMIN_BAN		// Флаг доступа к Aim меню: say /aim

enum CfgType
{
	AIM = 1,
	SPREAD,
	PUNISH,
	SAVE,
	OTHER
}

#if (AMXX_VERSION_NUM < 183)

	enum
	{
		print_team_default = 0,
		print_team_grey = -1,
		print_team_red = -2,
		print_team_blue = -3
	};

	#define replace_string replace_all

#endif

new Trie:g_tAimBotSteamWarns, Trie:g_tAimBotIpWarns;
new Trie:g_tNoSpreadSteamWarns, Trie:g_tNoSpreadIpWarns;

new g_iAimDetection, g_iAimSens, g_iAimMultiWarn, g_iAimNotify, g_iAimMaxWarns, g_iAimShotsReset, g_iAimKillsReset, g_iAimTimeReset;
new g_iSaveType, g_iAimSaveWarns, g_iSpreadSaveWarns;
new g_iSpreadDetection, g_iSpreadNotify, g_iSpreadMaxWarns;
new g_iAlertFlag;
new g_iSendProtectionWeapon;
new g_iCrashCheat;
new g_iBanTime[PunishType];
new g_szBanReason[PunishType][64];
new g_szBanString[PunishType][128];

#if defined ENABLE_LOG_FILE
	new g_FilePath[64], g_LogDir[128];
#endif

public plugin_init()
{
	register_plugin("ReAimDetector API", REAIMDETECTOR_VERSION, "ReHLDS Team");

	register_concmd("reaim_reloadcfg", "ReloadCfg", RELOAD_CMD);

	register_clcmd("say /aim", "AimMenu", MENU_CMD);
	register_clcmd("say_team /aim", "AimMenu", MENU_CMD);

	g_tAimBotSteamWarns = TrieCreate();
	g_tAimBotIpWarns = TrieCreate();
	g_tNoSpreadSteamWarns = TrieCreate();
	g_tNoSpreadIpWarns = TrieCreate();
}

public plugin_end()
{

#if defined ENABLE_LOG_FILE
	new Map[32], BufLog[64];
	get_mapname(Map, charsmax(Map));
	formatex(BufLog, charsmax(BufLog), "End Map [%s]", Map);
	SaveLogFile(BufLog);
#endif

	TrieClear(g_tAimBotSteamWarns);
	TrieClear(g_tAimBotIpWarns);
	TrieClear(g_tNoSpreadSteamWarns);
	TrieClear(g_tNoSpreadIpWarns);
}

public client_putinserver(id)
{
	switch(g_iSaveType)
	{
		case 1:
		{
			new szSteam[33], iWarns;
			get_user_authid(id, szSteam, charsmax(szSteam));

#if defined ENABLE_LOG_FILE
			new szBufLog[190], szAddress[17], szName[32];
			get_user_ip(id, szAddress, charsmax(szAddress), 1);
			get_user_name(id, szName, charsmax(szName));
#endif

			if(TrieKeyExists(g_tAimBotSteamWarns, szSteam))
			{
				TrieGetCell(g_tAimBotSteamWarns, szSteam, iWarns);
				TrieDeleteKey(g_tAimBotSteamWarns, szSteam);

				ad_set_client(id, AimWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "Aim Warn Recovered (Steam): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}

			if(TrieKeyExists(g_tNoSpreadSteamWarns, szSteam))
			{
				TrieGetCell(g_tNoSpreadSteamWarns, szSteam, iWarns);
				TrieDeleteKey(g_tNoSpreadSteamWarns, szSteam);

				ad_set_client(id, NoSpreadWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "NoSpread Warn Recovered (Steam): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}
		}
		case 2:
		{
			new szAddress[17], iWarns;
			get_user_ip(id, szAddress, charsmax(szAddress), 1);

#if defined ENABLE_LOG_FILE
			new szBufLog[190], szSteam[33], szName[32];
			get_user_authid(id, szSteam, charsmax(szSteam));
			get_user_name(id, szName, charsmax(szName));
#endif

			if(TrieKeyExists(g_tAimBotIpWarns, szAddress))
			{
				TrieGetCell(g_tAimBotIpWarns, szAddress, iWarns);
				TrieDeleteKey(g_tAimBotIpWarns, szAddress);

				ad_set_client(id, AimWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "Aim Warn Recovered (IP): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}

			if(TrieKeyExists(g_tNoSpreadIpWarns, szAddress))
			{
				TrieGetCell(g_tNoSpreadIpWarns, szAddress, iWarns);
				TrieDeleteKey(g_tNoSpreadIpWarns, szAddress);

				ad_set_client(id, NoSpreadWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "NoSpread Warn Recovered (IP): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}
		}
		case 3:
		{
			new szSteam[33], szAddress[17], iWarns;
			get_user_authid(id, szSteam, charsmax(szSteam));
			get_user_ip(id, szAddress, charsmax(szAddress), 1);

#if defined ENABLE_LOG_FILE
			new szBufLog[190], szName[32];
			get_user_name(id, szName, charsmax(szName));
#endif

			new bool:IsExistsAim = false;
			new bool:IsExistsSpread = false;

			if(TrieKeyExists(g_tAimBotSteamWarns, szSteam))
			{
				IsExistsAim = true;

				TrieGetCell(g_tAimBotSteamWarns, szSteam, iWarns);
				TrieDeleteKey(g_tAimBotSteamWarns, szSteam);

				ad_set_client(id, AimWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "Aim Warn Recovered (Steam): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}

			if(TrieKeyExists(g_tAimBotIpWarns, szAddress))
			{
				if(IsExistsAim)
				{
					TrieDeleteKey(g_tAimBotIpWarns, szAddress);
				}
				else
				{
					TrieGetCell(g_tAimBotIpWarns, szAddress, iWarns);
					TrieDeleteKey(g_tAimBotIpWarns, szAddress);

					ad_set_client(id, AimWarn, iWarns);

#if defined ENABLE_LOG_FILE
					formatex(szBufLog, charsmax(szBufLog), "Aim Warn Recovered (IP): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
					SaveLogFile(szBufLog);
#endif

				}
			}

			if(TrieKeyExists(g_tNoSpreadSteamWarns, szSteam))
			{
				IsExistsSpread = true;

				TrieGetCell(g_tNoSpreadSteamWarns, szSteam, iWarns);
				TrieDeleteKey(g_tNoSpreadSteamWarns, szSteam);

				ad_set_client(id, NoSpreadWarn, iWarns);

#if defined ENABLE_LOG_FILE
				formatex(szBufLog, charsmax(szBufLog), "NoSpread Warn Recovered (Steam): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
				SaveLogFile(szBufLog);
#endif

			}

			if(TrieKeyExists(g_tNoSpreadIpWarns, szAddress))
			{
				if(IsExistsSpread)
				{
					TrieDeleteKey(g_tNoSpreadIpWarns, szAddress);
				}
				else
				{
					TrieGetCell(g_tNoSpreadIpWarns, szAddress, iWarns);
					TrieDeleteKey(g_tNoSpreadIpWarns, szAddress);

					ad_set_client(id, NoSpreadWarn, iWarns);

#if defined ENABLE_LOG_FILE
					formatex(szBufLog, charsmax(szBufLog), "NoSpread Warn Recovered (IP): ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", id, szName, szSteam, szAddress, iWarns);
					SaveLogFile(szBufLog);
#endif

				}
			}
		}
	}
}

public player_disconnect(id)
{
	switch(g_iSaveType)
	{
		case 1:
		{
			new szSteam[33];
			get_user_authid(id, szSteam, charsmax(szSteam));

			new iAimBotWarns = ad_get_client(id, AimWarn);
			new iNoSpreadWarns = ad_get_client(id, NoSpreadWarn);

			if(iAimBotWarns >= g_iAimSaveWarns)
			{
				TrieSetCell(g_tAimBotSteamWarns, szSteam, iAimBotWarns);
			}

			if(iNoSpreadWarns >= g_iSpreadSaveWarns)
			{
				TrieSetCell(g_tNoSpreadSteamWarns, szSteam, iNoSpreadWarns);
			}
		}
		case 2:
		{
			new szAddress[17];
			get_user_ip(id, szAddress, charsmax(szAddress), 1);

			new iAimBotWarns = ad_get_client(id, AimWarn);
			new iNoSpreadWarns = ad_get_client(id, NoSpreadWarn);

			if(iAimBotWarns >= g_iAimSaveWarns)
			{
				TrieSetCell(g_tAimBotIpWarns, szAddress, iAimBotWarns);
			}

			if(iNoSpreadWarns >= g_iSpreadSaveWarns)
			{
				TrieSetCell(g_tNoSpreadIpWarns, szAddress, iNoSpreadWarns);
			}
		}
		case 3:
		{
			new szSteam[33], szAddress[17];
			get_user_authid(id, szSteam, charsmax(szSteam));
			get_user_ip(id, szAddress, charsmax(szAddress), 1);

			new iAimBotWarns = ad_get_client(id, AimWarn);
			new iNoSpreadWarns = ad_get_client(id, NoSpreadWarn);

			if(iAimBotWarns >= g_iAimSaveWarns)
			{
				TrieSetCell(g_tAimBotSteamWarns, szSteam, iAimBotWarns);
				TrieSetCell(g_tAimBotIpWarns, szAddress, iAimBotWarns);
			}

			if(iNoSpreadWarns >= g_iSpreadSaveWarns)
			{
				TrieSetCell(g_tNoSpreadSteamWarns, szSteam, iNoSpreadWarns);
				TrieSetCell(g_tNoSpreadIpWarns, szAddress, iNoSpreadWarns);
			}
		}
	}
}

public ReloadCfg(id, level, cid)
{
	if(~get_user_flags(id) & level) {
		return PLUGIN_CONTINUE;
	}

	ReadCfg();

	client_print(id, print_console, "[Aim Detector]: Reload Cfg.");

	return PLUGIN_HANDLED;
}

public AimMenu(id, level)
{
	if(~get_user_flags(id) & level) {
		return PLUGIN_CONTINUE;
	}

	static iPlayers[32], iNum, i, iPlayer;
	get_players(iPlayers, iNum, "ch");

	new szName[32], szInfo[3], szTempString[96];
	new iMenu = menu_create("\wAim Detector Menu", "AimMenuHandler");

	new bool:bFindPlayer = false;

	for(i = 0; i < iNum; i++) 
	{
		iPlayer = iPlayers[i];

		new iAimBotWarns = ad_get_client(iPlayer, AimWarn);
		new iNoSpreadWarns = ad_get_client(iPlayer, NoSpreadWarn);

		if(iAimBotWarns == 0 && iNoSpreadWarns == 0) {
			continue;
		}

		bFindPlayer = true;

		get_user_name(iPlayer, szName, charsmax(szName));

		formatex(szTempString, charsmax(szTempString), "\w%s \r[\yAim\r: \w%d\r|\yNoSpread\r: \w%d\r]", szName, iAimBotWarns, iNoSpreadWarns);

		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(iMenu, szTempString, szInfo);
	}

	if(bFindPlayer)
	{
		menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r");
		menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL);
		menu_setprop(iMenu, MPROP_EXITNAME, "Exit");
		menu_setprop(iMenu, MPROP_NEXTNAME, "Next");
		menu_setprop(iMenu, MPROP_BACKNAME, "Back");
	
		menu_display(id, iMenu);
	}
	else
	{
		new szBufNotify[190];
		formatex(szBufNotify, charsmax(szBufNotify), "^1[^4Aim Detector^1] ^3There are no players with any Aim/NoSpread warnings^1.");
		client_print_color(id, print_team_default, szBufNotify);
	}

	return PLUGIN_HANDLED;
}

public AimMenuHandler(id, menu, item) 
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new iAccess, szInfo[3], iCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), .callback = iCallback);

	new iPlayer = str_to_num(szInfo);

	new iAimWarn = ad_get_client(iPlayer, AimWarn);
	new iSpreadWarn = ad_get_client(iPlayer, NoSpreadWarn);

	new szBufNotify[190], szName[32];
	get_user_name(iPlayer, szName, charsmax(szName));

	formatex(szBufNotify, charsmax(szBufNotify), "^1[^4Aim Detector^1] ^3Name ^1[^4 %s ^1] ^3AimWarn ^1[^4 %d ^1] ^3NoSpreadWarn ^1[^4 %d ^1]", szName, iAimWarn, iSpreadWarn);
	client_print_color(id, print_team_default, szBufNotify);

	return PLUGIN_HANDLED;
}

public ad_init(const Version[], const Map[])
{

#if defined ENABLE_LOG_FILE
	get_localinfo("amxx_logs", g_FilePath, charsmax(g_FilePath));
	formatex(g_LogDir, charsmax(g_LogDir), "%s/reaimdetector", g_FilePath);

	if(!dir_exists(g_LogDir))
	{
		mkdir(g_LogDir);
	}
#endif

	ReadCfg();

#if defined ENABLE_LOG_FILE
	new szBufLog[190];
	formatex(szBufLog, charsmax(szBufLog), "Start Map [%s] AimSens [%d] AimMaxWarns [%d] NoSpreadNotifyWarns [%d] NoSpreadMaxWarns [%d]",
		Map, ad_get_cfg(AimSens), g_iAimMaxWarns, ad_get_cfg(NoSpreadNotifyWarns), g_iSpreadMaxWarns);

	SaveLogFile(szBufLog);
#endif

}

public ad_notify(const index, const PunishType:pType, const NotifyType:nType, const Kills, const Shots, const Warn)
{
	new szBufNotify[190], szName[32];

#if defined ENABLE_LOG_FILE
	new szBufLog[190], szAddress[22], szSteam[33];

	get_user_ip(index, szAddress, charsmax(szAddress));
	get_user_authid(index, szSteam, charsmax(szSteam));
#endif

	get_user_name(index, szName, charsmax(szName));

	if(pType == AIMBOT)
	{
		if(nType == WARNING && Warn > g_iAimNotify)
		{
			formatex(szBufNotify, charsmax(szBufNotify), "^1[^4Aim Detector^1] ^3Name ^1[^4 %s ^1] ^3Warn ^1[^4 %d ^1] ^3MaxWarn ^1[^4 %d ^1]", szName, Warn, g_iAimMaxWarns);
			Send_Notify_Admins(index, szBufNotify);

#if defined ENABLE_LOG_FILE
			formatex(szBufLog, charsmax(szBufLog), "Aim Warn Add: ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", index, szName, szSteam, szAddress, Warn);
			SaveLogFile(szBufLog);
#endif

		}
		else if(nType == DETECT)
		{
			formatex(szBufNotify, charsmax(szBufNotify), "^1[^4Aim Detector^1] ^3Name ^1[^4 %s ^1] ^3Detected", szName);
			Send_Notify_Admins(index, szBufNotify);

#if defined ENABLE_LOG_FILE
			formatex(szBufLog, charsmax(szBufLog), "Aim Detected: ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", index, szName, szSteam, szAddress, Warn);
			SaveLogFile(szBufLog);
#endif

			ad_set_client(index, AimCheck, 0);

			PunishPlayer(index, AIMBOT);
		}
	}
	else if(pType == NOSPREAD)
	{
		if(nType == WARNING && Warn > g_iSpreadNotify)
		{
			formatex(szBufNotify, charsmax(szBufNotify), "^1[^4NoSpread Detector^1] ^3Name ^1[^4 %s ^1] ^3Warn ^1[^4 %d ^1]", szName, Warn, g_iSpreadMaxWarns);
			Send_Notify_Admins(index, szBufNotify);

#if defined ENABLE_LOG_FILE
			formatex(szBufLog, charsmax(szBufLog), "NoSpread Warn Add: ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", index, szName, szSteam, szAddress, Warn);
			SaveLogFile(szBufLog);
#endif

		}
		else if(nType == DETECT)
		{
			formatex(szBufNotify, charsmax(szBufNotify), "^1[^4NoSpread Detector^1] ^3Name ^1[^4 %s ^1] ^3Detected", szName);
			Send_Notify_Admins(index, szBufNotify);

#if defined ENABLE_LOG_FILE
			formatex(szBufLog, charsmax(szBufLog), "NoSpread Detected: ID [%d] Name [%s] Steam [%s] IP [%s] Warn [%d]", index, szName, szSteam, szAddress, Warn);
			SaveLogFile(szBufLog);
#endif

			ad_set_client(index, NoSpreadCheck, 0);

			PunishPlayer(index, NOSPREAD);
		}
	}
}

#if defined ENABLE_LOG_FILE
	public ad_aim_reset_warn(const index, const ResetType:rType, const Kills, const Shots)
	{
		new szBufLog[190], szName[32], szAddress[22], szSteam[33];

		get_user_name(index, szName, charsmax(szName));
		get_user_ip(index, szAddress, charsmax(szAddress));
		get_user_authid(index, szSteam, charsmax(szSteam));

		switch(rType)
		{
			case KILLED:
			{
				formatex(szBufLog, charsmax(szBufLog), "Killed Reset: ID [%d] Name [%s] Steam [%s] IP [%s] Kills [%d] Shots [%d]", index, szName, szSteam, szAddress, Kills + 1, Shots);
				SaveLogFile(szBufLog);
			}
			case SHOTS:
			{
				formatex(szBufLog, charsmax(szBufLog), "Shots Reset: ID [%d] Name [%s] Steam [%s] IP [%s] Kills [%d] Shots [%d]", index, szName, szSteam, szAddress, Kills, Shots + 1);
				SaveLogFile(szBufLog);
			}
			case TIME:
			{
				formatex(szBufLog, charsmax(szBufLog), "Time Reset: ID [%d] Name [%s] Steam [%s] IP [%s] Kills [%d] Shots [%d]", index, szName, szSteam, szAddress, Kills, Shots);
				SaveLogFile(szBufLog);
			}
		}
	}
#endif

stock ReadCfg()
{
	new szFilePath[64];
	get_localinfo("amxx_configsdir", szFilePath, charsmax(szFilePath));
	formatex(szFilePath, charsmax(szFilePath), "%s/reaimdetector.ini", szFilePath);

	new FileHandle = fopen(szFilePath, "rt");

	if(!FileHandle)
	{
		set_fail_state("Error load cfg.");
	}

	new szTemp[256], szKey[32], szValue[512], iSection;

	while(!feof(FileHandle))
	{
		fgets(FileHandle, szTemp, charsmax(szTemp));
		trim(szTemp);

		if (szTemp[0] == '[')
		{
			iSection++;
			continue;
		}

		if(!szTemp[0] || szTemp[0] == ';' || szTemp[0] == '/') {
			continue;
		}

		strtok(szTemp, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
		trim(szKey);
		trim(szValue);

		switch(iSection)
		{
			case AIM:
			{
				if(equal(szKey, "AIM_DETECTION"))
					g_iAimDetection = str_to_num(szValue);

				else if(equal(szKey, "SENS"))
					g_iAimSens = str_to_num(szValue);

				else if(equal(szKey, "MULTI_WARN"))
					g_iAimMultiWarn = str_to_num(szValue);

				else if(equal(szKey, "NOTIFY_WARNS"))
					g_iAimNotify = str_to_num(szValue);

				else if(equal(szKey, "MAX_WARNS"))
					g_iAimMaxWarns = str_to_num(szValue);

				else if(equal(szKey, "SHOTS_RESET"))
					g_iAimShotsReset = str_to_num(szValue);
	
				else if(equal(szKey, "KILLS_RESET"))
					g_iAimKillsReset = str_to_num(szValue);

				else if(equal(szKey, "TIME_RESET"))
					g_iAimTimeReset = str_to_num(szValue);
			}
			case SPREAD:
			{
				if(equal(szKey, "NOSPREAD_DETECTION"))
					g_iSpreadDetection = str_to_num(szValue);

				else if(equal(szKey, "NOTIFY_WARNS"))
					g_iSpreadNotify = str_to_num(szValue);

				else if(equal(szKey, "MAX_WARNS"))
					g_iSpreadMaxWarns = str_to_num(szValue);
			}
			case PUNISH:
			{
				if(equal(szKey, "REASON_AIMBOT"))
					copy(g_szBanReason[AIMBOT], charsmax(g_szBanReason[]), szValue);

				else if(equal(szKey, "BAN_TIME_AIMBOT"))
					g_iBanTime[AIMBOT] = str_to_num(szValue);

				else if(equal(szKey, "REASON_NOSPREAD"))
					copy(g_szBanReason[NOSPREAD], charsmax(g_szBanReason[]), szValue);

				else if(equal(szKey, "BAN_TIME_NOSPREAD"))
					g_iBanTime[NOSPREAD]  = str_to_num(szValue);

				else if(equal(szKey, "PUNISH_AIMBOT"))
					copy(g_szBanString[AIMBOT], charsmax(g_szBanString[]), szValue);

				else if(equal(szKey, "PUNISH_NOSPREAD"))
					copy(g_szBanString[NOSPREAD], charsmax(g_szBanString[]), szValue);

			}
			case SAVE:
			{
				if(equal(szKey, "TYPE"))
					g_iSaveType = str_to_num(szValue);

				else if(equal(szKey, "AIM_WARNS"))
					g_iAimSaveWarns = str_to_num(szValue);

				else if(equal(szKey, "NOSPREAD_WARNS"))
					g_iSpreadSaveWarns = str_to_num(szValue);
			}
			case OTHER:
			{
				if(equal(szKey, "FLAG_ALERT"))
				{
					new szFlags[21];
					copy(szFlags, charsmax(szFlags), szValue);

					g_iAlertFlag = read_flags(szFlags);
				}

				else if(equal(szKey, "SEND_PROTECTION_WEAPON"))
					g_iSendProtectionWeapon = str_to_num(szValue);

				else if(equal(szKey, "CRASH_CHEAT"))
					g_iCrashCheat = str_to_num(szValue);
			}
		}
	}

	fclose(FileHandle);

	SetCfg();

	return PLUGIN_CONTINUE;
}

stock SetCfg()
{
	ad_set_cfg(AimDetection, g_iAimDetection);
	ad_set_cfg(AimSens, g_iAimSens);
	ad_set_cfg(AimMultiWarns, g_iAimMultiWarn);
	ad_set_cfg(AimNotifyWarns, g_iAimNotify);
	ad_set_cfg(AimMaxWarns, g_iAimMaxWarns);
	ad_set_cfg(AimShotsReset, g_iAimShotsReset);
	ad_set_cfg(AimKillsReset, g_iAimKillsReset);
	ad_set_cfg(AimTimeReset, g_iAimTimeReset);
	ad_set_cfg(NoSpreadDetection, g_iSpreadDetection);
	ad_set_cfg(NoSpreadNotifyWarns, g_iSpreadNotify);
	ad_set_cfg(NoSpreadMaxWarns, g_iSpreadMaxWarns);
	ad_set_cfg(SendProtectionWeapon, g_iSendProtectionWeapon);
	ad_set_cfg(CrashCheat, g_iCrashCheat);
}

stock PunishPlayer(id, PunishType:iType)
{
	new szUserId[10], szSteam[33], szIp[17], szTime[10], szBanString[128];

	formatex(szUserId, charsmax(szUserId), "#%d", get_user_userid(id));

	get_user_authid(id, szSteam, charsmax(szSteam));
	get_user_ip(id, szIp, charsmax(szIp), 1);

	num_to_str(g_iBanTime[iType], szTime, charsmax(szTime));

	copy(szBanString, charsmax(szBanString), g_szBanString[iType]);

	replace_string(szBanString, charsmax(szBanString), "[userid]", szUserId);
	replace_string(szBanString, charsmax(szBanString), "[steam]", szSteam);
	replace_string(szBanString, charsmax(szBanString), "[ip]", szIp);
	replace_string(szBanString, charsmax(szBanString), "[reason]", g_szBanReason[iType]);
	replace_string(szBanString, charsmax(szBanString), "[time]", szTime);

	server_cmd("%s", szBanString);
}

stock Send_Notify_Admins(const NotifyIndex, const Msg[])
{
	new Players[MAX_PLAYERS], iNum, iReceiver;
	get_players(Players, iNum, "ch");

	for (new i = 0; i < iNum; ++i)
	{
		iReceiver = Players[i];

		if(NotifyIndex == iReceiver || !(get_user_flags(iReceiver) & g_iAlertFlag)) {
			continue;
		}

		client_print_color(iReceiver, print_team_default, Msg);
	}
}

#if defined ENABLE_LOG_FILE
	stock SaveLogFile(const LogText[])
	{
		new LogFileTime[32], LogTime[32], LogFile[128], LogMsg[190];

		get_time("20%y.%m.%d", LogFileTime, charsmax(LogFileTime));
		get_time("%H:%M:%S", LogTime, charsmax(LogTime));

		formatex(LogFile, charsmax(LogFile), "%s/%s.log", g_LogDir, LogFileTime);
		formatex(LogMsg, charsmax(LogMsg), "[%s] [%s] %s", LogFileTime, LogTime, LogText);

		write_file(LogFile, LogMsg, -1);
	}
#endif

#if (AMXX_VERSION_NUM < 183)
	stock client_print_color(const id, const iSender, const input[], any:...)
	{
		static iSayText = 0;
		if (!iSayText) {
			iSayText = get_user_msgid("SayText");
		}
		new iReceiver, iNum = 1, Players[MAX_PLAYERS], Msg[190];
		vformat(Msg, charsmax(Msg), input, 3);
		if(id)
		{
			if(!is_user_connected(id)) {
				return;
			}
			Players[0] = id;
		} else {
			get_players(Players, iNum, "ch");
		}
		for (new i = 0; i < iNum; i++)
		{
			iReceiver = Players[i];
			message_begin(MSG_ONE, iSayText , _, iReceiver);
			write_byte(iSender ? iSender : iReceiver);
			write_string(Msg);
			message_end();
		}
	}
#endif