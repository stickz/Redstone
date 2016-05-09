#include <sourcemod>
#include <nd_stocks>

public Plugin:myinfo =
{
	name 		= "[ND] Project Communication",
	author 		= "Stickz",
	description 	= "Breaks Communication Barriers",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_project_communication/nd_project_communication.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	AddUpdaterLibrary(); //auto-updater
}

public Event_CommanderPromo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "teamid");
	
	if (IsValidClient(client))
	{
		new langNum = GetClientLanguage(client);
		decl String:langCode[8], String:langName[32];
		GetLanguageInfo(langNum, langCode, sizeof(langCode), langName, sizeof(langName));
		
		if (!StrEqual("english", langName, true))
			PrintCLangToTeam(team, langName);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintTeamLanguages();
}

PrintCLangToTeam(team, const String:langName[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "\x05The commander's game client language is %s.", langName);  
		}
	}
}

PrintTLangToTeam(team, const String:printOut[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "\x05Team Languages: %s", printOut);	
		}
	}
}

PrintTeamLanguages()
{
	new bool:ShowMessage[2] = {false, ...};
	new langCount[2][64] = {0, ..., ...};
	new clientTeam, teamIDX;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			clientTeam = GetClientTeam(client);
			
			if (clientTeam > 2)
			{
				new langNum = GetClientLanguage(client);
				decl String:langCode[8], String:langName[32];
				GetLanguageInfo(langNum, langCode, sizeof(langCode), langName, sizeof(langName));
				
				if (!StrEqual("english", langName, true))
				{
					teamIDX = clientTeam - 2;
					ShowMessage[teamIDX] = true;
					langCount[teamIDX][langNum]++;
				}
			}
		}
	}
	
	for (new team = 0; team < 2; team++)
	{
		if (ShowMessage[team])
		{
			decl String:PrintOut[128];
			for (new lang = 0; lang < 64; lang++)
			{
				if (langCount[team][lang] > 0)
				{
					decl String:langCode[8], String:langName[32];
					GetLanguageInfo(lang, langCode, sizeof(langCode), langName, sizeof(langName));  
					StrCat(PrintOut, sizeof(PrintOut), " %s: %d", langCode, langCount[team][lang]);
				}
			}
			PrintTLangToTeam(team + 2, PrintOut);
		}
	}
}
