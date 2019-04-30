#include <amxmodx>
#include <messages>

#define ADMIN_FLAG_TILDE	(1<<29)	/* flag "~" */
#define IsPlayer(%1)		(1<=%1<=maxPlayers)
#define KILLER_FLAG		(1<<0)
#define VICTIM_FLAG		(1<<1)

new maxPlayers;
new msgDeathMsg;
new msgTeamInfo;
new bool:msgDeathMsgActive=true;

new teams[4][]={
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

public plugin_init(){
	register_plugin("VIP grey kill nick", "1.1", "benio101");
}

public plugin_cfg(){
	maxPlayers=get_maxplayers();				// pobieramy liczbê slotów
	
	msgDeathMsg=get_user_msgid("DeathMsg");			// cache`ujemy id eventu DeathMsg
	msgTeamInfo=get_user_msgid("TeamInfo");			// cache`ujemy id eventu TeamInfo
	
	// rejestrujemy DeathMsg
	register_message(msgDeathMsg, "DeathMsg");
}

public DeathMsg(){
	if(msgDeathMsgActive){
		new kid=get_msg_arg_int(1); 			// zabojca
		new vid=get_msg_arg_int(2); 			// ofiara
		
		// suma bitów: 1 jeœli zabójca jest vipem, 2 jeœli ofiara jest vipem.
		new vipid=0;
		
		if(IsPlayer(kid) && get_user_flags(kid) & ADMIN_FLAG_TILDE){
			vipid|=KILLER_FLAG; 			// zabojca jest vipem
		}
		if(IsPlayer(vid) && get_user_flags(vid) & ADMIN_FLAG_TILDE){
			vipid|=VICTIM_FLAG;			// ofiara jest vipem
		}
		
		if(vipid){
			new killer_team, victim_team, weapon[32];
			
			// pobieramy broñ
			get_msg_arg_string(4, weapon, 31);
			
			if(vipid & KILLER_FLAG){ 		// zabojca jest vipem
				// zmieniamy dru¿ynê zabojcy na SPECTATORA (kolor szary)
				message_begin(MSG_BROADCAST, msgTeamInfo);
				write_byte(kid);
				write_string("SPECTATOR");
				message_end();
				
				// pobieramy dru¿ynê zabójcy
				killer_team=get_user_team(kid);
			}
			
			if(vipid & VICTIM_FLAG){ 		// ofiara jest vipem
				// zmieniamy dru¿ynê zabojcy na SPECTATORA (kolor szary)
				message_begin(MSG_BROADCAST, msgTeamInfo);
				write_byte(vid);
				write_string("SPECTATOR");
				message_end();
				
				// pobieramy dru¿ynê ofiary
				victim_team=get_user_team(vid);
			}
			
			// w³asnego wywo³ania wiadomoœci nie chcemy ³apaæ
			msgDeathMsgActive=false;
			
			// wyœwietlamy informacjê o zabójstwie (VIP ma ju¿ nick szary)
			message_begin(MSG_BROADCAST, msgDeathMsg);
			write_byte(kid);
			write_byte(vid);
			write_byte(get_msg_arg_int(3));
			write_string(weapon);
			message_end();
			
			// wiadomoœc wys³ana, ³apiemy wiadomoœci na nowo
			msgDeathMsgActive=true;
			
			if(vipid & KILLER_FLAG){ 		// zabojca jest vipem
				// przywracamy w³aœciw¹ dru¿ynê zabójcy
				message_begin(MSG_BROADCAST, msgTeamInfo);
				write_byte(kid);
				write_string(teams[killer_team]);
				message_end();
			}
			
			if(vipid & VICTIM_FLAG){ 		// ofiara jest vipem
				// przywracamy w³aœciw¹ dru¿ynê ofierze
				message_begin(MSG_BROADCAST, msgTeamInfo);
				write_byte(vid);
				write_string(teams[victim_team]);
				message_end();
			}
			
			// blokujemy wiadomoœæ, sami j¹ wyœwietliliœmy
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

/*
	11.06 16:14 Aktualizacja pluginu do wersji 1.1:
		Od teraz, jeœli zarówno zabójca, jak i ofiara s¹ vipami, to obydwa nicki s¹ kolorowane.
*/