#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <engine>

#define IsPlayer(%1) (1<=%1<=maxPlayers)
#define FALL_VELOCITY 350.0

forward amxbans_admin_connect(id);
forward zp_user_infected_post(infected, infector);

native zp_ammopacks_set(id, ap);
native zp_ammopacks_get(id);

new Array:g_Array, CsArmorType:armortype, bool:g_Vip[33], g_Hudmsg, ioid,
maxPlayers, skoki[33];

new const g_Langcmd[][]={"say /vips","say_team /vips","say /vipy","say_team /vipy"};
new const g_Prefix[] = "Vip Chat";
new bool:falling[33];

public client_PreThink(id) 
{
	if(is_user_alive(id))
	{
		if(entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY) 
			falling[id] = true;
		else
			falling[id] = false;
	}
}

public client_PostThink(id) 
{
	if(is_user_alive(id)) 
	{
		if(falling[id] && g_Vip[id]) 
		{
			entity_set_int(id, EV_INT_watertype, -3);
		}
	}
}

public plugin_init(){
	register_plugin("VIP Ultimate", "12.3.0.2", "benio101 & speedkill");
	register_forward(FM_CmdStart, "CmdStartPre");
	RegisterHam(Ham_Spawn, "player", "SpawnedEventPre", 1);
	RegisterHam(Ham_TakeDamage, "player", "takeDamage", 0);
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	register_event("DeathMsg", "DeathMsg", "a");
	g_Array=ArrayCreate(64,32);
	for(new i;i<sizeof g_Langcmd;i++){
		register_clcmd(g_Langcmd[i], "ShowVips");
	}
	register_clcmd("say /vip", "ShowMotd");
	register_clcmd("say_team", "VipChat");
	register_message(get_user_msgid("SayText"),"handleSayText");
	g_Hudmsg=CreateHudSyncObj();
}
public plugin_natives()
{
	register_native("set_user_vip", "zp_set_user_vip", 1);
	register_native("get_user_vip", "zp_get_user_vip", 1);
}
public zp_set_user_vip(id)
{
	g_Vip[id]=true;
	new g_Name[64];
	get_user_name(id,g_Name,charsmax(g_Name));
	
	new g_Size = ArraySize(g_Array);
	new szName[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, szName, charsmax(szName));
		
		if(equal(g_Name, szName)){
			return 0;
		}
	}
	ArrayPushString(g_Array,g_Name);
	
	return PLUGIN_CONTINUE;
}
public zp_get_user_vip(id)
	return g_Vip[id];
public client_authorized(id){
	if(get_user_flags(id) & 524288 == 524288){
		client_authorized_vip(id);
	}
}
public client_authorized_vip(id){
	g_Vip[id]=true;
	new g_Name[64];
	get_user_name(id,g_Name,charsmax(g_Name));
	
	new g_Size = ArraySize(g_Array);
	new szName[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, szName, charsmax(szName));
		
		if(equal(g_Name, szName)){
			return 0;
		}
	}
	ArrayPushString(g_Array,g_Name);
	set_hudmessage(24, 190, 220, 0.25, 0.2, 0, 6.0, 6.0);
	ShowSyncHudMsg(0, g_Hudmsg, "VIP %s wbija na serwer !",g_Name);
	
	return PLUGIN_CONTINUE;
}
public client_disconnected(id){
	if(g_Vip[id]){
		client_disconnect_vip(id);
	}
}
public client_disconnect_vip(id){
	g_Vip[id]=false;
	new Name[64];
	get_user_name(id,Name,charsmax(Name));
	
	new g_Size = ArraySize(g_Array);
	new g_Name[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		if(equal(g_Name,Name)){
			ArrayDeleteItem(g_Array,i);
			break;
		}
	}
}
public CmdStartPre(id, uc_handle){
	if(g_Vip[id]){
		if(is_user_alive(id)){
			CmdStartPreVip(id, uc_handle);
		}
	}
}
public CmdStartPreVip(id, uc_handle){
	new flags = pev(id, pev_flags);
	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && skoki[id]>0){
		--skoki[id];
		new Float:velocity[3];
		pev(id, pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id,pev_velocity,velocity);
	} else if(flags & FL_ONGROUND && skoki[id]!=-1){
		skoki[id] = 2;
	}
}
public SpawnedEventPre(id){
	if(g_Vip[id]){
		if(is_user_alive(id)){
			SpawnedEventPreVip(id);
		}
	}
}
public SpawnedEventPreVip(id){
	set_user_gravity(id, 0.5);
	skoki[id]=2;
	cs_set_user_armor(id, min(cs_get_user_armor(id,armortype)+50, 150), CS_ARMOR_VESTHELM);
}
public DeathMsg(){
	new killer=read_data(1);
	new victim=read_data(2);
	
	if(is_user_alive(killer) && g_Vip[killer] && get_user_team(killer) != get_user_team(victim))
		zp_ammopacks_set(killer, zp_ammopacks_get(killer) + 1);
}
public zp_user_infected_post(infected, infector)
{
	if(g_Vip[infector])
	{
		set_user_health(infector, get_user_health(infector) + 500);
		zp_ammopacks_set(infector, zp_ammopacks_get(infector) + 1);
	}
}
public plugin_cfg(){
	maxPlayers=get_maxplayers();
}
public takeDamage(this, idinflictor, idattacker, Float:damage, damagebits){
	if(((IsPlayer(idattacker) && is_user_connected(idattacker) && g_Vip[idattacker] && (ioid=idattacker)) ||
	(ioid=pev(idinflictor, pev_owner) && IsPlayer(ioid) && is_user_connected(ioid) && g_Vip[ioid]))){
		damage*=(100+10)/100;
	}
}
public VipStatus(){
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && g_Vip[id]){
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
	}
}
public ShowVips(id){
	new g_Name[64],g_Message[192];
	
	new g_Size=ArraySize(g_Array);
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		add(g_Message, charsmax(g_Message), g_Name);
		
		if(i == g_Size - 1){
			add(g_Message, charsmax(g_Message), ".");
		}
		else{
			add(g_Message, charsmax(g_Message), ", ");
		}
	}
	client_print_color(id, id,"^x03Vipy na serwerze:^x04 %s", g_Message);
	return PLUGIN_CONTINUE;
}
public client_infochanged(id){
	if(g_Vip[id]){
		new szName[64];
		get_user_info(id,"name",szName,charsmax(szName));
		
		new Name[64];
		get_user_name(id,Name,charsmax(Name));
		
		if(!equal(szName,Name)){
			ArrayPushString(g_Array,szName);
			
			new g_Size=ArraySize(g_Array);
			new g_Name[64];
			for(new i = 0; i < g_Size; i++){
				ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
				
				if(equal(g_Name,Name)){
					ArrayDeleteItem(g_Array,i);
					break;
				}
			}
		}
	}
}
public plugin_end(){
	ArrayDestroy(g_Array);
}
public ShowMotd(id){
	show_motd(id, "vip.txt", "Informacje o VIPie");
}
public VipChat(id){
	if(g_Vip[id]){
		new g_Msg[256],
		g_Text[256];
		
		read_args(g_Msg,charsmax(g_Msg));
		remove_quotes(g_Msg);
		
		if(g_Msg[0] == '*' && g_Msg[1]){
			new g_Name[64];
			get_user_name(id,g_Name,charsmax(g_Name));
			
			formatex(g_Text,charsmax(g_Text),"^x01(%s) ^x03%s : ^x04%s",g_Prefix, g_Name, g_Msg[1]);
			
			for(new i=1;i<33;i++){
				if(is_user_connected(i) && g_Vip[i])
				client_print_color(i, i, "%s", g_Text);
			}
			return PLUGIN_HANDLED_MAIN;
		}
	}
	return PLUGIN_CONTINUE;
}
public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id) && g_Vip[id]){
		new szTmp[256],szTmp2[256];
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		
		new szPrefix[64] = "^x04[VIP]";
		
		if(!equal(szTmp,"#Cstrike_Chat_All")){
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2)," ");
			add(szTmp2,charsmax(szTmp2),szTmp);
		}
		else{
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
		}
		set_msg_arg_string(2,szTmp2);
	}
	return PLUGIN_CONTINUE;
}
public amxbans_admin_connect(id){
	client_authorized(id, "");
}