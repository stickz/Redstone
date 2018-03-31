#define INVALID_USERID	0
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
	CreateTimer(1.5, TIMER_PrepRoundRestart, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;	
}

public Action TIMER_PrepRoundRestart(Handle timer, any userid)
{	
	// Get the client. If valid, print who restarted the round
	int client = GetClientOfUserId(userid);	
	if (client != INVALID_USERID)
	{
		// Get the name of the admin who restarted the round
		char clientName[64];
		GetClientName(client, clientName, sizeof(clientName));

		// Print a message to everyone explaining what happened
		PrintToChatAll("\x05%s has restarted the round!", clientName);
	}
	else
		PrintToChatAll("\x05The round has been restarted!");
	
	// End the round by sending the timelimit to 1 minute
	ServerCommand("mp_roundtime 1");
	
	// Delay the round start, so the server has time to react
	CreateTimer(1.5, TIMER_EngageRoundRestart, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action TIMER_EngageRoundRestart(Handle timer)
{
	// Default time limit to 60, unless anther plugin changes it
	ServerCommand("mp_roundtime 60");
	
	// Set the round to start immediately without balancing
	ServerCommand("mp_minplayers 1");
	
	return Plugin_Handled;
}
