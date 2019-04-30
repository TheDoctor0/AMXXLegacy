#include <amxmodx>


new HIGHPING_MAX = 140 // set maximal acceptable ping
new HIGHPING_TIME = 4  // set in seconds frequency of ping checking
new HIGHPING_TESTS = 3  // minimal number of checks before doing anything

new iNumTests[33]

public plugin_init() {
	register_plugin("High Ping Kicker","1.2.0","DynAstY")
	if (HIGHPING_TIME < 10) HIGHPING_TIME = 4
	if (HIGHPING_TESTS < 4) HIGHPING_TESTS = 3
	return PLUGIN_CONTINUE
}

public client_disconnected(id) {
	remove_task(id)
	return PLUGIN_CONTINUE
}
	
public client_putinserver(id) {
	iNumTests[id] = 0
	if (!is_user_bot(id)) {
		new param[1]
		param[0] = id
		set_task(120.0, "showWarn", id, param, 1)
	}
	return PLUGIN_CONTINUE
}

kickPlayer(id) {
	new name[32]
	get_user_name(id, name, 31)
	new uID = get_user_userid(id)
	server_cmd("kick #%d ^"[HPK] Twoj ping jest za duzy!^"", uID)
	//client_cmd(id, "echo ^"[HPK] Twoj ping jest za duzy!^"; disconnect")
	client_print_color(0, id, "^x04[HPK]^x01 Gracz^x03 %s ^x01zostal rozlaczony z powodu duzego ping'u!", name)
	return PLUGIN_CONTINUE
} 

public checkPing(param[]) {
	new id = param[0]
	if ((get_user_flags(id) & ADMIN_IMMUNITY)) {
		remove_task(id)
		client_print_color(0, id, "^x04[HPK]^x01 Ping nie obowiazuje graczy z immunitetem...")
		return PLUGIN_CONTINUE
	}
	new p, l
	get_user_ping(id, p, l)
	if (p > HIGHPING_MAX)
		++iNumTests[id]
	else
		if (iNumTests[id] > 0) --iNumTests[id]
	if (iNumTests[id] > HIGHPING_TESTS)
		kickPlayer(id)
	return PLUGIN_CONTINUE
}

public showWarn(param[]) {
	client_print_color(param[0], param[0], "^x04[HPK]^x01 Gracze z pingiem wiekszym niz^x04 %d^x01 beda wyrzucani!", HIGHPING_MAX)
	set_task(float(HIGHPING_TIME), "checkPing", param[0], param, 1, "b")
	return PLUGIN_CONTINUE
}

