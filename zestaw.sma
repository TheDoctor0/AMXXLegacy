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

enum
{
	WYLACZONE = -1,
	PLONACY = 0,
	KRWAWY = 1,
};

new const v_M4A1Models[][] =
{
	"models/cs-reload/fire/v_m4a1.mdl",
	"models/cs-reload/black/v_m4a1.mdl"
};

new const v_AK47Models[][] =
{
	"models/cs-reload/fire/v_ak47.mdl",
	"models/cs-reload/black/v_ak47.mdl"
};

new const v_AWPModels[][] =
{
	"models/cs-reload/fire/v_awp.mdl",
	"models/cs-reload/black/v_awp.mdl"
};

new szName[33][64], iModels[33], bool:bSelected[33];

new vModel, g_MaxClients;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	vModel = nvault_open("weapons_models");
	if(vModel == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku weapon_models.vault");
		
	register_clcmd("say /bronie", "GunsMOTD");
	
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

public plugin_precache() 
{
	for(new i = 0; i < sizeof v_M4A1Models; i++)
		precache_model(v_M4A1Models[i]);

	for(new i = 0; i < sizeof v_AK47Models; i++)
		precache_model(v_AK47Models[i]);
		
	for(new i = 0; i < sizeof v_AWPModels; i++)
		precache_model(v_AK47Models[i]);
}

public client_putinserver(id)
{
	iModels[id] = -1;
	bSelected[id] = false;
	
	get_user_name(id, szName[id], charsmax(szName));
	
	LoadModels(id);
}
	
public client_disconnect(id)
{
	iModels[id] = -1;
	bSelected[id] = false;
}

public GunsMOTD(id)
	show_motd(id, "bronie.txt", "Informacje o Zestawach Broni");

public ChangeModel(id)
{
	new menu = menu_create("\wWybierz \rzestaw \wlub \ywylacz\w pokazywanie modeli:", "ChangeModel_Handler");
	new menu_callback = menu_makecallback("ChangeModel_Callback");
	
	menu_additem(menu, "\wZestaw \yPlonacy", _, _, menu_callback);
	menu_additem(menu, "\wZestaw \yKrwawy", _, _, menu_callback);
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
		case 0: 
		{
			if(stats[0] >= 500 || (get_user_flags(id) & ADMIN_ADMIN))	
				return ITEM_ENABLED;
		}
		case 1: 
		{
			if(stats[0] >= 1000 || (get_user_flags(id) & ADMIN_ADMIN))	
				return ITEM_ENABLED;
		}
		case 2: return ITEM_ENABLED;
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
			iModels[id] = PLONACY;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Plonacy^x01 zestaw broni.");
		}
		case 1: 
		{
			iModels[id] = KRWAWY;
			ColorChat(id, RED, "[ZESTAW]^x01 Wybrales^x04 Krwawy^x01 zestaw broni.");
		}
		case 2: 
		{
			iModels[id] = WYLACZONE;
			ColorChat(id, RED, "[ZESTAW]^x01 Modele broni zostaly^x04 wylaczone^x01.");
		}
	}
	
	SaveModels(id);
	
	bSelected[id] = true;
	
	return PLUGIN_HANDLED;
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker) || !is_user_connected(this) || get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
		
	new stats[8], bodyhits[8];
	get_user_stats(idattacker, stats, bodyhits);
	
	if(stats[0] >= 500 && stats[0] < 1000)
	{
		SetHamParamFloat(4, damage + 1.0);
		return HAM_HANDLED;
	}
	else if(stats[0] >= 1000)
	{
		SetHamParamFloat(4, damage + 2.0);
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
		switch(iModels[id])
		{
			case PLONACY: set_pev(id, pev_viewmodel2, v_M4A1Models[PLONACY]);
			case KRWAWY: set_pev(id, pev_viewmodel2, v_M4A1Models[KRWAWY]);
		}
	}
}

public AK47Model(weapon)
{
	static id;
	id = pev(weapon, pev_owner);
		
	if(is_user_player(id))
	{
		switch(iModels[id])
		{
			case PLONACY: set_pev(id, pev_viewmodel2, v_AK47Models[PLONACY]);
			case KRWAWY: set_pev(id, pev_viewmodel2, v_AK47Models[KRWAWY]);
		}
	}
}

public AWPModel(weapon)
{
	static id;
	id = pev(weapon, pev_owner);
		
	if(is_user_player(id))
	{
		switch(iModels[id])
		{
			case PLONACY: set_pev(id, pev_viewmodel2, v_AWPModels[PLONACY]);
			case KRWAWY: set_pev(id, pev_viewmodel2, v_AWPModels[KRWAWY]);
		}
	}
}

public SaveModels(id)
{
	new szVaultKey[64], szVaultData[4];
	
	formatex(szVaultKey, 63, "%s-zestawy", szName[id]);
	formatex(szVaultData, 3, "%d", iModels[id]);
	
	nvault_set(vModel, szVaultKey, szVaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadModels(id)
{
	new szVaultKey[64], szVaultData[4];
	
	formatex(szVaultKey, 63, "%s-zestawy", szName[id]);
	formatex(szVaultData, 3, "%d", iModels[id]);
	
	if(nvault_get(vModel, szVaultKey, szVaultData, 63))
	{
		new szSaved[2];
		parse(szVaultData, szSaved, 1);
		
		iModels[id] = str_to_num(szSaved);
		bSelected[id] = true;
	}
	
	return PLUGIN_CONTINUE;
} 