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
		
		PrintCommanderLangTeam(client, team, langName);
	}
}

PrintCommanderLangTeam(commander, team, langName)
{
	decl String:cName[64];
	GetClientName(commander, cName, sizeof(cName));
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintToChat(client, "\x04[xG] %s's game client language is %s.", cName, langName);  
		}
	}
}
