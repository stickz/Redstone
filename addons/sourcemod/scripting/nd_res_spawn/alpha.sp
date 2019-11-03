void AdjustTertiarySpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		// Remove tertiary by prime and secondary
		ND_RemoveTertiaryPoint("tertiary_cr", "tertiary_cr_area");
		ND_RemoveTertiaryPoint("tertiary_mb", "tertiary_mb_area");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_DowntownDyn))
	{
		// Remove tertiary by prime
		ND_RemoveTertiaryPoint("tertiary_bank", "tertiary_bank_area");
		ND_RemoveTertiaryPoint("tertiary_mb", "tertiary_mb_area");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		ND_RemoveTertiaryPoint("tertiary02", "tertiary_area02");
		ND_RemoveTertiaryPoint("tertiary05", "tertiary_area05");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Rock))
	{
		// Remove the two points on the far edge of base
		ND_RemoveTertiaryPoint("tertiary02", "tertiary_area02");
		ND_RemoveTertiaryPoint("tertiary06", "tertiary_area06");
		
		// Remove the two points on the benches
		ND_RemoveTertiaryPoint("tertiary03", "tertiary_area03");
		ND_RemoveTertiaryPoint("tertiary04", "tertiary_area04");
	}
	
	else if (ND_StockMapEquals(map_name, ND_Oilfield))
	{
		// Inner corner spawns are teir 1
		ND_RemoveTertiaryPoint("tertiary_4", "tertiary_area4");
		ND_RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		
		// Middle corner spawns are teir 2
		ND_RemoveTertiaryPoint("tertiary_9", "tertiary_area9");
		ND_RemoveTertiaryPoint("tertiary_10", "tertiary_area10");
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Nuclear))
	{
		// Remove tertaries between base and secondary
		ND_RemoveTertiaryPoint("InstanceAuto4-tertiary_point", "InstanceAuto4-tertiary_point_area");
		ND_RemoveTertiaryPoint("InstanceAuto9-tertiary_point", "InstanceAuto9-tertiary_point_area");		
	}
	
	else if (ND_StockMapEquals(map_name, ND_Clocktower))
	{
		ND_RemoveTertiaryPoint("tertiary_1", "tertiary_area1");
		ND_RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		ND_RemoveTertiaryPoint("tertiary_4", "tertiary_area4");
		
		ND_RemoveTertiaryPoint("tertiary_tunnel", "tertiary_tunnel_area");		
		ND_SpawnTertiaryPoint({1690.0, 4970.0, -1390.0});
	}
	
	else if (ND_StockMapEquals(map_name, ND_Oasis))
		ND_RemoveTertiaryPoint("tertiary_2", "tertiary_area2");
		
	else if (ND_StockMapEquals(map_name, ND_Coast))
	{
		// Remove two tertiary points near the secondary
		ND_RemoveTertiaryPoint("tertiary_park", "tertiary_park_area");
		ND_RemoveTertiaryPoint("tertiary_gameshop", "tertiary_gameshop_area");
		//ND_RemoveTertiaryPoint("tertiary_sideroom", "tertiary_sideroom_area");
		
		// Move the sand tertiary over more
		//ND_RemoveTertiaryPoint("tertiary_sand", "tertiary_area");
		//ND_SpawnTertiaryPoint({6700.0, 6800.0, 45.0});
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Mars))
	{
		// Remove 2 out of 5 tertaries on top of the map
		ND_RemoveTertiaryPoint("tertiary_res_02", "tertiary_res_area_02");
		ND_RemoveTertiaryPoint("tertiary_res_05", "tertiary_res_area_05");		
	}
	
	//else if (ND_StockMapEquals(map_name, ND_Silo))
	//	ND_RemoveTertiaryPoint("tertiary_ct", "tertiary_ct_area");
}

void CheckTertiarySpawns()
{
	char map_name[64];   
	GetCurrentMap(map_name, sizeof(map_name));
	
	// Will throw tag mismatch warning, it's okay
	if (ND_StockMapEquals(map_name, ND_Downtown))
	{
		if (RED_OnTeamCount() >= cvarDowntownTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({-2160.0, 6320.0, -3840.0});
			ND_SpawnTertiaryPoint({753.0, 1468.0, -3764.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_DowntownDyn))
	{
		if (RED_OnTeamCount() >= cvarDowntownTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({2224.0, -784.0, -3200.0});
			ND_SpawnTertiaryPoint({753.0, 1468.0, -3764.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Roadwork))
	{
		if (RED_OnTeamCount() >= cvarRoadworkTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({3456.0, -5760.0, 7.0});
			ND_SpawnTertiaryPoint({-6912.0, -2648.0, -118.0});
			tertsSpawned[SECOND_TIER] = true;
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Mars))
	{
		if (RED_OnTeamCount() >= cvarMarsTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({-556.0, 4408.0, 28.0});
			ND_SpawnTertiaryPoint({540.0, 3836.0, 28.0});
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
				ND_SpawnTertiaryPoint({4052.0, 7008.0, -300.0});
				ND_SpawnTertiaryPoint({-3720.0, -8716.0, -500.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarRockTertiarySpawns[SECOND_TIER].IntValue)
			{
				ND_SpawnTertiaryPoint({5648.0, -3264.0, -496.0});
				ND_SpawnTertiaryPoint({-3932.0, 2964.0, -496.0});
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
				ND_SpawnTertiaryPoint({3691.0, 4118.0, -1056.0});
				ND_SpawnTertiaryPoint({-4221.0, -3844.0, -951.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarOilfeildTertiarySpawns[SECOND_TIER].IntValue)
			{
				ND_SpawnTertiaryPoint({-6654.0, -4276.0, -904.0});
				ND_SpawnTertiaryPoint({6642.0, 4530.0, -996.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}
	}
	
	else if (ND_CustomMapEquals(map_name, ND_Nuclear))
	{
		if (RED_OnTeamCount() >= cvarNuclearTertiarySpawns.IntValue)
		{
			ND_SpawnTertiaryPoint({7867.0, 3467.0, 21.0});
			ND_SpawnTertiaryPoint({312.0, 2635.0, -88.0});
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
				ND_SpawnTertiaryPoint({-5028.0, -2906.0, -1396.0});
				ND_SpawnTertiaryPoint({-1550.0, 2764.0, -1200.0});
				tertsSpawned[FIRST_TIER] = true;
			}
			
			if (teamCount >= cvarClocktowerTertiarySpawns[SECOND_TIER].IntValue)
			{
				// Respawn tunnel resources			
				ND_SpawnTertiaryPoint({-1674.0, 1201.0, -1848.0});
				ND_SpawnTertiaryPoint({-2564.0, 282.0, -1672.0});
				tertsSpawned[SECOND_TIER] = true;
			}
		}		
	}
	
	else if (ND_StockMapEquals(map_name, ND_Oasis))
	{
		if (RED_OnTeamCount() >= cvarOasisTertiarySpawns.IntValue)
		{
			// (Re)spawn tertaries near the secondaries
			ND_SpawnTertiaryPoint({-4702.0, 1176.0, -224.0});
			ND_SpawnTertiaryPoint({5600.0, 1500.0, -390.0});
			tertsSpawned[FIRST_TIER] = true;
		}
	}
	
	else if (ND_StockMapEquals(map_name, ND_Coast))
	{
		if (RED_OnTeamCount() >= cvarCoastTertiarySpawns.IntValue)
		{
			// (Re)spawn tertaries near the secondaries			
			ND_SpawnTertiaryPoint({700.0, 7164.0, 40.0});
			ND_SpawnTertiaryPoint({2500.0, -528.0, 54.0});
			tertsSpawned[FIRST_TIER] = true;
		}
	}
	
	else
		tertsSpawned[SECOND_TIER] = true;
}
