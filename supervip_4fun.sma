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

#define XO_PLAYER 5
#define m_rgpPlayerItems_0 376
#define MAX_PLAYERS 32

#define ADMIN_FLAG_X (1<<23)

new Array:aVIP, Array:aSVIP, bool:bUsed[MAX_PLAYERS + 1], iSVIPModel[MAX_PLAYERS + 1], bool:bDisable, gRound = 0, iVip, iSVip, iModel;

new const szCmdVIP[][] = {"say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };
new const szCmdSVIP[][] = {"say /svips", "say_team /svips", "say /svipy", "say_team /svipy" };

new szDisallowed[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL, CSW_AK47, CSW_M4A1, CSW_AWP, 
	CSW_SG550, CSW_G3SG1, CSW_UMP45, CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

enum { MALE = 0, FEMALE = 1, OFF = 2 };

enum { AmmoX_AmmoID = 1, AmmoX_Ammount };

enum { ammo_none, ammo_338magnum = 1, ammo_762nato, ammo_556natobox, ammo_556nato, ammo_buckshot, ammo_45acp, 
	ammo_57mm, ammo_50ae, ammo_357sig, ammo_9mm, ammo_flashbang, ammo_hegrenade, ammo_smokegrenade, ammo_c4 };

new const g_iMaxBpAmmo[] = { 0, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };

forward amxbans_admin_connect(id);

native umc_vote_in_process();
native check_small_map();
native get_small_map();

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCmdVIP; i++) register_clcmd(szCmdVIP[i], "ShowVips");
	for(new i; i < sizeof szCmdSVIP; i++) register_clcmd(szCmdSVIP[i], "ShowSVips");
	
	register_clcmd("say /vip", "ShowVIPMotd");
	register_clcmd("say /svip", "ShowSVIPMotd");
	register_clcmd("say /supervip", "ShowSVIPMotd");
	register_clcmd("say /model", "ChangeSVIPModel");
	register_clcmd("say /postac", "ChangeSVIPModel");
	
	register_clcmd("say_team", "VipChat");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	
	register_event("TextMsg", "RoundRestart", "a", "2&#Game_C", "2&#Game_w");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	register_message(get_user_msgid("AmmoX"), "MessageAmmoX");

	iModel = nvault_open("vip");
	
	if(iModel == INVALID_HANDLE) set_fail_state("[VIP] Nie mozna otworzyc pliku vip.vault");
	
	aVIP = ArrayCreate(32, 32);
	aSVIP = ArrayCreate(32, 32);
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("get_user_vip", "_get_user_vip", 1);
	register_native("set_user_svip", "_set_user_svip", 1);
	register_native("get_user_svip", "_get_user_svip", 1);
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

	iSVIPModel[id] = MALE;
	
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

	if(get_user_flags(id) & ADMIN_FLAG_X)
	{
		Set(id, iVip);
		Set(id, iSVip);

		LoadModel(id);
		
		new szName[32], szTempName[32], iSize = ArraySize(aSVIP);
		
		get_user_name(id, szName, charsmax(szName));
		
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aSVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName)) return PLUGIN_CONTINUE;
		}
		
		ArrayPushString(aSVIP, szName);
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

public ChangeSVIPModel(id)
{
	if(!Get(id, iSVip))
	{
		client_print_color(id, id, "^x04[SVIP]^x01 Nie posiadasz^x03 SuperVIPa^x01!");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\wMenu \ySuperVIP\w: Wybierz \rPostac\w", "ChangeSVIPModel_Handler");
	
	menu_additem(menu, "\yKobieta");
	menu_additem(menu, "\yMezczyzna");
	menu_additem(menu, "\rWylaczony");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public ChangeSVIPModel_Handler(id, menu, item)
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
			iSVIPModel[id] = FEMALE;

			if(is_user_alive(id))
			{
				switch(get_user_team(id))
				{
					case 1: cs_set_user_model(id, "csrft");
					case 2: cs_set_user_model(id, "csrfct");
				}
			}

			client_print_color(id, id, "^x04[SVIP]^x01 Ustawiony zostal model^x03 kobiety^x01!");
		}
		case 1: 
		{
			iSVIPModel[id] = MALE;

			if(is_user_alive(id))
			{
				switch(get_user_team(id))
				{
					case 1: cs_set_user_model(id, "csrmt");
					case 2: cs_set_user_model(id, "csrmct");
				}
			}

			client_print_color(id, id, "^x04[SVIP]^x01 Ustawiony zostal model^x03 mezczyzny^x01!");
		}
		case 2: 
		{
			iSVIPModel[id] = OFF;

			cs_reset_user_model(id);

			client_print_color(id, id, "^x04[SVIP]^x01 Model postaci zostal^x03 wylaczony^x01!");
		}
	}

	SaveModel(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}
	
public NewRound()
	++gRound;

public RoundRestart()
	gRound = 0;

public TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || get_user_team(iVictim) == get_user_team(iAttacker) || !Get(iAttacker, iSVip) || check_small_map()) return HAM_IGNORED;

	SetHamParamFloat(4, fDamage + 3.0);
	return HAM_HANDLED;
}

public PlayerSpawned(id)
{
	if(!is_user_alive(id) || bDisable || !Get(id, iVip)) return PLUGIN_CONTINUE;

	if(Get(id, iSVip))
	{
		switch(iSVIPModel[id])
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
	}

	if(check_small_map()) return PLUGIN_CONTINUE;

	StripWeapons(id, Secondary);

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
	}
	
	if(gRound >= 3) VipMenu(id);
	
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
			if(!Get(id, iSVip)) StripWeapons(id, Secondary);
			
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
			if(!Get(id, iSVip)) StripWeapons(id, Secondary);
			
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
				if(!Get(id, iSVip)) StripWeapons(id, Secondary);
				
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
				if(!Get(id, iSVip)) StripWeapons(id, Secondary);
				
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
	}
	
	return PLUGIN_CONTINUE;
}

public DeathMsg()
{
	new iKiller = read_data(1), iVictim = read_data(2), iHS = read_data(3);
	
	if(Get(iKiller, iVip) && is_user_alive(iKiller) && get_user_team(iKiller) != get_user_team(iVictim) && !check_small_map())
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
		new szTempMessage[190], szMessage[190], szPrefix[64], szSteamID[33];
		
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
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), "^x03 %s1^x01 :  %s2");
		}
		
		set_msg_arg_string(2, szMessage);
	}
	
	return PLUGIN_CONTINUE;
}

public MessageAmmoX(iMsgId, iMsgDest, id)
{
	new iAmmoID = get_msg_arg_int(AmmoX_AmmoID);

	if(is_user_alive(id) && iAmmoID && iAmmoID <= ammo_9mm && Get(id, iSVip) && !check_small_map())
	{
		new iMaxBpAmmo = g_iMaxBpAmmo[iAmmoID];
		if(get_msg_arg_int(AmmoX_Ammount) < iMaxBpAmmo)
		{
			set_msg_arg_int(AmmoX_Ammount, ARG_BYTE, iMaxBpAmmo);
			set_pdata_int(id, m_rgpPlayerItems_0 + iAmmoID, iMaxBpAmmo, XO_PLAYER);
		}
	}
}

stock bool:check_weapons(id, szszDisallowed[], iAmount = sizeof(szszDisallowed)) 
{
	new iWeapons[32], iWeapon, iNum, i;
	
	iWeapon = get_user_weapons(id, iWeapons, iNum);
	
	for(i = 0; i < iAmount; ++i) if(iWeapon & (1<<szszDisallowed[i])) return true;
	
	return false;
}

public SaveModel(id)
{
	new szVaultKey[64], szVaultName[32], szVaultData[2];

	get_user_name(id, szVaultName, charsmax(szVaultName));
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-model", szVaultName);
	formatex(szVaultData, charsmax(szVaultData), "%d", iSVIPModel[id]);
	
	nvault_set(iModel, szVaultKey, szVaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadModel(id)
{
	new szVaultKey[64], szVaultName[32], szVaultData[2];

	get_user_name(id, szVaultName, charsmax(szVaultName));
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-model", szVaultName);
	
	if(nvault_get(iModel, szVaultKey, szVaultData, charsmax(szVaultData))) iSVIPModel[id] = str_to_num(szVaultData);
	
	return PLUGIN_CONTINUE;
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

public _set_user_svip(id)
{
	if(get_user_flags(id) & ADMIN_FLAG_X && !Get(id, iSVip))
	{
		Set(id, iVip);
		Set(id, iSVip);

		LoadModel(id);
		
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
	
		ArrayPushString(aVIP, szName);
		ArrayPushString(aSVIP, szName);
	}
	
	return PLUGIN_CONTINUE;
}

public _get_user_svip(id)
	return Get(id, iSVip);