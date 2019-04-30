#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <stripweapons>

#define PLUGIN "Ruletka 4FUN"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

#define ADMIN_FLAG_X (1<<23)

#define TASK_INFO 3045
#define TASK_RESET 3156
#define TASK_EXPLODE 3209
#define TASK_LOOK 3343
#define TASK_GODMODE 3495
#define TASK_NOCLIP 3543
#define TASK_POISON 3683
#define TASK_RESPAWN 3772
#define TASK_TELEPORT 3839
#define TASK_DISPLAY 3948 

new const max_clip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20, 
10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

new const szCommandClan[][] = { "say /ruletka", "say_team /ruletka", "say /los", "say_team /los", "say /r", "say_team /r" };

new const szTag[] = "^x03[Ruletka]^x01";

new const szSprites[][] =
{
	"sprites/dexplo.spr",
	"sprites/white.spr",
	"sprites/steam1.spr",
	"sprites/lgtning.spr"
};

new iSprite[sizeof szSprites];

new iRoulette, iSpeed, iSlow, iLook, iGlasses, iLowDmg, iMediumDmg, iHighDmg, iJumper, iJump, iNoRecoil, iBlinder,
iRecoil, iLongJump, iJumped, iBunnyHop, iAmmo, iPoison, iPoisoner, iOnlyHead, iNoHead, iRespawn, iReload;

new gRound, gFreezeTime;

native check_small_map();

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCommandClan; i++) register_clcmd(szCommandClan[i], "CmdRoulette");

	register_logevent("RoundStart", 2, "1=Round_Start");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("CurWeapon", "UnlimitedAmmo", "be", "1=1");
	
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_PlayerPreThink, "PreThink");
	register_forward(FM_UpdateClientData, "UpdateClientData", 1);
	register_forward(FM_TraceLine, "TraceLine", 1);
	
	register_message(get_user_msgid("ScreenFade"), "BlockFlashbang");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", 0);
	RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	RegisterHam(Ham_Spawn, "player", "Spawn", 1);
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "Player_ResetMaxSpeed", 1);
}

public plugin_precache()
{
	for(new i = 0; i < sizeof szSprites; i++) iSprite[i] = precache_model(szSprites[i]);

	precache_sound("ambience/thunder_clap.wav");
}

public client_authorized(id)
	Set(id, iRoulette);

public client_putinserver(id)
{
	if(!is_user_hltv(id) && !is_user_bot(id)) set_task(170.0, "ShowInfo", id + TASK_INFO, _, _, "b");
}

public client_disconnected(id)
{
	remove_task(id + TASK_INFO);
	remove_task(id + TASK_RESET);
	remove_task(id + TASK_DISPLAY);
	remove_task(id + TASK_GODMODE);
	remove_task(id + TASK_LOOK);
	remove_task(id + TASK_NOCLIP);
	remove_task(id + TASK_POISON);
	remove_task(id + TASK_RESPAWN);
	remove_task(id + TASK_TELEPORT);
	remove_task(id + TASK_EXPLODE);
}

public CmdRoulette(id)
{
	if(!is_user_alive(id))
	{
		client_print_color(id, id, "%s Nie mozesz korzystac z ruletki, gdy jestes^x04 martwy^x01.", szTag);
		return PLUGIN_HANDLED;
	}
	
	if(check_small_map())
	{
		client_print_color(id, id, "%s Ruletka na^x04 malych mapach^x01 jest^x04 wylaczona^x01.", szTag);
		return PLUGIN_HANDLED;
	}
	
	if(gRound == 1)
	{
		client_print_color(id, id, "%s Ruletka w^x04 pierwszej rundzie^x01 jest^x04 wylaczona^x01.", szTag);
		return PLUGIN_HANDLED;
	}
	
	if(!Get(id, iRoulette))
	{
		client_print_color(id, id, "%s Ruletka mozesz zakrecic raz na^x04 3 minuty^x01.", szTag);
		return PLUGIN_HANDLED;
	}
	
	client_print_color(id, id, "%s Losowanie trwa...", szTag);
	Rem(id, iRoulette);
	
	set_task(1.0, "RollRoulette", id);
	set_task(180.0, "ResetRoulette", id + TASK_RESET);

	return PLUGIN_HANDLED;
}

public RollRoulette(id)
{
	switch(random_num(1, 50))
	{
		case 1:
		{
			client_print_color(id, id, "%s Brawo, masz^x04 +100 HP^x01.", szTag);
			set_user_health(id, get_user_health(id) + 100);
		}
		case 2:
		{
			client_print_color(id, id, "%s Pech, zostales z^x04 1 HP^x01.", szTag);
			set_user_health(id, 1);
		}
		case 3:
		{
			client_print_color(id, id, "%s To nie twoj dzien, masz o^x04 polowe mniej HP^x01.", szTag);
			set_user_health(id, get_user_health(id)/2);
		}
		case 4:
		{
			client_print_color(id, id, "%s Niezle, dostales^x04 +50 HP^x01.", szTag);
			set_user_health(id, get_user_health(id) + 50);
		}
		case 5:
		{
			client_print_color(id, id, "%s Pieknie, wygrales^x04 M4A1^x01.", szTag);
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 6:
		{
			client_print_color(id, id, "%s Niezle, wygrales^x04 AK47^x01.", szTag);
			give_item(id,"weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 7:
		{
			client_print_color(id, id, "%s Mozesz czuc sie bezpieczniej, masz^x04 200 kamizelki^x01.", szTag);
			give_item(id, "item_assaultsuit");
			set_user_armor(id, 200);
		}
		case 8:
		{
			client_print_color(id, id, "%s Mozesz skradac sie bez obaw, masz^x04 ciche chodzenie^x01.", szTag);
			set_user_footsteps(id, 1);
		}
		case 9:
		{
			client_print_color(id, id, "%s Niestety, zaliczyles^x04 zgon^x01.", szTag);
			user_kill(id);
		}
		case 10:
		{
			client_print_color(id, id, "%s Dostales^x04 5 kopniakow^x01.", szTag);
			for(new i; i < 5; i++) user_slap(id, 1);
		}
		case 11:
		{
			client_print_color(id, id, "%s Mysle, ze przyda ci sie zestaw^x04 granatow^x01.", szTag);
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_smokegrenade");
		}
		case 12:
		{
			client_print_color(id, id, "%s A co to, wygrales^x04 5000$^x01.", szTag);
			cs_set_user_money(id, min(cs_get_user_money(id) + 5000, 16000));
		}
		case 13:
		{
			new iFrags = random_num(1, 3);
			
			client_print_color(id, id, "%s Dostales w prezencie^x04 %i frag%s^x01.", szTag, iFrags, iFrags > 1 ? "i" : "a");
			set_user_frags(id, get_user_frags(id) + iFrags);
		}
		case 14:
		{
			new iFrags = random_num(1, 3);

			if(get_user_frags(id) < iFrags)
			{
				RollRoulette(id);
				return PLUGIN_HANDLED;
			}
			
			client_print_color(id, id, "%s Tak bywa, straciles^x04 %i frag%s^x01.", szTag, iFrags, iFrags > 1 ? "i" : "a");
			set_user_frags(id, get_user_frags(id) - iFrags);
		}
		case 15:
		{
			client_print_color(id, id, "%s Wow, jestes calkowicie^x04 niewidzialny^x01.", szTag);
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
		}
		case 16:
		{
			client_print_color(id, id, "%s Niezle, jestes prawie^x04 niewidzialny^x01.", szTag);
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 60);
		}
		case 17:
		{
			client_print_color(id, id, "%s Poskacz sobie, masz mniejsza^x04 grawitacje^x01.", szTag);
			set_user_gravity(id, 0.4);
		}
		case 18:
		{
			client_print_color(id, id, "%s Chyba trafiles na Jowisza, masz wieksza^x04 grawitacje^x01.", szTag);
			set_user_gravity(id, 1.5);
		}
		case 19:
		{
			new iDeaths = random_num(1, 3);

			if(get_user_deaths(id) < iDeaths)
			{
				RollRoulette(id);
				return PLUGIN_HANDLED;
			}
			
			client_print_color(id, id, "%s Ciesz sie, odjalem ci^x04 %i zgon%s^x01.", szTag, iDeaths, iDeaths > 1 ? "y" : "");
			cs_set_user_deaths(id, get_user_deaths(id) - iDeaths);
		}
		case 20:
		{
			new iDeaths = random_num(1, 3);
			
			client_print_color(id, id, "%s Niestety, masz^x04 %i zgon%s^x01 wiecej^x01.", szTag, iDeaths, iDeaths > 1 ? "y" : "");
			cs_set_user_deaths(id, get_user_deaths(id) + iDeaths);
		}
		case 21:
		{
			client_print_color(id, id, "%s Wylosowales zestaw snipera, dostajesz^x04 AWP + Deagle^x01.", szTag);
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 30);
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
		}
		case 22:
		{
			client_print_color(id, id, "%s Ups... Ktos wyczyscil ci^x04 konto^x01.", szTag);
			cs_set_user_money(id, 0);
		}
		case 23:
		{
			client_print_color(id, id, "%s Hohoho, ale sie^x04 zjarales^x01.", szTag);
			set_task(1.0, "Look", id + TASK_LOOK, _, _, "b");
			Set(id, iLook);
		}
		case 24:
		{
			client_print_color(id, id, "%s Jestes na koksie,^x04 szybciej biegasz^x01.", szTag);
			Set(id, iSpeed);
		}
		case 25:
		{
			client_print_color(id, id, "%s Postarzales sie,^x04 wolniej biegasz^x01.", szTag);
			Set(id, iSlow);
		}
		case 26:
		{
			client_print_color(id, id, "%s Raz, dwa, trzy, dzis^x04 bez broni^x01 jestes ty.", szTag);
			StripWeapons(id, Primary);
			StripWeapons(id, Secondary);
			StripWeapons(id, Grenades);
		}
		case 27:
		{
			client_print_color(id, id, "%s Jestes bogaty, masz^x04 16000$^x01.", szTag);
			cs_set_user_money(id, 16000);
		}
		case 28:
		{
			client_print_color(id, id, "%s Jestes^x04 niesmiertelny^x01 przez^x04 10 sekund^x01.", szTag);
			set_bartime(id, 10);
			set_user_godmode(id, 1);
			set_task(10.0, "RemoveGodMode", id + TASK_GODMODE);
		}
		case 29:
		{
			client_print_color(id, id, "%s Przez^x04 15 sekund^x01 mozesz^x04 przechodzic przez sciany^x01.", szTag);
			set_user_noclip(id, 1);
			set_bartime(id, 15);
			set_task(15.0, "RemoveNoclip", id + TASK_NOCLIP);
		}
		case 30:
		{
			client_print_color(id, id, "%s Masz ciemne okulary, nie dzialaja na ciebie^x04 granaty oslepiajace^x01.", szTag);
			Set(id, iGlasses);
		}
		case 31:
		{
			client_print_color(id, id, "%s Twoje bronie sa bezuzyteczne, zadajesz ze wszystkich po^x04 3 obrazenia^x01.", szTag);
			Set(id, iLowDmg);
		}
		case 32:
		{
			client_print_color(id, id, "%s Podrasowalem nieco twoj sprzet. Zadajesz^x04 +5 obrazen^x01.", szTag);
			Set(id, iMediumDmg);
		}
		case 33:
		{
			client_print_color(id, id, "%s Teraz bedzie zabawa. Zadajesz^x04 +15 obrazen^x01.", szTag);
			Set(id, iHighDmg);
		}
		case 34:
		{
			client_print_color(id, id, "%s Jest moc, mozesz raz^x04 podskoczyc w powietrzu^x01.", szTag);
			Set(id, iJumper);
		}
		case 35:
		{
			client_print_color(id, id, "%s Stales sie chodzaca^x04 bomba^x01, wybuchniesz za^x04 10 sekund^x01.", szTag);
			set_bartime(id, 10);
			set_task(10.0, "EffectExplode", id + TASK_EXPLODE);
		}
		case 36:
		{
			client_print_color(id, id, "%s To jest to, nie masz^x04 odrzutu^x01 w broniach.", szTag);
			Set(id, iNoRecoil);
		}
		case 37:
		{
			client_print_color(id, id, "%s Ok, masz^x04 mniejszy odrzut^x01 w broniach.", szTag);
			Set(id, iRecoil);
		}
		case 38:
		{
			client_print_color(id, id, "%s Mozesz skakac jak krolik, masz^x04 BunnyHop^x01.", szTag);
			Set(id, iBunnyHop);
		}
		case 39:
		{
			client_print_color(id, id, "%s Chyba czyms sie zatrules. Tracisz^x04 5 HP^x01 co^x04 3 sekundy^x01.", szTag);
			Set(id, iPoison);
			set_task(3.0, "Poisoning", id + TASK_POISON, _, _, "a", 10);
		}
		case 40:
		{
			client_print_color(id, id, "%s Calkiem, calkiem. Masz^x01 20% na zatrucie gracza^x04 przy trafieniu^x01.", szTag);
			Set(id, iPoisoner);
		}
		case 41:
		{
			client_print_color(id, id, "%s No niezle. Masz^x01 25% na oslepienie gracza^x04 przy trafieniu^x01.", szTag);
			Set(id, iBlinder);
		}
		case 42:
		{
			client_print_color(id, id, "%s Tak, tak, tak. Masz^x04 nieskonczona amunicje^x01.", szTag);
			Set(id, iAmmo);
			set_user_clip(id, 31);
		}
		case 43:
		{
			client_print_color(id, id, "%s Ooo.. popatrz. Masz^x04 ubranie wroga^x01.", szTag);

			if(get_user_flags(id) && ADMIN_FLAG_X) cs_reset_user_model(id);

			ChangeSkin(id, 0);
		}
		case 44:
		{
			client_print_color(id, id, "%s Szykuj sie. Za^x04 3 sekundy^x01 teleportuje cie na^x04 resp wroga^x01.", szTag);

			if(get_user_flags(id) && ADMIN_FLAG_X) cs_reset_user_model(id);

			ChangeSkin(id, 0);

			set_task(3.0, "Teleport", id + TASK_TELEPORT);
		}
		case 45:
		{
			client_print_color(id, id, "%s Wylosowales^x04 Long Jump^x01. Kucnij i wcisnij spacje, aby skoczyc.", szTag);
			Set(id, iLongJump);
		}
		case 46:
		{
			client_print_color(id, id, "%s Zabawmy sie w^x04 medyka^x01. Ustawilem ci losowa ilosc^x04 zycia^x01.", szTag);
			set_user_health(id, random_num(1, 200));
		}
		case 47:
		{
			client_print_color(id, id, "%s Dostajesz specjalny pancerz. Mozna cie zabic tylko^x04 strzalami w glowe^x01.", szTag);
			Set(id, iOnlyHead);
		}
		case 48:
		{
			client_print_color(id, id, "%s Zakladaj tytanowy helm. Nie dzialaja na ciebie^x04 strzaly w glowe^x01.", szTag);
			Set(id, iNoHead);
		}
		case 49:
		{
			client_print_color(id, id, "%s ladnie. Odrodzisz sie po smierci, bo masz^x04 respawn^x01.", szTag);
			Set(id, iRespawn);
		}
		case 50:
		{
			client_print_color(id, id, "%s Yeah! Masz zwinne palce, wiec^x04 natychmiastowo^x01 przeladowujesz bron.", szTag);
			Set(id, iReload);
		}
	}
	return PLUGIN_CONTINUE;
}

public ResetRoulette(id)
{
	id -= TASK_RESET;
	
	Set(id, iRoulette);
	client_print_color(id, id, "%s Mozesz ponownie uzyc^x04 ruletki^x01.", szTag);
}

public ShowInfo(id)
{
	id -= TASK_INFO;
	
	if(is_user_connected(id)) client_print_color(id, id, "%s Aby uzyc ruletki wpisz^x04 /ruletka", szTag);
}

public GameCommencing()
	gRound = 0;

public NewRound()
{
	gFreezeTime = true;
	gRound++;
}

public RoundStart()
	gFreezeTime = false;

public Spawn(id)
{
	if(is_user_alive(id))
	{
		ChangeSkin(id, 1);
		
		set_user_footsteps(id, 0);
		set_user_gravity(id, 1.0);
		set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
		set_user_health(id, 100);

		message_begin(MSG_ONE, 95, {0,0, 0}, id);
		write_byte(90);
		message_end();
			
		Rem(id, iLook);
		Rem(id, iSpeed);
		Rem(id, iSlow);
		Rem(id, iGlasses);
		Rem(id, iLowDmg);
		Rem(id, iMediumDmg);
		Rem(id, iHighDmg);
		Rem(id, iJumper);
		Rem(id, iNoRecoil);
		Rem(id, iRecoil);
		Rem(id, iBunnyHop);
		Rem(id, iAmmo);
		Rem(id, iLongJump);
		Rem(id, iReload);
		Rem(id, iPoisoner);
		Rem(id, iPoison);
		Rem(id, iOnlyHead);
		Rem(id, iNoHead);
		Rem(id, iReload);
		Rem(id, iBlinder);
	}
}

public PlayerKilled(id)
	if(Get(id, iRespawn)) set_task(0.1, "Respawn", id + TASK_RESPAWN);

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id)) return FMRES_IGNORED;

	new iFlags = pev(id, pev_flags);

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(iFlags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && Get(id, iJump) && Get(id, iJumper))
	{
		Rem(id, iJump);
		new Float:fVelocity[3];
		pev(id, pev_velocity, fVelocity);
		fVelocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity, fVelocity);
	}
	else if(iFlags & FL_ONGROUND) Set(id, iJump);
		
	if(Get(id, iRecoil) && get_uc(uc_handle, UC_Buttons) & IN_ATTACK)
	{
		new Float:fPunchAngle[3];
		pev(id, pev_punchangle, fPunchAngle);
		for(new i = 0; i < 3; i++) fPunchAngle[i] *= 0.9;
		set_pev(id, pev_punchangle, fPunchAngle);
	}
	
	if(Get(id, iReload))
	{
		new iButtons = get_uc(uc_handle, UC_Buttons);
		new iOldButtons = pev(id, pev_oldbuttons);
		new clip, ammo, weapon = get_user_weapon(id, clip, ammo);
	
		if(max_clip[weapon] == -1 || !ammo) return FMRES_IGNORED;
	
		if((iButtons & IN_RELOAD && !(iOldButtons & IN_RELOAD) && !(iButtons & IN_ATTACK)) || !clip)
		{
			cs_set_user_bpammo(id, weapon, ammo - (max_clip[weapon] - clip));
			new new_ammo = (max_clip[weapon] > ammo)? clip + ammo: max_clip[weapon]
			set_user_clip(id, new_ammo);
		}
	}

	return FMRES_IGNORED;
}

public PreThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
		
	if(Get(id, iNoRecoil)) set_pev(id, pev_punchangle, {0.0,0.0,0.0});

	if (entity_get_int(id, EV_INT_button) & 2 && Get(id, iBunnyHop)) 
	{
		entity_set_float(id, EV_FL_fuser2, 0.0);
		new iFlags = entity_get_int(id, EV_INT_flags);

		if(iFlags & FL_WATERJUMP) return PLUGIN_CONTINUE;
		if(entity_get_int(id, EV_INT_waterlevel) >= 2) return PLUGIN_CONTINUE;
		if(!(iFlags & FL_ONGROUND)) return PLUGIN_CONTINUE;

		new Float:fVelocity[3];
		entity_get_vector(id, EV_VEC_velocity, fVelocity);
		fVelocity[2] += 250.0;
		entity_set_vector(id, EV_VEC_velocity, fVelocity);

		entity_set_int(id, EV_INT_gaitsequence, 6);
	}
	
	if(!Get(id, iLongJump)) return PLUGIN_CONTINUE;
		
	new iButton = get_user_button(id);
	
	if((iButton & IN_DUCK) && (iButton & IN_JUMP) && !(get_user_oldbutton(id) & IN_JUMP) && !Get(id, iJumped)) 
	{ 
		new iFlags = pev(id,pev_flags);
		if(iFlags & FL_ONGROUND) 
		{ 
			set_pev(id, pev_flags, iFlags & ~FL_ONGROUND);

			new Float:fAngle[3], Float:fVelocity[3];
			entity_get_vector(id, EV_VEC_v_angle, fAngle);
			fVelocity[0] = floatcos(fAngle[1]/180.0*M_PI)*560.0;
			fVelocity[1] = floatsin(fAngle[1]/180.0*M_PI)*560.0;
			fVelocity[2] = 300.0;
			entity_set_vector(id,EV_VEC_velocity, fVelocity);

			Set(id, iJumped);
		} 
	}
	else Rem(id, iJumped);
		
	return PLUGIN_CONTINUE;
}

public UpdateClientData(id, sw, cd_handle)
	if(Get(id, iNoRecoil) && is_user_alive(id)) set_cd(cd_handle, CD_PunchAngle, {0.0,0.0,0.0});

public TraceLine(Float:fStart[3], Float:fEnd[3], conditions, id, trace)
{	
	if(!is_user_alive(id)) return FMRES_IGNORED;
		
	static entity; entity = get_tr2(trace, TR_pHit);
		
	if(!is_user_alive(entity) || id == entity) return FMRES_IGNORED;

	static hit; hit = get_tr2(trace, TR_iHitgroup);
	
	if(hit == HIT_HEAD && Get(entity, iNoHead)) set_tr2(trace, TR_iHitgroup, 8);
		
	if(hit != 1 && Get(entity, iOnlyHead)) 
	{
		set_tr2(trace, TR_flFraction, 1.0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
	if(!is_user_alive(iVictim) || !is_user_alive(iAttacker)) return HAM_IGNORED;
		
	if(Get(iAttacker, iPoisoner) && random_num(1, 5) == 1)
	{
		Set(iVictim, iPoison);
		set_task(3.0, "Poisoning", iVictim + TASK_POISON, _, _, "a", 10);
	}
	
	if(Get(iAttacker, iBlinder) && random_num(1, 4) == 1)
		DisplayFade(iVictim, 1<<14, 1<<14, 1<<16, 0, 255, 0, 230);
	
	if(Get(iAttacker, iLowDmg))
	{
		SetHamParamFloat(4, 3.0);
		return HAM_HANDLED;
	}
	
	if(Get(iAttacker, iMediumDmg))
	{
		SetHamParamFloat(4, fDamage + 5.0);
		return HAM_HANDLED;
	}
	
	if(Get(iAttacker, iHighDmg))
	{
		SetHamParamFloat(4, fDamage + 15.0);
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public Player_ResetMaxSpeed(id)
{
	if(!gFreezeTime && is_user_alive(id))
	{
		if(Get(id, iSpeed)) set_user_maxspeed(id, get_user_maxspeed(id) + 50);
		if(Get(id, iSlow)) set_user_maxspeed(id, get_user_maxspeed(id) - 50)
	}
}

public BlockFlashbang(msgId, msgType, id)
{
	if(!Get(id, iGlasses) || !is_user_connected(id)) return PLUGIN_CONTINUE;
	
	if(get_msg_arg_int(4) == 255 && get_msg_arg_int(5) == 255 && get_msg_arg_int(6) == 255 && get_msg_arg_int(7) > 199) return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public RemoveGodMode(id)
{
	id -= TASK_GODMODE;
	
	set_user_godmode(id, 0);
}

public RemoveNoclip(id)
{
	id -= TASK_NOCLIP;
	
	set_user_noclip(id, 0);
	
	if(is_user_alive(id))
	{
		set_pev(id, pev_movetype, MOVETYPE_WALK);

		new Float:fOrigin[3];

		pev(id, pev_origin, fOrigin);

		if(!is_hull_vacant(fOrigin, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id)) user_silentkill(id);
	}
}

public Respawn(id)
{
	id -= TASK_RESPAWN;
	
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	Rem(id, iRespawn);
}

public UnlimitedAmmo(id) 
{
	if(!is_user_alive(id) || !Get(id, iAmmo)) return 0;

	set_user_clip(id, 31);

	return 0;
}

public Look(id)
{
	id -= TASK_LOOK;

	if(!is_user_alive(id)) return;
	
	if(Get(id, iLook))
	{
		message_begin(MSG_ONE, 95, {0,0,0}, id);
		write_byte(150);
		message_end();
	}
	else
	{
		message_begin(MSG_ONE, 95, {0,0,0}, id);
		write_byte(90);
		message_end();
		remove_task(id + TASK_LOOK);
	}
}

public Teleport(id)
{
	id -= TASK_TELEPORT;
	
	if(!is_user_alive(id)) return;
	
	teleport_to_enemy_spawn(id);
}

public Poisoning(id) 
{
	id -= TASK_POISON;
	
	if(!is_user_alive(id) || !Get(id, iPoison))
	{
		remove_task(id + TASK_POISON);
		return;
	}
	
	new health = get_user_health(id);
	set_user_health(id, health <= 5 ? 1 : (health - 5));
}

public ChangeSkin(id, reset)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE;

	if (reset) cs_reset_user_model(id);
	else
	{
		static CT_Skins[4][] = {"sas", "gsg9", "urban", "gign"};
		static Terro_Skins[4][] = {"arctic", "leet", "guerilla", "terror"};
	
		new iNum = random_num(0,3);
		cs_set_user_model(id, (get_user_team(id) == 1)? CT_Skins[iNum]: Terro_Skins[iNum]);
	}

	return PLUGIN_CONTINUE;
}

public EffectExplode(id)
{
	id -= TASK_EXPLODE;
	
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
		
	new Float:fOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin);

	new iOrigin[3];
	for(new i = 0;i <= 2; i++) iOrigin[i] = floatround(fOrigin[i]);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(iSprite[0]);
	write_byte(32);
	write_byte(20);
	write_byte(0);
	message_end();
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1] + 200);
	write_coord(iOrigin[2] + 200);
	write_short(iSprite[1]);
	write_byte(0);
	write_byte(0);
	write_byte(10);
	write_byte(10);
	write_byte(255);
	write_byte(255);
	write_byte(100);
	write_byte(100);
	write_byte(128);
	write_byte(0);
	message_end();

	new iEntList[33], iNum = find_sphere_class(id, "player", 250.0, iEntList, 32);
	
	for (new i = 0; i <= iNum; i++)
	{	
		new pid = iEntList[i]

		if (is_user_alive(pid) && get_user_team(id) != get_user_team(pid)) ExecuteHam(Ham_TakeDamage, pid, 0.0, id, 100.0, (1<<24));
	}
	
	user_silentkill(id);
	
	return PLUGIN_CONTINUE;
}

stock DisplayFade(id, duration, holdtime, fadetype, red, green, blue, alpha)
{
	if(!pev_valid(id)) return;
		
	static msgScreenFade;
	
	if(!msgScreenFade) msgScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE, msgScreenFade, {0, 0, 0}, id);
	write_short(duration);
	write_short(holdtime);
	write_short(fadetype);
	write_byte(red);	
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}

stock set_bartime(id, duration)
{
	static msgBartime;
	
	if(!msgBartime) msgBartime = get_user_msgid("BarTime");

	message_begin(MSG_ONE, msgBartime, _, id);
	write_short(duration);
	message_end();
}

stock set_user_clip(id, ammo) 
{
	new szWeaponName[32], iWeaponID = -1, iWeapon = get_user_weapon(id, _, _);
	get_weaponname(iWeapon, szWeaponName, charsmax(szWeaponName));
	
	while((iWeaponID = engfunc(EngFunc_FindEntityByString, iWeaponID, "classname", szWeaponName)) != 0)
	{
		if(pev(iWeaponID, pev_owner) == id) 
		{
			set_pdata_int(iWeaponID, 51, ammo, 4);
			return iWeaponID;
		}
	}
	return 0;
}

public teleport_to_enemy_spawn(id)
{
   new iOrigin[3], Float:fOrigin[3], Float:fAngle[3];
   new iTeam = get_user_team(id);

   if(iTeam == 1) find_free_spawn(2, fOrigin, fAngle);
   else find_free_spawn(1, fOrigin, fAngle);
   FVecIVec(fOrigin, iOrigin);

   set_user_origin(id, iOrigin);
   set_pev(id, pev_angles, fAngle);
}

stock const spawnEntString[2][] = {"info_player_start","info_player_deathmatch"}

stock find_free_spawn(iTeamNumber, Float:spawnOrigin[3], Float:spawnAngle[3])
{
	new iSpawn;
	if(iTeamNumber == 2) iSpawn=0;
	else iSpawn=1;

	const maxSpawns = 128;
	new spawnPoints[maxSpawns], bool:spawnChecked[maxSpawns], spawnpoint, spawnnum;
	new ent = -1, spawnsFound = 0;

	while((ent = fm_find_ent_by_class(ent, spawnEntString[iSpawn])) && spawnsFound < maxSpawns) spawnPoints[spawnsFound++] = ent;

	new Float:vicinity = 100.0;
	new i, entList[1];

	for(i = 0; i<maxSpawns; i++) spawnChecked[i] = false;

	i = 0;
	while(i++ < spawnsFound*10)
	{
		spawnnum = random(spawnsFound);
		spawnpoint = spawnPoints[spawnnum];

		if(spawnpoint && !spawnChecked[spawnnum])
		{
			spawnChecked[spawnnum] = true;

			pev(spawnpoint, pev_origin, spawnOrigin);

			if(!fm_find_sphere_class(0, "player", vicinity, entList, 1, spawnOrigin))
			{
				pev(spawnpoint, pev_angles, spawnAngle);
				return spawnpoint;
			}
		}
	}

	return 0;
 }

stock fm_find_sphere_class(ent, const _classname[], Float:radius, entlist[], maxents, Float:origin[3]={0.0,0.0,0.0})
{
	if(pev_valid(ent)) pev(ent, pev_origin, origin);

	new tempent, tempclass[32], entsfound;
	while((tempent = fm_find_ent_in_sphere(tempent, origin, radius)) && entsfound < maxents)
	{
		if(pev_valid(tempent))
		{
			pev(tempent, pev_classname, tempclass, 31);
			if(equal(_classname, tempclass ))
				entlist[entsfound++] = tempent;
		}
	}

	return entsfound;
}

stock bool:is_hull_vacant(const Float:fOrigin[3], hull, id)
{
	static tr;
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, hull, id, tr);

	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) return true;

	return false;
}