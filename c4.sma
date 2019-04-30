#include <amxmodx>
#include <csx>
#include <cstrike>
#include <engine>

#define PLUGIN "C4 Features"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_SOUND 74185

#define BombSound "sound/misc/bomba.wav" 

new g_c4timer, c4;

new cvar_sound;

new bool:g_bRoundEnd;

new g_szIcons[][] = { "bombticking", "bombticking1" };

new g_mShowTimer, g_mRoundTime, g_mScenario;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cvar_sound = register_cvar("bomb_sound", "0");

	c4 = get_cvar_pointer("mp_c4timer");

	register_event("HLTV", "eventRoundStart", "a", "1=0", "2=0");
	register_logevent("eventRoundEnd", 2, "1=Round_End");
	register_event("BombDrop", "eventBombPlanted", "a", "4=1");
	register_logevent("eventBombDefused", 3, "2=Defused_The_Bomb");

	g_mShowTimer = get_user_msgid("ShowTimer");
	g_mRoundTime = get_user_msgid("RoundTime");
	g_mScenario = get_user_msgid("Scenario");
}

public plugin_precache()
	precache_sound("misc/bomba.wav");

public bomb_defusing(id)
	entity_set_float(id, EV_FL_maxspeed, 240.0);
	
public bomb_planting(id)
	entity_set_float(id, EV_FL_maxspeed, 240.0);

public eventRoundStart()
	g_bRoundEnd = false;

public eventRoundEnd()
{
	g_bRoundEnd = true;

	remove_task(TASK_SOUND);
}

public eventBombPlanted()
{
	g_c4timer = get_pcvar_num(c4);

	if(g_c4timer)
	{
		if(!g_bRoundEnd)
		{
			set_task(1.0, "ShowTimer");

			if(get_pcvar_num(cvar_sound)) set_task(float(g_c4timer - 10), "bombSound", TASK_SOUND);
		}
	}
	else log_error(AMX_ERR_NATIVE, "Cvar mp_c4timer is not set!");
}

public eventBombDefused()
{
	if(get_pcvar_num(cvar_sound))
	{
		remove_task(TASK_SOUND);
		client_cmd(0, "stopsound");
		client_cmd(0, "spk sound/radio/bombdef");
		set_task(1.2, "roundWin");
	}
}
	
public roundWin()
	client_cmd(0, "spk sound/radio/ctwin");

public bombSound()
	client_cmd(0, "spk %s", BombSound);

public ShowTimer()
{
	message_begin(MSG_BROADCAST, g_mShowTimer);
	message_end();

	message_begin(MSG_BROADCAST, g_mRoundTime);
	write_short(g_c4timer);
	message_end();
	
	static icon; icon = !icon;

	message_begin(MSG_BROADCAST, g_mScenario);
	write_byte(1);
	write_string(g_szIcons[icon]);
	write_byte(150);
	write_short(20);
	message_end();
}