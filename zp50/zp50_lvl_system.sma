#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_ammopacks>
#include <dhudmessage>

new g_lvl[33], g_exp[33]
/*
new const EXPERIENCE[] = {
		0, // нулевой уровень (не используется).
		5, // первый уровень. сколько експы нужно для 2 лвл
		6, // второй уровень. сколько експы нужно для 3 лвл
		7
		
		
}
new MAX_LVL = sizeof EXPERIENCE
*/
new MAX_LVL = 500

public plugin_init() RegisterHam(Ham_Killed, "player", "ham_PlayerKilled")

public client_connect(id) g_lvl[id]=1

public plugin_natives()
{
	register_library("zp50_level")
	register_native("zp_level_get", "native_level_get")
	register_native("zp_maxlevel_get", "native_maxlevel_get")
	register_native("zp_exp_get", "native_exp_get")
	register_native("zp_nextexp_get", "native_nextexp_get")
	
	register_native("zp_level_set", "native_level_set")
	register_native("zp_exp_set", "native_exp_set")
}

public ham_PlayerKilled(victim, attacker, shouldgib)
{
	if(victim==attacker || !is_user_connected(attacker)) return
	if(zp_core_is_zombie(attacker)) return
	exp_up(attacker)
}

public exp_up(id){
	if(g_lvl[id]>=MAX_LVL) return
	
	g_exp[id]++
	if(g_exp[id]>=g_lvl[id]){
		g_exp[id]=0
		g_lvl[id]++
		zp_ammopacks_set(id, zp_ammopacks_get(id) + 10)
		return
	}
}

public native_level_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_lvl[id];
}

public native_maxlevel_get(plugin_id, num_params)
{
	return MAX_LVL;
}

public native_exp_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_exp[id];
}

public native_nextexp_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_lvl[id];
}

public native_level_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return;
	}
	
	g_lvl[id]=get_param(2);
}

public native_exp_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return;
	}
	
	g_exp[id]=get_param(2)
}