RegAdminSpawnCmds()
{
	RegAdminCmd("sm_SpawnSilo", CMD_SpawnSilo, ADMFLAG_ROOT, "dummy");
}

public Action CMD_SpawnSilo(int client, int args)
{
	// In middle map
	SpawnTertiaryPoint({-3375.0, 1050.0, 2.0});
	SpawnTertiaryPoint({-36.0, -2000.0, 5.0});
	
	// Near base
	SpawnTertiaryPoint({-5402.0, -3859.0, 114.0});
	SpawnTertiaryPoint({2340.0, 2558.0, 50.0});
	
	return Plugin_Handled;
}
