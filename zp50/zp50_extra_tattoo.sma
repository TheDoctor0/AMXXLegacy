#include <amxmodx>
#include <hamsandwich>
#include <zp50_items>
#include <zp50_class_human>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

new g_tattoo[33], g_itemid_Flame, g_itemid_Tiger, g_itemid_Dragon, g_MaxPlayers

public plugin_natives()
{
	register_library("zp50_tattoo")
	register_native("zp_tattoo_get", "native_tattoo_get")
	register_native("zp_tattoo_set", "native_tattoo_set")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_generic("sprites/640hudTATTOO.spr")
}

public plugin_init(){
	RegisterHam(Ham_Spawn,"player","ham_spawn_post",1)
	g_itemid_Flame=zp_items_register("Flame Tattoo",0)
	g_itemid_Tiger=zp_items_register("Tiger Tattoo",0)
	g_itemid_Dragon=zp_items_register("Dragon Tattoo",0)
}

public zp_fw_items_select_post(id,itemid) {
	if(itemid!=g_itemid_Dragon&&itemid!=g_itemid_Tiger&&itemid!=g_itemid_Flame) return
	if(itemid==g_itemid_Flame){
	g_tattoo[id]=1
	show_pickup_msg(id)
	}
	if(itemid==g_itemid_Tiger){
	g_tattoo[id]=2
	show_pickup_msg(id)
	}
	if(itemid==g_itemid_Dragon){
	g_tattoo[id]=3
	show_pickup_msg(id)
	}
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	ExecuteHamB(Ham_Item_Deploy,weapon_ent)
}

public native_tattoo_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return g_tattoo[id] + zp_class_human_get_sex(id);
}

public native_tattoo_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return;
	}
	
	g_tattoo[id]=get_param(2)
}

new bool:g_wl_load_state[33]

public ham_spawn_post(id) if(is_user_alive(id)&&!g_wl_load_state[id])load_weaponlist(id) 
public client_disconnect(id)g_wl_load_state[id]=false

public load_weaponlist(id)
{
	g_wl_load_state[id]=true
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id) 
	write_string("tattoo_chaos") 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(2) 
	write_byte(1) 
	write_byte(115) 
	write_byte(0) 
	message_end()
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id) 
	write_string("tattoo_tiger") 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(2) 
	write_byte(1) 
	write_byte(116) 
	write_byte(0) 
	message_end()
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id) 
	write_string("tattoo_dragon") 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(-1) 
	write_byte(2) 
	write_byte(1) 
	write_byte(117) 
	write_byte(0) 
	message_end()
}
public show_pickup_msg(id){
	
	message_begin(MSG_ONE, get_user_msgid("WeapPickup"), {0,0,0}, id) 
	switch(g_tattoo[id]){
	case 1: write_byte(115) 
	case 2: write_byte(116) 
	case 3: write_byte(117) 
	}
	message_end()
}