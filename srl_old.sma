#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define SRL_PREFIX "Serwery"
#define TASK_INFO 345

new configsdir[200], serversfile[200]
new Data[255], charnum, szNum[3]
new Left[25], Right[50], menu_name[100]
new LastIP[26], LastName[50]
new g_fServers
new Trie:g_iServers
new Trie:g_nServers

public plugin_init()
{
	register_plugin("Server Redirect List", "1.0", "O'Zone")
	
	register_clcmd("say /servers", "Servers")
	register_clcmd("say_team /servers", "Servers")
	register_clcmd("say /server", "Servers")
	register_clcmd("say_team /server", "Servers")
	register_clcmd("say /join", "Join")
	register_clcmd("say_team /join", "Join")
	
	register_clcmd("say /serwery", "Servers")
	register_clcmd("say_team /serwery", "Servers")
	register_clcmd("say /serwer", "Servers")
	register_clcmd("say_team /serwer", "Servers")
	register_clcmd("say /dolacz", "Join")
	register_clcmd("say_team /dolacz", "Join")
	
	get_configsdir(configsdir, charsmax(configsdir))
	format(serversfile, charsmax(serversfile), "%s/servers.cfg", configsdir)
	g_fServers = file_size(serversfile, 1)
	
	if(!file_exists(serversfile))
	{
		new error[100]
		formatex(error, charsmax(error), "[%s] Nie mozna zaladowac pliku konfiguracyjnego: %s!", SRL_PREFIX, serversfile)
		set_fail_state(error)
		return
	}
}

public Servers(id)
{
	formatex(menu_name, charsmax(menu_name), "\r[ Menu Serwerow ]^n", SRL_PREFIX)
	new menu = menu_create(menu_name, "Menu_Handler")
	
	g_nServers = TrieCreate()
	g_iServers = TrieCreate()
	
	for(new i; i < g_fServers; i++)
	{
		new menuText[80]
		read_file(serversfile, i, Data, charsmax(Data), charnum)
		if(strlen(Data) < 2 || Data[0] == ';' || equali(Data, "//", 2))
			continue
		
		strbreak(Data, Left, charsmax(Left), Right, charsmax(Right))
			
		remove_quotes(Left)
		remove_quotes(Right)
		num_to_str(i, szNum, 2)
		
		formatex(menuText, charsmax(menuText), "\y[%s] \w[%s]", Right, Left)
		
		menu_additem(menu, menuText, szNum, 0)
		
		TrieSetString(g_nServers, menuText, Right)
		TrieSetString(g_iServers, menuText, Left)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public Menu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	new info[3], name[80], _access, callback
	menu_item_getinfo(menu, item, _access, info, 2, name, 95, callback)
	
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	new szServerIP[26]
	TrieGetString(g_iServers, name, szServerIP, 25)
	TrieGetString(g_iServers, name, LastIP, 25)
	
	new szServerName[50]
	TrieGetString(g_nServers, name, szServerName, 49)
	TrieGetString(g_nServers, name, LastName, 25)
	
	cmdExecute(id,"connect %s", szServerIP)
	
	new message[190]
	formatex(message, charsmax(message), "[%s]^x03 %s^x01 zostal przekierowany na^x04 %s.", SRL_PREFIX, szName, szServerName)
	ColorChat(0, GREEN, message)
	formatex(message, charsmax(message), "[%s]^x01 Wpisz^x04 /dolacz^x01, aby dolaczyc do niego.", SRL_PREFIX)
	ColorChat(0, GREEN, message)
}

public Join(id)
{
	if(equal(LastIP, "")){
		ColorChat(id, GREEN, "[%s]^x01 Nikt nie zostal jeszcze przekierowany na zaden serwer.", SRL_PREFIX)
		return;
	}
	
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	cmdExecute(id,"connect %s", LastIP)
	
	new message[190]
	formatex(message, charsmax(message), "[%s]^x03 %s^x01 zostal przekierowany na^x04 %s.", SRL_PREFIX, szName, LastName)
	ColorChat(0, GREEN, message)
	formatex(message, charsmax(message), "[%s]^x01 Wpisz^x04 /dolacz^x01, aby dolaczyc do niego.", SRL_PREFIX)
	ColorChat(0, GREEN, message)
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