#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "SklepSMS: Usluga ZP AP"
#define AUTHOR "O'Zone"

native zp_ammopacks_get(id);
native zp_ammopacks_set(id, amount);

new const serviceID[MAX_ID] = "zp_ap";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR)

public plugin_cfg()
	ss_register_service(serviceID);

public plugin_natives()
	set_native_filter("native_filter");

public ss_service_bought(id, amount)
	zp_ammopacks_set(id, zp_ammopacks_get(id) + amount);

public native_filter(const native_name[], index, trap)
{
	if (trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR);

		pause_plugin();

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
