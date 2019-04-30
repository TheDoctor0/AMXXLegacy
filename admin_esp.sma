#include <amxmodx>
#include <engine>

new g_iLaser;
new bool:g_bAdmin[33];
new bool:g_IsAlive[33];

public plugin_precache()
	g_iLaser = precache_model("sprites/laserbeam.spr");

public plugin_end()
{
	new pl[32], pnum; get_players(pl, pnum);
	for(new i; i < pnum; i++)
		remove_task(pl[i]);
}	
	
public plugin_init()
{
#define VERSION "1.0"
	register_plugin("Lite Admin ESP", VERSION, "Safety1st");
	register_cvar("lite_aesp", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	register_event("DeathMsg", "eDeathMsg", "a", "1>0");
	register_event("ResetHUD", "eResetHud", "be");
	register_event("TextMsg", "eSpecMode", "b", "2&#Spec_M");
}

public client_putinserver(id)
{
	g_bAdmin[id]  = (get_user_flags(id) & ADMIN_KICK) ? true : false;
	g_IsAlive[id] = false;
}

public client_disconnect(id)
{
	if(g_bAdmin[id])
		remove_task(id);
}

public eDeathMsg()
	g_IsAlive[read_data(2)] = false;

public eResetHud(id)
	g_IsAlive[id] = true;

public eSpecMode(id)
{
	if(!g_bAdmin[id]) return;

	if(entity_get_int(id, EV_INT_iuser1) == 4)
		set_task(0.3, "EspTimer", id, .flags="b");
	else
		remove_task(id);
}

public EspTimer(id)
{
	switch(g_IsAlive[id])
	{
		case false:
		{
			static iTarget; iTarget = entity_get_int(id, EV_INT_iuser2);

			if(iTarget && is_user_alive(iTarget) && is_valid_ent(iTarget))
				SendQuadro(id, iTarget);
		}
		case true: remove_task(id);
		
	}	
}

SendQuadro(id, iTarget)
{
	static pl[32], pnum, my_team;
	static Float:my_origin[3], Float:target_origin[3], Float:v_middle[3], Float:v_hitpoint[3];
	static Float:distance, Float:distance_to_hitpoint, Float:distance_target_hitpoint, Float:scaled_bone_len;
	static Float:v_bone_start[3], Float:v_bone_end[3], Float:offset_vector[3], Float:eye_level[3];

	entity_get_vector(iTarget, EV_VEC_origin, my_origin);
	my_team = get_user_team(iTarget);
	get_players(pl, pnum, "ah");
	for(new i; i < pnum; i++)
	{
		if(pl[i] == iTarget) continue;
		if(my_team == get_user_team(pl[i])) continue;

		entity_get_vector(pl[i], EV_VEC_origin, target_origin);
		distance = vector_distance(my_origin, target_origin);

		trace_line(-1, my_origin, target_origin, v_hitpoint);
		
		subVec(target_origin, my_origin, v_middle);
		normalize(v_middle, offset_vector, (distance_to_hitpoint = vector_distance(my_origin, v_hitpoint)) - 10.0);

		copyVec(my_origin, eye_level);
		eye_level[2] += 17.5;
		addVec(offset_vector, eye_level);

		copyVec(offset_vector, v_bone_start);
		copyVec(offset_vector, v_bone_end);
		v_bone_end[2] -= (scaled_bone_len = distance_to_hitpoint / distance * 50.0);

		if(distance_to_hitpoint == distance)
			continue;
		
		distance_target_hitpoint = (distance - distance_to_hitpoint) / 12;
		MakeQuadrate(id, v_bone_start, v_bone_end, floatround(scaled_bone_len * 3.0), (distance_target_hitpoint < 170.0) ? (255 - floatround(distance_target_hitpoint)) : 85)
	}
}

stock normalize(Float:Vec[3], Float:Ret[3], Float:multiplier)
{
	static Float:len; len = vector_distance(Vec, Float:{ 0.0, 0.0, 0.0 });
	copyVec(Vec, Ret);

	Ret[0] /= len;
	Ret[1] /= len;
	Ret[2] /= len;
	Ret[0] *= multiplier;
	Ret[1] *= multiplier;
	Ret[2] *= multiplier;
}

stock copyVec(Float:Vec[3], Float:Ret[3])
{
	Ret[0] = Vec[0];
	Ret[1] = Vec[1];
	Ret[2] = Vec[2];
}

stock subVec(Float:Vec1[3], Float:Vec2[3], Float:Ret[3])
{
	Ret[0] = Vec1[0] - Vec2[0];
	Ret[1] = Vec1[1] - Vec2[1];
	Ret[2] = Vec1[2] - Vec2[2];
}

stock addVec(Float:Vec1[3], Float:Vec2[3])
{
	Vec1[0] += Vec2[0];
	Vec1[1] += Vec2[1];
	Vec1[2] += Vec2[2];
}

MakeQuadrate(id, Float:Vec1[3], Float:Vec2[3], width, brightness)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id);
	write_byte(0);
	write_coord(floatround(Vec1[0]));
	write_coord(floatround(Vec1[1]));
	write_coord(floatround(Vec1[2]));
	write_coord(floatround(Vec2[0]));
	write_coord(floatround(Vec2[1]));
	write_coord(floatround(Vec2[2]));
	write_short(g_iLaser);
	write_byte(3);
	write_byte(0);
	write_byte(3);
	write_byte(width);
	write_byte(0);
	write_byte(0);
	write_byte(255);
	write_byte(0);
	write_byte(brightness);
	write_byte(0);
	message_end();
}