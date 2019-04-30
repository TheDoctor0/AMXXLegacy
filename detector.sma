#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

new kills[33], hs_kills[33], damage[33], hs_streak[33], bool:scanned[33];

public plugin_init()
{
	register_plugin("Simple Cheat Detector","1.0","O'Zone");
	
	register_logevent("Wall_Kills", 2, "1=Round_End");
	
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
}

public client_connect(id)
{
	kills[id] = 0;
	hs_kills[id] = 0;
	damage[id] = 0;
	scanned[id] = false;
}

public Wall_Kills()
{
	for(new id = 1; id <= get_playersnum(); id++){
		if(kills[id] >= 2){
			new name[33];
			get_user_name(id, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					client_print_color(player, id, "^x04[DETECTOR]^x01 Gracz^x03 %s^x01 w tej rundzie skanujac zabil^x04 %i^x01 (w tym^x04 %i^x01 z HS)!", name, kills[id], hs_kills[id]);
					continue;
				}
			}
		}
		else if(damage[id] >= 200){
			new name[33];
			get_user_name(id, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					client_print_color(player, id, "^x04[DETECTOR]^x01 Gracz^x03 %s^x01 w tej rundzie skanujac zadal^x04 %i^x01 obrazen!", name, damage[id]);
					continue;
				}
			}
		}

		kills[id] = 0;
		hs_kills[id] = 0;
		damage[id] = 0;
		scanned[id] = false;
	}
}

public TraceAttack(iVictim, iAttacker, Float:flDamage, Float:vDirection[3], ptr, Bits)
{
	if(!is_user_alive(iAttacker) || get_user_weapon(iAttacker) == CSW_KNIFE || get_user_flags(iAttacker) & ADMIN_BAN)
		return HAM_IGNORED;
		
	static Float:vStart[3], Float:vEnd[3], Float:flFraction;
		
	get_tr2(ptr, TR_vecEndPos, vEnd);
	get_tr2(ptr, TR_flFraction, flFraction);
		
	xs_vec_mul_scalar(vDirection, -1.0, vDirection);
	xs_vec_mul_scalar(vDirection, flFraction * 9999.0, vStart);
	xs_vec_add(vStart, vEnd, vStart);
		
	new iTarget = trace_line(iVictim, vEnd, vStart, vEnd);
		
	if(!iTarget){
		scanned[iVictim] = true;
		damage[iAttacker] += floatround(flDamage);
	}
	else
		scanned[iVictim] = false;

	return HAM_IGNORED;
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if(killer == victim  || get_user_flags(killer) & ADMIN_BAN)
		return;
		
	if(scanned[victim])
	{
		kills[killer]++;
		if(hitplace == HIT_HEAD)
			hs_kills[killer]++;
	}
		
	if(hitplace == HIT_HEAD)
	{
		hs_streak[killer]++;
		if(hs_streak[killer] >= 5 && hs_streak[killer]%2 != 0)
		{
			new name[33];
			get_user_name(killer, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					client_print_color(player, killer, "^x04[DETECTOR]^x01 Gracz^x03 %s^x01 zabil z HS^x04 %i^x01 z rzedu!", name, hs_streak[killer]);
					continue;
				}
			}
		}
	}
	else
		hs_streak[killer] = 0;
}