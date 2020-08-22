#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>

#define PLUGIN  "Voice Manager"
#define VERSION "1.0.1"
#define AUTHOR  "O'Zone"

#define TASK_INFO 3872
#define TASK_MUTES 4319
#define TASK_CHECK 5604

#define get_team(%0) get_pdata_int(%0, 114, 5)

new const cmdMenuPlayer[][] = { "say /mute", "say_team /mute", "say /mutuj", "say_team /mutuj", "say /ucisz", "say_team /ucisz", "say /unmute", "say_team /unmute", "say /odmutuj", "say_team /odmutuj" };
new const cmdMenuAdmin[][] = { "amx_mute", "amx_unmute", "amx_mute_menu", "amx_unmute_menu", "amx_gag", "amx_ungag" };
new const cmdVoiceStatus[][] = { "say /vm", "say_team /vm", "say /voice", "say_team /voice", "say /glos", "say_team /glos" };

enum _:menus { MENU_PLAYER, MENU_ADMIN };
enum _:data { bool:INFO, bool:INFO_USED, bool:ALIVE, bool:INTER_VOICE, bool:LISTEN, bool:MUTED, Trie:MUTES, PLAYER, MENU, SETTINGS[2], IP[16], NAME[32], STEAMID[35], SAFE_NAME[64] };

new playerData[MAX_PLAYERS + 1][data], cvarHost[32], cvarUser[32], cvarPassword[32], cvarDatabase[32], cvarAlive, cvarDead, cvarInfoTime, cvarAdminMuteMenu, cvarPlayerMuteMenu,
	cvarAdminVoice, cvarAdminVoiceOverride, cvarAdminListen, cvarAdminInterVoice, adminVoice, Trie:mutes, Handle:sql, bool:sqlConnection;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("vm_version", VERSION, FCVAR_SERVER);

	bind_pcvar_string(create_cvar("vm_sql_host", "127.0.0.1", FCVAR_SPONLY|FCVAR_PROTECTED), cvarHost, charsmax(cvarHost));
	bind_pcvar_string(create_cvar("vm_sql_user", "user", FCVAR_SPONLY|FCVAR_PROTECTED), cvarUser, charsmax(cvarUser));
	bind_pcvar_string(create_cvar("vm_sql_pass", "password", FCVAR_SPONLY|FCVAR_PROTECTED), cvarPassword, charsmax(cvarPassword));
	bind_pcvar_string(create_cvar("vm_sql_db", "database", FCVAR_SPONLY|FCVAR_PROTECTED), cvarDatabase, charsmax(cvarDatabase));

	bind_pcvar_num(create_cvar("vm_alive", "0"), cvarAlive); // 0: Alive teammates | 1: Alive players | 2: All teammates | 3: All players (Default: 0)
	bind_pcvar_num(create_cvar("vm_dead", "1"), cvarDead); // 0: Dead teammates | 1: Dead players | 2: All teammates | 3: All players (Default: 1)
	bind_pcvar_num(create_cvar("vm_info_time", "5"), cvarInfoTime); // Time in seconds for player to give info to his team - 0 to disable (Default: 5)
	bind_pcvar_num(create_cvar("vm_admin_mute_menu", "1"), cvarAdminMuteMenu); // Admin mute menu for blocking voice/chat globally for players - 0 to disable (Default: 1)
	bind_pcvar_num(create_cvar("vm_player_mute_menu", "1"), cvarPlayerMuteMenu); // Player mute menu for blocking other players voice by themself - 0 to disable (Default: 1)
	bind_pcvar_num(create_cvar("vm_admin_voice", "1"), cvarAdminVoice); // Admin command for talking to all players despite dead/alive settings - 0 to disable (Default: 1)
	bind_pcvar_num(create_cvar("vm_admin_voice_override", "1"), cvarAdminVoiceOverride); // Override players settings so even players with disabled sound receive will hear admin - 0 to disable (Default: 1)
	bind_pcvar_num(create_cvar("vm_admin_intervoice", "1"), cvarAdminInterVoice); // Admins voice chat - 0 to disable (Default: 1)
	bind_pcvar_num(create_cvar("vm_admin_listen", "1"), cvarAdminListen); // Admin command for listening to all players despite dead/alive settings - 0 to disable (Default: 1)

	for (new i; i < sizeof(cmdMenuPlayer); i++) register_clcmd(cmdMenuPlayer[i], "menu_player");
	for (new i; i < sizeof(cmdMenuAdmin); i++) register_clcmd(cmdMenuAdmin[i], "menu_admin");
	for (new i; i < sizeof(cmdVoiceStatus); i++) register_clcmd(cmdVoiceStatus[i], "voice_status");

	register_clcmd("+adminvoice", "admin_voice_on");
	register_clcmd("-adminvoice", "admin_voice_off");

	register_clcmd("+interadminvoice", "admin_intervoice_on");
	register_clcmd("-interadminvoice", "admin_intervoice_off");

	register_clcmd("+adminlisten", "admin_listen_on");
	register_clcmd("-adminlisten", "admin_listen_off");

	register_clcmd("say", "say_handle");
	register_clcmd("say_team", "say_handle");

	register_forward(FM_Voice_SetClientListening, "set_client_listening");

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	register_event("DeathMsg", "player_die", "ae");
	register_event("VoiceMask", "voice_mask", "b");
}

public plugin_cfg()
{
	for (new id = 1; id <= MAX_PLAYERS; id++) playerData[id][MUTES] = TrieCreate();

	mutes = TrieCreate();

	server_cmd("sv_alltalk 1;alias sv_alltalk");
	server_exec();

	sql_init();
}

public plugin_end()
{
	for (new id = 1; id <= MAX_PLAYERS; id++) TrieDestroy(playerData[id][MUTES]);

	TrieDestroy(mutes);

	SQL_FreeHandle(sql);
}

public client_putinserver(id)
{
	TrieClear(playerData[id][MUTES]);

	for (new i = INFO; i <= MUTED; i++) playerData[id][i] = false;

	if (is_user_hltv(id) || is_user_bot(id)) return;

	get_user_ip(id, playerData[id][IP], charsmax(playerData[][IP]), 1);
	get_user_name(id, playerData[id][NAME], charsmax(playerData[][NAME]));
	get_user_authid(id, playerData[id][STEAMID], charsmax(playerData[][STEAMID]));
	sql_safe_string(playerData[id][NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	set_task(0.1, "check_if_player_muted", id + TASK_CHECK);
	set_task(0.1, "load_player_mutes", id + TASK_MUTES);
}

public client_disconnected(id)
{
	remove_task(id + TASK_INFO);
	remove_task(id + TASK_CHECK);
	remove_task(id + TASK_MUTES);
}

public menu_player(id)
{
	if (!cvarPlayerMuteMenu || !sqlConnection) return PLUGIN_CONTINUE;

	menu_show(id, MENU_PLAYER);

	return PLUGIN_HANDLED;
}

public menu_admin(id)
{
	if (!cvarAdminMuteMenu || !sqlConnection || !(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_CONTINUE;

	menu_show(id, MENU_ADMIN);

	return PLUGIN_HANDLED;
}

public menu_show(id, type)
{
	if (!sqlConnection) return;

	playerData[id][MENU] = type;

	new menu = menu_create("\yMenu \rMutowania\w:", "menu_show_handle");

	menu_additem(menu, "\wZmutuj \yGracza");
	menu_additem(menu, "\wOdmutuj \yGracza");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
}

public menu_show_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	item ? menu_unmute(id) : menu_mute(id);

	return PLUGIN_HANDLED;
}

public menu_mute(id)
{
	new players, menu = menu_create("\yWybierz \wgracza\y, ktorego chcesz \rzmutowac\w:", "menu_mute_handle");

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (id == i || !is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

		if (playerData[id][MENU] == MENU_PLAYER && TrieKeyExists(playerData[id][MUTES], playerData[i][NAME])) continue;
		else if (playerData[id][MENU] == MENU_ADMIN && (TrieKeyExists(mutes, playerData[i][NAME]) || playerData[i][MUTED] || (get_user_flags(id) & ADMIN_BAN))) continue;

		menu_additem(menu, playerData[i][NAME]);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[GLOS]^x01 Na serwerze nie ma nikogo, kogo moglbys zmutowac!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public menu_mute_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new name[32], tempData[1], access, callback;

	menu_item_getinfo(menu, item, access, tempData, charsmax(tempData), name, charsmax(name), callback);

	menu_destroy(menu);

	playerData[id][PLAYER] = get_user_index(name);

	if (!is_user_connected(playerData[id][PLAYER])) {
		client_print_color(id, id, "^x04[GLOS]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\yWybierz \rtyp mute\w:", "menu_mute_type_handle");

	menu_additem(menu, "Na \yMape");
	menu_additem(menu, "Na \rZawsze");

	if (playerData[id][MENU] == MENU_ADMIN) menu_addtext(menu, "^n\wBan \rna mape\w jest nakladany na \yNick\w.^nBan \rna zawsze\w jest nakladany na \yNick + SteamID + IP\w.", 0);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public menu_mute_type_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new player = playerData[id][PLAYER];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "^x04[GLOS]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			if (playerData[id][MENU] == MENU_ADMIN) {
				TrieSetCell(mutes, playerData[player][NAME], 0);

				client_print_color(0, player, "^x04[GLOS]^x01 Gracz^x03 %s^x01 zostal zmutowany do konca^x04 mapy^x01.", playerData[player][NAME]);

				log_to_file("voice_manager.log", "Admin %s zmutowal do konca mapy gracza %s", playerData[id][NAME], playerData[player][NAME]);
			} else {
				TrieSetCell(playerData[id][MUTES], playerData[player][NAME], 0);

				client_print_color(id, player, "^x04[GLOS]^x01 Zmutowales gracza^x03 %s^x01 do konca^x04 mapy^x01.", playerData[player][NAME]);
			}
		} case 1: {
			static queryData[192];

			if (playerData[id][MENU] == MENU_ADMIN) {
				playerData[player][MUTED] = true;

				TrieSetCell(mutes, playerData[player][NAME], 1);

				formatex(queryData, charsmax(queryData), "INSERT INTO `voice_manager` (`name`, `muted`) VALUES ('', ^"%s^"), ('', ^"%s^"), ('', ^"%s^");", playerData[player][SAFE_NAME], playerData[player][STEAMID], playerData[player][IP]);

				client_print_color(0, player, "^x04[GLOS]^x01 Gracz^x03 %s^x01 zostal zmutowany^x04 na zawsze^x01.", playerData[player][NAME]);

				log_to_file("voice_manager.log", "Admin %s zmutowal na zawsze gracza %s", playerData[id][NAME], playerData[player][NAME]);
			} else {
				TrieSetCell(playerData[id][MUTES], playerData[player][NAME], 1);

				formatex(queryData, charsmax(queryData), "INSERT INTO `voice_manager` (`name`, `muted`) VALUES (^"%s^", ^"%s^");", playerData[id][SAFE_NAME], playerData[player][SAFE_NAME]);

				client_print_color(id, player, "^x04[GLOS]^x01 Zmutowales^x04 na zawsze^x01 gracza^x03 %s^x01.", playerData[player][NAME]);
			}

			SQL_ThreadQuery(sql, "ignore_handle", queryData);
		}
	}

	return PLUGIN_HANDLED;
}

public menu_unmute(id)
{
	new menuData[64], itemData[8], players, type, menu = menu_create("\yWybierz \wgracza\y, ktorego chcesz \rodmutowac\w:", "menu_unmute_handle");

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (id == i || !is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

		if (playerData[id][MENU] == MENU_PLAYER && !TrieKeyExists(playerData[id][MUTES], playerData[i][NAME])) continue;
		else if (playerData[id][MENU] == MENU_ADMIN && (!TrieKeyExists(mutes, playerData[i][NAME]) && !playerData[i][MUTED])) continue;

		if (playerData[id][MENU] == MENU_PLAYER) TrieGetCell(playerData[id][MUTES], playerData[i][NAME], type);
		else type = playerData[i][MUTED];

		formatex(menuData, charsmax(menuData), "\w%s %s", playerData[i][NAME], type ? "\r[Na Zawsze]" : "\r[Na Mape]");
		formatex(itemData, charsmax(itemData), "%i#%i", i, type);

		menu_additem(menu, menuData, itemData);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[GLOS]^x01 Zaden z graczy na serwerze nie jest %szmutowany!", playerData[id][MENU] == MENU_PLAYER ? "przez ciebie " : "");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public menu_unmute_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[8], tempId[4], type[2], access, callback, player;

	menu_item_getinfo(menu, item, access, itemData, charsmax(itemData), _, _, callback);

	menu_destroy(menu);

	split(itemData, tempId, charsmax(tempId), type, charsmax(type), "#");

	player = str_to_num(tempId);

	if (!is_user_connected(player)) {
		client_print_color(id, id, "^x04[GLOS]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	if (str_to_num(type)) {
		static queryData[192];

		if (playerData[id][MENU] == MENU_ADMIN) {
			playerData[player][MUTED] = false;

			formatex(queryData, charsmax(queryData), "DELETE FROM `voice_manager` WHERE name = '' AND (muted = ^"%s^" OR muted = '%s' OR muted = '%s');", playerData[id][SAFE_NAME], playerData[player][STEAMID], playerData[player][IP]);
		} else {
			TrieDeleteKey(playerData[id][MUTES], playerData[player][NAME]);

			formatex(queryData, charsmax(queryData), "DELETE FROM `voice_manager` WHERE name = ^"%s^" AND muted = ^"%s^";", playerData[id][SAFE_NAME], playerData[player][SAFE_NAME]);
		}

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	TrieDeleteKey(playerData[id][MENU] == MENU_ADMIN ? mutes : playerData[id][MUTES], playerData[player][NAME]);

	if (playerData[id][MENU] == MENU_ADMIN) {
		log_to_file("voice_manager.log", "Admin %s odmutowal gracza %s", playerData[id][NAME], playerData[player][NAME]);

		client_print_color(0, player, "^x04[GLOS]^x01 Gracz^x03 %s^x01 zostal odmutowany!", playerData[player][NAME]);
	} else client_print_color(id, player, "^x04[GLOS]^x01 Odmutowales gracza^x03 %s^x01!", playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public voice_status(id)
{
	switch (cvarAlive) {
		case 0: client_print_color(id, id, "^x04[GLOS]^x01 Zywi gracze slysza:^x03 zywych graczy ze swojej druzyny^x01.");
		case 1: client_print_color(id, id, "^x04[GLOS]^x01 Zywi gracze slysza:^x03 wszystkich zywych graczy^x01.");
		case 2: client_print_color(id, id, "^x04[GLOS]^x01 Zywi gracze slysza:^x03 wszystkich graczy ze swojej druzyny^x01.");
		case 3: client_print_color(id, id, "^x04[GLOS]^x01 Zywi gracze slysza:^x03 wszystkich graczy^x01.");
	}

	switch (cvarDead) {
		case 0: client_print_color(id, id, "^x04[GLOS]^x01 Martwi gracze slysza:^x03 martwych graczy ze swojej druzyny^x01.");
		case 1: client_print_color(id, id, "^x04[GLOS]^x01 Martwi gracze slysza:^x03 wszystkich martwych graczy^x01.");
		case 2: client_print_color(id, id, "^x04[GLOS]^x01 Martwi gracze slysza:^x03 wszystkich graczy ze swojej druzyny^x01.");
		case 3: client_print_color(id, id, "^x04[GLOS]^x01 Martwi gracze slysza:^x03 wszystkich graczy^x01.");
	}

	return PLUGIN_HANDLED;
}

public admin_voice_on(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN) || !cvarAdminVoice) return PLUGIN_HANDLED;

	if (adminVoice) {
		client_print_color(id, id, "^x04[GLOS]^x01 Poczekaj, jeden z adminow wlasnie uzywa^x03 glosu admina^x01.");

		return PLUGIN_HANDLED;
	}

	adminVoice = id;

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_bot(player)) continue;

		if (player != id) client_print_color(player, id, "^x04[GLOS]^x01 Posluchaj admina^x03 %s^x01.", playerData[id][NAME]);
		else client_print_color(player, id, "^x04[GLOS]^x01 Mowisz do^x03 wszystkich^x01.");
	}

	client_cmd(id, "+voicerecord");

	return PLUGIN_HANDLED;
}

public admin_voice_off(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN) || !cvarAdminVoice) return PLUGIN_HANDLED;

	if (adminVoice != id) {
		client_cmd(id, "-voicerecord");

		return PLUGIN_HANDLED;
	}

	adminVoice = 0;

	client_cmd(id, "-voicerecord");

	return PLUGIN_HANDLED;
}

public admin_intervoice_on(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN) || !cvarAdminInterVoice) return PLUGIN_HANDLED;

	playerData[id][INTER_VOICE] = true;

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_bot(player) || !(get_user_flags(id) & ADMIN_BAN)) continue;

		if (player != id) client_print_color(player, id, "^x04[GLOS]^x03 %s^x01 mowi do adminow.", playerData[id][NAME]);
		else client_print_color(player, id, "^x04[GLOS]^x01 Mowisz do^x03 adminow^x01.");
	}

	client_cmd(id, "+voicerecord");

	return PLUGIN_HANDLED;
}

public admin_intervoice_off(id)
{
	if (!playerData[id][INTER_VOICE] || !cvarAdminInterVoice) return PLUGIN_HANDLED;

	playerData[id][INTER_VOICE] = false;

	client_cmd(id, "-voicerecord");

	return PLUGIN_HANDLED;
}

public admin_listen_on(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN) || !cvarAdminListen) return PLUGIN_HANDLED;

	playerData[id][LISTEN] = true;

	return PLUGIN_HANDLED;
}

public admin_listen_off(id)
{
	if (!playerData[id][LISTEN] || !cvarAdminListen) return PLUGIN_HANDLED;

	playerData[id][LISTEN] = false;

	return PLUGIN_HANDLED;
}

public say_handle(id)
{
	if (!playerData[id][INFO] || playerData[id][INFO_USED]) return PLUGIN_CONTINUE;

	static message[192];

	read_argv(1, message, charsmax(message));

	trim(message);

	if (!message[0] || message[0] == '/' || message[0] == ' ') return PLUGIN_CONTINUE;

	playerData[id][INFO_USED] = true;

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || (!is_user_alive(player) && player != id) || get_team(player) != get_team(id)) continue;

		client_print_color(player, id, "^x04[INFO OD %s]^x03 %s.", playerData[id][NAME], message);
	}

	return PLUGIN_HANDLED;
}

public set_client_listening(receiver, sender, bool:listen)
{
	if (!is_user_connected(sender) || !is_user_connected(receiver)) return FMRES_IGNORED;

	if (cvarAdminVoiceOverride) {
		if (adminVoice) {
			if (!playerData[receiver][SETTINGS][0] || playerData[receiver][SETTINGS][1] & (1<<(sender - 1))) return FMRES_IGNORED;

			engfunc(EngFunc_SetClientListening, receiver, sender, adminVoice == sender);

			forward_return(FMV_CELL, adminVoice == sender);

			return FMRES_SUPERCEDE;
		}
	} else {
		if (adminVoice) {
			if (!playerData[receiver][SETTINGS][0] || playerData[receiver][SETTINGS][1] & (1<<(sender - 1))) return FMRES_IGNORED;

			engfunc(EngFunc_SetClientListening, receiver, sender, adminVoice == sender);

			forward_return(FMV_CELL, adminVoice == sender);

			return FMRES_SUPERCEDE;
		}
	}

	if (playerData[sender][INTER_VOICE]) {
		engfunc(EngFunc_SetClientListening, receiver, sender, (get_user_flags(receiver) & ADMIN_BAN));

		forward_return(FMV_CELL, (get_user_flags(receiver) & ADMIN_BAN));

		return FMRES_SUPERCEDE;
	}

	if (playerData[sender][MUTED] || TrieKeyExists(mutes, playerData[sender][NAME]) || TrieKeyExists(playerData[receiver][MUTES], playerData[sender][NAME])) {
		engfunc(EngFunc_SetClientListening, receiver, sender, false);

		forward_return(FMV_CELL, false);

		return FMRES_SUPERCEDE;
	}

	if ((playerData[sender][INFO] && get_team(receiver) == get_team(sender)) || playerData[receiver][LISTEN]) {
		engfunc(EngFunc_SetClientListening, receiver, sender, true);

		forward_return(FMV_CELL, true);

		return FMRES_SUPERCEDE;
	}

	if (playerData[receiver][ALIVE]) {
		switch (cvarAlive) {
			case 0: {
				if (playerData[sender][ALIVE] && get_team(receiver) == get_team(sender)) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 1: {
				if (playerData[sender][ALIVE]) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 2: {
				if (get_team(receiver) == get_team(sender)) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 3: {
				engfunc(EngFunc_SetClientListening, receiver, sender, true);

				forward_return(FMV_CELL, true);

				return FMRES_SUPERCEDE;
			}
		}
	} else {
		switch (cvarDead) {
			case 0: {
				if (!playerData[sender][ALIVE] && get_team(receiver) == get_team(sender)) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 1: {
				if (!playerData[sender][ALIVE]) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 2: {
				if (get_team(receiver) == get_team(sender)) {
					engfunc(EngFunc_SetClientListening, receiver, sender, true);

					forward_return(FMV_CELL, true);

					return FMRES_SUPERCEDE;
				}
			} case 3: {
				engfunc(EngFunc_SetClientListening, receiver, sender, true);

				forward_return(FMV_CELL, true);

				return FMRES_SUPERCEDE;
			}
		}
	}

	engfunc(EngFunc_SetClientListening, receiver, sender, false);

	forward_return(FMV_CELL, false);

	return FMRES_SUPERCEDE;
}

public player_spawn(id)
{
	playerData[id][ALIVE] = true;
	playerData[id][INFO] = false;
	playerData[id][INFO_USED] = false;
}

public player_die()
{
	new victim = read_data(2);

	playerData[victim][ALIVE] = false;
	playerData[victim][INFO] = true;

	set_task(float(cvarInfoTime), "stop_info", victim + TASK_INFO);
}

public voice_mask(id)
{
	playerData[id][SETTINGS][0] = read_data(1);
	playerData[id][SETTINGS][1] = read_data(2);
}

public stop_info(id)
{
	id -= TASK_INFO;

	playerData[id][INFO] = false;

	if (is_user_connected(id)) client_cmd(id, "-voicerecord");
}

public sql_init()
{
	new error[128], errorNum;

	sql = SQL_MakeDbTuple(cvarHost, cvarUser, cvarPassword, cvarDatabase);

	new Handle:connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("voice_manager.log", "[INIT] SQL Query Error: %s", error);

		return;
	}

	new queryData[192];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `voice_manager` (`id` INT(11) AUTO_INCREMENT, `name` VARCHAR(64) NOT NULL, `muted` VARCHAR(64) NOT NULL, PRIMARY KEY(`id`));");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connection);

	sqlConnection = true;
}

public ignore_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState == TQUERY_CONNECT_FAILED) log_to_file("voice_manager.log", "[IGNORE] Could not connect to SQL database. [%d] %s", errorCode, error);
	else if (failState == TQUERY_QUERY_FAILED) log_to_file("voice_manager.log", "[IGNORE] Query failed. [%d] %s", errorCode, error);
}

public load_player_mutes(id)
{
	id -= TASK_MUTES;

	if (!sqlConnection) {
		set_task(1.0, "load_player_mutes", id + TASK_MUTES);

		return;
	}

	static playerId[1], queryData[128];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `voice_manager` WHERE name = ^"%s^";", playerData[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "load_player_mutes_handle", queryData, playerId, sizeof(playerId));
}

public load_player_mutes_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("voice_manager.log", "[PLAYER] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new muteName[32], id = playerId[0];

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "muted"), muteName, charsmax(muteName));

		TrieSetCell(playerData[id][MUTES], muteName, 1);

		SQL_NextRow(query);
	}
}

public check_if_player_muted(id)
{
	id -= TASK_CHECK;

	if (!sqlConnection) {
		set_task(1.0, "check_if_player_muted", id + TASK_CHECK);

		return;
	}

	static playerId[1], queryData[192];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `voice_manager` WHERE name = '' AND (muted = ^"%s^" OR muted = '%s' OR muted = '%s');", playerData[id][SAFE_NAME], playerData[id][STEAMID], playerData[id][IP]);

	SQL_ThreadQuery(sql, "check_if_player_muted_handle", queryData, playerId, sizeof(playerId));
}

public check_if_player_muted_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("voice_manager.log", "[CHECK] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_MoreResults(query)) playerData[id][MUTED] = true;
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
