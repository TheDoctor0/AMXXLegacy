#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "JailBreak: Ruletka"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define TASK_INFO 545
#define TASK_RESET 656
#define TASK_LOOK 743
#define TASK_SHOOTING 767

new tag[] = "RULETKA"
new bool:g_Ruletka[33]
new speed[33]
new jumper[33]
new jump[33]
new bunny_hop[33]
new reload[33]
new shooting[33]
new ammo[33]
new no_recoil[33]
new ghost[33]
new slow[33]
new dark_glasses[33]
new look[33]
new high_dmg[33]
new msg_bartime

native set_user_block_drop(id)

new const max_clip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20, 
10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 }

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("say /ruletka", "CmdRuletka")
	register_clcmd("say_team /ruletka", "CmdRuletka")
	register_clcmd("ruletka", "CmdRuletka")
	
	register_clcmd("say /los", "CmdRuletka")
	register_clcmd("say_team /los", "CmdRuletka")
	register_clcmd("los", "CmdRuletka")
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1)
	RegisterHam(Ham_TakeDamage, "player","TakeDamage", 0)
	register_event("CurWeapon", "UnlimitedAmmo", "be", "1=1")
	register_forward(FM_CmdStart, "CmdStart")
	register_forward(FM_PlayerPreThink, "PreThink")
	register_message(get_user_msgid("ScreenFade"), "block_flashbang")
	msg_bartime = get_user_msgid("BarTime")
}

public client_authorized(id)
	g_Ruletka[id] = true

public client_disconnected(id)
{
	remove_task(id+TASK_INFO)
	remove_task(id+TASK_RESET)
	remove_task(id+TASK_LOOK)
	remove_task(id+TASK_SHOOTING)
	speed[id] = false
	shooting[id] = false
	no_recoil[id] = false
	bunny_hop[id] = false
	ammo[id] = false
	jumper[id] = false
	reload[id] = false
	ghost[id] = false
	slow[id] = false
	dark_glasses[id] = false
	look[id] = false
	high_dmg[id] = false
}

public Reset(id)
{
	id -= TASK_RESET
	g_Ruletka[id] = true
	client_print_color(id, id, "^x03[%s]^x01 Mozesz juz uzyc ponownie^x04 ruletki^x01.",tag)
}

public CmdRuletka(id)
{
	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x03[%s]^x01 Widziales kiedys trupa w kasynie?", tag)
		return PLUGIN_HANDLED
	}
	
	if(!g_Ruletka[id])
	{
		client_print_color(id, id, "^x03[%s]^x01 Ruletki mozna uzyc raz na 3 minuty.", tag)
		return PLUGIN_HANDLED
	}
	
	if(jail_get_play_game())
	{
		client_print_color(id, id, "^x03[%s]^x01 Nie mozesz uzyc ruletki w trakcie trwania zabawy!", tag); 
		return PLUGIN_HANDLED; 
	}	
	
	if(jail_get_days() == NIEDZIELA || jail_get_days() == SOBOTA)
	{
		client_print_color(id, id, "^x03[%s]^x01 Nie mozesz uzyc ruletki w sobote i niedziele!", tag); 
		return PLUGIN_HANDLED; 
	}
	
	
	client_print_color(id, id, "^x03[%s]^x01 Rozpoczynam losowanie...", tag)
	if(get_user_team(id) == 1)
		set_task(1.0, "RuletkaLosujTT", id)
	else
		set_task(1.0, "RuletkaLosujCT", id)
	g_Ruletka[id] = false
	set_task(180.0, "Reset", id+TASK_RESET)

	return PLUGIN_HANDLED
}

public RuletkaLosujTT(id)
{
	switch(random_num(1, 17))
	{
	case 1 :
		{
			client_print_color(id, id, "^x03[%s]^x01 Brawo, masz^x04 255 HP^x01.", tag)
			set_user_health(id, 255)
		}
	case 2 :
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zostales uratowany przed wylosowaniem^x04 1 HP^x01.", tag)
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Pech, zostales z^x04 1 HP^x01.", tag)
				set_user_health(id, 1)
			}
		}
	
	case 3:
		{
			client_print_color(id, id, "^x03[%s]^x01 Prosze bardzo, wez ten^x04 Zestaw Granatow^x01.", tag)
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_smokegrenade")
		}
	case 4:
		{
			client_print_color(id, id, "^x03[%s]^x01 Mozesz czuc sie bezpieczniej, masz^x04 100 kamizelki^x01.", tag)
			give_item(id, "item_assaultsuit")
			set_user_armor(id, 100)
		}
	case 5:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
			{
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zamiast cichego chodzenia dostajesz^x04 3500$^x01.", tag)
				new money = cs_get_user_money(id)
				if(money + 3500 < 16000)
					cs_set_user_money(id, money + 3500)
				else
					cs_set_user_money(id, 16000)
			}
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Mozesz sie skradac bez obaw, masz^x04 ciche chodzenie^x01.", tag)
				set_user_footsteps(id, 1)
			}
		}
	case 6:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zostales uratowany przed wylosowaniem^x04 smierci^x01.", tag)
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Niestety, zaliczyles^x04 zgon^x01.", tag)
				user_kill(id)
			}
		}
	case 7:
		{
			client_print_color(id, id, "^x03[%s]^x01 Mam dla ciebie zla wiadomosc. Nic nie wylosowales.", tag)
		}
	case 8:
		{
			client_print_color(id, id, "^x03[%s]^x01 Poskacz sobie, masz mniejsza^x04 grawitacje^x01.", tag)
			set_user_gravity(id, 0.4)
		}
	case 9:
		{
			client_print_color(id, id, "^x03[%s]^x01 Jestes na koksie,^x04 szybciej biegasz^x01.", tag)
			speed[id] = true
			jail_set_user_speed(id, 300.0)
		}
	case 10:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
			{
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zamiast dodatkowego skoku dostajesz^x04 5000$^x01.", tag)
				new money = cs_get_user_money(id)
				if(money + 5000 < 16000)
					cs_set_user_money(id, money + 5000)
				else
					cs_set_user_money(id, 16000)
			}
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Jest moc! Mozesz podskoczyc^x04 w powietrzu^x01.", tag)
				jumper[id] = true
			}
		}
	case 11:
		{
			client_print_color(id, id, "^x03[%s]^x01 Skacz jak krolik. Masz^x04 BunnyHop^x01.", tag)
			bunny_hop[id] = true
		}
	case 12:
		{
			client_print_color(id, id, "^x03[%s]^x01 Niezle, jestes praktycznie^x04 niewidzialny^x01.", tag)
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 30)
			ghost[id] = true
		}
	case 13:
		{
			client_print_color(id, id, "^x03[%s]^x01 Jestes bogaty, masz^x04 16000$^x01.", tag)
			cs_set_user_money(id, 16000)
		}
	case 14:
		{
			client_print_color(id, id, "^x03[%s]^x01 Ooo...^x04 Nie wypada ci kasa po smierci^x01.", tag)
			set_user_block_drop(id)
		}
	
	case 15:
		{
			client_print_color(id, id, "^x03[%s]^x01 Dostales^x04 5 kopniakow^x01.", tag)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
			user_slap(id, 1)
		}
	case 16:
		{
			client_print_color(id, id, "^x03[%s]^x01 Ktos wyczyscil ci^x04 konto^x01.", tag)
			cs_set_user_money(id, 0)
		}

	case 17:
		{
			client_print_color(id, id, "^x03[%s]^x01 Ooo.. popatrz. Masz^x04 ubranie wroga^x01.", tag)
			ZmienUbranie(id, 0)
		}
	}
	return PLUGIN_CONTINUE
}

public RuletkaLosujCT(id)
{
	switch(random_num(1, 20))
	{
	case 1 :
		{
			client_print_color(id, id, "^x03[%s]^x01 Brawo, masz^x04 255 HP^x01.", tag)
			set_user_health(id, 255)
		}
	case 2 :
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zostales uratowany przed wylosowaniem^x04 1 HP^x01.", tag)
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Pech, zostales z^x04 1 HP^x01.", tag)
				set_user_health(id, 1)
			}
		}
	case 3:
		{
			client_print_color(id, id, "^x03[%s]^x01 Jestes na koksie,^x04 szybciej biegasz^x01.", tag)
			speed[id] = true
		}
	case 4:
		{
			client_print_color(id, id, "^x03[%s]^x01 Poczuj sie jak Rambo, dostales^x04 Krowe^x01.", tag)
			give_item(id, "weapon_m249")
			cs_set_user_bpammo(id, CSW_M249, 200)
		}
	case 5:
		{
			client_print_color(id, id, "^x03[%s]^x01 Mozesz czuc sie bezpieczniej, masz^x04 100 kamizelki^x01.", tag)
			give_item(id, "item_assaultsuit")
			set_user_armor(id, 100)
		}
	case 6:
		{
			client_print_color(id, id, "^x03[%s]^x01 Mozesz sie skradac bez obaw, masz^x04 ciche chodzenie^x01.", tag)
			set_user_footsteps(id, 1)
		}
	case 7:
		{
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				client_print_color(id, id, "^x03[%s]^x01 Jestes VIP'em, wiec zostales uratowany przed wylosowaniem^x04 smierci^x01.", tag)
			else
			{
				client_print_color(id, id, "^x03[%s]^x01 Niestety, zaliczyles^x04 zgon^x01.", tag)
				user_kill(id)
			}
		}
	case 8:
		{
			client_print_color(id, id, "^x03[%s]^x01 Mam dla ciebie zla wiadomosc. Nic nie wylosowales.", tag)
		}
	case 9:
		{
			client_print_color(id, id, "^x03[%s]^x01 Poskacz sobie, masz mniejsza^x04 grawitacje^x01.", tag)
			set_user_gravity(id, 0.4)
		}
	case 10:
		{
			client_print_color(id, id, "^x03[%s]^x01 Wow! Masz natychmiastowe^x04 przeladowanie^x01.", tag)
			reload[id] = true
		}
	case 11:
		{
			client_print_color(id, id, "^x03[%s]^x01 Ups.. zadajesz^x04 0 obrazen^x01 przez 15 sekund.", tag)
			shooting[id] = true
			set_task(15.0, "OffShooting", TASK_SHOOTING+id)
		}
	
	case 13:
		{
			client_print_color(id, id, "^x03[%s]^x01 Tak, tak, tak. Masz^x04 nieskonczone ammo^x01.", tag)
			ammo[id] = true
			set_user_clip(id, 31)
		}
	case 14:
		{
			client_print_color(id, id, "^x03[%s]^x01 To jest to! Nie masz^x04 odrzutu^x01 w broniach.", tag)
			no_recoil[id] = true
		}
	case 15:
		{
			client_print_color(id, id, "^x03[%s]^x01 Hohoho, ale sie^x04 zjarales^x01.", tag)
			set_task(1.0, "Look", id+TASK_LOOK, _, _, "b")
			look[id] = true
		}
	case 16:
		{
			client_print_color(id, id, "^x03[%s]^x01 Postarzales sie,^x04 wolniej biegasz^x01.", tag)
			jail_set_user_speed(id, 200.0)
			slow[id] = true
		}
	case 17:
		{
			client_print_color(id, id, "^x03[%s]^x01 Podrasowalem twoj sprzet. Zadajesz^x04 +10 obrazen^x01.", tag)
			high_dmg[id] = true
		}
	case 18:
		{
			client_print_color(id, id, "^x03[%s]^x01 Jestes bogaty, masz^x04 16000$^x01.", tag)
			cs_set_user_money(id, 16000)
		}
	case 19:
		{
			client_print_color(id, id, "^x03[%s]^x01 Ktos wyczyscil ci^x04 konto^x01.", tag)
			cs_set_user_money(id, 0)
		}
	case 20:
		{
			client_print_color(id, id, "^x03[%s]^x01 Dostales ciemne okulary, nie dzialaja na ciebie^x04 granaty oslepiajace^x01.", tag)
			dark_glasses[id] = true
		}
	}
	return PLUGIN_CONTINUE
}

public OnLastPrisonerWishTaken(id) 
{
	speed[id] = false
	no_recoil[id] = false
	bunny_hop[id] = false
	ammo[id] = false
	reload[id] = false
	slow[id] = false
	high_dmg[id] = false
}

public Spawn(id)
{
	if(is_user_alive(id))
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H)) set_user_footsteps(id, 0)
		set_user_gravity(id, 1.0)
		if(ghost[id]) set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	}
	if(speed[id] || slow[id])
		jail_set_user_speed(id, -1.0)
	speed[id] = false
	shooting[id] = false
	no_recoil[id] = false
	bunny_hop[id] = false
	ammo[id] = false
	jumper[id] = false
	reload[id] = false
	ghost[id] = false
	slow[id] = false
	dark_glasses[id] = false
	look[id] = false
	high_dmg[id] = false
	ZmienUbranie(id, 1)
	message_begin(MSG_ONE, 95, {0,0,0}, id)
	write_byte(90)
	message_end()
	
	if(!task_exists(id+TASK_INFO))
		set_task(170.0, "Info", id+TASK_INFO, _, _, "b")
}

public Info(id)
{
	id -= TASK_INFO
	if(is_user_connected(id) && !is_user_hltv(id))
		client_print_color(id, id, "^x03[%s]^x01 Aby uzyc ruletki wpisz^x04 /ruletka^x01 lub^x04 /los^x01.", tag)
}

public OffShooting(id)
{
	id -= TASK_SHOOTING
	if(is_user_connected(id))
		shooting[id] = false
}

public Look(id)
{
	id -= TASK_LOOK;
	
	if(is_user_alive(id) && look[id])
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

public UnlimitedAmmo(id) 
{
	if(!is_user_alive(id) || !ammo[id]) 
		return 0

	set_user_clip(id, 31)

	return 0
}

public PreThink(id)
{
	if(!is_user_alive(id) || !bunny_hop[id])	
		return PLUGIN_CONTINUE

	if (entity_get_int(id, EV_INT_button) & 2) 
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
	return PLUGIN_CONTINUE
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED

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
	
	new buttons = get_uc(uc_handle, UC_Buttons)
	new oldbuttons = pev(id, pev_oldbuttons)
	new clip, ammo, weapon = get_user_weapon(id, clip, ammo)
	
	if(max_clip[weapon] == -1 || !ammo || !reload[id])
		return FMRES_IGNORED
		
	if((buttons & IN_RELOAD && !(oldbuttons & IN_RELOAD) && !(buttons & IN_ATTACK)) || !clip)
	{
		cs_set_user_bpammo(id, weapon, ammo-(max_clip[weapon]-clip))
		new new_ammo = (max_clip[weapon] > ammo)? clip+ammo: max_clip[weapon]
		set_user_clip(id, new_ammo)
	}

	return FMRES_IGNORED
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_alive(this) || !is_user_alive(idattacker))
		return HAM_IGNORED
	
	if(shooting[idattacker])
	{
		SetHamParamFloat(4, 0.0)
		return HAM_HANDLED
	}
	
	if(high_dmg[idattacker])
	{
		SetHamParamFloat(4, damage+10.0)
		return HAM_HANDLED
	}
	
	return HAM_IGNORED
}

public SetSpeed(id)
	set_user_maxspeed(id, get_user_maxspeed(id) + 50);

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
