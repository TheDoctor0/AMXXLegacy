#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define PLUGIN "Mala/Duza Mapa"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define TASK_CHECK 501

new CheckTime, DelayTime, VoteTime, PauseTime, MPlayers, DPlayers, Maps, Type, MapChooser, LastMaps
new bool:SmallMap, bool:BigMap, bool:Voted, bool:Voting, bool:NextMap
new sMapsCount, bMapsCount, lMapsCount
new sMapsInVote[5], bMapsInVote[5], MapsNumber
new Votes[6], Chosen[4], Choice
new sMaps[64][32], bMaps[64][32], lMaps[64][32], Map[32]
new current_map[32]

new const PausePlugins[][] = {"mapchooser.amxx", "deagsmapmanager.amxx", "galileo.amxx"}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	CheckTime = register_cvar("mdm_checktime", "20") // odstep czasowy sprawdzania ilosci graczy na serwerze
	DelayTime = register_cvar("mdm_delaytime", "120") // czas na poczatku mapy, w ktorym liczba graczy nie jest sprawdzana (aby dac graczom czas na wejscie po zmianie mapy)
	VoteTime = register_cvar("mdm_votetime", "180") // czas do konca mapy, w ktorym jesli graczy jest graczy jest zbyt malo graczy zostanie wywolane vote jedynie z malymi mapami
	PauseTime = register_cvar("mdm_pausetime", "150") // czas do konca mapy, w ktorym plugin zostanie dezaktywowany, by nie wchodzic w konflikt z mapchooserem (nie radze zmieniac na mniej niz 140)
	MPlayers = register_cvar("mdm_mplayers", "6") // ilosc graczy potrzebna do zmiany mapy na mala
	DPlayers = register_cvar("mdm_dplayers", "17") // ilosc graczy potrzebna do zmiany mapy na duza
	Maps = register_cvar("mdm_maps", "5") // ilosc map w vote (maksymalnie 5)
	Type = register_cvar("mdm_type", "2") // 0 - wywoluje vote i zmienia mape od razu | 1 - wywoluje vote i zmienia mape po zakonczeniu aktualnej | 2 - wywoluje vote z pytaniem, czy zmienic mape/jesli tak, to czy od razu, czy po zakonczeniu aktualnej
	MapChooser = register_cvar("mdm_mapchooser", "1") // 0 - nie wspolpracuje z DeagsMapManager | 1 - wlacza wspolprace i laduje ostanio grane mapy
	LastMaps = register_cvar("mdm_lastmaps", "8") // ilosc map granych ostatnio, ktore nie pojawia sie w vote (dziala tylko jesli na serwerze jest plugin DeagsMapManager i cvar mdm_mapchooser jest ustawiony na 1)
	
	register_message(SVC_INTERMISSION, "Message_Intermission")
	
	LoadMaps()
}

public plugin_natives()
	register_native("check_current_map", "CheckCurrentMap", 1)

public plugin_cfg()
	set_task(get_pcvar_float(DelayTime), "StartChecking", TASK_CHECK)

public StartChecking()
{
	set_task(get_pcvar_float(CheckTime), "CheckPlayers", TASK_CHECK, "", 0, "b")
	CheckPlayers()
}
	
public LoadMaps()
{
	new file[128], file2[128], map[32], last, small, big, line
	new bool:last_played
	get_mapname(current_map, 31)
	get_configsdir(file, 127)
	get_configsdir(file2, 127)
	
	if(get_pcvar_num(MapChooser) && get_pcvar_num(LastMaps) > 0){
		new file3[128]
		get_configsdir(file3, 127)
		format(file3, 127 ,"%s/lastmapsplayed.txt", file3)
		last = fopen(file3, "rt")
		lMapsCount = 0
		if(last == 0){
			log_amx("[MDM] Brak pliku lastmapsplayed.txt. Jesli nie masz pluginu DeagsMapManager przestaw cvar mdm_mapchooser na 0!")
		} 
		else {
			while (!feof(last)){
				fgets(last, map, 31)
				trim(map)
				if(map[0] != 0){
					copy(lMaps[lMapsCount], 31, map)
					log_amx("%s", lMaps[lMapsCount])
					lMapsCount++
				}
				line++
				if(line == get_pcvar_num(LastMaps))
					break
			}
		}
		fclose(last)
	}
	
	format(file2, 127 ,"%s/mapcycle_duze.txt", file2)
	big = fopen(file2, "rt")
	bMapsCount = 0
	if(big == 0){
		log_amx("[MDM] Blad podczas ladowania pliku mapcycle_duze.txt!")
	} 
	else {
		while (!feof(big)){
			fgets(big, map, 31)
			trim(map)
			if(map[0] != 0){
				if(equal(current_map, map)) {
					BigMap = true
				}
				last_played = false
				for(new i = 0; i < lMapsCount; i++){
					if(equal(lMaps[i], map))
						last_played = true
				}
				if(!last_played){
					copy(bMaps[bMapsCount], 31, map)
					bMapsCount++
				}
			}
		}
		fclose(big)
	}
	
	format(file, 127 ,"%s/mapcycle_male.txt", file)
	small = fopen(file, "rt")
	sMapsCount = 0
	if(small == 0){
		log_amx("[MDM] Blad podczas ladowania pliku mapcycle_male.txt!")
	} 
	else {
		while (!feof(small)){
			fgets(small, map, 31)
			trim(map)
			if(map[0] != 0){
				if(equal(current_map, map)) {
					SmallMap = true
				}
				last_played = false
				for(new i = 0; i < lMapsCount; i++){
					if(equal(lMaps[i], map))
						last_played = true
				}
				if(!last_played){
					copy(sMaps[sMapsCount], 31, map)
					sMapsCount++
				}
			}
		}
		fclose(small)
	}
	log_amx("[MDM] Zaladowano %i malych map i %i duzych map. Z glosowania wykluczono %i ostatnio granych map.", sMapsCount, bMapsCount, lMapsCount)
	
	return PLUGIN_CONTINUE
}

public CheckPlayers()
{
	if(Voted || get_playersnum() < 2 || get_timeleft() <= get_pcvar_num(PauseTime))
		return PLUGIN_CONTINUE
	if(get_timeleft() <= get_pcvar_num(VoteTime) && SmallMap && get_playersnum() <= get_pcvar_num(MPlayers)){
		SmallMap = false
		BigMap = true
		Choice = 2
		Voted = true
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i])
		set_task(10.0, "StartMapVote")
		ColorChat(0, RED, "[MDM]^x01 Zbyt malo graczy, by zagrac na^x04 duzej^x01 mapie! Wymuszam glosowanie za^x04 10 sekund^x01.")
		return PLUGIN_CONTINUE
	}
	if(Voting)
		return PLUGIN_CONTINUE
	if(get_playersnum() >= get_pcvar_num(DPlayers) && SmallMap){
		ColorChat(0, RED, "[MDM]^x01 Wystarczajaco graczy, by zmienic mape na^x04 duza^x01! Za^x04 10 sekund^x01 nastapi glosowanie.")
		new type = get_pcvar_num(Type)
		switch(type){
			case 0, 1: set_task(10.0, "StartMapVote")
			case 2: set_task(10.0, "StartQuestionVote")
		}
		Voting = true
		return PLUGIN_CONTINUE
	}
	if(get_playersnum() <= get_pcvar_num(MPlayers) && BigMap){
		ColorChat(0, RED, "[MDM]^x01 Zbyt malo graczy, by grac na^x04 duzej^x01 mapie! Za^x04 10 sekund^x01 nastapi glosowanie.")
		new type = get_pcvar_num(Type)
		switch(type){
			case 0, 1: set_task(10.0, "StartMapVote")
			case 2: set_task(10.0, "StartQuestionVote")
		}
		Voting = true
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public StartQuestionVote()
{
	new menu = SmallMap ? menu_create("\yCzy zmienic mape na Duza?", "StartQuestionVote_Handler") : menu_create("\yCzy zmienic mape na Mala?", "StartQuestionVote_Handler")
	menu_additem(menu, "\wTak\r - Natychmiastowo", "1", 0)
	menu_additem(menu, "\wTak\y - Po zakonczeniu mapy", "2", 0)
	menu_additem(menu, "\wNie", "3", 0)

	new players[32], inum;
	get_players(players, inum, "ch")
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
			menu_display(players[i], menu, 0)
	}
	set_task(10.0, "Finish_QuestionVote", menu)

	Chosen[1] = Chosen[2] = Chosen[3]

	return PLUGIN_CONTINUE
}

public StartQuestionVote_Handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if (item == MENU_EXIT)
	{
		menu_cancel(id)
		return PLUGIN_HANDLED
	}

	new data[6], name[32]
	new access, callback

	menu_item_getinfo(menu, item, access, data, 5, _, _, callback)

	new key = str_to_num(data)
	get_user_name(id, name, 31)
	
	switch (key)
	{
		case 1: ColorChat(0, RED, "[MDM]^x04 %s^x01 zaglosowal na^x04 Tak - Natychmiastowo^x01.", name)
		case 2: ColorChat(0, RED, "[MDM]^x04 %s^x01 zaglosowal na^x04 Tak - Po zakonczeniu mapy^x01.", name)
		case 3: ColorChat(0, RED, "[MDM]^x04 %s^x01 zaglosowal na^x04 Nie^x01.", name)
	}

	++Chosen[key]

	menu_cancel(id)
	return PLUGIN_HANDLED
}

public Finish_QuestionVote(menu)
{
	show_menu(0, 0, "^n", 1)
	
	if((Chosen[1] > Chosen[2]) && (Chosen[1] > Chosen[3])){
		if((SmallMap && bMapsCount == 1) || (BigMap && sMapsCount == 1)){
			SmallMap ? copy(Map, 31, bMaps[bMapsInVote[1]]) : copy(Map, 31, sMaps[sMapsInVote[1]])
			ColorChat(0, RED, "[MDM]^x01 Zaraz nastapi^x04 zmiana mapy na ^x04 %s^x01.", Map)
			set_task(5.0, "MapChange")
			return PLUGIN_CONTINUE
		}
		ColorChat(0, RED, "[MDM]^x01 Wynik glosowania:^x04 Zmiana mapy natychmiastowo^x01. Zaraz rozpocznie sie^x04 vote^x01 o mape!")
		set_task(5.0, "StartMapVote")
		Voted = true
		Choice = 1
		return PLUGIN_CONTINUE
	}
	else if((Chosen[2] > Chosen[1]) && (Chosen[2] > Chosen[3])){
		if((SmallMap && bMapsCount == 1) || (BigMap && sMapsCount == 1)){
			SmallMap ? copy(Map, 31, bMaps[bMapsInVote[1]]) : copy(Map, 31, sMaps[sMapsInVote[1]])
			ColorChat(0, RED, "[MDM]^x01 Jako kolejna bedzie grana mapa^x04 %s^x01.", Map)
			server_cmd("amx_nextmap %s", Map)
			return PLUGIN_CONTINUE
		}
		ColorChat(0, RED, "[MDM]^x01 Wynik glosowania:^x04 Zmiana mapy po zakonczeniu^x01. Zaraz rozpocznie sie^x04 vote^x01 o mape!")
		set_task(5.0, "StartMapVote")
		Voted = true
		Choice = 2
		return PLUGIN_CONTINUE
	}
	else if((Chosen[3] > Chosen[1]) && (Chosen[3] > Chosen[2])){
		ColorChat(0, RED, "[MDM]^x01 Wynik glosowania:^x04 Bez zmiany mapy^x01. Na razie mapa^x04 nie zostanie^x01 zmieniona.")
		set_task(520.0, "ResetVote")
		return PLUGIN_CONTINUE
	}
	else {
		ColorChat(0, RED, "[MDM]^x01 Zadna z opcji nie zdobyla wystarczajacej ilosci glosow. Niedlugo glosowanie zostanie powtorzone.")
		Voting = false
	}
	return PLUGIN_CONTINUE
}

public ResetVote()
	Voting = false
	
public StartMapVote()
{
	new VoteIteration
	MapsNumber = get_pcvar_num(Maps) > 5 ? 5 : get_pcvar_num(Maps)
	new Number = SmallMap ? (bMapsCount < MapsNumber ? bMapsCount : MapsNumber) : (sMapsCount < MapsNumber ? sMapsCount : MapsNumber)
	MapsNumber = Number
	new Random = SmallMap ? random_num(0, bMapsCount - 1) : random_num(0, sMapsCount - 1)
	
	for(VoteIteration = 0; VoteIteration < Number; VoteIteration++) {
		Random = -1
		while(Random == -1) {
			Random = SmallMap ? random_num(0, bMapsCount - 1) : random_num(0, sMapsCount - 1)
			for(new a = 0; a < VoteIteration; a++)
			{
				if(SmallMap){
					if(Random == bMapsInVote[a]) {
						Random = -1
					}
				}
				else {
					if(Random == sMapsInVote[a]) {
						Random = -1
					}
				}
			}
		}
		if(SmallMap)
			bMapsInVote[VoteIteration] = Random
		else
			sMapsInVote[VoteIteration] = Random
	}
	
	new menu = menu_create("\yWybierz Mape:", "StartMapVote_Handler")
	for(new i = 0; i < Number; i++){
		SmallMap ? menu_additem(menu, bMaps[bMapsInVote[i]]) : menu_additem(menu, sMaps[sMapsInVote[i]])
	}

	new players[32], inum
	get_players(players, inum, "ch")
	for(new i = 0; i < inum; i++)
	{
		if(is_user_connected(players[i]) && !is_user_hltv(players[i]))
			menu_display(players[i], menu, 0)
	}
	set_task(15.0, "Finish_MapVote", menu)
	Voted = true

	return PLUGIN_CONTINUE
}

public StartMapVote_Handler(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
		
	if (item == MENU_EXIT)
	{
		menu_cancel(id)
		return PLUGIN_HANDLED
	}

	new name[32]
	get_user_name(id, name, 31)
	
	ColorChat(0, RED, "[MDM]^x04 %s^x01 zaglosowal na^x04 %s^x01.", name, SmallMap ? bMaps[bMapsInVote[item]] : sMaps[sMapsInVote[item]])

	++Votes[item]

	menu_cancel(id)
	return PLUGIN_HANDLED
}

public Finish_MapVote() 
{
	show_menu(0, 0, "^n", 1)
	new Winner = 0
	for(new i = 0; i < MapsNumber; i++) {
		if(Votes[i] > Votes[Winner]) {
			Winner = i
		}
	}
	SmallMap ? copy(Map, 31, bMaps[bMapsInVote[Winner]]) : copy(Map, 31, sMaps[sMapsInVote[Winner]])
	if(Choice == 1 || get_pcvar_num(Type) == 0){
		ColorChat(0, RED, "[MDM]^x01 Wygrala mapa^x04 %s^x01! Zaraz nastapi^x04 zmiana mapy^x01.", Map)
		set_task(5.0, "MapChange")
	}
	if(Choice == 2 || get_pcvar_num(Type) == 1) {
		ColorChat(0, RED, "[MDM]^x01 Wygrala mapa^x04 %s^x01! Bedzie grana jako^x04 kolejna mapa^x01.", Map)
		server_cmd("amx_nextmap %s", Map)
		NextMap = true
		for(new i = 0; i < sizeof PausePlugins; i++)
			pause("ac", PausePlugins[i])
	}
	Voting = false
}

public Message_Intermission()
{
	if(NextMap)
		set_task(0.1, "MapChange")
}

public MapChange()
	server_cmd("changelevel %s", Map)

public CheckCurrentMap()
	return SmallMap ? 1 : 0
