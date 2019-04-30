#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "Active Ban Checker"
#define VERSION "1.0"
#define AUTHOR "O'Zone"
 

new g_SqlX_Cache[512];
new Handle:g_SqlX;
new PropablyBanned[33];
new Admins[33];
new g_CountQuery[512];
new tbl_bans[50];
 
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") 
	
	copy(g_CountQuery, charsmax(g_CountQuery), "SELECT count(1) \
			FROM `%s` WHERE (player_ip like '%s^%' OR \
			player_nick like '%s^%') \
			AND expired = 0 \
			AND (ban_length = 0 OR ban_created = 0 \
			OR UNIX_TIMESTAMP(NOW()) > (ban_created + ban_time * 60))");
			
	new host[64], user[64], pass[64], db[64]

	get_cvar_string("amx_sql_host", host, 63)
	get_cvar_string("amx_sql_user", user, 63)
	get_cvar_string("amx_sql_pass", pass, 63)
	get_cvar_string("amx_sql_db", db, 63)
	
	g_SqlX = SQL_MakeDbTuple(host, user, pass, db)
}


public CheckIsBanned(id) {
	new player_nick[50]
	new player_ip[20]
	
	mysql_get_username_safe(id, player_nick, 49);
	get_user_ip(id, player_ip, 19, 1);

	formatex(g_SqlX_Cache, charsmax(g_SqlX_Cache), g_CountQuery,
			tbl_bans, player_ip, player_nick);			
	
	new data[1]
	
	data[0] = id
	Admins[id] = is_user_admin(id);
	
	SQL_ThreadQuery(g_SqlX, "_CheckIsBanned", g_SqlX_Cache, data, 1)
	
	return PLUGIN_HANDLED
}
public client_authorized(id){
	set_task(5.0, "CheckIsBanned",id);
	return PLUGIN_CONTINUE;
}


public client_disconnect(id){
	Admins[id] =0;
	PropablyBanned[id] = 0;
}

public _CheckIsBanned(failstate, Handle:query, error[], errnum, data[], size){
	new id = data[0]

	if (failstate)
	{
		new szQuery[256]
		MySqlX_ThreadError( szQuery, error, errnum, failstate, 17 )
		return PLUGIN_HANDLED
	}
	
	if(!SQL_NumResults(query)) {
		PropablyBanned[id] = 0;
		
	} else {
		PropablyBanned[id] = 1;
		printBanInfo();
	}
	return PLUGIN_HANDLED	
}


public event_new_round() {
	printBanInfo();
	return PLUGIN_CONTINUE;
}
public printBanInfo() {
	new plnum=get_maxplayers()
	new message[512];
	new name[50];
	new msg[100];
	for(new i=1;i <= plnum; i++) {
		if(PropablyBanned[i]) {
			get_user_name(i, name, charsmax(name));
			if(msg[0]){
				add(msg, charsmax(msg), ", ");
			}
			add(msg, charsmax(message), name);
		}
	}
	if(msg[0]){
		formatex(message, charsmax(message), "[AmxBans] Gracz(e) %s Prawdopodobnie gra(ja) na aktywnym banie!", msg);
		for(new i=1;i<=plnum;i++) {
			if(Admins[i]) {
				if(is_user_connected(i)){
					client_print(i, print_chat, message);
					client_print(i, print_chat, message);
					client_print(i, print_chat, message);
					client_print(i, print_chat, message);
					client_print(i, print_chat, message);
				}
			}
		}
	}
}
MySqlX_ThreadError(szQuery[], error[], errnum, failstate, id) {
	if (failstate == TQUERY_CONNECT_FAILED) {
		log_amx("%L", LANG_SERVER, "TCONNECTION_FAILED")
	} else if (failstate == TQUERY_QUERY_FAILED) {
		log_amx("%L", LANG_SERVER, "TQUERY_FAILED")
	}
	log_amx("%L", LANG_SERVER, "TQUERY_ERROR", id)
	log_amx("%L", LANG_SERVER, "TQUERY_MSG", error, errnum)
	log_amx("%L", LANG_SERVER, "TQUERY_STATEMENT", szQuery)
}

mysql_get_username_safe(id,dest[],len) {
	new name[128]
	get_user_name(id,name,127)
	SQL_QuoteString(Empty_Handle,dest,len,name)
}