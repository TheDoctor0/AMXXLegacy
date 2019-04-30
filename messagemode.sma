#include <amxmodx>

#define PLUGIN "Messagemode API"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new message[64], pluginId = -1, functionId = -1, playerId;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say");
}

public plugin_natives()
	register_native("messagemode", "_messagemode");

public _messagemode(plugin, params)
{
	if (params != 2 || !get_param(1)) return PLUGIN_CONTINUE;

	static functionName[64];

	get_string(2, functionName, charsmax(functionName));

	if ((functionId = get_func_id(functionName, plugin)) > -1) {
		pluginId = plugin;

		playerId = get_param(1);
	}

	return PLUGIN_CONTINUE;
}

public handle_say(id)
{
	if (pluginId == -1 || functionId == -1 || playerId != id) return PLUGIN_CONTINUE;

	read_args(message, charsmax(message));

	remove_quotes(message);

	callfunc_begin_i(functionId, pluginId);
	callfunc_push_int(playerId);
	callfunc_push_str(message);
	callfunc_end();

	pluginId = functionId = playerId = -1;

	return PLUGIN_CONTINUE;
}