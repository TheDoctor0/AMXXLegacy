#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define PLUGIN "JailBreak: Player Models"
#define VERSION "1.2"
#define AUTHOR "WiLS"

// Delay between model changes (increase if getting SVC_BAD kicks)
#define MODELCHANGE_DELAY 0.2

// Delay after roundstart (increase if getting kicks at round start)
#define ROUNDSTART_DELAY 2.0

// Enable custom hitboxes (experimental, might lag your server badly with some models)
//#define SET_MODELINDEX_OFFSET

#define MAXPLAYERS 32
#define MODELNAME_MAXLENGTH 32

#define TASK_MODELCHANGE 100
#define ID_MODELCHANGE (taskid - TASK_MODELCHANGE)

new const DEFAULT_MODELINDEX_T[] = "models/player/terror/terror.mdl"
new const DEFAULT_MODELINDEX_CT[] = "models/player/urban/urban.mdl"

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114
#define OFFSET_MODELINDEX 491 // Orangutanz

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define flag_unset(%1,%2)	(%1 &= ~(1 << (%2 & 31)));

new g_MaxPlayers
new g_HasCustomModel
new Float:g_ModelChangeTargetTime
new g_CustomPlayerModel[MAXPLAYERS+1][MODELNAME_MAXLENGTH]
#if defined SET_MODELINDEX_OFFSET
new g_CustomModelIndex[MAXPLAYERS+1]
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue");
	
	g_MaxPlayers = get_maxplayers();
}

public plugin_natives()
{
	register_library("cs_player_models_api")
	register_native("cs_set_player_model", "native_set_player_model")
	register_native("cs_reset_player_model", "native_reset_player_model")
}

public native_set_player_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new newmodel[MODELNAME_MAXLENGTH]
	get_string(2, newmodel, charsmax(newmodel))
	
	remove_task(id+TASK_MODELCHANGE)
	flag_set(g_HasCustomModel, id)
	
	copy(g_CustomPlayerModel[id], charsmax(g_CustomPlayerModel[]), newmodel)
	
#if defined SET_MODELINDEX_OFFSET	
	new modelpath[32+(2*MODELNAME_MAXLENGTH)]
	formatex(modelpath, charsmax(modelpath), "models/player/%s/%s.mdl", newmodel, newmodel)
	g_CustomModelIndex[id] = engfunc(EngFunc_ModelIndex, modelpath)
#endif
	
	new currentmodel[MODELNAME_MAXLENGTH]
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
	
	if (!equal(currentmodel, newmodel))
		fm_cs_user_model_update(id+TASK_MODELCHANGE)
	
	return true;
}

public native_reset_player_model(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	// Player doesn't have a custom model, no need to reset
	if (!flag_get(g_HasCustomModel, id))
		return true;
	
	remove_task(id+TASK_MODELCHANGE)
	flag_unset(g_HasCustomModel, id)
	fm_cs_reset_user_model(id)
	
	return true;
}

public client_disconnected(id)
{
	remove_task(id+TASK_MODELCHANGE)
	flag_unset(g_HasCustomModel, id)
}

public event_round_start()
{
	// An additional delay is offset at round start
	// since SVC_BAD is more likely to be triggered there
	g_ModelChangeTargetTime = get_gametime() + ROUNDSTART_DELAY
	
	// If a player has a model change task in progress,
	// reschedule the task, since it could potentially
	// be executed during roundstart
	new player
	for (player = 1; player <= g_MaxPlayers; player++)
	{
		if (task_exists(player+TASK_MODELCHANGE))
		{
			remove_task(player+TASK_MODELCHANGE)
			fm_cs_user_model_update(player+TASK_MODELCHANGE)
		}
	}
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[], const value[])
{
	if (flag_get(g_HasCustomModel, id) && equal(key, "model"))
	{
		static currentmodel[MODELNAME_MAXLENGTH]
		fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
		
		if (!equal(currentmodel, g_CustomPlayerModel[id]) && !task_exists(id+TASK_MODELCHANGE))
			fm_cs_set_user_model(id+TASK_MODELCHANGE)
		
#if defined SET_MODELINDEX_OFFSET
		fm_cs_set_user_model_index(id)
#endif
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fm_cs_set_user_model(taskid)
{
	set_user_info(ID_MODELCHANGE, "model", g_CustomPlayerModel[ID_MODELCHANGE])
}

stock fm_cs_set_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MODELINDEX, g_CustomModelIndex[id])
}

stock fm_cs_reset_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	switch (fm_cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_T))
		}
		case CS_TEAM_CT:
		{
			set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_CT))
		}
	}
}

stock fm_cs_get_user_model(id, model[], len)
{
	get_user_info(id, "model", model, len)
}

stock fm_cs_reset_user_model(id)
{
	// Set some generic model and let CS automatically reset player model to default
	copy(g_CustomPlayerModel[id], charsmax(g_CustomPlayerModel[]), "gordon")
	fm_cs_user_model_update(id+TASK_MODELCHANGE)
#if defined SET_MODELINDEX_OFFSET
	fm_cs_reset_user_model_index(id)
#endif
}

stock fm_cs_user_model_update(taskid)
{
	new Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_ModelChangeTargetTime >= MODELCHANGE_DELAY)
	{
		fm_cs_set_user_model(taskid)
		g_ModelChangeTargetTime = current_time
	}
	else
	{
		set_task((g_ModelChangeTargetTime + MODELCHANGE_DELAY) - current_time, "fm_cs_set_user_model", taskid)
		g_ModelChangeTargetTime = g_ModelChangeTargetTime + MODELCHANGE_DELAY
	}
}

stock CsTeams:fm_cs_get_user_team(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return CS_TEAM_UNASSIGNED;
	
	return CsTeams:get_pdata_int(id, OFFSET_CSTEAMS);
}
