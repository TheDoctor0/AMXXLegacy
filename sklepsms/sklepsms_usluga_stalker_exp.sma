#include <amxmodx>
#include <sklep_sms>
#include <colorchat>
native stalker_get_user_class(id);
native stalker_add_xp(id,amount);

new const service_id[MAX_ID] = "stalker_exp";
#define PLUGIN "Sklep-SMS: Usluga Stalker EXP"
#define AUTHOR "O'Zone"

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
	if( !stalker_get_user_class(id) ) {
		ColorChat(id, RED,"[SKLEPSMS]^x01 Musisz^x04 wybrac klase^x01, aby moc zakupic^x04 EXP^x01.");
		return SS_STOP;
	}

	return SS_OK;
}

public ss_service_bought(id,amount) {
	stalker_add_xp(id,amount);
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
