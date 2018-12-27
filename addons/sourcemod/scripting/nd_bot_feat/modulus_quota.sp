/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{	
	// Get max quota and reduce amount from convars.sp
	int rQuota = botReductionValue;
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	
	// Get the spec count and the unassigned count
	int specCount = ValidTeamCount(TEAM_SPEC);
	int assignCount = ValidTeamCount(TEAM_UNASSIGNED);
	
	// Get the number of bots to subtract and the max number of bots
	int substractCount = GetNumEvenM1(specCount + assignCount);
	int totalCount = GetNumEvenM1(maxQuota - substractCount);

	// Caculate the value for the bot cvar. Adjust bot value to offset the spectators
	int botAmount = totalCount - rQuota + substractCount + GetNumEvenM1(specCount);
	
	// If the bot value is greater than max, we must use the max instead
	if (botAmount >= totalCount)
		botAmount = totalCount;
		
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount - 1;
	
	return botAmount;
}

int GetNumEvenM1(int num) {
	return num % 2 == 0 ? num : num - 1;
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
