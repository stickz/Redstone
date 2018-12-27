/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{	
	// Get max quota and the current spectator count
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	int specCount = ValidTeamCount(TEAM_SPEC);
	
	// Caculate the value for the bot cvar. Adjust bot value to offset the spectators
	int botAmount = maxQuota - botReductionValue + specCount;
	
	// If the bot value is greater than max, we must use the max instead
	int totalCount = maxQuota - specCount - ValidTeamCount(TEAM_UNASSIGNED);
	if (botAmount >= totalCount)
		botAmount = totalCount;
	
	// If required, modulate the bot count so the number is even
	return GetNumEvenM1(botAmount);
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
