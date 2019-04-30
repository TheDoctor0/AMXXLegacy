#include <amxmodx>
#include <cstrike>

#define PLUGIN "Przelew i Bank"
#define VERSION "1.2"
#define AUTHOR "O'Zone"

#define MAX_MONEY 16000

new iPlayer[33], iAmount[33], iBankCT, iBankTT, iRound;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /przelew", "MenuTransfer");
	register_clcmd("say_team /przelew", "MenuTransfer");
	register_clcmd("przelew", "MenuTransfer");

	register_clcmd("say /przelej", "MenuTransfer");
	register_clcmd("say_team /przelej", "MenuTransfer");
	register_clcmd("przelej", "MenuTransfer");

	register_clcmd("say /bank", "MenuBank");
	register_clcmd("say_team /bank", "MenuBank");
	register_clcmd("bank", "MenuBank");

	register_clcmd("say /wyplac", "Withdraw");
	register_clcmd("say_team /wyplac", "Withdraw");
	register_clcmd("wyplac", "Withdraw");

	register_clcmd("say /wplac", "Deposit");
	register_clcmd("say_team /wplac", "Deposit");
	register_clcmd("wplac", "Deposit");

	register_clcmd("KWOTA", "Transfer_Handler");
	register_clcmd("KWOTA_WPLATY", "Deposit_Handler");
	register_clcmd("KWOTA_WYPLATY", "Withdraw_Handler");

	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
}

public plugin_cfg()
	set_task(240.0, "ShowInfo", .flags = "b");

public GameCommencing()
	iRound = 0;

public NewRound()
{
	for(new i = 1; i <= 32; i++) iAmount[i] = 0;

	iRound++;
}

public MenuTransfer(id)
{
	new szTemp[64], szName[32], szData[4], menu = menu_create("\wWybierz \rgracza\w, ktoremu chcesz przelac \ykase\w:", "MenuTransfer_Handler");

	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || id == i) continue;

		num_to_str(i, szData, charsmax(szData));

		get_user_name(i, szName, charsmax(szName));

		formatex(szTemp, charsmax(szTemp), "%s \w(\r%i$\w)", szName, cs_get_user_money(i));

		menu_additem(menu, szTemp, szData);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public MenuTransfer_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if(iRound == 1)
	{
		client_print_color(id, id, "^x03[PRZELEW]^x01 Przelewanie kasy w^x04 pierwszej rundzie^x01 jest zabronione!");

		return PLUGIN_HANDLED;
	}

	new szData[4], iAccess, iCallback, player;

	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);

	player = str_to_num(szData);

	if(!is_user_connected(player))
	{
		client_print_color(id, id, "^x03[PRZELEW]^x01 Tego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	iPlayer[id] = player;

	client_cmd(id, "messagemode KWOTA");

	client_print_color(id, id, "^x03[PRZELEW]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz przelac!");

	client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz przelac!");

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public Transfer_Handler(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	if(!is_user_connected(iPlayer[id]))
	{
		client_print_color(id, id, "^x03[PRZELEW]^x01 Gracza, ktoremu chcesz przelac kase nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	new szMoney[10], iMoney,  player = iPlayer[id], iCash = cs_get_user_money(id), iPlayerCash = cs_get_user_money(player);

	read_args(szMoney, charsmax(szMoney));
	remove_quotes(szMoney);

	iMoney = str_to_num(szMoney);

	if(iMoney <= 0)
	{
		client_print_color(id, id, "^x03[PRZELEW]^x01 Kwota musi byc wieksza od^x04 0$^x01!");

		return PLUGIN_HANDLED;
	}

	if(iCash < iMoney)
	{
		client_print_color(id, id, "^x03[PRZELEW]^x01 Nie masz tyle kasy!");

		return PLUGIN_HANDLED;
	}

	new szName[32], szPlayerName[32];

	get_user_name(id, szName, charsmax(szName));
	get_user_name(player, szPlayerName, charsmax(szPlayerName));

	if(iPlayerCash == MAX_MONEY)
	{
		client_print_color(id, id, "^x03[PRZELEW]^x03 %s^x01 ma wystarczajaco duzo kasy!", szPlayerName);

		return PLUGIN_HANDLED;
	}

	if (iPlayerCash + iMoney > MAX_MONEY)
	{
		iMoney = MAX_MONEY - iPlayerCash;

		client_print_color(id, id, "^x03[PRZELEW]^x03 %s^x01 nie potrzebowal az tyle kasy. Przelalem^x04 %i^x01 dolarow!", szPlayerName, iMoney);
	}

	cs_set_user_money(id, iCash - iMoney);
	cs_set_user_money(player, iPlayerCash + iMoney);

	client_print_color(0, id, "^x03%s^x01 przelal^x04 %i$^x01 na konto^x03 %s^x01.", szName, iMoney, szPlayerName);

	return PLUGIN_HANDLED;
}

public MenuBank(id)
{
	if(get_user_team(id) != 1 && get_user_team(id) != 2) return PLUGIN_HANDLED;

	if(iRound == 1)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Bank w^x04 pierwszej rundzie^x01 jest zamkniety!");

		return PLUGIN_HANDLED;
	}

	new szMenu[64];

	formatex(szMenu, charsmax(szMenu), "\wWybierz \ropcje \wbanku:^nStan konta druzyny: \y%i", get_user_team(id) == 1 ? iBankTT : iBankCT);

	new menu = menu_create(szMenu, "MenuBank_Handler");

	menu_additem(menu, "Wplac \yKase");
	menu_additem(menu, "Wyplac \yKase");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public Withdraw(id)
{
	client_cmd(id, "messagemode KWOTA_WYPLATY");

	client_print_color(id, id, "^x03[BANK]^x01 W banku druzyny jest aktualnie^x04 %i$^x01!", get_user_team(id) == 1 ? iBankTT : iBankCT);
	client_print_color(id, id, "^x03[BANK]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz wyplacic z banku!");

	client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz wyplacic z banku!");

	return PLUGIN_HANDLED;
}

public Deposit(id)
{
	client_cmd(id, "messagemode KWOTA_WPLATY");

	client_print_color(id, id, "^x03[BANK]^x01 W banku druzyny jest aktualnie^x04 %i$^x01!", get_user_team(id) == 1 ? iBankTT : iBankCT);
	client_print_color(id, id, "^x03[BANK]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz wplacic do banku!");

	client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz wplacic do banku!");

	return PLUGIN_HANDLED;
}

public MenuBank_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0:
		{
			client_cmd(id, "messagemode KWOTA_WPLATY");

			client_print_color(id, id, "^x03[BANK]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz wplacic do banku!");

			client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz wplacic do banku!");
		}
		case 1:
		{
			client_cmd(id, "messagemode KWOTA_WYPLATY");

			client_print_color(id, id, "^x03[BANK]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz wyplacic do banku!");

			client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz wyplacic do banku!");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public Deposit_Handler(id)
{
	if(!is_user_connected(id) || (get_user_team(id) != 1 && get_user_team(id) != 2)) return PLUGIN_HANDLED;

	new szMoney[10], iMoney, iCash = cs_get_user_money(id);

	read_args(szMoney, charsmax(szMoney));
	remove_quotes(szMoney);

	iMoney = str_to_num(szMoney);

	if(iMoney <= 0)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Kwota musi byc wieksza od^x04 0$^x01!");

		return PLUGIN_HANDLED;
	}

	if(iCash < iMoney)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Nie masz tyle kasy!");

		return PLUGIN_HANDLED;
	}

	switch(get_user_team(id))
	{
		case 1: iBankTT += iMoney;
		case 2: iBankCT += iMoney;
	}

	new szName[32];

	get_user_name(id, szName, charsmax(szName));

	cs_set_user_money(id, iCash - iMoney);

	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || get_user_team(id) != get_user_team(i) || id == i) continue;

		client_print_color(i, id, "^x03%s^x01 wplacil^x04 %i$^x01 do banku druzyny^x03 %s^x01.", szName, iMoney, get_user_team(id) == 1 ? "terrorystow" : "antyterrorystow");
	}

	client_print_color(id, id, "^x03[BANK]^x01 Wplaciles^x04 %i$^x01 do banku druzyny^x03 %s^x01.", iMoney, get_user_team(id) == 1 ? "terrorystow" : "antyterrorystow");

	return PLUGIN_HANDLED;
}

public Withdraw_Handler(id)
{
	if(!is_user_connected(id) || (get_user_team(id) != 1 && get_user_team(id) != 2)) return PLUGIN_HANDLED;

	if(iRound < 3)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Wyplacanie kasy z banku jest mozliwe od^x04 trzeciej rundy^x01!");

		return PLUGIN_HANDLED;
	}

	new szMoney[10], iMoney, iCash = cs_get_user_money(id), iBank = get_user_team(id) == 1 ? iBankTT : iBankCT;

	read_args(szMoney, charsmax(szMoney));
	remove_quotes(szMoney);

	iMoney = str_to_num(szMoney);

	if(iMoney <= 0)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Kwota musi byc wieksza od^x04 0$^x01!");

		return PLUGIN_HANDLED;
	}

	if(iAmount[id] + iMoney > 5000)
	{
		client_print_color(id, id, "^x03[BANK]^x01 W jednej rundzie mozesz wyplacic maksymalnie^x04 5000$^x01!");

		return PLUGIN_HANDLED;
	}

	if(iBank < iMoney)
	{
		client_print_color(id, id, "^x03[BANK]^x01 W banku nie ma tyle kasy!");

		return PLUGIN_HANDLED;
	}

	if(iCash == MAX_MONEY)
	{
		client_print_color(id, id, "^x03[BANK]^x01 Masz wystarczajaco duzo kasy!");

		return PLUGIN_HANDLED;
	}

	if (iCash + iMoney > MAX_MONEY)
	{
		iMoney = MAX_MONEY - iCash;

		client_print_color(id, id, "^x03[BANK]^x01 Nie potrzebowales az tyle kasy. Przelalem^x04 %i^x01 dolarow!", iMoney);
	}

	switch(get_user_team(id))
	{
		case 1: iBankTT -= iMoney;
		case 2: iBankCT -= iMoney;
	}

	iAmount[id] += iMoney;

	new szName[32];

	get_user_name(id, szName, charsmax(szName));

	cs_set_user_money(id, iCash + iMoney);

	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || get_user_team(id) != get_user_team(i) || id == i) continue;

		client_print_color(i, id, "^x03%s^x01 wyplacil^x04 %i$^x01 z banku druzyny^x03 %s^x01.", szName, iMoney, get_user_team(id) == 1 ? "terrorystow" : "antyterrorystow");
	}

	client_print_color(id, id, "^x03[BANK]^x01 Wyplaciles^x04 %i$^x01 z banku druzyny^x03 %s^x01.", iMoney, get_user_team(id) == 1 ? "terrorystow" : "antyterrorystow");

	return PLUGIN_HANDLED;
}

public ShowInfo()
{
	if(get_playersnum() == 0) return;

	switch(random_num(0, 1))
	{
		case 0: client_print_color(0, 0, "Wpisz^x04 /przelej^x01, aby przelac kase innym graczom.");
		case 1: client_print_color(0, 0, "Wpisz^x04 /bank^x01, aby wplacic/wyplacic kase z banku druzyny.");
	}
}
