#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>

#define ANIM_IDLE		0
#define ANIM_DRAW		3
#define ANIM_PRIMARYATTACK		6
#define ANIM_PRIMARYATTACK2		7
#define ANIM_SECONDARYATTACK		5

#define ANIM_ONE (1<<1)

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

new g_knife[33], g_secattack[33]

native zp_tattoo_get(id)

new g_MaxPlayers;

#include "knife_combat.inl"
#include "knife_axe.inl"
#include "knife_hammer.inl"
#include "knife_papin.inl"

public plugin_natives()
{
	register_native("zp_extra_knife_set", "native_knife_set")
	register_native("zp_extra_knife_get", "native_knife_get")
	
	g_MaxPlayers = get_maxplayers();
}

public plugin_precache() {
	knife_combat_precache()
	knife_axe_precache()
	knife_hammer_precache()
	knife_papin_precache()
}

public plugin_init(){
	register_forward(FM_EmitSound, "fm_emitsound")
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "ham_item_deploy_post",1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "ham_weapon_primaryattack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "ham_weapon_secondaryattack")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_knife", "ham_weapon_idle")
	RegisterHam(Ham_TraceAttack, "player", "ham_traceattack_post")
	RegisterHam(Ham_TraceAttack, "player", "ham_traceattack_post")
	RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack_post")
	RegisterHam(Ham_TraceAttack, "func_breakable", "ham_traceattack_post")
	
	knife_combat_init()
	knife_axe_init()
	knife_hammer_init()
	knife_papin_init()
}

public ham_item_deploy_post(weapon_ent){
	static id;id=get_pdata_cbase(weapon_ent,41,4)
	play_weapon_animation(id, ANIM_DRAW)
	if(g_knife[id]==0&&!zp_core_is_zombie(id)) knife_combat_deploy(id)
	if(g_knife[id]==1&&!zp_core_is_zombie(id)) knife_axe_deploy(id)
	if(g_knife[id]==2&&!zp_core_is_zombie(id)) knife_hammer_deploy(id, weapon_ent)
	if(g_knife[id]==3&&!zp_core_is_zombie(id)) knife_papin_deploy(id)
	set_pdata_float(id, 83, 0.5, 5)
	set_pdata_float(weapon_ent, 48, 1.4, 4)
}

public ham_traceattack_post(victim,attacker,Float:flDamage,Float:direction[3],ptr,damage_type) {
	if(!is_user_connected(attacker)||get_user_weapon(attacker)!=CSW_KNIFE)return
	
	if(g_secattack[attacker]) play_weapon_animation(attacker, ANIM_SECONDARYATTACK-1)
	
	if(zp_core_is_zombie(attacker)) return
	
	new Float:End[3], Float:vecPlane[3]
	get_tr2(ptr, TR_vecEndPos, End)
	
	if(is_user_alive(victim)&&zp_core_is_zombie(victim)){
		if(g_knife[attacker]==0) knife_combat_traceattack(flDamage)
		if(g_knife[attacker]==1) knife_axe_traceattack(flDamage)
		if(g_knife[attacker]==2) knife_hammer_traceattack(flDamage, End)
	}
	get_tr2(ptr,TR_vecPlaneNormal,vecPlane)
	xs_vec_mul_scalar(vecPlane,5.0,vecPlane)
	xs_vec_add(End,vecPlane,End)
	
	if(g_knife[attacker]==3) knife_papin_traceattack(attacker, victim, flDamage, End)
}

public ham_weapon_primaryattack(weapon_entity){
	static id;id=get_pdata_cbase(weapon_entity,41,4)
	if(g_knife[id]==2&&!zp_core_is_zombie(id)) {
		knife_hammer_primary(id, weapon_entity)
		return HAM_SUPERCEDE
	}
	if(g_knife[id]==3&&!zp_core_is_zombie(id)) {
		knife_papin_primary(id, weapon_entity)
		return HAM_SUPERCEDE
	}
	if(get_pdata_int(weapon_entity, 74, 4) & ANIM_ONE){
		play_weapon_animation(id, ANIM_PRIMARYATTACK)
		set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~ANIM_ONE, 4)
	}else{
		play_weapon_animation(id, ANIM_PRIMARYATTACK2)
		set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)|ANIM_ONE, 4)
	}
	ExecuteHam(Ham_Weapon_PrimaryAttack, weapon_entity)
	set_pdata_float(weapon_entity,46,0.45,4)
	set_pdata_float(weapon_entity, 48, 2.5, 4)
	return HAM_SUPERCEDE
}

public ham_weapon_secondaryattack(weapon_entity){
	static id;id=get_pdata_cbase(weapon_entity,41,4)
	if(g_knife[id]==2&&!zp_core_is_zombie(id)) {
		knife_hammer_secondary(id, weapon_entity)
		return HAM_SUPERCEDE
	}
	if(g_knife[id]==3&&!zp_core_is_zombie(id)) {
		knife_papin_secondary(id, weapon_entity)
		return HAM_SUPERCEDE
	}
	play_weapon_animation(id, ANIM_SECONDARYATTACK)
	g_secattack[id]=true
	ExecuteHam(Ham_Weapon_SecondaryAttack, weapon_entity)
	g_secattack[id]=false
	set_pdata_float(weapon_entity,46,1.1,4)
	set_pdata_float(weapon_entity, 48, 2.0, 4)
	return HAM_SUPERCEDE
}

public ham_weapon_idle(ent) {
	static id;id=get_pdata_cbase(ent,41,4)
	if(get_pdata_float(ent, 48, 4)>0.0)return HAM_IGNORED
	if(g_knife[id]==2&&!zp_core_is_zombie(id)) {
		knife_hammer_idle(id, ent)
		return HAM_SUPERCEDE
	}
	if(g_knife[id]==3&&!zp_core_is_zombie(id)) {
		knife_papin_idle(id, ent)
		return HAM_SUPERCEDE
	}
	play_weapon_animation(id, ANIM_IDLE)
	set_pdata_float(ent, 48, 5.0, 4)
	return HAM_SUPERCEDE
}

public zp_fw_items_select_post(id,itemid) {
	knife_combat_extra(id, itemid)
	knife_axe_extra(id, itemid)
	knife_hammer_extra(id, itemid)
	knife_papin_extra(id, itemid)
}

public fm_emitsound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id)||zp_core_is_zombie(id)) return HAM_IGNORED
	if(equal(sample, "player/pl_step1.wav")||equal(sample, "player/pl_step2.wav")||equal(sample, "player/pl_step3.wav")||equal(sample, "player/pl_step4.wav")) {
	emit_sound(id, channel, "csobc/boss_footstep_1.wav", volume, attn, flags, pitch)
        return HAM_SUPERCEDE
	}
	if (sample[8] != 'k' || sample[9] != 'n' || sample[10] != 'i') return HAM_IGNORED
        new sound[64], g_index_sound
      
	if (sample[14] == 'd') g_index_sound=0
	else if (sample[14] == 'h') {
		if (sample[17] == 'w') g_index_sound=1
		else g_index_sound=2
	}else{
		if (sample[15] == 'l') g_index_sound=3
		else g_index_sound=4
	}
	
	if(g_knife[id]==0)knife_combat_sound(g_index_sound, sound)
	if(g_knife[id]==1)knife_axe_sound(g_index_sound, sound)
	if(g_knife[id]==2)knife_hammer_sound(g_index_sound, sound)
	if(g_knife[id]==3)return HAM_SUPERCEDE
                
        emit_sound(id, channel, sound, volume, attn, flags, pitch)
        return HAM_SUPERCEDE
}

public native_knife_set(plugin_id, num_params)
{
	new id = get_param(1)
	new set = get_param(2)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return;
	}
	
	g_knife[id] = set;
}

public native_knife_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_knife[id]
}

stock play_weapon_animation(id,sequence)message_begin(MSG_ONE,SVC_WEAPONANIM,_,id),write_byte(sequence),write_byte(zp_tattoo_get(id)),message_end()