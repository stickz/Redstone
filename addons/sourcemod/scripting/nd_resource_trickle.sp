#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_entities>
#include <nd_resources>
#include <nd_resource_eng>
#include <smlib/math>
#include <nd_maps>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Trickle",
	author 		= "Stickz",
	description 	= "Adjusts tertaries to have team trickle amounts",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_trickle/nd_resource_trickle.txt"
#include "updater/standard.sp"

#define PRIMARY_TEAM_TRICKLE 40000 // Reserved pool of resources for each team
#define PRIMARY_TRICKLE_SET 40000 // Initial pool of resources, first come, first serve

#define TERTIARY_TEAM_TRICKLE 8000 // Reserved pool of resources for each team
#define TERTIARY_TRICKLE_SET 8000 // Initial pool of resources, first come, first serve
#define TERTIARY_TRICKLE_REGEN_INTERVAL 15 // Amount to regenerate every five seconds
#define TERTIARY_TRICKLE_REGEN_AMOUNT 1800 // Maximum amount to regen on opposite team's pool
#define TERTIARY_TRICKLE_DEGEN_INTERVAL 25 // Amount to degenerate every five seconds
#define TERTIARY_TRICKLE_DEGEN_MINUTES 9 // Minutes to degenerate if team hasn't owned tertiary

#define SECONDARY_TRICKLE_REGEN_AMOUNT 4140 // Maximum amount to regen on opposite team's pool
#define SECONDARY_TRICKLE_REGEN_INTERVAL 69 // Amount to regen every ten seconds

#define RESOURCE_NOT_TERTIARY 	-1
#define RESPOINT_NOT_FOUND		-1

ArrayList listTertiaries;
ArrayList structTertaries;

ArrayList listSecondaries;
ArrayList structSecondaries;

ArrayList structPrimary;

Handle tertiaryTimer[19] = { INVALID_HANDLE, ... };
Handle secondaryTimer[4] = { INVALID_HANDLE, ... };
Handle primaryTimer = INVALID_HANDLE;
int PrimeEntity = -1;

bool cornerMap = false;

// Include the teritary structure and natives
#include "nd_res_trickle/resource.sp"
#include "nd_res_trickle/natives.sp"

int Tertiary_FindArrayIndex(int entity) {
	return structTertaries.FindValue(entity, ResPoint::entIndex);	
}

int Secondary_FindArrayIndex(int entity) {
	return structSecondaries.FindValue(entity, ResPoint::entIndex);
}

public void OnPluginStart()
{
	listTertiaries = new ArrayList(18);
	structTertaries = new ArrayList(sizeof(ResPoint));
	
	listSecondaries = new ArrayList(6);
	structSecondaries = new ArrayList(sizeof(ResPoint));
	
	structPrimary = new ArrayList(sizeof(ResPoint));
	
	HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);
	
	AddUpdaterLibrary(); // Add auto updater feature
	
	// Add late loading support to resource trickle
	if (ND_RoundStarted() && ND_ResPointsCached())
		ND_OnResPointsCached();
}

public void OnMapStart() {
	cornerMap = ND_CurrentMapIsCorner();
}

public void ND_OnRoundStarted()
{
	/* Initialize varriables */
	listTertiaries.Clear();
	structTertaries.Clear();
	listSecondaries.Clear();
	structSecondaries.Clear();
}

public void ND_OnResPointsCached()
{
	// Get the list of tertaries from the resource engine
	listTertiaries = ND_GetTertiaryList();
	listSecondaries = ND_GetSecondaryList();
	PrimeEntity = ND_GetPrimaryPoint();
	
	// Set the current trickle amount to 7000 resources for all the tertaries
	CreateTimer(3.0, TIMER_SetResPointStructs, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnTertairySpawned(int entity, int trigger)
{
	// Add tertiary to the list of tertaries
	// Create a new tertiary struct for trickling
	int index = listTertiaries.Push(entity);
	initNewTertiary(index, entity, false);
}

public Action TIMER_SetResPointStructs(Handle timer)
{	
	/* Set tertiary resources and initilize teritary structure */
	for (int t = 0; t < listTertiaries.Length; t++) 
	{
		int tert = listTertiaries.Get(t);
		ND_SetCurrentResources(tert, TERTIARY_TRICKLE_SET + TERTIARY_TEAM_TRICKLE);
	}	
	initTertairyStructs();
	
	// If the map is corner, set prime trickling
	if (cornerMap)
	{
		/* Set primary resources and initilize primary structure */
		ND_SetCurrentResources(PrimeEntity, PRIMARY_TRICKLE_SET + PRIMARY_TEAM_TRICKLE);
		initNewPrimary(PrimeEntity);		
	}
	else // Otherwise, initalize the secondary structures for trickle regen
		initSecondaryStructs();

	return Plugin_Continue;
}

void initTertairyStructs()
{
	for (int t = 0; t < listTertiaries.Length; t++)
		initNewTertiary(t, listTertiaries.Get(t), true);
}

void initSecondaryStructs()
{
	for (int s = 0; s < listSecondaries.Length; s++)
		initNewSecondary(s, listSecondaries.Get(s));	
}

void initNewTertiary(int arrIndex, int entIndex, bool fullRes)
{
	// Create and initialize new tertiary object
	ResPoint tert;
	tert.arrayIndex = arrIndex;
	tert.entIndex = entIndex;
	tert.owner = TEAM_SPEC;
	tert.type = RESOURCE_TERTIARY;
	tert.timeOwned = 0;

	// Should we init the teritary with full resources?
	if (fullRes)
	{
		tert.initialRes = TERTIARY_TRICKLE_SET;
		tert.empireRes = TERTIARY_TEAM_TRICKLE;
		tert.consortRes = TERTIARY_TEAM_TRICKLE;
	}
	else
	{
		int average = GetAverageSpawnRes();
		tert.initialRes = average;
		tert.empireRes = average;
		tert.consortRes = average;
	}	
	
	// Push the teritary object into the struct list
	structTertaries.PushArray(tert);	
}

void initNewSecondary(int arrIndex, int entIndex)
{
	// Create and initalize new secondary object
	ResPoint sec;
	sec.arrayIndex = arrIndex;
	sec.entIndex = entIndex;
	sec.owner = TEAM_SPEC;
	sec.type = RESOURCE_SECONDARY;
	sec.timeOwned = 0;
	
	// Don't enable team resource feature for secondaries
	sec.initialRes = RES_SECONDARY_START;
	sec.empireRes = 0;
	sec.consortRes = 0;
	
	structSecondaries.PushArray(sec);	
}

void initNewPrimary(int entIndex)
{
	ResPoint prime;
	prime.arrayIndex = 0;
	prime.entIndex = entIndex;
	prime.owner = TEAM_SPEC;
	prime.type = RESOURCE_PRIME;	
	prime.initialRes = PRIMARY_TRICKLE_SET;
	prime.empireRes = PRIMARY_TEAM_TRICKLE;
	prime.consortRes = PRIMARY_TEAM_TRICKLE;
	prime.timeOwned = 0;
	
	// Push the primary object into the struct list
	structPrimary.PushArray(prime);
}

int GetAverageSpawnRes()
{
	// Calculate the total amount of initial resoruces in all the tertaries
	int totalRes = 0;
	for (int i = 0; i < structTertaries.Length; i++)
	{
		// Get the tertiary structure
		ResPoint tert;
		structTertaries.GetArray(i, tert);
		
		// Add the intial resources to the total resources
		totalRes += tert.initialRes;
	}
	
	// Calculate the average initial resources and return it as an integer
	float average = float(totalRes) / float(structTertaries.Length);
	return RoundFloat(average);	
}

public Action Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
	// Don't fire the resource captured event unless the round is started
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	// Get the resource point type and team
	int type = event.GetInt("type");
	int team = event.GetInt("team");
	int entity = event.GetInt("entindex")
	
	// Switch the resource point type and fire the events
	switch (type)
	{
		case RESOURCE_TERTIARY: Tertiary_Captured(entity, team);
		case RESOURCE_SECONDARY: Secondary_Captured(entity, team);		
		case RESOURCE_PRIME: Primary_Captured(team);
	}
	
	return Plugin_Continue;
}

void Primary_Captured(int team)
{
	// If the current map is not corner, don't change the primary resource point
	if (!cornerMap)
		return;
	
	// Get the primary structure from the ArrayList
	ResPoint prime;
	structPrimary.GetArray(0, prime);
	
	// Change the owner to the team and update the primary structure
	prime.owner = team;
	structTertaries.SetArray(0, prime);
	
	// Set the current resources of the primary structure to team resources when captured
	ND_SetCurrentResources(prime.entIndex, prime.GetRes());
	
	// Kill the timer before the next one
	if (primaryTimer != INVALID_HANDLE && IsValidHandle(primaryTimer))
	{
		KillTimer(primaryTimer);
		primaryTimer = INVALID_HANDLE;	
	}
	
	// Since the resource extract event doesn't work, we must use a repeating timer to simulate resource extracts
	if (prime.owner == TEAM_EMPIRE || prime.owner == TEAM_CONSORT)
		primaryTimer = CreateTimer(15.0, TIMER_PrimaryExtract, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Secondary_Captured(int entity, int team)
{
	// If the current map is corner, don't change the secondary resource point
	if (cornerMap)
		return;
	
	// Get the array index of Secondary, exit if not found
	int arrIndex = Secondary_FindArrayIndex(entity);
	if (arrIndex == RESPOINT_NOT_FOUND)
		return;
	
	// Get the secondary structure from the ArrayList
	ResPoint sec;
	structSecondaries.GetArray(arrIndex, sec);
	
	// Change the owner to the team and update the secondary list
	sec.owner = team;
	structSecondaries.SetArray(arrIndex, sec);
	
	// Set the current resources of the secondary to team resources when captured
	ND_SetCurrentResources(sec.entIndex, sec.GetRes());
	
	// Kill the timer before creating the next one
	if (secondaryTimer[arrIndex] != INVALID_HANDLE && IsValidHandle(secondaryTimer[arrIndex]))
	{
		KillTimer(secondaryTimer[arrIndex]);
		secondaryTimer[arrIndex] = INVALID_HANDLE;
	}
	
	// Since the resource extract event doesn't work, we must use a repeating timer to simulate resource extracts
	secondaryTimer[arrIndex] = CreateTimer(10.0, TIMER_SecondaryExtract, arrIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Tertiary_Captured(int entity, int team)
{
	// Get the array index of Tertiary, exit if not found
	int arrIndex = Tertiary_FindArrayIndex(entity);		
	if (arrIndex == RESPOINT_NOT_FOUND)
		return;	
	
	// Get the tertiary structure from the ArrayList
	ResPoint tert;
	structTertaries.GetArray(arrIndex, tert);
		
	// Change the owner to the team and update the tertiary list
	tert.owner = team;
	tert.timeOwned = 0;
	structTertaries.SetArray(arrIndex, tert);
		
	// Set the current resources of the tertiary to team resources when captured
	ND_SetCurrentResources(tert.entIndex, tert.GetRes());
		
	// Kill the timer before creating the next one
	if (tertiaryTimer[arrIndex] != INVALID_HANDLE && IsValidHandle(tertiaryTimer[arrIndex]))
	{
		KillTimer(tertiaryTimer[arrIndex]);
		tertiaryTimer[arrIndex] = INVALID_HANDLE;
	}
		
	// Since the resource extract event doesn't work, we must use a repeating timer to simulate resource extracts
	if (tert.owner == TEAM_EMPIRE || tert.owner == TEAM_CONSORT)
		tertiaryTimer[arrIndex] = CreateTimer(5.0, TIMER_TertiaryExtract, arrIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public Action TIMER_TertiaryExtract(Handle timer, int arrIndex)
{
	// Get the tertiary structure from the ArrayList
	ResPoint tert;
	structTertaries.GetArray(arrIndex, tert);
	
	// Every five seconds a tertiary extracts 50 resources subtract that
	// Also update the amount of time the resource point was owned for
	tert.SubtractRes(50);
	tert.timeOwned += 5;
	
	// Get the opposing team, which doesn't own the tertiary resource point
	int otherTeam = getOtherTeam(tert.owner);
	
	// Every five seconds, regenerate 15 resources (30% of full production)
	// If the opposite team's reserved pool is less than 1800 (10 minutes of regen)
	if (tert.GetResTeam(otherTeam) <= TERTIARY_TRICKLE_REGEN_AMOUNT)
		tert.AddRes(otherTeam, TERTIARY_TRICKLE_REGEN_INTERVAL);
	
	// Every five seconds, degenerate 25 resources (50% of full production)
	// If the opposite team has not owned the resource point for 9 minutes
	if (tert.timeOwned > TERTIARY_TRICKLE_DEGEN_MINUTES * 60)
		tert.SubtractResTeam(otherTeam, TERTIARY_TRICKLE_DEGEN_INTERVAL);

	// Update the tertiary structure in the ArrayList
	structTertaries.SetArray(arrIndex, tert);
	return Plugin_Continue;
}

public Action TIMER_SecondaryExtract(Handle timer, int arrIndex)
{
	// Get the secodnary structure from the ArrayList
	ResPoint sec;
	structSecondaries.GetArray(arrIndex, sec);
	
	// Every ten seconds a secondary extracts 275 resources subtract that
	sec.SubtractRes(275);
	
	// Every ten seconds, regenerate 69 resources (25% of full production)
	// If the opposite teams reserved pool is less than 4140 (10 minutes of regen)
	// And if the initial resources of the secondary is depleted
	int otherTeam = getOtherTeam(sec.owner)
	if (sec.initialRes <= 0 && sec.GetResTeam(otherTeam) <= SECONDARY_TRICKLE_REGEN_AMOUNT)
		sec.AddRes(otherTeam, SECONDARY_TRICKLE_REGEN_INTERVAL);
	
	// Update the secondary structure in the ArrayList
	structSecondaries.SetArray(arrIndex, sec);
	return Plugin_Continue;	
}

public Action TIMER_PrimaryExtract(Handle timer)
{
	// Get the primary structure from the ArrayList
	ResPoint prime;
	structPrimary.GetArray(0, prime);
	
	// Every fifteen seconds, primary generates 750 resources subtract that
	prime.SubtractRes(750);
	
	// Update the primary structure in the ArrayList
	structTertaries.SetArray(0, prime);	
	return Plugin_Continue;
}