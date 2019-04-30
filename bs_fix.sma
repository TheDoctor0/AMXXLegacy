/*
R3X @ 2009
HomePage: http://amxx.pl

Description:
Plugin allow you add/delete/modifify bombsites on maps. All configuration files goes to:
amxmodx/configs/bs_creator/[MAPNAME].ini

Please do not edit these files manually!

Credits:
- Miczu and his m_eel.amxx (entities laboratory :D)
- Pavulon (help with decals)

*/
#include <amxmodx>
#include <engine>
#include <fakemeta>

#define PLUGIN "BombSite Fix - de_dust2"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define ENTITY_CLASS "func_bomb_target"

public plugin_init() 
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_precache()
{
	register_forward(FM_Spawn, "forward_spawn")

	create_bombsites();
}

public forward_spawn(ent) 
{
	if(!pev_valid(ent)) return FMRES_IGNORED;

	static className[32];

	pev(ent, pev_classname, className, charsmax(className));

	if(equal(className, ENTITY_CLASS)) 
	{
		engfunc(EngFunc_RemoveEntity, ent);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED
}

public create_bombsites()
{
	new Float:fMin[3], Float:fMax[3], Float:fOrigin[3];

	//BombSite B
	fMin[0] = -174.0;
	fMin[1] = -194.0;
	fMin[2] = -50.0;

	fMax[0] = 174.0;
	fMax[1] = 174.0;
	fMax[2] = 50.0;

	fOrigin[0] = -1536.0;
	fOrigin[1] = 2688.0;
	fOrigin[2] = 48.0;

	create_bombsite(fMin, fMax, fOrigin);

	//BombSite A
	fMin[0] = -115.0;
	fMin[1] = -152.0;
	fMin[2] = -50.0;

	fMax[0] = 105.0;
	fMax[1] = 152.0;
	fMax[2] = 50.0;

	fOrigin[0] = 1152.0;
	fOrigin[1] = 2464.0;
	fOrigin[2] = 144.0;

	create_bombsite(fMin, fMax, fOrigin);
}

public create_bombsite(Float:fMin[3], Float:fMax[3], Float:fOrigin[3])
{
	new bombsite = create_entity(ENTITY_CLASS);

	if(bombsite > 0)
	{
		DispatchKeyValue(bombsite, "classname", ENTITY_CLASS);

		DispatchSpawn(bombsite);

		entity_set_string(bombsite, EV_SZ_classname, ENTITY_CLASS);
		entity_set_origin(bombsite, fOrigin);
		entity_set_size(bombsite, fMin, fMax);
		entity_set_edict(bombsite, EV_ENT_owner, 0);
		entity_set_int(bombsite, EV_INT_movetype, 0);
		entity_set_int(bombsite, EV_INT_solid, SOLID_TRIGGER);
		entity_set_float(bombsite,EV_FL_nextthink, halflife_time() + 0.01);

		new targetName[32], ent = -1;

		do
		{
			ent = find_ent_in_sphere(ent, fOrigin, 300.0);

			if(is_valid_ent(ent))
			{
				entity_get_string(ent, EV_SZ_classname, targetName, charsmax(targetName));

				if(!equal(targetName, "func_breakable")) continue;

				if(entity_get_float(ent, EV_FL_dmg_take) == 0.0)
				{
					entity_get_string(ent, EV_SZ_targetname, targetName, charsmax(targetName));

					if(targetName[0])
					{
						entity_set_string(bombsite, EV_SZ_target, targetName);

						break;
					}
				}
			}
		}
		while(ent);
	}
}