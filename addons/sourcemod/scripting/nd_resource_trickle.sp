#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_entities>
#include <nd_resources>
#include <nd_resource_eng>

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

#define TEAM_TRICKLE 8000
#define TRICKLE_SET 8000

#define RESOURCE_NOT_TERTIARY 	-1
#define TERTIARY_NOT_FOUND		-1

ArrayList listTertiaries;
ArrayList structTertaries;
Handle tertiaryTimer[18] = { INVALID_HANDLE, ... };

// Include the teritary structure and natives
#include "nd_res_trickle/tertiary.sp"
#include "nd_res_trickle/natives.sp"

int Tertiary_FindArrayIndex(int entity) {
	return structTertaries.FindValue(entity, Tertiary::entIndex);	
}

public void OnPluginStart()
{
	listTertiaries = new ArrayList(18);
	structTertaries = new ArrayList(sizeof(Tertiary));
	
	HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);
	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnMapStart() 
{
	/* Initialize varriables */
	listTertiaries.Clear();
}

public void ND_OnResPointsCached()
{
	// Get the list of tertaries from the resource engine
	listTertiaries = ND_GetTertiaryList();	
	
	// Set the current trickle amount to 7000 resources for all the tertaries
	CreateTimer(3.0, TIMER_SetTertiaryResources, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_SetTertiaryResources(Handle timer) 
{	
	for (int t = 0; t < listTertiaries.Length; t++) 
	{
		int tert = listTertiaries.Get(t);
		ND_SetCurrentResources(tert, TRICKLE_SET + TEAM_TRICKLE);
	}
	
	initTertairyStructs();

	return Plugin_Continue;
}

void initTertairyStructs()
{
	for (int t = 0; t < listTertiaries.Length; t++)
	{
		// Create and initialize new tertiary object
		Tertiary tert;
		tert.arrayIndex = t;
		tert.entIndex = listTertiaries.Get(t);		
		tert.initialRes = TRICKLE_SET;
		tert.empireRes = TEAM_TRICKLE;
		tert.consortRes = TEAM_TRICKLE;
		tert.owner = TEAM_SPEC;
		
		// Push the teritary object into the struct list
		structTertaries.PushArray(tert);
	}	
}

public Action Event_ResourceCaptured(Event event, const char[] name, bool dontBroadcast)
{
	// If the resource point is not a tertiary, exit
	if (event.GetInt("type") != RESOURCE_TERTIARY)
		return Plugin_Continue;
	
	// Get the array index and Tertiary if it's not found, exit
	int arrIndex = Tertiary_FindArrayIndex(event.GetInt("entindex"));		
	if (arrIndex == TERTIARY_NOT_FOUND)
		return Plugin_Continue;		
	
	// Get the tertiary structure from the ArrayList
	Tertiary tert;
	structTertaries.GetArray(arrIndex, tert);
		
	// Change the owner to the team and update the tertiary list
	tert.owner = event.GetInt("team");
	structTertaries.SetArray(arrIndex, tert);
		
	// Set the current resources of the tertiary to team resources when captured
	ND_SetCurrentResources(tert.entIndex, tert.GetRes());
		
	// Kill the timer before creating the next one
	if (tertiaryTimer[arrIndex] != INVALID_HANDLE)
	{
		KillTimer(tertiaryTimer[arrIndex]);
		tertiaryTimer[arrIndex] = INVALID_HANDLE;
	}
		
	// Since the resource extract event doesn't work, we must use a repeating timer to simulate resource extracts
	if (tert.owner == TEAM_EMPIRE || tert.owner == TEAM_CONSORT)
		tertiaryTimer[arrIndex] = CreateTimer(5.0, TIMER_ResourceExtract, arrIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action TIMER_ResourceExtract(Handle timer, int arrIndex)
{
	// Get the tertiary structure from the ArrayList
	Tertiary tert;
	structTertaries.GetArray(arrIndex, tert);
	
	// Every five seconds a tertiary extracts 50 resources subtract that
	tert.SubtractRes(50);

	// Update ther tertiary structures in the ArrayList
	structTertaries.SetArray(arrIndex, tert);
	return Plugin_Continue;
}