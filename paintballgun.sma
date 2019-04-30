#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Paintball Gun"
#define VERSION "1.1"
#define AUTHOR "WhooKid & O'Zone"

#define MAX_PAINTBALLS	200
#define TASK_PB_RESET	1000
#define TASK_RELOAD	2000

new g_paintballs[MAX_PAINTBALLS], g_pbstatus[MAX_PAINTBALLS], g_pbcount, Float:lastshot[33], Float:nextattack[33], freezetime;
new pbgun, pbgunvip, pbusp, pbglock, pbtgun, pbctgun, color, shots, veloc, speed, blife, sound, bglow, damge, friendlyfire, beamspr;

static const g_shot_anim[4] = {0, 3, 9, 5};
static const g_pbgun_models[11][] = {"models/v_pbgun.mdl", "models/v_pbgun1.mdl", "models/v_pbgun2.mdl", "models/v_pbgun3.mdl", "models/v_pbgun4.mdl", "models/v_pbgun5.mdl", "models/v_pbgun6.mdl", "models/v_pbgun7.mdl", "models/v_pbgun8.mdl", "models/v_pbgun9.mdl", "models/v_pbgun10.mdl"};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	pbgun		=	register_cvar("amx_pbgun", "1");
	pbgunvip	=	register_cvar("amx_pbgunvip", "1");
	pbusp		=	register_cvar("amx_pbusp", "1");
	pbglock		=	register_cvar("amx_pbglock", "1");
	pbtgun		=	register_cvar("pbgun_tgun", "3");
	pbctgun 	= 	register_cvar("pbgun_ctgun", "7");

	if(get_pcvar_num(pbgun) || get_pcvar_num(pbusp) || get_pcvar_num(pbglock))
	{
		if(get_pcvar_num(pbgun))
		RegisterHam(Ham_Item_Deploy, "weapon_mp5navy", "mp5_model" , 1);
		if(get_pcvar_num(pbgunvip))
			RegisterHam(Ham_Item_Deploy, "weapon_p90", "p90_model" , 1);
		if(get_pcvar_num(pbusp))
			RegisterHam(Ham_Item_Deploy, "weapon_usp", "usp_model" , 1);
		if(get_pcvar_num(pbglock))
			RegisterHam(Ham_Item_Deploy, "weapon_glock18", "glock_model" , 1);
			
		register_logevent("ev_roundstart", 2, "0=World triggered", "1=Round_Start");
		if(get_cvar_num("mp_freezetime") > 0)
			register_event("HLTV", "ev_freezetime", "a", "1=0", "2=0");

		register_forward(FM_Touch, "fw_touch");
		register_forward(FM_SetModel, "fw_setmodel");
		register_forward(FM_SetModel, "fw_setmodelvip");
		register_forward(FM_PlayerPreThink, "fw_playerprethink", 1);
		register_forward(FM_UpdateClientData, "fw_updateclientdata", 1);

		color = register_cvar("pbgun_color", "2");
		shots = register_cvar("pbgun_shots", "100");
		veloc = register_cvar("pbgun_velocity", "2000");
		speed = register_cvar("pbgun_speed", "0.08");
		blife = register_cvar("pbgun_life", "15");
		sound = register_cvar("pbgun_sound", "1");
		bglow = register_cvar("pbgun_glow", "a");
		damge = register_cvar("pbgun_damage", "100");
		friendlyfire = get_cvar_pointer("mp_friendlyfire");

		new a, max_ents_allow = global_get(glb_maxEntities) - 5;
		for (a = 1; a <= get_pcvar_num(shots); a++)
		{
			if (a < MAX_PAINTBALLS)
			{
				if (engfunc(EngFunc_NumberOfEntities) < max_ents_allow)
				{
					g_paintballs[a] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
					if (pev_valid(g_paintballs[a]))
					{
						set_pev(g_paintballs[a], pev_effects, pev(g_paintballs[a], pev_effects) | EF_NODRAW);
						g_pbcount++;
					}
				}
			}
		}
		if (g_pbcount < 1)
			set_fail_state("[AMXX] Failed to load Paintball Gun (unable to create ents)");

		server_print("*** %s v%s by %s Enabled ***", PLUGIN, VERSION, AUTHOR);
	}
}

public plugin_precache()
{	
	pbgun		=	register_cvar("amx_pbgun", "1");
	pbgunvip	=	register_cvar("amx_pbgunvip", "1");
	pbusp		=	register_cvar("amx_pbusp", "1");
	pbglock		=	register_cvar("amx_pbglock", "1");
	pbtgun		=	register_cvar("pbgun_tgun", "3");
	pbctgun 	= 	register_cvar("pbgun_ctgun", "7");
	
	if (get_pcvar_num(pbgun)) 
	{
		precache_model(g_pbgun_models[get_pcvar_num(pbtgun)]);
		precache_model(g_pbgun_models[get_pcvar_num(pbctgun)]);
		precache_model(get_pcvar_num(pbctgun) ? "models/p_pbgun1.mdl" : "models/p_pbgun.mdl");
		precache_model("models/w_pbgun.mdl");
	}
	
	if (get_pcvar_num(pbgunvip))
		precache_model("models/v_pbgun2.mdl");
	
	if (get_pcvar_num(pbusp)) 
	{
		precache_model("models/v_pbusp.mdl");
		precache_model("models/p_pbusp.mdl");
	}
	
	if (get_pcvar_num(pbglock)) 
	{
		precache_model("models/v_pbglock.mdl");
		precache_model("models/p_pbglock.mdl");
	}
	
	if (get_pcvar_num(pbgun) || get_pcvar_num(pbusp) || get_pcvar_num(pbglock)) 
	{
		precache_sound("misc/pb1.wav");
		precache_sound("misc/pb2.wav");
		precache_sound("misc/pb3.wav");
		precache_sound("misc/pb4.wav");
		precache_sound("misc/pbg.wav");
		precache_model("models/w_paintball.mdl");
		precache_model("sprites/paintball.spr");
	}
	
	beamspr = precache_model("sprites/laserbeam.spr");
}

public mp5_model(weapon) 
{
    new id = get_pdata_cbase(weapon, 41, 4); 
    if(is_user_alive(id) && get_pcvar_num(pbgun))   
    {
		set_pev(id, pev_viewmodel2, (get_user_team(id) == 1) ? g_pbgun_models[get_pcvar_num(pbtgun)] : g_pbgun_models[get_pcvar_num(pbctgun)]);
		set_pev(id, pev_weaponmodel2, get_pcvar_num(pbctgun) ? "models/p_pbgun1.mdl" : "models/p_pbgun.mdl");
	}
}

public p90_model(weapon) 
{
    new id = get_pdata_cbase(weapon, 41, 4); 
    if(is_user_alive(id) && get_pcvar_num(pbgunvip))   
    {
		set_pev(id, pev_viewmodel2, "models/v_pbgun2.mdl");
		set_pev(id, pev_weaponmodel2, get_pcvar_num(pbctgun) ? "models/p_pbgun1.mdl" : "models/p_pbgun.mdl");
	}
}

public usp_model(weapon) 
{
    new id = get_pdata_cbase(weapon, 41, 4); 
    if(is_user_alive(id) && get_pcvar_num(pbusp))   
    {
		set_pev(id, pev_viewmodel2, "models/v_pbusp.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_pbusp.mdl");
	}
}

public glock_model(weapon) 
{
    new id = get_pdata_cbase(weapon, 41, 4); 
    if(is_user_alive(id) && get_pcvar_num(pbglock))   
    {
		set_pev(id, pev_viewmodel2, "models/v_pbglock.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_pbglock.mdl");
	}
}

public fw_setmodel(ent, model[]) 
{
    if (equali(model, "models/w_mp5.mdl")) 
	{
        if (get_pcvar_num(pbgun))
		{
			engfunc(EngFunc_SetModel, ent, "models/w_pbgun.mdl");
			return FMRES_SUPERCEDE;
		}
	}
    return FMRES_IGNORED;
}
public fw_setmodelvip(ent, model[]) 
{
	if (equali(model, "models/w_p90.mdl")) 
	{
		if (get_pcvar_num(pbgunvip))
		{
			engfunc(EngFunc_SetModel, ent, "models/w_pbgun.mdl");
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public fw_updateclientdata(id, sw, cd_handle)
{
	if (user_has_pbgun(id) && cd_handle)
	{
		set_cd(cd_handle, CD_ID, 1);
		get_cd(cd_handle, CD_flNextAttack, nextattack[id]);
		//set_cd(cd_handle, CD_flNextAttack, 10.0);
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public fw_playerprethink(id)
{
	new my_pbgun = user_has_pbgun(id);
	if (my_pbgun)
	{
		new buttons = pev(id, pev_button);
		if (buttons & IN_ATTACK)
		{
			new ammo, null = get_user_weapon(id, ammo, null);
			if (ammo)
			{
				set_pev(id, pev_button, buttons & ~IN_ATTACK);
				new Float:gametime = get_gametime(), Float:g_speed;
				if (my_pbgun == 1)
					g_speed = get_pcvar_float(speed);
				else
					g_speed = (my_pbgun == 2) ? get_pcvar_float(speed) * 2.0 : get_pcvar_float(speed) * 3.0;
					
				if (gametime-lastshot[id] > g_speed  && nextattack[id] < 0.0 && !freezetime)
				{
					if (paint_fire(id))
					{
						lastshot[id] = gametime;
						set_user_clip(id, ammo - 1);
						set_pev(id, pev_punchangle, Float:{-0.5, 0.0, 0.0});
						message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
						write_byte(g_shot_anim[my_pbgun]);
						write_byte(0);
						message_end();
						if (get_pcvar_num(sound))
							emit_sound(id, CHAN_AUTO, "misc/pbg.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
					}
				}
			}
		}
	}
	return FMRES_IGNORED;
}

public paint_fire(id)
{
	new a, ent;
	while (a++ < g_pbcount - 1 && !ent)
		if (g_pbstatus[a] == 0)
			ent = g_pbstatus[a] = g_paintballs[a];
	if (!ent)
		while (a-- > 1 && !ent)
			if (g_pbstatus[a] == 2)
				ent = g_pbstatus[a] = g_paintballs[a];

	if (pev_valid(ent) && is_user_alive(id))
	{
		new Float:vangles[3], Float:nvelocity[3], Float:voriginf[3], vorigin[3], clr;
		set_pev(ent, pev_classname, "pbBullet");
		set_pev(ent, pev_owner, id);
		engfunc(EngFunc_SetModel, ent, "models/w_paintball.mdl");
		engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});

		switch (get_pcvar_num(color))
		{
			case 2: clr = (get_user_team(id) == 1) ? 0 : 1;
			case 3: clr = (get_user_team(id) == 1) ? 4 : 3;
			case 4: clr = (get_user_team(id) == 1) ? 2 : 5;
			default: clr = random_num(0, 6);
		}
		
		set_pev(ent, pev_skin, clr);
		
		get_user_origin(id, vorigin, 1);
		IVecFVec(vorigin, voriginf);
		engfunc(EngFunc_SetOrigin, ent, voriginf);

		vangles[0] = random_float(-180.0, 180.0);
		vangles[1] = random_float(-180.0, 180.0);
		set_pev(ent, pev_angles, vangles);

		pev(id, pev_v_angle, vangles);
		set_pev(ent, pev_v_angle, vangles);
		pev(id, pev_view_ofs, vangles);
		set_pev(ent, pev_view_ofs, vangles);

		set_pev(ent, pev_solid, 2);
		set_pev(ent, pev_movetype, 5);

		velocity_by_aim(id, get_pcvar_num(veloc), nvelocity);
		set_pev(ent, pev_velocity, nvelocity);
		set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);

		set_task(0.1, "paint_glow", ent);
		set_task(15.0 , "paint_reset", ent+TASK_PB_RESET);
	}

	return ent;
}

public fw_touch(bullet, ent)
{
	new class[20];
	pev(bullet, pev_classname, class, 19);
	if (!equali(class, "pbBullet"))
		return FMRES_IGNORED;

	new Float:origin[3], class2[20], owner = pev(bullet, pev_owner), is_ent_alive = is_user_alive(ent);
	pev(ent, pev_classname, class2, 19);
	pev(bullet, pev_origin, origin);

	if (is_ent_alive)
	{
		if (owner == ent || pev(ent, pev_takedamage) == DAMAGE_NO)
			return FMRES_IGNORED;
		if (get_user_team(owner) == get_user_team(ent))
			if (!get_pcvar_num(friendlyfire))
				return FMRES_IGNORED;

		ExecuteHam(Ham_TakeDamage, ent, owner, owner, float(get_pcvar_num(damge)), 4098);
	}

	if (!equali(class, class2))
	{	
		set_pev(bullet, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(bullet, pev_classname, "pbPaint");
		set_pev(bullet, pev_solid, 0);
		set_pev(bullet, pev_movetype, 0);
		engfunc(EngFunc_SetModel, bullet, "sprites/paintball.spr");

		new a, findpb = 0;
		while (a++ < g_pbcount && !findpb)
			if (g_paintballs[a] == bullet)
				findpb = g_pbstatus[a] = 2;

		remove_task(bullet);
		remove_task(bullet+TASK_PB_RESET);

		if (get_pcvar_num(sound))
		{
			static wav[20];
			formatex(wav, 20, is_ent_alive ? "player/pl_pain%d.wav" : "misc/pb%d.wav", is_ent_alive ? random_num(4,7) : random_num(1,4));
			emit_sound(bullet, CHAN_AUTO, wav, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}

		new bool:valid_surface = (is_ent_alive || containi(class2, "door") != -1) ? false : true;
		if (pev(ent, pev_health) && !is_ent_alive && pev(ent,pev_takedamage))
		{
			ExecuteHam(Ham_TakeDamage, ent, owner, owner, float(pev(ent, pev_health)), 0);
			valid_surface = false;
		}
		
		if (valid_surface)
		{
			paint_splat(bullet);
			set_task(float(get_pcvar_num(blife)), "paint_reset", bullet+TASK_PB_RESET);
		}
		else
			paint_reset(bullet+TASK_PB_RESET);

		return FMRES_HANDLED; 
	}

	return FMRES_IGNORED;
}

public paint_splat(ent)
{
	new Float:origin[3], Float:norigin[3], Float:viewofs[3], Float:angles[3], Float:normal[3], Float:aiming[3];
	pev(ent, pev_origin, origin);
	pev(ent, pev_view_ofs, viewofs);
	pev(ent, pev_v_angle, angles);

	norigin[0] = origin[0] + viewofs[0];
	norigin[1] = origin[1] + viewofs[1];
	norigin[2] = origin[2] + viewofs[2];
	aiming[0] = norigin[0] + floatcos(angles[1], degrees) * 1000.0;
	aiming[1] = norigin[1] + floatsin(angles[1], degrees) * 1000.0;
	aiming[2] = norigin[2] + floatsin(-angles[0], degrees) * 1000.0;

	engfunc(EngFunc_TraceLine, norigin, aiming, 0, ent, 0);
	get_tr2(0, TR_vecPlaneNormal, normal);

	vector_to_angle(normal, angles);
	angles[1] += 180.0;
	if (angles[1] >= 360.0) angles[1] -= 360.0;
	set_pev(ent, pev_angles, angles);
	set_pev(ent, pev_v_angle, angles);

	origin[0] += (normal[0] * random_float(0.3, 2.7));
	origin[1] += (normal[1] * random_float(0.3, 2.7));
	origin[2] += (normal[2] * random_float(0.3, 2.7));
	engfunc(EngFunc_SetOrigin, ent, origin);
	set_pev(ent, pev_frame, float(random_num( (pev(ent, pev_skin) * 18), (pev(ent, pev_skin) * 18) + 17 ) ));
	if (pev(ent, pev_renderfx) != kRenderFxNone)
		set_rendering(ent);
}

public paint_glow(ent)
{
	if (pev_valid(ent))
	{
		static pbglow[5], clr[3];
		get_pcvar_string(bglow, pbglow, 4);
		
		switch (get_pcvar_num(color))
		{
			case 2: clr = (get_user_team(pev(ent, pev_owner))==1) ? {255, 0, 0} : {0, 0, 255};
			default: clr = {255, 255, 255};
		}
		
		if (read_flags(pbglow) & (1 << 0))
			set_rendering(ent, kRenderFxGlowShell, clr[0], clr[1], clr[2], kRenderNormal, 255);
			
		if (read_flags(pbglow) & (1 << 1))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(ent);
			write_short(beamspr);
			write_byte(4);
			write_byte(2);
			write_byte(clr[0]);
			write_byte(clr[1]);
			write_byte(clr[2]);
			write_byte(255);
			message_end();
		}
	}
}

public paint_reset(ent)
{
	remove_task(ent);
	ent -= TASK_PB_RESET;
	new a, findpb = 1;
	while (a++ <= g_pbcount && findpb)
	{
		if (g_paintballs[a] == ent)
			findpb = g_pbstatus[a] = 0;
	}

	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
	engfunc(EngFunc_SetSize, ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
	engfunc(EngFunc_SetOrigin, ent, Float:{-2000.0, -2000.0, -2000.0});
	if (pev(ent, pev_renderfx) != kRenderFxNone)
		set_rendering(ent);
}

public ev_roundstart()
{
	for (new a = 1; a <= g_pbcount; a++)
	{
		if (g_pbstatus[a] != 0)
			paint_reset(g_paintballs[a]+TASK_PB_RESET);
	}
	if (freezetime)
		freezetime = 0;
}

public ev_freezetime()
	freezetime = 1;

stock user_has_pbgun(id)
{
	if (is_user_alive(id))
	{
		new model[25];
		pev(id, pev_viewmodel2, model, 24);
		if (containi(model, "models/v_pbgun") != -1)
			return 1;
		else if (equali(model, "models/v_pbusp.mdl"))
			return 2;
		else if (equali(model, "models/v_pbglock.mdl"))
			return 3;
	}
	return 0;
}

stock set_user_clip(id, ammo)
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _);
	get_weaponname(weapon, weaponname, 31);
	while ((weaponid = engfunc(EngFunc_FindEntityByString, weaponid, "classname", weaponname)) != 0)
		if (pev(weaponid, pev_owner) == id) {
			set_pdata_int(weaponid, 51, ammo, 4);
			return weaponid;
		}
	return 0;
}

stock set_rendering(index, fx=kRenderFxNone, r=0, g=0, b=0, render=kRenderNormal, amount=16)
{
	set_pev(index, pev_renderfx, fx);
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	set_pev(index, pev_rendercolor, RenderColor);
	set_pev(index, pev_rendermode, render);
	set_pev(index, pev_renderamt, float(amount));
}