#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Wojna na sniezki"
#define VERSION "1.0.7"
#define AUTHOR "Cypis"

#define NADE_BALL 3351

#define MAX_BALL 10

new id_zabawa, bool:bGame, bool:bEnd;

new HamHook:hSpawn;
new HamHook:hItemDeployHE, fmSetModelGrenade, HamHook:hThinkGrenade, fmTouchGrenade;

native cs_set_player_model(id, newmodel[]);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	id_zabawa = jail_register_game("Wojna na sniezki");
}

public plugin_precache()
{
	precache_generic("models/player/mikolaj/mikolaj.mdl");
	
	precache_model("models/jb/sniezki/p.mdl");
	precache_model("models/jb/sniezki/v.mdl");
	precache_model("models/jb/sniezki/w.mdl");

	precache_generic("sound/reload/sniezki.mp3");
}

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		SetZabawa(false);
		fm_remove_entity_name("grenade");
		bGame = false;
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{
		formatex(szInfo2, 256, "Zasady:^nWalka wiezniow miedzy soba.^nWiezniowie dostaja 5 sniezek i rzucaja sie nimi.^nSniezki trzeba zbierac, gdy sie skoncza!^nZakaz Kampienia!");
		szInfo = "Wojna na sniezki";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		SetZabawa(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 0;
		setting[7] = 1;
		setting[8] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		bEnd = false;
		
		jail_open_cele();
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		if(!bEnd)
		{
			bEnd = true;

			jail_set_game_hud(300, "Koniec zabawy za");
			jail_set_game_end(300.0);
			
			set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
			show_hudmessage(0, "== BITWA NA SNIEZKI ==");

			client_cmd(0, "mp3 play sound/reload/sniezki.mp3");

			bGame = true;

			jail_set_prisoners_fight(true, false, false);

			for(new i=1; i<=MAX; i++)
			{
				if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T)
					continue;
				
				cs_set_player_model(i, "mikolaj");
				
				UstawPrzydzial(i);
			}
		}
	}
}

public fwSpawn(id)
{
	UstawPrzydzial(id);
}

public UstawPrzydzial(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return;
			
	if(get_user_team(id) != 1)
		return;
	
	strip_user_weapons(id);
	give_item(id, "weapon_hegrenade");
	cs_set_user_bpammo(id, CSW_HEGRENADE, 5);
}

public DajeBall(id, ent)
{
	if(get_user_team(id) != 1)
		return;
	
	new ammo = cs_get_user_bpammo(id, CSW_HEGRENADE);
	if(ammo == 0)
	{
		give_item(id, "weapon_hegrenade");
		
		set_pev(id, pev_viewmodel2, "models/jb/sniezki/v.mdl");	
		set_pev(id, pev_weaponmodel2, "models/jb/sniezki/p.mdl");
		
		fm_remove_entity(ent);
		
		return;
	}
	if(ammo >= MAX_BALL)
		return;

	cs_set_user_bpammo(id, CSW_HEGRENADE, ammo+1);
	fm_remove_entity(ent);
}

//////////////////////////////////
public SetZabawa(bool:wartosc)
{
	if(wartosc)
	{
		if(!hSpawn)
			hSpawn = RegisterHam(Ham_Spawn, "player", "fwSpawn", 1);
		else
			EnableHamForward(hSpawn);
		
		if(!hItemDeployHE)
			hItemDeployHE = RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fwWeaponHE", 1);
		else
			EnableHamForward(hItemDeployHE);
		
		if(!hThinkGrenade)
			hThinkGrenade = RegisterHam(Ham_Think, "grenade", "fwThinkGrenade");
		else
			EnableHamForward(hThinkGrenade);
		
		if(!fmSetModelGrenade)
			fmSetModelGrenade = register_forward(FM_SetModel, "fwSetModelGrenade");
		
		if(!fmTouchGrenade)
			fmTouchGrenade = register_forward(FM_Touch, "fwTouchGrenade");
	}
	else
	{
		if(hSpawn)
			DisableHamForward(hSpawn);
		
		if(hItemDeployHE)
			DisableHamForward(hItemDeployHE);
		
		if(hThinkGrenade)
			DisableHamForward(hThinkGrenade);
			
		if(fmSetModelGrenade)
		{
			unregister_forward(FM_SetModel, fmSetModelGrenade);
			fmSetModelGrenade = 0;
		}
		
		if(fmTouchGrenade)
		{
			unregister_forward(FM_Touch, fmTouchGrenade);
			fmTouchGrenade = 0;
		}
	}
}

public fwWeaponHE(ent)
{
	if(!bGame || !pev_valid(ent))
		return;
	
	new id = get_pdata_cbase(ent, 41, 4);
	if(!is_user_alive(id) || get_user_team(id) != 1)
		return;

	set_pev(id, pev_viewmodel2, "models/jb/sniezki/v.mdl");	
	set_pev(id, pev_weaponmodel2, "models/jb/sniezki/p.mdl");
}

public fwThinkGrenade(ent)
{   
	if(!bGame || !pev_valid(ent)) 
		return HAM_IGNORED;

	new Float:dmgtime;
	pev(ent, pev_dmgtime, dmgtime);

	if(dmgtime > get_gametime())
		return HAM_IGNORED;

	if(pev(ent, pev_flTimeStepSound) == NADE_BALL)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public fwSetModelGrenade(ent, const model[])
{
	if(!bGame || !pev_valid(ent)) 
		return HAM_IGNORED;
	
	new Float:dmgtime;
	pev(ent, pev_dmgtime, dmgtime);

	if(dmgtime == 0.0)
		return HAM_IGNORED;

	if(!equal(model,"models/w_hegrenade.mdl"))
		return HAM_IGNORED;
	
	fm_entity_set_model(ent, "models/jb/sniezki/w.mdl");
	fm_entity_set_size(ent, Float:{-6.0,-6.0,-6.0},Float:{6.0,6.0,6.0});

	set_pev(ent, pev_friction, 0.6);
	set_pev(ent, pev_iuser1, 0);
	set_pev(ent, pev_flTimeStepSound, NADE_BALL);
	
	new id = pev(ent, pev_owner);
	
	new Float:fVelocity[3];
	velocity_by_aim(id, 800, fVelocity);
	set_pev(ent, pev_velocity, fVelocity);
	
	//set_pev(ent, pev_gravity, 0.4);
	
	set_task(5.0, "stop_roll", ent);
	return HAM_SUPERCEDE;
}

public stop_roll(ent) 
{
	if(!bGame || !pev_valid(ent))
		return;
	
	if(!(pev(ent, pev_flags) & FL_ONGROUND))
	{
		set_task(5.0, "stop_roll", ent);
		return;
	}

	set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(ent, pev_gravity, 1.0);
}

public fwTouchGrenade(ent, id)
{
	if(!bGame || !pev_valid(ent))
		return;

	if(pev(ent, pev_flTimeStepSound) != NADE_BALL)
		return;
	
	if(is_user_alive(id))
	{
		if(pev(ent, pev_iuser1) == 0)
		{
			if(!bGame)
				return;
				
			new Float:fOrigin[3], Float:fVelocity[3];
			pev(ent, pev_origin, fOrigin);
			get_velocity_from_origin(id, fOrigin, 5120.0, fVelocity);
			fVelocity[2] = 512.0;
			set_pev(id, pev_velocity, fVelocity);
			
			ExecuteHamB(Ham_TakeDamage, id, ent, pev(ent, pev_owner), 150.0, DMG_BULLET);
		}
		else
		{
			DajeBall(id, ent);
		}
	}
	else
	{
		set_pev(ent, pev_owner, 0);
		set_pev(ent, pev_iuser1, 1);
	}
}


public get_velocity_from_origin(ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3]) 
{
	new Float:fEntOrigin[3];
	pev(ent, pev_origin,fEntOrigin);

	// Velocity = Distance / Time

	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0];
	fDistance[1] = fEntOrigin[1] - fOrigin[1];
	fDistance[2] = fEntOrigin[2] - fOrigin[2];

	new Float:fTime = ( vector_distance( fEntOrigin,fOrigin ) / fSpeed );

	fVelocity[0] = fDistance[0] / fTime;
	fVelocity[1] = fDistance[1] / fTime;
	fVelocity[2] = fDistance[2] / fTime;

	return (fVelocity[0] && fVelocity[1] && fVelocity[2]);
}
