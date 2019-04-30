#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN "JailBreak: Hats"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new gEnt[33], gHat[33];

new Array:gModel, Array:gNazwa, Array:gBody;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /hat", "MenuHats");
	register_clcmd("say_team /hat", "MenuHats");
	register_clcmd("hat", "MenuHats");
	
	register_clcmd("say /hats", "MenuHats");
	register_clcmd("say_team /hats", "MenuHats");
	register_clcmd("hats", "MenuHats");
	
	register_clcmd("say /czapka", "MenuHats");
	register_clcmd("say_team /czapka", "MenuHats");
	register_clcmd("czapka", "MenuHats");
	
	register_clcmd("say /czapki", "MenuHats");
	register_clcmd("say_team /czapki", "MenuHats");
	register_clcmd("czapki", "MenuHats");
}

public plugin_precache()
{
	gModel = ArrayCreate(128);
	gNazwa = ArrayCreate(64);
	gBody = ArrayCreate();
	
	ArrayPushString(gModel, "Brak");
	ArrayPushString(gNazwa, "\yZdejmij \rCzapke");
	ArrayPushCell(gBody, 0);
	
	new szConfigsFile[128];
	
	get_configsdir(szConfigsFile, charsmax(szConfigsFile));
	add(szConfigsFile, charsmax(szConfigsFile), "/hats.ini");

	if(!file_exists(szConfigsFile)) return;

	new szLine[128], iLen, iAmount;
	
	for(new i = 0; i < file_size(szConfigsFile, 1); i++)
	{
		read_file(szConfigsFile, i, szLine, charsmax(szLine), iLen);
		
		if(contain(szLine, ";") != -1 || !iLen) continue;
		
		new szModel[128], szTempModel[128], szName[64], szBody[6];
		
		parse(szLine, szModel, charsmax(szModel), szName, charsmax(szName), szBody, charsmax(szBody));
		
		remove_quotes(szModel);
		remove_quotes(szName);
		remove_quotes(szBody);
		
		format(szModel, charsmax(szModel), "models/hat/%s", szModel);

		ArrayPushString(gModel, szModel);
		ArrayPushString(gNazwa, szName);
		ArrayPushCell(gBody, str_to_num(szBody));
		
		if(iAmount)
		{
			for(new j = 1; j < ArraySize(gBody) - 1; j++)
			{
				ArrayGetString(gModel, j, szTempModel, charsmax(szTempModel));
				
				if(equal(szModel, szTempModel))
				{
					szTempModel[0] = 1;
					
					break;
				}
				else szTempModel[0] = 0;
			}
		}
		
		if(!szTempModel[0]) precache_model(szModel);
		
		iAmount++;
	}
	
	log_amx("[CZAPKI] Zaladowano %i czapek.", iAmount);	
}

public client_putinserver(id)
	gHat[id] = 0;

public MenuHats(id)
{
	new szName[64], szNum[4], menu = menu_create("\yWybierz \rCzapke:", "MenuHats_Handler");

	for(new i = 0; i < ArraySize(gBody); i++)
	{
		if(!gHat[id] && i == 0) continue;
		
		num_to_str(i, szNum, charsmax(szNum));
		
		ArrayGetString(gNazwa, i, szName, charsmax(szName));
		
		if(gHat[id] == i) format(szName, charsmax(szName), "\r%s", szName);
		
		menu_additem(menu, szName, szNum);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuHats_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}

	new szName[64], szNum[4], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szNum, charsmax(szNum), szName, charsmax(szName), iCallback);

	SetHat(id, str_to_num(szNum));
	
	str_to_num(szNum) ? client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zalozyles czapke^x03 %s^x01.", szName): client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zdjales czapke.");
	
	return PLUGIN_CONTINUE;
}

stock SetHat(id, num)
{
	if(!is_user_connected(id) || (gEnt[id] && !is_valid_ent(gEnt[id]))) return;
	
	if(gEnt[id]) set_pev(gEnt[id], pev_effects, num ? pev(gEnt[id], pev_effects) & ~EF_NODRAW: pev(gEnt[id], pev_effects) | EF_NODRAW);

	if(!num)
	{
		gHat[id] = 0;
		
		return;
	}
	else
	{
		gHat[id] = num;
		
		new szModel[128];
		
		ArrayGetString(gModel, num, szModel, charsmax(szModel));

		if(!gEnt[id]) 
		{
			gEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
			
			set_pev(gEnt[id], pev_movetype, MOVETYPE_FOLLOW);
			set_pev(gEnt[id], pev_aiment, id);
			set_pev(gEnt[id], pev_rendermode, kRenderNormal);
		}

		engfunc(EngFunc_SetModel, gEnt[id], szModel);	
		set_pev(gEnt[id], pev_body, ArrayGetCell(gBody, num));
	}
}
