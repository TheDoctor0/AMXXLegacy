#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <engine>
#include <jailbreak>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "JailBreak: Szybki jak blyskawica"
#define VERSION "1.0.7"
#define AUTHOR "Wielkie Jol"

#define IsPlayer(%1) (1<=%1<=maxPlayers)

new id_zabawa;
new HamHook: hDmg, HamHook:hBron, HamHook:hBron2;
new maxPlayers;
new bool:bGame;

native cs_set_player_model(id, newmodel[]);

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_zabawa = jail_register_game("Strus Pedziwiatr");
}

public plugin_precache()
	precache_generic("sound/reload/szybki.mp3");

public plugin_cfg() maxPlayers=get_maxplayers();

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		bGame = false;
		
		for(new i=1; i<=32; i++)
		{
			if(is_user_alive(i) & get_user_team(i) == 2) jail_set_user_speed(i, -1.0);
			if(is_user_connected(i) & get_user_team(i) == 1) cs_set_user_zoom(i, CS_RESET_ZOOM, 1);
		}
		if(hDmg)
			DisableHamForward(hDmg);
		if(hBron)
			DisableHamForward(hBron);
		if(hBron2)
			DisableHamForward(hBron2);
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{
		formatex(szInfo2, 256, "Zasady:^nKlawisze maja bardzo malo hp, sa bardzo szybcy i zabijaja na raz^nWiezniowie maja tylko scouta bez zooma i musza zabic straznikow.^nZAKAZ KAMPIENIA!");
		szInfo = "Strus Pedziwiatr";
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		bGame = true;
		
		jail_open_cele();
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public HamTouchPre(weapon, id){
	if(!bGame || !pev_valid(weapon) || !IsPlayer(id) || !is_user_alive(id)){
		return HAM_IGNORED;
	}
	new name[20];
	pev(weapon, pev_model, name, 19);
	if(containi(name, "w_backpack")!=-1){
		return HAM_IGNORED;
	}
	return HAM_SUPERCEDE;
}

public TakeDamage(id, ent, attacker){
	if(!bGame) return HAM_IGNORED;
	
	if(is_user_alive(attacker) && get_user_team(attacker) == 2 && get_user_weapon(attacker) == CSW_KNIFE)
	{
		cs_set_user_armor(id, 0, CS_ARMOR_NONE);
		SetHamParamFloat(4, float(get_user_health(id) + 1));
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		jail_set_ct_hit_tt(false);
		jail_set_god_ct(false);

		client_cmd(0, "mp3 play sound/reload/szybki.mp3");
		
		for(new i=1; i<=32; i++)
		{
			if(is_user_alive(i) && get_user_team(i) == 2)
			{
				strip_user_weapons(i);
				give_item(i, "weapon_knife");
				jail_set_user_speed(i, 2000.0);
				set_user_maxspeed(i, 2000.0);
				set_user_health(i, 10);
			}
			if(is_user_alive(i) && get_user_team(i) == 1)
			{
				strip_user_weapons(i);
				give_item(i, "weapon_scout");
				cs_set_user_bpammo(i, CSW_SCOUT, 90);
				cs_set_user_zoom(i, CS_SET_NO_ZOOM, 0);
			}
		}
		if(!hDmg)
			hDmg = RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
		else
			EnableHamForward(hDmg);
		if(!hBron)
			hBron = RegisterHam(Ham_Touch, "weaponbox", "HamTouchPre", 0);
		else
			EnableHamForward(hBron);
		if(!hBron2)
			hBron2 = RegisterHam(Ham_Touch, "armoury_entity", "HamTouchPre", 0);
		else
			EnableHamForward(hBron2);
	}
}

