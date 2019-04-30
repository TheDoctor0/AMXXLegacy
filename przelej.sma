#include <amxmodx>
#include <cstrike>

#define PLUGIN "Przelew"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define MAX_MONEY 16000

new selectedPlayer[MAX_PLAYERS + 1], roundNum;

new const commandTransfer[][] = { "przelej", "say /przelej", "say_team /przelej", "say /przelew", "say_team /przelew" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for(new i; i < sizeof commandTransfer; i++) register_clcmd(commandTransfer[i], "transfer_menu");

	register_clcmd("KWOTA", "transfer_handle");

	register_event("HLTV", "new_round", "a", "1=0", "2=0");

	register_event("TextMsg", "game_restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
}

public plugin_cfg()
	set_task(240.0, "ShowInfo", .flags = "b");

public game_restart()
	roundNum = 0;

public new_round()
	roundNum++;

public transfer_menu(id)
{
	new menuData[64], playerName[32], tempId[4], menu = menu_create("\wWybierz \rgracza\w, ktoremu chcesz przelac \ykase\w:", "transfer_menu_handle");

	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || id == i) continue;

		num_to_str(i, tempId, charsmax(tempId));

		get_user_name(i, playerName, charsmax(playerName));

		formatex(menuData, charsmax(menuData), "%s \w(\r%i$\w)", playerName, cs_get_user_money(i));

		menu_additem(menu, menuData, tempId);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public transfer_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if(roundNum == 1)
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Przelewanie kasy w^x04 pierwszej rundzie^x01 jest zabronione!");

		return PLUGIN_HANDLED;
	}

	new tempId[4], menuAccess, menuCallback, player;

	menu_item_getinfo(menu, item, menuAccess, tempId, charsmax(tempId), _, _, menuCallback);

	player = str_to_num(tempId);

	if(!is_user_connected(player))
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Tego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	selectedPlayer[id] = player;

	client_cmd(id, "messagemode KWOTA");

	client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Wpisz ilosc^x04 kasy^x01, ktora chcesz przelac!");

	client_print(id, print_center, "Wpisz ilosc kasy, ktora chcesz przelac!");

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public transfer_handle(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;

	if(!is_user_connected(selectedPlayer[id]))
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Gracza, ktoremu chcesz przelac kase nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	new tempMoney[10], transferMoney, player = selectedPlayer[id], playerMoney = cs_get_user_money(id), selectedPlayerMoney = cs_get_user_money(player);

	read_args(tempMoney, charsmax(tempMoney));
	remove_quotes(tempMoney);

	transferMoney = str_to_num(tempMoney);

	if(transferMoney <= 0)
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Kwota musi byc wieksza od^x04 0$^x01!");

		return PLUGIN_HANDLED;
	}

	if(playerMoney < transferMoney)
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x01 Nie masz tyle kasy!");

		return PLUGIN_HANDLED;
	}

	new playerName[32], selectedPlayerName[32];

	get_user_name(id, playerName, charsmax(playerName));
	get_user_name(player, selectedPlayerName, charsmax(selectedPlayerName));

	if(selectedPlayerMoney == MAX_MONEY)
	{
		client_print_color(id, print_team_red, "^x03[PRZELEW]^x03 %s^x01 ma wystarczajaco duzo kasy!", selectedPlayerName);

		return PLUGIN_HANDLED;
	}

	if (selectedPlayerMoney + transferMoney > MAX_MONEY)
	{
		transferMoney = MAX_MONEY - selectedPlayerMoney;

		client_print_color(id, print_team_red, "^x03[PRZELEW]^x03 %s^x01 nie potrzebowal az tyle kasy. Przelalem^x04 %i^x01 dolarow!", selectedPlayerName, transferMoney);
	}

	cs_set_user_money(id, playerMoney - transferMoney);
	cs_set_user_money(player, selectedPlayerMoney + transferMoney);

	client_print_color(0, id, "^x03%s^x01 przelal^x04 %i$^x01 na konto^x03 %s^x01.", playerName, transferMoney, selectedPlayerName);

	return PLUGIN_HANDLED;
}

public ShowInfo()
{
	if(!get_playersnum()) return;

	client_print_color(0, print_team_default, "Wpisz^x04 /przelej^x01, aby przelac kase innym graczom.");
}
