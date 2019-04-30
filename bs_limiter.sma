#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <csx>

#define MAXBSNUM 10 //maksymalna ilosc BS'ow na mapie
#define ADMIN_ACCESS ADMIN_BAN //wymagana flaga dostepu

new const PLUGIN[] = "BS Limiter"

new g_msg_statusicon
new sline //sprite
new BsList[MAXBSNUM], num //bs'y
new ctnum, prev_num //ct
new pcCtMin //pcvar
new mapname[32] 
new g_BsName[32], g_BsNum = -1 //dane bs'a

public plugin_init()
{
	register_plugin(PLUGIN, "1.1.1", "Pavulon")
	
	pcCtMin = register_cvar("bsl_ctmin", "4") //minimalna liczba graczy by grac na wszystkie BS'y
	
	register_clcmd("bsl_menu", "menuGlowne") //menu
	register_clcmd("bsl_name", "bsl_name")
	
	g_msg_statusicon = get_user_msgid("StatusIcon")
	
	register_message(g_msg_statusicon, "Check_Icon") //ikonka c4
	register_event("TeamInfo", "Check_Team", "a") //zmiana team'u
	set_task(1.0, "check_bs")	
}

public ReadFile() //wczytujemy config
{
	new cfgfile[64]
	
	get_configsdir(cfgfile, 63)
	format(cfgfile, 63, "%s/bs_limiter.ini", cfgfile)
	
	if (!file_exists(cfgfile))
	{
		log_amx("[BSL] Nie mozna otworzyc pliku %s. Plik nie istnieje", cfgfile)
		return
	}
	g_BsNum = -1
	copy(g_BsName, 31, "")
	
	new mapa[32], ent[4], bs[32], i, linia[70], len
	while (read_file(cfgfile, i++, linia, 69, len))
	{
		if(linia[0]!=';')
		{
			copy(mapa, 31, "")
			copy(ent, 31, "")
			copy(bs, 31, "")
			parse(linia, mapa, 31, ent, 3, bs, 31)
			
			if (equal(mapa, mapname))
			{
				remove_quotes(bs)
				if (strlen(ent)>0)
				{
					g_BsNum = str_to_num(ent)
					copy(g_BsName, 31, bs)
				}
				return
			}
		}
	}
}

public SaveFile(param1, param2[32]) //zapisujemy config
{
	new cfgfile[64]
	
	get_configsdir(cfgfile, 63)
	format(cfgfile, 63, "%s/bs_limiter.ini", cfgfile)

	if (!file_exists(cfgfile))
	{
		log_amx("[BSL] Nie mozna zapisac pliku %s. Plik nie istnieje", cfgfile)
		return
	}	
	
	new tmp[70]
	formatex(tmp, 69, "%s %d ^"%s^"", mapname, param1, param2)
	
	new mapa[32], ent[4], bs[32], i, linia[70], len
	while (read_file(cfgfile, i++, linia, 69, len))
	{
		if(linia[0]!=';')
		{
			parse(linia, mapa, 31, ent, 3, bs[31])

			if (equal(mapa, mapname))
			{
				write_file(cfgfile, tmp, i-1)
				return
			}
		}
	}
	write_file(cfgfile, tmp, -1)
}

public Check_Team()
{
	ctnum = count_ct()
	new team[3], pnum = get_pcvar_num(pcCtMin)-1
	read_data(2, team, 2);
	if (ctnum==pnum && ctnum!=prev_num)
	{
		set_hudmessage(255, 255, 0, -1.0, 0.3, 0, 3.0, 3.0, _, _, 3)
		show_hudmessage(0, "Limit BS'ow wlaczony!! Wymagana ilosc graczy w druzynie CT do wylaczenia limitu to %d !!", get_pcvar_num(pcCtMin))
	}
	prev_num = pnum
}

public check_bs()
{
	get_mapname(mapname, 31)
	if( contain( mapname, "de_" ) == -1 || contain( mapname, "css_" ) == -1 )
		pause("a")

	ReadFile()
		
	num = 0
	new ent = -1
	while ((ent = find_ent_by_class(ent, "func_bomb_target")))
		BsList[num++] = ent
		
	while ((ent = find_ent_by_class(ent, "info_bomb_target")))
		BsList[num++] = ent
	
	if (num==0)
		pause("a")
		
	AddMenuItem("BS Limiter Menu", "bsl_menu", ADMIN_ACCESS, PLUGIN)
}

public menuGlowne(id)
{
	if (!(get_user_flags(id)&ADMIN_ACCESS))
	{
		console_print(id, "[BSL] Nie masz dostepu do tej funkcji")
		return PLUGIN_HANDLED
	}
	if (g_BsNum>=0)
	{
		set_task(0.2, "LineToBs", id)
	}
	
	new mGlowne = menu_create("BS Limiter", "cbGlowne")
	new GlowneCb = menu_makecallback("mcbGlowne")
	
	new tmp[32]
	menu_additem(mGlowne, "\yUstaw nazwe:", _, ADMIN_ACCESS, GlowneCb)
	if (strlen(g_BsName)>0)
		formatex(tmp, 31, "\r%s", g_BsName)
	else
		copy(tmp, 31, "")
	menu_additem(mGlowne, tmp, _, ADMIN_ACCESS, GlowneCb)
	menu_additem(mGlowne, "\yWybierz BS:", _, ADMIN_ACCESS, GlowneCb)
	if (g_BsNum>=0)
		formatex(tmp, 31, "\r[%d] %d", g_BsNum, BsList[g_BsNum])
	else
		copy(tmp, 31, "")
	menu_additem(mGlowne, tmp, _, ADMIN_ACCESS, GlowneCb)
	menu_additem(mGlowne, "\yZapisz PLIK", _, ADMIN_ACCESS, GlowneCb)
	menu_setprop(mGlowne, MPROP_EXITNAME, "WYJSCIE")
	menu_display(id, mGlowne, 0)
	
	return PLUGIN_HANDLED
}

public mcbGlowne(id, menu, item)
{
	if(1==item || item==3)
		return ITEM_DISABLED

	return ITEM_ENABLED
}

public cbGlowne(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			client_cmd(id, "messagemode ^"bsl_name^"")
		}
		case 2:
		{
			menuLista(id)
		}
		case 4:
		{
			SaveFile(g_BsNum, g_BsName)
		}
		case MENU_EXIT:
		{
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}



public menuLista(id)
{
	new mLista = menu_create("Lista BS'ow", "cbLista")
	new ListaCb = menu_makecallback("mcbLista")
	menu_additem(mLista, "\yWybierz BS:", _, ADMIN_ACCESS, ListaCb)
	new tmp[32], strent[4]
	
	for (new i=0; i<num; i++)
	{
		formatex(tmp, 31, "%s[%d] %d", (i==g_BsNum)?"\r":"\y", i, BsList[i])
		num_to_str(BsList[i], strent, 3)
		menu_additem(mLista, tmp, strent, ADMIN_ACCESS, ListaCb)	
	}
	menu_setprop(mLista, MPROP_EXITNAME, "WYJSCIE")
	
	if (g_BsNum>=0)
	{
		set_task(0.2, "LineToBs", id)
	}

	menu_display(id, mLista, 0)
}

public mcbLista(id, menu, item)
{
	return ITEM_ENABLED
}

public cbLista(id, menu, item)
{
	if (item==MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} else if (item==0){
		menuGlowne(id)
	} else {
		new acc, info[32], name[32], cb
		menu_item_getinfo(menu, item, acc, info, 31, name, 32, cb)
		g_BsNum = item-1
		set_task(0.2, "LineToBs", id)
		menuLista(id)
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public bsl_name(id)
{
	if (!(get_user_flags(id)&ADMIN_ACCESS))
	{
		console_print(id, "[BSL] Nie masz dostepu do tej funkcji")
		return PLUGIN_HANDLED
	}
	
	new name[32]
	
	read_argv (1, name, 31) 
	remove_quotes(name)
	
	if (strlen(name)>0)
		copy(g_BsName, 31, name)
	
	menuGlowne(id)

	return PLUGIN_HANDLED
}

public bomb_planting(id)
{
	if (ctnum<get_pcvar_num(pcCtMin) && in_right_bs(id)<=0)
	{
		client_cmd(id, "-attack")
		cs_set_user_plant(id, 0)
		set_task(5.0, "reset_planting", id)
		set_hudmessage(255, 255, 0, -1.0, 0.3, 0, 2.5, 5.0, _, _, 3)
		show_hudmessage(id, "Poniewaz jest malo graczy gramy tylko na %s^nJestes na niewlasciwym BS'ie, idz na drugi.", (strlen(g_BsName)<=0)?"jeden BS":g_BsName)
	}
}

public reset_planting(id)
{
	if (is_user_alive(id) && user_has_weapon(id, CSW_C4))
		cs_set_user_plant(id)
}

public Check_Icon(msgid, msgDest, id)
{
	if (!get_msg_arg_int(1))
		return
	
	new icon[3]
	get_msg_arg_string(2, icon, 2)
	if (equal(icon, "c4"))
		if (ctnum<get_pcvar_num(pcCtMin) && in_right_bs(id)<0)
		{
			set_msg_arg_int(3, ARG_BYTE, 255)
			set_msg_arg_int(4, ARG_BYTE, 0)
		}
}

stock in_right_bs(id)
{
	if (g_BsNum == -1)
		return 1
	
	static Float:origin[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	
	new ent = -1, i
	while ((ent = find_ent_in_sphere(ent, origin, 30.0)))
		for (i=0; i<num; i++)
			if (ent == BsList[i])
				if (i == g_BsNum)
					return 1
				else
					return -1
	return 0
}

stock count_ct()
{
	new players[32], num, ct
	get_players(players, num)
	for(new i; i<num; i++)
	{
		if (cs_get_user_team(players[i]) == CS_TEAM_CT)
			ct++
	}
	return ct
}

public LineToBs(id)
{
	if (!is_user_connected(id))
		return
	
	new bs = BsList[g_BsNum]
	
	new Float:float_min[3], Float:float_max[3], Float:float_pos[3]
	entity_get_vector(bs, EV_VEC_absmin, float_min)
	entity_get_vector(bs, EV_VEC_absmax, float_max)
	entity_get_vector(id, EV_VEC_origin, float_pos)
	
	new bsmin[3], bsmax[3], bspos[3], pos[3]
	for(new i=0;i<3;i++)
	{
		bsmin[i] = floatround(float_min[i])
		bsmax[i] = floatround(float_max[i])
		bspos[i] = floatround((float_min[i]+float_max[i])/2)
		pos[i] = floatround(float_pos[i])
	}

	Line(id, pos[0], pos[1], pos[2], bspos[0], bspos[1], bspos[2])
	
	Line(id, bsmin[0], bsmin[1], bsmin[2], bsmin[0], bsmin[1], bsmax[2])
	Line(id, bsmin[0], bsmin[1], bsmin[2], bsmin[0], bsmax[1], bsmin[2])
	Line(id, bsmin[0], bsmin[1], bsmin[2], bsmax[0], bsmin[1], bsmin[2])

	Line(id, bsmax[0], bsmax[1], bsmax[2], bsmax[0], bsmax[1], bsmin[2])
	Line(id, bsmax[0], bsmax[1], bsmax[2], bsmax[0], bsmin[1], bsmax[2])
	Line(id, bsmax[0], bsmax[1], bsmax[2], bsmin[0], bsmax[1], bsmax[2])
	
	Line(id, bsmax[0], bsmax[1], bsmin[2], bsmin[0], bsmax[1], bsmin[2])
	Line(id, bsmax[0], bsmax[1], bsmin[2], bsmax[0], bsmin[1], bsmin[2])
	Line(id, bsmax[0], bsmin[1], bsmin[2], bsmax[0], bsmin[1], bsmax[2])
	
	Line(id, bsmin[0], bsmin[1], bsmax[2], bsmax[0], bsmin[1], bsmax[2])
	Line(id, bsmin[0], bsmin[1], bsmax[2], bsmin[0], bsmax[1], bsmax[2])
	Line(id, bsmin[0], bsmax[1], bsmax[2], bsmin[0], bsmax[1], bsmin[2])

	if (task_exists(id))
		remove_task(id)
		
	new mid, keys
	get_user_menu(id, mid, keys)
	if (mid>0)
		set_task(0.2, "LineToBs", id)
}

public Line(id, n0, n1, n2, x0, x1, x2) 
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_BEAMPOINTS)
	write_coord(n0)
	write_coord(n1)
	write_coord(n2)
	write_coord(x0)
	write_coord(x1)
	write_coord(x2)
	write_short(sline)
	write_byte(1)
	write_byte(5)
	write_byte(10)
	write_byte(3)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	write_byte(5)
	message_end()
}

public plugin_precache()
{
	sline = precache_model("sprites/dot.spr")
}