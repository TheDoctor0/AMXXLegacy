#include <amxmodx> 
#include <fakemeta> 
#include <xs> 

new g_kills[33]; 
new bool:g_firstblood; 
new g_maxplayers; 

new one_kill
new two_kill
new three_kill
new four_kill
new five_kill
new six_kill
new seven_kill
new eight_kill
new more_than_eight
new last_kill
new first_kill
new knife_kill
new grenade_kill
new head_shot
new c4_set
new c4_defuse

public plugin_init() 
{ 
	register_plugin("Kill Effects","1.0","O'Zone") 
	register_logevent("RoundStart", 2, "1=Round_Start")  
	register_event("DeathMsg", "DeathMsg", "a") 
	g_maxplayers = get_maxplayers() 
} 

public plugin_precache() 
{ 
	head_shot = precache_model("sprites/headshot.spr")
	knife_kill = precache_model("sprites/knife_kill.spr")
	grenade_kill = precache_model("sprites/grenade_kill.spr")
	one_kill = precache_model("sprites/1_kill.spr")
	two_kill = precache_model("sprites/2_kill.spr")
	three_kill = precache_model("sprites/3_kill.spr")
	four_kill = precache_model("sprites/4_kill.spr")
	five_kill = precache_model("sprites/5_kill.spr")
	six_kill = precache_model("sprites/6_kill.spr")
	seven_kill = precache_model("sprites/7_kill.spr")
	eight_kill = precache_model("sprites/8_kill.spr")
	more_than_eight = precache_model("sprites/more_than_8.spr")
	c4_set = precache_model("sprites/c4_set.spr")
	c4_defuse = precache_model("sprites/c4_defuse.spr")
	first_kill = precache_model("sprites/first_kill.spr")
	last_kill = precache_model("sprites/last_kill.spr")
} 
  
public RoundStart() 
{ 
    g_firstblood = false 

    for(new i = 1; i <= g_maxplayers; i++) 
    { 
        g_kills[i] = 0 
    } 
} 

public bomb_defused(id) 
{ 
    ShowSprite(id, c4_defuse) 
} 

public bomb_planted(id) 
{ 
    ShowSprite(id, c4_set) 
}  

public Show(id)
	ShowSprite(id, one_kill) 
	
public DeathMsg() 
{ 
	new killer, victim, headshot, weapon[12]; 

	killer = read_data(1) 
	victim = read_data(2) 
	headshot = read_data(3) 
	read_data(4, weapon, charsmax(weapon)) 

	if(is_user_bot(killer) || killer == victim) 
		return 

	g_kills[killer]++ 

	new players_t[32], players_ct[32], t_count, ct_count; 

	get_players(players_t, t_count, "ae", "TERRORIST") 
	get_players(players_ct, ct_count, "ae", "CT")  

	if(!g_firstblood) 
	{ 
		g_firstblood = true 
		ShowSprite(victim, first_kill) 
		return 
	} 
     
	if(t_count == 0 || ct_count == 0) 
	{ 
		ShowSprite(victim, last_kill) 
		return 
	} 
     
	if(equali(weapon,"knife")) 
	{ 
		ShowSprite(victim, knife_kill) 
		return 
	} 
     
	if(equali(weapon,"grenade")) 
	{ 
		ShowSprite(victim, grenade_kill) 
		return 
	} 
	
	if(headshot) 
		ShowSprite(victim, head_shot) 
    
	switch(g_kills[killer]){
		case 1: ShowSprite(victim, one_kill) 
		case 2: ShowSprite(victim, two_kill) 
		case 3: ShowSprite(victim, three_kill) 
		case 4: ShowSprite(victim, four_kill) 
		case 5: ShowSprite(victim, five_kill) 
		case 6: ShowSprite(victim, six_kill) 
		case 7: ShowSprite(victim, seven_kill) 
		case 8: ShowSprite(victim, eight_kill) 
		default: ShowSprite(victim, more_than_eight) 
	}
} 
	
public ShowSprite(id, sprite)
{	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE

	static origin[3]
	get_user_origin(id, origin)
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+65)
	write_short(sprite)
	write_byte(8)
	write_byte(250)
	message_end()
        
	return PLUGIN_CONTINUE
}
