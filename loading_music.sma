#include <amxmodx>

#define PLUGIN "Server Loading Music"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
	register_plugin(PLUGIN, VERSION, AUTHOR)

public client_connect(id)
	client_cmd(id, "mp3 loop sound/load_music.mp3")

public plugin_precache()
	precache_generic("sound/load_music.mp3")
