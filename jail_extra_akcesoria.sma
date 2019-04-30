#include <amxmodx>
#include <cstrike>
#include <fun>
#include <engine> 

#define PLUGIN "JailBreak: Akcesoria"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new iPlayer[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /akcesoria", "Akcesoria");
	register_clcmd("say_team /akcesoria", "Akcesoria");
	register_clcmd("akcesoria", "Akcesoria");	
	
	register_clcmd("say /dajdeagla", "Deagle");
	register_clcmd("say_team /dajdeagla", "Deagle");
	register_clcmd("dajdeagla", "Deagle");
}

public plugin_precache()
	precache_generic("sound/reload/dzwonek.wav");

public Akcesoria(id)
{
	if(get_user_team(id) != 2) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yAkcesoria Straznika\w:", "Akcesoria_Handler");
	
	menu_additem(menu, "\wZrob \yGong");  
	menu_additem(menu, "\wStworz \yPilke");
	menu_additem(menu, "\wCzas \yMeczu");
	menu_additem(menu, "\wPodziel \yWiezniow");
	menu_additem(menu, "\wUsun \yPodzial");
	menu_additem(menu, "\wLosuj \yWieznia");
	menu_additem(menu, "\wDaj \yZyczenie");
	menu_additem(menu, "\wDaj \yDeagla");
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public Akcesoria_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{	
		case 0: client_cmd(0, "spk sound/reload/dzwonek.wav");
		case 1: client_cmd(id, "say /ball");
		case 2: client_cmd(id, "say /mecz");
		case 3: client_cmd(id, "say /podziel");
		case 4: client_cmd(id, "say /rozdziel");
		case 5: client_cmd(id, "say /losuj");
		case 6: client_cmd(id, "say /obsluga");
		case 7: Deagle(id);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
} 

public Deagle(id) 
{
	new szName[64], szNum[4], menu = menu_create("\yWybierz \rGracza\w:", "Deagle_Handler");
	
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

public Deagle_Handler(id, menu, item)
{
	if(item == MENU_EXIT || get_user_team(id) != 2)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szNum[4], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szNum, charsmax(szNum), _, _, iCallback);
	
	iPlayer[id] = str_to_num(szNum);
	
	menu_destroy(menu);
	
	new menu = menu_create("\yWybierz \rOpcje\w:", "GiveDeagle");
	
	menu_additem(menu, "\wDeagle bez naboi");
	menu_additem(menu, "\wDeagle z 1 nabojem");
	menu_additem(menu, "\wDeagle z 3 nabojami");
	menu_additem(menu, "\wDeagle z pelnym magazynkiem");  
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public GiveDeagle(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[64], iDeagle = find_ent_by_owner(-1, "weapon_deagle", iPlayer[id]);
	
	cs_set_user_bpammo(id, CSW_DEAGLE, 0);
	
	get_user_name(iPlayer[id], szName, charsmax(szName));
	
	give_item(iPlayer[id], "weapon_deagle");
	
	switch(item)
	{
		case 0:
		{
			if(iDeagle) cs_set_weapon_ammo(iDeagle, 0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal pustego deagla.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales pustego deagla.");
		}
		case 1:
		{
			if(iDeagle) cs_set_weapon_ammo(iDeagle, 1);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z jednym nabojem.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z jednym nabojem.");
		}
		case 2:
		{
			if(iDeagle) cs_set_weapon_ammo(iDeagle, 3);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z 3 nabojami.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z 3 nabojami.");
		}
		case 3:
		{
			if(iDeagle) cs_set_weapon_ammo(iDeagle, 7);
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z pelnym magazynkiem.", szName);
			
			client_print_color(iPlayer[id], iPlayer[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z pelnym magazynkiem.");
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}
