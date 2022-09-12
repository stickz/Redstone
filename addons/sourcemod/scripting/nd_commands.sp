#include <sourcemod>
#include <sdktools>
#include <nd_access>

public Plugin myinfo =
{
	name = "[ND] Server Commands",
	author = "Stickz",
	description = "Adds administrative server commands",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commands/nd_commands.txt"
#include "updater/standard.sp"

Handle g_OnTeamPlacedForward;

public void OnPluginStart()
{
	RegisterCommands();	
	
	g_OnTeamPlacedForward = CreateGlobalForward("ND_OnClientTeamSet", ET_Ignore, Param_Cell, Param_Cell);
	LoadTranslations("common.phrases");
	
	AddUpdaterLibrary(); //auto-updater
}

/*Switch a target player's team */
public Action Command_Swap(int client, int args) 
{
	if (!ND_HasTeamPickRunAccess(client))
		return Plugin_Handled;
	
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_swap [player name]");
		return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	int target = FindTarget(0, targetArg);
	if (target != -1)
	{
		if (GetClientTeam(target) > 1)
		{
			LogAction(client, target, "\"%L\" swapped \"%L\" 's team.", client, target);
			PerformSwap(target);			
		}
			
		else
			ReplyToCommand(client, "Target is not on a playable team.");
	}
	else
		ReplyToCommand(client, "Unable to locate target.");

	return Plugin_Handled;
}

void PerformSwap(int client)
{
	int CurrentTeam = GetClientTeam(client);
	int TargetTeam = (CurrentTeam == TEAM_CONSORT ? TEAM_EMPIRE : TEAM_CONSORT);
	PerformTeamChange(client, TargetTeam);	
}

/* Force a player into specate */
//Spec Command
public Action Command_Spec(int client, int args)
{
	if (!ND_HasTeamPickRunAccess(client))
		return Plugin_Handled;
	
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_spec [player name]");
		return Plugin_Handled;
	}

	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));

	int target = FindTarget(0, targetArg);
	if (target != -1)
	{
		if (GetClientTeam(target) > TEAM_SPEC)
		{
			LogAction(client, target, "\"%L\" put \"%L\" in spectate.", client, target);		
			PerformTeamChange(target, TEAM_SPEC);
		}

		else
			ReplyToCommand(client, "Target is not on a playable team.");
	}
	else
		ReplyToCommand(client, "Unable to locate target.");
		
	return Plugin_Handled;
}

public Action Command_SetTeam(int client, int args)
{
	if (!ND_HasTeamPickRunAccess(client))
		return Plugin_Handled;
	
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_setteam <player> <empire/consort/spec>");
		return Plugin_Handled;
	}
	
	char playerArg[50];
	GetCmdArg(1, playerArg, sizeof(playerArg));
	
	int target = FindTarget(0, playerArg);
	
	if (target == -1)
	{
		ReplyToCommand(client, "Invalid player name.");
		return Plugin_Handled;	
	}	
		
	char teamArg[16];
	GetCmdArg(2, teamArg, sizeof(teamArg));
	
	int team;
	
	if (StrContains(teamArg, "emp", false) > -1)
		team = TEAM_EMPIRE;
	else if (StrContains(teamArg, "con", false) > -1)
		team = TEAM_CONSORT;
	else if (StrContains(teamArg, "spec", false) > -1)
		team = TEAM_SPEC;		
	else
	{
		ReplyToCommand(client, "Invalid team name.");
		return Plugin_Handled;	
	}
	
	PerformTeamChange(target, team);		
	return Plugin_Handled;	
}

void PerformTeamChange(int target, int team)
{
	// First change to spectator team to avoid loss of stats points
	ChangeClientTeam(target, TEAM_SPEC);
	
	if (team > TEAM_SPEC)
	{
		ChangeClientTeam(target, team);
		FireOnTeamPlacedForward(target, team);
	}

	else	
		FireOnTeamPlacedForward(target, TEAM_SPEC);
}

void FireOnTeamPlacedForward(int client, int team)
{
	Action dummy;
	Call_StartForward(g_OnTeamPlacedForward);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_Finish(dummy);	
}

public Action CMD_GetID(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pid <Name|#UserID>");
		return Plugin_Handled;
	}
	
	char player[64];
	GetCmdArg(1, player, sizeof(player));
	
	int target = FindTarget(client, player, true, true);
	if (target == -1)
	{
		ReplyToCommand(client, "Invalid player name.");
		return Plugin_Handled;	
	}	
	
	PerformGetID(client, target);
	
	return Plugin_Handled;
}

void PerformGetID(int client, int target)
{
	if (target == -1)
		return;
		
	int pID = GetClientUserId(target);
	
	char pName[64];	
	GetClientName(target, pName, sizeof(pName));
	
	char gAuth[64];	
	GetClientAuthId(target, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	char gIP[64];
	GetClientIP(target, gIP, sizeof(gIP));
		
	PrintToChat(client, "Name: %s\nPID: %d\nSTEAMID: %s\nIP: %s", pName, pID, gAuth, gIP);
}

void RegisterCommands()
{
	RegAdminCmd("sm_pid", CMD_GetID, ADMFLAG_GENERIC, "Checks player ID");
	RegConsoleCmd("sm_swap", Command_Swap, "Swaps the team of targeted player.");
	RegConsoleCmd("sm_forcespec", Command_Spec, "Swaps the targeted player to spectator team.");
	RegConsoleCmd("sm_SetTeam", Command_SetTeam, "Sets the team of a target player");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_PickedTeamsThisMap");
	return APLRes_Success;
}

