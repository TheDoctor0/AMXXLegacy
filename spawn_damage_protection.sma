/*
	- sdp_action
		0 - No damage
		1 - damage comes back to attacker
		2 - kill attacker
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <ColorChat>

#define PLUGIN "Spawn Damage Protection"
#define VERSION "1.1"
#define AUTHOR "Zabijaka & O'Zone"

#define DMG_BULLET (1<<1)

new bool:gProtect;
new gCvarActive;
new gCvarAction;
new gCvarTime;
new gCvarMP_FRIENDLYFIRE;
new const spawnProtection[] = "Ochrona Na Spawnie";
new g_Disabled;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	gCvarActive = register_cvar("sdp_active", "1");
	gCvarAction = register_cvar("sdp_action", "1");
	gCvarTime = register_cvar("sdp_time", "2.0");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	register_logevent("Logevent_RoundStart", 2, "0=World triggered", "1=Round_Start");
	CheckMap()
}
public plugin_cfg(){
	gCvarMP_FRIENDLYFIRE = get_cvar_pointer("mp_friendlyfire");
}
public Logevent_RoundStart(){
	if(get_pcvar_num(gCvarActive) && !g_Disabled){
		gProtect = true;
		
		new t = get_pcvar_num(gCvarTime);
		new a = get_pcvar_num(gCvarAction);
		
		set_hudmessage(255, 25, 25, -1.0, -1.0, _, _, float(t), _, _, 4);
		switch(a){
			case 1: show_hudmessage(0, "%s. Nie strzelaj, bo pozalujesz!", spawnProtection);
			case 2: show_hudmessage(0, "%s. Nie strzelaj, bo zginiesz!", spawnProtection);
			default: show_hudmessage(0, spawnProtection);
		}		
		set_task(get_pcvar_float(gCvarTime), "protectionOff");
	}
}
public protectionOff() {
	gProtect = false;
}

public TakeDamage(id, idinflictor, attacker, Float:damage, damagebits) {
	if(!get_pcvar_num(gCvarActive) || !gProtect || id == attacker)
		return HAM_IGNORED; 
	if(!get_pcvar_num(gCvarMP_FRIENDLYFIRE) && get_user_team(id) == get_user_team(attacker))
		return HAM_IGNORED; 
	
	if(damagebits & DMG_BULLET){
		new name[32]
		get_user_name(attacker, name, 31);
		new action = get_pcvar_num(gCvarAction);
		switch(action){
		case 1: {
				if(get_user_health(attacker) > damage){
					SetHamParamEntity(1, attacker);
					ColorChat(attacker, GREEN, "** %s. Obrazenia wracaja do Ciebie. **", spawnProtection);
					return HAM_IGNORED;
				} else {
					user_kill(attacker);
					ColorChat(0, GREEN, "** %s. %s umiera przez wlasna glupote! **", spawnProtection, name);
					return HAM_SUPERCEDE;
				}
			}
		case 2: {
				user_kill(attacker);
				ColorChat(attacker, GREEN, "** %s. %s zostal skazany(a) na smierc za probe zabojstwa! **", spawnProtection, name);
				return HAM_SUPERCEDE;
			}
		default :{
				ColorChat(attacker, GREEN, "** %s. Nie mozesz nikogo zranic. Tracisz tylko naboje. **", spawnProtection);
				return HAM_SUPERCEDE;
			}
		}
	}
	return HAM_IGNORED; 
}

CheckMap() 
{
	new g_iMapPrefix[][] = 
	{ 
		"de_",
		"cs_"
	}
	new MapName[32]
	get_mapname(MapName, 31)
	
	for(new i = 0; i < sizeof(g_iMapPrefix); i++)
	{
		if(containi(MapName, g_iMapPrefix[i]) != -1) 
		{
			g_Disabled = true
		}
	}
}