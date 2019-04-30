#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <engine> 

#define PLUGIN "JailBreak: Jail Mod Core"
#define VERSION "1.0.11"
#define AUTHOR "Cypis & O'Zone"

#pragma dynamic 65536

#define TASK_CHECK 9543
#define TASK_END 7854

//#define DEBUG

#define SUNDAY_GAMES

#define MAX 32

#define WSZYSCY 0
#define ZYWI 1

#define strip_user_weapons2(%0) strip_user_weapons(%0), set_pdata_int(%0, 116, 0)

native cs_set_player_model(id, newmodel[]);

enum
{
	ID_DZWIEK_POSZ = 7000,
	ID_LOS_PROWADZACY,
	ID_CZAS,
	ID_FREZZ,
	ID_SPEED_FZ,
	ID_HUD
}

enum
{
	MIKRO = 0,
	WALKA,
	FF_TT,
	TT_GOD,
	CT_GOD,
	CT_NIE_MOZE_TT,
	TT_NIE_MOZE_CT
}

enum
{
	V_PALKA = 0,
	P_PALKA,
	V_PIESCI,
	P_PIESCI,
	V_REKAWICE,
	P_REKAWICE
}

new static szReasons[][] = 
{
    "Sranie w sklepie",
    "Krzywy ryj",
    "Bluzganie na papieza",
    "Bycie rudym",
    "Wciaganie cukru pudru",
    "Seks z oposem",
    "Sikanie na przystanku",
    "Publiczna masturbacje",
    "Kradziez cukierka",
    "Uprowadzenie listonosza",
    "Zgwalcenie babci",
	"Jedynke z matmy"
}

#if defined SUNDAY_GAMES
new bool:bSunday, iVotes[32];
#endif

new const iMaxAmmo[31] = {0,52,0,90,1,31,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,31,90,120,90,2,35,90,90,0,100};
new const szColor[][] = { "Brak", "Czerwoni", "Niebiescy" };
new const szColors[][3] = { {0, 0, 0}, {255, 0, 0}, {0, 0, 255} };
new const szWeekDays[][] = {"Niedziela", "Poniedzialek", "Wtorek", "Sroda", "Czwartek", "Piatek", "Sobota"};

new Float:fPlayerSpeed[MAX + 1], Float:fWaitButton[MAX + 1], bool:bMuted[MAX + 1][MAX + 1], bool:iWeaponsMenu[MAX + 1][2], bool:bPlayerVoted[MAX + 1], bool:bFight[MAX + 1], bool:bFreeday[MAX + 1], bool:bSetFreeday[MAX + 1], 
	bool:bGhost[MAX + 1], bool:bPlayerMode[7], bool:bEraseSettings, bool:bEraseEnd, bool:bShowOnce, bool:bWeaponsTime, bool:bServiceGiven, bool:bGame, bool:bFreezeTime, bool:bGameChosen, bool:bWishChosen, bool:bWishGame;
	
new szWanted[256], szInfo[256], szInfoPosz[256], szHudMessage[64], szMap[32], szNextMap[32], szDayData[11], szButtons[10], szModels[6][128], szHudData[6], szPlayerName[MAX + 1][64], 
	iWeaponsBit[MAX + 1][2], iPlayerWeapons[MAX + 1][2], iLastPosition[MAX + 1][2], iPlayerAFK[MAX + 1], iPlayerTeam[MAX + 1], iTeam[MAX + 1], iReason[MAX + 1], iPlayersCount[2], aPlayers[2][MAX + 1], iTeams[3];

new SyncHudObj1, SyncHudObj2, SyncHudObj3, iJailDay, iAdminVoice, iLeader, iLastPrisoner, iTimeStart, iRoundTime, iFreezeTime, iGameID, iHudCountdown = 0;

new Array:aGameNames, Array:aWishNames, fLastPrisonerWishTaken, fLastPrisonerTakeWish, fRemoveData, fDayStartPre, fDayStartPost, MenuLeader;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
	RegisterHam(Ham_Killed, "player", "PlayerDeath", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "WeaponKnife", 1);
	RegisterHam(Ham_TraceAttack, "func_button", "ButtonTraceAttack");
	RegisterHam(Ham_Touch, "armoury_entity", "TouchWeapon");
	RegisterHam(Ham_Touch, "weapon_shield", "TouchWeapon");
	RegisterHam(Ham_Touch, "weaponbox", "TouchWeapon");
	RegisterHam(Ham_Use, "game_player_equip", "BlockUse");
	RegisterHam(Ham_Use, "player_weaponstrip", "BlockUse");
	RegisterHam(Ham_Use, "func_button", "BlockUse2");
	RegisterHam(Ham_Use, "func_healthcharger", "BlockHeal");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "OnAddToPlayerKnife", 1);
	RegisterHam(get_player_resetmaxspeed_func(), "player", "SpeedChange", true);

	register_forward(FM_EmitSound, "EmitSound");
	register_forward(FM_Voice_SetClientListening, "Voice_SetClientListening");

	register_event("StatusValue", "StatusShow", "be", "1=2", "2!0");
	register_event("StatusValue", "StatusHide", "be", "1=1", "2=0");
	register_event("HLTV", "PreRoundStart", "a", "1=0", "2=0");
	register_event("CurWeapon", "CurWeapon", "be", "1=1");
	
	register_logevent("RoundEnd", 2, "1=Round_End");
	register_logevent("RoundRestart", 2, "0=World triggered", "1=Game_Commencing");
	register_logevent("PostRoundStart", 2, "0=World triggered", "1=Round_Start");

	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET);
	set_msg_block(get_user_msgid("HudTextPro"), BLOCK_SET);
	set_msg_block(get_user_msgid("StatusText"), BLOCK_SET);
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);
	
	register_clcmd("radio1", "BlockCommand");
	register_clcmd("radio2", "BlockCommand");
	register_clcmd("radio3", "BlockCommand");
	register_clcmd("drop", "BlockDrop");
	register_clcmd("weapon_piesci", "ClientCommand_SelectKnife");
	register_clcmd("weapon_palka", "ClientCommand_SelectKnife"); 
	register_clcmd("jail_cele", "MenuSetCellButton");
	register_clcmd("+adminvoice", "AdminVoiceOn");
	register_clcmd("-adminvoice", "AdminVoiceOff");
	register_clcmd("say /oddaj", "GiveLeadership");
	register_clcmd("oddaj", "GiveLeadership");
	register_clcmd("say /obejmij", "TakeLeadership");
	register_clcmd("obejmij", "TakeLeadership");
	register_clcmd("say /obsluga", "MenuWishService");
	register_clcmd("obsluga", "MenuWishService");
	register_clcmd("say /guns", "MenuWeapons");
	register_clcmd("guns", "MenuWeapons");
	register_clcmd("say /zabawy", "MenuGames");
	register_clcmd("zabawy", "MenuGames");
	register_clcmd("say /lr", "MenuWishes");
	register_clcmd("say /zyczenie", "MenuWishes");
	register_clcmd("lr", "MenuWishes");
	register_clcmd("say /mute", "MenuMute");

	register_message(get_user_msgid("TextMsg") ,"msg_TextMsg");
	register_message(get_user_msgid("StatusIcon"), "msg_StatusIcon");
	register_impulse(100, "msg_FlashLight");

	iFreezeTime = get_pcvar_num(get_cvar_pointer("mp_freezetime"));
	iRoundTime = floatround(get_cvar_float("mp_roundtime")*60.0);

	SyncHudObj1 = CreateHudSyncObj();
	SyncHudObj2 = CreateHudSyncObj();
	SyncHudObj3 = CreateHudSyncObj();

	fDayStartPre = CreateMultiForward("OnDayStartPre", ET_CONTINUE, FP_CELL, FP_ARRAY, FP_ARRAY, FP_ARRAY, FP_CELL);
	fDayStartPost = CreateMultiForward("OnDayStartPost", ET_CONTINUE, FP_CELL);
	fLastPrisonerTakeWish = CreateMultiForward("OnLastPrisonerTakeWish", ET_CONTINUE, FP_CELL, FP_CELL);
	fLastPrisonerWishTaken = CreateMultiForward("OnLastPrisonerWishTaken", ET_CONTINUE, FP_CELL);
	fRemoveData = CreateMultiForward("OnRemoveData", ET_CONTINUE, FP_CELL);
	
	MenuLeader = menu_create("\wPozwol \yWiezniowi\w wybrac zyczenie:", "MenuWishService_Handle");	

	menu_additem(MenuLeader, "Tak");
	menu_additem(MenuLeader, "Nie");
	
	set_task(0.5, "task_server", _, _, _, "b");
}

public plugin_cfg()
{
	get_mapname(szMap, charsmax(szMap));
	get_cvar_string("amx_nextmap", szNextMap, charsmax(szMap));
	
	new szFile[128];

	formatex(szFile, charsmax(szFile), "addons/amxmodx/data/cele/%s.ini", szMap);
	
	if(file_exists(szFile))
	{
		new szData[4][32], szTemp[256], iLen;
		
		for(new i = 0; i < file_size(szFile, 1); i++)
		{
			if(i > 1) break;
			
			read_file(szFile, i, szTemp, charsmax(szTemp), iLen);
			parse(szTemp, szData[0], charsmax(szData[]), szData[1], charsmax(szData[]), szData[2], charsmax(szData[]), szData[3], charsmax(szData[]));
			
			new Float:fOrigin[3], Float:fDistance = 9999.0, Float:fDistance2, iEnt;
			
			fOrigin[0] = str_to_float(szData[0]);
			fOrigin[1] = str_to_float(szData[1]);
			fOrigin[2] = str_to_float(szData[2]);
			
			while((iEnt = find_ent_by_class(iEnt, szData[3])))
			{	
				new Float:fOrigin2[3];
				
				get_brush_entity_origin(iEnt, fOrigin2);
				
				fDistance2 = vector_distance(fOrigin2, fOrigin);
				
				if(fDistance2 < fDistance)
				{
					fDistance = fDistance2;
					szButtons[i] = iEnt;
				}
			}
		}
	}
	else SetupButtons();
	
	AddMenuItem("Dodanie Cel", "jail_cele", ADMIN_RCON, PLUGIN);
	
	server_cmd("exec addons/amxmodx/configs/jailbreak.cfg");
}

public plugin_precache()
{
	szModels[V_PALKA] = "models/reload_akcesoriacs/v_palka.mdl";
	szModels[P_PALKA] = "models/reload_akcesoriacs/p_palka.mdl";
	szModels[V_PIESCI] = "models/reload_akcesoriacs/v_piesci.mdl";
	szModels[P_PIESCI] = "models/reload_akcesoriacs/p_piesci.mdl";
	szModels[V_REKAWICE] = "models/reload_akcesoriacs/v_rekawice.mdl";
	szModels[P_REKAWICE] = "models/reload_akcesoriacs/p_rekawice.mdl";

	precache_model(szModels[V_PALKA]);
	precache_model(szModels[P_PALKA]);
	precache_model(szModels[V_PIESCI]);
	precache_model(szModels[P_PIESCI]);
	precache_model(szModels[V_REKAWICE]);
	precache_model(szModels[P_REKAWICE]);
	
	precache_sound("weapons/prawy_przycisk1.wav");
	precache_sound("weapons/uderzenie_mur1.wav");
	precache_sound("weapons/hitt.wav");
	precache_sound("weapons/hitt1.wav");
	precache_sound("weapons/machanie1.wav");

	precache_generic("models/player/reload_wiezien/reload_wiezien.mdl");
	precache_generic("models/player/reload_klawisz/reload_klawisz.mdl");
	precache_generic("models/player/reload_vipct/reload_vipct.mdl");
	precache_generic("models/player/reload_vipct/reload_vipctT.mdl");
	precache_generic("models/player/reload_viptt/reload_viptt.mdl");

	precache_generic("sound/jb_cypis/uciekinier.wav");

	precache_generic("sprites/weapon_piesci.txt");  
	precache_generic("sprites/weapon_palka.txt");  
	precache_generic("sprites/640hud41.spr");  
}

public plugin_natives()
{
	aGameNames = ArrayCreate(32);
	aWishNames = ArrayCreate(32);

	register_native("jail_register_game", "RegisterGame", 1);
	register_native("jail_register_wish", "RegisterWish", 1);
	
	register_native("jail_set_game_hud", "jail_set_game_hud_p", 0);

	register_native("jail_get_prisoners_micro", "GetMicro", 1);
	register_native("jail_get_prisoners_fight", "GetBattle", 1);
	register_native("jail_get_prisoner_free", "GetFreeday", 1);
	register_native("jail_get_prisoner_ghost", "GetGhost", 1);
	register_native("jail_get_prisoner_last", "GetLastPrisoner", 1);
	register_native("jail_get_prowadzacy", "GetLeader", 1);
	register_native("jail_get_poszukiwany", "CheckWanted", 1);
	register_native("jail_get_poszukiwani", "GetWanted", 1);
	register_native("jail_get_user_block", "GetFight", 1);
	register_native("jail_get_play_game_id", "GetGameID", 1);
	register_native("jail_get_play_game", "GetGame", 1);
	register_native("jail_get_days", "GetDay", 1);

	register_native("jail_set_prisoners_micro", "SetMicro", 1);
	register_native("jail_set_prisoners_fight", "SetBattle", 1);
	register_native("jail_set_prisoner_free", "SetFreeday", 1);
	register_native("jail_set_prisoner_ghost", "SetGhost", 1);
	register_native("jail_set_prisoners_game", "SetGameVote", 1);
	register_native("jail_set_prowadzacy", "SetLeader", 1);
	register_native("jail_set_god_tt", "SetTTGod", 1);
	register_native("jail_set_god_ct", "SetCTGod", 1);
	register_native("jail_set_ct_hit_tt", "SetCTHitTT", 1);
	register_native("jail_set_tt_hit_ct", "SetTTHitCT", 1);
	register_native("jail_set_user_block", "SetBlock", 1);
	register_native("jail_set_play_game", "SetGame", 1);
	register_native("jail_set_user_menuweapons", "SetMenuWeapons", 1);
	register_native("jail_set_user_speed", "SetPlayerSpeed", 1);
	register_native("jail_set_game_end", "EndGame", 1);
	register_native("jail_set_teams", "SetTeams", 1);
	register_native("jail_get_team", "GetTeam", 1);
	register_native("jail_open_cele", "OpenCells", 1);
}

public RegisterWish(szWish[])
{
	param_convert(1);
	
	ArrayPushString(aWishNames, szWish);
	
	static iAmount; iAmount++;
	
	return iAmount;
}

public RegisterGame(szGame[])
{
	param_convert(1);
	ArrayPushString(aGameNames, szGame);
	
	static iCount = 8; iCount++;
	return iCount;
}

public MenuWishes(id)
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes pre");
	#endif
	if(!is_user_alive(id))
	{
		#if defined DEBUG
		log_to_file("jail_api_jailbreak.log", "MenuWishes not alive");
		#endif
		return PLUGIN_HANDLED;
	}
	
	if(iPlayerTeam[id] != 1)
	{
		#if defined DEBUG
		log_to_file("jail_api_jailbreak.log", "MenuWishes not terrorist");
		#endif
		return PLUGIN_HANDLED;
	}
	
	if(iLastPrisoner != id)
	{
		#if defined DEBUG
		new iPlayersAlive = iPlayersCount[ZYWI],
		iPlayersAll = iPlayersCount[WSZYSCY];
		
		new iPlayers[32], iPlayer, iAll, iAlive;
    
		get_players(iPlayers, iAll, "ceh", "TERRORIST");
    
		for(new i = 0; i < iAll; i++)
		{
			iPlayer = iPlayers[i];
			
			if(is_user_connected(iPlayer) && is_user_alive(iPlayer) && !bGhost[iPlayer] && !bFreeday[iPlayer]) iAlive++;
		}
		
		log_to_file("jail_api_jailbreak.log", "MenuWishes not last prisoner. Dynamic: %i/%i. Normal: %i/%i.", iPlayersAlive, iPlayersAll, iAlive, iAll);
		#endif
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie jestes ostatnim wiezniem!");
		return PLUGIN_HANDLED;
	}
	
	if(bWishChosen)
	{
		#if defined DEBUG
		log_to_file("jail_api_jailbreak.log", "MenuWishes wish taken");
		#endif
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zyczenie zostalo juz wybrane!");
		return PLUGIN_HANDLED;
	}
	
	if(!bServiceGiven)
	{
		#if defined DEBUG
		log_to_file("jail_api_jailbreak.log", "MenuWishes service not given");
		#endif
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Straznik prowadzacy nie pozwolil na wybranie zyczenia!");
		return PLUGIN_HANDLED;
	}

	if(!ArraySize(aWishNames))
	{
		#if defined DEBUG
		log_to_file("jail_api_jailbreak.log", "MenuWishes no games");
		#endif
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie ma zadnych zyczen na serwerze!");
		return PLUGIN_HANDLED;
	}
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes premenu");
	#endif

	new szWish[64], szID[5], menu = menu_create("\wWybierz \yZyczenie\w:", "MenuWishes_Handle");	
	
	for(new i = 0; i < ArraySize(aWishNames); i++)
	{
		ArrayGetString(aWishNames, i, szWish, charsmax(szWish));
		
		num_to_str(i + 1, szID, charsmax(szID));
		
		menu_additem(menu, szWish, szID);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes post");
	#endif
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	set_user_health(id, 100);
	
	set_user_rendering(id, kRenderFxNone, 0,0,0, kRenderTransAlpha, 255);
	set_user_rendering(id, kRenderFxGlowShell, 255, 255, 255, kRenderGlow, 1);
	
	if(!(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		cs_set_player_model(id, "reload_wiezien");
	
		set_pev(id, pev_body, random(3));
	}
	else cs_set_player_model(id, "reload_viptt");

	return PLUGIN_HANDLED;
}

public MenuWishes_Handle(id, menu, item)
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes_Handle pre");
	#endif
	if(item == MENU_EXIT || !is_user_alive(id) || iLastPrisoner != id) return;

	new szWish[64], szID[3], iAccess, iRet;
	
	menu_item_getinfo(menu, item, iAccess, szID, charsmax(szID), szWish, charsmax(szWish), iAccess);
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes_Handle ID: %s", szID);
	#endif
	
	ExecuteForward(fLastPrisonerTakeWish, iRet, id, str_to_num(szID));
	
	if(iRet == 9999)
	{
		menu_display(id, menu);
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz wybrac tego zyczenia!");
		
		return;
	}
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 wybral^x03 %s", szPlayerName[id], szWish);
	
	ExecuteForward(fLastPrisonerWishTaken, iRet, id);
	
	bWishChosen = true;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuWishes_Handle: %s", szWish);
	#endif
}

public MenuGames(id)
{
	if(iPlayerTeam[id] != 2 || iLeader != id) return PLUGIN_CONTINUE;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuGames pre");
	#endif
	if(!ArraySize(aGameNames))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie ma zadnych zabaw na serwerze!");
		return PLUGIN_CONTINUE;
	}
	
	if(bGameChosen)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Juz wybrales dzisiaj zabawe.");
		return PLUGIN_CONTINUE;
	}
	
	#if defined SUNDAY_GAMES
	if(bSunday)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Dzisiaj wiezniowie wybieraja zabawe.");
		return PLUGIN_CONTINUE;
	}
	#endif
	
	new szGame[32], szID[3], menu = menu_create("\wWybierz \yZabawe\w:", "MenuGames_Handle");
	
	for(new i = 0; i < ArraySize(aGameNames); i++)
	{
		ArrayGetString(aGameNames, i, szGame, charsmax(szGame));
		num_to_str(i + 9, szID, charsmax(szID));
		menu_additem(menu, szGame, szID);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuGames post");
	#endif
	return PLUGIN_HANDLED;
}

public MenuGames_Handle(id, menu, item)
{
	if(item == MENU_EXIT || bGameChosen || iLeader != id) return;
	
	if(iPlayersCount[WSZYSCY] != iPlayersCount[ZYWI])
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Juz za pozno na zabawe! Ktos z wiezniow nie zyje.");
		return;
	}
	
	if(bFreezeTime)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zaczekaj na calkowite rozpoczecie rundy!");
		return;
	}
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuGames_Handle pre");
	#endif
	new acces, szGame[32], szID[32];
	
	menu_item_getinfo(menu, item, acces, szID, 31, szGame, 31, acces);
	
	client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 %s%s", SetGame(str_to_num(szID), false) ? "wlaczyles ": "juz jest za pozno, aby wlaczyc ", szGame);
	
	bGameChosen = true;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "MenuGames_Handle post");
	#endif
}

#if defined SUNDAY_GAMES
public StartGameVote()
{
	if(!iLeader)
	{
		ForwardDayStartPre(iJailDay%7);
		return PLUGIN_CONTINUE;
	}
	
	if(!ArraySize(aGameNames)) return PLUGIN_CONTINUE;

	if(!iPlayersCount[ZYWI])
	{
		set_task(5.0, "StartGameVote");
		return PLUGIN_CONTINUE;
	}
	
	for(new i = 0; i < ArraySize(aGameNames); i++) iVotes[i] = 0;
	
	new szGame[32], szID[3], menu = menu_create("\yGlosowanie: \yWybierz Zabawe\w", "GameVote_Handle");
	
	for(new i = 0; i < ArraySize(aGameNames); i++)
	{
		ArrayGetString(aGameNames, i, szGame, charsmax(szGame));
		num_to_str(i + 9, szID, charsmax(szID));
		
		menu_additem(menu, szGame, szID);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");
	
	for(new i = 0; i < iNum; i++) if(is_user_alive(iPlayers[i]) && get_user_team(iPlayers[i]) == 1) menu_display(iPlayers[i], menu, 0);
	
	client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Glosowanie na zabawe potrwa^x04 10s^x01.");
	
	set_task(10.0, "EndVote", menu);
	
	return PLUGIN_HANDLED;
}

public GameVote_Handle(id, menu, item)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED

	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}
	
	new szName[33], szGame[32];
	
	ArrayGetString(aGameNames, item, szGame, charsmax(szGame));
	get_user_name(id, szName, charsmax(szName));
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x01 %s zaglosowal na^x03 %s^x01.", szName, szGame);
	iVotes[item]++;

	menu_cancel(id);
	return PLUGIN_HANDLED;
}

public EndVote(menu) 
{
	if(!iLeader)
	{
		ForwardDayStartPre(iJailDay%7);
		
		return;
	}
	
	menu_destroy(menu);
	
	new szGame[32], iGame = 0;
	
	for(new i = 0; i < ArraySize(aGameNames); i++) if(iVotes[i] > iVotes[iGame]) iGame = i
	
	ArrayGetString(aGameNames, iGame, szGame, charsmax(szGame));
	
	ForwardDayStartPre(iGame + 9);
	
	client_print_color(0, print_team_red, "^x04[WIEZIENIE CS-RELOAD]^x01 Wiezniowie wybrali^x03 %s^x01 na dzisiejsza zabawe.", szGame);
}
#endif

public CurWeapon(id)
{	
	if(!is_user_alive(id)) return;
	
	new iWeapon = read_data(2);
	
	if(bGhost[id])
	{
		if(iWeapon != CSW_KNIFE)
		{
			bGhost[id] = false;
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
			
			AddArray(id, WSZYSCY);
			AddArray(id, ZYWI);
		}
	}
	
	if(szDayData[7])
	{
		if(szDayData[7] != 3 && szDayData[7] != iPlayerTeam[id]) return;
		
		if(iWeapon == CSW_KNIFE || iWeapon == CSW_HEGRENADE || iWeapon == CSW_FLASHBANG || iWeapon == CSW_SMOKEGRENADE) return;
		
		cs_set_user_bpammo(id, iWeapon, iMaxAmmo[iWeapon]);
	}
}

public SpeedChange(id)
{
	if(!is_user_alive(id)) return HAM_IGNORED;
	
	if(!bFreezeTime) ChangePlayerSpeed(id);
	
	return HAM_IGNORED;
}

public SetPlayerSpeed(id, Float:speed)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	
	switch(speed)
	{
		case 0.1: fPlayerSpeed[id] = 0.1;
		case -1.0: fPlayerSpeed[id] = 250.0;
		default: fPlayerSpeed[id] = speed;
	}
	
	ChangePlayerSpeed(id);
	
	return PLUGIN_CONTINUE;
}

public ChangePlayerSpeed(id)
{
	if(!is_user_alive(id) || bFreezeTime)	 return PLUGIN_CONTINUE;
	
	set_user_maxspeed(id, fPlayerSpeed[id]);
	
	engfunc(EngFunc_SetClientMaxspeed, id, fPlayerSpeed[id])
	
	return PLUGIN_CONTINUE;
}

public EndGame(Float:Time)
	set_task(Time, "GameEnded", TASK_END);

public GameEnded()
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "GameEnd pre");
	#endif
	
	switch(random_num(1, 3))
	{
		case 1:
		{
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Straznicy nie zdazyli wypelnic swoich obowiazkow - wlasnie zgineli.");
			
			for(new i = 1; i <= MAX; i++)
			{
				if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 2) continue;

				user_kill(i);
			}
		}
		case 2:
		{
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Pora na zemste wiezniow na straznikami - niech rozpocznie sie walka.");
			
			bPlayerMode[CT_GOD] = false;
			bPlayerMode[CT_NIE_MOZE_TT] = false;
			bPlayerMode[TT_NIE_MOZE_CT] = false;
			
			for(new i = 1; i <= MAX; i++)
			{
				if(!is_user_connected(i) || !is_user_alive(i) || bFreeday[i] || bGhost[i]) continue;

				SetPlayerSpeed(i, -1.0);
				
				set_user_health(i, 100);
				
				strip_user_weapons2(i);
				
				give_item(i, "weapon_knife");
				give_item(i, "weapon_deagle");
				give_item(i, "ammo_50ae");
				give_item(i, "ammo_50ae");

				switch(get_user_team(i))
				{
					case 1: 
					{
						cs_set_player_model(i, "wiezien_cypis");
						
						give_item(i, "weapon_ak47");
						give_item(i, "ammo_762nato");
						give_item(i, "ammo_762nato");
					}
					case 2:
					{
						give_item(i, "weapon_m4a1");
						give_item(i, "ammo_556nato");
						give_item(i, "ammo_556nato");
					}
				}
			}
		}
		case 3:
		{
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Zaraz zobaczymy, ktory z wiezniow jest najtwardszy - walczcie!");
			
			bPlayerMode[CT_NIE_MOZE_TT] = true;
			bPlayerMode[TT_NIE_MOZE_CT] = true;
			bPlayerMode[WALKA] = true;
			bPlayerMode[FF_TT] = true;

			for(new i = 1; i <= MAX; i++)
			{
				if(!is_user_connected(i) || !is_user_alive(i) || bFreeday[i] || bGhost[i]) continue;
				
				SetPlayerSpeed(i, -1.0);
				
				set_user_health(i, 100);
				
				if(get_user_team(i) == 1)
				{
					cs_set_player_model(i, "wiezien_cypis");
					
					strip_user_weapons2(i);
					
					give_item(i, "weapon_knife");
					
					if(get_user_weapon(i) == CSW_KNIFE)
					{	
						set_pev(i, pev_viewmodel2, szModels[V_REKAWICE]);
						set_pev(i, pev_weaponmodel2, szModels[P_REKAWICE]);
					}
				}
			}
		}
	}
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "GameEnd post");
	#endif
}

public GetGameID()
	return iGameID;

public GetGame()
	return bGame;

public bool:GetFight(id)
	return bFight[id];

public bool:CheckWanted(id)
	return (contain(szWanted, szPlayerName[id]) != -1) ? true: false;
	
public bool:GetWanted(id)
	return (!szWanted[0]) ? false: true;

public bool:GetMicro()
	return bool:bPlayerMode[MIKRO];

public bool:GetBattle()
	return bool:bPlayerMode[WALKA];

public bool:GetFreeday(id)
	return bFreeday[id];

public bool:GetGhost(id)
	return bGhost[id];

public GetLastPrisoner()
	return iLastPrisoner;

public GetLeader()
	return iLeader;

public GetDay()
	return iJailDay%7;

public SetMicro(bool:value, bool:info)
{
	if(iLastPrisoner || szDayData[1]) return;
	
	bPlayerMode[MIKRO] = value;
	
	if(info) client_print_color(0, print_team_red, "^x04[WIEZIENIE CS-RELOAD]^x01 Status mikro dla wiezniow: ^x03%s!", bPlayerMode[MIKRO] ? "wlaczone": "wylaczone");
}

public SetBattle(bool:value, bool:models, bool:info)
{
	if(iLastPrisoner || (szDayData[1] && models)) return;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetBattle pre");
	#endif
	bPlayerMode[WALKA] = models;
	bPlayerMode[FF_TT] = value;
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || iPlayerTeam[i] != 1 || bFreeday[i] || bGhost[i]) continue;
	
		set_user_health(i, 100);
		
		if(get_user_weapon(i) == CSW_KNIFE)
		{	
			set_pev(i, pev_viewmodel2, models ? szModels[V_REKAWICE]: szModels[V_PIESCI]);
			set_pev(i, pev_weaponmodel2, models ? szModels[P_REKAWICE]: szModels[P_PIESCI]);
		}
	}
	
	if(info) client_print_color(0, print_team_red, "^x04[WIEZIENIE CS-RELOAD]^x01 Walka^x03 %s^x01!", bPlayerMode[WALKA]? "wlaczona": "wylaczona");
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetBattle post");
	#endif
}

public SetFreeday(id, bool:value, bool:nextround)
{
	if(!id || (szDayData[1] && !nextround)) return 0;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetFreeday pre");
	#endif
	if(!nextround && value)
	{
		new iCount = 0;
		
		for(new i = 1; i <= MAX; i++) if(is_user_alive(i) && is_user_connected(i) && iPlayerTeam[i] == 1 && !bFreeday[i] && !bGhost[i]) iCount++;
		
		if(iCount == 1) return 0;
	}
	
	if(value)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	
	bFreeday[id] = value;
	bSetFreeday[id] = nextround;
	
	if(!value)
	{
		AddArray(id, WSZYSCY);
		AddArray(id, ZYWI);
	}
	
	set_pev(id, pev_body, value ? 3 : random(3));
	
	value ? set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 15) : set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetFreeday post");
	#endif
	return 1;
}

public SetGhost(id, bool:value, bool:nextround)
{
	if(!id || (szDayData[1] && !nextround)) return 0;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetGhost pre");
	#endif
	
	new bool:bHave = bGhost[id];
	
	if(!nextround && value)
	{
		new iCount = 0;
		
		for(new i = 1; i <= MAX; i++) if(is_user_alive(i) && is_user_connected(i) && iPlayerTeam[i] == 1 && !bFreeday[i] && !bGhost[i]) iCount++;

		if(iCount == 1) return 0;
	}
	
	if(value)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	
	bGhost[id] = value;
	bSetFreeday[id] = nextround;
	
	if(!value)
	{
		AddArray(id, WSZYSCY);
		AddArray(id, ZYWI);
	}
	
	if(bHave || value) set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, value ? 0:255);
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetGhost post");
	#endif
	return 1;
}

public SetGameVote()
	bWishGame = true;

public SetTTGod(bool:value)
	bPlayerMode[TT_GOD] = value;

public SetCTGod(bool:value)
	bPlayerMode[CT_GOD] = value;

public SetCTHitTT(bool:value)
	bPlayerMode[CT_NIE_MOZE_TT] = value;

public SetTTHitCT(bool:value)
	bPlayerMode[TT_NIE_MOZE_CT] = value;

public SetBlock(id, bool:value)
	bFight[id] = value;

public SetLeader(id)
{
	if(!szDayData[1])
	{
		if(iLeader != id && iLeader)
		{
			set_pev(iLeader, pev_body, 0);
			set_user_rendering(iLeader, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
		}
		
		iLeader = id;
		
		if(id)
		{
			if(task_exists(ID_LOS_PROWADZACY))
			remove_task(ID_LOS_PROWADZACY);
			
			set_pev(id, pev_body, 1);
			set_user_rendering(id, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 15);
		}
	}
}

public SetGame(game, bool:fast)
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetGame pre");
	#endif	
	if(!fast)
	{
		if(bWeaponsTime || iPlayersCount[WSZYSCY] != iPlayersCount[ZYWI]) return 0;
		
		if(bPlayerMode[WALKA] || bPlayerMode[FF_TT]) SetBattle(false, false, false);
	}
	
	ForwardDayStartPre(game);
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "SetGame post");
	#endif	
	return 1;
}

public MenuWeapons(id)
{
	if(!is_user_alive(id) || iPlayerTeam[id] != 2 || bWeaponsTime) return PLUGIN_HANDLED;
	
	SetMenuWeapons(id, true, true, 0, 0);
	
	return PLUGIN_HANDLED;
}

public SetMenuWeapons(id, bool:weapons, bool:pistols, bitsum_weapons, bitsum_pistols)
{
	if(!weapons && !pistols)
	{
		new iWeapon = iPlayerWeapons[id][0], szWeapon[24];
		
		if(iWeapon > 0)
		{
			get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));
			give_item(id, szWeapon);
			cs_set_user_bpammo(id, iWeapon, iMaxAmmo[iWeapon]);
		}
		
		iWeapon = iPlayerWeapons[id][1];
		
		if(iWeapon > 0)
		{
			get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));
			give_item(id, szWeapon);
			cs_set_user_bpammo(id, iWeapon, iMaxAmmo[iWeapon]);
		}
		
		return;
	}
	
	iPlayerWeapons[id][0] = 0;
	iPlayerWeapons[id][1] = 0;
	
	iWeaponsMenu[id][0] = weapons;
	iWeaponsMenu[id][1] = pistols;
	
	iWeaponsBit[id][0] = bitsum_weapons;
	iWeaponsBit[id][1] = bitsum_pistols;
	
	MenuChooseWeapons(id);
}

public MenuChooseWeapons(id)
{
	if(!iWeaponsMenu[id][0] && iWeaponsMenu[id][1])
	{
		MenuPistols(id);
		return;
	}
	
	if(!iWeaponsMenu[id][0]) return;
	
	new menu = menu_create("\wWybierz \yBronie\w:", "Handel_Bronie");
	
	if(!(iWeaponsBit[id][0] & (1<<CSW_M4A1))) menu_additem(menu, "\rM4A1", "22");
	if(!(iWeaponsBit[id][0] & (1<<CSW_AK47))) menu_additem(menu, "\rAK47", "28");
	if(!(iWeaponsBit[id][0] & (1<<CSW_AWP))) menu_additem(menu, "\rAWP", "18");
	if(!(iWeaponsBit[id][0] & (1<<CSW_SCOUT))) menu_additem(menu, "\rScout", "3");
	if(!(iWeaponsBit[id][0] & (1<<CSW_AUG))) menu_additem(menu, "\rAUG", "8");
	if(!(iWeaponsBit[id][0] & (1<<CSW_SG550))) menu_additem(menu, "\rKrieg 550", "13");
	if(!(iWeaponsBit[id][0] & (1<<CSW_M249))) menu_additem(menu, "\rM249", "20");
	if(!(iWeaponsBit[id][0] & (1<<CSW_MP5NAVY))) menu_additem(menu, "\rMP5", "19");
	if(!(iWeaponsBit[id][0] & (1<<CSW_UMP45))) menu_additem(menu, "\rUMP45", "12");
	if(!(iWeaponsBit[id][0] & (1<<CSW_FAMAS))) menu_additem(menu, "\rFamas", "15");
	if(!(iWeaponsBit[id][0] & (1<<CSW_GALIL))) menu_additem(menu, "\rGalil", "14");
	if(!(iWeaponsBit[id][0] & (1<<CSW_M3))) menu_additem(menu, "\rM3", "21");
	if(!(iWeaponsBit[id][0] & (1<<CSW_XM1014))) menu_additem(menu, "\rXM1014", "5");
	if(!(iWeaponsBit[id][0] & (1<<CSW_MAC10))) menu_additem(menu, "\rMac10", "7");
	if(!(iWeaponsBit[id][0] & (1<<CSW_TMP))) menu_additem(menu, "\rTMP", "23");
	if(!(iWeaponsBit[id][0] & (1<<CSW_P90))) menu_additem(menu, "\rP90", "30");
	if(!(iWeaponsBit[id][0] & (1<<CSW_G3SG1))) menu_additem(menu, "\rG3SG1 \y(autokampa)", "24");
	if(!(iWeaponsBit[id][0] & (1<<CSW_SG552))) menu_additem(menu, "\rKrieg 552 \y(autokampa)", "27");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
}

public Handel_Bronie(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || !iWeaponsMenu[id][0])
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szWeapon[24], szData[3], iWeapon, iCallback;
	menu_item_getinfo(menu, item, iWeapon, szData, charsmax(szData), _, _, iCallback);
	
	if((iCallback = WhatPistol(id)) > 0) ham_strip_weapon(id, iCallback);
	
	iWeapon = str_to_num(szData);
	
	get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));
	
	give_item(id, szWeapon);
	cs_set_user_bpammo(id, iWeapon, iMaxAmmo[iWeapon]);
	
	iPlayerWeapons[id][0] = iWeapon;
	
	if(iWeaponsMenu[id][1]) MenuPistols(id);
	
	return PLUGIN_HANDLED;
}

public MenuPistols(id)
{
	if(!iWeaponsMenu[id][1]) return;
	
	new menu = menu_create("\wWybierz \yPistolet\w:", "Handel_Pistolety");
	
	if(!(iWeaponsBit[id][1] & (1<<CSW_USP))) menu_additem(menu, "\rUSP",	"16");
	if(!(iWeaponsBit[id][1] & (1<<CSW_GLOCK18))) menu_additem(menu, "\rGlock", 	"17");
	if(!(iWeaponsBit[id][1] & (1<<CSW_DEAGLE))) menu_additem(menu, "\rDeagle", 	"26");
	if(!(iWeaponsBit[id][1] & (1<<CSW_P228))) menu_additem(menu, "\rP228",	"1");
	if(!(iWeaponsBit[id][1] & (1<<CSW_FIVESEVEN))) menu_additem(menu, "\rFiveSeven", "11");
	if(!(iWeaponsBit[id][1] & (1<<CSW_ELITE))) menu_additem(menu, "\rDual", 	"10");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
}

public Handel_Pistolety(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || !iWeaponsMenu[id][1])
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new weaponname[24], data[3], weapon, callback;
	menu_item_getinfo(menu, item, weapon, data, 2, _, _, callback);
	
	weapon = str_to_num(data);
	get_weaponname(weapon, weaponname, 23);
	give_item(id, weaponname);
	cs_set_user_bpammo(id, weapon, iMaxAmmo[weapon]);
	
	iPlayerWeapons[id][1] = weapon;
	
	return PLUGIN_HANDLED;
}

public ButtonTraceAttack(ent, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(pev_valid(ent) && iLeader == id)
	{
		ExecuteHam(Ham_Use, ent, id, 0, 2, 1.0);
		set_pev(ent, pev_frame, 0.0);
	}
	
	return HAM_IGNORED;
}

public TakeDamage(id, ent, attacker, Float:damage, damagebits)
	return vAttackDamagePlayer(id, attacker, damage, damagebits, true);

public TraceAttack(id, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
	return vAttackDamagePlayer(id, attacker);

vAttackDamagePlayer(id, attacker, Float:fDamage = 0.0, iDamageBits = 0, bool:bDmg = false)
{
	if(!is_user_connected(id)) return HAM_IGNORED;
	
	if((iPlayerTeam[id] == 1 && bPlayerMode[TT_GOD]) || (iPlayerTeam[id] == 2 && bPlayerMode[CT_GOD])) return HAM_SUPERCEDE;
	
	if(is_user_connected(attacker))
	{
		if(iTeam[id] && iTeam[attacker] && iTeam[attacker] == iTeam[id]) return HAM_SUPERCEDE;
		
		if(iPlayerTeam[id] == 1 && iPlayerTeam[attacker] == 1 && !bPlayerMode[FF_TT]) return HAM_SUPERCEDE;
		
		if(iPlayerTeam[id] == 2 && iPlayerTeam[attacker] == 2) return HAM_SUPERCEDE;
		
		if(iPlayerTeam[id] == 1 && iPlayerTeam[attacker] == 2 && bPlayerMode[CT_NIE_MOZE_TT]) return HAM_SUPERCEDE;
		
		if(iPlayerTeam[id] == 2 && iPlayerTeam[attacker] == 1 && bPlayerMode[TT_NIE_MOZE_CT]) return HAM_SUPERCEDE;
		
		if(bFreeday[attacker] || iPlayerTeam[attacker] == 1 && bFreeday[id]) return HAM_SUPERCEDE;
		
		if(bGhost[id] && iPlayerTeam[attacker] == 1) return HAM_SUPERCEDE;
		
		if(bGhost[attacker] && iPlayerTeam[id] == 2)
		{
			bGhost[attacker] = false;
			
			set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
			
			AddArray(attacker, WSZYSCY);
			AddArray(attacker, ZYWI);

			return HAM_IGNORED;
		}
		
		if(bDmg && get_user_weapon(attacker) == CSW_KNIFE && iDamageBits & DMG_BULLET) SetHamParamFloat(4, fDamage*0.4);
	}
	return HAM_IGNORED;
}

public PlayerSpawn(id)
{
	if(!is_user_alive(id) || !is_user_connected(id)) return;
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	
	strip_user_weapons2(id);
	
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			iPlayerTeam[id] = 1;
			
			if(!(get_user_flags(id) & ADMIN_LEVEL_H))
			{
				cs_set_player_model(id, "reload_wiezien");
				
				set_pev(id, pev_body, random(3));
			}
			else cs_set_player_model(id, "reload_viptt");
			
			AddArray(id, WSZYSCY);
			AddArray(id, ZYWI);
		}
		case CS_TEAM_CT:
		{
			if(szDayData[4] < 2)
			{
				if(iPlayerWeapons[id][0] && iPlayerWeapons[id][1])
				{
					for(new i = 0; i < 2; i++)
					{
						new szWeapon[24];
						
						get_weaponname(iPlayerWeapons[id][i], szWeapon, charsmax(szWeapon));
						give_item(id, szWeapon);
						cs_set_user_bpammo(id, iPlayerWeapons[id][i], iMaxAmmo[iPlayerWeapons[id][i]]);
					}
				}
				else if(!bWeaponsTime) SetMenuWeapons(id, true, true, 0, 0);
			}
			iPlayerTeam[id] = 2;
			
			if(get_user_flags(id) & ADMIN_LEVEL_H) cs_set_player_model(id, "reload_vipct");
			else cs_set_player_model(id, "reload_klawisz");	
		}
	}
	
	give_item(id, "weapon_knife");
	
	iReason[id] = random_num(0, sizeof szReasons - 1);  
	
	if(bFreeday[id])
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H)) set_pev(id, pev_body, 3);
		
		set_task(0.3, "FreedayRender", id);
	}
	
	if(bGhost[id]) set_task(0.3, "GhostRender", id);
}

public FreedayRender(id)
	set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 15);
	
public GhostRender(id)
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);

public GiveLeadership(id)
{
	if(iLeader != id) return PLUGIN_HANDLED;
	
	new szNum[3], menu = menu_create("\wOddaj \yProwadzenie\w:", "GiveLeadership_Handle");
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || iPlayerTeam[i] != 2 || iLeader == i) continue;
		
		num_to_str(i, szNum, charsmax(szNum));
		menu_additem(menu, szPlayerName[i], szNum);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);	

	return PLUGIN_HANDLED;
}

public TakeLeadership(id)
{
	if(iLeader == id || iLeader || bGame || !is_user_alive(id) || get_user_team(id) != 2) return PLUGIN_HANDLED;
	
	iLeader = id;
	
	client_print_color(0, print_team_blue, "^x04[WIEZIENIE CS-RELOAD]^x01 Zmienil sie^x03 Prowadzacy^x01!");
	
	set_pev(iLeader, pev_body, 1);
	set_user_rendering(iLeader, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 15);
	
	return PLUGIN_HANDLED;
}

public GiveLeadership_Handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || iLeader != id)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new szData[3], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	iLeader = str_to_num(szData);
	
	client_print_color(0, print_team_blue, "^x04[WIEZIENIE CS-RELOAD]^x01 Zmienil sie^x03 Prowadzacy^x01!");
	
	set_pev(id, pev_body, 0);
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	set_pev(iLeader, pev_body, 1);
	set_user_rendering(iLeader, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 15);

	return PLUGIN_HANDLED;
}

public WeaponKnife(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	
	if(!is_user_alive(id) || cs_get_user_shield(id)) return;
	
	if(!(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		if(iPlayerTeam[id] == 1 && !bPlayerMode[WALKA])
		{
			set_pev(id, pev_viewmodel2, szModels[V_PIESCI]);
			set_pev(id, pev_weaponmodel2, szModels[P_PIESCI]);
		}
		else if(iPlayerTeam[id] == 1 && bPlayerMode[WALKA])
		{
			set_pev(id, pev_viewmodel2, szModels[V_REKAWICE]);
			set_pev(id, pev_weaponmodel2, szModels[P_REKAWICE]);
		}
	}
	if(iPlayerTeam[id] == 2)
	{
		set_pev(id, pev_viewmodel2, szModels[V_PALKA]);
		set_pev(id, pev_weaponmodel2, szModels[P_PALKA]);
	}
}

public EmitSound(id, channel, sample[])
{	
	if(!is_user_alive(id) || !is_user_connected(id)) return FMRES_IGNORED;
	
	if(equal(sample, "weapons/knife_", 14))
	{
		switch(sample[17])
		{
			case ('b'): emit_sound(id, CHAN_WEAPON, "weapons/prawy_przycisk1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			case ('w'): emit_sound(id, CHAN_WEAPON, "weapons/uderzenie_mur1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW);
			case ('s'): emit_sound(id, CHAN_WEAPON, "weapons/machanie1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			case ('1'): emit_sound(id, CHAN_WEAPON, "weapons/hitt.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
			case ('2'): emit_sound(id, CHAN_WEAPON, "weapons/hitt1.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
		}
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(sample, "common/wpn_denyselect.wav")) return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public AdminVoiceOn(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;
	
	if(iAdminVoice) return PLUGIN_HANDLED;
	
	iAdminVoice = id;
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Cisza!^x03 %s^x01 przemawia.", szPlayerName[id]);
	
	client_cmd(id, "+voicerecord");
	
	return PLUGIN_HANDLED;
}

public AdminVoiceOff(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_HANDLED;
	
	if(iAdminVoice != id)
	{
		client_cmd(id, "-voicerecord");
		return PLUGIN_HANDLED;
	}
	
	client_cmd(id, "-voicerecord");
	
	iAdminVoice = 0;
	
	return PLUGIN_HANDLED;
}

public MenuMute(id)
{
	new szName[64], szNum[3], menu = menu_create("\wWybierz \yGracza \wdo zmutowania:", "MenuMute_Handle");
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_connected(i) || is_user_hltv(i)) continue;

		num_to_str(i, szNum, charsmax(szNum));
		
		szName = szPlayerName[i];
		
		if(bMuted[id][i]) add(szName, charsmax(szName), " \r[MUTE]");
		
		menu_additem(menu, szName, szNum);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);	
}

public MenuMute_Handle(id, menu, item)
{
	if(item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szData[3], iAccess, iPlayer;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iPlayer);
	
	iPlayer = str_to_num(szData);
	
	bMuted[id][iPlayer] = !bMuted[id][iPlayer];
	
	client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 %s gracza ^x03%s", bMuted[id][iPlayer] ? "Zmutowales": "Odmutowales", szPlayerName[iPlayer]);

	return PLUGIN_HANDLED;
}

public Voice_SetClientListening(odbiorca, nadawca, listen) 
{
	if(odbiorca == nadawca)
	return FMRES_IGNORED;
	
	if(bMuted[odbiorca][nadawca])
	{
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	if(iAdminVoice)
	{
		if(iAdminVoice == nadawca)
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, true);
			return FMRES_SUPERCEDE;
		}
		else if(iPlayerTeam[nadawca] == 1)
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
			return FMRES_SUPERCEDE;
		}
	}
	
	if(iPlayerTeam[nadawca] == 1 && !bPlayerMode[MIKRO])
	{
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	
	if(is_user_alive(odbiorca))
	{
		if(is_user_alive(nadawca))
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, true);
			return FMRES_SUPERCEDE;
		}
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public BlockUse(ent, id, activator, iType, Float:fValue)
{
	if(!is_user_connected(id) || id == activator)
	return HAM_IGNORED;
	
	if(szDayData[4] == 3 || szDayData[4] == iPlayerTeam[id] || bFight[id] || bFreeday[id])
	return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public BlockHeal(ent, id, activator, iType, Float:fValue)
{
	if(!is_user_connected(id))
	return HAM_IGNORED;
	
	if(szDayData[4] == 3 || szDayData[4] == iPlayerTeam[id] || bFight[id])
	return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public TouchWeapon(weapon, id)
{
	if(!is_user_connected(id))
	return HAM_IGNORED;
	
	if(bFreeday[id] || szDayData[4] == 3 || szDayData[4] == iPlayerTeam[id] || bFight[id])
	return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public BlockDrop(id)
{
	if(szDayData[4] == 3 || szDayData[4] == iPlayerTeam[id] || bFight[id])
	return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public PlayerDeath(id, attacker, shouldgib)
{	
	if(!is_user_connected(id)) return HAM_IGNORED;

	if(iPlayerTeam[id] == 1)
	{
		DelArray(id, ZYWI);
		
		if(is_user_connected(attacker) && iPlayerTeam[attacker] == 1) set_user_frags(attacker, get_user_frags(attacker)+2);
		
		if(iTeam[id] > 0)
		{
			iTeams[iTeam[id]]--;
			iTeam[id] = 0;
			CheckTeams();
		}
		
		RemoveWanted(id);
	}
	else if(iPlayerTeam[id] == 2)
	{	
		if(is_user_connected(attacker) && iPlayerTeam[attacker] == 1 && !bServiceGiven && !szDayData[2]) AddWanted(attacker);
		if(iLeader == id)
		{
			iLeader = 0;
			
			if(!bServiceGiven && !szDayData[2]) set_task(1.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
		}
	}
	
	if(iLastPrisoner)
	{
		for(new i=1; i<=MAX; i++)
		{
			if(is_user_alive(i))
			{	
				if(bFreeday[i] || bGhost[i])
				{
					bFreeday[i] = false;
					bGhost[i] = false;
					
					user_silentkill(i);
				}
			}
		}
	}
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "PlayerDeath");
	#endif
	return HAM_IGNORED;
}

public StatusShow(id)
{
	new pid = read_data(2), team = iPlayerTeam[pid]; 
	
	set_hudmessage(team == 1? 255: 0, 50, team == 1? 0: 255, -1.0, 0.9, 0, 0.01, 6.0);
	ShowSyncHudMsg(id, SyncHudObj1, "%s: %s [%i]", team == 1 ? "Wiezien": "Straznik", szPlayerName[pid], get_user_health(pid));
}

public StatusHide(id)
	ClearSyncHud(id, SyncHudObj1);

public msg_FlashLight(id)
{
	if(iPlayerTeam[id] == 1) return PLUGIN_HANDLED;	
	return PLUGIN_CONTINUE;
}

public msg_TextMsg()
{	
	new message[32];
	get_msg_arg_string(2, message, 31);
	
	if(equal(message, "#Game_teammate_attack") || equal(message, "#Killed_Teammate"))
	return PLUGIN_HANDLED;
	
	if(equal(message, "#Terrorists_Win"))
	{
		set_msg_arg_string(2, "Wiezniowie wygrali!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#CTs_Win"))
	{
		set_msg_arg_string(2, "Klawisze wygrali!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Round_Draw"))
	{
		set_msg_arg_string(2, "Runda remisowa!")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Only_1_Team_Change"))
	{
		set_msg_arg_string(2, "Dozwolona tylko 1 zmiana druzyny!")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_SemiAuto"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb pol-automatyczny")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_BurstFire"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb serii")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_FullAuto"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb automatyczny")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Game_Commencing"))
	{
		set_msg_arg_string(2, "Rozpoczecie Gry!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Cannot_Be_Spectator"))
	{
		set_msg_arg_string(2, "Nie mozesz byc obserwatorem");
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}	

public msg_StatusIcon(msgid, dest, id)
{
	new szIcon[8];
	get_msg_arg_string(2, szIcon, 7);
	
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	set_user_info(id, "_vgui_menus", "0");
	get_user_name(id, szPlayerName[id], 63);
	fPlayerSpeed[id] = 250.0;
	iReason[id] = random_num(0, sizeof szReasons - 1);
}

public client_disconnected(id)
{
	if(iLastPrisoner == id)
	iLastPrisoner = 0;
	
	if(iPlayerTeam[id] == 1)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	
	if(iAdminVoice == id)
	iAdminVoice = 0;
	
	if(iLeader == id)
	{
		iLeader = 0;
		set_task(1.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
	}
	
	iPlayerWeapons[id][0] = 0;
	iPlayerWeapons[id][1] = 0;
	bFight[id] = false;
	bFreeday[id] = false;
	bGhost[id] = false;
	bSetFreeday[id] = false;
	bSetFreeday[id] = false;
	iPlayerTeam[id] = 0;
	iReason[id] = -1;
	
	for(new i = 1; i <= MAX; i++) bMuted[i][id] = false;
	
	iPlayerTeam[id] = 0;
}

public client_infochanged(id) 
	get_user_info(id, "name", szPlayerName[id], 63);


public RoundRestart()
{
	bEraseSettings = true;
	bEraseEnd = true;
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "RoundRestart");
	#endif
	
	UsuwanieWydarzen();
}

public RoundEnd()
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "RoundEnd");
	#endif
	
	bEraseEnd = true;
	bWeaponsTime = false;
	UsuwanieWydarzen();
}

public PreRoundStart()
{	
	szInfo = "";
	szInfoPosz = "";
	szWanted = "";
	
	iLastPrisoner = 0;
	iLeader = 0;
	
	bFreezeTime = true;
	bEraseEnd = false;
	bServiceGiven = false;
	bShowOnce = false;
	bWeaponsTime = false;
	bGameChosen = false;
	bWishChosen = false;
	
	bPlayerMode[MIKRO] = true;
	bPlayerMode[WALKA] = false;
	bPlayerMode[FF_TT] = false;
	bPlayerMode[TT_GOD] = false;
	bPlayerMode[CT_GOD] = false;
	bPlayerMode[CT_NIE_MOZE_TT] = false;
	bPlayerMode[TT_NIE_MOZE_CT] = false;
	
	iTeams[1] = 0;
	iTeams[2] = 0;
	
	if(task_exists(ID_DZWIEK_POSZ)) remove_task(ID_DZWIEK_POSZ);
	if(task_exists(ID_LOS_PROWADZACY)) remove_task(ID_LOS_PROWADZACY);
	if(task_exists(ID_CZAS)) remove_task(ID_CZAS);
	if(task_exists(ID_FREZZ)) remove_task(ID_FREZZ);
	if(task_exists(ID_SPEED_FZ)) remove_task(ID_SPEED_FZ);
	if(task_exists(TASK_END)) remove_task(TASK_END);
	if(task_exists(ID_HUD)) remove_task(ID_HUD);
	
	for(new i = 0; i <= 10; i++) szDayData[i] = 0;
	
	if(bEraseSettings)
	{
		iJailDay = 0;
		bEraseSettings = false;
	}
	else iJailDay++;
	
	if(iJailDay)
	{
		iTimeStart = get_systime();
		
		#if defined SUNDAY_GAMES
		if(iJailDay%7 == 0 || iJailDay%7 == 6 || bWishGame) 
		{
			bSunday = true;
			
			if(bWishGame) bWishGame = false;
		}
		else bSunday = false;
		#else
		ForwardDayStartPre(iJailDay%7);
		#endif
	}
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "NewRound");
	#endif
}

UsuwanieWydarzen()
{
	for(new i=1; i<=MAX; i++)
	{	
		bPlayerVoted[i] = false;
		bFight[i] = false;
		bFight[i] = false;
		iWeaponsMenu[i][0] = false;
		iWeaponsMenu[i][1] = false;
		iPlayerTeam[i] = 0;
		aPlayers[WSZYSCY][i] = 0;
		aPlayers[ZYWI][i] = 0;
		fPlayerSpeed[i] = 250.0;
		
		if(bSetFreeday[i])
		{
			bSetFreeday[i] = false;
			bFreeday[i] = true;
		}
		else bFreeday[i] = false;
		
		if(bSetFreeday[i])
		{
			bSetFreeday[i] = false;
			bGhost[i] = true;
		}
		else bGhost[i] = false;
	}
	
	iPlayersCount[WSZYSCY] = 0;
	iPlayersCount[ZYWI] = 0;
	
	bGame = false;
	
	new Return_F;
	if(fRemoveData) ExecuteForward(fRemoveData, Return_F, iGameID);
}

public PostRoundStart()
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "RoundStart pre");
	#endif
	
	bFreezeTime = false;
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i)) continue;
		
		ChangePlayerSpeed(i);
	}
	
	set_task(60.0, "koniec_czasu", ID_CZAS);
	
	if(!iJailDay)
	{
		iTimeStart = get_systime();
		ForwardDayStartPre(iJailDay%7);
	}
	
	if(!iLeader && !szDayData[1]) set_task(1.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
	#if defined SUNDAY_GAMES
	if(bSunday) set_task(1.2, "StartGameVote");
	#endif
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "RoundStart post");
	#endif
}

ForwardDayStartPre(zabawa)
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "ForwardDayStartPre pre");
	#endif
	new dane[1], iRet, is_frezz = iFreezeTime-(get_systime()-iTimeStart), czas = iRoundTime+min(is_frezz, 0);

	ExecuteForward(fDayStartPre, iRet, zabawa, PrepareArray(szInfo, 255, 1), PrepareArray(szInfoPosz, 255, 1), PrepareArray(szDayData, 10, 1), czas);
	iGameID = zabawa;
	bGame = true;

	dane[0] = zabawa;
	
	if(is_frezz) set_task(is_frezz+0.1, "ForwardDayStartPost", ID_FREZZ, dane, 1);
	else ForwardDayStartPost(dane);
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "ForwardDayStartPre post - Game: %s", szInfo);
	#endif
}


public ForwardDayStartPost(zabawa[1])
{
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "ForwardDayStartPost pre");
	#endif
	new iRet;
	ExecuteForward(fDayStartPost, iRet, zabawa[0]);
	
	#if defined DEBUG
	log_to_file("jail_api_jailbreak.log", "ForwardDayStartPost - Game: %s", szInfo);
	#endif
}

public koniec_czasu()
	bWeaponsTime = true;

public LosujProwadzacego()
{
	if(!iLeader)
	{
		if(((iLeader = RandomCT()) > 0))
		{
			if(is_user_alive(iLeader))
			{
				set_pev(iLeader, pev_body, 1);
				set_user_rendering(iLeader, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 15);
			}
		}
	}
}

stock RandomCT()
{
	new CT_Player[MAX + 2], ile=0;
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || iPlayerTeam[i] != 2) continue;
		
		CT_Player[++ile] = i;
	}
	
	return CT_Player[(ile? random_num(1, ile): 0)];
}

public task_server()
{
	if(bEraseEnd) return;
	
	for(new id = 1; id <= MAX; id++)
	{
		if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		static szDay[256], Time, PlayerTeam;
		formatex(szDay, charsmax(szDay), "[Dzien %i - %s]", iJailDay, szWeekDays[iJailDay%7]);
		
		Time = get_timeleft();
		PlayerTeam = get_user_team(id);
		
		if(PlayerTeam == 1) formatex(szDay, charsmax(szDay), "%s^n[Siedzisz za: %s]", szDay, szReasons[iReason[id]]);
		if(iLeader) format(szDay, charsmax(szDay), "%s^n[Prowadzacy: %s]", szDay, szPlayerName[iLeader]);
		if(szInfo[0]) format(szDay, charsmax(szDay), "%s^n[Zabawa: %s]", szDay, szInfo);
		if(iTeam[id]) format(szDay, charsmax(szDay), "%s^n[Druzyna: %s]", szDay, szColor[iTeam[id]]);
		
		format(szDay, charsmax(szDay), "%s^n[Wiezienie: %s]", szDay, szMap);
		
		if(szNextMap[0]) format(szDay, charsmax(szDay), "%s^n[Kolejne: %s]", szDay, szNextMap);
		
		format(szDay, charsmax(szDay), "%s^n[Czas do zmiany: %d:%02d]", szDay, (Time / 60), (Time % 60));
		
		if(PlayerTeam == 2 && iPlayersCount[WSZYSCY] > 0) format(szDay, 255, "%s^n[Wiezniowe: %i / %i]", szDay, iPlayersCount[ZYWI], iPlayersCount[WSZYSCY]);
	
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.1);
		ShowSyncHudMsg(id, SyncHudObj2, szDay);
	
		if(szWanted[0])
		{
			set_hudmessage(255, 85, 85, 0.7, 0.15, 0, 0.01, 1.1);
			ShowSyncHudMsg(id, SyncHudObj3, "[Poszukiwani]%s", szWanted);
		}
		else if(szInfoPosz[0])
		{
			set_hudmessage(255, 255, 0, 0.7, 0.01, 0, 0.01, 1.1);
			ShowSyncHudMsg(id, SyncHudObj3, szInfoPosz);
		}
		
		if(!is_user_alive(id)) continue;
		
		if(PlayerTeam == 1)
		{
			if(bWeaponsTime && szDayData[0] == 1 && iLastPrisoner == id && !bShowOnce)
			{
				RemoveDaySettings();
				
				bServiceGiven = true;
				bShowOnce = true;
				
				MenuWishes(iLastPrisoner);
			}
			
			if(szDayData[6])
			{
				new PlayerPos[3];
				get_user_origin(id, PlayerPos);
				
				if(PlayerPos[0] == iLastPosition[id][0] && PlayerPos[1] == iLastPosition[id][1]) 
				{
					iPlayerAFK[id]++;	
					if(iPlayerAFK[id] == 15) 
					{
						client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 5.0, (1<<14));
					} 
					else if(iPlayerAFK[id] == 18) 
					{
						client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 10.0, (1<<14));
					}
					else if(iPlayerAFK[id] >= 20)
					{
						client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 20.0, (1<<14));
					}
				}
				else iPlayerAFK[id] = 0;
				
				iLastPosition[id][0] = PlayerPos[0];
				iLastPosition[id][1] = PlayerPos[1];
			}
		}
		else if(PlayerTeam == 2)
		{
			if(bWeaponsTime && !szDayData[0] && iLastPrisoner && iLeader == id && !bShowOnce)
			{
				menu_display(id, MenuLeader);
				
				RemoveDaySettings();
				
				bShowOnce = true;
			}
		}
	}
}

public GetTeam(id)
	return iTeam[id];

public SetTeams()
{
	static iCount = 1;
	
	for(new id = 1; id < 33; id++)
	{
		if(!is_user_alive(id) || !is_user_connected(id) || is_user_hltv(id) || cs_get_user_team(id) != CS_TEAM_T || bFreeday[id] || bGhost[id]) continue;
		
		iTeam[id] = iCount;
		iTeams[iCount]++;
		
		set_user_rendering(id, kRenderFxGlowShell, szColors[iCount][0], szColors[iCount][1], szColors[iCount][2], kRenderGlow, 20);
		set_user_health(id, 100);
		
		client_print_color(id, id, "^x04^x04[WIEZIENIE CS-RELOAD]^x01 Twoja aktualna druzyna to:^x04 %s", szColor[iTeam[id]]);
		
		iCount++;
	
		if(iCount > 2) iCount = 1;
	}
}

public CheckTeams()
{
	if(iTeams[1] > 1 && iTeams[2] == 0)
	{
		iTeams[1] = 0;
		iTeams[2] = 0;

		SetTeams();
	}
	
	if(iTeams[2] > 1 && iTeams[1] == 0)
	{
		iTeams[1] = 0;
		iTeams[2] = 0;

		SetTeams();
	}
	
	return PLUGIN_CONTINUE;
}

public RemoveDaySettings()
{
	if(bPlayerMode[WALKA])
	{
		bPlayerMode[WALKA] = false;
		
		if(is_user_alive(iLastPrisoner) && get_user_weapon(iLastPrisoner) == CSW_KNIFE)
		{
			set_pev(iLastPrisoner, pev_viewmodel2, szModels[V_PIESCI]);
			set_pev(iLastPrisoner, pev_weaponmodel2, szModels[P_PIESCI]);
		}
	}
	
	bPlayerMode[FF_TT] = false;
	bPlayerMode[TT_GOD] = false;
	bPlayerMode[CT_GOD] = false;
	bPlayerMode[CT_NIE_MOZE_TT] = false;
	bPlayerMode[TT_NIE_MOZE_CT] = false;
	
	szDayData[4] = 0;
	szDayData[6] = 0;
	szDayData[7] = 0;
	
	remove_task(TASK_END);
	
	for(new i = 1; i <= MAX; i++)
	{
		SetPlayerSpeed(i, -1.0);
		
		iTeam[i] = 0;
	}
}

public MenuWishService(id)
{
	if(iLeader != id || bServiceGiven || !iLastPrisoner || !bWeaponsTime) return PLUGIN_HANDLED;

	menu_display(id, MenuLeader);

	return PLUGIN_HANDLED;
}

public MenuWishService_Handle(id, menu, item)
{
	if(iLeader != id || !iLastPrisoner || !is_user_alive(id) || item == MENU_EXIT) return;

	switch(item)
	{
		case 0:
		{
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Obsluga wiezienia pozwolila wybrac zyczenie!");
			
			bServiceGiven = true;
			
			MenuWishes(iLastPrisoner);
		}
		case 1: client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Obsluga wiezienia zadecydowala ze wiezien nie ma zyczenia!");
	}
}

public ClientCommand_SelectKnife(id)
	engclient_cmd(id, "weapon_knife"); 

public OnAddToPlayerKnife(const item, const player)  
{  
	if(pev_valid(item) && is_user_alive(player)) 
	{  
		message_begin(MSG_ONE, 78, .player = player);
		{
			write_string(cs_get_user_team(player) == CS_TEAM_T ? "weapon_piesci": "weapon_palka"); 
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(-1);
			write_byte(2);
			write_byte(1);
			write_byte(CSW_KNIFE);
			write_byte(0);
		}
		
		message_end();  
	}  
} 

public BlockCommand()
	return PLUGIN_HANDLED;

public MenuSetCellButton(id)
{
	if(!(get_user_flags(id) & ADMIN_RCON)) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wUstaw \yprzycisk\w do cel:", "MenuSetCellButton_Handle");
	
	menu_additem(menu, "\rPrzycisk 1");
	menu_additem(menu, "\rPrzycisk 2 \y(jesli sa 2 przyciski do cel)");
	menu_additem(menu, "\rUsun Przyciski");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuSetCellButton_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: SaveCellButton(id, 0);
		case 1: SaveCellButton(id, 1);
		case 2:
		{
			if(szButtons[0])
			{
				new szFile[128];
				
				formatex(szFile, charsmax(szFile), "addons/amxmodx/data/cele/%s.ini", szMap);
				
				delete_file(szFile);
				
				szButtons[0] = 0;
				
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Usunieto przyciski!")
			}
			if(szButtons[1]) szButtons[1] = 0;
		}
	}
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

SaveCellButton(id, iLine)
{
	new iEnt, iBody;
	
	get_user_aiming(id, iEnt, iBody);
	
	if(!pev_valid(iEnt)) return;
	
	szButtons[iLine] = iEnt;
	
	new szFile[128], szTemp[128], szName[32], Float:fOrigin[3];
	
	get_brush_entity_origin(iEnt, fOrigin);
	pev(iEnt, pev_classname, szName, charsmax(szName));
	
	formatex(szTemp, charsmax(szTemp), "%f %f %f %s", fOrigin[0], fOrigin[1], fOrigin[2], szName);
	formatex(szFile, charsmax(szFile), "addons/amxmodx/data/cele/%s.ini", szMap);
	
	write_file(szFile, szTemp, iLine);
	
	client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Dodano^x03 %i^x01 przycisk.", iLine + 1);
}

public SetupButtons()
{
	new szClass[32], iEnt[3], Float:fOrigin[3], i;
	
	while((i < sizeof(szButtons)) && (iEnt[0] = engfunc(EngFunc_FindEntityByString, iEnt[0], "classname", "info_player_deathmatch")))
	{ 
		pev(iEnt[0], pev_origin, fOrigin);
		
		while((iEnt[1] = engfunc(EngFunc_FindEntityInSphere, iEnt[1], fOrigin, 300.0)))
		{ 
			if(!pev_valid(iEnt[1])) continue;
			
			pev(iEnt[1], pev_classname, szClass, charsmax(szClass));
			
			if(!equal(szClass, "func_door")) continue;
			
			pev(iEnt[1], pev_targetname, szClass, charsmax(szClass));
			
			iEnt[2] = engfunc(EngFunc_FindEntityByString, 0, "target", szClass);
			
			if(pev_valid(iEnt[2]) && (in_array(iEnt[2], szButtons, sizeof(szButtons)) < 0)) 
			{
				szButtons[i++] = iEnt[2]; 
				
				iEnt[1] = 0;
				iEnt[2] = 0;
				
				break;
			} 
		} 
	} 
}

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++) if(data[i] == needle) return i;
	
	return -1;
}

public OpenCells()
{
	//new ent = -1;
	
	//while((ent = fm_find_ent_by_class(ent, "func_door"))) dllfunc(DLLFunc_Use, ent, 0);

	for(new i = 0; i < sizeof(szButtons); i++)
	{
		if(!pev_valid(szButtons[i]) || !szButtons[i]) continue;
		
		ExecuteHam(Ham_Use, szButtons[i], 0, 0, 2, 1.0);
	}
}	

public AddArray(id, who)
{
	if(bFreeday[id] || bGhost[id] || aPlayers[who][id]) return;
	
	iLastPrisoner = (iPlayersCount[who] ? 0 : id);
	
	aPlayers[who][id] = id;
	iPlayersCount[who]++;
}

public DelArray(id, who)
{
	if(bFreeday[id] || bGhost[id] || !aPlayers[who][id]) return;
	
	aPlayers[who][id] = 0;
	iPlayersCount[who]--;
	
	if(who == ZYWI)
	{
		switch(iPlayersCount[ZYWI])
		{
			case 1:
			{ 
				for(new i = 1; i <= MAX; i++)
				{
					if(aPlayers[ZYWI][i])
					{
						iLastPrisoner = aPlayers[ZYWI][i];
						break;
					}
				}
			}
			default: iLastPrisoner = 0;
		}
	}
}

public AddWanted(attacker)
{
	if(contain(szWanted, szPlayerName[attacker]) == -1)
	{
		new szTemp[512];
		
		formatex(szTemp, charsmax(szTemp), "^n  %s%s", szPlayerName[attacker], szWanted);
		copy(szWanted, charsmax(szWanted), szTemp);
		
		if(!(get_user_flags(attacker) & ADMIN_LEVEL_H)) set_pev(attacker, pev_body, 4);
		
		set_user_rendering(attacker, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 15);
	}
	
	if(task_exists(ID_DZWIEK_POSZ)) remove_task(ID_DZWIEK_POSZ);
	
	SoundWanted();
	
	set_task(1.0, "SoundWanted", ID_DZWIEK_POSZ, .flags="a", .repeat=9);	
}

public SoundWanted()
	client_cmd(0, "spk jb_cypis/uciekinier.wav");

public RemoveWanted(id)
{
	if(contain(szWanted, szPlayerName[id]) != -1)
	{
		new szTemp[256];
		
		formatex(szTemp, charsmax(szTemp), "^n  %s", szPlayerName[id]);
		replace_all(szWanted, charsmax(szWanted), szTemp, "");
	}
}

stock ham_strip_weapon(id, wid)
{
	if(!wid) return 0;
	
	new szName[24], ent;
	
	get_weaponname(wid, szName, 23);
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", szName)) && pev(ent, pev_owner) != id) {}
	
	if(!ent) return 0;
	
	if(get_user_weapon(id) == wid)  ExecuteHam(Ham_Weapon_RetireWeapon, ent);
	
	if(ExecuteHam(Ham_RemovePlayerItem, id, ent)) 
	{
		ExecuteHam(Ham_Item_Kill, ent);
		
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wid));
	}
	
	return 1;
}

stock WhatPistol(id)
{
	if(!is_user_alive(id)) return 0;
	
	new szWeapons[32], iWeapon;
	
	get_user_weapons(id, szWeapons, iWeapon);
	
	for(new i = 0; i < iWeapon; i++) if((1<<szWeapons[i]) & 0x50FCF1A8) return szWeapons[i];
	
	return 0;
}

public BlockUse2(ent, id, activator, iType, Float:fValue)
{
	if(!is_user_alive(id) || id != activator) return HAM_IGNORED;
	
	if((get_gametime() - fWaitButton[id]) <= 1.0)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie spamuj guzikami!");
		
		return HAM_SUPERCEDE;
	}
	
	fWaitButton[id] = get_gametime();
	
	if(szDayData[4] != 3 && szDayData[4] != iPlayerTeam[id] && !bFight[id] && !bFreeday[id]) return HAM_IGNORED;
	
	new szClass[2][32];  
	
	pev(ent, pev_target, szClass[0], 31)        
	
	ent = -1;
	
	while((ent = fm_find_ent_by_tname(ent, szClass[0])))
	{
		pev(ent, pev_classname, szClass[1], 31);
		
		if(!equal(szClass[1], "game_player_equip") && !equal(szClass[1], "player_weaponstrip") && !equal(szClass[1], "multi_manager")) continue;
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public jail_set_game_hud_p(plugin, params) 
{	
	iHudCountdown = get_param(1);
	
	get_string(2, szHudMessage, 63);
	
	szHudData[0] = clamp(get_param(3), 0, 255);
	szHudData[1] = clamp(get_param(4), 0, 255);
	szHudData[2] = clamp(get_param(5), 0, 255);
	szHudData[3] = floatround(get_param_f(6)*100)
	szHudData[4] = floatround(get_param_f(7)*100)
	szHudData[5] = plugin;
	
	
	if(!szHudData[0] && !szHudData[1] && !szHudData[2])
	{
		szHudData[0] = 0;
		szHudData[1] = 127;
		szHudData[2] = 255;
	}
	
	if(!szHudData[3] && !szHudData[4])
	{
		szHudData[3] = 50;
		szHudData[4] = 70;
	}
	
	remove_task(ID_HUD, 1);
	
	TimesHud();
}

public TimesHud()
{
	new iRet;

	if(--iHudCountdown > 0)
	{
		new szTime[32], iFwdHandle = CreateOneForward(szHudData[5], "OnGameHudTick", FP_CELL, FP_CELL);
		
		ExecuteForward(iFwdHandle, iRet, iGameID, iHudCountdown);
		DestroyForward(iFwdHandle);
		
		format_time(szTime, 31, "%M:%S", iHudCountdown);
		
		set_hudmessage(szHudData[0], szHudData[1], szHudData[2], szHudData[3]/100.0, szHudData[4]/100.0, 0, 0.01, 1.0);
		show_hudmessage(0, "%s [%s]", szHudMessage, szTime);
		
		if(iHudCountdown <= 10)
		{
			new szWord[6];
			
			num_to_word(iHudCountdown, szWord, charsmax(szWord));
			
			client_cmd(0, "spk ^"%s^"", szWord);
		}
		
		set_task(1.0, "TimesHud", ID_HUD);
	}
	else 
	{
		new iFwdHandle = CreateOneForward(szHudData[5], "OnGameHudEnd", FP_CELL);
		
		ExecuteForward(iFwdHandle, iRet, iGameID);
		DestroyForward(iFwdHandle);
	}
}

Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed) ? Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}