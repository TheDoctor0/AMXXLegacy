#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <ColorChat>
#include <StripWeapons>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>

#define PLUGIN	"Active Spectator"
#define AUTHOR	"O'Zone"
#define VERSION	"1.0"

#define IsPlayer(%1)  (1 <= %1 <= gMaxClients)

#define FALL_VELOCITY 350.0

// Hides Crosshair, Ammo, Weapons List ( CAL in code ). Players won't be able to switch weapons using list so it's not recommended
//#define HUD_HIDE_CAL (1<<0)

// Hides Flashlight, but adds Crosshair ( Flash in code )
#define HUD_HIDE_FLASH (1<<1)

// Hides Radar, Health & Armor, but adds Crosshair ( RHA in code )	
#define HUD_HIDE_RHA (1<<3)

// Hides Timer	
//#define HUD_HIDE_TIMER (1<<4)

// Hides Money
#define HUD_HIDE_MONEY (1<<5)

// Hides Crosshair ( Cross in code )
//#define HUD_HIDE_CROSS (1<<6)

// Draws additional Crosshair, NOT tested.
//#define HUD_DRAW_CROSS (1<<7)

new g_msgHideWeapon
new bool:spectator[33];
new bool:falling[33];
new old_team[33];
new gMaxClients;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_concmd("say /duch", "RespawnSpectator");
	register_concmd("say /ghost", "RespawnSpectator");
	
	register_event("CurWeapon", "CheckWeapons", "be");
	register_event("ResetHUD", "ResetHUD", "b");
	
	RegisterHam(Ham_TakeDamage, "player","NoDamage", 0);
	RegisterHam(Ham_Item_PreFrame, "player", "SetSpeed", 1);
	RegisterHam(Ham_Touch, "weaponbox","BlockWeapons");
	RegisterHam(Ham_Touch, "armoury_entity", "BlockWeapons");
	RegisterHam(Ham_Touch, "weapon_shield", "BlockWeapons");
	
	//register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1);
	register_forward(FM_PlayerPreThink, "GhostModeTouch");
	register_forward(FM_PlayerPostThink, "GhostModePlayer");
	register_forward(FM_CmdStart, "BlockImpulse");
	register_forward(FM_ClientKill, "BlockKill");
	register_forward(FM_EmitSound, "BlockSound", 0);
	
	g_msgHideWeapon = get_user_msgid("HideWeapon");
	gMaxClients = get_maxplayers();
}

public client_PreThink( id ){
	
	if( !is_user_alive( id ) || !spectator[id]){
		return PLUGIN_CONTINUE;
	}

	entity_set_float( id, EV_FL_fuser2, 0.0 );

	if (entity_get_int(id, EV_INT_button) & 2) {
		new flags = entity_get_int( id , EV_INT_flags );

		if (flags & FL_WATERJUMP || entity_get_int(id, EV_INT_waterlevel) >= 2 || !(flags & FL_ONGROUND) ){
			return PLUGIN_CONTINUE;
		}

		new Float:velocity[ 3 ];
		
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] += 250.0
		entity_set_vector(id, EV_VEC_velocity, velocity)

		entity_set_int(id, EV_INT_gaitsequence, 6)
	}
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
	spectator[id] = false;
	
public client_putinserver(id)
	spectator[id] = false;

public RespawnSpectator(id)
{
	if(!spectator[id])
	{
		ColorChat(id, GREEN, "[GHOST]^x01 Tryb aktywnego obserwatora zostal^x04 wlaczony^x01!");
		spectator[id] = true;
		GiveAbilities(id);
	}
	else
	{
		ColorChat(id, GREEN, "[GHOST]^x01 Tryb aktywnego obserwatora zostal^x04 wylaczony^x01!");
		TakeAbilities(id);
		user_silentkill(id);
		cs_set_user_deaths(id, cs_get_user_deaths(id)-1);
		spectator[id] = false;
	}
	return PLUGIN_CONTINUE;
}

public GiveAbilities(id)
{
	engclient_cmd(id, "drop", "weapon_c4");
	old_team[id] = get_user_team(id);
	new team = random_num(1, 2);
	cs_set_user_team(id, CsTeams:team);
	ExecuteHam(Ham_CS_RoundRespawn, id);
	cs_set_user_team(id, CsTeams:3);
	set_user_rendering(id, kRenderFxNone, 0,0,0, kRenderTransAlpha, 0);
	set_user_footsteps(id, 1);
	set_user_godmode(id, 1);
	set_task(0.1, "Reset", id);
}

public GiveKnife(id)
{
	fm_strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");
}

public Reset(id)
{
	ResetHUD(id);
	SetSpeed(id);
	set_user_maxspeed(id, 250.0);
	set_task(0.1, "GiveKnife", id);
}

public TakeAbilities(id)
{
	cs_set_user_team(id, CsTeams:old_team[id]);
	set_user_rendering(id, kRenderFxNone, 0,0,0, kRenderTransAlpha, 255);
	set_user_footsteps(id, 0);
	set_user_godmode(id, 0);
	set_user_maxspeed(id);
}

public BlockKill(id)
{
	if(spectator[id])
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public ResetHUD(id)
{
	if(!spectator[id])
		return;
		
	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
	{
		message_begin(MSG_ONE, g_msgHideWeapon, _, id)
		write_byte(iHideFlags)
		message_end()
	}	
}

public msgHideWeapon()
{
	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags)
}

GetHudHideFlags()
{
	new iFlags

//	iFlags |= HUD_HIDE_CAL
	iFlags |= HUD_HIDE_FLASH
	iFlags |= HUD_HIDE_RHA
//	iFlags |= HUD_HIDE_TIMER
	iFlags |= HUD_HIDE_MONEY 
//	iFlags |= HUD_HIDE_CROSS)
//	iFlags |= HUD_DRAW_CROSS

	return iFlags
}

public UpdateClientData_Post(id, sendweapons, cd_handle)
{
    if(!is_user_alive(id) || !spectator[id])
        return FMRES_IGNORED;
    
    set_cd(cd_handle, CD_ID, 0);        
    
    return FMRES_HANDLED;
}

public CheckWeapons(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;
	
	if(read_data(2) != CSW_KNIFE)
	{
		StripWeapons(id, Primary);
		StripWeapons(id, Secondary);
		StripWeapons(id, Grenades);
		StripWeapons(id, C4);
	}
	return PLUGIN_CONTINUE;
}

public NoDamage(victim, inflictor, attacker, Float:damage, bits) 
{
	if(!IsPlayer(victim) || !IsPlayer(attacker))
		return HAM_IGNORED;
		
	if(spectator[victim] || spectator[attacker])
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public SetSpeed(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;
		
	if(spectator[id])
		set_user_maxspeed(id, 250.0);

	return HAM_IGNORED;
}

public BlockWeapons(weapon, id)
{
	if(IsPlayer(id)){
		if(spectator[id])
			return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public GhostModeTouch(id)
{
	if(!spectator[id])
		return FMRES_IGNORED;
		
	set_pev(id, pev_solid, SOLID_SLIDEBOX)
	
	if(entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY)
		falling[id] = true;
	else
		falling[id] = false;

	return FMRES_IGNORED;
}

public GhostModePlayer(id)
{
	if(!spectator[id])
		return FMRES_IGNORED;
	
	set_pev(id, pev_solid, SOLID_NOT)
	
	if(falling[id])
		entity_set_int(id, EV_INT_watertype, -3);
		
	return FMRES_IGNORED;
}  

public BlockImpulse(id, uc_handle)
{	
	if(!spectator[id])
		return FMRES_IGNORED;

	if(get_uc(uc_handle,UC_Impulse) == 201) 
    { 
        set_uc(uc_handle, UC_Impulse, 0);
        return FMRES_HANDLED;
    } 

	return FMRES_IGNORED;
}

public BlockSound(ent, channel, const sample[], Float:volume, Float:attenuation, fFlags, pitch)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED;
		
	if(!is_user_alive(ent))
		return FMRES_IGNORED;
		
	if(spectator[ent])
		return FMRES_SUPERCEDE;
				
	return FMRES_IGNORED;
}