
 ////////////////////////////////////////////////
 //     ___      _                         _   //
 //    / _ \___ | | _____  /\/\   ___   __| |  //
 //   / /_)/ _ \| |/ / _ \/    \ / _ \ / _` |  //
 //  / ___/ (_) |   <  __/ /\/\ \ (_) | (_| |  //
 // /_/    \___/|_|\_\___\/    \/\___/ \__,_|  //
 //                                            //
 ////////////////////////////////////////////////
 //                                            //
 //      Welcome to The World of Pokemon.      //
 //                                            //
 ////////////////////////////////////////////////

 /*
 //--ChangeLog--//
 *	v1.2.3 RC 2 - 0?/??/08
 *							- Fixed some problems with skills
 *							- Fixed some default skill/pokemon properties
 *							- New define TOUCH_SKILL_TEAM in custom.inl
 *							- Fixed "okemon" in PokeMart menu
 *							- Catch items with over 1000 chance will now catch pokemon with 'e' flag and pokemon above MAX_CATCH_LEVEL
 *							- Fixed problem with admin commands effecting @TEAMS
 *							- Fixed problem with first pokeitem being named "None"
 *							- Evolved pokemon can now be caught off the ground if they don't have the 'c' flag
 *							- New define in custom.inl SAVE_ID
 *							- More optimizations
 *							- Fixed problem with global skills not getting correct level
 *							- Renamed pokemon files to be more appropriate
 *							- New flag 'e' in pokemon.ini to disallow pokemon from being caught (removed define CATCH_SPECIAL from custom.inl)
 *							- Renamed MAX_CATCH_LEVEL to CATCH_MAX_LEVEL in custom.inl
 *							- New define CATCH_GHOST in custom.inl
 *							- Removed FASTSPEED and SLOWSPEED from custom.inl (they have been seperated)
 *							- More defines in skill_defines.inl
 *							- New define OAK_RESET_SKILLS in custom.inl
 *							- Made all skills independent of eachother (you don't need Rage for Counter to work, etc.)
 *							- Added pokemon images in pokedex and other motd windows
 *							- New define POKEDEX_IMAGES in custom.inl
 *							- Added partial MultiLingual Support
 *							- Fixed problem with pokerank being erased
 *							- Added checks to prevent crashing from over precaching
 *							- Changed MultiForwards
 *							- Removed unnecessary SQLX support
 *							- Fixed screenshake message
 *							- 
 *	v1.2.3 RC - 05/27/08
 *							- Dropped skill forwards
 *							- Converted skill system to prepare for 1.3.0
 *							- Seperated skills into more files
 *							- Added maxarmor capabilities
 *							- Updated pokemod.inc
 *							- Converted some file natives to new file natives
 *							- Adjusted pokemon skills to damage based on skill type instead of pokemon type
 *							- Added functionality to change how skills are activated
 *							- Fixed potential bug when exiting Bill's PC
 *							- Every skill should be able to be global with new system
 *							- Added some more important debug messages
 *							- Changed the items.cfg file a little bit
 *							- Fixed small bug in pokemart that would show all categories
 *							- Renamed Bill's PC to Emp`s PC
 *							- Fixed bug where safari file would stay open
 *							- Can now change starting pokemon
 *							- Dropped support for other plugins with speed (got too complicated)
 *							- Added functions for skill damage for more universal use
 *							- Changed how delays after pokeskills work
 *							- Minor code improvements
 *							- Fixed being able to manually activate non-bind skills
 *							- Converted sprite system to match sounds and models
 *							- Added random player round saving
 *							- Fixed not being able to do command 'pokemod debug off'
 *							- Renamed config.inl to files.inl
 *							- Made find_free_spawn function more efficient
 *							- When doing 'pokemod' in console and the server is missing files, it will now list the files
 *							- Fixed define POKEBALL_SPECIAL
 *							- Redid pokedex
 *							- Made help menu smarter
 *							- Made pokedex smarter
 *							- Redid pokeitem help
 *							- Fixed problem where last pokemon's name would not be picked up
 *							- Changed NightShade to not go below MIN_INVIS
 *							- Finished all default pokemon
 *							- Fixed problem with round start being called at the wrong time with freezetime
 *							- Fixed problem when admins erased all experience
 *							- Burn will now catch all players on fire (not just teammates)
 *							- Added smarter item searching
 *							- Fixed problem with paralysis
 *							- Can no longer release or give away your active pokemon
 *							- Fixed bug where you would try to catch pokemon with items that can't catch
 *							- Fixed problem with many fake natives
 *							- Fixed problem with picking up the first registered item
 *							- Added flexibility to interact with EAM
 *							- Fixed Start Menu not working if you were assigned a pokemon
 *							- Redid menu code
 *	v1.2.2 - 02/01/08
 *							- Dropped hamsandwich module and added back fun module
 *							- Fixed and cleaned AoEdamage and Linedamage
 *							- Fixed speed issue that was occuring
 *	v1.2.1 - 01/26/08
 *							- Fixed fire status
 *							- Fixed harden skill
 *							- Fixed menus not working occasionally
 *							- Fixed mist and sky attack not displaying in correct position
 *							- Redid type system to prepare for 1.3.0
 *							- Added status effects for normal pokedamage function
 *							- Redid how status effects are calculated in pokedamage
 *							- Added type None
 *							- Added prefix TYPE_ to the type defines/enum
 *							- Redid admin commands
 *							- Fixed weird damages with AoE and Line damage
 *							- Dropped engine module, now uses fakemeta_util
 *							- Dropped fun module, now uses fakemeta and hamsandwich
 *							- Removed time include
 *							- Now requires Hamsandwich module
 *							- Fixed rock slide skill
 *							- Bots now release pokemon randomly
 *							- Fixed global skills being able to be done twice
 *							- Fixed dodrio
 *
 *	v1.2.0 - 12/24/07
 *							- Seperated into smaller files
 *							- Added xp and lvls
 *							- Added more pokemon
 *							- And a lot more (for full list, check PokeMod forums)
 *							- Now requires AMXX 1.8 or greater
 *
 *	v1.1.1 - 07/06/06
 *							- Fixed some things
 *							- Added some cvars
 *							- Cleaned code
 *							- Made a little bit ready for when lvls and xp are added
 *
 *	v1.1.0 - 06/29/06
 *							- Redid menus
 *							- Added more pokemon (33 in total)
 *							- Cleaned code
 *							- Changed cvars to pcvars
 *							- Now requires AMXX 1.71 or greater
 *
 *	v1.0.1 - Never Released
 *							- Fixed some stuff
 *							- Cleaned code
 *							- Added more cvars
 *
 *	v1.0.0 - 01/15/06
 *							- Released to the public
 *
 //--Credits--//
 *	- RockThrow				- modified sprites and sounds code from yang's Veronika hero
 *	- Teleport				- used PassAimTest code from sharky / JTP10181 's Batgirl hero
 *	- Flamethrower			- modified Cheap_Suit's flamethrower
 *							- KoST - for the get_distance_to_line stock
 *							- VEN - for his fm_is_ent_visible stock
 *	- PsyBeam				- based on vittu's SSJ Gohan hero
 *	- SmokeScreen			- made by Om3gA
 *
 *	- Config files			- based on superheromod's
 *	- XP Save key			- based on superheromod's
 *	- Sounds				- used some sounds from FFX mod
 *	- Models				- used Prof. Oak model from old abandoned Pokemon Mod for Half-Life
 *							- original pokeball made by Emp`, fixed by Om3gA
 *							- bone model made by coca-cola
 *	- PokeLoop				- used loop code from {HOJ} Batman/JTP10181 's Captain America hero
 *	- NPCs					- used Twilight Suzuka's NPC guide
 *	- MYSQL Saving			- Superhero Mod
 *	- SQLx Saving			- Teame06
 *	- Dynamic Natives		- help from Hawk552
 *	- Other					- modified mole code from WC3FT mod
 *							- is_user_outside stock from timer16 by Twilight Suzuka
 *
 *		- Anything not listed here was most likely done by Emp`
 *
 //--To Do--//
 *	- Personal colored huds
 *	- PP points
 *	- Read files rather than having defines
 *	- Personal Pokemon Names
 *	- Pokemon skill selection
 *	- Dynamic skill properties
 *	- Dynamic statuses
 *	- More fake natives
 */





	///////////////////////////////////////////////////
	//        DO NOT CHANGE ANYTHING IN HERE!        //
	//      Things for customizing your server       //
	//            have been moved to the             //
	//      _custom.inl and _skill_defines.inl       //
	///////////////////////////////////////////////////





 #if defined _pokemod_plugin_included
	#endinput
 #endif
 #define _pokemod_plugin_included

 //Lets increase the memory
 #pragma dynamic 32768

 //Change the stupid escape character to the normal one
 #pragma ctrlchar '\'

 //Lets load some libraries
 #include <amxmisc>
 #include <fakemeta_util>
 #include <fun>
 #include <xs>

 #if AMXX_VERSION_NUM < 180
	#assert _____\
			PokeMod requires AMXX 1.8 or higher and must be compiled locally!\
			_____
 #endif

 //PokeMod includes
 #tryinclude "pokemon/custom.inl"	//gotta include these first because its used in the other files
 #tryinclude "pokemon/defines.inl"

 #if !defined _pokemod_custom_included || !defined _pokemod_defines_included
	#assert _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ \
			_ _ _ _ _ _ _ _ _ _ _ PokeMod must be compiled locally! _ _ _ _ _ _ _ _ _ _ _ \
			_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
 #endif

 #if MOD==CS
	#include <cstrike>
 #endif
 #if MOD==DOD
	#include <dodfun>
	#include <dodx>
 #endif
 #if MOD==NS
	#include <ns>
 #endif

 #if SAVE==SAVE_MYSQL
	#include <dbi>
 #endif
 #if SAVE==SAVE_NVAULT
	#include <nvault>
 #endif

 native pokemod_check_account(id);
 native check_small_map();
 
 #include "pokemon/skill_defines.inl"
 #include "pokemon/globals.inl"
 #include "pokemon/other.inl"

 #include "pokemon/admin.inl"
 #include "pokemon/bot.inl"
 #include "pokemon/items.inl"
 #include "pokemon/checks.inl"
 #include "pokemon/eam.inl"
 #include "pokemon/evolution.inl"
 #include "pokemon/files.inl"
 #include "pokemon/helps.inl"
 #include "pokemon/menus.inl"
 #include "pokemon/mod_specific.inl"
 #include "pokemon/natives.inl"
 #include "pokemon/oak.inl"
 #include "pokemon/pokedamage.inl"
 #include "pokemon/pokerank.inl"
 #include "pokemon/publics.inl"
 #include "pokemon/registers.inl"
 #include "pokemon/skills.inl"
 #include "pokemon/status.inl"
 #include "pokemon/stocks.inl"
 #include "pokemon/xp.inl"

 /////////////////////
 //  Starts plugin  //
 /////////////////////
 public plugin_init()
 {
	plugin_id = register_plugin(PLUGNAME, VERSION, AUTHOR);

	//lets register the most important things first (incase pokemod was disabled)

	set_pcvar_string( register_cvar("PokeMod_Version",VERSION,FCVAR_SERVER|FCVAR_SPONLY), VERSION );

	register_concmd("pokemod","Console_Pokemod",ADMIN_ALL, "- information about PokeMod");
	register_concmd("pm","Console_Pokemod");

	//Client Say Commands
	register_clcmd("say","HandleSay");

	//if pokemod was disabled, we don't need to waste server resources
	if( PM_disabled == PM_OFF )
		return;

	cvar_registry();

	//Events
	#if MOD==CS
		register_event("Damage", "player_damage", "b", "2!0");
		register_event("HLTV", "round_start", "a", "1=0", "2=0");
		register_logevent("poke_round_end", 2, "1=Round_End");
		register_logevent("poke_round_end", 2, "1&Restart_Round_");
		register_event("StatusText", "pokemon_statustext", "b");
		register_event("ResetHUD", "pokemon_spawn", "b");
		register_event("Money", "pokemon_money", "b");
		register_message(get_user_msgid("Health"), "message_Health");
	#else
		#if MOD==DOD
			register_event("RoundState", "poke_round_end", "a", "1=3", "1=4");
		#endif
		#if MOD==NS
			register_event("Damage", "player_damage", "b", "2!0");
		#endif
		register_event("ResetHUD", "team_ready", "b");
	#endif
	register_event("DeathMsg", "pokemon_death", "a");
	register_event("CurWeapon", "WeaponChange", "be", "1=1");
	register_forward(FM_Touch, "touches");
	register_forward(FM_AddToFullPack, "forward_AddToFullPack", 1);

	#if CHANGE_GAME_NAME==1
	register_forward(FM_GetGameDescription,"GameDesc");
	#endif
	register_forward(FM_AlertMessage, "log_block");

	//Loop every second
	set_task(1.0, "pokemon_loop", 0, "", 0, "b");

	debugMessage( 0,7,"Init", "Done registering events" );

	//Client Console Commands
	register_clcmd("+pokeskill","pokeskill_down", _, "- uses pokemon bind skill");
	register_clcmd("-pokeskill","pokeskill_up");

	new command[32];
	for(new i=1; i <= MAX_SKILLS; i++){
		formatex(command, 31, "+pokeskill%d", i);
		register_clcmd(command,"pokeskill_down");
		formatex(command, 31, "-pokeskill%d", i);
		register_clcmd(command,"pokeskill_up");
	}

	register_clcmd("+pokeitem","pokeitem_down", _, "- brings up Item Menu");
	register_clcmd("-pokeitem","pokeitem_up");
	register_clcmd("pokeskill","updatecommands");		//this just tells them to rebind with a +
	register_clcmd("pokemart","Console_Pokemart");
	register_clcmd("fullupdate","fullupdate");			//this just blocks the fullupdate abuse

	//All Console Commands
	register_concmd("playerspokemon","Console_PlayersPokemon", _, "- shows everyones pokemon");	//views players pokemon
	register_concmd("playerspokes","Console_PlayersPokemon");											//views players pokemon
	register_concmd("playersitems","Console_PlayersItems", _, "- shows everyones items");		//views players items
	register_concmd("pokedex","Console_Pokedex", _, "- shows pokemon information");				//views pokedex
	register_concmd("pokeitem","Console_Pokeitem", _, "- shows pokeitem information");				//views pokeitem help

	#if POKERANK_SYSTEM==1
	//PokeRank Commands
	register_concmd("pokerank","Console_PlayersRanks", _, "- shows players PokeRanks");	//views players ranks
	#endif

	pokeadmin_init();

	debugMessage( 0,7,"Init", "Done registering commands" );

	//Global Messages
	gmsgScreenFade	= get_user_msgid("ScreenFade");
	gmsgScreenShake = get_user_msgid("ScreenShake");
	gmsgDeathMsg	= get_user_msgid("DeathMsg");
	gmsgScoreInfo	= get_user_msgid("ScoreInfo");
	gmsgDamage		= get_user_msgid("Damage");

	//MultiForwards - thanks to vittu && teame06
	PokePayForward = CreateMultiForward("poke_pay", ET_STOP, FP_CELL, FP_CELL);				//stop on return value, id, amount

	PlayerEventForward = CreateMultiForward("poke_player_event", ET_STOP, FP_CELL, FP_CELL);		//stop on return value, id, props
	ItemEventForward = CreateMultiForward("poke_item_event", ET_STOP, FP_CELL, FP_CELL, FP_CELL);		//stop on return value, id, props, item

	RegisterItemForward = CreateMultiForward("poke_register_item", ET_STOP);							//stop on return value

	debugMessage( 0,7,"Init", "Done making forwards" );

	HUDSYNC = CreateHudSyncObj();
	g_coloredMenus = colored_menus();

	set_task(1.0, "StartPokeMod", 1);
	set_task(SAVE_SPAM,"plugin_end",_,_,_,"d")
 }

 #if CHANGE_GAME_NAME==1
 public GameDesc()
 {
	forward_return(FMV_STRING,GAME_NAME);
	return FMRES_SUPERCEDE;
 }
 #endif

 public StartPokeMod(initial)
 {
	debugMessage( 0,7,EMPTY, LANG, 0, "POKEMOD_START", initial );
//	debugMessage( 0,7,"Starting PokeMod. Initial Start = %s", initial?"true":"false" );
	if(initial){
		#if ALLOW_WILD==1
			set_task(180.0, "WildMessage", 0, "", 0, "b");
		#endif

		#if SAVE==SAVE_MYSQL || SAVE==SAVE_NVAULT
			saving_init();
		#endif

		set_task(1.0, "poke_round_end");
		set_task(2.0, "round_start");
	}

	LoadConfig();

	set_task(1.0, "ReadXPs");
	set_task(2.0, "SetSafariLevels");
	set_task(2.5, "ReadSkills");
	set_task(3.0, "ReadItems", 0);
	set_task(3.5, "ReadPokemon", 0);
	set_task(4.0, "ReadItems", 1);
	set_task(4.5, "ReadPokemon", 1);
	set_task(5.0, "PokeModLoaded");
 }
 public PokeModLoaded()
 {
	PM_Loaded = true;
	load_all();
	debugMessage( 0,7,EMPTY,LANG, 0, "POKEMOD_LOADED" );
//	debugMessage( 0,7,"PokeMod has been Loaded." );
 }
 ///////////////////////
 //--Precached Items--//
 ///////////////////////
 public plugin_precache()
 {
	//load the multilingual file for pokemod
	register_dictionary("pokemod.txt");

	//register the debug cvars for debug messages
	register_pokecvar( pm_debug, cvar_default[pm_debug] );
	register_pokecvar( pm_debug_key, cvar_default[pm_debug_key] );

	spawnhookid = register_forward( FM_Spawn, "spawn_hook", 1);

	SetupConfig();

	new PokeFile[128];
	Poke_FileName( F_PokeMaps, PokeFile);

	if( file_exists(PokeFile) ){
		new Data[124], len;
		new mapname[32];
   		new line = 0;
		new bool:finding_map = true;

		get_mapname(mapname, 31);

		while( (line = read_file(PokeFile , line , Data , 123 , len) ) != 0 ){

			if( !ValidData( Data ) )
				continue;

			//Check the map
			if( equal(Data, LEFT_BRACKET, 1) ){
				replace(Data, 123, LEFT_BRACKET, EMPTY);
				replace(Data, 123, RIGHT_BRACKET, EMPTY);

				if( containi(Data,STAR)!=-1 ){
					replace_all(Data, 123, STAR, EMPTY)
					if(containi(mapname, Data)!=-1){	//deal with this map
						finding_map = false;
						continue;
					}
				}
				else if(equali(mapname, Data)){
					finding_map = false;
					continue;
				}
				else
					finding_map = true;
			}
			else if(!finding_map){	//do the commands
				if(equali(Data,"-disabled")){
					poke_error(LANG, 0, "POKEMOD_DISABLED");
					PM_disabled = PM_OFF;
					break;
				}
				else if(equali(Data,"-skills_off")){
					poke_error(LANG, 0, "POKEMOD_SKILLSDISABLED");
					PM_disabled = PM_XP;
					break;
				}
				else{
					//delay the command until after the mod has been loaded
					set_task(10.0, "delay_cmd",0,Data,strlen(Data));
				}
			}

		}
		debugMessage( 0,7,"Config", "Map File Loaded." );
	}
	else{
		ResetMapsConfig();
		debugMessage( 0,7,"Config", "Map File Reset." );
	}
 }
 public delay_cmd(Data[])
 {
	server_cmd(Data);
	server_exec();
 }
 public spawn_hook()
 {
	poke_precaches();
	unregister_forward( FM_Spawn, spawnhookid, 1 );
 }
 poke_precaches()
 {
	new i, PokeFile[128];

	if( PM_disabled == PM_ON ){
		debugMessage( 0,7,"Precache", "Starting." );

		//check if theres enough resources for pokemod, well just check the first file (the intro sound)
		formatex(PokeFile, 127, "%s%s", sound_directory, SOUNDS[0]);
		if( file_exists(PokeFile) || contain(SOUNDS[0],"pokemon")==-1 ){
			FoundSound[0] = true;

			// get resources used so far
			i = engfunc(EngFunc_PrecacheSound, SOUNDS[0]);

			debugMessage( _,7,"Precache", "First sound precached at %d", i );
			// add in the amount we will use in pokemod
			i += MAX_SND;
			debugMessage( _,7,"Precache", "Expecting to precache sounds to %d", i );

			if( i > 512 ){
				poke_error(LANG, 0, "POKEMOD_RESOURCES");
				PM_disabled = PM_OFF;
				return;
			}
		}
		//check for one model
		if( file_exists(MODELS_T[0]) || contain(MODELS_T[0],"pokemon")==-1 ){
			FoundModelT[0] = true;

			// get resources used so far
			i = engfunc(EngFunc_PrecacheModel, MODELS_T[0]);

			debugMessage( _,7,"Precache", "First model precached at %d", i );
			// add in the amount we will use in pokemod
			i += MAX_SPR + MAX_MDL + MAX_T_MDL;
			debugMessage( _,7,"Precache", "Expecting to precache models to %d", i );

			if( i > 512 ){
				poke_error(LANG, 0, "POKEMOD_RESOURCES");
				PM_disabled = PM_OFF;
				return;
			}
		}

		for(i=1; i<MAX_SND; i++)
			poke_precache_sound( i );
		for(i=1; i<MAX_T_MDL; i++)
			poke_precache_model_t( i );
		for(i=0; i<MAX_SPR; i++)
			poke_precache_sprite( i );
		for(i=0; i<MAX_MDL; i++)
			poke_precache_model( i );

		new missing = poke_missing_files();
		if( missing ){
			if( missing == 1 )
				poke_error(LANG, 0, "POKEMOD_MISSINGFILE");
			else
				poke_error(LANG, 0, "POKEMOD_MISSINGFILES");
			PM_disabled = PM_OFF;
		}

		debugMessage( 0,7,"Precache", "Done." );
	}
 }
 poke_precache_model(const i)
 {
	if(file_exists(MODELS[i]) || contain(MODELS[i],"pokemon")==-1){
		debugMessage( _,8,"Precache", "%d %s", engfunc(EngFunc_PrecacheModel, MODELS[i]) ,MODELS[i] );
		return (FoundModel[i] = true);
	}
	return false;
 }
 poke_precache_model_t(const i)
 {
	if(file_exists(MODELS_T[i]) || contain(MODELS_T[i],"pokemon")==-1){
		debugMessage( _,8,"Precache", "%d %s", engfunc(EngFunc_PrecacheModel, MODELS_T[i]) ,MODELS_T[i] );
		return (FoundModelT[i] = true);
	}
	return false;
 }
 poke_precache_sprite(const i)
 {
	if(file_exists(SPRITES[i]) || contain(SPRITES[i],"pokemon")==-1){
		debugMessage( _,8,"Precache", "%d %s", (SPRITE_INDEX[i] = engfunc(EngFunc_PrecacheModel, SPRITES[i])) ,SPRITES[i] );
		return (FoundSprite[i] = true);
	}
	return false;
 }
 poke_precache_sound(const i)
 {
	new sound_location[151];
	formatex(sound_location, 150, "%s%s", sound_directory, SOUNDS[i]);
	if(file_exists(sound_location) || contain(SOUNDS[i],"pokemon")==-1){
		debugMessage( _,8,"Precache", "%d %s", engfunc(EngFunc_PrecacheSound, SOUNDS[i]) ,SOUNDS[i] );
		return (FoundSound[i] = true);
	}
	return false;
 }
 poke_missing_files()
 {
	new i, files_missing = 0, tempfile[52];
	for(i=0; i<MAX_SND; i++){
		if( !FoundSound[i] ){
			formatex(tempfile, 51, "%s%s", sound_directory, SOUNDS[i]);
			poke_error( LANG,0,"POKEMOD_FILENOTFOUND", tempfile );
			files_missing++;
		}
	}
	for(i=0; i<MAX_SPR; i++){
		if( !FoundSprite[i] ){
			poke_error( LANG,0,"POKEMOD_FILENOTFOUND", SPRITES[i] );
			files_missing++;
		}
	}
	for(i=0; i<MAX_MDL; i++){
		if( !FoundModel[i] ){
			poke_error( LANG,0,"POKEMOD_FILENOTFOUND", MODELS[i] );
			files_missing++;
		}
	}
	for(i=0; i<MAX_T_MDL; i++){
		if( !FoundModelT[i] ){
			poke_error( LANG,0,"POKEMOD_FILENOTFOUND", MODELS_T[i] );
			files_missing++;
		}
	}
	return files_missing;
 }
 poke_error(const error[], any:...)
 {
	new output[256];
	vformat(output, 255, error, 2);
	log_amx(output);
 }
 public plugin_end()
 {
	if( PM_disabled == PM_OFF )
		return;

	// SAVE EVERYTHING...
	debugMessage( 0,3,"End", LANG, 0,"POKEMOD_FINALSAVES" );
	save_all();

	#if SAVE==SAVE_MYSQL
		//Final cleanup in the saving include
		saving_end();
	#endif

	cleanXP();
 }
 cvar_registry()
 {
	//CVARS used, but lets create them just incase ;)
	mp_freezetime = register_cvar("mp_freezetime","0");

	//These Cvars should be in the game already
	mp_friendlyfire = get_cvar_pointer("mp_friendlyfire");
	mp_logdetail = get_cvar_pointer("mp_logdetail");

	//PokeMod Cvars
	for(new i=0; i<MAX_CVARS; i++)
		register_pokecvar(i,cvar_default[i]);

	debugMessage( 0,7,"Init", "Done registering cvars." );
 }

 debugMessage(id=0, level=0, const key[], const msg[], any:... )
 {
	if( PM_disabled == PM_OFF )
		return;

	static debugMode;
	debugMode = get_ppcvar_num( pm_debug );

	if( debugMode < level && level )
		return;		//there is a level, but we arent looking that high

	if( id && debugger && id != debugger )
		return;		//its about someone, but its not the debugger

	static debug_key[51];
	get_ppcvar_string( pm_debug_key, debug_key, 50 );
	if( key[0] != '\0' && debug_key[0] != '\0' && containi(key,debug_key) == -1 )
		return;		//it didn't have the debug key in it

	static output[256];
	vformat( output, 255, msg, 5 );

	if( id > 0 && id <= MAX_PLAYERS ){
		static lastid;
		static name[32],authid[32], userid;

		if( lastid != id ){
			lastid = id;
			get_user_name( id, name, 31 );
			get_user_authid( id, authid, 31 );
			userid = get_user_userid( id );
		}
		if( userid > 0 )
			format( output, 255, "\"%s<%d><%s><%s>\" %s", name,userid,authid,PokeToName(Pokemon[id]), output );
	}

	if( output[0] == '\0' )
		return;

	if( debugMode )
		format( output, 255, "DEBUG %s: %s", key, output );

	switch(debugMode)
	{
		case 0: log_amx( output );				//no matter what, were going to log it
		case 1: log_amx( output );				//log it completely

		case 2..9: console_print( 0, output );	//higher the number, more it outputs

		case 10: log_amx( output );				//log everything (this is extremely crazy!)
	}
	if( debugger )
		console_print( debugger, output );		//put it in console of debugger
 }

