#include <amxmodx>

#define MAX_PLAYERS 31

public plugin_init()
	register_plugin("Redirection", "1.0", "O'Zone")

public client_authorized(id)
{
	if(get_user_flags(id) & ADMIN_RESERVATION || get_user_flags(id) & ADMIN_BAN)
		return PLUGIN_CONTINUE;

	if(get_playersnum() >= MAX_PLAYERS)
		client_execute(id, "connect 91.224.117.113");
		
	return PLUGIN_CONTINUE;
}

stock client_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    new szMessage[256];

    format_args(szMessage ,charsmax(szMessage), 1);

    message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
    write_byte(strlen(szMessage) + 2);
    write_byte(10);
    write_string(szMessage);
    message_end();
}
