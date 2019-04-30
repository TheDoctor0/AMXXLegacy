#include <amxmodx>

#define PLUGIN "Echo Blocker"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_logevent("BlockEcho", 2, "1=Round_Start")
}

public BlockEcho() {
	for(new id=1; id<=32; id++)
		if(is_user_connected(id))
			client_cmd(id, "room_type 0")
}