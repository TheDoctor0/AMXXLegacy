#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Losowe wiadomosci"
#define VERSION "1.0"
#define AUTHOR "R3X //edit by ogury"

#define TASKID_MESSAGE 1345
#define MESSAGE_MAXLEN 128

new Array:gszInfos;
new Array:giColors;

new giSize;

new const giDefaultColor[3] = {255, 255, 255};

new gcvarFromStart;

new gcvarStay;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_logevent( "eventRoundStart",2, "1=Round_Start");
	register_event("BombDrop", "eventBombPlanted", "a", "4=1");
	
	gszInfos = ArrayCreate(MESSAGE_MAXLEN);
	giColors = ArrayCreate(3);
	
	gcvarFromStart = register_cvar("amx_msgrand_from_start", "0.1");
	
	gcvarStay = register_cvar("amx_msgrand_staytime", "3.0");
}

public plugin_cfg(){
	static szFile[MESSAGE_MAXLEN+64];
	get_datadir(szFile, charsmax(szFile));
	
	add(szFile, charsmax(szFile), "/losowe_wiadomosci.txt");
	
	new fp = fopen(szFile, "rt");
	if(!fp){
		set_fail_state("Brak pliku 'losowe_wiadomosci.txt' w katalogu data/");
		return;
	}
	
	new R[4], G[4], B[4];
	new iNum;
	new iColor[3];
	
	while(!feof(fp)){
		fgets(fp, szFile, charsmax(szFile));
		trim(szFile);
		
		if(szFile[0] == ';') 
		continue;
		
		iNum = parse(szFile, szFile, MESSAGE_MAXLEN-1, R, 3, G, 3, B, 3);
		
		if(iNum == 4){
			iColor[0] = str_to_num(R);
			iColor[1] = str_to_num(G);
			iColor[2] = str_to_num(B);
			}else
			iColor = giDefaultColor;
			
			ArrayPushString(gszInfos, szFile);
			ArrayPushArray(giColors, iColor);
		}

		giSize = ArraySize(gszInfos);

		if(giSize == 0)
		set_fail_state("Brak wiadomosci");
	}

	public eventRoundStart(){
		new Float:fTime;
		fTime = get_pcvar_float(gcvarFromStart);
		set_task(fTime, "taskDisplayRandom", TASKID_MESSAGE);
	}

	public eventBombPlanted(){
		if(task_exists(TASKID_MESSAGE))
		remove_task(TASKID_MESSAGE);
	}

	public taskDisplayRandom(){
		new index = random(giSize);

		new iColor[3];
		ArrayGetArray(giColors, index, iColor);

		set_hudmessage(iColor[0], iColor[1], iColor[2], 0.04, 0.54, 0, 6.0, get_pcvar_float(gcvarStay), 1.0, 0.5, -1);
		show_hudmessage(0, "%a", ArrayGetStringHandle(gszInfos, index));


	}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
