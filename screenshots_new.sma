#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "Screenshots Ban"
#define VERSION "1.6"
#define AUTHOR "O'Zone"

#define TASK_SCREEN 5632

enum _:cvary { HOST, USER, PASS, DBNAME, SSAMOUNT, TYPE, INTERVAL, SITE, BAN, BANTIME, BANLIMIT, BANREASON }

new const tag[] 			= "[SB]";

new gCvars[cvary];
new gScreens[33];
new gScreened[33];

new g_SyncHud;

new gMapa[33];
new gNazwa[101];

new Handle: g_SqlTuple;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	gCvars[HOST] 		= register_cvar("ss_hostname", "sql.pukawka.pl", FCVAR_SPONLY|FCVAR_PROTECTED);
	gCvars[USER] 		= register_cvar("ss_username", "510128", FCVAR_SPONLY|FCVAR_PROTECTED);
	gCvars[PASS] 		= register_cvar("ss_password", "xvQ5CusRVCVzj83aruWk", FCVAR_SPONLY|FCVAR_PROTECTED);
	gCvars[DBNAME] 		= register_cvar("ss_database", "510128_amxbans", FCVAR_SPONLY|FCVAR_PROTECTED);
	gCvars[SSAMOUNT]	= register_cvar("ss_amount", "5");
	gCvars[TYPE]		= register_cvar("ss_type", "2"); //0 - BMP | 1 - TGA | 2 - BMP+TGA
	gCvars[INTERVAL] 	= register_cvar("ss_interval", "1.0");
	gCvars[SITE]		= register_cvar("ss_sitemap", "http://cs-reload.pl");
	gCvars[BAN]			= register_cvar("ss_banplayer", "1");
	gCvars[BANTIME]		= register_cvar("ss_bantime", "0");
	gCvars[BANLIMIT]	= register_cvar("ss_banlimit", "3");
	gCvars[BANREASON]	= register_cvar("ss_banreason", "Wrzuc screeny na Cs-Reload.pl");
	
	register_concmd("amx_ss", 	"SprawdzGracza", 	ADMIN_BAN, "<authid, nick or #userid>");
	register_concmd("amx_screen", 	"SprawdzGracza", 	ADMIN_BAN, "<authid, nick or #userid>");
	register_concmd("amx_screenm", 	"MenuScreenow", ADMIN_BAN, " - pokazuje menu screenow");

	g_SyncHud = CreateHudSyncObj();
}

public plugin_cfg() 
{
	get_mapname(gMapa, 32);
	get_user_name(0, gNazwa, 100);
	
	set_task(0.1, "SqlInit");
}

public SqlInit() 
{
	new t[4][33];
	
	get_pcvar_string(gCvars[HOST], 		t[HOST], 32);
	get_pcvar_string(gCvars[USER], 		t[USER], 32);
	get_pcvar_string(gCvars[PASS], 		t[PASS], 32);
	get_pcvar_string(gCvars[DBNAME], 	t[DBNAME], 32);
	
	g_SqlTuple = SQL_MakeDbTuple(t[HOST], t[USER], t[PASS], t[DBNAME]);

	if(g_SqlTuple == Empty_Handle) set_fail_state("Nie mozna utworzyc uchwytu do polaczenia");
	
	new iErr, szError[128];
	new Handle:link = SQL_Connect(g_SqlTuple, iErr, szError, 127);
	
	if(link == Empty_Handle)
	{
		log_amx("Error (%d): %s", iErr, szError);
		set_fail_state("Brak polaczenia z baza danych. Sprawdz logi bledow.");
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

public Query(failstate, Handle:query, error[]) 
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("SQL Insert error: %s", error);
		return;
	}
}

public client_putinserver(id)
{
	gScreens[id] = 0;
	gScreened[id] = 0;
}

public SprawdzGracza(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;
		
	new t[1][33], pid;
	
	read_argv(1, t[0], 32);
	
	pid = cmd_target(id, t[0]);
	
	if(!pid) 
		return PLUGIN_HANDLED;
		
	gScreened[id] = get_user_userid(pid);
		
	new dane[2], name[33];
	dane[0] = id;
	dane[1] = pid;
	
	get_user_name(pid, name, 32);
	replace_all(name, 32, "'", "\'");
	replace_all(name, 32, "`", "\`");
	
	new buffer[128];
	formatex(buffer, charsmax(buffer), "SELECT * FROM `screeny` WHERE uname = '%s'", name);
	SQL_ThreadQuery(g_SqlTuple, "SprawdzGracza_", buffer, dane, 2);
	
	return PLUGIN_HANDLED;
}

public SprawdzGracza_(FailState, Handle:Query, Error[], Errcode, Data[2], DataSize) 
{
	if(FailState != TQUERY_SUCCESS)
	{
		log_amx("%s <Query> Error: %s", tag, Error);
		return PLUGIN_CONTINUE
	}
	
	if(SQL_NumRows(Query))
	{
		new screeny = SQL_NumResults(Query)
		if(screeny < get_pcvar_num(gCvars[BANLIMIT]))
		{
			ZrobScreena(Data)
			return PLUGIN_CONTINUE
		}
		new name[33], title[128]
		get_user_name(Data[1], name, 32)
		formatex(title, 127, "\wGracz \r%s \wmial SS'y robione \r%i \wrazy.^n\yCzy na pewno chcesz zrobic kolejne?", name, screeny)
		new menu = menu_create(title, "SprawdzGracza_Handler")
		menu_additem(menu, "\rTak", Data, 0)
		menu_additem(menu, "\wNie", "", 0)
		menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
		menu_display(Data[0], menu)
	}
	else
		ZrobScreena(Data)
		
	return PLUGIN_CONTINUE
}

public SprawdzGracza_Handler(id, menu, item) 
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(item == 1)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new info[2], access, callback;
	menu_item_getinfo(menu, item, access, info, 2, "", 0, callback);

	ZrobScreena(info)
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public ZrobScreena(data[2]) 
{
	new id = data[0]
	new pid = data[1]
	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	if(get_user_userid(pid) != gScreened[id] || !is_user_connected(pid))
	{
		client_print_color(id, print_team_red, "^x03%s^x01 Wybranego gracza nie ma juz na serwerze!", tag);
		return PLUGIN_CONTINUE;
	}
	
	new dane[3];
	new Float: Interval = get_pcvar_float(gCvars[INTERVAL]);
	
	new Type	= get_pcvar_num(gCvars[TYPE]);
	new Screens	= get_pcvar_num(gCvars[SSAMOUNT]);
	
	dane[0] = id;
	dane[1] = pid;
	dane[2] = Type;
	
	gScreens[pid] = Screens;
	
	set_task(Interval, "ZrobScreena_", TASK_SCREEN + pid, dane, 3, "a", Screens);
	
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
	return PLUGIN_CONTINUE;
}

public ZrobScreena_(dane[3]) 
{
	new id 		= dane[0];
	new pid 	= dane[1];
	new type 	= dane[2];
	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(get_user_userid(pid) != gScreened[id] || !is_user_connected(pid))
	{
		client_print_color(id, print_team_red, "^x03%s^x01 Gracz uciekl z serwera!", tag);
		remove_task(TASK_SCREEN + pid);
		return PLUGIN_CONTINUE;
	}

	new t[7][35];
	
	get_user_name(id, t[0], 32);
	get_user_name(pid, t[1], 32);
	get_user_ip(pid, t[2], 20, 1);
	get_user_authid (pid, t[3], 34);
	
	get_time("%m/%d/%Y - %H:%M:%S", t[3], 31);
	
	set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 0.0, 2.0, 0.0, 0.0, 4);
	ShowSyncHudMsg(pid, g_SyncHud, "** CZAS: %s **", t[3]);
	if(gScreens[pid]%2)
		client_print_color(pid, pid, "** Screenshot zrobiony^x04 %s (IP: %s)^x01 przez^x04 %s^x01 **", t[1], t[2], t[0])
	else
		client_print_color(pid, pid, "** Screenshot zrobiony^x04 %s (%s)^x01 przez^x04 %s^x01 **", t[1], t[3], t[0])
	
	switch(type)
	{
		case 0: 
		{
			format(t[6], 32, "BMP");
			client_cmd(pid, "snapshot");
		}
		case 1: 
		{
			format(t[6], 32, "TGA");
			client_cmd(pid, "screenshot");
		}
		case 2: 
		{
			format(t[6], 32, "BMP+TGA");
			client_cmd(pid, "snapshot");
			client_cmd(pid, "screenshot");
		}
	}
	
	if(get_pcvar_num(gCvars[BAN]) && !--gScreens[pid]) 
	{
		get_pcvar_string(gCvars[BANREASON], t[4], 32);
		get_pcvar_string(gCvars[SITE], 		t[5], 32);
		
		console_print(pid, "%s ==========================================", tag);
		console_print(pid, "%s Admin %s zrobil Ci screeny", tag, t[0]);
		console_print(pid, "%s Ilosc: %d", tag, get_pcvar_num(gCvars[SSAMOUNT]));
		console_print(pid, "%s Typ: %s", tag, t[6]);
		console_print(pid, "%s Umiesc screeny na: %s", tag, t[5]);
		console_print(pid, "%s ==========================================", tag);
		
		client_cmd(id, "amx_ban %d #%d ^"%s^"", get_pcvar_num(gCvars[BANTIME]), get_user_userid(pid), t[4]);
	}
	return PLUGIN_CONTINUE;
}

public MenuScreenow(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 1)) 
		return PLUGIN_HANDLED;
	
	new players[32], name[33], temp[2][256], num, pl;
	get_players(players, num);
	
	new m = menu_create("Lista Graczy", "MenuScreenow_");
	
	for(new i = 0; i < num; i++) 
	{
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

public MenuScreenow_c(id, m, i) 
{
	new data[6], iName[64], access, callback;
	menu_item_getinfo(m, i, access, data,5, iName, 63, callback);
	
	new pl = str_to_num(data);
	
	if(get_user_flags(pl) & ADMIN_IMMUNITY || id == pl)
		return ITEM_DISABLED;
	
	return ITEM_ENABLED;
}

public MenuScreenow_(id, m, i) 
{
	if(i == MENU_EXIT)
	{
		menu_destroy(m);
		return PLUGIN_HANDLED;
	}

	new data[6], iName[64], access, callback;
	menu_item_getinfo(m, i, access, data,5, iName, 63, callback);
	
	gScreened[id] = get_user_userid(str_to_num(data));
	
	client_cmd(id, "amx_ss #%d", gScreened[id]);

	menu_destroy(m);
	return PLUGIN_HANDLED;
}
