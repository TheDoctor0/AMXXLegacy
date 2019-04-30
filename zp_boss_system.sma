#include <amxmodx>
#include <amxmisc>

#define PLUGIN "ZP Boss System"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define MAX_BOSSES 32
#define MAX_PLAYERS 32
#define MAX_LENGHT 64

new const PausePlugins[][] = { "mapchooser.amxx", "deagsmapmanager.amxx", "umc.amxx" };

new MinPlayers, VotesPercent, LastMaps, VoteCount[MAX_BOSSES], Voted[MAX_PLAYERS+1], bool:MapChanged;

new BossNames[MAX_BOSSES][MAX_LENGHT], BossMaps[MAX_BOSSES][MAX_LENGHT], BossMap[MAX_LENGHT], bool:BossLast, BossCount;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	MinPlayers = register_cvar("zp_boss_minplayers", "13");
	VotesPercent = register_cvar("zp_boss_votespercent", "51");
	LastMaps = register_cvar("zp_boss_lastmaps", "3");
	
	register_logevent("NewRound", 2, "1=Round_Start");
	
	register_clcmd("say /boss", "ShowBossMenu");
	register_clcmd("say_team /boss", "ShowBossMenu");
	
	register_clcmd("say /bossy", "ShowBossMenu");
	register_clcmd("say_team /bossy", "ShowBossMenu");
	
	set_task(1.0, "LoadLastMaps");
}

public plugin_natives()
	register_native("zp_register_boss", "RegisterBoss");
	
public LoadLastMaps()
{
	new szFile[128], szMap[32], iLine, iLast;
	get_configsdir(szFile, 127);
	format(szFile, 127 ,"%s/lastmaps.umc", szFile);
	
	iLast = fopen(szFile, "rt");
	
	if(!iLast)
		log_amx("[BOSS] Brak pliku lastmaps.umc - nie mozna zaladowac ostatnich map!");
	else 
	{
		while (!feof(iLast))
		{
			fgets(iLast, szMap, 31);
			trim(szMap);
			
			if(szMap[0] != 0)
			{
				for(new i = 1; i <= BossCount; i++)
				{
					if(equal(szMap, BossMaps[i]))
						BossLast = true;
				}
			}
				
			iLine++;
			
			if(iLine == get_pcvar_num(LastMaps))
				break;
		}
	}
	
	fclose(iLast);
	
	return PLUGIN_CONTINUE;
}

public RegisterBoss(plugin, params)
{
	if(params != 2 || ++BossCount > MAX_BOSSES)
		return PLUGIN_CONTINUE;
	
	get_string(1, BossNames[BossCount], MAX_LENGHT);
	get_string(2, BossMaps[BossCount], MAX_LENGHT);
	log_amx("[BOSS] Zaladowano %s (Mapa: %s)", BossNames[BossCount], BossMaps[BossCount]);
	
	return PLUGIN_CONTINUE;
}
	
public client_disconnected(id)
{
	switch(Voted[id])
	{
		case 1: VoteCount[1]--;
		case 2: VoteCount[2]--;
		case 3: VoteCount[3]--;
		case 4: VoteCount[4]--;
		case 5: VoteCount[5]--;
	}
	
	Voted[id] = 0;
}

public ShowBossMenu(id)
{
	if(IsBossMap())
	{
		client_print_color(id, id, "^x03[BOSS]^x01 Wlasnie grana jest mapa z^x04 Bossem^x01!");
		return PLUGIN_HANDLED;
	}
	
	if(MapChanged)
	{
		client_print_color(id, id, "^x03[BOSS]^x01 Mapa z^x04 Bossem^x01 zostala juz wybrana!");
		return PLUGIN_HANDLED;
	}
	
	if(BossLast)
	{
		client_print_color(id, id, "^x03[BOSS]^x01 Mapa z^x04 Bossem^x01 byla grana jako jedna z ostatnich^x04 %i^x01 map!", get_pcvar_num(LastMaps));
		return PLUGIN_HANDLED;
	}
		
	if(get_playersnum() < get_pcvar_num(MinPlayers))
	{
		client_print_color(id, id, "^x03[BOSS]^x01 Zbyt malo graczy na serwerze (Wymagane min.^x04 %i^x01)!", get_pcvar_num(MinPlayers));
		return PLUGIN_HANDLED;
	}
		
	new szMenu[128];
	formatex(szMenu, charsmax(szMenu), "\rZaglosuj na Bossa:^n\yWymagana liczba glosow: %i", floatround(get_playersnum()*get_pcvar_num(VotesPercent)/100.0))
	new menu = menu_create(szMenu, "ShowBossMenu_Handle");
	
	for(new i = 1; i <= BossCount; i++)
	{
		formatex(szMenu, charsmax(szMenu), "\w%s \r[Glosy: %i]", BossNames[i], VoteCount[i]);
		menu_additem(menu, szMenu);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz", 0);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ShowBossMenu_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	item++;
	
	if(Voted[id])
	{
		switch(Voted[id])
		{
			case 1: VoteCount[1]--;
			case 2: VoteCount[2]--;
			case 3: VoteCount[3]--;
			case 4: VoteCount[4]--;
			case 5: VoteCount[5]--;
		}
		client_print_color(id, id, "^x03[BOSS]^x01 Twoj poprzedni glos zostal anulowany^x01!");
	}
	
	VoteCount[item]++; 
	Voted[id] = item;
	
	client_print_color(id, id, "^x03[BOSS]^x01 Zaglosowales na^x04 %s^x01!", BossNames[item]);
	
	if(floatround(get_playersnum()*get_pcvar_num(VotesPercent)/100.0) >= VoteCount[item])
	{
		client_print_color(0, print_team_red, "^x03[BOSS]^x01 Osiagnieto wymagana liczbe glosow na^x04 %s^x01.", BossNames[item]);
		client_print_color(0, print_team_red, "^x03[BOSS]^x01 Mapa zmieni sie na^x04 %s^x01 na poczatku nastepnej rundy.", BossMaps[item]);
		
		MapChanged = true;
		
		formatex(BossMap, charsmax(BossMap), BossMaps[item]);
		
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i]);
	}
	
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public NewRound()
{
	if(MapChanged) 
		server_cmd("changelevel %s", BossMap);
}
	
public IsBossMap()
{
	new szMapName[32], bool:Map;
	get_mapname(szMapName, 31);
	
	for(new i = 0; i <= BossCount; i++)
		if(equali(szMapName, BossMaps[i]))
			Map = true;
	
	return Map;
}