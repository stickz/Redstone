int	LevelCacheArray[MAXPLAYERS+1] = {-1, ...};

int getClientLevel(int client)
{
	//Cache the client level if needed
	if (LevelCacheArray[client] < 2)
	{
		// If the client's exp is retrievable from steamworks, check if they're past level 80
		if (ND_EXPAvailible(client) && ND_GetClientEXP(client) >= g_Cvar[LevelEightyExp].IntValue)
		{
			LevelCacheArray[client] = 80;
			return LevelCacheArray[client];			
		}
		
		int clientLevel = GetEntProp(playerResEntity, Prop_Send, "m_iPlayerRank", 1, client);		
		
		if (clientLevel > 1)
		{
			LevelCacheArray[client] = clientLevel;
			return LevelCacheArray[client];
		}

		return 1;
	}
	
	return LevelCacheArray[client];
}