#include <amxmodx>
#include <amxmisc>

new mc_duzamapa // Menu
new mcbc_duzamapa // Menu Callback

new gWpisal[32]
new gMaps[300][32]
new gMapsCount=0
new gVoteRunning=0
new gVotes[5]
new gMapsInVote[5]
new gGranaDuzaMapa
new gAdmins[32]
new gIsAdmin

public plugin_init() {
	register_plugin("Duza Mapa", "1.0", "OZone")
	register_cvar("amx_duzamapa_admin","0")
	register_clcmd ( "say", "sprawdz" )
	register_clcmd ( "say_team", "sprawdz" )
	set_task(120.0,"reklama",0,"",0,"b")
	wczytaj_mapy()
}

public wczytaj_mapy()
{
	new rsFile[128],s[128],i
	new current_map[19]
	get_mapname(current_map, 20)
	get_configsdir(rsFile, 128)
	format(rsFile, 128 ,"%s/mapcycle_duze.txt", rsFile) // should be something like addons/amxmodx/configs/
	i=fopen(rsFile,"rt")
	gMapsCount=0
	if(i==0){
		log_amx("Error loading config file! [%s]", rsFile)
	} else {
		log_amx("Reading config file [%s]", rsFile)
		while (!feof(i)) // Czytamy mapki
		{
			fgets(i,s,30)
			trim(s)
			if(s[0]!=0) {
				if(equal(current_map, s)) {
					gGranaDuzaMapa=1
				}
				log_amx("Loaded [%s]", s);
				copy(gMaps[gMapsCount], 30, s)
				gMapsCount++
			}
		}
		fclose(i)
	}
	log_amx("Loaded maps: %d", gMapsCount)
	return PLUGIN_CONTINUE
}

public client_connect(id) {
	if(gGranaDuzaMapa)
		return PLUGIN_CONTINUE

	if(get_user_flags(id) & ADMIN_KICK) {
		gAdmins[id] = 1
		gIsAdmin++
	}
 	if((gIsAdmin > 0) && (get_cvar_num("amx_duzamapa_admin") == 1))
		return PLUGIN_CONTINUE
	if(player_count()>=8) {
		client_print(0,print_chat, "Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2))
	}
	return PLUGIN_CONTINUE
}

public client_disconnect(id) {
	if(gGranaDuzaMapa)
		return PLUGIN_CONTINUE
	
	if(gAdmins[id] == 1) {
		gIsAdmin--
		gAdmins[id] = 0
	}

	if(gWpisal[id]==1) {
		gWpisal[id]=0
	}
 	if((gIsAdmin > 0) && (get_cvar_num("amx_duzamapa_admin") == 1))
		return PLUGIN_CONTINUE
	if(player_count()>=8) {
		client_print(0,print_chat, "Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2))
	}
	return PLUGIN_CONTINUE
}

public sprawdz(id) {
 	if((gIsAdmin > 0) && (get_cvar_num("amx_duzamapa_admin") == 1))
		return PLUGIN_CONTINUE

	new txt[90], username[32]
	get_user_name(id, username, 32)
	read_args ( txt, 90 )

	if(equali(txt, "^"duza mapa^""))
	{
		if(gGranaDuzaMapa) {
			client_print(0, print_chat, "Duza mapa jest obecnie grana!")
			return PLUGIN_CONTINUE
		}

		if(gVoteRunning)
			return PLUGIN_CONTINUE
		if(player_count()<=8)
		{
			if(gWpisal[id]==0) {
				gWpisal[id]=1
				client_print(0,print_chat, "[%s] zaglosowal na zmiane na duza mape", username)
				client_print(0,print_chat, "Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2))
				log_amx("[%s] zaglosowal na zmiane na duzamape", username)
				log_amx("Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2))
			} else
			{
				gWpisal[id]=0
				client_print(0,print_chat, "[%s] wypisal sie z glosowania na zmiane na duza mape", username)
				client_print(0,print_chat, "Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2))
				log_amx("[%s] wypisal sie z glosowania na zmiane na duza mape", username)
				log_amx("Potrzebnych glosow na zmiane na duza mape: %d", (player_count()/2));
			}

			if((player_count()/2)<=0) // odpalamy vote
			{
				run_vote()
			}
		}
	}
	return PLUGIN_CONTINUE
}

public run_vote() { // przygotowujemy vote na nextmap
	gVoteRunning=1
	new a, toLog[128]
	new iterateVotes
	new rand = random_num(0, gMapsCount-1) // pierwsza mapa losowa

	for(iterateVotes=0; iterateVotes<3; iterateVotes++) { // 3x szukamy nastepnych losowych map (ma byc 3)
		rand=-1
		while(rand == -1) {
			rand = random_num(0, gMapsCount-1)
			for(a = 0; a<iterateVotes; a++) // sprawdzamy, czy wylosowana mapa juz nie zostala wylosowana
			{
				if(rand == gMapsInVote[a]) {
					rand = -1
				}
			}
		}
		gMapsInVote[iterateVotes] = rand
		format(toLog, 200, "%s %s", toLog, gMaps[rand]) // debugger
	}

	mc_duzamapa = menu_create("Wybierz duza mape", "mh_c_duzamapa") // przygotowujemy menu
	mcbc_duzamapa = menu_makecallback("mcb_c_duzamapa")
	menu_additem(mc_duzamapa, gMaps[gMapsInVote[0]], "ma_c_duzamapa", ADMIN_ALL, mcbc_duzamapa)
	menu_additem(mc_duzamapa, gMaps[gMapsInVote[1]], "ma_c_duzamapa", ADMIN_ALL, mcbc_duzamapa)
	menu_additem(mc_duzamapa, gMaps[gMapsInVote[2]], "ma_c_duzamapa", ADMIN_ALL, mcbc_duzamapa)
	/* Menu End */

	new iPlayers[32],iNum
	get_players(iPlayers, iNum)
	for(new i=0;i<iNum;i++) // wyswietlamy menu dla kazdego gracz, ktory jest polaczony
	{
	     if(is_user_connected(iPlayers[i]))
	     {
			menu_display(iPlayers[i], mc_duzamapa, 0)
	     }
	}

	log_amx("%s",toLog) // debugger
	set_task(10.0, "change_map", 666) // za 10 sekund konczymy vote
}

public change_map() {
	new winner=0
	for(new i=1; i<3; i++) { // wyszukujemy mape z najwyzsza iloscia glosow
		if(gVotes[i]>gVotes[winner]) {
			winner = i
		}
	}
	menu_destroy(mc_duzamapa) // usuwamy menu - koniec glosowania!

	client_print(0, print_chat,"****************")
	client_print(0, print_chat,"*** KONIEC GLOSOWANIA! Zmieniam na duza mape: %s (glosow: %i)", gMaps[gMapsInVote[winner]], gVotes[winner]) // wyswietlamy info o malej mapie
	client_print(0, print_chat,"****************")
	log_amx("Duza mapa: %s (glosow: %i)", gMaps[gMapsInVote[winner]], gVotes[winner])
	server_cmd("changelevel %s", gMaps[gMapsInVote[winner]])
}


public reklama() {
	if(gGranaDuzaMapa)
		return PLUGIN_CONTINUE

	client_print(0,print_chat,"Jesli na serwerze jest duzo graczy, mozna zmienic mape na wieksza wpisujac ^"duza mapa^" !")
	return PLUGIN_CONTINUE
}

public player_count() {
	new iPlayers[32], iNum, count
	get_players(iPlayers, iNum)
	for(new i=0;i<iNum;i++)
	{
	     if(is_user_connected(iPlayers[i]) && !is_user_bot(iPlayers[i]) && !is_user_hltv(iPlayers[i]))
	     {
			count++
	     }
	}
	return count
}

public mh_c_duzamapa(id, menu, item) {
	if(item>-1 && item<3) { // 3 map, nie obchodza nas inne wybory
		new name[31]
		get_user_name (id, name, 32)
		gVotes[item]++
		client_print(0,print_chat,"%s wybral %s (glosow: %i)", name, gMaps[gMapsInVote[item]], gVotes[item]) // wypisujemy jaka mape wybral gracz i ile ma glosow
		log_amx("%s wybral %s (glosow: %i)", name, gMaps[gMapsInVote[item]], gVotes[item])
	}
}

public ma_c_duzamapa(id) {
}

public mcb_c_duzamapa(id, menu, item) {
}