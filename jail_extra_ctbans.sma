#include <amxmodx>
#include <amxmisc> 
#include <sqlx>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN "JailBreak: CT Bans"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define TASK_RESPAWN 9090
#define TASK_VOTE 8247

new Handle:g_SqlTuple, szTable[32], szMap[64], bool:CanRespawn, bool:FreezeTime, bool:HasBan[33], bool:SqlLoaded, TempID[33][2], Reason[33][64];

new Float:g_newround_time, Float:g_roundstart_time, Float:g_bombplanted_time, Float:g_freezetime, Float:g_roundtime, Float:g_c4timer;

new pCvarTime, pCvarCtToTT, sCvarTime, sCvarCtToTT;

new pcvar_roundtime, pcvar_freezetime, pcvar_c4timer;

new g_playtime = 1;

new bool:Vote, VoteID, bool:RecentlyVoted[33], VoteYes, VoteNo, MaxVotes, Trie:CTBan;

native jail_get_user_time(id);

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("jail_ctban_host", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_ctban_user", "511617", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_ctban_pass", "Ph5P3FSR4FVOc66A", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_ctban_database", "511617_jail", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("jail_ctban_table", "jail_ctbans", FCVAR_SPONLY|FCVAR_PROTECTED);
	
	sCvarTime = register_cvar("jail_ct_time", "1800");
	sCvarCtToTT = register_cvar("jail_tt_to_ct", "5");
	
	register_logevent("RoundStart", 2, "1=Round_Start");
	register_logevent("RoundEnd", 2, "1=Round_End");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("SendAudio","SendAudio","a","2=%!MRAD_BOMBPL");
	register_event("TextMsg", "Restart", "a", "2&#Game_C", "2&#Game_w");
	register_event("TeamInfo", "TeamAssign", "a");
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);

	register_clcmd("say /wyrzuc", "VoteBanCT");
	register_clcmd("say_team /wyrzuc", "VoteBanCT");
	register_clcmd("say /votect", "VoteBanCT");
	register_clcmd("say_team /votect", "VoteBanCT");
	
	register_clcmd("say /ctban", "MenuBanCT", ADMIN_KICK, "menu bana na granie w CT");
	register_clcmd("say_team /ctban", "MenuBanCT", ADMIN_KICK, "menu bana na granie w CT");

	register_concmd("jail_ctbanmenu", "MenuBanCT", ADMIN_KICK, "menu bana na granie w CT");
	register_concmd("jail_ctban", "CmdBanCT", ADMIN_KICK, "<nick/userid> <powod> - ban na granie w CT");

	register_clcmd("say /ctunban", "MenuUnBanCT", ADMIN_KICK, "menu bana na granie w CT");
	register_clcmd("say_team /ctunban", "MenuUnBanCT", ADMIN_KICK, "menu bana na granie w CT");

	register_concmd("jail_ctunbanmenu", "MenuUnBanCT", ADMIN_KICK, "menu unbana na granie w CT");
	register_concmd("jail_ctunban", "CmdUnBanCT", ADMIN_KICK, "<nick> - unban na granie w CT");

	register_clcmd("Powod", "MenuBanCT_Handler2");
	
	pcvar_roundtime = get_cvar_pointer("mp_roundtime");
	pcvar_freezetime = get_cvar_pointer("mp_freezetime");
	pcvar_c4timer = get_cvar_pointer("mp_c4timer");

	CTBan = TrieCreate();
	
	set_task(0.1, "SqlInit");
}

public plugin_cfg()
{
	pCvarCtToTT = max(1, get_pcvar_num(sCvarCtToTT));
	pCvarTime = get_pcvar_num(sCvarTime);
	
	SqlInit();
}

public SqlInit()
{
	new szHost[32], szUser[32], szPass[32], szDatabase[32], szTemp[256];
	get_cvar_string("jail_ctban_host", szHost, charsmax(szHost));
	get_cvar_string("jail_ctban_user", szUser, charsmax(szUser));
	get_cvar_string("jail_ctban_pass", szPass, charsmax(szPass));
	get_cvar_string("jail_ctban_database", szDatabase, charsmax(szDatabase));
	get_cvar_string("jail_ctban_table", szTable, charsmax(szTable));
	
	g_SqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDatabase);
	
	new Error, szError[128];
	new Handle:hConn = SQL_Connect(g_SqlTuple, Error, szError, 127);
	if(Error)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Error: %s", szError);
		return;
	}
	
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) AUTO_INCREMENT, `name` varchar(64) UNIQUE, `adminname` varchar(64), `sid` varchar(64), `reason` varchar(64), `map` varchar(64), `time` int(15), PRIMARY KEY (`id`))", szTable);
	
	new Handle:Query = SQL_PrepareQuery(hConn, szTemp);
	SQL_Execute(Query);
	SQL_FreeHandle(Query);
	SQL_FreeHandle(hConn);
	
	SqlLoaded = true;
	
	get_mapname(szMap, 63);
}
	
public client_putinserver(id)
{
	HasBan[id] = false;
	RecentlyVoted[id] = false;
	
	if(SqlLoaded) CheckBanCT(id);
	else set_task(1.0, "client_putinserver", id);
}

public client_disconnected(id)
	if(VoteID == id) VoteID = 0;

public Restart()
	g_playtime = 0;
	
public RoundEnd()
	g_playtime = 0;
	
public NewRound() 
{
	g_playtime = 1;
	
	FreezeTime = true;

	new Float:freezetime = get_pcvar_float(pcvar_freezetime);
	if(freezetime)
	{
		g_newround_time = get_gametime();
		g_freezetime = freezetime;
	}
	g_c4timer = get_pcvar_float(pcvar_c4timer);
	g_roundtime = floatmul(get_pcvar_float(pcvar_roundtime), 60.0) - 1.0;
}

public RoundStart()
{
	CanRespawn = true;
	
	FreezeTime = false;
	
	remove_task(TASK_RESPAWN);
	set_task(25.0, "BlockRespawn", TASK_RESPAWN);
	
	g_playtime = 2;
	g_roundstart_time = get_gametime();
}

public SendAudio() 
{
	g_playtime = 3;
	g_bombplanted_time = get_gametime();
}

public get_time_remaining() 
{
	switch(g_playtime)
	{
		case 0: return 0;
		case 1: return floatround( ( get_gametime() - g_newround_time ) - g_freezetime , floatround_ceil );
		case 2: return floatround( g_roundtime - ( get_gametime() - g_roundstart_time ) , floatround_ceil );
		case 3: return floatround( g_c4timer - ( get_gametime() - g_bombplanted_time ) , floatround_ceil );
	}
	
	return 0;
}

public BlockRespawn()
	CanRespawn = false;
	
public PlayerRespawn(id)
{
	id -= TASK_RESPAWN;
	
	if(is_user_connected(id)) ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public Spawn(id)
{
	if(get_time_remaining() <= 0 && !FreezeTime && get_playersnum() > 2)
	{
		user_silentkill(id);
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Blokada spawnu po czasie 0:00!");
		
		return PLUGIN_HANDLED;
	}
	
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT && HasBan[id])
	{
		user_silentkill(id);
		
		cs_set_user_team(id, CS_TEAM_T);
		
		if(CanRespawn) set_task(0.5, "PlayerRespawn", id + TASK_RESPAWN);
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Masz bana na gre jako^x03 Klawisz! Powod:^x03 %s^x01.", Reason[id]);
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Mozesz odwolac sie od nalozonego bana na naszym forum^x03 CS-Reload.pl^x01.");
	}
	return PLUGIN_HANDLED;
}

public TeamAssign()
{
	static iOldTeam[33];
	
	new szTeam[32], szName[32], iTeam, id = read_data(1);
	
	read_data(2, szTeam, 31);
	
	if(equal(szTeam,"UNASSIGNED")) iTeam = 0;
	else if(equal(szTeam,"TERRORIST")) iTeam = 1;
	else if(equal(szTeam,"CT")) iTeam = 2;
	else if(equal(szTeam,"SPECTATOR")) iTeam = 3;
	
	if(iOldTeam[id] == iTeam) return;
	
	iOldTeam[id] = iTeam;
	
	if(iTeam == 2)
	{
		get_user_name(id, szName, charsmax(szName));

		if(HasBan[id] || TrieKeyExists(CTBan, szName))
		{
			if(is_user_alive(id))
			{
				user_silentkill(id);
				cs_set_user_team(id, CS_TEAM_T);
			
				if(CanRespawn) set_task(0.5, "PlayerRespawn", id);
			}
			else cs_set_user_team(id, CS_TEAM_T);
		
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Masz bana na gre jako^x03 Klawisz! Powod:^x03 %s^x01.", Reason[id]);
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Mozesz odwolac sie od nalozonego bana na naszym forum^x03 CS-Reload.pl^x01.");
		}
		
		new iPlayers[2];
		
		iPlayers[1]--;
		iPlayers[0]++;
		
		for(new i = 1; i <= 32; i++)
		{
			if(!is_user_connected(i)) continue;
		
			switch(cs_get_user_team(i))
			{
				case 1: iPlayers[0]++;
				case 2: iPlayers[1]++;
			}
		}
		
		if(iPlayers[1] && (iPlayers[1] * pCvarCtToTT >= iPlayers[0]) && !(get_user_flags(id) & ADMIN_KICK))
		{
			if(is_user_alive(id)) 
			{
				user_silentkill(id);
				
				cs_set_user_team(id, CS_TEAM_T);
				
				if(CanRespawn) set_task(0.5, "PlayerRespawn", id + TASK_RESPAWN);
			}
			else cs_set_user_team(id, CS_TEAM_T);
			
			iOldTeam[id] = 1;

			engclient_cmd(id, "joinclass", "1");
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Druzyna^x03 Klawiszow^x01 jest pelna! Dolaczyles do druzyny^x03 Wiezniow^x01!");
			
			return;
		}
		
		new iTime = jail_get_user_time(id);
		
		if((iTime < pCvarTime) && !(get_user_flags(id) & ADMIN_KICK))
		{
			if(is_user_alive(id)) 
			{
				user_silentkill(id);
				
				cs_set_user_team(id, CS_TEAM_T);
				
				if(CanRespawn) set_task(0.5, "PlayerRespawn", id + TASK_RESPAWN);
			}
			else cs_set_user_team(id, CS_TEAM_T);
			
			iOldTeam[id] = 1;
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie masz wystarczajaco czasu gry, aby wejsc do druzyny^x03 Klawiszow^x01!");
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Masz^x03 %i^x01 z^x03 %i^x01 wymaganych minut w grze.", iTime/60, pCvarTime);
			
			return;
		}

		engclient_cmd(id, "joinclass", "1");
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Dolaczyles do druzyny^x03 Klawiszow^x01! Pamietaj, ze do prowadzenia wymagany jest^x03 mikrofon^x01!");
	}
}

public CheckBanCT(id)
{
	if(!is_user_connected(id)) return;

	new szTemp[256], szName[64], Data[1];
	get_user_name(id, szName, charsmax(szName));
	replace_all(szName, charsmax(szName), "'", "\'");
	replace_all(szName, charsmax(szName), "`", "\`");
	Data[0] = id;
	
	formatex(szTemp, charsmax(szTemp), "SELECT * FROM `%s` WHERE name = '%s'", szTable, szName);
	SQL_ThreadQuery(g_SqlTuple, "CheckBanCTIgnoreHandle", szTemp, Data, 1);
}

public CheckBanCTIgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Select - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		return PLUGIN_HANDLED;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Select Query failed. [%d] %s", ErrCode, Error);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	
	if(SQL_NumResults(Query) > 0) 
	{
		HasBan[id] = true;
		
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "reason"), Reason[id], charsmax(Reason[]));
	}

	return PLUGIN_HANDLED
}

public VoteBanCT(id)
{
	if(Vote)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Juz trwa glosowanie!");

		return PLUGIN_HANDLED;
	}

	new name[32], player[3], players, menu = menu_create("\rWiezienie CS-Reload \yKogo wyrzucamy z CT\w:", "VoteBanCT_Handler");
	
	for(new i = 1; i <= 32; i++)
	{
		get_user_name(i, name, charsmax(name));

		if(get_user_flags(i) & ADMIN_BAN)
		{
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Na serwerze znajduje sie admin. To jego zadaniem jest pilnowanie porzadku!");

			return PLUGIN_HANDLED;
		}

		if(is_user_connected(i) && i != id && !HasBan[i] && !TrieKeyExists(CTBan, name) && !(get_user_flags(i) & ADMIN_KICK))
		{
			num_to_str(i, player, charsmax(player));

			menu_additem(menu, name);

			players++;
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if(players) menu_display(id, menu);
	else client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 W CT nie ma zadnych graczy!");
	
	return PLUGIN_HANDLED;
}

public VoteBanCT_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[3], szName[32], access, callback;
	menu_item_getinfo(menu, item, access, data, 2, szName, 31, callback);
	
	VoteID = str_to_num(data);
	menu_destroy(menu);
	
	if(!is_user_connected(VoteID))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wybranego gracza nie ma juz na serwerze.");
		return PLUGIN_HANDLED;
	}
	
	if(RecentlyVoted[id])
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 W ciagu ostatnich 10 min bylo juz glosowanie o wyrzucenie tego gracza.");
		return PLUGIN_HANDLED;
	}

	StartVoteBan();

	return PLUGIN_HANDLED;
}

public StartVoteBan()
{
	VoteYes = 0;
	VoteNo = 0;

	Vote = true;

	new name[32], menuData[64];

	get_user_name(VoteID, name, charsmax(name));

	formatex(menuData, charsmax(menuData), "\wCzy chcesz wyrzucic gracza \y%s\w z CT?:")
	
	new menu = menu_create(menuData, "StartMapVote_Handler");
	
	menu_additem(menu, "\rTak");
	menu_additem(menu, "Nie");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	for(new i = 0; i <= 32; i++) if(is_user_connected(i) && !is_user_hltv(i) && !is_user_bot(i) && get_user_team(i) == 1) menu_display(i, menu, 0);
	
	set_task(15.0, "FinishVoteBan", menu);

	return PLUGIN_CONTINUE
}

public StartMapVote_Handler(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new name[32];
	get_user_name(id, name, charsmax(name));
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 zaglosowal na^x03 %s^x01.", name, item ? "NIE" : "TAK");

	if(!item) VoteYes++;
	else VoteNo++;

	menu_cancel(id);
	
	return PLUGIN_HANDLED;
}

public Finish_MapVote() 
{
	show_menu(0, 0, "^n", 1);

	if(!is_user_connected(VoteID))
	{
		client_print_color(0, VoteID, "^x04[WIEZIENIE CS-RELOAD]^x01 Gracza, o ktorego wyrzuceniu glosowano nie ma juz na serwerze^x01.");
	}

	new name[32];
	get_user_name(VoteID, name, charsmax(name));
	
	if(VoteYes > floatround(MaxVotes*0.5))
	{
		client_print_color(0, VoteID, "^x04[WIEZIENIE CS-RELOAD]^x01 Wiekszosc zdecydowala, aby wyrzucic gracza^x03 %s^x01 z CT^x01.", name);

		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Wiekszosc graczy zdecydowala, by zbanowac na gre jako Klawisz gracza %s do konca mapy.", name);

		if(cs_get_user_team(VoteID) == CS_TEAM_CT)
		{
			if(is_user_alive(VoteID))
			{
				user_silentkill(VoteID);
				cs_set_user_team(VoteID, CS_TEAM_T);
				
				if(CanRespawn) set_task(0.5, "PlayerRespawn", VoteID);
			}
			else cs_set_user_team(VoteID, CS_TEAM_T);
			
			client_print_color(VoteID, VoteID, "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales bana na gre jako^x03 Klawisz^x01 do konca mapy! Powod:^x03 Glosowanie^x01.");

			TrieSetCell(CTBan, name, 1);
		}
	}
	else
	{
		client_print_color(0, VoteID, "^x04[WIEZIENIE CS-RELOAD]^x01 Niewystarczajaca liczba graczy zaglosowala, aby wyrzucic gracza^x03 %s^x01 z CT^x01.", name);

		RecentlyVoted[VoteID] = true;

		set_task(300.0, "RemoveVoteBlock", VoteID + TASK_VOTE);
	}
}

public RemoveVoteBlock(id)
{
	id -= TASK_VOTE;

	RecentlyVoted[id] = false;
}

public MenuBanCT(id, level, cid)
{
	if(!(get_user_flags(id) & ADMIN_KICK)) 
	{
		console_print(id,"[CTBAN] Brak uprawnien!");
		return PLUGIN_HANDLED;
	}

	new menuData[64];
	if(get_user_flags(id) & ADMIN_BAN) formatex(menuData, charsmax(menuData), "\wWybierz\y Gracza\w, ktorego chcesz\r zbanowac\w na granie w CT:");
	else formatex(menuData, charsmax(menuData), "\wWybierz\y Gracza\w, ktorego chcesz\r zbanowac\w na granie w CT do konca mapy:");
	
	new menu = menu_create(menuData, "MenuBanCT_Handler");
	new player, players[32], num, szName[32], szTempID[3], online = 0;
	get_players(players, num);
	for(new i; i < num; i++)
	{
		player = players[i];
		
		if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && id != player && !(get_user_flags(player) & ADMIN_KICK))
		{
			get_user_name(player, szName, 31);
			num_to_str(player, szTempID, 2);
			menu_additem(menu, szName, szTempID, 0);
			online++;
		}
	}
		
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if(online) menu_display(id, menu);
	else client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Na serwerze nie ma nikogo, kogo moglbys zbanowac!"); 

	return PLUGIN_HANDLED;
}

public MenuBanCT_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[3], szName[32], access, callback;
	menu_item_getinfo(menu, item, access, data, 2, szName, 31, callback);
	
	TempID[id][0] = str_to_num(data);
	TempID[id][1] = get_user_userid(TempID[id][0]);
	menu_destroy(menu);
	
	if(!is_user_connected(TempID[id][0]))
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Wybranego gracza nie ma juz na serwerze.");
		return PLUGIN_HANDLED;
	}
	
	client_cmd(id, "messagemode Powod");
	client_print_color(id, id, "^x04[JailBreak]^x01 Wpisz^x03 powod^x01 bana na granie w CT dla podanego gracza!");
	return PLUGIN_HANDLED;
}

public MenuBanCT_Handler2(id, menu, item)
{
	if(!(get_user_flags(id) & ADMIN_KICK)) 
	{
		console_print(id, "[CTBAN] Brak uprawnien!");
		return PLUGIN_HANDLED;
	}
	
	new szArgs[64];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	
	if(equal(szArgs, ""))
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Nie wpisano powodu bana! Wpisz go teraz.");
		client_cmd(id, "messagemode Powod");
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_connected(TempID[id][0]))
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Wybranego gracza nie ma juz na serwerze.");
		return PLUGIN_HANDLED;
	}

	if(get_user_userid(TempID[id][0]) != TempID[id][1])
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Wybranego gracza nie ma juz na serwerze.");
		return PLUGIN_HANDLED;
	}
	
	BanCT(id, TempID[id][0], szArgs);
	return PLUGIN_HANDLED;
}

public CmdBanCT(id, level, cid) 
{
	if(!(get_user_flags(id) & ADMIN_KICK)) 
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Brak uprawnien!");
		return PLUGIN_HANDLED;
	}
	
	if(read_argc() < 2) 
	{ 
		client_print_color(id, id, "^x04[JailBreak]^x01 Podaj wszystkie argumenty!");
		return PLUGIN_HANDLED;
	}
	
	new user[64], reason[64];
	
	read_argv(1, user, 63);
	read_argv(2, reason, 63);
	
	new player = cmd_target(id, user, 7);
	
	if(!is_user_connected(player)) 
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Nie znaleziono podanego gracza!");
		return PLUGIN_HANDLED;
	}
	
	if(!reason[0])
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Nie podano powodu bana!");
		return PLUGIN_HANDLED;		
	}
	
	BanCT(id, player, reason);
	return PLUGIN_HANDLED;
}

public BanCT(id, player, reason[])
{
	if(!is_user_connected(player)) 
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Nie znaleziono podanego gracza!");
		return PLUGIN_HANDLED;
	}
		
	new szTemp[512], szName[64], szAdminName[64], szSID[33], szError[128], Error, MaxID;
	
	get_user_name(player, szName, charsmax(szName));
	get_user_name(id, szAdminName, charsmax(szAdminName));

	if(get_user_flags(id) & ADMIN_BAN)
	{
		replace_all(szName, charsmax(szName), "'", "\'");
		replace_all(szName, charsmax(szName), "`", "\`");
		replace_all(szAdminName, charsmax(szAdminName), "'", "\'");
		replace_all(szAdminName, charsmax(szAdminName), "`", "\`");
		get_user_authid(player, szSID, charsmax(szSID));
		
		new Handle:hConn = SQL_Connect(g_SqlTuple, Error, szError, 127);
		if(Error)
		{
			log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Error: %s", szError);
			return PLUGIN_CONTINUE;
		}
		
		formatex(szTemp, charsmax(szTemp), "SELECT MAX(`id`) FROM `%s`", szTable);
		new Handle:TQuery = SQL_PrepareQuery(hConn, szTemp);
		if(SQL_Execute(TQuery) == 1)
			MaxID = SQL_ReadResult(TQuery, 0) + 1;
		
		formatex(szTemp, charsmax(szTemp), "INSERT IGNORE INTO `%s` (`name`, `sid`, `adminname`, `reason`, `map`, `time`) VALUES ('%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP())", szTable, szName, szSID, szAdminName, reason, szMap);
		new Handle:Query = SQL_PrepareQuery(hConn, szTemp);
		
		if(SQL_Execute(Query) == 1)
		{
			if(SQL_GetInsertId(Query) != MaxID)
			{
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ten gracz ma juz bana na gre jako Klawisz!");
				return PLUGIN_CONTINUE;
			}
			replace_all(szName, charsmax(szName), "\'", "'");
			replace_all(szName, charsmax(szName), "\`", "`");
			
			log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Admin %s zbanowal na gre jako Klawisz gracza %s za %s.", szAdminName, szName, reason);
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zbanowales gracza^x03 %s^x01 na gre jako Klawisz za^x03 %s^x01!", szName, reason);
		
			set_hudmessage(0, 255, 0, 0.35, 0.1, 0, 6.0, 7.0);
			show_hudmessage(0, "%s dostal bana na gre jako Klawisz za %s!", szName, reason);
		
			formatex(Reason[id], charsmax(Reason[]), "%s", reason);
			HasBan[player] = true;
			
			if(cs_get_user_team(player) == CS_TEAM_CT)
			{
				if(is_user_alive(player))
				{
					user_silentkill(player);
					cs_set_user_team(player, CS_TEAM_T);
					
					if(CanRespawn) set_task(0.5, "PlayerRespawn", player);
				}
				else cs_set_user_team(player, CS_TEAM_T);
				
				client_print_color(player, player, "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales bana na gre jako^x03 Klawisz^x01! Powod:^x03 %s^x01.", Reason[id]);
				client_print_color(player, player, "^x04[WIEZIENIE CS-RELOAD]^x01 Mozesz odwolac sie od nalozonego bana na naszym forum^x03 CS-Reload.pl^x01.");
			}
		}
		SQL_FreeHandle(hConn);
		SQL_FreeHandle(TQuery);
		SQL_FreeHandle(Query);
	}
	else
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Straznik %s zbanowal na gre jako Klawisz do konca mapy gracza %s za %s.", szAdminName, szName, reason);
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zbanowales gracza^x03 %s^x01 na gre jako Klawisz do konca mapy za^x03 %s^x01!", szName, reason);
	
		set_hudmessage(0, 255, 0, 0.35, 0.1, 0, 6.0, 7.0);
		show_hudmessage(0, "%s dostal bana na gre jako Klawisz do konca mapy za %s!", szName, reason);
	
		TrieSetCell(CTBan, szName, 1);
		
		if(cs_get_user_team(player) == CS_TEAM_CT)
		{
			if(is_user_alive(player))
			{
				user_silentkill(player);
				cs_set_user_team(player, CS_TEAM_T);
				
				if(CanRespawn) set_task(0.5, "PlayerRespawn", player);
			}
			else cs_set_user_team(player, CS_TEAM_T);
			
			client_print_color(player, player, "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales bana na gre jako^x03 Klawisz^x01 do konca mapy! Powod:^x03 %s^x01.", reason);
			client_print_color(player, player, "^x04[WIEZIENIE CS-RELOAD]^x01 Mozesz odwolac sie od nalozonego bana na naszym forum^x03 CS-Reload.pl^x01.");
		}
	}

	return PLUGIN_HANDLED;
}

public MenuUnBanCT(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK)) 
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Brak uprawnien!");
		return PLUGIN_HANDLED;
	}
	
	new Data[1], szTemp[128];
	Data[0] = id;
	formatex(szTemp, 128, "SELECT * FROM `%s` ORDER BY `id` DESC LIMIT 50", szTable);
	SQL_ThreadQuery(g_SqlTuple, "MenuUnBanCTIgnoreHandle", szTemp, Data, 1);
	return PLUGIN_HANDLED;
}

public MenuUnBanCTIgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Select - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		return PLUGIN_HANDLED;
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Select Query failed. [%d] %s", ErrCode, Error);
		return PLUGIN_HANDLED;
	}
	
	new id = Data[0];
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	new menu = menu_create("\wWybierz\y Gracza\w, ktorego chcesz\r odbanowac\w na granie w CT:", "MenuUnBanCT_Handler");
	new szName[64], szReason[64], szItem[128], online;
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "name"), szName, 63);
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "reason"), szReason, 63);
		formatex(szItem, 127, "\y%s \w- Powod: \r%s", szName, szReason);
		menu_additem(menu, szItem, szName, 0);
		SQL_NextRow(Query);
	}
	if(!online)
		client_print_color(id, id, "^x04[JailBreak]^x01 W bazie nie ma nikogo, kogo moglbys odbanowac!"); 
		
	menu_setprop(menu, MPROP_BACKNAME, "Wroc")
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej")
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie")
	menu_display(id, menu)
	return PLUGIN_HANDLED
}

public MenuUnBanCT_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szTemp[32], access, callback;
	menu_item_getinfo(menu, item, access, szName, 31, szTemp, 31, callback);
	
	UnBanCT(id, szName);

	menu_destroy(menu);
	return PLUGIN_HANDLED
}

public CmdUnBanCT(id, level, cid)
{
	if(!(get_user_flags(id) & ADMIN_KICK)) 
	{
		client_print_color(id, id, "^x04[JailBreak]^x01 Brak uprawnien!");
		return PLUGIN_HANDLED;
	}
	
	new szName[32];
	read_argv(1, szName, 31);
	
	if(!szName[0]) 
	{ 
		client_print_color(id, id, "^x04[JailBreak]^x01 Podaj nick gracza do odbanowania!");
		return PLUGIN_HANDLED;
	}

	UnBanCT(id, szName);
	return PLUGIN_HANDLED;
}

public UnBanCT(id, szName[])
{
	new szPlayerName[64], szAdminName[64], szTemp[256], szError[128], Error;
	get_user_name(id, szAdminName, charsmax(szAdminName));
	formatex(szPlayerName, charsmax(szPlayerName), szName);
	replace_all(szPlayerName, charsmax(szPlayerName), "'", "\'");
	replace_all(szPlayerName, charsmax(szPlayerName), "`", "\`");

	new Handle:hConn = SQL_Connect(g_SqlTuple, Error, szError, 127);
	if(Error)
	{
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Error: %s", szError);
		return PLUGIN_CONTINUE;
	}
	formatex(szTemp, charsmax(szTemp), "DELETE FROM `%s` WHERE name = '%s'", szTable, szPlayerName);
	new Handle:Query = SQL_PrepareQuery(hConn, szTemp);
	
	if(SQL_Execute(Query) == 1)
	{
		if(SQL_AffectedRows(Query) > 0)
		{
			replace_all(szPlayerName, charsmax(szPlayerName), "\'", "'");
			replace_all(szPlayerName, charsmax(szPlayerName), "\`", "`");
				
			client_print_color(id, id, "^x04[JailBreak]^x01 Gracz^x03 %s^x01 zostal pomyslnie odbanowany na granie w CT!", szPlayerName);
			log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Admin %s odbanowal na granie w CT gracza %s.", szAdminName, szPlayerName);
			
			new player = cmd_target(id, szPlayerName, 7); 
			if(is_user_connected(player))
				HasBan[player] = false;
		}
		else
			client_print_color(id, id, "^x04[JailBreak]^x01 Nie znaleziono gracza o podanym nicku!");
	}
	else
	{
		SQL_QueryError(Query, szError, 127);
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Error: %s", szError);
		client_print_color(id, id, "^x04[JailBreak]^x01 Wystapil blad podczas zdejmowania bana z gracza!");
	}
	SQL_FreeHandle(hConn);
	SQL_FreeHandle(Query);
	return PLUGIN_HANDLED;
}

public IgnoreHandle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Could not connect to SQL database.  [%d] %s", ErrCode, Error);
	else if(FailState == TQUERY_QUERY_FAILED)
		log_to_file("addons/amxmodx/logs/jail_ctban.txt", "Query failed. [%d] %s", ErrCode, Error);
}