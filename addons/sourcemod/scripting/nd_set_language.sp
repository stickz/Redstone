#include <sourcemod>
#include <clientprefs>
#include <nd_stocks>
#include <geoip>

public Plugin myinfo =
{
	name = "[ND] Set Language",
	author = "Stickz",
	description = "Set's a client's game language based on their region",
	version = "recompile2",
	url = "https://github.com/stickz/Redstone/"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_set_language/nd_set_language.txt"
#include "updater/standard.sp"

#include "nd_slang/clientprefs.sp"

public void OnPluginStart()
{
	RegConsoleCmd("sm_getlangcode", CMD_GetLangCode);
	
	LoadTranslations("nd_set_language.phrases");
	AddClientPrefsSupport(); // nd_slang/clientprefs.sp	
	
	AddUpdaterLibrary(); // Add updater support
}

public Action CMD_GetLangCode(int client, int args)
{
	char code[64];
	GetCmdArg(1, code, sizeof(code));
	
	int lang = GetLanguageByCode(code);
	PrintToChat(client, "Code: %s, Lang %d", code, lang);
	
	return Plugin_Handled;	
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client) && option_set_language[client])
	{
		char ip[16];
		GetClientIP(client, ip, sizeof(ip));
		
		char ccode[3];
		GeoipCode2(ip, ccode);
		
		int lang = -1;		
		if (StrEqual(ccode, "de", false))
		{
			lang = GetLanguageByCode("de");
			SetClientLanguage(client, lang);
			PrintToConsole(client, "Your server language was set to German");	
		}
		else if (StrEqual(ccode, "ru", false))
		{
			lang = GetLanguageByCode("ru");
			SetClientLanguage(client, lang);
			PrintToConsole(client, "Your server language was set to Russian");
		}
		else if (StrEqual(ccode, "ca", false) || StrEqual(ccode, "us", false))
		{
			lang = GetLanguageByCode("en");
			SetClientLanguage(client, lang);
			PrintToConsole(client, "Your server language was set to English");
		}
		else
		{
			char message[128];
			Format(message, sizeof(message), "Unsupported language: %s", ccode);			
			ConsoleToAdmins(message, "b");
		}
	}
}