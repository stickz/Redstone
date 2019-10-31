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

#define RESOURCE_NOT_TERTIARY -1

ArrayList listTertiaries;
ArrayList structTertaries;
Handle tertiaryTimer[18] = { INVALID_HANDLE, ... };

/* Tertiary struct and functions */
enum struct Tertiary 
{
	int arrayIndex;
	int entIndex;
	
	int owner;
	
	int initialRes;
	int empireRes;
	int consortRes;	
}

int Tertiary_FindArrayIndex(int entity) {
	return structTertaries.FindValue(entity, Tertiary::entIndex);	
}

int Tertiary_GetResources(const Tertiary t)
{
	// Return initial resources if greater than 0
	int initRes = t.initialRes;	
	if (initRes > 0)
		return initRes;
	
	// Otherwise, return the owner team's resources
	switch (t.owner)
	{
		case TEAM_EMPIRE: return t.empireRes;
		case TEAM_CONSORT: return t.consortRes;
	}
	
	// If no owner is present, return the initial resources
	return initRes;	
}

void Tertiary_UpdateResources(int index, int amount)
{		
	// Get the tertiary structure from the ArrayList
	Tertiary tert;
	structTertaries.GetArray(index, tert);
	
	// If the initial resources is greater than 0, update it
	if (tert.initialRes > 0)
		tert.initialRes -= amount;
	
	// Otherwise, update the team resources
	else
	{
		switch (tert.owner)
		{
			case TEAM_EMPIRE: tert.empireRes -= amount;
			case TEAM_CONSORT: tert.consortRes -= amount;
		}	
	}

	// Update ther tertiary structures in the ArrayList
	structTertaries.SetArray(index, tert);	
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
		ND_SetCurrentResources(tert, TRICKLE_SET);
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
	if (event.GetInt("type") == RESOURCE_TERTIARY)
	{	
		// Get the array index and owner team of the Tertiary
		int arrIndex = Tertiary_FindArrayIndex(event.GetInt("entindex"));
		int team = event.GetInt("team");
		
		// Get the tertiary structure from the ArrayList
		Tertiary tert;
		structTertaries.GetArray(arrIndex, tert);
		
		// Change the owner to the team and update the tertiary list
		tert.owner = team;
		structTertaries.SetArray(arrIndex, tert);
		
		// Set the current resources of the tertiary to team resources when captured
		int resources = Tertiary_GetResources(tert);
		ND_SetCurrentResources(tert.entIndex, resources);
		
		// Kill the timer before creating the next one
		if (tertiaryTimer[arrIndex] != INVALID_HANDLE)
		{
			KillTimer(tertiaryTimer[arrIndex]);
			tertiaryTimer[arrIndex] = INVALID_HANDLE;
		}
		
		// Since the resource extract event doesn't work, we must use a repeating timer to simulate resource extracts
		if (tert.owner == TEAM_EMPIRE || tert.owner == TEAM_CONSORT)
			tertiaryTimer[arrIndex] = CreateTimer(5.0, TIMER_ResourceExtract, arrIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TIMER_ResourceExtract(Handle timer, int arrIndex)
{
	// Get the tertiary structure from the ArrayList
	Tertiary tert;
	structTertaries.GetArray(arrIndex, tert);
	
	// Every five seconds a tertiary extracts 50 resources update that
	Tertiary_UpdateResources(tert.arrayIndex, 50);
	
	// Keep setting resources, in case we run out of team resources
	int teamRes = Tertiary_GetResources(tert);
	ND_SetCurrentResources(tert.entIndex, teamRes);
	
	return Plugin_Continue;
}