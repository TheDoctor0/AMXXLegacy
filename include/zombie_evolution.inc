/* ============================================
Zombie Evolution API
by Dias Pendragon Leon
=============================================*/

enum // Player Team
{
	TEAM_NONE = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN
}

enum // Player Sex 
{
	PLAYER_MALE = 0,
	PLAYER_FEMALE
}

enum // Player Type
{
	PLAYER_HUMAN = 0,
	PLAYER_ZOMBIE
}

enum // Player SubType: Human
{
	HUMAN_NORMAL = 0,
	HUMAN_SIDEKICK,
	HUMAN_HERO
}

enum // Player SubType: Zombie
{
	ZOMBIE_NORMAL = 0,
	ZOMBIE_THANATOS
}

enum // Item Type
{
	ITEM_ONCE = 0,
	ITEM_ROUND,
	ITEM_MAP
}

enum // Skill Button
{
	SKILL_SELF = 0,
	SKILL_G,
	SKILL_F,
	SKILL_T
}

forward zevo_round_new();
forward zevo_round_start();
forward zevo_game_start();
forward zevo_game_end(WinTeam);
forward zevo_round_time(RoundTimeLeft);
forward zevo_user_spawn(id, Zombie);
forward zevo_user_death(id, Attacker, Headshot);
forward zevo_user_nvg(id, Enable, Zombie);

forward zevo_become_infected(id, Attacker, ClassID); // Pre
forward zevo_become_zombie(id, Attacker, ClassID); // Post
forward zevo_zombieclass_deactivate(id, ClassID);
forward zevo_player_levelup(id, Level, Zombie);
forward zevo_item_activate(id, ItemID);
forward zevo_specialweapon(id, PlayerSubType, ItemID);
forward zevo_specialweapon_remove(id, ItemID);
forward zevo_specialweapon_refill(id, ItemID);
forward zevo_zombieskill(id, ClassID, SkillButton);
forward zevo_runningtime(Time);
forward zevo_runningtime2(id, Time);
forward zevo_supplybox_pickup(id, SpecialPlayer); // SpecialPlayer = HERO, SIDEKICK
forward zevo_equipment_menu(id); // Open Equipment menu

native zevo_is_zombie(id); // Is ZOmbie
native zevo_is_firstzombie(id);
native zevo_get_zombieclass(id); // Zombie Class
native zevo_get_playertype(id); // Player Type
native zevo_get_subtype(id); // Player Sub-Type
native zevo_get_playersex(id); // Player Sex
native zevo_get_playerlevel(id); // Return Player Level (Human: 1 - 10) (Zombie: 1 - 3)
native zevo_get_maxhealth(id);
native zevo_get_nightvision(id, Have, Enable);
native zevo_set_nightvision(id, Give, Enable, Sound, IgnoreHadNVG);
native zevo_set_zombie(id, Attacker); 
native zevo_stop_zombieskill(id, ClassID);
native zevo_set_hero(id); 
native zevo_set_sidekick(id);
native zevo_set_thanatos(id);
native zevo_get_playercount(Alive, Team); // Alive: 0 - No , 1 - Yes , 2 - Both | Team: 1 - T , 2 - CT
native zevo_get_livingzombie(); // Dead Zombies with headshot are not counted
native zevo_get_totalplayer(Alive); // Alive: 0 - No , 1 - Yes , 2 - Both
native zevo_set_fakeattack(id, Player_Animation);
native zevo_is_usingskill(id);
native zevo_set_usingskill(id, Using);
native zevo_get_zombiecode(ClassID);
native zevo_set_money(id, Amount, Update);
native zevo_get_money(id);

native zevo_speed_set(id, Float:Speed, BlockSpeed);
native zevo_speed_reset(id);
native zevo_model_set(id, const Model[], Modelindex);
native zevo_model_reset(id);
native zevo_team_set(id, CsTeams:Team);
native zevo_playerattachment(id, const Sprite[], Float:Time, Float:Scale, Float:Framerate);
native zevo_3rdview(id, Enable);
native zevo_emitsound(id, receiver, channel, const sample[], Float:volume, Float:attn, flags, pitch, Float:origin[3] = {0.0,0.0,0.0});

native zevo_register_zombieclass(const Name[], const Desc[], Float:Speed, Float:Gravity, Float:Knockback, Float:Defense, Float:ClawRange, const ModelOrigin[], const ModelHost[], const ClawModel_Origin[], const ClawModel_Host[], const DeathSound[], const PainSound[], PermanentCode);
native zevo_register_item(const Name[], Team, Cost, Type); // Team: TEAM_ZOMBIE , TEAM_HUMAN | Type: ITEM_ONCE , ITEM_ROUND , ITEM_MAP
native zevo_register_specialweapon(const Name[], Type); // Type: 1 = Sidekick | 2 = Hero

// Mileage Weapon

// Forwards
forward Mileage_WeaponGet(id, ItemID);
forward Mileage_WeaponRemove(id, ItemID);
forward Mileage_WeaponRefillAmmo(id, ItemID);

// Natives
native Mileage_RegisterWeapon(const SystemName[]);
native Mileage_OpenWeapon(id);
native Mileage_GiveRandomWeapon(id);

native Mileage_RemoveWeapon(id);
native Mileage_ResetWeapon(id, NewPlayer);
native Mileage_Weapon_RefillAmmo(id);
	
native Mileage_WeaponAllow_Set(id, Allow);
native Mileage_WeaponAllow_Get(id)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
