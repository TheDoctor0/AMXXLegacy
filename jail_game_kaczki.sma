#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Kaczki"
#define VERSION "1.0.8"
#define AUTHOR "Cypis & O'Zone"

#define TASK_MINMODELS 8435

new bool:bDucks, id_zabawa;

native cs_set_player_model(id, newmodel[]);

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	id_zabawa = jail_register_game("Kaczki vs AWP");
}

public plugin_precache()
{
	precache_model("models/rpgrocket.mdl");
	
	precache_generic("models/player/kaczki/kaczki.mdl");
	precache_generic("sound/reload/kaczki.mp3");
}

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		client_cmd(0, "mp3 stop");
		
		remove_task(TASK_MINMODELS);

		for(new i = 1; i <= MAX; i++)
		{
			if(!is_user_connected(i)) continue;

			set_view(i, CAMERA_NONE);
		}
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nWiezniowie maja 15 sekund na schownie sie^nCT dostaje AWP, a nastepnie szuka^n i zabija uciekajace kaczki");
		
		szInfo = "Kaczki vs AWP";
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 3;
		setting[6] = 1;
		setting[7] = 2;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		bDucks = false;
		
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
		
		jail_set_users_speed(0.1);
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		if(!bDucks)
		{
			jail_set_game_hud(300, "Koniec zabawy za");
			jail_set_game_end(300.0);
			
			jail_set_ct_hit_tt(false);
		
			jail_set_users_speed(-1.0);
			
			client_cmd(0, "mp3 play sound/reload/kaczki.mp3");
			
			set_task(1.0, "set_minmodels", TASK_MINMODELS, .flags = "b");
			
			bDucks = true;
		}
	}
}

stock jail_set_users_speed(Float:speed)
{
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i)) continue;
			
		if(get_user_team(i) == 1)
		{
			strip_user_weapons(i);
			
			cs_set_player_model(i, "kaczki");

			set_view(i, CAMERA_3RDPERSON);
		}
		else
		{
			if(speed == 0.1)
			{
				strip_user_weapons(i);
				
				give_item(i, "weapon_awp");
				
				cs_set_user_bpammo(i, CSW_AWP, 30);
			}
			
			jail_set_user_speed(i, speed);
		}
	}
}

public set_minmodels()
{
	new iPlayers[32], iNum;
	
	get_players(iPlayers, iNum);
	
	for(new i = 0; i < iNum; i++)
	{
		if(is_user_alive(iPlayers[i]))
		{
			cmd_execute(iPlayers[i], "cl_minmodels ^"0^"");
			
			client_cmd(iPlayers[i], "echo ^"^";^"cl_minmodels^" ^"0^"");
			
			client_cmd(iPlayers[i], "cl_minmodels 0");
		}
	}
}

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256];

    	format_args(szMessage ,charsmax(szMessage), 1);

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
        write_byte(strlen(szMessage) + 2);
        write_byte(10);
        write_string(szMessage);
        message_end();
    }
}
