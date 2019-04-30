#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <sqlx>
#include <unixtime>
#include <stripweapons>
#if AMXX_VERSION_NUM < 183
#include <colorchat>
#include <dhudmessage>
#endif

#define PLUGIN "Battlefield One Mod"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

#define MAX_PLAYERS 32
#define MAX_LENGHT 32
#define MAX_RANKS 17
#define MAX_BONUSRANKS 7
#define MAX_BADGES 10
#define MAX_ORDERS 10
#define MAX_DEGREES 5

#define TASK_HUD 9876
#define TASK_HELP 8765
#define TASK_GLOW 7654
#define TASK_FROST 6543
#define TASK_TIME 5432
#define TASK_AD 5432

#define LOG_FILE "addons/amxmodx/logs/BF1.log"

#define DMG_GRENADE (1<<24)
#define DMG_BULLET (1<<1)

new const gWeaponNames[][] = { "weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", 
"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", 
"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90" }

new const gCmdMainMenu[][] = { "bf1", "say /bf1", "say_team /bf1", "say /bf1menu", "say_team /bf1menu", "say /bf2", "say_team /bf2", "say /bf2menu", "say_team /bf2menu" };
new const gCmdHelp[][] = { "pomoc", "say /pomoc", "say_team /pomoc", "say /help", "say_team /help" };
new const gCmdHelpMenu[][] = { "pomocmenu", "say /pomocmenu", "say_team /pomocmenu", "say /helpmenu", "say_team /helpmenu" };
new const gCmdBadges[][] = { "odznaki", "say /odznaki", "say_team /odznaki", "say /badges", "say_team /badges" };
new const gCmdOrders[][] = { "ordery", "say /ordery", "say_team /ordery", "say /orders", "say_team /orders" };
new const gCmdRanks[][] = { "rangi", "say /rangi", "say_team /rangi", "say /ranks", "say_team /ranks" };
new const gCmdPlayers[][] = { "gracze", "say /gracze", "say_team /gracze", "say /kto", "say_team /kto", "say /players", "say_team /players", "say /who", "say_team /who" };
new const gCmdStats[][] = { "staty", "say /staty", "say_team /staty", "say /stats", "say_team /stats", "say /bf1stats", "say_team /bf1stats" };
new const gCmdStatsMenu[][] = { "statymenu", "say /statymenu", "say_team /statymenu", "say /statsmenu", "say_team /statsmenu" };
new const gCmdStatsServer[][] = { "statyserwer", "say /statyserwer", "say_team /statyserwer", "say /statsserver", "say_team /statsserver", "say /serverstats", "say_team /serverstats" };
new const gCmdHUD[][] = { "hud", "say /hud", "say_team /hud", "say /zmienhud", "say_team /zmienhud", "say /changehud", "say_team /changehud" };
new const gCmdTime[][] = { "czas", "say /czas", "say_team /czas", "say /time", "say_team /time" };
new const gCmdTimeTop[][] = { "topczas", "say /topczas", "say_team /topczas", "say /toptime", "say_team /toptime", "say /ctop15", "say_team /ctop15", "say /ttop15", "say_team /ttop15" };
new const gCmdTimeMenu[][] = { "czasmenu", "say /czasmenu", "say_team /czasmenu", "say /timemenu", "say_team /timemenu" };
new const gCmdDegrees[][] = { "stopnie", "say /stopnie", "say_team /stopnie", "say /degrees", "say_team /degrees", "say /stopien", "say_team /stopien", "say /degree", "say_team /degree" };

enum _:ePlayer
{ 
	KILLS, HS_KILLS, ASSISTS, GOLD, SILVER, BRONZE, HUD, HUD_RED, HUD_GREEN, HUD_BLUE, HUD_POSX, HUD_POSY, DEGREE, ADMIN, TIME, VISITS, FIRST_VISIT, LAST_VISIT, KNIFE, PISTOL, GLOCK, USP, P228, 
	DEAGLE, FIVESEVEN, ELITES, SNIPER, SCOUT, AWP, G3SG1, SG550, RIFLE, AK47, M4A1, GALIL, FAMAS, SG552, AUG, M249, SMG, MAC10, TMP, MP5, UMP45, P90, GRENADE, SHOTGUN, M3, XM1014, PLANTS, EXPLOSIONS, 
	DEFUSES, RESCUES, SURVIVED, DMG_TAKEN, DMG_RECEIVED, EARNED, MONEY, MENU, RANK, NEXT_RANK, BADGES_COUNT, ORDERS_COUNT, NAME[32], SAFE_NAME[32], BADGES[MAX_BADGES], ORDERS[MAX_ORDERS]
};

new gPlayer[MAX_PLAYERS + 1][ePlayer];

enum eSounds { SOUND_RANKUP, SOUND_ORDER, SOUND_BADGE, SOUND_PACKAGE, SOUND_LOAD, SOUND_GRENADE };

new const gSounds[][] =
{
	"bf1/rankup.wav",
	"bf1/orderget.wav",
	"bf1/badgeget.wav",
	"bf1/packageget.wav",
	"bf1/getin.wav",
	"items/9mmclip1.wav"
};

enum eResources { MODEL_PACKAGE, SPRITE_GREEN, SPRITE_ACID }

new const gResources[][] = 
{
	"models/bf1/package_item.mdl",
	"sprites/bf1/green.spr",
	"sprites/bf1/acid_pou.spr"
};

new iResources[sizeof(gResources)];

new gSprites[MAX_RANKS + MAX_BONUSRANKS];

enum eDegrees { DEGREES, DESC, HOURS };

new gDegrees[MAX_DEGREES][eDegrees][] = 
{
	{ "Przybysz", 		"Stopien I, Przybysz.", 									"0" },
	{ "Bywalec", 		"Stopien II, Bywalec, powyzej 8 godzin czasu gry.", 		"8" },
	{ "Staly Gracz", 	"Stopien III, Staly Gracz, powyzej 24 godzin czasu gry.", 	"24" },
	{ "Bohater", 		"Stopien IV, Bohater, powyzej 50 godzin czasu gry.", 		"50" },
	{ "Legenda", 		"Stopien V, Legenda, powyzej 100 godzin czasu gry.", 		"100" }
};

enum eOrdersList
{ 
	ORDER_AIMBOT, ORDER_ANGEL, ORDER_BOMBERMAN, ORDER_SAPER, ORDER_PERSIST, 
	ORDER_DESERV, ORDER_MILION, ORDER_BULLET, ORDER_RAMBO, ORDER_SURVIVER 
};

enum eOrders { DESIGNATION, NEEDS };

new gOrders[MAX_ORDERS][eOrders][] = 
{
	{ "Aimboter", 		"Zabij 2500 razy przez trafienie w glowe" },
	{ "Aniol Stroz", 	"Zalicz 500 asyst" },
	{ "Bomberman", 		"Podloz 100 bomb" },
	{ "Saper", 			"Rozbroj 50 bomb" },
	{ "Wytrwaly", 		"Odwiedz serwer 100 razy" },
	{ "Zasluzony", 		"Zdobadz 100 medali" },
	{ "Milioner", 		"Zarob 1 milion dolarow" },
	{ "Kuloodporny", 	"Otrzymaj 50.000 obrazen" },
	{ "Rambo", 			"Zadaj 50.000 obrazen" },
	{ "Niedobitek", 	"Przetrwaj 1000 rund" }
};

enum _:eServer 
{ 
	HIGHESTSERVERRANK, MOSTSERVERKILLS, MOSTSERVERWINS, HIGHESTSERVERRANKNAME[MAX_LENGHT], MOSTSERVERKILLSNAME[MAX_LENGHT], MOSTSERVERWINSNAME[MAX_LENGHT], MOSTSERVERKILLSID, 
	HIGHESTRANK, HIGHESTRANKID, HIGHESTRANKNAME[MAX_LENGHT], MOSTKILLS, MOSTKILLSID, MOSTKILLSNAME[MAX_LENGHT], MOSTWINS, MOSTWINSID, MOSTWINSNAME[MAX_LENGHT],
}

new gServer[eServer];

new const gRankName[MAX_RANKS + MAX_BONUSRANKS][] = 
{ 
	"Szeregowy",			//0
	"Starszy Szeregowy",	//1
	"Kapral",				//2
	"Starszy Kapral",		//3
	"Plutonowy",			//4
	"Sierzant",				//5
	"Starszy Sierzant",		//6
	"Mlodszy Chorazy",		//7
	"Chorazy",				//8
	"Starszy Chorazy",		//9
	"Chorazy Sztabowy",		//10
	"Podporucznik",			//11
	"Porucznik",			//12
	"Kapitan",				//13
	"Major",				//14
	"Podpulkownik",			//15
	"Pulkownik",			//16
	"General Brygady",		//17
	"General Dywizji",		//18
	"General Korpusu",		//19
	"General Armii",		//20
	"Marszalek Polski",		//21
	"Marszalek Europy",		//22
	"Marszalek Swiata"		//23
};

new const Float:gRankOrder[MAX_RANKS + MAX_BONUSRANKS] =
{
	0.0,
	1.0,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
	7.0,
	8.0,
	9.0,
	10.0,
	11.0,
	12.0,
	13.0,
	14.0,
	15.0,
	16.0,
	7.5,
	8.5,
	15.5,
	20.0,
	21.0,
	22.0,
	23.0
};

new const gRankKills[MAX_RANKS + 1] =
{
	0,		//0
	25,		//1
	50,		//2
	100,	//3
	250,	//4
	500,	//5
	1000,	//6
	2000,	//7
	3000,	//8
	4000,	//9
	5000,	//10
	6500,	//11
	8000,	//12
	9500,	//13
	11000,	//14
	12500,	//15
	15000	//16
};

enum eBadges 
{ 
	BADGE_KNIFE, BADGE_PISTOL, BADGE_ASSAULT, BADGE_SNIPER, BADGE_SUPPORT, 
	BADGE_EXPLOSIVES, BADGE_SHOTGUN, BADGE_SMG, BADGE_TIME, BADGE_GENERAL 
};

enum _:eLevels { LEVEL_NONE, LEVEL_START, LEVEL_EXPERIENCED, LEVEL_VETERAN, LEVEL_MASTER };

new const gBadgeName[MAX_BADGES][][] =
{
	{ "", "Nowicjusz w Walce Nozem", "Doswiadczony w Walce Nozem", "Weteran w Walce Nozem", "Mistrz w Walce Nozem" },
	{ "", "Nowicjusz w Walce Pistoletem", "Doswiadczony w Walce Pistoletem", "Weteran w Walce Pistoletem", "Mistrz w Walce Pistoletem" },
	{ "", "Nowicjusz w Walce Bronia Szturmowa", "Doswiadczony w Walce Bronia Szturmowa", "Weteran w Walce Bronia Szturmowa", "Mistrz w Walce Bronia Szturmowa" },
	{ "", "Nowicjusz w Walce Bronia Snajperska", "Doswiadczony w Walce Bronia Snajperska", "Weteran w Walce Bronia Snajperska", "Mistrz w Walce Bronia Snajperska" },
	{ "", "Nowicjusz w Walce Bronia Wsparcia", "Doswiadczony w Walce Bronia Wsparcia", "Weteran w Walce Bronia Wsparcia", "Mistrz w Walce Bronia Wsparcia" },
	{ "", "Nowicjusz w Walce Granatami", "Doswiadczony w Walce Granatami", "Weteran w Walce Granatami", "Mistrz w Walce Granatami" },
	{ "", "Nowicjusz w Walce Shotgunami", "Doswiadczony w Walce Shotgunami", "Weteran w Walce Shotgunami", "Mistrz w Walce Shotgunami" },
	{ "", "Nowicjusz w Walce SMG", "Doswiadczony w Walce SMG", "Weteran w Walce SMG", "Mistrz w Walce SMG" },
	{ "", "Nowicjusz w Walce Czasowej", "Doswiadczony w Walce Czasowej", "Weteran w Walce Czasowej", "Mistrz w Walce Czasowej" },
	{ "", "Nowicjusz w Walce Ogolnej", "Doswiadczony w Walce Ogolnej", "Weteran w Walce Ogolnej", "Mistrz w Walce Ogolnej" }
};

new const gBadgeInfo[MAX_BADGES][] =
{
	"Masz szanse na dostanie cichego chodzenia podczas odrodzenia",
	"Masz szanse na odbicie pocisku, ktory cie trafil",
	"Masz szanse na krytyczne trafienie (1 hit = dead)",
	"Dostajesz dodatkowe pieniadze podczas odrodzenia",
	"Dostajesz dodatkowe HP podczas odrodzenia",
	"Wszystkie bronie zadaja ci mniejsze obrazenia",
	"Zadajesz zwiekszone obrazenia z kazdej broni",
	"Masz zwiekszona predkosc poruszania sie",
	"Jestes niewidzialny na nozu",
	"Otrzymujesz dodatkowe granaty podczas odrodzenia"
};

new const gInvisibleValue[] =
{
	150,	//Start
	110,	//Experienced
	70,		//Veteran
	30,		//Master
};

enum _:eMenus { MENU_MAIN, MENU_HELP, MENU_STATS, MENU_TIME, MENU_BADGES, MENU_PLAYERBADGES, MENU_PLAYERSTATS };

enum _:eHUD { TYPE_HUD, TYPE_DHUD, TYPE_STATUSTEXT };

enum eSave { NORMAL, DISCONNECT, MAP_END };

new pCvarDBHost, pCvarDBUser, pCvarDBPass, pCvarDBBase, pCvarBF1Active, pCvarBadgePowers, pCvarHelpUrl, 
pCvarXpMinPlayers, pCvarIconTime, pCvarPackage, pCvarDropChance, pCvarHP, pCvarSpeed, pCvarMoney, pCvarArmor;

new iLoaded, iNewPlayer, iVisit, iInvisible, iRound = 0;

new bool:bPackages, bool:bFreezeTime, bool:bSQL, bool:bServer;

new sConfigsDir[128], Handle:hSqlHook, Float:fGameTime, gmsgStatusText, gHUD, gHUDAim;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("bf1_version", VERSION, FCVAR_SERVER);
	
	pCvarDBHost = register_cvar("bf1_db_host", "127.0.0.1", FCVAR_SPONLY|FCVAR_PROTECTED);
	pCvarDBUser = register_cvar("bf1_db_user", "user", FCVAR_SPONLY|FCVAR_PROTECTED);
	pCvarDBPass = register_cvar("bf1_db_pass", "pass", FCVAR_SPONLY|FCVAR_PROTECTED);
	pCvarDBBase = register_cvar("bf1_db_database", "db", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	pCvarBF1Active = register_cvar("bf1_active", "1");
	pCvarBadgePowers = register_cvar("bf1_badgepowers", "1");
	pCvarHelpUrl = register_cvar("bf1_help_url", "http://cs-reload.pl/bf1webdocs");
	pCvarXpMinPlayers = register_cvar("bf1_xpminplayers", "3");
	pCvarIconTime = register_cvar("bf1_icon_time", "1.5");
	pCvarPackage = register_cvar("bf1_package_enabled", "1");
	pCvarDropChance = register_cvar("bf1_package_drop_chance", "8");
	pCvarHP = register_cvar("bf1_badge_hp", "5");
	pCvarSpeed = register_cvar("bf1_badge_speed", "10.0");
	pCvarMoney = register_cvar("bf1_badge_money", "250");
	pCvarArmor = register_cvar("bf1_bonus_armor", "25");
	
	for(new i; i < sizeof gCmdMainMenu; i++) register_clcmd(gCmdMainMenu[i], "menu_bf1");
	for(new i; i < sizeof gCmdHelp; i++) register_clcmd(gCmdHelp[i], "cmd_help");
	for(new i; i < sizeof gCmdHelpMenu; i++) register_clcmd(gCmdHelpMenu[i], "menu_help");
	for(new i; i < sizeof gCmdBadges; i++) register_clcmd(gCmdBadges[i], "menu_badges");
	for(new i; i < sizeof gCmdOrders; i++) register_clcmd(gCmdOrders[i], "cmd_orders");
	for(new i; i < sizeof gCmdRanks; i++) register_clcmd(gCmdRanks[i], "cmd_rankhelp");
	for(new i; i < sizeof gCmdPlayers; i++) register_clcmd(gCmdPlayers[i], "cmd_ranks");
	for(new i; i < sizeof gCmdStats; i++) register_clcmd(gCmdStats[i], "cmd_mystats");
	for(new i; i < sizeof gCmdStatsMenu; i++) register_clcmd(gCmdStatsMenu[i], "menu_stats");
	for(new i; i < sizeof gCmdStatsServer; i++) register_clcmd(gCmdStatsServer[i], "cmd_serverstats");
	for(new i; i < sizeof gCmdHUD; i++) register_clcmd(gCmdHUD[i], "hud_menu");
	for(new i; i < sizeof gCmdTime; i++) register_clcmd(gCmdTime[i], "cmd_time");
	for(new i; i < sizeof gCmdTimeMenu; i++) register_clcmd(gCmdTimeMenu[i], "menu_time");
	for(new i; i < sizeof gCmdTimeTop; i++) register_clcmd(gCmdTimeTop[i], "cmd_timetop");
	for(new i; i < sizeof gCmdDegrees; i++) register_clcmd(gCmdDegrees[i], "cmd_degrees");
	
	register_clcmd("say", "cmd_say");
	register_clcmd("say_team", "cmd_say");
	
	register_concmd("bf1_addbadge", "cmd_addbadge", ADMIN_ALL, "<player> <badge> <level>"); 
	register_concmd("bf1_addbadgesql", "cmd_addbadge_sql", ADMIN_ALL, "<player> <badge> <level>");
	
	register_clcmd("flash", "flashbang_buy");
	register_clcmd("hegren", "hegrenade_buy");
	register_clcmd("sgren", "smokegrenade_buy");
	
	register_menucmd(-34, (1<<2), "flashbang_buy");
	register_menucmd(-34, (1<<3), "hegrenade_buy");
	register_menucmd(-34, (1<<4), "smokegrenade_buy");
	
	register_menucmd(register_menuid("BuyItem"), (1<<2), "flashbang_buy");
	register_menucmd(register_menuid("BuyItem"), (1<<3), "hegrenade_buy");
	register_menucmd(register_menuid("BuyItem"), (1<<4), "smokegrenade_buy");
	
	register_event("DeathMsg", "event_deathmsg", "a");
	register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("TextMsg", "event_hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("StatusValue", "event_on_showstatus", "be", "1=2", "2!0");
	register_event("StatusValue", "event_on_hidestatus", "be", "1=1", "2=0");
	register_event("Money", "event_money", "be");
	register_logevent("event_round_start", 2, "0=World triggered", "1=Round_Start");
	register_logevent("event_round_end", 2, "1=Round_End");
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "player_takedamage", 0);
	RegisterHam(Ham_Touch, "armoury_entity", "touch_grenades", 0);
	RegisterHam(get_player_resetmaxspeed_func(), "player", "set_speed", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "weapon_knife", 1);
	for (new i = 0; i < sizeof gWeaponNames; i++) RegisterHam(Ham_Item_Deploy, gWeaponNames[i], "weapon_other", 1);
	
	register_forward(FM_PlayerPreThink, "player_prethink");
	register_forward(FM_Touch, "touch_package");
	
	register_message(SVC_INTERMISSION, "award_check");
	register_message(get_user_msgid("SayText"), "chat_prefix");
	register_message(get_user_msgid("TextMsg") , "block_message");
	
	gHUD = CreateHudSyncObj();
	gHUDAim = CreateHudSyncObj();

	gmsgStatusText = get_user_msgid("StatusText");
	
	set_task(120.0, "display_help", TASK_HELP, .flags = "b");
}

public plugin_precache()
{
	new bool:bError;
	
	for (new i = 0; i < sizeof(gResources); i++)
	{
		if (!file_exists(gResources[i]))
		{
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", gResources[i]);
			bError = true;
		}
		else iResources[i] = precache_model(gResources[i]);
	}

	new sSoundFile[32];
	
	for (new i = 0; i < sizeof(gSounds); i++)
	{
		formatex(sSoundFile, charsmax(sSoundFile), "sound/%s", gSounds[i]);
		
		if (!file_exists(sSoundFile))
		{
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", sSoundFile);
			bError = true;
		}
		else precache_sound(gSounds[i]);
	}
	
	new sSpriteFile[32];
	
	for (new i = 0; i < MAX_RANKS + MAX_BONUSRANKS; i++)
	{
		formatex(sSpriteFile, charsmax(sSpriteFile), "sprites/bf1/%d.spr", i);
		
		if (!file_exists(sSpriteFile))
		{
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", sSpriteFile);
			bError = true;
		}
		else gSprites[i] = precache_model(sSpriteFile);
	}
	
	if (bError) set_fail_state("[BF1] Zaladowanie pluginu niemozliwe - brak wymaganych plikow! Sprawdz logi w BF1.log!");
}

public plugin_cfg()
{
	get_configsdir(sConfigsDir, charsmax(sConfigsDir));
	
	server_cmd("exec %s/bf1.cfg", sConfigsDir);
	
	format(sConfigsDir, charsmax(sConfigsDir), "%s/bf1webdocs", sConfigsDir);
	
	set_task(0.1, "sql_init");
	
	check_map();
}

public plugin_end()
{
	save_server();
	
	SQL_FreeHandle(hSqlHook);
}

public client_connect(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return PLUGIN_CONTINUE;
	
	for(new i = 0; i <= ORDERS_COUNT; i++) gPlayer[id][i] = 0;

	for(new i = 0; i < MAX_BADGES; i++) gPlayer[id][BADGES][i] = 0;
	
	for(new i = 0; i < MAX_ORDERS; i++) gPlayer[id][ORDERS][i] = 0;
	
	gPlayer[id][HUD] = TYPE_HUD;
	gPlayer[id][HUD_RED] = 255;
	gPlayer[id][HUD_GREEN] = 128;
	gPlayer[id][HUD_BLUE] = 0;
	gPlayer[id][HUD_POSX] = 66;
	gPlayer[id][HUD_POSY] = 6;

	Set(id, iNewPlayer);
	Set(id, iVisit);
	
	Rem(id, iLoaded);
	Rem(id, iInvisible);
	
	remove_task(id + TASK_HUD);
	remove_task(id + TASK_AD);
	
	get_user_name(id, gPlayer[id][NAME], charsmax(gPlayer[]));
	
	mysql_escape_string(gPlayer[id][NAME], gPlayer[id][SAFE_NAME], charsmax(gPlayer[]));
	
	load_stats(id);
	
	cmd_execute(id, "hud_centerid 0");
	cmd_execute(id, "cl_shadows 0");
	
	set_task(0.1, "display_hud", id + TASK_HUD, _, _, "b");
	set_task(30.0, "display_advertisement", id + TASK_AD);
	
	return PLUGIN_CONTINUE;
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	save_stats(id, DISCONNECT);
	
	if (gPlayer[id][KILLS] == gServer[MOSTSERVERKILLS]) gServer[MOSTSERVERKILLSID] = 0;
	
	if (id == gServer[MOSTKILLSID]) most_kills_disconnect();
	
	if (id == gServer[MOSTWINSID]) most_wins_disconnect();
	
	if (id == gServer[HIGHESTRANKID]) highest_rank_disconnect();
}

public plugin_natives()
{
	register_library("bf1");
	
	register_native("bf1_get_maxbadges","_bf1_get_maxbadges");
	register_native("bf1_get_badge_name","_bf1_get_badge_name", 1);
	register_native("bf1_get_user_badge", "_bf1_get_user_badge");
	register_native("bf1_set_user_badge", "_bf1_set_user_badge");
	register_native("bf1_add_assist_kill", "_bf1_add_assist_kill");
}

public _bf1_get_maxbadges(plugin, params)
	return MAX_BADGES;

public _bf1_get_user_badge(plugin, params)
{
	if (!is_user_connected(get_param(1))) return -1;

	return gPlayer[get_param(1)][BADGES][get_param(2)];
}

public _bf1_get_badge_name(iBadge, iLevel, sReturn[], iLen) 
{
	param_convert(3);
	
	copy(sReturn, iLen, gBadgeName[iBadge][iLevel]);
	
	return;
}

public _bf1_set_user_badge(plugin, params)
{
	if (!is_user_connected(get_param(1))) return -1;
		
	return gPlayer[get_param(1)][BADGES][get_param(2)] = get_param(3);
}

public _bf1_add_assist_kill(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) return;

	switch(get_user_weapon(id))
	{
		case CSW_KNIFE: gPlayer[id][KNIFE]++;
		case CSW_M249: gPlayer[id][M249]++;
		case CSW_AWP: { gPlayer[id][SNIPER]++; gPlayer[id][AWP]++; }
		case CSW_SCOUT: { gPlayer[id][SNIPER]++; gPlayer[id][SCOUT]++; }
		case CSW_G3SG1: { gPlayer[id][SNIPER]++; gPlayer[id][G3SG1]++; }
		case CSW_SG550: { gPlayer[id][SNIPER]++; gPlayer[id][SG550]++; }
		case CSW_DEAGLE: { gPlayer[id][PISTOL]++; gPlayer[id][DEAGLE]++; }
		case CSW_ELITE: { gPlayer[id][PISTOL]++; gPlayer[id][ELITES]++; }
		case CSW_USP: { gPlayer[id][PISTOL]++; gPlayer[id][USP]++; }
		case CSW_FIVESEVEN: { gPlayer[id][PISTOL]++; gPlayer[id][FIVESEVEN]++; }
		case CSW_P228: { gPlayer[id][PISTOL]++; gPlayer[id][P228]++; }
		case CSW_GLOCK18: { gPlayer[id][PISTOL]++; gPlayer[id][GLOCK]++; }
		case CSW_XM1014: { gPlayer[id][XM1014]++; gPlayer[id][SHOTGUN]++; }
		case CSW_M3: { gPlayer[id][M3]++; gPlayer[id][SHOTGUN]++; }
		case CSW_MAC10: { gPlayer[id][MAC10]++; gPlayer[id][SMG]++; }
		case CSW_UMP45: { gPlayer[id][UMP45]++; gPlayer[id][SMG]++; }
		case CSW_MP5NAVY: { gPlayer[id][MP5]++; gPlayer[id][SMG]++; }
		case CSW_TMP: { gPlayer[id][TMP]++; gPlayer[id][SMG]++; }
		case CSW_P90: { gPlayer[id][P90]++; gPlayer[id][SMG]++; }
		case CSW_AUG: { gPlayer[id][AUG]++; gPlayer[id][RIFLE]++; }
		case CSW_GALIL: { gPlayer[id][GALIL]++; gPlayer[id][RIFLE]++; }
		case CSW_FAMAS: { gPlayer[id][FAMAS]++; gPlayer[id][RIFLE]++; }
		case CSW_M4A1: { gPlayer[id][M4A1]++; gPlayer[id][RIFLE]++; }
		case CSW_AK47: { gPlayer[id][AK47]++; gPlayer[id][RIFLE]++; }
		case CSW_SG552: { gPlayer[id][SG552]++; gPlayer[id][RIFLE]++; }
		case CSW_HEGRENADE: gPlayer[id][GRENADE]++;
	}
	
	gPlayer[id][ASSISTS]++;
	gPlayer[id][KILLS]++;
	
	return;
}

public client_death(killer, victim, iWeapon, iHitPlace, iTeamKill)
{
	if (!get_pcvar_num(pCvarBF1Active) || !is_user_connected(killer)) return;
	
	if (killer == victim)
	{
		check_badges(victim);
		
		return;
	}
	
	switch(iWeapon)
	{
		case CSW_KNIFE: gPlayer[killer][KNIFE]++;
		case CSW_M249: gPlayer[killer][M249]++;
		case CSW_AWP: { gPlayer[killer][SNIPER]++; gPlayer[killer][AWP]++; }
		case CSW_SCOUT: { gPlayer[killer][SNIPER]++; gPlayer[killer][SCOUT]++; }
		case CSW_G3SG1: { gPlayer[killer][SNIPER]++; gPlayer[killer][G3SG1]++; }
		case CSW_SG550: { gPlayer[killer][SNIPER]++; gPlayer[killer][SG550]++; }
		case CSW_DEAGLE: { gPlayer[killer][PISTOL]++; gPlayer[killer][DEAGLE]++; }
		case CSW_ELITE: { gPlayer[killer][PISTOL]++; gPlayer[killer][ELITES]++; }
		case CSW_USP: { gPlayer[killer][PISTOL]++; gPlayer[killer][USP]++; }
		case CSW_FIVESEVEN: { gPlayer[killer][PISTOL]++; gPlayer[killer][FIVESEVEN]++; }
		case CSW_P228: { gPlayer[killer][PISTOL]++; gPlayer[killer][P228]++; }
		case CSW_GLOCK18: { gPlayer[killer][PISTOL]++; gPlayer[killer][GLOCK]++; }
		case CSW_XM1014: { gPlayer[killer][XM1014]++; gPlayer[killer][SHOTGUN]++; }
		case CSW_M3: { gPlayer[killer][M3]++; gPlayer[killer][SHOTGUN]++; }
		case CSW_MAC10: { gPlayer[killer][MAC10]++; gPlayer[killer][SMG]++; }
		case CSW_UMP45: { gPlayer[killer][UMP45]++; gPlayer[killer][SMG]++; }
		case CSW_MP5NAVY: { gPlayer[killer][MP5]++; gPlayer[killer][SMG]++; }
		case CSW_TMP: { gPlayer[killer][TMP]++; gPlayer[killer][SMG]++; }
		case CSW_P90: { gPlayer[killer][P90]++; gPlayer[killer][SMG]++; }
		case CSW_AUG: { gPlayer[killer][AUG]++; gPlayer[killer][RIFLE]++; }
		case CSW_GALIL: { gPlayer[killer][GALIL]++; gPlayer[killer][RIFLE]++; }
		case CSW_FAMAS: { gPlayer[killer][FAMAS]++; gPlayer[killer][RIFLE]++; }
		case CSW_M4A1: { gPlayer[killer][M4A1]++; gPlayer[killer][RIFLE]++; }
		case CSW_AK47: { gPlayer[killer][AK47]++; gPlayer[killer][RIFLE]++; }
		case CSW_SG552: { gPlayer[killer][SG552]++; gPlayer[killer][RIFLE]++; }
		case CSW_HEGRENADE: gPlayer[killer][GRENADE]++;
	}
	
	if (iHitPlace == HIT_HEAD) gPlayer[killer][HS_KILLS]++;
	
	gPlayer[killer][KILLS]++;
	
	check_badges(victim);
	
	if (gServer[MOSTKILLSID] == killer) gServer[MOSTKILLS]++;
	else if (gPlayer[killer][KILLS] > gServer[MOSTKILLS])
	{
		gServer[MOSTKILLS] = gPlayer[killer][KILLS];
		gServer[MOSTKILLSID] = killer;
		
		get_user_name(killer, gServer[MOSTKILLSNAME], charsmax(gServer[MOSTKILLSNAME]));
		
		#if AMXX_VERSION_NUM < 183
		ColorChat(killer, GREEN, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTKILLSNAME], gServer[MOSTKILLS]);
		#else
		client_print_color(killer, killer, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTKILLSNAME], gServer[MOSTKILLS]);
		#endif
	}
	
	if (gServer[MOSTSERVERKILLSID] == killer) gServer[MOSTSERVERKILLS]++;
	else if (gPlayer[killer][KILLS] > gServer[MOSTSERVERKILLS])
	{
		gServer[MOSTSERVERKILLS] = gPlayer[killer][KILLS];
		
		client_cmd(killer, "spk %s", gSounds[SOUND_RANKUP]);
		
		get_user_name(killer, gServer[MOSTSERVERKILLSNAME], charsmax(gServer[MOSTSERVERKILLSNAME]));

		#if AMXX_VERSION_NUM < 183
		ColorChat(killer, GREEN, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTSERVERKILLSNAME], gServer[MOSTSERVERKILLS]);
		#else
		client_print_color(killer, killer, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTSERVERKILLSNAME], gServer[MOSTSERVERKILLS]);
		#endif
	}
}

public bomb_planted(planter)
{
	if (get_playersnum() < get_pcvar_num(pCvarXpMinPlayers)) return;
	
	gPlayer[planter][PLANTS]++;
}

public bomb_explode(planter, defuser)
{
	if (get_playersnum() < get_pcvar_num(pCvarXpMinPlayers)) return;

	gPlayer[planter][EXPLOSIONS]++;
	gPlayer[planter][KILLS] += 3;

	#if AMXX_VERSION_NUM < 183
	ColorChat(planter, GREEN, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za wybuch bomby.");
	#else
	client_print_color(planter, planter, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za wybuch bomby.");
	#endif
}

public bomb_defused(defuser)
{
	if (get_playersnum() < get_pcvar_num(pCvarXpMinPlayers)) return;

	gPlayer[defuser][DEFUSES]++;
	gPlayer[defuser][KILLS] += 3;

	#if AMXX_VERSION_NUM < 183
	ColorChat(defuser, GREEN, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za rozbrojenie bomby.");
	#else
	client_print_color(defuser, defuser, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za rozbrojenie bomby.");
	#endif
}

public event_hostages_rescued()
{
	if (get_playersnum() < get_pcvar_num(pCvarXpMinPlayers)) return;
	
	new sLogUser[80], sName[32];
	
	read_logargv(0, sLogUser, charsmax(sLogUser));
	parse_loguser(sLogUser, sName, charsmax(sName));

	new rescuer = get_user_index(sName);
	
	gPlayer[rescuer][RESCUES]++;
	gPlayer[rescuer][KILLS] += 3;

	#if AMXX_VERSION_NUM < 183
	ColorChat(rescuer, GREEN, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za uratowanie zakladnikow.");
	#else
	client_print_color(rescuer, rescuer, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za uratowanie zakladnikow.");
	#endif
}

public event_deathmsg()
{
	new killer = read_data(1), victim = read_data(2);
	
	if (!is_user_alive(killer) || !is_user_connected(victim)) return;

	check_badges(victim);
	
	if (killer == victim || !get_pcvar_num(pCvarPackage) || bPackages) return;
	
	if (random_num(1, get_pcvar_num(pCvarDropChance)) == 1)
	{
		new sName[32];
		
		get_user_name(victim, sName, charsmax(sName));
		
		place_package(victim, killer);

		#if AMXX_VERSION_NUM < 183
		ColorChat(killer, GREEN, "^x04[BF1]^x01 Zabiles^x03 %s^x01 i wypadla z niego^x03 paczka^x01. Zabierz ja szybko, bo mozesz znalezc w niej kase, fragi, a nawet odznake!", sName);
		#else
		client_print_color(killer, killer, "^x04[BF1]^x01 Zabiles^x03 %s^x01 i wypadla z niego^x03 paczka^x01. Zabierz ja szybko, bo mozesz znalezc w niej kase, fragi, a nawet odznake!", sName);
		#endif
	}
}

public event_on_hidestatus(id)
	ClearSyncHud(id, gHUDAim);

public event_on_showstatus(id)
{
	new sPlayerName[33], player = read_data(2), iPlayerRank = gPlayer[player][RANK], iColor1 = 0, iColor2 = 0;

	get_user_name(player, sPlayerName, charsmax(sPlayerName));

	if (get_user_team(player) == 1) iColor1 = 255;
	else iColor2 = 255;

	if (get_user_team(player) == get_user_team(id))
	{
		new sWeapon[32], iWeapon = get_user_weapon(player);

		if (iWeapon) xmod_get_wpnname(iWeapon, sWeapon, charsmax(sWeapon));

		set_hudmessage(iColor1, 50, iColor2, -1.0, 0.35, 1, 0.01, 3.0, 0.01, 0.01);

		ShowSyncHudMsg(id, gHUDAim, "%s : %s^n%d HP / %d AP / %s", sPlayerName, gRankName[iPlayerRank], get_user_health(player), get_user_armor(player), sWeapon);

		new iIconTime = floatround(get_pcvar_float(pCvarIconTime) * 10);
		if (iIconTime > 0) Create_TE_PLAYERATTACHMENT(id, player, 55, gSprites[iPlayerRank], iIconTime);
	}
	else if(!Get(player, iInvisible))
	{
		set_hudmessage(iColor1, 50, iColor2, -1.0, 0.35, 1, 0.01, 3.0, 0.01, 0.01);

		ShowSyncHudMsg(id, gHUDAim, "%s : %s", sPlayerName, gRankName[iPlayerRank]);
	}
}

public event_round_end()
{
	new sPlayers[32], iNum;
	get_players(sPlayers, iNum, "ah");

	for (new i = 0; i < iNum; i++)
	{
		check_badges(sPlayers[i]);
		
		gPlayer[sPlayers[i]][SURVIVED]++;
	}
}

public event_round_start()
	bFreezeTime = false;	

public event_new_round()
{
	fGameTime = get_gametime();
	
	bFreezeTime = true;
	
	iRound++;
	
	new iEnt = -1;
	
	while((iEnt = find_ent_by_class(iEnt, "package")) != 0) engfunc(EngFunc_RemoveEntity, iEnt);

	iEnt = -1;

	while((iEnt = find_ent_by_class(iEnt, "armoury_entity")) != 0) 
	{
		set_entity_visibility(iEnt, 1);
		
		entity_set_int(iEnt, EV_INT_iuser1, 0);
	}
}

public event_game_commencing()
	iRound = 0;
	
public event_money(id)
{
	new iMoney = read_data(1);
	
	if(iMoney > gPlayer[id][MONEY]) gPlayer[id][EARNED] += (iMoney - gPlayer[id][MONEY]);
	
	gPlayer[id][MONEY] = iMoney;
}

public weapon_knife(weapon)
{
	static id;
	
	id = pev(weapon, pev_owner);

	set_render(id);
}

public set_render(id)
{
	if (!get_pcvar_num(pCvarBadgePowers) || !is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE) return;
	
	new iTimeBadgeLevel = gPlayer[id][BADGES][BADGE_TIME];
	
	if (iTimeBadgeLevel) 
	{
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, gInvisibleValue[iTimeBadgeLevel - 1]);
		
		Set(id, iInvisible);
	}
}

public weapon_other(weapon)
{
	static id;
	
	id = pev(weapon, pev_owner);

	reset_render(id);
}

public reset_render(id)
{
	if (!get_pcvar_num(pCvarBadgePowers) || !is_user_alive(id)) return;
	
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 255);
	
	Rem(id, iInvisible);
}

public give_weapons(id)
{
	if (!get_pcvar_num(pCvarBadgePowers) || !is_user_alive(id)) return;
	
	new bool:iItem;
	
	new iSniperBadgeLevel = gPlayer[id][BADGES][BADGE_SNIPER];
	
	if (iSniperBadgeLevel && iRound >= 2)
	{
		if(random_num(1, 5 - iSniperBadgeLevel) == 1)
		{
			if (check_weapons(id))
			{
				#if AMXX_VERSION_NUM < 183
				ColorChat(id, GREEN, "^x04[BF1]^x01 Nie otrzymales Scouta z racji posiadania odznaki za Walke Bronia Snajperska, bo masz juz bron!");
				#else
				client_print_color(id, id, "^x04[BF1]^x01 Nie otrzymales Scouta z racji posiadania odznaki za Walke Bronia Snajperska, bo masz juz bron!");
				#endif
			}
			else 
			{
				fm_give_item(id, "weapon_scout");
			
				cs_set_user_bpammo(id, CSW_SCOUT, 90);
				
				iItem = true;
			}
		}
		
		cs_set_user_money(id, min(cs_get_user_money(id) + get_pcvar_num(pCvarMoney) * iSniperBadgeLevel, 16000), 1);
		
		iItem = true;
	}
	
	new iKnifeBadgeLevel = gPlayer[id][BADGES][BADGE_KNIFE];
	
	if (iKnifeBadgeLevel && random_num(1, 5 - iKnifeBadgeLevel) == 1) 
	{
		set_user_footsteps(id, 1);
		
		iItem = true;
	}
	else set_user_footsteps(id, 0);
	
	new iSupportBadgeLevel = gPlayer[id][BADGES][BADGE_SUPPORT];
	
	if (iSupportBadgeLevel)
	{
		new iHP = 100 + (iSupportBadgeLevel * get_pcvar_num(pCvarHP));
		
		set_user_health(id, iHP);
		set_pev(id, pev_max_health, float(iHP));

		iItem = true;
	}
	
	new iGeneralBadgeLevel = gPlayer[id][BADGES][BADGE_GENERAL];
	
	if(iGeneralBadgeLevel)
	{
		handle_buy(id, CSW_FLASHBANG, 1); 
		
		if(iGeneralBadgeLevel > LEVEL_START) handle_buy(id, CSW_HEGRENADE, 1);
		
		if(iGeneralBadgeLevel > LEVEL_EXPERIENCED) handle_buy(id, CSW_FLASHBANG, 1);
		
		if(iGeneralBadgeLevel > LEVEL_VETERAN) handle_buy(id, CSW_SMOKEGRENADE, 1);
	}
	
	new CsArmorType:ArmorType, iArmor, iUserArmor = cs_get_user_armor(id, ArmorType);
	
	switch (gPlayer[id][BADGES_COUNT])
	{
		case 10 .. 19: iArmor = get_pcvar_num(pCvarArmor);
		case 20 .. 29: iArmor = get_pcvar_num(pCvarArmor) * 2;
		case 30 .. 39: iArmor = get_pcvar_num(pCvarArmor) * 3;
		case 40: iArmor = get_pcvar_num(pCvarArmor) * 4;
	}
	
	if (iUserArmor < iArmor)
	{
		cs_set_user_armor(id, iArmor, CS_ARMOR_VESTHELM);

		iItem = true;
	}
	
	if (iItem) screen_flash(id, 0, 255, 0, 100);
}

public player_spawn(id)
{
	if (!get_pcvar_num(pCvarBF1Active) || !is_user_alive(id)) return HAM_IGNORED;

	check_rank(id);

	if (!get_pcvar_num(pCvarBadgePowers)) return HAM_IGNORED;
	
	set_render(id);

	set_task(0.1, "give_weapons", id);
	
	if(Get(id, iVisit)) set_task(3.0, "check_time", id + TASK_TIME);
	
	if (Get(id, iNewPlayer) && Get(id, iLoaded))
	{
		Rem(id, iNewPlayer);
		
		client_cmd(id, "spk %s", gSounds[SOUND_LOAD]);

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Twoja ranga^x03 %s^x01 zostala zaladowana.", gRankName[gPlayer[id][RANK]]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Twoja ranga^x03 %s^x01 zostala zaladowana.", gRankName[gPlayer[id][RANK]]);
		#endif
	}

	return HAM_IGNORED;
}

public player_takedamage(victim, iInflictor, attacker, Float:fDamage, iDamageBits)
{
	if (!get_pcvar_num(pCvarBadgePowers) || !is_user_connected(attacker) || !is_user_alive(victim)) return HAM_IGNORED;
	if (victim == attacker || cs_get_user_team(victim) == cs_get_user_team(attacker)) return HAM_IGNORED;
	
	if (iDamageBits & DMG_BULLET)
	{
		new bool:bCritical;
		
		switch(gPlayer[attacker][BADGES][BADGE_ASSAULT])
		{
			case LEVEL_START: if(random_num(1, 100) == 1) bCritical = true;
			case LEVEL_EXPERIENCED: if(random_num(1, 65) == 1) bCritical = true;
			case LEVEL_VETERAN: if(random_num(1, 50) == 1) bCritical = true;
			case LEVEL_MASTER: if(random_num(1, 40) == 1) bCritical = true;
		}
		
		if(bCritical)
		{
			cs_set_user_armor(victim, 0, CS_ARMOR_NONE);
		
			SetHamParamFloat(4, float(get_user_health(victim) + 1));
		
			return HAM_HANDLED;
		}
	}

	new iShotgunBadgeLevel = gPlayer[attacker][BADGES][BADGE_SHOTGUN],
		iExplosivesBadgeLevel = gPlayer[victim][BADGES][BADGE_EXPLOSIVES],
		iPistolBadgeLevel = gPlayer[victim][BADGES][BADGE_PISTOL];
		
	if (iShotgunBadgeLevel) fDamage += fDamage * iShotgunBadgeLevel * 0.04;
	
	if (iExplosivesBadgeLevel) fDamage -= fDamage * iExplosivesBadgeLevel * 0.04;
	
	if(iPistolBadgeLevel && random_num(1, 16 - iPistolBadgeLevel * 2) == 1 && iDamageBits & DMG_BULLET)
	{
		ExecuteHam(Ham_TakeDamage, attacker, victim, victim, fDamage, iDamageBits);
		
		player_glow(victim, 255, 0, 0);

		return HAM_SUPERCEDE;
	}

	SetHamParamFloat(4, fDamage);
	
	gPlayer[victim][DMG_RECEIVED] += floatround(fDamage);
	gPlayer[attacker][DMG_TAKEN] += floatround(fDamage);

	return HAM_HANDLED;
}

public set_speed(id)
{
	if(bFreezeTime || !is_user_alive(id)) return HAM_IGNORED;
	
	set_user_maxspeed(id, get_user_maxspeed(id) + gPlayer[id][BADGES][BADGE_SMG] * get_pcvar_float(pCvarSpeed));

	return HAM_IGNORED;
}

public player_prethink(id) 
{
	if (is_user_alive(id)) 
	{
		new Float:fVector[3];
		
		pev(id, pev_velocity, fVector);
		
		new Float:fSpeed = floatsqroot(fVector[0] * fVector[0] + fVector[1] * fVector[1] + fVector[2] * fVector[2]);
		
		if ((fm_get_user_maxspeed(id) * 5) > (fSpeed * 9)) set_pev(id, pev_flTimeStepSound, 300);
	}
}

public use_package(id)
{
	if (!is_user_connected(id) || !is_user_alive(id) || !get_pcvar_num(pCvarPackage) || bPackages) return PLUGIN_HANDLED;
		
	switch(random_num(1, 15))
	{
		case 1 .. 3:
		{
			new iRandomHP = random_num(5, 25), iMaxHP = 100 + (gPlayer[id][BADGES][BADGE_ASSAULT] * get_pcvar_num(pCvarHP));

			fm_set_user_health(id, min(get_user_health(id) + iRandomHP, iMaxHP));

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Znalazles mala apteczke. Dostajesz^x03 %i^x01 HP!", iRandomHP);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Znalazles mala apteczke. Dostajesz^x03 %i^x01 HP!", iRandomHP);
			#endif
		}
		case 4 .. 6:
		{
			new iRandomHP = random_num(25, 50), iMaxHP = 100 + (gPlayer[id][BADGES][BADGE_ASSAULT] * get_pcvar_num(pCvarHP));

			fm_set_user_health(id, min(get_user_health(id) + iRandomHP, iMaxHP));

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Znalazles duza apteczke. Dostajesz^x03 %i^x01 HP!", iRandomHP);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Znalazles duza apteczke. Dostajesz^x03 %i^x01 HP!", iRandomHP);
			#endif
		}
		case 7 .. 9:
		{
			new iRandomMoney = random_num(500, 2500);
			
			cs_set_user_money(id, min(cs_get_user_money(id) + iRandomMoney, 16000), 1);

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Znalazles troche gotowki. Dostajesz^x03 %i$^x01!", iRandomMoney);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Znalazles troche gotowki. Dostajesz^x03 %i$^x01!", iRandomMoney);
			#endif
		}
		case 10 .. 12:
		{
			new iRandomMoney = random_num(2500, 6000);
			
			cs_set_user_money(id, min(cs_get_user_money(id) + iRandomMoney, 16000), 1);

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Znalazles sporo gotowki. Dostajesz^x03 %i$^x01!", iRandomMoney);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Znalazles sporo gotowki. Dostajesz^x03 %i$^x01!", iRandomMoney);
			#endif
		}
		case 13, 14:
		{
			set_user_frags(id, get_user_frags(id) + 1);
			
			gPlayer[id][KILLS]++;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Niezle! Dostajesz dodatkowego^x03 fraga^x01.");
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Niezle! Dostajesz dodatkowego^x03 fraga^x01.");
			#endif
		}
		case 15:
		{
			new Array:aBadges = ArrayCreate(1, 10), iBadges;

			for(new i = 0; i < 10; i++)
			{
				if (gPlayer[id][BADGES][i] >= LEVEL_START) iBadges++;
				
				ArrayPushCell(aBadges, i);
			}
			
			if (iBadges < MAX_BADGES)
			{
				for(new j = 0; j < 10; j++)
				{
					new iRandomBadge = random_num(0, 9 - j), iBadge = ArrayGetCell(aBadges, iRandomBadge);

					if (gPlayer[id][BADGES][iBadge] < LEVEL_START)
					{
						gPlayer[id][BADGES][iBadge] = LEVEL_START;

						#if AMXX_VERSION_NUM < 183
						ColorChat(id, GREEN, "^x04[BF1]^x01 Wow! Znalazles losowa^x03 odznake^x01 na poziomie^x03 Nowicjusz^x01.");
						#else
						client_print_color(id, id, "^x04[BF1]^x01 Wow! Znalazles losowa^x03 odznake^x01 na poziomie^x03 Nowicjusz^x01.");
						#endif

						break;
					}
				
					ArrayDeleteItem(aBadges, iRandomBadge);
				}
			}
			else
			{
				set_user_frags(id, get_user_frags(id) + 2);
			
				gPlayer[id][KILLS] += 2;

				#if AMXX_VERSION_NUM < 183
				ColorChat(id, GREEN, "^x04[BF1]^x01 Masz wszystkie odznaki z poziomu Nowicjusz, wiec dostajesz^x03 dwa fragi^x01.");
				#else
				client_print_color(id, id, "^x04[BF1]^x01 Masz wszystkie odznaki z poziomu Nowicjusz, wiec dostajesz^x03 dwa fragi^x01.");
				#endif
			}
			
			ArrayDestroy(Array:aBadges);
		}
	}
	
	return PLUGIN_HANDLED;
}

public place_package(id, owner)
{
	new Float:fOrigin[3];
	
	pev(id, pev_origin, fOrigin);

	fOrigin[2] -= 30.0;
	
	new entity = fm_create_entity("info_target");
	
	set_pev(entity, pev_classname, "package");
	set_pev(entity, pev_origin, fOrigin);

	engfunc(EngFunc_SetModel, entity, gResources[MODEL_PACKAGE]);

	set_pev(entity, pev_mins, Float:{ -10.0, -10.0, 0.0 });
	set_pev(entity, pev_maxs, Float:{ 10.0, 10.0, 50.0 });
	set_pev(entity, pev_size, Float:{ -1.0, -3.0, 0.0, 1.0, 1.0, 10.0 });
	engfunc(EngFunc_SetSize, entity, Float:{ -1.0,-3.0,0.0 }, Float:{ 1.0,1.0,10.0 });
	
	set_pev(entity, pev_solid, SOLID_TRIGGER);
	set_pev(entity, pev_movetype, MOVETYPE_FLY);
	
	entity_set_int(entity, EV_INT_sequence, 1);
	entity_set_float(entity, EV_FL_animtime, 360.0);
	entity_set_float(entity, EV_FL_framerate,  1.0);
	entity_set_float(entity, EV_FL_frame, 0.0);
}

public touch_package(entity, id)
{
	if (!pev_valid(entity) || !is_user_alive(id)) return FMRES_IGNORED;

	static sClassName[64];
	
	pev(entity, pev_classname, sClassName, charsmax(sClassName));
	
	if (!equal(sClassName, "package")) return FMRES_IGNORED;
	
	new iOrigin[3];
	get_user_origin(id, iOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(iResources[SPRITE_GREEN]);
	write_byte(20);
	write_byte(255);
	message_end();
	
	message_begin(MSG_ALL, SVC_TEMPENTITY, {0, 0, 0}, id);
	write_byte(TE_SPRITETRAIL);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 20);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 80);
	write_short(iResources[SPRITE_ACID]);
	write_byte(20);
	write_byte(20);
	write_byte(4);
	write_byte(20);
	write_byte(10);
	message_end();
	
	engfunc(EngFunc_RemoveEntity, entity);
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, gSounds[SOUND_PACKAGE], 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	use_package(id);

	return FMRES_IGNORED;
}

public check_rank(id)
{
	if (!Get(id, iLoaded)) return;

	new iStats[8], iBodyHits[8], iPreviousRank = gPlayer[id][RANK], iRank = get_user_stats(id, iStats, iBodyHits);

	while(gPlayer[id][KILLS] >= gRankKills[gPlayer[id][RANK] + 1] && gPlayer[id][RANK] < MAX_RANKS) gPlayer[id][RANK]++

	gPlayer[id][NEXT_RANK] = (gRankKills[gPlayer[id][RANK] + 1] == gRankKills[MAX_RANKS] ? gRankKills[gPlayer[id][RANK]] : gRankKills[gPlayer[id][RANK] + 1]);

	gPlayer[id][BADGES_COUNT] = 0;
	
	for (new i = 0; i < MAX_BADGES; i++) gPlayer[id][BADGES_COUNT] += gPlayer[id][BADGES][i];
	
	gPlayer[id][ORDERS_COUNT] = 0;
	
	for (new i = 0; i < MAX_ORDERS; i++) gPlayer[id][ORDERS_COUNT] += gPlayer[id][ORDERS][i];

	switch(gPlayer[id][RANK])
	{
		case 9: if (gPlayer[id][BADGES_COUNT] >= MAX_BADGES) gPlayer[id][RANK] = 17;
		case 12: if (gPlayer[id][BADGES_COUNT] >= floatround(MAX_BADGES * 2.5)) gPlayer[id][RANK] = 18;
		case 15: if (gPlayer[id][BADGES_COUNT] == MAX_BADGES * 3) gPlayer[id][RANK] = 19;
		case 16:
		{
			if (gPlayer[id][BADGES_COUNT] == MAX_BADGES * 4)
			{
				switch(iRank)
				{
					case 1: gPlayer[id][RANK] = 23;
					case 2: gPlayer[id][RANK] = 22;
					case 3: gPlayer[id][RANK] = 21;
					case 4 .. 15: gPlayer[id][RANK] = 20;
				}
			}
		}
	}
	
	if (gPlayer[id][KILLS] == gServer[MOSTSERVERKILLS]) gServer[MOSTSERVERKILLSID] = id;
	
	if (gPlayer[id][GOLD] > gServer[MOSTWINS])
	{
		gServer[MOSTWINS] = gPlayer[id][RANK];
		gServer[MOSTWINSID] = id;
		
		get_user_name(id, gServer[MOSTWINSNAME], charsmax(gServer[MOSTWINSNAME]));
	}
	
	if (is_ranked_higher(gPlayer[id][RANK], iPreviousRank))
	{
		client_cmd(id, "spk %s", gSounds[SOUND_RANKUP]);

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Gratulacje! Awansowales do rangi^x03 %s^x01.", gRankName[gPlayer[id][RANK]]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Gratulacje! Awansowales do rangi^x03 %s^x01.", gRankName[gPlayer[id][RANK]]);
		#endif
	}
	
	if (is_ranked_higher(gPlayer[id][RANK], gServer[HIGHESTRANK]))
	{
		gServer[HIGHESTRANK] = gPlayer[id][RANK];
		gServer[HIGHESTRANKID] = id;
		
		get_user_name(id, gServer[HIGHESTRANKNAME], charsmax(gServer[HIGHESTRANKNAME]));

		#if AMXX_VERSION_NUM < 183
		ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTRANKNAME], gRankName[gServer[HIGHESTRANK]]);
		#else
		client_print_color(0, id, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTRANKNAME], gRankName[gServer[HIGHESTRANK]]);
		#endif
	}

	if (is_ranked_higher(gPlayer[id][RANK], gServer[HIGHESTSERVERRANK]))
	{
		gServer[HIGHESTSERVERRANK] = gPlayer[id][RANK];
		
		client_cmd(id, "spk %s", gSounds[SOUND_RANKUP]);
		
		get_user_name(id, gServer[HIGHESTSERVERRANKNAME], charsmax(gServer[HIGHESTSERVERRANKNAME]));

		#if AMXX_VERSION_NUM < 183
		ColorChat(0, GREEN, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTSERVERRANKNAME], gRankName[gServer[HIGHESTSERVERRANK]]);
		#else
		client_print_color(0, id, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTSERVERRANKNAME], gRankName[gServer[HIGHESTSERVERRANK]]);
		#endif
	}
}

public check_badges(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return;

	new iWeaponKills, iRoundKills, iRoundHSKills, iBadge, iLevel, bool:bBadge;

	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Sprawdzanie zdobytych odznak...");
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Sprawdzanie zdobytych odznak...");
	#endif
	
	iBadge = gPlayer[id][BADGES][BADGE_KNIFE];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
	
		get_weapon_round_stats(id, CSW_KNIFE, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][KNIFE];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 50) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 100) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 250 && iRoundKills >= 2) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 500 && iRoundKills >= 3) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_KNIFE] = iLevel;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_KNIFE][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_KNIFE][iLevel]);
			#endif
		}
	}
	
	iBadge = gPlayer[id][BADGES][BADGE_PISTOL];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_GLOCK18, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_USP, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_P228, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_DEAGLE, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_FIVESEVEN, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_ELITE, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][PISTOL];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 100) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 250 && iRoundKills >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 500 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 1000 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_PISTOL] = iLevel;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_PISTOL][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_PISTOL][iLevel]);
			#endif
		}
	}
	
	iBadge = gPlayer[id][BADGES][BADGE_ASSAULT];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_AK47, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_M4A1, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_GALIL, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_FAMAS, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_SG552, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_AUG, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][RIFLE];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 500 && iRoundKills >= 2) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 1000 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 2500 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 5000 && iRoundKills >= 5 && iRoundHSKills >= 3) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_ASSAULT] = iLevel;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_ASSAULT][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_ASSAULT][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_SNIPER];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_SCOUT, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_AWP, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_G3SG1, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_SG550, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][SNIPER];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 250) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 500 && iRoundKills >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 1000 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 2500 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_SNIPER] = iLevel;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SNIPER][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SNIPER][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_SUPPORT];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_M249, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][M249];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 100) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 250 && iRoundKills >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 500 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 1000 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_SUPPORT] = iLevel;
			
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SUPPORT][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SUPPORT][iLevel]);
			#endif
		}
	}
	
	iBadge = gPlayer[id][BADGES][BADGE_EXPLOSIVES];

	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iWeaponKills = gPlayer[id][GRENADE];
		
		new iExplosions = gPlayer[id][EXPLOSIONS];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 50 && iExplosions >= 10) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 100 && iExplosions >= 25) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 175 && iExplosions >= 50) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 250 && iExplosions >= 100) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_EXPLOSIVES] = iLevel;
			
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_EXPLOSIVES][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_EXPLOSIVES][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_SHOTGUN];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_M3, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_XM1014, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][SHOTGUN];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 100) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 250 && iRoundKills >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 500 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 1000 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_SHOTGUN] = iLevel;
			
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SHOTGUN][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SHOTGUN][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_SMG];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		iRoundKills = 0;
		iRoundHSKills = 0;
		
		get_weapon_round_stats(id, CSW_MAC10, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_UMP45, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_TMP, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_MP5NAVY, iRoundKills, iRoundHSKills);
		get_weapon_round_stats(id, CSW_P90, iRoundKills, iRoundHSKills);

		iWeaponKills = gPlayer[id][SMG];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iWeaponKills >= 100) iLevel = LEVEL_START;
			case LEVEL_START: if (iWeaponKills >= 250 && iRoundKills >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iWeaponKills >= 500 && iRoundKills >= 3 && iRoundHSKills >= 1) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iWeaponKills >= 1000 && iRoundKills >= 4 && iRoundHSKills >= 2) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_SMG] = iLevel;
			
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SMG][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_SMG][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_TIME];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;
		
		new iDegree = gPlayer[id][DEGREE];

		switch (iBadge)
		{
			case LEVEL_NONE: if (iDegree >= 1) iLevel = LEVEL_START;
			case LEVEL_START: if (iDegree >= 2) iLevel = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (iDegree >= 3) iLevel = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (iDegree >= 4) iLevel = LEVEL_MASTER;
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;
			
			gPlayer[id][BADGES][BADGE_TIME] = iLevel;
			
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_TIME][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_TIME][iLevel]);
			#endif
		}
	}

	iBadge = gPlayer[id][BADGES][BADGE_GENERAL];
	
	if(iBadge != LEVEL_MASTER)
	{
		iLevel = LEVEL_NONE;

		switch (iBadge)
		{
			case LEVEL_NONE: 
			{
				new iBadges;
				
				for(new i = 0; i < MAX_BADGES - 1; i++)
					if(gPlayer[id][BADGES][i] >= LEVEL_START) iBadges++;

				if (iBadges >= MAX_BADGES - 1) iLevel = LEVEL_START;
			}
			case LEVEL_START: 
			{
				new iBadges;
				
				for(new i = 0; i < MAX_BADGES - 1; i++)
					if(gPlayer[id][BADGES][i] >= LEVEL_EXPERIENCED) iBadges++;

				if (iBadges >= MAX_BADGES - 1) iLevel = LEVEL_EXPERIENCED;
			}
			case LEVEL_EXPERIENCED: 
			{
				new iBadges;
				
				for(new i = 0; i < MAX_BADGES - 1; i++)
					if(gPlayer[id][BADGES][i] >= LEVEL_VETERAN) iBadges++;

				if (iBadges >= MAX_BADGES - 1) iLevel = LEVEL_VETERAN;
			}
			case LEVEL_VETERAN: 
			{
				new iBadges;
				
				for(new i = 0; i < MAX_BADGES - 1; i++)
					if(gPlayer[id][BADGES][i] >= LEVEL_MASTER) iBadges++;

				if (iBadges >= MAX_BADGES - 1) iLevel = LEVEL_MASTER;
			}
		}
		
		if(iLevel > iBadge)
		{
			bBadge = true;

			gPlayer[id][BADGES][BADGE_GENERAL] = iLevel;

			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_GENERAL][iLevel]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", gBadgeName[BADGE_GENERAL][iLevel]);
			#endif
		}
	}

	if (bBadge)
	{
		client_cmd(id, "spk %s", gSounds[SOUND_BADGE]);

		save_stats(id, NORMAL);
	}
	
	check_orders(id);
}

public check_orders(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return;

	new bool:bOrder;

	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Sprawdzanie zdobytych orderow...");
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Sprawdzanie zdobytych orderow...");
	#endif
	
	if(!gPlayer[id][ORDERS][ORDER_AIMBOT] && gPlayer[id][HS_KILLS] >= 2500)
	{
		gPlayer[id][ORDERS][ORDER_AIMBOT] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_AIMBOT][DESIGNATION], gOrders[ORDER_AIMBOT][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_AIMBOT][DESIGNATION], gOrders[ORDER_AIMBOT][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_ANGEL] && gPlayer[id][ASSISTS] >= 500)
	{
		gPlayer[id][ORDERS][ORDER_ANGEL] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_ANGEL][DESIGNATION], gOrders[ORDER_ANGEL][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_ANGEL][DESIGNATION], gOrders[ORDER_ANGEL][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_BOMBERMAN] && gPlayer[id][PLANTS] >= 100)
	{
		gPlayer[id][ORDERS][ORDER_BOMBERMAN] = 1;
		
		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_BOMBERMAN][DESIGNATION], gOrders[ORDER_BOMBERMAN][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_BOMBERMAN][DESIGNATION], gOrders[ORDER_BOMBERMAN][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_SAPER] && gPlayer[id][DEFUSES] >= 50)
	{
		gPlayer[id][ORDERS][ORDER_SAPER] = 1;
		
		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_SAPER][DESIGNATION], gOrders[ORDER_SAPER][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_SAPER][DESIGNATION], gOrders[ORDER_SAPER][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_PERSIST] && gPlayer[id][VISITS] >= 100)
	{
		gPlayer[id][ORDERS][ORDER_PERSIST] = 1;
		
		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_PERSIST][DESIGNATION], gOrders[ORDER_PERSIST][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_PERSIST][DESIGNATION], gOrders[ORDER_PERSIST][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_DESERV] && (gPlayer[id][GOLD] + gPlayer[id][SILVER]  + gPlayer[id][BRONZE]) >= 100)
	{
		gPlayer[id][ORDERS][ORDER_DESERV] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_DESERV][DESIGNATION], gOrders[ORDER_DESERV][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_DESERV][DESIGNATION], gOrders[ORDER_DESERV][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_MILION] && gPlayer[id][EARNED] >= 1000000)
	{
		gPlayer[id][ORDERS][ORDER_MILION] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_MILION][DESIGNATION], gOrders[ORDER_MILION][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_MILION][DESIGNATION], gOrders[ORDER_MILION][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_BULLET] && gPlayer[id][DMG_RECEIVED] >= 50000)
	{
		gPlayer[id][ORDERS][ORDER_BULLET] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_BULLET][DESIGNATION], gOrders[ORDER_BULLET][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_BULLET][DESIGNATION], gOrders[ORDER_BULLET][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_RAMBO] && gPlayer[id][DMG_TAKEN] >= 50000)
	{
		gPlayer[id][ORDERS][ORDER_RAMBO] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_RAMBO][DESIGNATION], gOrders[ORDER_RAMBO][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_RAMBO][DESIGNATION], gOrders[ORDER_RAMBO][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if(!gPlayer[id][ORDERS][ORDER_SURVIVER] && gPlayer[id][SURVIVED] >= 1000)
	{
		gPlayer[id][ORDERS][ORDER_SURVIVER] = 1;

		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_SURVIVER][DESIGNATION], gOrders[ORDER_SURVIVER][NEEDS]);
		#else
		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", gOrders[ORDER_SURVIVER][DESIGNATION], gOrders[ORDER_SURVIVER][NEEDS]);
		#endif
		
		bOrder = true;
	}
	
	if (bOrder)
	{
		client_cmd(id, "spk %s", gSounds[SOUND_ORDER]);

		save_stats(id, NORMAL);
	}
}

public most_kills_disconnect()
{
	new iPlayers[32], iNum, player;
	get_players(iPlayers, iNum, "h");
	
	gServer[MOSTKILLS] = 0;
	gServer[MOSTKILLSID] = 0;
	gServer[MOSTKILLSNAME] = "";
	
	for (new i = 1; i < iNum; i++)
	{
		player = iPlayers[i];
		
		if (gPlayer[player][KILLS] > gServer[MOSTKILLS])
		{
			gServer[MOSTKILLS] = gPlayer[player][KILLS];
			gServer[MOSTKILLSID] = player;
		}
	}

	if (!gServer[MOSTKILLSID]) return;
	
	get_user_name(gServer[MOSTKILLSID], gServer[MOSTKILLSNAME], charsmax(gServer[MOSTKILLSNAME]));
	
	#if AMXX_VERSION_NUM < 183
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTKILLSNAME], gServer[MOSTKILLS]);
	#else
	client_print_color(0, gServer[MOSTKILLSID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", gServer[MOSTKILLSNAME], gServer[MOSTKILLS]);
	#endif
}

public most_wins_disconnect()
{
	new iPlayers[32], iNum, player;
	get_players(iPlayers, iNum, "h");
	
	gServer[MOSTWINS] = 0;
	gServer[MOSTWINSID] = 0;
	gServer[MOSTWINSNAME] = "";
	
	for (new i = 1; i < iNum; i++)
	{
		player = iPlayers[i];
		
		if (gPlayer[player][KILLS] > gServer[MOSTWINS])
		{
			gServer[MOSTWINS] = gPlayer[player][KILLS];
			gServer[MOSTWINSID] = player;
		}
	}

	if (!gServer[MOSTWINSID]) return;
	
	get_user_name(gServer[MOSTWINSID], gServer[MOSTWINSNAME], charsmax(gServer[MOSTWINSNAME]));

	#if AMXX_VERSION_NUM < 183
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem w zwyciestwach z^x03 %i^x01 zlotymi medalami.", gServer[MOSTWINSNAME], gServer[MOSTWINS]);
	#else
	client_print_color(0, gServer[MOSTWINSID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem w zwyciestwach z^x03 %i^x01 zlotymi medalami.", gServer[MOSTWINSNAME], gServer[MOSTWINS]);
	#endif
}

public highest_rank_disconnect()
{
	new iPlayers[32], iNum, player;
	get_players(iPlayers, iNum, "h");

	gServer[HIGHESTRANK] = 0;
	gServer[HIGHESTRANKID] = 0;
	gServer[HIGHESTRANKNAME] = "";

	for (new i = 1; i < iNum; i++)
	{
		player = iPlayers[i];
		
		if (is_ranked_higher(gPlayer[player][RANK], gServer[HIGHESTRANK]))
		{
			gServer[HIGHESTRANK] = gPlayer[player][RANK];
			gServer[HIGHESTRANKID] = player;
		}
	}

	if (!gServer[HIGHESTRANK]) return;

	get_user_name(gServer[HIGHESTRANKID], gServer[HIGHESTRANKNAME], charsmax(gServer[HIGHESTRANKNAME]));
	
	#if AMXX_VERSION_NUM < 183
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTRANKNAME], gRankName[gServer[HIGHESTRANK]]);
	#else
	client_print_color(0, gServer[HIGHESTRANKID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", gServer[HIGHESTRANKNAME], gRankName[gServer[HIGHESTRANK]]);
	#endif
}

public award_check()
{
	enum _:eWiners { THIRD, SECOND, FIRST };
	
	new sName[eWiners][32], sPlayers[32], iBestID[eWiners], iBestFrags[eWiners], bool:bNewLeader, iNum, iTempFrags, iSwapFrags, iSwapID, id;
	
	get_players(sPlayers, iNum, "h");
	
	if(!iNum) return;

	for (new i = 0; i < iNum; i++)
	{
		id = sPlayers[i];
		
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id))
			continue;
		
		iTempFrags = get_user_frags(id);
		
		if(iTempFrags > iBestFrags[THIRD])
		{
			iBestFrags[THIRD] = iTempFrags;
			iBestID[THIRD] = id;
			
			if(iTempFrags > iBestFrags[SECOND])
			{
				iSwapFrags = iBestFrags[SECOND];
				iSwapID = iBestID[SECOND];
				iBestFrags[SECOND] = iTempFrags;
				iBestID[SECOND] = id;
				iBestFrags[THIRD] = iSwapFrags;
				iBestID[THIRD] = iSwapID;
				
				if(iTempFrags > iBestFrags[FIRST])
				{
					iSwapFrags = iBestFrags[FIRST];
					iSwapID = iBestID[FIRST];
					iBestFrags[FIRST] = iTempFrags;
					iBestID[FIRST] = id;
					iBestFrags[SECOND] = iSwapFrags;
					iBestID[SECOND] = iSwapID;
				}
			}
		}
	}
	
	if(!iBestID[FIRST]) return;
	
	gPlayer[iBestID[THIRD]][BRONZE]++;
	gPlayer[iBestID[SECOND]][SILVER]++;
	gPlayer[iBestID[FIRST]][GOLD]++;
	
	for(new i = 0; i < iNum; i++) if(is_user_connected(id)) save_stats(id, MAP_END);
	
	for(new i = 0; i < 3; i++) get_user_name(iBestID[i], sName[i], charsmax(sName[]));
	
	if (gPlayer[iBestID[FIRST]][GOLD] > gServer[MOSTSERVERWINS])
	{
		bNewLeader = true;
		
		gServer[MOSTSERVERWINS] = gPlayer[iBestID[FIRST]][GOLD];
		
		formatex(gServer[MOSTSERVERWINSNAME], charsmax(gServer[MOSTSERVERWINSNAME]), sName[FIRST]);
	}

	#if AMXX_VERSION_NUM < 183
	ColorChat(0, GREEN, "^x04[BF1]^x01 Gratulacje dla^x03 Zwyciezcow^x01!");
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 - Zloty Medal -^x03 %i^x01 Zabojstw%s.", sName[FIRST], iBestFrags[FIRST], bNewLeader ? " - Wygrywa" : "");
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 - Srebrny Medal -^x03 %i^x01 Zabojstw.", sName[SECOND], iBestFrags[SECOND]);
	ColorChat(0, GREEN, "^x04[BF1]^x03 %s^x01 - Brazowy Medal -^x03 %i^x01 Zabojstw.", sName[THIRD], iBestFrags[THIRD]);
	#else
	client_print_color(0, 0, "^x04[BF1]^x01 Gratulacje dla^x03 Zwyciezcow^x01!");
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Zloty Medal -^x03 %i^x01 Zabojstw%s.", sName[FIRST], iBestFrags[FIRST], bNewLeader ? " - Wygrywa" : "");
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Srebrny Medal -^x03 %i^x01 Zabojstw.", sName[SECOND], iBestFrags[SECOND]);
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Brazowy Medal -^x03 %i^x01 Zabojstw.", sName[THIRD], iBestFrags[THIRD]);
	#endif
}

public get_weapon_round_stats(id, weapon, &iRoundKills, &iRoundHSKills)
{
	new iStats[8], iBodyHits[8];
	
	get_user_wrstats(id, weapon, iStats, iBodyHits);
	
	iRoundKills += iStats[0];
	iRoundHSKills += iStats[2];
	
	return 1;
}

bool:is_ranked_higher(rank1, rank2)
	return (gRankOrder[rank1] > gRankOrder[rank2]) ? true : false;

public chat_prefix(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if (!is_user_connected(id)) return PLUGIN_CONTINUE;

	new sTemp[256], sMessage[256], sPrefix[64];
	
	get_msg_arg_string(2, sTemp, charsmax(sTemp));
	
	formatex(sPrefix, charsmax(sPrefix), "^x04[%s]", gRankName[gPlayer[id][RANK]]);
	
	if (!equal(sTemp, "#Cstrike_Chat_All"))
	{
		add(sMessage, charsmax(sMessage), sPrefix);
		add(sMessage, charsmax(sMessage), " ");
		add(sMessage, charsmax(sMessage), sTemp);
	}
	else
	{
		add(sMessage, charsmax(sMessage), sPrefix);
		add(sMessage, charsmax(sMessage), " ^x03%s1 ^x01:  %s2");
	}
	
	set_msg_arg_string(2, sMessage);
	
	return PLUGIN_CONTINUE;
}

public block_message()
{
	if(get_msg_argtype(2) == ARG_STRING) 
	{
		new sText[32];
		
		get_msg_arg_string(2, sText, charsmax(sText));

		if(equali(sText, "#Cannot_Carry_Anymore")) return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public flashbang_buy(id) 
	if(gPlayer[id][BADGES][BADGE_GENERAL]) handle_buy(id, CSW_FLASHBANG, 0);

public hegrenade_buy(id) 
	if(gPlayer[id][BADGES][BADGE_GENERAL]) handle_buy(id, CSW_HEGRENADE, 0);

public smokegrenade_buy(id) 
	if(gPlayer[id][BADGES][BADGE_GENERAL]) handle_buy(id, CSW_SMOKEGRENADE, 0);
	
public handle_buy(id, grenade, nocost) 
{
	if(!is_user_alive(id) && get_user_team(id) < 1 && get_user_team(id) > 2 && !cs_get_user_buyzone(id) && !nocost) return PLUGIN_CONTINUE;

	new iMaxAmmo, iCost, iBadge = gPlayer[id][BADGES][BADGE_GENERAL];

	switch(grenade) 
	{
		case CSW_FLASHBANG: iMaxAmmo = iBadge > LEVEL_NONE ? (iBadge > LEVEL_EXPERIENCED ? 4 : 3) : 2, iCost = 200;
		case CSW_HEGRENADE: iMaxAmmo = iBadge > LEVEL_START ? 2 : 1, iCost = 300;
		case CSW_SMOKEGRENADE: iMaxAmmo = iBadge > LEVEL_VETERAN ? 2 : 1, iCost = 300;
	}
	
	if(!nocost)
	{
		new Float:fBuyTime = get_cvar_float("mp_buytime") * 60.0;
		new Float:fTimePasses = get_gametime() - fGameTime;

		if(floatcmp(fTimePasses, fBuyTime) == 1) return PLUGIN_HANDLED;

		if(cs_get_user_money(id) - iCost <= 0) 
		{
			client_print(id, print_center, "You have insufficient funds!");
		
			return PLUGIN_HANDLED;
		}
	}

	if(cs_get_user_bpammo(id, grenade) == iMaxAmmo) 
	{
		if(!nocost) client_print(id, print_center, "You cannot carry anymore!");
		
		return PLUGIN_HANDLED;
	}

	give_grenade(id, grenade);

	if(!nocost) cs_set_user_money(id, cs_get_user_money(id) - iCost, 1);

	return PLUGIN_CONTINUE;
}

public give_grenade(id, grenade) 
{
	new iGrenades = cs_get_user_bpammo(id, grenade);
	
	if(!iGrenades)
	{
		switch(grenade)
		{
			case CSW_FLASHBANG: give_item(id, "weapon_flashbang");
			case CSW_HEGRENADE: give_item(id, "weapon_hegrenade");
			case CSW_SMOKEGRENADE: give_item(id, "weapon_smokegrenade");
		}
	}
	
	cs_set_user_bpammo(id, grenade, iGrenades + 1);

	emit_sound(id, CHAN_WEAPON, gSounds[SOUND_GRENADE], 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public touch_grenades(model, id) 
{
	if(!is_valid_ent(model) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	if(entity_get_int(model, EV_INT_iuser1)) return PLUGIN_HANDLED;

	new sModel[64];
	
	entity_get_string(model, EV_SZ_model, sModel, charsmax(sModel));

	new grenade = check_grenade_model(sModel);

	if(grenade != -1)
	{
		new iAmmo = cs_get_user_bpammo(id, grenade), iMaxAmmo, iBadge = gPlayer[id][BADGES][BADGE_GENERAL];

		switch(grenade)
		{
			case CSW_FLASHBANG: iMaxAmmo = iBadge > LEVEL_NONE ? (iBadge > LEVEL_EXPERIENCED ? 4 : 3) : 2;
			case CSW_HEGRENADE: iMaxAmmo = iBadge > LEVEL_START ? 2 : 1;
			case CSW_SMOKEGRENADE: iMaxAmmo = iBadge > LEVEL_VETERAN ? 2 : 1;
		}

		if(iMaxAmmo <= 0) return PLUGIN_CONTINUE;

		if(!iAmmo)
		{
			set_entity_visibility(model, 0);
			
			entity_set_int(model, EV_INT_iuser1, 1);

			return PLUGIN_CONTINUE;
		}

		if(iAmmo < iMaxAmmo)
		{
			set_entity_visibility(model, 0);
			
			entity_set_int(model, EV_INT_iuser1, 1);
			
			give_grenade(id, grenade);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public check_grenade_model(sModel[]) 
{
	if(equal(sModel, "models/w_flashbang.mdl" )) return CSW_FLASHBANG;
	
	if(equal(sModel, "models/w_hegrenade.mdl")) return CSW_HEGRENADE;
	
	if(equal(sModel, "models/w_smokegrenade.mdl")) return CSW_SMOKEGRENADE;

	return -1;
}

public display_advertisement(id)
{
	id -= TASK_AD;
	
	if (!get_pcvar_num(pCvarBF1Active)) return;

	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Ten serwer uzywa^x03 %s^x01 w wersji^x03 %s^x01 autorstwa^x03 %s^x01.", PLUGIN, VERSION, AUTHOR);
	ColorChat(id, GREEN, "^x04[BF1]^x01 Wpisz^x03 /bf1^x01 lub^x03 /pomoc^x01, aby uzyskac wiecej informacji.");
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Ten serwer uzywa^x03 %s^x01 w wersji^x03 %s^x01 autorstwa^x03 %s^x01.", PLUGIN, VERSION, AUTHOR);
	client_print_color(id, id, "^x04[BF1]^x01 Wpisz^x03 /bf1^x01 lub^x03 /pomoc^x01, aby uzyskac wiecej informacji.");
	#endif
}

public display_hud(id)
{
	id -= TASK_HUD;
	
	if (!get_pcvar_num(pCvarBF1Active) || !is_user_connected(id)) return PLUGIN_CONTINUE;

	new target = id;
	
	if (!is_user_alive(id))
	{
		target = pev(id, pev_iuser2);
		
		if (!gPlayer[target][HUD]) set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0, 4);
		else set_dhudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0);
	}
	else
	{
		if (!gPlayer[target][HUD]) set_hudmessage(gPlayer[target][HUD_RED], gPlayer[target][HUD_GREEN], gPlayer[target][HUD_BLUE], float(gPlayer[target][HUD_POSX]) / 100.0, float(gPlayer[target][HUD_POSY]) / 100.0, 0, 0.0, 0.3, 0.0, 0.0, 4);
		else set_dhudmessage(gPlayer[target][HUD_RED], gPlayer[target][HUD_GREEN], gPlayer[target][HUD_BLUE], float(gPlayer[target][HUD_POSX]) / 100.0, float(gPlayer[target][HUD_POSY]) / 100.0, 0, 0.0, 0.3, 0.0, 0.0);
	}
	
	if (!target) return PLUGIN_CONTINUE;

	static sInfo[512], iSeconds, iMinutes, iHours;
	
	if (!Get(target, iLoaded)) formatex(sInfo, charsmax(sInfo), "[%s] Trwa wczytywanie danych...", PLUGIN);
	else
	{
		iSeconds = (gPlayer[target][TIME] + get_user_time(target)), iMinutes = 0, iHours = 0;
	
		while (gPlayer[target][DEGREE] < sizeof(gDegrees) && iSeconds / 3600 >= str_to_num(gDegrees[gPlayer[target][DEGREE] + 1][HOURS])) gPlayer[target][DEGREE]++;
	
		while(iSeconds >= 60)
		{
			iSeconds -= 60;
			iMinutes++;
		
			if (iMinutes >= 60)
			{
				iMinutes -= 60;
				iHours++;
			}
		}
		
		if (gPlayer[target][HUD] < TYPE_STATUSTEXT) formatex(sInfo, charsmax(sInfo), "[%s]^n[Ranga]: %s^n[Odznaki]: %d/%d^n[Ordery]: %d/%d^n[Zabicia]: %d/%d^n[Czas Gry]: %i h %i min %i s^n[Stopien]: %s", PLUGIN, gRankName[gPlayer[target][RANK]], gPlayer[target][BADGES_COUNT], MAX_BADGES * 4, gPlayer[target][ORDERS_COUNT], MAX_ORDERS, gPlayer[target][KILLS], gPlayer[target][NEXT_RANK], iHours, iMinutes, iSeconds, gDegrees[gPlayer[target][DEGREE]][DEGREES]);
		else formatex(sInfo, charsmax(sInfo), "[BF1] Zabicia: %d/%d  Ranga: %s Odznaki: %d/%d", gPlayer[target][KILLS], gPlayer[target][NEXT_RANK], gRankName[gPlayer[target][RANK]], gPlayer[target][BADGES_COUNT], MAX_BADGES * 4);
	}

	switch(gPlayer[target][HUD])
	{
		case TYPE_HUD: ShowSyncHudMsg(id, gHUD, sInfo);
		case TYPE_DHUD: show_dhudmessage(id, sInfo);
		case TYPE_STATUSTEXT:
		{
			message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
			write_byte(0);
			write_string(sInfo);
			message_end();
		}
	}
	
	return PLUGIN_CONTINUE;
}

public display_help()
{
	switch(random_num(1, 4))
	{
		case 1: 
		{ 
			#if AMXX_VERSION_NUM < 183
			ColorChat(0, GREEN, "^x04[BF1]^x01 Mozesz spersonalizowac wyswietlanie informacji w HUD wpisujac^x03 /hud"); 
			#else
			client_print_color(0, 0, "^x04[BF1]^x01 Mozesz spersonalizowac wyswietlanie informacji w HUD wpisujac^x03 /hud");
			#endif
		}
		case 2:
		{ 
			#if AMXX_VERSION_NUM < 183
			ColorChat(0, GREEN, "^x04[BF1]^x01 Chcesz dowiedziec sie wiecej o modzie BF1? Wpisz komende^x03 /pomoc");
			#else
			client_print_color(0, 0, "^x04[BF1]^x01 Chcesz dowiedziec sie wiecej o modzie BF1? Wpisz komende^x03 /pomoc");
			#endif
		}
		case 3:
		{ 
			#if AMXX_VERSION_NUM < 183
			ColorChat(0, GREEN, "^x04[BF1]^x01 Aby wejsc do glownego menu BF1 nalezy wpisac komende^x03 /bf1");
			#else
			client_print_color(0, 0, "^x04[BF1]^x01 Aby wejsc do glownego menu BF1 nalezy wpisac komende^x03 /bf1");
			#endif
		}
		case 4:
		{ 
			#if AMXX_VERSION_NUM < 183
			ColorChat(0, GREEN, "^x04[BF1]^x01 W paczkach wypadajacych z graczy znajdziesz^x03 hp, fragi, kase, odznaki^x01!");
			#else
			client_print_color(0, 0, "^x04[BF1]^x01 W paczkach wypadajacych z graczy znajdziesz^x03 hp, fragi, kase, odznaki^x01!");
			#endif
		}
	}
}

public cmd_say(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new sText[31];
	
	read_args(sText, charsmax(sText));
	remove_quotes(sText);

	if (equal(sText, "/whostats", 9))
	{
		new player = cmd_target(id, sText[10], 0);
		
		if (!player || is_user_bot(player) || is_user_hltv(player))
		{
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", sText[10]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", sText[10]);
			#endif
			
			return PLUGIN_CONTINUE;
		}

		cmd_stats(id, player);

		return PLUGIN_CONTINUE;
	}
	
	if (equal(sText, "/whois", 6))
	{
		new player = cmd_target(id, sText[7], 0);
		
		if (!player || is_user_bot(player) || is_user_hltv(player))
		{
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", sText[7]);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", sText[7]);
			#endif
			
			return PLUGIN_CONTINUE;
		}

		cmd_badges(id, player);

		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public cmd_rankhelp(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new sMotd[2048], sTemp[128];

	formatex(sMotd, charsmax(sMotd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong>Wymagania Rang</strong><br><br>");
	add(sMotd, charsmax(sMotd), sTemp);

	for (new i = 0; i < MAX_RANKS - 1; i++)
	{
		formatex(sTemp, charsmax(sTemp), "%s - %d Zabic<br>", gRankName[i], gRankKills[i]);
		add(sMotd, charsmax(sMotd), sTemp);

		switch(i)
		{
			case 9:
			{
				formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz %d Odznak<br>", gRankName[17], gRankName[9], MAX_BADGES);
				add(sMotd, charsmax(sMotd), sTemp);
			}
			case 12:
			{
				formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz %d Odznak<br>", gRankName[18], gRankName[12], floatround(MAX_BADGES * 2.5));
				add(sMotd, charsmax(sMotd), sTemp);
			}
		}
	}

	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz %d Odznaki<br>", gRankName[19], gRankName[15], MAX_BADGES * 4);
	add(sMotd, charsmax(sMotd), sTemp);

	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz %d Zabic<br>", gRankName[16], gRankName[19], gRankKills[MAX_RANKS - 1]);
	add(sMotd, charsmax(sMotd), sTemp);

	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz pozycja w Top15 rankingu BF1<br>", gRankName[20], gRankName[16]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz pozycja Top3 rankingu BF1<br>", gRankName[21], gRankName[16]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz pozycja Top2 rankingu BF1<br>", gRankName[22], gRankName[16]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "%s - Wymagane %s oraz pozycja Top1 rankingu BF1<br></font></body></html>", gRankName[23], gRankName[16]);
	add(sMotd, charsmax(sMotd), sTemp);

	show_motd(id, sMotd, "BF1: Wymagania Rang");
	
	return PLUGIN_CONTINUE;
}

public cmd_serverstats(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new sMotd[2048], sTemp[256];

	formatex(sMotd, charsmax(sMotd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^">");
	add(sMotd, charsmax(sMotd), sTemp);

	formatex(sTemp, charsmax(sTemp), "<strong>Obecne Statystyki</strong><br><br>Najwyzsza Ranga: %s (%s)<br><br>Najwiecej Zabic: %s (%i)<br><br>Najwiecej Zwyciestw: %s (%i)<br><br>", 
	gServer[HIGHESTRANKNAME], gRankName[gServer[HIGHESTRANK]], gServer[MOSTKILLSNAME], gServer[MOSTKILLS], gServer[MOSTWINSNAME], gServer[MOSTWINS]);
	add(sMotd, charsmax(sMotd), sTemp);

	formatex(sTemp,charsmax(sTemp), "<strong>Statystyki Serwera</strong><br><br>Najwyzsza Ranga: %s (%s)<br><br>Najwiecej Zabic: %s (%i)<br><br>Najwiecej Zwyciestw: %s (%i)<br><br></font></body></html>", 
	gServer[HIGHESTSERVERRANKNAME], gRankName[gServer[HIGHESTSERVERRANK]], gServer[MOSTSERVERKILLSNAME], gServer[MOSTSERVERKILLS], gServer[MOSTSERVERWINSNAME], gServer[MOSTSERVERWINS]);
	add(sMotd, charsmax(sMotd), sTemp);

	show_motd(id, sMotd, "BF1: Statystyki Serwera");

	return PLUGIN_CONTINUE;
}

public cmd_badgehelp(id, badge)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;
	
	new sMotd[128], sURL[64], sBadgeURL[64], sTitle[32];
	
	get_pcvar_string(pCvarHelpUrl, sURL, charsmax(sURL));
	
	switch(badge)
	{
		case 1:	
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_nozem.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Nozem");
		}
		case 2:	
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_pistoletami.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Pistoletami");
		}
		case 3:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_bronia_szturmowa.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Bronia Szturmowa");
		}
		case 4:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_bronia_snajperska.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Bronia Snajperska");
		}
		case 5:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_bronia_wsparcia.htm"); 
			formatex(sTitle, charsmax(sTitle), "Bronia Wsparcia");
		}
		case 6:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_bronia_wybuchowa.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Bronia Wybuchowa");
		}
		case 7:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_shotgunami.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Bronia Shotgunami");
		}
		case 8:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_smg.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Bronia SMG");
		}
		case 9:
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_czasowa.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Czasowa");
		}
		case 10: 
		{
			formatex(sBadgeURL, charsmax(sBadgeURL), "walka_ogolna.htm"); 
			formatex(sTitle, charsmax(sTitle), "BF1: Odznaka Walka Ogolna");
		}
	}

	formatex(sMotd, charsmax(sMotd), "%s/%s", equal(sURL, "") ? sConfigsDir : sURL, sBadgeURL);
	
	show_motd(id, sMotd, sTitle);
	
	return PLUGIN_CONTINUE;
}

public cmd_badges(id, player)
{
	new sMotd[2048], sTemp[128], sName[32];
	
	get_user_name(player, sName, charsmax(sName));

	formatex(sMotd, charsmax(sMotd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong><b>");
	formatex(sTemp, charsmax(sTemp), "Statystyki Rang i Odznak dla gracza %s</strong></b><br><br>Ranking: %s<br><br>Zdobyte Odznaki: %d/%d<br>", 
	sName, gRankName[gPlayer[player][RANK]], gPlayer[player][BADGES_COUNT], MAX_BADGES * 4);
	add(sMotd, charsmax(sMotd), sTemp);

	for (new i = 0; i < MAX_BADGES; i++)
	{
		if (gPlayer[player][BADGES][i])
		{
			formatex(sTemp, charsmax(sTemp), "%s - %s<br>", gBadgeName[i][gPlayer[player][BADGES][i]], gBadgeInfo[i]);
			add(sMotd, charsmax(sMotd), sTemp);
		}
	}
	
	formatex(sTemp, charsmax(sTemp), "<br>Zdobyte Ordery: %d/%d<br>", gPlayer[player][ORDERS_COUNT], MAX_ORDERS);
	add(sMotd, charsmax(sMotd), sTemp);
	
	for (new i = 0; i < MAX_ORDERS; i++)
	{
		if (gPlayer[player][ORDERS][i])
		{
			formatex(sTemp, charsmax(sTemp), "%s - %s<br>", gOrders[i][DESIGNATION], gOrders[i][NEEDS]);
			add(sMotd, charsmax(sMotd), sTemp);
		}
	}

	add(sMotd,charsmax(sMotd),"</font></body></html>");

	show_motd(id, sMotd, "BF1: Informacje o Graczu");

 	return PLUGIN_CONTINUE;
}

public cmd_ranks(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new sMotd[2048], sTemp[128], sName[32], iPlayers[32], player, iNum;

	formatex(sMotd,charsmax(sMotd),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong><b>Ranking Graczy</strong></b><br><br>");

	get_players(iPlayers, iNum);

	for (new i = 0; i < iNum; i++)
	{
		player = iPlayers[i];
		
		if(is_user_bot(player) || is_user_hltv(player)) continue;
		
		get_user_name(player, sName, charsmax(sName));
		
		formatex(sTemp, charsmax(sTemp), "%s - %s<br>", sName, gRankName[gPlayer[player][RANK]]);
		add(sMotd, charsmax(sMotd), sTemp);
	}
	
	add(sMotd, charsmax(sMotd), "</font></body></html>");

	show_motd(id, sMotd, "BF1: Ranking Graczy");

	return PLUGIN_CONTINUE;
}

public cmd_orders(id)
{
	new sMotd[1024], sTemp[256];
	
	formatex(sMotd, charsmax(sMotd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FF0000^"><strong><center>Lista Orderow:</font><br><font size=^"1^" face=^"verdana^" color=^"FFFFFF^">");
	
	for(new i; i < MAX_ORDERS; i++)
	{
		formatex(sTemp, charsmax(sTemp), "%s - %s <br>", gOrders[i][DESIGNATION], gOrders[i][NEEDS]);
		add(sMotd, charsmax(sMotd), sTemp);
	}

	add(sMotd,charsmax(sMotd), "</font></center></body></html>");
	
	show_motd(id, sMotd, "Lista Orderow");
	
	return PLUGIN_CONTINUE;
}

public cmd_help(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new sMotd[256], sURL[128];
	get_pcvar_string(pCvarHelpUrl, sURL, charsmax(sURL));

	if (equal(sURL, ""))
	{
		formatex(sURL, charsmax(sURL), "%s/bf1webdocs/pomoc.htm", sConfigsDir);
		show_motd(id, sURL, "BF1: Pomoc");
	}
	else
	{
		formatex(sMotd,charsmax(sMotd), "<html><iframe src =^"%s/pomoc.htm^" scrolling=^"yes^" width=^"800^" height=^"600^"></iframe></html>", sURL);
		show_motd(id, sMotd, "BF1: Pomoc");
	}

	return PLUGIN_CONTINUE;
}

public cmd_mystats(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	cmd_stats(id, id);

	return PLUGIN_CONTINUE;
}

public cmd_stats(id, player)
{
	new sMotd[2048], sTemp[256], sName[32], iStats[8], iBodyHits[8], iRanked = get_user_stats(player, iStats, iBodyHits), iRank = gPlayer[player][RANK], iNextRank;

	switch(iRank)
	{
		case 16, 19, 20, 21, 22, 23: iNextRank = 15;
		case 17: iNextRank = 7;
		case 18: iNextRank = 8;
		default: iNextRank = iRank;
	}
	
	++iNextRank;

	get_user_name(player, sName, charsmax(sName));

	formatex(sMotd, charsmax(sMotd), "<html><style type=^"text/css^">h1{font-size:10px;color:c4c4c4;margin:0}h2{font-size:12px;color:white;margin:0}</style>");
	formatex(sTemp, charsmax(sTemp), "<body bgcolor=^"#474642^"><h2><strong>Statystyki Gracza: %s</strong><br>(Aktualizowane co Runde)<br><br><table border=^"0^">", sName);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "<tr><td align=^"left^"><h2>Ranking: #%d<br><br>Odznaki: %d/%d<br><br>Ordery: %d/%d<br><br>Ranga: %s<br><br>Zabicia: %d<br><br>Zabicia z HS: %d<br><br>Asysty: %d<br><br>", 
	iRanked, gPlayer[id][BADGES_COUNT], MAX_BADGES * 4, gPlayer[id][ORDERS_COUNT], MAX_ORDERS, gRankName[iRank], gPlayer[player][KILLS], gPlayer[player][HS_KILLS], gPlayer[player][ASSISTS]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp,charsmax(sTemp),"<h2>Przetrwane Rundy: %d<br><br><h2>Zdobyte Pieniadze: %d<br><br>Zdobyte Medale: %d<br><h1>Zlote: %d<br>Srebrne: %d<br>Brazowe: %d", 
	gPlayer[player][SURVIVED], gPlayer[player][EARNED], gPlayer[player][GOLD] + gPlayer[player][SILVER] + gPlayer[player][BRONZE], gPlayer[player][GOLD], gPlayer[player][SILVER], gPlayer[player][BRONZE]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp,charsmax(sTemp),"<br><br><h2>Obrazenia:<br><h1>Zadane: %d<br>Otrzymane: %d<br><br><h2>Bomby:<h1>Podlozone: %d<br>Wysadzone: %d<br>Rozbrojone %d<br><br><h2>Uratowane Hosty: %d<td width=^"120^"></td>",
	gPlayer[player][DMG_TAKEN], gPlayer[player][DMG_RECEIVED], gPlayer[player][XM1014], gPlayer[player][PLANTS], gPlayer[player][EXPLOSIONS], gPlayer[player][DEFUSES], gPlayer[player][RESCUES]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "<td><br><h2>Zabicia z Noza: %d<br><br>Zabicia Pistoletami: %d<h1>Glock: %d<br>USP: %d<br>P228: %d<br>Deagle: %d<br>FiveSeven: %d<br>Dual Elites: %d<br><br>", 
	gPlayer[player][KNIFE], gPlayer[player][PISTOL], gPlayer[player][GLOCK], gPlayer[player][USP], gPlayer[player][P228], gPlayer[player][DEAGLE], gPlayer[player][FIVESEVEN], gPlayer[player][ELITES]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "<h2>Zabicia Snajperkami: %d<h1>Scout: %d<br>AWP: %d<br>G3SG1: %d<br>SG550: %d<br><br>", 
	gPlayer[player][SNIPER], gPlayer[player][SCOUT], gPlayer[player][AWP], gPlayer[player][G3SG1], gPlayer[player][SG550]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp, charsmax(sTemp), "<h2>Zabicia Karabinami: %d<h1>AK47: %d<br>M4A1: %d<br>Galil: %d<br>Famas: %d<br>SG552: %d<br>AUG: %d<br><br><h2>Zabicia z M249: %d<br><br>",
	gPlayer[player][RIFLE], gPlayer[player][AK47], gPlayer[player][M4A1], gPlayer[player][GALIL], gPlayer[player][FAMAS], gPlayer[player][SG552], gPlayer[player][AUG], gPlayer[player][M249]);
	add(sMotd, charsmax(sMotd), sTemp);
	
	formatex(sTemp,charsmax(sTemp), "Zabicia z SMG: %d<h1>MAC10: %d<br>TMP: %d<br>MP5: %d<br>UMP45: %d<br>P90: %d<br><br><h2>Zabicia Granatami: %d<br><br>Zabicia Shotgunami: %d<h1>M3: %d<br>XM1014: %d</tr></table></body></html>",
	gPlayer[player][SMG], gPlayer[player][MAC10], gPlayer[player][TMP], gPlayer[player][MP5], gPlayer[player][UMP45], gPlayer[player][P90], gPlayer[player][GRENADE], gPlayer[player][SHOTGUN], gPlayer[player][M3], gPlayer[player][XM1014]);
	add(sMotd, charsmax(sMotd), sTemp);

	show_motd(id, sMotd, "BF1: Statystyki Gracza");
}

public hud_menu(id)
{
	new szMenu[128], menu = menu_create("\yBF1: \rKonfiguracja HUD", "hud_menu_handle");
	
	format(szMenu, charsmax(szMenu), "\wSposob \yWyswietlania: \r%s", gPlayer[id][HUD] > TYPE_HUD ? (gPlayer[id][HUD] > TYPE_DHUD ? "StatusText" : "DHUD") : "HUD");
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wKolor \yCzerwony: \r%i", gPlayer[id][HUD_RED]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wKolor \yZielony: \r%i", gPlayer[id][HUD_GREEN]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wKolor \yNiebieski: \r%i", gPlayer[id][HUD_BLUE]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wPolozenie \yOs X: \r%i%%", gPlayer[id][HUD_POSX]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wPolozenie \yOs Y: \r%i%%^n", gPlayer[id][HUD_POSY]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\yDomyslne \rUstawienia");
	menu_additem(menu, szMenu);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz", 0);
	
	menu_display(id, menu);
}

public hud_menu_handle(id, menu, item) 
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
			if(++gPlayer[id][HUD] > TYPE_STATUSTEXT) gPlayer[id][HUD] = TYPE_HUD;
	
			if(gPlayer[id][HUD] != TYPE_STATUSTEXT)
			{
				message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
				write_byte(0);
				write_short(0);
				message_end();
			}
		}
		case 1: if((gPlayer[id][HUD_RED] += 15) > 255) gPlayer[id][HUD_RED] = 0;
		case 2: if((gPlayer[id][HUD_GREEN] += 15) > 255) gPlayer[id][HUD_GREEN] = 0;
		case 3: if((gPlayer[id][HUD_BLUE] += 15) > 255) gPlayer[id][HUD_BLUE] = 0;
		case 4: if((gPlayer[id][HUD_POSX] += 3) > 100) gPlayer[id][HUD_POSX] = 0;
		case 5: if((gPlayer[id][HUD_POSY] += 3) > 100) gPlayer[id][HUD_POSY] = 0;
		case 6:
		{
			gPlayer[id][HUD] = TYPE_HUD;
			gPlayer[id][HUD_RED] = 255;
			gPlayer[id][HUD_GREEN] = 128;
			gPlayer[id][HUD_BLUE] = 0;
			gPlayer[id][HUD_POSX] = 66;
			gPlayer[id][HUD_POSY] = 6;
		}
	}
	
	hud_menu(id);
	
	save_stats(id, NORMAL);
	
	return PLUGIN_CONTINUE;
}

public cmd_addbadge(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4)) return PLUGIN_HANDLED;

	new sPlayer[32], sBadge[4], sLevel[4];

	read_argv(1, sPlayer, charsmax(sPlayer));
	read_argv(2, sBadge, charsmax(sBadge));
	read_argv(3, sLevel, charsmax(sLevel));

	new iBadge = str_to_num(sBadge) - 1, iLevel = str_to_num(sLevel), player = cmd_target(id, sPlayer, 0);
	
	if (!player)
	{
		console_print(id, "[BF1] Nie znaleziono podanego gracza!", sPlayer);
		
		return PLUGIN_HANDLED;
	}
	
	if ((iBadge > 9) || (iBadge < 0))
	{
		console_print(id, "[BF1] Podales bledny numer odznaki!");
		
		return PLUGIN_HANDLED;
	}
	
	if ((iLevel > 3) || (iLevel < 0))
	{
		console_print(id, "[BF2] Podales bledny poziom odznaki!");
		
		return PLUGIN_HANDLED;
	}
	
	gPlayer[player][BADGES][iBadge] = iLevel;
	
	save_stats(player, NORMAL);

	new sAdmin[32];
	
	get_user_name(id, sAdmin, charsmax(sAdmin));
	get_user_name(player, sPlayer, charsmax(sPlayer));

	#if AMXX_VERSION_NUM < 183
	ColorChat(player, GREEN, "^x04[BF1]^x01 Otrzymales odznake:^x03 %s^x01.", gBadgeName[iBadge][iLevel]);
	ColorChat(id, GREEN, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", gBadgeName[iBadge][iLevel], sPlayer);
	#else
	client_print_color(player, player, "^x04[BF1]^x01 Otrzymales odznake:^x03 %s^x01.", gBadgeName[iBadge][iLevel]);
	client_print_color(id, id, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", gBadgeName[iBadge][iLevel], sPlayer);
	#endif
	
	log_to_file(LOG_FILE, "[BF1-ADMIN] %s przyznal odznake %s graczowi %s.", sAdmin, gBadgeName[iBadge][iLevel], sPlayer);

	return PLUGIN_HANDLED;
}

public cmd_addbadge_sql(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4)) return PLUGIN_HANDLED;

	new sPlayer[32], sBadge[4], sLevel[4];

	read_argv(1, sPlayer, charsmax(sPlayer));
	read_argv(2, sBadge, charsmax(sBadge));
	read_argv(3, sLevel, charsmax(sLevel));

	new iBadge = str_to_num(sBadge) - 1, iLevel = str_to_num(sLevel);
	
	if ((iBadge > 9) || (iBadge < 0))
	{
		console_print(id, "[BF1] Podales bledny numer odznaki!");
		
		return PLUGIN_HANDLED;
	}
	
	if ((iLevel > 3) || (iLevel < 0))
	{
		console_print(id, "[BF2] Podales bledny poziom odznaki!");
		
		return PLUGIN_HANDLED;
	}

	new sTemp[512], sPlayerSafe[32], sAdmin[32], sData[1];
	
	sData[0] = id;
	
	mysql_escape_string(sPlayer, sPlayerSafe, charsmax(sPlayerSafe));
	
	formatex(sTemp, charsmax(sTemp), "UPDATE bf1 SET badge%i = %i WHERE playerid=^"%s^"", iBadge + 1, iLevel, sPlayerSafe);
	
	SQL_ThreadQuery(hSqlHook, "cmd_addbadge_sql_handle", sTemp, sData, 1);
	
	get_user_name(id, sAdmin, charsmax(sAdmin));

	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", gBadgeName[iBadge][iLevel], sPlayer);
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", gBadgeName[iBadge][iLevel], sPlayer);
	#endif
	
	log_to_file(LOG_FILE, "[BF1-ADMIN] %s przyznal odznake %s graczowi %s.", sAdmin, gBadgeName[iBadge][iLevel], sPlayer);

	return PLUGIN_HANDLED;
}

public cmd_addbadge_sql_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if(iFailState)
	{
		log_to_file(LOG_FILE, "SQL Error: %s (%d)", sError, iError);
		
		return PLUGIN_CONTINUE;
	}
	
	SQL_FreeHandle(hQuery);
	
	return PLUGIN_CONTINUE;
}

public check_time(id)
{
	id -= TASK_TIME;
	
	if(!Get(id, iVisit)) return PLUGIN_CONTINUE;
	
	if (!Get(id, iLoaded))
	{ 
		set_task(3.0, "check_time", id + TASK_TIME);
		
		return PLUGIN_CONTINUE;
	}
	
	new iTime = get_systime(), iYear, iMonth, Month, iDay, Day, iHour, iMinute, iSecond;

	UnixToTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
	
	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Aktualnie jest godzina^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Aktualnie jest godzina^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", iHour, iMinute, iSecond, iDay, iMonth, iYear);
	#endif
	
	if (gPlayer[id][FIRST_VISIT] == gPlayer[id][LAST_VISIT])
	{
		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[BF1]^x01 To twoja^x03 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!");
		#else
		client_print_color(id, id, "^x04[BF1]^x01 To twoja^x03 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!");
		#endif
	}
	else 
	{
		UnixToTime(gPlayer[id][LAST_VISIT], iYear, Month, Day, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		if (iMonth == Month && iDay == Day)
		{
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 dzisiaj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 dzisiaj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
			#endif
		}
		else if (iMonth == Month && iDay - 1 == Day) 
		{
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 wczoraj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 wczoraj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", iHour, iMinute, iSecond);
			#endif
		}
		else 
		{
			#if AMXX_VERSION_NUM < 183
			ColorChat(id, GREEN, "^x04[BF1]^x01 Twoja ostatnia wizyta:^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, iYear);
			#else
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta:^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", iHour, iMinute, iSecond, Day, Month, iYear);
			#endif
		}
	}
	
	Rem(id, iVisit);
	
	return PLUGIN_CONTINUE;
}

public cmd_time(id)
{
	new sTemp[512], sData[1];
	
	sData[0] = id;

	format(sTemp,charsmax(sTemp), "SELECT COUNT(*) AS rank FROM bf1 WHERE time >= (SELECT time FROM bf1 WHERE name = ^"%s^")", gPlayer[id][SAFE_NAME]);
	
	SQL_ThreadQuery(hSqlHook, "cmd_time_handle", sTemp, sData, 1);
}

public cmd_time_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Time - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Time - Query failed. [%d] %s", iError, sError);

		return PLUGIN_CONTINUE;
	}
	
	new id = sData[0], iRank = SQL_ReadResult(hQuery, 0), iSeconds = (gPlayer[id][TIME] + get_user_time(id)), iMinutes, iHours;
	
	while(iSeconds >= 60)
	{
		iSeconds -= 60;
		iMinutes++;
		
		if (iMinutes >= 60)
		{
			iMinutes -= 60;
			iHours++;
		}
	}
	
	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04[BF1]^x01 Twoj czas gry wynosi^x03 %i h %i min %i s^x01. Zajmujesz^x03 %i^x01 miejsce w rankingu.", iHours, iMinutes, iSeconds, iRank);
	#else
	client_print_color(id, id, "^x04[BF1]^x01 Twoj czas gry wynosi^x03 %i h %i min %i s^x01. Zajmujesz^x03 %i^x01 miejsce w rankingu.", iHours, iMinutes, iSeconds, iRank);
	#endif
	
	return PLUGIN_CONTINUE;
}

public cmd_degrees(id)
{
	new sMotd[1024], sTemp[256];
	
	formatex(sMotd, charsmax(sMotd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FF0000^"><strong><center>Lista Stopni:</font><br><font size=^"1^" face=^"verdana^" color=^"FFFFFF^">");
	
	for(new i; i < sizeof(gDegrees); i++)
	{
		formatex(sTemp, charsmax(sTemp), "%s <br>", gDegrees[i][DESC]);
		add(sMotd, charsmax(sMotd), sTemp);
	}

	add(sMotd,charsmax(sMotd), "</font></center></body></html>");
	
	show_motd(id, sMotd, "Lista Stopni");
	
	return PLUGIN_CONTINUE;
}

public cmd_timetop(id)
{
	new sTemp[512], sData[1];

	sData[0] = id;
	
	format(sTemp, charsmax(sTemp), "SELECT name, time FROM bf1 ORDER BY time DESC LIMIT 15");
	
	SQL_ThreadQuery(hSqlHook, "cmd_timetop_handle", sTemp, sData, 1);
}

public cmd_timetop_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "TimeTop - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "TimeTop - Query failed. [%d] %s", iError, sError);

		return PLUGIN_CONTINUE;
	}
	
	new sBuffer[2048], sName[33], id = sData[0], iLen = 0, iPlace = 0;

	iLen = format(sBuffer, charsmax(sBuffer), "<body bgcolor=#000000><font color=#FFB000><pre>")
	iLen += format(sBuffer[iLen], charsmax(sBuffer) - iLen, "%8s %24s %15s^n", "Rank", "Nick", "Czas")
	
	while(SQL_MoreResults(hQuery))
	{
		new iSeconds = SQL_ReadResult(hQuery, 1), iMinutes = 0, iHours = 0;
		SQL_ReadResult(hQuery, 0, sName, charsmax(sName));
		
		replace_all(sName, charsmax(sName), "<", "");
		replace_all(sName, charsmax(sName), ">", "");
		
		while(iSeconds >= 60)
		{
			iSeconds -= 60;
			iMinutes++;
		
			if (iMinutes >= 60)
			{
				iMinutes -= 60;
				iHours++;
			}
		}
		
		iPlace++;
		
		iLen += format(sBuffer[iLen], charsmax(sBuffer) - iLen, "#%1i%s %-22.22s %3ih %3imin %3is^n", iPlace, iPlace >= 10 ? "" : " ", sName, iHours, iMinutes, iSeconds);
		
		SQL_NextRow(hQuery);
	}
	
	show_motd(id, sBuffer, "Top15 Czasu Gry");
	
	return PLUGIN_CONTINUE;
}

public menu_bf1(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rMenu Glowne", "menu_handler");

	menu_additem(menu, "\wMenu \yPomocy", "0", 0);
	menu_additem(menu, "\wMenu \yStatystyk", "1", 0);
	menu_additem(menu, "\wMenu \yCzasu", "2", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	gPlayer[id][MENU] = MENU_MAIN;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_help(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;
    
	new menu = menu_create("\yBF1: \rMenu Pomocy", "menu_handler");
 
	menu_additem(menu, "\wOpis \yModa BF1", "0", 0);
	menu_additem(menu, "\wOpis \yOdznak", "1", 0);
	menu_additem(menu, "\wOpis \yRang", "2", 0);
	menu_additem(menu, "\wOpis \yOrderow^n", "3", 0);
	menu_additem(menu, "\wZmien \yHUD^n", "4", 0);
	menu_additem(menu, "\wWstecz", "5", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	gPlayer[id][MENU] = MENU_HELP;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_stats(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;
    
	new menu = menu_create("\yBF1: \rMenu Statystyk", "menu_handler");
 
	menu_additem(menu, "\wPokaz\y Liste Graczy", "0", 0);
	menu_additem(menu, "\wPokaz\y Moje Odznaki i Ordery", "1", 0);
	menu_additem(menu, "\wPokaz\y Moje Statystyki", "2", 0);
	menu_additem(menu, "\wPokaz\y Odznaki i Ordery Gracza", "3", 0);
	menu_additem(menu, "\wPokaz\y Statystyki Gracza", "4", 0);
	menu_additem(menu, "\wPokaz\y Statystyki Serwera^n", "5", 0);
	menu_additem(menu, "\wWstecz", "6", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	gPlayer[id][MENU] = MENU_STATS;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_time(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;
	
	new menu = menu_create("\yBF1: \rMenu Czasu", "menu_handler");
 
	menu_additem(menu, "\wPokaz \yMoj Czas", "0", 0);
	menu_additem(menu, "\wPokaz \yListe Stopni", "1", 0);
	menu_additem(menu, "\wPokaz \yTop15 Czasu^n", "2", 0);
	menu_additem(menu, "\wWstecz", "3", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	gPlayer[id][MENU] = MENU_TIME;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_badges(id)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;

  	new menu = menu_create("\yBF1: \rInformacje o Odznakach\w", "menu_handler");

	menu_additem(menu, "\wWalka \yNozem", "0", 0);
	menu_additem(menu, "\wWalka \yPistoletem", "1", 0);
	menu_additem(menu, "\wWalka \yBronia Szturmowa", "2", 0);
	menu_additem(menu, "\wWalka \yBronia Snajperska", "3", 0);
	menu_additem(menu, "\wWalka \yBronia Wsparcia", "4", 0);
	menu_additem(menu, "\wWalka \yBronia Wybuchowa", "5", 0);
	menu_additem(menu, "\wWalka \yShotgunem", "6", 0);
	menu_additem(menu, "\wWalka \ySMG", "7", 0);
	menu_additem(menu, "\wWalka \yCzasowa", "8", 0);
	menu_additem(menu, "\wWalka \yOgolna^n", "9", 0);
	menu_additem(menu, "\wWstecz", "10", 0);
  
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_BACKNAME, "Wstecz");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
  
	gPlayer[id][MENU] = MENU_BADGES;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_playerlist(id, type)
{
	if (!get_pcvar_num(pCvarBF1Active)) return PLUGIN_CONTINUE;
    
	new menu = menu_create("\yBF1: \rWybierz Gracza", "menu_handler");
 
	new sName[33], sID[3], iPlayers[32], iNum, player;
	
	get_players(iPlayers, iNum, "h");
	
	for (new i = 0; i < iNum; i++)
	{
		player = iPlayers[i];
		
		if(is_user_hltv(player) || is_user_bot(player)) continue;
		
		get_user_name(player, sName, charsmax(sName));
		
		formatex(sID, charsmax(sID), "%i", player);
		
		menu_additem(menu, sName, sID, 0);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu,MPROP_EXITNAME, "Wyjscie");

	gPlayer[id][MENU] = type ? MENU_PLAYERBADGES : MENU_PLAYERSTATS;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	else if (item == MENU_BACK)
	{
		menu_display(id, menu, 0);
		
		return PLUGIN_HANDLED;	
	}
	
	new sData[6], iAccess, iCallback;

	menu_item_getinfo(menu, item, iAccess, sData, charsmax(sData), _, _, iCallback);

	if (!(get_user_flags(id) & iAccess) && iAccess) return PLUGIN_HANDLED;

	new iKey = str_to_num(sData);

	switch (gPlayer[id][MENU])
	{
		case MENU_MAIN:
		{
			switch (iKey)
			{
				case 0: menu_help(id);
				case 1:	menu_stats(id);
				case 2:	menu_time(id);
				case 3:	menu_bf1(id);
			}
		}
		case MENU_HELP:
		{
			menu_help(id);
			
			switch (iKey)
			{
				case 0: cmd_help(id);
				case 1:	menu_badges(id);
				case 2:	cmd_rankhelp(id);
				case 3:	cmd_orders(id);
				case 4:	hud_menu(id);
				case 5: menu_bf1(id);
			}
		}
		case MENU_STATS:
		{
			menu_stats(id);
			
			switch (iKey)
			{
				case 0: cmd_ranks(id);
				case 1:	cmd_badges(id, id);
				case 2: cmd_mystats(id);
				case 3: menu_playerlist(id, 1);
				case 4: menu_playerlist(id, 0);
				case 5: cmd_serverstats(id);
				case 6: menu_bf1(id);
			}
		}
		case MENU_TIME:
		{
			menu_time(id);
			
			switch (iKey)
			{
				case 0:	cmd_time(id);
				case 1: cmd_degrees(id);
				case 2: cmd_timetop(id);
				case 3: menu_bf1(id);
			}
		}
		case MENU_BADGES:
		{
			menu_badges(id);
			
			switch (iKey)
			{
				case 0 .. 9: cmd_badgehelp(id, iKey + 1);
				case 10: menu_bf1(id);
			}
		}
		case MENU_PLAYERBADGES: 
		{
			menu_stats(id);
			
			if(is_user_connected(iKey)) cmd_badges(id, iKey);
		}
		case MENU_PLAYERSTATS:
		{
			menu_stats(id);
			
			if(is_user_connected(iKey)) cmd_stats(id, iKey);
		}
	}
	
   	menu_destroy(menu);
    
	return PLUGIN_HANDLED;
}

public sql_init()
{
	new sCache[2048], sHost[32], sUser[32], sPass[32], sDB[32];
	
	get_pcvar_string(pCvarDBHost, sHost, charsmax(sHost));
	get_pcvar_string(pCvarDBUser, sUser, charsmax(sUser));
	get_pcvar_string(pCvarDBPass, sPass, charsmax(sPass));
	get_pcvar_string(pCvarDBBase, sDB, charsmax(sDB));
	
	hSqlHook = SQL_MakeDbTuple(sHost, sUser, sPass, sDB);
	
	formatex(sCache, charsmax(sCache), "CREATE TABLE IF NOT EXISTS bf1_server (server VARCHAR(11), rank INT(11), kills INT(11), wins INT(11), rankname VARCHAR(33), killsname VARCHAR(33), winsname VARCHAR(33), PRIMARY KEY (server))");
	
	SQL_ThreadQuery(hSqlHook, "table_handle", sCache);

	formatex(sCache, charsmax(sCache), "CREATE TABLE IF NOT EXISTS bf1 (name VARCHAR(33), badge1 INT(4), badge2 INT(4), badge3 INT(4), badge4 INT(4), badge5 INT(4), badge6 INT(4), badge7 INT(4), badge8 INT(4), badge9 INT(4), badge10 INT(4), order1 INT(4), order2 INT(4), order3 INT(4), order4 INT(4), order5 INT(4), order6 INT(4), ");
	add(sCache, charsmax(sCache), "order7 INT(4), order8 INT(4), order9 INT(4), order10 INT(4), kills INT(11), hskills INT(11), assists INT(11), gold INT(6), silver INT(6), bronze INT(6), hud INT(4), red INT(4), green INT(4), blue INT(4), posx INT(4), posy INT(4), degree INT(4), admin INT(4), time INT(11) NOT NULL, visits INT(9), ");
	add(sCache, charsmax(sCache), "firstvisit INT(11), lastvisit INT(11), knife INT(9), pistol INT(9), glock INT(9), usp INT(9), p228 INT(9), deagle INT(9), fiveseven INT(9), elites INT(9), sniper INT(9), scout INT(9), awp INT(9), g3sg1 INT(9), sg550 INT(9), rifle INT(9), ak47 INT(9), m4a1 INT(9), galil INT(9), famas INT(9), sg552 INT(9), ");
	add(sCache, charsmax(sCache), "aug INT(9), m249 INT(9), smg INT(9), mac10 INT(9), tmp INT(9), mp5 INT(9), ump45 INT(9), p90 INT(9), grenade INT(9), shotgun INT(9), m3 INT(9), xm1014 INT(9), plants INT(9), explosions INT(9), defuses INT(9), rescues INT(9), survived INT(9), dmgtaken INT(9), dmgreceived INT(9), earned INT(11), PRIMARY KEY (name))");
	
	SQL_ThreadQuery(hSqlHook, "table_handle", sCache);
}

public load_stats(id)
{
	new sCache[128], sData[1];
	
	sData[0] = id;

	formatex(sCache, charsmax(sCache), "SELECT * FROM bf1 WHERE name = ^"%s^"", gPlayer[id][SAFE_NAME]);
	
	SQL_ThreadQuery(hSqlHook, "load_stats_handle", sCache, sData, 1);
}

public load_server()
	SQL_ThreadQuery(hSqlHook, "load_server_handle", "SELECT * FROM bf1_server WHERE server = 'Server'");

public save_stats(id, end)
{
	if (!Get(id, iLoaded) || !bSQL) return PLUGIN_CONTINUE;

	new sCache[2048], sTemp[512];

	formatex(sCache, charsmax(sCache), "UPDATE bf1 SET badge1 = %i, badge2 = %i, badge3 = %i, badge4 = %i, badge5 = %i, badge6 = %i, badge7 = %i, badge8 = %i, badge9 = %i, badge10 = %i, ",
	gPlayer[id][BADGES][BADGE_KNIFE], gPlayer[id][BADGES][BADGE_PISTOL], gPlayer[id][BADGES][BADGE_ASSAULT], gPlayer[id][BADGES][BADGE_SNIPER], gPlayer[id][BADGES][BADGE_SUPPORT], gPlayer[id][BADGES][BADGE_EXPLOSIVES], gPlayer[id][BADGES][BADGE_SHOTGUN], gPlayer[id][BADGES][BADGE_SMG], gPlayer[id][BADGES][BADGE_GENERAL], gPlayer[id][BADGES][BADGE_TIME]);
 
	formatex(sTemp, charsmax(sTemp), "order1 = %i, order2 = %i, order3 = %i, order4 = %i, order5 = %i, order6 = %i, order7 = %i, order8 = %i, order9 = %i, order10 = %i, ",
	gPlayer[id][ORDERS][ORDER_AIMBOT], gPlayer[id][ORDERS][ORDER_ANGEL], gPlayer[id][ORDERS][ORDER_BOMBERMAN], gPlayer[id][ORDERS][ORDER_SAPER], gPlayer[id][ORDERS][ORDER_PERSIST], gPlayer[id][ORDERS][ORDER_DESERV], gPlayer[id][ORDERS][ORDER_MILION], gPlayer[id][ORDERS][ORDER_BULLET], gPlayer[id][ORDERS][ORDER_RAMBO], gPlayer[id][ORDERS][ORDER_SURVIVER]);
	add(sCache, charsmax(sCache), sTemp);

	formatex(sTemp, charsmax(sTemp), "kills = %i, hskills = %i, assists = %i, gold = %i, silver = %i, bronze = %i, hud = %i, red = %i, green = %i, blue = %i, posx = %i, posy = %i, degree = %i, admin = %i, time = %i, visits = %i, lastvisit = %i, knife = %i, pistol = %i, glock = %i, ", 
	gPlayer[id][KILLS], gPlayer[id][HS_KILLS], gPlayer[id][ASSISTS], gPlayer[id][GOLD], gPlayer[id][SILVER], gPlayer[id][BRONZE], gPlayer[id][HUD], gPlayer[id][HUD_RED], gPlayer[id][HUD_GREEN], gPlayer[id][HUD_BLUE], gPlayer[id][HUD_POSX], gPlayer[id][HUD_POSY], gPlayer[id][DEGREE], gPlayer[id][ADMIN], gPlayer[id][TIME] + get_user_time(id), gPlayer[id][VISITS], get_systime(), gPlayer[id][KNIFE], gPlayer[id][PISTOL], gPlayer[id][GLOCK]);
	add(sCache, charsmax(sCache), sTemp);

	formatex(sTemp, charsmax(sTemp), "usp = %i, p228 = %i, deagle = %i, fiveseven = %i, elites = %i, sniper = %i, scout = %i, awp = %i, g3sg1 = %i, sg550 = %i, rifle = %i, ak47 = %i, m4a1 = %i, galil = %i, famas = %i, sg552 = %i, aug = %i, m249 = %i, smg = %i, mac10 = %i,", 
	gPlayer[id][USP], gPlayer[id][P228], gPlayer[id][DEAGLE], gPlayer[id][FIVESEVEN], gPlayer[id][ELITES], gPlayer[id][SNIPER], gPlayer[id][SCOUT], gPlayer[id][AWP], gPlayer[id][G3SG1], gPlayer[id][SG550], gPlayer[id][RIFLE], gPlayer[id][AK47], gPlayer[id][M4A1], gPlayer[id][GALIL], gPlayer[id][FAMAS], gPlayer[id][SG552], gPlayer[id][AUG], gPlayer[id][M249], gPlayer[id][SMG], gPlayer[id][MAC10]);
	add(sCache, charsmax(sCache), sTemp);

	formatex(sTemp, charsmax(sTemp), "tmp = %i, mp5 = %i, ump45 = %i, p90 = %i, grenade = %i, shotgun = %i, m3 = %i, xm1014 = %i, plants = %i, explosions = %i, defuses = %i, rescues = %i, survived = %i, dmgtaken = %i, dmgreceived = %i, earned = %i WHERE name = ^"%s^"", 
	gPlayer[id][TMP], gPlayer[id][MP5], gPlayer[id][UMP45], gPlayer[id][P90], gPlayer[id][GRENADE], gPlayer[id][SHOTGUN], gPlayer[id][M3], gPlayer[id][XM1014], gPlayer[id][PLANTS], gPlayer[id][EXPLOSIONS], gPlayer[id][DEFUSES], gPlayer[id][RESCUES], gPlayer[id][SURVIVED], gPlayer[id][DMG_TAKEN], gPlayer[id][DMG_RECEIVED], gPlayer[id][EARNED], gPlayer[id][SAFE_NAME]);
	add(sCache, charsmax(sCache), sTemp);

	switch(end)
	{
		case NORMAL, DISCONNECT: SQL_ThreadQuery(hSqlHook, "query_handle", sCache);
		case MAP_END: query_nonthreaded_handle(sCache);
	}
	
	if(end) Rem(id, iLoaded);
	
	return PLUGIN_CONTINUE;
}

public save_server()
{
	if(!bSQL || !bServer) return PLUGIN_CONTINUE;
	
	mysql_escape_string(gServer[HIGHESTSERVERRANKNAME], gServer[HIGHESTSERVERRANKNAME], charsmax(gServer[HIGHESTSERVERRANKNAME]));
	mysql_escape_string(gServer[MOSTSERVERKILLSNAME], gServer[MOSTSERVERKILLSNAME], charsmax(gServer[MOSTSERVERKILLSNAME]));
	mysql_escape_string(gServer[MOSTSERVERWINSNAME], gServer[MOSTSERVERWINSNAME], charsmax(gServer[MOSTSERVERWINSNAME]));
	
	new sCache[512];
	
	formatex(sCache, charsmax(sCache), "UPDATE bf1_server SET rank = %i, rankname = '%s', kills = %i, killsname = '%s', wins = %i, winsname = '%s' WHERE server = 'Server'",
	gServer[HIGHESTSERVERRANK], gServer[HIGHESTSERVERRANKNAME], gServer[MOSTSERVERKILLS], gServer[MOSTSERVERKILLSNAME], gServer[MOSTSERVERWINS], gServer[MOSTSERVERWINSNAME]);
	
	query_nonthreaded_handle(sCache);
	
	return PLUGIN_CONTINUE;
}

public load_stats_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Load Server - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Load Server - Query failed. [%d] %s", iError, sError);

		return PLUGIN_CONTINUE;
	}

	new id = sData[0];

	if (!SQL_NumResults(hQuery))
	{
		new sCache[256];

		formatex(sCache, charsmax(sCache), "INSERT IGNORE INTO bf1 (name, firstvisit) VALUES('%s', '%i')", gPlayer[id][SAFE_NAME], get_systime());
		
		SQL_ThreadQuery(hSqlHook, "query_handle", sCache);
	}
	else
	{
		for (new i = 0; i < MAX_BADGES; i++) gPlayer[id][BADGES][i] = SQL_ReadResult(hQuery, i + 1);
		
		for (new i = 0; i < MAX_ORDERS; i++) gPlayer[id][ORDERS][i] = SQL_ReadResult(hQuery, i + MAX_BADGES + 1);
		
		for (new i = 0; i <= EARNED; i++) gPlayer[id][i] = SQL_ReadResult(hQuery, i + MAX_BADGES + MAX_ORDERS + 1);
		
		gPlayer[id][ADMIN] = (get_user_flags(id) & ADMIN_BAN) ? 1 : 0;
		
		gPlayer[id][VISITS]++;
	}
	
	Set(id, iLoaded);
	
	return PLUGIN_CONTINUE;
}

public load_server_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Load Server - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Load Server - Query failed. [%d] %s", iError, sError);

		return PLUGIN_CONTINUE;
	}

	if (!SQL_NumResults(hQuery))
	{
		for(new i = 0; i < HIGHESTSERVERRANKNAME; i++) gServer[i] = 0;
		
		formatex(gServer[HIGHESTSERVERRANKNAME], charsmax(gServer[HIGHESTSERVERRANKNAME]), "Brak");
		formatex(gServer[MOSTSERVERKILLSNAME], charsmax(gServer[MOSTSERVERKILLSNAME]), "Brak");
		formatex(gServer[MOSTWINSNAME], charsmax(gServer[MOSTWINSNAME]), "Brak");

		SQL_ThreadQuery(hSqlHook, "query_handle", "INSERT IGNORE INTO bf1_server VALUES('Server', '0', '0', '0', 'Brak', 'Brak', 'Brak')");
	}
	else
	{
		for(new i = 0; i < HIGHESTSERVERRANKNAME; i++) gServer[i] = SQL_ReadResult(hQuery, i + 1);
		
		SQL_ReadResult(hQuery, 4, gServer[HIGHESTSERVERRANKNAME], charsmax(gServer[HIGHESTSERVERRANKNAME]));
		SQL_ReadResult(hQuery, 5, gServer[MOSTSERVERKILLSNAME], charsmax(gServer[MOSTSERVERKILLSNAME]));
		SQL_ReadResult(hQuery, 6, gServer[MOSTSERVERWINSNAME], charsmax(gServer[MOSTSERVERWINSNAME]));
	}
	
	bServer = true;
	
	return PLUGIN_CONTINUE;
}

public table_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Create - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Create - Query failed. [%d] %s", iError, sError);
		
		bSQL = false;

		return PLUGIN_CONTINUE;
	}
	
	if (bSQL) load_server();

	bSQL = true;
	
	return PLUGIN_CONTINUE;
}

public query_handle(iFailState, Handle:hQuery, sError[], iError, sData[], iDataSize)
{
	if (iFailState) 
	{
		if(iFailState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Save - Could not connect to SQL database.  [%d] %s", iError, sError);
		else if (iFailState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Save - Query failed. [%d] %s", iError, sError);
	}
	
	return PLUGIN_CONTINUE;
}

public query_nonthreaded_handle(sCache[])
{
	new sError[128], iError, Handle:hSqlConnection, Handle:hQuery;

	hSqlConnection = SQL_Connect(hSqlHook, iError, sError, charsmax(sError));

	if(!hSqlConnection)
	{
		log_to_file(LOG_FILE, "Save Nonthreaded - Could not connect to SQL database.  [%d] %s", iError, sError);

		SQL_FreeHandle(hSqlConnection);

		return PLUGIN_CONTINUE;
	}
	
	hQuery = SQL_PrepareQuery(hSqlConnection, sCache);
	
	if(!SQL_Execute(hQuery))
	{
		iError = SQL_QueryError(hQuery, sError, charsmax(sError));

		log_to_file(LOG_FILE, "Save Nonthreaded failed. [%d] %s", iError, sError);

		SQL_FreeHandle(hQuery);
		SQL_FreeHandle(hSqlConnection);

		return PLUGIN_CONTINUE;
	}

	SQL_FreeHandle(hQuery);
	SQL_FreeHandle(hSqlConnection);
	
	return PLUGIN_CONTINUE;
}

public player_glow(id, iRed, iGreen, iBlue)
{
	fm_set_rendering(id, kRenderFxGlowShell, iRed, iGreen, iBlue, kRenderNormal, 16);
	
	set_task(1.0, "player_noglow", id + TASK_GLOW);
}

public player_noglow(id)
{
	id -= TASK_GLOW;
	
	if (!is_user_connected(id)) return;

	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 16);
	
	if(get_user_weapon(id) == CSW_KNIFE) set_render(id);
}

stock Create_TE_PLAYERATTACHMENT(id, iEntity, iOffset, iSprite, iLife)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(iEntity);
	write_coord(iOffset);
	write_short(iSprite);
	write_short(iLife);
	message_end();
}

public screen_flash(id, iRed, iGreen, iBlue, iAlpha)
{
	static gmsgScreenFade;
	
	if(!gmsgScreenFade) gmsgScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id);
	write_short(1<<12);
	write_short(1<<12);
	write_short(1<<12);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock cmd_execute(id, const szText[], any:...) 
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szText) + 2);
	write_byte(10);
	write_string(szText);
	message_end();
	
	#pragma unused szText

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}

stock mysql_escape_string(const szSource[], szDest[], iLen)
{
	copy(szDest, iLen, szSource);
	
	replace_all(szDest, iLen, "\\", "\\\\");
	replace_all(szDest, iLen, "\", "\\");
	replace_all(szDest, iLen, "\0", "\\0");
	replace_all(szDest, iLen, "\n", "\\n");
	replace_all(szDest, iLen, "\r", "\\r");
	replace_all(szDest, iLen, "\x1a", "\Z");
	replace_all(szDest, iLen, "'", "\'");
	replace_all(szDest, iLen, "`", "\`");
	replace_all(szDest, iLen, "^"", "\^"");
}

stock ham_strip_weapon(id, sWeapon[])
{
	if (!equal(sWeapon, "weapon_", 7)) return 0;
	
	new iEnt, iWeapon = get_weaponid(sWeapon);
	
	if (!iWeapon) return 0;
	
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", sWeapon)) && pev(iEnt, pev_owner) != id) {}
	
	if (!iEnt) return 0;
	
	if (get_user_weapon(id) == iWeapon) ExecuteHamB(Ham_Weapon_RetireWeapon, iEnt);
	
	if (!ExecuteHamB(Ham_RemovePlayerItem, id, iEnt)) return 0;
	
	ExecuteHamB(Ham_Item_Kill, iEnt);
	
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<iWeapon));
	
	return 1;
}

stock bool:check_weapons(id) 
{
	new sWeapon[32], iNum, iWeapon, sDisallowed[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,CSW_AK47, 
	CSW_M4A1, CSW_AWP, CSW_SG550, CSW_G3SG1, CSW_UMP45,CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };
	
	iWeapon = get_user_weapons(id, sWeapon, iNum);
	
	for(new i = 0; i < sizeof(sDisallowed); i++)
		if (iWeapon & (1<<sDisallowed[i])) return true;

	return false;
}

stock check_map() 
{
	new const sPackageMap[][] = 
	{ 
		"awp_", 
		"awp4one", 
		"35hp_2" 
	};
	
	new const sSmallMap[][] = 
	{ 
		"fy_", 
		"aim_", 
		"mini_",
		"_mini",
		"_long",
		"2x2"
	};
	
	new sMapName[32];
	
	get_mapname(sMapName, charsmax(sMapName));
	
	for(new i = 0; i < sizeof(sPackageMap); i++) if (containi(sMapName, sPackageMap[i]) != -1) { bPackages = true; break; }

	for(new i = 0; i < sizeof(sSmallMap); i++) if (containi(sMapName, sSmallMap[i]) != -1) { server_cmd("amx_cvar bf1_badgepowers 0"); break; }
}

Ham:get_player_resetmaxspeed_func()
{
    #if defined Ham_CS_Player_ResetMaxSpeed
	return IsHamValid(Ham_CS_Player_ResetMaxSpeed) ? Ham_CS_Player_ResetMaxSpeed : Ham_Item_PreFrame;
    #else
	return Ham_Item_PreFrame;
    #endif
}