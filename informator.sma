			/* This plugin is made by xakintosh with Amxmodx Studio 1.4.3 (final) */
						// Spolszczenie - [H]ARDBO[T] //
						
					      /////////////////CVARY/////////////////////
					      //srv_hud_rgb "0 255 0" - kolor napisów////
					      //srv_hud_x "0.11" - X pozycja na ekranie//
					      //srv_hud_y "0.01" - Y poyzcja na ekranie//
					      //srv_hud_effects "0" - mrygaj¹cy effekt///			
					      ///////////////////////////////////////////			
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new hud_rgb, hud_x, hud_y, hud_effects,g_round = 1,maxplayers,hudsync

public plugin_init() {
	register_plugin("Info","1.0","OZone")
	hud_rgb = register_cvar( "srv_hud_rgb", "255 215 0" )
	hud_x = register_cvar( "srv_hud_x", "0.6" )
	hud_y = register_cvar( "srv_hud_y", "0.01" )
	hud_effects = register_cvar( "srv_hud_effects", "0" )
	hudsync = CreateHudSyncObj()
	maxplayers = get_maxplayers()
	set_task(0.1, "Fwd_StartFrame", 1, "", 0, "b")
	register_forward(FM_StartFrame, "Fwd_StartFrame")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
}
public Fwd_StartFrame(id) {
	new timestring[31]
	get_time("%H:%M:%S",timestring,8)
	static Float:GameTime, Float:FramesPer = 0.0
	static Float:Fps
	GameTime = get_gametime()
	if(FramesPer >= GameTime)
		Fps += 1.0;
	else {
		FramesPer = FramesPer + 1.0
		for( new id = 1; id <= maxplayers; id++ ) { 
			new ip[42],red, green, blue
			new timeleft = get_timeleft()
			get_hud_color(red, green, blue)
			get_user_ip(0, ip, 31, 1)
			set_hudmessage(red,green,blue,get_pcvar_float(hud_x),get_pcvar_float(hud_y),get_pcvar_num(hud_effects),6.0,1.0)
			ShowSyncHudMsg(id,hudsync,"*** Czas do konca : %d:%02d | Godzina: %s ***",timeleft / 60, timeleft % 60,timestring)
		}
		Fps = 0.0
	}
}
get_hud_color(&r, &g, &b) {
	new color[20]
	static red[5], green[5], blue[5]
	get_pcvar_string(hud_rgb, color, charsmax(color))
	parse(color, red, charsmax(red), green, charsmax(green), blue, charsmax(blue))
	r = str_to_num(red)
	g = str_to_num(green)
	b = str_to_num(blue)
}
