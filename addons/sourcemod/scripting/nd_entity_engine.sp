#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_structures>

#define CHECK_ALL -1

public Plugin myinfo =
{
	name = "[ND] Entity Engine",
	author = "Stickz",
	description = "Caches entities indexes",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_entity_engine/nd_entity_engine.txt"
#include "updater/standard.sp"

int g_iPlayerManager = -1;
int g_iTeamEntities[2] = {-1, ...};
int g_iBunkerEntities[2] = {-1, ...};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	/* Update the entity caches each time the map starts */
	SetBunkerEntityIndexs();
	g_iPlayerManager = FindEntityByClassname(CHECK_ALL, "nd_player_manager");
	g_iTeamEntities[TEAM_EMPIRE-2] = FindEntityByClassname(CHECK_ALL, "nd_team_empire");
	g_iTeamEntities[TEAM_CONSORT-2] = FindEntityByClassname(CHECK_ALL, "nd_team_consortium");
}

public void OnMapEnd() {
	ExpireRoundCache();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	// Only set bunker entities if not previously availible
	if (g_iBunkerEntities[0] == -1 || g_iBunkerEntities[1] == -1)
		SetBunkerEntityIndexs();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	ExpireRoundCache();
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	/* Create natives to retrieve the entity caches */
	CreateNative("ND_GetTeamEntity", Native_GetTeamManager);
	CreateNative("ND_GetTeamBunkerEntity", Native_GetTeamBunker);
	CreateNative("ND_GetPlayerManagerEntity", Native_GetPlayerManager);

	return APLRes_Success;
}

public int Native_GetPlayerManager(Handle plugin, int numParams) {
	return _:g_iPlayerManager;
}

public int Native_GetTeamManager(Handle plugin, int numParams)
{
	// Retrieve the team parameter
	int team = GetNativeCell(1);

	// Throw an error if the team is invalid
	if (IsTeamInvalid(team))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid team index (%d)", team);	

	// Otherwise, return the team entity index
	return _:g_iTeamEntities[team-2];
}

public int Native_GetTeamBunker(Handle plugin, int numParams) 
{
	// Retrieve the team parameter
	int team = GetNativeCell(1);

	// Throw an error if the team is invalid
	if (IsTeamInvalid(team))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid team index (%d)", team);	

	// Otherwise, return the bunker entity index
	return _:g_iBunkerEntities[team-2];
}

bool IsTeamInvalid(int team) {
	return team != TEAM_EMPIRE || team != TEAM_CONSORT;	
}

void SetBunkerEntityIndexs()
{
	// Loop through all entities finding the bunkers
	int loopEntity = INVALID_ENT_REFERENCE;	int team;
	while ((loopEntity = FindEntityByClassname(loopEntity, STRUCT_BUNKER)) != INVALID_ENT_REFERENCE)
	{
		// Cache the bunker entities when found
		team = GetEntProp(loopEntity, Prop_Send, "m_iTeamNum") - 2;
		g_iBunkerEntities[team] = loopEntity;
	}
}

void ExpireRoundCache()
{
	g_iBunkerEntities[0] = -1;
	g_iBunkerEntities[1] = -1;
}