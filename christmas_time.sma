#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

#define PLUGIN	"Christmas Time"
#define AUTHOR	"O'Zone"
#define VERSION	"1.1.0"

enum _:modelsData { SNOWBALL, SNOWBALL_HE, SNOWBALL_FLASH, SNOWBALL_SMOKE, PRESENT, SNOWMAN, CHRISTMAS_TREE, SANTA_HAT };

new const models[modelsData][] = {
	"models/w_snowball.mdl",
	"models/v_snowball_he.mdl",
	"models/v_snowball_flash.mdl",
	"models/v_snowball_smoke.mdl",
	"models/present.mdl",
	"models/snowman.mdl",
	"models/christmastree.mdl",
	"models/santahat.mdl"
};

new HamHook:forwardRain, HamHook:forwardSound, santaHatsEnabled, santaHats, bool:santaHat[MAX_PLAYERS + 1], santaHatEnt[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("christmas_santa_hat", "1"), santaHatsEnabled);

	register_clcmd("say /czapka", "change_hat");
	register_clcmd("say_team /czapka", "change_hat");

	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "model_he", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_flashbang", "model_flash", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "model_smoke", 1);

	register_forward(FM_SetModel, "forward_model");
		
	DisableHamForward(forwardRain);
	DisableHamForward(forwardSound);

	santaHats = nvault_open("christmas_time");
	
	if (santaHats == INVALID_HANDLE) set_fail_state("Nie mozna otworzyc pliku christmas_time.vault");
}

public plugin_end()
	nvault_close(santaHats);

public plugin_precache()
{
	for (new i; i <= SANTA_HAT; i++) engfunc(EngFunc_PrecacheModel, models[i]);
	
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));
	
	forwardRain = RegisterHam(Ham_Spawn, "env_rain", "spawn_rain", 1);
	forwardSound = RegisterHam(Ham_Spawn, "ambient_generic", "spawn_sound", 1);
}

public client_connect(id)
{
	client_cmd(id, "cl_weather 1");
	cmd_execute(id, "cl_weather 1");
}

public client_putinserver(id)
	load_hat(id);

public client_disconnected(id)
	remove_hat(id);

public change_hat(id)
{
	if (!santaHatsEnabled) return PLUGIN_HANDLED;

	if (!santaHat[id]) {
		client_print_color(id, id, "^x03[SWIETA]^x01 Twoja czapka mikolaja zostala^x04 wlaczona^x01.");

		make_hat(id);
	} else {
		client_print_color(id, id, "^x03[SWIETA]^x01 Twoja czapka mikolaja zostala^x04 wylaczona^x01.");

		remove_hat(id);
	}

	return PLUGIN_HANDLED;
}

public make_hat(id)
{
	santaHat[id] = true;

	santaHatEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
	if (pev_valid(santaHatEnt[id])) {
		engfunc(EngFunc_SetModel, santaHatEnt[id], models[SANTA_HAT]);

		set_pev(santaHatEnt[id], pev_movetype, MOVETYPE_FOLLOW);
		set_pev(santaHatEnt[id], pev_aiment, id);
		set_pev(santaHatEnt[id], pev_owner, id);
	}
}

public remove_hat(id)
{
	santaHat[id] = false;

	if (pev_valid(santaHatEnt[id])) {
		engfunc(EngFunc_RemoveEntity, santaHatEnt[id]);

		santaHatEnt[id] = 0;
	}
}

public spawn_rain(ent)
{
	if (!pev_valid(ent)) return HAM_IGNORED;
	
	engfunc(EngFunc_RemoveEntity, ent);
	
	return HAM_IGNORED;
}

public spawn_sound(ent)
{
	if (!pev_valid(ent)) return HAM_IGNORED;
	
	static sound[16];
	
	pev(ent, pev_message, sound, charsmax(sound));
	
	if (!equal(sound, "ambience/rain.wav")) return HAM_IGNORED;
	
	engfunc(EngFunc_RemoveEntity, ent);
	
	return HAM_IGNORED;
}

public model_he(weapon)
{
	static id;

	id = pev(weapon, pev_owner);

	set_pev(id, pev_viewmodel2, models[SNOWBALL_HE]);

	return HAM_SUPERCEDE;
}
	
public model_flash(weapon)
{
	static id;

	id = pev(weapon, pev_owner);

	set_pev(id, pev_viewmodel2, models[SNOWBALL_FLASH]);

	return HAM_SUPERCEDE;
}

public model_smoke(weapon)
{
	static id;

	id = pev(weapon, pev_owner);

	set_pev(id, pev_viewmodel2, models[SNOWBALL_SMOKE]);

	return HAM_SUPERCEDE;
}

public forward_model(entity, const model[])
{
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	if (equali(model,"models/w_c4.mdl")) {
		switch (random_num(1, 3)) {
			case 1: {
				engfunc(EngFunc_SetModel, entity, models[PRESENT]);

				return FMRES_SUPERCEDE;
			} case 2: {
				engfunc(EngFunc_SetModel, entity, models[SNOWMAN]);

				return FMRES_SUPERCEDE;
			} case 3: {
				engfunc(EngFunc_SetModel, entity, models[CHRISTMAS_TREE]);

				return FMRES_SUPERCEDE;
			}
		}
	}
	
	if (model[0] == 'm' && model[7] == 'w' && model[8] == '_' && ((model[9] == 'f' && model[10] == 'l')  || (model[9] == 'h' && model[10] == 'e') || (model[9] == 's' && model[10] == 'm'))) {
		switch (model[9]) {
			case 'f': {
				fm_set_rendering(entity, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 125);

				set_pev(entity, pev_iuser1, 1);
			}
			case 'h': {
				fm_set_rendering(entity, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 125);

				set_pev(entity, pev_iuser1, 2);
			}
			case 's': {
				fm_set_rendering(entity, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 125);

				set_pev(entity, pev_iuser1, 3);
			}
		}

		engfunc(EngFunc_SetModel, entity, models[SNOWBALL]);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public save_hat(id, enabled)
{
	new vaultKey[32];

	get_user_name(id, vaultKey, charsmax(vaultKey));
	
	enabled ? nvault_set(santaHats, vaultKey, "1") : nvault_remove(santaHats, vaultKey);
}

public load_hat(id)
{
	new vaultKey[32], vaultData[1];

	get_user_name(id, vaultKey, charsmax(vaultKey));
	
	if (nvault_get(santaHats, vaultKey, vaultData, charsmax(vaultData))) make_hat(id);
}

stock fm_set_rendering(index, fx = kRenderFxNone, r = 0, g = 0, b = 0, render = kRenderNormal, amount = 16)
{
	set_pev(index, pev_renderfx, fx);

	new Float:renderColor[3];

	renderColor[0] = float(r);
	renderColor[1] = float(g);
	renderColor[2] = float(b);

	set_pev(index, pev_rendercolor, renderColor);
	set_pev(index, pev_rendermode, render);
	set_pev(index, pev_renderamt, float(amount));
}

stock cmd_execute(id, const text[], any:...)
{
	#pragma unused text

	new message[192];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}