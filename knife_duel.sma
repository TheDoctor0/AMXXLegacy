#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>

#define PLUGIN 	"Pojedynek Nozowy 1vs1"
#define VERSION "1.0"
#define AUTHOR 	"O'Zone"

#define TASK_RESET 		5436
#define DECIDE_SECONDS 	10
#define KNIFE_SLASHES 	3

enum _:duelSound { SOUND_CHALLENGE, SOUND_COME, SOUND_COWARD };

new const duelSounds[duelSound][] =
{
	"knife_duel/wyzwanie.wav",
	"knife_duel/chocdomnie.wav",
	"knife_duel/cykor.wav"
};

new bool:duelInProgress, bool:duelQuestion;
new duelChallenger, duelChallenged;
new knifeSlashes[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("CurWeapon", "event_curweapon", "be", "1=1");

	register_forward(FM_EmitSound, "event_emitsound");

	register_event("DeathMsg", "event_cancel", "a")

	register_logevent("event_cancel", 2, "1=Round_End");

	set_task(240.0, "show_info", .flags = "b");
}

public plugin_precache()
	for(new i; i < sizeof(duelSounds); i++) precache_sound(duelSounds[i]);

public client_disconnected(id)
	if(duelChallenger == id || duelChallenged == id) cancel_duel();

public show_info()
	client_print_color(0, 0, "^x04[1vs1]^x01 Kiedy jestes tylko Ty i Twoj przeciwnik, mozesz go wyzwac na pojedynek nozowy pocierajac nozem o sciane.");

public event_curweapon(id)
{
    if(!duelInProgress || !is_user_alive(id)) return PLUGIN_CONTINUE;

    if(read_data(2) != CSW_KNIFE) engclient_cmd(id, "weapon_knife");

    return PLUGIN_CONTINUE;
}

public event_emitsound(id, channel, sound[], Float:volume, Float:attn, flags, pitch)
{
	if(duelInProgress || duelQuestion || !is_user_alive(id) || !equal(sound, "weapons/knife_hitwall1.wav")) return FMRES_IGNORED;

	new opponents = 0, matchingOpponent = 0;

	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || id == i) continue;

		if(get_user_team(id) == get_user_team(i)) return FMRES_IGNORED;
		else if(++opponents > 1) return FMRES_IGNORED;
		else matchingOpponent = i;
	}

	if(!matchingOpponent) return FMRES_IGNORED;

	if(++knifeSlashes[id] >= KNIFE_SLASHES)
	{
		challenge_question(id, matchingOpponent);

		knifeSlashes[id] = 0;
	}
	else set_task(3.0, "resetKnifeSlashes", id + TASK_RESET);

	return FMRES_IGNORED;
}

public event_cancel() 
	if(duelQuestion || duelInProgress) cancel_duel();

public resetKnifeSlashes(id)
{
	id -= TASK_RESET;

	knifeSlashes[id] = 0;
}

public challenge_question(challenger, challenged)
{
	duelChallenger = challenger;
	duelChallenged = challenged;

	duelQuestion = true;

	new menuData[128], challengerName[32], challengedName[32];

	get_user_name(challenger, challengerName, charsmax(challengerName));
	get_user_name(challenged, challengedName, charsmax(challengedName));

	client_print_color(challenger, challenger, "^x04[1vs1]^x01 Wyzwales^x03 %s^x01 na pojedynek nozowy! Oczekiwanie na odpowiedz (^x04 %d^x01 sekund^x01).", challengedName, DECIDE_SECONDS);

	client_cmd(0, "spk %s", duelSounds[SOUND_CHALLENGE]);

	formatex(menuData, charsmax(menuData), "\yPojedynek Nozowy 1vs1^n\r%s \wwyzwal Cie na pojedynek nozowy!^nZgadzasz sie? Masz \r%d sekund\w na odpowiedz.", challengerName, DECIDE_SECONDS);

	new menu = menu_create(menuData, "challenge_answer");

	menu_additem(menu, "Dawac go tutaj!");

	menu_setprop(menu, MPROP_EXITNAME, "Nie, boje sie :(");

	menu_display(duelChallenged, menu, _, DECIDE_SECONDS);
}

public challenge_answer(id, menu, item)
{
	if(!duelQuestion)
	{
		menu_destroy(menu);

		return PLUGIN_CONTINUE;
	}

	menu_destroy(menu);

	new challengerName[32], challengedName[32];

	get_user_name(duelChallenger, challengerName, charsmax(challengerName));
	get_user_name(duelChallenged, challengedName, charsmax(challengedName));

	if(item == MENU_EXIT)
	{
		client_print_color(0, duelChallenged, "^x04[1vs1]^x03 %s^x01 nie zgodzil sie na wyzwanie^x03 %s^x01...", challengedName, challengerName);

		client_cmd(0, "spk %s", duelSounds[SOUND_COWARD]);

		cancel_duel();

		return PLUGIN_CONTINUE;
	}

	if(item == MENU_TIMEOUT)
	{
		client_print_color(0, duelChallenged, "^x04[1vs1]^x03 %s^x01 nie odpowiedzial^x03 %s^x01 na jego wyzwanie...", challengerName, challengedName);

		cancel_duel();

		return PLUGIN_CONTINUE;
	}

	client_cmd(0, "spk %s", duelSounds[SOUND_COME]);

	client_print_color(0, duelChallenged, "^x04[1vs1]^x03 %s^x01 zgodzil sie na wyzwanie^x03 %s^x01!", challengedName, challengerName);

	duelQuestion = false;
	duelInProgress = true;

	set_user_health(duelChallenger, 100);
	set_user_health(duelChallenged, 100);

	cs_set_user_armor(duelChallenger, 100, CS_ARMOR_VESTHELM);
	cs_set_user_armor(duelChallenged, 100, CS_ARMOR_VESTHELM);

	strip_user_weapons(duelChallenger);
	strip_user_weapons(duelChallenged);

	give_item(duelChallenger, "weapon_knife");
	give_item(duelChallenged, "weapon_knife");

	engclient_cmd(duelChallenger, "weapon_knife");
	engclient_cmd(duelChallenged, "weapon_knife");

	return PLUGIN_CONTINUE;
}

public cancel_duel()
{
	duelQuestion = false;
	duelInProgress = false;

	knifeSlashes[duelChallenger] = 0;
	knifeSlashes[duelChallenged] = 0;

	remove_task(duelChallenger + TASK_RESET);
	remove_task(duelChallenged + TASK_RESET);

	if(is_user_connected(duelChallenger)) show_menu(duelChallenger, 0, "^n", 1);
	if(is_user_connected(duelChallenged)) show_menu(duelChallenged, 0, "^n", 1);
}