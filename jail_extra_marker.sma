#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>
#include <jailbreak>

#define PLUGIN "JailBreak: Marker"
#define VERSION "3.1"
#define AUTHOR "stupok69 & O'Zone"

#define MAX_PLAYERS 32

new Float:fPlayer[MAX_PLAYERS + 1][3], iCounter[MAX_PLAYERS + 1], bool:bDrawing[MAX_PLAYERS + 1], bool:bHolding[MAX_PLAYERS + 1], iSprite;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("+paint", "paint_handler", 0, "Paint on the walls!");
	register_clcmd("-paint", "paint_handler", 0, "Paint on the walls!");

	register_forward(FM_PlayerPreThink, "forward_FM_PlayerPreThink", 0);
}

public plugin_precache()
	iSprite = precache_model("sprites/lgtning.spr")

public paint_handler(id)
{
	if(jail_get_prowadzacy() == id || get_user_flags(id) & ADMIN_KICK)
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED;

		static szCmd[2];

		read_argv(0, szCmd, charsmax(szCmd));

		switch(szCmd[0])
		{
			case '+': bDrawing[id] = true;
			case '-': bDrawing[id] = false;
		}
	}

	return PLUGIN_HANDLED;
}

public forward_FM_PlayerPreThink(id)
{
	if(iCounter[id]++ > 5)
	{
		if(bDrawing[id] && !is_aiming_at_sky(id))
		{
			static Float:fOrigin[3], Float:fDistance;
			
			fOrigin = fPlayer[id];

			if(!bHolding[id])
			{
				fm_get_aim_origin(id, fPlayer[id]);

				move_toward_client(id, fPlayer[id]);

				bHolding[id] = true;

				return FMRES_IGNORED;
			}

			fm_get_aim_origin(id, fPlayer[id]);

			move_toward_client(id, fPlayer[id]);

			fDistance = get_distance_f(fPlayer[id], fOrigin);

			if(fDistance > 2) draw_line(fPlayer[id], fOrigin);
		}
		else bHolding[id] = false

		iCounter[id] = 0;
	}

	return FMRES_IGNORED;
}

stock draw_line(Float:fOriginOne[3], Float:fOriginTwo[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	
	write_byte(TE_BEAMPOINTS);

	engfunc(EngFunc_WriteCoord, fOriginOne[0]);
	engfunc(EngFunc_WriteCoord, fOriginOne[1]);
	engfunc(EngFunc_WriteCoord, fOriginOne[2]);
	engfunc(EngFunc_WriteCoord, fOriginTwo[0]);
	engfunc(EngFunc_WriteCoord, fOriginTwo[1]);
	engfunc(EngFunc_WriteCoord, fOriginTwo[2]);

	write_short(iSprite);

	write_byte(0);
	write_byte(10);
	write_byte(255);
	write_byte(50);
	write_byte(0);
	write_byte(random(255));
	write_byte(random(255));
	write_byte(random(255));
	write_byte(255);
	write_byte(0);

	message_end();
}

stock fm_get_aim_origin(id, Float:fOrigin[3])
{
	static Float:fStart[3], Float:fView[3], Float:fDesc[3];

	pev(id, pev_origin, fStart);
	pev(id, pev_view_ofs, fView);

	xs_vec_add(fStart, fView, fStart);

	pev(id, pev_v_angle, fDesc)

	engfunc(EngFunc_MakeVectors, fDesc)

	global_get(glb_v_forward, fDesc)

	xs_vec_mul_scalar(fDesc, 9999.0, fDesc)

	xs_vec_add(fStart, fDesc, fDesc)

	engfunc(EngFunc_TraceLine, fStart, fDesc, 0, id, 0);

	get_tr2(0, TR_vecEndPos, fOrigin);

	return 1;
}

stock move_toward_client(id, Float:fOrigin[3])
{		
	static Float:fPlayerOrigin[3];

	pev(id, pev_origin, fPlayerOrigin);

	fOrigin[0] += (fPlayerOrigin[0] > fOrigin[0]) ? 1.0 : -1.0;

	fOrigin[1] += (fPlayerOrigin[1] > fOrigin[1]) ? 1.0 : -1.0;

	fOrigin[2] += (fPlayerOrigin[2] > fOrigin[2]) ? 1.0 : -1.0;
}

stock bool:is_aiming_at_sky(id)
{
	static target, temp;

	get_user_aiming(id, target, temp);

	if(engfunc(EngFunc_PointContents, target) == CONTENTS_SKY) return true;

	return false;
}