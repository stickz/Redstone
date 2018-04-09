#define REMOVE_COMPILE_WARNING -1

#define ENABLE_SKILL_PREDICT 45
#define SERVER_IS_ROOKIE 35

bool EnableSkillPrediction() {
	return RED_OnTeamCount() > 15 && lastAverage > ENABLE_SKILL_PREDICT;
}

bool RookieClassify() {
	return lastAverage < SERVER_IS_ROOKIE;
}

float MinSkillValue(int clientLevel, int endLevel = 20, int multiple = 5) 
{
	if (clientLevel < endLevel)
		return float(RoundToMult(clientLevel, multiple));
	
	return float(clientLevel);
}

float PredictedSkill(int clientLevel)
{
	/* Predict to increase accuracy of players lacking data
	 * int players are worth 4 average players
	 * Semi-int players are worth 3 average players
	 * Otherwise, use the client level for regular clients.
	 */	
	
	float min = lastAverage / 4.25;
	float max = lastAverage / 3.0;
						
	return 	clientLevel < min ? min : 
			clientLevel < max ? max : 
			float(clientLevel);
}