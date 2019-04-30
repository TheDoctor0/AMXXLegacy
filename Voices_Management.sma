// Required admin access level
#define ADMIN_VOICE	ADMIN_CHAT

// Comment this out if you don't want that a "no sound" player can hear admins using +adminvoice
// All other player settings are respected whatever this is commented or not.
#define SUPER_ADMIN_PRIORITY

/* ** END OF EDITABLE ** */

/*    Changelog
*
* v1.0.2 (04/19/08)
* -few code corrections
* -updated player spawn detection
* -added HLTV & BOT checks
*
* v1.0.1 (03/31/08)
* -added colored chat
* -added chat command /vm that display voices settings
* -inform new players about /vm command
* -display adminlisten status when toggle_adminlisten command is used
* -added support for amx_show_activity cvar on amx_(un)mute command
*
* v1.0.0 (03/26/08)
* First release
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define VERSION "1.0.2"

#define MAX_PLAYERS	32

#define OFFSET_TEAM		114

new g_iClientSettings[MAX_PLAYERS+1][2]
new bool:g_bPlayerNonSpawnEvent[MAX_PLAYERS+1]
new g_iFwFmClientCommandPost
new bool:g_bAlive[MAX_PLAYERS+1]

new g_iAdminVoice
new bool:g_bAdmin[MAX_PLAYERS+1]
new bool:g_bInterAdminVoice[MAX_PLAYERS+1]
new bool:g_bAdminListen[MAX_PLAYERS+1]

new bool:g_bMuted[MAX_PLAYERS+1]
new g_szClientsIp[MAX_PLAYERS+1][22]
new Array:g_aMutedPlayersIps

new g_iMaxPlayers
new g_msgidSayText
new g_pcvarAlivesHear, g_pcvarDeadsHear
new g_amx_show_activity

public plugin_init()
{
	register_plugin("Voices Management", VERSION, "ConnorMcLeod")
	register_dictionary("voicesmanagement.txt")
	register_dictionary("common.txt")

	g_pcvarAlivesHear = register_cvar("vm_alives", "1")  // 0:alive teamates , 1:alives , 2:all
	g_pcvarDeadsHear = register_cvar("vm_deads", "2")	// 0:dead teamates , 1:deads , 2:all

	register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening")
	register_event("VoiceMask", "Event_VoiceMask", "b")

	register_event("TextMsg", "Event_TextMsg_Restart", "a", "2=#Game_will_restart_in")
	register_event("ResetHUD", "Event_ResetHUD", "b")
	register_event("DeathMsg", "Event_DeathMsg", "a")

	register_clcmd("+adminvoice", "AdminCommand_VoiceOn")
	register_clcmd("-adminvoice", "AdminCommand_VoiceOff")

	register_clcmd("+interadminvoice", "AdminCommand_InterAdminOn")
	register_clcmd("-interadminvoice", "AdminCommand_InterAdminOff")

	register_clcmd("+adminlisten", "AdminCommand_ListenOn")
	register_clcmd("-adminlisten", "AdminCommand_ListenOff")
	register_clcmd("toggle_adminlisten", "AdminCommand_ListenToggle")

	register_concmd("amx_mute", "AdminCommand_Mute", ADMIN_VOICE, "<name/#userid>")
	register_concmd("amx_unmute", "AdminCommand_UnMute", ADMIN_VOICE, "<name/#userid>")

	register_clcmd("say /vm", "ClientCommand_SayStatus")
	register_clcmd("say_team /vm", "ClientCommand_SayStatus")

	register_clcmd("fullupdate", "ClientCommand_fullupdate")
}

public plugin_cfg()
{
	server_cmd("sv_alltalk 1;alias sv_alltalk")
	server_exec()
	g_iMaxPlayers = get_maxplayers()
	g_aMutedPlayersIps = ArrayCreate(22)
	g_msgidSayText = get_user_msgid("SayText")
	g_amx_show_activity = get_cvar_pointer("amx_show_activity")
}

public ClientCommand_SayStatus(id)
{
	new iDeads = get_pcvar_num(g_pcvarDeadsHear), 
		iAlives = get_pcvar_num(g_pcvarAlivesHear)

	new szDeadsStatus[18], szAlivesStatus[19]

	switch( iAlives )
	{
		case 0:szAlivesStatus = "VM_ALIVES_TEAMATES"
		case 1:szAlivesStatus = "VM_ALIVES"
		case 2:szAlivesStatus = "VM_ALL"
	}

	switch( iDeads )
	{
		case 0:szDeadsStatus = "VM_DEADS_TEAMATES"
		case 1:szDeadsStatus = "VM_DEADS"
		case 2:szDeadsStatus = "VM_ALL"
	}

	col_mess(id, id, "%L", id, "VM_ALIVES_STATUS", id, szAlivesStatus)
	col_mess(id, id, "%L", id, "VM_DEADS_STATUS", id, szDeadsStatus)
}

public ClientCommand_fullupdate(id)
{
	g_bPlayerNonSpawnEvent[id] = true
	static const szFwFmClientCommandPost[] = "fwFmClientCommandPost"
	g_iFwFmClientCommandPost = register_forward(FM_ClientCommand, szFwFmClientCommandPost, 1)
	return PLUGIN_CONTINUE
}

public fwFmClientCommandPost(iPlayerId) {
	unregister_forward(FM_ClientCommand, g_iFwFmClientCommandPost, 1)
	g_bPlayerNonSpawnEvent[iPlayerId] = false
	return FMRES_HANDLED
}

public Event_TextMsg_Restart()
{
	for(new id=1; id <= g_iMaxPlayers; ++id)
	{
		if(g_bAlive[id])
		{
			g_bPlayerNonSpawnEvent[id] = true
		}
	}
}

public Event_ResetHUD(id)
{
	if( !is_user_alive(id) )
	{
		return
	}

	if(g_bPlayerNonSpawnEvent[id])
	{
		g_bPlayerNonSpawnEvent[id] = false
		return
	}
	g_bAlive[id] = true
}

public client_authorized(id)
{
	g_bAdmin[id] = bool:(get_user_flags(id) & ADMIN_VOICE)
}

public client_putinserver(id)
{
	g_bAlive[id] = false
	g_bAdminListen[id] = false
	g_bInterAdminVoice[id] = false

	if(is_user_bot(id) || is_user_hltv(id))
		return

	static szIp[22]
	get_user_ip(id, szIp, 21)
	g_szClientsIp[id] = szIp

	static szTempIp[22], iArraySize
	iArraySize = ArraySize(g_aMutedPlayersIps)
	for(new i; i<iArraySize; i++)
	{
		ArrayGetString(g_aMutedPlayersIps, i, szTempIp, 21)
		if( equal(szIp, szTempIp) )
		{
			ArrayDeleteItem(g_aMutedPlayersIps, i)
			g_bMuted[id] = true
			break
		}
	}
}

public client_disconnect(id)
{
	if(g_iAdminVoice == id)
	{
		g_iAdminVoice = 0
	}
	if(g_bMuted[id])
	{
		ArrayPushString(g_aMutedPlayersIps, g_szClientsIp[id])
		g_bMuted[id] = false
	}
}

public Event_DeathMsg()
{
	g_bAlive[read_data(2)] = false
}

public Event_VoiceMask(id)
{
	g_iClientSettings[id][0] = read_data(1)
	g_iClientSettings[id][1] = read_data(2)
}

public Forward_SetClientListening(iReceiver, iSender, bool:bListen)
{
#if defined SUPER_ADMIN_PRIORITY
	if(g_iAdminVoice)
	{
		if(g_iAdminVoice == iSender)
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if( !g_iClientSettings[iReceiver][0] || g_iClientSettings[iReceiver][1] & (1<<(iSender-1)) )
	{
		return FMRES_IGNORED
	}
#else
	if( !g_iClientSettings[iReceiver][0] || g_iClientSettings[iReceiver][1] & (1<<(iSender-1)) )
	{
		return FMRES_IGNORED
	}

	if(g_iAdminVoice)
	{
		if(g_iAdminVoice == iSender)
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}
#endif
	if(g_bMuted[iSender])
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if(g_bInterAdminVoice[iSender])
	{
		if(g_bAdmin[iReceiver]) 
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
			forward_return(FMV_CELL, true)
			return FMRES_SUPERCEDE
		}
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
		forward_return(FMV_CELL, false)
		return FMRES_SUPERCEDE
	}

	if(g_bAdminListen[iReceiver])
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
		forward_return(FMV_CELL, true)
		return FMRES_SUPERCEDE
	}

	if(g_bAlive[iReceiver])
	{
		switch(get_pcvar_num(g_pcvarAlivesHear))
		{
			case 0:
			{
				if( g_bAlive[iSender] && get_pdata_int(iReceiver, OFFSET_TEAM) == get_pdata_int(iSender, OFFSET_TEAM) )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 1:
			{
				if( g_bAlive[iSender] )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 2:
			{
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
				forward_return(FMV_CELL, true)
				return FMRES_SUPERCEDE
			}
		}
	}
	else
	{
		switch(get_pcvar_num(g_pcvarDeadsHear))
		{
			case 0:
			{
				if( !g_bAlive[iSender] && get_pdata_int(iReceiver, OFFSET_TEAM) == get_pdata_int(iSender, OFFSET_TEAM) )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 1:
			{
				if( !g_bAlive[iSender] )
				{
					engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
					forward_return(FMV_CELL, true)
					return FMRES_SUPERCEDE
				}
			}
			case 2:
			{
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true)
				forward_return(FMV_CELL, true)
				return FMRES_SUPERCEDE
			}
		}
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
	forward_return(FMV_CELL, false)
	return FMRES_SUPERCEDE
}

public AdminCommand_ListenOn(id)
{
	if( !g_bAdmin[id] )
		return PLUGIN_HANDLED

	g_bAdminListen[id] = true

	return PLUGIN_HANDLED
}

public AdminCommand_ListenOff(id)
{
	if( g_bAdminListen[id] )
	{
		g_bAdminListen[id] = false
	}

	return PLUGIN_HANDLED
}

public AdminCommand_ListenToggle(id)
{
	if( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	g_bAdminListen[id] = !g_bAdminListen[id]

	col_mess(id, id, "%L", id, "VM_LISTEN_STATUS", g_bAdminListen[id] ? "ON" : "OFF")

	return PLUGIN_HANDLED
}

public AdminCommand_VoiceOn(id)
{
	if(!g_bAdmin[id])
	{
		return PLUGIN_HANDLED
	}

	if(g_iAdminVoice)
	{
		col_mess(id, id, "%L", id, "VM_ALREADY_INUSE")
		return PLUGIN_HANDLED
	}

	g_iAdminVoice = id

	new name[32]
	pev(id, pev_netname, name, 31)

	for(new player = 1; player <= g_iMaxPlayers; player++)
	{
		if( is_user_connected(player) && !is_user_hltv(player) && !is_user_bot(player) )
		{
			col_mess(player, id, "%L", player, "VM_ADMIN_TALK", name)
		}
	}

	client_cmd(id, "+voicerecord")

	return PLUGIN_HANDLED
}

public AdminCommand_VoiceOff(id)
{
	if( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	if(g_iAdminVoice != id)
	{
		client_cmd(id, "-voicerecord")
		return PLUGIN_HANDLED
	}

	client_cmd(id, "-voicerecord")
	g_iAdminVoice = 0
	return PLUGIN_HANDLED
}

public AdminCommand_InterAdminOn(id)
{
	if( !g_bAdmin[id] )
	{
		return PLUGIN_HANDLED
	}

	g_bInterAdminVoice[id] = true
	client_cmd(id, "+voicerecord")

	new name[32]
	get_user_name(id, name, 31)
	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if( !g_bAdmin[i] || !is_user_connected(i) )
		{
			continue
		}
		col_mess(i, id, "%L", i, "VM_INTER_START", name)
	}

	return PLUGIN_HANDLED
}

public AdminCommand_InterAdminOff(id)
{
	if(!g_bInterAdminVoice[id])
		return PLUGIN_HANDLED

	g_bInterAdminVoice[id] = false
	client_cmd(id, "-voicerecord")

	new name[32]
	get_user_name(id, name, 31)
	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if( !g_bAdmin[i] || !is_user_connected(i) )
		{
			continue
		}
		col_mess(i, id, "%L", i, "VM_INTER_STOP", name)
	}

	return PLUGIN_HANDLED
}

public AdminCommand_Mute(id, level, cid)
{
	if( !cmd_access(id, level, cid, 2, true) )
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[32]
	read_argv(1, szPlayer, 31)
	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS)

	if( !iPlayer )
	{
		return PLUGIN_HANDLED
	}

	if( g_bAdmin[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_MUTE_ADMIN")
		return PLUGIN_HANDLED
	}

	if( g_bMuted[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_AR_MUTED")
		return PLUGIN_HANDLED
	}

	g_bMuted[iPlayer] = true
	client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_MUTED")

	if(g_amx_show_activity)
	{
		new name[32], name2[32]
		get_user_name(id, name, 31)
		get_user_name(iPlayer, name2, 31)
		show_activity_col(id, name, name2, "VM_MUTE_ACTIVITY")
	}
	return PLUGIN_HANDLED
}

public AdminCommand_UnMute(id, level, cid)
{
	if( !cmd_access(id, level, cid, 2, true) )
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[32], iPlayer
	read_argv(1, szPlayer, 31)
	iPlayer = cmd_target(id, szPlayer, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS)

	if( !iPlayer )
	{
		return PLUGIN_HANDLED
	}

	if( !g_bMuted[iPlayer] )
	{
		client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_NOT_MUTED")
		return PLUGIN_HANDLED
	}

	g_bMuted[iPlayer] = false
	client_print(id, print_console, "%L", id ? id : LANG_SERVER, "VM_UNMUTED")

	if(g_amx_show_activity)
	{
		new name[32], name2[32]
		get_user_name(id, name, 31)
		get_user_name(iPlayer, name2, 31)

		show_activity_col(id, name, name2, "VM_UNMUTE_ACTIVITY")
	}

	return PLUGIN_HANDLED
}

col_mess(id, sender, string[], any:...)
{
	static szMessage[128]
	szMessage[0] = 0x01
	vformat(szMessage[1], 127, string, 4)

	replace_all(szMessage, 127, "!n", "^x01")
	replace_all(szMessage, 127, "!t", "^x03")
	replace_all(szMessage, 127, "!g", "^x04")

	message_begin(MSG_ONE_UNRELIABLE, g_msgidSayText, _, id)
	write_byte(sender)
	write_string(szMessage)
	message_end()
}

show_activity_col(id, name[], name2[], ML_KEY[])
{
	switch(get_pcvar_num(g_amx_show_activity))
	{
		case 5: // hide name only to admins, show nothing to normal users
		{		
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[VM] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
					}
				}
			}
		}
		case 4: // show name only to admins, show nothing to normal users
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[VM] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
					}
				}
			}
		}
		case 3: // show name only to admins, hide name from normal users
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					if (is_user_admin(i))
					{
						col_mess(i, id, " ** !g[VM] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
					}
					else
					{
						col_mess(i, id, " ** !g[VM] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
					}
				}
			}
		}
		case 2: // show name to all
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					col_mess(i, id, " ** !g[VM] !n%L !t%s!n: %L", i, "ADMIN", name, i, ML_KEY, name2)
				}
			}
		}
		case 1: // hide name to all
		{
			for (new i=1; i<=g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
				{
					col_mess(i, id, " ** !g[VM] !n%L: %L", i, "ADMIN", i, ML_KEY, name2)
				}
			}
		}
	}
}