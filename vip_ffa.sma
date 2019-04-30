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

forward amxbans_admin_connect(id);

new Array:aVIP, bool:bUsed[MAX_PLAYERS + 1], iModel[MAX_PLAYERS + 1], iJumps[MAX_PLAYERS + 1], bool:bDisable, gRound = 0, iVip, iModels;

new const szCmdVIP[][] = { "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };
new const szCmdVIPMotd[][] = { "say /vip", "say_team /vip" };
new const szCmdSkins[][] = { "say /model", "say_team /model", "say /postac", "say_team /postac" };

enum { MALE = 0, FEMALE = 1, OFF = 2 };

new szDisallowed[] = { 
CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,
CSW_AK47, CSW_M4A1, CSW_AWP, CSW_SG550, CSW_G3SG1, CSW_UMP45,
CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCmdVIP; i++) register_clcmd(szCmdVIP[i], "ShowVips");
	for(new i; i < sizeof szCmdVIPMotd; i++) register_clcmd(szCmdVIPMotd[i], "ShowVIPMotd");
	for(new i; i < sizeof szCmdSkins; i++) register_clcmd(szCmdSkins[i], "ChangeVIPModel");
	
	register_clcmd("say_team", "VipChat");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);

	register_forward(FM_CmdStart, "CmdStart");
	
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");

	iModels = nvault_open("vip");
	
	if(iModels == INVALID_HANDLE) set_fail_state("[VIP] Nie mozna otworzyc pliku vip.vault");
	
	aVIP = ArrayCreate(32, 32);
	
	check_map();
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("is_user_vip", "_is_user_vip", 1);
}

public plugin_precache()
{
	precache_generic("models/player/csrmt/csrmt.mdl");
	precache_generic("models/player/csrmct/csrmct.mdl");
	precache_generic("models/player/csrft/csrft.mdl");
	precache_generic("models/player/csrft/csrftT.mdl");
	precache_generic("models/player/csrfct/csrfct.mdl");
	precache_generic("models/player/csrfct/csrfctT.mdl");
}

public plugin_end()
	ArrayDestroy(aVIP);

public amxbans_admin_connect(id)
	client_authorized(id, "");

public client_authorized(id)
	client_authorized_post(id);

public client_authorized_post(id)
{
	Rem(id, iVip);

	iModel[id] = MALE;
	
	if(get_user_flags(id) & ADMIN_LEVEL_H)
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

public ShowVIPMotd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");
	
public NewRound()
	++gRound;

public GameCommencing()
	gRound = 0;

public PlayerSpawned(id)
{
	if(!Get(id, iVip) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	switch(iModel[id])
	{
		case FEMALE:
		{
			switch(get_user_team(id))
			{
				case 1: cs_set_user_model(id, "csrft");
				case 2: cs_set_user_model(id, "csrfct");
			}
		}
		case MALE:
		{
			switch(get_user_team(id))
			{
				case 1: cs_set_user_model(id, "csrmt");
				case 2: cs_set_user_model(id, "csrmct");
			}
		}
		case OFF: cs_reset_user_model(id);
	}

	if(bDisable) return PLUGIN_CONTINUE;

	if(gRound >= 2)
	{
		give_item(id, "weapon_hegrenade");

		cs_set_user_armor(id, 150, CS_ARMOR_VESTHELM);
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
	
	set_task(15.0, "CloseVipMenu", id);

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
		case 2:
		{
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
			case 3:
			{
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

public ChangeVIPModel(id)
{
	if(!Get(id, iVip))
	{
		client_print_color(id, id, "^x04[VIP]^x01 Nie posiadasz^x03 SuperVIPa^x01!");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\wWybierz \rPostac\w", "ChangeVIPModel_Handler");
	
	menu_additem(menu, "\yKobieta");
	menu_additem(menu, "\yMezczyzna");
	menu_additem(menu, "\rWylaczony");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ChangeVIPModel_Handler(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0: 
		{
			iModel[id] = FEMALE;

			if(is_user_alive(id))
			{
				switch(get_user_team(id))
				{
					case 1: cs_set_user_model(id, "csrft");
					case 2: cs_set_user_model(id, "csrfct");
				}
			}

			client_print_color(id, id, "^x04[VIP]^x01 Ustawiony zostal model^x03 kobiety^x01!");
		}
		case 1: 
		{
			iModel[id] = MALE;

			if(is_user_alive(id))
			{
				switch(get_user_team(id))
				{
					case 1: cs_set_user_model(id, "csrmt");
					case 2: cs_set_user_model(id, "csrmct");
				}
			}

			client_print_color(id, id, "^x04[VIP]^x01 Ustawiony zostal model^x03 mezczyzny^x01!");
		}
		case 2: 
		{
			iModel[id] = OFF;

			cs_reset_user_model(id);

			client_print_color(id, id, "^x04[VIP]^x01 Model postaci zostal^x03 wylaczony^x01!");
		}
	}

	SaveModel(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
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
			
			set_user_health(iKiller, min(get_user_health(iKiller) + 15, 110));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 350);
		}
		else 
		{
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(iKiller, "Zabiles! +10 HP");
			
			set_user_health(iKiller, min(get_user_health(iKiller) + 10, 100));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 200);
		}
	}
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id) || !Get(id, iVip)) return FMRES_IGNORED;

	new flags = pev(id, pev_flags);

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && iJumps[id])
	{
		iJumps[id]--;

		new Float:velocity[3];

		pev(id, pev_velocity, velocity);

		velocity[2] = random_float(265.0,285.0);

		set_pev(id, pev_velocity, velocity);
	}
	else if(flags & FL_ONGROUND) iJumps[id] = 1;

	return FMRES_IGNORED;
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

check_map() 
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

public SaveModel(id)
{
	new szVaultKey[64], szVaultName[32], szVaultData[2];

	get_user_name(id, szVaultName, charsmax(szVaultName));
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-model", szVaultName);
	formatex(szVaultData, charsmax(szVaultData), "%d", iModel[id]);
	
	nvault_set(iModels, szVaultKey, szVaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadModel(id)
{
	new szVaultKey[64], szVaultName[32], szVaultData[2];

	get_user_name(id, szVaultName, charsmax(szVaultName));
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-model", szVaultName);
	
	if(nvault_get(iModels, szVaultKey, szVaultData, charsmax(szVaultData))) iModel[id] = str_to_num(szVaultData);
	
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

public _is_user_vip(id)
	return Get(id, iVip);