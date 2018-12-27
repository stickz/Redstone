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
			
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount - 1;

	return botAmount;
}

bool CheckShutOffBots()
{	
	// Get the empire, consort and total on team count
	int empireCount = RED_GetTeamCount(TEAM_EMPIRE);
	int consortCount = RED_GetTeamCount(TEAM_CONSORT);	
	
	// If total count on one or both teams is reached, disable bots
	bool isTotalDisable = (empireCount + consortCount) >= totalDisable;
	return isTotalDisable || empireCount >= teamDisable || consortCount >= teamDisable;
}
