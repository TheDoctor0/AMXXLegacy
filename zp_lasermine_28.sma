/*
	Shidla [SGC] | 2013 год
	ICQ: 312-298-513

	2.8.2 [Final Version] | 21.05.2013
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <fakemeta_util>
#include <engine>
#include <zombieplague>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or greater library required!
#endif

#define PLUGIN "[ZP] LaserMine"
#define VERSION "2.8.3"
#define AUTHOR "SandStriker / Shidla / QuZ / DJ_WEST / O'Zone"

#define RemoveEntity(%1)	engfunc(EngFunc_RemoveEntity,%1)
#define TASK_PLANT			15100
#define TASK_RESET			15500
#define TASK_RELEASE		15900
#define TASK_CHECK 			16300

#define LASERMINE_TEAM		pev_iuser1 //EV_INT_iuser1
#define LASERMINE_OWNER		pev_iuser2 //EV_INT_iuser3
#define LASERMINE_STEP		pev_iuser3
#define LASERMINE_HITING	pev_iuser4
#define LASERMINE_COUNT		pev_fuser1

#define LASERMINE_POWERUP	pev_fuser2
#define LASERMINE_BEAMTHINK	pev_fuser3

#define LASERMINE_BEAMENDPOINT	pev_vuser1
#define MAX_MINES			10
#define MODE_LASERMINE		0
#define OFFSET_TEAM			114
#define OFFSET_MONEY		115
#define OFFSET_DEATH		444

#define cs_get_user_team(%1)	CsTeams:get_offset_value(%1,OFFSET_TEAM)
#define cs_get_user_deaths(%1)	get_offset_value(%1,OFFSET_DEATH)
#define is_valid_player(%1)	(1 <= %1 <= 32)


/*########### Цвета Мин и лазерных лучей ###########*/
// Цвет мины и лазера людей
new const
	Red_Hum		= 0,
	Green_Hum 	= 0,
	Blue_Hum	= 255;

// Цвет мины и лазера зомби
new const
	Red_Zomb	= 0,
	Green_Zomb 	= 255,
	Blue_Zomb	= 0;
/*####### Цвета Мин и лазерных лучей (конец) #######*/

enum tripmine_e {
	TRIPMINE_IDLE1 = 0,
	TRIPMINE_IDLE2,
	TRIPMINE_ARM1,
	TRIPMINE_ARM2,
	TRIPMINE_FIDGET,
	TRIPMINE_HOLSTER,
	TRIPMINE_DRAW,
	TRIPMINE_WORLD,
	TRIPMINE_GROUND,
};

enum
{
	POWERUP_THINK,
	BEAMBREAK_THINK,
	EXPLOSE_THINK
};

enum
{
	POWERUP_SOUND,
	ACTIVATE_SOUND,
	STOP_SOUND
};

new const
	ENT_MODELS[]	= "models/zombie_plague/LaserMines/v_laser_mine.mdl",
	ENT_SOUND1[]	= "weapons/mine_deploy.wav",
	ENT_SOUND2[]	= "weapons/mine_charge.wav",
	ENT_SOUND3[]	= "weapons/mine_activate.wav",
	ENT_SOUND4[]	= "items/suitchargeok1.wav",
	ENT_SOUND5[]	= "items/gunpickup2.wav",
	ENT_SOUND6[]	= "debris/bustglass1.wav",
	ENT_SOUND7[]	= "debris/bustglass2.wav",
	ENT_SPRITE1[]	= "sprites/laserbeam.spr",
	ENT_SPRITE2[]	= "sprites/lm_explode.spr";

new const
	ENT_CLASS_NAME[]	=	"lasermine",
	ENT_CLASS_NAME3[]	=	"func_breakable",
	gSnarkClassName[]	=	"wpn_snark",	// Для совместимости с плагином "Snark"
	barnacle_class[]	=	"barnacle",		// Для совместимости с плагином "Barnacle"
	weapon_box[]		=	"weaponbox";

new g_EntMine, beam, boom
new g_LENABLE, g_LFMONEY, g_LAMMO, g_LDMG, g_LBEO, g_LTMAX, g_LCOST, g_LHEALTH, g_LMODE, g_LRADIUS, g_NOROUND, g_NEMROUND, g_SURVROUND, g_SWARROUND, g_ASSROUND
new g_LRDMG,g_LFF,g_LCBT, g_LDELAY, g_LVISIBLE, g_LSTAMMO, g_LACCESS, g_LGLOW, g_LDMGMODE, g_LCLMODE
new g_LCBRIGHT, g_LDSEC, g_LCMDMODE, g_LBUYMODE, g_LME;
new g_msgDeathMsg,g_msgScoreInfo,g_msgDamage,g_msgStatusText;
new g_dcount[33],g_nowtime,g_MaxPL
new bool:g_settinglaser[33]
new Float:plspeed[33], plsetting[33], g_havemine[33], g_deployed[33];
//new CVAR_LMCost

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// Вызываем функцию Laser_TakeDamage при получении урона объектом ENT_CLASS_NAME3 (func_breakable)
	RegisterHam(Ham_TakeDamage, ENT_CLASS_NAME3, "Laser_TakeDamage")
	RegisterHam(Ham_Spawn , "player", "Player_Spawn", 1);
	// Add your code here...
	register_clcmd("+setlaser","CreateLaserMine_Progress_b");
	register_clcmd("-setlaser","StopCreateLaserMine");
	register_clcmd("+dellaser","ReturnLaserMine_Progress");
	register_clcmd("-dellaser","StopReturnLaserMine");
	register_clcmd("say","say_lasermine");
	register_clcmd("buy_lasermine","BuyLasermineChat");

	g_LENABLE	= register_cvar("zp_ltm","1")
	g_LACCESS	= register_cvar("zp_ltm_acs","0") //0 all, 1 admin
	g_LMODE		= register_cvar("zp_ltm_mode","0") //0 lasermine, 1 tripmine
	g_LAMMO		= register_cvar("zp_ltm_ammo","3")
	g_LDMG		= register_cvar("zp_ltm_dmg","10") //laser hit dmg
	g_LCOST		= register_cvar("zp_ltm_cost","2")
	g_LFMONEY	= register_cvar("zp_ltm_fragmoney","1")
	g_LHEALTH	= register_cvar("zp_ltm_health","10")
	g_LTMAX		= register_cvar("zp_ltm_teammax","128")
	g_LRADIUS	= register_cvar("zp_ltm_radius","25.0")
	g_LRDMG		= register_cvar("zp_ltm_rdmg","100") //radius damage
	g_LFF		= register_cvar("zp_ltm_ff","0")
	g_LCBT		= register_cvar("zp_ltm_cbt","ALL")
	g_LDELAY	= register_cvar("zp_ltm_delay","0.1")
	g_LVISIBLE	= register_cvar("zp_ltm_line","1")
	g_LGLOW		= register_cvar("zp_ltm_glow","1")
	g_LCBRIGHT	= register_cvar("zp_ltm_bright","255")//laser line brightness.
	g_LCLMODE	= register_cvar("zp_ltm_color","0") //0 is team color,1 is green
	g_LDMGMODE	= register_cvar("zp_ltm_ldmgmode","0") //0 - frame dmg, 1 - once dmg, 2 - 1 second dmg
	g_LDSEC		= register_cvar("zp_ltm_ldmgseconds","1") //mode 2 only, damage / seconds. default 1 (sec)
	g_LSTAMMO	= register_cvar("zp_ltm_startammo","0")
	g_LBUYMODE	= register_cvar("zp_ltm_buymode","1");
	g_LCMDMODE	= register_cvar("zp_ltm_cmdmode","1");		//0 is +USE key, 1 is bind, 2 is each.
	g_LBEO		= register_cvar("zp_ltm_brokeenemy","1");
	g_NOROUND	= register_cvar("zp_ltm_noround","1");
	g_NEMROUND	= register_cvar("zp_ltm_nemround","1");
	g_SURVROUND	= register_cvar("zp_ltm_survround","1");
	g_SWARROUND	= register_cvar("zp_ltm_swarround","1");
	g_ASSROUND	= register_cvar("zp_ltm_assround","1");

	register_event("DeathMsg", "DeathEvent", "a");
	register_event("CurWeapon", "standing", "be", "1=1");
	register_event("ResetHUD", "delaycount", "a");
	register_event("ResetHUD", "newround", "b");
	register_logevent("endround", 2, "0=World triggered", "1=Round_End");	// Регистрируем конец раунда
	register_event("Damage","CutDeploy_onDamage","b");
	g_msgDeathMsg	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	g_msgDamage		= get_user_msgid("Damage");
	g_msgStatusText = get_user_msgid("StatusText");

	// Forward.
	register_forward(FM_Think, "ltm_Think");
	register_forward(FM_PlayerPostThink, "ltm_PostThink");
	register_forward(FM_PlayerPreThink, "ltm_PreThink");

	// Регистируем файл языков
	register_dictionary("LaserMines.txt")
	register_cvar("Shidla", "[ZP] LaserMines v.2.8.1 Final", FCVAR_SERVER|FCVAR_SPONLY)

	// Регистрируем ExtraItem
	g_LME = zp_register_extra_item("Laser Mine", get_pcvar_num(g_LCOST), ZP_TEAM_HUMAN)
}

public plugin_precache() 
{
	precache_sound(ENT_SOUND1);
	precache_sound(ENT_SOUND2);
	precache_sound(ENT_SOUND3);
	precache_sound(ENT_SOUND4);
	precache_sound(ENT_SOUND5);
	precache_sound(ENT_SOUND6);
	precache_sound(ENT_SOUND7);
	precache_model(ENT_MODELS);
	beam = precache_model(ENT_SPRITE1);
	boom = precache_model(ENT_SPRITE2);
	return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	client_cmd(id, "echo ^"^";^"bind^" ^"p^" ^"+setlaser^"");
	client_cmd(id, "echo ^"^";^"bind^" ^"x^" ^"+dellaser^"");
	cmdExecute(id, "bind p +setlaser");
	cmdExecute(id, "bind x +dellaser");
}

public Player_Spawn(id) 
{
	if(is_user_alive(id) && !task_exists(id + TASK_CHECK))
		set_task(0.4, "Check_Owner", id + TASK_CHECK, "", 0, "b")
}

public Check_Owner(id)
{
	id -= TASK_CHECK
	
	if(is_user_alive(id))
	{
		new entity = Get_Laser_By_Aim(id)
		if (entity && is_valid_ent(entity) && fm_is_ent_visible(id, entity))
		{
			new owner = pev(entity, pev_iuser2)
			if(owner != id)
			{
				new szName[32];
				get_user_name(owner, szName, charsmax(szName))
				set_dhudmessage(255, 0, 0, 0.35, 0.25, 0, 0.0, 0.6, 0.0, 0.0)
				show_dhudmessage(id, "Wlasciciel: %s", szName)
			}
		}
	}
}

public plugin_cfg()
{
	g_EntMine = engfunc(EngFunc_AllocString,ENT_CLASS_NAME3);
	arrayset(g_havemine,0,sizeof(g_havemine));
	arrayset(g_deployed,0,sizeof(g_deployed));
	g_MaxPL = get_maxplayers();

	new file[64]; get_localinfo("amxx_configsdir",file,63);
	format(file, 63, "%s/zp_ltm_cvars_ap.cfg", file);
	if(file_exists(file)) server_cmd("exec %s", file), server_exec();
}

public Laser_TakeDamage(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	if(get_pcvar_num(g_LBEO))
	{
		new i_Owner

		// Получаем ID игрока, который поставил мину
		i_Owner = pev(victim, LASERMINE_OWNER)

		// Если урон нанасит владелец, а так же проверка игрока.
		if(i_Owner == attacker || !is_valid_player(i_Owner) || !is_valid_player(attacker))
			return PLUGIN_CONTINUE

		// Если мина установлена человеком, то урон ей наносят только зомби
		if((CsTeams:pev(victim, LASERMINE_TEAM) == CS_TEAM_CT) && (cs_get_user_team(attacker) != CS_TEAM_CT))
			return PLUGIN_CONTINUE

		// Если мина установлена зомби, а владелец мины и атакующий в разных командах - урон мине могун наносить все
		if((CsTeams:pev(victim, LASERMINE_TEAM) == CS_TEAM_T) && ((cs_get_user_team(i_Owner) != CS_TEAM_T) || (CsTeams:pev(victim, LASERMINE_TEAM) != cs_get_user_team(attacker))))
			return PLUGIN_CONTINUE

		return HAM_SUPERCEDE
	}
	return PLUGIN_CONTINUE
}

public delaycount(id)
{
	g_dcount[id] = floatround(get_gametime());
}

bool:CheckTime(id)
{
	g_nowtime = floatround(get_gametime()) - g_dcount[id];
	if(g_nowtime >= get_pcvar_num(g_LDELAY))
		return true;
	return false;
}

public CreateLaserMine_Progress_b(id)
{
	if(get_pcvar_num(g_LCMDMODE) != 0)
		CreateLaserMine_Progress(id);
	return PLUGIN_HANDLED;
}

public CreateLaserMine_Progress(id)
{

	if(!CreateCheck(id))
		return PLUGIN_HANDLED;
	g_settinglaser[id] = true;

	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(1);
	write_byte(0);
	message_end();

	set_task(1.2, "Spawn", (TASK_PLANT + id));

	return PLUGIN_HANDLED;
}

public ReturnLaserMine_Progress(id)
{

	if(!ReturnCheck(id))
		return PLUGIN_HANDLED;
	g_settinglaser[id] = true;

	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(1);
	write_byte(0);
	message_end();

	set_task(1.2, "ReturnMine", (TASK_RELEASE + id));

	return PLUGIN_HANDLED;
}

public StopCreateLaserMine(id)
{

	DeleteTask(id);
	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(0);
	write_byte(0);
	message_end();

	return PLUGIN_HANDLED;
}

public StopReturnLaserMine(id)
{

	DeleteTask(id);
	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(0);
	write_byte(0);
	message_end();

	return PLUGIN_HANDLED;
}

public ReturnMine(id)
{
	id -= TASK_RELEASE;
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 70.0) return;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return;
	if(pev(tgt,LASERMINE_OWNER) != id) return;
	RemoveEntity(tgt);

	g_havemine[id] ++;
	g_deployed[id] --;
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ShowAmmo(id)

	return;
}

public Spawn(id)
{
	id -= TASK_PLANT
	// motor
	new i_Ent = engfunc(EngFunc_CreateNamedEntity,g_EntMine);
	if(!i_Ent)
	{
		client_print(id, print_chat,"[Lasermine Debug] Can't Create Entity");
		return PLUGIN_HANDLED_MAIN;
	}
	set_pev(i_Ent,pev_classname,ENT_CLASS_NAME);

	engfunc(EngFunc_SetModel,i_Ent,ENT_MODELS);

	set_pev(i_Ent,pev_solid,SOLID_NOT);
	set_pev(i_Ent,pev_movetype,MOVETYPE_FLY);

	set_pev(i_Ent,pev_frame,0);
	set_pev(i_Ent,pev_body,3);
	set_pev(i_Ent,pev_sequence,TRIPMINE_WORLD);
	set_pev(i_Ent,pev_framerate,0);
	set_pev(i_Ent,pev_takedamage,DAMAGE_YES);
	set_pev(i_Ent,pev_dmg,100.0);
	set_user_health(i_Ent,get_pcvar_num(g_LHEALTH));
	new Float:vOrigin[3];
	new	Float:vNewOrigin[3],Float:vNormal[3],Float:vTraceDirection[3],
		Float:vTraceEnd[3],Float:vEntAngles[3];
	pev(id, pev_origin, vOrigin);
	velocity_by_aim(id, 128, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0);
	new Float:fFraction;
	get_tr2(0, TR_flFraction, fFraction);

	// -- We hit something!
	if(fFraction < 1.0)
	{
		// -- Save results to be used later.
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vNormal);
	}


	xs_vec_mul_scalar(vNormal, 8.0, vNormal);
	xs_vec_add(vTraceEnd, vNormal, vNewOrigin);

	engfunc(EngFunc_SetSize, i_Ent, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 });
	engfunc(EngFunc_SetOrigin, i_Ent, vNewOrigin);

	// -- Rotate tripmine.
	vector_to_angle(vNormal,vEntAngles);
	set_pev(i_Ent,pev_angles,vEntAngles);

	// -- Calculate laser end origin.
	new Float:vBeamEnd[3], Float:vTracedBeamEnd[3];
		 
	xs_vec_mul_scalar(vNormal, 8192.0, vNormal);
	xs_vec_add(vNewOrigin, vNormal, vBeamEnd);

	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, IGNORE_MONSTERS, -1, 0);

	get_tr2(0, TR_vecPlaneNormal, vNormal);
	get_tr2(0, TR_vecEndPos, vTracedBeamEnd);

	// -- Save results to be used later.
	set_pev(i_Ent, LASERMINE_OWNER, id);
	set_pev(i_Ent,LASERMINE_BEAMENDPOINT,vTracedBeamEnd);
	set_pev(i_Ent,LASERMINE_TEAM,int:cs_get_user_team(id));
	new Float:fCurrTime = get_gametime();

	set_pev(i_Ent,LASERMINE_POWERUP, fCurrTime + 2.5);
	set_pev(i_Ent,LASERMINE_STEP,POWERUP_THINK);
	set_pev(i_Ent,pev_nextthink, fCurrTime + 0.2);

	PlaySound(i_Ent,POWERUP_SOUND);
	g_deployed[id]++;
	g_havemine[id]--;
	DeleteTask(id);
	ShowAmmo(id);
	return 1;
}

stock TeamDeployedCount(id)
{
	static i;
	static CsTeams:t;t = cs_get_user_team(id);
	static cnt;cnt=0;

	for(i = 1;i <= g_MaxPL;i++)
	{
		if(is_user_connected(i))
			if(t == cs_get_user_team(i))
				cnt += g_deployed[i];
	}

	return cnt;
}

bool:CheckCanTeam(id)
{
	new arg[5],CsTeam:num;
	get_pcvar_string(g_LCBT,arg,3);
	if(equali(arg,"Z"))
	{
		num = CsTeam:CS_TEAM_T;
	}
	else if(equali(arg,"H"))
	{
		num = CsTeam:CS_TEAM_CT;
	}
	else if(equali(arg,"ALL") || equali(arg,"HZ") || equali(arg,"ZH"))
	{
		num = CsTeam:CS_TEAM_UNASSIGNED;
	}
	else
	{
		num = CsTeam:CS_TEAM_UNASSIGNED;
	}
	if(num != CsTeam:CS_TEAM_UNASSIGNED && num != CsTeam:cs_get_user_team(id))
		return false;
	return true;
}

bool:CanCheck(id,mode)	// Проверки: когда можно ставить мины
{
	if(!get_pcvar_num(g_LENABLE))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NOTACTIVE")

		return false;
	}
	if(get_pcvar_num(g_LACCESS) != 0)
		if(!(get_user_flags(id) & ADMIN_IMMUNITY))
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NOACCESS")
			return false;
		}
	if(!pev_user_alive(id)) return false;
	if(!CheckCanTeam(id))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_CBT")
		return false;
	}
	if(mode == 0)
	{
		if(g_havemine[id] <= 0)
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_DONTHAVEMINE")
			return false;
		}
	}
	if(mode == 1)
	{
		if(get_pcvar_num(g_LBUYMODE) == 0)
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_CANTBUY")
			return false;
		}
		if(g_havemine[id] >= get_pcvar_num(g_LAMMO))
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_HAVEMAX")
			return false;
		}
		if(zp_get_user_ammo_packs(id) < get_pcvar_num(g_LCOST))
		{
			client_print(id, print_chat, "%L %L%d %L", id, "CHATTAG",id, "STR_NOMONEY",get_pcvar_num(g_LCOST),id, "STR_NEEDED")
			return false;
		}
	}
	if(!CheckTime(id))
	{
		client_print(id, print_chat, "%L %L %d %L", id, "CHATTAG",id, "STR_DELAY",get_pcvar_num(g_LDELAY)-g_nowtime,id, "STR_SECONDS")
		return false;
	}

	return true;
}

bool:ReturnCheck(id)
{
	if(!CanCheck(id,-1)) return false;
	if(g_havemine[id] + 1 > get_pcvar_num(g_LAMMO)) return false;
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return false;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 70.0) return false;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return false;
	if(pev(tgt,LASERMINE_OWNER) != id) return false;
	return true;
}

bool:CreateCheck(id)
{
	if(!CanCheck(id,0)) return false;

	// Проверка на разрешение
	if(!zp_has_round_started() && get_pcvar_num(g_NOROUND))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NOROUND")
		return false;
	}

	if(zp_is_nemesis_round() && get_pcvar_num(g_NEMROUND))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NEMROUND")
		return false;
	}

	if(zp_is_survivor_round() && get_pcvar_num(g_SURVROUND))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_SURVROUND")
		return false;
	}
	
	if(zp_is_swarm_round() && get_pcvar_num(g_SWARROUND))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_SWARROUND")
		return false;
	}
	
	if(zp_is_assassin_round() && get_pcvar_num(g_ASSROUND))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_ASSROUND")
		return false;
	}

	if(g_deployed[id] >= get_pcvar_num(g_LAMMO))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_MAXDEPLOY")
		return false;
	}

	if(TeamDeployedCount(id) >= get_pcvar_num(g_LTMAX))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_MANYPPL")
		return false;
	}
	new Float:vTraceDirection[3], Float:vTraceEnd[3],Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	velocity_by_aim(id, 128, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0);
	new Float:fFraction,Float:vTraceNormal[3];
	get_tr2(0, TR_flFraction, fFraction);
	// -- We hit something!
	if(fFraction < 1.0)
	{
		// -- Save results to be used later.
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vTraceNormal);

		return true;
	}

	client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_PLANTWALL")
	DeleteTask(id);
	// -- Did not touched something. (not solid)
	return false;
}

public ltm_Think(i_Ent)
{
	if(!pev_valid(i_Ent))
		return FMRES_IGNORED;
	new EntityName[32];
	pev(i_Ent, pev_classname, EntityName, 31);
	if(!get_pcvar_num(g_LENABLE)) return FMRES_IGNORED;
	// -- Entity is not a tripmine, ignoring the next...
	if(!equal(EntityName, ENT_CLASS_NAME))
		return FMRES_IGNORED;

	static Float:fCurrTime;
	fCurrTime = get_gametime();

	switch(pev(i_Ent, LASERMINE_STEP))
	{
		case POWERUP_THINK :
		{
			new Float:fPowerupTime;
			pev(i_Ent, LASERMINE_POWERUP, fPowerupTime);

			if(fCurrTime > fPowerupTime)
			{
				set_pev(i_Ent, pev_solid, SOLID_BBOX);
				set_pev(i_Ent, LASERMINE_STEP, BEAMBREAK_THINK);

				PlaySound(i_Ent, ACTIVATE_SOUND);
			}
			if(get_pcvar_num(g_LGLOW)!=0)
			{
				if(get_pcvar_num(g_LCLMODE)==0)
				{
					switch (pev(i_Ent,LASERMINE_TEAM))
					{
						// цвет лазера Зомби
						case CS_TEAM_T: set_rendering(i_Ent,kRenderFxGlowShell,Red_Zomb,Green_Zomb,Blue_Zomb,kRenderNormal,10);
						// цвет лазера Человека
						case CS_TEAM_CT:set_rendering(i_Ent,kRenderFxGlowShell,Red_Hum,Green_Hum,Blue_Hum,kRenderNormal, 10);
					}
				}else
				{
					// цвет лазера, если стоит "одинаковый для всех" цвет
					set_rendering(i_Ent,kRenderFxGlowShell,random_num(50 , 200),random_num(50 , 200),random_num(50 , 200),kRenderNormal, 10);
				}
			}
			set_pev(i_Ent, pev_nextthink, fCurrTime + 0.1);
		}
		case BEAMBREAK_THINK :
		{
			static Float:vEnd[3],Float:vOrigin[3];
			pev(i_Ent, pev_origin, vOrigin);
			pev(i_Ent, LASERMINE_BEAMENDPOINT, vEnd);

			static iHit, Float:fFraction;
			engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, 0);

			get_tr2(0, TR_flFraction, fFraction);
			iHit = get_tr2(0, TR_pHit);

			// -- Something has passed the laser.
			if(fFraction < 1.0)
			{
				// -- Ignoring others tripmines entity.
				if(pev_valid(iHit))
				{
					pev(iHit, pev_classname, EntityName, 31);
					// Игнорим всякую хрень
					if(!equal(EntityName, ENT_CLASS_NAME) && !equal(EntityName, gSnarkClassName) && !equal(EntityName, barnacle_class) && !equal(EntityName, weapon_box))
					{
						set_pev(i_Ent, pev_enemy, iHit);

						if(get_pcvar_num(g_LMODE) == MODE_LASERMINE)
							CreateLaserDamage(i_Ent,iHit);
						else
							if(get_pcvar_num(g_LFF) || CsTeams:pev(i_Ent,LASERMINE_TEAM) != cs_get_user_team(iHit))
								set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);

						if (!pev_valid(i_Ent))	// если не верный объект - ничего не делаем. Спасибо DJ_WEST
							return FMRES_IGNORED;

						set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
					}
				}
			}
			if(get_pcvar_num(g_LDMGMODE)!=0)
				if(pev(i_Ent,LASERMINE_HITING) != iHit)
					set_pev(i_Ent,LASERMINE_HITING,iHit);
 
			// -- Tripmine is still there.
			if(pev_valid(i_Ent))
			{
				static Float:fHealth;
				pev(i_Ent, pev_health, fHealth);

				if(fHealth <= 0.0 || (pev(i_Ent,pev_flags) & FL_KILLME))
				{
				set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);
				set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
				}
										 
				static Float:fBeamthink;
				pev(i_Ent, LASERMINE_BEAMTHINK, fBeamthink);
						 
				if(fBeamthink < fCurrTime && get_pcvar_num(g_LVISIBLE))
				{
					DrawLaser(i_Ent, vOrigin, vEnd);
					set_pev(i_Ent, LASERMINE_BEAMTHINK, fCurrTime + 0.1);
				}
				set_pev(i_Ent, pev_nextthink, fCurrTime + 0.01);
			}
		}
		case EXPLOSE_THINK :
		{
			// -- Stopping entity to think
			set_pev(i_Ent, pev_nextthink, 0.0);
			PlaySound(i_Ent, STOP_SOUND);
			g_deployed[pev(i_Ent,LASERMINE_OWNER)]--;
			CreateExplosion(i_Ent);
			CreateDamage(i_Ent,get_pcvar_float(g_LRDMG),get_pcvar_float(g_LRADIUS))
			RemoveEntity	(i_Ent);
		}
	}

	return FMRES_IGNORED;
}

PlaySound(i_Ent, i_SoundType)
{
	switch (i_SoundType)
	{
		case POWERUP_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, 0, PITCH_NORM);
		}
		case ACTIVATE_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, 1, 75);
		}
		case STOP_SOUND :
		{
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, SND_STOP, 75);
		}
	}
}

DrawLaser(i_Ent, const Float:v_Origin[3], const Float:v_EndOrigin[3])
{
	new tcolor[3];
	new teamid = pev(i_Ent, LASERMINE_TEAM);
	if(get_pcvar_num(g_LCLMODE) == 0)
	{
		switch(teamid){
			case 1:{
				// Цвет луча для Зомби
				tcolor[0] = Red_Zomb;
				tcolor[1] = Green_Zomb;
				tcolor[2] = Blue_Zomb;
			}
			case 2:{
				// Цвет луча для Человека
				tcolor[0] = Red_Hum;
				tcolor[1] = Green_Hum;
				tcolor[2] = Blue_Hum;
			}
		}
	}else
	{
		// Цвет луча для всез при режиме 1-н луч для всех
		tcolor[0] = random_num(50 , 200);
		tcolor[1] = random_num(50 , 200);
		tcolor[2] = random_num(50 , 200);
	}
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,v_Origin[0]);
	engfunc(EngFunc_WriteCoord,v_Origin[1]);
	engfunc(EngFunc_WriteCoord,v_Origin[2]);
	engfunc(EngFunc_WriteCoord,v_EndOrigin[0]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[1]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[2]); //Random
	write_short(beam);
	write_byte(0);
	write_byte(0);
	write_byte(1);	//Life
	write_byte(5);	//Width
	write_byte(0);	//wave
	write_byte(tcolor[0]); // r
	write_byte(tcolor[1]); // g
	write_byte(tcolor[2]); // b
	write_byte(get_pcvar_num(g_LCBRIGHT));
	write_byte(255);
	message_end();
}

CreateDamage(iCurrent,Float:DmgMAX,Float:Radius)
{
	// Get given parameters
	new Float:vecSrc[3];
	pev(iCurrent, pev_origin, vecSrc);

	new AtkID =pev(iCurrent,LASERMINE_OWNER);
	new TeamID=pev(iCurrent,LASERMINE_TEAM);

	new ent = -1;
	new Float:tmpdmg = DmgMAX;

	new Float:kickback = 0.0;
	// Needed for doing some nice calculations :P
	new Float:Tabsmin[3], Float:Tabsmax[3];
	new Float:vecSpot[3];
	new Float:Aabsmin[3], Float:Aabsmax[3];
	new Float:vecSee[3];
	new trRes;
	new Float:flFraction;
	new Float:vecEndPos[3];
	new Float:distance;
	new Float:origin[3], Float:vecPush[3];
	new Float:invlen;
	new Float:velocity[3];
	new iHitHP,iHitTeam;
	// Calculate falloff
	new Float:falloff;
	if(Radius > 0.0)
	{
		falloff = DmgMAX / Radius;
	} else {
		falloff = 1.0;
	}
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		if(!pev_valid(ent)) continue;
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
		{
			// Entity is not a player or monster, ignore it
			continue;
		}
		if(!pev_user_alive(ent)) continue;
		// Reset data
		kickback = 1.0;
		tmpdmg = DmgMAX;
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(ent, pev_absmin, Tabsmin);
		pev(ent, pev_absmax, Tabsmax);
		xs_vec_add(Tabsmin,Tabsmax,Tabsmin);
		xs_vec_mul_scalar(Tabsmin,0.5,vecSpot);
		pev(iCurrent, pev_absmin, Aabsmin);
		pev(iCurrent, pev_absmax, Aabsmax);
		xs_vec_add(Aabsmin,Aabsmax,Aabsmin);
		xs_vec_mul_scalar(Aabsmin,0.5,vecSee);
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, iCurrent, trRes);
		get_tr2(trRes, TR_flFraction, flFraction);
		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if(flFraction >= 0.9 || get_tr2(trRes, TR_pHit) == ent)
		{
			// Work out the distance between impact and entity
			get_tr2(trRes, TR_vecEndPos, vecEndPos);
			distance = get_distance_f(vecSrc, vecEndPos) * falloff;
			tmpdmg -= distance;
			if(tmpdmg < 0.0)
				tmpdmg = 0.0;
			// Kickback Effect
			if(kickback != 0.0)
			{
				xs_vec_sub(vecSpot,vecSee,origin);
				invlen = 1.0/get_distance_f(vecSpot, vecSee);

				xs_vec_mul_scalar(origin,invlen,vecPush);
				pev(ent, pev_velocity, velocity)
				xs_vec_mul_scalar(vecPush,tmpdmg,vecPush);
				xs_vec_mul_scalar(vecPush,kickback,vecPush);
				xs_vec_add(velocity,vecPush,velocity);
				if(tmpdmg < 60.0)
				{
					xs_vec_mul_scalar(velocity,12.0,velocity);
				} else {
					xs_vec_mul_scalar(velocity,4.0,velocity);
				}
				if(velocity[0] != 0.0 || velocity[1] != 0.0 || velocity[2] != 0.0)
				{
					// There's some movement todo :)
					set_pev(ent, pev_velocity, velocity)
				}
			}

			iHitHP = pev_user_health(ent) - floatround(tmpdmg)
			iHitTeam = int:cs_get_user_team(ent)
			if(iHitHP <= 0)
			{
				if(iHitTeam != TeamID)
				{
					zp_set_user_ammo_packs(AtkID,zp_get_user_ammo_packs(AtkID) + get_pcvar_num(g_LFMONEY))
					set_score(AtkID,ent,1,iHitHP)
				}else
				{
					if(get_pcvar_num(g_LFF))
					{
						zp_set_user_ammo_packs(AtkID,zp_get_user_ammo_packs(AtkID) - get_pcvar_num(g_LFMONEY))
						set_score(AtkID,ent,-1,iHitHP)
					}
				}
			}else
			{
				if(iHitTeam != TeamID || get_pcvar_num(g_LFF))
				{
					//set_pev(Player,pev_health,iHitHP)
					set_user_health(ent, iHitHP)
					engfunc(EngFunc_MessageBegin,MSG_ONE_UNRELIABLE,g_msgDamage,{0.0,0.0,0.0},ent);
					write_byte(floatround(tmpdmg))
					write_byte(floatround(tmpdmg))
					write_long(DMG_BULLET)
					engfunc(EngFunc_WriteCoord,vecSrc[0])
					engfunc(EngFunc_WriteCoord,vecSrc[1])
					engfunc(EngFunc_WriteCoord,vecSrc[2])
					message_end()
				}
			}
		}
	}
	return
}

bool:pev_user_alive(ent)
{
	new deadflag = pev(ent,pev_deadflag);
	if(deadflag != DEAD_NO)
		return false;
	return true;
}

CreateExplosion(iCurrent)
{
	new Float:vOrigin[3];
	pev(iCurrent,pev_origin,vOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(99); //99 = KillBeam
	write_short(iCurrent);
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord,vOrigin[0]);
	engfunc(EngFunc_WriteCoord,vOrigin[1]);
	engfunc(EngFunc_WriteCoord,vOrigin[2]);
	write_short(boom);
	write_byte(30);
	write_byte(15);
	write_byte(0);
	message_end();
}

CreateLaserDamage(iCurrent,isHit)
{
	if(isHit < 0) return PLUGIN_CONTINUE
	switch(get_pcvar_num(g_LDMGMODE))
	{
		case 1:
		{
			if(pev(iCurrent,LASERMINE_HITING) == isHit)
				return PLUGIN_CONTINUE
		}
		case 2:
		{
			if(pev(iCurrent,LASERMINE_HITING) == isHit)
			{
				static Float:cnt
				static now,htime;now = floatround(get_gametime())

				pev(iCurrent,LASERMINE_COUNT,cnt)
				htime = floatround(cnt)
				if(now - htime < get_pcvar_num(g_LDSEC))
				{
					return PLUGIN_CONTINUE;
				}else{
					set_pev(iCurrent,LASERMINE_COUNT,get_gametime())
				}
			}else
			{
				set_pev(iCurrent,LASERMINE_COUNT,get_gametime())
			}
		}
	}

	new Float:vOrigin[3],Float:vEnd[3]
	pev(iCurrent,pev_origin,vOrigin)
	pev(iCurrent,pev_vuser1,vEnd)

	new teamid = pev(iCurrent, LASERMINE_TEAM)

	new szClassName[32]
	new Alive,God
	new iHitTeam,iHitHP,id
	new hitscore

	szClassName[0] = '^0'
	pev(isHit,pev_classname,szClassName,32)
	if((pev(isHit, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
	{
		Alive = pev_user_alive(isHit)
		God = get_user_godmode(isHit)
		if(!Alive || God) return PLUGIN_CONTINUE
		iHitTeam = int:cs_get_user_team(isHit)
		iHitHP = pev_user_health(isHit) - get_pcvar_num(g_LDMG)
		id = pev(iCurrent,LASERMINE_OWNER)//, szNetName[32]
		if(iHitHP <= 0)
		{
			if(iHitTeam != teamid)
			{
				emit_sound(isHit, CHAN_WEAPON, ENT_SOUND4, 1.0, ATTN_NORM, 0, PITCH_NORM)
				hitscore = 1
				zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + get_pcvar_num(g_LFMONEY))
				set_score(id,isHit,hitscore,iHitHP)
			}else
			{
				if(get_pcvar_num(g_LFF))
				{
					emit_sound(isHit, CHAN_WEAPON, ENT_SOUND4, 1.0, ATTN_NORM, 0, PITCH_NORM)
					hitscore = -1
					zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) - get_pcvar_num(g_LFMONEY))
					set_score(id,isHit,hitscore,iHitHP)
				}
			}
		}else if(iHitTeam != teamid || get_pcvar_num(g_LFF))
		{
			emit_sound(isHit, CHAN_WEAPON, ENT_SOUND4, 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_user_health(isHit,iHitHP)
			set_pev(iCurrent,LASERMINE_HITING,isHit);
			engfunc(EngFunc_MessageBegin,MSG_ONE_UNRELIABLE,g_msgDamage,{0.0,0.0,0.0},isHit);
			write_byte(get_pcvar_num(g_LDMG))
			write_byte(get_pcvar_num(g_LDMG))
			write_long(DMG_BULLET)
			engfunc(EngFunc_WriteCoord,vOrigin[0])
			engfunc(EngFunc_WriteCoord,vOrigin[1])
			engfunc(EngFunc_WriteCoord,vOrigin[2])
			message_end()
		}
	}else if(equal(szClassName, ENT_CLASS_NAME3))
	{
		new hl;
		hl = pev_user_health(isHit);
		set_user_health(isHit,hl-get_pcvar_num(g_LDMG));
	}
	return PLUGIN_CONTINUE
}

stock pev_user_health(id)
{
	new Float:health
	pev(id,pev_health,health)
	return floatround(health)
}

stock set_user_health(id,health)
{
	health > 0 ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

stock get_user_godmode(index) {
	new Float:val
	pev(index, pev_takedamage, val)

	return (val == DAMAGE_NO)
}

stock set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags))

	return 1
}

stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}

set_score(id,target,hitscore,HP){

	new idfrags = pev_user_frags(id) + hitscore// get_user_frags(id) + hitscore
	set_user_frags(id,idfrags)
	new tarfrags = pev_user_frags(target) + 1 //get_user_frags(target) + 1
	set_user_frags(target,tarfrags)
	new idteam = int:cs_get_user_team(id)
	new iddeaths = cs_get_user_deaths(id)


	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string(ENT_CLASS_NAME)
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(idfrags)
	write_short(iddeaths)
	write_short(0)
	write_short(idteam)
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)

	set_user_health(target, HP)

}

public BuyLasermine(id)
{
	if(!CanCheck(id,1)) return PLUGIN_CONTINUE

	g_havemine[id]++;

	client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_BOUGHT")

	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ShowAmmo(id)
	return PLUGIN_HANDLED
}

public BuyLasermineChat(id)
{
	if(!CanCheck(id,1)) return PLUGIN_CONTINUE

	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) - get_pcvar_num(g_LCOST))
	g_havemine[id]++;

	client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_BOUGHT")

	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ShowAmmo(id)
	return PLUGIN_HANDLED
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_LME)
		BuyLasermine(id)

	if(g_havemine[id] >= get_pcvar_num(g_LAMMO))
			return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

ShowAmmo(id)
{ 
	new ammo[51] 
	new PlugStat[ 555 char ];
	formatex(PlugStat, charsmax(PlugStat), "%L", LANG_PLAYER, "STR_STATE")
	formatex(ammo, 50, "%s %i/%i",PlugStat, g_havemine[id],get_pcvar_num(g_LAMMO))

	message_begin(MSG_ONE, g_msgStatusText, {0,0,0}, id) 
	write_byte(0) 
	write_string(ammo) 
	message_end() 
} 

public showInfo(id)
{
	client_print(id, print_chat, "%L", id, "STR_REF")
}

public say_lasermine(id){
	new said[32]
	read_argv(1,said,31);
	if(!get_pcvar_num(g_LENABLE))
	{
		return PLUGIN_CONTINUE
	}
	if(equali(said,"/buy lasermine")||equali(said,"/lm")||equali(said,"buy_lasermine")){
		BuyLasermineChat(id)
	}else if(equali(said, "lasermine") || equali(said, "/lasermine")){
		const SIZE = 1024
		new msg[SIZE+1],len = 0;
		len += formatex(msg[len], SIZE - len, "<html><body>")
		len += formatex(msg[len], SIZE - len, "<p><b>LaserMine</b></p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p>You can be setting the mine on the wall.</p><br/>")
		len += formatex(msg[len], SIZE - len, "<p>That laser will give what touched it damage.</p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p><b>LaserMine Commands</b></p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p><b>Say /buy lasermine</b> or <b>Say /lm</b> //buying lasermine<br/>")
		len += formatex(msg[len], SIZE - len, "<b>buy_lasermine</b> //bind ^"F2^" buy_lasermine : using F2 buying lasermine<br/>")
		len += formatex(msg[len], SIZE - len, "<b>+setlaser</b> //bind mouse3 +setlaser : using mouse3 set lasermine on wall<br/>")
		len += formatex(msg[len], SIZE - len, "</body></html>")
		show_motd(id, msg, "Lasermine Entity help")
		return PLUGIN_CONTINUE
	}
	else if(containi(said, "laser") != -1) {
		showInfo(id)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public standing(id) 
{
	if(!g_settinglaser[id])
		return PLUGIN_CONTINUE

	set_pev(id, pev_maxspeed, 1.0)

	return PLUGIN_CONTINUE
}

public ltm_PostThink(id) 
{
	if(!g_settinglaser[id] && plsetting[id]){
		resetspeed(id)
	}
	else if(g_settinglaser[id] && !plsetting[id]) {
		pev(id, pev_maxspeed,plspeed[id])
		set_pev(id, pev_maxspeed, 1.0)
	}
	plsetting[id] = g_settinglaser[id]
	return FMRES_IGNORED
}

public ltm_PreThink(id)
{
	if(!pev_user_alive(id) || g_settinglaser[id] == true || is_user_bot(id) || get_pcvar_num(g_LCMDMODE) == 1)
		return FMRES_IGNORED;

	if(pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE))
		CreateLaserMine_Progress(id)
	return FMRES_IGNORED;
}

resetspeed(id)
{
	set_pev(id, pev_maxspeed, plspeed[id])
}

public client_putinserver(id){
	g_deployed[id] = 0;
	g_havemine[id] = 0;
	DeleteTask(id);
	return PLUGIN_CONTINUE
}

public client_disconnected(id){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
	DeleteTask(id);
	RemoveAllTripmines(id);
	return PLUGIN_CONTINUE
}


public newround(id){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
	pev(id, pev_maxspeed,plspeed[id])
	DeleteTask(id);
	RemoveAllTripmines(id);
	//client_print(id, print_chat, "[ZP][LM][DeBug] All Mines removied!");
	delaycount(id);
	SetStartAmmo(id);
	return PLUGIN_CONTINUE
}

public endround(id)
{
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE

	// Удаление мин после конца раунда
	DeleteTask(id);
	RemoveAllTripmines(id);

	return PLUGIN_CONTINUE
}

public DeathEvent(){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE

	new id = read_data(2)
	if(is_user_connected(id)) DeleteTask(id);
	return PLUGIN_CONTINUE
}

public RemoveAllTripmines(i_Owner)
{
	new iEnt = g_MaxPL + 1;
	new clsname[32];
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", ENT_CLASS_NAME)))
	{
		if(i_Owner)
		{
			if(pev(iEnt, LASERMINE_OWNER) != i_Owner)
				continue;
			clsname[0] = '^0'
			pev(iEnt, pev_classname, clsname, sizeof(clsname)-1);
			if(equali(clsname, ENT_CLASS_NAME))
			{
				PlaySound(iEnt, STOP_SOUND);
				RemoveEntity(iEnt);
			}
		}
		else
			set_pev(iEnt, pev_flags, FL_KILLME);
	}
	g_deployed[i_Owner]=0;
}

SetStartAmmo(id)
{
	new stammo = get_pcvar_num(g_LSTAMMO);
	if(stammo <= 0) return PLUGIN_CONTINUE;
	g_havemine[id] = (g_havemine[id] <= stammo) ? stammo : g_havemine[id];
	return PLUGIN_CONTINUE;
}

public CutDeploy_onDamage(id)
{
	if(get_user_health(id) < 1)
		DeleteTask(id);
}

DeleteTask(id)
{
	if(task_exists((TASK_PLANT + id)))
	{
		remove_task((TASK_PLANT + id))
	}
	if(task_exists((TASK_RELEASE + id)))
	{
		remove_task((TASK_RELEASE + id))
	}
	g_settinglaser[id] = false
	return PLUGIN_CONTINUE;
}

// Gets offset data
get_offset_value(id, type)
{
	new key = -1;
	switch(type)
	{
		case OFFSET_TEAM: key = OFFSET_TEAM;
		case OFFSET_MONEY:
		key = OFFSET_MONEY;
		case OFFSET_DEATH: key = OFFSET_DEATH;
	}
	if(key != -1)
	{
		return get_pdata_int(id, key);
	}
	return -1;
}

stock Get_Laser_By_Aim(id)
{
   new entList[1]
   new Float:fOrigin[3],Float:vAngles[3],Float:vecReturn[3]
   entity_get_vector(id, EV_VEC_origin, fOrigin)
   fOrigin[2] += 10
   entity_get_vector(id, EV_VEC_v_angle, vAngles)

   for(new Float:i=0.0;i<=1000.0;i+=20.0)
   {
		Vector_By_Angle(fOrigin, vAngles, i, 1, vecReturn)
		find_sphere_class(0, "lasermine", 10.0, entList, 1, vecReturn)
   }
   return entList[0]
}

stock Vector_By_Angle(Float:fOrigin[3],Float:vAngles[3], Float:multiplier, FRU, Float:vecReturn[3])
{
   angle_vector(vAngles, FRU, vecReturn)
   vecReturn[0] = vecReturn[0] * multiplier + fOrigin[0]
   vecReturn[1] = vecReturn[1] * multiplier + fOrigin[1]
   vecReturn[2] = vecReturn[2] * multiplier + fOrigin[2]
}

stock cmdExecute(id, const szText[], any:...) 
{
    #pragma unused szText

    if (id == 0 || is_user_connected(id))
	{
    	new szMessage[256]

    	format_args( szMessage ,charsmax(szMessage), 1)

        message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
        write_byte(strlen(szMessage) + 2)
        write_byte(10)
        write_string(szMessage)
        message_end()
    }
}