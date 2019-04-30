#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "Sklep-SMS: Usluga CS:GO Jackpot Money"
#define AUTHOR "O'Zone"

native csgo_get_money(id);
native csgo_set_money(id, Float:amount);

new const serviceID[MAX_ID] = "jackpot";

public plugin_natives()
	set_native_filter("native_filter");

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceID);

public ss_service_bought(id, amount)
	csgo_set_money(id, float(csgo_get_money(id) + amount));

public native_filter(const native_name[], index, trap)
{
	if(trap == 0)
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);

		pause_plugin();

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
