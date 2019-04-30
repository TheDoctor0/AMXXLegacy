#include <amxmodx>
#include <amxmisc>
#include <engine>

new count[MAX_PLAYERS + 1][MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("AdminListen","2.3x","/dev/ urandom");

	register_event("SayText", "catch_say", "b");

	return PLUGIN_CONTINUE;
}

public catch_say(id)
{
	static message[190], channel[190], name[32];

	new receiver = read_data(0), sender = read_data(1);

	read_data(2, channel, charsmax(channel));
	read_data(4, message, charsmax(message));
	get_user_name(sender, name, charsmax(name));

	count[sender][receiver] = 1;

	if (sender == receiver) {      
		new players[MAX_PLAYERS], playersNum;

		get_players(players, playersNum, "c");

		for (new i = 0; i < playersNum; i++) {
			if (get_user_flags(players[i]) & ADMIN_LEVEL_B) {
				if (count[sender][players[i]] != 1) {              
					message_begin(MSG_ONE, get_user_msgid("SayText"), {0, 0, 0}, players[i]);
					write_byte(sender);
					write_string(channel);
					write_string(name);
					write_string(message);
					message_end();
				}
			}

			count[sender][players[i]] = 0;
		}
	}

	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
	if ((get_user_flags(id) & ADMIN_LEVEL_B)) set_speak(id, 4);

public client_connect(id)
	if ((get_user_flags(id) & ADMIN_LEVEL_B)) set_speak(id, 4);
