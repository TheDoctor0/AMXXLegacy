#include <amxmodx>
 
#define PLUGIN "4FUN Menu"
#define VERSION "1.0"
#define AUTHOR "O'Zone" 

new const szCommandMenu[][] = { "say /menu", "say_team /menu", "menu" };

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof szCommandMenu; i++)
		register_clcmd(szCommandMenu[i], "ShowMenu");
}

public client_putinserver(id)
{
	client_cmd(id,"bind ^"v^" ^"menu^"");
	cmd_execute(id, "bind v menu");
}

public ShowMenu(id)
{
	new menu = menu_create("\wMenu \rSerwera", "ShowMenu_Handle");
 
	menu_additem(menu, "\wZmien \rSerwer \y(/serwer)", "1");
	menu_additem(menu, "\wSklep \rSMS \y(/sklepsms)", "2");
	menu_additem(menu, "\wZestawy \rBroni \y(/zestawy)", "3");
	menu_additem(menu, "\wWymagania \rZestawow \y(/wymagania)", "4");
	menu_additem(menu, "\wSprzedaj \rBron \y(/sprzedaj)", "5");
	menu_additem(menu, "\wKup \rRedBulla \y(/redbull)", "6");
	menu_additem(menu, "\wUzyj \rRuletki \y(/ruletka)", "7");
	menu_additem(menu, "\wInformacje o \rVIPie \y(/vip)", "8");
	menu_additem(menu, "\wLista \rVIPow \y(/vipy)", "9");
	menu_additem(menu, "\wZarzadzaj \rRS \y(/rs)", "10");
	if(get_user_flags(id) & ADMIN_BAN)
		menu_additem(menu, "\wMenu \rAdmina \y(amxmodmenu)", "11");
    
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	
	menu_display(id, menu, 0);
}
 
public ShowMenu_Handle(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
	
    new szData[4], iAccess, iCallback;
    menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
    
    new iKey = str_to_num(szData);
    
    switch(iKey)
    { 
       case 1: client_cmd(id, "say /serwer"); 
       case 2: client_cmd(id, "say /sklepsms"); 
	   case 3: client_cmd(id, "say /zestawy"); 
	   case 4: client_cmd(id, "say /wymagania"); 
	   case 5: client_cmd(id, "say /sprzedaj"); 
	   case 6: client_cmd(id, "say /redbull"); 
	   case 7: client_cmd(id, "say /ruletka"); 
	   case 8: client_cmd(id, "say /vip"); 
	   case 9: client_cmd(id, "say /vipy");
	   case 10: client_cmd(id, "say /rs");
	   case 11: client_cmd(id, "amxmodmenu");
    }
	
    menu_destroy(menu);
    return PLUGIN_HANDLED;
} 

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if(id == 0 || is_user_connected(id))
	{
    	new szMessage[256];

    	format_args( szMessage ,charsmax(szMessage), 1);

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
        write_byte(strlen(szMessage) + 2);
        write_byte(10);
        write_string(szMessage);
        message_end();
    }
}