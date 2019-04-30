#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <jailbreak>
#include <cstrike>

#define PLUGIN "JailBreak: Bomberman"
#define VERSION "1.0.9"
#define AUTHOR "Wielkie Jol"

new id_zabawa;

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    id_zabawa = jail_register_game("Bomberman");
}

public plugin_precache()
    precache_generic("sound/reload/bomberman.mp3");

public OnLastPrisonerWishTaken(id)
    OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		jail_set_ct_hit_tt(false);
		jail_set_god_ct(false);
	
		server_cmd("sv_gravity 800");
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{    
    if(day == id_zabawa)
    {
        formatex(szInfo2, charsmax(szInfo2), "Zasady:^nTerrorysci nawzajem zabijaja sie granatami.^nZAKAZ KAMPIENIA!");
		
        szInfo = "Bomberman";
        
        setting[0] = 1;
        setting[1] = 1;
        setting[2] = 1;
        setting[4] = 1;
        setting[7] = 2;
    }
}

public OnDayStartPost(day)
{
    if(day == id_zabawa)
    {
        jail_set_ct_hit_tt(true);
        jail_set_god_ct(true);
		
        jail_open_cele();
		
        jail_set_game_hud(15, "Rozpoczecie zabawy za");
    }
}

public OnGameHudEnd(day)
{
    if(day == id_zabawa)
    {
        jail_set_prisoners_fight(true, false, false);
		
        server_cmd("sv_gravity 350");

        client_cmd(0, "mp3 play sound/reload/bomberman.mp3");
		
        for(new i = 1; i <= MAX; i++)
		{
            if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T) continue;
			
            give_item(i, "weapon_hegrenade");
			
            cs_set_user_bpammo(i, CSW_HEGRENADE, 999);
        }
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
