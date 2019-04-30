#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <fakemeta>

#define PLUGIN "JailBreak: Perm Mute"
#define VERSION "2.1"
#define AUTHOR "HubertTM & O'Zone"

#define TASK_MUTE 5802

new gName[33][32], gIP[33][24], Trie:gMute, gVault;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	gVault = nvault_open("PermMute");
	
	if(gVault == INVALID_HANDLE) set_fail_state("[MUTE] Nie mozna otworzyc pliku PermMute.vault");
	
	gMute = TrieCreate();
	
	register_clcmd("amx_permmute", "DajMute", 0, "name>");
	register_clcmd("amx_permmute_menu", "DajMuteMenu");
	register_clcmd("amx_permmutemenu", "DajMuteMenu");
	
	register_clcmd("amx_unmutemenu", "DajUnmuteMenu");
	register_clcmd("amx_unmute_menu", "DajUnmuteMenu");
	register_clcmd("amx_unpermmute_menu", "DajUnmuteMenu");
	register_clcmd("amx_unpermmutemenu", "DajUnmuteMenu");
	
	register_clcmd("amx_mute2", "DajMute2", 0, "<name>");
	register_clcmd("amx_mute2menu", "DajMuteMenu2", 0, "<name>");
	register_clcmd("amx_mute2_menu", "DajMuteMenu2", 0, "<name>");
	
	register_forward(FM_Voice_SetClientListening, "Voice_SetClientListening");
}

public client_putinserver(id)
{
	gName[id] = "";
	gIP[id] = "";

	remove_task(id + TASK_MUTE);
	
	set_task(1.0, "Wczytaj", id + TASK_MUTE);
}

public client_disconnected(id)
{
	remove_task(id + TASK_MUTE);

	gName[id] = "";
	gIP[id] = "";
}

public plugin_end()
	nvault_close(gVault);

public Wczytaj(id)
{
	id -= TASK_MUTE;
	
	if(is_user_connected(id))
	{
		get_user_name(id, gName[id], 31);
		get_user_ip(id, gIP[id], 23);
		
		if(!TrieKeyExists(gMute, gName[id]) && !TrieKeyExists(gMute, gIP[id])) wczytaj_mute(id);
	}
}

public DajMuteMenu(id)
{
	if(!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yZmutuj Gracza - Na Zawsze\w:", "DajMuteMenuH");
	
	for(new i = 1; i <= 32; i++) if(is_user_connected(i) && !TrieKeyExists(gMute, gName[i]) && !TrieKeyExists(gMute, gIP[i]) && !(get_user_flags(i) & read_flags("a")))	menu_additem(menu, gName[i]);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED
}

public DajMuteMenuH(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id)) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szData[1], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new player = get_user_index(szName);
	
	if (!player || !is_user_connected(player))
	{
		client_print(id, print_console, "Gracz %s nie zostal znaleziony!", szName);
		
		return PLUGIN_HANDLED;
	}
	else
	{
		new szAdmin[32];
		
		get_user_name(id, szAdmin, charsmax(szAdmin));
		
		client_print(id, print_console, "Zmutowano gracza %s!", szName);
		
		TrieSetCell(gMute, gName[player], 1); 
		TrieSetCell(gMute, gIP[player], 1);
		
		zapisz_mute(player);
		
		client_cmd(player, "-voicerecord");
		
		client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na zawsze przez admina^x04 %s^x01.", szName, szAdmin);
	}
	
	return PLUGIN_HANDLED;
}

public DajMuteMenu2(id)
{
	if(!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yZmutuj Gracza - Na Mape\w:", "DajMuteMenuH2");
	
	for(new i = 1; i <= 32; i++) if(is_user_connected(i) && !TrieKeyExists(gMute, gName[i]) && !TrieKeyExists(gMute, gIP[i]) && !(get_user_flags(i) & read_flags("a")))	 menu_additem(menu, gName[i]);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED
}

public DajMuteMenuH2(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id)) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szData[1], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new player = get_user_index(szName);
	
	if (!player || !is_user_connected(player))
	{
		client_print(id, print_console, "Gracz %s nie zostal znaleziony!", szName);
		
		return PLUGIN_HANDLED;
	}
	else
	{
		new szAdmin[32];
		
		get_user_name(id, szAdmin, charsmax(szAdmin));
		
		client_print(id, print_console, "Zmutowano gracza %s!", szName);
		
		TrieSetCell(gMute, gName[player], 1); 
		TrieSetCell(gMute, gIP[player], 1);
		
		client_cmd(player, "-voicerecord");
		
		client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na mape przez admina^x04 %s^x01.", szName, szAdmin);
	}
	
	return PLUGIN_HANDLED;
}


public DajUnmuteMenu(id)
{
	if(!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yOdmutuj Gracza\w:", "DajUnmuteMenuH");
	
	for(new i = 1; i <= 32; i++) if(is_user_connected(i) && (TrieKeyExists(gMute, gName[i]) || TrieKeyExists(gMute, gIP[i])))	 menu_additem(menu, gName[i]);

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public DajUnmuteMenuH(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id)) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szData[1], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new player = get_user_index(szName);
	
	if (!player || !is_user_connected(player))
	{
		client_print(id, print_console, "Gracz %s nie zostal znaleziony!", szName);
		
		return PLUGIN_HANDLED;
	}
	else
	{
		new szAdmin[32];
		
		get_user_name(id, szAdmin, charsmax(szAdmin));
		
		client_print(id, print_console, "Zmutowano gracza %s!", szName);
		
		Odbanuj_Gracza(player);
		
		if(TrieKeyExists(gMute, gName[player])) TrieDeleteKey(gMute, gName[player]);
		
		if(TrieKeyExists(gMute, gIP[player])) TrieDeleteKey(gMute, gIP[player]);
		
		client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal odmutowany przez admina^x04 %s^x01.", szName, szAdmin);
	}
	
	return PLUGIN_HANDLED;
}

public DajMute(id)
{
	if(!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new szPlayer[32];
	
	read_argv(1, szPlayer, charsmax(szPlayer));
	
	if(!szPlayer[0]) return PLUGIN_CONTINUE;
	
	new szAdmin[32], player = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF)
	
	get_user_name(id, szAdmin, charsmax(szAdmin));
	
	if (!player || !is_user_connected(player))
	{
		new cReturn = Z_or_od_banujGracza(szPlayer, 2, 1);
		
		if(cReturn) client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na zawsze przez admina^x04 %s^x01.", szPlayer, szAdmin);
		else client_print(id, print_console, "Gracz %s nie zostal odnaleziony.", szPlayer);
		
		return PLUGIN_HANDLED;
	}
	else
	{
		client_print(id, print_console, "Zmutowano gracza %s!", szPlayer);
		
		TrieSetCell(gMute, gName[player], 1); 
		TrieSetCell(gMute, gIP[player], 1);
		
		zapisz_mute(player);
		
		client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na zawsze przez admina^x04 %s^x01.", szPlayer, szAdmin);
	}
	
	return PLUGIN_HANDLED;
}

public DajMute2(id)
{
	if(!(get_user_flags(id) & read_flags("c")) && id != 0) return PLUGIN_HANDLED;
	
	new szPlayer[32];
	
	read_argv(1, szPlayer, charsmax(szPlayer));
	
	if(!szPlayer[0]) return PLUGIN_CONTINUE;
	
	new szAdmin[32], player = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF)
	
	get_user_name(id, szAdmin, charsmax(szAdmin));
	
	if (!player || !is_user_connected(player))
	{
		new cReturn = Z_or_od_banujGracza(szPlayer, 2, 1);
		
		if(cReturn) client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na mape przez admina^x04 %s^x01.", szPlayer, szAdmin);
		else client_print(id, print_console, "Gracz %s nie zostal odnaleziony.", szPlayer);
		
		return PLUGIN_HANDLED;
	}
	else
	{
		client_print(id, print_console, "Zmutowano gracza %s!", szPlayer);
		
		TrieSetCell(gMute, gName[player], 1); 
		TrieSetCell(gMute, gIP[player], 1);
		
		client_print_color(id, print_team_red, "^x03[MUTE]^x01 Gracz^x04 %s^x01 zostal zmutowany na mape przez admina^x04 %s^x01.", szPlayer, szAdmin);
	}
	
	return PLUGIN_HANDLED;
}

public wczytaj_mute(id)
{
	new szVaultKey[64], szVaultData[256], szData[6];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-m-", gName[id]);
	nvault_get(gVault, szVaultKey, szVaultData, charsmax(szVaultData));
	
	parse(szVaultData, szData, charsmax(szData)); 
	
	if(str_to_num(szData)) TrieSetCell(gMute, gName[id], 1);
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-mip-", gIP[id]) 
	nvault_get(gVault, szVaultKey, szVaultData, charsmax(szVaultData));
	
	parse(szVaultData, szData, charsmax(szData));
	
	if(str_to_num(szData)) TrieSetCell(gMute, gIP[id], 1);
}  


public zapisz_mute(id)
{
	new szVaultKey[64], szVaultData[256];
	
	if(TrieKeyExists(gMute, gName[id]))
	{
		formatex(szVaultKey, charsmax(szVaultKey), "%s-m-", gName[id]);
		formatex(szVaultData, charsmax(szVaultData), "1");
		
		nvault_set(gVault, szVaultKey, szVaultData);
	}
	
	if(TrieKeyExists(gMute, gIP[id]))
	{
		formatex(szVaultKey, charsmax(szVaultKey), "%s-mip-", gIP[id]);
		formatex(szVaultData, charsmax(szVaultData), "1");
		
		nvault_set(gVault, szVaultKey, szVaultData);
	}
}

public Odbanuj_Gracza(id)
{
	new szVaultKey[64];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-m-", gName[id]) ;

	nvault_remove(gVault, szVaultKey);
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-mip-", gIP[id]) 

	nvault_remove(gVault, szVaultKey);
}

public Voice_SetClientListening(odbiorca, nadawca, listen) 
{
	if(odbiorca == nadawca || !is_user_connected(nadawca)) return FMRES_IGNORED;
	
	if(TrieKeyExists(gMute, gName[nadawca]) || TrieKeyExists(gMute, gIP[nadawca]))
	{
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

stock Z_or_od_banujGracza(const text[], bantype = 1, szData = 1)
{
	new szVaultKey[64], szVaultData[256], cReturn = 0;
	
	if(bantype == 1 || bantype == 2)
	{
		formatex(szVaultKey, charsmax(szVaultKey), "%s-m-", text);
		formatex(szVaultData, charsmax(szVaultData), "%d", szData);
		
		nvault_set(gVault, szVaultKey, szVaultData);
		
		cReturn++;
	}
	
	if(bantype == 0 || bantype == 2)
	{
		formatex(szVaultKey, charsmax(szVaultKey), "%s-mip-", text);
		formatex(szVaultData, charsmax(szVaultData), "%d");
		
		nvault_set(gVault, szVaultKey, szVaultData);
		
		cReturn++;
	}
	
	return cReturn;
}