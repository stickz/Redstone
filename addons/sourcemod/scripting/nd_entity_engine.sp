#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_structures>

#define CHECK_ALL -1
#define NATIVE_ERROR -1
#define PRIME_ENTITY "nd_info_primary_resource_point"

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
int g_iPrimeEntity = -1;
int g_iBunkerEntities[2] = {-1, ...};

bool UpdatingEntityCache = true;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() 
{
	UpdatingEntityCache = true;
	CreateTimer(5.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd() {
	ExpireRoundCache();
}

public Action TIMER_SetEntityClasses(Handle timer)
{
	/* Update team and player manager entities when the map starts */
	g_iPlayerManager = FindEntityByClassname(CHECK_ALL, "nd_player_manager");
	g_iPrimeEntity = FindEntityByClassname(CHECK_ALL, PRIME_ENTITY);
	
	// Update bunker entity indexs when the map starts
	SetBunkerEntityIndexs();
	
	// Mark the boolean has updated
	UpdatingEntityCache = false;
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{	
	UpdatingEntityCache = true;
	CreateTimer(1.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	ExpireRoundCache();
	return Plugin_Continue;
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	/* Create natives to retrieve the entity caches */
	CreateNative("ND_GetPrimeEntity", Native_GetPrimeEntity);
	CreateNative("ND_GetTeamBunkerEntity", Native_GetTeamBunker);
	CreateNative("ND_GetPlayerManagerEntity", Native_GetPlayerManager);
	
	CreateNative("ND_UpdateEntityCache", Native_UpdateEntityCache);

	return APLRes_Success;
}

public int Native_GetPrimeEntity(Handle plugin, int numParams) 
{
	// Get the current name of the prime entity index
	char entityName[32];
	if (g_iPrimeEntity != -1)
		GetEntityClassname(g_iPrimeEntity, entityName, sizeof(entityName)); 
	
	// If it's not equal the prime entity, refresh it
	if (!StrEqual(entityName, PRIME_ENTITY, true))
		g_iPrimeEntity = FindEntityByClassname(CHECK_ALL, PRIME_ENTITY);	
	
	return _:g_iPrimeEntity;
}

public int Native_GetPlayerManager(Handle plugin, int numParams) {
	return _:g_iPlayerManager;
}

public int Native_GetTeamBunker(Handle plugin, int numParams) 
{
	// Retrieve the team parameter
	int team = GetNativeCell(1);

	// Log an error and return -1 if the team is invalid
	if (IsTeamInvalid(team))
	{
		LogError("Invalid team index (%d) for native GetTeamBunkerEntity()", team);
		return NATIVE_ERROR;
	}

	// Otherwise, return the bunker entity index
	return _:g_iBunkerEntities[team-2];
}

public int Native_UpdateEntityCache(Handle plugin, int numParams) 
{
	if (!UpdatingEntityCache)
	{
		UpdatingEntityCache = true;
		CreateTimer(1.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return 0;
}

bool IsTeamInvalid(int team) {
	return team != TEAM_EMPIRE && team != TEAM_CONSORT;	
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
