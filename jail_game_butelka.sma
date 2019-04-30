#include <amxmodx>
#include <xs>
#include <fakemeta_util>
#include <jailbreak>

#define PLUGIN "JailBreak: Chowanie Butelki"
#define VERSION "1.0"
#define AUTHOR "MarWit & O'Zone"

new id_zabawa, iBottleOwner, bool:bGame;

new const gszBottle[] = "models/winebottle.mdl";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_CmdStart, "fwCmdStart");
	
	id_zabawa = jail_register_game("Szukanie Butelki");
}

public plugin_precache()
{
	precache_model(gszBottle);
	precache_generic("sound/reload/butelka.mp3");
}
	
public OnDayStartPre(iDay, szDayName[256], szInfo[256], iSettings[10], iRoundTime)
{
	if(iDay != id_zabawa) return;

	format(szDayName, 255, "Szukanie Butelki");
	format(szInfo, 255, "Zasady:^nStraznicy chowaja butelke.^nPo schowaniu maja 15 sec na schowanie sie.^nWiezien, ktory znajdzie butelke ma zyczenie.");

	iSettings[0] = 1;
	iSettings[1] = 1;
	iSettings[2] = 1;
	iSettings[4] = 1;
	
	jail_set_ct_hit_tt(true);  
	jail_set_god_ct(true);
}

public OnDayStartPost(iDay)
{
	if(iDay != id_zabawa) return;
	
	bGame = true;

	iBottleOwner = RandomPlayer(2);
	
	if(!iBottleOwner) return;

	for(new i = 1; i < 33; i ++) if(is_user_alive(i) && get_user_team(i) == 1) set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN);

	for(new i = 1; i < 33; i ++) 
	{
		if(is_user_alive(i) && get_user_team(i) == 2) 
		{
			fm_strip_user_weapons(i);
			fm_give_item(i, "weapon_knife");
		}
	}
	client_print_color(iBottleOwner, iBottleOwner, "^x04[WIEZIENIE CS-RELOAD]^x01 Dostales butelke. Szybko, ukryj ja gdzies!");
}

public OnLastPrisonerWishTaken(id)
	OnRemoveData(jail_get_play_game_id());

public OnRemoveData(day)
	if(day == id_zabawa) bGame = false;

public fwCmdStart(id, ucHandle)
{
	if(!bGame || !(get_uc(ucHandle, UC_Buttons) & IN_USE) || pev(id, pev_oldbuttons) & IN_USE) return FMRES_IGNORED;

	new iTR = create_tr2();
	new Float:fOrigin[3], Float:fEnd[3];
	
	pev(id, pev_origin, fOrigin);
	pev(id, pev_view_ofs, fEnd);
	xs_vec_add(fOrigin, fEnd, fOrigin);
	
	pev(id, pev_v_angle, fEnd);
	engfunc(EngFunc_MakeVectors, fEnd);
	global_get(glb_v_forward, fEnd);
	
	xs_vec_mul_scalar(fEnd, 9999.0, fEnd);
	xs_vec_add(fOrigin, fEnd, fEnd);
	
	pev(id, pev_origin, fOrigin);

	if(id == iBottleOwner)
	{
		engfunc(EngFunc_TraceLine, fOrigin, fEnd, IGNORE_MONSTERS, id, iTR);
		get_tr2(iTR, TR_vecEndPos, fEnd);
	
		new iBottle = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
		set_pev(iBottle, pev_classname, "jail_bottle");
		engfunc(EngFunc_SetModel, iBottle, gszBottle);
		engfunc(EngFunc_SetSize, iBottle, { -3.0, -3.0, -3.0 }, { 3.0, 3.0, 3.0 });
		engfunc(EngFunc_SetOrigin, iBottle, fOrigin);
		set_pev(iBottle, pev_solid, SOLID_BBOX);
	
		iBottleOwner = 0;
		
		client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Butelka zostala schowana! Za^x03 15 sekund^x01 bedzie mozna zaczac jej szukac.");

		client_cmd(0, "mp3 play sound/reload/butelka.mp3");
	
		set_task(15.0, "taskUnfrezzeTT");
	}
	else if(get_user_team(id) == 1)
	{
		engfunc(EngFunc_TraceLine, fOrigin, fEnd, DONT_IGNORE_MONSTERS, id, iTR);
		
		new iEnt = get_tr2(iTR, TR_pHit);
		
		get_tr2(iTR, TR_vecEndPos, fEnd);
		
		new szClassName[33];
		
		if(pev_valid(iEnt))
		{
			pev(iEnt, pev_classname, szClassName, 32);
			if(equali(szClassName, "jail_bottle")) return findBottle(iEnt, id);
		}
		
		iEnt = 0;
		
		while((iEnt = fm_find_ent_in_sphere(iEnt, fEnd, 17.5)) > 0)
		{
			pev(iEnt, pev_classname, szClassName, 32);
			if(equali(szClassName, "jail_bottle")) return findBottle(iEnt, id);
		}
	}
		
	return FMRES_IGNORED;
}

public findBottle(iEnt, id)
{
	new szName[33];
	get_user_name(id, szName, charsmax(szName));
	
	client_print_color(0, id, "^x04[WIEZIENIE CS-RELOAD]^x01 Gratulacje dla^x03 %s^x01, ktory znalazl butelke! Wiezniowie gina, a on dostaje zyczenie.", szName);
	
	for(new i = 1; i < MAX; i ++) if(id != i && is_user_alive(i) && get_user_team(i) == 1) user_silentkill(i);

	engfunc(EngFunc_RemoveEntity, iEnt);
	
	return 0;
}

public taskUnfrezzeTT()
{
	for(new i = 1; i < 33; i ++) if(is_user_alive(i) && get_user_team(i) == 1) set_pev(i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN);

	jail_open_cele();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
