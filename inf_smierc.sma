#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Info po smierci"
#define VERSION "1.0"
#define AUTHOR "DarkGL"

new maxPlayers,
	Float: taskTimeStop,
	bool:bCan[ 33 ];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar( "info_smierci_czas" , "5.0" );
	
	register_event("DeathMsg", "DeathMsg", "a")
	
	register_clcmd("say","sayHandle")
	register_clcmd("say_team","sayHandle")
	
	register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening");
	
	maxPlayers = get_maxplayers();
}

public plugin_cfg(){
	taskTimeStop =  get_cvar_float( "info_smierci_czas" );
}

public sayHandle(id){
	if( !bCan[ id ] ) {
		return PLUGIN_CONTINUE;
	}
	
	new szTmp[ 256 ],
		szPrint[190],
		szName[64];
	
	read_argv(1,szTmp,charsmax(szTmp));
	trim( szTmp )
	
	get_user_name( id , szName,charsmax( szName ) );
	
	formatex(szPrint,charsmax(szPrint),"^x04[INFO OD %s]^x03 %s",szName,szTmp);
	
	client_print_color( id , id , szPrint);
	
	for(new iPlayer = 1;iPlayer <= maxPlayers; iPlayer++){
		if( !is_user_alive( iPlayer ) || get_user_team( iPlayer ) != get_user_team(id)){
			continue;
		}
		
		client_print_color( iPlayer , iPlayer , szPrint);
	}
	
	return PLUGIN_HANDLED;
}

public DeathMsg(){
	new idVictim = read_data( 2 );
	
	if( !is_user_connected( idVictim ) || is_user_alive( idVictim ) ){
		return PLUGIN_CONTINUE;
	}
	
	bCan[ idVictim ] = true;
	
	remove_task( idVictim );
	
	set_task( taskTimeStop ,"stopInfo" , idVictim );
	
	return PLUGIN_CONTINUE;
}

public client_connect( id ){
	bCan[ id ] = false;
}

public client_disconnected( id ){
	bCan[ id ] = false;
}

public stopInfo( id ){
	bCan[ id ] = false;
	
	for(new iPlayer = 1;iPlayer <= maxPlayers; iPlayer++){
		if( !is_user_alive( iPlayer ) ){
			continue;
		}
		
		engfunc(EngFunc_SetClientListening, iPlayer, id, false);
	}
}

public Forward_SetClientListening( iReceiver, iSender, bool:bListen ) {
	if( !is_user_connected(iSender) || !is_user_connected( iReceiver ) ){
		return FMRES_IGNORED;
	}
	
	if( get_user_team(iSender) != get_user_team( iReceiver ) ){
		return FMRES_IGNORED;
	}
	
	if( !bCan[iSender] ){
		return FMRES_IGNORED;
	}
	
	engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
	forward_return(FMV_CELL, true);
	
	return FMRES_SUPERCEDE
}
