#include <amxmodx>
#include <fakemeta>

public plugin_init() 
	register_forward(FM_EmitSound, "block_sound");

public block_sound(entity, channel, const sound[]) 
{
	log_to_file("sounds.log", "Ent: %i | Channel: %i | Sound: %s", entity, channel, sound);

	return FMRES_IGNORED;
}