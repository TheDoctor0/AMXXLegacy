#include <amxmodx>
#include <fakemeta>

#define PLUGIN "[ZP] Auto Binder"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public client_authorized(id)
{
	client_cmd(id, "echo ^"^";^"bind^" ^"g^" ^"drop^"");
	client_cmd(id, "echo ^"^";^"bind^" ^"c^" ^"radio3^"");
	client_cmd(id, "echo ^"^";^"bind^" ^"z^" ^"+setlaser^"");
	client_cmd(id, "echo ^"^";^"bind^" ^"x^" ^"+dellaser^"");
	
	cmd_execute(id, "bind g drop");
	cmd_execute(id, "bind c radio3");
	cmd_execute(id, "bind z +setlaser");
	cmd_execute(id, "bind x +dellaser");
}

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args(szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}