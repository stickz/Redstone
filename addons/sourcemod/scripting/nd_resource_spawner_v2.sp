#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>
#include <nd_fskill>
#include <autoexecconfig>
#include <nd_resource_eng>

// Note: To caculate z vector, crouch and subtract 40
public Plugin myinfo =
{
    name = "[ND] Resource Spawner V2",
    author = "Xander, Stickz",
    description = "Add additional resource points to maps.",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_spawner_v2/nd_resource_spawner_v2.txt"
#include "updater/standard.sp"

#define FIRST_TIER 	0
#define SECOND_TIER 	1

#define SKILL_LOW 		0
#define SKILL_HIGH 	1

bool tertsSpawned[2] = { false, ... };

ConVar cvarSpawnSkill[2];

public void OnPluginStart()
{
	CreatePluginConvars();	
	AddUpdaterLibrary(); //auto-updater
}

public void OnConfigsExecuted()
{
	// Fire round start event if plugin loads late
	if (ND_RoundStarted())
		ND_OnRoundStarted();
}

void CreatePluginConvars()
{
	// Tell the wrapper to create the files. Required for multiples.
	AutoExecConfig_SetCreateFile(true);
	
	// Set the file to the thresholds to control player skill
	AutoExecConfig_SetFile("nd_res_skill");
	
	// Create the convars to control the high and lowest skill thresholds
	cvarSpawnSkill[SKILL_LOW] = AutoExecConfig_CreateConVar("sm_res_slow", "60", "Sets the skill for the lowest tertiary spawn threshold.");
	cvarSpawnSkill[SKILL_HIGH] = AutoExecConfig_CreateConVar("sm_res_shigh", "110", "Sets the skill for the highest tertiary spawn threshold.");
	
	// Execute and clean the configuration file
	AutoExecConfig_EC_File();	
}

public void OnClientPutInServer(int client)
{	
	if (ND_RoundStarted())
	{
		if (!tertsSpawned[SECOND_TIER])
		{
			CheckStableSpawns();
		}
	}
}

public void ND_OnRoundStarted()
{
	tertsSpawned[FIRST_TIER] = false;
	tertsSpawned[SECOND_TIER] = false;
	
	CheckStableSpawns();		
}

void CheckStableSpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	// Will throw tag mismatch warning, it's okay
	if (ND_CustomMapEquals(map_name, ND_Submarine))
	{
		if (!tertsSpawned[FIRST_TIER])
		{
			// Center map tertiary resource points
			ND_SpawnTertiaryPoint({-1475.0, 3475.0, -33.0});
			ND_SpawnTertiaryPoint({-1000.0, -3820.0, -216.0});
			ND_SpawnTertiaryPoint({1350.0, -2153.0, 20.0});
			ND_SpawnTertiaryPoint({2495.0, 5775.0, 150.0});
			tertsSpawned[FIRST_TIER] = true;
		}
		
		if (RED_OnTeamCount() >= GetSpawnCount(20, 22, 24))
		{
			// Base tertiary resource points
			ND_SpawnTertiaryPoint({987.0, -7562.0, 23.0});  
			ND_SpawnTertiaryPoint({-1483.0, 9135.0, 123.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_MapEqualsAnyMetro(map_name))
	{
		int hCount 	= ND_PrimeDepleted() 
					? GetSpawnCount(6, 6, 8)
					: GetSpawnCount(14, 16, 18);
		
		if (RED_OnTeamCount() >= hCount)
		{
			ND_SpawnTertiaryPoint({2620.0, 529.0, 5.0});
			ND_SpawnTertiaryPoint({-2235.0, -3249.0, -85.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Silo))
	{
		int teamCount = RED_OnTeamCount();
		bool primeDepleted = ND_PrimeDepleted();
		
		if (!tertsSpawned[FIRST_TIER])
		{
			int fCount 	= primeDepleted 
						? GetSpawnCount(8, 8, 10)
						: GetSpawnCount(20, 24, 26);
			
			if (teamCount >= fCount)
			{
				ND_SpawnTertiaryPoint({-5402.0, -3859.0, 74.0});
				ND_SpawnTertiaryPoint({2340.0, 2558.0, 10.0});
				tertsSpawned[FIRST_TIER] = true;
			}
		}
		
		int sCount 	= primeDepleted
					? GetSpawnCount(16, 16, 18)
					: GetSpawnCount(24, 26, 28);
		
		if (teamCount >= sCount)
		{
			ND_SpawnTertiaryPoint({-3375.0, 1050.0, 2.0});
			ND_SpawnTertiaryPoint({-36.0, -2000.0, 5.0});
			tertsSpawned[SECOND_TIER] = true;			
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Hydro))
	{
		int hCount 	= ND_PrimeDepleted() 
					? GetSpawnCount(12, 14, 16)
					: GetSpawnCount(24, 26, 28);
							
		if (RED_OnTeamCount() >= hCount)
		{
			ND_SpawnTertiaryPoint({2132.0, 2559.0, 18.0});
			ND_SpawnTertiaryPoint({-5199.0, -3461.0, 191.0});
			tertsSpawned[SECOND_TIER] = true;	
		}
	}
}

int GetSpawnCount(int min, int med, int max)
{
	// If the average skill function is not availible, return the middle threshold
	if (!ND_GEA_AVAILBLE())
		return med;

	// Get the average skill on the server
	float avSkill = ND_GetEnhancedAverage();
	
	// Check if average skill is greater than the min or med thresholds
	if (avSkill >= cvarSpawnSkill[SKILL_HIGH])
		return min;	
	else if (avSkill >= cvarSpawnSkill[SKILL_LOW])
		return med;

	// If not, return the maximum number of players to spawn extra tertaries
	return max;
}
