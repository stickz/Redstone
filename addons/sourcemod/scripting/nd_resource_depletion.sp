#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_entities>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>
#include <nd_resource_eng>
#include <autoexecconfig>

#define EXTRA_RESOURCES 150

public Plugin myinfo = 
{
	name 		= "[ND] Resource Depletion",
	author 		= "Stickz",
	description 	= "Depletes the primary resource early on some maps",
	version 	= "recompile",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_depletion/nd_resource_depletion.txt"
#include "updater/standard.sp"

ConVar cvarEnableDepletion;
ConVar cvarDepletePlayerCount;
ConVar cvarCornerTrickleMin;
ConVar cvarCornerTricklePrime;

ArrayList listSecondaries;
ArrayList listTertiaries;

bool setCorner = false;

public void OnPluginStart()
{
	/* Create plugin convars */
	AutoExecConfig_SetFile("nd_res_deplete");
	cvarEnableDepletion 		=	AutoExecConfig_CreateConVar("sm_enable_depletion", "1", "Sets wether to enable depletion 0:disabled, 1:enabled");
	cvarDepletePlayerCount 		= 	AutoExecConfig_CreateConVar("sm_resource_deplete", "12", "Sets number of players to deplete the primary resource");
	
	cvarCornerTrickleMin		= 	AutoExecConfig_CreateConVar("sm_resource_trickle_cmin", "8", "Specifies min number of players on corner to disable trickling");
	cvarCornerTricklePrime		= 	AutoExecConfig_CreateConVar("sm_resource_trickle_cmin", "10", "Specifies min number of players to trickle prime on corner");
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
}

public void ND_OnResPointsCached()
{
	listSecondaries = ND_GetSecondaryList();
	listTertiaries = ND_GetTertiaryList();	
}

public void ND_OnRoundStarted() 
{
	/* Initialize varriables */
	setCorner = false;
	
	// Get the current map name
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
		
	// Check the prime depletion feature is enabled. Check if the player count is low enough to use.
	if (cvarEnableDepletion.BoolValue && ND_GetClientCount() <= cvarDepletePlayerCount.IntValue)
	{
		// Check if the map is Metro or Hydro
		if (	ND_MapEqualsAnyMetro(map_name) || 
				ND_StockMapEquals(map_name, ND_Hydro) || 
				ND_StockMapEquals(map_name, ND_Coast) ||
				ND_CustomMapEquals(map_name, ND_Sandbrick))
		{
			// Deplete prime of all the primary resources			
			CreateTimer(5.0, TIMER_DepletePrime, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	// Check if corner is ready for the trickle disable feature yet
	if (disableTrickCorner())
		CreateTimer(3.0, TIMER_CheckCornerTrickle, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Check every 15s to see if prime and both secondaries are owned by the same team
	CreateTimer(15.0, TIMER_CheckMainResourcesOwned, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client) {
	if (!setCorner && ND_RoundStarted() && disableTrickCorner()) {
		SetCornerTrickleDisable();
	}
}

bool disableTrickCorner() {
	return ND_GetClientCount() >= cvarCornerTrickleMin.IntValue;
}

bool trickleCornerPrime() {
	return ND_GetClientCount() >= cvarCornerTricklePrime.IntValue;
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

public Action TIMER_CheckMainResourcesOwned(Handle timer)
{
	// Check if the main resource points are owned by the same team
	// Also check if the resource points are not all owned by nobody
	int mainPoints = MainPointsOwnedByTeam();	
	if (mainPoints != TEAM_EMPIRE && mainPoints != TEAM_CONSORT)
		return Plugin_Continue;
	
	// Get the tertiary closest to the bunker for the other team
	int otherTeam = getOtherTeam(mainPoints);
	int closestTert = GetTertiaryClosestToBunker(otherTeam);
	
	// Get the amount of resources to add to the tertiary closest to the bunker
	int curRes = GetEntProp(closestTert, Prop_Send, "m_iCurrentResources");	
	int amount = curRes <= 0 ? EXTRA_RESOURCES : curRes + EXTRA_RESOURCES;
	
	// Update the resoruces of the tertiary closest to the bunker and continue
	ND_SetCurrentResources(closestTert, amount);
	return Plugin_Continue;
}

int MainPointsOwnedByTeam()
{
	int primeOwner = ND_GetPrimeOwner();	
	
	for (int s = 0; s < listSecondaries.Length; s++)
	{
		int sec = listSecondaries.Get(s);
		
		if (ND_GetResourceOwner(sec) != primeOwner)
			return TEAM_NONE;
	}			

	return primeOwner;
}

int GetTertiaryClosestToBunker(int team)
{
	// Get the first tertiary and it's position from the bunker
	int tertiary = listTertiaries.Get(0);
	float bunkerDist = ND_GetEntityBunkerDistance(team, tertiary);
	
	// Loop through all the remaining tertaries in the ArrayList
	for (int t = 1; t < listTertiaries.Length; t++) 
	{
		// Get the tert entity and see if it belongs to the team
		int tert = listTertiaries.Get(t);
		if (ND_GetResourceOwner(tert) == team)
		{
			// Get the bunker distance from the tert entity
			float distance = ND_GetEntityBunkerDistance(team, tert);
			
			// If the distance is less than the previous one, update the tertiary
			if (distance < bunkerDist)
			{
				tertiary = tert;
				bunkerDist = distance;
			}			
		}
	}
	
	return tertiary;	
}

public Action CMD_DisableTrickle(int client, int arg)
{
	PrintToChat(client, "debug: command ran");
	SetUnlimitedTrickleResources(true);
	PrintTrickleDisabled();
	return Plugin_Handled;
}

void SetCornerTrickleDisable()
{		
	if (!setCorner)
	{
		// Get the current map name
		char map_name[64];   
		GetCurrentMap(map_name, sizeof(map_name));
			
		if (ND_CustomMapEquals(map_name, ND_Corner))
		{
			bool prime = trickleCornerPrime();
			SetUnlimitedTrickleResources(prime);
			PrintTrickleDisabled();
			setCorner = true;
		}
	}
}
void SetUnlimitedTrickleResources(bool prime)
{
	if (prime)
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
	PrintToChatAll("\x05[xG] After 26m, production will no longer drop to 45%% !");
}
