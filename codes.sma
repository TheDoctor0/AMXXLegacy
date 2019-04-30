#include <amxmodx>

#define PLUGIN "Codes"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

enum _:codesInfo { CODE_TEXT[32], CODE_PLAYER[32] };

new codesFile[128], Array:codes, codesTime, codesChance, codesPlayers, codesMinPlayers, codesLeft = 0;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("codes_time", "600"), codesTime);
	bind_pcvar_num(create_cvar("codes_chance", "2"), codesChance);
	bind_pcvar_num(create_cvar("codes_players", "1"), codesPlayers);
	bind_pcvar_num(create_cvar("codes_min_players", "6"), codesMinPlayers);

	register_clcmd("say /kod", "show_code");
	register_clcmd("say_team /kod", "show_code");
}

public plugin_precache() 
{
	codes = ArrayCreate(codesInfo);
	
	get_localinfo("amxx_configsdir", codesFile, charsmax(codesFile));

	format(codesFile, charsmax(codesFile), "%s/codes.ini", codesFile);
	
	if (!file_exists(codesFile)) set_fail_state("[CODES] Brak pliku codes.ini!");
	
	new code[codesInfo], lineData[128], fileOpen = fopen(codesFile, "r");
	
	while (!feof(fileOpen)) {
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);
		
		if (lineData[0] == ';' || lineData[0] == '^0') continue;

		code[CODE_PLAYER] = "";
		
		split(lineData, code[CODE_TEXT], charsmax(code[CODE_TEXT]), code[CODE_PLAYER], charsmax(code[CODE_PLAYER]), " - ");

		if (!code[CODE_PLAYER][0]) codesLeft++;

		ArrayPushArray(codes, code);
			
		continue;
	}

	if (codesLeft) log_amx("[CODES] Zaladowano %i kod%s do wylosowania.", codesLeft, codesLeft == 1 ? "" : (codesLeft < 5 ? "y" : "ow"));
	else set_fail_state("[CODES] Brak kodow dostepnych do wylosowania!");
}

public plugin_cfg()
	set_task(float(codesTime), "codes_draw");

public codes_draw()
{
	if (get_playersnum() < codesMinPlayers) {
		set_task(30.0, "codes_draw");

		return;
	}

	if (random_num(1, codesChance) != 1) return;

	new code[codesInfo], players = random_num(1, min(codesLeft, codesPlayers)), player, randomCode;

	for (new i = 1; i <= players; i++) {
		player = get_random_player();

		if (player == -1 || !codesLeft) break;

		randomCode = random_num(1, codesLeft);

		new randomCodeCount = 0;

		for (new j = 0; j < ArraySize(codes); j++) {
			ArrayGetArray(codes, j, code);

			if (code[CODE_PLAYER][0]) continue;

			if (++randomCodeCount == randomCode) {
				client_print_color(player, player, "^x04[NAGRODA]^x01 Gratulacje, zostales wylosowany i otrzymales^x04 kod na nagrode^x01! Twoj kod to:^x03 %s^x01.", code[CODE_TEXT]);
				client_print_color(player, player, "^x04[NAGRODA]^x01 Zapisz go i zglos sie po nagrode na naszym forum^x04 CS-Reload.pl^x01.");
				client_print_color(player, player, "^x04[NAGRODA]^x01 W razie potrzeby otrzymany kod bedzie od teraz dostepny pod komenda^x04 /kod^x01.");

				set_hudmessage(50, 255, 50, -1.0, 0.4, 2, 0.0, 5.0, 0.1, 0.1);

				show_hudmessage(player, "Gratulacje, zostales wylosowany i otrzymales kod na nagrode!");

				get_user_name(player, code[CODE_PLAYER], charsmax(code[CODE_PLAYER]));

				ArraySetArray(codes, j, code);

				codesLeft--;

				save_codes();
			}
		}
	}
}

public show_code(id)
{
	new playerName[32], code[codesInfo];

	get_user_name(id, playerName, charsmax(playerName));

	for (new j = 0; j < ArraySize(codes); j++) {
		ArrayGetArray(codes, j, code);

		if (equal(code[CODE_PLAYER], playerName)) {
			client_print_color(id, id, "^x04[NAGRODA]^x01 Twoj kod to:^x03 %s^x01.", code[CODE_TEXT]);
			client_print_color(id, id, "^x04[NAGRODA]^x01 Zglos sie po nagrode na naszym forum^x04 CS-Reload.pl^x01.");

			return PLUGIN_HANDLED;
		}
	}

	client_print_color(id, id, "^x04[NAGRODA]^x01 Jak na razie nie wylosowales kodu na nagrode.");

	return PLUGIN_HANDLED;
}

public save_codes()
{
	delete_file(codesFile);

	write_file(codesFile, "; Lista kodow do wylosowania");

	new codeLine[128], code[codesInfo];

	for (new j = 0; j < ArraySize(codes); j++) {
		ArrayGetArray(codes, j, code);

		if (code[CODE_PLAYER][0]) formatex(codeLine, charsmax(codeLine), "%s - %s", code[CODE_TEXT], code[CODE_PLAYER]);
		else copy(codeLine, charsmax(codeLine), code[CODE_TEXT])

		write_file(codesFile, codeLine);
	}
}

stock get_random_player()
{
	new players[32], playerName[32], code[codesInfo], bool:found, player;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if(!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i)) continue;

		get_user_name(i, playerName, charsmax(playerName));

		found = false;

		for (new j = 0; j < ArraySize(codes); j++) {
			ArrayGetArray(codes, j, code);

			if (equal(playerName, code[CODE_PLAYER])) {
				found = true;

				break;
			}
		}

		if (!found) players[player++] = i;
	}

	if (player == 1) return players[0];
	if (player > 0) return players[random(player)];

	return -1;
}