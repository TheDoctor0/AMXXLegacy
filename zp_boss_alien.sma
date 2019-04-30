// Босс скачан с сайта Zombie-Mod.ru
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <xs>

#define PLUGIN "[ZP] Alien Boss"
#define VERSION "3.1"
#define AUTHOR "Remake muxaz & O'Zone"

#define ANIM_DUMMY 0
#define ANIM_DEATH 1
#define ANIM_IDLE 2
#define ANIM_WALK 3
#define ANIM_RUN 4
#define ANIM_SHOCKWAVE 5
#define ANIM_JUSTICESWING 6
#define ANIM_MAHADASH 7

#define ALIEN_ATTACK_DELAY 1.0 // Промежуток между атаками Босса
#define ALIEN_ATTACK_DISTANCE 160.0 // Дистанция для атаки Босса
#define ALIEN_DASH_DISTANCE 200.0 // Дистанция на каторую Босс прыгает

#define ALIEN_JUMP_AFTER_SWING_COUNT 4 // Отсчет между скиллами

#define ALIEN_TASK 231211
#define ALIEN_TASK1 113713
#define ALIEN_TASK2 123714
#define ALIEN_TASK3 133715
#define ALIEN_TASK4 143716

// Agression one - 1-ый уровенить агресси
#define ALIEN_SPEED_AG1 220 // Скорость Босса при 1 агрессии
#define ALIEN_DAMAGE_ATTACK_AG1 35.0 // Урон Босса при 1 агрессии
#define ALIEN_DASH_DAMAGE_AG1 75 // Урон Босса при использование скилла в 1 агрессии
#define ALIEN_SHOCK_SCREEN_RADIUS_AGRES1 800 // Радиус тряски и урона при волне в 1 агрессии
#define ALIEN_SHOCK_SCREEN_DAMAGE_AGRES1 50 // Урон от волны в 1 агрессии

// Agression two - 2-ой уровень агресси когда мень 50 % жизни у алиена
#define ALIEN_SPEED_AG2	250 // Скорость Босса при 2 агрессии
#define ALIEN_DAMAGE_ATTACK_AG2 50.0 // Урон Босса при 2 агрессии
#define ALIEN_DASH_DAMAGE_AG2 100 // Урон Босса при использование скилла в 2 агрессии
#define ALIEN_SHOCK_SCREEN_RADIUS_AGRES2 500 // Радиус тряски и урона при волне в 1 агрессии
#define ALIEN_SHOCK_SCREEN_DAMAGE_AGRES2 200 // Урон от волны в 2 агрессии

#define boss_classname 	"boss_alien"

new const BossName[] = "Alien";
new const BossMap[] = "zp_boss_alien";

new const AlienResource[][] = {
	"models/zp/boss/boss_alien.mdl",
	"models/zp/boss/package.mdl",
	"sprites/zp/boss/boss_health.spr",
	"sprites/blood.spr",
	"sprites/bloodspray.spr",
	"sprites/shockwave.spr"
}

static g_AlienResource[sizeof AlienResource]

new const g_AlienSound[][] = 
{ 
	"zp/boss/boss_death.wav",
	"zp/boss/boss_dash.wav",
	"zp/boss/boss_swing.wav",
	"zp/boss/boss_shokwave.wav",
	"zp/boss/package_get.wav"
}

enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

new Float:g_dmg
new Float:g_distance
new Float:g_lastat
new Float:g_atdelay
new g_speed
new g_moves
new bool:g_alive
new g_target
new g_animrun
new g_animattack
new g_ability
new g_timer
new g_game_start
new g_can_jump
new g_maxplayers
new g_pSprite
new g_jump_count
new bool:start_swing
new bool:start_knock
new bool:g_bAlienLevel
new g_screenshake
new const UNIT_SECOND = (1<<12)

#define TASK_CREATE_NPC 	123124
#define ALIEN_CREATE_TASK 	21341
#define TASK_MAPEVENT 58493
#define TASK_RESPAWN 58431
new g_iRandomSkills = ALIEN_JUMP_AFTER_SWING_COUNT;

new const FILE_SETTING[] = "zp_boss_alien.ini"
new boss_heal, boss_health, prepare_time, best_exp, gift_min_ap, gift_max_ap, gift_min_exp, gift_max_exp

new Float:Damage_Taken[33]
new bool:Gift_Taken[33]
new bool:Gift_Message[33]

native zp_register_boss(const name[], const map[]);
native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id, amount)
native zp_add_user_exp(id, amount)

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Killed, "info_target", "npc_killed");
	RegisterHam(Ham_Killed, "player", "player_killed");
	RegisterHam(Ham_Think, "info_target", "npc_think");
	RegisterHam(Ham_TraceAttack, "info_target", "npc_traceattack");
	RegisterHam(Ham_TakeDamage, "info_target", "npc_takedamage");

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_Touch, "TouchPackage");

	register_event("DeathMsg", "event_death", "ae");

	register_clcmd("+attack", "block", g_timer)

	g_screenshake = get_user_msgid("ScreenShake");
	
	g_maxplayers = get_maxplayers();
	
	zp_register_boss(BossName, BossMap);
	
	set_task(1.0, "MapEvent", TASK_MAPEVENT);
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
		for(new i = 0; i < sizeof AlienResource; i++)
			g_AlienResource[i] = precache_model(AlienResource[i])
			
		for(new i = 0 ; i < sizeof g_AlienSound ; i++) 
			precache_sound(g_AlienSound[i]); 
	}
}

public PauseBoss()
	pause("ad");

public MapEvent() 
{
	if(!get_player_alive()) 
	{
		set_task(1.0, "MapEvent", TASK_MAPEVENT);
		return
	}
	else
	{
		remove_task(TASK_MAPEVENT);
		
		set_task(1.0, "spawn_alien", TASK_CREATE_NPC);
		
		return
	}
}

public block(id) 
	return PLUGIN_HANDLED;

public client_connect(id){
	Damage_Taken[id] = 0.0
}

public spawn_alien()
{	
	g_timer = prepare_time //26
	set_task(1.0, "count_start", ALIEN_TASK)
	
	set_task(float(prepare_time), "create_alien", ALIEN_CREATE_TASK);
}

public create_alien()
{
	g_pSprite = create_entity("info_target");
	
	entity_set_model(g_pSprite, AlienResource[2]);
	
	entity_set_int(g_pSprite, EV_INT_rendermode, kRenderTransTexture);
	entity_set_float(g_pSprite, EV_FL_renderamt, 0.0);
		
	new Float:origin[3];
	
	// Origins for center map
	origin[0] = -27.0
	origin[0] = 24.0
	origin[2] = 460.0

	origin[1] += 50.0
	
	new ent = npc_alien_spawn(1);
	 
	set_pev(ent, pev_origin, origin);
	
	start_swing = false
	start_knock = false
	g_ability = false
	g_game_start = false
	g_jump_count = 0
	
	origin[2] += 250;
	
	entity_set_origin(g_pSprite, origin);
	
	entity_set_int(g_pSprite, EV_INT_rendermode, kRenderNormal);
	entity_set_float(g_pSprite, EV_FL_renderamt, 16.0);
	
	entity_set_float(g_pSprite, EV_FL_frame, 100.0);
	
	g_game_start = true;
}

public npc_alien_spawn(anim_run)
{
	new ent = create_entity("info_target"); 
	
	if(!ent) return 0;
	
	entity_set_string(ent, EV_SZ_classname, boss_classname);
	entity_set_model(ent, AlienResource[0]);
	
	entity_set_int(ent, EV_INT_iuser4, 0); 
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX); 
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP); 
	
	entity_set_float(ent, EV_FL_takedamage, 1.0);
	entity_set_float(ent, EV_FL_gravity, 1.0);
	entity_set_float(ent, EV_FL_health, float(PlayerHp(boss_heal)));
	entity_set_float(ent, EV_FL_animtime, get_gametime());
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0) 
	
	Util_PlayAnimation(ent, ANIM_SHOCKWAVE);

	new Float: maxs[3] = { 16.0, 16.0, 60.0 }
	new Float: mins[3] = {-16.0, -16.0, -36.0} 

	entity_set_size(ent, mins, maxs)

	g_alive = true
	g_dmg = ALIEN_DAMAGE_ATTACK_AG1
	g_animrun = ANIM_RUN
	g_speed = ALIEN_SPEED_AG1
	g_distance = ALIEN_ATTACK_DISTANCE
	g_atdelay = ALIEN_ATTACK_DELAY
	g_lastat = 0.0
	g_target = find_closes_enemy(ent)

	set_task(1.0, "update_target", ent, .flags="b")

	return ent;
}

public npc_think(ent) 
{ 
	if(!is_valid_ent(ent)) 
		return; 

	static className[32], animation; 
	animation = 0;
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname))
		return; 
	
	if (!g_bAlienLevel)
		if (entity_get_float(ent, EV_FL_health) <= (boss_health / 2.0))
		{
			g_bAlienLevel = true;
			
			g_speed = ALIEN_SPEED_AG2;
			g_dmg = ALIEN_DAMAGE_ATTACK_AG2;
		}
	
	if(g_alive)
	{
		new Float:vecOrigin[3];
		
		entity_get_vector(ent, EV_VEC_origin, vecOrigin);
		
		vecOrigin[2] += 250;
		
		entity_set_origin(g_pSprite, vecOrigin);
		
		if(g_game_start)
		{
			new Float:velocity[3]
			pev(ent,pev_velocity,velocity)
			velocity[0] += velocity[1] + velocity[2]

			if(!is_user_alive(g_target))
				g_target = find_closes_enemy(ent)
		
			new Float:angle[3], Float:zmaim[3]
			pev(g_target, pev_origin, zmaim)
			aim_at_origin(ent, zmaim, angle)
			angle[0] = 0.0
			entity_set_vector(ent, EV_VEC_angles, angle)

			if(g_target)
			{
				new Float:origins[3]
				pev(ent, pev_origin, origins)
				new Float:flDistance = get_distance_f(origins, zmaim)
 
				if(flDistance> 170.0)
				{
					if(g_moves)
					{
						zmaim[0] += random_num(1, -1) * 80.0
						zmaim[1] += random_num(1, -1) * 80.0
						g_moves -= 1
					}
					else if(!g_moves && random_num(1, 5) == 1)
						g_moves = 20
				}
				if(flDistance <= ALIEN_ATTACK_DISTANCE) g_moves = 0
				if(flDistance <= g_distance && get_gametime() - g_lastat > g_atdelay)
				{
					if(!start_swing && !start_knock)
					{
						g_lastat = get_gametime()
		
						new anim = ANIM_JUSTICESWING

						Util_PlayAnimation(ent, ANIM_IDLE)
						Util_PlayAnimation(ent, anim)
						
						ExecuteHamB(Ham_TakeDamage, g_target, 0, g_target, g_dmg, DMG_BLAST);
						
						set_task(2.0, "reset_swing", ent + ALIEN_TASK3)
						start_swing = true
						g_animattack = anim
					
						if(anim == ANIM_JUSTICESWING)
							emit_sound(ent, CHAN_VOICE, g_AlienSound[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					
						if(g_jump_count < g_iRandomSkills)
							g_jump_count++
					}
				}
				else
				{				
					new Float:frames
					if(g_animattack == ANIM_JUSTICESWING) frames = 1.5
		
					if(get_gametime() - g_lastat > frames)
					{
						if(flDistance <= g_distance)
							Util_PlayAnimation(ent, ANIM_IDLE)
						else
						{
							if(g_jump_count == g_iRandomSkills && flDistance <= 400.0)
							{
								// change skill delay
								g_iRandomSkills = random_num(2,4);
								
								if(!task_exists(ent + ALIEN_TASK2) && !task_exists(ent + ALIEN_TASK1))
								{
									new task_args[4]
									task_args[0] = ent
									task_args[1] = floatround(zmaim[0]*100000, floatround_floor)
									task_args[2] = floatround(zmaim[1]*100000, floatround_floor)
									task_args[3] = floatround(zmaim[2]*100000, floatround_floor)
								
									if(!g_ability)
									{
										g_ability = true
										Util_PlayAnimation(ent, ANIM_MAHADASH)
										emit_sound(ent, CHAN_VOICE, g_AlienSound[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
								
										set_task(0.8, "go_jump", ent + ALIEN_TASK1, task_args, 4)
										
										animation = 1;
									}
									else
									{
										if (entity_get_float(ent, EV_FL_health) > (boss_health / 2))
										{
											Util_PlayAnimation(ent, ANIM_SHOCKWAVE)
											start_knock = true
											set_task(2.1, "go_knock_agres1", ent + ALIEN_TASK1, task_args, 4)
										}
										else if (entity_get_float(ent, EV_FL_health) <= (boss_health / 2))
										{
											Util_PlayAnimation(ent, ANIM_SHOCKWAVE)
											start_knock = true
											set_task(2.1, "go_knock_agres2", ent + ALIEN_TASK1, task_args, 4)
										}
										
										animation = 2;
									}
								}
							}
							else
							{
								ent_move_to(ent, zmaim, g_speed)
								Util_PlayAnimation(ent, g_animrun)
							}
						}
					}
				}
			}
			if(!g_target) Util_PlayAnimation(ent, ANIM_IDLE)
		}
		else if(g_can_jump)
			Util_PlayAnimation(ent, ANIM_IDLE)
		else
			Util_PlayAnimation(ent, ANIM_IDLE)
		if(animation == 1)
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.8); 
		else if(animation == 2)
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 2.1); 
		else
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01); 
	}
}

public check_dash_damage(ent, id)
{
	ent -= ALIEN_TASK4
	
	for(new i = 0; i < g_maxplayers; i++)
	{
		if(is_user_alive(i))
		{
			new Float:range_distance = entity_range(ent, i)
			
			if(ALIEN_DASH_DISTANCE < floatround(range_distance) < ALIEN_ATTACK_DISTANCE)
			{			
				if (g_bAlienLevel)
					ExecuteHamB(Ham_TakeDamage, i, 0, i, ALIEN_DASH_DAMAGE_AG2, DMG_BLAST)
				else
					ExecuteHamB(Ham_TakeDamage, i, 0, i, ALIEN_DASH_DAMAGE_AG1, DMG_BLAST)
			}
		}
	}
}

public go_knock_agres1(args[], id)
{
	new ent = args[0]
	new Float:origin[3]
	
	pev(ent,pev_origin,origin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMCYLINDER)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])-16)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(0.0))
	write_short(g_AlienResource[5]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(25) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(255) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
        emit_sound(ent, CHAN_VOICE, g_AlienSound[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(1.0, "reset_knock", ent + ALIEN_TASK2)

	static Float:flOrigin[3] , Float:flDistance , Float:flSpeed
	for(new iVictim=1;iVictim <= 32;iVictim++)
	{
		if(is_user_connected(iVictim) && is_user_alive(iVictim))
		{
			pev(iVictim, pev_origin, flOrigin)
			flDistance = get_distance_f ( origin, flOrigin )   

			if(flDistance <= ALIEN_SHOCK_SCREEN_RADIUS_AGRES1)
			{
				ScreenShake(iVictim)

				flSpeed = 1400.0
               
				static Float:flNewSpeed
				flNewSpeed = flSpeed * ( 1.0 - ( flDistance / 1000.0 ) )
				ExecuteHamB(Ham_TakeDamage, iVictim, 0, iVictim,  ALIEN_SHOCK_SCREEN_DAMAGE_AGRES1, DMG_SONIC)
               
				static Float:flVelocity [ 3 ]
				get_speed_vector ( origin, flOrigin, flNewSpeed, flVelocity )
               
				set_pev ( iVictim, pev_velocity,flVelocity )
			}
		}
	}
}

public go_knock_agres2(args[], id)
{
	new ent = args[0]
	new Float:origin[3]
	
	pev(ent,pev_origin,origin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMCYLINDER)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])-16)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(0.0))
	write_short(g_AlienResource[5]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(10) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(250) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
        emit_sound(ent, CHAN_VOICE, g_AlienSound[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(1.0, "reset_knock", ent + ALIEN_TASK2)

	static Float:flOrigin[3] , Float:flDistance , Float:flSpeed
	for(new iVictim=1;iVictim <= 32;iVictim++)
	{
		if(is_user_connected(iVictim) && is_user_alive(iVictim))
		{
			pev(iVictim, pev_origin, flOrigin)
			flDistance = get_distance_f ( origin, flOrigin )   

			if(flDistance <= ALIEN_SHOCK_SCREEN_RADIUS_AGRES2)
			{
				ScreenShake(iVictim)

				flSpeed = 1400.0
               
				static Float:flNewSpeed
				flNewSpeed = flSpeed * ( 1.0 - ( flDistance / 1000.0 ) )
				ExecuteHamB(Ham_TakeDamage, iVictim, 0, iVictim, ALIEN_SHOCK_SCREEN_DAMAGE_AGRES2, DMG_SONIC)
               
				static Float:flVelocity [ 3 ]
				get_speed_vector ( origin, flOrigin, flNewSpeed, flVelocity )
               
				set_pev ( iVictim, pev_velocity,flVelocity )
			}
		}
	}
}

public ScreenShake(id)
{
	if(!is_user_alive(id))
		return;

	message_begin(MSG_ONE_UNRELIABLE, g_screenshake, _, id)
	write_short(UNIT_SECOND*7) // amplitude
	write_short(UNIT_SECOND*5) // duration
	write_short(UNIT_SECOND*15) // frequency
	message_end()
}

public reset_knock(ent)
{
	ent = ent - ALIEN_TASK2
	
	start_knock = false
	g_ability = false
	g_jump_count = 0
}

public go_jump(args[])
{
	new ent = args[0]
	new Float:zmaim[3]
	
	zmaim[0]=float(args[1]/100000)
	zmaim[1]=float(args[2]/100000)
	zmaim[2]=float(args[3]/100000)
	
	ent_jump_to(ent, zmaim, 1700)
	
	g_can_jump = true
	
	set_task(0.6, "check_dash_damage", ent + ALIEN_TASK4)
	set_task(1.4, "reset_jump", ent + ALIEN_TASK2)
}

public reset_swing(ent)
{
	ent = ent - ALIEN_TASK3
	start_swing = false
}

public reset_jump(ent)
{
	ent = ent - ALIEN_TASK2
	g_jump_count = 0
	set_task(0.5, "reset_time", ent + 55555)
}

public reset_time()
	g_can_jump = false
	
public npc_takedamage(ent, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_alive(attacker) || !is_valid_ent(ent))
		return;

	new className[32]; 
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname) || !g_alive) 
		return; 
	
	Damage_Taken[attacker] += damage;
	
	entity_set_float(g_pSprite, EV_FL_frame, entity_get_float(ent, EV_FL_health) / (boss_health / 100.0));
}

public fw_PlayerPreThink(id)
{
	if(is_user_connected(id))
	{
		if(cs_get_user_team(id) == CS_TEAM_T) 
			cs_set_user_team(id, CS_TEAM_CT)
	}
}

public npc_traceattack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits) 
{ 
	if(!is_valid_ent(ent) || !g_alive) 
		return; 

	new className[32]; 
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname) || !g_alive) 
		return; 

	new Float: end[3] 
	get_tr2(trace, TR_vecEndPos, end); 

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE) 
	engfunc(EngFunc_WriteCoord, end[0]) 
	engfunc(EngFunc_WriteCoord, end[1]) 
	engfunc(EngFunc_WriteCoord, end[2]) 
	write_short(g_AlienResource[3]) 
	write_short(g_AlienResource[4]) 
	write_byte(247)
	write_byte(random_num(5, 10))
	message_end() 
}

public player_killed(victim, attacker) 
{	
	if(get_user_team(victim) == 1 || get_user_team(victim) == 2)
		set_task(5.0, "Respawn", victim + TASK_RESPAWN)
}

public npc_killed(ent, attacker) 
{ 
	new className[32]; 
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className)) 

	if(!equali(className, boss_classname) || !g_alive) 
		return HAM_IGNORED; 

	g_alive = false
	Util_PlayAnimation(ent, ANIM_DEATH); 
	emit_sound(ent, CHAN_VOICE, g_AlienSound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM) 
	remove_task(ent)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_task(4.5, "npc_remove", ent)

	entity_set_int(ent, EV_INT_iuser4, 1); 
	
	entity_set_int(g_pSprite, EV_INT_rendermode, kRenderTransTexture);
	entity_set_float(g_pSprite, EV_FL_renderamt, 0.0);
	
	server_cmd("umc_onlynextround 0");
	server_cmd("umc_startvote");
	
	DropGifts(ent)
	
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Boss zostal^x04 zabity^x01! Wypadly z niego paczki z^x04 expem^x01 i^x04 AP^x01!")
	client_print_color(0, print_team_red, "^x03[BOSS]^x01 Zaraz nastapi glosowanie o kolejna mape!")
	DamageBonus()

	return HAM_SUPERCEDE;
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
	new Float:colors[3]
	new Gifts = floatround(float(get_playersnum())/1.5, floatround_round)
	for (new i; i < Gifts; ++i) {
		new Float:Vector[3]
		pev(Ent, pev_origin, Vector)
		
		new Gift = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
		set_pev(Gift, pev_classname, "package")
		//engfunc(EngFunc_SetSize, Gift, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,25.0}) 
		engfunc(EngFunc_SetSize, Gift, {-1.1, -1.1, -1.1},{1.1, 1.1, 1.1})
		engfunc(EngFunc_SetModel, Gift, AlienResource[1])
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
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, g_AlienSound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
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

public event_death(id)
{
	static ent = -1;
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", boss_classname)) != 0)
	{
		if(g_target == id)
			g_target = find_closes_enemy(ent)
	}
	
	return PLUGIN_CONTINUE;
}

public npc_remove(ent) 
{	
	remove_task(ALIEN_TASK)
	remove_task(ALIEN_TASK1)
	remove_task(ALIEN_TASK2)
	remove_task(ALIEN_TASK3)
	remove_task(ALIEN_TASK4)
	
	remove_entity(ent)
	remove_task(ent)
	
	g_jump_count = 0
	g_game_start = false
}

public count_start(task)
{
	if(g_game_start)
		return
		
	g_timer--
	
	if(g_timer > 0)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.30, 1, 5.0, 5.0)
		show_hudmessage(0, "Alien pojawi sie za %d sekund", g_timer)
		//client_print(0, print_center, "Alien pojawi sie za %d sekund", g_timer)
	}
	
	if(g_timer < 11)
		client_cmd(0, "spk zp/boss/vox/%d", g_timer)
	
	if(g_timer >= 0)
		set_task(1.0, "count_start", ALIEN_TASK)
		
	if(g_timer == 0)
	{
		client_print_color(0, print_team_red, "^x03[BOSS]^x01 Pamietajcie, aby trzymac Bossa jak najblizej srodka mapy! Powodzenia!")
		g_game_start = true
	}
}

public update_target(ent)
{
	if(!is_valid_ent(ent))
		return;

	g_target = find_closes_enemy(ent)
}

stock find_closes_enemy(ent)
{
	new enemy, Float:dist, Float:distmin, Float:origin[3], Float:originT[3]
	pev(ent, pev_origin, origin)
	origin[2] += 120.0
	
	for(new id=1; id<=32; id++)
	{
		if (!is_user_alive(id)) continue;

		dist = entity_range(ent, id)
		pev(id, pev_origin, originT)
		if ((!distmin || dist <= distmin))
		{
			distmin = dist
			enemy = id
		}
	}	

	return enemy
}

stock ent_move_to(ent, Float:target[3], speed)
{
	static Float:vec[3]
	aim_at_origin(ent, target, vec)
	engfunc(EngFunc_MakeVectors, vec)
	global_get(glb_v_forward, vec)
	vec[0] *= speed
	vec[1] *= speed
	vec[2] *= speed * 0.1
	set_pev(ent, pev_velocity, vec)
		
	new Float:angle[3]
	aim_at_origin(ent, target, angle)
	angle[0] = 0.0
	entity_set_vector(ent, EV_VEC_angles, angle)
}

stock ent_jump_to(ent, Float:target[3], speed)
{
	static Float:vec[3]
	aim_at_origin(ent, target, vec)
	engfunc(EngFunc_MakeVectors, vec)
	global_get(glb_v_forward, vec)
	vec[0] *= speed
	vec[1] *= speed
	vec[2] *= speed * 0.1
	set_pev(ent, pev_velocity, vec)
		
	new Float:angle[3]
	aim_at_origin(ent, target, angle)
	angle[0] = 0.0
	entity_set_vector(ent, EV_VEC_angles, angle)
	
}

stock aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id, pev_origin, vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles, vec, angles)
	angles[0] *= -1.0, angles[2] = 0.0
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
       
	return 1;
} 

stock Util_PlayAnimation(index, sequence, Float: framerate = 1.0) 
{ 
	if(entity_get_int(index, EV_INT_sequence) == sequence) return;

	entity_set_float(index, EV_FL_animtime, get_gametime()); 
	entity_set_float(index, EV_FL_framerate, framerate); 
	entity_set_float(index, EV_FL_frame, 0.0); 
	entity_set_int(index, EV_INT_sequence, sequence); 
} 

stock bool:is_hull_vacant(const Float:origin[3], hull,id) 
{
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
	return true

	return false
}

stock PlayerHp(hp) {
	new Count, Hp
	for(new id = 1; id <= get_maxplayers(); id++)
		if (is_user_connected(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	
	boss_health = Hp;
	
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
