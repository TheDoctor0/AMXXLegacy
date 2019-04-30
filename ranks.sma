#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <csx>

#define PLUGIN "Ranks"
#define VERSION "2.5"
#define AUTHOR "O'Zone"

#define TASK_HUD 999
#define MAX_RANKS 21

new kills[33];
new rank[33] = 0;
new gHUD;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	gHUD = CreateHudSyncObj();
}	

new const RankName[MAX_RANKS][] = { 
	"Lamus",
	"Poczatkujacy",
	"Wiesniak",
	"Sierota",
	"Cherlak",
	"Doswiadczony",
	"Kozak",
	"Kox",
	"Macho",
	"Joker",
	"Snajper",
	"Rambo",
	"Terminator",
	"Morfeusz",
	"Wybraniec",
	"Killer",
	"Multi Killer",
	"Mistrz",
	"Owner",
	"GOD",
	"Legenda CS-Reload"
};

new const gRankKills[MAX_RANKS] = {
	0,
	150,
	500,
	800,
	2500,
	5000,
	8000,
	13000,
	20000,
	28000,
	40000,
	50000,
	60000,
	70000,
	80000,
	90000,
	100000
};

public client_putinserver(id)
	set_task(0.5, "DisplayHUD", id+TASK_HUD, .flags="b");
	
public client_disconnect(id)
	remove_task(id+TASK_HUD);

public DisplayHUD(id) {
	id -= TASK_HUD;

	if (is_user_bot(id) || !is_user_connected(id))
	return PLUGIN_CONTINUE;

	if(!is_user_alive(id)) {
		new target = pev(id, pev_iuser2);
		
		if(!target)
		return PLUGIN_CONTINUE;
		
		new rankname = rank[target];
		new nextrankkills = floatround(gRankKills[rankname+1] * 0.1);
		set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.6, 0.0, 0.0, 3);
		ShowSyncHudMsg(id, gHUD,"[Ranga]: %s^n[Zabicia]: %d/%d^n[Forum]: CS-Reload.pl", RankName[rankname], kills[target], nextrankkills);
	}
	else {
		static stats[8], bodyhits[8];
		get_user_stats(id, stats, bodyhits);
		kills[id] = stats[0];
		
		for (new counter = 0; counter < MAX_RANKS; counter++) {
			if (kills[id] >= floatround(gRankKills[counter]*0.1)) {
				rank[id] = counter;
			}
			else break;
		}
		new rankname = rank[id];
		new nextrankkills = floatround(gRankKills[rankname+1] * 0.1);
		set_hudmessage(0, 255, 0, 0.01, 0.85, 0, 0.0, 0.6, 0.0, 0.0, 3);
		ShowSyncHudMsg(id, gHUD,"[Ranga]: %s || [Zabicia]: %d/%d || [Forum]: CS-Reload.pl", RankName[rankname], kills[id], nextrankkills);
	}
	return PLUGIN_CONTINUE;
}
