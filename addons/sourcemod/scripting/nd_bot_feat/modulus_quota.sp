/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{
	int specCount = getSpectatorAdjustment();
	int toSubtract = getUnassignedAdjustment();	

	int totalCount = g_cvar[BoosterQuota].IntValue - specCount - toSubtract;	
	
	if (ReduceBotCountByMap())
		totalCount = GetSmallMapCount(totalCount);
	
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

#define STOCK_MAP_SIZE 	2
int eSM[STOCK_MAP_SIZE] = {
	view_as<int>(ND_Silo),
	view_as<int>(ND_Hydro)
}

#define CUSTOM_MAP_SIZE 3
int eCM[CUSTOM_MAP_SIZE] = {
	view_as<int>(ND_Sandbrick),
	view_as<int>(ND_MetroImp),
	view_as<int>(ND_Mars)
}


/* Functions for adjusting quota based on the map */
bool ReduceBotCountByMap()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));

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

int GetSmallMapCount(int totalCount)
{
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	int rQuota = g_cvar[BotReduction].IntValue;
	
	int fromMax = maxQuota - totalCount;
	int toReduce = totalCount - rQuota + fromMax;
	
	if (totalCount <= toReduce)
		return totalCount;
		
	if (toReduce % 2 != totalCount % 2)
		return toReduce + 1;

	return toReduce;
}