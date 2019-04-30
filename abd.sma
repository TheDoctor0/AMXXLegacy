#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "1.1"
#define AUTHOR "Sn!ff3r & O'Zone"

new g_hudmsg1, g_hudmsg2

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")	
	
	g_hudmsg1 = CreateHudSyncObj()	
	g_hudmsg2 = CreateHudSyncObj()
}

public on_damage(id)
{
	static attacker; attacker = get_user_attacker(id);
	static damage; damage = read_data(2);
	
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage)		

	if(is_user_connected(attacker))
	{
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)				
	}
}
