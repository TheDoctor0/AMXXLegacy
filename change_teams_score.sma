#include <amxmodx>
#include <amxmisc>
#include <orpheu>
#include <orpheu_memory>
#include <cstrike>
#include <fun>
#include <ColorChat>

#define set_mp_pdata(%1,%2)  (OrpheuMemorySetAtAddress(g_pGameRules, %1, 1, %2))
#define get_mp_pdata(%1)	 (OrpheuMemoryGetAtAddress(g_pGameRules, %1))

#define TEAM_CT 1
#define TEAM_TT 2

new CT_MODELS[4][] = {"sas","gsg9","urban","gign"};
new TT_MODELS[4][] = {"arctic","leet","guerilla","terror"};

new g_pGameRules;

new pCvarLimit;
new pCvarScores;

new TTScore;
new CTScore;

new gmsgScoreInfo;

new MaxPlayers;

new bool:Switch;
new bool:MatchEnd;

public plugin_init ()
{
	register_plugin( "Switch Teams with Scores", "1.0", "O'Zone" );
	
	pCvarLimit = register_cvar("teams_win_limit","6");
	
	pCvarScores = register_cvar("players_keep_scores","1");
	
	register_event("TeamScore", "tt_score", "a", "1=TERRORIST");
	
	register_event("TeamScore", "ct_score", "a", "1=CT");
	
	register_event("TextMsg", "Restart", "a", "2&#Game_C", "2&#Game_w");
	
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
	
	MaxPlayers = get_maxplayers();
}

public plugin_precache()
	OrpheuRegisterHook(OrpheuGetFunction( "InstallGameRules" ), "OnInstallGameRules", OrpheuHookPost);

public OnInstallGameRules()
	g_pGameRules = OrpheuGetReturn();
	
public Restart()
{
	Switch = false;
	MatchEnd = false;
}

public tt_score()
{
	TTScore = read_data(2);
	
	if(TTScore == get_pcvar_num(pCvarLimit) || TTScore == get_pcvar_num(pCvarLimit)*2)
		ChangeTeams();
}

public ct_score()
{
	CTScore = read_data(2);
	
	if(CTScore == get_pcvar_num(pCvarLimit) || CTScore == get_pcvar_num(pCvarLimit)*2)
		ChangeTeams();
}

public ChangeTeams()
{
	new CT_SCORE = CTScore;
	new TT_SCORE = TTScore;
	
	for(new id = 1; id <= MaxPlayers; id++ )
	{
		if(!is_user_connected(id) || is_user_hltv(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) 
			continue;
			
		if(!Switch)
		{
			CT_SCORE > TT_SCORE ? ColorChat(id, BLUE, "Antyterrorysci^x01 wygrali pierwsza polowe i prowadza^x04 %i^x01 :^x04 %i^x01. Zamiana Druzyn!", CT_SCORE, TT_SCORE) 
			: ColorChat(id, RED, "Terrorysci^x01 wygrali pierwsza polowe i prowadza^x04 %i^x01 :^x04 %i^x01. Zamiana Druzyn!", TT_SCORE, CT_SCORE);

			cs_set_user_team(id, cs_get_user_team(id) == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT);
		
			new Model = random_num(0,3);
			cs_set_user_model(id, cs_get_user_team(id) == CS_TEAM_CT ? TT_MODELS[Model]: CT_MODELS[Model]);
		
			cs_set_user_money(id, 800);
		
			if(!get_pcvar_num(pCvarScores))
			{
				new team = get_user_team(id);
				cs_set_user_deaths(id, 0);
				set_user_frags(id, 0);
			
				message_begin(MSG_ALL, gmsgScoreInfo)
				write_byte(id)  
				write_short(0) 
				write_short(0) 
				write_short(0) 
				write_short(team) 
				message_end()
			}
			else
			{	
				CT_SCORE > TT_SCORE ? ColorChat(id, BLUE, "Antyterrorysci^x01 wygrali mecz z wynikiem^x04 %i^x01 :^x04 %i^x01. Gratulujemy!", CT_SCORE, TT_SCORE) 
				: ColorChat(id, RED, "Terrorysci^x01 wygrali mecz z wynikiem^x04 %i^x01 :^x04 %i^x01. Gratulujemy!", TT_SCORE, CT_SCORE);
				MatchEnd = true;
			}
		}
	}
	
	if(!MatchEnd)
	{
		Switch = true;
	
		SetTeamScore(TEAM_CT, TT_SCORE);
		SetTeamScore(TEAM_TT, CT_SCORE);
	}
	
	return PLUGIN_CONTINUE;
}

public SetTeamScore(team, score)
{
	new signedShort = 32768;
	new scoreToGive = clamp( score, -signedShort, signedShort );
	
	switch(team)
	{
		case TEAM_CT:
		{
			set_mp_pdata("m_iNumCTWins", scoreToGive);
		}
		case TEAM_TT:
		{
			set_mp_pdata("m_iNumTerroristWins", scoreToGive);
		}
		default :
		{
			return PLUGIN_HANDLED;
		}
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