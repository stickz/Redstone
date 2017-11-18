float GetSkillLevel(int client)
{
	// Get the client level for later use
	int clientLevel = getClientLevel(client);
	int skillFloor = ND_GetSkillFloor(client);
	
	/* Try to use the gameme skill value first */
	float gameMeSkill = GameME_PlayerSkill[client];
	if (gameMeSkill > -1)
	{
		/* If the player is under-performing, lower their skill */
		if (g_isWeakVeteran[client] && gameMeSkill > lastAverage)
			gameMeSkill = lastAverage;
		else
		{
			/* Enforce of min skill of clientLevel * 0.8 */
			float minSkill = clientLevel * 0.8;
			if (gameMeSkill < minSkill)
				gameMeSkill = minSkill;
			
			/* Or Enforce a min skill of the set floor */
			else if (gameMeSkill < skillFloor)
				gameMeSkill = float(skillFloor);
		}
			
		return gameMeSkill;			
	}
	
	/* Then check if a client has a skill floor */
	if (skillFloor != -1)
		return float(skillFloor);
	
	/* Check if the client is a rookie, and needs their skill modified */
	if (g_isSkilledRookie[client])
	{
		float cachedAverage = lastAverage / ROOKIE_SKILL_ADJUSTMENT;
		if (clientLevel < cachedAverage)
			return cachedAverage;	
	}

	if (EnableSkillPrediction())
		return PredictedSkill(clientLevel);
		
	// Return a min skill multiple or the client level (whichever is greater)
	return MinSkillValue(clientLevel, RookieClassify() ? 10 : 20);
}

float GetCommanderSkill(int client)
{
	// Get the client level for later use
	int clientLevel = getClientLevel(client);
	int skillFloor = ND_GetSkillFloor(client);
	
	/* Try to use the gameme skill value first */
	float gameMeComSkill = GameME_CommanderSkill[client];
	if (gameMeComSkill > -1)
	{
		/* Enforce of min skill of clientLevel */
		if (gameMeComSkill < clientLevel)
			gameMeComSkill = float(clientLevel);
			
		/* Or Enforce a min skill of the set floor */
		else if (gameMeComSkill < skillFloor)
			gameMeComSkill = float(skillFloor);
		
		return gameMeComSkill;
	}
	
	/* Then check if a client has a skill floor */
	if (skillFloor != -1)
		return float(skillFloor);
	
	/* Then try to use the client level */
	if (clientLevel >= 20)
		return float(clientLevel);
	
	return MinSkillValue(clientLevel);
}

void UpdateSkillAverage()
{
	float average = 0.0;
	int count = 0;
	
	RED_LOOP_CLIENTS(client)
	{
		average += GetSkillLevel(client);
		count++;
	}

	average /= count;	
	lastAverage = average;
}

#define MAX_SKILL 225;

void UpdateSkillMedian()
{
	int count = RED_ClientCount();	
	if (count == 0)
		return;
	
	ArrayList players = new ArrayList();	
	
	RED_LOOP_CLIENTS(client) {
		players.Push(GetSkillLevel(client));
	}
	
	SortADTArray(players, Sort_Ascending, Sort_Float);
	
	if (count == 1)
		lastMedian = players.Get(0);
	
	else if (count % 2 == 0)
		lastMedian = players.Get((count / 2) - 1);
	
	else
	{
		int left = RoundToFloor(float(count) / 2.0);
		int right = RoundToCeil(float(count) / 2.0);
		
		lastMedian = players.Get(left) + players.Get(right) / 2.0;			
	}	
}
