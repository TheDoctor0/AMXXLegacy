#include <amxmodx>

#define PLUGIN "Rock to Ban"
#define VERSION "1.02"
#define AUTHOR "Safety1st"

#define MAX_PLAYERS 32
#define IMMUNITY_FLAG ( ADMIN_IMMUNITY | ADMIN_BAN )
new gszPrefix[] = "[VOTEBAN]"
const VOTEBAN_NEED = 4	

new giVotedPlayers[MAX_PLAYERS + 1]
new giVotes[MAX_PLAYERS + 1]
new giVoted[MAX_PLAYERS + 1]

#define CheckFlag(%1,%2)	( %1 &   ( 1 << (%2-1) ) )
#define AddFlag(%1,%2)		( %1 |=  ( 1 << (%2-1) ) )
#define RemoveFlag(%1,%2)	( %1 &= ~( 1 << (%2-1) ) )

enum _:Labels {
	CVAR_PERCENT = 0,
	CVAR_BANTYPE,
	CVAR_BANTIME,
	CVAR_LIMIT,
	CVAR_REASON,
	CVAR_LOG
}
new pCvar[Labels]

enum _:Types {
	AUTO = 0,
	STEAMID,
	IP,
	AMXBAN,
	AMXBANS5,
	SUPERBAN,
	JAILBREAK
}

enum _:LogRecords {
	UNVOTE = 0,
	VOTE
}

new gszLogRecords[LogRecords][] = {
	"Gracz '%s' anulowal glosowanie o zbanowanie '%s'",
	"Player '%s' zostal wytypowany do glosowania o zbanowanie przez '%s'"
}

public plugin_init() {
	register_plugin( PLUGIN, VERSION, AUTHOR )
	register_dictionary( "rock2ban.txt" )
	register_cvar( "rock2ban", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED )

	register_saycmd( "voteban", "VoteBanMenu" )

	pCvar[CVAR_PERCENT] = register_cvar( "voteban_percent", "75" )
	pCvar[CVAR_BANTYPE] = register_cvar( "voteban_type", "6" )
	pCvar[CVAR_BANTIME] = register_cvar( "voteban_time", "60" )
	pCvar[CVAR_LIMIT] = register_cvar( "voteban_limit", "9" )
	pCvar[CVAR_REASON] = register_cvar( "voteban_reason", " VoteBan " )
	pCvar[CVAR_LOG] = register_cvar( "voteban_log", "1" )
}

register_saycmd( saycommand[], function[] ) {
	new szTemp[64]
	formatex( szTemp, charsmax(szTemp), "say %s", saycommand )
	register_clcmd( szTemp, function )
	formatex( szTemp, charsmax(szTemp), "say_team %s", saycommand )
	register_clcmd( szTemp, function )
	formatex( szTemp, charsmax(szTemp), "say /%s", saycommand )
	register_clcmd( szTemp, function )
	formatex( szTemp, charsmax(szTemp), "say .%s", saycommand )
	register_clcmd( szTemp, function )
	formatex( szTemp, charsmax(szTemp), "say_team /%s", saycommand )
	register_clcmd( szTemp, function )
	formatex( szTemp, charsmax(szTemp), "say_team .%s", saycommand )
	register_clcmd( szTemp, function )
}

public client_disconnected(id) {
	static iPlayers[32], iPlayersNum, i, iPlayer


	if ( giVoted[id] ) {
		get_players( iPlayers, iPlayersNum, "ch" )	
		for ( i = 0; i < iPlayersNum; i++ ) {
			iPlayer = iPlayers[i]
			if ( CheckFlag( giVotedPlayers[id], iPlayer ) )
				giVotes[iPlayer]--
		}
		giVotedPlayers[id] = 0
		giVoted[id] = 0
	}


	if ( giVotes[id] ) {
		get_players( iPlayers, iPlayersNum, "ch" )	
		for ( i = 0; i < iPlayersNum; i++ ) {
			iPlayer = iPlayers[i]
			if ( CheckFlag( giVotedPlayers[iPlayer], id ) ) {
				RemoveFlag( giVotedPlayers[iPlayer], id )
				giVotes[id]--
				giVoted[iPlayer]--
			}
			if ( !giVotes[id] )
				break
		}
		giVotes[id] = 0	
	}
}

public VoteBanMenu(id) {
	static iPlayers[32], iPlayersNum, i, iPlayer, bool:iAdmin

	get_players( iPlayers, iPlayersNum, "ch" )
	if ( iPlayersNum < VOTEBAN_NEED ) 
	{
		ColorPrint( id, "^4%s %L", gszPrefix, id, "VOTEBAN_NEEDX", VOTEBAN_NEED )
		return PLUGIN_HANDLED
	}
	
	for ( i = 0; i < iPlayersNum; i++ ) 
	{
		iPlayer = iPlayers[i]

		if ( get_user_flags(iPlayer) & ADMIN_BAN )
			iAdmin = true
	}
	
	if( iAdmin ) 
	{
		ColorPrint( id, "^4%s %L", gszPrefix, id, "VOTEBAN_ADMIN" )
		return PLUGIN_HANDLED
	}

	new szTempString[64], szName[32], szInfo[3]
	formatex( szTempString, charsmax(szTempString), "%L\y:", id, "VOTEBAN_MENU" )
	new iMenu = menu_create( szTempString, "MenuHandle", .ml = 1 )
	new iCallback = menu_makecallback( "CallbackMenu" )
	menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\r" )
	menu_setprop( iMenu, MPROP_EXIT, MEXIT_ALL )
	formatex( szTempString, charsmax(szTempString), "%L", id, "VOTEBAN_EXIT" )
	menu_setprop( iMenu, MPROP_EXITNAME, szTempString )
	formatex( szTempString, charsmax(szTempString), "%L", id, "VOTEBAN_NEXT" )
	menu_setprop( iMenu, MPROP_NEXTNAME, szTempString )
	formatex( szTempString, charsmax(szTempString), "%L", id, "VOTEBAN_BACK" )
	menu_setprop( iMenu, MPROP_BACKNAME, szTempString )

	new iPercent
	for ( i = 0; i < iPlayersNum; i++ ) {
		iPlayer = iPlayers[i]
		get_user_name( iPlayer, szName, 31 )
		if ( get_user_flags(iPlayer) & IMMUNITY_FLAG ) {

			menu_additem( iMenu, szName, "", .callback = iCallback )
		}
		else {
			iPercent = get_percent( giVotes[iPlayer], iPlayersNum )
			if ( giVotes[iPlayer] && CheckFlag( giVotedPlayers[id], iPlayer ) )
				formatex( szTempString, charsmax(szTempString), "%s \d(\r%d%%\d) \y%L", szName, iPercent, id, "VOTEBAN_VOTED" )
			else
				formatex( szTempString, charsmax(szTempString), "%s \d(\r%d%%\d)", szName, iPercent )
			num_to_str( iPlayer, szInfo, charsmax(szInfo) )
			menu_additem( iMenu, szTempString, szInfo, .callback = iCallback )
		}
	}

	menu_display( id, iMenu )

	return PLUGIN_CONTINUE
}

public CallbackMenu( id, menu, item ) {
	new access, info[3], callback, szTempString[64]
	menu_item_getinfo( menu, item, access, info, charsmax(info), szTempString, charsmax(szTempString), callback )

	if ( !info[0] )

		return ITEM_DISABLED

	if ( str_to_num(info) == id )
		return ITEM_DISABLED

	return ITEM_ENABLED
}

public MenuHandle( id, menu, item ) {
	if ( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new access, info[3], callback
	menu_item_getinfo( menu, item, access, info, charsmax(info), .callback = callback )
	menu_destroy(menu)

	new iTarget = str_to_num(info)

	if ( !is_user_connected(iTarget) ) {
		VoteBanMenu(id)
		return PLUGIN_HANDLED
	}

	if ( CheckFlag( giVotedPlayers[id], iTarget ) ) {
		RemoveFlag( giVotedPlayers[id], iTarget )
		giVoted[id]--
		giVotes[iTarget]--

		new szName[32], szTargetName[32]
		get_user_name( id, szName, 31 )
		get_user_name( iTarget, szTargetName, 31 )
		MsgToLog( gszLogRecords[UNVOTE], szName, szTargetName )
		ColorPrint( 0, "^4%s %L", gszPrefix, LANG_SERVER, "VOTEBAN_UNVOTE", szName, szTargetName )
		client_print( id, print_center, "%L", id, "VOTEBAN_CLEAR" )
		return PLUGIN_HANDLED
	}

	new iLimit = get_pcvar_num( pCvar[CVAR_LIMIT] )
	if ( giVoted[id] >= iLimit ) {

		client_print( id, print_center, "%L", id, "VOTEBAN_LIMIT", iLimit )
		return PLUGIN_HANDLED
	}

	client_print( id, print_center, "%L", id, "VOTEBAN_SET" )
	giVoted[id]++
	giVotes[iTarget]++
	AddFlag( giVotedPlayers[id], iTarget )

	CheckVotes( iTarget, id )

	return PLUGIN_HANDLED
}

CheckVotes( target, voter ) {
	new szName[32], szTargetName[32]
	get_user_name( voter, szName, 31 )
	get_user_name( target, szTargetName, 31 )

	MsgToLog( gszLogRecords[VOTE], szTargetName, szName )
	ColorPrint( 0, "^4%s %L", gszPrefix, LANG_SERVER, "VOTEBAN_VOTE", szName, szTargetName )

	new iPlayers[32], iPlayersNum
	get_players( iPlayers, iPlayersNum, "ch" )	// skip bots and HLTV

	if ( get_percent( giVotes[target], iPlayersNum ) < get_pcvar_num( pCvar[CVAR_PERCENT] ) )
		return

	new iUserid = get_user_userid(target)
	new iType = get_pcvar_num( pCvar[CVAR_BANTYPE] )
	new iBanTime = get_pcvar_num( pCvar[CVAR_BANTIME] )
	new szAuthid[32], szReason[256]
	get_pcvar_string( pCvar[CVAR_REASON], szReason, charsmax(szReason) )

	switch ( iType ) {
		case AMXBAN, AMXBANS5, SUPERBAN : {
			// clear unused template
			replace( szReason, charsmax(szReason), "%time%", " " )
		}
		case JAILBREAK: ColorPrint( 0, "^4%s %L", gszPrefix, LANG_SERVER, "VOTEBAN_BANCT", szTargetName)
		default : {
			static szHostname[64]
			if ( !szHostname[0] )
				get_cvar_string( "hostname", szHostname, 63 )
			get_user_authid( target, szAuthid, charsmax(szAuthid) )
			log_amx( "Ban: ^"%s<0><><>^" ban and kick ^"%s<%d><%s><>^" (minutes ^"%d^") (reason ^"Voteban^")", szHostname, szTargetName, iUserid, szAuthid, iBanTime )
			ColorPrint( 0, "^4%s %L", gszPrefix, LANG_SERVER, "VOTEBAN_BAN", szTargetName, iBanTime )
			// set actual ban time in the reason
			if ( containi( szReason, "%time%" ) != -1 ) {
				new szBanTime[4]
				num_to_str( iBanTime, szBanTime, 3 )
				replace( szReason, charsmax(szReason), "%time%", szBanTime )
			}
		}
	}

	if ( !iType ) { 	// AUTO
		/* AMXX base plugin 'plmenu.amxx', code by MistaGee
		IF AUTHID STEAM_ID_LAN OR VALVE_ID_LAN OR HLTV, BAN PER IP TO DON'T BAN EVERYONE */
		if ( equal( "STEAM_ID_LAN", szAuthid ) || equal( "VALVE_ID_LAN", szAuthid ) || equal( "HLTV", szAuthid ) )
			iType = IP
		else
			iType = STEAMID
	}
	
	switch ( iType ) {
		case STEAMID :
			server_cmd( "kick #%d %s;wait;wait;wait;banid %d %s", iUserid, szReason, iBanTime, szAuthid )
		case IP : {
			new szIp[32]
			get_user_ip( target, szIp, charsmax(szIp), 1 /* without_port */ )
			server_cmd( "kick #%d %s;wait;wait;wait;addip %d %s", iUserid, szReason, iBanTime, szIp )
		}
		case AMXBAN :
			server_cmd( "amx_ban #%d %d ^"%s^"", iUserid, iBanTime, szReason )
		case AMXBANS5 :
			server_cmd( "amx_ban %d #%d ^"%s^"", iBanTime, iUserid, szReason )
		case SUPERBAN :
			server_cmd( "amx_superban #%d %d ^"%s^"", iUserid, iBanTime, szReason )
		case JAILBREAK :
		{
			server_cmd( "amx_mute2 ^"%s^"", szTargetName )
			server_cmd( "jail_ctban ^"%s^" ^"VoteBan^"", szTargetName )
		}
	}
}

get_percent( value, tvalue ) {
	return floatround( floatmul( float(value) / float(tvalue) , 100.0 ) )
}

MsgToLog( szRawMessage[], any:... ) {
	if ( !get_pcvar_num( pCvar[CVAR_LOG] ) )
		return

	static szLogFile[192] = "", szTime[32], fp
	if ( !szLogFile[0] ) {
		new szLogsDir[64], szDate[16]
		get_time ( "%Y%m", szDate, charsmax(szDate) )
		get_localinfo( "amxx_logs", szLogsDir, 63 ) 
		formatex( szLogFile, charsmax(szLogFile), "%s/voteban_%s.log", szLogsDir, szDate )
	}

	new szMessage[192]
	vformat( szMessage, charsmax( szMessage ), szRawMessage, 2 )

	get_time( "%m/%d/%Y - %H:%M:%S", szTime, 31 ) 
	fp = fopen( szLogFile, "a" )
	fprintf( fp, "L %s: %s^n", szTime, szMessage )
	fclose(fp) 
}

ColorPrint( iReceiver, const szRawMessage[ ], any:... ) {
	static iMsgSayText = 0
	if( !iMsgSayText )
		iMsgSayText = get_user_msgid( "SayText" )

	new szMessage[192], iPlayers[32], iPlayersNum = 1, iPlayer
	vformat( szMessage, charsmax(szMessage), szRawMessage, 3 )
	replace_all( szMessage, charsmax(szMessage), "!n", "^1" )
	replace_all( szMessage, charsmax(szMessage), "!t", "^3" )
	replace_all( szMessage, charsmax(szMessage), "!g", "^4" )
	if ( szMessage[0] != '^1' || szMessage[0] != '^3' || szMessage[0] != '^4' )
		format( szMessage, charsmax(szMessage), "^1%s", szMessage )	// we must set initial default color if it is not provided explicitly

	if ( iReceiver )
		iPlayers[0] = iReceiver
	else {
		get_players( iPlayers, iPlayersNum, "ch" )	// skip bots and HLTV
		if ( !iPlayersNum )
			return	// don't print useless message
	}

	for ( new i = 0 ; i < iPlayersNum ; i++ ) {
		iPlayer = iPlayers[i]
		message_begin( MSG_ONE_UNRELIABLE, iMsgSayText, _, iPlayer )
		write_byte(iPlayer)	// use target player as sender to see colors at all (and his own team color for ^3)
		write_string(szMessage)
		message_end()
	}
}
