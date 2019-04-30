/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Classic -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>

// Classic Human Attributes
new const humanclass1_name[] = "Anna"
new const humanclass1_info[] = "Female"
new const humanclass1_models[][] = { "csobc_girls" }
const humanclass1_health = 100
const Float:humanclass1_speed = 1.1
const Float:humanclass1_gravity = 1.0

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Natasha", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_HumanClassID = zp_class_human_register(humanclass1_name, humanclass1_info, humanclass1_health, humanclass1_speed, humanclass1_gravity)
	new index
	for (index = 0; index < sizeof humanclass1_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass1_models[index])
}
