#define REMOVE_COMPILE_WARNING -1

#define ENABLE_SKILL_PREDICT 45
#define SERVER_IS_ROOKIE 35

bool EnableSkillPrediction() {
	return RED_OnTeamCount() > 15 && lastAverage > ENABLE_SKILL_PREDICT;
}

bool RookieClassify() {
	return lastAverage < SERVER_IS_ROOKIE;
}

float RookieMinSkillValue(int clientLevel)
{
	switch (clientLevel)
	{
		case 0,1,2,3,4: return 5.0;
		case 6,7,8,9: return 10.0;
		default: return float(clientLevel);
	}
	
	return float(REMOVE_COMPILE_WARNING); //This code isn't accessible
}

float MinSkillValue(int clientLevel)
{
	switch (clientLevel)
	{
		case 0,1,2,3,4,5,6,7,8,9,10: return 10.0;
		case 11,12,13,14,15: return 15.0;
		case 16,17,18,19,20: return 20.0;
		default: return float(clientLevel);
	}
	
	return float(REMOVE_COMPILE_WARNING); //This code isn't accessible
}

float PredictedSkill(int clientLevel)
{
	/* Predict to increase accuracy of players lacking data
	 * int players are worth 4 average players
	 * Semi-int players are worth 2.75 average players
	 * Otherwise, use the client level for regular clients.
	 */	
	
	float min = lastAverage / 4.25;
	float max = lastAverage / 3.0;
						
	return clientLevel < min ? min : clientLevel < max ? max : float(clientLevel);
}