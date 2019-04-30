#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "JailBreak: Podziel"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /podziel", "Podziel");
	register_clcmd("say_team /podziel", "Podziel");
	register_clcmd("podziel", "Podziel");
	
	register_clcmd("say /rozdziel", "Rozdziel");
	register_clcmd("say_team /rozdziel", "Rozdziel");
	register_clcmd("rozdziel", "Rozdziel");
}

public Rozdziel(id) 
{
    if(!is_user_alive(id) || get_user_team(id) != 2) return PLUGIN_HANDLED;

    for(new i = 1; i <= 32; i++) 
	{
		if(!is_user_alive(i) || get_user_team(i) != 1  || jail_get_prisoner_ghost(i)) continue;

		set_user_rendering(i);
    }
	
    return PLUGIN_HANDLED;
}

public Podziel(id) 
{
	if(!is_user_alive(id) || get_user_team(id) != 2) return PLUGIN_HANDLED;

	new bool:bTeam;
	
	for(new i = 1; i <= 32; i++) 
	{		
		if(!is_user_alive(i) || get_user_team(i) != 1 || jail_get_prisoner_ghost(i)) continue;

		if(bTeam) 
		{ 
			set_pev(i, pev_body, 1); 
			
			client_cmd(i, "spk vox/yellow");
			
			set_user_rendering(i, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 5);
		}
		else 
		{ 
			set_pev(i, pev_body, 2);
			
			client_cmd(i, "spk vox/white");
			
			set_user_rendering(i, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 5);
		}
		
		client_print(i, print_center, "Masz kolor: %s", bTeam ? "Zolty" : "Bialy");

		client_print_color(i, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Masz kolor: %s", bTeam ? "Zolty" : "Bialy");
		
		bTeam = !bTeam;
	}
	
	return PLUGIN_HANDLED;
}