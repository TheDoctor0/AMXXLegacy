#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <zp50_items>

#define MIN -10.0
#define MAX 10.0

#define RADIUS 290.0
#define DAMAGE 2.0
#define V_MODEL "models/zombie_plague/v_grenade_fire.mdl"

#define CRAZY_CODE 5646489

#define WEAPON_NAME		"Behemoth Grenade"
#define WEAPON_COST		0

new gMsgScreenShake , g_iHookedDeathMsg, gMsgScreenFade, behemoth[33], grenadetrail, g_exploSpr, sExplo, g_itemid
public plugin_init()
{
	register_plugin("Behemoth Grenade" , "1.6" , "maTT_hArdy")
	register_cvar("behemot", "hardy", FCVAR_SERVER|FCVAR_SPONLY)
	register_forward(FM_SetModel, "fw_SetModel")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Item_Deploy,"weapon_hegrenade", "fw_Item_Deploy_Post", 1)
	RegisterHam( Ham_Killed, "player", "player_dead" )
	gMsgScreenShake = get_user_msgid("ScreenShake");
	gMsgScreenFade = get_user_msgid("ScreenFade");
	g_itemid=zp_items_register(WEAPON_NAME,WEAPON_COST)
}

public plugin_precache()
{
	grenadetrail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_exploSpr = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr")
	sExplo = precache_model("sprites/zombiebomb.spr")
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheSound, "zombi_bomb_exp.wav")
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(weapon_ent)
	if (!pev_valid(id))
		return
	
	if(!behemoth[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL)
}

public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	if(pev(entity, pev_iuser2) != CRAZY_CODE) return HAM_IGNORED;
	
	new Float:dmgtime;
	pev(entity,pev_dmgtime,dmgtime);
	if(dmgtime > get_gametime()) return HAM_IGNORED;
	
	fire_explode(entity)
	return HAM_SUPERCEDE;
}

public MsgDeathMsg( ) {
	set_msg_arg_int( 3, ARG_BYTE, 0 );
	set_msg_arg_string( 4, "grenade" );
	
	return PLUGIN_CONTINUE;
}

fire_explode(ent)
{
	// Get origin
	static Float:originF[3], Owner
	pev(ent, pev_origin, originF)
	Owner = pev(ent, pev_owner)
	// Make the explosion
	create_blast2(originF)
	
	// Fire nade explode sound
	emit_sound(ent, CHAN_WEAPON, "zombi_bomb_exp.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static Float:PlayerOrigin[3]
	static Float:distance
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(!is_user_connected(Owner))
			continue
		if(!get_cvar_num("mp_friendlyfire") && cs_get_user_team(i) == cs_get_user_team(Owner) && i != Owner)
			continue
		pev(i, pev_origin, PlayerOrigin)
		distance = get_distance_f(originF, PlayerOrigin)
		if(distance > RADIUS)
			continue
				
		new Float:pengurang = distance / RADIUS
		new Float:pengurang2 = 1.0 - pengurang
		new Float:flDamage = 100.0 * pengurang2
		new Float:flDamage_final = flDamage + (flDamage * DAMAGE)
		
		playerlight(i)
		crazy2(i)
		set_task(0.5,"crazy",i+231687,"",0,"a",20)
		
		g_iHookedDeathMsg = register_message( get_user_msgid("DeathMsg"), "MsgDeathMsg" );
		
		ExecuteHamB( Ham_TakeDamage, i, ent, Owner, flDamage_final, DMG_GENERIC );
		
		if( g_iHookedDeathMsg )
		{
			unregister_message( get_user_msgid("DeathMsg"), g_iHookedDeathMsg );
			
			g_iHookedDeathMsg = 0;
		}
	}
	
	// Get rid of the grenade
	set_pev(ent, pev_iuser2, 0)
	engfunc(EngFunc_RemoveEntity, ent)
}

public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;
	
	if (model[9] == 'h' && model[10] == 'e' && behemoth[pev(entity, pev_owner)]) // Napalm Grenade
	{
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, 244, 251, 105, kRenderNormal, 16);
		
		set_pev(entity, pev_iuser2, CRAZY_CODE)
		behemoth[pev(entity, pev_owner)] = 0
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(grenadetrail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(244) // r
		write_byte(251) // g
		write_byte(105) // b
		write_byte(200) // brightness
		message_end()
	}
}

public zp_fw_items_select_post(id,itemid) 
{
	if(itemid!=g_itemid)
	return
	
	fm_give_item( id, "weapon_hegrenade" )
	behemoth[id] = 1
}

public crazy(taskid)
{
	new id = taskid - 231687
	
	new Float:fVec[3];
	fVec[0] = random_float(MIN , MAX);
	fVec[1] = random_float(MIN , MAX);
	fVec[2] = random_float(MIN , MAX);
	entity_set_vector(id , EV_VEC_punchangle , fVec);
	message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,id)
	write_short( 1<<14 );
	write_short( 1<<14 );
	write_short( 1<<14 );
	message_end();

	message_begin(MSG_ONE_UNRELIABLE , gMsgScreenFade , {0,0,0} , id);
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( 1<<12 );
	write_byte( random_num(0,255) );
	write_byte( random_num(0,255) );
	write_byte( random_num(0,255) );
	write_byte( 95 );
	message_end();
}

public crazy2(id)
{
	new Float:fVec[3];
	fVec[0] = random_float(MIN , MAX);
	fVec[1] = random_float(MIN , MAX);
	fVec[2] = random_float(MIN , MAX);
	entity_set_vector(id , EV_VEC_punchangle , fVec);
	message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,id)
	write_short( 1<<14 );
	write_short( 1<<14 );
	write_short( 1<<14 );
	message_end();

	message_begin(MSG_ONE_UNRELIABLE , gMsgScreenFade , {0,0,0} , id);
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( 1<<12 );
	write_byte( random_num(0,255) );
	write_byte( random_num(0,255) );
	write_byte( random_num(0,255) );
	write_byte( 95 );
	message_end();
}

public playerlight(id)
{
	if (!is_user_alive(id)) return;
	
	// create glow shell
	set_normal(id)
	set_normal(id, kRenderFxGlowShell, 244, 251, 105, kRenderNormal, 0)
	if (task_exists(id+56213)) remove_task(id+56213)
	set_task(10.0, "RemoveGlowShell", id+56213)
}

public Event_NewRound()
{
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(task_exists(i+56213))
		{
			remove_task(i+56213)
			set_normal(i)
		}
		if(task_exists(i+231687)) remove_task(i+231687)
		
	}
}

public player_dead(id)
{
	if(task_exists(id+56213))
	{
		remove_task(id+56213)
		set_normal(id)
	}
	if(task_exists(id+231687)) remove_task(id+231687)
}

public RemoveGlowShell(taskid)
{
	new id = taskid - 56213
	set_normal(id)
	
	if(task_exists(taskid)) remove_task(taskid)
}

create_blast2(const Float:originF[3])
{
	static TE_FLAG
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	TE_FLAG |= 4
	TE_FLAG |= 8
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2]+30)
	write_short(sExplo)
	write_byte(50)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()
}

stock set_normal(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != 2)
		return -1
	
	return get_pdata_cbase(ent, 41, 4)
}