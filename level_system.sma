#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <ColorChat>
#include <weapon>
#include <zombie_plague_advance>
#include <dhudmessage>

#define HUD 123

#define ZP_MAX_EXP 15000

#define is_user_steam(%1) (%1[1] == ':' && %1[3] == ':')

#define IsPlayer(%1)  (1 <= %1 <= gMaxClients)

stock const expTable[] = {
	0, 30, 50, 100, 250,				// 5 LVL
	500, 700, 1500, 2500, 3500,       // 10 LVL
	5000, 7500, 10000, 12500, 15000   // 15 LVL
}

new gVault;
new user_datakey[33][36];
new user_class[33];
new user_level[33] = 1;
new user_exp[33];
new new_user_class[33];

new bool:FreezeTime;

new gMaxClients;

public plugin_init() {
	register_plugin("Level System", "1.0", "O'Zone")
	
	register_clcmd("say /klasa", "ChooseClass");
	register_clcmd("say /klasy", "ClassDescription");
	
	register_concmd("amx_setlvl", "SetLevel", ADMIN_IMMUNITY, "<nick> <level>");
	register_concmd("amx_addexp", "AddExp", ADMIN_IMMUNITY, "<nick> <exp>");
	register_concmd("amx_remexp", "RemoveExp", ADMIN_IMMUNITY, "<nick> <exp>");
	
	register_event("DeathMsg", "EventDeath", "a");
	register_logevent("RoundStart", 2, "1=Round_Start"); 
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	RegisterHam(Ham_TakeDamage, "player","TakeDamage", 0);
	RegisterHam(Ham_Item_PreFrame, "player", "SetSpeed", 1);
	
	gVault = nvault_open("LevelSystem");
	
	gMaxClients = get_maxplayers();
}

enum { 
	NONE = 0, 
	Lowca, 
	Human, 
	Skoczek, 
	Barbazynca
};

new const class_names[][] = {
	"Brak",
	"Lowca",
	"Human",
	"Skoczek",
	"Barbazynca (Premium)"
};

new const class_descriptions[][] = {
	"Brak",
	"Zadaje 5 obrazen wiecej, jest troche wolniejszy.",
	"Ma 20HP wiecej, dostaje +10 kamizelki",
	"Ma o 1/3 mniejsza grawitacje",
	"Zadaje 5 obrazen wiecej, +10 kamizelki i 1/4 mniejsza grawitacja."
};

public plugin_natives()
{
	register_native("zp_get_user_class", "nativeGetUserClass", 1)
	register_native("zp_get_user_level", "nativeGetUserLevel", 1)
	register_native("zp_set_user_level", "nativeSetUserLevel", 1)

	register_native("zp_add_user_exp", "nativeAddUserExp", 1)
	register_native("zp_get_user_exp", "nativeGetUserExp", 1)
	register_native("zp_set_user_exp", "nativeSetUserExp", 1)
}

public plugin_precache()
	precache_sound("common/wpn_denyselect.wav");

public plugin_end()
	nvault_close(gVault);

public client_connect(id) {
	user_class[id] = 0;
	user_level[id] = 0;
	user_exp[id] = 0;
	
	set_task(1.0, "ShowHUD", id+HUD, .flags="b");
	
	get_user_authid(id, user_datakey[id], 35);
	if(!is_user_steam(user_datakey[id]))
		get_user_name(id, user_datakey[id], 35);
}

public client_disconnect(id)
	remove_task(id+HUD);

public Spawn(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	if(new_user_class[id]) {
		user_class[id] = new_user_class[id];
		new_user_class[id] = 0;
		LoadData(id, user_class[id]);
	}
	
	if(zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return PLUGIN_CONTINUE;
	
	if(!user_class[id]) {
		ChooseClass(id);
		return PLUGIN_CONTINUE;
	}
	else
		WeaponMenu(id);
	
	ResetAbilities(id);
	return PLUGIN_CONTINUE;
}

public ResetAbilities(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	set_user_gravity(id, 1.0);
	if(get_user_health(id) == 120)
		set_user_health(id, 100);
	if(get_user_flags(id) & ADMIN_LEVEL_H)
		set_user_armor(id, 45);
	else
		set_user_armor(id, 0);
	set_task(0.1, "SetAbilities", id);
	return PLUGIN_CONTINUE;
}

public SetAbilities(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	switch(user_class[id]) {
	case Human: {
			set_user_armor(id, get_user_armor(id)+10);
			set_user_health(id, get_user_health(id)+20);
		}
	case Skoczek: {
			set_user_gravity(id, 0.66);
		}
	case Barbazynca: {
			set_user_gravity(id, 0.75);
			set_user_armor(id, get_user_armor(id)+10);
		}
	}
	return PLUGIN_CONTINUE;
}

public WeaponMenu(id) {
	new menu = menu_create("\yWybierz Bron","WeaponMenu_Handle");
	menu_additem(menu, "\y[Pistolet] \wAnaconda \r(1 LVL)");
	menu_additem(menu, "\y[Pistolet] \wSkull-1 \r(2 LVL)");
	menu_additem(menu, "\y[Pistolet] \wDual Infinity \r(3 LVL)");
	menu_additem(menu, "\y[Karabin] \wM14 EBR \r(4 LVL)");
	menu_additem(menu, "\y[Karabin] \wXM8 Basic \r(5 LVL)");
	menu_additem(menu, "\y[Karabin] \wAK-47 Long \r(6 LVL)");
	menu_additem(menu, "\y[Karabin] \wDual Kriss \r(7 LVL)");
	menu_additem(menu, "\y[Sniper] \wSL-8EX \r(8 LVL)");
	menu_additem(menu, "\y[Sniper] \wSkull-5 \r(9 LVL)");
	menu_additem(menu, "\y[Bazooka] \wDragon Cannon \r(10 LVL)");
	menu_additem(menu, "\y[Pistolet] \wJanus \r(11 LVL)");
	menu_additem(menu, "\y[Karabin] \wGuitar \r(12 LVL)");
	menu_additem(menu, "\y[Karabin] \wPlasma Gun \r(13 LVL)");
	menu_additem(menu, "\y[Karabin] \wM134 \r(14 LVL)");
	menu_additem(menu, "\y[Karabin] \wSFMG \r(15 LVL)");
 
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_BACKNAME, "Wstecz");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
}
 
public WeaponMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 0: {
			if(user_level[id] >= 1)
				give_weapon_anaconda(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 1: {
			if(user_level[id] >= 2)
				give_weapon_skull1(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 2: {
			if(user_level[id] >= 3)
				give_dinfinity(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 3: {
			if(user_level[id] >= 4)
				give_weapon_balrog5(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 4: {
			if(user_level[id] >= 5)
				give_cso_cart_blue(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 5: {
			if(user_level[id] >= 6)
				give_weapon_ak47long(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 6: {
			if(user_level[id] >= 7)
				give_kriss(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 7: {
			if(user_level[id] >= 8)
				give_weapon_sl8ex(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 8: {
			if(user_level[id] >= 9)
				give_weapon_skull5(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 9: {
			if(user_level[id] >= 10)
				give_weapon_cannon(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 10: {
			if(user_level[id] >= 11)
				give_weapon_janus1(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 11: {
			if(user_level[id] >= 12)
				give_weapon_guitar1(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 12: {
			if(user_level[id] >= 13)
				give_weapon_plasmagun(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 13: {
			if(user_level[id] >= 14)
				give_weapon_m134ex(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
		case 14: {
			if(user_level[id] >= 15)
				give_weapon_sfmg(id);
			else {
				ColorChat(id, GREEN, "[Level System]^x01 Nie masz wystarczajacego^x03 LVL'a^x01! Twoj LVL:^x04 %d", user_level[id])
				WeaponMenu(id);
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public EventDeath() {
	new iKiller = read_data(1), iVictim = read_data(2), HeadShot = read_data(3);
	if(iKiller == iVictim || !is_user_connected(iKiller))
		return;
	
	user_exp[iKiller] += 1;
	if(HeadShot)
		user_exp[iKiller] += 1;
	
	CheckLevel(iKiller);
}

public CheckLevel(id) {
	if(user_level[id] < 15){
		while(user_exp[id] >= expTable[user_level[id]]){
			user_level[id]++;
			ColorChat(id, GREEN, "[Level System]^x01 Awansowales na^x03%i^x01 poziom!", user_level[id]);
		}
	}
	SaveData(id);
}

public ShowHUD(id) {
	id -= HUD;
		
	if(!is_user_alive(id)) {
		if(!is_valid_ent(id))
			return PLUGIN_CONTINUE;
		
		new iDest = entity_get_int(id, EV_INT_iuser2);
		
		if(iDest == 0)
			return PLUGIN_CONTINUE;
		
		set_dhudmessage(255, 255, 255, -1.0, 0.8, 0, 0.1, 1.0, 0.1, 0.0, false);
		if(user_exp[iDest] >= ZP_MAX_EXP)
			show_dhudmessage(id , "[KLASA: %s] [LVL: %d] [EXP: %d]", class_names[user_class[iDest]], user_level[iDest], user_exp[iDest]);
		else
			show_dhudmessage(id , "[KLASA: %s] [LVL: %d] [EXP: %d / %d]", class_names[user_class[iDest]], user_level[iDest], user_exp[iDest], expTable[user_level[iDest]]);
		
		return PLUGIN_CONTINUE;
	}
	
	set_dhudmessage(0, 255, 0, -1.0, 0.8, 0, 0.1, 1.0, 0.1, 0.0, false);
	if(user_exp[id] >= ZP_MAX_EXP)
		show_dhudmessage(id, "[KLASA: %s] [LVL: %d] [EXP: %d]", class_names[user_class[id]], user_level[id], user_exp[id]);
	else
		show_dhudmessage(id, "[KLASA: %s] [LVL: %d] [EXP: %d / %d]", class_names[user_class[id]], user_level[id], user_exp[id], expTable[user_level[id]]);
	
	return PLUGIN_CONTINUE;
}

public TakeDamage(victim, inflictor, attacker, Float:damage, bits) {
	if(!IsPlayer(victim) || !IsPlayer(attacker))
		return HAM_IGNORED;
		
	if(user_class[attacker] == Lowca || user_class[attacker] == Barbazynca) {
		SetHamParamFloat(4, damage+5.0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public RoundStart()
	FreezeTime = false; 
	
public NewRound()
	FreezeTime = true; 

public SetSpeed(id) {
	if(!is_user_alive(id))
		return HAM_IGNORED;
	
	if(FreezeTime)
		return HAM_IGNORED;
	
	if(user_class[id] == Lowca)
		set_user_maxspeed(id, get_user_maxspeed(id)-20);
	
	return HAM_IGNORED;
}

public ChooseClass(id) {
	new menu = menu_create("Wybierz Klase:", "ChooseClass_Handle");
	new class[50];
	for(new i=1; i<sizeof class_names; i++) {
		LoadData(id, i);
		format(class, 49, "\y%s \rPoziom: %i", class_names[i], user_level[id]);
		menu_additem(menu, class);
	}
	
	LoadData(id, user_class[id]);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
}

public ChooseClass_Handle(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}    
	
	item++;
	
	if(item == user_class[id])
		return PLUGIN_CONTINUE;
	
	if(item == Barbazynca && !(get_user_flags(id) & ADMIN_LEVEL_F)) {
		ColorChat(id, GREEN, "[Level System]^x01 Nie masz odpowiednich uprawnien, by korzystac z klasy Premium.");
		ChooseClass(id);
		return PLUGIN_CONTINUE;
	}
	
	if(user_class[id]) {
		new_user_class[id] = item;
		ColorChat(id, GREEN, "[Level System]^x01 Klasa zmieni sie na nowa w kolejnej rundzie.");
	}
	else {
		user_class[id] = item;
		LoadData(id, user_class[id]);
		Spawn(id);
	}
	return PLUGIN_CONTINUE;
}

public ClassDescription(id)
{
	new menu = menu_create("Wybierz Klase:", "ClassDescription_Handle");
	for(new i=1; i<sizeof class_names; i++)
		menu_additem(menu, class_names[i]);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
}

public ClassDescription_Handle(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	ColorChat(id, GREEN, "[Level System]^x01 %s: %s", class_names[item+1], class_descriptions[item+1]);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public SaveData(id) {
	new key[64], data[64];
	format(key, 63, "%s-%i-zm", user_datakey[id], user_class[id]);
	format(data, 63, "%i#%i", user_exp[id], user_level[id]);
	nvault_set(gVault, key, data);
}

public LoadData(id, class) {
	new key[64], data[64];
	format(key, 63, "%s-%i-zm", user_datakey[id], class);
	format(data, 63, "%i#%i", user_exp[id], user_level[id]);
	nvault_get(gVault, key, data, 63);
	replace_all(data, 63, "#", " ");
	new userexp[32], userlevel[32];
	parse(data, userexp, 31, userlevel, 31);
	
	user_exp[id] = str_to_num(userexp);
	user_level[id] = str_to_num(userlevel)>0?str_to_num(userlevel):1;
}

public SetLevel(id, level, target)
{
	if(!cmd_access(id, level, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33];
	new arg2[5];
	read_argv(1,arg1,32);
	read_argv(2,arg2,4);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new level = str_to_num(arg2);
	if(level > sizeof expTable) {
		client_print(id, print_console, "[Level System] Chciales ustawic za duzy poziom!");
		return PLUGIN_HANDLED;
	} 
	
	user_level[player] = level;
	user_exp[player] = expTable[user_level[player]-1];
	CheckLevel(player);
	
	return PLUGIN_HANDLED;
}

public AddExp(id, exp, target)
{
	if(!cmd_access(id, exp, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33];
	new arg2[10];
	read_argv(1,arg1,32);
	read_argv(2,arg2,9);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new exp = str_to_num(arg2);
	
	user_exp[id] += exp;
	CheckLevel(player);
	
	return PLUGIN_HANDLED;
}

public RemoveExp(id, exp, target)
{
	if(!cmd_access(id, exp, target, 3))
		return PLUGIN_HANDLED;
	
	new arg1[33];
	new arg2[10];
	read_argv(1,arg1,32);
	read_argv(2,arg2,9);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new exp = str_to_num(arg2);
	if(user_exp[id] - exp < 0) {
		client_print(id, print_console, "[Level System] Chciales odjac graczowi za duzo expa!")
		return PLUGIN_HANDLED;
	} 
	
	user_exp[id] -= exp;
	CheckLevel(player);
	
	return PLUGIN_HANDLED;
}

public nativeGetUserClass(id)
	return user_class[id];

public nativeGetUserExp(id)
	return user_exp[id];

public nativeSetUserExp(id, iValue) {
	user_exp[id] = iValue;
	CheckLevel(id);
}

public nativeAddUserExp(id, iValue) {
	user_exp[id] += iValue;
	CheckLevel(id);
}

public nativeRemoveUserExp(id, iValue) {
	user_exp[id] -= iValue;
	CheckLevel(id);
}

public nativeGetUserLevel(id)
	return user_level[id];

public nativeSetUserLevel(id, iValue) {
	user_exp[id] = expTable[iValue-1];
	CheckLevel(id);
}
