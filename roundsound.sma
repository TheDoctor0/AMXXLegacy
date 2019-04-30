#include <amxmodx>
#include <amxmisc>
#include <nvault>

#define PLUGIN "RoundSound"
#define VERSION "2.3"
#define AUTHOR "speedkill & O'Zone"

new const g_Prefix[] = "RS"

new Array:g_PathCT,
	Array:g_PathTT,
	Array:g_SoundNameCT,
	Array:g_SoundNameTT;

new bool:g_RoundSound[33],
	bool:g_ShowAds[33],
	bool:g_FirstPlay,
	bool:g_MusicPlaying;

new g_LastSong[96],
	g_ShowInfo[33],
	g_ArraySize[4],
	g_ValueTeam[2],
	g_MaxPlayers,
	g_PlaylistType,
	g_RandomMusic;

new const g_ShowNames[][]={
	"Brak",
	"Czat"
};

new const g_LangCmd[][]={
	"say /rsy",	
	"say_team /rsy",
	"say /roundsound",
	"say_team /roundsound"
};

new const g_LastLangCmd[][]={
	"say /last",
	"say_team /last",
	"say /ostatnia",
	"say_team /ostatnia"
};

new roundsound;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i = 0; i < sizeof g_LangCmd; i++)
		register_clcmd(g_LangCmd[i], "ShowRsMenu");
	
	for(new i = 0; i < sizeof g_LastLangCmd; i++)
		register_clcmd(g_LastLangCmd[i], "ShowLastSong");
		
	register_event("SendAudio", "PlaySoundTT", "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "PlaySoundCT", "a", "2&%!MRAD_ctwin");
	
	register_logevent("RoundStart", 2, "1=Round_Start");

	roundsound = nvault_open("roundsound");
}

public plugin_precache(){
	g_PathCT = ArrayCreate(128);
	g_PathTT = ArrayCreate(128);
	
	g_SoundNameCT = ArrayCreate(96);
	g_SoundNameTT = ArrayCreate(96);
	
	new g_Path[128];
	formatex(g_Path[ get_configsdir(g_Path, charsmax(g_Path)) ], charsmax(g_Path), "/roundsound.ini");
	
	if(file_exists(g_Path)){
		new g_Line[256],
			g_SoundPath[128],
			g_Name[96],
			g_Team[6],
			g_Len,
			g_Loaded = 0,
			g_LoadedCT = 0,
			g_LoadedTT = 0;
		
		for(new i = 0; read_file(g_Path, i, g_Line, charsmax(g_Line), g_Len); i++){
			if(!g_Len || !g_Line[0] || g_Line[0] == ';' || !i)
				continue;

			parse(g_Line, g_SoundPath, charsmax(g_SoundPath), g_Name, charsmax(g_Name), g_Team, charsmax(g_Team));
			
			new g_Value = strlen(g_SoundPath) - 4;
			
			if(equal(g_SoundPath[ g_Value ], ".mp3") || equal(g_SoundPath[ g_Value ], ".wav")){
				if(equal(g_SoundPath[ g_Value ], ".mp3")){
					format(g_SoundPath, charsmax(g_SoundPath), "sound/%s", g_SoundPath);
					precache_generic(g_SoundPath);
				}
				else
					precache_sound(g_SoundPath);
				
				if(contain(g_Team, "CT") != -1){
					ArrayPushString(g_PathCT, g_SoundPath);
					ArrayPushString(g_SoundNameCT, g_Name);
					g_LoadedCT++;
				}
				if(contain(g_Team, "TT") != -1){
					ArrayPushString(g_PathTT, g_SoundPath);
					ArrayPushString(g_SoundNameTT, g_Name);
					g_LoadedTT++;
				}
				g_Loaded++;
			}
			else
				log_amx("Plik %s ma niewlasciwy format.", g_SoundPath);
		}
		log_amx("Zaladowano poprawnie %i utworow! (Dla CT: %i | Dla TT: %i)", g_Loaded, g_LoadedCT, g_LoadedTT);
	}
	else
		set_fail_state("Brak pliku roundsound.ini w configs/.");

	GetArraySize();
}

public plugin_cfg() {
	g_RandomMusic = 1;
	
	g_MaxPlayers = get_maxplayers();
	
	set_task(300.0, "ShowAds",.flags = "b");
	
	g_ValueTeam[0] = g_ValueTeam[1] = -1;
}

public client_putinserver(id){
	g_RoundSound[id] = true;
	
	g_ShowAds[id]  = true;
	
	g_ShowInfo[id] = 1;

	load_settings(id);
}

public GetArraySize(){
	g_ArraySize[0] = ArraySize(g_PathCT);
	g_ArraySize[1] = ArraySize(g_PathTT);
	g_ArraySize[2] = ArraySize(g_SoundNameCT);
	g_ArraySize[3] = ArraySize(g_SoundNameTT);
}

public ShowRsMenu(id){
	new g_FormatText[64];
	
	new g_Menu = menu_create("\wRoundSound \yUstawienia", "MenuChoose");
	
	formatex(g_FormatText, charsmax(g_FormatText), "\yRoundsound: \r[\d%s\r]", g_RoundSound[id] ? "ON" : "OFF");
	menu_additem(g_Menu, g_FormatText);
	
	menu_additem(g_Menu, "\rOdsluchaj utwory \yCT \d[\yPlaylista\d]");
	menu_additem(g_Menu, "\yOdsluchaj utwory \rTT \d[\rPlaylista\d]");
	
	formatex(g_FormatText, charsmax(g_FormatText), "\rReklamy: \y[\d%s\y]", g_ShowAds[id] ? "ON" : "OFF");
	menu_additem(g_Menu, g_FormatText);
	
	formatex(g_FormatText, charsmax(g_FormatText), "\yWyswietlanie nazwy \rutworu: \y[\d%s\y]", g_ShowNames[ g_ShowInfo[id] ]);
	menu_additem(g_Menu, g_FormatText);
	
	menu_setprop(g_Menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, g_Menu);
}

public MenuChoose(id, g_Menu, g_Item){
	if(g_Item == MENU_EXIT){
		menu_destroy(g_Menu);
		return PLUGIN_HANDLED;
	}
	
	switch(g_Item){
		case 0:{
			g_RoundSound[id] = !g_RoundSound[id];
			client_print_color(id, id, "^x04[%s]^x01 Roundsound:^x03 %s^x01.", g_Prefix, g_RoundSound[id] ? "wlaczony" : "wylaczony");
			
			ShowRsMenu(id);
		}
		
		case 1..2: ShowPlaylist(id, g_Item);
		
		case 3:{
			g_ShowAds[id] = !g_ShowAds[id];
			client_print_color(id, id, "^x04[%s]^x01 Reklamy:^x03 %s^x01.", g_Prefix, g_ShowAds[id] ? "wlaczone" : "wylaczone");
			
			ShowRsMenu(id);

		}
		
		case 4:{
			if(g_ShowInfo[id] >= 1)
				g_ShowInfo[id] = -1;

			g_ShowInfo[id]++;
			
			ShowRsMenu(id);
		}
	}

	menu_destroy(g_Menu);

	save_settings(id);

	return PLUGIN_HANDLED;
}

public ShowPlaylist(id, g_Type){
	new g_FormatText[64],
		g_Name[96];
		
	formatex(g_FormatText, charsmax(g_FormatText), "Playlista \d%s", g_Type == 1 ? "CT" : "TT");
	new g_Menu = menu_create(g_FormatText, "PlaylistChoose");
	
	switch(g_Type){
		case 1:{
			for(new g_Item = 0; g_Item < g_ArraySize[2]; g_Item++){
				ArrayGetString(g_SoundNameCT, g_Item, g_Name, charsmax(g_Name));
				menu_additem(g_Menu, g_Name);
			}
		}
		case 2:{
			for(new g_Item = 0; g_Item < g_ArraySize[3]; g_Item++){
				ArrayGetString(g_SoundNameTT, g_Item, g_Name, charsmax(g_Name));
				menu_additem(g_Menu, g_Name);
			}
		}
	}
	g_PlaylistType = g_Type;
	
	menu_setprop(g_Menu, MPROP_BACKNAME, "Powrot");
	menu_setprop(g_Menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(g_Menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(g_Menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_display(id, g_Menu);
}

public PlaylistChoose(id, g_Menu, g_Item){
	if(g_Item == MENU_EXIT){
		menu_destroy(g_Menu);
		return PLUGIN_HANDLED;
	}
	
	new g_SoundPath[128];
	ArrayGetString(g_PlaylistType == 1 ? g_PathCT : g_PathTT, g_Item, g_SoundPath, charsmax(g_SoundPath));
	
	new g_Format = strlen(g_SoundPath) - 4;
	
	if(equal(g_SoundPath[ g_Format ], ".mp3"))
		client_cmd(id, "mp3 play %s", g_SoundPath);
	else
		client_cmd(id, "spk %s", g_SoundPath);

	ShowPlaylist(id, g_PlaylistType);
	
	return PLUGIN_CONTINUE;
}

public ShowLastSong(id){
	if(g_FirstPlay)
		client_print_color(id, id, "^x04[%s]^x01 Ostatni utwor:^x03 %s^x01.", g_Prefix, g_LastSong);
	else
		client_print_color(id, id, "^x04[%s]^x01 Nie zostala odegrana zadna^x03 piosenka^x01.!", g_Prefix);
}

public RoundStart()
	g_MusicPlaying = false;

public PlaySoundTT()
	CheckMusic(1);

public PlaySoundCT()
	CheckMusic(2);

public CheckMusic(g_Type){
	if(!g_MusicPlaying){
		RandMusic(g_Type);
		g_MusicPlaying = true;
	}
}

public RandMusic(g_Type){
	if(!g_FirstPlay)
		g_FirstPlay = true;
	
	new g_SoundPath[128],
		g_SoundName[128],
		g_Name[96],
		g_Format,
		g_FileFormat;
		
	
	switch(g_Type){
		case 1:{
			if(g_RandomMusic){
				g_ValueTeam[0] = random(g_ArraySize[1]);
			}
			else{
				g_ValueTeam[0]++;
				
				if(g_ValueTeam[0] >= g_ArraySize[1]){
					g_ValueTeam[0] = 0;
				}
			}
			
			ArrayGetString(g_PathTT, g_ValueTeam[0], g_SoundPath, charsmax(g_SoundPath));
			ArrayGetString(g_SoundNameTT, g_ValueTeam[0], g_Name, charsmax(g_Name));
		}
		case 2:{
			if(g_RandomMusic)
				g_ValueTeam[1] = random(g_ArraySize[0]);
			else{
				g_ValueTeam[1]++;
				
				if(g_ValueTeam[1] >= g_ArraySize[0]){
					g_ValueTeam[1] = 0;
				}
			}
			
			ArrayGetString(g_PathCT, g_ValueTeam[1], g_SoundPath, charsmax(g_SoundPath));
			ArrayGetString(g_SoundNameCT, g_ValueTeam[1], g_Name, charsmax(g_Name));
		}
	}
	
	copy(g_LastSong, charsmax(g_LastSong), g_Name);
	
	g_Format = strlen(g_SoundPath) - 4;
	
	if(equal(g_SoundPath[ g_Format ], ".mp3"))
		g_FileFormat = 1;
	else
		g_FileFormat = 2;
	
	formatex(g_SoundName, charsmax(g_SoundName), "Teraz gramy:^x03 %s^x01.", g_Name);
	
	for(new i = 1; i <= g_MaxPlayers; i++){
		if(is_user_connected(i) && g_RoundSound[i]){
			switch(g_FileFormat){
				case 1: client_cmd(i, "mp3 play %s", g_SoundPath);
				case 2: client_cmd(i, "spk %s", g_SoundPath);
			}
			if(g_ShowInfo[i])
				client_print_color(i, i, "^x04[%s]^x01 %s", g_Prefix, g_SoundName);
		}
	}
	return PLUGIN_CONTINUE;
}

public ShowAds(){
	for(new i = 1; i <= g_MaxPlayers; i++){
		if(is_user_connected(i) && g_ShowAds[i]){
			switch(random(3)){
				case 0: client_print_color(i, i, "^x04[%s]^x01 Chcesz^x04 %s^x01 roundsound? Wpisz^x03 /roundsound^x01 lub^x03 /rsy", g_Prefix, g_RoundSound[i] ? "wylaczyc" : "wlaczyc");
				case 1: client_print_color(i, i, "^x04[%s]^x01 Podobala Ci sie ostatnia piosenka, a nie pamietasz jej nazwy? Wpisz^x03 /last^x01 lub ^x03/ostatnia", g_Prefix);
				case 2: client_print_color(i, i, "^x04[%s]^x01 Chcesz posluchac utworow CT / TT? Wpisz^x03 /roundsound^x01 lub^x03 /rs", g_Prefix);
			}
		}
	}
}

public plugin_end(){
	ArrayDestroy(g_PathCT);
	ArrayDestroy(g_PathTT);
	ArrayDestroy(g_SoundNameCT);
	ArrayDestroy(g_SoundNameTT);
}

public save_settings(id)
{
	new vaultKey[64], vaultData[16], playerName[32];

	get_user_name(id, playerName, charsmax(playerName));
	
	formatex(vaultKey, charsmax(vaultKey), "%s-roundsound", playerName);
	formatex(vaultData, charsmax(vaultData), "%d %d %d", g_RoundSound[id], g_ShowAds[id], g_ShowInfo[id]);
	
	nvault_set(roundsound, vaultKey, vaultData);
	
	return PLUGIN_CONTINUE;
}

public load_settings(id)
{
	new vaultKey[64], vaultData[16], playerName[32], tempData[3][3];

	get_user_name(id, playerName, charsmax(playerName));
	
	formatex(vaultKey, charsmax(vaultKey), "%s-roundsound", playerName);
	
	if(nvault_get(roundsound, vaultKey, vaultData, charsmax(vaultData)))
	{
		parse(vaultData, tempData[0], charsmax(tempData), tempData[1], charsmax(tempData), tempData[2], charsmax(tempData));

		if(!str_to_num(tempData[0])) g_RoundSound[id] = false;
		if(!str_to_num(tempData[1])) g_ShowAds[id] = false;
		if(!str_to_num(tempData[2])) g_ShowInfo[id] = 0;
	}

	return PLUGIN_CONTINUE;
} 