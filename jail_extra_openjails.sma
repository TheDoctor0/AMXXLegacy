#include <amxmodx>
#include <jailbreak>
#include <fakemeta_util>

#define PLUGIN "JailBreak: Open Jails"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new bool:bVoted[33], bool:bOpened, Float:fTime, iVotes;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /cele", "OtworzCele");
	register_clcmd("say_team /cele", "OtworzCele");
	register_clcmd("cele", "OtworzCele");
	
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("DeathMsg", "DeathMsg", "a");
	
	register_logevent("RoundStart", 2, "1=Round_Start") ;
}

public client_disconnected(id)
	if(bVoted[id]) bVoted[id] = false;

public RoundStart()
	fTime = get_gametime();

public NewRound()
{	
	static iPlayers[32], iNum;
	
	get_players(iPlayers, iNum);
	
	for(new i = 0; i < iNum; i++) bVoted[iPlayers[i]] = false;
	
	iVotes = 0;
	
	bOpened = false;
}

public DeathMsg()
{
	new victim = read_data(1);
	
	if(is_user_connected(victim) && get_user_team(victim) == 1 && bVoted[victim]) bVoted[victim] = false;	
}

public OtworzCele(id)
{	
	switch(get_user_team(id))
	{
		case 1: WiezienOtworzCele(id);
		case 2: ProwadzacyOtworzCele(id);
	}
	
	return PLUGIN_HANDLED;
}

public ProwadzacyOtworzCele(id)
{
	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Nie mozesz otworzyc celi bedac martwy.");
		
		return PLUGIN_HANDLED;		
	}	

	if(jail_get_prowadzacy() != id)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Tylko prowadzacy moze otworzyc cele.");
		
		return PLUGIN_HANDLED;		
	}	

	jail_open_cele();
	
	bOpened = !bOpened;
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Cele zostaly^x03 %s^x01.", bOpened ? "otwarte" : "zamkniete");
	
	return PLUGIN_HANDLED;	
}

public WiezienOtworzCele(id)
{
	if(!is_user_alive(id))
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Jak chcesz wyjsc skoro nie zyjesz?");
		
		return PLUGIN_HANDLED;		
	}	
	
	if(bOpened)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Cele juz zostaly otwarte");
		
		return PLUGIN_HANDLED
	}	
	
	if(jail_get_play_game())
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Teraz trwa zabawa!");
		
		return PLUGIN_HANDLED;
	}
	
	new Float:fTimeNow = get_gametime();
	
	if(fTimeNow - fTime < 30.0)
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Za wczesnie, czekaj na straznikow!");
		
		return PLUGIN_HANDLED;
	}
	
	new iNeeded = needed_votes();
	
	if(!bVoted[id])
	{	
		iVotes++;
		
		bVoted[id] = true;
		
		if(iVotes >= iNeeded)
		{
			jail_open_cele();
			
			bOpened = true;
			
			client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Wiezniowie sie zbuntowali i otworzyli cele!");
			
			return PLUGIN_HANDLED;
		}
		else client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Oky... niech Twoi kumple jeszcze wpisza (potrzeba jeszcze %d glosow)", iNeeded - iVotes);
	}
	else
	{
		client_print_color(id, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Juz glosowales na otworzenie celi (potrzeba jeszcze %d glosow) !", iNeeded - iVotes);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

stock needed_votes()
	return floatround(float(active_players()) * 0.8 + 0.49);

stock active_players()
{
	new iPlayers[32], iNum, iActive = 0;
	
	get_players(iPlayers, iNum, "h");
	
	for(new i = 0; i < iNum; i++) if(get_user_team(iPlayers[i]) == 1 && is_user_alive(iPlayers[i])) iActive++;

	return iActive;
}