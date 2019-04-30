#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <zp50_core>
#include <zp50_items>
#include <zp50_ammopacks>
#include <zp50_colorchat>

new const class_name[] = "box_system"

new model[] = "models/box_system/box_item.mdl"
new sound[] =  "box_system/get_item.wav"

new sprite_1, sprite_2, box_chance

public plugin_init() 
{
	register_plugin("[ZP] Box System", "1.2", "O'Zone")
	register_event("DeathMsg", "DeathMsg", "a")
	register_touch(class_name, "player", "Touch")
	box_chance = register_cvar("zp_drop_box_chance", "13");
}

public plugin_precache()
{
	precache_model(model)
	precache_sound(sound)
	sprite_1 = precache_model("sprites/box_system/green.spr") 
	sprite_2 = precache_model("sprites/box_system/acid_pou.spr")
}

public DeathMsg()
{
	new victim = read_data(2)
	
	if(!zp_core_is_zombie(victim))
		return PLUGIN_CONTINUE
		
	if(random_num(1, get_pcvar_num(box_chance)) == 1)
		CreateBox(victim)
	
	return PLUGIN_CONTINUE
}

public CreateBox(id)
{
	new Float:origin[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	
	new ent = fm_create_entity("info_target")
	set_pev(ent, pev_classname, class_name)
	
	engfunc(EngFunc_SetModel, ent, model)
	
	set_pev(ent,pev_mins, Float:{-10.0,-10.0,0.0})
	set_pev(ent,pev_maxs, Float:{10.0,10.0,50.0})
	set_pev(ent,pev_size, Float:{-1.0,-3.0,0.0,1.0,1.0,10.0})
	engfunc(EngFunc_SetSize, ent, Float:{-1.0,-3.0,0.0}, Float:{1.0,1.0,10.0})
	
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	entity_set_origin(ent, origin)
	entity_set_int(ent, EV_INT_sequence, 1)
	entity_set_float(ent, EV_FL_animtime, 360.0)
	entity_set_float(ent, EV_FL_framerate,  1.0)
	entity_set_float(ent, EV_FL_frame, 0.0)
	
	return PLUGIN_HANDLED
}

public Touch(entity, id)
{
	if(!is_user_alive(id)) 
		return PLUGIN_CONTINUE

	zp_core_is_zombie(id) ? PresentZombie(id) : PresentHuman(id)
	
	Effects(id)
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	remove_entity(entity)
	return PLUGIN_CONTINUE	
}

public PresentZombie(id) 
{
	new Present = random_num(1, 6)
	switch(Present)
	{
		case 1: 
		{
			zp_items_force_buy(id, zp_items_get_id("Infection Bomb"), 1)
			zp_colored_print(id, "Dostales^x04 Infection Bomb^x01!")
			return PLUGIN_CONTINUE
		}
		case 2: 
		{
			zp_items_force_buy(id, zp_items_get_id("Antidote"), 1)
			zp_colored_print(id, "Dostales^x04 Antidote^x01!")
			return PLUGIN_CONTINUE
		}
		case 3: 
		{
			set_user_health(id, get_user_health(id) - 1000)
			zp_colored_print(id, "Pech.. dostales^x04 -1000hp^x01!")
			return PLUGIN_CONTINUE
		}
		case 4: 
		{
			set_user_health(id, get_user_health(id) + 1000)
			zp_colored_print(id, "Dostales^x04 +1000hp^x01!")
			return PLUGIN_CONTINUE
		}
		case 5: 
		{
			zp_ammopacks_set(id, zp_ammopacks_get(id) + 10)
			zp_colored_print(id, "Dostales^x04 +10 AP^x01!")
			return PLUGIN_CONTINUE
		}
		case 6: {
			zp_ammopacks_set(id, zp_ammopacks_get(id) - 10)
			zp_colored_print(id, "Pech.. dostales^x04 -10 AP^x01!")
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public PresentHuman(id) 
{
	new Present = random_num(1, 7)
	switch(Present)
	{
		case 1: 
		{
			zp_items_force_buy(id, zp_items_get_id("M-134 Ex"), 1)
			zp_colored_print(id, "Dostales^x04 M-134 Ex^x01!")
			return PLUGIN_CONTINUE
		}
		case 2: 
		{
			zp_items_force_buy(id, zp_items_get_id("Laser Mine"), 1)
			zp_colored_print(id, "Dostales^x04 Laser Mine^x01!")
			return PLUGIN_CONTINUE	
		}
		case 3: 
		{
			zp_items_force_buy(id, zp_items_get_id("Thunderbolt"), 1)
			zp_colored_print(id, "Dostales^x04 Thunderbolt^x01!")
			return PLUGIN_CONTINUE
		}
		case 4: 
		{
			zp_ammopacks_set(id, zp_ammopacks_get(id) + 10)
			zp_colored_print(id, "Dostales^x04 +10 AP^x01!")
			return PLUGIN_CONTINUE
		}
		case 5: 
		{
			zp_ammopacks_set(id, zp_ammopacks_get(id) - 10)
			zp_colored_print(id, "Pech.. dostales^x04 -10 AP^x01!")
			return PLUGIN_CONTINUE
		}
		case 6: 
		{
			set_user_health(id, get_user_health(id) - 50)
			zp_colored_print(id, "Pech.. dostales^x04 -50hp^x01!")
			return PLUGIN_CONTINUE
		}
		case 7: 
		{
			set_user_health(id, get_user_health(id) + 50)
			zp_colored_print(id, "Dostales^x04 +50hp^x01!")
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public Effects(id) 
{
	new origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short(sprite_1)
	write_byte(20)
	write_byte(255)
	message_end()
	
	message_begin(MSG_ALL, SVC_TEMPENTITY, {0, 0, 0}, id)
	write_byte(TE_SPRITETRAIL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 20)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 80)
	write_short(sprite_2)
	write_byte(20)
	write_byte(20)
	write_byte(4)
	write_byte(20)
	write_byte(10)
	message_end()
}