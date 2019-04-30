#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>

#define PLUGIN					"Matrix Jump"
#define AUTHOR					"OT"
#define VERSION					"1.5"

#define add_mjump_prop(%0) 		bs_canmatrix |= (1<<(%0-1))
#define del_mjump_prop(%0) 		bs_canmatrix &= ~(1<<(%0-1))
#define can_mjump(%0) 			(bs_canmatrix & (1<<(%0-1)))

new pcv_useflags

new bs_canmatrix

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	pcv_useflags = register_cvar("mjump_flags", "z")
	
	RegisterHam(Ham_Player_Jump, "player", "pfw_jump", 1)
	
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_say")
}

public hook_say(id)
{
	new string[40]
	read_argv(1, string, charsmax(string))
	
	if (containi(string, "/mjump") == -1)
		return PLUGIN_CONTINUE
	
	new flags[33]
	get_pcvar_string(pcv_useflags, flags, charsmax(flags))
	
	if (!has_flag(id, flags) && !(read_flags(flags) & ADMIN_USER))
	{
		client_print(id, print_chat, "No Matrix for you!")
		return PLUGIN_HANDLED
	}
	
	if (!can_mjump(id))
	{
		client_print(id, print_chat, "Welcome Mr. Anderson!")
		add_mjump_prop(id)
	}
	else
	{
		client_print(id, print_chat, "Hello Operator? I'm out!")
		del_mjump_prop(id)
	}
	
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	new string[33]
	get_pcvar_string(pcv_useflags, string, charsmax(string))
	
	if (read_flags(string) & ADMIN_USER)
	{
		add_mjump_prop(id)
	}
	else
	{
		if (has_flag(id, string))
		{
			add_mjump_prop(id)
		}
	}
}

public client_disconnect(id)
{
	del_mjump_prop(id)
}

public pfw_jump(id)
{
	if (can_mjump(id) && entity_get_int(id, EV_INT_waterlevel) == 0 && (entity_get_int(id, EV_INT_flags) & (FL_ONGROUND | FL_PARTIALGROUND | FL_ONTRAIN)))
	{
		entity_set_int(id, EV_INT_sequence, 55)  // The MATRIX sequence!!!
	}
	
	return HAM_IGNORED
}
