#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define TASK_REDBULL 8936

new bool:bRedbull[33], bool:bFreezeTime;

new cvarCost, cvarTime, cvarSpeed;

native check_small_map();

public plugin_init()
{
	register_plugin("Red Bull", "3.1", "GHW_Chronic & O'Zone");

	register_clcmd("say /redbull", "BuyRedbull");
	register_clcmd("sayteam /redbull", "BuyRedbull");

	cvarCost = register_cvar("RedBull_Cost", "4000");
	cvarTime = register_cvar("RedBull_Time", "15.0");
	cvarSpeed = register_cvar("RedBull_Speed", "290.0");

	RegisterHam(get_player_resetmaxspeed_func(), "player", "Forward_Speed", 1);
	
	register_forward(FM_PlayerPreThink, "Forward_FM_PlayerPreThink");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	
	register_logevent("RoundStart", 2, "1=Round_Start");

	register_dictionary("redbull.txt");
}

public client_connect(id) 
	bRedbull[id] = false;
	
public client_disconnected(id) 
{
	bRedbull[id] = false;
	
	if(task_exists(id + TASK_REDBULL)) remove_task(id + TASK_REDBULL);
}

public NewRound()
	bFreezeTime = true;

public RoundStart()
	set_task(0.5, "Unlock");
	
public Unlock()
	bFreezeTime = false;

public BuyRedbull(id)
{
	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_NOBUY_DEAD");
		return PLUGIN_HANDLED;
	}
	
	if(bFreezeTime)
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_NOBUY_ROUND");
		return PLUGIN_HANDLED;
	}
	
	if(check_small_map())
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_NOBUY_MAP");
		return PLUGIN_HANDLED;
	}
		
	if(bRedbull[id])
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_NOBUY_HAVE");
		return PLUGIN_HANDLED;
	}
	
	if(cs_get_user_money(id) < get_pcvar_num(cvarCost))
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_NOBUY_POOR", get_pcvar_num(cvarCost));
		return PLUGIN_HANDLED;
	}
	
	bRedbull[id] = true;
	
	cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvarCost), 1);
	set_user_gravity(id, 0.6);
	set_user_maxspeed(id, get_pcvar_float(cvarSpeed));
	
	set_task(get_pcvar_float(cvarTime), "RedbullOver", id + TASK_REDBULL);
	
	client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_REDBULL1")
	client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_REDBULL2");
	
	return PLUGIN_HANDLED;
}

public RedbullOver(id)
{
	id -= TASK_REDBULL;
	
	if(is_user_connected(id))
	{
		client_print_color(id, id, "^x03[REDBULL]^x01 %L", id, "MSG_REDBULL_OFF");
		
		bRedbull[id] = false;
		
		set_user_maxspeed(id, 250.0);
		set_user_gravity(id, 1.0);
		remove_task(id);
	}
}

public Forward_Speed(id)
{
	if(is_user_alive(id) && bRedbull[id])
		set_user_maxspeed(id, get_pcvar_float(cvarSpeed));
}

public Forward_FM_PlayerPreThink(id) 
{
	if(is_user_alive(id)) 
	{
		new Float:fVector[3];
		pev(id, pev_velocity, fVector);
		new Float: fSpeed = floatsqroot(fVector[0]*fVector[0]+fVector[1]*fVector[1]+fVector[2]*fVector[2]);

		if((fm_get_user_maxspeed(id) * 5) > (fSpeed*9))
			set_pev(id, pev_flTimeStepSound, 300);
	}
}

Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed) ? Ham_CS_Player_ResetMaxSpeed : Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
