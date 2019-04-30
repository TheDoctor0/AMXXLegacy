#include <amxmodx>

#define PLUGIN "Pokemod Commands Block"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_BLOCK 90843

new const commands[][] = {
	"+pokeskill",
	"+pokeskill1",
	"+pokeskill2",
	"+pokeskill3",
	"+pokeskill4",
	"+pokeskill5"
};

native check_small_map();

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i = 0; i < sizeof(commands); i++) register_clcmd(commands[i], "command_block");
}

public command_block()
{
	if (check_small_map()) return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}