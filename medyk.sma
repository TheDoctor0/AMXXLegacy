#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define EIM_SND_VOL 1.0

//DO NOT CHANGE THESE DEFINES:
#define MAX_PLAYERS 32
#define PTR_LC 0  //cell used to indicate last used cell on g_list_*
#define SOUND_TIME 0.8
#define UPDATE_TIME 0.3
#define CPHU 2 //checks per HUD update

#define NO_TARGET 0
#define NO_HEALERS 0
#define NO_HEAL_POINTS 0.0
#define NO_DAMAGE 0.0

#define EIM_SND_NONE 0
#define EIM_SND_START 1
#define EIM_SND_HEALING 2
#define EIM_SND_UNABLE 3
////////////////////////////////


#define _Is(%1,%2) (%1&1<<%2)
#define _Set(%1,%2) %1|=1<<%2
#define _UnSet(%1,%2) %1&=~(1<<%2)
#define _Clear(%1) %1 = 0
new _alive, _medic, _bot

new g_max_players
new g_fpc = 30   //frames per check, there is check every g_fps server frames if time passed is correct

new Float:g_p_distance[MAX_PLAYERS+1]
new g_p_aiming_at[MAX_PLAYERS+1]
new g_p_target[MAX_PLAYERS+1]
new g_p_healers[MAX_PLAYERS+1]
new Float:g_p_points[MAX_PLAYERS+1]
new Float:g_p_dmg[MAX_PLAYERS+1]
new Float:g_p_start_hp[MAX_PLAYERS+1]
new Float:g_p_max_hp[MAX_PLAYERS+1]

new g_p_team[MAX_PLAYERS+1]

//player is on g_list_healers if g_p_target[player] != NO_TARGET
new g_list_healers[MAX_PLAYERS+1]

//player is on g_list_sounds if g_snd_frames[player] != 0
new g_list_sounds[MAX_PLAYERS+1]
new g_snd_frames[MAX_PLAYERS+1]
new g_snd_next[MAX_PLAYERS+1]
new g_snd_current[MAX_PLAYERS+1]
new g_snd_fpc = 30  //frames per check for sounds

new g_sprite

new g_HSO_p_info //hud sync object - player info
new g_HSO_t_info //hud sync object - target info

//pcvars
new pcvar_range  //maximum distance between players required for healing to work
new pcvar_hps   //health per second
new pcvar_maxhealers  //amount of players that can heal 1 player simultaneously
new pcvar_healpoints  //amount of hp that can be healed by player every round
new pcvar_healeff  //healing efficiency  -  fraction of damage that can be healed
new pcvar_in_team  //which team have medics - 0==both
new pcvar_mode //0 - everyone is medic, 1 - one random player is a medic

new g_range
new Float:g_hps 
new g_maxhealers 
new g_healpoints
new Float:g_healeff
new g_in_team  
new g_mode 

new VER[] = {"1.51"}

public plugin_init(){
	register_plugin("EveryoneIsMedic", VER, "Sylwester")
	register_forward(FM_PlayerPreThink, "player_PreThink")
	register_forward(FM_StartFrame, "fwd_StartFrame")

	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_Killed, "player", "player_killed", 0)
	
	g_max_players = get_maxplayers()

	register_cvar("eim_ver", VER, FCVAR_SERVER)
	pcvar_range = register_cvar("eim_range", "70")
	pcvar_hps = register_cvar("eim_hps", "10.0", 0, 10.0)
	pcvar_maxhealers = register_cvar("eim_maxhealers", "2")
	pcvar_healpoints = register_cvar("eim_healpoints", "0")
	pcvar_healeff = register_cvar("eim_healeff", "1.0", 0, 1.0)
	pcvar_in_team = register_cvar("eim_in_team", "0")
	pcvar_mode = register_cvar("eim_mode", "0") 
	//for cs: 1 - ts, 2 - cts

	g_HSO_t_info = CreateHudSyncObj()
	g_HSO_p_info = CreateHudSyncObj()
}


public plugin_precache(){
	precache_sound("items/medshot4.wav")
	precache_sound("items/medcharge5.wav")
	precache_sound("items/medshotno1.wav")
	g_sprite = precache_model("sprites/laserbeam.spr")
}

public fwd_StartFrame(){
	static Float:current_time
	static Float:last_time
	static frames_counter
	static checks_counter
	static i
	static targetid
	static targetbody

	frames_counter++

	if(frames_counter > g_fpc){
		current_time = get_gametime()
		g_fpc = floatround((g_fpc*UPDATE_TIME/(current_time-last_time) + g_fpc)/2)
		g_snd_fpc = floatround((g_fpc/UPDATE_TIME*SOUND_TIME + g_snd_fpc)/2)
		last_time = current_time
		frames_counter = 1

		for(i = 1; i <= g_max_players; i++){
			if(!_Is(_alive, i))
			continue
			g_p_distance[i] = get_user_aiming(i, targetid, targetbody)
			if(g_p_target[i] != NO_TARGET && (targetid != g_p_target[i] || g_p_distance[i] > g_range)){
				stop_healing_process(i)
				g_snd_next[i] = EIM_SND_NONE
			}else if(targetid > g_max_players || targetid < 1 || g_p_team[targetid] != g_p_team[i])
			g_p_aiming_at[i] = 0
			else
			g_p_aiming_at[i] = targetid
			
			check_health(i)
		}

		checks_counter++
		if(checks_counter > CPHU){
			show_info()
			checks_counter = 1
		}
		
		if(g_healpoints == 0)
		heal_targets_uhp(UPDATE_TIME*g_hps) //unlimited heal points
		else
		heal_targets(UPDATE_TIME*g_hps)
	}

	update_sounds()
}


public show_info(){
	static i
	static pos
	static msg[512]
	static targetid
	static button

	for(i=1; i<=g_max_players; i++){
		if(!_Is(_alive, i) || !_Is(_medic, i))
		continue
		set_hudmessage(200, 100, 0, -5.0, 0.20, 0, 6.0, CPHU*UPDATE_TIME, 0.1, 0.2, -1)
		pos = 0
		formatex(msg, 511, "")
		if(g_p_points[i] > NO_HEAL_POINTS)
		pos += formatex(msg[pos], 511-pos, "Punkty zdrowia: %0.f^n", g_p_points[i])
		if(g_p_dmg[i] > NO_DAMAGE)
		pos += formatex(msg[pos], 511-pos, "Obrazenia do uleczenia: %0.f^n", g_p_dmg[i])
		if(g_p_healers[i] > NO_HEALERS){
			pos += formatex(msg[pos], 511-pos, "Aktualni medycy: %d", g_p_healers[i])
			if(g_p_healers[i] >= g_maxhealers)
			pos += formatex(msg[pos], 511-pos, " (MAX)")
		}
		if(pos > 0)
		ShowSyncHudMsg(i, g_HSO_p_info, msg)

		targetid = g_p_aiming_at[i]
		if(targetid){
			if((g_p_points[i] > NO_HEAL_POINTS || g_healpoints == 0)&& g_p_dmg[targetid] > NO_DAMAGE && g_p_target[i] == NO_TARGET){
				if(g_p_distance[i] > g_range){
					button = pev(i, pev_button)
					if(button & IN_USE){
						formatex(msg, 511, "^ngracz jest za daleko")
						set_hudmessage(200, 100, 0, -1.0, 0.45, 0, 6.0, CPHU*UPDATE_TIME, 0.1, 0.2, -1)
						ShowSyncHudMsg(i, g_HSO_t_info, msg)
					}
				}else{
					formatex(msg, 511, "^nWcisnij USE aby uleczyc^n")
					set_hudmessage(200, 100, 0, -1.0, 0.45, 0, 6.0, CPHU*UPDATE_TIME, 0.1, 0.2, -1)
					ShowSyncHudMsg(i, g_HSO_t_info, msg)
				}
			}
		}
	}
}


public sndl_add(&playerid){
	g_list_sounds[PTR_LC]++
	g_list_sounds[g_list_sounds[PTR_LC]] = playerid
}

public sndl_delete(&cell){
	static j
	for(j = cell+1; j<=g_list_sounds[PTR_LC]; j++)
	g_list_sounds[j-1] = g_list_sounds[j]
	g_list_sounds[PTR_LC]--
}


public update_sounds(){
	static i
	static playerid
	i = 1
	while(i<=g_list_sounds[PTR_LC]){
		playerid = g_list_sounds[i]
			
		if(g_snd_frames[playerid] == 0 || g_snd_frames[playerid] >= g_snd_fpc){	
			g_snd_frames[playerid] = 0
			switch(g_snd_next[playerid]){
			case EIM_SND_NONE:{
					if(g_snd_current[playerid] == EIM_SND_HEALING)
					emit_sound(playerid, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
					sndl_delete(i)
					g_snd_current[playerid] = EIM_SND_NONE
				}
			case EIM_SND_START:{
					if(g_p_target[playerid] != NO_TARGET){
						if(g_snd_current[playerid] == EIM_SND_HEALING)
						emit_sound(playerid, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
						emit_sound(playerid, CHAN_STREAM, "items/medshot4.wav", EIM_SND_VOL, ATTN_NORM, 0, PITCH_NORM)
						g_snd_current[playerid] = EIM_SND_START
						g_snd_next[playerid] = EIM_SND_HEALING
						g_snd_frames[playerid]++
						i++
					}else{
						sndl_delete(i)
					}
				}
			case EIM_SND_HEALING:{
					if(g_p_target[playerid] != NO_TARGET){
						if(g_snd_current[playerid] != EIM_SND_HEALING){
							emit_sound(playerid, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, 0, PITCH_NORM)
							g_snd_current[playerid] = EIM_SND_HEALING
						}
						g_snd_frames[playerid]++
						i++
					}else{
						sndl_delete(i)
					}
				}
			case EIM_SND_UNABLE:{
					if(g_snd_current[playerid] == EIM_SND_HEALING)
					emit_sound(playerid, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
					if(g_snd_current[playerid] == EIM_SND_UNABLE){
						g_snd_current[playerid] = EIM_SND_NONE
						g_snd_next[playerid] = EIM_SND_NONE
					}else{
						emit_sound(playerid, CHAN_STREAM, "items/medshotno1.wav", EIM_SND_VOL, ATTN_NORM, 0, PITCH_NORM)
						g_snd_current[playerid] = EIM_SND_UNABLE
						g_snd_next[playerid] = EIM_SND_NONE
					}
					g_snd_frames[playerid]++
					i++
				}
				
			}
		}else{
			g_snd_frames[playerid]++
			i++
		}
	}
}

public heal_targets_uhp(Float:health_amount){  //unlimited heal points
	static healerid
	static targetid
	static Float:targethp
	static i

	i = 1
	while(i <= g_list_healers[PTR_LC]){
		healerid = g_list_healers[i]
		targetid = g_p_target[healerid]
		if(g_p_dmg[targetid] > NO_DAMAGE && _Is(_alive, healerid)){
			pev(targetid, pev_health, targethp)
			if(health_amount < g_p_dmg[targetid]){
				set_pev(targetid, pev_health, targethp + health_amount)
				g_p_dmg[targetid] -= health_amount
				i++
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMENTS); // TE_BEAMENTS 8
				write_short(targetid); // Start entity
				write_short(healerid); // End entity
				write_short(g_sprite); // Sprite index
				write_byte(1); // Starting frame
				write_byte(1); // frame rate in 0.1's
				write_byte(3); // life in 0.1's
				write_byte(50); // line width in 0.1's
				write_byte(0); // noise amplitude in 0.01's
				write_byte(255); // R
				write_byte(0); // G
				write_byte(0); // B
				write_byte(150); // brightness
				write_byte(15); // scroll speed in 0.1's
				message_end()
			}else{
				set_pev(targetid, pev_health, targethp + g_p_dmg[targetid])
				g_p_dmg[targetid] = NO_DAMAGE
				stop_healing_process(healerid)
			}
		}else{
			stop_healing_process(healerid)
		}
	}
}


public heal_targets(Float:health_amount){
	static healerid
	static targetid
	static Float:targethp
	static Float:temp_health
	static i

	i = 1
	while(i <= g_list_healers[PTR_LC]){
		healerid = g_list_healers[i]
		targetid = g_p_target[healerid]
		if(g_p_points[healerid] > NO_HEAL_POINTS && g_p_dmg[targetid] > NO_DAMAGE && _Is(_alive, healerid)){
			pev(targetid, pev_health, targethp)
			if(health_amount < g_p_points[healerid] && health_amount < g_p_dmg[targetid]){
				set_pev(targetid, pev_health, targethp + health_amount)
				g_p_points[healerid] -= health_amount
				g_p_dmg[targetid] -= health_amount
				i++
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMENTS); // TE_BEAMENTS 8
				write_short(targetid); // Start entity
				write_short(healerid); // End entity
				write_short(g_sprite); // Sprite index
				write_byte(1); // Starting frame
				write_byte(1); // frame rate in 0.1's
				write_byte(3); // life in 0.1's
				write_byte(50); // line width in 0.1's
				write_byte(0); // noise amplitude in 0.01's
				write_byte(255); // R
				write_byte(0); // G
				write_byte(0); // B
				write_byte(150); // brightness
				write_byte(15); // scroll speed in 0.1's
				message_end()
			}else{
				temp_health = func_fmin3(health_amount, g_p_points[healerid], g_p_dmg[targetid])
				set_pev(targetid, pev_health, targethp + temp_health)
				g_p_points[healerid] -= temp_health
				g_p_dmg[targetid] -= temp_health
				stop_healing_process(healerid)
			}
		}else{
			stop_healing_process(healerid)
		}
	}
}


public player_PreThink(id){
	static targetid, targetbody
	static button
	button = pev(id, pev_button)
	if(button & IN_USE && g_p_target[id] == NO_TARGET){
		if(_Is(_alive, id) && _Is(_medic, id)){
			g_p_distance[id] = get_user_aiming(id, targetid, targetbody)

			if(targetid > g_max_players || targetid < 1 || g_p_team[targetid] != g_p_team[id])
			g_p_aiming_at[id] = 0
			else{
				g_p_aiming_at[id] = targetid
				if(g_p_distance[id] <= g_range)
				start_healing_process(id, targetid)
			}
		}
	}else if(g_p_target[id] != NO_TARGET && !(button & IN_USE)){
		stop_healing_process(id)
		g_snd_next[id] = EIM_SND_NONE
	}
}


public start_healing_process(id, targetid){
	stop_healing_process(id)
	check_health(targetid)
	if(g_p_healers[targetid] >= g_maxhealers){
		if(g_snd_frames[id] == 0)
		sndl_add(id)
		g_snd_next[id] = EIM_SND_UNABLE
	}else if((g_p_points[id] <= NO_HEAL_POINTS && g_healpoints > 0 ) || g_p_dmg[targetid] <= NO_DAMAGE){
		if(g_snd_frames[id] == 0)
		sndl_add(id)
		g_snd_next[id] = EIM_SND_UNABLE
	}else{
		g_p_target[id] = targetid
		g_p_healers[targetid]++
		g_list_healers[PTR_LC]++
		g_list_healers[g_list_healers[PTR_LC]] = id
		if(g_snd_frames[id] == 0)
		sndl_add(id)
		if(g_snd_next[id] != EIM_SND_HEALING)
		g_snd_next[id] = EIM_SND_START
		g_snd_frames[id] = 0
	}
}

public stop_healing_process(id){
	if(g_p_target[id] != NO_TARGET){
		if(g_snd_next[id] != EIM_SND_NONE)
		g_snd_next[id] = EIM_SND_UNABLE

		g_p_healers[g_p_target[id]]--
		g_p_target[id] = NO_TARGET

		static i
		i = 1
		while(g_list_healers[i]!=id)
		i++
		while(i<g_list_healers[PTR_LC]){
			g_list_healers[i] = g_list_healers[i+1]
			i++
		}
		g_list_healers[PTR_LC]--
	}
}


public event_new_round(){
	_Clear(_medic)
	g_range = get_pcvar_num(pcvar_range)
	g_hps = get_pcvar_float(pcvar_hps)
	g_maxhealers = get_pcvar_num(pcvar_maxhealers)
	g_healpoints = get_pcvar_num(pcvar_healpoints)
	g_healeff = get_pcvar_float(pcvar_healeff)
	g_in_team = get_pcvar_num(pcvar_in_team)
	g_mode = get_pcvar_num(pcvar_mode)

	reset_all()
}

public reset_all(){
	for(new i=1; i<=g_max_players; i++){
		stop_healing_process(i)
		g_p_healers[i] = NO_HEALERS
		g_p_points[i] = float(g_healpoints)
		g_p_dmg[i] = NO_DAMAGE
		g_snd_current[i] = EIM_SND_NONE
		g_snd_next[i] = EIM_SND_NONE
		emit_sound(i, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
	}
	g_list_healers[PTR_LC] = 0
}

public logevent_round_start(){
	new players[4][32], pnum[4], team
	for(new i=1; i<=g_max_players; i++){
		if(!_Is(_alive, i) || _Is(_bot, i))
		continue
		team = g_p_team[i]
		players[team][pnum[team]++] = i
		pev(i, pev_health, g_p_start_hp[i])
		g_p_max_hp[i] = g_p_start_hp[i]
	}
	
	new team_medic[4] 
	if(g_mode == 1){
		if(0 < g_in_team < 3){
			if(pnum[g_in_team] > 0){
				team_medic[g_in_team] = players[g_in_team][random(pnum[g_in_team])]
				_Set(_medic, team_medic[g_in_team])
			}
		}else{
			if(pnum[1] > 0){
				team_medic[1] = players[1][random(pnum[1])]
				_Set(_medic, team_medic[1])
			}
			if(pnum[2] > 0){
				team_medic[2] = players[2][random(pnum[2])]
				_Set(_medic, team_medic[2])
			}
		}
	}
	new name[32], msg[64]
	for(team=1; team<=2; team++){
		if(team_medic[team] == 0)
		continue
		get_user_name(team_medic[team], name, sizeof(name)-1)
		formatex(msg, 63, "%s is a medic this round!", name)
		for(new i=0; i<pnum[team]; i++){
			set_hudmessage(200, 100, 0, -1.0, 0.45, 0, 6.0, 5.0, 0.1, 0.2, -1)
			ShowSyncHudMsg(players[team][i], g_HSO_t_info, msg)
		}        
	}
}


public player_spawn(id){
	if(!is_user_alive(id))
	return
	_Set(_alive, id)
	stop_healing_process(id)
	g_p_healers[id] = NO_HEALERS
	g_p_points[id] = float(g_healpoints)
	g_p_dmg[id] = NO_DAMAGE
	g_p_team[id] = get_user_team(id)
	
	if(g_mode == 0 && (!g_in_team || g_in_team == g_p_team[id])){
		_Set(_medic, id)
	}    
}


public player_killed(id){
	emit_sound(id, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
	_UnSet(_alive, id)
	_UnSet(_medic, id)
	g_snd_current[id] = EIM_SND_NONE
	g_snd_next[id] = EIM_SND_NONE
	stop_healing_process(id)
}

public client_connect(id){
	g_p_healers[id] = NO_HEALERS
	g_p_points[id] = float(g_healpoints)
	g_p_dmg[id] = NO_DAMAGE
	g_p_start_hp[id] = 100.0
	g_p_max_hp[id] = 100.0
	if(is_user_bot(id))
	_Set(_bot, id)
	else
	_UnSet(_bot, id)
}

public client_disconnected(id){
	emit_sound(id, CHAN_STREAM, "items/medcharge5.wav", EIM_SND_VOL, ATTN_NORM, SND_STOP, PITCH_NORM)
	_UnSet(_alive, id)
	_UnSet(_medic, id)
	g_snd_current[id] = EIM_SND_NONE
	g_snd_next[id] = EIM_SND_NONE
	stop_healing_process(id)
}


public check_health(id){
	static Float:p_health
	pev(id, pev_health, p_health)
	if(p_health < g_p_max_hp[id]){
		if(g_p_dmg[id] + p_health < g_p_max_hp[id])
		g_p_max_hp[id] -=  (g_p_max_hp[id] - (g_p_dmg[id] + p_health))*(1.0 - g_healeff)
		g_p_dmg[id] = g_p_max_hp[id] - p_health
	}else if(p_health > g_p_start_hp[id]){
		g_p_max_hp[id] = g_p_start_hp[id]
		g_p_dmg[id] = NO_DAMAGE
	}else{
		g_p_max_hp[id] = p_health
		g_p_dmg[id] = NO_DAMAGE
	}
}


public Float:func_fmin3(&Float:a, &Float:b, &Float:c){
	if(a>b)
	if(b>c)
	return c
	else
	return b
	else if(a>c)
	return c
	return a
}