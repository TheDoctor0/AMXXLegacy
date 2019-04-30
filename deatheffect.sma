#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <dhudmessage>

new knife_kill, grenade_kill, headshot, normal_kill

new level[32]
new bool:kills[32]

new one_kill
new two_kill
new three_kill
new four_kill
new five_kill
new six_kill
new seven_kill
new eight_kill
new more_than_eight_kill
new g_lastkill
new g_firstblood

public plugin_precache()
{
        headshot = precache_model("sprites/headshot.spr")
        knife_kill = precache_model("sprites/knife_kill.spr")
        grenade_kill = precache_model("sprites/grenade_kill.spr")
        one_kill = precache_model("sprites/1_kill.spr")
        two_kill = precache_model("sprites/2_kill.spr")
        three_kill = precache_model("sprites/3_kill.spr")
        four_kill = precache_model("sprites/4_kill.spr")
        five_kill = precache_model("sprites/5_kill.spr")
        six_kill = precache_model("sprites/6_kill.spr")
        seven_kill = precache_model("sprites/7_kill.spr")
        eight_kill = precache_model("sprites/8_kill.spr")
        more_than_eight_kill = precache_model("sprites/more_than_8_kill.spr")
        normal_kill = precache_model("sprites/normal_kill.spr")
	precache_sound("misc/headshot.wav")
        precache_sound("misc/knife_kill.wav")
        precache_sound("misc/grenade_kill.wav")
        precache_sound("misc/wallshot.wav")
        precache_sound("misc/1_kill.wav")
        precache_sound("misc/2_kill.wav")
        precache_sound("misc/3_kill.wav")
        precache_sound("misc/4_kill.wav")
        precache_sound("misc/5_kill.wav")
        precache_sound("misc/6_kill.wav")
        precache_sound("misc/7_kill.wav")
        precache_sound("misc/8_kill.wav")
        precache_sound("misc/firstblood.wav")
        precache_sound("misc/last_kill.wav")
        precache_sound("misc/unstoppable.wav")
}

public plugin_init()
{
	register_plugin("Death Sprite Effect","1.5","RaZzoR")
        register_event("DeathMsg","onDeath","a")
        register_event("DeathMsg","onDeath_level","a")
        register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w")
	register_event("SendAudio", "eEndRound", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	register_event("RoundTime", "eNewRound", "bc")
	register_clcmd("say /test", "Showme");
}


public eRestart()
{
	eEndRound()
	g_firstblood = 1
}

public eEndRound()
{

}

public client_disconnect(id)
{
	level[id]= 0
}
public client_putinserver(id)
{
	level[id]= 0
}

public onDeath()
{
        new name_attacker[32]
	new name_victim[32]
        new wpn[3]
        new hs = read_data(3)
        new attacker = read_data(1)
        new victim = read_data(2)

        get_user_name(attacker, name_attacker, 31)
	get_user_name(victim, name_victim, 31)
        read_data(4,wpn,2)
    
        if (wpn[0] != 'k' && wpn[1] != 'r' && !can_see_fm(attacker, victim)) 
	{
		if (hs)
                {
                  set_dhudmessage(255, 0, 0, -1.0, 0.20, 0, 6.0, 3.0, 0.1, 1.5) 
	          show_dhudmessage(attacker, "FALON AT FEJLOVES!^n-|IGEN! :D|-")
                  client_cmd(attacker,"spk misc/headshot")
                }
	}
        else if (hs && wpn[0] != 'k' && wpn[1] != 'r')
	{
		show_sprite(victim, headshot)
                client_cmd(attacker,"spk misc/headshot")   
	}
        else if (wpn[0] == 'k')
        {
	        show_sprite(victim, knife_kill)
                client_cmd(attacker,"spk misc/knife_kill")
        }
        else if (wpn[1] == 'r')
        {
	        show_sprite(victim, grenade_kill)
                client_cmd(attacker,"spk misc/grenade_kill")
        }

        return PLUGIN_CONTINUE
}

public onDeath_level()
{
        new players_ct[32], players_t[32], ict, ite
	get_players(players_ct,ict,"ae","CT")   
	get_players(players_t,ite,"ae","TERRORIST")
	if (ict == 0 || ite == 0) g_lastkill = 1
        
        new attacker = read_data(1)
        new victim = read_data(2)
        new name_attacker[32]
	new name_victim[32]

        level[attacker] += 1
	level[victim]= 0

        get_user_name(attacker, name_attacker, 31)
	get_user_name(victim, name_victim, 31)

        if((victim == attacker) || (get_user_team(attacker) == get_user_team(victim)) || !victim || !attacker)
			return PLUGIN_CONTINUE
       


        if (g_firstblood && attacker!=victim && attacker>0) 
	{	
                 g_firstblood = 0			
		 set_dhudmessage(255, 105, 180, -1.0, 0.35, 0, 6.0, 3.0, 0.1, 1.5) 
		 show_dhudmessage(0, "ELSO OLES: ^n %s megolte %s-t!", name_attacker, name_victim)
		 client_cmd(0, "speak misc/firstblood")
	}
        if (g_lastkill == 1)
	{
		g_lastkill = 0
                set_dhudmessage(255, 215, 0, -1.0, 0.30, 0, 6.0, 3.0, 0.1, 1.5) 
		show_dhudmessage(0, "UTOLSO OLES: ^n %s megolte %s-t!", name_attacker, name_victim)
		client_cmd(0, "speak misc/last_kill")
	}  
        if (level[attacker] == 1)
        {
	        show_sprite(victim, one_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/1_kill")	
		
	}
        if (level[attacker] == 2)
        {
	        show_sprite(victim, two_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/2_kill")		
		
	}
        if (level[attacker] == 3)
        {
	        show_sprite(victim, three_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/3_kill")		
		
	}
        if (level[attacker] == 4)
        {
	        show_sprite(victim, four_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/4_kill")		
		
	}
        if (level[attacker] == 5)
        {
	        show_sprite(victim, five_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/5_kill")	 	
		
	}
        if (level[attacker] == 6)
        {
	        show_sprite(victim, six_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/6_kill")	 	
		
	}
        if (level[attacker] == 7)
        {
	        show_sprite(victim, seven_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/7_kill")	 	
		
	}
        if (level[attacker] == 8)
        {
	        show_sprite(victim, eight_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/8_kill")		
		
	}
        if (level[attacker] > 8)
        {
	        show_sprite(victim, more_than_eight_kill)
                kills[victim] = true
                client_cmd(attacker,"spk misc/unstoppable")		
		
	}
         
        return PLUGIN_CONTINUE
}

public Showme(id)
	show_sprite(id, more_than_eight_kill)

public show_sprite(attacker, sprite)
{	
        if(!is_user_connected(attacker))
		return PLUGIN_CONTINUE



	static origin[3]
	get_user_origin(attacker, origin)
	
        message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+65)
	write_short(sprite)
	write_byte(10)
	write_byte(250)
	message_end()
        
        return PLUGIN_CONTINUE
}

public podesi_boolove(id)
{	
	kills[id] = false
}

bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}