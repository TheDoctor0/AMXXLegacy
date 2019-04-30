#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Admin Free Look"
#define VERSION "2.0"
#define AUTHOR "Jim"

#define ADMIN_ACCESS	ADMIN_BAN	//flag "d"

#define SPECT_KEYS	MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6|MENU_KEY_0
#define CLASS_KEYS	MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5

#define LINUXDIFF	5

#if cellbits == 32
	#define OFFSET_TEAM 114
#else
	#define OFFSET_TEAM 139
#endif

#define TEAM_T		1
#define TEAM_CT		2
#define TEAM_SPEC	3

new bool:g_roundend
new bool:g_corpse_made[33]
new bool:g_model_selected[33]
new g_team[33]
new g_maxplayers

stock bool:is_admin(id)
	return g_team[id] && get_user_flags(id) & ADMIN_ACCESS ? true : false

stock bool:is_admin_dead(id)
	return is_admin(id) && g_corpse_made[id] ? true : false

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "new_round", "a", "1=0", "2=0")
	register_logevent("round_end", 2, "1=Round_End")
	register_event("ClCorpse", "hook_corpse", "a", "12>0")
	register_event("TeamInfo", "event_teaminfo", "a", "1>0")
	register_event("TextMsg", "joined_a_team", "a", "1=1", "2=#Game_join_terrorist", "2=#Game_join_ct")
	
	register_clcmd("jointeam", "join_spec_cmd")
	register_clcmd("joinclass", "select_a_model")
	register_menucmd(register_menuid("IG_Team_Select_Spect",1), SPECT_KEYS, "join_spec_menucmd")
	register_menucmd(register_menuid("Terrorist_Select", 1), CLASS_KEYS, "select_a_model")
	register_menucmd(register_menuid("CT_Select", 1), CLASS_KEYS, "select_a_model")
	
	g_maxplayers = get_maxplayers()
}

public client_connect(id)
{
	g_team[id] = 0
	g_model_selected[id] = false
	g_corpse_made[id] = false
}

public client_disconnected(id)
{
	g_team[id] = 0
	g_model_selected[id] = false
	g_corpse_made[id] = false
}

public event_teaminfo()
{
	new id = read_data(1)
	new team[2]
	read_data(2, team, 1)
	switch(team[0])
	{
		case 'T': g_team[id] = TEAM_T
		case 'C': g_team[id] = TEAM_CT
		case 'S': g_team[id] = TEAM_SPEC
	}
}

public stay_spec(id)
{
	if(g_team[id] != TEAM_SPEC)
	{
		g_team[id] = TEAM_SPEC
		message_begin(MSG_ALL, get_user_msgid("TeamInfo"))
		write_byte(id)
		write_string("SPECTATOR")
		message_end()
	}
}

public join_spec_cmd(id)
{
	new argv[2]
	read_argv(1, argv, 1)
	if(argv[0] == '6')
		stay_spec(id)
}

public join_spec_menucmd(id, key)
{
	if(key == 5)
		stay_spec(id)
}

public joined_a_team()
{
	new name[32]
	read_data(3, name, 31)
	new id = get_user_index(name)
	g_model_selected[id] = false
}

public select_a_model(id)
{
	g_model_selected[id] = true
	if(!g_roundend && is_admin(id))
		set_task(1.0, "delay", id)
}

public delay(id)
{
	if(g_team[id] && !is_user_alive(id))
	{
		g_corpse_made[id] = true
		free_look(id)
	}
}

public hook_corpse()
{
	new id = read_data(12)
	g_corpse_made[id] = true
	if(!g_roundend && is_admin(id))
		free_look(id)
}

public free_look(id)
{
	if(!g_roundend && is_admin_dead(id) && g_model_selected[id])
		set_pdata_int(id, OFFSET_TEAM, TEAM_SPEC, LINUXDIFF)
}

public round_end()
{
	g_roundend = true
	freelook_over()
}

public new_round()
{
	g_roundend = false
	freelook_over()
}

public freelook_over()
{
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(is_admin_dead(id) && get_pdata_int(id, OFFSET_TEAM, LINUXDIFF) == TEAM_SPEC && g_team[id] != TEAM_SPEC)
			set_pdata_int(id, OFFSET_TEAM, g_team[id], LINUXDIFF)
		g_corpse_made[id] = false
	}
}