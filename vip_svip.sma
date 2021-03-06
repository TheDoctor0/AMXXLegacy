#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <nvault>

#define PLUGIN "Universal VIP"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

#define is_user_valid(%1) (1 <= %1 <= MAX_PLAYERS)

#define XO_PLAYER 5
#define m_rgpPlayerItems_0 376
#define MAX_PLAYERS 32

#define ADMIN_FLAG_X (1<<23)

new Array:aVIP, Array:aSVIP, bool:bUsed[MAX_PLAYERS + 1], bool:bDisable, gRound = 0, iVip, iSVip, iRandomVIP;

new const szCmdVIP[][] = { "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };
new const szCmdSVIP[][] = { "say /svips", "say_team /svips", "say /svipy", "say_team /svipy" };
new const szCmdVIPMotd[][] = { "say /vip", "say_team /vip" };
new const szCmdSVIPMotd[][] = { "say /svip", "say_team /svip", "say /supervip", "say_team /supervip" };

new szDisallowed[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL, CSW_AK47, CSW_M4A1, CSW_AWP, 
	CSW_SG550, CSW_G3SG1, CSW_UMP45, CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

enum { AmmoX_AmmoID = 1, AmmoX_Ammount };

enum { ammo_none, ammo_338magnum = 1, ammo_762nato, ammo_556natobox, ammo_556nato, ammo_buckshot, ammo_45acp, 
	ammo_57mm, ammo_50ae, ammo_357sig, ammo_9mm, ammo_flashbang, ammo_hegrenade, ammo_smokegrenade, ammo_c4 };

new const g_iMaxBpAmmo[] = { 0, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };

forward amxbans_admin_connect(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCmdVIP; i++) register_clcmd(szCmdVIP[i], "ShowVips");
	for(new i; i < sizeof szCmdSVIP; i++) register_clcmd(szCmdSVIP[i], "ShowSVips");
	for(new i; i < sizeof szCmdVIPMotd; i++) register_clcmd(szCmdVIPMotd[i], "ShowVIPMotd");
	for(new i; i < sizeof szCmdSVIPMotd; i++) register_clcmd(szCmdSVIPMotd[i], "ShowSVIPMotd");
	
	register_clcmd("say_team", "VipChat");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);
	
	register_event("TextMsg", "RoundRestart", "a", "2&#Game_C", "2&#Game_w");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	register_message(get_user_msgid("AmmoX"), "MessageAmmoX");
	
	aVIP = ArrayCreate(32, 32);
	aSVIP = ArrayCreate(32, 32);
	
	check_map();
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("get_user_vip", "_get_user_vip", 1);
	register_native("set_user_svip", "_set_user_svip", 1);
	register_native("get_user_svip", "_get_user_svip", 1);
}

public plugin_end()
{
	ArrayDestroy(aVIP);
	ArrayDestroy(aSVIP);
}

public amxbans_admin_connect(id)
	client_authorized_post(id);

public client_authorized(id)
	client_authorized_post(id);

public client_authorized_post(id)
{
	Rem(id, iVip);
	Rem(id, iSVip);
	
	if(get_user_flags(id) & ADMIN_LEVEL_H || get_user_flags(id) & ADMIN_FLAG_X)
	{
		Set(id, iVip);
		
		new szName[32], szTempName[32], iSize = ArraySize(aVIP), bool:bFound;
		
		get_user_name(id, szName, charsmax(szName));
		
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName)) bFound = true;
		}
		
		if(!bFound) ArrayPushString(aVIP, szName);

		if(get_user_flags(id) & ADMIN_FLAG_X)
		{
			Set(id, iSVip);
		
			new szName[32], szTempName[32], iSize = ArraySize(aSVIP);
			
			get_user_name(id, szName, charsmax(szName));
			
			for(new i = 0; i < iSize; i++)
			{
				ArrayGetString(aSVIP, i, szTempName, charsmax(szTempName));
			
				if(equal(szName, szTempName)) return PLUGIN_CONTINUE;
			}
			
			ArrayPushString(aSVIP, szName);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if(iRandomVIP == id) iRandomVIP = 0;

	if(Get(id, iVip))
	{
		Rem(id, iVip);
		
		new szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_name(id, szName, charsmax(szName));
	
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName))
			{
				ArrayDeleteItem(aVIP, i);
				
				break;
			}
		}
	}

	if(Get(id, iSVip))
	{
		Rem(id, iSVip);
		
		new szName[32], szTempName[32], iSize = ArraySize(aSVIP);
		
		get_user_name(id, szName, charsmax(szName));
	
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aSVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName))
			{
				ArrayDeleteItem(aSVIP, i);
				
				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if(Get(id, iVip))
	{
		new szNewName[32], szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_info(id, "name", szNewName,charsmax(szNewName));
		get_user_name(id, szName, charsmax(szName));
	
		if(szName[0] && !equal(szName, szNewName))
		{
			ArrayPushString(aVIP, szNewName);
			
			for(new i = 0; i < iSize; i++)
			{
				ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
				if(equal(szName, szTempName))
				{
					ArrayDeleteItem(aVIP, i);
					
					break;
				}
			}
		}
	}

	if(Get(id, iSVip))
	{
		new szNewName[32], szName[32], szTempName[32], iSize = ArraySize(aSVIP);
		
		get_user_info(id, "name", szNewName,charsmax(szNewName));
		get_user_name(id, szName, charsmax(szName));
	
		if(szName[0] && !equal(szName, szNewName))
		{
			ArrayPushString(aSVIP, szNewName);
			
			for(new i = 0; i < iSize; i++)
			{
				ArrayGetString(aSVIP, i, szTempName, charsmax(szTempName));
		
				if(equal(szName, szTempName))
				{
					ArrayDeleteItem(aSVIP, i);
					
					break;
				}
			}
		}
	}
}

public ShowVIPMotd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");

public ShowSVIPMotd(id)
	show_motd(id, "svip.txt", "Informacje o SuperVIPie");
	
public NewRound()
{
	++gRound;

	if(iRandomVIP) Rem(iRandomVIP, iVip);

	new randomPlayer[MAX_PLAYERS], players;
	
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || is_user_hltv(i) || Get(i, iVip)) continue;
		
		randomPlayer[++players] = i;
	}

	iRandomVIP = randomPlayer[(players ? random_num(1, players): 0)];

	if(iRandomVIP) Set(iRandomVIP, iVip);
}

public RoundRestart()
	gRound = 0;

public PlayerSpawned(id)
{
	if(!is_user_alive(id) || bDisable || !Get(id, iVip)) return PLUGIN_CONTINUE;

	if(iRandomVIP == id) 
	{
		set_hudmessage(0, 255, 0, -1.0, 0.35, 2, 3.0, 2.0, 0.2, 0.2);
		show_hudmessage(id, "Gratulacje, w tej rundzie dostales Darmowego VIPa!");
	}

	if(gRound >= 2)
	{
		give_item(id, "weapon_hegrenade");

		if(Get(id, iSVip))
		{
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_smokegrenade");
		}

		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

		StripWeapons(id, Secondary);

		give_item(id, "weapon_deagle");
		give_item(id, "ammo_50ae");

		new weapon_id = find_ent_by_owner(-1, "weapon_deagle", id);
		if(weapon_id) cs_set_weapon_ammo(weapon_id, 7);
		
		cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	} else {
		VipMenuPistol(id);
	}
	
	if(gRound >= 3) VipMenu(id);
	
	if(get_user_team(id) == 2) cs_set_user_defuse(id, 1);

	return PLUGIN_CONTINUE;
}

public VipMenu(id)
{
	bUsed[id] = false;
	
	set_task(15.0, "CloseVipMenu", id);

	new menu;

	if(Get(id, iSVip))
	{
		menu = menu_create("\wMenu \ySuperVIP\w: Wybierz \rZestaw\w", "VipMenu_Handler");
	
		menu_additem(menu, "\yM4A1 + Deagle","1");
		menu_additem(menu, "\yAK47 + Deagle","2");
		menu_additem(menu, "\yAWP + Deagle^n","3");
		menu_additem(menu, "\wWyjscie","0");
	}
	else
	{
		menu = menu_create("\wMenu \yVIP\w: Wybierz \rZestaw\w", "VipMenu_Handler");
	
		menu_additem(menu, "\yM4A1 + Deagle","1");
		menu_additem(menu, "\yAK47 + Deagle^n","2");
		menu_additem(menu, "\wWyjscie","0");
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
}

public VipMenu_Handler(id, menu, item)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;

	bUsed[id] = true;

	new szData[2], iAccess, iCallback, iKey;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	iKey = str_to_num(szData);

	if(!iKey)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		case 1: 
		{
			StripWeapons(id, Secondary);
			
			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
			StripWeapons(id, Primary);
			
			give_item(id, "weapon_m4a1");
			give_item(id, "ammo_556nato");
			
			cs_set_user_bpammo(id, CSW_M4A1, 90);
			
			client_print(id, print_center, "Dostales M4A1 + Deagle!");
		}
		case 2:
		{
			StripWeapons(id, Secondary);
			
			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
			StripWeapons(id, Primary);
			
			give_item(id, "weapon_ak47");
			give_item(id, "ammo_762nato");
			
			cs_set_user_bpammo(id, CSW_AK47, 90);
			
			client_print(id, print_center, "Dostales AK47 + Deagle!");
		}
		case 3:
		{
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
			StripWeapons(id, Primary);
			
			give_item(id, "weapon_awp");
			give_item(id,"ammo_338magnum");
			
			cs_set_user_bpammo(id, CSW_AWP, 30);
			
			client_print(id, print_center, "Dostales AWP + Deagle!");
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public CloseVipMenu(id)
{
	if(bUsed[id] || !is_user_alive(id)) return PLUGIN_CONTINUE;

	show_menu(id, 0, "^n", 1);
	
	if(!check_weapons(id, szDisallowed))
	{
		client_print_color(id, id, "^x04[%sVIP]^x01 Zestaw zostal ci przydzielony losowo.", Get(id, iSVip) ? "S" : "");

		new iRandom = random_num(0, Get(id, iSVip) ? 2 : 1);
		
		switch(iRandom)
		{
			case 0: 
			{
				StripWeapons(id, Secondary);
				
				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");
				
				cs_set_user_bpammo(id, CSW_DEAGLE, 35);
				
				StripWeapons(id, Primary);
				
				give_item(id, "weapon_m4a1");
				give_item(id, "ammo_556nato");
				
				cs_set_user_bpammo(id, CSW_M4A1, 90);
				
				client_print(id, print_center, "Dostales M4A1 + Deagle!");
			}
			case 1:
			{
				StripWeapons(id, Secondary);
				
				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");
				
				cs_set_user_bpammo(id, CSW_DEAGLE, 35);
				
				StripWeapons(id, Primary);
				
				give_item(id, "weapon_ak47");
				give_item(id, "ammo_762nato");
				
				cs_set_user_bpammo(id, CSW_AK47, 90);
				
				client_print(id, print_center, "Dostales AK47 + Deagle!");
			}
			case 2:
			{
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");
			
				cs_set_user_bpammo(id, CSW_DEAGLE, 35);
				
				StripWeapons(id, Primary);
				
				give_item(id, "weapon_awp");
				give_item(id,"ammo_338magnum");
				
				cs_set_user_bpammo(id, CSW_AWP, 30);
				
				client_print(id, print_center, "Dostales AWP + Deagle!");
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public VipMenuPistol(id)
{
	bUsed[id] = false;
	
	set_task(15.0, "CloseVipMenuPistol", id);

	new menu;

	if(Get(id, iSVip)) menu = menu_create("\wMenu \ySuperVIP\w: Wybierz \rPistolet\w", "VipMenuPistol_Handler");
	else menu = menu_create("\wMenu \yVIP\w: Wybierz \rPistolet\w", "VipMenuPistol_Handler");
	
	menu_additem(menu, "\yDeagle","1");
	menu_additem(menu, "\yUSP","2");
	menu_additem(menu, "\yGlock^n","3");
	menu_additem(menu, "\wWyjscie","0");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
}

public VipMenuPistol_Handler(id, menu, item)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;

	bUsed[id] = true;

	new szData[2], iAccess, iCallback, iKey;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	iKey = str_to_num(szData);

	if(!iKey)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(iKey)
	{
		case 1: 
		{
			StripWeapons(id, Secondary);
			
			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");
			
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			
			client_print(id, print_center, "Dostales Deagle!");
		}
		case 2:
		{
			StripWeapons(id, Secondary);
			
			give_item(id, "weapon_usp");
			give_item(id, "ammo_45acp");
			
			cs_set_user_bpammo(id, CSW_USP, 100);
			
			client_print(id, print_center, "Dostales USP!");
		}
		case 3:
		{
			StripWeapons(id, Secondary);

			give_item(id, "weapon_glock18");
			give_item(id, "ammo_9mm");
			
			cs_set_user_bpammo(id, CSW_GLOCK18, 120);
			
			client_print(id, print_center, "Dostales Glocka!");
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public CloseVipMenuPistol(id)
{
	if(bUsed[id] || !is_user_alive(id)) return PLUGIN_CONTINUE;

	show_menu(id, 0, "^n", 1);
	
	if(!check_weapons(id, szDisallowed))
	{
		client_print_color(id, id, "^x04[%sVIP]^x01 Pistolet zostal ci przydzielony losowo.", Get(id, iSVip) ? "S" : "");

		new iRandom = random_num(1, 3);
		
		switch(iRandom)
		{
			case 1: 
			{
				StripWeapons(id, Secondary);
				
				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");
				
				cs_set_user_bpammo(id, CSW_DEAGLE, 35);
				
				client_print(id, print_center, "Dostales Deagle!");
			}
			case 2:
			{
				StripWeapons(id, Secondary);
				
				give_item(id, "weapon_usp");
				give_item(id, "ammo_45acp");
				
				cs_set_user_bpammo(id, CSW_USP, 100);
				
				client_print(id, print_center, "Dostales USP!");
			}
			case 3:
			{
				StripWeapons(id, Secondary);

				give_item(id, "weapon_glock18");
				give_item(id, "ammo_9mm");
				
				cs_set_user_bpammo(id, CSW_GLOCK18, 120);
				
				client_print(id, print_center, "Dostales Glocka!");
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public DeathMsg()
{
	new iKiller = read_data(1), iVictim = read_data(2), iHS = read_data(3);
	
	if(Get(iKiller, iVip) && is_user_alive(iKiller) && get_user_team(iKiller) != get_user_team(iVictim))
	{
		if(iHS)
		{
			set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(iKiller, "HeadShot! +15 HP");
			
			set_user_health(iKiller, get_user_health(iKiller) > 100 ? get_user_health(iKiller) + 15 : min(get_user_health(iKiller) + 15, 100));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 350);
		}
		else 
		{
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(iKiller, "Zabiles! +10 HP");
			
			set_user_health(iKiller, get_user_health(iKiller) > 100 ? get_user_health(iKiller) + 10 : min(get_user_health(iKiller) + 10, 100));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 200);
		}
	}
}

public ShowVips(id)
{
	new szName[32], szTempMessage[190], szMessage[190], iSize = ArraySize(aVIP);
	
	for(new i = 0; i < iSize; i++)
	{
		ArrayGetString(aVIP, i, szName, charsmax(szName));
		
		add(szTempMessage, charsmax(szTempMessage), szName);
		
		if(i == iSize - 1) add(szTempMessage, charsmax(szTempMessage), ".");
		else add(szTempMessage, charsmax(szTempMessage), ", ");
	}
	
	formatex(szMessage, charsmax(szMessage), szTempMessage);
	
	client_print_color(id, id, "^x04%s", szMessage);
	
	return PLUGIN_CONTINUE;
}

public ShowSVips(id)
{
	new szName[32], szTempMessage[190], szMessage[190], iSize = ArraySize(aSVIP);
	
	for(new i = 0; i < iSize; i++)
	{
		ArrayGetString(aSVIP, i, szName, charsmax(szName));
		
		add(szTempMessage, charsmax(szTempMessage), szName);
		
		if(i == iSize - 1) add(szTempMessage, charsmax(szTempMessage), ".");
		else add(szTempMessage, charsmax(szTempMessage), ", ");
	}
	
	formatex(szMessage, charsmax(szMessage), szTempMessage);
	
	client_print_color(id, id, "^x04%s", szMessage);
	
	return PLUGIN_CONTINUE;
}

public VipStatus()
{
	new id = get_msg_arg_int(1);
	
	if(is_user_alive(id) && Get(id, iVip)) set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
}

public VipChat(id)
{
	if(Get(id, iVip))
	{
		new szText[190], szMessage[190];
		
		read_args(szText, charsmax(szText));
		remove_quotes(szText);
		
		if(szText[0] == '*' && szText[1])
		{
			new szName[32];
			
			get_user_name(id, szName, charsmax(szName));
			
			formatex(szMessage, charsmax(szMessage), "^x01(VIP CHAT) ^x03%s : ^x04%s", szName, szText[1]);
			
			for(new i = 1; i <= 32; i++) if(is_user_connected(i) && Get(i, iVip)) client_print_color(i, i, "^x04%s", szMessage);

			return PLUGIN_HANDLED_MAIN;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public HandleSayText(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id) && Get(id, iVip))
	{
		new szTempMessage[190], szMessage[190], szPrefix[64], szSteamID[33], szPlayerName[32];
		
		get_msg_arg_string(2, szTempMessage, charsmax(szTempMessage));
		get_user_authid(id, szSteamID, charsmax(szSteamID)); 

		if(equali(szSteamID, "STEAM_0:1:55664") || equali(szSteamID, "STEAM_0:1:6389510")) formatex(szPrefix, charsmax(szPrefix), "^x04[WLASCICIEL]");
		else if(Get(id, iSVip)) formatex(szPrefix, charsmax(szPrefix), "^x04[SVIP]");
		else formatex(szPrefix, charsmax(szPrefix), "^x04[VIP]");
		
		if(!equal(szTempMessage, "#Cstrike_Chat_All"))
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), " ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		else
		{
			//add(szMessage, charsmax(szMessage), szPrefix);
			//add(szMessage, charsmax(szMessage), "^x03 %s1^x01 :  %s2");
			get_user_name(id, szPlayerName, charsmax(szPlayerName));
			get_msg_arg_string(4, szTempMessage, charsmax(szTempMessage)); 
			set_msg_arg_string(4, "");
		
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), "^x03 ");
			add(szMessage, charsmax(szMessage), szPlayerName);
			add(szMessage, charsmax(szMessage), "^x01 :  ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		
		set_msg_arg_string(2, szMessage);
	}
	
	return PLUGIN_CONTINUE;
}

public MessageAmmoX(iMsgId, iMsgDest, id)
{
	new iAmmoID = get_msg_arg_int(AmmoX_AmmoID);

	if(is_user_alive(id) && iAmmoID && iAmmoID <= ammo_9mm && Get(id, iSVip))
	{
		new iMaxBpAmmo = g_iMaxBpAmmo[iAmmoID];
		if(get_msg_arg_int(AmmoX_Ammount) < iMaxBpAmmo)
		{
			set_msg_arg_int(AmmoX_Ammount, ARG_BYTE, iMaxBpAmmo);
			set_pdata_int(id, m_rgpPlayerItems_0 + iAmmoID, iMaxBpAmmo, XO_PLAYER);
		}
	}
}

stock check_map() 
{
	new g_iMapPrefix[][] = 
	{ 
		"aim_", 
		"awp_", 
		"awp4one", 
		"fy_" ,
		"cs_deagle5" ,
		"fun_allinone",
		"1hp_he",
		"css_india"
	}
	
	new szMapName[32];
	
	get_mapname(szMapName, charsmax(szMapName));
	
	for(new i = 0; i < sizeof(g_iMapPrefix); i++) if(containi(szMapName, g_iMapPrefix[i]) != -1) bDisable = true
}

stock bool:check_weapons(id, szszDisallowed[], iAmount = sizeof(szszDisallowed)) 
{
	new iWeapons[32], iWeapon, iNum, i;
	
	iWeapon = get_user_weapons(id, iWeapons, iNum);
	
	for(i = 0; i < iAmount; ++i) if(iWeapon & (1<<szszDisallowed[i])) return true;
	
	return false;
}

public _set_user_vip(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_H && !Get(id, iVip)) client_authorized_post(id);
	
	return PLUGIN_CONTINUE;
}

public _get_user_vip(id)
	return Get(id, iVip);

public _set_user_svip(id)
{
	if(get_user_flags(id) & ADMIN_FLAG_X && !Get(id, iSVip)) client_authorized_post(id);
	
	return PLUGIN_CONTINUE;
}

public _get_user_svip(id)
	return Get(id, iSVip);