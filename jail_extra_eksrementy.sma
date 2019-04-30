#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN  "JailBreak Ekstrementy"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

#define TASK_PISS 1984
#define TASK_PUDDLE 2392
#define TASK_PUKE 3534

new cvarPissUses, cvarPukeUses, cvarDookieUses, pissUses[MAX_PLAYERS + 1], pukeUses[MAX_PLAYERS + 1], dookieUses[MAX_PLAYERS + 1], freezeTime;

new const dookieCommands[][] = { "say /sraj", "say_team /sraj", "say /wysraj", "say_team /wysraj", "say /kupa", "say_team /kupa", "say /gowno", "say_team /gowno" };
new const pissCommands[][] = { "say /sikaj", "say_team /sikaj", "say /lej", "say_team /lej", "say /szczaj", "say_team /szczaj" };
new const pukeCommands[][] = { "say /rzygaj", "say_team /rzygaj", "say /wymiotuj", "say_team /wymiotuj" };

enum _:spriteData { SPRITE_STEAM, SPRITE_SMOKE };
enum _:dookieData { DOOKIE_MODEL, DOOKIE_MODEL2, DOOKIE_SOUND, DOOKIE_SOUND2 };
enum _:pissData { PISS_MODEL, PISS_MODEL2, PISS_MODEL3, PISS_MODEL4, PISS_MODEL5, PISS_SOUND };
enum _:pukeData { PUKE_SOUND, PUKE_SOUND2 };

new const sprite[spriteData][] = { "sprites/xsmoke3.spr", "sprites/steam1.spr" };
new const dookie[dookieData][] = { "models/jail/dookie.mdl", "models/jail/dookie2.mdl", "sound/jail/dookie.wav", "sound/jail/dookie2.wav" };
new const piss[pissData][] = { "models/jail/piss.mdl", "models/jail/piss2.mdl", "models/jail/piss3.mdl", "models/jail/piss4.mdl", "models/jail/piss5.mdl", "sound/jail/piss.wav" };
new const puke[pukeData][] = { "sound/jail/puke.wav", "sound/jail/puke2.wav" };

new sprites[spriteData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	bind_pcvar_num(register_cvar("jail_piss_uses", "3"), cvarPissUses);
	bind_pcvar_num(register_cvar("jail_puke_uses", "3"), cvarPukeUses);
	bind_pcvar_num(register_cvar("jail_dookie_uses", "3"), cvarDookieUses);

	for (new i; i < sizeof dookieCommands; i++) register_clcmd(dookieCommands[i], "make_dookie");
	for (new i; i < sizeof pissCommands; i++) register_clcmd(pissCommands[i], "make_piss");
	for (new i; i < sizeof pukeCommands; i++) register_clcmd(pukeCommands[i], "make_puke");

	register_logevent("round_start", 2, "1=Round_Start");
	
	register_event("HLTV", "new_round", "a", "1=0", "2=0");

	register_think("dookie", "think_dookie");
}

public plugin_precache()
{
	for (new i; i < sizeof sprite; i++) sprites[i] = precache_model(sprite[i]);

	for (new i; i <= DOOKIE_MODEL2; i++) precache_model(dookie[i]);
	for (new i = DOOKIE_SOUND; i <= DOOKIE_SOUND2; i++) precache_sound(dookie[i]);

	for (new i; i <= PISS_MODEL5; i++) precache_model(piss[i]);

	precache_sound(piss[PISS_SOUND]);

	for (new i; i <= PUKE_SOUND2; i++) precache_sound(puke[i]);
}

public client_disconnected(id)
	remove_ents(id);

public client_putinserver(id)
{
	pissUses[id] = 0;
	pukeUses[id] = 0;
	dookieUses[id] = 0;

	remove_tasks(id);
}

public new_round()
{
	remove_ents();
	
	freezeTime = true;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		pissUses[id] = 0;
		pukeUses[id] = 0;
		dookieUses[id] = 0;

		remove_tasks(id);
	}
}

public round_start()
	freezeTime = false;

public remove_tasks(id)
{
	remove_task(id + TASK_PISS);
	remove_task(id + TASK_PUDDLE);
	remove_task(id + TASK_PUKE);
}

public think_dookie(ent)
{
	if (!pev_valid(ent)) return FMRES_IGNORED;

	new Float:origin[3], Float:globalTime;

	pev(ent, pev_origin, origin);

	global_get(glb_time, globalTime);
	set_pev(ent, pev_nextthink, globalTime + 1.0);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 10.0);
	write_short(sprites[SPRITE_STEAM]);
	write_byte(8);
	write_byte(10);
	message_end();

	return FMRES_HANDLED;
}

public make_dookie(id)
{
	if (!is_user_alive(id) || freezeTime) return PLUGIN_HANDLED;

	if (dookieUses[id] >= cvarDookieUses) {
		client_print(id, print_center, "Wysrales sie juz maksymalna liczbe razy w tej rundzie!");

		return PLUGIN_HANDLED;
	}

	dookieUses[id]++;

	new Float:origin[3];

	pev(id, pev_origin, origin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	write_short(sprites[SPRITE_SMOKE]);
	write_byte(60);
	write_byte(5);
	message_end();

	if (random_num(1, 5) == 1) {
		client_print(id, print_center, "Postawiles mega klocka!");

		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, dookie[DOOKIE_SOUND2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		create_super_dookie(id);

	} else {
		client_print(id, print_center, "Postawiles klocka!");

		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, dookie[DOOKIE_SOUND], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		create_dookie(id);
	}

	return PLUGIN_HANDLED;
}

public create_dookie(id)
{
	new Float:origin[3], Float:globalTime, ent;

	pev(id, pev_origin, origin);

	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	if (!ent) return PLUGIN_HANDLED;

	set_pev(ent, pev_classname, "dookie");

	engfunc(EngFunc_SetModel, ent, dookie[DOOKIE_MODEL]);

	engfunc(EngFunc_SetSize, ent, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, ent, origin);

	set_pev(ent, pev_solid, SOLID_SLIDEBOX);
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(ent, pev_owner, id);

	global_get(glb_time, globalTime);
	set_pev(ent, pev_nextthink, globalTime + 1.0);

	return PLUGIN_HANDLED;
}

public create_super_dookie(id)
{
	new Float:origin[3], Float:globalTime, ent;

	pev(id, pev_origin, origin);

	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	if (!ent) return PLUGIN_HANDLED;

	set_pev(ent, pev_classname, "dookie");

	engfunc(EngFunc_SetModel, ent, dookie[DOOKIE_MODEL2]);

	engfunc(EngFunc_SetSize, ent, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, ent, origin);

	set_pev(ent, pev_solid, SOLID_SLIDEBOX);
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(ent, pev_owner, id);

	global_get(glb_time, globalTime);
	set_pev(ent, pev_nextthink, globalTime + 1.0);

	new players[MAX_PLAYERS], playersNum;

	get_players(players, playersNum, "a");

	static msgScreenShake;
	
	if (!msgScreenShake) msgScreenShake = get_user_msgid("ScreenShake");

	for (new i = 0; i < playersNum; i++) {
		if(!is_user_alive(players[i])) continue;

		message_begin(MSG_ONE, msgScreenShake, _, players[i]);
		write_short(1<<15);
		write_short(1<<11);
		write_short(1<<15);
		message_end();
	}

	for (new j = 0; j < 10; j++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_BLOODSTREAM);
		engfunc(EngFunc_WriteCoord, origin[0]);
		engfunc(EngFunc_WriteCoord, origin[1]);
		engfunc(EngFunc_WriteCoord, origin[2] - 20.0);
		write_coord(random_num(-100, 100));
		write_coord(random_num(-100, 100));
		write_coord(random_num(20, 300));
		write_byte(100);
		write_byte(random_num(100, 200));
		message_end();
	}

	return PLUGIN_HANDLED;
}

public make_piss(id)
{
	if (!is_user_alive(id) || freezeTime) return PLUGIN_HANDLED;

	if (pissUses[id] >= cvarPissUses) {
		client_print(id, print_center, "Wysikales sie juz maksymalna liczbe razy w tej rundzie!");

		return PLUGIN_HANDLED;
	}

	if (task_exists(id + TASK_PISS)) {
		client_print(id, print_center, "Juz jestes w trakcie sikania!");

		return PLUGIN_HANDLED;
	}

	if (task_exists(id + TASK_PUKE)) {
		client_print(id, print_center, "Jestes w trakcie rzygania!");

		return PLUGIN_HANDLED;
	}

	pissUses[id]++;

	client_print(id, print_center, "Sikasz!");

	emit_sound(id, CHAN_VOICE, piss[PISS_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM);

	set_task(0.2, "create_pee", id + TASK_PISS, .flags = "a", .repeat = 30);
	set_task(2.0, "place_puddle", id + TASK_PUDDLE, .flags = "a", .repeat = 3);

	return PLUGIN_HANDLED;
}

public create_pee(id)
{
	id -= TASK_PISS;

	if (!is_user_alive(id)) {
		remove_tasks(id);

		return PLUGIN_HANDLED;
	}

	new vector[3], aimVector[3], velocity[3];

	get_user_origin(id, vector);
	get_user_origin(id, aimVector, 3);

	new speed = floatround(get_distance(vector, aimVector) * 1.9);

	velocity[0] = aimVector[0] - vector[0];
	velocity[1] = aimVector[1] - vector[1];
	velocity[2] = aimVector[2] - vector[2];

  	new length = sqroot(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]);

	velocity[0] = velocity[0] * speed / length;
	velocity[1] = velocity[1] * speed / length;
	velocity[2] = velocity[2] * speed / length;

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(101);
	write_coord(vector[0]);
	write_coord(vector[1]);
	write_coord(vector[2]);
	write_coord(velocity[0]);
	write_coord(velocity[1]);
	write_coord(velocity[2]);
	write_byte(102);
	write_byte(160);
	message_end();

	return PLUGIN_HANDLED;
}

public place_puddle(id)
{
	id -= TASK_PUDDLE;

	if (!is_user_alive(id)) {
		remove_tasks(id);

		return PLUGIN_HANDLED;
	}

	new Float:origin[3], ent;

	pev(id, pev_origin, origin);

	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	if (!ent) return PLUGIN_HANDLED;

	set_pev(ent, pev_classname, "puddle");

	engfunc(EngFunc_SetSize, ent, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});

	engfunc(EngFunc_SetModel, ent, piss[random_num(PISS_MODEL, PISS_MODEL5)]);

	engfunc(EngFunc_SetOrigin, ent, origin);

	set_pev(ent, pev_solid, SOLID_SLIDEBOX);
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(ent, pev_owner, id);

	return PLUGIN_HANDLED;
}

public make_puke(id)
{
	if (!is_user_alive(id) || freezeTime) return PLUGIN_HANDLED;

	if (pukeUses[id] >= cvarPukeUses) {
		client_print(id, print_center, "Wyrzygales sie juz maksymalna liczbe razy w tej rundzie!");

		return PLUGIN_HANDLED;
	}

	if (task_exists(id + TASK_PUKE)) {
		client_print(id, print_center, "Juz jestes w trakcie rzygania!");

		return PLUGIN_HANDLED;
	}

	if (task_exists(id + TASK_PISS)) {
		client_print(id, print_center, "Jestes w trakcie sikania!");

		return PLUGIN_HANDLED;
	}

	pukeUses[id]++;

	client_print(id, print_center, "Rzygasz!");

	switch (random_num(0, 1)) {
		case 0: emit_sound(id, CHAN_VOICE, puke[PUKE_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 1: emit_sound(id, CHAN_VOICE, puke[PUKE_SOUND2], 1.0, ATTN_NORM, 0, PITCH_NORM);
	}

	set_task(0.3, "create_puke", id + TASK_PUKE, .flags = "a", .repeat = 9);

	return PLUGIN_HANDLED;
}

public create_puke(id)
{
	id -= TASK_PUKE;

	if (!is_user_alive(id)) {
		remove_tasks(id);

		return PLUGIN_HANDLED;
	}

	new vector[3], aimVector[3], velocity[3];

	get_user_origin(id, vector);
	get_user_origin(id, aimVector, 3);

	new speed = floatround(get_distance(vector, aimVector) * 1.9);

	velocity[0] = aimVector[0] - vector[0];
	velocity[1] = aimVector[1] - vector[1];
	velocity[2] = aimVector[2] - vector[2];

  	new length = sqroot(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]);

	velocity[0] = velocity[0] * speed / length;
	velocity[1] = velocity[1] * speed / length;
	velocity[2] = velocity[2] * speed / length;

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(101);
	write_coord(vector[0]);
	write_coord(vector[1]);
	write_coord(vector[2] - 2);
	write_coord(velocity[0]);
	write_coord(velocity[1]);
	write_coord(velocity[2]);
	write_byte(82);
	write_byte(160);
	message_end();

	return PLUGIN_HANDLED;
}

stock remove_ents(id = 0)
{
	new const ents[][] = { "dookie", "piss" };

	for (new i = 0; i < sizeof(ents); i++) {
		new ent = find_ent_by_class(-1, ents[i]);

		while (ent > 0) {
			if (!id || (id && entity_get_edict(ent, EV_ENT_owner) == id)) remove_entity(ent);

			ent = find_ent_by_class(ent, ents[i]);
		}
	}
}