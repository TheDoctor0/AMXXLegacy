#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "JailBreak: Headshot Day"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define HEADSHOT (1<<1)

new bool:headshot;

new id_zabawa;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_TraceLine, "Fwd_TraceLine", 1);
	id_zabawa = jail_register_game("HeadShot Day");
}

public plugin_precache()
	precache_generic("sound/reload/hs.mp3");

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
		formatex(szInfo2, 256, "Wieznowie maja 15s na rozstawienie sie na mapie.^nPo ich uplywie wybieraja bronie.^nMoga strzelac jedynie w glowe.");
		szInfo = "HeadShot Day";

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

		client_cmd(0, "mp3 play sound/reload/hs.mp3");
		
		for(new i = 1; i <= MAX; i++)
		{
			if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T) continue;

			new menu = menu_create("\wMenu Broni: \rWybierz Zestaw", "menu_handler");
			
			menu_additem(menu, "\yM4A1 + Deagle", "0", 0);
			menu_additem(menu, "\yAK47 + Deagle", "1", 0);
			menu_additem(menu, "\yFamas + Deagle", "2", 0);
			
			menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
			menu_display(i, menu);
		}
	}
}

public menu_handler(id, menu, item)
{
	if(!is_user_alive(id) || !headshot) return PLUGIN_HANDLED;

	strip_user_weapons(id);

	give_item(id, "weapon_knife");
	give_item(id, "weapon_deagle");
	
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	
	switch(item)
	{		
		case 0: 
		{
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 1:
		{
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 2:
		{
			give_item(id, "weapon_famas");
			cs_set_user_bpammo(id, CSW_FAMAS, 90);
		}
	}
	return PLUGIN_HANDLED;
}

public Fwd_TraceLine(Float:StartPos[3],Float:EndPos[3], SkipMonsters, id, Trace)
{
	if(!is_user_connected(id) || !is_user_alive(id) || !headshot)
		return FMRES_IGNORED;

	new Victim = get_tr2(Trace, TR_pHit);
	
	if(!is_user_alive(Victim))
		return FMRES_IGNORED;
	
	new HitGroup = (1<<get_tr2(Trace, TR_iHitgroup));

	if(!(HitGroup & HEADSHOT))
	{
		set_tr2(Trace, TR_flFraction, 1.0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}