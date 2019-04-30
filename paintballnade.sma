#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Paintball Nade"
#define VERSION "1.1"
#define AUTHOR "WhooKid & O'Zone"

new pbnade, radius, MaxPlayers, blood1, blood2;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	pbnade = register_cvar("amx_pbnade", "1");

	if (get_pcvar_num(pbnade))
	{
		RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "grenade_deploy", 1);
		register_forward(FM_SetModel, "fw_setmodel");
		register_forward(FM_Think, "fw_think");

		radius = register_cvar("pbnade_radius", "150");
		
		MaxPlayers = get_maxplayers();
	}
}

public plugin_precache()
{
	pbnade = register_cvar("amx_pbnade", "1");
	if (get_pcvar_num(pbnade))
	{
		precache_model("models/p_pbnade.mdl");
		precache_model("models/v_pbnade.mdl");
		precache_model("models/w_pbnade.mdl");
		blood1 = precache_model("sprites/blood.spr");
		blood2 = precache_model("sprites/bloodspray.spr");
	}
}

public grenade_deploy(weapon)
{
	new id = get_pdata_cbase(weapon, 41, 4);
	
	if(is_user_alive(id))
	{
		set_pev(id, pev_viewmodel2, "models/v_pbnade.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_pbnade.mdl");
	}
}

public fw_setmodel(ent, model[]) 
{
	if (equali(model, "models/w_hegrenade.mdl")) 
	{
		engfunc(EngFunc_SetModel, ent, "models/w_pbnade.mdl");
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_think(ent)
{
	new model[25];
	pev(ent, pev_model, model, 24);

	if (!equali(model, "models/w_pbnade.mdl"))
		return FMRES_IGNORED;

	set_task(1.6, "act_explode", ent);

	return FMRES_SUPERCEDE;
}

public act_explode(ent)
{
	if (!pev_valid(ent))
		return;

	new origin[3], Float:forigin[3], colors[4], owner = pev(ent, pev_owner), user_team = get_user_team(owner);

	colors = (user_team == 1) ? { 255, 0, 247, 70} : { 0, 255, 208, 30};
	pev(ent, pev_origin, forigin);
	FVecIVec(forigin, origin);

	new id, Float:distance = float(get_pcvar_num(radius)), Float:porigin[3];

	while (id++ < MaxPlayers)
		if (is_user_alive(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_LAVASPLASH);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2] - 50);
			message_end();

			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_BLOODSPRITE);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2] + 20);
			write_short(blood2);
			write_short(blood1);
			write_byte(colors[2]);
			write_byte(30);
			message_end();

			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2]);
			write_byte(40);
			write_byte(colors[0]);
			write_byte(20);
			write_byte(colors[1]);
			write_byte(8);
			write_byte(60);
			message_end();

			if (user_team != get_user_team(id) || owner == id)
			{
				pev(id, pev_origin, porigin);
				if (get_distance_f(forigin, porigin) <= distance)
					if (fm_is_visible(ent, id))
						ExecuteHam(Ham_TakeDamage, id, ent, owner, (id != owner) ? 100.0 : 300.0, 0);
			}
		}

	emit_sound(ent, CHAN_AUTO, "weapons/sg_explode.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

	engfunc(EngFunc_RemoveEntity, ent);
}

stock bool:fm_is_visible(ent, target)
{
	if (pev_valid(ent) && pev_valid(target))
	{
		new Float:start[3], Float:view_ofs[3], Float:point[3];
		pev(ent, pev_origin, start);
		pev(ent, pev_view_ofs, view_ofs);
		pev(target, pev_origin, point);
		start[0] += view_ofs[0];
		start[1] += view_ofs[1];
		start[2] += view_ofs[2];
		engfunc(EngFunc_TraceLine, start, point, 1, ent, 0);
		new Float:fraction;
		get_tr2(0, TR_flFraction, fraction);
		if (fraction == 1.0)
			return true;
	}
	return false;
}