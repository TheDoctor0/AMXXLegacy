#include <amxmodx>
#include <fakemeta>

new camera[MAX_PLAYERS + 1]
new const g_sCamclass[] = "PlayerCamera"

public plugin_init() {
	register_plugin("Kamera 3D", "1.0", "creepMP3")

	register_forward(FM_Think, "FM_Think_Hook")

	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0")

	register_clcmd("say /3d", "Camera")
	register_clcmd("say /camera", "Camera")
	register_clcmd("say camera", "Camera")
	register_clcmd("say /kamera", "Camera")
	register_clcmd("say kamera", "Camera")
}

public NowaRunda()
	for (new id = 1; id <= MAX_PLAYERS; id++) camera[id] = 0;

public Camera(id)
{
	if(!camera[id])
		Create_Camera(id)
	else {
		camera[id] = 0
	}
	return PLUGIN_HANDLED
}

public Create_Camera(id)
{
	new iEnt
	static const sClassname[] = "classname"
	while( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, sClassname, g_sCamclass))!= 0)
	{
		if(pev(iEnt, pev_owner) == id)
		{
			engfunc(EngFunc_SetView, id, iEnt)
			camera[id] = iEnt
			set_pev(iEnt, pev_nextthink, get_gametime())
			return
		}
	}
	static const sInfo_target[] = "info_target"
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, sInfo_target))
	if(!pev_valid(iEnt))
		return
	static const sCam_model[] = "models/w_usp.mdl"
	set_pev(iEnt, pev_classname, g_sCamclass)
	engfunc(EngFunc_SetModel, iEnt, sCam_model)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_movetype, MOVETYPE_FLYMISSILE)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_rendermode, kRenderTransTexture)
	set_pev(iEnt, pev_renderamt, 0.0)
	engfunc(EngFunc_SetView, id, iEnt)
	camera[id] = iEnt
	set_pev(iEnt, pev_nextthink, get_gametime())
}

public FM_Think_Hook(ent)
{
	if (pev_valid(ent) != 2) return FMRES_HANDLED

	static classname[32]
	pev(ent,pev_classname,classname,31)

	if(equal(classname,g_sCamclass))
	{
		new id = pev(ent,pev_owner)
		if(pev_valid(id) != 2 || !is_user_alive(id))
			return FMRES_IGNORED
		if(!camera[id])
		{
			engfunc( EngFunc_SetView, id, id )
			engfunc( EngFunc_RemoveEntity, ent )
			return FMRES_IGNORED
		}
		static Float:fOrigin[3], Float:fAngle[3],Float: Origin[3]
		pev(id,pev_origin,fOrigin )
		for(new i=0;i<3;i++)
			Origin[i] = fOrigin[i]
		pev(id,pev_v_angle,fAngle )

		static Float:fVBack[3]
		angle_vector(fAngle,ANGLEVECTOR_FORWARD,fVBack )

		fOrigin[2] += 20.0

		fOrigin[0] += ( -fVBack[0] * 150.0 )
		fOrigin[1] += ( -fVBack[1] * 150.0 )
		fOrigin[2] += ( -fVBack[2] * 150.0 )
		new trace
		engfunc(EngFunc_TraceLine,Origin,fOrigin,IGNORE_MONSTERS|IGNORE_GLASS|IGNORE_MISSILE,id,trace)
		get_tr2(trace, TR_vecEndPos, fOrigin)
		free_tr2(trace)
		engfunc( EngFunc_SetOrigin,ent,fOrigin)

		set_pev(ent,pev_angles,fAngle )
		set_pev(ent,pev_nextthink,get_gametime())
		pev(id,pev_velocity,fOrigin)
		set_pev(ent,pev_velocity,fOrigin)
	}

	return FMRES_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
