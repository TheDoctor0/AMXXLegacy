#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "CS:GO C4"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

new const c4[][] = { "models/p_c4_csgo.mdl", "models/v_c4_csgo.mdl", "models/w_c4_csgo.mdl" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Item_Deploy, "weapon_c4", "weapon_deploy", 1);
	
	register_forward(FM_SetModel, "set_model");
}

public plugin_precache()
	for(new i = 0; i < sizeof(c4); i++) precache_model(c4[i]);

public weapon_deploy(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);

	if(!is_user_alive(id)) return HAM_IGNORED;

	set_pev(id, pev_weaponmodel2, c4[0]);
	set_pev(id, pev_viewmodel2, c4[1]);

	return HAM_IGNORED;
}

public set_model(ent, model[])
{
	if(equali(model,"models/w_c4.mdl"))
	{
		engfunc(EngFunc_SetModel, ent, c4[2]);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}