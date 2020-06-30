#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>

public Plugin myinfo =
{
	name = "[ND] Afk Sweep",
	author = "Stickz",
	description = "Sweeps afk players off teams",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

/* Auto Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_afk_sweep/nd_afk_sweep.txt"
#include "updater/standard.sp"

bool g_PlayerHasSpawned[MAXPLAYERS+1] = { false, ... };

ConVar cvarAfkSweepTime;

public void OnPluginStart()
{
	cvarAfkSweepTime = CreateConVar("sm_afk_sweep_time", "180", "Seconds after round start to move clients that haven't spawned yet to spectator");
	
	AddUpdaterLibrary(); // Add auto updater feature

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void ND_OnRoundStarted()
{
	float SweepTime = cvarAfkSweepTime.FloatValue;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClientEx(client) && GetClientTeam(client) > TEAM_SPEC)
		{
			CreateTimer(SweepTime, TIMER_CheckClientSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
}

public void ND_OnRoundEnded()
{
	ResetSpawnStatus();	
}

void ResetSpawnStatus()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		g_PlayerHasSpawned[client] = false;		
	}	
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));	
	if (IsValidClient(client))
		g_PlayerHasSpawned[client] = true;
	
	return Plugin_Continue;
}

public Action TIMER_CheckClientSpawn(Handle timer, any:Userid)
{
	// Check if the client user id is invalid
	int client = GetClientOfUserId(Userid);	
	if (client == INVALID_USERID)
		return Plugin_Continue;
	
	// Check if the client is invalid (before calling GetClientTeam())
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	// If the player has not spawned and is still on a team, move them to spectator
	if (!g_PlayerHasSpawned[client] && GetClientTeam(client) > TEAM_SPEC)
	{
		ChangeClientTeam(client, TEAM_SPEC);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}