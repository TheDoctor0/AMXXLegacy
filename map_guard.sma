#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define PLUGIN "Map Guard"
#define VERSION "1.3"
#define AUTHOR "O'Zone"

#define TASK_CHECK 501

new CheckTime, DelayTime, VoteTime, PauseTime, MPlayers, DPlayers, NPlayers, ChangeVotes, Maps, Type, MapChooser, LastMaps;
new bool:SmallMap, bool:Vote, bool:NextMap, bool:FastChange, bool:Voted[33];
new sMapsCount, bMapsCount, lMapsCount, sMapsInVote[5], bMapsInVote[5], MapsNumber;
new Votes[6], Chosen[4], sMaps[64][32], bMaps[64][32], lMaps[64][32], Map[32], current_map[32];

new const PausePlugins[][] = {"mapchooser.amxx", "deagsmapmanager.amxx", "galileo.amxx", "umc.amxx"}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	CheckTime = register_cvar("mdm_checktime", "5"); // odstep czasowy sprawdzania ilosci graczy na serwerze
	DelayTime = register_cvar("mdm_delaytime", "90"); // czas na poczatku mapy, w ktorym liczba graczy nie jest sprawdzana (aby dac graczom czas na wejscie po zmianie mapy)
	VoteTime = register_cvar("mdm_votetime", "180"); // czas do konca mapy, w ktorym jesli graczy jest graczy jest zbyt malo graczy zostanie wywolane vote jedynie z malymi mapami
	PauseTime = register_cvar("mdm_pausetime", "150"); // czas do konca mapy, w ktorym plugin zostanie dezaktywowany, by nie wchodzic w konflikt z mapchooserem (nie radze zmieniac na mniej niz 140)
	MPlayers = register_cvar("mdm_mplayers", "8"); // ilosc graczy potrzebna do zmiany mapy na mala
	DPlayers = register_cvar("mdm_dplayers", "18"); // ilosc graczy potrzebna do zmiany mapy na duza
	Maps = register_cvar("mdm_maps", "5"); // ilosc map w vote (maksymalnie 5)
	Type = register_cvar("mdm_type", "2"); // 0 - wywoluje vote i zmienia mape od razu | 1 - wywoluje vote i zmienia mape po zakonczeniu aktualnej | 2 - wywoluje vote z pytaniem, czy zmienic mape/jesli tak, to czy od razu, czy po zakonczeniu aktualnej
	MapChooser = register_cvar("mdm_mapchooser", "2"); // 0 - nie wspolpracuje z mapchooserem | 1 - laduje ostatnie mapy z Deags' Map Management | 2 - laduje ostatnie mapy z Universal MapChooser
	LastMaps = register_cvar("mdm_lastmaps", "5"); // ilosc map granych ostatnio, ktore nie pojawia sie w vote (dziala tylko jesli na serwerze jest plugin DeagsMapManager i cvar mdm_mapchooser jest ustawiony na 1)
	
	register_message(SVC_INTERMISSION, "Message_Intermission");
	
	register_clcmd("say /malamapa", "CmdSmallMap");
	register_clcmd("say_team /malamapa", "CmdSmallMap");
	register_clcmd("say /duzamapa", "CmdBigMap");
	register_clcmd("say_team /duzamapa", "CmdBigMap");
	
	LoadMaps();
}

public plugin_natives()
	register_native("check_current_map", "CheckCurrentMap", 1);

public plugin_cfg()
	set_task(get_pcvar_float(DelayTime), "StartChecking", TASK_CHECK);
	
public client_putinserver(id)
{
	Voted[id] = false;
	NPlayers++;
}
	
public client_disconnect(id)
{
	NPlayers--;
	if(Voted[id])
		ChangeVotes--;
}

public LoadMaps()
{
	new file[128], file2[128], map[32], last, small, big, line;
	new bool:last_played;
	get_mapname(current_map, 31);
	get_configsdir(file, 127);
	get_configsdir(file2, 127);
	
	if(get_pcvar_num(MapChooser) && get_pcvar_num(LastMaps) > 0)
	{
		new file3[128];
		get_configsdir(file3, 127);
		get_pcvar_num(LastMaps) == 1 ? format(file3, 127 ,"%s/lastmapsplayed.txt", file3) : format(file3, 127 ,"%s/lastmaps.umc", file3);
		last = fopen(file3, "rt");
		lMapsCount = 0;
		if(!last)
			log_amx("[MAP] Brak pliku %s. Jesli nie masz pluginu %s przestaw cvar mdm_mapchooser na 0!", get_pcvar_num(LastMaps) == 1 ? "lastmapsplayed.txt":"lastmaps.umc", get_pcvar_num(LastMaps) == 1 ? "Deags' Map Management":"Universal MapChooser");
		else 
		{
			while (!feof(last))
			{
				fgets(last, map, 31);
				trim(map);
				if(map[0] != 0)
				{
					copy(lMaps[lMapsCount], 31, map);
					lMapsCount++;
				}
				line++;
				if(line == get_pcvar_num(LastMaps))
					break;
			}
		}
		fclose(last);
	}
	
	format(file, 127 ,"%s/mapcycle_male.txt", file);
	small = fopen(file, "rt");
	sMapsCount = 0;
	if(!small)
		log_amx("[MAP] Blad podczas ladowania pliku mapcycle_male.txt!")
	else 
	{
		while (!feof(small))
		{
			fgets(small, map, 31);
			trim(map);
			if(map[0] != 0)
			{
				if(equal(current_map, map)) 
					SmallMap = true;
					
				last_played = false;
				for(new i = 0; i < lMapsCount; i++)
				{
					if(equal(lMaps[i], map))
						last_played = true;
				}
				if(!last_played)
				{
					copy(sMaps[sMapsCount], 31, map);
					sMapsCount++;
				}
			}
		}
		fclose(small);
	}
	
	format(file2, 127 ,"%s/mapcycle_duze.txt", file2);
	big = fopen(file2, "rt");
	bMapsCount = 0;
	if(!big)
		log_amx("[MAP] Blad podczas ladowania pliku mapcycle_duze.txt!");
	else 
	{
		while (!feof(big))
		{
			fgets(big, map, 31);
			trim(map);
			if(map[0] != 0)
			{
				if(equal(current_map, map))
					SmallMap = false;

				last_played = false;
				for(new i = 0; i < lMapsCount; i++)
				{
					if(equal(lMaps[i], map))
						last_played = true;
				}
				if(!last_played)
				{
					copy(bMaps[bMapsCount], 31, map);
					bMapsCount++;
				}
			}
		}
		fclose(big);
	}
	log_amx("[MAP] Zaladowano %i malych map i %i duzych map. Z glosowania wykluczono %i ostatnio granych map.", sMapsCount, bMapsCount, lMapsCount);
	
	return PLUGIN_CONTINUE;
}

public CmdSmallMap(id)
{
	if(SmallMap)
	{
		ColorChat(id, RED, "[MAP]^x01 Aktualnie grasz na^x04 malej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(NPlayers >= get_pcvar_num(DPlayers))
	{
		ColorChat(id, RED, "[MAP]^x01 Na serwerze jest^x04 zbyt duzo graczy^x01, aby zagrac na malej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Voted[id])
	{
		ColorChat(id, RED, "[MAP]^x01 Juz zaglosowales na^x04 mala mape^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(++ChangeVotes >= floatround(NPlayers*0.51, floatround_round))
	{
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i]);
			
		SmallMap = false;
		FastChange = true;
		Vote = true;
		set_task(5.0, "StartMapVote");
		ColorChat(0, RED, "[MAP]^x01 Wystarczajaco duzo graczy zaglosowalo na^x04 mala mape^x01. Rozpoczynam glosowanie.");
	}
	else
	{
		new szName[32];
		get_user_name(id, szName, charsmax(szName));
		ColorChat(0, RED, "[MAP]^x04 %s^x01 uzyl komendy^x04 /malamapa^x01 i zaglosowal na zmiane mapy na mala^x01.", szName);
	}
	
	Voted[id] = true;
	
	return PLUGIN_CONTINUE;
}

public CmdBigMap(id)
{
	if(!SmallMap)
	{
		ColorChat(id, RED, "[MAP]^x01 Aktualnie grasz na^x04 duzej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(NPlayers <= get_pcvar_num(MPlayers))
	{
		ColorChat(id, RED, "[MAP]^x01 Na serwerze jest^x04 zbyt malo graczy^x01, aby zagrac na duzej mapie^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(Voted[id])
	{
		ColorChat(id, RED, "[MAP]^x01 Juz zaglosowales na^x04 duza mape^x01!");
		return PLUGIN_CONTINUE;
	}
	
	if(++ChangeVotes >= floatround(NPlayers*0.51, floatround_round))
	{
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i]);
			
		SmallMap = true;
		FastChange = true;
		Vote = true;
		set_task(5.0, "StartMapVote");
		ColorChat(0, RED, "[MAP]^x01 Wystarczajaco duzo graczy zaglosowalo na^x04 duza mape^x01. Rozpoczynam glosowanie.");
	}
	else
	{
		new szName[32];
		get_user_name(id, szName, charsmax(szName));
		ColorChat(0, RED, "[MAP]^x04 %s^x01 uzyl komendy^x04 /duzamapa^x01 i zaglosowal na zmiane mapy na duza^x01.", szName);
	}
	
	Voted[id] = true;
	
	return PLUGIN_CONTINUE;
}

public StartChecking()
{
	set_task(get_pcvar_float(CheckTime), "CheckPlayers", TASK_CHECK, "", 0, "b");
	CheckPlayers();
}

public CheckPlayers()
{
	if(Vote || NPlayers < 2 || get_timeleft() <= get_pcvar_num(PauseTime))
		return PLUGIN_CONTINUE;
		
	if(get_timeleft() <= get_pcvar_num(VoteTime) && SmallMap && NPlayers <= get_pcvar_num(MPlayers))
	{
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i]);
			
		SmallMap = false;
		FastChange = false;
		Vote = true;
		set_task(10.0, "StartMapVote");
		ColorChat(0, RED, "[MAP]^x01 Zbyt malo graczy, by zagrac na^x04 duzej^x01 mapie! Wymuszam glosowanie za^x04 10 sekund^x01.");
		
		return PLUGIN_CONTINUE;
	}
	
	if((NPlayers >= get_pcvar_num(DPlayers) && SmallMap) || (NPlayers <= get_pcvar_num(MPlayers) && !SmallMap))
	{
		switch(get_pcvar_num(Type))
		{
			case 0, 1: set_task(10.0, "StartMapVote");
			case 2: set_task(10.0, "StartQuestionVote");
		}
		
		Vote = true;
		ColorChat(0, RED, "[MAP]^x01 %s! Za^x04 10 sekund^x01 nastapi glosowanie.", SmallMap ? "Wystarczajaco graczy, by zmienic mape na^x04 duza^x01" : "Zbyt malo graczy, by grac na^x04 duzej^x01 mapie");
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public StartQuestionVote()
{
	new menu = SmallMap ? menu_create("\yCzy zmienic mape na Duza?", "StartQuestionVote_Handler") : menu_create("\yCzy zmienic mape na Mala?", "StartQuestionVote_Handler");
	new menu_callback = menu_makecallback("StartQuestionVote_Callback");
	menu_additem(menu, "\wTak\r - Natychmiastowo", "1", 0);
	menu_additem(menu, "\wTak\y - Po zakonczeniu mapy", "2", 0);
	menu_additem(menu, "\wNie^n", "3", 0);
	menu_additem(menu, "\yAnuluj Glosowanie^n", "4", menu_callback);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	new players[32], inum;
	get_players(players, inum, "ch");
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
			menu_display(players[i], menu, 0);
	}
	set_task(10.0, "Finish_QuestionVote", menu);

	Chosen[1] = Chosen[2] = Chosen[3];

	return PLUGIN_CONTINUE;
}

public StartQuestionVote_Callback(id, menu, item)
{
	if(get_user_flags(id) & ADMIN_BAN)
		return ITEM_ENABLED;
		
	return ITEM_DISABLED;
}

public StartQuestionVote_Handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if (item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new data[6], name[32];
	new access, callback;

	menu_item_getinfo(menu, item, access, data, 5, _, _, callback);

	new key = str_to_num(data);
	get_user_name(id, name, 31);
	
	switch (key)
	{
		case 1: ColorChat(0, RED, "[MAP]^x04 %s^x01 zaglosowal na^x04 Tak - Natychmiastowo^x01.", name);
		case 2: ColorChat(0, RED, "[MAP]^x04 %s^x01 zaglosowal na^x04 Tak - Po zakonczeniu mapy^x01.", name);
		case 3: ColorChat(0, RED, "[MAP]^x04 %s^x01 zaglosowal na^x04 Nie^x01.", name);
		case 4: 
		{
			Vote = true;
			remove_task(menu);
			show_menu(0, 0, "^n", 1);
			ColorChat(0, RED, "[MAP]^x01 Admin^x04 %s^x01 anulowal glosowanie^x01.", name);
		}
	}

	++Chosen[key];

	menu_cancel(id);
	return PLUGIN_HANDLED;
}

public Finish_QuestionVote(menu)
{
	show_menu(0, 0, "^n", 1);
	
	if((Chosen[1] > Chosen[2]) && (Chosen[1] > Chosen[3]))
	{
		if((SmallMap && bMapsCount == 1) || (!SmallMap && sMapsCount == 1))
		{
			SmallMap ? copy(Map, 31, bMaps[bMapsInVote[1]]) : copy(Map, 31, sMaps[sMapsInVote[1]]);
			ColorChat(0, RED, "[MAP]^x01 Zaraz nastapi^x04 zmiana mapy na ^x04 %s^x01.", Map);
			set_task(5.0, "MapChange");
			return PLUGIN_CONTINUE;
		}
		
		ColorChat(0, RED, "[MAP]^x01 Wynik glosowania:^x04 Zmiana mapy natychmiastowo^x01. Zaraz rozpocznie sie^x04 vote^x01 o mape!");
		set_task(5.0, "StartMapVote");
		FastChange = true;
		return PLUGIN_CONTINUE;
	}
	else if((Chosen[2] > Chosen[1]) && (Chosen[2] > Chosen[3]))
	{
		if((SmallMap && bMapsCount == 1) || (!SmallMap && sMapsCount == 1))
		{
			SmallMap ? copy(Map, 31, bMaps[bMapsInVote[1]]) : copy(Map, 31, sMaps[sMapsInVote[1]]);
			ColorChat(0, RED, "[MAP]^x01 Jako kolejna bedzie grana mapa^x04 %s^x01.", Map);
			server_cmd("amx_nextmap %s", Map);
			return PLUGIN_CONTINUE;
		}
		
		ColorChat(0, RED, "[MAP]^x01 Wynik glosowania:^x04 Zmiana mapy po zakonczeniu^x01. Zaraz rozpocznie sie^x04 vote^x01 o mape!");
		set_task(5.0, "StartMapVote");
		FastChange = false;
		return PLUGIN_CONTINUE;
	}
	else if((Chosen[3] > Chosen[1]) && (Chosen[3] > Chosen[2]))
	{
		ColorChat(0, RED, "[MAP]^x01 Wynik glosowania:^x04 Bez zmiany mapy^x01. Na razie mapa^x04 nie zostanie^x01 zmieniona.");
		set_task(420.0, "ResetVote");
		return PLUGIN_CONTINUE;
	}
	else 
	{
		ColorChat(0, RED, "[MAP]^x01 Zadna z opcji nie zdobyla wystarczajacej ilosci glosow. Niedlugo glosowanie zostanie powtorzone.");
		Vote = false;
	}
	return PLUGIN_CONTINUE;
}

public ResetVote()
	Vote = false;
	
public StartMapVote()
{
	new VoteIteration;
	MapsNumber = get_pcvar_num(Maps) > 5 ? 5 : get_pcvar_num(Maps);
	new Number = SmallMap ? (bMapsCount < MapsNumber ? bMapsCount : MapsNumber) : (sMapsCount < MapsNumber ? sMapsCount : MapsNumber);
	MapsNumber = Number;
	new Random = SmallMap ? random_num(0, bMapsCount - 1) : random_num(0, sMapsCount - 1);
	
	for(VoteIteration = 0; VoteIteration < Number; VoteIteration++)
	{
		Random = -1;
		while(Random == -1)
		{
			Random = SmallMap ? random_num(0, bMapsCount - 1) : random_num(0, sMapsCount - 1);
			for(new a = 0; a < VoteIteration; a++)
			{
				if(SmallMap)
				{
					if(Random == bMapsInVote[a])
						Random = -1;
				}
				else 
				{
					if(Random == sMapsInVote[a])
						Random = -1;
				}
			}
		}
		if(SmallMap)
			bMapsInVote[VoteIteration] = Random;
		else
			sMapsInVote[VoteIteration] = Random;
	}
	
	for(new i = 0; i < 6; i++)
		Votes[i] = 0;
	
	new menu = menu_create("\yWybierz Mape:", "StartMapVote_Handler");
	for(new i = 0; i < Number; i++)
		SmallMap ? menu_additem(menu, bMaps[bMapsInVote[i]]) : menu_additem(menu, sMaps[sMapsInVote[i]]);
		
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	new players[32], inum;
	get_players(players, inum, "ch");
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
			menu_display(players[i], menu, 0);
	}
	set_task(15.0, "Finish_MapVote", menu)

	return PLUGIN_CONTINUE
}

public StartMapVote_Handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new name[32];
	get_user_name(id, name, 31);
	
	ColorChat(0, RED, "[MAP]^x04 %s^x01 zaglosowal na^x04 %s^x01.", name, SmallMap ? bMaps[bMapsInVote[item]] : sMaps[sMapsInVote[item]]);

	++Votes[item];

	menu_cancel(id);
	return PLUGIN_HANDLED;
}

public Finish_MapVote() 
{
	show_menu(0, 0, "^n", 1);
	new Winner = 0;
	for(new i = 0; i < MapsNumber; i++)
		if(Votes[i] > Votes[Winner])
			Winner = i;

	SmallMap ? copy(Map, 31, bMaps[bMapsInVote[Winner]]) : copy(Map, 31, sMaps[sMapsInVote[Winner]]);
	log_amx("Nastepna mapa: %s", Map);
	
	if(FastChange || get_pcvar_num(Type) == 0)
	{
		ColorChat(0, RED, "[MAP]^x01 Wygrala mapa^x04 %s^x01! Zaraz nastapi^x04 zmiana mapy^x01.", Map);
		set_task(5.0, "MapChange");
	}
	if(!FastChange || get_pcvar_num(Type) == 1) 
	{
		ColorChat(0, RED, "[MAP]^x01 Wygrala mapa^x04 %s^x01! Bedzie grana jako^x04 kolejna mapa^x01.", Map);
		server_cmd("amx_nextmap %s", Map);
		NextMap = true;
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i]);
	}
}

public Message_Intermission()
{
	if(NextMap)
		set_task(1.0, "MapChange");
}

public MapChange()
	server_cmd("changelevel %s", Map);
	
public CheckCurrentMap()
	return SmallMap ? 1 : 0;
