#include <amxmodx>
#include <fakemeta>

#pragma ctrlchar	'\'

public plugin_init() {
	register_plugin("Fast Fix #", "1.2", "PRoSToTeM@");

	register_forward(FM_ClientUserInfoChanged, "ClientUserInfoChanged_Pre", false);

	register_clcmd( "say", "CheckChat" );
	register_clcmd( "say_team", "CheckChat" );
}

public ClientUserInfoChanged_Pre(const iClient, const pszInfoBuffer) {
	new szNetName[ 64 ];
	pev(iClient, pev_netname, szNetName, charsmax( szNetName ) );
	
	new szBufferName[ 64 ];
	engfunc( EngFunc_InfoKeyValue, pszInfoBuffer, "name", szBufferName, charsmax( szBufferName ) );
	
	if (szNetName[0] != '\0' && equal(szNetName, szBufferName)) {
		return FMRES_IGNORED;
	}
	
	new bool:fChanged;
	
	for (new i = 0; szBufferName[i] != '\0'; i++) {
		if (szBufferName[i] == '#' || (szBufferName[i] == '+' && !('0' <= szBufferName[i + 1] <= '9'))) {
			szBufferName[i] = ' ';
			
			fChanged = true;
		}
	}
	
	if (fChanged) {
		trim(szBufferName);
		
		engfunc(EngFunc_SetClientKeyValue, iClient, pszInfoBuffer, "name", szBufferName);
	}
	
	return FMRES_IGNORED;
}

public CheckChat( id ) {
	static szMsg[ 191 ];
	
	read_args( szMsg, charsmax( szMsg ) );

	if( contain( szMsg, "#" ) != -1 )
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}