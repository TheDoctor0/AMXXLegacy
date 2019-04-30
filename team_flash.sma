#include <amxmodx>
#include <reapi>

#define PLUGIN  "ReAPI Soft Team Flash"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHookChain(RG_PlayerBlind, "PlayerBlind", .post = false);
}

public PlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3])
{
	if(index != attacker && (get_member(index, m_iTeam) == get_member(attacker, m_iTeam)) && alpha && color[0] == 255.0 && color[1] == 255.0 && color[2] == 255.0) 
	{
		SetHookChainArg(5, ATYPE_FLOAT, fadeHold / 4);
		SetHookChainArg(4, ATYPE_FLOAT, fadeTime / 4);

		if(fadeHold / 4 >= 0.1)
		{
			static playerName[32];

			get_user_name(attacker, playerName, charsmax(playerName));

			client_print_color(index, index, "** Zostales oslepiony na^x04 %.2fs^x01 przez^x03 %s^x01. **", fadeHold / 4, playerName);
		}
	}
}
