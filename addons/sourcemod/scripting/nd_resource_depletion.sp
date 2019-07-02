#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_entities>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>
#include <autoexecconfig>

public Plugin myinfo = 
{
	name 		= "[ND] Resource Depletion",
	author 		= "Stickz",
	description = "Depletes the primary resource early on some maps",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_depletion/nd_resource_depletion.txt"
#include "updater/standard.sp"

ConVar cvarEnableDepletion;
ConVar cvarNumberPlayers;

public void OnPluginStart()
{
	AutoExecConfig_SetFile("nd_res_deplete");
	cvarEnableDepletion 	=	AutoExecConfig_CreateConVar("sm_enable_depletion", "1", "Sets wether to enable depletion 0:disabled, 1:enabled");
	cvarNumberPlayers 		= 	AutoExecConfig_CreateConVar("sm_resource_deplete", "10", "Sets number of players to deplete the primary resource.");
	AutoExecConfig_EC_File();
	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void ND_OnRoundStarted() 
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
		
	if (cvarEnableDepletion.BoolValue && ND_GetClientCount() <= cvarNumberPlayers.IntValue)
	{
		if (ND_MapEqualsAnyMetro(map_name) || 
			ND_StockMapEquals(map_name, ND_Silo) || 
			ND_StockMapEquals(map_name, ND_Hydro))
		{
			ND_SetPrimeResources(0);			
		}
	}
}