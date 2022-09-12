#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_maps>
#include <nd_team_eng>
#include <nd_rounds>
#include <nd_entities>
#include <nd_resources>
#include <nd_resource_eng>
#include <nd_redstone>
#include <smlib/math>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Trickle V2",
	author 		= "Stickz",
	description 	= "Improves game balance of tertaries & secondaries",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_trickle_v2/nd_resource_trickle_v2.txt"
#include "updater/standard.sp"

#define RESOURCE_NOT_TERTIARY 	-1
#define RESPOINT_NOT_FOUND		-1
#define RESPOINT_FRACK_FALSE 	0
#define RESPOINT_FRACK_TRUE 	1

#define SECONDARY_FRACKING_AMOUNT 130 // Amount of resources to grant per frack
#define SECONDARY_FRACKING_SECONDS 30 // Number of seconds inbetween fracks
#define SECONDARY_FRACKING_LEFT 650 // Amount of resources left before fracking is enabled
#define SECONDARY_FRACKING_DELAY 15.0  // Number of minutes a team most own a secondary to start fracking

#define TERTIARY_TRICKLE_SET 10000 // Initial pool of resources, first come, first serve
#define TERTIARY_TEAM_TRICKLE 5000 // Reserved pool of resources for each team

#define TERTIARY_TRICKLE_DEGEN_INTERVAL 25 // Amount to degenerate every five seconds
#define TERTIARY_TRICKLE_DEGEN_MINUTES 8 // Minutes to degenerate if team hasn't owned tertiary

#define FRACKING_MIN_PLYS 8 // Specifies the minimum player count to enable fracking
#define FRACKING_MIN_PLYS_MED 12 // Specifies the minimum player count to enable fracking
#define FRACKING_MIN_PLYS_LRG 16 // Specifies the minimum player count to enable fracking

ArrayList listTertiaries;
ArrayList structTertaries;

ArrayList listSecondaries;
ArrayList structSecondaries;

Handle tertiaryTimer[19] = { INVALID_HANDLE, ... };
Handle secondaryTimer[4] = { INVALID_HANDLE, ... };

bool cornerMap = false;
bool largeMap = false;
bool mediumMap = false;

int frackPlyCount = 0;
int curPlyCount = 0;

// Include the teritary structure
#include "nd_res_trickle_v2/resource.sp"

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
	
	HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);
	
	AddUpdaterLibrary(); // Add auto updater feature
	
	// Add late loading support to resource trickle
	if (ND_RoundStarted() && ND_ResPointsCached())
		ND_OnResPointsCached();
}

public void OnMapStart() 
{
	// Check if the current map is corner
	cornerMap = ND_CurrentMapIsCorner();
	
	// Check if the current map is a medium or large map
	largeMap = ND_IsLargeResMap();
	mediumMap = ND_IsMediumResMap();
	
	// Require more players to frack on larger maps, to prevent resource domination
	SetFrackingMinPlyCount();
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

public void ND_OnPlayerTeamChanged(int client, bool valid)
{	
	if (ND_RoundStarted())
		curPlyCount = RED_OnTeamCount();
}

public void ND_OnRoundStarted()
{
	// Initialize varriables
	listTertiaries.Clear();
	structTertaries.Clear();
	listSecondaries.Clear();
	structSecondaries.Clear();
	
	// Initialize the current player count	
	curPlyCount = ND_GetClientCount();
}

public void ND_OnResPointsCached()
{
	// Get the list of tertaries and secondaries from the resource engine
	listTertiaries = ND_GetTertiaryList();
	listSecondaries = ND_GetSecondaryList();
	
	// Setup the resource point structures to allow implementation of changes
	CreateTimer(3.0, TIMER_SetResPointStructs, _, TIMER_FLAG_NO_MAPCHANGE);
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
		ND_SetCurrentResources(sec, RES_SECONDARY_START);
	}	
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
	tert.firstFrack = RESPOINT_FRACK_TRUE;
	
	// Should we init the teritary with full resources?
	if (fullRes)
	{
		tert.initialRes = TERTIARY_TRICKLE_SET;
		tert.empireRes = TERTIARY_TEAM_TRICKLE;
		tert.consortRes = TERTIARY_TEAM_TRICKLE;		
	}
	
	// Otherwise init the tertiary with average resources
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
	
	// Initialize the secondary with stock resources
	sec.initialRes = RES_SECONDARY_START;
	sec.empireRes = 0;
	sec.consortRes = 0;
	
	// Push the secondary object into the struct list
	structSecondaries.PushArray(sec);
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

public void ND_OnTertairySpawned(int entity, int trigger)
{
	// Add tertiary to the list of tertaries
	// Create a new tertiary struct for trickling
	int index = listTertiaries.Push(entity);
	initNewTertiary(index, entity, false);
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
	}
	
	return Plugin_Continue;
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
	secondaryTimer[arrIndex] = CreateTimer(5.0, TIMER_SecondaryExtract, arrIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
	
	// Every five seconds, degenerate 25 resources (50% of full production)
	// If the opposite team has not owned the resource point for 8 minutes
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
	
	// Every ten seconds a secondary extracts 130 resources subtract that
	// Also update the amount of time the resource point was owned for
	sec.SubtractRes(130);
	sec.timeOwned += 5;
	
	// Every ten seconds, check if secondary qualfies for fracking.
	// Owned for 15 minutes by consort or empire with less than 650 team resources
	// Frack a total of 130 resources every 30 seconds (or 260 res/min)
	if (!cornerMap && ResPointReadyForFrack(sec, SECONDARY_FRACKING_DELAY, SECONDARY_FRACKING_LEFT, SECONDARY_FRACKING_SECONDS))
	{
		// Add the resources to the secondary struct and update the secondary entity resources
		sec.AddRes(sec.owner, SECONDARY_FRACKING_AMOUNT);
		ND_SetCurrentResources(sec.entIndex, sec.GetRes());
	}
	
	// Update the secondary structure in the ArrayList
	structSecondaries.SetArray(arrIndex, sec);
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