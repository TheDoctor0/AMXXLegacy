#include <amxmodx>
#include <sklep_sms>

#define PLUGIN "Sklep-SMS: Usluga Case USP"
#define AUTHOR "O'Zone"
#define VERSION "1.0"

new const service_id[MAX_ID] = "case_usp";

native set_player_case_usp(id,ilosc);
native get_player_case_usp(id);

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
	set_player_case_usp(id, get_player_case_usp(id)+amount);
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
