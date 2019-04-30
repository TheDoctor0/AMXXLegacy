#include <amxmodx>

#define PLUGIN	"Colored Flashbangs"
#define VERSION	"1.0"
#define AUTHOR	"v3x"

new g_nMsgScreenFade

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR)
	register_event("ScreenFade","FlashedEvent","be","4=255","5=255","6=255","7>199")
	g_nMsgScreenFade = get_user_msgid("ScreenFade")
	// Cvars
	register_cvar("amx_fb_mode", "2")
	register_cvar("amx_fb_r",    "255")
	register_cvar("amx_fb_g",    "25")
	register_cvar("amx_fb_b",    "25")
}

public FlashedEvent( id )
{
	new iMode = get_cvar_num("amx_fb_mode")

	if ( !iMode ) return PLUGIN_CONTINUE

	new iRed,iGreen,iBlue

	switch( iMode )
	{
		case 1:
		{
			iRed =   get_cvar_num("amx_fb_r")
			iGreen = get_cvar_num("amx_fb_g")
			iBlue =  get_cvar_num("amx_fb_b")
		}
		case 2:
		{
			iRed =   random_num(0,255)
			iGreen = random_num(0,255)
			iBlue =  random_num(0,255)
		}
	}

	if ( !( iRed ) || !( iGreen ) || !( iBlue ) )
	{
		iRed =   100
		iGreen = 100
		iBlue =  100
	}

	message_begin( MSG_ONE,g_nMsgScreenFade,{0,0,0},id )
	write_short( read_data( 1 ) )	// Duration
	write_short( read_data( 2 ) )	// Hold time
	write_short( read_data( 3 ) )	// Fade type
	write_byte ( iRed )		// Red
	write_byte ( iGreen )		// Green
	write_byte ( iBlue )		// Blue
	write_byte ( read_data( 7 ) )	// Alpha
	message_end()

	return PLUGIN_HANDLED
}