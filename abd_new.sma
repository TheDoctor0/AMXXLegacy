#include <amxmodx>
#include <fakemeta>
#include <nvault>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "1.3"
#define AUTHOR "O'Zone"

#define MAX_PLAYERS	32

#define TASK_RECEIVED 7935
#define TASK_TAKEN 8935

new const Float:fCoords[][] = 
{
	{0.40},
	{0.45},
	{0.50},
	{0.55},
	{0.60},
	{0.65},
	{0.70},
	{0.75}
};

enum _:ePlayer { NAME[32], POS_TAKEN, POS_RECEIVED, SHOTS, TAKEN, RECEIVED, TYPE };

new gPlayer[MAX_PLAYERS + 1][ePlayer], pCvarEnabled, hHudSync, vHUD;

new const sHUDCommands[][] = { "say /damage", "say_team /damage", "say /obrazenia", "say_team /obrazenia", "say /abd", "say_team /abd" };

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	pCvarEnabled = register_cvar("advanced_bullet_damage", "1");

	register_event("Damage", "on_damage", "b", "2!=0");
	
	for(new i; i < sizeof sHUDCommands; i++) register_clcmd(sHUDCommands[i], "change_hud");
	
	vHUD = nvault_open("abd_new");
	
	if(vHUD == INVALID_HANDLE) set_fail_state("[ABD] Nie mozna otworzyc pliku abd_new.vault");
	
	hHudSync = CreateHudSyncObj();
}

public client_connect(id)
{
	get_user_name(id, gPlayer[id][NAME], charsmax(gPlayer[]));
	
	gPlayer[id][POS_RECEIVED] = 0;
	gPlayer[id][POS_TAKEN] = 0;
	gPlayer[id][SHOTS] = 5;
	gPlayer[id][TYPE] = is_user_hltv(id) ? false : true;
	gPlayer[id][RECEIVED] = true;
	gPlayer[id][TAKEN] = true;
	
	load_hud(id);
	
	remove_task(id + TASK_RECEIVED);
	remove_task(id + TASK_TAKEN);
}

public change_hud(id)
{
	new szMenu[128], menu = menu_create("\yKonfiguracja: \rWyswietlanie Obrazen", "change_hud_handle");
	
	format(szMenu, charsmax(szMenu), "\wSposob \yWyswietlania: \r%s", gPlayer[id][TYPE] ? "DHUD" : "HUD");
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wZadawane \yObrazenia: \r%s", gPlayer[id][TAKEN] ? "Tak" : "Nie");
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wOtrzymywane \yObrazenia: \r%s", gPlayer[id][RECEIVED] ? "Tak" : "Nie");
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\wWyswietlane \yTrafienia: \r%i^n", gPlayer[id][SHOTS]);
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\yDomyslne \rUstawienia");
	menu_additem(menu, szMenu);
	
	format(szMenu, charsmax(szMenu), "\yStara \rWersja");
	menu_additem(menu, szMenu);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz", 0);
	
	menu_display(id, menu);
}

public change_hud_handle(id, menu, item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0: gPlayer[id][TYPE] = !gPlayer[id][TYPE];
		case 1: gPlayer[id][TAKEN] = !gPlayer[id][TAKEN];
		case 2: gPlayer[id][RECEIVED] = !gPlayer[id][RECEIVED];
		case 3: if(++gPlayer[id][SHOTS] > sizeof(fCoords)) gPlayer[id][SHOTS] = 1;
		case 4:
		{
			gPlayer[id][SHOTS] = 5;
			gPlayer[id][TYPE] = true;
			gPlayer[id][RECEIVED] = true;
			gPlayer[id][TAKEN] = true;
		}
		case 5:
		{
			gPlayer[id][SHOTS] = 1;
			gPlayer[id][TYPE] = false;
			gPlayer[id][RECEIVED] = false;
			gPlayer[id][TAKEN] = true;
		}
	}
	
	save_hud(id);
	
	change_hud(id);
	
	return PLUGIN_CONTINUE;
}

public on_damage(id)
{
	if(get_pcvar_num(pCvarEnabled))
	{
		static iAttacker; iAttacker = get_user_attacker(id);
		static iDamage; iDamage = read_data(2);
		
		new iPlayers[32], iNum, iPos, player, attacker, bool:bOld;
		get_players(iPlayers, iNum, "c");
	
		for(new i = 0; i < iNum; i++)
		{
			player = iPlayers[i];
			
			attacker = pev(player, pev_iuser2);
			
			if(player != id && pev(player, pev_iuser2) != id && attacker != iAttacker && player != iAttacker) continue;
			
			bOld = (gPlayer[player][SHOTS] == 1 && !gPlayer[player][RECEIVED]) ? true : false;

			if(is_user_connected(iAttacker) && id != iAttacker && (player == iAttacker || attacker == iAttacker) && gPlayer[player][TAKEN])
			{
				if(gPlayer[player][POS_TAKEN] + 1 >= gPlayer[player][SHOTS]) gPlayer[player][POS_TAKEN] = bOld ? 3 : 0;
			
				iPos = gPlayer[player][POS_TAKEN]++;
				
				remove_task(player + TASK_TAKEN);
				
				set_task(2.5, "reset_pos_taken", player + TASK_TAKEN);
				
				if(gPlayer[player][TYPE])
				{
					set_dhudmessage(0, 100, 200, bOld ? -1.0 : 0.7, fCoords[iPos][0], 0, 0.1, 2.5, 0.02, 0.02);
					show_dhudmessage(player, "%d", iDamage);
				}
				else
				{
					set_hudmessage(0, 100, 200, bOld ? -1.0 : 0.7, Float:fCoords[iPos][0], 0, 0.1, 2.5, 0.02, 0.02, 3);
					ShowSyncHudMsg(player, hHudSync, "%d", iDamage);
				}
			}
			else if(gPlayer[player][RECEIVED])
			{
				if(gPlayer[player][POS_RECEIVED] + 1 >= gPlayer[player][SHOTS]) gPlayer[player][POS_RECEIVED] = bOld ? 3 : 0;
			
				iPos = gPlayer[player][POS_RECEIVED]++;
				
				remove_task(player + TASK_RECEIVED);
				
				set_task(2.5, "reset_pos_received", player + TASK_RECEIVED);
				
				if(gPlayer[player][TYPE])
				{
					set_dhudmessage(255, id == iAttacker ? 150 : 0, 0, 0.3, fCoords[iPos][0], 0, 0.1, 2.5, 0.02, 0.02);
					show_dhudmessage(player, "%d", iDamage);
				}
				else
				{
					set_hudmessage(255, id == iAttacker ? 150 : 0, 0, 0.3, Float:fCoords[iPos][0], 0, 0.1, 2.5, 0.02, 0.02, 3);
					ShowSyncHudMsg(player, hHudSync, "%d", iDamage);
				}
			}
		}
	}
}

public reset_pos_taken(id)
{
	id -= TASK_TAKEN;
	
	gPlayer[id][POS_TAKEN] = 0;
}

public reset_pos_received(id)
{
	id -= TASK_RECEIVED;
	
	gPlayer[id][POS_RECEIVED] = 0;
}

public load_hud(id)
{
	new sVaultKey[64], sVaultData[32];
	
	formatex(sVaultKey, charsmax(sVaultKey), "%s-abd", gPlayer[id][NAME]);
	
	if(nvault_get(vHUD, sVaultKey, sVaultData, charsmax(sVaultData)))
	{
		replace_all(sVaultData, charsmax(sVaultData), "#", " ");

		new sType[2], sTaken[2], sReceived[2], sShots[2];

		parse(sVaultData, sType, charsmax(sType), sTaken, charsmax(sTaken), sReceived, charsmax(sReceived), sShots, charsmax(sShots));
		
		gPlayer[id][TYPE] = str_to_num(sType);
		gPlayer[id][TAKEN] = str_to_num(sTaken);
		gPlayer[id][RECEIVED] = str_to_num(sReceived);
		gPlayer[id][SHOTS] = str_to_num(sShots);
	}
	
	return PLUGIN_CONTINUE;
} 

public save_hud(id)
{
	new sVaultKey[64], sVaultData[32];
	
	formatex(sVaultKey, charsmax(sVaultKey), "%s-abd", gPlayer[id][NAME]);
	formatex(sVaultData, charsmax(sVaultData), "%i#%i#%i#%i", gPlayer[id][TYPE], gPlayer[id][TAKEN], gPlayer[id][RECEIVED], gPlayer[id][SHOTS]);
	
	nvault_set(vHUD, sVaultKey, sVaultData);
	
	return PLUGIN_CONTINUE;
}