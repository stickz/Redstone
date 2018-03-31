int curRoundCount = 1;

void RegRestartCommand() {
	RegAdminCmd("sm_RestartRound", CMD_RestartRound, ADMFLAG_CUSTOM6, "Restarts the round when used");
}

/* Toggle player picking mode */
public Action CMD_RestartRound(int client, int args)
{
	if (!ND_HasTPRunAccess(client))
	{
		ReplyToCommand(client, "[SM] You only have team-pick access to this command!");
		return Plugin_Handled;
	}
	
	// Simulate round end, so other plugins get the message
	ND_SimulateRoundEnd();
	
	// Increment the round count and increase it
	curRoundCount += 1;
	ServerCommand("mp_maxrounds %d", curRoundCount);
	
	// Delay ending the round, so other plugins have time to react
	CreateTimer(1.5, TIMER_RestartTheRound, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;	
}

public Action TIMER_RestartTheRound(Handle timer)
{
	// End the round by sending the timelimit to 1 minute
	ServerCommand("mp_roundtime 1");
	return Plugin_Handled;
}
