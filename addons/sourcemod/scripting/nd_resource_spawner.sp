#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>
#include <nd_stype>
#include <nd_fskill>
#include <autoexecconfig>
#include <nd_resource_eng>

// Note: To caculate z vector, crouch and subtract 40
public Plugin myinfo =
{
    name = "[ND] Resource Spawner",
    author = "Xander, Stickz",
    description = "Add additional resource points to maps.",
    version = "dummy",
    url = "https://github.com/stickz/Redstone"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_resource_spawner/nd_resource_spawner.txt"
#include "updater/standard.sp"

#define FIRST_TIER 	0
#define SECOND_TIER 	1

#define SKILL_LOW 	0
#define SKILL_HIGH 	1

bool tertsSpawned[2] = { false, ... };

/* Plugin Convars */
ConVar cvarMarsTertiarySpawns;
ConVar cvarOasisTertiarySpawns;
ConVar cvarCoastTertiarySpawns;
//ConVar cvarCornerTertiarySpawns;
ConVar cvarNuclearTertiarySpawns;
ConVar cvarRoadworkTertiarySpawns;
ConVar cvarDowntownTertiarySpawns;
ConVar cvarGateTertiarySpawns[2];
ConVar cvarRockTertiarySpawns[2];
ConVar cvarOilfeildTertiarySpawns[2];
ConVar cvarClocktowerTertiarySpawns[2];

ConVar cvarSpawnSkill[2];

// Store alpha spawns in seperate file to reduce clutter
#include "nd_res_spawn/alpha.sp"

// Allow root to spawn tertiary to test them
#include "nd_res_spawn/commands.sp"

public void OnPluginStart()
{
	CreatePluginConvars();
	
	RegAdminSpawnCmds();
	
	AutoExecConfig(true, "nd_res_spawner");
	
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
	
	CreateSkillConvars();	
	CreateMapConvars();
}

void CreateSkillConvars()
{
	// Set the file to the thresholds to control player skill
	AutoExecConfig_SetFile("nd_res_skill");
	
	// Create the convars to control the high and lowest skill thresholds
	cvarSpawnSkill[SKILL_LOW] = AutoExecConfig_CreateConVar("sm_res_slow", "60", "Sets the skill for the lowest tertiary spawn threshold.");
	cvarSpawnSkill[SKILL_HIGH] = AutoExecConfig_CreateConVar("sm_res_shigh", "110", "Sets the skill for the highest tertiary spawn threshold.");
	
	// Execute and clean the configuration file
	AutoExecConfig_EC_File();
}

void CreateMapConvars()
{
	// Set the file to the resource spawner
	AutoExecConfig_SetFile("nd_res_maps");
	
	// Create convars for resoruce spawning on a per map basis
	cvarMarsTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_mars", "16", "Sets number of players to spawn extra tertaries on mars.");
	cvarOasisTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_oasis", "18", "Sets number of players to spawn extra tertaries on oasis.");
	cvarCoastTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_coast", "16", "Sets number of players to spawn extra tertaries on coast.");	
	//cvarCornerTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_corner", "20", "Sets number of players to spawn extra tertaries on corner.");
	cvarNuclearTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_nuclear", "14", "Sets number of players to spawn extra tertaries on nuclear.");
	cvarRoadworkTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_roadwork", "16", "Sets number of players to spawn extra tertaries on roadwork.");
	cvarDowntownTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_downtown", "28", "Sets number of players to spawn extra tertaries on downtown and downtown_dyn.");
	cvarGateTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_gate1", "16", "Sets number of players to spawn extra tertaries on gate.");
	cvarGateTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_gate2", "22", "Sets number of players to spawn extra tertaries on gate.");
	cvarRockTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_rock1", "8", "Sets number of players to spawn extra tertaries on rock.");
	cvarRockTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_rock2", "16", "Sets number of players to spawn extra tertaries on rock.");
	cvarOilfeildTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_oilfeild1", "12", "Sets number of players to spawn extra tertaries on oilfield.");
	cvarOilfeildTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_oilfeild2", "20", "Sets number of players to spawn extra tertaries on oilfield.");
	cvarClocktowerTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_clocktower1", "24", "Sets number of players to spawn extra tertaries on clocktower.");
	cvarClocktowerTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_clocktower2", "18", "Sets number of players to spawn extra tertaries on clocktower.");

	// Execute and clean the configuration file
	AutoExecConfig_EC_File();
}

public void OnClientPutInServer(int client)
{	
	if (ND_RoundStarted())
	{
		if (!tertsSpawned[SECOND_TIER])
		{
			int serverType = ND_GetServerTypeEx();
			if (serverType >= SERVER_TYPE_STABLE)
			{
				CheckStableSpawns();

				if (serverType >= SERVER_TYPE_BETA)
				{
					CheckBetaSpawns();

					if (serverType >= SERVER_TYPE_ALPHA)
						CheckTertiarySpawns();
				}
			}
		}
	}
}

public void ND_OnRoundStarted()
{
	tertsSpawned[FIRST_TIER] = false;
	tertsSpawned[SECOND_TIER] = false;
	
	int serverType = ND_GetServerTypeEx();
	if (serverType >= SERVER_TYPE_STABLE)
	{
		AdjustStableSpawns();
		CheckStableSpawns();
		
		if (serverType >= SERVER_TYPE_BETA)
		{
			AdjustBetaSpawns();
			CheckBetaSpawns();
			
			if (serverType >= SERVER_TYPE_ALPHA)
			{
				AdjustTertiarySpawns();
				CheckTertiarySpawns();
			}
		}
	}
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
		int hCount 	= ND_PrimeDepleted() 
					? GetSpawnCount(6, 6, 8)
					: GetSpawnCount(14, 16, 18);
		
		if (RED_OnTeamCount() >= hCount)
		{
			ND_SpawnTertiaryPoint({-5402.0, -3859.0, 74.0});
			ND_SpawnTertiaryPoint({2340.0, 2558.0, 10.0});
			tertsSpawned[SECOND_TIER] = true;			
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		int hCount 	= ND_PrimeDepleted() 
					? GetSpawnCount(10, 10, 12)
					: GetSpawnCount(20, 22, 24);
		
		if (RED_OnTeamCount() >= hCount)
		{
			// Respawn tunnel resources			
			ND_SpawnTertiaryPoint({-1674.0, 1201.0, -1848.0});
			ND_SpawnTertiaryPoint({-2564.0, 282.0, -1672.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	/*else if (ND_CustomMapEquals(map_name, ND_Corner))
	{
		if (RED_OnTeamCount() >= cvarCornerTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({-3485.0, 11688.0, 5.0});
			ND_SpawnTertiaryPoint({-1947.0, -1942.0, 7.0});
			tertsSpawned[SECOND_TIER] = true;		
		}
	}*/
	
	else if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		if (RED_OnTeamCount() >= GetSpawnCount(26, 28, 30))
		{
			ND_SpawnTertiaryPoint({2385.0, -5582.0, -3190.0});
			ND_SpawnTertiaryPoint({-2668.0, -3169.0, -2829.0});
			tertsSpawned[SECOND_TIER] = true;		
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Hydro))
	{
		int hCount 	= ND_PrimeDepleted() 
					? GetSpawnCount(12, 14, 16)
					: GetSpawnCount(26, 28, 28);
							
		if (RED_OnTeamCount() >= hCount)
		{
			ND_SpawnTertiaryPoint({2132.0, 2559.0, 18.0});
			ND_SpawnTertiaryPoint({-5199.0, -3461.0, 191.0});
			tertsSpawned[SECOND_TIER] = true;	
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		if (!tertsSpawned[FIRST_TIER])
		{
			ND_SpawnTertiaryPoint({2335.0, -3557.0, -375.0});
			tertsSpawned[FIRST_TIER] = true;
		}		
	}
}

void CheckBetaSpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Gate))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarGateTertiarySpawns[FIRST_TIER].IntValue)
		{
			if (!tertsSpawned[FIRST_TIER])
			{
				ND_SpawnTertiaryPoint({-5824.0, -32.0, 0.0});
				ND_SpawnTertiaryPoint({3392.0, 0.0, 5.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarGateTertiarySpawns[SECOND_TIER].IntValue)
			{
				ND_SpawnTertiaryPoint({-3392.0, -2384.0, 0.0});
				ND_SpawnTertiaryPoint({-3456.0, 2112.0, -16.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}
	}
}

void AdjustStableSpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		// Remove tunnel resources
		ND_RemoveTertiaryPoint("tertiary_1", "tertiary_area1");	
		ND_RemoveTertiaryPoint("tertiary_tunnel", "tertiary_tunnel_area");
		
		// Spawn new tertiary near consort base
		// So empire + consort have same resource acess
		ND_SpawnTertiaryPoint({2181.0, 4161.0, -1380.0});
	}
}

void AdjustBetaSpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Gate))
	{
		// Tertaries by the secondaries
		ND_RemoveTertiaryPoint("tertiary01", "tertiary_area01");
		ND_RemoveTertiaryPoint("tertiary04", "tertiary_area04");
		
		// Tertaries by the secondary and prime
		ND_RemoveTertiaryPoint("tertiary013", "tertiary_area013");
		ND_RemoveTertiaryPoint("tertiary07", "tertiary_area07");
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
