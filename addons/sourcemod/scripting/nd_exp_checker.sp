#include <sourcemod>
#include <nd_stats>
#include <nd_stocks>
#include <nd_redstone>

public Plugin myinfo =
{
	name = "[ND] Expereince Checker",
	author = "Stickz",
	description = "Creates commands players can use to view client expereince.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_exp_checker/nd_exp_checker.txt"
#include "updater/standard.sp"

#define EXP_NAME_COUNT 3
char expNames[EXP_NAME_COUNT][] = {
	"sm_DumpPlayerEXP",
	"sm_ListPlayerEXP",
	"sm_ShowPlayerEXP"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_CheckExp", CMD_GetExp);
	
	for (int i = 0; i < EXP_NAME_COUNT; i++){
		RegConsoleCmd(expNames[i], CMD_DumpPlayerEXP);		
	}
	
	AddUpdaterLibrary(); // for auto-updater
}

public Action CMD_GetExp(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_CheckExp [player name]");
		return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	int target = FindTarget(client, targetArg);
	if (target == -1)
	{
		ReplyToCommand(client, "Target player name not found");
		return Plugin_Handled;	
	}
	
	if (!ND_EXPAvailible(target))
	{
		ReplyToCommand(client, "Failed to reteive exp from steamworks");
		return Plugin_Handled;	
	}
	
	char pName[64];
	GetClientName(target, pName, sizeof(pName))
	
	PrintToChat(client, "\x05[xG] %s's exp is %d", pName, ND_GetClientEXP(target));
	return Plugin_Handled;
}

/* Functions for !DumpPlayerData */
public Action CMD_DumpPlayerEXP(int client, int args)
{
	if (!ND_GCE_LOADED())
	{
		ReplyToCommand(client, "Failed to reteive exp from steamworks");
		return Plugin_Handled;
	}
	
	DumpPlayerEXP(client);
	return Plugin_Handled;
}

void DumpPlayerEXP(int player)
{
	PrintSpacer(player); PrintSpacer(player);
	
	PrintToConsole(player, "--> Player Experience Values <--");
	PrintToConsole(player, "Format: Name, Player Experience");
	PrintSpacer(player);
	
	for (int team = 0; team < 4; team++)
	{
		if (RED_GetTeamCount(team > 0))
		{
			PrintToConsole(player, "Team %s:", ND_GetTeamName(team));
			dumpPlayersOnTeam(team, player);
			PrintSpacer(player);
		}
	}
}

void dumpPlayersOnTeam(int team, int player)
{	
	char Name[32];
	for (int client; client <= MaxClients; client++)
	{
		if (RED_IsValidClient(client) && GetClientTeam(client) == team)
		{
			GetClientName(client, Name, sizeof(Name));		
			PrintToConsole(player, "Name: %s, Experience: %d", Name, ND_GetClientEXP(client));
		}
	}
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}