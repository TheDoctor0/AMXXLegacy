#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "JailBreak: Wojna Gangow"
#define VERSION "1.0.8"
#define AUTHOR "Cypis & O'Zone"

#define TASK_HUD 6542

new gWeapons[] = { CSW_AWP, CSW_AK47, CSW_M4A1, CSW_FAMAS, CSW_HEGRENADE, CSW_FLASHBANG };

new gColor[][] = { "Czerwony", "Zielony", "Niebieski" };

new gGangColor[][3] = 
{
	{255, 0, 0},
	{0, 255, 0},
	{0, 0, 255}
};

new bool:bGame, iGang[33], id_zabawa, fmClientDisconnect, HamHook:hSpawn, HamHook:fHamKill, HamHook:fHamTakeDamage[2];

public plugin_init()
 {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	id_zabawa = jail_register_game("Wojna Gangow");
}

public plugin_precache()
	precache_generic("sound/reload/wojna.mp3");

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		if(hSpawn) DisableHamForward(hSpawn);

		if(fHamKill) DisableHamForward(fHamKill);

		if(fHamTakeDamage[0]) DisableHamForward(fHamTakeDamage[0]);

		if(fHamTakeDamage[1]) DisableHamForward(fHamTakeDamage[1]);

		if(fmClientDisconnect)
		{
			unregister_forward(FM_ClientDisconnect, fmClientDisconnect);
			
			fmClientDisconnect = 0;
		}
		
		if(task_exists(TASK_HUD)) remove_task(TASK_HUD);
		
		bGame = false;
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	static szTime[12];
	
	if(day == id_zabawa)
	{
		format_time(szTime, charsmax(szTime), "%M:%S", gTimeRound - 60);
		formatex(szInfo2, charsmax(szInfo2), "Zasady:^n%s - walka wiezniow miedzy grupami^nOstatni wiezien ma zyczenie^nNie wolno KAMPIC", szTime);
		
		szInfo = "Wojna Gangow";

		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);

		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
		
		for(new i = 1; i <= MAX; i++) SetGang(i);
		
		if(!hSpawn) hSpawn = RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
		else EnableHamForward(hSpawn);

		if(!fHamKill) fHamKill = RegisterHam(Ham_Killed, "player", "PlayerDeath", 1);
		else EnableHamForward(fHamKill);

		if(!fHamTakeDamage[0]) fHamTakeDamage[0] = RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
		else EnableHamForward(fHamTakeDamage[0]);

		if(!fHamTakeDamage[1]) fHamTakeDamage[1] = RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
		else EnableHamForward(fHamTakeDamage[1]);

		if(!fmClientDisconnect) fmClientDisconnect = register_forward(FM_ClientDisconnect, "ClientDisconnect");
	
		set_task(1.0, "DisplayHUD", TASK_HUD, .flags = "b");
		
		bGame = true;
	}
}

public PlayerSpawn(id)
	SetGang(id);

public SetGang(id)
{
	if(!is_user_alive(id) || !is_user_connected(id) || cs_get_user_team(id) != CS_TEAM_T) return;

	static iPlayerGang = 0;
	
	for(new j = 0; j < sizeof(gWeapons); j++)
	{
		new szWeapon[24];
		
		get_weaponname(gWeapons[j], szWeapon, charsmax(szWeapon));
		
		give_item(id, szWeapon);
		
		if(gWeapons[j] != CSW_HEGRENADE && gWeapons[j] != CSW_FLASHBANG && gWeapons[j] != CSW_SMOKEGRENADE) cs_set_user_bpammo(id, gWeapons[j], 100);
	}
	
	if(pev(id, pev_health) > 100) set_pev(id, pev_health, 100.0);
	
	set_user_rendering(id, kRenderFxGlowShell, gGangColor[iPlayerGang][0], gGangColor[iPlayerGang][1], gGangColor[iPlayerGang][2], kRenderNormal, 10);
	
	iGang[id] = iPlayerGang;

	if(++iPlayerGang >= 3) iPlayerGang = 0;
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== BLUE vs RED vs GREEN ==");

		jail_set_prisoners_fight(true, false, false);

		client_cmd(0, "mp3 play sound/reload/wojna.mp3");
	}
}

public TakeDamage(id, ent, attacker, Float:damage, damagebits)
	return vTakeDamage(id, attacker);

public TraceAttack(id, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
	return vTakeDamage(id, attacker);

vTakeDamage(id, attacker)
{
	if(!bGame || !is_user_connected(id) || !is_user_connected(attacker) || cs_get_user_team(id) != CS_TEAM_T || cs_get_user_team(attacker) != CS_TEAM_T) return HAM_IGNORED;
	
	if(iGang[attacker] == iGang[id]) return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public ClientDisconnect(id)
	CheckGangs();

public PlayerDeath(id, attacker, shouldgib)
{	
	if(!is_user_connected(id) || cs_get_user_team(id) != CS_TEAM_T) return;

	CheckGangs();
}

public CheckGangs()
{
	new iPlayerGang[3];
	
	for(new i = 1; i <= MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_T) continue;

		iPlayerGang[iGang[i]]++;
	}
	
	if(!(iPlayerGang[0] || iPlayerGang[1]) || !(iPlayerGang[1] || iPlayerGang[2]) || !(iPlayerGang[0] || iPlayerGang[2]))
	{
		if(fHamTakeDamage[0]) DisableHamForward(fHamTakeDamage[0]);

		if(fHamTakeDamage[1]) DisableHamForward(fHamTakeDamage[1]);
	}
}

public DisplayHUD(taskid)
{
	static SyncHudObj;
	
	if(!SyncHudObj) SyncHudObj = CreateHudSyncObj();
	
	set_hudmessage(255, 0, 0, 0.05, 0.40, .holdtime = 1.0);
	
	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i)) continue;

		if(cs_get_user_team(i) != CS_TEAM_T) continue;

		ShowSyncHudMsg(i, SyncHudObj, "Kolor: %s", gColor[iGang[i]]);
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
