#include <amxmodx>
#include <amxmisc>
#include <cstrike>
 
new old_team[33], old_cash[33];

public plugin_init()
{
	register_plugin("Spectator Save Cash", "1.0", "O'Zone");
	register_event("TeamInfo","team_assign","a");
}
 
public team_assign()
{
	new tid;
	new id = read_data(1);
	new Team[33];
	read_data(2, Team, 32);
	
	if(equal(Team,"UNASSIGNED")) tid = 0;
	else if(equal(Team,"TERRORIST")) tid = 1;
	else if(equal(Team,"CT")) tid = 2;
	else if(equal(Team,"SPECTATOR")) tid = 3;
	
	if((tid == 1 || tid == 2) && old_team[id] != 3)
		old_cash[id] = cs_get_user_money(id);
		
	if(old_team[id] == tid) 
		return PLUGIN_CONTINUE;
	
	if(old_team[id] == 3 && (tid == 1 || tid == 2))
		cs_set_user_money(id, old_cash[id]);
	
	old_team[id] = tid;

	return PLUGIN_CONTINUE;
}

public client_connect(id)
{
	old_cash[id] = 0;
	old_team[id] = 0;
}

public client_disconnect(id)
{
	old_cash[id] = 0;
	old_team[id] = 0;
}