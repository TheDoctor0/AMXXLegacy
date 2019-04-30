#include <amxmodx>

#define MAX_POWODOW 20

#define PLUGIN "Reason Kicker"
#define VERSION "1.3"
#define AUTHOR "byCZEK & O'Zone"

new const strona[] = "http://CS-Reload.pl";

new const tag[] = "[KICK]";

new g_kogo[33];
new last[33][128];

new Array: powody;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("amx_kickmenu", "cmdKickMenu");
	register_clcmd("amx_custom",   "cmdWlasnyPowod");
}

public plugin_cfg()
{
	powody = ArrayCreate(256, 1);

	new plik[128]; get_localinfo("amxx_configsdir", plik, charsmax(plik));

	format(plik, charsmax(plik), "%s/powody_kickow.ini", plik);

	if (!file_exists(plik)) set_fail_state("Brak pliku z powodami.");

	new fp = fopen(plik, "r"), i = 0, tresc[128];

	while (!feof(fp) && i < MAX_POWODOW) {
		fgets(fp, tresc, charsmax(tresc)); trim(tresc);

		if (tresc[0] == ';' || tresc[0] == '^0') continue;

		ArrayPushString(powody, tresc);

		i++;
	}
	fclose(fp);
}


public cmdKickMenu(id)
{
	if (!(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_CONTINUE;

	MenuKickow(id);

	return PLUGIN_HANDLED;
}

public cmdWlasnyPowod(id)
{
	new s[128]; read_args(s, 127);

	remove_quotes(s);

	copy(last[id], 127, s);

	Kick(id, s);

	return PLUGIN_HANDLED;
}

public MenuKickow(id)
{
	new players[32], name[33], temp[2][128], num, pl;

	get_players(players, num);

	new m = menu_create("Lista Graczy", "MenuKickow_");

	for (new i = 0; i < num; i++) {
		pl = players[i];

		get_user_name(pl, name, 32);

		num_to_str(pl, temp[0], 2);
		formatex(temp[1], 127, "%s%s", name, (get_user_flags(pl) & ADMIN_KICK) ? "\r *" : "");

		menu_additem(m, temp[1], temp[0], _, menu_makecallback("MenuKickow_c"));
	}

	menu_display(id, m);
}

public MenuKickow_(id, menu, item)
{
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_CONTINUE;
	}

	new data[6], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	g_kogo[id] = str_to_num(data);

	MenuPowodow(id);

	return PLUGIN_CONTINUE;
}

public MenuKickow_c(id, menu, item)
{
	new data[6], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new pl = str_to_num(data);

	if (get_user_flags(pl) & ADMIN_IMMUNITY || pl == id) return ITEM_DISABLED;

	return ITEM_ENABLED;
}

public MenuPowodow(id)
{
	new m = menu_create("Powody", "MenuPowodow_");
	new p[128];

	for (new i = 0; i < ArraySize(powody); i++) {
		ArrayGetString(powody, i, p, charsmax(p));
		menu_additem(m, p);
	}

	menu_addblank(m, 0);
	menu_additem(m, "Wlasny Powod");

	if (last[id][0] != '^0') {
		new temp[140]; formatex(temp, 139, "/y  %s", last[id]);
		menu_additem(m, temp);
	}

	menu_display(id, m);
}

public MenuPowodow_(id, menu, item)
{
	if (item == MENU_EXIT || !g_kogo[id]) {
		menu_destroy(menu);

		return PLUGIN_CONTINUE;
	}

	new m = ArraySize(powody);

	if (item == m) client_cmd(id, "messagemode amx_custom");
	else if (item == m+1) Kick(id, last[id]);
	else {
		new p[128]; ArrayGetString(powody, item, p, charsmax(p));
		Kick(id, p);
	}

	return PLUGIN_CONTINUE;
}

public Kick(id, const powod[])
{
	if (!g_kogo[id]) {
		client_print(id, print_chat, "%s Nie podano niezbednych danych", tag);
		return;
	}

	new bool: show = (get_cvar_num("amx_show_activity") == 2) ? true : false;
	new pl = g_kogo[id];
	new name[2][33];

	get_user_name(id, name[0], 32);
	get_user_name(pl, name[1], 32);

	show_hudmessage(0, "Gracz o nicku %s ^nZostal wyrzucony przez %s ^nPowod: %s", name[1], show ? name[0] : "admina", powod);

	log_amx("Gracz o nicku %s zostal wyrzucony przez %s. Powod: %s.", name[1], name[0], powod);

	console_print(pl, "%s ==========================================", tag);
	console_print(pl, "%s Zostales wyrzucony przez %s", tag, show ? name[0] : "admina");
	console_print(pl, "%s Powod: ^"%s^"", tag, powod);
	console_print(pl, "%s Jezeli uwazasz, ze kick byl bezpodstawny", tag);
	console_print(pl, "%s zglos to na %s", tag, strona);
	console_print(pl, "%s ==========================================", tag);

	server_cmd("kick #%d ^"%s^"", get_user_userid(pl), powod);
}
