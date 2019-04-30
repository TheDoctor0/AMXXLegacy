#include <amxmodx>
#include <fakemeta>

#define PLUGIN  "Name Change Detector"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public client_connect(id)
{
	new name[33], name2[33], name3[33];
	get_user_name(id, name, charsmax(name));
	pev(id, pev_netname, name2, charsmax(name2));
	get_user_info(id, "name", name3, charsmax(name3));

	if(containi(name, "addons") != -1) log_to_file("names_addons.log", "[Connect] Name: %s | Info: %s | Net: %s", name, name2, name3);
}

public client_authorized(id)
{
	new name[33], name2[33], name3[33];
	get_user_name(id, name, charsmax(name));
	pev(id, pev_netname, name2, charsmax(name2));
	get_user_info(id, "name", name3, charsmax(name3));

	if(containi(name, "addons") != -1) log_to_file("names_addons.log", "[Authorized] Name: %s | Info: %s | Net: %s", name, name2, name3);
}

public client_putinserver(id)
{
	new name[33], name2[33], name3[33];
	get_user_name(id, name, charsmax(name));
	pev(id, pev_netname, name2, charsmax(name2));
	get_user_info(id, "name", name3, charsmax(name3));

	if(containi(name, "addons") != -1) log_to_file("names_addons.log", "[Connected] Name: %s | Info: %s | Net: %s", name, name2, name3);
}

public client_infochanged(id)
{
	new szNewName[64], szName[64];
		
	get_user_info(id, "name", szNewName, charsmax(szNewName));
	get_user_name(id, szName, charsmax(szName));

	if(!equal(szName, szNewName) && szName[0])
	{
		log_to_file("names_change.log", "Name Change | OldName: %s | NewName: %s", szName, szNewName);
		if(containi(szNewName, "addons") != -1)
		{
			set_user_info(id, "name", szName);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;	
}