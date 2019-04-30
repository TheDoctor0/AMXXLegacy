#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "Sklep-SMS: Usluga ZM Bonusowy EXP"
#define AUTHOR "O'Zone"

new const serviceID[MAX_ID] = "zp_bonus";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceID);