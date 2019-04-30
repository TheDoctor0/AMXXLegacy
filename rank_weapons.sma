#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <csx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <colorchat>
#include <nvault>

#define PLUGIN "Rank Weapons"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define is_user_player(%1) 1 <= %1 <= g_MaxClients

#define TASK_HUD 342
#define MAX_RANKS 19

new player_auth[33][64], kills[33], rank[33], next_kills[33], models[33], hand[33], bool:selected[33]
new model, gHUDmodel, g_MaxClients

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	model = nvault_open("weapons_models")
	if(model == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku weapon_models.vault")
		
	register_clcmd("say /bronie", "GunsMOTD")
	register_clcmd("sayteam /bronie", "GunsMOTD")
	register_clcmd("say /rangi", "RanksMOTD")
	register_clcmd("sayteam /rangi", "RanksMOTD")
	register_clcmd("say /ranga", "RankPrint")
	register_clcmd("sayteam /ranga", "RankPrint")
	register_clcmd("say /modele", "ChangeModel")
	register_clcmd("sayteam /modele", "ChangeModel")
	register_clcmd("say /zestawy", "ChangeModel")
	register_clcmd("sayteam /zestawy", "ChangeModel")
	register_clcmd("say /lewa", "LeftHand")
	register_clcmd("sayteam /lewa", "LeftHand")
	register_clcmd("say /prawa", "RightHand")
	register_clcmd("sayteam /prawa", "RightHand")
	
	new const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", 
		"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
		"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_mp5navy", "weapon_m249", "weapon_m3", 
		"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_knife", "weapon_p90" }
	
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)	if (g_szWpnEntNames[i][0]) RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "WeaponDeploy", 1)
	
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "WeaponModels", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "WeaponModels2", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_awp", "WeaponModels3", 1)
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0)
	RegisterHam(Ham_Spawn , "player", "Spawn", 1)
	
	register_event("DeathMsg", "DeathMsg", "a")
	
	gHUD = CreateHudSyncObj()
	
	g_MaxClients = get_maxplayers()
}	

public plugin_precache() 
{
	precache_model("models/cs-reload/cs_go/v_awp.mdl")
	precache_model("models/cs-reload/cs_go/v_ak47.mdl")
	precache_model("models/cs-reload/cs_go/v_m4a1.mdl")
	precache_model("models/cs-reload/fire/v_awp.mdl")
	precache_model("models/cs-reload/fire/v_ak47.mdl")
	precache_model("models/cs-reload/fire/v_m4a1.mdl")
	precache_model("models/cs-reload/black/v_awp.mdl")
	precache_model("models/cs-reload/black/v_ak47.mdl")
	precache_model("models/cs-reload/black/v_m4a1.mdl")
	precache_model("models/cs-reload/soldier/v_awp.mdl")
	precache_model("models/cs-reload/soldier/v_ak47.mdl")
	precache_model("models/cs-reload/soldier/v_m4a1.mdl")
	precache_model("models/cs-reload/golden/v_awp.mdl")
	precache_model("models/cs-reload/golden/v_ak47.mdl")
	precache_model("models/cs-reload/golden/v_m4a1.mdl")
	precache_model("models/cs-reload/asiimov/v_awp.mdl")
	precache_model("models/cs-reload/asiimov/v_ak47.mdl")
	precache_model("models/cs-reload/asiimov/v_m4a1.mdl")
}

new const RankName[MAX_RANKS][] = 
{ 
	"Lamus",
	"Wiesniak",
	"Sierota",
	"Cherlak",
	"Poczatkujacy",
	"Doswiadczony",
	"Kozak",
	"Koks",
	"Macho",
	"General",
	"Przywodca",
	"Rambo",
	"Terminator",
	"Owner",
	"Wybraniec",
	"Killer",
	"Kosiarz",
	"Mistrz",
	"Legenda CS-Reload"
}

new const gRankKills[MAX_RANKS] = 
{
	0,
	150,
	500,
	800,
	2500,
	5000,
	8000,
	13000,
	20000,
	28000,
	40000,
	50000,
	60000,
	70000,
	80000,
	90000,
	100000,
	125000,
	150000
}

public GunsMOTD(id)
	show_motd(id, "bronie.txt", "Informacje o Zestawach Broni")
	
public RanksMOTD(id)
	show_motd(id, "rangi.txt", "Lista Dostepnych Rang")

public RankPrint(id)
{
	ColorChat(id, RED, "[RANGA]^x01 Twoja aktualna ranga to:^x04 %s^x01. Do kolejnej rangi potrzebujesz^x04 %i^x01 zabic.", RankName[rank[id]], next_kills[id]-kills[id])
	return PLUGIN_CONTINUE
}

public LeftHand(id)
{
	hand[id] = 1
	SaveModels(id)
	ColorChat(id, RED, "[MODELE]^x01 Wybrales modele w^x04 lewej^x01 rece.")
	cmdExecute(id, "cl_righthand 0")
	return PLUGIN_CONTINUE
}

public RightHand(id)
{
	hand[id] = 0
	SaveModels(id)
	ColorChat(id, RED, "[MODELE]^x01 Wybrales modele w^x04 prawej^x01 rece.")
	cmdExecute(id, "cl_righthand 1")
	return PLUGIN_CONTINUE
}

public ChangeModel(id)
{
	new menu = menu_create("\wWybierz \rzestaw \wlub \ywylacz\w pokazywanie modeli:", "ChangeModel_Handler")
	new menu_callback = menu_makecallback("ChangeModel_Callback")
	menu_additem(menu, "\wZestaw \yCS:GO", "1", 0, menu_callback)
	menu_additem(menu, "\wZestaw \yPlonacy", "2", 0, menu_callback)
	menu_additem(menu, "\wZestaw \yKrwawy", "3", 0, menu_callback)
	menu_additem(menu, "\wZestaw \yWojskowy", "4", 0, menu_callback)
	menu_additem(menu, "\wZestaw \yZloty", "5", 0, menu_callback)
	menu_additem(menu, "\wZestaw \yAsiimov", "6", 0, menu_callback)
	menu_additem(menu, "\rWylacz \wModele", "7", 0, menu_callback)
	menu_addtext(menu, "\yWybrany zestaw zostanie zapisany.", 6)
	menu_addtext(menu, "\yBy go zmienic nalezy skorzystac z tego menu.", 6)
	menu_addtext(menu, "\yAby ponownie wlaczyc modele wystarczy wybrac dowolny zestaw.", 6)
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie")
	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public ChangeModel_Callback(id, menu, item)
{
	switch(item+1)
	{
		case 1: 
		{
			if(kills[id] >= 500 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
		case 2: 
		{
			if(kills[id] >= 1500 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
		case 3: 
		{
			if(kills[id] >= 3000 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
		case 4: 
		{
			if(kills[id] >= 5000 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
		case 5: 
		{
			if(kills[id] >= 7500 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
		case 6: 
		{
			if(kills[id] >= 10000 || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED
			else	return ITEM_DISABLED
		}
	}
	return ITEM_ENABLED;
}

public ChangeModel_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[6], name[64], acces, callback
	menu_item_getinfo(menu, item, acces, data, 5, name, 63, callback)
	
	new key = str_to_num(data)
	switch(key)
	{
	case 1: 
		{
			models[id] = 1
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 CS:GO^x01 jako zestaw broni.")
		}
	case 2: 
		{
			models[id] = 2
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 Plonacy^x01 jako zestaw broni.")
		}
	case 3: 
		{
			models[id] = 3
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 Krwawy^x01 jako zestaw broni.")
		}
	case 4: 
		{
			models[id] = 4
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 Wojskowy^x01 jako zestaw broni.")
		}
	case 5: 
		{
			models[id] = 5
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 Zloty^x01 jako zestaw broni.")
		}
	case 6: 
		{
			models[id] = 6
			ColorChat(id, RED, "[MODELE]^x01 Wybrales^x04 Asiimov^x01 jako zestaw broni.")
		}
	case 7: 
		{
			models[id] = 0
			ColorChat(id, RED, "[MODELE]^x01 Modele broni zostaly^x04 wylaczone^x01.")
		}
	}
	selected[id] = true
	return PLUGIN_HANDLED
}

public LoadKills(id)
{
	if(is_user_connected(id))
	{
		new stats[8], bodyhits[8]
		get_user_stats(id, stats, bodyhits)
		kills[id] = stats[0]
		CheckKills(id)
	}
}

public CheckKills(id)
{	
	if(!rank[id])
	{
		for (new counter = 0; counter < MAX_RANKS; counter++) 
		{
			if (kills[id] >= floatround(gRankKills[counter]*0.1))
				rank[id] = counter
			else 
				break
		}
	}
	else 
	{
		if(kills[id] >= next_kills[id])
			rank[id]++;
	}
	next_kills[id] = floatround(gRankKills[rank[id]+1] * 0.1)
	
	if(selected[id])
		return PLUGIN_CONTINUE
	
	if(kills[id] >= 500 && kills[id] < 1500)
		models[id] = 1
	else if(kills[id] >= 1500 && kills[id] < 3000)
		models[id] = 2
	else if(kills[id] >= 3000 && kills[id] < 5000)
		models[id] = 3
	else if(kills[id] >= 3000 && kills[id] < 5000)
		models[id] = 4
	else if(kills[id] >= 5000 && kills[id] < 7500)
		models[id] = 5
	else if(kills[id] >= 10000)
		models[id] = 6
		
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	get_user_name(id, player_auth[id], 63)
	LoadModels(id)
	set_task(0.5, "DisplayHUD", id+TASK_HUD, .flags="b")
}
	
public client_disconnect(id)
{
	if(selected[id]) 
		SaveModels(id)
	remove_task(id+TASK_HUD)
	rank[id] = 0
	kills[id] = 0
	next_kills[id] = 0
	hand[id] = 0
	models[id] = 0
	selected[id] = false
}

public Spawn(id)
{
	if(!task_exists(id+TASK_HUD))
		set_task(0.5, "DisplayHUD", id+TASK_HUD, .flags="b")
	if(!kills[id])
		LoadKills(id)
}

public DisplayHUD(id) 
{
	id -= TASK_HUD

	if (is_user_bot(id) || !is_user_connected(id))
	return PLUGIN_CONTINUE

	if(!is_user_alive(id)) 
	{
		new target = pev(id, pev_iuser2)
		
		if(!target)
		return PLUGIN_CONTINUE
		
		set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.6, 0.0, 0.0, 3)
		ShowSyncHudMsg(id, gHUD,"[Ranga]: %s^n[Zabicia]: %d/%d^n[Forum]: CS-Reload.pl", RankName[rank[target]], kills[target], next_kills[target])
	}
	else 
	{
		if(!kills[id]){
			static stats[8], bodyhits[8]
			get_user_stats(id, stats, bodyhits)
			kills[id] = stats[0]
			CheckKills(id)
		}
		
		set_hudmessage(0, 255, 0, 0.01, 0.85, 0, 0.0, 0.6, 0.0, 0.0, 3)
		ShowSyncHudMsg(id, gHUD,"[Ranga]: %s || [Zabicia]: %d/%d || [Forum]: CS-Reload.pl", RankName[rank[id]], kills[id], next_kills[id])
	}
	return PLUGIN_CONTINUE
}

public DeathMsg()
{
	new killer = read_data(1)
	new victim = read_data(2)
	
	if(is_user_connected(killer) && killer != victim)
	{
		kills[killer]++
		CheckKills(killer)
	}
}

public bomb_explode(planter, defuser) 
{
	kills[planter] += 3
	CheckKills(planter)
}

public bomb_defused(defuser)
{
	kills[defuser] += 3
	CheckKills(defuser)
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker) || !is_user_connected(this) || get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED
	
	if(kills[idattacker] >= 500 && kills[idattacker] < 1500)
	{
		SetHamParamFloat(4, damage + 1.0)
		return HAM_HANDLED
	}
	else if(kills[idattacker] >= 1500 && kills[idattacker] < 3000)
	{
		SetHamParamFloat(4, damage + 2.0)
		return HAM_HANDLED
	}
	else if(kills[idattacker] >= 3000 && kills[idattacker] < 5000)
	{
		SetHamParamFloat(4, damage + 3.0)
		return HAM_HANDLED
	}
	else if(kills[idattacker] >= 5000 && kills[idattacker] < 7500)
	{
		SetHamParamFloat(4, damage + 4.0)
		return HAM_HANDLED
	}
	else if(kills[idattacker] >= 7500 && kills[idattacker] < 10000)
	{
		SetHamParamFloat(4, damage + 5.0)
		return HAM_HANDLED
	}
	else if(kills[idattacker] >= 10000)
	{
		SetHamParamFloat(4, damage + 6.0)
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public WeaponModels(wpn)
{
	static id
	id = pev(wpn, pev_owner)
		
	if(is_user_player(id))
	{
		switch(models[id])
		{
			case 1: set_pev(id, pev_viewmodel2, "models/cs-reload/cs_go/v_m4a1.mdl")
			case 2: set_pev(id, pev_viewmodel2, "models/cs-reload/fire/v_m4a1.mdl")
			case 3: set_pev(id, pev_viewmodel2, "models/cs-reload/black/v_m4a1.mdl")
			case 4: set_pev(id, pev_viewmodel2, "models/cs-reload/soldier/v_m4a1.mdl")
			case 5: set_pev(id, pev_viewmodel2, "models/cs-reload/golden/v_m4a1.mdl")
			case 6: set_pev(id, pev_viewmodel2, "models/cs-reload/asiimov/v_m4a1.mdl")
		}
		if(models[id] == 4)
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 1")
			else
				cmdExecute(id, "cl_righthand 0")
		}
		else
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 0")
			else
				cmdExecute(id, "cl_righthand 1")
		}
	}
}

public WeaponModels2(wpn)
{
	static id
	id = pev(wpn, pev_owner)
		
	if(is_user_player(id))
	{
		switch(models[id])
		{
			case 1: set_pev(id, pev_viewmodel2, "models/cs-reload/cs_go/v_ak47.mdl")
			case 2: set_pev(id, pev_viewmodel2, "models/cs-reload/fire/v_ak47.mdl")
			case 3: set_pev(id, pev_viewmodel2, "models/cs-reload/black/v_ak47.mdl")
			case 4: set_pev(id, pev_viewmodel2, "models/cs-reload/soldier/v_ak47.mdl")
			case 5: set_pev(id, pev_viewmodel2, "models/cs-reload/golden/v_ak47.mdl")
			case 6: set_pev(id, pev_viewmodel2, "models/cs-reload/asiimov/v_ak47.mdl")
		}
		if(models[id] == 4)
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 1")
			else
				cmdExecute(id, "cl_righthand 0")
		}
		else
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 0")
			else
				cmdExecute(id, "cl_righthand 1")
		}
	}
}

public WeaponModels3(wpn)
{
	static id
	id = pev(wpn, pev_owner)
		
	if(is_user_player(id))
	{
		switch(models[id])
		{
			case 1: set_pev(id, pev_viewmodel2, "models/cs-reload/cs_go/v_awp.mdl")
			case 2: set_pev(id, pev_viewmodel2, "models/cs-reload/fire/v_awp.mdl")
			case 3: set_pev(id, pev_viewmodel2, "models/cs-reload/black/v_awp.mdl")
			case 4: set_pev(id, pev_viewmodel2, "models/cs-reload/soldier/v_awp.mdl")
			case 5: set_pev(id, pev_viewmodel2, "models/cs-reload/golden/v_awp.mdl")
			case 6: set_pev(id, pev_viewmodel2, "models/cs-reload/asiimov/v_awp.mdl")
		}
		if(models[id] == 4)
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 1")
			else
				cmdExecute(id, "cl_righthand 0")
		}
		else
		{
			if(hand[id])
				cmdExecute(id, "cl_righthand 0")
			else
				cmdExecute(id, "cl_righthand 1")
		}
	}
}

public WeaponDeploy(wpn)
{
	static id
	id = pev(wpn, pev_owner)
	
	if(is_user_player(id))
	{
		if(hand[id])
			cmdExecute(id, "cl_righthand 0")
		else
			cmdExecute(id, "cl_righthand 1")
	}
}

public SaveModels(id)
{
	new vaultkey[64], vaultdata[10]
	formatex(vaultkey, 63, "%s-player_model", player_auth[id])
	formatex(vaultdata, 9, "%d#%d", models[id], hand[id])
	nvault_set(model, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE
}

public LoadModels(id)
{
	new vaultkey[64], vaultdata[4]
	formatex(vaultkey, 63, "%s-player_model", player_auth[id])
	formatex(vaultdata, 2, "%d#%d", models[id])
	if(nvault_get(model, vaultkey, vaultdata, 63))
	{
		replace_all(vaultdata, 3, "#", " ")
		new saved[2], saved2[2]
		parse(vaultdata, saved, 1, saved2, 1)
		models[id] = str_to_num(saved)
		hand[id] = str_to_num(saved2)
		selected[id] = true
	}
	return PLUGIN_CONTINUE
} 

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args( szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}