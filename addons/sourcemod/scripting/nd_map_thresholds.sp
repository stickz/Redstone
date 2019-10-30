#include <sourcemod>
#include <nd_maps>
#include <nd_stype>
#include <nd_stocks>
#include <smlib/math>
#include <nd_redstone>

public Plugin myinfo =
{
    name = "[ND] Map Thresholds",
    author = "Stickz",
    description = "Creates a list of map vote options based on current conditions",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_map_thresholds/nd_map_thresholds.txt"
#include "updater/standard.sp"

ArrayList g_MapThresholdList;
ConVar cvarStockMapCount;
ConVar cvarCornerMapCount;

public void OnPluginStart() 
{
	g_MapThresholdList 	= 	new ArrayList(ND_MAX_MAP_SIZE);
	cvarStockMapCount	=	CreateConVar("sm_voter_scount", "23", "Sets the maximum number of players for stock maps");
	cvarCornerMapCount	=	CreateConVar("sm_voter_ccount", "20", "Sets the maximum number of players for corner");
	RegAdminCmd("sm_DebugMapVote", CMD_DebugMapVote, ADMFLAG_KICK, "Debugs the map vote list");
	
	AddUpdaterLibrary(); //auto-updater
}

/* Handle shipping the map vote list to other plugins */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetMapVoteList", Native_GetMapVoteList);
	return APLRes_Success;
}
public int Native_GetMapVoteList(Handle plugin, int numParams) 
{
	CreateMapThresholdList();
	return _:g_MapThresholdList;
}

/* Handle debugging the map voter list: print to console */
public Action CMD_DebugMapVote(int client, int args)
{
	CreateMapThresholdList(true);
	return Plugin_Handled;
}
void PrintMapVoteList()
{
	ConsoleToAdmins("--> Map Vote List <--", "a");
	for (int idx = 0; idx < g_MapThresholdList.Length; idx++)
	{
		char mapName[32];
		g_MapThresholdList.GetString(idx, mapName, sizeof(mapName));
		ConsoleToAdmins(mapName, "a");
	}
}

/* Handle nominating maps by chance */
void ND_NominateMap(char[] mapName, float fChance = 100.0)
{
	if (!StrEqualCurrentMap(mapName) && NominateByChance(RoundFloat(fChance)))
	{
		TrimString(mapName);
		g_MapThresholdList.PushString(mapName);
	}	
}
bool StrEqualCurrentMap(char[] checkMap)
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	return StrEqual(checkMap, currentMap, false);
}
bool NominateByChance(int chance) {
	return chance >= 100 || GetRandomInt(1, 100) <= chance;	
}

/* Handle creating the map vote list */
void CreateMapThresholdList(bool debugFunction = false)
{		
	g_MapThresholdList.Clear(); //clear the map list array
	
	/* Cast a few varriables we're going to need */
	int clientCount = ND_GetClientCount();
	int serverType = ND_GetServerTypeEx();
	
	// Always allow cycling of metro and silo
	ND_NominateMap(ND_StockMaps[ND_Metro]);
	ND_NominateMap(ND_StockMaps[ND_Silo]);
	
	// Always allow clocktower and roadwork in map voting
	// But restrict decrease cycling with less players
	float resAdjust = 60 + 2.5 * clientCount;
	ND_NominateMap(ND_StockMaps[ND_Clocktower], resAdjust);
	
	/* Run through the 'less than' x players to include maps */		
	if (clientCount <= cvarStockMapCount.IntValue)
	{
		ND_NominatePopularMaps();
		
		if (clientCount <= cvarCornerMapCount.IntValue)
		{		
			ND_NominateMap(ND_CustomMaps[ND_Corner]);

			if (clientCount < 8)
				ND_NominateMap(ND_CustomMaps[ND_Sandbrick], 80.0);
		}
	}
	
	if (clientCount >= 6)
	{
		float plyAdjust = 1.5 * (clientCount - 14);		
		ND_NominateMap(ND_CustomMaps[ND_Roadwork], 60 + plyAdjust);

		/* Run through the 'greater than' x players to include maps */
		if (clientCount >= 14)
		{
			ND_NominateMap(ND_CustomMaps[ND_Submarine], 50 + plyAdjust);			
			ND_NominateMap(ND_CustomMaps[ND_Nuclear], 60 + plyAdjust);
			
			if (clientCount >= 18)
			{
				ND_NominateMap(ND_StockMaps[ND_Oilfield], 50 + plyAdjust);
				ND_NominateMap(ND_StockMaps[ND_Downtown], 88 + plyAdjust);		
				ND_NominateMap(ND_CustomMaps[ND_Rock], 60 + plyAdjust);
				ND_NominateMap(ND_StockMaps[ND_Gate], 70 + plyAdjust);			
			}
		}
	}
	
	if (debugFunction)
		PrintMapVoteList();
}

/* Handle nominating the popular maps */
#define SP_MAP_SIZE 3
int ndsPopular[SP_MAP_SIZE] = {
	view_as<int>(ND_Hydro),
	view_as<int>(ND_Oasis),
	view_as<int>(ND_Coast)
}
void ND_NominatePopularMaps() {	
	for (int idx = 0; idx < SP_MAP_SIZE; idx++) {
		ND_NominateMap(ND_StockMaps[ndsPopular[idx]]);	
	}	
}
