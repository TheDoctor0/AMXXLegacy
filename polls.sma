#include <amxmodx>

#define PLUGIN  "Ankiety"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /ankieta", "command_poll");
	register_clcmd("say_team /ankieta", "command_poll");
	register_clcmd("say /ankiety", "command_poll");
	register_clcmd("say_team /ankiety", "command_poll");
}

public command_poll(id)
{
	new menu = menu_create("\yAnkiety dotyczace \rzmian \yna serwerze\w:", "command_poll_handle");
 
	menu_additem(menu, "\wAnkieta \rI \w- \ykomenda /bank");
	menu_additem(menu, "\wAnkieta \rII \w- \yoslepianie druzyny");
	menu_additem(menu, "\wAnkieta \rIII \w- \yprzenikanie");
    
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}  
 
public command_poll_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
    
	switch(item)
	{ 
		case 0: show_motd(id, "ankieta1.txt", "Ankieta I");
		case 1: show_motd(id, "ankieta2.txt", "Ankieta II");
		case 2: show_motd(id, "ankieta3.txt", "Ankieta III");
	}
	
	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}
