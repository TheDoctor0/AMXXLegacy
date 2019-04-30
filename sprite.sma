#include <amxmodx>
#include <csx>

#define PLUGIN  "Sprite Test"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

#define STATS 1
#define TEAM_RANK 2
#define ENEMY_RANK 4
#define BELOW_HEAD 8

#define MAX_RANKS 18

new sprites[MAX_RANKS + 1], spriteId, defaultInfo, aimHUD;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say test", "test");
	
	register_event("StatusValue", "show_icon", "be", "1=2", "2!0");
	register_event("StatusValue", "hide_icon", "be", "1=1", "2=0");

	defaultInfo = get_xvar_id("PlayerName");
	
	aimHUD = CreateHudSyncObj();
}

public test(id)
	if (++spriteId > MAX_RANKS) spriteId = 0;

public plugin_precache()
{
	new spriteFile[32];
	
	for (new i = 0; i <= MAX_RANKS; i++) {
		spriteFile[0] = '^0';

		formatex(spriteFile, charsmax(spriteFile), "sprites/csgo_ranks/%d.spr", i);
		
		if (file_exists(spriteFile)) sprites[i] = precache_model(spriteFile);
	}
}

public hide_icon(id)
{
	if (get_xvar_num(defaultInfo)) return;

	ClearSyncHud(id, aimHUD);
}

public show_icon(id)
{
	new color[2], Float:height, defaultHUD = get_xvar_num(defaultInfo), flags = read_flags("abcd"), target = read_data(2), name[32];

	get_user_name(target, name, charsmax(name));

	if (get_user_team(target) == 1) color[0] = 255;
	else color[1] = 255;

	if (flags & BELOW_HEAD) height = 0.6;
	else height = 0.35;

	if (get_user_team(id) == get_user_team(target)) {
		if (flags && !defaultHUD) {
			new weaponName[32], weapon = get_user_weapon(target);

			if (weapon) xmod_get_wpnname(weapon, weaponName, charsmax(weaponName));

			set_hudmessage(color[0], 50, color[1], -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

			if (flags & TEAM_RANK) {
				if (flags & STATS) ShowSyncHudMsg(id, aimHUD, "%s : %s^n%d HP | %d AP | %s", name, "Global Elite", get_user_health(target), get_user_armor(target), weaponName);
				else ShowSyncHudMsg(id, aimHUD, "%s : %s", name, "Global Elite");
			} else {
				if (flags & STATS) ShowSyncHudMsg(id, aimHUD, "%s^n%d HP | %d AP | %s", name, get_user_health(target), get_user_armor(target), weaponName);
				else ShowSyncHudMsg(id, aimHUD, "%s", name);
			}
		}

		create_attachment(id, target, 45, sprites[spriteId], 15);
	} else if (flags && !defaultHUD)
	{
		set_hudmessage(color[0], 50, color[1], -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

		if (flags & ENEMY_RANK) ShowSyncHudMsg(id, aimHUD, "%s : %s", name, "Global Elite");
		else ShowSyncHudMsg(id, aimHUD, "%s", name);
	}
}

stock create_attachment(id, entity, offset, sprite, life)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);
	write_coord(offset);
	write_short(sprite);
	write_short(life);
	message_end();
}