#include <amxmodx>
#include <amxmisc>

#define SQL_ZAPIS

#define TASK_SCREEN 56323

enum _:cvary { HOST, USER, PASS, DBNAME, SSAMOUNT, TYPE, INTERVAL, SITE, BAN, BANTIME, BANREASON }

new const tag[] 			= "[SSB]";
new const name[] 		= "ScreenShotBan";

new gCvars[cvary];
new gScreens[33];
new gScreened[33];

new g_SyncHud;

#if defined SQL_ZAPIS
#include <sqlx>

new gMapa[33];
new gNazwa[101];

new Handle: g_SqlTuple;

public SqlInit() {
	new t[4][33];
	
	get_pcvar_string(gCvars[HOST], 		t[HOST], 32);
	get_pcvar_string(gCvars[USER], 		t[USER], 32);
	get_pcvar_string(gCvars[PASS], 		t[PASS], 32);
	get_pcvar_string(gCvars[DBNAME], 	t[DBNAME], 32);
	
	g_SqlTuple = SQL_MakeDbTuple(t[HOST], t[USER], t[PASS], t[DBNAME]);

	if(g_SqlTuple == Empty_Handle)
		log_amx("Nie mozna utworzyc uchwytu do polaczenia");
	
	new iErr, szError[128];
	new Handle:link = SQL_Connect(g_SqlTuple, iErr, szError, 127);
	if(link == Empty_Handle) {
		log_amx("Brak polaczenia z baza danych");
		log_amx("Error (%d): %s", iErr, szError);
	}
	
	new Handle:query;
	query = SQL_PrepareQuery(link,
	"CREATE TABLE IF NOT EXISTS `screeny` ( \
		`id` int(11) NOT NULL auto_increment, \
		`uname` varchar(32) NOT NULL, \
		`aname` varchar(32) NOT NULL, \
		`uip` varchar(20) NOT NULL, \
		`usid` varchar(32) NOT NULL, \
		`map` varchar(32) NOT NULL, \
		`time` int(15) NOT NULL, \
		`type` int(1) NOT NULL, \
		`amount` int(3) NOT NULL, \
		`server` varchar(100) NOT NULL, \
		PRIMARY KEY  (`id`) \
	)");
	
	SQL_Execute(query);
	SQL_FreeHandle(query);
}

public Query(failstate, Handle:query, error[]) {
	if(failstate != TQUERY_SUCCESS) {
		log_amx("SQL Insert error: %s", error);
		return;
	}
}
#endif

public plugin_init() {
	register_plugin(name, "1.3", "byCZEK & O'Zone");
	
	gCvars[HOST] 		= register_cvar("ss_hostname", "sql.pukawka.pl");
	gCvars[USER] 		= register_cvar("ss_username", "262947");
	gCvars[PASS] 		= register_cvar("ss_password", "ZXCvbn1@3");
	gCvars[DBNAME] 		= register_cvar("ss_database", "262947_screeny");
	gCvars[SSAMOUNT]	= register_cvar("ss_amount", "5");
	gCvars[TYPE]		= register_cvar("ss_type", "2"); //0 - BMP | 1 - TGA | 2 - BMP+TGA
	gCvars[INTERVAL] 	= register_cvar("ss_interval", "1.0");
	gCvars[SITE]		= register_cvar("ss_sitemap", "http://cs-reload.pl");
	gCvars[BAN]			= register_cvar("ss_banplayer", "1");
	gCvars[BANTIME]		= register_cvar("ss_bantime", "0");
	gCvars[BANREASON]	= register_cvar("ss_banreason", "Wrzuc screeny na Cs-Reload.pl");
	
	register_concmd("amx_ss", 	"ZrobScreena", 	ADMIN_BAN, "<authid, nick or #userid>");
	register_concmd("amx_screen", 	"ZrobScreena", 	ADMIN_BAN, "<authid, nick or #userid>");
	register_concmd("amx_screenm", 	"MenuScreenow", ADMIN_BAN, " - pokazuje menu screenow");

	g_SyncHud = CreateHudSyncObj();
}

public plugin_cfg() {
	#if defined SQL_ZAPIS
	get_mapname(gMapa, 32);
	get_user_name(0, gNazwa, 100);
	set_task(0.1, "SqlInit");
	#endif
}

public client_putinserver(id)
	gScreens[id] = 0;

public ZrobScreena(id, level, cid) {
	if(!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}
		
	new t[1][33], pid;
	
	read_argv(1, t[0], 32);

	new Type	= get_pcvar_num(gCvars[TYPE]);
	new Screens	= get_pcvar_num(gCvars[SSAMOUNT]);
	
	pid = cmd_target(id, t[0]);
	
	if(!pid) 
		return PLUGIN_HANDLED;
		
	new dane[4];
	new Float: Interval = get_pcvar_float(gCvars[INTERVAL]);
	
	dane[0] = id;
	dane[1] = pid;
	dane[2] = Type;
	dane[3] = Screens;
	
	gScreens[pid] = Screens;
	
	set_task(Interval, "ZrobScreena_", TASK_SCREEN + pid, dane, 4, "a", Screens);
	
	#if defined SQL_ZAPIS
	new z[4][33], buffer[512];
	get_user_name(id, 	z[0], 32);
	get_user_name(pid, 	z[1], 32);
	get_user_ip(pid, 	z[2], 32, 1);
	get_user_authid(pid, 	z[3], 32);
	
	replace_all(z[0], 32, "'", "\'");
	replace_all(z[0], 32, "`", "\`");
	
	replace_all(z[1], 32, "'", "\'");
	replace_all(z[1], 32, "`", "\`");
	
	formatex(buffer, charsmax(buffer), "INSERT INTO `screeny` VALUES (NULL, '%s', '%s', '%s', '%s', '%s', UNIX_TIMESTAMP(), %d, %d, '%s');", z[1], z[0], z[2], z[3], gMapa, Type, Screens, gNazwa); 
	SQL_ThreadQuery(g_SqlTuple, "Query", buffer);	
	#endif
	
	return PLUGIN_HANDLED;
}

public ZrobScreena_(dane[4]) {
	new id 		= dane[0];
	new pid 	= dane[1];
	new tid 	= dane[2];

	new t[7][33];
	
	get_user_name(id, t[0], 32);
	get_user_name(pid, t[1], 32);
	get_user_ip(pid, t[2], 20, 1);
	
	get_time("%m/%d/%Y - %H:%M:%S", t[3], 31);
	
	set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 0.25, 1.0, 0.0, 0.0, 4);
	ShowSyncHudMsg(pid, g_SyncHud, "** %s **^n%s", t[1], t[3]);
	
	switch(tid){
	case 0: {
		client_cmd(pid, "snapshot");
		format(t[6], 32, "BMP");
		}
	case 1: {
		client_cmd(pid, "screenshot");
		format(t[6], 32, "TGA");
		}
	case 2: {
		client_cmd(pid, "snapshot");
		client_cmd(pid, "screenshot");
		format(t[6], 32, "BMP+TGA");
		}
	}
	
	if(get_pcvar_num(gCvars[BAN]) && !--gScreens[pid]) {
		new czas = get_pcvar_num(gCvars[BANTIME]);
		
		get_pcvar_string(gCvars[BANREASON], 	t[4], 32);
		get_pcvar_string(gCvars[SITE], 		t[5], 32);
		
		console_print(pid, "%s ==========================================", tag);
		console_print(pid, "%s Admin %s zrobil Ci screeny", tag, t[0]);
		console_print(pid, "%s Ilosc: %d", tag, dane[3]);
		console_print(pid, "%s Typ: %s", tag, t[6]);
		console_print(pid, "%s Umiesc screeny na: %s", tag, t[5]);
		console_print(pid, "%s ==========================================", tag);
		
		client_cmd(id, "amx_ban %d #%d ^"%s^"", czas, get_user_userid(pid), t[4]);
	}
}

public MenuScreenow(id, level, cid) {
	if(!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}
	
	new players[32], name[33], temp[2][256], num, pl;
	get_players(players, num);
	
	new m = menu_create("Lista Graczy", "MenuScreenow_");
	
	for(new i = 0; i < num; i++) {
		pl = players[i];
		
		get_user_name(pl, name, 32);
		num_to_str(pl, temp[0], 2);
		formatex(temp[1], 255, "%s%s", name, (get_user_flags(pl) & ADMIN_KICK) ? "\r *" : "");
		menu_additem(m, temp[1], temp[0], _, menu_makecallback("MenuScreenow_c"));   
	}
	
	menu_setprop(m, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, m, 0);
	return PLUGIN_HANDLED;
}

public MenuScreenow_c(id, m, i) {
	new data[6], iName[64], access, callback;
	menu_item_getinfo(m, i, access, data,5, iName, 63, callback);
	
	new pl = str_to_num(data);
	
	if(get_user_flags(pl) & ADMIN_IMMUNITY || pl == id)
		return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public MenuScreenow_(id, m, i) {
	new data[6], iName[64], access, callback;
	menu_item_getinfo(m, i, access, data,5, iName, 63, callback);
	
	gScreened[id] = get_user_userid(str_to_num(data));
	
	client_cmd(id, "amx_ss #%d", gScreened[id]);
}
