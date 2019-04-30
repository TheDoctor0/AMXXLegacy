#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <zp50_gamemodes>

new g_Timer[33]

static EntTimer, g_GameModeStarted

public plugin_init(){
	RegisterHam(Ham_Killed, "player", "Hook_Killed", 1)
	
	EntTimer = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(EntTimer, pev_classname, "Timer")
	register_event("TeamInfo","join_team","a")
	RegisterHamFromEntity(Ham_Think, EntTimer, "Ham_Timer")
	set_pev(EntTimer, pev_nextthink, get_gametime() + 1.0)
}

public Hook_Killed(victim, attacker, corpse) {
	if (!is_user_connected(victim))
		return HAM_IGNORED
	
	g_Timer[victim] = 4
	return HAM_HANDLED
}

public Ham_Timer(Ent) {
	if (!pev_valid(Ent))
		return HAM_IGNORED
		
	static ClassName[32]
	pev(Ent, pev_classname, ClassName, charsmax(ClassName))
	
	if (!equal(ClassName, "Timer"))
		return HAM_IGNORED

	for(new id = 1; id <= get_maxplayers(); id++) 
	{
		if (!is_user_connected(id) || is_user_alive(id) || !g_Timer[id] || !g_GameModeStarted)
			continue;

		if (get_user_team(id) == 0 || get_user_team(id) == 3)
			continue;
			
		g_Timer[id]--;
		
		if(g_Timer[id]==3)
		{
			message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id)
			write_short(3)
			message_end()
		}
		
		if(!g_Timer[id]) 
		{
			if(zp_gamemodes_get_chosen() != -2)
				zp_core_respawn_as_zombie(id, random_num(0,1))
			ExecuteHamB(Ham_CS_RoundRespawn, id)
		}
		
		else if(g_Timer[id]<4) 
			client_print(id, print_center, "Respawn za: %d sekund",g_Timer[id])
	}

	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	return HAM_HANDLED
}

public join_team()
{    
    new id = read_data(1)
    static user_team[32]
    
    read_data(2, user_team, 31)    
    
    if(!is_user_connected(id) || is_user_hltv(id))
        return PLUGIN_CONTINUE    
    
    switch(user_team[0])
    {
        case 'C': g_Timer[id] = 4  
        case 'T': g_Timer[id] = 4
    }
    return PLUGIN_CONTINUE
    
}  

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
}