#include <sourcemod>
#include <nd_print>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_com_eng>
#include <nd_swgm>
#include <nd_rstart>

public Plugin myinfo =
{
	name = "[ND] Spectators",
	author = "Stickz",
	description = "Allows a player to lock themselves in spectator",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_spectators/nd_spectators.txt"
#include "updater/standard.sp"

bool g_isLockedToSpec[MAXPLAYERS+1] = { false, ... };
bool g_IsLockedSpecAdmin[MAXPLAYERS+1] = { false, ... };

Handle g_OnPlayerLockedSpecForward;
Handle g_OnPlayerLockedSpecPostForward;

ArrayList g_LockedSteamIdList;

public void OnPluginStart()
{
	RegConsoleCmd("sm_spec", CMD_GoSpec);
	RegConsoleCmd("sm_LockSpec", CMD_LockPlayerSpec);
	
	LoadTranslations("nd_team_balancer.phrases");
	
	g_OnPlayerLockedSpecForward = CreateGlobalForward("ND_OnPlayerLockSpec", ET_Event, Param_Cell, Param_Cell);
	g_OnPlayerLockedSpecPostForward = CreateGlobalForward("ND_OnPlayerLockSpecPost", ET_Ignore, Param_Cell, Param_Cell);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientAuthorized(int client)
{	
	/* retrieve client steam-id and check if client has been demoted */
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (g_LockedSteamIdList.FindString(gAuth) != -1)
		g_IsLockedSpecAdmin[client] = true;	
}

// Remove spectator status when a client connects/disconnects
public void OnClientConnected(int client) {
	g_isLockedToSpec[client] = false;
}
public void OnClientDisconnect(int client) {
	g_isLockedToSpec[client] = false;
}

public void OnMapStart() {
	RemoveSpecLocks();
}

public void OnMapEnd() {
	RemoveSpecLocks();
}

void RemoveSpecLocks() {
	for (int client = 1; client <= MaxClients; client++) {
		g_isLockedToSpec[client] = false;
		g_IsLockedSpecAdmin[client] = false;
	}	
}

public Action CMD_LockPlayerSpec(int client, int args)
{
	if (!CanLockPlayerSpec(client))
		return Plugin_Handled;
	
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_LockSpec <Name|#Userid>");
		return Plugin_Handled;
	}
	
	// Get the player name from the input arg
	char playerName[64]
	GetCmdArg(1, playerName, sizeof(playerName));
	
	// Try to find the client from the playerName string
	int target = FindTarget(client, playerName, true, true);	
	if (target == -1)
	{
		ReplyToCommand(client, "[SM] Player not found by name segment %s", playerName);
		return Plugin_Handled;
	}
	
	// Get the players steam id. Check ArrayList to see if it's found
	char gAuth[32];
	GetClientAuthId(target, AuthId_Steam2, gAuth, sizeof(gAuth));
	int found = g_LockedSteamIdList.FindString(gAuth);
	
	if (g_IsLockedSpecAdmin[client])
	{
		// Unlock player from spec and remove entry from steamid list
		g_IsLockedSpecAdmin[client] = false;		
		if (found != -1)
			g_LockedSteamIdList.Erase(found);
		
		ReplyToCommand(client, "[SM] Player succesfully unlocked from spectator");
	}
	
	else
	{
		// Lock player in spec and add entry to steamid list
		g_IsLockedSpecAdmin[client] = true;
		if (found == -1)
			g_LockedSteamIdList.PushString(gAuth);			
			
		ReplyToCommand(client, "[SM] Player succesfully locked into spectator");
	}
	
	
	return Plugin_Handled;
}

bool CanLockPlayerSpec(int client)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return false;
	}

 	if (!HasTeamPickAccess(client))
	{
		ReplyToCommand(client, "[SM] You only have team-pick access to this command!");
		return false;
	}

 	return true;
}

/* Place yourself in spectator mode */
public Action CMD_GoSpec(int client, int args)
{
	if (!ND_RoundStarted())
	{
		PrintMessage(client, "TP Spectator");
		return Plugin_Handled;	
	}
	
	else if (ND_IsCommander(client)) //Fix switching team while commander bug
	{
		PrintMessage(client, "Resign Switch");
		return Plugin_Handled;
	}

	if (g_isLockedToSpec[client])
	{
		g_isLockedToSpec[client] = false;
		PrintMessage(client, "Spectator Unlocked");
	}
	
	else
	{
		int team = GetClientTeam(client);
		
		// Call forward before player is about to be locked spec
		// Allow the action to be blocked, by anther plugin		
		Action lockSpec;
		Call_StartForward(g_OnPlayerLockedSpecForward);
		Call_PushCell(client);
		Call_PushCell(team);
		Call_Finish(lockSpec);
		
		if (lockSpec == Plugin_Handled)
			return Plugin_Handled;
			
		// Put the player in spec and print a message
		g_isLockedToSpec[client] = true;
		ChangeClientTeam(client, TEAM_SPEC);
		PrintMessage(client, "Spectator Joined");
		
		// Call forward after the player has been locked spec
		FirePostLockSpecForward(client, team);
	}
	
	return Plugin_Handled;
}

void FirePostLockSpecForward(int client, int team)
{
	Action dummy;
	Call_StartForward(g_OnPlayerLockedSpecPostForward);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_Finish(dummy);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{	
	CreateNative("ND_PlayerSpecLocked", Native_GetPlayerSpecLock);
	CreateNative("ND_AdminSpecLocked", Native_GetAdminSpecLock);	
	return APLRes_Success;
}

public int Native_GetPlayerSpecLock(Handle plugin, int numParms) {
	return _:g_isLockedToSpec[GetNativeCell(1)];
}

public int Native_GetAdminSpecLock(Handle plugin, int numParms) {
	return _:g_IsLockedSpecAdmin[GetNativeCell(1)];
}
