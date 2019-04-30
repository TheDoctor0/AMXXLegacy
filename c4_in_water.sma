#include <amxmodx> 
#include <fakemeta> 
#include <hamsandwich> 

#define PLUGIN "Fix C4 in water"
#define VERSION "1.0"  
#define AUTHOR "O'Zone"

public plugin_init() 
{ 
    register_plugin(PLUGIN, VERSION, AUTHOR);
	
    RegisterHam(Ham_Think, "grenade", "C4_Think");
} 

public C4_Think(iEnt) 
{ 
    if(get_pdata_int(iEnt, 96) & (1<<8) && pev(iEnt, pev_waterlevel) >= 2) 
        set_pev(iEnt, pev_waterlevel, 0);
}  