#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_fskill>
#include <nd_print>
#include <nd_rounds>
#include <nd_swgm>
#include <nd_teampick>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_picking_list/nd_picking_list.txt"
#include "updater/standard.sp"

public Plugin myinfo = 
{
	name 		= "[ND] Team Pick List",
	author 		= "stickz",
	description 	= "Creates a list of players who want to command",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

bool WantsToCommand[MAXPLAYERS+1] = {false, ...};

public void OnPluginStart()
{
	RegConsoleCmd("sm_command", 	 CMD_VolunteerCommander);
	RegConsoleCmd("sm_PrintComList", CMD_PrintCommanderList);
	RegConsoleCmd("sm_DumpComSkills", CMD_PrintComSkillList);
	RegConsoleCmd("sm_DumpPickList", CMD_DumpPickList);
	
	/* Require steam group officer or root to access */
	RegConsoleCmd("sm_AddComList", 		CMD_AddCommanderList, 	 "Add a commander to the list");
	RegConsoleCmd("sm_RemoveComList", 	CMD_RemoveCommanderList, "Remove a commander from the list");
	RegConsoleCmd("sm_ClearComList", 	CMD_ClearCommanderList,  "Clear the commander list");
	
	LoadTranslations("common.phrases");
	LoadTranslations("nd_common.phrases");
	
	AddUpdaterLibrary();
}

public void OnMapStart() {
	ClearCommanderList();	
}

public void OnClientDisconnect(int client) {
	WantsToCommand[client] = false;
}

public Action CMD_VolunteerCommander(int client, int args)
{
	if (ND_RoundStarted())
	{
		PrintMessage(client, "Feature Unavailable");
		return Plugin_Handled;
	}
	
	if (WantsToCommand[client])
		PrintToChatAll("%s no longer wants to command!", GetClientName2(client));
	
	else if (!WantsToCommand[client])
		PrintToChatAll("%s would like to command!", GetClientName2(client));
							
	WantsToCommand[client] = !WantsToCommand[client];	
	return Plugin_Handled;
}

public Action CMD_AddCommanderList(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	// Check if the command was used properly
	if (args != 1) 
	{
		PrintToChat(client, "Usage: !AddComList <player>");
	 	return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));	
	int target = FindTarget(client, targetArg);
	
	// If the target is valid, add it to the commander list
	if (IsValidTarget(client, target))
	{	
		PrintToChat(client, "%s added to commander list", GetClientName2(target));	
		WantsToCommand[target] = true;
	}
	
	return Plugin_Handled;	
}

public Action CMD_RemoveCommanderList(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	// Check if the command was used properly
	if (args != 1) 
	{
		PrintToChat(client, "Usage: !RemoveComList <player>");
	 	return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));	
	int target = FindTarget(client, targetArg);
	
	// If the target is valid, remove it from the commander list
	if (IsValidTarget(client, target))
	{
		PrintToChat(client, "%s removed from commander list", GetClientName2(target));	
		WantsToCommand[target] = false;
	}
	
	return Plugin_Handled;	
}

public Action CMD_ClearCommanderList(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	ClearCommanderList();
	return Plugin_Handled;
}

public Action CMD_PrintCommanderList(int client, int args)
{
	PrintToChat(client, "See console for output");
	
	PrintSpacer(client); PrintSpacer(client);
	PrintToConsole(client, "--> List of Commanders <--");
	PrintToConsole(client, "Format: Name, Commander Skill");
	PrintSpacer(client);
	
	for (int target = 1; target <= MaxClients; target++)
		if (IsValidClient(target) && WantsToCommand[target])
			PrintToConsole(client, "%s: %d", GetClientName2(target), ND_GetRoundedCSkill(target));

	return Plugin_Handled;
}

public Action CMD_PrintComSkillList(int client, int args)
{
	PrintToChat(client, "See console for output");
	
	PrintSpacer(client); PrintSpacer(client);
	PrintToConsole(client, "--> List of Player Com Skill <--");
	PrintToConsole(client, "Format: Name, Commander Skill");
	PrintSpacer(client);
	
	for (int target = 1; target <= MaxClients; target++)
		if (IsValidClient(target))
			PrintToConsole(client, "%s: %d", GetClientName2(target), ND_GetRoundedCSkill(target));

	return Plugin_Handled;
}

public Action CMD_DumpPickList(int client, int args)
{
	PrintToChat(client, "See console for output");
	
	PrintSpacer(client); PrintSpacer(client);
	
	PrintToConsole(client, "--> List of Players picked by team <--");
	PrintToConsole(client, "Format: Name, Steamid");
	PrintSpacer(client);	
	
	PrintToConsole(client, "Team Consort");
	dumpClientsPickedByTeam(client, TEAM_CONSORT);
	PrintSpacer(client);
	
	PrintToConsole(client, "Team Empire");
	dumpClientsPickedByTeam(client, TEAM_EMPIRE);
	PrintSpacer(client);	
	
	PrintToConsole(client, "Not Picked");
	dumpClientsPickedByTeam(client, TEAM_SPEC);
	PrintSpacer(client);

	return Plugin_Handled;
}

void dumpClientsPickedByTeam(int player, int team)
{
	char clientName[64];
	char gAuth[32];
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && ND_GetPickedTeam(client) == team)
		{
			GetClientName(client, clientName, sizeof(clientName));
			GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
			PrintToConsole(player, "Name: %s, Steamid: %s", clientName, gAuth);
		}
	}	
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}

void ClearCommanderList() {
	for (int client = 1; client <= MaxClients; client++) 
		if (IsValidClient(client))
			WantsToCommand[client] = false;	
}

bool IsValidTarget(int client, int target) 
{
	if (target == -1)
	{
		PrintToChat(client, "Player not found.");
	 	return false;
	}
	
	return true;	
}

stock char GetClientName2(int client) 
{
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName));	
	return clientName;
}
