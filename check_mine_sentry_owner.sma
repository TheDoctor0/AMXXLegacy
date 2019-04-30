#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <dhudmessage>

#define PLUGIN "Check Mine/Sentry Owner"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define CHECK_TASKID 987
#define CHECK_HUDID 789

new sentry_owner_name[33][33];
new mine_owner_name[33][33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn , "player", "Spawn", 1);
}	

public Spawn(id) {
	set_task(0.3, "Check_Mine", id+CHECK_TASKID, "", 0, "b");
	set_task(0.3, "Check_Sentry", id+CHECK_TASKID, "", 0, "b");
}
	
public client_disconnect(id)
	remove_task(id+CHECK_TASKID)
	
public Check_Mine(id){
	id -= CHECK_TASKID;
	
	if(is_user_alive(id)){
		new entity = Get_Mine_By_Aim(id);
		if (entity && is_valid_ent(entity)){
			new owner = entity_get_edict(entity, EV_ENT_owner);
			if(owner != id){
				get_user_name(owner, mine_owner_name[id], charsmax(mine_owner_name));
				set_task(0.3, "Show_Mine_HUD", id+CHECK_HUDID);
			}
		}
	}
}

public Check_Sentry(id){
	id -= CHECK_TASKID;
	
	if(is_user_alive(id)){
		new entity = Get_Sentry_By_Aim(id);
		if (entity && is_valid_ent(entity)){
			new owner = entity_get_edict(entity, EV_ENT_owner);
			if(owner != id){
				get_user_name(owner, sentry_owner_name[id], charsmax(sentry_owner_name));
				set_task(0.3, "Show_Sentry_HUD", id+CHECK_HUDID);
			}
		}
	}
}

public Show_Mine_HUD(id){
	id -= CHECK_HUDID;
	remove_task(id+CHECK_HUDID);
	set_dhudmessage(255, 0, 0, 0.35, 0.25, 0, 0.0, 0.6, 0.1, 0.1);
	show_dhudmessage(id, "Wlasciciel Miny: %s", mine_owner_name[id]);
}

public Show_Sentry_HUD(id){
	id -= CHECK_HUDID;
	remove_task(id+CHECK_HUDID);
	set_dhudmessage(255, 0, 0, 0.35, 0.25, 0, 0.0, 0.6, 0.1, 0.1);
	show_dhudmessage(id, "Wlasciciel Dzialka: %s", sentry_owner_name[id]);
}

stock Get_Mine_By_Aim(id)
{
   new entList[1];
   new Float:fOrigin[3],Float:vAngles[3],Float:vecReturn[3];
   entity_get_vector(id, EV_VEC_origin, fOrigin);
   fOrigin[2] += 10;
   entity_get_vector(id, EV_VEC_v_angle, vAngles);

   for(new Float:i=0.0;i<=1000.0;i+=20.0)
   {
		Vector_By_Angle(fOrigin, vAngles, i, 1, vecReturn);
		find_sphere_class(0, "mine", 5.0, entList, 1, vecReturn);
   }
   return entList[0]
}

stock Get_Sentry_By_Aim(id)
{
   new entList[1];
   new Float:fOrigin[3],Float:vAngles[3],Float:vecReturn[3];
   entity_get_vector(id, EV_VEC_origin, fOrigin);
   fOrigin[2] += 10;
   entity_get_vector(id, EV_VEC_v_angle, vAngles);

   for(new Float:i=0.0;i<=1000.0;i+=20.0)
   {
      Vector_By_Angle(fOrigin, vAngles, i, 1, vecReturn);
      find_sphere_class(0, "sentry_shot", 5.0, entList, 1, vecReturn);
   }
   return entList[0]
}

stock Vector_By_Angle(Float:fOrigin[3],Float:vAngles[3], Float:multiplier, FRU, Float:vecReturn[3])
{
   angle_vector(vAngles, FRU, vecReturn)
   vecReturn[0] = vecReturn[0] * multiplier + fOrigin[0]
   vecReturn[1] = vecReturn[1] * multiplier + fOrigin[1]
   vecReturn[2] = vecReturn[2] * multiplier + fOrigin[2]
}
	
