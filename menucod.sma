#include <amxmodx>
#include <amxmisc>
#define PLUGIN "Menu Gracza"
#define VERSION "1.0"
#define AUTHOR "O`Zone"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd ("say /menu", "menu");
	register_clcmd("say_team /menu","menu");
	register_clcmd("menu", "menu");	
}

public client_putinserver(id)
	cmdExecute(id,"bind v menu")

public menu(id)
{
	new tytul[64];
	format(tytul, 63, "\rMenu Komend CoD");
	new menu = menu_create(tytul, "menu_handler");
	menu_additem(menu, "Wybierz \rKlase","1",0);//1
	menu_additem(menu, "Opisy \rKlas","2",0);//2
	menu_additem(menu, "Opis \rItemu","3",0);//3
	menu_additem(menu, "Opisy \rItemow","4",0);//4
	menu_additem(menu, "Wyrzuc \rItem","5",0);//5
	menu_additem(menu, "Daj \rItem","6",0);//6
	menu_additem(menu, "Sklep \rCoD","7",0);//7
	menu_additem(menu, "Resetuj \rStatystyki","8",0);//8
	menu_setprop(menu,MPROP_EXIT,MEXIT_ALL);
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public menu_handler(id,menu,item)
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
  
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data); 

	switch(key) 
	{ 
		case 1 : { 
		engclient_cmd(id, "klasa") 
		} 
		case 2 : { 
		engclient_cmd(id, "klasy") 
		} 
		case 3 : { 
		engclient_cmd(id, "item") 
		} 
		case 4 : { 
		engclient_cmd(id, "itemy") 
		} 
		case 5 : { 
		engclient_cmd(id, "drop") 
		} 
		case 6 : { 
		engclient_cmd(id, "daj") 
		} 
		case 7 : { 
		engclient_cmd(id, "sklep") 
		} 
		case 8 : { 
		engclient_cmd(id, "reset") 
		} 
	} 
	return PLUGIN_HANDLED 
}

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args( szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1250\\ deff0\\ deflang1045{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
