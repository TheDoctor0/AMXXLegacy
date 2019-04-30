#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat>
#include <nvault>

#define PLUGIN "Knife Models"
#define VERSION "1.3"
#define AUTHOR "O'Zone"

new player_auth[33][64], player_knife[33], knife;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "KnifeModel", 1);
	
	register_clcmd("say /noz", "ChangeKnife");
	register_clcmd("sayteam /noz", "ChangeKnife");
	register_clcmd("say /noze", "ChangeKnife");
	register_clcmd("sayteam /noze", "ChangeKnife");
	register_clcmd("say /knife", "ChangeKnife");
	register_clcmd("sayteam /knife", "ChangeKnife");
	register_clcmd("say /knifes", "ChangeKnife");
	register_clcmd("sayteam /knifes", "ChangeKnife");
	
	knife = nvault_open("knife");
	if(knife == INVALID_HANDLE)
		set_fail_state("Nie mozna otworzyc pliku knife.vault");
}	

public plugin_precache()
{
	precache_model("models/csr_knife.mdl"); //Gold Knife
	precache_model("models/csr_knife2.mdl"); //Shaolin Stick
	precache_model("models/csr_knife3.mdl"); //Katana Sword
	precache_model("models/csr_knife4.mdl"); //Machete Knife
	precache_model("models/csr_knife5.mdl"); //Dagger Knife
	precache_model("models/csr_knife6.mdl"); //Bayonet Marble Fade
	precache_model("models/csr_knife7.mdl"); //Huntsman Crimson Web
	precache_model("models/csr_knife8.mdl"); //Karambit Dopler
}

public client_putinserver(id)
{
	get_user_name(id, player_auth[id], 63);
	LoadKnife(id);
}

public client_disconnect(id)
	player_knife[id] = 0;

public ChangeKnife(id)
{
	new menu = menu_create("\wWybierz\r Model Noza\w:", "ChangeKnife_Handler");
	
	menu_additem(menu, "\wGold \yKnife", "0");
	menu_additem(menu, "\wShaolin \yStick", "1");
	menu_additem(menu, "\wKatana \ySword", "2");
	menu_additem(menu, "\wMachete \yKnife", "3");
	menu_additem(menu, "\wDagger \yKnife", "4");
	menu_additem(menu, "\wBayonet \yMarble Fade", "5");
	menu_additem(menu, "\wHuntsman \yCrimson Web", "6");
	menu_additem(menu, "\wKarambit \yDopler^n", "7");
	menu_additem(menu, "\wWyjscie");
	
	menu_setprop(menu, MPROP_PERPAGE, 0);
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public ChangeKnife_Handler(id, menu, item)
{
	if(item == 8 || !is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: 
		{
			player_knife[id] = 0;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Gold Knife^x01.");
		}
		case 1: 
		{
			player_knife[id] = 1;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Shaolin Stick^x01.");
		}
		case 2: 
		{
			player_knife[id] = 2;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Katana Sword^x01.");
		}
		case 3: 
		{
			player_knife[id] = 3;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Machete Knife^x01.");
		}
		case 4: 
		{
			player_knife[id] = 4;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Dagger Knife^x01.");
		}
		case 5: 
		{
			player_knife[id] = 5;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Bayonet Marble Fade^x01.");
		}
		case 6: 
		{
			player_knife[id] = 6;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Huntsman Crimson Web^x01.");
		}
		case 7: 
		{
			player_knife[id] = 7;
			ColorChat(id, RED, "[KNIFE]^x01 Wybrales model:^x04 Karambit Dopler^x01.");
		}
	}
	
	SaveKnife(id);
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public KnifeModel(wpn)
{
	static iOwner;
	iOwner = pev(wpn, pev_owner);
	
	if(!is_user_alive(iOwner))
		return PLUGIN_CONTINUE;
		
	switch(player_knife[iOwner])
	{
		case 0: set_pev(iOwner,pev_viewmodel2, "models/csr_knife.mdl"); 
		case 1: set_pev(iOwner,pev_viewmodel2, "models/csr_knife2.mdl");
		case 2: set_pev(iOwner,pev_viewmodel2, "models/csr_knife3.mdl"); 
		case 3: set_pev(iOwner,pev_viewmodel2, "models/csr_knife4.mdl");
		case 4: set_pev(iOwner,pev_viewmodel2, "models/csr_knife5.mdl");  
		case 5: set_pev(iOwner,pev_viewmodel2, "models/csr_knife6.mdl");
		case 6: set_pev(iOwner,pev_viewmodel2, "models/csr_knife7.mdl");
		case 7: set_pev(iOwner,pev_viewmodel2, "models/csr_knife8.mdl");
	}
	
	return PLUGIN_CONTINUE;
}

public SaveKnife(id)
{
	new vaultkey[64], vaultdata[10];
	
	formatex(vaultkey, 63, "%s-player_knife", player_auth[id]);
	formatex(vaultdata, 9, "%d", player_knife[id]);
	
	nvault_set(knife, vaultkey, vaultdata);
	
	return PLUGIN_CONTINUE;
}

public LoadKnife(id)
{
	new vaultkey[64], vaultdata[10];
	
	formatex(vaultkey, 63, "%s-player_knife", player_auth[id]);
	
	if(nvault_get(knife, vaultkey, vaultdata, 63))
	{
		new saved[10];
		parse(vaultdata, saved, 9);
		player_knife[id] = str_to_num(saved);
	}
	
	return PLUGIN_CONTINUE;
} 