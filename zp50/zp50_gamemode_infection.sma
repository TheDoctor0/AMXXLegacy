/*================================================================================
	
	---------------------------------
	-*- [ZP] Game Mode: Infection -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>

new g_MaxPlayers
new g_TargetPlayer

new cvar_infection_chance, cvar_infection_min_players
new cvar_infection_allow_respawn, cvar_respawn_after_last_human

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Infection", ZP_VERSION_STRING, "ZP Dev Team")
	new game_mode_id = zp_gamemodes_register("Infection Mode")
	zp_gamemodes_set_default(game_mode_id)
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_infection_chance = register_cvar("zp_infection_chance", "1")
	cvar_infection_min_players = register_cvar("zp_infection_min_players", "0")
	cvar_infection_allow_respawn = register_cvar("zp_infection_allow_respawn", "1")
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "1")
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_infection_allow_respawn))
		return PLUGIN_HANDLED;
	
	// Respawn if only the last human is left?
	if (!get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_infection_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_infection_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}

public zp_fw_gamemodes_start()
{
	// Allow infection for this game mode
	zp_gamemodes_set_allow_infect()
	
	// Turn player into the first zombie
	zp_core_infect(g_TargetPlayer, g_TargetPlayer) // victim = atttacker so that infection sound is played
	
	// Remaining players should be humans (CTs)
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our first zombie
		if (zp_core_is_zombie(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}