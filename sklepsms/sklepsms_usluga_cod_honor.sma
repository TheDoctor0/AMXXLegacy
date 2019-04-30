#include <amxmodx>
#include <sklep_sms>

native cod_add_user_honor(id, amount);

new const service_id[MAX_ID] = "cod_honor";
#define PLUGIN "Sklep-SMS: Usluga CoD Honor"
#define AUTHOR "O'Zone"

public plugin_natives() {
	set_native_filter("native_filter");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg() {
	ss_register_service(service_id);
}

public ss_service_bought(id,amount) {
	cod_add_user_honor(id,amount);
}

// Zabezpieczenie, jezeli plugin jest odpalony na serwerze bez odpowiednich funkcji
public native_filter(const native_name[], index, trap) {
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR); // Rejestrujemy plugin, aby nie bylo na liscie unknown
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
