#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <sqlx>

native zp_get_user_level(id);
native zp_get_user_ammo_packs(id);
native zp_set_user_ammo_packs(id, ap);
native zp_force_password(id);
native register_system_check(id);

enum _:SquadInfo
{
	SquadName[64],
	SquadPassword[32],
	SquadLevel,
	SquadAmmoPacks,
	SquadSpeed,
	SquadGravity,
	SquadDamage,
	SquadWeaponDrop,
	SquadKills,
	SquadMembers,
	Trie:SquadStatus,
};

enum
{
	STATUS_NONE = 0,
	STATUS_MEMBER,
	STATUS_ADMIN,
	STATUS_LEADER
};

new const g_szSquadValues[][] = 
{
	"Poziom",
	"AmmoPacki",
	"Predkosc",
	"Grawitacja",
	"Obrazenia",
	"Obezwladnienie",
	"Zabojstwa"
};

new const szPrefix[] = "^x01[^x04ZP^x01]";
new const szFile[] = "zp_squads.ini";

new g_pLevelCost, g_pNextLevelCost, g_pSpeedCost, g_pNextSpeedCost, g_pGravityCost,
g_pNextGravityCost, g_pDamageCost, g_pNextDamageCost, g_pWeaponDropCost, g_pNextWeaponDropCost;
new g_pLevelMax, g_pSpeedMax, g_pGravityMax, g_pDamageMax, g_pWeaponDropMax;
new g_pMembersPerLevel, g_pSpeedPerLevel, g_pGravityPerLevel, g_pDamagePerLevel, g_pWeaponDropPerLevel;
new g_pCreateLevel, g_pMaxMembers;

new Trie:g_tSquadNames;
new Trie:g_tSquadValues;

new Array:g_aSquads;

new g_MemberName[33][64]
new g_iSquad[33];
new iCurSquad = 1;

new Handle:g_SqlTuple;
new g_Cache[512];
new szMessage[2048];

new ChosenName[33][64];
new ChosenID[33];

new bool:Password[33];
new bool:g_FreezeTime;

native zp_save_ammopacks(id);

public plugin_init()
{
	register_plugin("ZP Squads System", "1.6", "O'Zone");
	
	register_cvar("zp_squads_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_squads_sql_user", "310529", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_squads_sql_pass", "IzQsAjTnjuPnJu41", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_squads_sql_db", "310529_zp", FCVAR_SPONLY|FCVAR_PROTECTED); 
	
	g_aSquads = ArrayCreate(SquadInfo);
	
	g_tSquadValues = TrieCreate();
	g_tSquadNames = TrieCreate();
	
	new aData[SquadInfo];
	aData[SquadName] = "Brak";
	aData[SquadLevel] = 0;
	aData[SquadAmmoPacks] = 0;
	aData[SquadSpeed] = 0;
	aData[SquadGravity] = 0;
	aData[SquadWeaponDrop] = 0;
	aData[SquadDamage] = 0;
	aData[SquadPassword] = 0;
	aData[SquadMembers] = 0;
	aData[SquadStatus] = _:TrieCreate();
	ArrayPushArray(g_aSquads, aData);
	
	for(new i = 0; i < sizeof g_szSquadValues; i++) TrieSetCell(g_tSquadValues, g_szSquadValues[i], i);
	
	register_clcmd("say /oddzial", "Cmd_Squad");
	register_clcmd("say /otop15", "Squads_Top15");
	register_clcmd("oddzial", "Cmd_Squad");
	register_clcmd("say_team /oddzial", "Cmd_Squad");
	register_clcmd("say_team /otop15", "Squads_Top15");
	register_clcmd("Nazwa", "Cmd_CreateSquad");
	register_clcmd("Ustaw_Haslo", "Cmd_SetPassword");
	register_clcmd("Podaj_Haslo", "Cmd_CheckPassword");
	register_clcmd("Nowa_Nazwa", "ChangeName_Handler");
	register_clcmd("Ilosc_AmmoPackow", "DepositAmmoPacks_Handle");
	
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"),"handleSayText");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	RegisterHam(Ham_TakeDamage, "player","TakeDamage", 0);
	RegisterHam(get_player_resetmaxspeed_func(), "player", "Player_ResetMaxSpeed", 1);
}

public plugin_end()
{
	SQL_FreeHandle(g_SqlTuple);
	ArrayDestroy(g_aSquads);
}
	
public plugin_cfg()
{
	Config_Load();
	SqlInit();
}

public client_disconnected(id)
{
	Password[id] = false;
	g_iSquad[id] = 0;
}

public client_putinserver(id)
{
	g_iSquad[id] = 0;
	LoadMember(id);
}

public NewRound()
	g_FreezeTime = true;

public RoundStart()
	g_FreezeTime = false;

public PlayerSpawn(id)
{
	if(!is_user_alive(id) || !g_iSquad[id]) return HAM_IGNORED;
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	if(equal(aData[SquadPassword], "") && get_user_status(id, g_iSquad[id]) == STATUS_LEADER)
	{
		client_print_color(id, id, "%s Nie wpisano hasla zarzadzania oddzialem. Wpisz je teraz!", szPrefix);
		client_cmd(id, "messagemode Ustaw_Haslo");
	}
	
	new iGravity = 800 - (g_pGravityPerLevel*aData[SquadGravity]);
	set_user_gravity(id, float(iGravity)/800.0);
	
	return HAM_IGNORED;
}

public Player_ResetMaxSpeed(id)
{
	if(!g_iSquad[id] || g_FreezeTime || !is_user_alive(id)) return HAM_IGNORED;
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	if(aData[SquadSpeed]) set_user_maxspeed(id, get_user_maxspeed(id) + (g_pSpeedPerLevel * aData[SquadSpeed]));

	return HAM_IGNORED;
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:Damage, iBits)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iVictim)) return HAM_IGNORED;
	
	if(get_user_team(iVictim) == get_user_team(iAttacker) || !g_iSquad[iAttacker]) return HAM_IGNORED;
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[iAttacker], aData);
	
	if(aData[SquadDamage]) SetHamParamFloat(4, Damage + (g_pDamagePerLevel*(aData[SquadDamage])));
	
	if(aData[SquadWeaponDrop] && random_num(1, (g_pWeaponDropMax*1.6 - (aData[SquadWeaponDrop] * g_pWeaponDropPerLevel)) == 1)) client_cmd(iVictim, "drop");
	
	return HAM_IGNORED;
}

public DeathMsg()
{
	new iKiller = read_data(1);
	
	if(!is_user_alive(iKiller) || !g_iSquad[iKiller]) return PLUGIN_CONTINUE;
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[iKiller], aData);
	
	aData[SquadKills]++;
	ArraySetArray(g_aSquads, g_iSquad[iKiller], aData);
	
	SaveSquad(g_iSquad[iKiller]);
	
	return PLUGIN_CONTINUE;
}

public Cmd_Squad(id)
{	
	if(!is_user_connected(id) || !register_system_check(id))
		return PLUGIN_HANDLED;
	
	new aData[SquadInfo], szMenu[128], menu;
	
	if(g_iSquad[id])
	{
		ArrayGetArray(g_aSquads, g_iSquad[id], aData);
		
		formatex(szMenu, charsmax(szMenu), "\yMenu Oddzialu^n\wAktualny Oddzial:\y %s^n\w(\y%i/%i %s | %i AmmoPackow\w)", aData[SquadName], aData[SquadMembers], aData[SquadLevel]*g_pMembersPerLevel+g_pMaxMembers, aData[SquadMembers] > 1 ? "Czlonkow" : "Czlonek", aData[SquadAmmoPacks]);
		menu = menu_create(szMenu, "SquadMenu_Handler");
		
		if(get_user_status(id, g_iSquad[id]) > STATUS_MEMBER)
			menu_additem(menu, "\wZarzadzaj \yOddzialem", "1");
		else 
		{
			formatex(szMenu, charsmax(szMenu), "\wStworz \yOddzial \r(Wymagany %i Poziom)", g_pCreateLevel);
			menu_additem(menu, szMenu, "1");
		}
	}
	else
	{
		menu = menu_create("\yMenu Oddzialu^n\wAktualny Oddzial:\y Brak", "SquadMenu_Handler");
		formatex(szMenu, charsmax(szMenu), "\wStworz \yOddzial \r(Wymagany %i Poziom)", g_pCreateLevel);
		menu_additem(menu, szMenu, "1");
	}
	
	new menu_callback = menu_makecallback("SquadMenu_Callback");

	menu_additem(menu, "\wOpusc \yOddzial", "2", 0, menu_callback);
	menu_additem(menu, "\wZapros \yGracza", "3", 0, menu_callback);
	menu_additem(menu, "\wCzlonkowie \yOnline", "4", 0, menu_callback);
	menu_additem(menu, "\wWplac \yAmmoPacki", "5", 0, menu_callback);
	menu_additem(menu, "\wTop15 \yOddzialow", "6", 0, menu_callback);
	
	menu_setprop(menu, MPROP_NOCOLORS, 1);
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public SquadMenu_Callback(id, menu, item)
{
	switch(item)
	{
		case 1, 3, 4: 
		{
			if(g_iSquad[id])
				return ITEM_ENABLED;
			else
				return ITEM_DISABLED;
		}
		case 2: 
		{
			if(g_iSquad[id] && get_user_status(id, g_iSquad[id]) > STATUS_MEMBER)
			{
				new aData[SquadInfo];
				ArrayGetArray(g_aSquads, g_iSquad[id], aData);
				
				if(((aData[SquadLevel]*g_pMembersPerLevel)+g_pMaxMembers) > aData[SquadMembers])
					return ITEM_ENABLED;
			}
			return ITEM_DISABLED;
		}
	}
	return ITEM_ENABLED;
}

public SquadMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0: 
		{
			if(get_user_status(id, g_iSquad[id]) > STATUS_MEMBER)
			{
				ShowLeaderMenu(id);
				return PLUGIN_HANDLED;
			}
			
			if(g_iSquad[id])
			{
				client_print_color(id, id, "%s Nie mozesz utworzyc oddzialu, jesli w jakims jestes!", szPrefix);
				return PLUGIN_HANDLED;
			}
			
			if(zp_get_user_level(id) < g_pCreateLevel)
			{
				client_print_color(id, id, "%s Nie masz wystarczajacego poziomu by stworzyc oddzial (Wymagany^x03 %i^x01)!", szPrefix, g_pCreateLevel);
				return PLUGIN_HANDLED;
			}
			
			client_cmd(id, "messagemode Nazwa");
		}
		case 1: ShowLeaveConfirmMenu(id);
		case 2: ShowInviteMenu(id);
		case 3: ShowMembersOnlineMenu(id);
		case 4: 
		{
			client_cmd(id, "messagemode Ilosc_AmmoPackow");
			client_print_color(id, id, "%s Wpisz ilosc AmmoPackow, ktora chcesz wplacic.", szPrefix);
		}
		case 5: Squads_Top15(id);
	}
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public Cmd_CreateSquad(id)
{
	if(g_iSquad[id])
	{
		client_print_color(id, id, "%s Nie mozesz utworzyc oddzialu, jesli w jakims jestes!", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	if(zp_get_user_level(id) < g_pCreateLevel)
	{
		client_print_color(id, id, "%s Nie masz wystarczajaco duzego poziomu (Wymagany: %i)!", szPrefix, g_pCreateLevel);
		return PLUGIN_HANDLED;
	}
	
	new szSquadName[64], TempSquadName[64];
	
	read_args(szSquadName, charsmax(szSquadName));
	remove_quotes(szSquadName);
	
	if(equal(szSquadName, ""))
	{
		client_print_color(id, id, "%s Nie wpisano nazwy oddzialu.", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	mysql_escape_string(szSquadName, TempSquadName, charsmax(TempSquadName));
	
	if(CheckSquadName(TempSquadName))
	{
		client_print_color(id, id, "%s Oddzial z taka nazwa juz istnieje.", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new aData[SquadInfo];
	
	copy(aData[SquadName], charsmax(aData[SquadName]), szSquadName);
	aData[SquadLevel] = 0;
	aData[SquadAmmoPacks] = 0;
	aData[SquadSpeed] = 0;
	aData[SquadGravity] = 0;
	aData[SquadWeaponDrop] = 0;
	aData[SquadDamage] = 0;
	aData[SquadPassword] = 0;
	aData[SquadMembers] = 0;
	aData[SquadStatus] = _:TrieCreate();
	
	ArrayPushArray(g_aSquads, aData);
	TrieSetCell(g_tSquadNames, aData[SquadName], iCurSquad);
	iCurSquad++; 
	
	formatex(g_Cache, charsmax(g_Cache), "INSERT INTO `squads` (`squad_name`) VALUES ('%s');", TempSquadName);
	log_to_file("addons/amxmodx/logs/squads.log", "CreateSquad: %s", g_Cache);
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	
	set_user_squad(id, ArraySize(g_aSquads) - 1, 1);
	set_user_status(id, ArraySize(g_aSquads) - 1, STATUS_LEADER);
	
	client_print_color(id, id, "%s Pomyslnie zalozyles oddzial^x03 %s^01.", szPrefix, szSquadName);
	client_print_color(id, id, "%s Teraz wpisz haslo, ktore pozwoli na zarzadzanie oddzialem.", szPrefix);
	client_print(id, print_center, "Wpisz haslo pozwalajace zarzadzac oddzialem!");
	
	client_cmd(id, "messagemode Ustaw_Haslo");
	
	return PLUGIN_HANDLED;
}

public Cmd_SetPassword(id)
{
	if(!g_iSquad[id])
	{
		client_print_color(id, id, "%s Nie mozesz ustawic hasla, bo nie masz oddzialu!", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	new szPassword[32];
	
	read_args(szPassword, charsmax(szPassword));
	remove_quotes(szPassword);
	
	if(equal(szPassword, ""))
	{
		client_print_color(id, id, "%s Nie wpisano hasla zarzadzania oddzialem. Wpisz je teraz!", szPrefix);
		client_cmd(id, "messagemode Ustaw_Haslo");
		return PLUGIN_HANDLED;
	}
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	copy(aData[SquadPassword], charsmax(aData[SquadPassword]), szPassword);
	ArraySetArray(g_aSquads, g_iSquad[id], aData);
	
	SaveSquad(g_iSquad[id]);
	
	client_print(id, print_center, "Haslo zostalo ustawione!");
	client_print_color(id, id, "%s Haslo zarzadzania oddzialem zostalo ustawione.", szPrefix);
	client_print_color(id, id, "%s Wpisz w konsoli^x03 setinfo ^"_oddzial^" ^"%s^"^x01.", szPrefix, szPassword);
	
	Password[id] = true;
	cmdExecute(id, "setinfo _oddzial %s", szPassword);
	cmdExecute(id, "writecfg oddzial");
	
	return PLUGIN_HANDLED;
}

public ShowInviteMenu(id)
{	
	new iPlayers[32], iNum, szInfo[6], Players = 0, szName[32];
	get_players(iPlayers, iNum);
	
	new Menu = menu_create("Wybierz gracza do zaproszenia:", "InviteMenu_Handler");
	
	for(new i = 0, iPlayer; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(iPlayer == id || g_iSquad[iPlayer] == g_iSquad[id] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
			continue;
			
		Players++;
		
		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szInfo, charsmax(szInfo));
		menu_additem(Menu, szName, szInfo);
	}	
	
	menu_display(id, Menu, 0);
	
	if(!Players)
	{
		menu_destroy(Menu);
		client_print_color(id, id, "%s Na serwerze nie ma gracza, ktorego moglbys zaprosic!", szPrefix);
	}
}

public InviteMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new szData[6], iAccess, hCallback, szName[32];
	menu_item_getinfo(menu, item, iAccess, szData, 5, szName, 31, hCallback);
	
	new iPlayer = str_to_num(szData);

	if(!is_user_connected(iPlayer) || !register_system_check(id))
		return PLUGIN_HANDLED;
	
	ShowInviteConfirmMenu(id, iPlayer);

	client_print_color(id, id, "%s Zaprosiles %s do do twojego oddzialu.", szPrefix, szName);
	
	Cmd_Squad(id);
	
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu(id, iPlayer)
{
	new szName[32];
	get_user_name(id, szName, charsmax(szName));
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	new szMenuTitle[128];
	formatex(szMenuTitle, charsmax(szMenuTitle), "%s zaprosil cie do oddzialu %s", szName, aData[SquadName]);
	new Menu = menu_create(szMenuTitle, "InviteConfirmMenu_Handler");
	
	new szInfo[6];
	num_to_str(g_iSquad[id], szInfo, 5);
	
	menu_additem(Menu, "Dolacz", szInfo);
	menu_additem(Menu, "Odrzuc", "-1");
	
	menu_display(iPlayer, Menu, 0);	
}

public InviteConfirmMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(menu, item, iAccess, szData, 5, _, _, hCallback);
	
	new iSquad = str_to_num(szData);
	
	if(iSquad < 1)
		return PLUGIN_HANDLED;
	
	if(get_user_status(id, g_iSquad[id]) == STATUS_LEADER)
	{
		client_print_color(id, id, "%s Nie mozesz dolaczyc do oddzialu, jesli jestes zalozycielem innego.", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, iSquad, aData);
	
	if(((aData[SquadLevel]*g_pMembersPerLevel)+g_pMaxMembers) <= aData[SquadMembers])
	{
		client_print_color(id, id, "%s Niestety, w tym oddzialie nie ma juz wolnego miejsca.", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	set_user_squad(id, iSquad);
	
	client_print_color(id, id, "%s Dolaczyles do oddzialu^x03 %s^01.", szPrefix, aData[SquadName]);
	
	return PLUGIN_HANDLED;
}

public ShowLeaveConfirmMenu(id)
{
	new Menu = menu_create("Jestes pewien ze chcesz opuscic oddzial?", "LeaveConfirmMenu_Handler");
	
	menu_additem(Menu, "Tak", "0");
	menu_additem(Menu, "Nie", "1");
	
	menu_display(id, Menu, 0);
}

public LeaveConfirmMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(menu, item, iAccess, szData, 5, _, _, hCallback);
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	switch(str_to_num(szData))
	{
		case 0: 
		{
			if(get_user_status(id, g_iSquad[id]) == STATUS_LEADER)
			{
				client_print_color(id, id, "%s Oddaj przywodctwo oddzialu jednemu z czlonkow zanim go upuscisz.", szPrefix);
				Cmd_Squad(id);
				return PLUGIN_HANDLED;
			}
			
			log_to_file("addons/amxmodx/logs/squads.log", "Opuszczenie oddzialu: %s", g_MemberName[id]);
			
			client_print_color(id, id, "%s Opusciles swoj oddzial.", szPrefix);
			
			set_user_squad(id);
			
			Cmd_Squad(id);
		}
		case 1: Cmd_Squad(id);
	}
	return PLUGIN_HANDLED;
}

public Cmd_CheckPassword(id)
{
	if(!g_iSquad[id] || get_user_status(id, g_iSquad[id]) < STATUS_ADMIN)
		return PLUGIN_HANDLED;
	
	new szPassword[32];
	read_args(szPassword, charsmax(szPassword));
	
	remove_quotes(szPassword);
	
	if(equal(szPassword, ""))
	{
		client_print_color(id, id, "%s Nie wpisales hasla zarzadzania oddzialem!", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	if(!equal(aData[SquadPassword], szPassword))
	{
		client_print_color(id, id, "%s Podane haslo zarzadzania oddzialem jest nieprawidlowe!", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	client_print_color(id, id, "%s Wpisane haslo jest prawidlowe.", szPrefix);
	Password[id] = true;
	
	ShowLeaderMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu(id)
{
	if(Password[id])
	{
		new Menu = menu_create("Zarzadzaj Oddzialem", "LeaderMenu_Handler");
	
		new iStatus = get_user_status(id, g_iSquad[id]);
	
		if(iStatus == STATUS_LEADER)
			menu_additem(Menu, "Rozwiaz\r Oddzial", "1");
			
		if(iStatus >= STATUS_ADMIN)
			menu_additem(Menu, "Ulepsz\r Umiejetnosci", "2");
		
		menu_additem(Menu, "Zarzadzaj\y Czlonkami", "3");
		menu_additem(Menu, "Zmien\y Nazwe Oddzialu^n", "4");
		menu_additem(Menu, "\wWroc", "5");
		menu_setprop(Menu, MPROP_EXITNAME, "\wWyjdz");
	
		menu_display(id, Menu, 0);
	}
	else
	{
		client_cmd(id, "messagemode Podaj_Haslo");
		client_print_color(id, id, "%s Wpisz jednorazowo haslo zarzadzania oddzialem.", szPrefix);
		client_print(id, print_center, "Wpisz haslo zarzadzania oddzialem");
	}
}

public LeaderMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[6];
	menu_item_getinfo(menu, item, iAccess, szData, 5, _, _, hCallback);
	
	switch(str_to_num(szData))
	{
		case 1: ShowDisbandConfirmMenu(id);
		case 2: ShowSkillsMenu(id);
		case 3: ShowMembersMenu(id);
		case 4: client_cmd(id, "messagemode Nowa_Nazwa");
		case 5: Cmd_Squad(id);
	}
	
	return PLUGIN_HANDLED;
}

public ShowDisbandConfirmMenu(id)
{
	new Menu = menu_create("Jestes pewien ze chcesz rozwiazac oddzial?", "DisbandConfirmMenu_Handler");
	menu_additem(Menu, "Tak", "0");
	menu_additem(Menu, "Nie^n", "1");
	menu_setprop(Menu, MPROP_EXITNAME, "\wWyjdz");
	menu_display(id, Menu, 0);
}

public DisbandConfirmMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED;
	
	new szData[6], iAccess, hCallback;
	menu_item_getinfo(menu, item, iAccess, szData, 5, _, _, hCallback);
	
	switch(str_to_num(szData))
	{
		case 0: 
		{
			new TempSquadName[64];
			
			new aData[SquadInfo];
			ArrayGetArray(g_aSquads, g_iSquad[id], aData);
			
			new iPlayers[32], iNum, iPlayer;
			get_players(iPlayers, iNum);
			
			for(new i = 0; i < iNum; i++)
			{
				iPlayer = iPlayers[i];
				
				if(iPlayer == id)
					continue;
				
				if(g_iSquad[id] != g_iSquad[iPlayer] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
					continue;
						
				set_user_squad(iPlayer);
				
				client_print_color(iPlayer, iPlayer, "%s Twoj oddzial zostal rozwiazany.", szPrefix);
			}
			
			new iSquad = g_iSquad[id];
			set_user_squad(id);
			
			client_print_color(id, id, "%s Rozwiazales swoj oddzial.", szPrefix);
			
			mysql_escape_string(aData[SquadName], TempSquadName, charsmax(TempSquadName));
			
			formatex(g_Cache, charsmax(g_Cache), "DELETE FROM `squads` WHERE squad_name = '%s'", TempSquadName);
			SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
			log_to_file("addons/amxmodx/logs/squads.log", "DeleteSquad-1: %s", g_Cache);
			
			formatex(g_Cache, charsmax(g_Cache), "UPDATE `squad_members` SET flag = '0', squad = '' WHERE squad = '%s'", TempSquadName);
			SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
			log_to_file("addons/amxmodx/logs/squads.log", "DeleteSquad-2: %s", g_Cache);
			
			ArrayDeleteItem(g_aSquads, iSquad);
			TrieDeleteKey(g_tSquadNames, aData[SquadName]);
			
			Cmd_Squad(id);
		}
		case 1: Cmd_Squad(id);
	}
	return PLUGIN_HANDLED;
}

public ShowSkillsMenu(id)
{	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	new szMenu[128];
	
	formatex(szMenu, charsmax(szMenu), "\yMenu Umiejetnosci^n\rAmmoPacki Oddzialu: %i", aData[SquadAmmoPacks]);
	new menu = menu_create(szMenu, "SkillsMenu_Handler");
	formatex(szMenu, charsmax(szMenu), "Poziom Oddzialu \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aData[SquadLevel], g_pLevelMax, g_pLevelCost+g_pNextLevelCost*aData[SquadLevel]);
	menu_additem(menu, szMenu, "0");
	formatex(szMenu, charsmax(szMenu), "Predkosc \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aData[SquadSpeed], g_pSpeedMax, g_pSpeedCost+g_pNextSpeedCost*aData[SquadSpeed]);
	menu_additem(menu, szMenu, "1");
	formatex(szMenu, charsmax(szMenu), "Grawitacja \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aData[SquadGravity], g_pGravityMax, g_pGravityCost+g_pNextGravityCost*aData[SquadGravity]);
	menu_additem(menu, szMenu, "2");
	formatex(szMenu, charsmax(szMenu), "Obrazenia \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aData[SquadDamage], g_pDamageMax, g_pDamageCost+g_pNextDamageCost*aData[SquadDamage]);
	menu_additem(menu,szMenu, "3");
	formatex(szMenu, charsmax(szMenu), "Obezwladnienie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", aData[SquadWeaponDrop], g_pWeaponDropMax, g_pWeaponDropCost+g_pNextWeaponDropCost*aData[SquadWeaponDrop]);
	menu_additem(menu, szMenu, "4");
	
	menu_setprop(menu, MPROP_NOCOLORS, 1);
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public SkillsMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		Cmd_Squad(id);
		return PLUGIN_CONTINUE;
	}
	
	new aData[SquadInfo], upgraded;
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	switch(item)
	{
		case 0:
		{
			if(aData[SquadLevel] == g_pLevelMax)
			{
				client_print_color(id, id, "%s Twoj oddzial ma juz maksymalny Poziom.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aData[SquadAmmoPacks] - (g_pLevelCost + g_pNextLevelCost*aData[SquadLevel]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, id, "%s Twoj oddzial nie ma wystarczajacej ilosci AmmoPackow.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			upgraded = 1;
			aData[SquadLevel]++;
			aData[SquadAmmoPacks] = iRemaining;
			client_print_color(id, id, "%s Ulepszyles oddzial na^x03 %i Poziom^x01!", szPrefix, aData[SquadLevel]);
		}
		case 1:
		{
			if(aData[SquadSpeed] == g_pSpeedMax)
			{
				client_print_color(id, id, "%s Twoj oddzial ma juz maksymalny poziom tej umiejetnosci.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aData[SquadAmmoPacks] - (g_pSpeedCost + g_pNextSpeedCost*aData[SquadSpeed]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, id, "%s Twoj oddzial nie ma wystarczajacej ilosci AmmoPackow.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			upgraded = 2;
			aData[SquadSpeed]++;
			aData[SquadAmmoPacks] = iRemaining;
			client_print_color(id, id, "%s Ulepszyles umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", szPrefix, aData[SquadSpeed]);
		}
		case 2:
		{
			if(aData[SquadGravity] == g_pGravityMax)
			{
				client_print_color(id, id, "%s Twoj oddzial ma juz maksymalny poziom tej umiejetnosci.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aData[SquadAmmoPacks] - (g_pGravityCost + g_pNextGravityCost*aData[SquadGravity]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, id, "%s Twoj oddzial nie ma wystarczajacej ilosci AmmoPackow.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			upgraded = 3;
			aData[SquadGravity]++;
			aData[SquadAmmoPacks] = iRemaining;
			client_print_color(id, id, "%s Ulepszyles umiejetnosc^x03 Grawitacja^x01 na^x03 %i^x01 poziom!", szPrefix, aData[SquadGravity]);
		}
		case 3:
		{
			if(aData[SquadDamage] == g_pDamageMax)
			{
				client_print_color(id, id, "%s Twoj oddzial ma juz maksymalny poziom tej umiejetnosci.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aData[SquadAmmoPacks] - (g_pDamageCost + g_pNextDamageCost*aData[SquadDamage]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, id, "%s Twoj oddzial nie ma wystarczajacej ilosci AmmoPackow.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			upgraded = 4;
			aData[SquadDamage]++;
			aData[SquadAmmoPacks] = iRemaining;
			client_print_color(id, id, "%s Ulepszyles umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", szPrefix, aData[SquadDamage]);
		}
		case 4:
		{
			if(aData[SquadWeaponDrop] == g_pWeaponDropMax)
			{
				client_print_color(id, id, "%s Twoj oddzial ma juz maksymalny poziom tej umiejetnosci.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = aData[SquadAmmoPacks] - (g_pWeaponDropCost + g_pNextWeaponDropCost*aData[SquadWeaponDrop]);
			
			if(iRemaining < 0)
			{
				client_print_color(id, id, "%s Twoj oddzial nie ma wystarczajacej ilosci AmmoPackow.", szPrefix);
				ShowSkillsMenu(id);
				return PLUGIN_HANDLED;
			}
			
			upgraded = 5;
			aData[SquadWeaponDrop]++;
			aData[SquadAmmoPacks] = iRemaining;
			client_print_color(id, id, "%s Ulepszyles umiejetnosc^x03 Obezwladnienie^x01 na^x03 %i^x01 poziom!", szPrefix, aData[SquadWeaponDrop]);
		}
	}
	
	ArraySetArray(g_aSquads, g_iSquad[id], aData);
	
	new iPlayers[32], iNum, iPlayer, szName[32];
	
	get_players(iPlayers, iNum);
	get_user_name(id, szName, charsmax(szName));
	
	for(new i = 0 ; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(iPlayer == id || g_iSquad[iPlayer] != g_iSquad[id])
			continue;
		
		switch(upgraded)
		{
			case 1: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 ulepszyl oddzial na^x03 %i Poziom^x01!", szPrefix, szName, aData[SquadLevel]);
			case 2: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 ulepszyl umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", szPrefix, szName, aData[SquadSpeed]);
			case 3: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 ulepszyl umiejetnosc^x03 Grawitacja^x01 na^x03 %i^x01 poziom!", szPrefix, szName, aData[SquadGravity]);
			case 4: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 ulepszyl umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", szPrefix, szName, aData[SquadDamage]);
			case 5: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 ulepszyl umiejetnosc^x03 Obezwladnienie^x01 na^x03 %i^x01 poziom!", szPrefix, szName, aData[SquadWeaponDrop]);
		}
	}
	
	SaveSquad(g_iSquad[id]);
	
	ShowSkillsMenu(id);
	
	return PLUGIN_HANDLED;
}

public ShowMembersOnlineMenu(id)
{
	new szName[64], iPlayers[32], iNum, Players = 0;
	get_players(iPlayers, iNum);
	
	new Menu = menu_create("Czlonkowie Online:", "MembersOnlineMenu_Handler");
	
	for(new i = 0, iPlayer; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if(g_iSquad[id] != g_iSquad[iPlayer])
			continue;
			
		Players++;
		get_user_name(iPlayer, szName, charsmax(szName));
		
		switch(get_user_status(iPlayer, g_iSquad[id]))
		{
			case STATUS_MEMBER: add(szName, charsmax(szName), " \r[Czlonek]");
			case STATUS_ADMIN: add(szName, charsmax(szName), " \r[Zastepca]");
			case STATUS_LEADER: add(szName, charsmax(szName), " \r[Przywodca]");
		}
		menu_additem(Menu, szName);
	}
	
	menu_setprop(Menu, MPROP_EXITNAME, "\wWyjdz");
	menu_display(id, Menu, 0);
	
	if(!Players)
	{
		menu_destroy(Menu);
		client_print_color(id, id, "%s Na serwerze nie ma zadnego czlonka twojego oddzialu!", szPrefix);
	}
}

public MembersOnlineMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu);
	
	ShowMembersOnlineMenu(id);
	
	return PLUGIN_HANDLED;
}

public ChangeName_Handler(id)
{
	if(!g_iSquad[id] || get_user_status(id, g_iSquad[id]) != STATUS_LEADER)
		return PLUGIN_HANDLED;
	
	new szSquadName[64], TempSquadName[64], OldSquadName[64];
	
	read_args(szSquadName, charsmax(szSquadName));
	remove_quotes(szSquadName);
	
	if(equal(szSquadName, ""))
	{
		client_print_color(id, id, "%s Nie wpisano nowej nazwy oddzialu.", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	mysql_escape_string(szSquadName, TempSquadName, charsmax(TempSquadName));
	
	if(CheckSquadName(TempSquadName))
	{
		client_print_color(id, id, "%s Oddzial z taka nazwa juz istnieje.", szPrefix);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	mysql_escape_string(aData[SquadName], OldSquadName, charsmax(OldSquadName));
	
	copy(aData[SquadName], charsmax(aData[SquadName]), szSquadName);
	ArraySetArray(g_aSquads, g_iSquad[id], aData);
	
	TrieSetCell(g_tSquadNames, aData[SquadName], g_iSquad[id]);
	
	formatex(g_Cache, charsmax(g_Cache), "UPDATE `squad_members` SET squad = '%s' WHERE squad = '%s'", TempSquadName, OldSquadName);
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	log_to_file("addons/amxmodx/logs/squads.log", "ChangeName-1: %s", g_Cache);
	
	formatex(g_Cache, charsmax(g_Cache), "UPDATE `squads` SET squad_name = '%s' WHERE squad_name = '%s'", TempSquadName, OldSquadName);
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	log_to_file("addons/amxmodx/logs/squads.log", "ChangeName-2: %s", g_Cache);
	
	client_print_color(id, id, "%s Zmieniles nazwe oddzialu na^x03 %s^x01.", szPrefix, aData[SquadName]);
	
	return PLUGIN_CONTINUE;
}

public ShowMembersMenu(id)
{
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	new TempSquadName[64];
	mysql_escape_string(aData[SquadName], TempSquadName, charsmax(TempSquadName));
	
	new data[1];
	data[0] = id;
	
	formatex(g_Cache, charsmax(g_Cache), "SELECT * FROM `squad_members` WHERE squad = '%s' ORDER BY flag DESC", TempSquadName);
	SQL_ThreadQuery(g_SqlTuple, "MembersMenuHandler", g_Cache, data, 1);
}

public MembersMenuHandler(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/squads.log", "<Query> Error: %s", Error);
		return;
	}
	
	new id = Data[0];
		
	new szName[33], szInfo[64], iStatus;
	new Menu = menu_create("\yZarzadzaj Czlonkami:^n\rWybierz czlonka, aby pokazac mozliwe opcje.", "MemberMenu_Handler");
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "name"), szName, charsmax(szName));
		iStatus = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "flag"));
		
		formatex(szInfo, charsmax(szInfo), "%s#%i", szName, iStatus);
		
		switch(iStatus)
		{
			case STATUS_MEMBER: add(szName, charsmax(szName), " \r[Czlonek]");
			case STATUS_ADMIN: add(szName, charsmax(szName), " \r[Zastepca]");
			case STATUS_LEADER: add(szName, charsmax(szName), " \r[Przywodca]");
		}
		
		menu_additem(Menu, szName, szInfo);
		SQL_NextRow(Query);
	}
	menu_setprop(Menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(Menu, MPROP_NEXTNAME, "Nastepne");
	menu_setprop(Menu, MPROP_EXITNAME, "\wWyjdz");
	menu_display(id, Menu, 0);
}

public MemberMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new szInfo[64], iAccess, Callback, szName[33], szTempFlag[2], iFlag, iID;
	
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), "", 0, Callback);
	
	menu_destroy(menu);

	strtok(szInfo, szName, charsmax(szName), szTempFlag, 1, '#');
	
	iFlag = str_to_num(szTempFlag);
	iID = get_user_index(szName);
		
	if(iID == id)
	{
		client_print_color(id, id, "%s Nie mozesz zarzadzac soba!", szPrefix);
		ShowMembersMenu(id);
		return PLUGIN_HANDLED;
	}
	
	if(g_iSquad[iID])	
		ChosenID[id] = get_user_userid(iID);
	
	if(iFlag == STATUS_LEADER)
	{
		client_print_color(id, id, "%s Nie mozna zarzadzac przywodca oddzialu!", szPrefix);
		ShowMembersMenu(id);
		return PLUGIN_HANDLED;
	}
		
	formatex(ChosenName[id], charsmax(ChosenName), szName);
	
	new Menu = menu_create("\yWybierz Opcje:", "MemberMenu2_Handler");
	
	if(get_user_status(id, g_iSquad[id]) == STATUS_LEADER)
	{
		menu_additem(Menu, "Przekaz \rPrzywodctwo", "1");
		
		if(iFlag == STATUS_MEMBER)
			menu_additem(Menu, "Mianuj \rZastepce", "2");
			
		if(iFlag == STATUS_ADMIN)
			menu_additem(Menu, "Degraduj \rZastepce", "3");
	}
	
	menu_additem(Menu, "Wyrzuc \rGracza", "4");
	
	menu_setprop(Menu, MPROP_EXITNAME, "\wWyjdz");
	menu_display(id, Menu, 0);
	
	return PLUGIN_CONTINUE;
}

public MemberMenu2_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		Cmd_Squad(id);
		return PLUGIN_HANDLED;
	}
	
	new Info[3], iAccess, Callback;
	menu_item_getinfo(menu, item, iAccess, Info, 2, "", 0, Callback);

	switch(str_to_num(Info))
	{
		case 1: UpdateMember(id, STATUS_LEADER);
		case 2:	UpdateMember(id, STATUS_ADMIN);
		case 3:	UpdateMember(id, STATUS_MEMBER);
		case 4: UpdateMember(id, STATUS_NONE);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

public UpdateMember(id, status)
{
	new bool:PlayerOnline;
	
	new iPlayers[32], iNum, iPlayer;
	get_players(iPlayers, iNum);

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
			
		if(g_iSquad[iPlayer] != g_iSquad[id] || is_user_hltv(iPlayer) || !is_user_connected(iPlayer))
			continue;
			
		if(get_user_userid(iPlayer) == ChosenID[id])
		{
			switch(status)
			{
				case STATUS_LEADER:
				{
					set_user_status(id, g_iSquad[id], STATUS_ADMIN);
					set_user_status(iPlayer, g_iSquad[id], STATUS_LEADER);
					client_print_color(iPlayer, iPlayer, "%s Zostales mianowany przywodca oddzialu!", szPrefix);
				}
				case STATUS_ADMIN:
				{
					set_user_status(iPlayer, g_iSquad[id], STATUS_ADMIN);
					client_print_color(iPlayer, iPlayer, "%s ^x01 Zostales zastepca przywodcy oddzialu!", szPrefix);		
				}
				case STATUS_MEMBER:
				{
					set_user_status(iPlayer, g_iSquad[id], STATUS_MEMBER);
					client_print_color(iPlayer, iPlayer, "%s ^x01 Zostales zdegradowany do rangi czlonka oddzialu.", szPrefix);
				}
				case STATUS_NONE:
				{
					log_to_file("addons/amxmodx/logs/squads.log", "Wyrzucenie z oddzialu: %s", ChosenName[id]);
					set_user_squad(iPlayer);
					client_print_color(iPlayer, iPlayer, "%s Zostales wyrzucony z oddzialu.", szPrefix);
				}
			}
			
			PlayerOnline = true;
			continue;
		}
		
		switch(status)
		{
			case STATUS_LEADER: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^01 zostal nowym przywodca oddzialu.", szPrefix, ChosenName[id]);
			case STATUS_ADMIN: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 zostal zastepca przywodcy oddzialu.", szPrefix, ChosenName[id]);
			case STATUS_MEMBER: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^x01 zostal zdegradowany do rangi czlonka oddzialu.", szPrefix, ChosenName[id]);
			case STATUS_NONE: client_print_color(iPlayer, iPlayer, "%s ^x03 %s^01 zostal wyrzucony z oddzialu.", szPrefix, ChosenName[id]);
		}
	}
	
	if(!PlayerOnline)
	{
		new TempName[64];
		mysql_escape_string(ChosenName[id], TempName, charsmax(TempName));
		
		SaveMember(id, status, TempName);
		
		if(status == STATUS_NONE)
		{
			new aData[SquadInfo];
			ArrayGetArray(g_aSquads, g_iSquad[id], aData);
			
			aData[SquadMembers]--;
			ArraySetArray(g_aSquads, g_iSquad[id], aData);
			
			SaveSquad(g_iSquad[id]);
			
			log_to_file("addons/amxmodx/logs/squads.log", "Wyrzucenie z oddzialu: %s", ChosenName[id]);
		}
	}
	
	Cmd_Squad(id);
	
	return PLUGIN_HANDLED;
}

public DepositAmmoPacks_Handle(id)
{
	if(!g_iSquad[id])
		return PLUGIN_HANDLED;
		
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, g_iSquad[id], aData);
	
	new szArgs[10], iAmmoPacks;
	
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	iAmmoPacks = str_to_num(szArgs);
	
	if(iAmmoPacks <= 0)
	{
		client_print_color(id, id, "%s Probujesz wplacic ujemna lub zerowa ilosc AmmoPackow!", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	if(iAmmoPacks > zp_get_user_ammo_packs(id))
	{
		client_print_color(id, id, "%s Nie masz tyle AmmoPackow!", szPrefix);
		return PLUGIN_HANDLED;
	}
	
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - iAmmoPacks);
	
	aData[SquadAmmoPacks] += iAmmoPacks;
	ArraySetArray(g_aSquads, g_iSquad[id], aData);
	
	SaveSquad(g_iSquad[id]);
	zp_save_ammopacks(id);
	
	client_print_color(id, id, "%s Wplaciles^x03 %i^x01 AmmoPackow na rzecz oddzialu.", szPrefix, iAmmoPacks);
	client_print_color(id, id, "%s Aktualnie twoj oddzial ma^x03 %i^x01 AmmoPackow.", szPrefix, aData[SquadAmmoPacks]);
	
	return PLUGIN_HANDLED;
}

public Squads_Top15(id)
{
	new szTemp[512], Data[1];
	Data[0] = id;
	
	format(szTemp, charsmax(szTemp), "SELECT squad_name, members, ammopacks, kills, level, speed, gravity, weapondrop, damage FROM `squads` ORDER BY kills DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowSquads_Top15", szTemp, Data, 1);
}

public ShowSquads_Top15(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState) 
	{
		log_to_file("addons/amxmodx/logs/squads.log", "SQL Error: %s (%d)", Error, ErrCode);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	static iLen, iPlace = 0;
	
	iLen = format(szMessage, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(szMessage[iLen], 2047 - iLen, "%1s %-22.22s %4s %8s %6s %8s %9s %12s %11s^n", "#", "Nazwa", "Czlonkowie", "Poziom", "Zabicia", "AmmoPacki", "Predkosc", "Grawitacja", "Obezwladnienie", "Obrazenia");
	
	while(SQL_MoreResults(Query))
	{
		iPlace++;
		static szName[32], iMembers, iLevel, iKills, iAmmoPacks, iSpeed, iGravity, iWeaponDrop, iDamage;
		SQL_ReadResult(Query, 0, szName, 31);
		replace_all(szName, 31, "<", "");
		replace_all(szName, 31, ">", "");
		iMembers = SQL_ReadResult(Query, 1);
		iAmmoPacks = SQL_ReadResult(Query, 2);
		iKills = SQL_ReadResult(Query, 3);
		iLevel = SQL_ReadResult(Query, 4);
		iSpeed = SQL_ReadResult(Query, 5);
		iGravity = SQL_ReadResult(Query, 6);
		iWeaponDrop = SQL_ReadResult(Query, 7);
		iDamage = SQL_ReadResult(Query, 8);
		
		if(iPlace >= 10)
			iLen += format(szMessage[iLen], 2047 - iLen, "%1i %22.22s %5d %8d %10d %8d %7d %10d %14d^n", iPlace, szName, iMembers, iLevel, iKills, iAmmoPacks, iSpeed, iGravity, iWeaponDrop, iDamage);
		else
			iLen += format(szMessage[iLen], 2047 - iLen, "%1i %22.22s %6d %8d %10d %8d %7d %10d %14d^n", iPlace, szName, iMembers, iLevel, iKills, iAmmoPacks, iSpeed, iGravity, iWeaponDrop, iDamage);
		
		log_amx(szName);
		SQL_NextRow(Query);
	}
	
	show_motd(id, szMessage, "Top 15 Oddzialow");
	
	return PLUGIN_HANDLED;
}

public Squads_Top15_Sort(const iElement1[], const iElement2[], const iArray[], szData[], iSize) 
{
	if(iElement1[1] > iElement2[1])
		return -1;
	
	else if(iElement1[1] < iElement2[1])
		return 1;
	
	return 0;
}

public handleSayText(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !g_iSquad[id])
		return PLUGIN_CONTINUE;
	
	new szTmp[192], szTmp2[192];
	get_msg_arg_string(2, szTmp, charsmax(szTmp))
	
	new szPrefix[20];
	new i = g_iSquad[id];
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, i, aData);
	
	formatex(szPrefix, charsmax(szPrefix), "^x04[%s]", aData[SquadName]);
	
	if(!equal(szTmp, "#Cstrike_Chat_All"))
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), " ");
		add(szTmp2, charsmax(szTmp2), szTmp);
	}
	else
	{
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), "^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2, szTmp2);
	
	return PLUGIN_CONTINUE;
}

set_user_squad(id, iSquad = 0, iOwner = 0)
{
	if(!is_user_connected(id) || is_user_hltv(id))
		return PLUGIN_CONTINUE;

	new aData[SquadInfo];
	
	if(iSquad == 0)
	{
		ArrayGetArray(g_aSquads, g_iSquad[id], aData);
		aData[SquadMembers]--;
		ArraySetArray(g_aSquads, g_iSquad[id], aData);
		TrieDeleteKey(aData[SquadStatus], g_MemberName[id]);
		
		SaveSquad(g_iSquad[id]);
		
		SaveMember(id, STATUS_NONE);
		
		Password[id] = false;
		g_iSquad[id] = 0;
	}
	else
	{
		g_iSquad[id] = iSquad;
		
		ArrayGetArray(g_aSquads, g_iSquad[id], aData);
		
		new TempSquadName[64];
		mysql_escape_string(aData[SquadName], TempSquadName, charsmax(TempSquadName));
		
		aData[SquadMembers]++;
		ArraySetArray(g_aSquads, g_iSquad[id], aData);
		TrieSetCell(aData[SquadStatus], g_MemberName[id], iOwner ? STATUS_LEADER : STATUS_MEMBER);
		
		SaveMember(id, iOwner ? STATUS_LEADER : STATUS_MEMBER, _, TempSquadName);
		
		SaveSquad(g_iSquad[id]);
	}
	
	return PLUGIN_CONTINUE;
}

set_user_status(id, iSquad, iStatus)
{
	if(!is_user_connected(id) || !iSquad)
		return PLUGIN_CONTINUE;
		
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, iSquad, aData);
	TrieSetCell(aData[SquadStatus], g_MemberName[id], iStatus);
	
	SaveMember(id, iStatus);
	
	return PLUGIN_CONTINUE;
}

get_user_status(id, iSquad)
{
	if(!is_user_connected(id) || iSquad == 0)
		return STATUS_NONE;
	
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, iSquad, aData);
	
	new iStatus;
	TrieGetCell(aData[SquadStatus], g_MemberName[id], iStatus);
	
	return iStatus;
}

public SqlInit()
{
	new db_data[4][64];
	get_cvar_string("zp_squads_sql_host", db_data[0], 63); 
	get_cvar_string("zp_squads_sql_user", db_data[1], 63); 
	get_cvar_string("zp_squads_sql_pass", db_data[2], 63); 
	get_cvar_string("zp_squads_sql_db", db_data[3], 63); 
	
	g_SqlTuple = SQL_MakeDbTuple(db_data[0], db_data[1], db_data[2], db_data[3]);
	
	formatex(g_Cache, charsmax(g_Cache), "CREATE TABLE IF NOT EXISTS `squads` (`squad_name` varchar(64) NOT NULL, `password` varchar(64) NOT NULL, `members` int(5) NOT NULL DEFAULT '1', `ammopacks` int(5) NOT NULL DEFAULT '0', `kills` int(5) NOT NULL DEFAULT '0', ");
	add(g_Cache, charsmax(g_Cache), "`level` int(5) NOT NULL DEFAULT '0', `speed` int(5) NOT NULL DEFAULT '0', `gravity` int(5) NOT NULL DEFAULT '0', `damage` int(5) NOT NULL DEFAULT '0', `weapondrop` int(5) NOT NULL DEFAULT '0', PRIMARY KEY (`squad_name`));");
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	
	formatex(g_Cache, charsmax(g_Cache), "CREATE TABLE IF NOT EXISTS `squad_members` (`name` varchar(64) NOT NULL, `squad` varchar(64) NOT NULL, `flag` int(5) NOT NULL DEFAULT '0', PRIMARY KEY (`name`));");
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
}

public TableHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState)
	{
		if(FailState == TQUERY_CONNECT_FAILED)
			log_to_file("addons/amxmodx/logs/squads.log", "Table - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		else if(FailState == TQUERY_QUERY_FAILED)
			log_to_file("addons/amxmodx/logs/squads.log", "Table Query failed. [%d] %s", ErrCode, Error);

		return;
	}
}

public SaveSquad(squad)
{
	new aData[SquadInfo];
	ArrayGetArray(g_aSquads, squad, aData);
	
	new TempSquadName[64];
	mysql_escape_string(aData[SquadName], TempSquadName, charsmax(TempSquadName));
	
	formatex(g_Cache, charsmax(g_Cache), "UPDATE `squads` SET password = '%s', level = '%i', ammopacks = '%i', kills = '%i', members = '%i', speed = '%i', gravity = '%i', weapondrop = '%i', damage = '%i' WHERE squad_name = '%s'", 
	aData[SquadPassword], aData[SquadLevel], aData[SquadAmmoPacks], aData[SquadKills], aData[SquadMembers], aData[SquadSpeed], aData[SquadGravity], aData[SquadWeaponDrop], aData[SquadDamage], TempSquadName);
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	log_to_file("addons/amxmodx/logs/squads.log", "SaveSquad: %s", g_Cache);
}

public LoadMember(id)
{
	get_user_name(id, g_MemberName[id], 63);
	mysql_escape_string(g_MemberName[id], g_MemberName[id], charsmax(g_MemberName))
	
	new data[1];
	data[0] = id;
	
	formatex(g_Cache, charsmax(g_Cache), "SELECT * FROM `squad_members` a JOIN `squads` b ON a.squad = b.squad_name WHERE a.name = '%s'", g_MemberName[id]);
	SQL_ThreadQuery(g_SqlTuple, "LoadMemberHandle", g_Cache, data, 1);
}

SaveMember(id, status, name[] = "", squad[] = "")
{
	if(!g_iSquad[id])
		return;
	
	if(status)
	{
		if(strlen(squad))
			formatex(g_Cache, charsmax(g_Cache), "UPDATE `squad_members` SET squad = '%s', flag = '%i' WHERE name = '%s'", squad, status, g_MemberName[id]);
		else
			formatex(g_Cache, charsmax(g_Cache), "UPDATE `squad_members` SET flag = '%i' WHERE name = '%s'", status, !strlen(name) ? g_MemberName[id] : name);
	}
	else
		formatex(g_Cache, charsmax(g_Cache), "UPDATE `squad_members` SET squad = '', flag = '0' WHERE name = '%s'", !strlen(name) ? g_MemberName[id] : name);
	
	log_to_file("addons/amxmodx/logs/squads.log", "SaveMember: %s", g_Cache);

	SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
}

public LoadMemberHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if(FailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/squads.log", "<Query> Error: %s", Error);
		return;
	}
	
	new id = Data[0];
	
	if(!is_user_connected(id))
		return;
	
	if(SQL_NumRows(Query))
	{
		new aData[SquadInfo], iStatus;
		new szSquad[64], szPassword[32];

		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "squad_name"), szSquad, charsmax(szSquad));
		if(!TrieKeyExists(g_tSquadNames, szSquad))
		{
			copy(aData[SquadName], charsmax(szSquad), szSquad);
			aData[SquadStatus] = _:TrieCreate();
			
			ArrayPushArray(g_aSquads, aData);
			TrieSetCell(g_tSquadNames, aData[SquadName], iCurSquad);
		
			SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "password"), aData[SquadPassword], charsmax(aData[SquadPassword]));

			aData[SquadLevel] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "level"));
			aData[SquadAmmoPacks] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ammopacks"));
			aData[SquadSpeed] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "speed"));
			aData[SquadGravity] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "gravity"));
			aData[SquadWeaponDrop] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "weapondrop"));
			aData[SquadDamage] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "damage"));
			aData[SquadKills] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "kills"));
			aData[SquadMembers] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "members"));
		
			ArraySetArray(g_aSquads, iCurSquad, aData);
			iCurSquad++;
		}
		
		TrieGetCell(g_tSquadNames, szSquad, g_iSquad[id]);
		ArrayGetArray(g_aSquads, g_iSquad[id], aData);
		iStatus = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "flag"));
		TrieSetCell(aData[SquadStatus], g_MemberName[id], iStatus);
			
		if(get_user_status(id, g_iSquad[id]) < STATUS_ADMIN)
			return;
			
		cmdExecute(id, "exec oddzial.cfg");
		get_user_info(id, "_oddzial", szPassword, charsmax(szPassword));
				
		if(equal(aData[SquadPassword], szPassword))
			Password[id] = true;
	}
	else
	{
		formatex(g_Cache, charsmax(g_Cache), "INSERT IGNORE INTO `squad_members` (`name`) VALUES ('%s');", g_MemberName[id]);
		SQL_ThreadQuery(g_SqlTuple, "TableHandle", g_Cache);
	}
}

public CheckSquadName(const szName[])
{
	new g_Cache[128];
	formatex(g_Cache, charsmax(g_Cache), "SELECT * FROM `squads` WHERE `squad_name` = '%s'", szName);
	
	new error, szError[128], bool:name;
	new Handle:g_Connect = SQL_Connect(g_SqlTuple, error, szError, 127);
	
	if(error)
	{
		log_to_file("addons/amxmodx/logs/squads.log", "<Query> Error: %s", szError);
		return true;
	}
	
	new Handle:Query = SQL_PrepareQuery(g_Connect, g_Cache);
	
	SQL_Execute(Query);
	
	if(SQL_NumResults(Query))
		name = true;
	else
		name = false;

	SQL_FreeHandle(Query);
	SQL_FreeHandle(g_Connect);
	
	return name;
}

public Config_Load() 
{
	new path[64];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	format(path, charsmax(path), "%s/%s", path, szFile);
    
	if (!file_exists(path)) 
	{
		new error[100];
		formatex(error, charsmax(error), "Brak pliku konfiguracyjnego: %s!", path);
		set_fail_state(error);
		return;
	}
    
	new linedata[1024], key[64], value[960], section;
	new file = fopen(path, "rt");
    
	while (file && !feof(file)) 
	{
		fgets(file, linedata, charsmax(linedata));
		replace(linedata, charsmax(linedata), "^n", "");
       
		if (!linedata[0] || linedata[0] == '/') continue;
		if (linedata[0] == '[') { section++; continue; }
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		switch (section) 
		{ 
			case 1: 
			{
				if (equal(key, "CREATE_LEVEL"))
					g_pCreateLevel = str_to_num(value);
				else if (equal(key, "MAX_MEMBERS"))
					g_pMaxMembers = str_to_num(value);
				else if (equal(key, "LEVEL_MAX"))
					g_pLevelMax = str_to_num(value);
				else if (equal(key, "SPEED_MAX"))
					g_pSpeedMax = str_to_num(value);
				else if (equal(key, "GRAVITY_MAX"))
					g_pGravityMax = str_to_num(value);
				else if (equal(key, "DAMAGE_MAX"))
					g_pDamageMax = str_to_num(value);
				else if (equal(key, "DROP_MAX"))
					g_pWeaponDropMax = str_to_num(value);
			}
			case 2: 
			{
				if (equal(key, "LEVEL_COST"))
					g_pLevelCost = str_to_num(value);
				else if (equal(key, "SPEED_COST"))
					g_pSpeedCost = str_to_num(value);
				else if (equal(key, "GRAVITY_COST"))
					g_pGravityCost = str_to_num(value);
				else if (equal(key, "DAMAGE_COST"))
					g_pDamageCost = str_to_num(value);
				else if (equal(key, "DROP_COST"))
					g_pWeaponDropCost = str_to_num(value);
				else if (equal(key, "LEVEL_COST_NEXT"))
					g_pNextLevelCost = str_to_num(value);
				else if (equal(key, "SPEED_COST_NEXT"))
					g_pNextSpeedCost = str_to_num(value);
				else if (equal(key, "GRAVITY_COST_NEXT"))
					g_pNextGravityCost = str_to_num(value);
				else if (equal(key, "DAMAGE_COST_NEXT"))
					g_pNextDamageCost = str_to_num(value);
				else if (equal(key, "DROP_COST_NEXT"))
					g_pNextWeaponDropCost = str_to_num(value);
			}
			case 3: 
			{
				if (equal(key, "MEMBERS_PER"))
					g_pMembersPerLevel = str_to_num(value);
				else if (equal(key, "SPEED_PER"))
					g_pSpeedPerLevel = str_to_num(value);
				else if (equal(key, "GRAVITY_PER"))
					g_pGravityPerLevel = str_to_num(value);
				else if (equal(key, "DAMAGE_PER"))
					g_pDamagePerLevel = str_to_num(value);
				else if (equal(key, "DROP_PER"))
					g_pWeaponDropPerLevel = str_to_num(value);
			}
		}
	}
	if (file) fclose(file)
}

mysql_escape_string(const source[], dest[], len)
{
	copy(dest, len, source);
	replace_all(dest, len, "\\", "\\\\");
	replace_all(dest, len, "\0", "\\0");
	replace_all(dest, len, "\n", "\\n");
	replace_all(dest, len, "\r", "\\r");
	replace_all(dest, len, "\x1a", "\Z");
	replace_all(dest, len, "'", "\'");
	replace_all(dest, len, "`", "\`");
	replace_all(dest, len, "^"", "\^"");
}

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256];

    	format_args(szMessage, charsmax(szMessage), 1);

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
        write_byte(strlen(szMessage) + 2);
        write_byte(10);
        write_string(szMessage);
        message_end();
    }
}

Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
	return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
	return Ham_Item_PreFrame;
	#endif
}