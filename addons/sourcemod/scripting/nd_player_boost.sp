#include <sourcemod>
#include <nd_stocks>
#include <nd_maps>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_team_eng>

public Plugin myinfo =
{
	name = "[ND] Player Boost",
	author = "Stickz",
	description = "Rebalances player boost with lower player counts",
	version = "dummy",
	url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_player_boost/nd_player_boost.txt"
#include "updater/standard.sp"

#include "nd_res_trickle/constants.sp"

bool currentState = false;

int mapPlayerCount = 0;

public void OnPluginStart()
{
	AddUpdaterLibrary(); // Auto-Updater support
	
	if (ND_RoundStarted())
		ND_OnPreRoundStart();
}

public void OnMapStart()
{
	// Get the current map
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Check if the current map is a medium or large map
	bool largeMap = ND_IsLargeResMap();
	bool mediumMap = ND_IsMediumResMap();
	
	// Get the player count where the resources are reduced in some form
	if (largeMap)	
		mapPlayerCount = TRICKLE_REDUCE_COUNT_LRG;
	else if (mediumMap)
		mapPlayerCount = TRICKLE_REDUCE_COUNT_MED;
	else
		mapPlayerCount = FRACKING_MIN_PLYS;	
}

public void ND_OnPreRoundStart()
{
	currentState = false;
	RefreshPlayerBoost();
}

public void ND_OnPlayerTeamChanged(int client, bool valid)
{	
	if (ND_RoundStarted())
		RefreshPlayerBoost();
}

public void OnDamageChanged(ConVar convar, char[] oldValue, char[] newValue) 
{	
	if (ND_RoundStarted())
		ND_OnPreRoundStart();
}

void RefreshPlayerBoost()
{
	bool normal = RED_OnTeamCount() >= mapPlayerCount;
	
	if (currentState != normal)
	{	
		currentState = normal;
		SetPlayerBoost(normal);
	}
}

void SetPlayerBoost(bool normal)
{
	if (normal)
	{
		ServerCommand("sm_cvar nd_playerboost_health_bonus %.2f", 0.05);
		ServerCommand("sm_cvar nd_playerboost_health_bonus2 %.2f", 0.1);
		ServerCommand("sm_cvar nd_playerboost_health_bonus3 %.2f", 0.15);
	}
	
	else
	{
		ServerCommand("sm_cvar nd_playerboost_health_bonus %.2f", 0.1);
		ServerCommand("sm_cvar nd_playerboost_health_bonus2 %.2f", 0.15);
		ServerCommand("sm_cvar nd_playerboost_health_bonus3 %.2f", 0.2);
	}
}
