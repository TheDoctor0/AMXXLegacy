#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <jailbreak>

#define PLUGIN "JailBreak: Ganiany"
#define VERSION "1.0.7"
#define AUTHOR "Cypis & O'Zone"

#define FALL_VELOCITY 250.0

new bool:bFall[33], bool:bGaniany, id_ganiany;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	id_ganiany = jail_register_game("Ganiany");
}

public plugin_precache()
	precache_generic("sound/reload/ganiany.mp3");
	
public plugin_natives()
	register_native("jail_is_ganiany", "jail_is_ganiany", 1);
	
public jail_is_ganiany()
	return bGaniany;

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{ 
	if(day == id_ganiany)
	{
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nStraznicy gonia Wiezniow^nBrak obrazen od upadku z wysokosci^nOstatni wiezien ma zyczenie^nNie wolno KAMPIC");
		
		szInfo = "Ganiany";

		for(new i = 1; i <= MAX; i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 2) continue;

			strip_user_weapons(i);
			
			give_item(i, "weapon_knife");
		}
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);

		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 3;
		setting[6] = 1;
	}
}

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_ganiany) bGaniany = false;
}

public OnDayStartPost(day)
{
	if(day == id_ganiany)
	{
		bGaniany = false;
		
		jail_set_all_speed(0.1, 2, 0);
		
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_ganiany)
	{
		if(!bGaniany)
		{
			jail_set_ct_hit_tt(false);
			
			jail_set_all_speed(600.0, 1, 1);
			jail_set_all_speed(600.0, 2, 1);
			
			client_cmd(0, "cl_forwardspeed 700");
			client_cmd(0, "cl_sidespeed 700");
			client_cmd(0, "cl_backspeed 700");

			client_cmd(0, "mp3 play sound/reload/ganiany.mp3");

			bGaniany = true;

			jail_set_game_hud(300, "Koniec zabawy za");
		}
		else
		{
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Zabawa dobiegla konca. Losowo zostal wybrany zwyciezca.");
			
			new iRandom = RandomPlayer(1);
			
			for(new i = 1; i <= MAX; i++)
			{
				if(!is_user_alive(i) || !is_user_connected(i) || get_user_team(i) != 1 || i == iRandom) continue;
			
				user_silentkill(i);
			}
		}
	}
}

public client_PreThink(id)
{
	if(is_user_alive(id))
	{
		if(entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY) bFall[id] = true;
		else bFall[id] = false;
	}
}

public client_PostThink(id)
	if(is_user_alive(id) && bFall[id] && bGaniany) entity_set_int(id, EV_INT_watertype, -3);

stock jail_set_all_speed(Float:speed, team, hp)
{
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || get_user_team(i) != team) continue;
		
		if(hp) set_user_health(i, 1); 
		
		jail_set_user_speed(i, speed);
	}
}