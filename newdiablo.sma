/* ================================================================================================ /
*	data  22,04.2012 //////////////////////////////////////////////////////////////////////////////
/ ================================================================================================= */

new Basepath[128]	//Path from Cstrike base directory

#include <amxmodx>
#include <amxmisc>

#include <engine>
#include <fakemeta> 
#include <csx>
#include <cstrike>

#include <fun>
#include <fakemeta_util>
#include <sqlx>
#include <colorchat> 
#include <hamsandwich> 
#include <nvault>
#include <nvault_util>
#include <xs>
#include <chr_engine>

#pragma tabsize 0
#define MAX 32			 //Max number of valid player entities

#define TE_BEAMFOLLOW               22
#define CS_PLAYER_HEIGHT 72.0
#define GLOBAL_COOLDOWN 0.5
#define TASK_GREET 240
#define TASK_HUD 120
#define	TASK_ENTANGLEWAIT	928	
#define GLUTON 95841
#define ILE_KLAS 25

//niesmiertelnosc
#define TASK_GOD 129

#define BALL_CLASSNAME "displacer_ball"
#define BEAM_CLASSNAME "dispball_beam"
#define BALL_CLASS "displacer"

//new weapon, clip, ammo
#define x 0
#define y 1
#define z 2
//hook
#define TASK_HOOK 360

#define TASK_CHARGE 100
#define TASK_FLASH_LIGHT 81184

//upadek z wysokosci
#define FALL_VELOCITY 350.0

#define TASKID_REVIVE 	1337
#define TASKID_RESPAWN 	1338
#define TASKID_CHECKRE 	1339
#define TASKID_CHECKST 	13310
#define TASKID_ORIGIN 	13311
#define TASKID_SETUSER 	13312
#define TASK_POCISKI_BIO 	1374
#define klawisze (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
#define message_begin_f(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)

#define pev_zorigin	pev_fuser4
#define seconds(%1) ((1<<12) * (%1))
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)

#define OFFSET_CAN_LONGJUMP    356

#define MAX_FLASH 15		//pojemnosc barejii maga (sekund)
#define ile_zablokuj 1

//pulapki z granatow
#define NADE_VELOCITY	EV_INT_iuser1
#define NADE_ACTIVE	EV_INT_iuser2	
#define NADE_TEAM	EV_INT_iuser3	
#define NADE_PAUSE	EV_INT_iuser4

#define FL_ONGROUND (1<<9) 

// The sizes of model

new SOUND_START[] 	= "items/medshot4.wav"
new SOUND_FINISHED[] 	= "items/smallmedkit2.wav"
new SOUND_FAILED[] 	= "items/medshotno1.wav"
new SOUND_EQUIP[]	= "items/ammopickup2.wav"

enum
{
ICON_HIDE = 0,
ICON_SHOW,
ICON_FLASH
}

#define SERVER_IP		"91.203.133.251:27060" // testowka
new g_haskit[MAX+1]
new Float:g_revive_delay[MAX+1]
new Float:g_body_origin[MAX+1][3]
new bool:g_wasducking[MAX+1]

new g_msg_bartime
new g_msg_screenfade
new g_msg_statusicon
new g_msg_clcorpse


new cvar_revival_time
new cvar_revival_health
new cvar_revival_dis
new wait1[33]


new attacker
new flashlight[33]
new flashbattery[33]
new flashlight_r
new flashlight_g
new flashlight_b
//hook
new hooked[33]

new planter
new defuser

// max clip
stock const maxClip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20,
10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

// max bpammo
stock const maxAmmo[31] = { -1, 52, -1, 90, -1, 32, -1, 100, 90, -1, 120, 100, 100, 90, 90, 90, 100, 100,
30, 120, 200, 32, 90, 120, 60, -1, 35, 90, 90, -1, 100 };

new gmsgDeathMsg
new gmsgStatusText
new gmsgBartimer
new gmsgScoreInfo
new gmsgHealth

new bool:freeze_ended
new c4state[33]
new c4bombc[33][3] 
new c4fake[33]
new fired[33],maxfired[33]

new sprite_blood_drop = 0
new BlueFlare,bake,sprite_blast
new sprite_blood_spray = 0
new sprite_gibs = 0
new sprite_white = 0
new sprite_fire = 0
new sprite_beam = 0
new sprite_boom = 0
new sprite_line = 0
new sprite_lgt = 0
new sprite_ignite = 0
new sprite_smoke = 0
new sprite_smoke1 = 0
new player_xp[33] = 0		//Holds players experience
new player_lvl[33] = 1			//Holds players level
new player_point[33] = 0	
new player_item_id[33] = 0	//Items id
new player_krysztal[33] 
new player_item_name[33][128]   //The items name
new player_intelligence[33]
new player_strength[33]
new player_grawitacja[33]
new player_witalnosc[33]
new player_agility[33]
new Float:player_damreduction[33]
new player_dextery[33]
new player_zloto[33]
new player_artefakt[33]
new player_wytrzymalosc[33]
new player_class[33]		
new Float:player_huddelay[33]
new ilerazysip[33],ilerazy1[33]
new trybroz[33]
new wczytalo[33]
new naswietlony[33]
new czasmaga[33],brak_strzal[33]
//////////////misje///////////////
//ze starego diablo
new quest_gracza[33];
new ile_juz[33];
new ile_wykonano[33];
new quest_wyk[33];
new questy_akt[33];
new uzyl_mikstury[33] = 0
new c_damage[33]
new c_vampire[33]
new c_shake[33]
new c_darksteel[33]
new c_silent[33]
new c_heal[33]	//ile hp co 3 sek.
new c_mine[33]
new c_dmgandariel[33]	//dodatkowe dmg andariel

//info o klasie i lvl w sayu
new pCvarPrefixy;

new bool:asysta_gracza[MAX+1][MAX+1];

new maksymalne_zdrowie_gracza[33];
//pulapki z granatow
new g_TrapMode[33]
new g_GrenadeTrap[33] = {0, ... }
new cvar_throw_vel = 90 // def: 90
new cvar_activate_dis = 175 // def 190
new cvar_nade_vel = 280 //def 280
new Float: cvar_explode_delay = 0.5 // def 0.50
new map_end = 0

//anty!!!
new c_antyarchy[33]
new c_antymeek[33]
new c_antyorb[33]
new c_antygrenade[33]

new c_bestia[33]	//moc bestii

new niewidka[33]

#define TE_BEAMENTPOINT 1
#define TE_KILLBEAM 99
#define DELTA_T 0.1				// seconds
#define BEAMLIFE 100			// deciseconds
#define MOVEACCELERATION 150	// units per second^2
#define REELSPEED 300			// units per second

/* Hook Stuff */
new gHookLocation[33][3]
new gHookLenght[33]
new bool:gIsHooked[33]
new gAllowedHook[33]
new Float:gBeamIsCreated[33]
new global_gravity
new beam


new SyncHudObj2;
//mana
new mana_gracza[33]
new player_m_antyarchy[33]
new player_m_antymeek[33]
new player_m_antyorb[33]
new player_m_antyfs[33]
new player_m_antyflesh[33]

new mana_staty[][]={
	{8,100},
	{20,200},
	{40,300},
	{70,400}
}

new zloto_gracza[33]

//Pomocnicy
new pomocnik_player[33]
enum { NONE = 0, Lotrzyca, PustynnyZuk, ZelaznyWilk, Barbarzynca_p}
new Pomocnik_txt[5][] = { "None", "Lotrzyca", "Pustynny Zuk", "Zelazny Wilk", "Barbarzynca"}
new anty_flesh[33]

//Pas i Mikstury
new ile_slotow[33]
new slot_pasa[33]
new m_leczenia[33]
new m_wzmocnienia[33]

//misje
new SOUND_DIABLO[][]={
	//Akt I
	"misc/fsf654.wav",
	"misc/dhhrdh.wav",
	"misc/re5fd4.wav",
	"misc/wre15.wav",
	"misc/5384.wav",
	"misc/5s86.wav",
	//Akt II
	"misc/57815.wav",
	"misc/s5a56.wav",
	"misc/24ds.wav",
	"misc/521.wav",
	"misc/175s8.wav",
	"misc/w4867d.wav",
	//Akt III
	"misc/ad456.wav",
	"misc/d857.wav",
	"misc/4178.wav",
	"misc/f745.wav",
	"misc/s4w2.wav",
	"misc/7658w.wav",
	//Akt IV
	"misc/2018.wav",
	"misc/45s35.wav",
	"misc/4763.wav",
	//Akt V
	"misc/r74y.wav",
	"misc/p3o2.wav",
	"misc/ewc4.wav",
	"misc/2ws56.wav",
	"misc/er325.wav",
	"misc/9f5dq8.wav",
	//INNE
	"misc/fdssf.wav", //item_wyrzuc 
	"misc/asd234.wav",//item_zniszcz
	"misc/lvlup.wav"//lvl up
}

//przedzial , ile ,kogo , nagroda expa, vip 1 tak 0 nie
new questy[][]={
	{1,10,0},
	{1,1,0},
	{1,1,1},
	{1,1,0},
	{1,1,1},
	{1,1,0},
	{2,1,0},
	{2,3,1},
	{2,30,0},
	{2,1,0},
	{2,1,1},
	{2,1,0},
	{3,1,1},
	{3,1,1},
	{3,4,1},
	{3,1,1},
	{3,4,0},
	{3,1,0},
	{4,1,0},
	{4,1,1},
	{4,1,0},
	{5,1,0},
	{5,15,2},
	{5,1,2},
	{5,1,1},
	{5,3,3},
	{5,1,1}
}

new vault_questy;
new vault_questy2;
new vault_pas;
new vault_mana;

//od , do, akt
new prze[][]={
	{"I"},
	{"II"},
	{"III"},
	{"IV"},
	{"V"}
}

new const q_info_podp1[][]={
	//Akt I
	"Zabij",
	"Znajdz",
	"Uratuj",
	"Pokonaj",
	"Przetrwaj"
}

new prze_wybrany[33]
		
//				q_info_zadanie[0]					q_info_cel[1]								q_info_zlecenio[2]				q_info_nagroda[3]																					q_info_podp[4]												q_info_podp2lp[5]					q_info_podp2lm[6]
new const q_info[27][7][]={																																																																									
	//Akt I																																																																									
	{ "Siedlisko Zla", 				"Zabij wszystkie potwory w Siedlisku Zla",					"Akara",				"2 dodatkowe punkty umiejetnosci",											"Potwory to: Imp, Cien, Duriel, UpadlyPaladyn,^nWladcagromow, Bestia, Szaman, Khazra",		"Potwora",							"Potwory"},
	{ "Cmentarz Siostr", 			"Znajdz i zabij Krwawa Orlice na Cmentarzu",				"Kashya",				"Otrzymujesz 100 Many",														"Szansa, ze napotkasz Krwawa Orlice wynosi 14%",											"Krwawa Orlice",					"Potworow"/*wykorzystanie tablicy*/},
	{ "W poszukiwaniu Caina", 		"Znajdz Zwoj Inifussa i uratuj Caina",						"Akara",				"25 do wytrzymalosci itemu",												"Znajdz Zwoj Inifussa wsrod itemow",														"Zwoj Inifussa",					"Demonow"/*ykorzystanie tablicy*/},
	{ "Zapomniana Wieza", 			"Znajdz i zabij Hrabine",									"Splesniala Ksiega",	"Otrzymujesz 3000 zlota",													"Szansa, ze napotkasz Hrabine wynosi 10%",													"Krwawa Hrabine",					""},
	{ "Narzedzia Pracy", 			"Odnajdz Mallusa Horadrimow w Koszarach Klasztoru",			"Charsi",				"Zadajesz o 2 wiecej obrazen",												"Znajdz Mallus Horadrimow wsrod itemow",													"Mallus Horadrimow",				""},
	{ "Siostry Rzezi", 				"Zabij Andariel w Katakumbach Klasztoru",					"Deckard Cain",			"Mozliwosc przejscia do Aktu II oraz otrzymujesz 15000 exp'a",				"Andariel ma ponad 30 level^nSzansa, ze napotkasz Andariel wynosi 5%",						"Andariel",							""},
	//Akt II																																																																														
	{ "Siedziba Radamenta", 		"Znajdz i zabij Radamenta w kanalach pod miastem",			"Atma",					"2 dodatkowe punkty umiejetnosci",											"Szansa, ze napotkasz Radamenta wynosi 8%",													"Radamenta",						""},
	{ "Laska Horadrimow", 			"Znajdz wszystkie czesci Laski Horadrimow",					"Deckard Cain",			"300 Many i 5000 exp'a",													"Szansa, ze znajdziesz Artefakt przy zwlokach wynosi 6%",									"Artefakt",							"Artefakty"},
	{ "Splamione Slonce", 			"Zniszcz oltarz w Swiatyni Zmijoszponow",					"Drognan",				"Otrzymujesz o 2 mniej obrazen",											"Demony to: Andariel, Baal, Mefisto,^nDiablo, Azmodan, Belial, Izual, Duriel",				"Demona",							"Demony"},
	{ "Tajemne Sanktuarium",		"Znajdz i zabij Demonologa",								"Drognan",				"Otrzymujesz 3000 zlota i 10000 exp'a",										"Szansa, ze napotkasz Demonologa wynosi 5%",												"Demonologa",						""},
	{ "Demonolog",					"Znajdz i przeczytaj Dziennik Horazona",					"Drognan",				"Zwieksza ci sie przyrost gotowki co runde",								"Znajdz Dziennik Horazona wsrod itemow",													"Dziennik Horazona",				""},
	{ "Siedem Grobowcow", 			"Zabij Duriela",											"Deckard Cain",			"Mozliwosc przejscia do Aktu III oraz otrzymujesz 30000 exp'a",				"Duriel ma ponad 50 level^nSzansa, ze napotkasz Duriela wynosi 3%",							"Duriela",							""},
	//Akt III																																																																														
	{ "Zloty Ptak", 				"Znajdz Jadeitowa Figurke",									"Deckard Cain",			"Zwieksznie zdrowia o 10",													"Znajdz Jadeitowa Figurke wsrod itemow",													"Jadeitowa Figurke",				""},
	{ "Ostrze Dawnej Religii", 		"Znajdz Gidbina w Dzungli Lupierzcow",						"Hratli",				"Zolty pierscien (10 wiecej zlota za zabujstwo) oraz 400 Many",							"Znajdz Gidbina wsrod itemow",																"Gidbina",							""},
	{ "Wola Khalima", 				"Odtworz Wole Khalima, ktora rozbijesz Kule Zniewolenia",	"Deckard Cain",			"Zadajesz o 3 wiecej obrazen",												"Szansa, ze znajdziesz Artefakt przy zwlokach wynosi 6%",									"Artefakt",							"Artefakty"},
	{ "Ksiega Lam Esena", 			"Znajdz ksiege Lam Esana",									"Alkor",				"2 dodatkowe punkty umiejetnosci",											"Znajdz ksiege Lam Esena wsrod itemow",														"Lam Esena",						""},
	{ "Poczerniala Swiatynia", 		"Zabij Wysoka Rade w Travincal",							"Ormus",				"Zadajesz o 3 wiecej obrazen jezeli trafiasz wroga od tylu",				"Szansa, ze napotkasz Przedstawiciela Wysokiej Rady wynosi 3%",								"Przedstawiciela Wysokiej Rady",	"Przedstawicieli Wysokiej Rady"},
	{ "Straznik", 					"Znajdz i zabij Mefista",									"Ormus",				"Mozliwosc przejscia do aktu IV oraz otrzymujesz 60000 exp'a",				"Mefisto ma ponad 65 level^nSzansa, ze napotkasz Mefista wynosi 2%",						"Mefista",							""},
	//Akt IV																																																																														
	{ "Upadly Aniol", 				"Znajdz i zabij Izuala",									"Tyrael",				"2 dodatkowe punkty umiejetnosci",											"Szansa, ze napotkasz Izuala wynosi 3%",													"Izuala",							""},
	{ "Piekielna Kuznia", 			"Zniszcz kamien duszy Mefist",								"Deckard Cain",			"10000 zlota i 500 many",													"Znajdz Mlot Kowala Hefasto wsrod itemow",													"Mlot Kowala Hefasto",				""},
	{ "Koniec Grozy", 				"Znajdz i zabij Diablo",									"Tyrael",				"Mozliwosc przejscia do aktu V oraz otrzymujesz 90000 exp'a",				"Diablo ma ponad 80 level^nSzansa, ze napotkasz Diablo wynosi 1%",							"Diablo",							""},
	//Akt V																																																																															
	{ "Powstrzymac Oblezenie", 		"Znajdz i zabij Shenka Nadzorce",							"Larzuk",				"25 do wytrzymalosci itemu",												"Szansa, ze napotkasz Shenka Nadzorce wynosi 1%",											"Shenka Nadzorce",					""},
	{ "Ratunek na Gorze Arreat", 	"Odnajdz i uratuj 15 uwiezionych Barbarzyncow",				"Qual-Kehk",			"Otrzymujesz 1 Skok co runde",												"Szansa, ze uratujesz uwiezionego Barbarzynce wynosi 5%",									"uwiezionego Barbarzynce",			"uwiezionych Barbarzyncow"},
	{ "Lodowe Wiezienie", 			"Odnajdz i uratuj z lodowego wiezienia Anye",				"Malah",				"Otrzymujesz o 3 mniej obrazen",											"Szansa, ze uratujesz Anye wynosi 0,8%",													"Anye",								""},
	{ "Zdrada w Harrogath",			"Zabij Nihlathaka",											"Anya",					"Zwieksznie zdrowia o 20",													"Szansa, ze napotkasz Nihlathaka wynosi 0,7%",												"Nihlathaka",						""},
	{ "Rytual Przejscia", 			"Pokonaj 3 Starozytnych",									"Qual-Kehk",			"Otrzymujesz 15000 zlota, 120000 exp'a",									"Starozytni maja ponad 95 level^nSzansa, ze napotkasz Starozytnego wynosi 1%",				"Starozytnego",						"Starozytnych"},
	{ "Wigilja Zniszczenia",		"Zabij Slugi Baala i Zabij Baala",							"Starozytni",			"Otrzymujesz 250000 exp'a, Swiety Pancerz Tyraela(200 Armoru) i 1000 many",	"Baal ma ponad 110 level^nSzansa, ze napotkasz Baala wynosi 0,5%",							"Baala",							""}
};
//koniec starego diablo
///////////////////////////////////////
new artefakt_info[][]={"Nic",
"Runiczne Berlo", //1
"Obuwie Maga", //2
"Iglicowy Helm", //3
"Cienista Kolczuga", //4
"Magiczna Sakwa", //5
"Niebianski Kamien", //6
"Fortuna Gheeda", //7
"Uzdrowienie Manalda", //8
"Buty Bezpieczenstwa", //9
"Myrmidonskie Nagolennice", //10
"Kolczuga", //11
"Swiete Pioro", //12
"Oslona Natury", //13
"Zdobywcze Rekawice", //14
"Szpony", //15
"Siewca Zaglady", //16
"Cichy Zabojca", //17
"Totemiczna Maska", //18
"Berlo Szamana", //19
"Szafir" //20
}
new n_moc_nozowa[33];
new n_krwawynaboj[33];	//krwawy naboj cienia
//Item attributes
new player_b_vampire[33] = 1	//Vampyric damage
new player_b_windwalk[33] = 1	//Ability to windwalk away
new player_b_usingwind[33] = 1	//Is player using windwalk
new player_b_killhp[33] = 1		//hp za killa
new player_b_invknife[33] = 1	//niewidzialnosc z nozem
new player_b_antyhs[33] = 1		//anty headshoot
new player_b_sidla[33] = 1	//1/x na unieruchomienie wroga
new player_b_fleshujtotem[33] = 1	//totem flashujacy
new player_b_mine[33] = 1	//Ability to lay down mines
new player_b_latarka[33] = 1	//latarka maga
new player_b_hook[33] = 1	//Ability to grap a player a hook him towards you
new Float:player_b_exp[33] = 1.0 //dodatkowy exp
new player_b_dajawp[33]=1
new player_b_dajak[33]=1 
new player_b_dajm4[33]=1 
new player_b_dajsg[33]=1
new player_b_dajaug[33]=1
new wear_sun[33] = 1			//anty flash
new player_b_weapontotem[33] = 1	//daje bron
new player_b_kasatotem[33] = 1			//daje kase
new player_b_extrastats[33] = 1	//Ability to gain extra stats
new player_b_godmode[33] = 1    // niesmiertelnosc
new player_b_ghost[33] = 1
new player_b_grenade[33]
new player_b_damage[33] = 1	//Bonus damage
new player_b_money[33] = 1	//Money bonus
new player_b_gravity[33] = 1	//Gravity bonus : 1 = best
new player_b_redbull[33] = 1	//super bonus gravitacji
new player_b_4move[33] = 1		//cichy bieg + dodatkowa szybkosc
new player_b_inv[33] = 1		//Invisibility bonus
new player_b_theif[33] = 1	//Amount of money to steal
new player_b_respawn[33] = 1	//Chance to respawn upon death
new player_b_explode[33] = 1	//Radius to explode upon death
new player_b_heal[33] = 1	//Ammount of hp to heal each 5 second
new player_b_blind[33] = 1	//Chance 1/Value to blind the enemy
new player_b_fireshield[33] = 1	//Protects against explode and grenade bonus 
new player_b_meekstone[33] = 1	//Ability to lay a fake c4 and detonate 
new player_b_zamroz[33] = 1
new player_b_grawi[33] = 1
new player_b_blink[33] = 1
new player_b_smierc[33] = 1
new player_b_smierc2[33] = 1
new player_b_redirect[33] = 1	//How much damage will the player redirect 
new player_b_fireball[33] = 1	//Ability to shot off a fireball value = radius
new player_b_blindtotem[33] = 1	//Ability to get a railgun
new player_b_froglegs[33] = 1	//Ability to hold down duck for 4 sec to frog-jump
new player_b_silent[33]	= 1	//Is player silent
new player_b_sniper[33] = 1	//Ability to kill in 1/sniper with scout
new player_b_masterele[33] = 1 //Ability to kill in 1/sniper with mp5 prad
new player_b_knife[33] = 1 //Ability to kill in 1/sniper with knife
new player_b_awp[33] = 1 //Ability to kill in 1/sniper with awp
new player_b_jumpx[33] = 1	//Ability to double jump
new player_b_firetotem[33] = 1	//Ability to put down a fire totem that explodes after 7 seconds
new player_b_darksteel[33] = 1	//Ability to damage double from behind the target 	
new player_b_kusza[33] = 1 
new player_b_odepch[33] = 1
new player_b_buty[33] = 1		//dodatkowe longjumpy?
new player_b_startaddhp[33] = 1
new skinchanged[33]	//Information about last disconnected players item
new player_sword[33] 		//nowyitem
new totemstop[33],zatakowany[33]
new mamvipa[33]
new power_bolt[33]
/////////////////////////////////////////////////////////////////////
new player_ultra_armor[33]
new player_ultra_armor_left[33]
/////////////////////////////////////////////////////////////////////

new bool:player_b_dagfired[33]	//Fired dagoon?
new bool:used_item[33] 
new bool:used_item1[33] 
new bool:otwarte_menu[33] 
new user_controllsem[33]
new c_blink[33]
new jumps[33]			//Keeps charge with the number of jumps the user has made
new bool:dojump[33]		//Are we jumping?
new item_boosted[33]		//Has this user boosted his item?
new earthstomp[33]
new bool:falling[33]
new gravitytimer[33]
new item_durability[33]	//Durability of hold item
new CTSkins[4][]={"sas","gsg9","urban","gign"}
new TSkins[4][]={"arctic","leet","guerilla","terror"}
new KNIFE_VIEW[] 	= "models/v_knife.mdl"
new KNIFE_PLAYER[] 	= "models/p_knife.mdl"
new ElectroSpr,burning

new cbow_VIEW[]  = "models/diablomod/v_crossbow.mdl" 
new cvow_PLAYER[]= "models/diablomod/p_crossbow.mdl" 
new cbow_bolt[]  = "models/diablomod/Crossbow_bolt.mdl"

new JumpsLeft[33]
new JumpsMax[33]

new loaded_xp[33]
new asked_sql[33]
new asked_klass[33]
new olny_one_time=0

enum { NONE = 0, Mag, Mnich, Paladyn, Nekromanta, Barbarzynca, Zabojca, Ninja, Hunter, Tyrael, Imp, Cien, Duch, Bestia, Szaman, Khazra, Baal, Diablo, Andariel, Mefisto, Izual, Nihlathak, Griswold, Kowal}
new Race[24][24] = { "None","Mag","Mnich","Paladyn","Nekromanta","Barbarzynca", "Zabojca", "Ninja", "Amazonka", "Tyrael", "Imp", "Cien", "Duch", "Bestia","Szaman", "Khazra", "Baal", "Diablo", "Andariel","Mefisto", "Izual","Nihlathak","GrisWold", "Kowal Dusz"}
new race_heal[24] = { 130,110,120,130,110,125,150,175,120,120,120,110,110,120,120,110,110,120,115,125,130,115,120,110}

new const LevelXP[] = {
0,12,48,108,192,300,432,588,768,972,//10
1200,1452,1728,2028,2352,2700,3072,3468,3888,4332,//20
4860,5415,6000,6615,7260,7935,8640,9375,10140,10935,//30
12000,13230,14520,15870,17280,18750,20280,21870,23520,25230,//40
28224,30276,32400,34596,36864,39204,41616,44100,46656,49284,//50 normal x 12
51450,54432,57498,60648,63882,67200,70602,74088,77658,81312,//60 normal x14
84672,88752,92928,97200,101568,106032,110592,115248,120000,124848,//70 normal x16
129654,135000,140454,146016,151686,157464,163350,169344,175446,181656,//80 normal x18
188160,194940,201840,208860,216000,223260,230640,238140,245760,253500,//90 normal x20
261954,270336,278850,287496,296274,305184,314226,323400,332706,342144,//100 normal x22
348100,360000,372100,384400,396900,409600,422500,435600,448900,462400,//110 slow x 20
476100,490000,504100,518400,532900,547600,562500,577600,592900,608400,//120 slow x 20
612500,630125,648000,666125,684500,703125,722000,741125,760500,780125,//130 slowx25
800000,820125,840500,861125,882000,903125,924500,946125,968000,990125,//140 slowx25
1012500,1035125,1058000,1081125,1104500,1128125,1152000,1176125,1200500,1225125,//150 slowx25
1242150,1269600,1297350,1325400,1353750,1382400,1411350,1440600,1470150,1500000,//160 slowx30
1530150,1560600,1591350,1622400,1653750,1685400,1717350,1749600,1782150,1815000,//170 slowx30
1848150,1881600,1915350,1949400,1983750,2018400,2053350,2088600,2124150,2160000,//180 slowx30
2196150,2232600,2269350,2306400,2343750,2381400,2419350,2457600,2496150,2535000,//190 slowx30
2574150,2613600,2653350,2693400,2733750,2774400,2815350,2856600,2898150,2940000,//200 slowx30
9999999999}
new const GildiaXP[11] = {
0,35000,85000,160000,290000,490000,620000,890000,1300000,1800000,99999999
}

new player_class_lvl[33][ILE_KLAS]

new player_xp_old[33]

new database_user_created[33]

new srv_avg[ILE_KLAS] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

//For Hook and powerup sy
new Float:player_global_cooldown[33]

//For optimization
new last_update_xp[33]
new Float:last_update_perc[33]
#define ICON_HIDE 0 
#define ICON_SHOW 1
#define ICON_FLASH 2 
#define ICON_S "suithelmet_full"

//Flags a user can have
enum
{
Flag_Ignite = 0,
Flag_Hooking,
Flag_Rot,
Flag_Dazed,
Flag_Moneyshield,
num_of_flags
}


//Flags
new afflicted[33][num_of_flags]
//noze

new max_knife[33]
new player_knife[33]
new Float:tossdelay[33]

//lLegionista

new Float:bowdelay[33]
new bow[33]
new button[33]

new Float:g_PreThinkDelay[33]


new Float:gfBlockSizeMin1[3]= {-32.0,-4.0,-32.0};
new Float:gfBlockSizeMax1[3]= { 32.0, 4.0, 32.0};
new Float:vAngles1[3] = {90.0,90.0,0.0}

new Float:gfBlockSizeMin2[3]= {-4.0,-32.0,-32.0}
new Float:gfBlockSizeMax2[3]= { 4.0, 32.0, 32.0}
new Float:vAngles2[3] = {90.0,0.0,0.0}


new casting[33]
new Float:cast_end[33]
new on_knife[33]
new golden_bulet[33]
new ultra_armor[33]
new after_bullet[33]
new num_shild[33]
new invisible_cast[33]
new c_theif[33]
new c_blind[33]
new c_redirect[33]
new c_respawn[33]
new c_piorun[33], poprzednie_uzycie[33];
new c_jump[33]
new c_odpornosc[33]
new c_lecz[33]
/* do artefaktow */
new g_vault,g_vault2
new player_password[33][128],dobre_haslo[33]
new password[33]
new nazwa[33]
new wpisane_haslo[33]
new gBindItem[33]
///bony artefaktow///
new Float:a_noz[33]
new a_spid[33]
new a_silent[33]
new a_jump[33]
new a_money[33]
new a_inv[33]
new a_wearsun[33]
new a_heal[33]
///// misje /////
new g_healspr,
laser
;
new SPRITE_PLASMA[] = "sprites/plasma.spr"
new SPRITE_RING[] = "sprites/displacer_ring.spr"
new SPRITE_PORTAL[] = "sprites/exit1.spr"
new m_Plasma,m_DispRing,m_ExitPortal

//////////////////gildie
new g_gildia,g_gil_spr,g_wplaty
new nazwa_gildi[33][128],nazwa_zalozycial[33][128],gildia_lvl[33],gildia_exp[33],ilosc_czlonkow[33];
new oddaj_id[33]
new oddaj_name[33][128]
new g_dmg[33],g_def[33],g_hp[33],g_spid[33],g_pkt[33],g_kam[33],g_drop[33],g_woj[128]
new zapamietaj_name[33][128],wplata[33]
////////////////////////dmg
new g_hudmsg1, g_hudmsg2
////////////////Bounce
new ent[33]
new P_MODEL[] = "models/p_gauss.mdl"
new V_MODEL[] = "models/v_gauss.mdl"
new g_model[] = "models/test.mdl"

new makul[33]
new mod_k[33]
new tryb[33]

/* PLUGIN CORE REDIRECTING TO FUNCTIONS ========================================================== */


// SQL //

new Handle:g_SqlTuple

new g_sqlTable[64] = "dbmod_tables"
new g_boolsqlOK=0


// SQL //


public plugin_init()
{

register_cvar("diablo_sql_host","localhost",FCVAR_PROTECTED)
register_cvar("diablo_sql_user","root",FCVAR_PROTECTED)
register_cvar("diablo_sql_pass","root",FCVAR_PROTECTED)
register_cvar("diablo_sql_database","dbmod",FCVAR_PROTECTED)
register_cvar("diablo_sql_save","0",FCVAR_PROTECTED)	// 0 - nick

register_cvar("diablo_sql_table","dbmod_tablet",FCVAR_PROTECTED)


register_cvar("diablo_avg", "1")	

cvar_revival_time 	= register_cvar("amx_revkit_time", 	"3")
cvar_revival_health	= register_cvar("amx_revkit_health", 	"25")
cvar_revival_dis 	= register_cvar("amx_revkit_distance", 	"70.0")

g_msg_bartime	= get_user_msgid("BarTime")
g_msg_clcorpse	= get_user_msgid("ClCorpse")
g_msg_screenfade= get_user_msgid("ScreenFade")
g_msg_statusicon= get_user_msgid("StatusIcon")

register_message(g_msg_clcorpse, "message_clcorpse")

register_event("HLTV", 		"event_hltv", 	"a", "1=0", "2=0")
register_event("ScreenFade","det_fade","be","1!0","2!0","7!0")

register_forward(FM_Touch, 		"fw_Touch")
register_forward(FM_EmitSound, 		"fwd_emitsound")
register_forward(FM_PlayerPostThink, 	"fwd_playerpostthink")
register_forward(FM_PlayerPreThink, "PreThink");


register_plugin("diabloMod","5.9i PL","Miczu & GuTeK") 

register_cvar("diablomod_version","5.9i PL",FCVAR_SERVER)

g_vault = nvault_open("Haslo")
g_vault2 = nvault_open("kamien")
g_gildia = nvault_open("Gildie")
g_gil_spr = nvault_open("nickgil")
g_wplaty = nvault_open("wpllata")

register_cvar("flashlight_custom","1");
register_cvar("flashlight_drain","1.0");
register_cvar("flashlight_charge","0.5");
register_cvar("flashlight_radius","8");
register_cvar("flashlight_decay","90");
register_event("Flashlight","event_flashlight","b");

RegisterHam(Ham_TakeDamage, "player","fwTakeDamage",0);
//asysta
RegisterHam(Ham_TakeDamage, "player", "fwdamage",1);
RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);

register_event("CurWeapon","CurWeapon","be", "1=1")
register_event("ResetHUD", "ResetHUD", "abe")
register_event("DeathMsg","DeathMsg","ade") 
//asysta
register_event("DeathMsg", "kiled", "a");
register_event("SendAudio","freeze_over","b","2=%!MRAD_GO","2=%!MRAD_MOVEOUT","2=%!MRAD_LETSGO","2=%!MRAD_LOCKNLOAD")
register_event("SendAudio","freeze_begin","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")  
register_event("SendAudio", "WygrywaTT", "a", "2&%!MRAD_terwin");
register_event("SendAudio", "WygrywaCT", "a", "2&%!MRAD_ctwin");

register_event("SendAudio", "award_defuse", "a", "2&%!MRAD_BOMBDEF")  	
register_event("BarTime", "bomb_defusing", "be", "1=10", "1=5")
register_event("Damage", "Damage", "b", "2!0")

register_touch("Mine", "player",  "DotykMiny");
register_concmd("kladzmine","item_mine");
	register_clcmd("+piorun", "piorun");
register_think("grenade", "think_Grenade");
register_think("think_bot", "think_Bot");
_create_ThinkBot();
register_event("ResetHUD", "ResetHUD2", "b");

	register_clcmd("+hook", "hook_on")
	register_clcmd("-hook", "hook_off")
//	register_clcmd("mocbestia","bestiaon") 
	register_clcmd("+predator","predator1") 
	register_clcmd("+kula","kula1") 
//	register_clcmd("+duch","duch_ghost") 
	register_clcmd("+inferno","item_ogienflara") 
	
	register_clcmd("say /komendy","komendy_info")
	register_clcmd("say komendy","komendy_info")
	
	
register_logevent("award_plant", 3, "2=Planted_The_Bomb");	
register_logevent("rescueHostage", 3, "1=triggered", "2=Rescued_A_Hostage");
register_event("StatusIcon", "got_bomb", "be", "1=1", "1=2", "2=c4")

register_logevent("logevent_host", 3, "1=triggered");
register_event("TextMsg","host_killed","b","2&#Killed_Hostage") 
register_event("TextMsg", "freeze_begin", "a", "2=#Game_will_restart_in")
register_clcmd("say drop","dropitem") 
register_clcmd("say /drop","dropitem") 
register_clcmd("say /d","dropitem")
register_clcmd("say /dropartefakt","dropa_menu")
register_clcmd("say /przedmiot","iteminfo")
register_clcmd("say artefakt","ainfo")
register_clcmd("say /artefakt","ainfo")
register_clcmd("say /art","ainfo")
register_clcmd("say /item","iteminfo")
register_clcmd("say /i","iteminfo")
register_clcmd("say /p","iteminfo")
register_clcmd("przedmiot","iteminfo")
register_clcmd("/przedmiot","iteminfo")
register_clcmd("say /przedmiot","iteminfo")
register_clcmd("say /pomoc","pomoc")

register_clcmd("say /Vip","vip") 
register_clcmd("say /vip","vip") 
register_clcmd("say /Klasa","changerace")
register_clcmd("say klasa","changerace")
register_clcmd("say /gracze","cmd_who")
register_clcmd("klasa","changerace")
register_clcmd("say /klasa","changerace")
register_clcmd("say /klasy","OpisKlasy")
register_clcmd("say /zmianaklasy","changerace")
register_clcmd("say zmianaklasy","changerace")
register_clcmd("say /czary", "showskills")
register_clcmd("say czary", "showskills")
register_clcmd("say /menu","showmenu") 
register_clcmd("menu","showmenu")
register_clcmd("vip","vip") 
register_clcmd("say /rune","buyrune")
register_clcmd("say /sklep","buyrune")
register_clcmd("/rune","buyrune") 
register_clcmd("rune","buyrune") 	
register_clcmd("/czary","showskills")
register_clcmd("/czary","showskills")
register_clcmd("say /exp", "exp")
register_clcmd("say /czary","showskills")
register_clcmd("say /czary","showskills")
register_clcmd("say /reset","reset_skill")
register_clcmd("reset","reset_skill")	 
register_clcmd("/reset","reset_skill")
register_clcmd("mag","item_fireball")
register_clcmd("ucieczka","ucieczka")
//register_clcmd("sciana","postawsciane")
register_clcmd("fullupdate","fullupdate")

	register_clcmd("say /questy","menu_questow")
	register_clcmd("say /quest","menu_questow")
	register_clcmd("say /q","menu_questow")
	register_clcmd("say /odpornosci", "showdefens")
	register_clcmd("say /odp", "showdefens")
	
	get_cvar_string("diablo_dir",Basepath,127)

register_concmd("wpisz_haslo", "stworz_haslo");
register_concmd("podaj_haslo", "wpisz_haslo1");
register_clcmd("Podaj_nowy_klawisz", "cmdBindKey");
register_concmd("wpisz_nazwe_gildi", "stworz_gildie_n");
register_clcmd("wprowadz_ilosc_expa","iDodaj")
register_clcmd("wprowadz_krysztal","iDodaj1")

register_menucmd(register_menuid("statystyki"), 1023, "skill_menu")
register_menucmd(register_menuid("Opcje"), 1023, "option_menu")
register_menucmd(register_menuid("Bohaterowie"), klawisze, "select_class_menu1")
register_menucmd(register_menuid("Potwory"), klawisze, "PressedKlasy")
register_menucmd(register_menuid("Demony"), klawisze, "select_class_menu3")
register_menucmd(register_menuid("ustawienia"), 1023, "ustawienia_menu")

gmsgDeathMsg = get_user_msgid("DeathMsg")
gmsgStatusText = get_user_msgid("StatusText")
gmsgBartimer = get_user_msgid("BarTime") 
gmsgScoreInfo = get_user_msgid("ScoreInfo") 

register_cvar("diablo_dmg_exp","20",0)
register_cvar("diablo_xpbonus","20",0)
register_cvar("diablo_xpbonus2","50",0)
register_cvar("diablo_durability","4",0) 
register_cvar("SaveXP", "1")
register_cvar("diablo_winxp", "10",0);

set_msg_block ( gmsgDeathMsg, BLOCK_SET ) 
set_task(3.0, "Timed_Healing", 0, "", 0, "b")
set_task(20.0, "check_drop", 0, "", 0, "b")
set_task(0.8, "UpdateHUD",0,"",0,"b")
set_task(1.0, "say_hud", 0, _, _, "b");

set_task(30.0, "Pomoc");

register_think("HealBot", "HealBotThink");
    CreateHealBot();

register_think("PowerUp","Think_PowerUp")
register_think("Effect_Rot","Effect_Rot_Think")
register_logevent("RoundStart", 2, "0=World triggered", "1=Round_Start")
register_clcmd("amx_giveexp","CmdGiveExp",ADMIN_IMMUNITY,"Uzycie amx_givezloto <nick>")
register_clcmd("amx_givezloto","CmdGivezloto",ADMIN_IMMUNITY,"Uzycie amx_givemana <nick>")
register_clcmd("amx_givemana","CmdGivemana",ADMIN_IMMUNITY,"Uzycie amx_giveexp <nick>")
register_clcmd("amx_giveitem",  "giveitem",ADMIN_IMMUNITY, "Uzycie <amx_giveitem NICK idITemku")
register_clcmd("amx_givea",  "giveartefakt",ADMIN_IMMUNITY, "Uzycie <amx_givea NICK idITemku")
register_clcmd("amx_givekam","CmdGiveKamien",ADMIN_IMMUNITY,"Uzycie amx_givek <nick>")
register_clcmd("amx_givegil","CmdGiveGil",ADMIN_IMMUNITY,"Uzycie amx_givegil <nick>")
register_clcmd("say", "cmd_say", 0, "<target> ");

register_think("Effect_Ignite_Totem", "Effect_Ignite_Totem_Think")
register_think("Effect_Ignite", "Effect_Ignite_Think")
register_think("Effect_Slow","Effect_Slow_Think")
register_think("Effect_Timedflag","Effect_Timedflag_Think")
register_think("Effect_MShield","Effect_MShield_Think")
register_think("Effect_Healing_Totem","Effect_Healing_Totem_Think")
register_think("Effect_Healing1_Totem","Effect_Healing1_Totem_Think")
register_think("Effect_Zamroz_Totem","Effect_Zamroz_Totem_Think")
register_think("Effect_Grawi_Totem","Effect_Grawi_Totem_Think")
register_think("Effect_2012_Totem","Effect_2012_Totem_Think")
register_think("Effect_Krz_Totem","Effect_Krz_Totem_Think")
register_think("Effect_Ode_Totem","Effect_Ode_Totem_Think")
register_think("Effect_Smie_Totem","Effect_Smie_Totem_Think")
register_think("Effect_Lus_Totem","Effect_Lus_Totem_Think")
register_think("Effect_Pra_Totem","Effect_Pra_Totem_Think")
register_think(BALL_CLASSNAME, "DispBall_Think");
register_think(BEAM_CLASSNAME, "DispBeam_Think");
register_touch(BALL_CLASSNAME, "*", "DispBall_Explode_Touch");
register_touch("predator_ent", "*", "touchedpredator");

register_event("Health", "Health", "be", "1!255")
register_cvar("diablo_show_health","1")
gmsgHealth = get_user_msgid("Health") 


register_touch("throwing_knife", "player", "touchKnife")
register_touch("throwing_knife", "worldspawn",		"touchWorld")
register_touch("throwing_knife", "func_wall",		"touchWorld")
register_touch("throwing_knife", "func_door",		"touchWorld")
register_touch("throwing_knife", "func_door_rotating",	"touchWorld")
register_touch("throwing_knife", "func_wall_toggle",	"touchWorld")
register_touch("throwing_knife", "dbmod_shild",		"touchWorld")

register_touch("throwing_knife", "func_breakable",	"touchbreakable")
register_touch("func_breakable", "throwing_knife",	"touchbreakable")

register_cvar("diablo_knife_speed","1000")

register_touch("xbow_arrow", "player", 			"toucharrow")
register_touch("xbow_arrow", "worldspawn",		"touchWorld2")
register_touch("xbow_arrow", "func_wall",		"touchWorld2")
register_touch("xbow_arrow", "func_door",		"touchWorld2")
register_touch("xbow_arrow", "func_door_rotating",	"touchWorld2")
register_touch("xbow_arrow", "func_wall_toggle",	"touchWorld2")
register_touch("xbow_arrow", "dbmod_shild",		"touchWorld2")

register_touch("xbow_arrow", "func_breakable",		"touchbreakable")
register_touch("func_breakable", "xbow_arrow",		"touchbreakable")

register_cvar("diablo_arrow","120.0")
register_cvar("diablo_arrow_multi","2.0")
register_cvar("diablo_arrow_speed","1800")

register_forward(FM_TraceLine,"fw_traceline");

g_hudmsg1 = CreateHudSyncObj()	
g_hudmsg2 = CreateHudSyncObj()

set_task(1.0, "sql_start");
	
	//vaulty
	vault_questy = nvault_open("Questy");
	vault_questy2 = nvault_open("Questy2");
	vault_pas = nvault_open("Pas");
	vault_mana = nvault_open("Mana")
	
	SyncHudObj2 = CreateHudSyncObj();
	
	
	//info w sayu
	register_message(get_user_msgid("SayText"),"handleSayText");
	pCvarPrefixy	=	register_cvar("cod_prefix","3");
	
	//kasa totem i weapon totem
	register_think("Effect_Kasa_Totem","Effect_Kasa_Totem_Think")
	register_think("Effect_Weapons_Totem","Effect_Weapons_Totem_Think")
	
	//flash totem
	register_think("Effect_Fleshuj_Totem","Effect_Fleshuj_Totem_Think")
	register_concmd("fleszuj","Flesh")

return PLUGIN_CONTINUE  
}

public say_hud(){
	new tpstring[251]
	for (new id=0; id < 32; id++) {
		if (!is_user_connected(id))
			continue
		if(quest_gracza[id] >= 0 && player_class[id] != NONE) {
			if((quest_gracza[id]==0 || quest_gracza[id]==8) && questy[quest_gracza[id]][1]-ile_juz[id] >4) {
				if(quest_gracza[id]==0)
					format(tpstring,250,"Quest: %s - %s %d %s", q_info[quest_gracza[id]][0], q_info_podp1[questy[quest_gracza[id]][2]], questy[quest_gracza[id]][1]-ile_juz[id],q_info[1][6])
				else
					format(tpstring,250,"Quest: %s - %s %d %s", q_info[quest_gracza[id]][0], q_info_podp1[questy[quest_gracza[id]][2]], questy[quest_gracza[id]][1]-ile_juz[id],q_info[2][6])
			}
			else
				format(tpstring,250,"Quest: %s - %s %d %s", q_info[quest_gracza[id]][0], q_info_podp1[questy[quest_gracza[id]][2]], questy[quest_gracza[id]][1]-ile_juz[id],questy[quest_gracza[id]][1]-ile_juz[id]-1?q_info[quest_gracza[id]][6]:q_info[quest_gracza[id]][5])	
		}
		else format(tpstring,250,"Quest: Brak")		
		message_begin(MSG_ONE,gmsgStatusText,{0,0,0}, id) 
		write_byte(0) 
		write_string(tpstring) 
		message_end()
		
	}
}

public menu_questow(id){
	
	if (player_class[id] != NONE) {
		wczytaj_questa(id)
		quest_gracza[id] = wczytaj_aktualny_quest(id);
		if(quest_gracza[id] == -1 || quest_gracza[id] == -2){
			
			new menu = menu_create("Menu Questow","menu_questow_handle")
			new menu_fun =menu_makecallback("mcbmenu_questow");
			new formats[128]
			for(new i = 0;i<sizeof prze;i++){
				formatex(formats,127,"\yAKT %s", prze[i][0]);
				
				menu_additem(menu,formats,"",0,menu_fun);
			}
			menu_display(id,menu,0)
		}
		else
		{
			new formats2[301]
			formatex(formats2,300,"\y[ \r%s \y]^n^n\dCel zadania: %s^nZleceniodawca: %s^nNagroda: %s^n^n\w%s^n^n\r0.\yWyjscie", q_info[quest_wyk[id]][0], q_info[quest_wyk[id]][1], q_info[quest_wyk[id]][2], q_info[quest_wyk[id]][3],q_info[quest_wyk[id]][4]);
			show_menu(id, MENU_KEY_0, formats2, -1, "quest_info") 
		}
	}
	else 
		client_print(id,print_chat,"Wybierz klase aby zaczac zadanie!");
}

public mcbmenu_questow(id, menu, item){
	if(item==1 && !(ile_wykonano[id] >= 6))
		return ITEM_DISABLED
	if(item==2 && !(ile_wykonano[id] >= 12))
		return ITEM_DISABLED
	if(item==3 && !(ile_wykonano[id] >= 18))
		return ITEM_DISABLED
	if(item==4 && !(ile_wykonano[id] >= 21))
		return ITEM_DISABLED
	return ITEM_ENABLED;
}

public menu_questow_handle(id,menu,item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new formats[128]
	formatex(formats,127,"AKT %s",prze[item][0]);
	questy_akt[id]= item;
	new menu2 = menu_create(formats,"menu_questow_handle2")
	new menu2_fun=menu_makecallback("mcbmenu_questow_handle2");
	for(new i = 0;i<sizeof(questy);i++){
		if(questy[i][0] == item+1){
			formatex(formats,127,"\y%s \d[ %s ]", q_info[i][0], q_info[i][1]);
			menu_additem(menu2,formats,"",0, menu2_fun)
		}
	}
	menu_setprop(menu2, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu2, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu2, MPROP_NEXTNAME, "Nastepna strona");
	prze_wybrany[id] = item+1;
	menu_display(id,menu2)
	return PLUGIN_CONTINUE;
}

public mcbmenu_questow_handle2(id, menu, item){
	if(item<=(ile_wykonano[id] - questy_akt[id]*6))
		return ITEM_ENABLED;
	return ITEM_DISABLED
}

public zapisz_aktualny_quest(id){
	
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"questy-%d-%s",player_class[id],name);
	new data[32]
	formatex(data,charsmax(data),"#%d#%d",quest_gracza[id]+1,ile_juz[id]);
	nvault_set(vault_questy2,key,data);
}

public wczytaj_aktualny_quest(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"questy-%d-%s",player_class[id], name);
	new data[32];
	nvault_get(vault_questy2,key,data,31);
	replace_all(data,31,"#"," ");
	new questt[32],ile[32]
	parse(data,questt,31,ile,31)
	ile_juz[id] = str_to_num(ile)
	quest_wyk[id] = str_to_num(questt)-1
	return str_to_num(questt)-1
}

public zapisz_questa(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"questy-%d-%s",player_class[id],name);
	new data[32]
	formatex(data,charsmax(data),"#%d",ile_wykonano[id]);
	nvault_set(vault_questy,key,data);
}

public wczytaj_questa(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"questy-%d-%s",player_class[id], name);
	new data[32];
	nvault_get(vault_questy,key,data,31);
	replace_all(data,31,"#"," ");
	new wykonano[32]
	parse(data,wykonano,31)
	ile_wykonano[id] = str_to_num(wykonano)
}

public menu_questow_handle2(id,menu,item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new ile2 = 0;
	for(new i = 0;i<sizeof(questy);i++){
		if(questy[i][0] != prze_wybrany[id]){
			continue;
		}
		if(ile2 == item){
			item = i;
			break;
		}
		ile2++;
	}
	
	new item2 = ile_wykonano[id]
	if(ile_wykonano[id]>21)
		item2-=3
	if(item<item2) {
		client_print(id,print_chat,"Wykonales juz to zadanie!");
		menu_questow(id)
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	quest_gracza[id] = item;
	ile_juz[id] = 0
	zapisz_aktualny_quest(id)
	new formats[301]
	formatex(formats,300,"\y[ \r%s \y] ^n^n\dCel zadania: %s^nZleceniodawca: %s^nNagroda: %s^n^n\w%s^n^n\r0.\yWyjscie", q_info[item][0], q_info[item][1], q_info[item][2], q_info[item][3],q_info[item][4]);
	show_menu(id, MENU_KEY_0, formats, -1, "quest_info") 
	
	quest_gracza[id] = wczytaj_aktualny_quest(id);
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public questy_nagrody(kid){
	client_cmd(kid,"spk %s",SOUND_DIABLO[quest_gracza[kid]]) 
	ile_wykonano[kid]++
	zapisz_questa(kid)
	switch(quest_gracza[kid]){
		//Akt I
		case 0:{
			player_point[kid]+=2
		}
		case 1:{
			mana_gracza[kid]+=100
			zapisz_mane(kid)
		}
		case 3:{
			zloto_gracza[kid]+=3000
		}
		case 4:{
			c_damage[kid]+=2
		}
		case 5:{
			Give_Xp(kid,15000)
		}
		//Akt II
		case 6:{
			player_point[kid]+=2
		}
		case 7:{
			mana_gracza[kid]+=300
			zapisz_mane(kid)
			Give_Xp(kid,5000)
		}
		case 8:{
			c_redirect[kid]+=2
		}
		case 9:{
			zloto_gracza[kid]+=3000
			Give_Xp(kid,10000)
		}
		case 11:{
			Give_Xp(kid,30000)
		}
		//Akt III
		case 12:{
			set_user_health(kid, get_user_health(kid) + 10)
		}
		case 13: {
			mana_gracza[kid]+=400
			zapisz_mane(kid)
		}
		case 14:{
			c_damage[kid]+=3
		}
		case 15:{
			player_point[kid]+=2
		}
		case 16:{
			c_darksteel[kid]+=3
		}
		case 17:{
			Give_Xp(kid,60000)
		}
		//Akt IV
		case 18:{
			player_point[kid]+=2
		}
		case 19:{
			zloto_gracza[kid]+=10000
			mana_gracza[kid]+=500
			zapisz_mane(kid)
		}
		case 20:{
			ile_wykonano[kid]+=3
			Give_Xp(kid,90000)
		}
		//Akt V
		case 26:{
			c_redirect[kid]+=3
		}
		case 27:{
			set_user_health(kid, get_user_health(kid) + 20)
		}
		case 28:{
			zloto_gracza[kid]+=15000
			Give_Xp(kid,120000)
		}
		case 29:{
			mana_gracza[kid]+=1000
			zapisz_mane(kid)
			set_user_armor(kid, 200)
			Give_Xp(kid,250000)
		}
	}	
	quest_gracza[kid] = -1;
	zapisz_aktualny_quest(kid)
	zapisz_questa(kid)
	set_hudmessage(60, 200, 25, -1.0, 0.7, 0, 1.0, 4.0, 2.0, 1.8, 3)
	show_hudmessage(kid, "Wykonales zadanie: %s gratulacje!^nW nagrode otrzymujesz: %s!",q_info[quest_gracza[kid]][0],q_info[quest_gracza[kid]][3])
}

public uzyj_mLeczenia(id){

	if(uzyl_mikstury[id] == 1)
		ColorChat(id, RED, "Mikstury mozesz uzyc co kazde 30 sek!")
	else if(m_leczenia[id] && player_item_id[id]!=17){
		--slot_pasa[id]
		--m_leczenia[id]
		new dhp = get_user_health(id) + 50
		if(dhp>race_heal[player_class[id]]+player_strength[id]*2) {
			set_user_health(id, race_heal[player_class[id]]+player_strength[id]*2)
			ColorChat(id, RED, "Mikstura odnowila Ci maxymalnie Hp!")
			zapisz_pas(id)
			uzyl_mikstury[id] = 1;
			set_task(30.0, "reset_mikstura", id)
		}
		else {
			set_user_health(id, dhp)
			ColorChat(id, RED, "Mikstura odnowila 50 Hp!")
			zapisz_pas(id)
			uzyl_mikstury[id] = 1;
			set_task(30.0, "reset_mikstura", id)
		}
	}
	else
		ColorChat(id, RED, "Nie masz mikstury leczenia lub masz nieodpowiedni przedmiot!")
	return PLUGIN_HANDLED;
}

public uzyj_mWzmocnienia(id){

	if(uzyl_mikstury[id] == 1)
		ColorChat(id, RED, "Mikstury mozesz uzyc co kazde 30 sek!")
	else if(m_wzmocnienia[id] && player_item_id[id]!=17){
		--slot_pasa[id]
		--m_wzmocnienia[id]
		set_user_health(id, race_heal[player_class[id]]+player_strength[id]*2)
		ColorChat(id, RED, "Mikstura odnowila Ci maxymalnie Hp!")
		zapisz_pas(id)
		uzyl_mikstury[id] = 1;
		set_task(30.0, "reset_mikstura", id)
	}
	else
		ColorChat(id, RED, "Nie masz mikstury wzmocnienia lub masz nieodpowiedni przedmiot!")
	return PLUGIN_HANDLED;
}

public pomocnicy(id){
	switch(pomocnik_player[id]){
		case Lotrzyca:
			anty_flesh[id]=1
		case ZelaznyWilk:{
			c_damage[id]+=4
			c_redirect[id]+=2
		}
		case Barbarzynca_p:{
			set_user_health(id, get_user_health(id) + 30)
			c_vampire[id]+=4
			
		}
	}
}

public zapisz_mane(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"m-%d-%s",player_class[id],name);
	new data[32]
	formatex(data,charsmax(data),"#%d#%d#%d#%d#%d#%d", mana_gracza[id], player_m_antyarchy[id], player_m_antymeek[id], player_m_antyorb[id], player_m_antyfs[id], player_m_antyflesh[id] );
	nvault_set(vault_mana,key,data);
}

public wczytaj_mane(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"m-%d-%s",player_class[id], name);
	new data[32];
	nvault_get(vault_mana,key,data,31);
	replace_all(data,31,"#"," ");
	new ile1[32], ile2[32], ile3[32], ile4[32], ile5[32], ile6[32]
	parse(data,ile1,31,ile2,31,ile3,31,ile4,31,ile5,31,ile6,31)
	
	mana_gracza[id] = str_to_num(ile1)
	player_m_antyarchy[id] = str_to_num(ile2)
	player_m_antymeek[id] = str_to_num(ile3)
	player_m_antyorb[id] = str_to_num(ile4)
	player_m_antyfs[id] = str_to_num(ile5)
	player_m_antyflesh[id] = str_to_num(ile6)
	
}

public zapisz_pas(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"pas-%d-%s",player_class[id],name);
	new data[32]
	formatex(data,charsmax(data),"#%i#%i#%i", ile_slotow[id], m_leczenia[id], m_wzmocnienia[id] );
	nvault_set(vault_pas,key,data);
}

public wczytaj_pas(id){
	new name[64];
	get_user_name(id,name,63)
	strtolower(name)
	new key[256];
	format(key,255,"pas-%d-%s",player_class[id], name);
	new data[32];
	nvault_get(vault_pas,key,data,31);
	replace_all(data,31,"#"," ");
	new ile[32], ile2[32], ile3[32]
	parse(data,ile,31,ile2,31,ile3,31)
	if(str_to_num(ile))
		ile_slotow[id] = str_to_num(ile)
	else
		ile_slotow[id] = 1
	m_leczenia[id] = str_to_num(ile2)
	m_wzmocnienia[id] = str_to_num(ile3)
	slot_pasa[id] = m_leczenia[id] + m_wzmocnienia[id]
}

public rescueHostage(){
	new uid, szInfo[64];
	read_logargv(0, szInfo, 63);
	parse_loguser(szInfo, szInfo, 63, uid);
	new id = find_player("k", uid);
	
	if(random_num(0,100)<=5 && quest_gracza[id] == 25) {
		ile_juz[id]++
		zapisz_aktualny_quest(id)
	}
				
	if(ile_juz[id] == questy[quest_gracza[id]][1])
		questy_nagrody(id)
	
}/*

format(q_command,511,"UPDATE `%s` SET `ip`='%s',`sid`='%s',`lvl`='%i',`exp`='%i',`str`='%i',`int`='%i',`dex`='%i',`zlo`='%i',`agi`='%i',`gra`='%i',`wit`='%i',`art`='%i',`wyt`='%i',`zlo2`='%i' WHERE `nick`='%s' AND `klasa`='%i' ",
	g_sqlTable,ip,sid,player_lvl[id],player_xp[id],player_strength[id],
	player_intelligence[id],player_dextery[id],
	player_zloto[id],player_agility[id],player_grawitacja[id],player_witalnosc[id],player_artefakt[id],player_wytrzymalosc[id],zloto_gracza[id],name,player_class[id])
	
	
*/
public sql_start() {
if(g_boolsqlOK) return;

new host[128], user[64], pass[64], database[64];

get_cvar_string("diablo_sql_database", database, 63);
get_cvar_string("diablo_sql_host", host, 127);
get_cvar_string("diablo_sql_user", user, 63);
get_cvar_string("diablo_sql_pass", pass, 63);

g_SqlTuple = SQL_MakeDbTuple(host, user, pass, database);

get_cvar_string("diablo_sql_table", g_sqlTable, 63);

new q_command[512];
formatex(q_command, 511, "CREATE TABLE IF NOT EXISTS `%s` (`nick` VARCHAR(48),`ip` VARCHAR(32),`sid` VARCHAR(32),`klasa` INT(2),`lvl` INT(3) DEFAULT 1,`exp` INT(9) DEFAULT 0,`str` INT(3) DEFAULT 0,`int` INT(3) DEFAULT 0,`dex` INT(3) DEFAULT 0,`zlo` INT(3) DEFAULT 0,`agi` INT(3) DEFAULT 0,`art` INT(3) DEFAULT 0,`wyt` INT(3) DEFAULT 0,`zlo2` INT(3) DEFAULT 0,`gra` INT(3) DEFAULT 0,`wit` INT(3) DEFAULT 0) DEFAULT CHARSET `utf8` COLLATE `utf8_general_ci`", g_sqlTable);

SQL_ThreadQuery(g_SqlTuple, "TableHandle", q_command);
}

public TableHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
if(FailState == TQUERY_CONNECT_FAILED) {
log_to_file("diablo.log", "Could not connect to SQL database.");
return PLUGIN_CONTINUE;
}
if(FailState == TQUERY_QUERY_FAILED) {
log_to_file("diablo.log", "Table Query failed.");
return PLUGIN_CONTINUE;
}
if(Errcode) {
log_to_file("diablo.log", "Error on Table query: %s", Error);
return PLUGIN_CONTINUE;
}

g_boolsqlOK = 1;
log_to_file("diablo.log", "Prawid;lowe polaczenie");

LoadAVG();

return PLUGIN_CONTINUE;
}
public create_klass(id, class) {
if(g_boolsqlOK) {
if(!is_user_bot(id) && !database_user_created[id]) {
	new data[2];
	data[0] = id;
	data[1] = class;
	
	new name[48], ip[32], sid[32], q_command[512];
	
	get_user_name(id, name, 47);
	get_user_ip(id, ip, 31, 1);
	get_user_authid(id, sid, 31);
	
	log_to_file("test_log.log", "*** %s [%s] <%s> *** Create %s ***", name, ip, sid, Race[class]);
	
	replace_all(name, 47, "'", "\'");
	
	formatex(q_command, 511, "INSERT INTO `%s` (`nick`,`ip`,`sid`,`klasa`,`lvl`,`exp`) VALUES ('%s','%s','%s',%i,%i,%i)", g_sqlTable, name, ip, sid, class, srv_avg[class], LevelXP[srv_avg[class]-1]);
	
	SQL_ThreadQuery(g_SqlTuple, "create_klass_handle", q_command, data, 2);
	
	database_user_created[id] = 1;
}
}
else sql_start();
}

public create_klass_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
new id = Data[0];
database_user_created[id] = 0;

if(FailState == TQUERY_CONNECT_FAILED) {
log_to_file("diablo.log", "Could not connect to SQL database.");
return PLUGIN_CONTINUE;
}
if(FailState == TQUERY_QUERY_FAILED) {
log_to_file("diablo.log", "create_klass Query failed.");
return PLUGIN_CONTINUE;
}
if(Errcode) {
log_to_file("diablo.log", "Error on create_klass query: %s", Error);
return PLUGIN_CONTINUE;
}

LoadXP(id, Data[1]);

return PLUGIN_CONTINUE;
}
//sql//

public Health(id) 
{ 
if(get_cvar_num("diablo_show_health")==1)
{
new health = read_data(1) 
if(health>255)
{
	message_begin( MSG_ONE, gmsgHealth, {0,0,0}, id ) 
	write_byte( 255 ) 
	message_end() 
} 
}
}
public plugin_precache()
{
	precache_model("models/rpgrocket.mdl")
	precache_model("models/mine.mdl")
	//hook
	beam = precache_model("sprites/zbeam4.spr")
	precache_sound("weapons/xbow_hit2.wav")

precache_model("addons/amxmodx/diablo/totem_ignite.mdl")
precache_model("addons/amxmodx/diablo/totem_heal.mdl")
precache_model("addons/amxmodx/diablo/w_paczka.mdl")
precache_model("models/s_grenade.mdl");
precache_model(KNIFE_VIEW)     
precache_model(KNIFE_PLAYER)
precache_model(P_MODEL)
precache_model(V_MODEL)
precache_model(g_model)


precache_sound("Ryklwa2.wav");
precache_sound("weapons/xbow_fire1.wav");
precache_sound("weapons/law_shoot1.wav");
precache_sound("diablosound/levelup1_1.wav");
precache_sound("diablosound/levelup1_2.wav");
precache_sound("diablosound/menu.wav");
precache_sound("diablosound/wybierz.wav");
precache_sound("diablosound/wybor.wav");
precache_sound("diablosound/kret.wav");
precache_sound("diablosound/teleport.wav");
precache_sound("diablosound/odrodzenie.wav");
precache_sound("diablosound/speed.wav");
precache_sound("diablosound/hit.wav");
precache_sound("diablosound/spark6.wav");
precache_sound("diablosound/readymoc.wav");
precache_sound("diablosound/korzen.wav");
precache_sound("diablosound/paczka.wav");

ElectroSpr = precache_model("addons/amxmodx/diablo/spark1.spr");
sprite_blood_drop = precache_model("sprites/blood.spr")
sprite_blood_spray = precache_model("sprites/bloodspray.spr")
sprite_ignite = precache_model("addons/amxmodx/diablo/flame.spr")
sprite_smoke = precache_model("sprites/steam1.spr")
sprite_smoke1 = precache_model("sprites/smoke.spr")
sprite_boom = precache_model("sprites/zerogxplode.spr") 
sprite_line = precache_model("sprites/dot.spr")
sprite_lgt = precache_model("sprites/lgtning.spr")
sprite_white = precache_model("sprites/white.spr") 
sprite_fire = precache_model("sprites/explode1.spr") 
sprite_gibs = precache_model("models/hgibs.mdl")
sprite_beam = precache_model("sprites/zbeam4.spr")
bake = precache_model("sprites/agrunt1.spr")
burning = precache_model("sprites/xfire.spr")
m_DispRing = precache_model(SPRITE_RING);
m_Plasma = precache_model(SPRITE_PLASMA);
BlueFlare = precache_model("sprites/blueflare2.spr")
sprite_blast = precache_model("sprites/dexplo.spr");
g_healspr = precache_model("sprites/heal.spr");
laser=precache_model("sprites/laserbeam.spr") 

precache_sound(SOUND_START)
precache_sound(SOUND_FINISHED)
precache_sound(SOUND_FAILED)
precache_sound(SOUND_EQUIP)
precache_sound("diablosound/merial.wav");
precache_sound("weapons/knife_hitwall1.wav")
precache_sound("weapons/knife_hit4.wav")
precache_sound("weapons/knife_deploy1.wav")
precache_model("models/diablomod/w_throwingknife.mdl")
precache_model("models/diablomod/bm_block_platform.mdl")

precache_sound("ambience/siren.wav") // 
precache_sound("ambience/jetflyby1.wav") // 
precache_sound("weapons/mortarhit.wav") // 
precache_sound("weapons/mortar.wav") // 

precache_sound("weapons/mine_charge.wav") // 
precache_sound("weapons/explode4.wav") //
m_ExitPortal = precache_model(SPRITE_PORTAL);

precache_model(cbow_VIEW)
precache_model(cvow_PLAYER)
precache_model(cbow_bolt)

}

public plugin_cfg() {
server_cmd("sv_maxspeed 1600");
}
public savexpcom(id)
{
if(player_class[id]!=0 && player_class_lvl[id][player_class[id]]==player_lvl[id] ) 
{
        SubtractStats(id,player_b_extrastats[id])
        SaveXP(id)
        BoostStats(id,player_b_extrastats[id])
        SaveXP(id)
}
}
stock bool:checkServerIp( szIp[] ){
	new szGetIp[ 64 ];
	
	get_user_ip( 0 , szGetIp , charsmax( szGetIp ) );
	
	return bool:( equal(szIp , szGetIp ) );
}

public SaveXP(id) {
if(g_boolsqlOK) {
if(!is_user_bot(id) && player_xp[id] != player_xp_old[id]) {
	new name[48], ip[32], sid[32], q_command[512];
	
	get_user_name(id, name, 47);
	get_user_ip(id, ip, 31, 1);
	get_user_authid(id, sid, 31);
	
	replace_all(name, 47, "'", "\'");
	
	format(q_command,511,"UPDATE `%s` SET `ip`='%s',`sid`='%s',`lvl`='%i',`exp`='%i',`str`='%i',`int`='%i',`dex`='%i',`zlo`='%i',`agi`='%i',`gra`='%i',`wit`='%i',`art`='%i',`wyt`='%i',`zlo2`='%i' WHERE `nick`='%s' AND `klasa`='%i' ",
	g_sqlTable,ip,sid,player_lvl[id],player_xp[id],player_strength[id],
	player_intelligence[id],player_dextery[id],
	player_zloto[id],player_agility[id],player_grawitacja[id],player_witalnosc[id],player_artefakt[id],player_wytrzymalosc[id],zloto_gracza[id],name,player_class[id])
	
	SQL_ThreadQuery(g_SqlTuple, "Save_xp_handle", q_command);
	
	player_xp_old[id] = player_xp[id];
}
}
else sql_start();
}

public Save_xp_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
if(FailState == TQUERY_CONNECT_FAILED) {
log_to_file("diablo.log", "Could not connect to SQL database.");
return PLUGIN_CONTINUE;
}
if(FailState == TQUERY_QUERY_FAILED) {
log_to_file("diablo.log", "Save_xp Query failed.");
return PLUGIN_CONTINUE;
}
if(Errcode) {
log_to_file("diablo.log", "Error on Save_xp query: %s", Error);
return PLUGIN_CONTINUE;
}

return PLUGIN_CONTINUE;
}
public LoadXP(id, klasa) {
if(is_user_bot(id) || asked_sql[id] || klasa == NONE)
return PLUGIN_HANDLED;

if(g_boolsqlOK) {
	new data[2];
	data[0] = id;
	data[1] = klasa;
	
	new name[48], q_command[512];
	get_user_name(id, name, 47);
	replace_all(name, 47, "'", "\'");
	formatex(q_command, 511, "SELECT * FROM `%s` WHERE `nick`='%s' AND `klasa`='%i'", g_sqlTable, name, klasa);
	
	SQL_ThreadQuery(g_SqlTuple, "Load_xp_handle", q_command, data, 2);
	
	asked_sql[id] = 1;
}
else sql_start();

return PLUGIN_HANDLED;
}


public Load_xp_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
new id = Data[0];
asked_sql[id] = 0;

if(FailState == TQUERY_CONNECT_FAILED) {
	log_to_file("diablo.log", "Could not connect to SQL database.");
	return PLUGIN_CONTINUE;
}
if(FailState == TQUERY_QUERY_FAILED) {
	log_to_file("diablo.log", "Load_xp Query failed.");
	return PLUGIN_CONTINUE;
}
if(Errcode) {
	log_to_file("diablo.log", "Error on Load_xp query: %s", Error);
	return PLUGIN_CONTINUE;
}

new klasa = Data[1];

if(SQL_MoreResults(Query)) 
{
	player_class[id] = klasa;
	player_lvl[id] = player_class_lvl[id][klasa];
	player_xp[id] =	SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "exp"));
	player_xp_old[id] = player_xp[id];
	
	player_intelligence[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"int"))
	player_strength[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"str"))
	player_agility[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"agi"))
	player_dextery[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"dex"))
	player_zloto[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"zlo"))
	player_artefakt[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"art"))
	player_wytrzymalosc[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"wyt"))
	zloto_gracza[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"zlo2"))
	player_grawitacja[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"gra"))
	player_witalnosc[id] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"wit"))
	
	player_point[id]=(player_lvl[id]-1)*2-player_intelligence[id]-player_strength[id]-player_dextery[id]-player_agility[id]-player_zloto[id]-player_grawitacja[id]-player_witalnosc[id]
	if(player_point[id]<0) player_point[id]=0
	player_damreduction[id] = (28.3057*(1.0-floatpower( 2.7182, -0.01750*float(player_agility[id])))/80)
}
else
	create_klass(id, klasa);
	
	return PLUGIN_CONTINUE;
}
public LoadAVG()
{
	if(g_boolsqlOK)
	{
		new data[2]
		data[0]= get_cvar_num("diablo_avg")
		
		if(data[0])
		{
			for(new i=1;i<ILE_KLAS;i++)
			{
				new q_command[512]
				data[1]=i
				//format(q_command,511,"SELECT AVG(`lvl`) FROM `%s` WHERE `lvl` > '%d' AND `klasa`='%d'", g_sqlTable, data[0]-1,i)
				format(q_command,511,"SELECT `klasa`,AVG(`lvl`) AS `AVG` FROM `%s` WHERE `lvl` > '%d' GROUP BY `klasa`", g_sqlTable, data[0]-1)
				SQL_ThreadQuery(g_SqlTuple,"Load_AVG_handle",q_command,data,2)
				
			}
			
		}
	}
	else sql_start()
	return PLUGIN_HANDLED
} 

public Load_AVG_handle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","Error on Load_AVG query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","Could not connect to SQL database.")
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("addons/amxmodx/logs/diablo.log","Load_AVG Query failed.")
		return PLUGIN_CONTINUE
	}
	while(SQL_MoreResults(Query))
	{
		new i = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "klasa"))
		srv_avg[i] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "AVG"))
		SQL_NextRow(Query)
	}
	if(olny_one_time==0)
	{
		olny_one_time=1
		look_for_none()
	}
	return PLUGIN_CONTINUE
}

public look_for_none()
{
	for(new i=1;i<ILE_KLAS;i++)
	{
		if(is_user_alive(i) )
		{
			if(player_class[i]==0)
			{
				select_class_query(i)
			}
		}
	}
}

public reset_skill(id)
{
	new g_player_point
	if(ile_wykonano[id]>=19)
		g_player_point=8
	else if(ile_wykonano[id]>=16)
		g_player_point=6
	else if(ile_wykonano[id]>=7)
		g_player_point=4
	else if(ile_wykonano[id]>=1)
		g_player_point=2
	client_print(id,print_chat,"Reset skill'ow")
	player_point[id] = (player_lvl[id]*2-2)+g_player_point
	player_intelligence[id] = 0
	player_strength[id] = 0 
	player_grawitacja[id] = 0
	player_witalnosc[id] = 0
	player_agility[id] = 0
	player_dextery[id] = 0 
	player_zloto[id] = 0
	BoostStats(id,player_b_extrastats[id])
	
	skilltree(id)
	set_speedchange(id)
	player_damreduction[id] = (28.3057*(1.0-floatpower( 2.7182, -0.01750*float(player_agility[id])))/80)
}


public freeze_over()
{
	set_task(3.0, "freezeover", 3659, "", 0, "")
}
public freezeover()
{
	freeze_ended = true
}
public freeze_begin()
{
	freeze_ended = false
}

public RoundStart()
{
	for (new i=0; i < MAX; i++){
		if(player_class[i] == Khazra){
				changeskin(i,0)
		}
		
		for(new id=1; id<=MAX; id++)
			asysta_gracza[id][i] = false;
		
		give_knife(i)
		RemoveFlag(i,Flag_Rot)
		JumpsLeft[i]=JumpsMax[i]
		
		if(player_class[i] == Nekromanta || player_item_id[i] == 167) g_haskit[i]=1
		else g_haskit[i]=0
		
		//Itemy//
		if(player_b_dajak[i] == 1)
		{
			fm_give_item(i, "weapon_ak47")
			fm_give_item(i, "ammo_762nato")
			fm_give_item(i, "ammo_762nato")
			fm_give_item(i, "ammo_762nato")
		}
		if(player_b_dajm4[i] == 1)
		{
			fm_give_item(i, "weapon_m4a1")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
		}
		if(player_b_dajsg[i] == 1)
		{
			fm_give_item(i, "weapon_sg552")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
		}
		if(player_b_dajaug[i] == 1)
		{
			fm_give_item(i, "weapon_aug")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
			fm_give_item(i, "ammo_556nato")
		}
		if(player_b_dajawp[i] == 1)
		{
			fm_give_item(i,"weapon_awp")
			fm_give_item(i,"ammo_338magnum")
			fm_give_item(i,"ammo_338magnum")
			fm_give_item(i,"ammo_338magnum")
			fm_give_item(i,"ammo_338magnum")
		}
		
		totemstop[i] = 0
		brak_strzal[i] = 0
		zatakowany[i] = 0
		golden_bulet[i]=0
		naswietlony[i] = 0;
		
		invisible_cast[i]=0
		ilerazy1[i]=0
		ilerazysip[i]=0
		power_bolt[i] = 0
		used_item[i] = false
		used_item1[i] = false
		n_moc_nozowa[i] = 0
		c_bestia[i] = 0
		c_dmgandariel[i] = 0
		c_damage[i] = 0
		c_redirect[i] = 0
		c_darksteel[i] = 0
		c_vampire[i] = 0
		
		if(player_artefakt[i] > 0 && wczytalo[i] == 0 && player_xp[i] > 0){
			Sprawdzartefakt(i)
		}
		ikona_mocy(i)
		
		num_shild[i]=4+floatround(player_intelligence[i]/10.0,floatround_floor)
		
		set_renderchange(i)
		
		if(ile_wykonano[i]>=30)
			set_user_armor(i, 200)
		if(ile_wykonano[i]>=11)
			cs_set_user_money(i, cs_get_user_money(i) + random_num(100,300))
		if(pomocnik_player[i])
			pomocnicy(i)
		if(quest_gracza[i] == -1 || quest_gracza[i] == -2 && player_class[i] != NONE)
			menu_questow(i)
			
		if(ile_wykonano[i]>=15)
			c_damage[i]+=5
		else if(ile_wykonano[i]>=5)
			c_damage[i]+=2

		if(ile_wykonano[i]>=27)
			c_redirect[i]+=5
		else if(ile_wykonano[i]>=9)
			c_redirect[i]+=2
		
		if(ile_wykonano[i]>=17)
			c_darksteel[i]+=3
			
		switch(player_class[i])
		{
			case Nekromanta:
			{
				c_vampire[i] += 4;
			}
			case Khazra:
			{
				c_vampire[i] += 4;
			}
			case Griswold:
			{
				c_vampire[i] += 3;
			}
		}
		savexpcom(i)
	}
	
	kill_all_entity("throwing_knife")
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	count_jumps(id)	//longjumpy
	remove_task(TASK_POCISKI_BIO + id);
		
	if(player_zloto[id] > 0)
	cs_set_user_money(id,cs_get_user_money(id)+player_zloto[id]*20)

	if(player_item_id[id] == 16 || player_class[id] == Duriel)
		changeskin(id,0)
	else changeskin(id,1)
	
	switch(player_class[id])
	{
		case Mnich:
		{
			c_piorun[id] = 2
		}
		case Duch:
		{
			c_silent[id] = 1
		}
		case Szaman:
		{
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_flashbang");				
			give_item(id, "weapon_smokegrenade");
		}
		case Khazra:
		{
			c_piorun[id]  = 2
		}
		case Baal:
		{
			give_item(id, "weapon_ak47");
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
		}
		case Diablo:
		{
			c_silent[id] = 1
			set_user_armor(id, 200)
		}
		case Izual:
		{
			c_mine[id] = 3;
		}
	}
	
	wczytaj_pas(id);
	wczytaj_mane(id);
		
	maksymalne_zdrowie_gracza[id] = race_heal[player_class[id]]+player_strength[id]*2;
	startaddhp(id)
	
	if (player_intelligence[id] < 0 || player_strength[id] < 0 || player_agility[id] < 0 || player_dextery[id] < 0 || player_zloto[id] < 0 || player_grawitacja[id] < 0 || player_witalnosc[id] < 0) reset_skill(id)
	
	return PLUGIN_CONTINUE;
}

/* BASIC FUNCTIONS ================================================================================ */
public csw_c44(id)
{
	client_cmd(id,"weapon_knife")
	engclient_cmd(id,"weapon_knife")
	on_knife[id]=1
}

public CurWeapon(id)
{
	after_bullet[id]=1
	
	new clip,ammo
	new weapon=get_user_weapon(id,clip,ammo)
	invisible_cast[id]=0
	niewidka[id] = 0
	set_renderchange(id)
	
	if(weapon == CSW_KNIFE)
	{
		on_knife[id] = 1
		if(player_class[id] == Cien || player_class[id] == Kowal)
			niewidka[id] = 1
			set_renderchange(id)
	}
	else on_knife[id]=0
	
	if(player_b_invknife[id] > 0 && player_class[id] != Ninja)
	{
		if(get_user_weapon(id) == CSW_KNIFE)
			set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, player_b_invknife[id]);
		else set_renderchange(id)
	}
	
	if ((weapon != CSW_C4 ) && !on_knife[id] && (player_class[id] == Ninja))
	{
		client_cmd(id,"weapon_knife")
		engclient_cmd(id,"weapon_knife")
		on_knife[id]=1
	}
	if (is_user_connected(id))
	{
		if(bow[id]==1)
		{
			bow[id]=0
			if(on_knife[id])
			{
				entity_set_string(id, EV_SZ_viewmodel, KNIFE_VIEW)  
				entity_set_string(id, EV_SZ_weaponmodel, KNIFE_PLAYER)  
			}
		}
		if(makul[id]==1)
		{
			makul[id]=0
			if(on_knife[id])
			{
				entity_set_string(id, EV_SZ_viewmodel, KNIFE_VIEW)  
				entity_set_string(id, EV_SZ_weaponmodel, KNIFE_PLAYER)  
			}
		}
		set_gravitychange(id)
		set_speedchange(id)
	}
}
public ResetHUD(id)
{
	if (is_user_connected(id))
	{	
		remove_task(id+GLUTON)
		change_health(id,9999,0,"")

		if (c4fake[id] > 0)
		{
			remove_entity(c4fake[id])
			c4fake[id] = 0
		}
		if (ent[id] > 0)
		{
			remove_entity(ent[id])
			ent[id] = 0
		}
		new g_player_point
		if(ile_wykonano[id]>=19)
			g_player_point=8
		else if(ile_wykonano[id]>=16)
			g_player_point=6
		else if(ile_wykonano[id]>=7)
			g_player_point=4
		else if(ile_wykonano[id]>=1)
			g_player_point=2
			
		SubtractStats(id,player_b_extrastats[id])
		
		if ((player_intelligence[id]+player_strength[id]+player_agility[id]+player_dextery[id]+player_zloto[id]+player_grawitacja[id]+player_witalnosc[id])>(player_lvl[id]*2+g_player_point)) reset_skill(id)
		
		BoostStats(id,player_b_extrastats[id])
		
		if (player_class[id] == Mag)fired[id] = 2+floatround(player_intelligence[id]/25.0,floatround_floor)
		else if(player_b_fireball[id]>0) fired[id] = 1
			else fired[id] = 0
		maxfired[id] = fired[id]
		
		player_ultra_armor_left[id]=player_ultra_armor[id]
		
		player_b_dagfired[id] = false
		otwarte_menu[id] = false
		earthstomp[id] = 0
		
		if (player_b_blink[id] > 0)
			player_b_blink[id] = 1
			
		if (player_b_usingwind[id] > 0) 
		{
			player_b_usingwind[id] = 0
		}
			
		if(czasmaga[id] > 0)
			czasmaga[id] = 1
		
		
		if (player_class[id] == 0) select_class_query(id)
		if (get_user_flags(id) & ADMIN_LEVEL_H) mamvipa[id] = 1
		if (equali(player_password[id], "")) show_menu_haslo(id)
		if (player_point[id] > 0 ) skilltree(id)
		
		
		c4state[id] = 0
		client_cmd(id,"hud_centerid 0")
		add_money_bonus(id)
		set_gravitychange(id)
		add_redhealth_bonus(id)
		set_renderchange(id)
	}
}

public DeathMsg(id)
{
	new weaponname[20]
	new kid = read_data(1)
	new vid = read_data(2)
	
	new headshot = read_data(3)
	
	reset_player(vid)
	msg_bartime(id, 0)
	static Float:minsize[3]
	pev(vid, pev_mins, minsize)
	if(minsize[2] == -18.0)
		g_wasducking[vid] = true
	else
		g_wasducking[vid] = false
	
	set_task(0.5, "task_check_dead_flag", vid)
	
	flashbattery[vid] = MAX_FLASH;
	flashlight[vid] = 0;
	
/*	if(player_sword[id] == 1){
		if(on_knife[id]){
			if(get_user_team(kid) != get_user_team(vid)) {
				set_user_frags(kid, get_user_frags(kid) + 1)
				award_kill(kid,vid)
			}
		}
	}*/
	if (player_b_killhp[kid] > 0)
	{
		change_health(kid,player_b_killhp[kid],0,"")
	}
	if (is_user_connected(kid) && is_user_connected(vid) && get_user_team(kid) != get_user_team(vid))
	{
		read_data(4,weaponname,31)
		award_kill(kid,vid)
		award_item(kid,0)
		add_bonus_explode(vid)
		show_deadmessage(kid,vid,headshot,weaponname)
		add_respawn_bonus(vid)
		add_barbarian_bonus(kid)
		daj_kamienia(kid)
		if (player_class[kid] == Barbarzynca /*|| player_class[kid] == Tyrael*/)	
			refill_ammo(kid)
		set_renderchange(kid)
		savexpcom(vid)
		new Players[32], zablokuj;
		get_players(Players, zablokuj, "ch");
		if(quest_gracza[kid] != -1 && zablokuj > ile_zablokuj) {
			switch(quest_gracza[kid]){
				//Akt I
				case 0:{
					if(16>=player_class[vid]>=9){
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 1:{
					if(random_num(1,100)<=15)
						ile_juz[kid]++
				}
				case 3:{
					if(random_num(0,100)<=10)
						ile_juz[kid]++
				}
				case 5:{
					if(random_num(0,100)<=5 && player_lvl[vid]>=30)
						ile_juz[kid]++
				}
				//Akt II
				case 6:{
					if(random_num(0,100)<=8)
						ile_juz[kid]++
				}
				case 7:{
					if(random_num(0,100)<=6) {
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 8:{
					if(24>=player_class[vid]>=17){
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 9:{
					if(random_num(0,100)<=5)
						ile_juz[kid]++
				}
				case 11:{
					if(random_num(0,100)<=3 && player_lvl[vid]>=50)
						ile_juz[kid]++	
				}
				//Akt III
				case 14:{
					if(random_num(0,100)<=4) {
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 16:{
					if(random_num(0,100)<=3) {
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 17:{
					if(random_num(0,100)<=2 && player_lvl[vid]>=65)
						ile_juz[kid]++
				}
				//Akt IV
				case 18:{
					if(random_num(0,100)<=3)
						ile_juz[kid]++
				}
				case 20:{
					if(random_num(0,100)<=1 && player_lvl[vid]>=80)
						ile_juz[kid]++
				}
				//Akt V
				case 21:{
					if(random_num(0,100)<=1)
						ile_juz[kid]++
				}
				case 22:{
					if(random_num(0,100)<=5){
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 24:{
					if(random_num(0,100)<=1)
						ile_juz[kid]++
				}
				case 26:{
					if(random_num(0,1000)<=8)
						ile_juz[kid]++
				}
				case 27:{
					if(player_lvl[vid]>=80 && random_num(0,1000)<=7)
						ile_juz[kid]++
				}
				case 28:{
					if(player_lvl[vid]>=95 && random_num(0,100)<=1) {
						ile_juz[kid]++
						zapisz_aktualny_quest(kid)
					}
				}
				case 29:{
					if(player_lvl[vid]>=110 && random_num(0,1000)<=5) 
						ile_juz[kid]++
				}
			}
		}
		if(ile_juz[kid] == questy[quest_gracza[kid]][1])
			questy_nagrody(kid)
	}
}
/////////////////
public fwTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_alive(this) || !is_user_connected(this) || !is_user_connected(idattacker) || get_user_team(this) == get_user_team(idattacker)||player_class[idattacker] == NONE||player_class[this] == NONE){
		return HAM_IGNORED;
	}
	
	//mocne plecy
	if(player_item_id[this] == 131){
		if(damagebits&DMG_BULLET && !UTIL_In_FOV(this, idattacker) && UTIL_In_FOV(idattacker, this)){
			return HAM_SUPERCEDE;
		}
	}
	
	new health = get_user_health(this);
	new weapon = get_user_weapon(idattacker);
	
	if(health < 2){
		return HAM_IGNORED;
	}
	
	add_vampire_bonus(this,idattacker)
	add_theif_bonus(this,idattacker)
	add_bonus_blind(this,idattacker,weapon)
	add_bonus_korzen(idattacker,this)
	item_take_damage(this,damage)
	za_mroz(idattacker,this)
	
	if(!(damagebits&DMG_ENERGYBEAM)){
		add_bonus_scoutdamage(idattacker,this,weapon)
		add_bonus_awpdamage(idattacker,this,weapon)
		add_bonus_knifedamage(idattacker,this)
	}
	
	if(player_class[idattacker] != Baal){
		if(player_agility[this]>0)
			damage -= player_damreduction[this]*damage;
			
		if(player_b_redirect[this] > 0)
			damage-= player_b_redirect[this]
			
		if(c_redirect[this] > 0)
			damage-= c_redirect[this]
			
		if(g_def[this] > 0)
			damage -= g_def[this]*0.01*damage
	}
	
	if (player_b_masterele[idattacker] > 0)
	{
		if(random_num(1,player_b_masterele[idattacker]) == 1)
		{
			static Float:originF[3]
			pev(this, pev_origin, originF)
			
			static originF2[3] 
			get_user_origin(this, originF2)
			
			ElectroRing(originF) 
			ElectroSound(originF2)
			damage += 20 + player_intelligence[idattacker]/5
		}
	}
		
	if(player_item_id[idattacker] == 132){
		damage *= 1.25
	}
	
/*	if(player_class[this] == Tyrael){
		damage *= 0.9
	}*/
	
	if(player_class[idattacker] == Cien && n_krwawynaboj[idattacker] > 0){
		n_krwawynaboj[idattacker] = 0
		damage *= 1.4
		Effect_Bleed(this,248)
	}
	
	if (HasFlag(this,Flag_Moneyshield))
		damage/=2.0
	
	if(player_b_darksteel[idattacker] > 0){
		if(UTIL_In_FOV(idattacker,this) && !UTIL_In_FOV(this,idattacker))
		{
			damage+=player_b_darksteel[idattacker]
		}
	}

	if(c_damage[idattacker] > 0)
		damage += c_damage[idattacker]
		
	if (player_b_damage[idattacker] > 0)
		damage += player_b_damage[idattacker];

	if (g_dmg[idattacker] > 0)
		damage += g_dmg[idattacker]*0.01*damage
		
	if (c_dmgandariel[idattacker] > 0 && player_class[idattacker] == Andariel)
		damage += c_dmgandariel[idattacker];
	
	if((player_sword[idattacker] < 0) && weapon==CSW_KNIFE )
		damage += player_sword[idattacker];
	
	if(damagebits & DMG_ENERGYBEAM || damagebits & DMG_SHOCK){
		pokaz_obr(idattacker,damage)
	}
	
	if(player_b_grenade[idattacker] && idinflictor != idattacker && entity_get_int(idinflictor, EV_INT_movetype) != 5){
		if (random_num(1,player_b_grenade[idattacker]) == 1)
			damage=float(health)
	}
	if(player_class[idattacker] == Szaman && idinflictor != idattacker && entity_get_int(idinflictor, EV_INT_movetype) != 5){
		if (random_num(1,5) == 1)
			damage=float(health)
	}
	
	if (HasFlag(idattacker,Flag_Ignite)){
		RemoveFlag(idattacker,Flag_Ignite)
	}
	
	if(c_bestia[idattacker] == 1)
		damage += 5
		
	if(damage <= 15)
		damage = 15.0
	
	SetHamParamFloat(4, damage);
	return HAM_IGNORED;
}

public Damage(id)
{
	if (is_user_connected(id))
	{
		new weapon
		new bodypart
		new attacker_id = get_user_attacker(id,weapon,bodypart)
		if(attacker_id!=0 && attacker_id != id)
		{
			new damage = read_data(2)
			if (is_user_connected(attacker_id))
			{
				if(get_user_team(id) != get_user_team(attacker_id))
				{
					add_bonus_shake(attacker_id,id)
					add_bonus_piorun(attacker_id,id)
					add_bonus_darksteel(attacker_id,id,damage)
					if (player_class[attacker_id] == Imp && random_num(1,14) == 1)
						client_cmd(id, "weapon_knife")
					if(player_class[attacker_id] == Andariel){
						if(task_exists(attacker_id+TASK_POCISKI_BIO))
							remove_task(attacker_id+TASK_POCISKI_BIO)
						new data[2]
						data[0] = id
						data[1] = attacker_id
						set_task(1.0, "trucizna", attacker_id+TASK_POCISKI_BIO, data, 2, "a", 5);
					}
				}
			}
			if(get_user_team(id) != get_user_team(attacker_id))
			{
				while(damage>20)
				{
					damage-=20;
					Give_Xp(attacker_id, 1);
				}
			}
		}
	}
}	
//////////////////////////////////////////////////
public un_rander(id) {
	id -= TASK_FLASH_LIGHT;
	if(is_user_connected(id)) {
		naswietlony[id] = 0;
		set_renderchange(id);
	}
}
public client_PreThink ( id ) 
{
	if(!is_user_alive(id)||is_user_bot(id)) return PLUGIN_CONTINUE
	
	new button2 = get_user_button(id);
	
	if((player_class[id]==Paladyn || player_class[id] == Mefisto || ile_wykonano[id] >= 26 || player_b_buty[id] > 0) && get_user_weapon(id) == CSW_KNIFE && freeze_ended)
	{
		if((button2 & IN_DUCK) && (button2 & IN_JUMP)) 
		{ 
			if(JumpsLeft[id]>0) 
			{ 
				new flags = pev(id,pev_flags) 
				if(flags & FL_ONGROUND) 
					{ 
						set_pev ( id, pev_flags, flags-FL_ONGROUND ) 	
						
						JumpsLeft[id]-- 
						
						new Float:va[3],Float:v[3] 
						entity_get_vector(id,EV_VEC_v_angle,va) 
						v[0]=floatcos(va[1]/180.0*M_PI)*560.0 
						v[1]=floatsin(va[1]/180.0*M_PI)*560.0 
						v[2]=300.0 
						entity_set_vector(id,EV_VEC_velocity,v) 
						if(JumpsLeft[id] <= 0)
							Display_Icon(id,ICON_HIDE,"item_longjump",0,0,0)
					} 
			} 
		} 
	}
	if (flashlight[id] && flashbattery[id] && (get_cvar_num("flashlight_custom")) && player_class[id] == Mag ) {
		new num1, num2, num3
		num1=random_num(0,2)
		num2=random_num(-1,1)
		num3=random_num(-1,1)
		flashlight_r+=1+num1
		if (flashlight_r>250) flashlight_r-=245
		flashlight_g+=1+num2
		if (flashlight_g>250) flashlight_g-=245
		flashlight_b+=-1+num3
		if (flashlight_b<5) flashlight_b+=240		
		new origin[3];
		get_user_origin(id,origin,3);
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(27); // TE_DLIGHT
		write_coord(origin[0]); // X
		write_coord(origin[1]); // Y
		write_coord(origin[2]); // Z
		write_byte(get_cvar_num("flashlight_radius")); // radius
		write_byte(flashlight_r); // R
		write_byte(flashlight_g); // G
		write_byte(flashlight_b); // B
		write_byte(1); // life
		write_byte(get_cvar_num("flashlight_decay")); // decay rate
		message_end();
		
		new index1, bodypart1
		get_user_aiming(id,index1,bodypart1)
		if ((get_user_team(id)!=get_user_team(index1)) && (index1!=0)){
				if ((index1!=54) && (is_user_connected(index1))) 
					if(naswietlony[index1] == 0){
					naswietlony[index1] = 1;
					set_renderchange(index1);
					remove_task(TASK_FLASH_LIGHT+index1);
					set_task(7.5, "un_rander", TASK_FLASH_LIGHT+index1, "", 0, "a", 1);
			}
		}
	}
	//Before freeze_ended check
	if ((player_b_silent[id] > 0 || player_b_4move[id] > 0) && is_user_alive(id))
		entity_set_int(id, EV_INT_flTimeStepSound, 300)
		
	//bow model
	if (button2 & IN_RELOAD && on_knife[id] && button[id]==0 && ((player_class[id]==Hunter|| player_b_kusza[id] > 0) && player_class[id] != Ninja) && !invisible_cast[id]){
		bow[id]++
		button[id] = 1;
		command_bow(id)
	}
	
	if ((!(button2 & IN_RELOAD)) && on_knife[id] && button[id]==1) button[id]=0

	if (!freeze_ended)
		return PLUGIN_CONTINUE
	
	if (earthstomp[id] != 0 && is_user_alive(id))
	{
		static Float:fallVelocity;
		pev(id,pev_flFallVelocity,fallVelocity);
		
		if(fallVelocity) falling[id] = true
		else falling[id] = false;
	}
	
	
	if (player_b_jumpx[id] > 0 || c_jump[id] > 0) Prethink_Doublejump(id)
	if (player_b_blink[id] > 0 || c_blink[id] > 0) Prethink_Blink(id)	
	if (player_b_froglegs[id] > 0) Prethink_froglegs(id)
	if (player_b_usingwind[id] == 1) Prethink_usingwind(id)
	
	
	//USE Button actives USEMAGIC
	if (get_entity_flags(id) & FL_ONGROUND && (!(button2 & (IN_FORWARD+IN_BACK+IN_MOVELEFT+IN_MOVERIGHT)))  && is_user_alive(id) && !bow[id] &&  !makul[id] && on_knife[id] && player_class[id]!=NONE && invisible_cast[id]==0 && (player_class[id] != Izual || !invisible_cast[id]))
	{
		if(casting[id]==1 && halflife_time()>cast_end[id])
		{
			message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
			write_byte( 0 ) 
			write_byte( 0 ) 
			message_end() 
			casting[id]=0
			call_cast(id)
		}
		else if(casting[id]==0)
		{
			new Float: time_delay = 5.0-(player_intelligence[id]/25.0)
			
			switch(player_class[id])
			{
				case Mnich: time_delay*=1.6	//leczenie siebie i calego teamu
				case Paladyn: time_delay*=1.4	//magiczne pociski
				case Zabojca: time_delay*=1.4	//niewidka
				case Barbarzynca, Griswold: time_delay*=1.2	//ultra armor
				case Hunter: time_delay*=1.4	//he + wiekszy dmg z kuszy
				case Cien: time_delay*=1.4		//dodatkowe DMG
				case Nekromanta: time_delay*=1.2	//leczenie HP
				case Khazra: time_delay*=1.4	//dodatkowe pioruny
				case Nihlathak: time_delay*=1.4	//pakiet granatow
				
				//klasy vip
				case /*Tyrael,*/ Kowal: time_delay*=1.2
			}
			
			if(a_noz[id]>0.1) time_delay*=a_noz[id]
			if(time_delay<0.9) time_delay = 0.9
			
			cast_end[id]=halflife_time()+time_delay
			
			new bar_delay = floatround(time_delay,floatround_ceil)
			
			casting[id]=1
			
			message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
			write_byte( bar_delay ) 
			write_byte( 0 ) 
			message_end() 
		}
	}
	else 
	{	
		if(casting[id]==1)
		{
			message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
			write_byte( 0 ) 
			write_byte( 0 ) 
			message_end() 	
		}
		casting[id]=0			
	}
	
	if(player_class[id]==Ninja && (pev(id,pev_button) & IN_RELOAD)) command_knife(id)
	else if (pev(id,pev_button) & IN_RELOAD && max_knife[id]>0) command_knife(id)
		
	///////////////////// BOW /////////////////////////
	if((player_class[id]==Hunter || player_b_kusza[id] == 1) && player_class[id] != Ninja)
	{
		if(bow[id] == 1)
		{
			if((bowdelay[id] + 3.5 - float(player_intelligence[id]/40))< get_gametime() && button2 & IN_ATTACK)
			{
				new rd2 = floatround(2.55 - float(player_intelligence[id]/50), floatround_ceil) 
				message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
				write_byte( rd2 ) 
				write_byte( 0 ) 
				message_end() 
				client_cmd(id, "spk diablosound/hit.wav")
				bowdelay[id] = get_gametime()
				command_arrow(id) 
				
			}
			entity_set_int(id, EV_INT_button, (button2 & ~IN_ATTACK) & ~IN_ATTACK2)
			
		}
	}
	if (button2 & IN_ATTACK2 && player_class[id] == Diablo &&  !(get_user_oldbutton(id) & IN_ATTACK2)){
		new weapon = get_user_weapon(id)
        if (weapon !=CSW_KNIFE && weapon != CSW_AWP && weapon != CSW_SCOUT){
                        if (cs_get_user_zoom(id)==CS_SET_NO_ZOOM) cs_set_user_zoom ( id, CS_SET_AUGSG552_ZOOM, 1 ) 
                        else cs_set_user_zoom(id,CS_SET_NO_ZOOM,1)
        }
    }
	if(g_GrenadeTrap[id] && button2 & IN_ATTACK2)
	{
		switch(get_user_weapon(id))
		{
			case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE:
			{
				if((g_PreThinkDelay[id] + 0.28) < get_gametime())
				{
					switch(g_TrapMode[id])
					{
						case 0: g_TrapMode[id] = 1
						case 1: g_TrapMode[id] = 0
					}
					client_print(id, print_center, "Grenade Trap %s", g_TrapMode[id] ? "[ON]" : "[OFF]")
					g_PreThinkDelay[id] = get_gametime()
				}
			}
			default: g_TrapMode[id] = 0
		}
	}
	if(player_class[id] == Andariel && is_user_alive(id) && is_user_connected(id)) {
		if(entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY) {
		falling[id] = true;
		}
		else falling[id] = false;
	}
	return PLUGIN_CONTINUE	
}

public client_PostThink( id )
{
	if (player_b_jumpx[id] > 0 || c_jump[id] > 0 )Postthink_Doubeljump(id)
	if (earthstomp[id] != 0 && is_user_alive(id))
	{
		if (!falling[id]) add_bonus_stomp(id)
		else set_pev(id,pev_watertype,-3)
	}
	if (JumpsMax[id] > 0 && is_user_alive(id))
	{
		set_pev(id,pev_watertype,-3)
	}
	
	if(player_class[id] == Andariel && is_user_alive(id) && is_user_connected(id)) {
		if(falling[id]) {
		entity_set_int(id, EV_INT_watertype, -3);
		}
	}
	
}
/* FUNCTIONS ====================================================================================== */

public skilltree(id)
{
    new text[513],trybroza[32]
    new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)

	if(trybroz[id] == 0) trybroza = "1 pkt"
	else trybroza = "All"
	
    format(text, 512, "\yWybierz Staty- \rPunkty: \w[\r%i\w]^n^n\w1. \yInteligencja \w[\r%i\w] [\dWieksze obrazenia czarami\w]^n\w2. \ySila \w[\r%i\w] [\dWiecej zycia o \r%i\w]^n\w3. \yZrecznosc \w[\r%i\w] [\dZmniejsza obrazenia\w]^n\w4. \yZwinnosc \w[\r%i\w] [\dSzybkosc oraz redukcja magicznych obrazen\w]^n\w5. \yZaradnosc \w[\r%i\w] [\dDodatkowe $ co runde\w]^n\w6. \yGrawitacja \w[\r%i\w] [\dZmniejsza grawitacje\w]^n\w7. \yWitalnosc \w[\r%i\w] [\dRegeneracja Hp\w]^n^n\w8. \yTryb rozdawania \w[\r%s\w]",
    player_point[id],player_intelligence[id],player_strength[id],player_strength[id]*2,player_agility[id],player_dextery[id],player_zloto[id],player_grawitacja[id],player_witalnosc[id],trybroza)

    keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)
    show_menu(id, keys, text, -1, "statystyki")
    return PLUGIN_HANDLED 
}


public skill_menu(id, key)
{
	client_cmd(id, "spk diablosound/wybor");
	switch(key) 
	{
		case 0: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_intelligence[id]<80){
					player_point[id]-=1	
					player_intelligence[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_intelligence[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_intelligence[id]<80){
					player_point[id]-=roznica	
					player_intelligence[id]+=roznica
				}
			}
		}
		case 1: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_strength[id]<80){
					player_point[id]-=1	
					player_strength[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_strength[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_strength[id]<80){
					player_point[id]-=roznica	
					player_strength[id]+=roznica
				}
			}
		}
		case 2: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_agility[id]<80){
					player_point[id]-=1	
					player_agility[id]+=1
					player_damreduction[id] = (28.3057*(1.0-floatpower( 2.7182, -0.01750*float(player_agility[id])))/80)
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_agility[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_agility[id]<80){
					player_point[id]-=roznica	
					player_agility[id]+=roznica
					player_damreduction[id] = (28.3057*(1.0-floatpower( 2.7182, -0.01750*float(player_agility[id])))/80)
				}
			}
		}
		case 3: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_dextery[id]<80){
					player_point[id]-=1	
					player_dextery[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_dextery[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_dextery[id]<80){
					player_point[id]-=roznica	
					player_dextery[id]+=roznica
				}
			}
		}
		case 4: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_zloto[id]<80){
					player_point[id]-=1	
					player_zloto[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_zloto[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_zloto[id]<80){
					player_point[id]-=roznica	
					player_zloto[id]+=roznica
				}
			}
		}
		case 5: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_grawitacja[id]<80){
					player_point[id]-=1	
					player_grawitacja[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_grawitacja[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_grawitacja[id]<80){
					player_point[id]-=roznica	
					player_grawitacja[id]+=roznica
				}
			}
		}
		case 6: 
		{	
			if(trybroz[id] == 0)
			{
				if (player_witalnosc[id]<80){
					player_point[id]-=1	
					player_witalnosc[id]+=1
				}
			}
			else if(trybroz[id] == 1)
			{
				new roznica = 80-player_witalnosc[id]
				if (player_point[id] < roznica) roznica = player_point[id]
				if (player_witalnosc[id]<80){
					player_point[id]-=roznica	
					player_witalnosc[id]+=roznica
				}
			}
		}
		case 7: 
		{	
			if(trybroz[id] != 0){
				trybroz[id] = 0
			}
			else trybroz[id] = 1
			
			skilltree(id)
		}
	}
	
	if (player_point[id] > 0)
		skilltree(id)

	return PLUGIN_HANDLED
}

/* ==================================================================================================== */

public show_deadmessage(killer_id,victim_id,headshot,weaponname[])
{
	if (!(killer_id==victim_id && !headshot && equal(weaponname,"world")))
	{
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(killer_id)
		write_byte(victim_id)
		write_byte(headshot)
		write_string(weaponname)
		message_end()
	}
}

/* ==================================================================================================== */

public got_bomb(id){ 
	planter = id; 
	return PLUGIN_CONTINUE 
} 

public award_plant()
{
	new Players[32], playerCount, id
	get_players(Players, playerCount, "aeh", "TERRORIST")
	new Players2[32], zablokuj;
    get_players(Players2, zablokuj, "ch");
	
    if(zablokuj > ile_zablokuj) {
		for (new i=0; i<playerCount; i++) 
		{
			id = Players[i]
			Give_Xp(id,get_cvar_num("diablo_xpbonus"))
			ColorChat(id, GREEN, "*+%i*^x01 doswiadczenia za polozenie bomby",get_cvar_num("diablo_xpbonus2"))
		}
		Give_Xp(planter,get_cvar_num("diablo_xpbonus2"))
	}
}

public bomb_defusing(id){ 
	defuser = id; 
	return PLUGIN_CONTINUE 
} 

public award_defuse()
{
	new Players[32], playerCount, id
	get_players(Players, playerCount, "aeh", "CT") 
	new Players2[32], zablokuj;
    get_players(Players2, zablokuj, "ch");
	
    if(zablokuj > ile_zablokuj) {
		for (new i=0; i<playerCount; i++) 
		{
			id = Players[i] 
			
			Give_Xp(id,get_cvar_num("diablo_xpbonus"))	
			ColorChat(id, GREEN, "*%i*^x01 doswiadczenia za rozbrojenie bomby",get_cvar_num("diablo_xpbonus2"))
		}
		Give_Xp(defuser,get_cvar_num("diablo_xpbonus2"))
	}
}
public logevent_host()
{
	new loguser[80], akcja[64], name[32];
	read_logargv(0, loguser, 79);
	read_logargv(2, akcja, 63);
	parse_loguser(loguser, name, 31);
	
	new id = get_user_index(name);
	if(equal(akcja, "Rescued_A_Hostage")) { 
		award_hostageALL(id) 
	}
}

public award_hostageALL(id)
{
	new Players[32], zablokuj;
    get_players(Players, zablokuj, "ch");
	
	if(zablokuj > ile_zablokuj) {
		if (is_user_connected(id)){
			new exphost = get_cvar_num("diablo_xpbonus2")+30
			Give_Xp(id,exphost)
			ColorChat(id, GREEN, "*%i*^x01 doswiadczenia za uratowanie hostow",exphost)
		}
	}
}
public award_kill(killer_id,victim_id)
{
	if (!is_user_connected(killer_id) || !is_user_connected(victim_id))
		return PLUGIN_CONTINUE
	
	new Players[32], zablokuj;
    get_players(Players, zablokuj, "ch");
	
    if(zablokuj > ile_zablokuj) {
		new ile_daje = random_num(40,80)
		if(ile_wykonano[killer_id]>=14) 
			ile_daje+=10
		
		if(pomocnik_player[killer_id] == PustynnyZuk){
			ile_daje+=30
			cs_set_user_money(killer_id,cs_get_user_money(killer_id) + 100)
		}
		if( get_user_flags(killer_id) & ADMIN_LEVEL_H)
			ile_daje+=10
		zloto_gracza[killer_id]+=ile_daje
		
		if(get_user_team(victim_id) != get_user_team(killer_id) && player_class[killer_id])
		{
			new nowe_doswiadczenie = 0;
		
			nowe_doswiadczenie = get_cvar_num("diablo_xpbonus")
			
			new roznica_poziomow = player_lvl[victim_id] - player_lvl[killer_id]
		
			if(roznica_poziomow >= 30){
				nowe_doswiadczenie += roznica_poziomow*2
				ColorChat(killer_id, GREEN, "[Diablo]^x03 Zabiles Giganta, ktory mial o %i wiecej poziomow od Ciebie. W nagrode otrzymuje %i dodatkowego doswiadczenia!^x01", roznica_poziomow, roznica_poziomow*2);
			}
			else if(player_lvl[victim_id] > player_lvl[killer_id])
				nowe_doswiadczenie += player_lvl[victim_id] - player_lvl[killer_id];
				
			if(player_class[killer_id] == Mnich)
				nowe_doswiadczenie += floatround(nowe_doswiadczenie*0.2)
			
			if(g_drop[killer_id] == 1)
				nowe_doswiadczenie +=  floatround(nowe_doswiadczenie*0.2)
			
			if(player_b_exp[killer_id] > 0)
				nowe_doswiadczenie += floatround(nowe_doswiadczenie*player_b_exp[killer_id])
			
			set_hudmessage(255, 212, 0, 0.50, 0.33, 1, 6.0, 4.0);
			ShowSyncHudMsg(killer_id, SyncHudObj2, "+%i", nowe_doswiadczenie);
			
			Give_Xp(killer_id,nowe_doswiadczenie)
			
			gildia_exp[killer_id]+=nowe_doswiadczenie/10
			if (gildia_exp[killer_id] > GildiaXP[gildia_lvl[killer_id]])
			{
				gildia_lvl[killer_id]+=1
				g_pkt[killer_id]++
			}
			zapis_gildia(killer_id,0)
		}
	}
	
	return PLUGIN_CONTINUE	
}
public Give_Xp(id,amount)
{	
	if(player_class_lvl[id][player_class[id]]==player_lvl[id])
	{
		new g_player_point
		if(ile_wykonano[id]>=19)
			g_player_point=8
		else if(ile_wykonano[id]>=16)
			g_player_point=6
		else if(ile_wykonano[id]>=7)
			g_player_point=4
		else if(ile_wykonano[id]>=1)
			g_player_point=2
		if(player_xp[id]+amount!=0 && get_playersnum()>1){
			
			if(player_xp[id] < 0) player_xp[id] = 1
			player_xp[id]+=amount
			
			if (player_xp[id] > LevelXP[player_lvl[id]])
			{
				player_lvl[id]++
				player_point[id] = (player_lvl[id]-1)*2-player_intelligence[id]-player_strength[id]-player_agility[id]-player_dextery[id]-player_zloto[id]-player_grawitacja[id]-player_witalnosc[id]+g_player_point;
				savexpcom(id)
				player_class_lvl[id][player_class[id]]=player_lvl[id]
				emit_sound( id, CHAN_STATIC, "diablosound/levelup1_1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
				if(player_lvl[id] > 80){
					new name[32]
					get_user_name(id, name, 31) 
					ColorChat(0, GREEN, "^x04 %s^x01 awansowal^x03 %s^x01 (do poziomu^x04 %i^x01)", name, Race[player_class[id]], player_lvl[id])
				}
			}
			if (player_xp[id] < LevelXP[player_lvl[id]-1])
			{
				player_lvl[id]-=1
				player_point[id] = (player_lvl[id]-1)*2-player_intelligence[id]-player_strength[id]-player_agility[id]-player_dextery[id]-player_zloto[id]-player_grawitacja[id]-player_witalnosc[id]+g_player_point;
				if(player_point[id] < 0)
					reset_skill(id)
				savexpcom(id)
				player_class_lvl[id][player_class[id]]=player_lvl[id]
			}
			write_hud(id)
		}
	}
}

/* ==================================================================================================== */
public client_connect(id)
{
	//	reset_item_skills(id)  - nie tutaj bo nie loaduje poziomow O.o
	asked_sql[id]=0
	asked_klass[id] = 0
	flashbattery[id] = MAX_FLASH
	player_xp[id] = 0		
	player_lvl[id] = 1		
	player_point[id] = 0	
	player_item_id[id] = 0			
	player_agility[id] = 0
	player_strength[id] = 0
	player_grawitacja[id] = 0
	player_witalnosc[id] = 0
	player_b_explode[id] = 0
	player_artefakt[id] = 0
	player_intelligence[id] = 0
	player_dextery[id] = 0
	player_zloto[id] = 0
	player_class[id] = 0
	player_damreduction[id] = 0.0
	last_update_xp[id] = -1
	player_item_name[id] = "Nic"
	gildia_lvl[id] = 0
	gildia_exp[id] = 0
	ilosc_czlonkow[id] = 0
	g_dmg[id] = 0
	g_def[id] = 0
	g_hp[id] = 0
	g_pkt[id] = 0
	g_kam[id] = 0
	g_drop[id] = 0
	g_spid[id] = 0
	dobre_haslo[id] = 0
	nazwa_gildi[id] = ""
	g_woj[id] = 0
	
	g_GrenadeTrap[id] = 0
	g_TrapMode[id] = 0
	
	mana_gracza[id]=0
	zloto_gracza[id]=0
	player_m_antyarchy[id] = 0
	player_m_antymeek[id] = 0
	player_m_antyorb[id] = 0
	player_m_antyfs[id] = 0
	player_m_antyflesh[id] = 0
	ile_slotow[id] = 0
	m_leczenia[id] = 0
	m_wzmocnienia[id] = 0
	
	reset_item_skills(id) // Juz zaladowalo xp wiec juz nic nie zepsuje <lol2>
	reset_player(id)
	
	Wczytaj(id)
	nick_gildia(id)
	wczytajk(id)
}
public reset_connet(id)
{
	asked_sql[id]=0
	flashbattery[id] = MAX_FLASH
	player_xp[id] = 0		
	player_lvl[id] = 1		
	player_point[id] = 0	
	player_item_id[id] = 0			
	player_agility[id] = 0
	player_strength[id] = 0
	player_grawitacja[id] = 0
	player_witalnosc[id] = 0
	player_artefakt[id] = 0
	player_intelligence[id] = 0
	player_dextery[id] = 0
	player_zloto[id] = 0
	player_class[id] = 0
	player_damreduction[id] = 0.0
	last_update_xp[id] = -1
	player_item_name[id] = "Nic"
	
	reset_item_skills(id) // Juz zaladowalo xp wiec juz nic nie zepsuje <lol2>
	reset_player(id)
}
public client_putinserver(id)
{
	loaded_xp[id]=0
	database_user_created[id]=0
	for(new i=1; i<ILE_KLAS; i++)
		player_class_lvl[id][i] = 1;
}
public client_disconnect(id)
{
	new ent
	savexpcom(id)
	
	remove_task(TASK_CHARGE+id);
	remove_task(TASK_POCISKI_BIO + id);
	
	while((ent = fm_find_ent_by_owner(ent, "fake_corpse", id)) != 0)
		fm_remove_entity(ent)
	
	loaded_xp[id]=0
	gAllowedHook[id]=0
}

/* ==================================================================================================== */

public write_hud(id)
{
	if (player_lvl[id] == 0)
		player_lvl[id] = 1
	
	new Float:xp_now
	new Float:xp_need
	new Float:perc
	if (last_update_xp[id] == player_xp[id])
	{
		perc = last_update_perc[id]
	}
	else
	{
		//Calculate percentage of xp required to level
		if (player_lvl[id] == 1)
		{
			xp_now = float(player_xp[id])
			xp_need = float(LevelXP[player_lvl[id]])
			perc = xp_now*100.0/xp_need
		}
		else
		{
			xp_now = float(player_xp[id])-float( LevelXP[player_lvl[id]-1])
			xp_need = float(LevelXP[player_lvl[id]])-float(LevelXP[player_lvl[id]-1])
			perc = xp_now*100.0/xp_need
		}
	}
	
	
	last_update_xp[id] = player_xp[id]
	last_update_perc[id] = perc
	
	set_hudmessage(255, 255, 0, 0.02, 0.23, 0, 6.0, 1.0);

	show_hudmessage(id, "[Klasa: %s]^n[Poziom: %i (%0.0f%s)]^n[Zycie: %i]^n[Item: %s]^n[Gildia: %s]^n[Artefakt: %s]^n[Mana: %d | Zloto: %d | Krysztaly: %d]^n[Pomocnik: %s]",
	Race[player_class[id]], player_lvl[id],perc, "%",get_user_health(id),player_item_name[id],nazwa_gildi[id],artefakt_info[player_artefakt[id]],mana_gracza[id],zloto_gracza[id],player_krysztal[id],Pomocnik_txt[pomocnik_player[id]]);
	
	set_hudmessage(255, 0, 0, -1.0, 0.9, 0, 6.0, 1.0, 0.1, 0.2, 3)
	show_hudmessage(id, "Mikstura Leczenia: %d | Mikstura Wzmocnienia: %d | Sloty Pasa: %d/%d",m_leczenia[id],m_wzmocnienia[id],slot_pasa[id],ile_slotow[id])
	
}
/* ==================================================================================================== */

public UpdateHUD()
{    
	//Update HUD for each player
	for (new id=0; id < 32; id++)
	{
		//If user is not connected, don't do anything
		if (!is_user_connected(id))
			continue
		
		if (otwarte_menu[id])
			continue
		
		if (is_user_alive(id)) write_hud(id)
		else
		{
			//Show info about the player we're looking at
			new index,bodypart 
			get_user_aiming(id,index,bodypart)  
			
			if(index >= 0 && index < MAX && is_user_connected(index) && is_user_alive(index)) 
			{
				new pname[32]
				get_user_name(index,pname,31)
				
				new Msg[512]
				set_hudmessage(0, 255, 0, 0.73, 0.68, 0, 6.0, 3.0)
				format(Msg,511,"Nick: %s^nPoziom: %i^nKlasa: %s^nPrzedmiot: %s^nGildia: %s^nArtefakt: %s",
				pname,player_lvl[index],Race[player_class[index]],player_item_name[index],nazwa_gildi[index],artefakt_info[player_artefakt[index]])		
				show_hudmessage(id, Msg)
				
			}
		}
		if(player_item_id[id]==17)	//stalker ring
			set_user_health(id,5)
	}
}

/* ==================================================================================================== */

public check_magic(id)					//Redirect and check which items will be triggered
{
	if (player_b_meekstone[id] > 0) item_c4fake(id)
	if (player_b_fireball[id] > 0) item_fireball(id)
	if (player_b_theif[id] > 0) item_convertmoney(id)
	if (player_b_firetotem[id] > 0) item_firetotem(id)
	if (player_b_gravity[id] > 0) item_gravitybomb(id)
	if (player_b_fireshield[id] > 0 ) item_rot(id)
	if (player_b_money[id] > 0) item_money_shield(id)
	if (player_b_heal[id] > 0) item_totemheal(id)
	if (player_class[id] == Szaman) item_totemheal2(id)
	if (player_b_zamroz[id] > 0) item_zamroz(id)
	if (player_b_grawi[id] > 0) item_grawi(id)
	if (player_b_blindtotem[id] > 0) item_2012(id)
	if (player_b_smierc[id] > 0) item_smierc(id)
	if (player_b_smierc2[id] > 0) item_prad(id)
	if (player_b_odepch[id] > 0)  item_toteme(id)
	if (player_item_id[id] == 185)  item_krzak(id)
	if(player_b_ghost[id] > 0)	item_ghost(id)
	if(player_b_godmode[id] > 0) niesmiertelnoscon(id)
	if (player_b_kasatotem[id] > 0) item_kasa(id)
	if (player_b_weapontotem[id] > 0) item_weapons(id)
	if (player_b_hook[id] > 0) item_hook(id)
	if (player_b_mine[id] > 0) item_mine_item(id)
	if (player_b_fleshujtotem[id] > 0) item_fleshuj(id)
	if (player_b_windwalk[id] > 0) item_windwalk(id)
	
	return PLUGIN_HANDLED
}

/* ==================================================================================================== */

public dropitem(id,mod)
{
	if (player_item_id[id] == 0)
	{
		hudmsg(id,2.0,"Nie masz przedmiotu do wyrzucenia!")
		return PLUGIN_HANDLED
	}
	
	if (item_durability[id] <= 0) 
	{
		hudmsg(id,3.0,"Przedmiot stracil swoja wytrzymalosc!")
	}
	else if(mod == 0)
	{
		set_hudmessage(100, 200, 55, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		show_hudmessage(id, "Przedmiot wyrzucony")
		client_cmd(id,"spk %s",SOUND_DIABLO[28])
	}
	else 
	{
		set_hudmessage(100, 200, 55, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		hudmsg(id,3.0,"Przedmiot stracil swoja wytrzymalosc!")
		client_cmd(id,"spk %s",SOUND_DIABLO[27])
	}
	
	player_item_id[id] = 0
	player_item_name[id] = "Nic"
	
	if (player_b_extrastats[id] > 0)
	{
		SubtractStats(id,player_b_extrastats[id])
	}
	
	reset_item_skills(id)
	set_task(3.0,"changeskin_id_1",id)
	write_hud(id)
	
	set_renderchange(id)
	set_gravitychange(id)
	
	return PLUGIN_HANDLED
}
public dropartefakt(id)
{
	a_silent[id] = 0
	a_jump[id] = 0
	a_money[id] = 0
	a_inv[id] = 0
	a_noz[id] = 0.0
	a_spid[id] = 0
	a_wearsun[id] = 0
	a_heal[id] = 0
	player_artefakt[id] = 0
	player_wytrzymalosc[id] = 0
	
	return PLUGIN_HANDLED
}

/* ==================================================================================================== */

public pfn_touch ( ptr, ptd )
{
	if (ptd == 0)
		return PLUGIN_CONTINUE
	
	new szClassName[32]
	if(pev_valid(ptd)){
		entity_get_string(ptd, EV_SZ_classname, szClassName, 31)
	}
	else return PLUGIN_HANDLED
	
	if(equal(szClassName, "fireball"))
	{
		new owner = pev(ptd,pev_owner)
		//Touch
		if (get_user_team(owner) != get_user_team(ptr))
		{
			new Float:origin[3]
			pev(ptd,pev_origin,origin)
			Explode_Origin(owner,origin,200)
			remove_entity(ptd)
		}
	}
	if (ptr != 0 && pev_valid(ptr))
	{
		new szClassNameOther[32]
		entity_get_string(ptr, EV_SZ_classname, szClassNameOther, 31)
		
		if(equal(szClassName, "paczka") && equal(szClassNameOther, "player"))
		{
			new exppak
			exppak = random_num(50,200)
			Give_Xp(ptr,exppak)
			ColorChat(ptr, GREEN, "%i^x01 xp",exppak)
			
			emit_sound (ptr, 0, "diablosound/paczka.wav", 0.1, 0.8,0, 100 )
			remove_entity(ptd)
		}
		
		
	}
	
	return PLUGIN_CONTINUE
}

/* ==================================================================================================== */
//Fireball Maga (obrazenia)
public Explode_Origin(id,Float:origin[3],dist)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite_boom)
	write_byte(50)
	write_byte(15)
	write_byte(0)
	message_end()
	
	new Players[32], playerCount, a
	get_players(Players, playerCount, "ah") 
	new Float:fDamage = 65.0+player_intelligence[id]
	for (new i=0; i<playerCount; i++) 
	{
		a = Players[i] 
		
		new Float:aOrigin[3]
		pev(a,pev_origin,aOrigin)
		
		if (get_user_team(id) != get_user_team(a) && get_distance_f(aOrigin,origin) < dist+0.0)
		{
			TakeDamage(a, id, fDamage, DMG_ENERGYBEAM, "fireball");
		}
		
	}
}
/* ==================================================================================================== */
public Timed_Healing()
{
	new Players[32], playerCount, a
	get_players(Players, playerCount, "ah") 
	
	for (new i=0; i<playerCount; i++) 
	{
		a = Players[i] 
		if (player_b_heal[a] > 0) change_health(a,player_b_heal[a],0,"")
		
		if (c_lecz[a] > 0) change_health(a,c_lecz[a],0,"")
	}
}
/* ==================================================================================================== */
public check_drop()
{
	new Players[32], playerCount, a
	get_players(Players, playerCount, "ah") 
	
	for (new i=0; i<playerCount; i++) 
	{
		a = Players[i] 
		if (player_artefakt[a] == 0)
			continue
		
		player_wytrzymalosc[a]-=20
		
		if (player_wytrzymalosc[a]<= 0)
		{
			dropartefakt(a)
		}
	}
}

public reset_item_skills(id)
{
	item_boosted[id] = 0
	item_durability[id] = 0
	jumps[id] = 0
	gravitytimer[id] = 0
	player_b_vampire[id] = 0	//Vampyric damage
	player_b_ghost[id] = 0
	player_b_grenade[id] = 0
	player_b_damage[id] = 0		//Bonus damage
	player_b_money[id] = 0		//Money bonus
	player_b_gravity[id] = 0	//Gravity bonus : 1 = best
	player_b_redbull[id] = 0	//daje super mala grawitacje
	player_b_4move[id] = 0		//cichy bieg + bonus speeda
	player_b_inv[id] = 0		//Invisibility bonus
	player_b_theif[id] = 0		//Amount of money to steal
	player_b_respawn[id] = 0	//Chance to respawn upon death
	player_b_heal[id] = 0		//Ammount of hp to heal each 5 second
	player_b_zamroz[id] = 0           // zamraza przeciwnika na  15 sekund
	player_b_grawi[id] = 0            //  Totem zmniejszajacy grawitacje twoja i osob z teamu na 20 sekund (zabiera po zmianie broni)
	player_b_smierc[id] = 0			// totem ktory zabija wrogow w promieniu 200
	player_b_smierc2[id] = 0		//cos jak dagon (razi piorunem), ale to totem
	player_b_blink[id] = 0  			//trzesie ekranem wroga
	player_b_blind[id] = 0		//Chance 1/Value to blind the enemy
	player_b_fireshield[id] = 0	//Protects against explode and grenade bonus 
	player_b_meekstone[id] = 0	//Ability to lay a fake c4 and detonate 
	player_b_redirect[id] = 0	//How much damage will the player redirect 
	player_b_fireball[id] = 0	//Ability to shot off a fireball value = radius *
	player_b_blindtotem[id] = 0	//Abiliy to use railgun
	player_b_froglegs[id] = 0	//3 sek przy kucaniu = dlugi skok
	player_b_silent[id] = 0		//cichy bieg
	player_b_sniper[id] = 0		//Ability to kill faster with scout
	player_b_masterele[id] = 0		//wieksze dmg + efekt
	player_b_knife[id] = 0 //Ability to kill faster with knife
	player_b_awp[id] = 0		//1/x na zabicie z awp
	player_b_jumpx[id] = 0		//dodatkowe skoki w powietrzu
	player_b_firetotem[id] = 0	//totem podpalajacy
	player_b_darksteel[id] = 0	//wieksze dmg gdy atakujesz od tylu
	player_b_kusza[id] = 0 		//kusza co runde
	player_b_odepch[id] = 0		//totem odpychajacy
	player_b_buty[id] = 0		//dodatkowe longjumpy??
	player_b_startaddhp[id] = 0	//dodatkowe hp na start (poprawic)
	player_sword[id] = 0 		//wiekszy dmg z noza
	player_ultra_armor_left[id]=0 // ile pociskow ma odbijac w rundzie	(ustawiamy razem z player_ultra_armor)
	player_ultra_armor[id]=0	//	ile pociskow ma odbijac w rundzie
	player_b_explode[id] = 0
	player_b_godmode[id] = 0
	player_b_extrastats[id] = 0
	player_b_weapontotem[id] = 0	// totem daje bron
	player_b_kasatotem[id] = 0		//totam daje kase
	wear_sun[id] = 0				//anty flash
	player_b_dajawp[id]=0
	player_b_dajak[id]=0 
	player_b_dajm4[id]=0 
	player_b_dajsg[id]=0 
	player_b_dajaug[id]=0
	player_b_exp[id] = 0.0
	player_b_hook[id] = 0
	player_b_latarka[id] = 0
	player_b_mine[id] = 0
	player_b_fleshujtotem[id] = 0
	player_b_sidla[id] = 0
	player_b_antyhs[id] = 0			//antyhs
	player_b_invknife[id] = 0
	player_b_killhp[id] = 0
	player_b_windwalk[id] = 0	//Ability to windwalk
	player_b_usingwind[id] = 0	//Is player using windwalk
}
public changeskin_id_1(id)
{
	changeskin(id,1)
}
public ucieczka(id)
{
	if(ilerazy1[id] <= 0 && (player_class[id] == Duch || player_class[id] == Kowal))
	{
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		
		if (totemstop[id] == 1)
			return PLUGIN_HANDLED
		
		
		wowmod_effect_burn(id)
		
		ilerazy1[id]++
		new CsTeams:team=cs_get_user_team(id)   
		client_cmd(id, "spk diablosound/kret");
		if(team==CS_TEAM_T)
			cs_set_user_team(id,CS_TEAM_T,CS_DONTCHANGE)
		if(team==CS_TEAM_CT)
			cs_set_user_team(id,CS_TEAM_CT,CS_DONTCHANGE)
		ExecuteHam(Ham_Spawn,id)
		cs_set_user_team(id,team,CS_DONTCHANGE)
	}
	return PLUGIN_HANDLED
}
/* ==================================================================================================== */
public vip(id)
{	
	show_motd(id,"vip.txt")
	
}
public showitem(id,itemname[],itemeffect[],Durability[])
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Przedmiot <br><font color=green>%s </center><br></font></td><td><b><font color=white><br><center>Wytrzymalosc<font color=%s> %i </font></center><br></td></table><br>",itemname,item_durability[id] > 150 ? "green":"red",item_durability[id])
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><br><center><b>%s</center><br></font></td></table><br>",itemeffect)
	
	formatex(header,sizeof header - 1,"Przedmiot")
	
	show_motd(id,motd,header)     	
}
public showczary(id,cotammasz[])
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><br><center><b>%s</center><br></font></td></table><br>",cotammasz)
	
	formatex(header,sizeof header - 1,"Przedmiot")
	
	show_motd(id,motd,header)     	
}
public showartefakt(id,itemname[],itemeffect[])
{
	new czasjaki,minuty,godziny	
	czasjaki = player_wytrzymalosc[id]
	godziny = czasjaki/3600
	minuty=  (player_wytrzymalosc[id]-godziny*3600)/60
	
	new Time[128], len1 = 0
	if (godziny>= 1)
	{
		len1 += format(Time[len1], 127 -len1, "%d godzin. ",godziny)
	}
	if (minuty>= 1)
	{
		len1 += format(Time[len1], 127 -len1, "%d minut. ", minuty)
	}
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Artefakt<br><font color=green>%s </center><br></font></td><td><b><font color=white><br><center>Czas Do Konca<font color=%s><br> %s </font></center><br></td></table><br>",itemname,godziny > 2 ? "green":"red",Time)
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><br><center><b>%s</center><br></font></td></table></center><br>",itemeffect)
	
	formatex(header,sizeof header - 1,"Przedmiot")
	
	show_motd(id,motd,header)     	
}

/* ==================================================================================================== */

public iteminfo(id)
{
	new itemEffect[200]
	
	new TempSkill[11]					//There must be a smarter way
	
	if (player_b_vampire[id] > 0) 
	{
		num_to_str(player_b_vampire[id],TempSkill,10)
		add(itemEffect,199,"Kradnie ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," hp gdy uderzysz wroga<br>")
	}
	if (player_b_ghost[id] > 0) 
	{
		num_to_str(player_b_ghost[id],TempSkill,10)
		add(itemEffect,199,"Mozesz przenikac przez sciany przez ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," sek.<br>")
	}
	if (player_b_grenade[id] > 0) 
	{
		num_to_str(player_b_grenade[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," szans na natychmiastowe zabicie granatem<br>")
	}
	if (player_b_damage[id] > 0) 
	{
		num_to_str(player_b_damage[id],TempSkill,10)
		add(itemEffect,199,"Zadaje ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," dodatkowe obrazenia za kazdym razem gdy uderzysz wroga<br>")
	}
	if (player_b_money[id] > 0) 
	{
		num_to_str(player_b_money[id],TempSkill,10)
		add(itemEffect,199,"Dadaje ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," zlota i w kazdej rundzie na start otrzymasz 50 zlota. Mozesz takze uzyc tego przedmiotu by zredukowac normalne obrazenia o 50%<br>")
	}
	if (player_b_gravity[id] > 0) 
	{
		num_to_str(player_b_gravity[id],TempSkill,10)
		add(itemEffect,199,"Wysoki skok jest zredukowany do ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,". Uzyj tego przedmiotu jak bedziesz w powietrzu. Uszkodzenia zaleza od wysokosci skoku i twojej sily<br>")
	}
	if (player_b_inv[id] > 0) 
	{
		num_to_str(player_b_inv[id],TempSkill,10)
		add(itemEffect,199,"Twoja widocznosc jest zredukowana z 255 do ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"<br>")
	}
	if (player_b_theif[id] > 0) 
	{
		num_to_str(player_b_theif[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/7 szans na okradniecie kogos z")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," zlota, za kazdym razem gdy uderzysz swojego wroga. Mozesz uzyc tego przedmiotu zeby zamienic 1000 zlota na 15 HP<br>")
	}
	if (player_b_respawn[id] > 0) 
	{
		num_to_str(player_b_respawn[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," szanse do odrodzenia sie po zgonie<br>")
	}
	if (player_b_heal[id] > 0) 
	{
		num_to_str(player_b_heal[id],TempSkill,10)
		add(itemEffect,199,"Zyskasz +")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," HP co kazde 5 sekund. Uzyj aby polozyc leczacy totem na 7 sekund<br>")
	}
	if (player_b_blind[id] > 0) 
	{
		num_to_str(player_b_blind[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"szans zeby twoj przeciwnik stracil wzrok<br>")
	}
	if (player_b_fireshield[id] > 0) 
	{
		num_to_str(player_b_fireshield[id],TempSkill,10)
		add(itemEffect,199,"Nie mozesz byc zabity przez chaos orb, hell orb albo firerope<br>")
		add(itemEffect,199,"Uzyj, zeby zadac obrazenia, spowolnic i oslepic kazdego wroga wokol ciebie<br>")
	}
	if (player_b_meekstone[id] > 0) 
	{
		num_to_str(player_b_meekstone[id],TempSkill,10)
		add(itemEffect,199,"Mozesz polozyc falszywa bombe uzywajac klawisz E. Gdy przeciwna druzyna zblizy sie do niej, wybuchnie zadajac obrazenia<br>")
	}
	if (player_b_redirect[id] > 0) 
	{
		num_to_str(player_b_redirect[id],TempSkill,10)
		add(itemEffect,199,"Obrazenia sa zredukowane o")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," hitpoints<br>")
	}
	if (player_b_fireball[id] > 0) 
	{
		num_to_str(player_b_fireball[id],TempSkill,10)
		add(itemEffect,199,"Mozesz wyczarowac ognista kule uzywajac tego przedmiotu. Zabije ona ludzi w zasiegu ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,". Im wiecej masz inteligencji tym wieksze zadasz obrazenia. Na nozu otrzymujesz dodatkowe kule<br>")
	}
	if (player_b_blink[id] > 0) 
	{
		add(itemEffect,199,"Mozesz teleportowac sie przez uzywanie alternatywnego ataku twoim nozem (PPM). Inteligencja zwieksza dystans teleportacji<br>")
	}
	if (player_b_sniper[id] > 0) 
	{
		num_to_str(player_b_sniper[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"na natychmiastowe zabicie przeciwnika ze scouta<br>")
	}
	if (player_b_masterele[id] > 0) 
	{
		num_to_str(player_b_masterele[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," szans na zadanie dodatkowych 20 +int/5 obrazen elektrycznych przy strzale<br>")
	}
	if (player_b_knife[id] > 0)
	{
		num_to_str(player_b_knife[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"na natychmiastowe zabicie przeciwnika z Noza (PPM)<br>")
	}
	if (player_b_awp[id] > 0)
	{
		num_to_str(player_b_awp[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"na natychmiastowe zabicie przeciwnika z Awp<br>")
	}
	if (player_b_firetotem[id] > 0)
	{
		num_to_str(player_b_firetotem[id],TempSkill,10)
		add(itemEffect,199,"Uzyj tego przedmiotu, zeby polozyc eksplodujacy totem na ziemie. Totem wybuchnie po 7 sekundach. I zapali osoby w zasiegu <br>")
		add(itemEffect,199,TempSkill)
	}
	if (player_b_darksteel[id] > 0)
	{
		num_to_str(player_b_darksteel[id],TempSkill,10)
		add(itemEffect,199,"Zadajesz dodatkowo ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," trafiajac wroga od tylu<br>")
	}
	if (player_b_kusza[id] > 0)
	{
		add(itemEffect, 199, "Masz mozliwosc uzywania kuszy Lowcy (noz + R).<br>")
	}
	if (player_b_odepch[id] > 0)
	{
		num_to_str(player_b_odepch[id],TempSkill,10)
		add(itemEffect,199,"Masz totem odpychajacy, ktory odpycha na ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," jednostek<br>")
	}
	if (player_ultra_armor[id]>0)
	{
		num_to_str(player_ultra_armor[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"na zatrzymanie wrogiego pocisku<br>")
	}
	if (player_b_zamroz[id] > 0)
	{
		add(itemEffect,199,"Uzyj, zeby polozyc zamrazajacy totem. Zatrzyma on twoich przeciwnikow<br>")
	}
	if (player_b_grawi[id] > 0)
	{
		add(itemEffect,199,"Uzyj, zeby polozyc totem zmiejszajacy grawitacje tobie i czlonkom twojej druzyny<br>")
	}
	if (player_b_blindtotem[id] > 0)
	{
		add(itemEffect,199,"Uzyj, aby polozyc totem, ktory trzesie ekranem przeciwnika<br>")
	}
	if (player_b_smierc[id] > 0)
	{
		add(itemEffect,199,"Uzyj, aby postawic totem, ktory zabija przeciwnikow<br>")
	}
	if (player_b_smierc2[id] > 0)
	{
		add(itemEffect,199,"Uzyj, aby postawic totem, ktory razi pradem wrogow (zabiera jednorazowo 50 hp)<br>")
	}
	if (player_b_redbull[id] > 0) 
	{
		add(itemEffect,199,"Masz Redbull'a, Doda Ci skrzydel (znacznie zmiejsza grawitacje)<br>")
	}
	if (player_b_4move[id] > 0)
	{
		num_to_str(player_b_4move[id],TempSkill,10)
		add(itemEffect,199,"Masz +")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"dodatkowej predkosci. Twoj bieg cichnie<br>")
	}
	if (player_b_silent[id] >0) 
	{
		add(itemEffect,199,"Twoj bieg cichnie<br>")
	}
	if (player_b_jumpx[id] > 0) 
	{
		num_to_str(player_b_jumpx[id],TempSkill,10)
		add(itemEffect,199,"Mozesz wykonac ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"skokow w powietrzu<br>")
	}
	if (player_b_buty[id] > 0) 
	{
		num_to_str(player_b_buty[id],TempSkill,10)
		add(itemEffect,199,"Masz ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," dodatkowych LongJump'ow<br>")
	}
	if (player_b_startaddhp[id] > 0)
	{
		num_to_str(player_b_startaddhp[id],TempSkill,10)
		add(itemEffect,199,"Zwieksza twoje bazowe Hp o ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," w kazdej rundzie<br>")
	}
	if (player_b_froglegs[id] > 0)
	{
		add(itemEffect,199,"Kucnij aby zrobic daleki skok<br>")
	}
	if (player_b_explode[id] > 0) 
	{
		num_to_str(player_b_explode[id],TempSkill,10)
		add(itemEffect,199,"Gdy umierasz wybuchniesz w promieniu ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," zadaje 75 obrazen wokol ciebie - im wiecej masz inteligencji tym wiekszy zasieg wybuchu<br>")
	}
	if (player_sword[id] > 0) 
	{
		num_to_str(player_sword[id],TempSkill,10)
		add(itemEffect,199,"Zadajesz dodatkowe ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," pkt. obrazen nozem<br>")
	}
	if(player_b_godmode[id] > 0)
	{
		num_to_str(player_b_godmode[id],TempSkill,10)
		add(itemEffect,199,"Uzyj tego przedmiotu, aby stac sie niesmiertelnym na ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," sek. <br>")
	}
	if (player_b_extrastats[id] > 0)
	{
		num_to_str(player_b_extrastats[id],TempSkill,10)
		add(itemEffect,199,"Zyskasz +")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," do wszystkich statystyk majac ten przedmiot<br>")
	}
	if (player_b_kasatotem[id] > 0)
	{
		num_to_str(player_b_kasatotem[id],TempSkill,10)
		add(itemEffect,199,"Uzyj tego przedmiotu, zeby polozyc totem dodajacy tobie i teamowi kase.")
	}
	if (player_b_weapontotem[id] > 0)
	{
		num_to_str(player_b_weapontotem[id],TempSkill,10)
		add(itemEffect,199,"Uzyj tego przedmiotu, zeby polozyc totem dodajacy tobie i teamowi wyposazenie.")
	}
	if (player_b_dajawp[id] > 0) 
    {
		add(itemEffect,199," Dostajesz AWP co runde <br>")
    }
	if (player_b_dajak[id] > 0) 
    {
		add(itemEffect,199," Dostajesz AK47 co runde <br>")
    }
		if (player_b_dajm4[id] > 0) 
    {
		add(itemEffect,199," Dostajesz M4A1 co runde <br>")
    }
	if (player_b_dajsg[id] > 0) 
    {
		add(itemEffect,199," Dostajesz SG552 co runde <br>")
    }
	if (player_b_dajaug[id] > 0) 
    {
		add(itemEffect,199," Dostajesz AUG co runde <br>")
    }
	if (player_b_exp[id] > 0)
	{
		num_to_str(floatround(player_b_exp[id]*100),TempSkill,10)
		add(itemEffect,199,"Expisz ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," % szybciej.<br>")
	}
	if (wear_sun[id] > 0)
	{
		add(itemEffect,199,"jestes odporny na flash'e<br>")
	}
	if (player_b_latarka[id] > 0)
	{
		add(itemEffect, 199, "Mo¿esz u¿ywaæ latarki aby odkrywac Ninje. <br>")
	}
	if (player_b_mine[id] > 0)
	{
		add(itemEffect,199,"Uzyj, zeby polozyc niewidzialna mine, ktora eksploduje z kontakcie z wrogiem. Dostajesz 3 miny co runde<br>")
	}
	if (player_b_fleshujtotem[id] > 0)
	{
		add(itemEffect,199,"Uzyj tego przedmiotu, zeby polozyc oslepiajacy totem na ziemie. Oslepi on wrogow w zasiagu 300<br>")
	}
	if (player_b_sidla[id] > 0)
	{
		num_to_str(player_b_sidla[id],TempSkill,10)
		add(itemEffect,199,"Masz 1/")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," szansy na unieruchomienie wroga przy strzale<br>")
	}
	if (player_b_antyhs[id] > 0) 
	{
		num_to_str(player_b_antyhs[id],TempSkill,10)
		add(itemEffect,199,"Jestes odporny na ataki w glowe<br>")
	}
	if (player_b_invknife[id] > 0) 
	{
		num_to_str(player_b_invknife[id],TempSkill,10)
		add(itemEffect,199,"Twoja widocznosc jest zredukowana z 255 do ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," jezeli masz wyciagniety noz.<br>")
	}
	if (player_b_killhp[id] > 0) 
	{
		num_to_str(player_b_killhp[id],TempSkill,10)
		add(itemEffect,199,"Dostajesz ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," Hp za kazde zabojstwo.<br>")
	}
	if (player_b_windwalk[id] > 0) 
	{
		num_to_str(player_b_windwalk[id],TempSkill,10)
		add(itemEffect,199,"Uzyj, zeby stac sie niewidzialny. W tym czasie nie bedziesz mogl atakowac, ale za to staniesz sie szybszy na ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," sekund<br>")
	}
	
	
	
	switch(player_item_id[id])
	{
		case 16:
		{
			add(itemEffect,199,"Wygladasz jak przeciwnik! Nie daj sie zdemaskowac!<br>")
		}
		case 132:
		{
			add(itemEffect,199,"Szybkosc Zredukowana o 35%. Dmg wieksze o 25%<br>")
		}
		case 131:
		{
			add(itemEffect,199,"Jesli nie widzisz przeciwnika nie jest w stanie zadac Ci obrazen<br>")
		}
		case 167:
		{
			add(itemEffect,199,"Mozesz wskrzeszac umarlych<br>")
		}
		case 185:
		{
			add(itemEffect,199,"Uzyj, aby polozyc totem, ktory przywoluje magiczna burze unieruchamiajaca wrogow<br>")
		}
	}
	new Durability[10]
	num_to_str(item_durability[id],Durability,9)
	if (equal(itemEffect,"")) showitem2(id,"None","Zabij kogos, aby dostac item albo kup (/rune)","None")
	if (!equal(itemEffect,"")) showitem2(id,player_item_name[id],itemEffect,Durability)
}
public ainfo(id)
{
	new itemEffect[200]
	
	new TempSkill[11]					//There must be a smarter way
	
	Sprawdzartefakt(id)
	
	if (a_silent[id]>0) 
	{
		add(itemEffect,199,"Twoj bieg cichnie<br>")
	}
	if (a_jump[id]>0) 
	{
		num_to_str(a_jump[id],TempSkill,10)
		add(itemEffect,199,"Mozesz wykonac ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," skoki w powietrzu<br>")
	}
	if (a_money[id]>0)
	{
		num_to_str(a_money[id],TempSkill,10)
		add(itemEffect,199,"Dostajesz ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," dodatkowych $ co runde<br>")
	}
	if (a_inv[id]>0) 
	{
		num_to_str(a_inv[id],TempSkill,10)
		add(itemEffect,199,"Widocznosc zredukowana do ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199,"/255 jednostek (nie sumuje sie z mocami klas i itemow)<br>")
	}
	if (a_noz[id]>0.0)
	{
		num_to_str(floatround(a_noz[id]*100),TempSkill,10)
		add(itemEffect,199,"Czas ladowania mocy nozowej wynosi <br>")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," procent<br>")
	}
	if (a_spid[id]>0) 
	{
		num_to_str(a_spid[id],TempSkill,10)
		add(itemEffect,199,"Predkosc zwiekszona o ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," jednostek<br>")
	}
	if (a_wearsun[id]>0) 
	{
		add(itemEffect,199,"Jestes odporny na flash'e")
	}
	if (a_heal[id]>0) 
	{
		num_to_str(a_heal[id],TempSkill,10)
		add(itemEffect,199,"Regenerujesz ")
		add(itemEffect,199,TempSkill)
		add(itemEffect,199," zycia co kazde 3 sek.<br>")
	}
	
	if (equal(itemEffect,"")) showartefakt(id,artefakt_info[player_artefakt[id]],"Zabij ,aby dostac Artefakt")
	if (!equal(itemEffect,"")) showartefakt(id,artefakt_info[player_artefakt[id]],itemEffect)
}
/* ==================================================================================================== */

public award_item(id, itemnum)
{
	if(random_num(1,50) == 1){
		dajartefakt(id,0)
	}
	if (player_item_id[id] != 0)
		return PLUGIN_HANDLED
	
	set_hudmessage(220, 115, 70, -1.0, 0.40, 0, 3.0, 4.0, 0.2, 0.3, -1)
	new rannum = random_num(1,97)
	
	if (itemnum > 0) rannum = itemnum
	else if (itemnum < 0) return PLUGIN_HANDLED
		
	item_durability[id] = 250
	switch(rannum)
	{
		case 1:
		{
			player_item_name[id] = "Sejmitar"
			player_item_id[id] = rannum
			player_b_damage[id] = random_num(3,6)
			show_hudmessage(id, "Znalazles przedmiot: %s :: dodaje obrazenia +%i",player_item_name[id],player_b_damage[id])
		}
		case 2:
		{
			player_item_name[id] = "Rdzawy Uchwyt"
			player_item_id[id] = rannum
			player_b_vampire[id] = random_num(3,6)
			player_b_damage[id] = random_num(3,5)
			show_hudmessage(id, "Znalazles przedmiot: %s :: wysysasz %i hp przeciwnikowi",player_item_name[id],player_b_vampire[id])
		}
		case 3:
		{
			player_item_name[id] = "Wigor Boga Gromow"
			player_item_id[id] = rannum
			player_b_money[id] = random_num(1200,2000)
			show_hudmessage(id, "Znalazles przedmiot: %s :: dostajesz %i zloto w kazdej rundzie. Uzyj, aby chronil cie.",player_item_name[id],player_b_money[id]+player_intelligence[id]*50)	
		}
		case 4:
		{
			player_item_name[id] = "Skrzydla Aniola"
			player_item_id[id] = rannum
			player_b_gravity[id] = random_num(4,6)
			item_durability[id] = 200
			
			if (is_user_alive(id))
				set_gravitychange(id)

			show_hudmessage(id, "Znalazles przedmiot: %s :: +%i premia wyzszego skoku - Wcisnij e zeby uzyc",player_item_name[id],player_b_gravity[id])	
		}
		case 5:
		{
			player_item_name[id] = "Skrzydla Archaniola"
			player_item_id[id] = rannum
			player_b_gravity[id] = random_num(7,11)
			item_durability[id] = 200
			
			if (is_user_alive(id))
				set_gravitychange(id)

			
			show_hudmessage(id, "Znalazles przedmiot: %s :: +%i premia wyzszego skoku - Wcisnij e zeby uzyc",player_item_name[id],player_b_gravity[id])	
		}
		case 6:
		{
			player_item_name[id] = "Buty Eteryczne"
			player_item_id[id] = rannum
			player_b_inv[id] = random_num(100,150)
			show_hudmessage(id, "Znalazles przedmiot: %s :: +%i premii niewidocznosci",player_item_name[id],255-player_b_inv[id])			
		}
		case 7:
		{
			player_item_name[id] = "Podroznik"
			player_item_id[id] = rannum
			player_b_theif[id] = random_num(300,600)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/7 szans by ukrasc %i zlota jak uderzasz wroga. Uzyj zeby zamienic zloto w zycia",player_item_name[id],player_b_theif[id])	
		}
		case 8:
		{
			player_item_name[id] = "Kamien Jordana"
			player_item_id[id] = rannum
			player_b_respawn[id] = random_num(3,4)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/%i szans do ponownego odrodzenia sie po smierci",player_item_name[id],player_b_respawn[id])	
		}
		case 9:
		{
			player_item_name[id] = "Oblicze Andariel"
			player_item_id[id] = rannum
			player_b_heal[id] = random_num(20,30)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Regeneruje %i hp co kazde 5 sekund. Uzyj, zeby polozyc totem ktory bedzie leczyl wszystkich graczy z teamu",player_item_name[id],player_b_heal[id])	
		}
		case 10:
		{
			player_item_name[id] = "Ostrze Ali Baby"
			player_item_id[id] = rannum
			player_b_blind[id] = random_num(2,5)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/%i szans na utrate wzroku kiedy uszkadzasz wroga",player_item_name[id],player_b_blind[id])	
		}
		case 11:
		{
			player_item_name[id] = "Pochodnia Piekielnego Ognia"
			player_item_id[id] = rannum
			player_b_fireshield[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Chroni od natychmiastowego zabicia HE i orbami. Wcisnij e zeby go uzyc",player_item_name[id],player_b_fireshield[id])	
		}
		case 12:
		{
			player_item_name[id] = "Szpikoczlap"
			player_item_id[id] = 16
			player_b_silent[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Twoj bieg cichnie oraz wygladasz jak przeciwnik",player_item_name[id])	
		}
		case 13:
		{
			player_item_name[id] = "Fantom Smierci"
			player_item_id[id] = rannum
			player_b_meekstone[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, aby podlozyc sztuczna bombe, uzyj ponownie aby ja zdetonowac",player_item_name[id])
		}
		case 14:
		{
			player_item_name[id] = "Skorzana Zbroja"
			player_item_id[id] = rannum
			player_b_redirect[id] = random_num(7,12)
			show_hudmessage(id, "Znalazles przedmiot: %s :: +%i obniza uszkodzenia zadawane graczowi",player_item_name[id],player_b_redirect[id])	
		}
		case 15:
		{
			player_item_name[id] = "Mewa"
			player_item_id[id] = rannum
			player_sword[id] = 40
			show_hudmessage(id, "Znalazles przedmiot: %s :: zadajesz wieksze obrazenia nozem",player_item_name[id])		
		}
		case 16:
		{
			player_item_name[id] = "Szarza"
			player_item_id[id] = 15
			player_b_froglegs[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Kucnij na 3 sekundy, a zrobisz dlugi skok",player_item_name[id])	
		}
		case 17:
		{
			player_item_name[id] = "Oko Khalima"
			player_item_id[id] = 1
			player_b_sniper[id] = random_num(3,5)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/%i szans do natychmiastowego zabicia scoutem",player_item_name[id],player_b_sniper[id])	
		}
		case 18:
		{
			player_item_name[id] = "Pieczec Cathana"
			player_item_id[id] = rannum
			player_b_firetotem[id] = random_num(250,400)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, aby polozyc wybuchowy totem ognia",player_item_name[id])	
		}
		case 19:
		{
			player_item_name[id] = "Kolcze Rekawiczki"
			player_item_id[id] = rannum
			player_b_darksteel[id] = random_num(15,20)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dodatkowe uszkodzenia, gdy trafisz kogos od ty³u",player_item_name[id])	
		}
		case 20:
		{
			player_item_name[id] = "Wampiryczny Kostur"
			player_item_id[id] = rannum
			player_b_vampire[id] = random_num(8,12)
			show_hudmessage(id, "Znalazles przedmiot: %s :: wysysasz %i hp przeciwnikowi",player_item_name[id],player_b_vampire[id])	
		}
		case 21:
		{
			player_item_name[id] = "Pierscien Ducha"
			player_item_id[id] = rannum
			player_b_blink[id] = floatround(halflife_time())
			player_b_froglegs[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Twoj noz pozwala ci teleportowac sie co 3 sekundy i zrobic dlugi skok jak kucniesz na 3 sekundy",player_item_name[id])
		}
		case 22:	
		{
			player_item_name[id] = "Pierscien Czarodziejki"
			player_item_id[id] = rannum
			player_b_fireball[id] = random_num(50,80)
			fired[id]++
			show_hudmessage(id, "Znalazles przedmiot : %s :: Ten przedmiot dodaje ci +5 inteligencji i robi ognista kule, wcisnij E aby uzyc",player_item_name[id])
		}	
		case 23:	
		{
			player_item_name[id] = "Pierscien Nekromanty"
			player_item_id[id] = rannum
			player_b_respawn[id] = random_num(2,4)
			player_b_vampire[id] = random_num(2,6)
			show_hudmessage(id, "Znalazles przedmiot : %s :: Dzieki temu itemowi masz 1/%i szansy na ponowne odrodzenie sie i wysysasz %i zycia wrogowi za kazdym strzalem",player_item_name[id],player_b_respawn[id],player_b_vampire[id])
		}
		case 24:
		{
			player_item_name[id] = "Pierscien Paladyna"
			player_item_id[id] = rannum	
			player_b_redirect[id] = random_num(7,15)
			player_b_blind[id] = random_num(3,4)
			show_hudmessage(id, "Znalazles przedmiot : %s :: Redukuje normalne obrazenia o %i i masz 1/%i szansy na oslepienie wroga",player_item_name[id],player_b_redirect[id],player_b_blind[id])		
		}
		case 25:
		{
			player_item_name[id] = "Pierscien Druida"
			player_item_id[id] = rannum	
			player_b_grenade[id] = random_num(1,3)
			player_b_heal[id] = random_num(20,25)
			show_hudmessage(id, "Znalazles przedmiot : %s :: Masz 1/%i szansy na natychmiastowe zabicie z HE. Twoje hp bedzie sie regenerowac o %i co 5 sekund oraz mozesz polozyc leczacy totem na 7 sekund",player_item_name[id],player_b_grenade[id],player_b_heal[id])
		}	
		case 26:
		{
			player_item_name[id] = "Straz Tal Rasha"	
			player_item_id[id] = 16
			changeskin(id,0)  
			show_hudmessage (id, "Znalazles przedmiot : %s :: Wygladasz jak przeciwnik",player_item_name[id])
		}
		case 27:
		{
			player_item_name[id] = "Pierscieniowa Zbroja"	
			player_item_id[id] = rannum
			player_ultra_armor[id]=random_num(3,6)
			player_ultra_armor_left[id]=player_ultra_armor[id]
			show_hudmessage (id, "Znalazles przedmiot : %s :: Twoj pancerz moze odbic do %i pociskow",player_item_name[id],player_ultra_armor[id])
		}
		case 28:
		{
			player_item_name[id] = "Okulus"	
			player_item_id[id] = rannum
			player_b_blind[id] = random_num(1,5)
			player_b_heal[id] =  random_num(10,15)
			show_hudmessage (id, "Znalazles przedmiot : %s :: Masz 1/%i na oslepienie wroga, leczy %i hp, wcisnij E aby leczyl wszystkich wkolo",player_item_name[id],player_b_blind[id],player_b_heal[id])
		}
		case 29:
		{
			player_item_name[id] = "Siekacz Bartuca"
			player_item_id[id] = rannum
			player_b_sniper[id] = random_num(1,3)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/%i szans do natychmiastowego zabicia scoutem",player_item_name[id],player_b_sniper[id])	
		}
		case 30:
		{
			player_item_name[id] = "Ksiega Lam Esana"
			player_item_id[id] = rannum
			player_b_respawn[id] = random_num(1,4);
			player_b_inv[id] = random_num(80,150);
			show_hudmessage(id, "Znalazles przedmiot: %s :: Masz 1/%i szans na odrodzenie sie po smierci. Widocznosc zredukowana do %d", player_item_name[id], player_b_respawn[id], player_b_inv[id])
		}
		case 31:
		{
			player_item_name[id] = "Fortuna Gheeda"
			player_item_id[id] = rannum
			player_b_money[id] = random_num(2000,3000)
			show_hudmessage(id, "Znalazles przedmiot: %s :: dostajesz %i zloto w kazdej rundzie. Uzyj, zeby chronil cie.",player_item_name[id],player_b_money[id]+player_intelligence[id]*50)	
		}
		case 32:
		{
			player_item_name[id] = "Sidla"
			player_b_hook[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, aby rzucic hakiem, ktory przyciaga wrogow",player_item_name[id])
		}
		case 33:
		{
			player_item_name[id] = "Swiatlo Niebios"
			player_item_id[id] = rannum
			player_b_fleshujtotem[id] = random_num(250,400)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, aby polozyc totem oslepiajacy wroga",player_item_name[id])	
		}
		case 34:
		{
			player_item_name[id] = "Sila Wiatru"	
			player_item_id[id] = rannum
			player_b_kusza[id] = 1
			show_hudmessage(id, "Znalazles przedmiot : %s :: Mo¿esz u¿ywaæ kuszy jak¹ posiada Lowca (wybierz noz i kliknij R)", player_item_name[id])
		}
		case 35:
		{
			player_item_name[id] = "Rozpruwacz"
			player_item_id[id] = rannum
			player_b_knife[id] = random_num(2,4)
			show_hudmessage(id, "Znalazles przedmiot : %s :: 1/%i szans do natychmiastowego zabicia z Noza",player_item_name[id],player_b_knife[id])
		}
		case 36:
		{
			player_item_name[id] = "Zolwia skorupa"
			player_item_id[id] = rannum
			player_b_damage[id] = 6
			player_b_redirect[id] = random_num(5, 10)
			player_b_blink[id] = 1
			show_hudmessage (id, "Znalazles przedmiot : %s :: + %i do obrazen, otrzymujesz %i mniej obrazen, mozesz teleportowac sie za pomoca swojego noza (PPM)",player_item_name[id],player_b_damage[id],player_b_redirect[id])
		}
		case 37:
		{
			player_item_name[id] = "AWP Skill"
			player_item_id[id] = rannum
			player_b_awp[id] = random_num(1,4)
			show_hudmessage (id, "Znalazles przedmiot : %s :: 1/%i szans na natychmiastowe zabicie z AWP",player_item_name[id],player_b_awp[id])
		}
		case 38:
		{
			player_item_name[id] = "Awatar Trang-Oula"
			player_item_id[id] = 17
			player_b_inv[id] = 6	
			if(player_class[id]!=Hunter){
				player_b_kusza[id] = 1
			}
			if (is_user_alive(id)) set_user_health(id,5)	
			show_hudmessage (id, "Znalazles przedmiot : %s :: Masz 5 HP, widocznosc zredukowana do %i, mozesz uzywac kuszy lowcy (noz + R)",player_item_name[id],255-player_b_inv[id])
		}

		case 39:
		{
			player_item_name[id] = "Prastary Slad Naja"
			player_item_id[id] = rannum
			player_b_latarka[id] = 1
			show_hudmessage(id, "Znalazles przedmiot : %s :: Mozesz uzywac latarki aby odkrywac Ninje", player_item_name[id])
		}
		case 40:
		{
			player_item_name[id] = "Nova Mrozu"
			player_item_id[id] = rannum
			player_b_zamroz[id]=1
			show_hudmessage (id, "Znalazles przedmiot : %s :: uzyj aby polozyc totem zamrazajacy wrogow",player_item_name[id])
		}
		case 41:
		{
			player_item_name[id] = "Pajeczy Ksiezyc"
			player_item_id[id] = rannum
			player_b_grawi[id]=1
			show_hudmessage (id, "Znalazles przedmiot : %s :: Tworzy totem zmiejszajacy grawitacje tobie i czlonkom twojej druzyny",player_item_name[id])
		}
		case 42:
		{
			player_item_name[id] = "Nieskonczonosc"
			player_item_id[id] = rannum
			player_b_inv[id] = 140
			if(player_class[id]!=Hunter){
				player_b_kusza[id] = 1
			}
			player_b_jumpx[id] = 3
			show_hudmessage (id, "Znalazles przedmiot : %s :: Mozesz wykonac 3 skoki w powietrzu, poziadasz kusze lowcy (noz + R), widocznosc zredukowana do %i",player_item_name[id],255-player_b_inv[id])
		}
		case 43:
		{
			player_item_name[id] = "Dusza Natalii"
			player_item_id[id] = 16
			changeskin(id,0)  
			player_b_damage[id] = random_num(5,10)
			player_b_silent[id] = 1
			show_hudmessage (id, "Znalazles przedmiot : %s :: Wygladasz jak Przeciwnik, +%i do obrazen, cicho biegasz",player_item_name[id],player_b_damage[id])
		}
		case 44:
		{
			player_item_name[id] = "Fazowe Ostrze"
			player_item_id[id] = rannum
			player_b_knife[id] = random_num(2,3)
			show_hudmessage (id, "Znalazles przedmiot : %s :: 1/%i szansy na natychmiastowe zabicie z noza",player_item_name[id],player_b_knife[id])
		}
		
		case 45:
		{
			player_item_name[id] = "Miny Zabojczyni"
			player_item_id[id] = rannum
			player_b_mine[id] = 3
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, zeby polozyc niewidzialna mine",player_item_name[id])
		}
		case 46:
		{
			player_item_name[id] = "Skok"
			player_item_id[id] = rannum
			player_b_redbull[id] = 1
			
			if (is_user_alive(id))
				set_gravitychange(id)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Bardzo niska grawitacja",player_item_name[id])
		}
		case 47:
		{
			player_item_name[id] = "Tancerz Cieni"
			player_item_id[id] = 132
			player_b_silent[id] = 1
			if (is_user_alive(id)) 
				set_speedchange(id)
			show_hudmessage(id, "Znalazles przedmiot: %s :: +25% do obrazen, szybkosc zredukowana o 35%, nie slychac twoich krokow",player_item_name[id])
		}
		case 48:
		{
			player_item_name[id] = "Moc Krola Lisz"
			player_item_id[id] = rannum
			player_b_smierc[id]=1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj, aby polozyc tetem zabijajac wrogow!",player_item_name[id])
		}
		case 49:
		{
			player_item_name[id] = "Wygnanie"
			player_item_id[id] = rannum
			player_b_blindtotem[id]=1	
			show_hudmessage(id, "Znalazles przedmiot: %s :: uzyj aby polozyc totem, ktory dezorientuje wrogow",player_item_name[id])
		}
		case 50:
		{
			player_item_name[id] = "Szyszak"
			player_item_id[id] = rannum
			player_b_antyhs[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Jestes odporny na ataki w glowe",player_item_name[id])
		}
		case 51:
		{
			player_item_name[id] = "Jadeitowe Ostrze"
			player_item_id[id] = rannum
			player_b_invknife[id] = 40
			show_hudmessage(id, "Znalazles przedmiot: %s :: Widocznosc zredukowana do %i, kiedy masz wyciagniety noz",player_item_name[id],player_b_invknife[id])
		}
		case 52:
		{
			player_item_name[id] = "Oslona Cienia"
			player_item_id[id] = rannum
			player_b_windwalk[id] = 5
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj aby stac sie niewidzialnym na %i, sek, w tym czasnie nie bedziesz mogl atakowac, ale staniesz sie szybszy",player_item_name[id],player_b_windwalk[id])
		}
		case 53:
		{
			player_item_name[id] = "Elektryczne Strzaly"
			player_item_id[id] = rannum
			player_b_masterele[id] = random_num(4,7)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Masz 1/%i na zadanie dodatkowych 20+int/5 obrazen",player_item_name[id], player_b_masterele[id])
		}
		case 54:
		{
			player_item_name[id] = "Buty Paladyna"
			player_item_id[id] = rannum
			player_b_buty[id] = random_num(5,10)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz %i LongJump'ow co runde",player_item_name[id], player_b_buty[id])
		}
		case 55:
		{
			player_item_name[id] = "Eteryczne Buty Paladyna"
			player_item_id[id] = rannum
			player_b_buty[id] = random_num(10,30)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz %i LongJump'ow co runde",player_item_name[id], player_b_buty[id])
		}
		case 56:
		{
			player_item_name[id] = "Mroczna Burza"
			player_item_id[id] = 185
			show_hudmessage(id, "Znalazles przedmiot: %s :: uzyj aby polozyc totem, ktory wywola burze i unieruchamia wrogow",player_item_name[id])
		}
		case 57:
		{
			player_item_name[id] = "Sily Natury"
			player_item_id[id] = rannum
			player_b_killhp[id] = 25
			player_b_startaddhp[id] = 50
			show_hudmessage(id, "Znalazles przedmiot: %s :: Leczysz %i Hp za kazde zabojstwo, +%i dodatkowego Hp co runde",player_item_name[id],player_b_killhp[id],player_b_startaddhp[id])
		}
		case 58:
		{
			player_item_name[id] = "Mikstura Zycia"
			player_item_id[id] = rannum
			player_b_startaddhp[id] = 50
			show_hudmessage(id, "Znalazles przedmiot: %s :: Bazowe Hp zwiekszone o %i",player_item_name[id], player_b_startaddhp[id])
		}
		case 59:
		{
			player_item_name[id] = "Electro Sila"
			player_item_id[id] = rannum
			player_b_smierc2[id]=1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj aby polozyc totem zadajacy wrogom obrazenia elektryczne",player_item_name[id])
		}
		case 60:
		{
			player_item_name[id] = "Podrecznik Nekromanty"
			player_item_id[id] = 167
			player_b_respawn[id] = 1
			g_haskit[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Mozesz wskrzeszac umarlych, Masz 1/%i szansy na zrespienie sie po smierci",player_item_name[id], player_b_respawn[id])
		}
		case 61:
		{
			player_item_name[id] = "Wieksza Mikstura Zycia"
			player_item_id[id] = rannum
			player_b_startaddhp[id] = 80	
		}
		case 62:
		{
			player_item_name[id] = "Pierscien Doswiadczenia"
			player_item_id[id] = rannum
			item_durability[id] = 200
			player_b_exp[id] = 0.3
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz %0.0f%% wiecej doswiadczenia za fraga", player_item_name[id], player_b_exp[id]*100)
		}
		case 63:
		{
			player_item_name[id] = "Silna Wola"
			player_item_id[id] = rannum
			player_b_odepch[id]=random_num(255,480)
		}
		case 64:
		{
			player_item_name[id] = "Okowa Grozy"
			player_item_id[id] = rannum
			player_b_money[id] = random_num(1000,1500)
		}
		case 65:
		{
			player_item_name[id] = "Chwyt Drakuli"
			player_item_id[id] = rannum
			player_b_vampire[id] = random_num(8,10)
		}
		case 66:
		{
			player_item_name[id] = "Tancerz Cieni"
			player_item_id[id] = 132
			player_b_4move[id] = 130
			player_b_silent[id] = 1
			if (is_user_alive(id)) 
				set_speedchange(id)
		}
		case 67:
		{
			player_item_name[id] = "Skorupa Duriela"
			player_item_id[id] = 131
		}
		case 68:
		{
			player_item_name[id] = "Oblicze Grozy"
			player_item_id[id] = rannum
			player_b_sidla[id] = random_num(4,10)

			show_hudmessage(id, "Znalazles przedmiot: %s :: Masz 1/%i szansy na unieruchomienie wroga ",player_item_name[id],player_b_sidla[id])
		}
		case 69:
		{
			player_item_name[id] = "Zwoj Inifussa"
			player_item_id[id] = rannum
			player_b_extrastats[id] = 10
		}
		case 70:
		{
			player_item_name[id] = "Mallus Horadrimow"
			player_item_id[id] = rannum
			player_b_damage[id] = random_num(6,8)		
			player_ultra_armor[id] = 3
			player_ultra_armor_left[id]=player_ultra_armor[id]

			show_hudmessage(id, "Znalazles przedmiot: %s :: Dodaje obrazenia +%i, Twoj pancerz moze odbic do %i pociskow. ",player_item_name[id],player_b_damage[id],player_ultra_armor[id])	
		}
		case 71:
		{
			player_item_name[id] = "Dziennik Horazona"
			player_item_id[id] = rannum
			player_b_meekstone[id] = 1
		}
		case 72:
		{
			player_item_name[id] = "Aura Paladyna"
			player_item_id[id] = rannum
			player_b_redirect[id] = random_num(10,12)
		}
		case 73:
		{
			player_item_name[id] = "Dwureczny Topor Barbarzyncy"
			player_item_id[id] = rannum
			player_b_blink[id] = floatround(halflife_time())
			player_ultra_armor[id]=random_num(3,5)
			player_ultra_armor_left[id]=player_ultra_armor[id]
			player_b_damage[id] = random_num(3,6)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Mozesz sie teleportowac na nozu, twoj pancerz odbije do %i pociskow, zadawane obrazenia zwiekszone o %i", player_item_name[id],player_ultra_armor[id],player_b_damage[id])
		}
		case 74:
		{
			player_item_name[id] = "Ostateczna Esencja Zniszczenia"
			player_item_id[id] = rannum
			item_durability[id] = 100
			player_b_firetotem[id] = random_num(250,350)
			player_b_grenade[id] = 1
			player_b_awp[id] = 2
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/1 do natychmiastowego zabicia z He oraz 1/2 do natychmiastowego zabicia z AWP. Uzyj aby podlozyc wybuchowy totem ognia.", player_item_name[id])
		}
		case 75:
		{
			player_item_name[id] = "Infinity"
			player_item_id[id] = rannum
			item_durability[id] = 100
			player_b_awp[id] = random_num(1,3)
			player_b_grenade[id] = random_num(3,4)
			player_b_sniper[id] = random_num(1,3)
			show_hudmessage(id, "Znalazles przedmiot: %s :: 1/%i szans do natychmiastowego zabicia z awp,1/%i z he,1/%i z scouta",player_item_name[id],player_b_awp[id],player_b_grenade[id],player_b_sniper[id])
		}
		case 76:
		{
			player_item_name[id] = "Apocalypse Anihilation"
			player_item_id[id] = rannum
			player_b_damage[id] = 10
			player_b_silent[id] = 1
			item_durability[id] = 200
			show_hudmessage (id, "Znalazles przedmiot : %s :: Masz %i dodatkowych obrazen oraz cicho biegasz",player_item_name[id],player_b_damage[id])
		}
		case 77:
		{
			player_item_name[id] = "Ropiejaca Esencja Destrukcji"
			player_item_id[id] = rannum
			player_b_respawn[id] = 2
			player_b_sniper[id] = random_num(2,3)
			player_b_grenade[id] = random_num(1,4)
			show_hudmessage (id, "Znalazles przedmiot : %s :: Masz 1/2 na odrodzenie sie, 1/%i na natychmiastowe zabicie z scouta oraz 1/%i na zabicie z HE",player_item_name[id],player_b_sniper[id],player_b_grenade[id])
		}
		case 78:
		{
			player_item_name[id] = "Jadeitowa Figurka"
			player_item_id[id] = rannum
			player_b_heal[id] = random_num(20,25)
			player_b_redirect[id] = random_num(6,8)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Obrazenia sa zredukowane o %i. Regeneruje %i hp co kazde 5 sekund. Uzyj, zeby polozyc totem ktory bedzie leczyl wszystkich graczy z teamu",player_item_name[id],player_b_redirect,player_b_heal[id])
		}
		case 79:
		{
			player_item_name[id] = "Gidbin"
			player_item_id[id] = rannum
			player_b_damage[id] = random_num(6, 8)
			player_b_vampire[id] = random_num(6,8)
			show_hudmessage(id, "Znalazles przedmiot: %s :: wysysasz %i hp przeciwnikowi, dodaje obrazenia +%i",player_item_name[id],player_b_vampire[id],player_b_damage[id])
		}
		case 80:
		{
			player_item_name[id] = "Mlot Kowala Hefasto"
			player_item_id[id] = rannum
			player_b_jumpx[id] = 4
			player_b_grenade[id] = 2
			player_b_knife[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dodatkowe 4 skoki w powietrzu. 1/2 do natychmiastowego zabicia z He oraz 1/1 do natychmiastowego zabicia z noza",player_item_name[id],player_b_explode[id])	
		}
		case 81:
		{
			player_item_name[id] = "Mallus Horadrimow"
			player_item_id[id] = rannum
			player_b_damage[id] = random_num(6,10)
			player_ultra_armor[id] = 3
			player_ultra_armor_left[id]=player_ultra_armor[id]

			show_hudmessage(id, "Znalazles przedmiot: %s :: Dodaje obrazenia +%i, Twoj pancerz moze odbic do %i pociskow. ",player_item_name[id],player_b_damage[id],player_ultra_armor[id])	
		}
		case 82:
		{
			player_item_name[id] = "Dziennik Horazona"
			player_item_id[id] = rannum
			player_b_vampire[id] = 8
			player_b_startaddhp[id] = 80
		}
		case 83:
		{
			player_item_name[id] = "Jadeitowa Figurka"
			player_item_id[id] = rannum
			player_b_heal[id] = random_num(20,22)
			player_b_redirect[id] = random_num(6,10)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Obrazenia sa zredukowane o %i. Regeneruje %i hp co kazde 5 sekund. Uzyj, zeby polozyc totem ktory bedzie leczyl wszystkich graczy z teamu",player_item_name[id],player_b_redirect,player_b_heal[id])
		}
		case 84:
		{
			player_item_name[id] = "Duch"
			player_item_id[id] = rannum
			player_b_ghost[id] = random_num(7,10)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Mozesz przenikac przez sciany przez %i sek.",player_item_name[id],player_b_ghost[id])
		}
		case 85:
		{
			player_item_name[id] = "Duch Wiecznosci"
			player_item_id[id] = rannum
			player_b_ghost[id] = random_num(15,20)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Mozesz przenikac przez sciany przez %i sek.",player_item_name[id],player_b_ghost[id])
		}
		case 86:
		{
			player_item_name[id] = "Szal Barbarzyncy"
			player_item_id[id] = rannum
			player_b_godmode[id] = random_num(3,4)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj aby stac sie niesmiertelnym na %i sek.",player_item_name[id],player_b_godmode[id])
		}
		case 87:
		{
			player_item_name[id] = "Pekniety Szafir"
			player_item_id[id] = rannum
			player_b_extrastats[id] = random_num(2,4)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Zyskasz +%i do statystyk majac ten przedmiot", player_item_name[id],player_b_extrastats[id])
		}
		case 88:
		{
			player_item_name[id] = "Szafir ze skaza"
			player_item_id[id] = rannum
			player_b_extrastats[id] = random_num(5,10)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Zyskasz +%i do statystyk majac ten przedmiot", player_item_name[id],player_b_extrastats[id])
		}
		case 89:
		{
			player_item_name[id] = "Szafir Doskonaly"
			player_item_id[id] = rannum
			player_b_extrastats[id] = random_num(10,15)
			player_b_vampire[id] = random_num(4,7)
			show_hudmessage(id, "Znalazles przedmiot: %s :: Zyskasz +%i do statystyk majac ten przedmiot, wysysasz %i Hp strzelajac w wroga", player_item_name[id],player_b_extrastats[id],player_b_vampire[id])
		}
		case 90:
		{
			player_item_name[id] = "Esencja Bogactwa"
			player_item_id[id] = rannum
			player_b_kasatotem[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj aby polozyc totem dajacy kase tobie i twojemu teamowi", player_item_name[id])
		}
		case 91:
		{
			player_item_name[id] = "Runiczny Totem"
			player_item_id[id] = rannum
			player_b_weapontotem[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Uzyj aby polozyc totem dajacy bron tobie i twojemu teamowi", player_item_name[id])
		}
		case 92:
		{
			player_item_name[id] = "Blogoslawienstwo Mrocznych"	
			player_item_id[id] = rannum	
			wear_sun[id] = 1
			show_hudmessage (id, "Znalazles przedmiot: %s :: Flashbangi na ciebie nie dzialaja",player_item_name[id])
		}
		case 93:
		{
			player_item_name[id] = "Runa Mal"
			player_item_id[id] = rannum
			item_durability[id] = 150
			player_b_dajm4[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz darmowe M4 co runde", player_item_name[id])
		}
		case 94:
		{
			player_item_name[id] = "Runa Amn"
			player_item_id[id] = rannum
			item_durability[id] = 150
			player_b_dajak[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz darmowe AK co runde", player_item_name[id])
		}
		case 95:
		{
			player_item_name[id] = "Runa Sol"
			player_item_id[id] = rannum
			item_durability[id] = 150
			player_b_dajsg[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz darmowe SG552 co runde", player_item_name[id])
		}
		case 96:
		{
			player_item_name[id] = "Runa Nef"
			player_item_id[id] = rannum
			item_durability[id] = 150
			player_b_dajaug[id] = 1
			show_hudmessage(id, "Znalazles przedmiot: %s :: Dostajesz darmowego AUG'a co runde", player_item_name[id])
		}
		case 97:
		{
			player_item_name[id] = "Runa Zod"
			player_item_id[id] = rannum
			player_b_dajawp[id] = 1
			show_hudmessage(id, "Znalazles przedmiot : %s :: Dostajesz darmowe AWP co runde.", player_item_name[id])
		}
	}
	
	if(ile_wykonano[id]>=26)
		item_durability[id] += 50
	else if(ile_wykonano[id]>=3)
		item_durability[id] += 25
		
	if(player_b_extrastats[id] > 0)
		BoostStats(id,player_b_extrastats[id])
		
	if(quest_gracza[id] != -1){
		switch(quest_gracza[id]){
			case 2:{
				if(player_item_id[id] == 69)
					ile_juz[id]++
			}
			case 4:{
				if(player_item_id[id] == 81 || player_item_id[id] == 70)
					ile_juz[id]++
			}
			case 10:{
				if(player_item_id[id] == 82 || player_item_id[id] == 71)
					ile_juz[id]++
			}
			//////////
			case 12:{
				if(player_item_id[id] == 83 || player_item_id[id] == 78)
					ile_juz[id]++
			}
			case 13:{
				if(player_item_id[id] == 79)
					ile_juz[id]++
			}
			case 15:{
				if(player_item_id[id] == 30)
					ile_juz[id]++
			}
			case 19:{
				if(player_item_id[id] == 80)
					ile_juz[id]++
			}
		}
	}
	if(ile_juz[id] == questy[quest_gracza[id]][1])
		questy_nagrody(id)
	
	return PLUGIN_CONTINUE     
}        
public dajartefakt(id, itemnum1)
{
	if (player_artefakt[id] != 0)
		return PLUGIN_HANDLED
	
	new rannum = random_num(1,20)
	if (itemnum1 > 0) rannum = itemnum1
	else if (itemnum1 < 0) return PLUGIN_HANDLED
		
	switch(rannum)
	{
		case 1:
		{
			player_artefakt[id] = 1
			player_wytrzymalosc[id] = 2000
		}
		case 2:
		{
			player_artefakt[id] = 2
			player_wytrzymalosc[id] = 2000
		}
		case 3:
		{
			player_artefakt[id] = 3
			player_wytrzymalosc[id] = 2000
		}
		case 4:
		{
			player_artefakt[id] = 4
			player_wytrzymalosc[id] = 2000
		}
		case 5:
		{
			player_artefakt[id] = 5
			player_wytrzymalosc[id] = 2000
		}
		case 6:
		{
			player_artefakt[id] = 6
			player_wytrzymalosc[id] = 2000
		}
		case 7:
		{
			player_artefakt[id] = 7
			player_wytrzymalosc[id] = 2000
		}
		case 8:
		{
			player_artefakt[id] = 8
			player_wytrzymalosc[id] = 2000
		}
		case 9:
		{
			player_artefakt[id] = 9
			player_wytrzymalosc[id] = 2000
		}
		case 10:
		{
			player_artefakt[id] = 10
			player_wytrzymalosc[id] = 2000
		}
		case 11:
		{
			player_artefakt[id] = 13
			player_wytrzymalosc[id] = 2000
		}
		case 12:
		{
			player_artefakt[id] = 14
			player_wytrzymalosc[id] = 2000
		}
		case 13:
		{
			player_artefakt[id] = 15
			player_wytrzymalosc[id] = 2000
		}
		case 14:
		{
			player_artefakt[id] = 16
			player_wytrzymalosc[id] = 2000
		}
		case 15:
		{
			player_artefakt[id] = 17
			player_wytrzymalosc[id] = 2000
		}
		case 16:
		{
			player_artefakt[id] = 18
			player_wytrzymalosc[id] = 2000
		}
		case 17:
		{
			player_artefakt[id] = 19
			player_wytrzymalosc[id] = 2000
		}
		case 18:
		{
			player_artefakt[id] = 20
			player_wytrzymalosc[id] = 2000
		}
	}
	if(player_class[id] == Paladyn)
		player_wytrzymalosc[id] += 2000
	return PLUGIN_CONTINUE
}

/* UNIQUE ITEMS ============================================================================================ */
public add_vampire_bonus(id,attacker_id)
{
	if (player_b_vampire[attacker_id] > 0)
	{
		change_health(attacker_id,player_b_vampire[attacker_id],0,"")
	}
	if (c_vampire[attacker_id] > 0)
	{
		change_health(attacker_id,c_vampire[attacker_id],0,"")
	}
}
public add_money_bonus(id)
{
	if (player_b_money[id] > 0)
	{
		if (cs_get_user_money(id) < 16000 - player_b_money[id]) 
		{
			cs_set_user_money(id,cs_get_user_money(id)+ player_b_money[id]) 
		} 
		else 
		{
			cs_set_user_money(id,16000)
		}
	}
	if (a_money[id] > 0)
	{
		if (cs_get_user_money(id) < 16000 - a_money[id]) 
		{
			cs_set_user_money(id,cs_get_user_money(id)+ a_money[id]) 
		} 
		else 
		{
			cs_set_user_money(id,16000)
		}
	}
}
/* ==================================================================================================== */

public add_redhealth_bonus(id)
{
	if(player_item_id[id]==17)	//stalker ring
		set_user_health(id,5)
}

/* ==================================================================================================== */

public add_theif_bonus(id,attacker_id)
{
	if (player_b_theif[attacker_id] > 0)
	{
		new roll1 = random_num(1,5)
		if (roll1 == 1)
		{
			if (cs_get_user_money(id) > player_b_theif[attacker_id])
			{
				cs_set_user_money(id,cs_get_user_money(id)-player_b_theif[attacker_id])
				if (cs_get_user_money(attacker_id) + player_b_theif[attacker_id] <= 16000)
				{
					cs_set_user_money(attacker_id,cs_get_user_money(attacker_id)+player_b_theif[attacker_id])		
				}
			}
			else
			{
				new allthatsleft = cs_get_user_money(id)
				cs_set_user_money(id,0)
				if (cs_get_user_money(attacker_id) + allthatsleft <= 16000)
				{
					cs_set_user_money(attacker_id,cs_get_user_money(attacker_id) + allthatsleft)			
				}
			}
		}
	}
	if (c_theif[attacker_id] > 0)
	{
		new roll1 = random_num(1,20)
		if (roll1 == 1)
		{
			if (cs_get_user_money(id) > c_theif[attacker_id])
			{
				cs_set_user_money(id,cs_get_user_money(id)-c_theif[attacker_id])
				if (cs_get_user_money(attacker_id) + c_theif[attacker_id] <= 16000)
				{
					cs_set_user_money(attacker_id,cs_get_user_money(attacker_id)+c_theif[attacker_id])		
				}
			}
			else
			{
				new allthatsleft = cs_get_user_money(id)
				cs_set_user_money(id,0)
				if (cs_get_user_money(attacker_id) + allthatsleft <= 16000)
				{
					cs_set_user_money(attacker_id,cs_get_user_money(attacker_id) + allthatsleft)			
				}
			}
		}
	}
}


/* ==================================================================================================== */

public add_respawn_bonus(id)
{  
	if (player_b_respawn[id] > 0)
	{
		new roll = random_num(1,player_b_respawn[id])
		if (roll == 1)
		{
			new maxpl,players[32]
			get_players(players, maxpl) 
			if (maxpl > 2)
			{
				set_task(1.0,"ozywres",id) 		
			}
		}
		
	}
	if (c_respawn[id] > 0)
	{
		new roll = random_num(1,c_respawn[id])
		if (roll == 1)
		{
			new maxpl,players[32]
			get_players(players, maxpl) 
			if (maxpl > 2)
			{
				set_task(1.0,"ozywres",id) 
			}
		}
	}
}
/* ==================================================================================================== */
public add_bonus_blind(id,attacker_id,weapon)
{
	if (player_b_blind[attacker_id] > 0 && weapon != 4) 
	{
		if (random_num(1,player_b_blind[attacker_id]) == 1) Display_Fade(id,1<<14,1<<14 ,1<<16,255,155,50,230)		
	}
	if (c_blind[attacker_id] > 0 && weapon != 4)
	{
		if (random_num(1,c_blind[attacker_id]) == 1) Display_Fade(id,1<<14,1<<14 ,1<<16,255,155,50,230)		
	}
}
//obrazenia od tylu
public add_bonus_darksteel(attacker,id,damage)
{
	if (player_class[attacker] == Zabojca){
		if (UTIL_In_FOV(attacker,id) && !UTIL_In_FOV(id,attacker)){
			Effect_Bleed(id,248)
			change_health(id,-20,attacker,"world")
		}
	}
}
/* ==================================================================================================== */
public plusammo(id)
{
	const BITSUM_NO_RELOAD  = (1<<CSW_HEGRENADE)|(1<<CSW_C4)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE);
	new iWeapons[32], iNum, i, szWeapName[32],ent
	get_user_weapons(id, iWeapons, iNum)
	for(i=0;i<iNum;i++)
	{
		if (!(BITSUM_NO_RELOAD&(1<<iWeapons[i])))
		{
			get_weaponname (iWeapons[i], szWeapName, 31 );
			
			ent = find_ent_by_owner(-1, szWeapName, id);
			if(ent)
			{
				cs_set_weapon_ammo(ent, cs_get_weapon_ammo(ent)*2);
			}       
		}
	}
}
public item_c4fake(id)
{
	if (c4state[id] > 1)
	{
		hudmsg(id,2.0,"Meekstone mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE 
	}
	
	if (player_b_meekstone[id] > 0 && c4state[id] == 1 && is_user_alive(id) == 1 && freeze_ended == true)
	{
		explode(c4bombc[id],id,0)
		
		for(new a = 0; a < MAX; a++) 
		{ 
			new m_antymeek=0
			if (is_user_connected(a) && is_user_alive(a))
			{			
				new origin1[3]
				get_user_origin(a,origin1) 
				
				if(random_num(0,100)<=player_m_antymeek[a])
					m_antymeek=1
				
				if(get_distance(c4bombc[id],origin1) < 300 && get_user_team(a) != get_user_team(id))
				{
					if(c_antymeek[a] > 0 || m_antymeek)
						return PLUGIN_HANDLED;
					UTIL_Kill(id,a,"grenade")
				}
			}
		}
		
		c4state[id] = 2
		remove_entity(c4fake[id])
		c4fake[id] = 0 
	}
	
	if (player_b_meekstone[id] > 0 && c4state[id] == 0 && c4fake[id] == 0 && is_user_alive(id) == 1 && freeze_ended == true)
	{
		new Float:pOrigin[3]
		entity_get_vector(id,EV_VEC_origin, pOrigin)
		c4fake[id] = create_entity("info_target")
		
		entity_set_model(c4fake[id],"models/w_backpack.mdl")
		entity_set_origin(c4fake[id],pOrigin)
		entity_set_string(c4fake[id],EV_SZ_classname,"fakec4")
		entity_set_edict(c4fake[id],EV_ENT_owner,id)
		entity_set_int(c4fake[id],EV_INT_movetype,6)
		
		
		new Float:aOrigin[3]
		entity_get_vector(c4fake[id],EV_VEC_origin, aOrigin)
		c4bombc[id][0] = floatround(aOrigin[0])
		c4bombc[id][1] = floatround(aOrigin[1])
		c4bombc[id][2] = floatround(aOrigin[2])
		c4state[id] = 1
	}
	
	return PLUGIN_CONTINUE 
}

/* ==================================================================================================== */

public item_fireball(id)
{
	new xd = floatround(halflife_time()-wait1[id])
	new czas = 2-xd
	if (halflife_time()-wait1[id] <= 2)
	{
		client_print(id, print_center, "Za %d sek mozesz uzyc mocy!", czas)
		return PLUGIN_CONTINUE;
	}
	if (fired[id] < 1)
	{
		hudmsg(id,2.0,"Naladuj Kule")
		return PLUGIN_HANDLED
	}
	if (fired[id] > 0 && is_user_alive(id) == 1)
	{
		fired[id]--
		client_print(id, print_center, "Pozostalo %d magicznych kul", fired[id])
		new Float:vOrigin[3]
		new fEntity
		entity_get_vector(id,EV_VEC_origin, vOrigin)
		fEntity = create_entity("info_target")
		entity_set_model(fEntity, "models/rpgrocket.mdl")
		entity_set_origin(fEntity, vOrigin)
		entity_set_int(fEntity,EV_INT_effects,64)
		entity_set_string(fEntity,EV_SZ_classname,"fireball")
		entity_set_int(fEntity, EV_INT_solid, SOLID_BBOX)
		entity_set_int(fEntity,EV_INT_movetype,5)
		entity_set_edict(fEntity,EV_ENT_owner,id)
		
		
		
		//Send forward
		new Float:fl_iNewVelocity[3]
		VelocityByAim(id, 800, fl_iNewVelocity)
		entity_set_vector(fEntity, EV_VEC_velocity, fl_iNewVelocity)
		
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(22) 
		write_short(fEntity) 
		write_short(sprite_beam) 
		write_byte(45) 
		write_byte(4) 
		write_byte(255) 
		write_byte(0) 
		write_byte(0) 
		write_byte(25)
		message_end() 
		
		wait1[id]=floatround(halflife_time())
	}	
	return PLUGIN_HANDLED
}
/* ==================================================================================================== */
public Create_Line(id,origin1[3],origin2[3],bool:draw)
{
	if (draw)
	{
		message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id)
		write_byte(0)
		write_coord(origin1[0])	// starting pos
		write_coord(origin1[1])
		write_coord(origin1[2])
		write_coord(origin2[0])	// ending pos
		write_coord(origin2[1])
		write_coord(origin2[2])
		write_short(sprite_line)	// sprite index
		write_byte(1)		// starting frame
		write_byte(5)		// frame rate
		write_byte(2)		// life
		write_byte(3)		// line width
		write_byte(0)		// noise
		write_byte(255)	// RED
		write_byte(50)	// GREEN
		write_byte(50)	// BLUE					
		write_byte(155)		// brightness
		write_byte(5)		// scroll speed
		message_end()
	}
	
	new Float:ret[3],Float:fOrigin1[3],Float:fOrigin2[3]
	//So we dont hit oursdiablo
	origin1[2]+=50
	IVecFVec(origin1,fOrigin1)
	IVecFVec(origin2,fOrigin2)
	new hit = trace_line ( 0, fOrigin1, fOrigin2, ret )
	return hit
	
}

/* ==================================================================================================== */

public Prethink_Blink(id)
{
	if( get_user_button(id) & IN_ATTACK2 && !(get_user_oldbutton(id) & IN_ATTACK2) && is_user_alive(id)) 
	{			
		if (on_knife[id])
		{
			if (halflife_time()-czasmaga[id] <= 3) return PLUGIN_HANDLED		
			czasmaga[id] = floatround(halflife_time())	
			UTIL_Teleport(id,400+6*player_intelligence[id])
			client_cmd(id, "spk diablosound/teleport.wav")
		}
	}
	return PLUGIN_CONTINUE
}
/* ==================================================================================================== */
public item_convertmoney(id)
{
	new g_race_heal
	if(ile_wykonano[id]>=28)
		g_race_heal=15
	else if(ile_wykonano[id]>=13)
		g_race_heal=10
	if( get_user_flags(id) & ADMIN_LEVEL_H)
		g_race_heal+=15
	new maxhealth = race_heal[player_class[id]]+g_race_heal+player_strength[id]*2
	
	if (cs_get_user_money(id) < 1000)
		hudmsg(id,2.0,"Nie masz wystarczajacej ilosci zlota, zeby zamienic je w zycie")
	else if (get_user_health(id) == maxhealth)
		hudmsg(id,2.0,"Masz maksymalna ilosc zycia")
	else
	{
		cs_set_user_money(id,cs_get_user_money(id)-1000)
		change_health(id,15,0,"")			
		Display_Fade(id,2600,2600,0,0,255,0,15)
	}
}
/* ==================================================================================================== */
public host_killed(id)
{
	if (player_lvl[id] > 1)
	{
		hudmsg(id,2.0,"Straciles doswiadczenie za zabicie zakladnikow")
		Give_Xp(id,-floatround(3*player_lvl[id]/(2.65-player_lvl[id]/100)))
	}
	
}
/* ==================================================================================================== */
public showmenu(id)
{
	otwarte_menu[id] = true
	client_cmd(id, "spk diablosound/menu");
	new text[513] 
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)|(1<<9)
	
	
	
	format(text, 512, "\yOpcje^n\r1. \wInfo o przedmiocie^n\r2. \wUpusc  przedmiot^n\r3. \wWybierz klase^n\r4. \wMenu zadan^n\r5. \wSklep^n\r6. \wArtefakty^n\r7. \wGildie^n^n\r9. \wUstawienia^n\r0. Zamknij") 
	
	show_menu(id, keys, text, -1, "Opcje")
	return PLUGIN_HANDLED  
} 


public option_menu(id, key) 
{ 
	client_cmd(id, "spk diablosound/wybierz");
	switch(key) 
	{ 
		case 0: 
		{	
			otwarte_menu[id] = false
			iteminfo(id)
		}
		case 1: 
		{	
			otwarte_menu[id] = false
			dropitem(id,0)
		}
		case 2: 
		{	
			changerace(id)
		}
		case 3: 
		{	
			menu_questow(id)
		}
		case 4:
		{
			buyrune(id)
		}
		case 5:
		{
			show_menu_artef1(id)
		}
		case 6:
		{
			if(dobre_haslo[id] == 0){
				if (!equali(player_password[id], ""))
				{
					client_cmd(id, "messagemode podaj_haslo")
					ColorChat(id,GREEN,"Podaj haslo")
					otwarte_menu[id] = false
				}
				else gildie(id)
			}
			else{
				gildie(id)
			}
		}
		case 8:
		{
			ustawienia(id)
		}
		case 9:
		{
			otwarte_menu[id] = false
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_HANDLED
}
/* ==================================================================================================== */
public Prethink_froglegs(id)
{
	if (get_user_button(id) & IN_DUCK && totemstop[id] == 0 && freeze_ended)
	{
		if (floatround(halflife_time())-czasmaga[id] >= 3.0)
		{
			new Float:fl_iNewVelocity[3]
			VelocityByAim(id, 1000, fl_iNewVelocity)
			fl_iNewVelocity[2] = 210.0
			entity_set_vector(id, EV_VEC_velocity, fl_iNewVelocity)
			czasmaga[id] = floatround(halflife_time())
		}
	}
}

/* ==================================================================================================== */
public select_class_query(id) {
	if(is_user_bot(id) || asked_klass[id])
		return PLUGIN_HANDLED;
	
	if(g_boolsqlOK) {
		new name[48], data[1], q_command[512];
		data[0] = id;
		get_user_name(id, name, 47);
		replace_all(name, 47, "'", "\'");
		formatex(q_command, 511, "SELECT `klasa`, `lvl` FROM `%s` WHERE `nick`='%s'", g_sqlTable, name);
		
		SQL_ThreadQuery(g_SqlTuple, "select_class_handle", q_command, data, 1);
		
		asked_klass[id] = 1;
	}
	else sql_start();
	
	return PLUGIN_HANDLED;
}

public select_class_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
	new id = Data[0];
	
	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("diablo.log", "Could not connect to SQL database.");
		asked_klass[id] = 0;
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("diablo.log", "select_class_query Query failed.");
		asked_klass[id] = 0;
		return PLUGIN_CONTINUE;
	}
	if(Errcode) {
		log_to_file("diablo.log", "Error on select_class_query query: %s", Error);
		asked_klass[id] = 0;
		return PLUGIN_CONTINUE;
	}
	
	if(SQL_MoreResults(Query)) {
		new i, numklasa, numlvl;
		numklasa = SQL_FieldNameToNum(Query, "klasa");
		numlvl = SQL_FieldNameToNum(Query, "lvl");
		while(SQL_MoreResults(Query)) {
			i = SQL_ReadResult(Query, numklasa);
			player_class_lvl[id][i] = SQL_ReadResult(Query, numlvl);
			SQL_NextRow(Query);
		}
	}
	if(asked_klass[id] == 1) {
		asked_klass[id] = 2;
		select_class(id);
	}
	
	return PLUGIN_CONTINUE;
}
public select_class(id)
{
	if(is_user_bot(id)) return PLUGIN_HANDLED;
	asked_klass[id] = 0
	
	new MyMenu=menu_create("Wybierz Strone","select_class_menu");
	menu_additem(MyMenu,"Bohaterowie")
	menu_additem(MyMenu,"Potwory")
	menu_additem(MyMenu,"Demony")
	
	menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");
	
	menu_setprop(MyMenu,MPROP_PERPAGE,7)
	
	menu_display(id, MyMenu,0);
	return PLUGIN_HANDLED;
}
public select_class_menu(id, menu, item){
	client_cmd(id, "spk diablosound/wybierz")
	if(item == MENU_EXIT){
		menu_destroy(menu);
		otwarte_menu[id] = false
		return PLUGIN_HANDLED;
	}
	switch(item) 
	{ 
		case 0: select_class1(id)   
			case 1: ShowKlasy(id)
			case 2: select_class2(id)
		}	
	return PLUGIN_HANDLED;
}
public select_class1(id)
{
	new text1[512]
	format(text1, 511,"\yWybierz^n\r1. \wMag  Poziom :%i^n\r2. \wMnich  Poziom :%i^n\r3. \wPaladyn Poziom :%i^n\r4. \wNekromanta Poziom :%i^n\r5. \wBarbarzynca  Poziom :%i^n\r6. \wZabojca  Poziom :%i^n\r7. \wNinja  Poziom :%i^n\r8. \wAmazonka  Poziom :%i^n\r9. \wTyrael [PREMIUM] :%i^n^n\r0.\yWroc^n^n",
	player_class_lvl[id][1],player_class_lvl[id][2],player_class_lvl[id][3],player_class_lvl[id][4],player_class_lvl[id][5],player_class_lvl[id][6],player_class_lvl[id][7],player_class_lvl[id][8],player_class_lvl[id][9])
	
	show_menu(id, klawisze,text1, -1, "Bohaterowie")
}
public select_class_menu1(id, key) 
{ 
	reset_class_moc(id)
	client_cmd(id, "spk diablosound/wybierz");
	switch(key) 
	{ 
		
		case 0: 
		{
			player_class[id] = Mag
			c_blind[id] = 20
			client_cmd(id, "bind t mag")
			LoadXP(id, player_class[id])
		}
		case 1: 
		{	
			player_class[id] = Mnich
			c_piorun[id] = 2
//			c_theif[id] = 400
			c_lecz[id] = 5
			client_cmd(id, "bind t +piorun")
			LoadXP(id, player_class[id])
		}
		case 2: 
		{	
			player_class[id] =  Paladyn
			JumpsMax[id] = 6
			JumpsLeft[id]=JumpsMax[id]
			LoadXP(id, player_class[id])
		}
		case 3: 
		{			
			player_class[id] = Nekromanta
			c_respawn[id] = 3
			g_haskit[id] = 1
			c_odpornosc[id] = 1
			LoadXP(id, player_class[id])
		}
		case 4: 
		{	
			player_class[id] = Barbarzynca
			LoadXP(id, player_class[id])
		}
		case 5: 
		{
			player_class[id] = Zabojca
			c_jump[id] = 2
			c_silent[id] = 1
			LoadXP(id, player_class[id])
		}
		case 6: 
		{
			player_class[id] = Ninja
			LoadXP(id, player_class[id])
		}
		case 7: 
		{	
			player_class[id] = Hunter
			c_silent[id] = 1
			g_GrenadeTrap[id] = 1
			LoadXP(id, player_class[id])
		}
/*		case 8: 
		{
			if( get_user_flags(id) & ADMIN_LEVEL_H)
			{
				player_class[id] = Tyrael
				c_jump[id] = 2
				LoadXP(id, player_class[id])
			}
			else{
				select_class(id)
				hudmsg(id,2.0,"Wykup Premium")
			}
		}*/
		case 9:
		{
			select_class(id)
		}
	}
	otwarte_menu[id] = false
	CurWeapon(id)
	wczytaj_questa(id)
	quest_gracza[id] = wczytaj_aktualny_quest(id);
	wczytaj_pas(id)
	give_knife(id)
	ikona_mocy(id)
	
	return PLUGIN_HANDLED
} 
public ShowKlasy(id) {
	new text2[512]
	format(text2, 511,"\yWybierz^n\r1. \wImp  Poziom :%i^n\r2. \wCien  Poziom :%i^n\r3. \wDuch  Poziom :%i^n\45. \wDuriel  Poziom :%i^n\r5. \wSzaman  Poziom :%i^n\r6. \wKhazra  Poziom :%i^n^n0.\yWyjscie",
	player_class_lvl[id][10],player_class_lvl[id][11],player_class_lvl[id][12],player_class_lvl[id][13],player_class_lvl[id][14],player_class_lvl[id][15],player_class_lvl[id][16])
	
	show_menu(id, klawisze,text2, -1, "Potwory")
	
}
public PressedKlasy(id, key) {
	
	reset_class_moc(id)
	client_cmd(id, "spk diablosound/wybierz");
	switch (key) 
	{
		case 0: 
		{	
			player_class[id] = Imp
			c_blink[id] = 1
			LoadXP(id, player_class[id])
		}
		case 1: 
		{ 
			player_class[id] = Cien
			c_jump[id] = 2
			LoadXP(id, player_class[id])
		}
		case 3: 
		{
			player_class[id] = Duch
			client_cmd(id, "bind t ucieczka")
			LoadXP(id, player_class[id])
		}
		case 4: 
		{
			player_class[id] = Duriel
			client_cmd(id, "bind t +inferno")
//			client_cmd(id, "bind t mocbestia")
			LoadXP(id, player_class[id])
		}
		case 5: 
		{
			player_class[id] = Szaman
			c_heal[id] = 10
			c_jump[id] = 2
			LoadXP(id, player_class[id])
		}
		case 6: 
		{
			player_class[id] = Khazra
			c_piorun[id] = 2
			c_antyarchy[id] = 1
			c_antymeek[id] = 1
			c_antyorb[id] = 1
			c_antygrenade[id] = 1
			LoadXP(id, player_class[id])
		}
		case 9:
		{
			select_class(id)
		}
	}
	otwarte_menu[id] = false
	CurWeapon(id)
	give_knife(id)
	wczytaj_questa(id)
	quest_gracza[id] = wczytaj_aktualny_quest(id);
	wczytaj_pas(id)
	ikona_mocy(id)
	
	return PLUGIN_HANDLED
}
public select_class2(id)
{
	new text1[512]
	
	format(text1, 511,"\yWybierz^n\r1. \wBaal  Poziom :%i^n\r2. \wDiablo  Poziom :%i^n\r3. \wAndariel  Poziom :%i^n\r4. \wMefisto Poziom :%i^n\r5. \wIzual  Poziom :%i^n\r6. \wNihlathak  Poziom :%i^n\r7. \wGrisWold [PREMIUM]  Poziom :%i^n\r8. \wKowal Dusz [PREMIUM]  Poziom :%i^n^n0.\yWroc^n^n",
	player_class_lvl[id][17],player_class_lvl[id][18],player_class_lvl[id][19],player_class_lvl[id][20],player_class_lvl[id][21],player_class_lvl[id][22],player_class_lvl[id][23],player_class_lvl[id][24])
	
	show_menu(id, klawisze,text1, -1, "Demony")
}
public select_class_menu3(id, key) 
{ 
	reset_class_moc(id)
	client_cmd(id, "spk diablosound/wybierz");
	switch(key) 
	{
		case 0: 
		{
			player_class[id] = Baal
			LoadXP(id, player_class[id])
		}
		case 1: 
		{
			player_class[id] = Diablo
			LoadXP(id, player_class[id])
		}
		case 2: 
		{
			player_class[id] = Andariel
			client_cmd(id, "bind t +hook")
			LoadXP(id, player_class[id])
		}
		case 3: 
		{
			player_class[id] = Mefisto
			c_jump[id] = 2
			JumpsMax[id] = 3
			JumpsLeft[id]=JumpsMax[id]
			LoadXP(id, player_class[id])
		}
		case 4: 
		{	
			player_class[id] = Izual
			c_mine[id]=3
			c_silent[id] = 1
			c_redirect[id] = 5
			client_cmd(id, "bind v kladzmine")
			LoadXP(id, player_class[id])
		}
		case 5: 
		{	
			player_class[id] = Nihlathak
			client_cmd(id, "bind t +predator")
			LoadXP(id, player_class[id])
		}
		case 6: 
		{
			if( get_user_flags(id) & ADMIN_LEVEL_H)
			{
				player_class[id] = Griswold
				c_heal[id] = 10
				c_antyarchy[id] = 1
				c_antyorb[id] = 1
				c_antymeek[id] = 1
				c_antygrenade[id] = 1
				client_cmd(id, "bind t +kula")
				LoadXP(id, player_class[id])
			}
			else{
				select_class(id)
				hudmsg(id,2.0,"Wykup Premium")
			}
		}
		case 7: 
		{	
			if( get_user_flags(id) & ADMIN_LEVEL_H)
			{
				player_class[id] = Kowal
				c_blink[id] = 1
				client_cmd(id, "bind t ucieczka")
				LoadXP(id, player_class[id])
			}
			else{
				select_class(id)
				hudmsg(id,2.0,"Wykup Premium")
			}
		}
		case 9:
		{
			select_class(id)
			
		}
		
	}
	otwarte_menu[id] = false
	CurWeapon(id)
	wczytaj_questa(id)
	quest_gracza[id] = wczytaj_aktualny_quest(id);
	wczytaj_pas(id)
	ikona_mocy(id)
	
	give_knife(id)
	
	return PLUGIN_HANDLED
}
/*=============================================*/
public reset_class_moc(id)
{
	g_haskit[id] = 0
	asked_klass[id] = 0
	c_respawn[id] = 0
	c_blind[id] = 0
	c_redirect[id] = 0
	c_antyarchy[id] = 0
	c_vampire[id] = 0
	c_jump[id] = 0
	c_theif[id] = 0
	c_piorun[id] = 0
	c_blink[id] = 0
	c_odpornosc[id] = 0
	c_lecz[id] = 0
	JumpsMax[id] = 0
	wczytalo[id] = 0
	a_silent[id] = 0
	a_jump[id] = 0
	a_money[id] = 0
	a_inv[id] = 0
	a_noz[id] = 0.0
	a_spid[id] = 0
	a_wearsun[id] = 0
	a_heal[id] = 0
	c_silent[id]=0
	c_mine[id]=0
	g_GrenadeTrap[id] = 0
	c_heal[id] = 0
	c_damage[id] = 0
	c_antyorb[id] = 0
	c_antymeek[id] = 0
	c_antygrenade[id] = 0
}
/* ==================================================================================================== */
public add_barbarian_bonus(id)
{
	if (player_class[id] == Barbarzynca)
	{
		change_health(id,20,0,"")
		set_user_armor(id, 50)
	}
	if (player_class[id] == Izual)
	{
		set_user_armor(id, 200)
	}
/*	if (player_class[id] == Tyrael)
	{
		change_health(id,20,0,"")
	}*/
	if (player_class[id] == Kowal)
	{
		change_health(id,20,0,"")
	}
	if (get_user_flags(id) & ADMIN_LEVEL_H)
	{
		change_health(id,10,0,"")
	}
}
/* ==================================================================================================== */
//Find the nearest alive opponent in our view
public UTIL_FindNearestOpponent(id,maxdist)
{
	new best = 99999
	new entfound = -1
	new MyOrigin[3]
	get_user_origin(id,MyOrigin)
	
	for (new i=1; i < MAX; i++)
	{
		if (i == id || !is_user_connected(i) || !is_user_alive(i) || get_user_team(id) == get_user_team(i))
			continue
		
		new TempOrigin[3],Float:fTempOrigin[3]
		get_user_origin(i,TempOrigin)
		IVecFVec(TempOrigin,fTempOrigin)
		
		if (!UTIL_IsInView(id,i))
			continue
		
		
		new dist = get_distance ( MyOrigin,TempOrigin ) 
		
		if ( dist < maxdist && dist < best)
		{
			best = dist
			entfound = i
		}		
	}
	
	return entfound
}

/* ==================================================================================================== */

//Basicly see's if we can draw a straight line to the target without interference
public bool:UTIL_IsInView(id,target)
{
	new Float:IdOrigin[3], Float:TargetOrigin[3], Float:ret[3] 
	new iIdOrigin[3], iTargetOrigin[3]
	
	get_user_origin(id,iIdOrigin,1)
	get_user_origin(target,iTargetOrigin,1)
	
	IVecFVec(iIdOrigin,IdOrigin)
	IVecFVec(iTargetOrigin, TargetOrigin)
	
	if ( trace_line ( 1, IdOrigin, TargetOrigin, ret ) == target)
		return true
	
	if ( get_distance_f(TargetOrigin,ret) < 10.0)
		return true
	
	return false
	
}
/* ==================================================================================================== */

/* ==================================================================================================== */
//Will return 1 if user has amount of money and then substract
public bool:UTIL_Buyformoney(id,amount)
{
        if (cs_get_user_money(id) >= amount)
        {
                cs_set_user_money(id, cs_get_user_money(id) - amount)
                return true
        }
        else
        {
                hudmsg(id,2.0,"[SKLEP] Nie masz tyle zlota !")
                return false
        }
        
        return false
}

public bool:UTIL_Buyforzloto(id,amount)
{
        if (zloto_gracza[id] >= amount)
        {
                zloto_gracza[id]-=amount
                return true
        }
        else
        {
                hudmsg(id,2.0,"[SKLEP] Nie masz tyle zlota !")
                return false
        }
        
        return false
}

public bool:UTIL_Buyformana(id,amount)
{
        if (mana_gracza[id] >= amount)
        {
                mana_gracza[id]-=amount
                return true
        }
        else
        {
                hudmsg(id,2.0,"[SKLEP] Nie masz tyle many !")
                return false
        }
        
        return false
}

public buyrune(id){
	new sklep=menu_create("Wybierz Sklep:","cbBuyrune");
	
	menu_additem(sklep,"\ySklep za Dolary");
	menu_additem(sklep,"\ySklep za Zloto");
	menu_additem(sklep,"\ySklep za Mane");
	
	menu_display(id, sklep,0);
	return PLUGIN_HANDLED;
}

public cbBuyrune(id, menu, item){
	switch(item){
		case 0:{
			buyrune_d(id)
		}
		case 1:{
			buyrune_z(id)
		}
		case 2:{
			buyrune_m(id)
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public buyrune_d(id){
	new s_dolary=menu_create("Sklep za Dolary","cbBuyrune_d");
	
	menu_additem(s_dolary,"\yKsiega Doswiadczenia \dDostajesz losowa ilosc exp'a \r14500 $")
	menu_additem(s_dolary,"\ySrebrna Szkatulka \dDostajesz losowy przedmiot \r5000 $")
	menu_additem(s_dolary,"\yWkoj klejnot \dKowal ulepsza Ci przedmiot \r9000 $")
	menu_additem(s_dolary,"\yZlota Szkatulka \dDostajesz losowa ilosc zlota \r10000 $")
	menu_setprop(s_dolary,MPROP_EXIT,MEXIT_ALL)
	menu_setprop(s_dolary,MPROP_EXITNAME,"Wyjscie")
	
	menu_display(id, s_dolary,0);
	return PLUGIN_HANDLED;
}

public cbBuyrune_d(id, menu, item){
	switch(item){
		case 0:{
			new Players[32], zablokuj;
			get_players(Players, zablokuj, "ch");
			if(zablokuj > ile_zablokuj) {
				if (UTIL_Buyformoney(id,14500))
					Give_Xp(id, random_num(150,250))
			}
			else
				ColorChat(id, RED, "Aby kupic Ksiege Doswiadczenia musza grac %d osoby!",ile_zablokuj)
		}
		case 1:{
			if (UTIL_Buyformoney(id,5000))
				award_item(id,0)
		}
		case 2:{
			if (UTIL_Buyformoney(id,9000))
				upgrade_item(id)
		}
		case 3:{
			new Players[32], zablokuj;
			get_players(Players, zablokuj, "ch");
			if(zablokuj > ile_zablokuj) {
				if (UTIL_Buyformoney(id,10000))
					zloto_gracza[id]+=random_num(150,300)
			}
			else
				ColorChat(id, RED, "Aby kupic Zlota Szkatulke musza grac %d osoby!",ile_zablokuj)
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public buyrune_z(id){
	new s_zloto=menu_create("Sklep za Zloto","cbBuyrune_z");
	
	menu_additem(s_zloto,"\yKup Pomocnika \d(pomaga Ci na czas jednej mapy)")
	menu_additem(s_zloto,"\yKup Bron")
	menu_additem(s_zloto,"\yKup Wyposazenie")
	menu_additem(s_zloto,"\yKup Przedmiot")
	menu_setprop(s_zloto,MPROP_EXIT,MEXIT_ALL)
	menu_setprop(s_zloto,MPROP_BACKNAME,"Wroc")
	
	menu_display(id, s_zloto,0);
	return PLUGIN_HANDLED;
}

public cbBuyrune_z(id, menu, item){
	switch(item){
		case 0:
			show_pomocnicy(id)
		case 1:
			show_bronie(id)
		case 2:
			show_wyposarzenie(id)
		case 3:
			show_zPrzedmioty(id)
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}


public show_pomocnicy(id){
	new s_pom=menu_create("Pomocnicy :","cbShow_pomocnicy");
	
	menu_additem(s_pom,"\yLotrzyca \dOdporna na flesh i biega o 10 szybciej \r1000 Zlota")
	menu_additem(s_pom,"\yPustynny Zuk \dDodaje 100$ i 30 Zlota za zabicie \r1400 Zlota")
	menu_additem(s_pom,"\yZelazny Wilk \dDodaje 4 do dmg i zmiejsza o 2 obrazenia \r2000 Zlota")
	menu_additem(s_pom,"\yBarbarzynca \dDodaje 30 Hp i zabiera 4 hp przy uderzeniu wroga \r2400 Zlota")
	menu_setprop(s_pom,MPROP_EXIT,MEXIT_ALL)
	menu_setprop(s_pom,MPROP_EXITNAME,"Wyjscie")
	
	menu_display(id, s_pom,0);
	return PLUGIN_HANDLED;
}

public cbShow_pomocnicy(id, menu, item){
	switch(item){
		case 0:{
			if (UTIL_Buyforzloto(id,1000))
				pomocnik_player[id] = Lotrzyca
		}
		case 1:{
			if (UTIL_Buyforzloto(id,1400))
				pomocnik_player[id] = PustynnyZuk
		}
		case 2:{
			if (UTIL_Buyforzloto(id,2000))
				pomocnik_player[id] = ZelaznyWilk
		}
		case 3:{
			if (UTIL_Buyforzloto(id,2400))
				pomocnik_player[id] = Barbarzynca_p
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}


public show_bronie(id){
	new s_menu=menu_create("Sklep z Bronia","cbShow_bronie");
	
	menu_additem(s_menu,"\yArmor \r100 Zlota")
	menu_additem(s_menu,"\yAK-47 \r80 Zlota")
	menu_additem(s_menu,"\yM4A1 \r80 Zlota")
	menu_additem(s_menu,"\ySteyr AUG \r100 Zlota")
	menu_additem(s_menu,"\ySG-552 Commando \r100 Zlota")
	menu_additem(s_menu,"\yAWP \r180 Zlota")
	menu_additem(s_menu,"\ySG-550 \r240 Zlota")
	menu_additem(s_menu,"\yG3SG1 \r240 Zlota")
	menu_additem(s_menu,"\yM249 \r180 Zlota")
	menu_setprop(s_menu,MPROP_EXIT,MEXIT_ALL)
	menu_setprop(s_menu,MPROP_EXITNAME,"Wyjscie")
	menu_setprop(s_menu,MPROP_NEXTNAME,"Dalej")
	menu_setprop(s_menu,MPROP_BACKNAME,"Wroc")
	
	menu_display(id, s_menu,0);
	return PLUGIN_HANDLED;
}

public cbShow_bronie(id, menu, item){
	if(item!=0 && cs_get_user_hasprim (id)) 
		ColorChat(id, RED, "Masz juz bron dluga!")
	else {
		switch(item){
			case 0:{
				if (UTIL_Buyforzloto(id,100))
					give_item(id, "item_assaultsuit")
			}
			case 1:{
				if (UTIL_Buyforzloto(id,80)) {
					give_item(id, "weapon_ak47")
					give_item(id,"ammo_762nato") 
					give_item(id,"ammo_762nato") 
					give_item(id,"ammo_762nato") 
				}
			}
			case 2:{
				if (UTIL_Buyforzloto(id,80)) {
					give_item(id, "weapon_m4a1")
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato") 
				}
			}
			case 3:{
				if (UTIL_Buyforzloto(id,100)) {
					give_item(id, "weapon_aug") 
					give_item(id,"ammo_556nato")
					give_item(id,"ammo_556nato")
					give_item(id,"ammo_556nato")
				}
			}
			case 4:{
				if (UTIL_Buyforzloto(id,100)) {
					give_item(id, "weapon_sg552") 
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato")
				}
			}
			case 5:{
				if (UTIL_Buyforzloto(id,180)) {
					give_item(id, "weapon_awp")
					give_item(id,"ammo_338magnum")
					give_item(id,"ammo_338magnum")
					give_item(id,"ammo_338magnum")
				}
			}
			case 6:{
				if (UTIL_Buyforzloto(id,240)) {
					give_item(id, "weapon_sg550")
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato") 
					give_item(id,"ammo_556nato") 
				}
			}
			case 7:{
				if (UTIL_Buyforzloto(id,240)) {
					give_item(id, "weapon_g3sg1")
					give_item(id,"ammo_762nato")
					give_item(id,"ammo_762nato")
					give_item(id,"ammo_762nato")
				}
			}
			case 8:{
				if (UTIL_Buyforzloto(id,180)) {
					give_item(id, "weapon_m249")
					give_item(id,"ammo_556natobox")
					give_item(id,"ammo_556natobox")
				}
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public show_wyposarzenie(id){
	new keys  = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9)
	new Mstring[1001]
	new cena_pasa[12]
	switch(ile_slotow[id]){
		case 1:
			format(cena_pasa, 11, "300 Zlota")
		case 2:
			format(cena_pasa, 11, "600 Zlota")
		case 3:
			format(cena_pasa, 11, "1200 Zlota")
		case 4:
			format(cena_pasa, 11, "2000 Zlota")
		default:
			format(cena_pasa, 11, "MAX")
	}
	format(Mstring, 1000, "\ySklep z Wyposarzeniem^n^n\r1. \yMikstura Leczenia \dDodaje 50 HP.\r80 Zlota^n2. \yMikstura Wzmocnienia \dOdnawia cale Hp \r200 Zlota^n3. \yUlepsz Pas \dDodaje dodatkowy slot na miksture \r%s^n4. \ySrebrna Szkatulka \dDostajesz losowy przedmiot \r400 Zlota^n5. \yDiamentowa Szkatulka \dResetuje punkty many \r1200 Zlota^n^n0. \yWyjscie^n^n\r*-------------------------------------------------*^n\dUzycie Mikstury Leczenia: klawisz c^nUzycie Mikstury Wzmocnienia: klawisz x",cena_pasa)
	show_menu(id,keys,Mstring,-1,"Wyposarzenie")
}

public cbShow_wyposarzenie(id,item){
	switch(item){
		case 0:{
			if(slot_pasa[id] < ile_slotow[id]) {
				if (UTIL_Buyforzloto(id,80)) {
					++slot_pasa[id]
					++m_leczenia[id]
					ColorChat(id, RED, "Kupiles miksture! Wcisnij c, aby ja uzyc.")
				}
			}
			else
				ColorChat(id, RED, "Nie masz miejsca w pasie!")
			zapisz_pas(id)
		}
		case 1:{
			if(slot_pasa[id] < ile_slotow[id]) {
				if (UTIL_Buyforzloto(id,200)) {
					++slot_pasa[id]
					++m_wzmocnienia[id]
					ColorChat(id, RED, "Kupiles miksture! Wcisnij x, aby ja uzyc.")
				}
			}
			else
				ColorChat(id, RED, "Nie masz miejsca w pasie!")
			zapisz_pas(id)
		}
		case 2:{
			switch(ile_slotow[id]){
				case 1:{
					if (UTIL_Buyforzloto(id, 300))
					++ile_slotow[id]
				}
				case 2:{
					if (UTIL_Buyforzloto(id, 600))
					++ile_slotow[id]
				}
				case 3:{
					if (UTIL_Buyforzloto(id, 1200))
					++ile_slotow[id]
				}
				case 4:{
					if (UTIL_Buyforzloto(id, 2000))
					++ile_slotow[id]
				}
				default:
					ColorChat(id, RED, "Pas zostal maxymalnie ulepszony!")
			}
			zapisz_pas(id)
		}
		case 3:{
			if (UTIL_Buyforzloto(id, 400))
				award_item(id,0)
		}
		case 4:{
			if (UTIL_Buyforzloto(id, 1200)) {
				if(player_m_antyarchy[id])
					mana_gracza[id] += mana_staty[player_m_antyarchy[id]/3-1][1]
				if(player_m_antymeek[id])
					mana_gracza[id] += mana_staty[player_m_antymeek[id]/3-1][1]
				if(player_m_antyorb[id])
					mana_gracza[id] += mana_staty[player_m_antyorb[id]/3-1][1]
				if(player_m_antyfs[id])
					mana_gracza[id] += mana_staty[player_m_antyfs[id]/3-1][1]
				if(player_m_antyflesh[id])
					mana_gracza[id] += mana_staty[player_m_antyflesh[id]/3-1][1]
				player_m_antyarchy[id] = 0
				player_m_antymeek[id] = 0
				player_m_antyorb[id] = 0
				player_m_antyfs[id] = 0
				player_m_antyflesh[id] = 0
				zapisz_mane(id)
				ColorChat(id, RED, "Punkty many zostaly zresetowane!")
			}
		}
	}
	return PLUGIN_HANDLED;
}

public show_zPrzedmioty(id){
	new s_itemy=menu_create("Sklep z Przedmiotami","cbShow_zPrzedmioty");
	
	menu_additem(s_itemy,"\ySejmitar \r800 Zlota")
	menu_additem(s_itemy,"\yWigor Boga Gromow \r1500 Zlota")
	menu_additem(s_itemy,"\yOblicze Andariel \r1500 Zlota")
	menu_additem(s_itemy,"\yFantom Smierci \r1800 Zlota")
	menu_additem(s_itemy,"\ySkorzana Zbroja \r1500 Zlota")
	menu_additem(s_itemy,"\yPierscien Nekromanty \r1500 Zlota")
	menu_additem(s_itemy,"\yStraz Tal Rasha \r1000 Zlota")
	menu_additem(s_itemy,"\ySiekacz Bartuca \r1800 Zlota")
	menu_additem(s_itemy,"\ySila Wiatru \r800 Zlota")
	menu_additem(s_itemy,"\yTancerz Cieni \r2000 Zlota")
	menu_additem(s_itemy,"\yNiesmiertelny Krol \r2800 Zlota")
	menu_setprop(s_itemy,MPROP_EXIT,MEXIT_ALL)
	menu_setprop(s_itemy,MPROP_EXITNAME,"Wyjscie")
	menu_setprop(s_itemy,MPROP_NEXTNAME,"Dalej")
	menu_setprop(s_itemy,MPROP_BACKNAME,"Wroc")
	
	menu_display(id, s_itemy,0);
	return PLUGIN_HANDLED;
}

public cbShow_zPrzedmioty(id, menu, item){
	if(player_item_id[id]){
		ColorChat(id, RED, "Masz juz przedmiot!")
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch(item){
		case 0:{
			if (UTIL_Buyforzloto(id,800))
				award_item(id, 1)
		}
		case 1:{
			if (UTIL_Buyforzloto(id,1500))
				award_item(id, 3)
		}
		case 2:{
			if (UTIL_Buyforzloto(id,1500))
				award_item(id, 9) 
		}
		case 3:{
			if (UTIL_Buyforzloto(id,1800))
				award_item(id, 13)
		}
		case 4:{
			if (UTIL_Buyforzloto(id,1500))
				award_item(id, 14)
		}
		case 5:{
			if (UTIL_Buyforzloto(id,1500))
				award_item(id, 23)
		}
		case 6:{
			if (UTIL_Buyforzloto(id,1000))
				award_item(id, 26)
		}
		case 7:{
			if (UTIL_Buyforzloto(id,1800)) 
				award_item(id, 29)
		}
		case 8:{
			if (UTIL_Buyforzloto(id,800)) 
				award_item(id, 34)
		}
		case 9:{
			if (UTIL_Buyforzloto(id,2000)) 
				award_item(id, 47)
		}
		case 10:{
			if (UTIL_Buyforzloto(id,2800)) 
				award_item(id, 48)
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public buyrune_m(id){	
	new keys  = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9)
	new Mstring[451]
	new z1[31],z2[31],z3[31],z4[31],z5[31]
	if(player_m_antyarchy[id]<12)
		format(z1,30,"\dDaje %d % \r%d Many",mana_staty[player_m_antyarchy[id]/3][0],mana_staty[player_m_antyarchy[id]/3][1])
	else
		format(z1,30,"\r MAX")
	if(player_m_antymeek[id]<12)
		format(z2,30,"\dDaje %d %% \r%d Many",mana_staty[player_m_antymeek[id]/3][0],mana_staty[player_m_antymeek[id]/3][1])
	else
		format(z2,30,"\r MAX")
	if(player_m_antyorb[id]<12)
		format(z3,30,"\dDaje %d %% \r%d Many",mana_staty[player_m_antyorb[id]/3][0],mana_staty[player_m_antyorb[id]/3][1])
	else
		format(z3,30,"\r MAX")
	if(player_m_antyfs[id]<12)
		format(z4,30,"\dDaje %d %% \r%d Many",mana_staty[player_m_antyfs[id]/3][0],mana_staty[player_m_antyfs[id]/3][1])
	else
		format(z4,30,"\r MAX")
	if(player_m_antyflesh[id]<12)
		format(z5,30,"\dDaje %d %% \r%d Many",mana_staty[player_m_antyflesh[id]/3][0],mana_staty[player_m_antyflesh[id]/3][1])
	else
		format(z5,30,"\r MAX")
	
	format(Mstring, 450, "\ySklep za Mane^n^n\r1. \yOdpornosc na Archy %s^n\r2. \yOdpornosc na Meekstone %s^n\r3. \yOdpornosc na Wybuchy po smierci %s^n\r4. \yOdpornosc na Fire Shielda %s^n\r5. \yOdpornosc na Flesha %s^n^n0. \yWyjscie^n^n\r*-------------------------------------------------*^n\dOdpornosci zapisuja sie po zmianie mapy!^nWpisz /odpornosci lub /odp, by zobaczyc ich stan!",z1,z2,z3,z4,z5)
	show_menu(id,keys,Mstring,-1,"cbBuyrune_m")
}

public cbBuyrune_m(id, item){
	switch(item){
		case 0:{
			if (UTIL_Buyformana(id,mana_staty[player_m_antyarchy[id]/3][1])) 
				player_m_antyarchy[id]=mana_staty[player_m_antyarchy[id]/3][0]
		}
		case 1:{
			if (UTIL_Buyformana(id,mana_staty[player_m_antymeek[id]/3][1])) 
				player_m_antymeek[id]=mana_staty[player_m_antymeek[id]/3][0]
		}
		case 2:{
			if (UTIL_Buyformana(id,mana_staty[player_m_antyorb[id]/3][1])) 
				player_m_antyorb[id]=mana_staty[player_m_antyorb[id]/3][0]
		}
		case 3:{
			if (UTIL_Buyformana(id,mana_staty[player_m_antyfs[id]/3][1])) 
				player_m_antyfs[id]=mana_staty[player_m_antyfs[id]/3][0]
		}
		case 4:{
			if (UTIL_Buyformana(id,mana_staty[player_m_antyflesh[id]/3][1])) 
				player_m_antyflesh[id]=mana_staty[player_m_antyflesh[id]/3][0]
		}
	}
	zapisz_mane(id)
	return PLUGIN_HANDLED;
}
public upgrade_item(id)
{
	if(item_durability[id]>0) item_durability[id] += random_num(-50,50)
	if(item_durability[id]<1)
	{
		dropitem(id,0)
		return
	}
	if(player_b_jumpx[id]>0) player_b_jumpx[id] += random_num(0,1)
	
	if(player_b_vampire[id]>0)
	{
		if(player_b_vampire[id]>20) player_b_vampire[id] += random_num(-1,2)
		else if(player_b_vampire[id]>10) player_b_vampire[id] += random_num(0,2)
			else player_b_vampire[id]+= random_num(1,3)
	}
	if(player_b_damage[id]>0) player_b_damage[id] += random_num(0,3) 
	if(player_b_money[id]!=0) player_b_money[id]+= random_num(-100,300)	
	if(player_b_gravity[id]>0)
	{
		if(player_b_gravity[id]<3) player_b_gravity[id]+=random_num(0,2)
		else if(player_b_gravity[id]<5) player_b_gravity[id]+=random_num(1,3)
			else if(player_b_gravity[id]<8) player_b_gravity[id]+=random_num(-1,3)
			else if(player_b_gravity[id]<10) player_b_gravity[id]+=random_num(0,1)
		}
	if(player_b_inv[id]>0)
	{
		if(player_b_inv[id]>200) player_b_inv[id]-=random_num(0,50)
		else if(player_b_inv[id]>100) player_b_inv[id]-=random_num(-25,50)
			else if(player_b_inv[id]>50) player_b_inv[id]-=random_num(-10,20)
			else if(player_b_inv[id]>25) player_b_inv[id]-=random_num(-10,10)
		}
	if(player_b_theif[id]>0) player_b_theif[id] += random_num(0,250)
	if(player_b_respawn[id]>0)
	{
		if(player_b_respawn[id]>2) player_b_respawn[id]-=random_num(0,1)
		else if(player_b_respawn[id]>1) player_b_respawn[id]-=random_num(-1,1)
		}
	if(player_b_heal[id]>0)
	{
		if(player_b_heal[id]>20) player_b_heal[id]+= random_num(-1,3)
		else if(player_b_heal[id]>10) player_b_heal[id]+= random_num(0,4)
			else player_b_heal[id]+= random_num(2,6)
	}
	if(player_b_blind[id]>0)
	{
		if(player_b_blind[id]>5) player_b_blind[id]-= random_num(0,2)
		else if(player_b_blind[id]>1) player_b_blind[id]-= random_num(0,1)
		}
	
	if(player_b_4move[id]>0) player_b_4move[id] += random_num(0,150)
	if(player_b_redirect[id]>0) player_b_redirect[id]+= random_num(-2,1)
	if(player_b_fireball[id]>0) player_b_fireball[id]+= random_num(0,33)
	
	if(player_b_sniper[id]>0)
	{
		if(player_b_sniper[id]>7) player_b_sniper[id]-=random_num(0,2)
		else if(player_b_sniper[id]>5) player_b_sniper[id]-=random_num(0,1)
			else if(player_b_sniper[id]>3) player_b_sniper[id]-=random_num(-1,1)
	}
	if(player_b_knife[id]>0)
	{
		if(player_b_knife[id]>6) player_b_knife[id]-=random_num(0,2)
		else if(player_b_knife[id]>5) player_b_knife[id]-=random_num(0,1)
			else if(player_b_knife[id]>4) player_b_knife[id]-=random_num(-1,1)
		}
	if(player_b_awp[id]>0)
	{
		if(player_b_awp[id]>8) player_b_awp[id]-=random_num(0,2)
		else if(player_b_awp[id]>5) player_b_awp[id]-=random_num(0,1)
			else if(player_b_awp[id]>4) player_b_awp[id]-=random_num(-1,1)
		}
	if(player_b_firetotem[id]>0) player_b_firetotem[id] += random_num(0,50)
	
	if(player_b_darksteel[id]>0) player_b_darksteel[id] += random_num(0,2)
	if(player_sword[id]>0)
	{
		if(player_b_jumpx[id]==0 && random_num(0,10)==10) player_b_jumpx[id]=1
		if(player_b_vampire[id]==0 && random_num(0,10)==10) player_b_vampire[id]=1
		if(player_b_gravity[id]==0 && random_num(0,10)==10) player_b_gravity[id]=1
		if(player_b_respawn[id]==0 && random_num(0,10)==5) player_b_respawn[id]=15
		else if(player_b_respawn[id]>2 && random_num(0,10)==5) player_b_respawn[id]+=random_num(0,1)
			if(player_b_darksteel[id]==0 && random_num(0,10)==10) player_b_darksteel[id]=1
	}
	if(player_ultra_armor[id]>0) player_ultra_armor[id]++
	
	if(player_b_extrastats[id]>0) player_b_extrastats[id] += random_num(0,2)
	
}
public add_bonus_explode(id)
{
	if (player_b_explode[id] > 0)
	{
		new origin[3] 
		get_user_origin(id,origin) 
		explode(origin,id,0)
		
		
		for(new a = 0; a < MAX; a++) 
		{ 
			new m_antyorb=0
			if(random_num(0,100)<=player_m_antyorb[a])
				m_antyorb=1
			if (!is_user_connected(a) || !is_user_alive(a) || player_b_fireshield[a] != 0 ||  get_user_team(a) == get_user_team(id))
				continue
			if(c_antyorb[a] > 0 || m_antyorb)
				continue
			
			new origin1[3]
			get_user_origin(a,origin1) 
			
			if(get_distance(origin,origin1) < player_b_explode[id] + player_intelligence[id]*2)
			{
				new dam = 75-floatround(player_dextery[a]*0.5)
				if(dam<1) dam=1
				change_health(a,-dam,id,"grenade")
				Display_Fade(id,2600,2600,0,255,0,0,15)				
			}
		}
	}
	else if (player_class[id] == Barbarzynca)
	{
		
		new origin[3] 
		get_user_origin(id,origin) 
		explode(origin,id,0)
		
		
		for(new a = 0; a < MAX; a++) 
		{ 
			new m_antyorb=0
			if(random_num(0,100)<=player_m_antyorb[a])
				m_antyorb=1
			if (!is_user_connected(a) || !is_user_alive(a) || player_b_fireshield[a] != 0 ||  get_user_team(a) == get_user_team(id))
				continue
			if(m_antyorb)
				continue
			
			new origin1[3]
			get_user_origin(a,origin1) 
			
			if(get_distance(origin,origin1) < 100)
			{
				new dam = 40-floatround(40*(player_dextery[a]*0.5))
				if(dam<1) dam=1
				change_health(a,-dam,id,"grenade")
				Display_Fade(id,2600,2600,0,255,0,0,15)				
			}
		}
	}
}
//explode falszywa paka, wybuch po smierci
public explode(vec1[3],playerid, trigger)
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 21 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 32) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 1000)
	write_short( sprite_white ) 
	write_byte( 0 ) 
	write_byte( 0 ) 
	write_byte( 3 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	write_byte( 188 ) 
	write_byte( 220 ) 
	write_byte( 255 ) 
	write_byte( 255 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte( 12 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_byte( 188 ) 
	write_byte( 10 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 3 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_short( sprite_fire ) 
	write_byte( 65 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},playerid) 
	write_byte(107) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_coord(175) 
	write_short (sprite_gibs) 
	write_short (25)  
	write_byte (10) 
	message_end() 
	if (trigger == 1)
	{
		set_user_rendering(playerid,kRenderFxNone, 0,0,0, kRenderTransAdd,0) 
	}
}
/* ==================================================================================================== */

public item_take_damage(id,Float:damage)
{
	new itemdamage = get_cvar_num("diablo_durability")
	
	if (player_item_id[id] > 0 && item_durability[id] >= 0 && itemdamage> 0 && damage > 10)
	{
		//Make item take damage
		if (item_durability[id] - itemdamage <= 0)
		{
			item_durability[id]-=itemdamage
			dropitem(id,0)
		}
		else
		{
			item_durability[id]-=itemdamage
		}
		
	}
}
/* ==================================================================================================== */
//From twistedeuphoria plugin
public Prethink_Doublejump(id)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if((get_user_button(id) & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(get_user_oldbutton(id) & IN_JUMP))
	{
		if(jumps[id] < player_b_jumpx[id] || jumps[id] < c_jump[id] || jumps[id] < a_jump[id])
		{
			dojump[id] = true
			jumps[id]++
			return PLUGIN_HANDLED
		}
	}
	if((get_user_button(id) & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumps[id] = 0
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public Postthink_Doubeljump(id)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if(dojump[id] == true)
	{
		new Float:velocity[3]	
		entity_get_vector(id,EV_VEC_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,velocity)
		dojump[id] = false
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}
/*=============================================================*/
public showskills(id)
{
	static Skillsinfo[1050], len
	len = 0
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"<b><br><br>Masz %i sily - to daje tobie %i zycia<br><br>", player_strength[id],player_strength[id]*2);
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i zwinnosci - zwiekszona szybkosc o %i pkt. i redukuje sile atakow magia o %i%%<br><br>", player_dextery[id],floatround(player_dextery[id]*1.3),floatround(player_dextery[id]*0.5));
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i zrecznosci - Redukuje obrazenia z normalnych atkow %0.0f%%<br><br>", player_agility[id],player_damreduction[id]*100);
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i inteligencji - to daje wieksza moc przedmiotom ktorych da sie uzyc<br><br>", player_intelligence[id]);
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i zaradnosci - To daje Ci %i dodatkowych dolarow co runde<br><br>", player_zloto[id], player_zloto[id]*20);
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i Grawitacji - To zmniejsza twoja grawitacje o %i%%<br><br>", player_grawitacja[id],floatround(player_grawitacja[id]*0.8));
	len += formatex(Skillsinfo[len],sizeof Skillsinfo - 1 - len,"Masz %i Witalnosci - To regeneruje Ci %i Hp co 3 sek.</b>", player_witalnosc[id],player_witalnosc[id]/8);
	
	showitem2(id,"Statystyki","None", Skillsinfo)
}

public showdefens(id)
{
	new Defensinfo[768]
	format(Defensinfo,767,"<b><br><br>Masz %i % odpornosci na Achy.<br><br>Masz %i % odpornosci na Meekstone.<br><br>Masz %i % odpornosci na Wybuchy Po Smierci.<br><br>Masz %i % odpornosci na Fire Shielda.<br><br>Masz %i % odpornosci na Flesh'a.<br></b>",
	player_m_antyarchy[id], player_m_antymeek[id], player_m_antyorb[id], player_m_antyfs[id], player_m_antyflesh[id])
	
	showitem2(id,"Odpornosci","None", Defensinfo)
}

/* ==================================================================================================== */
//teleport
public UTIL_Teleport(id,distance)
{	
	Set_Origin_Forward(id,distance)
	
	new origin[3]
	get_user_origin(id,origin)
	
	//Particle burst ie. teleport effect	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(TE_PARTICLEBURST )
	write_coord(origin[0]) // origin
	write_coord(origin[1]) // origin
	write_coord(origin[2]) // origin
	write_short(25) // radius
	write_byte(2) // particle color
	write_byte(5) // duration * 10 will be randomized a bit
	message_end()
}

stock Set_Origin_Forward(id, distance) 
{
	new Float:origin[3]
	new Float:angles[3]
	new Float:teleport[3]
	new Float:heightplus = 10.0
	new Float:playerheight = 64.0
	new bool:recalculate = false
	new bool:foundheight = false
	pev(id,pev_origin,origin)
	pev(id,pev_angles,angles)
	
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	
	while (!Can_Trace_Line_Origin(origin,teleport) || Is_Point_Stuck(teleport,48.0))
	{	
		if (distance < 10)
			break;
		
		//First see if we can raise the height to MAX playerheight, if we can, it's a hill and we can teleport there	
		for (new i=1; i < playerheight+20.0; i++)
		{
			teleport[2]+=i
			if (Can_Trace_Line_Origin(origin,teleport) && !Is_Point_Stuck(teleport,48.0))
			{
				foundheight = true
				heightplus += i
				break
			}
			
			teleport[2]-=i
		}
		
		if (foundheight)
			break
		
		recalculate = true
		distance-=10
		teleport[0] = origin[0] + (distance+32) * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[1] = origin[1] + (distance+32) * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[2] = origin[2]+heightplus
	}
	
	if (!recalculate)
	{
		set_pev(id,pev_origin,teleport)
		return PLUGIN_CONTINUE
	}
	
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	set_pev(id,pev_origin,teleport)
	
	return PLUGIN_CONTINUE
}

stock bool:Can_Trace_Line_Origin(Float:origin1[3], Float:origin2[3])
{	
	new Float:Origin_Return[3]	
	new Float:temp1[3]
	new Float:temp2[3]
	
	temp1[x] = origin1[x]
	temp1[y] = origin1[y]
	temp1[z] = origin1[z]-30
	
	temp2[x] = origin2[x]
	temp2[y] = origin2[y]
	temp2[z] = origin2[z]-30
	
	trace_line(-1, temp1, temp2, Origin_Return) 
	
	if (get_distance_f(Origin_Return,temp2) < 1.0)
		return true
	
	return false
}

stock bool:Is_Point_Stuck(Float:Origin[3], Float:hullsize)
{
	new Float:temp[3]
	new Float:iterator = hullsize/3
	
	temp[2] = Origin[2]
	
	for (new Float:i=Origin[0]-hullsize; i < Origin[0]+hullsize; i+=iterator)
	{
		for (new Float:j=Origin[1]-hullsize; j < Origin[1]+hullsize; j+=iterator)
		{
			//72 mod 6 = 0
			for (new Float:k=Origin[2]-CS_PLAYER_HEIGHT; k < Origin[2]+CS_PLAYER_HEIGHT; k+=6) 
			{
				temp[0] = i
				temp[1] = j
				temp[2] = k
				
				if (point_contents(temp) != -1)
					return true
			}
		}
	}
	
	return false
}

stock Effect_Bleed(id,color)
{
	new origin[3]
	get_user_origin(id,origin)
	
	new dx, dy, dz
	
	for(new i = 0; i < 3; i++) 
	{
		dx = random_num(-15,15)
		dy = random_num(-15,15)
		dz = random_num(-20,25)
		
		for(new j = 0; j < 2; j++) 
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(dx*j))
			write_coord(origin[1]+(dy*j))
			write_coord(origin[2]+(dz*j))
			write_short(sprite_blood_spray)
			write_short(sprite_blood_drop)
			write_byte(color) // color index
			write_byte(8) // size
			message_end()
		}
	}
}

/* ==================================================================================================== */

public Use_Spell(id)
{
	if (player_global_cooldown[id] + GLOBAL_COOLDOWN >= halflife_time())
		return PLUGIN_CONTINUE
	else
		player_global_cooldown[id] = halflife_time()
	
	if (!is_user_alive(id) || !freeze_ended)
		return PLUGIN_CONTINUE
	
	/*See if USE button is used for anything else..
	1) Close to bomb
	2) Close to hostage
	3) Close to switch
	4) Close to door
	*/
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	//Func door and func door rotating
	new aimid, body
	get_user_aiming ( id, aimid, body ) 
	
	if (aimid > 0)
	{
		new classname[32]
		pev(aimid,pev_classname,classname,31)
		
		if (equal(classname,"func_door_rotating") || equal(classname,"func_door") || equal(classname,"func_button"))
		{
			new Float:doororigin[3]
			pev(aimid, pev_origin, doororigin)
			
			if (get_distance_f(origin, doororigin) < 70 && UTIL_In_FOV(id,aimid))
				return PLUGIN_CONTINUE
		}
		
	}
	
	//Bomb condition
	new bomb
	if ((bomb = find_ent_by_model(-1, "grenade", "models/w_c4.mdl"))) 
	{
		new Float:bombpos[3]
		pev(bomb, pev_origin, bombpos)
		
		//We are near the bomb and have it in FOV.
		if (get_distance_f(origin, bombpos) < 100 && UTIL_In_FOV(id,bomb))
			return PLUGIN_CONTINUE
	}
	//Hostage
	new hostage = engfunc(EngFunc_FindEntityByString, -1,"classname", "hostage_entity")
	
	while (hostage)
	{
		new Float:hospos[3]
		pev(hostage, pev_origin, hospos)
		if (get_distance_f(origin, hospos) < 70 && UTIL_In_FOV(id,hostage))
			return PLUGIN_CONTINUE
		
		hostage = engfunc(EngFunc_FindEntityByString, hostage,"classname", "hostage_entity")
	}
	
	check_magic(id)
	
	return PLUGIN_CONTINUE
}
//Angle to all targets in fov
stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2]
	new Float:flDot	
	new Float:CoreOrigin[3]
	new Float:TargetOrigin[3]
	new Float:CoreAngles[3]
	
	pev(Core,pev_origin,CoreOrigin)
	pev(Target,pev_origin,TargetOrigin)
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
		return 0.0
	
	pev(Core,pev_angles, CoreAngles)
	
	for ( new i = 0; i < 2; i++ )
		vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i]
	
	new Float:veclength = Vec2DLength(vec2LOS)
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[x] = 0.0
		vec2LOS[y] = 0.0
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[x] = vec2LOS[x]*flLen
		vec2LOS[y] = vec2LOS[y]*flLen
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles)
	
	new Float:v_forward[3]
	new Float:v_forward2D[2]
	get_global_vector(GL_v_forward, v_forward)
	
	v_forward2D[x] = v_forward[x]
	v_forward2D[y] = v_forward[y]
	
	flDot = vec2LOS[x]*v_forward2D[x]+vec2LOS[y]*v_forward2D[y]
	
	if ( flDot > 0.5 )
	{
		return flDot
	}
	
	return 0.0	
}

stock Float:Vec2DLength( Float:Vec[2] )  
{ 
	return floatsqroot(Vec[x]*Vec[x] + Vec[y]*Vec[y] )
}

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
		return true
	
	return false
}
/* ==================================================================================================== */

public changerace(id)
{
	if(player_class[id]!=NONE ) {
	set_user_health(id,0)
		savexpcom(id)
	}
	zapisz_aktualny_quest(id)
	player_class[id]=NONE
	reset_connet(id)
	select_class_query(id)
}

stock hudmsg(id,Float:display_time,const fmt[], {Float,Sql,Result,_}:...)
{	
if (player_huddelay[id] >= 0.03*4)
	return PLUGIN_CONTINUE
	
	new buffer[512]
	vformat(buffer, 511, fmt, 4)
	
	set_hudmessage ( 255, 0, 0, -1.0, 0.4 + player_huddelay[id], 0, display_time/2, display_time, 0.1, 0.2, -1 ) 	
	show_hudmessage(id, buffer)
	
	player_huddelay[id]+=0.03
	
	remove_task(id+TASK_HUD)
	set_task(display_time, "hudmsg_clear", id+TASK_HUD, "", 0, "a", 3)
	
	
	return PLUGIN_CONTINUE
	
}

public hudmsg_clear(id)
{
	new pid = id-TASK_HUD
	player_huddelay[pid]=0.0
}
/* ==================================================================================================== */

public item_firetotem(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Mozesz uzyc raz w rundzie totemu ognia")
	}
	else
	{
		used_item[id] = true
		Effect_Ignite_Totem(id,7)
	}
}

stock Effect_Ignite_Totem(id,seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_ignite.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 250,150,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_euser3,0)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
}

public Effect_Ignite_Totem_Think(ent)
{
	//Safe check because effect on death
	if (!freeze_ended)
		remove_entity(ent)
	
	if (!is_valid_ent(ent))
		return PLUGIN_CONTINUE
	
	new id = pev(ent,pev_owner)
	
	//Apply and destroy
	if (pev(ent,pev_euser3) == 1)
	{
		new entlist[513]
		new numfound = find_sphere_class(ent,"player",player_b_firetotem[id]+0.0,entlist,512)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			//This totem can hit the caster
			if (pid == id && is_user_alive(id))
			{
				Effect_Ignite(pid,id,4)
				hudmsg(pid,3.0,"Palisz sie. Strzel do kogos aby przestac sie palic!")
				continue
			}
			
			if (!is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
				continue
			
			//Dextery makes the fire damage less
			if (player_dextery[pid] > 20)
				Effect_Ignite(pid,id,1)
			else if (player_dextery[pid] > 15)
				Effect_Ignite(pid,id,2)
			else if (player_dextery[pid] > 10)
				Effect_Ignite(pid,id,3)
			else
				Effect_Ignite(pid,id,4)
			
			hudmsg(pid,3.0,"Palisz sie. Strzel do kogos aby przestac sie palic!")
		}
		
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time())
	{
		set_pev(ent,pev_euser3,1)
		
		//Show animation and die
		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and give them health
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
		write_byte( TE_BEAMCYLINDER );
		write_coord( origin[0] );
		write_coord( origin[1] );
		write_coord( origin[2] );
		write_coord( origin[0] );
		write_coord( origin[1] + player_b_firetotem[id]);
		write_coord( origin[2] + player_b_firetotem[id]);
		write_short( sprite_white );
		write_byte( 0 ); // startframe
		write_byte( 0 ); // framerate
		write_byte( 10 ); // life
		write_byte( 10 ); // width
		write_byte( 255 ); // noise
		write_byte( 150 ); // r, g, b
		write_byte( 150 ); // r, g, b
		write_byte( 0 ); // r, g, b
		write_byte( 128 ); // brightness
		write_byte( 5 ); // speed
		message_end();
		
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
		
	}
	else	
	{
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	}
	
	return PLUGIN_CONTINUE
}
stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}

stock Effect_Ignite(id,attacker,damage)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + 99 + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_euser1,attacker)
	set_pev(ent,pev_euser2,damage)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	AddFlag(id,Flag_Ignite)
}

//euser3 = destroy and apply effect
public Effect_Ignite_Think(ent)
{
	new id = pev(ent,pev_owner)
	attacker = pev(ent,pev_euser1)
	new damage = pev(ent,pev_euser2)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !HasFlag(id,Flag_Ignite)||player_class[id] == Ninja)
	{
		RemoveFlag(id,Flag_Ignite)
		Remove_All_Tents(id)
		Display_Icon(id ,0 ,"dmg_heat" ,200,0,0)
		
		remove_entity(ent)		
		return PLUGIN_CONTINUE
	}
	
	Display_Tent(id,sprite_ignite,2)
	new origin[3]
	get_user_origin(id,origin)
	
	//Make some burning effects
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SMOKE ) // 5
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short( sprite_smoke )
	write_byte( 22 )  // 10
	write_byte( 10 )  // 10
	message_end()
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_GUNSHOTDECAL ) // decal and ricochet sound
	write_coord( origin[0] ) //pos
	write_coord( origin[1] )
	write_coord( origin[2] )
	write_short (0) // I have no idea what thats supposed to be
	write_byte (random_num(199,201)) //decal
	message_end()
	
	Display_Icon(id ,1 ,"dmg_heat" ,200,0,0)
	//Do the actual damage
	change_health(id,-damage,attacker,"world")
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	
	
	return PLUGIN_CONTINUE
}

stock AddFlag(id,flag)
{
	afflicted[id][flag] = 1	
}

stock RemoveFlag(id,flag)
{
	afflicted[id][flag] = 0
}

stock bool:HasFlag(id,flag)
{
	if (afflicted[id][flag])
		return true
	
	return false
}

stock Display_Tent(id,sprite, seconds)
{
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(40) //Offset
	write_short(sprite)
	write_short(seconds*10)
	message_end()
}

stock Remove_All_Tents(id)
{
	message_begin(MSG_ALL ,SVC_TEMPENTITY) //message begin
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id) // entity index of player
	message_end()
}



stock Find_Best_Angle(id,Float:dist, same_team = false)
{
	new Float:bestangle = 0.0
	new winner = -1
	
	for (new i=0; i < MAX; i++)
	{
		if (!is_user_alive(i) || i == id || (get_user_team(i) == get_user_team(id) && !same_team))
			continue
		
		if (get_user_team(i) != get_user_team(id) && same_team)
			continue
		
		//User has spell immunity, don't target
		
		new Float:c_angle = Find_Angle(id,i,dist)
		
		if (c_angle > bestangle && Can_Trace_Line(id,i))
		{
			winner = i
			bestangle = c_angle
		}
		
	}
	
	return winner
}

//This is an interpolation. We make tree lines with different height as to make sure
stock bool:Can_Trace_Line(id, target)
{	
	for (new i=-35; i < 60; i+=35)
	{		
		new Float:Origin_Id[3]
		new Float:Origin_Target[3]
		new Float:Origin_Return[3]
		
		pev(id,pev_origin,Origin_Id)
		pev(target,pev_origin,Origin_Target)
		
		Origin_Id[z] = Origin_Id[z] + i
		Origin_Target[z] = Origin_Target[z] + i
		
		trace_line(-1, Origin_Id, Origin_Target, Origin_Return) 
		
		if (get_distance_f(Origin_Return,Origin_Target) < 25.0)
			return true
		
	}
	
	return false
}
public item_zamroz(id)
{
	if (used_item[id])
	{
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Zamroz_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 0,100,255, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Zamroz_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 600
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
				continue
			
			if (is_user_alive(pid)){
				totemstop[pid] = 1
				set_task(15.0, "off_zamroz",TASK_ENTANGLEWAIT + pid)
				set_speedchange(pid)
			}			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 0 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public off_zamroz(pid){
	pid -=TASK_ENTANGLEWAIT
	totemstop[pid] = 0
	zatakowany[pid] = 0
	set_speedchange(pid)
}
public item_grawi(id)
{
	if (used_item[id])
	{
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Grawi_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 20 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 0,100,255, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Grawi_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 750
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
			
			if (is_user_alive(pid)){
				set_user_gravity(pid, 0.25)
				
			}			
		}
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 0 ); // r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( 10 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public item_2012(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_2012_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 34,139,34, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_2012_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 700
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
				continue
			
			if (is_user_alive(pid)){
				message_begin(MSG_ONE,get_user_msgid("ScreenShake"),{0,0,0},pid); 
				write_short(7<<14); 
				write_short(2<<13); 
				write_short(3<<14); 
				message_end();
			}			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 34); // r, g, b
	write_byte( 139 ); // r, g, b
	write_byte( 34 ); // r, g, b
	write_byte( 170 ); // brightness
	write_byte( 6 ); // speed
	message_end();
	
	
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public item_smierc(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Smie_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 6 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 0,0,128, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}
public Effect_Smie_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 200
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
				continue
			
			if (is_user_alive(pid)) 
				
			UTIL_Kill(id,pid,"grenade")
			
			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 0 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
}
/* ==================================================================================================== */
public item_prad(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Pra_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 138,255,200, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}
public Effect_Pra_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 350
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
				continue
			
			if (is_user_alive(pid)){
				static Float:originF[3]
				pev(pid, pev_origin, originF)
				
				static originF2[3] 
				get_user_origin(pid, originF2)
				
				ElectroRing(originF) 
				ElectroSound(originF2)
				change_health(pid,-30,id,"")	
			}		
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte(138) 
	write_byte(255) 
	write_byte(200)
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
}
/* ==================================================================================================== */
public item_gravitybomb(id)
{
	if (pev(id,pev_flags) & FL_ONGROUND) 
	{
		hudmsg(id,2.0,"Musisz byc w powietrzu!")
		return PLUGIN_CONTINUE
	}
	
	if (halflife_time()-gravitytimer[id] <= 5)
	{
		hudmsg(id,2.0,"Ten przedmiot, moze byc uzyty co kazde 5 sekundy")
		return PLUGIN_CONTINUE
	}
	gravitytimer[id] = floatround(halflife_time())
	
	new origin[3]
	get_user_origin(id,origin)
	
	if (origin[2] == 0)
		earthstomp[id] = 1
	else
		earthstomp[id] = origin[2]
	
	set_user_gravity(id,5.0)
	falling[id] = true
	
	
	return PLUGIN_CONTINUE
	
}

public add_bonus_stomp(id)
{
	set_gravitychange(id)
	
	new origin[3]
	get_user_origin(id,origin)
	
	new dam = earthstomp[id]-origin[2]
	
	earthstomp[id] = 0
	
	//If jump is is high enough, apply some shake effect and deal damage, 300 = down from BOMB A in dust2
	if (dam < 85)
		return PLUGIN_CONTINUE
		
	dam = dam-85
	
	message_begin(MSG_ONE , get_user_msgid("ScreenShake") , {0,0,0} ,id)
	write_short( 1<<14 );
	write_short( 1<<12 );
	write_short( 1<<14 );
	message_end();
		
	new entlist[513]
	new numfound = find_sphere_class(id,"player",230.0+player_strength[id]*2,entlist,512)
	

	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
		new m_antyarchy=0
			
		if (pid == id || !is_user_alive(pid))
			continue
			
		if (get_user_team(id) == get_user_team(pid))
			continue
		if(random_num(0,100)<=player_m_antyarchy[pid])
			m_antyarchy=1
		if (c_antyarchy[pid] > 0 || m_antyarchy)
			continue
			
		if (!(pev(pid, pev_flags) & FL_ONGROUND)) continue	
			
		new Float:id_origin[3]
		new Float:pid_origin[3]
		new Float:delta_vec[3]
		
		pev(id,pev_origin,id_origin)
		pev(pid,pev_origin,pid_origin)
		
		
		delta_vec[x] = (pid_origin[x]-id_origin[x])+10
		delta_vec[y] = (pid_origin[y]-id_origin[y])+10
		delta_vec[z] = (pid_origin[z]-id_origin[z])+200
		
		set_pev(pid,pev_velocity,delta_vec)
						
		message_begin(MSG_ONE , get_user_msgid("ScreenShake") , {0,0,0} ,pid)
		write_short( 1<<14 );
		write_short( 1<<12 );
		write_short( 1<<14 );
		message_end();
		
		change_health(pid,-dam,id,"world")			
	}
		
	return PLUGIN_CONTINUE
}

/* ==================================================================================================== */
//fireshield
public item_rot(id)
{
	if (used_item[id])
	{
		RemoveFlag(id,Flag_Rot)
		used_item[id] = false
	}
	else
	{
		if (find_ent_by_owner(-1,"Effect_Rot",id) > 0)
			return PLUGIN_CONTINUE
		
		Create_Rot(id)
		used_item[id] = true
	}
	
	return PLUGIN_CONTINUE
}

public Create_Rot(id)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Rot")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_NOT)
	AddFlag(id,Flag_Rot)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
}

public Effect_Rot_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (!is_user_alive(id) || !HasFlag(id,Flag_Rot) || !freeze_ended)
	{
		Display_Icon(id,0,"dmg_bio",255,255,0)
		set_user_maxspeed(id,245.0+player_dextery[id])
		
		set_renderchange(id)
		
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_user_maxspeed(id,252.0+player_dextery[id]+15)
	Display_Icon(id,1,"dmg_bio",255,150,0)
	set_renderchange(id)
	
	new entlist[513]
	new numfound = find_sphere_class(id,"player",250.0,entlist,512)
	
	for (new i=0; i < numfound; i++)
	{		 
		new pid = entlist[i]
		new m_antyfs=0
		if(random_num(0,100)<=player_m_antyfs[ pid ])
			m_antyfs=1
		if(m_antyfs)
                        continue
			
		if (pid == id || !is_user_alive(pid))
			continue
			
		if (get_user_team(id) == get_user_team(pid))
			continue
		
		//Rot him!
		if (random_num(1,2) == 1) Display_Fade(pid,1<<14,1<<14,1<<16,255,155,50,230)
		
		change_health(pid,-45,id,"world")
		Effect_Bleed(pid,100)
		Create_Slow(pid,3)
		
	}
	
	change_health(id,-10,id,"world")
		
	set_pev(ent,pev_nextthink, halflife_time() + 0.8)
	return PLUGIN_CONTINUE
}
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
public item_ogienflara(id)
{
	if (player_class[id] == Duriel && freeze_ended && is_user_alive(id))
	{
		new xd = floatround(halflife_time()-wait1[id])
		new czas = 20-xd
		if (halflife_time()-wait1[id] <= 20)
		{
			client_print(id, print_center, "Za %d sek mozesz uzyc mocy!", czas)
			return PLUGIN_CONTINUE;
		} 																
		else {
			
			new entlist[513]
			new licz
			new numfound = find_sphere_class(id,"player",230.0,entlist,512)
			for (new i=0; i < numfound; i++)
			{		
				new pid = entlist[i]
				
				if (pid == id || !is_user_alive(pid))
					continue
				
				if (get_user_team(id) == get_user_team(pid))
					continue
				
				Effect_Ignite(pid,id,8)
				set_task(5.0, "offogien", pid)
				licz++
				
			}
			
			wait1[id]=floatround(halflife_time())
			
			new iorigin[3]
			get_user_origin( id, iorigin );
			
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY,iorigin);
			write_byte( TE_BEAMCYLINDER );
			write_coord( iorigin[0] );
			write_coord( iorigin[1] );
			write_coord( iorigin[2] );
			write_coord( iorigin[0] );
			write_coord( iorigin[1] + 230);
			write_coord( iorigin[2] + 230);
			write_short( sprite_white );
			write_byte( 0 ); // startframe
			write_byte( 0 ); // framerate
			write_byte( 10 ); // life
			write_byte( 10 ); // width
			write_byte( 255 ); // noise
			write_byte( 255 ); // r, g, b
			write_byte( 48 ); // r, g, b
			write_byte( 48 ); // r, g, b
			write_byte( 128 ); // brightness
			write_byte( 5 ); // speed
			message_end();
			
		}
	}
	return PLUGIN_CONTINUE
}
public offogien(id)
{
	RemoveFlag(id,Flag_Ignite)
}
/////////////////////////////////////////////////////
//Daze player
stock Create_Slow(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Slow")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	AddFlag(id,Flag_Dazed)
}

public Effect_Slow_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Display_Icon(id,0,"dmg_heat",255,255,0)
		RemoveFlag(id,Flag_Dazed)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	Display_Icon(id,1,"dmg_heat",255,255,0)
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	return PLUGIN_CONTINUE
}

/* ==================================================================================================== */

stock AddTimedFlag(id,flag,seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Timedflag")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_euser3,flag)			
	AddFlag(id,flag)	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
}

public Effect_Timedflag_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		RemoveFlag(id,pev(ent,pev_euser3))
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	return PLUGIN_CONTINUE
}
/* ==================================================================================================== */

public item_money_shield(id)
{
	if (used_item[id])
	{
		RemoveFlag(id,Flag_Moneyshield)
		used_item[id] = false
	}
	else
	{
		if (find_ent_by_owner(-1,"Effect_MShield",id) > 0)
			return PLUGIN_CONTINUE
		
		new ent = Spawn_Ent("info_target")
		set_pev(ent,pev_classname,"Effect_MShield")
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_solid,SOLID_NOT)		
		AddFlag(id,Flag_Moneyshield)	
		set_pev(ent,pev_nextthink, halflife_time() + 0.1)
		used_item[id] = true
	}
	
	return PLUGIN_CONTINUE
}

public Effect_MShield_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (!is_user_alive(id) || cs_get_user_money(id) <= 0 || !HasFlag(id,Flag_Moneyshield) || !freeze_ended)
	{
		RemoveFlag(id,Flag_Moneyshield)
		
		set_renderchange(id)
		
		Display_Icon(id,0,"suithelmet_empty",255,255,255)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	if (cs_get_user_money(id)-250 < 0)
		cs_set_user_money(id,0)
	else
		cs_set_user_money(id,cs_get_user_money(id)-250)
	
	set_renderchange(id)
	
	Display_Icon(id,1,"suithelmet_empty",255,255,255)
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	return PLUGIN_CONTINUE
}

/* ==================================================================================================== */	

//Find the owner that has target as target and the specific classname
public find_owner_by_euser(target,classname[])
{
	new ent = -1
	ent = find_ent_by_class(ent,classname)
	
	while (ent > 0)
	{
		if (pev(ent,pev_euser2) == target)
			return pev(ent,pev_owner)
		ent = find_ent_by_class(ent,classname)
	}
	
	return -1
}

/* ==================================================================================================== */

public item_totemheal(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Leczacy Totem mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	used_item[id] = true

	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Healing_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 7 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public item_totemheal2(id)
{
	if (used_item1[id])
	{
		hudmsg(id,2.0,"Leczacy Totem mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item1[id] = true

	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Healing_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 7 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Healing_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300
	new amount_healed = player_b_heal[id]
	if(player_class[id] == Szaman && player_b_heal[id] == 0)
		amount_healed = 15
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
			
			if (is_user_alive(pid)) change_health(pid,amount_healed,0,"")			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 100 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public Effect_Healing1_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300+player_intelligence[id]
	new amount_healed = 35
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
			
			if (is_user_alive(pid)) change_health(pid,amount_healed,0,"")			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 100 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public set_speedchange(id)
{	
	if (is_user_connected(id) && freeze_ended)
	{
		new speeds
		
		switch(player_class[id])
		{
			case Nihlathak:speeds=20
				case Imp:speeds+=25
				case Ninja:speeds+=40
				case Zabojca:speeds= 30
		}
		if(pomocnik_player[id]==Lotrzyca) speeds+= 10
		speeds += floatround(player_dextery[id]*1.3)
		
		if(player_b_4move[id] > 0) speeds += player_b_4move[id]
		if(ilerazysip[id] > 0 ) speeds += ilerazysip[id]
		if(totemstop[id] == 1) speeds -= 9250
		if(a_spid[id]) speeds += a_spid[id]
		if(g_spid[id]) speeds += g_spid[id]*10
		if(c_bestia[id] > 0) speeds +=50
		if(player_item_id[id]==132) speeds -= floatround(speeds*0.35)
		if(player_b_usingwind[id] == 1)	speeds += 150
		
		set_user_maxspeed(id,255.0 + speeds)
	}
}
public set_renderchange(id)
{	
	if(is_user_connected(id) && is_user_alive(id))
	{
		if(!naswietlony[id])
		{
			new render=255
			
			if(player_b_usingwind[id]==1)
				set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,3)
				
			else if(invisible_cast[id]==1)
			{
				//if(player_b_inv[id]>0) set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, floatround((10.0/255.0)*(255-player_b_inv[id])))
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 10)
			}
			
			else if (player_class[id] == Ninja)
			{
				render = 11
				
				if(HasFlag(id,Flag_Moneyshield)||HasFlag(id,Flag_Rot)) render*=2	
				
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, render)
			}
			else if (player_class[id] == Imp)
			{
				new inv_bonus = 225 - player_b_inv[id]
				new a_inv_bonus = 225 - a_inv[id]
				new inv = min(inv_bonus, a_inv_bonus)
				render = 120
				
				if(inv < render)
					render = inv_bonus
				
				if(HasFlag(id,Flag_Moneyshield)||HasFlag(id,Flag_Rot)) render*=2	
				
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, render)
			}
			else if (player_class[id] == Duch)
			{
				new inv_bonus = 225 - player_b_inv[id]
				render = 85
				
				if(player_b_inv[id]>0)
				{
					while(inv_bonus>0)
					{
						inv_bonus-=3
						render-=2
					}
				}
				if(render<0) render=5
				
				if(HasFlag(id,Flag_Moneyshield)||HasFlag(id,Flag_Rot)) render*=2	
				
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, render)
			}
			else if(HasFlag(id,Flag_Moneyshield)||HasFlag(id,Flag_Rot))
			{
				if(HasFlag(id,Flag_Moneyshield)) set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,16)  
				if(HasFlag(id,Flag_Rot)) set_rendering ( id, kRenderFxGlowShell, 255,255,0, kRenderFxNone, 10 )
			}
			else if(brak_strzal[id]==1)
			{
				set_user_rendering(id,kRenderFxGlowShell,0,100,255,kRenderNormal,50)
			}
			else if(niewidka[id]==1)
			{
				if(player_b_inv[id]>0) set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, floatround((10.0/255.0)*(255-player_b_inv[id])))
				else set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 40)
			}
			else
			{
				render = 255 
				if(player_b_inv[id]>0) render = player_b_inv[id]
				
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, render)
			}
			
		}	
		else set_user_rendering(id,kRenderFxGlowShell,flashlight_r,flashlight_g,flashlight_b,kRenderNormal,4)
	}
}
public WygrywaTT()
{
	new Players[32], playerCount, id
	get_players(Players, playerCount, "aeh", "TERRORIST") 
	
	
	for (new i=0; i<playerCount; i++) 
	{
		id = Players[i]
		Give_Xp(id,get_cvar_num("diablo_winxp"))	
		ColorChat(id, GREEN, "[NewDiablo]^x01 Dostales %i doswiadczenia za wygranie rundy",get_cvar_num("diablo_winxp"));
	}	
}

public WygrywaCT()
{
	new Players[32], playerCount, id
	get_players(Players, playerCount, "aeh", "CT") 
	
	for (new i=0; i<playerCount; i++) 
	{
		id = Players[i]
		Give_Xp(id,get_cvar_num("diablo_winxp"))	
		ColorChat(id, GREEN, "[NewDiablo]^x01 Dostales %i doswiadczenia za wygranie rundy",get_cvar_num("diablo_winxp"));
	}	
}
public set_gravitychange(id)
{
/*	if(is_user_alive(id))
	{
		switch(player_class[id])
		{
			case Ninja:
			{
				if(player_b_gravity[id]>6) set_user_gravity(id, 0.21)
				else if(player_b_gravity[id]>3) set_user_gravity(id, 0.22)
				else if(player_b_redbull[id]>0) set_user_gravity(id, 0.15)
				else set_user_gravity(id, 0.28)
			}
			case Mefisto:
			{
				if(player_b_gravity[id]>6) set_user_gravity(id, 0.4)
				else if(player_b_gravity[id]>3) set_user_gravity(id, 0.35)
				else if(player_b_redbull[id]>0) set_user_gravity(id, 0.3)
				else set_user_gravity(id, 0.5)
			}
			default:
			{
					set_user_gravity(id,1.0*(1.0-player_b_gravity[id]/17.0))
					if(player_b_redbull[id]>0) set_user_gravity(id, 0.2)
			}
		}
		if(c_bestia[id] == 1){
			set_user_gravity(id, 0.2)
		}
	}*/
	if(is_user_alive(id) && is_user_connected(id)){
		new Float: grawitacja_itemu[33]
		grawitacja_itemu[id] = 1.0*(1.0-player_b_gravity[id]/13.0)
		new Float: grawitacja_gracza2[33]
		grawitacja_gracza2[id] = 1.0*(1.0-player_grawitacja[id]/130.0)
		if(player_class[id] == Ninja)
		{
			grawitacja_gracza2[id] = (1.0*(1.0-player_grawitacja[id]/130.0))*0.25
			if(grawitacja_itemu[id] < grawitacja_gracza2[id]){
				if(player_b_gravity[id] > 8) set_user_gravity(id, 0.15)
				else if(player_b_gravity[id] > 4) set_user_gravity(id, 0.20)
			}
			else set_user_gravity(id, grawitacja_gracza2[id])
		}
		else if(player_class[id] == Mefisto)
		{
			grawitacja_gracza2[id] = (1.0*(1.0-player_grawitacja[id]/130.0))*0.35
			if(grawitacja_itemu[id] < grawitacja_gracza2[id]){
				if(player_b_gravity[id] > 8) set_user_gravity(id, 0.25)
				else if(player_b_gravity[id] > 4) set_user_gravity(id, 0.30)
			}
			else set_user_gravity(id, grawitacja_gracza2[id])
		}
		else if(player_class[id] == Szaman)
		{
			grawitacja_gracza2[id] = (1.0*(1.0-player_grawitacja[id]/130.0))*0.6
			if(grawitacja_itemu[id] < grawitacja_gracza2[id]){
				if(player_b_gravity[id] > 8) set_user_gravity(id, 0.4)
				else if(player_b_gravity[id] > 4) set_user_gravity(id, 0.5)
			}
			else set_user_gravity(id, grawitacja_gracza2[id])
		}
/*		else if(player_class[id] == Tyrael)
		{
			grawitacja_gracza2[id] = (1.0*(1.0-player_grawitacja[id]/130.0))*0.35
			if(grawitacja_itemu[id] < grawitacja_gracza2[id]){
				if(player_b_gravity[id] > 8) set_user_gravity(id, 0.25)
				else if(player_b_gravity[id] > 4) set_user_gravity(id, 0.30)
			}
			else set_user_gravity(id, grawitacja_gracza2[id])
		}*/
		else if(grawitacja_itemu[id] < grawitacja_gracza2[id])
			set_user_gravity(id,grawitacja_itemu[id])
		else set_user_gravity(id,grawitacja_gracza2[id])
	}
}
public cmd_who(id)
{
static motd[1600],header[100],name[32],len,i
len = 0
static players[32], numplayers
get_players(players, numplayers, "ch")
new playerid
// Table i background
len += formatex(motd[len],sizeof motd - 1 - len,"<body bgcolor=#000000 text=#FFB000>")
len += formatex(motd[len],sizeof motd - 1 - len,"<center><table width=700 border=1 cellpadding=4 cellspacing=4>")
len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>Name</td><td>Klasa</td><td>Level</td></tr>")
//Title
formatex(header,sizeof header - 1,"Statystyki")

for (i=0; i< numplayers; i++)
{
	playerid = players[i]
	
	get_user_name( playerid, name, 31 )
	
	len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>%s</td><td>%s</td><td>%d</td></tr>",name,Race[player_class[playerid]], player_lvl[playerid])
}
len += formatex(motd[len],sizeof motd - 1 - len,"</table>")

show_motd(id,motd,header)     
}
public changeskin(id,reset){
if (id<1 || id>32 || !is_user_connected(id)) return PLUGIN_CONTINUE
if (reset==1){
	cs_reset_user_model(id)
	skinchanged[id]=false
	return PLUGIN_HANDLED
	}else{
	//new newSkin[32]
	new num = random_num(0,3)
	
	if (get_user_team(id)==1){
		//add(newSkin,31,CTSkins[num])
		cs_set_user_model(id,CTSkins[num])
		}else{
		
		cs_set_user_model(id,TSkins[num])
	}
	
	skinchanged[id]=true
}

return PLUGIN_CONTINUE
}

stock refill_ammo(id)
{
new wpnid
if(!is_user_alive(id) || pev(id,pev_iuser1)) return;

new wpn[32],clip,ammo
wpnid = get_user_weapon(id, clip, ammo)
get_weaponname(wpnid,wpn,31)

new wEnt;

// set clip ammo
wpnid = get_weaponid(wpn)
//wEnt = get_weapon_ent(id,wpnid);
wEnt = get_weapon_ent(id,wpnid);
cs_set_weapon_ammo(wEnt,maxClip[wpnid]);

}
stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
// who knows what wpnName will be
static newName[32];

// need to find the name
if(wpnid) get_weaponname(wpnid,newName,31);

// go with what we were told
else formatex(newName,31,"%s",wpnName);

// prefix it if we need to
if(!equal(newName,"weapon_",7))
	format(newName,31,"weapon_%s",newName);
	
	new ent;
	while((ent = engfunc(EngFunc_FindEntityByString,ent,"classname",newName)) && pev(ent,pev_owner) != id) {}
	
	return ent;
}
public event_flashlight(id) {
	if(!get_cvar_num("flashlight_custom")) {
		return;
	}
	if(flashlight[id]) {
		flashlight[id] = 0;
	}
	else {
		if(flashbattery[id] > 0) {
			flashlight[id] = 1;
		}
	}
	
	if(!task_exists(TASK_CHARGE+id)) {
		new parms[1];
		parms[0] = id;
		set_task((flashlight[id]) ? get_cvar_float("flashlight_drain") : get_cvar_float("flashlight_charge"),"charge",TASK_CHARGE+id,parms,1);
	}
	
	message_begin(MSG_ONE,get_user_msgid("Flashlight"),{0,0,0},id);
	write_byte(flashlight[id]);
	write_byte(flashbattery[id]);
	message_end();
	
	entity_set_int(id,EV_INT_effects,entity_get_int(id,EV_INT_effects) & ~EF_DIMLIGHT);
}

public charge(parms[]) {
	if(!get_cvar_num("flashlight_custom")) {
		return;
	}
	
	new id = parms[0];
	
	if(flashlight[id]) {
		flashbattery[id] -= 1;
	}
	else {
		flashbattery[id] += 1;
	}
	
	message_begin(MSG_ONE,get_user_msgid("FlashBat"),{0,0,0},id);
	write_byte(flashbattery[id]);
	message_end();
	
	if(flashbattery[id] <= 0) {
		flashbattery[id] = 0;
		flashlight[id] = 0;
		
		message_begin(MSG_ONE,get_user_msgid("Flashlight"),{0,0,0},id);
		write_byte(flashlight[id]);
		write_byte(flashbattery[id]);
		message_end();
		
		// don't return so we can charge it back up to full
	}
	else if(flashbattery[id] >= MAX_FLASH) 
	{
		flashbattery[id] = MAX_FLASH
		return; // return because we don't need to charge anymore
	}
	
	set_task((flashlight[id]) ? get_cvar_float("flashlight_drain") : get_cvar_float("flashlight_charge"),"charge",TASK_CHARGE+id,parms,1)
}
////////////////////////////////////////////////////////////////////////////////
//                         REVIVAL KIT - NOT ALL                              //
////////////////////////////////////////////////////////////////////////////////
public message_clcorpse()
{	
	return PLUGIN_HANDLED
}

public event_hltv()
{
	fm_remove_entity_name("fake_corpse")
	fm_remove_entity_name("dbmod_shild")
	fm_remove_entity_name("totem_wplywa")
	fm_remove_entity_name("Mine")
	
	static players[32], num
	get_players(players, num, "a")
	for(new i = 0; i < num; i++)
	{
		if(is_user_connected(players[i]))
		{
			reset_player(players[i])
			msg_bartime(players[i], 0)
		}
	}
}

public reset_player(id)
{
	remove_task(TASKID_REVIVE + id)
	remove_task(TASKID_RESPAWN + id)
	remove_task(TASKID_CHECKRE + id)
	remove_task(TASKID_CHECKST + id)
	remove_task(TASKID_ORIGIN + id)
	remove_task(TASKID_SETUSER + id)
	remove_task(GLUTON+id)
	
	
	g_revive_delay[id] 	= 0.0
	g_wasducking[id] 	= false
	g_body_origin[id] 	= Float:{0.0, 0.0, 0.0}
	
}

public fwd_playerpostthink(id)
{
	if(!is_user_connected(id)) return FMRES_IGNORED
	
	if(g_haskit[id]==0) return FMRES_IGNORED
	
	if(!is_user_alive(id))
	{
		Display_Icon(id ,ICON_HIDE ,"rescue" ,0,160,0)
		return FMRES_IGNORED
	}
	
	new body = find_dead_body(id)
	if(fm_is_valid_ent(body))
	{
		new lucky_bastard = pev(body, pev_owner)
		
		if(!is_user_connected(lucky_bastard))
			return FMRES_IGNORED
		
		new lb_team = get_user_team(lucky_bastard)
		if(lb_team == 1 || lb_team == 2 )
			Display_Icon(id ,ICON_FLASH ,"rescue" ,0,160,0)
	}
	else
		Display_Icon(id , ICON_SHOW,"rescue" ,0,160,0)
	
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
	if(equal(sound, "common/wpn_denyselect.wav"))
	{
		Use_Spell(id);
		//return FMRES_SUPERCEDE;
	}

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
	if(lb_team != 1 && lb_team != 2)
		return FMRES_IGNORED
	
	static name[32]
	get_user_name(lucky_bastard, name, 31)
	client_print(id, print_chat, "Uzdrawianie %s", name)
	
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
	if(lb_team != 1 && lb_team != 2)
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
			
			new args[2]
			args[0]=lucky_bastard
			
			if(get_user_team(id)!=get_user_team(lucky_bastard))
			{
				change_health(id,30,0,"")
				player_xp[id]+=5
				args[1]=1
			}
			else
			{
				args[1]=0
				set_task(0.1, "task_respawn", TASKID_RESPAWN + lucky_bastard,args,2)
				player_xp[id]+=5
			}
			
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

public task_origin(args[])
{
	new id = args[0]
	engfunc(EngFunc_SetOrigin,id, g_body_origin[id])
	
	static  Float:origin[3]
	pev(id, pev_origin, origin)
	set_pev(id, pev_zorigin, origin[2])
	
	set_task(0.1, "task_stuck_check", TASKID_CHECKST + id,args,2)
	
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
	if(is_user_bot(id)||!is_user_alive(id)||!is_user_connected(id))
		return
	
	message_begin(MSG_ONE, g_msg_bartime, _, id)
	write_byte(seconds)
	write_byte(0)
	message_end()
}

public task_respawn(args[]) 
{
	new id = args[0]
	
	if (!is_user_connected(id) || is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR) return
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE) 
	dllfunc(DLLFunc_Think, id) 
	dllfunc(DLLFunc_Spawn, id) 
	set_pev(id, pev_iuser1, 0)
	
	set_task(0.1, "task_check_respawn", TASKID_CHECKRE + id,args,2)
	
}

public task_check_respawn(args[])
{
	new id = args[0]
	
	if(pev(id, pev_iuser1))
		set_task(0.1, "task_respawn", TASKID_RESPAWN + id,args,2)
	else
		set_task(0.1, "task_origin", TASKID_ORIGIN + id,args,2)
	
}

public task_stuck_check(args[])
{
	new id = args[0]
	
	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	if(origin[2] == pev(id, pev_zorigin))
		set_task(0.1, "task_respawn", TASKID_RESPAWN + id,args,2)
	else
		set_task(0.1, "task_setplayer", TASKID_SETUSER + id,args,2)
}
//godmode
public task_setplayer(args[])
{
	new id = args[0]
	
	fm_give_item(id, "weapon_knife")
	
	if(args[1]==1)
	{
		fm_give_item(id, "weapon_mp5navy")
		change_health(id,999,0,"")		
		set_user_godmode(id, 1)
		
		new newarg[1]
		newarg[0]=id
		
		set_task(3.0,"god_off",id+95123,newarg,1)
	}
	else
	{
		fm_set_user_health(id, get_pcvar_num(cvar_revival_health)+player_intelligence[args[1]])
		
		Display_Fade(id,seconds(2),seconds(2),0,0,0,0,255)
	}
	
	if(player_item_id[id]==17) fm_set_user_health(id,5)
}

public god_off(args[])
{
	set_user_godmode(args[0], 0)
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

public count_jumps(id)
{
	if( is_user_connected(id))
	{
		if( player_class[id]== Paladyn ) JumpsMax[id]=6+floatround(player_intelligence[id]/10.0)+player_b_buty[id]
		else if( player_class[id]== Mefisto ) JumpsMax[id]=3+floatround(player_intelligence[id]/10.0)+player_b_buty[id]
		else JumpsMax[id]=0
		if(player_b_buty[id] > 0) JumpsLeft[id]=player_b_buty[id]
		if(ile_wykonano[id]>=26) ++JumpsMax[id]
	}
}
////////////////////////////////////////////////////////////////////////////////
//                                  Noze                                      //
////////////////////////////////////////////////////////////////////////////////
public give_knife(id)
{
	new knifes = 0
	if(player_class[id] == Ninja) knifes = 8 + floatround ( player_intelligence[id]/10.0 , floatround_floor )
		
	max_knife[id] = knifes
	player_knife[id] = knifes
}

public command_knife(id) 
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	
	if(!player_knife[id])
	{
		client_print(id,print_center,"Nie masz juz nozy do rzucania")
		return PLUGIN_HANDLED
	}
	
	if(tossdelay[id] > get_gametime() - 0.9) return PLUGIN_HANDLED
	else tossdelay[id] = get_gametime()
	
	player_knife[id]--
	
	if (player_knife[id] == 1) {
		client_print(id,print_center,"Zostal ci tylko 1 noz!")
	}
	
	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	Ent = create_entity("info_target")
	
	if (!Ent) return PLUGIN_HANDLED
	
	entity_set_string(Ent, EV_SZ_classname, "throwing_knife")
	entity_set_model(Ent, "models/diablomod/w_throwingknife.mdl")
	
	new Float:MinBox[3] = {-1.0, -7.0, -1.0}
	new Float:MaxBox[3] = {1.0, 7.0, 1.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)
	
	vAngle[0] -= 90
	
	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)
	
	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 6)
	entity_set_edict(Ent, EV_ENT_owner, id)
	
	VelocityByAim(id, get_cvar_num("diablo_knife_speed") , Velocity)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	return PLUGIN_HANDLED
}

public touchKnife(knife, id)
{
	new kid = entity_get_edict(knife, EV_ENT_owner)
	
	if(is_user_alive(id)) 
	{
		new movetype = entity_get_int(knife, EV_INT_movetype)
		
		if(movetype == 0) 
		{
			if( player_knife[id] < max_knife[id] )
			{
				player_knife[id] += 1
				client_print(id,print_center,"Obecna liczba nozy: %i",player_knife[id])
			}
			emit_sound(knife, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			remove_entity(knife)
		}
		else if (movetype != 0) 
		{
			if(kid == id) return
			
			remove_entity(knife)
			
			if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(id) == get_user_team(kid)) return
			
			entity_set_float(id, EV_FL_dmg_take, 18.0)
			ExecuteHamB(Ham_TakeDamage, id, ent, kid, 30.0, DMG_ENERGYBEAM );	
			
			message_begin(MSG_ONE,get_user_msgid("ScreenShake"),{0,0,0},id)
			write_short(7<<14)
			write_short(1<<13)
			write_short(1<<14)
			message_end()		
			
			if(get_user_team(id) == get_user_team(kid)) {
				new name[33]
				get_user_name(kid,name,32)
				client_print(0,print_chat,"%s attacked a teammate",name)
			}
			
			emit_sound(id, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			
		}
	}
}

public touchWorld(knife, world)
{
	entity_set_int(knife, EV_INT_movetype, 0)
	emit_sound(knife, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public touchbreakable(ent1, ent2)
{
	if(!is_valid_ent(ent1) || !is_valid_ent(ent2)) return PLUGIN_CONTINUE
	
	new name[32], breakable, ent;
	entity_get_string(ent1, EV_SZ_classname, name, 31)
	if(equali(name, "func_breakable"))
	{
		breakable = ent1
		ent = ent2
	}
	else
	{
		breakable = ent2
		ent = ent1
	}
	if(entity_get_int(breakable, EV_INT_impulse) == 0)
	{
		new Float: b_hp = entity_get_float(breakable, EV_FL_health)
		if(b_hp > 80) entity_set_float(breakable, EV_FL_health, b_hp-50.0)
		else dllfunc(DLLFunc_Use, breakable, ent)
	}
	else
	{
		entity_get_string(ent, EV_SZ_classname, name, 31)
		if(equali(name, "throwing_knife"))
		{
			entity_set_int(ent, EV_INT_movetype, 0)
			emit_sound(ent, CHAN_ITEM, "weapons/knife_hitwall1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		else remove_entity(ent)
	}
	return PLUGIN_CONTINUE
}
public kill_all_entity(classname[]) {
	new iEnt = find_ent_by_class(-1, classname)
	while(iEnt > 0) {
		remove_entity(iEnt)
		iEnt = find_ent_by_class(iEnt, classname)		
	}
}
////////////////////////////////////////////////////////////////////////////////
//                             koniec z nozami                                //
//////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                             Hunter part code                               //
////////////////////////////////////////////////////////////////////////////////
public command_arrow(id) 
{
	
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	
	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	Ent = create_entity("info_target")
	
	if (!Ent) return PLUGIN_HANDLED
	
	entity_set_string(Ent, EV_SZ_classname, "xbow_arrow")
	entity_set_model(Ent, cbow_bolt)
	
	new Float:MinBox[3] = {-2.8, -2.8, -0.8}
	new Float:MaxBox[3] = {2.8, 2.8, 2.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)
	
	vAngle[0]*= -1
	Origin[2]+=10
	
	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)
	
	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 5)
	entity_set_edict(Ent, EV_ENT_owner, id)
	
	VelocityByAim(id, get_cvar_num("diablo_arrow_speed") , Velocity)
	set_rendering (Ent,kRenderFxGlowShell, 255,0,0, kRenderNormal,56)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	return PLUGIN_HANDLED
}

public command_bow(id) 
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	if(bow[id] == 1){
		entity_set_string(id,EV_SZ_viewmodel,cbow_VIEW)
		entity_set_string(id,EV_SZ_weaponmodel,cvow_PLAYER)
		bowdelay[id] = get_gametime()
	}
	else
	{
		entity_set_string(id,EV_SZ_viewmodel,KNIFE_VIEW)
		entity_set_string(id,EV_SZ_weaponmodel,KNIFE_PLAYER)
		bow[id]=0
	}
	return PLUGIN_CONTINUE
}

public toucharrow(arrow, id)
{	
	new kid = entity_get_edict(arrow, EV_ENT_owner)
	new lid = entity_get_edict(arrow, EV_ENT_enemy)
	
	if(is_user_alive(id)) 
	{
		if(kid == id || lid == id) return
		if(get_user_team(id) == get_user_team(kid)) return
		
		entity_set_edict(arrow, EV_ENT_enemy,id)
		new Float:fDamage = player_intelligence[kid]*2.0 + 100 + power_bolt[kid]
		
		Effect_Bleed(id,248)
		TakeDamage(id, kid, fDamage, DMG_ENERGYBEAM, "kusza");
		
		message_begin(MSG_ONE,get_user_msgid("ScreenShake"),{0,0,0},id); 
		write_short(7<<14); 
		write_short(1<<13); 
		write_short(1<<14); 
		message_end();
		
		emit_sound(id, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		remove_entity(arrow)
	}
}
public touchWorld2(arrow, world)
{
	remove_entity(arrow)
}
public change_health(id,hp,attacker,weapon[])
{
	new g_race_heal
	if(ile_wykonano[id]>=28)
		g_race_heal=15
	else if(ile_wykonano[id]>=13)
		g_race_heal=10
	if( get_user_flags(id) & ADMIN_LEVEL_H)
		g_race_heal+=15
	if(player_b_startaddhp[id] > 0)
		g_race_heal+=player_b_startaddhp[id]
	if(is_user_alive(id) && is_user_connected(id))
	{
		new health = get_user_health(id)
		if(hp>0)
		{
			new m_health = race_heal[player_class[id]]+g_race_heal+player_strength[id]*2
			if(player_item_id[id]==17 &&hp>0)
			{
				set_user_health(id,health+floatround(float(hp/10),floatround_floor)+1)
			}
			else if (hp+health>m_health) set_user_health(id,m_health)
			else set_user_health(id,get_user_health(id)+hp)
		}
		else
		{
			if(health+hp<1)
			{
				UTIL_Kill(attacker,id,weapon)
			}
			else set_user_health(id,get_user_health(id)+hp)
		}
	}
}

public UTIL_Kill(attacker,id,weapon[])
{
	if( is_user_alive(id)){
		new bPlayerAttack = is_user_connected(attacker);
		
		if(get_user_team(attacker)!=get_user_team(id) && bPlayerAttack)
			set_user_frags(attacker,get_user_frags(attacker) +1);
		
		if(get_user_team(attacker)==get_user_team(id))
			set_user_frags(attacker,get_user_frags(attacker) -1);
		
		cs_set_user_deaths(id, cs_get_user_deaths(id)+1)
		user_kill(id,1) 
		
		if(is_user_connected(attacker) && attacker!=id)
		{
			award_kill(attacker,id)
			if(is_user_alive(attacker)) award_item(attacker,0)
			
			
		}
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0) 
		write_byte(attacker) 
		write_byte(id) 
		write_byte(0) 
		write_string(weapon) 
		message_end() 
		
		if(bPlayerAttack){
			message_begin(MSG_ALL,gmsgScoreInfo) 
			write_byte(attacker) 
			write_short(get_user_frags(attacker)) 
			write_short(get_user_deaths(attacker)) 
			write_short(0) 
			write_short(get_user_team(attacker)) 
			message_end() 
		}
		
		message_begin(MSG_ALL,gmsgScoreInfo) 
		write_byte(id) 
		write_short(get_user_frags(id)) 
		write_short(get_user_deaths(id)) 
		write_short(0) 
		write_short(get_user_team(id)) 
		message_end()
	}
}
stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	message_begin( MSG_ONE, g_msg_screenfade,{0,0,0},id )
	write_short( duration )	// Duration of fadeout
	write_short( holdtime )	// Hold time of color
	write_short( fadetype )	// Fade type
	write_byte ( red )		// Red
	write_byte ( green )		// Green
	write_byte ( blue )		// Blue
	write_byte ( alpha )	// Alpha
	message_end()
}

stock Display_Icon(id ,enable ,name[] ,red,green,blue)
{
	if (!pev_valid(id) || is_user_bot(id))
	{
		return PLUGIN_HANDLED
	}
	///new string [8][32] = {"dmg_rad","item_longjump","dmg_shock","item_healthkit","dmg_heat","suit_full","cross","dmg_gas"}
	
	message_begin( MSG_ONE, g_msg_statusicon, {0,0,0}, id ) 
	write_byte( enable ) 	
	write_string( name ) 
	write_byte( red ) // red 
	write_byte( green ) // green 
	write_byte( blue ) // blue 
	message_end()
	
	return PLUGIN_CONTINUE
}

public createBlockAiming(id)
{
	
	new Float:vOrigin[3];
	new Float:vAngles[3]
	entity_get_vector(id,EV_VEC_v_angle,vAngles)
	entity_get_vector(id,EV_VEC_origin,vOrigin)
	new Float:offset = distance_to_floor(vOrigin)
	vOrigin[2]+=17.0-offset
	//create the block
	
	if(vAngles[1]>45.0&&vAngles[1]<135.0)
	{
		vOrigin[0]+=0.0
		vOrigin[1]+=34.0
		if(chacke_pos(vOrigin,0)==0) return
		make_shild(id,vOrigin,vAngles1,gfBlockSizeMin1,gfBlockSizeMax1)
	}
	else if(vAngles[1]<-45.0&&vAngles[1]>-135.0)
	{
		vOrigin[0]+=0.0
		vOrigin[1]+=-34.0
		if(chacke_pos(vOrigin,0)==0) return
		make_shild(id,vOrigin,vAngles1,gfBlockSizeMin1,gfBlockSizeMax1)
	}
	else if(vAngles[1]>-45.0&&vAngles[1]<45.0)
	{
		vOrigin[0]+=34.0
		vOrigin[1]+=0.0
		if(chacke_pos(vOrigin,1)==0) return
		make_shild(id,vOrigin,vAngles2,gfBlockSizeMin2,gfBlockSizeMax2)
	}
	else
	{
		vOrigin[0]+=-34.0
		vOrigin[1]+=0.0
		if(chacke_pos(vOrigin,1)==0) return
		make_shild(id,vOrigin,vAngles2,gfBlockSizeMin2,gfBlockSizeMax2)
	}
}

public make_shild(id,Float:vOrigin[3],Float:vAngles[3],Float:gfBlockSizeMin[3],Float:gfBlockSizeMax[3])
{
	new ent = create_entity("info_target")
	
	//make sure entity was created successfully
	if (is_valid_ent(ent))
	{
		//set block properties
		entity_set_string(ent, EV_SZ_classname, "dbmod_shild")
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE)
		entity_set_float(ent,EV_FL_health,50.0+float(player_intelligence[id]*2))
		entity_set_float(ent,EV_FL_takedamage,1.0)
		
		entity_set_model(ent, "models/diablomod/bm_block_platform.mdl");
		entity_set_vector(ent, EV_VEC_angles, vAngles)
		entity_set_size(ent, gfBlockSizeMin, gfBlockSizeMax)
		
		entity_set_edict(ent,EV_ENT_euser1,id)
		
		entity_set_origin(ent, vOrigin)
		
		num_shild[id]--
		
		return 1
	}
	return 0
}

public call_cast(id)
{ 
	set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)		
	switch(player_class[id])
	{
		case Mag:
		{
			if(n_moc_nozowa[id]>=3)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				fired[id]++
				show_hudmessage(id, "Masz %i magicznych kul",fired[id])
			}
		}
		case Mnich:
		{
			if(n_moc_nozowa[id]>=2)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				Mnichlecz(id)
				show_hudmessage(id, "Wspierasz sojusznikow przyrwacajac im oraz sobie 20 punktow zdrowia")
			}
		}
		case Paladyn:
		{
			if(n_moc_nozowa[id]>=7)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				golden_bulet[id]++
				if(golden_bulet[id]>3)
				{
					golden_bulet[id]=3
					show_hudmessage(id, "Mozesz miec maksymalnie 3 pociski",golden_bulet[id]) 
				}
				else show_hudmessage(id, "Masz %i magiczny(ch) pocisk(i) ",golden_bulet[id]) 
			}
		}
		case Nekromanta:
		{
			if(n_moc_nozowa[id]>=4)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				new lecz = 25+(player_intelligence[id]/5)
				change_health(id,lecz,0,"")
				show_hudmessage(id, "Uleczyles sie o %i punktow zdrowia",lecz)
			}
		}
		case Zabojca:
		{
			if(n_moc_nozowa[id]>=2)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				show_hudmessage(id, "Jestes niewidzialny! Zmiana broni uwidoczni cie") 
				invisible_cast[id]=1
				set_renderchange(id)
			}
		}
		case Barbarzynca:
		{
			if(n_moc_nozowa[id]>=7)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				ultra_armor[id]++
				if(ultra_armor[id]>3)
				{
					ultra_armor[id]=3
					show_hudmessage(id, "Maksymalna wartosc pancerza to 4",ultra_armor[id]) 
				}
				else show_hudmessage(id, "Magiczny pancerz wytrzyma %i strzal(y)",ultra_armor[id]) 
			}
		}
		case Ninja:
		{
			if(ilerazysip[id] >= 80)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!") 
			}
			else{
				n_moc_nozowa[id]++
				ilerazysip[id]+=20
				show_hudmessage(id, "Zyskujesz 20 punktow predkosci")
				set_speedchange(id)
			}
		}
		case Imp:
		{
			if(ilerazysip[id] >= 80)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!") 
			}
			else{
				n_moc_nozowa[id]++
				ilerazysip[id]+=20
				show_hudmessage(id, "Zyskujesz 20 punktow predkosci")
				set_speedchange(id)
			}
		}
		case Hunter:
		{
			if(n_moc_nozowa[id]>=2)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				client_cmd(id, "spk diablosound/hit.wav")
				power_bolt[id] += 20
				fm_give_item(id, "weapon_hegrenade")
				show_hudmessage(id, "Otrzymales He. Twoja kusza zadaje %i dodatkowych obrazen", power_bolt[id])
			}
		}
/*		case Tyrael:
		{
			if(n_moc_nozowa[id]>=2)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				if(player_item_id[id] !=0)
				{
					show_hudmessage(id, "Wyrzuc aktualny przedmiot aby wylosowac kolejny!")
					return;
				}
				n_moc_nozowa[id]++
				client_cmd(id, "spk diablosound/hit.wav")
				award_item(id,0)
				show_hudmessage(id, "Otrzymales przedmiot!")
			}
		}*/
		case Cien:
		{
			if(n_moc_nozowa[id]>=3)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				if(n_krwawynaboj[id] == 1){
				show_hudmessage(id, "Mozesz miec tylko jeden krwawy naboj w danej chwili")
				return;
				}
				n_krwawynaboj[id] = 1
				n_moc_nozowa[id]++
				show_hudmessage(id, "Dostales Krwawy Naboj")
			}
		}
		case Szaman:
		{
			if(n_moc_nozowa[id]>=7)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc uleczen na runde")
			}
			else{
				n_moc_nozowa[id]++
				new lecz = 20+(player_intelligence[id]/5)
				change_health(id,lecz,0,"")
				show_hudmessage(id, "Uleczyles %i hp .",lecz)
			}
		}
		case Duch:
		{
			if(n_moc_nozowa[id]>=2)
			{
				show_hudmessage(id, "W tej rundzie nie mozesz juz uzyc mocy!")
			}
			else{
				n_moc_nozowa[id]++
				show_hudmessage(id, "Jestes niewidzialny dopoki nie zmienisz broni") 
				invisible_cast[id]=1
				set_renderchange(id)
			}
		}
		case Khazra:
		{
			if(n_moc_nozowa[id]>=3)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc dodatkowych piorunow na runde")
			}
			else{
				if(c_piorun[id] >= 2){
					show_hudmessage(id, "Mozesz miec maksymalnie 2 pioruny")
				}
				else{
					c_piorun[id]++
					n_moc_nozowa[id]++
				}
			}
		}
		case Andariel:
		{
			if(n_moc_nozowa[id]>=1)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc dodatkowych obrazen na runde")
			}
			else{
				c_dmgandariel[id] += 5
				n_moc_nozowa[id]++
				show_hudmessage(id, "+ 5 dodatkowych obrazen")
			}
		}
		case Baal:
		{
			if(ilerazysip[id] >= 60)
			{
				show_hudmessage(id, "Maksymalna predkosc osiagnieta") 
			}
			else{
				n_moc_nozowa[id]++
				ilerazysip[id]+=20
				show_hudmessage(id, "+ 20 do predkosci")
				set_speedchange(id)
			}
		}
		case Mefisto:
		{
			if(n_moc_nozowa[id]>=3)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc dodatkowych LongJump'ow na runde")
			}
			else{
				if(JumpsLeft[id] >= 4){
					show_hudmessage(id, "Mozesz miec maksymalnie 4 LongJumpy")
				}
				else{
					JumpsLeft[id]++
					n_moc_nozowa[id]++
				}
			}
		}
		case Diablo:
		{
			if(n_moc_nozowa[id]>=1)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc losowan na runde")
			}
			else{
				if(player_item_id[id] !=0) return;
				n_moc_nozowa[id]++
				client_cmd(id, "spk diablosound/hit.wav")
				award_item(id,0)
				show_hudmessage(id, "Znalazles Item")
			}
		}
		case Nihlathak: 
		{
			if(n_moc_nozowa[id]>=3)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc dodatkowych granatow na runde")
			}
			else{
				fm_give_item(id, "weapon_flashbang")
				fm_give_item(id, "weapon_flashbang")
				fm_give_item(id, "weapon_hegrenade")
				fm_give_item(id, "weapon_smokegrenade")
				show_hudmessage(id, "[Nihlathak] Dostales Pakiet Granatow")
				n_moc_nozowa[id]++
			}
		}
		case Griswold:
		{
			if(n_moc_nozowa[id]>=5)
			{
				show_hudmessage(id, "Osiagnales maskymalna wartosc pancerza na runde")
			}
			else{
				ultra_armor[id]++
				n_moc_nozowa[id]++
				if(ultra_armor[id]>3)
				{
					ultra_armor[id]=3
					show_hudmessage(id, "Maksymalna wartosc pancerza to 3",ultra_armor[id]) 
				}
				else show_hudmessage(id, "Magiczny pancerz wytrzyma %i strzalow",ultra_armor[id])
			}
		}
		case Kowal:
		{
			if(n_moc_nozowa[id]>=1)
			{
				show_hudmessage(id, "Osiagnales maskymalna ilosc losowan na runde")
			}
			else{
				if(player_item_id[id] !=0) return;
				n_moc_nozowa[id]++
				client_cmd(id, "spk diablosound/hit.wav")
				award_item(id,0)
				show_hudmessage(id, "Znalazles Item") 
			}
		}
	}
	if(player_b_fireball[id] > 0 && fired[id] <= 0){
		fired[id]++
		client_print(id,print_chat,"Dostales magiczna kule")
	}
}

public chacke_pos(Float:vOrigin[3],axe)
{
	new test=0
	vOrigin[axe]-=15.0
	if(distance_to_floor(vOrigin)<31.0) test++
	vOrigin[axe]+=15.0
	if(distance_to_floor(vOrigin)<31.0) test++
	vOrigin[axe]+=15.0
	if(distance_to_floor(vOrigin)<31.0) test++
	if(test<2) return 0
	vOrigin[axe]-=15.0
	return 1
}

public fw_traceline(Float:vecStart[3],Float:vecEnd[3],ignoreM,id,trace) // pentToSkip == id, for clarity
{
	
	if(!is_user_connected(id))
		return FMRES_IGNORED;
	
	// not a player entity, or player is dead
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	new hit = get_tr2(trace, TR_pHit)	
	
	// not shooting anything
	if(!(pev(id,pev_button) & IN_ATTACK))
		return FMRES_IGNORED;
	
	new h_bulet=0
	
	if(golden_bulet[id]>0)
	{
		golden_bulet[id]--
		h_bulet=1
	}
	
	if(is_valid_ent(hit))
	{
		new name[64]
		entity_get_string(hit,EV_SZ_classname,name,63)
		
		if(equal(name,"dbmod_shild"))
		{
			new Float: ori[3]
			entity_get_vector(hit,EV_VEC_origin,ori)
			set_tr2(trace,TR_vecEndPos,vecEnd)
			if(after_bullet[id]>0)
			{			
				new Float: health=entity_get_float(hit,EV_FL_health)
				entity_set_float(hit,EV_FL_health,health-3.0)
				if(health-1.0<0.0) remove_entity(hit)
				after_bullet[id]--
			}
			set_tr2(trace,TR_iHitgroup,8);
			set_tr2(trace,TR_flFraction,1.0);
			return FMRES_SUPERCEDE;
		}
	}	
	if(is_user_alive(hit))
	{
		if(h_bulet > 0)
		{
			set_tr2(trace, TR_iHitgroup, HIT_HEAD) // Redirect shot to head
			
			// Variable angles doesn't really have a use here.
			static hit, Float:head_origin[3], Float:angles[3]
			
			hit = get_tr2(trace, TR_pHit) // Whomever was shot
			engfunc(EngFunc_GetBonePosition, hit, 8, head_origin, angles) // Find origin of head bone (8)
			
			set_tr2(trace, TR_vecEndPos, head_origin) // Blood now comes out of the head!
			Create_TE_SPRITETRAIL(id, hit, bake, 15, 15, 1, 2, 6 );
		}
		if(ultra_armor[hit]>0 || (player_class[hit]==Paladyn && random_num(1,10)==1) || random_num(0,player_ultra_armor_left[hit])==1)
		{
			if(after_bullet[id]>0)
			{
				if(ultra_armor[hit]>0) ultra_armor[hit]--
				else if(player_ultra_armor_left[hit]>0)player_ultra_armor_left[hit]--
					after_bullet[id]--
			}
			set_tr2(trace, TR_iHitgroup, 8)
		}
			//antyhs
		if(get_tr2(trace, TR_iHitgroup) != HIT_HEAD)
			return FMRES_IGNORED;
		
		new iHit = get_tr2(trace, TR_pHit);
	
		if(!is_user_connected(iHit))
			return FMRES_IGNORED;

		if(!player_b_antyhs[iHit])
			return FMRES_IGNORED;
		
		set_tr2(trace, TR_iHitgroup, 8);
			return FMRES_IGNORED
	}
	
	return FMRES_IGNORED;
}

stock Float:distance_to_floor(Float:start[3], ignoremonsters = 1) {
	new Float:dest[3], Float:end[3];
	dest[0] = start[0];
	dest[1] = start[1];
	dest[2] = -8191.0;
	
	engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, 0, 0);
	get_tr2(0, TR_vecEndPos, end);
	
	//pev(index, pev_absmin, start);
	new Float:ret = start[2] - end[2];
	
	return ret > 0 ? ret : 0.0;
}
public giveitem(id, level, cid) 
{ 
	if(!cmd_access(id,level, cid, 3)) 
		return PLUGIN_HANDLED; 
	
	new szName[32]; 
	read_argv(1, szName, 31); 
	new iTarget=cmd_target(id,szName,0); 
	if(iTarget)
	{ 
		get_user_name(iTarget, szName, 31); 
		new szItem[10], iItem; 
		read_argv(2, szItem, 9); 
		iItem=str_to_num(szItem); 
		client_print(id, print_console, "Do %s wyslano item nr %d",szName, iItem); 
		award_item(iTarget, iItem); 
		set_gravitychange(iTarget)
		set_speedchange(iTarget)
		set_renderchange(iTarget)
	} 
	return PLUGIN_HANDLED 
}
public giveartefakt(id, level, cid) 
{ 
	if(!cmd_access(id,level, cid, 3)) 
		return PLUGIN_HANDLED; 
	
	new szName[32]; 
	read_argv(1, szName, 31); 
	new iTarget=cmd_target(id,szName,0); 
	if(iTarget)
	{ 
		get_user_name(iTarget, szName, 31); 
		new szItem[10], iItem; 
		read_argv(2, szItem, 9); 
		iItem=str_to_num(szItem); 
		client_print(id, print_console, "Do %s wyslano artefakt nr %d",szName, iItem); 
		dropartefakt(iTarget)
		dajartefakt(iTarget, iItem); 
	} 
	return PLUGIN_HANDLED 
}
public CmdGiveExp(id, level, cid) 
{ 
	if(!cmd_access(id,level, cid, 3)) 
		return PLUGIN_HANDLED; 
	
	new szPlayer[32]; 
	read_argv(1,szPlayer, 31); 
	
	new iPlayer[ 32 ], iNum, all, szName[32]
	get_players( iPlayer, iNum, "c" );
	
	new szExp[10], iExp; 
	read_argv(2, szExp, 9); 
	iExp=str_to_num(szExp);
	
	if( equal( szPlayer, "@kazdy" ) )
	{
		for( new i; i < iNum; i++ )
		{
			all = iPlayer[ i ];
			get_user_name(all, szName, sizeof szName - 1)
			console_print(id, "%s dostal %i expa",szName, iExp); 
			if(player_lvl[all]>8) Give_Xp(all,iExp)
		}
		ColorChat(0, GREEN, "^x04 Kazdy^x01 otrzymal po ^x03 %i ^x01 Expa",iExp)
		log_to_file("wplaty.log", "Kazdy dostal %i expa",iExp);
		
		
	}
	else 
	{
		new iTarget=cmd_target(id,szPlayer,0);
		if( !iTarget ) 
		{
			return PLUGIN_HANDLED;
		} 
		get_user_name(iTarget, szName, sizeof szName - 1)
		console_print(id, "%s dostal %i expa",szName, iExp); 
		log_to_file("wplaty.log", "dal %s - %i expa",szName, iExp);
		Give_Xp(iTarget,iExp)
	}
	return PLUGIN_HANDLED 
}

public CmdGivezloto(id, level, cid) 
{ 
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[10];
	read_argv(1,arg1,32);
	read_argv(2,arg2,9);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new zloto = str_to_num(arg2);
	zloto_gracza[player] += zloto
	return PLUGIN_HANDLED;
}


public CmdGivemana(id, level, cid) 
{ 
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[10];
	read_argv(1,arg1,32);
	read_argv(2,arg2,9);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new mana = str_to_num(arg2);
	mana_gracza[player] += mana
	return PLUGIN_HANDLED;
}
public Create_TE_BEAMPOINTS(start[3], end[3],startFrame, frameRate, life, width, noise, red, green, blue, alpha, spid,sprite){
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMPOINTS )
	write_coord( start[0] )
	write_coord( start[1] )
	write_coord( start[2] )
	write_coord( end[0] )
	write_coord( end[1] )
	write_coord( end[2] )
	write_short( sprite )			// model
	write_byte( startFrame )		// start frame
	write_byte( frameRate )			// framerate
	write_byte( life )				// life
	write_byte( width )				// width
	write_byte( noise )				// noise
	write_byte( red )				// red
	write_byte( green )				// green
	write_byte( blue )				// blue
	write_byte( alpha )				// brightness
	write_byte( spid )				// speed
	message_end()
}
public piorun(id)
{
	if (c_piorun[id] <= 0)
	{
		client_print(id, print_center, "Nie masz piorunow!")
		return PLUGIN_CONTINUE;
	}
	if(poprzednie_uzycie[id]+2.0>get_gametime()) {
		client_print(id,print_chat,"Piorunu mozesz uzyc raz na 3 sek.");
		return PLUGIN_HANDLED;
	}
	if (freeze_ended && is_user_alive(id))
	{
		//Target nearest non-friendly player
		new target = Find_Best_Angle(id,650.0+player_intelligence[id],false)
		if (!is_valid_ent(target))
		{
			client_print(id, print_center, "Brak celu.")
			return PLUGIN_HANDLED
		}
		if (pev(target,pev_rendermode) == kRenderTransTexture || player_b_inv[target] < 20 && player_b_inv[target] != 0|| player_class[target] == Ninja || invisible_cast[target] == 1||!fm_is_ent_visible(id,target))
		{
			hudmsg(id,2.0,"Nie mozna wyczarowac Pioruna ")
			return PLUGIN_CONTINUE
		}
		new iEnd[3], iStart[3]
		get_user_origin(target,iEnd)
		get_user_origin(id,iStart)
		new fDamage
		fDamage = 65+player_intelligence[id]
		Create_TE_BEAMPOINTS(iStart, iEnd, 0, 0, 6, 50, 60, 200, 160, 40, 255, 0,sprite_beam)
		Display_Fade(target,2600,2600,0,255,0,0,15)
		c_piorun[id]--
		poprzednie_uzycie[id]=floatround(get_gametime());
		
//		TakeDamage(target, id, fDamage, DMG_SHOCK, "piorun");
		change_health(target,-fDamage,id,"grenade")
			
		emit_sound (id, 0, "diablosound/merial.wav", 0.5, 0.8,0, 100 )
		wait1[id]=floatround(halflife_time())
	}
	if(c_piorun[id] <= 0)
		Display_Icon(id,ICON_HIDE,"dmg_shock",0,0,0)
		
	return PLUGIN_HANDLED
}
public CmdGiveKamien(id, level, cid) 
{ 
	if(!cmd_access(id,level, cid, 3)) 
		return PLUGIN_HANDLED; 
	
	new szPlayer[32]; 
	read_argv(1,szPlayer, 31); 
	new iTarget=cmd_target(id,szPlayer,0); 
	if(iTarget)
	{ 
		new szZadanie[10], iZadanie; 
		read_argv(2, szZadanie, 9); 
		iZadanie=str_to_num(szZadanie);
		new szName[32]
		get_user_name(iTarget, szName, sizeof szName - 1)
		console_print(id, "%s dostal %i krysztalow",szName, iZadanie); 
		log_to_file("wplaty.log", "dal %s - %i krysztalow",szName, iZadanie);
		player_krysztal[iTarget] += iZadanie
		zapiszk(iTarget)
	} 
	return PLUGIN_HANDLED 
}
public ElectroSound(iOrigin[3])
{
	new Entity = create_entity("info_target")
	
	new Float:flOrigin[3]
	IVecFVec(iOrigin, flOrigin)
	
	entity_set_origin(Entity, flOrigin)
	
	emit_sound(Entity, CHAN_WEAPON, "diablosound/spark6.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	remove_entity(Entity)
}
public ElectroRing(const Float:originF3[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0)
	write_byte(TE_BEAMCYLINDER) 
	engfunc(EngFunc_WriteCoord, originF3[0]) 
	engfunc(EngFunc_WriteCoord, originF3[1]) 
	engfunc(EngFunc_WriteCoord, originF3[2]) 
	engfunc(EngFunc_WriteCoord, originF3[0])
	engfunc(EngFunc_WriteCoord, originF3[1]) 
	engfunc(EngFunc_WriteCoord, originF3[2]+100.0) 
	write_short(ElectroSpr) 
	write_byte(0)
	write_byte(0) 
	write_byte(4) 
	write_byte(60)
	write_byte(0) 
	write_byte(41) 
	write_byte(138) 
	write_byte(255) 
	write_byte(200)
	write_byte(0) 
	message_end()
}
public exp(id)
{
	ColorChat(id, GREEN, "Poziom: ^x04%i ^x01- Masz ^x03(%d/%d)^x01 Doswiadczenia", player_lvl[id], player_xp[id], LevelXP[player_lvl[id]])
	ColorChat(id, GREEN, "Do nastepnego poziomu brakuje ^x04%d^x01 Doswiadczenia", LevelXP[player_lvl[id]]-player_xp[id])
}
public Mnichlecz(id)
{
	new Players[32], playerCount, a, name[32]
	get_players(Players, playerCount, "ah") 
	get_user_name(id, name, 31) 
	for (new i=0; i<playerCount; i++) 
	{
		a = Players[i] 
		
		if (get_user_team(a) != get_user_team(id))
			continue
		
		change_health(a,10,0,"")
		ColorChat(id,GREEN,"Pewiem Mnich Cie uleczyl")
	}    
}
public ozywres(id)
{
	if(is_user_alive(id)||is_user_bot(id)) return PLUGIN_HANDLED;
	
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	fm_give_item(id, "weapon_knife");
	
	return PLUGIN_HANDLED;
}
public add_bonus_korzen(attacker_id,id)
{
	if((player_class[attacker_id] == Nihlathak && (random_num(1,10) == 1) && get_user_team(attacker_id) != get_user_team(id)) || (player_b_sidla[attacker_id] > 0 && (random_num(1,player_b_sidla[attacker_id]) == 1) && get_user_team(attacker_id) != get_user_team(id))){
		
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		
		if (zatakowany[id] == 1)
			return PLUGIN_HANDLED
		
		NE_ULT_Entangle(id)
		zatakowany[id] = 1
		
	}
	return PLUGIN_HANDLED
}
public explode12(vec1[3],playerid, trigger)
{ 
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 21 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 32) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2] + 1000)
	write_short( sprite_white ) 
	write_byte( 0 ) 
	write_byte( 0 ) 
	write_byte( 3 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	write_byte( 188 ) 
	write_byte( 220 ) 
	write_byte( 255 ) 
	write_byte( 255 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte( 12 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_byte( 188 ) 
	write_byte( 10 ) 
	message_end() 
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1) 
	write_byte( 3 ) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_short( sprite_fire ) 
	write_byte( 65 ) 
	write_byte( 10 ) 
	write_byte( 0 ) 
	message_end() 
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},playerid) 
	write_byte(107) 
	write_coord(vec1[0]) 
	write_coord(vec1[1]) 
	write_coord(vec1[2]) 
	write_coord(175) 
	write_short (sprite_gibs) 
	write_short (25)  
	write_byte (10) 
	message_end() 
	if (trigger == 1)
	{
		set_user_rendering(playerid,kRenderFxNone, 0,0,0, kRenderTransAdd,0) 
	}
}
////////////////////////////////////////
public item_krzak(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Krz_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 151,255,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}
public Effect_Krz_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 430
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (pid == id || !is_user_alive(pid))
				continue
			
			if (get_user_team(id) == get_user_team(pid))
				continue
			
			if (!is_user_alive(pid))
				continue
			if (zatakowany[pid] == 1)
				continue
			
			NE_ULT_Entangle(pid)
			zatakowany[pid] = 1
			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.0)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-4.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_SPRITETRAIL)	// line of moving glow sprites with gravity, fadeout, and collisions
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 320)
	write_short(BlueFlare) // (sprite index)
	write_byte(250) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(1) // byte (scale in 0.1's)
	write_byte(random_num(40,70)) // (velocity along vector in 10's)
	write_byte(40) // (randomness of velocity in 10's)
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public item_toteme(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ode_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 93,79,82, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Ode_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = player_b_odepch[id]
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (pid == id || !is_user_alive(pid))
				continue
			
			if (get_user_team(id) == get_user_team(pid))
				continue
			
			new vOrigin[3];
			
			new Float:gfOrigin[2][3], b;
			
			entity_get_vector(pid, EV_VEC_origin, gfOrigin[1]);
			entity_get_vector(ent, EV_VEC_origin, gfOrigin[0]);
			
			get_user_origin(pid, vOrigin);
			for(b = 0; b <= 2; b ++) 
			{
				gfOrigin[1][b] -= gfOrigin[0][b];
				gfOrigin[1][b] +=30;
				gfOrigin[1][b] *=7;
			}
			
			entity_set_vector(pid, EV_VEC_velocity, gfOrigin[1]);
			change_health(pid,-40,id,"")
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);  
			write_byte(0);  
			write_coord(origin[0]);  
			write_coord(origin[1]);  
			write_coord(origin[2]);  
			write_coord(vOrigin[0]);  
			write_coord(vOrigin[1]);  
			write_coord(vOrigin[2]);  
			write_short(sprite_lgt);  
			write_byte(1); 
			write_byte(5); 
			write_byte(2); 
			write_byte(20); 
			write_byte(30); 
			write_byte(200);  
			write_byte(200); 
			write_byte(200); 
			write_byte(200); 
			write_byte(200); 
			message_end(); 
			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3];
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	new red = random_num(1,255)
	new grenn = random_num(1,255)
	new blue = random_num(1,255)
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
	write_byte( red); // r, g, b
	write_byte( grenn ); // r, g, b
	write_byte( blue ); // r, g, b
	write_byte( 170 ); // brightness
	write_byte( 6 ); // speed
	message_end();
	
	
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
public ikona_mocy(id)
{
	if(c_piorun[id] > 0 && player_class[id])
	{
		client_cmd( id, "speak diablosound/readymoc.wav")
		Display_Icon(id,ICON_SHOW,"dmg_shock",255,69,0)
	}
	if(JumpsMax[id] > 0 && player_class[id])
	{
		client_cmd( id, "speak diablosound/readymoc.wav")
		Display_Icon(id,ICON_SHOW,"item_longjump",255,69,0)
	}
}
stock bool:jakamapa(prze[])
{
	new mapname[33]
	get_mapname ( mapname,32 )  
	
	if(!equal(prze,mapname,1)){
		return true;	
	}
	return false;
}
stock bool:wmape(prze[])
{
	new mapname[32]
	get_mapname(mapname, 31)
	
	if(equali(mapname, prze)){
		return true;	
	}
	return false;
}
stock Create_TE_BEAMFOLLOW(entity, iSprite, life, width, red, green, blue, alpha){
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMFOLLOW )
	write_short( entity )			// entity
	write_short( iSprite )			// model
	write_byte( life )				// life
	write_byte( width )				// width
	write_byte( red )				// red
	write_byte( green )				// green
	write_byte( blue )				// blue
	write_byte( alpha )				// brightness
	message_end()
}
public NE_ULT_Entangle(iEnemy )
{
	// Follow the user until they stop moving...
	Create_TE_BEAMFOLLOW( iEnemy, sprite_smoke1, 10, 5, 10, 108, 23, 255 );
	new parm[4];
	parm[0] = iEnemy;
	parm[1] = 0;
	parm[2] = 0;
	parm[3] = 0;
	_NE_ULT_EntangleWait( parm );
	
}

// Wait for the user to stop moving
public _NE_ULT_EntangleWait( parm[4] )
{
	new id = parm[0];
	
	new vOrigin[3];
	get_user_origin( id, vOrigin );
	
	// Checking to see if the user has actually stopped yet?
	if ( vOrigin[0] == parm[1] && vOrigin[1] == parm[2] && vOrigin[2] == parm[3] )
	{
		NE_ULT_EntangleEffect( id )
	}
	else
	{
		parm[1] = vOrigin[0];
		parm[2] = vOrigin[1];
		parm[3] = vOrigin[2];
		
		set_task( 0.1, "_NE_ULT_EntangleWait", TASK_ENTANGLEWAIT + id, parm, 4 );
	}
	return;
}

public NE_ULT_EntangleEffect( id )
{
	if(!is_user_alive(id)) return 1;
	
	totemstop[id] = 1
	set_speedchange(id)
	set_task(6.0, "off_zamroz",TASK_ENTANGLEWAIT + id)
	// Get the user's origin
	new vOrigin[3];
	get_user_origin( id, vOrigin );
	
	// Play the entangle sound
	emit_sound( id, CHAN_STATIC, "diablosound/korzen.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
	
	new iStart[3], iEnd[3], iHeight;
	new iRadius	= 20, iCounter = 0;
	new x1, y1, x2, y2;
	
	// Some sweet crap that I don't understand courtesy of SpaceDude - draws the "cylinder" around the player
	while ( iCounter <= 7 )
	{
		if ( iCounter == 0 || iCounter == 8 )
			x1 = -iRadius;
		else if ( iCounter == 1 || iCounter == 7 )
			x1 = -iRadius * 100/141;
		else if ( iCounter == 2 || iCounter == 6 )
			x1 = 0;
		else if ( iCounter == 3 || iCounter == 5 )
			x1 = iRadius*100/141
		else if ( iCounter == 4 )
			x1 = iRadius
		
		if ( iCounter <= 4 )
			y1 = sqroot( iRadius*iRadius-x1*x1 );
		else
			y1 = -sqroot( iRadius*iRadius-x1*x1 );
		
		++iCounter;
		
		if ( iCounter == 0 || iCounter == 8 )
			x2 = -iRadius;
		else if ( iCounter == 1 || iCounter==7 )
			x2 = -iRadius*100/141;
		else if ( iCounter == 2 || iCounter==6 )
			x2 = 0;
		else if ( iCounter == 3 || iCounter==5 )
			x2 = iRadius*100/141;
		else if ( iCounter == 4 )
			x2 = iRadius;
		
		if ( iCounter <= 4 )
			y2 = sqroot( iRadius*iRadius-x2*x2 );
		else
			y2 = -sqroot( iRadius*iRadius-x2*x2 );
		
		iHeight = 16 + 2 * iCounter;
		
		while ( iHeight > -40 )
		{
			
			iStart[0]	= vOrigin[0] + x1;
			iStart[1]	= vOrigin[1] + y1;
			iStart[2]	= vOrigin[2] + iHeight;
			iEnd[0]		= vOrigin[0] + x2;
			iEnd[1]		= vOrigin[1] + y2;
			iEnd[2]		= vOrigin[2] + iHeight + 2;
			
			Create_TE_BEAMPOINTS( iStart, iEnd, 0, 0, 60, 10, 5, 10, 108, 23, 255, 0 ,sprite_beam);
			
			iHeight -= 16;
		}
	}
	
	return 0;
}
stock Create_TE_IMPLOSION(id, radius, count, life){
	new position[3]
	get_user_origin(id, position)
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte ( TE_IMPLOSION )
	write_coord( position[0] )			// position (X)
	write_coord( position[1] )			// position (Y)
	write_coord( position[2] )			// position (Z)
	write_byte ( radius )				// radius
	write_byte ( count )				// count
	write_byte ( life )					// life in 0.1's
	message_end()
}
stock Create_TE_SPRITETRAIL(id, vid, iSprite, count, life, scale, velocity, random ){
	
	if(get_user_team(id)==get_user_team(vid))
		return;
	
	new start[3],end[3]
	
	get_user_origin(id, start);
	get_user_origin(vid, end);
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SPRITETRAIL )
	write_coord( start[0] )				// start position (X)
	write_coord( start[1] )				// start position (Y)
	write_coord( start[2] )				// start position (Z)
	write_coord( end[0] )				// end position (X)
	write_coord( end[1] )				// end position (Y)
	write_coord( end[2] )				// end position (Z)
	write_short( iSprite )				// sprite index
	write_byte( count )					// count
	write_byte( life)					// life in 0.1's
	write_byte( scale)					// scale in 0.1's
	write_byte( velocity )				// velocity along vector in 10's
	write_byte( random )				// randomness of velocity in 10's
	message_end()
}
////////////////////////bindy//////////////////////////////////
public cmdBindKey(id)
{
	static gszKey[5];
	read_argv(1, gszKey, charsmax(gszKey));
	
	switch(gBindItem[id]) 
	{
		case 1:
		{
			client_cmd(id, "bind %s menu", gszKey);
			client_print(id, print_chat, "Menu Glowne bind pod klawisz: %s",gszKey);
		}
		case 2: 
		{
			client_cmd(id, "bind %s noze", gszKey);
			client_print(id, print_chat, "Menu Klas bind pod klawisz: %s",gszKey);
		}
		case 3:
		{
			client_cmd(id, "bind %s mag", gszKey);
			client_print(id, print_chat, "Fireballe bind pod klawisz: %s",gszKey);
		}
		case 4:
		{
			client_cmd(id, "bind %s ucieczka", gszKey);
			client_print(id, print_chat, "Ucieczka bind pod klawisz: %s",gszKey);
		}
		case 5:
		{
			client_cmd(id, "bind %s sciana", gszKey);
			client_print(id, print_chat, "Sciana bind pod klawisz: %s",gszKey);
		}
	}
	gBindItem[id] = 0;
	
}
public ustawienia(id)
{
	new text[513]
	format(text, 512, "\yUstawienia^n\r1. \wBinduj Menu Glowne^n\r2. \wBinduj Menu Klas^n^n\r4. \wStworz haslo^n\r5. \wZmien Haslo^n^n\r0. \wWyjdz")
	
	new keys
	keys = (1<<0)|(1<<1)|(1<<3)|(1<<4)|(1<<9)
	show_menu(id, keys, text, -1, "ustawienia")
	return PLUGIN_HANDLED
} 
public ustawienia_menu(id, key)
{
	client_cmd(id, "spk diablosound/wybierz");
	switch(key)
	{
		case 0:
		{
			gBindItem[id] = 1;
			client_cmd(id, "messagemode Podaj_nowy_klawisz");
		}
		case 1:
		{
			gBindItem[id] = 2;
			client_cmd(id, "messagemode Podaj_nowy_klawisz");
			
		}
		case 3:
		{
			if (equali(player_password[id], ""))
			{
				client_cmd(id, "messagemode wpisz_haslo")
				ColorChat(id,GREEN,"Podaj Haslo.")
			}
			else ColorChat(id,GREEN,"Posiadasz juz haslo ")
		}
		case 4:
		{
			if (equali(player_password[id], ""))
			{
				ColorChat(id,GREEN,"Nie posiadasz hasla")
				return PLUGIN_HANDLED
			}
			if(dobre_haslo[id] == 0)
			{
				client_cmd(id, "messagemode podaj_haslo")
				ColorChat(id,GREEN,"Podaj haslo")
			}
			else{
				client_cmd(id, "messagemode wpisz_haslo")
				ColorChat(id,GREEN,"Podaj Haslo.")
				
			}
		}
		case 9:
		{
			return PLUGIN_HANDLED
		}
	}
	otwarte_menu[id] = false
	return PLUGIN_HANDLED
}

/* ==================================================================================================== */
public add_bonus_scoutdamage(attacker_id,id,weapon)
{
	if (player_b_sniper[attacker_id] > 0 && weapon == CSW_SCOUT && player_class[attacker_id]!=Ninja )
	{
		
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		if (random_num(1,player_b_sniper[attacker_id]) == 1)
		{
			UTIL_Kill(attacker_id,id,"scout")	
		}
		
	}
	
	return PLUGIN_HANDLED
}
public add_bonus_shake(attacker_id,id)
{
        if(c_shake[attacker_id] > 0 && get_user_team(attacker_id) != get_user_team(id) && is_user_alive(id)) 
        {
                if (random_num(1,c_shake[attacker_id]) == 1)
                {
                        message_begin(MSG_ONE,get_user_msgid("ScreenShake"),{0,0,0},id); 
                        write_short(7<<14); 
                        write_short(1<<13); 
                        write_short(1<<14); 
                        message_end();
                }
        }
        return PLUGIN_HANDLED
}
/* ==================================================================================================== */
public add_bonus_knifedamage(attacker_id,id)
{
	if (player_b_knife[attacker_id] > 0 && c_odpornosc[id] == 0 && on_knife[attacker_id]>0 && get_user_button(attacker_id) & IN_ATTACK2)
	{
		
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		if (random_num(1,player_b_knife[attacker_id]) == 1){
			UTIL_Kill(attacker_id,id,"knife")
		}
	}
	return PLUGIN_HANDLED
}
/* ==================================================================================================== */
public add_bonus_awpdamage(attacker_id,id,weapon)
{
	if (player_b_awp[attacker_id] > 0 && c_odpornosc[id] == 0 && weapon == CSW_AWP && player_class[attacker_id]!=Ninja)
	{
		
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		if (random_num(1,player_b_awp[attacker_id]) == 1)
		{
			UTIL_Kill(attacker_id,id,"awp")
		}
	}
	return PLUGIN_HANDLED
}
public postawsciane(id)
{
	if(player_class[id] == Mnich){
		
		if (!is_user_alive(id))
			return PLUGIN_HANDLED
		
		
		if(num_shild[id])
		{
			createBlockAiming(id)
		}
	}
	return PLUGIN_HANDLED
}
public wowmod_effect_burn(id) {
	
	new rx, ry, rz, forigin[3]
	
	rx = random_num( -10, 10 )
	ry = random_num( -10, 10 )
	rz = random_num( -30, 30 )
	get_user_origin( id, forigin )
	
	//TE_SPRITE - additive sprite, plays 1 cycle
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 17 )
	write_coord(forigin[0]+rx) // coord, coord, coord (position)
	write_coord(forigin[1]+ry)
	write_coord(forigin[2]+10+rz)
	write_short( burning ) // short (sprite index)
	write_byte( 30 ) // byte (scale in 0.1's)
	write_byte( 200 ) // byte (brightness)
	message_end()
	
}
//////////////////////////////////////////////////////////////
////////////////////Ulepszania Artefaktow ////////////////////
//////////////////////////////////////////////////////////////
public show_menu_artef1(id)
{
	new MyMenu=menu_create("Menu","artmenu1");
	
	new aktywna=menu_makecallback("aktywna_func");
	
	new nieaktywna=menu_makecallback("nieaktywna_func");
	
	menu_additem(MyMenu,"Twoj Artefakt","",0,player_artefakt[id]?aktywna:nieaktywna);
	menu_additem(MyMenu,"Wywal Artefakt","",0,player_artefakt[id]?aktywna:nieaktywna);
	menu_additem(MyMenu,"Przedluz Zywotnosc \d 10 min","",0,player_artefakt[id]?aktywna:nieaktywna);
	
	menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");
	
	menu_setprop(MyMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(MyMenu,MPROP_NEXTNAME,"Nastepne")
	
	menu_display(id, MyMenu,0);
	return PLUGIN_HANDLED;
}
public artmenu1(id, menu, item){
	client_cmd(id, "spk diablosound/wybierz");
	if(item == MENU_EXIT){
		menu_destroy(menu);
		otwarte_menu[id] = false
		return PLUGIN_HANDLED;
	}
	switch(item){
		case 0:ainfo(id)
			case 1:dropa_menu(id)
			case 2:{
			if(!UTIL_Buykamien(id,2))
				return PLUGIN_HANDLED
			player_wytrzymalosc[id] += 600;
			}
	}
	return PLUGIN_HANDLED;
}

public dropa_menu(id)
{
	new MyMenu=menu_create("Wyrzucic artefakt ?? ","artmenu2");
	
	
	menu_additem(MyMenu,"Tak","",0,_);
	menu_additem(MyMenu,"Nie","",0,_);
	menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");
	
	menu_setprop(MyMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(MyMenu,MPROP_NEXTNAME,"Nastepne")
	
	menu_display(id, MyMenu,0);
	return PLUGIN_HANDLED;
}
public artmenu2(id, menu, item){
	client_cmd(id, "spk diablosound/wybierz");
	if(item == MENU_EXIT){
		menu_destroy(menu);
		otwarte_menu[id] = false
		return PLUGIN_HANDLED;
	}
	switch(item){
		case 0:dropartefakt(id)
			case 1:show_menu_artef1(id)
		}
	return PLUGIN_HANDLED;
}
public bool:UTIL_Buykamien(id,amount)
{
	if (player_krysztal[id] >= amount)
	{
		player_krysztal[id]-=amount
		zapiszk(id)
		return true
	}
	else
	{
		hudmsg(id,2.0,"Nie masz tyle krysztalow")
		return false
	}
	
	return false
}
public Sprawdzartefakt(id)
{
	wczytalo[id] = 1
	switch(player_artefakt[id])
	{
		case 1:
		{
			a_noz[id] = 0.6
			a_wearsun[id] = 1
		}
		case 2:
		{
			a_silent[id] = 1
			a_heal[id] = 3
		}
		case 3:
		{
			a_wearsun[id] = 1
			a_inv[id] = 150
		}
		case 4:
		{
			a_inv[id] = 150
			a_jump[id] = 1
		}
		case 5:
		{
			a_money[id] = 200
			a_heal[id] = 4
		}
		case 6:
		{
			a_money[id] = 200
			a_noz[id] = 0.6
		}
		case 7:
		{
			a_money[id] = 200
			a_jump[id] = 1
		}
		case 8:
		{
			a_heal[id] = 4
			a_spid[id] = 30
		}
		case 9:
		{
			a_silent[id] = 1
			a_spid[id] = 30
		}
		case 10:
		{
			a_jump[id] = 1
			a_spid[id] = 40
		}
		case 11:
		{
			a_inv[id] = 140
			a_money[id] = 200
		}
		case 12:
		{
			a_noz[id] = 0.5
			a_heal[id] = 4
		}
		case 13:
		{
			a_wearsun[id] = 1
			a_heal[id] = 4
		}
		case 14:
		{
			a_money[id] = 200
			a_spid[id] = 40
		}
		case 15:
		{
			a_noz[id] = 0.5
			a_spid[id] = 50
		}
		case 16:
		{
			a_silent[id] = 1
			a_jump[id] = 1
			a_spid[id] = 30
		}
		case 17:
		{
			a_silent[id] = 1
			a_inv[id] = 140
		}
		case 18:
		{
			a_wearsun[id] = 1
			a_noz[id] = 0.6
		}
		case 19:
		{
			a_jump[id] = 1
			a_heal[id] = 4
		}
		case 20:
		{
			a_silent[id] = 1
			a_wearsun[id] = 1
		}
	}
}
public stworz_haslo(id)
{
	new text[192]
	read_argv(1,text,191)
	format(password, charsmax(password), "%s", text)
	
	new Unique_name[100]
	add(Unique_name,99,text)
	
	player_password[id] = Unique_name
	
	if(equali(player_password[id],""))
	{
		ColorChat(id,GREEN,"[*Pass*]^x01 Zle haslo")
		return PLUGIN_HANDLED;
	}
	if(strlen(player_password[id]) < 5 )
	{
		ColorChat(id,GREEN,"[*Pass*]^x01 Haslo za krotkie")
		Wczytaj(id)
		return PLUGIN_HANDLED;
	}
	if(strlen(player_password[id]) > 15 )
	{
		ColorChat(id,GREEN,"[*Pass*]^x01 Haslo za dlugie")
		Wczytaj(id)
		return PLUGIN_HANDLED;
	}
	
	new AuthID[35]
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[128]
	formatex(vaultkey,63,"%s",AuthID)
	formatex(vaultdata,127,"^"%s^"", player_password[id])
	nvault_set(g_vault,vaultkey,vaultdata)
	
	ColorChat(id,GREEN,"[%s]^x01 Pomyslnie zapisano haslo ",player_password[id])
	
	return PLUGIN_HANDLED
	
}
public wpisz_haslo1(id)
{
	new text[192]
	read_argv(1,text,191)
	format(wpisane_haslo, charsmax(wpisane_haslo), "%s", text)
	
	new Unique_name[100]
	add(Unique_name,99,text)
	
	if(equali(player_password[id],Unique_name))
	{
		ColorChat(id,GREEN,"[*NewDiablo*]^x01 Haslo poprawne")
		dobre_haslo[id] = 1
		showmenu(id)
	}
	else  ColorChat(id,GREEN,"[*NewDiablo*]^x01 Podales zle haslo")
}
public Wczytaj(id)
{
	new AuthID[35]
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[128]
	formatex(vaultkey,63,"%s",AuthID)
	nvault_get(g_vault,vaultkey,vaultdata,127)
	
	new ps[12]
	parse(vaultdata, ps, 11)
	
	copy(player_password[id], 31, ps);
	
	return PLUGIN_CONTINUE
}
public zapiszk(id)
{
	new AuthID[35]
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[128]
	formatex(vaultkey,63,"%s",AuthID)
	formatex(vaultdata,127,"%i", player_krysztal[id])
	nvault_set(g_vault2,vaultkey,vaultdata)
	return PLUGIN_CONTINUE
}
public wczytajk(id)
{
	new AuthID[35]
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[128]
	formatex(vaultkey,63,"%s",AuthID)
	nvault_get(g_vault2,vaultkey,vaultdata,127)
	
	new ps[12]
	parse(vaultdata, ps, 11)
	
	player_krysztal[id]= str_to_num(ps)
	
	return PLUGIN_CONTINUE
}
////////////////misje//////////////////
public daj_kamienia(id)
{
	if (random_num(1,25) == 1)
	{
		player_krysztal[id]++
		ColorChat(id,GREEN,"[*Diablo*]^x01 Znalazles krysztal")
		
		if(player_class[id] == Baal)
		{
			player_krysztal[id]++
			ColorChat(id,GREEN,"[*Diablo*]^x01 Jako Baal podwoiles krysztal")
		}
		zapiszk(id)
	}
}
///////////////////////tes////////////////////////////////
stock VecNormilize(Float: in[3], Float: out[3])
{
	static Float: vlen;
	
	vlen = vector_length(in);
	vlen = 1/vlen;
	
	out[0] *= vlen;
	out[1] *= vlen;
	out[2] *= vlen;
}

stock UTIL_MakeBeamCylinder(const Float:origin[3], const m_Sprite) 
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 200.0) ;
	write_short(m_Sprite) ;
	write_byte(0);
	write_byte(10);
	write_byte(3); 
	write_byte(20); 
	write_byte(0); 
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(0);
	message_end();
}
DispBall_Animate(const ent)
{
entity_set_float(ent, EV_FL_frame, entity_get_float(ent, EV_FL_frame) + 10.0);

if (entity_get_float(ent, EV_FL_frame) > 24.0)
	entity_set_float(ent, EV_FL_frame, 0.0);
}
//////////////////////////////////////////////////////////////////////////////////////
public lecz_Bard(id)
{
	new entlist[513]
	new numfound = find_sphere_class(id,"player",210.0,entlist,512)
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
		
		if (pid == id || !is_user_alive(pid))
			continue
		
		if (get_user_team(id) != get_user_team(pid))
			continue
		
		static Float:originF[3]
		pev(pid, pev_origin, originF)
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SPRITE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0)) // x
		engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0)) // y
		engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0)) // z
		write_short(g_healspr) // sprite
		write_byte(random_num(5, 10)) // scale
		write_byte(200) // brightness
		message_end()
		change_health(pid,25,id,"world")
		
	}
	change_health(id,18,id,"world")
	
	return PLUGIN_CONTINUE
}
//////////////////////ni zeimn icncaie/////////////////////
public kula1(id)
{
	if (player_class[id] == Griswold && freeze_ended && is_user_alive(id))
	{
		new xd = floatround(halflife_time()-wait1[id])
		new czas = 30-xd
		if (halflife_time()-wait1[id] <= 30)
		{
			client_print(id, print_center, "Za %d sek mozesz uzyc mocy!", czas)
			return PLUGIN_CONTINUE;
		} 																
		else {
			DispBall_Spawn(id)
			wait1[id]=floatround(halflife_time())
		}
		
		
	}
	return PLUGIN_HANDLED
}
public DispBall_Explode(ent)
{
	if (!pev(ent, pev_iuser3)){
		new Float: origin[3];
		pev(ent, pev_origin, origin);
		set_pev(ent, pev_iuser3, 1);	
		
//		UTIL_MakeBeamCylinder(origin, m_DispRing) ;
		
		new Players[32], playerCount, a
		get_players(Players, playerCount, "ah")
		
		new id = pev(ent,pev_owner)
		for (new i=0; i<playerCount; i++) 
		{
			a = Players[i] 
			
			new Float:aOrigin[3]
			pev(a,pev_origin,aOrigin)
			
			if (get_user_team(id) != get_user_team(a) && get_distance_f(aOrigin,origin) < 150.0)
			{
				ExecuteHamB(Ham_TakeDamage, a, ent, id, 40.0+float(player_intelligence[id]), DMG_ENERGYBEAM );
		
				NE_ULT_Entangle(ent)
				zatakowany[ent] = 1
			}
		}
	}
	set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(ent, pev_iuser4, 1);
	set_pev(ent, pev_nextthink, get_gametime() + 0.6);
}
public DispBall_Spawn(id)
{
	static AllocStringCached;
	if (!AllocStringCached)
	{
		AllocStringCached = engfunc(EngFunc_AllocString, "info_target");
	}
	
	new ent = engfunc(EngFunc_CreateNamedEntity, AllocStringCached);
	if(!pev_valid(ent)) return 0;
	
	set_pev(ent, pev_classname, BALL_CLASSNAME);
	
	new Float: origin[3];
	new Float: velocity[3];
	new Float: v_forward[3];
	new Float: v_right[3];
	new Float: v_up[3];
	
	GetGunPosition(id, origin);
	
	global_get(glb_v_forward, v_forward);
	global_get(glb_v_right, v_right);
	global_get(glb_v_up, v_up);
	
	//xs_vec_mul_scalar(v_forward, 29.0, v_forward)
	xs_vec_mul_scalar(v_right, 2.0, v_right);
	xs_vec_mul_scalar(v_up, -5.0, v_up);
	
	xs_vec_add(origin, v_forward, origin);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin, v_up, origin);
	
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_owner, id);
	set_pev(ent, pev_dmg, 100.0);
	
	engfunc(EngFunc_SetModel, ent, SPRITE_PORTAL);
	engfunc(EngFunc_SetSize, ent, Float:{0.0, 0.0, 0.0} , Float:{0.0, 0.0, 0.0});
	
	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_LIGHT);
	set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
	
	velocity_by_aim(id, 1000, velocity);
	set_pev(ent, pev_velocity, velocity);
	
	dllfunc(DLLFunc_Spawn, ent);
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY);
	set_pev(ent, pev_solid, SOLID_BBOX);
	set_pev(ent, pev_scale, 5);
	set_pev(ent, pev_nextthink, get_gametime() + 0.1);
	
	return ent;
}

public DispBall_Think(ent)
{
	if (!pev_valid(ent)) 
		return;
	
	DispBall_Animate(ent);
	
	if (pev(ent, pev_iuser4))
	{
		remove_entity(ent);
		return;
	}
	
	static Float: velocity[3];
	pev(ent, pev_velocity, velocity);
	
	if (!vector_length(velocity) || !IsInWorld(ent))
	{
		DispBall_Explode(ent)
		return;
	}
	
	static ptr, i, id, owner, beam;
	static Float: Dist;
	static Float: flFraction;
	static Float: origin[3];
	static Float: vecDir[3];
	static Float: vecEndPos[3];
	
	Dist = 1.00; ptr = create_tr2();
	
	pev(ent, pev_origin, origin);
	
	while ((id = engfunc(EngFunc_FindEntityInSphere, id, origin, 280.0)))
	{
		if (random_float(0.0, 1.0) <= 0.3 && pev(id, pev_takedamage) && is_visible(id, ent) && id != (owner = pev(ent, pev_owner)))
		{
			static Float: target_origin[3]; pev(id, pev_origin, target_origin);
			
			ExecuteHamB(Ham_TakeDamage, id, ent, owner, 22.0, DMG_ENERGYBEAM );
			
			if ((beam = BeamCreate(id, SPRITE_PLASMA, m_Plasma, 65.0)))
			{
				RelinkBeam(beam, origin, target_origin);
				
				BeamSetColor(beam, 255.0, 255.0, 255.0);
				BeamSetNoise(beam, 45);
				BeamSetBrightness(beam, 255.0);
				BeamSetScrollRate(beam, 35.0);
				BeamLiveForTime(beam, 0.1);
			}
		}
	}
	for (i = 0; i < 10; i++)
	{
		vecDir[0] = random_float(-1.0, 1.0);
		vecDir[1] = random_float(-1.0, 1.0);
		vecDir[2] = random_float(-1.0, 1.0);
		
		VecNormilize(vecDir, vecDir);
		xs_vec_mul_scalar(vecDir, 1536.0, vecDir);
		xs_vec_add(vecDir, origin, vecDir);
		
		engfunc(EngFunc_TraceLine, origin, vecDir, IGNORE_MONSTERS, ent, ptr);
		get_tr2(ptr, TR_flFraction, flFraction);
		
		if (Dist > flFraction)
		{  
			get_tr2(ptr, TR_vecEndPos, vecEndPos);
			Dist = flFraction;
		}
	}
	
	if (Dist < 1.0) 
	{
		if ((beam = BeamCreate(ent, SPRITE_PLASMA, m_Plasma, 30.0)))
		{
			RelinkBeam(beam, vecEndPos, origin);
			
			BeamSetColor(beam, 23.0, 170.0, 17.0);
			BeamSetNoise(beam, 65);
			BeamSetBrightness(beam, 255.0);
			BeamSetScrollRate(beam, 35.0);
			BeamLiveForTime(beam, 1.0);
		}
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1);
	free_tr2(ptr);
}

public DispBeam_Think(ent)
{
	if (pev_valid(ent))
	{
		remove_entity(ent);
	}
}

public DispBall_Explode_Touch(ent)
{
	if (pev_valid(ent))
	{
		DispBall_Explode(ent);
	}
}

stock GetGunPosition(const player, Float:origin[3] )
{
	new Float:viewOfs[3];
	
	pev(player, pev_origin, origin);
	pev(player, pev_view_ofs, viewOfs);
	
	xs_vec_add( origin, viewOfs, origin);
}
stock BeamCreate(const endIndex, const pSpriteName[], const spriteIndex, const Float: width)
{
	static AllocStringCached;
	if (!AllocStringCached)
	{
		AllocStringCached = engfunc(EngFunc_AllocString, "beam");
	}
	
	static ent;
	if (!(ent = engfunc(EngFunc_CreateNamedEntity, AllocStringCached))) 
		return 0;
	
	set_pev(ent, pev_classname, BEAM_CLASSNAME);	
	
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_CUSTOMENTITY);
	
	BeamSetFrame(ent, 0);
	
	set_pev(ent, pev_model, pSpriteName);
	
	BeamSetTexture(ent, spriteIndex);
	BeamSetWidth(ent, width);
	
	set_pev(ent, pev_skin, endIndex);
	set_pev(ent, pev_sequence, 0);
	set_pev(ent, pev_rendermode, 1);
	
	DispatchSpawn(ent);
	
	return ent;
}
stock RelinkBeam(const beam, const Float: startPos[3], const Float: endPos[3])
{
	static Float: mins[3], Float: maxs[3];
	
	mins[0] = floatmin(startPos[0], endPos[0]);
	mins[1] = floatmin(startPos[1], endPos[1]);
	mins[2] = floatmin(startPos[2], endPos[2]);
	
	maxs[0] = floatmax(startPos[0], endPos[0]);
	maxs[1] = floatmax(startPos[1], endPos[1]);
	maxs[2] = floatmax(startPos[2], endPos[2]);
	
	xs_vec_sub(mins, startPos, mins);
	xs_vec_sub(maxs, startPos, maxs);
	
	set_pev(beam, pev_mins, mins);
	set_pev(beam, pev_maxs, maxs);
	
	engfunc(EngFunc_SetSize, beam, mins, maxs);
	engfunc(EngFunc_SetOrigin, beam, startPos);
}
///////////////////////////////////
public PreThink(id)
{	
	if(!is_user_alive(id))
		return FMRES_IGNORED;	
	
	if(brak_strzal[id] == 1) {
		set_pev(id, pev_button, pev(id,pev_button) & ~IN_ATTACK) 
	}
	
	if(user_controllsem[id])
	{
		new ent = user_controllsem[id];
		if(is_valid_ent(ent))
		{
			new Float:Velocity[3], Float:Angle[3];
			velocity_by_aim(id, 500, Velocity);
			entity_get_vector(id, EV_VEC_v_angle, Angle);
			
			entity_set_vector(ent, EV_VEC_velocity, Velocity);
			entity_set_vector(ent, EV_VEC_angles, Angle);
		}
		else
			attach_view(id, id);
	}
	
	if ((c_silent[id] > 0 || a_silent[id] > 0) && is_user_alive(id)) 
		entity_set_int(id, EV_INT_flTimeStepSound, 300)
	
	return FMRES_IGNORED;
}
public predator1(id)
{
	if (player_class[id] == Nihlathak && freeze_ended && is_user_alive(id))
	{
		new xd = floatround(halflife_time()-wait1[id])
		new czas = 30-xd
		if (halflife_time()-wait1[id] <= 30)
		{
			client_print(id, print_center, "Za %d sek mozesz uzyc mocy!", czas)
			return PLUGIN_CONTINUE;
		}
	
		new Float:Origin[3], Float:Angle[3], Float:Velocity[3];
		velocity_by_aim(id, 100, Velocity);
		entity_get_vector(id, EV_VEC_origin, Origin);
		entity_get_vector(id, EV_VEC_v_angle, Angle);
		
		Angle[0] *= -1.0;
		
		new ent = create_entity("info_target");
		
		entity_set_string(ent, EV_SZ_classname, "predator_ent");
		entity_set_model(ent, "models/rpgrocket.mdl");
		entity_set_int(ent, EV_INT_solid, 2);
		entity_set_int(ent,EV_INT_effects,64)
		entity_set_int(ent, EV_INT_movetype, 5);
		entity_set_edict(ent, EV_ENT_owner, id);
		entity_set_origin(ent, Origin);
		
		entity_set_vector(ent, EV_VEC_velocity, Velocity);
		entity_set_vector(ent, EV_VEC_angles, Angle);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent);
		write_short(sprite_smoke1);
		write_byte(10);
		write_byte(5);
		write_byte(205);
		write_byte(237);
		write_byte(163);
		write_byte(200);
		message_end();
		
		attach_view(id, ent);
		user_controllsem[id] = ent;
		wait1[id]=floatround(halflife_time())
	}
	
	return PLUGIN_CONTINUE;
} 
stock Float:estimate_take_hurt(Float:fPoint[3], ent) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	entity_get_vector(ent, EV_VEC_origin, fOrigin);
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, 0, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if(fFraction == 1.0 || get_tr2(tr, TR_pHit) == ent)
		return 1.0
	return 0.6
}
public touchedpredator(ent, id)
{
	if(!is_valid_ent(ent))
		return PLUGIN_CONTINUE;
	
	new owner = entity_get_edict(ent, EV_ENT_owner);
	
	if(!is_user_connected(owner))
		return PLUGIN_CONTINUE;
		
/*	new entlist[33];
	new numfound = find_sphere_class(id, "player", 300.0 , entlist, 32);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
		
		if (!is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
			continue;
			
//		new dam = 80 + player_intelligence[id]
//		ExecuteHam(Ham_TakeDamage, pid, 0, id, dam , 1);
		change_health(target,-dam,id,"grenade")
	}*/
	
	bombs_explode(ent, 40.0, 120.0);
	attach_view(owner, owner);
	user_controllsem[owner] = 0;
	return PLUGIN_CONTINUE;
}
//////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////
/* Gildie by stachu mroz */
public zapisz_gildia_nick(id)
{
	new AuthID[35]
	
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-GIL",AuthID);
	format(vaultdata,255,"^"%s^"",nazwa_gildi[id])
	nvault_set(g_gil_spr,vaultkey,vaultdata);
	
	new vaultkey1[64]
	format(vaultkey1,63,"%s-GIL",AuthID);
	nvault_remove(g_wplaty,vaultkey1);
	
	ColorChat(id,GREEN,"[*%s*]^x01 Przypisano nick do gildi",nazwa_gildi[id])
	
	return PLUGIN_CONTINUE
}
public nick_gildia(id)
{
	new AuthID[35]
	
	get_user_name(id,AuthID,34)
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-GIL",AuthID)
	nvault_get(g_gil_spr,vaultkey,vaultdata,255);
	
	new ng[32]
	parse(vaultdata,ng , 31)
	
	copy(nazwa_gildi[id], 31, ng);
	
	if(!equali(nazwa_gildi[id],"")){
		wczytaj_gildia(id)
	}else nazwa_gildi[id] = "Brak"
	
	return PLUGIN_CONTINUE
}
public zapis_gildia(id,mode)
{
	if(mode == 1){
		get_user_name(id,nazwa_zalozycial[id],32)
		ilosc_czlonkow[id]=1
		gildia_lvl[id]=1
	}	
	
	new vaultkey[64],vaultdata[256];
	format(vaultkey,63,"%s-GTB",nazwa_gildi[id]);
	format(vaultdata,255,"%i %i %i ^"%s^" %i %i %i %i %i %i %i %i",gildia_lvl[id],gildia_exp[id],ilosc_czlonkow[id],nazwa_zalozycial[id],g_dmg[id],g_def[id],g_hp[id],g_spid[id],g_pkt[id],g_kam[id],g_drop[id],g_woj[id])
	nvault_set(g_gildia,vaultkey,vaultdata);
}

public wczytaj_gildia(id)
{
	new vaultkey[64],vaultdata[256];
	format(vaultkey,63,"%s-GTB",nazwa_gildi[id]);
	nvault_get(g_gildia,vaultkey,vaultdata,255)
	
	new nz[32],gl[32],ge[32],ic[32],gd[32],gde[32],gh[32],gs[32],pkt[32],gh1[32],gs1[32],pkt1[32]
	
	parse(vaultdata, gl, 31, ge ,31, ic ,31, nz ,31, gd ,31, gde ,31, gh ,31, gs ,31, pkt ,31, gh1 ,31, gs1 ,31, pkt1 ,31)
	
	gildia_lvl[id] = str_to_num(gl);
	gildia_exp[id] = str_to_num(ge);
	ilosc_czlonkow[id] = str_to_num(ic);
	g_dmg[id] = str_to_num(gd);
	g_def[id] = str_to_num(gde);
	g_hp[id] = str_to_num(gh);
	g_spid[id] = str_to_num(gs);
	g_pkt[id] = str_to_num(pkt);
	g_kam[id] = str_to_num(gh1);
	g_drop[id] = str_to_num(gs1);
	g_woj[id] = str_to_num(pkt1);
	
	copy(nazwa_zalozycial[id], 31, nz);
}
//////////////menu///////
public wczytaj_wplata(id)
{
	new AuthID[35]
	
	get_user_name(id,AuthID,34)
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-GIL",AuthID)
	nvault_get(g_wplaty,vaultkey,vaultdata,255);
	new nz[32]
	
	parse(vaultdata, nz, 31)
	
	wplata[id] = str_to_num(nz);
}
public zapisz_wplata(id)
{
	new AuthID[35]
	
	get_user_name(id,AuthID,34)
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-GIL",AuthID)
	format(vaultdata,255,"%i",wplata[id])
	nvault_set(g_wplaty,vaultkey,vaultdata);
}
//////////////menu///////
public zrob_gildie(id)
{
	if(player_lvl[id] <= 19){
		ColorChat(id,GREEN,"[*Diablo Gildie*]^x01 Aby zalozyc wlasna gildie potrzeba min. 20lvl")
		return PLUGIN_HANDLED
	}
	
	client_cmd(id, "messagemode wpisz_nazwe_gildi")
	ColorChat(id,GREEN,"[*Diablo Gildie*]^x01 Wpisz nazwe gildi")
	return PLUGIN_HANDLED
}
public stworz_gildie_n(id)
{
	new text[192]
	
	read_argv(1,text,191)
	format(nazwa, charsmax(nazwa), "%s", text)
	
	new Unique_name[100]
	add(Unique_name,99,nazwa)
	
	nazwa_gildi[id] = Unique_name
	
	if(equali(nazwa_gildi[id],"Brak")||equali(nazwa_gildi[id],""))
	{
		ColorChat(id,GREEN,"[*%s*]^x01 Blad",nazwa_gildi[id])
		return PLUGIN_HANDLED;
	}
	
	
	wczytaj_gildia(id)
	if(gildia_lvl[id]==0){
		ColorChat(id,GREEN,"[*%s*]^x01Zalozyles nowa gildie",nazwa)
		zapisz_gildia_nick(id)
		zapis_gildia(id,1)
		}else{ 
		ColorChat(id,GREEN,"[*diablo*]^x01 Nazwa gildi w uzyciu")
		gildia_lvl[id] = 0
		gildia_exp[id] = 0
		ilosc_czlonkow[id] = 0
		g_dmg[id] = 0
		g_def[id] = 0
		g_hp[id] = 0
		g_spid[id] = 0
		g_pkt[id] = 0
		g_kam[id] = 0
		g_drop[id] = 0
		g_woj[id] = 0
		nazwa_gildi[id] = ""
		nazwa_zalozycial[id] = ""
		nick_gildia(id)
	}
	return PLUGIN_HANDLED;
}

////////////////////////////opis gildi///////////////////
public showgildia(id)
{
	
	new tempstring[100];
	new motd[2048];
	
	
	formatex(motd,charsmax(motd),"<html><body bgcolor=^"#000000^"><font size=^"2^" face=^"verdana^" color=^"FFB000^"><center><strong>Statystyki Gildi: %s</strong><br>", nazwa_gildi[id]);
	add(motd,charsmax(motd),"(Aktualizowane co Mape)<br><br>");
	
	formatex(tempstring,charsmax(tempstring),"Lvl %i/10<br>",gildia_lvl[id]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Exp %i/%i<br>",gildia_exp[id],GildiaXP[gildia_lvl[id]]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Krysztaly %i<br>",g_kam[id]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Zalozyciel %s <br><br>",nazwa_zalozycial[id]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"<b>Czlonkowie (%i/%i)</b><br>",ilosc_czlonkow[id],gildia_lvl[id]+2);
	add(motd,charsmax(motd),tempstring);
	
	new iPos , szKey[ 32 ] , szVal[ 64 ] , iTimeStamp;
	new ala[32],key[128],nazwa1[128],l = 0
	new iVaultHandle = nvault_util_open("nickgil")
	new iCount = nvault_util_count (iVaultHandle) 
	
	for ( new iCurrent = 1 ; iCurrent <= iCount ; iCurrent++ )
	{
		iPos = nvault_util_read( iVaultHandle , iPos , szKey , charsmax( szKey ) , szVal , charsmax( szVal ) , iTimeStamp );
		
		parse(szVal, ala, 31);
		copy(nazwa1, 31, ala);
		
		if(!equal(nazwa_gildi[id],nazwa1))
			continue;
		
		formatex(key, 127, "%s",szKey);
		key[strlen(key)-4] = 0;
		
		new vaultkey[64],vaultdata[256]
		format(vaultkey,63,"%s-GIL",key)
		nvault_get(g_wplaty,vaultkey,vaultdata,255);
		
		new ng[32],ile
		parse(vaultdata,ng , 31)
		ile = str_to_num(ng);
		
		l++
		
		formatex(tempstring,charsmax(tempstring),"%i. %s   |WPLATA| %i <br>",l,key,ile);
		add(motd,charsmax(motd),tempstring);
	}
	formatex(tempstring,charsmax(tempstring),"<b>Statystyki</b><br>",ilosc_czlonkow[id],gildia_lvl[id]+2);
	add(motd,charsmax(motd),tempstring);
	if(g_dmg[id]){
		formatex(tempstring,charsmax(tempstring),"Zadajesz %i%% dodatkowych obrazen<br>",g_dmg[id]);
		add(motd,charsmax(motd),tempstring);
	}
	if(g_def[id]){
		formatex(tempstring,charsmax(tempstring),"Otrzymujesz %i%% mniej obrazen<br>",g_def[id]);
		add(motd,charsmax(motd),tempstring);
	}
	if(g_spid[id]){
		formatex(tempstring,charsmax(tempstring),"Biegasz szybciej o %i jednostek<br>",g_spid[id]);
		add(motd,charsmax(motd),tempstring);
	}
	if(g_hp[id]){
		formatex(tempstring,charsmax(tempstring),"Zwieksza twoje Hp o %i%%<br>",g_hp[id]);
		add(motd,charsmax(motd),tempstring);
	}
	/*if(g_woj[id]){
	formatex(tempstring,charsmax(tempstring),"Drop butelek %i<br>",g_drop[id]);
	add(motd,charsmax(motd),tempstring)
	}*/
	if(g_drop[id]){
		formatex(tempstring,charsmax(tempstring),"Zdobywasz doswiadczenie 20%% szybciej<br>");
		add(motd,charsmax(motd),tempstring)
	}
add(motd,charsmax(motd),"</center></font></body></html>");


show_motd(id,motd,"Legion: Statystyki");

}
////////////////////zapraszanie///////////////////////////

public aktywna_func(id, menu, item){
return ITEM_ENABLED;
}
public nieaktywna_func(id, menu, item){
return ITEM_DISABLED;
}
public gildia_wybierz(id)
{
new MyMenu=menu_create("Gildie","zapros_gildia");
new cb = menu_makecallback("gildia_wybierz_Callback");
new nick[64]
for(new i=0, n=0; i<=32; i++)
{
	if(!is_user_connected(i))
		continue;
	
	oddaj_id[n++] = i;
	get_user_name(i, nick, 63)
	menu_additem(MyMenu, nick, _, _, cb);
}
menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

menu_setprop(MyMenu,MPROP_BACKNAME,"Wroc")
menu_setprop(MyMenu,MPROP_NEXTNAME,"Nastepne")

//zawsze poka¿ opcjê wyjœcia
menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

menu_display(id, MyMenu);
}
public zapros_gildia(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

new id2 = oddaj_id[item];


if(!is_user_connected(id2)){
	client_print(id, print_chat, "Nie odnaleziono zadanego gracza.");
	return PLUGIN_CONTINUE;
}
new nick[64]
get_user_name(id, nick, 63)
new nazwa_menu[128]
formatex(nazwa_menu, charsmax(nazwa_menu), "Dolacz do Gildi %s",nazwa_gildi[id])

new menu2 = menu_create(nazwa_menu, "menu_dolacz");

menu_additem(menu2,"Tak",nick);
menu_additem(menu2,"Nie",nick);

menu_setprop(menu2,MPROP_EXITNAME,"Wyjscie");

//zawsze poka¿ opcjê wyjœcia
menu_setprop(menu2,MPROP_EXIT,MEXIT_ALL);

menu_setprop(menu2,MPROP_PERPAGE,7)

menu_display(id2, menu2);
return PLUGIN_CONTINUE;
}
public menu_dolacz(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}
new access, callback, data[64];
menu_item_getinfo(menu, item, access, data, charsmax(data), _, _, callback);
new id2 = get_user_index(data) 

switch(item)
{
	case 0: 
	{ 
		nazwa_gildi[id]=nazwa_gildi[id2]
		ilosc_czlonkow[id2]++
		zapis_gildia(id2,0)
		zapisz_gildia_nick(id)
		nick_gildia(id)
		ColorChat(id2,GREEN,"[*Diablo*]^x01 Gracz dolaczyl do gildi")
	}
	case 1: ColorChat(id2,GREEN,"[*Diablo*]^x01 Gracz odrzucil propozycje")
	}
return PLUGIN_CONTINUE;
}
public gildia_wybierz_Callback(id, menu, item)
{
new id2 = oddaj_id[item];
if(id2 == id || gildia_lvl[id2]>0)
	return ITEM_DISABLED;
return ITEM_ENABLED;
}
public gildia_wybierz_Callback1(id, menu, item)
{
new id2 = oddaj_id[item];
if(id2 == id || !equal(nazwa_zalozycial[id],nazwa_zalozycial[id2]))
	return ITEM_DISABLED;
return ITEM_ENABLED;
}
//////////////////menu//////////////
public gildie(id)
{
new MyMenu=menu_create("Menu Gildi","gildia_menu");

new aktywna=menu_makecallback("aktywna_func");

new nieaktywna=menu_makecallback("nieaktywna_func");

new AuthID[35]
get_user_name(id,AuthID,34)
tryb[id] = 0

if(gildia_lvl[id] == 0) tryb[id] = 0
else if(equal(AuthID,nazwa_zalozycial[id])) tryb[id] = 1
	else tryb[id] = 2

switch(tryb[id]){
	case 0:{
		
		menu_additem(MyMenu,"Zaloz gildie","",0,aktywna);
		menu_additem(MyMenu,"Ogolne info","",0,aktywna);
	}
	case 1:{
		if(ilosc_czlonkow[id] < 2+gildia_lvl[id]) menu_additem(MyMenu,"Zapros graczy","",0,aktywna);
		else menu_additem(MyMenu,"Zapros graczy","",0,nieaktywna);
		
		menu_additem(MyMenu,"Opis Gildi","",0,aktywna);
		
//		if(player_lvl[id]>10) menu_additem(MyMenu,"Wplac expa","",0,aktywna);
//		else menu_additem(MyMenu,"Wplac expa","",0,nieaktywna);
		
		if(player_krysztal[id]) menu_additem(MyMenu,"Daj Krysztal","",0,aktywna);
		else menu_additem(MyMenu,"Daj Krysztal","",0,nieaktywna);
		
		if(ilosc_czlonkow[id]>1) menu_additem(MyMenu,"Wyrzuc Gracza","",0,aktywna);
		else menu_additem(MyMenu,"Wyrzuc Gracza","",0,nieaktywna);
		
		menu_additem(MyMenu,"Rozdaj punkty","",0,aktywna);
		menu_additem(MyMenu,"Usun Gildie","",0,aktywna);
		menu_additem(MyMenu,"Ogolne info","",0,aktywna);
	}
	case 2:{
		menu_additem(MyMenu,"Opis Gildi","",0,aktywna);
		
//		if(player_lvl[id]>10) menu_additem(MyMenu,"Wplac expa","",0,aktywna);
//		else menu_additem(MyMenu,"Wplac expa","",0,nieaktywna);
		
		if(player_krysztal[id]) menu_additem(MyMenu,"Daj krysztal","",0,aktywna);
		else menu_additem(MyMenu,"Daj krysztal","",0,nieaktywna);
		
		menu_additem(MyMenu,"Odejdz z gildi","",0,aktywna);
		
		menu_additem(MyMenu,"Ogolne info","",0,aktywna);	
	}
}


menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

menu_setprop(MyMenu,MPROP_BACKNAME,"Wroc")
menu_setprop(MyMenu,MPROP_NEXTNAME,"Nastepne")

//zawsze poka¿ opcjê wyjœcia
menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

//kolor cyfry przycisku zmieñ na ¿ó³ty
//menu_setprop(MyMenu,MPROP_NUMBER_COLOR,"r");

menu_display(id, MyMenu,0);
return PLUGIN_HANDLED;
}
public gildia_menu(id, menu, item){
if(item == MENU_EXIT){
	menu_destroy(menu);
	otwarte_menu[id] = false
	return PLUGIN_HANDLED;
}
switch(tryb[id]){
	case 0:{
		
		switch(item){
			case 0:{
				zrob_gildie(id)
			}
			case 1:{
				showpomoc_gildie(id)
				gildie(id)
			}
		}
	}
	case 1:{
		switch(item){
			case 0:{
				gildia_wybierz(id)
			}
			case 1:{
				wczytaj_gildia(id)
				showgildia(id)
			}
//			case 2:{
//				wczytaj_gildia(id)
//				client_cmd(id, "messagemode wprowadz_ilosc_expa");
//				ColorChat(id,GREEN,"[*%s*]^x01Twoj exp wynosi %i.",nazwa_gildi[id],player_xp[id]-1)
//			}
			case 2:{
				wczytaj_gildia(id)
				client_cmd(id, "messagemode wprowadz_krysztal");
				ColorChat(id,GREEN,"[*%s*]^x01Posiadasz %i krysztalow",nazwa_gildi[id],player_krysztal[id])
			}
			case 3:{
				odejdz_gildia(id)
			}
			case 4:{
				rozdaj_skill(id)
			}
			case 5:{
				rozwiaz_gildie_menu(id)
			}
			case 6:{
				showpomoc_gildie(id)
				gildie(id)
			}
		}
	}
	case 2:{
		switch(item){
			case 0:{
				wczytaj_gildia(id)
				showgildia(id)
			}
//			case 1:{
//				wczytaj_gildia(id)
//				client_cmd(id, "messagemode wprowadz_ilosc_expa");
//				ColorChat(id,GREEN,"[*%s*]^x01Twoj exp wynosi %i.",nazwa_gildi[id],player_xp[id]-1)
//			}
			case 1:{
				wczytaj_gildia(id)
				client_cmd(id, "messagemode wprowadz_krysztal");
				ColorChat(id,GREEN,"[*%s*]^x01Posiadasz %i krysztalow",nazwa_gildi[id],player_krysztal[id])
			}
			case 2:{
				odejdz_gildia(id)
			}
			case 3:{
				showpomoc_gildie(id)
				gildie(id)
			}
		}
	}
}
otwarte_menu[id] = false
return PLUGIN_HANDLED;
}
//////////////////////////////////////////////
public odejdz_gildia(id)
{
new AuthID[35]

get_user_name(id,AuthID,34)
if(!equal(AuthID,nazwa_zalozycial[id])){
	
	wczytaj_gildia(id)
	--ilosc_czlonkow[id]
	
	
	new vaultkey[64]
	format(vaultkey,63,"%s-GIL",AuthID);
	nvault_remove(g_gil_spr,vaultkey);
	
	zapis_gildia(id,0)
	
	ColorChat(id,GREEN,"[*%s*]^x01 Odeszles z Gildi",nazwa_gildi[id])
	
	gildia_lvl[id] = 0
	gildia_exp[id] = 0
	ilosc_czlonkow[id] = 0
	g_dmg[id] = 0
	g_def[id] = 0
	g_hp[id] = 0
	g_spid[id] = 0
	g_pkt[id] = 0
	g_drop[id] = 0
	g_woj[id] = 0
	g_kam[id] = 0
	nazwa_gildi[id] = ""
	nazwa_zalozycial[id] = ""
	nick_gildia(id)
	
	return PLUGIN_CONTINUE
}
else if(ilosc_czlonkow[id]>1){
	wczytaj_gildia(id)
	menu_wywal(id)	
}

return PLUGIN_CONTINUE
}
public rozwiaz_gildie_menu(id)
{
new MyMenu=menu_create("Chcesz Usunac Gildie ??","rozwiaz_gildie");

menu_additem(MyMenu,"Tak","",0,_);
menu_additem(MyMenu,"Nie","",0,_);

menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

//zawsze poka¿ opcjê wyjœcia
menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

//kolor cyfry przycisku zmieñ na ¿ó³ty
//menu_setprop(MyMenu,MPROP_NUMBER_COLOR,"r");

menu_display(id, MyMenu,0);
return PLUGIN_HANDLED;
}
public rozwiaz_gildie(id, menu, item)
{
if(item == MENU_EXIT){
	menu_destroy(menu);
	otwarte_menu[id] = false
	return PLUGIN_HANDLED;
}
switch(item){
	case 0:{
		new iPlayers[ 32 ], iNum;
		new AuthID[35]
		
		get_players( iPlayers, iNum );
		
		new iPlayer;
		
		for( new i = 0; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( iPlayer == id )
				continue;
			
			if(!equal(nazwa_gildi[id],nazwa_gildi[iPlayer]))
				continue;
			
			get_user_name(iPlayer,AuthID,34)
			new vaultkey[64]
			format(vaultkey,63,"%s-GIL",AuthID);
			nvault_remove(g_gil_spr,vaultkey);
			
			ColorChat(iPlayer,GREEN,"[*%s*]^x01 Gildia Usunieta",nazwa_gildi[iPlayer])
			
			nazwa_gildi[iPlayer] = ""
			nick_gildia(iPlayer)
		}
		get_user_name(id,AuthID,34)
		new vaultkey[64]
		format(vaultkey,63,"%s-GIL",AuthID);
		nvault_remove(g_gil_spr,vaultkey);
		new vaultkey1[64]
		format(vaultkey1,63,"%s-GTB",nazwa_gildi[id]);
		nvault_remove(g_gildia,vaultkey1);
		ColorChat(id,GREEN,"[*%s*]^x01 Gildia Usunieta",nazwa_gildi[id])
		nazwa_gildi[id] = ""
		nick_gildia(id)
	}
}
otwarte_menu[id] = false
return PLUGIN_HANDLED;

}
//////////////////menu//////////////
public rozdaj_skill(id)
{

new Msg1[50]
new Msg2[50]
new Msg3[50]
new Msg4[50]
new Msg6[50]

format(Msg6,49,"Rozdaj Punkty [%i]",g_pkt[id])

new MyMenu=menu_create(Msg6,"gildia_skill");

new aktywna=menu_makecallback("aktywna_func");

new nieaktywna=menu_makecallback("nieaktywna_func");

format(Msg1,49,"Zycie [%i] [+%i%% hp]",g_hp[id],g_hp[id])
format(Msg2,49,"Atak [%i] [Zadajesz %i%% dodatkowych obrazen]",g_dmg[id],g_dmg[id])
format(Msg3,49,"Obrona [%i] [Redukcja %i%% obrazen]",g_def[id],g_def[id])
format(Msg4,49,"Szybkosc [%i] [+%i do predkosci]",g_spid[id],g_spid[id]*10)

if(g_pkt[id] && g_hp[id] <=10) menu_additem(MyMenu,Msg1,"",0,aktywna);
else menu_additem(MyMenu,Msg1,"",0,nieaktywna);

if(g_pkt[id] && g_dmg[id] <=5) menu_additem(MyMenu,Msg2,"",0,aktywna);
else menu_additem(MyMenu,Msg2,"",0,nieaktywna);

if(g_pkt[id] && g_def[id] <=5) menu_additem(MyMenu,Msg3,"",0,aktywna);
else menu_additem(MyMenu,Msg3,"",0,nieaktywna);

if(g_pkt[id] && g_spid[id] <=5) menu_additem(MyMenu,Msg4,"",0,aktywna);
else menu_additem(MyMenu,Msg4,"",0,nieaktywna);

if(g_pkt[id]>=5 && !g_drop[id] && g_kam[id]>=500) menu_additem(MyMenu,"+20% expa dla czlonkow gildii [5 pkt i 500 krysztalow]","",0,aktywna);
else menu_additem(MyMenu,"+20% expa dla czlonkow gildii [5 pkt i 500 krysztalow]","",0,nieaktywna);

if(g_kam[id]>=150) menu_additem(MyMenu,"Zresetuj Staty (150 krysztalow)(nie resetujesz dodatkowego expa)","",0,aktywna);
else menu_additem(MyMenu,"Zresetuj Staty (150 krysztalow)","",0,nieaktywna);

menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

//kolor cyfry przycisku zmieñ na ¿ó³ty
//menu_setprop(MyMenu,MPROP_NUMBER_COLOR,"r");

menu_display(id, MyMenu,0);
return PLUGIN_HANDLED;
}
public gildia_skill(id, menu, item){
if(item == MENU_EXIT){
	menu_destroy(menu);
	otwarte_menu[id] = false
	return PLUGIN_HANDLED;
}
switch(item){
	case 0:{
		g_hp[id]++
		g_pkt[id]--
		zapis_gildia(id,0)
	}
	case 1:{
		g_dmg[id]++
		g_pkt[id]--
		zapis_gildia(id,0)
	}
	case 2:{
		g_def[id]++
		g_pkt[id]--
		zapis_gildia(id,0)
	}
	case 3:{
		g_spid[id]++
		g_pkt[id]--
		zapis_gildia(id,0)
	}
	case 4:{
		g_drop[id]+=1
		g_pkt[id]-=5
		g_kam[id]-=500
		zapis_gildia(id,0)
	}
	case 5:{
		g_kam[id]-=150
		g_pkt[id]+=g_def[id]+g_dmg[id]+g_hp[id]+g_spid[id]
		g_def[id]=0
		g_dmg[id]=0
		g_spid[id]=0
		g_hp[id]=0
		ColorChat(id,GREEN,"[*%s*]^x01Masz %i pkt.",nazwa_gildi[id],g_pkt[id])
		zapis_gildia(id,0)
	}
}
rozdaj_skill(id)
return PLUGIN_HANDLED;
}
//////////////wspolny exp///////////////
public daj_gildi_exp(id,exp)
{
switch(gildia_lvl[id])
{
	case 1: exp /=10
		case 2: exp /=9
		case 3: exp /=8
		case 4: exp /=7
		case 5: exp /=6
		case 6: exp /=5
		case 7: exp /=4
		case 8: exp /=3
		case 9: exp /=2
}

for(new i=0; i<=32; i++)
{
	if(!is_user_connected(i))
		continue;
	if(!is_user_alive(i))
		continue;
	if(id==i)
		continue;
	if(equali(nazwa_gildi[i],"Brak"))
		continue;
	if(equali(nazwa_gildi[i],""))
		continue;
	if(!equal(nazwa_zalozycial[id],nazwa_zalozycial[i]))
		continue;
	
	if(exp<2)
		continue;
	
	Give_Xp(i,exp)
	
	ColorChat(i,GREEN,"+%i xp",exp)
}
}
//////////////////menu//////////////
public iDodaj(id)
{

new szDodaj[196];
read_args(szDodaj,charsmax(szDodaj))
remove_quotes(szDodaj)
if(is_str_num(szDodaj)) 
{
	new iIle = str_to_num(szDodaj)
	if(iIle >= player_xp[id]){
		ColorChat(id,GREEN,"[*%s*]^x01Masz za malo xp.",nazwa_gildi[id])
		
		gildie(id)
		
		return PLUGIN_CONTINUE;
	}
	if(get_playersnum()<2) {
		ColorChat(id,GREEN,"[*%s*]^x01Za malo graczy na serwerze",nazwa_gildi[id])
		
		gildie(id)
		return PLUGIN_CONTINUE;
	}
	if(iIle < 2000){
		ColorChat(id,GREEN,"[*%s*]^x01Minimalna wplata 2000.",nazwa_gildi[id])
		
		gildie(id)
		
		return PLUGIN_CONTINUE;
	}
	
	ColorChat(id,GREEN,"[*%s*]^x01Wplaciles %i",nazwa_gildi[id],iIle)
	Give_Xp(id,-iIle)
	gildia_exp[id]+=iIle
	if (gildia_exp[id] > GildiaXP[gildia_lvl[id]])
	{	
		gildia_lvl[id]+=1
		g_pkt[id]++
	}
	zapis_gildia(id,0)
	
	wczytaj_wplata(id)
	wplata[id]+=iIle
	zapisz_wplata(id)
	
	
	
}
else{
	ColorChat(id,GREEN,"[*%s*]^x01Tylko cyfry",nazwa_gildi[id])
	
	gildie(id)
	
	return PLUGIN_CONTINUE;
}
return PLUGIN_CONTINUE;
}
public iDodaj1(id)
{

new szDodaj[196];
read_args(szDodaj,charsmax(szDodaj))
remove_quotes(szDodaj)
if(is_str_num(szDodaj)) 
{
	new iIle = str_to_num(szDodaj)
	if(iIle > player_krysztal[id]){
		ColorChat(id,GREEN,"[*%s*]^x01Masz za malo krysztalow.",nazwa_gildi[id])
		
		gildie(id)
		
		return PLUGIN_CONTINUE;
	}
	ColorChat(id,GREEN,"[*%s*]^x01Wplaciles %i",nazwa_gildi[id],iIle)
	g_kam[id]+=iIle
	player_krysztal[id] -= iIle
	zapis_gildia(id,0)
	zapiszk(id)
}
else{
	ColorChat(id,GREEN,"[*%s*]^x01Tylko cyfry",nazwa_gildi[id])
	
	gildie(id)
	
	return PLUGIN_CONTINUE;
}
return PLUGIN_CONTINUE;
}
/*public za_mroz(attacker_id,id)
{
if(player_class[attacker_id] == Mefisto && random_num(1,20) == 1){
	
	if (!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if (totemstop[id]!=0)
		return PLUGIN_HANDLED
	
	if (random_num(1,10) == 1)
	{
		totemstop[id] = 1
		brak_strzal[id] = 1 
		set_speedchange(id)
		set_renderchange(id)
		set_task(0.7,"pogolemie",id)
	}
}
return PLUGIN_HANDLED
}*/
public pogolemie(id)
{
totemstop[id] = 0
brak_strzal[id] = 0
set_speedchange(id)
set_renderchange(id)
}
/////////////////////////////////////////////////////

public on_damage(id)
{	
static attacker; attacker = get_user_attacker(id)
static damage; damage = read_data(2)	

set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage)	

if(is_user_connected(attacker))
{
	if (pev(id,pev_rendermode) == kRenderTransTexture || player_b_inv[id] < 70 && player_b_inv[id] != 0|| player_class[id] == Ninja || invisible_cast[id] == 1||!fm_is_ent_visible(attacker,id))
		return PLUGIN_CONTINUE
	
	
	set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
	ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)	
}
return PLUGIN_HANDLED
}
public pokaz_obr(id,Float:dmg)
{
if(is_user_connected(id))
{
	set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
	ShowSyncHudMsg(id, g_hudmsg1, "%.1f^n", dmg)	
}
return PLUGIN_HANDLED
}
/////////////////rakieta/////////////////
bombs_explode(ent, Float:zadaje, Float:promien)
{
if(!is_valid_ent(ent)) 
return;

new attacker = entity_get_edict(ent, EV_ENT_owner);

new Float:entOrigin[3], Float:Origin[3];
entity_get_vector(ent, EV_VEC_origin, entOrigin);
entOrigin[2] += 1.0;

new entlist[33];
new numfound = find_sphere_class(ent, "player", promien, entlist, 32);	
for(new i=0; i < numfound; i++)
{		
	new victim = entlist[i];		
	if(!is_user_alive(victim) || get_user_team(attacker) == get_user_team(victim))
		continue;
	
	entity_get_vector(victim, EV_VEC_origin, Origin);
	new Float:fDamage
	fDamage = zadaje - (zadaje*player_damreduction[victim]) + float(player_intelligence[attacker])
	if(fDamage>0.0)
		TakeDamage(victim, attacker, fDamage, DMG_ENERGYBEAM, "Pred");
}
message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
write_byte(TE_EXPLOSION);
write_coord(floatround(entOrigin[0]));
write_coord(floatround(entOrigin[1])); 
write_coord(floatround(entOrigin[2]));
write_short(sprite_blast);
write_byte(32);
write_byte(20); 
write_byte(0);
message_end();
remove_entity(ent);
}
stock TakeDamage(victim, attacker, Float:fDamage, damagebits, const szWeapon[] = ""){
static info_target = 0;
if(!info_target)
	info_target = engfunc(EngFunc_AllocString, "info_target");


new ent = 0
ent = engfunc(EngFunc_CreateNamedEntity, info_target);
set_pev(ent, pev_classname, szWeapon);
ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, fDamage, damagebits);
set_pev(ent, pev_flags, FL_KILLME);
}
public command_kula(id) 
{
if(!is_user_alive(id)) return PLUGIN_HANDLED

if(makul[id] == 1){
	entity_set_string(id,EV_SZ_viewmodel,V_MODEL)
	entity_set_string(id,EV_SZ_weaponmodel,P_MODEL)
	if(bowdelay[id] + 2 < get_gametime()) bowdelay[id] = get_gametime()-3
}
else
{
	entity_set_string(id,EV_SZ_viewmodel,KNIFE_VIEW)
	entity_set_string(id,EV_SZ_weaponmodel,KNIFE_PLAYER)
	makul[id]=0
}

return PLUGIN_CONTINUE
}
public command_kula1(id) 
{

if(!is_user_alive(id)) return PLUGIN_HANDLED

ent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

new Float:Origin[3], Float:Angle[3], Float:Velocity[3];
pev(id, pev_origin, Origin);
pev(id, pev_v_angle, Angle);
Origin[2]-=15.0
Angle[0] *= -1.0

if (!ent[id]) return PLUGIN_HANDLED

set_pev(ent[id], pev_classname, BALL_CLASS);
engfunc(EngFunc_SetModel, ent[id], g_model);

set_pev(ent[id], pev_solid, SOLID_BBOX);
switch(mod_k[id])
{
	case 0:
	{
		velocity_by_aim(id, 480, Velocity);
		set_pev(ent[id], pev_movetype, MOVETYPE_BOUNCE);
	}
	case 1:
	{
		velocity_by_aim(id, 700, Velocity);
		set_pev(ent[id], pev_movetype, MOVETYPE_TOSS);
		set_pev(ent[id], pev_gravity, 0.35);
	}
}
set_pev(ent[id], pev_owner, id);
set_pev(ent[id], pev_mins, Float:{-4.0, -4.0, -4.0});
set_pev(ent[id], pev_maxs, Float:{4.0, 4.0, 4.0});
set_pev(ent[id], pev_origin, Origin);
set_pev(ent[id], pev_velocity, Velocity);
set_pev(ent[id], pev_angles, Angle);

return PLUGIN_CONTINUE;

}
public wybuch(id)
{
if(!pev_valid(ent[id]))
	return FMRES_IGNORED

new class[32]
pev(ent[id], pev_classname, class, charsmax(class))

if(!equal(class, BALL_CLASS))
	return FMRES_IGNORED

new Float:entOrigin[3], Float:fDamage, Float:Origin[3];
pev(ent[id], pev_origin, entOrigin);
entOrigin[2] += 1.0;

new Float:g_damage = 280.0
new Float:g_radius = 160.0
g_damage += player_intelligence[id]/2
g_radius += player_dextery[id]

new victim = -1
while((victim = engfunc(EngFunc_FindEntityInSphere, victim, entOrigin, g_radius)) != 0)
{		
	if(!is_user_alive(victim) || get_user_team(id) == get_user_team(victim))
		continue;
	
	pev(victim, pev_origin, Origin);
	fDamage = g_damage - floatmul(g_damage, floatdiv(get_distance_f(Origin, entOrigin), g_radius));
	fDamage *= estimate_take_hurt(entOrigin, victim);
	if(fDamage>0.0)
		ExecuteHamB(Ham_TakeDamage, victim, ent[id], id, fDamage, DMG_BULLET );
}

message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
write_byte(TE_EXPLOSION); 
write_coord(floatround(entOrigin[0])); 
write_coord(floatround(entOrigin[1])); 
write_coord(floatround(entOrigin[2])); 
write_short(sprite_blast); 
write_byte(40);
write_byte(30);
write_byte(TE_EXPLFLAG_NONE); 
message_end(); 

message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(5)
write_coord(floatround(entOrigin[0])); 
write_coord(floatround(entOrigin[1])); 
write_coord(floatround(entOrigin[2]));
write_short(sprite_smoke);
write_byte(35);
write_byte(5);
message_end();
fm_remove_entity(ent[id]);
ent[id]=0
return FMRES_IGNORED
}

//////////////////menu//////////////
public show_menu_haslo(id)
{
new MyMenu=menu_create("Zaloz haslo","haslo_1");

new aktywna=menu_makecallback("aktywna_func");

menu_additem(MyMenu,"Zaloz Haslo^n^nProsimy o zalozenie hasla^nJest ono niezbedne do zarzadzania gildia np. przelewanie na nia expa^nJezeli tego nie zrobisz, mozez zostac okradziony z doswiadczenia!","",0,aktywna);

menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

//zawsze poka¿ opcjê wyjœcia
menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

//kolor cyfry przycisku zmieñ na ¿ó³ty
//menu_setprop(MyMenu,MPROP_NUMBER_COLOR,"r");

menu_display(id, MyMenu,0);
return PLUGIN_HANDLED;
}
public haslo_1(id, menu, item){
if(item == MENU_EXIT){
	menu_destroy(menu);
	otwarte_menu[id] = false
	return PLUGIN_HANDLED;
}
switch(item){
	case 0:{
	{
		client_cmd(id, "messagemode wpisz_haslo")
		ColorChat(id,GREEN,"[*diablo*]^x01 Podaj Haslo.")
	}
}
}


otwarte_menu[id] = false
return PLUGIN_HANDLED;
}
public cmd_say(id)
{
new Arg1[31];
read_args(Arg1, charsmax(Arg1));
remove_quotes(Arg1);

if (!((equal(Arg1, "/whois",6)) || (equal(Arg1, "/whostats",6))))
return PLUGIN_CONTINUE;

if (equal(Arg1, "/whostats",6))
{
	new player = cmd_target(id, Arg1[10], 0);
	if (!player)
	{
		client_print(id,print_chat, "Przepraszamy, gracz %s nie moze zostac zlokalizowany",Arg1[10])
		return PLUGIN_CONTINUE;
	}
	
	display_stats(id,player);
	
	return PLUGIN_CONTINUE;
}
return PLUGIN_CONTINUE;
}

public display_stats(id,sid)
{
new tempstring[100];
new motd[2048];
new tempname[32];
get_user_name(sid,tempname,charsmax(tempname));

formatex(motd,charsmax(motd),"<html><body bgcolor=^"#000000^"><font size=^"2^" face=^"verdana^" color=^"FFB000^"><center><strong>Statystyki Graczy: %s</strong><br>", tempname);
add(motd,charsmax(motd),"(Aktualizowane co Runde)<br><br>");

formatex(tempstring,charsmax(tempstring),"Gildia: %s<br>",nazwa_gildi[sid]);
add(motd,charsmax(motd),tempstring);
formatex(tempstring,charsmax(tempstring),"Lvl Gildi: %i<br>",gildia_lvl[sid]);
add(motd,charsmax(motd),tempstring);
formatex(tempstring,charsmax(tempstring),"Aktualna Klasa: %s (%i Lvl)<br>",Race[player_class[sid]],player_lvl[sid]);
add(motd,charsmax(motd),tempstring);
formatex(tempstring,charsmax(tempstring),"Liczba krysztalow: %i<br>",player_krysztal[sid]);
add(motd,charsmax(motd),tempstring);
//formatex(tempstring,charsmax(tempstring),"Zadanie nr. : %i<br>",player_misja[sid]);
//add(motd,charsmax(motd),tempstring);
formatex(tempstring,charsmax(tempstring),"Przedmiot: %s<br>",player_item_name[sid]);
add(motd,charsmax(motd),tempstring);
formatex(tempstring,charsmax(tempstring),"<b>Statystyki Innych Klas</b><br>");
add(motd,charsmax(motd),tempstring);
for(new i=1;i<ILE_KLAS;i++)
{
	if(player_class_lvl[sid][i]>5 && player_class[sid]!= i)
	{
		formatex(tempstring,charsmax(tempstring),"%s (%i Lvl)<br>",Race[i],player_class_lvl[sid][i]);
		add(motd,charsmax(motd),tempstring);
	}
}
add(motd,charsmax(motd),"</center></font></body></html>");

show_motd(id,motd,"Legion: Statystyki Gracza");

}

//////////////////////////////////////////////
//etst//
///


public menu_wywal(id)
{
new key[128],nazwa_gildi1[128],nick[64]
new MyMenu=menu_create("Wywal","info_wywal");

new iPos , szKey[ 32 ] , szVal[ 64 ] , iTimeStamp;
new ala[32],nazwa1[128]
new iVaultHandle = nvault_util_open("nickgil")
new iCount = nvault_util_count (iVaultHandle) 

get_user_name(id, nick, 63)

for ( new iCurrent = 1 , n=0; iCurrent <= iCount ; iCurrent++ )
{
	iPos = nvault_util_read( iVaultHandle , iPos , szKey , charsmax( szKey ) , szVal , charsmax( szVal ) , iTimeStamp );
	
	
	parse(szVal, ala, 31);
	copy(nazwa1, 31, ala);
	
	if(!equal(nazwa_gildi[id],nazwa1))
		continue;
	
	
	formatex(key, 127, "%s",szKey);
	key[strlen(key)-4] = 0;
	
	if(equal(key,nick))
		continue;
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s-GIL",key)
	nvault_get(g_gil_spr,vaultkey,vaultdata,255);
	
	new ng[32]
	parse(vaultdata,ng , 31)
	
	copy(nazwa_gildi1, 31, ng);
	
	if(equali(nazwa_gildi1,""))
		continue;
	
	oddaj_name[n++] = key;
	
	
	menu_additem(MyMenu, key, _, _,  _);
	
}
menu_setprop(MyMenu,MPROP_EXITNAME,"Wyjscie");

menu_setprop(MyMenu,MPROP_BACKNAME,"Wroc")
menu_setprop(MyMenu,MPROP_NEXTNAME,"Nastepne")

//zawsze poka? opcj? wyj?cia
menu_setprop(MyMenu,MPROP_EXIT,MEXIT_ALL);

menu_setprop(MyMenu,MPROP_PERPAGE,7)

menu_display(id, MyMenu);
}

public info_wywal(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu);
	return PLUGIN_HANDLED
}


new nazwa_menu[128]
formatex(nazwa_menu, charsmax(nazwa_menu), "Wywal gracza %s",oddaj_name[item])

new menu2 = menu_create(nazwa_menu, "menu_wywal1");

menu_additem(menu2,"Tak");
menu_additem(menu2,"Nie");

menu_setprop(menu2,MPROP_EXITNAME,"Wyjscie");

//zawsze poka¿ opcjê wyjœcia
menu_setprop(menu2,MPROP_EXIT,MEXIT_ALL);

menu_setprop(menu2,MPROP_PERPAGE,7)
zapamietaj_name[id] = oddaj_name[item]
menu_display(id, menu2);

return PLUGIN_HANDLED
}
public menu_wywal1(id, menu, item)
{
if(item == MENU_EXIT)
{
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

switch(item)
{
	case 0: 
	{ 
		new nick[64]
		for(new i=0; i<=32; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			get_user_name(i, nick, 63)
			
			if(equal(nick,zapamietaj_name[id])){
				new id2 = i
				
				wczytaj_gildia(id2)
				ilosc_czlonkow[id2]--
				zapis_gildia(id2,0)
				
				new vaultkey[64]
				format(vaultkey,63,"%s-GIL",zapamietaj_name[id]);
				nvault_remove(g_gil_spr,vaultkey);
				
				ColorChat(id,GREEN,"[*%s*]^x01 Wywaliles Gracza %s (online)",nazwa_gildi[id],zapamietaj_name[id])
				ColorChat(id2,GREEN,"[*%s*]^x01 Wywalono cie z gildi",nazwa_gildi[id2])
				
				gildia_lvl[id2] = 0
				gildia_exp[id2] = 0
				ilosc_czlonkow[id2] = 0
				g_dmg[id2] = 0
				g_def[id2] = 0
				g_hp[id2] = 0
				g_spid[id2] = 0
				g_pkt[id2] = 0
				nazwa_gildi[id2] = ""
				nazwa_zalozycial[id2] = ""
				nick_gildia(id)
				
				return PLUGIN_HANDLED
			}
			else {
				new vaultkey[64]
				format(vaultkey,63,"%s-GIL",zapamietaj_name[id]);
				nvault_remove(g_gil_spr,vaultkey);
				
				ColorChat(id,GREEN,"[*%s*]^x01 Wywaliles Gracza %s (offline)",nazwa_gildi[id],zapamietaj_name[id])
				ilosc_czlonkow[id]--
				zapis_gildia(id,0)
				
				return PLUGIN_HANDLED
			}
		}
	}
}

return PLUGIN_CONTINUE;
}
public CmdGiveGil(id, level, cid) 
{ 
if(!cmd_access(id,level, cid, 3)) 
	return PLUGIN_HANDLED; 

new szPlayer[32]; 
read_argv(1,szPlayer, 31);

new szExp[10], iExp; 
read_argv(2, szExp, 9); 
iExp=str_to_num(szExp);

new szName[32];
new iTarget=cmd_target(id,szPlayer,0);
if( !iTarget ) 
{
	return PLUGIN_HANDLED;
} 
if(!gildia_lvl[iTarget]) 
{
	console_print(id, "Gracz nie ma gildi"); 
	return PLUGIN_HANDLED;
	
} 
wczytaj_gildia(iTarget)

gildia_exp[iTarget]+=iExp

zapis_gildia(iTarget,0)

wczytaj_wplata(iTarget)
wplata[iTarget]+=iExp
zapisz_wplata(iTarget)

get_user_name(iTarget, szName, sizeof szName - 1)
console_print(id, "%s dostal %i expa na gildie %s",szName, iExp, nazwa_gildi[iTarget]); 

return PLUGIN_HANDLED 
}
/////////////////////////////////////////////////////////
public  fullupdate(id) 
{
return PLUGIN_HANDLED
}
/////////////////////////////////////////////////
BeamLiveForTime(const ent, const Float: time)
{
set_pev(ent, pev_nextthink, halflife_time() + time);
}

BeamSetColor(const ent, const Float: red, const Float: green, const Float: blue)
{
static Float: rgb[3];

rgb[0] = red;
rgb[1] = green;
rgb[2] = blue;

set_pev(ent, pev_rendercolor, rgb);
}

BeamSetBrightness(const ent, const Float: brightness)
{
set_pev(ent, pev_renderamt, brightness);
}

BeamSetNoise(const ent, const noise)
{
set_pev(ent, pev_body, noise);
}

BeamSetFrame(const ent, const frame)
{
set_pev(ent, pev_frame, frame);
}

BeamSetScrollRate(const ent, const Float: speed)
{
set_pev(ent, pev_animtime, speed);
}

BeamSetTexture(const ent, const spriteIndex)
{
set_pev(ent, pev_modelindex, spriteIndex);
}

BeamSetWidth(const ent, const Float: width)
{
set_pev(ent, pev_scale, width);
}

//mikstury co 30 sek.
public reset_mikstura(id)
{
	uzyl_mikstury[id] = 0;
	ColorChat(id, RED, "Mozesz juz uzyc mikstury!")
}
//showitem ze starego diablo
public showitem2(id,itemname[],itemeffect[],Durability[])
{
        new diabloDir[64]       
        new g_ItemFile[64]
        new amxbasedir[64]
        get_basedir(amxbasedir,63)
        
        format(diabloDir,63,"%s/diablo",amxbasedir)
        
        if (!dir_exists(diabloDir))
        {
                new errormsg[512]
                format(errormsg,511,"Blad: Folder %s/diablo nie mog³ byæ znaleziony. Prosze skopiowac ten folder z archiwum do folderu amxmodx",amxbasedir)
                show_motd(id, errormsg, "An error has occured") 
                return PLUGIN_HANDLED
        }
        
        
        format(g_ItemFile,63,"%s/diablo/item.txt",amxbasedir)
        if(file_exists(g_ItemFile))
                delete_file(g_ItemFile)
        
        new Data[768]
        
        //Header
        format(Data,767,"<html><head><title>Informacje o przedmiocie</title></head>")
        write_file(g_ItemFile,Data,-1)
        
        //Background
        format(Data,767,"<body text=^"#FFFF00^" bgcolor=^"#000000^" background=^"http://cs-fifka.pl/serwery/diablo/drkmotr.jpg^">",Basepath)
        write_file(g_ItemFile,Data,-1)
        
        //Table stuff
        format(Data,767,"<table border=^"0^" cellpadding=^"0^" cellspacing=^"0^" style=^"border-collapse: collapse^" width=^"100%s^"><tr><td width=^"0^">","^%")
        write_file(g_ItemFile,Data,-1)
        
        //ss.gif image
        format(Data,767,"<p align=^"center^"><img border=^"0^" src=^"http://cs-fifka.pl/serwery/diablo/ss.gif^"></td>",Basepath)
        write_file(g_ItemFile,Data,-1)
        

        //item name
        format(Data,767,"<td width=^"0^"><p align=^"center^"><font face=^"Arial^"><font color=^"#FFCC00^"><b>Przedmiot: </b>%s</font><br>",itemname)
        write_file(g_ItemFile,Data,-1)
        
        //Durability
        format(Data,767,"<font color=^"#FFCC00^"><b><br>Wytrzymalosc: </b>%s</font><br><br>",Durability)
        write_file(g_ItemFile,Data,-1)
        
        //Effects
        format(Data,767,"<font color=^"#FFCC00^"><b>Efekt:</b> %s</font></font></td>",itemeffect)
        write_file(g_ItemFile,Data,-1)
        
        //image ss
        format(Data,767,"<td width=^"0^"><p align=^"center^"><img border=^"0^" src=^"http://cs-fifka.pl/serwery/diablo/gf.gif^"></td>", Basepath)
        write_file(g_ItemFile,Data,-1)
        
        //end
        format(Data,767,"</tr></table></body></html>")
        write_file(g_ItemFile,Data,-1)
        
        //show window with message
        show_motd(id, g_ItemFile, "Informacje Przedmiotu")
        
        return PLUGIN_HANDLED
        
}
//antyflash
public det_fade(id)
{
	new m_anty_flesh=0
	if(random_num(0,100)<=player_m_antyflesh[id])
		m_anty_flesh=1
		
	if (wear_sun[id] == 1 || anty_flesh[id] == 1 || m_anty_flesh || a_wearsun[id]){
		Display_Icon(id ,ICON_FLASH ,ICON_S ,0,255,0)
		Display_Fade(id,1,1,1<<12,0,0,0,0)
	}
	if (wear_sun[id] == 0 || anty_flesh[id] == 0 || a_wearsun[id] == 0){
		Display_Icon(id ,ICON_HIDE ,ICON_S ,0,255,0)
	}
}
//leczenie
CreateHealBot()
{
        new Bot = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
        if (Bot)
        {
                set_pev(Bot, pev_classname, "HealBot");
                dllfunc(DLLFunc_Spawn, Bot);
                set_pev(Bot, pev_nextthink, get_gametime() + 3.0);
        }
}
public HealBotThink(Bot)
{
        new iPlayers[32], iNum, id;
        get_players(iPlayers, iNum);
        for(new i; i<iNum; i++)
        {
            id = iPlayers[i];
            if (!is_user_alive(id)) continue;
            if(c_heal[id] > 0)
				change_health(id,c_heal[id],0,"");
			if(player_witalnosc[id] > 0){
				new heal = player_witalnosc[id]/8
				change_health(id,heal,0,"");
			}
			if(a_heal[id] > 0)
				change_health(id,a_heal[id],0,"");
        }
        set_pev(Bot, pev_nextthink, get_gametime() + 3.0);
}
//piorun
public add_bonus_piorun(attacker_id,id)
{
if ((player_class[attacker_id] == Diablo && (random_num(1,5) == 1))/* || (player_class[attacker_id] == Tyrael && (random_num(1,5) == 1))*/)
{
    new Float:fl_Origin[3]
    pev(id, pev_origin, fl_Origin)  
if(cs_get_user_team(attacker_id) == cs_get_user_team(id))
return HAM_IGNORED

set_pev(id, pev_velocity, Float:{0.0,0.0,0.0}) // stop motion
//set_pev(id, pev_maxspeed, 5.0) // prevent from moving

thunder_effects(fl_Origin)
ExecuteHam(Ham_TakeDamage, id, attacker_id, attacker_id, 25.0+float(player_intelligence[id])/5 , 1);
}
return PLUGIN_HANDLED
}
thunder_effects(Float:fl_Origin[3])
{
        new Float:fX = fl_Origin[0], Float:fY = fl_Origin[1], Float:fZ = fl_Origin[2]



        // Beam effect between two points
        engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
        write_byte(TE_BEAMPOINTS)               // 0
        engfunc(EngFunc_WriteCoord, fX + 150.0) // start position
        engfunc(EngFunc_WriteCoord, fY + 150.0)
        engfunc(EngFunc_WriteCoord, fZ + 800.0)
        engfunc(EngFunc_WriteCoord, fX) // end position
        engfunc(EngFunc_WriteCoord, fY)
        engfunc(EngFunc_WriteCoord, fZ)
        write_short(sprite_lgt) // sprite index
        write_byte(1)                                   // starting frame
        write_byte(15)                                  // frame rate in 0.1's
        write_byte(10)                                  // life in 0.1's
        write_byte(80)                                  // line width in 0.1's
        write_byte(30)                                  // noise amplitude in 0.01's
        write_byte(255)                                 // red
        write_byte(255)                                 // green
        write_byte(255)                                 // blue
        write_byte(255)                                 // brightness
        write_byte(200)                                 // scroll speed in 0.1's
        message_end()

        // Sparks
        message_begin(MSG_PVS, SVC_TEMPENTITY)
        write_byte(TE_SPARKS)                   // 9
        engfunc(EngFunc_WriteCoord, fX) // position
        engfunc(EngFunc_WriteCoord, fY)
        engfunc(EngFunc_WriteCoord, fZ + 10.0)
        message_end()

        // Smoke
        engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
        write_byte(TE_SMOKE)                    // 5
        engfunc(EngFunc_WriteCoord, fX) // position
        engfunc(EngFunc_WriteCoord, fY)
        engfunc(EngFunc_WriteCoord, fZ + 10.0)
        write_short(sprite_smoke)               // sprite index
        write_byte(10)                                  // scale in 0.1's
        write_byte(10)                                  // framerate
        message_end()
        
        // Blood
        engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fl_Origin, 0)
        write_byte(TE_LAVASPLASH)               // 10
        engfunc(EngFunc_WriteCoord, fX) // position
        engfunc(EngFunc_WriteCoord, fY)
        engfunc(EngFunc_WriteCoord, fZ + 12.0)
        message_end()


}
//miny
public item_mine(id)
{
	
	if (!c_mine[id])
	{
		client_print(id, print_center, "Wykorzystales juz wszystkie miny!");
		return PLUGIN_CONTINUE;
	}
	
	if(player_intelligence[id] < 1)
		client_print(id, print_center, "Aby wzmocnic miny, zwieksz inteligencje!");
	
	c_mine[id]--;
	
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
	
	set_rendering(ent,kRenderFxNone, 0,0,0, kRenderTransTexture,80)	;
	
	
	return PLUGIN_CONTINUE;
}
public item_mine_item(id)
{
	if (player_b_mine[id] > 0 && is_user_alive(id))
	{
		new count = 0
		new ents = -1
		ents = find_ent_by_owner(ents,"Mine",id)
		while (ents > 0)
		{
			count++
			ents = find_ent_by_owner(ents,"Mine",id)
		}
		
		if (count > 2)
		{
			hudmsg(id,2.0,"Mozesz polozyc maksymalnie 3 miny na runde")
			return PLUGIN_CONTINUE
		}
		
		
		new origin[3]
		pev(id,pev_origin,origin)
			
		new ent = Spawn_Ent("info_target")
		set_pev(ent,pev_classname,"Mine")
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_movetype,MOVETYPE_TOSS)
		set_pev(ent,pev_origin,origin)
		set_pev(ent,pev_solid,SOLID_BBOX)
		
		engfunc(EngFunc_SetModel, ent, "models/mine.mdl")  
		engfunc(EngFunc_SetSize,ent,Float:{-16.0,-16.0,0.0},Float:{16.0,16.0,2.0})
		
		drop_to_floor(ent)

		entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.01) 
		
		set_rendering(ent,kRenderFxNone, 0,0,0, kRenderTransTexture,50)
	}
	return PLUGIN_CONTINUE
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
		
		remove_entity(ent);
		for (new i=0; i < numfound; i++)
		{
			new pid = entlist[i];
			
			if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid))
				continue;
				
			new dam = 70 + player_intelligence[id]
			change_health(pid,-dam,attacker,"grenade")
			//ExecuteHam(Ham_TakeDamage, pid, ent, attacker, dam , 1);
		}
	}
}
public trucizna(data[], len){
	new attacker_id, id
	attacker_id -= TASK_POCISKI_BIO
	id = data[0];
    attacker_id = data[1];
	if(is_user_alive(id)){
		change_health(id,-7,attacker_id,"world")
	}
}


//pulapki z granatow
public grenade_throw(id, ent, wID)
{	
	if(!g_TrapMode[id] || !is_valid_ent(ent))
		return PLUGIN_CONTINUE
		
	new Float:fVelocity[3]
	VelocityByAim(id, cvar_throw_vel, fVelocity)
	entity_set_vector(ent, EV_VEC_velocity, fVelocity)
	
	new Float: angle[3]
	entity_get_vector(ent,EV_VEC_angles,angle)
	angle[0]=0.00
	entity_set_vector(ent,EV_VEC_angles,angle)
	
	entity_set_float(ent,EV_FL_dmgtime,get_gametime()+3.5)
	
	entity_set_int(ent, NADE_PAUSE, 0)
	entity_set_int(ent, NADE_ACTIVE, 0)
	entity_set_int(ent, NADE_VELOCITY, 0)
	entity_set_int(ent, NADE_TEAM, get_user_team(id))
	
	new param[1]
	param[0] = ent
	set_task(3.0, "task_ActivateTrap", 0, param, 1)
	
	return PLUGIN_CONTINUE
}

public task_ActivateTrap(param[])
{
	new ent = param[0]
	if(!is_valid_ent(ent)) 
		return PLUGIN_CONTINUE
	
	entity_set_int(ent, NADE_PAUSE, 1)
	entity_set_int(ent, NADE_ACTIVE, 1)
	
	new Float:fOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, fOrigin)
	fOrigin[2] -= 8.1*(1.0-floatpower( 2.7182, -0.06798*float(player_agility[entity_get_edict(ent,EV_ENT_owner)])))
	entity_set_vector(ent, EV_VEC_origin, fOrigin)
	
	return PLUGIN_CONTINUE
}
public think_Grenade(ent)
{
	new entModel[33]
	entity_get_string(ent, EV_SZ_model, entModel, 32)
	
	if(!is_valid_ent(ent) || equal(entModel, "models/w_c4.mdl"))
		return PLUGIN_CONTINUE
	
	if(entity_get_int(ent, NADE_PAUSE))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}
public think_Bot(bot)
{
	new ent = -1
	while((ent = find_ent_by_class(ent, "grenade")))
	{
		new entModel[33]
		entity_get_string(ent, EV_SZ_model, entModel, 32)
			
		if(equal(entModel, "models/w_c4.mdl"))
			continue

		if(!entity_get_int(ent, NADE_ACTIVE))
			continue
				 
		new Players[32], iNum
		get_players(Players, iNum, "a")
						
		for(new i = 0; i < iNum; ++i)
		{
			new id = Players[i]
			if(entity_get_int(ent, NADE_TEAM) == get_user_team(id)) 
				continue
				
			if(get_entity_distance(id, ent) > cvar_activate_dis || player_speed(id) <200.0) 
				continue
			
			if(entity_get_int(ent, NADE_VELOCITY)) continue
			
			new Float:fOrigin[3]
			entity_get_vector(ent, EV_VEC_origin, fOrigin)
			while(PointContents(fOrigin) == CONTENTS_SOLID)
				fOrigin[2] += 100.0
		
			entity_set_vector(ent, EV_VEC_origin, fOrigin)
			drop_to_floor(ent)
				
			new Float:fVelocity[3]
			entity_get_vector(ent, EV_VEC_velocity, fVelocity)
			fVelocity[2] += float(cvar_nade_vel)
			entity_set_vector(ent, EV_VEC_velocity, fVelocity)
			entity_set_int(ent, NADE_VELOCITY, 1)
		
			new param[1]
			param[0] = ent 
			//set_task(cvar_explode_delay, "task_ExplodeNade", 0, param, 1)
			entity_set_float(param[0], EV_FL_nextthink, halflife_time() + cvar_explode_delay)
			entity_set_int(param[0], NADE_PAUSE, 0)
		}
	}
	if(get_timeleft()<2 && map_end<2)
	{
		map_end=2
	}
	else if(get_timeleft()<6 && map_end<1)
	{
		new play[32],num

		get_players(play,num)
		
		for(new i=0;i<num;i++)
		{
			savexpcom(play[i])
		}
		map_end=1
	}
	
	entity_set_float(bot, EV_FL_nextthink, halflife_time() + 0.1)
}
stock Float:player_speed(index) 
{
	new Float:vec[3]
	
	pev(index,pev_velocity,vec)
	vec[2]=0.0
	
	return floatsqroot ( vec[0]*vec[0]+vec[1]*vec[1] )
}
public _create_ThinkBot()
{
	new think_bot = create_entity("info_target")
	if(!is_valid_ent(think_bot))
		log_amx("For some reason, the universe imploded, reload your server")
	else 
	{
		entity_set_string(think_bot, EV_SZ_classname, "think_bot")
		entity_set_float(think_bot, EV_FL_nextthink, halflife_time() + 1.0)
	}
}

//hook - stary
stock kz_velocity_set(id,vel[3]) {
	//Set Their Velocity to 0 so that they they fall straight down from
	new Float:Ivel[3]
	Ivel[0]=float(vel[0])
	Ivel[1]=float(vel[1])
	Ivel[2]=float(vel[2])
	entity_set_vector(id, EV_VEC_velocity, Ivel)
}

stock kz_velocity_get(id,vel[3]) {
	//Set Their Velocity to 0 so that they they fall straight down from
	new Float:Ivel[3]

	entity_get_vector(id, EV_VEC_velocity, Ivel)
	vel[0]=floatround(Ivel[0])
	vel[1]=floatround(Ivel[1])
	vel[2]=floatround(Ivel[2])
}

public ropetask(parm[])
{
	new id = parm[0]
	new user_origin[3], user_look[3], user_direction[3], move_direction[3]
	new A[3], D[3], buttonadjust[3]
	new acceleration, velocity_towards_A, desired_velocity_towards_A
	new velocity[3], null[3]

	if (!is_user_alive(id))
	{
		RopeRelease(id)
		return
	}

	if (gBeamIsCreated[id] + BEAMLIFE/10 <= get_gametime())
	{
		beamentpoint(id)
	}

	null[0] = 0
	null[1] = 0
	null[2] = 0

	get_user_origin(id, user_origin)
	get_user_origin(id, user_look,2)
	kz_velocity_get(id, velocity)

	buttonadjust[0]=0
	buttonadjust[1]=0

	if (get_user_button(id)&IN_FORWARD)		buttonadjust[0]+=1
	if (get_user_button(id)&IN_BACK)		buttonadjust[0]-=1
	if (get_user_button(id)&IN_MOVERIGHT)	buttonadjust[1]+=1
	if (get_user_button(id)&IN_MOVELEFT)	buttonadjust[1]-=1
	if (get_user_button(id)&IN_JUMP)		buttonadjust[2]+=1
	if (get_user_button(id)&IN_DUCK)		buttonadjust[2]-=1

	if (buttonadjust[0] || buttonadjust[1])
	{
		user_direction[0] = user_look[0] - user_origin[0]
		user_direction[1] = user_look[1] - user_origin[1]

		move_direction[0] = buttonadjust[0]*user_direction[0] + user_direction[1]*buttonadjust[1]
		move_direction[1] = buttonadjust[0]*user_direction[1] - user_direction[0]*buttonadjust[1]
		move_direction[2] = 0

		velocity[0] += floatround(move_direction[0] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
		velocity[1] += floatround(move_direction[1] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
	}

	if (buttonadjust[2])	gHookLenght[id] -= floatround(buttonadjust[2] * REELSPEED * DELTA_T)
	if (gHookLenght[id] < 100) gHookLenght[id] = 100

	A[0] = gHookLocation[id][0] - user_origin[0]
	A[1] = gHookLocation[id][1] - user_origin[1]
	A[2] = gHookLocation[id][2] - user_origin[2]

	D[0] = A[0]*A[2] / get_distance(null,A)
	D[1] = A[1]*A[2] / get_distance(null,A)
	D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

	acceleration = - global_gravity * D[2] / get_distance(null,D)

	velocity_towards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
	desired_velocity_towards_A = (get_distance(user_origin,gHookLocation[id]) - gHookLenght[id] /*- 10*/) * 4

	if (get_distance(null,D)>10)
	{
		velocity[0] += floatround((acceleration * DELTA_T * D[0]) / get_distance(null,D))
		velocity[1] += floatround((acceleration * DELTA_T * D[1]) / get_distance(null,D))
		velocity[2] += floatround((acceleration * DELTA_T * D[2]) / get_distance(null,D))
	}

	velocity[0] += ((desired_velocity_towards_A - velocity_towards_A) * A[0]) / get_distance(null,A)
	velocity[1] += ((desired_velocity_towards_A - velocity_towards_A) * A[1]) / get_distance(null,A)
	velocity[2] += ((desired_velocity_towards_A - velocity_towards_A) * A[2]) / get_distance(null,A)

	kz_velocity_set(id, velocity)
}

public hooktask(parm[])
{ 
	new id = parm[0]
	new velocity[3]

	if ( !gIsHooked[id] ) return 
	
	new user_origin[3],oldvelocity[3]
	parm[0] = id

	if (!is_user_alive(id))
	{
		RopeRelease(id)
		return
	}

	if (gBeamIsCreated[id] + BEAMLIFE/10 <= get_gametime())
	{
		beamentpoint(id)
	}

	get_user_origin(id, user_origin) 
	kz_velocity_get(id, oldvelocity) 
	new distance=get_distance( gHookLocation[id], user_origin )
	if ( distance > 10 ) 
	{ 
		velocity[0] = floatround( (gHookLocation[id][0] - user_origin[0]) * ( 2.0 * REELSPEED / distance ) )
		velocity[1] = floatround( (gHookLocation[id][1] - user_origin[1]) * ( 2.0 * REELSPEED / distance ) )
		velocity[2] = floatround( (gHookLocation[id][2] - user_origin[2]) * ( 2.0 * REELSPEED / distance ) )
	} 
	else
	{
		velocity[0]=0
		velocity[1]=0
		velocity[2]=0
	}

	kz_velocity_set(id, velocity) 
	
} 

public hook_on(id)
{
	if (player_class[id] == Andariel && freeze_ended && is_user_alive(id))
	{
		new xd = floatround(halflife_time()-wait1[id])
		new czas = 5-xd
		if (halflife_time()-wait1[id] <= 5)
		{
			client_print(id, print_center, "Za %d sek mozesz uzyc pajeczyny!", czas)
			return PLUGIN_CONTINUE;
		}													
		else {
			if (!gIsHooked[id] && is_user_alive(id))
			{
				new cmd[32]
				read_argv(0,cmd,31)
				if(equal(cmd,"+rope")) RopeAttach(id,0)
				if(equal(cmd,"+hook")) RopeAttach(id,1)
				wait1[id]=floatround(halflife_time())
			}
		}
	}
	return PLUGIN_HANDLED
}

public hook_off(id)
{
	if (player_class[id] == Andariel) {
		if (gIsHooked[id])
		{
			RopeRelease(id)
		}
	}
	return PLUGIN_HANDLED
}

public RopeAttach(id,hook)
{
	new parm[1], user_origin[3]
	parm[0] = id
	gIsHooked[id] = true
	get_user_origin(id,user_origin)
	get_user_origin(id,gHookLocation[id], 3)
	gHookLenght[id] = get_distance(gHookLocation[id],user_origin)
	global_gravity = get_cvar_num("sv_gravity")
	set_user_gravity(id,0.001)
	beamentpoint(id)
	emit_sound(id, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	if (hook) set_task(DELTA_T, "hooktask", 200+id, parm, 1, "b")
	else set_task(DELTA_T, "ropetask", 200+id, parm, 1, "b")
}

public RopeRelease(id)
{
	gIsHooked[id] = false
	killbeam(id)
	set_user_gravity(id)
	remove_task(200+id)
}

public beamentpoint(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMENTPOINT )
	write_short( id )
	write_coord( gHookLocation[id][0] )
	write_coord( gHookLocation[id][1] )
	write_coord( gHookLocation[id][2] )
	write_short( beam )	// sprite index
	write_byte( 0 )		// start frame
	write_byte( 0 )		// framerate
	write_byte( BEAMLIFE )	// life
	write_byte( 10 )	// width
	write_byte( 0 )		// noise
	write_byte( 0 )	// r, g, b
	write_byte( 255 )	// r, g, b
	write_byte( 0 )	// r, g, b
	write_byte( 150 )	// brightness
	write_byte( 0 )		// speed
	message_end( )
	gBeamIsCreated[id] = get_gametime()
}

public killbeam(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_KILLBEAM )
	write_short( id )
	message_end()
}
public ResetHUD2(id) {
	//Check if he is hooked to something
	if (gIsHooked[id]) RopeRelease(id)
}
/*//moc bestii
public bestiaon(id)
{
	new xd = floatround(halflife_time()-poprzednie_uzycie[id])
	new czas = 30-xd
	if (halflife_time()-poprzednie_uzycie[id] <= 30)
	{
		client_print(id, print_center, "Za %d sek mozesz znow zmienic sie w bestie!", czas)
		return PLUGIN_CONTINUE;
	}
	if(player_class[id] == Bestia){
		c_bestia[id] = 1
		emit_sound (id, 0, "Ryklwa2.wav", 0.5, 0.8,0, 100 )
		set_gravitychange(id)
		set_speedchange(id)
		change_health(id,30,0,"")
		set_task(6.0, "bestiaoff", id)
		msg_bartime2(id, 6)
		message_begin(MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id);
        write_short(1<<10) // duration
        write_short(1<<10) // hold time
        write_short(0x0000) // flags
        write_byte(50) // red
        write_byte(0) // green
        write_byte(0) // blue
        write_byte(150) // alpha
        message_end()  
		poprzednie_uzycie[id]=floatround(halflife_time())
	}
	return PLUGIN_CONTINUE;
}
public bestiaoff(id)
{
	c_bestia[id] = 0
	set_gravitychange(id)
	set_speedchange(id)
}*/
stock msg_bartime2(id, seconds) 
{
	if(is_user_bot(id)||!is_user_alive(id)||!is_user_connected(id))
		return
	
	message_begin(MSG_ONE, g_msg_bartime, _, id)
	write_byte(seconds)
	write_byte(0)
	message_end()
}

public komendy_info(id)
	showitem2(id,"Pomoc","/menu - otwiera menu glowne NewDiabloMod (zarzadzanie klasa, itemem, artefaktem, gildia oraz haslem)<br>/klasa lub /k - zmiana klasy postaci<br>/item lub /i - info o itemie<br>/artefakt lub /art - info o artefakcie<br>/drop lub /d- wyrzuca aktualny item<br>/dropartefakt - wyrzuca aktualny artefakt<br>/czary - informacje o statach<br>/sklep lub /rune - otwiera sklep<br>/klasy - wyswietla opisy klas<br>/reset - resetuje staty<br><br>/q lub /questy - otwiera menu Questow", "Brak")




public OpisKlasy(id, menu, item)
{
	new OpisKlasy=menu_create("Opisy Klas New Diablo Mod","OpisKlasy_Handle");

	menu_additem(OpisKlasy,"Bohaterowie");//item=0
	menu_additem(OpisKlasy,"Potwory");//item=1
	menu_additem(OpisKlasy,"Demony");//item=2
	
	menu_display(id, OpisKlasy,0);
	return PLUGIN_HANDLED;
}
public OpisKlasy_Handle(id, menu, item){
		switch(item){
			case 0:{
				OpisKlas_bohaterowie(id, menu, item)
			}
			case 1:{
				OpisKlas_potwory(id, menu, item)
			}
			case 2:{
				OpisKlas_demony(id, menu, item)
			}
		}
		menu_destroy(menu);
		return PLUGIN_HANDLED;
}
public OpisKlas_bohaterowie(id, menu, item)
{
	new OpisKlas_bohaterowie=menu_create("Opisy Klas New Diablo Mod","OpisKlas_bohaterowie_Handle");

	menu_additem(OpisKlas_bohaterowie,"Mag");//item=0
	menu_additem(OpisKlas_bohaterowie,"Mnich");//item=1
	menu_additem(OpisKlas_bohaterowie,"Paladyn");//item=2
	menu_additem(OpisKlas_bohaterowie,"Zabojca");//item=3
	menu_additem(OpisKlas_bohaterowie,"Nekromanta");//item=4
	menu_additem(OpisKlas_bohaterowie,"Barbarzynca");//item=5
	menu_additem(OpisKlas_bohaterowie,"Ninja");//item=6
	menu_additem(OpisKlas_bohaterowie,"Amazonka");//item=7
//	menu_additem(OpisKlas_bohaterowie,"Tyrael [REMIUM]");//item=7
	
	menu_display(id, OpisKlas_bohaterowie,0);
	return PLUGIN_HANDLED;
}
public OpisKlas_bohaterowie_Handle(id, menu, item){
		switch(item){
			case 0:{
				OpisKlas_bohaterowie_mag(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 1:{
				OpisKlas_bohaterowie_mnich(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 2:{
				OpisKlas_bohaterowie_paladyn(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 3:{
				OpisKlas_bohaterowie_zabojca(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 4:{
				OpisKlas_bohaterowie_nekromanta(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 5:{
				OpisKlas_bohaterowie_barba(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 6:{
				OpisKlas_bohaterowie_ninja(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 7:{
				OpisKlas_bohaterowie_amazonka(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
/*			case 8:{
				OpisKlas_bohaterowie_tyrael(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}*/
		}
		menu_destroy(menu);
		return PLUGIN_HANDLED;
}
public OpisKlas_potwory(id, menu, item)
{
	new OpisKlas_potwory=menu_create("Opisy Klas New Diablo Mod","OpisKlas_potwory_Handle");

	menu_additem(OpisKlas_potwory,"Imp");//item=0
	menu_additem(OpisKlas_potwory,"Cien");//item=1
	menu_additem(OpisKlas_potwory,"GromoWladny");//item=4
	menu_additem(OpisKlas_potwory,"Duriel");//item=5
	menu_additem(OpisKlas_potwory,"Szaman");//item=6
	menu_additem(OpisKlas_potwory,"Khazra");//item=7
	
	menu_display(id, OpisKlas_potwory,0);
	return PLUGIN_HANDLED;
}
public OpisKlas_potwory_Handle(id, menu, item){
		switch(item){
			case 0:{
				OpisKlas_potwory_imp(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 1:{
				OpisKlas_potwory_cien(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 2:{
				OpisKlas_potwory_wladcagromow(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 3:{
				OpisKlas_potwory_duriel(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 4:{
				OpisKlas_potwory_szaman(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 5:{
				OpisKlas_potwory_khazra(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
		}
		menu_destroy(menu);
		return PLUGIN_HANDLED;
}
public OpisKlas_demony(id, menu, item)
{
	new OpisKlas_demony=menu_create("Opisy Klas New Diablo Mod","OpisKlas_demony_Handle");

	
	menu_additem(OpisKlas_demony,"Baal");//item=1
	menu_additem(OpisKlas_demony,"Diablo");//item=3
	menu_additem(OpisKlas_demony,"Andariel");//item=0
	menu_additem(OpisKlas_demony,"Mefisto");//item=2
	menu_additem(OpisKlas_demony,"Izual");//item=6
	menu_additem(OpisKlas_demony,"Nihlathak");//item=7
	menu_additem(OpisKlas_demony,"GrisWold [REMIUM]");//item=7
	menu_additem(OpisKlas_demony,"Kowal Dusz [REMIUM]");//item=7
	
	menu_display(id, OpisKlas_demony,0);
	return PLUGIN_HANDLED;
}
public OpisKlas_demony_Handle(id, menu, item){
		switch(item){
			case 0:{
				OpisKlas_demony_baal(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 1:{
				OpisKlas_demony_diablo(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 2:{
				OpisKlas_demony_andariel(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 3:{
				OpisKlas_demony_mefisto(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 4:{
				OpisKlas_demony_izual(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 5:{
				OpisKlas_demony_duriel(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 6:{
				OpisKlas_demony_griswold(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
			case 7:{
				OpisKlas_demony_kowal(id)
				OpisKlasy(id, menu, item)
				return PLUGIN_CONTINUE;
			}
		}
		menu_destroy(menu);
		return PLUGIN_HANDLED;
}
	
public pomoc(id){
	new pomoc=menu_create("Pomoc New Diablo Mod","pomoc_Handle");
	
	menu_additem(pomoc,"Pomoc Ogolna");//item=0
	menu_additem(pomoc,"Artefakty");//item=1
	menu_additem(pomoc,"Gildie");//item=1
	menu_additem(pomoc,"Questy");//item=1
	menu_additem(pomoc,"Krysztaly");//item=1
	
	menu_display(id, pomoc,0);
	return PLUGIN_HANDLED;
}

public pomoc_Handle(id, menu, item){
	switch(item){
		case 0:{
			showpomoc(id)
			pomoc(id)
			return PLUGIN_CONTINUE;
		}
		case 1:{
			showpomoc_artefakty(id)
			pomoc(id)
			return PLUGIN_CONTINUE;
		}
		case 2:{
			showpomoc_gildie(id)
			pomoc(id)
			return PLUGIN_CONTINUE;
		}
		case 3:{
			showpomoc_questy(id)
			pomoc(id)
			return PLUGIN_CONTINUE;
		}
		case 4:{
			showpomoc_krysztaly(id)
			pomoc(id)
			return PLUGIN_CONTINUE;
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

//dodatkowe hp
public startaddhp(id)
{
	if(player_b_startaddhp[id] > 0)
		maksymalne_zdrowie_gracza[id] += player_b_startaddhp[id]
	if(g_hp[id] > 0)
		maksymalne_zdrowie_gracza[id] += maksymalne_zdrowie_gracza[id]*g_hp[id]*0.01
	if(get_user_flags(id) & ADMIN_LEVEL_H)
		maksymalne_zdrowie_gracza[id] += 15
	if(ile_wykonano[id]>=28)
		maksymalne_zdrowie_gracza[id] += 20
	else if(ile_wykonano[id]>=13)
		maksymalne_zdrowie_gracza[id] += 10
	set_user_health(id, maksymalne_zdrowie_gracza[id]);
	return PLUGIN_HANDLED
}

public Pomoc()
{
	new num = random_num(0,9)
	switch(num)
	{
		case 0: client_print(0, print_chat, "[NewDiabloMod] Aby zresetowac umiejetnosci napisz /reset");
		case 1: client_print(0, print_chat, "[NewDiabloMod] Aby zmienic klase napisz /klasa lub /k");
		case 3: client_print(0, print_chat, "[NewDiabloMod] Aby wyrzucic item napisz /drop. Aby wyrzucic artefakt napisz /dropartefakt");
		case 4: client_print(0, print_chat, "[NewDiabloMod] Wpisz /menu aby otworzyc menu w ktorym mozesz zarzadzac Gildia, itemem, artefaktami oraz zapisanym haslem");
		case 5: client_print(0, print_chat, "[NewDiabloMod] Aby zobaczyc opis klas napisz /klasy.");
		case 6: client_print(0, print_chat, "[NewDiabloMod] Aby otworzyc Sklep napisz /sklep lub /rune");
		case 7: client_print(0, print_chat, "[NewDiabloMod] Wpisz /komendy aby zobaczyc liste przydatnyck komend.");
		case 8: client_print(0, print_chat, "[NewDiabloMod] Wpisz /pomoc aby uzyskac pomoc.");
		case 9: client_print(0, print_chat, "[NewDiabloMod] Wpisz /questy lub /q aby zaczac wykonywac zadanie!");
	}
	set_task(30.0, "Pomoc");
}

//przechodzenie przez sciany
public WylaczNoclip(id)
{
	if(!is_user_connected(id))
		return;
		
	set_pev(id, pev_movetype, MOVETYPE_WALK);
	
	new Float:origin[3];
	
	pev(id, pev_origin, origin);
	
	if (!is_hull_vacant2(origin, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id))
		user_silentkill(id);
}

stock bool:is_hull_vacant2(const Float:origin[3], hull,id) 
{
	static tr;
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true;
	
	return false;
}

public item_ghost(id)
{
	if (player_b_ghost[id] > 0 && is_user_alive(id) && !used_item[id])
	{
		set_pev(id, pev_movetype, MOVETYPE_NOCLIP);
		msg_bartime(id, player_b_ghost[id]);
		
		set_task(float(player_b_ghost[id]), "WylaczNoclip", id);
		used_item[id] = true;
	}
	else
	{
		hudmsg(id,2.0,"Przedmiot zostal uzyty!")
	}
}

public duch_ghost(id)
{
	if (player_class[id] == Duch && freeze_ended && is_user_alive(id))
	{
		new xd = floatround(halflife_time()-wait1[id])
		new czas = 20-xd
		if (halflife_time()-wait1[id] <= 20)
		{
			client_print(id, print_center, "Za %d sek mozesz uzyc mocy!", czas)
			return PLUGIN_CONTINUE;
		} 																
		else{
			set_pev(id, pev_movetype, MOVETYPE_NOCLIP);
			msg_bartime(id, 5);
		
			set_task(5.0, "WylaczNoclip", id);
			
			wait1[id]=floatround(halflife_time())
		}
	}
	return PLUGIN_HANDLED;
}

//niesmiertelnosc
public niesmiertelnoscon(id) {
        if(used_item[id]) {
                hudmsg(id, 2.0, "Niesmiertelnosci mozesz uzyc raz na runde!");
                return PLUGIN_CONTINUE;
        }
        set_user_godmode(id, 1);
        new Float:czas = player_b_godmode[id]+0.0;
        remove_task(id+TASK_GOD);
        set_task(czas, "niesmiertelnoscoff", id+TASK_GOD, "", 0, "a", 1);

        message_begin(MSG_ONE, gmsgBartimer, {0,0,0}, id);
        write_byte(player_b_godmode[id]);
        write_byte(0);
        message_end();
        used_item[id] = true;

        return PLUGIN_CONTINUE;
}

public niesmiertelnoscoff(id) {
        id-=TASK_GOD;

        if(is_user_connected(id)) {
                set_user_godmode(id, 0);

                message_begin(MSG_ONE, gmsgBartimer, {0,0,0}, id);
                write_byte(0);
                write_byte(0);
                message_end();
        }
}
//info na sayu
public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id))      return PLUGIN_CONTINUE;
	
	new szTmp[256],szTmp2[256];
	get_msg_arg_string(2,szTmp, charsmax( szTmp ) )
	
	new szPrefix[64]
	
	switch(get_pcvar_num(pCvarPrefixy)){
		case 1:{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]",Race[player_class[id]]);
		}
		case 2:{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%d]",player_lvl[id]);
		}
		case 3:{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s - %d]",Race[player_class[id]],player_lvl[id]);
		}
	}
	
	if(!equal(szTmp,"#Cstrike_Chat_All")){
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2)," ");
		add(szTmp2,charsmax(szTmp2),szTmp);
	}
	else{
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2,szTmp2);
	
	return PLUGIN_CONTINUE;
}

//Exp za asyste
public fwdamage(id, ent, attacker, Float:damage, damagebits)
{
	if(is_user_connected(attacker) && is_user_connected(id) && get_user_team(id) != get_user_team(attacker)){
		asysta_gracza[attacker][id] = true;
	}
}
public kiled()
{
	new attacker = read_data(1);
	new id = read_data(2);
	if(is_user_connected(attacker) && get_user_team(id) != get_user_team(attacker) && player_class[attacker])
	{
		for(new i=1; i<=MAX; i++)
		{
			if(asysta_gracza[i][id] && attacker != i && is_user_connected(i) && player_class[i])
			{
				Give_Xp(i,4)
				zloto_gracza[id] += 10
				ShowSyncHudMsg(i, SyncHudObj2, "Asysta!^n+4XP^n+10 zlota");
				asysta_gracza[i][id] = false;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public BoostStats(id,amount)
{
	player_strength[id]+=amount
	player_dextery[id]+=amount
	player_agility[id]+=amount
	player_intelligence[id]+=amount
	player_zloto[id]+=amount
	player_grawitacja[id]+=amount
	player_witalnosc[id]+=amount
	
}

public SubtractStats(id,amount)
{
	player_strength[id]-=amount
	player_dextery[id]-=amount
	player_agility[id]-=amount
	player_intelligence[id]-=amount
	player_zloto[id]-=amount
	player_grawitacja[id]-=amount
	player_witalnosc[id]-=amount
}

//totem dajacy kase
public item_kasa(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Kasa_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,215,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Kasa_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 200
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		

		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
								
			if (is_user_alive(pid))
				cs_set_user_money(pid, cs_get_user_money(pid)+random_num(150,250), 1)		
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
	set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 255); // r, g, b
	write_byte( 215 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}
//totem dajacy bron
public item_weapons(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Weapons_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,215,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Weapons_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 150
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		

		new jaka_bron = random_num(1,2)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
								
			if (is_user_alive(pid)) {
				if(!cs_get_user_hasprim (pid)) {
					if(jaka_bron==1) {
						give_item(pid, "weapon_m4a1")
						give_item(pid,"ammo_556nato") 
						give_item(pid,"ammo_556nato") 
						give_item(pid,"ammo_556nato") 
					}
					else {
						give_item(pid, "weapon_ak47")
						give_item(pid,"ammo_762nato") 
						give_item(pid,"ammo_762nato") 
						give_item(pid,"ammo_762nato") 
					}

				}
			}
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
	set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 255); // r, g, b
	write_byte( 215 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}

//hook
public item_hook(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Haku mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE	
	}
	
	new target = Find_Best_Angle(id,1000.0,false)
	
	if (!is_valid_ent(target))
	{
		hudmsg(id,2.0,"Obiekt jest poza zasiegiem.")
		return PLUGIN_CONTINUE
	}
	
	AddFlag(id,Flag_Hooking)
	
	set_user_gravity(target,0.0)
	set_task(0.1,"hook_prethink",id+TASK_HOOK,"",0,"b")
	hooked[id] = target
	hook_prethink(id+TASK_HOOK)
	emit_sound(id,CHAN_VOICE,"weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	used_item[id] = true	
	return PLUGIN_HANDLED
	
}

public hook_prethink(id)
{
	id -= TASK_HOOK
	if(!is_user_alive(id) || !is_user_alive(hooked[id])) 
	{
		RemoveFlag(id,Flag_Hooking)
		return PLUGIN_HANDLED
	}
	if (get_user_button(id) & ~IN_USE)
	{
		RemoveFlag(id,Flag_Hooking)
		return PLUGIN_HANDLED	
	}
	if(!HasFlag(id,Flag_Hooking))
	{
		if (is_user_alive(hooked[id]))
			set_user_gravity(id,1.0)
		remove_task(id+TASK_HOOK)
		return PLUGIN_HANDLED
	}
	
	//Get Id's origin
	static origin1[3]
	get_user_origin(id,origin1)
	
	static origin2[3]
	get_user_origin(hooked[id],origin2)
	
	//Create blue beam
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)		//TE_BEAMENTPOINT
	write_short(id)		// start entity
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2])
	write_short(sprite_line)
	write_byte(1)		// framestart
	write_byte(1)		// framerate
	write_byte(2)		// life in 0.1's
	write_byte(5)		// width
	write_byte(0)		// noise
	write_byte(0)		// red
	write_byte(0)		// green
	write_byte(255)		// blue
	write_byte(200)		// brightness
	write_byte(0)		// speed
	message_end()
	
	//Calculate Velocity
	new Float:velocity[3]
	velocity[0] = (float(origin1[0]) - float(origin2[0])) * 3.0
	velocity[1] = (float(origin1[1]) - float(origin2[1])) * 3.0
	velocity[2] = (float(origin1[2]) - float(origin2[2])) * 3.0
	
	new Float:dy
	dy = velocity[0]*velocity[0] + velocity[1]*velocity[1] + velocity[2]*velocity[2]
	
	new Float:dx
	dx = (4+player_intelligence[id]/2) * 120.0 / floatsqroot(dy)
	
	velocity[0] *= dx
	velocity[1] *= dx
	velocity[2] *= dx
	
	set_pev(hooked[id],pev_velocity,velocity)
	
	return PLUGIN_CONTINUE
}

//flash totem
public Flesh(id){
	Display_Fade(id,1<<14,1<<14 ,1<<16,255,155,50,230)
}
public item_fleshuj(id)
{
	if (used_item[id])
	{
		hudmsg(id,2.0,"Totemu mozesz uzyc raz na runde!")
		return PLUGIN_CONTINUE
	}
	
	used_item[id] = true
	
	new origin[3]
	pev(id,pev_origin,origin)
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Fleshuj_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + 15 + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "addons/amxmodx/diablo/totem_heal.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,255,250, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE	
}

public Effect_Fleshuj_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)		

		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
			continue
			
			if (is_user_alive(pid)){
				client_cmd(pid, "fleszuj")
				set_task(15.0, "off_fleshuj", pid)
			}			
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
	set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
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
	write_byte( 255 ); // r, g, b
	write_byte( 250 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	
	return PLUGIN_CONTINUE
	
}

public off_fleshuj(pid){
	set_user_maxspeed(pid, 270.0)
}

//windwalk
public item_windwalk(id)
{
	//First time this round
	if (player_b_usingwind[id] == 0)
	{
		new szId[10]
		num_to_str(id,szId,9)
		player_b_usingwind[id] = 1
		
		set_renderchange(id)
		
		engclient_cmd(id,"weapon_knife") 
		on_knife[id]=1
		set_speedchange(id)
		
		new Float:val = player_b_windwalk[id] + 0.0
		set_task(val,"resetwindwalk",0,szId,32) 
		
		message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
		write_byte( player_b_windwalk[id]) 
		write_byte( 0 ) 
		message_end() 
	}
	
	//Disable again
	else if (player_b_usingwind[id] == 1)
	{
		player_b_usingwind[id] = 2
		
		set_speedchange(id)
		
		set_user_maxspeed(id,270.0)
		message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
		write_byte( 0) 
		write_byte( 0 ) 
		message_end() 
	}
	
	//Already used
	else if (player_b_usingwind[id] == 2)
	{
		set_hudmessage(220, 30, 30, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		show_hudmessage(id, "Ten przedmiot mozesz uzyc raz na runde!") 
	}
	
}

public resetwindwalk(szId[])
{
	new id = str_to_num(szId)
	if (id < 0 || id > MAX)
	{
		log_amx("Error in resetwindwalk, id: %i out of bounds", id)
	}
	
	if (player_b_usingwind[id] == 1)
	{
		player_b_usingwind[id] = 2
		
		set_renderchange(id)
		
		set_user_maxspeed(id,270.0)
		message_begin( MSG_ONE, gmsgBartimer, {0,0,0}, id ) 
		write_byte( 0) 
		write_byte( 0 ) 
		message_end() 
	}
	
}

/* ==================================================================================================== */

public Prethink_usingwind(id)
{
	
	if( get_user_button(id) & IN_ATTACK && is_user_alive(id))
	{
		new buttons = pev(id,pev_button)
		set_pev(id,pev_button,(buttons & ~IN_ATTACK));
		return FMRES_HANDLED;	
	}
	
	if( get_user_button(id) & IN_ATTACK2 && is_user_alive(id))
	{
		new buttons = pev(id,pev_button)
		set_pev(id,pev_button,(buttons & ~IN_ATTACK2));
		return FMRES_HANDLED;	
	}
	
	return PLUGIN_CONTINUE
}

public showpomoc(id)
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Ogolne info<br></center><br></td></table><br>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><b>Podstawowa czescia gry jest realizowanie celow mapy oraz zabijanie rywali. Za to otrzymujemy punkty doswiadczenia poprzez ktore zdobywamy coraz wyzszy poziom. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Za kazdy zdobyty poziom otrzymujemy 2 punkty umiejetnosci ktore mozemy rozdac w statystyki (postep /czary) podczas rozgrywki mozemy takze zdobyc itemy (100%% szans) oraz artefakty (1%% szans) przy zabojstwie. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Itemy oraz artefakty daja nam dodatkowe umiejetnosci. Itemy sa uszkadzane przy kazdym strzale, natomiast artefakty mamy na okreslony czas. <br> Wpisz /komandy, aby uzyskac liste przydatnych komend<br></font></td></table></center><br>")
	formatex(header,sizeof header - 1,"pomoc")
	
	show_motd(id,motd,header)	
}
public showpomoc_artefakty(id)
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Informacje o Artefaktach<br></center><br></font></td></table><br>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><b>Artefakty sa to przedmioty dajace nam dodatkowe umiejetnosci. Mamy 1%% szans aby je zdobyc (3%% gdy jestesmy Paladynem). ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Otrzyujemy je na okreslony czas i nie sa uszkadzane od uderzen. Artefaktu moga byc ulepszane za pomoca krysztalow. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"<br>Wpisz /menu oraz wybierz 6 opcje, aby wejsc w menu artefaktu<br>Komendy: /artefakt lub /art - info o posiadanym artefakcie, /dropartefakt - wyrzuca posiadany artefakt<br></font></td></table></center>")
	formatex(header,sizeof header - 1,"pomoc")
	
	show_motd(id,motd,header)	
}

public showpomoc_gildie(id)
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Informacje o Gildii<br></center><br></font></td></table><br>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><b>Gildiie to ugrupowania, ktore daja rozne bonusy jej czlonkom np. redukcje obrazen, dodatkowe Hp oraz DMG, predkosc oraz dodatkowy exp za fraga. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Musisz miec min. 20 poziom aby zalozyc wlasna Gildie. Mozesz przekazywac swoj exp gildii aby zwiekszyc jej poziom. Do gildii dodawane jest takze 1/10 expa z twojego fraga (ale ty go nie tracisz). ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Po zdobyciu przez gildie odpowiedniego poziomu otrzymuje ona punkty. Zalozyciel gildii rozdaje te punkty w rozne statystyki. Statystyki te daja rozne bonusy wsyzstkim jej cylonkom (wymienione wyzej). ")
	len += formatex(motd[len],sizeof motd - 1 - len,"<br>Wpisz /menu oraz wybierz 7 opcje, aby wejsc w opcje Gildii<br><br></font></td></table></center>")
	formatex(header,sizeof header - 1,"pomoc")
	
	show_motd(id,motd,header)	
}

public showpomoc_questy(id)
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Informacje o Questach<br></center><br></font></td></table><br>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><b>Questy nawiazuja do fabuly Diablo II. Wykonujac je otrzymujemy nagrody. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Jedna z nagrod jest mana, za ktora w sklepie mozemy kupic odpornosci na wrogie moce. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"<br>Wpisz /questy lub /q aby zaczac wykonywac zadanie<br></font></td></table></center>")
	formatex(header,sizeof header - 1,"pomoc")
	
	show_motd(id,motd,header)	
}
public showpomoc_krysztaly(id)
{
	static motd[1050],header[100],len
	len = 0
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><b><font color=white><br><center>Informacje o Krysztalach<br></center><br></font></td></table><br>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<table bordercolor=3366FF width=700 border=1 cellpadding=4 cellspacing=8>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<td><font color=white><b>Krysztaly jest to waluta niezbedna do ulepszania artefaktow oraz zozwoju Gildii. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"Dzieki nim mozemy ulepszyc lub wydluzyc zywotnosc naszego artefaktu. W opcjach gildii pozwala nam ona zresetowac punkty statystyki oraz odblokowac potezna statystyke gildyjna, ktora daje nam 25%% expa wiecej za kazdego fraga. ")
	len += formatex(motd[len],sizeof motd - 1 - len,"<br>Masz 5%% szans na znalezienie krysztalu przy martwym wrogu<br><br></font></td></table></center>")
	formatex(header,sizeof header - 1,"pomoc")
	
	show_motd(id,motd,header)	
}

public OpisKlas_bohaterowie_mag(id)
	showitem2(id,"Czarodziejka","<br>- Na start 110 Hp<br>- Jego latarka odkrywa Ninje<br>- 5% szans na oslepienie wroga.<br>- Posiada magiczne kule (2 na start, kolejne co 25 pk. inteligencji) (zadaja 65 + inteligencja obrazen)(uzycie - T)<br>Moc nozowa: Zyskuje dodatkowe magiczne kule<br>","Brak")
public OpisKlas_bohaterowie_mnich(id)
	showitem2(id,"Mnich","<br>- Na start 120 Hp<br>- 2 blyskawice (kazda zadaje 65 + inteligencja obrazen)(uzycie T)<br>- Wbudowana regeneracja 5 Hp co 3 sekundy<br>- Dostaje 20% wiecej expa<br>- Moc nozowa: Przywracasz 20 Hp sobie oraz wszystkim zywym sojusznikom<br>","Brak")
public OpisKlas_bohaterowie_paladyn(id)
	showitem2(id,"Paladyn","<br>- Na start 130 Hp<br>- Moze wykonywac LongJump'y (6 na start, kolejne co 25 pkt. inteligencji)<br>- Posiada platynowa zbroje (1/6 szansy na zatrzymanie wrogiego pocisku)<br>- Moc nozowa: Magiczne pociski (zawsze trafiaja w glowe)<br>","Brak")
public OpisKlas_bohaterowie_zabojca(id)
	showitem2(id,"Zabojca","<br>- Na start 150 Hp<br>- 2 skoki w powietrzu<br>- Cicho biega<br>- +30 do szybkosci<br>- Atakujac wroga od tylu zadajesz dodatkowe 20 pkt. obrazen<br>- Moc nozowa: Stajesz sie niewidzialny dopoki nie zmienisz broni<br>","Brak")
public OpisKlas_bohaterowie_nekromanta(id)
	showitem2(id,"Nekromanta","<br>- Na start 110 Hp<br>- Moze wskrzeszac umarlych (dostaje doswiadczenie za kazdego wskrzeszonego)<br>- 1/3 szansy na odrodzenie sie po smierci<br>- Wysysa 4 Hp przy kazdym strzale<br>- Moc nozowa: Ulecza sobie 25 + inteligencja/5 Hp<br>","Brak")
public OpisKlas_bohaterowie_barba(id)
	showitem2(id,"Barbarzynca","<br>- Na start 125 Hp<br>- Zabijajac wroga dostaje 20 Hp, 50 Armor'u i odnawia mu sie magazynek.<br>- Po smierci wybucha w pomieniu zadajac 40 pkt. obrazen kazdemu w promieniu 100 jednostek<br>- Moc nozowa: Magiczny pancerz (blokuje wrogie pociski)<br>","Brak")
public OpisKlas_bohaterowie_ninja(id)
	showitem2(id,"Ninja","<br>- Na start 175 Hp<br>- Posiada tylko noz, slabo widoczny<br>- Wyzej skacze<br>- +40 do szybkosci<br>- 8 nozy do rzucania (uzycie - R)<br>- Na nozu zwieksza swoja szybkosc<br>","Brak")
public OpisKlas_bohaterowie_amazonka(id)
	showitem2(id,"Lowca","<br>- Na start 140 Hp<br>- Moze uzywac kuszy (uzycie - noz i R)<br>- Moze zastawiac pulapki z granatow<br>- Nie slychac jego krokow<br>- Moc nozowa: Wzmacnia kusze (dodatkowe 20 pkt. obrazen) oraz dostaje He<br>","Brak")
public OpisKlas_bohaterowie_tyrael(id)
	showitem2(id,"Tyrael","<br>[KLASA PREMIUM]<br>- Aby ja kupic odwiedz sklep.cs-fifka.pl<br>- Na start 130 Hp<br>- Za zabojstwo odnawia mu sie magazynek oraz 20 Hp<br>- 2 skoki w powietrzu<br>- 1/5 szansy na porazenie wroga blyskawica, ktora zadaje 20 + inteligencja/5 obrazen<br>- Redukuje 10% otrzymanych obrazen<br>- Na nozu losuje darmowy item<br>","Brak")
public OpisKlas_potwory_imp(id)
	showitem2(id,"Imp","<br>- Na start 120 Hp<br>- Moze teleportowac sie za pomoca noza (uzycie PPM co 3 sek.)<br>- Widocznosc zredukowana do 120<br>- 7% szans na zmiane broni przeciwnika na noz<br>- +25 do szybkosci<br>- Moz nozowa: Zwieksza swoja predkosc<br>","Brak")
public OpisKlas_potwory_cien(id)
	showitem2(id,"Cien","<br>- Na start 110 Hp<br>- 2 skoki w powietrzu<br>- Na nozu widocznosc zredukowana do 40<br>- Nie slychac jego krokow<br>- Moc nozowa: Jego nastepny atak zada 140% podstawowych obrazen<br>","Brak")
public OpisKlas_potwory_szkielet(id)
	showitem2(id,"Duriel","<br>- Na start 115 Hp<br>- Za zabojstwo 30Hp<br>- Regeneruje 10 Hp co 3 sek<br>- 1/3 szans na zrespienie sie po smierci<br>- 5% szans na zatrzymanie wrogiego pocisku<br>- Moc nozowa: Laduje pociski-korzenie, ktore unieruchamiaja wroga<br>","Brak")
public OpisKlas_potwory_wladcagromow(id)
	showitem2(id,"Duch","<br>- Na start 110 Hp<br>- Widocznosc zredukowana do 85<br>- Mozesz uzyc ucieczki (przenosi Cie na respa oraz regeneruje cale Hp)<br>- Moc nozowa: Stajesz sie niewidzialny dopoki nie zmienisz broni<br>","Brak")
public OpisKlas_potwory_duriel(id)
	showitem2(id,"Duriel","<br>- Na start 120 Hp<br>- Wyglada jak przeciwnik<br>- Mozesz aktywowac inferno, ktore podpala wrogow w okolicy<br>- Moc nozowa: Laduje pociski-korzenie, ktore unieruchamiaja wroga<br>","Brak")
public OpisKlas_potwory_szaman(id)
	showitem2(id,"Szaman","<br>- Na start 120 Hp<br>- Co runde dostaje wszystkie granaty<br>- 20% szans na natychmiastowe zabicie z He<br>- Regeneruje sobie 10 Hp co 3 sek<br>- 2 skoki w powietrzu<br>- 1 na runde moze postawic totem leczacy<br>- Na nozu regeneruje sobie Hp<br>","Brak")
public OpisKlas_potwory_khazra(id)
	showitem2(id,"Khazra","<br>- Na start 110 Hp<br>- Wyglada jak przeciwnik<br>- Wysysa 4 hp za kazdy strzal we wroga<br>- Odporny na: Archy, falszywe paki, wybuchy po smierci oraz natychmiastowe zabiecie granatem<br>- Na nozu dodatkowe blyskawice<br>","Brak")
public OpisKlas_demony_andariel(id)
	showitem2(id,"Andariel","<br>- Na start 115 Hp<br>- Potrafi rzucac nicia do szybkiego przemieszczania sie (uzycie T)<br>- Jej ataki zatruwaja cel (zadaja dodatkowe 7 DMG co sek. przed 5 sek.)<br>- Nie traci Hp przy upadku<br>","Brak")
public OpisKlas_demony_baal(id)
	showitem2(id,"Baal","<br>- Na start 110 Hp<br>- Zadaje prawdziwe obrazenia tzn. omija redukcje obrazen ze zrecznosci ofiary oraz bonusy z itemow, sklepu, questow i artefaktow<br>- 2 blyskawice (kazda zadaje 75 + inteligencja obrazen)(uzycie T)<br>- Na nozu otrzymuje dodatkowe blyskawice<br>","Brak")
public OpisKlas_demony_mefisto(id)
	showitem2(id,"Mefisto","<br>- Na start 125 Hp<br>- Zmiejszona grawitacja<br>- 2 skoki w powietrzu<br>- Moze uzyc kuli energetycznej, ktora kaleczy i unieruchamia wrogow na swej trasie (uzycie - T) <br>- Na nozu otrzymuje dodatkowe LongJumpy<br>","Brak")
public OpisKlas_demony_diablo(id)
	showitem2(id,"Diablo","<br>- Na start 120 Hp<br>- Posiada zoom do broni (uzycie PPM)<br>- Nie slychac jego krokow<br>- Co runde 200 Armoru<br>- 1/5 szansy na porazenie wroga blyskawica, ktora zadaje 25 + inteligencja/5 obrazen<br>- Na nozu losuje darmowy item<br>","Brak")
public OpisKlas_demony_izual(id)
	showitem2(id,"Izual","<br>- Na start 110 Hp<br>- Regeneruje 20 Hp za zabicie wgora<br>- 4 miny(uzycie - v)<br>- Raz na runde moze uzyc ucieczki, ktora przenosi go na respa i regeneruje mu cale Hp (uzycie - T)<br>- Moc nozowa: Zyskuje dodatkowe miny","Brak")
public OpisKlas_demony_duriel(id)
	showitem2(id,"Nihlathak","<br>- Na start 115 Hp<br>- 10% szans na unieruchowmienie wroga<br>- +40 do szybkosci<br>- Moze cisnac kula, ktora steruje, po zderzeniu z celem zadaje 40 + inteligencja obrazen (uzycie -T)<br>- Na nozu otrzymuje pakiet granatow<br>","Brak")
public OpisKlas_demony_griswold(id)
	showitem2(id,"Griswold","<br>[KLASA PREMIUM]<br>- Aby ja kupic odwiedz sklep.cs-fifka.pl<br>- Na start 120 Hp<br>- Regeneruje 10 Hp co 3 sek.<br>- Odporny na: Archy, falszywe paki, wybuchy po smierci oraz natychmiastowe zabiecie granatem<br>- Wysysa 3 Hp za kazdy strzal w przeciwnika<br>- Moze uzyc kuli energetycznej, ktora kaleczy i unieruchamia wroga (uzycie - T)<br>- Na nozu pancerz odbijajacy pociski<br>","Brak")
public OpisKlas_demony_kowal(id)
	showitem2(id,"Kowal Dusz","<br>[KLASA PREMIUM]<br>- Aby ja kupic odwiedz sklep.cs-fifka.pl<br>- Na start 120 Hp<br>- Za zabojstwo 20 Hp<br>- Na nozu widocznosc zredukowana do 40 oraz teleportacja(PPM)<br>- Raz na runde moze uzyc ucieczki, ktora przenosi go na respa i regeneruje mu cale Hp (uzycie - T)<br>- Na nozu losuje darmowy item<br>","Brak")
	
	
/* MOCE:
- Odporny na itemy 1/x z broni<br>
- Odporna na: Archy, falszywe paki, wybuchy po smierci oraz natychmiastowe zabiecie granatem<br>



*/
	
public plugin_end()
{
	//Close the vault when the plugin ends (map change\server shutdown\restart)
	for(new id; id <= 32; id++) {
		zapis_gildia(id,0)
		zapisz_aktualny_quest(id)
	}
	nvault_close(g_gildia)
	nvault_close(vault_questy2)
}