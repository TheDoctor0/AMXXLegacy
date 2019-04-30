#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define UPDATE_INTERVAL 0.5
#define TID_TIMER 26642

#define _Set(%1,%2) %1|=1<<%2
#define _UnSet(%1,%2) %1&=~(1<<%2)
#define _Is(%1,%2) (%1&1<<%2)
new _alive, _in_server

new g_max_players
new g_timer_entid
new Float:g_t_time
new g_HSO

new pc_enabled
new pc_team_color
new pc_details
new pc_req_flags
new pc_dead_only

new g_enabled
new g_team_color
new g_details
new g_req_flags
new g_dead_only

new g_target[33]
new g_name[33][32]
new g_weap_name[32][32] = {"", "p228", "", "scout", "HE",
"xm1014", "c4", "mac10", "aug", "SG", "elite",
"fiveseven", "ump45", "sg550", "galil", "famas", "usp", "glock",
"awp", "mp5", "m249", "m3", "m4a1", "tmp",
"g3sg1", "FB", "deagle", "sg552", "ak47",
"knife", "p90", ""}
new g_hp[33]
new g_ap[33]
new g_weapon[33]
new g_team[33]


public plugin_init(){
    register_plugin("Target Info on HUD", "1.2", "Sylwester")

    register_message(get_user_msgid("StatusValue"), "update_target")
    register_message(get_user_msgid("Health"), "update_hp")
    register_message(get_user_msgid("Battery"), "update_ap")
    register_message(get_user_msgid("CurWeapon"), "update_weapon")
    register_event("TeamInfo", "join_team","a")
    register_event("HLTV", "update_cvars", "a", "1=0", "2=0")
    
    RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
    RegisterHam(Ham_Killed, "player", "Player_Killed", 1)

    pc_enabled = register_cvar("ti_enabled", "1") //0 - plugin disabled //1 - plugin enabled
    pc_team_color = register_cvar("ti_team_color", "1") //0-same color for all teams//1-team color
    pc_details = register_cvar("ti_details", "2") //0-only name//1-show details//2-teammates details
    pc_req_flags = register_cvar("ti_req_flags", "") //0 - plugin disabled //1 - plugin enabled
    pc_dead_only = register_cvar("ti_dead_only", "0") //0-same color for all teams//1-team color
    
    g_max_players = get_maxplayers()
    g_HSO = CreateHudSyncObj()
    create_timer()
}


public plugin_cfg(){
    update_cvars()
}


public update_weapon(msg_id, msg_dest, id){
    if(get_msg_arg_int(1))
        g_weapon[id] = get_msg_arg_int(2)
}


public update_hp(msg_id, msg_dest, id){
    g_hp[id] = get_user_health(id)
}


public update_ap(msg_id, msg_dest, id){
    g_ap[id] = get_user_armor(id)
}


public update_target(msg_id, msg_dest, id){
    if(get_msg_arg_int(1) == 2)
        g_target[id] = get_msg_arg_int(2)
}


public client_connect(id){
    g_target[id] = 0
    g_team[id] = 0
    get_user_name(id, g_name[id], 31)
}


public client_putinserver(id){
    _Set(_in_server, id)
}


public client_disconnected(id){
    _UnSet(_alive, id)
    _UnSet(_in_server, id)
}


public Player_Spawn(id){
    if(!is_user_alive(id))
        return
    _Set(_alive, id)
}


public Player_Killed(id){
    _UnSet(_alive, id)
}


public update_cvars(){
    g_enabled = get_pcvar_num(pc_enabled)
    g_team_color = get_pcvar_num(pc_team_color)
    g_details = get_pcvar_num(pc_details)
    g_dead_only = get_pcvar_num(pc_dead_only)
    new tmp[32]
    get_pcvar_string(pc_req_flags, tmp, 31)    
    g_req_flags = read_flags(tmp)
}


public client_infochanged(id){ //update name
    get_user_info(id, "name", g_name[id], 31)
}


public join_team(){
    static id, team[2]
    id = read_data(1)
    read_data(2, team, 1)
    switch(team[0]){
        case 'C': g_team[id] = 2
        case 'T': g_team[id] = 1
        default : g_team[id] = 0
    }
}


public create_timer(){
    g_timer_entid = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString,"info_target"))

    if(pev_valid(g_timer_entid)){
        set_pev(g_timer_entid, pev_classname, "ti_timer")
        global_get(glb_time, g_t_time)
        set_pev(g_timer_entid, pev_nextthink, g_t_time + UPDATE_INTERVAL)
        register_forward(FM_Think, "fwd_Think")
    }else{
        log_amx("Warning: Failed to create timer entity, using task instead.")
        set_task(UPDATE_INTERVAL, "timer_cycle", TID_TIMER, "", 0, "b")
    }
}


public fwd_Think(Ent){
    if(Ent != g_timer_entid)
        return FMRES_IGNORED
    g_t_time += UPDATE_INTERVAL
    set_pev(Ent, pev_nextthink, g_t_time)
    timer_cycle()
    return FMRES_IGNORED
}


public plugin_unpause(){
    if(pev_valid(g_timer_entid)){
        global_get(glb_time, g_t_time)
        g_t_time += UPDATE_INTERVAL
        set_pev(g_timer_entid, pev_nextthink, g_t_time)
    }
}


public timer_cycle(){
    static id, cache[512], tar, pos
    if(!g_enabled)
        return
    for(id = 1; id<=g_max_players; id++){
        if(!_Is(_in_server, id) || (get_user_flags(id)&g_req_flags != g_req_flags))
            continue
        tar = g_target[id]  
        if(_Is(_alive, id)){
            if(g_dead_only)
                continue
        }else{
            if(pev(id, pev_iuser2) == g_target[id])
                tar = g_target[tar]
        }
        if(tar == 0)
            continue
        if(g_team_color == 0){
            set_hudmessage(250, 150, 50, -1.0, 0.53, 1, _, UPDATE_INTERVAL-0.1, 0.1, 0.1, -1)
        }else{
            switch(g_team[tar]){
                case 1: set_hudmessage(255, 30, 30, -1.0, 0.53, 1, _, UPDATE_INTERVAL-0.1, 0.1, 0.1, -1)
                case 2: set_hudmessage(30, 30, 255, -1.0, 0.53, 1, _, UPDATE_INTERVAL-0.1, 0.1, 0.1, -1)
                default: set_hudmessage(150, 150, 150, -1.0, 0.53, 1, _, UPDATE_INTERVAL-0.1, 0.1, 0.1, -1)
            }
        }

        pos = formatex(cache, 511, "%s", g_name[tar])
        if(g_details == 1 || (g_details == 2 && g_team[id] == g_team[tar]))
            pos += formatex(cache[pos], 511-pos, " -- %d HP / %d AP / %s", g_hp[tar], g_ap[tar], g_weap_name[g_weapon[tar]])
        ShowSyncHudMsg(id, g_HSO, cache)
    }
}
