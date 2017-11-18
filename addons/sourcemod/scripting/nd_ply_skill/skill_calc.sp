float GetSkillLevel(int client)
{
	// Get the client level for later use
	int clientLevel = getClientLevel(client);
	int skillFloor = ND_GetSkillFloor(client);
	
	// If the gameme player skill is found...
	// If the player is under-performing, set their skill to the average		
	// Otherwise, return the max of the clientLevel, gameMeSkill or Skill Floor
	float gameMeSkill = GameME_PlayerSkill[client];
	if (gameMeSkill > -1)
		return 	PlayerUnderPerforming(client, gameMeSkill) ? lastAverage : 
			Math_Max(Math_Max(gameMeSkill, clientLevel), skillFloor);		
	
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
	
	// If the gameme commander skill is found... 
	// Return the max of the clientLevel, GameMeCommSkill or Skill Floor
	float gameMeComSkill = GameME_CommanderSkill[client];
	if (gameMeComSkill > -1)
		return Math_Max(Math_Max(gameMeComSkill, clientLevel), skillFloor);

	// If the client has a skill floor then return that otherwise...
	// Return a min skill multiple or the client level (whichever is greater)
	return skillFloor != -1 ? float(skillFloor) : MinSkillValue(clientLevel, 30);
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
