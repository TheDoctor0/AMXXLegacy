#include <amxmodx>
#include <jailbreak>
#include <fun>

#define PLUGIN "JailBreak: Losowanie"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_RESET 8433

new gHUD;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /losuj", "Losowanie");
	register_clcmd("say_team /losuj", "Losowanie");
	register_clcmd("losuj", "Losowanie");

	gHUD = CreateHudSyncObj();
}

public Losowanie(id) 
{
	if(!is_user_alive(id) || (!(get_user_flags(id) & ADMIN_KICK) && jail_get_prowadzacy() != id)) return PLUGIN_HANDLED;

	new player = LosowyGracz();
	
	if(player < 0) return PLUGIN_HANDLED;
	
	client_cmd(player, "spk fvox/blip");
	
	set_user_rendering(player, kRenderFxGlowShell, 255, 212, 85, kRenderNormal, 8);
	
	set_task(5.0, "Reset", player + TASK_RESET);
	
	new szName[32];

	get_user_name(player, szName, charsmax(szName));
	
	set_hudmessage(255, 255, 255, 0.01, 0.37, 0, 6.0, 5.0);
	
	ShowSyncHudMsg(0, gHUD, "Wylosowany wiezien: %s", szName);
	
	return PLUGIN_HANDLED;
}

stock LosowyGracz()
{
	new i, j, graczeTT[32];
	
	for(i = 1; i <= 32; i++) if(is_user_alive(i) && get_user_team(i) == 1) graczeTT[j++] = i;

	if(j == 1) return graczeTT[0];
	
	if(j > 0) return graczeTT[random(j)];
	
	return -1;
}

public Reset(id) 
{
	id -= TASK_RESET;
	
	if(!is_user_alive(id)) return;

	set_user_rendering(id);
}