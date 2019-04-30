#include <amxmodx>
#include <hamsandwich>
#include <zp50_class_zombie>

public plugin_init()RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post")

public fw_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType) {
	if(!is_user_connected(iAttacker) || iVictim == iAttacker||zp_core_is_zombie(iAttacker)) return
	static iVictimHealth; iVictimHealth = get_user_health(iVictim)
	
	/*ClearSyncHud(iAttacker, g_HudSync)
	if(iVictimHealth>floatround(flDamage)) {
		set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 0.1, 1.5, 0.05, 0.5, 2)
		ShowSyncHudMsg(iAttacker, g_HudSync, "[HP: %d]",iVictimHealth-floatround(flDamage))
	}else{
		set_hudmessage(255, 255, 255, -1.0, 0.35, 0, 0.1, 3.5, 0.5, 1.0, -1)
		ShowSyncHudMsg(iAttacker, g_HudSync, "Kill!")
	}*/
	
	if(iVictimHealth>floatround(flDamage)) {
		client_print(iAttacker, print_center, "[ HP: %d ]",iVictimHealth-floatround(flDamage))
	}else{
		client_print(iAttacker, print_center, "Zabiles!")
	}
}
