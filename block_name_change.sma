#include <amxmodx>

#define PLUGIN "Block Change Name"
#define VERSION "1.0"
#define AUTHOR "DJ_WEST"

#define MAX_PLAYERS 32

new g_SayText

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_SayText = get_user_msgid("SayText")
	register_message(g_SayText, "Block_NameChange")
}

public Block_NameChange(msgid, msgdest, msgent)
{
	new s_MessageType[32]
	get_msg_arg_string(2, s_MessageType, charsmax(s_MessageType))
	
	if (equal(s_MessageType, "#Cstrike_Name_Change"))
	{
		client_print(msgent, print_console, "Sorry, change name not allowed!")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public client_infochanged(id)
{
	if (is_user_connected(id))
	{
		new s_NewName[32], s_OldName[32]
		
		get_user_info(id, "name", s_NewName, charsmax(s_NewName))
		get_user_name(id, s_OldName, charsmax(s_OldName))
		
		if (!equali(s_OldName, s_NewName))
			set_user_info(id, "name", s_OldName)
	}
}




#include <amxmodx>
#include <fakemeta>
#include <amxmisc>

#define PLUGIN_NAME "No Name Change"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

new const g_reason[] = "It is NOT allowed to change nick names."
new const g_name[] = "name"
new g_iTarget = 0

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    register_forward(FM_ClientUserInfoChanged, "fwClientUserInfoChanged")
    register_concmd("amx_nick", "cmdNick", ADMIN_SLAY, "<name or #userid> <new nick>")
}

public cmdNick(id, level, cid)
{
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED

    new arg1[32], arg2[32], authid[32], name[32], authid2[32], name2[32]

    read_argv(1, arg1, 31)
    read_argv(2, arg2, 31)

    new player = cmd_target(id, arg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)

    if (!player)
        return PLUGIN_HANDLED

    get_user_authid(id, authid, 31)
    get_user_name(id, name, 31)
    get_user_authid(player, authid2, 31)
    get_user_name(player, name2, 31)

    g_iTarget = player
    set_user_info(player, "name", arg2)

    log_amx("Cmd: ^"%s<%d><%s><>^" change nick to ^"%s^" ^"%s<%d><%s><>^"", name, get_user_userid(id), authid, arg2, name2, get_user_userid(player), authid2)

    show_activity_key("ADMIN_NICK_1", "ADMIN_NICK_2", name, name2, arg2);

    console_print(id, "[AMXX] %L", id, "CHANGED_NICK", name2, arg2)

    return PLUGIN_HANDLED
}


public fwClientUserInfoChanged(id, buffer)
{
    if(!is_user_connected(id) || is_user_admin(id))
        return FMRES_IGNORED;

    static name[32], val[32]
    get_user_name(id, name, sizeof name - 1)
    engfunc(EngFunc_InfoKeyValue, buffer, g_name, val, sizeof val - 1)
    if(equal(val, name))
        return FMRES_IGNORED;

    if( g_iTarget != id )
    {
        engfunc(EngFunc_SetClientKeyValue, id, buffer, g_name, name)
        console_print(id, "%s", g_reason)
        return FMRES_SUPERCEDE;
    }
    g_iTarget = 0
    return FMRES_IGNORED
}  