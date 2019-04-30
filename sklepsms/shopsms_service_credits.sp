#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <shopsms>

#define SERVICE_ID "dr_credits"

native void Store_IsClientLoaded (int client);
native int Store_GetClientCredits (int client);
native void Store_SetClientCredits (int client, int amount);

public Plugin myinfo =
{
	name = "Shop SMS: Service: DeathRun Credits",
	author = "O'Zone",
	description = "ShopSMS's extension that allow players to purchase VIP.",
	version = VERSION,
	url = "http://www.sklep-sms.pl/"
};

public void OnPluginStart() {
	SSRegisterService(SERVICE_ID, _, ServiceAddingToList, _, SSServicePurchased);
}

public int ServiceAddingToList(int id) {
	// Wylaczamy mozliwosc zakupu, jezeli dane gracza nie zostaly zaladowane
	if( !Store_IsClientLoaded(id) )
		return ITEMDRAW_DISABLED;

	return ITEMDRAW_DEFAULT;
}

public void SSServicePurchased (int id, int amount) {
	Store_SetClientCredits(id, Store_GetClientCredits(id) + amount);
}
