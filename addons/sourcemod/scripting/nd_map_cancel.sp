#include <sourcemod>
#include <mapchooser>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_mvote>
#include <nd_redstone>
#include <nd_maps>
#include <nd_stype>
#include <nd_mlist>

public Plugin myinfo =
{
    name = "[ND] Map Cancel",
    author = "Stickz",
    description = "Cancels cycling to maps based on certain conditions",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_map_cancel/nd_map_cancel.txt"
#include "updater/standard.sp"

ConVar cvarUsePlayerThresolds;
//ConVar cvarStockMapCount;

public void OnPluginStart()
{
	cvarUsePlayerThresolds	= CreateConVar("sm_mcancel_thresholds", "1", "Specifies wehter or not to cancel map cycling by player count");
	//cvarStockMapCount	= CreateConVar("sm_mcancel_stock", "23", "Sets the maximum number of players for stock maps");
	
	LoadTranslations("nd_map_management.phrases"); //load the plugin's translations	
	AutoExecConfig(true, "nd_mcancel");
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientPutInServer(int client)
{
	// Only check map thresholds if the round is started and the map voter isn't running
	if (cvarUsePlayerThresolds.BoolValue && CanStartMapVote())
		checkMapExcludes();
}

bool CanStartMapVote() {
	return ND_RoundStarted() && CanMapChooserStartVote();
}

bool MapNotInVoterList(char[] nextMap) 
{
	ArrayList voteList = ND_GetMapVoteList();	
	int index = voteList.Length - 1;
	
	while (index >= 0)
	{
		// Get the map name, and trim it for comparison
		char mapName[32];
		voteList.GetString(index, mapName, sizeof(mapName));
		TrimString(mapName);
		
		if (StrEqual(mapName, nextMap, true))
			return true;
			
		index--;
	}
	
	return false;	
}

void TriggerMapVote(char[] nextMap)
{
	if (CanStartMapVote() && !MapNotInVoterList(nextMap))
	{	
		PrintToChatAll("\x05[xG] %t", "Retrigger Map Vote", nextMap);	
		ND_TriggerMapVote();
	}	
}

void checkMapExcludes()
{
	char nextMap[32];
	GetNextMap(nextMap, sizeof(nextMap));
	
	int clientCount = ND_GetClientCount();
	
	if (clientCount < 12)
	{
		if (	ND_GetServerTypeEx() != SERVER_TYPE_BETA &&
			StrEqual(nextMap, ND_StockMaps[ND_Gate], false))
		{
			TriggerMapVote(nextMap);
			return;
		}		
		
		else if (StrEqual(nextMap, ND_StockMaps[ND_Downtown], false) ||
			StrEqual(nextMap, ND_StockMaps[ND_Oilfield], false) ||
			StrEqual(nextMap, ND_CustomMaps[ND_Nuclear], false))
		{
			TriggerMapVote(nextMap);
			return;	
		}		
			
		if (clientCount < 8)
		{
			if (StrEqual(nextMap, ND_CustomMaps[ND_Rock], false))
			{
				TriggerMapVote(nextMap);
				return;					
			}				
		}
	}
	
	else if (clientCount >= 10)
	{
		if (StrEqual(nextMap, ND_CustomMaps[ND_Sandbrick], false))
		{
			TriggerMapVote(nextMap);
			return;
		}
		
		if (clientCount >= 18)
		{		
			if (	StrEqual(nextMap, ND_CustomMaps[ND_Mars], false) || 
				StrEqual(nextMap, ND_CustomMaps[ND_Corner], false))
			{
				TriggerMapVote(nextMap);
				return;
			}
			
			/*if (clientCount > cvarStockMapCount.IntValue && 
			     (StrEqual_PopularMap(nextMap) || StrEqual(nextMap, ND_StockMaps[ND_Silo], false)))
			{
				TriggerMapVote(nextMap);
				return;
			}*/
		}
	}
}

/*int ndsPopular[SP_MAP_SIZE] = {
	view_as<int>(ND_Hydro),
	view_as<int>(ND_Oasis),
	view_as<int>(ND_Coast),
	view_as<int>(ND_Silo),
	view_as<int>(ND_Metro)
}

bool StrEqual_PopularMap(char[] checkMap)
{
	for (int idx = 0; idx < SP_MAP_SIZE; idx++) {
		if (StrEqual(checkMap, ND_StockMaps[ndsPopular[idx]], false))
			return true;
	}
	
	return false;
}*/
