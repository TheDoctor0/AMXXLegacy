#include <amxmodx>
#include <engine>

#define PLUGIN "Plant Bomb in Move"
#define AUTHOR "O'Zone"
#define VERSION "1.0"

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public bomb_defusing(id)
	entity_set_float(id, EV_FL_maxspeed, 240.0);
	
public bomb_planting(id)
	entity_set_float(id, EV_FL_maxspeed, 240.0);