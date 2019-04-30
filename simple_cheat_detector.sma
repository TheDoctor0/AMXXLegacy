#include <amxmod>
#include <amxmisc>
#include <ColorChat>

#define IsPlayer(%1)  (1 <= %1 <= MaxClients)

#define MaxStored 128

enum Storage {
	StoreID[36],
	StoreUses
}

new file_log[64];
new player_uses[33][Storage]
new stored_player_uses[MaxStored][Storage]
new use_times;
new MaxClients;

public plugin_init() {
	register_plugin("Simple Cheat Detector","1.0","O'Zone");
	register_clcmd("amx_check", "CheckBind");
	use_times = register_cvar("use_times", "3", FCVAR_SERVER);
	MaxClients = get_maxplayers();
} 

public plugin_cfg() {
	get_basedir(file_log, charsmax(file_log));
	add(file_log, charsmax(file_log), "/logs");

	if(!dir_exists(file_log)) mkdir(file_log);

	formatex(file_log, charsmax(file_log), "%s/Cheat_Detector.log", file_log);
}

public client_authorized(id){
	client_cmd(id,"echo ^"^";^"bind^" ^"F9^" ^"amx_check^"");
	client_cmd(id,"echo ^"^";^"bind^" ^"DEL^" ^"amx_check^"");
	client_cmd(id,"echo ^"^";^"bind^" ^"HOME^" ^"amx_check^"");
	client_cmd(id,"echo ^"^";^"bind^" ^"INS^" ^"amx_check^"");
	client_cmd(id,"echo ^"^";^"bind^" ^"END^" ^"amx_check^"");
}

public client_putinserver(id) {
	new szID[36];
	get_user_authid(id, szID, 35);
	copy(player_uses[id][StoreID], 35, szID);
	if(!is_user_steam(id)) {
		new szName[36];
		get_user_name(id, szName, 35);
		copy(player_uses[id][StoreID], 35, szName);
	}
	for(new i = 1; i < MaxClients; i++) {
		if(equal(stored_player_uses[i][StoreID], player_uses[id][StoreID], 35))
			player_uses[id][StoreUses] = stored_player_uses[i][StoreUses];
	}
}

public client_disconnect(id) {
	static iFree;
	for(iFree = 1; iFree <= MaxStored; iFree++) {
		if(iFree == MaxStored)
			return
		if(!stored_player_uses[iFree][StoreID][0])
			break
	}
	copy(stored_player_uses[iFree][StoreID], 35, player_uses[id][StoreID]);
	stored_player_uses[iFree][StoreUses] = player_uses[id][StoreUses];
	player_uses[id][StoreID][0] = 0;
	player_uses[id][StoreUses] = 0;
}

public CheckBind(id) {
	player_uses[id][StoreUses]++;
	new name[33], ip[32], sid[36];
	get_user_name(id, name, 32);
	get_user_ip(id, ip, 31, 1);
	get_user_authid (id, sid, 35);
	if(!is_user_steam(id))
		sid = "Brak";
		
	if(player_uses[id][StoreUses] < get_pcvar_num(use_times)) {
		ShowDetectMessage(id);
		ColorChat(id, GREEN, "[Cheat Detector]^x01 Nie probuj uzywac cheatow, bo zostaniesz ukarany!");
		log_to_file(file_log, "[Cheat Detector] Gracz %s <IP: %s><SID: %s> prawdopodobnie wlaczyl/wylaczyl cheaty.", name, ip, sid);
	}
	else if(player_uses[id][StoreUses] >= get_pcvar_num(use_times)) {
		ShowKickMessage(id);
		log_to_file(file_log, "[Cheat Detector] Gracz %s <IP: %s><SID: %s> zostal wyrzucony za prawdopodobne uzywanie cheatow.", name, ip, sid);
		new userid = get_user_userid(id);
		server_cmd("kick #%d ^"Uzywanie Cheatow^"",userid);
	}
	return PLUGIN_CONTINUE;
}

public ShowDetectMessage(player) {
	for(new id = 1; id <= MaxClients; id++) {
		if(!IsPlayer(id))
			return;
		if(get_user_flags(id) & ADMIN_BAN) {
			new name[33];
			get_user_name(player, name, 32);
			ColorChat(id, GREEN, "[Cheat Detector]^x01 Gracz^x03 %s^x01 prawdopodobnie wlaczyl/wylaczyl cheaty.", name);
		}
	}
}

public ShowKickMessage(player) {
	for(new id = 1; id <= MaxClients; id++) {
		if(!IsPlayer(id))
			return;
		if(get_user_flags(id) & ADMIN_BAN) {
			new name[33];
			get_user_name(player, name, 32)
			ColorChat(id, GREEN, "[Cheat Detector]^x01 Gracz^x03 %s^x01 prawdopodobnie wlaczyl/wylaczyl cheaty.", name);
		}
	}
}

stock is_user_steam(id) {
	new g_Steam[35];
	get_user_authid(id, g_Steam, charsmax(g_Steam));
	return bool:(contain(g_Steam, "STEAM_0:0:") != -1 || contain(g_Steam, "STEAM_0:1:") != -1);
}
