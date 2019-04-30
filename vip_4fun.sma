#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>

#define PLUGIN "Universal VIP"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

forward amxbans_admin_connect(id);

native umc_vote_in_process();
native check_small_map();
native get_small_map();

new Array:aVIP, bool:bUsed[33], gRound = 0, iVip;

new const szCmdVIP[][] = {"say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };

new szDisallowed[] = { 
CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,
CSW_AK47, CSW_M4A1, CSW_AWP, CSW_SG550, CSW_G3SG1, CSW_UMP45,
CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCmdVIP; i++) register_clcmd(szCmdVIP[i], "ShowVips");
	
	register_clcmd("say /vip", "ShowMotd");
	
	register_clcmd("say_team", "VipChat");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);
	
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	
	aVIP = ArrayCreate(32, 32);
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("get_user_vip", "_get_user_vip", 1);
}

public plugin_end()
	ArrayDestroy(aVIP);

public amxbans_admin_connect(id)
	client_authorized(id, "");

public client_authorized(id)
{
	Rem(id, iVip);
	
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		Set(id, iVip);
		
		new szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_name(id, szName, charsmax(szName));
		
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName)) return PLUGIN_CONTINUE;
		}
		
		ArrayPushString(aVIP, szName);
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
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
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if(Get(id, iVip))
	{
		new szNewName[32], szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_info(id, "name", szNewName,charsmax(szNewName));
		get_user_name(id, szName, charsmax(szName));
	
		if(!equal(szName, szNewName))
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
}

public ShowMotd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");
	
public NewRound()
	++gRound;

public GameCommencing()
	gRound = 0;

public PlayerSpawned(id)
{
	if(!Get(id, iVip) || !is_user_alive(id) || check_small_map()) return PLUGIN_CONTINUE;

	if(gRound >= 2)
	{
		give_item(id, "weapon_hegrenade");
		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	}
	
	if(gRound >= 3) VipMenu(id);

	StripWeapons(id, Secondary);
	
	give_item(id, "weapon_deagle");
	give_item(id, "ammo_50ae");
	
	new weapon_id = find_ent_by_owner(-1, "weapon_deagle", id);
	if(weapon_id) cs_set_weapon_ammo(weapon_id, 7);
	
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	
	if(get_user_team(id) == 2) cs_set_user_defuse(id, 1);

	return PLUGIN_CONTINUE;
}

public VipMenu(id)
{
	bUsed[id] = false;
	
	if(!get_small_map() && umc_vote_in_process()) set_task(0.1, "CloseVipMenu", id);
	else set_task(15.0, "CloseVipMenu", id);

	new menu = menu_create("\wMenu \yVIP\w: Wybierz \rZestaw\w", "VipMenu_Handler");
	
	menu_additem(menu, "\yM4A1 + Deagle","0", 0);
	menu_additem(menu, "\yAK47 + Deagle^n","1", 0);
	menu_additem(menu, "\wWyjscie","2", 0);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu);
}

public VipMenu_Handler(id, menu, item)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;

	bUsed[id] = true;

	if(item == 2)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
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
		client_print_color(id, id, "^x04[VIP]^x01 Zestaw zostal ci przydzielony losowo.");
		
		switch(random_num(0,1))
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
			
			for(new i = 1; i <= 32; i++) if(is_user_connected(i) && Get(i, iVip)) client_print_color(i, id, "%s", szMessage);

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
		new szTempMessage[190], szMessage[190], szPrefix[64], szSteamID[33];
		
		get_msg_arg_string(2, szTempMessage, charsmax(szTempMessage));
		get_user_authid(id, szSteamID, charsmax(szSteamID)); 
	
		if(equali(szSteamID, "STEAM_0:1:55664") || equali(szSteamID, "STEAM_0:1:6389510")) formatex(szPrefix, charsmax(szPrefix), "^x04[WLASCICIEL]");
		else formatex(szPrefix, charsmax(szPrefix), "^x04[VIP]");
		
		if(!equal(szTempMessage, "#Cstrike_Chat_All"))
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), " ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		else
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), "^x03 %s1^x01 :  %s2");
		}
		
		set_msg_arg_string(2, szMessage);
	}
	
	return PLUGIN_CONTINUE;
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
	if(get_user_flags(id) & ADMIN_LEVEL_H && !Get(id, iVip))
	{
		Set(id, iVip);
		
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
	
		ArrayPushString(aVIP, szName);
	}
	
	return PLUGIN_CONTINUE;
}

public _get_user_vip(id)
	return Get(id, iVip);