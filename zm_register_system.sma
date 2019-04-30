#include <amxmodx>
#include <sqlx>
#include <fakemeta>

#define PLUGIN "ZM Accounts System"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define SETINFO "_csrpass"
#define CONFIG "csrpass"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

#define is_user_valid(%1) (1 <= %1 <= MAX_PLAYERS)

#define TASK_PASSWORD 1945

#define m_iMenuCode 205
#define OFFSET_LINUX 5
#define VGUI_JOIN_TEAM_NUM 2

new playerName[33][64], playerSafeName[33][64], playerPassword[33][33], playerTempPassword[33][33], 
	playerFails[33], playerStatus[33], Handle:sql, dataLoaded, autoLogin;

enum _:status { NOT_REGISTERED, NOT_LOGGED, LOGGED, GUEST };

enum _:queries { UPDATE, INSERT, DELETE };

new const accountStatus[status][] = { "Niezarejestrowany", "Niezalogowany", "Zalogowany", "Gosc" };

new const commandAccount[][] = { "say /haslo", "say_team /haslo", "say /password", "say_team /password", 
	"say /konto", "say_team /konto", "say /account", "say_team /account", "konto" };

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof commandAccount; i++) register_clcmd(commandAccount[i], "account_menu");
	
	register_clcmd("WPROWADZ_SWOJE_HASLO", "login_account");
	register_clcmd("WPROWADZ_WYBRANE_HASLO", "register_step_one");
	register_clcmd("POWTORZ_WYBRANE_HASLO", "register_step_two");
	register_clcmd("WPROWADZ_AKTUALNE_HASLO", "change_step_one");
	register_clcmd("WPROWADZ_NOWE_HASLO", "change_step_two");
	register_clcmd("POWTORZ_NOWE_HASLO", "change_step_three");
	register_clcmd("WPROWADZ_SWOJE_AKTUALNE_HASLO", "delete_account");

	register_forward(FM_PlayerPreThink, "player_prethink");
}

public plugin_natives()
	register_native("register_system_check", "_register_system_check");

public plugin_cfg()
	sql_init();

public plugin_end()
	SQL_FreeHandle(sql);

public client_connect(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return;

	playerPassword[id] = "";
	
	playerFails[id] = 0;
	
	playerStatus[id] = NOT_REGISTERED;

	rem_bit(id, dataLoaded);
	rem_bit(id, autoLogin);

	get_user_name(id, playerName[id], charsmax(playerName[]));
	
	mysql_escape_string(playerName[id], playerSafeName[id], charsmax(playerSafeName[]));
	
	load_account(id);
}

public client_disconnected(id)
	remove_task(id + TASK_PASSWORD);

public kick_player(id)
{
	id -= TASK_PASSWORD;
	
	if(is_user_connected(id)) server_cmd("kick #%d ^"Nie zalogowales sie w ciagu 60s!^"", get_user_userid(id));
}
public account_menu(id)
{
	if(!is_user_connected(id) || !is_user_valid(id)) return PLUGIN_HANDLED;

	if(!get_bit(id, dataLoaded))
	{
		remove_task(id);

		set_task(0.1, "account_menu", id);

		return PLUGIN_HANDLED;
	}

	if(!get_user_team(id) && playerStatus[id] == LOGGED)
	{
		engclient_cmd(id, "chooseteam");

		return PLUGIN_HANDLED;
	}

	if(playerStatus[id] <= NOT_LOGGED) if(!task_exists(id + TASK_PASSWORD)) set_task(60.0, "kick_player", id + TASK_PASSWORD);
	
	static menuData[192];

	formatex(menuData, charsmax(menuData), "\rSYSTEM REJESTRACJI^n^n\rNick: \w[\y%s\w]^n\rStatus: \w[\y%s\w]", playerName[id], accountStatus[playerStatus[id]]);
	
	if((playerStatus[id] == NOT_LOGGED || playerStatus[id] == LOGGED) && !get_bit(id, autoLogin)) format(menuData, charsmax(menuData),"%s^n\wWpisz w konsoli \ysetinfo ^"%s^" ^"twojehaslo^"^n\wSprawi to, ze twoje haslo bedzie ladowane \rautomatycznie\w.", menuData, SETINFO);

	new menu = menu_create(menuData, "account_menu_handle"), callback = menu_makecallback("account_menu_callback");
	
	menu_additem(menu, "\yLogowanie", _, _, callback);
	menu_additem(menu, "\yRejestracja^n", _, _, callback);
	menu_additem(menu, "\yZmien \wHaslo", _, _, callback);
	menu_additem(menu, "\ySkasuj \wKonto^n", _, _, callback);
	menu_additem(menu, "\yZaloguj jako \wGosc \r(NIEZALECANE)^n", _, _, callback);
	if(playerStatus[id] == LOGGED) menu_additem(menu, "\wWyjdz", _, _, callback);
 
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public account_menu_callback(id, menu, item)
{
	switch(item)
	{
		case 0: return playerStatus[id] == NOT_LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 1: return (playerStatus[id] == NOT_REGISTERED || playerStatus[id] == GUEST) ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 3: return playerStatus[id] == LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 4: return playerStatus[id] == NOT_REGISTERED ? ITEM_ENABLED : ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public account_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
		
	if(item == MENU_EXIT || item == 5)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0:
		{
			client_print_color(id, id, "^x04[ZM]^x01 Wprowadz swoje^x04 haslo^x01, aby sie^x04 zalogowac.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Wprowadz swoje haslo.");

			client_cmd(id, "messagemode WPROWADZ_SWOJE_HASLO");
		}
		case 1: 
		{
			client_print_color(id, id, "^x04[ZM]^x01 Rozpoczales proces^x04 rejestracji^x01. Wprowadz wybrane^x04 haslo^x01.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Wprowadz swoje haslo.");
	
			client_cmd(id, "messagemode WPROWADZ_WYBRANE_HASLO");

			remove_task(id + TASK_PASSWORD);
		}
		case 2:
		{
			client_print_color(id, id, "^x04[ZM]^x01 Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.");

			set_hudmessage(255, 128, 0, 0.22, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Wprowadz swoje aktualne haslo.");
			
			client_cmd(id, "messagemode WPROWADZ_AKTUALNE_HASLO");
		}
		case 3: 
		{
			client_print_color(id, id, "^x04[ZM]^x01 Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.");

			set_hudmessage(255, 128, 0, 0.22, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Wprowadz swoje aktualne haslo.");
			
			client_cmd(id, "messagemode WPROWADZ_SWOJE_AKTUALNE_HASLO");
		}
		case 4: 
		{
			client_print_color(id, id, "^x04[ZM]^x01 Zalogowales sie jako^x04 Gosc^x01. By zabezpieczyc swoj nick^x04 zarejestruj sie^x01.");

			set_hudmessage(0, 255, 0, -1.0, 0.9, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Zostales pomyslnie zalogowany jako Gosc.");
			
			remove_task(id + TASK_PASSWORD);
			
			playerStatus[id] = GUEST;
			
			engclient_cmd(id, "chooseteam");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public login_account(id)
{
	if(playerStatus[id] != NOT_LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;
	
	new password[33];
	
	read_args(password, charsmax(password));
	
	remove_quotes(password);

	if(!equal(playerPassword[id], password))
	{
		if(++playerFails[id] >= 3) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		client_print_color(id, id, "^x04[ZM]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", playerFails[id]);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}

	playerStatus[id] = LOGGED;

	playerFails[id] = 0;

	remove_task(id + TASK_PASSWORD);
	
	client_print_color(id, id, "^x04[ZM]^x01 Zostales pomyslnie^x04 zalogowany^x01. Zyczymy milej gry.");

	set_hudmessage(0, 255, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

	show_hudmessage(id, "Zostales pomyslnie zalogowany.");
	
	engclient_cmd(id, "chooseteam");
	
	return PLUGIN_HANDLED;
}

public register_step_one(id)
{
	if((playerStatus[id] != NOT_REGISTERED && playerStatus[id] != GUEST) || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(strlen(password) < 5)
	{
		client_print_color(id, id, "^x04[ZM]^x01 Haslo musi miec co najmniej^x04 5 znakow^x01.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Haslo musi miec co najmniej 5 znakow.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	copy(playerTempPassword[id], charsmax(playerTempPassword), password);
	
	client_print_color(id, id, "^x04[ZM]^x01 Teraz powtorz wybrane^x04 haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

	show_hudmessage(id, "Powtorz wybrane haslo.");
	
	client_cmd(id, "messagemode POWTORZ_WYBRANE_HASLO");
	
	return PLUGIN_HANDLED;
}
	
public register_step_two(id)
{
	if((playerStatus[id] != NOT_REGISTERED && playerStatus[id] != GUEST) || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;
	
	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(!equal(password, playerTempPassword[id]))
	{
		client_print_color(id, id, "^x04[ZM]^x01 Podane hasla^x04 roznia sie^x01 od siebie.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane hasla roznia sie od siebie.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}

	new menuData[192];
	
	formatex(menuData, charsmax(menuData), "\rPOTWIERDZENIE REJESTRACJI^n^n\wTwoj Nick: \y[\r%s\y]^n\wTwoje Haslo: \y[\r%s\y]", playerName[id], playerTempPassword[id]);

	new menu = menu_create(menuData, "register_confirmation_handle");
	
	menu_additem(menu, "\rPotwierdz \wRejestracje");
	menu_additem(menu, "\yZmien \wHaslo^n");
	menu_additem(menu, "\wAnuluj \wRejestracje");
 
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public register_confirmation_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	switch(item)
	{
		case 0:
		{
			playerStatus[id] = LOGGED;
			
			copy(playerPassword[id], charsmax(playerPassword[]), playerTempPassword[id]);

			account_query(id, INSERT);

			set_hudmessage(0, 255, 0, -1.0, 0.9, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Zostales pomyslnie zarejestrowany i zalogowany.");
	
			client_print_color(id, id, "^x04[ZM]^x01 Twoj nick zostal pomyslnie^x04 zarejestrowany^x01.");
			client_print_color(id, id, "^x04[ZM]^x01 Wpisz w konsoli komende^x04 setinfo ^"%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", SETINFO, playerPassword[id]);
	
			cmd_execute(id, "setinfo %s %s", SETINFO, playerPassword[id]);
			cmd_execute(id, "writecfg %s", CONFIG);
	
			engclient_cmd(id, "chooseteam");
		}
		case 1:
		{
			client_print_color(id, id, "^x04[ZM]^x01 Rozpoczales proces^x04 rejestracji^x01. Wprowadz wybrane^x04 haslo^x01.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

			show_hudmessage(id, "Wprowadz wybrane haslo.");
	
			client_cmd(id, "messagemode WPROWADZ_WYBRANE_HASLO");
		}
		case 2: account_menu(id);
	}
	
	return PLUGIN_HANDLED;
}

public change_step_one(id)
{
	if(playerStatus[id] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(!equal(playerPassword[id], password))
	{
		if(++playerFails[id] >= 3) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		client_print_color(id, id, "^x04[ZM]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", playerFails[id]);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	client_print_color(id, id, "^x04[ZM]^x01 Wprowadz swoje^x04 nowe haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

	show_hudmessage(id, "Wprowadz swoje nowe haslo.");

	client_cmd(id, "messagemode WPROWADZ_NOWE_HASLO");
	
	return PLUGIN_HANDLED;
}

public change_step_two(id)
{
	if(playerStatus[id] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(equal(playerPassword[id], password))
	{
		client_print_color(id, id, "^x04[ZM]^x01 Nowe haslo jest^x04 takie samo^x01 jak aktualne.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Nowe haslo jest takie samo jak aktualne.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	if(strlen(password) < 5)
	{
		client_print_color(id, id, "^x04[ZM]^x01 Nowe haslo musi miec co najmniej^x04 5 znakow^x01.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Nowe haslo musi miec co najmniej 5 znakow.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	copy(playerTempPassword[id], charsmax(playerTempPassword), password);
	
	client_print_color(id, id, "^x04[ZM]^x01 Powtorz swoje nowe^x04 haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

	show_hudmessage(id, "Powtorz swoje nowe haslo.");
	
	client_cmd(id, "messagemode POWTORZ_NOWE_HASLO");
	
	return PLUGIN_HANDLED;
}

public change_step_three(id)
{
	if(playerStatus[id] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;
	
	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(!equal(password, playerTempPassword[id]))
	{
		client_print_color(id, id, "^x04[ZM]^x01 Podane hasla^x04 roznia sie^x01 od siebie.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane hasla roznia sie od siebie.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	copy(playerPassword[id], charsmax(playerPassword[]), password);

	account_query(id, UPDATE);

	set_hudmessage(0, 255, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

	show_hudmessage(id, "Twoje haslo zostalo pomyslnie zmienione.");
	
	client_print_color(id, id, "^x04[ZM]^x01 Twoje haslo zostalo pomyslnie^x04 zmienione^x01.");
	client_print_color(id, id, "^x04[ZM]^x01 Wpisz w konsoli komende^x04 setinfo ^"%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", SETINFO, playerPassword[id]);
	
	cmd_execute(id, "setinfo %s %s", SETINFO, playerPassword[id]);
	cmd_execute(id, "writecfg %s", CONFIG);
	
	return PLUGIN_HANDLED;
}

public delete_account(id)
{
	if(playerStatus[id] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;
		
	new password[33];
	
	read_args(password, charsmax(password));
	remove_quotes(password);
	
	if(!equal(playerPassword[id], password))
	{
		if(++playerFails[id] >= 3) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));
		
		client_print_color(id, id, "^x04[ZM]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/3^x01)", playerFails[id]);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");
		
		account_menu(id);
		
		return PLUGIN_HANDLED;
	}
	
	new menuData[128];
	
	formatex(menuData, charsmax(menuData), "\wCzy na pewno chcesz \rusunac \wswoje konto?");

	new menu = menu_create(menuData, "delete_account_handle");
	
	menu_additem(menu, "\rTak");
	menu_additem(menu, "\wNie^n");
	menu_additem(menu, "\wWyjdz");
 
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public delete_account_handle(id, menu, item)
{
	if(item == 0)
	{
		account_query(id, DELETE);
		
		console_print(id, "==================================");
		console_print(id, "==========SYSTEM REJESTRACJI==========");
		console_print(id, "              Skasowales konto o nicku: %s", playerName[id]);
		console_print(id, "==================================");
		
		server_cmd("kick #%d ^"Konto zostalo usuniete!^"", get_user_userid(id));
	}
	
	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], queryData[128], error[128], errorNum;
	
	get_cvar_string("zp_sql_host", host, charsmax(host));
	get_cvar_string("zp_sql_user", user, charsmax(user));
	get_cvar_string("zp_sql_pass", pass, charsmax(pass));
	get_cvar_string("zp_sql_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("zm.log", "Error: %s", error);
		
		return;
	}
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `zm_accounts` (`name` VARCHAR(64), `pass` VARCHAR(33), PRIMARY KEY(`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

public load_account(id)
{
	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `zm_accounts` WHERE name = '%s'", playerSafeName[id]);
	SQL_ThreadQuery(sql, "load_account_handle", queryData, tempId, sizeof(tempId));
}

public load_account_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("zm.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "pass"), playerPassword[id], charsmax(playerPassword[]));
		
		if(!equal(playerPassword[id], ""))
		{
			new password[33], info[32];

			get_user_info(id, "name", info, charsmax(info));
		
			cmd_execute(id, "exec %s.cfg", CONFIG);
		
			get_user_info(id, SETINFO, password, charsmax(password));

			if(equal(playerPassword[id], password))
			{
				playerStatus[id] = LOGGED;
				
				set_bit(id, autoLogin);
			}
			else playerStatus[id] = NOT_LOGGED;

			cmd_execute(id, "exec config.cfg");
		}
	}

	set_bit(id, dataLoaded);

	if(playerStatus[id] < LOGGED) account_menu(id);
}

public account_query(id, type)
{
	if(!is_user_connected(id)) return;

	new queryData[128], password[33];

	mysql_escape_string(playerPassword[id], password, charsmax(password));

	switch(type)
	{
		case INSERT: formatex(queryData, charsmax(queryData), "INSERT INTO `zm_accounts` VALUES ('%s', '%s')", playerSafeName[id], password);
		case UPDATE: formatex(queryData, charsmax(queryData), "UPDATE `zm_accounts` SET pass = '%s' WHERE name = '%s'", password, playerSafeName[id]);
		case DELETE: formatex(queryData, charsmax(queryData), "DELETE FROM `zm_accounts` WHERE name = '%s'", playerSafeName[id]);
	}

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) 
	{
		if(failState == TQUERY_CONNECT_FAILED) log_to_file("zm.log", "Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("zm.log", "Query failed. [%d] %s", errorNum, error);
	}
	
	return PLUGIN_CONTINUE;
}

public _register_system_check(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id);
		
		return 0;
	}
	
	if(playerStatus[id] < LOGGED)
	{
		client_print_color(id, id, "^x04[ZM]^x01 Musisz sie^x03 zalogowac^x01, aby miec do tego dostep!");
		
		account_menu(id);
		
		return 0;
	}
	
	return 1;
}

stock cmd_execute(id, const text[], any:...) 
{
	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);
	
	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}