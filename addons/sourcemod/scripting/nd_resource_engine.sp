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

#include "nd_res_trickle/constants.sp"

#define TERTIARY_MODEL "models/rts_structures/rts_resource/rts_resource_tertiary.mdl"
#define VECTOR_SIZE 3

#define CAPTURE_RADIUS 200.0
#define nCAPTURE_RADIUS -200.0

Handle OnPrimeResDepleted;
Handle OnResPointsCached;
Handle OnTertiarySpawned;

bool bPrimeDepleted = false;
bool roundStarted = false;
bool resPointsCached = false;

int PrimeEntity = -1;
int resSpawnCount = 0;

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
	OnTertiarySpawned = CreateGlobalForward("ND_OnTertairySpawned", ET_Ignore, Param_Cell, Param_Cell);
	
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
	
	/* Initialize varriables */
	bPrimeDepleted = false;
	resPointsCached = false;
	roundStarted = true;
	resSpawnCount = 0;
	listSecondaries.Clear();
	listTertiaries.Clear();	
	
	// Store entity index of all secondaries and tertaries on the map
	CreateTimer(5.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	roundStarted = false;
	return Plugin_Continue;
}

public Action TIMER_SetEntityClasses(Handle timer)
{
	/* Initialize varriables */
	listSecondaries.Clear();
	listTertiaries.Clear();	
	
	// Cache the prime entity and all the secondaries and tertaries
	PrimeEntity = FindEntityByClassname(-1, "nd_info_primary_resource_point");
	SetSecondariesList();
	SetTertariesList();
	
	// Fire the cache complete forward to signal the info is ready for access
	Action dummy;
	Call_StartForward(OnResPointsCached);
	Call_Finish(dummy);
	resPointsCached = true;	
	
	return Plugin_Continue;
}

public Action TIMER_CheckPrimeDepleted(Handle timer)
{
	// Stop the timer, if the round is not started
	if (!roundStarted)
		return Plugin_Stop;
	
	if (PrimeEntity == -1)
		return Plugin_Continue;
	
	// Get the current resources prime has left
	int curRes = GetEntProp(PrimeEntity, Prop_Send, "m_iCurrentResources");
	if (curRes <= PRIMARY_FRACKING_LEFT)
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

public void SpawnTertiaryPoint(float origin[VECTOR_SIZE])
{
	int rt = CreateEntityByName("nd_info_tertiary_resource_point");
	int trigger = CreateEntityByName("nd_trigger_resource_point");
	
	SpawnResourcePoint("tertiary", TERTIARY_MODEL, rt, trigger, origin);
	
}

public void SpawnResourcePoint( const char[] type, const char[] model, int rt, int trigger, float origin[VECTOR_SIZE])
{	
	char rt_name[32];
	char trigger_name[32];

	Format(rt_name, sizeof(rt_name), "%s-%i", type, resSpawnCount);
	Format(trigger_name, sizeof(trigger_name), "%s-%i-area", type, resSpawnCount);
		
	DispatchSpawn(rt);
	DispatchSpawn(trigger);
       
	ActivateEntity(rt);
	ActivateEntity(trigger);
       
	SetEntPropString(rt, Prop_Data, "m_iName", rt_name);
	SetEntPropString(trigger, Prop_Data, "m_iName", trigger_name);
       
	SetEntPropString(trigger, Prop_Data, "m_iszResourcePointName", rt_name);
	SetEntPropFloat(trigger, Prop_Data, "m_flCapTime", 5.0);
	SetEntProp(trigger, Prop_Data, "m_iButtonsToCap", 0);
	SetEntProp(trigger, Prop_Data, "m_iNumPlayersToCap", 1);
	
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	
	// Deplete tertiary resources if prime is depleted on spawn
	if (bPrimeDepleted)
		SetEntProp(rt, Prop_Send, "m_iCurrentResources", 0);
 
	SetEntityModel(rt, TERTIARY_MODEL);
	SetEntityModel(trigger, TERTIARY_MODEL); //will throw warning in game console; required and no model displayed for brush entity
       
	TeleportEntity(rt, origin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(trigger, origin, NULL_VECTOR, NULL_VECTOR);
       
	float min_bounds[VECTOR_SIZE] = {nCAPTURE_RADIUS, nCAPTURE_RADIUS, nCAPTURE_RADIUS};
	float max_bounds[VECTOR_SIZE] = {CAPTURE_RADIUS, CAPTURE_RADIUS, CAPTURE_RADIUS};
	
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", min_bounds);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", max_bounds);
	
	resSpawnCount++;
	
	// Update the tertiary list with the new tertiary spawned
	listTertiaries.Push(rt);
	
	// Fire the resource spawn forward
	Action dummy;
	Call_StartForward(OnTertiarySpawned);
	Call_PushCell(rt);
	Call_PushCell(trigger);
	Call_Finish(dummy);
}

public void RemoveTertiaryPoint(const char[] rtName, const char[] trigName)
{
	int entity = LookupEntity("nd_info_tertiary_resource_point", rtName, -1);	
	if (entity > -1) AcceptEntityInput(entity, "Kill");	
	
	entity = LookupEntity("nd_trigger_resource_point", trigName, -1);
	if (entity > -1) AcceptEntityInput(entity, "Kill");
}

//Recursivly lookup entities by classname until we find the matching name
public int LookupEntity(const char[] classname, const char[] lookup_name, int start_point)
{
	int entity = FindEntityByClassname(start_point, classname);
	
	if (entity > -1)
	{
		char entity_name[32];
		GetEntPropString(entity, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
		return StrEqual(entity_name, lookup_name) ? entity : LookupEntity(classname, lookup_name, entity);
	}
	
	return -1;
}

/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsPrimeDepleted", Native_PrimeDepleted);	
	CreateNative("ND_ResPointsCached", Native_ResPointsCached);
	
	CreateNative("ND_GetPrimaryPoint", Native_GetPrimePoint);
	CreateNative("ND_GetSecondaryList", Native_GetSecList);
	CreateNative("ND_GetTertiaryList", Native_GetTertList);
	
	CreateNative("ND_SpawnTertiaryPoint", Native_SpawnTertiaryPoint);
	CreateNative("ND_RemoveTertiaryPoint", Native_RemoveTertiaryPoint);
	
	return APLRes_Success;
}

public int Native_PrimeDepleted(Handle plugin, int numParams) {
	return _:bPrimeDepleted;
}

public int Native_ResPointsCached(Handle plugin, int numParams) {
	return _:resPointsCached;
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

public int Native_SpawnTertiaryPoint(Handle plugin, int numParams) 
{
	// Get the location to spawn the tertiary
	float origin[VECTOR_SIZE];
	GetNativeArray(1, origin, VECTOR_SIZE);
	
	// Spawn the tertiary resource point
	SpawnTertiaryPoint(origin);
	return 0;
}

public int Native_RemoveTertiaryPoint(Handle plugin, int numParams)
{
	// Get the tertiary name to remove
	char rtName[32];
	GetNativeString(1, rtName, sizeof(rtName));
	
	// Get the trigger name to remove
	char trigName[32];
	GetNativeString(2, trigName, sizeof(trigName));
	
	// Remove the tertiary resource point
	RemoveTertiaryPoint(rtName, trigName);
	return 0;
}
