#include <amxmodx>  
#include <hamsandwich> 
#include <cstrike> 
#include <fun> 
#include <fakemeta>
#include <engine>
#include <jailbreak>

#define PLUGIN "JailBreak: Shop" 
#define VERSION "1.0" 
#define AUTHOR "O'Zone" 

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

#define TASK_GODMODE 8431

new iJumps[33], bool:bBlocked, iJumper, iNoRecoil, iSpeed, iPunch, iGoldDeagle, iGoldAK47, iGoldM4A1, iUsed;

new cDmgDeagle, cDmgAK47, cDmgM4A1;

new const gDeagle[][] =  { "models/reload_gold/v_deagle.mdl", "models/reload_gold/p_deagle.mdl" };
new const gAK47[][] =  { "models/reload_gold/v_ak47.mdl", "models/reload_gold/p_ak47.mdl" };
new const gM4A1[][] =  { "models/reload_gold/v_m4a1.mdl", "models/reload_gold/p_m4a1.mdl" };

native cs_set_player_model(id, new_model[]);

public plugin_init() 
{ 
	register_plugin(PLUGIN, VERSION, AUTHOR); 
	
	register_clcmd("say /sklep", "JBShop"); 
	register_clcmd("say_team /sklep", "JBShop"); 
	register_clcmd("sklep", "JBShop"); 
	
	register_clcmd("say /sklepvip", "JBVIPShop");
	register_clcmd("say_team /sklepvip", "JBVIPShop");
	register_clcmd("sklepvip", "JBVIPShop");
	
	cDmgDeagle = register_cvar("jail_damage_deagle", "1.1");
	cDmgAK47 = register_cvar("jail_damage_ak47", "1.1");
	cDmgM4A1 = register_cvar("jail_damage_m4a1", "1.1");
	
	register_logevent("RoundStart", 2, "1=Round_Start");
	
	register_forward(FM_PlayerPreThink, "PreThink");
	register_forward(FM_UpdateClientData, "UpdateClientData", 1);
	register_forward(FM_CmdStart, "CmdStart");

	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "M4A1Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "AK47Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_deagle", "DeagleModel", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
} 

public plugin_precache()
{
	precache_model(gDeagle[0]);
	precache_model(gAK47[0]);
	precache_model(gM4A1[0]);

	precache_model(gDeagle[1]);
	precache_model(gAK47[1]);
	precache_model(gM4A1[1]);
}

public JBShop(id)
{
	if(!is_user_connected(id) || bBlocked) return PLUGIN_HANDLED;

	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Tylko zywi moga kupowac!"); 
		
		return PLUGIN_HANDLED; 
	} 
	
	if(jail_get_days() == NIEDZIELA || jail_get_days() == SOBOTA)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Sklep jest zamkniety w sobote i niedziele!"); 
		
		return PLUGIN_HANDLED; 
	}
	
	if(jail_get_play_game())
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz kupowac w trakcie trwania zabawy!"); 
		
		return PLUGIN_HANDLED; 
	}
	
	switch(get_user_team(id))
	{
		case 1: ShopTT(id);
		case 2: ShopCT(id);
	}
	
	return PLUGIN_HANDLED;
}

public ShopTT(id)
{ 
	new menu = menu_create("\rWiezienie CS-Reload \ySklep Wieznia", "ShopTT_Handler"); 
	
	menu_additem(menu, "\yPalestynskie Cichobiegi \w[Ciche Chodzenia] \r[3000$]", "3000"); 
	menu_additem(menu, "\yKapcie Cygana \w[Wieksza Predkosc] \r[11000$]", "11000");
	menu_additem(menu, "\yNieziemska Moc \w[Mniejsza Grawitacja] \r[9000$]", "9000");    
	menu_additem(menu, "\yWyskokowe Klapki \w[Podwojny Skok] \r[8000$]", "8000");  
	menu_additem(menu, "\yPower Punch \w[Podwojne Obrazenia] \r[12000$]", "12000");
	menu_additem(menu, "\yDlon Boga \w[+50 HP] \r[5000$]", "5000");

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL); 
	
	menu_display(id, menu, 0); 
	
	return PLUGIN_HANDLED;
}

public ShopTT_Handler(id, menu, item)
{ 
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		
		return PLUGIN_HANDLED; 
	} 
	
	new szCost[6], iCost, iAccess, iCallback; 
	
	menu_item_getinfo(menu, item, iAccess, szCost, charsmax(szCost), _, _, iCallback); 
	
	iCost = str_to_num(szCost);	
	
	if(cs_get_user_money(id) < iCost)
	{  
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie masz wystarczajaco duzo hajsu!"); 
		
		return PLUGIN_HANDLED; 
	} 
	else cs_set_user_money(id, cs_get_user_money(id) - iCost, 0); 
	
	switch(item) 
	{ 
		case 0:
		{ 
			set_user_footsteps(id, 1);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Palestynskie Cichobiegi^x01, dzieki ktorym nie slychac twoich krokow.");
		} 
		case 1:
		{ 
			Set(id, iSpeed);
			
			jail_set_user_speed(id, 300.0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Kapcie Cygana^x01, dzieki ktorym mozesz szybciej biegac."); 
		} 
		case 2: 
		{ 
			set_user_gravity(id, 0.5); 
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Nieziemska Moc^x01, dzieki ktorym mozesz wyzej skakac."); 
		} 
		case 3:
		{ 
			Set(id, iJumper);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Wyskokowe Klapki^x01, dziêki ktoremu masz podwojny skok.");
		} 
		case 4:
		{ 
			Set(id, iPunch);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Power Punch^x01, zadajesz 2x wieksze obrazenia."); 
		} 
		case 5:
		{ 
			if(jail_get_play_game())
			{ 
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz tego kupic w trakcie zabawy!"); 
				
				return PLUGIN_HANDLED; 
			} 
			
			set_user_health(id, get_user_health(id) + 50);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Dlon Boga^x01, masz +50 HP."); 
		}
	}
	return PLUGIN_HANDLED; 
}

public ShopCT(id)
{ 	
	new menu = menu_create("\rWiezienie CS-Reload \ySklep Straznika", "ShopCT_Handler");
	
	menu_additem(menu, "\yPalestynskie Cichobiegi \w[Ciche Chodzenia] \r[2000$]", "2000"); 
	menu_additem(menu, "\yKapcie Cygana \w[Wieksza Predkosc] \r[9000$]", "9000");
	menu_additem(menu, "\yNieziemska Moc \w[Mniejsza Grawitacja] \r[7000$]", "7000");    
	menu_additem(menu, "\yWyskokowe Klapki \w[Podwojny Skok] \r[8000$]", "8000");  
	menu_additem(menu, "\yRambo \w[Brak rozrzutu Broni] \r[13000$]", "13000");
	menu_additem(menu, "\yBog \w[Niesmiertelnosc na 20 sekund (Raz na mape)] \r[15000$]", "15000"); 
	menu_additem(menu, "\yZly Blizniak \w[Przebranie Wieznia] \r[16000$]", "16000"); 
	menu_additem(menu, "\yDlon Boga \w[+50 HP] \r[5000$]", "5000");
	menu_additem(menu, "\yZloty Deagle \w[Wyglad i wiekszy DMG] \r[13000$]", "13000");
	menu_additem(menu, "\yZlote M4A1 \w[Wyglad i wiekszy DMG] \r[15000$]", "15000");
	menu_additem(menu, "\yZlote AK47 \w[Wyglad i wiekszy DMG] \r[15000$]", "15000");

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL); 
	
	menu_display(id, menu, 0); 
	
	return PLUGIN_HANDLED;
}

public ShopCT_Handler(id, menu, item)
{ 
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		
		return PLUGIN_HANDLED; 
	} 
	
	new szCost[6], iCost, iAccess, iCallback; 
	
	menu_item_getinfo(menu, item, iAccess, szCost, charsmax(szCost), _, _, iCallback); 
	
	iCost = str_to_num(szCost);	
	
	if(cs_get_user_money(id) < iCost)
	{  
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie masz wystarczajaco duzo hajsu!"); 
		
		return PLUGIN_HANDLED; 
	} 
	else cs_set_user_money(id, cs_get_user_money(id) - iCost, 0); 
	
	switch(item) 
	{ 
		case 0:
		{ 
			set_user_footsteps(id, 1);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Palestynskie Cichobiegi^x01, dzieki ktorym nie slychac twoich krokow.");
		} 
		case 1:
		{ 
			Set(id, iSpeed);
			
			jail_set_user_speed(id, 300.0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Kapcie Cygana^x01, dzieki ktorym mozesz szybciej biegac."); 
		} 
		case 2: 
		{ 
			set_user_gravity(id, 0.5); 
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Nieziemska Moc^x01, dzieki ktorym mozesz wyzej skakac."); 
		} 
		case 3:
		{ 
			Set(id, iJumper);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Wyskokowe Klapki^x01, Dziêki ktoremu masz podwojny skok.");
		} 
		case 4:
		{ 
			Set(id, iNoRecoil);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 No Recoil^x01, przez to nie masz rozrzutu w broni."); 
		} 
		case 5:
		{
			if(Get(id, iUsed))
			{
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Niestety, ale wykorzystales ta umiejetnosc, nastepny raz mozesz uzyc w nastepnej mapie!");
				
				return PLUGIN_HANDLED;
			}
			
			Set(id, iUsed);
			
			set_user_godmode(id, 1);
			
			set_task(20.0, "god_off", id + TASK_GODMODE);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Niesmiertelnosc^x01 na 20 sekund.");
		}
		case 6:
		{ 
			cs_set_player_model(id, "reload_wiezien");
			
			set_pev(id, pev_body, 0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Przebranie Wieznia^x01."); 
		} 
		case 7:
		{ 
			if(jail_get_play_game())
			{ 
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz tego kupic w trakcie zabawy!"); 
				return PLUGIN_HANDLED; 
			} 
			
			set_user_health(id, get_user_health(id) + 50);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Dlon Boga^x01, masz +50 HP."); 
		}
		case 8:
		{ 
			Set(id, iGoldDeagle);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Zlotego Deagle'a^x01."); 
		} 
		case 9:
		{ 
			Set(id, iGoldM4A1);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Zlote M4A1^x01."); 
		} 
		case 10:
		{ 
			Set(id, iGoldAK47);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Zlote AK47^x01.");  
		} 
	}
	return PLUGIN_HANDLED; 
}

public JBVIPShop(id)
{
	if(!is_user_connected(id) || bBlocked) return PLUGIN_HANDLED;

	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Tylko zywi moga kupowac!"); 
		
		return PLUGIN_HANDLED; 
	} 
	
	if(!(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Tylko VIPy maja dostep do tego sklepu!"); 
		
		return PLUGIN_HANDLED; 
	}
	
	if(jail_get_play_game())
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz kupowac w trakcie trwania zabawy!"); 
		
		return PLUGIN_HANDLED; 
	}

	new menu = menu_create("\rWiezienie CS-Reload \ySklep VIP", "JBVIPShop_Handler"); 
	
	menu_additem(menu, "\yPalestynskie Cichobiegi \w[Ciche Chodzenia] \r[2000$]", "2000"); 
	menu_additem(menu, "\yKapcie Cygana \w[Wieksza Predkosc] \r[9000$]", "9000");
	menu_additem(menu, "\yNieziemska Moc \w[Mniejsza Grawitacja] \r[7000$]", "7000");    
	menu_additem(menu, "\yZly Blizniak \w[Przebranie Straznika] \r[10000$]", "10000");  
	menu_additem(menu, "\yMagnetyczne Radary \w[Usuniecie z Poszukiwanych] \r[9000$]", "9000");
	menu_additem(menu, "\yPomoc Dymna \w[Smoke] \r[13000$]", "13000");

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL); 
	
	menu_display(id, menu, 0); 
	
	return PLUGIN_HANDLED;
}

public JBVIPShop_Handler(id, menu, item)
{ 
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		
		return PLUGIN_HANDLED; 
	} 
	
	new szCost[6], iCost, iAccess, iCallback; 
	
	menu_item_getinfo(menu, item, iAccess, szCost, charsmax(szCost), _, _, iCallback); 
	
	iCost = str_to_num(szCost);	
	
	if(cs_get_user_money(id) < iCost)
	{  
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie masz wystarczajaco duzo hajsu."); 
		
		return PLUGIN_HANDLED; 
	} 
	else cs_set_user_money(id, cs_get_user_money(id) - iCost, 0); 
	
	switch(item) 
	{ 
		case 0:
		{ 
			set_user_footsteps(id, 1);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Palestynskie Cichobiegi^x01, dzieki ktorym nie slychac twoich krokow.");
		} 
		case 1:
		{ 
			Set(id, iSpeed);
			
			jail_set_user_speed(id, 300.0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Kapcie Cygana^x01, dzieki ktorym mozesz szybciej biegac."); 
		} 
		case 2: 
		{ 
			set_user_gravity(id, 0.5); 
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Nieziemska Moc^x01, dzieki ktorym mozesz wyzej skakac."); 
		} 
		case 3:
		{ 
			cs_set_player_model(id, "reload_klawisz");
			
			set_pev(id, pev_body, 0);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Przebranie Straznika^x01.");
		} 
		case 4:
		{ 
			if(!jail_get_poszukiwany(id))
			{ 
				client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Musisz byc poszukiwany!"); 
				
				return PLUGIN_HANDLED; 
			}
			
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 30);
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Usunieto cie z^x03 Poszukiwanych^x01."); 
		} 
		case 5:
		{ 
			give_item(id, "weapon_smokegrenade");
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Kupiles^x03 Pomoc Dymna - Smoke^x01."); 
		}
	}
	
	return PLUGIN_HANDLED; 
}

public god_off(id)
{ 
	id -= TASK_GODMODE;
	
	if(is_user_alive(id)) set_user_godmode(id);	
}

public OnLastPrisonerWishTaken(id)
{
	bBlocked = true;
	
	Rem(id, iPunch);
}

public client_disconnected(id)
{
	Rem(id, iUsed);
	Rem(id, iSpeed);
	Rem(id, iJumper);
	Rem(id, iPunch);
	Rem(id, iNoRecoil);
	Rem(id, iGoldDeagle);
	Rem(id, iGoldAK47);
	Rem(id, iGoldM4A1);
}

public RoundStart() 
{
	bBlocked = false;
	
	for(new id = 1; id < 33; id++)
	{
		if(Get(id, iSpeed)) jail_set_user_speed(id, -1.0);
		
		Rem(id, iSpeed);
		Rem(id, iJumper);
		Rem(id, iPunch);
		Rem(id, iNoRecoil);
	}
}

public PreThink(id)
	if(Get(id, iNoRecoil)) set_pev(id, pev_punchangle, {0.0,0.0,0.0});

public UpdateClientData(id, sw, cd_handle)
	if(Get(id, iNoRecoil)) set_cd(cd_handle, CD_PunchAngle, {0.0,0.0,0.0});   

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id) || !Get(id, iJumper)) return FMRES_IGNORED;

	new flags = pev(id, pev_flags);

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && iJumps[id])
	{
		iJumps[id]--;
		
		new Float:velocity[3];
		
		pev(id, pev_velocity,velocity);
		
		velocity[2] = random_float(265.0,285.0);
		
		set_pev(id, pev_velocity,velocity);
	}
	else if(flags & FL_ONGROUND) iJumps[id] = 2;

	return FMRES_IGNORED;
}

public PlayerSpawn(id)
	if(is_user_alive(id) && (!get_user_flags(id) & ADMIN_LEVEL_H)) set_user_footsteps(id, 0);

public M4A1Model(weapon)
{
	static id;
	
	id = pev(weapon, pev_owner);
	
	if(get_user_team(id) == 2 && Get(id, iGoldM4A1))
	{
		set_pev(id, pev_viewmodel2, gM4A1[0]);
		set_pev(id, pev_weaponmodel2, gM4A1[1]);
	}
}

public AK47Model(weapon)
{
	static id;
	
	id = pev(weapon, pev_owner);
	
	if(get_user_team(id) == 2 && Get(id, iGoldAK47))
	{
		set_pev(id, pev_viewmodel2, gAK47[0]);
		set_pev(id, pev_weaponmodel2, gAK47[1]);
	}
}

public DeagleModel(weapon)
{
	static id;
	
	id = pev(weapon, pev_owner);
	
	if(get_user_team(id) == 2 && Get(id, iGoldDeagle))
	{
		set_pev(id, pev_viewmodel2, gDeagle[0]);
		set_pev(id, pev_weaponmodel2, gDeagle[1]);
	}
}

public TakeDamage(victim, entity, attacker, Float:damage, damage_bits)
{
	if(!is_user_connected(attacker) || !is_user_connected(victim)) return HAM_IGNORED;

	if(Get(attacker, iPunch))
	{
		SetHamParamFloat(4, damage * 2.0);
		
		return HAM_HANDLED;
	}

	switch(get_user_weapon(attacker))
	{
		case CSW_DEAGLE:
		{
			if(get_pcvar_float(cDmgDeagle) && Get(attacker, iGoldDeagle))
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cDmgDeagle));
				return HAM_HANDLED;
			}
		}
		case CSW_AK47:
		{
			if(get_pcvar_float(cDmgAK47) && Get(attacker, iGoldAK47))
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cDmgAK47));
				return HAM_HANDLED;
			}
		}
		case CSW_M4A1:
		{
			if(get_pcvar_float(cDmgM4A1) && Get(attacker, iGoldM4A1))
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cDmgM4A1));
				return HAM_HANDLED;
			}
		}
	}
	return HAM_IGNORED;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/