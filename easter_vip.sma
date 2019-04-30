#include <amxmodx>
#include <nvault>
#include <colorchat>

#define PLUGIN "Easter VIP"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

//new codes[][] = { "34UVHMR3", "QG39RE9U", "FDFCZN2P", "NLHTPINI", "C83JLLC1", "R618A0TG", "4YIUCBAP", "MH82PMAS", "L42WF5NW", "1FV26E80", "LFD3BN5L", "6QWF9HO0", "D5FHF5OA", "LJ8ZTW95", "2CY3PUFM" } DD2
//new codes[][] = { "87KUTM10", "C2CJYAD9", "6DNMKS7Y", "XMHEVKQU", "H0F1D6SF", "ZVONVSNS", "W046J2V6", "E2AZCQKJ", "HPAKLSPA", "D4OZM1H9" } 4FUN
//new codes[][] = { "5SREWDM2", "YL2T89MH", "SY02L3VB", "JOQ0K0KG", "J1L55XYU", "8RE7RQF9", "E61PZMR9", "170BXAI7", "2T3XGRIF", "9MDQ2IP7", "S0RFQ0CD", "ZHH7EN93", "276PMWLC", "5WZDT1GC", "RXI8OKCE" } BF2
//new codes[][] = { "XN1SFM1M", "LQX34U98", "5OPDS7LL", "G4VHKC77", "QZPWBH9N", "YWHTHHRC", "W6FE3RP9", "MBHWEEUV", "4AI6HHJ6", "4RPBZ6DL" } DIABLO
//new codes[][] = { "UQTL4H38", "V0Y01I4N", "TBVOX07B", "R32D4GMO", "W6ZQDTPZ", "JDQAMKO5", "LAK90IAI", "B2M58YKV", "UACYTRO3", "V547FJ3R" } ZM
new codes[][] = { "5SREWDM2", "YL2T89MH", "SY02L3VB", "JOQ0K0KG", "J1L55XYU", "8RE7RQF9", "E61PZMR9", "170BXAI7", "2T3XGRIF", "9MDQ2IP7", "S0RFQ0CD", "ZHH7EN93", "276PMWLC", "5WZDT1GC", "RXI8OKCE" }
new code[33][15]
new code_number = 0

new vip_codes
new code_numbers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	vip_codes = nvault_open("vip_codes")
	if(vip_codes == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku vip_codes.vault")
		
	code_numbers = nvault_open("code_numbers")
	if(code_numbers == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku code_numbers.vault")
		
	register_clcmd("say /kod", "CheckCode")
	register_event("DeathMsg", "DeathMsg", "a")
	
	LoadNumber()
}

public client_putinserver(id)
{
	if(!is_user_hltv(id) && !is_user_bot(id))
		LoadCode(id)
}

public CheckCode(id)
{
	if(strlen(code[id][0]) == 1)
		ColorChat(id, RED, "[KOD]^x01 Nie udalo ci sie dotychczas zdobyc kodu. Walcz dalej!")
	else
		ColorChat(id, RED, "[KOD]^x01 Twoj kod do kupna VIP'a w SklepieSMS:^x04 %s^x01.", code[id])
}

public CodeInfo(id)
{
	if(is_user_connected(id))
	{
		ColorChat(id, RED, "[KOD]^x01 Posiadasz zdobyty kod do kupna VIP'a na 30 dni SklepieSMS.")
		ColorChat(id, RED, "[KOD]^x01 Twoj kod to:^x04 %s^x01.", code[id])
		ColorChat(id, RED, "[KOD]^x01 Wpisz go jako kod zwrotny SMS przy zakupie.")
		ColorChat(id, RED, "[KOD]^x01 Wykorzystaj go dla siebie lub oddaj innemu graczowi.")
	}
}

public DeathMsg()
{
	new killer = read_data(1)
	new victim = read_data(2)
	
	if(is_user_connected(killer) && killer != victim && random_num(1, 3500) == 1)
		GiveCode(killer)
		
	return PLUGIN_CONTINUE
}

public GiveCode(id)
{
	if(strlen(code[id][0]) != 1 || code_number == 15)
		return PLUGIN_CONTINUE
		
	new name[33]
	get_user_name(id, name, 32)
	client_print(id, print_center, "Znalazles kod na VIP'a na 30 dni!")
	ColorChat(0, RED, "[KOD]^x01 %s znalazl^x04 jajko wielkanocne^x01, a w nim kod na^x04 VIP'a na 30 dni^x01!", name)
	ColorChat(id, RED, "[KOD]^x01 Zabity przeciwnik upuscil^x04 jajko wielkanocne^x01. Znalazles w nim:^x04 VIP'a na 30 dni^x01!")
	ColorChat(id, RED, "[KOD]^x01 Twoj kod:^x04 %s^x01!", codes[code_number])
	ColorChat(id, RED, "[KOD]^x01 Mozesz go wykorzystac w SklepieSMS dla siebie lub oddac kod innemu graczowi.")
	ColorChat(id, RED, "[KOD]^x01 Jesli zapomnisz kodu, mozesz go sprawdzic wpisujac komende:^x04 /kod^x01.")
	
	formatex(code[id], 9, codes[code_number])
	SaveCode(id)
	
	code_number++
	SaveNumber()
	log_to_file("addons/amxmodx/logs/easter_vip.txt", "Gracz %s zdobyl %i kod: %s", name, code_number, codes[code_number-1]);
	
	return PLUGIN_CONTINUE
}

public SaveCode(id)
{
	new vaultkey[64], vaultdata[10], name[33]
	get_user_name(id, name, 32)
	formatex(vaultkey, 63, "%s-vip_code", name)
	formatex(vaultdata, 9, "%s", code[id])
	nvault_set(vip_codes, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE
}

public LoadCode(id)
{
	code[id] = "0"
	new vaultkey[64], vaultdata[10], name[33]
	get_user_name(id, name, 32)
	formatex(vaultkey, 63, "%s-vip_code", name)
	if(nvault_get(vip_codes, vaultkey, vaultdata, 63))
	{
		parse(vaultdata, code[id], 9)
		set_task(10.0, "CodeInfo", id)
	}
	
	return PLUGIN_CONTINUE
}

public SaveNumber()
{
	new vaultkey[16], vaultdata[10]
	formatex(vaultkey, 15, "code_numbers")
	formatex(vaultdata, 9, "%d", code_number)
	nvault_set(code_numbers, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE
}  

public LoadNumber()
{
	new vaultkey[16], vaultdata[10], number[10]
	formatex(vaultkey, 15, "code_numbers")
	
	if(nvault_get(code_numbers, vaultkey, vaultdata, 15))
	{
		parse(vaultdata, number, 9)
		code_number = str_to_num(number)
	}
	
	return PLUGIN_CONTINUE
}