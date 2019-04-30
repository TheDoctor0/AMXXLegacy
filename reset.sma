#include <amxmodx>
#include <cstrike>
#include <fun>

#define PLUGIN "Reset Score"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new const commandReset[][] = { "say /rs", "say_team /rs", "say /reset", "say_team /reset", "say /resetscore", "say_team /resetscore", "reset" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i; i < sizeof commandReset; i++) register_clcmd(commandReset[i], "reset_score");
}

public reset_score(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	set_user_frags(id, 0);
	cs_set_user_deaths(id, 0);

	new name[32];
	get_user_name(id, name, charsmax(name));
	
	client_print_color(0, id,"^x04[RESET]^x03 %s^x01 zresetowal sobie statystyki!", name);

	set_user_frags(id, 0);
	cs_set_user_deaths(id, 0);
	
	return PLUGIN_HANDLED;
}
