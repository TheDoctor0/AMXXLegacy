// Required admin access level
#define ADMIN_VOICE	ADMIN_CHAT

// Comment this out if you don't want that a "no sound" player can hear admins using +adminvoice
// All other player settings are respected whatever this is commented or not.
#define SUPER_ADMIN_PRIORITY

/* ** END OF EDITABLE ** */

/*    Changelog
*
* v1.0.2 (04/19/08)
* -few code corrections
* -updated player spawn detection
* -added HLTV & BOT checks
*
* v1.0.1 (03/31/08)
* -added colored chat
* -added chat command /vm that display voices settings
* -inform new players about /vm command
* -display adminlisten status when toggle_adminlisten command is used
* -added support for amx_show_activity cvar on amx_(un)mute command
*
* v1.0.0 (03/26/08)
* First release
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <nvault>
#include <sqlx>

#define VERSION "1.1"

#define MAX_PLAYERS	32

#define OFFSET_TEAM		114

new g_iClientSettings[MAX_PLAYERS+1][2]
new bool:g_bPlayerNonSpawnEvent[MAX_PLAYERS+1]
new g_iFwFmClientCommandPost
new bool:g_bAlive[MAX_PLAYERS+1]

new g_iAdminVoice
new bool:g_bAdmin[MAX_PLAYERS+1]
new bool:g_bInterAdminVoice[MAX_PLAYERS+1]
new bool:g_bAdminListen[MAX_PLAYERS+1]
new bool:g_bCan[MAX_PLAYERS+1]
new bool:g_bUsed[MAX_PLAYERS+1]

new bool:g_bMuted[MAX_PLAYERS+1]
new g_szClientsIp[MAX_PLAYERS+1][22]
new Array:g_aMutedPlayersIps

new bool:g_mute[MAX_PLAYERS+1][MAX_PLAYERS+1]
new g_menuposition[MAX_PLAYERS+1]
new g_menuplayers[MAX_PLAYERS+1][32]
new g_menuplayersnum[MAX_PLAYERS+1]

new cvar_alltalk
new g_iMaxPlayers
new g_msgidSayText
new g_pcvarAlivesHear, g_pcvarDeadsHear, g_pcvarInfoTime, g_pcvarMuteMenu
new g_amx_show_activity
new Float:g_infoTime

new ip[MAX_PLAYERS + 1][24]

new plik_vault;
new Trie:MuteNaMape

new playerName[MAX_PLAYERS + 1][32], safePlayerName[MAX_PLAYERS + 1][32], Trie:playerMutes[MAX_PLAYERS + 1], playerId[MAX_PLAYERS + 1], Handle:sql, bool:sqlConnection;

new const cmdMenu[][] = { "say /mute", "say_team /mute", "say /mutuj", "say_team /mutuj", "say /ucisz", "say_team /ucisz" };

public plugin_init()
{
	register_plugin("Voices Management", VERSION, "ConnorMcLeod & O'Zone")
	register_dictionary("voicesmanagement.txt")
	register_dictionary("common.txt")

	create_cvar("advanced_mute_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("advanced_mute_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED);

	g_pcvarAlivesHear = register_cvar("vm_alives", "0")  // 0:alive teamates , 1:alives , 2:all
	g_pcvarDeadsHear = register_cvar("vm_deads", "1")	// 0:dead teamates , 1:deads , 2:all
	g_pcvarInfoTime = register_cvar("vm_infotime", "5.0") // time for info after death (in seconds)
	g_pcvarMuteMenu = register_cvar("vm_mutemenu", "0") // enable mute menu for players

	register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening")
	register_event("VoiceMask", "Event_VoiceMask", "b")

	register_event("TextMsg", "Event_TextMsg_Restart", "a", "2=#Game_will_restart_in")
	register_event("ResetHUD", "Event_ResetHUD", "b")
	register_event("DeathMsg", "Event_DeathMsg", "a")

	register_clcmd("+adminvoice", "AdminCommand_VoiceOn")
	register_clcmd("-adminvoice", "AdminCommand_VoiceOff")

	register_clcmd("+interadminvoice", "AdminCommand_InterAdminOn")
	register_clcmd("-interadminvoice", "AdminCommand_InterAdminOff")

	register_clcmd("+adminlisten", "AdminCommand_ListenOn")
	register_clcmd("-adminlisten", "AdminCommand_ListenOff")
	register_clcmd("toggle_adminlisten", "AdminCommand_ListenToggle")

	register_clcmd("say","sayHandle")
	register_clcmd("say_team","sayHandle")

	register_concmd("amx_mute", "AdminCommand_Mute", ADMIN_VOICE, "<name/#userid>")
	register_concmd("amx_unmute", "AdminCommand_UnMute", ADMIN_VOICE, "<name/#userid>")

	register_clcmd("amx_permmute", "DajMute", 0, "<name>")
	register_clcmd("amx_permmute_menu", "DajMuteMenu")
	register_clcmd("amx_permmutemenu", "DajMuteMenu")
	
	register_clcmd("amx_unmutemenu", "DajUnmuteMenu")
	register_clcmd("amx_unmute_menu", "DajUnmuteMenu")
	register_clcmd("amx_unpermmute_menu", "DajUnmuteMenu")
	register_clcmd("amx_unpermmutemenu", "DajUnmuteMenu")
	
	register_clcmd("amx_mute2", "DajMute2", 0, "<name>")
	register_clcmd("amx_mute2menu", "DajMuteMenu2", 0, "<name>")
	register_clcmd("amx_mute2_menu", "DajMuteMenu2", 0, "<name>")

	for (new i; i < sizeof(cmdMenu); i++) register_clcmd(cmdMenu[i], "menu_show");

	register_clcmd("say /vm", "ClientCommand_SayStatus")
	register_clcmd("say_team /vm", "ClientCommand_SayStatus")
	
	register_clcmd("say /glos", "ClientCommand_SayStatus")
	register_clcmd("say_team /glos", "ClientCommand_SayStatus")

	register_clcmd("fullupdate", "ClientCommand_fullupdate")

	register_menucmd(register_menuid("mute menu"), 1023, "action_mutemenu")

	cvar_alltalk = get_cvar_pointer("sv_alltalk")

	plik_vault = nvault_open("PermMute")
	MuteNaMape = TrieCreate()

	for (new id = 1; id <= MAX_PLAYERS; id++) playerMutes[id] = TrieCreate();
}

public plugin_cfg()
{
	new configPath[64];

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/advanced_mute.cfg", configPath);
	server_exec();

	sql_init();

	server_cmd("sv_alltalk 1;alias sv_alltalk")
	server_exec()

	g_iMaxPlayers = get_maxplayers()
	g_aMutedPlayersIps = ArrayCreate(22)
	g_msgidSayText = get_user_msgid("SayText")
	g_amx_show_activity = get_cvar_pointer("amx_show_activity")

	g_infoTime =  get_pcvar_float(g_pcvarInfoTime)
}

public sayHandle(id)
{
	if (!g_bCan[id] || g_bUsed[id]) return PLUGIN_CONTINUE;
	
	static szTmp[190], szPrint[190];
	
	read_argv(1, szTmp, charsmax(szTmp));
	trim(szTmp);

	if (szTmp[0] == '/') return PLUGIN_CONTINUE;

	g_bUsed[id] = true;
	
	formatex(szPrint, charsmax(szPrint), "^x04[INFO OD %s]^x03 %s", playerName[id], szTmp);
	
	client_print_color(id, id, szPrint);
	
	for (new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++) {
		if (!is_user_alive(iPlayer) || get_user_team(iPlayer) != get_user_team(id)) continue;
		
		client_print_color(iPlayer, iPlayer, szPrint);
	}
	
	return PLUGIN_HANDLED;
}

public ClientCommand_SayStatus(id)
{
	new iDeads = get_pcvar_num(g_pcvarDeadsHear), 
		iAlives = get_pcvar_num(g_pcvarAlivesHear)

	new szDeadsStatus[18], szAlivesStatus[19]

	switch( iAlives )
	{
		case 0:szAlivesStatus = "VM_ALIVES_TEAMATES"
		case 1:szAlivesStatus = "VM_ALIVES"
		case 2:szAlivesStatus = "VM_ALL"
	}

	switch( iDeads )
	{
		case 0:szDeadsStatus = "VM_DEADS_TEAMATES"
		case 1:szDeadsStatus = "VM_DEADS"
		case 2:szDeadsStatus = "VM_ALL"
	}

	col_mess(id, id, "%L", id, "VM_ALIVES_STATUS", id, szAlivesStatus)
	col_mess(id, id, "%L", id, "VM_DEADS_STATUS", id, szDeadsStatus)
}

public ClientCommand_fullupdate(id)
{
	g_bPlayerNonSpawnEvent[id] = true
	static const szFwFmClientCommandPost[] = "fwFmClientCommandPost"
	g_iFwFmClientCommandPost = register_forward(FM_ClientCommand, szFwFmClientCommandPost, 1)
	return PLUGIN_CONTINUE
}

public fwFmClientCommandPost(iPlayerId) {
	unregister_forward(FM_ClientCommand, g_iFwFmClientCommandPost, 1)
	g_bPlayerNonSpawnEvent[iPlayerId] = false
	return FMRES_HANDLED
}

public Event_TextMsg_Restart()
{
	for(new id=1; id <= g_iMaxPlayers; ++id)
	{
		if (g_bAlive[id])
		{
			g_bPlayerNonSpawnEvent[id] = true
		}
	}
}

public Event_ResetHUD(id)
{
	if ( !is_user_alive(id) )
	{
		return
	}

	if (g_bPlayerNonSpawnEvent[id])
	{
		g_bPlayerNonSpawnEvent[id] = false
		return
	}
	g_bAlive[id] = true
}

public client_authorized(id)
{
	g_bAdmin[id] = bool:(get_user_flags(id) & ADMIN_VOICE);
}

public client_putinserver(id)
{
	g_bAlive[id] = false
	g_bAdminListen[id] = false
	g_bInterAdminVoice[id] = false
	g_bCan[id] = false
	g_bUsed[id] = false

	get_user_name(id, playerName[id], charsmax(playerName[]));
	get_user_ip(id, ip[id], charsmax(ip[]), 1);

	if (task_exists(id+5802)) remove_task(id+5802);

	clear_list(id);

	static szIp[22]
	get_user_ip(id, szIp, 21)
	g_szClientsIp[id] = szIp

	static szTempIp[22], iArraySize
	iArraySize = ArraySize(g_aMutedPlayersIps)

	for (new i; i<iArraySize; i++) {
		ArrayGetString(g_aMutedPlayersIps, i, szTempIp, 21);

		if (equal(szIp, szTempIp)) {
			ArrayDeleteItem(g_aMutedPlayersIps, i);

			g_bMuted[id] = true;

			break;
		}
	}

	if (is_user_bot(id) || is_user_hltv(id) || !get_pcvar_num(g_pcvarMuteMenu)) return;

	sql_safe_string(playerName[id], safePlayerName[id], charsmax(safePlayerName[]));

	set_task(0.1, "load_mutes", id);

	set_task(1.0, "Wczytaj", id+5802);
}

public client_disconnected(id)
{
	g_bCan[id] = false;

	remove_task(id);

	if (g_iAdminVoice == id) {
		g_iAdminVoice = 0;
	}

	if (g_bMuted[id]) {
		ArrayPushString(g_aMutedPlayersIps, g_szClientsIp[id]);
		g_bMuted[id] = false;
	}

	if (!get_pcvar_num(g_pcvarMuteMenu)) return;

	if (task_exists(id+5802)){
		remove_task(id+5802);
	}

	clear_list(id);
}

public Wczytaj(id)
{
	id -= 5802;
	
	if (is_user_connected(id) && !TrieKeyExists(MuteNaMape, playerName[id]) && !TrieKeyExists(MuteNaMape, ip[id])) wczytaj_mute(id);
}

public DajMuteMenu(id)
{
	if (!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new menu = menu_create("Wybierz \rgracza\w, ktorego chcesz \ypermanentnie zmutowac\w", "DajMuteMenuH");
	for(new i=1; i<33; i++){
		if (is_user_connected(i) && !TrieKeyExists(MuteNaMape, playerName[i]) && !TrieKeyExists(MuteNaMape, ip[i]) && !(get_user_flags(i) & read_flags("a")))	
		menu_additem(menu, playerName[i]);
	}
	menu_display(id, menu);
	
	
	return PLUGIN_HANDLED
}

public DajMuteMenuH(id, menu, item){
	if (item == MENU_EXIT)
	return PLUGIN_HANDLED;
	
	if (!is_user_connected(id))
	return PLUGIN_HANDLED;
	
	new acces, info[6], name2[32], callback;
	
	menu_item_getinfo(menu, item, acces, info, 5, name2, 31, callback);
	
	new player = cmd_target(id, name2, CMDTARGET_ALLOW_SELF)
	
	new namea[32];
	get_user_name(id, namea, 31);
	
	if (!player || !is_user_connected(player))
	{
		console_print(id, "Gracz %s nie zostal odnaleziony.",name2);
		return PLUGIN_HANDLED;
	}
	else
	{
		TrieSetCell(MuteNaMape, playerName[player], 1); 
		TrieSetCell(MuteNaMape, ip[player], 1);
		zapisz_mute(player);
		client_cmd(player, "-voicerecord");

		client_print(id, print_console, "Gracz %s zostal zmutowany!", name2);
		client_print_color(id, player, "^x04[MUTE]^x01 Gracz^x03 %s^x01 zostal permanentnie zmutowany!", name2);
	}
	return PLUGIN_HANDLED;
}


public DajMuteMenu2(id){
	if (!(get_user_flags(id) & read_flags("c")) && id != 0)
	return PLUGIN_HANDLED;
	
	
	new menu = menu_create("Wybierz \rgracza\w, ktorego chcesz \yzmutowac do konca mapy\w:", "DajMuteMenuH2");
	for(new i=1; i<33; i++){
		if (is_user_connected(i) && !TrieKeyExists(MuteNaMape, playerName[i]) && !TrieKeyExists(MuteNaMape, ip[i]) && !(get_user_flags(i) & read_flags("a")))	
		menu_additem(menu, playerName[i]);
	}
	menu_display(id, menu);
	
	
	return PLUGIN_HANDLED
}

public DajMuteMenuH2(id, menu, item){
	if (item == MENU_EXIT)
	return PLUGIN_HANDLED;
	
	if (!is_user_connected(id))
	return PLUGIN_HANDLED;
	
	new acces, info[6], name2[32], callback;
	
	menu_item_getinfo(menu, item, acces, info, 5, name2, 31, callback);
	
	new player = cmd_target(id, name2, CMDTARGET_ALLOW_SELF)

	new namea[32];
	get_user_name(id, namea, 31);
	
	if (!player || !is_user_connected(player))
	{
		console_print(id, "Gracz %s nie zostal odnaleziony.",name2);
		return PLUGIN_HANDLED;
	}
	else
	{
		TrieSetCell(MuteNaMape, playerName[player], 1); 
		TrieSetCell(MuteNaMape, ip[player], 1);
		
		client_cmd(player, "-voicerecord");
		client_print(id, print_console, "Gracz %s zostal zmutowany!", name2);
		client_print_color(id, player, "^x04[MUTE]^x01 Gracz^x03 %s^x01 zostal zmutowany do konca mapy!", name2);
	}
	return PLUGIN_HANDLED;
}


public DajUnmuteMenu(id){
	if (!(get_user_flags(id) & read_flags("c")) && id != 0)
	return PLUGIN_HANDLED;
	
	
	new menu = menu_create("Wybierz \rgracza\w, ktorego chcesz \yodmutowac\w:", "DajUnmuteMenuH");
	for(new i=1; i<33; i++){
		if (is_user_connected(i) && (TrieKeyExists(MuteNaMape, playerName[i]) || TrieKeyExists(MuteNaMape, ip[i])))	
		menu_additem(menu, playerName[i]);
	}
	menu_display(id, menu);
	
	
	return PLUGIN_HANDLED
}

public DajUnmuteMenuH(id, menu, item){
	if (item == MENU_EXIT)
	return PLUGIN_HANDLED;
	
	if (!is_user_connected(id))
	return PLUGIN_HANDLED;
	
	new acces, info[6], name2[32], callback;
	
	menu_item_getinfo(menu, item, acces, info, 5, name2, 31, callback);
	
	new player = cmd_target(id, name2, CMDTARGET_ALLOW_SELF)
	
	new namea[32];
	get_user_name(id, namea, 31);
	
	if (!player || !is_user_connected(player))
	{
		console_print(id, "Gracz %s nie zostal odnaleziony.",name2);
		return PLUGIN_HANDLED;
	}
	else
	{
		client_print(id, print_console, "Gracz %s zostal odmutowany!", namea);
		Odbanuj_Gracza(player);
		
		if (TrieKeyExists(MuteNaMape, playerName[player]))
		TrieDeleteKey(MuteNaMape, playerName[player]);
		
		if (TrieKeyExists(MuteNaMape, ip[player]))
		TrieDeleteKey(MuteNaMape, ip[player]);
	}
	return PLUGIN_HANDLED;
}


/* Perm Mute na ZAWSZE przez nick, nawet OFFLINE! */
public DajMute(id){
	if (!(get_user_flags(id) & read_flags("c")) && id != 0)
	return PLUGIN_HANDLED;
	
	new arg1[32];
	read_argv(1, arg1, 31)
	
	if (!arg1[0])
	return PLUGIN_CONTINUE;
	
	new player = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
	
	new namea[32];
	get_user_name(id, namea, 31);
	
	if (!player || !is_user_connected(player))
	{
		new cReturn = Z_or_od_banujGracza(arg1, 2, 1)
		if (cReturn){
			client_print_color(id, player, "^x04[MUTE]^x01 Gracz^x03 %s^x01 zostal permanentnie zmutowany!", arg1);
		}
		
		return PLUGIN_HANDLED;
	}
	else
	{
		TrieSetCell(MuteNaMape, playerName[player], 1); 
		TrieSetCell(MuteNaMape, ip[player], 1);
		zapisz_mute(player);
		client_print(id, print_console, "Gracz %s zostal permanentnie zmutowany!", arg1);
		client_print_color(id, player, "^x04[MUTE]^x01 Gracz^x03 %s^x01 zostal permanentnie zmutowany!", arg1);
	}
	
	return PLUGIN_HANDLED
}


/* Perm Mute na mape przez nick, bez OFFLINE! */
public DajMute2(id){
	if (!(get_user_flags(id) & read_flags("c")) && id != 0)
	return PLUGIN_HANDLED;
	
	new arg1[32];
	read_argv(1, arg1, 31)
	
	if (!arg1[0])
	return PLUGIN_CONTINUE;
	
	new player=cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
	
	if (!player || !is_user_connected(player))
	{
		console_print(id, "Gracz %s nie zostal odnaleziony.", arg1);
		return PLUGIN_HANDLED;
	}
	else
	{
		TrieSetCell(MuteNaMape, playerName[player], 1); 
		TrieSetCell(MuteNaMape, ip[player], 1);
		client_print(id, print_console, "Gracz %s zostal zmutowany do konca mapy!", arg1);
		client_print_color(id, player, "^x04[MUTE]^x01 Gracz^x03 %s^x01 zostal zmutowany do konca mapy!", arg1);
	}
	
	return PLUGIN_HANDLED
}


public wczytaj_mute(id)
{
	new vaultkey[64], vaultdata[256];
	
	formatex(vaultkey,63,"%s-m-",playerName[id])
	nvault_get(plik_vault,vaultkey,vaultdata,255) 
	
	new wartosc[6];
	parse(vaultdata, wartosc, 5) 
	
	if (str_to_num(wartosc)){
		TrieSetCell(MuteNaMape, playerName[id], 1);
	}
	
	formatex(vaultkey,63,"%s-mip-", ip[id]) 
	nvault_get(plik_vault, vaultkey, vaultdata,255) 
	
	new wartosc2[6];
	parse(vaultdata, wartosc2, 5) 
	
	if (str_to_num(wartosc2)){
		TrieSetCell(MuteNaMape, ip[id], 1);
	}
}  


public zapisz_mute(id)
{
	new vaultkey[64], vaultdata[256];
	
	if (TrieKeyExists(MuteNaMape, playerName[id]))
	{
		formatex(vaultkey, 63, "%s-m-", playerName[id]);
		formatex(vaultdata, 255, "1");
		nvault_set(plik_vault, vaultkey, vaultdata);
	}
	
	if (TrieKeyExists(MuteNaMape, ip[id]))
	{
		formatex(vaultkey, 63, "%s-mip-", ip[id]) 
		formatex(vaultdata, 255, "1");
		nvault_set(plik_vault, vaultkey, vaultdata);
	}

}

public Odbanuj_Gracza(id){
	new vaultkey[64]; /*, vaultdata[256];*/
	
	formatex(vaultkey, 63, "%s-m-", playerName[id]) 
	/*formatex(vaultdata, 255, "0") 
	nvault_set(plik_vault, vaultkey, vaultdata)*/
	nvault_remove(plik_vault, vaultkey);
	
	formatex(vaultkey, 63, "%s-mip-", ip[id]) 
	/*formatex(vaultdata, 255, "0") 
	nvault_set(plik_vault, vaultkey, vaultdata)*/
	nvault_remove(plik_vault, vaultkey);
}

public Event_DeathMsg()
{
	new iVictim = read_data(2)

	g_bAlive[iVictim] = false
	
	if (!is_user_connected(iVictim) || is_user_alive(iVictim)) return
	
	g_bCan[iVictim] = true

	g_bUsed[iVictim] = false
	
	remove_task(iVictim)
	
	set_task(g_infoTime, "Stop_Info", iVictim)
}

public Stop_Info(id)
{
	g_bCan[id] = false
	
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if (!is_user_alive(iPlayer)) continue
		
		engfunc(EngFunc_SetClientListening, iPlayer, id, false)
	}
}

public Event_VoiceMask(id)
{
	g_iClientSettings[id][0] = read_data(1)
	g_iClientSettings[id][1] = read_data(2)
}

public Forward_SetClientListening(iReceiver, iSender, bool:bListen)
{
#if defined SUPER_ADMIN_PRIORITY
	if (g_iAdminVoice)
	{
		if (g_iAdminVoice == iSender)
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if ( !g_iClientSettings[iReceiver][0] || g_iClientSettings[iReceiver][1] & (1<<(iSender-1)) )
	{
		return FMRES_IGNORED
	}
#else
	if ( !g_iClientSettings[iReceiver][0] || g_iClientSettings[iReceiver][1] & (1<<(iSender-1)) )
	{
		return FMRES_IGNORED
	}

	if (g_iAdminVoice)
	{
		if (g_iAdminVoice == iSender)
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}
#endif
	if (g_bInterAdminVoice[iSender])
	{
		if (g_bAdmin[iReceiver]) 
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if (TrieKeyExists(playerMutes[iReceiver], playerName[iSender])) {
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);

		return FMRES_SUPERCEDE;
	}

	if (TrieKeyExists(MuteNaMape, playerName[iSender]) || TrieKeyExists(MuteNaMape, ip[iSender]))
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE;
	}

	if (g_bMuted[iSender])
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if (g_mute[iReceiver][iSender])
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if (g_bCan[iSender] && get_user_team(iSender) == get_user_team(iReceiver))
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
		forward_return(FMV_CELL, true)
		return FMRES_SUPERCEDE
	}

	if (g_bAdminListen[iReceiver])
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
		forward_return(FMV_CELL, true)
		return FMRES_SUPERCEDE
	}

	if (g_bAlive[iReceiver])
	{
		switch(get_pcvar_num(g_pcvarAlivesHear))
		{
			case 0:
			{
				if ( g_bAlive[iSender] && get_pdata_int(iReceiver, OFFSET_TEAM) == get_pdata_int(iSender, OFFSET_TEAM) )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 1:
			{
				if ( g_bAlive[iSender] )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 2:
			{
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
				forward_return(FMV_CELL, true)
				return FMRES_SUPERCEDE
			}
		}
	}
	else
	{
		switch(get_pcvar_num(g_pcvarDeadsHear))
		{
			case 0:
			{
				if ( !g_bAlive[iSender] && get_pdata_int(iReceiver, OFFSET_TEAM) == get_pdata_int(iSender, OFFSET_TEAM) )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 1:
			{
				if ( !g_bAlive[iSender] )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 2:
			{
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
				forward_return(FMV_CELL, true)
				return FMRES_SUPERCEDE
			}
		}
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
	forward_return(FMV_CELL, false)
	return FMRES_SUPERCEDE
}

public AdminCommand_ListenOn(id)
{
	if ( !g_bAdmin[id] )
		return PLUGIN_HANDLED

	g_bAdminListen[id] = true

	return PLUGIN_HANDLED
}

public AdminCommand_ListenOff(id)
{
	if ( g_bAdminListen[id] )
	{
		g_bAdminListen[id] = false
	}

	return PLUGIN_HANDLED
}

public AdminCommand_ListenToggle(id)
{
	if ( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	g_bAdminListen[id] = !g_bAdminListen[id]

	col_mess(id, id, "%L", id, "VM_LISTEN_STATUS", g_bAdminListen[id] ? "ON" : "OFF")

	return PLUGIN_HANDLED
}

public AdminCommand_VoiceOn(id)
{
	if (!g_bAdmin[id])
	{
		return PLUGIN_HANDLED
	}

	if (g_iAdminVoice)
	{
		col_mess(id, id, "%L", id, "VM_ALREADY_INUSE")
		return PLUGIN_HANDLED
	}

	g_iAdminVoice = id

	for(new player = 1; player <= g_iMaxPlayers; player++)
	{
		if ( is_user_connected(player) && !is_user_hltv(player) && !is_user_bot(player) )
		{
			col_mess(player, id, "%L", player, "VM_ADMIN_TALK", playerName[id])
		}
	}

	client_cmd(id, "+voicerecord")

	return PLUGIN_HANDLED
}

public AdminCommand_VoiceOff(id)
{
	if ( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	if (g_iAdminVoice != id)
	{
		client_cmd(id, "-voicerecord")
		return PLUGIN_HANDLED
	}

	client_cmd(id, "-voicerecord")
	g_iAdminVoice = 0
	return PLUGIN_HANDLED
}

public AdminCommand_InterAdminOn(id)
{
	if ( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	g_bInterAdminVoice[id] = true
	client_cmd(id, "+voicerecord")

	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if ( !g_bAdmin[i] || !is_user_connected(i) )
		{
			continue
		}
		col_mess(i, id, "%L", i, "VM_INTER_START", playerName[id]);
	}

	return PLUGIN_HANDLED
}

public AdminCommand_InterAdminOff(id)
{
	if (!g_bInterAdminVoice[id])
		return PLUGIN_HANDLED

	g_bInterAdminVoice[id] = false
	client_cmd(id, "-voicerecord")

	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if ( !g_bAdmin[i] || !is_user_connected(i) )
		{
			continue
		}
		col_mess(i, id, "%L", i, "VM_INTER_STOP", playerName[id]);
	}

	return PLUGIN_HANDLED
}

public AdminCommand_Mute(id, level, cid)
{
	if ( !cmd_access(id, level, cid, 2, true) )
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[32]
	read_argv(1, szPlayer, 31)
	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS)

	if ( !iPlayer )
	{
		return PLUGIN_HANDLED
	}

	if ( g_bAdmin[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_MUTE_ADMIN")
		return PLUGIN_HANDLED
	}

	if ( g_bMuted[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_AR_MUTED")
		return PLUGIN_HANDLED
	}

	g_bMuted[iPlayer] = true
	client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_MUTED")

	if (g_amx_show_activity)
	{
		show_activity_col(id, playerName[id], playerName[iPlayer], "VM_MUTE_ACTIVITY")
	}
	return PLUGIN_HANDLED
}

public AdminCommand_UnMute(id, level, cid)
{
	if ( !cmd_access(id, level, cid, 2, true) )
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[32], iPlayer
	read_argv(1, szPlayer, 31)
	iPlayer = cmd_target(id, szPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS)

	if ( !iPlayer )
	{
		return PLUGIN_HANDLED
	}

	if ( !g_bMuted[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_NOT_MUTED")
		return PLUGIN_HANDLED
	}

	g_bMuted[iPlayer] = false
	client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_UNMUTED")

	if (g_amx_show_activity)
	{
		show_activity_col(id, playerName[id], playerName[iPlayer], "VM_UNMUTE_ACTIVITY")
	}

	return PLUGIN_HANDLED
}

display_mutemenu(id, pos) 
{
	if (pos < 0)  
		return
		
	static team[11]
	get_user_team(id, team, 10)
	
	new at = get_pcvar_num(cvar_alltalk)
	get_players(g_menuplayers[id], g_menuplayersnum[id], 
	at ? "c" : "ce", at ? "" : team)

  	new start = pos * 8
  	if (start >= g_menuplayersnum[id])
    		start = pos = g_menuposition[id]

  	new end = start + 8
	if (end > g_menuplayersnum[id])
    		end = g_menuplayersnum[id]
	
	static menubody[512]	
  	new len = format(menubody, 511, "\wMute Menu^n^n")
	
	new b = 0, i
	new keys = MENU_KEY_0
	
  	for(new a = start; a < end; ++a)
	{
		i = g_menuplayers[id][a]
		
		if (i == id)
		{
			++b
			len += format(menubody[len], 511 - len, "\d#  %s %s\w^n", playerName[i], g_mute[id][i] ? "(Zmutowany)" : "")
		}
		else
		{
			keys |= (1<<b)
			len += format(menubody[len], 511 - len, "%s%d. %s %s\w^n", g_mute[id][i] ? "\y" : "\w", ++b, playerName[i], g_mute[id][i] ? "(Zmutowany)" : "")
		}
	}

  	if (end != g_menuplayersnum[id]) 
	{
    	format(menubody[len], 511 - len, "^n9. %s...^n0. %s", "Wiecej", pos ? "Wroc" : "Wyjdz")
    	keys |= MENU_KEY_9
  	}
  	else
		format(menubody[len], 511-len, "^n0. %s", pos ? "Wroc" : "Wyjdz")
	
  	show_menu(id, keys, menubody, -1, "mute menu")
}

public show_mutemenu(id)
	if (get_pcvar_num(g_pcvarMuteMenu)) display_mutemenu(id, g_menuposition[id] = 0)

public action_mutemenu(id, key)
{
	switch(key) 
	{
		case 8: display_mutemenu(id, ++g_menuposition[id])
		case 9: display_mutemenu(id, --g_menuposition[id])
		default: 
		{
			new player = g_menuplayers[id][g_menuposition[id] * 8 + key]
		
			g_mute[id][player] = g_mute[id][player] ? false : true
			display_mutemenu(id, g_menuposition[id])
		
			if (g_mute[id][player])
				client_print_color(id, print_team_red, "^x03[MUTE]^x01 Uciszyles gracza^x04 %s", playerName[player])
			else
				client_print_color(id, print_team_red, "^x03[MUTE]^x01 Przywrociles glos graczowi^x04 %s",playerName[player])
		}
  	}
	return PLUGIN_HANDLED
}

stock Z_or_od_banujGracza(const text[], bantype=1, wartosc=1){
	new vaultkey[64], vaultdata[256];
	new cReturn = 0;
	
	if (bantype == 1 || bantype == 2){
		formatex(vaultkey, 63, "%s-m-", text);
		formatex(vaultdata, 255, "%d", wartosc);
		nvault_set(plik_vault, vaultkey, vaultdata);	
		cReturn++;
	}
	
	if (bantype == 0 || bantype == 2)
	{
		formatex(vaultkey, 63, "%s-mip-", text);
		formatex(vaultdata, 255, "%d");
		nvault_set(plik_vault, vaultkey, vaultdata);
		cReturn++;
	}
	
	return cReturn;
}

clear_list(id)
	for(new i = 0; i <= g_iMaxPlayers; ++i) g_mute[id][i] = false

col_mess(id, sender, string[], any:...)
{
	static szMessage[128]
	szMessage[0] = 0x01
	vformat(szMessage[1], 127, string, 4)

	replace_all(szMessage, 127, "!n", "^x01")
	replace_all(szMessage, 127, "!t", "^x03")
	replace_all(szMessage, 127, "!g", "^x04")

	message_begin(MSG_ONE_UNRELIABLE, g_msgidSayText, _, id)
	write_byte(sender)
	write_string(szMessage)
	message_end()
}

show_activity_col(id, name[], name2[], ML_KEY[])
{
	switch(get_pcvar_num(g_amx_show_activity))
	{
		case 5: // hide name only to admins, show nothing to normal users
		{		
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[GLOS] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
					}
				}
			}
		}
		case 4: // show name only to admins, show nothing to normal users
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[GLOS] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
					}
				}
			}
		}
		case 3: // show name only to admins, hide name from normal users
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[GLOS] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
					}
					else
					{
						col_mess(i, id, " ** !g[GLOS] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
					}
				}
			}
		}
		case 2: // show name to all
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					col_mess(i, id, " ** !g[GLOS] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
				}
			}
		}
		case 1: // hide name to all
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					col_mess(i, id, " ** !g[GLOS] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
				}
			}
		}
	}
}

public menu_show(id)
{
	new menu = menu_create("\yMenu \rMutowania\w:", "menu_show_handle");

	menu_additem(menu, "\wZmutuj \yGracza");
	menu_additem(menu, "\wOdmutuj \yGracza");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public menu_show_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id)) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	item ? unmute_menu(id) : mute_menu(id);

	return PLUGIN_HANDLED;
}

public mute_menu(id)
{
	new players, menu = menu_create("\yWybierz gracza, ktorego chcesz \rzmutowac\w:", "mute_menu_handle");
	
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || TrieKeyExists(playerMutes[id], playerName[i]) || get_user_flags(i) & ADMIN_IMMUNITY) continue;

		menu_additem(menu, playerName[i]);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[MUTE]^x01 Na serwerze mie ma nikogo, kogo moglbys zmutowac!"); 
	else menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public mute_menu_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new name[32], tempData[1], access, callback;
	
	menu_item_getinfo(menu, item, access, tempData, charsmax(tempData), name, charsmax(name), callback);

	menu_destroy(menu);
	
	playerId[id] = get_user_index(name);

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}
	
	new menu = menu_create("\yWybierz \rtyp mute\w:", "mute_menu_type_handle");
	
	menu_additem(menu, "Na \yMape");
	menu_additem(menu, "Na \rZawsze");

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public mute_menu_type_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");
		
		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			TrieSetCell(playerMutes[id], playerName[playerId[id]], 0);
			
			client_print_color(id, id, "^x04[MUTE]^x01 Zmutowales^x04 na mape^x01 gracza^x03 %s^x01.", playerName[playerId[id]]);
		} case 1: {
			static queryData[128];

			formatex(queryData, charsmax(queryData), "INSERT INTO `advanced_mute` (`name`, `muted`) VALUES (^"%s^", ^"%s^");", safePlayerName[id], safePlayerName[playerId[id]]);

			SQL_ThreadQuery(sql, "ignore_handle", queryData);

			TrieSetCell(playerMutes[id], playerName[playerId[id]], 1);
			
			client_print_color(id, id, "^x04[MUTE]^x01 Zmutowales^x04 na zawsze^x01 gracza^x03 %s^x01.", playerName[playerId[id]]);
		}
	}

	return PLUGIN_HANDLED;
}

public unmute_menu(id)
{
	new menuData[64], itemData[8], players, type, menu = menu_create("\yWybierz gracza, ktorego chcesz \rodmutowac\w:", "unmute_menu_handle");

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || !TrieKeyExists(playerMutes[id], playerName[i])) continue;

		TrieGetCell(playerMutes[id], playerName[i], type);

		formatex(menuData, charsmax(menuData), "\w%s %s", playerName[i], type ? "\r[Na Zawsze]" : "\r[Na Mape]");
		formatex(itemData, charsmax(itemData), "%i#%i", i, type);

		menu_additem(menu, menuData, itemData);

		players++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!players) client_print_color(id, id, "^x04[MUTE]^x01 Zaden z graczy na serwerze nie jest przez ciebie zmutowany!"); 
	else menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public unmute_menu_handle(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new itemData[8], tempId[4], type[2], access, callback;
	
	menu_item_getinfo(menu, item, access, itemData, charsmax(itemData), _, _, callback);

	menu_destroy(menu);

	split(itemData, tempId, charsmax(tempId), type, charsmax(type), "#");

	playerId[id] = str_to_num(tempId);

	if (!is_user_connected(playerId[id])) {
		client_print_color(id, id, "^x04[MUTE]^x01 Wybranego gracza nie ma juz na serwerze!");
		
		return PLUGIN_HANDLED;
	}

	TrieDeleteKey(playerMutes[id], playerName[playerId[id]]);

	if (str_to_num(type)) {
		static queryData[128];

		formatex(queryData, charsmax(queryData), "DELETE FROM `advanced_mute` WHERE name = ^"%s^" AND mutes = ^"%s^");", safePlayerName[id], safePlayerName[playerId[id]]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	client_print_color(id, id, "^x04[MUTE]^x01 Odmutowales gracza^x03 %s^x01!", playerName[playerId[id]]); 
	
	return PLUGIN_HANDLED;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], error[128], errorNum;
	
	get_cvar_string("advanced_mute_host", host, charsmax(host));
	get_cvar_string("advanced_mute_user", user, charsmax(user));
	get_cvar_string("advanced_mute_pass", pass, charsmax(pass));
	get_cvar_string("advanced_mute_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connection = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_amx("[MUTE] SQL Query Error: %s", error);
		
		return;
	}

	new queryData[128];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `advanced_mute` (`id` INT(11) AUTO_INCREMENT, `name` VARCHAR(32) NOT NULL, `muted` VARCHAR(32) NOT NULL, PRIMARY KEY(`id`));");  

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connection);

	sqlConnection = true;
}

public load_mutes(id)
{
	if (!sqlConnection) {
		set_task(1.0, "load_mutes", id);

		return;
	}

	static playerId[1], queryData[128];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `advanced_mute` WHERE name = ^"%s^"", safePlayerName[id]);
	
	SQL_ThreadQuery(sql, "load_mutes_handle", queryData, playerId, sizeof(playerId));
}

public load_mutes_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_amx("[MUTE] SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new muteName[32], id = playerId[0];
	
	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "muted"), muteName, charsmax(muteName));

		TrieSetCell(playerMutes[id], muteName, 1);

		SQL_NextRow(query);
	}
}

public ignore_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState == TQUERY_CONNECT_FAILED) log_amx("[MUTE] Could not connect to SQL database. [%d] %s", errorCode, error);
	else if (failState == TQUERY_QUERY_FAILED) log_amx("[MUTE] Query failed. [%d] %s", errorCode, error);
}

stock sql_safe_string(const source[], dest[], length)
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
