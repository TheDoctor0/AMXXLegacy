// Import Bibliotek

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
// Definicje rejestracyjne

#define PLUGIN	"Grenade Sack and Limiter"
#define VERSION	"0.5.1"
#define AUTHOR	"Benio101 & v3x"

// Informacje o pluginie

/*	Autorzy{
			Autor		[Godnosc, //Adres, M@il]

			Benio101	(Pawel Benetkiewicz, //pawel.pro, amxx@pawel.pro)
		&	v3x		(//forums.alliedmods.net/member.php?u=2782)
	};
*/
/*	Opis{
		Grenade Sack and Limiter to bazujacy na Grenade Sack v. 0.4.1 by v3x
		ktory zostal przez Benio101 dostosowany do limitacji kupowanych granatow
		wg podanych CVARow. Wspolpracuje on z innymi pluginami poprzez posiadane
		funkcje natywne, dzieki ktorym granaty dodawane sa automatycznie.
		Plugin kompatybilny ze wszelkimi innymi pluginami i dzialajacy wlasciwie
		po zastosowaniu dodawania granatow poprzez funkcje natywne.
	};
*/
/*	Zastosowanie{
		Grenade Sack and Limiter pozwala na:
			Zmiane limitow mozliwych do posiadania granatow,
			Limitacji kupowania granatow na runde,
			Automatyczna obsluge kupowania granatow, w pelni
				kompatybilna z innymi pluginami,
				dzieki funkcjom	natywnym.
	};
*/
/*	ChangeLog{
		B	v. 0.4.1	Grenade Sack (//amxx.pl/topic/1012-grenade-sack-041) by v3x		
		+	v. 0.5		Added Grenade Limiting by Benio101
		+	v. 0.5.1	Added native grenades adding by Benio101
	};
*/
/*	Licencja{		
			PAL (//bineo.biz/licencje/PAL)
	};
*/

// Ustalenie kosztow

#define CSTRIKE_DEFAULT_FB_COST 200
#define CSTRIKE_DEFAULT_HE_COST 300
#define CSTRIKE_DEFAULT_SG_COST 300

// Tresci komunikatow

new MSG_NO_FUNDS[] = "Nie masz wystarczajaco duzo pieniedzy!";
new MSG_CANT_CARRY[] = "Nie mozesz kupic kolejnych granatow!";

// Nazwy CVARow

new CVAR_STR_FB[] = "mp_max_fb";
new CVAR_STR_HE[] = "mp_max_he";
new CVAR_STR_SG[] = "mp_max_sg";

// Domyslne wartosci limitow

new VAL_DEF_FB[] = "2";
new VAL_DEF_HE[] = "1";
new VAL_DEF_SG[] = "1";

// Pojemniki i uchwyty

new he[33];
new fb[33];
new sg[33];

new NADE_PICKUP_SOUND[] = "items/9mmclip1.wav";

// The following block of code was VEN's idea
// --->
// initial AMXX version number supported CVAR pointers in get/set_pcvar_* natives
#define CVAR_POINTERS_AMXX_INIT_VER_NUM 170

// determine if get/set_pcvar_* natives can be used
#if defined AMXX_VERSION_NUM && AMXX_VERSION_NUM >= CVAR_POINTERS_AMXX_INIT_VER_NUM
	#define CVAR_POINTERS
	new g_PCVAR_FB;
	new g_PCVAR_HE;
	new g_PCVAR_SG;

	#define CVAR_FB get_pcvar_num(g_PCVAR_FB)
	#define CVAR_HE get_pcvar_num(g_PCVAR_HE)
	#define CVAR_SG get_pcvar_num(g_PCVAR_SG)
#else
	#define CVAR_FB get_cvar_num(CVAR_STR_FB)
	#define CVAR_HE get_cvar_num(CVAR_STR_HE)
	#define CVAR_SG get_cvar_num(CVAR_STR_SG)
#endif
// <---

// Inicjalizacja pluginu

public plugin_init() 
{
	register_plugin(PLUGIN , VERSION , AUTHOR);

#if defined CVAR_POINTERS
	g_PCVAR_FB = register_cvar(CVAR_STR_FB , VAL_DEF_FB);
	g_PCVAR_HE = register_cvar(CVAR_STR_HE , VAL_DEF_HE);
	g_PCVAR_SG = register_cvar(CVAR_STR_SG , VAL_DEF_SG);
#else
	register_cvar(CVAR_STR_FB , VAL_DEF_FB);
	register_cvar(CVAR_STR_HE , VAL_DEF_HE);
	register_cvar(CVAR_STR_SG , VAL_DEF_SG);
#endif

	register_message(get_user_msgid("TextMsg") , "block_message");
	register_event("HLTV" , "new_round" , "a" , "1=0" , "2=0");
	register_touch("armoury_entity" , "player" , "touch_player");
	RegisterHam(Ham_Spawn, "player", "fillGrenadesNumberOneInfo", 1);
	register_clcmd("flash","fb_buy");
	register_clcmd("hegren","he_buy");
	register_clcmd("sgren","sg_buy");
	
	check_mod();
}

// Zerowanie limitow

public client_putinserver(id){
	if(is_user_connected(id)){
		he[id]=0;
		fb[id]=0;
		sg[id]=0;
	}
}

new Float:g_GameTime;

public plugin_precache()
	precache_sound(NADE_PICKUP_SOUND);

// Funkcje natywne

public fb_buy(id){
	if(fb[id]<CVAR_FB){
		++fb[id];
		if(get_nade_num(CSW_FLASHBANG) > 2) 
			handle_buy(id , CSW_FLASHBANG);
	} else {
		client_print(id , print_center , MSG_CANT_CARRY);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public he_buy(id){
	if(he[id]<CVAR_HE){
		++he[id];
		if(get_nade_num(CSW_HEGRENADE) > 1) 
			handle_buy(id , CSW_HEGRENADE);
	} else {
		client_print(id , print_center , MSG_CANT_CARRY);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public sg_buy(id){
	if(sg[id]<CVAR_SG){
		++sg[id];
		if(get_nade_num(CSW_SMOKEGRENADE) > 1) 
			handle_buy(id , CSW_SMOKEGRENADE);
	} else {
		client_print(id , print_center , MSG_CANT_CARRY);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

// Obsluga kupowania

public handle_buy(id , nade) 
{
	if(!is_user_alive(id) || get_user_team(id) > 2)
		return PLUGIN_CONTINUE;

	new ammo = cs_get_user_bpammo(id , nade);

	if(!ammo) /* If the player doesn't have a nade yet, let CS handle it */
		return PLUGIN_CONTINUE;

	if(!cs_get_user_buyzone(id)) /* Check if the player is in the buyzone */
		return PLUGIN_CONTINUE;

	new max_ammo , cost;

	switch(nade) 
	{
		case CSW_FLASHBANG:	max_ammo = get_nade_num(CSW_FLASHBANG)	  , cost = CSTRIKE_DEFAULT_FB_COST;
		case CSW_HEGRENADE:	max_ammo = get_nade_num(CSW_HEGRENADE)	  , cost = CSTRIKE_DEFAULT_HE_COST;
		case CSW_SMOKEGRENADE:	max_ammo = get_nade_num(CSW_SMOKEGRENADE) , cost = CSTRIKE_DEFAULT_SG_COST;
	}

	new Float:buytime = get_cvar_float("mp_buytime") * 60.0;
	new Float:timepassed = get_gametime() - g_GameTime;

	if(floatcmp(timepassed , buytime) == 1)
		return PLUGIN_HANDLED;

	if(cs_get_user_money(id) - cost <= 0) 
	{
		client_print(id , print_center , MSG_NO_FUNDS);
		return PLUGIN_HANDLED;
	}

	if(ammo == max_ammo) 
	{
		client_print(id , print_center , MSG_CANT_CARRY);
		return PLUGIN_HANDLED;
	}

	give_nade(id , nade);

	cs_set_user_money(id , cs_get_user_money(id) - cost , 1);

	return PLUGIN_CONTINUE;
}

// Obsluga dotyku

public touch_player(pToucher , pTouched) 
{
	if(!is_valid_ent(pToucher) || !is_user_alive(pTouched))
		return PLUGIN_CONTINUE;

	if(entity_get_int(pToucher , EV_INT_iuser1))
		return PLUGIN_HANDLED;

	new pToucherMdl[64];
	entity_get_string(pToucher , EV_SZ_model , pToucherMdl , 63);

	new model = check_nade_model(pToucherMdl); /* Check if the model is a grenade's */

	if(model != -1) /* If it's a grenade it'll return a value > -1 */
	{
		new ammo = cs_get_user_bpammo(pTouched , model) , max_ammo;

		switch(model) /* Get the max values for grenade ammo types */
		{
			case CSW_FLASHBANG:	max_ammo = get_nade_num(CSW_FLASHBANG);
			case CSW_HEGRENADE:	max_ammo = get_nade_num(CSW_HEGRENADE);
			case CSW_SMOKEGRENADE:	max_ammo = get_nade_num(CSW_SMOKEGRENADE);
		}

		if(max_ammo <= 0) /* If the max ammo cvar doesn't have a value > 0 then hault the code */
			return PLUGIN_CONTINUE;

		if(ammo <= 0) /* Let CS handle the first grenade */
		{ 
			set_entity_visibility(pToucher , 0);
			entity_set_int(pToucher , EV_INT_iuser1 , 1);

			return PLUGIN_CONTINUE;
		}

		if(ammo > 0 && ammo < max_ammo) /* Everything is OK so give the grenade! */
		{
			set_entity_visibility(pToucher , 0);
			entity_set_int(pToucher , EV_INT_iuser1 , 1);
			give_nade(pTouched , model);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

// Aktualizacja informacji

public fillGrenadesNumberOneInfo(id){
	if(!is_user_alive(id))return;
	he[id]=cs_get_user_bpammo(id,CSW_HEGRENADE);
	fb[id]=cs_get_user_bpammo(id,CSW_FLASHBANG);
	sg[id]=cs_get_user_bpammo(id,CSW_SMOKEGRENADE);
}

// Dodanie granatow

public give_nade(id, grenade){
	if(!is_user_alive(id))return;
	new ammo=cs_get_user_bpammo(id , grenade);
	cs_set_user_bpammo(id , grenade , ammo + 1);

	emit_sound(id, CHAN_WEAPON , NADE_PICKUP_SOUND , 1.0 , ATTN_NORM , 0 , PITCH_NORM);
}

// Rozroznianie typow granatow

public check_nade_model(model[]) 
{
	if(equal(model, "models/w_flashbang.mdl" )) 
		return CSW_FLASHBANG;
	if(equal(model, "models/w_hegrenade.mdl")) 
		return CSW_HEGRENADE;
	if(equal(model, "models/w_smokegrenade.mdl")) 
		return CSW_SMOKEGRENADE;

	return -1;
}

// Pobranie liczby posiadanych granatow

public get_nade_num(grenade) 
{
	switch(grenade) 
	{
		case CSW_FLASHBANG:	return CVAR_FB;
		case CSW_HEGRENADE:	return CVAR_HE;
		case CSW_SMOKEGRENADE:	return CVAR_SG;
	}

	return -1;
}

// Nowa runda

public new_round() 
{
	g_GameTime = get_gametime();
	new ent = -1;
	while((ent = find_ent_by_class(ent , "armoury_entity")) != 0) 
	{
		set_entity_visibility(ent , 1);
		entity_set_int(ent , EV_INT_iuser1 , 0);
	}
}

// Blokowanie komunikatu celem zastapienia wlasnym

public block_message() /* Blocks the "You cannot carry anymore" message" */
{
	if(get_msg_argtype(2) == ARG_STRING) 
	{
		new value[64];
		get_msg_arg_string(2 , value , 63);

		if(equali(value , "#Cannot_Carry_Anymore"))
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// Zatrzymanie pluginu dla innych modyfikacji, niz CS // Profilaktyka

public check_mod() /* Check if the mod is CS, if not, pause the entire plugin */
{
	new modname[21];
	get_modname(modname , 20);

	if(!equal(modname , "cstrike"))
		pause("ad");
}

/* Misc stuff
 #Name_change_at_respawn
 #Not_Enough_Money
 #Cstrike_Already_Own_Weapon
 #Auto_Team_Balance_Next_Round
 L 02/19/2006 - 04:56:04: [msglogging.amxx] MessageBegin TextMsg(77) Arguments=2 Destination=One(1) Origin={0.000000 0.000000 0.000000} Entity=1 Classname=player Netname=|-=R]A[D=->SyNthetic
 L 02/19/2006 - 04:56:04: [msglogging.amxx] Arg 1 (Byte): 4
 L 02/19/2006 - 04:56:04: [msglogging.amxx] Arg 2 (String): #Cannot_Carry_Anymore
 L 02/19/2006 - 04:56:04: [msglogging.amxx] MessageEnd TextMsg(77)
*/
