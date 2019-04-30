#include <amxmodx>
#include <jailbreak>
#include <hamsandwich>
#include <fakemeta_util>

#define PLUGIN "JailBreak: Berek"
#define VERSION "1.0.9"
#define AUTHOR "Cypis & O'Zone"

#define TASK_BEREK 12398
#define TASK_BEREK_WAIT 12921

new id_zabawa, bool:bGame, bool:bEnd, iPlayerTeam[33];

new HamHook:fHamKill, HamHook:fHamTakeDamage[2];
new fmClientDisconnect;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_zabawa = jail_register_game("Berek");
}

public plugin_precache()
	precache_generic("sound/reload/berek.mp3");

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
{
	if(day == id_zabawa)
	{
		bGame = false;
		
		for(new id = 1; id <= MAX; id++) remove_task(TASK_BEREK + id);
		
		SetZabawa(false);
	}
}

public OnDayStartPre(day, szInfo[256], szInfo2[256], setting[10], gTimeRound)
{	
	if(day == id_zabawa)
	{
		formatex(szInfo2, 256, "Zasady:^nWylosowany zostanie wiezien ktory jest berkiem^nBerek ma 15 sekund na oddanie berka, jezeli tego nie zrobi ginie i zostaje losowany nowy berek^nOstatni wiezien ma zyczenie!");
		szInfo = "Berek";
		
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 3;
		setting[6] = 1;
		setting[7] = 3;
		setting[8] = 1;
		
		bGame = true;
	}
}

public OnDayStartPost(day)
{
	if(day == id_zabawa)
	{
		SetZabawa(true);
		
		bEnd = false;
		
		jail_open_cele();
		
		jail_set_game_hud(15, "Rozpoczecie zabawy za");
	
		for(new i = 1; i <= MAX; i++) iPlayerTeam[i] = 0;
	}
}

public OnGameHudEnd(day)
{
	if(day == id_zabawa)
	{
		if(!bEnd)
		{
			bEnd = true;

			client_cmd(0, "mp3 play sound/reload/berek.mp3");
			
			jail_set_game_hud(300, "Koniec zabawy za");
			
			UstawPrzydzial(RandomPlayer(1), 0);
		}
		else
		{
			bEnd = false;	
			
			client_print_color(0, print_team_default, "^x04[WIEZIENIE CS-RELOAD]^x01 Zabawa dobiegla konca. Losowo zostal wybrany zwyciezca.");
			
			new iRandom = RandomPlayer(1);
			
			for(new i = 1; i <= MAX; i++)
			{
				if(!is_user_alive(i) || !is_user_connected(i) || get_user_team(i) != 1 || i == iRandom) continue;
			
				user_silentkill(i);
			}
		}
	}
}

public UstawPrzydzial(id, old)
{
	if(!is_user_alive(id) || get_user_team(id) != 1) return;
	
	if(is_user_alive(old))
	{
		remove_task(TASK_BEREK+old);
		
		fm_set_rendering(old);
		
		iPlayerTeam[old] = 0;
		
		createBarTime(old, 0);
		
		jail_set_user_speed(old, 220.0);
	}
	
	new last = jail_get_prisoner_last();
	
	if(last && last == id) return;
	
	ExecuteHam(Ham_TakeDamage, id, 0, 0, 20.0, DMG_BULLET);
	
	jail_set_user_speed(id, 250.0);
	fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25);
	iPlayerTeam[id] = 1;
	
	createBarTime(id, 15, 0);

	set_dhudmessage(255, 255, 0, -1.0, 0.30, 2, 6.0, 3.0, 0.1, 1.5);
	show_dhudmessage(id, "B-E-R-E-K");
	
	remove_task(TASK_BEREK+id);
	set_task(15.0, "task_berek", TASK_BEREK+id);
}

public task_berek(id)
{
	id -= TASK_BEREK;
	
	if(!is_user_alive(id) || iPlayerTeam[id] != 1 || !bGame) return;

	new last = jail_get_prisoner_last();
	
	if(last && last == id) return;

	user_kill(id);
	
	UstawPrzydzial(RandomPlayer(1), 0);
}

public SetZabawa(bool:wartosc)
{
	if(wartosc)
	{
		if(!fHamKill)
			fHamKill = RegisterHam(Ham_Killed, "player", "SmiercGraczaPost", 1);
		else
			EnableHamForward(fHamKill);
			
		if(!fHamTakeDamage[0])
			fHamTakeDamage[0] = RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
		else
			EnableHamForward(fHamTakeDamage[0]);
			
		if(!fHamTakeDamage[1])
			fHamTakeDamage[1] = RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
		else
			EnableHamForward(fHamTakeDamage[1]);
			
		if(!fmClientDisconnect)
			fmClientDisconnect = register_forward(FM_ClientDisconnect, "fwClientDisconnect");
	}
	else
	{
		if(fHamKill)
			DisableHamForward(fHamKill);
		
		if(fHamTakeDamage[0])
			DisableHamForward(fHamTakeDamage[0]);
			
		if(fHamTakeDamage[1])
			DisableHamForward(fHamTakeDamage[1]);
			
		if(fmClientDisconnect)
		{
			unregister_forward(FM_ClientDisconnect, fmClientDisconnect);
			fmClientDisconnect = 0;
		}
	}
}

/////////////////////////////////
public TakeDamage(id, ent, attacker, Float:damage, damagebits)
	return vTakeDamage(id, attacker);

public TraceAttack(id, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
	return vTakeDamage(id, attacker);

vTakeDamage(id, attacker)
{
	if(!bGame || !is_user_connected(id) || get_user_team(id) != 1)
		return HAM_IGNORED;
		
	if(!is_user_connected(attacker) || get_user_team(attacker) != 1)
		return HAM_IGNORED;
	
	if(iPlayerTeam[attacker] == iPlayerTeam[id])
		return HAM_SUPERCEDE;

	if(task_exists(TASK_BEREK_WAIT+attacker))
	return HAM_SUPERCEDE;
	
	if(iPlayerTeam[id] == 1 && iPlayerTeam[attacker] == 0)
	return HAM_SUPERCEDE;	
		
	if(iPlayerTeam[attacker] == 1 && iPlayerTeam[id] == 0)
	{
		set_task(2.0, "task_wait", TASK_BEREK_WAIT+id);
		UstawPrzydzial(id, attacker);
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public task_wait() {}

public fwClientDisconnect(id)
{
	if(!bGame || iPlayerTeam[id] == 1 && get_user_team(id) == 1)
	{
		iPlayerTeam[id] = 0;
		UstawPrzydzial(RandomPlayer(1), 0);
	}
}

public SmiercGraczaPost(id, attacker, shouldgib)
{	
	if(!bGame || !is_user_connected(id) || get_user_team(id) != 1 || iPlayerTeam[id] != 1) return;

	iPlayerTeam[id] = 0;
	id = RandomPlayer(1);
	
	UstawPrzydzial(id, 0);
}

stock createBarTime(id, iTime, startprogress = 0)
{
	static barTime2;
	if(!barTime2)	
		barTime2 = get_user_msgid("BarTime2");
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, barTime2, _, id)
	write_short( iTime );
	write_short( startprogress );
	message_end(); 
}