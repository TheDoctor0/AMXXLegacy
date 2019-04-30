#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <jailbreak>
 
#define PLUGIN "JailBreak: Predator"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

#define TASK_END 81932
#define TASK_FOG 91432

#define RADIUS 250.0
#define FROST_DURATION 4.0
#define FROST_CODE 32379
#define ICE_MODEL "models/jailbreak/iceblock.mdl"
#define GRENADE_MODEL "models/jailbreak/v_grenade_frost.mdl"
 
new iIceEnt[33], iPredator, iFrostGrenade, id_zabawa, gGlass, gGrenadeTrail, 
gFrostGib, gFrost, gExplosion, gMsgDamage, gMsgScreenFade, gHudSyncObj;

new CSW_MAXAMMO[33] = {-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1};
 
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("CurWeapon", "EventCurWeapon", "be", "1=1")
 
	id_zabawa = jail_register_game("Predator");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	
	register_forward(FM_SetModel, "SetModel");
	register_forward(FM_Touch, "Touch");
	
	register_message(get_user_msgid("Health"), "MessageHealth");
	
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "ItemDeployPost", 1);
	RegisterHam(Ham_Killed, "player", "PlayerKilled");
	
	gMsgDamage = get_user_msgid("Damage");
	gMsgScreenFade = get_user_msgid("ScreenFade");
	
	gHudSyncObj = CreateHudSyncObj();
}

public plugin_precache()
{
	gGrenadeTrail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
	gFrost = precache_model("sprites/frost_exp.spr");
	gExplosion = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");
	gFrostGib = precache_model("sprites/frostgib.spr");
	gGlass = engfunc(EngFunc_PrecacheModel, "models/glassgibs.mdl");
	
	precache_generic("models/player/predator/predator.mdl");
	
	engfunc(EngFunc_PrecacheModel, ICE_MODEL);
	engfunc(EngFunc_PrecacheModel, GRENADE_MODEL);
	
	engfunc(EngFunc_PrecacheSound, "warcraft3/frostnova.wav");
	engfunc(EngFunc_PrecacheSound, "warcraft3/impalehit.wav");
	engfunc(EngFunc_PrecacheSound, "warcraft3/impalelaunch1.wav");
}
 
public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{ 
	static szTime[12];
	if(day == id_zabawa)
	{
		static szTimes[12];
 
		format_time(szTimes, 11, "%M:%S", gTimeRound-60);
		formatex(szInfo2, 255, "Zasady:^n%s - Wiezniowie maja 30s na rozstawienie sie na mapie.^nProwadzacy staje sie Predatorem i ma za zadanie polowac na wiezniow.^n% ^nOstatni wiezien ma Zyczenie^n", szTime, szTimes);
		szInfo = "Dzisiaj jest Predator";
 
		jail_set_prisoners_micro(true, true);
		jail_set_god_ct(true);
		jail_set_god_tt(false);
		jail_set_ct_hit_tt(true);
		
		for(new id = 1; id <= MAX; id++)
		{
			if(!is_user_alive(id))
				continue;
				
			if(get_user_team(id) == 2)
				jail_set_user_speed(id, 0.1);
		}
 
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 0;
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

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		for(new id = 1; id <= MAX; id++)
		{
			if(!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;
			
			if(is_user_alive(id))
			{
				set_user_health(id, 100);
				set_user_gravity(id, 1.0);	
			}
			
			Rem(id, iFrostGrenade);
			Rem(id, iPredator);
		}
		
		remove_task(TASK_FOG);
		
		jail_set_god_ct(false);

		CreateFog(0, .clear = true);
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== Predator rozpoczal polowanie! ==");
		
		jail_set_ct_hit_tt(false);
		
		set_task(0.5, "ApplyFog", TASK_FOG, _, _, "b");
		
		for(new id = 1; id <= MAX; id++)
		{
			if(!is_user_alive(id))
				continue;
				
			switch(get_user_team(id))
			{
				case 1:
				{
					set_user_health(id, 1000);
					give_item(id, "smokegrenade");
					
					Set(id, iFrostGrenade);
				}
				case 2:
				{
					if(id == jail_get_prowadzacy())
					{
						give_item(id, "weapon_m249");
						give_item(id, "ammo_556natobox");
						
						cs_set_user_model(id, "predator");
						
						fm_set_user_nvg(id, 1);
						
						engclient_cmd(id, "nightvision");
						
						set_user_gravity(id, 0.4);
						
						jail_set_user_speed(id, 350.0);
						
						Set(id, iPredator);
					}
					else
						jail_set_user_speed(id, 250.0);
				}
			}
		}
	}
}

public ApplyFog()
{
	for(new id = 1; id <= MAX; id++)
	{
		if(!is_user_alive(id))
			continue;

		CreateFog(id, 0, 0, 0, 0.01);
		
		cmd_execute(id, "gl_fog 1");
	}
}

public MessageHealth(iMsgId, MSG_DEST, id)
{
    new iHealth = get_user_health(id);
	
    if(iHealth > 255)
	{
		set_msg_arg_int(1, ARG_BYTE, 255);
		
		set_hudmessage(255, 255, 255, 0.01, 0.87, 2, 0.02, 1000.0, 0.1, 3.0, -1);
		ShowSyncHudMsg(id, gHudSyncObj, "Zycie: %d", iHealth);
	}
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id) || !Get(id, iPredator))
		return PLUGIN_CONTINUE;
	
	new iWeaponID = read_data(2);
	
	if(iWeaponID == CSW_C4 || iWeaponID == CSW_KNIFE || iWeaponID == CSW_HEGRENADE || iWeaponID == CSW_SMOKEGRENADE || iWeaponID == CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
	
	if(cs_get_user_bpammo(id, iWeaponID) != CSW_MAXAMMO[iWeaponID])
		cs_set_user_bpammo(id, iWeaponID, CSW_MAXAMMO[iWeaponID]);
	
	return PLUGIN_CONTINUE;
}

public ItemDeployPost(weapon_ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(weapon_ent);
	
	if(!pev_valid(id))
		return;
	
	if(!Get(id, iFrostGrenade))
		return;
		
	set_pev(id, pev_viewmodel2, GRENADE_MODEL);
}

public Touch(pfn, ptd)
{
	if(!pev_valid(pfn))
		return;
	
	static Classname[32]; pev(pfn, pev_classname, Classname, sizeof(Classname))
	if(equal(Classname, "grenade"))
	{
		if(pev(pfn, pev_iuser2) != FROST_CODE)
			return;

		FrostExplode(pfn);
		
		set_pev(pfn, pev_iuser2, 0);
		
		engfunc(EngFunc_RemoveEntity, pfn);
	}
}

FrostExplode(ent)
{
	static Float:originF[3], Owner;
	pev(ent, pev_origin, originF);
	Owner = pev(ent, pev_owner);
	
	CreateBlast(originF);
	
	emit_sound(ent, CHAN_WEAPON, "warcraft3/frostnova.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	static Float:PlayerOrigin[3]
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue;
		if(cs_get_user_team(i) == cs_get_user_team(Owner))
			continue;
			
		pev(i, pev_origin, PlayerOrigin);
		
		if(get_distance_f(originF, PlayerOrigin) > RADIUS)
			continue;
			
		if(!is_user_connected(Owner)) Owner = i;
		
		FrozePlayer(i);
		
		message_begin(MSG_ONE_UNRELIABLE, gMsgDamage, _, i);
		write_byte(0);
		write_byte(0);
		write_long(DMG_DROWN);
		write_coord(0);
		write_coord(0);
		write_coord(0);
		message_end();
		
		emit_sound(i, CHAN_BODY, "warcraft3/impalehit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		message_begin(MSG_ONE, gMsgScreenFade, _, i);
		write_short(0);
		write_short(0);
		write_short(0x0004);
		write_byte(0);
		write_byte(50);
		write_byte(200);
		write_byte(100);
		message_end();

		set_task(FROST_DURATION, "RemoveFreeze", i);
	}
}

public RemoveFreeze(id)
{
	if(!is_user_alive(id))
		return;
		
	message_begin(MSG_ONE, gMsgScreenFade, _, id);
	write_short((1<<12));
	write_short(0);
	write_short(0x0000);
	write_byte(0);
	write_byte(50);
	write_byte(200);
	write_byte(100);
	message_end();
	
	IceEntity(id, 0);
	
	emit_sound(id, CHAN_BODY, "warcraft3/impalelaunch1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	static origin2[3];
	get_user_origin(id, origin2);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin2);
	write_byte(TE_BREAKMODEL);
	write_coord(origin2[0]);
	write_coord(origin2[1]);
	write_coord(origin2[2]+24);
	write_coord(16);
	write_coord(16);
	write_coord(16);
	write_coord(random_num(-50, 50));
	write_coord(random_num(-50, 50));
	write_coord(25);
	write_byte(10);
	write_short(gGlass);
	write_byte(10);
	write_byte(25);
	write_byte(0x01);
	message_end();
}

public SetModel(entity, const model[])
{
	if(strlen(model) < 8)
		return;
	
	if(model[9] == 's' && model[10] == 'm' && model[11] == 'o' && model[12] == 'k' && model[13] == 'e' && model[14] == 'g' && Get(pev(entity, pev_owner), iFrostGrenade))
	{
		fm_set_rendering(entity, kRenderFxGlowShell, 84, 231, 247, kRenderNormal, 16);
		
		set_pev(entity, pev_iuser2, FROST_CODE);
		Rem(pev(entity, pev_owner), iFrostGrenade);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(entity);
		write_short(gGrenadeTrail);
		write_byte(10);
		write_byte(10);
		write_byte(0);
		write_byte(191);
		write_byte(255);
		write_byte(200);
		message_end();
	}
}

public NewRound()
{
	for(new i = 0; i < MAX; i++)
		IceEntity(i, 0);
}

public PlayerKilled(id)
	IceEntity(id, 0);

public FrozePlayer(id)
	IceEntity(id, 1);

stock IceEntity(id, status) 
{
	if(status)
	{
		static ent, Float:o[3]
		if(!is_user_alive(id))
		{
			IceEntity(id, 0)
			return;
		}
		
		if(is_valid_ent(iIceEnt[id]))
		{
			if(pev(iIceEnt[id], pev_iuser3) != id)
			{
				if(pev(iIceEnt[id], pev_team) == 6969)
					remove_entity(iIceEnt[id]);
			}
			else
			{
				pev(id, pev_origin, o);
				
				if(pev( id, pev_flags) & FL_DUCKING ) o[2] -= 15.0;
				else o[2] -= 35.0;
				
				entity_set_origin(iIceEnt[id], o);
				return;
			}
		}
		
		pev(id, pev_origin, o);
		
		if(pev( id, pev_flags) & FL_DUCKING) o[2] -= 15.0;
		else o[2] -= 35.0;
		
		ent = create_entity("info_target");
		set_pev(ent, pev_classname, "IceEntity");
		
		entity_set_model(ent, ICE_MODEL);
		dllfunc(DLLFunc_Spawn, ent);
		set_pev(ent, pev_solid, SOLID_BBOX);
		set_pev(ent, pev_movetype, MOVETYPE_FLY);
		entity_set_origin(ent, o);
		entity_set_size(ent, Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 });
		set_pev(ent, pev_iuser3, id);
		set_pev(ent, pev_team, 6969);
		set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255);
		iIceEnt[id] = ent;
	}
	else
	{
		if(is_valid_ent(iIceEnt[id]))
		{
			if(pev(iIceEnt[id], pev_team) == 6969) 
				remove_entity(iIceEnt[id]);
			iIceEnt[id] = -1;
		}
	}
}

CreateBlast(const Float:originF[3])
{
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0);
    write_byte(TE_BEAMCYLINDER);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2]);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2] + 470.0);
    write_short(gExplosion);
    write_byte(0);
    write_byte(0);
    write_byte(4);
    write_byte(60);
    write_byte(0);
    write_byte(0);
    write_byte(191);
    write_byte(255);
    write_byte(200);
    write_byte(0);
    message_end();
    
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0);
    write_byte(TE_BEAMCYLINDER);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2]);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2] + 555.0);
    write_short(gExplosion);
    write_byte(0);
    write_byte(0);
    write_byte(4);
    write_byte(60);
    write_byte(0);
    write_byte(0);
    write_byte(191);
    write_byte(255);
    write_byte(200);
    write_byte(0);
    message_end()
    
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0);
    write_byte(TE_DLIGHT);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2]);
    write_byte(50);
    write_byte(0);
    write_byte(191);
    write_byte(255);
    write_byte(30);
    write_byte(30);
    message_end();

    engfunc(EngFunc_MessageBegin, MSG_BROADCAST,SVC_TEMPENTITY, originF, 0);
    write_byte(TE_EXPLOSION);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2] + 10);
    write_short(gFrost);
    write_byte(17);
    write_byte(15);
    write_byte(TE_EXPLFLAG_NOSOUND);
    message_end();
    
    engfunc(EngFunc_MessageBegin, MSG_BROADCAST,SVC_TEMPENTITY, originF, 0);
    write_byte(TE_SPRITETRAIL);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2] + 40);
    engfunc(EngFunc_WriteCoord, originF[0]);
    engfunc(EngFunc_WriteCoord, originF[1]);
    engfunc(EngFunc_WriteCoord, originF[2]);
    write_short(gFrostGib);
    write_byte(30);
    write_byte(10);
    write_byte(4);
    write_byte(50);
    write_byte(10);
    message_end();
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_pdata_cbase(ent, 41, 4);
}

stock CreateFog(const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false)
{
	static msgFog;
	
	if(!msgFog)
		msgFog = get_user_msgid("Fog");
	
	new density = _:floatclamp(density_f, 0.0001, 0.25) * _:!clear;
	message_begin(index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index);
	write_byte(clamp(red, 0, 255));
	write_byte(clamp(green, 0, 255));
	write_byte(clamp(blue, 0, 255));
	write_byte((density & 0xFF));
	write_byte((density >>  8) & 0xFF);
	write_byte((density >> 16) & 0xFF);
	write_byte((density >> 24) & 0xFF);
	message_end();
}

stock fm_set_user_nvg(id, onoff = 1) 
{
    new nvg = get_pdata_int(id, 129);

    set_pdata_int(id, 129, onoff ? nvg | (1<<0) : nvg & ~(1<<0));

    return 1;
}

stock cmd_execute(id, const szText[], any:...) 
{
	#pragma unused szText

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);
	
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}