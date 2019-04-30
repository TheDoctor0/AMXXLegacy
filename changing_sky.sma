#include <amxmisc>

#define PLUGIN "Changing Sky"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
{
	new iHour;

	time(iHour);

	if(iHour >= 21 || iHour <= 6) set_cvar_string("sv_skyname", "space");
	else set_cvar_string("sv_skyname", "desert");
}