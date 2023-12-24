#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_entities>
#include <nd_resources>
#include <nd_resource_eng>
#include <nd_redstone>
#include <smlib/math>
#include <nd_maps>
#include <nd_team_eng>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Trickle",
	author 		= "Stickz",
	description 	= "Adjusts tertaries to have team trickle amounts",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_trickle/nd_resource_trickle.txt"
#include "updater/standard.sp"

#define RESOURCE_NOT_TERTIARY 	-1
#define RESPOINT_NOT_FOUND		-1
#define RESPOINT_FRACK_FALSE 	0
#define RESPOINT_FRACK_TRUE 	1

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
bool coastMap = false;
bool largeMap = false;
bool mediumMap = false;

int initPlyCount = 0;
int curPlyCount = 0;
int frackPlyCount = 0;

// Include the teritary structure and natives
#include "nd_res_trickle/constants.sp"
#include "nd_res_trickle/resource.sp"
#include "nd_res_trickle/natives.sp"

// Resource constants. Determine on map start.
int primaryFrackingAmount = PRIMARY_FRACKING_AMOUNT;
int primaryFrackingSeconds = PRIMARY_FRACKING_SECONDS;
float primaryFrackingDelay = PRIMARY_FRACKING_DELAY;

// Resource entity lookup functions for tertaries and secondaries
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
	
	InitForwards(); // Creates plugin forwards
	
	// Add late loading support to resource trickle
	if (ND_RoundStarted() && ND_ResPointsCached())
		ND_OnResPointsCached();
}

public void OnMapStart() 
{
	// Get the current map
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Check if the current map is coast or corner
	cornerMap = ND_CustomMapEquals(currentMap, ND_Corner);
	coastMap = ND_StockMapEquals(currentMap, ND_Coast);
	
	// Check if the current map is a medium or large map
	largeMap = ND_IsLargeResMap();
	mediumMap = ND_IsMediumResMap();
	
	// If corner or coast, change the primary fracking intervals
	SetPrimaryFrackingIntervals();
	
	// Require more players to frack on larger maps, to prevent resource domination
	SetFrackingMinPlyCount();
}

public void ND_OnPlayerTeamChanged(int client, bool valid)
{	
	if (ND_RoundStarted())
		curPlyCount = RED_OnTeamCount();
}

public void ND_OnRoundStarted()
{
	/* Initialize varriables */
	listTertiaries.Clear();
	structTertaries.Clear();
	listSecondaries.Clear();
	structSecondaries.Clear();
	PrimeEntity = -1;	
	structPrimary.Clear();
	
	int clientCount = ND_GetClientCount();	
	initPlyCount = clientCount;
	curPlyCount = clientCount;
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
	if (PrimeEntity != -1)
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
	tert.firstFrack = RESPOINT_FRACK_TRUE;

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
	sec.firstFrack = RESPOINT_FRACK_TRUE;
	
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
	prime.firstFrack = RESPOINT_FRACK_TRUE;
	
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

void SetPrimaryFrackingIntervals()
{
	if (cornerMap)
	{
		primaryFrackingAmount = PRIMARY_FRACKING_AMOUNT_FASTER;
		primaryFrackingSeconds = PRIMARY_FRACKING_SECONDS_FASTER;
		primaryFrackingDelay = PRIMARY_FRACKING_DELAY_FASTER;	
	}
	
	else if (coastMap)
	{
		primaryFrackingAmount = PRIMARY_FRACKING_AMOUNT_FASTER;
		primaryFrackingSeconds = PRIMARY_FRACKING_SECONDS_FASTER;
		primaryFrackingDelay = PRIMARY_FRACKING_DELAY;
	}
	
	else
	{
		primaryFrackingAmount = PRIMARY_FRACKING_AMOUNT;
		primaryFrackingSeconds = PRIMARY_FRACKING_SECONDS;
		primaryFrackingDelay = PRIMARY_FRACKING_DELAY;		
	}	
}

void SetFrackingMinPlyCount()
{
	if (largeMap)
		frackPlyCount = FRACKING_MIN_PLYS_LRG;
	else if (mediumMap)
		frackPlyCount = FRACKING_MIN_PLYS_MED;
	else
		frackPlyCount = FRACKING_MIN_PLYS;
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
	
	// Update capture varriables and push them to the primary structure
	prime.owner = team;
	prime.timeOwned = 0;
	prime.firstFrack = RESPOINT_FRACK_TRUE;
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
	
	// Update capture varriables and push them to the secondary array list
	sec.owner = team;
	sec.timeOwned = 0;
	sec.firstFrack = RESPOINT_FRACK_TRUE;
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
		
	// Update capture varriables and push them to the teritary array list
	tert.owner = team;
	tert.timeOwned = 0;
	tert.firstFrack = RESPOINT_FRACK_TRUE;
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
	// Owned for 8 minutes by consort or empire with less than 300 team resources
	// Frack a total of 100 resources every 25 seconds (or 150 res/min)
	if (!cornerMap && ResPointReadyForFrack(tert, TERTIARY_FRACKING_DELAY, TERTIARY_FRACKING_LEFT, TERTIARY_FRACKING_SECONDS))
	{
		// If this is the first frack, fire the forward
		if (tert.firstFrack == RESPOINT_FRACK_TRUE)
		{
			FireOnResFrackStartedForward(tert.type, TERTIARY_FRACKING_DELAY, TERTIARY_FRACKING_SECONDS, TERTIARY_FRACKING_AMOUNT);
			tert.firstFrack = RESPOINT_FRACK_FALSE;
		}
		
		// Add the resources to the teritary struct and update the tertiary entity resources
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
	// Owned for 15 minutes by consort or empire with less than 825 team resources
	// Frack a total of 275 resources every 20 seconds (or 453.5 res/min)
	if (!cornerMap && ResPointReadyForFrack(sec, SECONDARY_FRACKING_DELAY, SECONDARY_FRACKING_LEFT, SECONDARY_FRACKING_SECONDS))
	{
		// If this is the first frack, fire the forward
		if (sec.firstFrack == RESPOINT_FRACK_TRUE)
		{
			FireOnResFrackStartedForward(sec.type, SECONDARY_FRACKING_DELAY, SECONDARY_FRACKING_SECONDS, SECONDARY_FRACKING_AMOUNT);
			sec.firstFrack = RESPOINT_FRACK_FALSE;
		}
		
		// Add the resources to the secondary struct and update the secondary entity resources
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
	// Owned for 20 minutes by consort or empire with less than 1500 team resources
	// Frack a total of 750 resources every 30 seconds (or 825 res/min)
	// On corner or coast map frack 3000 every 60 seconds, if owned for 15 minutes. (100% production)
	if (ResPointReadyForFrack(prime, primaryFrackingDelay, PRIMARY_FRACKING_LEFT, primaryFrackingSeconds))
	{
		// If this is the first frack, fire the forward
		if (prime.firstFrack == RESPOINT_FRACK_TRUE)
		{
			FireOnResFrackStartedForward(prime.type, primaryFrackingDelay, primaryFrackingSeconds, primaryFrackingAmount);
			prime.firstFrack = RESPOINT_FRACK_FALSE;
		}
		
		// Add the resources to the primary struct and update the prime entity resources		
		prime.AddRes(prime.owner, primaryFrackingAmount);
		ND_SetPrimeResources(prime.GetRes());		
	}
	
	// Update the primary structure in the ArrayList
	structPrimary.SetArray(0, prime);	
	return Plugin_Continue;
}

bool ResPointReadyForFrack(ResPoint point, float frackDelay, int resLeft, int interval)
{
	if (point.timeOwned > frackDelay * 60.0 && point.GetResTeam(point.owner) <= resLeft &&
	    (point.owner == TEAM_CONSORT || point.owner == TEAM_EMPIRE) && 
		 point.timeOwned % interval == 0 && curPlyCount >= frackPlyCount)
			return true;			
			
	return false;
}
