#include <amxmodx>

#define PLUGIN  "Ultimate CSStats"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

//Natives:
//get_stats(index,stats[8],bodyhits[8],name[],len); - overall stats for index from ranking  (https://www.amxmodx.org/api/tsstats/get_stats)
//get_stats2(index, stats[4], authid[] = "", authidlen = 0); - overall stats for objectives for index from ranking (https://www.amxmodx.org/api/csstats/get_stats2)
//get_user_stats(index,stats[8],bodyhits[8]); - overall player stats (https://www.amxmodx.org/api/tsstats/get_user_stats)
//get_user_stats2(index, stats[4]); - overall player stats for objectives (https://www.amxmodx.org/api/csstats/get_user_stats2)
//get_statsnum(); - numbers of players in ranking (https://www.amxmodx.org/api/tsstats/get_statsnum)
//get_user_wstats(index,wpnindex,stats[8],bodyhits[8]); - overall player stats for given weapon (https://www.amxmodx.org/api/tsstats/get_user_wstats)
//get_user_wrstats(index,wpnindex,stats[8],bodyhits[8]); - round player stats for given weapon (https://www.amxmodx.org/api/tsstats/get_user_wrstats)
//

new enum _:forwardsData {
	FORWARD_DAMAGE,
	FORWARD_DEATH,
	FORWARD_ASSIST,
	FORWARD_PLANTING,
	FORWARD_PLANTED,
	FORWARD_EXPLODE,
	FORWARD_DEFUSING,
	FORWARD_DEFUSED,
	FORWARD_THROW
};

new enum statsData {

};

new playerStats[MAX_PLAYERS + 1][statsData], statsForwards[forwardsData], ret;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	create_cvar("csstats_sql_host", "sql.pukawka.pl", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("csstats_sql_user", "510128", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("csstats_sql_pass", "xvQ5CusRVCVzj83aruWk", FCVAR_SPONLY | FCVAR_PROTECTED); 
	create_cvar("csstats_sql_db", "590489_stats", FCVAR_SPONLY | FCVAR_PROTECTED);
	
	statsForwards[FORWARD_DAMAGE] = CreateMultiForward("client_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_DEATH] =  CreateMultiForward("client_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_ASSIST] = CreateMultiForward("client_assist", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	statsForwards[FORWARD_PLANTING] = CreateMultiForward("bomb_planting", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_PLANTED] = CreateMultiForward("bomb_planted", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_EXPLODE] = CreateMultiForward("bomb_explode", ET_IGNORE, FP_CELL, FP_CELL);
	statsForwards[FORWARD_DEFUSING] = CreateMultiForward("bomb_defusing", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_DEFUSED] = CreateMultiForward("bomb_defused", ET_IGNORE, FP_CELL);
	statsForwards[FORWARD_THROW] = CreateMultiForward("grenade_throw", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);

	register_logevent("eventRoundEnd", 2, "1=Round_End");
	register_logevent("eventRoundStart", 2, "1=Round_Start");
	register_logevent("eventBombPlanted", 3, "2=Planted_The_Bomb");
	register_logevent("eventBombDefused", 3, "2=Defused_The_Bomb");
	register_logevent("eventBombDefusing", 3, "2=Begin_Bomb_Defuse_Without_Kit");
	register_logevent("eventBombDefusing", 3, "2=Begin_Bomb_Defuse_With_Kit");
	register_logevent("eventBombExplode", 6, "3=Target_Bombed");

	register_event("HLTV", "eventNewRound", "a", "1=0", "2=0");
	register_event("SendAudio", "eventTWin" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "eventCTWin", "a", "2&%!MRAD_ct_win_round");
	register_event("23", "eventBombPlantedNoRound", "a", "1=17", "6=-105", "7=17");
	register_event("BarTime", "eventBombPlanting", "be", "1=3");
	register_event("CurWeapon", "eventCurWeapon", "b" ,"1=1");
	register_event("Damage", "eventDamage","b", "2!0");
}

public eventBombPlanting(planter)
	ExecuteForward(statsForwards[FORWARD_PLANTING], ret, planter);

public eventBombPlanted()
{
	new planter = get_loguser_index();

	//Stats planted +1
	
	ExecuteForward(statsForwards[FORWARD_PLANTED], ret, planter);
}

public eventBombPlantedNoRound(planter)
	ExecuteForward(statsForwards[FORWARD_PLANTED], ret, planter);

public eventBombDefused()
{
	new defuser = get_loguser_index();

	//Stats defused +1
	
	ExecuteForward(statsForwards[FORWARD_DEFUSED], ret, defuser);
}

public eventBombDefusing()
{
	new defuser = get_loguser_index();

	// Stats defusing + 1
}

public eventBombExplode()
{
	new planter = get_loguser_index();

	//Stats explode +1
	
	ExecuteForward(statsForwards[FORWARD_EXPLODE], ret, planter);
}

public eventCurWeapon(id)
{
	static weaponsAmmo[MAX_PLAYERS + 1][CSW_P90 + 1], weapon, ammo;
	
	weapon = read_data(2);
	ammo = read_data(3);
	
	if (weaponsAmmo[player][weapon] != ammo) {
		if (weaponsAmmo[player][WEAPON] > ammo) // Stats save shot

		weaponsAmmo[player][WEAPON] = ammo;
	}
}

public eventDamage(victim)
{
	static damage, inflictor, attacker, weapon, hitPlace, sameTeam;

	damage = read_data(2);
	inflictor = pev(victim, pev_dmg_inflictor);
	
	if (!pev_valid(inflictor)) return;

	attacker = get_user_attacker(victim, weapon, hitPlace);

	sameTeam = get_user_team(victim) == get_user_team(attacker) ? true : false;
	
	if (!(0 < inflictor <= MAX_PLAYERS)) weapon = CSW_HEGRENADE;
	
	if (0 <= hitPlace < HIT_END) {
		ExecuteForward(statsForwards[FORWARD_DAMAGE], ret, attacker, victim, damage, weapon, hitPlace, sameTeam);

		// Stats save hit

		if(!is_user_alive(victim)) {
			ExecuteForward(statsForwards[FORWARD_DEATH], ret, attacker, victim, weapon, hitPlace, sameTeam);

			// Stats save kill
		}
	}
}

public eventTWin()
	roundWinner(1);
	
public eventCTWin()
	roundWinner(2);

public roundWinner(team)
{
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || get_user_team(id) != team) continue;

		// Stats win + 1
	}
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], queryData[512], error[128], errorNum;
	
	get_cvar_string("csstats_sql_host", host, charsmax(host));
	get_cvar_string("csstats_sql_user", user, charsmax(user));
	get_cvar_string("csstats_sql_pass", pass, charsmax(pass));
	get_cvar_string("csstats_sql_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("csstats.log", "Error: %s", error);
		
		return;
	}
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csstats` (`name` VARCHAR(35) NOT NULL, `class` VARCHAR(64) NOT NULL, `exp` INT UNSIGNED NOT NULL DEFAULT 0, `level` INT UNSIGNED NOT NULL DEFAULT 1, `intelligence` INT UNSIGNED NOT NULL DEFAULT 0, ");
	add(queryData,  charsmax(queryData), "`health` INT UNSIGNED NOT NULL DEFAULT 0, `stamina` INT UNSIGNED NOT NULL DEFAULT 0, `condition` INT UNSIGNED NOT NULL DEFAULT 0, `strength` INT UNSIGNED NOT NULL DEFAULT 0, PRIMARY KEY(`name`, `class`));");   

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

stock get_loguser_index()
{
	new userLog[96], userName[32];
	
	read_logargv(0, userLog, charsmax(userLog));
	parse_loguser(userLog, userName, charsmax(userName));

	return get_user_index(userName);
}