#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Ball"
#define VERSION "1.1"
#define AUTHOR "xPaw, Cypis, O'Zone"

#define TASK_COUNTDOWN 6743

new Float:fOrigin[3], bool:bCreateBall, gBall, gTrail, iTime;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1);

	new const szEntity[][] = 
	{
		"worldspawn", "func_wall", "func_door",  "func_door_rotating",
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train",
		"func_illusionary", "func_button", "func_rot_button", "func_rotating"
	}
	
	for(new i = 0; i < sizeof szEntity; i++) register_touch("ball", szEntity[i], "FwdTouchWorld");

	register_touch("ball", "player", "FwdTouchPlayer");
	register_think("ball", "FwdThinkBall");
	
	register_logevent("RoundEnd", 2, "1=Round_End");
	
	register_clcmd("say /ball", "MenuBall");
	register_clcmd("ball", "MenuBall");
	
	register_clcmd("say /pilka", "MenuBall");
	register_clcmd("pilka", "MenuBall");
	
	register_clcmd("say /mecz", "MenuMatch");
	register_clcmd("mecz", "MenuMatch");
	
	register_clcmd("say /reset", "AdminUpdateBall");
	register_clcmd("reset", "AdminUpdateBall");
	
	register_clcmd("jail_pilka", "MenuBall");
	
	WczytajPliki();
}

public plugin_precache()
{
	gTrail = precache_model("sprites/laserbeam.spr");

	precache_model("models/jb_cypis/ball.mdl");
	
	precache_sound("jb_cypis/bounce.wav");
	
	precache_sound("misc/whistle.wav");
	precache_sound("misc/whistle_endgame.wav");
}

public WczytajPliki()
{
	new szMap[32], szFile[128], bool:znalazl_wczyt = false;
	
	get_mapname(szMap, charsmax(szMap));
	formatex(szFile, charsmax(szFile), "addons/amxmodx/data/ball/%s.ini", szMap);
	
	if(file_exists(szFile))
	{
		new dane_tablicy[3][32], tablica[256], txtlen;	
		read_file(szFile, 0, tablica, 255, txtlen);
		
		if(txtlen > 3)
		{
			parse(tablica, dane_tablicy[0], 31, dane_tablicy[1], 31, dane_tablicy[2], 31);

			fOrigin[0] = str_to_float(dane_tablicy[0]);
			fOrigin[1] = str_to_float(dane_tablicy[1]);
			fOrigin[2] = str_to_float(dane_tablicy[2]);
			
			znalazl_wczyt = true;
		}
	}

	if(znalazl_wczyt)
	{
		remove_entity_name("func_pushable");
		CreateBall(fOrigin);
	}
	else
	{
		new ent;
		
		while((ent = find_ent_by_class(ent, "func_pushable")) > 0)
		{
			get_brush_entity_origin(ent, fOrigin);
			remove_entity(ent);

			fOrigin[2] += 15.0;
			
			CreateBall(fOrigin);
			ZapiszPilke(fOrigin);
			
			break;
		}
	}
	
	AddMenuItem("Dodanie Pilki", "jail_pilka", ADMIN_KICK, "Jail");
}

public OnRemoveData()
{	
	if(bCreateBall)
	{
		if(!pev_valid(gBall)) CreateBall(fOrigin);
		else UpdateBall();
	}
}

public OnLastPrisonerShowWish(id)
	if(bCreateBall && pev_valid(gBall)) remove_entity(gBall);

public FwdHamObjectCaps(id)
	if(is_user_alive(id) && pev_valid(gBall) && pev(gBall, pev_iuser1) == id) KickBall(id);

public FwdThinkBall(ent) 
{
	if(!pev_valid(ent)) return PLUGIN_HANDLED;
	
	set_pev(ent, pev_nextthink, halflife_time() + 0.25);
	
	new Float:EntOrigin[3], Float:EntVelocity[3];
	
	pev(ent, pev_origin, EntOrigin); 
	pev(ent, pev_velocity, EntVelocity); 
	
	new owner = pev(ent, pev_iuser1);
	//new solid = pev(ent, pev_solid);
	
	static Float:LastThink;
	
	if(LastThink < get_gametime()) 
	{
		if(floatround(vector_length(EntVelocity)) > 10) 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_KILLBEAM);
			write_short(gBall);
			message_end();
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(gBall);
			write_short(gTrail);
			write_byte(10);
			write_byte(10);
			write_byte(0);
			write_byte(170);
			write_byte(127);
			write_byte(255);
			message_end();
		}
		
		LastThink = get_gametime() + 3.0;
	}

	if(owner) 
	{
		new Float:OwnerOrigin[3];
		
		pev(owner, pev_origin, OwnerOrigin); 
		
		if(!is_user_alive(owner))
		{
			OwnerOrigin[2] += 5.0;
			
			set_pev(ent, pev_solid, SOLID_TRIGGER);
			
			set_pev(ent, pev_iuser1, 0);
			set_pev(ent, pev_origin, OwnerOrigin); 
			set_pev(ent, pev_velocity, Float:{1.0, 1.0, 0.0}); 
			
			return PLUGIN_CONTINUE;
		}
		
		//if(solid != SOLID_NOT) set_pev(ent, pev_solid, SOLID_NOT);
		
		set_pev(ent, pev_frame, pev(ent, pev_frame));
		set_pev(ent, pev_animtime, 0.0);
		set_pev(ent, pev_framerate, 0.0);
		
		new Float:Angles[3], Float:vReturn[3];
		
		pev(owner, pev_v_angle, Angles);
		
		vReturn[0] = (floatcos(Angles[1], degrees) * 55.0) + OwnerOrigin[0];
		vReturn[1] = (floatsin(Angles[1], degrees) * 55.0) + OwnerOrigin[1];
		vReturn[2] = OwnerOrigin[2] - ((pev(owner, pev_flags) & FL_DUCKING) ?10.0: 30.0);
	
		set_pev(ent, pev_origin, vReturn); 
		set_pev(ent, pev_velocity, Float:{1.0, 1.0, 0.0}); 
	} 
	else 
	{
		//if(solid != SOLID_TRIGGER) set_pev(ent, pev_solid, SOLID_TRIGGER);
		
		static Float:VerticalOrigin;
		
		if(!EntVelocity[2]) 
		{
			set_pev(ent, pev_frame, pev(ent, pev_frame));
			set_pev(ent, pev_animtime, 0.0);
			set_pev(ent, pev_framerate, 0.0);

			static iCounts;
			
			if(VerticalOrigin > EntOrigin[2]) 
			{
				iCounts++;
				
				if(iCounts > 10) 
				{
					iCounts = 0;
					UpdateBall();
				}
			}
			else
			{
				iCounts = 0;
				
				if(PointContents(EntOrigin) != CONTENTS_EMPTY) UpdateBall();
			}
			
			VerticalOrigin = EntOrigin[2];
		}
	}
	
	return PLUGIN_CONTINUE;
}

public KickBall(id)
{
	new Float:fOrigin[3];
	
	pev(gBall, pev_origin, fOrigin); 
	
	if(PointContents(fOrigin) != CONTENTS_EMPTY) return PLUGIN_HANDLED;
	
	new Float:fVelocity[3], Float:fAngles[3];
	
	velocity_by_aim(id, 630, fVelocity);
	pev(id, pev_v_angle, fAngles);
	
	fAngles[0] = 0.0;
	
	set_pev(gBall, pev_angles, fAngles);
	
	set_pev(gBall, pev_solid, SOLID_TRIGGER);
	set_pev(gBall, pev_frame, pev(gBall, pev_frame));
	set_pev(gBall, pev_animtime, get_gametime());
	set_pev(gBall, pev_framerate, 1.0);
	
	set_pev(gBall, pev_iuser1, 0);
	set_pev(gBall, pev_velocity, fVelocity); 
	
	jail_set_user_speed(id, 250.0);	
	
	return PLUGIN_CONTINUE;
}

public FwdTouchPlayer(ent, id)
{
	if(!pev(ent, pev_iuser1))
	{
		set_pev(ent, pev_iuser1, id);
		
		set_pev(ent, pev_solid, SOLID_NOT);
		
		jail_set_user_speed(id, 200.0);
	}
	
	return PLUGIN_CONTINUE;
}

public FwdTouchWorld(ent, world)
{
	new Float:fVelocity[3];
	
	pev(ent, pev_velocity, fVelocity); 
	
	if(floatround(vector_length(fVelocity)) > 10)
	{
		fVelocity[0] *= 0.85;
		fVelocity[1] *= 0.85;
		fVelocity[2] *= 0.85;

		if(fVelocity[0] && fVelocity[1])
		{
			new Float:fAngles[3];
			
			vector_to_angle(fVelocity, fAngles);
			
			fAngles[0] = 0.0;
			
			set_pev(ent, pev_angles, fAngles);
		}
		
		set_pev(ent, pev_velocity, fVelocity);
		
		emit_sound(ent, CHAN_ITEM, "jb_cypis/bounce.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	return PLUGIN_CONTINUE;
}

public MenuBall(id) 
{
	if(!(get_user_flags(id) & ADMIN_KICK) && jail_get_prowadzacy() != id) 
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Aby miec dostep do tej komendy musisz byc adminem lub prowadzacym.");
		
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\rWiezienie CS-Reload \rMenu Pilki\w:", "MenuBall_Handle");
	
	menu_additem(menu, "\wStworz \rPilke");
	menu_additem(menu, "\wResetuj \rPilke");
	menu_additem(menu, "\wUsun \rPilke");
	menu_additem(menu, "\wCzas \yMeczu");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuBall_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	switch(item) 
	{
		case 0:    
		{
			if(pev_valid(gBall)) remove_entity_name("ball");
			
			new iOrigin[3];
			
			get_user_origin(id, iOrigin, 3);
			IVecFVec(iOrigin, fOrigin);
			
			fOrigin[2] += 15.0;
			
			CreateBall(fOrigin);
			ZapiszPilke(fOrigin);
			
			MenuBall(id);
		}
		case 1: 
		{
			if(pev_valid(gBall)) UpdateBall();
			
			MenuBall(id);
		}
		case 2: 
		{
			if(!pev_valid(gBall)) return PLUGIN_CONTINUE;
			
			bCreateBall = false;
			
			remove_entity_name("ball");
			
			new szMapa[32], szFile[128];
			
			get_mapname(szMapa, charsmax(szMapa));
			formatex(szFile, charsmax(szFile), "addons/amxmodx/data/ball/%s.ini", szMapa);
			write_file(szFile, "", 0);
			
			MenuBall(id);
		}
		case 3: MenuMatch(id);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

public MenuMatch(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK) && jail_get_prowadzacy() != id) 
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Aby miec dostep do tej komendy musisz byc adminem lub prowadzacym.");
		
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\rWiezienie CS-Reload \yCzas trwania meczu\w:", "MenuMatch_Handle");
	
	menu_additem(menu, "\y30 \wsekund"); 
	menu_additem(menu, "\y60 \wsekund"); 
	menu_additem(menu, "\y90 \wsekund"); 
	menu_additem(menu, "\y30 \wsekund + \rRestart pilki");
	menu_additem(menu, "\y60 \wsekund + \rRestart pilki");
	menu_additem(menu, "\y90 \wsekund + \rRestart pilki");

	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public MenuMatch_Handle(id, menu, item)
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0, 3: iTime = 30;
		case 1, 4: iTime = 60;
		case 2, 5: iTime = 90;
	}
	
	if(item >= 3 && pev_valid(gBall)) UpdateBall();
	
	if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN);
	
	client_cmd(0, "spk misc/whistle.wav");
	
	set_task(1.0, "Countdown", TASK_COUNTDOWN, _, _, "b");
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public Countdown()
{
	set_hudmessage(80, 0, 255, 0.03, 0.76, 2, 0.02, 1.0, 0.01);
	show_hudmessage(0, "Czas do konca meczu: %d!", iTime);
	
	iTime--;
	
	if(!iTime)
	{
		if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN);
		
		client_cmd(0, "spk misc/whistle_endgame.wav");
	}
}

public RoundEnd()
	remove_task(TASK_COUNTDOWN);

public AdminUpdateBall(id)
{
	if(get_user_flags(id) & ADMIN_KICK) UpdateBall();
	
	return PLUGIN_HANDLED;
}

public UpdateBall()
{
	if(!pev_valid(gBall)) return;
	
	set_pev(gBall, pev_velocity, Float:{0.0, 0.0, 0.1}); 
	set_pev(gBall, pev_mins, Float:{-15.0, -15.0, 0.0});
	set_pev(gBall, pev_maxs, Float:{15.0, 15.0, 15.0});

	set_pev(gBall, pev_solid, SOLID_TRIGGER);
	set_pev(gBall, pev_frame, 0.0);
	set_pev(gBall, pev_animtime, 0.0);
	set_pev(gBall, pev_framerate, 0.0);
	set_pev(gBall, pev_iuser1, 0);
	
	set_pev(gBall, pev_origin, fOrigin);
}

public CreateBall(Float:origin[3])
{
	gBall = create_entity("info_target");

	set_pev(gBall, pev_classname, "ball");
	engfunc(EngFunc_SetModel, gBall, "models/jb_cypis/ball.mdl");

	set_pev(gBall, pev_solid, SOLID_TRIGGER);
	set_pev(gBall, pev_movetype, MOVETYPE_BOUNCE);

	set_pev(gBall, pev_mins, Float:{-15.0, -15.0, 0.0});
	set_pev(gBall, pev_maxs, Float:{15.0, 15.0, 15.0});

	set_pev(gBall, pev_sequence, 2);
	set_pev(gBall, pev_framerate, 0.0);
	set_pev(gBall, pev_frame, 0.0);
	
	set_pev(gBall, pev_origin, origin);
	set_pev(gBall, pev_nextthink, get_gametime() + 0.05);
	
	bCreateBall = true;
}

ZapiszPilke(Float:origin[3])
{
	new szTemp[128], szMapa[32], szFile[128];
	
	get_mapname(szMapa, charsmax(szMapa));
	
	formatex(szFile, charsmax(szFile), "addons/amxmodx/data/ball/%s.ini", szMapa);
	formatex(szTemp, charsmax(szTemp), "%f %f %f", origin[0], origin[1], origin[2]);
	
	write_file(szFile, szTemp, 0);
}
