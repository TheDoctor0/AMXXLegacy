#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <shopsms>

#define SERVICE_ID "goresnick"

public Plugin myinfo =
{
	name = "Shop SMS: Service: Nick Reservation",
	author = "SeeK",
	description = "ShopSMS's extension that allow players to purchase Nick Reservation.",
	version = VERSION,
	url = "http://www.sklep-sms.pl/"
};

public void OnPluginStart() {
	SSRegisterService(SERVICE_ID);
}
