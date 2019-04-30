/* =======================================================================================
/
/
/			[ZP] Extra Item : Dual Mp7
/			  ( weapon for humans )
/
/			     by Van 'n Fry
/
/
/
/	Description :
/
/			Another Extra weapon for Humans and very powerful too...
/			Dual MP7A1  by Van
/
/
/
/	Credits :
/
/       KaOs - For his Dual MP5 (Ogiginal)
/
/       Van - For his Dial MP7A1  (Remake CSO)
/
*/


#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <zombieplague>

#define PLUGIN "[ZP] Extra : Dual MP7a1"
#define VERSION "0.7.2"
#define AUTHOR "Van"

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

new MP5_MODEL_NAME[64] = "models/zombie_plague/v_dmp7a1.mdl"
new g_dualmp5_unlimitedammo, g_dualmp5_doubledamage
new bool:g_hasDual[33]

new g_item_name[] = { "Dual MP7a1" }
new g_itemid_dual_mp5, g_dualmp5_cost

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("zp_extra_dual_mp5",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	g_dualmp5_unlimitedammo = register_cvar("zp_dualmp5_unlimitedammo", "1")
	g_dualmp5_doubledamage = register_cvar("zp_dualmp5_doubledamage", "1")
	g_dualmp5_cost = register_cvar("zp_dualmp5_cost", "25")
	
	g_itemid_dual_mp5 = zp_register_extra_item(g_item_name, get_pcvar_num(g_dualmp5_cost), ZP_TEAM_HUMAN)
	
	register_clcmd("say /dm7", "buy_dual")
	register_clcmd("say_team /dm7", "buy_dual")
	
	register_event("ResetHUD","newRound","b")
	register_event("DeathMsg", "Death", "a")
	register_event("WeapPickup","checkModel","b","1=19")
	register_event("CurWeapon","checkWeapon","be","1=1")

	if (get_pcvar_num(g_dualmp5_doubledamage) == 1) 
	{
		// When somebody has damage done to them, call doDamage (so we can multiply 2x)
		register_event("Damage", "doDamage", "b", "2!0")
	}
}

public client_connect(id)
{
	g_hasDual[id] = false
}

public client_disconnected(id)
{
	g_hasDual[id] = false
}

public Death()
{
	g_hasDual[read_data(2)] = false
}

public newRound(id)
{
	g_hasDual[id] = false
}

public plugin_precache()
{
	precache_model(MP5_MODEL_NAME)
	return PLUGIN_CONTINUE
}

public buy_dual(id)
{
	if (zp_get_user_zombie(id) && !is_user_alive(id))
		return PLUGIN_HANDLED
		
	if (g_hasDual[id])
	{
		client_print(id, print_chat, "[ZP] У вас есть две MP7a1")
		return PLUGIN_HANDLED
	}
	
	new ammo_packs = zp_get_user_ammo_packs(id)
	new ammo_cost = get_pcvar_num(g_dualmp5_cost)
	
	if (ammo_packs < ammo_cost)
	{
		client_print(id, print_chat, "[ZP] У вас нехватает кредитов!", ammo_cost)
		return PLUGIN_HANDLED
	}
	
	zp_set_user_ammo_packs(id, ammo_packs - ammo_cost)
	
	g_hasDual[id] = true 
	
	fm_give_item(id, "weapon_mp5navy")
	fm_give_item(id, "ammo_9mm")
	fm_give_item(id, "ammo_9mm")
	fm_give_item(id, "ammo_9mm")
	fm_give_item(id, "ammo_9mm")
	client_print(id, print_chat,"[ZP] Вы купили две MP7a1.")
	
	return PLUGIN_HANDLED
}
	
public checkModel(id)
{ 
	if (zp_get_user_zombie(id))
		return PLUGIN_HANDLED
	
	entity_set_string(id, EV_SZ_viewmodel, MP5_MODEL_NAME)
		
	new iCurrent
	iCurrent = find_ent_by_class(-1,"weapon_mp5navy")

	while(iCurrent != 0) 
	{
		iCurrent = find_ent_by_class(iCurrent,"weapon_mp5navy")
	}
	return PLUGIN_HANDLED
} 

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId

	plrWeapId = get_user_weapon(id, plrClip, plrAmmo)

	if (plrWeapId == CSW_MP5NAVY)
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}

	if (plrClip == 0)
	{
		if(get_pcvar_num(g_dualmp5_unlimitedammo) == 1) 
		{
			get_weaponname(plrWeapId, plrWeap, 31)
			fm_give_item(id, plrWeap)
			engclient_cmd(id, plrWeap) 
			engclient_cmd(id, plrWeap)
			engclient_cmd(id, plrWeap)
		}
	}
	return PLUGIN_CONTINUE 
} 

public doDamage(id)
{
	new plrDmg = read_data(2)
	new plrWeap
	new plrPartHit
	new plrAttacker = get_user_attacker(id, plrWeap, plrPartHit)
	new plrHealth = zp_get_zombie_maxhealth(id)
	new plrNewDmg

	//
	// plrDmg is set to how much damage was done to the victim
	// plrHealth is set to how much health the victim has
	// plrAttacker is set to the id of the person doing the shooting
	//
	// Could have put the above on one line, didn't for learning purposes (nubs may read this!) lol
	// Example: new plrWeap, plrPartHit, plrAttacker = get_user_attacker( .. etc etc
	//

	if (plrWeap != CSW_MP5NAVY)
	{
	    // If the damage was not done with an MP5, just exit function..
		return PLUGIN_CONTINUE
	}

	if (is_user_alive(id) && !zp_get_user_zombie(id))
	{
	    // If the victim is still alive.. (should be)
		plrNewDmg = (plrHealth - plrDmg)
		//
		// Make the new damage their current health - plrDmg..
		// This is actually damage 2x, becuase when they did the damage
		// lets say it was 10, now this is subtracting 10 from current heatlh
		// doing 20, so thats 2 times =D
		//
		if(plrNewDmg < 1)
		{
			message_begin(MSG_ALL, get_user_msgid("DeathMsg"), {0,0,0}, 0)
			// Start a death message, so it doesnt just say "Player Died",
			// the killer will get the credit
			
			write_byte(plrAttacker)		// Write KILLER ID
			write_byte(id)			// Write VICTIM ID
			write_byte(random_num(0,1))
			// Write HEAD SHOT or not
			// I made this random because I was unsure of how to detect
			// if plrPartHit was "head" or not.. someone help..
			
			write_string("mp5navy") 	// Write the weapon VICTIM ID was killed with..
			message_end()			// End the message..
		}
		fm_set_user_health(id, plrNewDmg)
		// Then set the health, even if it will kill the player
	}
	return PLUGIN_CONTINUE
}

public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_itemid_dual_mp5)
	{
		fm_give_item(player, "weapon_mp5navy")
		fm_give_item(player, "ammo_9mm")
		fm_give_item(player, "ammo_9mm")
		fm_give_item(player, "ammo_9mm")
		fm_give_item(player, "ammo_9mm")
		client_print(player, print_chat,"[ZP] Вы купили две MP7a1, Повеселитесь!")
	}
	return PLUGIN_CONTINUE
}

stock fm_give_item(index, const item[]) 
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

stock fm_set_user_health(index, health) 
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}
