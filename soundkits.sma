#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "Sound Kits"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

new const soundCmds[][] = { "say /dzwieki", "say_team /dzwieki", "say /sounds", "say_team /sounds" };

enum _:soundData { SOUND_PRICE, SOUND_TYPE, SOUND_NAME[64], SOUND_PATH[128] };
enum _:soundTypes { SOUND_NONE = -1, SOUND_MP3, SOUND_WAV };

new Array:soundKits, Array:playerSoundKits[MAX_PLAYERS + 1], playerActiveSoundKit[MAX_PLAYERS + 1], playerName[MAX_PLAYERS + 1], soundKitsLoaded, Handle:sql;

native get_user_money(id);
native set_user_money(id, money);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("sound_kits_sql_host", "localhost", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("sound_kits_sql_user", "user", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("sound_kits_sql_pass", "password", FCVAR_SPONLY|FCVAR_PROTECTED);
	register_cvar("sound_kits_sql_db", "database", FCVAR_SPONLY|FCVAR_PROTECTED);

	for (new i = 0; i < sizeof soundCmds; i++) register_clcmd(soundCmds[i], "sound_kits");

	register_event("DeathMsg", "player_death", "a");
}

public plugin_precache()
{
	for (new id = 1; id <= MAX_PLAYERS; id++) playerSoundKits[id] = ArrayCreate(128);

	soundKits = ArrayCreate(128);

	new filePath[128];

	formatex(filePath[get_configsdir(filePath, charsmax(filePath))], charsmax(filePath), "/sound_kits.ini");

	if (!file_exists(filePath)) set_fail_state("[ERROR] Brak pliku sound_kits.ini.");

	new fileLine[256], soundPath[128], absoluteSoundPath[128], soundName[64], soundPrice[16], soundKit[soundData], fileOpen = fopen(filePath, "r");

	while (!feof(fileOpen)) {
		fgets(fileOpen, fileLine, charsmax(fileLine)); trim(fileLine);

		if (!fileLine[0] || fileLine[0] == ';' || fileLine[0] == '^0' || fileLine[0] == '/') continue;

		parse(fileLine, soundName, charsmax(soundName), soundPrice, charsmax(soundPrice), soundPath, charsmax(soundPath));

		format(absoluteSoundPath, charsmax(absoluteSoundPath), "sound/%s", soundPath);

		if (!file_exists(absoluteSoundPath)) {
			log_to_file("soundkits-error.log", "Plik %s nie istnieje.", absoluteSoundPath);

			continue;
		}

		new soundExtension = strlen(absoluteSoundPath) - 4;

		if (equal(absoluteSoundPath[soundExtension], ".mp3")) {
			formatex(soundKit[SOUND_PATH], charsmax(soundKit[SOUND_PATH]), absoluteSoundPath);

			precache_generic(soundKit[SOUND_PATH]);

			soundKit[SOUND_TYPE] = SOUND_MP3;
		} else if (equal(absoluteSoundPath[soundExtension], ".wav")) {
			formatex(soundKit[SOUND_PATH], charsmax(soundKit[SOUND_PATH]), soundPath);

			precache_sound(soundKit[SOUND_PATH]);

			soundKit[SOUND_TYPE] = SOUND_WAV;
		} else {
			log_to_file("soundkits-error.log", " Plik %s ma niewlasciwy format.", absoluteSoundPath);

			continue;
		}

		formatex(soundKit[SOUND_NAME], charsmax(soundKit[SOUND_NAME]), soundName);

		soundKit[SOUND_PRICE] = str_to_num(soundPrice);

		ArrayPushArray(soundKits, soundKit);
	}
}

public plugin_cfg()
{
	new configPath[128], error[128], host[32], user[32], pass[32], db[32], errorNum;

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/sound_kits.cfg", configPath);
	server_exec();

	get_cvar_string("sound_kits_sql_host", host, charsmax(host));
	get_cvar_string("sound_kits_sql_user", user, charsmax(user));
	get_cvar_string("sound_kits_sql_pass", pass, charsmax(pass));
	get_cvar_string("sound_kits_sql_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("soundkits-error.log", "SQL Error: %s (%i)", error, errorNum);

		return;
	}

	new queryData[192];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `sound_kits` (name VARCHAR(35), sound_kit VARCHAR(64), active INT NOT NULL DEFAULT 0, PRIMARY KEY(name, sound_kit));");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
}

public plugin_end()
	SQL_FreeHandle(sql);

public client_putinserver(id)
{
	ArrayClear(playerSoundKits[id]);

	playerActiveSoundKit[id] = SOUND_NONE;

	rem_bit(id, soundKitsLoaded);

	load_player_sound_kits(id);
}

public player_death()
{
	new killer = read_data(1), victim = read_data(2);

	if (!is_user_connected(killer) || !is_user_connected(victim) || killer == victim) return;

	if (playerActiveSoundKit[killer] > SOUND_NONE) {
		new soundKit[soundData], soundCommand[192];

		ArrayGetArray(soundKits, playerActiveSoundKit[killer], soundKit);

		formatex(soundCommand, charsmax(soundCommand), "%s %s", soundKit[SOUND_TYPE] == SOUND_MP3 ? "mp3 play" : "spk", soundKit[SOUND_PATH]);

		client_cmd(killer, soundCommand);
		client_cmd(victim, soundCommand);
	}
}

public sound_kits(id)
{
	if (!get_bit(id, soundKitsLoaded)) {
		client_print_color(id, id, "^x04[SOUND]^x01 Trwa ladowanie twoich danych.");

		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\wSound \yKits", "sound_kits_handle");

	menu_additem(menu, "\yKup \rSound Kit");
	menu_additem(menu, "\yUstaw \rSound Kit");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public sound_kits_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: buy_sound_kit(id);
		case 1: set_sound_kit(id);
	}

	return PLUGIN_HANDLED;
}

public buy_sound_kit(id)
{
	if (ArraySize(soundKits) == ArraySize(playerSoundKits[id])) {
		client_print_color(id, id, "^x04[SOUND]^x01 Posiadasz juz wszystkie dostepne^x03 sound kity^x01.");

		return PLUGIN_HANDLED;
	}

	new menuData[128], soundKitId[5], soundKit[soundData], menu = menu_create("\wKup \ySound Kit\y", "buy_sound_kit_handle");

	for (new i = 0; i < ArraySize(soundKits); i++) {
		ArrayGetArray(soundKits, i, soundKit);

		if (!has_sound_kit(id, i)) {
			formatex(menuData, charsmax(menuData), "%s \y(%i)", soundKit[SOUND_NAME], soundKit[SOUND_PRICE]);

			num_to_str(i, soundKitId, charsmax(soundKitId));

			menu_additem(menu, menuData, soundKitId);
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public buy_sound_kit_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new soundKit[soundData], menuTitle[128], itemData[5], itemAccess, itemCallback, soundKitId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	soundKitId = str_to_num(itemData);

	ArrayGetArray(soundKits, soundKitId, soundKit);

	formatex(menuTitle, charsmax(menuTitle), "\wSound Kit: \y%s", soundKit[SOUND_NAME]);

	new menu = menu_create(menuTitle, "buy_sound_kit_confirm_handle");

	menu_additem(menu, "\yKup \rSound Kit^n", itemData);
	menu_additem(menu, "\yOdsluchaj \rSound Kit^n", itemData);

	menu_additem(menu, "Wroc");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public buy_sound_kit_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if (item > 1) {
		menu_destroy(menu);

		buy_sound_kit(id);

		return PLUGIN_HANDLED;
	}

	new soundKit[soundData], itemData[5], itemAccess, itemCallback, soundKitId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	soundKitId = str_to_num(itemData);

	ArrayGetArray(soundKits, soundKitId, soundKit);

	if (!item) {
		if (get_user_money(id) < soundKit[SOUND_PRICE]) {
			client_print_color(id, id, "^x04[SOUND]^x01 Nie posiadasz wystarczajacych srodkow, aby zakupic ten^x03 sound kit^x01.");

			return PLUGIN_HANDLED;
		}

		set_user_money(id, get_user_money(id) - soundKit[SOUND_PRICE]);

		add_player_sound_kit(id, soundKitId);

		client_print_color(id, id, "^x04[SOUND]^x01 Kupiles sound kit:^x03 %s^x01.", soundKit[SOUND_NAME]);
	} else {
		client_cmd(id, "%s %s", soundKit[SOUND_TYPE] == SOUND_MP3 ? "mp3 play" : "spk", soundKit[SOUND_PATH]);

		client_print_color(id, id, "^x04[SOUND]^x01 Odtwarzam sound kit:^x03 %s^x01.", soundKit[SOUND_NAME]);
	}

	return PLUGIN_HANDLED;
}

public set_sound_kit(id)
{
	if (!ArraySize(playerSoundKits[id])) {
		client_print_color(id, id, "^x04[SOUND]^x01 Nie posiadasz zadnych^x03 sound kitow^x01.");

		return PLUGIN_HANDLED;
	}

	new menuData[128], soundKitId[5], soundKit[soundData], menu = menu_create("\wUstaw \ySound Kit\y", "set_sound_kit_handle");

	menu_additem(menu, "Wylacz", "-1");

	for (new i = 0; i < ArraySize(playerSoundKits[id]); i++) {
		ArrayGetArray(soundKits, ArrayGetCell(playerSoundKits[id], i), soundKit);

		formatex(menuData, charsmax(menuData), "%s \r%s", soundKit[SOUND_NAME], playerActiveSoundKit[id] == ArrayGetCell(playerSoundKits[id], i) ? "[AKTYWNY]" : "");

		num_to_str(i, soundKitId, charsmax(soundKitId));

		menu_additem(menu, menuData, soundKitId);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public set_sound_kit_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new soundKit[soundData], itemData[5], itemAccess, itemCallback, soundKitId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	soundKitId = str_to_num(itemData);

	if (soundKitId == SOUND_NONE) {
		client_print_color(id, id, "^x04[SOUND]^x01 Sound kit zostal^x03 wylaczony^x01.");

		return PLUGIN_HANDLED;
	}

	ArrayGetArray(soundKits, soundKitId, soundKit);

	set_player_sound_kit(id, soundKitId);

	client_print_color(id, id, "^x04[SOUND]^x01 Ustawiles sound kit:^x03 %s^x01.", soundKit[SOUND_NAME]);

	return PLUGIN_HANDLED;
}

public load_player_sound_kits(id)
{
	new playerId[1], queryData[128];

	playerId[0] = id;

	get_user_name(id, playerName[id], charsmax(playerName[]));

	mysql_safe_string(playerName[id], playerName[id], charsmax(playerName[]));

	formatex(queryData, charsmax(queryData), "SELECT * FROM `sound_kits` WHERE name = ^"%s^";", playerName[id]);

	SQL_ThreadQuery(sql, "load_player_sound_kits_handle", queryData, playerId, sizeof(playerId));
}

public load_player_sound_kits_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("soundkits-error.log", "SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0], soundKitName[64], soundKitId;

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "sound_kit"), soundKitName, charsmax(soundKitName));

		soundKitId = get_sound_kit_id(soundKitName);

		if (soundKitId > SOUND_NONE) {
			ArrayPushCell(playerSoundKits[id], soundKitId);

			if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "active"))) playerActiveSoundKit[id] = soundKitId;
		}
	}

	set_bit(id, soundKitsLoaded);
}

public add_player_sound_kit(id, soundKitId)
{
	if (!get_bit(id, soundKitsLoaded)) return;

	new soundKit[soundData], queryData[192], safeSoundKitName[64];

	ArrayGetArray(soundKits, soundKitId, soundKit);

	if (playerActiveSoundKit[id] == SOUND_NONE) playerActiveSoundKit[id] = soundKitId;

	ArrayPushCell(playerSoundKits[id], soundKitId);

	mysql_safe_string(soundKit[SOUND_NAME], safeSoundKitName, charsmax(safeSoundKitName));

	formatex(queryData, charsmax(queryData), "INSERT INTO `sound_kits` ('name', 'sound_kit') VALUES (^"%s^", ^"%s^");", playerName[id], safeSoundKitName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public set_player_sound_kit(id, soundKitId)
{
	if (!get_bit(id, soundKitsLoaded)) return;

	new soundKit[soundData], queryData[192], safeSoundKitName[64];

	ArrayGetArray(soundKits, soundKitId, soundKit);

	playerActiveSoundKit[id] = soundKitId;

	mysql_safe_string(soundKit[SOUND_NAME], safeSoundKitName, charsmax(safeSoundKitName));

	formatex(queryData, charsmax(queryData), "UPDATE `sound_kits` SET `active` = 1 WHERE `name` = ^"%s^" AND `sound_kit` = ^"%s^";", playerName[id], safeSoundKitName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("soundkits-error.log", "Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("soundkits-error.log", "Query failed. [%d] %s", errorNum, error);
	}

	return PLUGIN_CONTINUE;
}

stock has_sound_kit(id, soundKit)
{
	for (new i = 0; i < ArraySize(playerSoundKits[id]); i++) {
		if (ArrayGetCell(playerSoundKits[id], i) == soundKit) return true;
	}

	return false;
}

stock get_sound_kit_id(const soundKitName[])
{
	new soundKit[soundData];

	for (new i = 0; i < ArraySize(soundKits); i++) {
		ArrayGetArray(soundKits, i, soundKit);

		if (equal(soundKitName, soundKit[SOUND_NAME])) return i;
	}

	return -1;
}

stock mysql_safe_string(const source[], dest[], length)
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