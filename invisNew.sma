/*	
@author Rafal "DarkGL" Wiecek 
@site www.darkgl.amxx.pl
*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <nvault>

const maxPlayer = 32;

new g_bPlayerInvisible[ maxPlayer + 1 ],
	bool:g_bWaterInvisible[ maxPlayer + 1];
	
new Array: gWaterEntity;

new invis, water;

new bHookVisible = 0;

public plugin_init( )
{
	register_plugin( "Invis", "1.0", "DarkGL");
	
	gWaterEntity = ArrayCreate( 1 , 1 );
	
	register_clcmd( "say /invis", "menuInvisDisplay" );
	register_clcmd( "say_team /invis" , "menuInvisDisplay" );
	
	register_menucmd( register_menuid( "" ), ( 1<<0 | 1<<1 | 1<<9  ) , "MenuInvis" );
	
	register_forward( FM_AddToFullPack, "fwdAddToFullPack_Pre" );
	register_forward( FM_AddToFullPack, "fwdAddToFullPack_Post" , 1 );
	
	register_forward( FM_CheckVisibility,"checkVisibility");
	
	invis = nvault_open( "invis" );
	if( invis == INVALID_HANDLE )
		set_fail_state( "Nie mozna otworzyc pliku invis.vault" );
		
	water = nvault_open( "water" );
	if( water == INVALID_HANDLE )
		set_fail_state( "Nie mozna otworzyc pliku water.vault" );
}

public plugin_cfg( )
{
	new iEnt = engfunc( EngFunc_FindEntityByString, -1, "classname", "func_water" );
	
	while( iEnt )
	{
		if( !pev_valid( iEnt ) )
			continue;
		
		ArrayPushCell( gWaterEntity , iEnt );
		
		iEnt = engfunc( EngFunc_FindEntityByString, iEnt, "classname", "func_water" );
	}
}

public checkVisibility(id,pset)
{
	if( !pev_valid( id ) )
		return FMRES_IGNORED;
	
	if( !bHookVisible )
		return FMRES_IGNORED;
	
	bHookVisible = false;
	
	forward_return( FMV_CELL , 0 );
	
	return FMRES_SUPERCEDE;
}

public fwdAddToFullPack_Pre( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player )
	{
		if(is_user_alive(host) && is_user_alive(ent) && (g_bPlayerInvisible[host] == 1 || (g_bPlayerInvisible[host] == -1 && cs_get_user_team( host ) == cs_get_user_team( ent ))) && host != ent )
			bHookVisible = true;
	}
}

public fwdAddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
{
	if( is_user_alive( host ) && g_bWaterInvisible[host] && isEntWater( ent ) )
		set_es( es_handle, ES_Effects, EF_NODRAW );
}

public menuInvisDisplay( plr )
{
	static menu[ 512 ];
	
	new len = 0;
	
	len += format( menu[len], sizeof menu - len, "\r1. \wGracze: \y%s^n", g_bPlayerInvisible[plr] == 1 ? "Niewidoczni" : ( g_bPlayerInvisible[plr] == 0 ? "Widoczni" : "Widoczni tylko przeciwnicy" ) );
	len += format( menu[len], sizeof menu - len, "\r2. \wWoda: \y%s^n^n", ArraySize( gWaterEntity ) ? ( g_bWaterInvisible[plr] ? "Niewidoczna" : "Widoczna" ) : "Brak wody na mapie" );
	
	len += format( menu[len], sizeof menu - len, "\r0. \wWyjscie" );
	
	show_menu( plr, ( 1<<0 | 1<<1 | 1<<9 ), menu, -1 );
	
	return PLUGIN_HANDLED;
}

public MenuInvis( plr, key )
{
	switch( key )
	{
		case 0:
		{
			if( ++g_bPlayerInvisible[plr] > 1 )
				g_bPlayerInvisible[plr] = -1;
				
			saveInvis( plr );
			
			menuInvisDisplay( plr );
		}
		case 1:
		{
			g_bWaterInvisible[plr] = !g_bWaterInvisible[plr];
			
			saveWater( plr );
			
			menuInvisDisplay( plr );
		}
		default: show_menu( plr, 0, "" );
	}
}

public client_connect( plr )
{
	g_bPlayerInvisible[plr] = 0;
	g_bWaterInvisible[plr] = false;
	
	loadInvis( plr );
	
	loadWater( plr );
}  

public saveInvis( plr )
{
	new szVaultKey[64], szVaultData[10], szName[33];
	
	get_user_name( plr, szName, charsmax(szName) );
	
	formatex( szVaultKey, 63, "%s-invis", szName );
	formatex( szVaultData, 9, "%d", g_bPlayerInvisible[plr] );
	
	nvault_set( invis, szVaultKey, szVaultData );
	
	return PLUGIN_CONTINUE;
}

public loadInvis( plr )
{
	new szVaultKey[64], szVaultData[10], szName[33];
	
	get_user_name( plr, szName, charsmax(szName) );
	
	formatex( szVaultKey, 63, "%s-invis", szName );
	
	if( nvault_get( invis, szVaultKey, szVaultData, 63 ) )
	{
		new szSaved[10];
		
		parse( szVaultData, szSaved, 9 );
		
		g_bPlayerInvisible[plr] = str_to_num( szSaved );
	}
	
	return PLUGIN_CONTINUE;
} 

public saveWater( plr )
{
	new szVaultKey[64], szVaultData[10], szName[33];
	
	get_user_name( plr, szName, charsmax(szName) );
	
	formatex( szVaultKey, 63, "%s-water", szName );
	formatex( szVaultData, 9, "%d", g_bWaterInvisible[plr] );
	
	nvault_set( water, szVaultKey, szVaultData );
	
	return PLUGIN_CONTINUE;
}

public loadWater( plr )
{
	new szVaultKey[64], szVaultData[10], szName[33];
	
	get_user_name( plr, szName, charsmax(szName) );
	
	formatex( szVaultKey, 63, "%s-water", szName );
	
	if( nvault_get( water, szVaultKey, szVaultData, 63 ) )
	{
		new szSaved[10];
		
		parse( szVaultData, szSaved, 9 );
		
		g_bWaterInvisible[plr] = bool:str_to_num( szSaved );
	}
	
	return PLUGIN_CONTINUE;
} 

bool: isEntWater( iEnt )
{
	for( new iCurrent = 0 ; iCurrent < ArraySize( gWaterEntity ) ; iCurrent++ )
	{
		if( ArrayGetCell( gWaterEntity , iCurrent ) == iEnt )
			return true;
	}
	
	return false;
}
