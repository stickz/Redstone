void AdjustTertiarySpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		// Remove tertiary by prime and secondary
		RemoveTertiaryPoint("tertiary_cr", "tertiary_cr_area");
		RemoveTertiaryPoint("tertiary_mb", "tertiary_mb_area");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_DowntownDyn))
	{
		// Remove tertiary by prime
		RemoveTertiaryPoint("tertiary_bank", "tertiary_bank_area");
		RemoveTertiaryPoint("tertiary_mb", "tertiary_mb_area");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		RemoveTertiaryPoint("tertiary02", "tertiary_area02");
		RemoveTertiaryPoint("tertiary05", "tertiary_area05");
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
	
	else if (ND_StockMapEquals(map_name, ND_Oasis))
		RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		
	else if (ND_StockMapEquals(map_name, ND_Coast))
	{
		// Remove two tertiary points near the secondary
		RemoveTertiaryPoint("tertiary_park", "tertiary_park_area");
		RemoveTertiaryPoint("tertiary_gameshop", "tertiary_gameshop_area");
		//RemoveTertiaryPoint("tertiary_sideroom", "tertiary_sideroom_area");
		
		// Move the sand tertiary over more
		//RemoveTertiaryPoint("tertiary_sand", "tertiary_area");
		//SpawnTertiaryPoint({6700.0, 6800.0, 45.0});
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Mars))
	{
		// Remove 2 out of 5 tertaries on top of the map
		RemoveTertiaryPoint("tertiary_res_02", "tertiary_res_area_02");
		RemoveTertiaryPoint("tertiary_res_05", "tertiary_res_area_05");		
	}
	
	//else if (ND_StockMapEquals(map_name, ND_Silo))
	//	RemoveTertiaryPoint("tertiary_ct", "tertiary_ct_area");
}

void CheckTertiarySpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	// Will throw tag mismatch warning, it's okay
	if (ND_CustomMapEquals(map_name, ND_Submarine))
	{
		if (ND_GetServerTypeEx() == SERVER_TYPE_ALPHA)
		{
			SpawnTertiaryPoint({2366.0, 3893.0, 13.8});
			SpawnTertiaryPoint({-1000.0, -3820.0, -186.0});
			SpawnTertiaryPoint({1350.0, -2153.0, 54.0});
			SpawnTertiaryPoint({1001.0, 1523.0, -112.0});
		}
		
		tertsSpawned[SECOND_TIER] = true;
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
	
	else if (ND_CustomMapEquals(map_name, ND_DowntownDyn))
	{
		if (RED_OnTeamCount() >= cvarDowntownTertiarySpawns.IntValue)
		{
			SpawnTertiaryPoint({2224.0, -784.0, -3200.0});
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
				SpawnTertiaryPoint({-1550.0, 2764.0, -1200.0});
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
	
	else if (ND_StockMapEquals(map_name, ND_Oasis))
	{
		if (RED_OnTeamCount() >= cvarOasisTertiarySpawns.IntValue)
		{
			// (Re)spawn tertaries near the secondaries
			SpawnTertiaryPoint({-4702.0, 1176.0, -224.0});
			SpawnTertiaryPoint({5600.0, 1500.0, -390.0});
			tertsSpawned[FIRST_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Coast))
	{
		if (RED_OnTeamCount() >= cvarCoastTertiarySpawns.IntValue)
		{
			// (Re)spawn tertaries near the secondaries			
			SpawnTertiaryPoint({700.0, 7164.0, 40.0});
			SpawnTertiaryPoint({2500.0, -528.0, 54.0});
			tertsSpawned[FIRST_TIER] = true;
		}
	}
	
	else
		tertsSpawned[SECOND_TIER] = true;
}
