#include <amxmodx>

public plugin_init()
{
	register_plugin("[ZP] Buy Block", "1.0", "O'Zone");

	register_clcmd("glock","block")
	register_clcmd("usp","block")
	register_clcmd("p228","block")
	register_clcmd("deagle","block")
	register_clcmd("fn57","block")
	register_clcmd("elites","block")
	register_clcmd("m3","block")
	register_clcmd("xm1014","block")
	register_clcmd("tmp","block")
	register_clcmd("mac10","block")
	register_clcmd("mp5","block")
	register_clcmd("ump45","block")
	register_clcmd("p90","block")
	register_clcmd("galil","block")
	register_clcmd("famas","block")
	register_clcmd("ak47","block")
	register_clcmd("m4a1","block")
	register_clcmd("sg552","block")
	register_clcmd("aug","block")
	register_clcmd("scout","block")
	register_clcmd("sg550","block")
	register_clcmd("awp","block")
	register_clcmd("g3sg1","block")
	register_clcmd("m249","block")
	register_clcmd("primammo","block")
	register_clcmd("secammo","block")
	register_clcmd("vest","block")
	register_clcmd("vesthelm","block")
	register_clcmd("flash","block")
	register_clcmd("hegren","block")
	register_clcmd("sgren","block")
	register_clcmd("nvgs","block")
	register_clcmd("shield","block")
	register_clcmd("defuser","block")
}

public block() 
	return PLUGIN_HANDLED