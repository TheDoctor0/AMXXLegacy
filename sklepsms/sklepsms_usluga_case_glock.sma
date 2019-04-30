#include <amxmodx>
#include <shop_sms>

#define PLUGIN "Sklep-SMS: Usluga Case Glock"
#define AUTHOR "O'Zone"
#define VERSION "1.0"

new const service_id[MAX_ID] = "case_glock";

native set_player_case_glock(id,ilosc);
native get_player_case_glock(id);

public plugin_natives() {
	set_native_filter("native_filter");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_cfg() {
	ss_register_service(service_id)
}

public ss_service_chosen(id) {
	return SS_OK;
}

public ss_service_bought(id,amount) {
	set_player_case_glock(id, get_player_case_glock(id)+amount);
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
