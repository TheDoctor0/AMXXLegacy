#include <amxmodx>

public plugin_init() {
	register_plugin("Auto Admins Reload","1.0","O'Zone")
	set_task(90.0, "Reload_Admins");
} 

public Reload_Admins(){
	server_cmd("amx_reloadadmins");
	set_task(360.0, "Reload_Admins");
}
