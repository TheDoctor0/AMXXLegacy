#include <amxmodx>
#include <sqlx>
#include <sockets>
#include <unixtime>

#define PLUGIN "Sklep SMS"
#define VERSION "3.6.6"
#define AUTHOR "O'Zone"

#define TASK_SOCKET 4435
#define TASK_TIMEOUT 5432

#define DELIMITER 13

#define SS_OK -1
#define SS_ERROR -2
#define SS_STOP -3
#define SS_BAD_ARGS -4

#define TYPE_NICK 1<<0
#define TYPE_IP 1<<1
#define TYPE_SID 1<<2

#define ADMIN_FLAG_V (1<<21)
#define ADMIN_FLAG_W (1<<22)
#define ADMIN_FLAG_X (1<<23)

#define LOG_FILE "sklep_sms.log"

new const commandShop[][] = { "sklepsms", "say /sklepsms", "say_team /sklepsms", "say /shopsms", "say_team /shopsms", "say /sms", "say_team /sms" };
new const commandServices[][] = { "uslugi", "say /uslugi", "say_team /uslugi", "say /services", "say_team /services" };

enum _:playerData { PLAYER_SERVICE, PLAYER_TARIFF, PLAYER_TYPE, PLAYER_SOCKET, PLAYER_PASS_SS[32], PLAYER_PASS_PW[32], PLAYER_PASSWORD[32],
	PLAYER_AUTH[32], PLAYER_NAME[32], PLAYER_SID[32], PLAYER_IP[32], PLAYER_FLAGS[32], bool:PLAYER_CODE, bool:PLAYER_BUYING };
enum _:flagsData { FLAGS_TYPE, FLAGS_AUTH[32], FLAGS_PASSWORD[32], FLAGS_FLAGS[32] };
enum _:serviceData { SERVICE_ID[32], SERVICE_NAME[32], SERVICE_TYPES, Array:SERVICES_DATA, SERVICE_FLAGS[32],
	SERVICE_TAG[16], SERVICE_PLUGIN, SERVICE_DATA, SERVICE_ADDTOLISTING, SERVICE_CHOSEN, SERVICE_BOUGHT };
enum _:tariffData { SERVICE_NUMBER[16], SERVICE_TARIFF, SERVICE_AMOUNT };
enum _:serverData { SERVER_ID, SERVER_SERVICE[32], SERVER_CODE[32], SERVER_CURRENCY[32], SERVER_KEY[34], SERVER_URL[64], Float:SERVER_VAT };

new cvarHost[32], cvarUser[32], cvarPassword[32], cvarDatabase[32], cvarProvider, serverIP[32], serverPort[16], forwardAdminConnect,
	server[serverData], Handle:sql, Handle:connection, Array:registeredServices, Array:shopServices, Array:playerServices, playerBuy[MAX_PLAYERS + 1][playerData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("sklepsms_version", VERSION, FCVAR_SERVER);

	registeredServices = ArrayCreate(serviceData);
	shopServices = ArrayCreate(serviceData);
	playerServices = ArrayCreate(flagsData);

	bind_pcvar_string(create_cvar("sklepsms_sql_host", "localhost", FCVAR_SPONLY|FCVAR_PROTECTED), cvarHost, charsmax(cvarHost));
	bind_pcvar_string(create_cvar("sklepsms_sql_user", "user", FCVAR_SPONLY|FCVAR_PROTECTED), cvarUser, charsmax(cvarUser));
	bind_pcvar_string(create_cvar("sklepsms_sql_pass", "password", FCVAR_SPONLY|FCVAR_PROTECTED), cvarPassword, charsmax(cvarPassword));
	bind_pcvar_string(create_cvar("sklepsms_sql_db", "database", FCVAR_SPONLY|FCVAR_PROTECTED), cvarDatabase, charsmax(cvarDatabase));

	cvarProvider = get_cvar_pointer("dp_r_id_provider");

	for (new i; i < sizeof commandShop; i++) register_clcmd(commandShop[i], "shop_menu");
	for (new i; i < sizeof commandServices; i++) register_clcmd(commandServices[i], "show_services");

	register_concmd("Podaj_Kod_Zwrotny", "service_code");
	register_concmd("Podaj_Haslo", "service_password");

	register_concmd("ss_reload_services", "load_shop_data");
	register_concmd("ss_reload_players_services", "load_players_services");

	register_clcmd("say", "handle_say");
	register_clcmd("say_team", "handle_say");

	register_menucmd(register_menuid("SMS_Info"), (MENU_KEY_1 | MENU_KEY_0), "service_buy_handle");

	forwardAdminConnect = CreateMultiForward("amxbans_admin_connect", ET_IGNORE, FP_CELL);
}

public plugin_cfg()
{
	new configPath[64];

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/sklep_sms.cfg", configPath);

	server_exec();

	get_cvar_string("ip", serverIP, charsmax(serverIP));
	get_cvar_string("port", serverPort, charsmax(serverPort));

	sql_init();
}

public plugin_end()
{
	if (sql != Empty_Handle) SQL_FreeHandle(sql);
	if (connection != Empty_Handle) SQL_FreeHandle(connection);

	ArrayDestroy(shopServices);
	ArrayDestroy(playerServices);
}

public plugin_natives()
{
	register_library("shop_sms");

	register_native("ss_register_service", "_ss_register_service");
	register_native("ss_show_sms_info", "_ss_show_sms_info", 1);
}

public client_authorized(id)
	load_flags(id);

public client_disconnected(id)
{
	playerBuy[id][PLAYER_AUTH] = "";
	playerBuy[id][PLAYER_FLAGS] = "";
	playerBuy[id][PLAYER_PASS_SS] = "";
	playerBuy[id][PLAYER_PASS_PW] = "";

	playerBuy[id][PLAYER_CODE] = false;
	playerBuy[id][PLAYER_BUYING] = false;

	remove_task(id);
	remove_task(id + TASK_SOCKET);
	remove_task(id + TASK_TIMEOUT);
}

public show_services(id)
{
	new queryData[512], safeName[32], playerId[1];

	playerId[0] = id;

	mysql_escape_string(playerBuy[id][PLAYER_NAME], safeName, charsmax(safeName));

	formatex(queryData, charsmax(queryData), "SELECT a.type, b.expire, c.name FROM `ss_user_service_extra_flags` a JOIN `ss_user_service` b ON a.us_id = b.id JOIN `ss_services` c ON a.service = c.id WHERE a.server = '%i' AND (a.auth_data = '%s' OR a.auth_data = '%s' OR a.auth_data = '%s')",
		server[SERVER_ID], safeName, playerBuy[id][PLAYER_IP], playerBuy[id][PLAYER_SID]);

	SQL_ThreadQuery(sql, "show_services_menu", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_services_menu(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	new id = playerId[0];

	if (failState) {
		log_to_file(LOG_FILE, "[ERROR] SQL Error (Services): %s (%d)", error, errorNum);

		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil blad podczas ladowania twoich uslug. Sprobuj ponownie pozniej.");

		return;
	}

	new menuData[128], menu = menu_create("\rSKLEP SMS^n\yTwoje aktywne uslugi:\w", "show_services_menu_handle"), count = 0, type, expire, year, month, day, hour, minute, second;

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), menuData, charsmax(menuData));

		expire = SQL_ReadResult(query, SQL_FieldNameToNum(query, "expire"));

		if (expire != -1) {
			UnixToTime(expire, year, month, day, hour, minute, second, UT_TIMEZONE_SERVER);

			format(menuData, charsmax(menuData), "%s \y(Wygasa: %i/%i/%i %i:%i)", menuData, day, month, year, hour, minute);
		} else add(menuData, charsmax(menuData), " \y(Wygasa: Na Zawsze)");

		type = SQL_ReadResult(query, SQL_FieldNameToNum(query, "type"));

		if (type & TYPE_NICK) add(menuData, charsmax(menuData), " \r(Typ: Nick i Haslo)");
		if (type & TYPE_IP) add(menuData, charsmax(menuData), " \r(Typ: IP i Haslo)");
		if (type & TYPE_SID) add(menuData, charsmax(menuData), " \r(Typ: SteamID)");

		menu_additem(menu, menuData);

		count++;

		SQL_NextRow(query);
	}

	if (count) {
		menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
		menu_setprop(menu, MPROP_BACKNAME, "Wroc");
		menu_setprop(menu, MPROP_NEXTNAME, "Dalej");

		menu_display(id, menu);
	} else {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Nie posiadasz zadnych uslug. Moze pora to zmienic? Wpisz^x03 /sklepsms^x01.");
	}
}

public show_services_menu_handle(id, menu, item)
{
	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public shop_menu(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (ArraySize(shopServices)) {
		playerBuy[id][PLAYER_PASSWORD] = "";
		playerBuy[id][PLAYER_CODE] = false;
		playerBuy[id][PLAYER_BUYING] = true;

		new service[serviceData], callback = menu_makecallback("shop_menu_callback"),
        menu = menu_create("\rSKLEP SMS^n\yWybierz usluge:\w", "shop_menu_handle");

		for (new i = 0; i < ArraySize(shopServices); i++) {
			ArrayGetArray(shopServices, i, service);

			menu_additem(menu, service[SERVICE_NAME], _, _, callback);
		}

		menu_addblank(menu, 0);

		menu_additem(menu, "Aktywne \yUslugi");

		menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
		menu_setprop(menu, MPROP_BACKNAME, "Wroc");
		menu_setprop(menu, MPROP_NEXTNAME, "Dalej");

		menu_display(id, menu);
	} else client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Nie ma zadnych dostepnych do kupienia uslug.");

	return PLUGIN_HANDLED;
}

public shop_menu_callback(id, menu, item)
{
	new service[serviceData], ret;

	ArrayGetArray(shopServices, item, service);

	if (service[SERVICE_ADDTOLISTING]) {
		ExecuteForward(service[SERVICE_ADDTOLISTING], ret, id, service[SERVICE_FLAGS]);

		return ret;
	}

	return ITEM_ENABLED;
}

public shop_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || item == MENU_EXIT) {
		playerBuy[id][PLAYER_BUYING] = false;

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	if (item == ArraySize(shopServices)) {
		show_services(id);

		return PLUGIN_HANDLED;
	}

	new service[serviceData], tariff[tariffData];

	ArrayGetArray(shopServices, item, service);

	if (check_service_unlimited(id, service[SERVICE_NAME], service[SERVICE_FLAGS])) {
		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Posiadasz juz ta usluge wykupiona^x03 na zawsze^x01.");

		return PLUGIN_HANDLED;
	}

	playerBuy[id][PLAYER_SERVICE] = item;

	if (ArraySize(service[SERVICES_DATA])) {
		new menuData[128];

		formatex(menuData, charsmax(menuData), "\rSKLEP SMS^n\y%s - Wybierz ilosc %s:\w", service[SERVICE_NAME], service[SERVICE_TAG]);

		new menu = menu_create(menuData, "service_tariff_handle"), Float:servicePrice;

		for (new i = 0; i < ArraySize(service[SERVICES_DATA]); i++) {
			ArrayGetArray(service[SERVICES_DATA], i, tariff);

			servicePrice = float(tariff[SERVICE_TARIFF]);

			formatex(menuData, charsmax(menuData), "\y%i %s\w za %.2f %s + VAT \d( %.2f %s )", tariff[SERVICE_AMOUNT], service[SERVICE_TAG], servicePrice, server[SERVER_CURRENCY], servicePrice * server[SERVER_VAT], server[SERVER_CURRENCY]);

			menu_additem(menu, menuData);
		}

		menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
		menu_setprop(menu, MPROP_BACKNAME, "Wroc");
		menu_setprop(menu, MPROP_NEXTNAME, "Dalej");

		menu_display(id, menu);
	} else client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Ta usluga nie ma zdefiniowanego cennika.");

	return PLUGIN_HANDLED;
}

public service_tariff_handle(id, menu, item)
{
	if (!is_user_connected(id) || item == MENU_EXIT) {
		playerBuy[id][PLAYER_BUYING] = false;

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	playerBuy[id][PLAYER_TARIFF] = item;

	new service[serviceData], ret;

	ArrayGetArray(shopServices, playerBuy[id][PLAYER_SERVICE], service);

	if (service[SERVICE_CHOSEN]) {
		ExecuteForward(service[SERVICE_CHOSEN], ret, id, item);

		if (ret == SS_STOP) return PLUGIN_HANDLED;
	}

	if (service[SERVICE_TYPES]) {
		new menu = menu_create("\rSKLEP SMS^n\yWybierz typ uslugi:\w", "service_type_handle"), callback = menu_makecallback("service_tariff_callback");

		menu_additem(menu, "Na Nick i Haslo", _, _, callback);
		menu_additem(menu, "Na IP i Haslo", _, _, callback);
		menu_additem(menu, "Na SteamID", _, _, callback);

		menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");

		menu_display(id, menu);
	} else service_buy(id);

	return PLUGIN_HANDLED;
}

public service_tariff_callback(id, menu, item)
{
	static service[serviceData];

	ArrayGetArray(shopServices, playerBuy[id][PLAYER_SERVICE], service);

	switch(item) {
		case 0: if (!(service[SERVICE_TYPES] & TYPE_NICK)) return ITEM_DISABLED;
		case 1: if (!(service[SERVICE_TYPES] & TYPE_IP)) return ITEM_DISABLED;
		case 2: if (!(service[SERVICE_TYPES] & TYPE_SID) || !is_user_steam(id)) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public service_type_handle(id, menu, item)
{
	if (!is_user_connected(id) || item == MENU_EXIT) {
		playerBuy[id][PLAYER_BUYING] = false;

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	switch(item) {
		case 0: {
			playerBuy[id][PLAYER_TYPE] = TYPE_NICK;

			copy(playerBuy[id][PLAYER_AUTH], charsmax(playerBuy[][PLAYER_AUTH]), playerBuy[id][PLAYER_NAME]);
		} case 1: {
			playerBuy[id][PLAYER_TYPE] = TYPE_IP;

			copy(playerBuy[id][PLAYER_AUTH], charsmax(playerBuy[][PLAYER_IP]), playerBuy[id][PLAYER_IP]);
		} case 2: {
			playerBuy[id][PLAYER_TYPE] = TYPE_SID;

			copy(playerBuy[id][PLAYER_AUTH], charsmax(playerBuy[][PLAYER_SID]), playerBuy[id][PLAYER_SID]);
		}
	}

	if (item != 2) {
		client_print(id, print_center, "Podaj haslo uslugi");

		client_cmd(id, "messagemode Podaj_Haslo");
	} else service_buy(id);

	return PLUGIN_HANDLED;
}

public service_buy(id)
{
	remove_task(id);

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new service[serviceData], tariff[tariffData], menuData[512];

	ArrayGetArray(shopServices, playerBuy[id][PLAYER_SERVICE], service);

	ArrayGetArray(service[SERVICES_DATA], playerBuy[id][PLAYER_TARIFF], tariff);

	new Float:servicePrice = float(tariff[SERVICE_TARIFF]);

	formatex(menuData, charsmax(menuData), "\rSKLEP SMS^n^nWybrales/as opcje zakupu %s^n\wIlosc: \y%i %s^n^n\rW celu dokonania zakupu, wyslij SMSa^n\wO tresci: \y%s^n\wNa numer: \y%s^n\wKoszt: \y%.2f %s + VAT \d( %.2f %s )^n^n\wPo wyslaniu SMSa poczekaj na kod zwrotny.^nW celu wprowadzenia go wcisnij: \y1^n^n\wAby wyjsc, wcisnij: \y0",
		service[SERVICE_NAME], tariff[SERVICE_AMOUNT], service[SERVICE_TAG], server[SERVER_CODE], tariff[SERVICE_NUMBER], servicePrice, server[SERVER_CURRENCY], servicePrice * server[SERVER_VAT], server[SERVER_CURRENCY]);

	show_menu(id, (MENU_KEY_1 | MENU_KEY_0), menuData, -1, "SMS_Info");

	set_task(1.0, "service_buy", id, .flags = "b");

	return PLUGIN_HANDLED;
}

public service_buy_handle(id, key)
{
	remove_task(id);

	if (!is_user_connected(id) || key) {
		playerBuy[id][PLAYER_BUYING] = false;

		return PLUGIN_HANDLED;
	}

	client_print(id, print_center, "Podaj kod zwrotny");

	client_cmd(id, "messagemode Podaj_Kod_Zwrotny");

	playerBuy[id][PLAYER_CODE] = true;

	return PLUGIN_HANDLED;
}

public service_password(id)
{
	if (!is_user_connected(id) || !playerBuy[id][PLAYER_BUYING]) return PLUGIN_HANDLED;

	read_args(playerBuy[id][PLAYER_PASSWORD], charsmax(playerBuy[][PLAYER_PASSWORD]));

	remove_quotes(playerBuy[id][PLAYER_PASSWORD]);

	trim(playerBuy[id][PLAYER_PASSWORD]);

	if (strlen(playerBuy[id][PLAYER_PASSWORD]) < 8) {
		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Haslo uslugi musi miec co najmniej^x03 8 znakow^x01.");

		client_print(id, print_center, "Podaj haslo uslugi");

		client_cmd(id, "messagemode Podaj_Haslo");

		return PLUGIN_HANDLED;
	}

	new queryData[192], safeName[64], tempId[1];

	mysql_escape_string(playerBuy[id][PLAYER_NAME], safeName, charsmax(safeName));

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT password FROM `ss_players_flags` WHERE (auth_data = '%s' OR auth_data = '%s') AND server = '%i'", safeName, playerBuy[id][PLAYER_IP], server[SERVER_ID]);
	SQL_ThreadQuery(sql, "service_password_validate", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public service_password_validate(failState, Handle:query, error[], errorNum, tempData[], dataSize)
{
	new id = tempData[0];

	if (failState) {
		log_to_file(LOG_FILE, "[ERROR] SQL Error (Password): %s (%d)", error, errorNum);

		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil blad podczas sprawdzania hasla. Sprobuj ponownie pozniej.");

		return PLUGIN_HANDLED;
	}

	new password[32];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "password"), password, charsmax(password));

		if (!equal(playerBuy[id][PLAYER_PASSWORD], password)) {
			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Istnieje juz usluga wykupiona na ten^x03 nick lub IP^x01, lecz posiada inne haslo.");
			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Sprobuj wprowadzic^x03 haslo^x01 jeszcze raz.");

			client_cmd(id, "messagemode Podaj_Haslo");

			return PLUGIN_HANDLED;
		}

		SQL_NextRow(query);
	}

	service_buy(id);

	return PLUGIN_HANDLED;
}

public service_code(id)
{
	if (!is_user_connected(id) || !playerBuy[id][PLAYER_CODE]) return PLUGIN_HANDLED;

	new code[32];

	read_args(code, charsmax(code));

	remove_quotes(code);

	trim(code);

	strtoupper(code);

	if (!strlen(code))
	{
		client_print(id, print_center, "Podaj kod zwrotny");

		client_cmd(id, "messagemode Podaj_Kod_Zwrotny");

		return PLUGIN_HANDLED;
	}

	service_code_validate(id, code);

	return PLUGIN_HANDLED;
}

public handle_say(id)
{
	if (!playerBuy[id][PLAYER_CODE]) return PLUGIN_CONTINUE;

	new code[32];

	read_args(code, charsmax(code));

	if (strlen(code)) {
		service_code_validate(id, code);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public service_code_validate(id, code[])
{
	playerBuy[id][PLAYER_CODE] = false;

	new tempUrl[128], host[64], url[64], bool:error, socketError;

	copy(tempUrl, charsmax(tempUrl), server[SERVER_URL]);

	replace_all(tempUrl, charsmax(tempUrl), "http://", "");
	replace_all(tempUrl, charsmax(tempUrl), "https://", "");

	strtok(tempUrl, host, charsmax(host), url, charsmax(url), '/');

	if (url[0]) format(url, charsmax(url), "/%s", url);

	playerBuy[id][PLAYER_SOCKET] = socket_open(host, 80, SOCKET_TCP, socketError);

	switch (socketError) {
		case 1: {
			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil blad poczas weryfikacji kodu. Sprobuj ponownie pozniej.");

			log_to_file(LOG_FILE, "[ERROR] Nie udalo sie utworzyc socketa.");

			error = true;
		} case 2: {
			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil blad poczas weryfikacji kodu. Sprobuj ponownie pozniej.");

			log_to_file(LOG_FILE, "[ERROR] Nie udalo sie znalezc hosta.");

			error = true;
		} case 3: {
			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil blad poczas weryfikacji kodu. Sprobuj ponownie pozniej.");

			log_to_file(LOG_FILE, "[ERROR] Nie udalo sie utworzyc polaczenia.");

			error = true;
		}
	}

	new service[serviceData], tariff[tariffData], socketData[1024], serviceUrl[512];

	ArrayGetArray(shopServices, playerBuy[id][PLAYER_SERVICE], service);
	ArrayGetArray(service[SERVICES_DATA], playerBuy[id][PLAYER_TARIFF], tariff);

	formatex(serviceUrl, charsmax(serviceUrl), "%s/servers_stuff.php?key=%s&action=purchase_service&platform=engine_amxx&service=%s&type=%d&auth_data=%s&password=%s&method=sms&server=%d&transaction_service=%s&sms_code=%s&tariff=%d&uid=0&ip=%s&language=polish",
		url, server[SERVER_KEY], service[SERVICE_ID], playerBuy[id][PLAYER_TYPE], playerBuy[id][PLAYER_AUTH], playerBuy[id][PLAYER_PASSWORD], server[SERVER_ID], server[SERVER_SERVICE], code, tariff[SERVICE_TARIFF], playerBuy[id][PLAYER_IP]);

	url_encode(serviceUrl, socketData, charsmax(socketData));
	log_to_file(LOG_FILE, "%s", socketData);
	format(socketData, charsmax(socketData), "GET %s HTTP/1.1^nHost: %s^r^n^r^n", socketData, host);
	log_to_file(LOG_FILE, "%s", socketData);

	if (error) log_to_file(LOG_FILE, "[ERROR] %s", socketData);
	else {
		socket_send(playerBuy[id][PLAYER_SOCKET], socketData, charsmax(socketData));

		client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Trwa weryfikacja kodu sms...");

		set_task(0.1, "service_code_verified", id + TASK_SOCKET, .flags = "b");

		set_task(15.0, "service_socket_timeout", id + TASK_TIMEOUT);
	}
}

public service_socket_timeout(id)
{
	id -= TASK_TIMEOUT;

	remove_task(id + TASK_SOCKET);

	log_to_file(LOG_FILE, "Zakup nie zostal sfinalizowany z powodu przekroczenia limitu czasu polaczenia.");

	new motdData[1024];

	formatex(motdData, charsmax(motdData), "<head><style type='text/css'>body{background-color:#0f0f0f;color:#ccc;font-size:14px;}</style><meta http-equiv='Content-Type' content='text/html; charset=utf8'></head><body><center><br/><h1>Przekroczeno limit czasu polaczenia!<br/>Sprobuj ponownie za chwile.<br/><br/>W razie dalszych problemow zglos to na<br/><font color='red'>CS-Reload.pl</font><br/>");

	show_motd(id, motdData, "Blad");

	client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Zakup^x03 nie zostal sfinalizowany^x01 z powodu przekroczenia limitu czasu polaczenia.");
}

public service_code_verified(id)
{
	id -= TASK_SOCKET;

	if (socket_is_readable(playerBuy[id][PLAYER_SOCKET])) {
		remove_task(id + TASK_SOCKET);
		remove_task(id + TASK_TIMEOUT);

		new socketResponse[1024], responseData[256], lineData[256], httpTempCode[4];

		socket_recv(playerBuy[id][PLAYER_SOCKET], socketResponse, charsmax(socketResponse));

		replace(socketResponse, charsmax(socketResponse), "HTTP/1.1 ", "");

		copy(httpTempCode, charsmax(httpTempCode), socketResponse);

		new httpCode = str_to_num(httpTempCode), dataLength = strlen(socketResponse), length = 4;

		if (httpCode >= 300 || httpCode < 200) {
			log_to_file(LOG_FILE, "[ERROR] %s", socketResponse);

			new motdData[1024];

			formatex(motdData, charsmax(motdData), "<head><style type='text/css'>body{background-color:#0f0f0f;color:#ccc;font-size:14px;}</style><meta http-equiv='Content-Type' content='text/html; charset=utf8'></head><body><center><br/><h1>Wystapil nieoczekiwany blad!<br/>Sprobuj ponownie za chwile.<br/><br/>W razie dalszych problemow zglos to na<br/><font color='red'>CS-Reload.pl</font><br/>");

			show_motd(id, motdData, "Blad");

			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil^x03 nieoczekiwany blad^x01. Sprobuj ponownie za chwile.");

			return;
		}

		while (length < dataLength) {
			length += (1 + copyc(lineData, charsmax(lineData), socketResponse[length], DELIMITER));

			if (lineData[1] == '<') copy(responseData, charsmax(responseData), lineData[1]);
		}

		new responseReturnValue[32], responseText[64];

		get_value(responseData, "return_value", responseReturnValue, charsmax(responseReturnValue));
		get_value(responseData, "text", responseText, charsmax(responseText));

		if (equal(responseReturnValue, "purchased")) {
			new service[serviceData], tariff[tariffData], ret;

			ArrayGetArray(shopServices, playerBuy[id][PLAYER_SERVICE], service);

			ArrayGetArray(service[SERVICES_DATA], playerBuy[id][PLAYER_TARIFF], tariff);

			if (service[SERVICE_BOUGHT]) ExecuteForward(service[SERVICE_BOUGHT], ret, id, tariff[SERVICE_AMOUNT]);

			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 %s", responseText);

			if (service[SERVICE_TYPES]) {
				new motdData[1024], flags[flagsData];

				formatex(motdData, charsmax(motdData), "<head><style type='text/css'>body{background-color:#0f0f0f;color:#ccc;font-size:14px;}</style><meta http-equiv='Content-Type' content='text/html; charset=utf8'></head><body><center><br/><h1>Wykupiles/as usluge: <font color='red'>%s</font><br/><br/>", service[SERVICE_NAME]);

				if (!(playerBuy[id][PLAYER_TYPE] & TYPE_SID)) format(motdData, charsmax(motdData), "%sAby usluga dzialala wpisz w konsoli lub dodaj do pliku config.cfg:<br/><font color='#3399ff'>setinfo _ss ^"%s^"</font><br/><br/>", motdData, playerBuy[id][PLAYER_PASSWORD]);

				format(motdData, charsmax(motdData), "%s<i>W razie problemow skontaktuj sie z nami.</i></center>", motdData);

				show_motd(id, motdData, "Informacje dotyczace uslugi");

				cmd_execute(id, "setinfo _ss ^"%s^"", playerBuy[id][PLAYER_PASSWORD]);
				set_user_info(id, "_ss", playerBuy[id][PLAYER_PASSWORD]);

				add(playerBuy[id][PLAYER_FLAGS], charsmax(playerBuy[][PLAYER_FLAGS]), service[SERVICE_FLAGS]);

				set_user_flags(id, get_user_flags(id) | read_flags(playerBuy[id][PLAYER_FLAGS]));

				copy(flags[FLAGS_AUTH], charsmax(flags[FLAGS_AUTH]), playerBuy[id][PLAYER_AUTH]);
				copy(flags[FLAGS_PASSWORD], charsmax(flags[FLAGS_PASSWORD]), playerBuy[id][PLAYER_PASSWORD]);
				copy(flags[FLAGS_FLAGS], charsmax(flags[FLAGS_FLAGS]), service[SERVICE_FLAGS]);

				ArrayPushArray(playerServices, flags);

				ExecuteForward(forwardAdminConnect, ret, id);
			} else client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Zakupiles^x04 %s^x01:^x03 %i %s^x01.", service[SERVICE_NAME], tariff[SERVICE_AMOUNT], service[SERVICE_TAG]);
		} else if (equal(responseReturnValue, "bad_code") || equal(responseReturnValue, "bad_data") || equal(responseReturnValue, "bad_email") || equal(responseReturnValue, "bad_number")) client_print_color(id, id, "^x04[SKLEP-SMS]^x01 %s", responseText);
		else {
			log_to_file(LOG_FILE, "[ERROR] %s", socketResponse);

			new motdData[1024];

			formatex(motdData, charsmax(motdData), "<head><style type='text/css'>body{background-color:#0f0f0f;color:#ccc;font-size:14px;}</style><meta http-equiv='Content-Type' content='text/html; charset=utf8'></head><body><center><br/><h1>Wystapil wewnetrzny blad!<br/><br/>Powiadom nas o tym na<br/><font color='red'>CS-Reload.pl</font><br/>");

			show_motd(id, motdData, "Blad");

			client_print_color(id, id, "^x04[SKLEP-SMS]^x01 Wystapil^x03 wewnetrzny blad^x01. Powiadam nas o tym.");
		}

		socket_close(playerBuy[id][PLAYER_SOCKET]);
	}
}

public sql_init()
{
	new error[64], errorNum;

	sql = SQL_MakeDbTuple(cvarHost, cvarUser, cvarPassword, cvarDatabase);

	connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file(LOG_FILE, "[ERROR] SQL Error (Init): %s (%d)", error, errorNum);

		set_task(5.0, "sql_init");

		return;
	}

	new queryData[512];

	formatex(queryData, charsmax(queryData), "UPDATE `ss_servers` SET type = 'amxx', version = '%s' WHERE ip = '%s' AND port = '%s'", VERSION, serverIP, serverPort);

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);

	load_players_services();

	load_shop_data();
}

public load_players_services()
{
	new queryData[512];

	ArrayClear(playerServices);

	formatex(queryData, charsmax(queryData), "SELECT f.type, f.auth_data, f.password, f.a, f.b, f.c, f.d, f.e, f.f, f.g, f.h, f.i, f.j, f.k, f.l, f.m, f.n, f.o, f.p, f.q, f.r, f.s, f.t, f.u, f.v, f.y, f.w, f.x, f.z \
	FROM `ss_players_flags` AS f JOIN `ss_servers` AS s ON s.id = f.server WHERE s.ip = '%s' AND s.port = '%s' ORDER BY f.auth_data, f.type DESC", serverIP, serverPort);

	SQL_ThreadQuery(sql, "load_players_services_handle", queryData);
}

public load_players_services_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file(LOG_FILE, "[ERROR] SQL Error (Players): %s (%d)", error, errorNum);

		set_fail_state("Wystapil blad podczas ladowania danych SklepuSMS. Sprawdz logi bledow!");

		return;
	}

	while (SQL_MoreResults(query)) {
		new flags[flagsData], flagTimestamp, allFlags[][] = { "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","y","v","w","x","z" };

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "auth_data"), flags[FLAGS_AUTH], charsmax(flags[FLAGS_AUTH]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "password"), flags[FLAGS_PASSWORD], charsmax(flags[FLAGS_PASSWORD]));

		flags[FLAGS_TYPE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "type"));

		for (new i = 0; i < sizeof(allFlags); i++) {
			flagTimestamp = SQL_ReadResult(query, SQL_FieldNameToNum(query, allFlags[i]));

			if (flagTimestamp != 0) add(flags[FLAGS_FLAGS], charsmax(flags[FLAGS_FLAGS]), allFlags[i], charsmax(allFlags[]));
		}

		ArrayPushArray(playerServices, flags);

		SQL_NextRow(query);
	}

	log_amx("Zaladowano %i uslug graczy.", ArraySize(playerServices));

	reload_players_flags();
}

public load_shop_data()
{
	new queryData[1024];

	ArrayClear(shopServices);

	formatex(queryData, charsmax(queryData), "SELECT a.id, a.sms_service, c.data as sms_code, c.sms, b.service_id, d.name as service, d.types, e.tariff, f.number, d.flags, e.amount, d.tag, g.value as url, h.value as vat, i.value as random_key, j.value as currency \
	FROM `ss_servers` AS a \
	LEFT JOIN `ss_servers_services` AS b ON a.id = b.server_id \
	LEFT JOIN `ss_transaction_services` AS c ON a.sms_service = c.id \
	LEFT JOIN `ss_services` AS d ON b.service_id = d.id \
	LEFT JOIN `ss_pricelist` AS e ON (b.service_id = e.service AND (e.server = b.server_id OR e.server = '-1')) \
	LEFT JOIN `ss_sms_numbers` AS f ON (e.tariff = f.tariff AND a.sms_service = f.service) \
	JOIN `ss_settings` g \
	JOIN `ss_settings` h \
	JOIN `ss_settings` i \
	JOIN `ss_settings` j \
	WHERE g.key = 'shop_url' AND h.key = 'vat' AND i.key = 'random_key' AND j.key = 'currency' AND c.sms = '1' AND a.ip = '%s' AND a.port = '%s' ORDER BY d.order, e.tariff, e.server DESC", serverIP, serverPort);

	SQL_ThreadQuery(sql, "load_shop_data_handle", queryData);
}

public load_shop_data_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file(LOG_FILE, "[ERROR] SQL Error (Shop): %s (%d)", error, errorNum);

		set_fail_state("Wystapil blad podczas ladowania danych SklepuSMS. Sprawdz logi bledow!");

		return;
	}

	new service[serviceData], tariff[tariffData], codeData[64], serviceId[32], ret;

	while (SQL_MoreResults(query)) {
		if (!server[SERVER_ID]) {
			if (!SQL_ReadResult(query, SQL_FieldNameToNum(query, "sms"))) set_fail_state("Metoda platnosci wybrana dla serwera nie obsluguje SMSow!");

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "sms_code"), codeData, charsmax(codeData));

			get_value(codeData, _, server[SERVER_CODE], charsmax(server[SERVER_CODE]), 1);

			if (!server[SERVER_CODE][0]) set_fail_state("Metoda platnosci wybrana dla serwera nie posiada podanej tresci SMS!");

			server[SERVER_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "sms_service"), server[SERVER_SERVICE], charsmax(server[SERVER_SERVICE]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "url"), server[SERVER_URL], charsmax(server[SERVER_URL]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "currency"), server[SERVER_CURRENCY], charsmax(server[SERVER_CURRENCY]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "random_key"), server[SERVER_KEY], charsmax(server[SERVER_KEY]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "vat"), server[SERVER_VAT]);

			if (!server[SERVER_URL]) {
				set_fail_state("SklepSMS nie posiada zdefiniowanego adresu URL.");
			} else if (!server[SERVER_SERVICE]) {
				set_fail_state("SklepSMS nie posiada zdefiniowanego serwisu uslug SMS.");
			}

			hash_string(server[SERVER_KEY], Hash_Md5, server[SERVER_KEY], charsmax(server[SERVER_KEY]));
		}

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "service_id"), serviceId, charsmax(serviceId));

		service[SERVICE_PLUGIN] = get_service_plugin(serviceId);

		if (!service[SERVICE_PLUGIN]) {
			SQL_NextRow(query);

			if (!SQL_MoreResults(query)) ArrayPushArray(shopServices, service);

			continue;
		}

		if (!equal(serviceId, service[SERVICE_ID])) {
			if (service[SERVICE_ID][0]) ArrayPushArray(shopServices, service);

			copy(service[SERVICE_ID], charsmax(service[SERVICE_ID]), serviceId);

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "service"), service[SERVICE_NAME], charsmax(service[SERVICE_NAME]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "flags"), service[SERVICE_FLAGS], charsmax(service[SERVICE_FLAGS]));
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "tag"), service[SERVICE_TAG], charsmax(service[SERVICE_TAG]));

			service[SERVICE_TYPES] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "types"));

			service[SERVICE_DATA] = CreateOneForward(service[SERVICE_PLUGIN], "ss_service_data", FP_STRING, FP_STRING);
			service[SERVICE_ADDTOLISTING] = CreateOneForward(service[SERVICE_PLUGIN], "ss_service_addingtolist", FP_CELL, FP_STRING);
			service[SERVICE_CHOSEN] = CreateOneForward(service[SERVICE_PLUGIN], "ss_service_chosen", FP_CELL, FP_CELL);
			service[SERVICE_BOUGHT] = CreateOneForward(service[SERVICE_PLUGIN], "ss_service_bought", FP_CELL, FP_CELL);

			if (service[SERVICE_DATA]) ExecuteForward(service[SERVICE_DATA], ret, service[SERVICE_NAME], service[SERVICE_FLAGS]);

			service[SERVICES_DATA] = ArrayCreate(tariffData);
		}

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "number"), tariff[SERVICE_NUMBER], charsmax(tariff[SERVICE_NUMBER]));

		tariff[SERVICE_TARIFF] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "tariff"));
		tariff[SERVICE_AMOUNT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "amount"));

		if (strlen(tariff[SERVICE_NUMBER])) {
			if (!tariff_defined(service[SERVICES_DATA], tariff[SERVICE_TARIFF])) ArrayPushArray(service[SERVICES_DATA], tariff);
		} else log_to_file(LOG_FILE, "[ERROR] Nieprawidlowy cennik uslugi %s (%i %s).", service[SERVICE_NAME], tariff[SERVICE_AMOUNT], service[SERVICE_TAG]);

		SQL_NextRow(query);

		if (!SQL_MoreResults(query)) ArrayPushArray(shopServices, service);
	}

	if (!server[SERVER_ID]) set_fail_state("Ten serwer nie znajduje sie w bazie danych SklepuSMS.");

	log_amx("Zaladowano %i uslug do kupienia.", ArraySize(shopServices));
}

public load_flags(id)
{
	get_user_info(id, "_ss", playerBuy[id][PLAYER_PASS_SS], charsmax(playerBuy[][PLAYER_PASS_SS]));
	get_user_info(id, "_pw", playerBuy[id][PLAYER_PASS_PW], charsmax(playerBuy[][PLAYER_PASS_PW]));
	get_user_name(id, playerBuy[id][PLAYER_NAME], charsmax(playerBuy[][PLAYER_NAME]));
	get_user_ip(id, playerBuy[id][PLAYER_IP], charsmax(playerBuy[][PLAYER_IP]), 1);
	get_user_authid(id, playerBuy[id][PLAYER_SID], charsmax(playerBuy[][PLAYER_SID]));

	new flags[flagsData], ret;

	for (new i = 0; i < ArraySize(playerServices); i++) {
		ArrayGetArray(playerServices, i, flags);

		switch(flags[FLAGS_TYPE]) {
			case TYPE_NICK: {
				if (equal(flags[FLAGS_AUTH], playerBuy[id][PLAYER_NAME])) {
					if (equal(flags[FLAGS_PASSWORD], playerBuy[id][PLAYER_PASS_SS]) || equal(flags[FLAGS_PASSWORD], playerBuy[id][PLAYER_PASS_PW])) add(playerBuy[id][PLAYER_FLAGS], charsmax(playerBuy[][PLAYER_FLAGS]), flags[FLAGS_FLAGS], charsmax(flags[FLAGS_FLAGS]));
					else {
						server_cmd("kick #%d ^"Nieprawidlowe haslo^"", get_user_userid(id));

						break;
					}
				}
			} case TYPE_IP: {
				if (equal(flags[FLAGS_AUTH], playerBuy[id][PLAYER_IP])) {
					if (playerBuy[id][PLAYER_PASS_SS] && (equal(flags[FLAGS_PASSWORD], playerBuy[id][PLAYER_PASS_SS]) || equal(flags[FLAGS_PASSWORD], playerBuy[id][PLAYER_PASS_PW]))) add(playerBuy[id][PLAYER_FLAGS], charsmax(playerBuy[][PLAYER_FLAGS]), flags[FLAGS_FLAGS], charsmax(flags[FLAGS_FLAGS]));
					else {
						server_cmd("kick #%d ^"Nieprawidlowe haslo^"", get_user_userid(id));

						break;
					}
				}
			} case TYPE_SID: if (equal(flags[FLAGS_AUTH], playerBuy[id][PLAYER_SID])) add(playerBuy[id][PLAYER_FLAGS], charsmax(playerBuy[][PLAYER_FLAGS]), flags[FLAGS_FLAGS], charsmax(flags[FLAGS_FLAGS]));
		}
	}

	if (!playerBuy[id][PLAYER_FLAGS][0]) return;

	set_user_flags(id, get_user_flags(id) | read_flags(playerBuy[id][PLAYER_FLAGS]));

	ExecuteForward(forwardAdminConnect, ret, id);

	log_amx("Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^") (nick ^"^") (static 0)",
		playerBuy[id][PLAYER_NAME], get_user_userid(id), playerBuy[id][PLAYER_SID], playerBuy[id][PLAYER_SID], playerBuy[id][PLAYER_FLAGS], playerBuy[id][PLAYER_IP]);
}

public check_service_unlimited(id, service[], flags[])
{
	new queryData[512], serviceName[64], safeName[32], bool:unlimited;

	mysql_escape_string(playerBuy[id][PLAYER_NAME], safeName, charsmax(safeName));

	copy(serviceName, charsmax(serviceName), service)

	strtolower(serviceName);

	formatex(queryData, charsmax(queryData), "SELECT b.expire FROM `ss_user_service_extra_flags` a JOIN `ss_user_service` b ON a.us_id = b.id JOIN `ss_services` c ON a.service = c.id WHERE a.server = '%i' AND (a.auth_data = '%s' OR a.auth_data = '%s' OR a.auth_data = '%s') AND a.service = '%s'",
		server[SERVER_ID], safeName, playerBuy[id][PLAYER_IP], playerBuy[id][PLAYER_SID], serviceName);

	new error[128], errorNum, Handle:query;

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if ((!SQL_NumResults(query) && get_user_flags(id) & read_flags(flags)) || (SQL_NumResults(query) && SQL_ReadResult(query, 0) == -1)) unlimited = true;
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file(LOG_FILE, "[ERROR] SQL Query Error: [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return unlimited;
}

public amxbans_sql_initialized(info, const prefix[])
{
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (is_user_connected(id) && playerBuy[id][PLAYER_FLAGS][0]) {
			set_user_flags(id, get_user_flags(id) | read_flags(playerBuy[id][PLAYER_FLAGS]));

			log_amx("Login: ^"%s<%d><%s><>^" became an admin (account ^"%s^") (access ^"%s^") (address ^"%s^") (nick ^"^") (static 0)",
			playerBuy[id][PLAYER_NAME], get_user_userid(id), playerBuy[id][PLAYER_SID], playerBuy[id][PLAYER_SID], playerBuy[id][PLAYER_FLAGS], playerBuy[id][PLAYER_IP]);
		}
	}
}

public reload_players_flags()
	for (new id = 1; id <= MAX_PLAYERS; id++) if (is_user_connected(id)) load_flags(id);

public _ss_register_service(plugin, params)
{
	if (params != 1) return PLUGIN_CONTINUE;

	new service[serviceData];

	get_string(1, service[SERVICE_ID], charsmax(service[SERVICE_ID]));

	service[SERVICE_PLUGIN] = plugin;

	ArrayPushArray(registeredServices, service);

	return ArraySize(registeredServices) - 1;
}

public _ss_show_sms_info(id)
	service_buy(id);

stock get_service_plugin(serviceId[])
{
	new service[serviceData];

	for (new i = 0; i < ArraySize(registeredServices); i++) {
		ArrayGetArray(registeredServices, i, service);

		if (equal(service[SERVICE_ID], serviceId)) return service[SERVICE_PLUGIN];
	}

	return 0;
}

stock get_value(const input[], const tag[] = "", output[], length, type = 0)
{
	new tempData[128], value[64], startTag[32], endTag[32];

	if (type) {
		formatex(startTag, charsmax(startTag), "^"sms_text^":^"");
		formatex(endTag, charsmax(endTag), "^"");
	} else {
		formatex(startTag, charsmax(startTag), "<%s>", tag);
		formatex(endTag, charsmax(endTag), "</%s>", tag);
	}

	copy(tempData, charsmax(tempData), input);

	split(tempData, value, charsmax(value), tempData, charsmax(tempData), startTag);
	split(tempData, value, charsmax(value), tempData, charsmax(tempData), endTag);

	copy(output, length, value);
}

stock bool:tariff_defined(Array:service, tariff)
{
	new serviceTariff[tariffData];

	for (new i = 0; i < ArraySize(service); i++) {
		ArrayGetArray(service, i, serviceTariff);

		if (serviceTariff[SERVICE_TARIFF] == tariff) return true;
	}

	return false;
}

stock bool:is_user_steam(id)
{
	server_cmd("dp_clientinfo %d", id);
	server_exec();

	static client;
	client = get_pcvar_num(cvarProvider);

	if (client == 2) return true;

	return false;
}

stock cmd_execute(id, const text[], any:...)
{
	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);

	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}

stock url_encode(const source[], dest[], length)
{
	static const hexChars[16] = {
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66
	};

	new urlPos, urlChar, urlLength;

	while ((urlChar = source[urlPos]) && urlLength < length) {
        if (urlChar == 0x20) {
            dest[urlLength++] = 0x2B;
        } else if (
        	!(0x41 <= urlChar <= 0x5A)
        	&& !(0x61 <= urlChar <= 0x7A)
        	&& !(0x30 <= urlChar <= 0x39)
        	&& urlChar != 0x2D
        	&& urlChar != 0x2E
        	&& urlChar != 0x5F
        ) {
            if((urlLength + 3) > length) {
                break;
            } else if(urlChar > 0xFF || urlChar < 0x00) {
                urlChar = 0x2A;
            }

            dest[urlLength++] = 0x25;
            dest[urlLength++] = hexChars[urlChar >> 4];
            dest[urlLength++] = hexChars[urlChar & 15];
        } else {
            dest[urlLength++] = urlChar;
        }

        urlPos++;
	}

	dest[urlLength] = 0;
}