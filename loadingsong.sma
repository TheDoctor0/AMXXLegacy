//Loading Music Also In Spectator Mode
//by Torch
//MP3 ONLY
//Copy MP3 file to sound/misc/loading.mp3
//Music will still play after the player has joined server until he chooses a team.
//Music will start playing again if the person goes back to spectator mode
//(not DEAD spectator, only Team Select>Spectator)

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

new bool:playing[32]

public plugin_init() { 
	register_plugin("Loading Song","1.0","O'Zone")
	for (new i=0;i<32;i++)
	{
		playing[i]=false
	}
	return PLUGIN_CONTINUE 
} 

public plugin_precache() {
	precache_sound("misc/[ZH]BestLoading.mp3")
	return PLUGIN_CONTINUE 
}

public client_connect(id) {
	play_song(id)
	return PLUGIN_CONTINUE
} 

public play_song(id) {
	client_cmd(id,"mp3 loop sound/misc/[ZH]BestLoading.mp3")
	return PLUGIN_HANDLED
}

public play_song_task(params[],id) {
	new player = params[0]
	client_cmd(player,"mp3 loop sound/misc/[ZH]BestLoading.mp3")
	return PLUGIN_HANDLED
}

public client_putinserver(id)
	client_cmd(id, "mp3 stop")
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
