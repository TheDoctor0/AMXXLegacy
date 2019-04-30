#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "Sklep-SMS: Usluga VIP"
#define AUTHOR "O'Zone"

new const serviceID[MAX_ID] = "vip";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceID);