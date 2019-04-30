#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <jailbreak>
#include <hamsandwich>

#define PLUGIN "JailBreak: KillDay"
#define VERSION "1.0.8"
#define AUTHOR "Cypis & O'Zone"

new const maxAmmo[31] = { 0, 52, 0, 90, 1, 31, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 31, 90, 120, 90, 2, 35, 90, 90, 0, 100 };

new const gWeapon[] = { 3, 5, 7, 8, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 27, 28, 30 };

new HamHook:hKilled, bool:bKillDay, id_killday;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_killday = jail_register_game("KillDay");
}

public plugin_precache()
	precache_generic("sound/reload/killday.mp3");

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_killday) SetKillDay(false);
}
	
public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_killday)
	{
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nWiezniowie maja 15 sekund na rozstawienie sie po mapie.^nNastepnie dostaja Deagle^n i walcza miedzy soba.^nOstatni dwaj wiezniowie walcza na noze.");
		
		szInfo = "KillDay";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 0;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_killday)
	{
		SetKillDay(true);
		
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_killday)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== TT vs TT ==");

		client_cmd(0, "mp3 play sound/reload/killday.mp3");
		
		new szWeapon[24], iWeapon = gWeapon[random(charsmax(gWeapon))];
	
		get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));
	
		for(new i = 1; i <= MAX; i++)
		{
			if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_T) continue;

			strip_user_weapons(i);
		
			give_item(i, "weapon_knife");
			give_item(i, "weapon_deagle");
		
			give_item(i, szWeapon);
		
			cs_set_user_bpammo(i, iWeapon, maxAmmo[iWeapon]);
			cs_set_user_bpammo(i, CSW_DEAGLE, maxAmmo[CSW_DEAGLE]);
		}
		
		jail_set_prisoners_fight(true, false, false);
	}
}

public SetKillDay(bool:value)
{
	if(value)
	{
		bKillDay = true;
		
		if(!hKilled) RegisterHam(Ham_Killed, "player", "Ham_Killed_Post", 1);
		else EnableHamForward(hKilled);
	}
	else
	{
		bKillDay = false;
		
		if(hKilled) DisableHamForward(hKilled);
	}
}

public Ham_Killed_Post(vid, kid)
{
	if(!bKillDay) return PLUGIN_CONTINUE;
	
	new iGroup = 0;
	
	for(new id = 1; id <= MAX; id++) if(is_user_alive(id) && get_user_team(id) == 1) ++iGroup;
	
	if(iGroup == 2)
	{
		for(new i = 1; i <= MAX; i++)
		{
			if(is_user_alive(i) && get_user_team(i) == 1)
			{
				strip_user_weapons(i);
				
				give_item(i, "weapon_knife");
				
				set_user_health(i, 200);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}