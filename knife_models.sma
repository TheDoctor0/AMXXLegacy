#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

#define PLUGIN "Knife Models"
#define VERSION "1.5"
#define AUTHOR "O'Zone"

#define MAX_ITEMS 8
#define EXIT "-1"

new const szMenuCommands[][] = { "say /noz", "say_team /noz", "say /noze", "say_team /noze", "say /knife", "say_team /knife", 
"say /knifes", "say_team /knifes", "say /kosa", "say_team /kosa", "say /kosy", "say_team /kosy" };

new szPlayer[33][64], iPlayerKnife[33];

new iKnife; 

new Array:aNames, Array:aTitles, Array:aModels, Array:aFlags;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "KnifeModel", 1);
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	
	for(new i; i < sizeof szMenuCommands; i++) register_clcmd(szMenuCommands[i], "ChangeKnife");
	
	iKnife = nvault_open("knife");
	
	if(iKnife == INVALID_HANDLE) set_fail_state("[KNIFE] Nie mozna otworzyc pliku knife.vault");
}	

public plugin_precache()
{
	aNames = ArrayCreate(64, 1);
	aTitles = ArrayCreate(64, 1);
	aModels = ArrayCreate(64, 1);
	aFlags = ArrayCreate(64, 1);
	
	new szFile[128]; 
	
	get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
	format(szFile, charsmax(szFile), "%s/knife_models.ini", szFile);
	
	if(!file_exists(szFile)) set_fail_state("[KNIFE] Brak pliku knife_models.ini!");
	
	new szContent[256], szName[64], szTitle[64], szModel[64], szFlags[64], iOpen = fopen(szFile, "r");
	
	while(!feof(iOpen))
	{
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
		if(!szContent[0] || szContent[0] == ';' || szContent[0] == '^0') continue;

		parse(szContent, szName, charsmax(szName), szTitle, charsmax(szTitle), szModel, charsmax(szModel), szFlags, charsmax(szFlags));
		
		if(!file_exists(szModel))
		{
			log_amx("[KNIFE] Plik %s nie istnieje!", szModel);
			
			continue;
		}
		
		ArrayPushString(aNames, szName);
		ArrayPushString(aTitles, szTitle);
		ArrayPushString(aModels, szModel);
		ArrayPushString(aFlags, szFlags);
		
		precache_model(szModel);
	}
	
	fclose(iOpen);
}

public plugin_end()
	nvault_close(iKnife);

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return;

	iPlayerKnife[id] = 0;
	
	LoadKnife(id);
}
	
public Spawn(id)
	SetModel(id);

public ChangeKnife(id)
{
	new menu = menu_create("\wWybierz\r Model Noza\w:", "ChangeKnife_Handler");
	
	new szTitle[64], szFlags[64];
	
	for(new i = ArraySize(aTitles) - 1; i >= 0; i--)
	{
		ArrayGetString(aTitles, i, szTitle, charsmax(szTitle));
		ArrayGetString(aFlags, i, szFlags, charsmax(szFlags));
		
		menu_additem(menu, szTitle, "", read_flags(szFlags));
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	if(ArraySize(aTitles) == MAX_ITEMS)
	{
		menu_addblank(menu, 1);
		
		menu_additem(menu, "Wyjscie", EXIT);
		
		menu_setprop(menu, MPROP_PERPAGE, 0);
	}
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public ChangeKnife_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[64], szData[3], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	
	if(equal(szData, EXIT))
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	item = ArraySize(aTitles) - item - 1;
    
	ArrayGetString(aNames, item, szName, charsmax(szName));
	
	iPlayerKnife[id] = item;
	
	SaveKnife(id);
	SetModel(id);
	
	client_print_color(id, print_team_red, "^x03[KNIFE]^x01 Wybrales model:^x04 %s^x01.", szName);
	
	menu_destroy(menu);

	ChangeKnife(id);
	
	return PLUGIN_HANDLED;
}

public KnifeModel(weapon)
{
	static iOwner;
	iOwner = pev(weapon, pev_owner);

	SetModel(iOwner, 0);
	
	return PLUGIN_CONTINUE;
}

SetModel(id, check = 1)
{
	if(!is_user_alive(id) || (check && get_user_weapon(id) != CSW_KNIFE)) return PLUGIN_CONTINUE;
	
	static szModel[64];
	
	ArrayGetString(aModels, iPlayerKnife[id], szModel, charsmax(szModel));
	
	set_pev(id, pev_viewmodel2, szModel); 
	
	return PLUGIN_CONTINUE;
}

public SaveKnife(id)
{
	new szVaultKey[64], szVaultData[10];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-player_knife", szPlayer[id]);
	formatex(szVaultData, charsmax(szVaultData), "%d", iPlayerKnife[id]);
	
	nvault_set(iKnife, szVaultKey, szVaultData);
	
	return PLUGIN_CONTINUE;
}

public LoadKnife(id)
{
	get_user_name(id, szPlayer[id], charsmax(szPlayer));
	
	new szVaultKey[64], szVaultData[10];
	
	formatex(szVaultKey, charsmax(szVaultKey), "%s-player_knife", szPlayer[id]);
	
	if(nvault_get(iKnife, szVaultKey, szVaultData, charsmax(szVaultData))) iPlayerKnife[id] = str_to_num(szVaultData);
	
	return PLUGIN_CONTINUE;
} 