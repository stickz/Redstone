#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_access>
#include <nd_rounds>

#undef REQUIRE_PLUGIN
#include <afk_manager>
#define REQUIRE_PLUGIN

#define INVALID_TARGET -1

public Plugin myinfo =
{
	name = "[ND] Afk Marker",
	author = "Stickz",
	description = "Allows admins to mark players as afk",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_afk_marker/nd_afk_marker.txt"
#include "updater/standard.sp"

bool IsMarkedAfk[MAXPLAYERS+1] = { false, ... };

public void OnPluginStart()
{
	RegConsoleCmd("sm_MarkAFK", CMD_MarkAfterPlayer, "Manually marks as player as afk.");
	
	LoadTranslations("common.phrases");
	
	AddCommandListener(PlayerJoinTeam, "jointeam");	// Listen for when a player joins a team	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnClientPutInServer(int client) {
	IsMarkedAfk[client] = false;
}

public void AFKM_OnClientAFK(int client) {
	CheckAfkStatus(client);
}

public void AFKM_OnClientBack(int client) {
	CheckAfkStatus(client, false);
}

public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	CheckAfkStatus(client);		
	return Plugin_Continue;
}

void CheckAfkStatus(int client, bool rStart = true)
{
	// If the client is currently marked as afk
	if ((!rStart || ND_RoundStarted()) && IsMarkedAfk[client])
	{
		// Set the client's afk status to false
		IsMarkedAfk[client] = false;
		
		// Get the name of player who revoked afk status
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		// Format the message to display about the player
		char message[128];
		Format(message, sizeof(message), "[SM] %s revoked afk status", pName);
		
		// Print the message to all team-pick admins
		PrintToAdmins(message, "t");
	}	
}

public Action CMD_MarkAfterPlayer(int client, int args)
{	
	if (!ND_HasTeamPickAccess(client))
		return Plugin_Handled;
	
	// If no args are inputted, tell how to use the command
	if (!args) 
	{
		ReplyToCommand(client, "[SM] Usage: !MarkAfk <player>");
		return Plugin_Handled;
	}
	
	// Get the player cmd arg and try to target them
	char player[64]
	GetCmdArg(1, player, sizeof(player));	
	int target = FindTarget(0, player);
	
	// If the player we're trying to target is invalid
	if (target == INVALID_TARGET)
	{
		PrintToChat(client, "[SM] Player name segment %s invalid", player);
		return Plugin_Handled;
	}
	
	// Toggle the targets afk status and print message to admin
	ToogleAfkStatus(client, target);
	return Plugin_Handled;	
}

void ToogleAfkStatus(int client, int target)
{
	// Set target player afk status to opposite value
	IsMarkedAfk[target] = !IsMarkedAfk[target];
	
	// Get the name of the target player
	char pName[64];
	GetClientName(target, pName, sizeof(pName));
	
	// Print the target player name and status change to admin
	PrintToChat(client, "[SM] %s has been %s as AFK.",
		pName, IsMarkedAfk[target] ? "marked" : "removed");	
}

/* Naive ND_IsPlayerMarkedAfk() boolean */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsPlayerMarkedAFK", Native_IsPlayerMarkedAfk);
	RegPluginLibrary("afkmanager");
	
	MarkNativeAsOptional("ND_TeamPickMode");
	MarkNativeAsOptional("ND_PauseWarmup");
	
	return APLRes_Success;
}

public int Native_IsPlayerMarkedAfk(Handle plugin, int numParms) {
	// GetNativeCell(1) = client, return if client is marked afk
	return IsMarkedAfk[GetNativeCell(1)];
}
