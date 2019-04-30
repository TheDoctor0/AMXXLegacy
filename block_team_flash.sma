/**
 * Team Flash Blocker
 * Written by GwynBleidD
 * based on Connor's Team Flash Punish v1.1.1
 */

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Team Flash Blocker"
#define VERSION "1.2"
#define AUTHOR "GwynBleidD & O'Zone"

#define TEAM_NONE	0
#define TEAM_TT		1
#define TEAM_CT		2
#define TEAM_SPEC	3

#define TASK_FLASH	3829
#define MAX_PLAYERS	32

#define IsPlayer(%1) (1 <= %1 <= iMaxPlayers)

#define SetGrenadeExplode(%1) bitGonnaExplode[%1>>5] |= 1<<(%1 & 31)
#define ClearGrenadeExplode(%1) bitGonnaExplode[%1>>5] &= ~( 1 << (%1 & 31))
#define WillGrenadeExplode(%1) bitGonnaExplode[%1>>5] & 1<<(%1 & 31)

new bitGonnaExplode[64], bool:bCurrentFlashed[MAX_PLAYERS + 1], iTeam[MAX_PLAYERS + 1], Float:fCurrentGameTime, iCurrentFlasher, iMaxPlayers, msgScreenFade;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("ScreenFade", "Event_ScreenFade", "be", "4=255", "5=255", "6=255", "7>199");
	register_event("TeamInfo", "Join_Team", "a");
	
	RegisterHam(Ham_Think, "grenade", "CGrenade_Think");
	
	msgScreenFade = get_user_msgid("ScreenFade");

	iMaxPlayers = get_maxplayers();
}

public client_putinserver(id)
	bCurrentFlashed[id] = false;

public client_disconnected(id)
	iTeam[id] = TEAM_NONE;

public Join_Team()
{
	new id, szTeam[2];
	
	id = read_data(1);
	read_data(2, szTeam, charsmax(szTeam));
	
	switch(szTeam[0])
	{
		case 'T': iTeam[id] = TEAM_TT;
		case 'C': iTeam[id] = TEAM_CT;
		default: iTeam[id] = TEAM_SPEC;
	}
	
	return PLUGIN_CONTINUE;
}

public CGrenade_Think(iEnt)
{
	static Float:fGameTime, Float:fDmgTime, iOwner;
	
	fGameTime = get_gametime();
	
	pev(iEnt, pev_dmgtime, fDmgTime);
	
	if(fDmgTime <= fGameTime && get_pdata_int(iEnt, 114, 5) == 0 && !(get_pdata_int(iEnt, 96, 5) & (1<<8)) && IsPlayer((iOwner = pev(iEnt, pev_owner))))
	{
		if(~WillGrenadeExplode(iEnt)) SetGrenadeExplode(iEnt);
		else
		{
			ClearGrenadeExplode(iEnt);
			
			fCurrentGameTime = fGameTime;
			iCurrentFlasher = iOwner;
		}
	}
}

public Event_ScreenFade(id)
{
	if(!is_user_connected(id)) return;

	new Float:fGameTime = get_gametime();
	
	if(id != iCurrentFlasher && fCurrentGameTime == fGameTime && !bCurrentFlashed[id] && iTeam[id] == iTeam[iCurrentFlasher])
	{
		message_begin(MSG_ONE, msgScreenFade, {0, 0, 0}, id);
		write_short(1);
		write_short(1);
		write_short(1);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		message_end();

		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if(!is_user_connected(i) || pev(i, pev_iuser2) != id || i == id) continue;
			
			message_begin(MSG_ONE, msgScreenFade, {0, 0, 0}, i);
			write_short(1);
			write_short(1);
			write_short(1);
			write_byte(0);
			write_byte(0);
			write_byte(0);
			write_byte(255);
			message_end();
		}
	}
	else if(!bCurrentFlashed[id])
	{
		bCurrentFlashed[id] = true;
		
		set_task(2.0, "RemoveFlash", id + TASK_FLASH);
	}
}

public RemoveFlash(id)
{
	id -= TASK_FLASH;
	
	bCurrentFlashed[id] = false;
}