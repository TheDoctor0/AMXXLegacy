#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>

#define PLUGIN "Jail Extra VIP"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define Set(%2,%1) (%1 |= (1<<(%2&31)))
#define Rem(%2,%1) (%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1) (%1 & (1<<(%2&31)))

#define V_MODEL "models/v_crowbar.mdl"
#define W_MODEL "models/w_crowbar.mdl"
#define P_MODEL "models/p_crowbar.mdl"

#define KNIFE_W_MODEL "models/w_knife.mdl"

forward amxbans_admin_connect(id);

native umc_vote_in_process();
native get_small_map();

new Array:aVIP, bool:bFreezeTime, iJumps[33], gRound = 0, iVip, gHUD;

new const iClips[] = {0, 13, -0, 10, 1, 7, 0, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, 0, 50};

new const szCmdVIP[][] = {"say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };

new const gSounds[][] = {
	"cb/knife_deploy1.wav",
	"cb/knife_hitwall1.wav",
	"cb/knife_hit1.wav",
	"cb/knife_hit2.wav",
	"cb/knife_hit3.wav",
	"cb/knife_hit4.wav",
	"cb/knife_slash1.wav",
	"cb/knife_slash2.wav",
	"cb/knife_stab.wav"
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCmdVIP; i++) register_clcmd(szCmdVIP[i], "ShowVips");
	
	register_clcmd("say /vip", "ShowMotd");
	
	register_clcmd("say_team", "VipChat");
	
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	register_logevent("RoundStart", 2, "1=Round_Start");
	register_logevent("RoundEnd", 2, "0=Round_End");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_message(get_user_msgid("SayText"), "HandleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	
	register_forward(FM_CmdStart, "CmdStartPre");
	register_forward(FM_EmitSound, "EmitSound");
	register_forward(FM_SetModel, "SetModel");
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawned", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "WeaponKnife", 1);
	RegisterHam(get_player_resetmaxspeed_func(), "player", "PlayerResetMaxSpeed", 1);
	
	aVIP = ArrayCreate(32, 32);
	
	gHUD = CreateHudSyncObj();
}

public plugin_natives()
{
	register_native("set_user_vip", "_set_user_vip", 1);
	register_native("get_user_vip", "_get_user_vip", 1);
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL);
	engfunc(EngFunc_PrecacheModel, P_MODEL);
	engfunc(EngFunc_PrecacheModel, W_MODEL);
	
	for(new i = 0; i < sizeof gSounds; i++) precache_sound(gSounds[i]);
}

public plugin_end()
	ArrayDestroy(aVIP);

public amxbans_admin_connect(id)
	client_authorized(id, "");
	
public client_connect(id)
	Rem(id, iVip);

public client_authorized(id)
{
	Rem(id, iVip);
	
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		Set(id, iVip);
		
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
		
		ArrayPushString(aVIP, szName);
		
		set_hudmessage(24, 190, 220, 0.25, 0.2, 0, 6.0, 6.0);
		ShowSyncHudMsg(0, gHUD, "VIP %s wbija na serwer!", szName);
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if(Get(id, iVip))
	{
		Rem(id, iVip);
		
		new szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_name(id, szName, charsmax(szName));
	
		for(new i = 0; i < iSize; i++)
		{
			ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
			if(equal(szName, szTempName))
			{
				ArrayDeleteItem(aVIP, i);
				
				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if(Get(id, iVip))
	{
		new szNewName[32], szName[32], szTempName[32], iSize = ArraySize(aVIP);
		
		get_user_info(id, "name", szNewName,charsmax(szNewName));
		get_user_name(id, szName, charsmax(szName));
	
		if(!equal(szName, szNewName))
		{
			ArrayPushString(aVIP, szNewName);
			
			for(new i = 0; i < iSize; i++)
			{
				ArrayGetString(aVIP, i, szTempName, charsmax(szTempName));
		
				if(equal(szName, szTempName))
				{
					ArrayDeleteItem(aVIP, i);
					
					break;
				}
			}
		}
	}
}

public ShowMotd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");

public RoundStart()
	bFreezeTime = false;
	
public RoundEnd()
	for(new i = 1; i <= 32; i++) if(is_user_alive(i) && Get(i, iVip)) cs_set_user_money(i, cs_get_user_money(i) + 500);

public NewRound()
{
	bFreezeTime = true;
	
	++gRound;
}

public GameCommencing()
	gRound = 0;

public PlayerResetMaxSpeed(id)
	if(!bFreezeTime && is_user_alive(id) && Get(id, iVip)) set_user_maxspeed(id, get_user_maxspeed(id) + 30);

public PlayerSpawned(id)
{
	if(!Get(id, iVip) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	if(gRound >= 0) set_user_footsteps(id, 1);
	
	iJumps[id] = (gRound >= 0 ? 2 : -1);
	
	set_user_health(id, get_user_health(id) + 50);

	return PLUGIN_CONTINUE;
}

public CmdStartPre(id, uc_handle)
{
	if(is_user_alive(id) && Get(id, iVip))
	{
		new iFlags = pev(id, pev_flags);
		
		if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(iFlags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && iJumps[id] > 0)
		{
			--iJumps[id];
			
			new Float:fVelocity[3];
			
			pev(id, pev_velocity, fVelocity);
			
			fVelocity[2] = random_float(265.0,285.0);
			
			set_pev(id,pev_velocity, fVelocity);
		} 
		else if(iFlags & FL_ONGROUND && iJumps[id] != -1) iJumps[id] = 2;
	}
}

public DeathMsg()
{
	new iKiller = read_data(1), iVictim = read_data(2), iHS = read_data(3);
	
	if(Get(iKiller, iVip) && is_user_alive(iKiller) && get_user_team(iKiller) != get_user_team(iVictim))
	{
		if(iHS)
		{
			set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(iKiller, "HeadShot! +10 HP");
			
			set_user_health(iKiller, get_user_health(iKiller) > 150 ? get_user_health(iKiller) + 10 : min(get_user_health(iKiller) + 10, 150));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 350);
		}
		else 
		{
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(iKiller, "Zabiles! +5 HP");
			
			set_user_health(iKiller, get_user_health(iKiller) > 150 ? get_user_health(iKiller) + 5 : min(get_user_health(iKiller) + 5, 150));
			
			cs_set_user_money(iKiller, cs_get_user_money(iKiller) + 200);
		}
		
		Recharge(iKiller);
	}
}

public Recharge(id)
{
	new iWeapon = get_user_weapon(id);
	
	if(iWeapon)
	{
		new iWeaponName[32], iWeaponEnt;
		
		get_weaponname(iWeapon, iWeaponName, charsmax(iWeaponName));
		
		iWeaponEnt = find_ent_by_owner(-1, iWeaponName, id);
		
		if(iWeaponEnt) cs_set_weapon_ammo(iWeaponEnt, iClips[iWeapon]);
	}
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamagebits)
{
	if(is_user_connected(iAttacker) && is_user_connected(iVictim) && iAttacker != iVictim && Get(iAttacker, iVip))
	{
		fDamage *= 1.1;
		
		SetHamParamFloat(4, fDamage);
	}
}

public WeaponKnife(ent) 
{     
	new id = get_pdata_cbase(ent, 41, 4);
	
	if(!is_user_alive(id) || cs_get_user_shield(id) || get_user_team(id) != 1 || !Get(id, iVip)) return;

	set_pev(id, pev_viewmodel2, V_MODEL);
	set_pev(id, pev_weaponmodel2, P_MODEL);
	
	return;
}

public SetModel(ent, const szModel[])
{
	if(!pev_valid(ent) || strcmp(KNIFE_W_MODEL, szModel)) return FMRES_IGNORED;
	
	static szClassName[32];
	
	pev(ent, pev_classname, szClassName, charsmax(szClassName));
	
	if(!strcmp(szClassName, "weaponbox") || !strcmp(szClassName, "armoury_entity") || !strcmp(szClassName, "grenade"))
	{
		engfunc(EngFunc_SetModel, ent, W_MODEL);
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public EmitSound(id, iChannel, szSample[], Float:fVolume, Float:fAttenuation, fFlags, iPitch)
{
	if(!is_user_alive(id) || !is_user_connected(id) || !Get(id, iVip) || get_user_team(id) != 1) return FMRES_IGNORED;
	
	if(equal(szSample,"weapons/knife_deploy1.wav"))
	{         
		emit_sound(id, iChannel, gSounds[6], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_hitwall1.wav"))
	{         
		emit_sound(id, iChannel, gSounds[1], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_hit1.wav"))
	{         
		emit_sound(id, iChannel, gSounds[2], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_hit2.wav"))
	{         
		emit_sound(id, iChannel, gSounds[3], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_hit3.wav"))
	{         
		emit_sound(id, iChannel, gSounds[4], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_hit4.wav"))
	{         
		emit_sound(id, iChannel, gSounds[5], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_slash1.wav"))
	{         
		emit_sound(id, iChannel, gSounds[6], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_slash2.wav"))
	{         
		emit_sound(id, iChannel, gSounds[7], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSample,"weapons/knife_stab.wav"))
	{         
		emit_sound(id, iChannel, gSounds[7], fVolume, fAttenuation, fFlags, iPitch);
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED; 
}

public ShowVips(id)
{
	new szName[32], szTempMessage[190], szMessage[190], iSize = ArraySize(aVIP);
	
	for(new i = 0; i < iSize; i++)
	{
		ArrayGetString(aVIP, i, szName, charsmax(szName));
		
		add(szTempMessage, charsmax(szTempMessage), szName);
		
		if(i == iSize - 1) add(szTempMessage, charsmax(szTempMessage), ".");
		else add(szTempMessage, charsmax(szTempMessage), ", ");
	}
	
	formatex(szMessage, charsmax(szMessage), szTempMessage);
	
	client_print_color(id, id, "^x04%s", szMessage);
	
	return PLUGIN_CONTINUE;
}

public VipStatus()
{
	new id = get_msg_arg_int(1);
	
	if(is_user_alive(id) && Get(id, iVip)) set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
}

public VipChat(id)
{
	if(Get(id, iVip))
	{
		new szText[190], szMessage[190];
		
		read_args(szText, charsmax(szText));
		remove_quotes(szText);
		
		if(szText[0] == '*' && szText[1])
		{
			new szName[32];
			
			get_user_name(id, szName, charsmax(szName));
			
			formatex(szMessage, charsmax(szMessage), "^x01(VIP CHAT) ^x03%s : ^x04%s", szName, szText[1]);
			
			for(new i = 1; i <= 32; i++) if(is_user_connected(i) && Get(i, iVip)) client_print_color(i, id, "%s", szMessage);

			return PLUGIN_HANDLED_MAIN;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public HandleSayText(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id) && Get(id, iVip))
	{
		new szTempMessage[190], szMessage[190], szPrefix[64], szSteamID[33];
		
		get_msg_arg_string(2, szTempMessage, charsmax(szTempMessage));
		get_user_authid(id, szSteamID, charsmax(szSteamID)); 
	
		if(equali(szSteamID, "STEAM_0:1:55664")) formatex(szPrefix, charsmax(szPrefix), "^x04[WLASCICIEL]");
		else formatex(szPrefix, charsmax(szPrefix), "^x04[VIP]");
		
		if(!equal(szTempMessage, "#Cstrike_Chat_All"))
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), " ");
			add(szMessage, charsmax(szMessage), szTempMessage);
		}
		else
		{
			add(szMessage, charsmax(szMessage), szPrefix);
			add(szMessage, charsmax(szMessage), "^x03 %s1^x01 :  %s2");
		}
		
		set_msg_arg_string(2, szMessage);
	}
	
	return PLUGIN_CONTINUE;
}

public _set_user_vip(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_H && !Get(id, iVip))
	{
		Set(id, iVip);
		
		new szName[32];
		
		get_user_name(id, szName, charsmax(szName));
	
		ArrayPushString(aVIP, szName);
	}
	
	return PLUGIN_CONTINUE;
}

public _get_user_vip(id)
	return Get(id, iVip);
	
Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
	return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
	return Ham_Item_PreFrame;
	#endif
}