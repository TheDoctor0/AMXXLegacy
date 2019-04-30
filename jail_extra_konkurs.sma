#include <amxmodx>

#define PLUGIN "JailBreak: Konkurs"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /konkurs", "Konkurs");
	register_clcmd("say_team /konkurs", "Konkurs");
	register_clcmd("konkurs", "Konkurs");	
}

public Konkurs(id)
{
	new menu = menu_create("\rWiezienie CS-Reload \ySprawdz Konkursy na Serwerze", "Konkurs_Handler"); 
	
	menu_additem(menu, "\wKonkurs \y1");
	menu_additem(menu, "\wKonkurs \y2");
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public Konkurs_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: show_motd(id, "konkurs_1.txt", "Konkurs 1"); 
		case 1: show_motd(id, "konkurs_2.txt", "Konkurs 2"); 
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/