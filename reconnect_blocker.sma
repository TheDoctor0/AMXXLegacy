#include <amxmodx>
#include <fakemeta>


#define PLUGIN "Reconnect Features"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.2.4 BETA"

#define MAX_PLAYERS	32
#define MAX_STORED 	64

#define OFFSET_CSMONEY	115
#define OFFSET_CSDEATHS	444

#define TASK_KILL	1946573517
#define TASK_CLEAR	2946573517
#define TASK_PLAYER 3946573517


enum Storage {
	StoreSteamId[35],
	StoreFrags,
	StoreDeaths,
	StoreMoney,
	StoreRound
}

new g_CurInfos[MAX_PLAYERS+1][Storage]
new g_StoredInfos[MAX_STORED][Storage]

new bool:g_bPlayerNonSpawnEvent[MAX_PLAYERS + 1]
new g_iFwFmClientCommandPost

new g_iRoundNum

new g_pcvarTime, g_pcvarScore, g_pcvarMoney, g_pcvarSpawn, g_pcvarStartMoney
new mp_startmoney
new g_msgidDeathMsg
new g_iMaxPlayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_cvar("reconnect_features", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	g_pcvarTime = register_cvar("amx_noreconnect_time", "60")
	g_pcvarScore = register_cvar("amx_noreconnect_score", "1")
	g_pcvarMoney = register_cvar("amx_noreconnect_money", "1")
	g_pcvarSpawn = register_cvar("amx_noreconnect_spawn", "1")
	g_pcvarStartMoney = register_cvar("amx_noreconnect_startmoney", "0")

	register_event("HLTV", "eNewRound", "a", "1=0", "2=0")

	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w")

	register_event("ResetHUD", "Event_ResetHUD", "b")
	register_event("TextMsg", "Event_TextMsg_GameWillRestartIn", "a", "2=#Game_will_restart_in")
	register_clcmd("fullupdate", "ClientCommand_fullupdate")

	register_event("Money", "eMoney", "be")
	register_event("ScoreInfo", "eScoreInfo", "a")
}

public plugin_cfg()
{
	mp_startmoney = get_cvar_pointer("mp_startmoney")
	g_msgidDeathMsg = get_user_msgid("DeathMsg")
	g_iMaxPlayers = global_get(glb_maxClients)
}

public Event_TextMsg_GameWillRestartIn()
{
	static id
	for(id = 1; id <= g_iMaxPlayers; ++id)
		if( is_user_alive(id) )
			g_bPlayerNonSpawnEvent[id] = true
}

public ClientCommand_fullupdate(id)
{
	g_bPlayerNonSpawnEvent[id] = true
	static const szClientCommandPost[] = "Forward_ClientCommand_Post"
	g_iFwFmClientCommandPost = register_forward(FM_ClientCommand, szClientCommandPost, 1)
	return PLUGIN_CONTINUE
}

public Forward_ClientCommand_Post(id)
{
	unregister_forward(FM_ClientCommand, g_iFwFmClientCommandPost, 1)
	g_bPlayerNonSpawnEvent[id] = false
	return FMRES_HANDLED
}

public Event_ResetHUD(id)
{
	if (!is_user_alive(id))
		return

	if (g_bPlayerNonSpawnEvent[id])
	{
		g_bPlayerNonSpawnEvent[id] = false
		return
	}

	Forward_PlayerSpawn(id)
}

Forward_PlayerSpawn(id)
{
	if(g_CurInfos[id][StoreRound] == g_iRoundNum)
	{
		g_CurInfos[id][StoreRound] = 0
		set_task(0.1, "task_delay_kill", id+TASK_KILL)
	}
}

public task_delay_kill(id)
{
	id -= TASK_KILL

	new Float:fFrags
	pev(id, pev_frags, fFrags)
	set_pev(id, pev_frags, ++fFrags)

	set_pdata_int(id, OFFSET_CSDEATHS, get_pdata_int(id, OFFSET_CSDEATHS) - 1)

	new msgblock = get_msg_block(g_msgidDeathMsg)
	set_msg_block(g_msgidDeathMsg, BLOCK_ONCE)
	dllfunc(DLLFunc_ClientKill, id)
	set_msg_block(g_msgidDeathMsg, msgblock)

	client_print_color(id, print_team_red, "^x03[RECONNECT]^x01 Nie mozesz dwukrotnie zrespawnowac sie podczas trwania tej samej rundy^x01!")
}

public eMoney(id)
{
	g_CurInfos[id][StoreMoney] = read_data(1)
}

public eScoreInfo()
{
	new id = read_data(1)
	if(!(1<= id <= g_iMaxPlayers))
		return

	g_CurInfos[id][StoreFrags] = read_data(2)
	g_CurInfos[id][StoreDeaths] = read_data(3)
}

public eRestart()
{
	for(new i; i < MAX_STORED; i++)
	{
		remove_task(i+TASK_CLEAR)
		remove_task(i+TASK_PLAYER)
		g_StoredInfos[i][StoreSteamId][0] = 0
	}
}

public eNewRound()
{
	g_iRoundNum++
}

public client_disconnected(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
	{
		return
	}

	new Float:fTaskTime = get_pcvar_float(g_pcvarTime)
	if(!fTaskTime)
		return

	static iFree
	for(iFree = 0; iFree <= MAX_STORED; iFree++)
	{
		if(iFree == MAX_STORED)
		{
			return
		}
		if(!g_StoredInfos[iFree][StoreSteamId][0])
			break
	}

	copy(g_StoredInfos[iFree][StoreSteamId], 34, g_CurInfos[id][StoreSteamId])
	g_StoredInfos[iFree][StoreFrags] = g_CurInfos[id][StoreFrags]
	g_StoredInfos[iFree][StoreDeaths] = g_CurInfos[id][StoreDeaths]
	g_StoredInfos[iFree][StoreMoney] = g_CurInfos[id][StoreMoney]
	g_StoredInfos[iFree][StoreRound] = g_iRoundNum

	g_CurInfos[id][StoreSteamId][0] = 0
	g_CurInfos[id][StoreFrags] = 0
	g_CurInfos[id][StoreDeaths] = 0
	g_CurInfos[id][StoreMoney] = 0
	g_CurInfos[id][StoreRound] = 0

	set_task(fTaskTime, "task_clear", iFree+TASK_CLEAR)
}

public task_clear(iTaskId)
{
	iTaskId -= TASK_CLEAR
	g_StoredInfos[iTaskId][StoreSteamId][0] = 0
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return

	g_bPlayerNonSpawnEvent[id] = false

	static szSteamId[35]
	get_user_authid(id, szSteamId, charsmax(szSteamId))
	copy(g_CurInfos[id][StoreSteamId], charsmax(szSteamId), szSteamId)

	for(new i; i < MAX_STORED; i++)
	{
		if(!g_StoredInfos[i][StoreSteamId][0])
			continue

		if( equal(g_StoredInfos[i][StoreSteamId], szSteamId, strlen(szSteamId)) )
		{
			if(get_pcvar_num(g_pcvarScore))
			{
				set_pev(id, pev_frags, float(g_StoredInfos[i][StoreFrags]))
				set_pdata_int(id, OFFSET_CSDEATHS, g_StoredInfos[i][StoreDeaths])
				g_CurInfos[id][StoreFrags] = g_StoredInfos[i][StoreFrags]
				g_CurInfos[id][StoreDeaths] = g_StoredInfos[i][StoreDeaths]
			}
			if(get_pcvar_num(g_pcvarMoney))
			{
				new iMoney = g_StoredInfos[i][StoreMoney]
				new iStartMoney = get_pcvar_num(mp_startmoney)
				if(get_pcvar_num(g_pcvarStartMoney) && iMoney > iStartMoney)
				{
					set_pdata_int(id, OFFSET_CSMONEY, iStartMoney)
					g_CurInfos[id][StoreMoney] = iStartMoney
				}
				else
				{
					set_pdata_int(id, OFFSET_CSMONEY, iMoney)
					g_CurInfos[id][StoreMoney] = iMoney
				}
			}
			if(get_pcvar_num(g_pcvarSpawn))
			{
				g_CurInfos[id][StoreRound] = g_StoredInfos[i][StoreRound]
			}

			remove_task(id+TASK_PLAYER)
			set_task(7.0, "task_print_player", id+TASK_PLAYER)

			g_StoredInfos[i][StoreSteamId][0] = 0
			return
		}
	}
	g_CurInfos[id][StoreRound] = -1
}

public task_print_player(id)
{
	if(is_user_connected(id -= TASK_PLAYER))
	{
		client_print_color(id, print_team_red, "^x03[RECONNECT]^x01 Z powodu reconnectu twoje staty i kasa zostaly^x04 przywrocone^x01!")
		client_print_color(id, print_team_red, "^x03[RECONNECT]^x01 Jesli chcesz zresetowac staty uzyj komendy^x04 /reset^x01, a nie reconnectu!")
	}
}
