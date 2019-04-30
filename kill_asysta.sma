/* --------------------------------------------------------------------------
CVary

- amx_killassist_enabled 0-1 (default: 1)
0 = Wylacz plugin / 1 = Uruchom plugin

- amx_killassist_mindamage 1-9999 (default: 30)
Ilosc dmg jaka musi zadac gracz zeby zaliczylo asyste
-------------------------------------------------------------- */
#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <fun>


#define PLUGIN		"Frag za Asyste"
#define VERSION		"1.1"
#define AUTHOR		"O'Zone"

#define MAXPLAYERS		32 + 1

#define HUD_colorR		255	// default: 255
#define HUD_colorG		155	// default: 155
#define HUD_colorB		0	// default: 0
#define HUD_posX		0.6	// default: 0.6
#define HUD_posY		0.20	// default: 0.2
#define HUD_fx			0	// default: 0
#define HUD_fxTime		0.0	// default: 0.0
#define HUD_holdTime		1.0	// default: 1.0
#define HUD_fadeInTime		0.3	// default: 0.3
#define HUD_fadeOutTime		1.0	// default: 1.0
#define HUD_channel			-1	// default: -1

#define TEAM_NONE			0
#define TEAM_TE			1
#define TEAM_CT			2
#define TEAM_SPEC			3

#define is_player(%1) (1 <= %1 <= g_iMaxPlayers)

new msgID_money;

new pCVar_enabled;
new pCVar_minDamage;

new ch_pCVar_enabled;
new ch_pCVar_minDamage;

new g_iTeam[MAXPLAYERS];
new g_iDamage[MAXPLAYERS][MAXPLAYERS];
new bool:g_bAlive[MAXPLAYERS] = {false, ...};
new bool:g_bOnline[MAXPLAYERS] = {false, ...};

new g_iMaxPlayers = 0;

//native bf1_add_assist_kill(id);
//native top_stats_add_kill(id);
native stats_add_kill(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	pCVar_enabled = register_cvar("amx_killassist_enabled", "1");
	pCVar_minDamage = register_cvar("amx_killassist_mindamage", "60");
	
	msgID_money = get_user_msgid("Money");
	
	register_event("Damage", "player_damage", "be", "2!0", "3=0", "4!0");
	register_event("DeathMsg", "player_die", "ae");
	register_event("TeamInfo", "player_joinTeam", "a");
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
	
	g_iMaxPlayers = get_maxplayers();	
}

public plugin_natives()
	set_native_filter("native_filter");
	
public native_filter(const native_name[], index, trap) 
	return PLUGIN_HANDLED;

public plugin_cfg() 
{
	ch_pCVar_enabled = get_pcvar_num(pCVar_enabled);
	ch_pCVar_minDamage = get_pcvar_num(pCVar_minDamage);
}

public client_putinserver(iPlayer)
{
	g_bOnline[iPlayer] = true;
	
	for(new p = 1; p <= g_iMaxPlayers; p++)
		g_iDamage[iPlayer][p] = 0;
}

public client_disconnected(iPlayer)
{
	g_iTeam[iPlayer] = TEAM_NONE;
	g_bAlive[iPlayer] = false;
	g_bOnline[iPlayer] = false;
}

public player_joinTeam()
{
	new iPlayer, szTeam[2];

	iPlayer = read_data(1);
	read_data(2, szTeam, 1);

	switch(szTeam[0])
	{
		case 'T': g_iTeam[iPlayer] = TEAM_TE;
		case 'C': g_iTeam[iPlayer] = TEAM_CT;
		default: g_iTeam[iPlayer] = TEAM_SPEC;
	}
	return PLUGIN_CONTINUE;
}

public player_spawn(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return HAM_IGNORED;

	g_bAlive[iPlayer] = true;

	for(new p = 1; p <= g_iMaxPlayers; p++)
		g_iDamage[iPlayer][p] = 0;

	return HAM_IGNORED;
}

public player_damage(iVictim)
{
	if(!ch_pCVar_enabled || !is_player(iVictim))
		return PLUGIN_CONTINUE;

	new iAttacker = get_user_attacker(iVictim);
	
	if(!is_player(iAttacker))
		return PLUGIN_CONTINUE;

	g_iDamage[iAttacker][iVictim] += read_data(2);
	
	return PLUGIN_CONTINUE;
}

public player_die()
{
	if(!ch_pCVar_enabled)
		return PLUGIN_CONTINUE;
	
	new iVictim = read_data(2);
	new iKiller = read_data(1);
	
	g_bAlive[iVictim] = false;
	
	new iKillerTeam = g_iTeam[iKiller];
	
	if(iKiller != iVictim && g_iTeam[iVictim] != iKillerTeam)
	{
		new iKiller2 = 0;
		new iDamage2 = 0;

		for(new p = 1; p <= g_iMaxPlayers; p++)
		{
			if(p != iKiller && g_bOnline[p] && iKillerTeam == g_iTeam[p] && g_iDamage[p][iVictim] >= ch_pCVar_minDamage && g_iDamage[p][iVictim] > iDamage2)
			{
				iKiller2 = p;
				iDamage2 = g_iDamage[p][iVictim];
			}
			g_iDamage[p][iVictim] = 0;
		}

		if(iKiller2 > 0 && iDamage2 > ch_pCVar_minDamage)
		{
			new iFrags = get_user_frags(iKiller2) + 1;

			set_user_frags(iKiller2, iFrags);

			cs_set_user_deaths(iKiller2, cs_get_user_deaths(iKiller2));

			new iMoney = cs_get_user_money(iKiller2) + 300;

			if(iMoney > 16000)
				iMoney = 16000;

			cs_set_user_money(iKiller2, iMoney);

			if(g_bAlive[iKiller2])
			{
				message_begin(MSG_ONE_UNRELIABLE, msgID_money, _, iKiller2);
				write_long(iMoney);
				write_byte(1);
				message_end();
			}
			
			new szName1[32], szName2[32], szName3[32], szMsg[128];

			get_user_name(iKiller, szName1, 31);
			get_user_name(iKiller2, szName2, 31);
			get_user_name(iVictim, szName3, 31);

			//formatex(szMsg, 63, "%s pomogl %s w  zabiciu %s", szName2, szName1, szName3);
			//set_hudmessage(HUD_colorR, HUD_colorG, HUD_colorB, HUD_posX, HUD_posY, HUD_fx, HUD_fxTime, HUD_holdTime, HUD_fadeInTime, HUD_fadeOutTime, HUD_channel);
			//show_hudmessage(0, szMsg);
			
			client_print_color(iKiller2, iKiller2, "^x03[ASYSTA]^x01 Pomogles^x04 %s^x01 w zabiciu^x04 %s^x01. Dostajesz fraga!", szName1, szName3);
			
			stats_add_kill(iKiller2);
			//top_stats_add_kill(iKiller2);
			//bf1_add_assist_kill(iKiller2);
		}
	}
	return PLUGIN_CONTINUE;
}