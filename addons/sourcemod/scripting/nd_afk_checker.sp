#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_afk_sweep>

#undef REQUIRE_PLUGIN
#include <afk_manager>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name = "[ND] Afk Checker",
	author = "Stickz",
	description = "Remembers if the client is afk for team balance",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_afk_checker/nd_afk_checker.txt"
#include "updater/standard.sp"

bool IsCheckedAfk[MAXPLAYERS+1] = { false, ... };
ArrayList g_AFKSteamIdList;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	AddCommandListener(PlayerJoinTeam, "jointeam");	// Listen for when a player joins a team
	AddUpdaterLibrary(); // Add auto updater feature
	
	RegConsoleCmd("sm_DumpAFKs", CMD_DumpAFKs);
	
	g_AFKSteamIdList = new ArrayList(128);
}

public Action CMD_DumpAFKs(int client, int args)
{
	if (g_AFKSteamIdList.Length == 0)
		PrintToChat(client, "No afk players to show");
	else
	{
		PrintToChat(client, "See output in console.");
		dumpAfkPlayers(client);
	}
	
	return Plugin_Handled;
}

void dumpAfkPlayers(int player)
{
	PrintSpacer(player); PrintSpacer(player);
	PrintToConsole(player, "--> Player AFK SteamIDs <--");
	PrintSpacer(player);	
	
	for (int idx = 0; idx < g_AFKSteamIdList.Length; idx++)
	{
		char gAuth[32];
		g_AFKSteamIdList.GetString(idx, gAuth, sizeof(gAuth));		
		PrintToConsole(player, "Player #%d: %s", idx+1, gAuth);	
		PrintSpacer(player);
	}
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}

public void ND_OnRoundStarted()
{
	// If the AFK steamid list is empty, exit
	if (g_AFKSteamIdList.Length == 0)
		return;
	
	// Store the steam id's of all connected clients to a temporary array list
	ArrayList g_ClientSteamIdList = new ArrayList(MaxClients+1);	
	for (int client = 1; client <= MaxClients; client++)
	{			
		if (IsValidClientEx(client))
		{
			// Get the player's steam id.
			char gAuth[32];
			GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));		
			g_ClientSteamIdList.PushString(gAuth);
		}
	}
	
	// Delete the steam id's all clients currently not connected from the afk array list
	for (int id = g_AFKSteamIdList.Length - 1; id >= 0; id--)
	{
		char gAuth[32];
		g_AFKSteamIdList.GetString(id, gAuth, sizeof(gAuth));
		
		if (g_ClientSteamIdList.FindString(gAuth) == -1)
			g_AFKSteamIdList.Erase(id);
	}
	
	// Delete the temporary array list when complete
	delete g_ClientSteamIdList;
}

public void OnClientAuthorized(int client)
{	
	/* retrieve client steam-id and check if client is set afk */
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	bool WasClientAFK = g_AFKSteamIdList.FindString(gAuth) != -1;
	IsCheckedAfk[client] = WasClientAFK;
}

public Action AFKM_OnAFKEvent(const char[] name, int client)
{
	// If the event is afk kick, we don't need to log it, just continue
	if (StrEqual(name, "afk_kick", false))
		return Plugin_Continue;
	
	SetAfkStatus(client, true);	
	return Plugin_Continue;
}

public void ND_OnPlayerAfkSweep(int client) {
	SetAfkStatus(client, true);	
}

public void OnClientDisconnect(int client)
{
	if (ND_RoundStarted())
		SetAfkStatus(client, false);
}

public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	CreateTimer(0.5, TIMER_CheckPlayerJoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	
	return Plugin_Continue;
}

public Action TIMER_CheckPlayerJoinTeam(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client != INVALID_USERID)
	{
		if (IsValidClient(client) && GetClientTeam(client) != TEAM_UNASSIGNED)
		{
			SetAfkStatus(client, false);
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;	
}

void SetAfkStatus(int client, bool state)
{
	// Get the player's steam id.
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	int found = g_AFKSteamIdList.FindString(gAuth);
	
	if (state && found == -1)
		g_AFKSteamIdList.PushString(gAuth);
		
	else if (!state && found != -1)
		g_AFKSteamIdList.Erase(found);
	
	IsCheckedAfk[client] = state;
}

/* Naive ND_IsPlayerCheckedAfk() boolean */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsPlayerCheckedAFK", Native_IsPlayerCheckedAfk);
	RegPluginLibrary("afkmanager");	
	return APLRes_Success;
}

public int Native_IsPlayerCheckedAfk(Handle plugin, int numParms) {
	// GetNativeCell(1) = client, return if client is marked afk
	return IsCheckedAfk[GetNativeCell(1)];
}
