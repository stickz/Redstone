RegAdminSpawnCmds()
{
	RegAdminCmd("sm_SpawnSilo", CMD_SpawnSilo, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_SpawnCorner", CMD_SpawnCorner, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_SpawnDowntown", CMD_SpawnDowntown, ADMFLAG_ROOT, "dummy");
	RegAdminCmd("sm_SpawnHydro", CMD_SpawnHydro, ADMFLAG_ROOT, "dummy");
}

public Action CMD_SpawnSilo(int client, int args)
{
	// In middle map
	SpawnTertiaryPoint({-3375.0, 1050.0, 2.0});
	SpawnTertiaryPoint({-36.0, -2000.0, 5.0});
	tertsSpawned[FIRST_TIER] = true;
	
	// Near base
	SpawnTertiaryPoint({-5402.0, -3859.0, 74.0});
	SpawnTertiaryPoint({2340.0, 2558.0, 10.0});
	tertsSpawned[SECOND_TIER] = true;
	
	return Plugin_Handled;
}

public Action CMD_SpawnCorner(int client, int args)
{
	SpawnTertiaryPoint({-3485.0, 11688.0, 5.0});
	SpawnTertiaryPoint({-1947.0, -1942.0, 7.0});
	tertsSpawned[SECOND_TIER] = true;

	return Plugin_Handled;
}

public Action CMD_SpawnDowntown(int client, int args)
{
	SpawnTertiaryPoint({2385.0, -5582.0, -3190.0});
	SpawnTertiaryPoint({-2668.0, -3169.0, -2829.0});
	tertsSpawned[SECOND_TIER] = true;

	return Plugin_Handled;
}

public Action CMD_SpawnHydro(int client, int args)
{
	SpawnTertiaryPoint({2132.0, 2559.0, 18.0});
	SpawnTertiaryPoint({-5199.0, -3461.0, 191.0});
	tertsSpawned[SECOND_TIER] = true;

	return Plugin_Handled;
}
