#include <amxmodx>
#include <fakemeta>
#include <regex>
#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif	

#define PLUGIN "Kick Spamers"
#define VERSION "0.6.1"
#define AUTHOR "gyxoBka"

#define MAXPLAYERS 32                        // максимальное количество игроков на сервере
#define ADMIN_FLAG ADMIN_BAN                // флаг админа, которого будет игнорировать ( по умолчанию 'd' )
#define CHECK_CHAT                         // Проверка сообщений в чате. закомментируйте, чтобы не проверять

enum _:CVARS
{
	SITE,
	WAIT,
	WARNINGS
}

new g_iCvars[CVARS]

new Regex:g_RegexIP, Regex:g_RegexSite;

new g_iWarnings[MAXPLAYERS+1];
new Float:g_flWaitTime[MAXPLAYERS + 1];

new bool:g_bRegexSite
#if defined CHECK_CHAT
new g_szMessage[192]
#endif

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar( "kickspamers", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED )
	
	register_forward(FM_ClientUserInfoChanged,"fw_ClientUserInfoChanged", false);
	
	LoadCvars();
	LoadRegex();
	
	if(get_pcvar_num(g_iCvars[SITE])) g_bRegexSite = true
	
	#if defined CHECK_CHAT
	register_clcmd("say","HookSay");
	register_clcmd("say_team","HookTeamSay");
	#endif
}

public client_putinserver(id)
{
	if(get_user_flags(id) & ADMIN_FLAG || is_user_hltv(id) ) return PLUGIN_HANDLED;

	NickControl(id)
	return PLUGIN_CONTINUE;
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	g_flWaitTime[id] = 0.0
	g_iWarnings[id] = 0

}		

public fw_ClientUserInfoChanged(id, szBuffer)
{
	if(!is_user_alive(id) || get_user_flags(id) & ADMIN_FLAG) return FMRES_IGNORED;

	static szOldName[32], szNewName[32];
	get_user_name(id, szOldName, 31);
	engfunc(EngFunc_InfoKeyValue, szBuffer, "name", szNewName, 31);
	
	if(equali(szOldName, szNewName)) return FMRES_IGNORED;
	
	static piWaitTime; piWaitTime = get_pcvar_num(g_iCvars[WAIT]); 
	static Float:flTime; flTime = get_gametime();

	if(g_flWaitTime[id] > flTime)
	{
		g_flWaitTime[id] = flTime + piWaitTime;
			
		engfunc(EngFunc_SetClientKeyValue, id, szBuffer, "name", szOldName);
			
		if(++g_iWarnings[id] >= get_pcvar_num(g_iCvars[WARNINGS]))
		{
			server_cmd("kick #%d You changed name too fast", get_user_userid(id));
		}	
		client_print_color(id, 0, "^1[^4 Предупреждение^1 ]^3 Нельзя часто менять ник ^1[^4%d^1/^4%d^1]^3!",g_iWarnings[id], get_pcvar_num(g_iCvars[WARNINGS]))
		return FMRES_SUPERCEDE
	}	
	g_flWaitTime[id] = flTime + piWaitTime;
	NickControl(id, szNewName)
	
	return FMRES_HANDLED;
}

#if defined CHECK_CHAT
public HookSay(id)
{
	static ret; ret = 0
	read_args(g_szMessage,191);
	remove_quotes(g_szMessage);
	
	if(equal(g_szMessage,""))return PLUGIN_HANDLED;
	
	if( regex_match_c( g_szMessage, g_RegexIP, ret) > 0) return PLUGIN_HANDLED_MAIN;
	
	if( regex_match_c( g_szMessage, g_RegexSite, ret) > 0) return PLUGIN_HANDLED_MAIN;

	return PLUGIN_CONTINUE
}

public HookTeamSay(id)
{
	static ret; ret = 0
	read_args(g_szMessage,191);
	remove_quotes(g_szMessage);
	
	if(equal(g_szMessage,""))return PLUGIN_HANDLED;
	
	if( regex_match_c( g_szMessage, g_RegexIP, ret) > 0) return PLUGIN_HANDLED_MAIN;

	if( regex_match_c( g_szMessage, g_RegexSite, ret) > 0) return PLUGIN_HANDLED_MAIN;
	
	return PLUGIN_CONTINUE
}
#endif

NickControl(const id, szName[32] = "")
{
	new ret;
	if( strlen(szName) == 0 ) get_user_name(id, szName, 31)

	CheckIP(id)
	
	if( g_bRegexSite )
	{
		if( regex_match_c( szName, g_RegexSite, ret) > 0)
		{
			server_cmd("kick #%d [BadName] Change name and try again.", get_user_userid(id))
			PrintLog("[SPAM] Игрок %s был кикнут за спам сайта", szName)
		}
	}
}

CheckIP(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	new iLen = strlen(szName)
	new iNum, iChar, iTemp
	
	for(new i; i < iLen; i++)
	{
		iTemp = szName[i]
		
		if ('0' <= iTemp <= '9') iNum++
		else iChar++
	}
	
	if( iNum > iChar ) 
	{
		server_cmd("kick #%d [BadName] Change name and try again.", get_user_userid(id))
		PrintLog("[SPAM] Игрок %s был кикнут за спам IP", szName)
	}
}

PrintLog(const szMessage[], any:...)
{
	static szMsg[100];
	vformat(szMsg, charsmax(szMsg), szMessage, 2);
	
	log_to_file("KickSpamers.txt", "%s", szMsg)
}
	
LoadCvars()
{
	g_iCvars[SITE] = register_cvar( "regex_match_site", 	"0"		);
	g_iCvars[WARNINGS] 	 = register_cvar( "max_warnings", 	"3"		);
	g_iCvars[WAIT] 		 = register_cvar( "min_wait", 		"10"	);
}

LoadRegex()
{
	// Паттерн на IP
	new szPatternIP[] = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
	// Паттерн на Site
	new szPatternSite[] = "(?:\w+\.[a-z]{2,4}\b|(?:\s*\d+\s*\.){3})"
	new ret, error[128]

	g_RegexIP = regex_compile( szPatternIP, ret, error, charsmax(error), "i" )
	if(g_RegexIP == REGEX_PATTERN_FAIL) 
		return set_fail_state("|     Incorrect pattern IP.    |");	
		
	g_RegexSite = regex_compile( szPatternSite, ret, error, charsmax(error), "i" )
	if(g_RegexSite == REGEX_PATTERN_FAIL) 
		return set_fail_state("|     Incorrect pattern SITE.    |");	
	
	return PLUGIN_CONTINUE
}	

#if AMXX_VERSION_NUM < 183
stock replace_string(text[], maxlength, const search[], const Replace[])
{
	replace_all(text, maxlength, search, Replace)
}
#endif