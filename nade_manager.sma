#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Nade Manager"
#define AUTHOR "O'Zone"
#define VERSION	"1.6"

#define OFFSET_NADE_AMMO 387

new grenadeBought[MAX_PLAYERS + 1][3], grenadeUsed[MAX_PLAYERS + 1][3], bool:picked[MAX_PLAYERS + 1], 
	bool:throwed[MAX_PLAYERS + 1], bool:freeze, buyNadeCount[3], useNadeCount[3], throwNadeTime[3], roundStartTime;

enum { FLASH, HE, SMOKE };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	buyNadeCount[FLASH] = register_cvar("buy_maxflash", "2");
	useNadeCount[FLASH] = register_cvar("use_maxflash", "4");
	throwNadeTime[FLASH] = register_cvar("flash_time", "0");
	buyNadeCount[HE] = register_cvar("buy_maxhe", "1");
	useNadeCount[HE] = register_cvar("use_maxhe", "2");
	throwNadeTime[HE] = register_cvar("he_time", "0");
	buyNadeCount[SMOKE] = register_cvar("buy_maxsmoke", "1");
	useNadeCount[SMOKE] = register_cvar("use_maxsmoke", "2");
	throwNadeTime[SMOKE] = register_cvar("smoke_time", "0");
	
	RegisterHam(Ham_Item_Deploy, "weapon_flashbang", "flash_deploy");
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "hegrenade_deploy");
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "smoke_deploy");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "flash_attack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "hegrenade_attack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_smokegrenade", "smoke_attack");
	RegisterHam(Ham_GiveAmmo, "player", "grenade_ammo");
	RegisterHam(Ham_Touch, "grenade", "nade_pickup");
	RegisterHam(Ham_Spawn, "player", "player_spawn", 0);
	
	register_forward(FM_Touch, "nade_pickup");
	register_forward(FM_SetModel, "nade_use");

	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_logevent("round_start", 2, "1=Round_Start");
}

public new_round()
	freeze = true;

public round_start()
{
	freeze = false;

	roundStartTime = floatround(get_gametime());
}

public player_spawn(id)
{
	grenadeBought[id][FLASH] = 0;
	grenadeBought[id][HE] = 0;
	grenadeBought[id][SMOKE] = 0;

	grenadeUsed[id][FLASH] = 0;
	grenadeUsed[id][HE] = 0;
	grenadeUsed[id][SMOKE] = 0;
}

public flash_deploy(ent)
	check_nade(ent, FLASH, 1);

public hegrenade_deploy(ent)
	check_nade(ent, HE, 1);

public smoke_deploy(ent)
	check_nade(ent, SMOKE, 1);

public flash_attack(ent)
	check_nade(ent, FLASH);

public hegrenade_attack(ent)
	check_nade(ent, HE);

public smoke_attack(ent)
	check_nade(ent, SMOKE);

stock check_nade(ent, i, deploy = 0)
{
	if (freeze || !pev_valid(ent)) return;

	static nadeWeapon[21], nadeName[7], nadeCount, nadeTime, id;

	id = pev(ent, pev_owner);

	if (!is_user_alive(id)) return;

	switch(i) {
		case FLASH: {
			nadeTime = get_pcvar_num(throwNadeTime[FLASH]);
			nadeName = "Flash";
			nadeWeapon = "weapon_flashbang";
		} case HE: {
			nadeTime = get_pcvar_num(throwNadeTime[HE]);
			nadeName = "HE";
			nadeWeapon = "weapon_hegrenade";
		} case SMOKE: {
			nadeTime = get_pcvar_num(throwNadeTime[SMOKE]);
			nadeName = "Smoke";
			nadeWeapon = "weapon_smokegrenade";
		}
	}

	nadeCount = get_pcvar_num(useNadeCount[i]);

	if (grenadeUsed[id][i] >= nadeCount && nadeCount > 0) {
		client_cmd(id, "lastinv");

		client_print(id, print_center, "Nie mozesz uzyc %s wiecej niz %d raz%s w rundzie.", nadeName, nadeCount, nadeCount > 1 ? "y" : "");

		return;
	}

	if ((nadeTime + roundStartTime) > floatround(get_gametime()) && !deploy) {
		client_cmd(id, "lastinv");
		client_cmd(id, nadeWeapon);

		new timeLeft = roundStartTime + nadeTime - floatround(get_gametime());

		client_print(id, print_center, "Nie mozesz rzucic %s przez nastepne %d sekund%s.", nadeName, timeLeft, timeLeft < 5 ? (timeLeft < 2 ? "e" : "y") : "");

		return;
	}

	if(!deploy) throwed[id] = true;
}

public grenade_ammo(id, amount, const name[], Max)
{
	if (!is_user_alive(id)) return;

	static nadeWeapon[21], nadeName[7], nadeType, nadeCount, i;

	if (equal(name, "Flashbang")) {
		i = FLASH;
		nadeType = CSW_FLASHBANG;
		nadeName = "Flash";
		nadeWeapon = "weapon_flashbang";
	} else if (equal(name, "HEGrenade")) {
		i = HE;
		nadeType = CSW_HEGRENADE;
		nadeName = "HE";
		nadeWeapon = "weapon_hegrenade";
	} else if (equal(name, "SmokeGrenade")) {
		i = SMOKE;
		nadeType = CSW_SMOKEGRENADE;
		nadeName = "Smoke";
		nadeWeapon = "weapon_smokegrenade";
	} else return;

	nadeCount = get_pcvar_num(buyNadeCount[i]);

	if (nadeCount < 0) return;

	if (!picked[id]) grenadeBought[id][i]++;
	
	if (grenadeBought[id][i] > get_pcvar_num(buyNadeCount[i]) && !picked[id]) {
		client_print(id, print_center, "Mozesz kupic tylko %d %s w rundzie.", nadeCount, nadeName);

		set_pdata_int(id, OFFSET_NADE_AMMO + i, get_pdata_int(id, OFFSET_NADE_AMMO + i) - 1);

		switch(i) {
			case FLASH: cs_set_user_money(id, min(cs_get_user_money(id) + 200, 16000));
			case HE, SMOKE: cs_set_user_money(id, min(cs_get_user_money(id) + 300, 16000));
		}

		if (get_user_weapon(id) == nadeType) client_cmd(id, "lastinv");
		else {
			client_cmd(id, nadeWeapon);
			client_cmd(id, "lastinv");
		}
	}

	if (picked[id]) picked[id] = false;
}

public nade_pickup(ent, id)
{
	if (!is_user_alive(id) || !pev_valid(ent) || !(pev(ent, pev_flags) & FL_ONGROUND)) return;

	picked[id] = true;

	static model[32];
			
	pev(ent, pev_model, model, charsmax(model));

	if (containi(model, "models/w_flashbang.mdl") && get_pdata_int(id, OFFSET_NADE_AMMO + FLASH) == 2) return;
	else if (equal(model, "models/w_hegrenade.mdl") && get_pdata_int(id, OFFSET_NADE_AMMO + HE) == 1) return;
	else if (equal(model, "models/w_smokegrenade.mdl") && get_pdata_int(id, OFFSET_NADE_AMMO + SMOKE) == 1) return;
	else if (equal(model, "models/w_snowball.mdl")) {
		switch(pev(ent, pev_iuser1)) {
			case 1: if (get_pdata_int(id, OFFSET_NADE_AMMO + FLASH) == 2) return;
			case 2: if (get_pdata_int(id, OFFSET_NADE_AMMO + HE) == 1) return;
			case 3: if (get_pdata_int(id, OFFSET_NADE_AMMO + SMOKE) == 1) return;
		}
	}
}

public nade_use(ent, const model[])
{
	if (!pev_valid(ent)) return FMRES_IGNORED;
	
	if (model[0] == 'm' && model[7] == 'w' && model[8] == '_') {
		new id = pev(ent, pev_owner);

		if (!is_user_alive(id) || !throwed[id]) return FMRES_IGNORED;

		throwed[id] = false;

		switch (model[9]) {
			case 'f': grenadeUsed[id][FLASH]++;
			case 'h': grenadeUsed[id][HE]++;
			case 's': grenadeUsed[id][SMOKE]++;
		}

		if (equal(model, "models/w_snowball.mdl")) {
			switch(pev(ent, pev_iuser1)) {
				case 1: grenadeUsed[id][FLASH]++;
				case 2: grenadeUsed[id][HE]++;
				case 3: grenadeUsed[id][SMOKE]++;
			}
		}
	}

	return FMRES_IGNORED;
}