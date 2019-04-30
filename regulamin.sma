#include <amxmodx>

#define PLUGIN "Regulamin"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /regulamin", "Regulamin");
	register_clcmd("say_team /regulamin", "Regulamin");
	register_clcmd("regulamin", "Regulamin");	
}

public Regulamin(id)
	show_motd(id, "regulamin.txt", "Regulamin Serwera"); 

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/