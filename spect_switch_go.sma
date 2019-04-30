#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Spectator Switcher"
#define VERSION "2.1"
#define AUTHOR "O'Zone"

#define Set(%2,%1)	(%1 |= (1<<(%2&31)))
#define Rem(%2,%1)	(%1 &= ~(1 <<(%2&31)))
#define Get(%2,%1)	(%1 & (1<<(%2&31)))

#define DEAD_FLAG   (1<<0)

#define TASK_SPECT	48598

new const szCommandSpect[][] = { "say /spect", "say_team /spect", "say /wroc", "say_team /wroc", "say /s", "say_team /s", "amx_spect" };

new iSpectator, iSpawned, iNextRound, iDefuse, iTime;

new CsTeams:iTeam[33], CsTeams:iOldTeam[33];

new iDeaths[33], iFrags[33], iHealth[33], iArmor[33], iWeapon[33][32], 
iNum[33], iWeapons[33], iWeaponAmmo[33][32], iWeaponBPAmmo[33][32];

new bool:bRoundEnd;

new gmsgScoreAttrib, gmsgTeamInfo;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCommandSpect; i++) register_clcmd(szCommandSpect[i], "CmdSpect");
	
	register_message(gmsgScoreAttrib, "msg_ScoreAttrib");
	register_message(gmsgTeamInfo, "msg_TeamInfo");

	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	
	register_logevent("RoundEnd", 2, "1=Round_End");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
}

public plugin_natives()
	register_native("is_user_spect", "is_user_spect", 1);

public is_user_spect(id)
	return Get(id, iSpectator);
	
public client_disconnected(id)
{
	Rem(id, iSpectator);
	
	remove_task(id + TASK_SPECT);
}

public client_connect(id)
	Rem(id, iSpectator);
	
public client_command(id)
{
	if(!Get(id, iSpectator)) return PLUGIN_CONTINUE;

	new szCommand[12];
	
	read_argv(0, szCommand, charsmax(szCommand));
	
	if(equal(szCommand, "jointeam", 8) || equal(szCommand, "chooseteam", 10)) return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
	
public CmdSpect(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN)) return PLUGIN_CONTINUE;
		
	if(Get(id, iSpectator))
	{
		if(cs_get_user_team(id) != CS_TEAM_SPECTATOR) return PLUGIN_CONTINUE;

		client_print_color(id, print_team_red, "^x03[SPECT]^x01 Wrociles do gry.");
		
		cs_set_user_team(id, iOldTeam[id]);
	
		switch(iOldTeam[id])
		{
			case CS_TEAM_T: SendTeamInfo(id, "TERRORIST");
			case CS_TEAM_CT: SendTeamInfo(id, "CT");
		}
	
		if(Get(id, iSpawned) || (Get(id, iNextRound) && iTime + 30.0 >= get_gametime()))
		{
			ExecuteHamB(Ham_CS_RoundRespawn, id);
			
			set_task(0.1, "Spawn", id);
		}
		else SendScoreAttrib(id, DEAD_FLAG);
		
		remove_task(id + TASK_SPECT);
	
		Rem(id, iSpectator);
	}
	else
	{
		if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) return PLUGIN_CONTINUE;

		client_print_color(id, print_team_red, "^x03[SPECT]^x01 Zostales ukrytym obserwatorem.");
		
		Set(id, iSpectator);
		Rem(id, iNextRound);
		Rem(id, iSpawned);
	
		iDeaths[id] = cs_get_user_deaths(id);
		iFrags[id] = get_user_frags(id);
		iOldTeam[id] = cs_get_user_team(id);
	
		if(is_user_alive(id))
		{
			Set(id, iSpawned);
			
			iHealth[id] = get_user_health(id);
			iArmor[id] = get_user_armor(id);
			iWeapons[id] = get_user_weapons(id, iWeapon[id], iNum[id]);
		
			for(new i = 1; i < iNum[id]; i++)
			{
				new szWeaponName[32];
				
				get_weaponname(iWeapon[id][i], szWeaponName, charsmax(szWeaponName));
			
				if(equal(szWeaponName, "weapon_knife")) continue;
				
				if(equal(szWeaponName, "weapon_c4"))
				{
					new szPlayers[MAX_PLAYERS], iNum, iPlayer;
					
					get_players(szPlayers, iNum, "e", "TERRORIST");
	
					for(new i = 0; i < iNum; i++)
					{
						iPlayer = szPlayers[i];
			
						if(!is_user_alive(iPlayer) || id == iPlayer) continue;

						give_item(iPlayer, "weapon_c4");
						
						cs_set_user_plant(iPlayer, 1);
					
						break;
					}
				}
				
				new iWeaponID = find_ent_by_owner(-1, szWeaponName, id);
				
				if(!iWeaponID)	continue;
				
				iWeaponAmmo[id][i] = cs_get_weapon_ammo(iWeaponID);
				iWeaponBPAmmo[id][i] = cs_get_user_bpammo(id, iWeapon[id][i]);
			}
			
			if(cs_get_user_defuse(id)) Set(id, iDefuse);
			
			static gmsgClCorpse;
	
			if(!gmsgClCorpse) gmsgClCorpse = get_user_msgid("ClCorpse");
		
			set_msg_block(gmsgClCorpse, BLOCK_ONCE);
		
			strip_user_weapons(id);
		
			user_silentkill(id);
		
			set_task(0.1, "Stats", id);
		}

		cs_set_user_team(id, CS_TEAM_SPECTATOR);

		SetTeam(id);
	
		SendFlags(0, true);
	
		set_task(1.0, "UpdateInfo", id + TASK_SPECT, _, _, "b");
	}

	return PLUGIN_HANDLED;
}

public PlayerSpawn(id)
{
	if(Get(id, iSpectator))
	{
		static gmsgClCorpse;
	
		if(!gmsgClCorpse) gmsgClCorpse = get_user_msgid("ClCorpse");
		
		set_msg_block(gmsgClCorpse, BLOCK_ONCE);
		
		strip_user_weapons(id);
		
		user_silentkill(id);

		cs_set_user_team(id, CS_TEAM_SPECTATOR);

		SetTeam(id);
	
		SendFlags(0, true);
	}
}

public Stats(id)
{
	set_user_frags(id, iFrags[id]);
	cs_set_user_deaths(id, iDeaths[id]);
}

public UpdateInfo(id)
{
	id -= TASK_SPECT;
	
	SetTeam(id);
	
	if(!bRoundEnd) SendFlags(0, true);
}

public SetTeam(id)
{
	if(Get(id, iSpectator))
	{
		new szPlayers[MAX_PLAYERS], iTT, iCT;
		
		get_players(szPlayers, iTT, "e", "TERRORIST");
		get_players(szPlayers, iCT, "e", "CT");
		
		iTeam[id] = iTT > iCT ? CS_TEAM_CT : CS_TEAM_T;

		switch(iTeam[id])
		{
			case CS_TEAM_T: SendTeamInfo(id, "TERRORIST");
			case CS_TEAM_CT: SendTeamInfo(id, "CT");
		}
	}
}

public Spawn(id)
{
	strip_user_weapons(id);
	
	give_item(id, "weapon_knife");
	
	for (new i = 1; i < iNum[id]; i++)
	{
		new szWeaponName[32];
		
		get_weaponname(iWeapon[id][i], szWeaponName, charsmax(szWeaponName));

		if(equal(szWeaponName, "weapon_knife") || equal(szWeaponName, "weapon_c4")) continue;

		give_item(id, szWeaponName);

		new iWeaponID = find_ent_by_owner(-1, szWeaponName, id);
		
		if(!iWeaponID)	continue;

		cs_set_weapon_ammo(iWeaponID, iWeaponAmmo[id][i]);
		cs_set_user_bpammo(id, iWeapon[id][i], iWeaponBPAmmo[id][i]);
	}
	
	if(Get(id, iDefuse) && get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	
	if(!Get(id, iNextRound))
	{
		set_user_armor(id, iArmor[id]);
		set_user_health(id, iHealth[id]);
	}
}

public DeathMsg()
	if(!bRoundEnd) SendFlags(DEAD_FLAG, true);

public NewRound()
{
	iTime = floatround(get_gametime());
	
	bRoundEnd = false;
	
	SendFlags();
	
	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
		Set(i, iNextRound);
		Rem(i, iSpawned);
	}
}

public RoundEnd()
{
	bRoundEnd = true;
	
	SendFlags(DEAD_FLAG);
}

public msg_ScoreAttrib(msg_type, msg_dest, target)
{
	if(!Get(get_msg_arg_int(1), iSpectator)) return;
	
	static flags;
	
	flags = get_msg_arg_int(2);
	
	if(flags & DEAD_FLAG) set_msg_arg_int(2, 0, flags & ~DEAD_FLAG)
	
	return; 
}

public msg_TeamInfo(msg_type, msg_dest, target)
{
	static id;
	
	id = get_msg_arg_int(1);
	
	if(!Get(id, iSpectator)) return;
	
	new szTeam[12];
	
	get_msg_arg_string(2, szTeam, charsmax(szTeam));
	
	if(iTeam[id] == CS_TEAM_T && strcmp(szTeam, "TERRORIST") != 0) set_msg_arg_string(2, "TERRORIST");
	if(iTeam[id] == CS_TEAM_CT && strcmp(szTeam, "CT") != 0) set_msg_arg_string(2, "CT");
	
	return;
}

SendFlags(iFlags = 0, bCheck = false)
{
	new szPlayers[MAX_PLAYERS], iPlayer, iPlayers;
	
	if(bCheck)
	{
		new iDead, Float:fPercent = 0.4;
		
		get_players(szPlayers, iDead, "bh");
		get_players(szPlayers, iPlayers, "h");
	
		if(float(iDead) / float(iPlayers) < fPercent) return;

		iFlags = DEAD_FLAG;
	}
	else get_players(szPlayers, iPlayers, "h");
	
	for(new i; i < iPlayers; i++)
	{
		iPlayer = szPlayers[i];
		
		if(Get(iPlayer, iSpectator)) SendScoreAttrib(iPlayer, iFlags);
	}
}

SendScoreAttrib(id, iFlags)
{
	static gmsgScoreAttrib;
	
	if(!gmsgScoreAttrib) gmsgScoreAttrib = get_user_msgid("ScoreAttrib");

	message_begin(MSG_ALL, gmsgScoreAttrib, _, 0);
	
	write_byte(id);
	write_byte(iFlags);
	
	message_end();
}

SendTeamInfo(id, szTeam[])
{
	static gmsgTeamInfo;
	
	if(!gmsgTeamInfo) gmsgTeamInfo = get_user_msgid("TeamInfo");

	message_begin(MSG_ALL, gmsgTeamInfo, _, 0);
	
	write_byte(id);
	write_string(szTeam);
	
	message_end();
}