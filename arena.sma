#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <round_terminator>
#include <adv_vault>
#include <colorchat>

#if AMXX_VERSION_NUM < 183
    #define MAX_PLAYERS 32
#endif

/* =================================================================================
*               [ Initiation & Global stuff ]
* ================================================================================= */

//#define SAVE_BY_STEAMID

const MAX_ARENAS = 16;

#define SetPlayerBit(%1,%2) ( %1 |= ( 1 << ( %2 & 31 ) ) )
#define ClearPlayerBit(%1,%2) ( %1 &= ~( 1 << ( %2 & 31 ) ) )
#define GetPlayerBit(%1,%2) ( %1 & ( 1 << ( %2 & 31 ) ) )

#define IsPlayerValid(%0) ( 1 <= %0 <= 32 )

const m_iTeam = 114;
const m_iVGUI = 510;
const m_pPlayer = 41;
const m_iRadiosLeft = 192;
const TASK_RESTART = 1315;
const EXTRAOFFSET_WEAPONS = 4;

const MAIN_KEYS = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5;

enum _:Vault_Fields
{
    Field_Points,
    Field_Kills,
    Field_Deaths
}

enum _:Game_Status
{
    Game_Waiting,
    Game_Playing
}

enum _:Team_Data
{
    Team_Terrorist,
    Team_Antiterrorist,
}

enum _:Weapon_Data
{
    Weapon_Name[32],
    Weapon_Ammo[16],
    Weapon_Index,
    Weapon_Bullets
}

enum _:Round_Type
{
    Round_None,
    Round_Rifle,
    Round_Sniper,
    Round_Pistol,
    Round_Knife
}

enum _:Player_Data
{
    Player_Name[ 32 ],
    Player_Next,
    Player_Model,
    Player_Arena,
    Player_Enemy,
    Player_Points,
    Player_Kills,
    Player_Deaths,
    Player_Primary,
    Player_Secondary,
    Player_RoundType,
    Player_TotalPoints,
    Player_Preference[ Round_Type ]
}

enum _:Cvars
{
    Cvar_Prefix,
    Cvar_Autojoin,
    Cvar_GameDescription,
    Cvar_HideHUD,
    Cvar_RoundTimer,
    Cvar_BlockDrop,
    Cvar_BlockModel,
    Cvar_BlockRadio,
    Cvar_BlockFallDamage,
    Cvar_BlockNameChange,
    Cvar_ShowActivity,
    Cvar_Points_Best,
    Cvar_Points_Good,
    Cvar_Points_Default
}

new const g_szNumbers[ ][ ] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16" };
new const g_szRoundTypes[ ][ ] = { "Zwykla Runda", "Runda na karabiny", "Runda na snajperki", "Runda na pistolety", "Runda na noze" };

new const g_eWeapons[ ][ Weapon_Data ] =
{
    { "weapon_knife", "", CSW_KNIFE, 1 },
    { "weapon_awp", "338magnum", CSW_AWP, 30 },
    { "weapon_m4a1", "556nato", CSW_M4A1, 90 },
    { "weapon_ak47", "762nato", CSW_AK47, 90 },
    { "weapon_famas", "556nato", CSW_FAMAS, 90 },
    { "weapon_galil", "556nato", CSW_GALIL, 90 },
    { "weapon_mp5navy", "9mm", CSW_MP5NAVY, 120 },
    { "weapon_glock18", "9mm", CSW_GLOCK18, 120 },
    { "weapon_usp", "45acp", CSW_USP, 100 },
    { "weapon_p228", "357sig", CSW_P228, 52 },
    { "weapon_deagle", "50ae", CSW_DEAGLE, 35 },
    { "weapon_fiveseven", "57mm", CSW_FIVESEVEN, 100 },
    { "weapon_elite", "9mm", CSW_ELITE, 120 }
};

new const g_szEntitiesToDelete[ ][ ] =
{
    "func_bomb_target",
    "info_bomb_target",
    "hostage_entity",
    "monster_scientist",
    "func_hostage_rescue",
    "info_hostage_rescue",
    "info_map_parameters",
    "info_vip_start",
    "func_vip_safetyzone",
    "func_escapezone",
    "func_buyzone"
};

new const g_szPlayerModels[ ][ ]    = { "terror", "gign" };
new const g_szCache_Model[ ]        = "model";
new const g_szCache_Name[ ]         = "name";
new const g_szHudThinkClassname[ ]  = "ShowHud";
new const g_szCache_WeaponStrip[ ]  = "player_weaponstrip";

new g_iGame,
    g_iSort,
    g_iAlive,
    g_iVault,
    g_iLeader,
    g_bNoDamage,
    g_iHudThink,
    g_iShowMenu,
    g_iVGUIMenu,
    g_iTeamInfo,
    g_iScoreInfo,
    g_iCrosshair,
    g_iConnected,
    g_iGameHudObj,
    g_iFirstRound,
    g_iHideWeapon,
    g_iForwardSpawn,
    g_iPrimaryMenu,
    g_iSecondaryMenu,
    g_iRemainingSeconds,
    g_iPlayerWeaponStrip;

new g_szPrefix[16],
    g_iCvars[ Cvars ],
    g_iFields[ Vault_Fields ],
    Float:g_flSpawnOrigin[ 33 ][ 3 ],
    Float:g_flSpawnAngles[ 33 ][ 3 ],
    g_ePlayerData[ 33 ][ Player_Data ];

public plugin_precache( )
{
    SetBuyConditions( );
    
    g_iPlayerWeaponStrip = create_entity( g_szCache_WeaponStrip );
    DispatchSpawn( g_iPlayerWeaponStrip );
    
    g_iForwardSpawn = register_forward( FM_Spawn, "fw_Spawn_Pre", false );
}

public plugin_init( )
{
    register_plugin( "Arena", "1.1b", "Manu" );
    register_cvar( "arena_version", "1.1b", FCVAR_SERVER|FCVAR_SPONLY );
    
    register_event( "ResetHUD", "ev_ResetHUD", "be" );
    register_logevent( "ev_RoundEnd", 2, "1=Round_End" );
    register_logevent( "ev_RoundStart", 2, "1=Round_Start" );
    
    register_think( g_szHudThinkClassname, "think_ShowHUD" );
    
    RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn_Post", true );
    RegisterHam( Ham_Killed, "player", "fw_PlayerKilled_Post", true );
    RegisterHam( Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Pre", false );
    
    unregister_forward( FM_Spawn, g_iForwardSpawn );
    register_forward( FM_ClientKill, "fw_ClientKill_Pre", false );
    register_forward( FM_GetGameDescription, "fw_GameDescription_Pre", false );
    register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue_Pre", false );
    register_forward( FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged_Pre", false );
    
    register_menucmd( register_menuid( "Main Menu", false ), MAIN_KEYS, "MainHandler" );
    register_menucmd( register_menuid( "Team_Select", true ), (1<<0)|(1<<1)|(1<<4)|(1<<5), "HookTeamChoosing" );
    
    register_clcmd( "say /amrank", "CommandRank" );
    register_clcmd( "say /amtop", "CommandTop" );
    
    register_clcmd( "drop", "CommandDrop" );
    register_clcmd( "jointeam", "HookTeamChoosing" );
    register_clcmd( "chooseteam", "HookTeamChoosing" );
    
    g_bNoDamage     = true;
    g_iGameHudObj   = CreateHudSyncObj( );
    g_iShowMenu     = get_user_msgid( "ShowMenu" );
    g_iVGUIMenu     = get_user_msgid( "VGUIMenu" );
    g_iTeamInfo     = get_user_msgid( "TeamInfo" );
    g_iHideWeapon   = get_user_msgid( "HideWeapon" );
    g_iCrosshair    = get_user_msgid( "Crosshair" );
    g_iScoreInfo    = get_user_msgid( "ScoreInfo" );
    g_iHudThink     = create_entity( "info_target" );
    g_iVault        = adv_vault_open( "arena_stats", false );
    
    g_iCvars[ Cvar_Prefix ] = register_cvar( "am_prefix", "Arena" );
    g_iCvars[ Cvar_Autojoin ] = register_cvar( "am_autojoin", "1" );
    g_iCvars[ Cvar_GameDescription ] = register_cvar( "am_gamedescription", "1" );
    g_iCvars[ Cvar_HideHUD ] = register_cvar( "am_hidehud", "1" );
    g_iCvars[ Cvar_RoundTimer ] = register_cvar( "am_roundtimer", "60" );
    g_iCvars[ Cvar_BlockDrop ] = register_cvar( "am_blockdrop", "1" );
    g_iCvars[ Cvar_BlockModel ] = register_cvar( "am_blockmodel", "1" );
    g_iCvars[ Cvar_BlockRadio ] = register_cvar( "am_blockradio", "1" );
    g_iCvars[ Cvar_BlockFallDamage ] = register_cvar( "am_blockfalldamage", "1" );
    g_iCvars[ Cvar_BlockNameChange ] = register_cvar( "am_blocknamechange", "1" );
    g_iCvars[ Cvar_ShowActivity ] = register_cvar( "am_showactivity", "1" );
    g_iCvars[ Cvar_Points_Best ] = register_cvar( "am_points_best", "3" );
    g_iCvars[ Cvar_Points_Good ] = register_cvar( "am_points_good", "2" );
    g_iCvars[ Cvar_Points_Default ] = register_cvar( "am_points_default", "1" );

    g_iFields[ Field_Points ]   = adv_vault_register_field( g_iVault, "points" );
    g_iFields[ Field_Kills ]    = adv_vault_register_field( g_iVault, "kills" );
    g_iFields[ Field_Deaths ]   = adv_vault_register_field( g_iVault, "deaths" );

    adv_vault_init( g_iVault );
    
    g_iSort = adv_vault_sort_create( g_iVault, ORDER_DESC, 180, 0, g_iFields[ Field_Points ] );

    copy( g_szPrefix, charsmax( g_szPrefix ), "Arena" );
    copy( g_ePlayerData[ 0 ][ Player_Name ], charsmax( g_ePlayerData[ ][ Player_Name ] ), "Ninguno" );

    entity_set_string( g_iHudThink, EV_SZ_classname, g_szHudThinkClassname );

    ExecuteConfig( );
    CreatePlayerMenus( );
    
    if( !GetSpawnPoints( ) )
    {
        log_error( AMX_ERR_GENERAL, "Nie mozna znalezc spawna (nie kompatybilny mapa). Wstrzymywanie ..." );
        pause( "a" );
    }
}

public plugin_natives( )
{
    register_native( "am_get_roundtime", "_am_get_roundtime" );
    register_native( "am_get_player_arena", "_am_get_player_arena" );
    register_native( "am_get_player_points", "_am_get_player_points" );
}

/* =================================================================================
*               [ Events & Messages ]
* ================================================================================== */

public ev_RoundStart( )
{
    if( g_iFirstRound == 2 && !task_exists( TASK_RESTART ) )
    {
        set_task( 10.0, "task_RestartGame" );
        
        ColorChat( 0, TEAM_COLOR, "^4[%s]^1 Witamy na serwerze Arena 1vs1^1!", g_szPrefix );
        ColorChat( 0, TEAM_COLOR, "^4[%s]^1 Gra rozpocznie sie za 10 sekund^1. Przygotuj sie!", g_szPrefix );
    }
    else if( g_iGame == Game_Playing )
    {
        new iTerrorist, iAntiterrorist, iPlayers[32];
        
        g_iFirstRound = 0; g_bNoDamage = false;
        
        for( new iPlayer = 1, iIndex, iNum; iPlayer <= MAX_PLAYERS; iPlayer++ )
        {
            if( GetPlayerBit( g_iConnected, iPlayer ) )
            {
                g_ePlayerData[ iPlayer ][ Player_Arena ] = g_ePlayerData[ iPlayer ][ Player_Next ];
                
                for( iIndex = 0; iIndex < MAX_PLAYERS; iIndex++ )
                {
                    if( ( iPlayers[ iIndex ] == 0 ) || ( g_ePlayerData[ iPlayers[ iIndex ] ][ Player_Arena ] > g_ePlayerData[ iPlayer ][ Player_Arena ] ) )
                    {
                        for( iNum = iPlayer; iNum > iIndex; iNum-- )
                            iPlayers[ iNum ] = iPlayers[ iNum - 1 ];
                        
                        iPlayers[ iIndex ] = iPlayer; break;
                    }
                }
            }
        }
        
        for( new iIndex; iIndex < MAX_ARENAS; iIndex++ )
        {
            iTerrorist = iPlayers[ (iIndex * 2) ];
            iAntiterrorist = iPlayers[ (iIndex * 2) + 1 ];
                        
            if( GetPlayerBit( g_iAlive, iTerrorist ) )
            {
                SetPlayerTeam( iTerrorist, 1 );
                SetPlayerModel( iTerrorist, 0 );
                
                entity_set_origin( iTerrorist, g_flSpawnOrigin[ (iIndex * 2) ] );
                entity_set_vector( iTerrorist, EV_VEC_v_angle, g_flSpawnAngles[ (iIndex * 2) ] );
                
                g_ePlayerData[ iTerrorist ][ Player_Arena ] = iIndex;
                g_ePlayerData[ iTerrorist ][ Player_Enemy ] = iAntiterrorist;
                g_ePlayerData[ iTerrorist ][ Player_RoundType ] = GetPreference( iTerrorist, iAntiterrorist );
                
                GiveWeapons( iTerrorist );
                
                if( GetPlayerBit( g_iAlive, iAntiterrorist ) )
                {
                    SetPlayerTeam( iAntiterrorist, 2 );
                    SetPlayerModel( iAntiterrorist, 1 );
                    
                    entity_set_origin( iAntiterrorist, g_flSpawnOrigin[ (iIndex * 2) + 1 ] );
                    entity_set_vector( iAntiterrorist, EV_VEC_v_angle, g_flSpawnAngles[ (iIndex * 2) + 1 ] );
                    
                    g_ePlayerData[ iAntiterrorist ][ Player_Arena ] = iIndex;
                    g_ePlayerData[ iAntiterrorist ][ Player_Enemy ] = iTerrorist;
                    g_ePlayerData[ iAntiterrorist ][ Player_RoundType ] = g_ePlayerData[ iTerrorist ][ Player_RoundType ];
                    
                    GiveWeapons( iAntiterrorist);
                    
                    continue;
                }
                
                g_ePlayerData[ iTerrorist][ Player_Next ] = ( iIndex - 1 );
                ColorChat( iTerrorist, TEAM_COLOR, "^4[%s]^1 Nie miaĹ‚es zadnego przeciwnika. WygraĹ‚es.", g_szPrefix );                    
            }
            else
                break;
        }
        
        UpdateLeader( );
        
        get_pcvar_string( g_iCvars[ Cvar_Prefix ], g_szPrefix, charsmax( g_szPrefix ) );
        g_iRemainingSeconds = max( 10, get_pcvar_num( g_iCvars[ Cvar_RoundTimer ] ) );
        entity_set_float( g_iHudThink, EV_FL_nextthink, get_gametime( ) + 1.0 );
    }
}

public ev_RoundEnd( )
{
    entity_set_float( g_iHudThink, EV_FL_nextthink, 0.0 );
    
    for( new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++ )
    {
        if( !GetPlayerBit( g_iConnected, iPlayer ) )
            continue;
        
        g_ePlayerData[ iPlayer ][ Player_Enemy ] = 0;
        g_ePlayerData[ iPlayer ][ Player_RoundType ] = 0;
    }
}

public ev_ResetHUD( iId )
{
    if( get_pcvar_num( g_iCvars[ Cvar_HideHUD ] ) > 0 )
    {
        message_begin( MSG_ONE_UNRELIABLE, g_iHideWeapon, _, iId );
        write_byte( ( 1<<4 | 1<<5 ) );
        message_end( );
        
        message_begin( MSG_ONE_UNRELIABLE, g_iCrosshair, _, iId );
        write_byte( 0 );
        message_end( );
    }
}

public task_ForceJoinTeam( const iId )
{
    if( GetPlayerBit( g_iConnected, iId ) )
    {
        static iRestore; iRestore = get_pdata_int( iId, m_iVGUI );
        
        if( iRestore & (1<<0) )
            set_pdata_int( iId, m_iVGUI, iRestore & ~(1<<0) );
        
        set_msg_block( g_iShowMenu, BLOCK_SET );
        set_msg_block( g_iVGUIMenu, BLOCK_SET );
        
        engclient_cmd( iId, "jointeam", "5" );
        engclient_cmd( iId, "joinclass", "5" );
        
        set_msg_block( g_iShowMenu, BLOCK_NOT );
        set_msg_block( g_iVGUIMenu, BLOCK_NOT );
        
        if( iRestore & (1<<0) ) 
            set_pdata_int( iId, m_iVGUI, iRestore ); 
        
        menu_cancel( iId );
    }
}

public task_RestartGame( )
{
    g_iFirstRound = 1;
    
    server_cmd( "sv_restartround 1" );
}

/* =================================================================================
*               [ Engine ]
* ================================================================================== */

public think_ShowHUD( iEnt )
{
    g_iRemainingSeconds--;
    
    for( new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++ )
    {
        if( GetPlayerBit( g_iConnected, iPlayer ) )
        {
            set_hudmessage( 255, 140, 0, -1.0, 0.1, 0, 1.0, 1.0 );
            ShowSyncHudMsg( iPlayer, g_iGameHudObj, "[ Arena %s | %s | Czas: %d ]^n[ Lider: %s z %d punktami ]^n^n[ Przeciwnik: %s ]",
                g_szNumbers[ g_ePlayerData[ iPlayer ][ Player_Arena ] ],
                g_szRoundTypes[ g_ePlayerData[ iPlayer ][ Player_RoundType ] ],
                g_iRemainingSeconds,
                g_ePlayerData[ g_iLeader ][ Player_Name ],
                g_ePlayerData[ g_iLeader ][ Player_Points ],
                g_ePlayerData[ g_ePlayerData[ iPlayer ][ Player_Enemy ] ][ Player_Name ] );
        }
    }
    
    if( g_iRemainingSeconds == 5 )
    {
        ColorChat( 0, TEAM_COLOR, "^4[%s]^1 Pozostalo^3 piec sekund^1 do konca rundy.", g_szPrefix );
        ColorChat( 0, TEAM_COLOR, "^4[%s]^1 Jesli sie nie skonczy, wygrywa druzyna z wieksza liczba zywych graczy.", g_szPrefix );
    }
    else if( g_iRemainingSeconds <= 0 )
    {
        new iNum[2], iPlayers[32];
        
        for( new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++ )
        {
            if( !GetPlayerBit( g_iAlive, iPlayer ) )
                continue;
            
            ( get_user_team( iPlayer ) == 1 ) ? (iPlayers[iNum[0]++] = iPlayer) : (iPlayers[16 + iNum[1]++] = iPlayer);
        }
        
        new iIndex = ( iNum[0] > iNum[1] ) ? 0 : 16;
        new iUntil = max( iNum[0], iNum[1] ) + iIndex;
        
        while( iIndex < iUntil )
        {
            if( g_ePlayerData[ iPlayers[ iIndex ] ][ Player_Enemy ] > 0
            && GetPlayerBit( g_iAlive, g_ePlayerData[ iPlayers[ iIndex ] ][ Player_Enemy ] ) )
                ArenaRewards( iPlayers[ iIndex ], g_ePlayerData[ iPlayers[ iIndex ] ][ Player_Enemy ] );
            
            iIndex++;
        }
        
        g_bNoDamage = true;
        TerminateRound( RoundEndType_Draw );
        
        return;
    }
    
    entity_set_float( iEnt, EV_FL_nextthink, get_gametime( ) + 1.0 );
}

/* =================================================================================
*               [ Hamsandwich ]
* ================================================================================== */

public fw_PlayerSpawn_Post( iId )
{
    if( is_user_alive( iId ) )
    {
        SetPlayerBit( g_iAlive, iId );
        SetPlayerModel( iId, GetPlayerTeam( iId ) > 1 ? 0 : 1 );
        
        if( get_pcvar_num( g_iCvars[ Cvar_BlockRadio ] ) > 0 )
            set_pdata_int( iId, m_iRadiosLeft, 0 );
    }
    
    return HAM_IGNORED;
}

public fw_PlayerTakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits )
{
    if( ( iDamageBits == DMG_FALL && get_pcvar_num( g_iCvars[ Cvar_BlockFallDamage ] ) > 0 ) || g_bNoDamage ) 
        return HAM_SUPERCEDE;
    
    return HAM_IGNORED;
}

public fw_PlayerKilled_Post( iVictim, iAttacker, bShouldgib )
{
    ClearPlayerBit( g_iAlive, iVictim );
    
    if( !g_bNoDamage )
    {
        CheckRoundStatus( );
        ArenaRewards( iAttacker, iVictim );
    }

    return HAM_IGNORED;
}

/* =================================================================================
*               [ Fakemeta ]
* ================================================================================== */

public fw_Spawn_Pre( iEnt )
{
    if( !pev_valid( iEnt ) )
        return FMRES_IGNORED;
    
    new szClassname[ 32 ]; entity_get_string( iEnt, EV_SZ_classname, szClassname, charsmax( szClassname ) );
    
    for( new i; i < sizeof( g_szEntitiesToDelete ); i++ )
    {
        if( equal( szClassname, g_szEntitiesToDelete[ i ] ) )
        {
            remove_entity( iEnt );
            
            return FMRES_SUPERCEDE;
        }
    }
    
    return FMRES_IGNORED;
}

public fw_ClientUserInfoChanged_Pre( iId )
{
    if( GetPlayerBit( g_iConnected, iId ) )
    {
        static szName[ 32 ]; get_user_info( iId, g_szCache_Name, szName, charsmax( szName ) );
        
        if( !equal( szName, g_ePlayerData[ iId ][ Player_Name ] ) )
        {
            if( get_pcvar_num( g_iCvars[ Cvar_BlockNameChange ] ) > 0 )
            {
                client_cmd( iId, ";name ^"%s^"", g_ePlayerData[ iId ][ Player_Name ] );
                set_user_info( iId, g_szCache_Name, g_ePlayerData[ iId ][ Player_Name ] );
            }
            else
                copy( g_ePlayerData[ iId ][ Player_Name ], charsmax( g_ePlayerData[ ][ Player_Name ] ), szName );
            
            return FMRES_SUPERCEDE;
        }
    }
    
    return FMRES_IGNORED;
}

public fw_SetClientKeyValue_Pre( iId, szBuffer[ ], szKey[ ], szValue[ ] )
{
    if( GetPlayerBit( g_iConnected, iId )
    && get_pcvar_num( g_iCvars[ Cvar_BlockModel ] ) > 0
    && equal( szKey, g_szCache_Model )
    && !equal( szValue, g_szPlayerModels[ g_ePlayerData[ iId ][ Player_Model ] ] ) )
    {
        set_user_info( iId, szKey, g_szPlayerModels[ g_ePlayerData[ iId ][ Player_Model ] ] );
        
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

public fw_ClientKill_Pre( iId )
{
    ColorChat( iId, TEAM_COLOR, "^x04[%s]^x01 No puedes suicidarte.", g_szPrefix );
    
    return FMRES_SUPERCEDE;
}

public fw_GameDescription_Pre( )
{
    if( get_pcvar_num( g_iCvars[ Cvar_GameDescription ] ) <= 0 )
        return FMRES_IGNORED;
        
    forward_return( FMV_STRING, "Arena 1.1b" );
    
    return FMRES_SUPERCEDE;
}

/* =================================================================================
*               [ Client-related ]
* ================================================================================== */

public client_putinserver( iId )
{
    ClearPlayerBit( g_iAlive, iId );
    SetPlayerBit( g_iConnected, iId );
    
    if( !is_user_bot( iId ) )
        set_pdata_int( iId, 365, 1 );
    
    get_user_name( iId, g_ePlayerData[ iId ][ Player_Name ], charsmax( g_ePlayerData[ ][ Player_Name ] ) );
    
    g_ePlayerData[ iId ][ Player_Next ] = 15;
    g_ePlayerData[ iId ][ Player_Arena ] = 0;
    g_ePlayerData[ iId ][ Player_Kills ] = 0;
    g_ePlayerData[ iId ][ Player_Deaths ] = 0;
    g_ePlayerData[ iId ][ Player_Points ] = 0;
    
    g_ePlayerData[ iId ][ Player_Preference ][ Round_Rifle ] = 1;
    g_ePlayerData[ iId ][ Player_Preference ][ Round_Pistol ] = 1;
    g_ePlayerData[ iId ][ Player_Preference ][ Round_Sniper ] = 1;
    g_ePlayerData[ iId ][ Player_Preference ][ Round_Knife ] = 1;
    
    if( get_pcvar_num( g_iCvars[ Cvar_Autojoin ] ) > 0 )
        set_task( 1.0, "task_ForceJoinTeam", iId );
    
    LoadPlayerData( iId );
    CheckGameStatus( );
}

public client_disconnect( iId )
{
    ClearPlayerBit( g_iConnected, iId );
    ClearPlayerBit( g_iAlive, iId );
    
    if( GetPlayerBit( g_iConnected, g_ePlayerData[ iId ][ Player_Enemy ] ) )
    {
        g_ePlayerData[ g_ePlayerData[ iId ][ Player_Enemy ] ][ Player_Enemy ] = 0;
        g_ePlayerData[ g_ePlayerData[ iId ][ Player_Enemy ] ][ Player_Next ] = max( 0, g_ePlayerData[ g_ePlayerData[ iId ][ Player_Enemy ] ][ Player_Arena ] - 1 );
        
        client_cmd( g_ePlayerData[ iId ][ Player_Enemy ], "spk fvox/bell" );
        ColorChat( g_ePlayerData[ iId ][ Player_Enemy ], TEAM_COLOR, "^x04[%s]^x01 Tu contrincante se ha^3 desconectado^1.", g_szPrefix );
    }
    
    g_ePlayerData[ iId ][ Player_Enemy ] = 0;
    g_ePlayerData[ iId ][ Player_Primary ] = 0;
    g_ePlayerData[ iId ][ Player_Secondary ] = 0;
    g_ePlayerData[ iId ][ Player_TotalPoints ] += g_ePlayerData[ iId ][ Player_Points ];
    
    SavePlayerData( iId );
    CheckGameStatus( );
}

public HookTeamChoosing( iId, iKey )
{
    ShowMainMenu( iId );
    
    return PLUGIN_HANDLED;
}

public CommandDrop( iId )
{
    if( get_pcvar_num( g_iCvars[ Cvar_BlockDrop ] ) <= 0 )
        return PLUGIN_CONTINUE;
    
    client_cmd( iId, "spk buttons/button10" );
    
    return PLUGIN_HANDLED;
}

public CommandRank( iId )
{
    new iRank = adv_vault_sort_key( g_iVault, g_iSort, 0, g_ePlayerData[ iId ][ Player_Name ] );

    if( !iRank )
        ColorChat( iId, TEAM_COLOR, "^4[%s]^1 Nie posiadasz rangi w tej chwili.", g_szPrefix );
    else
        ColorChat( iId, TEAM_COLOR, "^4[%s]^1 Estas en el puesto ^4%d^1 de ^4%d jugadores.", g_szPrefix, iRank, adv_vault_sort_numresult( g_iVault, g_iSort ) );
    
    return PLUGIN_HANDLED;
}

public CommandTop( iId )
{
    if( adv_vault_sort_numresult( g_iVault, g_iSort ) < 10 )
    {
        ColorChat( iId, TEAM_COLOR, "^4[%s]^1 El top debe poseer al menos diez jugadores." );
        
        return PLUGIN_HANDLED;
    }

    static szMotd[1024], szKeyname[32], iLen, iKey, iPoints, iKills, iDeaths;

    iLen = formatex( szMotd, charsmax( szMotd ), "<html><head><style>table,td,th { border:1px solid black; border-collapse:collapse; }</style></head><body bgcolor='#ebf3f8'><table style='width:748px'>" );
    iLen += formatex( szMotd[ iLen ], charsmax( szMotd ) - iLen, "<th>Nr.</th><th>Nombre/SteamID</th><th>Puntos</th><th>Asesinatos</th><th>Muertes</th>");

    for( new i = 1; i <= 10; i++ )
    {
        iKey = adv_vault_sort_position( g_iVault, g_iSort, i );

        if( !adv_vault_get_prepare( g_iVault, iKey ) )
            continue;

        iPoints = adv_vault_get_field( g_iVault, g_iFields[ Field_Points ] );
        iKills = adv_vault_get_field( g_iVault, g_iFields[ Field_Points ] );
        iDeaths = adv_vault_get_field( g_iVault, g_iFields[ Field_Points ] );

        adv_vault_get_keyname( g_iVault, iKey, szKeyname, charsmax( szKeyname ) );

        iLen += formatex( szMotd[ iLen ], charsmax( szMotd ) - iLen, "<tr><td>%d.</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td></tr>",
        i, szKeyname, iPoints, iKills, iDeaths );
    }

    iLen += formatex( szMotd[ iLen ], charsmax( szMotd ) - iLen, "</table></body></html>" );

    show_motd( iId, szMotd, "Top 10 najlepszych graczy" );

    return PLUGIN_HANDLED;
}

/* =================================================================================
 *              [ Player Menus ]
 * ================================================================================== */

ShowMainMenu( iId )
{
    static szData[ 256 ], iLen;
    
    iLen = formatex( szData, charsmax( szData ), "\wTryb: \yArena \d- \wWersja: \y2.0^n^n" );
    
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[1]\w Wybierz \yBron^n^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\y - \w Ustawienia \y-^n^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[2]\w Runda na \yKarabiny \r[%s\r]^n", g_ePlayerData[ iId ][ Player_Preference ][ Round_Rifle ] > 0 ? "\wTAK" : "\dNIE" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[3]\w Runda na \yPistolety \r[%s\r]^n", g_ePlayerData[ iId ][ Player_Preference ][ Round_Pistol ] > 0 ? "\wTAK" : "\dNIE" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[4]\w Runda na \yNozowa \r[%s\r]^n", g_ePlayerData[ iId ][ Player_Preference ][ Round_Knife ] > 0 ? "\wTAK" : "\dNIE" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[5]\w Runda na \ySnajperki \r[%s\r]^n^n", g_ePlayerData[ iId ][ Player_Preference ][ Round_Sniper ] > 0 ? "\wTAK" : "\dNIE" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[0]\w Anuluj" );
    
    show_menu( iId, MAIN_KEYS, szData, -1, "Menu Glowne" );
    
    return PLUGIN_HANDLED;
}

public MainHandler( iId, iKey )
{
    if( iKey < 5 )
    {
        client_cmd( iId, "spk buttons/lightswitch2" );
        
        switch( iKey )
        {
            case 0:
            {
                menu_display( iId, g_iPrimaryMenu );
                ColorChat( iId, TEAM_COLOR, "^4[%s]^1 Wybierz swoja bron podstawowa:", g_szPrefix );
                
                return PLUGIN_HANDLED;
            }
            case 1: g_ePlayerData[ iId ][ Player_Preference ][ Round_Rifle ] = (g_ePlayerData[ iId ][ Player_Preference ][ Round_Rifle ] > 0) ? 0 : 1;
            case 2: g_ePlayerData[ iId ][ Player_Preference ][ Round_Pistol ] = (g_ePlayerData[ iId ][ Player_Preference ][ Round_Pistol ] > 0) ? 0 : 1;
            case 3: g_ePlayerData[ iId ][ Player_Preference ][ Round_Knife ] = (g_ePlayerData[ iId ][ Player_Preference ][ Round_Knife ] > 0) ? 0 : 1;
            case 4: g_ePlayerData[ iId ][ Player_Preference ][ Round_Sniper ] = (g_ePlayerData[ iId ][ Player_Preference ][ Round_Sniper ] > 0) ? 0 : 1;
        }
        
        ShowMainMenu( iId );
    }
    
    return PLUGIN_HANDLED;
}

public PrimaryHandler( iId, iMenu, iItem )
{
    if( iItem != MENU_EXIT )
    {
        g_ePlayerData[ iId ][ Player_Primary ] = iItem;
        
        menu_display( iId, g_iSecondaryMenu );
        
        client_cmd( iId, "spk buttons/button3" );
        ColorChat( iId, TEAM_COLOR, "^4[%s]^1 Wybierz swoja bron drugorzedna:", g_szPrefix );
    }
    
    return PLUGIN_HANDLED;
}

public SecondaryHandler( iId, iMenu, iItem )
{
    if( iItem != MENU_EXIT )
    {
        g_ePlayerData[ iId ][ Player_Secondary ] = iItem;
        
        client_cmd( iId, "spk buttons/button3" );
        ColorChat( iId, TEAM_COLOR, "^4[%s]^1 Bron zostala zmieniona pomyslnie.", g_szPrefix );
    }
    
    return PLUGIN_HANDLED;
}
    
/* =================================================================================
 *              [ Engine ]
 * ================================================================================== */

RemovePlayerWeapons( iId )
{
    dllfunc( DLLFunc_Use, g_iPlayerWeaponStrip, iId );
}

CreatePlayerMenus( )
{
    g_iPrimaryMenu = menu_create( "Wybierz swoja bron podstawowa:", "PrimaryHandler" );
    
    menu_additem( g_iPrimaryMenu, "M4A1" );
    menu_additem( g_iPrimaryMenu, "AK-47" );
    menu_additem( g_iPrimaryMenu, "Famas" );
    menu_additem( g_iPrimaryMenu, "Galil" );
    menu_additem( g_iPrimaryMenu, "MP5" );
    
    menu_setprop( g_iPrimaryMenu, MPROP_EXITNAME, "Anuluj" );
    
    g_iSecondaryMenu = menu_create( "Wybierz swoja bron drugorzedna:", "SecondaryHandler" );
    
    menu_additem( g_iSecondaryMenu, "Glock-18" );
    menu_additem( g_iSecondaryMenu, "USP" );
    menu_additem( g_iSecondaryMenu, "P228" );
    menu_additem( g_iSecondaryMenu, "Desert Eagle" );
    menu_additem( g_iSecondaryMenu, "Five-Seven" );
    menu_additem( g_iSecondaryMenu, "Dual Berettas" );
    
    menu_setprop( g_iSecondaryMenu, MPROP_EXITNAME, "Anuluj" );
}

ArenaRewards( iAttacker, iVictim )
{
    g_ePlayerData[ iVictim ][ Player_Deaths ]++;
    g_ePlayerData[ iVictim ][ Player_Next ] = (g_ePlayerData[ iVictim ][ Player_Arena ] + 1);
    
    if( !IsPlayerValid( iAttacker ) || (iAttacker == iVictim) )
        iAttacker = g_ePlayerData[ iVictim ][ Player_Enemy ];
    
    if( IsPlayerValid( iAttacker ) && GetPlayerBit( g_iConnected, iAttacker ) )
    {
        g_ePlayerData[ iAttacker ][ Player_Kills ]++;
        
        if( get_pcvar_num( g_iCvars[ Cvar_ShowActivity ] ) > 0 )
        {
            ColorChat( 0, TEAM_COLOR, "^4[%s]^1 Arena^3 %s^1: ^4%s^1 le ganĂł a^4 %s^1.",
                g_szPrefix, g_szNumbers[ g_ePlayerData[ iAttacker ][ Player_Arena ] ],
                g_ePlayerData[ iAttacker ][ Player_Name ], g_ePlayerData[ iVictim ][ Player_Name ] );
        }
        
        ColorChat( iVictim, TEAM_COLOR, "^4[%s]^1 No lograste vencer en ^4arena %s^1 y bajarĂˇs de arena.",
            g_szPrefix, g_szNumbers[ g_ePlayerData[ iAttacker ][ Player_Arena ] ] );
        
        if( g_ePlayerData[ iAttacker ][ Player_Arena ] <= 2 )
        {
            if( g_ePlayerData[ iAttacker ][ Player_Arena ] > 0 )
            {
                g_ePlayerData[ iAttacker ][ Player_Next ] = ( g_ePlayerData[ iAttacker ][ Player_Arena ] - 1 );
                g_ePlayerData[ iAttacker ][ Player_Points ] += get_pcvar_num( g_iCvars[ Cvar_Points_Good ] );
                
                ColorChat( iAttacker, TEAM_COLOR, "^4[%s]^1 Ganaste^3 %d^1 punto(s) por sobrevivir en arena %s.", g_szPrefix, get_pcvar_num( g_iCvars[ Cvar_Points_Good ] ), g_szNumbers[ g_ePlayerData[ iAttacker ][ Player_Arena ] ] );
            }
            else
            {
                g_ePlayerData[ iAttacker ][ Player_Next ] = 0;
                g_ePlayerData[ iAttacker ][ Player_Points ] += get_pcvar_num( g_iCvars[ Cvar_Points_Best ] );
                
                ColorChat( iAttacker, TEAM_COLOR, "^4[%s]^1 Ganaste^3 %d^1 punto(s) por sobrevivir en arena uno.", g_szPrefix, get_pcvar_num( g_iCvars[ Cvar_Points_Best ] ) );
            }
        }
        else
        {
            g_ePlayerData[ iAttacker ][ Player_Next ] = ( g_ePlayerData[ iAttacker ][ Player_Arena ] - 1 );
            g_ePlayerData[ iAttacker ][ Player_Points ] += get_pcvar_num( g_iCvars[ Cvar_Points_Default ] );
            
            ColorChat( iAttacker, TEAM_COLOR, "^4[%s]^1 Ganaste^3 %d^1 punto(s) por sobrevivir en arena %s.", g_szPrefix, get_pcvar_num( g_iCvars[ Cvar_Points_Default ] ), g_szNumbers[ g_ePlayerData[ iAttacker ][ Player_Arena ] ] );
        }
        
        entity_set_float( iAttacker, EV_FL_frags, float( g_ePlayerData[ iAttacker ][ Player_Points ] ) );
        
        message_begin( MSG_BROADCAST, g_iScoreInfo );
        write_byte( iAttacker );
        write_short( g_ePlayerData[ iAttacker ][ Player_Points ] );
        write_short( get_user_deaths( iAttacker ) );
        write_short( 0 );
        write_short( get_user_team( iAttacker ) );
        message_end( );
    }
    
    UpdateLeader( );
}

LoadPlayerData( const iId )
{
    #if defined SAVE_BY_STEAMID
    
    static szAuthId[32]; get_user_authid( iId, szAuthId, charsmax( szAuthId ) );
    
    if( adv_vault_get_prepare( g_iVault, _, szAuthId ) )
    {
        g_ePlayerData[ iId ][ Player_Kills ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Kills ] );
        g_ePlayerData[ iId ][ Player_Deaths ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Deaths ] );
        g_ePlayerData[ iId ][ Player_TotalPoints ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Points ] );
    }
    
    #else
    
    if( adv_vault_get_prepare( g_iVault, _, g_ePlayerData[ iId ][ Player_Name ] ) )
    {
        g_ePlayerData[ iId ][ Player_Kills ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Kills ] );
        g_ePlayerData[ iId ][ Player_Deaths ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Deaths ] );
        g_ePlayerData[ iId ][ Player_TotalPoints ] = adv_vault_get_field( g_iVault, g_iFields[ Field_Points ] );
    }
    
    #endif
}

SavePlayerData( const iId )
{
    adv_vault_set_start( g_iVault );

    adv_vault_set_field( g_iVault, g_iFields[ Field_Kills ], g_ePlayerData[ iId ][ Player_Kills ] );
    adv_vault_set_field( g_iVault, g_iFields[ Field_Deaths ], g_ePlayerData[ iId ][ Player_Deaths ] );
    adv_vault_set_field( g_iVault, g_iFields[ Field_Points ], g_ePlayerData[ iId ][ Player_TotalPoints ] );
    
    #if defined SAVE_BY_STEAMID
    
    static szAuthId[32]; get_user_authid( iId, szAuthId, charsmax( szAuthId ) );
    
    adv_vault_set_end( g_iVault, 0, szAuthId );
    
    #else
    
    adv_vault_set_end( g_iVault, 0, g_ePlayerData[ iId ][ Player_Name ] );
    
    #endif
}

GetPreference( iTerrorist, iAntiterrorist )
{
    new iType, Array:aTypes = ArrayCreate(1,1);
    
    ArrayPushCell( aTypes, 0 );
    
    for( new i = 1; i < Round_Type; i++ )
    {
        if( g_ePlayerData[ iTerrorist ][ Player_Preference ][ i ] > 0
        && g_ePlayerData[ iAntiterrorist ][ Player_Preference ][ i ] > 0 )
            ArrayPushCell( aTypes, i );
    }
    
    iType = ArrayGetCell( aTypes, random( ArraySize( aTypes ) ) );
    ArrayDestroy( aTypes );
    
    return iType;
}

GiveWeapons( iId )
{
    RemovePlayerWeapons( iId );
    HamGiveWeapon( iId, 0 );
    
    entity_set_float( iId, EV_FL_armorvalue, 100.0 );
    set_pdata_int( iId, 112, 2 );
    
    switch( g_ePlayerData[ iId ][ Player_RoundType ] )
    {
        case Round_Sniper: HamGiveWeapon( iId, 1 );
        case Round_Rifle: HamGiveWeapon( iId, ( g_ePlayerData[ iId ][ Player_Primary ] + 2 ) );
        case Round_Pistol:
        {
            set_pdata_int( iId, 112, 1 );
            HamGiveWeapon( iId, ( g_ePlayerData[ iId ][ Player_Secondary ] + 7 ) );
        }
        case Round_None:
        {
            HamGiveWeapon( iId, ( g_ePlayerData[ iId ][ Player_Primary ] + 2 ) );
            HamGiveWeapon( iId, ( g_ePlayerData[ iId ][ Player_Secondary ] + 7 ) );
        }
    }
}

ExecuteConfig( )
{
    new szFile[64];
    
    get_localinfo( "amxx_configsdir", szFile, charsmax( szFile ) );
    add( szFile, charsmax( szFile ), "/arena.cfg" );
    
    if( file_exists( szFile ) )
    {
        server_cmd( "exec %s", szFile );
        server_exec( );
    }
    
    set_cvar_num( "mp_roundtime", (get_pcvar_num( g_iCvars[ Cvar_RoundTimer ] ) / 60) + 1 );
}

HamGiveWeapon( iId, iWeapon )
{
    static iEnt;
    
    if( !is_valid_ent( ( iEnt = create_entity( g_eWeapons[ iWeapon ][ Weapon_Name ] ) ) ) )
        return 0;
    
    entity_set_int( iEnt, EV_INT_spawnflags, SF_NORESPAWN );
    entity_set_int( iEnt, EV_INT_iuser1, iWeapon );
    
    DispatchSpawn( iEnt );

    if( !ExecuteHamB( Ham_AddPlayerItem, iId, iEnt ) )
    {
        entity_set_int( iEnt, EV_INT_flags, entity_get_int( iEnt, EV_INT_flags ) & FL_KILLME );
        return 0;
    }
    
    ExecuteHamB( Ham_Item_AttachToPlayer, iEnt, iId );
    ExecuteHamB( Ham_GiveAmmo, iId, g_eWeapons[ iWeapon ][ Weapon_Bullets ], g_eWeapons[ iWeapon ][ Weapon_Ammo ], g_eWeapons[ iWeapon ][ Weapon_Bullets ] );
    
    return iEnt;
}

GetSpawnPoints( )
{
    new iEnt, szName[8];
    
    for( new iIndex; iIndex < MAX_PLAYERS; iIndex++ )
    {
        formatex( szName, charsmax( szName ), "arena%d", iIndex + 1 );
        
        if( ( iEnt = find_ent_by_tname( -1, szName ) ) <= 0 )
            return false;
        
        entity_get_vector( iEnt, EV_VEC_angles, g_flSpawnAngles[ iIndex ] );
        entity_get_vector( iEnt, EV_VEC_origin, g_flSpawnOrigin[ iIndex ] );
    }
    
    return true;
}

CheckGameStatus( )
{
    if( get_playersnum( ) >= 3 )
    {
        if( g_iGame != Game_Playing )
        {
            g_iGame = Game_Playing;
            
            g_iFirstRound = 2;
            
            server_cmd( "sv_restartround 1" );
            ColorChat( 0, TEAM_COLOR, "^x04[%s]^x01 WystarczajÄ…ca iloĹ›Ä‡ graczy zostaĹ‚y osiÄ…gniÄ™te. Przygotuj siÄ™!", g_szPrefix );
        }
    }
    else if( g_iGame != Game_Waiting )
    {
        g_bNoDamage = true;
        g_iGame = Game_Waiting;
        
        server_cmd( "sv_restartround 1" );
        ColorChat( 0, TEAM_COLOR, "^x04[%s]^x01 Nie ma wystarczajacej ilosci graczy do uruchomienia rozgrywki.", g_szPrefix );
    }
}

CheckRoundStatus( )
{
    for( new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++ )
        if( GetPlayerBit( g_iAlive, iPlayer )
        && IsPlayerValid( g_ePlayerData[ iPlayer ][ Player_Enemy ] )
        && GetPlayerBit( g_iAlive, g_ePlayerData[ iPlayer ][ Player_Enemy ] ) )
            return;
    
    TerminateRound( RoundEndType_Draw );
}

UpdateLeader( )
{
    for( new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++ )
    {
        if( GetPlayerBit( g_iConnected, iPlayer ) && ( g_iLeader == 0 || g_ePlayerData[ g_iLeader ][ Player_Points ] < g_ePlayerData[ iPlayer ][ Player_Points ] ) )
            g_iLeader = iPlayer;
    }
}

GetPlayerTeam( const iPlayer )
{
    if( !GetPlayerBit( g_iConnected, iPlayer ) )
        return log_amx( "ERROR GetPlayerTeam: Uzytkownik niepodlaczony." );
    
    return get_pdata_int( iPlayer, 114 );
}

SetPlayerModel( const iId, const iModel )
{
    g_ePlayerData[ iId ][ Player_Model ] = iModel;
    set_user_info( iId, g_szCache_Model, g_szPlayerModels[ g_ePlayerData[ iId ][ Player_Model ] ] );
}

SetPlayerTeam( const iPlayer, const iTeam )
{
    if( !GetPlayerBit( g_iConnected, iPlayer ) )
        return log_amx( "ERROR SetPlayerTeam: Uzytkownik nie jest podlaczony." );
    
    static const szTeams[ ][ ] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };
    
    set_pdata_int( iPlayer, 114, iTeam );
    
    emessage_begin( MSG_BROADCAST, g_iTeamInfo );
    ewrite_byte( iPlayer );
    ewrite_string( szTeams[ iTeam ] );
    emessage_end( );
    
    return 1;
}

SetBuyConditions( )
{
    new iEnt = create_entity( "info_map_parameters" );
    
    DispatchKeyValue( iEnt, "buying", "3" );
    DispatchSpawn( iEnt );
}

/* =====================================================================
 *              [ Natives ]
 * ===================================================================== */

public _am_get_roundtime( iPlugin, iParams )
{
    if( iParams != 0 || ( g_iGame == Game_Waiting ) || ( entity_get_float( g_iHudThink, EV_FL_nextthink ) < get_gametime( ) ) )
        return -1;
    
    return g_iRemainingSeconds;
}

public _am_get_player_arena( iPlugin, iParams )
{
    if( iParams != 1 || ( g_iGame == Game_Waiting ) )
        return -1;
    
    return g_ePlayerData[ get_param( 1 ) ][ Player_Arena ];
}

public _am_get_player_points( iPlugin, iParams )
{
    if( iParams != 1 || ( g_iGame == Game_Waiting ) )
        return -1;
    
    return g_ePlayerData[ get_param( 1 ) ][ Player_Points ];
}