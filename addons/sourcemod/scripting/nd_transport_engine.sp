#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_struct_eng>
#include <nd_rounds>

public Plugin myinfo = 
{
	name 		= "[ND] Transport Engine",
	author 		= "Stickz",
	description = "Caches and returns transport gate count",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_transport_engine/nd_transport_engine.txt"
#include "updater/standard.sp"

int gateCount[TEAM_COUNT] = { 0, ... };
bool tgCountRefreshing = false;

public void ND_OnRoundStarted() {
	resetVars();
}

void resetVars()
{
	gateCount[TEAM_CONSORT] = 2;
	gateCount[TEAM_EMPIRE] = 2;
	tgCountRefreshing = false;
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

public Action Event_BuildingDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetInt("type") == view_as<int>(Transport_Gate))
		RefreshTransports();
}
public Action Event_BuildingSold(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetInt("type") == view_as<int>(Transport_Gate))
	{
		// Don't spam this event, if multiple gates are sold at once
		if (!tgCountRefreshing)
			CreateTimer(0.3, TIMER_DelayTgRefresh, _, TIMER_FLAG_NO_MAPCHANGE);
		
		tgCountRefreshing = true;
	}
}
public Action Event_GateCreated(Event event, const char[] name, bool dontBroadcast)
{
	RefreshTransports();
}

public Action TIMER_DelayTgRefresh(Handle timer)
{
	RefreshTransports();
	tgCountRefreshing = false;
	return Plugin_Handled;
}

void RefreshTransports()
{
	int loopEntity = INVALID_ENT_REFERENCE;
	int newGates[TEAM_COUNT] = { 0, ... };
	
	while ((loopEntity = FindEntityByClassname(loopEntity, STRUCT_TRANSPORT)) != INVALID_ENT_REFERENCE)
	{
		int team = GetEntProp(loopEntity, Prop_Send, "m_iTeamNum");
		newGates[team]++;
	}
	
	gateCount[TEAM_CONSORT] = newGates[TEAM_CONSORT];
	gateCount[TEAM_EMPIRE] = newGates[TEAM_EMPIRE];
}

/* Native Management */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetTeamTGCache", Native_GetTeamTGCount);
	return APLRes_Success;
}

public int Native_GetTeamTGCount(Handle plugin, int numParams) {
	// Return the transport gate count for the inputted team
	return gateCount[GetNativeCell(1)];
}