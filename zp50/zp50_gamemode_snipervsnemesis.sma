#include <amxmodx>
#include <fun>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_sniper>
#include <zp50_class_nemesis>
#include <zp50_deathmatch>

#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 0
#define HUD_EVENT_G 50
#define HUD_EVENT_B 200

new g_MaxPlayers
new g_HudSync

new cvar_svn_chance, cvar_svn_min_players
new cvar_svn_ratio
new cvar_svn_sniper_hp_multi, cvar_svn_nemesis_hp_multi
new cvar_svn_show_hud
new cvar_svn_allow_respawn

public plugin_precache()
{
	register_plugin("[ZP] Game Mode: Sniper vs Nemesis", ZP_VERSION_STRING, "zmd94")
	zp_gamemodes_register("Sniper vs Nemesis")
	
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_svn_chance = register_cvar("zp_svn_chance", "20")
	cvar_svn_min_players = register_cvar("zp_svn_min_players", "0")
	cvar_svn_ratio = register_cvar("zp_svn_ratio", "0.5")
	cvar_svn_sniper_hp_multi = register_cvar("zp_svn_sniper_hp_multi", "0.25")
	cvar_svn_nemesis_hp_multi = register_cvar("zp_svn_nemesis_hp_multi", "0.25")
	cvar_svn_show_hud = register_cvar("zp_svn_show_hud", "1")
	cvar_svn_allow_respawn = register_cvar("zp_svn_allow_respawn", "0")
}

public zp_fw_deathmatch_respawn_pre(id)
{
	if (!get_pcvar_num(cvar_svn_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		if (random_num(1, get_pcvar_num(cvar_svn_chance)) != 1)
			return PLUGIN_HANDLED;
		
		if (GetAliveCount() < get_pcvar_num(cvar_svn_min_players))
			return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{
	new id, alive_count = GetAliveCount()
	new sniper_count = floatround(alive_count * get_pcvar_float(cvar_svn_ratio), floatround_ceil)
	new nemesis_count = alive_count - sniper_count
	
	new iSnipers, iMaxSnipers = sniper_count
	while (iSnipers < iMaxSnipers)
	{
		id = GetRandomAlive(random_num(1, alive_count))
		
		if (zp_class_sniper_get(id))
			continue;
		
		zp_class_sniper_set(id)
		iSnipers++
		
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_svn_sniper_hp_multi)))
	}
	new iNemesis, iMaxNemesis = nemesis_count
	while (iNemesis < iMaxNemesis)
	{
		id = GetRandomAlive(random_num(1, alive_count))
		
		if (zp_class_sniper_get(id) || zp_class_nemesis_get(id))
			continue;
		
		zp_class_nemesis_set(id)
		iNemesis++
		
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_svn_nemesis_hp_multi)))
	}
	
	if (get_pcvar_num(cvar_svn_show_hud))
	{
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Sniper vs Nemesis Round!")
	}
}

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