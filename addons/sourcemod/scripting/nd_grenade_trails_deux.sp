#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

#include <nd_stocks>
#include <nd_rounds>
#include <nd_com_eng>
#include <nd_redstone>
#include <nd_swgm>
#include <nd_print>

#define NO_COMMANDER -1
#define MAX_DISPLAYNAME_SIZE 30
#define COLOUR_SCALE_SIZE 4

#define TRAIL_LIFETIME 1.0
#define TRAIL_WIDTH 10.0
#define TRAIL_FADE 5

#define VMT_SPOTLIGHT "materials/sprites/spotlight.vmt"
#define VTF_SPOTLIGHT "materials/sprites/spotlight.vtf"

int SpotlightModel = -1;

// First colour set is team_consort (team index 2), Second colour set is team_empire (team index 3)
int Colours[2][COLOUR_SCALE_SIZE] = { { 0, 80, 255, 255 } , { 255, 0, 0, 255 }};
int Colour_Gray[COLOUR_SCALE_SIZE] = { 158, 158, 158, 255 };

public Plugin myinfo =
{
	name 		= "[ND] Grenade Trails V2",
	author 		= "Stickz",
	description 	= "Adds lightbeams to grenades/rockets",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#include "nd_trails/clientprefs.sp"

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_grenade_trails_deux/nd_grenade_trails_deux.txt"
#include "updater/standard.sp"

public void OnMapStart() {
	PrecacheTrails();
}

public void OnPluginStart()
{
	if (ND_MapStarted())
		PrecacheTrails();
	
	LoadTranslations("nd_grenade_trails_deux.phrases");
	LoadTranslations("nd_common.phrases");
	AddClientPrefSupport(); // clientprefs.sp
	AddUpdaterLibrary(); //auto-updater
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "gren") != -1 || StrContains(classname, "rocket") != -1)
	{
		if (StrEqual(classname, "emp_grenade_ent", true))
			SDKHook(entity, SDKHook_Spawn, OnEmpGrenadeSpawned);

		SDKHook(entity, SDKHook_Spawn, OnTrailItemSpawned);
	}
}

public void OnEmpGrenadeSpawned(int entity)
{
	int owner = GetEntClientInt(entity);	
	if (IsValidClient(owner))
	{
		ArrayList players = new ArrayList(32);
		
		/* Send to the commander, when NOT in commander view */
		int ownerTeam = GetClientTeam(owner);
		int commander = ND_GetTeamCommander(ownerTeam);	
		if (commander != NO_COMMANDER && !ND_InCommanderMode(commander))
			players.Push(commander);
		
		/* Send to all players currently on a team */
		int clientTeam = -1;
		RED_LOOP_CLIENTS(idx) 
		{
			clientTeam = GetClientTeam(idx);
			if (clientTeam >= 2 && clientTeam == ownerTeam && option_trails[idx])
				players.Push(idx);
		}
		
		/* Setup the beam and send it to the array list of players */
		Trail_SendEffect(players, entity, Colour_Gray);
		
		// Must delete arraylist when complete, to curve memory leaks
		delete players;
	}
}

public void OnTrailItemSpawned(int entity)
{
	int owner = GetEntClientInt(entity);	
	if (IsValidClient(owner))
	{
		ArrayList players = new ArrayList(32);
		
		/* Send to the commander, when in commander view */
		int ownerTeam = GetClientTeam(owner);
		int commander = ND_GetTeamCommander(ownerTeam);		
		if (commander != NO_COMMANDER && ND_InCommanderMode(commander))
			players.Push(commander);
		
		/* Send to all players currently in spectator or unassigned */
		RED_LOOP_CLIENTS(idx) 
		{
			if (GetClientTeam(idx) < 2 && option_trails[idx])
				players.Push(idx);
		}
		
		/* Setup the beam and send it to the array list of players */
		Trail_SendEffect(players, entity, Colours[ownerTeam-2]);
		
		// Must delete arraylist when complete, to curve memory leaks
		delete players;
	}
}

void Trail_SendEffect(ArrayList &players, int entity, int colour[COLOUR_SCALE_SIZE])
{
	int arraySize = players.Length;	
	if (arraySize > 0)
	{
		Trail_SetupBeamFollow(entity, colour);
						   
		int[] arrayContainer = new int[arraySize];			
		for (int element = 0; element < arraySize; element++)
			arrayContainer[element] = players.Get(element);

		TE_Send(arrayContainer, arraySize);		
	}	
}

void Trail_SetupBeamFollow(int entity, int colour[COLOUR_SCALE_SIZE])
{
	TE_SetupBeamFollow(	entity, 
				SpotlightModel, 
				0, 
				TRAIL_LIFETIME, 
				TRAIL_WIDTH, 
				TRAIL_WIDTH, 
				TRAIL_FADE, 
				colour
			  );
}

int GetEntClientInt(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (IsValidEdict(client))
	{
		char classname[32];
		GetEdictClassname(client, classname, sizeof(classname));
		if (StrContains(classname, "weapon") != -1)
			client = GetEntPropEnt(client, Prop_Send, "m_hOwnerEntity");
	}
		
	return client;
}

void PrecacheTrails()
{
	SpotlightModel = PrecacheModel(VMT_SPOTLIGHT);
	AddFileToDownloadsTable(VMT_SPOTLIGHT);
	AddFileToDownloadsTable(VTF_SPOTLIGHT);
}
