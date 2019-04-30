#include <amxmodx>

new const PLUGIN[] = "Universal Map Chooser";
new const VERSION[] = "2.34";
new const AUTHOR[] = "DeRoiD & O'Zone";

#define MapID 180912

#define R 240
#define G 240
#define B 240

#define CHUD 1.5
#define MaxCSpeed 5.0

#define Max 100
#define MinRounds 5
#define MaxChoice 9
#define PMPage 6
#define MaxSB 8

#define StartVoteFlag ADMIN_LEVEL_A
#define InfoFlag ADMIN_BAN
#define RoundFlag ADMIN_RCON

#pragma semicolon 1

new MapFile[64], LastMapsFile[64], MapCycle[32], MapFile_Lines, LastMapsFile_Lines, MapCycle_Lines, LastMapsNum;
new Maps[Max][32], LastMaps[Max][32], MapName[32], MapNames[MaxChoice][32], MapRevote[2][32], NomMaps[Max][32], NomNum, Nom, Nomed[Max];
new MapVote[MaxChoice], RevoteCounts[2], VoteMenu, RevoteMenu, MapCounter, VotedMap[32], BeginCounter;
new AllVotes, AllRevotes, Next[32], RTV, RTVTime[3], PlayerMap[33], ElapsedTime[3], VoteMod;
new bool:Voted, bool:PlayerVoted[33], bool:ChangeMap, bool:Begined, bool:inProcess, bool:Revoted,
bool:PlayerRTV[33], bool:toRTV, bool:AlreadyNom[33], bool:PlayerRevoted[33], bool:NeedRV;
new SayText, Rounds, MaxRounds, TimeLimit, oRounds, Lang, StartButton, PlayedCount, Started;

new Cvar_WaitVoteMenuTime, Cvar_MenuDestroyTime, Cvar_RTVMinute, Cvar_VoteCounter,
Cvar_NomChance, Cvar_VoteSound, Cvar_Extend, Cvar_StartRevoteTime, Cvar_VotePercentMin,
Cvar_Nomination, Cvar_PlayedMaps, Cvar_LastMaps, Cvar_RTV, Cvar_VoteVariable, Cvar_RTVMin, 
Cvar_Mod, Cvar_ChangeSpeed, Cvar_MaxMaps, Cvar_WaitRevoteMenuTime, Cvar_HudMod, 
Cvar_OnlyNextRound, Cvar_CountSound, Cvar_ChooseSound, Cvar_StartButton, Cvar_LangMode;

new Prefix[32], sHudObj, Off;

new const MapMenuCommands[][] =
{
	"/playedmaps",
	"/pm",
	"!playedmaps",
	"!pm",
	"playedmaps",
	"pm",
	"/rozegrane",
	"!rozegrane",
	"rozegrane",
	"/grane",
	"!grane",
	"grane"
};
new const TimeLeftCommands[][] =
{
	"/timeleft",
	"/tl",
	"!timeleft",
	"!tl",
	"timeleft",
	"tl",
	"/pozostalyczas",
	"!pozostalyczas",
	"pozostalyczas"
};
new const NextMapCommands[][] =
{
	"/nextmap",
	"/nm",
	"!nextmap",
	"!nm",
	"nextmap",
	"nm",
	"/nastepnamapa",
	"!nastepnamapa",
	"nastepnamapa"
};
new const AdminCommands[][] =
{
	"/startvote",
	"!startvote",
	"startvote",
	"/glosowanie",
	"!glosowanie"
};
new const RTVCommands[][] =
{
	"/rtv",
	"!rtv",
	"/rockthevote",
	"!rockthevote",
	"rockthevote",
	"rtv"
};
new const NomCommands[][] =
{
	"/nom",
	"!nom",
	"/nomination",
	"!nomination",
	"nom",
	"nomination",
	"/nominacja",
	"!nominacja",
	"nominacja"
};
new const CurrentMapCommands[][] =
{
	"/currentmap",
	"!currentmap",
	"/cm",
	"!cm",
	"currentmap",
	"cm",
	"/mapa",
	"!mapa",
	"mapa",
	"/aktualnamapa",
	"!aktualnamapa",
	"aktualnamapa"
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("dmc.txt");
	sHudObj = CreateHudSyncObj();
	
	static ConfigsDir[64]; 
	get_localinfo("amxx_configsdir", ConfigsDir, 63);
	formatex(MapFile, 63, "%s/mapdatas.dmc", ConfigsDir);
	formatex(LastMapsFile, 63, "%s/lastmaps.dmc", ConfigsDir);
	formatex(MapCycle, 31, "mapcycle.txt");
	formatex(Prefix, 31, "!g[MAPA]");
	
	MapFile_Lines = file_size(MapFile, 1);
	LastMapsFile_Lines = file_size(LastMapsFile, 1);
	MapCycle_Lines = file_size(MapCycle, 1);
	
	Cvar_Mod = register_cvar("dmc_mod", "1");
	Cvar_HudMod = register_cvar("dmc_hudmod", "1");
	Cvar_ChangeSpeed = register_cvar("dmc_changespeed", "5.0");
	Cvar_WaitVoteMenuTime = register_cvar("dmc_waitvotemenutime", "10.0");
	Cvar_WaitRevoteMenuTime = register_cvar("dmc_waitrevotemenutime", "5.0");
	Cvar_MenuDestroyTime = register_cvar("dmc_menudestroyTime", "5.0");
	Cvar_RTVMinute = register_cvar("dmc_rtvminute", "5");
	Cvar_VoteCounter = register_cvar("dmc_votecounter", "15");
	Cvar_VoteVariable = register_cvar("dmc_votevariable", "3");
	Cvar_VotePercentMin = register_cvar("dmc_votepercent", "50");
	Cvar_MaxMaps = register_cvar("dmc_maxmaps", "6");
	Cvar_Nomination = register_cvar("dmc_nomination", "1");
	Cvar_PlayedMaps = register_cvar("dmc_playedmaps", "1");
	Cvar_LastMaps = register_cvar("dmc_lastmaps", "5");
	Cvar_RTV = register_cvar("dmc_rtv", "1");
	Cvar_VoteSound = register_cvar("dmc_votesound", "1");
	Cvar_RTVMin = register_cvar("dmc_rtvmin", "2");
	Cvar_NomChance = register_cvar("dmc_nomchance", "50");
	Cvar_Extend = register_cvar("dmc_extend", "15");
	Cvar_StartRevoteTime = register_cvar("dmc_startrevotetime", "5.0");
	Cvar_OnlyNextRound = register_cvar("dmc_onlynextround", "1");
	Cvar_CountSound = register_cvar("dmc_countsound", "1");
	Cvar_ChooseSound = register_cvar("dmc_choosesound", "1");
	Cvar_LangMode = register_cvar("dmc_langmode", "0");
	Cvar_StartButton = register_cvar("dmc_startbutton", "1");
	
	server_cmd("exec %s/dmc.cfg", ConfigsDir);
	server_exec();
	set_cvar_float("mp_chattime", 120.0);
	
	register_concmd("amx_dmc", "ShowInfo");
	
	VoteMenu = register_menuid("VoteMenu");
	RevoteMenu = register_menuid("RevoteMenu");
	register_menucmd(VoteMenu, 1023, "VoteMenuKeys");
	register_menucmd(RevoteMenu, 1023, "RevoteMenuKeys");
	SayText = get_user_msgid("SayText");
	
	TimeLimit = get_cvar_num("mp_timelimit");
	MaxRounds = get_cvar_num("mp_maxrounds");
	oRounds = MaxRounds;
	
	if(get_pcvar_num(Cvar_LangMode) == 0)
	{
		Lang = 0;
	}
	else
	{
		Lang = -1;
	}
	
	StartButton = get_pcvar_num(Cvar_StartButton);
	
	if(StartButton < 1)
	{
		set_pcvar_num(Cvar_StartButton, 1);
	}
	
	if(StartButton > 1 && StartButton <= MaxSB)
	{
		new Check;
		Check = get_pcvar_num(Cvar_MaxMaps) + get_pcvar_num(Cvar_StartButton);
		
		if(Check > 9)
		{
			Check = MaxChoice - get_pcvar_num(Cvar_MaxMaps);
			if(0 != Check - StartButton)
			{
				Check -= StartButton;
				Check = -Check;
				set_pcvar_num(Cvar_MaxMaps, get_pcvar_num(Cvar_MaxMaps)-Check+1);
			}
		}
	}
	else if(StartButton > MaxSB)
	{
		StartButton = MaxSB;
		set_pcvar_num(Cvar_MaxMaps, 2);
	}
	else
	{
		StartButton = 1;
	}
	
	if(get_pcvar_num(Cvar_MaxMaps) > MaxChoice)
	{
		set_pcvar_num(Cvar_MaxMaps, MaxChoice);
	}
	
	if(get_pcvar_num(Cvar_MaxMaps) <= 1)
	{
		set_pcvar_num(Cvar_MaxMaps, 2);
	}
	
	if(get_pcvar_float(Cvar_ChangeSpeed) > MaxCSpeed)
	{
		set_pcvar_float(Cvar_ChangeSpeed, MaxCSpeed);
	}
	
	if(get_pcvar_float(Cvar_ChangeSpeed) < 1.0)
	{
		set_pcvar_float(Cvar_ChangeSpeed, 1.0);
	}
	
	if(MapCycle_Lines-get_pcvar_num(Cvar_MaxMaps) < 0)
	{
		new Error[64];
		formatex(Error, charsmax(Error), "Only %d maps in %s file! (Min: %d)", MapCycle_Lines, MapCycle, get_pcvar_num(Cvar_MaxMaps));
		log_amx(Error);
		
		if(MapCycle_Lines > 1)
		{
			set_pcvar_num(Cvar_MaxMaps, MapCycle_Lines);
			formatex(Error, charsmax(Error), "MaxMaps set %d", MapCycle_Lines);
			log_amx(Error);
		}
		else
		{
			Off = 1;
		}
	}
	
	if(TimeLimit == 0 && get_pcvar_num(Cvar_Mod) == 1)
	{
		Off = 1;
	}
	
	if(Off == 0)
	{
		register_event("HLTV", "NewRound", "a", "1=0", "2=0");
		register_logevent("SavePresentTime", 2, "0=World triggered", "1=Game_Commencing");
		register_logevent("RestartRound", 2, "0=World triggered", "1&Restart_Round_");
		register_logevent("RestartRound", 2, "0=World triggered", "1=Game_Commencing");
		
		if(get_pcvar_num(Cvar_Mod) == 0)
		{
			register_logevent("RoundEnd", 2, "0=World triggered", "1=Round_End");
		}
		
		set_task(0.5, "CheckTime", MapID-1, _, _, "b");
		
		if(get_pcvar_num(Cvar_Mod) == 0)
		{	
			register_concmd("amx_dmc_maxrounds", "AddRound");
			
			if(MaxRounds < MinRounds)
			{
				server_cmd("mp_maxrounds ^"%d^"", MinRounds);
			}
			
			server_cmd("mp_timelimit 0");
			
			MaxRounds = get_cvar_num("mp_maxrounds");
			oRounds = MaxRounds;
		}
		
		if(get_pcvar_num(Cvar_Mod) == 1)
		{
			server_cmd("mp_maxrounds 0");
		}
	}
	
	get_mapname(MapName, charsmax(MapName));
	
	set_task(0.1, "LoadLastMaps");
	set_task(0.2, "LoadMaps");
	set_task(0.3, "LoadVoteMaps");
	set_task(0.4, "SavePresentTime");
	
	toRTV = false;

	new Cmd[32];
	
	if(get_pcvar_num(Cvar_PlayedMaps) == 1)
	{
		for(new Num = 0; Num < sizeof MapMenuCommands; Num++)
		{
			format(Cmd, charsmax(Cmd), "say %s", MapMenuCommands[Num]);
			register_clcmd(Cmd, "ShowMapMenu");
		}
	}
	
	for(new Num = 0; Num < sizeof NextMapCommands; Num++)
	{
		format(Cmd, charsmax(Cmd), "say %s", NextMapCommands[Num]);
		register_clcmd(Cmd, "ShowNextMap");
	}
	
	for(new Num = 0; Num < sizeof CurrentMapCommands; Num++)
	{
		format(Cmd, charsmax(Cmd), "say %s", CurrentMapCommands[Num]);
		register_clcmd(Cmd, "ShowCurrentMap");
	}
	
	for(new Num = 0; Num < sizeof TimeLeftCommands; Num++)
	{
		format(Cmd, charsmax(Cmd), "say %s", TimeLeftCommands[Num]);
		register_clcmd(Cmd, "ShowTimeLeft");
	}
	
	for(new Num = 0; Num < sizeof AdminCommands; Num++)
	{
		format(Cmd, charsmax(Cmd), "say %s", AdminCommands[Num]);
		register_clcmd(Cmd, "StartVote");
	}
	
	if(get_pcvar_num(Cvar_RTV) == 1)
	{
		for(new Num = 0; Num < sizeof RTVCommands; Num++)
		{
			format(Cmd, charsmax(Cmd), "say %s", RTVCommands[Num]);
			register_clcmd(Cmd, "RockTheVote");
		}
	}
	
	if(get_pcvar_num(Cvar_Nomination) == 1)
	{
		for(new Num = 0; Num < sizeof NomCommands; Num++)
		{
			format(Cmd, charsmax(Cmd), "say %s", NomCommands[Num]);
			register_clcmd(Cmd, "ShowNomMenu");
		}
	}
}
public AddRound(id) {
	if(get_user_flags(id) & RoundFlag)
	{
		new sRound[32], RoundNum;
		read_args(sRound, charsmax(sRound));
		remove_quotes(sRound);
		
		RoundNum = str_to_num(sRound);
		
		MaxRounds = RoundNum+Rounds;
		set_cvar_num("mp_maxrounds", get_cvar_num("mp_maxrounds")+RoundNum);
	}
}
public SavePresentTime()
{	
	new Hour[32], Minute[32], Second[32];
	format_time(Hour, sizeof Hour - 1, "%H");
	format_time(Minute, sizeof Minute - 1, "%M");
	format_time(Second, sizeof Second  - 1, "%S");
	ElapsedTime[0] = str_to_num(Second);
	ElapsedTime[1] = str_to_num(Minute);
	ElapsedTime[2] = str_to_num(Hour);
	RTVTime[2] = str_to_num(Hour);
	RTVTime[1] = str_to_num(Minute)+get_pcvar_num(Cvar_RTVMinute);
	RTVTime[0] = str_to_num(Second);
	
	if(RTVTime[1] >= 60)
	{
		RTVTime[1] -= 60;
		RTVTime[2]++;
	}
}
public RestartRound() {
	if(get_pcvar_num(Cvar_Mod) == 1)
		server_cmd("mp_timelimit %d", TimeLimit);
	else
	{
		server_cmd("mp_maxrounds %d", get_cvar_num("mp_maxrounds")+oRounds+Rounds);
		MaxRounds = oRounds+Rounds;
	}
	
	remove_task(MapID+8123);
	remove_task(MapID+1);
	remove_task(MapID+211);
	remove_task(MapID+2);
	remove_task(MapID+3);
	remove_task(MapID+33);
	NeedRV = false;
	ChangeMap = false;
	Begined = false;
	BeginCounter = 0;
	MapCounter = 0;
	Voted = false;
	Revoted = false;
	inProcess = false;
	AllVotes = 0;
	AllRevotes = 0;
	Started = 0;
	
	new Num;
	
	for(Num = 0; Num < 32; Num++)
	{
		if(!is_user_connected(Num))
		{
			continue;
		}
		
		AlreadyNom[Num] = false;
		PlayerMap[Num] = 0;
		PlayerVoted[Num] = false;
		PlayerRevoted[Num] = false;
	}
	
	for(Num = 0; Num < Nom; Num++)
	{
		NomMaps[Num] = "";
	}
	
	for(Num = 0; Num < Max; Num++)
	{
		Nomed[Num] = 0;
	}
	
	for(Num = 0; Num < get_pcvar_num(Cvar_MaxMaps); Num++)
	{
		MapNames[Num] = "";
		MapVote[Num] = 0;
	}
	
	RTV = 0;
	Nom = 0;
	LoadVoteMaps();
	LoadNomMaps();
	Next = "";
	set_task(get_pcvar_float(Cvar_MenuDestroyTime)+1.0, "VotedMapN", MapID+777);
	SavePresentTime();
}
public NewRound() {
	if(get_pcvar_num(Cvar_Mod) == 1)
	{
		if(ChangeMap)
		{
			if(isValidMap(Next))
			{
				ChangeLevel();
			}
		}
	}
	else if(get_pcvar_num(Cvar_Mod) == 0)
	{
		if(0 >= MaxRounds-Rounds)
		{
			if(ChangeMap)
			{
				if(isValidMap(Next))
				{
					ChangeLevel();
				}
			}
		}
	}
}
public RoundEnd()
{
	if(MaxRounds-Rounds > 0 && Started == 1)
	{
		Rounds++;
	}
	if(Started == 0)
	{
		Started = 1;
	}
}
public StartVote(id)
{
	if(get_user_flags(id) & StartVoteFlag)
	{
		if(!inProcess || !Voted || !Revoted || !ChangeMap || Off == 0 || !Begined)
		{
			NeedRV = false;
			new String[32];
			float_to_str(get_pcvar_float(Cvar_WaitVoteMenuTime), String, 2);
			replace_all(String, 2, ".", "");
			Begined = true;
			inProcess = true;
			
			if(get_pcvar_num(Cvar_Mod) == 1)
			{
				server_cmd("mp_timelimit 0");
			}
			else if(get_pcvar_num(Cvar_Mod) == 0)
			{
				Rounds = MaxRounds;
			}
			
			VoteMod = 2;
			
			if(get_pcvar_num(Cvar_HudMod) == 1)
			{
				remove_task(MapID+8123);
				BeginCounter = str_to_num(String);
				VoteCounter();
			}
			else if(get_pcvar_num(Cvar_HudMod) == 0)
			{
				set_task(get_pcvar_float(Cvar_WaitVoteMenuTime), "StartMapChooser", MapID+3);
				set_hudmessage(R, G, B, -1.0, 0.20, 0, 6.0, get_pcvar_float(Cvar_WaitVoteMenuTime));
				ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE2", String);
			}
		}
	}
}
public VoteCounter()
{
	if(BeginCounter > 0)
	{
		new String[32];
		num_to_str(BeginCounter, String, 2);
		
		if(get_pcvar_num(Cvar_CountSound) == 1)
		{
			new CountSound[32];
			num_to_word(BeginCounter, CountSound, 31);
			
			if(get_pcvar_num(Cvar_VoteSound) == 1)
				client_cmd(0, "spk ^"fvox/%s^"", CountSound);
		}
		
		set_hudmessage(R, G, B, -1.0, 0.20, 0, 0.1, CHUD);
		
		if(VoteMod == 4)
		{
			ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE4", String);
		}
		else if(VoteMod == 3)
		{
			ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE3", String);
		}
		else if(VoteMod == 2)
		{
			ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE2", String);
		}
		else if(VoteMod == 1)
		{
			ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE1", String);
		}
		
		BeginCounter--;
		set_task(1.0, "VoteCounter", MapID+8123);
	}
	else
	{
		if(NeedRV)
		{
			StartRevote();
		}
		else
		{
			StartMapChooser();
		}
	}
}
public RockTheVote(id)
{
	new Hour[32], Minute[32], Time[2];
	format_time(Hour, sizeof Hour - 1, "%H");
	format_time(Minute, sizeof Minute - 1, "%M");
	Time[0] = str_to_num(Hour);
	Time[1] = str_to_num(Minute);
	
	if(Time[0] > RTVTime[2]
	|| Time[0] == RTVTime[2] && Time[1] >= RTVTime[1])
	toRTV = true;
	
	if(PlayerRTV[id] || Voted || inProcess || !toRTV || Off == 1)
	{
		if(!toRTV)
		{
			if(RTVTime[2] > Time[0])
			{
				print_color(id, "%s %L", Prefix, Lang, "RTV2", (RTVTime[1]+60)-Time[1]);
			}
			else
			{
				print_color(id, "%s %L", Prefix, Lang, "RTV2", RTVTime[1]-Time[1]);
			}
		}
		
		if(PlayerRTV[id])
		{
			print_color(id, "%s %L", Prefix, Lang, "RTV1");
		}
		
		return PLUGIN_HANDLED;
	}
	
	PlayerRTV[id] = true;
	RTV++;
	
	new Players[32], Num;
	get_players(Players, Num, "c");
	
	if(RTV >= Num/get_pcvar_num(Cvar_RTVMin))
	{
		new String[32];
		float_to_str(get_pcvar_float(Cvar_WaitVoteMenuTime), String, 2);
		replace_all(String, 2, ".", "");
		Begined = true;
		inProcess = true;
		
		if(get_pcvar_num(Cvar_Mod) == 1)
		{
			server_cmd("mp_timelimit 0");
		}
		else if(get_pcvar_num(Cvar_Mod) == 0)
		{
			Rounds = MaxRounds;
		}
		
		VoteMod = 1;
		
		if(get_pcvar_num(Cvar_HudMod) == 1)
		{
			remove_task(MapID+8123);
			BeginCounter = str_to_num(String);
			VoteCounter();
		}
		else if(get_pcvar_num(Cvar_HudMod) == 0)
		{
			set_task(get_pcvar_float(Cvar_WaitVoteMenuTime), "StartMapChooser", MapID+3);
			set_hudmessage(R, G, B, -1.0, 0.20, 0, 6.0, get_pcvar_float(Cvar_WaitVoteMenuTime));
			ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE1", String);
		}
	}
	else
	{
		print_color(0, "%s %L", Prefix, Lang, "RTV3", (Num/get_pcvar_num(Cvar_RTVMin))-RTV);
	}
	
	return PLUGIN_HANDLED;
}
public Extend()
{
	NeedRV = false;
	ChangeMap = false;
	Begined = false;
	Voted = false;
	Revoted = false;
	inProcess = false;
	AllVotes = 0;
	AllRevotes = 0;
	
	new Num;
	
	for(Num = 0; Num < 32; Num++)
	{
		if(!is_user_connected(Num))
		{
			continue;
		}
		
		AlreadyNom[Num] = false;
		PlayerMap[Num] = 0;
		PlayerVoted[Num] = false;
		PlayerRevoted[Num] = false;
	}
	
	for(Num = 0; Num < Nom; Num++)
	{
		NomMaps[Num] = "";
	}
	
	for(Num = 0; Num < Max; Num++)
	{
		Nomed[Num] = 0;
	}
	
	for(Num = 0; Num < get_pcvar_num(Cvar_MaxMaps); Num++)
	{
		MapNames[Num] = "";
		MapVote[Num] = 0;
	}
	
	RTV = 0;
	Nom = 0;
	LoadVoteMaps();
	LoadNomMaps();
	Next = "";
	set_task(get_pcvar_float(Cvar_MenuDestroyTime)+1.0, "VotedMapN", MapID+777);
}
public VotedMapN()
{
	VotedMap = "";
}
public CheckTime()
{
	static Time[3];
	Time[0] = get_timeleft();
	Time[1] = Time[0] / 60;
	Time[2] = Time[1] / 60;
	Time[0] = Time[0] - Time[1] * 60;
	Time[1] = Time[1] - Time[2] * 60;
	
	if(get_pcvar_num(Cvar_Mod) == 1)
	{
		if(Time[1] <= get_pcvar_num(Cvar_VoteVariable) && !Begined && !inProcess)
		{
			new String[32];
			float_to_str(get_pcvar_float(Cvar_WaitVoteMenuTime), String, 2);
			replace_all(String, 2, ".", "");
			
			VoteMod = 3;
			
			if(get_pcvar_num(Cvar_HudMod) == 1)
			{
				remove_task(MapID+8123);
				BeginCounter = str_to_num(String);
				VoteCounter();
			}
			else if(get_pcvar_num(Cvar_HudMod) == 0)
			{
				set_task(get_pcvar_float(Cvar_WaitVoteMenuTime), "StartMapChooser", MapID+3);
				set_hudmessage(R, G, B, -1.0, 0.20, 0, 6.0, get_pcvar_float(Cvar_WaitVoteMenuTime));
				ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE3", String);
			}
		
			Begined = true;
			inProcess = true;
		}
	
		if(Time[0] <= 3 && Time[1] == 0 && Time[2] == 0)
		{
			server_cmd("mp_timelimit 0");
			if(!ChangeMap && Voted && !inProcess && !Revoted
			|| !ChangeMap && Revoted && !inProcess && !Voted)
			{
				if(get_pcvar_num(Cvar_OnlyNextRound) == 1)
				{
					print_color(0, "%s %L", Prefix, Lang, "MCAR");
					set_cvar_string("amx_nextmap", Next);
					ChangeMap = true;
				}
				else if(get_pcvar_num(Cvar_OnlyNextRound) == 0)
				{
					ChangeMap = true;
					set_cvar_string("amx_nextmap", Next);
					ChangeLevel();
				}
			}
		}
	}
	else if(get_pcvar_num(Cvar_Mod) == 0)
	{
		if(Rounds == MaxRounds-get_pcvar_num(Cvar_VoteVariable) && !Begined && !inProcess)
		{
			new String[32];
			float_to_str(get_pcvar_float(Cvar_WaitVoteMenuTime), String, 2);
			replace_all(String, 2, ".", "");
			
			VoteMod = 3;
			
			if(get_pcvar_num(Cvar_HudMod) == 1)
			{
				remove_task(MapID+8123);
				BeginCounter = str_to_num(String);
				VoteCounter();
			}
			else if(get_pcvar_num(Cvar_HudMod) == 0)
			{
				set_task(get_pcvar_float(Cvar_WaitVoteMenuTime), "StartMapChooser", MapID+3);
				set_hudmessage(R, G, B, -1.0, 0.20, 0, 6.0, get_pcvar_float(Cvar_WaitVoteMenuTime));
				ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE3", String);
			}
			
			Begined = true;
			inProcess = true;
		}
		
		if(Rounds >= MaxRounds && !ChangeMap && Voted
		|| Rounds >= MaxRounds && !ChangeMap && Revoted)
		{
			print_color(0, "%s %L", Prefix, Lang, "MCAR");
			set_cvar_string("amx_nextmap", Next);
			ChangeMap = true;
		}
	}
	
	if(!toRTV)
	{
		new Hour[32], Minute[32];
		format_time(Hour, sizeof Hour - 1, "%H");
		format_time(Minute, sizeof Minute - 1, "%M");
		Time[2] = str_to_num(Hour);
		Time[1] = str_to_num(Minute);
		
		if(RTVTime[2] == Time[2] && RTVTime[1]+get_pcvar_num(Cvar_RTVMinute) <= Time[1])
		{
			toRTV = true;
		}
	}
}
public StartMapChooser()
{
	remove_task(MapID+3);
	ChangeMap = false;
	Voted = false;
	Revoted = false;
	MapCounter = get_pcvar_num(Cvar_VoteCounter);
	Counter();
	VoteMod = 0;
	if(get_pcvar_num(Cvar_VoteSound) == 1)
	{
		client_cmd(0, "spk Gman/Gman_Choose%i", random_num(1, 2));
	}
}
public Change()
{
	if(ChangeMap)
	{
		server_cmd("changelevel ^"%s^"", Next);
	}
}
public ShowInfo(id)
{
	if(get_user_flags(id) & InfoFlag)
	{
		client_print(id, print_console, "* ------------");
		client_print(id, print_console, "* %s - v%s by %s *", PLUGIN, VERSION, AUTHOR);
		client_print(id, print_console, "* ------------");
		client_print(id, print_console, "* Ostatnia mapa: %s", LastMaps[0]);
		client_print(id, print_console, "* Nastepna mapa: %s", Next);
		client_print(id, print_console, "* Mapy: %d", NomNum);
		client_print(id, print_console, "* ------------");
		client_print(id, print_console, "* Czas Mapy: %d", TimeLimit);
		client_print(id, print_console, "* Limit Rund: %d", oRounds);
		client_print(id, print_console, "* ------------");
		client_print(id, print_console, "* Rozegrane mapy: %d", PlayedCount);
		client_print(id, print_console, "* ------------");
	}
}
public ShowTimeLeft()
{
	if(get_pcvar_num(Cvar_Mod) == 1)
	{
		static Time[3];
		Time[0] = get_timeleft();
		Time[1] = Time[0] / 60;
		Time[2] = Time[1] / 60;
		Time[0] = Time[0] - Time[1] * 60;
		Time[1] = Time[1] - Time[2] * 60;
		if(ChangeMap && Voted && Begined && !Revoted || ChangeMap && Revoted && Begined && !Voted)
		{
			print_color(0, "%s!y %L!t !t-!y:!t-", Prefix, Lang, "TL");
		}
		else
		{
			if(Time[2] > 0 && Time[1] > 0 && Time[0] > 0)
				print_color(0, "%s!y %L!t %d%!y:!t%02d!y:!t%02d", Prefix, Lang, "TL", Time[2], Time[1], Time[0]);
			else if(Time[1] > 0 && Time[0] > 0)
				print_color(0, "%s!y %L!t %02d!y:!t%02d", Prefix, Lang, "TL", Time[1], Time[0]);
			else
				print_color(0, "%s!y %L!t !t-!y:!t-", Prefix, Lang, "TL");
		}
	}
	else if(get_pcvar_num(Cvar_Mod) == 0)
	{
		print_color(0, "%s!t %L", Prefix, Lang, "RM", MaxRounds-Rounds);
	}
}
public ShowNextMap()
{
	new Status[2][32];
	formatex(Status[0], 31, "%L", Lang, "NYT");
	formatex(Status[1], 31, "%L", Lang, "VIP");
	if(isValidMap(Next))
	print_color(0, "%s!y %L!t %s", Prefix, Lang, "NM", Next);
	else
	{
		if(inProcess)
		{
			print_color(0, "%s!y %L!t %s", Prefix, Lang, "NM", Status[1]);
		}
		else
		{
			print_color(0, "%s!y %L!t %s", Prefix, Lang, "NM", Status[0]);
		}
	}
}
public ShowCurrentMap()
{
	print_color(0, "%s!y %L", Prefix, Lang, "CM", MapName);
}
public Counter()
{
	if(MapCounter < 1)
	{
		Voted = true;
		
		inProcess = false;
		
		CheckVotes();
		
		for(new Num; Num < 32; Num++)
		{
			if(!is_user_connected(Num))
				continue;
				
			ShowVoteMenu(Num);
		}
	}
	else
	{
		MapCounter--;
		
		set_task(1.0, "Counter", MapID+1);
		
		for(new Num; Num < 32; Num++)
		{
			if(!is_user_connected(Num))
				continue;
				
			ShowVoteMenu(Num);
		}
	}
}
public NextMap()
{
	remove_task(MapID-4);
	
	if(!NeedRV)
	{
		ShowNextMap();
	}
	
	set_task(get_pcvar_float(Cvar_MenuDestroyTime), "DestroyVoteMenu", MapID-4);
}
public DestroyVoteMenu()
{
	for(new Num; Num < 32; Num++)
	{
		if(!is_user_connected(Num))
			continue;
			
		show_menu(Num, 0, "^n", 1);
	}
}
public ShowVoteMenu(id)
{	
	if(equal(VotedMap, MapName))
	{
		DestroyVoteMenu();
		return;
	}
	
	new Menu[512], String[128], Key, MapPercent[MaxChoice];
	
	AllVotes = 0;
	
	for(new All; All < get_pcvar_num(Cvar_MaxMaps); All++)
	{
		AllVotes += MapVote[All];
	}
	
	formatex(String, 127, "%L", Lang, "CHONM", AllVotes);
	add(Menu, 511, String);
	
	for(new Num; Num < get_pcvar_num(Cvar_MaxMaps); Num++)
	{
		if(MapVote[Num] > 0)
		MapPercent[Num] = ((MapVote[Num]*100)/(AllVotes));
		if(equal(MapName, MapNames[Num]))
		formatex(String, 127, "%L", Lang, "MOP5", Num+StartButton, MapNames[Num], MapVote[Num], MapPercent[Num]);
		else
		formatex(String, 127, "%L", Lang, "MOPD", Num+StartButton, MapNames[Num], MapVote[Num], MapPercent[Num]);
		add(Menu, 511, String);
	}
	
	if(Voted)
	formatex(String, 127, "%L", Lang, "MNM", Next);
	else if(!Revoted && !Voted && MapCounter <= 0 && NeedRV)
	formatex(String, 127, "%L", Lang, "MNRE");
	else
	formatex(String, 127, "%L", Lang, "MCSL", MapCounter);
	
	add(Menu, 511, String);
	
	Key = (-1^(-1<<(get_pcvar_num(Cvar_MaxMaps)+StartButton)));
	
	show_menu(id, Key, Menu, -1, "VoteMenu");
}
public VoteMenuKeys(id, Key)
{
	if(PlayerVoted[id] || Voted)
	{
		if(PlayerVoted[id])
		{
			print_color(id, "%s %L", Prefix, Lang, "AVO");
		}
		return;
	}
	
	if(!Begined || NeedRV)
	{
		show_menu(id, 0, "^n", 1);
		return;
	}
	
	new PlayerName[32];
	get_user_name(id, PlayerName, 31);
	
	Key -= StartButton-1;
	if(Key < get_pcvar_num(Cvar_MaxMaps) && Key > -1)
	{
		PlayerMap[id] = Key;
		PlayerVoted[id] = true;
		print_color(0, "%s %L", Prefix, Lang, "PCHO", PlayerName, MapNames[Key]);
		MapVote[Key]++;
		if(get_pcvar_num(Cvar_ChooseSound) == 1)
		{
			client_cmd(0, "spk buttons/lightswitch2");
		}
	}
	
	ShowVoteMenu(id);
}
public LoadVoteMaps()
{
	new Line[128], Map[32], Len, Used[Max], Loaded, File, Found;
	
	File = fopen(MapCycle, "rt");
	
	if(File)
	{
		
		for(new lNum; lNum < Max; lNum++)
		{
			Found = 0;
			
			new RandomMap = random(MapCycle_Lines);
			read_file(MapCycle, RandomMap, Line, 127, Len);
			
			parse(Line, Map, 31);
			
			for(new mc; mc < MaxChoice; mc++)
			{
				if(equali(Map, MapNames[mc]))
				{
					Found = 1;
				}
			}
			
			if(Found == 1 || equali(Map, MapName))
			{
				continue;
			}
			
			if(Used[RandomMap] == 0 && Loaded < get_pcvar_num(Cvar_MaxMaps)-1 && isValidMap(Map))
			{
				Used[RandomMap] = 1;
				copy(MapNames[Loaded], sizeof Map - 1, Map);
				Loaded++;
			}
		}
		
	}
	
	fclose(File);
	
	MapNames[get_pcvar_num(Cvar_MaxMaps)-1] = MapName;
	set_task(0.1, "LoadNomMaps", MapID+69);
}
public LoadNomMaps()
{
	new Line[128], Map[32], File, Found;
	
	File = fopen(MapCycle, "rt");
	
	while(!feof(File))
	{
		fgets(File, Line, charsmax(Line));
			
		parse(Line, Map, 31);
		
		for(new nn; nn < NomNum; nn++)
		{
			if(equali(Map, NomMaps[nn]))
			{
				Found = 1;
			}
		}
		
		if(Found == 1)
		{
			continue;
		}
		
		if(NomNum < MapCycle_Lines && isValidMap(Map))
		{
			copy(NomMaps[NomNum], sizeof Map - 1, Map);
			NomNum++;
		}
	}
	
	fclose(File);
}
public ShowMapMenu(id)
{
	new Menu, MenuLine[128], MapDatas[2][32], String[32];
	formatex(MenuLine, 127, "%L", Lang, "MPNM");
	Menu = menu_create(MenuLine, "MapKey");
	
	for(new MapNum; MapNum < MapFile_Lines-1; MapNum++)
	{
		parse(Maps[MapNum], MapDatas[0], 31, MapDatas[1], 31);
		formatex(MenuLine, 127, "%L", Lang, "PMPM", MapDatas[0], MapDatas[1]);
		num_to_str(MapNum, String, 2);
		menu_additem(Menu, MenuLine, String);
	}
	
	formatex(MenuLine, 127, "%L", Lang, "MNEXT");
	menu_setprop(Menu, MPROP_NEXTNAME, MenuLine);
	formatex(MenuLine, 127, "%L", Lang, "MEXIT");
	menu_setprop(Menu, MPROP_EXITNAME, MenuLine);
	formatex(MenuLine, 127, "%L", Lang, "MBACK");
	menu_setprop(Menu, MPROP_BACKNAME, MenuLine);
	menu_setprop(Menu, MPROP_PERPAGE, PMPage);
	menu_display(id, Menu);
}
public MapKey(id, Menu, Item)
{
	new MenuNum[2], Data[2][32], Key;
	menu_item_getinfo(Menu, Item, MenuNum[0], Data[0], charsmax(Data), Data[1], charsmax(Data), MenuNum[1]);
	
	Key = str_to_num(Data[0]);
	
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new MapDatas[2][32];
	parse(Maps[Key], MapDatas[0], 31, MapDatas[1], 31);
	
	print_color(id, "%s %L", Prefix, Lang, "MNP", MapDatas[0], MapDatas[1]);
}
public ShowNomMenu(id)
{	
	if(Nom >= get_pcvar_num(Cvar_MaxMaps)-1)
	{
		print_color(id, "%s %L", Prefix, Lang, "NOMT");
		return;
	}
	if(AlreadyNom[id])
	{
		print_color(id, "%s %L", Prefix, Lang, "NOMN");
		return;
	}
	if(inProcess || Voted || Revoted)
	{
		return;
	}
	
	new Menu, MenuLine[128], Already;
	formatex(MenuLine, 127, "%L", Lang, "NOMM");
	Menu = menu_create(MenuLine, "NomKey");
	
	for(new MapNum; MapNum < MapCycle_Lines; MapNum++)
	{
		if(Nomed[MapNum] == 1)
			continue;
			
		Already = 0;
		
		for(new mc; mc < MaxChoice; mc++)
		{
			if(equali(NomMaps[MapNum], MapNames[mc]))
			{
				Already = 1;
			}
		}
		
		if(Already == 1)
			continue;
			
		if(equali(NomMaps[MapNum], MapName))
			continue;
			
		if(!isValidMap(NomMaps[MapNum]))
			continue;
		
		formatex(MenuLine, 127, "%L", Lang, "NOM1", NomMaps[MapNum]);
		menu_additem(Menu, MenuLine, NomMaps[MapNum]);
	}
	
	formatex(MenuLine, 127, "%L", Lang, "MNEXT");
	menu_setprop(Menu, MPROP_NEXTNAME, MenuLine);
	formatex(MenuLine, 127, "%L", Lang, "MEXIT");
	menu_setprop(Menu, MPROP_EXITNAME, MenuLine);
	formatex(MenuLine, 127, "%L", Lang, "MBACK");
	menu_setprop(Menu, MPROP_BACKNAME, MenuLine);
	menu_display(id, Menu);
}
public NomKey(id, Menu, Item)
{
	if(Nom > get_pcvar_num(Cvar_MaxMaps)-1)
	{
		print_color(id, "%s %L", Prefix, Lang, "NOMT");
		return PLUGIN_HANDLED;
	}
	if(AlreadyNom[id])
	{
		print_color(id, "%s %L", Prefix, Lang, "NOMN");
		return PLUGIN_HANDLED;
	}
	if(inProcess || Voted)
	{
		return PLUGIN_HANDLED;
	}
	
	new MenuNum[2], Data_1[32], Data_2[32], PlayerName[32];
	menu_item_getinfo(Menu, Item, MenuNum[0], Data_1, charsmax(Data_1), Data_2, charsmax(Data_2), MenuNum[1]);
	
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
			
	new Already = 0;

	for(new mc; mc < MaxChoice; mc++)
	{
		if(equali(Data_1, MapNames[mc]))
		{
			Already = 1;
		}
	}
	
	if(Already == 1 || !isValidMap(Data_1) || Nomed[Nom] == 1)
	return PLUGIN_HANDLED;
	
	get_user_name(id, PlayerName, charsmax(PlayerName));
	
	print_color(0, "%s %L", Prefix, Lang, "NOMC", PlayerName, Data_1);
	
	if(get_pcvar_num(Cvar_NomChance) >= (random_num(1,100)))
	{
		MapNames[Nom] = Data_1;
	}
	
	MapNames[Nom] = Data_1;
	Nomed[Nom] = 1;
	Nom++;
	AlreadyNom[id] = true;
	
	return PLUGIN_HANDLED;
}
public LoadMapMenu()
{
	new Line[64], File, Len;
	
	File = fopen(MapFile, "rt");
	
	if(File)
	{
		for(new MapNum; MapNum < MapFile_Lines; MapNum++)
		{
			read_file(MapFile, MapNum, Line, 63, Len);
			
			if(Line[0] == ';' || strlen(Line) < 2)
				continue;
				
			remove_quotes(Line);
			
			copy(Maps[MapNum], sizeof Line - 1, Line);
		}
	}
	
	fclose(File);
}
public LoadLastMaps()
{
	copy(LastMaps[LastMapsNum++], charsmax(LastMaps), MapName);
	
	new Line[64], File, Len;
	
	File = fopen(LastMapsFile, "rt");
	
	if(File)
	{
		for(new MapNum; MapNum < LastMapsFile_Lines; MapNum++)
		{
			read_file(MapFile, MapNum, Line, 63, Len);
			
			if(Line[0] == ';' || strlen(Line) < 2)
				continue;
				
			remove_quotes(Line);
			
			copy(LastMaps[LastMapsNum++], sizeof Line - 1, Line);
		}
	}
	
	fclose(File);
	
	WriteLastMaps();
}
public WriteLastMaps()
{
	if(file_exists(LastMapsFile)) 
		delete_file(LastMapsFile);

	new szText[256];
	for(new MapNum; MapNum < LastMapsNum; MapNum++) 
	{
		formatex(szText, charsmax(szText), "%s", LastMaps[MapNum]);
		write_file(LastMapsFile, szText);
	}
}
public LoadMaps()
{
	remove_task(MapID);
	
	new Line[64], File, MapDatas[2][32], LineNum, MapNum, bool:Found;
	File = fopen(MapFile, "rt");
	
	while(!feof(File))
	{
		fgets(File, Line, charsmax(Line));
		
		if(Line[0] == ';' || strlen(Line) < 2)
			continue;
			
		parse(Line, MapDatas[0], 31, MapDatas[1], 31);
		
		PlayedCount += str_to_num(MapDatas[1]);
		
		if(equal(MapDatas[0], MapName))
		{
			MapNum = str_to_num(MapDatas[1])+1;
			format(Line, sizeof Line - 1, "^"%s^" ^"%d^"", MapName, MapNum);
			write_file(MapFile, Line, LineNum);
			Found = true;
		}
		
		LineNum++;
	}
	
	fclose(File);
	
	if(!Found)
	{
		NewMap();
	}
	
	set_task(0.5, "LoadMapMenu", MapID);
}
public NewMap()
{
	new Line[32], File;
	File = fopen(MapFile, "at+");
	formatex(Line, sizeof Line - 1, "^"%s^" ^"%d^"^n", MapName, 1);
	fprintf(File, Line);
	fclose(File);
}
public StartRevoteTime() 
{
	new String[32];
	float_to_str(get_pcvar_float(Cvar_WaitRevoteMenuTime), String, 2);
	replace_all(String, 2, ".", "");
	VoteMod = 4;
	if(get_pcvar_num(Cvar_HudMod) == 1)
	{
		remove_task(MapID+8123);
		BeginCounter = str_to_num(String);
		VoteCounter();
	}
	else if(get_pcvar_num(Cvar_HudMod) == 0)
	{
		set_task(get_pcvar_float(Cvar_StartRevoteTime), "StartRevote", MapID+33);
		set_hudmessage(R, G, B, -1.0, 0.20, 0, 6.0, get_pcvar_float(Cvar_WaitVoteMenuTime));
		ShowSyncHudMsg(0, sHudObj, "%L", Lang, "VOTE4", String);
	}
	
	inProcess = true;
}
public StartRevote() 
{
	Voted = false;
	Begined = true;
	MapCounter = get_pcvar_num(Cvar_VoteCounter);
	ReCounter();
	if(get_pcvar_num(Cvar_VoteSound) == 1)
		client_cmd(0, "spk Gman/Gman_Choose%i", random_num(1, 2));
}
public ShowRevoteMenu(id)
{
	if(equal(VotedMap, MapName))
	{
		DestroyVoteMenu();
		return;
	}
	
	new Menu[512], String[128], Key, MapPercent[MaxChoice];
	
	AllRevotes = 0;
	
	for(new All; All < 2; All++)
	{
		AllRevotes += RevoteCounts[All];
	}
	
	formatex(String, 127, "%L", Lang, "CHONM", AllRevotes);
	add(Menu, 511, String);
	
	for(new Num; Num < 2; Num++)
	{
		if(RevoteCounts[Num] > 0)
		MapPercent[Num] = ((RevoteCounts[Num]*100)/(AllRevotes));
		formatex(String, 127, "%L", Lang, "MOPD", Num+StartButton, MapRevote[Num], RevoteCounts[Num], MapPercent[Num]);
		add(Menu, 511, String);
	}
	
	if(!Revoted)
	formatex(String, 127, "%L", Lang, "MCSL", MapCounter);
	else
	formatex(String, 127, "%L", Lang, "MNM", Next);
	
	add(Menu, 511, String);
	
	Key = (-1^(-1<<(1+StartButton)));
	
	show_menu(id, Key, Menu, -1, "RevoteMenu");
}
public RevoteMenuKeys(id, Key)
{
	if(PlayerRevoted[id] || Revoted)
	{
		if(PlayerVoted[id])
			print_color(id, "%s %L", Prefix, Lang, "AVO");
		
		ShowRevoteMenu(id);
		return;
	}
	
	if(!Begined)
	{
		show_menu(id, 0, "^n", 1);
		return;
	}
	
	new PlayerName[32];
	get_user_name(id, PlayerName, 31);
	
	Key -= StartButton-1;
	
	if(Key <= 2 && Key > -1)
	{
		PlayerMap[id] = Key;
		PlayerRevoted[id] = true;
		print_color(0, "%s %L", Prefix, Lang, "PCHO", PlayerName, MapRevote[Key]);
		RevoteCounts[Key]++;
		if(get_pcvar_num(Cvar_ChooseSound) == 1)
		{
			client_cmd(0, "spk buttons/lightswitch2");
		}
	}
	
	ShowRevoteMenu(id);
}
public ReCounter()
{
	if(MapCounter < 1)
	{
		Revoted = true;
		
		inProcess = false;
		
		CheckRevotes();
		
		for(new Num; Num < 32; Num++)
		{
			if(!is_user_connected(Num))
				continue;
				
			ShowRevoteMenu(Num);
		}
	}
	else
	{
		MapCounter--;
		
		set_task(1.0, "ReCounter", MapID+211);
		
		for(new Num; Num < 32; Num++)
		{
			if(!is_user_connected(Num))
				continue;
				
			ShowRevoteMenu(Num);
		}
	}
}
public client_disconnect(id)
{
	if(PlayerRTV[id])
	{
		RTV--;
		PlayerRTV[id] = false;
	}
	
	if(PlayerVoted[id])
	{
		MapVote[PlayerMap[id]]--;
		PlayerVoted[id] = false;
	}
	
	if(PlayerRevoted[id])
	{
		RevoteCounts[PlayerMap[id]]--;
		PlayerRevoted[id] = false;
	}
	
	PlayerMap[id] = 0;
	
}
stock ChangeLevel()
{
	set_task(get_pcvar_float(Cvar_ChangeSpeed), "Change", MapID+2);
	message_begin(MSG_ALL, SVC_INTERMISSION);
	message_end();
}
stock print_color(const id, const input[], any:...)
{
	new Count = 1, Players[32];
	static Msg[191];
	vformat(Msg, 190, input, 3);
	
	replace_all(Msg, 190, "!g", "^4");
	replace_all(Msg, 190, "!y", "^1");
	replace_all(Msg, 190, "!t", "^3");

	if(id) Players[0] = id; else get_players(Players, Count, "ch");
	{
		for (new i = 0; i < Count; i++)
		{
			if (is_user_connected(Players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, Players[i]);
				write_byte(Players[i]);
				write_string(Msg);
				message_end();
			}
		}
	}
	return PLUGIN_HANDLED;
}
stock CheckVotes() {
	
	if(AllVotes == 0)
	{
		Revoted = false;
		Next = MapNames[0];
		set_cvar_string("amx_nextmap", Next);
		NextMap();
		return PLUGIN_HANDLED;
	}
	
	new VoteNum_1 = 0;
	
	for(new Num = 0; Num < get_pcvar_num(Cvar_MaxMaps); ++Num)
	{
		if(MapVote[VoteNum_1] < MapVote[Num])
		{
			VoteNum_1 = Num;
		}
	}
	
	if((MapVote[VoteNum_1]*100/AllVotes) >= get_pcvar_num(Cvar_VotePercentMin))
	{
		Revoted = false;
		Next = MapNames[VoteNum_1];
		VotedMap = Next;
		set_cvar_string("amx_nextmap", Next);
		
		if(get_pcvar_num(Cvar_Mod) == 1)
		{
			if(equali(Next, MapName))
			{
				new Hour[32], Minute[32], Second[32], pTime[3];
				format_time(Hour, sizeof Hour - 1, "%H");
				format_time(Minute, sizeof Minute - 1, "%M");
				format_time(Second, sizeof Second - 1, "%S");
				pTime[0] = str_to_num(Second);
				pTime[1] = str_to_num(Minute);
				pTime[2] = str_to_num(Hour);
				
				pTime[1] = pTime[1] - ElapsedTime[1];
				
				if(pTime[0] >= ElapsedTime[0])
					pTime[0] = pTime[0] - ElapsedTime[0];
				else
				{
					pTime[0] = pTime[0]+60 - ElapsedTime[0];
					pTime[1]--;
				}
				
				if(pTime[2] == ElapsedTime[2])
				server_cmd("mp_timelimit %d.%02d", get_pcvar_num(Cvar_Extend)+pTime[1], pTime[0]);
				else
				server_cmd("mp_timelimit %d.%02d", (get_pcvar_num(Cvar_Extend)+pTime[1])+(60*(pTime[2]-ElapsedTime[2])), pTime[0]);
				
				print_color(0, "%s %L", Prefix, Lang, "MEXTEND1", get_pcvar_num(Cvar_Extend));
				
				Extend();
			}
		}
		else if(get_pcvar_num(Cvar_Mod) == 0)
		{
			if(equali(Next, MapName))
			{
				print_color(0, "%s %L", Prefix, Lang, "MEXTEND2", get_pcvar_num(Cvar_Extend));
				server_cmd("mp_maxrounds ^"%d^"", get_pcvar_num(Cvar_Extend)+oRounds+Rounds);
				
				MaxRounds = get_pcvar_num(Cvar_Extend)+(MaxRounds-Rounds);
				Rounds = 0;
				
				Extend();
			}
		}
	}
	else
	{
		NeedRV = true;
		Voted = false;
		
		MapVote[VoteNum_1] = -MapVote[VoteNum_1];
		
		new VoteNum_1_1 = 0;

		for(new Num = 0; Num < get_pcvar_num(Cvar_MaxMaps); ++Num)
		{
			if(MapVote[VoteNum_1_1] < MapVote[Num])
			{
				VoteNum_1_1 = Num;
			}
		}
		
		MapVote[VoteNum_1] = 0-MapVote[VoteNum_1];
		
		copy(MapRevote[0], 31, MapNames[VoteNum_1]);
		copy(MapRevote[1], 31, MapNames[VoteNum_1_1]);
		
		RevoteCounts[0] = 0;
		RevoteCounts[1] = 0;
		
		VoteMod = 0;
		set_task(get_pcvar_float(Cvar_StartRevoteTime), "StartRevoteTime", MapID+3);
		print_color(0, "%s %L", Prefix, Lang, "RER", get_pcvar_num(Cvar_VotePercentMin));
	}	
	
	NextMap();
	return PLUGIN_CONTINUE;
}
stock CheckRevotes() {
	
	if(AllRevotes == 0)
	{
		Next = MapRevote[0];
		set_cvar_string("amx_nextmap", Next);
		NeedRV = false;
		VotedMap = Next;
		NextMap();
		return PLUGIN_HANDLED;
	}
	
	new VoteNum_1 = 0;
	
	for(new Num = 0; Num < 2; ++Num)
	{
		if(RevoteCounts[VoteNum_1] < RevoteCounts[Num])
		VoteNum_1 = Num;
	}
	
	Next = MapRevote[VoteNum_1];
	set_cvar_string("amx_nextmap", Next);
	NeedRV = false;
	VotedMap = Next;
	
	if(get_pcvar_num(Cvar_Mod) == 1)
	{
		if(equali(Next, MapName))
		{
			new Hour[32], Minute[32], Second[32], pTime[3];
			format_time(Hour, sizeof Hour - 1, "%H");
			format_time(Minute, sizeof Minute - 1, "%M");
			format_time(Second, sizeof Second - 1, "%S");
			pTime[0] = str_to_num(Second);
			pTime[1] = str_to_num(Minute);
			pTime[2] = str_to_num(Hour);
			
			pTime[1] = pTime[1] - ElapsedTime[1];
			
			if(pTime[0] >= ElapsedTime[0])
				pTime[0] = pTime[0] - ElapsedTime[0];
			else
			{
				pTime[0] = pTime[0]+60 - ElapsedTime[0];
				pTime[1]--;
			}
			
			if(pTime[2] == ElapsedTime[2])
			server_cmd("mp_timelimit %d.%02d", get_pcvar_num(Cvar_Extend)+pTime[1], pTime[0]);
			else
			server_cmd("mp_timelimit %d.%02d", (get_pcvar_num(Cvar_Extend)+pTime[1])+(60*(pTime[2]-ElapsedTime[2])), pTime[0]);
			
			print_color(0, "%s %L", Prefix, Lang, "MEXTEND1", get_pcvar_num(Cvar_Extend));
			
			Extend();
		}
	}
	else if(get_pcvar_num(Cvar_Mod) == 0)
	{
		if(equali(Next, MapName))
		{
			print_color(0, "%s %L", Prefix, Lang, "MEXTEND2", get_pcvar_num(Cvar_Extend));
			server_cmd("mp_maxrounds ^"%d^"", get_pcvar_num(Cvar_Extend)+oRounds+Rounds);
			
			MaxRounds = get_pcvar_num(Cvar_Extend)+(MaxRounds-Rounds);
			Rounds = 0;
			
			Extend();
		}
	}
	
	NextMap();
	return PLUGIN_CONTINUE;
}
stock bool:isValidMap(Map[])
{
	for(new MapNum; MapNum < get_pcvar_num(Cvar_LastMaps); MapNum++) 
	{
		if(equal(LastMaps[MapNum], Map))
			return false;
	}
	
	if(is_map_valid(Map))
	{
		return true;
	}
	
	new Len = strlen(Map) - 4;
	
	if(0 > Len)
	{
		return false;
	}
	
	if(equali(Map[Len], ".bsp"))
	{
		Map[Len] = '^0';
		
		if(is_map_valid(Map))
		{
			return true;
		}
	}
	
	return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
