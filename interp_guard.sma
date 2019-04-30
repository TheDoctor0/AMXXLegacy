#include <amxmodx>

#define PLUGIN "Interp Guard"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_CHECK 72765

//#define RATE

public plugin_init() 
	register_plugin(PLUGIN, VERSION, AUTHOR);

public client_disconnected(id)
	remove_task(id + TASK_CHECK);

public client_putinserver(id)
{
	if(task_exists(id + TASK_CHECK)) remove_task(id + TASK_CHECK);
			
	set_task(0.1, "Check", id + TASK_CHECK);
}

public Check(id) 
{
	id -= TASK_CHECK;
	
	if(is_user_connected(id)) 
	{
		client_cmd(id, "ex_interp 0.01");
		cmd_execute(id, "ex_interp 0.01");
		#if defined RATE
		client_cmd(id, "rate 25000");
		cmd_execute(id, "rate 25000");
		client_cmd(id, "cl_updaterate 101");
		cmd_execute(id, "cl_updaterate 101");
		client_cmd(id, "cl_cmdrate 101");
		cmd_execute(id, "cl_cmdrate 101");
		#endif
		
		set_task(30.0, "Check", id+TASK_CHECK);
	}
}

stock cmd_execute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
		new szMessage[256];

		format_args(szMessage ,charsmax(szMessage), 1);

		message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
		write_byte(strlen(szMessage) + 2);
		write_byte(10);
		write_string(szMessage);
		message_end();
    }
}