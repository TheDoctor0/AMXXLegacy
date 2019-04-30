#include <amxmodx>

public plugin_init(){
	register_plugin("HashTag Replacer","1.0","O'Zone")
	register_clcmd("say", "CheckSay")
	register_clcmd("say_team", "CheckSay")
}

new block[][] = 
{
	"#Cstrike_",
	"#Career_",
	"#CZero_",
	"#Alias_",
	"#Game_",
	"#GameUI_",
	"#Spec_",
	"#Team_",
	"#Title_"
}

public client_connect(id){
	new name[32]
	get_user_name(id, name, 31)
	for(new i=0; i<sizeof(block); i++){
		if(containi(name, block[i] ) != -1){
			new uid = get_user_userid(id)
			replace_all(name, 31, "#", " ")
			server_cmd("amx_nick #%d ^"%s^"", uid, name)
		}
	}
	return PLUGIN_CONTINUE
}

public CheckSay(id)
{ 
	static szMsg[190]
	read_args(szMsg, 189)
	remove_quotes(szMsg)
		
	for(new i=0; i<sizeof(block); i++)
	{
		if(containi(szMsg, block[i]) != -1)
		{
			new gracz[32],sAuthid[35], ipt[32] 
			new fo_logfile[190],data[64],maxtext[189]
				
			get_user_name(id,gracz,31)
			get_user_ip(id,ipt,31, 1); 
			get_user_authid(id,sAuthid,34)
			get_time("%d/%m/%Y - %H:%M:%S",data,63)
			
			format(maxtext, charsmax(maxtext), "%s: [Say] [%s] [%s] [%s]",data,gracz,ipt,sAuthid)
			format(fo_logfile, 189, "addons/amxmodx/logs/exploit.txt")	
			write_file(fo_logfile,maxtext,-1)

			return PLUGIN_HANDLED
		}
	}
		
	return PLUGIN_CONTINUE
}
	
public client_infochanged(id)
{
	new name[32]
	get_user_info(id, "name", name,31)
	for(new i=0; i<sizeof(block); i++) 
	{ 
		if(containi(name, block[i]) != -1) 
		{
			new gracz[32],sAuthid[35], ipt[32] 
			new fo_logfile[42],data[64],maxtext[100]
				
			get_user_name(id,gracz,31)
			get_user_ip(id,ipt,31, 1); 
			get_user_authid(id,sAuthid,34)
			get_time("%d/%m/%Y - %H:%M:%S",data,63)
			
			format(maxtext, charsmax(maxtext), "%s: [Name] '%s' [%s] [%s]",data,gracz,ipt,sAuthid)
			format(fo_logfile, 41, "addons/amxmodx/logs/exploit.txt")	
			write_file(fo_logfile,maxtext,-1)
			
			new uid = get_user_userid(id)
			replace_all(name, 31, "#", " ")
			server_cmd("amx_nick #%d ^"%s^"", uid, name)
		}
	}
	return PLUGIN_CONTINUE
}