#include <amxmodx>
#include <colorchat>

#define PLUGIN "Wynik"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

new CT, TT;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("HLTV", "Nowa_Runda", "a", "1=0", "2=0");
	register_event("TeamScore", "TT_Score", "a", "1=TERRORIST");
	register_event("TeamScore", "CT_Score", "a", "1=CT");
}

public Nowa_Runda()
{
	for(new id = 1; id < 33; id++ )
	{
		if(!is_user_connected(id) || is_user_hltv(id) || get_user_team(id) == 3) 
			continue;
		
		if(CT == TT)
			ColorChat(id, GREY, "Remis^x04 %d^x01 :^x04 %d", CT, TT);
		
		if(CT > TT)
			ColorChat(id, BLUE, "Antyterrorysci^x01 prowadza^x04 %d^x01 :^x04 %d", CT, TT);
		
		if(CT <TT)
			ColorChat(id, RED, "Terrorysci^x01 prowadza^x04 %d^x01 :^x04 %d", TT, CT);
	}
}

public TT_Score()
	TT = read_data(2);

public CT_Score()
	CT = read_data(2);
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/