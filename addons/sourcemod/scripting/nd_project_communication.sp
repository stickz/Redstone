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

#define LANGUAGE_COUNT 		44
#define STRING_STARTS_WITH 	0

#define REQUEST_BUILDING_COUNT 12

new const String:nd_request_building[REQUEST_BUILDING_COUNT][] =
{
	"Transport Gate",
	"MG Turret",
	"Power Station",
	"Supply Station",
	"Armory",
	"Artillery",
	"Radar Station",
	"Flamethrower Turret",
	"Sonic Turret",
	"Rocket Turret",
	"Wall",
	"Barrier"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_project_communication/nd_project_communication.txt"
#include "updater/standard.sp"

#include "nd_project_communication/commander_lang.sp"
#include "nd_project_communication/team_lang.sp"

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	AddUpdaterLibrary(); //auto-updater
	
	LoadTranslations("structminigame.phrases");
	LoadTranslations("nd_project_communication.phrases");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintTeamLanguages();
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client)
	{
		if (STRING_STARTS_WITH == StrContains(sArgs, "request", false))
		{
			new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
			
			for (new idx = 0; idx < REQUEST_PHRASES_SIZE; idx++)
			{
				if (StrContains(sArgs, nd_request_building[idx], false))
				{
					PrintSimpleBuildingRequest(client, nd_request_building[idx]);
					SetCmdReplySource(old);
					return Plugin_Stop; 
				}
			}
			
			PrintToChat(client, "/x04(Translator) /x05No translation keyword found.");
			SetCmdReplySource(old);
			return Plugin_Stop; 
		}
	}
}

PrintSimpleBuildingRequest(client, const String:bName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsValidClient(idx) && GetClientTeam(client) == team)
			{
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, cName, bName);
				
				PrintToChat(idx, "/x04(Translator) /x05%s", ToPrint); 
			}
		}
	}
}
