#include <amxmodx>
#include <amxmisc>
#include <fun>

#define PLUGIN "Noclip"
#define AUTHOR "O'Zone"
#define VERSION "1.0"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_concmd("amx_noclip", "amx_noclip", ADMIN_BAN, "<target>");
}

public amx_noclip(id,level,cid) 
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[32], admin_name[32], target_name[32];
	read_argv(1, arg, 31);

	new player = cmd_target(id, arg, 14);
	if (!player) 
		return PLUGIN_HANDLED;

	get_user_name(id, admin_name, 31);
	get_user_name(player, target_name, 31);

	if (!get_user_noclip(player)) 
	{
		set_user_noclip(player, 1);
		switch(get_cvar_num("amx_show_activity")) 
		{
			case 2:	client_print_color(0, id, "^x04Admin^x03 %s^x04 wlaczyl noclip graczowi^x03 %s^x04.", admin_name, target_name);
			case 1:	client_print_color(0, id, "^x04Admin wlaczyl noclip graczowi^x03 %s^x04.", target_name);
		}
	} 
	else 
	{
		set_user_noclip(player);
		switch(get_cvar_num("amx_show_activity")) 
		{
			case 2:	client_print_color(0, id, "^x04Admin^x03 %s^x04 wylaczyl noclip graczowi^x03 %s^x04.", admin_name, target_name);
			case 1:	client_print_color(0, id, "^x04Admin wylaczyl noclip graczowi^x03 %s^x04.", target_name);
		}
	}
	return PLUGIN_HANDLED;
}
