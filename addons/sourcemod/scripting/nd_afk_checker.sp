#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>

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
	
	g_AFKSteamIdList = new ArrayList(128);
}

public void OnClientAuthorized(int client)
{	
	/* retrieve client steam-id and check if client is set afk */
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	bool WasClientAFK = g_AFKSteamIdList.FindString(gAuth) != -1;
	IsCheckedAfk[client] = WasClientAFK;
}

public void AFKM_OnClientAFK(int client) {
	SetAfkStatus(client, true);
}

public void AFKM_OnClientBack(int client) {
	SetAfkStatus(client, false);
}

public void OnClientDisconnect_Post(int client)
{
	if (ND_RoundStarted())
		SetAfkStatus(client, false);
}

public Action PlayerJoinTeam(int client, char[] command, int argc) 
{
	SetAfkStatus(client, false);
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
