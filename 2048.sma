#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <ColorChat>
#include <sqlx>

#define PLUGIN "2048 Game"
#define AUTHOR "HubertTM & O'Zone"

new name[33][32];
new liczby[33][16];
new wynik[33];
new rekord[33];
new bool:gra[33];
new czasgry[33];
new ruchy[33];
new limit[33];
new kiedy[33];
new buffer[512];
new Handle: g_SqlTuple;
enum _:Cvary {Host, User, Pass, DBName};
new gCvar[Cvary];

public plugin_init() {
	register_plugin(PLUGIN, "2.0", AUTHOR)
	
	register_clcmd("say /2048", "Game");
	register_clcmd("say_team /2048", "Game");
	register_clcmd("say /gra", "Game");
	register_clcmd("say_team /gra", "Game");
	register_forward(FM_CmdStart, "CmdStart");
	
	gCvar[Host] = register_cvar("2048_hostname", "localhost");
	gCvar[User] = register_cvar("2048_username", "root");
	gCvar[Pass] = register_cvar("2048_password", "password");
	gCvar[DBName] = register_cvar("2048_database", "2048");
	
	set_task(1.0, "LiczCzasGry", 0, _,_, "b");
	
	set_task(0.1, "SQLInit");
}

public SQLInit(){
	new t[4][33];
	
	get_pcvar_string(gCvar[Host], 		t[Host], 32);
	get_pcvar_string(gCvar[User], 		t[User], 32);
	get_pcvar_string(gCvar[Pass], 		t[Pass], 32);
	get_pcvar_string(gCvar[DBName], 	t[DBName], 32);
	
	g_SqlTuple = SQL_MakeDbTuple(t[Host], t[User], t[Pass], t[DBName]);

	if(g_SqlTuple == Empty_Handle)
		set_fail_state("Nie mozna utworzyc uchwytu do polaczenia");
	
	new iErr, szError[32];
	new Handle:link = SQL_Connect(g_SqlTuple, iErr, szError, 31);
	if(link == Empty_Handle) {
		log_amx("Error (%d): %s", iErr, szError);
		set_fail_state("Brak polaczenia z baza danych");
	}
	new g_Cache[512];
	
	formatex(g_Cache, charsmax(g_Cache), "CREATE TABLE IF NOT EXISTS records (name VARCHAR(32), record SMALLINT(6), result SMALLINT(6), gamelimit SMALLINT(6), whenplay SMALLINT(6), time SMALLINT(6), moves SMALLINT(6), l1 SMALLINT(6), l2 SMALLINT(6), l3 SMALLINT(6), l4 SMALLINT(6), ");
	add(g_Cache, charsmax(g_Cache), "l5 SMALLINT(6), l6 SMALLINT(6), l7 SMALLINT(6), l8 SMALLINT(6), l9  SMALLINT(6), l10 SMALLINT(6), l11 SMALLINT(6), l12 SMALLINT(6), l13 SMALLINT(6), l14 SMALLINT(6), l15 SMALLINT(6), l16 SMALLINT(6), PRIMARY KEY (name))");
	
	SQL_ThreadQuery(g_SqlTuple, "Query", g_Cache);
}

public client_connect(id){
	for(new i=0; i<16; i++)
		liczby[id][i] = 0;
		
	wynik[id] = 0;
	rekord[id] = 0;
	gra[id] = false;
	czasgry[id] = 0;
	ruchy[id] = 0;
	limit[id] = 2048;
	kiedy[id] = 1;
	get_user_name(id, name[id], charsmax(name));
	replace_all(name[id], charsmax(name), "'", "\'");
	replace_all(name[id], charsmax(name), "`", "\`");
	Wczytaj(id);
}

public client_disconnect(id){
	if(rekord[id]>0)
		Zapisz(id);
	client_connect(id);
}

public Zapisz(id){
	formatex(buffer, charsmax(buffer), "UPDATE records SET record = %i, result = %i, gamelimit = %i, whenplay = %i, time = %i, moves = %i, l1 = %i, l2 = %i, l3 = %i, l4 = %i, l5 = %i, l6 = %i, l7 = %i, l8 = %i, l9 = %i, l10 = %i, l11 = %i, l12 = %i, l13 = %i, l14 = %i, l15 = %i, l16 = %i WHERE name='%s'", 
	rekord[id], wynik[id], limit[id], kiedy[id], czasgry[id], ruchy[id], liczby[id][0], liczby[id][1], liczby[id][2], liczby[id][3], liczby[id][4], liczby[id][5], liczby[id][6], liczby[id][7], liczby[id][8], liczby[id][9], liczby[id][10], liczby[id][11], liczby[id][12], liczby[id][13], liczby[id][14], liczby[id][15], name[id]); 
	SQL_ThreadQuery(g_SqlTuple, "Query", buffer);
}

public Wczytaj(id){
	static Data[2];
	Data[0] = id;
	format(buffer,charsmax(buffer),"SELECT * FROM records WHERE name='%s'", name[id]);
	SQL_ThreadQuery(g_SqlTuple, "LoadQuery", buffer, Data, 1);
}


public LiczCzasGry(){
	for(new i=1; i<33; i++){
		if(is_user_connected(i) && gra[i]){
			czasgry[i]++;
			Game(i);
		}
	}
}

public Game(id){
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	if(is_user_alive(id) && !kiedy[id]){
		ColorChat(id, RED, "[2048]^x01 Nie mozesz zagrac bedac zywy. Mozesz to zmienic po smierci w^x04 Ustawieniach^x01.");
		gra[id] = false;
		return PLUGIN_CONTINUE;
	}
	
	gra[id] = true;
		
	if(pustych(id) == 16){
		random_liczba(id, random_miejsce(id));	
		random_liczba(id, random_miejsce(id));	
	}
	else {
		if(CzyPrzegral(id)){
			ColorChat(id, RED, "[2048]^x01 Niestety przegrales! Uzyj^x04 Resetu^x01, aby zagrac ponownie.");
			gra[id] = false;
		}
		else {
			if(CzyWygral(id)){
				ColorChat(id, RED, "[2048]^x01 Gratulacje! Wygrales z wynikiem^x04 %d^x01 (Ruchy:^x04 %d^x01 | Czas:^x04 %d s^x01).", wynik[id], ruchy[id], czasgry[id]);
				ColorChat(id, RED, "[2048]^x01 Uzyj^x04 Resetu^x01, aby zagrac ponownie.");
				gra[id] = false;
				Zapisz(id);
			}
		}
	}
	
	if(wynik[id] >= rekord[id])
		rekord[id] = wynik[id]
	
	static szText[512];
	formatex(szText, 511, "\yGRA 2048^n\wWynik:\r %d^n\wRekord:\r %d^n\wRuchy: \r%d^n\wCzas: \r%d s^n\d|", wynik[id], rekord[id], ruchy[id], czasgry[id]);
	new szLiczbyString[16][10];
	for(new i=0; i<16; i++)
	{
		num_to_str(liczby[id][i], szLiczbyString[i], 7);
		switch(liczby[id][i]){
			case 0: {	
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "\d++++|");
				else
					format(szLiczbyString[i], 9, "\d++++|");
			}
			case 2,4,8: {		
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "+++\w%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "+++\w%s\d|", szLiczbyString[i]);
			}
		case 16,32: {
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "++\w%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "++\w%s\d|", szLiczbyString[i]);
			}
		case 64: {
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "++\y%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "++\y%s\d|", szLiczbyString[i]);
			}
		case 128,256: {
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "+\y%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "+\y%s\d|", szLiczbyString[i]);
			}
		case 512: {
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "+\r%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "+\r%s\d|", szLiczbyString[i]);
			}
		default: {
				if(i != 3 && i != 7 && i != 11 && i != 15)	
					format(szLiczbyString[i], 9, "\r%s\d|", szLiczbyString[i]);
				else
					format(szLiczbyString[i], 9, "\r%s\d|", szLiczbyString[i]);
			}
		}
	}
	
	for(new j=0; j<16; j++)
	{
		add(szText, 511, szLiczbyString[j], 511);

		if(((j+1)%4) == 0 && j != 15)
			add(szText, 511, "^n\d|", 511);
	}
	new menu = menu_create(szText, "GameH");
	menu_additem(menu, "Zapisz i Wyjdz");
	menu_additem(menu, "\yUstawienia");
	menu_additem(menu, "\rReset");
	menu_additem(menu, "Top15 Rekordow");
	
	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public GameH(id, menu, item){
	menu_destroy(menu);
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	switch(item){
		case 0: gra[id] = false;
		case 1: {
			gra[id] = false;
			Settings(id);
		}
		case 2: {
			for(new i=0; i<16; i++)
				liczby[id][i] = 0;
			wynik[id] = 0;
			czasgry[id] = 0;
			ruchy[id] = 0;
			Game(id);
		}
		case 3: {
			gra[id] = false;
			Top15(id);
		}
	}
	return PLUGIN_CONTINUE;
}

public Settings(id){
	new menu = menu_create("2048: \yUstawienia", "SettingsH");
	new lmenu[16], mmenu[30];
	if(limit[id] != -1)
		formatex(lmenu, charsmax(lmenu), "Limit:\r %i", limit[id]);
	else
		formatex(lmenu, charsmax(lmenu), "Limit:\r Brak", limit[id]);
	menu_additem(menu, lmenu);
	if(kiedy[id] != 0)
		formatex(mmenu, charsmax(mmenu), "Mozliwosc Gry:\r Zawsze^n");
	else
		formatex(mmenu, charsmax(mmenu), "Mozliwosc Gry:\r Po Smierci^n");
	menu_additem(menu, mmenu);
	menu_additem(menu, "Wroc");
	
	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public SettingsH(id, menu, item){
	menu_destroy(menu);
	if(!is_user_connected(id))
		return;

	switch(item){
		case 0: {
			switch(limit[id]){
				case 2048: limit[id] = 4096;
				case 4096: limit[id] = -1;
				case -1: limit[id] = 2048;
			}
			Settings(id);
		}
		case 1: {
			switch(kiedy[id]){
				case 0: kiedy[id] = 1;
				case 1: kiedy[id] = 0;
			}
			Settings(id);
		}
		case 2: Game(id);
	}
}

public Query(FailState, Handle:query, Error[]) {
	if(FailState != TQUERY_SUCCESS) {
		log_amx("SQL Insert error: %s", Error);
		return;
	}
}

public LoadQuery(FailState, Handle:Query, Error[], Errcode, Data[], DataSize){
	if(FailState != TQUERY_SUCCESS) {
		log_amx("SQL Insert error: %s", Error);
		return;
	}
	new id = Data[0];
	if(SQL_NumResults(Query)){
		rekord[id] = SQL_ReadResult(Query, 1);
		wynik[id] = SQL_ReadResult(Query, 2);
		limit[id] = SQL_ReadResult(Query, 3);
		kiedy[id] = SQL_ReadResult(Query, 4);
		czasgry[id] = SQL_ReadResult(Query, 5);
		ruchy[id] = SQL_ReadResult(Query, 6);
		for(new i=0; i<16; i++)
			liczby[id][i] = SQL_ReadResult(Query, 7+i);
	}
	else {
		formatex(buffer, charsmax(buffer), "INSERT INTO `records` VALUES ('%s', 0, 0, 2048, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);", name[id]);
		SQL_ThreadQuery(g_SqlTuple, "Query", buffer);
	}
}

public Top15(id){
	new szTemp[512];
	static Data[2];
	Data[0] = id;
	
	format(szTemp,charsmax(szTemp),"SELECT name, record FROM records ORDER BY record DESC LIMIT 15");
	SQL_ThreadQuery(g_SqlTuple, "ShowTop15", szTemp, Data, 1);
}

public ShowTop15(FailState, Handle:Query, Error[], Errcode, Data[], DataSize){
	if(FailState) {
		log_amx("SQL Error: %s (%d)", Error, Errcode)
		return PLUGIN_HANDLED;
	}
	new id;
	id = Data[0];
	static iLen, place, sBuffer[1024];
	place = 0;
	iLen = format(sBuffer, 1023, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += format(sBuffer[iLen], 1023 - iLen, "%8s %20s %4s^n", "Rank", "Nick", "Rekord");
	
	while(SQL_MoreResults(Query)){
		place++
		static player_name[33];
		SQL_ReadResult(Query, 0, player_name, 32);
		new record = SQL_ReadResult(Query, 1);
		replace_all(player_name, 32, "<", "")
		replace_all(player_name, 32, ">", "")
		
		iLen += format(sBuffer[iLen], 1023 - iLen, "#%3i %-22.22s %7i^n", place, player_name, record)
		
		SQL_NextRow(Query) 
	}
	show_motd(id, sBuffer, "Top15 Rekordow w 2048");
	return PLUGIN_HANDLED;
}

public random_liczba(id, miejsce)
	liczby[id][miejsce] = random(3)?2:4;

public random_miejsce(id){
	new miejsc[16], maks=0;
	
	for(new i=0; i<16; i++){
		if(!liczby[id][i])
			miejsc[maks++] = i;
	}
	
	return miejsc[random(maks)];
}

public pustych(id){
	new puste;
	
	for(new i=0; i<16; i++){
		if(!liczby[id][i])
		puste++;
	}
	
	return puste;
}

public CmdStart(id, uc_handle){
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(!gra[id])
		return PLUGIN_CONTINUE;
	
	new button = get_uc(uc_handle, UC_Buttons);
	
	if(is_user_alive(id) && button && !kiedy[id])
		return PLUGIN_CONTINUE;
	
	new oldbutton = pev(id, pev_oldbuttons);
	
	if(button == oldbutton)
	return PLUGIN_CONTINUE;
	
	if(button & IN_FORWARD)
		Gora(id);
	else {
		if(button & IN_BACK)
			Dol(id);
		else {
			if(button & IN_MOVERIGHT || button & IN_RIGHT)
				Prawo(id);
			else {
				if(button & IN_MOVELEFT || button & IN_LEFT)
					Lewo(id);
			}
		}
	}
	
	
	return PLUGIN_CONTINUE
}

public Gora(id)
{
	new bool:ruszylo = false;
	
	for(new i=4; i<16; i++){
		if(!liczby[id][i-4] && liczby[id][i]){
			liczby[id][i-4]=liczby[id][i]
			liczby[id][i]=0;
			ruszylo=true;
			
			i=3;
		}
	}
	
	
	for(new i=4; i<16; i++){
		if(liczby[id][i-4] == liczby[id][i] && liczby[id][i]){
			liczby[id][i-4]*=2;
			wynik[id] += liczby[id][i-4];
			liczby[id][i]=0;
			ruszylo=true;
		}
	}
	
	
	for(new i=4; i<16; i++){
		if(!liczby[id][i-4] && liczby[id][i]){
			liczby[id][i-4]=liczby[id][i]
			liczby[id][i]=0;
			ruszylo=true;
			
			i=3
		}
	}
	
	if(ruszylo){
		if(pustych(id))
			random_liczba(id, random_miejsce(id));	

		Game(id)
		
		ruchy[id]++;
	}
}

public Dol(id)
{
	new bool:ruszylo = false;
	
	for(new i=11; i>=0; i--){
		if(!liczby[id][i+4] && liczby[id][i]){
			liczby[id][i+4]=liczby[id][i];
			liczby[id][i]=0;
			ruszylo=true;
			
			i=12;
		}
	}
	
	for(new i=11; i>=0; i--){
		if(liczby[id][i+4] == liczby[id][i] && liczby[id][i]){
			liczby[id][i+4]*=2;
			wynik[id] += liczby[id][i+4]
			liczby[id][i]=0;
			ruszylo=true;
		}
	}
	
	for(new i=11; i>=0; i--){
		if(!liczby[id][i+4] && liczby[id][i]){
			liczby[id][i+4]=liczby[id][i];
			liczby[id][i]=0;
			ruszylo=true;
			
			i=12;
		}
	}
	
	
	if(ruszylo){
		if(pustych(id))
			random_liczba(id, random_miejsce(id));	

		Game(id)
		
		ruchy[id]++;
	}
}

public Prawo(id)
{
	new bool:ruszylo = false;
	for(new i=14; i>=0; i--){
		if(i==3 || i==7 || i==11)
			continue;
		
		if(!liczby[id][i+1] && liczby[id][i]){
			liczby[id][i+1]=liczby[id][i];
			liczby[id][i]=0;
			ruszylo=true;
			
			i=15;
		}
	}
	
	for(new i=14; i>=0; i--){
		if(i==3 || i==7 || i==11)
			continue;
		
		if(liczby[id][i+1] == liczby[id][i] && liczby[id][i]){
			liczby[id][i+1]*=2;
			wynik[id]+=liczby[id][i+1]
			liczby[id][i]=0;
			ruszylo=true;
			
		}
	}
	
	for(new i=14; i>=0; i--){
		if(i==3 || i==7 || i==11)
			continue;
		
		if(!liczby[id][i+1] && liczby[id][i]){
			
			liczby[id][i+1]=liczby[id][i];
			liczby[id][i]=0;
			ruszylo=true;
			
			i=15;
		}
	}
	
	
	
	if(ruszylo){
		if(pustych(id))
			random_liczba(id, random_miejsce(id));	

		Game(id)
		
		ruchy[id]++;
	}
}

public Lewo(id)
{
	new bool:ruszylo = false;
	
	for(new i=1; i<16; i++){
		if(i== 4 || i==8 || i== 12)
			continue;
		
		if(!liczby[id][i-1] && liczby[id][i]){
			liczby[id][i-1]=liczby[id][i];
			liczby[id][i]=0;
			ruszylo=true;
			
			i=0;
		}
	}
	
	for(new i=1; i<16; i++){
		if(i== 4 || i==8 || i== 12)
			continue;
		
		if(liczby[id][i-1] == liczby[id][i] && liczby[id][i]){
			liczby[id][i-1]*=2;
			wynik[id]+=liczby[id][i-1]
			liczby[id][i]=0;
			ruszylo=true;
		}
	}
	
	for(new i=1; i<16; i++){
		if(i== 4 || i==8 || i== 12)
			continue;
		
		for(new i=1; i<16; i++){
			if(i== 4 || i==8 || i== 12)
				continue;
			
			if(!liczby[id][i-1] && liczby[id][i]){
				liczby[id][i-1]=liczby[id][i];
				liczby[id][i]=0;
				ruszylo=true;
				
				i=0;
			}
		}
	}
	
	
	if(ruszylo){
		if(pustych(id))
			random_liczba(id, random_miejsce(id));	

		Game(id)
		
		ruchy[id]++;
	}
}

public CzyPrzegral(id)
{
	if(pustych(id) != 0)
		return 0;
	
	for(new i=4; i<16; i++){
		if(liczby[id][i-4] == liczby[id][i] && liczby[id][i]){
			return 0;
		}
	}
	
	for(new i=11; i>=0; i--){
		if(liczby[id][i+4] == liczby[id][i] && liczby[id][i]){
			return 0;
		}
	}	
	
	for(new i=14; i>=0; i--){
		if(i==3 || i==7 || i==11)
			continue;
		
		if(liczby[id][i+1] == liczby[id][i] && liczby[id][i]){
			return 0;
		}
	}
	for(new i=1; i<16; i++){
		if(i== 4 || i==8 || i== 12)
			continue;
		
		if(liczby[id][i-1] == liczby[id][i] && liczby[id][i]){
			return 0;
		}
	}
	
	return 1;
}

public CzyWygral(id){
	for(new i=0; i<16; i++)
		switch(limit[id]){
			case 2048: {
			if(liczby[id][i] == 2048)
				return 1;
			}
			case 4096: {
			if(liczby[id][i] == 4096)
				return 1;
			}
			case -1:
				return 0;
		}
	return 0;
}
