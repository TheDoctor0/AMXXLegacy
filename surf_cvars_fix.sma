#include <amxmodx>
#include <amxmisc>
#include <surf>
#include <fakemeta>
  
#define PLUGIN "Surf Cvars Fix"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	
	SetCvars();
}

public NewRound()
	SetCvars();
	
public SetCvars()
{
	server_cmd("sv_gravity 800");
	server_cmd("sv_airmove 1");
	server_cmd("sv_airaccelerate 100");
	server_cmd("sv_accelerate 1000");
}