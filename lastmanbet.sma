#define PLUGINNAME	"Obstawianie"
#define VERSION		"0.9.4"
#define AUTHOR		"JGHG"
#define PREFIX "LMB"
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>

// Naprawiona wersja Last Man Bets by Mrozu, edit umadBRO?

// ---------- Adjust below settings to your liking ---------------------------------------
//#define DEBUGMODE				// remove this comment to compile in debugmode
#define IWANTPRIZES				// comment this if you don't want prizes
#define XTRA_HEALTHBOOST		40 // how much extra health a health boost prize should give
// When you win money over $16000, the plugin automatically "buys" you prizes for that money until that money is all used up.
// You can change these values. Ie by default an extra life costs 1000, extra health 100 and armour 10. The plugin first tries to buy you as many extra lives
// it can (ie until less than $1000 remains), then goes on to buy extra health, and then extra armour. With that said, make sure extra life is still the most expensive
// and extra armour the cheapest prize, or you will run into trouble.
#define PRIZEPRICE_EXTRALIFE	10000
#define PRIZEPRICE_EXTRAHEALTH	5000
#define PRIZEPRICE_EXTRAARMOUR	3000

#define HUDCHANNEL_T			1 // Hud channels. You probably don't need to change these, but you can if you find that some of hud-displaying plugins are interfered
#define HUDCHANNEL_CT			3 // by the red/blue messages telling how much each player was bet on.
#define HUDMESSAGE_HOLDTIME		25.0 // For how many seconds (after last placed bet) should the red/blue messages stay onscreen. Must be a float (end with a decimal) value.



// __________________Bot settings here (you don't need to touch these)__________________
// A bot can be a "gambler", betting on the person with the lowest sum of HP and armour, else he's playing it "safe". To become a gambler
// each bot needs to get a random value below a certain (individual) value. This value in turn is gotten by choosing a random value between BOTGAMBLERMIN and BOTGAMBLERMAX.
// Ie the bot gamble value could end up as 0.3, and then it's a 30% chance that the bot will bet on the weaker remaining player.
#define BOTGAMBLERMAX			0.4
#define BOTGAMBLERMIN			0.1
// A random float from 0.0 to 1.0 decides how much $ a bot will bet. A setting will be used if the random float ends at least this value.
#define RATIO_HIGH				0.9
#define RATIO_MEDIUM			0.6
// Depending on ratio, this is how much of the bot's current money the bot will bet. MAXBET_LOW can at most let the bot set about one third of his total money sum.
#define MAXBET_LOW				0.3 // about one third here
#define MAXBET_MEDIUM			0.5 // half money maximum here
#define MAXBET_HIGH				1.0 // bot could bet all of his money here
// ---------- Adjust above settings to your liking ---------------------------------------

#define MENUBUTTON1				(1<<0)
#define MENUBUTTON2				(1<<1)
#define MENUBUTTON3				(1<<2)
#define MENUBUTTON4				(1<<3)
#define MENUBUTTON5				(1<<4)
#define MENUBUTTON6				(1<<5)
#define MENUBUTTON7				(1<<6)
#define MENUBUTTON8				(1<<7)
#define MENUBUTTON9				(1<<8)
#define MENUBUTTON0				(1<<9)
#define MENUSELECT1				0
#define MENUSELECT2				1
#define MENUSELECT3				2
#define MENUSELECT4				3
#define MENUSELECT5				4
#define MENUSELECT6				5
#define MENUSELECT7				6
#define MENUSELECT8				7
#define MENUSELECT9				8
#define MENUSELECT0				9
#define TEAM_T					1
#define TEAM_CT					2

// Time in seconds (must be float) from 1vs1 situation appears until bettings start - if the player that died when it was 2vs1 has respawned, the betting will be called off.
#define INITBETTINGSTIME		1.0
// Time in seconds (must be float) from a player dies until respawn, if having any extra lives. If round ended during this time, respawn will be called off. Must be lower than INITBETTINGSTIME.
#define RESPAWNTIME				0.5

#define TASKID_RESPAWN			100 // just some value. don't change
#define TASKID_BETTINGS			200 // don't change
#define TASKID_BETTIMER			300 // don't change
#define TASKID_BETTIMERDISPLAY	400	// don't change

// Hud settings
#define TRED					200
#define TGREEN					0
#define TBLUE					55
#define TX						0.25

#define CTRED					0
#define CTGREEN					55
#define CTBLUE					200
#define CTX						0.75

#define Y						0.35
#define EFFECTS					0
#define FXTIME					5.0
#define FADEINTIME				0.30
#define FADEOUTTIME				0.75

// Global vars below
//new const CT[] = "CT"
//new const T[] = "TERRORIST"
new const OVERRIDEPREVIOUSMENU[] = "lastmanbets_overridemenus"
new const CVAR_DEFAULTBET[] = "lastmanbets_defaultbet"
new const CVAR_BETTIME[] = "lastmanbets_bettime"
new const VAULTKEY_POT[] = "lastmanbets_pot"
new g_names[3][33]
new g_betperson[33]
new g_betamount[33]
new g_t
new g_ct
new bool:g_betting = false
new g_pot = 0
new g_betmenu
new bool:g_round
enum BETSETTING {BET_LOW, BET_MEDIUM, BET_HIGH}
#if defined IWANTPRIZES
new g_extralives[33] = {0, ...}
new g_extrahealth[33] = {0, ...}
new g_extraarmour[33] = {0, ...}
new bool:g_freezenewround[33] = {false, ...} // to prevent from giving prizes several times on newround (could happen ~2 times for some reason)
#endif
// Global vars above

public death_event() {
#if defined IWANTPRIZES
	new victim = read_data(2) // victim needed by IWANTPRIZES and DEBUGMODE, else not
	//client_print(0, print_chat, "death_event, victim: %d, g_round: %d, g_extralives[victim]: %d", victim, g_round, g_extralives[victim])
	if (g_extralives[victim]) {
		new team = get_user_team(victim)
		if (team == TEAM_T || team == TEAM_CT) {
			new idd[1]
			idd[0] = victim
			set_task(RESPAWNTIME, "respawn", TASKID_RESPAWN + victim, idd, 1)

		// Return here. If victim died and can respawn, this means a 1vs1 has not happened yet. Victim will not respawn if round ended - and if round ended, bet shouldn't start anyway.
		//client_print(0, print_chat, "death_event, end 1")
			return PLUGIN_CONTINUE
		}
	}
#endif // defined IWANTPRIZES

	if (!g_round) {
		//client_print(0, print_chat, "death_event, end 2")
		return PLUGIN_CONTINUE
	}

	new cts[32], ts[32], ctsnum = 0, tsnum = 0
	new const MAXPLAYERS = get_maxplayers()

	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || !is_user_alive(i))
			continue

		switch (cs_get_user_team(i)) {
			case TEAM_T: ts[tsnum++] = i
			case TEAM_CT: cts[ctsnum++] = i
			default: {
				// A user that is not alive but not on T _or_ CT, who is he anyway?? :-)
				return PLUGIN_CONTINUE
			}
		}

		if (tsnum > 1 || ctsnum > 1) {
			//client_print(0, print_chat, "Deathevent ends in loop, not 1vs1: CT: %d, T: %d", ctsnum, tsnum)
			return PLUGIN_CONTINUE
		}

	}
	// (These two get_players had problems in earlier versions, they are now replaced by manual code finding players)
	//get_players(cts, ctsnum, "ae", CT) // match alive and team
	//get_players(ts, tsnum, "ae", T) // match alive and team

	if (ctsnum != 1 || tsnum != 1) {
		//client_print(0, print_chat, "death_event, end 3, CT: %d, T: %d", ctsnum, tsnum)
		return PLUGIN_CONTINUE
	}

	get_user_name(ts[0], g_names[TEAM_T], 32)
	get_user_name(cts[0], g_names[TEAM_CT], 32)

	g_t = ts[0]
	g_ct = cts[0]

#if defined DEBUGMODE
	new victimdebug = read_data(2) // victim needed by IWANTPRIZES and DEBUGMODE, else not
	new victimname[32]
	get_user_name(victimdebug, victimname, 31)
	log_amx("Obstawianie moze zacznie sie za %f sekund(jezeli %s juz zginal, albo runda sie skonczyla)", INITBETTINGSTIME, victimname)
#endif
	set_task(INITBETTINGSTIME, "initbettings", TASKID_BETTINGS)

	return PLUGIN_CONTINUE
}

displaybetshud() {
	//client_print(0, print_chat, "%s obstawil $%d na %s.", name, g_betamount[id], g_names[g_betperson[id]])
	new const MAXPLAYERS = get_maxplayers()

	// First calculate how much each player has been bet on.
	new betamounts[2] = {0, 0}, betcount[2] = {0, 0} // t, ct

	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) // no one can win money from a player that has disconnected, even though he bet...
		 || g_betperson[i] == 0) // this player didn't bet yet
			continue

		betamounts[g_betperson[i] - 1] += g_betamount[i] // -1 because person will be a team number, either 1 (t) or 2 (ct).
		betcount[g_betperson[i] - 1]++
	}

	const MESSAGESIZE = 511
	new tMessage[MESSAGESIZE + 1], ctMessage[MESSAGESIZE + 1]

	format(tMessage, MESSAGESIZE, "%s^n$%d z %d obstawionych", g_names[TEAM_T], betamounts[0], betcount[0])
	format(ctMessage, MESSAGESIZE, "%s^n$%d z %d obstawionych", g_names[TEAM_CT], betamounts[1], betcount[1])


	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || is_user_bot(i))
			continue

		// display hud stuff to this person
		set_hudmessage(TRED, TGREEN, TBLUE, TX, Y, EFFECTS, FXTIME, HUDMESSAGE_HOLDTIME, FADEINTIME, FADEOUTTIME, HUDCHANNEL_T)
		show_hudmessage(i, tMessage)

		set_hudmessage(CTRED, CTGREEN, CTBLUE, CTX, Y, EFFECTS, FXTIME, HUDMESSAGE_HOLDTIME, FADEINTIME, FADEOUTTIME, HUDCHANNEL_CT)
		show_hudmessage(i, ctMessage)
	}
}

#if defined IWANTPRIZES // keeping all prizes-only functions within this big block, don't forget to move fns out of it when they are used by nonprize compiles
public respawn(idd[1]) {
	new team = get_user_team(idd[0])
	if (team != TEAM_T && team != TEAM_CT)
		return

	// Call any bets off. If we have a respawner, a 1vs1 situation is impossible.

#if defined DEBUGMODE
	new name[32]
	get_user_name(idd[0], name, 31)
	log_amx("%s %s %s", name, g_round ? "respawn!" : "pojawisz sie ponownie, jezeli runda sie jeszcze nie skonczyla... nie pojawisz sie tym razem!", task_exists(TASKID_BETTINGS) ? "A betting was about to happen but will called off." : "A betting wasn't about to happen anyway, no action taken.")
#endif


	if (task_exists(TASKID_BETTINGS)) // probably not entirely necessary
		remove_task(TASKID_BETTINGS) // this should be necessary, though

	if (!g_round)
		return

	g_extralives[idd[0]]--
	spawn(idd[0])
	new name2[32]
	get_user_name(idd[0], name2, 31)
	client_print_color(0, idd[0], "^x04[%s] ^x01Gracz ^x03%s^x01 odrodzony, posiada jeszcze ^x04%d^x01 zyc!", PREFIX, name2, g_extralives[idd[0]]);
	//client_print(0, print_chat, "%s odrodzil sie, majac %d jeszcze li%s zyc extra!", name2, g_extralives[idd[0]], g_extralives[idd[0]] == 1 ? "fe" : "ves")
}

public client_connect(id) {
	resetprizes(id)

	return PLUGIN_CONTINUE
}

prize(id, moneyover16k) {
	new lives = 0, healths = 0, armours = 0, origmoney = moneyover16k

	while (moneyover16k >= PRIZEPRICE_EXTRALIFE) {
		g_extralives[id]++
		moneyover16k -= PRIZEPRICE_EXTRALIFE
		lives++
	}
	while (moneyover16k >= PRIZEPRICE_EXTRAHEALTH) {
		g_extrahealth[id]++
		moneyover16k -= PRIZEPRICE_EXTRAHEALTH
		healths++
	}
	while (moneyover16k >= PRIZEPRICE_EXTRAARMOUR) {
		g_extraarmour[id]++
		moneyover16k -= PRIZEPRICE_EXTRAARMOUR
		armours++
	}
	client_print_color(id, id, "^x04[%s] ^x01Jezeli wygrasz ^x04%d^x01$ okolo ^x04$16000^x01, wygrasz takze te nagrody: ^x04%d^x01 dodatkowe zycia, ^x04%d^x01 zwiekszenie zdrowia, ^x04%d^x01 dodatkowy atak i tym podobne!", PREFIX, origmoney, lives, healths, armours);
	//client_print(id, print_chat, "For winning $%d over $16000, you win these prizes: %d Xtra lives, %d health boosts, %d assault suits", origmoney, lives, healths, armours)
}

setprizes(id) {
	new bool:extrahealthused = false, bool:extraarmourused = false
	// Add extra health
	if (g_extrahealth[id] > 0) {
		g_extrahealth[id]--
		new idd[1]
		idd[0] = id
		set_task(0.5, "delayedhealthboost", 0, idd, 1)
		extrahealthused = true
	}

	// Add extra armour
	new userarmour = get_user_armor(id)
	if (g_extraarmour[id] > 0 && userarmour < 100) {
		g_extraarmour[id]--

		give_item(id, "item_assaultsuit")
		extraarmourused = true
	}

	if (g_extralives[id] + g_extrahealth[id] + g_extraarmour[id] != 0)
		client_print_color(id, id, "^x04[%s] ^x01Do wygrania: ^x04%d^x01 dodatkowe zycia, ^x04%d^x01 zwiekszenie zdrowia, ^x04%d^x01 dodatkowy atak!", PREFIX, g_extralives[id], g_extrahealth[id], extrahealthused ? " (1 wykorzystane)" : "", g_extraarmour[id], extraarmourused ? " (1 wykorzystane)" : "");
}

public delayedhealthboost(idd[1]) {
	set_user_health(idd[0], get_user_health(idd[0]) + XTRA_HEALTHBOOST)
}

remove_respawntasks() {
	for (new i = 1; i < 33; i++)
		remove_task(TASKID_RESPAWN + i)
}

public unsetfreeze(idd[1]) {
	g_freezenewround[idd[0]] = false
}

public restartgame_event() {
	for (new i = 1; i < 33; i++)
		resetprizes(i)

	return PLUGIN_CONTINUE
}

resetprizes(id) {
	g_extralives[id] = 0
	g_extrahealth[id] = 0
	g_extraarmour[id] = 0
	g_freezenewround[id] = false
}

#if defined DEBUGMODE
public giveprize(id, level, cid) {
	if (!cmd_access(id, level, cid, 4)) {
		return PLUGIN_HANDLED
	}

	new giveto, theprize, prizes
	new buffer[10]
	read_argv(1, buffer, 9)
	giveto = str_to_num(buffer)
	read_argv(2, buffer, 9)
	theprize = str_to_num(buffer)
	read_argv(3, buffer, 9)
	prizes = str_to_num(buffer)

	switch (theprize) {
		case 1: {
			g_extralives[giveto] += prizes
		}
		case 2: {
			g_extrahealth[giveto] += prizes
		}
		case 3: {
			g_extraarmour[giveto] += prizes
		}
		default: {
			console_print(id, "Tylko 1-3 dziala...")
			return PLUGIN_HANDLED
		}

	}

	console_print(id, "Podarowalismy %d przedmiotow typu %d do %d!", prizes, theprize, giveto)


	return PLUGIN_HANDLED
}

public giveprizeall(id, level, cid) {
	if (!cmd_access(id, level, cid, 3)) {
		return PLUGIN_HANDLED
	}

	new theprize, prizes
	new buffer[10]
	read_argv(1, buffer, 9)
	theprize = str_to_num(buffer)
	read_argv(2, buffer, 9)
	prizes = str_to_num(buffer)

	new const MAXCLIENTS = get_maxplayers()

	for (new i = 1; i <= MAXCLIENTS; i++) {
		if (!is_user_connected(i))
			continue
		switch (theprize) {
			case 1: {
				g_extralives[i] = prizes
			}
			case 2: {
				g_extrahealth[i] = prizes
			}
			case 3: {
				g_extraarmour[i] = prizes
			}
			default: {
				console_print(id, "Tylko 1-3 dziala...")
				return PLUGIN_HANDLED
			}
		}
	}

	console_print(id, "Ustawilismy %d przedmiotow typu %d dla wszystkich!", prizes, theprize)

	return PLUGIN_HANDLED
}
#endif // defined DEBUGMODE
#endif // defined IWANTPRIZES

public newround_event(id) {
#if defined IWANTPRIZES
	if (g_freezenewround[id])
		return PLUGIN_CONTINUE
	//log_amx("newround_event called for %d", id)

	g_freezenewround[id] = true

	new idd[1]
	idd[0] = id
	set_task(1.0, "unsetfreeze", 0, idd, 1)

	setprizes(id)
#endif // defined IWANTPRIZES

	if (!g_round)
		g_round = true

	return PLUGIN_CONTINUE
}

hudtimerstarter() {
	new timeend[1]
	timeend[0] = get_systime() + get_cvar_num(CVAR_BETTIME)
	hudtimerdisplay(timeend)
	set_task(1.0, "hudtimerdisplay", TASKID_BETTIMERDISPLAY, timeend, 1, "b")
}

public hudtimerdisplay(timeend[1]) {
	new const MAXPLAYERS = get_maxplayers()
	new secondsleft = timeend[0] - get_systime()
	new msg[64]

	if (secondsleft > 0) {
		msg = "Koniec obstawiania za %d sekund!"
		format(msg, 63, msg, secondsleft)
	}
	else
		msg = "Nie udalo Ci sie obstawic..."

	new usermenu, userkeys, bool:nooneisinmenu = true
	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || is_user_alive(i) || is_user_bot(i))
			continue
		else
			nooneisinmenu = false

		get_user_menu(i, usermenu, userkeys) // get user menu
		if (usermenu == g_betmenu) {
			// Display time left here
			client_print(i, print_center, msg)
		}
	}

	// End loops if no one is in menu...
	if (nooneisinmenu) {
		remove_task(TASKID_BETTIMER)
		remove_task(TASKID_BETTIMERDISPLAY)
	}
}

public initbettings() {
	if (!g_round) { // if round already ended, call bets off
#if defined DEBUGMODE
		log_amx("Obstawianie mialo sie rozpoczac, jednak runda sie zakonczyla, nie bedzie tym razem glosowania.")
#endif
		return
	}

	// Start timer here
	set_task(get_cvar_float(CVAR_BETTIME), "closebetmenu", TASKID_BETTIMER)
	hudtimerstarter()

	new const DEFAULTBET = get_cvar_num(CVAR_DEFAULTBET)
	g_betting = true

	for (new i = 1; i < 33; i++) // Reset votes
		g_betperson[i] = 0

	new bool:overridepreviousmenu, bool:bot, currentmenu, CsTeams:team, keys
	if (get_cvar_num(OVERRIDEPREVIOUSMENU))
		overridepreviousmenu = true
	else
		overridepreviousmenu = false

	new const MAXPLAYERS = get_maxplayers()
#if defined DEBUGMODE
	log_amx("Obstawiania sie rozpoczyna. Serwer popiera %d graczy.", MAXPLAYERS)
	new name[32]
#endif
	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || is_user_alive(i)) { // Online, dead players only
#if defined DEBUGMODE
			if (!is_user_connected(i)) {
				//log_amx("Gracz #%d nie polaczyl sie i nie bedzie mogl obstawic.", i)
			}
			else {
				get_user_name(i, name, 31)
				log_amx("Gracz #%d (%s) zyje i nie bedzie mogl obstawic.", i, name)
			}
#endif
			continue
		}

		bot = bool:is_user_bot(i)
		if (!bot && !overridepreviousmenu) {
			// If already in a menu, don't bother. This isn't that important...
			get_user_menu(i, currentmenu, keys) // currentmenu should be 0 when user is in no menu, only then it's ok to show a bet menu :-]
			if (currentmenu > 0) {
#if defined DEBUGMODE
				get_user_name(i, name, 31)
				log_amx("Gracz #%d (%s) aktualnie ma otwarte inne menu (%d) - Twoj %s cvar ustawiony jest, zeby nie pokazywac menu obstawiania osoba, ktore maja otwarte inne menu. (Bet menu ma id %d)", i, name, currentmenu, OVERRIDEPREVIOUSMENU, g_betmenu)
#endif
				continue
			}
		}

		// Must be on T or CT team
		team = cs_get_user_team(i)
		if (team != CS_TEAM_T && team != CS_TEAM_CT) {
#if defined DEBUGMODE
			get_user_name(i, name, 31)
			log_amx("Gracz #%d (%s) nie jest w druzynie 1 (T) albo 2 (CT). Gracz ten aktualnie jest w druzynie %d i nie moze obstawiac.", i, name, int:team)
#endif
			continue
		}

		// Must have at least DEFAULTBET dollars to participate...
		if (cs_get_user_money(i) < DEFAULTBET) {
#if defined DEBUGMODE
			get_user_name(i, name, 31)
			log_amx("Gracz #%d (%s) ma tylko $%d, wymagane jest $%d aby obstawic.", i, name, cs_get_user_money(i), DEFAULTBET)
#endif
			//client_print(i, print_chat, "Nie masz minimalnej stawki (pieniedzy): $%d, nie mozesz obstawiac.", DEFAULTBET)
			client_print_color(i, i, "^x04[%s] ^x01Nie posiadasz minimalnej stawki: ^x04%d^x01$, nie mozesz obstawiac!", PREFIX, DEFAULTBET);
			continue
		}

		g_betamount[i] = DEFAULTBET

		if (bot) {
			// Bots "bet"
			//client_print(0, print_chat, "%d bedzie bostawiac i jest botem!", deadplayers[i])
			new botid[1]
			botid[0] = i
			set_task(random_float(1.0, 5.0), "botbet", 0, botid, 1)
#if defined DEBUGMODE
			get_user_name(i, name, 31)
			log_amx("Gracz #%d (%s) jest botem i bedzie obstawiac...", i, name)
#endif
		}
		else {
			//client_print(deadplayers[i], print_chat, "rozpoczynamy obstawianie na Ciebie")
#if defined DEBUGMODE
			get_user_name(i, name, 31)
			log_amx("Gracz #%d (%s) jest normalnym graczem i menu obstawiania mu sie pokazalo, ma szanse na wygrana...", i, name)
#endif
			startbet(i)
		}
	}

	displaybetshud()
}

public botbet(botid[1]) {
	if (!g_betting || !is_user_connected(botid[0])) // bot may have been disconnected during the time...
		return PLUGIN_CONTINUE

	// Bot will bet.
	// Bot can bet any even $100 value... and should choose the player with most hp+armour, and possibly best frags/deaths ratio, and then it could turn all over to the other guy for
	// gambling purpose.

	// Gambling ratio could be set somewhere between 0.1 and 0.5...
	new const Float:GAMBLER_RATIO = random_float(BOTGAMBLERMIN, BOTGAMBLERMAX)
	new bool:gambler = false // this bot is not a gambler... yet
	if (random_float(0.0, 1.0) <= GAMBLER_RATIO)
		gambler = true // ok, this bot wants to be a gambler :-)

	new nongamblerschoice = getnongamblerschoice()

	new choice = gambler ? (nongamblerschoice == TEAM_T ? TEAM_CT : TEAM_T) : nongamblerschoice
	/*if (gambler) {
		if (nongamblerschoice == TEAM_T)
			choice = TEAM_CT
		else
			choice = TEAM_T
	}*/

	new money = cs_get_user_money(botid[0])
	money -= money % 100 // 553 - (553 % 100) would be 553 - (53) would be 500, ie even amount in hundreds...
	money = botbetmoney(money)
	if (money == 0) // Bot didn't bet this time...
		return PLUGIN_CONTINUE

	g_betamount[botid[0]] = money
	placebet(botid[0], choice)

	return PLUGIN_CONTINUE
}

// Decides how much money the will bot bet.
botbetmoney(money) {
	// Low (0.0 > 0.6), medium (0.6 > 0.9), high (0.9 > 1.0)
	// Low == max 30% of money
	// Medium == max 50% of money
	// High == max 100% of money

	new const Float:RATIO = random_float(0.0, 1.0)
	new BETSETTING:betSetting = BET_LOW
	if (RATIO >= RATIO_HIGH)
		betSetting = BET_HIGH
	else if (RATIO >= RATIO_MEDIUM)
		betSetting = BET_MEDIUM

	new Float:pctOfMoneyToBet
	switch (betSetting) {
		case BET_LOW: pctOfMoneyToBet = random_float(0.0, MAXBET_LOW) // MAXBET_LOW	0.3
		case BET_MEDIUM: pctOfMoneyToBet = random_float(0.0, MAXBET_MEDIUM) // MAXBET_MEDIUM	0.5
		//case BET_HIGH: pctOfMoneyToBet = random_float(0.0, MAXBET_HIGH) // MAXBET_HIGH	1.0
		default: pctOfMoneyToBet = random_float(0.0, MAXBET_HIGH) // MAXBET_HIGH	1.0
	}

	money = floatround(money * pctOfMoneyToBet)

	money -= money % 100 // to have equal 100s...

	return money
}

getnongamblerschoice() {
	new choice
	new t_hp = get_user_health(g_t), ct_hp = get_user_health(g_ct), t_armour = get_user_armor(g_t), ct_armour = get_user_armor(g_ct)
	if (t_hp + t_armour > ct_hp + ct_armour)
		choice = TEAM_T
	else if (t_hp + t_armour < ct_hp + ct_armour)
		choice = TEAM_CT
	else // They're equal
		choice = random_num(TEAM_T, TEAM_CT)

	return choice
}

startbet(id) {
	if (!g_betting) {
		client_print(id, print_center, "Twoja stawka jest zbyt niska!")
		return
	}

	new menuBody[512], flags = MENUBUTTON1|MENUBUTTON2|MENUBUTTON0, money = cs_get_user_money(id)

	new t_hp = get_user_health(g_t), ct_hp = get_user_health(g_ct), t_armour = get_user_armor(g_t), ct_armour = get_user_armor(g_ct)

	new len = format(menuBody, 511, "Pojedynek \y%s\w vs. \y%s\w! Obstaw! Kto wygra?^n^n\r1. \y%s \d(\wHP: \y%d\w, Pancerz: \y%d\d)^n\r2. \y%s \d(\wHP: \y%d\w, Pancerz: \y%d\d)\w^n^nStawka: $\y%d\w^n", g_names[TEAM_T], g_names[TEAM_CT], g_names[TEAM_T], t_hp, t_armour, g_names[TEAM_CT], ct_hp, ct_armour, g_betamount[id])

	if (g_pot > 0)
		len += format(menuBody[len], 511 - len, "^nAktualnie w puli jest $\y%d\w^n", g_pot)

	new const DEFAULTBET = get_cvar_num(CVAR_DEFAULTBET)

	// +1x
	if (money >= g_betamount[id] + DEFAULTBET) {
		flags |= MENUBUTTON3
		len += format(menuBody[len], 511 - len, "\r")
	}
	else
		len += format(menuBody[len], 511 - len, "\d")
	len += format(menuBody[len], 511 - len, "3. \wPodnies stawke o $\y%d\w^n", DEFAULTBET)

	// +10x
	if (money >= g_betamount[id] + DEFAULTBET * 10) {
		flags |= MENUBUTTON4
		len += format(menuBody[len], 511 - len, "\r")
	}
	else
		len += format(menuBody[len], 511 - len, "\d")
	len += format(menuBody[len], 511 - len, "4. \wPodnies stawke o $\y%d\w^n", DEFAULTBET * 10)


	// -1x
	if (g_betamount[id] - DEFAULTBET >= DEFAULTBET) {
		flags |= MENUBUTTON5
		len += format(menuBody[len], 511 - len, "\r")
	}
	else
		len += format(menuBody[len], 511 - len, "\d")
	len += format(menuBody[len], 511 - len, "5. \wObniz stawke o $\y%d\w^n", DEFAULTBET)

	// -10x
	if (g_betamount[id] - DEFAULTBET * 10 >= DEFAULTBET) {
		flags |= MENUBUTTON6
		len += format(menuBody[len], 511 - len, "\r")
	}
	else
		len += format(menuBody[len], 511 - len, "\d")
	len += format(menuBody[len], 511 - len, "6. \wObniz stawke o $\y%d^n\w", DEFAULTBET * 10)

	len += format(menuBody[len], 511 - len, "\r7. \wPostaw wszystko!")
	flags |= MENUBUTTON7

	len += format(menuBody[len], 511 - len, "^n^n\r0. \wPier*ole, nie obstawiam!")

	show_menu(id, flags, menuBody)
	//client_print(id, print_chat, "Menu zostalo Ci ukazane")
}

public menu_fn(id, key) {
	//client_print(id, print_chat, "Zaznaczyles opcje w menu, przycisk: %d", key)
	new bool:stayinmenu = true
	new const DEFAULTBET = get_cvar_num(CVAR_DEFAULTBET)
	switch (key) {
		case MENUSELECT1: {
			// bet on t
			placebet(id, TEAM_T)
			stayinmenu = false
		}
		case MENUSELECT2: {
			// bet on ct
			placebet(id, TEAM_CT)
			stayinmenu = false
		}
		case MENUSELECT3: {
			// raise bet
			alterbet(id, DEFAULTBET)
		}
		case MENUSELECT4: {
			// lower bet
			alterbet(id, DEFAULTBET * 10)
		}
		case MENUSELECT5: {
			// raise bet
			alterbet(id, -DEFAULTBET)
		}
		case MENUSELECT6: {
			// lower bet
			alterbet(id, -DEFAULTBET * 10)
		}
		case MENUSELECT7: {
			// bet all
			betall(id)
		}
		case MENUSELECT0: {
			// no bet
			if (g_betting)
				client_print_color(id, id, "^x04[%s] ^x01Dobry wybor, zachowaj swoje pieniadze!", PREFIX);
			stayinmenu = false
		}
	}

	if (stayinmenu)
		startbet(id)

	return PLUGIN_HANDLED
}

placebet(id, choice) {
	if (!is_user_connected(id))
		return

	if (g_betting) {
		g_betperson[id] = choice
		altermoney(id, -g_betamount[id])
		new name[33]
		get_user_name(id, name, 32)
		client_print_color(0, id, "^x04[%s] ^x01Gracz ^x03%s^x01 postawil ^x04%d^x01$ na ^x03%s^x01!", PREFIX,name, g_betamount[id], g_names[g_betperson[id]]);
		client_cmd(id, "spk LMB/obstawiam.wav");
		//client_print(0, print_chat, "%s postawil $%d na %s.", name, g_betamount[id], g_names[g_betperson[id]])

		displaybetshud()
	}
	else
		client_print(id, print_center, "Twoja stawka jest zbyt niska!")
}

alterbet(id, money) {
	g_betamount[id] += money
}

betall(id) {
	g_betamount[id] = cs_get_user_money(id)
}
altermoney(id, money) { // calc 16000+ bonuses here?
	new newmoney = cs_get_user_money(id) + money
#if defined IWANTPRIZES
	if (newmoney > 16000)
		prize(id, newmoney - 16000)
#endif

	cs_set_user_money(id, newmoney, 1)
}

roundendtasks(const TEAM) {
#if defined IWANTPRIZES
	remove_respawntasks()
#endif
	g_round = false
	if (g_betting) {
		closebetmenu()
		remove_task(TASKID_BETTIMER) // stop the timer that will close the menu...
		remove_task(TASKID_BETTIMERDISPLAY) // stop the timer that displays the time left until menu closes...
		if (TEAM == TEAM_T || TEAM == TEAM_CT)
			calculatebets(TEAM)
		else // round ended in a draw... payback all bet money
			payback()
	}
}

public roundend_t_event() {
	roundendtasks(TEAM_T)
}
public roundend_ct_event() {
	roundendtasks(TEAM_CT)
}
public roundend_draw_event() {
	roundendtasks(0)
}

public closebetmenu() {
	new const MAXPLAYERS = get_maxplayers()
	new usermenu, userkeys
	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || is_user_alive(i) || is_user_bot(i))
			continue

		get_user_menu(i, usermenu, userkeys) // get user menu
		if (usermenu == g_betmenu) // Hide it here!
			client_cmd(i, "slot10") // client_print(players[i], print_chat, "Hey, round's over and you didn't bet yet... close that menu!")
	}
}

payback() {
	// End betting here
	g_betting = false
	for (new i = 1; i < 33; i++) {
		if (i == g_t || i == g_ct || !is_user_connected(i) || g_betperson[i] == 0) // the remaining players didn't bet, and don't interact with disconnected players, and don't give anything to those who didn't bet
			continue

		altermoney(i, g_betamount[i])
		client_print_color(i, i, "^x04[%s] ^x01Runda zakonczyla sie remisem, oddajemy Ci ^x04%d^x01$!", PREFIX,g_betamount[i]);
	}
}

calculatebets(result) {
	// End betting here
	g_betting = false

	// Find all who voted for right player, store how much they voted
	new totalrightbets = 0, overallbets = 0
	for (new i = 1; i < 33; i++) {
		if (g_betperson[i] == result)
			totalrightbets += g_betamount[i]

		if (g_betperson[i] == TEAM_T || g_betperson[i] == TEAM_CT)
			overallbets += g_betamount[i]
	}

	// Did anyone make a bet at all?
	if (overallbets == 0) {
		client_print_color(0, print_team_default, "^x04[%s] ^x01Nikt nie obstawial w tej rundzie!", PREFIX);
		return
	}

	// Print total bets.
	client_print_color(0, print_team_default, "^x04[%s] ^x01Cala pula: ^x04%d^x01$ (^x04%d^x01$ na zwycieska druzyne!)", PREFIX,overallbets, totalrightbets);

	// Now hand out money...
	new Float:wonmoney, name[33], Float:highestwonmoney = -1.0, nr_of_highestwinners = 0, highestwinners[32],CsTeams:team
	for (new i = 1; i < 33; i++) {
		if (i == g_t || i == g_ct || !is_user_connected(i)) // the remaining players didn't bet, and don't interact with disconnected players...
			continue

		team = cs_get_user_team(i)
		if (team != CS_TEAM_T && team != CS_TEAM_CT) // spectators don't get anything
			continue

		get_user_name(i, name, 32)
		if (totalrightbets > 0 && g_betperson[i] == result) { // Just to avoid divison by 0 (which shouldn't happen, but...)
			// This player should have money. How much? ((g_betamount[i] / totalrightbets) * overallbets)
			wonmoney = (float(g_betamount[i]) / float(totalrightbets)) * float(overallbets)
			client_cmd(i, "spk LMB/wygrana.wav");
			client_print_color(i, i, "^x04[%s] ^x01Wygrales! Zwracamy Ci twoje pieniadze, ^x04%d^x01$, wraz z wygrana ^x04%d^x01$!", PREFIX, g_betamount[i], floatround(wonmoney) - g_betamount[i]);
			client_print_color(0, i, "^x04[%s] ^x01Gracz ^x03%s^x01 wygral i dostaje swoje pieniadze, ^x04%d^x01$, wraz z wygrana ^x04%d^x01$!", PREFIX,name, g_betamount[i], floatround(wonmoney) - g_betamount[i]);
			altermoney(i, floatround(wonmoney))
			if (wonmoney - g_betamount[i] > highestwonmoney) {
				nr_of_highestwinners = 0
				highestwinners[nr_of_highestwinners++] = i
				highestwonmoney = wonmoney - g_betamount[i]
			}
			else if (wonmoney - g_betamount[i] == highestwonmoney) {
				highestwinners[nr_of_highestwinners++] = i
			}
		}
		else if (g_betperson[i] == 0) {
			client_print_color(i, i, "^x04[%s] ^x01Nie obstawiles tym razem!", PREFIX);
			client_print_color(0, i, "^x04[%s] ^x01Gracz ^x03%s^x01 trzyma ^x04hajs^x01 przy d*pie!", PREFIX,name);
		}
		else {
			client_print_color(i, i, "^x04[%s] ^x01Tracisz swoja stawke w wysokosci ^x04%d^x01$!", PREFIX, g_betamount[i]);
			client_cmd(i, "spk LMB/przegrana.wav");
			//client_print(i, print_chat, "Straciles swoja stawke wysokosci $%d!", g_betamount[i])
			client_print_color(0, i, "^x04[%s] ^x01Gracz ^x03%s^x01 stracil ^x04%d^x01$ na obstawianiu!", PREFIX, name, g_betamount[i])
		}
	}

	//statsworker(highestwinners, nr_of_highestwinners, highestwonmoney)

	if (nr_of_highestwinners == 0) { // Did anyone make the right bet? If not, move the bet money to the pot.
		client_print_color(0, print_team_default, "^x04[%s] ^x01Nikt nie wygral, w puli jest ^x04%d^x01$, w sumie: ^x04%d^x01$!", PREFIX, overallbets, g_pot += overallbets);
		set_vaultpot(g_pot)
		return
	}
	else if (nr_of_highestwinners == 1) { // Winner takes it all.
		get_user_name(highestwinners[0], name, 32)
		if (g_pot != 0) {
			client_cmd(highestwinners[0], "spk IS-4FuN/wygrana.wav");
			client_print_color(0, highestwinners[0], "^x04[%s] ^x01Gracz ^x03%s^x01 wygral ^x04%d^x01$ ze stawka ^x04%d^x01$, wygral takze pozostala pule, ^x04%d^x01$!", PREFIX, name, floatround(highestwonmoney), g_betamount[highestwinners[0]], g_pot);
			give_pot(nr_of_highestwinners, highestwinners)
		}
		else {
			if (highestwonmoney >= 1.0)
			client_cmd(highestwinners[0], "spk IS-4FuN/wygrana.wav");
			client_print_color(0, highestwinners[0], "^x04[%s] ^x01Gracz ^x03%s^x01 wygral ^x04%d^x01$ ze stawka ^x04%d^x01$, pula nagrod jest pusta!", PREFIX,name, floatround(highestwonmoney), g_betamount[highestwinners[0]]);
		}
	}
	else { // Winners share it all.
		new msg[128], len = 0
		if (g_pot > 0) {
			len += format(msg[len], 127 - len, "Dzielenie puli $%d: ", g_pot)
			give_pot(nr_of_highestwinners, highestwinners)
		}
		else
			len += format(msg[len], 127 - len, "Najlepsi hazardzisci: ")

		for (new i = 0; i < nr_of_highestwinners; i++) {
			get_user_name(highestwinners[i], name, 32)
			len += format(msg[len], 127 - len, "%s ", name)
		}
	}
}

/*
statsworker(highestwinners[32], const NROFHIGHESTWINNERS, Float:highestwonmoney) {
	// Build result table of last bet
}
*/

set_vaultpot(value) {
	new potstr[16]
	num_to_str(value, potstr, 15)
	set_vaultdata(VAULTKEY_POT, potstr)
}

give_pot(nr_of_winners, winners[32]) {
	new pot = g_pot
	g_pot = 0
	set_vaultpot(0) // empty pot in vault

	if (nr_of_winners == 1) {
		altermoney(winners[0], pot)
		return
	}

	if (nr_of_winners == 0) {
		log_amx("%s: Error in script - division by zero error in give_pot! nr_of_winners: %d", nr_of_winners)
		return
	}
	new share = pot/nr_of_winners
	for (new i = 0; i < nr_of_winners; i++)
		altermoney(winners[i], share)
}

/*
public killtest(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new const MAXPLAYERS = get_maxplayers()

	new bool:tSkonad = false, bool:ctSkonad = false, team

	for (new i = 1; i <= MAXPLAYERS; i++) {
		if (!is_user_connected(i) || !is_user_alive(i))
			continue

		if (tSkonad && ctSkonad) {
			user_kill(i, 1)
			continue
		}

		team = cs_get_user_team(i)

		if (team == TEAM_T) {
			if (tSkonad || i == id)
				user_kill(i, 1)
			else
				tSkonad = true
		}
		else if (team == TEAM_CT) {
			if (ctSkonad || i == id)
				user_kill(i, 1)
			else
				ctSkonad = true
		}
		else {
			// Some odd team... just kill!
			user_kill(i, 1)
		}
	}

	return PLUGIN_HANDLED
}
*/

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)

	register_event("DeathMsg", "death_event", "a")
	register_event("SendAudio", "roundend_t_event", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "roundend_ct_event", "a", "2&%!MRAD_ctwin")
	register_event("SendAudio", "roundend_draw_event", "a", "2&%!MRAD_rounddraw")
	register_event("ResetHUD", "newround_event", "b")

#if defined IWANTPRIZES
	register_event("TextMsg", "restartgame_event", "a", "2&#Game_C","2&#Game_w")
	register_event("TextMsg", "restartgame_event", "a", "2&#Game_will_restart_in")
#if defined DEBUGMODE
	register_concmd("0gp", "giveprize", ADMIN_CFG, "<id> <1-3> <#> - give # 1-3 prizes to id")
	register_concmd("0gpa", "giveprizeall", ADMIN_CFG, "<1-3> <#> - give # 1-3 prizes to all")
#endif
#endif
	//register_clcmd("0killtest", "killtest", ADMIN_CFG, "- kills you and leaves two people alive on each team...")
	register_cvar(OVERRIDEPREVIOUSMENU, "1")
	register_cvar(CVAR_DEFAULTBET, "100")
	register_cvar(CVAR_BETTIME, "20")

	g_betmenu = register_menuid("Pojedynek")
	register_menucmd(g_betmenu, 1023, "menu_fn")

	if (vaultdata_exists(VAULTKEY_POT))
		g_pot = get_vaultdata(VAULTKEY_POT)

	server_print("LMB: %s wersja v%s", PLUGINNAME, VERSION)
}

public plugin_precache()
{
	precache_sound("LMB/wygrana.wav");
	precache_sound("LMB/przegrana.wav");
	precache_sound("LMB/obstawiam.wav");
}
