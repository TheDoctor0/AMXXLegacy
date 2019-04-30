#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Map Guard"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define TASK_MAPCHANGE 9328
#define TASK_CHECK 9920

new Players, DPlayers, NPlayers, ChangeVotes, Maps, MaxPlayers, MinPlayers, AutoVote, DAutoVote, DelayTime, CheckTime;
new bool:SmallMap, bool:VoteInProgress, bool:Changed, bool:Voted[33], bool:Connected[33];
new sMapsCount, sMapsInVote[5], MapsNumber, SmallChecks, BigChecks, StopChecking, Vote;
new Votes[6], sMaps[64][32], Map[32], current_map[32];

new const PausePlugins[][] = {"mapchooser.amxx", "deagsmapmanager.amxx", "galileo.amxx", "umc.amxx", "umc_small.amxx"}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	Players = register_cvar("mg_smallmap_players", "10"); // liczba graczy na duzej mapie umozliwiajaca uzycie komendy /malamapa
	DPlayers = register_cvar("mg_bigmap_players", "10"); // liczba graczy na malej mapie umozliwiajaca uzycie komendy /duzamapa
	MaxPlayers = register_cvar("mg_max_players", "12"); // maksymalna liczba graczy na malej mapie (do wymuszenia glosowania)
	MinPlayers = register_cvar("mg_min_players", "8"); // minimalna liczba graczy na duzej mapie(do wymuszenia glosowania)
	AutoVote = register_cvar("mg_smallmap_autovote", "0"); // automatyczne vote o mala mape, jesli graczy jest mniej niz minimalna liczba na duzej mapie
	DAutoVote = register_cvar("mg_bigmap_autovote", "0"); // automatyczne vote o duza mape, jesli graczy jest wiecej niz maksymalna liczba na malej mapie
	Maps = register_cvar("mg_vote_maps", "5"); // liczba malych map w vote (maksymalnie 5)
	DelayTime = register_cvar("mg_check_delay", "90"); // czas na poczatku mapy, w ktorym liczba graczy nie jest sprawdzana (aby dac graczom czas na wejscie po zmianie mapy)
	CheckTime = register_cvar("mg_check_time", "10"); // odstep czasowy sprawdzania liczby graczy na serwerze
	
	register_clcmd("say /malamapa", "CmdSmallMap");
	register_clcmd("say_team /malamapa", "CmdSmallMap");

	register_clcmd("say /duzamapa", "CmdBigMap");
	register_clcmd("say_team /duzamapa", "CmdBigMap");
	
	register_clcmd("say nextmap", "CmdNextMap");
	register_clcmd("say timeleft", "CmdTimeLeft");
	register_clcmd("say rtv", "CmdRockTheVote");
	
	LoadMaps();

	set_task(90.0, "StartChecking");
}

public plugin_natives()
{
	register_native("check_small_map", "check_small_map");
	register_native("get_small_map", "get_small_map");
	register_native("vote_small_map", "vote_small_map");
}

public plugin_cfg()
	set_task(get_pcvar_float(DelayTime), "StartChecking", TASK_CHECK);

public StartChecking()
{
	set_task(get_pcvar_float(CheckTime), "CheckPlayers", TASK_CHECK, "", 0, "b");
	CheckPlayers();
}
	
public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return;
	
	Connected[id] = true;
	Voted[id] = false;
	NPlayers++;
}
	
public client_disconnected(id)
{
	if(is_user_bot(id) || is_user_hltv(id) || !Connected[id]) return;

	Connected[id] = false;

	NPlayers--;
	
	if(Voted[id]) ChangeVotes--;
}

public LoadMaps()
{
	new file[128], map[32], small;
	get_mapname(current_map, 31);
	get_configsdir(file, 127);
	
	format(file, 127 ,"%s/mapcycle_male.txt", file);
	small = fopen(file, "rt");
	sMapsCount = 0;
	
	if(!small) log_amx("[MAPA] Blad podczas ladowania pliku mapcycle_male.txt!")
	else 
	{
		while (!feof(small))
		{
			fgets(small, map, 31);
			trim(map);
			
			if(map[0] != 0)
			{
				if(equal(current_map, map)) SmallMap = true;

				copy(sMaps[sMapsCount], 31, map);
				sMapsCount++;
			}
		}
		fclose(small);
	}
	
	log_amx("[MAPA] Zaladowano %i malych map.", sMapsCount);
	
	return PLUGIN_CONTINUE;
}

public CheckPlayers()
{
	if(Vote || StopChecking) return PLUGIN_CONTINUE;
		
	if(!SmallMap && NPlayers <= get_pcvar_num(MinPlayers) && get_pcvar_num(AutoVote))
	{
		if(++BigChecks >= 3) {
			for(new i = 0; i < sizeof PausePlugins; i++) pause("ac", PausePlugins[i]);

			Vote = true;

			set_task(10.0, "StartSmallMapVote");

			client_print_color(0, 0, "^x04[MAPA]^x01 Zbyt malo graczy, by zagrac na^x04 duzej^x01 mapie! Wymuszam glosowanie za^x04 10 sekund^x01.");
		}
	} else BigChecks = 0;

	if(SmallMap && NPlayers >= get_pcvar_num(MaxPlayers) && get_pcvar_num(DAutoVote))
	{
		if(++SmallChecks >= 3) {
			Vote = true;

			server_cmd("umc_startvote");

			client_print_color(0, 0, "^x04[MAPA]^x01 Zbyt duzo graczy, by zagrac na^x04 malej^x01 mapie! Wymuszam glosowanie za^x04 10 sekund^x01.");
		}
	} else SmallChecks = 0;
	
	return PLUGIN_CONTINUE;
}

public CmdNextMap(id)
{
	if(!Changed) return;
	
	client_print_color(id, id, "^x04[MAPA]^x01 Nastepna mapa:^x03 %s^x01.", Map);
}

public CmdTimeLeft(id)
{
	if(!Changed) return;
	
	static szVoice[128], Time[3];
	
	Time[0] = get_timeleft();
	Time[1] = Time[0] / 60;
	Time[0] = Time[0] - Time[1] * 60;

	getTimeVoice(szVoice, 127, 0, get_timeleft());
	client_cmd(id, "%s", szVoice);
	
	if(Time[1] > 0 && Time[0] > 0) client_print_color(id, id, "^x04[MAPA]^x01 Pozostaly czas:^x03 %i^x01:^x03%i^x01.", Time[1], Time[0]);
	else client_print_color(id, id, "^x04[MAPA]^x01 Pozostaly czas:^x03 -^x01:^x03-^x01.", Time[1], Time[0]);
}

stock getTimeVoice(text[], len, flags, tmlf)
{
	new temp[7][32], secs = tmlf % 60, mins = tmlf / 60;
	
	for(new a = 0;a < 7;++a) temp[a][0] = 0;

	if(secs > 0)
	{
		num_to_word(secs, temp[4], 31);
		
		if (!(flags & 8)) temp[5] = "seconds ";
	}
	
	if(mins > 59)
	{
		new hours = mins / 60;
		
		num_to_word(hours, temp[0], 31);
		
		if (!(flags & 8)) temp[1] = "hours ";
		
		mins = mins % 60;
	}
	
	if(mins > 0)
	{
		num_to_word(mins, temp[2], 31);
		
		if (!(flags & 8)) temp[3] = "minutes ";
	}
	
	if(!(flags & 4)) temp[6] = "remaining ";
	
	return format(text, len, "spk ^"vox/%s%s%s%s%s%s%s^"", temp[0], temp[1], temp[2], temp[3], temp[4], temp[5], temp[6]);
}

public CmdRockTheVote(id)
{
	if(!Changed) return;
	
	client_print_color(id, id, "^x04[MAPA]^x01 Nastepna mapa zostala juz^x03 wybrana^x01.", Map);
}

public CmdSmallMap(id)
{
	if(SmallMap)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Aktualnie grasz na^x03 malej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Changed)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Nastepna mapa zostala juz wybrana^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(NPlayers > get_pcvar_num(DPlayers))
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Na serwerze jest^x03 zbyt duzo graczy^x01, aby grac na malej mapie^x01 (maksymalnie^x03 %i graczy^x01)!", get_pcvar_num(DPlayers));
		return PLUGIN_CONTINUE;
	}
	
	if(VoteInProgress)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Glosowanie wlasnie^x03 trwa^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Voted[id])
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Juz zaglosowales na^x03 mala mape^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(++ChangeVotes >= floatround(NPlayers*0.51, floatround_round))
	{
		for(new i = 0; i < sizeof PausePlugins; i++) pause("ac", PausePlugins[i]);

		VoteInProgress = true;

		set_task(10.0, "StartSmallMapVote");
		
		client_print_color(0, id, "^x04[MAPA]^x01 Wystarczajaco duzo graczy zaglosowalo na^x03 mala mape^x01. Rozpoczynam glosowanie.");
	}
	else
	{
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
		
		client_print_color(0, id, "^x04[MAPA]^x03 %s^x01 uzyl komendy^x03 /malamapa^x01 i zaglosowal na zmiane mapy na mala^x01.", szName);
	}
	
	Voted[id] = true;
	
	return PLUGIN_CONTINUE;
}

public CmdBigMap(id)
{
	if(!SmallMap)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Aktualnie grasz na^x03 duzej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Changed)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Nastepna mapa zostala juz wybrana^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(NPlayers < get_pcvar_num(Players))
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Na serwerze jest^x03 zbyt malo graczy^x01, aby grac na duzej mapie^x01 (minimalnie^x03 %i graczy^x01)!", get_pcvar_num(Players));
		return PLUGIN_CONTINUE;
	}
	
	if(VoteInProgress)
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Glosowanie wlasnie^x03 trwa^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Voted[id])
	{
		client_print_color(id, id, "^x04[MAPA]^x01 Juz zaglosowales na^x03 duza mape^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(++ChangeVotes >= floatround(NPlayers*0.51, floatround_round))
	{
		for(new i = 0; i < sizeof PausePlugins; i++) pause("ac", PausePlugins[i]);

		VoteInProgress = true;

		server_cmd("umc_startvote");
		
		client_print_color(0, id, "^x04[MAPA]^x01 Wystarczajaco duzo graczy zaglosowalo na^x03 duza mape^x01. Rozpoczynam glosowanie.");
	}
	else
	{
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
		
		client_print_color(0, id, "^x04[MAPA]^x03 %s^x01 uzyl komendy^x03 /duzamapa^x01 i zaglosowal na zmiane mapy na duza^x01.", szName);
	}
	
	Voted[id] = true;
	
	return PLUGIN_CONTINUE;
}
	
public StartSmallMapVote()
{
	new VoteIteration;
	
	MapsNumber = min(sMapsCount, get_pcvar_num(Maps) > 5 ? 5 : get_pcvar_num(Maps));
	
	new Random = random_num(0, sMapsCount - 1);
	
	for(VoteIteration = 0; VoteIteration < MapsNumber; VoteIteration++)
	{
		Random = -1;
		while(Random == -1)
		{
			Random = random_num(0, sMapsCount - 1);
			
			for(new a = 0; a < VoteIteration; a++) if(Random == sMapsInVote[a]) Random = -1;
		}
		sMapsInVote[VoteIteration] = Random;
	}
	
	for(new i = 0; i < MapsNumber; i++) Votes[i] = 0;
	
	new menu = menu_create("\wWybierz \rMape:", "StartMapVote_Handler");
	
	for(new i = 0; i < MapsNumber; i++) menu_additem(menu, sMaps[sMapsInVote[i]]);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	new players[32], inum;
	
	get_players(players, inum, "ch");
	
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
		{
			menu_display(players[i], menu, 0);
			client_cmd(0, "spk Gman/Gman_Choose%i", random_num(1, 2));
		}
	}
	
	set_task(15.0, "FinishSmallMapVote", menu)

	return PLUGIN_CONTINUE
}

public StartMapVote_Handler(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new name[32];
	get_user_name(id, name, 31);
	
	client_print_color(0, id, "^x04[MAPA]^x03 %s^x01 zaglosowal na^x03 %s^x01.", name, sMaps[sMapsInVote[item]]);

	++Votes[item];

	menu_cancel(id);
	
	return PLUGIN_HANDLED;
}

public FinishSmallMapVote() 
{
	show_menu(0, 0, "^n", 1);
	
	new Winner = 0;
	
	for(new i = 0; i < MapsNumber; i++) if(Votes[i] > Votes[Winner]) Winner = i;

	copy(Map, 31, sMaps[sMapsInVote[Winner]]);
	
	Changed = true;
	
	if(!SmallMap) 
	{
		set_task(10.0, "ChangeMap", TASK_MAPCHANGE);
		
		client_print_color(0, print_team_red, "^x04[MAPA]^x01 Wygrala mapa^x03 %s^x01. Zmiana mapy za^x03 10 sekund^x01.", Map);
	}
	else
	{
		set_task(float(get_timeleft() - 5), "ChangeMap", TASK_MAPCHANGE);
		
		client_print_color(0, print_team_red, "^x04[MAPA]^x01 Jako nastepna grana bedzie mapa^x03 %s^x01.", Map);
	}
}

public ChangeMap()
{
	set_task(5.0, "MapChange", TASK_MAPCHANGE);
	emessage_begin(MSG_ALL, SVC_INTERMISSION);
	emessage_end();
}

public MapChange()
	server_cmd("changelevel %s", Map);
	
public check_small_map()
	return SmallMap;
	
public get_small_map()
	return VoteInProgress;
	
public vote_small_map()
{
	if(NPlayers >= get_pcvar_num(MinPlayers) || !NPlayers || VoteInProgress)
	{
		StopChecking = true;

		return 0;
	}

	for(new i = 0; i < sizeof PausePlugins; i++) pause("ac", PausePlugins[i]);

	VoteInProgress = true;

	set_task(10.0, "StartSmallMapVote");
	
	client_print_color(0, print_team_red, "^x04[MAPA]^x01 Zbyt malo graczy, aby zagrac^x03 duza mape^x01. Zaraz rozpoczenie sie glosowanie.");

	return 1;
}
