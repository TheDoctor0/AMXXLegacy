#include <amxmisc>
#include <fakemeta>
#include <vault>

#define PLUGIN "Lightsaber"
#define VERSION "1.0.1"
#define AUTHOR "R3X"

#define KeysSabre (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<9) // Keys: 12340

#define KNIFE_RANGE_BONUS 50
new bool:noz[33]=false;
//Sounds
new const gszOldSounds[][]={
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	"weapons/knife_stab.wav",
	"weapons/knife_hitwall1.wav",
	"weapons/knife_slash1.wav",
	"weapons/knife_slash2.wav",
	"weapons/knife_deploy1.wav"
};
new const gszNewSounds[sizeof gszOldSounds][]={
	"weapons/ls_hitbod1.wav",
	"weapons/ls_hitbod2.wav",
	"weapons/ls_hitbod3.wav",
	"weapons/ls_hitbod3.wav",
	"weapons/ls_hit2.wav",
	"weapons/ls_hit1.wav",
	"weapons/ls_miss.wav",
	"weapons/ls_miss.wav",
	"weapons/ls_pullout.wav"
};
//Models - by xVox-Bloodstonex http://www.fpsbanana.com/skins/34512
new const gszRedModelP[]="models/p_r_lightsabre.mdl";
new const gszGreenModelP[]="models/p_g_lightsabre.mdl";
new const gszBlueModelP[]="models/p_b_lightsabre.mdl";

new const gszRedModelV[]="models/v_r_lightsabre.mdl";
new const gszGreenModelV[]="models/v_g_lightsabre.mdl";
new const gszBlueModelV[]="models/v_b_lightsabre.mdl";

new const gszModelW[]="models/w_lightsabre.mdl";

new const gszModelKnifeV[]="models/v_knife.mdl";
new const gszModelKnifeP[]="models/p_knife.mdl";



//Colors
enum{
	RED,
	GREEN,
	BLUE,
	ZWYKLY
}
new giColor[33]={ZWYKLY,...};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_menucmd(register_menuid("Saber"), KeysSabre, "PressedSaber")
	register_event("CurWeapon","eventKnife","be","1=1","2=29");
	
	register_forward(FM_EmitSound, "fwEmitSound",0);
	register_forward(FM_TraceHull, "fwTraceHull",0);
	
	register_clcmd("say /miecz", "cmdChooseSabre");
	register_clcmd("say /mieczswietlny", "cmdChooseSabre");
	register_clcmd("say /noz", "cmdChooseSabre");
	register_clcmd("say /starwars", "cmdChooseSabre");
}
public plugin_precache(){
	for(new i=0;i<sizeof gszNewSounds;i++)
		precache_sound(gszNewSounds[i]);
	precache_model(gszRedModelV);
	precache_model(gszGreenModelV);
	precache_model(gszBlueModelV);
	
	precache_model(gszRedModelP);
	precache_model(gszGreenModelP);
	precache_model(gszBlueModelP);
	
	precache_model(gszModelW);
	
	precache_model(gszModelKnifeV);
	precache_model(gszModelKnifeP);
	
}

//Forwards
public fwEmitSound(ent, channel, const sample[], Float:volume, Float:attenuation, fFlags, pitch){
	if(is_user_alive(ent) && (channel==1 || channel==3) && !noz[ent]){
		for(new i=0;i<sizeof gszOldSounds;i++){
			if(equal(sample,gszOldSounds[i])){
				engfunc(EngFunc_EmitSound, ent, channel, gszNewSounds[i], volume, attenuation, fFlags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
	}
	return FMRES_IGNORED;
}
public fwTraceHull(const Float:v1[], const Float:v2[3], fNoMonsters, hullNumber, pentToSkip, ptr){
	if(is_user_alive(pentToSkip) && !noz[pentToSkip]){
		new Float:fEnd[3], Float:fNormal[3];
		get_tr2(ptr, TR_vecEndPos, fEnd);
		get_tr2(ptr, TR_vecPlaneNormal, fNormal);
		for(new i=0;i<3;i++)
			fEnd[i]+=(fNormal[i]*KNIFE_RANGE_BONUS);
		set_tr2(ptr, TR_vecEndPos, fEnd);
		return FMRES_OVERRIDE;
	}
	return FMRES_IGNORED;
}
public eventKnife(id){
	new szVModel[32], szPModel[32];
	switch(giColor[id]){
		case RED:{
			copy(szVModel, 31, gszRedModelV);
			copy(szPModel, 31, gszRedModelP);
		}
		case GREEN:{
			copy(szVModel, 31, gszGreenModelV);
			copy(szPModel, 31, gszGreenModelP);
		}
		case BLUE:{
			copy(szVModel, 31, gszBlueModelV);
			copy(szPModel, 31, gszBlueModelP);
		}
		case ZWYKLY:{
			copy(szVModel, 31, gszModelKnifeV);
			copy(szPModel, 31, gszModelKnifeP);
			noz[id]=true;
		}
		default:{
			return;
		}
	}

	set_pev(id, pev_viewmodel2, szVModel);
	set_pev(id, pev_weaponmodel2, szPModel);
}
//cmds
public cmdChooseSabre(id){
	show_menu(id, KeysSabre, "\yWybierz kolor miecza swietlnego^n^n\w1. Czerwony^n2. Zielony^n3. Niebieski^n4. Zwykly Noz^n^n0. Exit^n", -1, "Saber");
	return PLUGIN_CONTINUE;
}
public PressedSaber(id, key) {
	/* Menu:
	* Choose color of sabre
	* 1. Red
	* 2. Green
	* 3. Blue
	* 4. Normal
	* 
	* 0. Exit
	*/

	switch (key) {
		case 0: { // 1
			giColor[id]=RED;
			noz[id]=false;
		}
		case 1: { // 2
			giColor[id]=GREEN;
			noz[id]=false;
		}
		case 2: { // 3
			giColor[id]=BLUE;
			noz[id]=false;
		}
		case 3: { // 4
			giColor[id]=ZWYKLY;
			noz[id]=true;
		}
		default: return PLUGIN_HANDLED
	}
	SaveData(id)
	return PLUGIN_HANDLED
}

public client_authorized(id)
	{
	LoadData(id)
}

SaveData(id)
{ 
	new Name[32] 
	get_user_name(id, Name, charsmax(Name)) 
	
	new vaultkey[64]
	new vaultdata[64]
	
	format(vaultkey, 63, "KNIFE_%s", Name)
	format(vaultdata, 63, "%d", giColor[id])
	set_vaultdata(vaultkey, vaultdata)
}

LoadData(id) 
{ 
	new Name[32] 
	get_user_name(id, Name, charsmax(Name)) 
	
	new vaultkey[64], vaultdata[64]
	
	format(vaultkey, 63, "KNIFE_%s", Name)
	get_vaultdata(vaultkey, vaultdata, 63)
	giColor[id] = str_to_num(vaultdata)
} 