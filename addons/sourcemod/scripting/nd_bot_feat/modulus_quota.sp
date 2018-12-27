/* Functions for Bot Modulus Quota */
int getBotModulusQuota()
{
	// Get the spec count and the max total bot count
	int specCount = getSpectatorAdjustment();
	int toSubtract = getUnassignedAdjustment();
	int totalCount = g_cvar[BoosterQuota].IntValue - specCount - toSubtract;	

	// Get max quota and reduce amount from convars.sp
	int rQuota = botReductionValue;
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	
	// Caculate the value for the bot cvar
	int botAmount = totalCount - rQuota + (maxQuota - totalCount);
	
	// Adjust bot value to offset the spectators 
	botAmount += specCount;
	
	// If the bot value is greater than max, we must use the max instead
	if (botAmount >= totalCount)
		botAmount = totalCount;
	
	// If required, modulate the bot count so the number is even
	if (botAmount % 2 != totalCount % 2)
		return botAmount - 1;
	
	return botAmount;
}

int getSpectatorAdjustment() {
	return ValidTeamCount(TEAM_SPEC) % 2 == 0 ? 2 : 1;
}

int getUnassignedAdjustment() //Fix bug which prevents connecting to the server
{	
	int NotAssignedCount = ValidTeamCount(TEAM_UNASSIGNED);	
	return NotAssignedCount % 2 == 0 ? NotAssignedCount : NotAssignedCount - 1;
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
