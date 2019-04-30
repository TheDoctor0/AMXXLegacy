#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <nvault>
#include <colorchat>
#include <fakemeta_util>

#define PLUGIN "Call of Duty: MW Mod"
#define VERSION "0.7.9 Beta"
#define AUTHOR "QTM_Peyote"

#define STANDARDOWA_SZYBKOSC 250.0
#define STANDARDTIMESTEPSOUND 400
new Odliczanie[33];
native cod_add_wskrzes(id, ile)
#define ZADANIE_POKAZ_INFORMACJE 672
#define ZADANIE_WSKRZES 704
#define ZADANIE_WYSZKOLENIE_SANITARNE 736
#define ZADANIE_POKAZ_REKLAME 768
#define ZADANIE_USTAW_SZYBKOSC 832
#define ZADANIE_ODBIJAJ -96
#define MAX_PLAYERS     32
#define MAXLVL 301

#define TASKID_REVIVE   1337
#define TASKID_RESPAWN  1338
#define TASKID_CHECKRE  1339
#define TASKID_CHECKST  13310
#define TASKID_ORIGIN   13311
#define TASKID_SETUSER  13312

#define pev_zorigin     pev_fuser4
#define seconds(%1) ((1<<12) * (%1))
#define Keysrod (1<<0)|(1<<1)|(1<<9) // Keys: 1234567890
//#define BOTY 1

new SyncHudObj;
new SyncHudObj2;
new SyncHudObj3;
new g_msg_screenfade;

new sprite_white;
new sprite_blast;

new g_vault;

new podkladajacy;
new rozbrajajacy;

new doswiadczenia_za_zabojstwo;
new doswiadczenie_za_bombe;
new doswiadczenie_za_wygrana;
new doswiadczenie_za_hs;
new doswiadczenie_za_kase;
new doswiadczenie_za_kasez;
new doswiadczenie_za_totek;
new doswiadczenie_za_fail;
new oddaj_id[33];
new bool:dostal_przedmiot[33];

new Ubrania_CT[4][]={"sas","gsg9","urban","gign"};
new Ubrania_Terro[4][]={"arctic","leet","guerilla","terror"};

new const maxAmmo[31]={0,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100};
new const maxClip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20, 
10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

new g_msgHostageAdd, g_msgHostageDel;

new pozostale_elektromagnesy[33];

new pcvar_ilosc_elektromagnesow, pcvar_zasieg, pcvar_czas_dzialania, pcvar_widocznosc_fali;

new informacje_przedmiotu_gracza[33][2];
new const nazwy_przedmiotow[][] = {"Brak", 
	"Buty Szturmowego", //1
	"Podwojna Kamizelka", //2
	"Wzmocniona Kamizelka", //3
	"Weteran Noza", //4
	"Zaskoczenie Wroga", //5
	"Plaszcz Partyzanta", //6 
	"Morfina", //7
	"Noz Komandosa", //8
	"Podrecznik Szpiega", //9
	"Tajemnica Generala", //10
	"Notatki Ninji", //11
	"Tajemnica Wojskowa", //12
	"AWP Sniper", //13
	"Adrenalina", //14
	"Tajemnica Rambo", //15
	"Wyszkolenie Sanitarne", //16
	"Kamizelka NASA", //17
	"Wytrenowany Weteran", //18
	"Apteczka", //19
	"Eliminator Rozrzutu", //20
	"Tytanowe Naboje", //21
	"Naboje Pulkownika", //22
	"Ogranicznik Rozrzutu", //23
	"Tarcza SWAT", //24
	"Wytrenowany Rekrut", //25
	"Pancerz Nomexowy", //26
	"Notatki Kapitana", //27
	"Modul odrzutowy", //28
	"Umiejetnosc Wojownika", //29
	"Tajemnica Komandosa", //30
	"Podstepny Szpieg", //31
	"Marzenie Komandosa", //32
	"Mistrz Shotguna", //33
	"Skoczek", //34
	"Zestaw Medyka", //35
	"Furia Generala", //36
	"Gniew Szeregowca", //37
	"Tajemnica Skoczka", //38
	"Bandaze Medyka", //39
	"Kamizelka Terrorysty", //40
	"Kamuflaz", //41
	"Klatwa Ducha", //42
	"Skupienie Mistrza", //43
	"Notatki Snajpera", //44
	"Obrona Ninjy", //45
	"Zestaw Snajperski", //46
	"Tajemnica Majora", //47
	"Umiejetnosc Technika", //48
	"Helm Kapitana", //49
	"Kombinezon z Tytanu", //50
	"Bezlik Ammo", //51
	"Rada McGyvera", //52
	"Magazynek Rambo ", //53
	"Rada Wampira", //54
	"Rozbrajacz", //55
	"Moc Ducha", //56
	"Teleport", //57
	"Zwinne Palce", //58
	"Zaawansowana Lewitacja", //59
	"Ghost", //60
	"Elektromagnes Militarny", //61
	"Radar Telegrafisty", //62
	"Pancerz Kapitana", //63
	"Zemsta Niesmiertelnego", //64
	"Zegar Msciciela" //65
};

new const opisy_przedmiotow[][] = {"Zabij kogos aby dostac przedmiot", 
	"Cicho biegasz", //1
	"Obniza uszkodzenia zadawane graczowi o LW", //2
	"Obniza uszkodzenia zadawane graczowi o LW", //3
	"Zadajesz wieksze obrazenia nozem", //4
	"Gdy trafisz kogos od tylu, obrazenia sa 2 razy wieksze", //5
	"Masz LW premii niewidocznosci", //6
	"1/LW szans do ponownego odrodzenia sie po smierci", //7
	"Natychmiastowe zabicie z Noza", //8
	"Masz 1/LW szans na natychmiastowe zabicie z HE. Posiadasz takze ubranie wroga", //9
	"Natychmiastowe zabicie granatem HE. Zadajesz LW dodatkowych obrazen", //10
	"Mozesz zrobic podwojny skok w powietrzu", //11
	"Twoje obrazenia sa zredukowane o 5. Masz 1/LW szans na oslepienie wroga", //12
	"Natychmiastowe zabicie z AWP", //13
	"Za kazdego Fraga dostajesz 50 zycia", //14
	"Za kazdego Fraga dostajesz pelen magazynek oraz +20 hp", //15
	"Dostajesz 10 HP co 5 sekund", //16
	"Masz 500 pancerza", //17
	"Dostajesz +100 HP co runde, wolniej biegasz", //18
	"Uzyj, aby uleczyc sie do maksymalnej ilosci HP", //19
	"Nie posiadasz rozrzutu broni", //20
	"Zadajesz 10 obrazen wiecej", //21
	"Zadajesz 20 obrazen wiecej", //22
	"Twoj rozrzut jest mniejszy", //23
	"Nie dzialaja na ciebie zadne przedmioty", //24
	"Dostajesz +50 HP co runde, wolniej biegasz", //25
	"Masz 1/LW szans na odbicie pocisku przez pancerz", //26
	"Jestes odporny na 3 pociski w kazdej rundzie", //27
	"Nacisnij CTRL i SPACE aby uzyc modulu, modul laduje sie co 4 sekundy", //28
	"Jestes szybszy o 20 jednostek, redukcja obrazen o 10, +50 hp", //29
	"Dostajesz +100hp, +20 do obrazen oraz twoj bieg jest zredukowany o 30", //30
	"+10 dmg, kameleon, 1/LW z he", //31 
	"1/LW na zabicie z Deagle", //32
	"1/LW na zabicie z Shotguna", //33
	"Skaczesz wyzej", //34
	"Co 5s regeneruje ci sie 15hp", //35
	"Dostajesz +100 HP, cicho biegasz oraz zadajesz o 8 obrazen wiecej", //36
	"Obniza otrzymywane obrazenia o 10, szybszy bieg, +10 dmg", //37
	"Posiadasz auto bunny hopa + 70hp", //38
	"Tego itemu mozna uzyc raz na runde, regeneruje HP w pelni", //39
	"500 pancerza, 1/LW szans na odbicie pocisku", //40
	"Gdy kucasz stajesz sie niewidzialny", //41
	"10 sekund przenikania przez sciany.", //42
	"+10 dmg, cichy bieg, szybszy bieg o 50 jednostek, +100 hp", //43
	"+5 dmg oraz redukcja dmg o 7",  //44
	"Uzyj[e] aby stac sie niesmiertelnym na 5 sec", //45
	"Kameleon oraz 1/LW ze scouta", //46
	"+20 dmg, cichy bieg", //47
	"Posiadasz ZOOM'a na wszystkich broniach", //48
	"Jestes odporny na headshoty", //49
	"Mozna Cie zabic jedynie strzalami w glowe", //50
	"Niekonczacy sie magazynek", //51
	"Masz wiekszy rozrzut broni + 100hp obrazenia sa zredukowane o 10", //52
	"Za kazdego fraga dostajesz pelen magazynek", //53
	"Trafiasz kogos wykradasz mu hp i dajesz sobie", //54
	"Jezeli zadasz komus 40 obrazen wypadnie mu bron", //55
	"Przez 10 sekund mozesz przechodzic przez sciany", //56
	"Uzyj, aby przeniesc sie w miejsce wskazane celownikiem", //57
	"Natychmiastowe przeladowanie", //58
	"Zmniejszona grawitacja i mniejsza widocznosc na nozu", //59
	"Masz 1hp i jestes calkowicie niewidoczny", //60
	"Co runde mozesz polozyc elektromagnes. Pole dzialania zalezne od inteligencji", //61
	"Widzisz wrogow na radarze", //62
	"Uzyj, aby przez 3 sekundy odbijac obrazenia", //63
	"Dostajesz na start 50% wiecej HP + jak cie ktos zabije bez HS to traci zycie", //64
	"Mozesz zatrzymac czas na 3 sec, item na jedno uzycie" //65
};

new zatrzymaj_czas;

new nazwa_gracza[33][64];
new klasa_gracza[33];
new poziom_gracza[33] = 1;
new doswiadczenie_gracza[33];
new kupiono[33] = 1

new nowa_klasa_gracza[33];

new const doswiadczenie_poziomu[] = {
	0,
	32, 80, 197, 326, 489, 668, 914, 1167, 1524, 1922, //10
	2442, 2976, 3537, 4127, 4755, 5434, 6248, 7070, 7950, 8896, //20
	9847, 10833, 11836, 12908, 14038, 15200, 16378, 17609, 18863, 20252, //30
	21715, 23219, 24734, 26362, 28028, 29699, 31443, 33253, 35073, 36924, //40
	38870, 40865, 42862, 44958, 47086, 49266, 51446, 53696, 55975, 58309, //50
	60652, 63015, 65535, 68107, 70712, 73386, 76060, 78736, 81527, 84373, //60
	87238, 90153, 93159, 96188, 99260, 102363, 105521, 108761, 112036, 115377, //70
	118776, 122187, 125617, 129091, 132674, 136311, 140001, 143699, 147453, 151282, //80
	155123, 159013, 162906, 166930, 170956, 175057, 179167, 183390, 187648, 191927, //90
	196227, 200559, 204905, 209411, 213948, 218537, 223175, 227828, 232557, 237324, //100
	242139, 246983, 251885, 256800, 261837, 266885, 271936, 276987, 282127, 287326, //110
	292588, 297960, 303367, 308806, 314326, 319878, 325450, 331024, 336731, 342461, //120
	348263, 354083, 359906, 365733, 371672, 377675, 383759, 389894, 396067, 402269, //130
	408494, 414766, 421126, 427500, 433966, 440471, 447006, 453603, 460224, 466883, //140
	473549, 480360, 487212, 494124, 501039, 508012, 515059, 522162, 529306, 536478, //150
	543665, 550926, 558208, 565534, 572905, 580289, 587811, 595340, 602932, 610595, //160
	618277, 625970, 633668, 641471, 649285, 657183, 665110, 673098, 681091, 689112, //170
	697146, 705223, 713353, 721515, 729789, 738194, 746675, 755209, 763784, 772365, //180
	781026, 789752, 798481, 807285, 816141, 825068, 834036, 843027, 852032, 861129, //190
	870290, 879478, 888666, 897974, 907284, 916613, 926049, 935536, 945064, 954628, //200
	964219, 973821, 983478, 993250, 1003077, 1012953, 1022845, 1032760, 1042685, 1052695, //210
	1062705, 1072747, 1082862, 1093041, 1103334, 1113654, 1124054, 1134510, 1144985, 1155471, //220
	1166008, 1176649, 1187315, 1198020, 1208789, 1219567, 1230427, 1241296, 1252216, 1263160, //230
	1274124, 1285219, 1296321, 1307483, 1318656, 1329843, 1341190, 1352550, 1363970, 1375441, //240
	1386927, 1398529, 1410167, 1421839, 1433572, 1445316, 1457163, 1469063, 1480992, 1492932, //250
	1504959, 1517036, 1529161, 1541326, 1553529, 1565746, 1577984, 1590337, 1602743, 1615213, //260
	1627726, 1640289, 1652862, 1665518, 1678236, 1690957, 1703743, 1716584, 1729448, 1742408, //270
	1755376, 1768387, 1781446, 1794519, 1807684, 1820914, 1834199, 1847530, 1860903, 1874308, //280
	1887777, 1901269, 1914770, 1928380, 1942007, 1955700, 1969451, 1983223, 1996998, 2010913, //290
	2024852, 2038813, 2052866, 2066971, 2081085, 2095214, 2109346, 2123587, 2137930, 2152288, //300
	2166693
};

new punkty_gracza[33];
new zdrowie_gracza[33];
new inteligencja_gracza[33];
new bool: pomocs[33];
new wytrzymalosc_gracza[33];
new Float:redukcja_obrazen_gracza[33];
new kondycja_gracza[33];
new maksymalne_zdrowie_gracza[33];
new Float:szybkosc_gracza[33];

enum { NONE = 0, Snajper, Komandos, Strzelec, Obronca, Medyk, Wsparcie, Saper, Demolitions, Rusher, Rambo, Zolnierz, Zabojca, Partyzant, Szybki, Terrorysta, Kapitan, Plutonowy, Deagleman, Oficer, Zwiadowca, Kameleon, Szturmowiec, Major};
new const zdrowie_klasy[] = { 0, 120, 140, 110, 120, 110, 100, 100, 110, 100, 130, 120, 130, 120, 120, 70, 120, 150, 120, 80, 110, 100, 120, 120};
new const Float:szybkosc_klasy[] = {0.0, 1.1, 1.35, 1.1, 0.8, 1.2, 1.0, 1.0, 1.0, 1.3 , 1.2, 1.2, 1.1, 1.0, 1.4, 1.3, 1.1, 1.1, 1.2, 1.1, 1.1, 1.2, 1.15, 1.1};
new const pancerz_klasy[] = { 0, 100, 100, 100, 150, 100, 100, 100, 100, 50, 150, 75, 50, 150, 50, 100, 150, 200, 100, 100, 50, 100, 100, 150};
new const nazwy_klas[][] = {"Brak",
	"Snajper",
	"Komandos",
	"Strzelec Wyborowy",
	"Obronca",
	"Medyk",
	"Wsparcie Ogniowe",
	"Saper",
	"Demolitions",
	"Rusher",
	"Rambo (Klasa Premium)",
	"Zolnierz",
	"Zabojca",
	"Partyzant",
	"Szybki Zolnierz",
	"Terrorysta",
	"Kapitan (Klasa Premium)",
	"Plutonowy",
	"Deagleman",
	"Oficer",
	"Zwiadowca",
	"Kameleon",
	"Szturmowiec",
	"Major (Klasa Premium)"
};

new const opisy_klas[][] = {"Brak",
	"Dostaje AWP, scout i deagle, 120hp bazowe, 1/3 szansy natychmiastowego zabicia noza, 110% biegu, 100 pancerza.",
	"Dostaje Deagle, 140hp bazowe, Natychmiastowe zabicie z noza (prawy przycisk myszy), 135% biegu, 100 pancerza.",
	"Dostaje AK i M4A1, 110hp bazowe, 110 % biegu, 100 pancerza.",
	"Dostaje M249 (Krowa), 120hp bazowe, 80% biegu, jest odporny na miny, ma wszystkie granaty, 150 pancerza.",
	"Dostaje UMP45, 110hp bazowe, posiada apteczke, 100 pancerza.",
	"Dostaje MP5, 100 hp bazowe. Ma dwie rakiety, ktore po trafieniu przeciwnika zadaja duze obrazenia.",
	"Dostaje P90, 100hp bazowe, 100 pancerza, Dostaje 3 miny, gdy ktos w nie wejdzie wybuchaja.",
	"Dostaje AUG, 110 hp bazowe, ma wszystkie granaty. Dostaje dynamit, który zabiera sporo zycia.",
	"Dostaje Shotguna M3, 100 hp bazowe, 130% biegu",
	"Dostaje Famasa, 130 hp bazowe, 120% biegu, podwojny skok, za kazde zabójstwo +20 hp oraz pelen magazynek.",
	"Dostaje Galila, 120 HP bazowe, szybciej biega, dostaje 2 rakiety.",
	"Dostaje Deagle, 130 HP bazowe, wyglada jak wróg.",
	"Dostaje P90, 120 HP bazowe, lekko niewidzialny.",
	"Dostaje UMP45, 120HP bazowe 135% biegu, premia do grawitacji.",
	"Dostaje Dual Elites, 70 HP bazowe 130% biegu, dostaje 1 rakiete, moze wykonac podwojny skok w powietrzu.",
	"Dostaje SG552, 120 HP bazowe, jest odporny na 3 pociski w kazdej rundzie.",
	"Dostaje Shotgany, 150HP bazowe, 200 pancerza, 110% biegu.",
	"Dostaje Deagle, zadaje wieksze obrazenia z deagle, 120 HP bazowe, 120% biegu, odpornosc na miny.",
	"Dostaje TMP i MAC10, 80 HP bazowe, 150 pancerza, zadaje o 15 wieksze dmg.",
	"Dostaje Scout i P228, 110HP bazowe, 1/3 szansy na natychmiastowego zabicia scout'a, 110% biegu.",
	"Dostaje losowa bron co runde, 100 HP bazowe.",
	"Dostaje M4A1, UPS, 120 HP bazowe, 100 pancerza, 115% biegu, cicho biega.",
	"Dostaje AK47 120 HP bazowe i 150 pancerza, 120% biegu oraz zadaje wieksze obrazenia z deagle."
};

new ilosc_apteczek_gracza[33];
new ilosc_rakiet_gracza[33];
new Float:poprzednia_rakieta_gracza[33];
new ilosc_min_gracza[33];
new ilosc_dynamitow_gracza[33];
new ilosc_skokow_gracza[33];
new SOUND_START[]       = "items/medshot4.wav"
new SOUND_FINISHED[]    = "items/smallmedkit2.wav"
new SOUND_FAILED[]      = "items/medshotno1.wav"

enum
{
ICON_HIDE = 0,
ICON_SHOW,
ICON_FLASH
}

new bool:g_haskit[MAX_PLAYERS+1]
new Float:g_revive_delay[MAX_PLAYERS+1]
new Float:g_body_origin[MAX_PLAYERS+1][3]
new bool:g_wasducking[MAX_PLAYERS+1]

new g_msg_bartime
new g_msg_statusicon
new g_msg_clcorpse

new cvar_revival_time
new cvar_revival_health
new cvar_revival_dis
new bool:freezetime = true;
new hasZoom[33];
new bool:HasC4[33]

native cod_set_user_xp(id, wartosc)
native cod_get_user_xp(id)
	
/* --==[ VIP ] ==-- */
static const COLOR[] = "^x04" //green
static const CONTACT[] = ""
new maxplayers
new gmsgSayText
new mpd, mkb, mhb
new g_MsgSync
new health_add
new health_hs_add
new health_max
new nKiller
new nKiller_hp
new nHp_add
new nHp_max
new g_vip_active
new g_menu_active
//#define DAMAGE_RECIEVED
//#define Keysrod (1<<0)|(1<<1)|(1<<9) // Keys: 1234567890
new round;
/* --==[ VIP ] ==-- */

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_vault = nvault_open("CodMod");
	
	register_think("Apteczka","ApteczkaThink");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	RegisterHam(Ham_Touch, "armoury_entity", "DotykBroni");
	RegisterHam(Ham_Touch, "weapon_shield", "DotykBroni");
	RegisterHam(Ham_Touch, "weaponbox", "DotykBroni");
	
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_EmitSound, "EmitSound");
	register_forward(FM_EmitSound, "fwd_emitsound")
	register_forward(FM_PlayerPostThink, "fwd_playerpostthink")
	register_forward(FM_PlayerPreThink, "Player_PreThink")
	register_forward(FM_TraceLine,"fw_traceline");
	
	register_logevent("PoczatekRundy", 2, "1=Round_Start"); 
	register_logevent("BombaPodlozona", 3, "2=Planted_The_Bomb");
	register_event("SendAudio", "BombaRozbrojona", "a", "2&%!MRAD_BOMBDEF");
	register_event("BarTime", "RozbrajaBombe", "be", "1=10", "1=5");
	register_event("DeathMsg", "Death", "ade");
	register_event("Damage", "Damage", "b", "2!=0");
	register_event("CurWeapon","CurWeapon","be", "1=1");
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_hltv", "a", "1=0", "2=0")
	
	register_touch("Rocket", "*" , "DotykRakiety");
	register_touch("Mine", "player",  "DotykMiny");
	
	register_cvar("cod_killxp", "25");
	register_cvar("cod_bombxp", "100");
	register_cvar("cod_hsexp", "40");
	register_cvar("cod_winxp", "50");
	
	cvar_revival_time = register_cvar("amx_revkit_time", "4")
	cvar_revival_health = register_cvar("amx_revkit_health", "75")
	cvar_revival_dis = register_cvar("amx_revkit_distance", "100.0")
	register_message(get_user_msgid("Health"),"message_health");
	register_event("SendAudio", "WygranaTerro" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "WygranaCT", "a", "2&%!MRAD_ctwin");
	
	register_menucmd(register_menuid("rod"), Keysrod, "Pressedrod")
	register_clcmd("say /klasa", "WybierzKlase");
	register_clcmd("say /klasy", "OpisKlasy");
	register_clcmd("say /przedmiot", "OpisPrzedmiotu");
	register_clcmd("say /itemy", "OpisItemow");
	register_clcmd("say /przedmioty", "OpisItemow");
	register_clcmd("say /item", "OpisPrzedmiotu");
	register_clcmd("say /perk", "OpisPrzedmiotu");
	register_clcmd("say /drop", "WyrzucPrzedmiot");
	register_clcmd("say /wyrzuc", "WyrzucPrzedmiot");
	register_clcmd("say /reset", "KomendaResetujPunkty");
	register_clcmd("say /sklep", "Sklep");
	register_clcmd("say /shop", "Sklep");
	register_clcmd("say /oddaj", "OddajPrzedmiot");
	register_clcmd("say /daj", "OddajPrzedmiot");
	register_clcmd("fullupdate", "BlokujKomende");
	register_clcmd("cl_autobuy", "BlokujKomende");
	register_clcmd("say /molotov", "BlokujKomende");
	register_clcmd("say molotov", "BlokujKomende");
	register_clcmd("cl_rebuy", "BlokujKomende");
	register_clcmd("cl_setautobuy","BlokujKomende");
	register_clcmd("rebuy", "BlokujKomende");
	register_clcmd("autobuy", "BlokujKomende");
	register_clcmd("glock", "BlokujKomende");
	register_clcmd("usp", "BlokujKomende");
	register_clcmd("p228", "BlokujKomende");
	register_clcmd("deagle", "BlokujKomende");
	register_clcmd("elites", "BlokujKomende");
	register_clcmd("elite", "BlokujKomende");
	register_clcmd("fn57", "BlokujKomende");
	register_clcmd("m3", "BlokujKomende");
	register_clcmd("xm1014", "BlokujKomende");
	register_clcmd("mac10", "BlokujKomende");
	register_clcmd("tmp", "BlokujKomende");
	register_clcmd("mp5", "BlokujKomende");
	register_clcmd("ump45", "BlokujKomende");
	register_clcmd("p90", "BlokujKomende");
	register_clcmd("galil", "BlokujKomende");
	register_clcmd("ak47", "BlokujKomende");
	register_clcmd("scout", "BlokujKomende");
	register_clcmd("sg552", "BlokujKomende");
	register_clcmd("awp", "BlokujKomende");
	register_clcmd("g3sg1", "BlokujKomende");
	register_clcmd("famas", "BlokujKomende");
	register_clcmd("m4a1", "BlokujKomende");
	register_clcmd("bullpup", "BlokujKomende");
	register_clcmd("sg550", "BlokujKomende");
	register_clcmd("m249", "BlokujKomende");
	register_clcmd("shield", "BlokujKomende");
	register_clcmd("hegren", "BlokujKomende");
	register_clcmd("sgren", "BlokujKomende");
	register_clcmd("flash", "BlokujKomende");
	register_clcmd("vest", "BlokujKomende");
	register_clcmd("vesthelm", "BlokujKomende");
	
	register_concmd("cod_lvl", "cmd_setlvl", ADMIN_CVAR, "<name> <level>");
	register_concmd("cod_addlvl", "cmd_addlvl", ADMIN_CVAR, "<name> <lvl to add>");
	register_concmd("cod_remlvl", "cmd_remlvl", ADMIN_CVAR, "<name> <lvl to remove>");
	register_concmd("cod_dajitemek", "KomendaDajPrzedmiot", ADMIN_CVAR, "<nick> <item>");
	register_message(g_msg_clcorpse, "message_clcorpse")
	register_clcmd("say /vips", "print_adminlist")
	gmsgSayText = get_user_msgid("SayText")
	
	g_msg_screenfade = get_user_msgid("ScreenFade");
	g_msg_bartime = get_user_msgid("BarTime")
	g_msg_clcorpse = get_user_msgid("ClCorpse")
	g_msg_statusicon = get_user_msgid("StatusIcon")
	SyncHudObj = CreateHudSyncObj();
	SyncHudObj2 = CreateHudSyncObj();
	SyncHudObj3 = CreateHudSyncObj();
	doswiadczenia_za_zabojstwo = get_cvar_num("cod_killxp");
	doswiadczenie_za_bombe = get_cvar_num("cod_bombxp");
	doswiadczenie_za_wygrana = get_cvar_num("cod_winxp");
	doswiadczenie_za_hs = get_cvar_num("cod_hsexp");	
	doswiadczenie_za_kase = 100;
	doswiadczenie_za_kasez = 200;
	doswiadczenie_za_totek = 200;
	doswiadczenie_za_fail = 1;
	
	register_event("ResetHUD", "ResetHUD", "abe");
	
	register_think("magnet","MagnetThink");
	
	pcvar_ilosc_elektromagnesow = register_cvar("cod_magnets", "1");
	pcvar_zasieg = register_cvar("cod_magnetradius", "250");
	pcvar_czas_dzialania = register_cvar("cod_magnettime", "14");
	pcvar_widocznosc_fali = register_cvar("cod_wavesvisibility", "5");
	/* --==[ VIP ] ==-- */
	mpd = register_cvar("money_per_damage","0")
	mkb = register_cvar("money_kill_bonus","0")
	mhb = register_cvar("money_hs_bonus","0")
	health_add = register_cvar("amx_vip_hp", "0")
	health_hs_add = register_cvar("amx_vip_hp_hs", "0")
	health_max = register_cvar("amx_vip_max_hp", "1000")
	g_vip_active = register_cvar("vip_active", "0")
	g_menu_active = register_cvar("menu_active", "0")
	
	register_event("CurWeapon", "event_CurWeapon_Vip", "be", "1=1")
	
	register_event("Damage","Damage2","b")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
	
	/* #if defined DAMAGE_RECIEVED
	g_MsgSync2 = CreateHudSyncObj()
	#endif */
	register_menucmd(register_menuid("rod"), Keysrod, "Pressedrod")
	register_clcmd("say /vip","ShowMotd")
	
	maxplayers = get_maxplayers()
	g_MsgSync = CreateHudSyncObj()
	gmsgSayText = get_user_msgid("SayText")
	register_clcmd("say", "handle_say")
	register_cvar("sv_contact", CONTACT, FCVAR_SERVER)
	
	register_logevent("Round_Reset", 2, "1=Game_Commencing")
	register_event("TextMsg", "Round_Reset", "a", "2&Game_will_restart_in")
	register_event("DeathMsg", "hook_death", "a", "1>0")
	/* --==[ VIP ] ==-- */
	set_task(30.0, "Pomoc");
	
	g_msgHostageAdd = get_user_msgid("HostagePos");
	g_msgHostageDel = get_user_msgid("HostageK");
	
	set_task(1.5, "radar_scan", _, _, _, "b");
}

public Sklep(id)
{
	new menu = menu_create("Sklep COD:", "Sklep_Handle");
	menu_additem(menu, "Ketonal \r[Leczy 20 HP] \yKoszt: \r2000$");
	menu_additem(menu, "Flegamina \r[Leczy 50 HP] \yKoszt: \r4000$");
	menu_additem(menu, "Aspirina \r[Leczy 100 HP] \yKoszt: \r8000$");
	menu_additem(menu, "RedBull \r[Wysoki Skok + Szybkie Chodzenie] \yKoszt: \r2000$");
	menu_additem(menu, "Lotto \r[Losowa Nagroda] \yKoszt: \r2000$");
	menu_additem(menu, "Doswiadczenie \r[Dodaje 100 EXP] \yKoszt: \r6000$");
	menu_additem(menu, "Super Doswiadczenie \r[Dodaje 200 EXP] \yKoszt: \r10000$");
	menu_display(id, menu);
}

public Sklep_Handle(id, menu, item) 
{
	client_cmd(id, "spk QTM_CodMod/mementoselect");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	menu_display(id, menu);
	new kasa_gracza = cs_get_user_money(id);
	new hp = get_user_health(id);
	switch(item) 
	{ 
		case 0:
		{
			new koszt = 2000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Nie masz wystarczajacej ilosci pieniedzy.");
				return PLUGIN_CONTINUE;
			}
			if(hp >= maksymalne_zdrowie_gracza[id])
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Jestes w pelni uleczony.");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			new ammount=20;
			new nowe_zdrowie = (hp+ammount<maksymalne_zdrowie_gracza[id])? hp+ammount: maksymalne_zdrowie_gracza[id];
			set_user_health(id, nowe_zdrowie);
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles^x03 Ketonal");
		}
		case 1:
		{
			new koszt = 4000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Nie masz wystarczajacej ilosci pieniedzy.");
				return PLUGIN_CONTINUE;
			}
			if(hp >= maksymalne_zdrowie_gracza[id])
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Jestes w pelni uleczony.");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			new ammount=50;
			new nowe_zdrowie = (hp+ammount<maksymalne_zdrowie_gracza[id])? hp+ammount: maksymalne_zdrowie_gracza[id];
			set_user_health(id, nowe_zdrowie);
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles^x03 Flegamine");
		}
		case 2:
		{
			new koszt = 8000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Nie masz wystarczajacej ilosci pieniedzy.");
				return PLUGIN_CONTINUE;
			}
			if(hp >= maksymalne_zdrowie_gracza[id])
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Jestes w pelni uleczony.");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			new ammount=100;
			new nowe_zdrowie = (hp+ammount<maksymalne_zdrowie_gracza[id])? hp+ammount: maksymalne_zdrowie_gracza[id];
			set_user_health(id, nowe_zdrowie);
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles^x03 Aspirine");
		}
		case 3:
		{
			new koszt = 2000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Nie masz wystarczajacej ilosci pieniedzy."); 
				return PLUGIN_CONTINUE;
			}
			if (get_user_gravity(id) <= 0.4)
			{
        ColorChat(id,GREEN,"[SKLEP]^x01 W tej rundzie juz sie nie napijesz^x03 RedBulla");
				}
			else
			{
				cs_set_user_money(id, kasa_gracza-koszt);
				set_user_gravity(id,get_user_gravity(id) - 0.3);
				set_user_maxspeed(id,get_user_maxspeed(id) + 10.0);
				ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles i Wypiles^x03 RedBulla");
			}
		}
		case 4:
		{
			new kasa = cs_get_user_money(id)
			new koszt = 2000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Nie masz wystarczajacej ilosci pieniedzy.");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles kupon Totolotka");
			ColorChat(id,GREEN,"[SKLEP]^x01 Trwa losowanie...");
			new rand = random_num(0,15);
			switch(rand) 
			{
				case 0:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 1$^x01 !")
					cs_set_user_money(id, kasa + 1)
				}
				case 1:
				{
				  if (get_user_gravity(id) <= 0.4)
					{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 2000$^x01 !")
					cs_set_user_money(id, kasa + 2000)
					}
					else
					{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 Redbulla^x01 !")
					set_user_gravity(id,get_user_gravity(id) - 0.3);
					set_user_maxspeed(id,get_user_maxspeed(id) + 10.0);
					}
				}
				case 2:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Niestety nic nie wygrales !")
				}
				case 3:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 4000$^x01 !")
					cs_set_user_money(id, kasa + 4000)
				}
				case 4:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 2000$^x01 !")
					cs_set_user_money(id, kasa + 2000)
				}
				case 5:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Niestety nic nie wygrales !")
				}
				case 6:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Niestety nic nie wygrales !")
				}
				case 7:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Przegrales^x03 Wszystko^x01 !")
					cs_set_user_money(id, kasa - kasa_gracza)
				}
				case 8:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Niestety nic nie wygrales !")
				}
				case 9:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 200 EXP^x01 !")
					doswiadczenie_gracza[id] += doswiadczenie_za_totek;
					
				}
				case 10:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 200 EXP^x01 !")
					doswiadczenie_gracza[id] += doswiadczenie_za_totek;
				}
				case 11:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Niestety nic nie wygrales !")
				}
				case 12:
				{
					ColorChat(id,GREEN,"[SKLEP]^x01 Wygrales^x03 1 EXP^x01 !")
					doswiadczenie_gracza[id] += doswiadczenie_za_fail;
				}
			}
			SprawdzPoziom(id);
			return PLUGIN_CONTINUE;
		}
		case 5:
		{
			new koszt = 6000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Masz za malo kasy");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			doswiadczenie_gracza[id] += doswiadczenie_za_kase;
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles^x03 Doswiadczenie");
			SprawdzPoziom(id);
		}
		case 6:
		{
			new koszt = 10000;
			if (kasa_gracza<koszt)
			{
				ColorChat(id,GREEN,"[SKLEP]^x01 Masz za malo kasy");
				return PLUGIN_CONTINUE;
			}
			cs_set_user_money(id, kasa_gracza-koszt);
			doswiadczenie_gracza[id] += doswiadczenie_za_kasez;
			ColorChat(id,GREEN,"[SKLEP]^x01 Kupiles^x03 Super Doswiadczenie");
			SprawdzPoziom(id);
		}
	}
	return PLUGIN_CONTINUE;
} 

public plugin_cfg() 
{	
	server_cmd("sv_maxspeed 320");
}

public plugin_precache()
{
	sprite_white = precache_model("sprites/white.spr") ;
	sprite_blast = precache_model("sprites/dexplo.spr");
	
	precache_sound("QTM_CodMod/select.wav");
	precache_sound("QTM_CodMod/start.wav");
	precache_sound("QTM_CodMod/start2.wav");
	precache_sound("QTM_CodMod/levelup.wav");
	
	precache_model("models/w_medkit.mdl");
	precache_model("models/rpgrocket.mdl");
	precache_model("models/mine.mdl");
	precache_model("models/player/arctic/arctic.mdl")
	precache_model("models/player/terror/terror.mdl")
	precache_model("models/player/leet/leet.mdl")
	precache_model("models/player/guerilla/guerilla.mdl")
	precache_model("models/player/gign/gign.mdl")
	precache_model("models/player/sas/sas.mdl")
	precache_model("models/player/gsg9/gsg9.mdl")
	precache_model("models/player/urban/urban.mdl")
	precache_model("models/player/vip/vip.mdl")
	
	precache_model("models/QTM_CodMod/electromagnet.mdl");
	
	precache_sound("weapons/mine_charge.wav");
	precache_sound("weapons/mine_activate.wav");
	precache_sound("weapons/mine_deploy.wav");
	
	precache_sound(SOUND_START)
	precache_sound(SOUND_FINISHED)
	precache_sound(SOUND_FAILED)
	
}
public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	new Float: velocity[3];
        entity_get_vector(id, EV_VEC_velocity, velocity);
        new Float: speed = vector_length(velocity);
        if(szybkosc_gracza[id] > speed*1.8)
                entity_set_int(id, EV_INT_flTimeStepSound, 300);
								
	if(zatrzymaj_czas && zatrzymaj_czas != id)
	{
		entity_set_vector(id, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
		entity_set_vector(id, EV_VEC_v_angle, Float:{0.0, 0.0, 0.0});
		entity_set_vector(id, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
		entity_set_int(id, EV_INT_fixangle, 1);
		set_pdata_float(id, 83, 0.1, 5);
		set_uc(uc_handle, UC_Buttons, 0);
		new name[55];
		get_user_name(zatrzymaj_czas, name, 54);
		client_print(id, print_center, "%s zatrzymal czas swym itemem na 3sec.", name);
	}
	
	new button = get_uc(uc_handle, UC_Buttons);
	new oldbutton = get_user_oldbutton(id);
	new flags = get_entity_flags(id);
	
	if(informacje_przedmiotu_gracza[id][0] == 11 || klasa_gracza[id] == Rambo || klasa_gracza[id] == Terrorysta)
	{
		if((button & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldbutton & IN_JUMP) && ilosc_skokow_gracza[id] > 0)
		{
			ilosc_skokow_gracza[id]--;
			new Float:velocity[3];
			entity_get_vector(id,EV_VEC_velocity,velocity);
			velocity[2] = random_float(265.0,285.0);
			entity_set_vector(id,EV_VEC_velocity,velocity);
		}
		else if(flags & FL_ONGROUND)
		{	
			ilosc_skokow_gracza[id] = 0;
			if(informacje_przedmiotu_gracza[id][0] == 11)
				ilosc_skokow_gracza[id]++;
			if(klasa_gracza[id] == Rambo)
				ilosc_skokow_gracza[id]++;
			if(klasa_gracza[id] == Terrorysta)
				ilosc_skokow_gracza[id]++;
		}
	}
	if(informacje_przedmiotu_gracza[id][0] == 41)
	{
		if(button & IN_DUCK)
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 8);
		else
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 255);
	}
	
	if(button & IN_ATTACK2 && !(pev(id, pev_oldbuttons) & IN_ATTACK2) && informacje_przedmiotu_gracza[id][0] == 48)
	{
		new szClip, szAmmo
		new WeapID = get_user_weapon( id, szClip, szAmmo )
		
		if(WeapID != CSW_KNIFE && WeapID != CSW_C4 && WeapID != CSW_AWP && WeapID != CSW_SCOUT && WeapID != CSW_SG550 && WeapID != CSW_G3SG1 && !hasZoom[id])
		{
			hasZoom[id] = true;
			cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1);
			emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100);
		}
		else if (hasZoom[id])
		{
			hasZoom[id] = false;
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
		}
	}
	
	if(button & IN_ATTACK)
	{
		new Float:punchangle[3];
		
		if(informacje_przedmiotu_gracza[id][0] == 20)
			entity_set_vector(id, EV_VEC_punchangle, punchangle);
		if(informacje_przedmiotu_gracza[id][0] == 23)
		{
			entity_get_vector(id, EV_VEC_punchangle, punchangle);
			for(new i=0; i<3;i++) 
				punchangle[i]*=0.9;
			entity_set_vector(id, EV_VEC_punchangle, punchangle);
		}
		
		if(informacje_przedmiotu_gracza[id][0] == 52)
		{
			entity_get_vector(id, EV_VEC_punchangle, punchangle);
			for(new i=0; i<3;i++) 
				punchangle[i]*=1.1;
			entity_set_vector(id, EV_VEC_punchangle, punchangle);
		}
	}
	
	if(informacje_przedmiotu_gracza[id][0] == 28 && button & IN_JUMP && button & IN_DUCK && flags & FL_ONGROUND && get_gametime() > informacje_przedmiotu_gracza[id][1]+4.0)
	{
		informacje_przedmiotu_gracza[id][1] = floatround(get_gametime());
		new Float:velocity[3];
		VelocityByAim(id, 700, velocity);
		velocity[2] = random_float(265.0,285.0);
		entity_set_vector(id, EV_VEC_velocity, velocity);
	}
	
	new clip, ammo, weapon = get_user_weapon(id, clip, ammo);
	
	if(maxClip[weapon] == -1 || !ammo)
		return FMRES_IGNORED;
	
	if(informacje_przedmiotu_gracza[id][0] == 58 && ((button & IN_RELOAD && !(oldbutton & IN_RELOAD) && !(button & IN_ATTACK)) || !clip))
	{
		cs_set_user_bpammo(id, weapon, ammo-(maxClip[weapon]-clip));
		new new_ammo = min(clip+ammo, maxClip[weapon]);
		set_user_clip(id, new_ammo);
	}
	
	return FMRES_IGNORED;
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(nowa_klasa_gracza[id])
	{
		klasa_gracza[id] = nowa_klasa_gracza[id];
		nowa_klasa_gracza[id] = 0;
		cod_add_wskrzes(id, 0)
		fm_strip_user_weapons(id);
		fm_give_item(id, "weapon_knife");
		set_user_gravity(id, 1.0);
		switch(get_user_team(id))
		{
			case 1: fm_give_item(id, "weapon_glock18");
				case 2: fm_give_item(id, "weapon_usp");
			}
		WczytajDane(id, klasa_gracza[id]);
	}
	
	if(!klasa_gracza[id])
	{
		WybierzKlase(id);
		return PLUGIN_CONTINUE;
	}
	switch(klasa_gracza[id])
	{
		case Snajper:
		{
			fm_give_item(id, "weapon_awp");
			fm_give_item(id, "weapon_deagle");
			fm_give_item(id, "weapon_scout");
		}
		case Komandos:
			fm_give_item(id, "weapon_deagle");
		
		case Strzelec:
		{
			fm_give_item(id, "weapon_m4a1");
			fm_give_item(id, "weapon_ak47");
			
		}
		case Obronca:
		{
			fm_give_item(id, "weapon_m249");
			fm_give_item(id, "weapon_hegrenade");
			fm_give_item(id, "weapon_flashbang");
			fm_give_item(id, "weapon_flashbang");
			fm_give_item(id, "weapon_smokegrenade");
		}
		
		case Medyk:
		{
			fm_give_item(id, "weapon_ump45");	
			ilosc_apteczek_gracza[id] = 2;
		}	
		case Wsparcie:
		{
			fm_give_item(id, "weapon_mp5navy");
			ilosc_rakiet_gracza[id] = 2;
		}
		case Saper:
		{
			fm_give_item(id, "weapon_p90");
			ilosc_min_gracza[id] += 3;
			fm_give_item(id, "item_thighpack");
		}
		case Demolitions:
		{
			fm_give_item(id, "weapon_aug");
			fm_give_item(id, "weapon_hegrenade");
			fm_give_item(id, "weapon_flashbang");
			fm_give_item(id, "weapon_flashbang");
			fm_give_item(id, "weapon_smokegrenade");			
		}
		case Rusher:
			fm_give_item(id, "weapon_m3");
		
		case Rambo:
		{
			fm_give_item(id, "weapon_famas");
			fm_give_item(id, "item_thighpack");
		}
		case Zolnierz:
		{
			fm_give_item(id, "weapon_galil");
			ilosc_rakiet_gracza[id] = 2;
		}
		case Zabojca:
		{
			fm_give_item(id, "weapon_deagle");
			ZmienUbranie(id, 0);
		}
		case Partyzant:
		{
			fm_give_item(id, "weapon_p90");
			fm_give_item(id, "weapon_flashbang");
			fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 70);
		}
		case Szybki:
		{
			fm_give_item(id, "weapon_ump45");
		}
		
		case Terrorysta:
		{
			fm_give_item(id, "weapon_elite");
			ilosc_rakiet_gracza[id] = 1;
		}
		case Kapitan:
		{
			fm_give_item(id, "weapon_sg552");
			fm_give_item(id, "item_thighpack");
		}
		case Plutonowy:
		{
			fm_give_item(id, "weapon_m3");
			fm_give_item(id, "weapon_xm1014");
		}
		case Deagleman:
		{ 
			fm_give_item(id, "weapon_deagle");
		}
		case Oficer:
		{
			fm_give_item(id, "weapon_tmp");
			fm_give_item(id, "weapon_mac10");
		}
		case Zwiadowca:
		{
			fm_give_item(id, "weapon_scout");
			fm_give_item(id, "weapon_p228");
		}
		
		case Kameleon:
		{
			if (user_has_weapon(id, CSW_C4) && get_user_team(id) == 1)
				HasC4[id] = true;
			else
				HasC4[id] = false;
			strip_user_weapons(id);
			new randomweapon = random_num(0,12);
			switch(randomweapon) 
			{
				case 0:         fm_give_item(id, "weapon_awp");
					case 1:         fm_give_item(id, "weapon_m4a1");
					case 2:         fm_give_item(id, "weapon_galil");
					case 3:         fm_give_item(id, "weapon_m3");
					case 4:         fm_give_item(id, "weapon_p90");
					case 5:         fm_give_item(id, "weapon_famas");
					case 6:         fm_give_item(id, "weapon_ak47");
					case 7:         fm_give_item(id, "weapon_aug");
					case 8:         fm_give_item(id, "weapon_mp5navy");
					case 9:         fm_give_item(id, "weapon_m249");
					case 10:         fm_give_item(id, "weapon_ump45");
					case 11:         fm_give_item(id, "weapon_tmp");
					case 12:         fm_give_item(id, "weapon_sg552");
				}
			fm_give_item(id, "weapon_knife");
			if (HasC4[id])
			{
				fm_give_item(id, "weapon_c4");
				cs_set_user_plant( id );
			}
			switch(get_user_team(id))
			{
				case 1: fm_give_item(id, "weapon_glock18");
					case 2: fm_give_item(id, "weapon_usp");
				}
		}
		case Szturmowiec:
		{
			fm_give_item(id, "weapon_m4a1");
			fm_give_item(id, "weapon_usp");
		}
		case Major:
		{
			fm_give_item(id, "weapon_ak47");
			fm_give_item(id, "weapon_deagle");
			fm_give_item(id, "item_thighpack");
		}
	}
	
	if(!informacje_przedmiotu_gracza[id][0])
	{
	  if(klasa_gracza[id] != Partyzant)
			fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 255);
		else
			fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 70);
	}
	
	if(punkty_gracza[id]>0)
		set_task(0.1, "PrzydzielPunkty", id);
	
	if(klasa_gracza[id] == Szybki)
		set_user_gravity(id, 0.4);
	
	if(informacje_przedmiotu_gracza[id][0] == 59)
		fm_set_user_gravity(id, 0.5);
	
	if(informacje_przedmiotu_gracza[id][0] == 10 || informacje_przedmiotu_gracza[id][0] == 9 || informacje_przedmiotu_gracza[id][0] == 31)
		fm_give_item(id, "weapon_hegrenade");
	
	if(informacje_przedmiotu_gracza[id][0] == 9 || informacje_przedmiotu_gracza[id][0] == 31 || informacje_przedmiotu_gracza[id][0] == 46)
		ZmienUbranie(id, 0);
	
	if(informacje_przedmiotu_gracza[id][0] == 1 || informacje_przedmiotu_gracza[id][0] == 36 || informacje_przedmiotu_gracza[id][0] == 43 || informacje_przedmiotu_gracza[id][0] == 47 || informacje_przedmiotu_gracza[id][0] == 60 || klasa_gracza[id] == Szturmowiec)
		set_user_footsteps(id, 1);
	else
		set_user_footsteps(id, 0);
	
	if(informacje_przedmiotu_gracza[id][0] == 13)
		fm_give_item(id, "weapon_awp");
	
	if(informacje_przedmiotu_gracza[id][0] == 32)
		fm_give_item(id, "weapon_deagle");
	
	if(informacje_przedmiotu_gracza[id][0] == 33)
		fm_give_item(id, "weapon_m3");
	
	if(informacje_przedmiotu_gracza[id][0] == 46)
		fm_give_item(id, "weapon_scout");
	
	if(informacje_przedmiotu_gracza[id][0] == 19)
		informacje_przedmiotu_gracza[id][1] = 1;
	
	if(informacje_przedmiotu_gracza[id][0] == 56 || informacje_przedmiotu_gracza[id][0] == 57 || informacje_przedmiotu_gracza[id][0] == 39 || informacje_przedmiotu_gracza[id][0] == 63)
		informacje_przedmiotu_gracza[id][1] = 1;
	
	if(informacje_przedmiotu_gracza[id][0] == 27 || klasa_gracza[id] == Kapitan)
		informacje_przedmiotu_gracza[id][1] = 3;
	
	if(informacje_przedmiotu_gracza[id][0] == 60) 
	{
		fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 1);
	}
	
	
	new weapons[32];
	new weaponsnum;
	get_user_weapons(id, weapons, weaponsnum);
	for(new i=0; i<weaponsnum; i++)
		if(is_user_alive(id))
		if(maxAmmo[weapons[i]] > 0)
		cs_set_user_bpammo(id, weapons[i], maxAmmo[weapons[i]]);
	
	redukcja_obrazen_gracza[id] = (47.3057*(1.0-floatpower( 2.7182, -0.06798*float(wytrzymalosc_gracza[id])))/100);
	maksymalne_zdrowie_gracza[id] = zdrowie_klasy[klasa_gracza[id]]+zdrowie_gracza[id]*2;
	szybkosc_gracza[id] = STANDARDOWA_SZYBKOSC*szybkosc_klasy[klasa_gracza[id]]+floatround(kondycja_gracza[id]*1.3);
	
	if(informacje_przedmiotu_gracza[id][0] == 52 || informacje_przedmiotu_gracza[id][0] == 43 || informacje_przedmiotu_gracza[id][0] == 36 || informacje_przedmiotu_gracza[id][0] == 18 || informacje_przedmiotu_gracza[id][0] == 30)
		maksymalne_zdrowie_gracza[id] += 100;
	
	if(informacje_przedmiotu_gracza[id][0] == 18)
		szybkosc_gracza[id] -= 0.4;
	
	if(informacje_przedmiotu_gracza[id][0] == 29)
	{
		maksymalne_zdrowie_gracza[id] += 50;
		szybkosc_gracza[id] += 0.2;
	}
	
	if(informacje_przedmiotu_gracza[id][0] == 34)
		fm_set_user_gravity(id, 0.5);
	
	if(informacje_przedmiotu_gracza[id][0] == 30)
		szybkosc_gracza[id] -= 20;
	
	if(informacje_przedmiotu_gracza[id][0] == 25)
	{
		maksymalne_zdrowie_gracza[id] += 50;
		szybkosc_gracza[id] -= 0.3;
	}
	if(informacje_przedmiotu_gracza[id][0] == 60)
		maksymalne_zdrowie_gracza[id] = 1;
	
	if(informacje_przedmiotu_gracza[id][0] == 37)
		szybkosc_gracza[id] += 20;
	
	if(informacje_przedmiotu_gracza[id][0] == 38)
		maksymalne_zdrowie_gracza[id] += 70;
	
	if(informacje_przedmiotu_gracza[id][0] == 42)
		informacje_przedmiotu_gracza[id][1] = 1;
	
	if(informacje_przedmiotu_gracza[id][0] == 45)
		informacje_przedmiotu_gracza[id][1] = 1;
	
	if(informacje_przedmiotu_gracza[id][0] == 64)
		maksymalne_zdrowie_gracza[id] *= 2;

	if(informacje_przedmiotu_gracza[id][0] == 17 || informacje_przedmiotu_gracza[id][0] == 40)
		fm_set_user_armor(id, 500);
	
	fm_set_user_armor(id, pancerz_klasy[klasa_gracza[id]]);
	fm_set_user_health(id, maksymalne_zdrowie_gracza[id]);
	
	return PLUGIN_CONTINUE;
}

public PoczatekRundy()	
{	
	freezetime = false;
	for(new id=0;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue;
		
		set_task(0.1, "UstawSzybkosc", id+ZADANIE_USTAW_SZYBKOSC);
		kupiono[id] = false;
		
		switch(get_user_team(id))
		{
			case 1: client_cmd(id, "spk QTM_CodMod/start");
				case 2: client_cmd(id, "spk QTM_CodMod/start2");
			}
	}
	
	round++;
	new players[32], player, pnum;
	get_players(players, pnum, "a");
	for(new i = 0; i < pnum; i++)
	{
		player = players[i];
		if(is_user_connected(player) && get_user_flags(player) & ADMIN_LEVEL_H)
		{
			if(!get_pcvar_num(g_menu_active))
				return PLUGIN_CONTINUE
			if(!is_user_hltv(player) && !is_user_bot(player))
			{
				fm_give_item(player, "weapon_hegrenade");
				fm_give_item(player, "weapon_flashbang");
				fm_give_item(player, "weapon_flashbang");
				fm_give_item(player, "weapon_smokegrenade");
				fm_give_item(player, "item_assaultsuit");
				fm_give_item(player, "item_thighpack");
			}
			if(round > 3) Showrod(player)
		}
	}
	return PLUGIN_HANDLED;
}

public NowaRunda()
{
	NowaRunda_magnet();
	freezetime = true;
	new iEnt = find_ent_by_class(-1, "Mine");
	while(iEnt > 0) 
	{
		remove_entity(iEnt);
		iEnt = find_ent_by_class(iEnt, "Mine");	
	}
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_alive(this) || !is_user_connected(this) || informacje_przedmiotu_gracza[this][0] == 24 || !is_user_connected(idattacker) || get_user_team(this) == get_user_team(idattacker) || !klasa_gracza[idattacker])
		return HAM_IGNORED;
	
	new health = get_user_health(this);
	new weapon = get_user_weapon(idattacker);
	
	if(health < 2)
		return HAM_IGNORED;
	
	if(informacje_przedmiotu_gracza[this][0] == 27 && informacje_przedmiotu_gracza[this][1]>0)
	{
		informacje_przedmiotu_gracza[this][1]--;
		return HAM_SUPERCEDE;
	}
	if(informacje_przedmiotu_gracza[idattacker][0] == 30)
		damage += 20.0;
	
	if(informacje_przedmiotu_gracza[this][0] == 52)
		damage -= floatmin(damage, 10.0);
	
	if(wytrzymalosc_gracza[this]>0)
		damage -= redukcja_obrazen_gracza[this]*damage;
	
	if(informacje_przedmiotu_gracza[this][0] == 2 || informacje_przedmiotu_gracza[this][0] == 3)
		damage-=(float(informacje_przedmiotu_gracza[this][1])<damage)? float(informacje_przedmiotu_gracza[this][1]): damage;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 5 && !UTIL_In_FOV(this, idattacker) && UTIL_In_FOV(idattacker, this))
		damage*=2.0;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 10)
		damage+=informacje_przedmiotu_gracza[idattacker][1];
	
	if(informacje_przedmiotu_gracza[this][0] == 12)
		damage-=(5.0<damage)? 5.0: damage;
	
	if(informacje_przedmiotu_gracza[this][0] == 29)
		damage-=(10.0<damage)? 10.0: damage;
	
	if(informacje_przedmiotu_gracza[this][0] == 37)
		damage-=(10.0<damage)? 10.0: damage;
	
	if(informacje_przedmiotu_gracza[this][0] == 44)
		damage-=(7.0<damage)? 7.0: damage;
	
	if(weapon == CSW_AWP && informacje_przedmiotu_gracza[idattacker][0] == 13)
		damage=float(health);
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 21)
		damage+=10;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 22)
		damage+=20;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 31)
		damage+=10;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 36)
		damage+=8;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 37)
		damage+=10;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 43)
		damage+=10;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 44)
		damage+=5;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 47)
		damage+=20;
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 55 && damage >= 40.0)
		client_cmd(this, "drop");
	
	if(informacje_przedmiotu_gracza[idattacker][0] == 54)
		fm_set_user_health(idattacker, min(maksymalne_zdrowie_gracza[idattacker], get_user_health(idattacker)+floatround(damage)))
	
	if(idinflictor != idattacker && entity_get_int(idinflictor, EV_INT_movetype) != 5)
	{
		if(informacje_przedmiotu_gracza[idattacker][0] == 10 || (informacje_przedmiotu_gracza[idattacker][0] == 9 && random_num(1, informacje_przedmiotu_gracza[idattacker][1]) == 1))
			damage = float(health);	
	}
	
	if(weapon == CSW_SCOUT)
	{
		if((informacje_przedmiotu_gracza[idattacker][0] == 46 && random_num(1, informacje_przedmiotu_gracza[idattacker][1]) == 1))
			damage = float(health);	
	}
	
	if(weapon == CSW_HEGRENADE)
	{
		if((klasa_gracza[idattacker] == Kapitan && random(2) == 1))
			damage = float(health);
	}
	
	if(weapon == CSW_KNIFE)
	{
		if(informacje_przedmiotu_gracza[this][0] == 4)
			damage=damage*1.4+inteligencja_gracza[idattacker];
		if(informacje_przedmiotu_gracza[idattacker][0] == 8 || (klasa_gracza[idattacker] == Snajper && random(2) == 2) || klasa_gracza[idattacker] == Komandos && !(get_user_button(idattacker) & IN_ATTACK))
			damage = float(health);
	}
	if(weapon == CSW_SCOUT)
	{
		if((klasa_gracza[idattacker] == Zwiadowca && random(3) == 1))
			damage = float(health);
	} 
	
	if(weapon == CSW_DEAGLE && klasa_gracza[idattacker] == Major)
	{       
		damage+=25.0;
	}
	
	if(weapon == CSW_DEAGLE && klasa_gracza[idattacker] == Deagleman)
	{       
		damage+=10.0;
	}
	if(klasa_gracza[idattacker] == Oficer)
	{
		damage+=15.0;
	}
	if(weapon == CSW_DEAGLE)
	{
		if(informacje_przedmiotu_gracza[idattacker][0] == 32 && random_num(1, informacje_przedmiotu_gracza[idattacker][1]) == 1)
			damage = float(health);
	}
	
	
	if(weapon == CSW_M3)
	{
		if((informacje_przedmiotu_gracza[idattacker][0] == 33 && random_num(2, informacje_przedmiotu_gracza[idattacker][1]) == 2) || (informacje_przedmiotu_gracza[idattacker][0] == 80 && !random(5)))
			damage = float(health);
	}
	if(weapon == CSW_HEGRENADE)
	{
		if(informacje_przedmiotu_gracza[idattacker][0] == 31 && random_num(1, informacje_przedmiotu_gracza[idattacker][1]) == 1)
			damage = float(health);
	}
	
	if(informacje_przedmiotu_gracza[this][0] == 26 && random_num(1, informacje_przedmiotu_gracza[this][1]) == 1)
	{
		SetHamParamEntity(3, this);
		SetHamParamEntity(1, idattacker);
	}
	if(informacje_przedmiotu_gracza[this][0] == 40 && random_num(1, informacje_przedmiotu_gracza[this][1]) == 1)
	{
		SetHamParamEntity(3, this);
		SetHamParamEntity(1, idattacker);
	}
	if(task_exists(this+ZADANIE_ODBIJAJ))
	{
		SetHamParamEntity(3, this);
		SetHamParamEntity(1, idattacker);
	}
	
	SetHamParamFloat(4, damage);
	return HAM_IGNORED;
}

public Damage(id)
{
	new attacker = get_user_attacker(id);
	new damage = read_data(2);
	if(!is_user_alive(attacker) || !is_user_connected(attacker) || id == attacker || !klasa_gracza[attacker])
		return PLUGIN_CONTINUE;
	
	if(informacje_przedmiotu_gracza[attacker][0] == 12 && random_num(1, informacje_przedmiotu_gracza[id][1]) == 1)
		Display_Fade(id,1<<14,1<<14 ,1<<16,255,155,50,230);
	
	if(get_user_team(id) != get_user_team(attacker))
	{
		while(damage>20)
		{
			damage-=20;
			doswiadczenie_gracza[attacker]++;
		}
	}
	SprawdzPoziom(attacker);
	
	if(informacje_przedmiotu_gracza[id][0] == 7 && random_num(1, informacje_przedmiotu_gracza[id][1]) == 1)
		set_task(0.1, "Wskrzes", id+ZADANIE_WSKRZES);
	
	return PLUGIN_CONTINUE;
}

public Death()
{	
	new weaponname[20]
	new headshot = read_data(3)
	read_data(4,weaponname,31)
	new id = read_data(2);
	new attacker = read_data(1);
	
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return PLUGIN_CONTINUE;
	
	new weapon = get_user_weapon(attacker);
	new zdrowie = get_user_health(attacker);
	
	if(get_user_team(id) != get_user_team(attacker) && klasa_gracza[attacker])
	{
		new nowe_doswiadczenie = 0;
		
		nowe_doswiadczenie += doswiadczenia_za_zabojstwo;
		
		if(klasa_gracza[id] == Rambo && klasa_gracza[attacker] != Rambo)
			nowe_doswiadczenie += doswiadczenia_za_zabojstwo*2;
		
		if(klasa_gracza[id] == Rambo && klasa_gracza[attacker] != Kapitan)
			nowe_doswiadczenie += doswiadczenia_za_zabojstwo*2;
		
		if(klasa_gracza[id] == Rambo && klasa_gracza[attacker] != Major)
			nowe_doswiadczenie += doswiadczenia_za_zabojstwo*2;
		
		if(poziom_gracza[id] > poziom_gracza[attacker])
			nowe_doswiadczenie += poziom_gracza[id] - poziom_gracza[attacker];
		
		if(informacje_przedmiotu_gracza[id][0] == 88 && !read_data(3))
			fm_set_user_health(attacker, 1);
		
		if (get_user_flags(attacker) & ADMIN_LEVEL_H)
		{		
			if(headshot)
			{
				new nowe_zdrowie = (zdrowie+30);
				fm_set_user_health(attacker, nowe_zdrowie);
				cs_set_user_money(attacker, cs_get_user_money(attacker)+800);
			}
			else
			{
				new nowe_zdrowie = (zdrowie+15);
				fm_set_user_health(attacker, nowe_zdrowie);
				cs_set_user_money(attacker, cs_get_user_money(attacker)+500);
			}
		}
		if(klasa_gracza[attacker] == Rambo || informacje_przedmiotu_gracza[attacker][0] == 15 && maxClip[weapon] != -1)
		{
			
			new nowe_zdrowie = (zdrowie+20);
			set_user_clip(attacker, maxClip[weapon]);
			fm_set_user_health(attacker, nowe_zdrowie);
		}
		if((!(klasa_gracza[attacker] == Rambo)) && (informacje_przedmiotu_gracza[attacker][0] == 71 || informacje_przedmiotu_gracza[attacker][0] == 81))
		{
			
			new nowe_zdrowie = (zdrowie+25);
			fm_set_user_health(attacker, nowe_zdrowie);
		}
		
		if((!(klasa_gracza[attacker] == Rambo)) && (informacje_przedmiotu_gracza[attacker][0] == 53 && maxClip[weapon] != -1))
			set_user_clip(attacker, maxClip[weapon]);
		
		#if defined BOTY
		if(is_user_bot2(attacker) && random(9) == 0)
			WyrzucPrzedmiot(id);
		#endif
		if(!informacje_przedmiotu_gracza[attacker][0])
			DajPrzedmiot(attacker, random_num(1, sizeof nazwy_przedmiotow-1));
		
		if(informacje_przedmiotu_gracza[attacker][0] == 14)
		{
			new nowe_zdrowie = (zdrowie+50<maksymalne_zdrowie_gracza[attacker])? zdrowie+50: maksymalne_zdrowie_gracza[attacker];
			fm_set_user_health(attacker, nowe_zdrowie);
		}
		
		set_hudmessage(255, 212, 0, 0.50, 0.33, 1, 6.0, 4.0);
		ShowSyncHudMsg(attacker, SyncHudObj2, "+%i", nowe_doswiadczenie);
		
		doswiadczenie_gracza[attacker] += nowe_doswiadczenie;
	}
	
	SprawdzPoziom(attacker);
	
	if(informacje_przedmiotu_gracza[id][0] == 7 && random_num(1, informacje_przedmiotu_gracza[id][1]) == 1)
		set_task(0.1, "Wskrzes", id+ZADANIE_WSKRZES);
	
	return PLUGIN_CONTINUE;
}

public client_connect(id)
{
	//resetuje umiejetnosci
	klasa_gracza[id] = 0;
	poziom_gracza[id] = 0;
	doswiadczenie_gracza[id] = 0;
	punkty_gracza[id] = 0;
	zdrowie_gracza[id] = 0;
	inteligencja_gracza[id] = 0;
	wytrzymalosc_gracza[id] = 0;
	kondycja_gracza[id] = 0;
	maksymalne_zdrowie_gracza[id] = 0;
	szybkosc_gracza[id] = 0.0;
	hasZoom[id] = false 
	pomocs[id] = true;
	
	get_user_name(id, nazwa_gracza[id], 63);
	
	remove_task(id+ZADANIE_POKAZ_INFORMACJE);
	remove_task(id+ZADANIE_POKAZ_REKLAME);	
	remove_task(id+ZADANIE_USTAW_SZYBKOSC);
	remove_task(id+ZADANIE_WSKRZES);
	remove_task(id+ZADANIE_WYSZKOLENIE_SANITARNE);
	
	set_task(10.0, "PokazReklame", id+ZADANIE_POKAZ_REKLAME);
	set_task(3.0, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE);
	
	//resetuje przedmioty
	UsunPrzedmiot(id);
}

public client_disconnect(id)
{
	remove_task(id+ZADANIE_POKAZ_INFORMACJE);
	remove_task(id+ZADANIE_POKAZ_REKLAME);	
	remove_task(id+ZADANIE_USTAW_SZYBKOSC);
	remove_task(id+ZADANIE_WSKRZES);
	remove_task(id+ZADANIE_WYSZKOLENIE_SANITARNE);
	hasZoom[id] = false 
	ZapiszDane(id);
	UsunPrzedmiot(id);
	client_disconnect_magnet(id);
}

public RozbrajaBombe(id)
	if(klasa_gracza[id])
	rozbrajajacy = id;

public BombaPodlozona()
{
	new Players[32], playerCount, id;
	get_players(Players, playerCount, "aeh", "TERRORIST");
	
	if(get_playersnum() > 1)
	{
		doswiadczenie_gracza[podkladajacy] += doswiadczenie_za_bombe;
		for (new i=0; i<playerCount; i++) 
		{
			id = Players[i];
			if(!klasa_gracza[id])
				continue;
			
			if(id != podkladajacy)
			{
				doswiadczenie_gracza[id] += doswiadczenia_za_zabojstwo;
				ColorChat(id, RED, "[COD]^x04 Dostales %i doswiadczenia za podlozenie bomby przez twoj team.", doswiadczenia_za_zabojstwo);
			}
			else
			{
				ColorChat(id, RED, "[COD]^x04 Dostales %i doswiadczenia za podlozenie bomby.", doswiadczenie_za_bombe);
			}
			SprawdzPoziom(id);
		}
	}
}

public BombaRozbrojona()
{
	new Players[32], playerCount, id;
	get_players(Players, playerCount, "aeh", "CT");
	
	doswiadczenie_gracza[rozbrajajacy] += doswiadczenie_za_bombe;
	for (new i=0; i<playerCount; i++) 
	{
		id = Players[i];
		if(!klasa_gracza[id])
			continue;
		if(id != rozbrajajacy)
		{
			doswiadczenie_gracza[id]+= doswiadczenia_za_zabojstwo;
			ColorChat(id, RED, "[COD]^x04 Dostales %i doswiadczenia za rozbrojenie bomby przez twoj team.", doswiadczenia_za_zabojstwo);
		}
		else
			ColorChat(id, RED, "[COD]^x04 Dostales %i doswiadczenia za rozbrojenie bomby.",doswiadczenie_za_bombe);
		SprawdzPoziom(id);
	}
}

public OpisKlasy(id)
{
	new menu = menu_create("Wybierz klase:", "OpisKlasy_Handle");
	for(new i=1; i<sizeof nazwy_klas; i++)
		menu_additem(menu, nazwy_klas[i]);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
	
	client_cmd(id, "spk QTM_CodMod/select");
}

public OpisKlasy_Handle(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	ColorChat(id, RED, "[COD]^x04 %s: %s", nazwy_klas[item+1], opisy_klas[item+1]);
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public OpisItemow(id)
{
        new menu = menu_create("Wybierz przedmiot:", "OpisItemow_Handle");
        for(new i=1; i<sizeof nazwy_przedmiotow; i++)
        menu_additem(menu, nazwy_przedmiotow[i]);
        menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
        menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
        menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
        menu_display(id, menu);
        
        client_cmd(id, "spk QTM_CodMod/select");
}

public OpisItemow_Handle(id, menu, item)
{
        if(item == MENU_EXIT)
        {
                menu_destroy(menu);
                return PLUGIN_CONTINUE;
        }
        ColorChat(id, GREEN, "[CoD]^x01 ^x03%s^x01: %s.", nazwy_przedmiotow[item+1], opisy_przedmiotow[item+1]);
        menu_display(id, menu);
        
        client_cmd(id, "spk QTM_CodMod/select");
        
        return PLUGIN_CONTINUE;
}

public WybierzKlase(id)
{
	new menu = menu_create("Wybierz klase:", "WybierzKlase_Handle");
	new klasa[50];
	for(new i=1; i<sizeof nazwy_klas; i++)
	{
		WczytajDane(id, i);
		format(klasa, 49, "%s Poziom: %i", nazwy_klas[i], poziom_gracza[id]);
		menu_additem(menu, klasa);
	}
	
	WczytajDane(id, klasa_gracza[id]);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
	
	client_cmd(id, "spk QTM_CodMod/select");
	#if defined BOTY
	if(is_user_bot2(id))
		WybierzKlase_Handle(id, menu, random(sizeof nazwy_klas-1));
	#endif
}

public WybierzKlase_Handle(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}	
	
	item++;
	
	if(item == klasa_gracza[id])
		return PLUGIN_CONTINUE;
	
	if(item == Rambo && !(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		client_print(id, print_chat, "[COD] Nie masz uprawnien aby kozystac z klasy premium.");
		WybierzKlase(id);
		return PLUGIN_CONTINUE;
	}
	
	if(item == Kapitan && !(get_user_flags(id) & ADMIN_LEVEL_G))
	{
		client_print(id, print_chat, "[COD] Nie masz uprawnien aby kozystac z klasy premium.");
		WybierzKlase(id);
		return PLUGIN_CONTINUE;
	}
	
	
	if(item == Major && !(get_user_flags(id) & ADMIN_LEVEL_F))
	{
		client_print(id, print_chat, "[COD] Nie masz uprawnien aby kozystac z klasy premium.");
		WybierzKlase(id);
		return PLUGIN_CONTINUE;
	}
	
	if(klasa_gracza[id])
	{
		nowa_klasa_gracza[id] = item;
		client_print(id, print_chat, "[COD] Klasa zostanie zmieniona w nastepnej rundzie.");
	}
	else
	{
		klasa_gracza[id] = item;
		WczytajDane(id, klasa_gracza[id]);
		Odrodzenie(id);
	}
	return PLUGIN_CONTINUE;
}

public PrzydzielPunkty(id)
{
	new inteligencja[65];
	new zdrowie[60];
	new wytrzymalosc[60];
	new kondycja[60];
	new tytul[25];
	format(inteligencja, 64, "Inteligencja: \r%i \y(Zwieksza obrazenia zadawane przedmiotami)", inteligencja_gracza[id]);
	format(zdrowie, 59, "Zycie: \r%i \y(Zwieksza zycie)", zdrowie_gracza[id]);
	format(wytrzymalosc, 59, "Wytrzymalosc: \r%i \y(Zmniejsza obrazenia)", wytrzymalosc_gracza[id]);
	format(kondycja, 59, "Kondycja: \r%i \y(Zwieksza tempo chodu)", kondycja_gracza[id]);
	format(tytul, 24, "Przydziel Punkty(%i):", punkty_gracza[id]);
	new menu = menu_create(tytul, "PrzydzielPunkty_Handler");
	menu_additem(menu, inteligencja);
	menu_additem(menu, zdrowie);
	menu_additem(menu, wytrzymalosc);
	menu_additem(menu, kondycja);
	menu_display(id, menu);
	#if defined BOTY
	if(is_user_bot2(id))
		PrzydzielPunkty_Handler(id, menu, random(4));
	#endif
}

public PrzydzielPunkty_Handler(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item) 
	{ 
		case 0: 
		{	
			if(inteligencja_gracza[id]<100)
				inteligencja_gracza[id]++;
			else 
				ColorChat(id, RED, "[COD]^x04 Maxymalny poziom inteligencji osiagniety");
			
		}
		case 1: 
		{	
			if(zdrowie_gracza[id]<80)
				zdrowie_gracza[id]++;
			else 
				ColorChat(id, RED, "[COD]^x04 Maxymalny poziom sily osiagniety");
		}
		case 2: 
		{	
			if(wytrzymalosc_gracza[id]<200)
				wytrzymalosc_gracza[id]++;
			else 
				ColorChat(id, RED, "[COD]^x04 Maxymalny poziom zrecznosci osiagniety");
			
		}
		case 3: 
		{	
			if(kondycja_gracza[id]<200)
				kondycja_gracza[id]++;
			else 
				ColorChat(id, RED, "[COD]^x04 Maxymalny poziom zwinnosci osiagniety");
		}
	}
	
	punkty_gracza[id]--;
	
	if(punkty_gracza[id]>0)
		PrzydzielPunkty(id);
	
	return PLUGIN_CONTINUE;
}

public ResetujPunkty(id)
{	
	punkty_gracza[id] = poziom_gracza[id]*2-2;
	inteligencja_gracza[id] = 0;
	zdrowie_gracza[id] = 0;
	kondycja_gracza[id] = 0;
	wytrzymalosc_gracza[id] = 0;
	PrzydzielPunkty(id)
}

public KomendaResetujPunkty(id)
{	
	ColorChat(id, RED, "[COD]^x04 Punkty zostana zresetowane.");
	client_cmd(id, "spk QTM_CodMod/select");
	ResetujPunkty(id);
}

public WyszkolenieSanitarne(id)
{
	id -= ZADANIE_WYSZKOLENIE_SANITARNE;
	if(informacje_przedmiotu_gracza[id][0] != 16 || informacje_przedmiotu_gracza[id][0] != 35)
		return PLUGIN_CONTINUE;
	set_task(5.0, "WyszkolenieSanitarne", id+ZADANIE_WYSZKOLENIE_SANITARNE);
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	new health = get_user_health(id);
	
	fm_set_user_health(id, min((informacje_przedmiotu_gracza[id][0] == 16)? health+10: health+15, maksymalne_zdrowie_gracza[id]));
	return PLUGIN_CONTINUE;
}

public StworzApteczke(id)
{
	if (!ilosc_apteczek_gracza[id])
	{
		client_print(id, print_center, "Masz tylko 2 apteczki na runde!");
		return PLUGIN_CONTINUE;
	}
	
	if(inteligencja_gracza[id] < 1)
		client_print(id, print_center, "Aby wzmocnic apteczke, zwieksz inteligencje!");
	
	ilosc_apteczek_gracza[id]--;
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, "Apteczka");
	entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_vector(ent, EV_VEC_origin, origin);
	entity_set_float(ent, EV_FL_ltime, halflife_time() + 7 + 0.1);
	
	
	entity_set_model(ent, "models/w_medkit.mdl");
	set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) 	;
	drop_to_floor(ent);
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
	
	return PLUGIN_CONTINUE;
}

public ApteczkaThink(ent)
{
	new id = entity_get_edict(ent, EV_ENT_owner);
	new totem_dist = 300;
	new totem_heal = 5+floatround(inteligencja_gracza[id]*0.5);
	if (entity_get_edict(ent, EV_ENT_euser2) == 1)
	{		
		new Float:forigin[3], origin[3];
		entity_get_vector(ent, EV_VEC_origin, forigin);
		FVecIVec(forigin,origin);
		
		new entlist[33];
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist, 32,forigin);
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i];
			
			if (get_user_team(pid) != get_user_team(id))
				continue;
			
			new zdrowie = get_user_health(pid);
			new nowe_zdrowie = (zdrowie+totem_heal<maksymalne_zdrowie_gracza[pid])?zdrowie+totem_heal:maksymalne_zdrowie_gracza[pid];
			if (is_user_alive(pid)) fm_set_user_health(pid, nowe_zdrowie);		
		}
		
		entity_set_edict(ent, EV_ENT_euser2, 0);
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + 1.5);
		
		return PLUGIN_CONTINUE;
	}
	
	if (entity_get_float(ent, EV_FL_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent);
		return PLUGIN_CONTINUE;
	}
	
	if (entity_get_float(ent, EV_FL_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) ;
	
	new Float:forigin[3], origin[3];
	entity_get_vector(ent, EV_VEC_origin, forigin);
	FVecIVec(forigin,origin);
	
	//Find people near and give them health
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + totem_dist );
	write_coord( origin[2] + totem_dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 255 ); // r, g, b
	write_byte( 100 );// r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	entity_set_edict(ent, EV_ENT_euser2 ,1);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.5);
	
	
	return PLUGIN_CONTINUE;
	
}

public StworzRakiete(id)
{
	if (!ilosc_rakiet_gracza[id])
	{
		client_print(id, print_center, "Wykrzystales juz wszystkie rakiety!");
		return PLUGIN_CONTINUE;
	}
	
	if(poprzednia_rakieta_gracza[id] + 2.0 > get_gametime())
	{
		client_print(id, print_center, "Rakiet mozesz uzywac co 2 sekundy!");
		return PLUGIN_CONTINUE;
	}
	
	if (is_user_alive(id))
	{	
		if(inteligencja_gracza[id] < 1)
			client_print(id, print_center, "Aby wzmocnic rakiete, zwieksz inteligencje!");
		
		poprzednia_rakieta_gracza[id] = get_gametime();
		ilosc_rakiet_gracza[id]--;
		
		new Float: Origin[3], Float: vAngle[3], Float: Velocity[3];
		
		entity_get_vector(id, EV_VEC_v_angle, vAngle);
		entity_get_vector(id, EV_VEC_origin , Origin);
		
		new Ent = create_entity("info_target");
		
		entity_set_string(Ent, EV_SZ_classname, "Rocket");
		entity_set_model(Ent, "models/rpgrocket.mdl");
		
		vAngle[0] *= -1.0;
		
		entity_set_origin(Ent, Origin);
		entity_set_vector(Ent, EV_VEC_angles, vAngle);
		
		entity_set_int(Ent, EV_INT_effects, 2);
		entity_set_int(Ent, EV_INT_solid, SOLID_BBOX);
		entity_set_int(Ent, EV_INT_movetype, MOVETYPE_FLY);
		entity_set_edict(Ent, EV_ENT_owner, id);
		
		VelocityByAim(id, 1000 , Velocity);
		entity_set_vector(Ent, EV_VEC_velocity ,Velocity);
	}	
	return PLUGIN_CONTINUE;
}

public PolozDynamit(id)
{
	if(!ilosc_dynamitow_gracza[id])
	{
		client_print(id, print_center, "Wykorzystales juz caly dynamit!");
		return PLUGIN_CONTINUE;
	}
	
	if(inteligencja_gracza[id] < 1)
		client_print(id, print_center, "Aby wzmocnic dynamit, zwieksz inteligencje!");
	
	ilosc_dynamitow_gracza[id]--;
	new Float:fOrigin[3], iOrigin[3];
	entity_get_vector( id, EV_VEC_origin, fOrigin);
	iOrigin[0] = floatround(fOrigin[0]);
	iOrigin[1] = floatround(fOrigin[1]);
	iOrigin[2] = floatround(fOrigin[2]);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(sprite_blast);
	write_byte(32);
	write_byte(20);
	write_byte(0);
	message_end();
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, iOrigin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( iOrigin[0] );
	write_coord( iOrigin[1] );
	write_coord( iOrigin[2] );
	write_coord( iOrigin[0] );
	write_coord( iOrigin[1] + 300 );
	write_coord( iOrigin[2] + 300 );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 255 ); // r, g, b
	write_byte( 100 );// r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 8 ); // speed
	message_end();
	
	new entlist[33];
	new numfound = find_sphere_class(id, "player", 300.0 , entlist, 32);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
		
		if (!is_user_alive(pid) || get_user_team(id) == get_user_team(pid) || informacje_przedmiotu_gracza[pid][0] == 24)
			continue;
		ExecuteHam(Ham_TakeDamage, pid, 0, id, 90.0+float(inteligencja_gracza[id]) , 1);
	}
	return PLUGIN_CONTINUE;
}

public PostawMine(id)
{
	if (!ilosc_min_gracza[id])
	{
		client_print(id, print_center, "Wykorzystales juz wszystkie miny!");
		return PLUGIN_CONTINUE;
	}
	
	if(inteligencja_gracza[id] < 1)
		client_print(id, print_center, "Aby wzmocnic miny, zwieksz inteligencje!");
	
	ilosc_min_gracza[id]--;
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	
	new ent = create_entity("info_target");
	entity_set_string(ent ,EV_SZ_classname, "Mine");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	
	entity_set_model(ent, "models/mine.mdl");
	entity_set_size(ent,Float:{-16.0,-16.0,0.0},Float:{16.0,16.0,2.0});
	
	drop_to_floor(ent);
	
	entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.01) ;
	
	set_rendering(ent,kRenderFxNone, 0,0,0, kRenderTransTexture,50)	;
	
	return PLUGIN_CONTINUE;
}

public DotykMiny(ent, id)
{
	new attacker = entity_get_edict(ent, EV_ENT_owner);
	if (get_user_team(attacker) != get_user_team(id))
	{
		new Float:fOrigin[3], iOrigin[3];
		entity_get_vector( ent, EV_VEC_origin, fOrigin);
		iOrigin[0] = floatround(fOrigin[0]);
		iOrigin[1] = floatround(fOrigin[1]);
		iOrigin[2] = floatround(fOrigin[2]);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(TE_EXPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(sprite_blast);
		write_byte(32); // scale
		write_byte(20); // framerate
		write_byte(0);// flags
		message_end();
		new entlist[33];
		new numfound = find_sphere_class(ent,"player", 90.0 ,entlist, 32);
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i];
			
			if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid) || informacje_przedmiotu_gracza[pid][0] == 24 || klasa_gracza[id] == Obronca || klasa_gracza[id] == Deagleman)
				continue;
			
			ExecuteHam(Ham_TakeDamage, pid, ent, attacker, 90.0+float(inteligencja_gracza[attacker]) , 1);
		}
		remove_entity(ent);
	}
}

public DotykRakiety(ent)
{
	if ( !is_valid_ent(ent))
		return;
	
	new attacker = entity_get_edict(ent, EV_ENT_owner);
	
	new Float:fOrigin[3], iOrigin[3];
	entity_get_vector( ent, EV_VEC_origin, fOrigin);	
	iOrigin[0] = floatround(fOrigin[0]);
	iOrigin[1] = floatround(fOrigin[1]);
	iOrigin[2] = floatround(fOrigin[2]);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(sprite_blast);
	write_byte(32); // scale
	write_byte(20); // framerate
	write_byte(0);// flags
	message_end();
	
	new entlist[33];
	new numfound = find_sphere_class(ent, "player", 230.0, entlist, 32);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
		
		if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid) || informacje_przedmiotu_gracza[pid][0] == 24)
			continue;
		ExecuteHam(Ham_TakeDamage, pid, ent, attacker, 55.0+float(inteligencja_gracza[attacker]) , 1);
	}
	remove_entity(ent);
}	

public CurWeapon(id)
{
	if(freezetime || !klasa_gracza[id])
		return PLUGIN_CONTINUE;
	
	new weapon = read_data(2);
	
	if(informacje_przedmiotu_gracza[id][0] == 51 && maxClip[weapon] != -1)
		set_user_clip(id, maxClip[weapon]);
	
	UstawSzybkosc(id);
	
	if(informacje_przedmiotu_gracza[id][0] == 59)
	{
		if(weapon == CSW_KNIFE)
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 50);
		else 
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 255);
	}
	
	if(weapon == CSW_C4)
		podkladajacy = id;
	return PLUGIN_CONTINUE;
}

public EmitSound(id, iChannel, szSound[], Float:fVol, Float:fAttn, iFlags, iPitch ) 
{
	if(equal(szSound, "common/wpn_denyselect.wav"))
	{
		UzyjPrzedmiotu(id);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public UzyjPrzedmiotu(id)
{
	if((informacje_przedmiotu_gracza[id][0] == 19 || informacje_przedmiotu_gracza[id][0] == 39) && informacje_przedmiotu_gracza[id][1]>0) 
	{
		fm_set_user_health(id, maksymalne_zdrowie_gracza[id]);
		informacje_przedmiotu_gracza[id][1]--;
	}
	if(informacje_przedmiotu_gracza[id][0] == 42 && informacje_przedmiotu_gracza[id][1]>0) 
	{
		set_task(0.1,"clipon",id,"",0,"a",1);
		informacje_przedmiotu_gracza[id][1]--;
	}
	if(informacje_przedmiotu_gracza[id][0] == 45 && informacje_przedmiotu_gracza[id][1]>0) 
	{
		set_task(0.1,"godon",id,"",0,"a",1);
		informacje_przedmiotu_gracza[id][1]--;
	}
	
	if(informacje_przedmiotu_gracza[id][1] == 1 && informacje_przedmiotu_gracza[id][0] == 56)
	{
		set_task(0.1,"clipon",id,"",0,"a",1);
		informacje_przedmiotu_gracza[id][1] = 0;
	}
	
	if(informacje_przedmiotu_gracza[id][1] == 1 && informacje_przedmiotu_gracza[id][0] == 57)
	{
		new Origin[3], DstOrigin[3];
		get_user_origin(id, Origin);
		get_user_origin(id, DstOrigin, 3);
		
		DstOrigin[0] += DstOrigin[0]-Origin[0] < 0 ? 50 : -50;
		DstOrigin[1] += DstOrigin[1]-Origin[1] < 0 ? 50 : -50;
		DstOrigin[2] += DstOrigin[2]-Origin[2]-50 < 0 ? 50 : -50;
		
		informacje_przedmiotu_gracza[id][1] = 0;
		
		fm_set_user_origin(id, DstOrigin);
	}
	
	if(informacje_przedmiotu_gracza[id][0] == 61)
		UzyjElektromagnes(id);
	
	if(informacje_przedmiotu_gracza[id][0] == 63 && informacje_przedmiotu_gracza[id][1])
	{
		set_task(3.0, "Pusta", id+ZADANIE_ODBIJAJ);
		informacje_przedmiotu_gracza[id][1] = 0;
	}
	
	if(informacje_przedmiotu_gracza[id][0] == 65 && !zatrzymaj_czas)
	{
		zatrzymaj_czas = id;
		set_task(3.0, "Pusc");
		UsunPrzedmiot(id);
	}
	
	if(ilosc_apteczek_gracza[id]>0)
		StworzApteczke(id);
	if(ilosc_rakiet_gracza[id]>0)
		StworzRakiete(id);
	if(ilosc_min_gracza[id]>0)
		PostawMine(id);
	if(ilosc_dynamitow_gracza[id]>0)
		PolozDynamit(id);
	
	return PLUGIN_HANDLED;
}

public Pusc()
	zatrzymaj_czas = 0;

public Pusta(){}

public UzyjElektromagnes(id)
{	
	if (pozostale_elektromagnesy[id] < 1)
	{
		client_print(id, print_center, "Wykorzystales juz elektromagnes!");
		return PLUGIN_CONTINUE;
	}
	
	pozostale_elektromagnesy[id]--;
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, "magnet");
	entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_vector(ent, EV_VEC_origin, origin);
	entity_set_float(ent, EV_FL_ltime, halflife_time() + get_pcvar_num(pcvar_czas_dzialania) + 3.5);
	entity_set_model(ent, "models/QTM_CodMod/electromagnet.mdl");
	drop_to_floor(ent);
	
	emit_sound(ent, CHAN_VOICE, "weapons/mine_charge.wav", 0.5, ATTN_NORM, 0, PITCH_NORM );
	emit_sound(ent, CHAN_ITEM, "weapons/mine_deploy.wav", 0.5, ATTN_NORM, 0, PITCH_NORM );
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 3.5);
	
	return PLUGIN_CONTINUE;
}
public ZapiszDane(id)
{
	new vaultkey[64],vaultdata[256];
	format(vaultkey,63,"%s-%i-cod", nazwa_gracza[id], klasa_gracza[id]);
	format(vaultdata,255,"%i#%i#%i#%i#%i#%i", doswiadczenie_gracza[id], poziom_gracza[id], inteligencja_gracza[id], zdrowie_gracza[id], wytrzymalosc_gracza[id], kondycja_gracza[id]);
	nvault_set(g_vault,vaultkey,vaultdata);
}

public WczytajDane(id, klasa)
{
	new vaultkey[64],vaultdata[256];
	format(vaultkey,63,"%s-%i-cod", nazwa_gracza[id], klasa);
	format(vaultdata,255,"%i#%i#%i#%i#%i#%i", doswiadczenie_gracza[id], poziom_gracza[id], inteligencja_gracza[id], zdrowie_gracza[id], wytrzymalosc_gracza[id], kondycja_gracza[id]);
	nvault_get(g_vault,vaultkey,vaultdata,255);
	
	replace_all(vaultdata, 255, "#", " ");
	
	new doswiadczeniegracza[32], poziomgracza[32], inteligencjagracza[32], silagracza[32], zrecznoscgracza[32], zwinnoscgracza[32];
	
	parse(vaultdata, doswiadczeniegracza, 31, poziomgracza, 31, inteligencjagracza, 31, silagracza, 31, zrecznoscgracza, 31, zwinnoscgracza, 31);
	
	doswiadczenie_gracza[id] = str_to_num(doswiadczeniegracza);
	poziom_gracza[id] = str_to_num(poziomgracza)>0?str_to_num(poziomgracza):1;
	inteligencja_gracza[id] = str_to_num(inteligencjagracza);
	zdrowie_gracza[id] = str_to_num(silagracza);
	wytrzymalosc_gracza[id] = str_to_num(zrecznoscgracza);
	kondycja_gracza[id] = str_to_num(zwinnoscgracza);
	punkty_gracza[id] = (poziom_gracza[id]-1)*2-inteligencja_gracza[id]-zdrowie_gracza[id]-wytrzymalosc_gracza[id]-kondycja_gracza[id];
}  
public WyrzucPrzedmiot(id)
{
	if(informacje_przedmiotu_gracza[id][0])
	{
		ColorChat(id, RED, "[COD]^x04 Wyrzuciles %s.", nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]]);
		UsunPrzedmiot(id);
	}
	else
		ColorChat(id, RED, "[COD]^x04 Nie masz zadnego przedmiotu.");
}

public UsunPrzedmiot(id)
{
	informacje_przedmiotu_gracza[id][0] = 0;
	informacje_przedmiotu_gracza[id][1] = 0;
	if(is_user_alive(id)){
		if(!informacje_przedmiotu_gracza[id][0] && klasa_gracza[id] != Szturmowiec)
		{
		set_user_footsteps(id, 0);
		}
		if(!informacje_przedmiotu_gracza[id][0])
		{
			if(klasa_gracza[id] != Partyzant)
				fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 255);
			else
				fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 70);
		}
		if(!informacje_przedmiotu_gracza[id][0] && klasa_gracza[id] != Deagleman)
		ZmienUbranie(id, 1);
	}
}

public DajPrzedmiot(id, przedmiot)
{
	UsunPrzedmiot(id);
	informacje_przedmiotu_gracza[id][0] = przedmiot;
	new name[32]
	get_user_name(id, name, 31)
	ColorChat(id, RED, "[COD]^x01 Znalazles przedmiot - ^x04 %s", nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]]); 	
	switch(przedmiot)
	{			
		case 1: 
		{
			if(klasa_gracza[id] == Szturmowiec)
				DajPrzedmiot(id, random_num(1, sizeof nazwy_przedmiotow-1));
			else
				set_user_footsteps(id, 1);
		}
		case 2: informacje_przedmiotu_gracza[id][1] = random_num(3,6);
			case 3: informacje_przedmiotu_gracza[id][1] = random_num(6, 11);
			case 5: informacje_przedmiotu_gracza[id][1] = random_num(6, 9);
			case 6:
		{
			informacje_przedmiotu_gracza[id][1] = random_num(120, 170);
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, informacje_przedmiotu_gracza[id][1]);
		}
		case 7: informacje_przedmiotu_gracza[id][1] = random_num(2, 4);
			case 8:
		{
			if(klasa_gracza[id] == Komandos)
				DajPrzedmiot(id, random_num(1, sizeof nazwy_przedmiotow-1));
		}
		case 9:
		{
			informacje_przedmiotu_gracza[id][1] = random_num(1, 3);
			ZmienUbranie(id, 0);
			fm_give_item(id, "weapon_hegrenade");
		}
		case 10: 
		{
		informacje_przedmiotu_gracza[id][1] = random_num(4, 8);
		fm_give_item(id, "weapon_hegrenade");
		}
			case 12: informacje_przedmiotu_gracza[id][1] = random_num(1, 4);
			case 13: fm_give_item(id, "weapon_awp");
			case 15:
		{
			if(klasa_gracza[id] == Rambo)
				DajPrzedmiot(id, random_num(1, sizeof nazwy_przedmiotow-1));
		}
		case 16: set_task(5.0, "WyszkolenieSanitarne", id+ZADANIE_WYSZKOLENIE_SANITARNE);
			case 17: fm_set_user_armor(id, 500);
			case 18:
		{
			maksymalne_zdrowie_gracza[id] += 100;
			szybkosc_gracza[id] -= 0.4;
		}
		case 19: informacje_przedmiotu_gracza[id][1] = 1;
			case 25:
		{
			maksymalne_zdrowie_gracza[id] += 50;
			szybkosc_gracza[id] -= 0.3;
		}
		case 26: informacje_przedmiotu_gracza[id][1] = random_num(3, 6);
			case 27: informacje_przedmiotu_gracza[id][1] = 3;
			case 29:
		{
			maksymalne_zdrowie_gracza[id] += 50;
			szybkosc_gracza[id] += 0.2;
		}
		case 30:
		{
			maksymalne_zdrowie_gracza[id] += 100;
			szybkosc_gracza[id] -= 0.7;
		}
		case 31:
		{
			informacje_przedmiotu_gracza[id][1] = random_num(1, 3);
			ZmienUbranie(id, 0);
			fm_give_item(id, "weapon_hegrenade");
		}
		case 32: 
		{
			informacje_przedmiotu_gracza[id][1] = random_num(2, 7);
			fm_give_item(id, "weapon_deagle");
		}
		case 33: 
		{
			informacje_przedmiotu_gracza[id][1] = random_num(3, 9);
			fm_give_item(id, "weapon_m3");
		}
			case 34: fm_set_user_gravity(id, 0.5);
			case 35: set_task(5.0, "WyszkolenieSanitarne", id+ZADANIE_WYSZKOLENIE_SANITARNE);
			case 37: szybkosc_gracza[id] += 0.3;
			case 36:
		{
			set_user_footsteps(id, 1);
			maksymalne_zdrowie_gracza[id] += 100;
		}
		case 39: informacje_przedmiotu_gracza[id][1] = 1;
			case 40:
		{
			informacje_przedmiotu_gracza[id][1] = random_num(3, 6);
			fm_set_user_armor(id, 500);
		}
		case 42: informacje_przedmiotu_gracza[id][1] = 1;
			case 43:
		{
			set_user_footsteps(id, 1);
			maksymalne_zdrowie_gracza[id] += 100;
			szybkosc_gracza[id] += 0.4;
		}
		case 45: informacje_przedmiotu_gracza[id][1] = 1;
			case 46:
		{
			informacje_przedmiotu_gracza[id][1] = random_num(1, 3);
			ZmienUbranie(id, 0);
			fm_give_item(id, "weapon_scout");
		}
		case 47: set_user_footsteps(id, 1);
			case 56: informacje_przedmiotu_gracza[id][1] = 1;
			case 57: informacje_przedmiotu_gracza[id][1] = 1;
			case 59: fm_set_user_gravity(id, 0.5);
		case 60:
		{
			set_user_footsteps(id, 1);
			set_user_health(id, 1);
			maksymalne_zdrowie_gracza[id] = 1;
			fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
		}
			case 61: ResetHUD(id);
			case 63: informacje_przedmiotu_gracza[id][1] = random_num(2, 4);
		}
}

public OpisPrzedmiotu(id)
{
	new opis_przedmiotu[128];
	new losowa_wartosc[3];
	num_to_str(informacje_przedmiotu_gracza[id][1], losowa_wartosc, 2);
	format(opis_przedmiotu, 127, opisy_przedmiotow[informacje_przedmiotu_gracza[id][0]]);
	replace_all(opis_przedmiotu, 127, "LW", losowa_wartosc);
	ColorChat(id, RED, "[COD] ^x01Przedmiot ^x04%s^n^x01Opis: ^x04%s",nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]],opis_przedmiotu)
}

public Wskrzes(id)
{
	id-=ZADANIE_WSKRZES;
	ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public SprawdzPoziom(id)
{	
	if(poziom_gracza[id] < 201)
	{
		while(doswiadczenie_gracza[id] >= doswiadczenie_poziomu[poziom_gracza[id]])
		{
			poziom_gracza[id]++;
			set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2);
			ShowSyncHudMsg(id, SyncHudObj3, "Zdobyles poziom");
			client_cmd(id, "spk QTM_CodMod/levelup");
		}
		
		while(doswiadczenie_gracza[id] < doswiadczenie_poziomu[poziom_gracza[id]-1])
			poziom_gracza[id]--;
		
		punkty_gracza[id] = (poziom_gracza[id]-1)*2-inteligencja_gracza[id]-zdrowie_gracza[id]-wytrzymalosc_gracza[id]-kondycja_gracza[id];
	}
	ZapiszDane(id);
}

public message_health(msg_id,msg_dest,msg_entity)
{
	if(pev(msg_entity, pev_health) >= 255)
	{
		set_msg_arg_int(1, ARG_BYTE, 255);
	}
	return PLUGIN_CONTINUE;
}



public PokazInformacje(id)
{               
	id -= ZADANIE_POKAZ_INFORMACJE;
	
	set_task(0.1, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE);
	
	if(!is_user_alive(id))
	{
		if(!is_valid_ent(id))
			return PLUGIN_CONTINUE;
		
		new target = entity_get_int(id, EV_INT_iuser2);
		
		if(target == 0)
			return PLUGIN_CONTINUE;
		set_hudmessage(255, 255, 255, 0.63, 0.46, 0, 6.0, 0.3, 0.0, 0.0, 2);
		ShowSyncHudMsg(id, SyncHudObj, "Klasa : %s^nDoswiadczenie : %i / %i^nPoziom : %i^nPrzedmiot : %s", nazwy_klas[klasa_gracza[target]], doswiadczenie_gracza[target], doswiadczenie_poziomu[poziom_gracza[target]], poziom_gracza[target], nazwy_przedmiotow[informacje_przedmiotu_gracza[target][0]]);
		return PLUGIN_CONTINUE;
	}
	
	new hp = get_user_health(id)
	set_hudmessage(0, 255, 0, 0.01, 0.25, 0, 6.0, 0.3, 0.0, 0.0);
	ShowSyncHudMsg(id, SyncHudObj, "[Klasa : %s]^n[Doswiadczenie : %i / %i]^n[Poziom : %i]^n[Przedmiot : %s]^n[Zycie : %d]^n[Forum: ShootMachine.pl]", nazwy_klas[klasa_gracza[id]], doswiadczenie_gracza[id], doswiadczenie_poziomu[poziom_gracza[id]], poziom_gracza[id], nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]], hp);
	
	return PLUGIN_CONTINUE;
}

public PokazReklame(id)
{
	id-=ZADANIE_POKAZ_REKLAME;
	if( -1 < get_user_team(id) < 4){
		client_print(id, print_chat,"[COD]^n Modyfikacja by O`Zone.");
	}
	return PLUGIN_CONTINUE	
	
}
public UstawSzybkosc(id)
{
	id -= id>32? ZADANIE_USTAW_SZYBKOSC: 0;
	
	if(klasa_gracza[id])
		fm_set_user_maxspeed(id, szybkosc_gracza[id]);
}

public ZmienUbranie(id,reset)
{
	if (id<1 || id>32 || !is_user_connected(id)) 
		return PLUGIN_CONTINUE;
	
	if (reset)
		cs_reset_user_model(id);
	else
	{
		new num = random_num(0,3);
		switch(get_user_team(id))
		{
			case 1: cs_set_user_model(id, Ubrania_CT[num]);
				case 2:cs_set_user_model(id, Ubrania_Terro[num]);
			}
	}
	
	return PLUGIN_CONTINUE;
}
public WylaczPomoc(id) 
{
	if(pomocs[id] == true)
	{
		pomocs[id] = false;
		set_hudmessage(255, 0, 0, -1.0, 0.01)
		show_hudmessage(id, "Pomoc zostala wylaczona")
	}
	else if(pomocs[id] == false)
	{
		pomocs[id] = true;
		Pomoc();
		set_hudmessage(255, 0, 0, -1.0, 0.01)
		show_hudmessage(id, "Pomoc zostala wlaczona")
	}
}
public Pomoc()
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum);
	
	for (new i = 0; i < iNum ; i++){
		if(!(pomocs[iPlayers[i]] == false))
			switch(random(10))
		{
		  case 0: client_print(iPlayers[i], print_chat, "[COD] Menu komend jest dostepne pod /menu lub klawiszem v.");
				case 1: client_print(iPlayers[i], print_chat, "[COD] Aby zresetowac umiejetnosci napisz /reset.");
				case 2: client_print(iPlayers[i], print_chat, "[COD] Aby zmienic klase napisz /klasa.");
				case 3: client_print(iPlayers[i], print_chat, "[COD] Aby uzyc przedmiotu nacisnij E.");
				case 4: client_print(iPlayers[i], print_chat, "[COD] Aby wyrzucic przedmiot napisz /drop.");
				case 5: client_print(iPlayers[i], print_chat, "[COD] Aby zobaczyc opis przedmiotu napisz /item.");
				case 6: client_print(iPlayers[i], print_chat, "[COD] Aby zobaczyc opis klas napisz /klasy.");
				case 7: client_print(iPlayers[i], print_chat, "[COD]^nAby wylaczyc/wlaczyc pomoc^n napisz /pomoc.");
				case 8: client_print(iPlayers[i], print_chat, "[COD]^nAby zobaczyc opisy przedmiotow wpisz /itemy.");
				case 9: client_print(iPlayers[i], print_chat, "[COD]^nAby skorzystac ze sklepu wpisz /sklep.");
			}
	}
	set_task(30.0, "Pomoc");
}
public cmd_setlvl(id, level, cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[6];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 5);
	new player = cmd_target(id, arg1);
	if(!is_user_connected(player))
		return PLUGIN_HANDLED;
	new value = str_to_num(arg2)-1;
	
	doswiadczenie_gracza[player] = doswiadczenie_poziomu[value];
	poziom_gracza[player] = 0;
	SprawdzPoziom(player);
	return PLUGIN_HANDLED;
}

public DotykBroni(weapon,id)
{
	new model[23];
	entity_get_string(weapon, EV_SZ_model, model, 22);
	if (!is_user_connected(id) || entity_get_edict(weapon, EV_ENT_owner) == id || equal(model, "models/w_backpack.mdl"))
		return HAM_IGNORED;
	return HAM_SUPERCEDE;
}

public BlokujKomende()
	return PLUGIN_HANDLED;

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
		return true;
	
	return false;
}
#if defined BOTY
public is_user_bot2(id)
{
	new ping, loss
	get_user_ping(id, ping, loss)
	if(ping > 0 && loss > 0)
		return false
	return true
}
#endif

stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2];
	new Float:flDot;
	new Float:CoreOrigin[3];
	new Float:TargetOrigin[3];
	new Float:CoreAngles[3];
	
	pev(Core,pev_origin,CoreOrigin);
	pev(Target,pev_origin,TargetOrigin);
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
		return 0.0;
	
	pev(Core,pev_angles, CoreAngles);
	
	for ( new i = 0; i < 2; i++ )
		vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i];
	
	new Float:veclength = Vec2DLength(vec2LOS);
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[0] = 0.0;
		vec2LOS[1] = 0.0;
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[0] = vec2LOS[0]*flLen;
		vec2LOS[1] = vec2LOS[1]*flLen;
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles);
	
	new Float:v_forward[3];
	new Float:v_forward2D[2];
	get_global_vector(GL_v_forward, v_forward);
	
	v_forward2D[0] = v_forward[0];
	v_forward2D[1] = v_forward[1];
	
	flDot = vec2LOS[0]*v_forward2D[0]+vec2LOS[1]*v_forward2D[1];
	
	if ( flDot > 0.5 )
	{
		return flDot;
	}
	
	return 0.0;
}

stock Float:Vec2DLength( Float:Vec[2] )  
{ 
	return floatsqroot(Vec[0]*Vec[0] + Vec[1]*Vec[1] );
}

stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	message_begin( MSG_ONE, g_msg_screenfade,{0,0,0},id );
	write_short( duration );	// Duration of fadeout
	write_short( holdtime );	// Hold time of color
	write_short( fadetype );	// Fade type
	write_byte ( red );		// Red
	write_byte ( green );		// Green
	write_byte ( blue );		// Blue
	write_byte ( alpha );	// Alpha
	message_end();
}

stock set_user_clip(id, ammo)
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _);
	get_weaponname(weapon, weaponname, 31);
	while ((weaponid = find_ent_by_class(weaponid, weaponname)) != 0)
		if(entity_get_edict(weaponid, EV_ENT_owner) == id) 
	{
		set_pdata_int(weaponid, 51, ammo, 4);
		return weaponid;
	}
	return 0;
}

public client_death(killer,victim,weapon,hitplace,TK) {
	
	if(!killer || !victim || TK)
		return;
	
	if(hitplace == HIT_HEAD)
	{
		
		doswiadczenie_gracza[killer] += doswiadczenie_za_hs;
		
		ColorChat(killer, RED, "[COD]^x01 Dostales ^x03 %i ^x01 doswiadczenia za trafienie w glowe.", doswiadczenie_za_hs);
		
	}
}

public message_clcorpse()	
	return PLUGIN_HANDLED

public event_hltv()
{
	fm_remove_entity_name("fake_corpse")
	
	static players[32], num
	get_players(players, num, "a")
	for(new i = 0; i < num; ++i)
		reset_player(players[i])
}

public reset_player(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	remove_task(TASKID_REVIVE + id)
	remove_task(TASKID_RESPAWN + id)
	remove_task(TASKID_CHECKRE + id)
	remove_task(TASKID_CHECKST + id)
	remove_task(TASKID_ORIGIN + id)
	remove_task(TASKID_SETUSER + id)
	
	msg_bartime(id, 0)
	g_revive_delay[id] 	= 0.0
	g_wasducking[id] 	= false
	g_body_origin[id] 	= Float:{0.0, 0.0, 0.0}
	return PLUGIN_HANDLED;
}

public event_death()
{
	new id = read_data(2)
	
	reset_player(id)
	
	static Float:minsize[3]
	pev(id, pev_mins, minsize)
	
	if(minsize[2] == -18.0)
		g_wasducking[id] = true
	else
		g_wasducking[id] = false
	
	set_task(0.5, "task_check_dead_flag", id)
	
	if(read_data(1)<=maxplayers && read_data(1) && read_data(1)!=read_data(2)) cs_set_user_money(read_data(1),cs_get_user_money(read_data(1)) + get_pcvar_num(mkb) - 300)
}

public fwd_playerpostthink(id)
{
	if(!is_user_connected(id) || !g_haskit[id])
		return FMRES_IGNORED
	
	if(!is_user_alive(id))
	{
		msg_statusicon(id, ICON_HIDE)
		return FMRES_IGNORED
	}
	
	new body = find_dead_body(id)
	if(fm_is_valid_ent(body))
	{
		new lucky_bastard = pev(body, pev_owner)
		
		if(!is_user_connected(lucky_bastard))
			return FMRES_IGNORED
		
		new lb_team = get_user_team(lucky_bastard)
		new rev_team = get_user_team(id)
		if(lb_team == 1 || lb_team == 2 && lb_team == rev_team)
			msg_statusicon(id, ICON_FLASH)
	}
	else
		msg_statusicon(id, ICON_SHOW)
	
	return FMRES_IGNORED
}

public task_check_dead_flag(id)
{
	if(!is_user_connected(id))
		return
	
	if(pev(id, pev_deadflag) == DEAD_DEAD)
		create_fake_corpse(id)
	else
		set_task(0.5, "task_check_dead_flag", id)
}	

public create_fake_corpse(id)
{
	set_pev(id, pev_effects, EF_NODRAW)
	
	static model[32]
	cs_get_user_model(id, model, 31)
	
	static player_model[64]
	format(player_model, 63, "models/player/%s/%s.mdl", model, model)
	
	static Float: player_origin[3]
	pev(id, pev_origin, player_origin)
	
	static Float:mins[3]
	mins[0] = -16.0
	mins[1] = -16.0
	mins[2] = -34.0
	
	static Float:maxs[3]
	maxs[0] = 16.0
	maxs[1] = 16.0
	maxs[2] = 34.0
	
	if(g_wasducking[id])
	{
		mins[2] /= 2
		maxs[2] /= 2
	}
	
	static Float:player_angles[3]
	pev(id, pev_angles, player_angles)
	player_angles[2] = 0.0
	
	new sequence = pev(id, pev_sequence)
	
	new ent = fm_create_entity("info_target")
	if(ent)
	{
		set_pev(ent, pev_classname, "fake_corpse")
		engfunc(EngFunc_SetModel, ent, player_model)
		engfunc(EngFunc_SetOrigin, ent, player_origin)
		engfunc(EngFunc_SetSize, ent, mins, maxs)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
		set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		set_pev(ent, pev_owner, id)
		set_pev(ent, pev_angles, player_angles)
		set_pev(ent, pev_sequence, sequence)
		set_pev(ent, pev_frame, 9999.9)
	}	
}

public fwd_emitsound(id, channel, sound[]) 
{
	if(!is_user_alive(id) || !g_haskit[id])
		return FMRES_IGNORED	
	
	if(!equali(sound, "common/wpn_denyselect.wav"))
		return FMRES_IGNORED	
	
	if(task_exists(TASKID_REVIVE + id))
		return FMRES_IGNORED
	
	if(!(fm_get_user_button(id) & IN_USE))
		return FMRES_IGNORED
	
	new body = find_dead_body(id)
	if(!fm_is_valid_ent(body))
		return FMRES_IGNORED
	
	new lucky_bastard = pev(body, pev_owner)
	new lb_team = get_user_team(lucky_bastard)
	new rev_team = get_user_team(id)
	if(lb_team != 1 && lb_team != 2 || lb_team != rev_team)
		return FMRES_IGNORED
	
	static name[32]
	get_user_name(lucky_bastard, name, 31)
	client_print(id, print_chat, "Reanimacja %s", name)
	
	new revivaltime = get_pcvar_num(cvar_revival_time)
	msg_bartime(id, revivaltime)
	
	new Float:gametime = get_gametime()
	g_revive_delay[id] = gametime + float(revivaltime) - 0.01
	
	emit_sound(id, CHAN_AUTO, SOUND_START, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.0, "task_revive", TASKID_REVIVE + id)
	
	return FMRES_SUPERCEDE
}

public task_revive(taskid)
{
	new id = taskid - TASKID_REVIVE
	
	if(!is_user_alive(id))
	{
		failed_revive(id)
		return FMRES_IGNORED
	}
	
	if(!(fm_get_user_button(id) & IN_USE))
	{
		failed_revive(id)
		return FMRES_IGNORED
	}
	
	new body = find_dead_body(id)
	if(!fm_is_valid_ent(body))
	{
		failed_revive(id)
		return FMRES_IGNORED
	}
	
	new lucky_bastard = pev(body, pev_owner)
	if(!is_user_connected(lucky_bastard))
	{
		failed_revive(id)
		return FMRES_IGNORED
	}
	
	new lb_team = get_user_team(lucky_bastard)
	new rev_team = get_user_team(id)
	if(lb_team != 1 && lb_team != 2 || lb_team != rev_team)
	{
		failed_revive(id)
		return FMRES_IGNORED
	}
	
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	velocity[0] = 0.0
	velocity[1] = 0.0
	set_pev(id, pev_velocity, velocity)
	
	new Float:gametime = get_gametime()
	if(g_revive_delay[id] < gametime)
	{
		if(findemptyloc(body, 10.0))
		{
			fm_remove_entity(body)
			emit_sound(id, CHAN_AUTO, SOUND_FINISHED, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			set_task(0.1, "task_respawn", TASKID_RESPAWN + lucky_bastard)
		}
		else
			failed_revive(id)
	}
	else
		set_task(0.1, "task_revive", TASKID_REVIVE + id)
	
	return FMRES_IGNORED
}

public failed_revive(id)
{
	msg_bartime(id, 0)
	emit_sound(id, CHAN_AUTO, SOUND_FAILED, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public task_origin(taskid)
{
	new id = taskid - TASKID_ORIGIN
	engfunc(EngFunc_SetOrigin, id, g_body_origin[id])
	
	static  Float:origin[3]
	pev(id, pev_origin, origin)
	set_pev(id, pev_zorigin, origin[2])
	
	set_task(0.1, "task_stuck_check", TASKID_CHECKST + id)
}

stock find_dead_body(id)
{
	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	new ent
	static classname[32]	
	while((ent = fm_find_ent_in_sphere(ent, origin, get_pcvar_float(cvar_revival_dis))) != 0) 
	{
		pev(ent, pev_classname, classname, 31)
		if(equali(classname, "fake_corpse") && fm_is_ent_visible(id, ent))
			return ent
	}
	return 0
}

stock msg_bartime(id, seconds) 
{
	if(is_user_bot(id))
		return
	
	message_begin(MSG_ONE, g_msg_bartime, _, id)
	write_byte(seconds)
	write_byte(0)
	message_end()
}

stock msg_statusicon(id, status)
{
	if(is_user_bot(id))
		return
	
	message_begin(MSG_ONE, g_msg_statusicon, _, id)
	write_byte(status)
	write_string("rescue")
	write_byte(0)
	write_byte(160)
	write_byte(0)
	message_end()
}

public task_respawn(taskid) 
{
	new id = taskid - TASKID_RESPAWN
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	dllfunc(DLLFunc_Spawn, id)
	set_pev(id, pev_iuser1, 0)
	
	set_task(0.1, "task_check_respawn", TASKID_CHECKRE + id)
}

public task_check_respawn(taskid)
{
	new id = taskid - TASKID_CHECKRE
	
	if(pev(id, pev_iuser1))
		set_task(0.1, "task_respawn", TASKID_RESPAWN + id)
	else
		set_task(0.1, "task_origin", TASKID_ORIGIN + id)
}

public task_stuck_check(taskid)
{
	new id = taskid - TASKID_CHECKST
	
	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	if(origin[2] == pev(id, pev_zorigin))
		set_task(0.1, "task_respawn", TASKID_RESPAWN + id)
	else
		set_task(0.1, "task_setplayer", TASKID_SETUSER + id)
}

public task_setplayer(taskid)
{
	new id = taskid - TASKID_SETUSER
	
	fm_set_user_health(id, get_pcvar_num(cvar_revival_health))
	
	message_begin(MSG_ONE,g_msg_screenfade, _, id)      
	write_short(seconds(2))
	write_short(seconds(2))   
	write_short(0)  
	write_byte(0)    
	write_byte(0)    
	write_byte(0)     
	write_byte(255)    
	message_end()
}


stock bool:findemptyloc(ent, Float:radius)
{
	if(!fm_is_valid_ent(ent))
		return false
	
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	origin[2] += 2.0
	
	new owner = pev(ent, pev_owner)
	new num = 0, bool:found = false
	
	while(num <= 100)
	{
		if(is_hull_vacant(origin))
		{
			g_body_origin[owner][0] = origin[0]
			g_body_origin[owner][1] = origin[1]
			g_body_origin[owner][2] = origin[2]
			
			found = true
			break
		}
		else
		{
			origin[0] += random_float(-radius, radius)
			origin[1] += random_float(-radius, radius)
			origin[2] += random_float(-radius, radius)
			
			num++
		}
	}
	return found
}

stock bool:is_hull_vacant(const Float:origin[3])
{
	new tr = 0
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HUMAN, 0, tr)
	if(!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen))
		return true
	
	return false
}
public godon(id)
{
	fm_set_user_godmode(id, 1) // Tutaj mo¿emy np, daæ coœ co bêdzie uruchomione w trakcie odliczania ja da³em GodMode
	
	Odliczanie[id] = 4    // nasza zmienna + czas ile ma odliczaæ do zera w tym przypadku 4 sekundy
	
	if(task_exists(id + 3431))
	{
		remove_task(id + 3431)
	}
	set_task(1.0, "godoff", id + 3431, _, _, "b")
	
	return PLUGIN_CONTINUE
}
public godoff(task_id)
{
	new id = task_id - 3431
	
	set_hudmessage(0, 255, 0, 0.03, 0.76, 2, 0.02, 1.0, 0.01)
	show_hudmessage(id, "Za %d sekund stracisz Niesmiertelnosc.", Odliczanie[id]) //Wiadomoœæ pokazana w HUD'zie
	
	Odliczanie[id] -= 1 
	
	if(Odliczanie[id] <= 0)
	{
		if(task_exists(task_id))
		{
			remove_task(task_id)
		}
		fm_set_user_godmode(id, 0); // tutaj wy³¹cza goodmoda
	}
}
public clipon(id)
{
	fm_set_user_noclip(id, 1) // Tutaj mo¿emy np, daæ coœ co bêdzie uruchomione w trakcie odliczania ja da³em noclip
	
	Odliczanie[id] = 9    // nasza zmienna + czas ile ma odliczaæ do zera w tym przypadku 9sekund
	
	if(task_exists(id + 3431))
	{
		remove_task(id + 3431)
	}
	set_task(1.0, "clipoff", id + 3431, _, _, "b")
	
	return PLUGIN_CONTINUE
}
public clipoff(task_id)
{
	new id = task_id - 3431
	
	set_hudmessage(0, 255, 0, 0.03, 0.76, 2, 0.02, 1.0, 0.01)
	show_hudmessage(id, "Za %d sekund nie bedzies przechodzil przez sciany.", Odliczanie[id]) //Wiadomoœæ pokazana w HUD'zie
	
	Odliczanie[id] -= 1 
	
	if(Odliczanie[id] <= 0)
	{
		if(task_exists(task_id))
		{
			remove_task(task_id)
		}
		fm_set_user_noclip(id, 0); // tutaj wy³¹cza noclipa
	}
}

public client_PreThink(id) {
	if (entity_get_int(id, EV_INT_button) & 2 && informacje_przedmiotu_gracza[id][0] == 38) {
		new flags = entity_get_int(id, EV_INT_flags)
		
		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE
		
		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] += 250.0
		entity_set_vector(id, EV_VEC_velocity, velocity)
		
		entity_set_int(id, EV_INT_gaitsequence, 6)
	}
	return PLUGIN_CONTINUE
}

public fw_traceline(Float:vecStart[3],Float:vecEnd[3],ignoreM,id,trace) 
{
	if(!is_user_connected(id))
		return;
	
	new hit = get_tr2(trace, TR_pHit);
	
	if(!is_user_connected(hit))
		return;
	
	new hitzone = get_tr2(trace, TR_iHitgroup);
	if((informacje_przedmiotu_gracza[hit][0] == 49 && hitzone == HIT_HEAD) || informacje_przedmiotu_gracza[hit][0] == 50 && hitzone != HIT_HEAD)
		set_tr2(trace, TR_iHitgroup, 8);
}

public WygranaTerro()
	WygranaRunda("TERRORIST");

public WygranaCT()
	WygranaRunda("CT");

public WygranaRunda(const Team[])
{
	new Players[32], playerCount, id;
	get_players(Players, playerCount, "aeh", Team);
	
	if(get_playersnum() < 3)
		return;
	
	for (new i=0; i<playerCount; i++) 
	{
		id = Players[i];
		if(!klasa_gracza[id] && !is_user_connected(id))
			continue;
		
		doswiadczenie_gracza[id] += doswiadczenie_za_wygrana;
		ColorChat(id, RED, "[COD]^x01 Dostales %i doswiadczenia za wygrana runde.", doswiadczenie_za_wygrana);
		SprawdzPoziom(id);
	}
}

public OddajPrzedmiot(id)
{
	new menu = menu_create("Oddaj przedmiot", "OddajPrzedmiot_Handle");
	new cb = menu_makecallback("OddajPrzedmiot_Callback");
	new numer_przedmiotu;
	for(new i=0; i<=32; i++)
	{
		if(!is_user_connected(i))
			continue;
		oddaj_id[numer_przedmiotu++] = i;
		menu_additem(menu, nazwa_gracza[i], "0", 0, cb);
	}
	menu_display(id, menu);
}

public OddajPrzedmiot_Handle(id, menu, item)
{
	if(item < 1 || item > 32) return PLUGIN_CONTINUE;
	
	if(!is_user_connected(oddaj_id[item]))
	{
		client_print(id, print_chat, "Nie odnaleziono rzadanego gracza.");
		return PLUGIN_CONTINUE;
	}
	if(dostal_przedmiot[id])
	{
		client_print(id, print_chat, "Musisz poczekac 1 runde.");
		return PLUGIN_CONTINUE;
	}
	if(!informacje_przedmiotu_gracza[id][0])
	{
		client_print(id, print_chat, "Nie masz zadnego przedmiotu.");
		return PLUGIN_CONTINUE;
	}
	if(informacje_przedmiotu_gracza[oddaj_id[item]][0])
	{
		client_print(id, print_chat, "Ten gracz ma juz przedmiot.");
		return PLUGIN_CONTINUE;
	}
	dostal_przedmiot[oddaj_id[item]] = true;
	DajPrzedmiot(oddaj_id[item], informacje_przedmiotu_gracza[id][0]);
	informacje_przedmiotu_gracza[oddaj_id[item]][1] = informacje_przedmiotu_gracza[id][1];
	client_print(id, print_chat, "Przekazales %s graczowi %s.",nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]] , nazwa_gracza[oddaj_id[item]]);
	client_print(oddaj_id[item], print_chat, "Dostales %s od gracza %s.",nazwy_przedmiotow[informacje_przedmiotu_gracza[id][0]] , nazwa_gracza[id]);
	UsunPrzedmiot(id);
	return PLUGIN_CONTINUE;
}

public OddajPrzedmiot_Callback(id, menu, item)
{
	if(oddaj_id[item] == id)
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}

public MagnetThink(ent)
{
	if(entity_get_int(ent, EV_INT_iuser2))
		return PLUGIN_CONTINUE;
	
	if(!entity_get_int(ent, EV_INT_iuser1))
		emit_sound(ent, CHAN_VOICE, "weapons/mine_activate.wav", 0.5, ATTN_NORM, 0, PITCH_NORM );
	
	entity_set_int(ent, EV_INT_iuser1, 1);
	
	new id = entity_get_edict(ent, EV_ENT_owner);
	new dist = get_pcvar_num(pcvar_zasieg)+inteligencja_gracza[id];
	
	new Float:forigin[3];
	entity_get_vector(ent, EV_VEC_origin, forigin);
	
	new entlist[33];
	new numfound = find_sphere_class(0,"player", float(dist),entlist, 32,forigin);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
		
		if (get_user_team(pid) == get_user_team(id))
			continue;
		
		if (is_user_alive(pid))
		{
			new bronie_gracza = entity_get_int(pid, EV_INT_weapons);
			for(new n=1; n <= 32;n++)
			{
				if(1<<n & bronie_gracza)
				{
					new weaponname[33];
					get_weaponname(n, weaponname, 32);
					engclient_cmd(pid, "drop", weaponname);
				}
			}
		}
	}
	
	numfound = find_sphere_class(0,"weaponbox", float(dist)+100.0,entlist, 32,forigin);
	
	for (new i=0; i < numfound; i++)
		if(get_entity_distance(ent, entlist[i]) > 50.0)
		set_velocity_to_origin(entlist[i], forigin, 999.0);
	
	if (entity_get_float(ent, EV_FL_ltime) < halflife_time() || !is_user_alive(id))
	{
		entity_set_int(ent, EV_INT_iuser2, 1);
		return PLUGIN_CONTINUE;
	}
	
	new iOrigin[3];
	FVecIVec(forigin, iOrigin);
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, iOrigin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( iOrigin[0] );
	write_coord( iOrigin[1] );
	write_coord( iOrigin[2] );
	write_coord( iOrigin[0] );
	write_coord( iOrigin[1] + dist );
	write_coord( iOrigin[2] + dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 0 ); // r, g, b
	write_byte( 100 );// r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( get_pcvar_num(pcvar_widocznosc_fali) ); // brightness
	write_byte( 0 ); // speed
	message_end();
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01);
	
	return PLUGIN_CONTINUE;
}

public ResetHUD(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	client_disconnect_magnet(id);
	pozostale_elektromagnesy[id] = get_pcvar_num(pcvar_ilosc_elektromagnesow);
	return PLUGIN_HANDLED
}

public client_disconnect_magnet(id)
{
	new ent = find_ent_by_class(0, "magnet");
	while(ent > 0)
	{
		if(entity_get_edict(id, EV_ENT_owner) == id)
			remove_entity(ent);
		ent = find_ent_by_class(ent, "magnet");
	}
}

public NowaRunda_magnet()
{
	new ent = find_ent_by_class(-1, "magnet");
	while(ent > 0) 
	{
		remove_entity(ent);
		ent = find_ent_by_class(ent, "magnet");	
	}
}

stock get_velocity_to_origin( ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3] )
{
	new Float:fEntOrigin[3];
	entity_get_vector( ent, EV_VEC_origin, fEntOrigin );
	
	// Velocity = Distance / Time
	
	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0];
	fDistance[1] = fEntOrigin[1] - fOrigin[1];
	fDistance[2] = fEntOrigin[2] - fOrigin[2];
	
	new Float:fTime = -( vector_distance( fEntOrigin,fOrigin ) / fSpeed );
	
	fVelocity[0] = fDistance[0] / fTime;
	fVelocity[1] = fDistance[1] / fTime;
	fVelocity[2] = fDistance[2] / fTime + 50.0;
	
	return ( fVelocity[0] && fVelocity[1] && fVelocity[2] );
}

stock set_velocity_to_origin( ent, Float:fOrigin[3], Float:fSpeed )
{
	new Float:fVelocity[3];
	get_velocity_to_origin( ent, fOrigin, fSpeed, fVelocity )
	
	entity_set_vector( ent, EV_VEC_velocity, fVelocity );
	
	return ( 1 );
} 

public radar_scan()
{	
	new PlayerCoords[3];
	
	new players[32],count;
	get_players(players,count)
	for (new i = 1; i <= count; i++)
	{
		new id = players[i];
		
		if(!is_user_alive(id) || !is_user_connected(id) || informacje_przedmiotu_gracza[id][0] != 86)
			return PLUGIN_HANDLED;
		
		if(!is_user_alive(i) || get_user_team(i) == get_user_team(id)) 
			
		get_user_origin(i, PlayerCoords)
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgHostageAdd, {0,0,0}, id)
		write_byte(id)
		write_byte(i)           
		write_coord(PlayerCoords[0])
		write_coord(PlayerCoords[1])
		write_coord(PlayerCoords[2])
		message_end()
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgHostageDel, {0,0,0}, id)
		write_byte(i)
		message_end()
	}
	return PLUGIN_HANDLED;
}

public cmdKill()
	return FMRES_SUPERCEDE;

stock fm_create_ent(id, ent, szName[], szModel[], iSolid, iMovetype, Float:fOrigin[3])
{
	if(!pev_valid(ent))
		return;
	
	set_pev(ent, pev_classname, szName)
	engfunc(EngFunc_SetModel, ent, szModel)
	set_pev(ent, pev_solid, iSolid)
	set_pev(ent, pev_movetype, iMovetype)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_origin, fOrigin)
}

stock Float:estimate_take_hurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent )
		return 1.0
	return 0.6
}

public plugin_natives()
{
	register_native("cod_set_user_xp", "UstawDoswiadczenie", 1);
	register_native("cod_get_user_xp", "PobierzDoswiadczenie", 1);
	register_native("cod_get_user_health", "PobierzZdrowieMax", 1);
}

public UstawDoswiadczenie(id, wartosc)
{
	doswiadczenie_gracza[id] = wartosc;
	SprawdzPoziom(id);
}

public PobierzDoswiadczenie(id)
	return doswiadczenie_gracza[id];

public PobierzZdrowieMax(id)
	return maksymalne_zdrowie_gracza[id];

/* --==[ VIP ] ==-- */
public event_CurWeapon_Vip(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if (!get_pcvar_num(g_vip_active))
		return PLUGIN_CONTINUE
	
	if(read_data(2) == CSW_SG550)
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H))
		{
			client_print(id, print_center, "AutoKampa 'SG550' tylko dla VIPow!")
			client_cmd(id, "drop")
		}
	}
	else if(read_data(2) == CSW_G3SG1)
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H))
		{
			client_print(id, print_center, "AutoKampa 'G3SG1' tylko dla VIPow!")
			client_cmd(id, "drop")
		}
	}
	else if(read_data(2) == CSW_M249)
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H))
		{
			client_print(id, print_center, "Bron 'M249 Para' tylko dla VIPow")
			client_cmd(id, "drop")
		}
	}
	return PLUGIN_HANDLED
}

public on_damage(id)
{
	new attacker = get_user_attacker(id)
	if ( is_user_connected(id) && is_user_connected(attacker) )
		if (get_user_flags(attacker) & ADMIN_LEVEL_H)
	{
		new damage = read_data(2)
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", damage)
	}
}


public Damage2(id)
{
	new weapon, hitpoint, attacker = get_user_attacker(id,weapon,hitpoint)
	if(attacker<=maxplayers && is_user_alive(attacker) && attacker!=id)
		if (is_user_connected(attacker) && get_user_flags(attacker) & ADMIN_LEVEL_H) 
	{
		new money = read_data(2) * get_pcvar_num(mpd)
		if(hitpoint==1) money += get_pcvar_num(mhb)
		cs_set_user_money(attacker,cs_get_user_money(attacker) + money)
	}
}
public HandleCmd(id){
	if (!get_pcvar_num(g_vip_active))
		return PLUGIN_CONTINUE
	if(get_user_flags(id) & ADMIN_LEVEL_H) 
		return PLUGIN_CONTINUE
	client_print(id, print_center, "Niektore bronie sa tylko dla VIPow!")
	return PLUGIN_HANDLED
}

public Showrod(id) {
	show_menu(id, Keysrod, "\rVIP Menu^n\d1. \wWez \yM4A1+Deagle ^n\d2. \wWez \yAK47+Deagle^n^n\d0. Wyjscie^n", -1, "rod") // Display menu
}
public Pressedrod(id, key) {
	/* Menu:
	* VIP Menu
	* 1. Wez M4A1 + Deagle
	* 2. Wez AK47+Deagle
	* 0. Exit
	*/
	switch (key) {
		case 0: { 
			if (user_has_weapon(id, CSW_C4) && get_user_team(id) == 1)
				HasC4[id] = true;
			else
				HasC4[id] = false;
			
			fm_strip_user_weapons (id)
			fm_give_item(id,"weapon_m4a1")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"weapon_deagle")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"weapon_knife")
			if(get_user_flags(id) & ADMIN_RCON)
			{
				fm_give_item(id, "weapon_hegrenade");
				fm_give_item(id, "weapon_flashbang");
				fm_give_item(id, "weapon_flashbang");
				fm_give_item(id, "weapon_smokegrenade");
				client_print(id, print_center, "Otrzymales M4A1, Deagle, HE, Smoke i 2x Flesh!")
			}
			else
			{
				fm_give_item(id, "weapon_hegrenade");
			}
			fm_give_item(id, "item_assaultsuit");
			fm_give_item(id, "item_thighpack");
			client_print(id, print_center, "Wziales M4A1, Deagle i HE!")
			
			if (HasC4[id])
			{
				fm_give_item(id, "weapon_c4");
				cs_set_user_plant( id );
			}
		}
		case 1: { 
			if (user_has_weapon(id, CSW_C4) && get_user_team(id) == 1)
				HasC4[id] = true;
			else
				HasC4[id] = false;
			
			fm_strip_user_weapons (id)
			fm_give_item(id,"weapon_ak47")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"weapon_deagle")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"weapon_knife")
			if(get_user_flags(id) & ADMIN_RCON)
			{
				fm_give_item(id, "weapon_hegrenade");
				fm_give_item(id, "weapon_flashbang");
				fm_give_item(id, "weapon_flashbang");
				fm_give_item(id, "weapon_smokegrenade");
				client_print(id, print_center, "Wziales AK47, Deagle, HE")
			}
			else
			{
				fm_give_item(id, "weapon_hegrenade");
				client_print(id, print_center, "Otrzymales AK47, Deagle i HE!")
			}
			fm_give_item(id, "item_assaultsuit");
			fm_give_item(id, "item_thighpack");
			
			if (HasC4[id])
			{
				fm_give_item(id, "weapon_c4");
				cs_set_user_plant( id );
			}
		}
		case 9: {
			// 0
			client_print(id, print_center, "Otrzymales Granaty!")
		}
	}
	return PLUGIN_CONTINUE
}

public Round_Reset()
{
	round = 0;
}

public hook_death()
{
	// Killer id
	nKiller = read_data(1)
	
	if(!is_user_connected(nKiller))
		return;
	
	if ( (read_data(3) == 1) && (read_data(5) == 0) )
	{
		nHp_add = get_pcvar_num (health_hs_add)
	}
	else
		nHp_add = get_pcvar_num (health_add)
	nHp_max = get_pcvar_num (health_max)
	// Updating Killer HP
	if(!(get_user_flags(nKiller) & ADMIN_LEVEL_H))
		return;
	
	nKiller_hp = get_user_health(nKiller)
	nKiller_hp += nHp_add
	// Maximum HP check
	if (nKiller_hp > nHp_max) nKiller_hp = nHp_max
	fm_set_user_health(nKiller, nKiller_hp)
	// Hud message "Healed +15/+30 hp"
	set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 1.0, 1.0, 0.1, 0.1, -1)
	show_hudmessage(nKiller, "Healed +%d hp", nHp_add)
	// Screen fading
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, nKiller)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0x0000)
	write_byte(0)
	write_byte(0)
	write_byte(200)
	write_byte(75)
	message_end()
	
}

public handle_say(id) {
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/vips") != -1 )
		set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE
}

public print_adminlist(user) 
{
	new adminnames[33][32]
	new message[192]
	new contactinfo[112], contact[64]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
		if(get_user_flags(id) & ADMIN_LEVEL_H)
		get_user_name(id, adminnames[count++], 31)
	
	len = format(message, 191, "%s VIP'y ONLINE: ",COLOR)
	if(count > 0) 
	{
		for(x = 0 ; x < count ; x++) 
		{
			len += format(message[len], 191-len, "%s%s%s ", COLOR, adminnames[x], x < (count-1) ? "^x01, ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 191, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 191-len, "Brak Vip'ow Online")
		print_message(user, message)
	}
	
	get_cvar_string("amx_contactinfo", contact, 63)
	if(contact[0])  {
		format(contactinfo, 111, "%s Kontakt z Adminem -- %s", COLOR, contact)
		print_message(user, contactinfo)
	}
	return PLUGIN_HANDLED;
}

print_message(id, msg[]) {
	if(!is_user_connected(id))
		return;
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public ShowMotd(id)
{
	show_motd(id, "vip.txt")
}

public KomendaDajPrzedmiot(id, level, cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;
	
	new arg1[33];
	new arg2[6];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 5);
	new gracz  = cmd_target(id, arg1, 0);
	new przedmiot = str_to_num(arg2)-1;
	
	if(przedmiot < 1 || przedmiot > sizeof nazwy_przedmiotow-1)
	{
		client_print(id, print_console, "Podales nieprawidlowy numer przedmiotu.")
		return PLUGIN_HANDLED;
	}
	
	DajPrzedmiot(gracz, przedmiot);
	return PLUGIN_HANDLED;
}

public cmd_addlvl(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[4];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 3);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new lvl = str_to_num(arg2);
	if(poziom_gracza[player] + lvl > MAXLVL) {
		client_print(id, print_console, "[COD] Chciales dodac za duzo lvli (lvlgracza + wartosc < %i)", MAXLVL)
		} else {
		doswiadczenie_gracza[player] = doswiadczenie_poziomu[poziom_gracza[player] + lvl-1];
		SprawdzPoziom(player);
	}
	return PLUGIN_HANDLED;
}
public cmd_remlvl(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[4];
	read_argv(1, arg1, 32);
	read_argv(2, arg2, 3);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new lvl = str_to_num(arg2);
	if(poziom_gracza[player] - lvl < 1) 
		{
		client_print(id, print_console, "[COD] Chciales usunac za duzo lvli (lvlgracza - wartosc > 1)")
		} 
	else 
	{
		doswiadczenie_gracza[player] = doswiadczenie_poziomu[poziom_gracza[player] - lvl-1];
		poziom_gracza[player] = 0;
		SprawdzPoziom(player);
	}
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
