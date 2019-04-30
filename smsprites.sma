#include <amxmodx> 
#include <fakemeta> 
#include <xs> 

new g_kills[33]; 
new bool:g_firstblood; 
new g_maxplayers; 
new g_player_hud[33]; 

#define NORMAL_KILLS_NUM 8 
#define OTHER_KILLS_NUM 7 

new const normal_kill[8][] = 
{ 
    "sprites/smmarks/kill_1.spr", 
    "sprites/smmarks/kill_2.spr", 
    "sprites/smmarks/kill_3.spr", 
    "sprites/smmarks/kill_4.spr", 
    "sprites/smmarks/kill_5.spr", 
    "sprites/smmarks/kill_6.spr", 
    "sprites/smmarks/kill_7.spr", 
    "sprites/smmarks/kill_8.spr" 
} 

new const other_kills[OTHER_KILLS_NUM][] = 
{ 
    "sprites/smmarks/kill_first.spr", 
    "sprites/smmarks/kill_last.spr", 
    "sprites/smmarks/kill_headshot_gold.spr", 
    "sprites/smmarks/kill_knife.spr", 
    "sprites/smmarks/kill_he.spr", 
    "sprites/smmarks/c4_set.spr", 
    "sprites/smmarks/c4_defuse.spr" 
} 


public plugin_init() 
{ 
    register_plugin("Effects Killer","1.0","NST") 

    register_logevent("RoundStart", 2, "1=Round_Start")  
    register_forward(FM_AddToFullPack, "AddToFullPack", 1) 
    register_event("DeathMsg", "DeathMsg", "a") 

    g_maxplayers = get_maxplayers() 
} 

public plugin_precache() 
{ 
    new i; 

    for(i = 0 ; i < NORMAL_KILLS_NUM ; i++) 
    { 
        precache_model(normal_kill[i]) 
    } 
     
    for(i = 0 ; i < OTHER_KILLS_NUM ; i++) 
    { 
        precache_model(other_kills[i]) 
    } 
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
    ShowSprite(id, other_kills[5]) 
} 

public bomb_planted(id) 
{ 
    ShowSprite(id, other_kills[6]) 
} 

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
        ShowSprite(killer, other_kills[0]) 
        return 
    } 
     
    if(t_count == 0 || ct_count == 0) 
    { 
        ShowSprite(killer, other_kills[1]) 
        return 
    } 
     
    if(headshot) 
    { 
        ShowSprite(killer, other_kills[2]) 
        return 
    } 
     
    if(equali(weapon,"knife")) 
    { 
        ShowSprite(killer, other_kills[3]) 
        return 
    } 
     
    if(equali(weapon,"grenade")) 
    { 
        ShowSprite(killer, other_kills[4]) 
        return 
    } 
     
    if(g_kills[killer] < 8) 
    { 
        ShowSprite(killer, normal_kill[g_kills[killer] - 1]) 
        return 
    } 
} 

public AddToFullPack(es, e, ent, host, host_flags, player, p_set) 
{ 
    if(!is_user_connected(host) || !pev_valid(host) || !pev_valid(ent)) 
        return FMRES_IGNORED 

    if (ent == g_player_hud[host]) 
    { 
        static Float:origin[3], Float:forvec[3], Float:voffsets[3] 
         
        pev(host, pev_origin, origin) 
        pev(host, pev_view_ofs, voffsets) 
        xs_vec_add(origin, voffsets, origin) 
        velocity_by_aim(host, 12, forvec) 
        xs_vec_add(origin, forvec, origin) 
        engfunc(EngFunc_SetOrigin, ent, origin) 
        set_es(es, ES_Origin, origin) 
        set_es(es, ES_RenderMode, kRenderTransAdd) 
        set_es(es, ES_RenderAmt, 255) 
    } 
    return FMRES_IGNORED 
} 

public ShowSprite(id, const sprite[]) 
{ 
    if(!is_user_connected(id)) 
        return 

    remove_task(id) 

    if(!pev_valid(g_player_hud[id])) 
        g_player_hud[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))

    set_pev(g_player_hud[id], pev_takedamage, 0.0) 
    set_pev(g_player_hud[id], pev_solid, SOLID_NOT) 
    set_pev(g_player_hud[id], pev_movetype, MOVETYPE_NONE) 
    engfunc(EngFunc_SetModel, g_player_hud[id], sprite) 
    set_pev(g_player_hud[id], pev_rendermode, kRenderTransAdd) 
    set_pev(g_player_hud[id], pev_renderamt, 0.0) 
    set_pev(g_player_hud[id], pev_scale, 0.03)     
     
    set_pev(g_player_hud[id], pev_animtime, get_gametime()) 
    set_pev(g_player_hud[id], pev_framerate, 0.0) 
    set_pev(g_player_hud[id], pev_spawnflags, SF_SPRITE_STARTON) 
    dllfunc(DLLFunc_Spawn, g_player_hud[id]) 
     
     
    set_task(2.0, "RemoveSprite", id) 
} 

public RemoveSprite(id) 
{ 
    if(pev_valid(g_player_hud[id])) 
    { 
        engfunc(EngFunc_RemoveEntity, g_player_hud[id]) 
        g_player_hud[id] = 0 
        remove_task(id) 
    } 
    else 
    { 
        g_player_hud[id] = 0 
        remove_task(id) 
    } 
} 