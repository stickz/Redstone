#define REMOVE_COMPILE_WARNING -1

#define ENABLE_SKILL_PREDICT 45
#define SERVER_IS_ROOKIE 35

bool EnableSkillPrediction() {
	return RED_OnTeamCount() > 15 && lastAverage > ENABLE_SKILL_PREDICT;
}

bool RookieClassify() {
	return lastAverage < SERVER_IS_ROOKIE;
}

float RookieMinSkillValue(int clientLevel) {
	return clientLevel < 10 ? RoundToNearestMultipleEx(clientLevel, 5) : float(clientLevel);
}

float MinSkillValue(int clientLevel) {
	return clientLevel < 20 ? RoundToNearestMultipleEx(clientLevel, 5) : float(clientLevel);
}

float PredictedSkill(int clientLevel)
{
	/* Predict to increase accuracy of players lacking data
	 * int players are worth 4 average players
	 * Semi-int players are worth 3 average players
	 * Otherwise, use the client level for regular clients.
	 */
	float min = lastAverage / 4.25;
	return clientLevel < min ? min : Math_Max(clientLevel, lastAverage / 3);
}
