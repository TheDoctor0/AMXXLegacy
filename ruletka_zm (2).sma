#include <amxmodx>
#include <fun>
#include <colorchat>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <zombieplague>

#define PLUGIN "Ruletka ZM"
#define VERSION "1.0"
#define AUTHOR "O`Zone"

#define is_user_player(%1) 1 <= %1 <= g_MaxClients

#define TASK_RULETKA 6855
#define TASK_INFO 4643

new const g_Lang[][] = { "say /ruletka","say_team /ruletka","say /los","say_team /los"}

new tag[] = "Ruletka";
new bool:g_Ruletka[33];

new skoki[33];
new bool:ma_skoki[33];

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i;i<sizeof g_Lang;i++)
		register_clcmd(g_Lang[i], "Ruletka");
	register_logevent("KoniecRundy", 2, "1=Round_End");
	register_forward(FM_CmdStart, "MultiJump");
	set_task(200.0, "info", TASK_INFO, _, _, "b");
}

public client_authorized(id)
	g_Ruletka[id] = true

public client_disconnect(id)
	remove_task(id+TASK_INFO)

public Reset(id){
	id -= TASK_RULETKA
	if(is_user_connected(id)){
		g_Ruletka[id] = true
		ColorChat(id, RED, "[%s]^x01 Mozesz juz uzyc ponownie^x04 ruletki^x01.", tag)
	}
}

public Ruletka(id){
	if(!is_user_alive(id)){
		ColorChat(id, GREEN, "[%s]^x01 Widziales kiedys trupa w kasynie?", tag)
		return PLUGIN_CONTINUE
	}
	if(zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id)){
		ColorChat(id, GREEN, "[%s]^x01 Widziales kiedys zombie w kasynie?", tag)
		return PLUGIN_CONTINUE
	}
	if(!g_Ruletka[id]){
		ColorChat(id, GREEN, "[%s]^x01 Ruletke mozesz uzyc raz na 5 min.", tag)
		return PLUGIN_CONTINUE
	}
	g_Ruletka[id] = false;
	set_task(300.0, "Reset", id+TASK_RULETKA);

	switch(random_num(1, 16)){
	case 1 :{
			ColorChat(id, RED, "[%s]^x01 Brawo, masz^x04 +100 HP.", tag);
			set_user_health(id, get_user_health(id)+100);
		}
	case 2 :{
			ColorChat(id, RED, "[%s]^x01 Pech, zostales z^x04 1 HP.", tag);
			set_user_health(id, 1);
		}
	case 3:{
			ColorChat(id, RED, "[%s]^x01 Mozesz czuc sie bezpieczniej, masz^x04 +50 kamizelki", tag);
			set_user_armor(id, get_user_armor(id)+50);
		}
	case 4:{
			ColorChat(id, RED, "[%s]^x01 Niestety, zaliczyles^x04 zgon.", tag);
			user_kill(id);
		}
	case 5:{
			ColorChat(id, RED, "[%s]^x01 Masz wielkiego pecha, straciles^x04 50AP.", tag);
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id)-50);
		}
	case 6:{
			ColorChat(id, RED, "[%s]^x01 Masz pecha, straciles^x04 20AP.", tag);
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id)-20);
		}
	case 7:{
			ColorChat(id, RED, "[%s]^x01 Wielkie gratulacje, zarobiles^x04 50AP.", tag);
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id)+50);
		}
	case 8:{
			ColorChat(id, RED, "[%s]^x01 Gratulacje, zarobiles^x04 20AP.", tag);
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id)+20);
		}
	case 9:{
			ColorChat(id, RED, "[%s]^x01 Niezle, jestes calkowicie^x04 niewidzialny.", tag);
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0);
		}
	case 10:{
			ColorChat(id, RED, "[%s]^x01 Poskacz sobie, masz mniejsza^x04 grawitacje.", tag);
			set_user_gravity(id, 0.5);
		}
	case 11:{
			ColorChat(id, RED, "[%s]^x01 Jestes teraz jak krolik, masz^x04 dodatkowy skok.", tag);
			ma_skoki[id] = true;
		}
	case 12:{
			ColorChat(id, RED, "[%s]^x01 Chcesz byc hardcorem? Wiec masz tylko^x04 noz.", tag);
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
		}
	case 13:{
			ColorChat(id, RED, "[%s]^x01 Uppss.. stales sie^x04 Zombie.", tag);
			zp_infect_user(id);
		}
	case 14:{
			ColorChat(id, RED, "[%s]^x01 Szybko, podpal Zombie, masz^x04 Napalm.", tag);
			give_item(id, "weapon_hegrenade");
		}
	case 15:{
			ColorChat(id, RED, "[%s]^x01 Zamroz ich teraz, dostajesz^x04 Frost Nade.", tag);
			give_item(id, "weapon_flashbang");
		}
	case 16:{
			ColorChat(id, RED, "[%s]^x01 Niech stanie sie jasnosc, dostajesz^x04 Flare.", tag);
			give_item(id, "weapon_smokegrenade");
		}
	}

	return PLUGIN_CONTINUE
}

public KoniecRundy()
{
	for(new id = 1; id <= 33; id++)
	{
		if(is_user_connected(id))
		{
			set_user_gravity(id, 1.0);
			set_rendering(id,kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
			ma_skoki[id] = false;
		}
	}
}

public MultiJump(id, uc_handle)
{
	if(!is_user_alive(id) || !ma_skoki[id])
		return FMRES_IGNORED;

	new flags = pev(id, pev_flags);

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && skoki[id])
	{
		skoki[id]--;
		new Float:velocity[3];
		pev(id, pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity,velocity);
	}
	else if(flags & FL_ONGROUND)
		skoki[id] = 1;

	return FMRES_IGNORED;
}

public info()
{
	if(get_playersnum() != 0)
		ColorChat(0, RED, "[%s]^x01 Aby uzyc ruletki wpisz^x04 /ruletka", tag)
}
