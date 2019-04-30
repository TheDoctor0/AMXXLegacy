#include <amxmodx>
#include <engine>
#include <fakemeta>

#define VERSION "1.1"

new const g_szClassname[] = "colored_smokenade";

new g_szSmokeSprites[ 6 ];
new g_Cvar_Enabled;

public plugin_init( ) {
	register_plugin( "Colored Smoke", VERSION, "xPaw" );
	
	register_cvar( "colored_smoke", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "colored_smoke", VERSION );
	
	g_Cvar_Enabled = register_cvar( "sv_colored_smoke", "1" );
	
	register_forward( FM_EmitSound, "FwdEmitSound" );
	register_touch( g_szClassname, "worldspawn", "FwdTouch_FakeSmoke" );
	register_think( g_szClassname, "FwdThink_FakeSmoke" );
}

public plugin_precache( ) {
	g_szSmokeSprites[ 0 ] = precache_model( "sprites/gas_puff_01c.spr" );
	g_szSmokeSprites[ 1 ] = precache_model( "sprites/gas_puff_01r.spr" );
	g_szSmokeSprites[ 2 ] = precache_model( "sprites/gas_puff_01b.spr" );
	g_szSmokeSprites[ 3 ] = precache_model( "sprites/gas_puff_01g.spr" );
	g_szSmokeSprites[ 4 ] = precache_model( "sprites/gas_puff_01m.spr" );
	g_szSmokeSprites[ 5 ] = precache_model( "sprites/gas_puff_01o.spr" );
	
	precache_sound( "weapons/grenade_hit1.wav" );
}

public FwdEmitSound( iOrigEnt, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch ) {
	new iCvar = get_pcvar_num( g_Cvar_Enabled );
	if( iCvar > 0 ) {
		static const szSmokeSound[] = "weapons/sg_explode.wav";
		
		if( equal( szSample, szSmokeSound ) ) {
			// cache origin, angles and model
			new Float:vOrigin[ 3 ], Float:vAngles[ 3 ], szModel[ 64 ], iOwner;
			iOwner = entity_get_edict( iOrigEnt, EV_ENT_owner );
			entity_get_vector( iOrigEnt, EV_VEC_origin, vOrigin );
			entity_get_vector( iOrigEnt, EV_VEC_angles, vAngles );
			entity_get_string( iOrigEnt, EV_SZ_model, szModel, charsmax( szModel ) );
			
			// remove entity from world
			entity_set_vector( iOrigEnt, EV_VEC_origin, Float:{ 9999.9, 9999.9, 9999.9 } );
			entity_set_int( iOrigEnt, EV_INT_flags, FL_KILLME );
			
			// create new entity
			new iEntity = create_entity( "info_target" );
			if( iEntity > 0 ) {
				entity_set_string( iEntity, EV_SZ_classname, g_szClassname );
				
				entity_set_origin( iEntity, vOrigin );
				entity_set_vector( iEntity, EV_VEC_angles, vAngles );
				
				entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_TOSS );
				entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
				
				entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 21.5 );
				entity_set_float( iEntity, EV_FL_gravity, 0.5 );
				entity_set_float( iEntity, EV_FL_friction, 0.8 );
				
				entity_set_model( iEntity, szModel );
				
				new Float:vVelocity[ 3 ];
				vVelocity[ 0 ] = random_float( -220.0, 220.0 );
				vVelocity[ 1 ] = random_float( -220.0, 220.0 );
				vVelocity[ 2 ] = random_float(  200.0, 300.0 );
				entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
				
				emit_sound( iEntity, iChannel, szSample, fVol, fAttn, iFlags, iPitch );
				
				// Create fake smoke
				new iSmoke;
				
				if( iCvar == 2 )
					iSmoke = get_user_team( iOwner ); // i did indexes as team, 1 - red, 2 - blue, 3 - green( spec oO )
				else
					iSmoke = random_num( 0, 5 );
				
				// Store the smoke number in entity, we will use it later
				entity_set_int( iEntity, EV_INT_iuser4, iSmoke );
				
				message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
				write_byte( TE_FIREFIELD );
				engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
				engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
				engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 50 );
				write_short( 100 );
				write_short( g_szSmokeSprites[ iSmoke ] );
				write_byte( 100 );
				write_byte( TEFIRE_FLAG_ALPHA );
				write_byte( 1000 );
				message_end();
				
				message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
				write_byte( TE_FIREFIELD );
				engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
				engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
				engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 50 );
				write_short( 150 );
				write_short( g_szSmokeSprites[ iSmoke ] );
				write_byte( 10 );
				write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT );
				write_byte( 1000 );
				message_end( );
			}
		}
	}
}

public FwdTouch_FakeSmoke( iEntity, iWorld ) {
	if( !is_valid_ent( iEntity ) )
		return PLUGIN_CONTINUE;
	
	// Bounce sound
	emit_sound( iEntity, CHAN_VOICE, "weapons/grenade_hit1.wav", 0.25, ATTN_NORM, 0, PITCH_NORM );
	
	new Float:vVelocity[ 3 ];
	entity_get_vector( iEntity, EV_VEC_velocity, vVelocity );
	
	if( vVelocity[ 1 ] <= 0.0 && vVelocity[ 2 ] <= 0.0 ) {
		new Float:vOrigin[ 3 ];
		new iSmoke = entity_get_int( iEntity, EV_INT_iuser4 );
		entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
		
		// Make small smoke near grenade on ground
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_FIREFIELD );
		engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
		engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
		engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 10 );
		write_short( 2 );
		write_short( g_szSmokeSprites[ iSmoke ] );
		write_byte( 2 );
		write_byte( TEFIRE_FLAG_ALLFLOAT | TEFIRE_FLAG_ALPHA );
		write_byte( 30 );
		message_end();
	}
	
	return PLUGIN_CONTINUE;
}

public FwdThink_FakeSmoke( iEntity ) {
	if( !is_valid_ent( iEntity ) )
		return PLUGIN_CONTINUE;
	
	remove_entity( iEntity );
	
	return PLUGIN_CONTINUE;
}