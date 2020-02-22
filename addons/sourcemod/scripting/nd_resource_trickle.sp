#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_entities>
#include <nd_resources>
#include <nd_resource_eng>
#include <nd_redstone>
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
bool largeMap = false;
bool mediumMap = false;
int initPlyCount = 0;

// Include the teritary structure and natives
#include "nd_res_trickle/constants.sp"
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

public void OnMapStart() 
{
	cornerMap = ND_CurrentMapIsCorner();
	largeMap = ND_IsLargeResMap();
	mediumMap = ND_IsMediumResMap();
}

public void ND_OnRoundStarted()
{
	/* Initialize varriables */
	listTertiaries.Clear();
	structTertaries.Clear();
	listSecondaries.Clear();
	structSecondaries.Clear();
	
	initPlyCount = ND_GetClientCount();
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
	
	/* Set secondary resources and initilize secondary structure */
	for (int s = 0; s < listSecondaries.Length; s++)
	{
		int sec = listSecondaries.Get(s);
		ND_SetCurrentResources(sec, SECONDARY_TRICKLE_SET + SECONDARY_TEAM_TRICKLE);		
	}	
	initSecondaryStructs();
	
	/* Set primary resources and initilize primary structure */
	ND_SetCurrentResources(PrimeEntity, PRIMARY_TRICKLE_SET + PRIMARY_TEAM_TRICKLE);
	initNewPrimary(PrimeEntity);

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
		// If large/medium map with little players, give tertiary 2000 inital and 4000 reserved
		if (ReduceTrickleRes())
		{
			tert.initialRes = TERTIARY_TRICKLE_SET_LRG;
			tert.empireRes = TERTIARY_TEAM_TRICKLE_LRG;
			tert.consortRes = TERTIARY_TEAM_TRICKLE_LRG;			
		}
		else
		{		
			tert.initialRes = TERTIARY_TRICKLE_SET;
			tert.empireRes = TERTIARY_TEAM_TRICKLE;
			tert.consortRes = TERTIARY_TEAM_TRICKLE;
		}
	}
	else
	{
		int average = GetAverageSpawnRes();
		int split = average / 3;
		
		tert.initialRes = split;
		tert.empireRes = split;
		tert.consortRes = split;
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
	
	// Don't enable team resource feature or trickle regen for secondaries on corner
	if (cornerMap)
	{	
		sec.initialRes = RES_SECONDARY_START;
		sec.empireRes = 0;
		sec.consortRes = 0;
	}
	// If large/medium map with little players, give secondary 20350 inital and 3300 reserved
	else if (ReduceTrickleRes())
	{
		sec.initialRes = SECONDARY_TRICKLE_SET_LRG;
		sec.empireRes = SECONDARY_TEAM_TRICKLE_LRG;
		sec.consortRes = SECONDARY_TEAM_TRICKLE_LRG;	
	}
	// Otherwise, give secondary 40700 inital and 3300 reserved
	else
	{
		sec.initialRes = SECONDARY_TRICKLE_SET;
		sec.empireRes = SECONDARY_TEAM_TRICKLE;
		sec.consortRes = SECONDARY_TEAM_TRICKLE;		
	}
	
	structSecondaries.PushArray(sec);	
}

void initNewPrimary(int entIndex)
{
	ResPoint prime;
	prime.arrayIndex = 0;
	prime.entIndex = entIndex;
	prime.owner = TEAM_SPEC;
	prime.type = RESOURCE_PRIME;	
	
	/* Decide based on the map and player count how many resources to prime prime */
	if (cornerMap) // If corner give prime 40k inital and 40k reserved
	{	
		prime.initialRes = PRIMARY_TRICKLE_SET_CORNER;
		prime.empireRes = PRIMARY_TEAM_TRICKLE_CORNER;
		prime.consortRes = PRIMARY_TEAM_TRICKLE_CORNER;
	}
	// If large/medium map with little players, give prime 37.5k inital and 5.25k reserved
	else if (ReduceTrickleRes())
	{
		prime.initialRes = PRIMARY_TRICKLE_SET_LRG;
		prime.empireRes = PRIMARY_TEAM_TRICKLE_LRG;
		prime.consortRes = PRIMARY_TEAM_TRICKLE_LRG;
	}
	else // Otherwise give prime 75k initial and 5.25k reserved
	{
		prime.initialRes = PRIMARY_TRICKLE_SET;
		prime.empireRes = PRIMARY_TEAM_TRICKLE;
		prime.consortRes = PRIMARY_TEAM_TRICKLE;
	}	
	
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

bool ReduceTrickleRes()
{
	if (largeMap && initPlyCount < TRICKLE_REDUCE_COUNT_LRG)
		return true;
	else if (mediumMap && initPlyCount < TRICKLE_REDUCE_COUNT_MED)
		return true;
	
	return false;
}

public Action Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
	// Don't fire the resource captured event unless the round is started
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	// Get the resource point type and team
	int type = event.GetInt("type");
	int team = event.GetInt("team");
	int entity = event.GetInt("entindex");
	
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
	// Get the primary structure from the ArrayList
	ResPoint prime;
	structPrimary.GetArray(0, prime);
	
	// Change the owner to the team and update the primary structure
	prime.owner = team;
	structPrimary.SetArray(0, prime);
	
	// Set the current resources of the primary structure to team resources when captured
	ND_SetPrimeResources(prime.GetRes());
	
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
	
	// Every five seconds, check if the tertiary qualfies for fracking.
	// Owned for 13 minutes by consort or empire with less than 300 team resources
	// Frack a total of 100 (55 actually) resources every 20 seconds (or 120 res/min)
	if (tert.timeOwned > TERTIARY_FRACKING_DELAY * 60 &&
		tert.GetResTeam(tert.owner) <= TERTIARY_FRACKING_LEFT &&
		(tert.owner == TEAM_EMPIRE || tert.owner == TEAM_CONSORT) &&
		tert.timeOwned % TERTIARY_FRACKING_SECONDS == 0)
		{
			// Add the resources to the tertiary and update the current resources
			tert.AddRes(tert.owner, TERTIARY_FRACKING_AMOUNT);
			ND_SetCurrentResources(tert.entIndex, tert.GetRes());
		}

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
	// Also update the amount of time the resource point was owned for
	sec.SubtractRes(275);
	sec.timeOwned += 10;
	
	// Every ten seconds, regenerate 55 resources (20% of full production)
	// If the opposite teams reserved pool is less than 3300 (10 minutes of regen)
	// And if the initial resources of the secondary is depleted
	// And if the map is not corner
	int otherTeam = getOtherTeam(sec.owner)
	if (!cornerMap && sec.initialRes <= 0 && sec.GetResTeam(otherTeam) <= SECONDARY_TRICKLE_REGEN_AMOUNT)
		sec.AddRes(otherTeam, SECONDARY_TRICKLE_REGEN_INTERVAL);
	
	// Every ten seconds, check if secondary qualfies for fracking.
	// Owned for 19.5 minutes by consort or empire with less than 825 team resources
	// Frack a total of 275 (151 actually) resources every 30 seconds (or 302.5 res/min)	
	if (sec.timeOwned > SECONDARY_FRACKING_DELAY * 60 &&
		sec.GetResTeam(sec.owner) <= SECONDARY_FRACKING_LEFT &&
		(sec.owner == TEAM_CONSORT || sec.owner == TEAM_EMPIRE) &&
		sec.timeOwned % SECONDARY_FRACKING_SECONDS == 0)
		{
			sec.AddRes(sec.owner, SECONDARY_FRACKING_AMOUNT);
			ND_SetCurrentResources(sec.entIndex, sec.GetRes());			
		}
	
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
	// Also update the amount of time the resource point was owned for
	prime.SubtractRes(750);
	prime.timeOwned += 15;
	
	// Get the opposing team, which doesn't own the primary resource point
	int otherTeam = getOtherTeam(prime.owner);
	
	// Every fifteen seconds, regenerate 75 resources (10% of full production)
	// If the opposite teams reserved pool is less than 3000 (10 minutes of regen)
	// And if the initial resources of the prime is depleted
	if (!cornerMap && prime.initialRes <= 0 && prime.GetResTeam(otherTeam) <= PRIMARY_TRICKLE_REGEN_AMOUNT)
		prime.AddRes(otherTeam, PRIMARY_TRICKLE_REGEN_INTERVAL);
	
	// Every fifteen seconds, degenerate 375 resources (50% of full production)
	// If the opposite team has not owned the resource point for 12 minutes
	else if (cornerMap && prime.timeOwned > PRIMARY_TRICKLE_DEGEN_MINUTES * 60)
		prime.SubtractResTeam(otherTeam, PRIMARY_TRICKLE_DEGEN_INTERVAL);
	
	// Every 15 seconds, check if the prime qualfies for fracking.
	// Owned for 26 minutes by consort or empire with less than 1500 team resources
	// Frack a total of 750 (412 actually) resources every 45 seconds (or 550 res/min)
	if (prime.timeOwned > PRIMARY_FRACKING_DELAY * 60 &&
		prime.GetResTeam(prime.owner) <= PRIMARY_FRACKING_LEFT &&
		(prime.owner == TEAM_CONSORT || prime.owner == TEAM_EMPIRE) &&
		prime.timeOwned % PRIMARY_FRACKING_SECONDS == 0)
		{
			prime.AddRes(prime.owner, PRIMARY_FRACKING_AMOUNT);
			ND_SetPrimeResources(prime.GetRes());
		}
	
	// Update the primary structure in the ArrayList
	structPrimary.SetArray(0, prime);	
	return Plugin_Continue;
}
