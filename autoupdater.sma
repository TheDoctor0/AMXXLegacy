#include <amxmodx>
#include <sockets>

#define PLUGIN "Plugins AutoUpdater"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define LOG_FILE "addons/amxmodx/logs/autoupdater.log" // Plik logów
#define TEMP_CONFIG "update.ini" // Tymczasowy plik aktualizacyjny
#define MAX_PACKET 1460	// Maksymalna wielkosc pakietu
#define BACKUP 1 // Tworzenie kopii zapasowej pobieranego pliku
#define RESTORE_BACKUP 1 // Przywracanie kopii w razie, gdy plik zostal poprany nieprawidlowo
#define REMOVE_BACKUP 1 // Usuwanie kopii po zakonczeniu procesu pobierania

#define TASK_DOWNLOAD 7651
#define TASK_SOCKET 8651
#define TASK_CLOSE 9651

#pragma dynamic 32768

new iSocket, iDownloaded;

new Trie:tPlugins;

new cvarHost, cvarVersion, cvarFiles;

new szFiles[64], szVersion[64], szHost[32];

new bool:iFilesUpdated;

new const szStatus[][] = 
{
	"OK",
	"Nie udalo sie utworzyc socketa",
	"Nie rozpoznano nazwy hosta",
	"Polaczenie HTTP nie moglo zostac nawiazane",
	"Nie podano wszystkich danych",
	"Nie udalo sie otworzyc lokalnego pliku",
	"Nieprawidlowy rozmiar pliku",
	"Czas polaczenia zostal przekroczony"
};

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cvarHost = register_cvar("autoupdater_host", "cs-reload.co.nf");
	cvarFiles = register_cvar("autoupdater_files", "/autoupdater/files.ini");
	cvarVersion = register_cvar("autoupdater_version", "/autoupdater/version.php");
	
	tPlugins = TrieCreate();

	get_plugin(-1, szFiles, charsmax(szFiles), _, _, szVersion, charsmax(szVersion), _, _, _, _);
	
	TrieSetString(tPlugins, szFiles, szVersion);
	
	CheckUpdates();
}

public plugin_end()
	TrieClear(tPlugins);

public plugin_natives()
	register_native("autoupdater_register_plugin", "RegisterPlugin");
	
public RegisterPlugin(plugin, params)
{
	if(params != 0)
		return;
	
	static szFile[64], szVersion[16];
	
	get_plugin(plugin, szFile, charsmax(szFile), _, _, szVersion, charsmax(szVersion), _, _, _, _);
	
	TrieSetString(tPlugins, szFile, szVersion);
}

public CheckUpdates()
{
	get_pcvar_string(cvarHost, szHost, charsmax(szHost));
	get_pcvar_string(cvarFiles, szFiles, charsmax(szFiles));
	get_pcvar_string(cvarVersion, szVersion, charsmax(szVersion));
	
	new iFail = Download(szHost, szVersion, TEMP_CONFIG, 1);
	
	if(iFail)
	{
		new szError[64];
		
		formatex(szError, charsmax(szError), "[AutoUpdater] Blad pobierania wersji aktualizacji: %s", szStatus[iFail]);
		set_fail_state(szError);
	}
	
	if(iFilesUpdated) return;
	
	iFail = Download(szHost, szFiles, TEMP_CONFIG);
	
	if(iFail)
	{
		new szError[64];
		
		formatex(szError, charsmax(szError), "[AutoUpdater] Blad pobierania aktualizacji: %s", szStatus[iFail]);
		set_fail_state(szError);
	}
	
	set_task(0.1, "DownloadUpdate", TASK_DOWNLOAD, .flags = "b");
}

public DownloadUpdate()
{	
	if(!iDownloaded)
		return;
		
	remove_task(TASK_DOWNLOAD);

	new szContent[256], szDestination[192], szDirectory[128], szSource[128], szName[64], szFolder[64], szLocalVersion[16], szNetVersion[16], iUpdated, iOpen = fopen(TEMP_CONFIG, "r");
	
	get_localinfo("amxx_pluginsdir", szDirectory, charsmax(szDirectory));
	
	while(!feof(iOpen))
	{
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
		if(szContent[0] == ';' || szContent[0] == '^0' || contain(szContent, "version") != -1) 
			continue;
			
		if(contain(szContent, "folder") != -1)
		{
			parse(szContent, szName, charsmax(szName), szFolder, charsmax(szFolder));
			continue;
		}

		parse(szContent, szName, charsmax(szName), szNetVersion, charsmax(szNetVersion));
		
		if(TrieGetString(tPlugins, szName, szLocalVersion, charsmax(szLocalVersion)) && !equal(szNetVersion, szLocalVersion))
		{
			log_to_file(LOG_FILE, "[AutoUpdater] Znaleziono aktualizacje pluginu %s!", szName);
			
			formatex(szSource, charsmax(szSource), "%s/%s", szFolder, szName);
			
			formatex(szDestination, charsmax(szDestination), "%s/%s", szDirectory, szName);
			
			new iFail = Download(szHost, szSource, szDestination);

			if(iFail) log_to_file(LOG_FILE, "[AutoUpdater] Blad pobierania pliku: ^"%s^" - %s", szName, szStatus[iFail]);
			else iUpdated++;
		}
	}
	fclose(iOpen);
	
	if(iUpdated) log_to_file(LOG_FILE, "[AutoUpdater] Zaktualizowano %i plugin%s!", iUpdated, iUpdated == 1 ? "" : iUpdated > 4 ? "ow" : "y");
}

stock Download(szHost[], szSource[], szDestination[], iCheck = 0)
{
	if(!strlen(szHost) || !strlen(szSource) || !strlen(szDestination))
		return 4;
	
	new iError;
	
	iSocket = socket_open(szHost, 80, SOCKET_TCP, iError);
	
	if(iSocket < 1)
		return iError;
	
	static szQuery[1024], iLen;
	
	iLen = format(szQuery, charsmax(szQuery), "GET %s HTTP/1.0^r^n", szSource);
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Cache-control: max-age=0^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Cache-Control: no-cache^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Cache-Control: max-stale=0^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Cache-Control: min-fresh=1000^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Accept: */*^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Keep-Alive: 600^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Connection: keep-alive^r^n");
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "User-Agent: %s's %s v.%s^r^n", AUTHOR, PLUGIN, VERSION);
	iLen += format(szQuery[iLen], charsmax(szQuery) - iLen, "Host: %s^r^n^r^n", szHost);
	
	socket_send(iSocket, szQuery, strlen(szQuery));
	
	if(iCheck)
	{
		new szBuffer[1024], szVersion[16];

		socket_recv(iSocket, szBuffer, charsmax(szBuffer));
		
		new iPos = strfind(szBuffer, "Content-Type: text/html; charset=UTF-8") + 38;
		
		formatex(szVersion, charsmax(szVersion), szBuffer[iPos]);
		
		replace_all(szVersion, charsmax(szVersion), " ", "");
		replace_all(szVersion, charsmax(szVersion), "^n", "");
		replace_all(szVersion, charsmax(szVersion), "^r", "");
		
		new szContent[64], szName[32], szTempVersion[16], iOpen = fopen(TEMP_CONFIG, "r");
	
		while(!feof(iOpen))
		{
			fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);
		
			if(szContent[0] == ';' || szContent[0] == '^0') 
				continue;
			
			if(contain(szContent, "version") != -1)
			{
				parse(szContent, szName, charsmax(szName), szTempVersion, charsmax(szTempVersion));
			
				if(equal(szVersion, szTempVersion))
					iFilesUpdated = true;
				
				break;
			}
		}

		socket_close(iSocket);
	}
	else
	{
		set_task(0.1, "DownloadAnswer", TASK_SOCKET, szDestination, 63, .flags = "b");
	
		set_task(15.0, "CloseConnection", TASK_CLOSE);
	}
	
	return 0;
}

public DownloadAnswer(szDestination[])
{
	if(!socket_change(iSocket))
		return;
		
	remove_task(TASK_SOCKET);
	
	new szBuffer[MAX_PACKET + 1], szBackup[128], iLen, iContentLen, iPlainPos;
	
	iLen = socket_recv(iSocket, szBuffer, MAX_PACKET);
	
	if(contain(szBuffer, "200 OK") != -1)
	{
		new szTemp[8], i, iPos = strfind(szBuffer, "Content-Length: ") + 16;

		while(szBuffer[iPos + i] != 10)
		{
			szTemp[i] = szBuffer[iPos + i];
			i++;
		}
		
		iContentLen = str_to_num(szTemp);
		iPlainPos = strfind(szBuffer, "^r^n^r^n");
	} 
	else log_to_file(LOG_FILE, "[AutoUpdater] Blad! Nieprawidlowa odpowiedz z hosta.");

	if(BACKUP && file_exists(szDestination))
	{
		formatex(szBackup, charsmax(szBackup), "%s.backup", szDestination);
		
		if(file_exists(szBackup))
			unlink(szBackup);

		rename_file(szDestination, szBackup, 1);
	}
	
	new iOpen = fopen(szDestination, "wb");
	
	if(!iOpen) log_to_file(LOG_FILE, "[AutoUpdater] Blad: %s.", szStatus[5]);
	
	if(iPlainPos != -1)
	{
		for(new i = iPlainPos + 4; i < iLen; i++) 
			fputc(iOpen, szBuffer[i]);
	}

	while(socket_change(iSocket) || 1)
	{
		iLen = socket_recv(iSocket, szBuffer, MAX_PACKET);
		
		if(iLen == 0)	
			break;

		for(new i; i < iLen; i++)
			fputc(iOpen, szBuffer[i]);
	}

	fclose(iOpen);
	socket_close(iSocket);
	
	if((file_size(szDestination, 0) != iContentLen) && iContentLen)
	{
		formatex(szBackup, charsmax(szBackup), "%s.backup", szDestination);
		
		if(RESTORE_BACKUP && file_exists(szBackup))
		{
			unlink(szDestination);
			rename_file(szBackup, szDestination, 1);
		} 
		else log_to_file(LOG_FILE, "[AutoUpdater] Blad: %s.", szStatus[6]);
	}
	
	formatex(szBackup, charsmax(szBackup), "%s.backup", szDestination);
	
	if(REMOVE_BACKUP && file_exists(szBackup)) unlink(szBackup);
	
	if(contain(szDestination, TEMP_CONFIG) != -1)
		iDownloaded = true;
	
	remove_task(TASK_CLOSE);
}

public CloseConnection()
{
	log_to_file(LOG_FILE, "[AutoUpdater] Blad: %s.", szStatus[7]);
	
	socket_close(iSocket);
}
