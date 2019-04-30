//=========================================================================
#define CSW_BALROG7		CSW_P228
new const g_weapon_entity[]=	"weapon_p228"
new const g_weaponbox_model[]=	"models/w_p228.mdl"

#define WEAPON_NAME		"Janus-1"
#define WEAPON_COST		0

#define SHOTS_MODE		5
#define DAMAGE			1.5
#define DAMAGE_EX		2.0
#define RECOIL			0.5
#define RATE_OF_FIRE		2.5
#define RATE_OF_FIREEX		0.25
#define CLIP			50
#define AMMO			100
#define TIME_RELOAD		3.4

#define ANIM_IDLE			0
#define ANIM_DRAW		3
#define ANIM_SHOOT		6
#define ANIM_CHANGE		9


#define BODY_NUMBER		0
new const MODELS[][]={
				"models/csobc/v_janus1.mdl",
				"models/csobc/p_janus1.mdl",
				"models/csobc/w_janus1.mdl"
}
new const SOUNDS[][]= {
				"weapons/janus1-1.wav",
				"weapons/janus1-2.wav",
				"weapons/janus1_exp.wav",
				"weapons/janus1_change1.wav",
				"weapons/janus1_change2.wav",
				"weapons/m79_draw.wav"
}
#define WEAPONLIST		"csobc_janus1"
#define WEAPONLIST_2	"csobc_janus1_2"
new const SPRITES[][]=	{
				"sprites/csobc/640hud7.spr",
				"sprites/csobc/640hud100.spr",
				"sprites/csobc/scope_vip_grenade.spr",
				"sprites/csobc/scope_vip2_grenade.spr"
}
#define SPRITE_SHOCK		"sprites/csobc/setrum_lagi2.spr"
new const GrenadeModel[]="models/grenade.mdl"
//=========================================================================
#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>
new g_msgWeaponList,g_itemid,g_wpn_variables[10],g_iszWeaponKey,g_iHits[33]
new trail_spr, decal_index, explode_spr, puff_spr, Blood[2]
new gMsg_CurWeapon, gMsg_AmmoX, gMsg_HideWeapon, gMsg_Crosshair, gMsg_SetFOV
#define is_valid_weapon(%1) (pev_valid(%1)&&pev(%1, pev_impulse) == g_iszWeaponKey)
#define JANUS_READY		(1<<1)
#define JANUS_MODE		(1<<2)
public plugin_precache() {
		for(new i;i<=charsmax(MODELS);i++)precache_model(MODELS[i])
		for(new i;i<=charsmax(SOUNDS);i++)precache_sound(SOUNDS[i])
		for(new i;i<=charsmax(SPRITES);i++) precache_generic(SPRITES[i])
		new tmp[64];formatex(tmp,charsmax(tmp),"sprites/%s.txt",WEAPONLIST)
		precache_generic(tmp)
		formatex(tmp,charsmax(tmp),"sprites/%s.txt",WEAPONLIST_2)
		precache_generic(tmp)
		for(new i;i<=charsmax(SPRITES);i++)precache_generic(SPRITES[i])
		g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
		trail_spr=precache_model("sprites/laserbeam.spr")
		explode_spr=precache_model("sprites/fexplo.spr")//zerogxplode_svd.spr")	
		puff_spr=precache_model("sprites/wall_puff1.spr")	
		Blood[0]=precache_model("sprites/bloodspray.spr")
		Blood[1]=precache_model("sprites/blood.spr")
		precache_model(GrenadeModel)
		precache_model(SPRITE_SHOCK)
		register_clcmd(WEAPONLIST, "clcmd_weapon")
		register_message(78, "message_weaponlist")
}
public plugin_init() {
		register_forward(FM_CmdStart, "fm_cmdstart")
		register_forward(FM_SetModel, "fm_setmodel")
		register_forward(FM_UpdateClientData, "fm_updateclientdata_post", 1)
		register_forward(FM_PlaybackEvent, "fm_playbackevent")
		RegisterHam(Ham_Item_Deploy, g_weapon_entity, "ham_item_deploy_post",1)
		RegisterHam(Ham_Item_Holster, g_weapon_entity, "ham_item_holster_post",1)
		RegisterHam(Ham_Weapon_PrimaryAttack, g_weapon_entity, "ham_weapon_primaryattack")
		RegisterHam(Ham_Weapon_Reload, g_weapon_entity, "ham_weapon_reload")
		RegisterHam(Ham_Weapon_WeaponIdle, g_weapon_entity, "ham_weapon_idle")
		RegisterHam(Ham_Item_PostFrame, g_weapon_entity, "ham_item_postframe")
		RegisterHam(Ham_Item_AddToPlayer, g_weapon_entity, "ham_item_addtoplayer")
		
		register_touch("janus1 grenade", "*", "fwTouch")
		
		g_msgWeaponList=get_user_msgid("WeaponList")
		g_iszWeaponKey=engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_itemid=zp_items_register(WEAPON_NAME,WEAPON_COST)
		
		gMsg_CurWeapon=get_user_msgid("CurWeapon")
		gMsg_AmmoX=get_user_msgid("AmmoX")	
		gMsg_SetFOV=get_user_msgid("SetFOV")
		gMsg_HideWeapon=get_user_msgid("HideWeapon")
		gMsg_Crosshair=get_user_msgid("Crosshair")	
		
		decal_index=fm_get_decal_index("{scorch3")
		
		register_message(gMsg_AmmoX, "Message_AmmoX")
		register_message(gMsg_CurWeapon, "Message_CurWeapon")
}
public clcmd_weapon(id)engclient_cmd(id, g_weapon_entity)
public message_weaponlist(msg_id,msg_dest,id)if(get_msg_arg_int(8)==CSW_BALROG7)for(new i=2;i<=9;i++)g_wpn_variables[i]=get_msg_arg_int(i)
public fm_cmdstart(id,uc_handle,seed){
	if(!is_user_alive(id))return
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	if(!is_valid_weapon(weapon_ent)) return
	if((get_uc(uc_handle,UC_Buttons)&IN_ATTACK2)&&get_pdata_float(id,83,5)<=0.0&&get_pdata_float(weapon_ent, 46, 4)<=0.0){
		if(get_pdata_int(weapon_ent, 74, 4) & JANUS_READY){
			set_weaponlist(id,3)
			Msg_SetFOV(id, 89)
			Msg_CurWeapon(id, 1, CSW_BALROG7, -1)
			Msg_SetFOV(id, 90)
			play_weapon_animation(id, ANIM_CHANGE)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)|JANUS_MODE, 4)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)&~JANUS_READY, 4)
			set_pdata_float(id,83,1.5,5)
			set_pdata_float(weapon_ent, 48, 2.0, 4)
			set_pdata_float(weapon_ent, 47, 5.0, 4)
		}
	}
}
public fm_setmodel(model_entity,model[]){
	if(!pev_valid(model_entity)||!equal(model,g_weaponbox_model))return FMRES_IGNORED			
	static weap;weap=fm_find_ent_by_owner(-1,g_weapon_entity,model_entity)	
	if(!is_valid_weapon(weap))return FMRES_IGNORED	
	fm_entity_set_model(model_entity,MODELS[2])
	set_pev(model_entity,pev_body,BODY_NUMBER)
	return FMRES_SUPERCEDE
}
public fm_updateclientdata_post(id,SendWeapons,CD_Handle){
	if(!is_user_alive(id))return
	static weapon_ent; weapon_ent=get_pdata_cbase(id,373,5)
	if(is_valid_weapon(weapon_ent)) set_cd(CD_Handle, CD_flNextAttack, get_gametime()+0.001)
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
	if(get_pdata_int(weapon_ent, 74, 4) & JANUS_MODE) play_weapon_animation(id, ANIM_DRAW+2)
	else play_weapon_animation(id, get_pdata_int(weapon_ent, 74, 4) & JANUS_READY?ANIM_DRAW+1:ANIM_DRAW)
	set_pdata_float(id, 83, 0.5, 5)
	set_pdata_float(weapon_ent, 48, 1.4, 4)
	Msg_HideWeapon(id, 64)
	
	Msg_SetFOV(id, 89)
	Msg_CurWeapon(id, 1, CSW_BALROG7, -1)
	Msg_SetFOV(id, 90)	
}
public ham_item_holster_post(weapon_ent){
	if(!is_valid_weapon(weapon_ent))return
	static id;id=get_pdata_cbase(weapon_ent,41,4)
	Msg_HideWeapon(id, 128)
	
	Msg_Crosshair(id, 0)
}
public ham_weapon_primaryattack(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
		
	if(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE){
		GrenadeAttack(id,weapon_entity)
		
		emit_sound(id, CHAN_WEAPON, SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		play_weapon_animation(id, ANIM_SHOOT+2)
		
		set_pdata_float(weapon_entity,46,RATE_OF_FIREEX,4)
		set_pdata_float(weapon_entity, 48, 1.5, 4)
	}else{
		static clip;clip=get_pdata_int(weapon_entity,51,4)
		if(!clip) return HAM_IGNORED
		set_pdata_int(weapon_entity,51, clip-1,4)
		GrenadeAttack(id, weapon_entity)	
		
		Msg_AmmoX(id, 8, clip-1)
		
		emit_sound(id, CHAN_WEAPON, SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		play_weapon_animation(id, (get_pdata_int(weapon_entity, 74, 4) & JANUS_READY)?ANIM_SHOOT+1:ANIM_SHOOT)
		
		set_pdata_float(weapon_entity,46,RATE_OF_FIRE,4)
		set_pdata_float(weapon_entity, 48, 3.0, 4)
	}
	return HAM_SUPERCEDE
}
public ham_weapon_reload(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	return HAM_SUPERCEDE
}
public ham_weapon_idle(ent) {
	if(!is_valid_weapon(ent))return HAM_IGNORED
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(get_pdata_float(ent, 48, 4)>0.0)return HAM_IGNORED
	if(get_pdata_int(ent, 74, 4) & JANUS_MODE){
		play_weapon_animation(id, ANIM_IDLE+2)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}else if(get_pdata_int(ent, 74, 4) & JANUS_READY){
		play_weapon_animation(id, ANIM_IDLE+1)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}else{
		play_weapon_animation(id, ANIM_IDLE)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}
public ham_item_postframe(weapon_entity)  {
	if(!is_valid_weapon(weapon_entity)) return
	static id; id = get_pdata_cbase(weapon_entity,41,4)
	if(get_pdata_float(weapon_entity, 47, 4)<=0.0){
		if(get_pdata_int(weapon_entity, 74, 4)&JANUS_READY&&get_pdata_float(weapon_entity, 46, 4)<=0.0){
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_READY, 4)
			set_pdata_float(weapon_entity, 48, 0.1, 4)
		}else if(get_pdata_int(weapon_entity, 74, 4)&JANUS_MODE){
			play_weapon_animation(id, ANIM_CHANGE+1)
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_MODE, 4)
			set_pdata_float(weapon_entity, 46, 1.5, 4)
			set_pdata_float(weapon_entity, 48, 1.5, 4)
			emit_sound(id, CHAN_WEAPON, SOUNDS[1], 0.0, ATTN_NORM, 0, PITCH_NORM)
		}
		set_weaponlist(id,1)
		Msg_SetFOV(id, 89)
		Msg_CurWeapon(id, 1, CSW_BALROG7, -1)
		Msg_SetFOV(id, 90)
	}
}
public ham_item_addtoplayer(weapon_entity,id){
	if(!is_valid_weapon(weapon_entity)) return
	if(get_pdata_int(weapon_entity, 74, 4)&JANUS_MODE) set_weaponlist(id,3)
	else if(get_pdata_int(weapon_entity, 74, 4)&JANUS_READY) set_weaponlist(id,2)
	else set_weaponlist(id,1)
}
public zp_fw_items_select_post(id,itemid) {
	if(itemid!=g_itemid)return
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
	Msg_AmmoX(id, 8, CLIP)
}
public plugin_natives()
	register_native("zp_give_item_janus1", "zp_give_item_janus1", 1);
public zp_give_item_janus1(id)
{
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
}
public give_weapon(id){
	new Float:Origin[3]
	pev(id, pev_origin, Origin)
	new wName[32],iItem=get_pdata_cbase(id, 367 + 2, 5);
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
stock play_weapon_animation(id,sequence)set_pev(id, pev_weaponanim, sequence),message_begin(MSG_ONE,SVC_WEAPONANIM,_,id),write_byte(sequence),write_byte(0),message_end()
stock set_weaponlist(id,num=0){	
	message_begin(MSG_ONE,g_msgWeaponList,_,id)
	switch(num){
	case 0:write_string(g_weapon_entity) 
	case 1:write_string(WEAPONLIST) 
	case 2:write_string(WEAPONLIST_2) 
	case 3:write_string(WEAPONLIST) 
	}
	if(num==3){
		write_byte(-1)
		write_byte(-1)
		for(new i=4;i<=9;i++)write_byte(g_wpn_variables[i])
	} else for(new i=2;i<=9;i++)write_byte(g_wpn_variables[i]) 
	message_end()
	
}
public GrenadeAttack(id, weap)
{	
	new Float:Origin[3], Float:AimOrigin[3], Float:Velocity[3], Float:PlayerVelocity[3]

	pev(id, pev_velocity, PlayerVelocity)
	
	new ent=fm_create_entity("info_target")

	set_pev(ent, pev_classname, "janus1 grenade")	
	
	set_pev(ent, pev_owner, id)
	
	get_weapon_position(id, Origin, .add_forward=30.0, .add_right=10.0, .add_up=-5.0)
		
	set_pev(ent, pev_origin, Origin)
	
	fm_entity_set_model(ent,GrenadeModel)

	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)

	fm_entity_set_size(ent,Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0})

	set_pev(ent, pev_gravity, 0.5)
	
	set_pev(ent, pev_iuser1, weap)

	fm_get_aim_origin(id, AimOrigin)

	xs_vec_sub(AimOrigin, Origin, AimOrigin)
	xs_vec_normalize(AimOrigin, Velocity)
	xs_vec_mul_scalar(Velocity, 800.0, Velocity)
	Velocity[2]+=90.0
	
	vector_to_angle(AimOrigin, AimOrigin)

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]-10.0)
	write_short(puff_spr)
	write_byte(6)
	write_byte(35)
	write_byte(2|4|8)
	message_end()	
	
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
	
	emit_sound(ent, CHAN_WEAPON, SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+20.0)
	write_short(explode_spr)
	write_byte(25)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0]+random_float(-64.0, 64.0))
	engfunc(EngFunc_WriteCoord, Origin[1]+random_float(-64.0, 64.0))
	engfunc(EngFunc_WriteCoord, Origin[2]+random_float(30.0, 35.0))
	write_short(explode_spr)
	write_byte(30)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()	

	message_begin(MSG_ALL, SVC_TEMPENTITY) 
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(decal_index)
	message_end()
	
	new victim=FM_NULLENT, Float:vOrigin[3], Float:temp, attacker, Float:damage, Float:radius, iVictims

	attacker=pev(ent, pev_owner)
	
	radius=250.0
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, radius))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT)
		{
			damage=random_float(200.0, 350.0)
			
			if(1<=victim<=32)
			{
				if(is_user_alive(victim)&&zp_core_is_zombie(victim))
				{
					iVictims++
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
				
					xs_vec_sub(Origin, vOrigin, vOrigin)
					
					temp=vector_length(vOrigin)
		
					if(temp<1.0)
						temp=1.0
		
					if(temp>radius)
						temp=radius
						
					damage-=(damage/radius)*temp			
					
					ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET|DMG_ALWAYSGIB)
				}
			}
			else
				ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, damage, DMG_BULLET|DMG_ALWAYSGIB)
		}
	}
	
	new weapon_entity=pev(ent, pev_iuser1)
	if(iVictims) {
		if(!(get_pdata_int(weapon_entity, 74, 4)&JANUS_READY)&&!(get_pdata_int(weapon_entity, 74, 4)&JANUS_MODE))
			g_iHits[attacker]++
	}
	if(g_iHits[attacker]>=SHOTS_MODE){
		g_iHits[attacker]=0
		
		set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)|JANUS_READY, 4)
		set_pdata_float(weapon_entity, 47, 7.0, 4)
		set_weaponlist(attacker,2)
		Msg_SetFOV(attacker, 89)
		Msg_CurWeapon(attacker, 1, CSW_BALROG7, -1)
		Msg_SetFOV(attacker, 90)
	}
	
	fm_remove_entity(ent)
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

stock Msg_CurWeapon(id, active, weapon, ammo)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsg_CurWeapon, {0,0,0}, id)
	write_byte(active)
	write_byte(weapon)
	write_byte(ammo)
	message_end()
}

stock Msg_AmmoX(id, ammotype, num)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsg_AmmoX, {0,0,0}, id)
	write_byte(ammotype)
	write_byte(num)
	message_end()		
}

stock Msg_HideWeapon(id, flags)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsg_HideWeapon, {0,0,0}, id)
	write_byte(flags)
	message_end()
}

stock Msg_Crosshair(id, flag)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsg_Crosshair, {0,0,0}, id)
	write_byte(flag)
	message_end()
}

stock Msg_SetFOV(id, fov)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsg_SetFOV, {0,0,0}, id)
	write_byte(fov)
	message_end()	
}

public Message_AmmoX(msg_id, msg_dest, msg_entity)
{
	if(!is_user_alive(msg_entity))
		return
		
	if(get_msg_arg_int(1)!=8)
		return
		
	static weapon_ent;weapon_ent=get_pdata_cbase(msg_entity,373,5)
	if(!is_valid_weapon(weapon_ent)) return
	
	static clip;clip=get_pdata_int(weapon_ent, 51, 4)
		
	set_msg_arg_int(1, ARG_BYTE, clip)	
}
public Message_CurWeapon(msg_id, msg_dest, msg_entity)
{
	if(get_msg_arg_int(2)!=CSW_BALROG7||!is_user_alive(msg_entity))
		return
		
	static weapon_ent;weapon_ent=get_pdata_cbase(msg_entity,373,5)
	if(!is_valid_weapon(weapon_ent)) return
		
	set_msg_arg_int(3, ARG_BYTE, -1)
	set_msg_arg_int(1, ARG_BYTE, 0)
}