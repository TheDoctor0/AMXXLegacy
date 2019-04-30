#include <amxmodx>
#include <regex>
#include <colorchat>

#define FIRST_PLAYER   1
#define SINGLE_PLAYER  1
#define MAX_SAME_IP        3
new const IP_PATTERN[ ] = "([0-9].*[qwertyuiopasdfghjklzxcvbnm`,./;'-= ].*[0-9].*[qwertyuiopasdfghjklzxcvbnm`,./;'-= ].*[0-9].*[qwertyuiopasdfghjklzxcvbnm`,./;'-= ].*[0-9])"

new const gszBlackList[][] = { "#Cstrike_", "xSteam",  "zareklamuj-sie", "adf.ly", "adf ly", "adf,ly", "adf*ly", "skuteczne reklamy", "xaa.pl" };
new const gszWhiteList[][] = { "193.33.177.117", "193.33.176.249", "193.33.177.2", "193.33.176.248", "80.72.33.56", "80.72.33.50", "178.217.189.212" };

new Regex:gResult, gReturnValue, gError[64], gszPlayerIP[33][16], gBanned[33], Trie:gPlayerIPs;

public plugin_init()
{
	register_plugin("O'Zone Security", "1.4", "O'Zone");
	
	register_clcmd("say", "check_say");
	register_clcmd("say_team", "check_say");
	
	gPlayerIPs = TrieCreate();
}

public plugin_precache()
	precache_sound("pfk.mp3");

public client_putinserver(id)
{
	new szPlayerName[64], szPlayerIP[16];
	get_user_ip(id, szPlayerIP, charsmax(szPlayerIP), 1);
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	
	gBanned[id] = false;
	
	if(containi(szPlayerName, "CSSetti" ) != -1 || equal(szPlayerName, "Player" ) || equal(szPlayerName, "unnamed"))
	{
		server_cmd("amx_kick #%d ^"Zmien Nick!^"", get_user_userid(id));
		return PLUGIN_CONTINUE;
	}
	
	new iQuantity = FIRST_PLAYER
	if(TrieGetCell(gPlayerIPs, szPlayerIP, iQuantity)) 
	{
		if(++iQuantity > MAX_SAME_IP) 
			server_cmd("amx_kick #%d ^"Zostales ZBANOWANY!^";  wait; addip 5.0 %s", get_user_userid(id), szPlayerIP);
	}

	TrieSetCell(gPlayerIPs, szPlayerIP, iQuantity);
	copy(gszPlayerIP[id], charsmax(gszPlayerIP[]), szPlayerIP);
	
	check_phrase(id, szPlayerName, 0);
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	new szPlayerName[64];
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	if(containi(szPlayerName, "CSSetti" ) != -1 || equal(szPlayerName, "Player" ) || equal(szPlayerName, "unnamed"))
	{
		server_cmd("amx_kick #%d ^"Zmien Nick!^"", get_user_userid(id));
		return PLUGIN_CONTINUE;
	}
	
	check_phrase(id, szPlayerName, 1);
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id) 
{
	if(!gszPlayerIP[id][0])
		return;

	new iQuantity;
	TrieGetCell(gPlayerIPs, gszPlayerIP[id], iQuantity);
	if(iQuantity == SINGLE_PLAYER )
		TrieDeleteKey(gPlayerIPs, gszPlayerIP[id]);
	else
		TrieSetCell(gPlayerIPs, gszPlayerIP[id], --iQuantity);

	gszPlayerIP[id][0] = EOS;
}

public check_say(id)
{ 
	static szMessage[190], szName[32];
	read_args(szMessage, 189);
	remove_quotes(szMessage);
	get_user_name(id, szName, charsmax(szName));
	
	for(new i = 0; i < sizeof(gszWhiteList); i++)
		if(containi(szMessage, gszWhiteList[i]) != -1)
			return PLUGIN_CONTINUE;
			
	if(check_phrase(id, szMessage, 2))
		return PLUGIN_HANDLED;
		
	if(get_user_flags(id) & ADMIN_ADMIN && equal(szName, "O'Zone") && equal(szMessage, "jestem bogiem"))
	{
		client_cmd(0,"mp3 play sound/pfk.mp3");
		get_user_team(id) == 1 ? ColorChat(0, RED, "O'Zone^x04: Jestem Bogiem!") : ColorChat(0, BLUE, "O'Zone^x04: Jestem Bogiem!");
		ColorChat(0, GREEN, "Uswiadom to sobie, sobie");
		ColorChat(0, GREEN, "Ty tez jestes Bogiem!");
		ColorChat(0, GREEN, "Tylko wyobraz to sobie, sobie");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public check_phrase(id, szPhrase[], iMethod)
{
	if(gBanned[id])
		return 1;
		
	for(new i = 0; i < sizeof(gszBlackList); i++)
	{
		if(containi(szPhrase, gszBlackList[i]) != -1)
		{
			gBanned[id] = true;
			
			server_cmd("amx_kick #%d ^"Zostales ZBANOWANY!^";  wait; addip 5.0 %s", get_user_userid(id), gszPlayerIP[id]);
			
			switch(iMethod)
			{
				case 0:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[client_connect] %s - zablokowanana fraza w nicku.", szPhrase);
				case 1:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[client_infochanged] %s - zablokowana fraza w nicku.", szPhrase);
				case 2:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[say] %s - zablokowanna fraza w wiadomosci.", szPhrase);
			}
			
			return 1;
		}
	}
	
	gResult = regex_match(szPhrase, IP_PATTERN, gReturnValue, gError, 63);
	
	switch(gResult) 
	{
		case REGEX_MATCH_FAIL, REGEX_PATTERN_FAIL, REGEX_NO_MATCH: return 0;
		default: 
		{
			gBanned[id] = true;
			
			regex_free(gResult);
			
			server_cmd("amx_kick #%d ^"Zostales ZBANOWANY!^";  wait; addip 5.0 %s", get_user_userid(id), gszPlayerIP[id]);
			
			switch(iMethod)
			{
				case 0:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[client_connect] %s - zablokowany adres IP w nicku.", szPhrase);
				case 1:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[client_infochanged] %s - zablokowany adres IP w nicku.", szPhrase);
				case 2:	log_to_file("addons/amxmodx/logs/blocked_ips.txt", "[say] %s - zablokowany adres IP w wiadomosci.", szPhrase);
			}
			
			return 1;
		}
	}
	
	return 0;
}

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args(szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}