#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <engine>

#define PLUGIN "JailBreak: Drop the Money"
#define VERSION "1.1"
#define AUTHOR "SAMURAI & O'Zone"

#define MINS Float:{-12.650000, -22.070000, -3.950000}
#define MAXS Float:{19.870001, 8.390000, 20.540001}

new const money_model[] = "models/reload/briefcase_money_model.mdl";
new const money_classname[] = "csr_money";

new bool:bBlock[33];

native jail_get_prisoner_last();

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("DeathMsg", "DeathMsg", "ade");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");

	register_forward(FM_Touch, "TouchMoney");
}

public plugin_natives()
	register_native("set_user_block_drop", "set_user_block_drop");
	
public plugin_precache()
	precache_model(money_model);

public client_disconnected(id)
	bBlock[id] = false;

public DeathMsg()
{
	new iVictim = read_data(2);
	
	if(jail_get_prisoner_last() == iVictim || bBlock[iVictim] || !is_user_connected(iVictim)) return;
	
	DropMoney(iVictim);
}

public NewRound()
{
	new ent = 0;
	
	while((ent = find_ent_by_class(ent, money_classname)) > 0) engfunc(EngFunc_RemoveEntity, ent);
}

public DropMoney(id)
{
	new Float:fOrigin[3];
	
	pev(id, pev_origin, fOrigin);
	
	fOrigin[2] -= 30.0;
	
	new ent = fm_create_entity("info_target");
	
	set_pev(ent, pev_classname, money_classname);
	set_pev(ent, pev_origin, fOrigin);

	engfunc(EngFunc_SetModel, ent, money_model);

	set_pev(ent, pev_mins, Float:{ -10.0, -10.0, 0.0 });
	set_pev(ent, pev_maxs, Float:{ 10.0, 10.0, 50.0 });
	set_pev(ent, pev_size, Float:{ -1.0, -3.0, 0.0, 1.0, 1.0, 10.0 });
	engfunc(EngFunc_SetSize, ent, Float:{ -1.0,-3.0,0.0 }, Float:{ 1.0,1.0,10.0 });
	
	set_pev(ent, pev_solid, SOLID_TRIGGER);
	set_pev(ent, pev_movetype, MOVETYPE_FLY);
	
	new iMoney = cs_get_user_money(id) / 2;
	
	set_pev(ent, pev_iuser4, iMoney);
	
	cs_set_user_money(id, iMoney, 1);
}

public TouchMoney(ent, id)
{	
	if(!pev_valid(ent) || !is_user_alive(id)) return FMRES_IGNORED;
	
	static szClassName[64];
	
	pev(ent, pev_classname, szClassName, charsmax(szClassName));
	
	if(!equal(szClassName, money_classname)) return FMRES_IGNORED;
	
	cs_set_user_money(id, min(cs_get_user_money(id) + pev(ent, pev_iuser4), 16000));

	engfunc(EngFunc_RemoveEntity, ent);

	return FMRES_IGNORED;
}

public set_user_block_drop(plugin, params)
{
	if(params != 1) return;

	bBlock[get_param(1)] = true;
}