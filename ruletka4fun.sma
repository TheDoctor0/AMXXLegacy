#include <amxmodx>
#include <fun>
#include <colorchat>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <StripWeapons>

#define PLUGIN "Ruletka"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define is_user_player(%1) 1 <= %1 <= g_MaxClients

#define TASK_INFO 545
#define TASK_RESET 656
#define TASK_LOOK 743
#define TASK_DISPLAY 883

new tag[] = "Ruletka"
new bool:g_Ruletka[33]
new bool:g_FreezeTime
new bool:speed[33]
new bool:slow[33]
new bool:dark_glasses[33]
new bool:low_dmg[33]
new bool:high_dmg[33]
new bool:jumper[33]
new bool:no_recoil[33]
new bool:bunny_hop[33]
new bool:ammo[33]
new bool:look[33]
new bool:long_jump[33]
new bool:jumped[33]
new bool:cut_throat[33]
new lightning[33]
new poison[33]
new jump[33]
new sprite_blast
new sprite_white
new g_Round
new max_players
new sprSmoke
new sprLightning
new msg_bartime
new msg_damage
new msg_screenfade

native check_small_map();

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("say /ruletka", "CmdRuletka")
	register_clcmd("say_team /ruletka", "CmdRuletka")
	register_clcmd("say /los", "CmdRuletka")
	register_clcmd("say_team /los", "CmdRuletka")
	
	register_logevent("round_start", 2, "1=Round_Start")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("CurWeapon", "UnlimitedAmmo", "be", "1=1")
	
	register_forward(FM_CmdStart, "CmdStart")
	register_forward(FM_PlayerPreThink, "PreThink")
	
	register_message(get_user_msgid("ScreenFade"), "block_flashbang")
	
	RegisterHam(Ham_Touch, "weaponbox", "HamTouchPre", 0) 
	RegisterHam(Ham_Touch, "armoury_entity", "HamTouchPre", 0)
	RegisterHam(Ham_TakeDamage, "player","TakeDamage", 0)
	RegisterHam(Ham_Spawn , "player" , "Spawn" , 1)
	RegisterHam(get_player_resetmaxspeed_func(), "player", "Player_ResetMaxSpeed", 1)
	
	msg_bartime = get_user_msgid("BarTime")
	msg_damage = get_user_msgid("Damage")
	msg_screenfade = get_user_msgid("ScreenFade")
	max_players = get_maxplayers()
}

public plugin_natives()
{
	register_native("is_user_cut_throat", "is_user_cut_throat")
}

public plugin_precache()
{
	sprite_white = precache_model("sprites/white.spr")
	sprite_blast = precache_model("sprites/dexplo.spr")
	precache_sound("ambience/thunder_clap.wav")
	sprSmoke = precache_model("sprites/steam1.spr")
	sprLightning = precache_model("sprites/lgtning.spr")
}

public client_authorized(id)
	g_Ruletka[id] = true

public client_disconnect(id)
{
	remove_task(id+TASK_INFO)
	remove_task(id+TASK_RESET)
}
	
public Spawn(id)
{
	if(!task_exists(id+TASK_INFO))
		set_task(170.0, "info", id+TASK_INFO, _, _, "b")
}

public Reset(id)
{
	id -= TASK_RESET
	g_Ruletka[id] = true
	ColorChat(id, RED, "[%s]^x01 Mozesz juz uzyc ponownie^x04 ruletki^x01.",tag)
}

public CmdRuletka(id)
{
	if(!is_user_alive(id))
	{
		ColorChat(id, RED, "[%s]^x01 Widziales kiedys trupa w kasynie?", tag)
		return PLUGIN_HANDLED
	}
	
	if(check_small_map())
	{
		ColorChat(id, RED, "[%s]^x01 Ruletka na malych mapach jest^x03 wylaczona^x01.",tag)
		return PLUGIN_HANDLED
	}
	
	if(g_Round < 2)
	{
		ColorChat(id, RED, "[%s]^x01 Ruletka w^x04 pierwszej rundzie^x01 jest^x03 wylaczona^x01.",tag)
		return PLUGIN_HANDLED
	}
	
	if(!g_Ruletka[id])
	{
		ColorChat(id, RED, "[%s]^x01 Ruletke mozna uzyc raz na 3 minuty.", tag)
		return PLUGIN_HANDLED
	}
	
	ColorChat(id, RED, "[%s]^x01 Rozpoczynam losowanie...", tag)
	set_task(1.0, "RuletkaLosuj", id)
	g_Ruletka[id] = false
	set_task(180.0, "Reset", id+TASK_RESET)

	return PLUGIN_HANDLED
}

public RuletkaLosuj(id)
{
	switch(random_num(1, 40))
	{
	case 1 :
		{
			ColorChat(id, RED, "[%s]^x01 Brawo, masz^x04 +100 HP^x01.", tag)
			set_user_health(id, get_user_health(id)+100)
		}
	case 2 :
		{
			ColorChat(id, RED, "[%s]^x01 Pech, zostales z^x04 1 HP^x01.", tag)
			set_user_health(id,1)
		}
	case 3:
		{
			ColorChat(id, RED, "[%s]^x01 Przyda ci sie dobra bron, lap^x04 M4A1^x01.", tag)
			give_item(id,"weapon_m4a1")
			give_item(id, "ammo_556nato")
			give_item(id, "ammo_556nato")
			give_item(id, "ammo_556nato")
			give_item(id, "ammo_556nato")
		}
	case 4:
		{
			ColorChat(id, RED, "[%s]^x01 Prosze bardzo, wez^x04 AK47^x01.", tag)
			give_item(id,"weapon_ak47")
			give_item(id, "ammo_762nato")
			give_item(id, "ammo_762nato")
			give_item(id, "ammo_762nato")
			give_item(id, "ammo_762nato")
		}
	case 5:
		{
			ColorChat(id, RED, "[%s]^x01 Mozesz czuc sie bezpieczniej, masz^x04 200 kamizelki^x01.", tag)
			give_item(id, "item_assaultsuit")
			set_user_armor(id, 200)
		}
	case 6:
		{
			ColorChat(id, RED, "[%s]^x01 Mozesz sie skradac bez obaw, masz^x04 ciche chodzenie^x01.", tag)
			set_user_footsteps(id, 1)
		}
	case 7:
		{
			ColorChat(id, RED, "[%s]^x01 Niestety, zaliczyles^x04 zgon^x01.", tag)
			user_kill(id)
		}
	case 8:
		{
			ColorChat(id, RED, "[%s]^x01 Dostales^x04 5 kopniakow^x01.", tag)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
		}
	case 9:
		{
			ColorChat(id, RED, "[%s]^x01 Granaty dla^x04 MISTRZA^x01.", tag)
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_smokegrenade")
		}
	case 10:
		{
			ColorChat(id, RED, "[%s]^x01 No niech bedzie, lap^x04 5000$^x01.", tag)
			new plusmoney = cs_get_user_money(id) + 5000
			cs_set_user_money(id, plusmoney)
		}
	case 11:
		{
			ColorChat(id, RED, "[%s]^x01 Dostales w prezencie kilka^x04 fragow^x01.", tag)
			new frag = random_num(1,3)
			new fragi = get_user_frags(id)
			set_user_frags(id, fragi + frag)
		}
	case 12:
		{
			new frag = random_num(1,3)
			new fragi = get_user_frags(id)
			if(fragi < frag)
			{
				RuletkaLosuj(id)
				return PLUGIN_CONTINUE
			}
			set_user_frags(id, fragi - frag)
			ColorChat(id, RED, "[%s]^x01 Tak bywa, straciles kilka^x04 fragow^x01.", tag)
		}
	case 13:
		{
			ColorChat(id, RED, "[%s]^x01 Niezle, jestes praktycznie^x04 niewidzialny^x01.", tag)
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 25)
		}
	case 14:
		{
			ColorChat(id, RED, "[%s]^x01 Poskacz sobie, masz mniejsza^x04 grawitacje^x01.", tag)
			set_user_gravity(id, 0.4)
		}
	case 15:
		{
			new zgon = random_num(1,3)
			new zgony = get_user_deaths(id)
			if(zgony < zgon)
			{
				RuletkaLosuj(id)
				return PLUGIN_CONTINUE
			}
			cs_set_user_deaths(id, zgony - zgon)
			ColorChat(id, RED, "[%s]^x01 Ciesz sie, odjalem ci kilka^x04 zgonow^x01.", tag)
		}
	case 16:
		{
			ColorChat(id, RED, "[%s]^x01 Pech, masz kilka^x04 zgonow^x01 wiecej^x01.", tag)
			new zgon = random_num(1,3);
			new zgony = get_user_deaths(id)
			cs_set_user_deaths(id, zgony + zgon)
		}
	case 17:
		{
			ColorChat(id, RED, "[%s]^x01 Zrobie z ciebie snipera, dostajesz^x04 AWP+DEAGLE^x01.", tag)
			give_item(id, "weapon_awp")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id, "ammo_338magnum")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
		}
	case 18:
		{
			ColorChat(id, RED, "[%s]^x01 Ktos wyczyscil ci^x04 konto^x01.", tag)
			cs_set_user_money(id, 0)
		}
	case 19:
		{
			ColorChat(id, RED, "[%s]^x01 Hohoho, ale sie^x04 zjarales^x01.", tag)
			set_task(1.0, "Look", id+TASK_LOOK, _, _, "b")
			look[id] = true
		}
	case 20:
		{
			ColorChat(id, RED, "[%s]^x01 Jestes na koksie,^x04 szybciej biegasz^x01.", tag)
			speed[id] = true
		}
	case 21:
		{
			ColorChat(id, RED, "[%s]^x01 Postarzales sie,^x04 wolniej biegasz^x01.", tag)
			slow[id] = true
		}
	case 22:
		{
			ColorChat(id, RED, "[%s]^x01 Raz, dwa, trzy. Dzisiaj^x04 broni nie masz^x01 ty.", tag)
			StripWeapons(id, Primary);
			StripWeapons(id, Secondary);
			StripWeapons(id, Grenades);
		}
	case 23:
		{
			ColorChat(id, RED, "[%s]^x01 Jestes bogaty, masz^x04 16000$^x01.", tag)
			cs_set_user_money(id, 16000)
		}
	case 24:
		{
			ColorChat(id, RED, "[%s]^x01 Jestes ^x04niesmiertelny ^x01przez^x04 10 sekund^x01.", tag)
			set_bartime(id, 10)
			set_user_godmode(id, 1)
			set_task(10.0, "remove_godmode", id)
		}
	case 25:
		{
			ColorChat(id, RED, "[%s]^x01 Przez^x04 15 sekund^x01 przechodzisz przez sciany^x01.", tag)
			set_user_noclip(id, 1)
			set_bartime(id, 15)
			set_task(15.0, "remove_noclip", id)
		}
	case 26:
		{
			ColorChat(id, RED, "[%s]^x01 Dostales ciemne okulary, nie dzialaja na ciebie^x04 granaty oslepiajace^x01.", tag)
			dark_glasses[id] = true
		}
	case 27:
		{
			ColorChat(id, RED, "[%s]^x01 Twoje bronie sa bezuzyteczne, zadajesz ze wszystkich po^x04 1 obrazen^x01.", tag)
			low_dmg[id] = true
		}
	case 28:
		{
			ColorChat(id, RED, "[%s]^x01 Podrasowalem twoj sprzet. Zadajesz^x04 +10 obrazen^x01.", tag)
			high_dmg[id] = true
		}
	case 29:
		{
			ColorChat(id, RED, "[%s]^x01 Jest moc! Mozesz podskoczyc^x04 w powietrzu^x01.", tag)
			jumper[id] = true
		}
	case 30:
		{
			ColorChat(id, RED, "[%s]^x01 Jestes chodzaca bomba. Wybuchniesz za^x04 10 sekund^x01.", tag)
			set_bartime(id, 10)
			set_task(10.0, "explode", id)
		}
	case 31:
		{
			ColorChat(id, RED, "[%s]^x01 To jest to! Nie masz^x04 odrzutu^x01 w broniach.", tag)
			no_recoil[id] = true
		}
	case 32:
		{
			ColorChat(id, RED, "[%s]^x01 Skacz jak krolik. Masz^x04 BunnyHop^x01.", tag)
			bunny_hop[id] = true
		}
	case 33:
		{
			ColorChat(id, RED, "[%s]^x01 Zatrules sie czyms. Tracisz^x04 10 razy po 5HP^x01 co^x04 5 sekund^x01.", tag)
			poison[id] = 10
			set_task(3.0, "poisoning", id, _, _, "a", 10)
		}
	case 34:
		{
			ColorChat(id, RED, "[%s]^x01 Wszyscy uciekac! Jestes^x04 Rambo^x01 przez^x04 20 sekund^x01.", tag)
			set_user_godmode(id, 1);
			StripWeapons(id, Primary);
			give_item(id, "weapon_m249");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			give_item(id, "ammo_556natobox");
			set_task(20.0, "remove_rambo", id)
			set_bartime(id, 20)
			set_pev(id,pev_rendercolor, 200.0,0.0,0.0);
			set_pev(id,pev_rendermode, kRenderNormal);
			set_pev(id,pev_renderfx, kRenderFxGlowShell);
			set_pev(id,pev_renderamt, 25.0);
		}
	case 35:
		{
			ColorChat(id, RED, "[%s]^x01 Tak, tak, tak. Masz^x04 nieskonczone ammo^x01.", tag)
			ammo[id] = true
			set_user_clip(id, 31)
		}
	case 36:
		{
			ColorChat(id, RED, "[%s]^x01 Ooo.. popatrz. Masz^x04 ubranie wroga^x01.", tag)
			ZmienUbranie(id, 0)
		}
	case 37:
		{
			ColorChat(id, RED, "[%s]^x01 Wylosowales^x04 Long Jump'a^x01. Kucnij i wcisnij spacje, aby skoczyc.", tag)
			long_jump[id] = true
		}
	case 38:
		{
			ColorChat(id, RED, "[%s]^x01 Uppss.. chyba trafila cie^x04 blyskawica^x01.", tag)
			Lightning(id)
		}
	case 39:
		{
			ColorChat(id, RED, "[%s]^x01 Zabawmy sie w^x04 medyka^x01. Ustawilem ci losowa ilosc^x04 zycia^x01.", tag)
			new hp = random_num(1, 200);
			set_user_health(id, hp);
		}
	case 40:
		{
			ColorChat(id, RED, "[%s]^x01 Tak jest, zostales^x04 nozownikiem.^x01 Masz^x04 noz, 1000HP i szybko biegasz^x01.", tag)
			StripWeapons(id, Primary)
			StripWeapons(id, Secondary)
			StripWeapons(id, Grenades)
			client_cmd(id, "weapon_knife")
			set_user_health(id, 1000)
			set_task(0.1, "hp_display", id+TASK_DISPLAY, _, _, "b")
			cut_throat[id] = true
			set_user_maxspeed(id, 500.0)
		}
	}
	return PLUGIN_CONTINUE
}

public Look(id)
{
	id -= TASK_LOOK
	if(is_user_alive(id) && look[id])
	{
		message_begin(MSG_ONE, 95, {0,0,0}, id)
		write_byte(150)
		message_end()
	}
	else 
	{
		message_begin(MSG_ONE, 95, {0,0,0}, id)
		write_byte(90)
		message_end()
		remove_task(id+TASK_LOOK)
	}
}

public poisoning(id) 
{
	if(is_user_alive(id) && poison[id]) 
	{
		poison[id]--
		set_user_health(id, get_user_health(id) - 5)
	}
}

public remove_rambo(id)
{
	if(is_user_alive(id))
	{
		set_user_godmode(id, 0)
		set_pev(id, pev_renderfx, kRenderFxNone)
		set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	}
}

public remove_godmode(id)
{
	if(is_user_alive(id))
	{
		set_user_godmode(id, 0)
	}
}

public remove_noclip(id)
{
	if(is_user_alive(id))
	{
		set_user_noclip(id, 0)
		set_pev(id, pev_movetype, MOVETYPE_WALK)

		new Float:origin[3]

		pev(id, pev_origin, origin)

		if (!is_hull_vacant(origin, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id))
			user_silentkill(id)
	}
}

public explode(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	new Float:fOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin)

	new iOrigin[3];
	for(new i=0;i<=2;i++)
		iOrigin[i] = floatround(fOrigin[i])

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin)
	write_byte(TE_EXPLOSION)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(sprite_blast)
	write_byte(32)
	write_byte(20)
	write_byte(0)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
	write_byte(TE_BEAMCYLINDER)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_coord(iOrigin[0])
	write_coord(iOrigin[1]+200)
	write_coord(iOrigin[2]+200)
	write_short(sprite_white)
	write_byte(0)
	write_byte(0)
	write_byte(10)
	write_byte(10)
	write_byte(255)
	write_byte(255)
	write_byte(100)
	write_byte(100)
	write_byte(128)
	write_byte(0)
	message_end()

	new entlist[33]
	new numfound = find_sphere_class(id, "player", 250.0 , entlist, 32)
	
	for (new i=0; i <=numfound; i++)
	{	
		new pid = entlist[i]

		if (is_user_alive(pid) && get_user_team(id) != get_user_team(pid))
			ExecuteHam(Ham_TakeDamage, pid, 0.0, id, 100.0, (1<<24))
	}
	
	user_silentkill(id)
	
	return PLUGIN_CONTINUE;
}

public GameCommencing()
	g_Round = 0

public event_new_round()
{
	g_FreezeTime=true
	g_Round++
}

public round_start()
{
	g_FreezeTime = false;
	for(new i = 1; i <= max_players; i++)
	{
		if(is_user_alive(i))
		{
			set_user_footsteps(i,0)
			set_user_gravity(i, 1.0)
			set_rendering(i,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
			set_user_health(i, 100)
			remove_noclip(i)
			speed[i] = false
			slow[i] = false
			low_dmg[i] = false
			high_dmg[i] = false
			jumper[i] = false
			no_recoil[i] = false
			dark_glasses[i] = false
			bunny_hop[i] = false
			ammo[i] = false
			poison[i] = 0
			look[i] = false
			long_jump[i] = false
			lightning[i] = 0
			cut_throat[i] = false
			ZmienUbranie(i, 1)
			message_begin(MSG_ONE, 95, {0,0,0}, i)
			write_byte(90)
			message_end()
		}
	}
}
public info(id)
{
	id -= TASK_INFO
	if(is_user_connected(id) && !is_user_hltv(id))
		ColorChat(id, RED, "[%s]^x01 Aby uzyc ruletki wpisz^x04 /ruletka", tag)
}

public UnlimitedAmmo(id) 
{
	if(!is_user_alive(id) || !ammo[id]) 
		return 0

	set_user_clip(id, 31)

	return 0
}

public HamTouchPre(weapon, id) 
{
	if(!pev_valid(weapon) || !is_user_alive(id) || !cut_throat[id])
		return HAM_IGNORED;
	
	new name[20];
	pev(weapon, pev_model, name, 19);
	if(containi(name, "w_backpack") != -1)
		return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	new flags = pev(id, pev_flags)

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && jump[id] && jumper[id])
	{
		jump[id]--
		new Float:velocity[3]
		pev(id, pev_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		set_pev(id, pev_velocity,velocity)
	}
	else if(flags & FL_ONGROUND)
		jump[id] = 1
		
	if(no_recoil[id] && get_uc(uc_handle, UC_Buttons) & IN_ATTACK)
	{
		new Float:punchangle[3]
		pev(id, pev_punchangle, punchangle)
		for(new i=0; i<3;i++)
			punchangle[i]*=0.9
		set_pev(id, pev_punchangle, punchangle)
	}

	return FMRES_IGNORED;
}

public PreThink(id)
{
	if(!is_user_alive(id))	
		return PLUGIN_CONTINUE

	if (entity_get_int(id, EV_INT_button) & 2 && bunny_hop[id]) 
	{
		entity_set_float(id, EV_FL_fuser2, 0.0)
		new flags = entity_get_int(id, EV_INT_flags)

		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] += 250.0
		entity_set_vector(id, EV_VEC_velocity, velocity)

		entity_set_int(id, EV_INT_gaitsequence, 6)
	}
	
	if(!long_jump[id])
		return PLUGIN_CONTINUE
		
	new button = get_user_button(id)
	
	if((button & IN_DUCK) && (button & IN_JUMP) && !(get_user_oldbutton(id) & IN_JUMP)) 
	{ 
		if(jumped[id]) 
			return PLUGIN_CONTINUE
		
		new flags = pev(id,pev_flags) 
		if(flags & FL_ONGROUND) 
		{ 
			set_pev ( id, pev_flags, flags & ~FL_ONGROUND ) 
					
			new Float:va[3],Float:v[3] 
			entity_get_vector(id,EV_VEC_v_angle,va) 
			v[0]=floatcos(va[1]/180.0*M_PI)*560.0 
			v[1]=floatsin(va[1]/180.0*M_PI)*560.0 
			v[2]=300.0 
			entity_set_vector(id,EV_VEC_velocity,v) 
					
			jumped[id] = true
		} 
	}
	else
		jumped[id] = false
	return PLUGIN_CONTINUE;
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_alive(this) || !is_user_alive(idattacker))
		return HAM_IGNORED
	
	if(low_dmg[idattacker])
	{
		SetHamParamFloat(4, 1.0)
		return HAM_HANDLED
	}
	
	if(high_dmg[idattacker])
	{
		SetHamParamFloat(4, damage+10.0)
		return HAM_HANDLED
	}
	
	return HAM_IGNORED
}

Ham:get_player_resetmaxspeed_func()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
	return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
	return Ham_Item_PreFrame;
	#endif
}

public Player_ResetMaxSpeed(id)
{
	if(!g_FreezeTime && is_user_alive(id))
	{
		if(speed[id])
			set_user_maxspeed(id, get_user_maxspeed(id) + 50)
		if(slow[id])
			set_user_maxspeed(id, get_user_maxspeed(id) - 50)
		if(cut_throat[id])
			set_user_maxspeed(id, 500.0)
	}
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id)
{
	static tr;
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true
	return false
}

public set_bartime(id, czas)
{
	message_begin(MSG_ONE, msg_bartime, _, id)
	write_short(czas)
	message_end()
}

public block_flashbang(msgId, msgType, id)
{
	if(!dark_glasses[id]) 
		return PLUGIN_CONTINUE
	
	if(get_msg_arg_int(4) == 255 && get_msg_arg_int(5) == 255 && get_msg_arg_int(6) == 255 && get_msg_arg_int(7) > 199)
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

new CT_Skins[4][] = {"sas","gsg9","urban","gign"};
new Terro_Skins[4][] = {"arctic","leet","guerilla","terror"};

public ZmienUbranie(id, reset)
{
	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;

	if (reset)
		cs_reset_user_model(id);

	else
	{
		new num = random_num(0,3);
		cs_set_user_model(id, (get_user_team(id) == 1)? CT_Skins[num]: Terro_Skins[num]);
	}

	return PLUGIN_CONTINUE;
}

public Lightning(id)
{
	new blyskawica=random_num(20, 35);
	set_user_health(id, get_user_health(id)-blyskawica);
	
	new origin[3];
	get_user_origin(id, origin);
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_TAREXPLOSION);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	message_end();
	
	origin[2]=origin[2]-26;
	new sorigin[3];
	sorigin[0]=origin[0]+150;
	sorigin[1]=origin[1]+150;
	sorigin[2]=origin[2]+400;
	light(sorigin, origin);
	
	new Float:uderzenie[3]={0.0,0.0,500.0};
	entity_set_vector(id, EV_VEC_velocity, uderzenie);
	
	screen_flash(id, 255, 255, 200, 200);
	emit_sound(id, CHAN_STATIC, "ambience/thunder_clap.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id);
	write_short((1<<12)*8);
	write_short((1<<12)*6);
	write_short((1<<12)*1);
	message_end();
	
	lightning[id] = 4
	
	new data[1];
	data[0] = id;
	set_task(1.0, "timer", _, data, 1, "a", 3);
}

public timer(data[])
{
	new id=data[0];
	if(is_user_alive(id) && lightning[id])
	{
		if(--lightning[id])
		{
			new burn=random_num(2, 5);
			set_user_health(id, get_user_health(id)-burn);
			
			new origin[3];
			get_user_origin(id, origin);
			
			message_begin(MSG_ONE_UNRELIABLE, msg_damage, {0,0,0}, id);
			write_byte(30);
			write_byte(30);
			write_long(1<<21);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2]);
			message_end();
			
			screen_flash(id, 255, 255, 200, lightning[id]*40);
		}
	}
}

public light(vec1[3], vec2[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2]);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	write_short(sprLightning);
	write_byte(1);
	write_byte(5);
	write_byte(2);
	write_byte(20);
	write_byte(30);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	message_end();
    
	message_begin(MSG_PVS, SVC_TEMPENTITY, vec2);
	write_byte(TE_SPARKS);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	message_end();
        
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec2);
	write_byte(TE_SMOKE);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	write_short(sprSmoke);
	write_byte(10);
	write_byte(10);
	message_end();
}

public screen_flash(id, red, green, blue, alpha)
{
	message_begin(MSG_ONE_UNRELIABLE, msg_screenfade, _, id);
	write_short(1<<12);
	write_short(1<<12);
	write_short(1<<12);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}

public hp_display(id)
{
	id -= TASK_DISPLAY;
	if(is_user_alive(id) && cut_throat[id])
		client_print(id, print_center, "HP: %i", get_user_health(id));
	else
		remove_task(id+TASK_DISPLAY);
}

public is_user_cut_throat(plugin,params)
{
	if(params != 1)
		return PLUGIN_CONTINUE
		
	return cut_throat[get_param(1)]
}

stock set_user_clip(id, ammo) 
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _)
	get_weaponname(weapon, weaponname, 31)
	while((weaponid = engfunc(EngFunc_FindEntityByString, weaponid, "classname", weaponname)) != 0)
	if(pev(weaponid, pev_owner) == id) 
	{
		set_pdata_int(weaponid, 51, ammo, 4)
		return weaponid
	}
	return 0
}
