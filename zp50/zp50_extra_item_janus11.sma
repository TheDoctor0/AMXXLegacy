//=========================================================================
#define CSW_BALROG7		CSW_M3
new const g_weapon_entity[]=	"weapon_m3"
new const g_weaponbox_model[]=	"models/w_m3.mdl"

#define WEAPON_NAME		"Janus-11"
#define WEAPON_COST		0

#define SHOTS_MODE		14
#define DAMAGE			50.0
#define DAMAGE_EX		400.0
#define RECOIL			0.9
#define RATE_OF_FIRE		0.7
#define CLIP			15
#define AMMO			32
#define TIME_RELOAD		4.0
#define ANIM_SHOOT_1		2
#define ANIM_SHOOT_1R		15
#define ANIM_SHOOT_2		8
#define ANIM_RELOAD		3
#define ANIM_DRAW		6

#define ANIM_CHANGE 1
#define ANIM_CHANGE_EX 10

#define ANIM_IDLE 0
#define ANIM_IDLE_READY 11
#define ANIM_IDLE_MODE 7

#define BODY_NUMBER		0
new const MODELS[][]={
				"models/csobc/v_janus11.mdl",
				"models/csobc/p_janus11.mdl",
				"models/csobc/w_janus11.mdl"
}
new const SOUNDS[][]= {
				"weapons/janus11-1.wav",
				"weapons/janus11-4.wav",
				"weapons/janus11_after_reload.wav",
				"weapons/janus11_change1.wav",
				"weapons/janus11_change2.wav",
				"weapons/janus11_draw.wav",
				"weapons/janus11_insert.wav"
}
#define WEAPONLIST		"csobc_janus11"
new const SPRITES[][]=	{
				"sprites/csobc/640hud7.spr",
				"sprites/csobc/640hud107.spr"
}
//=========================================================================
#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_items>
native zp_tattoo_get(id)
new g_msgWeaponList,g_itemid,g_wpn_variables[10],g_iszWeaponKey,g_index_smoke,g_index_shell,g_iExplode3,decal_index,g_iHits[33]
#define is_valid_weapon(%1) (pev_valid(%1)&&pev(%1, pev_impulse) == g_iszWeaponKey)
#define JANUS_READY		(1<<1)
#define JANUS_MODE		(1<<2)
public plugin_precache() {
		for(new i;i<=charsmax(MODELS);i++)precache_model(MODELS[i])
		for(new i;i<=charsmax(SOUNDS);i++)precache_sound(SOUNDS[i])
		for(new i;i<=charsmax(SPRITES);i++) precache_generic(SPRITES[i])
		new tmp[32];formatex(tmp,charsmax(tmp),"sprites/%s.txt",WEAPONLIST)
		precache_generic(tmp)
		for(new i;i<=charsmax(SPRITES);i++)precache_generic(SPRITES[i])
		g_index_smoke=precache_model("sprites/wall_puff1.spr")
		g_index_shell=precache_model("models/shotgunshell.mdl")
		g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_iExplode3=precache_model("sprites/csobc/ef_shockwave.spr")
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
		RegisterHam(Ham_TraceAttack, "player", "ham_traceattack_post",1)
		RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack_post",1)
		RegisterHam(Ham_TraceAttack, "func_breakable", "ham_traceattack_post",1)
		g_msgWeaponList=get_user_msgid("WeaponList")
		g_iszWeaponKey=engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_itemid=zp_items_register(WEAPON_NAME,WEAPON_COST)
		decal_index = fm_get_decal_index("{gaussshot1")
		register_think("azaaza","ololo")
}
public clcmd_weapon(id)engclient_cmd(id, g_weapon_entity)
public message_weaponlist(msg_id,msg_dest,id)if(get_msg_arg_int(8)==CSW_BALROG7)for(new i=2;i<=9;i++)g_wpn_variables[i]=get_msg_arg_int(i)
public fm_cmdstart(id,uc_handle,seed){
	if(!is_user_alive(id))return
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	if(!is_valid_weapon(weapon_ent)) return
	if((get_uc(uc_handle,UC_Buttons)&IN_ATTACK2)&&get_pdata_float(weapon_ent,46,4)<=0.0){
		if(get_pdata_int(weapon_ent, 74, 4) & JANUS_READY){
			set_weaponlist(id,2)
			play_weapon_animation(id, ANIM_CHANGE)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)|JANUS_MODE, 4)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)&~JANUS_READY, 4)
			set_pdata_float(id,83,1.0,5)
			set_pdata_float(weapon_ent, 48, 1.5, 4)
			set_pdata_float(weapon_ent, 47, 6.0, 4)
			set_crosshair(id)
		}
	}
}
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
	if(get_pdata_int(weapon_ent, 74, 4) & JANUS_MODE) play_weapon_animation(id, 9)
	else play_weapon_animation(id, get_pdata_int(weapon_ent, 74, 4) & JANUS_READY?16:ANIM_DRAW)
	if((get_pdata_int(weapon_ent, 74, 4) & JANUS_READY))set_crosshair(id,1)
	set_pdata_float(id, 83, 0.5, 5)
	set_pdata_float(weapon_ent, 48, 1.4, 4)
	set_pdata_int(weapon_ent, 55, 0, 4)
}
public ham_item_holster_post(weapon_ent){
	if(!is_valid_weapon(weapon_ent))return
	static id;id=get_pdata_cbase(weapon_ent,41,4)
	set_crosshair(id)
}
public ham_weapon_primaryattack(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	new Float:Time, Clip=get_pdata_int(weapon_entity, 51, 4)
	Time=get_pdata_float(weapon_entity, 47, 4)
	if(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE){
		set_pdata_int(weapon_entity, 51, 1, 4)
		ExecuteHam(Ham_Weapon_PrimaryAttack, weapon_entity)
		set_pdata_float(weapon_entity, 47, Time, 4)
		emit_sound(id, CHAN_WEAPON, SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		play_weapon_animation(id, ANIM_SHOOT_2)
		set_pdata_float(weapon_entity,46,RATE_OF_FIRE-0.2,4)
		set_pdata_float(weapon_entity, 48, RATE_OF_FIRE+0.2, 4)
		set_pdata_int(weapon_entity, 51, Clip, 4)
	}else{
		static clip;clip=get_pdata_int(weapon_entity,51,4)
		ExecuteHam(Ham_Weapon_PrimaryAttack, weapon_entity)
		set_pdata_float(weapon_entity, 47, Time, 4)
		if(clip<=get_pdata_int(weapon_entity,51,4))return HAM_IGNORED
		if(g_iHits[id]>=SHOTS_MODE){
			g_iHits[id]=0
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)|JANUS_READY, 4)
			set_pdata_float(weapon_entity, 47, 10.0, 4)
			set_crosshair(id,1)
		}
		emit_sound(id, CHAN_WEAPON, SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		play_weapon_animation(id, (get_pdata_int(weapon_entity, 74, 4) & JANUS_READY)?ANIM_SHOOT_1R:ANIM_SHOOT_1)
		set_pdata_float(weapon_entity,46,RATE_OF_FIRE,4)
		set_pdata_float(weapon_entity, 48, RATE_OF_FIRE+0.2, 4)
	}
	set_pdata_int(weapon_entity,57,g_index_shell,4) 
        set_pdata_float(id,111,get_gametime()+0.3)
        set_pdata_int(weapon_entity, 55, 0, 4)
	return HAM_SUPERCEDE
}
public ham_weapon_reload(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity,41,4)
	static bpammo;bpammo=get_pdata_int(id,376+get_pdata_int(weapon_entity,49,4),5)
	static clip;clip=get_pdata_int(weapon_entity,51,4)
	if(!bpammo||clip==CLIP||(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE))return HAM_SUPERCEDE
	//ExecuteHam(Ham_Weapon_Reload,weapon_entity)
	Reload(id, weapon_entity)
	return HAM_SUPERCEDE
}
public ham_weapon_idle(ent) {
	if(!is_valid_weapon(ent))return HAM_IGNORED
	static id; id = get_pdata_cbase(ent, 41, 4)

	if(get_pdata_float(ent, 48, 4)>0.0)return HAM_IGNORED
	if(get_pdata_int(ent, 55, 4)){
		if(get_pdata_int(ent, 55, 4)==1) Reload(id, ent) 
		return HAM_IGNORED
	}else if(get_pdata_int(ent, 74, 4) & JANUS_MODE){
		play_weapon_animation(id, ANIM_IDLE_MODE)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}else if(get_pdata_int(ent, 74, 4) & JANUS_READY){
		play_weapon_animation(id, ANIM_IDLE_READY)
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
	static bpammo;bpammo=get_pdata_int(id,376+get_pdata_int(weapon_entity,49,4),5)
	static clip;clip=get_pdata_int(weapon_entity,51,4)
	if(clip==8&&bpammo&&get_pdata_float(weapon_entity, 48, 4)<=0.0&&get_pdata_int(weapon_entity, 55, 4)) Reload(id, weapon_entity)
	if(get_pdata_float(weapon_entity, 47, 4)<=0.0){
		if(get_pdata_int(weapon_entity, 74, 4)&JANUS_READY){
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_READY, 4)
			ham_weapon_idle(weapon_entity)
			set_crosshair(id)
		}else if(get_pdata_int(weapon_entity, 74, 4)&JANUS_MODE){
			set_weaponlist(id,1)
			play_weapon_animation(id, ANIM_CHANGE_EX)
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_MODE, 4)
			set_pdata_float(id,83,1.3,5)
			set_pdata_float(weapon_entity, 48, 1.5, 4)
		}
	}
}
public ham_item_addtoplayer(weapon_entity,id)if(is_valid_weapon(weapon_entity))set_weaponlist(id,1)
public ham_traceattack_post(pEntity,attacker,Float:flDamage,Float:direction[3],ptr,damage_type) {
	if(!is_user_connected(attacker)||!(damage_type&DMG_BULLET))return
	static weapon_entity;weapon_entity=get_pdata_cbase(attacker, 373, 5)
	if(!is_valid_weapon(weapon_entity))return
	new Float:vecEnd[3],Float:vecPlane[3]
	get_tr2(ptr,TR_vecEndPos,vecEnd)
	get_tr2(ptr,TR_vecPlaneNormal,vecPlane)
	xs_vec_mul_scalar(vecPlane,5.0,vecPlane)
	if(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE){
		new Float:orig[3]
		get_weapon_position(attacker, orig, .add_forward=32.0, .add_right=8.0, .add_up=-5.0)
		set_beam(orig, vecEnd, .Amplitude = 0, .Width = 150.0, .Scrollrate = 0.0, .Brigthness = 255.0, .Color = Float:{ 200.0, 0.0, 0.0 })
		set_beam(orig, vecEnd, .Amplitude = 0, .Width = 70.0, .Scrollrate = 0.0, .Brigthness = 200.0, .Color = Float:{ 200.0, 200.0, 0.0 })
	}
	if(is_user_alive(pEntity))g_iHits[attacker]++
        if(!is_user_alive(pEntity)){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord,vecEnd[0])
		engfunc(EngFunc_WriteCoord,vecEnd[1])
		engfunc(EngFunc_WriteCoord,vecEnd[2])
		write_short(pEntity)
		write_byte((get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE)?decal_index:random_num(41,45))
		message_end()
		xs_vec_add(vecEnd,vecPlane,vecEnd)
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord,vecEnd[0])
		engfunc(EngFunc_WriteCoord,vecEnd[1])
		engfunc(EngFunc_WriteCoord,vecEnd[2]-10.0)
		write_short(g_index_smoke)
		write_byte(3)
		write_byte(50)
		write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)
		message_end()
	}
}
public zp_fw_items_select_post(id,itemid) {
	if(itemid!=g_itemid)return
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
}
public plugin_natives()
	register_native("zp_give_item_janus11", "zp_give_item_janus11", 1);
public zp_give_item_janus11(id)
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
enum _:Coord_e { Float:x, Float:y, Float:z }
stock set_beam(const Float:Origin[Coord_e],const Float:End[Coord_e],const Amplitude,const Float:Width,const Float:Scrollrate,const Float:Brigthness,const Float:Color[Coord_e]){
	new Beam = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"))
	set_pev(Beam, pev_flags, pev(Beam, pev_flags)|FL_CUSTOMENTITY)
        set_pev(Beam, pev_model, "sprites/ef_shockwave.spr")
        set_pev(Beam, pev_modelindex, g_iExplode3)
        set_pev(Beam, pev_body, Amplitude)
        set_pev(Beam, pev_scale, Width)
        set_pev(Beam, pev_animtime, Scrollrate)
        set_pev(Beam, pev_renderamt, Brigthness)
        set_pev(Beam, pev_rendercolor, Color)
        set_pev(Beam, pev_rendermode, 0&0x0F)
        set_pev(Beam, pev_origin, End)
        set_pev(Beam, pev_angles, Origin)
        static Float:Mins[Coord_e]
        static Float:Maxs[Coord_e]
        Mins[ x ] = floatmin( End[ x ], Origin[ x ] ) - End[ x ]
        Mins[ y ] = floatmin( End[ y ], Origin[ y ] ) - End[ y ]
        Mins[ z ] = floatmin( End[ z ], Origin[ z ] ) - End[ z ]
        Maxs[ x ] = floatmax( End[ x ], Origin[ x ] ) - End[ x ]
        Maxs[ y ] = floatmax( End[ y ], Origin[ y ] ) - End[ y ]
        Maxs[ z ] = floatmax( End[ z ], Origin[ z ] ) - End[ z ]
        engfunc(EngFunc_SetSize, Beam, Mins, Maxs)
        engfunc(EngFunc_SetOrigin, Beam, End)
        set_pev(Beam, pev_classname, "azaaza")
        entity_set_float(Beam, EV_FL_nextthink, get_gametime())
}
public ololo(Beam) {
	new Float:lel
	pev(Beam,pev_renderamt,lel),lel-=20.0,set_pev(Beam,pev_renderamt,lel)
	if(lel<=0.0)engfunc(EngFunc_RemoveEntity,Beam)
	else entity_set_float(Beam,EV_FL_nextthink,get_gametime()+0.025)
}
public Reload(id, ent){	
	static bpammo;bpammo=get_pdata_int(id, 376 + get_pdata_int(ent, 49, 4), 5)
	static clip;clip=get_pdata_int(ent, 51, 4)
	switch(get_pdata_int(ent, 55, 4)){
		case 0:{
			play_weapon_animation(id, (get_pdata_int(ent, 74, 4) & JANUS_READY)?14:5)
			set_pdata_int(ent, 55, 1, 4)	
			set_pdata_float(id, 83, 0.55, 5)
			set_pdata_float(ent, 48, 0.55, 4)
		}
		case 1:{
			if(get_pdata_float(ent, 48, 4)>0.0)return
			if(clip>=CLIP||!bpammo){		
				play_weapon_animation(id, (get_pdata_int(ent, 74, 4) & JANUS_READY)?13:4)
				set_pdata_int(ent, 55, 0, 4)
				set_pdata_float(ent, 48, 0.9, 4)
				return
			}
			play_weapon_animation(id, (get_pdata_int(ent, 74, 4) & JANUS_READY)?12:3)
			set_pdata_int(ent, 55, 2, 4)
			set_pdata_float(ent, 48, 0.45, 4)
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

stock set_crosshair(id, ready=0){
if(ready) client_cmd(id,"cl_crosshair_color ^"200 25 200^"")
else client_cmd(id,"cl_crosshair_color ^"0 200 0^"")
}
forward damage_pre(id)
native damage_set(id, Float:dmg)
public damage_pre(attacker)
{
	static weapon_ent; weapon_ent=get_pdata_cbase(attacker,373,5)
	if(is_valid_weapon(weapon_ent)) {
		damage_set(attacker, DAMAGE)
		return 1
	}
	return 0
}