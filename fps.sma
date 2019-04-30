#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Server FPS"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new bool:showFPS[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
    
	register_forward(FM_StartFrame, "start_frame");
    
	register_clcmd("say /fps", "command_fps");
}

public command_fps(id)
{
	showFPS[id] = !showFPS[id];

	client_print_color(id, id, "^4[FPS]^x01 Licznik fps serwera zostal^x04 %s^x01.", showFPS[id] ? "wlaczony" : "wylaczony");

	return PLUGIN_HANDLED;
}

public client_disconnected(id)
    showFPS[id] = false;

public start_frame()
{
    static Float:GameTime, Float:FramesPer = 0.0;
    static Float:Fps;
    
    GameTime = get_gametime();
    
    if(FramesPer >= GameTime) Fps += 1.0;
    else
    {
		FramesPer = FramesPer + 1.0;
        
		static Players[32], Num;
		get_players(Players, Num);
        
		for(new i = 0; i < Num; i++)
		{
			if(!showFPS[Players[i]]) continue;

			new fps = floatround(Fps);

			if(fps > 500) set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 0.1, 0.8, 0.8, 0.1, -1);
			else if(fps > 300 && fps < 500) set_hudmessage(255, 165, 0, -1.0, 0.3, 0, 0.8, 0.8, 0.1, 0.1, -1);
			else set_hudmessage(255, 0, 0, -1.0, 0.3, 0, 0.1, 0.8, 0.8, 0.1, -1);
			show_hudmessage(Players[i], "FPS Serwera: %.1f", Fps);
		}

		Fps = 0.0;
    }
}  