#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_struct_eng>
#include <nd_rounds>

public Plugin myinfo = 
{
	name 		= "[ND] Transport Engine",
	author 		= "Stickz",
	description 	= "Caches and returns transport gate count",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_transport_engine/nd_transport_engine.txt"
#include "updater/standard.sp"

int gateCount[TEAM_COUNT] = { 0, ... };
float gateVecs[2][3];

public void ND_OnRoundStarted() {
	resetVars();
	RefreshTransports();
}

void resetVars()
{
	gateCount[TEAM_CONSORT] = 2;
	gateCount[TEAM_EMPIRE] = 2;
}

/* Event Management */
public void OnPluginStart() 
{
	HookEvent("structure_death", Event_BuildingDeath);
	HookEvent("structure_sold", Event_BuildingSold);
	HookEvent("transport_gate_created", Event_GateCreated);	
	
	if (ND_RoundStarted())
	{
		resetVars();
		RefreshTransports();
	}
	
	AddUpdaterLibrary();
}

public Action Event_BuildingDeath(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetInt("type") == view_as<int>(Transport_Gate)) {
		gateCount[event.GetInt("team")]--;
	}
}
public Action Event_BuildingSold(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetInt("type") == view_as<int>(Transport_Gate)) {
		gateCount[event.GetInt("ownerteam")]--;
	}
}
public Action Event_GateCreated(Event event, const char[] name, bool dontBroadcast) {
	gateCount[event.GetInt("teamid")]++;
}

void RefreshTransports()
{
	int loopEntity = INVALID_ENT_REFERENCE;
	int newGates[TEAM_COUNT] = { 0, ... };
	
	while ((loopEntity = FindEntityByClassname(loopEntity, STRUCT_TRANSPORT)) != INVALID_ENT_REFERENCE)
	{
		int team = GetEntProp(loopEntity, Prop_Send, "m_iTeamNum");
		GetEntPropVector(loopEntity, Prop_Send, "m_vecOrigin", gateVecs[team-2]);		
		newGates[team]++;
	}
	
	gateCount[TEAM_CONSORT] = newGates[TEAM_CONSORT];
	gateCount[TEAM_EMPIRE] = newGates[TEAM_EMPIRE];
}

/* Native Management */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetTeamTGCache", Native_GetTeamTGCount);
	CreateNative("ND_RefreshSpawnLocs", Native_RefreshSpawnLocs);
	CreateNative("ND_ForceSpawnPlayer", Native_ForceSpawnPlayer);
	return APLRes_Success;
}

public int Native_GetTeamTGCount(Handle plugin, int numParams) {
	// Return the transport gate count for the inputted team
	return gateCount[GetNativeCell(1)];
}

public int Native_RefreshSpawnLocs(Handle plugin, int numParams) {
	RefreshTransports();
}

public int Native_ForceSpawnPlayer(Handle plugin, int numParams)
{
	float delay = GetNativeCell(1);
	CreateTimer(delay, ForceSpawn, GetClientUserId(GetNativeCell(1)), TIMER_FLAG_NO_MAPCHANGE);
}

public Action ForceSpawn(Handle timer, any:Userid)
{
	int client = GetClientOfUserId(Userid);	
	if (client && IsClientInGame(client))
	{
		ForcePlayerSpawn(client);
		return Plugin_Handled;
	}	
	
	//CreateTimer(0.5, ForceSpawn, Userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

void ForcePlayerSpawn(int client) 
{
	int team = GetClientTeam(client);
	if (team > 1) 
	{
		// Set the location of the spawn area from the cached vector coordinates
		SetEntPropVector(client, Prop_Send, "m_vecSelectedSpawnArea", gateVecs[team-2]);
		
		// Set the player class to a random value, if they're not a bot
		if (!IsFakeClient(client)		
			FakeClientCommand(client, "joinclass %d 0", GetRandomInt(0,3));
			
		// Indicate ready to play, to force the spawn spawn to happen
		FakeClientCommand(client, "readytoplay");	
	}
}
