#include <amxmodx>
#include <hamsandwich>
#include <csx>
#include <fakemeta>
#include <sqlx>

#define PLUGIN "Weapon Sets"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define is_user_player(%1) 1 <= %1 <= iMaxClients

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

#define TASK_LOAD 3045
#define MAX_PLAYERS 32
#define WYLACZONE -1

#define SKLEPSMS

#if defined SKLEPSMS
#include <shop_sms>
#endif

enum _:WeaponSet
{
	SetName[64],
	SetKills,
	SetDamage,
	SetM4A1[64],
	SetAK47[64],
	SetAWP[64],
};

new szName[MAX_PLAYERS + 1][64], iWeaponSet[MAX_PLAYERS + 1], Array:aPlayerWeaponSets[MAX_PLAYERS + 1], 
Array:aWeaponSets, Handle:hSqlHook, bool:bSql, bool:bFile, iMaxClients, iLoaded;

native stats_get_kills(id);

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("weaponsets_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("weaponsets_sql_user", "298272", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("weaponsets_sql_pass", "fNhrZmHuOortS7C2", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("weaponsets_sql_db", "298272_weaponsets", FCVAR_SPONLY|FCVAR_PROTECTED);

	register_clcmd("say /bronie", "ShowMotd");
	register_clcmd("say /wymagania", "ShowMotd");
	
	register_clcmd("say /skin", "ChangeWeaponSet");
	register_clcmd("say /skiny", "ChangeWeaponSet");
	register_clcmd("say /modele", "ChangeWeaponSet");
	register_clcmd("say /zestaw", "ChangeWeaponSet");
	register_clcmd("say /zestawy", "ChangeWeaponSet");
	register_clcmd("say_team /skin", "ChangeWeaponSet");
	register_clcmd("say_team /skiny", "ChangeWeaponSet");
	register_clcmd("say_team /modele", "ChangeWeaponSet");
	register_clcmd("say_team /zestaw", "ChangeWeaponSet");
	register_clcmd("say_team /zestawy", "ChangeWeaponSet");
	
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "M4A1Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "AK47Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_awp", "AWPModel", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	
	iMaxClients = get_maxplayers();
}	

#if defined SKLEPSMS
public plugin_natives()
	set_native_filter("native_filter");
#endif

public plugin_precache() 
{
	for(new i = 1; i < MAX_PLAYERS + 1; i++) aPlayerWeaponSets[i] = ArrayCreate();
	
	aWeaponSets = ArrayCreate(WeaponSet);
	
	new szFile[128]; 
	
	get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
	format(szFile, charsmax(szFile), "%s/zestawy_broni.ini", szFile);
	
	if(!file_exists(szFile)) set_fail_state("[ZESTAWY] Brak pliku zestawy_broni.ini!");
	
	new aData[WeaponSet], szContent[256], szValue[64], szKey[1], bool:iError, iSection, iOpen = fopen(szFile, "r");
	
	while(!feof(iOpen))
	{
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
		if(szContent[0] == ';' || szContent[0] == '^0' || szContent[0] == '/') continue;
		
		if(szContent[0] == '[') 
		{ 
			iSection = 0; 
			
			aData[SetKills] = 0;
			aData[SetDamage] = 0;
			aData[SetM4A1] = "";
			aData[SetAK47] = "";
			aData[SetAWP] = "";
			
			parse(szContent, aData[SetName], charsmax(aData[SetName]));
			
			replace_all(aData[SetName], charsmax(aData[SetName]), "[", "");
			replace_all(aData[SetName], charsmax(aData[SetName]), "]", "");
			
			continue; 
		}
		
		strtok(szContent, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');

		trim(szValue);
		
		if(iSection > 1)
		{
			if(!file_exists(szValue))
			{
				log_to_file("addons/amxmodx/logs/zestawy_broni.log", "[ZESTAWY] Plik %s nie istnieje!", szValue);
			
				iError = true;
			}
			else precache_model(szValue);
		}
		
		switch(iSection)
		{
			case 0: aData[SetKills] = str_to_num(szValue);
			case 1: aData[SetDamage] = str_to_num(szValue);
			case 2: formatex(aData[SetM4A1], charsmax(aData[SetM4A1]), szValue);
			case 3: formatex(aData[SetAK47], charsmax(aData[SetAK47]), szValue);
			case 4: 
			{
				formatex(aData[SetAWP], charsmax(aData[SetAWP]), szValue);
				
				ArrayPushArray(aWeaponSets, aData);
			}
		}
		
		iSection++;
	}
	
	fclose(iOpen);
	
	if(iError) set_fail_state("[ZESTAWY] Nie zaladowano wszystkich modeli. Sprawdz logi bledow!");
	
	if(!ArraySize(aWeaponSets)) set_fail_state("[ZESTAWY] Nie zaladowano zadnego zestawu. Sprawdz plik konfiguracyjny zestawy_broni.ini!");
	
	#if defined SKLEPSMS
	RegisterServices();
	#endif
	
	for(new i = 1; i < MAX_PLAYERS + 1; i++) for(new j = 0; j < ArraySize(aWeaponSets); j++) ArrayPushCell(aPlayerWeaponSets[i], 0);
	
	bFile = true;
}

#if defined SKLEPSMS
public RegisterServices()
{
	new aData[WeaponSet];
	
	for(new i = 0; i < ArraySize(aWeaponSets); i++)
	{
		ArrayGetArray(aWeaponSets, i, aData);
		
		ss_register_service(aData[SetName]);
	}
}
#endif

public plugin_cfg()
{
	new szHost[32], szUser[32], szPass[32], szDatabase[32], szTemp[512], szError[128], iError;
	
	get_cvar_string("weaponsets_sql_host", szHost, charsmax(szHost));
	get_cvar_string("weaponsets_sql_user", szUser, charsmax(szUser));
	get_cvar_string("weaponsets_sql_pass", szPass, charsmax(szPass));
	get_cvar_string("weaponsets_sql_db", szDatabase, charsmax(szDatabase));
	
	hSqlHook = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);

	new Handle:hConnect = SQL_Connect(hSqlHook, iError, szError, charsmax(szError));
	
	if(iError)
	{
		log_to_file("addons/amxmodx/logs/zestawy_broni.log", "Error: %s", szError);
		
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `zestawy_broni` (name VARCHAR(35) NOT NULL, weaponset VARCHAR(64) NOT NULL, have INT NOT NULL DEFAULT -1, PRIMARY KEY(name, weaponset))");	

	new Handle:hQuery = SQL_PrepareQuery(hConnect, szTemp);

	SQL_Execute(hQuery);
	
	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hConnect);
	
	bSql = true;
}

public plugin_end()
{
	SQL_FreeHandle(hSqlHook);
	
	ArrayDestroy(aWeaponSets);
	
	for(new i = 1; i < MAX_PLAYERS + 1; i++) ArrayDestroy(aPlayerWeaponSets[i]);
}

public client_disconnected(id)
	remove_task(id + TASK_LOAD);

public client_putinserver(id)
{
	if(is_user_hltv(id) || is_user_bot(id)) return;
	
	Rem(id, iLoaded);
	
	iWeaponSet[id] = WYLACZONE;
	
	get_user_name(id, szName[id], charsmax(szName));
	
	mysql_escape_string(szName[id], szName[id], charsmax(szName));
	
	set_task(0.1, "LoadWeapons", id + TASK_LOAD);
}

public LoadWeapons(id)
{
	id -= TASK_LOAD;
	
	if(!bSql || !bFile || Get(id, iLoaded) || !is_user_connected(id)) return;
	
	new szData[1], szTemp[128];
	
	szData[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `zestawy_broni` WHERE name = '%s'", szName[id]);
	SQL_ThreadQuery(hSqlHook, "LoadWeapons_Handle", szTemp, szData, 1);
}

public LoadWeapons_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iDataSize)
{
	if(iFailState) 
	{
		log_to_file("addons/amxmodx/logs/zestawy_broni.log", "SQL Error: %s (%d)", szError, iError);
		
		return;
	}
	
	new id = szData[0], szTemp[256], szWeaponSet[32], szPlayerName[32], aData[WeaponSet], iCell, iWeaponSets = 0;
	
	for(new i = 0; i < ArraySize(aWeaponSets); i++) ArraySetCell(aPlayerWeaponSets[id], i, 0);
	
	while(SQL_MoreResults(hQuery))
	{
		if(!is_user_connected(id)) return;
		
		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "name"), szPlayerName, charsmax(szPlayerName));

		SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "weaponset"), szWeaponSet, charsmax(szWeaponSet));
		
		if(equal(szWeaponSet, "Wybrany")) 
		{
			iWeaponSet[id] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "have"));
			
			if(iWeaponSet[id] >= ArraySize(aWeaponSets))
			{
				iWeaponSet[id] = WYLACZONE;
				
				formatex(szTemp, charsmax(szTemp), "UPDATE `zestawy_broni` SET have = '-1' WHERE weaponset = 'Wybrany' AND name = '%s'", szName[id]);
				SQL_ThreadQuery(hSqlHook, "Ignore_Handle", szTemp);
			}
		}
		else
		{
			iCell = WYLACZONE;
			
			for(new i = 0; i < ArraySize(aWeaponSets); i++)
			{
				ArrayGetArray(aWeaponSets, i, aData);
		
				if(equal(aData[SetName], szWeaponSet)) 
				{
					iCell = i;
					
					iWeaponSets++;
				}
			}
			
			if(iCell > WYLACZONE) ArraySetCell(aPlayerWeaponSets[id], iCell, SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "have")));
		}

		SQL_NextRow(hQuery);
	}
	
	if(iWeaponSets != ArraySize(aWeaponSets))
	{
		new aData[WeaponSet];
		
		for(new i = 0; i < ArraySize(aWeaponSets); i++)
		{
			ArrayGetArray(aWeaponSets, i, aData);

			formatex(szTemp, charsmax(szTemp), "INSERT INTO `zestawy_broni` (`name`, `weaponset`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE name = name", szName[id], aData[SetName]);
			SQL_ThreadQuery(hSqlHook, "Ignore_Handle", szTemp);
		}
		
		formatex(szTemp, charsmax(szTemp), "INSERT INTO `zestawy_broni` (`name`, `weaponset`, `have`) VALUES ('%s', 'Wybrany', '-1') ON DUPLICATE KEY UPDATE name = name", szName[id]);
		SQL_ThreadQuery(hSqlHook, "Ignore_Handle", szTemp);
	}
	
	Set(id, iLoaded);
}

public ShowMotd(id)
{
	new szData[2048], aData[WeaponSet], iLen = 0;
	
	iLen += formatex(szData[iLen], charsmax(szData) - iLen, "<html><head><style type=^"text/css^">body {background-color: #161616;font-family:Verdana,Tahoma;}</style><meta http-equiv=^"Content-Type^" content=^"text/html; charset=utf8^"></head>");
	
	iLen += formatex(szData[iLen], charsmax(szData) - iLen, "<font size=^"5^" color=^"red^"><b><center>Wymagania Na Bronie:</b></font></center><br /><font size=^"2^" color=^"lightgrey^"><b><center><span style=^"line-height:20px^">");
	
	for(new i = 0; i < ArraySize(aWeaponSets); i++)
	{
		ArrayGetArray(aWeaponSets, i, aData);
		
		iLen += formatex(szData[iLen], charsmax(szData) - iLen, "* Zestaw %s - %i zabic (+%i DMG)<br>", aData[SetName], aData[SetKills], aData[SetDamage]);
	}
	
	iLen += formatex(szData[iLen], charsmax(szData) - iLen, "<br><font size=^"2^" color=^"#FF0000^"><b>Zestawy broni mozesz zakupic pod komenda: /sklepsms (bez wychodzenia z serwera)</b></font></center></b><br></span></body></html>");
	
	show_motd(id, szData, "Informacje o Zestawach Broni");
}

public ChangeWeaponSet(id)
{
	if(!Get(id, iLoaded))
	{
		client_print_color(id, id, "^x03[ZESTAWY]^x01 Trwa ladowanie danych...");
		
		return PLUGIN_CONTINUE;
	}
	
	new menu = menu_create("\wWybierz \rzestaw \wlub \ywylacz\w pokazywanie modeli:", "ChangeWeaponSet_Handler");
	new menu_callback = menu_makecallback("ChangeWeaponSet_Callback");
	
	new aData[WeaponSet], szMenu[64];
	
	for(new i = 0; i < ArraySize(aWeaponSets); i++)
	{
		ArrayGetArray(aWeaponSets, i, aData);
		
		formatex(szMenu, charsmax(szMenu), "\wZestaw \y%s", aData[SetName]);
		
		menu_additem(menu, szMenu, _, _, menu_callback);
	}

	menu_additem(menu, "\rWylacz \wModele", _, _, menu_callback);
	
	menu_addtext(menu, "\yAby sprawdzic wymagania zestawow wpisz \r/wymagania\y.", 2);
	menu_addtext(menu, "\yZestawy mozesz wykupic w \r/sklepsms\y.", 2);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ChangeWeaponSet_Callback(id, menu, item)
{
	new aData[WeaponSet];
	
	if(item < ArraySize(aWeaponSets))
	{
		ArrayGetArray(aWeaponSets, item, aData);
		
		if(stats_get_kills(id) >= aData[SetKills] ||  ArrayGetCell(aPlayerWeaponSets[id], item) || (get_user_flags(id) & ADMIN_ADMIN)) return ITEM_ENABLED;
		else return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

public ChangeWeaponSet_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	if(item < ArraySize(aWeaponSets))
	{
		new aData[WeaponSet];
		
		iWeaponSet[id] = item;
		
		ArrayGetArray(aWeaponSets, item, aData);
		
		client_print_color(id, id, "^x03[ZESTAWY]^x01 Wybrales zestaw broni:^x04 %s^x01.", aData[SetName]);
	}
	else
	{
		iWeaponSet[id] = WYLACZONE;
		
		client_print_color(id, id, "^x03[ZESTAWY]^x01 Modele broni zostaly^x04 wylaczone^x01.");
	}
	
	if(Get(id, iLoaded))
	{
		new szTemp[256];
		
		formatex(szTemp, charsmax(szTemp), "UPDATE `zestawy_broni` SET have = '%d' WHERE weaponset = 'Wybrany' AND name = '%s'", iWeaponSet[id], szName[id]);
		SQL_ThreadQuery(hSqlHook, "Ignore_Handle", szTemp);
	}
	
	return PLUGIN_HANDLED;
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || get_user_team(iVictim) == get_user_team(iAttacker)) return HAM_IGNORED;

	new aData[WeaponSet];
	
	for(new i = ArraySize(aWeaponSets) - 1; i > 0; i--)
	{
		ArrayGetArray(aWeaponSets, i, aData);
		
		if(stats_get_kills(iAttacker) >= aData[SetKills] || iWeaponSet[iAttacker] == i)
		{
			SetHamParamFloat(4, fDamage + float(aData[SetDamage]));
			
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

public M4A1Model(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id) && iWeaponSet[id] > WYLACZONE)
	{
		new aData[WeaponSet];
		
		ArrayGetArray(aWeaponSets, iWeaponSet[id], aData);
		
		set_pev(id, pev_viewmodel2, aData[SetM4A1]);
	}
}

public AK47Model(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id) && iWeaponSet[id] > WYLACZONE)
	{
		new aData[WeaponSet];
		
		ArrayGetArray(aWeaponSets, iWeaponSet[id], aData);
		
		set_pev(id, pev_viewmodel2, aData[SetAK47]);
	}
}

public AWPModel(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id) && iWeaponSet[id] > WYLACZONE)
	{
		new aData[WeaponSet];
		
		ArrayGetArray(aWeaponSets, iWeaponSet[id], aData);
		
		set_pev(id, pev_viewmodel2, aData[SetAWP]);
	}
}

public Ignore_Handle(iFailState, Handle:hQuery, szError[], iError, szData[], iSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file("addons/amxmodx/logs/zestawy_broni.log", "Could not connect to SQL database.  [%d] %s", iError, szError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file("addons/amxmodx/logs/zestawy_broni.log", "Query failed. [%d] %s", iError, szError);
	}
	
	return PLUGIN_CONTINUE;
}

#if defined SKLEPSMS
public ss_service_chosen(id, iWeaponSet) 
{
	if(ArrayGetCell(aPlayerWeaponSets[id], iWeaponSet)) 
	{
		client_print_color(id, print_team_red, "^x03[SKLEPSMS]^x01 Masz juz ten^x04 zestaw broni^x01.");
		
		return SS_STOP;
	}
	
	return SS_OK;
}

public ss_service_bought(id, iWeaponSet)
{
	new aData[WeaponSet], szTemp[256];
	
	for(new i = 0; i <= iWeaponSet; i++)
	{
		ArrayGetArray(aWeaponSets, i, aData);
		
		formatex(szTemp, charsmax(szTemp), "UPDATE `zestawy_broni` SET have = '1' WHERE weaponset = '%s' AND name = '%s'", aData[SetName], szName[id]);
		SQL_ThreadQuery(hSqlHook, "Ignore_Handle", szTemp);
		
		ArraySetCell(aPlayerWeaponSets[id], i, 1);
	}
}

public native_filter(const native_name[], index, trap) 
{
	if(trap == 0) 
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		
		pause_plugin();
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
#endif

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