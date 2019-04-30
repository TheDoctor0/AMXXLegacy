#include <amxmodx>

#define PLUGIN "PW Message"
#define VERSION "2.0c"
#define AUTHOR "HubertTM"

new PW[33][33];
new bool:Wysylal[33][33];

new maxplayers = 32;

new const szWulgi[][] = {
	"kurw",
	"huj",
	"cwel",
	"ysyn",
	"spierd",
	"dziwk",
	"jeban",
	"jebac",
	"cipa",
	"cipsk",
	"ruchane",
	"ruchal",
	"frajer",
	"pala",
	"pierda",
	"kutas",
	"ciot",
	"cipk",
	"pedal",
	"cipy",
	"pierdo",
	".pl",
	".eu",
	".com",
	"xaa",
	"zapraszam",
	"wejdz",
	"ip",
	"www",
	"skurw",
	"fiut",
	"cfel"
}


new cPodpowiadanie, pPodpowiadanie;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say_team", "WiadomoscSay");
	register_clcmd("say", "WiadomoscSay");
	register_clcmd("say /pw", "WiadomoscPW");
	register_clcmd("say_team /pw", "WiadomoscPW");
	register_clcmd("say /PW", "WiadomoscPW");
	register_clcmd("say_team /PW", "WiadomoscPW");
	register_clcmd("PW", "PWread");
	
	maxplayers = get_maxplayers();
	
	cPodpowiadanie = register_cvar("pw_msgtoalive", "1");
}

public plugin_cfg(){
	pPodpowiadanie = get_pcvar_num(cPodpowiadanie);
}

stock searchip(str[]){
	new len = strlen (str), punkty = 0;
	
	for(new i = 0; i < len; i++)
	{
		if ( str[i] == 'x' )
		punkty++;
		else
		if ( str[i] == '/' )
		punkty++;
		else
		if ( str[i] == ':' )
		punkty+=2;
		else
		if ( str[i] == '.' || str[i] == ',')
		punkty++;
		else
		if ( str[i] == '1' || str[i] == '9' || str[i] == '2' || str[i] == '7' || str[i] == '0')
		punkty++;
	}
	
	return punkty;
}

public WiadomoscSay(id){
	new szSay[199];
	read_argv(1, szSay, 198)
	
	if(!equali(szSay, "/pw ", 4))
	return PLUGIN_CONTINUE;
	
	replace_all(szSay, 198, "/pw ", "");
	replace_all(szSay, 198, "/PW ", "");
	replace_all(szSay, 198, "/Pw ", "");
	replace_all(szSay, 198, "/pW ", "");
	
	new szArg2[32];
	parse(szSay, szArg2, 31);
	
	replace_all(szArg2, 31, " ", "");
	replace_all(szArg2, 31, ",", " ");
	new szText[10][9];
	
	parse(szArg2, szText[0], 9, szText[1], 9, szText[2], 9, szText[3], 9, szText[4], 9, szText[5], 9, szText[6], 9, szText[7], 9, szText[8], 9, szText[9], 9);
	
	new liczba = 0;
	new ilosc = 0;
	
	for(new i=0; i<10; i++){
		if(!szText[i][0])
		continue;
		
		liczba = str_to_num(szText[i]);
		
		if(0 < liczba && liczba != get_user_userid(id)){
			if(get_id2(liczba)){
				PW[id][get_id2(liczba)] = 1;
				ilosc++;
			}
		}
	}
	
	if(ilosc)
	client_cmd(id, "messagemode PW");
	else
	client_print_color(id, id, "^x03[PW]^x01 Wpisales cos zle :( /pw numer_gracza_z_menu np. /pw 4");
	
	return PLUGIN_HANDLED_MAIN;
}


public get_id2(id2){
	for(new i=1;i<=maxplayers; i++){
		if(is_user_connected(i)){
			if(get_user_userid(i) == id2)
			return i;
		}
	}
	
	return 0;
}

public WiadomoscPW(id){
	new name[32], name2[64], idsz[9];
	
	new menu = menu_create("Do kogo wyslasz PW? Oznacz graczy!", "WiadomoscPWh");
	
	new j=0;
	
	for(new i=1;i<=maxplayers; i++){
		if(is_user_connected(i) && i != id){
			
			if(is_user_bot(i) || is_user_hltv(i))
			continue;
			
			if(!PW[id][i])
			continue;
			
			if(!pPodpowiadanie && !is_user_alive(id) && is_user_alive(i))
			continue;
			
			j++;
			
			if(j%7 == 0 && j){
				menu_additem(menu, "\yWyslij Wiadomosc(i)", "-593");
			}
			else
			{
				get_user_name(i, name, 31);
				num_to_str(get_user_userid(i), idsz, 8);
				
				if(PW[id][i]){
					if(j%7 == 6 && j)
					formatex(name2, 63, "\r%s \y(%d)^n", name, get_user_userid(i));
					else
					formatex(name2, 63, "\r%s \y(%d)", name, get_user_userid(i));
					
					menu_additem(menu, name2, idsz);
				}
				else
				{
					if(j%7 == 6 && j)
					formatex(name2, 63, "%s \y(%d)^n", name, get_user_userid(i));
					else
					formatex(name2, 63, "%s \y(%d)", name, get_user_userid(i));
					
					menu_additem(menu, name2, idsz);
				}
			}
		}
	}
	
	for(new i=1;i<=maxplayers; i++){
		if(is_user_connected(i) && i != id){
			
			if(is_user_bot(i) || is_user_hltv(i))
			continue;
			
			if(!Wysylal[id][i] || PW[id][i])
			continue;
			
			if(!pPodpowiadanie && !is_user_alive(id) && is_user_alive(i))
			continue;
			
			j++;
			
			if(j%7 == 0 && j){
				menu_additem(menu, "\yWyslij Wiadomosc(i)", "-593");
			}
			else
			{
				get_user_name(i, name, 31);
				num_to_str(get_user_userid(i), idsz, 8);
				
				if(j%7 == 6 && j)
				formatex(name2, 63, "%s \y(%d)^n", name, get_user_userid(i));
				else
				formatex(name2, 63, "%s \y(%d)", name, get_user_userid(i));
				
				menu_additem(menu, name2, idsz);
			}
		}
	}
	
	for(new i=1;i<=maxplayers; i++){
		if(is_user_connected(i) && i != id){

			if(is_user_bot(i) || is_user_hltv(i))
			continue;
		
			if(Wysylal[id][i] || PW[id][i])
			continue;
			
			if(!pPodpowiadanie && !is_user_alive(id) && is_user_alive(i))
			continue;
			
			j++;
			
			if(j%7 == 0 && j){
				menu_additem(menu, "\yWyslij Wiadomosc(i)", "-593");
			}
			else
			{
				get_user_name(i, name, 31);
				num_to_str(get_user_userid(i), idsz, 8);
				
				if(j%7 == 6 && j)
				formatex(name2, 63, "%s \y(%d)^n", name, get_user_userid(i));
				else
				formatex(name2, 63, "%s \y(%d)", name, get_user_userid(i));
				
				
				menu_additem(menu, name2, idsz);
			}
		}
	}
	
	if(j%7 != 0)
	menu_additem(menu, "\yWyslij Wiadomosc(i)", "-593");
	
	menu_setprop(menu, MPROP_BACKNAME, "<-");
	menu_setprop(menu, MPROP_NEXTNAME, "->");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	
	if(j)
	menu_display(id, menu);
	
	return PLUGIN_HANDLED_MAIN;
}


public WiadomoscPWh(id, menu, item){
	if(item == MENU_EXIT)
	return;
	
	if(!is_user_connected(id))
	return;
	
	new id_pw2, id_pw;
	new aces, info[9], name[32], callback;
	menu_item_getinfo(menu, item, aces, info, 6, name, 31, callback);
	id_pw2 = str_to_num(info);
	id_pw = get_id2(id_pw2);
	
	if((!is_user_connected(id_pw) && id_pw2 != -593) || (id_pw == 0 && id_pw2 != -593)){
		client_print_color(id, id, "^x03[PW]^x01 Ten gracz wyszedl z serwera!", name);
		WiadomoscPW(id);
		return;
	}
	
	if(id_pw2 != -593){
		PW[id][id_pw] = !PW[id][id_pw];
		
		replace_all(name, 31, "\y", "");
		
		if(PW[id][id_pw])
		client_print_color(id, id, "^x03[PW]^x01 Oznaczono^x04 %s^x01!", name);
		
		WiadomoscPW(id);
	}
	else
	{
		if(GetSendMsg(id))
		client_cmd(id, "messagemode PW", name);
		else
		client_print_color(id, id, "^x03[PW]^x01 Oznacz kogos!");
	}
}

public PWread(id){
	new arg[162]
	read_argv(1, arg, 151);
	
	if(arg[0] == 0){
		for(new i=1; i<=maxplayers; i++){
		
			if(PW[id][i]){
				Wysylal[id][i] = true;
				Wysylal[i][id] = true;
			}
			
			PW[id][i] = 0;
		}
		
		return PLUGIN_HANDLED_MAIN;
	}
	
	for(new i=1; i<=maxplayers; i++)
	if(PW[id][i] && (!is_user_connected(i) || (!pPodpowiadanie && !is_user_alive(id) && is_user_alive(i)))){	
		PW[id][i] = 0;
	}
	
	for(new i=0;i < sizeof szWulgi; i++){
		if(containi(arg, szWulgi[i]) > -1)
		{
			arg = "Prawdopodobne - wulgaryzmy lub reklama!";
			break;
		}
	}
	
	if(searchip(arg) >= 8)
	{
		arg = "Prawdopodobna reklama";
	}
	
	
	new name[32], name2[32];
	get_user_name(id, name, 31);
	
	new LiczbaWiadomosci = GetSendMsg(id);
	
	if(LiczbaWiadomosci == 1){
		for(new i=1; i<=maxplayers; i++){
			if(PW[id][i] && is_user_connected(i) && i != id){
				get_user_name(i, name2, 31);
				client_print_color(i, id, "^x03%s -> Ja:^x01 %s", name, arg);
				client_print_color(id, id, "^x03Ja -> %s:^x01 %s", name2, arg);
				
				break;
			}
		}
	}
	else
	if(LiczbaWiadomosci)
	{
		new szID[39], szUserID[9];
		
		for(new i=1; i<=maxplayers; i++)
		{
			if(PW[id][i] && is_user_connected(i)){
				num_to_str(get_user_userid(i), szUserID, 8);
				format(szID, 39, "%s%s%s", szID,strlen(szID)?", ":"", szUserID);
			}
		}
		
		client_print_color(id, id, "^x03Ja -> %s:^x01 %s", szID, arg);
		
		for(new i=1; i<=maxplayers; i++){
			if(PW[id][i] && is_user_connected(i) && i != id){
				client_print_color(i, id, "^x03%s -> Ja:^x01 %s", name, arg);
			}
		}
	}
	
	if(LiczbaWiadomosci)
	{
		client_cmd(id, "messagemode PW", name);
	}
	
	return PLUGIN_HANDLED_MAIN;
}


stock GetSendMsg(id){
	new j=0;
	
	for(new i=1; i<=maxplayers; i++)
	if(PW[id][i] && is_user_connected(i) && i != id)
	j++;
	
	return j;
}

public client_connect(id){
	for(new i=1; i<=maxplayers; i++){
		Wysylal[id][i] = false;
		Wysylal[i][id] = false;
		
		if(PW[id][i])
		PW[id][i] = 0;
		
		if(PW[i][id])
		PW[i][id] = 0;
	}
}

public client_disconnected(id){
	for(new i=1; i<=maxplayers; i++){
		Wysylal[id][i] = false;
		Wysylal[i][id] = false;
		
		if(PW[id][i])
		PW[id][i] = 0;
		
		if(PW[i][id]){
		PW[i][id] = 0;
		
		if(is_user_connected(i))
		client_print_color(i, i, "^x03[PW]^x01 Ktos z odbiorcow sie rozlaczyl! Jednak kontynuje prace bez niego!");
		
		}
	}
}