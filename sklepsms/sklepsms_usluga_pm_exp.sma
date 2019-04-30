#include <amxmodx>
#include <sklep_sms>

native Poke_PlayerPokemon(id, pokemon = -1);
native Poke_Give_XP(id, pokemon = -1, amount);

#define PLUGIN "Sklep-SMS: Usluga PM Exp"
#define AUTHOR "O'Zone"

new const service_id[MAX_ID] = "pm_exp";

public plugin_natives() {
	set_native_filter("native_filter");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_cfg() {
	ss_register_service(service_id);
}

public ss_service_chosen(id) {
	if(!Poke_PlayerPokemon(id)) {
		client_print_color(id, id, "^x03[SKLEPSMS]^x01 Musisz^x04 wybrac pokemona^x01, aby moc zakupic^x04 EXP^x01.");
		return SS_STOP;
	}

	return SS_OK;
}

public ss_service_bought(id, amount) {
	Poke_Give_XP(id, _, amount);
}

public native_filter(const native_name[], index, trap) {
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR);
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
