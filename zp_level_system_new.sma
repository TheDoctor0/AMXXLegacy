#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <weapon>
#include <zombie_plague_advance>

#define TASK_HUD 4123
#define TASK_MENU 5904

#define MAX_LEVEL 18

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

stock const expTable[] = 
{
	0, 100, 250,				// 3 LVL
	500, 700, 1500, 2500, 3500,       // 8 LVL
	5000, 7500, 10000, 12500, 15000,   // 13 LVL
	17500, 20000, 25000, 30000, 40000   // 18 LVL
}

new const levelWeapons[MAX_LEVEL][2][] =
{
	{ "Pistolet", "Dual Infinity" },
	{ "Karabin", "M14 EBR" },
	{ "Karabin", "XM8 Basic" },
	{ "Karabin", "AK-47 Long" },
	{ "Karabin", "Dual Kriss" },
	{ "Snajperka", "SL-8EX" },
	{ "Snajperka", "Skull-5" },
	{ "Strzelba", "USAS12" },
	{ "Strzelba", "Double Barrel" },
	{ "Karabin", "Guitar" },
	{ "Karabin", "Plasma Gun" },
	{ "Karabin Maszynowy", "M134" },
	{ "Karabin Maszynowy", "SFMG" },
	{ "Zestaw", "Double Barrel + Dual Kriss" },
	{ "Zestaw", "Guitar + Skull-5" },
	{ "Zestaw", "Plasma Gun + Double Barrel" },
	{ "Zestaw", "M134 + Skull-5" },
	{ "Zestaw", "SFMG + Guitar" }
};

enum Stats
{
	Level,
	Exp
}

enum Classes
{
	Brak = 0,
	Lowca,
	Human,
	Skoczek,
	Barbarzynca
}

enum
{
	BRAK,
	LOWCA,
	HUMAN,
	SKOCZEK,
	BARBARZYNCA
}

new const class_names[][] = 
{
	"Brak",
	"Lowca",
	"Human",
	"Skoczek",
	"Barbarzynca (Premium)"
};

new const class_descriptions[][] = 
{
	"Brak",
	"Zadaje 5 obrazen wiecej, jest troche wolniejszy.",
	"Ma 20HP wiecej, dostaje +10 kamizelki",
	"Ma o 1/3 mniejsza grawitacje",
	"Zadaje 5 obrazen wiecej, +10 kamizelki i 1/4 mniejsza grawitacja."
};

new g_PlayerStats[33][Classes][Stats], g_Player[33][Stats], g_AmmoPacks[33], g_Class[33], g_NewClass[33], g_PlayerName[33][36], 
bool:g_WeaponTaken[33], bool:g_Loaded[33], bool:FreezeTime, g_MaxPlayers, Handle:hookSql;

native zp_ammopacks_set(id, ap);
native zp_ammopacks_get(id);
native register_system_check(id);

public plugin_init() 
{
	register_plugin("ZP Level System", "1.0", "O'Zone");
	
	register_cvar("zp_sql_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_user", "310529", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_pass", "IzQsAjTnjuPnJu41", FCVAR_SPONLY|FCVAR_PROTECTED); 
	register_cvar("zp_sql_db", "310529_zp", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	register_clcmd("say /klasa", "ChooseClass");
	register_clcmd("say /klasy", "ClassDescription");
	
	register_concmd("amx_setlvl", "SetLevel", ADMIN_ADMIN, "<nick> <level>");
	register_concmd("amx_addexp", "AddExp", ADMIN_ADMIN, "<nick> <exp>");
	register_concmd("amx_remexp", "RemoveExp", ADMIN_ADMIN, "<nick> <exp>");
	
	register_event("DeathMsg", "EventDeath", "a");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_logevent("RoundStart", 2, "1=Round_Start"); 
	register_forward(FM_ClientDisconnect, "client_disconnect");
	register_message(SVC_INTERMISSION, "MsgIntermission");
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	RegisterHam(Ham_TakeDamage, "player","TakeDamage", 0);
	RegisterHam(Ham_Item_PreFrame, "player", "SetSpeed", 1);
	
	g_MaxPlayers = get_maxplayers();
	
	sql_init();
}

public plugin_precache()
	precache_sound("common/wpn_denyselect.wav");

public plugin_natives()
{
	register_native("zp_get_user_class", "nativeGetUserClass");
	register_native("zp_set_user_class", "nativeSetUserClass");
	
	register_native("zp_get_user_level", "nativeGetUserLevel");
	register_native("zp_set_user_level", "nativeSetUserLevel");
	
	register_native("zp_show_weapon_menu", "nativeShowWeaponMenu");
	
	register_native("zp_get_classes_num", "nativeGetClassesNum", 1);
	register_native("zp_get_class_name", "nativeGetClassName", 1);

	register_native("zp_add_user_exp", "nativeAddUserExp");
	register_native("zp_get_user_exp", "nativeGetUserExp");
	register_native("zp_set_user_exp", "nativeSetUserExp");
	
	register_native("zp_save_ammopacks", "nativeSaveAmmoPacks");
}

public plugin_end()
	SQL_FreeHandle(hookSql);

public sql_init()
{
	new db_data[4][64];
	get_cvar_string("zp_sql_host", db_data[0], 63); 
	get_cvar_string("zp_sql_user", db_data[1], 63); 
	get_cvar_string("zp_sql_pass", db_data[2], 63); 
	get_cvar_string("zp_sql_db", db_data[3], 63);  
	
	hookSql = SQL_MakeDbTuple(db_data[0], db_data[1], db_data[2], db_data[3]);

	new error, szError[128];
	new Handle:hConn = SQL_Connect(hookSql, error, szError, 127);
	
	if(error)
	{
		log_amx("Error: %s", szError);
		return;
	}
	
	new szTemp[1024];
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `save_stats_system` (name VARCHAR(35), lowcalvl INT (11), lowcaxp INT (11), humanlvl INT (11), ");
	add(szTemp, charsmax(szTemp), "humanxp INT (11), skoczeklvl INT (11), skoczekxp INT (11), barbarzyncalvl INT (11), barbarzyncaxp INT (11), ammopacks INT (11), PRIMARY KEY(name));");

	new Handle:query = SQL_PrepareQuery(hConn, szTemp);
	SQL_Execute(query);
	SQL_FreeHandle(query);
	SQL_FreeHandle(hConn);
}

public client_putinserver(id)
{
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		reset_stats(id);
		
		load_sql(id);
		
		set_task(1.0, "ShowHUD", id+TASK_HUD, .flags="b");
	}
}

public reset_stats(id)
{
	g_PlayerName[id] = "";
	
	g_Loaded[id] = false;
	
	g_PlayerStats[id][Lowca][Level] = 1;
	g_PlayerStats[id][Lowca][Exp] = 0;
	g_PlayerStats[id][Human][Level] = 1;
	g_PlayerStats[id][Human][Exp] = 0;
	g_PlayerStats[id][Skoczek][Level] = 1;
	g_PlayerStats[id][Skoczek][Exp] = 0;
	g_PlayerStats[id][Barbarzynca][Level] = 1;
	g_PlayerStats[id][Barbarzynca][Exp] = 0;
	
	g_Player[id][Level] = 1;
	g_Player[id][Exp] = 0;
	g_AmmoPacks[id] = 0;
	
	g_Class[id] = 0;
	g_NewClass[id] = 0;
}

public client_disconnected(id)
{ 
	if(!is_user_bot(id) && !is_user_hltv(id))
	{	
		save_stats(id, 1);
		remove_task(id + TASK_HUD);
		remove_task(id + TASK_MENU);
	}
}

public load_sql(id)
{
	get_user_name(id, g_PlayerName[id], charsmax(g_PlayerName[]));
	replace_all(g_PlayerName[id], 35, "'", "\'" );
	replace_all(g_PlayerName[id], 35, "`", "\`" );  
	replace_all(g_PlayerName[id], 35, "\\", "\\\\" );
	replace_all(g_PlayerName[id], 35, "^0", "\0");
	replace_all(g_PlayerName[id], 35, "^n", "\n");
	replace_all(g_PlayerName[id], 35, "^r", "\r");
	replace_all(g_PlayerName[id], 35, "^x1a", "\Z");
	
	new data[1], szTemp[256];
	data[0] = id;
	
	formatex(szTemp, 255, "SELECT * FROM `save_stats_system` WHERE name = '%s'", g_PlayerName[id]);
	SQL_ThreadQuery(hookSql, "load_stats", szTemp, data, 1);
}

public load_stats(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("<Query> Error: %s", error);
		return;
	}
	
	new id = data[0];
	
	if(!is_user_connected(id))
		return;
	
	if(SQL_MoreResults(query))
	{
		g_PlayerStats[id][Lowca][Level] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "lowcalvl"));
		g_PlayerStats[id][Lowca][Exp] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "lowcaxp"));
		g_PlayerStats[id][Human][Level] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "humanlvl"));
		g_PlayerStats[id][Human][Exp] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "humanxp"));
		g_PlayerStats[id][Skoczek][Level] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "skoczeklvl"));
		g_PlayerStats[id][Skoczek][Exp] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "skoczekxp"));
		g_PlayerStats[id][Barbarzynca][Level] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "barbarzyncalvl"));
		g_PlayerStats[id][Barbarzynca][Exp] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "barbarzyncaxp"));
		g_AmmoPacks[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "ammopacks"));
		
		zp_ammopacks_set(id, g_AmmoPacks[id]);
		
		if(!g_PlayerStats[id][Lowca][Level] && g_PlayerStats[id][Lowca][Exp]) while(g_PlayerStats[id][Lowca][Exp] >= expTable[g_PlayerStats[id][Lowca][Level]]) g_PlayerStats[id][Lowca][Level]++;
		if(!g_PlayerStats[id][Human][Level] && g_PlayerStats[id][Human][Exp]) while(g_PlayerStats[id][Human][Exp] >= expTable[g_PlayerStats[id][Human][Level]]) g_PlayerStats[id][Human][Level]++;
		if(!g_PlayerStats[id][Skoczek][Level] && g_PlayerStats[id][Skoczek][Exp]) while(g_PlayerStats[id][Skoczek][Exp] >= expTable[g_PlayerStats[id][Skoczek][Level]]) g_PlayerStats[id][Skoczek][Level]++;
		if(!g_PlayerStats[id][Barbarzynca][Level] && g_PlayerStats[id][Barbarzynca][Exp]) while(g_PlayerStats[id][Barbarzynca][Exp] >= expTable[g_PlayerStats[id][Barbarzynca][Level]]) g_PlayerStats[id][Barbarzynca][Level]++;
	}
	else
	{
		g_AmmoPacks[id] = get_cvar_num("zp_starting_ammo_packs");
		
		new szTemp[256];
		formatex(szTemp, 255, "INSERT INTO `save_stats_system` VALUES ('%s', '1', '0', '1', '0', '1', '0', '1', '0', '%i')", g_PlayerName[id], g_AmmoPacks[id]);
		SQL_ThreadQuery(hookSql, "load_ignore", szTemp);
		zp_ammopacks_set(id, g_AmmoPacks[id]);
	}
	
	g_Loaded[id] = true;
	
	if(is_user_alive(id) && !zp_get_user_zombie(id)) ChooseClass(id);
}

public load_ignore(FailState, Handle:Query, Error[], ErrCode, Data[], Size)
{
	if(FailState != TQUERY_SUCCESS)
	{
		log_to_file("addons/amxmodx/logs/save_stats_system.txt", "Save/Load - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		return;
	}
}

public WeaponMenu(id) 
{
	new szMenu[128];
	new menu = menu_create("\yWybierz \rBron", "WeaponMenu_Handle");
	
	for(new i = 0; i < MAX_LEVEL; i++)
	{
		formatex(szMenu, charsmax(szMenu), "\y[%s] \w%s \r(%i LVL)", levelWeapons[i][0], levelWeapons[i][1], i + 1);
		menu_additem(menu, szMenu);
	}
	
	set_task(30.0, "CloseMenu", id + TASK_MENU);
 
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_BACKNAME, "Wstecz");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
}
 
public WeaponMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if(g_Player[id][Level] < item + 1)
	{
		client_print_color(id, id, "^x04[ZP]^x01 Nie masz wystarczajacego^x03 poziomu^x01! Twoj Poziom:^x04 %d^x01 (Wymagany^x03 %i^x01).", g_Player[id][Level], item + 1);
		WeaponMenu(id);
		return PLUGIN_CONTINUE;
	}
	
	client_print_color(id, id, "^x04[ZP]^x01 Dostales^x04 %s^x01.", levelWeapons[item][1]);
	
	g_WeaponTaken[id] = true;
	
	switch(item)
	{
		case 0: give_dinfinity(id);
		case 1: give_weapon_balrog5(id);
		case 2: give_cso_cart_blue(id);
		case 3: give_weapon_ak47long(id);
		case 4: give_kriss(id, 1);
		case 5: give_weapon_sl8ex(id);
		case 6: give_weapon_skull5(id, 1);
		case 7: give_weapon_usas(id);
		case 8: give_weapon_dbarrel(id, 1);
		case 9: give_weapon_guitar1(id, 1);
		case 10: give_weapon_plasmagun(id, 1);
		case 11: give_weapon_m134ex(id);
		case 12: give_weapon_sfmg(id, 1);
		case 13: 
		{ 
			give_weapon_dbarrel(id, 0); 
			give_dinfinity(id); 
		}
		case 14: 
		{ 
			give_weapon_guitar1(id, 0); 
			give_weapon_skull5(id, 0); 
		}
		case 15: 
		{ 
			give_weapon_plasmagun(id, 0); 
			give_weapon_dbarrel(id, 0); 
		}
		case 16: 
		{ 
			give_weapon_m134ex(id); 
			give_weapon_skull5(id, 0); 
		}
		case 17: 
		{ 
			give_weapon_sfmg(id, 0);
			give_weapon_guitar1(id, 0); 
		}
	}
	
	remove_task(id + TASK_MENU);
	return PLUGIN_CONTINUE;
}

public CloseMenu(id)
{
	id -= TASK_MENU;
	
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	show_menu(id, 0, "^n", 1);
	
	new weapon = random_num(1, g_Player[id][Level]) - 1;
	
	client_print_color(id, id, "^x04[ZP]^x01 Dostales^x04 %s^x01.", levelWeapons[weapon][1]);
	
	switch(weapon)
	{
		case 0: give_dinfinity(id);
		case 1: give_weapon_balrog5(id);
		case 2: give_cso_cart_blue(id);
		case 3: give_weapon_ak47long(id);
		case 4: give_kriss(id, 1);
		case 5: give_weapon_sl8ex(id);
		case 6: give_weapon_skull5(id, 1);
		case 7: give_weapon_usas(id);
		case 8: give_weapon_dbarrel(id, 1);
		case 9: give_weapon_guitar1(id, 1);
		case 10: give_weapon_plasmagun(id, 1);
		case 11: give_weapon_m134ex(id);
		case 12: give_weapon_sfmg(id, 1);
		case 13: 
		{ 
			give_weapon_dbarrel(id, 0); 
			give_dinfinity(id); 
		}
		case 14: 
		{ 
			give_weapon_guitar1(id, 0); 
			give_weapon_skull5(id, 0); 
		}
		case 15: 
		{ 
			give_weapon_plasmagun(id, 0); 
			give_weapon_dbarrel(id, 0); 
		}
		case 16: 
		{ 
			give_weapon_m134ex(id); 
			give_weapon_skull5(id, 0); 
		}
		case 17: 
		{ 
			give_weapon_sfmg(id, 0);
			give_weapon_guitar1(id, 0); 
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ChooseClass(id) 
{
	if(!g_Loaded[id])
	{
		client_print_color(id, id, "^x04[ZP]^x01 Trwa na zaladowanie danych...");
		return PLUGIN_HANDLED;
	}
	
	if(!register_system_check(id))
		return PLUGIN_HANDLED;
	
	new menu = menu_create("Wybierz \rKlase:", "ChooseClass_Handle");
	new class[50];
	
	for(new i=1; i < sizeof class_names; i++) 
	{
		switch(i)
		{
			case Lowca: format(class, 49, "\y%s \rPoziom: %i", class_names[i], g_PlayerStats[id][Lowca][Level]);
			case Human: format(class, 49, "\y%s \rPoziom: %i", class_names[i], g_PlayerStats[id][Human][Level]);
			case Skoczek: format(class, 49, "\y%s \rPoziom: %i", class_names[i], g_PlayerStats[id][Skoczek][Level]);
			case Barbarzynca: format(class, 49, "\y%s \rPoziom: %i", class_names[i], g_PlayerStats[id][Barbarzynca][Level]);
		}
		menu_additem(menu, class);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ChooseClass_Handle(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}    
	
	item++;
	
	if(item == g_Class[id])
		return PLUGIN_CONTINUE;
	
	if(item == BARBARZYNCA && !(get_user_flags(id) & ADMIN_LEVEL_H)) 
	{
		client_print_color(id, id, "^x04[ZP]^x01 Nie jestes uprawniony, aby korzystac z klasy^x04 Premium^x01.");
		ChooseClass(id);
		return PLUGIN_CONTINUE;
	}
	
	if(g_Class[id]) 
	{
		g_NewClass[id] = item;
		client_print_color(id, id, "^x04[ZP]^x01 Twoja klasa zmieni sie w^x04 kolejnej^x01 rundzie.");
	}
	else 
	{
		g_Class[id] = item;
		
		switch(g_Class[id])
		{
			case Lowca: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Lowca][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Lowca][Exp];
			}
			case Human: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Human][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Human][Exp];
			}
			case Skoczek: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Skoczek][Level];
				g_Player[id][Exp] = g_PlayerStats[id][Skoczek][Exp];
			}
			case Barbarzynca: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Barbarzynca][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Barbarzynca][Exp];
			}
		}
		
		Spawn(id);
	}
	return PLUGIN_CONTINUE;
}

public ClassDescription(id)
{
	new menu = menu_create("Wybierz Klase:", "ClassDescription_Handle");
	for(new i = 1; i < sizeof class_names; i++)
		menu_additem(menu, class_names[i]);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
}

public ClassDescription_Handle(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	client_print_color(id, id, "^x04[ZP]^x01 %s: %s", class_names[item+1], class_descriptions[item+1]);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public Spawn(id) 
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	g_WeaponTaken[id] = false;
		
	if(g_NewClass[id]) 
	{
		g_Class[id] = g_NewClass[id];
		g_NewClass[id] = 0;
		
		switch(g_Class[id])
		{
			case Lowca: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Lowca][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Lowca][Exp];
			}
			case Human: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Human][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Human][Exp];
			}
			case Skoczek: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Skoczek][Level];
				g_Player[id][Exp] = g_PlayerStats[id][Skoczek][Exp];
			}
			case Barbarzynca: 
			{
				g_Player[id][Level] = g_PlayerStats[id][Barbarzynca][Level]; 
				g_Player[id][Exp] = g_PlayerStats[id][Barbarzynca][Exp];
			}
		}
	}
	
	if(!g_Class[id])
	{
		ChooseClass(id);
		return PLUGIN_CONTINUE;
	}
	
	if(zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return PLUGIN_CONTINUE;

	if(g_Class[id])
		WeaponMenu(id);
	
	ResetAbilities(id);
	return PLUGIN_CONTINUE;
}

public ResetAbilities(id) 
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	set_user_gravity(id, 1.0);
	
	if(get_user_health(id) == 120)
		set_user_health(id, 100);
		
	if(get_user_flags(id) & ADMIN_LEVEL_H)
		set_user_armor(id, 45);
	else
		set_user_armor(id, 0);
		
	set_task(0.1, "SetAbilities", id);
	
	return PLUGIN_CONTINUE;
}

public SetAbilities(id) 
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	switch(g_Class[id]) 
	{
		case Human: 
		{
			set_user_armor(id, get_user_armor(id) + 10);
			set_user_health(id, get_user_health(id) + 20);
		}
		case Skoczek: 
		{
			set_user_gravity(id, 0.66);
		}
		case Barbarzynca: 
		{
			set_user_gravity(id, 0.75);
			set_user_armor(id, get_user_armor(id) + 10);
		}
	}
	return PLUGIN_CONTINUE;
}

public EventDeath() 
{
	new iKiller = read_data(1), iVictim = read_data(2), iHS = read_data(3);
	
	if(iKiller == iVictim || !is_user_connected(iKiller))
		return;
	
	g_Player[iKiller][Exp] += 1;
	
	if(iHS)	
		g_Player[iKiller][Exp] += 1;
	
	CheckLevel(iKiller);
}

public CheckLevel(id) 
{
	if(g_Player[id][Level] < MAX_LEVEL)
	{
		while(g_Player[id][Exp] >= expTable[g_Player[id][Level]])
		{
			g_Player[id][Level]++;
			client_print_color(id, id, "^x04[ZP]^x01 Gratulacje. Awansowales na^x03 %i^x01 poziom!", g_Player[id][Level]);
		}
	}
	
	save_stats(id, 0);
}

public ShowHUD(id) 
{
	id -= TASK_HUD;
		
	if(!is_user_alive(id)) 
	{
		if(!is_valid_ent(id))
			return PLUGIN_CONTINUE;
		
		new iDest = entity_get_int(id, EV_INT_iuser2);
		
		if(iDest == 0)
			return PLUGIN_CONTINUE;
		
		set_dhudmessage(255, 255, 255, -1.0, 0.65, 0, 0.1, 1.0, 0.1, 0.0);
		if(g_Player[iDest][Level] >= MAX_LEVEL)
			show_dhudmessage(id , "[KLASA: %s] [LVL: %d] [EXP: %d]", class_names[g_Class[iDest]], g_Player[iDest][Level], g_Player[iDest][Exp]);
		else
			show_dhudmessage(id , "[KLASA: %s] [LVL: %d] [EXP: %d / %d]", class_names[g_Class[iDest]], g_Player[iDest][Level], g_Player[iDest][Exp], expTable[g_Player[iDest][Level]]);
		
		return PLUGIN_CONTINUE;
	}
	
	set_dhudmessage(0, 255, 0, -1.0, 0.7, 0, 0.1, 1.0, 0.1, 0.0);
	if(g_Player[id][Level] >= MAX_LEVEL)
		show_dhudmessage(id, "[KLASA: %s] [LVL: %d] [EXP: %d]", class_names[g_Class[id]], g_Player[id][Level], g_Player[id][Exp]);
	else
		show_dhudmessage(id, "[KLASA: %s] [LVL: %d] [EXP: %d / %d]", class_names[g_Class[id]], g_Player[id][Level], g_Player[id][Exp], expTable[g_Player[id][Level]]);
	
	return PLUGIN_CONTINUE;
}

public TakeDamage(victim, inflictor, attacker, Float:damage, bits) 
{
	if(!is_user_valid(victim) || !is_user_valid(attacker))
		return HAM_IGNORED;
		
	if(g_Class[attacker] == LOWCA || g_Class[attacker] == BARBARZYNCA) 
	{
		SetHamParamFloat(4, damage + 5.0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public RoundStart()
	FreezeTime = false; 
	
public NewRound()
	FreezeTime = true; 

public SetSpeed(id) 
{
	if(!is_user_alive(id))
		return HAM_IGNORED;
	
	if(FreezeTime)
		return HAM_IGNORED;
	
	if(g_Class[id] == LOWCA)
		set_user_maxspeed(id, get_user_maxspeed(id) - 20);
	
	return HAM_IGNORED;
}

public save_stats(id, type)
{
	if(!g_Loaded[id])
		return;
		
	if(type)
		g_Loaded[id] = false;
		
	switch(g_Class[id])
	{
		case Lowca:
		{
			g_PlayerStats[id][Lowca][Level] = g_Player[id][Level];
			g_PlayerStats[id][Lowca][Exp] = g_Player[id][Exp];
		}
		case Human:
		{
			g_PlayerStats[id][Human][Level] = g_Player[id][Level];
			g_PlayerStats[id][Human][Exp] = g_Player[id][Exp];
		}
		case Skoczek:
		{
			g_PlayerStats[id][Skoczek][Level] = g_Player[id][Level];
			g_PlayerStats[id][Skoczek][Exp] = g_Player[id][Exp];
		}
		case Barbarzynca:
		{
			g_PlayerStats[id][Barbarzynca][Level] = g_Player[id][Level];
			g_PlayerStats[id][Barbarzynca][Exp] = g_Player[id][Exp];
		}
	}
		
	new stats[9];

	stats[0] = g_PlayerStats[id][Lowca][Level];
	stats[1] = g_PlayerStats[id][Lowca][Exp];
	stats[2] = g_PlayerStats[id][Human][Level];
	stats[3] = g_PlayerStats[id][Human][Exp];
	stats[4] = g_PlayerStats[id][Skoczek][Level];
	stats[5] = g_PlayerStats[id][Skoczek][Exp];
	stats[6] = g_PlayerStats[id][Barbarzynca][Level];
	stats[7] = g_PlayerStats[id][Barbarzynca][Exp];
	stats[8] = zp_ammopacks_get(id);
	
	new szTemp[256];
	formatex(szTemp, 255, "UPDATE `save_stats_system` SET lowcalvl=%d, lowcaxp=%d, humanlvl=%d, humanxp=%d, skoczeklvl=%d, skoczekxp=%d, barbarzyncalvl=%d, barbarzyncaxp=%d, ammopacks=%d WHERE name='%s'", 
	stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7], stats[8], g_PlayerName[id]);
	
	if(type)
		log_to_file("addons/amxmodx/logs/save_stats_system.txt", szTemp);
	
	switch(type)
	{
		case 0: SQL_ThreadQuery(hookSql, "load_ignore", szTemp);
		case 1:
		{
			SQL_ThreadQuery(hookSql, "load_ignore", szTemp);
			reset_stats(id);
		}
		case 2:
		{
			new ErrCode, Error[128], Handle:SqlConnection, Handle:Query;
			SqlConnection = SQL_Connect(hookSql, ErrCode, Error, charsmax(Error));

			if (!SqlConnection)
			{
				log_to_file("addons/amxmodx/logs/save_stats_system.txt", "Save - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
				SQL_FreeHandle(SqlConnection);
				return;
			}
			
			Query = SQL_PrepareQuery(SqlConnection, szTemp);
			if (!SQL_Execute(Query))
			{
				ErrCode = SQL_QueryError(Query, Error, charsmax(Error));
				log_to_file("addons/amxmodx/logs/save_stats_system.txt", "Save Query Nonthreaded failed. [%d] %s", ErrCode, Error);
				SQL_FreeHandle(Query);
				SQL_FreeHandle(SqlConnection);
				return;
			}
	
			SQL_FreeHandle(Query);
			SQL_FreeHandle(SqlConnection);
			
			reset_stats(id);
		}
	}
}

public zp_user_infected_post(infected, infector)
	save_stats(infector, 0);

public zp_extra_item_selected(id, itemid)
	save_stats(id, 0);

public MsgIntermission() 
{
	new szPlayers[32], id, iNum;
	get_players(szPlayers, iNum, "h");
	
	if(iNum < 1)
		return PLUGIN_CONTINUE;
		
	for (new i = 0; i < iNum; i++)
	{
		id = szPlayers[i];
		
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id))
			continue;
		
		save_stats(id, 2);
	}
	
	return PLUGIN_CONTINUE;
}

public SetLevel(id, level, target)
{
	if(!cmd_access(id, level, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33], arg2[10];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 9);
	
	new player = cmd_target(id, arg1, 0);
	if(!is_user_connected(player))
	{
		client_print(id, print_console, "[ZP] Nie znaleziono podanego gracza.")
		return PLUGIN_HANDLED;
	}
	
	new level = str_to_num(arg2);
	if(level > sizeof expTable) 
	{
		client_print(id, print_console, "[ZP] Chciales ustawic za duzy poziom.");
		return PLUGIN_HANDLED;
	}
	
	g_Player[player][Level] = level;
	g_Player[player][Exp] = expTable[level - 1];
	CheckLevel(player);
	
	client_print(id, print_console, "[ZP] Pomyslnie ustawiono poziom graczowi.");
	
	return PLUGIN_HANDLED;
}

public nativeSaveAmmoPacks(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	save_stats(id, 0);
	
	return true;
}

public AddExp(id, exp, target)
{
	if(!cmd_access(id, exp, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33], arg2[10];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 9);
	
	new player = cmd_target(id, arg1, 0);
	if(!is_user_connected(player))
	{
		client_print(id, print_console, "[ZP] Nie znaleziono podanego gracza.")
		return PLUGIN_HANDLED;
	}

	new exp = str_to_num(arg2);
	g_Player[player][Exp] += exp;
	CheckLevel(player);
	
	client_print(id, print_console, "[ZP] Pomyslnie dodano exp graczowi.");
	
	return PLUGIN_HANDLED;
}

public RemoveExp(id, exp, target)
{
	if(!cmd_access(id, exp, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33], arg2[10];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 9);
	
	new player = cmd_target(id, arg1, 0);
	if(!is_user_connected(player))
	{
		client_print(id, print_console, "[ZP] Nie znaleziono podanego gracza.")
		return PLUGIN_HANDLED;
	}

	new exp = str_to_num(arg2);
	if(g_Player[id][Exp] - exp < 0) 
	{
		client_print(id, print_console, "[ZP] Chciales odjac graczowi za duzo expa.")
		return PLUGIN_HANDLED;
	} 
	
	g_Player[id][Exp] -= exp;
	g_Player[id][Level] = 1;
	CheckLevel(player);
	
	client_print(id, print_console, "[ZP] Pomyslnie odjeto exp graczowi.");
	
	return PLUGIN_HANDLED;
}
	
public nativeGetUserExp(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_Player[id][Exp];
}

public nativeAddUserExp(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	g_Player[id][Exp] += get_param(2);
	CheckLevel(id);
	
	return true;
}

public nativeSetUserExp(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	g_Player[id][Exp] = get_param(2);
	g_Player[id][Level] = 1;
	CheckLevel(id);
	
	return true;
}

public nativeGetUserClass(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_Class[id];
}

public nativeSetUserClass(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	g_Class[id] = get_param(2);
	
	switch(g_Class[id])
	{
		case Lowca: 
		{
			g_Player[id][Level] = g_PlayerStats[id][Lowca][Level]; 
			g_Player[id][Exp] = g_PlayerStats[id][Lowca][Exp];
		}
		case Human: 
		{
			g_Player[id][Level] = g_PlayerStats[id][Human][Level]; 
			g_Player[id][Exp] = g_PlayerStats[id][Human][Exp];
		}
		case Skoczek: 
		{
			g_Player[id][Level] = g_PlayerStats[id][Skoczek][Level];
			g_Player[id][Exp] = g_PlayerStats[id][Skoczek][Exp];
		}
		case Barbarzynca: 
		{
			g_Player[id][Level] = g_PlayerStats[id][Barbarzynca][Level]; 
			g_Player[id][Exp] = g_PlayerStats[id][Barbarzynca][Exp];
		}
	}
	
	return true;
}

public nativeGetUserLevel(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_Player[id][Level];
}

public nativeSetUserLevel(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	g_Player[id][Level] = get_param(2);
	g_Player[id][Exp] = expTable[get_param(2) - 1];
	save_stats(id, 0);
	
	return true;
}

public nativeShowWeaponMenu(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	if(!g_Class[id] || g_WeaponTaken[id] || !is_user_alive(id))
		return false;
		
	if(zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return false;
	
	WeaponMenu(id);
	
	return true;
}

public nativeGetClassesNum()
{
	return charsmax(class_names);
}

public nativeGetClassName(class, Return[], len)
{
	if(class <= charsmax(class_names))
	{
		param_convert(2);
		copy(Return, len, class_names[class]);
	}
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