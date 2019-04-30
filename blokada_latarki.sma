#include <amxmodx>
#include <fakemeta>

public plugin_init()
{
	register_plugin("Blokada Latarki", "1.0", "O'Zone");
	register_forward(FM_CmdStart, "FlashlightEvent");
}

public FlashlightEvent(id, uc_handle, seed )
{
	if(get_uc(uc_handle, UC_Impulse) == 100)
	{
		set_uc(uc_handle, UC_Impulse, 0);
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}