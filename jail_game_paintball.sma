#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <jailbreak>
#include <fun>
#include <engine>
#include <cstrike>

#define PLUGIN "JailBreak: Paintball Day"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define MAX_PAINTBALLS 200

#define TASK_PB_RESET 3213
#define TASK_RELOAD	2136

new Float:fLastShot[33], Float:fNextAttack[33], gPaintBalls[MAX_PAINTBALLS], gStatus[MAX_PAINTBALLS], gCount, bool:bFreezeTime, bool:bPaintBall, id_zabawa;

static const gShotAnim[4] = {0, 3, 9, 5};

native jail_set_teams();
native jail_get_team(id);

public plugin_init()
{
	id_zabawa = jail_register_game("PaintBall Day");
	
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Item_Deploy, "weapon_mp5navy", "ModelGun", 1);

	register_logevent("RoundStart", 2, "0=World triggered", "1=Round_Start");

	register_event("HLTV", "NewRound", "a", "1=0", "2=0");

	register_forward(FM_Touch, "Touch");
	register_forward(FM_PlayerPreThink, "PreThink", 1);
	register_forward(FM_UpdateClientData, "UpdateClientData", 1);
}

public plugin_precache()
{
	precache_sound("misc/pb1.wav");
	precache_sound("misc/pb2.wav");
	precache_sound("misc/pb3.wav");
	precache_sound("misc/pb4.wav");
	precache_sound("misc/pbg.wav");
	
	precache_model("models/v_pbgun1.mdl");
	precache_model("models/p_pbgun1.mdl");
	precache_model("models/w_paintball.mdl");
	precache_model("sprites/paintball.spr");

	precache_generic("sound/reload/paintball.mp3");
}

public plugin_cfg()
{
	for (new i = 1; i <= 200; i++)
	{
		if (i < MAX_PAINTBALLS && engfunc(EngFunc_NumberOfEntities) < global_get(glb_maxEntities) - 5)
		{
			gPaintBalls[i] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

			if (pev_valid(gPaintBalls[i]))
			{
				set_pev(gPaintBalls[i], pev_effects, pev(gPaintBalls[i], pev_effects) | EF_NODRAW);
				
				gCount++;
			}
		}
	}
	if (gCount < 1) set_fail_state("[PAINTBALL] Nie udalo sie zaladowac zabawy!");
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	static szTime[12];
	
	if(day == id_zabawa)
	{
		format_time(szTime, charsmax(szTime), "%M:%S", gTimeRound - 60);
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^nWiezniowie dostaja markery i sie zabijaja.^nZakaz Kampienia.");
		
		szInfo = "PaintBall Day";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);

		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa
	){
		jail_open_cele();
		
		jail_set_teams();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{		
		bPaintBall = true;

		set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== Niech rozpocznie sie PaintBall! ==");

		client_cmd(0, "mp3 play sound/reload/paintball.mp3");

		jail_set_prisoners_fight(true, false, false);

		for(new i = 1; i < 33; i++)
		{
			if(!is_user_alive(i) || !is_user_connected(i) || is_user_hltv(i) || cs_get_user_team(i) != CS_TEAM_T) continue;

			strip_user_weapons(i);
			
			give_item(i, "weapon_knife");
			give_item(i, "weapon_mp5navy");
			
			engclient_cmd(i, "weapon_mp5navy");
		}
	}
}

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
	if(day == id_zabawa) bPaintBall = false;

public ModelGun(weapon)
{
	if(!bPaintBall) return HAM_IGNORED;

	new id = get_pdata_cbase(weapon, 41, 4);
	
	if(get_user_team(id) == 1)
	{
		set_pev(id, pev_viewmodel2, "models/v_pbgun1.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_pbgun1.mdl");
	}
	
	return HAM_IGNORED;
}

public UpdateClientData(id, sw, cd_handle)
{
	if(!bPaintBall) return FMRES_IGNORED;
	
	if(user_has_pbgun(id) && cd_handle)
	{
		set_cd(cd_handle, CD_ID, 1);
		get_cd(cd_handle, CD_flNextAttack, fNextAttack[id]);

		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public PreThink(id)
{
	if(!bPaintBall) return FMRES_IGNORED;
	
	new iPaintBallGun = user_has_pbgun(id);
	
	if (iPaintBallGun)
	{
		new iButtons = pev(id, pev_button);
		
		if (iButtons & IN_ATTACK)
		{
			new iAmmo, iNull = get_user_weapon(id, iAmmo, iNull);
			
			if (iAmmo)
			{
				set_pev(id, pev_button, iButtons & ~IN_ATTACK);
				
				new Float:fGameTime = get_gametime(), Float:fSpeed;
				
				if (iPaintBallGun == 1) fSpeed = 0.08;
				else fSpeed = (iPaintBallGun == 2) ? 0.08 * 2.0 : 0.08 * 3.0;
				
				if (fGameTime - fLastShot[id] > fSpeed  && fNextAttack[id] < 0.0 && !bFreezeTime)
				{
					if (paint_fire(id))
					{
						fLastShot[id] = fGameTime;
						
						set_user_clip(id, iAmmo - 1);
						
						set_pev(id, pev_punchangle, Float:{-0.5, 0.0, 0.0});
						
						message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
						
						write_byte(gShotAnim[iPaintBallGun]);
						write_byte(0);
						
						message_end();

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
	if(!bPaintBall || !is_user_alive(id) || get_user_team(id) != 1) return FMRES_IGNORED;
	
	new i, ent;
	
	while(i++ < gCount - 1 && !ent) if (gStatus[i] == 0) ent = gStatus[i] = gPaintBalls[i];
	
	if(!ent) while(i-- > 1 && !ent) if(gStatus[i] == 2) ent = gStatus[i] = gPaintBalls[i];

	if (pev_valid(ent))
	{
		new Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], iOrigin[3];
		
		set_pev(ent, pev_classname, "paintball_bullet");
		set_pev(ent, pev_owner, id);
		
		engfunc(EngFunc_SetModel, ent, "models/w_paintball.mdl");
		engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});

		set_pev(ent, pev_skin, 0);
		
		get_user_origin(id, iOrigin, 1);
		IVecFVec(iOrigin, fOrigin);
		engfunc(EngFunc_SetOrigin, ent, fOrigin);

		fAngles[0] = random_float(-180.0, 180.0);
		fAngles[1] = random_float(-180.0, 180.0);
		
		set_pev(ent, pev_angles, fAngles);

		pev(id, pev_v_angle, fAngles);
		set_pev(ent, pev_v_angle, fAngles);
		
		pev(id, pev_view_ofs, fAngles);
		set_pev(ent, pev_view_ofs, fAngles);

		set_pev(ent, pev_solid, 2);
		set_pev(ent, pev_movetype, 5);

		velocity_by_aim(id, 1500, fVelocity);
		
		set_pev(ent, pev_velocity, fVelocity);
		set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);

		set_task(15.0 , "paint_reset", ent + TASK_PB_RESET);
	}

	return ent;
}

public Touch(bullet, ent)
{
	if(!bPaintBall || !pev_valid(bullet)) return FMRES_IGNORED;

	new szClassName[20];
	
	pev(bullet, pev_classname, szClassName, charsmax(szClassName));
	
	if(!equali(szClassName, "paintball_bullet")) return FMRES_IGNORED;

	new Float:fOrigin[3], szClassName2[20], owner = pev(bullet, pev_owner), is_ent_alive = is_user_alive(ent);
	
	pev(ent, pev_classname, szClassName2, charsmax(szClassName2));
	pev(bullet, pev_origin, fOrigin);

	if (is_ent_alive)
	{
		if(owner == ent || pev(ent, pev_takedamage) == DAMAGE_NO) return FMRES_IGNORED;
		
		if(get_user_team(owner) != get_user_team(ent)) return FMRES_IGNORED;
		
		if(jail_get_team(owner) == jail_get_team(ent)) return FMRES_IGNORED;

		if(bPaintBall == true) ExecuteHam(Ham_TakeDamage, ent, owner, owner, 200.0, (1<<1));
	}

	if (!equali(szClassName, szClassName2))
	{	
		set_pev(bullet, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(bullet, pev_classname, "paintball_paint");
		set_pev(bullet, pev_solid, 0);
		set_pev(bullet, pev_movetype, 0);
		
		engfunc(EngFunc_SetModel, bullet, "sprites/paintball.spr");

		new i, iFind = 0;
		
		while (i++ < gCount && !iFind) if (gPaintBalls[i] == bullet) iFind = gStatus[i] = 2;
		
		remove_task(bullet + TASK_PB_RESET);

		static szSound[20];
		
		formatex(szSound, charsmax(szSound), is_ent_alive ? "player/pl_pain%d.wav" : "misc/pb%d.wav", is_ent_alive ? random_num(4,7) : random_num(1,4));
		
		emit_sound(bullet, CHAN_AUTO, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

		new bool:bValidSurface = (is_ent_alive || containi(szClassName2, "door") != -1) ? false : true;
		
		if (pev(ent, pev_health) && !is_ent_alive && pev(ent, pev_takedamage))
		{
			ExecuteHam(Ham_TakeDamage, ent, owner, owner, float(pev(ent, pev_health)), 0);
			
			bValidSurface = false;
		}
		
		if (bValidSurface)
		{
			paint_splat(bullet);
			
			set_task(3.0, "paint_reset", bullet + TASK_PB_RESET);
		}
		else paint_reset(bullet + TASK_PB_RESET);

		return FMRES_HANDLED; 
	}

	return FMRES_IGNORED;
}

public paint_splat(ent)
{
	new Float:fOrigin[3], Float:fNoOrigin[3], Float:fViewOfs[3], Float:fAngles[3], Float:fNormal[3], Float:fAiming[3];
	
	pev(ent, pev_origin, fOrigin);
	pev(ent, pev_view_ofs, fViewOfs);
	pev(ent, pev_v_angle, fAngles);

	fNoOrigin[0] = fOrigin[0] + fViewOfs[0];
	fNoOrigin[1] = fOrigin[1] + fViewOfs[1];
	fNoOrigin[2] = fOrigin[2] + fViewOfs[2];
	fAiming[0] = fNoOrigin[0] + floatcos(fAngles[1], degrees) * 1000.0;
	fAiming[1] = fNoOrigin[1] + floatsin(fAngles[1], degrees) * 1000.0;
	fAiming[2] = fNoOrigin[2] + floatsin(-fAngles[0], degrees) * 1000.0;

	engfunc(EngFunc_TraceLine, fNoOrigin, fAiming, 0, ent, 0);
	get_tr2(0, TR_vecPlaneNormal, fNormal);

	vector_to_angle(fNormal, fAngles);
	
	fAngles[1] += 180.0;
	
	if (fAngles[1] >= 360.0) fAngles[1] -= 360.0;
	
	set_pev(ent, pev_angles, fAngles);
	set_pev(ent, pev_v_angle, fAngles);

	fOrigin[0] += (fNormal[0] * random_float(0.3, 2.7));
	fOrigin[1] += (fNormal[1] * random_float(0.3, 2.7));
	fOrigin[2] += (fNormal[2] * random_float(0.3, 2.7));
	
	engfunc(EngFunc_SetOrigin, ent, fOrigin);
	
	set_pev(ent, pev_frame, float(random_num((pev(ent, pev_skin) * 18), (pev(ent, pev_skin) * 18) + 17)));
}

public paint_reset(ent)
{
	remove_task(ent);
	
	ent -= TASK_PB_RESET;
	
	new i, iFind = 1;
	
	while(i++ <= gCount && iFind) if(gPaintBalls[i] == ent) iFind = gStatus[i] = 0;

	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
	
	engfunc(EngFunc_SetSize, ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	
	set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
	
	engfunc(EngFunc_SetOrigin, ent, Float:{-2000.0, -2000.0, -2000.0});
}

public RoundStart()
{
	for(new i = 1; i <= gCount; i++) if(gStatus[i] != 0) paint_reset(gPaintBalls[i] + TASK_PB_RESET);
	
	if(bFreezeTime) bFreezeTime = false;
}

public NewRound()
	bFreezeTime = true;

stock user_has_pbgun(id)
{
	if(is_user_alive(id))
	{
		new szModel[25];
		
		pev(id, pev_viewmodel2, szModel, charsmax(szModel));
		
		if(containi(szModel, "models/v_pbgun") != -1) return 1;
	}
	
	return 0;
}

stock set_user_clip(id, iAmmo)
{
	new szWeapon[32], iWeaponID = -1, iWeapon = get_user_weapon(id, _, _);
	
	get_weaponname(iWeapon, szWeapon, charsmax(szWeapon));
	
	while((iWeaponID = engfunc(EngFunc_FindEntityByString, iWeaponID, "classname", szWeapon)) != 0)
	{
		if (pev(iWeaponID, pev_owner) == id) 
		{
			set_pdata_int(iWeaponID, 51, iAmmo, 4);
			
			return iWeaponID;
		}
	}
	
	return 0;
}