#include <amxmodx>
#include <fakemeta>

new plnades[33][3]

public plugin_init() {
	register_plugin("Nades limit", "0.1", "Pavulon")
	
	register_event("HLTV", "resetnades", "a", "1=0", "2=0")
	register_event("CurWeapon","wpntest","be", "1=1")
	
	register_cvar("max_he","1")
	register_cvar("max_sg","1")
	register_cvar("max_fb","2")
	
	register_forward(FM_SetModel, "forward_setmodel")
}

public client_connect(id)
{
	plnades[id][0]=0
	plnades[id][1]=0
	plnades[id][2]=0
}

public forward_setmodel(const ENTITY, model[])
{
	if(!pev_valid(ENTITY))
		return FMRES_IGNORED
		
	new owner = pev(ENTITY, pev_owner)

	if (equal(model, "models/w_hegrenade.mdl"))
		plnades[owner][0]++
	else if (equal(model, "models/w_smokegrenade.mdl"))
		plnades[owner][1]++
	else if (equal(model, "models/w_flashbang.mdl"))
		plnades[owner][2]++
   
	return FMRES_IGNORED 
}

public resetnades()
{
	new players[32], playerCount, i, player
	
	get_players(players, playerCount)
	for (i=0; i<playerCount; i++)
	{
		player = players[i]
		plnades[player][0]=0
		plnades[player][1]=0
		plnades[player][2]=0
	} 
}

public wpntest(id)
{
	new wpn = read_data(2)
	new nade[11], len = 0
	switch(wpn)
	{
		case CSW_HEGRENADE:
		{
			if (plnades[id][0] >= get_cvar_num("max_he"))
			{
				client_cmd(id, "weapon_knife")
				len = format(nade, 10, "Hegranade")
			}
		}
		case CSW_SMOKEGRENADE:
		{
			if (plnades[id][1] >= get_cvar_num("max_sg"))
			{
				client_cmd(id, "weapon_knife")
				len = format(nade, 10, "Smokegrenade")
			}
		}
		case CSW_FLASHBANG:
		{
			if (plnades[id][2] >= get_cvar_num("max_fb"))
			{
				client_cmd(id, "weapon_knife")
				len = format(nade, 10, "Flashbang")
			}
		}
	}
	if (len > 0)
	{
		new message[128]
		format(message, 127, "^x04[Granaty]^x01 Osiagnales limit dla granatu^x04 %s ^x01w tej rundzie.", nade)
		colored_msg(id, message)
	}

	return PLUGIN_CONTINUE
}

public colored_msg(id,msg[]) { 
	message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
