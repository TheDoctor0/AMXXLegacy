#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>


#define CONFIG_FOLDERNAME "In-Game Ads"
#define MAIN_PRECACHE_FILE "precache_list.cfg"
#define MAIN_PRECACHE_FILE_TEXT "// To see your model or sprite in the menu, add its full path here.^n// For example:^n//models/wall.mdl^n//models/player.mdl^n//sprites/custom/sprite.spr^n//^n^n^n"

#define ERROR_FILE_NOT_FOUND		"Error: Failed to precache/load (%s), model/sprite does not exist."
#define ERROR_USER_ALREADY_PLACING	"Error: More than one user is placing an advertisement!"
#define ERROR_USER_ALREADY_DELETING	"Error: More than one user is deleting an advertisement!"

#define MENU_SAVE_TEXT				"Save this ent?^n^n1. Yes, save it.^n0. No, delete it.^n"
#define MENU_SELECT_TEXT_CHOOSE_MODEL		"Choose one: %i/%i^n^n"
#define MENU_SELECT_TEXT_OPTIONS_1		"^n6. Scale up^n7. Scale down^n^n8. Save this ent!^n^n9. More...^n0. %s"
#define MENU_SELECT_TEXT_OPTIONS_2		"^n6. Scale up^n7. Scale down^n^n8. Save this ent!^n^n0. %s"
#define MENU_DELETE_TEXT_HEADER			"Delete an ent: %i/%i^n(Select one to highlight it on the map)^n^n"
#define MENU_DELETE_TEXT_OPTIONS_1		"^n^n9.More...^n0.%s"
#define MENU_DELETE_TEXT_OPTIONS_2		"^n^n0.%s"
#define MENU_DELETE_TEXT_CONFIRM		"Delete selected ent?^n^n1. Yes, delete it.^n0. Cancel.^n"
#define MENU_TEXT_PREVIOUS			"Previous page"
#define MENU_TEXT_EXIT				"Exit"


//every X frames the ad's origin/angles will be updated
#define PRETHINK_REFRESH_TIME 5

//distance to move the entity away or towards the client
#define MOVE_DISTANCE 5.0

//amount to scale the sprites, for example, 1.00 - 0.01 = 0.99, 0.99 - 0.01 = 0.98
#define SCALE_AMOUNT 0.01

//model used to hilite before an ad is deleted
#define DELETE_ICON_PATH "models/chick.mdl"

//maximum number of ads in the current map
#define MAX_NUMBER_OF_ADS 32

//maximum number of models/sprites to choose from in the menu
#define MAX_AD_MODELS 16

//maximum length of the complete filename of a model/sprite, eg. "sprites/advert/bloodservers.spr"
#define MAX_MODEL_NAMELEN 48

//classname of models/sprites
#define MODEL_CLASSNAME "stupok_ad"

//access level for the commands
#define ADMIN_ACCESS_LEVEL ADMIN_BAN

//Do not change below
#define MENU_SELECT_SIZE (128 + (MAX_AD_MODELS * MAX_MODEL_NAMELEN))
#define MENU_SELECT_OPTIONS_NUM 5
#define MENU_DELETE_SIZE (128 + (MAX_AD_MODELS * MAX_MODEL_NAMELEN))
#define MENU_DELETE_OPTIONS_NUM 7
//Do not change above

//names of the models that are precached on the map
new g_precached_model_list[MAX_AD_MODELS][MAX_MODEL_NAMELEN]
new g_precached_model_list_len

//index of the model selected for creation or deletion
new g_selected_model_index
new g_delete_model_index

//current page on the menu
new g_menu_select_current_page
new g_menu_delete_current_page

//names/indexes of the models that are placed on the map
new g_map_model_entindex_list[MAX_NUMBER_OF_ADS]
new g_map_model_list[MAX_AD_MODELS][MAX_MODEL_NAMELEN]
new g_map_model_list_len

//creating/deleting/modifying this ent
new g_ent
new Float:g_aim_origin[3]
new Float:g_ent_angles[3]

//one user may use this plugin at a time
new g_ad_placer_id = -1
new bool:g_is_user_placing_ad = false
new g_prethink_counter

//names
new g_filename[256]
new g_mapname[32]

//is the model for hiliting deletions precached?
new bool:g_is_deleteicon_precached = false

//forward for player prethink
new fw_ppt

public plugin_init()
{
	register_plugin("In-Game Ads", "1.83", "stupok")
	
	register_clcmd("+place_ad", "cmd_place_ad", ADMIN_ACCESS_LEVEL)
	register_clcmd("-place_ad", "cmd_place_ad", ADMIN_ACCESS_LEVEL)
	
	register_clcmd("delete_ad", "cmd_delete_ad", ADMIN_ACCESS_LEVEL)
	
	register_clcmd("iga_closer", "cmd_move_toward_client", ADMIN_ACCESS_LEVEL)
	register_clcmd("iga_farther", "cmd_move_away_from_client", ADMIN_ACCESS_LEVEL)
	register_clcmd("iga_further", "cmd_move_away_from_client", ADMIN_ACCESS_LEVEL)
	
	register_menucmd(register_menuid("menu_save"), MENU_KEY_1|MENU_KEY_0, "Pressedmenu_save")
	register_menucmd(register_menuid("menu_select"), 1023, "Pressedmenu_select")
	register_menucmd(register_menuid("menu_delete"), 1023, "Pressedmenu_delete")
	register_menucmd(register_menuid("menu_confirm"), MENU_KEY_1|MENU_KEY_0, "Pressedmenu_confirm")
	
	load_saved_ads(g_filename)
}

public plugin_precache()
{
	if(precache_model(DELETE_ICON_PATH))
	{
		g_is_deleteicon_precached = true
	}
	else
	{
		log_amx(ERROR_FILE_NOT_FOUND, DELETE_ICON_PATH)
	}
	
	new configs_dir[64]
	
	get_configsdir(configs_dir, 63)
	get_mapname(g_mapname, 31)
	
	formatex(g_filename, 255, "%s/%s", configs_dir, CONFIG_FOLDERNAME)
	
	if(!dir_exists(g_filename))
	{
		mkdir(g_filename)
	}
	
	format(g_filename, 255, "%s/%s", g_filename, MAIN_PRECACHE_FILE)
	
	if(!file_exists(g_filename))
	{
		write_file(g_filename, MAIN_PRECACHE_FILE_TEXT)
	}
	
	precache_from_file(g_filename)
	
	formatex(g_filename, 255, "%s/%s/%s.txt", configs_dir, CONFIG_FOLDERNAME, g_mapname)
	
	precache_from_file(g_filename)
}

public fw_playerprethink(id)
{
	if(!g_is_user_placing_ad || id != g_ad_placer_id)
		return FMRES_HANDLED
	
	if(g_prethink_counter++ > PRETHINK_REFRESH_TIME)
	{
		g_prethink_counter = 0
		
		static Float:normal[3]
		
		fm_get_aim_origin_normal(id, g_aim_origin, normal)
		normal[0] *= -1.0
		normal[1] *= -1.0
		if(contain(g_precached_model_list[g_selected_model_index], ".spr") == -1)
		{
			normal[2] *= -1.0
		}
		vector_to_angle(normal, g_ent_angles)
		engfunc(EngFunc_SetOrigin, g_ent, g_aim_origin)
		set_pev(g_ent, pev_angles, g_ent_angles)
	}
	return FMRES_HANDLED
}

public cmd_place_ad(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS_LEVEL))
	{
		client_print(id, print_console, "You do not have access to this command.")
		return PLUGIN_HANDLED
	}
	
	g_ad_placer_id = id
	new cmd[2]
	read_argv(0, cmd, 1)
	
	switch(cmd[0])
	{
		case '+':
		{
			if(g_is_user_placing_ad)
			{
				log_amx(ERROR_USER_ALREADY_PLACING)
				client_print(0, print_chat, ERROR_USER_ALREADY_PLACING)
				return PLUGIN_HANDLED
			}
			
			if(!pev_valid(g_ent))
			{
				create_ad()
			}
			g_is_user_placing_ad = true
			fw_ppt = register_forward(FM_PlayerPreThink, "fw_playerprethink", 0)
		}
		case '-':
		{
			if(pev_valid(g_ent) && g_ent != 0)
			{
				Showmenu_select(id, g_menu_select_current_page)
			}
			g_is_user_placing_ad = false
			if(fw_ppt) unregister_forward(FM_PlayerPreThink, fw_ppt, 0)
		}
	}
	return PLUGIN_HANDLED
}

public cmd_delete_ad(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS_LEVEL))
	{
		client_print(id, print_console, "You do not have access to this command.")
		return PLUGIN_HANDLED
	}
	
	new ent = -1
	new i = -1
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", MODEL_CLASSNAME)) != 0)
	{
		g_map_model_entindex_list[++i] = ent
	}
	
	g_map_model_list_len = i+1
	
	for(new i = 0; i < g_map_model_list_len; i++)
	{
		pev(g_map_model_entindex_list[i], pev_model, g_map_model_list[i], MAX_MODEL_NAMELEN-1)
	}
	
	Showmenu_delete(id, 0)
	
	return PLUGIN_HANDLED
}

//moves one unit on an axis, not directly towards the client's origin
public cmd_move_toward_client(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS_LEVEL))
	{
		client_print(id, print_console, "You do not have access to this command.")
		return PLUGIN_HANDLED
	}
	
	move_on_axis(id, 1)
	
	return PLUGIN_HANDLED
}

//moves one unit on an axis, not directly away from the client's origin
public cmd_move_away_from_client(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS_LEVEL))
	{
		client_print(id, print_console, "You do not have access to this command.")
		return PLUGIN_HANDLED
	}
	
	move_on_axis(id, -1)
	
	return PLUGIN_HANDLED
}

public Showmenu_select(id, page)
{	
	if(page < 0) return
	
	static szMenuBody[MENU_SELECT_SIZE]
	new nCurrKey
	new nStart = page * MENU_SELECT_OPTIONS_NUM
	
	if(nStart >= g_precached_model_list_len)
		nStart = page = g_menu_select_current_page = 0
	
	new nLen = formatex(szMenuBody, MENU_SELECT_SIZE-1, MENU_SELECT_TEXT_CHOOSE_MODEL, page+1, (g_precached_model_list_len / MENU_SELECT_OPTIONS_NUM + ((g_precached_model_list_len % MENU_SELECT_OPTIONS_NUM) ? 1 : 0 )) )
	new nEnd = nStart + MENU_SELECT_OPTIONS_NUM
	new nKeys = (1<<9)
	
	if( nEnd > g_precached_model_list_len )
		nEnd = g_precached_model_list_len
	
	for(new i = nStart; i < nEnd; i++ )
	{
		nKeys |= (1<<nCurrKey++)
		nLen += formatex( szMenuBody[nLen], (MENU_SELECT_SIZE-1-nLen), "%i. %s^n", nCurrKey, g_precached_model_list[i] )
	}
	
	if( nEnd != g_precached_model_list_len )
	{
		formatex( szMenuBody[nLen], (MENU_SELECT_SIZE-1-nLen), MENU_SELECT_TEXT_OPTIONS_1, page ? MENU_TEXT_PREVIOUS : MENU_TEXT_EXIT )
		nKeys |= (1<<8)|(1<<7)|(1<<6)|(1<<5)|(1<<4)
	}
	else
	{
		formatex( szMenuBody[nLen], (MENU_SELECT_SIZE-1-nLen), MENU_SELECT_TEXT_OPTIONS_2, page ? MENU_TEXT_PREVIOUS : MENU_TEXT_EXIT )
		nKeys |= (1<<7)|(1<<6)|(1<<5)|(1<<4)
	}
	
	show_menu( id, nKeys, szMenuBody, -1, "menu_select" )
	
	return
}

public Pressedmenu_select(id, key)
{
	switch(key)
	{
		case 5:
		{
			add_to_scale(g_ent, SCALE_AMOUNT)
			Showmenu_select(id, g_menu_select_current_page)
		}
		case 6:
		{
			add_to_scale(g_ent, -1.0 * SCALE_AMOUNT)
			Showmenu_select(id, g_menu_select_current_page)
		}
		case 7:
		{
			Showmenu_save(id)
		}
		case 8:
		{
			Showmenu_select(id, ++g_menu_select_current_page)
		}
		case 9:
		{
			if(--g_menu_select_current_page < 0)
			{
				engfunc(EngFunc_RemoveEntity, g_ent)
				g_menu_select_current_page = 0
			}
			else
			{
				Showmenu_select(id, g_menu_select_current_page)
			}
		}
		default:
		{
			g_selected_model_index = (g_menu_select_current_page * MENU_SELECT_OPTIONS_NUM + key)
		
			engfunc(EngFunc_SetModel, g_ent, g_precached_model_list[g_selected_model_index])
		
			Showmenu_select(id, g_menu_select_current_page)
		}
	}
}

public Showmenu_save(id)
{
	show_menu(id, (1<<0)|(1<<9), MENU_SAVE_TEXT, -1, "menu_save")
}

public Pressedmenu_save(id, key)
{
	switch (key)
	{
		case 0: save_ad()
		case 9: engfunc(EngFunc_RemoveEntity, g_ent)
	}
}

public Showmenu_delete(id, page)
{
	if(page < 0) return
	
	static szMenuBody[MENU_DELETE_SIZE]
	new nCurrKey
	new nStart = page * MENU_DELETE_OPTIONS_NUM
	
	if(nStart >= g_map_model_list_len)
		nStart = page = g_menu_delete_current_page = 0
	
	new nLen = formatex(szMenuBody, MENU_DELETE_SIZE-1, MENU_DELETE_TEXT_HEADER, page+1, (g_map_model_list_len / MENU_DELETE_OPTIONS_NUM + ((g_map_model_list_len % MENU_DELETE_OPTIONS_NUM) ? 1 : 0 )) )
	new nEnd = nStart + MENU_DELETE_OPTIONS_NUM
	new nKeys = (1<<9)
	
	if( nEnd > g_map_model_list_len )
		nEnd = g_map_model_list_len
	
	for(new i = nStart; i < nEnd; i++ )
	{
		nKeys |= (1<<nCurrKey++)
		nLen += formatex( szMenuBody[nLen], (MENU_DELETE_SIZE-1-nLen), "%i. %s^n", nCurrKey, g_map_model_list[i] )
	}
	
	if( nEnd != g_map_model_list_len )
	{
		formatex( szMenuBody[nLen], (MENU_DELETE_SIZE-1-nLen), MENU_DELETE_TEXT_OPTIONS_1, page ? MENU_TEXT_PREVIOUS : MENU_TEXT_EXIT )
		nKeys |= (1<<8)
	}
	else
	{
		formatex( szMenuBody[nLen], (MENU_DELETE_SIZE-1-nLen), MENU_DELETE_TEXT_OPTIONS_2, page ? MENU_TEXT_PREVIOUS : MENU_TEXT_EXIT )
		nKeys |= (1<<7)|(1<<8)
	}
	
	show_menu( id, nKeys, szMenuBody, -1, "menu_delete" )
	
	return
}

public Pressedmenu_delete(id, key)
{
	switch(key)
	{
		case 8:
		{
			Showmenu_delete(id, ++g_menu_delete_current_page)
		}
		case 9:
		{
			if(--g_menu_delete_current_page < 0)
			{
				g_menu_delete_current_page = 0
			}
			else
			{
				Showmenu_delete(id, g_menu_delete_current_page)
			}
		}
		default:
		{
			g_delete_model_index = g_map_model_entindex_list[(g_menu_delete_current_page * MENU_DELETE_OPTIONS_NUM + key)]
			
			show_delete_icon(g_delete_model_index, 1)
			
			Showmenu_confirm(id)
		}
	}
}

public Showmenu_confirm(id)
{
	show_menu(id, (1<<0)|(1<<9), MENU_DELETE_TEXT_CONFIRM, -1, "menu_confirm")
}

public Pressedmenu_confirm(id, key)
{
	switch (key)
	{
		case 0:
		{
			show_delete_icon(g_delete_model_index, 0)
			delete_ad(g_delete_model_index)
			cmd_delete_ad(id)
		}
		case 9:
		{
			show_delete_icon(g_delete_model_index, 0)
			Showmenu_delete(id, g_menu_delete_current_page)
		}
	}
}

public create_ad()
{		
	g_ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(g_ent, pev_classname, MODEL_CLASSNAME)
	engfunc(EngFunc_SetModel, g_ent, g_precached_model_list[g_selected_model_index])
	set_pev(g_ent, pev_scale, 1.0)
}

public show_delete_icon(ent, show)
{
	if(!g_is_deleteicon_precached)
	{
		return 0
	}
	
	if(show)
	{
		if(!pev_valid(ent))
		{
			return 0
		}
		
		new Float:origin[3]
		
		pev(ent, pev_origin, origin)
		origin[2] += 5.0
		
		new ent2
		ent2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(ent2, pev_classname, "deleteicon")
		engfunc(EngFunc_SetModel, ent2, DELETE_ICON_PATH)
		set_pev(ent2, pev_scale, 1.0)
		engfunc(EngFunc_SetOrigin, ent2, origin)
		set_pev(ent2, pev_renderfx, kRenderFxGlowShell)
		set_pev(ent2, pev_rendercolor, {255.0, 0.0, 0.0})
		set_pev(ent2, pev_rendermode, kRenderTransAlpha)
		set_pev(ent2, pev_renderamt, 255.0)
	}
	else
	{
		new ent2 = -1
		while((ent2 = engfunc(EngFunc_FindEntityByString, ent2, "classname", "deleteicon")) != 0)
		{
			if(pev_valid(ent2))
				engfunc(EngFunc_RemoveEntity, ent2)
		}
	}
	
	return 1
}

public save_ad()
{
	new Float:f_scale
	new text[256]
	
	get_configsdir(g_filename, 255)
	format(g_filename, 255, "%s/%s/%s.txt", g_filename, CONFIG_FOLDERNAME, g_mapname)
	
	pev(g_ent, pev_angles, g_ent_angles)
	
	if(contain(g_precached_model_list[g_selected_model_index], ".spr") != -1)
	{
		pev(g_ent, pev_scale, f_scale)
		formatex(text, 255, "^n%s^norigin %f %f %f^nangles %f %f %f^nscale %f", g_precached_model_list[g_selected_model_index], g_aim_origin[0], g_aim_origin[1], g_aim_origin[2], g_ent_angles[0], g_ent_angles[1], g_ent_angles[2], f_scale)
	}
	else
	{
		formatex(text, 255, "^n%s^norigin %f %f %f^nangles %f %f %f", g_precached_model_list[g_selected_model_index], g_aim_origin[0], g_aim_origin[1], g_aim_origin[2], g_ent_angles[0], g_ent_angles[1], g_ent_angles[2])
	}
	
	write_file(g_filename, text)
	g_ent = 0
}
	
public delete_ad(ent)
{	
	new buffer[256]
	new Float:origin[3]
	new origin_str[64]
	
	
	get_configsdir(g_filename, 255)
	format(g_filename, 255, "%s/%s/%s.txt", g_filename, CONFIG_FOLDERNAME, g_mapname)
	
	pev(ent, pev_origin, origin)
	
	float_to_str(origin[0], buffer, 8)
	format(origin_str, 63, "origin %s", buffer)
	
	new line = find_line_with_string(g_filename, origin_str, 15)
	
	if(line < 0)
		return 0
	
	new f1 = fopen(g_filename, "r")
	write_file("InGameAdsTEMP.txt", "", -1)
	new f2 = fopen("InGameAdsTEMP.txt", "w")
	
	while(!feof(f1))
	{
		fgets(f1, buffer, 255)
		fputs(f2, buffer)
	}
	
	fclose(f1)
	fclose(f2)
	
	delete_file(g_filename)
	write_file(g_filename, "", -1)
	
	f1 = fopen(g_filename, "w")
	f2 = fopen("InGameAdsTEMP.txt", "r")
	
	new i = 0
	
	while(!feof(f2))
	{
		fgets(f2, buffer, 255)
		fputs(f1, buffer)
		i++
		if(i == line - 1)
		{
			fgets(f2, buffer, 255)
			fgets(f2, buffer, 255)
			i += 2
			while((contain(buffer, ".mdl") == -1) && (contain(buffer, ".spr") == -1) && !feof(f2))
			{
				fgets(f2, buffer, 255)
				i++
			}
			fputs(f1, buffer)
		}
	}
	
	fclose(f1)
	fclose(f2)
	
	delete_file("InGameAdsTEMP.txt")
	
	if(pev_valid(ent))
		return engfunc(EngFunc_RemoveEntity, ent)
		
	return 0
}

public find_line_with_string(file[], find_this[], len)
{
	new buffer[256]
	new f1 = fopen(file, "r")
	new i = 0
	
	while(!feof(f1))
	{
		fgets(f1, buffer, len)
		if(equal(buffer, find_this, len))
		{
			fclose(f1)
			return i
		}
		i++
	}
	fclose(f1)
	return -1
}

public precache_from_file(filename[])
{
	new file_handle = fopen(filename, "r")
	
	if(!file_handle)
	{
		return PLUGIN_HANDLED
	}
	
	new file_text[MAX_MODEL_NAMELEN]
	
	while(!feof(file_handle))
	{
		fgets(file_handle, file_text, MAX_MODEL_NAMELEN - 1)
		trim(file_text)
		
		if(equal(file_text, "//", 2) || !file_text[0])
		{
			continue
		}
		
		if(contain(filename, MAIN_PRECACHE_FILE) != -1)
		{
			if(dir_exists(file_text))
			{
				new dirname[MAX_MODEL_NAMELEN]
				copy(dirname, MAX_MODEL_NAMELEN - 1, file_text)
				replace_all(dirname, MAX_MODEL_NAMELEN - 1, "\", "/")
				
				new dirh = open_dir(file_text, file_text, MAX_MODEL_NAMELEN - 1)
				
				while(next_file(dirh, file_text, MAX_MODEL_NAMELEN - 1))
				{
					if(contain(file_text, ".spr") != -1 || contain(file_text, ".mdl") != -1)
					{
						format(file_text, MAX_MODEL_NAMELEN - 1, "%s/%s", dirname, file_text)
						if(!file_exists(file_text))
						{
							log_amx(ERROR_FILE_NOT_FOUND, file_text)
						}
						else
						{
							precache_model(file_text)
							
							for(new i = 0; i < MAX_AD_MODELS; i++)
							{
								if(equal(file_text, g_precached_model_list[i]))
								{
									break
								}
								else if(!g_precached_model_list[i][0])
								{
									g_precached_model_list[g_precached_model_list_len] = file_text
									g_precached_model_list_len++
									break
								}
							}
						}
					}
				}
				
				close_dir(dirh)
			}
		}
		
		if(contain(file_text, ".spr") != -1 || contain(file_text, ".mdl") != -1)
		{	
			if(!file_exists(file_text))
			{
				log_amx(ERROR_FILE_NOT_FOUND, file_text)
				continue
			}
			else
			{
				precache_model(file_text)
				
				for(new i = 0; i < MAX_AD_MODELS; i++)
				{
					if(equal(file_text, g_precached_model_list[i]))
					{
						break
					}
					else if(!g_precached_model_list[i][0])
					{
						g_precached_model_list[g_precached_model_list_len] = file_text
						g_precached_model_list_len++
						break
					}
				}
			}
		}
	}
	
	fclose(file_handle)
	
	return PLUGIN_HANDLED
}

//from fakemeta_util.inc, modified by stupok
stock fm_get_aim_origin_normal(index, Float:origin[3], Float:normal[3])
{
	static Float:start[3], Float:view_ofs[3]
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	static Float:dest[3]
	pev(index, pev_v_angle, dest)
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(start, dest, dest)
	
	static tr, Float:dist
	tr = create_tr2()
	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, index, tr)
	get_tr2(tr, TR_vecEndPos, origin)
	dist = get_distance_f(start, origin)
	origin[0] -= (origin[0] - start[0])/dist
	origin[1] -= (origin[1] - start[1])/dist
	origin[2] -= (origin[2] - start[2])/dist
	get_tr2(tr, TR_vecPlaneNormal, normal)
	free_tr2(tr)
}

stock add_to_scale(entid, Float:amount)
{
	if(!pev_valid(entid))
		return 0
	
	new Float:f_scale
	pev(entid, pev_scale, f_scale)
	set_pev(entid, pev_scale, (f_scale + amount))
	return 1
}

stock move_on_axis(id, toward)
{	
	static Float:player_origin[3], Float:distance[3], greatest
	
	pev(id, pev_origin, player_origin)

	distance[0] = floatabs(player_origin[0] - g_aim_origin[0])
	distance[1] = floatabs(player_origin[1] - g_aim_origin[1])
	distance[2] = floatabs(player_origin[2] - g_aim_origin[2])
	
	for(new i = 0; i < 3; i++)
	{
		if(distance[i] > distance[greatest])
		{
			greatest = i
		}
	}
	
	g_aim_origin[greatest] += (player_origin[greatest] > g_aim_origin[greatest] ? MOVE_DISTANCE * toward : -MOVE_DISTANCE * toward)
	
	engfunc(EngFunc_SetOrigin, g_ent, g_aim_origin)
}

stock load_saved_ads(filename[])
{	
	new file_handle = fopen(filename, "r")
	
	if(!file_handle)
	{
		return PLUGIN_HANDLED
	}
	
	new file_text[64]
	new ent, str_value[3][16], Float:f_value[3], Float:angles[3]
	new current_ad = -1
	
	while(!feof(file_handle) && current_ad < MAX_NUMBER_OF_ADS)
	{
		fgets(file_handle, file_text, 63)
		trim(file_text)
		
		if(equal(file_text, "//", 2) || !file_text[0])
			continue
		
		if(contain(file_text, ".mdl") != -1 || contain(file_text, ".spr") != -1)
		{
			if(!file_exists(file_text))
			{
				log_amx(ERROR_FILE_NOT_FOUND, file_text)
				continue
			}
			ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
			
			engfunc(EngFunc_SetModel, ent, file_text)
			
			current_ad++
		}
		else if(equal(file_text, "origin", 6))
		{
			parse(file_text[6], str_value[0], 15, str_value[1], 15, str_value[2], 15)
			
			f_value[0] = str_to_float(str_value[0])
			f_value[1] = str_to_float(str_value[1])
			f_value[2] = str_to_float(str_value[2])
			
			engfunc(EngFunc_SetOrigin, ent, f_value)
		}
		else if(equal(file_text, "angles", 6))
		{
			parse(file_text[6], str_value[0], 15, str_value[1], 15, str_value[2], 15)
			
			f_value[0] = str_to_float(str_value[0])
			f_value[1] = str_to_float(str_value[1])
			f_value[2] = str_to_float(str_value[2])
			angles = f_value
			
			set_pev(ent, pev_angles, angles)
		}
		else if(equal(file_text, "scale", 5))
		{
			parse(file_text[5], str_value[0], 15)
			
			set_pev(ent, pev_scale, str_to_float(str_value[0]))
		}
		else if(equal(file_text, "framerate", 9))
		{
			parse(file_text[9], str_value[0], 15)
			
			set_pev(ent, pev_framerate, str_to_float(str_value[0]))
			set_pev(ent, pev_spawnflags, SF_SPRITE_STARTON)
			dllfunc(DLLFunc_Spawn, ent)
			set_pev(ent, pev_angles, angles)
		}
		
		set_pev(ent, pev_classname, MODEL_CLASSNAME)
	}
	
	fclose(file_handle)
	
	return PLUGIN_HANDLED
}
