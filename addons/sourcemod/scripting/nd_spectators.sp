#include <sourcemod>
#include <nd_print>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_com_eng>

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

Handle g_OnPlayerLockedSpecForward;
Handle g_OnPlayerLockedSpecPostForward;

public void OnPluginStart()
{
	RegConsoleCmd("sm_spec", CMD_GoSpec);
	LoadTranslations("nd_team_balancer.phrases");
	
	g_OnPlayerLockedSpecForward = CreateGlobalForward("ND_OnPlayerLockSpec", ET_Event, Param_Cell, Param_Cell);
	g_OnPlayerLockedSpecPostForward = CreateGlobalForward("ND_OnPlayerLockSpecPost", ET_Ignore, Param_Cell, Param_Cell);
	
	AddUpdaterLibrary(); //auto-updater
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
	}	
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

	if (!g_isLockedToSpec[client])
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
		g_isLockedToSpec[client] = truel
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
	return APLRes_Success;
}

public int Native_GetPlayerSpecLock(Handle plugin, int numParms) {
	return _:g_isLockedToSpec[GetNativeCell(1)];
}
