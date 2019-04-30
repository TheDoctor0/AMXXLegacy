#include <amxmodx>
#include <fakemeta_util>
#include <jailbreak>

#define PLUGIN "JailBreak: Oznacz"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new iPlayer[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /oznacz", "MenuOznacz");
	register_clcmd("say_team /oznacz", "MenuOznacz");
	register_clcmd("oznacz", "MenuOznacz");
}

public MenuOznacz(id)
{
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED;

	new szName[64], szNum[4], menu = menu_create("\rWiezienie CS-Reload \yWybierz Gracza\w:", "MenuOznacz_Handler");

	for(new i = 0; i <= 32; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 1) continue;

		num_to_str(i, szNum, charsmax(szNum));

		get_user_name(i, szName, charsmax(szName));
		
		menu_additem(menu, szName, szNum);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuOznacz_Handler(id, menu, item) 
{
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new szNum[4], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szNum, charsmax(szNum), _, _, iCallback);
	
	iPlayer[id] = str_to_num(szNum);
	
	if(!is_user_alive(iPlayer[id])) return PLUGIN_HANDLED;
	
	menu_destroy(menu);
	
	new menu = menu_create("\rWIEZIENIE CS-R\yWybierz Kolor\w:", "MenuKolor_Handler");

	menu_additem(menu, "\wCzerwony");
	menu_additem(menu, "\wZielony");
	menu_additem(menu, "\wNiebieski");
	menu_additem(menu, "\wZolty");
	menu_additem(menu, "\wRozowy");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuKolor_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id) || !is_user_alive(iPlayer[id]))
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new szName[33];
	
	get_user_name(iPlayer[id], szName, charsmax(szName));
	
	switch(item)
	{
		case 0:
		{
			fm_set_user_rendering(iPlayer[id], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ustawiles graczowi^x03 %s^x01 kolor^x03 czerwony^x01.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor^x03 czerwony^x01.", szName);
		}
		case 1:
		{
			fm_set_user_rendering(iPlayer[id], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 25);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ustawiles graczowi^x03 %s^x01 kolor^x03 zielony^x01.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor^x03 zielony^x01.", szName);
		}
		case 2:
		{
			fm_set_user_rendering(iPlayer[id], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ustawiles graczowi^x03 %s^x01 kolor^x03 niebieski^x01.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor^x03 niebieski^x01.", szName);
		}
		case 3:
		{
			fm_set_user_rendering(iPlayer[id], kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 25);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ustawiles graczowi^x03 %s^x01 kolor^x03 zolty^x01.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor^x03 zolty^x01.", szName);
		}
		case 4:
		{
			fm_set_user_rendering(iPlayer[id], kRenderFxGlowShell, 255, 0, 255, kRenderNormal, 25);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Ustawiles graczowi^x03 %s^x01 kolor^x03 rozowy^x01.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor^x03 rozowy^x01.", szName);
		}
	}
	
	return PLUGIN_HANDLED;
}