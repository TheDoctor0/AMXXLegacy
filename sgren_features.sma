/**
 *
 * Smoke Grenade Features
 *  by Numb
 *
 *
 * Description:
 *  This plugin fixes some smoke grenade related bugs:
 *  + Ability to see through smoke.
 *  + Ability to see through smoke even better if using 16 bit.
 *  + Smoke grenades do not explode in air.
 *  + Smoke can go through walls.
 *  + Smoke grenades can and do lag up many players (fps drops).
 *
 *
 * Requires:
 *  FakeMeta
 *  HamSandWich
 *
 *
 * Additional Info:
 *  + Tested in Counter-Strike 1.6 with amxmodx 1.8.1 (with and without 16 bit).
 *
 *
 * ChangeLog:
 *
 *  + 1.4
 *  - Changed: Improved cheat protection.
 *  - Changed: Smoke disappears 10 seconds faster (now it's 35 seconds and value can be changed in source code config).
 *
 *  + 1.3
 *  - Fixed: Damaged archives - no need to download sprites.
 *  - Added: Ability to see through smoke even better when standing inside of it (can be changed in source code config).
 *  - Added: Ability to make certain percentage of smoke to be black. Supports only original version "sgren_features".
 *
 *  + 1.2
 *  - Fixed: svc_bad errors.
 *
 *  + 1.1
 *  - Fixed: Smoke is more dense (harder to see through it where it ends).
 *  - Fixed: Easier to see through smoke when you are standing inside of it.
 *
 *  + 1.0
 *  - First release.
 *
 *
 * Downloads:
 *  Amx Mod X forums: http://forums.alliedmods.net/showthread.php?p=970945#post970945
 *
**/



// ========================================================================= CONFIG START =========================================================================

// Radius in units from smoke grenade where smoke can be created. Float number type is needed
#define SMOKE_MAX_RADIUS 125.0 // default: (200.0)

// Number of smoke puffs what will be created every 0.1sec from one grenade (the higher this value is - the higher is ability of getting svc_bad errors)
#define SMOKE_PUFFS_PER_THINK 3 // default: (5)

// How long smoke will stay on until it disappears (in seconds). NOTE: Counter-Strike default is 25.0
#define SMOKE_LIFE_TIME 25.0 // default (35.0)

// How much percent of the smoke will be black? (NOTE: Using this feature can make smoke to go throw roof)
#define SMOKE_BLACK_PERCENT 0 // default: (0)

// Ability to see throw smoke better when standing inside of it (one of ???) (setting it to 0 will remove this feature)
#define VIEW_ABILITY 0 // default: (3)

// ========================================================================== CONFIG END ==========================================================================



#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME	"Smoke Grenade Features"
#define PLUGIN_VERSION	"1.4"
#define PLUGIN_AUTHOR	"Numb"

#define SGF1 ADMIN_CVAR
#define SGF2 ADMIN_MAP
#define SGF3 ADMIN_SLAY
#define SGF4 ADMIN_BAN
#define SGF5 ADMIN_KICK
#define SGF6 ADMIN_RESERVATION
#define SGF7 ADMIN_IMMUNITY

new g_iSpriteWhite;
new g_iSpriteBlack;
#if VIEW_ABILITY > 0
new g_iMaxPlayers;
new bool:g_bIsUserConnected[33];
#endif

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_forward(FM_SetModel, "FM_SetModel_Pre", 0);
	
	RegisterHam(Ham_Think, "grenade", "Ham_Think_grenade_Pre", 0);
	
#if VIEW_ABILITY > 0
	g_iMaxPlayers = clamp(get_maxplayers(), 1, 32);
#endif
}

// Before being a smart ass make sure do you really want to decode this and get more cheaters online.
// Even though most C++ coders never worked with FLAG system and don't know what some AMXX natives do,
// I know that most of you (AMXX coders) easily can read the 'hidden' information.
// So do me and yourself a favor - DON'T! 
public plugin_precache()
{
	new integer28Cells[28];
	
#if SMOKE_BLACK_PERCENT < 100
	integer28Cells[0]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[1]  = (SGF3|SGF2|SGF1);
	integer28Cells[2]  = (SGF6|SGF3|SGF2|SGF1);
	integer28Cells[3]  = (SGF7|SGF4|SGF2|SGF1);
	integer28Cells[4]  = (SGF5|SGF3|SGF2|SGF1);
	integer28Cells[5]  = (SGF7|SGF5|SGF2|SGF1);
	integer28Cells[6]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[7]  = (SGF7|SGF6|SGF5|SGF4|SGF2);
	integer28Cells[8]  = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[9]  = (SGF7|SGF2|SGF1);
	integer28Cells[10] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[11] = (SGF5|SGF3|SGF2|SGF1);
	integer28Cells[12] = (SGF7|SGF6|SGF5|SGF4|SGF3|SGF1);
	integer28Cells[13] = (SGF7|SGF6|SGF5|SGF3|SGF2|SGF1);
	integer28Cells[14] = (SGF7|SGF2|SGF1);
	integer28Cells[15] = (SGF5|SGF4|SGF2|SGF1);
	integer28Cells[16] = (SGF5|SGF4|SGF2|SGF1);
	integer28Cells[17] = (SGF3|SGF2|SGF1);
	integer28Cells[18] = (SGF7|SGF5|SGF3|SGF2|SGF1);
	integer28Cells[19] = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[20] = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[21] = (SGF7|SGF3|SGF2);
	integer28Cells[22] = (SGF6|SGF5|SGF4|SGF2);
	integer28Cells[23] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[24] = (SGF3|SGF2|SGF1);
	integer28Cells[25] = (SGF6|SGF3|SGF2|SGF1);
	
	if( contain(integer28Cells, "sprites/ballsmoke.spr") )
	{
		g_iSpriteWhite = precache_model(integer28Cells);
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, integer28Cells);
	}
	else
	{
		g_iSpriteWhite = precache_model("sprites/ballsmoke.spr");
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, "sprites/ballsmoke.spr");
	}
#endif
#if SMOKE_BLACK_PERCENT > 0
	integer28Cells[0]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[1]  = (SGF3|SGF2|SGF1);
	integer28Cells[2]  = (SGF6|SGF3|SGF2|SGF1);
	integer28Cells[3]  = (SGF7|SGF4|SGF2|SGF1);
	integer28Cells[4]  = (SGF5|SGF3|SGF2|SGF1);
	integer28Cells[5]  = (SGF7|SGF5|SGF2|SGF1);
	integer28Cells[6]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[7]  = (SGF7|SGF6|SGF5|SGF4|SGF2);
	integer28Cells[8]  = (SGF6|SGF2|SGF1);
	integer28Cells[9]  = (SGF5|SGF4|SGF2|SGF1);
	integer28Cells[10] = (SGF7|SGF2|SGF1);
	integer28Cells[11] = (SGF7|SGF6|SGF2|SGF1);
	integer28Cells[12] = (SGF7|SGF6|SGF4|SGF2|SGF1);
	integer28Cells[13] = (SGF7|SGF6|SGF5|SGF4|SGF3|SGF1);
	integer28Cells[14] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[15] = (SGF7|SGF5|SGF4|SGF2|SGF1);
	integer28Cells[16] = (SGF7|SGF6|SGF5|SGF4|SGF2|SGF1);
	integer28Cells[17] = (SGF7|SGF6|SGF4|SGF2|SGF1);
	integer28Cells[18] = (SGF7|SGF5|SGF2|SGF1);
	integer28Cells[19] = random(2)?(SGF7|SGF6|SGF3|SGF2):(SGF5|SGF3|SGF2);
	integer28Cells[20] = (SGF6|SGF5|SGF4|SGF2);
	integer28Cells[21] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[22] = (SGF3|SGF2|SGF1);
	integer28Cells[23] = (SGF6|SGF3|SGF2|SGF1);
	integer28Cells[24] = 0;
	integer28Cells[25] = 0;
	
	if( contain(integer28Cells, "sprites/bloodspray.spr") )
	{
		g_iSpriteWhite = precache_model(integer28Cells);
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, integer28Cells);
	}
	else
	{
		g_iSpriteBlack = precache_model("sprites/bloodspray.spr");
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, "sprites/bloodspray.spr");
	}
#endif
}

#if VIEW_ABILITY > 0
public client_putinserver(iPlrId)
	g_bIsUserConnected[iPlrId] = true;

public client_disconnect(iPlrId)
	g_bIsUserConnected[iPlrId] = false;
#endif

public FM_SetModel_Pre(iEnt, iModel[])
{
	if( pev_valid(iEnt) )
	{
		static s_iClassName[9];
		pev(iEnt, pev_classname, s_iClassName, 8);
		
		if( equal(s_iClassName, "grenade") && equal(iModel, "models/w_smokegrenade.mdl") )
			set_pev(iEnt, pev_iuser1, 3);
	}
}

public Ham_Think_grenade_Pre(iEnt)
{
	if( pev(iEnt, pev_iuser1)==3 )
	{
		static Float:s_fDmgTime, Float:s_fGameTime;
		pev(iEnt, pev_dmgtime, s_fDmgTime);
		global_get(glb_time, s_fGameTime);
		
		if( s_fGameTime>=s_fDmgTime )
		{
			set_pev(iEnt, pev_dmgtime, (s_fGameTime+SMOKE_LIFE_TIME));
			if( !pev(iEnt, pev_iuser4) )
			{
				emit_sound(iEnt, CHAN_WEAPON, "weapons/sg_explode.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_pev(iEnt, pev_iuser4, 1);
			}
			else
				set_pev(iEnt, pev_flags, (pev(iEnt, pev_flags)|FL_KILLME));
		}
		else if( !pev(iEnt, pev_iuser4) )
			return HAM_IGNORED;
		
		static Float:s_fOrigin[3], Float:s_fEndOrigin[3];
		pev(iEnt, pev_origin, s_fOrigin);
		s_fEndOrigin = s_fOrigin;
		s_fEndOrigin[2] += random_float(8.0, 32.0);
		
		static Float:s_fFraction;
		engfunc(EngFunc_TraceLine, s_fOrigin, s_fEndOrigin, IGNORE_MONSTERS, iEnt, 0);
		get_tr2(0, TR_flFraction, s_fFraction);
		
		if( s_fFraction!=1.0 )
			get_tr2(0, TR_pHit, s_fOrigin);
		else
			s_fOrigin = s_fEndOrigin;
		
		static s_iLoopId, Float:s_fDistance;
#if VIEW_ABILITY > 0
		static s_iPlrId, Float:s_fPlrOrigin[3]
#endif
		for( s_iLoopId=0; s_iLoopId<SMOKE_PUFFS_PER_THINK; s_iLoopId++ )
		{
			s_fEndOrigin[0] = random_float((random(2)?-50.0:-80.0), 0.0);
			s_fEndOrigin[1] = random_float((s_iLoopId*(360.0/SMOKE_PUFFS_PER_THINK)), ((s_iLoopId+1)*(360.0/SMOKE_PUFFS_PER_THINK)));
			s_fEndOrigin[2] = -20.0;
			while( s_fEndOrigin[1]>180.0 )
				s_fEndOrigin[1] -= 360.0;
			
			engfunc(EngFunc_MakeVectors, s_fEndOrigin);
			global_get(glb_v_forward, s_fEndOrigin);
			s_fEndOrigin[0] *= 9999.0;
			s_fEndOrigin[1] *= 9999.0;
			s_fEndOrigin[2] *= 9999.0;
			s_fEndOrigin[0] += s_fOrigin[0];
			s_fEndOrigin[1] += s_fOrigin[1];
			s_fEndOrigin[2] += s_fOrigin[2];
			
			engfunc(EngFunc_TraceLine, s_fOrigin, s_fEndOrigin, IGNORE_MONSTERS, iEnt, 0);
			get_tr2(0, TR_vecEndPos, s_fEndOrigin);
			
			if( (s_fDistance=get_distance_f(s_fOrigin, s_fEndOrigin))>(s_fFraction=(random(3)?random_float((SMOKE_MAX_RADIUS*0.5), SMOKE_MAX_RADIUS):random_float(16.0, SMOKE_MAX_RADIUS))) )
			{
				s_fFraction /= s_fDistance;
				
				if( s_fEndOrigin[0]!=s_fOrigin[0] )
				{
					s_fDistance = (s_fEndOrigin[0]-s_fOrigin[0])*s_fFraction;
					s_fEndOrigin[0] = (s_fOrigin[0]+s_fDistance);
				}
				if( s_fEndOrigin[1]!=s_fOrigin[1] )
				{
					s_fDistance = (s_fEndOrigin[1]-s_fOrigin[1])*s_fFraction;
					s_fEndOrigin[1] = (s_fOrigin[1]+s_fDistance);
				}
				if( s_fEndOrigin[2]!=s_fOrigin[2] )
				{
					s_fDistance = (s_fEndOrigin[2]-s_fOrigin[2])*s_fFraction;
					s_fEndOrigin[2] = (s_fOrigin[2]+s_fDistance);
				}
			}
			
#if VIEW_ABILITY > 0
			static bool:s_bBlackSmoke;
			s_bBlackSmoke = (random(100)<SMOKE_BLACK_PERCENT)?true:false;
			for( s_iPlrId=1; s_iPlrId<=g_iMaxPlayers; s_iPlrId++ )
			{
				if( g_bIsUserConnected[s_iPlrId] )
				{
					pev(s_iPlrId, pev_origin, s_fPlrOrigin);
					
					if( get_distance_f(s_fPlrOrigin, s_fEndOrigin)>(SMOKE_MAX_RADIUS*0.5) || random(VIEW_ABILITY) )
					{
						message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, s_iPlrId);
						if( s_bBlackSmoke )
						{
							write_byte(TE_SMOKE);
							engfunc(EngFunc_WriteCoord, s_fEndOrigin[0]);
							engfunc(EngFunc_WriteCoord, s_fEndOrigin[1]);
							engfunc(EngFunc_WriteCoord, (s_fEndOrigin[2]-32.0));
							write_short(g_iSpriteBlack);
							write_byte(random_num(30, 34));
							write_byte(18);
						}
						else
						{
							write_byte(TE_SPRITE);
							engfunc(EngFunc_WriteCoord, s_fEndOrigin[0]);
							engfunc(EngFunc_WriteCoord, s_fEndOrigin[1]);
							engfunc(EngFunc_WriteCoord, s_fEndOrigin[2]);
							write_short(g_iSpriteWhite);
							write_byte(random_num(18, 22));
							write_byte(127);
						}
						message_end();
					}
				}
			}
#else
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			if( random(100)<SMOKE_BLACK_PERCENT )
			{
				write_byte(TE_SMOKE);
				engfunc(EngFunc_WriteCoord, s_fEndOrigin[0]);
				engfunc(EngFunc_WriteCoord, s_fEndOrigin[1]);
				engfunc(EngFunc_WriteCoord, (s_fEndOrigin[2]-32.0));
				write_short(g_iSpriteBlack);
				write_byte(random_num(30, 34));
				write_byte(18);
			}
			else
			{
				write_byte(TE_SPRITE);
				engfunc(EngFunc_WriteCoord, s_fEndOrigin[0]);
				engfunc(EngFunc_WriteCoord, s_fEndOrigin[1]);
				engfunc(EngFunc_WriteCoord, s_fEndOrigin[2]);
				write_short(g_iSpriteWhite);
				write_byte(random_num(18, 22));
				write_byte(127);
			}
			message_end();
#endif
		}
	}
	
	return HAM_IGNORED;
}
