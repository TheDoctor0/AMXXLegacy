#include <amxmodx>
#include <orpheu>
#include <orpheu_memory>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <cs_team_changer>
#include <colorchat>

#define set_mp_pdata(%1,%2)  (OrpheuMemorySetAtAddress(g_pGameRules, %1, 1, %2))
#define get_mp_pdata(%1)	 (OrpheuMemoryGetAtAddress(g_pGameRules, %1))

#define TEAM_CT 1
#define TEAM_TT 2

new g_pGameRules;

new pCvarLimit;

new Score = 0;
new TTScore;
new CTScore;

new TT_Score;
new CT_Score;

new MaxPlayers;

new gmsgScoreInfo;

new Kills[33];
new Deaths[33];
new Team[33];

new bool:Change;

public plugin_init ()
{
	register_plugin( "Switch Teams with Score", "1.0", "O'Zone" );
	
	pCvarLimit = register_cvar("sts_win_limit", "16");
	
	register_event("TeamScore", "tt_score", "a", "1=TERRORIST");
	
	register_event("TeamScore", "ct_score", "a", "1=CT");
	
	register_event("SendAudio", "score", "a", "2&%!MRAD_terwin");
	
	register_event("SendAudio", "score", "a", "2&%!MRAD_ctwin");
	
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	
	MaxPlayers = get_maxplayers();
	
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
}

public plugin_precache()
	OrpheuRegisterHook(OrpheuGetFunction( "InstallGameRules" ), "OnInstallGameRules", OrpheuHookPost);

public OnInstallGameRules()
	g_pGameRules = OrpheuGetReturn();
	
public Spawn(id)
{
	if(Score == (get_pcvar_num(pCvarLimit) - 1) && is_user_alive(id))
	{
		StripWeapons(id, Primary);
		StripWeapons(id, Secondary);
		StripWeapons(id, Grenades);
		cs_set_user_bpammo(id, CSW_HEGRENADE, 0);
		cs_set_user_bpammo(id, CSW_FLASHBANG, 0);
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 0);
		set_user_armor(id, 0);
		switch(get_user_team(id))
		{
			case CSTEAM_CT: 
			{
				give_item(id, "weapon_usp");
				cs_set_user_bpammo(id, CSW_USP, 24);
			}
			case CSTEAM_TERRORIST: 
			{
				give_item(id, "weapon_glock18");
				cs_set_user_bpammo(id, CSW_GLOCK18, 40);
			}
		}
		cs_set_user_money(id, 800);
	}
}

public GameCommencing()
	Score = 0;
	
public score()
	Score++;

public tt_score()
{
	TTScore = read_data(2);

	if(Score == (get_pcvar_num(pCvarLimit) - 1))
		set_task(0.5, "ChangeTeams");
		
	if(TTScore >= get_pcvar_num(pCvarLimit) && (TTScore - CTScore >= 2))
		set_task(0.5, "MatchEnd");
}

public ct_score()
{
	CTScore = read_data(2);
	
	if(Score == (get_pcvar_num(pCvarLimit) - 1))
		set_task(0.5, "ChangeTeams");
		
	if(CTScore >= get_pcvar_num(pCvarLimit) && (CTScore - TTScore >= 2))
		set_task(0.5, "MatchEnd");
}

public ChangeTeams()
{
	if(Change)
		return PLUGIN_CONTINUE;
		
	TT_Score = TTScore;
	CT_Score = CTScore;
	
	Change = true;
	
	for(new id = 1; id <= MaxPlayers; id++)
	{
		if(!is_user_connected(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) 
			continue;
			
		Kills[id] = get_user_frags(id);
		Deaths[id] = get_user_deaths(id);
		Team[id] = get_user_team(id);
		switch(get_user_team(id))
		{
			case CSTEAM_TERRORIST: cs_set_team(id, CSTEAM_CT);
			case CSTEAM_CT: cs_set_team(id, CSTEAM_TERRORIST);
		}
	}
	
	CT_Score > TT_Score ? ColorChat(0, BLUE, "Antyterrorysci^x01 wygrali pierwsza polowe i prowadza^x04 %i^x01 :^x04 %i^x01. Zamiana Druzyn!", CT_Score, TT_Score) 
	: ColorChat(0, RED, "Terrorysci^x01 wygrali pierwsza polowe i prowadza^x04 %i^x01 :^x04 %i^x01. Zamiana Druzyn!", TT_Score, CT_Score);
	
	RestartRound();
	
	return PLUGIN_CONTINUE;
}

public ChangeTeam()
{
	for(new id = 1; id <= MaxPlayers; id++)
	{
		if(!is_user_connected(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) 
			continue;
			
		if(get_user_team(id) == Team[id])
		{
			switch(get_user_team(id))
			{
				case CSTEAM_TERRORIST: cs_set_team(id, CSTEAM_CT);
				case CSTEAM_CT: cs_set_team(id, CSTEAM_TERRORIST);
			}
		}
	}
}

public RestartRound()
{
	set_task(0.1, "ChangeTeam");
	set_task(1.0, "RestoreStats");
	set_task(1.2, "ChangeScore");
}
	
public RestoreStats()
{
	for(new id = 1; id <= MaxPlayers; id++)
	{
		if(!is_user_connected(id) || is_user_hltv(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) 
			continue;
		
		new Team = get_user_team(id);
		set_user_frags(id, Kills[id]);
		cs_set_user_deaths(id, Deaths[id]);
		message_begin(MSG_ALL, gmsgScoreInfo);
		write_byte(id);
		write_short(Kills[id]);
		write_short(Deaths[id]);
		write_short(0);
		write_short(Team); 
		message_end();
	}
}

public ChangeScore(id)
{	
	SetTeamScore(TEAM_CT, TT_Score);
	SetTeamScore(TEAM_TT, CT_Score);
}

public MatchEnd()
{
	CTScore > TTScore ? ColorChat(0, BLUE, "Antyterrorysci^x01 wygrali mecz z wynikiem^x04 %i^x01 :^x04 %i^x01. Gratulujemy!", CTScore, TTScore) 
	: ColorChat(0, RED, "Terrorysci^x01 wygrali mecz z wynikiem^x04 %i^x01 :^x04 %i^x01. Gratulujemy!", TTScore, CTScore);
	
	new nextmap[33] 
	get_cvar_string("amx_nextmap", nextmap, 32)
	ColorChat(0, NORMAL, "Za^x04 10 sekund^x01 nastapi zmiana mapy na^x04 %s^x01!", nextmap);
	set_task(10.0, "ChangeMap");
}

public ChangeMap()
{
	new nextmap[33] 
	get_cvar_string("amx_nextmap", nextmap, 32)
	server_cmd("amx_map %s", nextmap) 
}

public SetTeamScore(team, score)
{
	new signedShort = 32768;
	new scoreToGive = clamp( score, -signedShort, signedShort );
	
	switch(team)
	{
		case TEAM_CT: set_mp_pdata("m_iNumCTWins", scoreToGive);
		case TEAM_TT: set_mp_pdata("m_iNumTerroristWins", scoreToGive);
		default : return PLUGIN_HANDLED;
	}

	UpdateTeamScores(.notifyAllPlugins = true);

	return PLUGIN_HANDLED;
}   

UpdateTeamScores (const bool:notifyAllPlugins = false)
{
	static OrpheuFunction:handleFuncUpdateTeamScores;

	if (!handleFuncUpdateTeamScores)
		handleFuncUpdateTeamScores = OrpheuGetFunction( "UpdateTeamScores", "CHalfLifeMultiplay")

	(notifyAllPlugins ) ? OrpheuCallSuper(handleFuncUpdateTeamScores, g_pGameRules) : OrpheuCall(handleFuncUpdateTeamScores, g_pGameRules);
}