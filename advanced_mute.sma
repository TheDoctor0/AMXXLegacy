#include <amxmodx>
#include <fakemeta>
#include <sqlx>

#define PLUGIN "Advanced Mute"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new const cmdMenu[][] = { "say /mute", "say_team /mute", "say /mutuj", "say_team /mutuj", "say /ucisz", "say_team /ucisz" };

new playerName[MAX_PLAYERS + 1][32], safePlayerName[MAX_PLAYERS + 1][32], Trie:playerMutes[MAX_PLAYERS + 1], playerId[MAX_PLAYERS + 1], Handle:sql, bool:sqlConnection;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	create_cvar("advanced_mute_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED);
	
	for (new i; i < sizeof(cmdMenu); i++) register_clcmd(cmdMenu[i], "menu_show");
	
	register_forward(FM_Voice_SetClientListening, "voice_listening");

	for (new id = 1; id <= MAX_PLAYERS; id++) playerMutes[id] = TrieCreate();
}

public plugin_cfg()
{
	new configPath[64];

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/advanced_mute.cfg", configPath);
	server_exec();

	sql_init();
}

public plugin_end()
	SQL_FreeHandle(sql);

public client_putinserver(id)
{
	get_user_name(id, playerName[id], charsmax(playerName[]));

	if (is_user_bot(id) || is_user_hltv(id)) return;

	sql_safe_string(playerName[id], safePlayerName[id], charsmax(safePlayerName[]));

	set_task(0.1, "load_mutes", id);
}

public client_disconnected(id)
	remove_task(id);

public menu_show(id)
{
	new menu = menu_create("\yMenu \rMutowania\w:", "menu_show_handle");

	menu_additem(menu, "\wZmutuj \yGracza");
	menu_additem(menu, "\wOdmutuj \yGracza");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public menu_show_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id)) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	item ? unmute_menu(id) : mute_menu(id);

	return PLUGIN_HANDLED;
}

public mute_menu(id)
{
	new players, menu = menu_create("\yWybierz gracza, ktorego chcesz \rzmutowac\w:", "mute_menu_handle");
	
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || TrieKeyExists(playerMutes[id], playerName[i]) || get_user_flags(i) & ADMIN_IMMUNITY) continue;

		menu_additem(menu, playerName[i]);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[MUTE]^x01 Na serwerze mie ma nikogo, kogo moglbys zmutowac!"); 
	else menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public mute_menu_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new name[32], tempData[1], access, callback;
	
	menu_item_getinfo(menu, item, access, tempData, charsmax(tempData), name, charsmax(name), callback);

	menu_destroy(menu);
	
	playerId[id] = get_user_index(name);

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}
	
	new menu = menu_create("\yWybierz \rtyp mute\w:", "mute_menu_type_handle");
	
	menu_additem(menu, "Na \yMape");
	menu_additem(menu, "Na \rZawsze");

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public mute_menu_type_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");
		
		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			TrieSetCell(playerMutes[id], playerName[playerId[id]], 0);
			
			client_print_color(id, id, "^x04[MUTE]^x01 Zmutowales^x04 na mape^x01 gracza^x03 %s^x01.", playerName[playerId[id]]);
		} case 1: {
			static queryData[128];

			formatex(queryData, charsmax(queryData), "INSERT INTO `advanced_mute` (`name`, `muted`) VALUES (^"%s^", ^"%s^");", safePlayerName[id], safePlayerName[playerId[id]]);

			SQL_ThreadQuery(sql, "ignore_handle", queryData);

			TrieSetCell(playerMutes[id], playerName[playerId[id]], 1);
			
			client_print_color(id, id, "^x04[MUTE]^x01 Zmutowales^x04 na zawsze^x01 gracza^x03 %s^x01.", playerName[playerId[id]]);
		}
	}

	return PLUGIN_HANDLED;
}

public unmute_menu(id)
{
	new menuData[64], itemData[8], players, type, menu = menu_create("\yWybierz gracza, ktorego chcesz \rodmutowac\w:", "unmute_menu_handle");

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || !TrieKeyExists(playerMutes[id], playerName[i])) continue;

		TrieGetCell(playerMutes[id], playerName[i], type);

		formatex(menuData, charsmax(menuData), "\w%s %s", playerName[i], type ? "\r[Na Zawsze]" : "\r[Na Mape]");
		formatex(itemData, charsmax(itemData), "%i#%i", i, type);

		menu_additem(menu, menuData, itemData);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[MUTE]^x01 Zaden z graczy na serwerze nie jest przez ciebie zmutowany!"); 
	else menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public unmute_menu_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new itemData[8], tempId[4], type[2], access, callback;
	
	menu_item_getinfo(menu, item, access, itemData, charsmax(itemData), _, _, callback);

	menu_destroy(menu);

	split(itemData, tempId, charsmax(tempId), type, charsmax(type), "#");

	playerId[id] = str_to_num(tempId);

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");
		
		return PLUGIN_HANDLED;
	}

	TrieDeleteKey(playerMutes[id], playerName[playerId[id]]);

	if (str_to_num(type)) {
		static queryData[128];

		formatex(queryData, charsmax(queryData), "DELETE FROM `advanced_mute` WHERE name = ^"%s^" AND mutes = ^"%s^");", safePlayerName[id], safePlayerName[playerId[id]]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	client_print_color(id, id, "^x04[MUTE]^x01 Odmutowales gracza^x03 %s^x01!", playerName[playerId[id]]); 
	
	return PLUGIN_HANDLED;
}

public voice_listening(receiver, sender, listen) 
{
	if (receiver == sender || !is_user_connected(sender)) return FMRES_IGNORED;
	
	if (TrieKeyExists(playerMutes[receiver], playerName[sender])) {
		engfunc(EngFunc_SetClientListening, receiver, sender, false);

		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], error[128], errorNum;
	
	get_cvar_string("advanced_mute_host", host, charsmax(host));
	get_cvar_string("advanced_mute_user", user, charsmax(user));
	get_cvar_string("advanced_mute_pass", pass, charsmax(pass));
	get_cvar_string("advanced_mute_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connection = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_amx("[MUTE] SQL Query Error: %s", error);
		
		return;
	}

	new queryData[128];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `advanced_mute` (`id` INT(11) AUTO_INCREMENT, `name` VARCHAR(32) NOT NULL, `muted` VARCHAR(32) NOT NULL, PRIMARY KEY(`id`));");  

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connection);

	sqlConnection = true;
}

public load_mutes(id)
{
	if (!sqlConnection) {
		set_task(1.0, "load_mutes", id);

		return;
	}

	static playerId[1], queryData[128];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `advanced_mute` WHERE name = ^"%s^"", safePlayerName[id]);
	
	SQL_ThreadQuery(sql, "load_mutes_handle", queryData, playerId, sizeof(playerId));
}

public load_mutes_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_amx("[MUTE] SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new muteName[32], id = playerId[0];
	
	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "muted"), muteName, charsmax(muteName));

		TrieSetCell(playerMutes[id], muteName, 1);

		SQL_NextRow(query);
	}
}

public ignore_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState == TQUERY_CONNECT_FAILED) log_amx("[MUTE] Could not connect to SQL database. [%d] %s", errorCode, error);
	else if (failState == TQUERY_QUERY_FAILED) log_amx("[MUTE] Query failed. [%d] %s", errorCode, error);
}

stock sql_safe_string(const source[], dest[], length)
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