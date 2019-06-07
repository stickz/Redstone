#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>
#include <nd_stype>
#include <nd_fskill>
#include <autoexecconfig>

#define TERTIARY_MODEL "models/rts_structures/rts_resource/rts_resource_tertiary.mdl"
#define VECTOR_SIZE 3

#define CAPTURE_RADIUS 200.0
#define nCAPTURE_RADIUS -200.0
 
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

int resSpawnCount = 0;
bool tertsSpawned[2] = { false, ... };

/* Plugin Convars */
ConVar cvarMarsTertiarySpawns;
ConVar cvarMetroTertiarySpawns;
ConVar cvarOasisTertiarySpawns;
ConVar cvarCoastTertiarySpawns;
ConVar cvarCornerTertiarySpawns;
ConVar cvarNuclearTertiarySpawns;
ConVar cvarDowntownTertiarySpawns;
ConVar cvarRoadworkTertiarySpawns;
ConVar cvarSiloTertiarySpawns[2];
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
	AutoExecConfig_EC_File()
}

void CreateMapConvars()
{
	// Set the file to the resource spawner
	AutoExecConfig_SetFile("nd_res_maps");
	
	// Create convars for resoruce spawning on a per map basis
	cvarMarsTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_mars", "16", "Sets number of players to spawn extra tertaries on mars.");
	cvarMetroTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_metro", "18", "Sets number of players to spawn extra tertaries on metro.");	
	cvarOasisTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_oasis", "18", "Sets number of players to spawn extra tertaries on oasis.");
	cvarCoastTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_coast", "16", "Sets number of players to spawn extra tertaries on coast.");	
	cvarCornerTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_corner", "20", "Sets number of players to spawn extra tertaries on corner.");
	cvarNuclearTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_nuclear", "14", "Sets number of players to spawn extra tertaries on nuclear.");
	cvarDowntownTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_downtown", "28", "Sets number of players to spawn extra tertaries on downtown and downtown_dyn.");
	cvarRoadworkTertiarySpawns = AutoExecConfig_CreateConVar("sm_tertiary_roadwork", "16", "Sets number of players to spawn extra tertaries on roadwork.");
	cvarSiloTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_silo1", "14", "Sets number of players to spawn extra tertaries on silo.");
	cvarSiloTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_silo2", "26", "Sets number of players to spawn extra tertaries on silo.");	
	cvarGateTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_gate1", "16", "Sets number of players to spawn extra tertaries on gate.");
	cvarGateTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_gate2", "22", "Sets number of players to spawn extra tertaries on gate.");
	cvarRockTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_rock1", "8", "Sets number of players to spawn extra tertaries on rock.");
	cvarRockTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_rock2", "16", "Sets number of players to spawn extra tertaries on rock.");
	cvarOilfeildTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_oilfeild1", "12", "Sets number of players to spawn extra tertaries on oilfield.");
	cvarOilfeildTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_oilfeild2", "20", "Sets number of players to spawn extra tertaries on oilfield.");
	cvarClocktowerTertiarySpawns[FIRST_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_clocktower1", "20", "Sets number of players to spawn extra tertaries on clocktower.");
	cvarClocktowerTertiarySpawns[SECOND_TIER] = AutoExecConfig_CreateConVar("sm_tertiary_clocktower2", "18", "Sets number of players to spawn extra tertaries on clocktower.");

	// Execute and clean the configuration file
	AutoExecConfig_EC_File()
}

public void OnClientPutInServer(int client) {
	if (!tertsSpawned[SECOND_TIER] && ND_RoundStarted())
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

public void ND_OnRoundStarted()
{
	resSpawnCount = 0;
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
		if (RED_OnTeamCount() >= GetSpawnCount(20, 22, 24))
		{
			// Base tertiary resource points
			SpawnTertiaryPoint({987.0, -7562.0, 23.0});  
			SpawnTertiaryPoint({-1483.0, 9135.0, 123.0});
		}
		
		// Center map tertiary resource points
		SpawnTertiaryPoint({-1475.0, 3475.0, -33.0});
		SpawnTertiaryPoint({-1000.0, -3820.0, -216.0});
		SpawnTertiaryPoint({1350.0, -2153.0, 20.0});
		SpawnTertiaryPoint({2495.0, 5775.0, 150.0});
		tertsSpawned[SECOND_TIER] = true;
	}
	
	else if (ND_MapEqualsAnyMetro(map_name))
	{
		if (RED_OnTeamCount() >= GetSpawnCount(14, 16, 18))
		{
			SpawnTertiaryPoint({2620.0, 529.0, 5.0});
			SpawnTertiaryPoint({-2235.0, -3249.0, -85.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Silo))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarSiloTertiarySpawns[FIRST_TIER].IntValue)
		{
			if (!tertsSpawned[FIRST_TIER])
			{
				SpawnTertiaryPoint({-3375.0, 1050.0, 2.0});
				SpawnTertiaryPoint({-36.0, -2000.0, 5.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= GetSpawnCount(26, 28, 30))
			{
				SpawnTertiaryPoint({-5402.0, -3859.0, 74.0});
				SpawnTertiaryPoint({2340.0, 2558.0, 10.0});
				tertsSpawned[SECOND_TIER] = true;			
			}
		}	
	}
	
	else if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarClocktowerTertiarySpawns[FIRST_TIER].IntValue)
		{
			// Respawn tunnel resources			
			SpawnTertiaryPoint({-1674.0, 1201.0, -1848.0});
			SpawnTertiaryPoint({-2564.0, 282.0, -1672.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Corner))
	{
		if (RED_OnTeamCount() >= cvarCornerTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({-3485.0, 11688.0, 5.0});
			SpawnTertiaryPoint({-1947.0, -1942.0, 7.0});
			tertsSpawned[SECOND_TIER] = true;		
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		if (RED_OnTeamCount() >= GetSpawnCount(26, 28, 30))
		{
			SpawnTertiaryPoint({2385.0, -5582.0, -3190.0});
			SpawnTertiaryPoint({-2668.0, -3169.0, -2829.0});
			tertsSpawned[SECOND_TIER] = true;		
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Hydro))
	{
		if (RED_OnTeamCount() >= GetSpawnCount(26, 28, 28))
		{
			SpawnTertiaryPoint({2132.0, 2559.0, 18.0});
			SpawnTertiaryPoint({-5199.0, -3461.0, 191.0});
			tertsSpawned[SECOND_TIER] = true;	
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
				SpawnTertiaryPoint({-5824.0, -32.0, 0.0});
				SpawnTertiaryPoint({3392.0, 0.0, 5.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarGateTertiarySpawns[SECOND_TIER].IntValue)
			{
				SpawnTertiaryPoint({-3392.0, -2384.0, 0.0});
				SpawnTertiaryPoint({-3456.0, 2112.0, -16.0});
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
		RemoveTertiaryPoint("tertiary_1", "tertiary_area1");	
		RemoveTertiaryPoint("tertiary_tunnel", "tertiary_tunnel_area");
		
		// Spawn new tertiary near consort base
		// So empire + consort have same resource acess
		SpawnTertiaryPoint({1690.0, 4970.0, -1390.0});
	}
}

void AdjustBetaSpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Gate))
	{
		// Tertaries by the secondaries
		RemoveTertiaryPoint("tertiary01", "tertiary_area01");
		RemoveTertiaryPoint("tertiary04", "tertiary_area04");
		
		// Tertaries by the secondary and prime
		RemoveTertiaryPoint("tertiary013", "tertiary_area013");
		RemoveTertiaryPoint("tertiary07", "tertiary_area07");
	}
}

public void SpawnTertiaryPoint(float[VECTOR_SIZE] origin)
{
	int rt = CreateEntityByName("nd_info_tertiary_resource_point");
	int trigger = CreateEntityByName("nd_trigger_resource_point");
       
	SpawnResourcePoint("tertiary", TERTIARY_MODEL, rt, trigger, origin);
}

public void SpawnResourcePoint( const char[] type, const char[] model, int rt, int trigger, float[VECTOR_SIZE] origin)
{	
	char rt_name[32];
	char trigger_name[32];

	Format(rt_name, sizeof(rt_name), "%s-%i", type, resSpawnCount);
	Format(trigger_name, sizeof(trigger_name), "%s-%i-area", type, resSpawnCount);
		
	DispatchSpawn(rt);
	DispatchSpawn(trigger);
       
	ActivateEntity(rt);
	ActivateEntity(trigger);
       
	SetEntPropString(rt, Prop_Data, "m_iName", rt_name);
	SetEntPropString(trigger, Prop_Data, "m_iName", trigger_name);
       
	SetEntPropString(trigger, Prop_Data, "m_iszResourcePointName", rt_name);
	SetEntPropFloat(trigger, Prop_Data, "m_flCapTime", 5.0);
	SetEntProp(trigger, Prop_Data, "m_iButtonsToCap", 0);
	SetEntProp(trigger, Prop_Data, "m_iNumPlayersToCap", 1);
       
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
 
	SetEntityModel(rt, TERTIARY_MODEL);
	SetEntityModel(trigger, TERTIARY_MODEL); //will throw warning in game console; required and no model displayed for brush entity
       
	TeleportEntity(rt, origin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(trigger, origin, NULL_VECTOR, NULL_VECTOR);
       
	float min_bounds[VECTOR_SIZE] = {nCAPTURE_RADIUS, nCAPTURE_RADIUS, nCAPTURE_RADIUS};
	float max_bounds[VECTOR_SIZE] = {CAPTURE_RADIUS, CAPTURE_RADIUS, CAPTURE_RADIUS};
	
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", min_bounds);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", max_bounds);
	
	resSpawnCount++;
}

public void RemoveTertiaryPoint(const char[] rtName, const char[] trigName)
{
	int entity = LookupEntity("nd_info_tertiary_resource_point", rtName, -1);	
	if (entity > -1) AcceptEntityInput(entity, "Kill");	
	
	entity = LookupEntity("nd_trigger_resource_point", trigName, -1);
	if (entity > -1) AcceptEntityInput(entity, "Kill");
}

//Recursivly lookup entities by classname until we find the matching name
public int LookupEntity(const char[] classname, const char[] lookup_name, int start_point)
{
	int entity = FindEntityByClassname(start_point, classname);
	
	if (entity > -1)
	{
		char entity_name[32];
		GetEntPropString(entity, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
		return StrEqual(entity_name, lookup_name) ? entity : LookupEntity(classname, lookup_name, entity);
	}
	
	return -1;
}

int GetSpawnCount(int min, int med, int max)
{
	if (!ND_GEA_AVAILBLE())
		return med;	
		
	float avSkill = ND_GetEnhancedAverage();
	return 	avSkill >= cvarSpawnSkill[SKILL_HIGH] ? min :
		avSkill >= cvarSpawnSkill[SKILL_LOW]  ? med :
							max ;
}
