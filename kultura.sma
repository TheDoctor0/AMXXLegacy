#include <amxmodx>

#define PLUGIN "Kultura"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define MAX_LENGTH 32

new Array:swears;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say_team");

	swears = ArrayCreate(MAX_LENGTH);
	
	read_wordfile();
} 

public read_wordfile() 
{
	new file[MAX_LENGTH * 2], lineData[MAX_LENGTH], lineNum;

	formatex(file, charsmax(file), "addons/amxmodx/configs/wordlist.txt");

	if (!file_exists(file)) return;

	while (read_file(file, lineNum++, lineData, charsmax(lineData))) ArrayPushString(swears, lineData);
}

public handle_say(id) 
{
	static message[MAX_LENGTH * 6], name[MAX_LENGTH], swear[MAX_LENGTH];

	read_args(message, charsmax(message));

	remove_quotes(message);

	for (new i = 0; i < ArraySize(swears); i++) {
		ArrayGetString(swears, i, swear, charsmax(swear));

		if(containi(message, swear) != -1) {
			get_user_name(id, name, charsmax(name));

			format(message, charsmax(message), "%s%s^x03%s^x01 :  %s", (get_user_flags(id) & ADMIN_LEVEL_H) ? "^x04[VIP] ^x01" : "", get_user_team(id) == 3 ? "*SPEC*" : (!is_user_alive(id) ? "*DEAD* " : ""), name, message);

			client_print_color(id, id, message);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public handle_say_team(id) 
{
	static message[MAX_LENGTH * 6], name[MAX_LENGTH], team[MAX_LENGTH], swear[MAX_LENGTH];

	read_args(message, charsmax(message));

	remove_quotes(message);

	for (new i = 0; i < ArraySize(swears); i++) {
		ArrayGetString(swears, i, swear, charsmax(swear));

		if (containi(message, swear) != -1) {
			get_user_name(id, name, charsmax(name));

			switch(get_user_team(id)) {
				case 0: formatex(team, charsmax(team), "");
				case 1: formatex(team, charsmax(team), "(Terrorist)");
				case 2: formatex(team, charsmax(team), "(Counter-Terrorist)");
				case 3: formatex(team, charsmax(team), "(Spectator)");
			}

			format(message, charsmax(message), "%s^x01%s%s^x03 %s^x01 :  %s", (get_user_flags(id) & ADMIN_LEVEL_H) ? "^x04[VIP] " : "", get_user_team(id) == 3 ? "*SPEC*" : (!is_user_alive(id) ? "*DEAD* " : ""), team, name, message);

			client_print_color(id, id, message);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}