#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <jailbreak>
#include <engine> 

#define PLUGIN "JailBreak: Menu"
#define VERSION "1.0.8"
#define AUTHOR "O'Zone"

#define TASK_REVISION 4565

#define MENU_ADMIN 1
#define MENU_SPECT 2
#define MENU_PRISONER 3
#define MENU_GUARD 4
#define MENU_ACCESSORY 5
#define MENU_DEAGLE 6
#define MENU_RULES 7
#define MENU_FREEDAY 8
#define MENU_GIVE_FREEDAY 9
#define MENU_GIVE_GHOST 10
#define MENU_TAKE_FREEDAY 11
#define MENU_TAKE_GHOST 12

new iPlayerID[33], iMenu[33], iRevision[33], bool:bMicro, bool:bFight, bool:bAutoBH;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("Damage", "Damage", "b", "2!=0");
	register_event("ResetHUD", "SpawnPlayer", "be");
	
	register_clcmd("+revision", "RevisionOn");
	register_clcmd("-revision", "RevisionOff");
	
	register_clcmd("+steal", "StealWeapon");
	register_clcmd("-steal", "CommandBlock");
	
	register_clcmd("say /menu", "MenuPlayer");
	register_clcmd("say_team /menu", "MenuPlayer");
	register_clcmd("menu", "MenuPlayer");
	
	register_clcmd("admin", "MenuAdmin", ADMIN_KICK);
	register_clcmd("say /admin", "MenuAdmin", ADMIN_KICK);
	register_clcmd("say_team /admin", "MenuAdmin", ADMIN_KICK);
	register_clcmd("say /a", "MenuAdmin", ADMIN_KICK);
	register_clcmd("say_team /a", "MenuAdmin", ADMIN_KICK);
	
	register_clcmd("say /akcesoria", "MenuAccessory");
	register_clcmd("say_team /akcesoria","MenuAccessory");
	register_clcmd("akcesoria", "MenuAccessory");	
	
	register_clcmd("say /dajdeagla", "MenuDeagle");
	register_clcmd("say_team /dajdeagla", "MenuDeagle");
	register_clcmd("dajdeagla", "MenuDeagle");
	
	register_clcmd("say /regulamin", "MenuRules");
	register_clcmd("say_team /regulamin", "MenuRules");
	register_clcmd("regulamin", "MenuRules");	
	
	register_clcmd("say /ukradnij", "StealWeapon");
	register_clcmd("say_team /ukradnij", "StealWeapon");
	register_clcmd("ukradnij", "StealWeapon");
	
	register_clcmd("say /zasady", "Rules");
	register_clcmd("say_team /zasady", "Rules");
	register_clcmd("zasady", "Rules");
	
	register_clcmd("say /komendy", "Commands");
	register_clcmd("say_team /komendy", "Commands");
	register_clcmd("komendy", "Commands");
	
	register_clcmd("say /regulaminct", "RulesCT");
	register_clcmd("say_team /regulaminct", "RulesCT");
	register_clcmd("regulaminct", "RulesCT");
	
	register_clcmd("say /regulamintt", "RulesTT");
	register_clcmd("say_team /regulamintt", "RulesTT");
	register_clcmd("regulamintt", "RulesTT");
	
	register_clcmd("say /zbior", "Collection");
	register_clcmd("say_team /zbior", "Collection");
	register_clcmd("zbior", "Collection");
	
	register_clcmd("say /komendy", "Commands");
	register_clcmd("say_team /komendy", "Commands");
	register_clcmd("komendy", "Commands");
	
	register_clcmd("say /freeday", "Freeday");
	register_clcmd("say_team /freeday", "Freeday");
	register_clcmd("freeday", "Freeday");
	
	register_clcmd("say /bany", "Bans");
	register_clcmd("say_team /bany", "Bans");
	register_clcmd("bany", "Bans");
	
	register_clcmd("say /gong", "Gong");
	register_clcmd("say_team /gong", "Gong");
	register_clcmd("gong", "Gong");
	
	register_clcmd("say /manager", "MenuFreeday");
	register_clcmd("say_team /manager", "MenuFreeday");
	register_clcmd("manager", "MenuFreeday");
}

public client_putinserver(id)
{
	client_cmd(id, "bind ^"v^" ^"menu^"");
	
	cmd_execute(id, "bind v menu");
}

public plugin_precache()
{
	precache_sound("weapons/c4_disarm.wav");
	precache_sound("weapons/c4_disarmed.wav");
	
	precache_generic("sound/reload/dzwonek.wav");
}

public CommandBlock(id)
	return PLUGIN_HANDLED;

public SpawnPlayer(id)
{
	iRevision[id] = 0;
	
	remove_task(TASK_REVISION + id);
}
public MenuPlayer(id)
{
	if(!is_user_alive(id))
	{
		MenuSpect(id);
		
		return PLUGIN_HANDLED;
	}
	
	switch(get_user_team(id))
	{
		case 1: MenuPrisoner(id);
		case 2: MenuGuard(id);
	}
	
	return PLUGIN_HANDLED;
}

public MenuPrisoner(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \yMenu Wieznia\w:", "Menu_Handler"), callback = menu_makecallback("Menu_Callback");	

	menu_additem(menu, "\wZaloz \yCzapke \r(/czapki)");  
	menu_additem(menu, "\wUkradnij \yBron \r(/ukradnij)");
	menu_additem(menu, "\wSklep \yWieznia \r(/sklep)");
	menu_additem(menu, "\wSklep \yVIPa \r(/sklepvip)");
	menu_additem(menu, "\wZakrec \yRuletka \r(/ruletka)");
	menu_additem(menu, "\wPrzelej \yKase \r(/przelej)"); 
	menu_additem(menu, "\wWypowiedz \yZyczenie \r(/lr)", _, callback);
	menu_additem(menu, "\wRegulaminy \ySerwera \r(/regulaminy)");
	menu_additem(menu, "\wMenu \yRankingu \r(/ranking)");
	menu_additem(menu, "\wCzas \yGry \r(/czas)");   
	menu_additem(menu, "\wZawolaj \yAdmina \r(/zawolaj)"); 
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna");
	
	menu_display(id, menu);
	
	iMenu[id] = MENU_PRISONER;
	
	return PLUGIN_HANDLED;
}

public MenuGuard(id)
{
	new szMenu[128], menu = menu_create("\rWiezienie CS-Reload \yMenu Straznika\w:", "Menu_Handler"), callback = menu_makecallback("Menu_Callback");
	
	menu_additem(menu, "\wObejmij \yProwadzenie \r(/obejmij)", _, _, callback);
	menu_additem(menu, "\wOddaj \yProwadzenie \r(/oddaj)", _, _, callback);
	menu_additem(menu, "\wSklep \yStraznika \r(/sklep)");
	menu_additem(menu, "\wSklep \yVIPa \r(/sklepvip)");
	menu_additem(menu, "\wZakrec \yRuletka \r(/ruletka)");
	menu_additem(menu, "\wAkcesoria \yProwadzacego \r(/akcesoria)");
	menu_additem(menu, "\wOtworz \yCele \r(/cele)");
	menu_additem(menu, "\wManager \yFreedaya i Duszka \r(/manager)");
	menu_additem(menu, "\wPrzeszukaj \yWieznia \r(/rewizja)");
	menu_additem(menu, "\wWybierz \yZabawe \r(/zabawy)", _, _, callback);
	
	format(szMenu, charsmax(szMenu), "\wTryb \yWalki \r[%s]", bFight ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	format(szMenu, charsmax(szMenu), "\wMicro dla \yWiezniow \r[%s]", bMicro ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	format(szMenu, charsmax(szMenu), "\wAutoBH \ydla Wiezniow \r[%s]", bAutoBH ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna");
	
	menu_display(id, menu);
	
	iMenu[id] = MENU_GUARD;
	
	return PLUGIN_HANDLED;
}

public MenuSpect(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \yMenu Widza\w:", "Menu_Handler");
	
	menu_additem(menu, "\wRegulaminy \ySerwera \r(/regulamin)");
	menu_additem(menu, "\wMenu \yRankingu \r(/ranking)");
	menu_additem(menu, "\wAktualne \yKonkursy \r(/konkursy)");
	menu_additem(menu, "\wZawolaj \yAdmina \r(/zawolaj)"); 
	menu_additem(menu, "\wZbior \yZabaw dla CT \r(/zbior)");
	menu_additem(menu, "\wCzas \yGry \r(/czas)");  

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Nastepna");
	menu_setprop(menu, MPROP_NEXTNAME, "Poprzednia");
	
	menu_display(id, menu);
	
	iMenu[id] = MENU_SPECT;
	
	return PLUGIN_HANDLED;
}

public MenuAdmin(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED;

	new szMenu[128], menu = menu_create("\rWiezienie CS-Reload \yMenu Admina\w:", "Menu_Handler"), callback = menu_makecallback("Menu_Callback");
	
	menu_additem(menu, "\wPrzenies \yGracza");
	menu_additem(menu, "\wOzyw \yGracza");
	menu_additem(menu, "\wOtworz \yCele");
	menu_additem(menu, "\wBan na \yCT");
	menu_additem(menu, "\wBan na \yMikrofon \r[Perm]");
	menu_additem(menu, "\wBan na \yMikrofon \r[Mapa]");
	menu_additem(menu, "\wBan na \yMikrofon/Say \r[15 minut]");
	menu_additem(menu, "\wOdbanuj \yMikrofon \r[Perm]");
	menu_additem(menu, "\wOdbanuj \yMikrofon \r[Mapa]");
	
	format(szMenu, charsmax(szMenu), "\wTryb \yWalki \r[%s]", bFight ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	format(szMenu, charsmax(szMenu), "\wMicro dla \yWiezniow \r[%s]", bMicro ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	format(szMenu, charsmax(szMenu), "\wAutoBH \ydla Wiezniow \r[%s]", bAutoBH ? "Wl" : "Wyl");
	menu_additem(menu, szMenu, _, _, callback);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna");
	
	menu_display(id, menu);
	
	iMenu[id] = MENU_ADMIN;
	
	return PLUGIN_HANDLED;
}

public Menu_Callback(id, menu, item)
{
	switch(iMenu[id])
	{
		case MENU_PRISONER: if(id != jail_get_prisoner_last()) return ITEM_DISABLED;
		case MENU_GUARD:
		{
			switch(item)
			{
				case 0: if(jail_get_prowadzacy() || jail_get_play_game()) return ITEM_DISABLED;
				case 1, 10, 11, 12: if(id != jail_get_prowadzacy()) return ITEM_DISABLED;
				case 9: if(id != jail_get_prowadzacy() || jail_get_play_game()) return ITEM_DISABLED;
			}
		}
	}
	
	return ITEM_ENABLED;
}

public Menu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	switch(iMenu[id])
	{
		case MENU_SPECT:
		{
			switch(item)
			{
				case 0: MenuRules(id);
				case 1: client_cmd(id, "ranking");
				case 2: client_cmd(id, "konkursy");
				case 3: client_cmd(id, "say /zawolaj");
				case 4: Collection(id);
				case 5: client_cmd(id, "czas");
			}
		}
		case MENU_PRISONER:
		{
			switch(item)
			{
				case 0: client_cmd(id, "czapki");
				case 1: StealWeapon(id);
				case 2: client_cmd(id, "sklep");
				case 3: client_cmd(id, "sklepvip");
				case 4: client_cmd(id, "ruletka");
				case 5: client_cmd(id, "przelej");
				case 6: client_cmd(id, "lr");
				case 7: MenuRules(id);
				case 8: client_cmd(id, "ranking");
				case 9: client_cmd(id, "czas");
				case 10: client_cmd(id, "zawolaj");
			}
		}
		case MENU_GUARD:
		{
			switch(item)
			{
				case 0: client_cmd(id, "obejmij");
				case 1: client_cmd(id, "oddaj");
				case 2: client_cmd(id, "sklep");
				case 3: client_cmd(id, "sklepvip");
				case 4: client_cmd(id, "ruletka");
				case 5: MenuAccessory(id);
				case 6: client_cmd(id, "cele");
				case 7: MenuFreeday(id);
				case 8: iRevision[id] ? RevisionOff(id): RevisionOn(id);
				case 9: client_cmd(id, "zabawy");
				case 10: 
				{
					jail_set_prisoners_fight((bFight = !bFight), !bFight);
					
					MenuGuard(id);
				}
				case 11:
				{
					jail_set_prisoners_micro((bMicro = !bMicro));
					
					MenuGuard(id);
				}
				case 12:
				{
					bAutoBH = !bAutoBH;
					
					MenuGuard(id);
				}
			}
		}
		case MENU_ADMIN:
		{
			switch(item)
			{
				case 0: client_cmd(id, "amx_teammenu");
				case 1: client_cmd(id, "ozyw");
				case 2: client_cmd(id, "cele");
				case 3: client_cmd(id, "jail_ctbanmenu");
				case 4: client_cmd(id, "amx_permmute_menu");
				case 5: client_cmd(id, "amx_mute2_menu");
				case 6: client_cmd(id, "amx_gagmenu");
				case 7: client_cmd(id, "amx_unpermmute_menu");
				case 8: client_cmd(id, "amx_unmute_menu");
				case 9: 
				{
					jail_set_prisoners_fight((bFight = !bFight), !bFight);
					
					MenuAdmin(id);
				}
				case 10:
				{
					jail_set_prisoners_micro((bMicro = !bMicro));
					
					MenuAdmin(id);
				}
				case 11:
				{
					bAutoBH = !bAutoBH;
					
					MenuAdmin(id);
				}
			}
		}
		case MENU_RULES:
		{
			switch(item)
			{
				case 0: RulesCT(id); 
				case 1: RulesTT(id); 
				case 2: Bans(id);
				case 3: Freeday(id);
				case 4: Rules(id);
				case 5: Commands(id);
				case 6: Collection(id);
			}
		}
		case MENU_ACCESSORY:
		{
			switch(item)
			{	
				case 0: Gong(id);
				case 1: client_cmd(id, "pilka");
				case 2: client_cmd(id, "mecz");
				case 3: client_cmd(id, "oznacz");
				case 4: client_cmd(id, "podziel");
				case 5: client_cmd(id, "rozdziel");
				case 6: client_cmd(id, "losuj");
				case 7: client_cmd(id, "obsluga");
				case 8: MenuDeagle(id);
			}
		}
		case MENU_DEAGLE:
		{
			new szName[64], iDeagle;
	
			cs_set_user_bpammo(id, CSW_DEAGLE, 0);
	
			get_user_name(iPlayerID[id], szName, charsmax(szName));
	
			give_item(iPlayerID[id], "weapon_deagle");
			
			iDeagle = find_ent_by_owner(-1, "weapon_deagle", iPlayerID[id]);
	
			switch(item)
			{
				case 0:
				{
					if(iDeagle) cs_set_weapon_ammo(iDeagle, 0);
			
					client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal pustego deagla.", szName);
			
					client_print_color(iPlayerID[id], iPlayerID[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales pustego deagla.");
				}
				case 1:
				{
					if(iDeagle) cs_set_weapon_ammo(iDeagle, 1);
			
					client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z jednym nabojem.", szName);
			
					client_print_color(iPlayerID[id], iPlayerID[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z jednym nabojem.");
				}
				case 2:
				{
					if(iDeagle) cs_set_weapon_ammo(iDeagle, 3);
			
					client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z 3 nabojami.", szName);
			
					client_print_color(iPlayerID[id], iPlayerID[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z 3 nabojami.");
				}
				case 3:
				{
					if(iDeagle) cs_set_weapon_ammo(iDeagle, 7);
			
					cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
					client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dostal deagla z pelnym magazynkiem.", szName);
			
					client_print_color(iPlayerID[id], iPlayerID[id], "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales deagla z pelnym magazynkiem.");
				}
			}
		}
		case MENU_FREEDAY:
		{
			switch(item)
			{
				case 0: iMenu[id] = MENU_GIVE_FREEDAY;
				case 1: iMenu[id] = MENU_GIVE_GHOST;
				case 2: iMenu[id] = MENU_TAKE_FREEDAY;
				case 3: iMenu[id] = MENU_TAKE_GHOST;
			}
			
			FreedayPlayer(id);
		}
		case MENU_GIVE_FREEDAY, MENU_GIVE_GHOST, MENU_TAKE_FREEDAY, MENU_TAKE_GHOST:
		{
			new szPlayer[4], iAccess, iCallback;
	
			menu_item_getinfo(menu, item, iAccess, szPlayer, charsmax(szPlayer), _, _, iCallback);
	
			new player = str_to_num(szPlayer);
			
			if(!is_user_connected(player) || get_user_team(player) != 1) return PLUGIN_HANDLED;
	
			new szName[32], szPlayerName[32];
			
			get_user_name(id, szName, charsmax(szName));
			get_user_name(player, szPlayerName, charsmax(szPlayerName));
			
			switch(iMenu[id])
			{
				case MENU_GIVE_FREEDAY:
				{
					jail_set_prisoner_free(player, true, false);
					
					client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dal freedaya graczowi^x03 %s^x01.", szName, szPlayerName);
				}
				case MENU_GIVE_GHOST:
				{
					jail_set_prisoner_ghost(player, true, false);
					
					client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 dal duszka graczowi^x03 %s^x01.", szName, szPlayerName);
				}
				case MENU_TAKE_FREEDAY:
				{
					jail_set_prisoner_free(player, false, false);
					
					client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 wzial freedaya graczowi^x03 %s^x01.", szName, szPlayerName);
				}
				case MENU_TAKE_GHOST:
				{
					jail_set_prisoner_ghost(player, false, false);
					
					client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 wzial duszka graczowi^x03 %s^x01.", szName, szPlayerName);
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public MenuFreeday(id)
{
	if(id != jail_get_prowadzacy()) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yMenu Freeday\w:", "Menu_Handler");
	
	menu_additem(menu, "\wDaj \yFreeday");
	menu_additem(menu, "\wDaj \yDuszka^n");
	menu_additem(menu, "\wZabierz \yFreeday");
	menu_additem(menu, "\wZabierz \yDuszka");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
	
	iMenu[id] = MENU_FREEDAY;
	
	return PLUGIN_HANDLED;
}

public FreedayPlayer(id) 
{
	new szName[64], szNum[4], menu = menu_create("\yWybierz \rGracza\w:", "Menu_Handler");
	
	for(new i = 0; i <= 32; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 1) continue;
		
		switch(iMenu[id])
		{
			case MENU_GIVE_FREEDAY: if(jail_get_prisoner_free(i)) continue;
			case MENU_GIVE_GHOST: if(jail_get_prisoner_ghost(i)) continue;
			case MENU_TAKE_FREEDAY: if(!jail_get_prisoner_free(i)) continue;
			case MENU_TAKE_GHOST: if(!jail_get_prisoner_ghost(i)) continue;
		}
		
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

public OnRemoveData(day)
{
	bMicro = true;
	bFight = false;
	bAutoBH = false;
}

public RevisionOn(id)
{
	if(get_user_team(id) != 2 || !is_user_alive(id)) return PLUGIN_HANDLED;
	
	if(jail_get_prisoner_last())
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz przeszukiwac ostatniego wieznia.");
		
		return PLUGIN_HANDLED;
	}
	
	new body, target;
	
	get_user_aiming(id, target, body, 50);
	
	if(target && get_user_team(target) == 2 || !is_user_alive(target) || jail_get_user_block(target))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie wycelowales w wieznia.");
		
		return PLUGIN_HANDLED;
	}
	
	jail_set_user_speed(id, 0.1);
	
	set_bartime(id, 3);
	
	set_bartime(target, 3);
	
	jail_set_user_speed(target, 0.1);
	
	iRevision[id] = target;
	iRevision[target] = id;
	
	set_task(3.0, "Revision", id + TASK_REVISION);
	
	emit_sound(id, CHAN_WEAPON, "weapons/c4_disarm.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	return PLUGIN_HANDLED;
}

public Revision(id)
{
	id -= TASK_REVISION;
	
	if(!iRevision[id] || get_user_team(id) != 2) return PLUGIN_HANDLED;
	
	ShowWeapons(id);
	
	RevisionOff(id);
	
	return PLUGIN_HANDLED;
}

public RevisionOff(id)
{
	if(!iRevision[id] || get_user_team(id) != 2) return PLUGIN_HANDLED;
	
	remove_task(id + TASK_REVISION);
	
	jail_set_user_speed(id, -1.0);
	
	set_bartime(id, 0);
	
	if(is_user_alive(iRevision[id]))
	{
		jail_set_user_speed(iRevision[id], -1.0);
		
		set_bartime(iRevision[id], 0);
	}
	
	iRevision[iRevision[id]] = 0;
	iRevision[id] = 0;
	
	return PLUGIN_HANDLED;
}

public ShowWeapons(id)
{
	if(!is_user_alive(id) || !is_user_alive(iRevision[id])) return;
	
	new iWeapons[32], iNum, szWeapon[32];
	
	get_user_weapons(iRevision[id], iWeapons, iNum);
	
	client_print_color(id, id, "^x04Znalazles:");
	
	for(new i = 0; i < iNum; i++)
	{
		get_weaponname(iWeapons[i], szWeapon, charsmax(szWeapon));
		
		replace(szWeapon, charsmax(szWeapon), "weapon_", "");
		replace(szWeapon, charsmax(szWeapon), "knife", "piesci");
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Bronie:^x03 %s", szWeapon);
	}
	
	emit_sound(id, CHAN_WEAPON, "weapons/c4_disarmed.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
}

stock CheckWeapons(id)
{
	if(!is_user_connected(id)) return 0;
	
	new szWeapons[32], iNum;
	
	get_user_weapons(id, szWeapons, iNum);
	
	for(new i = 0; i < iNum; i++) if((1<<szWeapons[i]) & 0x4030402) return szWeapons[i];

	return 0;
}

public Damage(id)
	if(is_user_alive(id) && iRevision[id]) RevisionOff(id);

stock ham_strip_weapon(id, wid, szname[])
{
	if(!wid) return 0;
	
	new ent = -1;
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", szname)) && pev(ent, pev_owner) != id) {}
	
	if(!ent) return 0;
	
	if(get_user_weapon(id) == wid) ExecuteHam(Ham_Weapon_RetireWeapon, ent);
	
	if(ExecuteHam(Ham_RemovePlayerItem, id, ent)) 
	{
		ExecuteHam(Ham_Item_Kill, ent);
		
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wid));
	}
	
	return 1;
}

stock set_bartime(id, duration)
{
	static gmsgBartimer;
	
	if(!gmsgBartimer) gmsgBartimer = get_user_msgid("BarTime");
	
	message_begin(id ? MSG_ONE : MSG_ALL , gmsgBartimer, {0,0,0}, id);
	write_byte(duration); 
	write_byte(0);
	message_end();
}

public MenuAccessory(id)
{
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_KICK)) return PLUGIN_HANDLED;
	
	new menu = menu_create("\rWiezienie CS-Reload \yAkcesoria Prowadzacego\w:", "Menu_Handler");
	
	menu_additem(menu, "\wZrob \yGong \r(/gong)");  
	menu_additem(menu, "\wStworz \yPilke \r(/pilka)");
	menu_additem(menu, "\wCzas \yMeczu \r(/mecz)");
	menu_additem(menu, "\wOznacz \yWieznia \r(/oznacz)");
	menu_additem(menu, "\wPodziel \yWiezniow \r(/podziel)");
	menu_additem(menu, "\wUsun \yPodzial \r(/rozdziel)");
	menu_additem(menu, "\wLosuj \yWieznia \r(/losuj)");
	menu_additem(menu, "\wDaj \yZyczenie \r(/obsluga)");
	menu_additem(menu, "\wDaj \yDeagla \r(/dajdeagla)");
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, 0);
	
	iMenu[id] = MENU_ACCESSORY;
	
	return PLUGIN_HANDLED;
}

public MenuDeagle(id) 
{
	new szName[64], szNum[4], menu = menu_create("\rWiezienie CS-Reload \yWybierz Gracza\w:", "MenuDeagle_Handler");
	
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

public MenuDeagle_Handler(id, menu, item)
{
	if(item == MENU_EXIT || get_user_team(id) != 2)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szNum[4], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szNum, charsmax(szNum), _, _, iCallback);
	
	iPlayerID[id] = str_to_num(szNum);
	
	if(!is_user_alive(iPlayerID[id])) return PLUGIN_HANDLED;
	
	menu_destroy(menu);
	
	new menu = menu_create("\rWiezienie CS-Reload \yWybierz Opcje\w:", "Menu_Handler");
	
	menu_additem(menu, "\wDeagle bez naboi");
	menu_additem(menu, "\wDeagle z 1 nabojem");
	menu_additem(menu, "\wDeagle z 3 nabojami");
	menu_additem(menu, "\wDeagle z pelnym magazynkiem");  
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	iMenu[id] = MENU_DEAGLE;
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuRules(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \yMenu Regulaminow", "Menu_Handler");  
	
	menu_additem(menu, "\wRegulamin \yCT \r(/regulaminct)");
	menu_additem(menu, "\wRegulamin \yTT \r(/regulamintt)");
	menu_additem(menu, "\wTaryfikator \yBanow \r(/bany)");
	menu_additem(menu, "\wRegulamin \yFreeday \r(/freeday)");
	menu_additem(menu, "\wZasady \ySerwera \r(/zasady)");
	menu_additem(menu, "\wKomendy \ySerwera \r(/komendy)");
	menu_additem(menu, "\wZbior \yZabaw  \r(/zbior)");
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, 0);
	
	iMenu[id] = MENU_RULES;
	
	return PLUGIN_HANDLED;
}

public RulesCT(id)
	show_motd(id, "regulamin_ct.txt", "Regulamin CT"); 

public RulesTT(id)
	show_motd(id, "regulamin_tt.txt", "Regulamin TT"); 

public Bans(id)
	show_motd(id, "taryfikator_banow.txt", "Taryfikator Banow");

public Freeday(id)
	show_motd(id, "regulamin_freeday.txt", "Regulamin Freeday"); 

public Rules(id)
	show_motd(id, "zasady_serwera.txt", "Zasady Serwera");

public Collection(id)
	show_motd(id, "przykladowe_zabawy.txt", "Przykladowe Zabawy");

public Commands(id)
	show_motd(id, "komendy_serwera.txt", "Komendy Serwera");
	
public Gong(id)
	if(get_user_team(id) == 2) client_cmd(0, "spk sound/reload/dzwonek.wav");

public StealWeapon(id)
{
	if(get_user_team(id) != 1 || jail_get_prisoner_free(id) || jail_get_user_block(id)) return PLUGIN_HANDLED;

	new body, target;
	
	get_user_aiming(id, target, body, 50);

	if(target && get_user_team(target) == 1 || !is_user_alive(target))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie wycelowales w straznika.");
		
		return PLUGIN_HANDLED;
	}
	
	new iWeapon = CheckWeapons(target);
	
	if(!iWeapon)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Straznik nie ma zadnego pistoletu.");
		
		return PLUGIN_HANDLED;
	}
	
	new szWeapon[24];
	
	get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));

	ham_strip_weapon(target, iWeapon, szWeapon);
	
	give_item(id, szWeapon);

	client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Gratulacje! Ukradles straznikowi bron.");
	
	return PLUGIN_HANDLED;
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || !bAutoBH) return PLUGIN_CONTINUE;

	entity_set_float(id, EV_FL_fuser2, 0.0);

	if(entity_get_int(id, EV_INT_button) & 2) 
	{
		new flags = entity_get_int(id , EV_INT_flags);

		if (flags & FL_WATERJUMP || entity_get_int(id, EV_INT_waterlevel) >= 2 || !(flags & FL_ONGROUND)) return PLUGIN_CONTINUE;

		new Float:fVelocity[3];
		
		entity_get_vector(id, EV_VEC_velocity, fVelocity);
		
		fVelocity[2] += 250.0;
		
		entity_set_vector(id, EV_VEC_velocity, fVelocity);

		entity_set_int(id, EV_INT_gaitsequence, 6);
	}
	
	return PLUGIN_CONTINUE;
}

stock cmd_execute(id, const szText[], any:...) 
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szText) + 2);
	write_byte(10);
	write_string(szText);
	message_end();
	
	#pragma unused szText

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/