/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <ColorChat>
#include <fakemeta>
#include <engine>
#include <sqlx>

#define PLUGIN "Deathrun Rangi"
#define VERSION "1.1"
#define AUTHOR "speedkill & benio101"

#define max_level 16

#define TOP_DATA_BUFFER_SIZE 1536

enum deathrun
{
	skoki,
	ranga[64]
}

new stats[33][deathrun]

new msg[2][33]
new lvl[33]

new nick_gracza[33][64]

new Prefiks[64]

new bool:LoadData[33]
new bool:MenuOpened[33]

new Handle:g_SqlTuple

#include "db.inl"

new const g_Rangi[][] = 
{
	"Nowicjusz Reload",
	"Mlodszy amator",
	"Starszy amator",
	"Majster",
	"Starszy majster",
	"SpeedRunner",
	"BH Master",
	"Czlowiek BH",
	"Skoczek",
	"Pro BH Gamer",
	"Runner",
	"BunnyHoper",
	"Jumper",
	"Spider-Man",
	"Wariacik",
	"SLONIU"
}

new const g_Wymogi[] =
{
	0,
	300,
	600,
	1200,
	2100,
	3250,
	5000,
	7300,
	10000,
	14000,
	18500,
	23000,
	29000,
	35500,
	42000,
	50000
}

new g_NewLvl
new g_Best

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /rangi","Menu")
	register_forward(FM_CmdStart, "counting")
	register_logevent("Load", 2, "1=Round_Start") 
	
	g_NewLvl = CreateMultiForward("dr_rangi_new_lvl", ET_IGNORE, FP_CELL)
	g_Best = CreateMultiForward("dr_rangi_best_player", ET_IGNORE, FP_CELL)
	
	register_cvars()
}
public register_cvars()
{
	register_cvar("amx_dr_rangi_host", "	sql.pukawka.pl",FCVAR_PROTECTED)
	register_cvar("amx_dr_rangi_user", "497657",FCVAR_PROTECTED)
	register_cvar("amx_dr_rangi_pass", "4NqTz4TB7lKLWF",FCVAR_PROTECTED)
	register_cvar("amx_dr_rangi_db", "497657_klasydeathrun",FCVAR_PROTECTED)
	
	register_cvar("amx_dr_rangi_team", "2")  // 0 - wszyscy, 1 - tylko Terro, 2 - tylko CT, 3 - nikt
	register_cvar("amx_dr_rangi_speed", "290") 
	register_cvar("amx_dr_rangi_show_best","1")
	register_cvar("amx_dr_rangi_prefiks","[Deathrun_Rangi]")
}
public plugin_cfg()
{
	get_cvar_string("amx_dr_rangi_prefiks",Prefiks,charsmax(Prefiks))
	
	sql_connect()
}
public plugin_end()
{
	SQL_FreeHandle(g_SqlTuple)
}
public plugin_natives()
{
	register_library("Deathrun_Rangi")
	register_native("get_user_jumps", "get_user_jumps",1)
	register_native("get_user_rang", "get_user_rang",1)
}
public client_authorized(id)
{
	get_user_name(id, nick_gracza[id], charsmax(nick_gracza[]))
	replace_all(nick_gracza[id], charsmax(nick_gracza[]), "'", "\'")
	replace_all(nick_gracza[id], charsmax(nick_gracza[]), "`", "\`")
	sql_load(id)
}
public client_disconnect(id)
{
	sql_save(id)
	
	clear(id)
}
public clear(id)
{
	stats[id][skoki] = 0
	
	for(new i = 0; i < 2; i++)
		msg[i][id] = 0
	
	lvl[id] = 0	
	LoadData[id] = false
	MenuOpened[id] = false
}	
public client_infochanged(id)
{
	new szName[64]
	get_user_info(id,"name",szName,charsmax(szName))
	
	copy(nick_gracza[id],charsmax(nick_gracza[]),szName)
}
public counting(id,uc_handle)
{
	static button,flags
	button = get_uc(uc_handle,UC_Buttons)
	flags = pev(id, pev_flags)
	
	if(button & IN_JUMP)
	{
		if(flags & FL_ONGROUND)
		{
			if(get_cvar_num("amx_dr_rangi_team")-3 && (3-get_user_team(id)!=get_cvar_num("amx_dr_rangi_team")) && fm_get_user_speed(id) >= get_cvar_num("amx_dr_rangi_speed"))
			{
				stats[id][skoki]++
				show(id)
			}
		}
	}
}
public show(id)
{
	new poziom = 0
	for(new i=0;i<sizeof g_Wymogi;i++)
	{
		if(stats[id][skoki] >= g_Wymogi[i])
		{
			poziom++
			if(poziom > lvl[id])
			{
				ColorChat(id,GREEN,"^x03%s^x04 Awansowales do rangi : ^x03%s",Prefiks,g_Rangi[poziom - 1])
				new iRet
				ExecuteForward(g_NewLvl,iRet,id)
				
				if(MenuOpened[id])
					set_task(1.0,"Menu",id)
			}
		}
		else
			break
	}
	
	lvl[id] = poziom
	poziom--
	formatex(stats[id][ranga],63, "%s",g_Rangi[poziom])
	
	new bool:check = (poziom == max_level) ? true : false
	new wiad[128]
	
	if(msg[1][id] == 0)
		formatex(wiad,charsmax(wiad),"Skoki : %d/%d | Ranga : %s",stats[id][skoki],check ? 0 : g_Wymogi[poziom + 1],stats[id][ranga])
	else
		formatex(wiad,charsmax(wiad),"Skoki : %d/%d",stats[id][skoki],check ? 0 : g_Wymogi[poziom + 1])
	
	switch(msg[0][id])
	{
		case 0: 
			client_print(id,print_center,"%s",wiad)
		case 1: 
			show_status(id,"%s",wiad)
		case 2: 
			show_status(id,"")
	}
}
public Menu(id)
{
	MenuOpened[id] = true
	new tytul[128]
	formatex(tytul,charsmax(tytul),"\wDeathrun rangi^n\ySkoki : \d%d | \yRanga : \d%s^n^n",stats[id][skoki],stats[id][ranga])
	new menu = menu_create(tytul, "Wybor")
	
	menu_additem(menu, "\rTop10")
	menu_additem(menu, "\wTwoj ranking")
	menu_additem(menu, "\yOpis rang i ich wymagania")
	
	switch(msg[0][id])
	{
		case 0: 
			menu_additem(menu, "\dInformacja o skokach : \ySrodek")
		case 1:
			menu_additem(menu, "\dInformacja o skokach : \wLewy dolny rog")
		case 2:	
			menu_additem(menu, "\dInformacja o skokach : \rBrak")
	}
	switch(msg[1][id])
	{
		case 0:
			menu_additem(menu, "\wRanga przy ilosci skokow : \rTak")
		case 1: 
			menu_additem(menu, "\wRanga przy ilosci skokow : \yNie")
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie")
	menu_display(id, menu)
}
public Wybor(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: 
			Top10(id)
		case 1: 
			Rank_Load(id)
		case 2: 
			motd(id)
		case 3:
		{
			switch(msg[0][id])
			{	
				case 0: 
					msg[0][id] = 1
				case 1:
					msg[0][id] = 2
				case 2: 
					msg[0][id] = 0
			}
			Menu(id)
		}
		case 4:
		{
			switch(msg[1][id])
			{
				case 0:
					msg[1][id] = 1
				case 1:
					msg[1][id] = 0
			}
			Menu(id)
		}
	}
	MenuOpened[id] = false
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public motd(id)
{
	static Data[TOP_DATA_BUFFER_SIZE],Title[33],Len
	
	Len = formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<html><body bgcolor=Black><br>")								
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<center><table frame=^"border^" width=^"600^" cellspacing=^"0^" bordercolor=#4A4344 style=^"color:#56A5EC;text-align:center;^">")
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tr><td><b>Ranga</b></td><td><b>Wymagania</b></td></td></tr>")
	
	for(new i;i<sizeof g_Wymogi;i++)
	{
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tr>")
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%s</td>",g_Rangi[i])
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%d</td>",g_Wymogi[i])
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "</tr>")
	}
	Len += formatex(Data[Len],TOP_DATA_BUFFER_SIZE - Len,"</center></body></html>")
	
	formatex(Title, 32, "Opis Rang")
	show_motd(id, Data, Title)
	
}
public Top10(id)
{
	new szTemp[512],Data[1]
	Data[0] = id
	format(szTemp,charsmax(szTemp),"SELECT * FROM Deathrun_Rangi ORDER BY skoki DESC LIMIT 10")
	SQL_ThreadQuery(g_SqlTuple,"Top",szTemp,Data,sizeof(Data))
}
public Top(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState)
	{
		log_amx("SQL Error: %s (%d)", Error, Errcode)
		return PLUGIN_HANDLED
	}
	new id = Data[0]
	static Data[TOP_DATA_BUFFER_SIZE],Title[33],Len, Place,name[64],rangi[64],s
	
	Place = 0
	
	Len = formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<html><body bgcolor=Black><br>")								
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<center><table frame=^"border^" width=^"600^" cellspacing=^"0^" bordercolor=#4A4344 style=^"color:#56A5EC;text-align:center;^">")
	Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tr><td><b>#</b></td><td><b>Nick</b></td><td><b>Skoki</b></td></td><td><b>Ranga</b></td></tr>")
	
	while(SQL_MoreResults(Query))
	{
		Place++
		SQL_ReadResult(Query,0,name,charsmax(name))
		SQL_ReadResult(Query,2,rangi,charsmax(rangi))
		s = SQL_ReadResult(Query,1)
		
		replace_all(name,charsmax(name), "<", "")
		replace_all(name,charsmax(name), ">", "")
		
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<tr>")
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td><font color=Red>%d</font></td>", Place)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%s</td>",name)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%d</td>",s)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "<td>%s</td>",rangi)
		Len += formatex(Data[Len], TOP_DATA_BUFFER_SIZE - Len, "</tr>")
		
		SQL_NextRow(Query)
	}
	
	Len += formatex(Data[Len],TOP_DATA_BUFFER_SIZE - Len,"</center></body></html>")
	
	formatex(Title, 32, "Top 10 Skoczkow")
	show_motd(id, Data, Title)
	
	return PLUGIN_CONTINUE
}
public Rank_Load(id)
{	
	new szTemp[512],Data[1]
	Data[0] = id
	format(szTemp,charsmax(szTemp),"SELECT COUNT(*) FROM Deathrun_Rangi WHERE `skoki` >= %d",stats[id][skoki])
	SQL_ThreadQuery(g_SqlTuple,"Rank",szTemp,Data,1)
}

public Rank(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState)
	{
		log_amx("SQL Error: %s (%d)", Error, Errcode)
		return PLUGIN_HANDLED 
	}
	new count, id = Data[0]
	
	count = SQL_ReadResult(Query,0)
	
	if(count == 0)
		count = 1
	
	ColorChat(id,GREEN,"%s^x03 Zajmujesz %d miejsce z %d skokami i ranga %s",Prefiks,count,stats[id][skoki],stats[id][ranga])
	
	return PLUGIN_CONTINUE
}
public Load()
{
	for(new i=1;i<33;i++)
	{
		if(is_user_connected(i))
			sql_save(i)
	}
	
	if(get_cvar_num("amx_dr_rangi_show_best"))
		Best_Load()
}
public Best_Load() 
{
	new szTemp[512]
	format(szTemp,charsmax(szTemp),"SELECT * FROM Deathrun_Rangi ORDER BY skoki DESC LIMIT 1")
	SQL_ThreadQuery(g_SqlTuple,"Best",szTemp)
}
public Best(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState)
	{
		log_amx("SQL Error: %s (%d)", Error, Errcode)
		return PLUGIN_HANDLED 
	}
	new n[64],r[64],s
	
	SQL_ReadResult(Query,0,n,charsmax(n))
	SQL_ReadResult(Query,2,r,charsmax(r))
	s = SQL_ReadResult(Query,1)
	
	ColorChat(0,GREEN,"%s^x03 Prowadzi gracz %s z %d skokami i ranga %s",Prefiks,n,s,r)
	for(new i=1;i<33;i++)
	{
		if(is_user_connected(i))
		{
			if(equal(nick_gracza[i],n))
			{
				new iRet
				ExecuteForward(g_Best,iRet,i)
			}
		}
	}
	return PLUGIN_CONTINUE
}
public get_user_rang(id)
{
	return stats[id][ranga]
}
public get_user_jumps(id)
{
	return stats[id][skoki]
}
stock Float:fm_get_user_speed(id)
{
	if(!is_user_connected(id))
		return 0.0;
	
	static Float:fVelocity[3]
	pev(id, pev_velocity, fVelocity)
	
	fVelocity[2] = 0.0
	
	return vector_length(fVelocity)
}
//From dr_stats
stock show_status(id, const szMsg[], any:...)
{
	new szStatus[128]
	vformat(szStatus, 127, szMsg, 3)
	
	message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("StatusText"), _, id)
	write_byte(0)
	write_string(szStatus)
	message_end()
}
