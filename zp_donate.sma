#include <amxmodx>  
#include <fakemeta>  

native zp_set_user_ammo_packs(id, amount)
native zp_get_user_ammo_packs(id)
native register_system_check(id)

new chosen[33]
new g_menu_data[33][1]
#define MENU_PAGE_PLAYERS g_menu_data[id][0]

public plugin_init() 
{  
	register_plugin("ZP Donate", "1.1", "O'Zone")  	
	register_clcmd("say /daj", "DonateMenu")
	register_clcmd("say /donate", "DonateMenu")  
	register_clcmd("say /przelej", "DonateMenu")
	register_clcmd("say /przelew", "DonateMenu")
	register_clcmd("Ilosc", "Donate_Handler");
} 

public plugin_natives()
	register_native("donate_show", "DonateMenu",1)

public DonateMenu(id) 
{ 
	if(!register_system_check(id))
		return PLUGIN_HANDLED
	
	new menu[256], player_name[32], player_id[2], menuid, player, players
	
	formatex(menu, charsmax(menu), "\r[\yPrzelew AP\r]^n\wWybierz \yGracza\w:")
	menuid = menu_create(menu, "DonateMenu_Handler")
	
	for (player = 1; player <= 32; player++)
	{
		if (!is_user_connected(player) || player == id || is_user_hltv(id))
			continue;
		
		get_user_name(player, player_name, charsmax(player_name))
		
		formatex(menu, charsmax(menu), "%s \y[%d AP]", player_name, zp_get_user_ammo_packs(player))
		formatex(player_id, charsmax(player_id), "%i", get_user_index(player_name))
		
		menu_additem(menuid, menu, player_id)
		
		players++
	}
	
	menu_setprop(menuid, MPROP_BACKNAME, "Wroc")
	menu_setprop(menuid, MPROP_NEXTNAME, "Dalej")
	menu_setprop(menuid, MPROP_EXITNAME, "Wyjscie")
	
	MENU_PAGE_PLAYERS = min(MENU_PAGE_PLAYERS, menu_pages(menuid) - 1)
	
	set_pdata_int(id, 205, 0)
	menu_display(id, menuid, MENU_PAGE_PLAYERS)
	
	if(!players)
	{
		menu_destroy(menuid)
		client_print_color(id, id, "^x04[ZP]^x01 Na serwerze nie ma gracza, ktoremu moglbys przelac AP!")
	}
	
	return PLUGIN_HANDLED
}

public DonateMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new name[32], callback, data[6], access
	menu_item_getinfo(menu, item, access, data, 5, name, 31, callback)
	
	new id2 = str_to_num(data)
	
	if(!is_user_connected(id2) || is_user_hltv(id2))
	{
		client_print_color(id, id, "^x04[ZP]^x01 Tego gracza nie ma juz na serwerze!")
		return PLUGIN_HANDLED
	}
	
	chosen[id] = id2
	client_cmd(id, "messagemode Ilosc")
	client_print_color(id, id, "^x04[ZP]^x01 Wpisz ilosc^x03 AP^x01, ktora chcesz przelac!")
	client_print(id, print_center, "Wpisz ilosc AP, ktora chcesz przelac!")
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public Donate_Handler(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
		
	if(!is_user_connected(chosen[id]) || is_user_hltv(chosen[id]))
	{
		client_print_color(id, id, "^x04[ZP]^x01 Gracza, ktoremu chcesz AP kase nie ma juz na serwerze!")
		return PLUGIN_HANDLED
	}
	
	new szArgs[10], ap_amount, ap, player
	read_args(szArgs, charsmax(szArgs))
	remove_quotes(szArgs);
	player = chosen[id]
	ap_amount = str_to_num(szArgs)
	ap = zp_get_user_ammo_packs(id)
	
	if (ap_amount == 0) 
	{ 
		client_print_color(id, id, "^x04[ZP]^x01 Nie mozesz przelac^x04 0 AP^x01!")
		return PLUGIN_HANDLED
	} 
	
	new name[32], name2[32], ip[32], ip2[32], steam_id[35], steam_id2[35]
	get_user_name(id, name, 31) 
	get_user_name(player, name2, 31)
	get_user_ip(id, ip, 31, 1)
	get_user_ip(player, ip2, 31, 1)
	get_user_authid(id, steam_id, 34)
	get_user_authid(player, steam_id2, 34)
	
	if (ap < ap_amount) 
	{ 
		client_print_color(id, id, "^x04[ZP]^x01 Nie masz tyle AP!")
		return PLUGIN_HANDLED
	} 
	
	if (ap_amount < 0) 
	{ 
		client_print_color(id, id, "^x04[ZP]^x01 Nie probuj krasc AP^x03 %s^x01!", name2)
		return PLUGIN_HANDLED
	}
	
	zp_set_user_ammo_packs(player, zp_get_user_ammo_packs(player) + ap_amount)
	zp_set_user_ammo_packs(id, ap - ap_amount)
	client_print_color(0, id, "^x04[ZP]^x01 %s^x01 przelal^x03 %iAP^x01 na konto^x04 %s", name, ap_amount, name2)
	
	log_to_file("addons/amxmodx/logs/przelew_ap.txt", "%s <%s><%s> przelal %i AP na konto %s <%s><%s>", name, ip, steam_id, ap_amount, name2, ip2, steam_id2)
	
	return PLUGIN_HANDLED
}
