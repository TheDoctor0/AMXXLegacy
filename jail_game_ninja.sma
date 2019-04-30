#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <jailbreak>
#include <xs>

#define PLUGIN "JailBreak: Ninja Day"
#define VERSION "1.1"
#define AUTHOR "kIImIIz & O'Zone"

#define fm_get_user_button(%1) pev(%1, pev_button)	
#define fm_get_entity_flags(%1) pev(%1, pev_flags)

new const maxAmmo[31] = { 0, 52, 0, 90, 1, 31, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 31, 90, 120, 90, 2, 35, 90, 90, 0, 100 };

new Float:fWallOrigin[32][3], bool:bGame, id_ninja;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	id_ninja = jail_register_game("Ninja Day");
	
	register_forward(FM_Touch, "Touch");
	register_forward(FM_PlayerPreThink, "PlayerPrething");
}

public plugin_precache()
	precache_generic("sound/reload/ninja.mp3");

public OnRemoveData(day)
{
	if(day == id_ninja) 
	{
		set_lights("#OFF");
		
		bGame = false;
	}
}

public OnLastPrisonerWishTaken(day)
	OnRemoveData(jail_get_play_game_id());

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_ninja)
	{
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nWiezniowie maja 15 sekund na schownie sie^nWszyscy moga skakac odbijajac sie od scian.^nStraznicy musza wyeliminowac wiezniow.");
		
		szInfo = "Ninja Day";
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(false);
		jail_set_tt_hit_ct(false);
		
		setting[0] = 1;  
		setting[1] = 1;
		setting[2] = 1;
		setting[3] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 2;
	}
}

public OnDayStartPost(day)
{
	if(day == id_ninja)
	{
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
		
		set_lights("b");
	}
}

public OnGameHudEnd(day)
{
	if(day != id_ninja) return;
	
	if(!bGame)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "=== NINJA DAY ROZPOCZAL SIE ===");

		client_cmd(0, "mp3 play sound/reload/ninja.mp3");
	
		jail_open_cele();
	
		bGame = true;
		
		jail_set_game_hud(300, "Koniec zabawy za");
	
		for(new i = 1; i <= 32; i++)
		{
			if(!is_user_alive(i) || !is_user_connected(i)) continue;
		
			if(cs_get_user_team(i) != CS_TEAM_T)
			{
				strip_user_weapons(i);
			
				give_item(i, "weapon_knife");
				give_item(i, "weapon_tmp");
			
				cs_set_user_bpammo(i, CSW_TMP, maxAmmo[CSW_TMP]);
			
				set_user_health(i, 500);
			
				set_user_rendering(i, kRenderFxGlowShell, 0, 0, 100, kRenderNormal, 30);
			}
			else
			{
				strip_user_weapons(i);
			
				give_item(i, "weapon_knife");
			
				jail_set_user_speed(i, 500.0);
			
				set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 10);
			
				set_user_footsteps(i, 1);
			
				set_user_maxspeed(i, 500.0);
			}
		}
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

public Touch(id, world, day)
{
	if(!bGame || !is_user_alive(id) || day != id_ninja) return FMRES_IGNORED;
	
	new szClassName[33];
	
	pev(world, pev_classname, szClassName, charsmax(szClassName));
	
	if(equal(szClassName, "worldspawn") || equal(szClassName, "func_wall") || equal(szClassName, "func_breakable")) pev(id, pev_origin, fWallOrigin[id]);
	
	return FMRES_IGNORED;
}

public PlayerPrething(id) 
{		
	if(!bGame || !is_user_alive(id)) return FMRES_IGNORED;
	
	new iButton = fm_get_user_button(id);
	
	if(iButton & IN_USE)
	{
		static Float:fOrigin[3];
		
		pev(id, pev_origin, fOrigin);
		
		if(get_distance_f(fOrigin, fWallOrigin[id]) > 10.0 || fm_get_entity_flags(id) & FL_ONGROUND) return FMRES_IGNORED;
		
		if(iButton & IN_FORWARD)
		{
			velocity_by_aim(id, 120, fOrigin);
			
			fm_set_user_velocity(id, fOrigin);
		}
		else if(iButton & IN_BACK)
		{
			velocity_by_aim(id, -120, fOrigin);
			
			fm_set_user_velocity(id, fOrigin);
		}
	}
	else if((iButton & IN_JUMP) && iButton & IN_DUCK)
	{
		static Float:fOrigin[3];
		
		pev(id, pev_origin, fOrigin);
		
		if(get_distance_f(fOrigin, fWallOrigin[id]) > 10.0 || fm_get_entity_flags(id) & FL_ONGROUND) return FMRES_IGNORED;
		
		if(iButton & IN_FORWARD)
		{
			velocity_by_aim(id, 120, fOrigin);
			
			fm_set_user_velocity(id, fOrigin);
		}
		else if(iButton & IN_BACK)
		{
			velocity_by_aim(id, -120, fOrigin);
			
			fm_set_user_velocity(id, fOrigin);
		}
	}
	
	return FMRES_IGNORED;
}

stock fm_set_user_velocity(entity, const Float:vector[3]) 
{
	set_pev(entity, pev_velocity, vector);
	
	return 1;
}