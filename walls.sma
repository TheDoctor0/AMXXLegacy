#include <amxmodx>
#include <fakemeta>
#include <engine>

#define PLUGIN "Map Blocking Walls"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#pragma ctrlchar			'\'
#pragma semicolon			1

#define charm charsmax
/***** SETTING DEFINE START *****/

#define STATE_USE
#define MOVE_COORD_DUST2
#define WEAPONBOX_PUSH
#define WALLS_TOUCHMESSAGE

#if defined WALLS_TOUCHMESSAGE
	#define MESSAGE_TIMEWAIT	5.5
#endif

#define MESSAGE_MAP_STATUS		-1.0, 0.8
#define COLOR_MAP_CLOSE			255,	0, 0
#define COLOR_MAP_OPEN			0, 255, 0

#define STRONG_PUSH			15.0

/***** SETTING DEFINE END *****/

#define TASK_MAP_START		8590
#define MAX_PLAYERS			32
#define CLASSNAME_WALL			"info_wall"
#define CLASSNAME_WALL_PERMANENT			"info_wall_permanent"
#define SPRITE_WALL			"sprites/walls.spr"

#define IsUserTeam(%0)			(1 <= get_pdata_int(%0,114) <= 2)
#define IsUserFlags(%0,%1)		(get_user_flags(%0) & %1)
#define IsUserAValid(%0)		(1 <= %0 <= g_pServerVar[m_iMaxpl] && is_user_alive(%0))

#define CheckPlayers			(g_pServerVar[m_iOnline] >= checkNumPlayers())

#define Vector(%0,%1,%2)		(Float:{%0,%1,%2})
#define VectorCmp(%0,%1)		(%0[x] == %1[x] && %0[y] == %1[y] && %0[z] == %1[z])
#define VectorDT(%0,%1,%2,%3)		(!(%0[x] > %3[x] || %1[x] < %2[x]) && !(%0[y] > %3[y] || %1[y] < %2[y]) && !(%0[z] > %3[z] || %1[z] < %2[z]))

#if defined STATE_USE
#define STATEMENT_FALLBACK(%0,%1,%2)	public %0()<>{return %1;} public %0()<%2>{return %1;}
#endif

enum _:coord_s {
	Float:x,
	Float:y,
	Float:z
};

enum _:status_s {
	box_open = 0,
	box_close,
};

enum server_box_s {
	m_fOrigin,
	m_fAngles,
	m_fMins,
	m_fMaxs
};

enum _:server_info_s {
	m_iNone,
	m_iBox,
	m_iCopy,
	m_iType,
	m_iEntid,
	m_iSetting,
	m_iSolid,
	m_iMaxpl,
	m_szFile[64],
	m_iThink,
	m_iThinkPerm,
	bool:m_bAdvanced,
	m_iOnline,
	m_iSprite,
	status_s:m_iStatus,
	m_szMap[32],
	Float:m_fWait[MAX_PLAYERS + 1],
	Float:m_fScale
};

new g_pServerVar[server_info_s];
new Float:g_pServerBox[server_box_s][coord_s];
new g_Round;

public plugin_precache() {
	precache_model(SPRITE_WALL);
	
	get_mapname(g_pServerVar[m_szMap],charm(g_pServerVar[m_szMap]));

#if defined STATE_USE
	#if defined MOVE_COORD_DUST2
	if(!strcmp(g_pServerVar[m_szMap],"de_dust2"))
		state stpfnSpawn:Enabled;
	#endif
#endif
}

//native autoupdater_register_plugin();

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	//autoupdater_register_plugin();

	register_clcmd("say /walls","cmdMenuBox",ADMIN_RCON,"<Menu tworzenia scian>");
	register_clcmd("say /sciany","cmdMenuBox",ADMIN_RCON,"<Menu tworzenia scian>");

	register_menucmd(register_menuid("Menu Glowne"),0x3FF,"mainEditHandler");
	register_menucmd(register_menuid("Menu Ustawien"),0x3FF,"settingHandler");
	register_menucmd(register_menuid("Menu Wlasciwosci"),0x3FF,"propertiesHandler");

	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	
	register_event("HLTV","RoundNew","a","1=0","2=0");

	register_dictionary("walls.txt");

	g_pServerVar[m_iMaxpl] = get_maxplayers();

	loadConfig();
}
loadConfig() {
#if defined STATE_USE
	#if defined MOVE_COORD_DUST2
	state stpfnSpawn:Disabled;
	#endif
#endif
	get_localinfo("amxx_configsdir",g_pServerVar[m_szFile],charm(g_pServerVar[m_szFile]));

	add(g_pServerVar[m_szFile],charm(g_pServerVar[m_szFile]),"/walls/");
	mkdir(g_pServerVar[m_szFile]);

	formatex(g_pServerVar[m_szFile],charm(g_pServerVar[m_szFile]),"%s%s.ini",g_pServerVar[m_szFile],g_pServerVar[m_szMap]);

	if(file_exists(g_pServerVar[m_szFile])) {
		g_pServerVar[m_iNone] = boxLoad();

		showBox((g_pServerVar[m_iStatus] = status_s:box_open), false);

		#if defined WALLS_TOUCHMESSAGE
			register_touch(CLASSNAME_WALL,"player","pfnTouch");
			register_touch(CLASSNAME_WALL_PERMANENT,"player","pfnTouchPerm");
		#endif
		#if defined WEAPONBOX_PUSH
			register_touch("weaponbox",CLASSNAME_WALL,"pfnTouchWeaponBox");
			register_touch("weaponbox",CLASSNAME_WALL_PERMANENT,"pfnTouchWeaponBoxPerm");
		#endif
	}
}

public GameCommencing()
	g_Round = 0;

public RoundNew() {
	remove_task(TASK_MAP_START);
	
	CheckWalls();
	
	if(++g_Round == 1)
		set_task(5.0, "CheckWalls", TASK_MAP_START, .flags = "a", .repeat = 3);
}

public CheckWalls()
{
	if(CheckPlayers) {
		if(g_pServerVar[m_iStatus] == status_s:box_open)
			showBox((g_pServerVar[m_iStatus] = status_s:box_close),true);
	}
	else {
		remove_task(TASK_MAP_START);
		
		if(g_pServerVar[m_iStatus] == status_s:box_close)
			showBox((g_pServerVar[m_iStatus] = status_s:box_open),true);
	}
}

#if defined MOVE_COORD_DUST2
public pfn_spawn(ent)
#if defined STATE_USE
	<stpfnSpawn:Enabled>
#endif
{
	#if !defined STATE_USE
	if(strcmp(g_pServerVar[m_szMap],"de_dust2") != 0)
		return 0;
	#endif
	static classname[32];
	entity_get_string(ent,EV_SZ_classname,classname,charm(classname));
	if(!strcmp(classname,"info_player_deathmatch")) {
		static Float:vec[coord_s];
		entity_get_vector(ent,EV_VEC_origin,vec);

		static Float:looking[][coord_s] = {
			{-1024.0, -800.0, 176.0},
			{-1024.0, -704.0, 176.0},
			{-1024.0, -896.0, 192.0},

			{-826.0, -970.0, 200.0},
			{-726.0, -970.0, 200.0},
			{-626.0, -970.0, 200.0}
		};

		for(new b = 0; b < sizeof(looking) / 2; b++) {
			if(VectorCmp(vec,looking[b])) {
				entity_set_vector(ent,EV_VEC_origin,looking[b + 3]);
				break;
			}
		}
	}
	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfn_spawn,0,stpfnSpawn:Disabled)
#endif
#endif

public pfnThink(ent)
#if defined STATE_USE
	<stpfnThink:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(g_pServerVar[m_iEntid]) || !is_valid_ent(ent) || g_pServerVar[m_iEntid] != ent)
		return 0;
	#else
	if(g_pServerVar[m_iEntid] != ent)
		return 0;
	#endif
	static Float:b_mins[coord_s],Float:b_maxs[coord_s],Float:b_origin[coord_s];
	entity_get_vector(ent,EV_VEC_origin,b_origin);
	entity_get_vector(ent,EV_VEC_mins,b_mins);
	entity_get_vector(ent,EV_VEC_maxs,b_maxs);

	engfunc(EngFunc_MessageBegin,MSG_BROADCAST,SVC_TEMPENTITY,b_origin);
	write_byte(TE_BOX);
	engfunc(EngFunc_WriteCoord,(b_mins[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_mins[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_mins[z] += b_origin[z]));
	engfunc(EngFunc_WriteCoord,(b_maxs[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_maxs[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_maxs[z] += b_origin[z]));
	write_short(2);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();

	return entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnThink,0,stpfnThink:Disabled)
#endif

public pfnThinkPerm(ent)
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(g_pServerVar[m_iEntid]) || !is_valid_ent(ent) || g_pServerVar[m_iEntid] != ent)
		return 0;
	#else
	if(g_pServerVar[m_iEntid] != ent)
		return 0;
	#endif
	static Float:b_mins[coord_s],Float:b_maxs[coord_s],Float:b_origin[coord_s];
	entity_get_vector(ent,EV_VEC_origin,b_origin);
	entity_get_vector(ent,EV_VEC_mins,b_mins);
	entity_get_vector(ent,EV_VEC_maxs,b_maxs);

	engfunc(EngFunc_MessageBegin,MSG_BROADCAST,SVC_TEMPENTITY,b_origin);
	write_byte(TE_BOX);
	engfunc(EngFunc_WriteCoord,(b_mins[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_mins[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_mins[z] += b_origin[z]));
	engfunc(EngFunc_WriteCoord,(b_maxs[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_maxs[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_maxs[z] += b_origin[z]));
	write_short(2);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();

	return entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);
}

#if defined WEAPONBOX_PUSH
public pfnTouchWeaponBox(ent,id)
#if defined STATE_USE
	<stMode:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !is_valid_ent(id)) // why do it?!
		return 0;
	#endif
	new Float:velocity[3];
	get_global_vector(GL_v_forward,velocity);

	velocity[x] = -velocity[x] * STRONG_PUSH;
	velocity[y] = -velocity[y] * STRONG_PUSH;
	velocity[z] = -velocity[z] * STRONG_PUSH;

	entity_set_vector(ent,EV_VEC_velocity,velocity);

	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnTouchWeaponBox,0,stMode:Disabled)
#endif

public pfnTouchWeaponBoxPerm(ent,id)
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !is_valid_ent(id)) // why do it?!
		return 0;
	#endif
	new Float:velocity[3];
	get_global_vector(GL_v_forward,velocity);

	velocity[x] = -velocity[x] * STRONG_PUSH;
	velocity[y] = -velocity[y] * STRONG_PUSH;
	velocity[z] = -velocity[z] * STRONG_PUSH;

	entity_set_vector(ent,EV_VEC_velocity,velocity);

	return 0;
}
#endif

#if defined WALLS_TOUCHMESSAGE
public pfnTouch(ent,id)
#if defined STATE_USE
	<stMode:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !IsUserAValid(id))
		return 0;
	#else
	if(!is_user_alive(id))
		return 0;
	#endif

	static Float:currentTime;
	currentTime = get_gametime();
	if(currentTime > g_pServerVar[m_fWait][id]) {
		g_pServerVar[m_fWait][id] = _:(currentTime + MESSAGE_TIMEWAIT);
		return client_print_color(id,id,"%L %L",id,"WALLS_PREFIX",id,"WALLS_MESSAGE_TOUCH");
	}
	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnTouch,0,stMode:Disabled)
#endif

public pfnTouchPerm(ent,id)
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !IsUserAValid(id))
		return 0;
	#else
	if(!is_user_alive(id))
		return 0;
	#endif

	static Float:currentTime;
	currentTime = get_gametime();
	if(currentTime > g_pServerVar[m_fWait][id]) {
		g_pServerVar[m_fWait][id] = _:(currentTime + MESSAGE_TIMEWAIT);
		return client_print_color(id,id,"%L %L",id,"WALLS_PREFIX",id,"WALLS_MESSAGE_TOUCH_PERM");
	}
	return 0;
}
#endif

public cmdMenuBox(id,level,cid) {
	if(!IsUserFlags(id,level))
		return 0;

	if(!g_pServerVar[m_iThink])
		g_pServerVar[m_iThink] = register_think(CLASSNAME_WALL,"pfnThink");
	
	if(!g_pServerVar[m_iThinkPerm])
		g_pServerVar[m_iThinkPerm] = register_think(CLASSNAME_WALL_PERMANENT,"pfnThink");

	return showMainEditMenu(id);
}
showMainEditMenu(id) {
	new buf[512];
	formatex(buf,charm(buf),
		"%L",id,"WALLS_DEV_MENU_MAIN",
		g_pServerVar[m_iBox],
		g_pServerVar[m_iEntid] > 0 ? "\\d" : "\\w",
		g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
		g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
		id,g_pServerVar[m_iEntid] == 0 ? "WALLS_DEV_CHANGE" : "WALLS_DEV_SAVE",
		g_pServerVar[m_iEntid] == 0 ? "\\d" : "\\w",
		(g_pServerVar[m_iBox] == 0 || g_pServerVar[m_iEntid] > 0) ? "\\d" : "\\w",
		g_pServerVar[m_iCopy] == 0 ? "\\d" : "\\w",
		(g_pServerVar[m_iBox] == 0 || g_pServerVar[m_iEntid] > 0) ? "\\d" : "\\w"
	);
	return show_menu(id,0x3FF,buf,-1,"Menu Glowne");
}
public mainEditHandler(id,key) {
	switch(key)
	{
		case 0:
		{
			if(g_pServerVar[m_iEntid] > 0) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_5");
				goto _jmp0;
			}
			new Float:p_origin[coord_s],ent = createWall(.bParse = false);
			entity_get_vector(id,EV_VEC_origin,p_origin);

			g_pServerVar[m_iBox]++;
			g_pServerVar[m_iEntid] = ent;
			p_origin[z] += 32.0;

			#if defined STATE_USE
				state stpfnThink:Enabled;
			#endif

			entity_set_vector(ent,EV_VEC_origin,p_origin);
			entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));
		}
		case 1:
		{
			new ent,dummy;
			get_user_aiming(id,ent,dummy);
			if(is_valid_ent(ent)) {
				new classname[32];
				entity_get_string(ent,EV_SZ_classname,classname,charm(classname));
				if(!strcmp(classname,CLASSNAME_WALL) || !strcmp(classname,CLASSNAME_WALL_PERMANENT)) {
					if(--g_pServerVar[m_iBox] < 0)
						g_pServerVar[m_iBox] = 0;

					if(g_pServerVar[m_iEntid] == ent)
						g_pServerVar[m_iEntid] = 0;

					remove_entity(ent);
					client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_1","SOLID_BBOX");
				}
				else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");
			}
			else if(is_valid_ent(g_pServerVar[m_iEntid])) {
				new ent = g_pServerVar[m_iEntid];
				new Float:v_absmins[coord_s],Float:v_absmaxs[coord_s],Float:e_absmin[coord_s],Float:e_absmax[coord_s];

				entity_get_vector(id,EV_VEC_absmin,v_absmins);
				entity_get_vector(id,EV_VEC_absmax,v_absmaxs);

				v_absmins[x] += 1.0;
				v_absmins[y] += 1.0;
				v_absmins[z] += 3.0;

				v_absmaxs[x] -= 1.0;
				v_absmaxs[y] -= 1.0;
				v_absmaxs[z] -= 17.0;

				entity_get_vector(ent,EV_VEC_absmin,e_absmin);
				entity_get_vector(ent,EV_VEC_absmax,e_absmax);

				if(VectorDT(e_absmin,e_absmax,v_absmins,v_absmaxs)) {

					g_pServerVar[m_iBox]--;
					g_pServerVar[m_iEntid] = 0;
					client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_1",(entity_get_int(ent,EV_INT_solid) == SOLID_NOT) ? "SOLID_NOT" : "SOLID_BBOX");
					remove_entity(ent);
				}
			}
			else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");

			#if defined STATE_USE
			if(!g_pServerVar[m_iEntid])
				state stpfnThink:Disabled;

			#endif
		}
		case 2:
		{
			if(is_valid_ent(g_pServerVar[m_iEntid])) {
				#if defined STATE_USE
					state stpfnThink:Disabled;
				#endif
				entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,SOLID_BBOX);
				entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_rendercolor,Vector(0.0,0.0,0.0));
				entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

				g_pServerVar[m_iEntid] = 0;
				g_pServerVar[m_fScale] = _:0.250;

				g_pServerBox[m_fMaxs][x] = 32.0;
				g_pServerBox[m_fMaxs][y] = 32.0;
				g_pServerBox[m_fMaxs][z] = 32.0;

				g_pServerBox[m_fMins][x] = -32.0;
				g_pServerBox[m_fMins][y] = -32.0;
				g_pServerBox[m_fMins][z] = -32.0;

				g_pServerBox[m_fOrigin][x] = 0.0;
				g_pServerBox[m_fOrigin][y] = 0.0;
				g_pServerBox[m_fOrigin][z] = 0.0;

				g_pServerBox[m_fAngles][x] = 0.0;
				g_pServerBox[m_fAngles][y] = 0.0;
				g_pServerBox[m_fAngles][z] = 0.0;

				client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_4");
			}
			else {
				new ent,body;
				get_user_aiming(id,ent,body);
				if(is_valid_ent(ent)) {
					new classname[32];
					entity_get_string(ent,EV_SZ_classname,classname,charm(classname));
					if(!strcmp(classname,CLASSNAME_WALL) || !strcmp(classname,CLASSNAME_WALL_PERMANENT)) {
						#if defined STATE_USE
							state stpfnThink:Enabled;
						#endif
						g_pServerVar[m_iEntid] = ent;

						entity_get_vector(ent,EV_VEC_mins,g_pServerBox[m_fMins]);
						entity_get_vector(ent,EV_VEC_maxs,g_pServerBox[m_fMaxs]);

						entity_get_vector(ent,EV_VEC_origin,g_pServerBox[m_fOrigin]);
						entity_get_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);

						g_pServerVar[m_fScale] = _:(entity_get_float(ent,EV_FL_scale));

						entity_set_int(ent,EV_INT_solid,SOLID_NOT);
						entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);
						entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));
						entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);
						client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_5");
					}
					else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");
				}
				else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");
			}
		}
		case 3:
		{
			if(!g_pServerVar[m_iEntid]) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_4");
				goto _jmp0;
			}
			return showPropertiesMenu(id);
		}
		case 4:
		{
			return showSettingsMenu(id);
		}
		case 5:
		{
			if(g_pServerVar[m_iEntid] > 0) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_5");
				goto _jmp0;
			}
			new ent,dummy;
			get_user_aiming(id,ent,dummy);
			if(is_valid_ent(ent)) {
				new classname[32];
				entity_get_string(ent,EV_SZ_classname,classname,charm(classname));
				if(!strcmp(classname,CLASSNAME_WALL) || !strcmp(classname,CLASSNAME_WALL_PERMANENT))
				{
					if(g_pServerVar[m_iCopy] == ent) {
						client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_2");
						goto _jmp0;
					}
					g_pServerVar[m_iCopy] = ent;
					client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_2");
				}
				else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");
			}
			else client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_1");
		}
		case 6:
		{
			if(g_pServerVar[m_iEntid] > 0) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_5");
				goto _jmp0;
			}
			if(!is_valid_ent(g_pServerVar[m_iCopy])) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_3");
				goto _jmp0;
			}

			new Float:p_origin[coord_s],ent = createWall(.bParse = false);
			entity_get_vector(id,EV_VEC_origin,p_origin);

			g_pServerVar[m_iBox]++;
			g_pServerVar[m_iEntid] = ent;
			p_origin[z] += 32.0;

			#if defined STATE_USE
				state stpfnThink:Enabled;
			#endif

			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_mins,g_pServerBox[m_fMins]);
			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_maxs,g_pServerBox[m_fMaxs]);

			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_angles,g_pServerBox[m_fAngles]);

			g_pServerVar[m_fScale] = _:(entity_get_float(g_pServerVar[m_iCopy],EV_FL_scale));
			g_pServerVar[m_iSprite] = floatround(entity_get_float(g_pServerVar[m_iCopy],EV_FL_frame));

			entity_set_vector(ent,EV_VEC_origin,p_origin);
			entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));

			entity_set_vector(ent,EV_VEC_mins,g_pServerBox[m_fMins]);
			entity_set_vector(ent,EV_VEC_maxs,g_pServerBox[m_fMaxs]);
			entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);

			new iFlags = entity_get_int(g_pServerVar[m_iCopy],EV_INT_effects);

			entity_set_int(ent,EV_INT_effects,iFlags);
			entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
			entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));
		}
		case 8:
		{
			if(!g_pServerVar[m_iBox])
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_4");

			else if(g_pServerVar[m_iEntid])
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_5");

			else boxSave(id);
		}
		case 9:
		{
			return 0;
		}
	}
	_jmp0:
	return showMainEditMenu(id);
}
showPropertiesMenu(id) {

	new buf[512],len;
	len = formatex(buf,charm(buf),"%L",id,"WALLS_DEV_MENU_TITLE");
	switch(g_pServerVar[m_iSetting])
	{
		case 0:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.1;
			len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_COORD",
			g_pServerBox[m_fOrigin][x],
			g_pServerBox[m_fOrigin][y],
			g_pServerBox[m_fOrigin][z],iSize);
		}
		case 1:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 45.0 : (g_pServerVar[m_iType] == 1) ? 15.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_ANGLES",
			g_pServerBox[m_fAngles][x],
			g_pServerBox[m_fAngles][y],
			g_pServerBox[m_fAngles][z],iSize);
		}
		case 2,3:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_SIZE",
			g_pServerBox[m_fMins][x],
			g_pServerBox[m_fMins][y],
			g_pServerBox[m_fMins][z],
			g_pServerBox[m_fMaxs][x],
			g_pServerBox[m_fMaxs][y],
			g_pServerBox[m_fMaxs][z],iSize);
		}
		case 4:
		{
			new Float:iSize = ((g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051);
			switch(g_pServerVar[m_iType])
			{
				case 0,1:
					len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_SCALE_1",
					g_pServerVar[m_fScale],iSize,iSize,iSize);
				case 2:
					len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_SCALE_2",
					g_pServerVar[m_fScale],iSize,iSize,iSize);

				case 3:
					len += formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_SCALE_3",
					g_pServerVar[m_fScale],iSize,iSize,iSize);
			}
		}
	}
	formatex(buf[len],charm(buf) - len,"%L",id,"WALLS_DEV_MENU_ADDON",id,
	(g_pServerVar[m_iSetting] == 0) ?
		"WALLS_DEV_COORD"
			:
		(g_pServerVar[m_iSetting] == 1) ?
			"WALLS_DEV_ANGLES"
				:
			(g_pServerVar[m_iSetting] == 2 && g_pServerVar[m_bAdvanced]) ?
				"WALLS_DEV_MINS"
					:
				(g_pServerVar[m_iSetting] == 3 && g_pServerVar[m_bAdvanced]) ?
					"WALLS_DEV_MAXS"
						:
					(g_pServerVar[m_iSetting] == 3) ?
						"WALLS_DEV_SIZE"
							:
						"WALLS_DEV_SPRITE",
	id,(g_pServerVar[m_iSprite] == 0) ?
		"WALLS_DEV_TITLE"
			:
		(g_pServerVar[m_iSprite] == 1) ?
			"WALLS_DEV_WALL"
				:
			"WALLS_DEV_NULL"
	);
	return show_menu(id,(g_pServerVar[m_iSetting] < 4) ? 0x3FF : 0x3C3,buf,-1,"Menu Wlasciwosci");
}
public propertiesHandler(id,key) {
	if(key == 9)
		return showMainEditMenu(id);

	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_origin,g_pServerBox[m_fOrigin]);
	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_angles,g_pServerBox[m_fAngles]);
	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_maxs,g_pServerBox[m_fMaxs]);
	g_pServerVar[m_fScale] = _:(entity_get_float(g_pServerVar[m_iEntid],EV_FL_scale));

	switch(g_pServerVar[m_iSetting])
	{
		case 0:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.1;

			switch(key)
			{
				case 0:	g_pServerBox[m_fOrigin][x] += iSize;
				case 1:	g_pServerBox[m_fOrigin][y] += iSize;
				case 2:	g_pServerBox[m_fOrigin][z] += iSize;
				case 3:	g_pServerBox[m_fOrigin][x] -= iSize;
				case 4:	g_pServerBox[m_fOrigin][y] -= iSize;
				case 5:	g_pServerBox[m_fOrigin][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSprite] > 1 && g_pServerVar[m_iSetting] == 1) ? 2 + ((g_pServerVar[m_bAdvanced] == false) ? 1 : 0) : g_pServerVar[m_iSetting];
				}
			}
		}
		case 1:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 45.0 : (g_pServerVar[m_iType] == 1) ? 15.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;

			switch(key)
			{
				case 0: g_pServerBox[m_fAngles][x] += iSize;
				case 1: g_pServerBox[m_fAngles][y] += iSize;
				case 2: g_pServerBox[m_fAngles][z] += iSize;
				case 3: g_pServerBox[m_fAngles][x] -= iSize;
				case 4: g_pServerBox[m_fAngles][y] -= iSize;
				case 5: g_pServerBox[m_fAngles][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSetting] == 2 && g_pServerVar[m_bAdvanced] == false) ? 3 : g_pServerVar[m_iSetting];
				}
			}
		}
		case 2:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;

			switch(key)
			{
				case 0: g_pServerBox[m_fMins][x] -= iSize;
				case 1: g_pServerBox[m_fMins][y] -= iSize;
				case 2: g_pServerBox[m_fMins][z] -= iSize;
				case 3: g_pServerBox[m_fMins][x] += iSize;
				case 4: g_pServerBox[m_fMins][y] += iSize;
				case 5: g_pServerBox[m_fMins][z] += iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;
				}
			}
		}
		case 3:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;

			switch(key)
			{
				case 0: g_pServerBox[m_fMaxs][x] += iSize;
				case 1: g_pServerBox[m_fMaxs][y] += iSize;
				case 2: g_pServerBox[m_fMaxs][z] += iSize;
				case 3: g_pServerBox[m_fMaxs][x] -= iSize;
				case 4: g_pServerBox[m_fMaxs][y] -= iSize;
				case 5: g_pServerBox[m_fMaxs][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSprite] > 1 && g_pServerVar[m_iSetting] == 4) ? 0 : g_pServerVar[m_iSetting];
				}
			}
		}
		case 4:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051;

			if(iSize > g_pServerVar[m_fScale]) {
				if(++g_pServerVar[m_iType] > 3)
					g_pServerVar[m_iType] = 0;

				iSize = (g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051;
			}
			switch(key)
			{
				case 0:	g_pServerVar[m_fScale] += iSize;
				case 1: g_pServerVar[m_fScale] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;
				}
			}

		}
	}
	switch(key)
	{
		case 8:
		{
			if(is_valid_ent(g_pServerVar[m_iEntid])) {
				if(++g_pServerVar[m_iSprite] > 2)
					g_pServerVar[m_iSprite] = 0;

				new iFlags = entity_get_int(g_pServerVar[m_iEntid],EV_INT_effects);

				if(g_pServerVar[m_iSprite] > 1)
					entity_set_int(g_pServerVar[m_iEntid],EV_INT_effects,iFlags|EF_NODRAW);

				else {
					if(iFlags & EF_NODRAW)
						entity_set_int(g_pServerVar[m_iEntid],EV_INT_effects,iFlags &~ EF_NODRAW);
				}
				entity_set_float(g_pServerVar[m_iEntid],EV_FL_frame,float(g_pServerVar[m_iSprite]));
			}
		}
	}
	if(g_pServerVar[m_fScale] < 0.0051)
		g_pServerVar[m_fScale] = _:0.0051;

	if(g_pServerVar[m_bAdvanced])
	{
		if(g_pServerBox[m_fMins][x] > 0.0)
			g_pServerBox[m_fMins][x] = 0.0;

		else if(g_pServerBox[m_fMins][y] > 0.0)
			g_pServerBox[m_fMins][y] = 0.0;

		else if(g_pServerBox[m_fMins][z] > 0.0)
			g_pServerBox[m_fMins][z] = 0.0;

		if(g_pServerBox[m_fMaxs][x] < 0.0)
			g_pServerBox[m_fMaxs][x] = 0.0;

		else if(g_pServerBox[m_fMaxs][y] < 0.0)
			g_pServerBox[m_fMaxs][y] = 0.0;

		else if(g_pServerBox[m_fMaxs][z] < 0.0)
			g_pServerBox[m_fMaxs][z] = 0.0;

	}
	else
	{
		if(g_pServerBox[m_fMaxs][x] < 1.0)
			g_pServerBox[m_fMaxs][x] = 1.0;

		else if(g_pServerBox[m_fMaxs][y] < 1.0)
			g_pServerBox[m_fMaxs][y] = 1.0;

		else if(g_pServerBox[m_fMaxs][z] < 1.0)
			g_pServerBox[m_fMaxs][z] = 1.0;
	}

	if(g_pServerBox[m_fAngles][x] >= 360.0 || g_pServerBox[m_fAngles][x] <= -360.0)
		g_pServerBox[m_fAngles][x] = 0.0;

	if(g_pServerBox[m_fAngles][y] >= 360.0 || g_pServerBox[m_fAngles][y] <= -360.0)
		g_pServerBox[m_fAngles][y] = 0.0;

	if(g_pServerBox[m_fAngles][z] >= 360.0 || g_pServerBox[m_fAngles][z] <= -360.0)
		g_pServerBox[m_fAngles][z] = 0.0;

	if(!g_pServerVar[m_bAdvanced]) {
		g_pServerBox[m_fMins][x] = -g_pServerBox[m_fMaxs][x];
		g_pServerBox[m_fMins][y] = -g_pServerBox[m_fMaxs][y];
		g_pServerBox[m_fMins][z] = -g_pServerBox[m_fMaxs][z];
	}
	entity_set_float(g_pServerVar[m_iEntid],EV_FL_scale,g_pServerVar[m_fScale]);
	entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_angles,g_pServerBox[m_fAngles]);
	entity_set_float(g_pServerVar[m_iEntid],EV_FL_nextthink,get_gametime() + 0.1);
	entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,g_pServerVar[m_iSolid] ? SOLID_BBOX : SOLID_NOT);

	entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);
	entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_origin,g_pServerBox[m_fOrigin]);

	return showPropertiesMenu(id);
}
showSettingsMenu(id) {
	new menu[512];
	formatex(menu,511,"%L",id,"WALLS_DEV_MENU_CONFIG",
		id,g_pServerVar[m_iEntid] == 0 ? "WALLS_DEV_SOLID" : "WALLS_DEV_SOLID_D",
		g_pServerVar[m_iSolid] ? "SOLID_BBOX" : "SOLID_NOT",
		g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
		id,(g_pServerVar[m_iStatus] == status_s:box_close) ? "WALLS_DEV_HIDE" : "WALLS_DEV_SHOW",
		g_pServerVar[m_iOnline],
		id,entity_get_int(id,EV_INT_movetype) == MOVETYPE_NOCLIP ? "WALLS_DEV_YES" : "WALLS_DEV_NO",
		id,g_pServerVar[m_bAdvanced] ? "WALLS_DEV_YES" : "WALLS_DEV_NO");

	return show_menu(id,(MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5),menu,-1,"Menu Ustawien");
}
public settingHandler(id,key) {
	switch(key)
	{
		case 0:
		{
			if(!g_pServerVar[m_iEntid]) {
				client_print(id,print_center,"%L",id,"WALLS_DEV_FAILED_4");
				goto _jmp0;
			}
			entity_set_float(g_pServerVar[m_iEntid],EV_FL_nextthink,get_gametime() + 0.1);
			entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,(g_pServerVar[m_iSolid] ^= 1) ? SOLID_BBOX : SOLID_NOT);
			entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

			client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_6",g_pServerVar[m_iSolid] ? "SOLID_BBOX" : "SOLID_NOT");
		}
		case 1:
		{
			if(g_pServerVar[m_iBox])
				showBoxDeveloper((g_pServerVar[m_iStatus] ^= status_s:box_close));
		}
		case 2:
		{
			if(++g_pServerVar[m_iOnline] > g_pServerVar[m_iMaxpl])
				g_pServerVar[m_iOnline] = 0;
		}
		case 3:
		{
			if(is_user_alive(id))
				entity_set_int(id,EV_INT_movetype,(entity_get_int(id,EV_INT_movetype) == MOVETYPE_NOCLIP) ? MOVETYPE_WALK : MOVETYPE_NOCLIP);
		}
 		case 4: g_pServerVar[m_bAdvanced] ^= true;
		case 9:	return showMainEditMenu(id);
	}
	_jmp0:
	return showSettingsMenu(id);
}

boxSave(id) {
	delete_file(g_pServerVar[m_szFile]);

	new buf[1024],Float:frame,Float:p_origin[coord_s],Float:p_angles[coord_s],Float:p_mins[coord_s],Float:p_maxs[coord_s],Float:p_scale,p_sprite,count,ent = -1;
	formatex(buf,1023,"ONLINE=%d",g_pServerVar[m_iOnline]);
		
	write_file(g_pServerVar[m_szFile],buf,0);
	while((ent = find_ent_by_class(ent,CLASSNAME_WALL)))
	{
		if(g_pServerVar[m_iEntid] == ent)
			continue;

		entity_get_vector(ent,EV_VEC_origin,p_origin);
		entity_get_vector(ent,EV_VEC_angles,p_angles);
		entity_get_vector(ent,EV_VEC_mins,p_mins);
		entity_get_vector(ent,EV_VEC_maxs,p_maxs);

		p_scale = entity_get_float(ent,EV_FL_scale);
		frame = entity_get_float(ent,EV_FL_frame);

		p_sprite = floatround(frame);

		formatex(buf,1023,"\"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%d\"",p_origin[x],p_origin[y],p_origin[z],p_angles[x],p_angles[y],p_angles[z],p_mins[x],p_mins[y],p_mins[z],p_maxs[x],p_maxs[y],p_maxs[z],p_scale,p_sprite);
		write_file(g_pServerVar[m_szFile],buf,-1);
		count++;
	}
	while((ent = find_ent_by_class(ent,CLASSNAME_WALL_PERMANENT)))
	{
		if(g_pServerVar[m_iEntid] == ent)
			continue;

		entity_get_vector(ent,EV_VEC_origin,p_origin);
		entity_get_vector(ent,EV_VEC_angles,p_angles);
		entity_get_vector(ent,EV_VEC_mins,p_mins);
		entity_get_vector(ent,EV_VEC_maxs,p_maxs);

		p_scale = entity_get_float(ent,EV_FL_scale);
		frame = entity_get_float(ent,EV_FL_frame);

		p_sprite = floatround(frame);

		formatex(buf,1023,"\"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%d\"",p_origin[x],p_origin[y],p_origin[z],p_angles[x],p_angles[y],p_angles[z],p_mins[x],p_mins[y],p_mins[z],p_maxs[x],p_maxs[y],p_maxs[z],p_scale,p_sprite);
		write_file(g_pServerVar[m_szFile],buf,-1);
		count++;
	}
	if(id && count > 0)
		client_print(id,print_center,"%L",id,"WALLS_DEV_SUCCESS_3");
}
boxLoad() {
	new buf[2048],key[32],value[32],p_origin[coord_s][6],p_angles[coord_s][6],p_mins[coord_s][6],p_maxs[coord_s][6],p_scale[6],p_sprite[6];
	new file = fopen(g_pServerVar[m_szFile],"r");
	while(!feof(file))
	{
		fgets(file,buf,charm(buf));
		if(buf[0] == '\0' || buf[0] == ';') {
			continue;
		}

		trim(buf);
		strtok(buf,key,charm(key),value,charm(value),'=');

		if(!strcmp(key,"ONLINE")) {
			g_pServerVar[m_iOnline] = str_to_num(value);
			continue;
		}

		parse(buf,
		p_origin[x],5,p_origin[y],5,p_origin[z],5,
		p_angles[x],5,p_angles[y],5,p_angles[z],5,
		p_mins[x],5,p_mins[y],5,p_mins[z],5,
		p_maxs[x],5,p_maxs[y],5,p_maxs[z],5,
		p_scale,5,
		p_sprite,5);

		g_pServerBox[m_fOrigin][x] = str_to_float(p_origin[x]);
		g_pServerBox[m_fOrigin][y] = str_to_float(p_origin[y]);
		g_pServerBox[m_fOrigin][z] = str_to_float(p_origin[z]);

		g_pServerBox[m_fAngles][x] = str_to_float(p_angles[x]);
		g_pServerBox[m_fAngles][y] = str_to_float(p_angles[y]);
		g_pServerBox[m_fAngles][z] = str_to_float(p_angles[z]);

		g_pServerBox[m_fMins][x] = str_to_float(p_mins[x]);
		g_pServerBox[m_fMins][y] = str_to_float(p_mins[y]);
		g_pServerBox[m_fMins][z] = str_to_float(p_mins[z]);

		g_pServerBox[m_fMaxs][x] = str_to_float(p_maxs[x]);
		g_pServerBox[m_fMaxs][y] = str_to_float(p_maxs[y]);
		g_pServerBox[m_fMaxs][z] = str_to_float(p_maxs[z]);

		g_pServerVar[m_fScale] = _:(str_to_float(p_scale));
		g_pServerVar[m_iSprite] = str_to_num(p_sprite);

		createWall(.bParse = true);
		g_pServerVar[m_iBox]++;
	}
	return fclose(file);
}
checkNumPlayers() {
	new iNum;
	for(new index = 1; index <= g_pServerVar[m_iMaxpl]; index++) {
		if(!is_user_connected(index) || !IsUserTeam(index))
			continue;

		iNum++;
	}
	return iNum;
}
showBoxDeveloper(status_s:st) {
	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt,CLASSNAME_WALL)))
	{
		entity_set_int(iEnt,EV_INT_solid,st == status_s:box_close ? SOLID_BBOX : SOLID_NOT);

		if(g_pServerVar[m_iEntid] == iEnt || entity_get_float(iEnt,EV_FL_frame) > 1.0) {
			continue;
		}
		new iFlags = entity_get_int(iEnt,EV_INT_effects);
		entity_set_int(iEnt,EV_INT_effects,st == status_s:box_close ? iFlags &~ EF_NODRAW : iFlags|EF_NODRAW);
	}
}
showBox(status_s:st,bool:bShow) {
	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt,CLASSNAME_WALL)))
	{
		entity_set_int(iEnt,EV_INT_solid,st == status_s:box_close ? SOLID_BBOX : SOLID_NOT);

		if(entity_get_float(iEnt,EV_FL_frame) > 1)
			continue;

		new iFlags = entity_get_int(iEnt,EV_INT_effects);
		entity_set_int(iEnt,EV_INT_effects,st == status_s:box_close ? iFlags &~ EF_NODRAW : iFlags|EF_NODRAW);
	}
	switch(st)
	{
		case box_open: {
			#if defined STATE_USE
			state stMode:Disabled;
			#endif
			if(bShow) {
				set_dhudmessage(COLOR_MAP_OPEN,MESSAGE_MAP_STATUS,2,0.1,2.0,0.05,0.2);
				show_dhudmessage(0,"%L",LANG_PLAYER,"WALLS_MESSAGE_MAP_OPENED");
			}
		}
		case box_close: {
			#if defined STATE_USE
			state stMode:Enabled;
			#endif
			if(bShow) {
				set_dhudmessage(COLOR_MAP_CLOSE,MESSAGE_MAP_STATUS,2,0.1,2.0,0.05,0.2);
				show_dhudmessage(0,"%L",LANG_PLAYER,"WALLS_MESSAGE_MAP_CLOSED");
			}
		}
	}
}
createWall(bool:bParse) {
	new ent = create_entity("func_wall");

	if(!is_valid_ent(ent)) {
		return 0;
	}

	entity_set_string(ent,EV_SZ_classname, g_pServerVar[m_iSprite] == 2 ? CLASSNAME_WALL_PERMANENT : CLASSNAME_WALL);
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_FLY);

	if(bParse) {
		entity_set_model(ent,SPRITE_WALL);
		entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

		entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
		entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);
		entity_set_int(ent,EV_INT_solid,SOLID_BBOX);

		if(g_pServerVar[m_iSprite] > 1)
			entity_set_int(ent,EV_INT_effects,entity_get_int(ent,EV_INT_effects)|EF_NODRAW);

		entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));
		entity_set_int(ent,EV_INT_rendermode,kRenderTransAdd);
		entity_set_float(ent,EV_FL_renderamt,175.0);
		entity_set_vector(ent,EV_VEC_origin,g_pServerBox[m_fOrigin]);
	}
	else {
		g_pServerBox[m_fAngles][x] = 0.0;
		g_pServerBox[m_fAngles][y] = 0.0;
		g_pServerBox[m_fAngles][z] = 0.0;

		g_pServerBox[m_fMaxs][x] = 32.0;
		g_pServerBox[m_fMaxs][y] = 32.0;
		g_pServerBox[m_fMaxs][z] = 32.0;

		g_pServerBox[m_fMins][x] = -32.0;
		g_pServerBox[m_fMins][y] = -32.0;
		g_pServerBox[m_fMins][z] = -32.0;

		g_pServerVar[m_fScale] = _:0.250;

		entity_set_model(ent,SPRITE_WALL);
		entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

		entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
		entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);
		entity_set_int(ent,EV_INT_solid,SOLID_NOT);

		entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));

		entity_set_int(ent,EV_INT_rendermode,kRenderTransAdd);
		entity_set_float(ent,EV_FL_renderamt,175.0);

		entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);

		return ent;
	}
	return 0;
}