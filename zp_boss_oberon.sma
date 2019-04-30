#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define NAME 			"[ZP] Oberon Boss"
#define VERSION			"3.2"
#define AUTHOR			"Alexander.3 && O'Zone"

#define BOMB_CUSTOM
#define NEW_SEARCH
#define RANDOM_ABILITY
#define PLAYER_HP

new const BossName[] = "Oberon";
new const BossMap[] = "zp_boss_oberon";

new const Resource[][] = {
	"models/zp/boss/oberon_boss.mdl",		// 0
	"sprites/zp/boss/health_bar.spr",		// 1
	"sprites/blood.spr",				// 2
	"sprites/bloodspray.spr",			// 3
	"models/zp/boss/bomb.mdl",		// 4
	"sprites/eexplo.spr",				// 5
	"models/zp/boss/hole.mdl",		// 6
	"models/zp/boss/knife.mdl", 		// 7
	"models/zp/boss/cell.mdl",		// 8
	"models/zp/boss/gibs.mdl",		// 9
	"sprites/zp/boss/poison.spr",		// 10
	"sprites/shockwave.spr",			// 11
	"sprites/zp/boss/blue.spr",		// 12
	"models/zp/boss/package.mdl",   // 13
	"sprites/zp/boss/killed.spr"	// 14
}
static g_Resource[sizeof Resource]
new const SoundList[][] = {
	"zp/boss/step1.wav",		// 0
	"zp/boss/step2.wav",		// 1
	"zp/boss/attack1.wav",		// 2
	"zp/boss/attack2.wav",		// 3
	"zp/boss/attack3.wav",		// 4
	"zp/boss/attack1_knife.wav",	// 5
	"zp/boss/attack2_knife.wav",	// 6
	"zp/boss/bomb.wav",		// 7
	"zp/boss/hole.wav",		// 8
	"zp/boss/jump.wav",		// 9
	"zp/boss/knife.wav",		// 10
	"zp/boss/roar.wav",		// 11
	"zp/boss/death.wav",		// 12
	"zp/boss/scenario_ready.mp3",		// 13
	"zp/boss/scenario_rush.mp3",			// 14
	"zp/boss/scenario_normal.mp3",		// 15
	"zp/boss/package_get.wav"		// 16
}

#define TASK_RESPAWN 3503
#define TASK_REMOVE_OBERON 4324
#define MAX_BOMB	10
new const FILE_SETTING[] = "zp_boss_oberon.ini"
new boss_heal, prepare_time, Float:bomb_dist, blood_color,
	speed_boss, dmg_attack_max, dmg_attack, bomb_damage, hole_dmg, jump_damage, jump_distance, time_ability,
	speed_boss_agr, bomb_damage_agr, hole_dmg_agr, jump_damage_agr, time_ability_agr

#if defined SUPPORT_ZM
new zm_time, zm_add_time, zm_hp, zm_speed, zm_damage
#endif

#if defined BOMB_CUSTOM
new bomb_mind, Float:bomb_poison, bomb_poison_life, Float:bomb_frozen_time, g_Color
#endif

new best_exp, gift_min_ap, gift_max_ap, gift_min_exp, gift_max_exp

new Float:Damage_Taken[33]
new bool:Gift_Taken[33]
new bool:Gift_Message[33]
new bool:damage_bonus
new bool:drop_gifts
new bool:boss_killed

static g_Oberon, g_Bomb[MAX_BOMB], g_Hole, Float:g_MaxHp
static e_boss

enum {
	RUN,
	ATTACK,
	BOMB,
	HOLE,
	JUMP,
	AGRESS
}

native zp_register_boss(const name[], const map[]);
native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)
native zp_add_user_exp(id, amount)

#define pev_pre				pev_euser1
#define pev_num				pev_euser2
#define pev_ability			pev_euser3
#define pev_victim			pev_euser4

public plugin_init() 
{
	register_plugin(NAME, VERSION, AUTHOR)
	
	RegisterHam(Ham_TraceAttack, "info_target", "Hook_TraceAttack")
	RegisterHam(Ham_BloodColor, "info_target", "Hook_BloodColor")
	RegisterHam(Ham_Killed, "info_target", "Hook_Killed")
	RegisterHam(Ham_Killed, "player", "Hook_KilledPlayer", 1)
	RegisterHam(Ham_Spawn, "player", "Hook_Spawn")
	
	register_forward(FM_Touch, "TouchPackage")
	
	register_think("OberonBoss", "Think_Boss")
	register_think("OberonKnife", "Think_Knife")
	register_think("OberonTimer", "Think_Timer")
	register_think("Health", "Think_Health")
	register_think("Gas", "Think_Gase")
	register_think("Box", "Think_Box")
	
	register_touch("OberonBoss", "*", "Touch_Boss")
	register_touch("OberonBomb", "*", "Touch_Bomb")
	register_touch("Box", "player", "Touch_Box")
	
	zp_register_boss(BossName, BossMap)
	
	set_task(1.0, "MapEvent")
}

public Boss_Spawn(Float:hp, Ent) {
	new hpbar, Float:Origin[3]; pev(Ent, pev_origin, Origin)
	g_Oberon = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	hpbar = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	Origin[2] += 50.0
	engfunc(EngFunc_SetModel, g_Oberon, Resource[0])
	engfunc(EngFunc_SetSize, g_Oberon, Float:{-32.0, -32.0, -36.0}, Float:{32.0, 32.0, 96.0})
	engfunc(EngFunc_SetOrigin, g_Oberon, Origin)
	
	set_pev(g_Oberon, pev_classname, "OberonBoss")
	set_pev(g_Oberon, pev_solid, SOLID_BBOX)
	set_pev(g_Oberon, pev_movetype, MOVETYPE_TOSS)
	set_pev(g_Oberon, pev_takedamage, DAMAGE_NO)
	set_pev(g_Oberon, pev_deadflag, DEAD_NO)
	set_pev(g_Oberon, pev_health, hp)
	g_MaxHp = hp
	
	Origin[2] += 160.0
	engfunc(EngFunc_SetOrigin, hpbar, Origin)
	set_pev(hpbar, pev_effects, pev(hpbar, pev_effects) | EF_NODRAW)
	engfunc(EngFunc_SetModel, hpbar, Resource[1])
	entity_set_float(hpbar, EV_FL_scale, 0.5)
	set_pev(hpbar, pev_classname, "Health")
	set_pev(hpbar, pev_frame, 100.0)
	
	set_pev(g_Oberon, pev_fuser1, get_gametime() + 15.0)
	set_pev(hpbar, pev_nextthink, get_gametime() + 10.0)
	
	Anim(g_Oberon, 1, 1.0)
	
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Pamietajcie, aby trzymac Bossa jak najblizej srodka mapy! Powodzenia!")
	
	log_to_file("addons/amxmodx/logs/oberon.log", "Boss Spawn");
}

public EventPrepare()
{
	new Float:Origin[3], Box
	Box = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	pev(e_boss, pev_origin, Origin)
	engfunc(EngFunc_SetModel, Box, Resource[8])
	engfunc(EngFunc_SetSize, Box, {-64.0, -64.0, -1.0}, Float:{64.0, 64.0, 96.0})
	engfunc(EngFunc_SetOrigin, Box, Origin)
	set_pev(Box, pev_classname, "Box")
	set_pev(Box, pev_solid, SOLID_BBOX)
	set_pev(Box, pev_movetype, MOVETYPE_NONE)
	set_pev(Box, pev_nextthink, get_gametime() + 0.1)
	set_rendering(Box, kRenderFxFadeSlow, 255, 255, 0, kRenderTransAlpha, 255)
	
	log_to_file("addons/amxmodx/logs/oberon.log", "Boss Prepare");
}

public Think_Box(Ent) {
	static fade, Float:Origin[3]
	static Float:OriginBox[3]; pev(e_boss, pev_origin, OriginBox)
	switch (pev(Ent, pev_num)) {
		case 0: {
			static shake_num
			ScreenShake(0, ((1<<12) * 3), ((2<<12) * 3))
			set_pev(Ent, pev_nextthink, get_gametime() + 5.0)
			if (shake_num >= 2) set_pev(Ent, pev_num, 1)
			shake_num++
		} 
		case 1: {
			OriginBox[2] = 1350.0
			expl(OriginBox, 50, {255, 255, 0}, 0, 5)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			set_pev(Ent, pev_num, 2)
		}
		case 2: {
			OriginBox[2] = 1450.0
			expl(OriginBox, 50, {255, 255, 0}, 0, 5)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			set_pev(Ent, pev_num, 3)
		}
		case 3: {
			OriginBox[2] = 1600.0
			expl(OriginBox, 50, {255, 255, 0}, 0, 5)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			set_pev(Ent, pev_num, 4)
		}
		case 4: {
			OriginBox[2] = 1750.0
			set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
			expl(OriginBox, 50, {255, 255, 0}, 0, 5)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.5)
			set_pev(Ent, pev_num, 5)
		}
		case 5: {
			#if defined PLAYER_HP
			Boss_Spawn(float(PlayerHp(boss_heal)), Ent) 
			#else
			Boss_Spawn(float(boss_heal), Ent)
			#endif
			pev(Ent, pev_origin, Origin)
			ScreenShake(0, ((1<<12) * 4), ((2<<12) * 4))
			set_pev(Ent, pev_body, 1)
			set_pev(Ent, pev_nextthink, get_gametime() + 5.0)
			set_pev(Ent, pev_num, 6)
		}
		case 6: {
			set_pev(Ent ,pev_solid, SOLID_NOT)
			set_pev(g_Oberon, pev_ability, RUN)
			fade = 255
			Anim(Ent, 1, 2.0)
			Anim(g_Oberon, 0, 1.0)
			Sound(g_Oberon, 11)
			set_pev(g_Oberon, pev_nextthink, get_gametime() + 4.2)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.02)
			Wreck(Origin, {160.0, 160.0, 160.0}, {100.0, 100.0, 100.0}, 100, 100, 50, (0x02))
			set_pev(Ent, pev_num, 7)
		}
		case 7 : {
			if (fade <= 5) {
				engfunc(EngFunc_RemoveEntity, Ent)
				return
			}
			fade -= 2 
			set_rendering(Ent, kRenderFxFadeSlow, 255, 255, 0, kRenderTransAlpha, fade)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
		}
	}
}

public Think_Boss(Ent) {
	if (pev(Ent, pev_deadflag) == DEAD_DYING || boss_killed)
		return
		
	if (!get_player_alive()) {
		Anim(Ent, 1, 1.0)
		set_pev(Ent, pev_nextthink, get_gametime() + 6.1)
		return
	}
	
	if(!is_valid_ent(Ent)) 
		return; 
	
	static Agr; Agr = pev(Ent, pev_button)
	if (pev(Ent, pev_fuser1) <= get_gametime()) {
		if (pev(Ent, pev_ability) == RUN && pev(Ent, pev_button) != 3) {
			#if defined RANDOM_ABILITY
			switch( random(3) ) {
				case 0: set_pev(Ent, pev_ability, BOMB)
				case 1: set_pev(Ent, pev_ability, HOLE)
				case 2: set_pev(Ent, pev_ability, JUMP)
			}
			#else
			switch( pev(Ent, pev_weaponanim) ) {
				case 0: { set_pev(Ent, pev_ability, BOMB); set_pev(Ent, pev_weaponanim, 1); }
				case 1: { set_pev(Ent, pev_ability, HOLE); set_pev(Ent, pev_weaponanim, 2); }
				case 2: { set_pev(Ent, pev_ability, JUMP); set_pev(Ent, pev_weaponanim, 0); }
			}
			#endif
			set_pev(Ent, pev_num, 0)
		}
		set_pev(Ent, pev_fuser1, get_gametime() + (Agr ? float(time_ability_agr) : float(time_ability)))
	}	
	switch(pev(Ent, pev_ability)) {
		case RUN: {
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Run Start");
			new Float:Velocity[3], Float:Angle[3]
			static Target
			if (!is_user_alive(Target)) {
				Target = get_random_player()
				set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
				return
			}
			if (!pev(Ent, pev_num)) {
				set_pev(Ent, pev_num, 1)
				set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
				Anim(Ent, Agr ? 10 : 2, 1.5)
			}
			#if defined NEW_SEARCH
			new Len, LenBuff = 99999
			for(new i = 1; i <= get_maxplayers(); i++) {
				if (!is_user_alive(i) || is_user_bot(i))
					continue
						
				Len = Move(Ent, i, 500.0, Velocity, Angle)
				if (Len < LenBuff) {
					LenBuff = Len
					Target = i
				}
			}
			#endif
			Move(Ent, Target, pev(g_Oberon, pev_button) ? float(speed_boss_agr) : float(speed_boss), Velocity, Angle)
			Velocity[2] = 0.0
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Run End");
		}
		case ATTACK:{
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Attack Start");
			static randoms
			switch(pev(Ent, pev_num)) {
				case 0: {
					randoms = random(2)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					
					if(Agr) {
						Sound(Ent, random_num(5, 6))
						Anim(Ent, randoms ? 11 : 12, 1.0)
						set_pev(Ent, pev_nextthink, get_gametime() + (randoms ? 0.6 : 0.3))
					} else {
						Sound(Ent, randoms ? 2 : 4)
						Anim(Ent, randoms ? 3 : 4, 1.0)
						set_pev(Ent, pev_nextthink, get_gametime() + (randoms ? 1.5 : 0.8))
					}
					log_to_file("addons/amxmodx/logs/oberon.log", "Boss Attack Effect");
					return
				}
				case 1: {
					new Float:Velocity[3], Float:Angle[3], Len
					new victim = pev(Ent, pev_victim)
					
					Len = Move(Ent, victim, 2000.0, Velocity, Angle)
					if ( Len <= 165 ) {
						if (Agr) {
							AgrEff(0)
							ExecuteHamB(Ham_Killed, victim, victim, 2)
						} else {
							Velocity[2] = 500.0
							boss_damage(victim, randoms ? dmg_attack_max : dmg_attack, {255, 0, 0})
							if (!randoms) set_pev(victim, pev_velocity, Velocity)
						}
					}
					log_to_file("addons/amxmodx/logs/oberon.log", "Boss Attack Done");
				}
			}
			set_pev(Ent, pev_num, 0)
			set_pev(Ent, pev_ability, RUN)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.3)
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Attack End");
		}
		case BOMB: {
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Bomb Start");
			static BombTarget[MAX_BOMB], Float:VectorB[3]
			switch(pev(Ent, pev_num)) {
				case 0: {
					#if defined BOMB_CUSTOM
					if (Agr) g_Color = random_num(1, 4)
					#endif
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Anim(Ent, Agr ? 14 : 6, 1.0)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_nextthink, get_gametime() + 3.2)
					
					for (new i; i < MAX_BOMB; ++i) BombTarget[i] = get_random_player()
				}
				case 1: {
					Sound(Ent, 7)
					new Float:Origin[3]; pev(Ent, pev_origin, Origin)
					Origin[2] += 100.0
					for (new i; i < MAX_BOMB; ++i) {
						new Bomb = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
						new Float:Origin2[3], Float:Angles[3]
						get_position(BombTarget[i], random_float(-400.0, -400.0), random_float(-300.0, 300.0), random_float(-1500.0, 1500.0), Origin2)
						g_Bomb[i] = Bomb
						engfunc(EngFunc_SetModel, Bomb, Resource[4])
						engfunc(EngFunc_SetOrigin, Bomb, Origin)
						engfunc(EngFunc_SetSize, Bomb, {-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
						set_pev(Bomb, pev_classname, "OberonBomb")
						set_pev(Bomb, pev_solid, SOLID_NOT)
						set_pev(Bomb, pev_movetype, MOVETYPE_NOCLIP)
						Anim(Bomb, 0, 8.0)
						
						#if defined BOMB_CUSTOM
						switch (g_Color) {
							case 1: set_rendering(g_Bomb[i], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 60)
							case 2: if (i < 3) set_rendering(g_Bomb[i], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 60)
							case 3: if (i < 3) set_rendering(g_Bomb[i], kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 60)
							case 4: set_rendering(Bomb, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 60)
						}
						#endif
						xs_vec_sub(Origin2, Origin, VectorB)
						vector_to_angle(VectorB, Angles)
						xs_vec_normalize(VectorB, VectorB)
						Angles[0] = 0.0
						Angles[2] = 0.0
						VectorB[2] = 1.0
						xs_vec_mul_scalar(VectorB, 400.0, VectorB)
						set_pev(Bomb, pev_velocity, VectorB)
						set_pev(Bomb, pev_angles, Angles)
						set_pev(Ent, pev_num, 2)
						set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					}
				}
				case 2: {
					new Float:Angle[3], Float:Velocity[3]
					for (new i; i < MAX_BOMB; ++i) {
						new Bomb = g_Bomb[i]
						set_pev(Bomb, pev_movetype, MOVETYPE_BOUNCE)
						set_pev(Bomb, pev_solid, SOLID_BBOX)
						#if defined BOMB_CUSTOM
						if ( g_Color == 1 ) {
							BombTarget[i] = get_random_player()
							Move(Bomb, BombTarget[i], 2000.0, Velocity, Angle)
							set_pev(Bomb, pev_velocity, Velocity)
						} else VectorB[2] = 0.0
						#else
						VectorB[2] = 0.0
						#endif
						//set_pev(Bomb, pev_velocity, VectorB)
						//set_pev(Bomb, pev_angles, Angle)
					}
					static num
					if (num >= 2) {
						set_pev(Ent, pev_nextthink, get_gametime() + 1.5)
						set_pev(Ent, pev_ability, RUN)
						set_pev(Ent, pev_num, 0)
						num = 0
						return
					} else num++
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.8)
				}
			}
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Bomb End");			
		}
		case HOLE: {
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Hole Start");
			new Float:Origin[3]; pev(Ent, pev_origin, Origin)
			switch (pev(Ent, pev_num)) {
				case 0: {
					Sound(Ent, 8)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Origin[2] -= 35.0
					g_Hole = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
					engfunc(EngFunc_SetModel, g_Hole, Resource[6])
					engfunc(EngFunc_SetOrigin, g_Hole, Origin)
					
					Anim(Ent, Agr ? 15 : 7, 0.8)
					Anim(g_Hole, 0, 0.7)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					set_pev(Ent, pev_num, 1)
				}
				case 1: {
					static Float:Angle[3], Float:Velocity[3], Len, num
					for(new id = 1; id <= get_maxplayers(); id++) {
						if (!is_user_alive(id) || is_user_bot(id))
							continue
							
						Len = Move(id, Ent, 500.0, Velocity, Angle)
						if (Len < 800) set_pev(id, pev_velocity, Velocity)
					}
					set_pev(Ent, pev_nextthink, get_gametime() + 0.3)
					if (num >= 23) {
						num = 0
						set_pev(Ent, pev_num, 2)
						return
					}
					num++
				}
				case 2: {
					if (Agr) AgrEff(1)
					engfunc(EngFunc_RemoveEntity, g_Hole)
					static victim = -1
					while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
						if(0 < victim <= get_maxplayers() && is_user_alive(victim)) {
							boss_damage(victim, pev(g_Oberon, pev_button) ? hole_dmg_agr : hole_dmg, {255, 0, 0})
						}
					}
					set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
				}
			}
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Hole End");
		}
		case JUMP: {
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Jump Start");
			static Float:Origin2[3], Float:Velocity[3]
			new JumpTarget, Float:j_Origin[3], Float:j_Vector[3], Float:Len, Float:LenSubb
			switch (pev(Ent, pev_num)) {
				case 0: {
					new Float:Origin[3]; pev(Ent, pev_origin, Origin)
					for(new s; s <= get_maxplayers(); s++) {
						if (!is_user_alive(s) || is_user_bot(s))
							continue
							
						pev(s, pev_origin, j_Origin)
						xs_vec_sub(j_Origin, Origin, j_Vector)
						Len = xs_vec_len(j_Vector)
						
						if (Len > LenSubb) {
							LenSubb = Len
							JumpTarget = s
						}
					}
					static Float:Angle[3]; pev(JumpTarget, pev_origin, Origin2)
					Move(Ent, JumpTarget, 500.0, Velocity, Angle)
					set_pev(Ent, pev_angles, Angle)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.5)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Anim(Ent, Agr ? 13 : 5, 1.0)
					set_pev(Ent, pev_movetype, MOVETYPE_BOUNCE)
				}
				case 1: {
					Sound(Ent, 9)
					Velocity[2] = 1000.0
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					set_pev(Ent, pev_num, 2)
				}
				case 2: {
					new Float:Origin[3]; pev(Ent, pev_origin, Origin)
					set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
					xs_vec_sub(Origin2, Origin, Velocity)
					xs_vec_normalize(Velocity, Velocity)
					xs_vec_mul_scalar(Velocity, 1000.0, Velocity)
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.8)
					set_pev(Ent, pev_num, 3)
					set_pev(Ent, pev_pre, 1)
				}
				case 3: {
					set_pev(Ent, pev_pre, 0)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.6)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
				}
			}
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Jump End");
		}
		case AGRESS: {
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Agress Start");
			switch(pev(Ent, pev_num)) {
				case 0: {
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_takedamage, DAMAGE_NO)
					set_pev(Ent, pev_button, 3)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_nextthink, get_gametime() + 8.6)
					Anim(Ent, 8, 1.0)
					Sound(Ent, 10)
				}
				case 1: {
					set_pev(Ent, pev_takedamage, DAMAGE_YES)
					set_pev(Ent, pev_button, 1)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
					client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[14])
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
				}
			}
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Agress End");
		}
	}
}

public AgrEff(hole) {
	new Float:OriginKnf[3]; pev(g_Oberon, pev_origin, OriginKnf)
	new Float:AnglesKnf[3]; pev(g_Oberon, pev_angles, AnglesKnf)
	new Eff = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	OriginKnf[2] += 35.0
	engfunc(EngFunc_SetModel, Eff, Resource[7])
	engfunc(EngFunc_SetOrigin, Eff, OriginKnf)
	set_pev(Eff, pev_classname, "OberonKnife")
	set_pev(Eff, pev_angles, AnglesKnf)
	set_pev(Eff, pev_nextthink, get_gametime() + 1.0)
	set_rendering(Eff, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	Anim(Eff, hole ? 2 : 1, 1.0)
}

public Think_Knife(Ent) {
	if (!pev_valid(Ent))
		return
		
	static bool:num, fades
	if (!num) {
		num = true
		fades = 255
	} else {
		if (fades > 5) {
			fades--
			set_rendering(Ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, fades)
		} else {
			num = false
			engfunc(EngFunc_RemoveEntity, Ent)
			return
		}
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.03)
}

public Think_Health(Ent) {
	if (!pev_valid(g_Oberon)) {
		set_pev(Ent, pev_nextthink, get_gametime() + 0.5)
		return
	}
	
	static Float:frame, Float:hp; pev(g_Oberon, pev_health, hp)
	static Float:Origin[3]; pev(g_Oberon, pev_origin, Origin)
	switch (pev(Ent, pev_num)) {
		case 0: {
			set_pev(Ent, pev_num, 1)
			set_pev(g_Oberon, pev_takedamage, DAMAGE_YES)
			set_pev(Ent, pev_effects, pev(Ent, pev_effects) & ~EF_NODRAW)
			client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[15])
		}
		case 1: {
			frame = hp * 100.0 / g_MaxHp
			if (frame < 50 && pev(g_Oberon, pev_ability) == RUN && pev(g_Oberon, pev_button) == 0 && pev(Ent, pev_pre) == 0) {
				set_pev(g_Oberon, pev_ability, AGRESS)
				set_pev(g_Oberon, pev_num, 0)
				set_pev(Ent, pev_pre, 1)
			}
			Origin[2] += 210.0
			set_pev(Ent, pev_origin, Origin)
			set_pev(Ent, pev_frame, frame)
		}
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public Think_Gase(Ent) {
	if (!pev_valid(Ent))
		return
	
	static num
	if(num > bomb_poison_life) {
		num = 0
		engfunc(EngFunc_RemoveEntity, Ent)
		return
	}
	static Float:Origin[3], victim = -1
	set_pev(Ent, pev_nextthink, get_gametime() + 2.0)
	pev(Ent, pev_origin, Origin)
	Smoke(Origin)
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
		if(is_user_alive(victim)) {
			ExecuteHamB(Ham_TakeDamage, victim, 0, victim, bomb_poison, DMG_SONIC)
			DmgMsg(Origin, victim, 131072)
		}
	}
	num++
}

public Think_Timer(Ent) 
{
	if (!get_player_alive()) 
	{
		set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
		log_to_file("addons/amxmodx/logs/oberon.log", "Think Timer No Players");
		return
	}
	
	if(!is_valid_ent(Ent)) 
		return; 
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Think Timer Boss Valid");
	
	if (pev(g_Oberon, pev_deadflag) == DEAD_DYING)
		return
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Think Timer Boss Not Dead");
	
	static Counter
	switch(pev(Ent, pev_num)) 
	{
		case 0: 
		{ 
			Counter = prepare_time; EventPrepare(); 
			set_pev(Ent, pev_num, 1); 
			set_pev(Ent, pev_fuser1, get_gametime() + (prepare_time)); 
			log_to_file("addons/amxmodx/logs/oberon.log", "Boss Counter");
		}
		case 1: 
		{ 
			Counter--;
			set_hudmessage(0, 255, 0, -1.0, 0.30, 1, 5.0, 5.0)
			show_hudmessage(0, "Oberon pojawi sie za %d sekund", Counter)
			if (Counter <= 0) set_pev(Ent, pev_num, 2);
		}
		case 2: Counter ++;
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	message_begin(MSG_ALL, get_user_msgid("RoundTime"))
	write_short(Counter) 
	message_end()
}

public Touch_Boss(Boss, Ent) {
	if (pev(Boss, pev_ability) == ATTACK)
		return

	if (pev(Boss, pev_ability) == JUMP && pev(Boss, pev_pre) == 1) {
		static victim =-1
		new Agr = pev(Ent, pev_button)
		
		new Float:Origin[3]; pev(Boss, pev_origin, Origin)
		ShockWave(Origin, 10, 200, float(jump_distance), {255, 0, 0})
		ScreenShake(0, ((1<<12) * 8), ((2<<12) * 7))
		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, (float(jump_distance) * 4))) != 0) {
			if (!is_user_alive(victim))
				continue

			boss_damage(victim, Agr ? jump_damage_agr : jump_damage, {255, 0, 0})
		}
		if (!is_user_alive(Ent))
			return
			
		ExecuteHamB(Ham_Killed, Ent, Ent, 2)
		return
	}
		
	if (pev(Boss, pev_ability) != RUN)
		return
	
	if (!is_user_alive(Ent))
		return
	
	set_pev(Boss, pev_victim, Ent)
	set_pev(Boss, pev_ability, ATTACK)
	set_pev(Boss, pev_num, 0)
}

public Touch_Bomb(Ent, Ent2) {
	new MsgBomb = 8, Sprite = 5, Colors[3] = {255, 0, 0}, Float:Origin[3]; pev(Ent, pev_origin, Origin)
	Origin[2] += bomb_dist
	#if defined BOMB_CUSTOM
	switch (g_Color) {
		case 2: {
			if (g_Bomb[0] == Ent || g_Bomb[1] == Ent || g_Bomb[2] == Ent) {
				new Gase = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
				engfunc(EngFunc_SetModel, Gase, Resource[4])
				engfunc(EngFunc_SetSize, Gase, {40.0, 40.0, 40.0}, {40.0, 40.0, 40.0})
				engfunc(EngFunc_SetOrigin, Gase, Origin)
				set_pev(Gase, pev_classname, "Gas")
				set_pev(Gase, pev_solid, SOLID_TRIGGER)
				set_pev(Gase, pev_nextthink, get_gametime() + 2.0)
				set_pev(Gase, pev_effects, pev(Gase, pev_effects) | EF_NODRAW)
				Smoke(Origin)
			}
		}
		case 3: {
			static victim = -1
			if (g_Bomb[0] == Ent || g_Bomb[1] == Ent || g_Bomb[2] == Ent)
				while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
					if (!is_user_alive(victim))
						continue
				
					set_pev(victim, pev_health, 1.0)
					Colors = {255, 255, 0}
					MsgBomb = 8
					Sprite = 5
				}
			//Origin[2] -= bomb_dist
			ShockWave(Origin, 10, 100, 100.0, {255, 255, 0})
		}
		case 4: {
			static victim = -1
			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
				if (!is_user_alive(victim))
					continue
				
				set_rendering(victim, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 60)
				ScreenFade(victim, 6, 2, {0, 0, 255}, 90, 1)
				if(~pev(victim, pev_flags) & FL_FROZEN) set_pev(victim, pev_flags, pev(victim, pev_flags) | FL_FROZEN) 
				set_task(bomb_frozen_time, "Bomb_UnFrozen", 7512 + victim)
			}
			Sprite = 12
			Origin[2] += 50.0
			Colors = {0, 0, 255}
			ShockWave(Origin, 10, 100, 100.0, {0, 0, 255})
			MsgBomb = 16384
		}
	}
	#else
	MsgBomb = 8
	Colors = {255, 0, 0}
	#endif
	expl(Origin, 40, Colors, MsgBomb, Sprite)
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Touch_Box(Ent, Player) {
	if (!is_user_alive(Player) || !pev_valid(Ent))
		return
		
	ExecuteHamB(Ham_Killed, Player, Player, 2) 
}

public plugin_precache() {
	new szMapName[32];
	get_mapname(szMapName, 31);
	if(!(equal(szMapName, BossMap)))
		set_task(0.5, "PauseBoss");
	else
	{
		for (new i; i <= charsmax(Resource); i++)
			g_Resource[i] = precache_model(Resource[i])
		
		for(new e; e <= charsmax(SoundList); e++)
			precache_sound(SoundList[e])
	}
}

public PauseBoss()
	pause("ad")

public plugin_cfg()
	config_load()
	
public client_putinserver(id)
	Damage_Taken[id] = 0.0;

public Hook_TraceAttack(victim, attacker, Float:damage, Float:direction[3], th, dt) {
	if (is_boss_valid(victim) != 1)
		return HAM_IGNORED
		
	if (pev(victim, pev_button) == 3)
		return HAM_IGNORED
	
	Damage_Taken[attacker] += damage
	
	static Float:End[3]
	get_tr2(th, TR_vecEndPos, End)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, End[0])
	engfunc(EngFunc_WriteCoord, End[1])
	engfunc(EngFunc_WriteCoord, End[2])
	message_end()
	return HAM_IGNORED
}

public Hook_Killed(victim, attacker, corpse) 
{
	log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed");
	
	if (!is_boss_valid(victim))
		return HAM_IGNORED
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed Boss");
		
	if (pev(victim, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed Boss Dying");
		
	if(boss_killed)
		return HAM_IGNORED
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed Boss Drop");
		
	boss_killed = true
	
	Sound(victim, 12)
	Anim(victim, 16, 1.0)

	server_cmd("umc_onlynextround 0");
	server_cmd("umc_startvote");
	
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Boss zostal^x04 zabity^x01! Wypadly z niego paczki z^x04 expem^x01 i^x04 AP^x01!")
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Zaraz nastapi glosowanie o kolejna mape!")
	
	DropGifts(victim)
	DamageBonus()
	
	if (pev_valid(g_Hole)) engfunc(EngFunc_RemoveEntity, g_Hole)
	
	set_task(10.0, "set_remove_oberon", victim+TASK_REMOVE_OBERON)
	
	return HAM_SUPERCEDE
}

public Hook_KilledPlayer(victim, attacker, corpse) 
{
	log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed Player");
	
	if(is_user_connected(victim))
	{
		if(get_user_team(victim) == 1 || get_user_team(victim) == 2)
		{
			log_to_file("addons/amxmodx/logs/oberon.log", "Hook Killed Player Respawn");
			set_task(5.0, "Respawn", victim + TASK_RESPAWN)
		}
	}
	return HAM_IGNORED
}

public set_remove_oberon(victim)
{
	victim -= TASK_REMOVE_OBERON
	
	if(!pev_valid(victim))
		return;
	
	set_pev(victim, pev_solid, SOLID_NOT)
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(victim, pev_deadflag, DEAD_DYING)
	set_pev(victim, pev_effects, pev(victim, pev_effects) & ~EF_NODRAW)
	
	log_to_file("addons/amxmodx/logs/oberon.log", "Remove Boss");
}

public DamageBonus() {
	if(damage_bonus)
		return;
		
	damage_bonus = true;
		
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
	if(drop_gifts)
		return;
		
	log_to_file("addons/amxmodx/logs/oberon.log", "Drop Gifts");
		
	drop_gifts = true;
	
	new Float:colors[3]
	new Gifts = floatround(float(get_playersnum())/1.5, floatround_round)
	for (new i; i < Gifts; ++i) {
		new Float:Vector[3]
		pev(Ent, pev_origin, Vector)
		
		new Gift = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
		set_pev(Gift, pev_classname, "package")
		//engfunc(EngFunc_SetSize, Gift, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,25.0}) 
		engfunc(EngFunc_SetSize, Gift, {-1.1, -1.1, -1.1},{1.1, 1.1, 1.1})
		engfunc(EngFunc_SetModel, Gift, Resource[13])
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
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, SoundList[16], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	return HAM_IGNORED
}

public ResetMessage(id)
	Gift_Message[id] = false

public Respawn(id){
	id -= TASK_RESPAWN
	if(is_user_connected(id))
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public Hook_Spawn(id) {	
	if(!pev_valid(g_Oberon))
		return PLUGIN_CONTINUE
	if (pev(g_Oberon, pev_button) == 0) {
		if(pev(g_Oberon, pev_takedamage) == DAMAGE_NO)	
			client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[13])
		else
			client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[15])
	} 
	else 
		client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[14])
	return PLUGIN_CONTINUE
}

public Hook_BloodColor(Ent) {
	if (!is_boss_valid(Ent))
		return HAM_IGNORED
		
	SetHamReturnInteger(blood_color)
	return HAM_SUPERCEDE
}

public Bomb_UnFrozen(taskid) {
	new id = taskid - 7512
	set_rendering(id)
	if(pev(id, pev_flags) & FL_FROZEN) set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
}

public MapEvent() 
{
	e_boss = engfunc(EngFunc_FindEntityByString, e_boss, "targetname", "boss")
	set_pev(e_boss, pev_classname, "OberonTimer")
	set_pev(e_boss, pev_nextthink, get_gametime() + 1.0)
	log_to_file("addons/amxmodx/logs/oberon.log", "Map Event");
}

boss_damage(victim, damage, color[3]) {
	if (pev(victim, pev_health) - float(damage) <= 0)
		ExecuteHamB(Ham_Killed, victim, victim, 2)
	else {
		ExecuteHamB(Ham_TakeDamage, victim, 0, victim, float(damage), DMG_BLAST)
		ScreenFade(victim, 6, 0, color, 130, 1)
		ScreenShake(victim, ((1<<12) * 8), ((2<<12) * 7))
	}
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
				else if (equal(key, "BLOOD_COLOR"))
					blood_color = str_to_num(value)
			}
			case 2: {
				if (equal(key, "NORMAL_SPEED"))
					speed_boss = str_to_num(value)
				else if (equal(key, "DMG_MAX"))
					dmg_attack_max = str_to_num(value)  
				else if (equal(key, "DMG_NORMAL"))
					dmg_attack = str_to_num(value)
				else if (equal(key, "DMG_BOMB"))
					bomb_damage = str_to_num(value)
				else if (equal(key, "DMG_HOLE"))
					hole_dmg = str_to_num(value)
				else if (equal(key, "DMG_JUMP"))
					jump_damage = str_to_num(value)
				else if (equal(key, "DIST_JUMP"))
					jump_distance = str_to_num(value)
				else if (equal(key, "NTIME_ABILITY"))
					time_ability = str_to_num(value)
			}
			case 3: {
				if (equal(key, "AGR_SPEED"))
					speed_boss_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_BOMB"))
					bomb_damage_agr = str_to_num(value)  
				else if (equal(key, "AGR_DMG_HOLE"))
					hole_dmg_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_JUMP"))
					jump_damage_agr = str_to_num(value)
				else if (equal(key, "ATIME_ABILITY"))
					time_ability_agr = str_to_num(value)
			}
			case 4: {
				if (equal(key, "BOMB_DIST"))
					bomb_dist = float(str_to_num(value))
				#if defined BOMB_CUSTOM
				else if (equal(key, "BOMB_DMG_MIND"))
					bomb_mind = str_to_num(value)
				else if (equal(key, "BOMB_DMG_POISON"))
					bomb_poison = float(str_to_num(value))
				else if (equal(key, "BOMB_POISON_LIFE"))
					bomb_poison_life = str_to_num(value)
				else if (equal(key, "BOMB_FROZEN_TIME"))
					bomb_frozen_time = float(str_to_num(value))
				#endif
			}
			case 5: {
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
 
 /*========================
// STOCK 
========================*/

stock Move(Start, End, Float:speed, Float:Velocity[], Float:Angles[]) {
	new Float:Origin[3], Float:Origin2[3], Float:Angle[3], Float:Vector[3], Float:Len
	pev(Start, pev_origin, Origin2)
	pev(End, pev_origin, Origin)
	xs_vec_sub(Origin, Origin2, Vector)
	Len = xs_vec_len(Vector)
	vector_to_angle(Vector, Angle)
	Angles[0] = 0.0
	Angles[1] = Angle[1]
	Angles[2] = 0.0
	xs_vec_normalize(Vector, Vector)
	xs_vec_mul_scalar(Vector, speed, Velocity)
	return floatround(Len, floatround_round)
}
		
stock Anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}

stock PlayerHp(hp) {
	new Count, Hp
	for(new id = 1; id <= get_maxplayers(); id++)
		if (is_user_connected(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	return Hp
}

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[]) {
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
    
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_angles, vAngle) // if normal entity ,use pev_angles
    
	engfunc(EngFunc_AngleVectors, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
    
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock Smoke(Float:Origin[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_FIREFIELD)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 10)
	write_short(150)
	write_short(g_Resource[10])
	write_byte(100)
	write_byte(TEFIRE_FLAG_ALLFLOAT | TEFIRE_FLAG_ALPHA)
	write_byte(30)
	message_end()
}

expl(Float:Origin[3], scale19, Colors[3], Msg, SprIndex) {
	if(!is_valid_ent(g_Oberon))
		return
		
	static victim = -1
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])  
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Resource[SprIndex])
	write_byte(scale19)
	write_byte(20)
	write_byte(0)
	message_end()
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
		if(is_user_alive(victim)) {
			#if defined BOMB_CUSTOM
			switch (g_Color) {
				case 1: boss_damage(victim, bomb_mind, Colors)
				default: boss_damage(victim, pev(g_Oberon, pev_button) ? bomb_damage_agr : bomb_damage, Colors)
			}
			#else
			boss_damage(victim, Agr ? bomb_damage_agr : bomb_damage, Colors)
			#endif
			if (Msg) DmgMsg(Origin, victim, Msg)
		}
	}
	Light(Origin, 6, 40, 60, Colors)
}

stock ScreenShake(id, duration, frequency) {	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, get_user_msgid("ScreenShake"), _, id ? id : 0);
	write_short(1<<14)
	write_short(duration)
	write_short(frequency)
	message_end();
}

stock ScreenFade(id, Timer, FadeTime, Colors[3], Alpha, type) {
	if(id) if(!is_user_connected(id)) return

	if (Timer > 0xFFFF) Timer = 0xFFFF
	if (FadeTime <= 0) FadeTime = 4
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short(Timer * 1 << 12)
	write_short(FadeTime * 1 << 12)
	switch (type) {
		case 1: write_short(0x0000)		// IN ( FFADE_IN )
		case 2: write_short(0x0001)		// OUT ( FFADE_OUT )
		case 3: write_short(0x0002)		// MODULATE ( FFADE_MODULATE )
		case 4: write_short(0x0004)		// STAYOUT ( FFADE_STAYOUT )
		default: write_short(0x0001)
	}
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}

stock Light(Float:Origin[3], Time, Radius, Rate, Colors[3]) {		
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // x
	engfunc(EngFunc_WriteCoord, Origin[1]) // y
	engfunc(EngFunc_WriteCoord, Origin[2]) // z
	write_byte(Radius) // radius
	write_byte(Colors[0]) // r
	write_byte(Colors[1]) // g
	write_byte(Colors[2]) // b
	write_byte(10 * Time) //life
	write_byte(Rate) //decay rate
	message_end()
}

stock DmgMsg(Float:Origin[3], victim, Msg) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), {0,0,0}, victim)
	write_byte(0)
	write_byte(100)
	write_long((1<<1))
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	message_end()
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), {0,0,0}, victim)
	write_byte(0)
	write_byte(1)
	write_long(Msg)
	write_coord(0)
	write_coord(0)
	write_coord(0)
	message_end()
}

stock Wreck(Float:Origin[3], Size[3], Velocity[3], RandomVelocity, Num, Life, Flag) {			
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0]) // Pos.X
	engfunc(EngFunc_WriteCoord, Origin[1]) // Pos Y
	engfunc(EngFunc_WriteCoord, Origin[2]) // Pos.Z
	engfunc(EngFunc_WriteCoord, Size[0]) // Size X
	engfunc(EngFunc_WriteCoord, Size[1]) // Size Y
	engfunc(EngFunc_WriteCoord, Size[2]) // Size Z
	engfunc(EngFunc_WriteCoord, Velocity[0]) // Velocity X
	engfunc(EngFunc_WriteCoord, Velocity[1]) // Velocity Y
	engfunc(EngFunc_WriteCoord, Velocity[2]) // Velocity Z
	write_byte(RandomVelocity) // Random velocity
	write_short(g_Resource[9]) // Model/Sprite index
	write_byte(Num) // Num
	write_byte(Life) // Life
	write_byte(Flag) // Flags ( 0x02 )
	message_end()
}

stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, RGB[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Orig[0]) // x
	engfunc(EngFunc_WriteCoord, Orig[1]) // y
	engfunc(EngFunc_WriteCoord, Orig[2]-40.0) // z
	engfunc(EngFunc_WriteCoord, Orig[0]) // x axis
	engfunc(EngFunc_WriteCoord, Orig[1]) // y axis
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius) // z axis
	write_short(g_Resource[11]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(Life) // life (4)
	write_byte(Width) // width (20)
	write_byte(0) // noise
	write_byte(RGB[0]) // red
	write_byte(RGB[1]) // green
	write_byte(RGB[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}

stock Float:distance_to_floor(Float:start[3], ignoremonsters = 1) {
    new Float:dest[3], Float:end[3];
    dest[0] = start[0];
    dest[1] = start[1];
    dest[2] = -8191.0;

    engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, 0, 0);
    get_tr2(0, TR_vecEndPos, end);

    //pev(index, pev_absmin, start);
    new Float:ret = start[2] - end[2];

    return ret > 0 ? ret : 0.0;
}

public get_random_player() {
	new Index
	Index = GetRandomAlive(random_num(1, get_player_alive()))
	return Index
}

public get_player_alive() {
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
	return iAlive
}

GetRandomAlive(target_index) {
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) {
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
		if (iAlive == target_index) 
			return id
	}
	return -1
}

public is_boss_valid(index) {
	new ClassName[32]
	pev(index, pev_classname, ClassName, charsmax(ClassName))

	if (equal(ClassName, "OberonBoss")) return 1

	return 0
}

stock Sound(Ent, Sounds) engfunc(EngFunc_EmitSound, Ent, CHAN_AUTO, SoundList[_:Sounds], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
