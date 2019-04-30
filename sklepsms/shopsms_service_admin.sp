#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <shopsms>

#define SERVICE_ID "goadmin"
#define MAX_PLAYERS 32

new char g_szFlags[MAX_FLAGS + 1];
new bool bAdmin[MAX_PLAYERS + 1];
new bool bSql = false;
new Database db;
new Handle:ServerNameHandle = INVALID_HANDLE;
new String:ServerName[64];

public Plugin myinfo =
{
	name = "Shop SMS: Service: Admin",
	author = "O'Zone",
	description = "ShopSMS's extension that allow players to purchase Admin.",
	version = VERSION,
	url = "http://www.sklep-sms.pl/"
};

public void OnPluginStart() {
	SSRegisterService(SERVICE_ID, ServiceLoaded, ServiceAddingToList);
	
	ServerNameHandle = FindConVar("hostname");
	if(ServerNameHandle == INVALID_HANDLE)
		SetFailState("[ShopSMS] Unable to retrieve hostname.");
	
	GetConVarString(ServerNameHandle, ServerName, sizeof(ServerName));
	
	SqlInit();
}

public void ServiceLoaded(const char[] name, const char[] flags) {
	strcopy(g_szFlags, sizeof(g_szFlags), flags);
}

public void SqlInit()
{
	char error[255];
	db = SQL_Connect("shopsms", true, error, sizeof(error));
 
	if (db == null)
	{
		PrintToServer("Could not connect: %s", error);
		
		bSql = false;
	}
	
	bSql = true;
}

public void CheckList(int id)
{
	DBStatement hUserStmt = null;
	
	char error[255];
	hUserStmt = SQL_PrepareQuery(db, "SELECT a.date, a.type, b.name FROM ss_admins a JOIN ss_servers b ON a.server = b.id WHERE a.name = ?", error, sizeof(error));
	
	if (hUserStmt == null)
	{
		PrintToServer("Cannot create prepared query");
		
		return;
	}
	
	char name[64];
	GetClientName(id, name, sizeof(name));
 
	SQL_BindParamString(hUserStmt, 0, name, false);
	
	if (!SQL_Execute(hUserStmt))
	{
		return;
	}
	
	
	while(SQL_MoreRows(hUserStmt))
	{
		while(SQL_FetchRow(hUserStmt))
		{
			new String:Server[64];
 
			int Date = SQL_FetchInt(hUserStmt, 0);
			int Type = SQL_FetchInt(hUserStmt, 1);
			SQL_FetchString(hUserStmt, 2, Server, sizeof(Server));
		
			ReplaceString(Server, sizeof(Server), "CS-Reload.pl | ", "");
			ReplaceString(Server, sizeof(Server), " CS:GO", "");
		
			if(StrContains(ServerName, Server, false)) != -1)
			{
				if(!iDate)
				{
					bAdmin[id] = true;
			
					return;
				}

				if(iType)
				{
					bAdmin[id] = true;
			
					return;
				}
			}
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if( !IsFakeClient(client) && GetClientCount(true) < MaxClients )
	{
		bAdmin[client] = false;
		
		CheckList(client);
	}
}

public int ServiceAddingToList(int id) 
{
	if( GetUserFlagBits(id) & ReadFlagString(g_szFlags) == ReadFlagString(g_szFlags) || !bAdmin[id])
		return ITEMDRAW_DISABLED;

	return ITEMDRAW_DEFAULT;
}
