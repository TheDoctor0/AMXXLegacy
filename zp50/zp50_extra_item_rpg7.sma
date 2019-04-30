//=========================================================================
#define CSW_BALROG7		CSW_AUG
new const g_weapon_entity[]=	"weapon_aug"
new const g_weaponbox_model[]=	"models/w_aug.mdl"

#define WEAPON_NAME		"RPG-7"
#define WEAPON_COST		0

#define DAMAGE			2.0
#define RATE_OF_FIRE		0.7
#define CLIP			1
#define AMMO			10
#define TIME_RELOAD		2.0

#define ANIM_IDLE			0
#define ANIM_SHOOT		5
#define ANIM_RELOAD		6
#define ANIM_DRAW		7
#define ANIM_CHANGE		9


#define BODY_NUMBER		0
new const MODELS[][]={
				"models/csobc/v_rpg7.mdl",
				"models/csobc/p_rpg7.mdl",
				"models/csobc/w_rpg7.mdl"
}
new const SOUNDS[][]= {
				"weapons/rpg7-1.wav",
				"weapons/rpg7_draw.wav",
				"weapons/rpg7_reload.wav"
}
#define WEAPONLIST		"csobc_rpg7"
new const SPRITES[][]=	{
				"sprites/csobc/640hud7.spr",
				"sprites/csobc/640hud118.spr"
}
new const GrenadeModel[]="models/grenade.mdl"
//=========================================================================
#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_items>
native zp_tattoo_get(id)
new g_msgWeaponList,g_itemid,g_wpn_variables[10],g_iszWeaponKey,decal_index
new trail_spr, explode_spr, smoke_spr
new Blood[2]
#define M1_MODE		(1<<1)
#define is_valid_weapon(%1) (pev_valid(%1)&&pev(%1, pev_impulse) == g_iszWeaponKey)

public plugin_precache() {
		for(new i;i<=charsmax(MODELS);i++)precache_model(MODELS[i])
		for(new i;i<=charsmax(SOUNDS);i++)precache_sound(SOUNDS[i])
		for(new i;i<=charsmax(SPRITES);i++) precache_generic(SPRITES[i])
		new tmp[32];formatex(tmp,charsmax(tmp),"sprites/%s.txt",WEAPONLIST)
		precache_generic(tmp)
		for(new i;i<=charsmax(SPRITES);i++)precache_generic(SPRITES[i])
		g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
		register_clcmd(WEAPONLIST, "clcmd_weapon")
		register_message(78, "message_weaponlist")
		trail_spr=precache_model("sprites/laserbeam.spr")
		explode_spr=precache_model("sprites/fexplo.spr")
		smoke_spr=precache_model("sprites/black_smoke4.spr")	
		Blood[0] = precache_model("sprites/bloodspray.spr")
		Blood[1] = precache_model("sprites/blood.spr")	
		precache_model(GrenadeModel) 
}
public plugin_init() {
		register_forward(FM_SetModel, "fm_setmodel")
		register_forward(FM_UpdateClientData, "fm_updateclientdata_post", 1)
		register_forward(FM_PlaybackEvent, "fm_playbackevent")
		RegisterHam(Ham_Item_Deploy, g_weapon_entity, "ham_item_deploy_post",1)
		RegisterHam(Ham_Weapon_PrimaryAttack, g_weapon_entity, "ham_weapon_primaryattack")
		RegisterHam(Ham_Weapon_SecondaryAttack, g_weapon_entity, "ham_weapon_secondaryattack")
		RegisterHam(Ham_Weapon_Reload, g_weapon_entity, "ham_weapon_reload")
		RegisterHam(Ham_Weapon_WeaponIdle, g_weapon_entity, "ham_weapon_idle")
		RegisterHam(Ham_Item_PostFrame, g_weapon_entity, "ham_item_postframe")
		RegisterHam(Ham_Item_AddToPlayer, g_weapon_entity, "ham_item_addtoplayer")
		g_msgWeaponList=get_user_msgid("WeaponList")
		g_iszWeaponKey=engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_itemid=zp_items_register(WEAPON_NAME,WEAPON_COST)
		
		register_touch("rpg7 rocket", "*", "fwTouch")
		
		decal_index=fm_get_decal_index("{scorch3")
}
public clcmd_weapon(id)engclient_cmd(id, g_weapon_entity)
public message_weaponlist(msg_id,msg_dest,id)if(get_msg_arg_int(8)==CSW_BALROG7)for(new i=2;i<=9;i++)g_wpn_variables[i]=get_msg_arg_int(i)
public fm_setmodel(model_entity,model[]){
	if(!pev_valid(model_entity))return FMRES_IGNORED			
	if(!equal(model,g_weaponbox_model))return FMRES_IGNORED	
	static weap;weap=fm_find_ent_by_owner(-1,g_weapon_entity,model_entity)	
	if(!is_valid_weapon(weap))return FMRES_IGNORED	
	fm_entity_set_model(model_entity,MODELS[2])
	set_pev(model_entity,pev_body,BODY_NUMBER)
	return FMRES_SUPERCEDE
}
public fm_updateclientdata_post(id,SendWeapons,CD_Handle){
	if(!is_user_alive(id))return
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(!is_valid_weapon(weapon_ent))return
	set_cd(CD_Handle, CD_flNextAttack, get_gametime()+0.001)
}
public fm_playbackevent(flags,id){
	if(!is_user_alive(id))return FMRES_IGNORED
	static weapon_ent;weapon_ent=get_pdata_cbase(id, 373, 5)
	if(!is_valid_weapon(weapon_ent))return FMRES_IGNORED
	return FMRES_SUPERCEDE
}
public ham_item_deploy_post(weapon_ent){
	if(!is_valid_weapon(weapon_ent))return
	static id;id=get_pdata_cbase(weapon_ent,41,4)
	set_pev(id, pev_viewmodel2, MODELS[0]),set_pev(id, pev_weaponmodel2, MODELS[1])
	play_weapon_animation(id, get_pdata_int(weapon_ent,51,4)?ANIM_DRAW:ANIM_DRAW+1)
	set_pdata_float(id, 83, 0.5, 5)
	set_pdata_float(weapon_ent, 48, 1.4, 4)
	set_pdata_int(weapon_ent, 55, 0, 4)
	set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)&~M1_MODE, 4)
}
public ham_weapon_primaryattack(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	new Clip=get_pdata_int(weapon_entity, 51, 4)
	if(!Clip)return HAM_IGNORED
	
	set_pdata_int(weapon_entity, 51,Clip-1, 4)
	
	static Float:push[3]
	
	pev(id, pev_punchangle, push)
	
	push[0]+=random_float(-3.0, -5.5)
	push[1]+=random_float(-3.5, 3.5)
	
	set_pev(id,pev_punchangle,push)				
	
	if(get_pdata_int(weapon_entity, 74, 4)&M1_MODE)
		GrenadeAttack(id)
	else GrenadeAttack(id,1)
	
	set_pdata_int(id,363,90,5)
	set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~M1_MODE, 4)
	
	play_weapon_animation(id, ANIM_SHOOT)
	
	set_pdata_float(weapon_entity, 46, 0.5, 4)
	if(get_pdata_int(weapon_entity,51,4)) set_pdata_float(weapon_entity, 48, 2.25, 4)
	else set_pdata_float(weapon_entity, 48, 0.75, 4)
	set_pdata_int(weapon_entity, 55, 0, 4)
	
	emit_sound(id, CHAN_WEAPON, SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
	
	return HAM_SUPERCEDE
}
public ham_weapon_secondaryattack(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	if(get_pdata_float(weapon_entity,47,4)>0.0)return HAM_IGNORED
	static id;id=get_pdata_cbase(weapon_entity,41,4)
	if(get_pdata_int(weapon_entity, 74, 4)&M1_MODE){
		set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~M1_MODE, 4)
		play_weapon_animation(id, get_pdata_int(weapon_entity,51,4)?ANIM_CHANGE+1:ANIM_CHANGE+3)
		set_pdata_int(id,363, 90, 5)
	}else{
		set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)|M1_MODE, 4)
		play_weapon_animation(id, get_pdata_int(weapon_entity,51,4)?ANIM_CHANGE:ANIM_CHANGE+2)
		set_pdata_int(id,363, 65, 5)
	}
	set_pdata_float(weapon_entity,46,0.3,4)
	set_pdata_float(weapon_entity,47,0.3,4)
	set_pdata_float(weapon_entity,48,0.5,4)
	return HAM_SUPERCEDE
}
public ham_weapon_reload(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity,41,4)
	static bpammo;bpammo=get_pdata_int(id,376+get_pdata_int(weapon_entity,49,4),5)
	static clip;clip=get_pdata_int(weapon_entity,51,4)
	if(!bpammo||clip==CLIP)return HAM_SUPERCEDE
	ExecuteHam(Ham_Weapon_Reload,weapon_entity)
	play_weapon_animation(id,ANIM_RELOAD)
	set_pdata_int(id,363,90,5)
	set_pdata_float(id,83,TIME_RELOAD,5)
	set_pdata_int(weapon_entity,54,1,4)
	return HAM_SUPERCEDE
}
public ham_weapon_idle(ent) {
	if(!is_valid_weapon(ent))return HAM_IGNORED
	static id; id = get_pdata_cbase(ent, 41, 4)

	if(get_pdata_float(ent, 48, 4)>0.0)return HAM_IGNORED
	if(get_pdata_int(ent, 74, 4)&M1_MODE)
		play_weapon_animation(id, get_pdata_int(ent,51,4)?ANIM_IDLE+1:ANIM_IDLE+3)
	else play_weapon_animation(id, get_pdata_int(ent,51,4)?ANIM_IDLE:ANIM_IDLE+2)
	set_pdata_float(ent, 48, 5.0, 4)
	return HAM_SUPERCEDE
}
public ham_item_postframe(weapon_entity)  {
	if(!is_valid_weapon(weapon_entity)) return
	static id; id = get_pdata_cbase(weapon_entity,41,4)
	if(get_pdata_int(weapon_entity, 54, 4)&&get_pdata_float(id, 83, 5)<=0.0){		
		static bpammo;bpammo=get_pdata_int(id, 376 + get_pdata_int(weapon_entity, 49, 4), 5)
		static clip;clip=get_pdata_int(weapon_entity, 51, 4)
		for(new i=clip; i<CLIP;i++)if(bpammo)bpammo--,clip++	
		set_pdata_int(weapon_entity,54,0,4)
		set_pdata_int(weapon_entity,51,clip,4)
		set_pdata_int(id,376+get_pdata_int(weapon_entity,49,4),bpammo,5)
	}
}
public ham_item_addtoplayer(weapon_entity,id)if(is_valid_weapon(weapon_entity))set_weaponlist(id,1)
public zp_fw_items_select_post(id,itemid) {
	if(itemid!=g_itemid)return
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
}
public plugin_natives()
	register_native("zp_give_item_rpg7", "zp_give_item_rpg7", 1);
public zp_give_item_rpg7(id)
{
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
}
public give_weapon(id){
	new Float:Origin[3]
	pev(id, pev_origin, Origin)
	new wName[32],iItem=get_pdata_cbase(id, 367 + 1, 5);
	while (pev_valid(iItem)==2)pev(iItem,pev_classname,wName,31),engclient_cmd(id,"drop",wName),iItem=get_pdata_cbase(iItem, 42, 4)
	new iWeapon=engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,g_weapon_entity))
	if(!pev_valid(iWeapon)) return 0
	dllfunc(DLLFunc_Spawn, iWeapon)
	engfunc(EngFunc_SetOrigin, iWeapon, Origin)
	set_pev(iWeapon, pev_impulse, g_iszWeaponKey)
	set_pdata_int(iWeapon, 51, CLIP, 4)
	new save = pev(iWeapon,pev_solid)
	dllfunc(DLLFunc_Touch,iWeapon,id)
	if(pev(iWeapon, pev_solid)!=save)return iWeapon
	engfunc(EngFunc_RemoveEntity,iWeapon)
	return 0
}
stock play_weapon_animation(id,sequence)message_begin(MSG_ONE,SVC_WEAPONANIM,_,id),write_byte(sequence),write_byte(zp_tattoo_get(id)),message_end()
stock set_weaponlist(id,num=0){
	message_begin(MSG_ONE,g_msgWeaponList,_,id)
	write_string(num?WEAPONLIST:g_weapon_entity) 
	if(num!=2) for(new i=2;i<=9;i++)write_byte(g_wpn_variables[i]) 
	else{
		write_byte(-1)
		write_byte(-1)
		for(new i=4;i<=9;i++)write_byte(g_wpn_variables[i])
	}
	message_end()
}
public Reload(id, ent){	
	static bpammo;bpammo=get_pdata_int(id, 376 + get_pdata_int(ent, 49, 4), 5)
	static clip;clip=get_pdata_int(ent, 51, 4)
	switch(get_pdata_int(ent, 55, 4)){
		case 0:{
			play_weapon_animation(id, 4)
			set_pdata_float(id, 83, 0.7, 5)
			set_pdata_float(ent, 48, 0.7, 4)
			set_pdata_int(ent, 55, 1, 4)
		}
		case 1:{
			if(get_pdata_float(ent, 48, 4)>0.0)return
			if(clip>=CLIP||!bpammo){		
				play_weapon_animation(id, 3)
				set_pdata_float(ent, 48, 0.7, 4)
				set_pdata_int(ent, 55, 0, 4)
				return
			}
			play_weapon_animation(id, 2)
			set_pdata_int(ent, 55, 2, 4)
			set_pdata_float(ent, 48, 0.85, 4)
		}
		case 2:{
			clip++,bpammo--
			set_pdata_int(ent,51,clip,4)
			set_pdata_int(id,376+get_pdata_int(ent,49,4),bpammo,5)
			set_pdata_int(ent, 55, 1, 4)	
		}
	}		
}

stock get_weapon_position(id, Float:fOrigin[3], Float:add_forward=0.0, Float:add_right=0.0, Float:add_up=0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_v_angle, Angles)
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up,  Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0]=fOrigin[0]+Forward[0]+Right[0]+Up[0]
	fOrigin[1]=fOrigin[1]+Forward[1]+Right[1]+Up[1]
	fOrigin[2]=fOrigin[2]+Forward[2]+Right[2]+Up[2]
}

stock GrenadeAttack(id, random=0)
{	
	new Float:Origin[3], Float:AimOrigin[3], Float:Velocity[3], Float:PlayerVelocity[3]

	pev(id, pev_velocity, PlayerVelocity)
	
	new ent=fm_create_entity("info_target")
	
	if(!ent) return

	set_pev(ent, pev_classname, "rpg7 rocket")	
	
	set_pev(ent, pev_owner, id)
	
	get_weapon_position(id, Origin, .add_forward=60.0, .add_right=12.0, .add_up=-5.0)
		
	set_pev(ent, pev_origin, Origin)
	
	fm_entity_set_model(ent,GrenadeModel)

	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)

	fm_entity_set_size(ent,Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0})

	set_pev(ent, pev_gravity, 0.8)

	fm_get_aim_origin(id, AimOrigin)

	xs_vec_sub(AimOrigin, Origin, AimOrigin)
	xs_vec_normalize(AimOrigin, Velocity)
	xs_vec_mul_scalar(Velocity, 2096.0, Velocity)
	if(random){
	Velocity[0]+=random_float(-128.0,128.0)
	Velocity[1]+=random_float(-128.0,128.0)
	Velocity[2]+=random_float(-128.0,128.0)
	} 
	
	vector_to_angle(AimOrigin, AimOrigin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(trail_spr)
	write_byte(25)
	write_byte(3)
	write_byte(180)
	write_byte(180)
	write_byte(180)
	write_byte(250)
	message_end()	
	 	
	xs_vec_add(Velocity, PlayerVelocity, Velocity)	

	set_pev(ent, pev_angles, AimOrigin)
	set_pev(ent, pev_velocity, Velocity)
}

public fwTouch(ent, id)
{
	if(pev(ent, pev_owner)==id)
		return
			
	new Float:Origin[3]

	pev(ent, pev_origin, Origin)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)	
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0]+random_float(20.0, 35.0))
	engfunc(EngFunc_WriteCoord, Origin[1]+random_float(20.0, 35.0))
	engfunc(EngFunc_WriteCoord, Origin[2]+50.0)
	write_short(explode_spr)
	write_byte(19)
	write_byte(20)
	write_byte(0)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+90.0)
	write_short(explode_spr)
	write_byte(25)
	write_byte(20)
	write_byte(0)
	message_end()	

	message_begin(MSG_ALL, SVC_TEMPENTITY) 
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(decal_index)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+10)
	write_short(smoke_spr)
	write_byte(20)
	write_byte(20)
	message_end()	
	
	new victim=FM_NULLENT, Float:vOrigin[3], Float:temp, attacker, Float:damage, Float:radius

	attacker=pev(ent, pev_owner)
	
	radius=200.0
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, radius))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			damage=1000.0
			
			if(1<=victim<=32)
			{
				if(is_user_alive(victim)&&zp_core_is_zombie(victim))
				{
					pev(victim, pev_origin, vOrigin)
					
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
					write_byte(TE_BLOODSPRITE)
					engfunc(EngFunc_WriteCoord, vOrigin[0])
					engfunc(EngFunc_WriteCoord, vOrigin[1])
					engfunc(EngFunc_WriteCoord, vOrigin[2])
					write_short(Blood[0])
					write_short(Blood[1])
					write_byte(76)
					write_byte(10)
					message_end()
					
					temp=vector_distance(Origin, vOrigin)
					
					//xs_vec_normalize(vOrigin, vOrigin)
					//xs_vec_mul_scalar(vOrigin, KNOCKBACK, vOrigin)
					//xs_vec_neg(vOrigin, vOrigin)
					
					//vOrigin[2]+=KNOCKBACK
					
					//set_pev(victim, pev_velocity, vOrigin)
		
					if(temp<1.0)temp=1.0
		
					if(temp>radius)temp=radius
						
					damage-=(damage/radius)*temp			

					ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET|DMG_ALWAYSGIB)
				}
			}
			else
				ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET)
		}
	}
	
	fm_remove_entity(ent)
}