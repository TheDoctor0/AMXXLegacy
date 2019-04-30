#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <jailbreak>

#define PLUGIN "JailBreak: Chuck Norris"
#define VERSION "1.0.7"
#define AUTHOR "k4x4z5"

new id_1h1;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_1h1 = jail_register_game("Chuck Norris Style");
}

public plugin_precache()
	precache_generic("sound/reload/chuck.mp3");

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_1h1)
	{
		formatex(szInfo2, 255, "Zasady:^nWieznowie maja 15s na rozstawienie sie na mapie.^nPo ich uplywie dostaja krowy.^nWiezniowie walcza miedzy soba.");
		szInfo = "Chuck Norris Style";
		
		for(new i=1; i<=MAX; i++){
			if(is_user_alive(i) && is_user_connected(i) && get_user_team(i) == 1){
				strip_user_weapons(i);
				give_item(i, "weapon_m249")
				cs_set_user_bpammo(i, CSW_M249, 999);
				set_user_health(i, 1000)
			}
		}
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 0;
		setting[2] = 1;
		setting[4] = 1;
	}
}

public OnDayStartPost(day){
	if(day == id_1h1){
		jail_open_cele();
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day){
	if(day == id_1h1)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== TT vs TT ==");

		client_cmd(0, "mp3 play sound/reload/chuck.mp3");
		
		jail_set_prisoners_fight(true, false, false);
	}
}