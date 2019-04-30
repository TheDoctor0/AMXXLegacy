#include <amxmodx>
#include <engine>

#define PLUGIN "Shield Remover"
#define AUTHOR "O'Zone"
#define VERSION "1.0"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	set_task(0.1, "RemoveShields");
}

public RemoveShields()
{
	new szMap[33];
	get_mapname(szMap, charsmax(szMap));
	
	new iWeaponID = -1;
	
	while((iWeaponID = find_ent_by_model(iWeaponID, "armoury_entity", "models/w_shield.mdl")) != 0)
	{
		log_to_file("addons/amxmodx/logs/shield_remover.txt", "[%s] Usunieto tarcze.", szMap);
		remove_entity(iWeaponID);
	}
}