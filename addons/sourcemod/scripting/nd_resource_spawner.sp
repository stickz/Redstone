#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_maps>
#include <nd_redstone>

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

int resSpawnCount = 0;
bool tertsSpawned[2] = { false, ... };

/* Plugin Convars */
ConVar cvarMarsTertiarySpawns;
ConVar cvarSiloTertiarySpawns;
ConVar cvarMetroTertiarySpawns;
ConVar cvarNuclearTertiarySpawns;
ConVar cvarDowntownTertiarySpawns;
ConVar cvarRoadworkTertiarySpawns;
ConVar cvarGateTertiarySpawns[2];
ConVar cvarRockTertiarySpawns[2];
ConVar cvarOilfeildTertiarySpawns[2];
ConVar cvarClocktowerTertiarySpawns[2];

public void OnPluginStart()
{
	// Fire round start event if plugin loads late
	if (ND_RoundStarted())
		ND_OnRoundStarted();
	
	CreatePluginConvars();
	
	AutoExecConfig(true, "nd_res_spawner");
	
	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConvars()
{
	// Create convars for resoruce spawning and generate the configuration file
	cvarMarsTertiarySpawns = CreateConVar("sm_tertiary_mars", "16", "Sets number of players to spawn extra tertaries on mars.");
	cvarSiloTertiarySpawns = CreateConVar("sm_tertiary_silo", "14", "Sets number of players to spawn extra tertaries on silo.");
	cvarMetroTertiarySpawns = CreateConVar("sm_tertiary_metro", "18", "Sets number of players to spawn extra tertaries on metro.");	
	cvarNuclearTertiarySpawns = CreateConVar("sm_tertiary_nuclear", "14", "Sets number of players to spawn extra tertaries on nuclear.");
	cvarDowntownTertiarySpawns = CreateConVar("sm_tertiary_downtown", "18", "Sets number of players to spawn extra tertaries on downtown.");
	cvarRoadworkTertiarySpawns = CreateConVar("sm_tertiary_roadwork", "16", "Sets number of players to spawn extra tertaries on roadwork.");
	cvarGateTertiarySpawns[FIRST_TIER] = CreateConVar("sm_tertiary_gate1", "16", "Sets number of players to spawn extra tertaries on gate.");
	cvarGateTertiarySpawns[SECOND_TIER] = CreateConVar("sm_tertiary_gate2", "22", "Sets number of players to spawn extra tertaries on gate.");
	cvarRockTertiarySpawns[FIRST_TIER] = CreateConVar("sm_tertiary_rock1", "8", "Sets number of players to spawn extra tertaries on rock.");
	cvarRockTertiarySpawns[SECOND_TIER] = CreateConVar("sm_tertiary_rock2", "16", "Sets number of players to spawn extra tertaries on rock.");
	cvarClocktowerTertiarySpawns[FIRST_TIER] = CreateConVar("sm_tertiary_clocktower1", "12", "Sets number of players to spawn extra tertaries on clocktower.");
	cvarClocktowerTertiarySpawns[SECOND_TIER] = CreateConVar("sm_tertiary_clocktower2", "18", "Sets number of players to spawn extra tertaries on clocktower.");
}

public void OnClientPutInServer(int client) {
	if (!tertsSpawned[SECOND_TIER] && ND_RoundStarted())
		CheckTertiarySpawns();
}

public void ND_OnRoundStarted()
{
	resSpawnCount = 0;
	tertsSpawned[FIRST_TIER] = false;
	tertsSpawned[SECOND_TIER] = false;
	AdjustTertiarySpawns();
	CheckTertiarySpawns();
}

void CheckTertiarySpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	// Will throw tag mismatch warning, it's okay
	if (ND_CustomMapEquals(map_name, ND_Submarine))
	{
		SpawnTertiaryPoint({987.0, -7562.0, 23.0});
		SpawnTertiaryPoint({-1483.0, 9135.0, 123.0});
		//SpawnTertiaryPoint({2366.0, 3893.0, 13.8});
		//SpawnTertiaryPoint({-1000.0, -3820.0, -186.0});
		//SpawnTertiaryPoint({1350.0, -2153.0, 54.0});
		//SpawnTertiaryPoint({1001.0, 1523.0, -112.0});
		tertsSpawned[SECOND_TIER] = true;
	}
	
	else if (ND_CustomMapEquals(map_name, ND_MetroImp))
	{
		if (RED_OnTeamCount() >= cvarMetroTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({2620.0, 529.0, 5.0});
			SpawnTertiaryPoint({-2235.0, -3249.0, -85.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Silo))
	{
		if (RED_OnTeamCount() >= cvarSiloTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({-3375.0, 1050.0, 2.0});
			SpawnTertiaryPoint({-36.0, -2000.0, 5.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Gate))
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
	
	else if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		if (RED_OnTeamCount() >= cvarDowntownTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({-2160.0, 6320.0, -3840.0});
			SpawnTertiaryPoint({753.0, 1468.0, -3764.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		if (RED_OnTeamCount() >= cvarRoadworkTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({3456.0, -5760.0, 7.0});
			SpawnTertiaryPoint({-6912.0, -2648.0, -118.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Mars))
	{
		if (RED_OnTeamCount() >= cvarMarsTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({-556.0, 4408.0, 28.0});
			SpawnTertiaryPoint({540.0, 3836.0, 28.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Rock))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarRockTertiarySpawns[FIRST_TIER].IntValue)
		{
			if (!tertsSpawned[FIRST_TIER])
			{
				SpawnTertiaryPoint({4052.0, 7008.0, -300.0});
				SpawnTertiaryPoint({-3720.0, -8716.0, -500.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarRockTertiarySpawns[SECOND_TIER].IntValue)
			{
				SpawnTertiaryPoint({5648.0, -3264.0, -496.0});
				SpawnTertiaryPoint({-3932.0, 2964.0, -496.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Oilfield))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarOilfeildTertiarySpawns[FIRST_TIER].IntValue)
		{
			if (!tertsSpawned[FIRST_TIER])
			{				
				SpawnTertiaryPoint({3691.0, 4118.0, -1056.0});
				SpawnTertiaryPoint({-4221.0, -3844.0, -951.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarOilfeildTertiarySpawns[SECOND_TIER].IntValue)
			{
				SpawnTertiaryPoint({-6654.0, -4276.0, -904.0});
				SpawnTertiaryPoint({6642.0, 4530.0, -996.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Nuclear))
	{
		if (RED_OnTeamCount() >= cvarNuclearTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({7867.0, 3467.0, 21.0});
			SpawnTertiaryPoint({312.0, 2635.0, -88.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		int teamCount = RED_OnTeamCount();
		if (teamCount >= cvarClocktowerTertiarySpawns[FIRST_TIER].IntValue)
		{
			if (!tertsSpawned[FIRST_TIER])
			{
				// Respawn coutyard and near secondary resources
				SpawnTertiaryPoint({-5028.0, -2906.0, -1396.0});
				SpawnTertiaryPoint({-1550.0, -2764.0, -1200.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarClocktowerTertiarySpawns[SECOND_TIER].IntValue)
			{
				// Respawn tunnel resources			
				SpawnTertiaryPoint({-1674.0, 1201.0, -1848.0});
				SpawnTertiaryPoint({-2564.0, 282.0, -1672.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}		
	}
	
	else
		tertsSpawned[SECOND_TIER] = true;
}

void AdjustTertiarySpawns()
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
	
	else if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		// Remove tertiary by prime and secondary
		RemoveTertiaryPoint("tertiary_cr", "tertiary_areacr");
		RemoveTertiaryPoint("tertiary_mb", "tertiary_areamb");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		RemoveTertiaryPoint("tertiary02", "tertiary_area02");
		RemoveTertiaryPoint("tertiary05", "tertiary_area05");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Mars))
	{
		// Remove 2 out of 5 tertaries on top of the map
		RemoveTertiaryPoint("tertiary_res_02", "tertiary_res_area_02");
		RemoveTertiaryPoint("tertiary_res_05", "tertiary_res_area_05");		
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Rock))
	{
		// Remove the two points on the far edge of base
		RemoveTertiaryPoint("tertiary02", "tertiary_area02");
		RemoveTertiaryPoint("tertiary06", "tertiary_area06");
		
		// Remove the two points on the benches
		RemoveTertiaryPoint("tertiary03", "tertiary_area03");
		RemoveTertiaryPoint("tertiary04", "tertiary_area04");
	}
	
	else if (ND_StockMapEquals(map_name, ND_Oilfield))
	{
		// Inner corner spawns are teir 1
		RemoveTertiaryPoint("tertiary_4", "tertiary_area4");
		RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		
		// Middle corner spawns are teir 2
		RemoveTertiaryPoint("tertiary_9", "tertiary_area9");
		RemoveTertiaryPoint("tertiary_10", "tertiary_area10");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Nuclear))
	{
		// Remove tertaries between base and secondary
		RemoveTertiaryPoint("InstanceAuto4-tertiary_point", "InstanceAuto4-tertiary_point_area");
		RemoveTertiaryPoint("InstanceAuto9-tertiary_point", "InstanceAuto9-tertiary_point_area");		
	}
	
	else if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		RemoveTertiaryPoint("tertiary_1", "tertiary_area1");
		RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		RemoveTertiaryPoint("tertiary_4", "tertiary_area4");
		
		RemoveTertiaryPoint("tertiary_tunnel", "tertiary_tunnel_area");		
		SpawnTertiaryPoint({1690.0, 4970.0, -1390.0});
	}
	
	//else if (ND_StockMapEquals(map_name, ND_Silo))
	//	RemoveTertiaryPoint("tertiary_ct", "tertiary_ct_area");
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
