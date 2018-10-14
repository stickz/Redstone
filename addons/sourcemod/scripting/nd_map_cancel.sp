#include <sourcemod>
#include <mapchooser>
#include <nd_rounds>
#include <nd_mvote>
#include <nd_redstone>
#include <nd_maps>
#include <nd_stype>

ConVar cvarUsePlayerThresolds;

public void OnPluginStart()
{
	cvarUsePlayerThresolds	= CreateConVar("sm_mcanel_thresholds", "1", "Specifies wehter or not to cancel map cycling by player count");
	LoadTranslations("nd_map_management.phrases"); //load the plugin's translations	
	AutoExecConfig(true, "nd_mcancel");
}

public void OnClientPutInServer(int client)
{
	// Only check map thresholds if the round is started and the map voter isn't running
	if (cvarUsePlayerThresolds.BoolValue && ND_RoundStarted() && CanMapChooserStartVote())
		checkMapExcludes();
}

void TriggerMapVote()
{
	if (ND_RoundStarted() && CanMapChooserStartVote())
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
			TriggerMapVote();
			return;
		}		
		
		else if (StrEqual(nextMap, ND_StockMaps[ND_Downtown], false) ||
			StrEqual(nextMap, ND_StockMaps[ND_Oilfield], false) ||
			StrEqual(nextMap, ND_CustomMaps[ND_Nuclear], false))
		{
			TriggerMapVote();
			return;	
		}		
			
		if (clientCount < 8)
		{
			if (StrEqual(nextMap, ND_CustomMaps[ND_Rock], false))
			{
				TriggerMapVote();
				return;					
			}				
		}
	}
	
	else if (clientCount >= 10)
	{
		if (StrEqual(nextMap, ND_CustomMaps[ND_Sandbrick], false))
		{
			TriggerMapVote();
			return;
		}
		
		if (clientCount >= 18)
		{		
			if (	StrEqual(nextMap, ND_CustomMaps[ND_Mars], false) || 
				StrEqual(nextMap, ND_CustomMaps[ND_Corner], false))
			{
				TriggerMapVote();
				return;
			}
			
			/*if (clientCount > cvarStockMapCount.IntValue && 
			     (StrEqual_PopularMap(nextMap) || StrEqual(nextMap, ND_StockMaps[ND_Silo], false)))
			{
				ChangeMapByPlayerCount(CHANGE_TYPE_HIGH, nextMap, roundEnd);
				return;
			}*/
		}
	}
}
