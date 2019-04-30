#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

new const Float:fMultipler = 0.5;

new const w_szModels[][] =
{
	"models/w_hegrenade.mdl",
	"models/w_flashbang.mdl",
	"models/w_smokegrenade.mdl"
}

new const v_szModels[][] =
{
	"models/v_hegrenade_cs_go.mdl",
	"models/v_flashbang_cs_go.mdl",
	"models/v_smokegrenade_cs_go.mdl"
}

new bool:gbShortThrow[33];

new cvBlow;

public plugin_init()
{
	register_plugin("CS:GO Nades", "1.0", "O'Zone")
	
	cvBlow = register_cvar("amx_shortnade_blow", "1.0");
	
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "ModelChangeHE", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_flashbang", "ModelChangeFlash", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "ModelChangeSmoke", 1);
	
	register_forward(FM_SetModel, "fwSetmodel");
	register_forward(FM_CmdStart, "fwCmdStart");
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_szModels[0]);
	engfunc(EngFunc_PrecacheModel, v_szModels[1]);
	engfunc(EngFunc_PrecacheModel, v_szModels[2]);
}

public ModelChangeHE(weapon)
{
	static id;
	id = pev(weapon , pev_owner);
	set_pev(id, pev_viewmodel2, v_szModels[0]);
}

public ModelChangeFlash(weapon)
{
	static id;
	id = pev(weapon , pev_owner);
	set_pev(id, pev_viewmodel2, v_szModels[1]);
}

public ModelChangeSmoke(weapon)
{
	static id;
	id = pev(weapon , pev_owner);
	set_pev(id, pev_viewmodel2, v_szModels[2]);
}

public fwSetmodel(iEntity, sModel[])
{
	for(new i = 0; i < sizeof w_szModels; ++i)
	{
		if(equal(sModel, w_szModels[i]))
		{
			new id = pev(iEntity, pev_owner);
			
			if(!is_user_connected(id))
				return FMRES_IGNORED;
			
			if(gbShortThrow[id])
			{
				DecreaseSpeed(iEntity);
				gbShortThrow[id] = false;
				return FMRES_IGNORED;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public DecreaseSpeed(iEntity)
{
	static Float:fVec[3];
	pev(iEntity, pev_velocity, fVec);
	
	fVec[0] *= fMultipler;
	fVec[1] *= fMultipler;
	fVec[2] *= fMultipler;
	
	set_pev(iEntity, pev_velocity, fVec);
	
	pev(iEntity, pev_origin, fVec);
	
	fVec[2] -= 24.0;
	
	set_pev(iEntity, pev_origin, fVec);
	
	new Float:fBlowTime = get_pcvar_float(cvBlow);
	if(fBlowTime > 1.0 || fBlowTime < 0.1)
	{
		set_pcvar_float(cvBlow, 1.0);
		fBlowTime = 1.0;
	}
	
	static Float:fDmgTime;
	pev(iEntity, pev_dmgtime, fDmgTime);
	fDmgTime -= get_gametime();
	
	set_pev(iEntity, pev_dmgtime, get_gametime() + (fDmgTime * fBlowTime));
}

public fwCmdStart(id, ucHandle, seed)
{	
	static clip, ammo;
	new weapon = get_user_weapon(id, clip, ammo);
	
	if( weapon != CSW_HEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_SMOKEGRENADE)
		return FMRES_IGNORED;
	
	new button = get_uc(ucHandle, UC_Buttons);
	
	if(gbShortThrow[id] && button & IN_ATTACK)
		gbShortThrow[id] = false;
	
	if(button & IN_ATTACK2)
	{
		button &= ~IN_ATTACK2;
		button |= IN_ATTACK;
		
		gbShortThrow[id] = true;
		
		set_uc(ucHandle, UC_Buttons, button);
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}