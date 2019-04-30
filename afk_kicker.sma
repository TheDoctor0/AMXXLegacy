#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>
#include <fakemeta>

#define AFK_CHECK_FREQ       15 // Check for afk-frequency. This is also the warning message frequency.
#define SPEC_CHECK_FREQ      10 // Check for spec-kick. Has effect in afk_options 2 mode only or player is already a spectator.
#define MIN_AFK_TIME         30 // I use this incase stupid admins accidentally set afk_optstime to something silly.
#define BOMB_DROP_TIME       20 // Time until bomb gets dropped, it is also afk recognition time.
#define SHOW_FREQ            30 // Frequence of afk-count-messages, only needed if the CVAR afk_show_counter is set to 1
#define WARNING_TIME         25 // Time to start warning players before kick or spec-switch

#define TASK_SPECT 80324

new AfkT
new AfkCT
new numTalive
new numCTalive
new bombcarrier
new g_maxplayers
new lastCounterShow
new i_afktime[33]
new i_spectime[33]
new f_lastangles[33][3]
new f_spawnposition[33][3]
new bool:b_spawned[33] = {true, ...}
new bool:b_demorec[33] = {false, ...}
new bool:is_admin[33]  = {false, ...}
new bool:b_tobeslayed[33] = {false, ...}
new WEAPON[] = "weapon_c4"

native is_user_spect(id);

public plugin_init() {
	register_plugin("AFK Kicker", "1.1", "Isobold & O'Zone") 
	
	register_cvar("afk_slaytime",      "45") // AFK-Time until slay
	register_cvar("afk_optstime",     "90") // AFK-Time until afk_options will take effect
	register_cvar("afk_options",        "1") // 0 Spec, 1 Kick, 2 Spec+Kick, 3 Kick normal Players and Switch Admins to Spec, 4 nothing of these
	// in case 3 afk_adminkimmunity will have no effect
	register_cvar("afk_speckick",     "180") // time to be spec until kick
	register_cvar("afk_minplayers",     "2") // Minimum players to kick someone (afk_options 1 and 2 only)

	// 0 deactivate, 1 activate the following functions
	register_cvar("afk_bombdrop",       "1") // 1 Bomb will be dropped after BOMB_DROP_TIME
	register_cvar("afk_slayplayers",    "1") // 1 Slays AFK-Players when last survivor
	register_cvar("afk_adminsimmunity", "1") // 1 Admin immune against slay
	register_cvar("afk_adminkimmunity", "0") // 1 Admin immune against kick (against spec-kick to) (afk_options 1 and 2 only)
	register_cvar("afk_admincimmunity", "0") // 1 Admin immune against switch to specmode (afk_options 0 and 2 only)
	register_cvar("afk_show_counter",   "1") // 1 Displays a message every 25 seconds with the numbers and teams of afk_players ...
	// ... if at least 1 AFK detected
	register_cvar("afk_disable",        "0") // 1 Disable this plugin (4 example for clanwars)
	
	register_event("ResetHUD", "playerSpawned", "be")
	register_event("TeamInfo", "team_assign","a")
	register_logevent("bomb_events", 3, "1=triggered", "2=Spawned_With_The_Bomb", "2=Dropped_The_Bomb", "2=Got_The_Bomb", "2=Planted_The_Bomb")
	
	set_task(float(AFK_CHECK_FREQ),"checkPositions",_,_,_,"b")
	set_task(float(AFK_CHECK_FREQ),"checkDeath",_,_,_,"b")
	
	g_maxplayers = get_maxplayers()
}

public checkPositions() {
	new playernum, pl, t_slay, t_opts, t_bomb, t_slay_time, t_opts_time, min_players
	new a_ids[32], playerpos[3], playerview[3]
	if(get_cvar_num("afk_disable")) return PLUGIN_HANDLED
	get_players(a_ids, playernum, "ac")
	t_slay = get_cvar_num("afk_slayplayers")
	t_opts = get_cvar_num("afk_options")
	t_bomb = get_cvar_num("afk_bombdrop")
	t_slay_time = get_cvar_num("afk_slaytime")
	t_opts_time = get_cvar_num("afk_optstime")
	min_players = get_cvar_num("afk_minplayers")
	
	get_alive_nums()
	for(new i = 0; i < playernum; i++) {
		pl = a_ids[i]
		if(is_user_connected(pl) && !is_user_bot(pl) && !is_user_hltv(pl) && is_user_alive(pl) && b_spawned[pl]) {
			get_user_origin(pl, playerview, 3)
			get_user_origin(pl, playerpos)
			
			if((playerview[0] == f_lastangles[pl][0] && playerview[1] == f_lastangles[pl][1] && playerview[2] == f_lastangles[pl][2]) || (playerpos[0] == f_spawnposition[pl][0] && playerpos[1] == f_spawnposition[pl][1] && playerpos[2] == f_spawnposition[pl][2])) {
				i_afktime[pl] += AFK_CHECK_FREQ
				if(t_bomb == 1 && i_afktime[pl] >= BOMB_DROP_TIME && pl == bombcarrier) {
					new players[32], tnum
					get_players(players, tnum, "e", "TERRORIST")
					for(new i=0; i < tnum; i++){
						new player = players[i]
						if(!is_user_alive(player) || pl == player || i_afktime[player] >= BOMB_DROP_TIME)
							continue
						engclient_cmd(bombcarrier, "drop", WEAPON)
						new c4 = engfunc(EngFunc_FindEntityByString, -1, "classname", WEAPON)
						if (!c4)
							return PLUGIN_HANDLED

						new backpack = pev(c4, pev_owner)
						if (backpack <= g_maxplayers)
							return PLUGIN_HANDLED

						set_pev(backpack, pev_flags, pev(backpack, pev_flags) | FL_ONGROUND)
						dllfunc(DLLFunc_Touch, backpack, player)
						client_print_color(player, player, "^x04[AFK]^x01 Przekazalem^x03 Bombe^x01 od gracza AFK!")
						break
					}
				}
				if(t_opts == 0 || t_opts == 2) {
					if(playernum >= min_players)
					CheckSwitchSpec(pl, t_opts_time)
				}
				if(t_opts == 1 || t_opts == 3) {
					if(playernum >= min_players)
					checkKick(pl, t_opts, t_opts_time)
				}
				if(t_slay == 1) {
					if(t_slay_time <= i_afktime[pl])
					checkSlay(pl)
				}
			} else {
				i_afktime[pl] = 0
			}
			f_lastangles[pl][0] = playerview[0]
			f_lastangles[pl][1] = playerview[1]
			f_lastangles[pl][2] = playerview[2]
		}
	}
	afk_rs_msg()
	if((numTalive == 0 && AfkT > 0) || (numCTalive == 0 && AfkCT > 0)) {
		new players[32], num;
		get_players(players, num);
		for(new i; i<num; i++)
		{
			if(is_user_alive(players[i]) && !is_user_bot(players[i]) && !is_user_hltv(players[i])){
				client_print_color(players[i], players[i], "^x04[AFK]^x01 Wszyscy pozostali wrogowie sa AFK!")
			}
		}
	}
	return PLUGIN_HANDLED
}


// Handle Situations

//Check for Slay
checkSlay(id) {
	if(!((cs_get_user_team(id) == CS_TEAM_T && numTalive > 0) || (cs_get_user_team(id) == CS_TEAM_CT && numCTalive > 0))) {
		if(!(get_playersnum() < get_cvar_num("afk_minplayers") || (get_cvar_num("afk_adminsimmunity") == 1 && is_admin[id]))) {
			user_silentkill(id)
			b_tobeslayed[id] = true
		}
	}
}

CheckSwitchSpec(id, opts_time) {
	if (opts_time-WARNING_TIME <= i_afktime[id] < opts_time) {
		new timeleft = opts_time - i_afktime[id]
		client_print_color(id, id, "^x04[AFK]^x01 Za^x03 %i^x01 sekund zostaniesz przeniesiony do Spectators!", timeleft)
	} else if (i_afktime[id] > opts_time) {
		SwitchSpec(id)
	}
	return PLUGIN_CONTINUE
}

public checkKick(id, opt, opts_time) {
	if(get_cvar_num("afk_adminsimmunity") == 1 && is_admin[id] && opt == 1 && !is_user_spect(id)) {
	//if(get_cvar_num("afk_adminsimmunity") == 1 && is_admin[id] && opt == 1) {
		return PLUGIN_HANDLED
	} else {
		if(opts_time-WARNING_TIME <= i_afktime[id] < opts_time) {
			new timeleft = opts_time - i_afktime[id]
			if(is_admin[id] && opt == 3) {
				client_print_color(id, id, "^x04[AFK]^x01 Za^x03 %i sekund^x01 zostaniesz przeniesiony do Spectators!", timeleft)
			} else {
				client_print_color(id, id, "^x04[AFK]^x01 Za^x03 %i sekund^x01 zostaniesz wyrzucony z serwera!", timeleft)
			}
		} else if (i_afktime[id] >= opts_time) {
			if(is_admin[id] && opt == 3) {
				SwitchSpec(id)
			} else {
				new name[33], message[180]
				get_user_name(id, name, 32)
				formatex(message, charsmax(message), "^x04[AFK]^x01 Gracz^x03 %s^x01 byl AFK dluzej niz^x04 %i sekund^x01 i zostal wyrzucony z serwera!", name, opts_time)
				client_print_color(0, id, message)
				log_amx("%s zostal wyrzucony z serwera za bycie AFK dluzej niz %i sekund", name, opts_time)
				server_cmd("kick #%d ^"Byles AFK dluzej niz %i sekund!^"", get_user_userid(id), opts_time)
			}
		}
	}
	return PLUGIN_CONTINUE
}

public team_assign()
{
	new Team[32], id = read_data(1)
	read_data(2, Team, 31)

	if(is_user_bot(id) || is_user_hltv(id))
		return PLUGIN_CONTINUE
	
	remove_task(id + TASK_SPECT)
	
	if(equal(Team,"SPECTATOR") || equal(Team,"UNASSIGNED"))
	{
		i_spectime[id] = 0
		set_task(float(SPEC_CHECK_FREQ), "checkSpec", id + TASK_SPECT,_,_,"b")
	}

	return PLUGIN_CONTINUE 
}

SwitchSpec(id) {
	user_silentkill(id)
	cs_set_user_team(id, CS_TEAM_SPECTATOR)
	client_print_color(id, id, "^x04[AFK]^x01 Zostales przeniesiony na Specta za bycie AFK!")
	b_tobeslayed[id] = true
	i_spectime[id] = 0
	i_afktime[id] = 0
	return PLUGIN_CONTINUE
}

// Control Spec-Players
public checkSpec(id) {
	id -= TASK_SPECT
	new admin_imun, kicktime
	admin_imun = get_cvar_num("afk_adminkimmunity")
	kicktime = get_cvar_num("afk_speckick")
	
	if(!is_user_hltv(id) && is_user_connected(id) && !is_user_bot(id) && !is_user_spect(id)) {   
	//if(!is_user_hltv(id) && is_user_connected(id) && !is_user_bot(id)) {    
		if(!(admin_imun == 1 && is_admin[id])) {
			i_spectime[id] += SPEC_CHECK_FREQ

			//if(i_spectime[id] == kicktime/3) {
			//	client_print_color(id, print_team_red, "^x03[AFK]^x01 Za^x04 %i sekund^x01 zostaniesz wyrzucony ze specta. Wejdz do gry!", 2*kicktime/3)
			//}
			if(i_spectime[id] == kicktime/2) {
				client_print_color(id, id, "^x04[AFK]^x01 Za^x03 %i sekund^x01 zostaniesz wyrzucony ze specta. Wejdz do gry!", kicktime/2)
			}
			if(i_spectime[id] == 2*kicktime/3) {
				client_print_color(id, id, "^x04[AFK]^x01 Za^x03 %i sekund^x01 zostaniesz wyrzucony ze specta. Wejdz do gry!", kicktime/3)
			}
			if(i_spectime[id] >= kicktime) {
				new name[33], message[180]
				get_user_name(id, name, 32)
				formatex(message, charsmax(message), "^x04[AFK]^x01 Gracz^x03 %s^x01 byl spectem dluzej niz^x04 %i sekund^x01 i zostal wyrzucony z serwera!", name, kicktime)
				client_print_color(0, id, message)
				log_amx("%s zostal wyrzucony z serwera za bycie na spect dluzej niz %i sekund", name, kicktime)
				server_cmd("kick #%d ^"Byles spectem dluzej niz %i sekund!^"", get_user_userid(id), kicktime)
			}
		}
	}
	return PLUGIN_HANDLED
}

// Help functions

// Verifies if players are really dead
public checkDeath() {
	new playernum, pl
	new a_ids[32]
	
	if(get_cvar_num("afk_disable")) return PLUGIN_HANDLED
	get_players(a_ids, playernum, "ac")
	
	for(new i = 0; i < playernum; i++) {
		pl = a_ids[i]
		if(b_tobeslayed[pl]) {
			client_cmd(pl,"kill")
		}
	}
	return PLUGIN_HANDLED
}

// Tracks the bombholder
public bomb_events() {
	new arg0[64], action[64], name[33], userid, bid
	
	if(get_cvar_num("afk_disable")) return PLUGIN_HANDLED

	// Read the log data that we need 
	read_logargv(0,arg0,63) 
	read_logargv(2,action,63) 

	// Find the id of the player that triggered the log 
	parse_loguser(arg0,name,32,userid) 
	bid = find_player("k",userid) 

	// Find out what action it was 
	if (equal(action,"Spawned_With_The_Bomb")) { 
		bombcarrier = bid; 
	} else if (equal(action,"Dropped_The_Bomb")) { 
		bombcarrier = 0; 
	} else if (equal(action,"Got_The_Bomb")) { 
		bombcarrier = bid; 
	} else if (equal(action, "Planted_The_Bomb")) { 
		bombcarrier = 0; 
	} 
	return PLUGIN_HANDLED
}

public afk_rs_msg() {
	new playerCount, i, player
	new Players[32] 
	get_players(Players, playerCount, "ac")
	AfkT  = 0
	AfkCT = 0 

	for (i=0; i<playerCount; i++) {
		player = Players[i]
		if(i_afktime[player] > BOMB_DROP_TIME) {
			if(cs_get_user_team(player) == CS_TEAM_T)
			AfkT++
			if(cs_get_user_team(player) == CS_TEAM_CT)
			AfkCT++
		}
	}
	if((AfkT > 0 || AfkCT > 0) && get_cvar_num("afk_show_counter") == 1) {
		lastCounterShow += AFK_CHECK_FREQ
		if(lastCounterShow >= SHOW_FREQ) {
			new players[32], num;
			get_players(players, num);
			for(new i; i<num; i++)
			{
				if(is_user_alive(players[i]) && !is_user_bot(players[i]) && !is_user_hltv(players[i])){
					client_print_color(players[i], players[i], "^x04[AFK]^x01 Gracze^x04 TT^x01 AFK:^x03 %i^x01 | Gracze^x04 CT^x01 AFK:^x03 %i^x01 !", AfkT, AfkCT)
				}
			}
			lastCounterShow = 0
		}
	}
	return PLUGIN_CONTINUE
}

get_alive_nums() {
	new playerCount, i, gplayer
	new Players[32] 
	get_players(Players, playerCount, "ac")
	numCTalive = 0
	numTalive  = 0

	for (i=0; i<playerCount; i++) {
		gplayer = Players[i]
		if(cs_get_user_team(gplayer) == CS_TEAM_T && i_afktime[gplayer] < BOMB_DROP_TIME)
		numTalive++
		if(cs_get_user_team(gplayer) == CS_TEAM_CT && i_afktime[gplayer] < BOMB_DROP_TIME)
		numCTalive++
	}
	return PLUGIN_CONTINUE
}

public playerSpawned(id) {
	b_spawned[id]    = false
	b_demorec[id]    = false
	b_tobeslayed[id] = false
	new a_id[1]
	a_id[0] = id
	set_task(0.75, "getFirstPos",_, a_id, 1)
	return PLUGIN_HANDLED
}

public getFirstPos(a_id[]) {
	new id = a_id[0]
	b_spawned[id] = true
	get_user_origin(id, f_lastangles[id], 3)
	get_user_origin(id, f_spawnposition[id])
	if(get_user_flags(id)&ADMIN_IMMUNITY) {
		is_admin[id]   = true
	}
	return PLUGIN_HANDLED
}

public client_putinserver(id) {
	i_afktime[id]    = 0
	i_spectime[id]   = 0
	b_spawned[id]    = false
	b_demorec[id]    = false
	is_admin[id]     = false
	b_tobeslayed[id] = false
}

public client_disconnected(id)
	remove_task(id + TASK_SPECT)
