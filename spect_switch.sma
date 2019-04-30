#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>

#define PLUGIN      "Hidden Spectator"
#define VERSION     "2.2"
#define AUTHOR      "O'Zone"

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

#define TASK_SPECT  48598

#define DEAD_FLAG   (1<<0)

new const commandSpect[][] = { "say /spect", "say_team /spect", "say /wroc", "say_team /wroc", "say /s", "say_team /s", "amx_spect" };

enum _:playerData {
	CsTeams:PLAYER_TEAM,
	CsTeams:PLAYER_OLD_TEAM,
	PLAYER_FRAGS,
	PLAYER_DEATHS,
	PLAYER_HEALTH,
	PLAYER_ARMOR,
	PLAYER_WEAPONS_NUM,
	PLAYER_WEAPONS[32],
	PLAYER_WEAPONS_AMMO[32],
	PLAYER_WEAPONS_BPAMMO[32]
}

new spect[MAX_PLAYERS + 1][playerData], bool:roundEnd, hiddenSpectator, spawned, nextRound, defuser, roundTime;

new cvarSwitchTeams, Float:cvarDeadPercent, Float:cvarSpawnTime;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof commandSpect; i++) register_clcmd(commandSpect[i], "cmd_spect");

	bind_pcvar_num(create_cvar("hidden_spectator_switch_teams", "1"), cvarSwitchTeams);
	bind_pcvar_float(create_cvar("hidden_spectator_dead_percent", "0.4"), cvarDeadPercent);
	bind_pcvar_float(create_cvar("hidden_spectator_spawn_time", "45"), cvarSpawnTime);

	register_message(get_user_msgid("TeamInfo"), "message_teaminfo");
	
	register_logevent("round_end", 2, "1=Round_End");
	
	register_event("HLTV", "new_round", "a", "1=0", "2=0");
}

public plugin_natives()
	register_native("is_user_spect", "is_user_spect", 1);

public is_user_spect(id)
	return Get(id, hiddenSpectator);
	
public client_disconnected(id)
	Rem(id, hiddenSpectator);

public client_connect(id)
	Rem(id, hiddenSpectator);
	
public client_command(id)
{
	if (!Get(id, hiddenSpectator)) return PLUGIN_CONTINUE;

	new command[12];
	
	read_argv(0, command, charsmax(command));
	
	if (equal(command, "jointeam", 8) || equal(command, "chooseteam", 10)) return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public client_death(killer, victim, weapon, hitPlace, teamKill)
	if(!roundEnd) send_flag(DEAD_FLAG, true);

public new_round()
{
	roundTime = floatround(get_gametime());
	
	roundEnd = false;
	
	send_flag();
	
	for (new i = 0; i <= MAX_PLAYERS; i++) {
		Set(i, nextRound);
		Rem(i, spawned);
	}
}

public round_end()
{
	roundEnd = true;
	
	send_flag(DEAD_FLAG);
}

public message_teaminfo(msgType, msgDest, target)
{
	static id;
	
	id = get_msg_arg_int(1);
	
	if (!Get(id, hiddenSpectator)) return;

	set_msg_arg_string(2, spect[id][PLAYER_TEAM] == CS_TEAM_T ? "TERRORIST" : "CT");
	
	return;
}
	
public cmd_spect(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_CONTINUE;
		
	if (Get(id, hiddenSpectator)) {
		Rem(id, hiddenSpectator);

		client_print_color(id, id, "^x03[SPECT]^x01 Wrociles do gry.");
		
		cs_set_user_team(id, spect[id][PLAYER_OLD_TEAM]);

		send_team_info(id, spect[id][PLAYER_OLD_TEAM] == CS_TEAM_T ? "TERRORIST" : "CT");
	
		if(Get(id, spawned) || (Get(id, nextRound) && roundTime + cvarSpawnTime >= get_gametime())) {
			ExecuteHamB(Ham_CS_RoundRespawn, id);
			
			set_task(0.1, "player_spawn", id);
		}
		else send_score_attrib(id, DEAD_FLAG);
	} else {
		if (cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
			client_print_color(id, id, "^x03[SPECT]^x01 Nie mozesz zostac ukrytym obserwatorem, jesli nie jestes w zadnej druzynie.");

			return PLUGIN_CONTINUE;
		}

		client_print_color(id, id, "^x03[SPECT]^x01 Zostales ukrytym obserwatorem.");
		
		Set(id, hiddenSpectator);
		Rem(id, nextRound);
		Rem(id, spawned);

		spect[id][PLAYER_FRAGS] = get_user_frags(id);
		spect[id][PLAYER_DEATHS] = cs_get_user_deaths(id);
		spect[id][PLAYER_OLD_TEAM] = cs_get_user_team(id);
	
		if (is_user_alive(id)) {
			Set(id, spawned);
			
			spect[id][PLAYER_HEALTH] = get_user_health(id);
			spect[id][PLAYER_ARMOR] = get_user_armor(id);

			if (cs_get_user_defuse(id)) Set(id, defuser);

			new weapons[32], weaponName[32], weaponsNum, weaponNum, weaponEnt;

			get_user_weapons(id, weapons, weaponsNum);

			spect[id][PLAYER_WEAPONS_NUM] = 0;
		
			for (new i = 0; i < weaponsNum; i++) {
				get_weaponname(weapons[i], weaponName, charsmax(weaponName));
			
				if (equal(weaponName, "weapon_knife")) continue;
				
				if (equal(weaponName, "weapon_c4")) {
					give_c4(id);

					continue;
				}

				weaponNum = spect[id][PLAYER_WEAPONS_NUM]++;

				spect[id][PLAYER_WEAPONS][weaponNum] = weapons[i];
				spect[id][PLAYER_WEAPONS_BPAMMO][weaponNum] = cs_get_user_bpammo(id, weapons[i]);
				
				weaponEnt = find_ent_by_owner(-1, weaponName, id);
				
				if (!weaponEnt) continue;
				
				spect[id][PLAYER_WEAPONS_AMMO][weaponNum] = cs_get_weapon_ammo(weaponEnt);
			}

			strip_user_weapons(id);
			
			static gmsgClCorpse;
	
			if (!gmsgClCorpse) gmsgClCorpse = get_user_msgid("ClCorpse");
		
			set_msg_block(gmsgClCorpse, BLOCK_ONCE);
		
			user_silentkill(id);
		
			set_task(0.1, "set_stats", id);
		}

		cs_set_user_team(id, CS_TEAM_SPECTATOR);

		set_team(id);
	
		send_flag(0, true);
	
		set_task(1.0, "update_info", id + TASK_SPECT, _, _, "b");
	}

	return PLUGIN_HANDLED;
}

public player_spawn(id)
{
	strip_user_weapons(id);
	
	give_item(id, "weapon_knife");

	new weaponName[32];
	
	for (new i = 0; i < spect[id][PLAYER_WEAPONS_NUM]; i++) {
		get_weaponname(spect[id][PLAYER_WEAPONS][i], weaponName, charsmax(weaponName));

		give_item(id, weaponName);

		cs_set_user_bpammo(id, spect[id][PLAYER_WEAPONS][i], spect[id][PLAYER_WEAPONS_BPAMMO][i]);

		new weaponEnt = find_ent_by_owner(-1, weaponName, id);
		
		if(!weaponEnt) continue;

		cs_set_weapon_ammo(weaponEnt, spect[id][PLAYER_WEAPONS_AMMO][i]);
	}

	set_user_armor(id, spect[id][PLAYER_ARMOR]);
	
	if ((Get(id, defuser) || Get(id, nextRound)) && cs_get_user_team(id) == CS_TEAM_CT) cs_set_user_defuse(id, 1);
	
	if (!Get(id, nextRound)) set_user_health(id, spect[id][PLAYER_HEALTH]);
}

public give_c4(id)
{
	new players[MAX_PLAYERS], playersNum, player;
					
	get_players(players, playersNum, "e", "TERRORIST");

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if(!is_user_alive(player) || id == player) continue;

		give_item(player, "weapon_c4");
		
		cs_set_user_plant(player, 1);
	
		break;
	}
}

public set_stats(id)
{
	set_user_frags(id, spect[id][PLAYER_FRAGS]);
	cs_set_user_deaths(id, spect[id][PLAYER_DEATHS]);
}

public update_info(id)
{
	id -= TASK_SPECT;

	if (!Get(id, hiddenSpectator)) {
		remove_task(id + TASK_SPECT);

		return;
	}
	
	set_team(id);
	
	if (!roundEnd) send_flag(0, true);
}

public set_team(id)
{
	if (Get(id, hiddenSpectator) && cvarSwitchTeams) {
		new players[MAX_PLAYERS], numTT, numCT;
		
		get_players(players, numTT, "e", "TERRORIST");
		get_players(players, numCT, "e", "CT");
		
		spect[id][PLAYER_TEAM] = numTT > numCT ? CS_TEAM_CT : CS_TEAM_T;

		send_team_info(id, spect[id][PLAYER_TEAM] == CS_TEAM_T ? "TERRORIST" : "CT");
	}
}

stock send_flag(flag = 0, check = false)
{
	new players[MAX_PLAYERS], player, playersNum;
	
	if(check) {
		new playersDeadNum;
		
		get_players(players, playersDeadNum, "bh");
		get_players(players, playersNum, "h");
	
		if(float(playersDeadNum) / float(playersNum) >= cvarDeadPercent) flag = DEAD_FLAG;
	}
	else get_players(players, playersNum, "h");
	
	for (new i = 0; i < playersNum; i++) {
		player = players[i];
		
		if(Get(player, hiddenSpectator)) send_score_attrib(player, flag);
	}
}

stock send_score_attrib(id, flag)
{
	static gmsgScoreAttrib;
	
	if(!gmsgScoreAttrib) gmsgScoreAttrib = get_user_msgid("ScoreAttrib");

	message_begin(MSG_ALL, gmsgScoreAttrib, _, 0);
	
	write_byte(id);
	write_byte(flag);
	
	message_end();
}

stock send_team_info(id, team[])
{
	static gmsgTeamInfo;
	
	if(!gmsgTeamInfo) gmsgTeamInfo = get_user_msgid("TeamInfo");

	message_begin(MSG_ALL, gmsgTeamInfo, _, 0);
	
	write_byte(id);
	write_string(team);
	
	message_end();
}