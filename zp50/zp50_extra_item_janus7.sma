//=========================================================================
#define CSW_BALROG7		CSW_M249
new const g_weapon_entity[]=	"weapon_m249"
new const g_weaponbox_model[]=	"models/w_m249.mdl"

#define WEAPON_NAME		"Janus-7"
#define WEAPON_COST		0

#define SHOTS_MODE		70
#define DAMAGE			40.0
#define DAMAGE_EX		random_float(80.0, 120.0)
#define RECOIL			0.5
#define RATE_OF_FIRE		0.12
#define CLIP			120
#define AMMO			200
#define TIME_RELOAD		4.0
#define ANIM_SHOOT_1		3
#define ANIM_SHOOT_1R		5
#define ANIM_SHOOT_2		9
#define ANIM_RELOAD		1
#define ANIM_DRAW		2

#define ANIM_CHANGE 6
#define ANIM_CHANGE_EX 11

#define ANIM_IDLE_READY 12
#define ANIM_IDLE_MODE 7

#define BODY_NUMBER		0
new const MODELS[][]={
				"models/csobc/v_janus7.mdl",
				"models/csobc/p_janus7.mdl",
				"models/csobc/w_janus7.mdl"
}
new const SOUNDS[][]= {
				"weapons/janus7-1.wav",
				"weapons/janus7-2.wav",
				"weapons/janus7_change1.wav",
				"weapons/janus7_change2.wav",
				"weapons/mg3_clipin.wav",
				"weapons/mg3_clipout.wav",
				"weapons/mg3_close.wav",
				"weapons/mg3_open.wav"
}
#define WEAPONLIST		"csobc_janus7"
new const SPRITES[][]=	{
				"sprites/csobc/640hud7.spr",
				"sprites/csobc/640hud99.spr"
}
#define SPRITE_SHOCK		"sprites/csobc/setrum_lagi2.spr"
//=========================================================================
#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>
native zp_tattoo_get(id)
new g_msgWeaponList,g_itemid,g_wpn_variables[10],g_iszWeaponKey,g_index_smoke,g_index_shell,g_iExplode3, Float:flSoundTime[33],g_iHits[33]
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
		g_index_shell=precache_model("models/rshell.mdl")
		g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_iExplode3=precache_model("sprites/csobc/lgtning.spr")
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
		RegisterHam(Ham_RemovePlayerItem, "player", "ham_player_removeitem")
		RegisterHam(Ham_TraceAttack, "player", "ham_traceattack_post",1)
		RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack_post",1)
		RegisterHam(Ham_TraceAttack, "func_breakable", "ham_traceattack_post",1)
		g_msgWeaponList=get_user_msgid("WeaponList")
		g_iszWeaponKey=engfunc(EngFunc_AllocString, WEAPON_NAME)
		g_itemid=zp_items_register(WEAPON_NAME,WEAPON_COST)
		register_think("janus7_beam","ololo")
		register_think("janus7_explo","olelele")
}
public clcmd_weapon(id)engclient_cmd(id, g_weapon_entity)
public message_weaponlist(msg_id,msg_dest,id)if(get_msg_arg_int(8)==CSW_BALROG7)for(new i=2;i<=9;i++)g_wpn_variables[i]=get_msg_arg_int(i)
public fm_cmdstart(id,uc_handle,seed){
	if(!is_user_alive(id))return
	static weapon_ent;weapon_ent=get_pdata_cbase(id,373,5)
	if(!is_valid_weapon(weapon_ent)) return
	if((get_uc(uc_handle,UC_Buttons)&IN_ATTACK2)&&get_pdata_float(id,83,5)<=0.0){
		if(get_pdata_int(weapon_ent, 74, 4) & JANUS_READY){
			set_weaponlist(id,2)
			play_weapon_animation(id, ANIM_CHANGE)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)|JANUS_MODE, 4)
			set_pdata_int(weapon_ent, 74, get_pdata_int(weapon_ent, 74, 4)&~JANUS_READY, 4)
			set_pdata_float(id,83,1.5,5)
			set_pdata_float(weapon_ent, 48, 2.0, 4)
			set_pdata_float(weapon_ent, 47, 12.0, 4)
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
	if(!is_valid_weapon(weapon_ent)) return
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
	if(get_pdata_int(weapon_ent, 74, 4) & JANUS_MODE) play_weapon_animation(id, 8)
	else play_weapon_animation(id, get_pdata_int(weapon_ent, 74, 4) & JANUS_READY?14:ANIM_DRAW)
	if((get_pdata_int(weapon_ent, 74, 4) & JANUS_READY)||(get_pdata_int(weapon_ent, 74, 4) & JANUS_MODE))client_cmd(id,"cl_crosshair_color ^"200 25 200^"")
	set_pdata_float(id, 83, 0.5, 5)
	set_pdata_float(weapon_ent, 48, 1.4, 4)
}
public ham_item_holster_post(weapon_ent){
	if(!is_valid_weapon(weapon_ent))return
	static id;id=get_pdata_cbase(weapon_ent,41,4)
	client_cmd(id,"cl_crosshair_color ^"0 200 0^"")
	emit_sound(id, CHAN_WEAPON, SOUNDS[1], 0.0, ATTN_NORM, 0, PITCH_NORM), flSoundTime[id]=get_gametime()
}
public ham_weapon_primaryattack(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity, 41, 4)
	if(get_pdata_int(weapon_entity, 64, 4)==0) set_pev(id, pev_enemy, 0)
	if(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE){
		find_targ(id)
		if(flSoundTime[id]<=get_gametime()){
			emit_sound(id, CHAN_WEAPON, SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			flSoundTime[id]=get_gametime()+3.0
		}
		play_weapon_animation(id, ANIM_SHOOT_2)
		set_pdata_float(weapon_entity,46,RATE_OF_FIRE,4)
		set_pdata_float(weapon_entity, 48, RATE_OF_FIRE+0.8, 4)
		new Float:orig[3], Float:flAngle[3], Float:vecEnd[3]	
		engfunc(EngFunc_GetAttachment, id, 1, orig, flAngle)
		fm_get_aim_origin(id, vecEnd)
		set_beam(id,orig, vecEnd, .Amplitude = 20, .Width = 50.0, .Scrollrate = 1.0, .Brigthness = 250.0, .Color = Float:{ 250.0, 250.0, 0.0 })
	}else{
		new Float:Time=get_pdata_float(weapon_entity, 47, 4)
		static clip;clip=get_pdata_int(weapon_entity,51,4)
		ExecuteHam(Ham_Weapon_PrimaryAttack, weapon_entity)
		set_pdata_float(weapon_entity, 47, Time, 4)
		if(clip<=get_pdata_int(weapon_entity,51,4))return HAM_IGNORED
		if(g_iHits[id]>=SHOTS_MODE){
			g_iHits[id]=0
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)|JANUS_READY, 4)
			set_pdata_float(weapon_entity, 47, 10.0, 4)
			client_cmd(id,"cl_crosshair_color ^"200 25 200^"")
		}
		emit_sound(id, CHAN_WEAPON, SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		play_weapon_animation(id, (get_pdata_int(weapon_entity, 74, 4) & JANUS_READY)?ANIM_SHOOT_1R:ANIM_SHOOT_1)
		set_pdata_float(weapon_entity,46,RATE_OF_FIRE,4)
		set_pdata_float(weapon_entity, 48, RATE_OF_FIRE+0.8, 4)
		set_pdata_int(weapon_entity, 64,get_pdata_int(weapon_entity, 64, 4)+1,4)
		set_pdata_int(weapon_entity,57,g_index_shell,4) 
	        set_pdata_float(id,111,get_gametime())
	        set_pdata_float(weapon_entity,62,RECOIL,4)
	}
	return HAM_SUPERCEDE
}
public ham_weapon_reload(weapon_entity) {
	if(!is_valid_weapon(weapon_entity))return HAM_IGNORED
	static id; id = get_pdata_cbase(weapon_entity,41,4)
	static bpammo;bpammo=get_pdata_int(id,376+get_pdata_int(weapon_entity,49,4),5)
	static clip;clip=get_pdata_int(weapon_entity,51,4)
	if(!bpammo||clip==CLIP||(get_pdata_int(weapon_entity, 74, 4) & JANUS_MODE))return HAM_SUPERCEDE
	ExecuteHam(Ham_Weapon_Reload,weapon_entity)
	play_weapon_animation(id,(get_pdata_int(weapon_entity, 74, 4) & JANUS_READY)?13:ANIM_RELOAD)
	set_pdata_int(id,363,90,5)
	set_pdata_float(id,83,TIME_RELOAD,5)
	set_pdata_int(weapon_entity,54,1,4)
	return HAM_SUPERCEDE
}
public ham_weapon_idle(ent) {
	if(!is_valid_weapon(ent))return HAM_IGNORED
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(get_pdata_float(ent, 48, 4)>0.0)return HAM_IGNORED
	if(flSoundTime[id]>get_gametime())emit_sound(id, CHAN_WEAPON, SOUNDS[1], 0.0, ATTN_NORM, 0, PITCH_NORM), flSoundTime[id]=get_gametime()
	if(get_pdata_int(ent, 74, 4) & JANUS_MODE){
		play_weapon_animation(id, ANIM_IDLE_MODE)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}else if(get_pdata_int(ent, 74, 4) & JANUS_READY){
		play_weapon_animation(id, ANIM_IDLE_READY)
		set_pdata_float(ent, 48, 5.0, 4)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
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
	if(get_pdata_float(weapon_entity, 47, 4)<=0.0){
		if(get_pdata_int(weapon_entity, 74, 4)&JANUS_READY){
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_READY, 4)
			set_pdata_float(weapon_entity, 48, 0.1, 4)
			client_cmd(id,"cl_crosshair_color ^"0 200 0^"")
		}else if(get_pdata_int(weapon_entity, 74, 4)&JANUS_MODE){
			client_cmd(id,"cl_crosshair_color ^"0 200 0^"")
			set_weaponlist(id,1)
			play_weapon_animation(id, ANIM_CHANGE_EX)
			set_pdata_int(weapon_entity, 74, get_pdata_int(weapon_entity, 74, 4)&~JANUS_MODE, 4)
			set_pdata_float(id,83,1.5,5)
			set_pdata_float(weapon_entity, 46, 1.5, 4)
			set_pdata_float(weapon_entity, 48, 1.5, 4)
			emit_sound(id, CHAN_WEAPON, SOUNDS[1], 0.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
}
public ham_item_addtoplayer(weapon_entity,id)if(is_valid_weapon(weapon_entity))set_weaponlist(id,1)
public ham_player_removeitem(id,weapon_entity) if(is_valid_weapon(weapon_entity)) emit_sound(id, CHAN_WEAPON, SOUNDS[1], 0.0, ATTN_NORM, 0, PITCH_NORM)
public ham_traceattack_post(pEntity,attacker,Float:flDamage,Float:direction[3],ptr,damage_type) {
	if(!is_user_connected(attacker)||!(damage_type&DMG_BULLET))return
	static weapon_entity;weapon_entity=get_pdata_cbase(attacker, 373, 5)
	if(!is_valid_weapon(weapon_entity))return
	new Float:vecEnd[3],Float:vecPlane[3]
	get_tr2(ptr,TR_vecEndPos,vecEnd)
	get_tr2(ptr,TR_vecPlaneNormal,vecPlane)
	xs_vec_mul_scalar(vecPlane,5.0,vecPlane)
        if(!is_user_alive(pEntity)){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord,vecEnd[0])
		engfunc(EngFunc_WriteCoord,vecEnd[1])
		engfunc(EngFunc_WriteCoord,vecEnd[2])
		write_short(pEntity)
		write_byte(random_num(41,45))
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
	else g_iHits[attacker]++
}
public zp_fw_items_select_post(id,itemid) {
	if(itemid!=g_itemid)return
	new Ent=give_weapon(id)
	set_pdata_int(id,376+get_pdata_int(Ent,49,4),AMMO,5)
}
public plugin_natives()
	register_native("zp_give_item_janus7", "zp_give_item_janus7", 1);
public zp_give_item_janus7(id)
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
stock set_beam(id,const Float:Origin[Coord_e],const Float:End[Coord_e],const Amplitude,const Float:Width,const Float:Scrollrate,const Float:Brigthness,const Float:Color[Coord_e]){
	new Beam = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"))
	set_pev(Beam, pev_flags, pev(Beam, pev_flags)|FL_CUSTOMENTITY)
        set_pev(Beam, pev_model, "sprites/Janus_7_aq13/lgtning.spr")
        set_pev(Beam, pev_modelindex, g_iExplode3)
        set_pev(Beam, pev_body, Amplitude)
        set_pev(Beam, pev_scale, Width)
        set_pev(Beam, pev_animtime, Scrollrate)
        set_pev(Beam, pev_renderamt, Brigthness)
        set_pev(Beam, pev_rendercolor, Color)
        set_pev(Beam, pev_rendermode,1&0x0F) 
        if(pev(id, pev_enemy)) pev(pev(id, pev_enemy), pev_origin, End)
        
        set_pev(Beam, pev_origin, End)
        set_pev(Beam, pev_skin, id | 0x1000)
	set_pev(Beam, pev_aiment, id)
	set_pev(Beam, pev_owner, 6)

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
        set_pev(Beam, pev_classname, "janus7_beam")
        entity_set_float(Beam, EV_FL_nextthink, get_gametime())
}
public ololo(Beam) {
	static iPlayer;iPlayer=pev(Beam, pev_aiment)
	static Float:vecOrigin[3]
	if(!pev(iPlayer, pev_enemy)){
	static i, Float:vecUp[3],Float:vecRight[3],Float:vecForward[3],Float:vecViewOfs[3]
	pev(iPlayer, pev_v_angle, vecOrigin)
	engfunc(EngFunc_MakeVectors, vecOrigin)
	pev(iPlayer, pev_origin, vecOrigin)
	pev(iPlayer, pev_view_ofs, vecViewOfs)
	global_get(glb_v_up, vecUp)
	global_get(glb_v_right, vecRight)
	global_get(glb_v_forward, vecForward)
	for (i=0;i<3;i++) vecOrigin[i]=vecOrigin[i]+vecViewOfs[i]+vecForward[i]*300.0+vecUp[i]+vecRight[i]
	}
	else pev(pev(iPlayer, pev_enemy), pev_origin, vecOrigin)
	
	set_pev(Beam, pev_origin, vecOrigin)
	new lel=pev(Beam,pev_owner)
	lel-=1,set_pev(Beam,pev_owner,lel)
	if(lel<=0)engfunc(EngFunc_RemoveEntity,Beam)
	else entity_set_float(Beam,EV_FL_nextthink,get_gametime()+0.025)
}
public find_targ(id){
	static target;target=pev(id, pev_enemy)
	if(target){
		static origin1[3], origin2[3]
		get_user_origin(id, origin1)
		get_user_origin(target, origin2)
		if(!is_user_connected(target)||get_distance(origin1, origin2)>300||!is_user_alive(target)||!zp_core_is_zombie(target))set_pev(id, pev_enemy, 0)
		else{
			ExecuteHamB(Ham_TakeDamage, target, id, id, DAMAGE_EX, DMG_BULLET|DMG_NEVERGIB)
			create_spr(target)
			return
		}
	}
	new victim=FM_NULLENT,Float:Origin[3]
	pev(id, pev_origin, Origin)
	while((victim=fm_find_ent_in_sphere(victim, Origin, 300.0))!=0 && !pev(id, pev_enemy)){
		if(is_user_connected(victim)&&is_user_alive(victim)&&zp_core_is_zombie(victim)){
			set_pev(id, pev_enemy, victim)
		}
	}
	if(pev(id, pev_enemy))ExecuteHamB(Ham_TakeDamage, pev(id, pev_enemy), id, id, DAMAGE_EX, DMG_BULLET|DMG_NEVERGIB), create_spr(pev(id, pev_enemy))
}
new Ent[33], Float:CampoColors[3] = {200.0,200.0,0.0}
public create_spr(id){
	if(Ent[id]) return
	Ent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	entity_set_model(Ent[id], SPRITE_SHOCK)  
	set_pev(Ent[id], pev_aiment, id)
	set_pev(Ent[id], pev_movetype, MOVETYPE_FOLLOW)
	set_pev(Ent[id], pev_spawnflags, SF_SPRITE_ONCE)
	entity_set_int(Ent[id], EV_INT_rendermode, kRenderTransAdd)
	entity_set_float(Ent[id], EV_FL_renderamt, 255.0)
	entity_set_vector(Ent[id], EV_VEC_rendercolor, CampoColors)
	entity_set_float(Ent[id], EV_FL_scale, 0.5)
	DispatchSpawn(Ent[id])
	set_pev(Ent[id], pev_classname, "janus7_explo")
	entity_set_float(Ent[id],EV_FL_nextthink,get_gametime()+0.1)
}
public olelele(ent){
	new id=pev(ent, pev_aiment)
	static Float:Frm
	pev(ent, pev_frame, Frm)
	Frm+=1.0
	set_pev(ent, pev_frame, Frm)
	if(Frm>=3.0)engfunc(EngFunc_RemoveEntity,ent), Ent[id]=0
	else entity_set_float(Ent[id],EV_FL_nextthink,get_gametime()+0.1)
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