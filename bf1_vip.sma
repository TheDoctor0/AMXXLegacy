#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#if AMXX_VERSION_NUM < 183
#include <colorchat>
#include <dhudmessage>
#endif

#define PLUGIN "Battlefield One VIP"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new Array:VIPList, bool:VIP[33], round = 0, bool:disabled, usedMenu[33];

new const commandVIP[][]= { "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };

new disallowed[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,
	CSW_AK47, CSW_M4A1, CSW_AWP, CSW_SG550, CSW_G3SG1, CSW_UMP45,
	CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

forward amxbans_admin_connect(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	VIPList = ArrayCreate(64,32);
	
	for(new i; i < sizeof commandVIP; i++) register_clcmd(commandVIP[i], "ShowVips");
	
	register_clcmd("say /vip", "ShowMotd");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);
	
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"),"handleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	
	check_map();
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("get_user_vip", "_get_user_vip", 1);
}

public plugin_end()
	ArrayDestroy(VIPList);

public amxbans_admin_connect(id)
#if AMXX_VERSION_NUM < 183
	client_authorized(id);
#else
	client_authorized(id, "");
#endif

public client_authorized(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_H)
	{
		new playerName[32], listName[32], listSize = ArraySize(VIPList);
		
		get_user_name(id, playerName, charsmax(playerName));
		
		VIP[id] = true;
	
		for (new i = 0; i < listSize; i++)
		{
			ArrayGetString(VIPList, i, listName, charsmax(listName));
		
			if (equal(playerName, listName)) return 0;
		}
		
		ArrayPushString(VIPList, playerName);
	}
	
	return PLUGIN_CONTINUE;
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	if (VIP[id])
	{
		new playerName[32], listName[32], listSize = ArraySize(VIPList);
		
		get_user_name(id, playerName, charsmax(playerName));
	
		VIP[id] = false;
	
		for (new i = 0; i < listSize; i++)
		{
			ArrayGetString(VIPList, i, listName, charsmax(listName));
		
			if (equal(listName, playerName))
			{
				ArrayDeleteItem(VIPList, i); 

				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if (VIP[id])
	{
		new playerName[32];

		get_user_info(id, "name", playerName, charsmax(playerName));
		
		new playerOldName[32];

		get_user_name(id, playerOldName, charsmax(playerOldName));
		
		if (!equal(playerName, playerOldName))
		{
			ArrayPushString(VIPList, playerName);
			
			new listName[32], listSize = ArraySize(VIPList);

			for (new i = 0; i < listSize; i++)
			{
				ArrayGetString(VIPList, i, listName, charsmax(listName));
				
				if (equal(listName, playerOldName))
				{
					ArrayDeleteItem(VIPList,i);
					break;
				}
			}
		}
	}
}

public ShowMotd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");
	
public NewRound()
	++round;

public GameCommencing()
	round = 0;

public PlayerSpawned(id)
{
	if (!VIP[id] || !is_user_alive(id) || disabled) return PLUGIN_CONTINUE;
	
	if (round >= 3)
	{
		cmd_vip_menu(id);
		
		return PLUGIN_CONTINUE;
	}

	StripWeapons(id, Secondary);
	
	give_item(id, "weapon_deagle");
	give_item(id, "ammo_50ae");
	
	new weapon_id = find_ent_by_owner(-1, "weapon_deagle", id);

	if (weapon_id) cs_set_weapon_ammo(weapon_id, 7);
	
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	
	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");
	
	if (round == 2)
	{
		give_item(id, "weapon_hegrenade");
		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	}

	return PLUGIN_CONTINUE;
}

public cmd_vip_menu(id)
{
	usedMenu[id] = false;
	
	set_task(15.0, "close_menu", id);

	new menu = menu_create("\wMenu VIPa: \rWybierz Zestaw","menu_handler");
	
	menu_additem(menu, "\yM4A1 + Deagle");
	menu_additem(menu, "\yAK47 + Deagle");
	menu_additem(menu, "\yAWP");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
}

public menu_handler(id, menu, item)
{
	if (!is_user_alive(id)) return PLUGIN_HANDLED;
	
	usedMenu[id] = true;

	if (item == MENU_EXIT)
	{
		if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
		else give_item(id, "weapon_smokegrenade");
		
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
			
			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
			
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
			
			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
			
			client_print(id, print_center, "Dostales AK47 + Deagle!");
		}
		case 2:
		{
			StripWeapons(id, Primary);
			
			give_item(id, "weapon_awp");
			give_item(id, "ammo_338magnum");
			
			cs_set_user_bpammo(id, CSW_AWP, 30);
			
			client_print(id, print_center, "Dostales AWP!");
		}
	}
	
	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");

	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public close_menu(id)
{
	if (usedMenu[id] || !is_user_alive(id)) return PLUGIN_CONTINUE;
		
	show_menu(id, 0, "^n", 1);
	
	if (!check_weapons(id, disallowed))
	{
		#if AMXX_VERSION_NUM < 183
		ColorChat(id, GREEN, "^x04[VIP]^x01 Zestaw zostal ci przydzielony losowo.");
		#else
		client_print_color(id, id, "^x04[VIP]^x01 Zestaw zostal ci przydzielony losowo.");
		#endif
		
		switch(random_num(0, 2))
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
				
				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
				
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
				
				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
				
				client_print(id, print_center, "Dostales AK47 + Deagle!");
				
				cs_set_user_defuse(id, 1);
			}
			case 2:
			{
				StripWeapons(id, Primary);
				
				give_item(id, "weapon_awp");
				give_item(id, "ammo_338magnum");
				
				cs_set_user_bpammo(id, CSW_AWP, 30);
				
				client_print(id, print_center, "Dostales AWP!");
			}
		}
	}
	
	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");
	
	return PLUGIN_CONTINUE;
}

public DeathMsg()
{
	new killer = read_data(1), victim = read_data(2), hs = read_data(3);
	
	if (VIP[killer] && is_user_alive(killer) && get_user_team(killer) != get_user_team(victim))
	{
		if (hs)
		{
			set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "HeadShot! +15 HP");
			
			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 15 : min(get_user_health(killer) + 15, 100));

			cs_set_user_money(killer, cs_get_user_money(killer) + 350);
		}
		else 
		{
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "Zabiles! +10 HP");
			
			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 10 : min(get_user_health(killer) + 10, 100));

			cs_set_user_money(killer, cs_get_user_money(killer) + 200);
		}
	}
}

public ShowVips(id)
{
	new listName[32], tempMessage[180], chatMessage[180], listSize = ArraySize(VIPList);
	
	for (new i = 0; i < listSize; i++)
	{
		ArrayGetString(VIPList, i, listName, charsmax(listName));
		
		add(tempMessage, charsmax(tempMessage), listName);
		
		if (i == listSize - 1) add(tempMessage, charsmax(tempMessage), ".");
		else add(tempMessage, charsmax(tempMessage), ", ");
	}
	
	formatex(chatMessage, charsmax(chatMessage), tempMessage);
	
	#if AMXX_VERSION_NUM < 183
	ColorChat(id, GREEN, "^x04%s", chatMessage);
	#else
	client_print_color(id, id, "^x04%s", chatMessage);
	#endif
	
	return PLUGIN_CONTINUE;
}

public VipStatus()
{
	new id = get_msg_arg_int(1);
	
	if (is_user_alive(id) && VIP[id]) set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
}

public handleSayText(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if (is_user_connected(id) && VIP[id])
	{
		new tempMessage[180], chatMessage[180], chatPrefix[64];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		formatex(chatPrefix, charsmax(chatPrefix), "^x04[VIP]");
		
		if (!equal(tempMessage, "#Cstrike_Chat_All"))
		{
			add(chatMessage, charsmax(chatMessage), chatPrefix);
			add(chatMessage, charsmax(chatMessage), " ");
			add(chatMessage, charsmax(chatMessage), tempMessage);
		}
		else
		{
			add(chatMessage, charsmax(chatMessage), chatPrefix);
			add(chatMessage, charsmax(chatMessage), "^x03 %s1^x01 :  %s2");
		}

		set_msg_arg_string(2, chatMessage);
	}

	return PLUGIN_CONTINUE;
}

check_map() 
{
	new blockedMapPrefix[][] = 
	{ 
		"aim_", 
		"awp_", 
		"awp4one", 
		"fy_" ,
		"cs_deagle5" ,
		"fun_allinone",
		"1hp_he"
	}
	
	new mapName[32];
	get_mapname(mapName, charsmax(mapName));
	
	for (new i = 0; i < sizeof(blockedMapPrefix); i++) if (containi(mapName, blockedMapPrefix[i]) != -1) disabled = true;
}

stock bool:check_weapons(id, disallowed[], weapon = sizeof(disallowed)) 
{
	new weapons[32], num, pwpns, i;
	
	pwpns = get_user_weapons(id, weapons, num);
	
	for (i = 0; i < weapon; ++i)  if (pwpns & (1<<disallowed[i])) return true;

	return false;
}

public _set_user_vip(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_H)
	{
		new listName[32], playerName[32], listSize = ArraySize(VIPList);
		
		get_user_name(id,playerName,charsmax(playerName));
		
		VIP[id] = true;
	
		for (new i = 0; i < listSize; i++)
		{
			ArrayGetString(VIPList, i, listName, charsmax(listName));
		
			if (equal(listName, playerName)) return 0;
		}
		
		ArrayPushString(VIPList, playerName);
	}
	
	return PLUGIN_CONTINUE;
}

public _get_user_vip(id)
	return VIP[id];
