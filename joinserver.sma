#include <amxmodx>

public plugin_precache() {
	precache_sound("misc/joinserver3.mp3")
	return PLUGIN_CONTINUE
}


public client_connect(id) {
	client_cmd(id,"mp3 play sound/misc/joinserver3.mp3")
	return PLUGIN_CONTINUE
}



public plugin_init() {
	register_plugin("azure demo","1.0","Amxx Newbie")
	return PLUGIN_CONTINUE
}