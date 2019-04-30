#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"Hobo Nade Manager"
#define AUTHOR	"hoboman313 & O'Zone"
#define VERSION	"1.3"

#define MAX_PLAYERS 32

#define OFFSET_TEAM 114
#define OFFSET_NADE_AMMO 387

#define NADE_TIME_CHECK 0.5

new grenBought[MAX_PLAYERS + 1][3], nadeName[14], buyNadeCount[3], pickNadeCount[3], throwNadeTime[3], color[3], roundStartTime, nadeTimeCache, msgSync;

enum { FLASH, HE, SMOKE };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	buyNadeCount[FLASH] = register_cvar("hobo_buy_maxflash", "2");
	pickNadeCount[FLASH] = register_cvar("hobo_pick_maxflash", "2");
	throwNadeTime[FLASH] = register_cvar("hobo_flash_time", "0");
	buyNadeCount[HE] = register_cvar("hobo_buy_maxhe", "1");
	pickNadeCount[HE] = register_cvar("hobo_ct_maxhe", "1");
	throwNadeTime[HE] = register_cvar("hobo_he_time", "0");
	buyNadeCount[SMOKE] = register_cvar("hobo_buy_maxsmoke", "1");
	pickNadeCount[SMOKE] = register_cvar("hobo_max_maxsmoke", "1");
	throwNadeTime[SMOKE] = register_cvar("hobo_smoke_time", "0");
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "flash_attack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "hegrenade_attack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_smokegrenade", "smoke_attack");
	
	RegisterHam(Ham_GiveAmmo, "player", "grenade_ammo");
	
	register_forward(FM_Touch, "nade_pickup");

	register_logevent("round_start", 2, "1=Round_Start");

	msgSync = CreateHudSyncObj();
}

public round_start() 
	roundStartTime = floatround(get_gametime());

public player_spawn(id)
{
	grenBought[id][HE] = 0;
	grenBought[id][FLASH] = 0;
	grenBought[id][SMOKE] = 0;
}

public flash_attack(ent)
{
	if(floatround(get_gametime()) - roundStartTime > get_pcvar_num(throwNadeTime[FLASH])) return;
	
	color[0] = 100;
	color[1] = 100;
	color[2] = 100;

	nadeTimeCache = get_pcvar_num(throwNadeTime[FLASH]);
	nadeName = "Flash";

	check_time(ent);
}

public hegrenade_attack(ent)
{
	if(floatround(get_gametime()) - roundStartTime > get_pcvar_num(throwNadeTime[HE])) return;
	
	color[0] = 200;
	color[1] = 0;
	color[2] = 0;

	nadeTimeCache = get_pcvar_num(throwNadeTime[HE]);
	nadeName = "HE";

	check_time(ent);
}

public smoke_attack(ent)
{
	if(floatround(get_gametime()) - roundStartTime > get_pcvar_num(throwNadeTime[SMOKE])) return;
	
	color[0] = 0;
	color[1] = 200;
	color[2] = 0;

	nadeTimeCache = get_pcvar_num(throwNadeTime[SMOKE]);
	nadeName = "Smoke";

	check_time(ent);
}

public check_time(ent)
{	
	
	if((nadeTimeCache + roundStartTime) > floatround(get_gametime()))
	{
		new id = pev(ent, pev_owner);
		client_cmd(id, "weapon_knife");
			
		set_hudmessage(color[0], color[1], color[2], -1.0, 0.25, 1, 0.1, 3.0, 0.05, 0.05, -1);
		ShowSyncHudMsg(id, msgSync, "Nie mozesz rzucic granatu %s przez nastepne %d sekund.", nadeName, roundStartTime + nadeTimeCache - floatround(get_gametime()));
	}
}

public grenade_ammo(id, amount, const name[], Max)
{
	static nadeNameSw[21], nadeType, nadeCount, i;

	if(equal(name, "Flashbang"))
	{
		i = FLASH;
		nadeType = CSW_FLASHBANG;
		nadeName = "Flash";
		nadeNameSw = "weapon_flashbang";
	}
	else if(equal(name, "HEGrenade"))
	{
		i = HE;
		nadeType = CSW_HEGRENADE;
		nadeName = "HE";
		nadeNameSw = "weapon_hegrenade";
	}
	else if(equal(name, "SmokeGrenade"))
	{
		i = SMOKE;
		nadeType = CSW_SMOKEGRENADE;
		nadeName = "Smoke";
		nadeNameSw = "weapon_smokegrenade";
	}
	else return;

	nadeCount = get_pcvar_num(buyNadeCount[i]);
	
	if(nadeCount < 0) return;
	
	grenBought[id][i]++;
	
	if(grenBought[id][i] > nadeCount)
	{
		client_print_color(id, id, "^x04[LIMIT]^x01 Mozesz tylko kupic^x03 %d %s^x01 na runde.", nadeCount, nadeName);

		set_pdata_int(id, OFFSET_NADE_AMMO + i, get_pdata_int(id, OFFSET_NADE_AMMO + i) - 1);

		switch(i)
		{
			case FLASH: cs_set_user_money(id, min(cs_get_user_money(id) + 200, 16000));
			case HE, SMOKE: cs_set_user_money(id, min(cs_get_user_money(id) + 300, 16000));
		}

		if(get_user_weapon(id) == nadeType) client_cmd(id, "weapon_knife");
		else
		{
			client_cmd(id, nadeNameSw);
			client_cmd(id, "weapon_knife");
		}
	}		
}

public nade_pickup(ent, id)
{
	if(!is_user_alive(id) || !pev_valid(ent)) return;
		
	if(pev(ent, pev_flags) & FL_ONGROUND)
	{
		static modelName[32];
		new nadeCountCache, i;
			
		pev(ent, pev_model, modelName, 31);

		if(equal(modelName, "models/w_flashbang.mdl"))
		{
			i = FLASH;
				
			if(get_pdata_int(id, OFFSET_NADE_AMMO + i) == 2) return;
		}
		else if(equal(modelName, "models/w_hegrenade.mdl"))
		{
			i = HE;

			if(get_pdata_int(id, OFFSET_NADE_AMMO + i) == 1) return;
		}
		else if( equal( modelName, "models/w_smokerenade.mdl" ) )
		{
			i = SMOKE;
				
			if(get_pdata_int(id, OFFSET_NADE_AMMO + i) == 1) return;
		}
		else return;

		nadeCountCache = get_pcvar_num(pickNadeCount[i]);
			
		if(nadeCountCache < 0) return;
			
		if(grenBought[id][i] > nadeCountCache) grenBought[id][i] = nadeCountCache - 1;
		else grenBought[id][i]--;
	}
}
