#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>

#define PLUGIN "[ZP] Revenant Boss"
#define VERSION "1.3"
#define AUTHOR "Dias & O'Zone"

#define TASK_STARTING 3000
#define TASK_REMOVE_REVENANT 3003
#define TASK_BURNING 3016
#define TASK_EVOLUTION 3017
#define TASK_RECHECK 3018
#define TASK_CREATE 3019
#define TASK_MUSIC 3020
#define TASK_SKILL 3021
#define TASK_RESPAWN 3022

// Skill: FireStorm
#define TASK_MAKE_AURA 3010
#define TASK_MAKE_STORM 3011
#define TASK_STOP_STORM 3012
#define TASK_RESET_STORM 3013
#define TASK_SET_MINI_FIREBALL 3014
#define TASK_REMOVE_MINI_FIREBALL 3015
// End of Skill: FireStorm

// Skill:Circle Fire
#define TASK_DOING_CIRCLE_FIRE 3008
#define TASK_RESET_CIRCLE_FIRE 3009
new g_time_doing
#define EXPLOSION_RADIUS 250.0
#define EXPLOSION_DAMAGE 50.0

// Skill: Mahadash
#define TASK_DOING_MAHADASH 3006
#define TASK_STOP_MAHADASH 3007
#define MAHADASH_DAMAGE 200.0
new g_mahadashing
// End Of Skill: Mahadash

// Skill: Attack1 
#define TASK_REVENANT_ATTACK 3004
#define TASK_REVENANT_ATTACK_RELOAD 3005
#define ATTACK1_DAMAGE 70.0
// End of Skill: Attack1

// Skill: Fireball
#define TASK_FIREBALL1 3001
#define TASK_FIREBALL2 3002
#define FIREBALL_DAMAGE 50.0
#define FIREBALL_RADIUS 150.0

#define TASK_MAPEVENT 8954
#define REVENANT_TASK 7431
#define REVENANT_CREATE_TASK 6598
#define TASK_CREATE_REVENANT 5464

new g_fireball1_count, g_fireball2_count, g_fireball12_count, g_fireball22_count
new Float:fireball_origin1[3], Float:fireball_origin2[3], Float:fireball_origin12[3], Float:fireball_origin22[3]
// End of Skill: Fireball

#define boss_classname 	"boss_revenant"

new const RevenantResource[][] = {
	"models/zp/boss/boss_revenant.mdl",		// 0
	"sprites/zp/boss/revenant_healthbar.spr",	// 1
	"models/zp/boss/fireball.mdl",	  // 2
	"sprites/zp/boss/flame2.spr",	// 3
	"models/zp/boss/package.mdl",		// 4
	"sprites/blood.spr",	// 5
	"sprites/bloodspray.spr",	// 6
	"sprites/zerogxplode.spr"	// 7
}

static g_RevenantResource[sizeof RevenantResource]

new const g_RevenantSound[][] = {
	"zp/boss/revenant_zbs_death.wav",
	"zp/boss/revenant_fireball_explode.wav",
	"zp/boss/revenant_zbs_attack1.wav",
	"zp/boss/revenant_zbs_attack4.wav",
	"zp/boss/revenant_zbs_attack5.wav",
	"zp/boss/revenant_zbs_fireball1.wav",
	"zp/boss/revenant_zbs_fireball2.wav",
	"zp/boss/revenant_scene_appear.wav",
	"zp/boss/roundclear.wav",
	"zp/boss/roundfail.wav",
	"zp/boss/package_get.wav"
}

new const g_MapSound[][] = {
	"sound/zp/boss/Scenario_Ready.mp3",
	"sound/zp/boss/Scenario_Rush.mp3"
}

new Float:g_RevenantOrigin[3], g_fire_ent[5], g_ent, g_reg, g_doing_skill, g_evolution, g_healthbar, g_timer, bool:g_revenant_death

new const FILE_SETTING[] = "zp_boss_revenant.ini"
new boss_heal, boss_health, prepare_time, best_exp, gift_min_ap, gift_max_ap, gift_min_exp, gift_max_exp

new Float:Damage_Taken[33]
new bool:Gift_Taken[33]
new bool:Gift_Message[33]

native zp_register_boss(const name[], const map[]);
native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)
native zp_add_user_exp(id, amount)

new const BossName[] = "Revenant";
new const BossMap[] = "zp_boss_revenant";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Killed, "player", "player_killed");
	RegisterHam(Ham_Killed, "info_target", "revenant_death");
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_logevent("event_roundstart", 2, "1=Round_Start")
	register_logevent("event_roundend", 2, "1=Round_End")
	
	register_think(boss_classname, "fw_revenant_think")
	register_touch(boss_classname, "*", "fw_revenant_touch")
	
	register_forward(FM_Touch, "TouchPackage");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	
	register_think("revenant_fireball", "fw_fireball_think")
	register_touch("revenant_fireball", "*", "fw_fireball_touch")
	register_think("fireball_flame", "fw_flame_think")
	
	zp_register_boss(BossName, BossMap)
	
	set_task(1.0, "MapEvent", TASK_MAPEVENT, .flags="b");
}

public plugin_cfg()
	config_load()

public plugin_precache()
{
	new szMapName[32];
	get_mapname(szMapName, 31);
	if(!(equal(szMapName, BossMap)))
		set_task(0.5, "PauseBoss");
	else
	{
		for (new i = 0; i < sizeof (RevenantResource); i++)
			g_RevenantResource[i] = precache_model(RevenantResource[i])
		for(new i = 0; i < sizeof(g_RevenantSound); i++)
			precache_sound(g_RevenantSound[i])
		for(new i = 0; i < sizeof(g_MapSound); i++)
			precache_generic(g_MapSound[i])	
	
		g_RevenantOrigin[0] = -48.8
		g_RevenantOrigin[1] = 26.8
		g_RevenantOrigin[2] = 2000.0
	}
}

public PauseBoss()
	pause("ad")
	
public MapEvent() 
{
	if(!get_player_alive()) 
		return
	else
	{
		remove_task(TASK_MAPEVENT);
		set_task(1.0, "spawn_revenant", TASK_CREATE_REVENANT);
		log_to_file("addons/amxmodx/logs/revenant.log", "Boss Map Event");
		return
	}
}

public spawn_revenant()
{	
	set_task(1.0, "count_start", REVENANT_TASK)
	g_timer = prepare_time
	
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Prepare");
	
	set_task(float(prepare_time), "create_revenant", REVENANT_CREATE_TASK);
}

public count_start(task)
{
	g_timer--
	
	if(g_timer > 0)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.30, 1, 5.0, 5.0)
		show_hudmessage(0, "Revenant pojawi sie za %d sekund", g_timer)
		//client_print(0, print_center, "Revenant pojawi sie za %d sekund", g_timer)
	}
	
	if(g_timer < 11)
		client_cmd(0, "spk zp/boss/vox/%d", g_timer)
	
	if(g_timer >= 0)
		set_task(1.0, "count_start", REVENANT_TASK)
		
	if(g_timer == 0)
		client_print_color(0, print_team_red, "^x03[BOSS]^x01 Pamietajcie, aby trzymac Bossa jak najblizej srodka mapy! Powodzenia!")
}

public event_newround()
{	
	// Play ready sound
	client_cmd(0, "mp3 play %s", g_MapSound[0])
}

public event_roundstart()
{
	// Play ready sound
	client_cmd(0, "mp3 play %s", g_MapSound[1])	

	set_task(180.0, "replay_music", TASK_MUSIC)
}

public event_roundend()
{
	client_cmd(0, "stopsound")	
	remove_task(TASK_MUSIC)
}

public replay_music()
{
	// Play ready sound
	client_cmd(0, "mp3 play %s", g_MapSound[1])	
	set_task(180.0, "replay_music", TASK_MUSIC)
}

public fw_PlayerPreThink(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T) 
		cs_set_user_team(id, CS_TEAM_CT)
}

// ================== FireStorm =======================
public do_firestorm(ent)
{
	if(!pev_valid(ent) || g_doing_skill)
		return	
	
	g_doing_skill = 1
	set_entity_anim(ent, 12)
	
	static Float:Origin[3]
	get_position(ent, 150.0, 0.0, 50.0, Origin)
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	make_mini_fireball(ent, Origin)
	
	set_task(0.1, "make_aura", ent+TASK_MAKE_AURA, _, _, "b")
	set_task(4.0, "do_storm", ent+TASK_MAKE_STORM)
	set_task(10.0, "stop_storm", ent+TASK_STOP_STORM)
}

public make_mini_fireball(boss, Float:Origin[3])
{
	new ent = create_entity("info_target")

	static Float:Angles[3]
	pev(boss, pev_angles, Angles)
	
	entity_set_origin(ent, Origin)
	
	Angles[0] = 100.0
	entity_set_vector(ent, EV_VEC_angles, Angles)
	
	Angles[0] = -100.0
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	
	entity_set_string(ent, EV_SZ_classname, "revenant_fireball")
	entity_set_model(ent, RevenantResource[2])
	entity_set_int(ent, EV_INT_solid, 2)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	
	new Float:maxs[3] = {15.0, 15.0, 15.0}
	new Float:mins[3] = {-15.0, -15.0, -15.0}
	entity_set_size(ent, mins, maxs)
	set_pev(ent, pev_owner, boss)
	
	set_task(0.01, "set_mini_fireball", ent+TASK_SET_MINI_FIREBALL)
	set_task(3.0, "remove_mini_fireball", ent+TASK_REMOVE_MINI_FIREBALL)
	
	make_fire(ent, 0.5)
}

public set_mini_fireball(ent)
{
	ent -= TASK_SET_MINI_FIREBALL
	
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3]
	get_position(ent, 2.0, 0.0, 2.0, Origin)
	
	set_pev(ent, pev_origin, Origin)
	
	set_task(0.01, "set_mini_fireball", ent+TASK_SET_MINI_FIREBALL)
}

public remove_mini_fireball(ent)
{
	ent -= TASK_REMOVE_MINI_FIREBALL
	
	if(!pev_valid(ent))
		return
		
	remove_entity(ent)
}

public do_storm(ent)
{
	ent -= TASK_MAKE_STORM
	
	if(!pev_valid(ent))
		return
		
	static Float:Explosion_Origin[24][3], Float:Real_Origin[24][3]	
	
	// Plus
	Explosion_Origin[0][0] = 200.0
	Explosion_Origin[0][1] = 0.0
	Explosion_Origin[0][2] = 500.0
	
	Explosion_Origin[1][0] = 400.0
	Explosion_Origin[1][1] = 0.0
	Explosion_Origin[1][2] = 500.0
	
	Explosion_Origin[2][0] = -200.0
	Explosion_Origin[2][1] = 0.0
	Explosion_Origin[2][2] = 500.0
	
	Explosion_Origin[3][0] = -400.0
	Explosion_Origin[3][1] = 0.0
	Explosion_Origin[3][2] = 500.0
	
	Explosion_Origin[4][0] = 0.0
	Explosion_Origin[4][1] = 200.0
	Explosion_Origin[4][2] = 500.0
	
	Explosion_Origin[5][0] = 0.0
	Explosion_Origin[5][1] = 400.0
	Explosion_Origin[5][2] = 500.0
	
	Explosion_Origin[6][0] = 0.0
	Explosion_Origin[6][1] = -200.0
	Explosion_Origin[6][2] = 500.0
	
	Explosion_Origin[7][0] = 0.0
	Explosion_Origin[7][1] = -400.0
	Explosion_Origin[7][2] = 500.0
	
	// Other 1
	Explosion_Origin[8][0] = 200.0
	Explosion_Origin[8][1] = 200.0
	Explosion_Origin[8][2] = 500.0
	
	Explosion_Origin[9][0] = 400.0
	Explosion_Origin[9][1] = 400.0
	Explosion_Origin[9][2] = 500.0
	
	Explosion_Origin[10][0] = 200.0
	Explosion_Origin[10][1] = 400.0
	Explosion_Origin[10][2] = 500.0
	
	Explosion_Origin[11][0] = 400.0
	Explosion_Origin[11][1] = 200.0
	Explosion_Origin[11][2] = 500.0
	
	// Other 2	
	Explosion_Origin[12][0] = -200.0
	Explosion_Origin[12][1] = 200.0
	Explosion_Origin[12][2] = 500.0
	
	Explosion_Origin[13][0] = -400.0
	Explosion_Origin[13][1] = 400.0
	Explosion_Origin[13][2] = 500.0
	
	Explosion_Origin[14][0] = -200.0
	Explosion_Origin[14][1] = 400.0
	Explosion_Origin[14][2] = 500.0
	
	Explosion_Origin[15][0] = -400.0
	Explosion_Origin[15][1] = 200.0
	Explosion_Origin[15][2] = 500.0
	
	// Other 3
	Explosion_Origin[16][0] = -200.0
	Explosion_Origin[16][1] = -200.0
	Explosion_Origin[17][2] = 500.0
	
	Explosion_Origin[17][0] = -200.0
	Explosion_Origin[17][1] = -200.0
	Explosion_Origin[17][2] = 500.0
	
	Explosion_Origin[18][0] = -200.0
	Explosion_Origin[18][1] = -400.0
	Explosion_Origin[18][2] = 500.0
	
	Explosion_Origin[19][0] = -400.0
	Explosion_Origin[19][1] = -200.0
	Explosion_Origin[19][2] = 500.0
	
	// Other 4
	Explosion_Origin[20][0] = 200.0
	Explosion_Origin[20][1] = -200.0
	Explosion_Origin[20][2] = 500.0
	
	Explosion_Origin[21][0] = 400.0
	Explosion_Origin[21][1] = -400.0
	Explosion_Origin[21][2] = 500.0
	
	Explosion_Origin[22][0] = 200.0
	Explosion_Origin[22][1] = -400.0
	Explosion_Origin[22][2] = 500.0
	
	Explosion_Origin[23][0] = 400.0
	Explosion_Origin[23][1] = -200.0
	Explosion_Origin[23][2] = 500.0
	
	for(new i = 0; i < sizeof(Explosion_Origin); i++)
	{
		get_position(ent, Explosion_Origin[i][0], Explosion_Origin[i][1], Explosion_Origin[i][2], Real_Origin[i])
		make_fireball2(ent, Real_Origin[i])
	}

	remove_task(ent+TASK_MAKE_AURA)
	set_task(1.0, "do_storm", ent+TASK_MAKE_STORM)
}

public make_fireball2(boss, Float:Origin[3])
{
	new ent = create_entity("info_target")

	static Float:Angles[3]
	pev(boss, pev_angles, Angles)
	
	entity_set_origin(ent, Origin)
	
	Angles[0] = -100.0
	entity_set_vector(ent, EV_VEC_angles, Angles)
	
	Angles[0] = 100.0
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	
	entity_set_string(ent, EV_SZ_classname, "revenant_fireball")
	entity_set_model(ent, RevenantResource[2])
	entity_set_int(ent, EV_INT_solid, 2)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	
	new Float:maxs[3] = {15.0, 15.0, 15.0}
	new Float:mins[3] = {-15.0, -15.0, -15.0}
	entity_set_size(ent, mins, maxs)
	set_pev(ent, pev_owner, boss)
	
	static Float:Velocity[3]
	VelocityByAim(ent, random_num(250, 1000), Velocity)
	
	set_pev(ent, pev_light_level, 180)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)	
	
	entity_set_vector(ent, EV_VEC_velocity, Velocity)

	make_fire(ent, 0.5)
}

public fw_fireball2_touch(ent, id)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_RevenantResource[7])	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()	
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= FIREBALL_RADIUS)
		{
			shake_screen(i)
			ExecuteHam(Ham_TakeDamage, i, 0, i, FIREBALL_DAMAGE, DMG_BURN)
		}
	}
	
	remove_entity(ent)
}

public stop_storm(ent)
{
	ent -= TASK_STOP_STORM
	
	if(!pev_valid(ent))
		return	
	
	remove_task(ent+TASK_MAKE_AURA)
	remove_task(ent+TASK_MAKE_STORM)
	
	set_task(2.0, "reset_storm", ent+TASK_RESET_STORM)
}

public reset_storm(ent)
{
	ent -= TASK_RESET_STORM
	
	set_entity_anim(ent, 2)
	
	g_doing_skill = 0
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.0)
}

public make_aura(ent)
{
	ent -= TASK_MAKE_AURA
	
	if(!pev_valid(ent))
	{
		remove_task(ent+TASK_MAKE_AURA)
		return
	}
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(27)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(500)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(10)
	write_byte(60)
	message_end()	
}
// ================== End Of FireStorm =======================

// ================== Circle Fire =======================
public do_circle_fire(ent)
{
	if(!pev_valid(ent) || g_doing_skill)
		return	
	
	g_doing_skill = 1
	g_time_doing = 3
	set_entity_anim(ent, 11)
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(0.25, "do_explosion", ent+TASK_DOING_CIRCLE_FIRE)
	set_task(0.5, "do_explosion", ent+TASK_DOING_CIRCLE_FIRE)
	set_task(0.75, "do_explosion", ent+TASK_DOING_CIRCLE_FIRE)
	
	set_task(2.0, "reset_circle_explosion", ent+TASK_RESET_CIRCLE_FIRE)
}

public reset_circle_explosion(ent)
{
	ent -= TASK_RESET_CIRCLE_FIRE
	
	g_doing_skill = 0
	g_time_doing = 0	
	
	set_entity_anim(ent, 2)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)
}

public do_explosion(ent)
{
	ent -= TASK_DOING_CIRCLE_FIRE
	
	if(!is_valid_ent(ent))
		return;
	
	static Float:Explosion_Origin[8][3], Float:Real_Origin[8][3]
	
	if(g_time_doing == 3)
	{
		Explosion_Origin[0][0] = 100.0
		Explosion_Origin[0][1] = 0.0
		Explosion_Origin[0][2] = 0.0
		
		Explosion_Origin[1][0] = 50.0
		Explosion_Origin[1][1] = 50.0
		Explosion_Origin[1][2] = 0.0
		
		Explosion_Origin[2][0] = 0.0
		Explosion_Origin[2][1] = 100.0
		Explosion_Origin[2][2] = 0.0
		
		Explosion_Origin[3][0] = -50.0
		Explosion_Origin[3][1] = -100.0
		Explosion_Origin[3][2] = 0.0
		
		Explosion_Origin[4][0] = -100.0
		Explosion_Origin[4][1] = 0.0
		Explosion_Origin[4][2] = 0.0
		
		Explosion_Origin[5][0] = -50.0
		Explosion_Origin[5][1] = -50.0
		Explosion_Origin[5][2] = 0.0
		
		Explosion_Origin[6][0] = 0.0
		Explosion_Origin[6][1] = -50.0
		Explosion_Origin[6][2] = 0.0
		
		Explosion_Origin[7][0] = 50.0
		Explosion_Origin[7][1] = -50.0
		Explosion_Origin[7][2] = 0.0
	} else if(g_time_doing == 2) {
		Explosion_Origin[0][0] = 200.0
		Explosion_Origin[0][1] = 0.0
		Explosion_Origin[0][2] = 0.0
		
		Explosion_Origin[1][0] = 100.0
		Explosion_Origin[1][1] = 100.0
		Explosion_Origin[1][2] = 0.0
		
		Explosion_Origin[2][0] = 0.0
		Explosion_Origin[2][1] = 200.0
		Explosion_Origin[2][2] = 0.0
		
		Explosion_Origin[3][0] = -100.0
		Explosion_Origin[3][1] = -200.0
		Explosion_Origin[3][2] = 0.0
		
		Explosion_Origin[4][0] = -200.0
		Explosion_Origin[4][1] = 0.0
		Explosion_Origin[4][2] = 0.0
		
		Explosion_Origin[5][0] = -100.0
		Explosion_Origin[5][1] = -100.0
		Explosion_Origin[5][2] = 0.0
		
		Explosion_Origin[6][0] = 0.0
		Explosion_Origin[6][1] = -100.0
		Explosion_Origin[6][2] = 0.0
		
		Explosion_Origin[7][0] = 100.0
		Explosion_Origin[7][1] = -100.0
		Explosion_Origin[7][2] = 0.0			
	} else if(g_time_doing == 1) {
		Explosion_Origin[0][0] = 300.0
		Explosion_Origin[0][1] = 0.0
		Explosion_Origin[0][2] = 0.0
		
		Explosion_Origin[1][0] = 150.0
		Explosion_Origin[1][1] = 150.0
		Explosion_Origin[1][2] = 0.0
		
		Explosion_Origin[2][0] = 0.0
		Explosion_Origin[2][1] = 300.0
		Explosion_Origin[2][2] = 0.0
		
		Explosion_Origin[3][0] = -150.0
		Explosion_Origin[3][1] = -300.0
		Explosion_Origin[3][2] = 0.0
		
		Explosion_Origin[4][0] = -300.0
		Explosion_Origin[4][1] = 0.0
		Explosion_Origin[4][2] = 0.0
		
		Explosion_Origin[5][0] = -150.0
		Explosion_Origin[5][1] = -150.0
		Explosion_Origin[5][2] = 0.0
		
		Explosion_Origin[6][0] = 0.0
		Explosion_Origin[6][1] = -150.0
		Explosion_Origin[6][2] = 0.0
		
		Explosion_Origin[7][0] = 150.0
		Explosion_Origin[7][1] = -150.0
		Explosion_Origin[7][2] = 0.0		
	}
	
	for(new i = 0; i < sizeof(Explosion_Origin); i++)
	{
		get_position(ent, Explosion_Origin[i][0], Explosion_Origin[i][1], Explosion_Origin[i][2], Real_Origin[i])
		make_explosion(ent, Real_Origin[i])
	}	

	g_time_doing--
}

public make_explosion(ent, Float:Origin[3])
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_RevenantResource[7])	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()	
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i))
		{
			static Float:Origin2[3], Float:distance
			pev(i, pev_origin, Origin2)
			
			distance = get_distance_f(Origin, Origin2)
			
			if(distance <= EXPLOSION_RADIUS)
			{
				shake_screen(i)
				ExecuteHam(Ham_TakeDamage, i, 0, i, EXPLOSION_DAMAGE, DMG_BURN)
				
				static Float:Velocity[3]
				Velocity[0] = random_float(250.0, 750.0)
				Velocity[1] = random_float(250.0, 750.0)
				Velocity[2] = random_float(250.0, 750.0)
				
				set_pev(i, pev_velocity, Velocity)
			}
		}
	}
}
// ================== End of Circle Fire =======================

// ================== Madadash =======================
public do_mahadash(ent)
{
	if(!pev_valid(ent) || g_doing_skill)
		return	
	
	g_doing_skill = 1
	g_mahadashing = 0
	
	set_entity_anim(ent, 5)
	set_task(1.5, "mahadash_now", ent+TASK_DOING_MAHADASH)
	set_task(2.0, "stop_mahadash", ent+TASK_STOP_MAHADASH)
}

public mahadash_now(ent)
{
	ent -= TASK_DOING_MAHADASH
	
	if(!pev_valid(ent))
		return
		
	g_mahadashing = 1
	set_entity_anim(ent, 6)
	
	static Float:Origin[3]
	get_position(ent, 1000.0, 0.0, 0.0, Origin)
	
	hook_ent2(ent, Origin, 2000.0)
}

public fw_revenant_touch(ent, id)
{
	if(!pev_valid(id))
		return
	if(!g_mahadashing)
		return

	g_mahadashing = 0
	
	remove_task(ent+TASK_STOP_MAHADASH)
	set_task(0.1, "stop_mahadash", ent+TASK_STOP_MAHADASH)
	
	if(is_user_alive(id))
	{
		ExecuteHam(Ham_TakeDamage, id, 0, id, MAHADASH_DAMAGE, DMG_SLASH)
		shake_screen(id)
		
		static Float:Velocity[3]
		Velocity[0] = random_float(1000.0, 2000.0)
		Velocity[1] = random_float(1000.0, 2000.0)
		Velocity[2] = random_float(1000.0, 2000.0)
		
		set_pev(id, pev_velocity, Velocity)
	}
}

public stop_mahadash(ent)
{
	ent -= TASK_STOP_MAHADASH
	
	g_mahadashing = 0
	g_doing_skill = 1
	set_entity_anim(ent, 7)
	
	set_task(0.5, "reset_mahadash", ent)
}

public reset_mahadash(ent)
{
	g_doing_skill = 0
	set_entity_anim(ent, 2)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)
}

// ================== Make FireBall ===================
public do_fireball(ent)
{
	if(!pev_valid(ent) || g_doing_skill)
		return
	
	stop_fireball(ent)
	g_doing_skill = 1
	
	static random_mode
	random_mode = random_num(0, 1)
	
	switch(random_mode)
	{
		case 0: {
			set_entity_anim(ent, 9)
			set_task(1.0, "throw_fireball", g_ent+TASK_FIREBALL1)	
			emit_sound(ent, CHAN_BODY, g_RevenantSound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		case 1: {
			set_entity_anim(ent, 10)
			set_task(1.0, "throw_fireball2", g_ent+TASK_FIREBALL1)		
			emit_sound(ent, CHAN_BODY, g_RevenantSound[6], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
}

public stop_fireball(ent)
{
	g_doing_skill = 0
	
	remove_task(ent+TASK_FIREBALL1)
	remove_task(ent+TASK_FIREBALL2)
	remove_entity_name("revenant_fireball")
}

public throw_fireball(ent)
{
	ent -= TASK_FIREBALL1
	
	if(!is_valid_ent(ent))
		return;
		
	static Float:Origin[3], fireball_left, fireball_right
	
	// Fireball Left
	fireball_origin2[0] = 0.0
	fireball_origin2[1] = 0.0
	fireball_origin2[2] = 0.0		
	
	get_position(ent, 50.0, -25.0, 100.0, Origin)
	fireball_left = make_fireball(ent, Origin)	
	g_fireball2_count = 50
	set_pev(fireball_left, pev_iuser4, 2)
	set_pev(fireball_left, pev_nextthink, get_gametime() + 0.3)	
	
	// Fireball Right
	fireball_origin1[0] = 0.0
	fireball_origin1[1] = 0.0
	fireball_origin1[2] = 0.0	
	
	get_position(ent, 50.0, 50.0, 100.0, Origin)	
	fireball_right = make_fireball(ent, Origin)
	g_fireball1_count = 50
	set_pev(fireball_right, pev_iuser4, 1)
	set_pev(fireball_right, pev_nextthink, get_gametime() + 0.4)
	
	set_task(1.5, "restart_skill", ent+TASK_FIREBALL2)
}

public throw_fireball2(ent)
{
	ent -= TASK_FIREBALL1
	
	if(!is_valid_ent(ent))
		return;
		
	static Float:Origin[3], fireball_left, fireball_right
	
	// Fireball Left
	fireball_origin2[0] = 0.0
	fireball_origin2[1] = 0.0
	fireball_origin2[2] = 0.0		
	
	get_position(ent, 50.0, -25.0, 100.0, Origin)
	fireball_left = make_fireball(ent, Origin)	
	g_fireball2_count = 50
	set_pev(fireball_left, pev_iuser4, 2)
	set_pev(fireball_left, pev_nextthink, get_gametime() + 0.1)	
	
	// Fireball Right
	fireball_origin1[0] = 0.0
	fireball_origin1[1] = 0.0
	fireball_origin1[2] = 0.0	
	
	get_position(ent, 50.0, 50.0, 100.0, Origin)	
	fireball_right = make_fireball(ent, Origin)
	g_fireball1_count = 50
	set_pev(fireball_right, pev_iuser4, 1)
	set_pev(fireball_right, pev_nextthink, get_gametime() + 0.2)
	
	set_task(0.5, "throw_fireball2_2", ent)
	set_task(2.0, "restart_skill", ent+TASK_FIREBALL2)
}

public throw_fireball2_2(ent)
{
	if(!is_valid_ent(ent))
		return;
		
	static Float:Origin[3], fireball_left, fireball_right
	
	// Fireball Left
	fireball_origin22[0] = 0.0
	fireball_origin22[1] = 0.0
	fireball_origin22[2] = 0.0		
	
	get_position(ent, 50.0, -25.0, 100.0, Origin)
	fireball_left = make_fireball(ent, Origin)	
	g_fireball22_count = 50
	set_pev(fireball_left, pev_iuser4, 4)
	set_pev(fireball_left, pev_nextthink, get_gametime() + 0.1)	
	
	// Fireball Right
	fireball_origin12[0] = 0.0
	fireball_origin12[1] = 0.0
	fireball_origin12[2] = 0.0	
	
	get_position(ent, 50.0, 50.0, 100.0, Origin)	
	fireball_right = make_fireball(ent, Origin)
	g_fireball12_count = 50
	set_pev(fireball_right, pev_iuser4, 3)
	set_pev(fireball_right, pev_nextthink, get_gametime() + 0.2)	
}

public restart_skill(ent)
{
	ent -= TASK_FIREBALL2
	
	if(!is_valid_ent(ent)) 
		return; 
	
	g_doing_skill = 0
	set_pev(ent, pev_nextthink, get_gametime() + 1.0)
}

public make_fireball(boss, Float:Origin[3])
{
	new ent = create_entity("info_target")

	entity_set_origin(ent, Origin)
	
	entity_set_string(ent, EV_SZ_classname, "revenant_fireball")
	entity_set_model(ent, RevenantResource[2])
	entity_set_int(ent, EV_INT_solid, 0)
	entity_set_int(ent, EV_INT_movetype, 0)
	
	new Float:maxs[3] = {15.0, 15.0, 15.0}
	new Float:mins[3] = {-15.0, -15.0, -15.0}
	entity_set_size(ent, mins, maxs)
	set_pev(ent, pev_owner, boss)

	set_pev(ent, pev_light_level, 180)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)
	
	make_fire(ent, 0.5)
	
	return ent
}

public make_fire(fireball, Float:size)
{
	static ent
	ent = create_entity("env_sprite")
	
	set_pev(ent, pev_takedamage, 0.0)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_classname, "fireball_flame")
	
	engfunc(EngFunc_SetModel, ent, RevenantResource[3])
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_light_level, 180)
	
	set_pev(ent, pev_scale, size)
	set_pev(ent, pev_owner, fireball)
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 8.0)
	set_pev(ent, pev_frame, 0.1)
	set_pev(ent, pev_spawnflags, SF_SPRITE_STARTON)

	dllfunc(DLLFunc_Spawn, ent)

	fw_flame_think(ent)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01)
	
	return ent
}

public fw_flame_think(ent)
{
	if(!pev_valid(ent))
		return
		
	if(!pev_valid(pev(ent, pev_owner)))
	{
		remove_entity(ent)
		return
	}
	
	static owner
	owner = pev(ent, pev_owner)
	
	static Float:Origin[3]
	pev(owner, pev_origin, Origin)
	
	Origin[2] += 25.0
	entity_set_origin(ent, Origin)

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01)
}

public fw_fireball_think(ent) // Fireball Right
{
	if(!pev_valid(ent))
		return
	
	// 1st Time
	if(g_fireball1_count > 0 && pev(ent, pev_iuser4) == 1)
	{	
		static Float:Origin[3]
			
		switch(g_fireball1_count)
		{
			case 35..40: {
				fireball_origin1[2] += 0.5
				get_position(ent, fireball_origin1[0], fireball_origin1[1], fireball_origin1[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 20..34: {
				fireball_origin1[0] += 0.1
				fireball_origin1[1] += 0.25				
				get_position(ent, fireball_origin1[0], fireball_origin1[1], fireball_origin1[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 5..19: {
				fireball_origin1[2] -= 0.5
				fireball_origin1[1] -= 0.5
				fireball_origin1[0] -= 0.1
				get_position(ent, fireball_origin1[0], fireball_origin1[1], fireball_origin1[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}
			case 4: {
				static owner, Float:Velocity[3]
				owner = pev(ent, pev_owner)
	
				get_position(owner, 1000.0, 0.0, -100.0, Velocity)
				fm_get_aim_origin(owner, Velocity)
				//Velocity[2] -= 20.0
				
				entity_set_int(ent, EV_INT_solid, 2)
				set_pev(ent, pev_movetype, MOVETYPE_FLY)
				hook_ent2(ent, Velocity, random_float(2000.0, 4000.0))
					
				g_fireball1_count = 0
			}
		}
		
		if(g_fireball1_count > 0)
		g_fireball1_count--
	}
	
	if(g_fireball2_count > 0 && pev(ent, pev_iuser4) == 2)
	{	
		static Float:Origin[3]
			
		switch(g_fireball2_count)
		{
			case 35..40: {
				fireball_origin2[2] += 0.5
				get_position(ent, fireball_origin2[0], fireball_origin2[1], fireball_origin2[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 20..34: {
				fireball_origin2[0] -= 0.1
				fireball_origin2[1] += 0.25	
				get_position(ent, fireball_origin2[0], fireball_origin2[1], fireball_origin2[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 5..19: {
				fireball_origin2[2] -= 0.5
				fireball_origin2[1] -= 0.5
				fireball_origin2[0] += 0.1
				get_position(ent, fireball_origin2[0], fireball_origin2[1], fireball_origin2[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}
			case 4: {
				static owner, Float:Velocity[3]
				owner = pev(ent, pev_owner)
	
				get_position(owner, 1000.0, 0.0, -100.0, Velocity)
				fm_get_aim_origin(owner, Velocity)
				//Velocity[2] -= 20.0
				
				entity_set_int(ent, EV_INT_solid, 2)
				set_pev(ent, pev_movetype, MOVETYPE_FLY)
				hook_ent2(ent, Velocity, random_float(2000.0, 4000.0))
					
				g_fireball2_count = 0
			}
		}
		
		if(g_fireball2_count > 0)
		g_fireball2_count--
	}	
	
	// 2nd Time
	if(g_fireball12_count > 0 && pev(ent, pev_iuser4) == 3)
	{	
		static Float:Origin[3]
			
		switch(g_fireball12_count)
		{
			case 35..40: {
				fireball_origin12[2] += 0.5
				get_position(ent, fireball_origin12[0], fireball_origin12[1], fireball_origin12[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 20..34: {
				fireball_origin12[0] += 0.1
				fireball_origin12[1] += 0.25				
				get_position(ent, fireball_origin12[0], fireball_origin12[1], fireball_origin12[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 5..19: {
				fireball_origin12[2] -= 0.5
				fireball_origin12[1] -= 0.5
				fireball_origin12[0] -= 0.1
				get_position(ent, fireball_origin12[0], fireball_origin12[1], fireball_origin12[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}
			case 4: {
				static owner, Float:Velocity[3]
				owner = pev(ent, pev_owner)
	
				get_position(owner, 1000.0, 0.0, -100.0, Velocity)
				fm_get_aim_origin(owner, Velocity)
				//Velocity[2] -= 20.0
				
				entity_set_int(ent, EV_INT_solid, 2)
				set_pev(ent, pev_movetype, MOVETYPE_FLY)
				hook_ent2(ent, Velocity, 2000.0)
					
				g_fireball1_count = 0
			}
		}
		
		if(g_fireball12_count > 0)
		g_fireball12_count--
	}
	
	if(g_fireball22_count > 0 && pev(ent, pev_iuser4) == 4)
	{	
		static Float:Origin[3]
			
		switch(g_fireball22_count)
		{
			case 35..40: {
				fireball_origin22[2] += 0.5
				get_position(ent, fireball_origin22[0], fireball_origin22[1], fireball_origin22[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 20..34: {
				fireball_origin2[0] -= 0.1
				fireball_origin2[1] += 0.25	
				get_position(ent, fireball_origin22[0], fireball_origin22[1], fireball_origin22[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)	
			}	
			case 5..19: {
				fireball_origin22[2] -= 0.5
				fireball_origin22[1] -= 0.5
				fireball_origin22[0] += 0.1
				get_position(ent, fireball_origin22[0], fireball_origin22[1], fireball_origin22[2], Origin)
				set_pev(ent, pev_origin, Origin)
				
				static owner
				owner = pev(ent, pev_owner)
				
				if(pev_valid(owner))
					turn_to_victim(owner)					
			}
			case 4: {
				static owner, Float:Velocity[3]
				owner = pev(ent, pev_owner)
	
				get_position(owner, 1000.0, 0.0, -100.0, Velocity)
				fm_get_aim_origin(owner, Velocity)
				//Velocity[2] -= 20.0
				
				entity_set_int(ent, EV_INT_solid, 2)
				set_pev(ent, pev_movetype, MOVETYPE_FLY)
				hook_ent2(ent, Velocity, 2000.0)
					
				g_fireball22_count = 0
			}
		}
		
		if(g_fireball22_count > 0)
		g_fireball22_count--
	}		
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}

public turn_to_victim(ent)
{
	static victim
	victim = pev(ent, pev_iuser4)
	
	if(!is_user_alive(victim))
		return
	
	new Float:Ent_Origin[3], Float:Vic_Origin[3]
	pev(ent, pev_origin, Ent_Origin)
	pev(victim, pev_origin, Vic_Origin)
	
	npc_turntotarget(ent, Ent_Origin, victim, Vic_Origin)		
}

public fw_fireball_touch(ent, id)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_RevenantResource[7])	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()	
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= FIREBALL_RADIUS)
		{
			shake_screen(i)
			ExecuteHam(Ham_TakeDamage, i, 0, i, FIREBALL_DAMAGE, DMG_BURN)
		}
	}
	
	remove_entity(ent)
}
// ================== End of Make FireBall ===================

public create_revenant()
{
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Create");
	
	new ent = create_entity("info_target")
	g_ent = ent
	
	static Float:Origin[3]
	Origin[0] = g_RevenantOrigin[0]
	Origin[1] = g_RevenantOrigin[1]
	Origin[2] = g_RevenantOrigin[2]
	
	entity_set_origin(ent, Origin)
	
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_health, float(PlayerHp(boss_heal)) + 1000.0)
	
	entity_set_string(ent, EV_SZ_classname, boss_classname)
	entity_set_model(ent, RevenantResource[0])
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
	
	new Float:maxs[3] = {25.0, 50.0, 200.0}
	new Float:mins[3] = {-25.0, -50.0, -35.0}
	entity_set_size(ent, mins, maxs)
	entity_set_int(ent, EV_INT_modelindex, g_RevenantResource[0])
	
	set_entity_anim(ent, 1)
	set_task(4.0, "set_start_revenant", ent+TASK_STARTING)
	
	if(!g_reg)
	{
		g_reg = 1
		RegisterHamFromEntity(Ham_TakeDamage, ent, "revenant_takedamage", 1)
	}
	
	g_mahadashing = 0
	g_time_doing = 0
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[7], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Make g_healthbar
	g_healthbar = create_entity("env_sprite")
	
	set_pev(g_healthbar, pev_scale, 1.0)
	set_pev(g_healthbar, pev_owner, ent)
	engfunc(EngFunc_SetModel, g_healthbar, RevenantResource[1])	
	
	set_task(0.1, "recheck_boss", ent+TASK_RECHECK, _, _, "b")
	set_task(random_float(7.0, 15.0), "do_skill_now", TASK_SKILL)
	
	drop_to_floor(ent)
}

public do_skill_now()
{
	static ent
	ent = g_ent
	
	if(!pev_valid(ent))
		return
		
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Skill Prepare");
	
	static victim
	victim = pev(ent, pev_iuser4)
	
	set_task(random_float(5.0, 15.0), "do_skill_now", TASK_SKILL)
	
	if(!is_user_alive(victim))
		return
		
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Skill Start");
		
	static random_skill

	if(g_evolution)
	{
		random_skill = random_num(0, 3)		
		
		switch(random_skill)
		{
			case 0: do_fireball(ent)
			case 1: do_circle_fire(ent)
			case 2: do_mahadash(ent)
			case 3: do_firestorm(ent)
		}
	} else {
		random_skill = random_num(0, 3)	
		
		switch(random_skill)
		{
			case 0: do_fireball(ent)
			case 1: do_circle_fire(ent)
			case 2: do_mahadash(ent)
		}	
	}
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Skill End");
}

public recheck_boss(ent)
{
	ent -= TASK_RECHECK
	
	if(!pev_valid(ent))
	{
		remove_task(ent+TASK_RECHECK)
		return
	}
	
	static Float:Origin[3], Float:revenant_health
	pev(ent, pev_origin, Origin)
							
	Origin[2] += 250.0	
	engfunc(EngFunc_SetOrigin, g_healthbar, Origin)
	
	pev(ent, pev_health, revenant_health)
	
	if(boss_health < (revenant_health - 1000.0))
	{
		set_pev(g_healthbar, pev_frame, 99.0)
	}
	else
	{
		set_pev(g_healthbar, pev_frame, 0.0 + ((((revenant_health - 1000.0) - 1 ) * 100) / boss_health))
	}		
}

public set_start_revenant(ent)
{
	ent -= TASK_STARTING
	
	set_entity_anim(ent, 2)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)
}

public fw_revenant_think(ent)
{
	if(pev(ent, pev_iuser3))
		return
	if(pev(ent, pev_health) - 1000.0 < 0.0)
	{
		set_pev(ent, pev_iuser3, 1)
		return
	}
	
	if(!g_evolution && (pev(ent, pev_health) - 1000.0) <= (boss_health / 2) && !g_doing_skill)
	{
		log_to_file("addons/amxmodx/logs/revenant.log", "Boss Skill Evolution");
		
		g_evolution = 1
		g_doing_skill = 1
		
		do_evolution(ent)
		
		return
	}
	
	if(!g_doing_skill)
	{
		log_to_file("addons/amxmodx/logs/revenant.log", "Boss Run Start");
		static victim
		static Float:Origin[3], Float:VicOrigin[3], Float:distance
		
		victim = FindClosesEnemy(ent)
		pev(ent, pev_origin, Origin)
		pev(victim, pev_origin, VicOrigin)
		
		distance = get_distance_f(Origin, VicOrigin)
		
		if(is_user_alive(victim))
		{
			if(distance <= 250.0)
			{
				do_attack1(ent)
				entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.5)
			} else {
				if(pev(ent, pev_sequence) != 4)
					set_entity_anim(ent, 4)
					
				new Float:Ent_Origin[3], Float:Vic_Origin[3]
				
				pev(ent, pev_origin, Ent_Origin)
				pev(victim, pev_origin, Vic_Origin)
				
				npc_turntotarget(ent, Ent_Origin, victim, Vic_Origin)
				hook_ent(ent, victim, 200.0)

				if(pev(ent, pev_iuser4) != victim)
					set_pev(ent, pev_iuser4, victim)
				
				entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)
			}
		} else {
			if(pev(ent, pev_sequence) != 2)
				set_entity_anim(ent, 2)
				
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)
		}	
		log_to_file("addons/amxmodx/logs/revenant.log", "Boss Run End");
	} else {
		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.0)
	}
	
	return
}

public do_attack1(ent)
{
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Attack Start");
	
	g_doing_skill = 1
				
	set_entity_anim(ent, 8)	
	
	set_task(1.0, "revenant_attack1", ent+TASK_REVENANT_ATTACK)
	set_task(2.0, "reload_attack1", ent+TASK_REVENANT_ATTACK_RELOAD)	
}

public do_evolution(ent)
{
	set_entity_anim(ent, random_num(13, 14))

	set_task(2.9, "create_fire", ent+TASK_BURNING+1)
	set_task(3.0, "do_burning", ent+TASK_BURNING)
	set_task(10.0, "reset_evolution", ent+TASK_EVOLUTION)
}

public create_fire(ent)
{
	ent -= TASK_BURNING+1
	
	for(new i = 0; i < sizeof(g_fire_ent); i++)
	{
		if(!pev_valid(g_fire_ent[i]))
		{
			g_fire_ent[i] = create_entity("info_target")
			make_fire(g_fire_ent[i], 0.75)
		}
	}
}

public do_burning(ent)
{
	ent -= TASK_BURNING
	
	if(!pev_valid(ent))
		return;
	
	static Float:TempOrigin[5][3], Float:RealOrigin[5][3]
	
	TempOrigin[0][0] = 0.0
	TempOrigin[0][1] = 0.0
	TempOrigin[0][2] = 50.0
	
	TempOrigin[1][0] = 0.0
	TempOrigin[1][1] = 25.0
	TempOrigin[1][2] = 50.0
	
	TempOrigin[2][0] = 0.0
	TempOrigin[2][1] = -25.0
	TempOrigin[2][2] = 50.0
	
	TempOrigin[3][0] = 0.0
	TempOrigin[3][1] = 25.0
	TempOrigin[3][2] = 0.0
	
	TempOrigin[4][0] = 0.0
	TempOrigin[4][1] = -25.0
	TempOrigin[4][2] = 0.0	
	
	for(new i = 0; i < sizeof(g_fire_ent); i++)
	{
		get_position(ent, TempOrigin[i][0], TempOrigin[i][1], TempOrigin[i][2], RealOrigin[i])
		set_pev(g_fire_ent[i], pev_origin, RealOrigin[i])
	}
	
	set_task(0.1, "do_burning", ent+TASK_BURNING)
}

public reset_evolution(ent)
{
	ent -= TASK_EVOLUTION
	
	set_entity_anim(ent, 2)
	g_doing_skill = 0
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0)
}

public reload_attack1(ent)
{
	ent -= TASK_REVENANT_ATTACK_RELOAD
	
	g_doing_skill = 0
}

public revenant_attack1(ent)
{
	ent -= TASK_REVENANT_ATTACK
	
	if(!pev_valid(ent))
		return;
	
	emit_sound(ent, CHAN_BODY, g_RevenantSound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 300.0)
		{
			shake_screen(i)
			ExecuteHam(Ham_TakeDamage, i, 0, i, ATTACK1_DAMAGE, DMG_SLASH)
		}
	}
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Attack End");
}

public revenant_death(ent, attacker)
{
	new className[32]; 
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname) || g_revenant_death) 
		return HAM_IGNORED; 

	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Death");

	g_revenant_death = true
	
	remove_task(ent+TASK_BURNING)
	
	set_entity_anim(ent, 16)
	emit_sound(ent, CHAN_BODY, g_RevenantSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < sizeof(g_fire_ent); i++)
	{
		if(pev_valid(g_fire_ent[i]))
			remove_entity(g_fire_ent[i])
	}	
	
	remove_task(g_ent+TASK_RECHECK)
	if(pev_valid(g_healthbar)) remove_entity(g_healthbar)	
	
	server_cmd("umc_onlynextround 0");
	server_cmd("umc_startvote");
	
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Boss zostal^x04 zabity^x01! Wypadly z niego paczki z^x04 expem^x01 i^x04 AP^x01!")
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Zaraz nastapi glosowanie o kolejna mape!")
	
	DropGifts(ent)
	DamageBonus()
	
	set_task(10.0, "set_remove_revenant", ent+TASK_REMOVE_REVENANT)	
	
	return HAM_IGNORED; 
}

public DamageBonus() {
	new players[32], name[33], num, best, Float:damage, id
	get_players(players, num, "h");
	for(new i = 0; i < num; i++) {
		id = players[i];
			
		if(!is_user_connected(id) || is_user_hltv(id))
			continue;
			
		if(Damage_Taken[id] > damage) {
			damage = Damage_Taken[id]
			best = id
		}
	}
	get_user_name(best, name, charsmax(name))
	client_print_color(0, print_team_red, "^x03[BOSS]^x04 %s^x01 zadal Bossowi najwiecej obrazen. W nagrode otrzymuje^x04 %i^x01 expa!", name, best_exp)
	zp_add_user_exp(best, best_exp)
}

public DropGifts(Ent) {	
	log_to_file("addons/amxmodx/logs/revenant.log", "Drop Gifts");
	new Float:colors[3]
	new Gifts = floatround(float(get_playersnum())/1.5, floatround_round)
	for (new i; i < Gifts; ++i) {
		new Float:Vector[3]
		pev(Ent, pev_origin, Vector)
		
		new Gift = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
		set_pev(Gift, pev_classname, "package")
		//engfunc(EngFunc_SetSize, Gift, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,25.0}) 
		engfunc(EngFunc_SetSize, Gift, {-1.1, -1.1, -1.1},{1.1, 1.1, 1.1})
		engfunc(EngFunc_SetModel, Gift, RevenantResource[4])
		engfunc(EngFunc_SetOrigin, Gift, Vector)
		set_pev(Gift, pev_solid, SOLID_TRIGGER)
		set_pev(Gift, pev_movetype, MOVETYPE_TOSS)
		
		switch(random_num(1, 14)){
			case 0: { // pomaranczowy
				colors[0] = 255.0
				colors[1] = 170.0
				colors[2] = 0.0
			}
			case 1: { //blekitny
				colors[0] = 0.0
				colors[1] = 255.0
				colors[2] = 255.0
			}
			case 2: { //jasnozielony
				colors[0] = 50.0
				colors[1] = 255.0
				colors[2] = 0.0
			}
			case 3: { //czerwony
				colors[0] = 255.0
				colors[1] = 0.0
				colors[2] = 0.0
			}
			case 4: { //jasnozielony
				colors[0] = 128.0
				colors[1] = 255.0
				colors[2] = 0.0
			}
			case 5: { //fioletowy
				colors[0] = 60.0
				colors[1] = 0.0
				colors[2] = 255.0
			}
			case 6: { //ciemnorozowy
				colors[0] = 102.0
				colors[1] = 0.0
				colors[2] = 51.0
			}
			case 7: { //niebieski
				colors[0] = 0.0
				colors[1] = 0.0
				colors[2] = 255.0
			}
			case 8: { //ciemnozielony
				colors[0] = 102.0
				colors[1] = 0.0
				colors[2] = 0.0
			}
			case 9: { //granatowy
				colors[0] = 0.0
				colors[1] = 0.0
				colors[2] = 102.0
			}
			case 10: { //oliwkowy
				colors[0] = 153.0
				colors[1] = 153.0
				colors[2] = 0.0
			}
			case 11: { //brazowy
				colors[0] = 153.0
				colors[1] = 76.0
				colors[2] = 0.0
			}
			case 12: { //rozowy
				colors[0] = 255.0
				colors[1] = 0.0
				colors[2] = 255.0
			}
			case 13: { //bialy
				colors[0] = 255.0
				colors[1] = 255.0
				colors[2] = 255.0
			}
			case 14: { //szary
				colors[0] = 128.0
				colors[1] = 0.0
				colors[2] = 128.0
			}
		}
		set_pev(Gift, pev_renderfx, kRenderFxGlowShell)
		set_pev(Gift, pev_rendercolor, colors)
		set_pev(Gift, pev_rendermode, kRenderNormal)
		set_pev(Gift, pev_renderamt, 50.0)
		
		//get_position(Ent, random(2) ? (random_float(-900.0, -400.0)) : (random_float(300.0, 850.0)), random_float(-500.0, 500.0), random_float(-1000.0, 1000.0), Vector)
		//get_position(Ent, random(2) ? (random_float(-400.0, -100.0)) : (random_float(100.0, 400.0)), random_float(-500.0, 500.0), random_float(-1000.0, 1000.0), Vector)
		//get_position(Ent, random(2) ? (random_float(-600.0, -100.0)) : (random_float(100.0, 600.0)), random_float(-500.0, 500.0), random_float(0.0, 1000.0), Vector)
		get_position(Ent, random_float(-600.0, 600.0), random_float(-600.0, 600.0), random_float(-600.0, 600.0), Vector)
		xs_vec_normalize(Vector, Vector)
		xs_vec_mul_scalar(Vector, 600.0, Vector)
		set_pev(Gift, pev_velocity, Vector)
	}
}

public TouchPackage(entity, id)
{
	if(!pev_valid(entity))
		return HAM_IGNORED
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	static classname[64]
	pev(entity, pev_classname, classname, charsmax(classname))
	
	if(equal(classname, "package")){
		if(Gift_Message[id])
			return HAM_IGNORED
		if(Gift_Taken[id]){
			client_print_color(id, print_team_red, "^x03[BOSS]^x01 Juz podniosles paczke. Daj szanse innym na zdobycie nagrody!")
			Gift_Message[id] = true
			set_task(1.0, "ResetMessage", id)
			return HAM_IGNORED
		}
		new type = random_num(1, 2)
		switch(type)
		{
			case 1: {
				new ap = random_num(gift_min_ap, gift_max_ap)
				client_print_color(id, print_team_red, "^x03[BOSS]^x01 W paczce znalazles^x04 %i^x01 AP.", ap)
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + ap)
			}
			case 2: {
				new exp = random_num(gift_min_exp, gift_max_exp)
				client_print_color(id, print_team_red, "^x03[BOSS]^x01 W paczce znalazles^x04 %i^x01 expa.", exp)
				zp_add_user_exp(id, exp)
			}
		}
		Gift_Taken[id] = true
		engfunc(EngFunc_RemoveEntity, entity)
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, g_RevenantSound[10], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	return HAM_IGNORED
}

public ResetMessage(id)
	Gift_Message[id] = false
	
public player_killed(victim, attacker) 
{	
	if(get_user_team(victim) == 1 || get_user_team(victim) == 2)
		set_task(5.0, "Respawn", victim + TASK_RESPAWN)
}

public Respawn(id){
	id -= TASK_RESPAWN
	if(is_user_connected(id))
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public set_remove_revenant(ent)
{
	ent -= TASK_REMOVE_REVENANT
	
	log_to_file("addons/amxmodx/logs/revenant.log", "Boss Remove");
	
	if(pev_valid(ent))
		remove_entity(ent)
}

public revenant_takedamage(ent, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(attacker) || !is_valid_ent(ent))
		return;

	new className[32]; 
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname)) 
		return; 
		
	static Float:Origin[3]
	fm_get_aim_origin(attacker, Origin)
	
	Damage_Taken[attacker] += damage;
	
	create_blood(Origin)	
}

// ============ DEFAULT NPC FORWARD + PUBLIC ===============
public FindClosesEnemy(entid)
{
	new Float:Dist
	new Float:maxdistance=4000.0
	new indexid=0	
	for(new i=1;i<=get_maxplayers();i++){
		if(is_user_alive(i) && is_valid_ent(i) && can_see_fm(entid, i))
		{
			Dist = entity_range(entid, i)
			if(Dist <= maxdistance)
			{
				maxdistance=Dist
				indexid=i
				
				return indexid
			}
		}	
	}	
	return 0
}

public npc_turntotarget(ent, Float:Ent_Origin[3], target, Float:Vic_Origin[3]) 
{
	if(target) 
	{
		new Float:newAngle[3]
		entity_get_vector(ent, EV_VEC_angles, newAngle)
		new Float:x = Vic_Origin[0] - Ent_Origin[0]
		new Float:z = Vic_Origin[1] - Ent_Origin[1]

		new Float:radians = floatatan(z/x, radian)
		newAngle[1] = radians * (180 / 3.14)
		if (Vic_Origin[0] < Ent_Origin[0])
			newAngle[1] -= 180.0
        
		entity_set_vector(ent, EV_VEC_v_angle, newAngle)
		entity_set_vector(ent, EV_VEC_angles, newAngle)
	}
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}

public hook_ent(ent, victim, Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:VicOrigin[3], Float:EntOrigin[3]

	pev(ent, pev_origin, EntOrigin)
	pev(victim, pev_origin, VicOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)

	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed

		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = 0.0 //(VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

public get_player_alive() {
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
	return iAlive
}

config_load() {
	new path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, FILE_SETTING)
    
	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	new linedata[1024], key[64], value[960], section
	new file = fopen(path, "rt")
    
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
       
		if (!linedata[0] || linedata[0] == '/') continue;
		if (linedata[0] == '[') { section++; continue; }
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)
		
		switch (section) { 
			case 1: {
				if (equal(key, "HEALTH"))
					boss_heal = str_to_num(value)
				else if (equal(key, "PREPARE"))
					prepare_time = str_to_num(value)
			}
			case 2: {
				if (equal(key, "BEST_EXP"))
					best_exp = str_to_num(value)
				else if (equal(key, "GIFT_MIN_AP"))
					gift_min_ap = str_to_num(value)
				else if (equal(key, "GIFT_MAX_AP"))
					gift_max_ap = str_to_num(value)
				else if (equal(key, "GIFT_MIN_EXP"))
					gift_min_exp = str_to_num(value)
				else if (equal(key, "GIFT_MAX_EXP"))
					gift_max_exp = str_to_num(value)
			}
		}
	}
	if (file) fclose(file)
}

// ======================== NPC STOCK ======================
stock PlayerHp(hp) {
	new Count, Hp
	for(new id = 1; id <= get_maxplayers(); id++)
		if (is_user_connected(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	
	boss_health = Hp;
	
	return Hp
}

stock shake_screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed
		
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock set_entity_anim(ent, anim)
{
	entity_set_float(ent, EV_FL_animtime, get_gametime())
	entity_set_float(ent, EV_FL_framerate, 1.0)
	entity_set_float(ent, EV_FL_frame, 0.0)
	entity_set_int(ent, EV_INT_sequence, anim)	
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(g_RevenantResource[6])
	write_short(g_RevenantResource[5])
	write_byte(75)
	write_byte(5)
	message_end()
}
