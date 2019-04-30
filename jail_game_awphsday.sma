#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "JailBreak: AWP Headshot Day"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define HEADSHOT (1<<1)

new bool:headshot;

new id_zabawa;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_TraceLine, "Fwd_TraceLine", 1);
	id_zabawa = jail_register_game("AWP HeadShot Day");
}

public plugin_precache()
	precache_generic("sound/reload/awp.mp3");

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa) headshot = false;
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{
		formatex(szInfo2, 255, "Zasady:^nWieznowie maja 15s na rozstawienie sie na mapie.^nPo ich uplywie dostaja AWP.^nMoga strzelac jedynie w glowe.");
		szInfo = "AWP HeadShot Day";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);

		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		jail_open_cele();
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		headshot = true;
		
		jail_set_prisoners_fight(true, false, false);

		client_cmd(0, "mp3 play sound/reload/awp.mp3");
		
		for(new i = 1; i <= MAX; i++)
		{
			if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T) continue;
			
			strip_user_weapons(i);
			
			give_item(i, "weapon_knife");
			
			give_item(i, "weapon_awp");
			cs_set_user_bpammo(i, CSW_AWP, 30);
		}
	}
}

public Fwd_TraceLine(Float:StartPos[3],Float:EndPos[3], SkipMonsters, id, Trace)
{
	if(!headshot || !is_user_connected(id) || !is_user_alive(id)) return FMRES_IGNORED;

	new Victim = get_tr2(Trace, TR_pHit);
	
	if(!is_user_alive(Victim)) return FMRES_IGNORED;
	
	new HitGroup = (1<<get_tr2(Trace, TR_iHitgroup));

	if(!(HitGroup & HEADSHOT))
	{
		set_tr2(Trace, TR_flFraction, 1.0);
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}