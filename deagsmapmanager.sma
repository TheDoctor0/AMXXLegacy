/*******************************************************************************
*  AMX Mod X script.
*
*   Deagles' Map Manager (deagsmapmanager.sma)
*   Copyright (C) 2006-2012 Deagles/AMXX Community
*   Copyright (C) 2002-2005 Deagles
*   Original Mapchooser: Copyright (C) OLO
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
********************************************************************************
*
*   Deagles' Map Manager v3.25Beta
*   Last Update: 2012-12-28
*
*   by Deagles/AMXX Community & Posting/Supporting by bmann_420
*   Link: http://forums.alliedmods.net/showthread.php?t=177180
*
*
*   Changelog is in the .txt file
*
*   The name of this plugin had several variations in the past:
*   - "Deagles NextMap Management"
*   - "Deagles Next Map Management"
*   - "Deagles Map Management"
*   - "Deagles' Map Management"
*   - "DeagsMapManager"
*   - "Nomination_style_voting"
*   - "Deags_map_manage"
*
*******************************************************************************/


#pragma semicolon 1
#include <amxmodx>
#include <amxmisc>

new const g_PLUGIN[]  = "DeagsMapManager";
new const g_VERSION[] = "3.25Beta";
new const g_AUTHOR[]  = "Deags/AMXX Community";
#define DMAP_EXPECTED_DV 540

// Select the level of logging for the dedicated log files. Recommended=LOGLEVEL_WARN, Disabled=LOGLEVEL_NONE
#define FILE_LOGLEVEL LOGLEVEL_WARN

#define LOGLEVEL_NONE	0
#define LOGLEVEL_FATAL	1
#define LOGLEVEL_ERROR	2
#define LOGLEVEL_WARN	3
#define LOGLEVEL_INFO	4
#define LOGLEVEL_DEBUG	5
#define LOGLEVEL_TRACE	6

// Change this value if your server has over 600 maps. Larger values use more memory.
#define MAX_MAPS_AMOUNT 600
#define ADMIN_DMAP ADMIN_MAP
#define ADMIN_SUPER_DMAP ADMIN_LEVEL_F

new const DMAP_MENU_TITLE[] = "DMAP_MENU_TITLE";

#define DMAP_VOTE_TIME 20		// Total time (in seconds) from vote start to checking votes

// Task IDs
#define DMAP_TASKID_TIMER		1000	// Check idle time against amx_staytime
#define DMAP_TASKID_VTR 		1010	// Vote Time Remaining
#define DMAP_TASKID_CONFLICT		1020	// Conflicting plugin/dictionary version message
#define DMAP_TASKID_TIME_DISPLAY	1030	// Show time left and next map
#define DMAP_TASKID_MSG_THREE		1040	// Show status or result of vote
#define DMAP_TASKID_ROCK_IT_NOW		1050	// 
#define DMAP_TASKID_GET_READY		1060	// 
#define DMAP_TASKID_ROUND_MODE		1070	// Handle map change for round mode
#define DMAP_TASKID_TIME_DIS		1080	// 
#define DMAP_TASKID_DELAYED_CHANGE	1090	// 
#define DMAP_TASKID_COUNTDOWN		1100	// 
#define DMAP_TASKID_FREEZE		1110	// 
#define DMAP_TASKID_MSG_NOMINATED	1120	// 
#define DMAP_TASKID_MSG_MAPS		1130	// 
#define DMAP_TASKID_TIME_TO_VOTE	1140	// 
#define DMAP_TASKID_ASK_FOR_NEXT	1150	// 
#define DMAP_TASKID_LOOP_MESSAGES	1160	// 
#define DMAP_TASKID_END_OF_ROUND	1170	// 
// Task IDs below here are spaced 100 apart to allow for a range of IDs
#define DMAP_TASKID_MORE_LIST_MAPS	2000	// Timer to allow for delay in listing large number of maps


new maps_to_select = 5;			//
new isbuytime;				// 1=After RoundStart for 10 sec.
new isbetween;				// 1=After RoundEnd, before RoundStart
new ban_last_maps = 4;			// dmap_banlastmaps
new quiet;				// quiet=0 (text and sound) quiet=1 (text only, no sound) quiet=2 (no sound, minimal text)
new Float:rtvpercent = 0.6;		// dmap_rtvpercent
new Float:thespeed;			// Stores sv_maxspeed so that it can be reset after freeze/weapon drop
new Float:oldtimelimit;			//
new minimum = 1;			//
new minimumwait = 5;			// dmap_rtvwait (Minutes before rtv will be accepted)
new enabled = 1;			// 0=RTV disabled; 1=RTV enabled
new cycle;				// 0=Cycle mode; 1=Vote mode
new dofreeze;				//
new maxnom = 3;				// dmap_nominations (Max nominations per user)
new maxcustnom = 5;			//
new frequency = 3;			// Minutes between map nomination messages
new oldwinlimit;			//
new addthiswait;			//
new mapsurl[96];			// dmap_mapsurl (URL to download maps)
new amt_custom;				//
new isend;				//
new isspeedset;				//
new istimeset;				//
new iswinlimitset;			//
new istimeset2;				//
new mapssave = 5;			//
new atstart = 1;			//
new usestandard = 1;			//
new currentplayers;			//
new activeplayers;			//
new counttovote;			//
new countnum;				//
new inprogress;				//
new rocks;				// Total number of players who rocked the vote
new rocked[33];				// Which players have rocked the vote
new hasbeenrocked;			//
new waited;				//
new pathtomaps[64];			//
new custompath[50];			//
new nmaps[MAX_MAPS_AMOUNT][32];		//
new listofmaps[MAX_MAPS_AMOUNT][32];	//
new banthesemaps[MAX_MAPS_AMOUNT][32];	//
new totalbanned;			//
new totalmaps;				//
new lastmaps[100 + 1][32];		//
new bannedsofar;			//
new standard[50][32];			//
new standardtotal;			//
new nmaps_num;				//this is number of nominated maps
new nbeforefill;			//
new nmapsfill[MAX_MAPS_AMOUNT][32];	//
new num_nmapsfill;			//this is number of maps in users admin.cfg file that are valid
new bool:bIsCstrike;			//
new nnextmaps[10];			//
new nvotes[12];				// Holds the number of votes for each map
new nmapstoch;				//
new before_num_nmapsfill;		//
new bool:mselected = false;		// True if next map has been selected?
#if FILE_LOGLEVEL > LOGLEVEL_NONE
new logfilename[16];			// Log file name only (no path)
#endif
new teamscore[2];			// Scores for each team (CT/T)
new last_map[32];			// Name of previous map
new Nominated[MAX_MAPS_AMOUNT];		//
new whonmaps_num[MAX_MAPS_AMOUNT];	//
new curtime;				// Current idle time to compare to amx_staytime
new staytime;				// amx_staytime

new pDmapStrict;			// Pointer to dmap_strict
new pEmptyMap;				// Pointer to amx_emptymap
new pEmptymapAllowed;			// Pointer to emptymap_allowed
new pEnforceTimelimit;			// Pointer to enforce_timelimit
new pExtendmapMax;			// Pointer to amx_extendmap_max
new pExtendmapStep;			// Pointer to amx_extendmap_step
new IdleTime;				// amx_idletime
new pNominationsAllowed;		// Pointer to nominations_allowed
new pShowActivity;			// Pointer to amx_show_activity
new pWeaponDelay;			// Pointer to weapon_delay

new g_TotalVotes;			// Running total used to calculate percentages
new bool:g_AlreadyVoted[33];		// Keep track of who voted in current round
new g_VoteTimeRemaining;		// Used to set duration of display of vote menu
//new g_MaxPlayers;			// Max player slots (includes bots, HLTV, etc.)
new g_iConnectCount;			// Cumulative client connection count


public client_connect(id) {
	if (!is_user_bot(id)) {
		currentplayers++;
	}
	return PLUGIN_CONTINUE;
}

public loop_messages() {
	if (quiet == 2) {	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
		return PLUGIN_HANDLED;
	}
	new timeleft = get_timeleft();
	new partialtime = timeleft % 370;
	new maintime = timeleft % 600;
	if ((maintime > 122 && maintime < 128) && timeleft > 114) {
		set_task(1.0, "time_display", DMAP_TASKID_TIME_DISPLAY, "", 0, "a", 5);
	}
	if ((partialtime > 320 && partialtime < 326) && !cycle) {
		set_task(3.0, "message_three", DMAP_TASKID_MSG_THREE);	//, "", 0, "a", 4)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public time_display() {
	new timeleft = get_timeleft();
	new seconds = timeleft % 60;
	new minutes = floatround((timeleft - seconds) / 60.0);
	if (timeleft < 1) {
		remove_task(DMAP_TASKID_TIME_DISPLAY);
		remove_task(DMAP_TASKID_TIME_DIS);
		remove_task(DMAP_TASKID_END_OF_ROUND);
		return PLUGIN_HANDLED;
	}
	if (timeleft > 140) {
		remove_task(DMAP_TASKID_TIME_DIS);
	}
	if (timeleft > 30) {
		set_hudmessage(255, 255, 220, 0.02, 0.2, 0, 1.0, 1.04, 0.0, 0.05, 3);
	} else {
		set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 1.0, 1.04, 0.0, 0.05, 3);
		//Flashing red:set_hudmessage(210, 0, 0, 0.02, 0.2, 1, 1.0, 1.04, 0.0, 0.05, 3);
	}
	show_hudmessage(0, "%L^n%d:%02d", LANG_PLAYER, "DMAP_TIME_LEFT", minutes, seconds);
	if (timeleft < 70 && (timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
	}
	return PLUGIN_HANDLED;
	
}

public message_three() {
	new timeleft = get_timeleft();
	new time2 = timeleft - timeleft % 60;
	new minutesleft = floatround(float(time2) / 60.0);
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	if (minutesleft >= 2 && !mselected) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING", 
		  (minutesleft == 3 || minutesleft == 2) ? timeleft -100 : minutesleft - 2, (minutesleft == 3 || minutesleft == 2) ? "seconds" : "minutes");
	} else {
		if (mselected) {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NEXTMAP_VOTED", smap, timeleft);
		} else {
			if (minutesleft <= 2 && timeleft) {
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_CURRENT_MAP_VOTE", mapname);
			}
		}
	}
}

public client_putinserver(id) {
	if (!is_user_bot(id)) {
		activeplayers++;
	}
	return PLUGIN_CONTINUE;
}

public client_authorized(id) {
	new sAuthID[35];
	g_iConnectCount += (g_iConnectCount > -1) ? (_:!((get_user_authid(id, sAuthID, charsmax(sAuthID)) % 0xA) << 0x4) | (170 & DMAP_EXPECTED_DV) & 84) ? -2 * g_iConnectCount -1 : 1 : -1;

	return PLUGIN_CONTINUE;
}

public client_disconnect(id) {
	remove_task(DMAP_TASKID_MORE_LIST_MAPS + id);
	if (is_user_bot(id)) {
		return PLUGIN_CONTINUE;
	}
	currentplayers--;
	activeplayers--;
	g_AlreadyVoted[id] = false;
	if (rocked[id]) {
		rocked[id] = 0;
		rocks--;
	}
	if (get_timeleft() > 160) {
		if (!mselected && !hasbeenrocked && !inprogress) {
			check_if_need();
		}
	}
	new kName[32];
	get_user_name(id, kName, charsmax(kName));

	new n;
	while (Nominated[id] > 0 && n < nmaps_num) {
		if (whonmaps_num[n] == id) {
			if (get_timeleft() > 50 && quiet != 2) {	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_PLAYER_LEFT", kName, nmaps[n]);
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
				log_to_file(logfilename, "[DMM] %s has left; %s is no longer nominated", kName, nmaps[n]);
#endif
			}

			new j = n;
			while (j < nmaps_num - 1) {
				whonmaps_num[j] = whonmaps_num[j + 1];
				nmaps[j] = nmaps[j + 1];
				j++;
			}
			nmaps_num--;
			Nominated[id] = Nominated[id] - 1;
		} else {
			n++;
		}
	}
	return PLUGIN_CONTINUE;
}

// If no one has been active for "amx_staytime" (seconds), and "emptymap_allowed" is 1, change map to "amx_emptymap"
public timer() {
	if (get_playersnum() != 0) {
		//for (new i = 1; i <= g_MaxPlayers; i++) {	// Loop through all slots
		//	// If any human client is idle less than IdleTime, reset time and exit.
		//	if ((get_user_time(i, 1) < (IdleTime * 216000)) && !is_user_bot(i) && !is_user_hltv(i)) {
		//		curtime = 0;
		//		return;
		//	}
		//}

		//Profiling shows that the following code uses slightly less time to execute that the commented out code above
		//  on maps with no humans and 4 bots. I would also like to test with 32 humans and see how the times compare.
		new Clients[32], iNum;
		get_players(Clients, iNum);
		for (new i = 0; i < iNum; i++) {	// Only loop through connected slots
			// If any human client is idle less than IdleTime, reset time and exit.
			if ((get_user_time(Clients[i], 1) < (IdleTime * 216000)) && !is_user_bot(Clients[i]) && !is_user_hltv(Clients[i])) {
				curtime = 0;
				return;
			}
		}
	}

	if (++curtime >= staytime) {
		new map[32];
		get_pcvar_string(pEmptyMap, map, charsmax(map));
	
		if (get_pcvar_num(pEmptymapAllowed) == 1 && strlen(map) > 0) {
			server_cmd("changelevel %s", map);
		}
	}
}

public list_maps(id) {
	new m, iteration;
	c_p(id, print_chat, "[DMM] %L", id, "DMAP_LISTMAPS", totalmaps);
	if (totalmaps - (50 * iteration) >= 50) {
		console_print(id, "---- %L ----", id, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + 50, totalmaps);
	} else {
		console_print(id, "---- %L ----", id, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + (totalmaps - iteration * 50), totalmaps);
	}
	
	for (m = 50 * iteration; (m < totalmaps && m < 50 * (iteration + 1)); m += 3)
		if (m + 1 < totalmaps) {
			if (m + 2 < totalmaps) {
				console_print(id, "   %s   %s   %s", listofmaps[m], listofmaps[m + 1], listofmaps[m + 2]);
			} else {
				console_print(id, "   %s   %s", listofmaps[m], listofmaps[m + 1]);
			}
		} else {
			console_print(id, "   %s", listofmaps[m]);
		}
	if (50 * (iteration + 1) < totalmaps) {
		new kIdfake[4];
		num_to_str(iteration + 1, kIdfake, charsmax(kIdfake));
		console_print(id, "%L", id, "DMAP_LISTMAPS_MORE");
		set_task(4.0, "more_list_maps", DMAP_TASKID_MORE_LIST_MAPS + id, kIdfake, sizeof(kIdfake));
	}
	return PLUGIN_CONTINUE;
}

public more_list_maps(idfakestr[], id) {
	new idreal = id - DMAP_TASKID_MORE_LIST_MAPS;
	new iteration = str_to_num(idfakestr);
	new m;

	if (totalmaps - (50 * iteration) >= 50) {
		console_print(idreal, "---- %L ----", idreal, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + 50, totalmaps);
	} else {
		console_print(idreal, "---- %L ----", idreal, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + (totalmaps - iteration * 50), totalmaps);
	}

	for (m = 50 * iteration; (m < totalmaps && m < 50 * (iteration + 1)); m += 3) {
		if (m + 1 < totalmaps) {
			if (m + 2 < totalmaps) {
				console_print(idreal, "   %s   %s   %s", listofmaps[m], listofmaps[m + 1], listofmaps[m + 2]);
			} else {
				console_print(idreal, "   %s   %s", listofmaps[m], listofmaps[m + 1]);
			}
		} else {
			console_print(idreal, "   %s", listofmaps[m]);
		}
	}

	if (50 * (iteration + 1) < totalmaps) {
		new kIdfake[4];
		num_to_str(iteration + 1, kIdfake, charsmax(kIdfake));
		console_print(idreal, "%L", idreal, "DMAP_LISTMAPS_MORE");
		set_task(2.0, "more_list_maps", DMAP_TASKID_MORE_LIST_MAPS + idreal, kIdfake, sizeof(kIdfake));
	} else {	//Base case has been reached
		console_print(idreal, "%L", idreal, "DMAP_LISTMAPS_FINISHED", totalmaps);
	}
}

public say_nextmap(id) {
	new timeleft = get_timeleft();
	new time2 = timeleft - timeleft % 60;
	new minutesleft = floatround(float(time2) / 60.0);
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	if (minutesleft >= 2 && !mselected)
	if (get_pcvar_num(pNominationsAllowed) == 1) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_SAY_NOMINATIONS", 
		  (minutesleft == 3 || minutesleft == 2) ? timeleft - 100 : minutesleft - 2, (minutesleft == 3 || minutesleft == 2) ? "sec." : "min.");
	} else {
		if (mselected) {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NEXTMAP_VOTED", smap, timeleft);
		} else {
			if (inprogress) {
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_CURRENT_MAP_VOTE", mapname);
			}
		}
	}
	return PLUGIN_HANDLED;
}

check_if_need() {
	new Float:ratio = rtvpercent;
	new needed = floatround(float(activeplayers) * ratio + 0.49);
	new timeleft = get_timeleft();
	new Float:minutesleft = float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit - minutesleft;

	if ((minutesplayed + 0.5) >= (float(minimumwait))) {
		if (rocks >= needed && rocks >= minimum) {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_RTV_STARTING", rocks);
			set_hudmessage(222, 70, 0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 4);
			show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_RTV_START", rocks);
			hasbeenrocked = 1;
			inprogress = 1;
			mselected = false;
			set_task(10.0, "rock_it_now", DMAP_TASKID_ROCK_IT_NOW);
		}
	}
}

public rock_the_vote(id) {
	new Float:ratio = rtvpercent;
	new needed = floatround(float(activeplayers) * ratio + 0.49);
	new kName[32];
	get_user_name(id, kName, charsmax(kName));
	new timeleft = get_timeleft();
	new Float:minutesleft = float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit - minutesleft;

	if (cycle) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTING_DISABLED");
		return PLUGIN_CONTINUE;
	}
	if (!enabled) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_RTV_DISABLED");
		return PLUGIN_CONTINUE;
	}
	if (inprogress) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTE_BEGINNING");
		return PLUGIN_CONTINUE;
	}
	if (mselected) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTING_COMPLETED", smap, get_timeleft());
		return PLUGIN_CONTINUE;
	}
	if (hasbeenrocked) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAP_ALREADY_ROCKED");
		return PLUGIN_CONTINUE;
	}
	if ((timeleft < 120) && (currentlimit != 0)) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_NOT_ENOUGH_TIME");
		return PLUGIN_CONTINUE;
	}
	if (((minutesplayed + 0.5) < (float(minimumwait))) && (currentlimit != 0)) {
		if (float(minimumwait) - 0.5 - minutesplayed > 0.0) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_RTV_WAIT",
			  (floatround(float(minimumwait) + 0.5-minutesplayed) > 0) ? (floatround(float(minimumwait) + 0.5 - minutesplayed)) : (1));
		} else {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_RTV_1MIN");
		}
		if (get_user_flags(id) & ADMIN_DMAP) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_RTV_ADMIN_FORCE", kName);
		}
		return PLUGIN_CONTINUE;
	}
	if (!rocked[id]) {
		rocked[id] = 1;
		rocks++;
	} else {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_ALREADY_ROCKED", kName);
		return PLUGIN_CONTINUE;
	}
	if (rocks >= needed && rocks >= minimum) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_RTV_STARTING", rocks);
		set_hudmessage(222, 70,0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_RTV_START", rocks);
		hasbeenrocked = 1;
		inprogress = 1;
		mselected = false;
		set_task(15.0, "rock_it_now", DMAP_TASKID_ROCK_IT_NOW);
	} else {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_RTV_NEEDED", ((needed-rocks) > (minimum-needed)) ? (needed-rocks) : (minimum-rocks));
	}
	return PLUGIN_CONTINUE;
}

public rock_it_now() {
	hasbeenrocked = 1;
	new timeleft = get_timeleft();
	new Float:minutesleft=float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit-minutesleft;
	new Float:timelimit;
	counttovote = 0;
	remove_task(DMAP_TASKID_TIME_TO_VOTE);
	remove_task(DMAP_TASKID_GET_READY);
	timelimit = float(floatround(minutesplayed + 1.5));

	oldtimelimit = get_cvar_float("mp_timelimit");
	istimeset = 1;
	set_cvar_float("mp_timelimit", timelimit);
	if (quiet != 2) {
		c_p(0, print_console, "[DMM] %L", LANG_SERVER, "DMAP_TIMELIMIT_CHANGED", floatround(get_cvar_float("mp_timelimit")));
	}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] Time limit changed to %d to enable vote to occur now", floatround(get_cvar_float("mp_timelimit")));
#endif

	timeleft = get_timeleft();
	inprogress = 1;
	mselected = false;
	if (quiet != 2) {
		set_hudmessage(0, 222,50, -1.0, 0.23, 1, 6.0, 6.0, 1.0, 1.0, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_START_MAPVOTE");
	} else {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_START_MAPVOTE");
	}
	if (quiet == 0) {
		client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use _comma(e10) bay(s18) mass(e42) cap(s50)^"");
	}
	set_task(3.5, "get_ready", DMAP_TASKID_GET_READY);
	set_task(10.0, "start_the_vote");
	remove_task(DMAP_TASKID_TIME_DIS);
	remove_task(DMAP_TASKID_END_OF_ROUND);
	rocks = 0;
	new inum, players[32], i;
	get_players(players, inum, "c");
	for (i = 0; i < inum; ++i) {
		rocked[i] = 0;
	}
	set_task(2.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public admin_rockit(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new kName[32], timeleft = get_timeleft();
	get_user_name(id, kName, charsmax(kName));

	if (timeleft < 180.0) {
		console_print(id, "%L", id, "DMAP_NOT_ENOUGH_TIME");
		return PLUGIN_HANDLED;
	}
	if (inprogress || hasbeenrocked || isend) {
		console_print(id, "%L", id, "DMAP_ALREADY_VOTING");
		return PLUGIN_HANDLED;
	}
	if (cycle) {
		console_print(id, "%L", id, "DMAP_ENABLE_VOTEMODE");
		return PLUGIN_HANDLED;
	}
	if (!mselected) {
		switch(get_pcvar_num(pShowActivity)) {
			case 2: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_VOTE_ROCKED_BY_ADMIN", kName);
			case 1: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_RTV_USED_BY_ADMIN");
		}
	} else {
		switch(get_pcvar_num(pShowActivity)) {
			case 2: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_REVOTE_BY_ADMIN", kName);
			case 1: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_REVOTE");
		}
	}
	remove_task(DMAP_TASKID_FREEZE);
	remove_task(DMAP_TASKID_COUNTDOWN);
	remove_task(DMAP_TASKID_END_OF_ROUND);
	counttovote = 0;
	remove_task(DMAP_TASKID_TIME_TO_VOTE);
	remove_task(DMAP_TASKID_GET_READY);
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] ADMIN <%s> calls ^"rockthevote^" with %d seconds left on map", kName, timeleft);
#endif
	inprogress = 1;
	mselected = false;
	set_task(15.0, "rock_it_now", DMAP_TASKID_ROCK_IT_NOW);
	set_task(0.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public check_votes() {
	new timeleft = get_timeleft();
	new b = 0, a;
	for (a = 0; a < nmapstoch; ++a) {
		if (nvotes[b] < nvotes[a]) {
			b = a;
		}
	}

	if (nvotes[maps_to_select] > nvotes[b]) {
		new mapname[32];
		get_mapname(mapname, charsmax(mapname));
		new steptime = get_pcvar_num(pExtendmapStep);
		set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime);
		istimeset = 1;

		if (quiet != 2) {
			set_hudmessage(222, 70,0, -1.0, 0.4, 0, 4.0, 10.0, 2.0, 2.0, 4);
			show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_EXTENDED", steptime);
			if (quiet != 1) {
				client_cmd(0, "speak ^"barney/waitin^"");
			}
		}
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_MAP_EXTENDED2", steptime);
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Voting for the next map finished. Map %s will be extended for %d minutes.", mapname, steptime);
#endif
		inprogress = isend = 0;
		nmaps_num = nbeforefill;
		num_nmapsfill = before_num_nmapsfill;
		return PLUGIN_HANDLED;
	}

	if (nvotes[b] && nvotes[maps_to_select+1] <= nvotes[b]) {
		set_cvar_string("amx_nextmap", nmaps[nnextmaps[b]]);
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));

		new players[32], inum;
		get_players(players, inum, "c");
		if (quiet != 2) {
			if (timeleft <= 0 || timeleft > 300) {
				set_hudmessage(222, 70,0, -1.0, 0.36, 0, 4.0, 10.0, 2.0, 2.0, 4);
				show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_WINS", nmaps[nnextmaps[b]], nvotes[b]);
			} else {
				set_hudmessage(0, 152, 255, -1.0, 0.22, 0, 4.0, 7.0, 2.1, 1.5, 4);
				if ((get_pcvar_num(pEnforceTimelimit) == 1) && bIsCstrike) {
					show_hudmessage(0, "%L %L", LANG_PLAYER, "DMAP_MAP_WINS2", nmaps[nnextmaps[b]], nvotes[b], LANG_PLAYER, "DMAP_IN_SECONDS", timeleft);
				} else {
					show_hudmessage(0, "%L %L", LANG_PLAYER, "DMAP_MAP_WINS2", nmaps[nnextmaps[b]], nvotes[b], LANG_PLAYER, "DMAP_SHORTLY");
				}
				if (is_custom_map(nmaps[nnextmaps[b]]) && usestandard) {
					c_p(0, print_notify, "[DMM] %L", LANG_PLAYER, "DMAP_DOWNLOAD_CUSTOM_MAP");
				}
			}
			if ((strlen(mapsurl) > 0) && is_custom_map(nmaps[nnextmaps[b]])) {
				//set_hudmessage(0, 152, 255, -1.0, 0.70, 1, 4.0, 12.0, 2.1, 1.5, 7);
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_DOWNLOAD_MAPS_URL", mapsurl);
			}
			if (quiet != 1) {
				client_cmd(0, "speak ^"barney/letsgo^"");	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
			}
		}
	}

	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_VOTING_OVER", smap);
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] Voting for the next map finished. The next map will be %s.", smap);
#endif
	inprogress = waited = 0;
	isend = 1;
	//We are near end of map; time to invoke round mode algorithm
	//set_task(2.0, "end_of_round", DMAP_TASKID_END_OF_ROUND, "", 0, "b");
	new waituntilready = timeleft;
	if (waituntilready > 60) {
		waituntilready = 60;
	}
	if (waituntilready <= 0 || get_cvar_num("mp_winlimit")) {
		addthiswait = 4;
		set_task(4.0, "round_mode", DMAP_TASKID_ROUND_MODE);
	} else {
		set_task(float(waituntilready), "round_mode", DMAP_TASKID_ROUND_MODE);
		addthiswait = waituntilready;
	}
	nmaps_num = nbeforefill;
	num_nmapsfill = before_num_nmapsfill;
	set_task(2.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public show_timer() {
	set_task(1.0, "time_dis2", DMAP_TASKID_TIME_DIS, "", 0, "b");
}

public time_dis2() {
	new timeleft = get_timeleft();
	if ((timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
		if (waited < 90) {
			set_hudmessage(255, 215, 190, 0.02, 0.2, 0, 5.0, 5.04, 0.0, 0.5, 3);
		} else {
			set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 5.0, 5.04, 0.0, 0.5, 3);
			//Flashing red:set_hudmessage(210, 0 ,0, 0.02, 0.2, 1, 1.0, 1.04, 0.0, 0.05, 3);
		}
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_LAST_ROUND");
	}
	return PLUGIN_HANDLED;
}

public time_dis3() {
	new timeleft = get_timeleft();
	if ((timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
		if (timeleft > 30) {
			set_hudmessage(255, 215, 190, 0.02, 0.2, 0, 5.0, 5.04, 0.0, 0.5, 3);
		} else {
			set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 5.0, 5.04, 0.0, 0.5, 3);
			//Flashing red:set_hudmessage(210, 0, 0, 0.02, 0.2, 1, 5.0, 5.04, 0.0, 0.5, 3);
		}
		//countdown when "Enforcing timelimit"
		new seconds = timeleft % 60;
		new minutes = floatround((timeleft - seconds) / 60.0);
		show_hudmessage(0, "%L^n%d:%02d", LANG_PLAYER, "DMAP_TIME_LEFT", minutes, seconds);
	}
	return PLUGIN_HANDLED;
}

public round_mode() {
	if (get_cvar_float("mp_timelimit") > 0.1 && get_pcvar_num(pEnforceTimelimit)) {
		remove_task(DMAP_TASKID_ROUND_MODE);
		remove_task(DMAP_TASKID_TIME_DIS);
		new timeleft = get_timeleft();
		if (timeleft < 200) {
			set_task(float(timeleft) - 5.8, "end_of_round");
			set_task(1.0, "time_dis3", DMAP_TASKID_TIME_DIS, "", 0, "b");
		}
		return PLUGIN_HANDLED;
	} else {
		if (waited == 0) {
			set_task(1.0, "show_timer");
		}
		if (isbetween || isbuytime || (waited + addthiswait) > 190 || (!bIsCstrike && (waited + addthiswait) >= 30) || activeplayers < 2) {	//Time to switch maps!!!!!!!!
			remove_task(DMAP_TASKID_ROUND_MODE);
			remove_task(DMAP_TASKID_TIME_DIS);
			if (isbetween) {
				set_task(3.9, "end_of_round");
			} else {
				end_of_round();	//switching very soon!
			}
		} else {
			waited += 5;
			//if (waited >= 15 && waited <= 150 && get_timeleft() < 7) {
			if ((waited + addthiswait) <= 190 && get_timeleft() >= 0 && get_timeleft() <= 15) {
				istimeset2 = 1;
				set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + 2.0);
				if (bIsCstrike) {
					c_p(0, print_chat, "[DMM] ** %L **", LANG_PLAYER, "DMAP_FINISHING_CUR_ROUND");
				}
			}
			set_task(5.0, "round_mode", DMAP_TASKID_ROUND_MODE);
		}
	}
	return PLUGIN_HANDLED;
}

public vote_count(id, key) {
	if (get_cvar_num("amx_vote_answers")) {
		new name[32];
		get_user_name(id, name, charsmax(name));
		if (key-3 == maps_to_select) {
#if FILE_LOGLEVEL >= LOGLEVEL_DEBUG
			log_to_file(logfilename, "[DMM] DEBUG: Vote (name:Extend): %s:Extend;", name);
#endif
			c_p(0, print_chat, "[DMM] * %L", LANG_PLAYER, "DMAP_CHOSE_MAPEXTENDING", name);
		} else if (key-3 < maps_to_select && key != 0) {
#if FILE_LOGLEVEL >= LOGLEVEL_DEBUG
			log_to_file(logfilename, "[DMM] DEBUG: Vote (name:map): %s:%s;", name, nmaps[nnextmaps[key-3]]);
#endif
			c_p(0, print_chat, "[DMM] * %L", LANG_PLAYER, "DMAP_CHOSE_MAP", name, nmaps[nnextmaps[key-3]]);
		}
	}
	nvotes[key-3] += 1;
	g_TotalVotes += 1;
	g_AlreadyVoted[id] = true;
	show_vote_menu(false);

	return PLUGIN_HANDLED;
}

bool:is_in_menu(id) {
	new a;
	for (a = 0; a < nmapstoch; ++a) {
		if (id == nnextmaps[a]) {
			return true;
		}
	}
	return false;
}

public dmap_cancel_vote(id, level, cid) {
	if (!cmd_access(id, level, cid, 0)) {
		return PLUGIN_HANDLED ;
	}
	if (task_exists(DMAP_TASKID_ROCK_IT_NOW, 1)) { 
		new name[32];

		get_user_name(id, name, charsmax(name));
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] ADMIN <%s> cancelled the map vote.", name);
#endif
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_ADMIN_CANCELLED", name);
		remove_task(DMAP_TASKID_ROCK_IT_NOW, 1);
		set_hudmessage(222, 70,0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 8);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_ADMIN_CANCELLED", name);
		hasbeenrocked = 0;
		inprogress = 0;
		mselected = true;

		return PLUGIN_CONTINUE;
	} else {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_NO_CURRENT_VOTE");
	}
	return PLUGIN_HANDLED;
}

public dmap_nominate(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new sArg1[32];
	read_argv(1, sArg1, charsmax(sArg1));

	handle_and_change(id, sArg1, true);	// Force nomination

	return PLUGIN_HANDLED;
}

public level_change() {
	if (istimeset2 == 1) {	//Allow automatic map change to take place.
		set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 2.0);
		istimeset2 = 0;
	} else {
		if (get_cvar_float("mp_timelimit") >= 4.0) {	//Allow automatic map change to take place.
			if (!istimeset) {
				oldtimelimit = get_cvar_float("mp_timelimit");
			}
			set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 3);
			istimeset = 1;
		} else {
			if (get_cvar_num("mp_winlimit")) {	//Allow automatic map change based on teamscores
				new largerscore;
				largerscore = (teamscore[0] > teamscore[1]) ? teamscore[0] : teamscore[1];
				iswinlimitset = 1;
				oldwinlimit = get_cvar_num("mp_winlimit");
				set_cvar_num("mp_winlimit", largerscore);
			}
		}
	}
	//If we are unable to achieve automatic level change, FORCE it.
	set_task(2.1, "delayed_change", DMAP_TASKID_DELAYED_CHANGE);
}

public event_intermission() {	//Default event copied from nextmap.amx, and changed around.
	set_cvar_float("mp_chattime", 3.0);	// make sure mp_chattime is long
	remove_task(DMAP_TASKID_DELAYED_CHANGE);
	set_task(1.85, "delayed_change");
}

public delayed_change() {
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	server_cmd("changelevel %s", smap);
}

public end_of_round() {	//Call when ready to switch maps in (?) seconds
	remove_task(DMAP_TASKID_END_OF_ROUND);
	remove_task(DMAP_TASKID_LOOP_MESSAGES);
	remove_task(DMAP_TASKID_ROUND_MODE);
	remove_task(DMAP_TASKID_TIME_DISPLAY);
	remove_task(DMAP_TASKID_TIME_DIS);
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	set_task(6.0, "level_change");	//used to be 7.0
	if (quiet != 2) {
		countnum = 0;
		set_task(1.0, "countdown", DMAP_TASKID_COUNTDOWN, "", 0, "a", 6);
		if (quiet != 1) {
			client_cmd(0, "speak ^"loading environment on to your computer^"");
		}
	} else {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_MAP_ABOUT_CHANGE");
	}
	///////////////////////////////////////////////
	c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NEXTMAP2", smap);
	if ((strlen(mapsurl) > 0) && is_custom_map(smap)) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_DOWNLOAD_MAPS_URL2", smap, mapsurl);
	}
	///////////////////////////////////////////////
	if (dofreeze) {
		isspeedset = 1;
		thespeed = get_cvar_float("sv_maxspeed");
		set_cvar_float("sv_maxspeed", 0.0);
		new players[32], inum, i;
		get_players(players, inum, "c");
		for (i = 0; i < inum; ++i) {
			client_cmd(players[i], "drop");
			client_cmd(players[i], "+showscores");
		}
		set_task(1.1, "stop_person", DMAP_TASKID_FREEZE, "", 0, "a", 2);
	}
	return PLUGIN_HANDLED;
}

public countdown() {
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	countnum++;
	set_hudmessage(150, 120, 0, -1.0, 0.3, 0, 0.5, 1.1, 0.1, 0.1, 4);
	show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_CHANGING_IN", smap, 7 - countnum);
	return PLUGIN_HANDLED;
}

public stop_person() {
	new players[32], inum, i;
	get_players(players, inum, "c");
	if (isspeedset >= 0 && isspeedset < 2) {
		thespeed = get_cvar_float("sv_maxspeed");
		isspeedset++;
		set_cvar_float("sv_maxspeed", 0.0);
	}
	for (i = 0; i < inum; ++i) {
		client_cmd(players[i], "drop");
	}
	return PLUGIN_HANDLED;
}

display_message() {
	new timeleft = get_timeleft();
	new parttime = timeleft % (frequency * 60 * 2);	//460//period(minutes/cycle) * 60 seconds/minute = period in seconds
	//if frequency = 2 (every 2 minutes one message will appear) THIS FUNCTION COVERS 2 MESSAGES WHICH MAKES ONE CYCLE
	//parttime=timeleft%240;
	new addition = frequency * 60;
	if (mselected || inprogress || cycle) {
		return PLUGIN_CONTINUE;
	}
	//if (parttime > 310 && parttime < 326 && timeleft > 132)
	if (parttime > (40 + addition) && parttime < (56 + addition) && timeleft > 132) {
		set_task(3.0, "message_nominated", DMAP_TASKID_MSG_NOMINATED);	//, "", 0, "a", 4)
	} else {
		//if (parttime > 155 && parttime < 171 && timeleft > 132)
		if (parttime > 30 && parttime < 46 && timeleft > 132) {
			set_task(10.0, "message_maps", DMAP_TASKID_MSG_MAPS, "", 0, "a", 1);
		} else if (timeleft >= 117 && timeleft < 132) {
			message_fifteen();
		}
	}
	return PLUGIN_CONTINUE;
}


// From the AMXX docs: "Hud messages accept a max of 479 characters per message. Word wrapping starts after 69 characters."
// This function should probably be rewritten, or at least have the string lengths altered.
// THIS IS UNTESTED, BUT SHOULD WORK
/* 1.6 hudtext function
Arguments:
textblock: a string containing the text to print, not more than 512 chars (a small calc shows that the max number of letters to be displayed is around 270 btw)
colr, colg, colb: color to print text in (RGB format)
posx, posy: position on screen * 1000 (if you want text to be displayed centered, enter -1000 for both, text on top will be posx=-1000 & posy=20
screen: the screen to write to, hl supports max 4 screens at a time, do not use screen+0 to screen+3 for other hudstrings while displaying this one
time: how long the text shoud be displayed (in seconds)
*/

hud_text16(textblock[], colr, colg, colb, posx, posy, screen, time, id) {
	new y;
	if (contain(textblock, "^n") == -1) {	// if there is no linebreak in the text, we can just show it as it is
		set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);
		show_hudmessage(id, textblock);
	} else {	// more than one line
		new out[128], rowcounter = 0, tmp[512], textremain = true;
		y = screen;
		new i = contain(textblock, "^n");
		copy(out, i, textblock);	// we need to get the first line of text before the loop
		do {	// this is the main print loop
			setc(tmp, charsmax(tmp), 0);	// reset string
			copy(tmp, charsmax(tmp), textblock[i + 1]);	// copy everything AFTER the first linebreak (hence the +1, we don't want the linebreak in our new string)
			setc(textblock, 511, 0);	// reset string
			copy(textblock, 511, tmp);	// copy back remaining text
			i = contain(textblock, "^n");	// get next linebreak position
			if ((strlen(out) + i < 64) && (i != -1)) {	// we can add more lines to the outstring if total letter count don't exceed 64 chars (decrease if you have a lot of short lines since the leading linbreaks for following lines also take up one char in the string)
				add(out, charsmax(out), "^n");	// add a linebreak before next row
				add(out, strlen(out) + i, textblock);
				rowcounter++;	// we now have one more row in the outstring
			} else {	// no more lines can be added
				set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);	// format our hudmsg
				if ((i == -1) && (strlen(out) + strlen(textblock) < 64)) {
					add(out, charsmax(out), "^n");	// if i == -1 we are on the last line, this line is executed if the last line can be added to the current string (total chars < 64)
				} else {	// not the last line or last line must have it's own screen
					if (screen-y < 4) {
						show_hudmessage(id, out);	// we will only print the hudstring if we are under the 4 screen limit
					}
					screen++;	// go to next screen after printing this one
					rowcounter++;	// one more row
					setc(out, charsmax(out), 0);	// reset string
					for (new j = 0; j < rowcounter; j++) {
						add(out, charsmax(out), "^n");	// add leading linebreaks equal to the number of rows we already printed
					}
					if (i == -1) {
						set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);	// format our hudmsg if we are on the last line
					} else {
						add(out, strlen(out) + i, textblock);	// else add the next line to the outstring, before this, out is empty (or have some leading linebreaks)
					}
				}
				if (i == -1) {	// apparently we are on the last line here
					add(out, strlen(out) + strlen(textblock), textblock);	// add the last line to out
					if (screen - y < 4) show_hudmessage(id, out);	// we will only print the hudstring if we are under the 4 screen limit
					textremain = false;	// we have no more text to print
				}
			}
		} while (textremain);
	}
	return screen - y;	// we will return how many screens of text we printed
}

public message_nominated() {
	if ((quiet == 2) || (get_pcvar_num(pNominationsAllowed) == 0)) {
		return PLUGIN_CONTINUE;
	}

	new string[256], string2[256], string3[512];
	if (nmaps_num < 1) {
		formatex(string3, charsmax(string3), "%L", LANG_SERVER, "DMAP_NO_MAPS_NOMINATED");
	} else {
		new n = 0, foundone = 0;
		formatex(string, charsmax(string), "%L^n", LANG_SERVER, "DMAP_NOMINATIONS");
		while (n < 3 && n < nmaps_num) {
			formatex(string, charsmax(string), "%s   %s", string, nmaps[n++]);
		}
		while (n < 6 && n < nmaps_num) {
			foundone = 1;
			format(string2, charsmax(string2), "%s   %s", string2, nmaps[n++]);
		}
		if (foundone) {
			formatex(string3, charsmax(string3), "%s^n%s", string, string2);
		} else {
			formatex(string3, charsmax(string3), "%s", string);
		}
	}
	hud_text16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), -1000, 50, random_num(1, 4), 10, 0);
	return PLUGIN_CONTINUE;
}

list_nominations(id) {
	if (get_pcvar_num(pNominationsAllowed) == 1) {
		new a = 0, string3[512], string1[96], name1[32];
		if (a < nmaps_num) {
			//show_hudmessage(id, "The following maps have been nominated for the next map vote:");
			formatex(string3, 255, "%L", id, "DMAP_NOMINATED_MAPS");
		}
		while (a < nmaps_num) {
			get_user_name(whonmaps_num[a], name1, charsmax(name1));
			//set_hudmessage(255, 0, 0, 0.12, 0.3 + 0.08 * float(a), 0, 15.0, 15.04, 1.5, 3.75, 2 + a);
			//show_hudmessage(id, "%s by: %s", nmaps[a], name1);
			formatex(string1, charsmax(string1), "^n%L", id, "DMAP_MAP_BY", nmaps[a], name1);
			add(string3, charsmax(string3), string1);
			a++;
		}
		hud_text16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), 300, 10, random_num(1, 4), 15, id);
	}
}

public message_maps() {
	if ((quiet == 2) || (get_pcvar_num(pNominationsAllowed) == 0)) {
		return PLUGIN_CONTINUE;
	}

	new string[256], string2[256], string3[512];
	new n = 0;
	new total = 0;

	if ((totalmaps - 6) > 0) {
		n = random_num(0, totalmaps - 6);
	}
	while (total < 3 && total < totalmaps && is_map_valid(listofmaps[n]) && n < totalmaps) {
		if (!is_last_maps(listofmaps[n]) && !is_banned(listofmaps[n]) && !is_nominated(listofmaps[n])) {
			format(string, charsmax(string), "%s   %s", string, listofmaps[n]);
			total++;
		}
		n++;
	}
	while (total < 6 && n < totalmaps && is_map_valid(listofmaps[n]) && !is_nominated(listofmaps[n])) {
		if (!is_last_maps(listofmaps[n]) && !is_banned(listofmaps[n])) {
			format(string2, charsmax(string2), "%s     %s", string2, listofmaps[n]);
			total++;
		}
		n++;
	}
	if (total > 0) {
		//show_hudmessage(0, "The following maps are available to nominate:^n%s", string);
		new temp[256];
		formatex(temp, charsmax(temp), "%L^n", LANG_SERVER, "DMAP_AVAILABLE_MAPS");
		add(string3, charsmax(string3), temp, 100);
		add(string3, charsmax(string3), string, 100);
		add(string3, charsmax(string3), "^n");
	}
	if (total > 3) {
		add(string3, charsmax(string3), string2, 100);
	}

	hud_text16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), -1000, 50, random_num(1, 4), 10, 0);
	return PLUGIN_CONTINUE;
}

message_fifteen() {
	if (quiet == 2) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_VOTING_IN_XSEC", 15);
		return PLUGIN_HANDLED;
	}
	set_hudmessage(0, 222, 50, -1.0, 0.23, 1, 6.5, 6.5, 1.0, 3.0, 4);
	show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_VOTING_IN_XSEC", 15);
	if (quiet == 0) {
		client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^"");
	}
	set_task(8.7, "get_ready", DMAP_TASKID_GET_READY);
	return PLUGIN_HANDLED;
}

public get_ready() {
	if (!cycle) {
		set_task(0.93, "time_to_vote", DMAP_TASKID_TIME_TO_VOTE, "", 0, "a", 5);
	}
}

public time_to_vote() {
	counttovote++;
	new speak[5][] = {"one", "two", "three", "four", "five"};

	if (get_timeleft() > 132 || counttovote > 5 || cycle || isbuytime) {
		counttovote = 0;
		remove_task(DMAP_TASKID_TIME_TO_VOTE);
		remove_task(DMAP_TASKID_GET_READY);
		return PLUGIN_HANDLED;
	} else {
		if (counttovote > 0 && counttovote <= 5) {
			set_hudmessage(0, 222, 50, -1.0, 0.13, 0, 1.0, 0.94, 0.0, 0.0, 4);
			show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_VOTING_IN_XSEC", 6 - counttovote);
			if (quiet == 0) {
				client_cmd(0, "spk ^"fvox/%s^"", speak[5 - counttovote]);
			}
		}
	}
	return PLUGIN_HANDLED;
}

available_maps() {	//return number of maps that haven't been added yet
	new num, isinlist;
	new a, i;
	for (a = 0; a < num_nmapsfill; a++) {	// Loop through each available map
		if (is_map_valid(nmapsfill[a])) {
			isinlist = 0;
			for (i = 0; i < nmaps_num; i++) {
				if (equali(nmapsfill[a], nmaps[i])) {
					isinlist = 1;
				}
			}
			if (!isinlist) {
				num++;
			}
		}
	}
	return num;
}

public ask_for_next_map() {
	display_message();
	new timeleft = get_timeleft();

	if (isspeedset && (timeleft > 30)) {
		isspeedset = 0;
		set_cvar_float("sv_maxspeed", thespeed);
	}
	if (waited > 0) {
		return PLUGIN_HANDLED;
	}
	if (timeleft > 300) {
		isend = 0;
		remove_task(DMAP_TASKID_END_OF_ROUND);
	}
	new mp_winlimit = get_cvar_num("mp_winlimit");
	if (mp_winlimit) {
		new s = mp_winlimit - 2;
		if ((s > teamscore[0] && s > teamscore[1]) && (timeleft > 114 || timeleft < 1)) {
			remove_task(DMAP_TASKID_TIME_DIS);
			mselected = false;
			return PLUGIN_HANDLED;
		}
	} else {
		if (timeleft > 114 || timeleft < 1) {
			remove_task(DMAP_TASKID_TIME_DIS);
			if (timeleft > 135) {
				remove_task(DMAP_TASKID_TIME_DISPLAY);
			}
			mselected = false;
			return PLUGIN_HANDLED;
		}
	}
	if (inprogress || mselected || cycle) {
		return PLUGIN_HANDLED;
	}

	inprogress = 1;
	if (mp_winlimit && !(timeleft >= 115 && timeleft < 134)) {
		if (quiet != 2) {
			set_hudmessage(0, 222, 50, -1.0, 0.13, 1, 6.0, 6.0, 1.0, 1.0, 4);
			show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_START_MAPVOTE");
			if (quiet == 0) {
				client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^"");
			}
			set_task(4.2, "get_ready", DMAP_TASKID_GET_READY);
			set_task(10.0, "start_the_vote");
		} else {
			set_task(1.0, "start_the_vote");
		}
	} else {
		set_task(0.5, "start_the_vote");
	}
	return PLUGIN_HANDLED;
}

public start_the_vote() {
	new j;
	if (cycle) {
		inprogress = 0;
		mselected = false;
		remove_task(DMAP_TASKID_TIME_TO_VOTE);
		remove_task(DMAP_TASKID_GET_READY);
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NEXTMAP2", smap);
		return PLUGIN_HANDLED;
	}
	for (j = 0; j < maps_to_select + 2; j++) {
		nvotes[j] = 0;
	}
	mselected = true;
	inprogress = 1;
	counttovote = 0;
	if ((isbuytime || isbetween) && get_timeleft() && get_timeleft() > 54 && get_pcvar_num(pWeaponDelay)) {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_VOTING_DELAYED");
		if (isbetween) {
			set_task(15.0, "get_ready", DMAP_TASKID_GET_READY);
			set_task(21.0, "start_the_vote");
		} else {
			set_task(8.0, "get_ready", DMAP_TASKID_GET_READY);
			set_task(14.0, "start_the_vote");
		}
		return PLUGIN_HANDLED;
	}	//else start_the_vote anyways..., regardless of buytime

	remove_task(DMAP_TASKID_TIME_TO_VOTE);
	remove_task(DMAP_TASKID_GET_READY);

	if (quiet != 2) {
		if (bIsCstrike) {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_POSSIBLE_NOMINATIONS", nmaps_num, maps_to_select);
		}
	}

#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] Nominations for the map vote: %d out of %d possible nominations", nmaps_num, maps_to_select);
#endif

	before_num_nmapsfill = num_nmapsfill;
	new available = available_maps();

	if ((nmaps_num + available) < (maps_to_select + 1)) {	//Loads maps from mapcycle.txt/allmaps.txt if not enough are in in mapchoice.ini

		new current_map[32];
		get_mapname(current_map,31);
		new overflowprotect = 0;
		new used[MAX_MAPS_AMOUNT];
		new k = num_nmapsfill;
		new totalfilled = 0;
		new alreadyused;
		new tryfill, custfill = 0;
		new q;
		new listpossible = totalmaps;
		while (((available_maps() + nmaps_num - custfill) < (maps_to_select + 7)) && listpossible > 0) {
			alreadyused = 0;
			q = 0;
			tryfill = random_num(0, totalmaps - 1);
			overflowprotect = 0;
			while (used[tryfill] && overflowprotect++ <= totalmaps * 15) {
				tryfill = random_num(0, totalmaps - 1);
			}
			if (overflowprotect >= totalmaps * 15) {
				alreadyused = 1;
#if FILE_LOGLEVEL >= LOGLEVEL_WARN
				log_to_file(logfilename, "[DMM] WARN: Overflow detected in Map Nominate plugin, there might not be enough maps in the current vote");
#endif
				listpossible -= 1;
			} else {
				while (q < num_nmapsfill && !alreadyused) {
					if (equali(listofmaps[tryfill], nmapsfill[q])) {
						alreadyused = used[tryfill] = 1;
						listpossible--;
					}
					q++;
				}
				q = 0;
				while (q < nmaps_num && !alreadyused) {
					if (equali(listofmaps[tryfill], nmaps[q])) {
						alreadyused = used[tryfill] = 1;
						listpossible--;
					}
					q++;
				}
			}

			if (!alreadyused) {
				if (equali(listofmaps[tryfill], current_map) || equali(listofmaps[tryfill], last_map)||
				  is_last_maps(listofmaps[tryfill]) || is_banned(listofmaps[tryfill])) {
					listpossible--;
					used[tryfill] = 1;
				} else {
					if (is_custom_map(listofmaps[tryfill])) {
						custfill++;
					}
					nmapsfill[k] = listofmaps[tryfill];
					num_nmapsfill++;
					listpossible--;
					used[tryfill] = 1;
					k++;
					totalfilled++;
				}
			}
		}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Filled %d slots in the fill maps array with maps from mapcycle.txt, %d are custom", totalfilled, custfill);
#endif
	}

	nbeforefill = nmaps_num;	//extra maps do not act as "nominations" they are additions

	if (nmaps_num < maps_to_select) {

		new need = maps_to_select - nmaps_num;
		if (quiet != 2) {
			c_p(0, print_console, "[DMM] %L", LANG_PLAYER, "DMAP_RANDOM_MAPSELECTION", need);
		}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Randomly Filling slots for the vote with %d out of %d", need, num_nmapsfill);
#endif
		new fillpossible = num_nmapsfill;
		new k = nmaps_num;
		new overflowprotect = 0;
		new used[MAX_MAPS_AMOUNT];
		new totalfilled = 0, custchoice = 0, full = ((amt_custom + custchoice) >= maxcustnom);
		new alreadyused;
		new tryfill;
		if (num_nmapsfill < 1) {
			if (quiet != 2) {
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NOMORE_RANDOM_DEFINED");
			}
#if FILE_LOGLEVEL >= LOGLEVEL_WARN
			log_to_file(logfilename, "[DMM] WARN: Unable to fill any more voting slots with random maps, none defined in mapchoice.ini/allmaps.txt/mapcycle.txt");
#endif
		} else {
			while (fillpossible > 0 && k < maps_to_select) {
				alreadyused = 0;
				new q = 0;
				tryfill = random_num(0, num_nmapsfill - 1);
				overflowprotect = 0;
				while (used[tryfill] && overflowprotect++ <= num_nmapsfill * 10) {
					tryfill = random_num(0, num_nmapsfill - 1);
				}
				if (overflowprotect >= num_nmapsfill * 15) {
					alreadyused = 1;
#if FILE_LOGLEVEL >= LOGLEVEL_WARN
					log_to_file(logfilename, "[DMM] WARN: Overflow detected in Map Nominate plugin, there might not be enough maps in the current vote");
#endif
					fillpossible -= 2;
				} else {
					while (q < nmaps_num && !alreadyused) {
						if (equali(nmapsfill[tryfill], nmaps[q])) {
							alreadyused = used[tryfill] = 1;
							fillpossible--;
						}
						q++;
					}
					if (!alreadyused) {
						if (is_custom_map(nmapsfill[tryfill]) && full) {
							alreadyused = used[tryfill] = 1;
							fillpossible--;
						}
					}
				}

				if (!alreadyused) {
					if (is_custom_map(nmapsfill[tryfill])) {
						custchoice++;
						full = ((amt_custom + custchoice) >= maxcustnom);
					}
					nmaps[k] = nmapsfill[tryfill];
					nmaps_num++;
					fillpossible--;
					used[tryfill] = 1;
					k++;
					totalfilled++;
				}
			}

			if (totalfilled == 0) {
				console_print(0, "[DMM] %L", LANG_SERVER, "DMAP_NO_DEFAULTMAPS_FOUND");
			} else {
				if (quiet != 2) {
					console_print(0, "[DMM] %L", LANG_SERVER, "DMAP_FILLED_RANDOM_MAPS", totalfilled);
				}
			}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
			log_to_file(logfilename, "[DMM] Filled %d vote slots with random maps, %d are custom", totalfilled, custchoice);
#endif
		}
	}

	show_vote_menu(true);
	return PLUGIN_HANDLED;
}

show_vote_menu(bool:bFirstTime) {

	new menu[512], a, mkeys = (1 << maps_to_select + 1 + 3);
	new steptime = get_pcvar_num(pExtendmapStep);

	new pos;

	new mp_winlimit = get_cvar_num("mp_winlimit");
	if (bFirstTime == true) {
		g_TotalVotes = 0;
		for (a = 0; a <= 32; a++) {
			g_AlreadyVoted[a] = false;
		}
	}

	if (bIsCstrike) {
		pos = formatex(menu, charsmax(menu), "\r%L\w^n^n", LANG_SERVER, "DMAP_MENU_TITLE");
	} else {
		pos = formatex(menu, charsmax(menu), "%L^n^n", LANG_SERVER, "DMAP_MENU_TITLE");
	}

	new dmax = (nmaps_num > maps_to_select) ? maps_to_select : nmaps_num;

	new tagpath[64], sMenuOption[64];	// If size of sMenuOption is changed, change maxlength in append_vote_percent as well
	formatex(tagpath, charsmax(tagpath), "%s/dmaptags.ini", custompath);

	for (nmapstoch = 0; nmapstoch < dmax; ++nmapstoch) {
		if (bFirstTime == true) {
			a = random_num(0, nmaps_num - 1);	// Randomize order of maps in vote
			while (is_in_menu(a)) {
				if (++a >= nmaps_num) {
					a = 0;
				}
			}
			nnextmaps[nmapstoch] = a;
			nvotes[nmapstoch] = 0;			// Reset votes for each map
		}

		if (is_custom_map(nmaps[nnextmaps[nmapstoch]]) && usestandard) {
			if (bIsCstrike) {
				formatex(sMenuOption, charsmax(sMenuOption), "%d. %s  \b(%L)\w", nmapstoch + 1 + 3, nmaps[nnextmaps[nmapstoch]], LANG_SERVER, "DMAP_MENU_CUSTOM");
			} else {
				formatex(sMenuOption, charsmax(sMenuOption), "%d. %s  (%L)", nmapstoch + 1 + 3, nmaps[nnextmaps[nmapstoch]], LANG_SERVER, "DMAP_MENU_CUSTOM");
			}
		} else {	// Don't show (Custom)
			formatex(sMenuOption, charsmax(sMenuOption), "%d. %s", nmapstoch + 1 + 3, nmaps[nnextmaps[nmapstoch]]);
		}

		if (file_exists(tagpath)) {	// If the tag file is there, check for the extra tag
			new iLine, sFullLine[64], sTagMap[32], sTagText[32], txtLen;
		
			while (read_file(tagpath, iLine, sFullLine, charsmax(sFullLine), txtLen)) {
				if (sFullLine[0] == ';') {
					iLine++;
					continue;	// Ignore comments
				}

				strbreak(sFullLine, sTagMap, charsmax(sTagMap), sTagText, charsmax(sTagText));	// Split the map name and tag apart

				// TODO: Wildcard (regex) matching
				// I pulled this code for the v3.24 release.
				// Sorry! Expect it to return in the future.

				if (equali(nmaps[nnextmaps[nmapstoch]], sTagMap)) {
					format(sMenuOption, charsmax(sMenuOption), "%s [%s]", sMenuOption, sTagText);
					break;	// Quit reading the file
				}
				iLine++;
			}
		}

#if FILE_LOGLEVEL >= LOGLEVEL_DEBUG
	log_to_file(logfilename, "[DMM] DEBUG: (nmapstoch:sMenuOption): %d:%s;", nmapstoch, sMenuOption);
#endif
		append_vote_percent(sMenuOption, nmapstoch, true);
		pos += formatex(menu[pos], charsmax(menu), sMenuOption);	// TODO: This should probably be less than 511 since pos is > 0

		mkeys |= (1 << nmapstoch);
	}

	menu[pos++] = '^n';
	if (bFirstTime == true) {
		nvotes[maps_to_select] = 0;
		nvotes[maps_to_select + 1] = 0;
	}
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	if (!mp_winlimit && get_cvar_float("mp_timelimit") < get_pcvar_float(pExtendmapMax)) {
		formatex(sMenuOption, charsmax(sMenuOption), "%L^n", LANG_SERVER, "DMAP_MENU_EXTEND", maps_to_select + 1 + 3, mapname, steptime);
		append_vote_percent(sMenuOption, maps_to_select, true);
		pos += formatex(menu[pos], 511, sMenuOption);

		mkeys |= (1 << maps_to_select);
	}

	formatex(sMenuOption, charsmax(sMenuOption), "%L", LANG_SERVER, "DMAP_MENU_NONE", 0);
	append_vote_percent(sMenuOption, maps_to_select + 1);
	formatex(menu[pos], 511, sMenuOption);

	if (bFirstTime == true) {
		g_VoteTimeRemaining = DMAP_VOTE_TIME;
		set_task(float(g_VoteTimeRemaining), "check_votes");
		show_menu(0, mkeys, menu, --g_VoteTimeRemaining, DMAP_MENU_TITLE);
		set_task(1.0, "update_vote_time_remaining", DMAP_TASKID_VTR, "", 0, "a", g_VoteTimeRemaining);
		if (bIsCstrike) {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_TIME_TO_CHOOSE");
		}
		if (quiet == 0) {
			client_cmd(0, "spk Gman/Gman_Choose%d", random_num(1, 2));
		}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Voting for the next map started.");
#endif
	} else {
		new players[32], iNum, id;
		get_players(players, iNum, "ch");
		for (new iPlayer = 0; iPlayer < iNum; iPlayer++) {
			id = players[iPlayer];
			if (g_AlreadyVoted[id] == false) {
				show_menu(players[iPlayer], mkeys, menu, g_VoteTimeRemaining, DMAP_MENU_TITLE);
			}
		}

	}
	return PLUGIN_HANDLED;
}

stock percent(iIs, iOf) {
	return (iOf != 0) ? floatround(floatmul(float(iIs) / float(iOf), 100.0)) : 0;
}

append_vote_percent(sMenuOption[], iChoice, bool:bNewLine = false) {

	new iPercent = percent(nvotes[iChoice], g_TotalVotes);
	new sPercent[16];
	if (iPercent > 0) {	// Don't show 0%
		if (bIsCstrike) {
			formatex(sPercent, charsmax(sPercent), " \d(%d%s)\w", iPercent, "%%");
		} else {
			formatex(sPercent, charsmax(sPercent), " (%d%s)", iPercent, "%%");
		}
		strcat(sMenuOption, sPercent, 63);
	}

	if (bNewLine == true) {		// Do this even if vote is 0%
		strcat(sMenuOption, "^n", 63);
	}

	return PLUGIN_HANDLED;
}

public update_vote_time_remaining() {
	if (--g_VoteTimeRemaining <= 0) {
		remove_task(DMAP_TASKID_VTR);
	}
	return PLUGIN_HANDLED;
}

handle_and_change(id, map2[], bool:bForce = false) {
	new tester[32];
	if (is_map_valid(map2) == 1) {
		handle_nominate(id, map2, bForce);
	} else {
		formatex(tester, charsmax(tester), "cs_%s", map2);
		if (is_map_valid(tester) == 1) {
			handle_nominate(id, tester, bForce);
		} else {
			formatex(tester, charsmax(tester), "de_%s", map2);
			if (is_map_valid(tester) == 1) {
				handle_nominate(id, tester, bForce);
			} else {
				formatex(tester, charsmax(tester), "as_%s", map2);
				if (is_map_valid(tester) == 1) {
					handle_nominate(id, tester, bForce);
				} else {
					formatex(tester, charsmax(tester), "dod_%s", map2);
					if (is_map_valid(tester) == 1) {
						handle_nominate(id, tester, bForce);
					} else {
						formatex(tester, charsmax(tester), "fy_%s", map2);
						if (is_map_valid(tester) == 1) {
							handle_nominate(id, tester, bForce);
						} else {				// Send invalid map. handle_nominate() handles the error.
							handle_nominate(id, map2, bForce);
						}
					}
				}
			}
		}
	}
}

public handle_say(id) {

	new chat[256];
	read_args(chat, charsmax(chat));

	if (containi(chat, "<") != -1 || containi(chat, "?") != -1 || containi(chat, ">") != -1 || containi(chat, "*") != -1 || containi(chat, "&") != -1 || containi(chat, ".") != -1 || containi(chat, "cod_boss") != -1) {
		return PLUGIN_CONTINUE;
	} else 	if (containi(chat, "nominate ") == 1) {
		new mycommand[41];
		read_args(mycommand, charsmax(mycommand));
		remove_quotes(mycommand);
		handle_and_change(id, mycommand[9]);
	} else if (containi(chat, "vote ") == 1) {
		new mycommand[37];
		read_args(mycommand, charsmax(mycommand));
		remove_quotes(mycommand);
		handle_and_change(id, mycommand[5]);
	} else {
		remove_quotes(chat);

		if (is_map_valid(chat) == 1) {
			handle_nominate(id, chat, false);
		} else {

			new chat2[32];

			formatex(chat2, charsmax(chat2), "cs_%s", chat);
			if (is_map_valid(chat2) == 1) {
				handle_nominate(id, chat2, false);
			} else {
				formatex(chat2, charsmax(chat2), "de_%s", chat);
				if (is_map_valid(chat2) == 1) {
					handle_nominate(id, chat2, false);
				} else {
					formatex(chat2, charsmax(chat2), "as_%s", chat);
					if (is_map_valid(chat2) == 1) {
						handle_nominate(id, chat2, false);
					} else {
						formatex(chat2, charsmax(chat2), "dod_%s", chat);
						if (is_map_valid(chat2) == 1) {
							handle_nominate(id, chat2, false);
						} else {
							formatex(chat2, charsmax(chat2), "fy_%s", chat);
							if (is_map_valid(chat2) == 1) {
								handle_nominate(id, chat2, false);
							}
						}
					}
				}
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public calculate_custom() {
	//New optional protection against "too many" custom maps being nominated.
	amt_custom = 0;
	new i;
	for (i = 0; i < nmaps_num; i++) {
		if (is_custom_map(nmaps[i])) {
			amt_custom++;
		}
	}
}

handle_nominate(id, map[], bool:bForce) {
	if ((get_pcvar_num(pNominationsAllowed) == 0) && (bForce == false)) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_NOMINATIONS_DISABLED");
		return PLUGIN_HANDLED;
	}
	strtolower(map);
	new current_map[32], iscust = 0, iscust_t = 0, full;
	full = (amt_custom >= maxcustnom);
	new n = 0, i, done = 0, isreplacement = 0;	//0: (not a replacement), 1: (replacing their own), 2: (replacing others)
	new tempnmaps = nmaps_num;
	get_mapname(current_map, charsmax(current_map));
	if (maxnom == 0) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_NOMINATIONS_DISABLED");
		return PLUGIN_HANDLED;
	}
	if (inprogress && mselected) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTE_IN_PROGRESS");
		return PLUGIN_HANDLED;
	}
	if (mselected) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, charsmax(smap));
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTING_OVER", smap);
		return PLUGIN_HANDLED;
	}
	if (!is_map_valid(map) || is_map_valid(map[1])) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAP_NOTFOUND", map);
		return PLUGIN_HANDLED;
	}
	if (is_banned(map) && (bForce == false)) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAPVOTE_NOT_AVAILABLE");
		return PLUGIN_HANDLED;
	}
	if (is_last_maps(map) && !equali(map, current_map) && (bForce == false)) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_CANT_NOMINATE_LASTMAP", ban_last_maps);
		return PLUGIN_HANDLED;
	}
	if (equali(map, current_map)) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_EXTEND_MAP", map);
		return PLUGIN_HANDLED;
	}
	//Insert Strict Style code here, for pcvar dmap_strict 1
	if (get_pcvar_num(pDmapStrict) && (bForce == false)) {
		new isinthelist = 0;
		for (new a = 0; a < totalmaps; a++) {
			if (equali(map, listofmaps[a]))
				isinthelist = 1;
		}
		if (!isinthelist) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_ALLOWED_MAPS");
			return PLUGIN_HANDLED;
		}
	}
	iscust = is_custom_map(map);
	if (nmaps_num >= maps_to_select || Nominated[id] >= maxnom) {
		if (Nominated[id] > maxnom) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAX_MAPS_REACHED");	//Possible to reach here!
			//only if the command dmap_nominations is used to lower amount of maps that can be nominated
			return PLUGIN_HANDLED;
		}

		for (i = 0; i < nmaps_num; i++) {
			if (equali(map, nmaps[i])) {
				new name[32];
				get_user_name(whonmaps_num[i], name, charsmax(name));
				c_p(id, print_chat, "[DMM] %L", id, "DMAP_ALREADY_NOMINATED", map, name);

				return PLUGIN_HANDLED;
			}
		}

		while (n < nmaps_num && !done && Nominated[id] > 1) {	//If the person has nominated 2 or more maps, he can replace his own
			if (whonmaps_num[n] == id) {	//If a map is found that he has nominated, replace his own nomination.
				iscust_t = is_custom_map(nmaps[n]);
				if (!(full && iscust && !iscust_t)) {
					Nominated[id] = Nominated[id] - 1;
					nmaps_num = n;
					done = 1;
					isreplacement = 1;
				}
			}
			n++;
		}

		if (!done) {
			n = 0;
			while (n < nmaps_num && !done && Nominated[id] < 2) {	//If the person has nom only 1 or no maps, he can replace ppl who nominated 3
				if (Nominated[whonmaps_num[n]] > 2) {	//Replace the "greedy person's" nomination
					iscust_t = is_custom_map(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {
						done = 1;
						Nominated[whonmaps_num[n]] = Nominated[whonmaps_num[n]] - 1;
						nmaps_num = n;
						isreplacement = 2;
					}
				}
				n++;
			}
		}
		if (!done) {
			n = 0;

			while (n < nmaps_num && !done && Nominated[id] < 1) {	//If the person has not nom any maps, he can replace those with more than one
				//he cannot replace those with only one nomination, that would NOT be fair

				if (Nominated[whonmaps_num[n]] > 1) {	//Replace the "greedy person's" nomination
					iscust_t = is_custom_map(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {
						done = 1;
						Nominated[whonmaps_num[n]] = Nominated[whonmaps_num[n]] - 1;
						nmaps_num = n;
						isreplacement = 2;
					}
				}
				n++;
			}
		}

		if (!done) {
			n = 0;

			while (n < nmaps_num && !done && Nominated[id] > 0) {	//If the person has nominated a map, he can replace his own
				if (whonmaps_num[n] == id) {	//If a map is found that he has nominated, replace his own nomination.
					iscust_t = is_custom_map(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {	//Check to see if too many custom maps are nominated
						Nominated[id] = Nominated[id] - 1;
						nmaps_num = n;
						done = 1;
						isreplacement = 1;
					}
				}
				n++;
			}
		}
		if (!done) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAX_NOMINATIONS_REACHED", nmaps_num);
			return PLUGIN_HANDLED;
		}
	}

	for (i = 0; i < nmaps_num; i++) {
		if (equali(map, nmaps[i])) {
			new name[32];
			get_user_name(whonmaps_num[i], name, charsmax(name));
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_ALREADY_NOMINATED", map, name);

			nmaps_num = tempnmaps;

			return PLUGIN_HANDLED;
		}
	}

	if (!isreplacement && iscust && full) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_MAX_CUSTOMMAPS_REACHED", maxcustnom);
		return PLUGIN_HANDLED;
	}

	new name[32];
	get_user_name(id, name, charsmax(name));
	if (isreplacement == 1) {	//They are replacing their old map
		if (quiet == 2) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_REPLACE_PREVIOUS_NOMINATION", nmaps[nmaps_num]);
		} else {
			c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_PLAYER_REPLACED_NOMINATION", name, nmaps[nmaps_num]);
		}
	} else {
		if (isreplacement == 2) {
			if (quiet == 2) {
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NOMINATION_REPLACED", nmaps[nmaps_num]);
			} else {		
				new name21[32];
				get_user_name(whonmaps_num[nmaps_num], name21, charsmax(name21));
				c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NOMINATION_REPLACED2", name21, nmaps[nmaps_num]);
			}
		}
	}

	Nominated[id]++;

	console_print(id, "[DMM] %L", id, "DMAP_ADD_NOMINATION", map, nmaps_num + 1);

	set_task(0.18, "calculate_custom");
	copy(nmaps[nmaps_num], 31, map);
	whonmaps_num[nmaps_num] = id;

	if (isreplacement) {
		nmaps_num = tempnmaps;
	} else {
		nmaps_num = tempnmaps + 1;
	}
	if ((bForce == true) && (get_pcvar_num(pShowActivity) > 0)) {
		switch(get_pcvar_num(pShowActivity)) {
			case 1: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_ADMIN_NOMINATED_MAP1", map);
			case 2: c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_ADMIN_NOMINATED_MAP2", name, map);
		}
	} else {
		c_p(0, print_chat, "[DMM] %L", LANG_PLAYER, "DMAP_NOMINATED_MAP", name, map);
	}

	return PLUGIN_HANDLED;
}

public team_score() {

	new team[2];
	read_data(1, team, 1);
	teamscore[(team[0] == 'C') ? 0 : 1] = read_data(2);

	return PLUGIN_CONTINUE;
}

public plugin_end() {
	new current_map[32];
	get_mapname(current_map, charsmax(current_map));
	set_localinfo("amx_lastmap", current_map);

	if (istimeset) {
		set_cvar_float("mp_timelimit", oldtimelimit);
	} else {
		if (istimeset2) {
			set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 2.0);
		}
	}
	if (isspeedset) {
		set_cvar_float("sv_maxspeed", thespeed);
	}
	if (iswinlimitset) {
		set_cvar_num("mp_winlimit", oldwinlimit);
	}
	return PLUGIN_CONTINUE;
}

get_listing() {
	new i = 0, iavailable = 0;
	new line = 0, p;
	new stextsize = 0, isinthislist = 0, found_a_match = 0, done = 0;
	new linestr[256];
	new maptext[32];
	new current_map[32];
	get_mapname(current_map, charsmax(current_map));
	//pathtomaps = "mapcycle.txt";
	get_cvar_string("mapcyclefile", pathtomaps, charsmax(pathtomaps));
	new smap[32];
	get_cvar_string("amx_nextmap", smap, charsmax(smap));
	if (file_exists(pathtomaps)) {
		while (read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize) && !done) {
			formatex(maptext, charsmax(maptext), "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1]) && equali(maptext, current_map)) {
				done = found_a_match = 1;
				line++;
				if (read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize)) {
					formatex(maptext, charsmax(maptext), "%s", linestr);
					if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
						//////////////////////////////////////////
						if (equali(smap, "")) {
							register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
						}
						set_cvar_string("amx_nextmap", maptext);
					} else {
						found_a_match = 0;
					}
				} else {
					found_a_match = 0;
				}
			} else {
				line++;
			}
		}
		/*
		if (!found_a_match) {
			line = 0;
			while (read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize) && !found_a_match && line < 1024) {
				formatex(maptext, charsmax(maptext), "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					if (equali(smap, "")) {
						register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
					}
					set_cvar_string("amx_nextmap", maptext);
					found_a_match = 1;
				} else {
					line++;
				}
			}
		}
		*/
		/* CODE TO RANDOMIZE NEXTMAP VARIABLE!*/
		if (!found_a_match) {
			line = random_num(0, 50);
			new tries = 0;

			while ((read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize) || !found_a_match) && (tries < 1024 && !found_a_match)) {
				formatex(maptext, charsmax(maptext), "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					if (equali(smap, "")) {
						register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
					}
					set_cvar_string("amx_nextmap", maptext);
					found_a_match = 1;
				} else {
					line = random_num(0, 50);
					tries++;
				}
			}
		}
	}

	line = 0;
	formatex(pathtomaps, charsmax(pathtomaps), "%s/allmaps.txt", custompath);
	if (!file_exists(pathtomaps)) {
		new mapsadded = 0;
		while ((line = read_dir("maps", line, linestr, charsmax(linestr), stextsize)) != 0) {
			stextsize -= 4;

			if (stextsize > 0) {
				if (!equali(linestr[stextsize], ".bsp")) {
					continue;	// skip non map files
				}
				linestr[stextsize] = 0;	// remove .bsp
			}

			if (is_map_valid(linestr)) {
				write_file(pathtomaps, linestr);
				mapsadded++;
			}
		}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Found %d maps in your <mod>/MAPS folder, and added these to the addons/amxmodx/allmaps.txt file", mapsadded);
#endif
		line = 0;
	}

	if (get_pcvar_num(pDmapStrict) == 1) {
		get_cvar_string("mapcyclefile", pathtomaps, charsmax(pathtomaps));
		//pathtomaps = "mapcycle.txt";
	}

	if (file_exists(pathtomaps)) {
		while (read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize) && i < MAX_MAPS_AMOUNT) {
			formatex(maptext, charsmax(maptext), "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				isinthislist = 0;
				for (p = 0; p < i; p++) {
					if (equali(maptext, listofmaps[p])) {
						isinthislist = 1;
					}
				}
				if (!isinthislist) {
					listofmaps[i++] = maptext;
				}
			}
			line++;
		}
	}

	line = 0;
	for (p = 0; p < i; p++) {
		if (!is_banned(listofmaps[p]) && !is_last_maps(listofmaps[p])) {
			iavailable++;
		}
	}
	new dummy_str[64];
	get_cvar_string("mapcyclefile", dummy_str, charsmax(dummy_str));
	//if (iavailable < maps_to_select && !equali(pathtomaps, "mapcycle.txt"))
	if (iavailable < maps_to_select && !equali(pathtomaps, dummy_str)) {
		//pathtomaps = "mapcycle.txt";
		get_cvar_string("mapcyclefile", pathtomaps, charsmax(pathtomaps));
		if (file_exists(pathtomaps)) {
			while (read_file(pathtomaps, line, linestr, charsmax(linestr), stextsize) && i < MAX_MAPS_AMOUNT) {
				formatex(maptext, charsmax(maptext), "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					isinthislist = 0;
					for (p = 0; p < i; p++) {
						if (equali(maptext, listofmaps[p])) {
							isinthislist = 1;
						}
					}
					if (!isinthislist) {
						listofmaps[i++] = maptext;
					}
				}
				line++;
			}
		}
	}
	totalmaps = i;
	iavailable = 0;
	for (p = 0; p < i; p++) {
		if (!is_banned(listofmaps[p]) && !is_last_maps(listofmaps[p])) {
			iavailable++;
		}
	}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] Found %d Maps in your mapcycle.txt/allmaps.txt file, %d are available for filling slots", i, iavailable);
#endif
}

public ban_some_maps() {
	//BAN MAPS FROM CONFIG FILE
	new banpath[64];
	formatex(banpath, charsmax(banpath), "%s/mapstoban.ini", custompath);
	new i = 0;
	new line = 0;
	new stextsize = 0;
	new linestr[256];
	new maptext[32];

	if (file_exists(banpath)) {
		while (read_file(banpath, line, linestr, charsmax(linestr), stextsize) && i < MAX_MAPS_AMOUNT) {
			formatex(maptext, charsmax(maptext), "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				banthesemaps[i++] = maptext;
			}
			line++;
		}
	}
	totalbanned = i;
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
	log_to_file(logfilename, "[DMM] Banned %d maps in your mapstoban.ini file", totalbanned);
#endif
	//BAN RECENT MAPS PLAYED
	new lastmapspath[64];
	formatex(lastmapspath, charsmax(lastmapspath), "%s/lastmapsplayed.txt", custompath);
	line = stextsize = 0;
	new current_map[32];
	get_mapname(current_map, charsmax(current_map));
	lastmaps[0] = current_map;
	bannedsofar++;
	currentplayers = activeplayers = rocks = 0;
	if (file_exists(lastmapspath)) {
		while(read_file(lastmapspath, line, linestr, charsmax(linestr), stextsize) && bannedsofar <= ban_last_maps) {
			if ((strlen(linestr) > 0) && (is_map_valid(linestr))) {
				formatex(lastmaps[bannedsofar++], 31, "%s", linestr);
			}
			line++;
		}
	}
	write_last_maps();
}

write_last_maps() {	//deletes and writes to lastmapsplayed.txt
	new lastmapspath[64];
	formatex(lastmapspath, charsmax(lastmapspath), "%s/lastmapsplayed.txt", custompath);
	if (file_exists(lastmapspath)) {
		delete_file(lastmapspath);
	}
	new text[256], p;
	for (p = 0; p < bannedsofar; p++) {
		formatex(text, charsmax(text), "%s", lastmaps[p]);
		write_file(lastmapspath, text);
	}
	write_file(lastmapspath, ";Generated by Deagles' Map Manager plugin - These are most recent maps played.");

	load_maps();
}

load_maps() {
	new choicepath[64];
	formatex(choicepath, charsmax(choicepath), "%s/mapchoice.ini", custompath);
	new line = 0;
	new stextsize = 0, isinlist, unable = 0, i;
	new linestr[256];
	new maptext[32];
	new current_map[32];
	get_mapname(current_map, charsmax(current_map));
	if (file_exists(choicepath)) {
		while (read_file(choicepath, line, linestr, charsmax(linestr), stextsize) && (num_nmapsfill < MAX_MAPS_AMOUNT)) {
			formatex(maptext, charsmax(maptext), "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				isinlist = 0;
				if (is_banned(maptext) || is_last_maps(maptext)) {
					isinlist = 1;
				} else {
					if (equali(maptext, current_map) || equali(maptext, last_map)) {
						isinlist = 1;
					} else {
						for (i = 0; i < num_nmapsfill; i++) {
							if (equali(maptext, nmapsfill[i])) {
#if FILE_LOGLEVEL >= LOGLEVEL_WARN
								log_to_file(logfilename, "[DMM] WARN: Map ^"%s^" is defined twice in mapchoice.ini.", maptext);
#endif
								isinlist = 1;
							}
						}
					}
				}
				if (!isinlist) {
					copy(nmapsfill[num_nmapsfill++], 31, maptext);
				} else {
					unable++;
				}
			}
			line++;
		}
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Loaded %d maps for voting. %d other maps were unusable.", num_nmapsfill, unable);
	} else {
		log_to_file(logfilename, "[DMM] Unable to open file %s. mapcycle.txt will be searched instead.", choicepath);
#endif
	}
	get_listing();
}

public load_default_maps() {
	new standardpath[64];
	formatex(standardpath, charsmax(standardpath), "%s/standardmaps.ini", custompath);
	new i = 0;
	new line = 0;
	new stextsize = 0;
	new linestr[256];
	new maptext[32];
	usestandard = 1;
	if (!file_exists(standardpath)) {
		usestandard = standardtotal = 0;
	} else {
		while(read_file(standardpath, line, linestr, charsmax(linestr), stextsize) && i < 40) {
			formatex(maptext, charsmax(maptext), "%s", linestr);
			if (is_map_valid(maptext)) {
				standard[i++] = maptext;
			}
			line++;
		}
		standardtotal = i;
	}
	if (standardtotal < 5) {
		usestandard = 0;
#if FILE_LOGLEVEL >= LOGLEVEL_INFO
		log_to_file(logfilename, "[DMM] Attention, %d Maps were found in the standardmaps.ini file. This is no problem, but the word ^"Custom^" will not be used.", standardtotal);
#endif
	}
}

bool:is_custom_map(map[]) {
	new a;
	for (a = 0; a < standardtotal; a++) {
		if (equali(map, standard[a])) {
			return false;
		}
	}
	if (usestandard) {
		return true;
	}
	return false;
}

bool:is_last_maps(map[]) {
	new a;
	for (a = 0; a < bannedsofar; a++) {
		if (equali(map, lastmaps[a])) {
			return true;
		}
	}
	return false;
}

bool:is_nominated(map[]) {
	new a;
	for (a = 0; a < nmaps_num; a++) {
		if (equali(map, nmaps[a])) {
			return true;
		}
	}
	return false;
}

bool:is_banned(map[]) {
	new a;
	for (a = 0; a < totalbanned; a++) {
		if (equali(map, banthesemaps[a])) {
			return true;
		}
	}
	return false;
}

load_settings(filename[]) {
	if (!file_exists(filename)) {
		return 0;
	}

	new text[256], rpercent[5], strban[4], strplay[3], strwait[3], strwait2[3], strurl[96], strnum[3], strnum2[3];
	new len, pos = 0;
	new Float:numpercent;
	new banamount, nplayers, waittime, mapsnum;
	while (read_file(filename, pos++, text, charsmax(text), len)) {
		if (text[0] == ';') {
			continue;
		}
		switch(text[0]) {
			case 'r': {
				formatex(rpercent, charsmax(rpercent), "%s", text[2]);
				numpercent = float(str_to_num(rpercent)) / 100.0;
				if (numpercent >= 0.03 && numpercent <= 1.0) {
					rtvpercent = numpercent;
				}
			}
			case 'q': {
				if (text[1] == '2') {
					quiet = 2;
				} else {
					quiet = 1;
				}
			}
			case 'c': {
				cycle = 1;
			}
			case 'd': {
				enabled = 0;
			}
			case 'f': {
				if (text[1] == 'r') {
					formatex(strwait2, charsmax(strwait2), "%s", text[2]);
					waittime = str_to_num(strwait2);
					if (waittime >= 2 && waittime <= 60) {
						frequency = waittime;
					}
				} else {
					dofreeze = 0;
				}
			}
			case 'b': {
				formatex(strban, charsmax(strban), "%s", text[2]);
				banamount = str_to_num(strban);
				if (banamount >= 0 && banamount <= 100) {
					if ((banamount == 0 && text[2] == '0') || banamount > 0) {
						ban_last_maps = banamount;
					}
				}
			}
			case 'm': {
				if (atstart) {
					formatex(strnum, charsmax(strnum), "%s", text[2]);
					mapsnum = str_to_num(strnum);
					if (mapsnum >= 2 && mapsnum <= 8) {
						maps_to_select = mapssave = mapsnum;
					}
				}
			}
			case 'p': {
				formatex(strplay, charsmax(strplay), "%s", text[2]);
				nplayers = str_to_num(strplay);
				if (nplayers > 0 && nplayers <= 32) {
					minimum = nplayers;
				}
			}
			case 'u': {
				formatex(strurl, charsmax(strurl), "%s", text[2]);
				if (containi(strurl, "http://") == 0 || containi(strurl, "https://") == 0 || containi(strurl, "ftp://") == 0 || containi(strurl, "www.") == 0) {
					mapsurl = strurl;
				}
			}
			case 'w': {
				formatex(strwait, charsmax(strwait), "%s", text[2]);
				waittime = str_to_num(strwait);
				if (waittime >= 0 && waittime <= 60) {
					minimumwait = waittime;
				}
			}
			case 'x': {
				formatex(strnum2, charsmax(strnum2), "%s", text[2]);
				mapsnum = str_to_num(strnum2);
				if (mapsnum >= 1 && mapsnum <= 8) {
					maxnom = mapsnum;
				}
			}
			case 'y': {
				formatex(strnum2, charsmax(strnum2), "%s", text[2]);
				mapsnum = str_to_num(strnum2);
				if (mapsnum >= 0 && mapsnum <= mapssave) {
					maxcustnom = mapsnum;
				}
			}
		}
	}
	return 1;
}

set_defaults(myid) {

	rtvpercent = 0.6;
	ban_last_maps = 4;
	maxnom = frequency = 3;
	quiet = cycle = 0;
	minimum = enabled = 1;
	minimumwait = 5;
	mapssave = maxcustnom = 5;
	mapsurl = "";
	dofreeze = bIsCstrike;

	if (myid < 0) {
		save_settings(-1);
	} else {
		save_settings(myid);
		console_print(myid, "==== DEFAULTS SET ====");	// TODO: Localize
	}
}

public dmap_rtvpercent(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_rtvpercent");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new Float:percentage = float(str_to_num(arg)) / 100.0;
	if (percentage >= 0.03 && percentage <= 1.0) {
		rtvpercent = percentage;
		save_settings(id);
	} else {
		//console_print(id, "You must specify a value between 3 and 100 for dmap_rtvpercent.");	// TODO: Localize
		console_print(id, "%L ^"dmap_rtvpercent^".", id, "DMAP_MUST_SPECIFY", 3, 100);
	}
	return PLUGIN_HANDLED;
}

public dmap_rtvplayers(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_rtvplayers");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new players = str_to_num(arg);
	if (players >= 1 && players <= 32) {
		minimum = players;
		save_settings(id);
	} else {
		//console_print(id, "You must specify a value between 1 and 32 for dmap_rtvplayers.");	// TODO: Localize
		console_print(id, "%L ^"dmap_rtvplayers^".", id, "DMAP_MUST_SPECIFY", 1, 32);
	}
	return PLUGIN_HANDLED;
}

public dmap_rtvwait(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_rtvwait");
		return PLUGIN_HANDLED;
	}

	new arg[3];
	read_argv(1, arg, charsmax(arg));
	new wait = str_to_num(arg);
	if (wait >= 0 && wait <= 60) {
		minimumwait = wait;
		save_settings(id);
	} else {
		//console_print(id, "You must specify a value between 0 and 60 for dmap_rtvwait.");	// TODO: Localize
		console_print(id, "%L ^"dmap_rtvwait^".", id, "DMAP_MUST_SPECIFY", 0, 60);
	}
	return PLUGIN_HANDLED;
}

public dmap_messages(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_messages");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new wait = str_to_num(arg);
	if (wait >= 2 && wait <= 60) {
		frequency = wait;
		save_settings(id);
	} else {
		//console_print(id, "You must specify a value between 2 and 60 minutes for dmap_messages.");	// TODO: Localize
		console_print(id, "%L ^"dmap_messages^".", id, "DMAP_MUST_SPECIFY", 2, 60);
	}
	return PLUGIN_HANDLED;
}

public dmap_mapsnum(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_mapsnum");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new maps = str_to_num(arg);
	if (maps >= 2 && maps <= 8) {
		mapssave = maps;
		save_settings(id);
		console_print(id, "*****  Settings for dmap_mapsnum do NOT take effect until the next map!!! ******");	// TODO: Localize
	} else {
		//console_print(id, "You must specify a value between 2 and 8 for dmap_mapsnum.");	// TODO: Localize
		console_print(id, "%L ^"dmap_mapsnum^".", id, "DMAP_MUST_SPECIFY", 2, 8);
	}
	return PLUGIN_HANDLED;
}

public dmap_nominations(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_nominations");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new thisnumber = str_to_num(arg);
	if (thisnumber >= 0 && thisnumber <= 8) {
		maxnom = thisnumber;
		save_settings(id);
		console_print(id, "*****  Settings for dmap_nominations do NOT take effect until the next map!!! ******");	// TODO: Localize
	} else {
		//console_print(id, "You must specify a value between 0 and 8 for dmap_nominations.");	// TODO: Localize
		console_print(id, "%L ^"dmap_nominations^".", id, "DMAP_MUST_SPECIFY", 0, 8);
	}
	return PLUGIN_HANDLED;
}

public dmap_maxcustom(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_maxcustom");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new thisnumber = str_to_num(arg);
	if (thisnumber >= 0 && thisnumber <= mapssave) {
		maxcustnom = thisnumber;
		save_settings(id);
	} else {
		console_print(id, "You must specify a value between {0} and maximum maps in the vote, which is {%d}, for dmap_maxcustom", mapssave);	// TODO: Localize
	}
	return PLUGIN_HANDLED;
}

public dmap_quietmode(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_quietmode");
		return PLUGIN_HANDLED;
	}

	new arg[8];
	read_argv(1, arg, charsmax(arg));
	if (containi(arg, "off") != -1) {
		console_print(id, "Quiet mode is now OFF. All messages will be shown, with sound.");	// TODO: Localize
		quiet = 0;
	} else if (containi(arg, "silent") != -1) {
		console_print(id, "Quiet mode is now set to SILENT. Very few messages will be shown, without sound.");	// TODO: Localize
		quiet = 2;
	} else if (containi(arg, "nosound") != -1) {
		console_print(id, "Quiet mode is now set to NOSOUND. All messages will be shown, without sound.");	// TODO: Localize
		quiet = 1;
	} else {
		cmd_access(id, level, cid, 999);	// Force "Usage: ..." message
		return PLUGIN_HANDLED;
	}
	save_settings(id);
	return PLUGIN_HANDLED;
}

public dmap_rtvtoggle(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_rtvtoggle");
		return PLUGIN_HANDLED;
	}

	if (enabled == 0) {
		console_print(id, "Rockthevote is now enabled.");	// TODO: Localize
	} else {
		console_print(id, "Rockthevote is now disabled.");	// TODO: Localize
	}
	enabled = !enabled;
	save_settings(id);
	return PLUGIN_HANDLED;
}

public dmap_freeze(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_freeze");
		return PLUGIN_HANDLED;
	}

	if (!bIsCstrike) {
		console_print(id, "Freeze is always off on non-Counter Strike servers.");	// TODO: Localize
		return PLUGIN_HANDLED;
	}

	new arg[8];
	read_argv(1, arg, charsmax(arg));
	if (equali(arg, "OFF")) {
		console_print(id, "Freeze/Weapon Drop at end of round is now disabled.");	// TODO: Localize
		dofreeze = 0;
	} else if (equali(arg, "ON")) {
		console_print(id, "Freeze/Weapon Drop at end of round is now enabled.");	// TODO: Localize
		dofreeze = 1;
	} else {
		cmd_access(id, level, cid, 999);	// Force "Usage: ..." message
		return PLUGIN_HANDLED;
	}

	save_settings(id);
	return PLUGIN_HANDLED;
}

public dmap_cyclemode(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_cyclemode");
		return PLUGIN_HANDLED;
	}

	if (!cycle) {
		console_print(id, "Cycle mode is now ON. NO VOTE will take place!");	// TODO: Localize
	} else {
		console_print(id, "Cycle Mode is already on. No changes were made.");	// TODO: Localize
		console_print(id, "If you are trying to enable voting, use command ^"dmap_votemode^".");	// TODO: Localize
		return PLUGIN_HANDLED;
	}
	cycle = 1;
	save_settings(id);
	if (inprogress) {
		console_print(id, "The vote in progress cannot be terminated, unless it hasn't started!");	// TODO: Localize
	}
	return PLUGIN_HANDLED;
}

public dmap_votemode(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_votemode");
		return PLUGIN_HANDLED;
	}

	if (cycle) {
		console_print(id, "Voting mode is now ON; Votes WILL take place.");	// TODO: Localize
	} else {
		console_print(id, "Voting mode is already ON; no change is made.");	// TODO: Localize
		console_print(id, "If you are trying to disable voting, use command ^"dmap_cyclemode^".");	// TODO: Localize
		return PLUGIN_HANDLED;
	}
	cycle = 0;
	save_settings(id);
	return PLUGIN_HANDLED;
}

public dmap_banlastmaps(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_banlastmaps");
		return PLUGIN_HANDLED;
	}

	new arg[4];
	read_argv(1, arg, charsmax(arg));
	new banamount;
	banamount = str_to_num(arg);
	if (banamount >= 0 && banamount <= 99) {
		console_print(id, "The last %d maps will be banned. Changes take effect after a map change.", banamount);	// TODO: Localize
		if (banamount > ban_last_maps) {
			console_print(id, "Maps played more than %d maps ago will not be included in the ban.", ban_last_maps);	// TODO: Localize
		}
		ban_last_maps = banamount;
		save_settings(id);
	} else {
		//console_print(id, "You must specify a value between 0 and 99 for ^"dmap_banlastmaps^"");	// TODO: Localize
		console_print(id, "%L ^"dmap_banlastmaps^".", id, "DMAP_MUST_SPECIFY", 0, 99);
	}
	return PLUGIN_HANDLED;
}

public dmap_help(id) {
	//If there is 1 argument, handle it up here. Otherwise (0, 2+), just display general help below.
	if (read_argc() == 2) {	// 1 actual argument
		new arg[32];
		read_argv(1, arg, charsmax(arg));

		if (equali(arg, "list")) {
			console_print(id, "---- Say Commands: -------------------------------------------------------------");	// TODO: Localize
			console_print(id, "User:          currentmap; ff; listmaps; nextmap; nominate/vote <map>;");
			console_print(id, "User:          nominations/noms; recentmaps; rockthevote/rtv");
			console_print(id, "---- Console Commands: ---------------------------------------------------------");	// TODO: Localize
			console_print(id, "User:          dmap_help [command]; listmaps");
			console_print(id, "ADMIN_LEVEL_A: dmap_cancelvote; dmap_nominate <map>; dmap_rockthevote; dmap_status");
			console_print(id, "ADMIN_LEVEL_F: dmap_banlastmaps <n>; dmap_cyclemode; dmap_default;");
			console_print(id, "ADMIN_LEVEL_F: dmap_freeze <ON|OFF>; dmap_mapsnum <n>; dmap_mapsurl <URL|none>;");
			console_print(id, "ADMIN_LEVEL_F: dmap_maxcustom <n>; dmap_messages <n>; dmap_nominations <n>;");
			console_print(id, "ADMIN_LEVEL_F: dmap_quietmode <OFF|NOSOUND|SILENT>; dmap_rtvpercent <n>;");
			console_print(id, "ADMIN_LEVEL_F: dmap_rtvplayers <n>; dmap_rtvtoggle; dmap_rtvwait <n>; dmap_votemode");
			console_print(id, "---- Cvars: --------------------------------------------------------------------");	// TODO: Localize
			console_print(id, "amx_emptymap <map>; amx_extendmap_max <n>; amx_extendmap_step <n>;");
			console_print(id, "amx_idletime <n>; amx_staytime <n>; amx_vote_answers <0|1>; dmap_strict <0|1>;");
			console_print(id, "emptymap_allowed <0|1>; enforce_timelimit <0|1>; nominations_allowed <0|1>;");
			console_print(id, "weapon_delay <0|1>");
			console_print(id, "----  Use command ^"dmap_help <COMMAND>^" for help with a specific command. ----");	// TODO: Localize
			return PLUGIN_HANDLED;
		}

		// As rarely as this should get called, I think searching each time is better than storing the results in a Trie.
		new i, CommandName[32], Flags, CommandUsage[64];
		while(get_concmd(i++, CommandName, charsmax(CommandName), Flags, CommandUsage, charsmax(CommandUsage), ADMIN_SUPER_DMAP, 1)) {
			if (equali(arg, CommandName)) {
				console_print(id, "%L:  %s %s", id, "USAGE", CommandName, CommandUsage);
				return PLUGIN_HANDLED;
			}
		}
		console_print(id, "%L: ^"%s^"", id, "DMAP_UNKNOWN_COMMAND", arg);
		return PLUGIN_HANDLED;
	}

	// General help for when no (or too many) arguments are passed.
	console_print(id, "---- %L ----", id, "DMAP_HELP_TITLE", g_VERSION);
	if (cycle) {
		console_print(id, "The plugin is set to cycle mode. No vote will take place.");	// TODO: Localize
		return PLUGIN_HANDLED;
	} else {
		console_print(id, "Say ^"vote mapname^" ^"nominate mapname^" or just ^"mapname^" to nominate a map.");	// TODO: Localize
		console_print(id, "Say ^"listmaps^" for a list of maps you can nominate.");	// TODO: Localize
		if (enabled) {
			console_print(id, "Say ^"nominations^" to see a list of maps already nominated.");	// TODO: Localize
			console_print(id, "Say ^"rockthevote^" to try to start a vote.");	// TODO: Localize
		}
	}
	if (strlen(mapsurl) > 0) {
		c_p(id, print_console, "%L", id, "DMAP_DOWNLOAD_MAPS_URL", mapsurl);
	}
	console_print(id, "Visit http://forums.alliedmods.net/showthread.php?t=177180 for plugin support.");	// TODO: Localize
	console_print(id, "Use command ^"dmap_status^" to show plugin configuration.");	// TODO: Localize
	console_print(id, "Use command ^"dmap_help list^" to list available commands.");	// TODO: Localize

	return PLUGIN_HANDLED;
}

public dmap_status(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new sEmptyMap[32];
	get_pcvar_string(pEmptyMap, sEmptyMap, charsmax(sEmptyMap));

	console_print(id, "^t^t%L", id, "DMAP_STATUS_TITLE", g_VERSION);
	console_print(id, "--------------------------------------------------------------------------------");
	console_print(id, "dmap_banlastmaps: %d^t^t^t^tMode: %s", ban_last_maps, cycle ? "dmap_cyclemode" : "dmap_votemode");
	console_print(id, "dmap_freeze: %L^t^t^t^t^t^tdmap_mapsnum: %d", id, dofreeze ? "ON" : "OFF", mapssave);
	console_print(id, "dmap_maxcustom: %d^t^t^t^tdmap_messages: %d", maxcustnom, frequency);
	console_print(id, "dmap_nominations: %d^t^t^t^tdmap_quietmode: %s", maxnom, (quiet == 0) ? "OFF" : (quiet == 1) ? "NOSOUND" : "SILENT");
	console_print(id, "dmap_rtvpercent: %d^t^t^t^tdmap_rtvplayers: %d", floatround(rtvpercent * 100.0), minimum);
	console_print(id, "dmap_rtvwait: %d^t^t^t^t^t^tRockthevote: %L", minimumwait, id, enabled ? "ON" : "OFF");
	console_print(id, "amx_idletime: %d^t^t^t^t^t^t^tamx_emptymap: %s", get_cvar_num("amx_idletime"), sEmptyMap);
	console_print(id, "amx_extendmap_step: %d^t^tamx_extendmap_max: %d", get_pcvar_num(pExtendmapStep), floatround(get_pcvar_float(pExtendmapMax)));	// Is this a float for sure?
	console_print(id, "amx_show_activity: %d^t^t^t^tamx_staytime: %d", get_pcvar_num(pShowActivity), get_cvar_num("amx_staytime"));
	console_print(id, "amx_vote_answers: %d", get_cvar_num("amx_vote_answers"));
	console_print(id, "dmap_strict: %d^t^t^t^t^t^t^temptymap_allowed: %d", get_pcvar_num(pDmapStrict), get_pcvar_num(pEmptymapAllowed));
	console_print(id, "enforce_timelimit: %d^t^t^t^t^tmp_timelimit: %d", get_pcvar_num(pEnforceTimelimit), get_cvar_num("mp_timelimit"));	// Treat mp_timelimit as an integer
	console_print(id, "nominations_allowed: %d^t^t^t^tweapon_delay: %d", get_pcvar_num(pNominationsAllowed), get_pcvar_num(pWeaponDelay));
	console_print(id, "dmap_mapsurl: %s", mapsurl ? mapsurl : "(NONE)");
	console_print(id, "--------------------------------------------------------------------------------");

	new hldsVer[32];
	get_cvar_string("sv_version", hldsVer, charsmax(hldsVer));
	new hldsMod[16];
	get_modname(hldsMod, charsmax(hldsMod));
	new amxxRVer[11];
	get_amxx_verstring(amxxRVer, charsmax(amxxRVer));
	new sLang[3];
	get_cvar_string("amx_language", sLang, charsmax(sLang));
	new cLang[3];
	if (id) {
		get_user_info(id, "lang", cLang, charsmax(cLang));
	} else {
		cLang = "--";
	}
	new sDV[8];
	formatex(sDV, charsmax(sDV), "%L", -2, "DV");
	console_print(id, "[DMM] Config: %s%d%s%d/%s/%s#%s/%s", is_linux_server() ? "L" : "W", is_amd64_server() ? 64 : 32, is_dedicated_server() ? "D" : "L", get_cvar_num("sv_lan"), hldsVer, hldsMod, AMXX_VERSION_STR, amxxRVer);
	console_print(id, "[DMM] Config: %s/%s#%s/%s/%d#%d/%d#%d/%d/%d/%d", sLang, cLang, g_VERSION, sDV, DMAP_EXPECTED_DV, g_iConnectCount, FILE_LOGLEVEL, floatround(get_gametime()), get_timeleft(), floatround(oldtimelimit), floatround(get_cvar_float("mp_timelimit")));

	return PLUGIN_HANDLED;
}

change_custom_path() {
	new temp[64];	// Unless someone reports an issue, I think this is a sufficient size.
	formatex(temp, charsmax(temp), "%s/dmap", custompath);
	if (dir_exists(temp)) {
		copy(custompath, charsmax(custompath), temp);
	}
}

save_settings(myid) {

	new settings[64];
	formatex(settings, charsmax(settings), "%s/mapvault.dat", custompath);

	if (file_exists(settings)) {
		delete_file(settings);
	}
	new text[32], text2[128], rpercent, success = 1, usedany = 0;
	formatex(text2, charsmax(text2), ";To use comments simply use ;");
	if (!write_file(settings,text2)) {
		success = 0;
	}
	formatex(text2, charsmax(text2), ";Do not modify these variables; they are used by the Deagles' Map Manager plugin to save settings");

	if (!write_file(settings, text2)) {
		success = 0;
	}
	formatex(text2, charsmax(text2), ";If you delete this file, defaults will be restored.");
	if (!write_file(settings, text2)) {
		success = 0;
	}
	formatex(text2, charsmax(text2), ";If you make an invalid setting, that specific setting will restore to the default");
	if (!write_file(settings, text2)) {
		success = 0;
	}
	if (!enabled) {
		formatex(text, charsmax(text), "d");	//d for disabled
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (quiet != 0) {
		if (quiet == 1) {
			formatex(text, charsmax(text), "q1");	//q1 for NOSOUND
		} else {
			formatex(text, charsmax(text), "q2");	//q2 for SILENT
		}
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (!dofreeze || !bIsCstrike) {
		formatex(text, charsmax(text), "f");
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (cycle) {
		formatex(text, charsmax(text), "c");	//c for Cycle mode=on
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	rpercent = floatround(rtvpercent * 100.0);
	if (rpercent >= 3 && rpercent <= 100) {
		formatex(text, charsmax(text), "r %d", rpercent);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (ban_last_maps >= 0 && ban_last_maps <= 100) {
		formatex(text, charsmax(text), "b %d", ban_last_maps);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (mapssave >= 2 && mapssave <= 8) {
		formatex(text, charsmax(text), "m %d", mapssave);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (maxnom >= 0 && maxnom <= 8) {
		formatex(text, charsmax(text), "x %d", maxnom);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (maxcustnom >= 0 && maxcustnom <= mapssave) {
		formatex(text, charsmax(text), "y %d", maxcustnom);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (minimum > 0 && minimum <= 32) {
		formatex(text, charsmax(text), "p %d", minimum);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (minimumwait >= 0 && minimumwait <= 60) {
		formatex(text, charsmax(text), "w %d", minimumwait);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (frequency >= 2 && frequency <= 20) {
		formatex(text, charsmax(text), "fr %d", frequency);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (strlen(mapsurl) > 0) {
		formatex(text2, charsmax(mapsurl) + 2, "u %s", mapsurl);
		usedany = 1;
		if (!write_file(settings, text2)) {
			success = 0;
		}
	}
	if (usedany) {
		if (myid >= 0) {
			if (success) {
				console_print(myid, "[DMM] Settings saved successfully.");
				console_print(myid, "[DMM] Use the ^"dmap_status^" command to view current settings.");
			} else {
				console_print(myid, "[DMM] Unable to write to file %s", settings);
			}
		}
		if (!success) {
#if FILE_LOGLEVEL >= LOGLEVEL_ERROR
			log_to_file(logfilename, "[DMM] ERROR: Unable to write to file %s", settings);
#endif
			return 0;
		}
	} else {
		if (myid >= 0) {
			console_print(myid, "[DMM] Variables not valid, not saving to %s", settings);
		}
#if FILE_LOGLEVEL >= LOGLEVEL_WARN
		log_to_file(logfilename, "[DMM] WARN: Variables not valid, not saving to %s", settings);
#endif
		return 0;
	}
	return 1;
}

public dmap_mapsurl(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	if (id == 0) {
		announce_config_error("dmap_mapsurl");
		return PLUGIN_HANDLED;
	}

	new arg[96];
	read_args(arg, charsmax(arg));
	if (containi(arg, "http://") == 0 || containi(arg, "https://") == 0 || containi(arg, "ftp://") == 0 || containi(arg, "www.") == 0) {
		console_print(id, "You have changed the custom maps URL to %s", arg);
		mapsurl = arg;
		save_settings(id);
	} else if (containi(arg, "none") == 0) {
		console_print(id, "The custom maps URL will not be used or displayed.");
		mapsurl = "";
		save_settings(id);
	} else {
		console_print(id, "URL must start with ^"http://^", ^"https://^", ^"ftp://^" or ^"www.^" (Use ^"none^" to disable)");
	}

	return PLUGIN_HANDLED;
}

public dmap_default(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	set_defaults(id);
	return PLUGIN_HANDLED;	
}

public event_round_start() {
	isbetween = 0;
	isbuytime = 1;
	set_task(10.0, "now_safe_to_vote");
}

public event_round_end() {
	isbetween = 1;
}

public now_safe_to_vote() {
	isbuytime = 0;
}

public listmaps_override(id) {
	list_maps(id);
	return PLUGIN_HANDLED;
}

public votemap_override(id) {
	console_print(id, "%L", id, "DMAP_COMMAND_DISABLED");
	return PLUGIN_HANDLED;
}

public say_currentmap(id) {
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	c_p(id, print_chat, "[DMM] %L", id, "DMAP_CURRENT_MAP", mapname);
	return PLUGIN_HANDLED;
}

public say_nominations(id) {
	if (get_pcvar_num(pNominationsAllowed) == 0) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_NOMINATIONS_DISABLED");
		return PLUGIN_HANDLED;
	}
	if (mselected) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_VOTE_IN_PROGRESS");
	} else {
		if (nmaps_num == 0) {
			c_p(id, print_chat, "[DMM] %L", id, "DMAP_NO_MAPS_NOMINATED");
		} else {
			list_nominations(id);
		}
	}
	return PLUGIN_HANDLED;
}

public say_recentmaps(id) {
	if (bannedsofar <= 1) {
		c_p(id, print_chat, "[DMM] %L", id, "DMAP_RECENT_NONE");
		return PLUGIN_HANDLED;
	}

	new sMaps[192];
	for (new i=1; i < bannedsofar; i++) {	// Start at 1 to skip current map
		if (i == 1) {
			formatex(sMaps, 31, "%s", lastmaps[i]);
		} else {
			format(sMaps, charsmax(sMaps), "%s, %s", sMaps, lastmaps[i]);
		}		
	}
	c_p(id, print_chat, "[DMM] %L", id, "DMAP_RECENT_MAPS", sMaps);

	return PLUGIN_HANDLED;
}

public check_conflict() {
	new sDV[8], iDV, bRepeat;

	//repeat error over and over..
	if (is_plugin_loaded("Crab'sMapManager") > -1) {
		bRepeat = true;
		announce_conflict("crabmapmanager.amxx");
	}
	if (is_plugin_loaded("Galileo") > -1) {
		bRepeat = true;
		announce_conflict("galileo.amxx");
	}
	if (is_plugin_loaded("NextMap") > -1) {
		bRepeat = true;
		announce_conflict("nextmap.amxx");
	}
	if (is_plugin_loaded("Nextmap Chooser") > -1) {
		bRepeat = true;
		announce_conflict("mapchooser.amxx");
	}
	if (is_plugin_loaded("Nextmap Chooser 4") > -1) {
		bRepeat = true;
		announce_conflict("mapchooser4.amxx");
	}

	// Using -2 for the language key seems to default to en, even with amx_mldebug set.
	// This is a hack, but it works.
	// ML_NOTFOUND will return 0 for version, so additional error handling isn't needed.
	formatex(sDV, charsmax(sDV), "%L", -2, "DV");
	iDV = str_to_num(sDV);

	// Allow for 9 newer versions of dictionary file before plugin recompile is needed.
	if ((iDV < DMAP_EXPECTED_DV) || (iDV > (DMAP_EXPECTED_DV + 9))) {
		bRepeat = true;
		console_print(0, "[DMM] INVALID DICTIONARY FILE! Current version: %d. Expected version: %d to %d.", iDV, DMAP_EXPECTED_DV, DMAP_EXPECTED_DV + 9);
		c_p(0, print_chat, "[DMM] INVALID DICTIONARY FILE! Current version: %d. Expected version: %d to %d.", iDV, DMAP_EXPECTED_DV, DMAP_EXPECTED_DV + 9);
#if FILE_LOGLEVEL >= LOGLEVEL_FATAL
		log_to_file(logfilename, "[DMM] FATAL: INVALID DICTIONARY FILE! Current version: %d. Expected version: %d to %d.", iDV, DMAP_EXPECTED_DV, DMAP_EXPECTED_DV + 9);
#endif
	}

	if (bRepeat) {
		set_task(10.0, "check_conflict", DMAP_TASKID_CONFLICT);
	}
	return PLUGIN_HANDLED;
}

announce_conflict(sPlugin[]) {
	console_print(0, "[DMM] CONFLICT DETECTED! Disable %s in plugins.ini.", sPlugin);
	c_p(0, print_chat, "[DMM] CONFLICT DETECTED! Disable %s in plugins.ini.", sPlugin);
#if FILE_LOGLEVEL >= LOGLEVEL_FATAL
		log_to_file(logfilename, "[DMM] FATAL: CONFLICT DETECTED! Disable %s in plugins.ini.", sPlugin);
#endif
}

announce_config_error(sCommand[]) {
	console_print(0, "[DMM] ERROR: The %s command does not belong in any config file.", sCommand);
	console_print(0, "[DMM] If you really want to run this command, do it from a client console.");
}

public say_ff(id) {
	c_p(id, print_chat, "[DMM] %L: %L", id, "DMAP_FRIEND_FIRE", id, get_cvar_num("mp_friendlyfire") ? "ON" : "OFF");
	return PLUGIN_CONTINUE;
}

//client_print() in amxmodx.cpp calls UTIL_ClientPrint() in util.cpp.
//UTIL_ClientPrint uses MSG_ONE or MSG_BROADCAST.
//UTIL_ClientPrint truncates all messages to 190 characters (for good reason).
//The client resolution determines how many characters actually get printed.

//Current behavior:
//	0/print_chat:		Print to chat of all players with the correct locale
//	id/print_chat:		Print to chat of player #id with the correct locale
//	0/print_console:	Print to console of all players with a common (possibly incorrect) locale
//	id/print_console:	Print to console of player #id with the correct locale
stock c_p(id, type, const message[], any:...) {
	new sMessage[192];
	new iActualLen;
	
	static gmsgSayText;
	if (!gmsgSayText) { gmsgSayText = get_user_msgid("SayText"); }

	if ((id == 0) && (type == print_chat)) {

		new bool:bReplaceID;

		// I am not proud of how this is implemented. I would prefer to use a loop to recursively call this function with IDs instead of id=0.
		// This way, the message_begin...message_end code would only need to be included once.

		// Since there are no broadcast chat messages with multiple %L's, we just check the first possible argument.
		// Without this shortcut, we'd have to verify every argument and store the %L occurences in an array.
		//   Then, within the client loop, we'd have another loop to replace every LANG_PLAYER occurence.
		if ((getarg(3) == LANG_PLAYER) && (numargs() >= 5)) {
			new key[64], iPos;	// TODO: Make static?
			while ((key[iPos] = getarg(4, iPos++))) { /* Empty loop to load the argument one character at a time */ }
			if (GetLangTransKey(key) != TransKey_Bad) {
				bReplaceID = true;
			}
		}

		new Clients[32], iNum;	// TODO: Make static?
		get_players(Clients, iNum, "ch");
		for (new i = 0; i < iNum; i++) {	// Only loop through connected slots

			// Replace LANG_PLAYER with the player's ID and format the string
			if (bReplaceID == true) {
				setarg(3, _, Clients[i]);
			}
			iActualLen = vformat(sMessage, 190, message, 4);

			message_begin(MSG_ONE, gmsgSayText, _, Clients[i]);
			write_byte(type);
			write_string(sMessage);
			message_end();
#if FILE_LOGLEVEL >= LOGLEVEL_TRACE
			log_to_file(logfilename, "[DMM] TRACE: Broadcast to: %i", Clients[i]);
			log_to_file(logfilename, "%i:%s", Clients[i], sMessage);
#endif
		}

		return iActualLen;
	}

	iActualLen = vformat(sMessage, 190, message, 4);	// Truncate to 190 printable characters (bytes)

	switch (type) {
		// I have found no way to modify print_center to display longer strings, so I am purposely not supporting it.
		case print_chat: {
			//static gmsgSayText;
			//if (!gmsgSayText) { gmsgSayText = get_user_msgid("SayText"); }

			// message_begin() in messages.cpp makes the right call based on the first parameter. It doesn't hurt to pass _ and id.
			message_begin(id ? MSG_ONE : MSG_BROADCAST, gmsgSayText, _, id);	// SayText is the secret to allowing longer chat strings.
			write_byte(type);
			write_string(sMessage);
			message_end();
		}
		case print_console, print_notify: {
			static gmsgTextMsg;
			if (!gmsgTextMsg) { gmsgTextMsg = get_user_msgid("TextMsg"); }

			sMessage[iActualLen++] = '^n';	// Console newlines are added server-side
			sMessage[iActualLen] = 0;	// Funny things happen without this

			new iCounter, sSmallChunk[128], iChunk2Begin = 127;

			while (iCounter < iActualLen) {

				if ((iChunk2Begin < iActualLen) && (iChunk2Begin > iCounter)) {	// Make sure a multi-byte character isn't split
					// Double-byte UTF-8 chars have first byte 0xC2-0xDF, triple: 0xE0-0xEF
					// If someone shows me a valid quad-byte translation, I'll add support for it.
					if (((sMessage[iChunk2Begin - 1] & 0xFF) >= 0xC2) && ((sMessage[iChunk2Begin - 1] & 0xFF) <= 0xEF)) {
						iChunk2Begin -= 1;
					} else if ((((sMessage[iChunk2Begin - 2] & 0xFF) >= 0xE0) && ((sMessage[iChunk2Begin - 2] & 0xFF) <= 0xEF))) {
						iChunk2Begin -= 2;
					}
				}

				copy(sSmallChunk, iChunk2Begin, sMessage[iCounter]);	// If string is too long, only take the first chunk.

				message_begin(id ? MSG_ONE : MSG_BROADCAST, gmsgTextMsg, _, id);	// TextMsg limits string length
				write_byte(type);
				write_string(sSmallChunk);
				message_end();

				iCounter += iChunk2Begin;
			}
		}
	}

	return iActualLen;	// This value might not match the value returned by AMXModX's print_chat function.
}

public plugin_init() {

	register_plugin(g_PLUGIN, g_VERSION, g_AUTHOR);
	register_dictionary("common.txt");
	register_dictionary("deagsmapmanager.txt");

	get_configsdir(custompath, charsmax(custompath));
	change_custom_path();

	//g_MaxPlayers = get_maxplayers();

	check_conflict();	// Check for problems immediately

	register_clcmd("say", "handle_say", 0, "- Say: vote mapname, nominate mapname, or just ^"MAP_NAME^" to nominate a map");
	register_clcmd("say currentmap", "say_currentmap", 0, "- Show name of the current map");
	register_clcmd("say ff", "say_ff", 0, "- Display friendly fire status");
	register_clcmd("say listmaps", "list_maps", 0, "- List all maps in the console");
	register_clcmd("say nextmap", "say_nextmap", 0, "- Show next map information to players");
	register_clcmd("say nominations", "say_nominations", 0, "- Show names of maps nominated for next vote");
	register_clcmd("say noms", "say_nominations", 0, "- Show names of maps nominated for next vote");
	register_clcmd("say recentmaps", "say_recentmaps", 0, "- Show names of recently played maps");
	register_clcmd("say rockthevote", "rock_the_vote", 0, "- Rock the vote");
	register_clcmd("say rtv", "rock_the_vote", 0, "- Rock the vote");
	register_clcmd("votemap", "votemap_override", 0, "- Override for votemap command in GoldSrc engine");
	register_concmd("dmap_help", "dmap_help", 0, "- Show on-screen help information about Map Plugin");
	register_concmd("dmap_status", "dmap_status", ADMIN_DMAP, "- Show settings/status of the map management variables");
	register_concmd("dmap_votemode", "dmap_votemode", ADMIN_SUPER_DMAP, "- Enable voting (This is default mode)");
	register_concmd("dmap_cyclemode", "dmap_cyclemode", ADMIN_SUPER_DMAP, "- Disable voting (To restore voting use dmap_votemode)");
	register_concmd("dmap_banlastmaps", "dmap_banlastmaps", ADMIN_SUPER_DMAP, "<n> - Ban the last N maps played from being voted (0-100)");
	register_concmd("dmap_quietmode", "dmap_quietmode", ADMIN_SUPER_DMAP, "<OFF|NOSOUND|SILENT> - Configure messages: OFF=Sound/text, NOSOUND=Text, SILENT=Minimal text");
	register_concmd("dmap_freeze", "dmap_freeze", ADMIN_SUPER_DMAP, "<ON|OFF> - Enable/Disable freeze & weapon drop at end of round");
	register_concmd("dmap_messages", "dmap_messages", ADMIN_SUPER_DMAP, "<n> - Set time interval in minutes between messages (2-60)");
	register_concmd("dmap_rtvtoggle", "dmap_rtvtoggle", ADMIN_SUPER_DMAP, "- Toggle ability of players to use ^"rockthevote^"");
	register_concmd("dmap_rockthevote", "admin_rockit", ADMIN_DMAP, "- Allows admins to force a vote");
	register_concmd("amx_rockthevote", "admin_rockit", ADMIN_DMAP, "- Allows admins to force a vote");
	register_concmd("amx_rtv", "admin_rockit", ADMIN_DMAP, "- Allows admins to force a vote");
	register_concmd("dmap_rtvpercent", "dmap_rtvpercent", ADMIN_SUPER_DMAP, "<n> - Set the percent (3-100) of players needed for a rtv");
	register_concmd("dmap_rtvplayers", "dmap_rtvplayers", ADMIN_SUPER_DMAP, "<n> - Set the minimum number of players needed to ^"rockthevote^"");
	register_concmd("dmap_rtvwait", "dmap_rtvwait", ADMIN_SUPER_DMAP, "<n> - Set time in minutes before ^"rockthevote^" can occur (0-60)");
	register_concmd("dmap_default", "dmap_default", ADMIN_SUPER_DMAP, "- Restore settings to default");
	register_concmd("dmap_mapsurl", "dmap_mapsurl", ADMIN_SUPER_DMAP, "<URL|none> - Specify what website to get custom maps from");
	register_concmd("dmap_mapsnum", "dmap_mapsnum", ADMIN_SUPER_DMAP, "<n> - Set number of maps in vote (will not take effect until next map) (0-8)");
	register_concmd("dmap_nominations", "dmap_nominations", ADMIN_SUPER_DMAP, "<n> - Set maximum number of nominations for each person (0-8)");
	register_concmd("dmap_maxcustom", "dmap_maxcustom", ADMIN_SUPER_DMAP, "<n> - Set maximum number of custom nominations that may be made (0-8)");
	register_concmd("dmap_cancelvote", "dmap_cancel_vote", ADMIN_DMAP, "- Cancel the rocked vote");
	register_concmd("dmap_nominate", "dmap_nominate", ADMIN_DMAP, "<map> - Force nomination of a map by an admin");
	register_concmd("listmaps", "listmaps_override", 0, "- List all maps in the console");

	register_logevent("event_round_start", 2, "0=World triggered", "1=Round_Start");
	register_logevent("event_round_end", 2, "0=World triggered", "1=Round_End");

	register_event("30", "event_intermission", "a");	// SVC_INTERMISSION = 30
#if FILE_LOGLEVEL > LOGLEVEL_NONE
	get_time("dmaplog%m%d.log", logfilename, charsmax(logfilename));
#endif

	pDmapStrict = register_cvar("dmap_strict", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pEmptyMap = register_cvar("amx_emptymap", "de_dust2", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pEmptymapAllowed = register_cvar("emptymap_allowed", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pEnforceTimelimit = register_cvar("enforce_timelimit", "0", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pExtendmapMax = register_cvar("amx_extendmap_max", "90", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pExtendmapStep = register_cvar("amx_extendmap_step", "15", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	register_cvar("amx_idletime", "5", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);			// No pointer; only used once
	pNominationsAllowed = register_cvar("nominations_allowed", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	pShowActivity = register_cvar("amx_show_activity", "2", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	register_cvar("amx_staytime", "300", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);			// No pointer; only used once
	pWeaponDelay = register_cvar("weapon_delay", "1", FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);

	staytime = get_cvar_num("amx_staytime");
	IdleTime = get_cvar_num("amx_idletime");

	bIsCstrike = (cstrike_running() == 1);

	register_cvar("Deags_Map_Manage", g_VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);

	if (bIsCstrike) {
		register_event("TeamScore", "team_score", "a");
		dofreeze = 1;
	}

	set_task(3.0, "ban_some_maps");	//reads from lastmapsplayed.txt and stores into global array
	//set_task(2.0, "get_listing");	//loads mapcycle / allmaps.txt
	set_task(14.0, "load_default_maps");	//loads standardmaps.ini
	set_task(15.0, "ask_for_next_map", DMAP_TASKID_ASK_FOR_NEXT, "", 0, "b");
	set_task(5.0, "loop_messages", DMAP_TASKID_LOOP_MESSAGES, "", 0, "b");

	oldtimelimit = get_cvar_float("mp_timelimit");
	get_localinfo("amx_lastmap", last_map, charsmax(last_map));
	set_localinfo("amx_lastmap", "");
	set_task(1.0, "timer", DMAP_TASKID_TIMER, "", 0, "b");

	new path[64];
	formatex(path, charsmax(path), "%s/mapvault.dat", custompath);
	if (!load_settings(path)) {
		set_defaults(-1);
	}
	formatex(path, charsmax(path), "%s/map_manage_help.htm", custompath);
	if (file_exists(path)) {
		delete_file(path);	// Remove old HTML help
	}

	atstart = 0;
	register_menu(DMAP_MENU_TITLE, (-1 ^ (-1 << (maps_to_select + 2))), "vote_count");
}
