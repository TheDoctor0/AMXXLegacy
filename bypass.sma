#include <amxmodx>

#define PLUGIN  "Bypass SklepSMS License"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	set_task(15.0, "bypass_license");
}

public bypass_license()
{
	new plugin = find_plugin_byfile("sklep_sms.amxx"), func = get_func_id("getWebPageValidateLicense", plugin);

	if(func != -1)
	{
		callfunc_begin_i(func, plugin);
		callfunc_push_str("<text>updated</text>");
		callfunc_push_int(0);
		callfunc_push_int(-1);
		callfunc_push_int(200);
		callfunc_end();
	}
}