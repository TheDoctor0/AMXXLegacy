/*
AllChat v1.1
Copyright (C) 2006-2007 Ian (Juan) Cammarata

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as  published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; go to http://www.opensource.org/licenses/gpl-license.php


Description:
This plugin does for chat what sv_alltalk does for voice. Dead and alive and spectating players can all see each others chat messages. Team chat is still only visible among your team, but with no regard for whether you are dead or alive. By default this plugin works depending on whether or not sv_alltalk is on. It can be forced to be on all the time, as well as setting custom colors for messages that come from admins.


See it in Action:
Use the following link to find a server that's running this plugin:
http://www.game-monitor.com/search.php?search=allchat_version&type=variable&game=all&country=all


Cvars:
*First value is default

sv_allchat	<1|2|0>
1 - Dependent on sv_alltalk
2 - Always active
0 - Disabled

ac_namecolor <0|1|2>
ac_msgcolor <1|2|0>
0 - Team color
1 - Green
2 - White

ac_hidestatus <0|1>
0 = Show dead/spec status.
1 = Hide status.

ac_teamchat <0|1>
0 = Dead and living can't team chat.
1 = Dead and living can team chat. 


Change Log:
Key (+ added | - removed | f fixed | c changed)

v1.1 (Aug 14, 2007)
+: Cvar ac_hidestatus to show/hide dead/spec status.
+: Cvar ac_teamchat to enable/disable all chat for team chat.

v1.0.1 (June 28, 2007)
f: Replicated messages are now correctly collored based on admin flag.

v1.0 (June 26, 2007)
!Complete rewrite.
f: No longer interferes with other plugins.

v0.5 (June 21, 2007)
+: Tracking cvar.
c: Uses cvar pointers now.

v0.4 (??? ??, 2006) by Ian Cammarata & Dontask
f : Blocking text messages conataining only spaces.

v0.3 (June 23, 2006) by Ian Cammarata & Dontask
+ : Added multiple values to sv_allchat. See details in Cvar section.
+ : Added cvar ac_namecolor to change the color displayed on admins names.
+ : Added cvar ac_msgcolor to change the color displayed on admins msgs.
+ : Added colored messages even if sv_allchat is set to 1 while alltalk is set to 0.
+ : Added equivalent functionality for team say.

v0.2.1 (??? ??, 2006) by Ian Cammarata & Dontask
f : Fixed formatting color issues.

v0.2 (??? ??, 2006) by Ian Cammarata & Dontask
r : Admins name displayed in team color, message text displayed green.
+ : Displays dead status.
+ : Added cvar sv_allchat to enable allchat without alltalk enabled.

v0.1 (April 04, 2006)
+ : Initial release
*/

#include <amxmodx>

#define FLAG ADMIN_RESERVATION
#define VERSION "1.1"

new COLCHAR[3][2] = { "^x03"/*team col*/, "^x04"/*green*/, "^x01"/*white*/ }

//cvar pointers
new p_allchat, p_namecol, p_msgcol, p_alltalk, p_hidestat, p_teamchat

//vars to check if message has already been duplicated
new alv_sndr, alv_str2[26], alv_str4[101]
new msg[200]

public col_changer( msg_id, msg_dest, rcvr )
{
	new str2[26]
	get_msg_arg_string( 2, str2, 25 )
	if( equal( str2, "#Cstrike_Chat", 13 ) )
	{
		new str3[22]
		get_msg_arg_string( 3, str3, 21 )
		
		if( !strlen( str3 ) )
		{
			new str4[101]
			get_msg_arg_string( 4, str4, 100 )
			new sndr = get_msg_arg_int( 1 )
			
			new bool:is_team_msg = !bool:equal( str2, "#Cstrike_Chat_All", 17 )
			
			new sndr_team = get_user_team( sndr )
			new bool:is_sndr_spec = !bool:( 0 < sndr_team < 3 )
			
			new namecol = clamp( get_pcvar_num(p_namecol), 0, 2 )
			new msgcol = clamp( get_pcvar_num(p_msgcol), 0, 2 )
			
			new bool:same_as_last = bool:( alv_sndr == sndr && equal( alv_str2, str2 ) && equal( alv_str4, str4) )
			
			if( !same_as_last )
			{//Duplicate message once
				new allchat = clamp( get_pcvar_num( p_allchat ), 0, 2 )
				if( allchat == 2 || ( allchat == 1 && clamp( get_pcvar_num( p_alltalk ), 0, 1 ) == 1 ) )
				{
					if( !( is_team_msg && ( is_sndr_spec || is_team_msg && get_pcvar_num( p_teamchat ) == 0 ) ) )
					{//Don't duplicate if it's a spectator team message
						new flags[5], team[10]
						if( is_user_alive( sndr ) ) flags = "bch"
						else flags = "ach"
						
						if( is_team_msg )
						{
							add( flags[strlen( flags )], 4, "e" )
							if( sndr_team == 1 ) team = "TERRORIST"
							else team = "CT"
						}
						
						new players[32], num
						get_players( players, num, flags, team )

						if( get_user_flags( sndr ) & FLAG )
							buildmsg( sndr, is_sndr_spec, is_team_msg, sndr_team, namecol, msgcol, str4 ) //admin colored, by cvars
						else buildmsg( sndr, is_sndr_spec, is_team_msg, sndr_team, 0, 2, str4 ) //normal colors
						
						for( new i=0; i < num; i++ )
						{
							message_begin( MSG_ONE, get_user_msgid( "SayText" ), _, players[i] )
							write_byte( sndr )
							write_string( msg )
							message_end()
						}
						
					}
	
					alv_sndr = sndr
					alv_str2 = str2
					alv_str4 = str4
					if( task_exists( 411 ) ) remove_task( 411 )
					set_task( 0.1, "task_clear_antiloop_vars", 411 )
				}
			}
			
			if( get_user_flags( sndr ) & FLAG && ( namecol != 0 || msgcol != 2 ) )
			{//execute if sndr is admin and cols are not set to engine defaults
				if( !same_as_last ) buildmsg( sndr, is_sndr_spec, is_team_msg, sndr_team, namecol, msgcol, str4 )

				set_msg_arg_string( 2, msg )
				set_msg_arg_string( 4, "" )
			}
		}
	}
	return PLUGIN_CONTINUE
}

public buildmsg( sndr, is_sndr_spec, is_team_msg, sndr_team, namecol, msgcol, str4[ ] )
{
	new sndr_name[33]
	get_user_name( sndr, sndr_name, 32 )
	
	new prefix[30] = "^x01"
	if( get_pcvar_num( p_hidestat ) == 0 )
	{
		if( is_sndr_spec ) prefix = "^x01*SPEC* "
		else if( !is_user_alive( sndr ) ) prefix = "^x01*DEAD* "
	}
	
	if( is_team_msg )
	{
		if( is_sndr_spec ) prefix = "^x01(Spectator) "
		else if( sndr_team == 1 ) add( prefix[strlen(prefix)-1], 29, "(Terrorist) " )
		else if( sndr_team == 2 ) add( prefix[strlen(prefix)-1], 29, "(Counter-Terrorist) " )
	}
	
	format( msg, 199, "%s%s%s :  %s%s",\
		strlen( prefix ) > 1 ? prefix : "",\
		COLCHAR[namecol], sndr_name, COLCHAR[msgcol], str4 )
	return PLUGIN_HANDLED
}

public task_clear_antiloop_vars( )
{
	alv_sndr = 0
	alv_str2 = ""
	alv_str4 = ""
	return PLUGIN_HANDLED
}

public plugin_init( )
{
	register_plugin("All Chat",VERSION,"Ian Cammarata")
	register_cvar("allchat_version",VERSION,FCVAR_SERVER)
	
	p_allchat = register_cvar( "sv_allchat", "1" )
	p_namecol = register_cvar( "ac_namecolor", "0" )
	p_msgcol = register_cvar( "ac_msgcolor", "1" )
	p_hidestat = register_cvar( "ac_hidestatus", "0" )
	p_teamchat = register_cvar( "ac_teamchat", "0" )
	
	p_alltalk = get_cvar_pointer( "sv_alltalk" )
	
	register_message( get_user_msgid("SayText"), "col_changer" )
	return PLUGIN_CONTINUE
}