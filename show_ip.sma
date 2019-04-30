#include <amxmodx>
#include <amxmisc>

#define LICZBA_GRACZY 32
#define MAX_DLUGOSC_WPISU 46
#define MAX_ILOSC_ZAKRESOW 160 // Ilosc wpisow w pliku ipdesc.ini

#define SHIFT_8  8
#define SHIFT_16 16
#define SHIFT_24 24

new g_Poczatek_Zakresu[MAX_ILOSC_ZAKRESOW]
new g_Koniec_Zakresu[MAX_ILOSC_ZAKRESOW]
new g_OpisSieci[MAX_ILOSC_ZAKRESOW][MAX_DLUGOSC_WPISU + 1]
new g_licznik_zakresow = 0
new g_Opis_Sieci_gracza[LICZBA_GRACZY + 1][MAX_DLUGOSC_WPISU + 1]
new auth_prov_str[32][9]
new pcv_dp_r_id_provider

public plugin_init()
{
	register_plugin("StatusIP", "1.7", "ahtoh&ZiuTeK")
	register_concmd("amx_ip", "wyswietl_adresy_ip", ADMIN_ALL,"wyswietla IP graczy")
	new configsDir[64]
	get_configsdir(configsDir, sizeof(configsDir)-1)
	format(configsDir, sizeof(configsDir)-1, "%s/ipdesc.ini", configsDir)
	loadSubnets(configsDir)
	pcv_dp_r_id_provider = get_cvar_pointer ("dp_r_id_provider")
}

public wyswietl_adresy_ip(id)
{	
	new gracze[32], hostname[64], hostip[32],inum,userip[16]
	get_cvar_string("hostname", hostname, 63) 
	get_cvar_string("net_address", hostip, 31) 
	console_print(id, "----------------------Informacje------------------------------")
	console_print(id, " %s", hostip)
	console_print(id, " %s", hostname)
	console_print(id, "--------------------------------------------------------------")
	get_players(gracze, inum) 
	new authid[32], name[32]
	new i=0
	for(new a = 0; a < inum; ++a)
	{
		get_user_ip(gracze[a],userip,sizeof(userip)-1,1)
		get_user_name(gracze[a], name, sizeof(name)-1) 
		get_user_authid(gracze[a], authid, 31) 
		if (!is_user_bot(gracze[a]) && !is_user_hltv(gracze[a]))
		if(!(get_user_flags(gracze[a]) & ADMIN_RESERVATION) && (access(gracze[a],ADMIN_LEVEL_H) && access(gracze[a],ADMIN_USER)))
		{
			console_print(id,"#%d %s  %s  %s  %s  %s  KontoNEO", ++i, name, authid,userip,auth_prov_str[gracze[a]],g_Opis_Sieci_gracza[gracze[a]])
		}
		else
		{
		console_print(id,"#%d %s %s  %s  %s  %s", ++i, name, is_user_nonsteam(authid) ? "" :authid,userip,auth_prov_str[gracze[a]],g_Opis_Sieci_gracza[gracze[a]])
		/*(is_user_nonsteam(authid)) 
			? console_print(id,"#%d %s  %s  %s  %s", ++i, name, userip,auth_prov_str[gracze[a]],g_Opis_Sieci_gracza[gracze[a]])
			: console_print(id,"#%d %s %s  %s  %s  %s", ++i, name, authid, userip,auth_prov_str[gracze[a]],g_Opis_Sieci_gracza[gracze[a]])
		*/
		}
	}
	console_print(id, "--------------------------------------------------------------") 
	return PLUGIN_HANDLED
}
public client_authorized(id)
{
	new userip[16]
	get_user_ip(id,userip,sizeof(userip)-1,1)
	znajdz_opis_sieci(userip, g_Opis_Sieci_gracza[id], MAX_DLUGOSC_WPISU)
	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	server_cmd("dp_clientinfo %d",id)
	server_exec()
	new authprov = get_pcvar_num(pcv_dp_r_id_provider)
	switch (authprov) 
	{
		case 2: copy(auth_prov_str[id],8,  "Steam") // 2 to steam - pozostale to non
		default: copy(auth_prov_str[id], 8, "Nonsteam")
	}
}

znajdz_opis_sieci(const ip[16], description[], maxlen)
{
	new numIP = ip_to_num(ip) // zmieniamy IP na numer
	for (new i = 0; i < g_licznik_zakresow; i++)
	{
		if ( g_Poczatek_Zakresu[i] <= numIP <= g_Koniec_Zakresu[i])
		{
			copy(description, maxlen, g_OpisSieci[i])
			return 0
		}
		else copy(description, maxlen, "")
	}
	return -1
}

loadSubnets(szFilename[])
{
	g_licznik_zakresow = 0
	new File=fopen(szFilename,"r");
	if (File)
	{
		new Text[256]
		new subnet[33], g_poczatkowe_IP[16], g_koncowe_IP[16]
		while(g_licznik_zakresow < MAX_ILOSC_ZAKRESOW && !feof(File))
		{
			fgets(File,Text,sizeof(Text)-1);
			trim(Text)
			if (Text[0]==';' || Text[0] == 0) 
			{
				continue;
			}
			strbreak(Text, subnet, sizeof(subnet)-1, g_OpisSieci[g_licznik_zakresow], MAX_DLUGOSC_WPISU)
			replace(subnet, sizeof(subnet)-1, "/", " ")
			if (parse(subnet, g_poczatkowe_IP, sizeof(g_poczatkowe_IP)-1, g_koncowe_IP, sizeof(g_koncowe_IP)-1) != 2)
				continue 
			g_Poczatek_Zakresu[g_licznik_zakresow] = ip_to_num(g_poczatkowe_IP)
			g_Koniec_Zakresu[g_licznik_zakresow] = ip_to_num(g_koncowe_IP)
			++g_licznik_zakresow
		}
	}

	return 1
}
/*
stock ip_to_num(const ip[16])
{
    new ip2[16]
    ip2 = ip
    new len = strlen(ip)
    for(new i = 0; i < len; i++) if(ip2[i] == '.') copy(ip2[i], len-i-1, ip2[i+1])
    return str_to_num(ip2)
}*/


ip_to_num(const ip[])
{
	new n1[4], n2[4], n3[4], n4[4]
	new tmpStr[16]
	
	copy(tmpStr, sizeof(tmpStr)-1, ip)
	replace_all(tmpStr, sizeof(tmpStr)-1, ".", " ")
	if (parse(tmpStr, n1, sizeof(n1)-1, n2, sizeof(n2)-1, n3, sizeof(n3)-1, n4, sizeof(n4)-1) != 4)
		return -1 // wrong ip address
		
	return (str_to_num(n1) << SHIFT_24) + (str_to_num(n2) << SHIFT_16) + (str_to_num(n3) << SHIFT_8) + str_to_num(n4)
}
stock is_user_nonsteam(authid[])
{
	if(containi(authid, "LAN") != -1	) return 1;
	return 0;
}
