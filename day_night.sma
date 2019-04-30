#include <amxmodx>
#include <amxmisc>
#include <engine>

new normalsky[64]

public plugin_init()
{
    get_cvar_string("sv_skyname" , normalsky , 63); 
    register_plugin("Pogoda","1.0","KaMaZZ")
    pogoda()
}

public pogoda()
{
    new today_str[8]
    get_time("%H",today_str,8)
    new today = str_to_num(today_str)
    
    if((today >= 0) && (today < 4))
    {
        set_lights("b")
        set_cvar_string("sv_skyname", "night")
    }
    if((today >= 4) && (today < 6))
    {
        set_lights("c")
        set_cvar_string("sv_skyname", "night")
    }
    if((today >= 6) && (today < 7))
    {
        set_lights("f")
        set_cvar_string("sv_skyname", "space")
    }
    if((today >= 7) && (today < 12))
    {
        set_lights("i")
        set_cvar_string("sv_skyname", "normal")
    }
    if((today >= 12) && (today < 16))
    {
        set_lights("m")
        set_cvar_string("sv_skyname", "normal")
    }
    if((today >= 16) && (today < 18))
    {
        set_lights("k")
        set_cvar_string("sv_skyname", "normal")
    }
    if((today >= 18) && (today < 20))
    {
        set_lights("g")
        set_cvar_string("sv_skyname", "normal")
    }
    if((today >= 20) && (today < 22))
    {
        set_lights("e")
        set_cvar_string("sv_skyname", "space")
    }
    if((today >= 22) && (today < 24))
    {
        set_lights("c")
        set_cvar_string("sv_skyname", "night")
    }
}  