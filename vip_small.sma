#include <amxmodx>
#include <colorchat>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <dhudmessage>

forward amxbans_admin_connect(id);

new Array:g_Array, bool:g_Vip[33], gRound=0, bool:g_Disable, UsedMenu[33];

new const g_Langcmd[][]={"say /vips","say_team /vips","say /vipy","say_team /vipy"};

new disallowed[] = { 
CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,
CSW_AK47, CSW_M4A1, CSW_AWP, CSW_SG550, CSW_G3SG1, CSW_UMP45,
CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

public plugin_init(){
	register_plugin("Universal VIP", "1.0", "O'Zone");

	g_Array=ArrayCreate(64,32);
	
	for(new i;i<sizeof g_Langcmd;i++)
		register_clcmd(g_Langcmd[i], "ShowVips");
	register_clcmd("say /vip", "ShowMotd");
	
	RegisterHam(Ham_Spawn, "player", "SpawnedEventPre", 1);
	
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"),"handleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	
	CheckMap();
}

public plugin_natives()
{
	register_native("set_user_vip", "DodajVIP", 1);
}

public plugin_end()
	ArrayDestroy(g_Array);

public amxbans_admin_connect(id)
	client_authorized(id);

public client_authorized(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		g_Vip[id]=true;
		new g_Name[32];
		get_user_name(id,g_Name,charsmax(g_Name));
	
		new g_Size = ArraySize(g_Array);
		new szName[32];
	
		for(new i = 0; i < g_Size; i++)
		{
			ArrayGetString(g_Array, i, szName, charsmax(szName));
		
			if(equal(g_Name, szName))
				return 0;
		}
		ArrayPushString(g_Array,g_Name);
	}
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if(g_Vip[id])
	{
		g_Vip[id]=false;
		new Name[32];
		get_user_name(id,Name,charsmax(Name));
	
		new g_Size = ArraySize(g_Array);
		new g_Name[32];
	
		for(new i = 0; i < g_Size; i++)
		{
			ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
			if(equal(g_Name,Name))
			{
				ArrayDeleteItem(g_Array,i);
				break;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if(g_Vip[id])
	{
		new szName[32];
		get_user_info(id,"name",szName,charsmax(szName));
		
		new Name[32];
		get_user_name(id,Name,charsmax(Name));
		
		if(!equal(szName,Name))
		{
			ArrayPushString(g_Array,szName);
			
			new g_Size=ArraySize(g_Array);
			new g_Name[32];
			for(new i = 0; i < g_Size; i++)
			{
				ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
				
				if(equal(g_Name,Name))
				{
					ArrayDeleteItem(g_Array,i);
					break;
				}
			}
		}
	}
}

public ShowMotd(id)
	show_motd(id, "vip.txt", "Informacje o vipie");
	
public event_new_round()
	++gRound;

public GameCommencing()
	gRound=0;

public SpawnedEventPre(id)
{
	if(!g_Vip[id] || !is_user_alive(id) || g_Disable)
		return PLUGIN_CONTINUE;
		
	if(gRound >= 2)
	{
		give_item(id, "weapon_hegrenade");
		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	}
	
	if(gRound >= 3)
		show_vip_menu(id);

	StripWeapons(id, Secondary);
	give_item(id, "weapon_deagle");
	give_item(id, "ammo_50ae");
	new weapon_id = find_ent_by_owner(-1, "weapon_deagle", id);
	if(weapon_id)
		cs_set_weapon_ammo(weapon_id, 7);
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	
	if(get_user_team(id) == 2)
		cs_set_user_defuse(id, 1);

	return PLUGIN_CONTINUE;
}

public show_vip_menu(id)
{
	UsedMenu[id] = false;
	
	set_task(15.0, "close_menu", id);

	new menu = menu_create("\wMenu VIPa: \rWybierz Zestaw","menu_handler");
	
	menu_additem(menu, "\yM4A1 + Deagle","0", 0);
	menu_additem(menu, "\yAK47 + Deagle^n","1", 0);
	menu_additem(menu, "\wWyjscie","2", 0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, menu);
}

public menu_handler(id, menu, item)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
		
	UsedMenu[id] = true;
		
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

public close_menu(id)
{
	if(UsedMenu[id] || !is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	show_menu(id, 0, "^n", 1);
	if(!sprawdz_bronie(id, disallowed))
	{
		ColorChat(id, GREEN, "[VIP]^x01 Zestaw zostal ci przydzielony losowo.");
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
	new killer = read_data(1);
	new victim = read_data(2);
	new hs = read_data(3);
	
	if(g_Vip[killer] && is_user_alive(killer) && get_user_team(killer) != get_user_team(victim))
	{
		if(hs)
		{
			set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "HeadShot! +15HP");
			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) : min(get_user_health(killer)+15, 100));
			cs_set_user_money(killer, cs_get_user_money(killer)+350);
		}
		else 
		{
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "Zabiles! +10HP");
			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) : min(get_user_health(killer)+10, 100));
			cs_set_user_money(killer, cs_get_user_money(killer)+200);
		}
	}
}

public ShowVips(id){
	new g_Name[32], g_Message[150], g_Message2[170];
	
	new g_Size=ArraySize(g_Array);
	
	for(new i = 0; i < g_Size; i++)
	{
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		add(g_Message, charsmax(g_Message), g_Name);
		
		if(i == g_Size - 1)
			add(g_Message, charsmax(g_Message), ".");
		else
			add(g_Message, charsmax(g_Message), ", ");
	}
	formatex(g_Message2, charsmax(g_Message2), g_Message);
	ColorChat(id, GREEN, g_Message2);
	return PLUGIN_CONTINUE;
}

public VipStatus()
{
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && g_Vip[id])
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
}

public handleSayText(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id) && g_Vip[id])
	{
		new szTmp[150], szTmp2[170], szPrefix[64], szSteamID[33];
		get_msg_arg_string(2,szTmp, charsmax(szTmp));
		get_user_authid(id, szSteamID, charsmax(szSteamID)); 
	
		if(equali(szSteamID, "STEAM_0:1:77582"))
			formatex(szPrefix, charsmax(szPrefix), "^x04[WLASCICIEL]");
		else
			formatex(szPrefix, charsmax(szPrefix), "^x04[VIP]");
		
		if(!equal(szTmp,"#Cstrike_Chat_All"))
		{
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2)," ");
			add(szTmp2,charsmax(szTmp2),szTmp);
		}
		else
		{
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
		}
		set_msg_arg_string(2,szTmp2);
	}
	return PLUGIN_CONTINUE;
}

CheckMap() 
{
	new g_iMapPrefix[][] = 
	{ 
		"aim_", 
		"awp_", 
		"awp4one", 
		"fy_" ,
		"cs_deagle5" ,
		"fun_allinone",
		"1hp_he"
	}
	new MapName[32]
	get_mapname(MapName, 31)
	
	for(new i = 0; i < sizeof(g_iMapPrefix); i++)
	{
		if(containi(MapName, g_iMapPrefix[i]) != -1) 
			g_Disable = true
	}
}

stock bool:sprawdz_bronie(id, disallowed[], ile = sizeof(disallowed)) 
{
	new weapons[32], num, pwpns, i;
	pwpns = get_user_weapons(id, weapons, num);
	for(i=0; i<ile; ++i) 
	{
		if(pwpns & (1<<disallowed[i]))
			return true;
	}
	return false;
}

public DodajVIP(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		g_Vip[id]=true;
		new g_Name[32];
		get_user_name(id,g_Name,charsmax(g_Name));
	
		new g_Size = ArraySize(g_Array);
		new szName[32];
	
		for(new i = 0; i < g_Size; i++)
		{
			ArrayGetString(g_Array, i, szName, charsmax(szName));
		
			if(equal(g_Name, szName))
				return 0;
		}
		ArrayPushString(g_Array,g_Name);
	}
	return PLUGIN_CONTINUE;
}
