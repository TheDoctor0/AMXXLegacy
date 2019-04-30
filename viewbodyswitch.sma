#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include "viewbodyswitch.inc"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for (new i; i < sizeof WeaponNames; i++)
	{
		RegisterHam(Ham_Item_Deploy, WeaponNames[i], "HamF_Item_Deploy_Post", TRUE);
		RegisterHam(Ham_Weapon_PrimaryAttack, WeaponNames[i], "HamF_Weapon_PrimaryAttack");
		RegisterHam(Ham_CS_Weapon_SendWeaponAnim, WeaponNames[i], "HamF_CS_Weapon_SendWeaponAnim_Post", TRUE);
	}
	
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HamF_Weapon_SecondaryAttack");	//Hooking a bit delay between knife attacks while stabbing
	
	for (new i; i < sizeof TraceBullets; i++)
	{		
		RegisterHam(Ham_TraceAttack, TraceBullets[i], "HamF_TraceAttack_Post", TRUE);
	}
	
	register_forward(FM_PlaybackEvent, "Forward_PlaybackEvent");
	register_forward(FM_ClientUserInfoChanged, "Forward_ClientUserInfoChanged");

#if defined DEBUG	
	
	register_clcmd("switch_sex", "switch_sex");	//test cmd, type to switch sex, type again to switch back.

#endif	
	
	register_event("StatusValue", "iSpectatorViewBody", "bd", "1=2");	//That should fix the player, who killed us first.
	register_event("SpecHealth2", "iSpectatorViewBody", "bd");	//Hooking with both events...
}

public plugin_precache()
{
	register_forward(FM_PrecacheModel, "Forward_PrecacheModel");	//Unprecache old viewmodels

	for (new i; i < sizeof g_NewModels; i++)
	{
		engfunc(EngFunc_PrecacheModel, g_NewModels[i]);	//Precache now new
	}
	
	engfunc(EngFunc_PrecacheModel, FEMALE_KNIFE);
}

public Forward_PrecacheModel(const iModels[])
{
	for (new i; i < sizeof g_OldModels; i++) 
	{ 
		if(!strcmp(iModels, g_OldModels[i]))  
		{  
			forward_return(FMV_CELL, 0);
			
			return FMRES_SUPERCEDE;  
		}  
	}
	
	return FMRES_IGNORED;  	
}	

public HamF_Item_Deploy_Post(iEnt)
{
	static id, iWeaponName[24];
	
	id = get_pdata_cbase(iEnt, m_pPlayer, 4);

#if defined DEBUG
	
	switch(GetUserSex(id))	//DEBUG ONLY!!! Set character Sex in your own plugin 
	{
		case FEMALE: SetViewEntityBody(id, FEMALE);
		default: SetViewEntityBody(id, MALE);	
	}
	
#endif	
	
	WEAPON_STRING(iEnt, iWeaponName);

	for (new i; i < sizeof WeaponNames; i++)
	{
		if (!strcmp(iWeaponName, WeaponNames[i]) && strcmp(iWeaponName, "weapon_knife"))	//No check against knife, because going to set it by sex
		{
			set_pev(id, pev_viewmodel2, g_NewModels[i]);	//Old was unprecached
		}
	}
	
	if(!strcmp(iWeaponName, "weapon_knife"))
	{
		switch(GetUserSex(id))
		{
			case FEMALE: set_pev(id, pev_viewmodel2, FEMALE_KNIFE);
			default: set_pev(id, pev_viewmodel2, MALE_KNIFE);
		}
	}
	
	return HAM_IGNORED;	
}

public HamF_Weapon_PrimaryAttack(iEnt)
{
	switch(WEAPON_ENT(iEnt))
	{
		case CSW_C4, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: return HAM_IGNORED;	//No need to hook or supercede
		default: FireWeaponEffect(iEnt);
	}
	
	return HAM_SUPERCEDE;
}

public HamF_Weapon_SecondaryAttack(iEnt)
{
	static id;
	
	id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	
	ExecuteHam(Ham_Weapon_SecondaryAttack, iEnt);
	
	set_pdata_float(id, m_flNextAttack, 1.5, 5);	//A bit increase	
	set_pdata_float(iEnt, m_flTimeWeaponIdle, 2.5, 4);
	
	UTIL_SendWeaponAnim(id, KNIFE_STABMISS);
	
	return HAM_SUPERCEDE;	
}

public HamF_CS_Weapon_SendWeaponAnim_Post(iEnt, iAnim, Skiplocal)
{
	Skiplocal = FALSE;
	
	static id;
 
	id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	
	UTIL_SendWeaponAnim(id, iAnim);
	
#if defined DEBUG

	static iWeaponName[24];

	WEAPON_STRING(iEnt, iWeaponName);

	client_print(id, print_chat, "Animation Num: %d, Skiplocal Value: %d, Current Weapon: %s", iAnim, Skiplocal, iWeaponName);	//May overflow old client 4xxx
	
#endif

	UTIL_SendSpectatorAnim(id, iAnim);	//No checkout against non pev_iuser2, need to simplify later			
	
	return HAM_IGNORED;
}

public HamF_TraceAttack_Post(iEnt, iAttacker, Float:damage, Float:fDir[3], ptr, iDamageType)
{
	static iWeapon, Float:vecEnd[3];
	
	iWeapon = get_pdata_cbase(iAttacker, m_pActiveItem);

	switch(WEAPON_ENT(iWeapon))
	{
		case CSW_KNIFE: return HAM_IGNORED;	//No decals while stabbing or swinging with knife
		default:
		{
			get_tr2(ptr, TR_vecEndPos, vecEnd);	
	
			// Decal effects, add here spark, any
			engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0);
			write_byte(TE_GUNSHOTDECAL);
			engfunc(EngFunc_WriteCoord, vecEnd[0]);
			engfunc(EngFunc_WriteCoord, vecEnd[1]);
			engfunc(EngFunc_WriteCoord, vecEnd[2]);
			write_short(iEnt);
			write_byte(random_num(41, 45));
			message_end();			
		}
	}
	
	return HAM_IGNORED;	
}

public Forward_PlaybackEvent(iFlags, id, iEvent, Float:fDelay, Float:vecOrigin[3], Float:vecAngle[3], Float:flParam1, Float:flParam2, iParam1, iParam2, bParam1, bParam2)
{
	if(is_user_alive(id))
	{	
		return FMRES_SUPERCEDE;
	}
	
	//What this does? Fire anim fix for spectator.
	for(new iFirstPerson = 1; iFirstPerson < 33; iFirstPerson++)
	{			
		if(is_user_connected(iFirstPerson) && !is_user_alive(iFirstPerson) && !is_user_bot(iFirstPerson))
		{				
			if(pev(iFirstPerson, pev_iuser2) == id)
			{
				return FMRES_SUPERCEDE;
			}
		}
	}	
	
	return FMRES_IGNORED;	//Let other things to be pass	
}

public Forward_ClientUserInfoChanged(id)
{
	static iUserInfo[6] = "cl_lw", iClientValue[2], iServerValue[2] = "0";	//Preventing them from enabling client weapons
	
	if(CLIENT_DATA(id, iUserInfo, iClientValue))
	{
		HOOK_DATA(id, iUserInfo, iServerValue);

#if defined DEBUG
		
		client_print(id, print_chat, "User Local Weapons Value: %s, Server Local Weapons Value: %s", iClientValue, iServerValue);	//Receive get and set

#endif		
				
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public iSpectatorViewBody(pPlayer)
{
	if(!(1 <= pPlayer <= 32))
	{	
		return PLUGIN_HANDLED;
	}
	
	iSpectatorTarget[pPlayer] = read_data(2);
	
	if(!iSpectatorTarget[pPlayer])
	{
		return PLUGIN_HANDLED;
	}
	
	SetViewEntityBody(pPlayer, iBodyIndex[iSpectatorTarget[pPlayer]]);	//Because we are setting this actually for ourselves
	
	UTIL_SendWeaponAnim(pPlayer, IDLE_ANIM);	//Why? Because it will not switch to another submodel without delay bug. (Why 0, because 0 is idle anim, same as client)
		
#if defined DEBUG

	client_print(pPlayer, print_chat, "Target Sex: %d, Hands Bodygroup: %d", iSex[iSpectatorTarget[pPlayer]], iBodyIndex[iSpectatorTarget[pPlayer]]);
	
#endif

	return PLUGIN_CONTINUE;
}

#if defined DEBUG

//test functions only
public client_connect(id)
{
	//testing, was good. Comment nearby both if you want to uncomment and test this randomize
	switch(random_num(1,10))
	{
		case 1..5:
		{
			SetUserSex(id, MALE);	//Making it male, to make our nearby func work
			SetViewEntityBody(id, MALE);	//Set Viewbody			
		}
		case 6..10:
		{
			SetUserSex(id, FEMALE);	//Making this female
			SetViewEntityBody(id, FEMALE);	//Set Viewbody			
		}		
	}
	
	/*SetUserSex(id, MALE);	//Making it male, to make our nearby func work
	SetViewEntityBody(id, MALE);	//Reset Viewbody*/
	
}	

public switch_sex(id)
{		
	switch(GetUserSex(id))
	{
		//switching to female
		case MALE:
		{
			SetViewEntityBody(id, 1);
			SetUserSex(id, FEMALE);				
		}
		//to male
		case FEMALE:
		{
			SetViewEntityBody(id, 0);
			SetUserSex(id, MALE);					
		}
	}
	
	if(!is_user_alive(id))
	{
		return;
	}	
	
	static iWeapon;
	
	iWeapon = get_pdata_cbase(id, m_pActiveItem);
	
	if(iWeapon)
	{
		ExecuteHamB(Ham_Item_Deploy, iWeapon);	//Will give and error while dead
	}
}

#endif

//Natives
public plugin_natives()
{
	register_native("SetViewEntityBody", "ViewBodySwitch", TRUE);
	register_native("SetUserSex", "SetSex", TRUE);
	register_native("GetUserSex", "GetSex", TRUE);
}

public ViewBodySwitch(pPlayer, iValue)
{
	iBodyIndex[pPlayer] = iValue;
}

public SetSex(pPlayer, iValue)
{
	iSex[pPlayer] = iValue;
}

public GetSex(pPlayer)
{
	return iSex[pPlayer];
}