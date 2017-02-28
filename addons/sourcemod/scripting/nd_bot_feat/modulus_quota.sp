/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{
	int specCount = getSpectatorAdjustment();
	int toSubtract = getUnassignedAdjustment();	

	int totalCount = g_cvar[BoosterQuota].IntValue - specCount - toSubtract;	
	
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	if (ReduceBotCountByMap(map))
	{
		int reducedCount = GetBotReductionCount(map);
		totalCount = GetSmallMapCount(totalCount, specCount, reducedCount);		
	}
	
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

/* List maps to reduce bots on */
#define STOCK_MAP_SIZE 	6
int eSM[STOCK_MAP_SIZE] = {
	view_as<int>(ND_Silo),
	view_as<int>(ND_Hydro),
	view_as<int>(ND_Oasis),
	view_as<int>(ND_Coast),
	view_as<int>(ND_Metro),
	view_as<int>(ND_Clocktower)
}

#define CUSTOM_MAP_SIZE 5
int eCM[CUSTOM_MAP_SIZE] = {
	view_as<int>(ND_Sandbrick),
	view_as<int>(ND_MetroImp),
	view_as<int>(ND_Mars),
	view_as<int>(ND_Corner),
	view_as<int><ND_Roadwork)
}

/* Functions for adjusting quota based on the map */
bool ReduceBotCountByMap(const char[] map)
{
	for (int idx = 0; idx < STOCK_MAP_SIZE; idx++)
	{
		if (StrEqual(map, ND_StockMaps[eSM[idx]], false))
			return true;
	}
	
	for (int idx2 = 0; idx2 < CUSTOM_MAP_SIZE; idx2++)
	{
		if (StrEqual(map, ND_CustomMaps[eCM[idx2]], false))
			return true;
	}
	
	return false;
}

/* List the really tinny maps to reduce further, (assume default if unlisted) */
int GetBotReductionCount(const char[] map)
{
	if (StrEqual(map, ND_CustomMaps[view_as<int>(ND_Sandbrick)], false))
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
	
	// If the bot value is greater than max, we must return max instead
	if (botAmount >= totalCount)
		return totalCount;
					
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount+ 1;

	return botAmount;
}

/* Disable bots sonner on certain maps */
#define SMALL_MAP_SIZE2 1
int sSM[SMALL_MAP_SIZE2] = {
	view_as<int>(ND_Silo)
}
int cSM[SMALL_MAP_SIZE2] = {
	view_as<int>(ND_Sandbrick)
}

#define LARGE_MAP_SIZE 3
int lSM[LARGE_MAP_SIZE] = {
	view_as<int>(ND_Gate),
	view_as<int>(ND_Oilfield),
	view_as<int>(ND_Downtown)
};

int GetBotShutOffCount()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	/* Look through arrays to see if it's a small stock/custom map */
	for (int idx = 0; idx < SMALL_MAP_SIZE2; idx++)
	{
		if (StrEqual(map, ND_StockMaps[sSM[idx]], false) 
		|| (StrEqual(map, ND_CustomMaps[cSM[idx]], false)))
			return g_cvar[DisableBotsAtDec].IntValue;
	}
	
	/* Look through array to see if it's a large stock map */
	for (int ix = 0; ix < LARGE_MAP_SIZE; ix++)
	{
		if (StrEqual(map, ND_StockMaps[lSM[ix]], false))
			return g_cvar[DisableBotsAtInc].IntValue;
	}
	
	/* Otherwise, return the default value */
	return g_cvar[DisableBotsAt].IntValue;
}
