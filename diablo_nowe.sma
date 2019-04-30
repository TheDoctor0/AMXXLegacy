/*	
	@author Rafal "DarkGL" Wiecek 
	@site www.darkgl.amxx.pl
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <sqlx>
#include <csx>
#include <colorchat>

#include "configDiablo.inc"

/*---------------------SQL---------------------*/
new bool:bSql = false;

new bool:sqlPlayer[MAX+1]

enum sqlCvarsStruct {
	eHost,
	eUser,
	ePass,
	eDb
}

new Handle:gTuple;

new pSqlCvars[sqlCvarsStruct]

/*---------------------PCVARS---------------------*/

new pCvarSaveType,
pCvarAVG,
pCvarNum,
pCvarDamage,
pCvarXPBonus,
pCvarXPBonus2,
pCvarKnifeSpeed,
pCvarKnife,
pCvarPrefixy,
pCvarDurability,
pCvarArrow,
pCvarMulti,
pCvarSpeed,
pCvarVersion,
pCvarExpPrice,
pCvarRandomPrice,
pCvarUpgradePrice,
pCvarCostDaj,
pCvarPoints,
pCvarWriteHudMode,
pCvarStrPower,
pCvarReducePower,
pCvarFriendlyFire;

#if !defined EXP_TABLE
new pCvarLevelPropotion,
pCvarMaxLevel;
#endif

/*---------------------EXP---------------------*/

#if defined EXP_TABLE
new LevelXP[MAX_LEVEL + 1] = { 0,25,85,185,300,450,700,850,1000,1335,1500,1800,2100,2400,2800,3200,3600,4000,
	4500,5000,5500,6000,6500,7000,7500,8000,8500,9000,9500,10000,10500,11000,11500,12000,
	12400,13000,13600,14200,15000,15500,16000,16500,17000,17325,18000,18600,19000,19300,19700,20000,22000,24254,//52
	26874,29564,32265,35443,38765,40322,43654,46345,49231,51544,53265,56353,59675,62000,65000,68000,71000,74000,77000,79000,81000,83000,
	86000,89000,92000,95000,98000,101000,120000,140000,160000,180000,200000,220000,240000,260000,280000,300000,320000,340000,360000,380000,400000,420000,440000,460000,480000,500000,520000,540000,560000,580000,610000,640000,670000,700000,730000, //109
	760000,800000,840000,880000,920000,960000,980000,1040000,1080000,1120000,1160000,1200000,1240000,1280000,1320000,1360000,1400000,1440000,1480000,1520000,1560000,1600000,1640000,1680000,1720000,1760000,1800000,1840000,1880000,1920000,1960000,2000000,2040000,2080000,2120000,2160000,
	2200000,2240000,2280000,2320000,2360000,2400000,2440000,2480000,2520000,2560000,2600000,2640000,2680000,2720000,2760000,2800000,2840000,2880000,2920000,2960000,3000000,3040000,3080000,3120000,3160000,3200000,3240000,3280000,3320000,3360000,3400000,3440000,3480000,3520000,3560000,3600000,3640000,3680000,3720000,3760000,3800000,3840000,3880000,3920000,3960000,4200000,20815000}
#endif

enum renderStruct {
	renderR = 0,
	renderG,
	renderB,
	renderFx,
	renderNormal,
	renderAmount,
	renderTime
}

/* Forwards */

enum forwardsStructureClass {
	CLASS_CLEAN_DATA,
	CLASS_SET_DATA,
	CLASS_ENABLED,
	CLASS_DISABLED,
	CLASS_SPAWNED,
	CLASS_POST_THINK,
	CLASS_PRE_THINK,
	CLASS_CALL_CAST,
	CLASS_CAST_STOP,
	CLASS_CAST_MOVE,
	CLASS_CAST_TIME,
	CLASS_SKILL_USED,
	CLASS_KILLED,
	CLASS_DAMAGE_TAKEN,
	CLASS_DAMAGE_DO
}

enum forwardsStructureItem {
	ITEM_SKILL_USED,
	ITEM_UPGRADE_ITEM,
	ITEM_INFO,
	ITEM_RESET,
	ITEM_DROP,
	ITEM_PRE_THINK,
	ITEM_PLAYER_SPAWNED,
	ITEM_SET_DATA,
	ITEM_GIVE,
	ITEM_COPY,
	ITEM_DAMAGE_TAKEN,
	ITEM_DAMAGE_DO
}

enum forwardsMulti{
	MULTI_NEW_ROUND,
	MULTI_EXP_DAMAGE,
	MULTI_DAMAGE_TAKEN_POST,
	MULTI_DAMAGE_TAKEN_PRE,
	MULTI_USER_CHANGE_CLASS,
	MULTI_KILL_XP,
	MULTI_HUD_WRITE,
	MULTI_WEAPON_DEPLOY,
	MULTI_RENDER_CHANGE,
	MULTI_GRAV_CHANGE,
	MULTI_PLAYER_SPAWNED,
	MULTI_DEATH,
	MUTLI_USER_CHANGE_CLASS,
	MULTI_HAS_ADDITIONAL_DAMAGE,
	MUTLI_CLIENT_PRE_THINK,
	MUTLI_CLEAN_USER_INFORMATION,
	MULTI_SET_RENDER,
	MUTLI_CUR_WEAPON,
	MULTI_GIVE_ITEM,
	MULTI_CAN_USE_SKILL
}

new Array: gForwardsClass,
Array: gForwardsItem;

new gForwardsMulti[ forwardsMulti ];

/*---------------------HUD---------------------*/
new syncHud,
HudSyncObj,
gmsgStatusText;

new Array:gClassPlugins,
Array:gClassNames,
Array:gClassAvg,
Array:gClassHp,
Array:gClassDesc,
Array:gClassFlag,
Array:gItemName,
Array:gItemPlugin,
Array:gItemDur,
Array: gItemFrom,
Array: gItemTo,
Array:gClassFraction,
Array:gFractionNames;

new bool:bFirstRespawn[ MAX + 1 ];

enum DiabloDamageBits{
	diabloDamageKnife 	=	(1<<1) , 
	diabloDamageGrenade =	(1<<24) ,
	diabloDamageShot	=	(1<<12) | (1<<1)
}

enum PlayerStruct {
	currentClass,
	currentLevel,
	currentExp,
	currentStr,
	currentInt,
	currentDex,
	currentAgi,
	currentArmor,
	currentLuck,
	currentPoints,
	currentItem,
	extraStr,
	extraInt,
	extraDex,
	extraAgi,
	itemDurability,
	maxHp,
	castTime,
	currentSpeed,
	dmgReduce,
	maxKnife,
	howMuchKnife,
	tossDelay,
	userGrav,
	playerName[MAX_LEN_NAME_PLAYER + 1]
}

new playerInf[ MAX + 1 ][PlayerStruct],
Array:playerInfClasses[ MAX + 1 ],
Array:playerInfRender[ MAX + 1 ]

new bool:bFreezeTime = false,iPlayersNum = 0;
new bool:bWasducking[MAX+1]

new spriteBoom,spriteBloodSpray,spriteBloodDrop;

//trap mode
new bool:g_TrapMode[MAX+1];
new g_GrenadeTrap[MAX+1];
new Float:g_PreThinkDelay[MAX+1];

new cvar_throw_vel = 90 // def: 90
new cvar_activate_dis = 175 // def 190
new cvar_nade_vel = 280 //def 280
new Float: cvar_explode_delay = 0.5 // def 0.50

#define NADE_VELOCITY	EV_INT_iuser1
#define NADE_ACTIVE	EV_INT_iuser2	
#define NADE_TEAM	EV_INT_iuser3	
#define NADE_PAUSE	EV_INT_iuser4

//bow

new Float:bowdelay[MAX+1],bool:bow[MAX+1],bHasBow[MAX+1]

new pRuneMenu , pModMenu;

new iPlayerFraction[ MAX + 1 ];

new fileLogPath[ 256 ];

public plugin_init(){
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	pCvarVersion		=	register_cvar("diablomod_version","1.1.0 PL",FCVAR_SERVER)
	
	pSqlCvars[eHost] 	= 	register_cvar("diablo_host","localhost");
	pSqlCvars[eUser] 	= 	register_cvar("diablo_user","user");
	pSqlCvars[ePass] 	= 	register_cvar("diablo_pass","pass");
	pSqlCvars[eDb] 		= 	register_cvar("diablo_db","db");
	
	pCvarSaveType 		=	register_cvar("diablo_save_type","3")
	pCvarAVG			=	register_cvar("diablo_avg","1")
	
	pCvarNum			=	register_cvar("diablo_player_num","2");
	
	pCvarPoints			=	register_cvar("diablo_points" , "2" );
	
	pCvarDamage			=	register_cvar("diablo_dmg_exp","20");
	pCvarXPBonus		=	register_cvar("diablo_xpbonus","5");
	pCvarXPBonus2		=	register_cvar("diablo_xpbonus2","100")
	
	pCvarKnifeSpeed		=	register_cvar("diablo_knife_speed","1000");
	pCvarKnife			=	register_cvar("diablo_knife","80.0");
	
	pCvarPrefixy		=	register_cvar("diablo_prefixy","1");
	
	pCvarArrow 			=	register_cvar("diablo_arrow","120.0");
	pCvarMulti			=	register_cvar("diablo_arrow_multi","2.0");
	pCvarSpeed			=	register_cvar("diablo_arrow_speed","1500")
	
	pCvarDurability		=	register_cvar("diablo_durability","10")
	
	pCvarExpPrice		=	register_cvar("diablo_exp_price" , "14500")
	pCvarRandomPrice	=	register_cvar("diablo_random_price" , "9000")
	pCvarUpgradePrice	=	register_cvar("diablo_upgrade_price" , "5000")
	
	pCvarCostDaj		=	register_cvar("diablo_price_daj","5000");
	
	#if !defined EXP_TABLE
	pCvarLevelPropotion	=	register_cvar( "diablo_level_propotion", "35");
	pCvarMaxLevel		=	register_cvar( "diablo_max_level", "200");
	#endif
	
	pCvarWriteHudMode	=	register_cvar( "diablo_hud_mode" , "1" );
	
	pCvarStrPower		=	register_cvar( "diablo_strength_power" , "2" );
	pCvarReducePower	=	register_cvar( "diablo_reduce_power", "0.03" );
	
	pCvarFriendlyFire	=	get_cvar_pointer( "mp_friendlyfire" );
	
	new tmpForwardsClass[ forwardsStructureClass ],
	tmpForwardsItem[ forwardsStructureItem ];
	
	gClassPlugins 		= 	ArrayCreate(1,10)
	gClassNames			=	ArrayCreate(MAX_LEN_NAME,10)
	gClassAvg			=	ArrayCreate(1,10);
	gClassHp			=	ArrayCreate(1,10)
	gClassDesc			=	ArrayCreate(MAX_LEN_DESC,10);
	gClassFlag			=	ArrayCreate(1,10);
	gItemName			=	ArrayCreate(MAX_LEN_NAME,10);
	gItemPlugin			=	ArrayCreate(1,10);
	gItemDur			=	ArrayCreate(1,10);
	gItemFrom			=	ArrayCreate( 1 , 10 );
	gItemTo				=	ArrayCreate( 1 , 10 );
	gClassFraction		=	ArrayCreate(1,10);
	gFractionNames		=	ArrayCreate(MAX_LEN_FRACTION,10)
	
	gForwardsClass		=	ArrayCreate( sizeof( tmpForwardsClass )  , 10 );
	gForwardsItem		=	ArrayCreate( sizeof( tmpForwardsItem ) , 10 );
	
	for(new i = 1; i < MAX + 1;i ++ ){
		playerInfClasses[i] = 	ArrayCreate(9,10);
		playerInfRender[i]	=	ArrayCreate(8,10);
	}
	
	ArrayPushCell(gClassPlugins,0)
	ArrayPushString(gClassNames,"None");
	ArrayPushCell(gClassAvg,1);
	ArrayPushCell(gClassHp,100);
	ArrayPushString(gClassDesc,"None");
	ArrayPushCell(gClassFlag,FLAG_ALL)
	ArrayPushString(gItemName,"None");
	ArrayPushCell(gItemPlugin,0)
	ArrayPushCell(gItemDur,-1);
	ArrayPushCell( gItemFrom , 0 );
	ArrayPushCell( gItemTo , 0 );
	ArrayPushCell( gClassFraction , 0 );
	ArrayPushString( gFractionNames , "None" );
	
	ArrayPushArray( gForwardsClass , tmpForwardsClass );
	ArrayPushArray( gForwardsItem , tmpForwardsItem );
	
	register_clcmd("say /klasy",			"showKlasy")
	register_clcmd("say_team /klasy",		"showKlasy")
	register_clcmd("say /klasa",			"wybierzKlase")
	register_clcmd("say_team /klasa",		"wybierzKlase")
	register_clcmd("say /reset",			"resetSkills");
	register_clcmd("say_team /reset",		"resetSkills");
	register_clcmd("say /drop",				"dropItem") 
	register_clcmd("say_team /drop",		"dropItem") 
	register_clcmd("say /przedmiot",		"itemInfo")
	register_clcmd("say_team /przedmiot",	"itemInfo")
	register_clcmd("say /item",				"itemInfo")
	register_clcmd("say_team /item",		"itemInfo")
	register_clcmd("say /itemy",			"itemsMenu")
	register_clcmd("say_team /itemy",		"itemsMenu")
	register_clcmd("say /gracze",			"playersList")
	register_clcmd("say_team /gracze",		"playersList")
	register_clcmd("say /czary",			"showSkills")
	register_clcmd("say_team /czary",		"showSkills")
	register_clcmd("say /skille",			"showSkills")
	register_clcmd("say_team /skille",		"showSkills")
	register_clcmd("say /rune",				"runeMenu")
	register_clcmd("say_team /rune",		"runeMenu")
	register_clcmd("say /wymiana",			"wymianaItemami");
	register_clcmd("say_team /wymiana",		"wymianaItemami");
	register_clcmd("say /wymiem",			"wymianaItemami");
	register_clcmd("say_team /wymien",		"wymianaItemami");
	register_clcmd("say",					"wymianaItemami2");// /daj /oddaj
	register_clcmd("say_team",				"wymianaItemami2");// /daj /oddaj
	register_clcmd("say /pomoc",			"helpMotd");
	register_clcmd("say_team /pomoc",		"helpMotd");
	register_clcmd("say /help",				"helpMotd");
	register_clcmd("say_team /help",		"helpMotd");
	register_clcmd("say /komendy",			"commandList");
	register_clcmd("say_team /komendy",		"commandList");
	register_clcmd("say /menu",				"modMenu");
	register_clcmd("say_team /menu",		"modMenu");
	register_clcmd("say /exp",				"expInf");
	register_clcmd("say_team /exp",			"expInf");

	register_clcmd("diablomod_version",		"showVersion");
	
	//short commands
	register_clcmd("say /k",			"wybierzKlase")
	register_clcmd("say_team /k",		"wybierzKlase")
	register_clcmd("say /r",			"resetSkills");
	register_clcmd("say_team /r",		"resetSkills");
	register_clcmd("say /d",				"dropItem") 
	register_clcmd("say_team /d",		"dropItem") 
	register_clcmd("say /p",			"itemInfo")
	register_clcmd("say_team /p",		"itemInfo")
	register_clcmd("say /i",				"itemInfo")
	register_clcmd("say_team /i",		"itemInfo")
	register_clcmd("say /g",			"playersList")
	register_clcmd("say_team /g",		"playersList")
	register_clcmd("say /c",			"showSkills")
	register_clcmd("say_team /c",		"showSkills")
	register_clcmd("say /ru",				"runeMenu")
	register_clcmd("say_team /ru",		"runeMenu")
	register_clcmd("say /w",			"wymianaItemami");
	register_clcmd("say_team /w",		"wymianaItemami");
	register_clcmd("say /p",			"helpMotd");
	register_clcmd("say_team /p",		"helpMotd");
	register_clcmd("say /h",				"helpMotd");
	register_clcmd("say_team /h",		"helpMotd");
	register_clcmd("say /ko",			"commandList");
	register_clcmd("say_team /ko",		"commandList");
	register_clcmd("say /m",				"modMenu");
	register_clcmd("say_team /m",		"modMenu");
	
	register_clcmd("amx_giveexp",			"giveExp",		ADMIN_FLAG_GIVE , "Uzycie amx_giveexp <nick> <ile>" );
	register_clcmd("amx_giveitem",  		"giveItem",     ADMIN_FLAG_GIVE , "Uzycie amx_giveitem <nick> <iditemu>" );
	
	register_touch(THROW_KNIFE_CLASS, "*", "touchKnife")
	register_touch("func_breakable", THROW_KNIFE_CLASS,		"touchKnifeBreakAbleWrap")
	
	register_touch(XBOW_ARROW, "*",	"touchArrow")
	register_touch("func_breakable", XBOW_ARROW,	"touchArrowBreakAbleWrap")
	
	register_event("SendAudio",		"freezeOver","b","2=%!MRAD_GO","2=%!MRAD_MOVEOUT","2=%!MRAD_LETSGO","2=%!MRAD_LOCKNLOAD")
	register_event("SendAudio",		"freezeBegin","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw") 
	register_event("StatusValue", 	"showStatus", "be", "1=2", "2!0")
	register_event("StatusText",	"showStatus","be");
	register_event("DeathMsg", 		"DeathMsg", "a")
	register_event("Damage", 		"eventDamage", "b", "2!=0")
	register_event("TextMsg",		"hostKilled","b","2&#Killed_Hostage") 
	register_event("HLTV",			"newRound", 	"a", "1=0", "2=0")
	
	register_logevent("awardHostage",3,"2=Rescued_A_Hostage")
	
	gmsgStatusText	=	get_user_msgid("StatusText");
	
	if( !equal( GAME_DESCRIPTION , "" ) ){
		register_forward( FM_GetGameDescription, "fwGameDesc" )
	}
	
	new const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
		"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
		"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
		"weapon_ak47", "weapon_knife", "weapon_p90" }
	
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)	if (g_szWpnEntNames[i][0]) RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "fwItemDeployPost", 1)
	
	RegisterHam( Ham_Spawn , "player" , "fwSpawned" , true );
	RegisterHam( Ham_TakeDamage , "player","fwDamage" , false );
	
	RegisterHam( get_player_resetmaxspeed_func(), "player", "fwSpeedChange", true );
	
	register_message(get_user_msgid("Health") ,	"msgHealth");
	register_message(get_user_msgid("SayText"),	"handleSayText");
	register_message(get_user_msgid("ClCorpse"), "messageClCorpse")
	
	_create_runeMenu();
	_create_modMenu();
	
	syncHud		=	CreateHudSyncObj();
	HudSyncObj	=	CreateHudSyncObj();
	
	#if defined BOTY
	register_forward( FM_AddToFullPack, "fwAddToFullPack" );
	#endif
	
	set_task( 180.0 , "autoHelp" , .flags = "b" );
	
	return PLUGIN_HANDLED;
}

public plugin_precache(){
	precache_model("models/rpgrocket.mdl")
	precache_model(THROW_KNIFE_MODEL);
	
	precache_model(cbow_VIEW)
	precache_model(cvow_PLAYER)
	precache_model(cbow_bolt)
	
	spriteBoom			=	precache_model("sprites/zerogxplode.spr");
	spriteBloodSpray	=	precache_model("sprites/bloodspray.spr")	
	spriteBloodDrop		=	precache_model("sprites/blood.spr");
}

public plugin_cfg(){
	new szPathConfigFolder[ 256 ],
	szPathConfigFile[ 256 ];
	
	get_configsdir( szPathConfigFolder , charsmax( szPathConfigFolder ) );
	
	formatex( szPathConfigFile , charsmax( szPathConfigFile ),"%s/diablomod.cfg" , szPathConfigFolder );
	formatex( fileLogPath , charsmax( fileLogPath ),"%s/%s" , szPathConfigFolder , fileLog );
	
	server_cmd("exec ^"%s^"",szPathConfigFile );
	server_exec();
	
	server_cmd("sv_maxspeed 1500");
	server_exec();
	server_cmd("sv_airaccelerate 100");
	server_exec();
	
	gForwardsMulti[ MULTI_NEW_ROUND ] 				=	CreateMultiForward( "diablo_new_round" , ET_IGNORE );
	gForwardsMulti[ MULTI_EXP_DAMAGE ] 				= 	CreateMultiForward ("diablo_exp_damage",ET_CONTINUE,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_DAMAGE_TAKEN_POST	] 		= 	CreateMultiForward ("diablo_damage_taken_post",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_DAMAGE_TAKEN_PRE	] 		= 	CreateMultiForward ("diablo_damage_taken_pre",ET_IGNORE,FP_CELL,FP_CELL,FP_ARRAY);
	gForwardsMulti[ MULTI_USER_CHANGE_CLASS	] 		= 	CreateMultiForward("diablo_user_change_class",ET_IGNORE,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_KILL_XP ]					= 	CreateMultiForward ("diablo_kill_xp",ET_CONTINUE,FP_CELL,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_HUD_WRITE ] 				= 	CreateMultiForward ("diablo_hud_write",ET_IGNORE,FP_CELL,FP_ARRAY,FP_CELL);
	gForwardsMulti[ MULTI_WEAPON_DEPLOY ] 			= 	CreateMultiForward("diablo_weapon_deploy",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_RENDER_CHANGE ] 			= 	CreateMultiForward("diablo_render_change",ET_IGNORE,FP_CELL);
	gForwardsMulti[ MULTI_GRAV_CHANGE ] 			= 	CreateMultiForward("diablo_grav_change",ET_IGNORE,FP_CELL);
	gForwardsMulti[ MULTI_PLAYER_SPAWNED ] 			= 	CreateMultiForward("diablo_player_spawned",ET_IGNORE,FP_CELL);
	gForwardsMulti[ MULTI_DEATH ] 					= 	CreateMultiForward("diablo_death",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL,FP_CELL);
	gForwardsMulti[ MUTLI_USER_CHANGE_CLASS ]		=	CreateMultiForward("diablo_user_change_class",ET_IGNORE,FP_CELL,FP_CELL);
	gForwardsMulti[ MULTI_HAS_ADDITIONAL_DAMAGE ]	=	CreateMultiForward("diablo_is_additional_damage",ET_STOP);
	gForwardsMulti[ MUTLI_CLIENT_PRE_THINK ]		=	CreateMultiForward("diablo_preThink",ET_IGNORE,FP_CELL);
	gForwardsMulti[ MUTLI_CLEAN_USER_INFORMATION ]	=	CreateMultiForward("diablo_clean_user_inf",ET_IGNORE);
	gForwardsMulti[ MULTI_SET_RENDER ]				=	CreateMultiForward("diablo_is_set_render",ET_STOP);
	gForwardsMulti[ MUTLI_CUR_WEAPON ]				=	CreateMultiForward( "diablo_cur_weapon" , ET_IGNORE , FP_CELL );
	gForwardsMulti[ MULTI_GIVE_ITEM ]				=	CreateMultiForward( "diablo_give_item" , ET_IGNORE , FP_CELL , FP_CELL );
	gForwardsMulti[ MULTI_CAN_USE_SKILL ]			=	CreateMultiForward( "diablo_can_use_skill" , ET_STOP , FP_CELL );
	
	sqlStart();
}

public fwGameDesc( ){
	forward_return( FMV_STRING, GAME_DESCRIPTION ); 
	return FMRES_SUPERCEDE; 
}

public wymianaItemami2( id ){
	new szParametr[ 256 ] , szParametrTwo[ 64 ] , szCommand[ 64 ];
	
	read_argv( 1 , szParametr , charsmax( szParametr ) );
	
	parse( szParametr , szCommand , charsmax( szCommand ) , szParametrTwo , charsmax( szParametrTwo ) );
	
	if( equal( szCommand , "/daj") || equal( szCommand , "/oddaj") ){
		if( isPlayerItemNone( id ) ){
			ColorChat( id ,  GREEN ,"%s Nie posiadasz zadnego itemu!" , PREFIX_SAY);
			
			return PLUGIN_HANDLED;
		}
		
		new iFind	=	find_player( "bjlh" , szParametrTwo);
		
		if( !is_user_connected( iFind ) ){
			ColorChat( id , GREEN , "%s Nie znaleziono gracza", PREFIX_SAY );
			
			return PLUGIN_HANDLED;
		}
		
		if( !isPlayerItemNone( iFind ) ){
			ColorChat( id ,  GREEN ,"%s Ten gracz ma juz item sprobuj sie wymienic z nim poprzez komende /wymiana" , PREFIX_SAY );
			
			return PLUGIN_HANDLED;
		}
		
		new szID[ 16 ] , szTitle[ 256 ] , szItem[ MAX_LEN_NAME ] , szName[ MAX_LEN_NAME ];
		
		get_user_name( id , szName , charsmax( szName ) );
		
		ArrayGetString( gItemName , getPlayerItem( id ) , szItem , charsmax( szItem ) );
		
		formatex( szTitle , charsmax( szTitle ) , "\w%s chce wymienic sie z toba iteamami oferuje ci ^n\r %s ^nKoszt: %d$^n\w Zgadasz sie ?", szName , szItem , get_pcvar_num( pCvarCostDaj ) );
		
		new pMenu	=	menu_create( szTitle , "wymianaItemami2Handle");
		
		num_to_str( id , szID , charsmax( szID ) );
		
		menu_additem( pMenu , "Tak" , szID)
		menu_additem( pMenu , "Nie" , szID)
		
		menu_setprop( pMenu , MPROP_EXIT , MEXIT_NEVER );
		
		#if defined BOTY
		if( is_user_bot( id) ){
			wymianaItemamiPotwierdzenie(id , pMenu,  random_num( 0 , 1 ) )
			
			return PLUGIN_HANDLED;
		}
		#endif
		
		menu_display( iFind , pMenu );
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public wymianaItemami2Handle( id , menu , item ){
	if( item	==	MENU_EXIT ){
		menu_destroy( menu );
		
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( item == 1 ){
		ColorChat( idTarget ,  GREEN ,"%s Gracz nie zgodzil sie na wymiane" , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id , GREEN , "%s Tego gracza juz nie ma na serwerze" , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !isPlayerItemNone( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Ten gracz ma juz itemu" , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	if( isPlayerItemNone( id ) ){
		ColorChat( id ,  GREEN ,"%s Nie masz itemu oszuscie" , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new costDaj	=	get_pcvar_num( pCvarCostDaj );
	
	if( cs_get_user_money( id ) < costDaj ){
		ColorChat( id ,  GREEN ,"%s Masz za malo kasy potrzebujesz %d$" , PREFIX_SAY , costDaj);
		ColorChat( idTarget ,  GREEN ,"%s Gracz ma za malo kasy" , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_money( id , cs_get_user_money( id ) - costDaj );
	
	cs_set_user_money( idTarget , cs_get_user_money( idTarget ) + costDaj );
	
	new szItem[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , getPlayerItem( idTarget ) , szItem ,charsmax( szItem ) )
	
	ExecuteForwardIgnoreIntTwoParam( getForwardItem( getPlayerItem( idTarget ) , ITEM_COPY ) , idTarget , id );
	
	setPlayerItem( id , getPlayerItem( idTarget ) , playerInf[ idTarget ][ itemDurability ] );
	
	setPlayerItem( idTarget , 0 );
	
	ColorChat( id , GREEN , "%s Otrzymales %s" , PREFIX_SAY , szItem );
	ColorChat( idTarget ,  GREEN ,"%s Otrzymales %d$" , PREFIX_SAY , costDaj );
	
	menu_destroy( menu );
	
	return PLUGIN_HANDLED;
}

public expInf( id ){
	if( isPlayerClassNone( id ) ){ 
		ColorChat( id , GREEN , "%s Nie masz zadnej klasy" , PREFIX_SAY);
	}
	else{
		ColorChat( id , GREEN ,"%s Obecnie posiadasz %i expa potrzebujesz %i czyli brakuje ci %i ( %0.2f%s )" , PREFIX_SAY ,  playerInf[ id ][ currentExp ] ,  getLevelXP( playerInf[id][currentLevel] ), getLevelXP( playerInf[id][currentLevel] )  - playerInf[ id ][ currentExp ] , ((float(playerInf[id][currentExp])-float( getLevelXP( playerInf[id][currentLevel] - 1 ) ) )*100.0)/(float( getLevelXP( playerInf[id][currentLevel] ) )-float( getLevelXP( playerInf[id][currentLevel] - 1 ) ) ) , "%" );
	}
	return PLUGIN_HANDLED;
}

public messageClCorpse(){
	return PLUGIN_HANDLED;
}

public autoHelp( )
{
	set_hudmessage(0, 180, 0, -1.0, 0.70, 0, 10.0, 5.0, 0.1, 0.5, 11);
	
	switch ( random_num( 1 , 5 ) ){
	case 1: {
			show_hudmessage(0, "Przedmiot upuszczasz za pomoca /drop a informacje o przedmiocie uzyskasz za pomoca komendy /przedmiot")
		}
	case 2: {
			show_hudmessage(0, "Mozesz uzywac konkretnych przedmiotow za pomoca klawisza E")
		}
	case 3: {
			show_hudmessage(0, "Mozesz dostac wiecej pomocy jak napiszesz /pomoc lub zobaczyc wszystkie komendy jak napiszesz /komendy")
		}
	case 4: {
			show_hudmessage(0, "Zeby bylo prosciej grac mozesz zbindowac sobie diablo menu (bind klawisz say /menu")
		}
	case 5: {
			show_hudmessage(0, "Niektore przedmioty moga byc ulepszone przez Runy. Napisz /rune zeby otworzyc sklep z runami")
		}
	}
}

public giveExp( id , level , cid ){
	if(!cmd_access(id,level, cid, 3)) 
	return PLUGIN_HANDLED; 
	
	new szName[ 64 ];
	read_argv( 1 , szName , charsmax( szName ) );
	
	remove_quotes( szName );
	
	new idTarget	=	find_player( "bjlh" , szName );
	
	if( !is_user_connected( idTarget ) ){
		client_print( id , print_console , "Nie znaleziono gracza" );
		return PLUGIN_HANDLED;
	}
	
	new szExp[ 64 ] , iExp ;
	read_argv( 2 , szExp , charsmax( szExp ) );
	
	remove_quotes( szExp );
	
	iExp	=	str_to_num( szExp );
	
	if( iExp < 0 )
	takeXp( idTarget , -iExp );
	else
	giveXp( idTarget , iExp );
	
	client_print( id , print_console , "Gracz %s dostal %i expa" , szName , iExp );	
	
	return PLUGIN_HANDLED;
}

public giveItem( id , level , cid ){
	if(!cmd_access(id,level, cid, 3)) 
	return PLUGIN_HANDLED; 
	
	new szName[ 64 ];
	read_argv( 1 , szName , charsmax( szName ) );
	
	remove_quotes( szName );
	
	new idTarget	=	find_player( "bjlh" , szName );
	
	if( !is_user_connected( idTarget ) ){
		client_print( id , print_console , "Nie znaleziono gracza" );
		return PLUGIN_HANDLED;
	}
	
	new szItem[ 64 ] , iItem ;
	read_argv( 2 , szItem , charsmax( szItem ) );
	
	remove_quotes( szItem );
	
	iItem	=	str_to_num( szItem );
	
	if ( giveUserItem( idTarget , iItem ) ){
		client_print( id , print_console , "Gracz %s dostal item" , szName );	
	}
	
	return PLUGIN_HANDLED;
}

public commandList( id ){
	new szMessage[ 1650 ] , iLen = 0;
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<ul>\
	<li>/klasy 				- 	otwiera liste klas</li>\
	<li>/klasa 				- 	otwiera menu klas do wyboru</li>\
	<li>/reset 				- 	resetuje rozdane punkty umiejetnosci</li>\
	<li>/drop  				- 	wyrzuca aktualnie posiadany przedmiot</li>\
	<li>/item  				- 	opis akutalnie posiadanego przedmiotu</li>\
	<li>/przedmiot  		- 	takie samo dzialanie jak /item</li>");
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<li>/gracze  			-  	lista graczy wraz z ich levelami i klasami</li>\
	<li>/czary				-  	twoje statystyki</li>\
	<li>/skille				-  	tak jak /czary </li>\
	<li>/rune 				-  	menu gdzie mozna kupic rozne rzeczy</li>\
	<li>/wymiana  			-  	wymiana itemami</li>\
	<li>/wymien				-	tak jak /wymiana</li>\
	<li>/daj				-	oddaj item za kase</li>" );
	
	iLen	+=	formatex( szMessage [ iLen ] , charsmax( szMessage ) - iLen , "<li>/pomoc  			-  	krotka notatka o modzie</li>\
	<li>/komendy  			-	ta lista</li>\
	<li>/exp				-	informacje o stanie twojego expa</li>\
	<li>/menu				-	menu moda</li>\
	<li>diablomod_version 	-	wersja diablomoda uzywana na serwerze</li>\
	</ul>");
	
	showMotd( id , "" , "" , -1 , -1 , "" , szMessage);
}

public helpMotd( id ){
	showMotd( id , "" , "" , -1 , -1 , "" , "Dostajesz przedmioty i doswiadczenie za zabijanie innych. Item mozesz dostac tylko wtedy, gdy nie masz na sobie innego<br>\
	Aby dowiedziec sie wiecej o swoim przedmiocie napisz /przedmiot lub /item, a jak chcesz wyrzucic napisz /drop<br>\
	Niektore przedmoty da sie uzyc za pomoca klawisza E<br\
	Napisz /czary zeby zobaczyc jakie masz staty" );
	
	return PLUGIN_HANDLED;
}

public wymianaItemami( id ){
	if( isPlayerItemNone( id ) ){
		ColorChat( id ,  GREEN ,"%s Nie posiadasz zadnego itemu!" , PREFIX_SAY);
		
		return PLUGIN_HANDLED;
	}
	
	new szName[ 64 ] , szItem[ MAX_LEN_NAME ] , szTmp [ MAX_LEN_NAME + 128 ] , szID [ 16 ];
	
	new pMenu = menu_create( "Wymiana itemami" , "wymianaItemamiHandle" );
	
	for( new i = 1 ; i <= MAX ; i++ ){
		if(  !is_user_connected( i ) || isPlayerItemNone( i ) || i == id )
		continue;
		
		get_user_name( i , szName , charsmax( szName ) );
		
		ArrayGetString( gItemName , getPlayerItem( i ) , szItem , charsmax( szItem ) );
		
		formatex( szTmp , charsmax( szTmp ) , "%s \r %s" , szName , szItem );
		
		num_to_str( i , szID , charsmax( szID ) );
		
		menu_additem( pMenu , szTmp , szID );
	}
	
	menu_setprop( pMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pMenu , MPROP_EXITNAME , "Wyjscie" );
	menu_setprop( pMenu , MPROP_NEXTNAME , "Dalej");
	
	menu_display( id , pMenu );
	
	return PLUGIN_HANDLED;
}

public wymianaItemamiHandle( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Tego gracza juz nie ma na serwerze" , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( isPlayerItemNone( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Ten gracz juz nie ma itemu", PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	if( isPlayerItemNone( id ) ){
		ColorChat( id , GREEN , "%s Nie masz itemu oszuscie " , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szTitle [ MAX_LEN_NAME + 128 ] , szItem [ MAX_LEN_NAME ] , szName [ 64 ] , szID [ 16 ];
	
	get_user_name( id , szName , charsmax( szName ) );
	
	ArrayGetString( gItemName , getPlayerItem( id ) , szItem , charsmax( szItem ) );
	
	formatex( szTitle , charsmax( szTitle ) , "\w%s chce wymienic sie z toba iteamami oferuje ci ^n\r %s ^n\w Zgadasz sie ?", szName , szItem );
	
	num_to_str( id , szID , charsmax( szID ) );
	
	new pMenu = menu_create( szTitle , "wymianaItemamiPotwierdzenie" );
	
	menu_additem( pMenu , "Tak" , szID)
	menu_additem( pMenu , "Nie" , szID)
	
	menu_setprop( pMenu , MPROP_EXIT , MEXIT_NEVER );
	
	#if defined BOTY
	if( is_user_bot( idTarget ) ){
		menu_destroy( menu );
		wymianaItemamiPotwierdzenie(idTarget , pMenu,  random_num( 0 , 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display( idTarget , pMenu );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public wymianaItemamiPotwierdzenie( id , menu , item ){
	if( item	==	MENU_EXIT || !is_user_connected( id ) ){
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new idTarget = str_to_num( data );
	
	if( item == 1 ){
		ColorChat( idTarget ,  GREEN ,"%s Gracz nie zgodzil sie na wymiane" , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( idTarget ) ){
		ColorChat( id , GREEN , "%s Tego gracza juz nie ma na serwerze" , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	if( !is_user_connected( idTarget ) || isPlayerItemNone( idTarget ) ){
		ColorChat( id ,  GREEN ,"%s Ten gracz juz nie ma itemu" , PREFIX_SAY);
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	if( !is_user_connected( id ) || isPlayerItemNone( id ) ){
		ColorChat( id ,  GREEN ,"%s Nie masz itemu oszuscie" , PREFIX_SAY );
		
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new szItem[ MAX_LEN_NAME ] , szItem2[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , getPlayerItem( id ) , szItem ,charsmax( szItem ) )
	ArrayGetString( gItemName , getPlayerItem( idTarget ) , szItem2 ,charsmax( szItem2 ) )
	
	ExecuteForwardIgnoreIntTwoParam( getForwardItem( getPlayerItem( id ) , ITEM_COPY )  , id , idTarget );
	
	ExecuteForwardIgnoreIntTwoParam( getForwardItem( getPlayerItem( idTarget ) , ITEM_COPY ) ,  idTarget , id );
	
	new iTmpItem = getPlayerItem( id ), 
		iTmpDur = playerInf[ id ][ itemDurability ];
	
	setPlayerItem( id , getPlayerItem( idTarget ) , playerInf[ idTarget ][ itemDurability ] );
	
	setPlayerItem( idTarget , iTmpItem , iTmpDur );
	
	ColorChat( id , GREEN , "%s Otrzymales %s" , PREFIX_SAY , szItem2 );
	ColorChat( idTarget ,  GREEN ,"%s Otrzymales %s" , PREFIX_SAY , szItem );
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public _create_modMenu(){
	pModMenu	=	menu_create( "Menu moda" , "modMenuHandle" );
	
	menu_additem( pModMenu , "Informacje o przedmiocie" );
	menu_additem( pModMenu , "Upusc obecny przedmiot" );
	menu_additem( pModMenu , "Pokaz pomoc" );
	menu_additem( pModMenu , "Uzyj mocy przedmiotu" );
	menu_additem( pModMenu , "Kup Rune" );
	menu_additem( pModMenu , "Informacje o statystykach" );
	menu_additem( pModMenu , "Informacje o twoim expie" );
	menu_additem( pModMenu , "Lista komend" );
	
	menu_setprop( pModMenu , MPROP_EXITNAME , "Wyjscie" )
	menu_setprop( pModMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pModMenu , MPROP_NEXTNAME , "Dalej" );
}

public modMenuHandle( id , menu , item ){
	if( item	==	MENU_EXIT ){
		return PLUGIN_CONTINUE;
	}
	
	switch( item ){
	case 0:{
			itemInfo( id );
		}
	case 1:{
			dropItem( id );
		}
	case 2:{
			helpMotd( id );
		}
	case 3:{
			new iRet = PLUGIN_CONTINUE;
			
			ExecuteForward( getForwardMulti( MULTI_CAN_USE_SKILL ) , iRet , id );
			
			if(is_user_alive(id) && !isPlayerClassNone( id ) && !bFreezeTime && Float:playerInf[id][castTime] == 0.0 && !isPlayerItemNone( id ) && iRet == PLUGIN_CONTINUE ) {

				ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_SKILL_USED ), id);
			}
		}
	case 4:{
			runeMenu( id );
			
			return PLUGIN_HANDLED;
		}
	case 5:{
			showSkills( id );
		}
	case 6:{
			expInf( id );
		}
	case 7:{
			commandList( id );
		}
	}
	
	menu_display( id , pModMenu );
	
	return PLUGIN_CONTINUE;
}

public modMenu( id ){
	menu_display( id , pModMenu );
	
	return PLUGIN_HANDLED;
}

public _create_runeMenu(){
	new szTmp[ 256 ];
	
	pRuneMenu	=	menu_create("Sklep z runami","runeMenuHandle");
	
	formatex( szTmp ,charsmax( szTmp ) , "\yUpgrade \d[Ulepszenie Przedmiotu] - \r%d$^n\d Uwaga nie kazdy item sie da ulepszyc ^n Slabe itemy latwo ulepszyc ^n Mocne itemy moga ulec uszkodzeniu" , get_pcvar_num( pCvarUpgradePrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	formatex( szTmp ,charsmax( szTmp ) , "\yLosowanie przedmiotu \d[Dostajesz losowy przedmiot] \r%d$" , get_pcvar_num( pCvarRandomPrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	formatex( szTmp ,charsmax( szTmp ) , "\yExp \d[Dostajesz doswiadczenia] \r%d$" , get_pcvar_num( pCvarExpPrice ) )
	menu_additem( pRuneMenu , szTmp )
	
	menu_setprop( pRuneMenu , MPROP_EXITNAME , "Wyjscie" )
	
}

public runeMenu ( id ){
	menu_display( id , pRuneMenu );
	
	return PLUGIN_HANDLED;
}

public runeMenuHandle ( id , menu , item ){
	if( item == MENU_EXIT ){
		return PLUGIN_HANDLED;
	}
	
	switch( item ){
	case 0:{
			if( isPlayerItemNone( id )){
				ColorChat( id , GREEN , "%s Nie posiadasz zadnego itemu !" , PREFIX_SAY);
			}
			else{
				if( !UTIL_BuyForMoney( id , get_pcvar_num( pCvarUpgradePrice ) ) ){
					ColorChat( id ,  GREEN ,"%s Masz za malo kasy potrzebujesz %d$" , PREFIX_SAY , get_pcvar_num( pCvarUpgradePrice ) );
				}
				else{
					playerInf[ id ][ itemDurability ]  += random_num(-50,50);
					
					if( !checkItemDurability( id ) ){
						return PLUGIN_HANDLED;
					}
					
					ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem(  id ) , ITEM_UPGRADE_ITEM ) , id );
				}
			}
		}
	case 1:{
			if( !isPlayerItemNone( id ) ){
				ColorChat( id , GREEN , "%s Juz posiadasz item !",PREFIX_SAY);
			}
			else{
				if( !UTIL_BuyForMoney( id , get_pcvar_num( pCvarRandomPrice ) ) ){
					ColorChat( id , GREEN , "%s Masz za malo kasy potrzebujesz %d$" , PREFIX_SAY, get_pcvar_num( pCvarRandomPrice ) );
				}
				else{
					giveUserItem( id );
				}
			}
		}
	case 2:{
			if( !UTIL_BuyForMoney( id , get_pcvar_num( pCvarExpPrice ) ) ){
				ColorChat( id ,  GREEN ,"%s Masz za malo kasy potrzebujesz %d$" , PREFIX_SAY , get_pcvar_num( pCvarExpPrice ) );
			}
			else{
				new iExp = get_pcvar_num( pCvarXPBonus ) * random_num( 3,10 ) + playerInf[ id ][ currentLevel ] * get_pcvar_num( pCvarXPBonus )/20
				giveXp( id , iExp );
				ColorChat( id ,  GREEN ,"%s Otrzymales %d Expa !", PREFIX_SAY , iExp )
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public bool:UTIL_BuyForMoney ( id , iIle ){
	if( cs_get_user_money( id ) >= iIle ){
		
		cs_set_user_money( id , cs_get_user_money( id ) - iIle );
		
		return true;
	}
	
	return false;
}

public showVersion( id ){
	new szVersion[ 64 ];
	
	get_pcvar_string( pCvarVersion , szVersion , charsmax( szVersion ) )
	
	client_print( id , print_console , szVersion )
	
	return PLUGIN_HANDLED;
}

public playersList(id)
{
	static motd[1000],header[100],szName[64],szClass[ MAX_LEN_NAME ] ,len = 0,i
	new team[32]
	new players[32], numplayers
	new playerid
	
	get_players(players, numplayers, "a")
	
	len += formatex(motd[len],sizeof motd - 1 - len,"<body bgcolor=#000000 text=#FFB000>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<center><table width=700 border=1 cellpadding=4 cellspacing=4>")
	len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>Name</td><td>Klasa</td><td>Level</td><td>Team</td></tr>")
	
	formatex(header,sizeof header - 1,"Diablo Mod Statystyki")
	
	for (i = 0; i< numplayers; i++)
	{
		playerid = players[i]
		if ( get_user_team(playerid) == 1 ) team = "Terrorist"
		else if ( get_user_team(playerid) == 2 ) team = "CT"
		else team = "Spectator"
		get_user_name( playerid, szName, charsmax( szName ) )
		
		ArrayGetString( gClassNames , getPlayerClass( playerid ) , szClass , charsmax( szClass ) )
		
		len += formatex(motd[len],sizeof motd - 1 - len,"<tr><td>%s</td><td>%s</td><td>%d</td><td>%s</td></tr>",szName,szClass, playerInf[playerid][currentLevel],team)
	}
	len += formatex(motd[len],sizeof motd - 1 - len,"</table></center>")
	
	show_motd(id,motd,header)     
}

public showSkills( id ){
	new SkillsInfo[768]
	formatex( SkillsInfo, charsmax( SkillsInfo ) ,"Masz %i sily - co daje ci %i zycia<br>Masz %i zwinnosci - co daje ci szybsze bieganie o %i punkow i redukuje sile atakow magia %i%%<br>Masz %i zrecznosci - Redukuje obrazenia z normalnych atkow %0.1f%%<br>Masz %i inteligencji - to daje im wieksza moc przedmiotom ktorych da sie uzyc<br>Masz na starcie %i armora <br>Przy kazdym zabiciu dostajesz dodatkowo %i$",
	playerInf[ id ][ currentStr ],
	playerInf[ id ][ currentStr ] * get_pcvar_num( pCvarStrPower ),
	playerInf[ id ][ currentDex ],
	floatround(getUserDex( id ) * 1.3),
	playerInf[ id ][ currentDex ],
	playerInf[ id ][ currentAgi ],
Float:playerInf[ id ][ dmgReduce ] * 100.0,
	playerInf[ id ][ currentInt ] ,
	playerInf[id][currentArmor] * 2 ,	
	playerInf[id][currentLuck] * 10 );
	
	showMotd( id , "Skille" , "" , -1 , -1 , "" , SkillsInfo )
}

public itemsMenu( id ){
	new pMenu = menu_create("Lista itemow","itemsMenuHandle");
	new szTmp[ MAX_LEN_NAME ]
	
	for( new i = 1 ; i < ArraySize( gItemName ) ; i++ ){
		ArrayGetString( gItemName , i , szTmp , charsmax( szTmp ) );
		
		menu_additem( pMenu , szTmp );
	}
	
	menu_setprop( pMenu , MPROP_NUMBER_COLOR , "\r" );
	menu_setprop( pMenu , MPROP_BACKNAME , "Wroc" );
	menu_setprop( pMenu , MPROP_NEXTNAME , "Dalej" );
	menu_setprop( pMenu , MPROP_EXITNAME , "Wyjscie");
	
	menu_display( id , pMenu );
}

public itemsMenuHandle ( id , menu , item ){
	if( item == MENU_EXIT ){
		menu_destroy( menu );
		
		return PLUGIN_HANDLED;
	}
	
	new szMessage[ 256 ];
	
	ArrayGetString( gItemName , item + 1 , szMessage , charsmax( szMessage ) );
	
	ColorChat( id ,  GREEN ,"%s Item : %s" , PREFIX_SAY , szMessage );
	
	new iRet;
	
	new iArrayPass = PrepareArray(szMessage,256,1)
	
	ExecuteForward( getForwardItem( item + 1 , ITEM_INFO ), iRet, id , iArrayPass,charsmax( szMessage ) , true);
	
	ColorChat( id , GREEN , "%s Opis : %s",PREFIX_SAY , szMessage )
	
	menu_display( id , menu , item / 7 );
	
	return PLUGIN_CONTINUE;
}

public itemInfo( id ){
	if( !isPlayerItemNone( id ) ){
		showMotd( id , "Zabij kogos, aby dostac item albo kup (/rune)" , "Zabij kogos, aby dostac item albo kup (/rune)" );
	}
	else{
		new iRet , szMessage[ 256 ];
		
		new iArrayPass = PrepareArray(szMessage,256,1)
		
		ExecuteForward( getForwardItem( getPlayerItem( id ) , ITEM_INFO ) , iRet, id , iArrayPass,charsmax( szMessage ) , false);
		
		new szItem[ MAX_LEN_NAME ];
		
		ArrayGetString( gItemName , getPlayerItem( id ) , szItem , MAX_LEN_NAME - 1 );
		
		showMotd( id , szItem , szItem , -1 , playerInf[id][itemDurability] , "" , szMessage );
	}
	
	return PLUGIN_HANDLED;
}

public dropItem( id ){
	if( !isPlayerItemNone( id ) ){
		set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 ) 	
		show_hudmessage(id, "Nie masz przedmiotu do wyrzucenia!")
	}
	else{
		set_hudmessage(100, 200, 55, -1.0, 0.40, 0, 3.0, 2.0, 0.2, 0.3, 5)
		show_hudmessage(id, "Przedmiot wyrzucony")
		
		ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_DROP ) , id );
		
		setPlayerItem( id , 0 );
	}
	
	return PLUGIN_HANDLED;
}

public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id) || !get_pcvar_num(pCvarPrefixy) || ( get_user_team( id ) != 1 && get_user_team( id ) != 2 ))      return PLUGIN_CONTINUE;
	
	new szTmp[ 196 ],szTmp2[ 196 ],szTmp3[ 196 ];
	get_msg_arg_string(2,szTmp, charsmax( szTmp ) )
	
	new szPrefix[64]
	
	switch(get_pcvar_num(pCvarPrefixy)){
	case 1:{
			ArrayGetString(gClassNames,getPlayerClass( id ),szTmp3,charsmax( szTmp3 ) )
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s]",szTmp3);
		}
	case 2:{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%d]",playerInf[id][currentLevel]);
		}
	case 3:{
			ArrayGetString(gClassNames,getPlayerClass( id ),szTmp3,charsmax( szTmp3 ) )
			formatex(szPrefix,charsmax( szPrefix ),"^x04[%s - %d]",szTmp3,playerInf[id][currentLevel]);
		}
	}
	
	if(!equal(szTmp,"#Cstrike_Chat_All")){
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2)," ");
		add(szTmp2,charsmax(szTmp2),szTmp);
	}
	else{
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2,szTmp2);
	
	return PLUGIN_CONTINUE;
}

public msgHealth(iMsgtype, iMsgid, id){
	if(get_msg_arg_int(1) >= 0xFF){
		
		set_hudmessage(255, 212, 0, 0.01, 0.88, 0, 6.0, 5.0)
		show_hudmessage(id, "Zycie: %d", get_msg_arg_int(1))
		
		set_msg_arg_int(1, get_msg_argtype(1), 0xFF);
	}
}

public newRound()
{
	remove_entity_name(CLASS_NAME_CORSPE);
	remove_entity_name(THROW_KNIFE_CLASS);
	
	remove_entity_name( XBOW_ARROW );
	
	for(new i = 1; i <= MAX ; i++){
		if(!is_user_connected(i) || isPlayerClassNone( i ) )continue;
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( i ) , CLASS_CLEAN_DATA ) , i );
	}

	ExecuteForwardIgnoreIntNoParam( getForwardMulti( MULTI_NEW_ROUND ) );
}

public showKlasy(id){
	showKlasy2(id);
}

showKlasy2(id,page = 0){
	new pMenu,szTmp[MAX_LEN_NAME];
	
	pMenu = menu_create("Info klas","showKlasyHandle");
	
	for(new i = 1; i < ArraySize( gClassNames ) ; i++){
		ArrayGetString(gClassNames,i,szTmp,charsmax( szTmp ));
		menu_additem(pMenu,szTmp);
	}
	
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\r");
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc");
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie");
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej");
	
	menu_display(id,pMenu,page)
}

public showKlasyHandle(id,menu,item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	new szTitle[128],szClass[MAX_LEN_NAME],szDesc[MAX_LEN_DESC];
	
	ArrayGetString(gClassNames,item + 1 , szClass , charsmax( szClass ));
	ArrayGetString(gClassDesc, item + 1 , szDesc  , charsmax( szDesc ));
	
	formatex( szTitle, charsmax( szTitle ),"Informacje o klasie %s",szClass);
	
	showMotd(id,szTitle,.szDesc = szDesc );
	
	menu_destroy(menu);
	showKlasy2(id,item/7);
	
	return PLUGIN_CONTINUE;
}

public bomb_planted(iPlanter){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 1)	continue;
		
		ColorChat(i, GREEN ,"%s Dostales *%i* doswiadczenia za polozenie bomby przez twoj team",PREFIX_SAY , iBonus)
		giveXp(i,iBonus)
	}
}


public bomb_defused(iDefuse){
	new iBonus = get_pcvar_num(pCvarXPBonus2);
	
	for( new i = 1; i < MAX + 1; i++ ){
		if(!is_user_alive(i) || get_user_team(i) != 2)	continue;
		
		ColorChat(i, GREEN , "%s Dostales *%i* doswiadczenia za rozbrojenie bomby przez twoj team",PREFIX_SAY,iBonus)
		giveXp(i,iBonus)
	}
}

public awardHostage()
{
	new id = get_loguser_index()
	
	if (is_user_connected(id))	giveXp(id,get_pcvar_num(pCvarXPBonus2)/4)	
}

stock get_loguser_index()
{
	new loguser[80], szName[64]
	read_logargv(0, loguser, charsmax( loguser ))
	parse_loguser(loguser, szName, charsmax( szName ))
	
	return get_user_index(szName)
}

public hostKilled(id)
{
	set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 ) 	
	show_hudmessage(id, "Straciles doswiadczenie za zabicie zakladnika")
	
	takeXp(id,get_pcvar_num(pCvarXPBonus2)/4)
}

public eventDamage(id){
	static playerDamage[33];
	
	new iKiller = get_user_attacker(id);
	
	if(!is_user_alive(iKiller) || !is_user_alive(id) || iKiller == id || get_user_team(iKiller) == get_user_team(id))	return PLUGIN_CONTINUE;
	
	new iDamage	=	read_data(2);
	
	playerDamage[iKiller]	+=	iDamage;
	
	new iExp = 0,expDamage = get_pcvar_num(pCvarDamage);
	
	while(playerDamage[iKiller] >= expDamage)
	{
		playerDamage[iKiller] -= expDamage;
		iExp++
	}
	
	static iRet;
	
	if(iExp > 0){

		ExecuteForward( getForwardMulti( MULTI_EXP_DAMAGE ), iRet, iKiller ,iExp);
		
		if(iRet != 0)	iExp	=	iRet;
		
		if(iRet >= 0){
			giveXp(iKiller,iExp)
		}
		else{
			takeXp(iKiller,iExp)
		}
	}

	ExecuteForward( getForwardMulti( MULTI_DAMAGE_TAKEN_POST ) , iRet, iKiller,id,iDamage);
	
	return PLUGIN_CONTINUE;
}

public fwDamage(iVictim, idinflictor, iAttacker, Float:fDamage, damagebits)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim))	return HAM_IGNORED;
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "fwDamage Started" )
	#endif
	
	new pFunc;
	
	new iRet = PLUGIN_CONTINUE;
	
	ExecuteForward( getForwardMulti( MULTI_HAS_ADDITIONAL_DAMAGE ) , iRet );
	
	if( iRet == PLUGIN_CONTINUE ){
		
		if( !isPlayerClassNone( iVictim ) ){
			fDamage = fDamage - ( fDamage * Float:playerInf[iVictim][dmgReduce] );
			
			pFunc = getForwardClass( getPlayerClass( iVictim ) , CLASS_DAMAGE_TAKEN );
			
			if(pFunc != -1){
				callfunc_begin_i(pFunc,ArrayGetCell(gClassPlugins, getPlayerClass( iVictim ) ) )
				callfunc_push_int(iVictim);
				callfunc_push_int(iAttacker);
				callfunc_push_floatrf(fDamage);
				callfunc_push_int(damagebits);
				callfunc_end();
			}
		}
		
		if( !isPlayerClassNone( iAttacker ) ){
			pFunc = getForwardClass( getPlayerClass( iAttacker ) , CLASS_DAMAGE_DO );
			
			if(pFunc != -1){
				callfunc_begin_i(pFunc,ArrayGetCell(gClassPlugins, getPlayerClass( iAttacker ) ))
				callfunc_push_int(iVictim);
				callfunc_push_int(iAttacker);
				callfunc_push_floatrf(fDamage);
				callfunc_push_int(damagebits);
				callfunc_end();
			}
		}
		
		if( !isPlayerItemNone( iVictim ) ){
			pFunc =	getForwardItem( getPlayerItem( iVictim ) , ITEM_DAMAGE_TAKEN );
			
			if(pFunc != -1){
				callfunc_begin_i(pFunc,ArrayGetCell(gItemPlugin, getPlayerItem( iVictim ) ))
				callfunc_push_int(iVictim);
				callfunc_push_int(iAttacker);
				callfunc_push_floatrf(fDamage);
				callfunc_push_int(damagebits);
				callfunc_end();
			}
		}
		
		if( !isPlayerItemNone( iAttacker ) ){
			pFunc =	getForwardItem( getPlayerItem( iAttacker ) , ITEM_DAMAGE_DO );
			
			if(pFunc != -1){
				callfunc_begin_i(pFunc,ArrayGetCell(gItemPlugin, getPlayerItem( iAttacker ) ))
				callfunc_push_int(iVictim);
				callfunc_push_int(iAttacker);
				callfunc_push_floatrf(fDamage);
				callfunc_push_int(damagebits);
				callfunc_end();
			}
		}
	}
	
	new tempArray[ 1 ];
	tempArray[ 0 ]	=	_:fDamage;
	
	new pArray	=	PrepareArray( tempArray , 1 , 1);
	
	ExecuteForward( getForwardMulti( MULTI_DAMAGE_TAKEN_PRE ), iRet, iAttacker,iVictim,pArray);
	
	if(fDamage < 0.0){
		fDamage = 0.0;
	}
	
	SetHamParamFloat(4,fDamage );
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "fwDamage End" )
	#endif
	
	return HAM_HANDLED;
}

public client_PostThink(id){
	if( isPlayerClassNone( id ) || is_user_bot(id) || !is_user_alive(id)){
		return ;
	}
	
	ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_POST_THINK ), id );
}

public client_PreThink(id){
	if( isPlayerClassNone( id ) || is_user_bot( id ) ){
		return PLUGIN_CONTINUE;
	}
	
	if( Float:playerInf[id][castTime] <= get_gametime() && Float:playerInf[id][castTime] != 0.0 && is_user_alive(id)){
		
		playerInf[id][castTime]		=	_:0.0;
		
		makeBarTimer( id , 0 );
		
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		

		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_CALL_CAST ) , id );
	}
	
	else if( Float:playerInf[id][castTime] > 0.0 && (!is_user_alive(id) || get_user_button(id) & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) || get_user_weapon(id) != CSW_KNIFE || !(get_entity_flags(id) & FL_ONGROUND) || bFreezeTime) || bow[id]){
		new iRet;
		
		ExecuteForward( getForwardClass( getPlayerClass( id ) , CLASS_CAST_STOP ) ,iRet,id);
		
		if(iRet != DIABLO_STOP){
			playerInf[id][castTime]		=	_:0.0;
			
			makeBarTimer( id , 0 );
		}
	}
	
	else if(Float:playerInf[id][castTime] == 0.0 && is_user_alive(id) && get_user_weapon(id) == CSW_KNIFE && get_entity_flags(id) & FL_ONGROUND && !bFreezeTime && !bow[id]){
		new iRet,bool:bBreak = false;
		
		if(get_user_button(id) & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)){
			
			ExecuteForward( getForwardClass( getPlayerClass( id ) , CLASS_CAST_MOVE ) ,iRet,id);
			
			if(iRet == DIABLO_STOP || iRet == 0){
				bBreak = true;
			}
		}
		
		if(!bBreak){
			iRet	=	_:0.0;
			
			ExecuteForward( getForwardClass( getPlayerClass( id ) , CLASS_CAST_TIME ) ,iRet,id,5.0-(float(getUserInt( id ))/30.0));
			
			if(Float:iRet != 0.0){
				
				makeBarTimer( id , floatround(Float:iRet,floatround_ceil) );
				
				playerInf[id][castTime]	= _:(get_gametime() + Float:iRet);
			}
		}
	}
	
	if(g_GrenadeTrap[id] && get_user_button(id) & IN_ATTACK2)
	{
		switch(get_user_weapon(id))
		{
		case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE:
			{
				if((g_PreThinkDelay[id] + 0.28) < get_gametime())
				{
					switch(g_TrapMode[id])
					{
					case 0: g_TrapMode[id] = true;
					case 1: g_TrapMode[id] = false;
					}
					client_print(id, print_center, "Grenade Trap %s", g_TrapMode[id] ? "[ON]" : "[OFF]")
					g_PreThinkDelay[id] = get_gametime()
				}
			}
		default: g_TrapMode[id] = false
		}
	}
	
	if(bHasBow[id]){
		new button2 = get_user_button(id);
		
		if (get_user_button(id) & IN_RELOAD && !(get_user_oldbutton(id) & IN_RELOAD) && get_user_weapon(id) == CSW_KNIFE && !bow[id]){
			bow[id] = true;
			commandBow(id)
		}
		else if (get_user_button(id) & IN_RELOAD && !(get_user_oldbutton(id) & IN_RELOAD) && get_user_weapon(id) == CSW_KNIFE && bow[id]){
			bow[id] = false;
			entity_set_string(id, EV_SZ_viewmodel, KNIFE_VIEW)  
			entity_set_string(id, EV_SZ_weaponmodel, KNIFE_PLAYER)  
		}
		
		if(bow[id]){
			if( bowdelay[id] < get_gametime() && button2 & IN_ATTACK)
			{
				bowdelay[id] = get_gametime() + ( 4.25 - floatmin( 4.25 , float( getUserInt( id ) ) / 26.0 ) );
				command_arrow(id) 
			}
			entity_set_int(id, EV_INT_button, (button2 & ~IN_ATTACK) & ~IN_ATTACK2)
		}
	}
	
	new szClass[MAX_LEN_NAME];
	
	ArrayGetString(gClassNames, getPlayerClass( id ) ,szClass,charsmax ( szClass ));
	
	if( pev(id,pev_button) & IN_RELOAD && is_user_alive(id) && !bFreezeTime && playerInf[id][maxKnife] > 0 && (equal(szClass,"Ninja") || get_user_weapon(id) == CSW_KNIFE))	commandKnife(id);

	if(is_user_alive(id)){
		
		if( !isPlayerClassNone( id ) ){
			ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_PRE_THINK ) ,id);
		}
		
		if( !isPlayerItemNone( id ) ){
			
			ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_PRE_THINK ) ,id);
		}
		
		if( !isPlayerClassNone( id ) && !bFreezeTime && Float:playerInf[id][castTime] == 0.0 && pev(id,pev_button) & IN_USE && !( pev( id , pev_oldbuttons ) & IN_USE ) ){
			
			new Float:origin[3]
			pev(id, pev_origin, origin)
			
			//Func door and func door rotating
			new aimid, body
			get_user_aiming ( id, aimid, body ) 
			
			if (aimid > 0)
			{
				new classname[32]
				pev(aimid,pev_classname,classname,31)
				
				if (equal(classname,"func_door_rotating") || equal(classname,"func_door") || equal(classname,"func_button"))
				{
					new Float:doororigin[3]
					pev(aimid, pev_origin, doororigin)
					
					if (get_distance_f(origin, doororigin) < 70 && UTIL_In_FOV(id,aimid))
					return PLUGIN_CONTINUE
				}
				
			}
			
			//Bomb condition
			new bomb
			if ((bomb = find_ent_by_model(-1, "grenade", "models/w_c4.mdl"))) 
			{
				new Float:bombpos[3]
				pev(bomb, pev_origin, bombpos)
				
				//We are near the bomb and have it in FOV.
				if (get_distance_f(origin, bombpos) < 100 && UTIL_In_FOV(id,bomb))
				return PLUGIN_CONTINUE
			}
			
			
			//Hostage
			new hostage = engfunc(EngFunc_FindEntityByString, -1,"classname", "hostage_entity")
			
			while (hostage)
			{
				new Float:hospos[3]
				pev(hostage, pev_origin, hospos)
				if (get_distance_f(origin, hospos) < 70 && UTIL_In_FOV(id,hostage))
				return PLUGIN_CONTINUE
				
				hostage = engfunc(EngFunc_FindEntityByString, hostage,"classname", "hostage_entity")
			}
			
			
			ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SKILL_USED ) , id);
			
			new iRet = PLUGIN_CONTINUE;
			
			ExecuteForward( getForwardMulti( MULTI_CAN_USE_SKILL ) , iRet , id );
			
			if( !isPlayerItemNone( id ) && iRet == PLUGIN_CONTINUE){
				ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_SKILL_USED ), id);
			}
		}
	}
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MUTLI_CLIENT_PRE_THINK ) , id);
	
	return PLUGIN_CONTINUE;
}

public command_arrow( id ){

	if( !is_user_alive( id ) ){
		return PLUGIN_HANDLED;
	}
	
	new Float: Origin[3], 
		Float: fVelocity[3], 
		Float: vAngle[3], 
		iEnt;
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	iEnt = create_entity("info_target")
	
	if ( !pev_valid( iEnt ) ){
		return PLUGIN_HANDLED;
	}
	
	new Float:fDmg = get_pcvar_float(pCvarArrow) + getUserInt( id ) * get_pcvar_float(pCvarMulti);
	
	entity_set_string( iEnt, EV_SZ_classname, "xbow_arrow")
	
	vAngle[0]*= -1
	Origin[2]+=10
	
	entity_set_origin( iEnt, Origin)
	entity_set_vector( iEnt, EV_VEC_angles, vAngle)
	
	entity_set_int( iEnt, EV_INT_effects, EF_MUZZLEFLASH );
	entity_set_int( iEnt, EV_INT_solid, SOLID_TRIGGER );
	entity_set_int( iEnt, EV_INT_movetype, MOVETYPE_FLY );
	
	entity_set_edict( iEnt, EV_ENT_owner, id )
	entity_set_edict( iEnt, EV_ENT_enemy, 0);
	
	entity_set_float( iEnt, EV_FL_dmg, fDmg );
	
	entity_set_model( iEnt, cbow_bolt);
	entity_set_size( iEnt, Float:{-2.5, -7.0, -2.0}, Float:{2.5, 7.0, 2.0});
	
	velocity_by_aim( id, get_pcvar_num( pCvarSpeed ) , fVelocity );

	entity_set_vector( iEnt, EV_VEC_velocity, fVelocity );

	set_rendering( iEnt , kRenderFxGlowShell, 255 , 0 , 0 , kRenderNormal, 56);
	
	return PLUGIN_HANDLED
}

public commandBow(id) 
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	if(bow[id]){
		entity_set_string(id,EV_SZ_viewmodel,cbow_VIEW)
		entity_set_string(id,EV_SZ_weaponmodel,cvow_PLAYER)
	}
	
	return PLUGIN_CONTINUE
}

public touchArrow( arrow , id ){
	
	if( !is_valid_ent( arrow ) ){
		return PLUGIN_CONTINUE;
	}
	
	new classname[ 64 ];
	
	if(is_valid_ent( id  )) {
		if( entity_get_int(id, EV_INT_solid) == SOLID_TRIGGER ){
			return PLUGIN_CONTINUE;
		}

		entity_get_string(id, EV_SZ_classname, classname, charsmax( classname ) );
	}
	
	if( is_user_alive( id ) ) {
		new kid = entity_get_edict( arrow, EV_ENT_owner );
		new lid = entity_get_edict( arrow, EV_ENT_enemy );
		
		if(kid == id || lid == id ){
			return PLUGIN_CONTINUE;
		}
		
		if( !get_pcvar_num( pCvarFriendlyFire ) && cs_get_user_team( id ) == cs_get_user_team( kid ) ){
			return PLUGIN_CONTINUE;
		}
		
		entity_set_edict( arrow, EV_ENT_enemy,id );
		
		new Float: fDmg = entity_get_float( arrow,EV_FL_dmg );
		
		bloodEffect(id,248)
		
		doDamage( id , kid , fDmg  * ( 1.0 - ( float( getUserDex( id ) ) / 100.0 ) ) , diabloDamageKnife );
		
		screenShake( id , 7<<14 , 1<<13 , 1<<14 )	
		
		emit_sound(id, CHAN_ITEM, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		fDmg = ( fDmg - 5.0 )*0.75;
		
		if( fDmg < 30.0 ) {
			remove_entity( arrow );
			return PLUGIN_CONTINUE;
		}
		
		entity_set_float(arrow, EV_FL_dmg, fDmg );
	}
	else if(equal(classname, "func_breakable")) {
		touchArrowBreakAble( arrow , id );
	}
	else if( !equal(classname, XBOW_ARROW ) ) {
		remove_entity( arrow );
	}
	
	return PLUGIN_CONTINUE;
}

public touchArrowBreakAbleWrap( iBreakAble , iEnt ){
	return touchArrowBreakAble( iEnt , iBreakAble );
}

public touchArrowBreakAble( iEnt , iBreakAble ){
	if( !pev_valid( iEnt ) ){
		return PLUGIN_CONTINUE;
	}
	
	if( pev(iBreakAble,pev_takedamage) && pev(iBreakAble, pev_health)){
		
		new Float: b_hp = entity_get_float(iBreakAble,EV_FL_health)
		
		if(b_hp > entity_get_float(iEnt , EV_FL_dmg )) entity_set_float(iBreakAble,EV_FL_health,b_hp - entity_get_float(iEnt , EV_FL_dmg ))
		else dllfunc(DLLFunc_Use,iBreakAble,iEnt)
		
	}
	
	remove_entity( iEnt );
	
	return PLUGIN_CONTINUE;
}

stock Float:player_speed(index) 
{
	new Float:vec[3]
	
	pev(index,pev_velocity,vec)
	vec[2]=0.0
	
	return floatsqroot ( vec[0]*vec[0]+vec[1]*vec[1] )
}

public grenade_throw(id, ent, wID)
{	
	if(!g_TrapMode[id] || !is_valid_ent( ent ) ){
		return PLUGIN_CONTINUE;
	}
	
	new Float:fVelocity[3]
	VelocityByAim(id, cvar_throw_vel, fVelocity)
	entity_set_vector(ent, EV_VEC_velocity, fVelocity)
	
	new Float: angle[3]
	entity_get_vector(ent,EV_VEC_angles,angle)
	angle[0]=0.00
	entity_set_vector(ent,EV_VEC_angles,angle)
	
	entity_set_float(ent,EV_FL_dmgtime,get_gametime()+3.5)
	
	entity_set_int(ent, NADE_PAUSE, 0)
	entity_set_int(ent, NADE_ACTIVE, 0)
	entity_set_int(ent, NADE_VELOCITY, 0)
	entity_set_int(ent, NADE_TEAM, get_user_team(id))
	
	RegisterHamFromEntity( Ham_Think , ent , "fwGrenadeThink" , 0 );
	
	set_task(3.0, "task_ActivateTrap", ent )
	
	return PLUGIN_CONTINUE
}

public task_ActivateTrap( ent ){
	if( !is_valid_ent( ent ) ){
		return PLUGIN_CONTINUE;
	}
	
	entity_set_int(ent, NADE_PAUSE, 1)
	entity_set_int(ent, NADE_ACTIVE, 1)
	
	new Float:fOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, fOrigin)
	//fOrigin[2] -= 8.1*(1.0-floatpower( 2.7182, -0.06798*float(getUserAgi( entity_get_edict(ent,EV_ENT_owner) ))))
	entity_set_vector(ent, EV_VEC_origin, fOrigin)
	
	return PLUGIN_CONTINUE
}

public fwGrenadeThink( ent ){
	if( !pev_valid( ent ) ){
		return HAM_IGNORED;
	}
	
	
	if( entity_get_int(ent, NADE_ACTIVE ) ){
		
		new Players[32], iNum
		get_players(Players, iNum, "a")
		
		for(new i = 0; i < iNum; ++i){
			new id = Players[i];
			
			if(entity_get_int(ent, NADE_TEAM) == get_user_team(id)){ 
				continue;
			}
			
			if(get_entity_distance(id, ent) > cvar_activate_dis || player_speed(id) <200.0){
				continue;
			}
			
			if(entity_get_int(ent, NADE_VELOCITY)) continue
			
			new Float:fOrigin[3]
			entity_get_vector(ent, EV_VEC_origin, fOrigin)
			
			while(PointContents(fOrigin) == CONTENTS_SOLID)
				fOrigin[2] += 100.0
			
			entity_set_vector(ent, EV_VEC_origin, fOrigin)
			drop_to_floor(ent)
			
			new Float:fVelocity[3]
			entity_get_vector(ent, EV_VEC_velocity, fVelocity)
			fVelocity[2] += float(cvar_nade_vel)
			entity_set_vector(ent, EV_VEC_velocity, fVelocity)
			entity_set_int(ent, NADE_VELOCITY, 1)
			
			entity_set_float( ent , EV_FL_nextthink, halflife_time() + cvar_explode_delay)
			entity_set_int( ent , NADE_PAUSE, 0);
			
			return HAM_IGNORED;
		}
	}
	else if( !entity_get_int( ent , NADE_PAUSE ) ){
		return HAM_IGNORED;
	}
	
	entity_set_float( ent , EV_FL_nextthink, halflife_time() + 0.01 );
	
	return HAM_IGNORED;
}

public sqlStart(){
	
	new szHost[64],szUser[64],szPass[64],szDb[64];
	
	get_pcvar_string(pSqlCvars[eHost],szHost,charsmax( szHost ) );
	get_pcvar_string(pSqlCvars[eUser],szUser,charsmax( szUser ) );
	get_pcvar_string(pSqlCvars[ePass],szPass,charsmax( szPass ) );
	get_pcvar_string(pSqlCvars[eDb],szDb,charsmax( szDb ) );
	
	gTuple = SQL_MakeDbTuple(szHost,szUser,szPass,szDb);
	
	new szCommand[1024],iLen = 0;
	
	iLen += formatex(szCommand,charsmax( szCommand ),"CREATE TABLE IF NOT EXISTS %s (`ip` VARCHAR ( 64 ) , `sid` VARCHAR (64) , `nick` VARCHAR( 64 ) , `klasa` VARCHAR(64) , `lvl` INT(10) NOT NULL DEFAULT  '1', `exp` INT(10) NOT NULL DEFAULT  '0' ,`str` INT(10) NOT NULL DEFAULT  '0' , ",SQL_TABLE)
	iLen += formatex(szCommand[ iLen ],charsmax( szCommand ) - iLen,"`int` INT(10) NOT NULL DEFAULT  '0' , `dex` INT(10) NOT NULL DEFAULT  '0' , `agi` INT(10) NOT NULL DEFAULT  '0' , `armor` INT(10) NOT NULL DEFAULT  '0' , `luck` INT(10) NOT NULL DEFAULT  '0' , `points` INT(10) NOT NULL DEFAULT  '0' , `modified` DATETIME)" );
	
	if(get_pcvar_num(pCvarAVG))	formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"; SELECT `klasa`,AVG(`lvl`) AS `AVG` FROM `%s` GROUP BY `klasa`",SQL_TABLE)
	
	SQL_ThreadQuery(gTuple,"sqlStartHandle",szCommand)
}

public sqlStartHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		logDiablo( "sqlStartHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		logDiablo( "sqlStartHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		logDiablo( "sqlStartHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	if(SQL_MoreResults(Query) && get_pcvar_num(pCvarAVG)){
		while(SQL_MoreResults(Query)){
			new szClass[MAX_LEN_NAME],szTmp[MAX_LEN_NAME];
			
			SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"klasa"),szClass,charsmax( szClass ) );
			
			new iFind = -1;
			
			for(new i = 0;i < ArraySize( gClassNames ); i++){
				ArrayGetString(gClassNames,i,szTmp,charsmax( szTmp ) );
				
				replace_all(szTmp,charsmax( szTmp )," ","_");
				replace_all(szTmp,charsmax( szTmp ),"'","Q");
				replace_all(szTmp,charsmax( szTmp ),"`","Q");
				
				if(equal(szTmp,szClass)){
					iFind = i;
					break;
				}
			}
			
			if(iFind != -1){
				ArraySetCell(gClassAvg,iFind,SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"AVG")));
			}
			
			SQL_NextRow(Query);
		}
	}
	
	bSql = true;
	
	return PLUGIN_CONTINUE
}

public checkSQL(id){
	if(!bSql || sqlPlayer[ id ] )	return PLUGIN_CONTINUE;
	
	new szCommand[512],szTmp[64],iLen = 0;
	
	iLen += formatex(szCommand,charsmax( szCommand ),"SELECT * FROM %s WHERE ",SQL_TABLE);
	
	get_user_authid(id,szTmp,charsmax(szTmp));
	
	switch(get_pcvar_num(pCvarSaveType)){
	case 1:{	
			formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`nick` = '%s'",playerInf[id][playerName]);
		}
	case 2:{
			formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`sid` = '%s'",szTmp);
		}
	case 3:{
			if(is_steam(id)){
				formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`sid` = '%s'",szTmp);
			}
			else{
				formatex(szCommand[iLen],charsmax( szCommand ) - iLen,"`nick` = '%s' AND `sid` = '%s'",playerInf[id][playerName],szTmp);
			}
		}
	}
	
	new Data[1];
	
	Data[0] = id;
	
	SQL_ThreadQuery(gTuple,"checkSqlHandle",szCommand,Data,1);
	
	#if defined DEBUG
	log_to_file( DEBUG_LOG , "checkSql id %d | Query %s", id , szCommand )
	#endif
	
	return PLUGIN_CONTINUE;
}

public checkSqlHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		logDiablo( "checkSqlHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		logDiablo( "checkSqlHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		logDiablo( "checkSqlHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	new id = Data[0];
	
	if( sqlPlayer[ id ] ){
		return PLUGIN_CONTINUE;
	}
	
	sqlPlayer[id] = true;
	
	if(SQL_MoreResults(Query)){
		
		new Array:classLoaded = ArrayCreate(MAX_LEN_NAME,10);
		
		while(SQL_MoreResults(Query)){
			
			new szClass[MAX_LEN_NAME],szTmp[MAX_LEN_NAME],iFind = -1;
			SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"klasa"),szClass,charsmax( szClass ) );
			
			for(new i = 1;i < ArraySize(gClassNames) ; i++){
				ArrayGetString(gClassNames,i,szTmp,charsmax( szTmp ) );
				
				replace_all(szTmp,charsmax( szTmp )," ","_");
				replace_all(szTmp,charsmax( szTmp ),"'","Q");
				replace_all(szTmp,charsmax( szTmp ),"`","Q");
				
				if(equal(szTmp,szClass)){
					iFind = i;
					break;
				}	
			}
			
			if(iFind != -1){
				new iInput[9];
				
				iInput[0] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"lvl"))
				iInput[1] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"exp"))
				iInput[2] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"str"))
				iInput[3] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"int"))
				iInput[4] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"dex"))
				iInput[5] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"agi"))
				iInput[6] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"armor"))
				iInput[7] 	= 	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"luck"))
				iInput[8]	=	SQL_ReadResult(Query,SQL_FieldNameToNum(Query,"points"))
				
				ArraySetArray(playerInfClasses[id],iFind,iInput)
				ArrayPushString(classLoaded,szClass);
			}
			
			SQL_NextRow(Query);
		}
		
		for(new j = 1 ; j < ArraySize(gClassNames); j++){
			
			new iFind = -1,szTmp[MAX_LEN_NAME],szTmp2[MAX_LEN_NAME];
			
			ArrayGetString(gClassNames,j,szTmp,charsmax(szTmp));
			
			replace_all(szTmp,charsmax( szTmp )," ","_");
			replace_all(szTmp,charsmax( szTmp ),"'","Q");
			replace_all(szTmp,charsmax( szTmp ),"`","Q");
			
			for(new i = 0;i < ArraySize(classLoaded);i++){
				ArrayGetString(classLoaded,i,szTmp2,charsmax(szTmp2));
				
				if(equal(szTmp,szTmp2)){
					iFind = j;
					break;
				}
			}
			
			if(iFind == -1){
				new szAuth[64],szIp[64],szCommand[512];
				
				get_user_authid(id,szAuth,charsmax( szAuth ) );
				get_user_ip(id,szIp,charsmax( szIp ) );
				
				if( equal( szAuth , "" ) || equal( playerInf[id][playerName] , "" ) ){
					continue;
				}
				
				formatex(szCommand,charsmax( szCommand ),"INSERT INTO %s  (`ip`, `sid`, `nick`, `klasa`) VALUES ('%s','%s','%s','%s')",SQL_TABLE,szIp,szAuth,playerInf[id][playerName],szTmp);
				
				SQL_ThreadQuery(gTuple,"insertSqlHandle",szCommand);
				
				#if defined DEBUG
				log_to_file( DEBUG_LOG , "Insert1 id %d | class %d | Query %s", id , j , szCommand )
				#endif
				
				if(get_pcvar_num(pCvarAVG)){
					new iOutput[9];
					ArrayGetArray(playerInfClasses[id],j,iOutput);
					
					iOutput[0] = ArrayGetCell(gClassAvg,j);
					iOutput[1] = getLevelXP( iOutput[0] - 1 );
					iOutput[8] = ( iOutput[0] * 2 ) -2;
					
					ArraySetArray(playerInfClasses[id],j,iOutput);
				}
			}
		}
		
		ArrayClear(classLoaded);
	}
	else{
		new szAuth[64],szIp[64];
		
		get_user_authid(id,szAuth,charsmax( szAuth ) );
		get_user_ip(id,szIp,charsmax( szIp ) );
		
		new szCommand[512];
		
		for(new i = 1;i<ArraySize(gClassNames) ; i++){
			
			new szClass[MAX_LEN_NAME];
			ArrayGetString(gClassNames,i,szClass,MAX_LEN_NAME - 1);
			
			replace_all(szClass,charsmax( szClass )," ","_");
			replace_all(szClass,charsmax( szClass ),"'","Q");
			replace_all(szClass,charsmax( szClass ),"`","Q");
			
			formatex(szCommand,charsmax( szCommand ),"INSERT INTO %s  (`ip`, `sid`, `nick`, `klasa`) VALUES ('%s','%s','%s','%s')",SQL_TABLE,szIp,szAuth,playerInf[id][playerName],szClass);
			
			#if defined DEBUG
			log_to_file( DEBUG_LOG , "Insert2 id %d | class %d | Query %s" , id , i , szCommand )
			#endif
			
			SQL_ThreadQuery(gTuple,"insertSqlHandle",szCommand);
			
			if(get_pcvar_num(pCvarAVG)){
				new iOutput[9];
				ArrayGetArray(playerInfClasses[id],i,iOutput);
				
				iOutput[0] = ArrayGetCell(gClassAvg,i);
				iOutput[1] = getLevelXP( iOutput[0] - 1 );
				iOutput[8] = ( iOutput[0] * 2 ) -2;
				
				ArraySetArray(playerInfClasses[id],i,iOutput);
			}
		}
	}
	return PLUGIN_CONTINUE
}

public insertSqlHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		logDiablo( "insertSqlHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		logDiablo( "insertSqlHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		logDiablo( "insertSqlHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public saveSql(id){
	if(!sqlPlayer[id])	return PLUGIN_CONTINUE;
	
	new szClass[MAX_LEN_NAME]
	
	new szAuth[64],szIp[64],szName[64],szTmp[128];
	
	get_user_authid(id,szAuth,charsmax( szAuth ) );
	get_user_ip(id,szIp,charsmax( szIp ) );
	get_user_name( id , szName , charsmax( szName ) );
	
	replace_all(szName,charsmax( szName ),"'","Q")
	replace_all(szName,charsmax( szName ),"`","Q")
	
	switch(get_pcvar_num(pCvarSaveType)){
	case 1:{
			formatex(szTmp,charsmax( szTmp ),"`nick` = '%s'",playerInf[id][playerName]);
		}
	case 2:{			
			formatex(szTmp,charsmax( szTmp ),"`sid` = '%s'",szAuth);
		}
	case 3:{
			if(is_steam(id)){
				formatex(szTmp,charsmax( szTmp ),"`sid` = '%s'",szAuth);
			}
			else{
				formatex(szTmp,charsmax( szTmp ),"`nick` = '%s' AND `sid` = '%s'",playerInf[id][playerName],szAuth);
			}
		}
	}
	
	for(new i = 1;i < ArraySize(playerInfClasses[id]); i++){
		new szCommand[512],iLen = 0;
		
		ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
		
		replace_all(szClass,charsmax( szClass )," ","_");
		replace_all(szClass,charsmax( szClass ),"'","Q");
		replace_all(szClass,charsmax( szClass ),"`","Q");
		
		new iOutput[9];
		
		ArrayGetArray(playerInfClasses[id],i,iOutput)
		
		if( get_pcvar_num(pCvarSaveType) == 1 ){
			iLen += formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `sid` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `armor` = '%d' , `luck` = '%d' , `points` = '%d' , `modified` = CURDATE() WHERE `klasa` = '%s' AND ",SQL_TABLE,szIp,szAuth,iOutput[0],iOutput[1],iOutput[2],iOutput[3],iOutput[4],iOutput[5],iOutput[6] , iOutput[7] , iOutput[8],szClass);
		}
		else if( get_pcvar_num(pCvarSaveType) == 3 && !is_steam( id ) ){
			iLen += formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `armor` = '%d' , `luck` = '%d' , `points` = '%d' , `modified` = CURDATE() WHERE `klasa` = '%s' AND ",SQL_TABLE,szIp,iOutput[0],iOutput[1],iOutput[2],iOutput[3],iOutput[4],iOutput[5],iOutput[6] , iOutput[7] , iOutput[8],szClass);
		}
		else{
			iLen += formatex(szCommand,charsmax( szCommand ),"UPDATE %s SET `ip` = '%s' , `nick` = '%s' , `lvl` = '%d' , `exp` = '%d', `str` = '%d',`int` = '%d',`dex` = '%d',`agi` = '%d', `armor` = '%d' , `luck` = '%d' , `points` = '%d' , `modified` = CURDATE() WHERE `klasa` = '%s' AND ",SQL_TABLE,szIp,szName,iOutput[0],iOutput[1],iOutput[2],iOutput[3],iOutput[4],iOutput[5],iOutput[6] , iOutput[7] , iOutput[8],szClass);
		}
		
		add(szCommand,charsmax( szCommand ),szTmp);
		
		#if defined DEBUG
		log_to_file( DEBUG_LOG , "saveSql id %d | class %d | Query %s", id , i , szCommand )
		#endif
		
		SQL_ThreadQuery(gTuple,"saveSqlHandle",szCommand);
	}
	
	return PLUGIN_CONTINUE;
}

public saveSqlHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(Errcode)
	{
		logDiablo( "saveSqlHandle: Error on Table query: %s",Error)
	}
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		logDiablo( "saveSqlHandle: Could not connect to SQL database.")
		
		return PLUGIN_CONTINUE
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		logDiablo( "saveSqlHandle: Table Query failed.")
		
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public client_authorized(id){
	
	iPlayersNum++;
	
	setPlayerClass( id , 0 );
	setPlayerItem( id , 0 );
	
	playerInf[id][currentLevel] 	= 	1;
	playerInf[id][currentExp]		=	0;
	playerInf[id][currentStr]		=	0;
	playerInf[id][currentInt]		=	0;
	playerInf[id][currentDex]		=	0;
	playerInf[id][currentAgi]		=	0;
	playerInf[id][currentArmor]		=	0;
	playerInf[id][currentLuck]		=	0;
	playerInf[id][currentPoints] 	=	0;
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	playerInf[id][itemDurability]	=	0;
	playerInf[id][maxHp]			=	100;
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:BASE_SPEED;
	playerInf[id][dmgReduce]		=	_:0.0;
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]		=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	copy(playerInf[id][playerName],MAX_LEN_NAME_PLAYER,"");
	
	ArrayClear(playerInfClasses[id]);
	ArrayClear(playerInfRender[id]);
	
	new iInput[9] = {1,0,0,0,0,0,0,0,0}
	
	for(new i = 0 ; i < ArraySize(gClassNames) ; i++){
		ArrayPushArray(playerInfClasses[id],iInput)
	}
	
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	bFirstRespawn[id] = true;
	
	sqlPlayer[id] = false;
	
	client_cmd(id,"hud_centerid 0");
	
	new szName[MAX_LEN_NAME_PLAYER];
	
	get_user_name(id,szName,MAX_LEN_NAME_PLAYER - 1);
	
	replace_all(szName,charsmax( szName )," ","_");
	replace_all(szName,charsmax( szName ),"'","Q")
	replace_all(szName,charsmax( szName ),"`","Q")
	
	copy(playerInf[id][playerName],MAX_LEN_NAME_PLAYER,szName);
	
	set_task(TIME_HUD,"writeHud",id, .flags = "b");
	
	checkSQL(id);
}

public client_disconnect(id){
	
	iPlayersNum--;
	
	SaveInfo(id);
	
	saveSql(id);
	
	if( !isPlayerClassNone( id ) ){
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_DISABLED ),  id);
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_CLEAN_DATA ) ,id);
		
	}
	
	setPlayerClass( id , 0 );
	setPlayerItem( id , 0 );
	
	playerInf[id][currentLevel] 	= 	1;
	playerInf[id][currentExp]		=	0;
	playerInf[id][currentStr]		=	0;
	playerInf[id][currentInt]		=	0;
	playerInf[id][currentDex]		=	0;
	playerInf[id][currentAgi]		=	0;
	playerInf[id][currentArmor]		=	0;
	playerInf[id][currentLuck]		=	0;
	playerInf[id][currentPoints]	=	0;
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	playerInf[id][itemDurability]	=	0;
	playerInf[id][maxHp]			=	100;
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:BASE_SPEED;
	playerInf[id][dmgReduce]		=	_:0.0;
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]		=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	
	ArrayClear(playerInfClasses[id]);
	ArrayClear(playerInfRender[id]);
	
	new iInput[9] = {1,0,0,0,0,0,0,0,0}
	
	for(new i = 0 ; i < ArraySize(gClassNames) ; i++){
		ArrayPushArray(playerInfClasses[id],iInput)
	}
	
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	sqlPlayer[id] = false;
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MUTLI_CLEAN_USER_INFORMATION ) , id );
}

public getUserStr( id ){
	return playerInf[id][currentStr] + playerInf[id][extraStr];
}

public getUserInt( id ){
	return playerInf[id][currentInt] + playerInf[id][extraInt];
}

public getUserDex( id ){
	return playerInf[id][currentDex] + playerInf[id][extraDex];
}

public getUserAgi( id ){
	return playerInf[id][currentAgi] + playerInf[id][extraAgi];
}

public plugin_end(){
	SQL_FreeHandle(gTuple);
	
	ArrayDestroy(gClassPlugins);
	ArrayDestroy(gClassNames);
	ArrayDestroy(gClassAvg);
	ArrayDestroy(gClassHp);
	ArrayDestroy(gClassDesc);
	ArrayDestroy(gClassFlag);
	ArrayDestroy(gItemName);
	ArrayDestroy(gItemPlugin);
	ArrayDestroy( gItemDur );
	ArrayDestroy( gItemFrom );
	ArrayDestroy( gItemTo );
	ArrayDestroy(gFractionNames);
	ArrayDestroy(gClassFraction);
	
	for(new i = 1;i < MAX + 1; i++ ){
		ArrayDestroy(playerInfClasses[i])
		ArrayDestroy(playerInfRender[i]);
	}
	
	new tmpForwardsClass[ forwardsStructureClass ],
	tmpForwardsItem[ forwardsStructureItem ];
	
	for( new iPosition = 0 ; iPosition < ArraySize( gForwardsClass ); iPosition++ ){
		ArrayGetArray( gForwardsClass , iPosition , tmpForwardsClass );
		
		for( new iPositionTmp = 0; iPositionTmp < sizeof( tmpForwardsClass ); iPositionTmp++ ){
			DestroyForward( tmpForwardsClass[ forwardsStructureClass: iPositionTmp ] );
		}
	}
	
	for( new iPosition = 0 ; iPosition < ArraySize( gForwardsItem ); iPosition++ ){
		ArrayGetArray( gForwardsItem , iPosition , tmpForwardsItem );
		
		for( new iPositionTmp = 0; iPositionTmp < sizeof( tmpForwardsItem ); iPositionTmp++ ){
			DestroyForward( tmpForwardsItem[ forwardsStructureItem: iPositionTmp ] );
		}
	}
	
	for( new iPosition = 0; iPosition < sizeof( gForwardsMulti ); iPosition++ ){
		DestroyForward( gForwardsMulti[ forwardsMulti: iPosition ] );
	}
	
	ArrayDestroy( gForwardsClass );
	ArrayDestroy( gForwardsItem );
	
	menu_destroy( pRuneMenu );
	menu_destroy( pModMenu );
}

playerPointsMenu(id,page = 0){
	if( isPlayerClassNone( id ) || playerInf[id][currentPoints] <= 0)	return PLUGIN_CONTINUE;
	
	new pMenu,szTmp[128];
	
	formatex(szTmp,charsmax( szTmp ),"Wybierz Staty- \rPunkty: %i",playerInf[id][currentPoints]);
	pMenu = menu_create(szTmp,"playerPointsMenuHandle")
	
	formatex(szTmp,charsmax( szTmp ),"Inteligencja \r[%i] \y[Wieksze obrazenia czarami]",playerInf[id][currentInt]);
	menu_additem(pMenu,szTmp , "0" );
	
	formatex(szTmp,charsmax( szTmp ),"Sila \r[%i] \y[Wiecej zycia]",playerInf[id][currentStr]);
	menu_additem(pMenu,szTmp , "1" );
	
	formatex(szTmp,charsmax( szTmp ),"Zrecznosc \r[%i] \y[Bronie zadaja ci mniejsze obrazenia]",playerInf[id][currentAgi]);
	menu_additem(pMenu,szTmp , "2" );
	
	formatex(szTmp,charsmax( szTmp ),"Zwinnosc \r[%i] \y[Szybciej biegasz i magia zadaje ci mniejsze obrazenia]",playerInf[id][currentDex]);
	menu_additem(pMenu,szTmp, "3");

	formatex(szTmp,charsmax( szTmp ),"Pancerz \r[%i] \y[Dostajesz pancerz]",playerInf[id][currentArmor]);
	menu_additem(pMenu,szTmp, "8");

	formatex(szTmp,charsmax( szTmp ),"Szczescie \r[%i] \y[Dostajesz więcej kasy za zabicie (więcej pkt więcej kasy]",playerInf[id][currentLuck]);
	menu_additem(pMenu,szTmp, "9");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Inteligencje");
	menu_additem(pMenu,szTmp, "4");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Sile");
	menu_additem(pMenu,szTmp, "5");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Zrecznosc");
	menu_additem(pMenu,szTmp, "6");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Zwinnosc");
	menu_additem(pMenu,szTmp, "7");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Pancerz");
	menu_additem(pMenu,szTmp, "10");
	
	formatex(szTmp,charsmax( szTmp ),"\yWszystko w Szczescie");
	menu_additem(pMenu,szTmp, "11");
	
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\r");
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc");
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie");
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej");
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		playerPointsMenuHandle(id , pMenu,  random_num( 0 , 7 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_CONTINUE;
}

public playerPointsMenuHandle(id,menu,item){
	if(item == MENU_EXIT || isPlayerClassNone( id ) || playerInf[id][currentPoints] <= 0){
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	
	new iPage	=	item / 7;
	
	new item	=	str_to_num( data );
	
	switch(item){
	case 0:{
			if(playerInf[id][currentInt] < MAX_SKILL){
				playerInf[id][currentInt]++;
				playerInf[id][currentPoints]--;
			}
			else client_print(id,print_center,"Maxymalny poziom inteligencji osiagniety")
		}
	case 1:{
			if(playerInf[id][currentStr] < MAX_SKILL){
				playerInf[id][currentStr]++;
				playerInf[id][currentPoints]--;
			}
			else client_print(id,print_center,"Maxymalny poziom sily osiagniety")
		}
	case 2:{
			if(playerInf[id][currentAgi] < MAX_SKILL){
				playerInf[id][currentAgi]++;
				playerInf[id][currentPoints]--;
				
				playerInf[id][dmgReduce]		=	_:( float(playerInf[id][currentAgi]) * get_pcvar_float( pCvarReducePower ) );
			}
			else client_print(id,print_center,"Maxymalny poziom zrecznosci osiagniety")
		}
	case 3:{
			if(playerInf[id][currentDex] < MAX_SKILL){
				playerInf[id][currentDex]++;
				playerInf[id][currentPoints]--;
			}
			else client_print(id,print_center,"Maxymalny poziom zwinnosci osiagniety")
		}
	case 4: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentInt] <= MAX_SKILL)
			{
				playerInf[id][currentInt] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentInt]
				playerInf[id][currentInt] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom inteligencji osiagniety")
			}
		}
	case 5: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentStr] <= MAX_SKILL)
			{
				playerInf[id][currentStr] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentStr]
				playerInf[id][currentStr] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom sily osiagniety")
			}
		}
	case 6: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentAgi] <= MAX_SKILL)
			{
				playerInf[id][currentAgi] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentAgi]
				playerInf[id][currentAgi] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom zrecznosci osiagniety")
			}
			
			playerInf[id][dmgReduce]		=	_:(float(playerInf[id][currentAgi]) * get_pcvar_float( pCvarReducePower ));
		}
	case 7: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentDex] <= MAX_SKILL)
			{
				playerInf[id][currentDex] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentDex]
				playerInf[id][currentDex] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom zwinnosci osiagniety")
			}
		}
	case 8:{
			if(playerInf[id][currentArmor] < MAX_SKILL){
				playerInf[id][currentArmor]++;
				playerInf[id][currentPoints]--;
			}
			else client_print(id,print_center,"Maxymalny poziom armora osiagniety")
		}
	case 9:{
			if(playerInf[id][currentLuck] < MAX_SKILL){
				playerInf[id][currentLuck]++;
				playerInf[id][currentPoints]--;
			}
			else client_print(id,print_center,"Maxymalny poziom szczescia osiagniety")
		}
	case 10: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentArmor] <= MAX_SKILL)
			{
				playerInf[id][currentArmor] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentArmor]
				playerInf[id][currentArmor] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom armora osiagniety")
			}
		}
	case 11: 
		{	
			if (playerInf[id][currentPoints]+playerInf[id][currentLuck] <= MAX_SKILL)
			{
				playerInf[id][currentLuck] += playerInf[id][currentPoints]
				playerInf[id][currentPoints] = 0
			}
			else
			{
				playerInf[id][currentPoints] -= MAX_SKILL - playerInf[id][currentLuck]
				playerInf[id][currentLuck] = MAX_SKILL
				client_print(id,print_center,"Maxymalny poziom szczescia osiagniety")
			}
		}
	}
	
	if( !isPlayerClassNone( id ) && playerInf[id][currentPoints] > 0){
		playerPointsMenu(id,iPage);
	}
	
	return PLUGIN_CONTINUE;
}

public clearRender(id){
	if(ArraySize(playerInfRender[id]) != 1){	
		new Array:arrayTmp = ArrayCreate(8,1);
		new iOutput[8] , bool:bPush = true;
		
		for(new i = ArraySize(playerInfRender[id]) - 1 ; i >= 0 ; i-- ){
			ArrayGetArray(playerInfRender[id],i,iOutput);
			
			if( ( Float:iOutput[6] == 0.0 || Float:iOutput[6] > get_gametime() ) && iOutput[7] != DIABLO_RENDER_DESTROYED){			
				if(bPush){
					bPush	=	false;
					ArrayPushArray(arrayTmp,iOutput);
				}
				else{
					if(Float:iOutput[6] != 0.0){
						new iTmpOutput[8];
						ArrayGetArray(arrayTmp,0,iTmpOutput);
						if(Float:iTmpOutput[6] < Float:iOutput[6])
						ArrayInsertArrayBefore(arrayTmp,0,iOutput);
					}
					else
					ArrayInsertArrayBefore(arrayTmp,0,iOutput);
				}
			}
			if(Float:iOutput[6] == 0.0 && iOutput[7] != DIABLO_RENDER_DESTROYED )	break;
		}
		
		ArrayClear(playerInfRender[id]);
		
		for( new i = 0; i < ArraySize(arrayTmp) ; i++ ){
			ArrayGetArray(arrayTmp,i,iOutput);
			ArrayPushArray(playerInfRender[id],iOutput)
		}
		
		ArrayDestroy(arrayTmp);
	}
	else {
		new iOutput[8];
		ArrayGetArray( playerInfRender[id] , 0 , iOutput );
		
		if( iOutput[ 7 ] == DIABLO_RENDER_DESTROYED ){
			ArrayClear(playerInfRender[id]);
			
			new iInputRedner[8];
			
			iInputRedner[0]	=	255;
			iInputRedner[1]	=	255
			iInputRedner[2]	=	255
			iInputRedner[3]	=	kRenderFxNone;
			iInputRedner[4]	=	kRenderNormal;
			iInputRedner[5]	=	16;
			iInputRedner[6]	=	_:0.0;
			iInputRedner[7]	=	0;
			
			ArrayPushArray(playerInfRender[id],iInputRedner);
		}
	}
}

public wybierzKlase(id){
	if(!sqlPlayer[id]){
		return PLUGIN_HANDLED;
	}
	
	if(!bFreezeTime && !isPlayerClassNone( id ) ){
		user_kill( id );
	}
	
	if( ArraySize( gFractionNames )	==	1 ){
		wybierzKlase2( id );
	}
	else{
		wybierzKlaseFrakcje( id );
	}
	
	return PLUGIN_HANDLED;
}

wybierzKlaseFrakcje( id , page = 0 ){
	new pMenu = menu_create("Wybierz Frakcje","wybierzFrakcjeHandle");
	
	new szFraction[MAX_LEN_FRACTION],szTmp[MAX_LEN_NAME + 128],iOutput[9] , szNum[ 64 ] , szClass[ MAX_LEN_NAME ] ;
	
	for(new i = 1; i < ArraySize( gFractionNames ) ; i++ ){
		ArrayGetString( gFractionNames , i , szFraction , MAX_LEN_FRACTION - 1 );
		
		formatex(szTmp,charsmax( szTmp ),"%s",szFraction);
		
		num_to_str( i , szNum , charsmax( szNum ) )
		
		add( szNum , charsmax( szNum ) , "frakcja" );
		
		menu_additem(pMenu,szTmp , szNum);
	}
	
	for(new i = 1;i < ArraySize(gClassNames) ; i++){
		if( ArrayGetCell( gClassFraction  , i) == 0 ){
			ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
			ArrayGetArray(playerInfClasses[id],i,iOutput);
			
			formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
			
			num_to_str( i , szNum , charsmax( szNum ) )
			
			menu_additem( pMenu , szTmp , szNum );
		}
	}
	
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie")
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej")
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\w")
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		wybierzFrakcjeHandle(id , pMenu,  random_num( 0 , ArraySize( gFractionNames ) - 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_HANDLED;
}

public wybierzKlaseHandle2 ( id , menu , item ){
	if( item == MENU_EXIT ){
		menu_destroy( menu );
		
		wybierzKlaseFrakcje( id );
		
		return PLUGIN_HANDLED;
	}
	
	new data[64], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,63, iName, 63, callback)
	
	item	=	str_to_num( data );
	
	new oldItem	=	item;
	item	=	str_to_num( data );
	
	if(item == getPlayerClass( id ) ){
		ColorChat(id,GREEN,"%s ^x01 Masz juz ta klase !",PREFIX_SAY)
		
		wybierzKlaseFrakcje(id,oldItem/7)
		
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if( ArrayGetCell( gClassFlag , item ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item )) ){
		ColorChat(id,GREEN,"%s ^x01 Nie masz uprawnien do korzystania z tej klasy",PREFIX_SAY)
		
		createMenuFromFraction(id,oldItem/7)
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	if( !isPlayerClassNone( id ) ){
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_DISABLED ), id );
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_CLEAN_DATA ) ,id );
		
		SaveInfo(id);
	}
	else {
		ColorChat(id,GREEN,"%s ^x01 Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu !",PREFIX_SAY)
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SPAWNED ) ,id);
	}
	
	setPlayerClass( id , item );

	setPlayerItem( id , 0 );
	
	LoadInfo(id);
	
	ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_ENABLED ), id);
	
	ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SET_DATA ) ,id);
	
	ExecuteForwardIgnoreIntTwoParam( getForwardMulti( MULTI_USER_CHANGE_CLASS ) ,id , getPlayerClass( id ) );
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

createMenuFromFraction ( id , page	= 0 ){

	new pMenu = menu_create("Wybierz Klase","wybierzKlaseHandle2");
	
	new szClass[ MAX_LEN_NAME ],
		szTmp[ MAX_LEN_NAME + 128 ],
		iOutput[ 9 ], 
		szNum[ 16 ],
		iCurrentItem = 0;
	
	#if defined BOTY
	new Array: availableItems = ArrayCreate( 1 , 10 );
	#endif

	for( new i = 1 ; i < ArraySize( gClassNames ) ; i++ ){
		if( iPlayerFraction[ id ]	==	ArrayGetCell( gClassFraction , i ) ){

			iCurrentItem++;

			ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
			ArrayGetArray(playerInfClasses[id],i,iOutput);
			
			formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
			
			num_to_str( i , szNum , charsmax( szNum ) )
			
			menu_additem(pMenu,szTmp , szNum);

			#if defined BOTY
			if( ArrayGetCell( gClassFlag , i ) == FLAG_ALL || (get_user_flags( id ) & ArrayGetCell( gClassFlag , i )) ){
				ArrayPushCell( availableItems , currentItem );
			}
			#endif
		}
	}
	menu_setprop(pMenu,MPROP_EXITNAME , "Do frakcji" );
	menu_setprop(pMenu,MPROP_BACKNAME , "Wroc" );
	menu_setprop(pMenu,MPROP_NEXTNAME , "Dalej" );

	menu_setprop(pMenu,MPROP_NUMBER_COLOR , "\w" );
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		
		if( ArraySize( availableItems ) <= 0 ){
			ArrayDestroy( availableItems );

			return PLUGIN_HANDLED;
		}

		wybierzKlaseHandle2(id , pMenu,  ArrayGetCell( availableItems , random_num( 0 , ArraySize( availableItems ) - 1  ) ) );
		
		ArrayDestroy( availableItems );

		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display( id , pMenu , page);
	
	return PLUGIN_HANDLED;
}

public wybierzFrakcjeHandle( id , menu , item ){
	if( item	==	MENU_EXIT ){
		menu_destroy( menu );
		
		return PLUGIN_HANDLED;
	}
	
	new data[64], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,63, iName, 63, callback)
	
	if( contain( data , "frakcja" ) != -1 ){
		replace_all( data , charsmax( data ) , "frakcja" , "" );
		
		iPlayerFraction[ id ]	=	str_to_num( data );
		
		createMenuFromFraction ( id );
		
	}
	else{
		new oldItem	=	item;
		item	=	str_to_num( data );
		
		if(item == getPlayerClass( id ) ){
			ColorChat(id,GREEN,"%s ^x01 Masz juz ta klase !",PREFIX_SAY)
			
			wybierzKlaseFrakcje(id,oldItem/7)
			
			menu_destroy(menu);
			return PLUGIN_CONTINUE;
		}
		
		if( ArrayGetCell( gClassFlag , item ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item )) ){
			ColorChat(id,GREEN,"%s ^x01 Nie masz uprawnien do korzystania z tej klasy",PREFIX_SAY)
			
			wybierzKlaseFrakcje(id,oldItem/7)
			
			menu_destroy(menu);
			
			return PLUGIN_CONTINUE;
		}
		
		if( !isPlayerClassNone( id ) ){
			
			ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_DISABLED ) , id);
			
			ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_CLEAN_DATA ) ,id);
			
			SaveInfo(id);
		}
		else {
			ColorChat(id,GREEN,"%s ^x01 Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu !",PREFIX_SAY)
			
			ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SPAWNED ) ,id);
		}
		
		setPlayerClass( id , item );
		setPlayerItem( id , 0 );
		
		LoadInfo(id);
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_ENABLED ) , id);
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SET_DATA ) , id);
		
		ExecuteForwardIgnoreIntTwoParam( getForwardMulti( MUTLI_USER_CHANGE_CLASS ),id , getPlayerClass( id ) );
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
	
}

wybierzKlase2(id,page = 0){
	new pMenu = menu_create("Wybierz Klase","wybierzKlaseHandle");
	
	new szClass[MAX_LEN_NAME],szTmp[MAX_LEN_NAME + 128],iOutput[9];
	
	for(new i = 1;i < ArraySize(gClassNames) ; i++){
		ArrayGetString(gClassNames,i,szClass,charsmax( szClass ) );
		ArrayGetArray(playerInfClasses[id],i,iOutput);
		
		formatex(szTmp,charsmax( szTmp ),"\r%s \yLevel: %d",szClass,iOutput[0]);
		
		menu_additem(pMenu,szTmp);
	}
	
	menu_setprop(pMenu,MPROP_EXITNAME,"Wyjscie")
	menu_setprop(pMenu,MPROP_BACKNAME,"Wroc")
	menu_setprop(pMenu,MPROP_NEXTNAME,"Dalej")
	menu_setprop(pMenu,MPROP_NUMBER_COLOR,"\w")
	
	#if defined BOTY
	if( is_user_bot( id ) ){
		wybierzKlaseHandle(id , pMenu,  random_num( 0 , ArraySize(gClassNames) - 1 ) )
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	menu_display(id,pMenu,page)
	
	return PLUGIN_HANDLED;
}

public wybierzKlaseHandle(id,menu,item){
	if(item == MENU_EXIT || !is_user_connected( id ) ){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if(item + 1 == getPlayerClass( id ) ){
		ColorChat(id,GREEN,"%s ^x01 Masz juz ta klase !",PREFIX_SAY)
		
		wybierzKlase2(id,item/7)
		
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if( ArrayGetCell( gClassFlag , item + 1 ) != FLAG_ALL && !(get_user_flags( id ) & ArrayGetCell( gClassFlag , item + 1 )) ){
		ColorChat(id,GREEN,"%s ^x01 Nie masz uprawnien do korzystania z tej klasy",PREFIX_SAY)
		
		wybierzKlase2(id,item/7)
		
		menu_destroy(menu);
		
		return PLUGIN_CONTINUE;
	}
	
	if( !isPlayerClassNone( id ) ){
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_DISABLED ) , id);
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_CLEAN_DATA ) ,id);
		
		SaveInfo(id);
	}
	else {
		ColorChat(id,GREEN,"%s ^x01 Wszystkie skille klasy zostana zaladowane przy ponownym odrodzeniu !",PREFIX_SAY)
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SPAWNED ), id );
	}
	
	setPlayerClass( id , item + 1 );
	setPlayerItem( id , 0 );
	
	LoadInfo(id);
	
	ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_ENABLED ), id);
	
	ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SET_DATA ) ,id);

	ExecuteForwardIgnoreIntTwoParam( getForwardMulti( MULTI_USER_CHANGE_CLASS ) ,id , getPlayerClass( id ) );
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}
/*---------------------EXP---------------------*/

public showStatus(id){
	writeHud(id);
}

public sprawdzPoziomUp(id){
	new bool:bAwans = false;
	
	while(playerInf[id][currentExp] >= getLevelXP( playerInf[id][currentLevel] ) && playerInf[id][currentLevel] < getMaxLevel() ){
		
		playerInf[id][currentLevel]++;
		playerInf[id][currentPoints] += get_pcvar_num( pCvarPoints );
		
		bAwans = true;
	}
	
	if(bAwans){
		new szName[64];
		get_user_name(id,szName,charsmax( szName ) );
		
		new szClass[MAX_LEN_NAME];
		ArrayGetString(gClassNames, getPlayerClass( id ) ,szClass,charsmax( szClass ) );
		
		ColorChat(0, TEAM_COLOR, "%s^x01 awansowal na^x03 %i^x01 level (^x04%s^x01)", szName, playerInf[id][currentLevel], szClass)
		
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		ShowSyncHudMsg(id,syncHud,"Awansowales do poziomu %i", playerInf[id][currentLevel]) 
	}
}

public sprawdzPoziomLose(id){
	new bool:bSpadek = false;
	
	while(playerInf[id][currentExp] < getLevelXP( playerInf[id][currentLevel] - 1 ) && playerInf[id][currentLevel] > 1){
		
		playerInf[id][currentLevel]--;
		
		bSpadek = true;
	}
	
	if(bSpadek){	
		set_hudmessage(60, 200, 25, -1.0, 0.25, 0, 1.0, 2.0, 0.1, 0.2, 2)
		ShowSyncHudMsg(id,syncHud,"Spadles do poziomu %i", playerInf[id][currentLevel]) 
		
		resetSkills(id);
	}
}

public giveXp(id,ile){
	if( !isPlayerClassNone( id ) && iPlayersNum >= get_pcvar_num(pCvarNum) ){
		playerInf[id][currentExp] += ile;
		sprawdzPoziomUp(id);
		
		if( playerInf[ id ][ currentLevel ] >= getMaxLevel() ){
			playerInf[id][currentExp]	=	getLevelXP( getMaxLevel() );
		}
		
		SaveInfo(id);
	}
}

public takeXp(id,ile){
	if( !isPlayerClassNone( id ) && iPlayersNum >= get_pcvar_num(pCvarNum) ){
		playerInf[id][currentExp] -= ile;
		
		if(playerInf[id][currentExp] < 0)	playerInf[id][currentExp] = 0;
		
		sprawdzPoziomLose(id);
		SaveInfo(id)
	}
}

public killXP(iKiller,iVictim)
{
	if (!is_user_connected(iKiller) || !is_user_connected(iVictim) || get_user_team(iKiller) == get_user_team(iVictim))
	return PLUGIN_CONTINUE
	
	new iXpAward = get_pcvar_num(pCvarXPBonus),xpBonus = get_pcvar_num(pCvarXPBonus);
	
	if (playerInf[iKiller][currentExp] < playerInf[iVictim][currentExp])	 iXpAward	+=	xpBonus /4
	
	new moreLvl = playerInf[iVictim][currentLevel] - playerInf[iKiller][currentLevel]
	
	if(moreLvl>0) 		iXpAward += floatround((xpBonus/7)*(moreLvl*((2.0-moreLvl/101.0)/3.0)))
	else if(moreLvl<-50)	iXpAward -= xpBonus*(2/3)
	else if(moreLvl<-40)	iXpAward -= xpBonus/2
	else if(moreLvl<-30)	iXpAward -= xpBonus/3
	else if(moreLvl<-20)	iXpAward -= xpBonus/4
	else if(moreLvl<-10)	iXpAward -= xpBonus/7
	
	if(iXpAward < 0)	iXpAward = 0;
	
	new iRet;
	
	ExecuteForward( getForwardMulti( MULTI_KILL_XP ), iRet, iKiller,iVictim ,iXpAward);
	
	if(iRet != 0)	iXpAward = iRet;
	
	if(iRet >= 0){
		giveXp(iKiller,iXpAward)
	}
	else{
		takeXp(iKiller,iXpAward)
	}
	
	return PLUGIN_CONTINUE
	
}

public resetSkills(id){
	if( !isPlayerClassNone( id ) ){
		playerInf[id][currentPoints] = ( playerInf[id][currentLevel] * get_pcvar_num( pCvarPoints ) ) - get_pcvar_num( pCvarPoints );
		
		playerInf[ id ][ currentAgi ] = 0;
		playerInf[ id ][ currentDex ] = 0;
		playerInf[ id ][ currentInt ] = 0;
		playerInf[ id ][ currentStr ] = 0;
		playerInf[ id ][ currentArmor ] = 0;
		playerInf[ id ][ currentLuck ] = 0;
		
		ColorChat( id, GREEN , "%s Reset skill'ow" , PREFIX_SAY );
		
		playerPointsMenu( id );
	}
	
	return PLUGIN_HANDLED;
}

public writeHud(id){
	if(is_user_connected( id ) && !is_user_alive(id)){
		static iSpec ;
		
		iSpec	=	pev( id , pev_iuser2 );
		
		if( !is_user_alive( iSpec ) ){
			return PLUGIN_CONTINUE;
		}
		
		static szName[ 64 ] , szClass[ 256 ] , szItem[ 256 ];
		
		get_user_name( iSpec , szName , charsmax( szName ) );
		
		ArrayGetString( gClassNames , getPlayerClass( iSpec ) , szClass , charsmax( szClass ) );
		ArrayGetString( gItemName , getPlayerClass( iSpec ) , szItem , charsmax( szItem ) );
		
		set_hudmessage(255, 255, 255, 0.78, 0.65, 0, 6.0, 3.0)
		show_hudmessage( id , "Nick: %s^nPoziom: %i^nKlasa: %s^nPrzedmiot: %s^nInteligencja: %i^nSila: %i^nZwinnosc: %i^nZrecznosc: %i^nArmor: %i^nSzczescie: %i", szName , playerInf[ iSpec ][ currentLevel ] , szClass , szItem , playerInf[ iSpec ][ currentInt ] , playerInf[ iSpec ][ currentStr ] , playerInf[ iSpec ][ currentDex ] , playerInf[ iSpec ][ currentAgi ] , playerInf[ iSpec ][ currentArmor ] , playerInf[ iSpec ][ currentLuck ] );
	}
	else if( is_user_alive( id ) ) {
		static szMessage[256],
		szClass[ MAX_LEN_NAME ],
		szItem[ MAX_LEN_NAME ];
		
		ArrayGetString(gClassNames, getPlayerClass( id ) ,szClass,charsmax( szClass ));
		ArrayGetString(gItemName , getPlayerClass( id ) , szItem , charsmax( szItem ) );
		
		switch( get_pcvar_num( pCvarWriteHudMode ) ){
		case 0:{
				if( playerInf[ id ][ currentLevel ] >= getMaxLevel() ){ 
					formatex(szMessage,charsmax( szMessage ),"Klasa: %s Level: %i Item: %s ",szClass,playerInf[id][currentLevel],szItem)
				}
				else{
					formatex(szMessage,charsmax( szMessage ),"Klasa: %s Level: %i ( %0.1f%s ) Item: %s ",szClass,playerInf[id][currentLevel],((float(playerInf[id][currentExp])-float( getLevelXP( playerInf[id][currentLevel] - 1 ) ))*100.0)/(float( getLevelXP( playerInf[id][currentLevel] ) )-float( getLevelXP( playerInf[id][currentLevel] - 1 ) )),"%%",szItem)
				}
			}
		case 1:{
				if( playerInf[ id ][ currentLevel ] >= getMaxLevel() ){ 
					formatex(szMessage, charsmax(szMessage), "%s[Klasa: %s]^n[Level: %i]^n[Item: %s] [ %i ]", HUD_TEXT , szClass,playerInf[id][currentLevel],szItem, playerInf[ id ][ itemDurability ])
				}
				else{
					formatex(szMessage, charsmax(szMessage), "%s[Klasa: %s]^n[Level: %i] [ %0.1f%s ]^n[Item: %s] [ %i ]", HUD_TEXT , szClass,playerInf[id][currentLevel],((float(playerInf[id][currentExp])-float( getLevelXP( playerInf[id][currentLevel] - 1 ) ) )*100.0)/(float( getLevelXP( playerInf[id][currentLevel] ) )-float( getLevelXP( playerInf[id][currentLevel] - 1 ) )),"%%", szItem, playerInf[ id ][ itemDurability ])
				}
			}
		}
		
		if( get_user_health( id ) > 255 ){
			set_hudmessage(255, 212, 0, 0.01, 0.88, 0, 6.0, 5.0)
			show_hudmessage(id, "Zycie: %d", get_user_health( id ))
		}
		
		static iRet;
		
		static iArrayPass;
		
		iArrayPass = PrepareArray(szMessage,256,1);
		
		ExecuteForward( getForwardMulti( MULTI_HUD_WRITE ) , iRet, id , iArrayPass,charsmax( szMessage ));
		
		switch( get_pcvar_num( pCvarWriteHudMode ) ){
		case 0:{
				message_begin(MSG_ONE,gmsgStatusText,{0,0,0}, id) 
				write_byte(0) 
				write_string(szMessage) 
				message_end() 
			}
		case 1:{
				set_hudmessage(16, 186, 16, 0.02, 0.21, 0, 6.0, 2.0)
				show_hudmessage(id, szMessage)
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

/*---------------------FREEZETIME---------------------*/

public freezeOver(){
	bFreezeTime = false;
	
	for( new i = 1 ; i <= MAX ; i++ ){
		if( !is_user_alive( i ) || isPlayerClassNone( i ) ){
			continue;
		}
		
		speedChange( i );
	}
}

public freezeBegin(){
	bFreezeTime = true;
}

/*---------------------SAVE & LOAD---------------------*/

SaveInfo(id){
	new iInput[9];
	
	iInput[0] 	= 	playerInf[id][currentLevel];
	iInput[1]	=	playerInf[id][currentExp]
	iInput[2]	=	playerInf[id][currentStr]
	iInput[3]	=	playerInf[id][currentInt]
	iInput[4]	=	playerInf[id][currentDex]
	iInput[5]	=	playerInf[id][currentAgi]
	iInput[6]	=	playerInf[id][currentArmor]
	iInput[7]	=	playerInf[id][currentLuck]
	iInput[8]	=	playerInf[id][currentPoints];
	
	ArraySetArray(playerInfClasses[id], getPlayerClass( id ) ,iInput);
}

LoadInfo(id){
	new iOutput[9];
	
	ArrayGetArray(playerInfClasses[id], getPlayerClass( id ) ,iOutput);
	
	playerInf[id][currentLevel] 	= 	iOutput[0]
	playerInf[id][currentExp] 		= 	iOutput[1]
	playerInf[id][currentStr] 		= 	iOutput[2]
	playerInf[id][currentInt] 		= 	iOutput[3]
	playerInf[id][currentDex] 		= 	iOutput[4]
	playerInf[id][currentAgi] 		= 	iOutput[5]
	playerInf[id][currentArmor] 	= 	iOutput[6]
	playerInf[id][currentLuck] 		= 	iOutput[7]
	playerInf[id][currentPoints]	=	iOutput[8]
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	playerInf[id][maxHp]			=	ArrayGetCell(gClassHp, getPlayerClass( id ) ) + (getUserStr( id ) * get_pcvar_num( pCvarStrPower ))
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + (float( getUserDex( id ) ) * 1.3));
	playerInf[id][dmgReduce]		=	_:(float(playerInf[id][currentAgi]) * get_pcvar_float( pCvarReducePower ));
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]		=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	
	ArrayClear(playerInfRender[id]);
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	renderChange(id);
	speedChange(id);
	gravChange(id);
	
}

/*---------------------Jakies takie---------------------*/

public fwItemDeployPost(weaponEnt)
{
	new iOwner = get_pdata_cbase(weaponEnt, OFFSET_WPN_WIN, OFFSET_WPN_LINUX);	
	new iWpnID = cs_get_weapon_id(weaponEnt)
	
	if(!is_user_alive(iOwner))	return HAM_IGNORED;
	
	new iRet;
	
	ExecuteForward( getForwardMulti( MULTI_WEAPON_DEPLOY ) ,iRet,iOwner,iWpnID , weaponEnt );
	
	if(bow[iOwner])
	{
		bow[iOwner] = false;
		
		if(iWpnID == CSW_KNIFE)
		{
			entity_set_string(iOwner, EV_SZ_viewmodel, 	KNIFE_VIEW );  
			entity_set_string(iOwner, EV_SZ_weaponmodel, 	KNIFE_PLAYER );  
		}
	}
	
	return HAM_IGNORED;
}

public fwSpeedChange( id ){
	if( !is_user_alive( id ) ){
		return HAM_IGNORED;
	}
	
	if(!bFreezeTime)	speedChange(id);
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MUTLI_CUR_WEAPON ) , id );
	
	return HAM_IGNORED;
}

public renderChange(id){
	if(!is_user_alive(id))	return PLUGIN_CONTINUE;
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MULTI_RENDER_CHANGE ) ,id);
	
	new iPos = ArraySize(playerInfRender[id]) - 1,iOutput[8];
	
	if( iPos < 0 ){
		return PLUGIN_CONTINUE;
	}
	
	ArrayGetArray(playerInfRender[id],iPos,iOutput);
	
	set_user_rendering(id,iOutput[renderFx],iOutput[renderR],iOutput[renderG],iOutput[renderB],iOutput[renderNormal],iOutput[renderAmount]);
	
	remove_task( id + TASK_RENDER );
	
	if(Float:iOutput[6] != 0.0){
		
		set_task(Float:iOutput[6] - get_gametime(),"renderEnded",id + TASK_RENDER);
	}
	
	return PLUGIN_CONTINUE;
}	

public renderEnded(id){
	id	-=	TASK_RENDER;
	
	clearRender(id);
	renderChange(id);
}

public gravChange(id){
	if(!is_user_alive(id))	return PLUGIN_CONTINUE;
	
	set_user_gravity(id,Float:playerInf[id][userGrav]);
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MULTI_GRAV_CHANGE ) , id );
	
	return PLUGIN_CONTINUE;
}

public speedChange(id){
	if(!is_user_alive(id) || bFreezeTime)	return PLUGIN_CONTINUE;
	
	set_user_maxspeed(id,Float:playerInf[id][currentSpeed]);
	
	engfunc( EngFunc_SetClientMaxspeed , id , Float:playerInf[id][currentSpeed] )
	
	dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) );
	
	return PLUGIN_CONTINUE;
}

public fwSpawned(id){
	if(!is_user_alive(id))	return HAM_IGNORED;
	
	if(bFirstRespawn[id]){
		
		bFirstRespawn[id] = false;
		
		new szName[64]
		get_user_name(id,szName,charsmax( szName ));
		
		ColorChat(id, GREEN ,"%s %s witaj w Diablo Mod Core napisanym przez DarkGL", PREFIX_SAY , szName)
	}
	
	playerInf[id][maxHp]				=	ArrayGetCell(gClassHp, getPlayerClass( id ) ) + (getUserStr( id ) * get_pcvar_num( pCvarStrPower ))
	playerInf[id][castTime]			=	_:0.0;
	playerInf[id][currentSpeed]		=	_:(BASE_SPEED + ( float( getUserDex( id ) ) * 1.3));
	playerInf[id][maxKnife]			=	0;
	playerInf[id][howMuchKnife]		=	0;
	playerInf[id][tossDelay]			=	_:0.0;
	playerInf[id][userGrav]			=	_:1.0;
	playerInf[id][extraStr]		=	0;
	playerInf[id][extraInt]		=	0;
	playerInf[id][extraDex]		=	0;
	playerInf[id][extraAgi]		=	0;
	
	g_GrenadeTrap[id]				=	false;
	bHasBow[id]						=	0;
	bowdelay[id]					=	get_gametime();
	
	ArrayClear(playerInfRender[id]);
	new iInputRedner[8];
	
	iInputRedner[0]	=	255;
	iInputRedner[1]	=	255
	iInputRedner[2]	=	255
	iInputRedner[3]	=	kRenderFxNone;
	iInputRedner[4]	=	kRenderNormal;
	iInputRedner[5]	=	16;
	iInputRedner[6]	=	_:0.0;
	iInputRedner[7]	=	0;
	
	ArrayPushArray(playerInfRender[id],iInputRedner);
	
	bWasducking[id]	=	false;
	
	if( isPlayerClassNone( id ) ){
		wybierzKlase(id);
	}
	
	if( !isPlayerClassNone( id ) ){
		if( playerInf[id][currentPoints] > 0 ){
			playerPointsMenu(id);
		}
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SPAWNED ) ,id);
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( id ) , CLASS_SET_DATA ), id);
	}
	
	if( !isPlayerItemNone( id ) ){
		ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_PLAYER_SPAWNED ) , id );
	}
	
	ExecuteForwardIgnoreIntOneParam( getForwardMulti( MULTI_PLAYER_SPAWNED ) , id);
	
	playerInf[id][howMuchKnife]		=	playerInf[id][maxKnife];
	
	set_user_health( id , playerInf[id][maxHp] );
	
	cs_set_user_armor( id , playerInf[id][currentArmor] * 2 , CS_ARMOR_VESTHELM);
	
	new iEnt	=	-1;
	
	while( ( iEnt = find_ent_by_owner( iEnt , CLASS_NAME_CORSPE , id ) ) != 0 ) if( pev_valid( iEnt ) )	remove_entity( iEnt );
	
	clearRender(id);
	renderChange(id);
	gravChange(id);
	
	return HAM_IGNORED;
}

public DeathMsg(){
	new iVictim = read_data(2);
	new iKiller = read_data(1);
	
	if(!is_user_connected( iVictim ) || !is_user_connected( iKiller ) || iKiller == iVictim || get_user_team( iVictim ) == get_user_team( iKiller ) || is_user_alive( iVictim ) )	return PLUGIN_CONTINUE;
	
	new iRet;
	
	if( !isPlayerClassNone( iVictim ) ){
		
		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( iVictim ) , CLASS_CLEAN_DATA ) ,iVictim);

		ExecuteForwardIgnoreIntOneParam( getForwardClass( getPlayerClass( iVictim ) , CLASS_KILLED ) , iVictim);
	}
	
	ExecuteForward( getForwardMulti( MULTI_DEATH ),iRet,iKiller , getPlayerClass( iKiller ), iVictim , getPlayerClass( iVictim ) );
	
	killXP(iKiller,iVictim);
	
	remove_task(iVictim + TASK_DEATH);
	
	set_task(0.5, "checkDeathFlag", iVictim + TASK_DEATH , .flags = "b")
	
	new Float:fSize[3]
	pev(iVictim, pev_mins, fSize)
	
	if(fSize[2] == -18.0)	bWasducking[iVictim] = true
	else					bWasducking[iVictim] = false
	
	if( isPlayerItemNone( iKiller ) ){
		giveUserItem( iKiller );
	}
	
	if( !isPlayerItemNone( iVictim ) ){
		playerInf[iVictim][itemDurability] -=	get_pcvar_num( pCvarDurability )
		checkItemDurability( iVictim );
	}
	
	cs_set_user_money( iKiller , cs_get_user_money( iKiller ) + playerInf[iKiller][currentLuck] * 10 );
	
	return PLUGIN_CONTINUE;
}

public bool:checkItemDurability( id ){
	if( playerInf[id][itemDurability] <= 0 && !isPlayerItemNone( id ) ){
		set_hudmessage ( 255, 0, 0, -1.0, 0.4, 0, 1.0,2.0, 0.1, 0.2, -1 );
		show_hudmessage( id, "Przedmiot stracil swoja wytrzymalosc!" );
		
		setPlayerItem( id , 0 );
		
		return false;
	}
	
	return true;
}

bool: giveUserItem( id , iItem = 0){
	new iRandom = 0;
	
	if( !iItem ){
		new Array: itemsIDs = ArrayCreate( 1 , 10 );
	
		for( new iCurrentItem = 1; iCurrentItem < ArraySize( gItemName ); iCurrentItem++ ){
			if( ( ArrayGetCell( gItemFrom , iCurrentItem ) && ArrayGetCell( gItemFrom , iCurrentItem ) > getPlayerLevel( id ) ) || ( ArrayGetCell( gItemTo , iCurrentItem ) && ArrayGetCell( gItemTo , iCurrentItem ) < getPlayerLevel( id ) ) ){
				continue;
			}
			
			ArrayPushCell( itemsIDs , iCurrentItem );
		}
		
		if( ArraySize( itemsIDs ) == 0 ){
			iRandom = 0;
		}
		else{
			iRandom = ArrayGetCell( itemsIDs , random_num( 0 , ArraySize( itemsIDs ) - 1 ) );
		}
		
		ArrayDestroy( itemsIDs );
	}
	else{
		iRandom	=	iItem;
	}
	
	if( !setPlayerItem( id , iRandom , ArrayGetCell( gItemDur , iRandom ) ) ){
		return false;
	}
	
	new  iRet , szRet[ 256 ];
	
	ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_SET_DATA ) , id );
	
	new iArrayPass = PrepareArray(szRet,256,1)
	
	ExecuteForward( getForwardItem( getPlayerItem( id ) , ITEM_GIVE ) , iRet , id , iArrayPass , charsmax( szRet ) );
	
	new szName[ MAX_LEN_NAME ];
	
	ArrayGetString( gItemName , iRandom , szName , charsmax( szName ) );
	
	set_hudmessage(220, 115, 70, -1.0, 0.40, 0, 3.0, 4.0, 0.2, 0.3, 5)
	show_hudmessage(id, "Znalazles przedmiot: %s :: %s", szName , szRet );
	
	ExecuteForwardIgnoreIntTwoParam( getForwardMulti( MULTI_GIVE_ITEM ) , id , iRandom );
	
	return true;
}

public checkDeathFlag(id)
{
	id -= TASK_DEATH;
	
	if(!is_user_connected(id)){
		remove_task(id + TASK_DEATH);
		return ;
	}
	
	if(pev(id, pev_deadflag) == DEAD_DEAD){
		
		remove_task(id + TASK_DEATH);
		
		createFakeCorpse(id)
	}
}	

public createFakeCorpse(id)
{
	set_pev(id, pev_effects, EF_NODRAW)
	
	static szModel[32]
	cs_get_user_model(id,szModel, charsmax( szModel ))
	
	static player_model[64]
	formatex(player_model, charsmax( player_model ), "models/player/%s/%s.mdl", szModel, szModel)
	
	static Float: player_origin[3]
	pev(id, pev_origin, player_origin)
	
	static Float:mins[3]
	mins[0] = -16.0
	mins[1] = -16.0
	mins[2] = -34.0
	
	static Float:maxs[3]
	maxs[0] = 16.0
	maxs[1] = 16.0
	maxs[2] = 34.0
	
	if(bWasducking[id])
	{
		mins[2] /= 2
		maxs[2] /= 2
	}
	
	static Float:player_angles[3]
	pev(id, pev_angles, player_angles)
	player_angles[2] = 0.0
	
	new sequence = pev(id, pev_sequence)
	
	new ent = fm_create_entity("info_target")
	if(ent)
	{
		set_pev(ent, pev_classname, CLASS_NAME_CORSPE)
		engfunc(EngFunc_SetModel, ent, player_model)
		engfunc(EngFunc_SetOrigin, ent, player_origin)
		engfunc(EngFunc_SetSize, ent, mins, maxs)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
		set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		set_pev(ent, pev_owner, id)
		set_pev(ent, pev_angles, player_angles)
		set_pev(ent, pev_sequence, sequence)
		set_pev(ent, pev_frame, 9999.9)
	}	
}

showMotd(id,szTitle[] = "",szItemName[] = "",szValue = -1 ,szDur = -1,szEffect[] = "",szDesc[] = "")
{
	
	new szData[1024],iLen = 0;
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<html><head><title>%s</title></head>",szTitle)
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<body text=^"#FFFF00^" bgcolor=^"#000000^">")
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<center><table border=^"0^" cellpadding=^"0^" cellspacing=^"0^" style=^"border-collapse: collapse^" width=^"100%s^"><tr>","^%")
	
	if( !equal(szItemName,"") )	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<td width=^"0^"><p align=^"center^"><font face=^"Arial^"><font color=^"#FFCC00^"><b>Przedmiot: </b>%s</font><br>",szItemName)
	
	if( szValue != -1 )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Wartosc: </b>%d</font><br>",szValue)
	
	if( szDur != -1 )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Wytrzymalosc: </b>%d</font><br><br>",szDur)
	
	if( !equal(szEffect,"") )	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Efekt:</b> %s</font></td>",szEffect)
	
	if( !equal(szDesc,"") )		iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"<font color=^"#FFCC00^"><b><br>Opis:</b> %s</font></td>",szDesc)
	
	iLen += formatex(szData[iLen],charsmax( szData ) - iLen,"</font></tr></table></center></body></html>")
	
	show_motd(id,szData, szTitle)	
}

/*---------------------Rzucanie nozami---------------------*/

public commandKnife(id) 
{

	if(!is_user_alive(id)) return PLUGIN_HANDLED

	if(!playerInf[id][howMuchKnife])
	{
		client_print(id,print_center,"Nie masz juz nozy do rzucania")
		return PLUGIN_HANDLED
	}

	if(Float:playerInf[id][tossDelay] > get_gametime() - 0.9) return PLUGIN_HANDLED
	else playerInf[id][tossDelay] = _:get_gametime()

	playerInf[id][howMuchKnife]--

	if (playerInf[id][howMuchKnife] == 1) {
		client_print(id,print_center,"Zostal ci tylko 1 noz!")
	}
	else {
		client_print(id,print_center,"Zostalo ci tylko %d nozy !",playerInf[id][howMuchKnife])
	}

	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent

	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)

	Ent = create_entity("info_target")

	if (!Ent) return PLUGIN_HANDLED

	entity_set_string(Ent, EV_SZ_classname, THROW_KNIFE_CLASS)
	entity_set_model(Ent, THROW_KNIFE_MODEL)

	new Float:MinBox[3] = {-1.0, -7.0, -1.0}
	new Float:MaxBox[3] = {1.0, 7.0, 1.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)

	vAngle[0] -= 90

	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)

	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 6)
	entity_set_edict(Ent, EV_ENT_owner, id)

	VelocityByAim(id, get_pcvar_num(pCvarKnifeSpeed) , Velocity)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	return PLUGIN_HANDLED
}

public touchKnife( knife, id ){
	
	if( !is_valid_ent( knife ) ){
		return PLUGIN_CONTINUE;
	}
	
	new kid = entity_get_edict(knife, EV_ENT_owner)
	
	new classname[ 64 ];
	
	if(is_valid_ent( id  )) {
		if( entity_get_int(id, EV_INT_solid) == SOLID_TRIGGER ){
			return PLUGIN_CONTINUE;
		}

		entity_get_string(id, EV_SZ_classname, classname, charsmax( classname ) );
	}
	
	if(is_user_alive(id)) 
	{
		new movetype = entity_get_int(knife, EV_INT_movetype)
		
		if(movetype == 0) 
		{
			if( playerInf[id][howMuchKnife] < playerInf[id][maxKnife] )
			{
				playerInf[id][howMuchKnife] += 1
				client_print(id,print_center,"Obecna liczba nozy: %i",playerInf[id][howMuchKnife])
			}
			emit_sound(knife, CHAN_ITEM, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			remove_entity( knife );
		}
		else
		{
			if( kid == id ){
				return PLUGIN_CONTINUE;
			}

			remove_entity(knife)

			if( !get_pcvar_num( pCvarFriendlyFire ) && cs_get_user_team( id ) == cs_get_user_team( kid ) ){
				return PLUGIN_CONTINUE;
			}

			doDamage(id,kid,get_pcvar_float(pCvarKnife),diabloDamageKnife);
			
			screenShake( id , 7<<14 , 1<<13 , 1<<14 )	
			
			emit_sound( id , CHAN_ITEM , "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
		}
	}
	else if(equal( classname , "func_breakable" ) ) {
		touchKnifeBreakAble( knife , id );
	}
	else if( !equal( classname, THROW_KNIFE_CLASS ) ) {
		entity_set_int( knife, EV_INT_movetype, 0)
		emit_sound (knife, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return PLUGIN_CONTINUE;
}

public touchKnifeBreakAbleWrap( iBreakAble , iEnt ){
	return touchKnifeBreakAble( iEnt , iBreakAble );
}

public touchKnifeBreakAble( iEnt , iBreakAble ){
	if( !pev_valid( iEnt ) ){
		return PLUGIN_CONTINUE;
	}
	
	if( pev(iBreakAble,pev_takedamage) && pev(iBreakAble, pev_health)){
		
		new Float: b_hp = entity_get_float(iBreakAble,EV_FL_health)
		
		if(b_hp > get_pcvar_float(pCvarKnife)){
			entity_set_float(iBreakAble,EV_FL_health,b_hp - get_pcvar_float(pCvarKnife) )
		}
		else{
			dllfunc(DLLFunc_Use,iBreakAble,iEnt)
		}
	}
	
	emit_sound(iEnt, CHAN_ITEM, "weapons/knife_hitwall1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	
	return PLUGIN_CONTINUE;
}

#if defined BOTY
bool:checkMode( ENT ){
	new iRender	=	pev( ENT , pev_rendermode )
	
	return ( iRender != kRenderTransColor && iRender != kRenderTransTexture && iRender != kRenderTransAlpha && iRender != kRenderTransAdd );
}

public fwAddToFullPack( es_handle, e, ENT, HOST, hostflags, player, set){
	if( !player || !is_user_alive( HOST ) || !is_user_bot( HOST ) || !checkMode( ENT ) )	
		return	FMRES_IGNORED;
	
	new iAmount	=	pev( ENT , pev_renderamt );
	
	if( iAmount == 0 || ( iAmount <= 127 && random_num( 0 , iAmount / 50 ) == 0 ) ){
		set_es( es_handle , ES_Origin , { -8192.0 , -8192.0 , -8192.0 } )
	}
	
	return	FMRES_IGNORED;
}
#endif

/*---------------------STOCKS---------------------*/

stock bool:is_steam(id) {
	
	new szAuth[64];
	
	get_user_authid(id,szAuth,charsmax( szAuth ) );
	
	if(contain(szAuth, "STEAM_0:0:") != -1 || contain(szAuth, "STEAM_0:1:") != -1)
	return true;
	
	return false;
}

stock bloodEffect(id,iColor){
	new Float:fOrigin[3]
	pev(id,pev_origin,fOrigin)
	
	new Float:dx, Float:dy, Float:dz
	
	for(new i = 0; i < 3; i++) 
	{
		dx = random_float(-15.0,15.0)
		dy = random_float(-15.0,15.0)
		dz = random_float(-20.0,25.0)
		
		for(new j = 0; j < 2; j++) 
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord , fOrigin[0] + ( dx*j ) )
			engfunc(EngFunc_WriteCoord , fOrigin[1] + ( dy*j ) )
			engfunc(EngFunc_WriteCoord , fOrigin[2] + ( dz*j ) )
			write_short(spriteBloodSpray)
			write_short(spriteBloodDrop)
			write_byte(iColor) // color index
			write_byte(8) // size
			message_end()
		}
	}
}

stock bool:UTIL_In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
	return true
	
	return false
}

stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2]
	new Float:flDot	
	new Float:CoreOrigin[3]
	new Float:TargetOrigin[3]
	new Float:CoreAngles[3]
	
	pev(Core,pev_origin,CoreOrigin)
	pev(Target,pev_origin,TargetOrigin)
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
	return 0.0
	
	pev(Core,pev_angles, CoreAngles)
	
	for ( new i = 0; i < 2; i++ )
	vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i]
	
	new Float:veclength = Vec2DLength(vec2LOS)
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[0] = 0.0
		vec2LOS[1] = 0.0
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[0] = vec2LOS[0]*flLen
		vec2LOS[1] = vec2LOS[1]*flLen
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles)
	
	new Float:v_forward[3]
	new Float:v_forward2D[2]
	get_global_vector(GL_v_forward, v_forward)
	
	v_forward2D[0] = v_forward[0]
	v_forward2D[1] = v_forward[1]
	
	flDot = vec2LOS[0]*v_forward2D[0]+vec2LOS[1]*v_forward2D[1]
	
	if ( flDot > 0.5 )
	{
		return flDot
	}
	
	return 0.0	
}

stock Float:Vec2DLength( Float:Vec[2] )  
{ 
	return floatsqroot(Vec[0]*Vec[0] + Vec[1]*Vec[1] )
}

stock getLevelXP( level ){
	#if defined EXP_TABLE
	return LevelXP[ level ];
	#else
	return power( level , 2 ) * get_pcvar_num( pCvarLevelPropotion );
	#endif
}

stock getMaxLevel(){
	#if defined EXP_TABLE
	return MAX_LEVEL;
	#else
	return get_pcvar_num( pCvarMaxLevel );
	#endif
}

getPlayerClass( id ){
	return playerInf[ id ][ currentClass ];
}

setPlayerClass( id , class ){
	playerInf[ id ][ currentClass ]	=	class;
}

getPlayerLevel( id ){
	return playerInf[ id ][ currentLevel ];
}

bool: isPlayerClassNone( id ){
	return getPlayerClass( id ) == 0;
}

bool: isPlayerItemNone( id ){
	return getPlayerItem( id ) == 0;
}

getPlayerItem( id ){
	return playerInf[ id ][ currentItem ];
}

bool: setPlayerItem( id , item , itemDurabilityParam = 0 ){
	if( !is_user_connected( id ) || isPlayerClassNone( id ) ){
		return false;
	}
	
	if( item < 0 || item >= ArraySize( gItemName ) ){
		return false;
	}
	
	if( ( ArrayGetCell( gItemFrom , item ) && ArrayGetCell( gItemFrom , item ) > getPlayerLevel( id ) ) || ( ArrayGetCell( gItemTo , item ) && ArrayGetCell( gItemTo , item ) < getPlayerLevel( id ) ) ){
		return false;
	}
	
	if( !isPlayerItemNone( id ) ){
		ExecuteForwardIgnoreIntOneParam( getForwardItem( getPlayerItem( id ) , ITEM_RESET ) , id );
	}
	
	playerInf[ id ][ currentItem ]		=	item;
	playerInf[ id ][ itemDurability ]	=	itemDurabilityParam;
	
	if( item == 0 ){
		playerInf[ id ][ itemDurability ]	=	0;
	}
	
	return true;
}

getForwardClass( classID , forwardsStructureClass: position ){
	new tmpArrayClass[ forwardsStructureClass ];
	
	ArrayGetArray( gForwardsClass , classID , tmpArrayClass );
	
	return tmpArrayClass[ position ];
}


getForwardItem( itemID , forwardsStructureItem: position ){
	new tmpArrayItem[ forwardsStructureItem ];
	
	ArrayGetArray( gForwardsItem , itemID , tmpArrayItem );
	
	return tmpArrayItem[ position ];
}

getForwardMulti( forwardsMulti: position ){
	return gForwardsMulti[ position ];
}

ExecuteForwardIgnoreIntNoParam( forward_handle ){
	static iRet;
	
	return ExecuteForward( forward_handle , iRet );
}

ExecuteForwardIgnoreIntOneParam( forward_handle , paramOne ){
	static iRet;
	
	return ExecuteForward( forward_handle , iRet , paramOne );
}

ExecuteForwardIgnoreIntTwoParam( forward_handle , paramOne , paramTwo ){
	static iRet;
	
	return ExecuteForward( forward_handle , iRet , paramOne , paramTwo );
}

logDiablo( const szFormat[ 256 ] , any:... ){
	new szMessage[ 256 ];
	
	vformat( szMessage , charsmax( szMessage ) , szFormat , 2 );
	
	log_to_file( fileLogPath , szMessage );
}

stock makeBarTimer( id , iTime ){
	static gmsgBartimer;
	
	if( !gmsgBartimer ){
		gmsgBartimer =	get_user_msgid("BarTime");
	}
	
	message_begin( id ? MSG_ONE : MSG_ALL , gmsgBartimer, {0,0,0}, id ) 
	write_byte( iTime ) 
	write_byte( 0 )
	message_end()
}

Ham:get_player_resetmaxspeed_func(){
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed)?Ham_CS_Player_ResetMaxSpeed:Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}

#include "nativesDiablo.inc"