#include <amxmodx>
#include <amxmisc>

new onoff,rgb2,density_cvar,r,g,b,g_density[4]
new bool:on
public plugin_init() {
	register_plugin("Advanced Fog","0.7","Sh!nE*")
	onoff = register_cvar("amx_fog_default","1")
	rgb2 = register_cvar("amx_fog_color","116 137 147")
	density_cvar = register_cvar("amx_fog_amount","3")
	register_concmd("amx_fog","set_fog",ADMIN_MAP,"<on/off> <r/g/b> <amount 1-9>")
}

public set_fog(id,level,cid)
{
	if (!cmd_access(id,level,cid,4)) return PLUGIN_HANDLED
	new args[3][16],rgb[3][4],numrgb[3],i,tempdens[4]
	read_argv(1,args[0],15)
	read_argv(2,args[1],15)
	read_argv(3,args[2],15)
	new density = str_to_num(args[2])
	if((args[1][0]=='0' && !args[1][2]) || equali(args[1],"off")) {
		new temp_rgb2[3][4],temp_rgb[16]
		get_pcvar_string(rgb2,temp_rgb,15)
		parse(temp_rgb,temp_rgb2[0],3,temp_rgb2[1],3,temp_rgb2[2],3)
		for(i=0;i < 3;i++) numrgb[i] = str_to_num(temp_rgb2[i])
	} else {	
		parse(args[1],rgb[0],3,rgb[1],3,rgb[2],3)
		for(i=0;i < 3;i++) numrgb[i] = str_to_num(rgb[i])
	}
	if(numrgb[0] < 0 || numrgb[0] > 255 || numrgb[1] < 0 || numrgb[1] > 255 || numrgb[2] < 0 || numrgb[2] > 255) {
		client_print(id,print_console,"WARNING: RGB has to be a number between 0 and 255.");
		for(i=0;i < 3;i++) numrgb[i] = 150
	}
	if(density == 0 || density > 9 || density < 1) {client_print(id,print_console,"WARNING: Density has to be a number between 1 and 9");density = get_pcvar_num(density_cvar);}
	switch(density) {
		case 1:{tempdens[0]=3;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
		case 2:{tempdens[0]=125;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
		case 3:{tempdens[0]=27;tempdens[1]=59;tempdens[2]=66;tempdens[3]=96;}
		case 4:{tempdens[0]=60;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
		case 5:{tempdens[0]=68;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
		case 6:{tempdens[0]=95;tempdens[1]=59;tempdens[2]=10;tempdens[3]=41;}
		case 7:{tempdens[0]=125;tempdens[1]=59;tempdens[2]=111;tempdens[3]=18;}
		case 8:{tempdens[0]=3;tempdens[1]=60;tempdens[2]=111;tempdens[3]=18;}
		case 9:{tempdens[0]=19;tempdens[1]=60;tempdens[2]=68;tempdens[3]=116;}
	}
	g_density[0]=tempdens[0]
	g_density[1]=tempdens[1]
	g_density[2]=tempdens[2]
	g_density[3]=tempdens[3]
	r = numrgb[0]
	g = numrgb[1]
	b = numrgb[2]

	if(equali(args[0],"on") || args[0][0]=='1') {
		on = true
		message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
		write_byte(numrgb[0])  // R
		write_byte(numrgb[1])  // G
		write_byte(numrgb[2])  // B
		write_byte(tempdens[2]) // SD
		write_byte(tempdens[3])  // ED
		write_byte(tempdens[0])   // D1
		write_byte(tempdens[1])  // D2
		message_end()
	}
	else if(equali(args[0],"off") || args[0][0]=='0') {
		on = false
		message_begin(MSG_ALL,get_user_msgid("Fog"),{0,0,0},0)
		write_byte(0)  // R
		write_byte(0)  // G
		write_byte(0)  // B
		write_byte(0) // SD
		write_byte(0)  // ED
		write_byte(0)   // D1
		write_byte(0)  // D2
		message_end()
	}
	return PLUGIN_HANDLED
}

public client_putinserver(id) set_task(0.1,"set_fog2",id)

public set_fog2(id) {
	if(on || get_pcvar_num(onoff)) {
		new number[3],tempdens[4]
		if(g_density[0] == 0 && !on) {
			switch(get_pcvar_num(density_cvar)) {
				case 1:{tempdens[0]=3;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
				case 2:{tempdens[0]=125;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
				case 3:{tempdens[0]=27;tempdens[1]=59;tempdens[2]=66;tempdens[3]=96;}
				case 4:{tempdens[0]=60;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
				case 5:{tempdens[0]=68;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
				case 6:{tempdens[0]=95;tempdens[1]=59;tempdens[2]=10;tempdens[3]=41;}
				case 7:{tempdens[0]=125;tempdens[1]=59;tempdens[2]=111;tempdens[3]=18;}
				case 8:{tempdens[0]=3;tempdens[1]=60;tempdens[2]=111;tempdens[3]=18;}
				case 9:{tempdens[0]=19;tempdens[1]=60;tempdens[2]=68;tempdens[3]=116;}
			}
		}
		else {
			tempdens[0] = g_density[0]
			tempdens[1] = g_density[1]
			tempdens[2] = g_density[2]
			tempdens[3] = g_density[3]
		}
		if((r > 0 || g > 0 || b > 0) && on) {number[0] = r;number[1] = g;number[2] = b;} 
		else {
			new string[16],string2[3][4],i
			get_pcvar_string(rgb2,string,15)
			parse(string,string2[0],3,string2[1],3,string2[2],3)
			for(i=0;i < 3;i++) number[i] = str_to_num(string2[i])
			if(number[0] < 0 || number[0] > 255 || number[1] < 0 || number[1] > 255 || number[2] < 0 || number[2] > 255)
				log_amx("WARNING: RGB has to be a number between 0 and 255.")
		}
		message_begin(MSG_ONE,get_user_msgid("Fog"),{0,0,0},id)
		write_byte(number[0])  // R
		write_byte(number[1])  // G
		write_byte(number[2])  // B
		write_byte(tempdens[2]) // SD
		write_byte(tempdens[3])  // ED
		write_byte(tempdens[0])   // D1
		write_byte(tempdens[1])  // D2
		message_end()
	}
}

/*
				case 1:{tempdens[0]=125;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
				case 2:{tempdens[0]=3;tempdens[1]=58;tempdens[2]=111;tempdens[3]=18;}
				case 3:{tempdens[0]=68;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
				case 4:{tempdens[0]=125;tempdens[1]=59;tempdens[2]=111;tempdens[3]=18;}
				case 5:{tempdens[0]=95;tempdens[1]=59;tempdens[2]=10;tempdens[3]=41;}
				case 6:{tempdens[0]=60;tempdens[1]=59;tempdens[2]=90;tempdens[3]=101;}
				case 7:{tempdens[0]=27;tempdens[1]=59;tempdens[2]=66;tempdens[3]=96;}
				case 8:{tempdens[0]=3;tempdens[1]=60;tempdens[2]=111;tempdens[3]=18;}
				case 9:{tempdens[0]=19;tempdens[1]=60;tempdens[2]=68;tempdens[3]=116;}
				
						   D1   D2   SD    ED
				----------------------------------------
				 0.001 = -125 ; 58 ; 111 ; 18
				 0.002 = 3 ; 59 ; 111 ; 18
				 0.003 = 68 ; 59 ; -90 ; -101
				 0.004 = -125 ; 59 ; 111 ; 18
				 0.005 = -93 ; 59 ; 10; -41
				 0.006 = -60 ; 59 ; -90 ; -101
				 0.007 = -27 ; 59 ; 66 ; 96
				 0.008 = 3 ; 60 ; 111 ; 18
				 0.009 = 19 ; 60 ; -68 ; 116
*/

