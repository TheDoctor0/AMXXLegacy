#include <amxmodx>
#include <zp50_gamemodes>
#include <zp50_core>

#define TASK_SHOWSCORE 7832

enum _: eTeamData
{
	WIN_NO_ONE = 0,
	WIN_ZOMBIES,
	WIN_HUMANS	
	
}; new g_iWin[ eTeamData ];

public plugin_init() 
{
	register_message( get_user_msgid( "TextMsg" ), "Message_TextMsg" );
}

public Message_TextMsg( ) 
{
	static szMessages[ 32 ];
	get_msg_arg_string( 2, szMessages, charsmax( szMessages ) );
	
	if( equal( szMessages, "#Game_will_restart_in" ) )
	{
		g_iWin[ WIN_HUMANS ] = 0;
		g_iWin[ WIN_ZOMBIES ] = 0;
		g_iWin[ WIN_NO_ONE ] = 0;
	} 
}

public zp_fw_gamemodes_end(game_mode_id)
{
	if ( !zp_core_get_zombie_count( ) ) 
		g_iWin[ WIN_HUMANS ]++;
	else if ( !zp_core_get_human_count( ) ) 
		g_iWin[ WIN_ZOMBIES ]++;
	else 
		g_iWin[ WIN_NO_ONE ]++;
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;
		
	if (!task_exists(id+TASK_SHOWSCORE))
		set_task(2.0, "ShowScore", id+TASK_SHOWSCORE, _, _, "b");
}

public client_disconnected(id)
{
	remove_task(id+TASK_SHOWSCORE);
}

public ShowScore(id)
{
	id -= TASK_SHOWSCORE;
	
	if(!is_user_connected(id))
	{
		remove_task(id+TASK_SHOWSCORE);
		return;
	}

	set_dhudmessage( .red = 0, .green = 255, .blue = 0, .x = -1.0, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.1, .fadeintime = 1.1, .fadeouttime = 0.1); 
	show_dhudmessage( id, "[ Ludzie ]                               ^n%02d                               ", zp_core_get_human_count() );
	
	set_dhudmessage( .red = 255, .green = 255, .blue = 255, .x = -1.0, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.1, .fadeintime = 0.1, .fadeouttime = 0.1); 
	show_dhudmessage( id, "[ Runda ]^n%02d", ( g_iWin[ WIN_HUMANS ] + g_iWin[ WIN_ZOMBIES ] + g_iWin[ WIN_NO_ONE ] ) );
	
	set_dhudmessage( .red = 255, .green = 0, .blue = 0, .x = -1.0, .y = 0.02, .effects = 0, .fxtime = 6.0, .holdtime = 2.1, .fadeintime = 0.1, .fadeouttime = 0.1); 
	show_dhudmessage( id, "                               [ Zombie ]^n                              %02d", zp_core_get_zombie_count());
}