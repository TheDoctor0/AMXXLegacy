#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <ColorChat>

#define Plugin "Sell Weapons"
#define Version "1.5"
#define Author "Doombringer & O'Zone"

#define MAX_WEAPONS 33

new const g_prices[MAX_WEAPONS][] = {
	"0",
	"600",
	"0",
	"2750",
	"0",
	"3000",
	"0",
	"1400",
	"3500",
	"0",
	"800",
	"750",
	"1700",
	"4200",
	"2000",
	"2250",
	"500",
	"400",
	"4750",
	"1500",
	"5750",
	"1700",
	"3100",
	"1250",
	"5000",
	"0",
	"650",
	"3500",
	"2500",
	"0",
	"2350",
	"0",
	"0"
}

new cvar, buyzone, annonce, divide, g_Round
public plugin_init()
{
	register_plugin(Plugin, Version, Author)
	
	register_clcmd("say /sprzedaj", "cmd_sell")
	register_clcmd("say_team /sprzedaj", "cmd_sell")
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	
	cvar = register_cvar("SW_enabled", "1")
	buyzone = register_cvar("SW_buyzone", "0")
	annonce = register_cvar("SW_annonce", "240")
	divide = register_cvar("SW_divide", "2")
	
	if(get_pcvar_num(annonce) > 1)
		set_task(get_pcvar_float(annonce), "print_annonce",_,_,_,"b")
}

public print_annonce()
{
	if(get_pcvar_num(annonce) < 1 || get_playersnum() < 1)
	return PLUGIN_CONTINUE
	
	ColorChat(0, GREEN, "Chcesz sprzedac swoja bron? Wpisz^x03 /sprzedaj")
	return PLUGIN_CONTINUE //Continue...
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) { // http://forums.alliedmods.net/showthread.php?t=28284
	new strtype[11] = "classname", ent = index
	switch (jghgtype) {
		case 1: copy(strtype, 6, "target")
		case 2: copy(strtype, 10, "targetname")
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent
}

stock bool:fm_strip_user_gun(index, wid = 0, const wname[] = "") { // http://forums.alliedmods.net/showthread.php?t=28284
	new ent_class[32]
	if (!wid && wname[0])
		copy(ent_class, 31, wname)
	else {
		new weapon = wid, clip, ammo
		if (!weapon && !(weapon = get_user_weapon(index, clip, ammo)))
			return false
		
		get_weaponname(weapon, ent_class, 31)
	}

	new ent_weap = fm_find_ent_by_owner(-1, ent_class, index)
	if (!ent_weap)
		return false

	engclient_cmd(index, "drop", ent_class)

	new ent_box = pev(ent_weap, pev_owner)
	if (!ent_box || ent_box == index)
		return false

	dllfunc(DLLFunc_Think, ent_box)

	return true
}

public cmd_sell(id)
{
	if(get_pcvar_num(cvar) < 1)
	return PLUGIN_CONTINUE
	
	if(get_pcvar_num(buyzone) == 1 && cs_get_user_buyzone(id) == 0)
	{
		ColorChat(id, RED, "[SPRZEDAJ]^x01 Musisz byc w BuyZone, by sprzedac bron!")
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(id))
	{
		ColorChat(id, RED, "[SPRZEDAJ]^x01 Musisz byc zywy, by sprzedac bron!")
		return PLUGIN_HANDLED
	}
	
	if(g_Round < 2)
	{
		ColorChat(id, RED, "[SPRZEDAJ]^x01 Sprzedaz broni w pierwszej rundzie jest zabroniona!")
		return PLUGIN_HANDLED
	}
	
	new temp, weapon = get_user_weapon(id, temp, temp)
	new price = str_to_num(g_prices[weapon])
	
	if(price == 0)
	{
		ColorChat(id, RED, "[SPRZEDAJ]^x01 Nie mozesz tego sprzedac!")
		return PLUGIN_HANDLED
	}
	
	new weaponname[32]
	get_weaponname(weapon, weaponname, 31)

	new oldmoney = cs_get_user_money(id)
	new cash = clamp(oldmoney + (price / get_pcvar_num(divide)), 0, 16000)
	
	fm_strip_user_gun(id, weapon)
	cs_set_user_money(id, cash)
	
	ColorChat(id, RED, "[SPRZEDAJ]^x01 Dostales^x04 %d$^x01 za sprzedanie^x04 %s^x01!", cs_get_user_money(id) - oldmoney, weaponname[7])
	return PLUGIN_HANDLED
}

public GameCommencing()
	g_Round = 0

public event_new_round()
	g_Round++