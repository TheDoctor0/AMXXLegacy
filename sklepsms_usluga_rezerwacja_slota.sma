#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "SklepSMS: Usluga Rezerwacja Slota"
#define AUTHOR "O'Zone"

new const serviceID[MAX_ID] = "resslot";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceID);