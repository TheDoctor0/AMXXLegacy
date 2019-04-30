#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "Say Crash Blocker"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("say", "CmdSay")
	register_clcmd("say_team", "CmdSay")
}

public CmdSay(id)
{ 
	static szText[192]
	read_args(szText, 191)
	remove_quotes(szText)
	
	replace_all(szText, 191, "¹", "a")
	replace_all(szText, 191, "æ", "c")
	replace_all(szText, 191, "ê", "e")
	replace_all(szText, 191, "³", "l")
	replace_all(szText, 191, "ñ", "n")
	replace_all(szText, 191, "ó", "o")
	replace_all(szText, 191, "œ", "s")
	replace_all(szText, 191, "Ÿ", "z")
	replace_all(szText, 191, "¿", "z")
	
	new cmd[32]
	read_argv(0, cmd, 31)          
	engclient_cmd(id, cmd, szText) 
	
	return PLUGIN_HANDLED
}