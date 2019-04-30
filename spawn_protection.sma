/*
	- sdp_action
		0 - No damage
		1 - damage comes back to attacker
		2 - kill attacker
*/
#include <amxmodx>
#include <hamsandwich>

#define PLUGIN "Spawn Damage Protection"
#define VERSION "1.1"
#define AUTHOR "Zabijaka & O'Zone"

#define DMG_BULLET (1<<1)

new bool:gProtect, gCvarAction, gCvarTime, gCvarMP_FRIENDLYFIRE;

native check_small_map();

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	gCvarAction = register_cvar("sdp_action", "1");
	gCvarTime = register_cvar("sdp_time", "2.0");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");

	register_logevent("Logevent_RoundStart", 2, "0=World triggered", "1=Round_Start");
}

public plugin_cfg()
	gCvarMP_FRIENDLYFIRE = get_cvar_pointer("mp_friendlyfire");

public Logevent_RoundStart()
{
	if(check_small_map())
	{
		gProtect = true;
		
		new t = get_pcvar_num(gCvarTime), a = get_pcvar_num(gCvarAction);
		
		set_hudmessage(255, 25, 25, -1.0, -1.0, _, _, float(t), _, _, 4);

		switch(a)
		{
			case 1: show_hudmessage(0, "** Ochrona na Spawnie. Nie strzelaj, bo pozalujesz! **");
			case 2: show_hudmessage(0, "** Ochrona na Spawnie. Nie strzelaj, bo zginiesz! **");
			default: show_hudmessage(0, "** Ochrona na Spawnie **");
		}		

		set_task(get_pcvar_float(gCvarTime), "protectionOff");
	}
}

public protectionOff()
	gProtect = false;

public TakeDamage(id, idinflictor, attacker, Float:damage, damagebits) 
{
	if(!gProtect || id == attacker) return HAM_IGNORED; 
	if(!get_pcvar_num(gCvarMP_FRIENDLYFIRE) && get_user_team(id) == get_user_team(attacker)) return HAM_IGNORED; 
	
	if(damagebits & DMG_BULLET && check_small_map())
	{
		new name[32], action = get_pcvar_num(gCvarAction);
		get_user_name(attacker, name, charsmax(name));

		switch(action)
		{
			case 1: 
			{
				if(get_user_health(attacker) > damage)
				{
					SetHamParamEntity(1, attacker);
					client_print_color(attacker, attacker, "^x04** Ochrona na Spawnie. Obrazenia wracaja do Ciebie. **");

					return HAM_IGNORED;
				} 
				else 
				{
					user_kill(attacker);
					client_print_color(0, attacker, "^x04** Ochrona na Spawnie. %s umiera przez wlasna glupote! **", name);

					return HAM_SUPERCEDE;
				}
			}
			case 2: 
			{
				user_kill(attacker);
				client_print_color(attacker, attacker, "^x04** Ochrona na Spawnie. %s zostal skazany(a) na smierc za probe zabojstwa! **", name);

				return HAM_SUPERCEDE;
			}
			default :
			{
				client_print_color(attacker, attacker, "^x04** Ochrona na Spawnie. Nie mozesz nikogo zranic. Tracisz tylko naboje. **");

				return HAM_SUPERCEDE;
			}
		}
	}

	return HAM_IGNORED; 
}