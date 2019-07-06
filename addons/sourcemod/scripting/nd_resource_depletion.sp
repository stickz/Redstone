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
	description 	= "Depletes the primary resource early on some maps",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_depletion/nd_resource_depletion.txt"
#include "updater/standard.sp"

ConVar cvarEnableDepletion;
ConVar cvarDepletePlayerCount;

ArrayList listSecondaries;
ArrayList listTertiaries;

public void OnPluginStart()
{
	/* Create plugin convars */
	AutoExecConfig_SetFile("nd_res_deplete");
	cvarEnableDepletion 		=	AutoExecConfig_CreateConVar("sm_enable_depletion", "1", "Sets wether to enable depletion 0:disabled, 1:enabled");
	cvarDepletePlayerCount 		= 	AutoExecConfig_CreateConVar("sm_resource_deplete", "12", "Sets number of players to deplete the primary resource");
	AutoExecConfig_EC_File();
	
	/* Initialize corner varriables */
	listSecondaries = new ArrayList(6);
	listTertiaries = new ArrayList(18);
	
	// Register an admin command to test this feature
	RegAdminCmd("sm_DisableTrickle", CMD_DisableTrickle, ADMFLAG_ROOT, "disable resource point trickling");
	
	AddUpdaterLibrary(); // Add auto updater feature
}

public void OnMapStart() 
{
	/* Initialize varriables */
	listSecondaries.Clear();
	listTertiaries.Clear();
	
	// Store entity index of all secondaries and tertaries on the map
	CreateTimer(5.0, TIMER_SetEntityClasses, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnRoundStarted() 
{
	// Get the current map name
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
		
	// Check the prime depletion feature is enabled. Check if the player count is low enough to use.
	if (cvarEnableDepletion.BoolValue && ND_GetClientCount() <= cvarDepletePlayerCount.IntValue)
	{
		// Check if the map is Metro or Hydro
		if (ND_MapEqualsAnyMetro(map_name) || ND_StockMapEquals(map_name, ND_Hydro))
		{
			// Deplete prime of all the primary resources			
			CreateTimer(5.0, TIMER_DepletePrime, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	// Check if corner is ready for the trickle disable feature yet
	CreateTimer(3.0, TIMER_CheckCornerTrickle, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_DepletePrime(Handle timer) 
{
	ND_SetPrimeResources(0);
	return Plugin_Continue;
}

public Action TIMER_CheckCornerTrickle(Handle timer) 
{
	SetCornerTrickleDisable();
	return Plugin_Continue;
}

public Action TIMER_SetEntityClasses(Handle timer)
{
	SetSecondariesList();
	SetTertariesList();
	return Plugin_Continue;
}

public Action CMD_DisableTrickle(int client, int arg)
{
	PrintToChat(client, "debug: command ran");
	SetUnlimitedTrickleResources();
	PrintTrickleDisabled();
	return Plugin_Handled;
}

void SetSecondariesList()
{
	// Loop through all entities finding the secondaries
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "nd_info_secondary_resource_point")) != INVALID_ENT_REFERENCE)
	{
		// Cache the secondary entity index when found
		listSecondaries.Push(loopEntity);
	}
}
void SetTertariesList()
{
	// Loop through all entities finding the tertaries
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "nd_info_tertiary_resource_point")) != INVALID_ENT_REFERENCE)
	{
		// Cache the tertary entity index when found
		listTertiaries.Push(loopEntity);
	}
}

void SetCornerTrickleDisable()
{		
	// Get the current map name
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
		
	if (ND_CustomMapEquals(map_name, ND_Corner))
	{
		SetUnlimitedTrickleResources();			
		PrintTrickleDisabled();
	}	
}
void SetUnlimitedTrickleResources()
{
	ND_SetPrimeResources(999999);
			
	for (int s = 0; s < listSecondaries.Length; s++) 
	{
		int sec = listSecondaries.Get(s);
		ND_SetCurrentResources(sec, 999999);				
	}
			
	for (int t = 0; t < listTertiaries.Length; t++) 
	{
		int tert = listTertiaries.Get(t);
		ND_SetCurrentResources(tert, 999999);				
	}	
}

void PrintTrickleDisabled()
{
	PrintToChatAll("\x05[xG] Trickling Disabled! Set 100%% resource production!");
	PrintToChatAll("\x05[xG] After 26m, production will no longer drop 45%% !");
}
