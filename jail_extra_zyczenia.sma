#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <jailbreak>

#define PLUGIN "JailBreak: Zyczenia"
#define VERSION "1.0.8"
#define AUTHOR "Cypis & O'Zone"

#define TASK_EFFECT 7489
#define TASK_FIRE 4351

new const maxAmmo[31] = {0, 52, 0, 90, 1, 31, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 31, 90, 120, 90, 2, 35, 90, 90, 0, 100};

new id_kasa, id_bezruch, id_freeday, id_duszek, id_rambomod, id_m4a1, id_ak47, id_scouty, id_awp, id_autolama, id_m249, id_deagle, id_podpalenie, id_zabawa;

new HamHook:fHamWeapon[31], bool:bFire[33], iFight[2], gMaxPlayers, gFlash, gSmoke, iFightWeapons;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Killed, "player", "SmiercGraczaPost", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	
	id_kasa = jail_register_wish("Zabierz 6000$ i Spadaj");
	id_bezruch = jail_register_wish("Bezruch");
	id_freeday = jail_register_wish("FreeDay");
	id_duszek = jail_register_wish("Duszek");
	id_rambomod = jail_register_wish("RamboMod");
	id_podpalenie = jail_register_wish("Podpal Straznikow");
	id_zabawa = jail_register_wish("Wybrana Zabawa");
	id_m4a1 = jail_register_wish("Pojedynek na M4A1");
	id_ak47 = jail_register_wish("Pojedynek na AK47");
	id_scouty = jail_register_wish("Pojedynek na Scouty");
	id_awp = jail_register_wish("Pojedynek na AWP");
	id_autolama = jail_register_wish("Pojedynek na Autolamy");
	id_m249 = jail_register_wish("Pojedynek na Krowy");
	id_deagle = jail_register_wish("Pojedynek na Deagle");
	
	gMaxPlayers = get_maxplayers();
}

public plugin_precache()
{
	precache_sound("misc/rambo.wav");
	precache_sound("misc/pojedynek.wav");
	
	precache_sound("ambience/flameburst1.wav");
	precache_sound("scientist/scream07.wav");
	precache_sound("scientist/scream21.wav");
	
	precache_model("models/w_throw.mdl");
	
	gFlash = precache_model("sprites/muzzleflash.spr");
	gSmoke = precache_model("sprites/steam1.spr");
}

public plugin_natives()
	register_native("jail_is_fight", "jail_is_fight", 1);

public OnRemoveData(day)
{
	if(iFight[0] || iFight[1])
	{
		iFight[0] = 0;
		iFight[1] = 0;
		
		RegisterHams(false);
	}
	
	iFightWeapons = 0;
}

public OnLastPrisonerTakeWish(id, zyczenie)
{
	if(zyczenie == id_bezruch)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Bezruch");
		
		strip_user_weapons(id);
		
		give_item(id, "weapon_knife");
		give_item(id, "weapon_deagle")
		
		cs_set_user_bpammo(id, CSW_DEAGLE, maxAmmo[CSW_DEAGLE]);
		
		jail_set_ct_hit_tt(true);
		
		for(new i = 1; i <= gMaxPlayers; i++)
		{
			if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_CT) continue;
			
			strip_user_weapons(i);
			
			give_item(i, "weapon_knife");
			
			jail_set_user_speed(i, 0.1);
		}
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_kasa)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Kasa");
		
		new iCash = cs_get_user_money(id) + 6000;
		
		if(iCash >= 16000)
		{
			cs_set_user_money(id, 16000);

			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wypelniles portfel po brzegi - masz ^x03 16000$^x01.");
		}
		else
		{
			cs_set_user_money(id, iCash);

			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Zasililes twoj portfel o dodatkowe^x03 6000$^x01!");
		}

		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Konczysz aktualna runde samobojstwem.");
		
		user_silentkill(id);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_freeday)
	{
		if(jail_get_days() == PIATEK || jail_get_days() == SOBOTA) return JAIL_HANDLED;
		
		log_to_file("jail_api_jailbreak.log", "Zyczenie: FreeDay");

		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wybrales^x03 FreeDay^x01, ktory dostaniesz po rozpoczeniu nowej rundy.");
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Konczysz aktualna runde samobojstwem.");
		
		user_silentkill(id);
		
		jail_set_prisoner_free(id, true);	
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_duszek)
	{
		if(jail_get_days() == PIATEK || jail_get_days() == SOBOTA) return JAIL_HANDLED;
		
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Duszek");

		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wybrales^x03 Duszka^x01, ktorego dostaniesz po rozpoczeniu nowej rundy.");
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Konczysz aktualna runde samobojstwem.");
		
		user_silentkill(id);
		
		jail_set_prisoner_ghost(id, true);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_podpalenie)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Podpalenie");
		
		for(new i = 1; i <= gMaxPlayers; i++) if(is_user_alive(i) && get_user_team(i) == 2) set_on_fire();

		set_user_health(id, 3000);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_zabawa)
	{
		if(jail_get_days() == PIATEK || jail_get_days() == SOBOTA) return JAIL_HANDLED;
		
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Zabawa");
		
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wybrales^x03 dowolna zabawe^x01. Glosowanie rozpocznie sie w nowej rundzie.");
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Konczysz aktualna runde samobojstwem.");
		
		jail_set_prisoners_game();
		
		user_silentkill(id);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_rambomod)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Rambo");
		
		client_cmd(0, "spk misc/rambo.wav");
		
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 4.0);
		show_hudmessage(0, "RamboMod aktywny!");
		
		set_user_health(id, 1500);
		
		strip_user_weapons(id);
		
		give_item(id, "weapon_knife");
		give_item(id, "weapon_m249");
		
		cs_set_user_bpammo(id, CSW_M249, maxAmmo[CSW_M249]);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_m4a1)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek M4A1");
		
		MenuFight(id, CSW_M4A1);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_ak47)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek AK47");
		
		MenuFight(id, CSW_AK47);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_scouty)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek Scouty");
		
		MenuFight(id, CSW_SCOUT);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_awp)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek AWP");
		
		MenuFight(id, CSW_AWP);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_autolama)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek AutoLama");
		
		MenuFight(id, CSW_SG550);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_m249)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek M249");
		
		MenuFight(id, CSW_M249);
		
		return JAIL_CONTINUE;
	}
	if(zyczenie ==  id_deagle)
	{
		log_to_file("jail_api_jailbreak.log", "Zyczenie: Pojedynek Deagle");
		
		MenuFight(id, CSW_DEAGLE);
		
		return JAIL_CONTINUE;
	}
	
	return JAIL_CONTINUE;
}	

public MenuFight(id, weapon)
{
	iFight[0] = id;

	iFightWeapons = weapon;

	new szName[32], menu = menu_create("\rWiezienie CS-Reload \yWybierz przeciwnika\w:", "MenuFight_Handler");
	
	for(new i = 1; i <= gMaxPlayers; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_CT) continue;
		
		get_user_name(i, szName, charsmax(szName));
		
		menu_additem(menu, szName);
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	
	menu_display(id, menu);
}

public MenuFight_Handler(id, menu, item)
{
	if(iFight[0] != id || iFight[1] || !is_user_alive(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szData[1], iAccess, iCallback;
	
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	iFight[1] = get_user_index(szName);
	
	if(!is_user_alive(iFight[1]) || !is_user_connected(iFight[1]))
	{
		iFight[1] = 0;
		
		MenuFight(id, iFightWeapons);
		
		return PLUGIN_HANDLED;
	}
	
	RegisterHams(true);
	
	StartFight(iFight[0], iFight[1]);
	
	return PLUGIN_HANDLED;
}

public TakeDamage(id, ent, attacker, Float:damage, damagebits)
{
	if(!iFight[0] || !is_user_connected(id) || !is_user_connected(attacker) || id == attacker) return HAM_IGNORED;
	
	if((iFight[0] == id && iFight[1] != attacker) || (iFight[0] == attacker && iFight[1] != id)) return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public SmiercGraczaPost(id, attacker, shouldgib)
{	
	if(!is_user_connected(id) || id != iFight[1]) return HAM_IGNORED;
	
	jail_set_user_block(id, false);
	
	FindOpponent();
	
	return HAM_IGNORED;
}

public WeaponAttack(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	
	if(iFight[0] == id || iFight[1] == id) cs_set_user_bpammo(id, iFightWeapons, 1);
}		

public client_disconnected(id)
	if(iFight[1] == id) FindOpponent();
	
public StartFight(id, player)
{
	if(!is_user_alive(id) || !is_user_alive(player)) return PLUGIN_HANDLED;
	
	new szName[32], szPlayer[32];
	
	get_user_name(id, szName, charsmax(szName));
	get_user_name(player, szPlayer, charsmax(szPlayer));
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x03 %s^x01 walczy z^x03 %s^x01.", szName, szPlayer);
	
	client_cmd(0, "spk misc/pojedynek.wav");
	
	set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 10);
	set_user_rendering(player, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 10);
	
	jail_set_user_block(id, true);
	jail_set_user_block(player, true);
	
	set_user_health(id, 100);
	set_user_health(player, 100);
	
	strip_user_weapons(id);
	strip_user_weapons(player);
	
	new szWeapon[24];
	
	get_weaponname(iFightWeapons, szWeapon, charsmax(szWeapon));
	
	new iWeapon = give_item(id, szWeapon), iWeapon2 = give_item(player, szWeapon);
	
	if(iFightWeapons == CSW_KNIFE)
	{
		set_pev(id, pev_viewmodel2, "models/v_knife.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_knife.mdl");
		
		set_pev(player, pev_viewmodel2, "models/v_knife.mdl");
		set_pev(player, pev_weaponmodel2, "models/p_knife.mdl");
		
		return PLUGIN_HANDLED;
	}
	
	cs_set_weapon_ammo(iWeapon, 1);
	cs_set_weapon_ammo(iWeapon2, 1);
	
	return PLUGIN_HANDLED;
}

public FindOpponent()
{
	iFight[1] = RandomPlayer(2);
	
	if(!iFight[1] || !is_user_alive(iFight[0])) return PLUGIN_HANDLED;
	
	StartFight(iFight[0], iFight[1]);
	
	return PLUGIN_HANDLED;
}

public RegisterHams(bool:value)
{
	if(value)
	{
		if(fHamWeapon[iFightWeapons]) EnableHamForward(fHamWeapon[iFightWeapons]);
		else
		{
			new WeaponName[24];
				
			get_weaponname(iFightWeapons, WeaponName, 23);
				
			fHamWeapon[iFightWeapons] = RegisterHam(Ham_Weapon_PrimaryAttack, WeaponName, "WeaponAttack", 1);
		}
	}
	else 
	{
		if(fHamWeapon[iFightWeapons]) DisableHamForward(fHamWeapon[iFightWeapons]);
	}
}

public set_on_fire()
{
	for(new i = 1; i <= gMaxPlayers; i++)
	{
		if(is_user_alive(i) && get_user_team(i) == 2 && !bFire[i])
		{
			bFire[i] = true;

			fire_effects(i + TASK_EFFECT);
			fire_damage(i + TASK_FIRE);
		}
	}
}


public fire_effects(id)
{
	id -= TASK_EFFECT;
	
	if(!is_user_alive(id) || !bFire[id]) return;
	
	new iOrigin[3];

	get_user_origin(id, iOrigin);

	draw_fire(iOrigin);

	set_task(0.2, "fire_effects", id + TASK_EFFECT);
}

public fire_damage(id)
{
	id -= TASK_FIRE;
	
	if(!is_user_alive(id) || !bFire[id]) return;
	
	new iHealth = get_user_health(id) - 20;

	set_pev(id, pev_dmg_inflictor, 0);

	if(iHealth <= 0) user_kill(id, 1);
	else
	{
		set_pev(id, pev_health, float(iHealth));

		emit_sound(id, CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM);

		set_task(1.0, "fire_damage", id + TASK_FIRE);
	}
}

public draw_fire(iOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	
	write_byte(TE_SPRITE);
	
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	
	write_short(gFlash);
	
	write_byte(20);
	write_byte(200);
	
	message_end();

	smoke_effect(iOrigin, 20);
}

public smoke_effect(iOrigin[3], iAmount)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	
	write_byte(TE_SMOKE);
	
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	
	write_short(gSmoke);

	write_byte(iAmount);
	write_byte(10);
	
	message_end();
}

public jail_is_fight()
	return iFight[0] ? true : false;