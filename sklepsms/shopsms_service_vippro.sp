#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <shopsms>

#define SERVICE_ID "govippro"

char g_szFlags[MAX_FLAGS+1];

public Plugin myinfo =
{
	name = "Shop SMS: Service: VIP PRO",
	author = "SeeK",
	description = "ShopSMS's extension that allow players to purchase VIP PRO.",
	version = VERSION,
	url = "http://www.sklep-sms.pl/"
};

public void OnPluginStart() {
	SSRegisterService(SERVICE_ID, ServiceLoaded, ServiceAddingToList);
}

public void ServiceLoaded(const char[] name, const char[] flags) {
	strcopy(g_szFlags, sizeof(g_szFlags), flags);
}

public int ServiceAddingToList(int id) {
	// Wylaczamy mozliwosc zakupu, jezeli gracz juz ma odpowiedni zestaw flag
	if( GetUserFlagBits(id) & ReadFlagString(g_szFlags) == ReadFlagString(g_szFlags) )
		return ITEMDRAW_DISABLED;

	return ITEMDRAW_DEFAULT;
}
