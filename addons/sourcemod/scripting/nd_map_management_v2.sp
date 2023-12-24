#include <sourcemod>
#include <mapchooser>
#include <nd_stocks>
#include <autoexecconfig>

//#pragma newdecls required
#include <nd_maps>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_teampick>
#include <nd_mlist>
#include <nd_print>

#define MAX_MAP_COUNT 16

#define DEBUG 1		

#define CHANGE_TYPE_LOW		0
#define CHANGE_TYPE_HIGH 	1

#define IN_EXCLUDE_ARRAY 	0

#define NOT_IN_ARRAY -1

public Plugin myinfo =
{
	name = "[ND] Map Management",
	author = "Stickz",
	description = "Central map management plugin for ND",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_map_management_v2/nd_map_management_v2.txt"
#include "updater/standard.sp"

ArrayList g_MapInputList;
ArrayList g_PreviousMapList;

ConVar cvarPrefOptionCount;
ConVar cvarPrefExcludeCount;
ConVar cvarAbsoluteMinOpts;
ConVar cvarLrgTargetOpts;
ConVar cvarMaxStoreCount;
ConVar cvarMapListCooldown;
ConVar cvarRecentLrgMapCheck;
ConVar cvarLrgMapCyclePressure;
ConVar cvarPlayerDiffRetrigger;
//ConVar cvarMinPlayersAddMap;

int mapVoteTriggerCount = 0;
bool mapVoteStartedThisRound = false;

#include "nd_map_man_v2/textFiles.sp"
#include "nd_map_man_v2/commands.sp"
#include "nd_map_man_v2/stockMaps.sp"
#include "nd_map_man_v2/natives.sp"

public void OnPluginStart()
{
	g_MapInputList = new ArrayList(MAX_MAP_COUNT);
	g_PreviousMapList = new ArrayList(MAP_SIZE);
	
	CreateCommands(); // register the commands for commanders.sp
	
	// Set the file to the thresholds to control player skill
	AutoExecConfig_SetFile("nd_mvote_options");
	
	cvarPrefOptionCount 	= 	AutoExecConfig_CreateConVar("sm_voter_options", "6", "Sets the number of target map voter choices");
	cvarAbsoluteMinOpts		=	AutoExecConfig_CreateConVar("sm_voter_amin", "4", "Sets the minimum number of map voter choices");
	cvarLrgTargetOpts		= 	AutoExecConfig_CreateConVar("sm_voter_tmax", "4", "Sets the target max option count with large maps");
	cvarPrefExcludeCount	=	AutoExecConfig_CreateConVar("sm_voter_exclude", "5", "Sets the min target of previous maps to exclude");
	cvarMaxStoreCount		=	AutoExecConfig_CreateConVar("sm_voter_storage", "50", "Specifies how many previous maps to store");
	cvarMapListCooldown		= 	AutoExecConfig_CreateConVar("sm_voter_lcooldown", "30", "Sets # of seconds a user must wait before listing previous maps again");
	cvarRecentLrgMapCheck	=	AutoExecConfig_CreateConVar("sm_voter_rec_lrg", "8", "Specifies how many recent maps, to check for large maps");
	cvarLrgMapCyclePressure	=	AutoExecConfig_CreateConVar("sm_voter_cplrg", "17", "Specifies the amount of players to pressure cycling to large maps");
	cvarPlayerDiffRetrigger = 	AutoExecConfig_CreateConVar("sm_voter_retrigger", "10", "Specifies the amount of players added/removed to retrigger a map vote");
	//cvarMinPlayersAddMap	=	AutoExecConfig_CreateConVar("sm_voter_writelastmap", "3", "Specifies the number of real players to write the current map to excludes");
	
	// Execute and clean the configuration file
	AutoExecConfig_EC_File();
	
	LoadTranslations("nd_map_management.phrases"); //load the plugin's translations	
	CreateTextFile(); // Create text files (if not present)
	
	// Add late loading support
	if (ND_RoundStarted())
		PerformRoundStartActions();
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientPutInServer(int client)
{
	if (mapVoteStartedThisRound && ND_RoundStarted() && CanMapChooserStartVote())
	{
		int playerCount = cvarPlayerDiffRetrigger.IntValue;
		int clientCount = ND_GetClientCount();
		if (clientCount >= mapVoteTriggerCount + playerCount || clientCount <= mapVoteTriggerCount - playerCount)
		{
			PrintMessageAllTI1("Retrigger Player Count", playerCount);
			StartAndSetupMapVoter();
		}
	}	
}

public void ND_OnRoundStarted() 
{		
	PerformRoundStartActions();
	StartAndSetupMapVoter();
}

void PerformRoundStartActions()
{
	// Set if teampick mode is running, default to no if native is not availible
	teamPickMode = ND_TeamsPickedThisMap();
	ReadTextFile(); // Read maps for voting from the text file
}

public void ND_OnRoundEnded()
{
	/* Write the array list changes to a text file */
	WriteTextFile();
	
	// Top in progress votes
	if (!CanMapChooserStartVote())
		ServerCommand("sm_cancelvote");
	
	mapVoteStartedThisRound = false;
}

public void OnMapEnd()
{
	// Top in progress votes
	if (!CanMapChooserStartVote())
		ServerCommand("sm_cancelvote");
}

bool TestVoteDelay(int client)
{
 	int delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		PrintToChat(client, "\x05[xG] Please wait %d seconds", delay);
 		return false;
 	}
 	
	return true;
}

void StartAndSetupMapVoter()
{		
	mapVoteStartedThisRound = true;
	mapVoteTriggerCount = ND_GetClientCount();
	
	g_MapInputList.Clear(); //clear the map list array
	ParseExcludedMaps(); //Make sure the array count is 9
	
	/* Retreive the map vote list from nd_map_thresholds */
	g_MapInputList = ND_GetMapVoteList();
	
	/* Try to reduce the map option count */
	CheckAndReduceOptionCount();

	if (g_MapInputList.Length > 0)
		InitiateMapChooserVote(MapChange_MapEnd, g_MapInputList);
	else
	{
		LogError("Warning: The map vote list is empty, using failsafe");
		InitiateMapChooserVote(MapChange_MapEnd);
	}
}

void ParseExcludedMaps()
{
	/* Store the Current Map into the map string */
	char map[32];
	GetCurrentMap(map, sizeof(map));
		
	/* Remove all instances of the current map from exclude array */
	do{} while (RemoveStringFromArray(g_PreviousMapList, map));
	
	/* Add current map string to end of exclude array */
	g_PreviousMapList.PushString(map);
	
	/* If the array size is bigger than it's store count */
	if (g_PreviousMapList.Length > cvarMaxStoreCount.IntValue)
		/* Remove the final map from the list */
		g_PreviousMapList.Erase(0);
}

void CheckAndReduceOptionCount()
{
	int index = g_PreviousMapList.Length - 1;
	int options = GetOptionCount(g_MapInputList.Length);
	char mapName[32];
	
	while (g_MapInputList.Length > options && index >= 0)
	{
		/* Find the map name at the given index */
		g_PreviousMapList.GetString(index, mapName, sizeof(mapName));
		
		/* Remove the map of the given index */
		RemoveStringFromArray(g_MapInputList, mapName);
		
		index--;
	}
}

bool RemoveStringFromArray(ArrayList array, const char[] str)
{
	int index = array.FindString(str);
	if (index != -1)
	{
		array.Erase(index);
		return true;
	}
	
	return false;	
}

int GetOptionCount(int voteOptions)
{
	int options = voteOptions - cvarPrefExcludeCount.IntValue;
	int min = cvarAbsoluteMinOpts.IntValue;	
	
	// If options are less than min, we must use min anyways
	if (options < min)
		return min;

	// If we're within the threshold to play bigger maps
	if (ND_GetClientCount() >= cvarLrgMapCyclePressure.IntValue)
	{
		// Look to see if we need to decrese option count
		// This ensures more larger maps get played
		
		// Use this to further reduce optionCount (if required)
		int lrgMapCount = GetRecentLargeMapCount();
		
		if (lrgMapCount >= 3)
			return min;
		
		else if (lrgMapCount == 2) 
		{
			int target = cvarLrgTargetOpts.IntValue;	
			if (options > target)
				return target;
		}
	}		

	// If the option count is greater than max, we must use max anyways	
	int max = cvarPrefOptionCount.IntValue;
	if (options > max)
		return max;
	
	return options;
}
