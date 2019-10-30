#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Engine",
	author 		= "Stickz",
	description = "Creates forwards and natives for resources",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_engine/nd_resource_engine.txt"
#include "updater/standard.sp"

Handle OnPrimeResDepleted;
Handle OnResPointsCached;
bool bPrimeDepleted = false;
bool roundStarted = false;
int PrimeEntity = -1;

ArrayList listSecondaries;
ArrayList listTertiaries;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	/* Initialize corner varriables */
	listSecondaries = new ArrayList(6);
	listTertiaries = new ArrayList(18);
	
	OnPrimeResDepleted = CreateGlobalForward("ND_OnPrimeDepleted", ET_Ignore, Param_Cell);
	OnResPointsCached = CreateGlobalForward("ND_OnResPointsCached", ET_Ignore);
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnMapStart() 
{
	/* Initialize varriables */
	listSecondaries.Clear();
	listTertiaries.Clear();	
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(30.0, TIMER_CheckPrimeDepleted, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	bPrimeDepleted = false;
	roundStarted = true;
	
	// Store entity index of all secondaries and tertaries on the map
	CreateTimer(5.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);	
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	roundStarted = false;
}

public Action TIMER_SetEntityClasses(Handle timer)
{
	// Cache the prime entity and all the secondaries and tertaries
	PrimeEntity = FindEntityByClassname(-1, "nd_info_primary_resource_point");
	SetSecondariesList();
	SetTertariesList();
	
	// Fire the cache complete forward to signal the info is ready for access
	Action dummy;
	Call_StartForward(OnResPointsCached);
	Call_Finish(dummy);	
	
	return Plugin_Continue;
}

public Action TIMER_CheckPrimeDepleted(Handle timer)
{
	// Stop the timer, if the round is not started
	if (!roundStarted)
		return Plugin_Stop;
	
	// Get the current resources prime has left
	int curRes = GetEntProp(PrimeEntity, Prop_Send, "m_iCurrentResources");
	if (curRes <= 0)
	{				
		// When depleted... Fire forward, mark boolean and stop timer
		bPrimeDepleted = true;
		FirePrimeDepletedForward();
		return Plugin_Stop;
	}	
	
	return Plugin_Continue;
}

void FirePrimeDepletedForward()
{
	Action dummy;
	Call_StartForward(OnPrimeResDepleted);
	Call_PushCell(PrimeEntity);
	Call_Finish(dummy);
}

void SetSecondariesList()
{
	// Loop through all entities finding the secondaries
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "nd_info_secondary_resource_point")) != INVALID_ENT_REFERENCE)
	{
		// Cache the secondary entity index when found
		listSecondaries.Push(loopEntity);
	}
}
void SetTertariesList()
{
	// Loop through all entities finding the tertaries
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "nd_info_tertiary_resource_point")) != INVALID_ENT_REFERENCE)
	{
		// Cache the tertary entity index when found
		listTertiaries.Push(loopEntity);
	}
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsPrimeDepleted", Native_PrimeDepleted);	
	CreateNative("ND_GetPrimaryPoint", Native_GetPrimePoint);
	CreateNative("ND_GetSecondaryList", Native_GetSecList);
	CreateNative("ND_GetTertiaryList", Native_GetTertList);
	return APLRes_Success;
}

public int Native_PrimeDepleted(Handle plugin, int numParams) {
	return _:bPrimeDepleted;
}

public int Native_GetPrimePoint(Handle plugin, int numParms) {
	return PrimeEntity;
}

public int Native_GetSecList(Handle plugin, int numParams) {
	return view_as<int>(CloneHandle(listSecondaries, plugin));
}

public int Native_GetTertList(Handle plugin, int numParams) {
	return view_as<int>(CloneHandle(listTertiaries, plugin));
}
