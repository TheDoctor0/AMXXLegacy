#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <jailbreak>
 
#define PLUGIN "JailBreak: Wojna Bogow"
#define VERSION "1.0.9"
#define AUTHOR "O'Zone"
 
new id_bog;
 
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
 
	id_bog = jail_register_game("Wojna Bogow");
}

public plugin_precache()
	precache_generic("sound/reload/dzienbogow.mp3");
 
public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{ 
	if(day == id_bog)
	{
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nWiezniowie wybieraja Boga z menu^nPo tym rozpoczyna sie walka Wiezniow miedzy soba.^nOstatni Wiezien ma zyczenie.");
		
		szInfo = "Wojna Bogow";
 
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
 
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 1;
	}
}
 
public OnDayStartPost(day)
{
	if(day == id_bog)
	{
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_bog)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== TT vs TT ==");

		client_cmd(0, "mp3 play sound/reload/dzienbogow.mp3");
 
		jail_set_prisoners_fight(true, false, false);
		
		for(new i = 1; i <= MAX; i++) if(is_user_alive(i) && get_user_team(i) == 1) GodMenu(i);
	}
}

public GodMenu(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \yWybierz Boga\w:", "GodMenu_Handler");

	menu_additem(menu, "\wZeus \r[300 HP + Wszystkie Granaty + Deagle + AWP]")
	menu_additem(menu, "\wAres \r[100 HP + MP5 + M249 + AWP + Deagle]");
	menu_additem(menu, "\wApollo \r[200 HP + M4A1 + Noz]");
	menu_additem(menu, "\wHades \r[500 HP + Glock + Noz]");

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
 
public GodMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		//menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	switch (item)
	{
		case 0: Zeus(id);
        case 1:	Ares(id);
		case 2:	Apollo(id);
		case 3:	Hades(id);
	}
	
	//menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public Zeus(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	set_user_health(id, 300);
	
	strip_user_weapons(id);
	
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_smokegrenade");
	give_item(id, "weapon_deagle");
	give_item(id, "weapon_awp");

	cs_set_user_bpammo(id, CSW_FLASHBANG, 999);
	cs_set_user_bpammo(id, CSW_HEGRENADE, 999);
	cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 999);
	cs_set_user_bpammo(id, CSW_DEAGLE, 9999);
	cs_set_user_bpammo(id, CSW_AWP, 9999);
	
	return PLUGIN_HANDLED;
}

public Ares(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	set_user_health(id, 100);
	
	strip_user_weapons(id);
	
	give_item(id,"weapon_deagle");                 
	give_item(id,"weapon_mp5navy");
	give_item(id,"weapon_awp");            
	give_item(id,"weapon_m249");

	cs_set_user_bpammo(id, CSW_DEAGLE, 9999);
	cs_set_user_bpammo(id, CSW_MP5NAVY, 9999);
	cs_set_user_bpammo(id, CSW_AWP, 9999);
	cs_set_user_bpammo(id, CSW_M249, 9999);
	
	return PLUGIN_HANDLED;
}

public Apollo(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	set_user_health(id, 200);
	
	strip_user_weapons(id);
	
	give_item(id, "weapon_m4a1");
	give_item(id, "weapon_knife");

	cs_set_user_bpammo(id, CSW_M4A1, 9999);
	
	return PLUGIN_HANDLED;
}

public Hades(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	set_user_health(id, 500);
	
	strip_user_weapons(id);
	
	give_item(id, "weapon_glock18");
	give_item(id, "weapon_knife");
	
	cs_set_user_bpammo(id, CSW_GLOCK18, 9999);
	
	return PLUGIN_HANDLED;
}