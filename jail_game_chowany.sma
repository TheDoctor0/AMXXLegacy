#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <engine>
#include <jailbreak>

#define PLUGIN "JailBreak: Chowany"
#define VERSION "1.0.7"
#define AUTHOR "Cypis"

new bool:g_ChoosenColor[MAX+1], fPlayerPreThink, fCmdStart, bool:usun;
new czas, gMsgScreenFade;

new const g_FlashlightColors[][3] = 
{ 
	{255,0,0},//czerwony
	{0,255,0},//zielony
	{0,0,255},//niebieski
	{255,69,0},//pomaranczowy
	{0,255,255},//aqua
	{255,255,0},//zolty
	{255,0,255},//rozowy
	{255,255,255}//bialy
};

new const g_FlashlightColorNames[][] = 
{ 
	"Czerwonym",
	"Zielonym",
	"Niebieskim",
	"Pomaranczowym",
	"Aqua",
	"Zoltym",
	"Rozowym",
	"Bialy ratuje!"
};

new bool:g_HasFlashOn[MAX+1], g_FlashColor[MAX+1];

new id_zabawa;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_zabawa = jail_register_game("Chowany");
	
	czas = register_cvar("time_black_screen","60.0")
	gMsgScreenFade = get_user_msgid("ScreenFade")
}

public plugin_precache()
	precache_generic("sound/reload/chowany.mp3");

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		RegisterChowany(false);
		
		set_lights("#OFF");
		
		usun = false;
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{	
		formatex(szInfo2, 256, "Zasady:^nWiezniowie maja czas na schowanie sie^nStraznicy zaczynaja szukac^nOstatni wiezien ma zyczenie");
		szInfo = "Dzisiaj jest Chowany";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
			
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[7] = 2;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		jail_open_cele();
		jail_set_game_hud(30, "Rozpoczecie zabawy za");

		client_cmd(0, "mp3 play sound/reload/chowany.mp3");
		
		RegisterChowany(true);
		oslep();
	}
}

public oslep()
{
	for(new id=0;id<=32;id++)
	{
		if(is_user_alive(id) && get_user_team(id) == 2)
		{
			Display_Fade(id,(1<<12) * 1,(1<<12) * get_pcvar_num(czas)/6,0x0001,0,0,0,255)
			set_task(get_pcvar_float(czas)/6, "blackscreen", id, _, _, "a", 5)
		}
	}
}

public blackscreen(id)
{
	for(new id=0;id<=32;id++)
	{
		if(is_user_alive(id) && get_user_team(id) == 2)
		{
			Display_Fade(id,(1<<12) * 1,(1<<12) * get_pcvar_num(czas)/6,0x0001,0,0,0,255)
		}
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		if(!usun)
		{
			set_lights("a");
			jail_set_ct_hit_tt(false);
			jail_set_game_hud(300, "Zakonczenie zabawy za");
		}
		else
		{
			jail_set_play_game(USUWANIE_DANYCH, true);
			set_lights("#OFF");	
			
			RegisterChowany(false);
			jail_set_god_ct(true);
			for(new i=1; i<=32; i++)
			{
				if(!is_user_alive(i) || !is_user_connected(i))
					continue;
				g_ChoosenColor[i] = false;		
				set_user_maxspeed(i, 250.0);
				jail_set_prisoners_fight(true, false, true);
				client_print(i, print_center, "Koniec zabawy. Wiezniowie walcza o zyczenie");
	
				if(get_user_team(i) == 1)
				{
				give_item(i,"weapon_ak47");
				give_item(i,"ammo_762nato");
				give_item(i,"ammo_762nato");
				give_item(i,"ammo_762nato");
				}
			}
		}
		usun = !usun;
	}
}

//
RegisterChowany(bool:wartosc)
{
	if(wartosc)
	{
		if(!fPlayerPreThink)
			fPlayerPreThink = register_forward(FM_PlayerPreThink, "PreThink");
		
		if(!fCmdStart)
			fCmdStart = register_forward(FM_CmdStart, "fwCmdStart");
	}
	else
	{
		if(fPlayerPreThink)
		{
			unregister_forward(FM_PlayerPreThink, fPlayerPreThink);
			fPlayerPreThink = 0;
		}
		if(fCmdStart)
		{
			unregister_forward(FM_CmdStart, fCmdStart);
			fCmdStart = 0;
		}
	}
}

public showColorMenu(id)
{
	new menu = menu_create("\yZostales znaleziony! Wybierz nastepny kolor latarki!^nMasz\w 5\y sekund", "Handel_Kolor");

	menu_additem(menu, "Czerwony");
	menu_additem(menu, "Zielony");
	menu_additem(menu, "Niebieski");
	menu_additem(menu, "Pomaranczowy");
	menu_additem(menu, "Aqua");
	menu_additem(menu, "Zolty");
	menu_additem(menu, "Rozowy");

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, menu);
}

public Handel_Kolor(id, menu, item)
{
	if(item == MENU_EXIT || get_user_team(id) != 1 || !is_user_alive(id))
		return;
	
	new szColor[32], szName[32], acces, callback, data[2];
	get_user_name(id, szName, 31);
	menu_item_getinfo(menu, item, acces, data, 1, szColor, 31, callback);

	set_user_rendering(id, kRenderFxGlowShell, g_FlashlightColors[item][0], g_FlashlightColors[item][1], g_FlashlightColors[item][2], kRenderNormal, 1);
	client_print_color(0, id, "^x04[CHOWANY]^x03 %s^x01 wybral kolor^x03 %s", szName, szColor);
	
	SprwaczCzyOstatni();
}

SprwaczCzyOstatni()
{
	new bool:koniec = false;
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 1)
			continue;
			
		koniec = true;
		if(!g_ChoosenColor[i])
		{
			koniec = false;
			break;
		}
	}
	if(koniec)
	{
		jail_remove_game_hud();
		jail_set_play_game(USUWANIE_DANYCH, true);
		
		set_lights("#OFF");	
			
		RegisterChowany(false);
	
		for(new i=1; i<=MAX; i++)
		{
			g_ChoosenColor[i] = false;
			if(is_user_alive(i) && is_user_connected(i))			
				set_user_maxspeed(i, 250.0);
		}
	}
}

public fwCmdStart(id, uc)
{
	if(!is_user_alive(id) || get_user_team(id) != 2) 
		return FMRES_HANDLED;
		
	if(get_uc(uc, UC_Buttons) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE))
	{
		new id2, body;
		get_user_aiming(id, id2, body);
		
		if(is_user_connected(id2) && is_user_alive(id2) && get_user_team(id2) == 1)
		{
			if(!g_ChoosenColor[id2])
			{
				new szName[2][32];
				get_user_name(id, szName[0], 31);
				get_user_name(id2, szName[1], 31);
				
				client_cmd(id, "spk fvox/blip");
				client_cmd(id2, "spk fvox/blip");
				showColorMenu(id2);
		
				set_user_rendering(id2, kRenderFxPulseFastWide, 0, 0, 0, kRenderTransAdd, 128);
				client_print_color(0, id, "^x04[CHOWANY]^x03 %s^x01 znalazl^x03 %s^x01 !", szName[0], szName[1]);
				g_ChoosenColor[id2] = true;
			}
			else
			{
				client_print_color(id, id, "^x04[CHOWANY][Chowany]^x03 Ten gracz juz wybral kolor!");
			}
		}
	}
	if(get_uc(uc, UC_Impulse) == 100)
	{
		g_FlashColor[id] = random(sizeof(g_FlashlightColors));
		g_HasFlashOn[id] = !g_HasFlashOn[id];
		
		set_uc(uc, UC_Impulse, 0);
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public PreThink(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	set_pev(id, pev_flTimeStepSound, 999);
	set_pev(id, pev_fuser2, 0.0);
	
	switch(get_user_team(id))
	{
		case 1:{
			if(!usun)
			{
				set_pev(id, pev_maxspeed, 550.0);
				set_pev(id, pev_gravity, 0.36);
			}
			else
			{
				set_pev(id, pev_maxspeed, -1.0);
				set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
			}
		}
		case 2:{
			if(!usun)
			{
				set_pev(id, pev_maxspeed, -1.0);
				set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
			}
			else
			{
				set_pev(id, pev_maxspeed, 550.0);
				set_pev(id, pev_gravity, 0.36);
			}
			
			if(g_HasFlashOn[id])
				Make_FlashLight(id, g_FlashColor[id]);
		}
	}
	return FMRES_IGNORED;
} 

Make_FlashLight(id, color)
{
	new Origin[3];
	get_user_origin(id, Origin, 3);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, .player=id);
	write_byte(TE_DLIGHT);
	write_coord(Origin[0]);
	write_coord(Origin[1]);
	write_coord(Origin[2]);
	write_byte(17);
	write_byte(g_FlashlightColors[color][0]);
	write_byte(g_FlashlightColors[color][1]);
	write_byte(g_FlashlightColors[color][2]);
	write_byte(1);
	write_byte(60);
	message_end();
	
	set_hudmessage(g_FlashlightColors[color][0], g_FlashlightColors[color][1], g_FlashlightColors[color][2], 0.05, 0.65, 0, 0.25, 0.25, 0.5, 0.5, 3);
	show_hudmessage(id, "swiecisz kolorem %s", g_FlashlightColorNames[color]);
}

stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{	
	message_begin( MSG_ONE, gMsgScreenFade,{0,0,0},id)
	write_short(duration)        // Duration of fadeout
	write_short(holdtime)        // Hold time of color
	write_short(fadetype)        // Fade type
	write_byte (red)             // Red
	write_byte (green)           // Green
	write_byte (blue)            // Blue
	write_byte (alpha)   // Alpha
	message_end()
	
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
