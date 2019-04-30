#include <amxmodx>
#include <fun>
#include <fakemeta>

new stuck[33]

new cvar[3]

new const Float:size[][3] = {
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
}

public plugin_init() {
	register_plugin("Unstuck","1.0","O'Zone");
	
	cvar[0] = register_cvar("amx_autounstuck","1");
	cvar[1] = register_cvar("amx_autounstuckeffects","1");
	cvar[2] = register_cvar("amx_autounstuckwait","7");
	
	register_clcmd("say /unstuck", "checkstuck");
	register_clcmd("say_team /unstuck", "checkstuck");
	register_clcmd("say /stuck", "checkstuck");
	register_clcmd("say_team /stuck", "checkstuck");
}

public checkstuck(player) 
{
	if(get_pcvar_num(cvar[0]) >= 1) 
	{
		new Float:origin[3], Float:mins[3], Float:vec[3], hull;
		pev(player, pev_origin, origin)
		hull = pev(player, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
		if (!is_hull_vacant(origin, hull,player) && !get_user_noclip(player) && !(pev(player,pev_solid) & SOLID_NOT)) 
		{
			++stuck[player]
			if(stuck[player] >= get_pcvar_num(cvar[2])) 
			{
				pev(player, pev_mins, mins)
				vec[2] = origin[2]
				for (new o=0; o < sizeof size; ++o) 
				{
					vec[0] = origin[0] - mins[0] * size[o][0]
					vec[1] = origin[1] - mins[1] * size[o][1]
					vec[2] = origin[2] - mins[2] * size[o][2]
					if (is_hull_vacant(vec, hull,player)) 
					{
						engfunc(EngFunc_SetOrigin, player, vec)
						effects(player)
						set_pev(player,pev_velocity,{0.0,0.0,0.0})
						o = sizeof size
					}
				}
			}
		}
		else
		{
			stuck[player] = 0
		}
	}
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
	return true
	
	return false
}

public effects(id) {
	if(get_pcvar_num(cvar[1])) {
		set_hudmessage(255,150,50, -1.0, 0.65, 0, 6.0, 1.5,0.1,0.7) // HUDMESSAGE
		show_hudmessage(id,"Fuiste destrabado.") // HUDMESSAGE
		message_begin(MSG_ONE_UNRELIABLE,105,{0,0,0},id )      
		write_short(1<<10)   // fade lasts this long duration
		write_short(1<<10)   // fade lasts this long hold time
		write_short(1<<1)   // fade type (in / out)
		write_byte(20)            // fade red
		write_byte(255)    // fade green
		write_byte(255)        // fade blue
		write_byte(255)    // fade alpha
		message_end()
		client_cmd(id,"spk fvox/blip.wav")
	}
}
