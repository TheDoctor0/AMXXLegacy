
/* Map Spawns Editor v1.0 update [2006-10-23]
http://forums.alliedmods.net/showthread.php?t=43660

   This plugin let you ( add & del & edit ) map spawns absolute easy.

What's for::
 * A lot of map have spawndeath & bad position & less spawns problem I know since I has made a server 5 months.
   How can we fix this? I use some tools todo this but it hard use and do something when you are playing the game.
   I got the way to do this, so I made this plugin.

 * How easy? 
   1, One plugin and use one menu you can do all thing.
   2, Edit spawns and shange spawns angle at anytime without restart server or reload map just use save function.
   3, Add & Del spawns just reload map once (you can Del all spawns if you want)
*/

/* Requirements::
   AMX Mod X 1.76a or greater
   Engine module
*/

/* Install Instructions::
 * put the lang file Map_Spawns_Editor.amxx to (addons\amxmodx\plugins) folder
 * put the lang file map_spawns_editor.txt to (addons\amxmodx\data\lang) folder
*/

/* Description::
   1,Load the map which need to be edit spawns.
   2,Join server with ADMIN_BAN and bind a key with amx_editor_menu command.
   3,Type amx_spawn_editor 1 in console to enable editor function
   4,Push your binded key to open editor menu.(all function in menu)
   5,Now Add & Del & Edit use menu.(change angle and del spawn you need aim spawn what is need to be made)
   6,Finally, select <save all spawns> in menu when you finished and the changes will be activated.
   NOTICE: If your (Editor Spawns) diff. to (Origina Spawns) that the map needs to be reloaded once to activate your changes.
*/

/* Console Commands::
 * amx_spawn_editor 1/0 // Enable & Disable Editor Function
 * amx_editor_menu      // open Editor Menu
*/

/* Change Log::
 * [2006-10-23] v1.0
   Rewrite all code, it's almost a new one.
   Fixed the Del spawns can not be less than orgign limit.
   Added change spawn vangle left&right function.
   Added easily create above player spawn function.
   Added auto create (spawns) folder function if it's not exist.
   Added multi-lingual support
   Added Cvar map_spawns record spawns lets HLSW or Server Tools can see how many spawns in that map.
 * [2006-08-23] First release. v0.5 [98 downloaded]
   it works but have more bad code
*/

/* Credits:: help & some code from them
 * FreeCode, BAILOPAN, VEN, oneofthedragon 
 * and more...
*/

/* Screenshots::

*/

#include <amxmodx>
#include <amxmisc>
#include <engine>

#define REQUIRED_ADMIN_LEVEL ADMIN_BAN   // ADMIN_LEVEL_C

#define PLUGINNAME   "Map Spawns Editor"
#define VERSION      "1.0.16"
#define AUTHOR      "iG_os"

// CS default MDL and SPR
#define T_MDL     "models/player/leet/leet.mdl"
#define CT_MDL    "models/player/gign/gign.mdl"
#define LINE_SPR  "sprites/laserbeam.spr"

#define CHECKTIMER  0.8
#define CHECKTASKID  666
#define RESETENTITYTASKID  777
#define SAFEp2p 85   // point to point safe distance
#define SAFEp2w 40   // point to wall safe distance

#define EDIT_CLASSNAME  "Map_Spawns_Editor"

#define SPAWN_PRESENT_OFFSET 10
#define SPAWN_ABOVE_OFFSET 115

// store filename
new g_SpawnFile[256], g_DieFile[256], g_EntFile[256]

new g_MainMenuID = -1 // Menu Handel ID

new bool:g_DeathCheck_end = false
new bool:g_LoadSuccessed = false
new bool:g_LoadInit = false

new bool:g_CheckDistance = true

new bool:g_AbovePlayer = false
new g_OffSet = SPAWN_PRESENT_OFFSET

new g_Editing
new g_SpawnT, g_EditT
new g_SpawnCT,g_EditCT
new Laser_Spr
new g_BeamColors[4][3]={{255,0,0},{0,255,0},{200,200,0},{0,0,255}} 


public plugin_init()
{
   register_plugin(PLUGINNAME, VERSION, AUTHOR)
   register_dictionary("map_spawns_editor.txt")

   g_LoadInit = true // disabled pfn_keyvalue using

   Spawns_Count()
   new string[16]
   format(string,15,"T(%d) CT(%d)",g_SpawnT,g_SpawnCT)
   register_cvar("map_spawns",string,FCVAR_SERVER) // spawns info for HLSW display

   register_event("TextMsg", "event_restartgame", "a", "2&#Game_C","2&#Game_w")
   register_event("DeathMsg", "event_death", "a")
   register_event("HLTV", "event_newround", "a", "1=0", "2=0")

   register_clcmd("amx_spawn_editor", "editor_onoff", REQUIRED_ADMIN_LEVEL, "- 1/0 switch editor function on/off")
   register_clcmd("amx_editor_menu", "editor_menu", REQUIRED_ADMIN_LEVEL, "- open editor menu")

}


public editor_onoff(id,level,cid)
{
   if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED

   if (g_Editing && g_Editing!=id){
      client_print(id,print_chat,"* %L",id,"MSG_ALREADY_INUSE")
      return PLUGIN_HANDLED
   }

   new arg[2]
   read_argv(1,arg,2)
   if (equal(arg,"1",1) && !g_Editing){
      g_Editing = id
      Clear_AllEdit(0)
      Load_SpawnFlie(0)
      Spawns_To_Edit()
      client_print(0,print_chat,">> %L - %L",id,"MENU_TITLE",id,"ON")
   }else if (equal(arg,"0",1)){
      g_Editing = 0
      Clear_AllEdit(0)
      if (task_exists(id+CHECKTASKID)) remove_task(id+CHECKTASKID)
      client_print(0,print_chat,">> %L - %L",id,"MENU_TITLE",id,"OFF")
   }
   return PLUGIN_HANDLED 
}


public editor_menu(id,level,cid)
{
   if (!cmd_access(id,level,cid,1))
      return PLUGIN_HANDLED

   if (!g_Editing){
      client_print(id,print_chat,"* %L",id,"MSG_FUNCTION_DISABLED")
      return PLUGIN_HANDLED
   }

   if (g_Editing!=id){
      client_print(id,print_chat,"* %L",id,"MSG_ALREADY_INUSE")
      return PLUGIN_HANDLED
   }

   new tempString[101]
   format(tempString,100,"%L",id,"MENU_TITLE")
   g_MainMenuID = menu_create(tempString, "m_MainHandler")
   new callbackMenu = menu_makecallback("c_Main")

// page 1
   menu_additem(g_MainMenuID, "[Spawns Info]","1", 1, callbackMenu)
   menu_addblank(g_MainMenuID, 0)

   menu_additem(g_MainMenuID, "[Add spawn locate: present/above player]","2", 0, callbackMenu)
   format(tempString,100,"%L",id,"MENU_ADD_SPAWN","T")
   menu_additem(g_MainMenuID, tempString,"3", 0, callbackMenu)
   format(tempString,100,"%L",id,"MENU_ADD_SPAWN","CT")
   menu_additem(g_MainMenuID, tempString,"4", 0, callbackMenu)
   menu_addblank(g_MainMenuID, 0)

   format(tempString,100,"\y%L",id,"MENU_TURN_LEFT")
   menu_additem(g_MainMenuID, tempString,"5", 0, callbackMenu)
   format(tempString,100,"\y%L",id,"MENU_TURN_RIGHT")
   menu_additem(g_MainMenuID, tempString,"6", 0, callbackMenu)
   menu_addblank(g_MainMenuID, 0)

   format(tempString,100,"%L",id,"MENU_SAVE_ALL_SPAWNS")
   menu_additem(g_MainMenuID, tempString,"7", 0, callbackMenu)
   menu_addblank(g_MainMenuID, 0)
// page 1 end

// page 2
   menu_additem(g_MainMenuID, "[Spawns Info]","11", 1, callbackMenu)
   menu_addblank(g_MainMenuID, 0)

   menu_additem(g_MainMenuID, "[Safe range check on/off]","12", 0, callbackMenu)
   format(tempString,100,"%L",id,"MENU_CLEAR_SPAWN")
   menu_additem(g_MainMenuID, tempString,"13", 0, callbackMenu)
   menu_addblank(g_MainMenuID, 0)

   format(tempString,100,"%L",id,"MENU_CLEAR_ALL_T_SPAWNS")
   menu_additem(g_MainMenuID, tempString,"14", 0, callbackMenu)
   format(tempString,100,"%L",id,"MENU_CLEAR_ALL_CT_SPAWNS")
   menu_additem(g_MainMenuID, tempString,"15", 0, callbackMenu)

   format(tempString,100,"%L",id,"MENU_DEL_SPAWNS_FILE")
   menu_additem(g_MainMenuID, tempString,"16", 0, callbackMenu)

   format(tempString,100,"%L",id,"MENU_EXPORT_FOR_RIPENT")
   menu_additem(g_MainMenuID, tempString,"17", 0, callbackMenu)
   menu_addblank(g_MainMenuID, 0)
// page 2 end

   format(tempString,100,"%L",id,"MENU_EXIT")
   menu_setprop(g_MainMenuID, MPROP_EXITNAME, tempString)
   format(tempString,100,"%L",id,"MENU_NEXT")
   menu_setprop(g_MainMenuID, MPROP_NEXTNAME, tempString)
   format(tempString,100,"%L",id,"MENU_BACK")
   menu_setprop(g_MainMenuID, MPROP_BACKNAME, tempString)

   menu_setprop(g_MainMenuID, MPROP_EXIT, MEXIT_ALL)
   menu_display (id,g_MainMenuID,0)

   client_cmd(id,"spk buttons/button9")
   set_task(CHECKTIMER,"check_Task",id+CHECKTASKID,_,_,"b")

   return PLUGIN_HANDLED 
}

public c_Main(id, menu, item)
{
   if (item < 0) return PLUGIN_CONTINUE

   new cmd[6], fItem[256], iName[64]
   new access, callback
   menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
   new num = str_to_num(cmd)

   if (num==1 || num==11){
      if (g_EditT!=g_SpawnT || g_EditCT!=g_SpawnCT)
         format(fItem,255,"%L ( T=%d + CT=%d ) ^n0.\y %L \r( T=%d + CT=%d ) ^n>> %L", id, "MENU_ORIGIN_SPAWNS",g_SpawnT,g_SpawnCT, id,"MENU_EDIT_SPAWNS", g_EditT,g_EditCT, id,"MENU_NOTICE_SAVE")
      else format(fItem,255,"%L ( T=%d + CT=%d ) ^n0.\y %L ( T=%d + CT=%d )", id, "MENU_ORIGIN_SPAWNS",g_SpawnT,g_SpawnCT, id,"MENU_EDIT_SPAWNS", g_EditT,g_EditCT)
      menu_item_setname(menu, item, fItem )
      return ITEM_DISABLED
   }
   switch (num){
      case 2:{
         if (g_AbovePlayer)
            format(fItem,255,"\y%L ->\r %L",id,"MENU_ADD_LOCATION",id,"MENU_LOCATION_ABOVE")
         else format(fItem,255,"\y%L ->\r %L",id,"MENU_ADD_LOCATION",id,"MENU_LOCATION_CURRENT")
         menu_item_setname(menu, item, fItem ) 
      }
      case 12:{
         if (g_CheckDistance)
            format(fItem,255,"\y%L ->\r %L",id,"MENU_SAFE_CHECK",id,"ON")
         else format(fItem,255,"\y%L ->\r %L",id,"MENU_SAFE_CHECK",id,"OFF")
         menu_item_setname(menu, item, fItem ) 
      }
   }
   return ITEM_ENABLED 
}

public m_MainHandler(id, menu, item)
{
   if (item==MENU_EXIT || !g_Editing){
      if (task_exists(id+CHECKTASKID)) remove_task(id+CHECKTASKID)
      menu_destroy(g_MainMenuID)
      return PLUGIN_HANDLED
   }

   new cmd[6], iName[64] 
   new access, callback 
   menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback) 
   new iChoice = str_to_num(cmd) 
   
   switch(iChoice)
   {
      case 2:{ // Location Set
         if (g_AbovePlayer){
            g_OffSet = SPAWN_PRESENT_OFFSET
            g_AbovePlayer = false
         }else{
            g_OffSet = SPAWN_ABOVE_OFFSET
            g_AbovePlayer = true
         }
         client_cmd(id,"spk buttons/button3")
      }
      case 3:{ // Add T Spawn
         if (g_CheckDistance && !SafeRangeCheck(id,g_OffSet)){
            client_cmd(id,"spk buttons/button2")
            client_print(0,print_chat,">> %L",id,"MSG_CHECK_FAULT")
         }
         else if (CreateEditEntity(1,id,g_OffSet)==1){
            g_EditT++
            client_cmd(id,"spk buttons/button9")
            client_print(0,print_chat,">> %L",id,"MENU_ADD_SPAWN","T")
         }
      }
      case 4:{ // Add CT Spawn
         if (g_CheckDistance && !SafeRangeCheck(id,g_OffSet)){
            client_cmd(id,"spk buttons/button2")
            client_print(0,print_chat,">> %L",id,"MSG_CHECK_FAULT")
         }
         else if (CreateEditEntity(2,id,g_OffSet)==2){
            g_EditCT++
            client_cmd(id,"spk buttons/button9")
            client_print(0,print_chat,">> %L",id,"MENU_ADD_SPAWN","CT")
         }
      }
      case 5:{ // Spawn Turn Left
         new entity = Get_Edit_Point_By_Aim(id)
         if (entity && is_valid_ent(entity)){
            Entity_Turn_angle(entity,10)
            client_cmd(id,"spk buttons/blip1")
         }else{
            client_cmd(id,"spk buttons/button2")
            client_print(0,print_chat,">> %L",id,"ERROR_POINT_NOTFOUND")
         }
      }
      case 6:{ // Spawn Turn Right
         new entity = Get_Edit_Point_By_Aim(id)
         if (entity && is_valid_ent(entity)){
            Entity_Turn_angle(entity,-10)
            client_cmd(id,"spk buttons/blip1")
         }else{
            client_cmd(id,"spk buttons/button2")
            client_print(0,print_chat,">> %L",id,"ERROR_POINT_NOTFOUND")
         }
      }
      case 7:{ // Save All Spawn To File
         if (Save_SpawnsFile()){
            Load_SpawnFlie(0)
            client_cmd(id,"spk buttons/blip2")
            client_print(0,print_chat,">> %L (T=%d,CT=%d)",id,"MSG_SAVE_SPAWNSFLIE",g_EditT,g_EditCT)
         }else
            client_print(0,print_chat,">> %L",id,"ERROR_SAVE_SPAWNSFLIE")
      }
      case 12:{ // Safe Range Check
         g_CheckDistance = g_CheckDistance ? false:true
         client_cmd(id,"spk buttons/button3")
      }
      case 13:{ // Clear a Spawn
         new entity = Get_Edit_Point_By_Aim(id)
         if (entity && is_valid_ent(entity)){
            new team = entity_get_int(entity,EV_INT_iuser2)
            remove_entity(entity)
            client_cmd(id,"spk buttons/button3")
            if (team==1){
               g_EditT--
               client_print(0,print_chat,">> %L",id,"MSG_CLEAR_SPAWN","T")
            }else{
               g_EditCT--
               client_print(0,print_chat,">> %L",id,"MSG_CLEAR_SPAWN","CT")
            }
         }else{
            client_cmd(id,"spk buttons/button2")
            client_print(0,print_chat,">> %L",id,"ERROR_POINT_NOTFOUND")
         }
      }
      case 14:{ // Clear All T Spawn
         Clear_AllEdit(1)
         client_cmd(id,"spk buttons/blip2")
         client_print(0,print_chat,">> %L",id,"MENU_CLEAR_ALL_T_SPAWNS")
      }
      case 15:{ // Clear All CT Spawn
         Clear_AllEdit(2)
         client_cmd(id,"spk buttons/blip2")
         client_print(0,print_chat,">> %L",id,"MENU_CLEAR_ALL_CT_SPAWNS")
      }
      case 16:{ // Del Spawns Flie
         if (file_exists(g_SpawnFile)){
            delete_file(g_SpawnFile)
            client_cmd(id,"spk buttons/blip2")
            client_print(0,print_chat,">> %L",id,"MSG_DEL_SPAWNSFILE")
         }
      }
      case 17:{ // Expotr Spawn To ENT Format
         if (Export_RipentFormatFile()){
            client_cmd(id,"spk buttons/blip2")
            client_print(0,print_chat,">> %L [%s] (T=%d,CT=%d)",id,"MSG_EXOPRT_SPAWNSFLIE",g_EntFile,g_EditT,g_EditCT)
         }
      }
   }

   if (iChoice>=11 && iChoice<=17)  // go back to second page is using
      menu_display (id, g_MainMenuID, 1)
   else menu_display (id, g_MainMenuID, 0)
   return PLUGIN_CONTINUE 
}


public plugin_precache()
{
   new configdir[128]
   get_configsdir(configdir, 127 )
   new spawndir[256]
   format(spawndir,255,"%s/spawns",configdir)
   if (!dir_exists(spawndir)){
      if (mkdir(spawndir)==0){ // Create a dir,if it's not exist
         log_amx("Create [%s] dir successfully finished.",spawndir)
      }else{
         log_error(AMX_ERR_NOTFOUND,"Couldn't create [%s] dir,plugin stoped.",spawndir)
         pause("ad")
         return PLUGIN_CONTINUE
      }
   }

   precache_model(T_MDL)
   precache_model(CT_MDL)
   Laser_Spr = precache_model(LINE_SPR)

   new MapName[32]
   get_mapname(MapName, 31)
   //store spawns point data in this file
   format(g_SpawnFile, 255, "%s/%s_spawns.cfg",spawndir, MapName)
   //when restart game some bad spawn point will make user die,store data in this file,it's useful.
   format(g_DieFile, 255, "%s/%s_spawns_die.cfg",spawndir, MapName)
   //export spawns data to this file for ripent.exe format,it's useful for import to bsp for ripent.exe
   format(g_EntFile, 255, "%s/%s_ent.txt",spawndir, MapName)

   if (Load_SpawnFlie(1)) //load spawn file and create player spawn points
      g_LoadSuccessed = true
   else
      g_LoadSuccessed = false

   return PLUGIN_CONTINUE
}

//load spawns from file, Return 0 when didn't load anything.
stock Load_SpawnFlie(type) //createEntity = 1 create an entity when load a point
{
   if (file_exists(g_SpawnFile))
   {
      new ent_T, ent_CT
      new Data[128], len, line = 0
      new team[8], p_origin[3][8], p_angles[3][8]
      new Float:origin[3], Float:angles[3]

      while((line = read_file(g_SpawnFile , line , Data , 127 , len) ) != 0 ) 
      {
         if (strlen(Data)<2) continue

         parse(Data, team,7, p_origin[0],7, p_origin[1],7, p_origin[2],7, p_angles[0],7, p_angles[1],7, p_angles[2],7)
         
         origin[0] = str_to_float(p_origin[0]); origin[1] = str_to_float(p_origin[1]); origin[2] = str_to_float(p_origin[2]);
         angles[0] = str_to_float(p_angles[0]); angles[1] = str_to_float(p_angles[1]); angles[2] = str_to_float(p_angles[2]);

         if (equali(team,"T")){
            if (type==1) ent_T = create_entity("info_player_deathmatch")
            else ent_T = find_ent_by_class(ent_T, "info_player_deathmatch")
            if (ent_T>0){
               entity_set_int(ent_T,EV_INT_iuser1,1) // mark that create by map spawns editor
               entity_set_origin(ent_T,origin)
               entity_set_vector(ent_T, EV_VEC_angles, angles)
            }
         }
         else if (equali(team,"CT")){
            if (type==1) ent_CT = create_entity("info_player_start")
            else ent_CT = find_ent_by_class(ent_CT, "info_player_start")
            if (ent_CT>0){
               entity_set_int(ent_CT,EV_INT_iuser1,1) // mark that create by map spawns editor
               entity_set_origin(ent_CT,origin)
               entity_set_vector(ent_CT, EV_VEC_angles, angles)
            }
         }
      }
      return 1
   }
   return 0
}

// pfn_keyvalue..Execure after plugin_precache and before plugin_init
public pfn_keyvalue(entid)
{  // when load custom spawns file successed,we are del all spawns by map originate create
   if (g_LoadSuccessed && !g_LoadInit){
      new classname[32], key[32], value[32]
      copy_keyvalue(classname, 31, key, 31, value, 31)

      if (equal(classname, "info_player_deathmatch") || equal(classname, "info_player_start")){
         if (is_valid_ent(entid) && entity_get_int(entid,EV_INT_iuser1)!=1) //filter out custom spawns
            remove_entity(entid)
      }
   }
   return PLUGIN_CONTINUE
}


public event_restartgame()
{
   if (g_Editing && file_exists(g_DieFile))
      delete_file(g_DieFile)

   g_DeathCheck_end = false

   if (g_Editing){
      Clear_AllEdit(0)
      Load_SpawnFlie(0)
      Spawns_To_Edit()
   }
   return PLUGIN_CONTINUE
}

// Remove & save bad spawn point where force user die.
public event_death()
{
   if (!g_DeathCheck_end){
      new string[12]
      read_data(4,string,11)
      if (equal(string,"worldspawn")){
         new id = read_data(2)
         if (g_Editing){
            new entList[1],team
            find_sphere_class(id,EDIT_CLASSNAME, 30.0, entList, 1)
            if (entList[0]){
               team = entity_get_int(entList[0],EV_INT_iuser2) // team mark
               if (team==1){
                  client_print(0,print_chat,">> %L",id,"MSG_AUTO_REMOVE_SPAWN","T")
                  g_EditT--
               }else{
                  client_print(0,print_chat,">> %L",id,"MSG_AUTO_REMOVE_SPAWN","CT")
                  g_EditCT--
               }
               remove_entity(entList[0])
               return PLUGIN_CONTINUE
            }
         }else{
            new team = get_user_team(id)
            if (team==1) Point_WriteToFlie(g_DieFile,1,id,1)
            else if (team==2) Point_WriteToFlie(g_DieFile,2,id,1)
         }
      }
   }
   return PLUGIN_CONTINUE
}

public event_newround()
   set_task(3.0,"deathCheck_end")

public deathCheck_end()
   g_DeathCheck_end = true


// create a edit point
stock CreateEditEntity(team,iEnt,offset)
{
   new Float:fOrigin[3],Float:fAngles[3]
   entity_get_vector(iEnt, EV_VEC_origin, fOrigin)
   entity_get_vector(iEnt, EV_VEC_angles, fAngles)
   fOrigin[2] += float(offset) //offset Z

   new entity = create_entity("info_target")
   if (entity){
      entity_set_string(entity, EV_SZ_classname, EDIT_CLASSNAME)
      entity_set_model(entity,(team==1) ? T_MDL:CT_MDL)
      entity_set_origin(entity, fOrigin)
      entity_set_vector(entity, EV_VEC_angles, fAngles)
      entity_set_int(entity, EV_INT_sequence, 4)
      entity_set_int(entity,EV_INT_iuser2,team) // team mark
      return team
   }
   return 0
}

// clear up all edit points
stock Clear_AllEdit(team){
   new entity
   switch (team){
      case 0:{
         while ((entity = find_ent_by_class(entity, EDIT_CLASSNAME)))
            remove_entity(entity)
         g_EditT = 0
         g_EditCT = 0
      }
      case 1:{
         while ((entity = find_ent_by_class(entity, EDIT_CLASSNAME)))
            if (entity_get_int(entity,EV_INT_iuser2)==1)
               remove_entity(entity)
         g_EditT = 0
      }
      case 2:{
         while ((entity = find_ent_by_class(entity, EDIT_CLASSNAME)))
            if (entity_get_int(entity,EV_INT_iuser2)==2)
               remove_entity(entity)
         g_EditCT = 0
      }
   }
}

// convert origin spawns to edit points
stock Spawns_To_Edit()
{
   new entity
   g_EditT = 0
   while ((entity = find_ent_by_class(entity, "info_player_deathmatch"))){
      CreateEditEntity(1,entity,0)
      g_EditT++
   }
   entity = 0
   g_EditCT = 0
   while ((entity = find_ent_by_class(entity, "info_player_start"))){
      CreateEditEntity(2,entity,0)
      g_EditCT++
   }
}

stock Spawns_Count()
{
   new entity
   g_SpawnT = 0
   while ((entity = find_ent_by_class(entity, "info_player_deathmatch")))
      g_SpawnT++

   entity = 0
   g_SpawnCT = 0
   while ((entity = find_ent_by_class(entity, "info_player_start")))
      g_SpawnCT++
}

public check_Task(taskid){
   SafeRangeCheck(taskid-CHECKTASKID,SPAWN_PRESENT_OFFSET)
   Get_Edit_Point_By_Aim(taskid-CHECKTASKID)
}

// reset entity sequence
public reset_entity_stats(param){
   new entity = param - RESETENTITYTASKID
   if (is_valid_ent(entity)){
      entity_set_float(entity, EV_FL_animtime, 0.0)
      entity_set_float(entity, EV_FL_framerate, 0.0)
      entity_set_int(entity, EV_INT_sequence, 4)
   }
}

// set entity vangle[1]+turn
stock Entity_Turn_angle(entity,turn){
   if (is_valid_ent(entity)){
      new Float:fAngles[3]
      entity_get_vector(entity, EV_VEC_angles, fAngles)
      fAngles[1] += turn
      if (fAngles[1]>=360) fAngles[1] -= 360
      if (fAngles[1]<0) fAngles[1] += 360
      entity_set_vector(entity, EV_VEC_angles, fAngles)
   }
}

// check edit point or wall distance to id
stock SafeRangeCheck(id,offset)
{
   new safepostion = 1
   new Float:fOrigin[3],Float:fAngles[3],Float:inFrontPoint[3],Float:HitPoint[3]
   entity_get_vector(id, EV_VEC_origin, fOrigin)
   fOrigin[2] += offset // hight offset,same as Edit Point offset
   entity_get_vector(id, EV_VEC_angles, fAngles)

   for (new i=0;i<360;i+=10)
   {
      fAngles[1] = float(i)
      // get the id infront point for trace_line
      Vector_By_Angle(fOrigin,fAngles, SAFEp2w * 2.0, 1, inFrontPoint)

      // check id nearby wall
      trace_line(-1,fOrigin,inFrontPoint,HitPoint)
      new distance = floatround(vector_distance(fOrigin, HitPoint))

      if (distance<SAFEp2w){ // unsafe distance to wall
         Make_TE_BEAMPOINTS(id,0,fOrigin,HitPoint,2,255)
         safepostion = 0
      }
      else if (distance < SAFEp2w * 1.5)
         Make_TE_BEAMPOINTS(id,2,fOrigin,HitPoint,2,255)
   }

   // check id nearby Edit Points
   new entList[10],Float:vDistance
   new Float:entity_origin[3]
   find_sphere_class(0,EDIT_CLASSNAME, SAFEp2p * 1.5, entList, 9, fOrigin)
   for(new i=0;i<10;i++){
      if (entList[i]){
         entity_get_vector(entList[i], EV_VEC_origin, entity_origin)
         vDistance = vector_distance(fOrigin,entity_origin)
         if (vDistance < SAFEp2p){ // unsafe location to Edit Points
            Make_TE_BEAMPOINTS(id,0,fOrigin,entity_origin,5,255)
            entity_set_int(entList[i], EV_INT_sequence, 64)
            safepostion = 0
            if (task_exists(entList[i]+RESETENTITYTASKID)) 
               remove_task(entList[i]+RESETENTITYTASKID)
            set_task(CHECKTIMER+0.1,"reset_entity_stats",entList[i]+RESETENTITYTASKID)
         } else Make_TE_BEAMPOINTS(id,1,fOrigin,entity_origin,5,255)
      }
   }
   return safepostion
}


stock Get_Edit_Point_By_Aim(id)
{
   new entList[1],team
   new Float:fOrigin[3],Float:vAngles[3],Float:vecReturn[3]
   entity_get_vector(id, EV_VEC_origin, fOrigin)
   fOrigin[2] += 10 // offset Z of id
   entity_get_vector(id, EV_VEC_v_angle, vAngles)

   for(new Float:i=0.0;i<=1000.0;i+=20.0)
   {
      Vector_By_Angle(fOrigin,vAngles,i,1,vecReturn)
      //Make_TE_BEAMPOINTS(id,3,fOrigin,vecReturn,5,255)
      //client_print(0,print_chat,"fOrigin={%d,%d,%d},vecReturn={%d,%d,%d}",floatround(fOrigin[0]),floatround(fOrigin[1]),floatround(fOrigin[2]),floatround(vecReturn[0]),floatround(vecReturn[1]),floatround(vecReturn[2]))

      find_sphere_class(0,EDIT_CLASSNAME, 20.0, entList, 1, vecReturn)
      if (entList[0]){
         // let entity have anim.
         entity_set_float(entList[0], EV_FL_animtime, 1.0)
         entity_set_float(entList[0], EV_FL_framerate, 1.0)
         team = entity_get_int(entList[0],EV_INT_iuser2)
         client_print(id,print_center,"%L #%d",id,"MSG_AIM_SPAWN",(team==1) ? "T":"CT",entList[0])
         if (task_exists(entList[0]+RESETENTITYTASKID)) 
            remove_task(entList[0]+RESETENTITYTASKID)
         set_task(CHECKTIMER+0.1,"reset_entity_stats",entList[0]+RESETENTITYTASKID)
         break
      }
   }
   return entList[0] // return entity if be found
}


/* FRU define in vector.inc
#define ANGLEVECTOR_FORWARD      1
#define ANGLEVECTOR_RIGHT        2
#define ANGLEVECTOR_UP           3
*/
stock Vector_By_Angle(Float:fOrigin[3],Float:vAngles[3], Float:multiplier, FRU, Float:vecReturn[3])
{
   angle_vector(vAngles, FRU, vecReturn)
   vecReturn[0] = vecReturn[0] * multiplier + fOrigin[0]
   vecReturn[1] = vecReturn[1] * multiplier + fOrigin[1]
   vecReturn[2] = vecReturn[2] * multiplier + fOrigin[2]
}


// draw laserBeam
stock Make_TE_BEAMPOINTS(id,color,Float:Vec1[3],Float:Vec2[3],width,brightness){
   message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id)
   write_byte(TE_BEAMPOINTS) // TE_BEAMPOINTS = 0
   write_coord(floatround(Vec1[0])) // start position
   write_coord(floatround(Vec1[1]))
   write_coord(floatround(Vec1[2]))
   write_coord(floatround(Vec2[0])) // end position
   write_coord(floatround(Vec2[1]))
   write_coord(floatround(Vec2[2]))
   write_short(Laser_Spr) // sprite index
   write_byte(1) // starting frame
   write_byte(0) // frame rate in 0.1's
   write_byte(4) // life in 0.1's
   write_byte(width) // line width in 0.1's
   write_byte(0) // noise amplitude in 0.01's
   write_byte(g_BeamColors[color][0])
   write_byte(g_BeamColors[color][1])
   write_byte(g_BeamColors[color][2])
   write_byte(brightness) // brightness)
   write_byte(0) // scroll speed in 0.1's
   message_end()
}


stock Save_SpawnsFile()
{
   if (file_exists(g_SpawnFile))
      delete_file(g_SpawnFile)

   new mapname[32],line[128]
   get_mapname(mapname,31)
   format(line,127,"/* %s T=%d,CT=%d */ Map Spawns Editor Format File",mapname,g_EditT,g_EditCT)
   write_file(g_SpawnFile, line, -1)

   new entity,team
   while ((entity = find_ent_by_class(entity, EDIT_CLASSNAME))){
      team = entity_get_int(entity,EV_INT_iuser2)
      Point_WriteToFlie(g_SpawnFile,team,entity,1)
   }

   return 1
}

stock Export_RipentFormatFile()
{
   if (file_exists(g_EntFile))
      delete_file(g_EntFile)

   new entity,team
   while ((entity = find_ent_by_class(entity, EDIT_CLASSNAME))){
      team = entity_get_int(entity,EV_INT_iuser2)
      Point_WriteToFlie(g_EntFile,team,entity,2)
   }
   return 1
}

// store one entity data to file
stock Point_WriteToFlie(Flie[],team,entity,saveformat)
{
   new line[128],sTeam[32]
   new nOrigin[3],nAngles[3]
   new Float:fOrigin[3],Float:fAngles[3]

   entity_get_vector(entity, EV_VEC_origin, fOrigin)
   entity_get_vector(entity, EV_VEC_angles, fAngles)
   FVecIVec(fOrigin,nOrigin)
   FVecIVec(fAngles,nAngles)
   if (nAngles[1]>=360) nAngles[1] -= 360
   if (nAngles[1]<0) nAngles[1] += 360

   if (saveformat==1){ // write for plugin using format
      if (team==1) sTeam = "T"
      else sTeam = "CT"
      format(line, 127, "%s %d %d %d %d %d %d", sTeam, nOrigin[0], nOrigin[1], nOrigin[2], 0, nAngles[1], 0)
      write_file(Flie, line, -1)
   }
   else if (saveformat==2){ // write for ripent.exe format
      if (team==1) sTeam = "info_player_deathmatch"
      else sTeam = "info_player_start"
      format(line, 127,"{^n  ^"classname^" ^"%s^"",sTeam)
      write_file(Flie, line , -1)
      format(line, 127, "  ^"origin^" ^"%d %d %d^"", nOrigin[0], nOrigin[1], nOrigin[2])
      write_file(Flie, line, -1)
      format(line, 127, "  ^"angle^" ^"0 %d 0^"^n}^n", nAngles[1])
      write_file(Flie, line, -1)
   }
}

//////////////////////////////////////////////////////////
/* export spawns data to txt file for ripent.exe format */
/* 
{ //(T)
"classname" "info_player_deathmatch"
"origin" "-384 1056 108"
"angle" "0 180 0"
}
{ //(CT)
"classname" "info_player_start"
"origin" "-128 -832 104"
"angle" "0 270 0"
}
*/
//////////////////////////////////////////////////////////

