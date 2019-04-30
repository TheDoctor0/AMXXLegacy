#include <amxmodx>

#define PLUGIN  "Money Test"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

new playerMoney[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_natives()
{
	register_native("get_user_money", "_get_user_money", 1);
	register_native("set_user_money", "_set_user_money", 1);
}

public client_putinserver(id)
	playerMoney[id] = 100;

public _get_user_money(id)
	return playerMoney[id];

public _set_user_money(id, money)
	playerMoney[id] = money;
