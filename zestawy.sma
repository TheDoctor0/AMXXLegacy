#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <csx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <colorchat>
#include <nvault>

#define PLUGIN "Weapon Models"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define is_user_player(%1) 1 <= %1 <= g_MaxClients

#define MAX_PLAYERS 32

enum
{
	CSGO = 0,
	ORLI = 1,
	MOTYLKOWY = 2,
	GALAXY = 3,
	ELITARNY = 4,
	WYLACZONE = 5,
	WYBRANY = 6
};

new const v_M4A1Models[][] =
{
	"models/cs-reload/csgo/v_m4a1.mdl",
	"models/cs-reload/orli/v_m4a1.mdl",
	"models/cs-reload/motylkowy/v_m4a1.mdl",
	"models/cs-reload/galaxy/v_m4a1.mdl",
	"models/cs-reload/elitarny/v_m4a1.mdl"
};

new const v_AK47Models[][] =
{
	"models/cs-reload/csgo/v_ak47.mdl",
	"models/cs-reload/orli/v_ak47.mdl",
	"models/cs-reload/motylkowy/v_ak47.mdl",
	"models/cs-reload/galaxy/v_ak47.mdl",
	"models/cs-reload/elitarny/v_ak47.mdl"
};

new const v_AWPModels[][] =
{
	"models/cs-reload/csgo/v_awp.mdl",
	"models/cs-reload/orli/v_awp.mdl",
	"models/cs-reload/motylkowy/v_awp.mdl",
	"models/cs-reload/galaxy/v_awp.mdl",
	"models/cs-reload/elitarny/v_awp.mdl"
};

new szName[MAX_PLAYERS + 1][64], iModels[MAX_PLAYERS + 1][WYBRANY + 1];

new vModel, g_MaxClients;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	vModel = nvault_open("weapons_models");
	
	if(vModel == INVALID_HANDLE) set_fail_state("Nie mozna otworzyc pliku weapon_models.vault");

	register_clcmd("say /bronie", "GunsMOTD");
	register_clcmd("say /wymagania", "GunsMOTD");
	
	register_clcmd("say /modele", "ChangeModel");
	register_clcmd("say /model", "ChangeModel");
	
	register_clcmd("say /zestaw", "ChangeModel");
	register_clcmd("say /zestawy", "ChangeModel");
	
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "M4A1Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "AK47Model", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_awp", "AWPModel", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	
	g_MaxClients = get_maxplayers();
}	

public plugin_natives()
{
	register_native("dodaj_zestaw", "AddModels");
	register_native("sprawdz_zestaw", "CheckModels");
}

public plugin_precache() 
{
	for(new i = 0; i < sizeof v_M4A1Models; i++) precache_model(v_M4A1Models[i]);

	for(new i = 0; i < sizeof v_AK47Models; i++) precache_model(v_AK47Models[i]);

	for(new i = 0; i < sizeof v_AWPModels; i++) precache_model(v_AWPModels[i]);
}

public client_putinserver(id)
{
	iModels[id][WYBRANY] = WYLACZONE;
	iModels[id][CSGO] = 0;
	iModels[id][ORLI] = 0;
	iModels[id][MOTYLKOWY] = 0;
	iModels[id][GALAXY] = 0;
	iModels[id][ELITARNY] = 0;
	
	get_user_name(id, szName[id], charsmax(szName));
	
	LoadModels(id);
}
	
public client_disconnect(id)
{
	iModels[id][WYBRANY] = WYLACZONE;
	iModels[id][CSGO] = 0;
	iModels[id][ORLI] = 0;
	iModels[id][MOTYLKOWY] = 0;
	iModels[id][GALAXY] = 0;
	iModels[id][ELITARNY] = 0;
}

public GunsMOTD(id)
	show_motd(id, "bronie.txt", "Informacje o Zestawach Broni");

public ChangeModel(id)
{
	new menu = menu_create("\wWybierz \rzestaw \wlub \ywylacz\w pokazywanie modeli:", "ChangeModel_Handler");
	new menu_callback = menu_makecallback("ChangeModel_Callback");
	
	menu_additem(menu, "\wZestaw \yCS:GO", _, _, menu_callback);
	menu_additem(menu, "\wZestaw \yOrli", _, _, menu_callback);
	menu_additem(menu, "\wZestaw \yMotylkowy", _, _, menu_callback);
	menu_additem(menu, "\wZestaw \yGalaxy", _, _, menu_callback);
	menu_additem(menu, "\wZestaw \yElitarny", _, _, menu_callback);
	menu_additem(menu, "\rWylacz \wModele", _, _, menu_callback);
	
	menu_addtext(menu, "^n\yWybrany zestaw zostanie \rzapisany\y.", 2);
	menu_addtext(menu, "\yBy go \rzmienic \ynalezy skorzystac z tego menu.", 2);
	menu_addtext(menu, "\yAby ponownie \rwlaczyc modele \ywystarczy wybrac dowolny zestaw.", 2);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ChangeModel_Callback(id, menu, item)
{
	new stats[8], bodyhits[8];
	get_user_stats(id, stats, bodyhits);
	
	switch(item)
	{
		case 0: if(stats[0] >= 800 || iModels[id][CSGO] || (get_user_flags(id) & ADMIN_ADMIN)) return ITEM_ENABLED;
		case 1: if(stats[0] >= 1500 || iModels[id][ORLI] || (get_user_flags(id) & ADMIN_ADMIN)) return ITEM_ENABLED;
		case 2: if(stats[0] >= 2500 || iModels[id][MOTYLKOWY] || (get_user_flags(id) & ADMIN_ADMIN))	return ITEM_ENABLED;
		case 3: if(stats[0] >= 3500 || iModels[id][GALAXY] || (get_user_flags(id) & ADMIN_ADMIN)) return ITEM_ENABLED;
		case 4: if(stats[0] >= 5000 || iModels[id][ELITARNY] || (get_user_flags(id) & ADMIN_ADMIN)) return ITEM_ENABLED;

		case 5: return ITEM_ENABLED;
	}
	
	return ITEM_DISABLED;
}

public ChangeModel_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: 
		{
			iModels[id][WYBRANY] = CSGO;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 CS:GO^x01 zestaw broni.");
		}
		case 1: 
		{
			iModels[id][WYBRANY] = ORLI;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Orli^x01 zestaw broni.");
		}
		case 2: 
		{
			iModels[id][WYBRANY] = MOTYLKOWY;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Motylkowy^x01 zestaw broni.");
		}
		case 3: 
		{
			iModels[id][WYBRANY] = GALAXY;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Galaxy^x01 zestaw broni.");
		}
		case 4: 
		{
			iModels[id][WYBRANY] = ELITARNY;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Elitarny^x01 zestaw broni.");
		}
		case 5: 
		{
			iModels[id][WYBRANY] = WYLACZONE;
			ColorChat(id, RED, "[ZESTAW]^x01 Modele broni zostaly^x04 wylaczone^x01.");
		}
	}
	
	SaveModels(id);
	
	return PLUGIN_HANDLED;
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker) || !is_user_connected(this) || get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
		
	new stats[8], bodyhits[8];
	get_user_stats(idattacker, stats, bodyhits);
	
	if((stats[0] >= 800 && stats[0] < 1500) || iModels[idattacker][WYBRANY] == CSGO)
	{
		SetHamParamFloat(4, damage + 2.0);
		return HAM_HANDLED;
	}
	else if((stats[0] >= 1500 && stats[0] < 2500) || iModels[idattacker][WYBRANY] == ORLI)
	{
		SetHamParamFloat(4, damage + 3.0);
		return HAM_HANDLED;
	}
	else if((stats[0] >= 2500 && stats[0] < 3500) || iModels[idattacker][WYBRANY] == MOTYLKOWY)
	{
		SetHamParamFloat(4, damage + 4.0);
		return HAM_HANDLED;
	}
	else if((stats[0] >= 3500 && stats[0] < 5000) || iModels[idattacker][WYBRANY] == GALAXY)
	{
		SetHamParamFloat(4, damage + 5.0);
		return HAM_HANDLED;
	}
	else if(stats[0] >= 5000 || iModels[idattacker][WYBRANY] == ELITARNY)
	{
		SetHamParamFloat(4, damage + 6.0);
		return HAM_HANDLED;
	}
	
	
	return HAM_IGNORED;
}

public M4A1Model(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id))
	{
		switch(iModels[id][WYBRANY])
		{
			case CSGO: set_pev(id, pev_viewmodel2, v_M4A1Models[CSGO]);
			case ORLI: set_pev(id, pev_viewmodel2, v_M4A1Models[ORLI]);
			case MOTYLKOWY: set_pev(id, pev_viewmodel2, v_M4A1Models[MOTYLKOWY]);
			case GALAXY: set_pev(id, pev_viewmodel2, v_M4A1Models[GALAXY]);
			case ELITARNY: set_pev(id, pev_viewmodel2, v_M4A1Models[ELITARNY]);
		}
	}
}

public AK47Model(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id))
	{
		switch(iModels[id][WYBRANY])
		{
			case CSGO: set_pev(id, pev_viewmodel2, v_AK47Models[CSGO]);
			case ORLI: set_pev(id, pev_viewmodel2, v_AK47Models[ORLI]);
			case MOTYLKOWY: set_pev(id, pev_viewmodel2, v_AK47Models[MOTYLKOWY]);
			case GALAXY: set_pev(id, pev_viewmodel2, v_AK47Models[GALAXY]);
			case ELITARNY: set_pev(id, pev_viewmodel2, v_AK47Models[ELITARNY]);
		}
	}
}

public AWPModel(weapon)
{
	static id;
	id = pev(weapon, pev_owner);

	if(is_user_player(id))
	{
		switch(iModels[id][WYBRANY])
		{
			case CSGO: set_pev(id, pev_viewmodel2, v_AWPModels[CSGO]);
			case ORLI: set_pev(id, pev_viewmodel2, v_AWPModels[ORLI]);
			case MOTYLKOWY: set_pev(id, pev_viewmodel2, v_AWPModels[MOTYLKOWY]);
			case GALAXY: set_pev(id, pev_viewmodel2, v_AWPModels[GALAXY]);
			case ELITARNY: set_pev(id, pev_viewmodel2, v_AWPModels[ELITARNY]);
		}
	}
}

public SaveModels(id)
{
	new szVaultKey[64], szVaultData[64];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-zestaw", szName[id]);
	formatex(szVaultData, charsmax(szVaultData), "%d %i %i %i %i %i", iModels[id][WYBRANY], iModels[id][CSGO], iModels[id][ORLI], iModels[id][MOTYLKOWY], iModels[id][GALAXY], iModels[id][ELITARNY]);
	
	nvault_set(vModel, szVaultKey, szVaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadModels(id)
{
	new szVaultKey[64], szVaultData[64];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-zestaw", szName[id]);
	
	if(nvault_get(vModel, szVaultKey, szVaultData, charsmax(szVaultData)))
	{
		new szSaved[6][6];

		parse(szVaultData, szSaved[0], charsmax(szSaved), szSaved[1], charsmax(szSaved), szSaved[2], charsmax(szSaved), szSaved[3], charsmax(szSaved), szSaved[4], charsmax(szSaved), szSaved[5], charsmax(szSaved));

		iModels[id][WYBRANY] = str_to_num(szSaved[0]);
		iModels[id][CSGO] = str_to_num(szSaved[1]);
		iModels[id][ORLI] = str_to_num(szSaved[2]);
		iModels[id][MOTYLKOWY] = str_to_num(szSaved[3]);
		iModels[id][GALAXY] = str_to_num(szSaved[4]);
		iModels[id][ELITARNY] = str_to_num(szSaved[5]);
	}
	
	return PLUGIN_CONTINUE;
}

public AddModels(iPlugin, iParams)
{
	if(iParams != 2) return;

	new id = get_param(1);
	
	for(new i = 0; i <= get_param(2); i++) iModels[id][i] = 1;

	SaveModels(id);
}

public CheckModels(iPlugin, iParams)
{
	if(iParams != 2) return PLUGIN_CONTINUE;
		
	return iModels[get_param(1)][get_param(2)];
}