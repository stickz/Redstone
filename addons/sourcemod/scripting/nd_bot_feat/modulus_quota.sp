/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{	
	// Get max quota and reduce amount from convars.sp
	int rQuota = botReductionValue;
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	
	// Get the spec count and the max total bot count
	int specCount = ValidTeamCount(TEAM_SPEC);
	int totalCount = GetMaxBotCount(maxQuota, specCount);

	// Caculate the value for the bot cvar. Adjust bot value to offset the spectators
	int botAmount = totalCount - rQuota + (maxQuota - totalCount) + GetSpecEven(specCount);
	
	// If the bot value is greater than max, we must use the max instead
	if (botAmount >= totalCount)
		botAmount = totalCount;
		
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount - 1;
	
	return botAmount;
}

int GetSpecEven(int specCount) {
	return specCount % 2 == 0 ? specCount : specCount -1;
}

int GetMaxBotCount(int maxQuota, int spec)
{
	int total = maxQuota - spec - ValidTeamCount(TEAM_UNASSIGNED);	
	return total % 2 == 0 ? total : total - 1;
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
