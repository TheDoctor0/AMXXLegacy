#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: FreeDay"
#define VERSION "1.0.9"
#define AUTHOR "Cypis"

#define TASK_END 9032
#define TASK_FIGHT 7865

new bool:bRespawn, id_zabawa;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	id_zabawa = jail_register_game("FreeDay dla Wszystkich");
	
	register_event("DeathMsg", "DeathMsg", "a");
	register_event("TeamInfo", "TeamAssign", "a");
	
	register_logevent("RoundEnd", 2, "1=Round_End");
}

public plugin_precache()
	precache_generic("sound/reload/freeday.mp3");
	
public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		jail_remove_game_hud();
	
		remove_task(TASK_END);
		remove_task(TASK_FIGHT);
	
		bRespawn = false;
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa || day == NIEDZIELA)
	{
		formatex(szInfo2, charsmax(szInfo2), "FreeDay trwa 90 sekund.^nPotem Wiezniowie dostaja AK47^ni walcza ze Straznikami.^nWalka trwa 60 sekund^nKazdy TT kiedy zginie^nzostaje ozywiony ponownie.");
		
		szInfo = "FreeDay";
		
		jail_set_prowadzacy(0);
		jail_set_prisoners_micro(true, true);
		jail_set_god_ct(true);
		jail_set_god_tt(true);
		
		setting[0] = 2;
		setting[1] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa || day == NIEDZIELA)
	{
		client_cmd(0, "mp3 play sound/reload/freeday.mp3");

		jail_open_cele();
		
		set_task(90.0, "GameEnd", TASK_END);
		
		bRespawn = true;
	}
}

public GameEnd()
{
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i)) continue;
		
		if(get_user_team(i) == 1)
		{
			give_item(i, "weapon_ak47");
			
			give_item(i, "ammo_762nato");
			give_item(i, "ammo_762nato");
			give_item(i, "ammo_762nato");
			
			client_print_color(i, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Koniec Freedaya. Dostales AK47 - zapoluj na Straznikow!");
		}
		if(get_user_team(i) == 2) set_user_health(i, 250);
	}
	
	jail_set_god_ct(false);
	jail_set_god_tt(false);

	bRespawn = false;
	
	set_task(60.0, "RoundFight", TASK_FIGHT);
}

public RoundEnd()
{
	remove_task(TASK_END);
	remove_task(TASK_FIGHT);
	
	bRespawn = false;
}

public DeathMsg()
{
	new victim = read_data(2);
	
	if(!is_user_connected(victim) || get_user_team(victim) != 1 || !bRespawn) return;

	set_task(0.1, "Respawn", victim);
}

public Respawn(id)
	ExecuteHamB(Ham_CS_RoundRespawn, id);

public RoundFight()
{
	for(new i = 1; i <= MAX; i++)
	{
		if(is_user_alive(i) && get_user_team(i) == 1)
		{
			user_silentkill(i);
			
			cs_set_user_deaths(i, cs_get_user_deaths(i) - 1);
			
			client_print_color(i, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Koniec walki ze Straznikami!");
		}
	}
}

public TeamAssign()
{
	if(!bRespawn) return;
	
	new szTeam[16], id = read_data(1);
	
	read_data(2, szTeam, charsmax(szTeam));
	
	if(equal(szTeam, "TT")) set_task(0.1, "Respawn", id);
}