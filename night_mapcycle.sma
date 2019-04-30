#include <amxmodx>

#define PLUGIN "Day/Night Mapcycle"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new mTime, mTime2

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	mTime = register_cvar("m_time", "23")
	mTime2 = register_cvar("mp_time2", "9")
	CheckTime()
}

public CheckTime() 
{
	new time_string[3], time_hour
	get_time("%H", time_string, 2)
	time_hour = str_to_num(time_string)
	if(time_hour >= get_pcvar_num(mTime) || time_hour <= get_pcvar_num(mTime2))
		server_cmd("mapcyclefile mapcycle_night.txt")
	else
		server_cmd("mapcyclefile mapcycle.txt")
	return PLUGIN_HANDLED
}