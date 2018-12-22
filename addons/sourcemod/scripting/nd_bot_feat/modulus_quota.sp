/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{
	int specCount = getSpectatorAdjustment();
	int toSubtract = getUnassignedAdjustment();	

	int totalCount = g_cvar[BoosterQuota].IntValue - specCount - toSubtract;	
	
	int reducedCount = GetBotReductionCount();
	totalCount = GetSmallMapCount(totalCount, specCount, reducedCount);		
	
	return totalCount;
}

int getSpectatorAdjustment() {
	return ValidTeamCount(TEAM_SPEC) % 2 == 0 ? 2 : 1;
}

int getUnassignedAdjustment() //Fix bug which prevents connecting to the server
{	
	int NotAssignedCount = ValidTeamCount(TEAM_UNASSIGNED);	
	
	switch (NotAssignedCount)
	{
		case 0,1: NotAssignedCount = 0;
		case 2,3: NotAssignedCount = 2;
		default: NotAssignedCount = 4;	
	}		
	
	return NotAssignedCount;
}

/* List the really tinny maps to reduce further, (assume default if unlisted) */
int GetBotReductionCount()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	if (ND_CustomMapEquals(map, ND_Sandbrick) || ND_CustomMapEquals(map, ND_Mars))
		return g_cvar[BotReductionDec].IntValue;

	return g_cvar[BotReduction].IntValue;
}

/* Gets the max number of bots, based on the number of turrets on the map */
int GetTurretMaxQuota() {
	return ND_TurretCount() >= g_cvar[turretCountDec].IntValue ? g_cvar[turretBotDec].IntValue
				   				   : g_cvar[BoosterQuota].IntValue;
}

/* Get the number of bots after the reduction */
int GetSmallMapCount(int totalCount, int specCount, int rQuota)
{
	// Get max quota and reduce amount
	int maxQuota = g_cvar[BoosterQuota].IntValue;

	// Caculate the value for the bot cvar
	int botAmount = totalCount - rQuota + (maxQuota - totalCount);
	
	// Adjust bot value to offset the spectators 
	botAmount += specCount;
	
	// If the bot value is greater than max, we must use the max instead
	if (botAmount >= totalCount)
		botAmount = totalCount;
	
	// If the bot value is greater the amount allocated for turrets,
	// We must use the max turret allocation instead
	int maxTurretQuota = GetTurretMaxQuota();
	if (botAmount >= maxTurretQuota)
		botAmount = maxTurretQuota;
					
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount - 1;

	return botAmount;
}

bool CheckShutOffBots()
{
	// Get the current map we're playing
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	// Get the empire, consort and total on team count
	int empireCount = RED_GetTeamCount(TEAM_EMPIRE);
	int consortCount = RED_GetTeamCount(TEAM_CONSORT);	
	int totalCount = empireCount + consortCount;
	
	// Disable bots sooner if it's a tiny maps
	if (ND_CustomMapEquals(map, ND_Sandbrick))
	{		
		// If total count on one or both teams is reached, disable bots
		bool teamDisableDec = TCDisableBots(empireCount, consortCount, g_cvar[DisableBotsTeamDec].IntValue);
		return teamDisableDec || totalCount >= g_cvar[DisableBotsAtDec].IntValue;
	}
	
	// Disable bots later on big maps, to compensate for the size
	else if (ND_StockMapEquals(map, ND_Gate) || ND_StockMapEquals(map, ND_Downtown))
	{
		// If total count on one or both teams is reached, disable bots
		bool teamDisableInc = TCDisableBots(empireCount, consortCount, g_cvar[DisableBotsTeamInc].IntValue);
		return teamDisableInc || totalCount >= g_cvar[DisableBotsAtInc].IntValue;	
	}
	
	// If total count on one or both teams is reached, disable bots
	bool teamDisableReg = TCDisableBots(empireCount, consortCount, g_cvar[DisableBotsTeam].IntValue);
	return teamDisableReg || g_cvar[DisableBotsAt].IntValue;	
}

bool TCDisableBots(int empire, int consort, int threshold){
	return empire >= threshold || consort >= threshold;
}
