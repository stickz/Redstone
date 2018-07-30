#define INVALID_USERID	0

void RegRestartCommand() 
{
	RegConsoleCmd("sm_RestartRound", CMD_RestartRound, "Restarts the round when used");
	RegConsoleCmd("sm_RestartWarmup", CMD_RestartWarmup, "Restarts the warmup when used");
}

/* Stop the round and instantly restart it again */
public Action CMD_RestartRound(int client, int args)
{
	if (!CanRestartRound(client))
		return Plugin_Handled;
		
	ND_RestartRound(false); // Restart instantly without warmup.
	CreateTimer(1.0, TIMER_ShowRoundRestart, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;	
}

/* Stop the round and bring everyone back to warmup */
public Action CMD_RestartWarmup(int client, int args)
{
	if (!CanRestartRound(client))
		return Plugin_Handled;
		
	ND_RestartRound(true); // Pause after round. Go back to warmup round.
	CreateTimer(1.0, TIMER_ShowRoundRestart, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;	
}

bool CanRestartRound(int client)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		PrintToChat(client, "\x05[xG] You must be a RedstoneND officer to use this command!");
		return false;
	}
	
	if (!ND_HasTPRunAccess(client))
	{
		PrintToChat(client, "\x05[xG] You only have team-pick access to this command!");
		return false;
	}
	
	if (!ND_RoundRestartable())
	{
		PrintToChat(client, "\x05[xG] The round is not restartable at this time!");
		return false;	
	}

	return true;
}

public Action TIMER_ShowRoundRestart(Handle timer, any userid)
{	
	// Get the client. If valid, print who restarted the round
	int client = GetClientOfUserId(userid);	
	if (client != INVALID_USERID)
	{
		// Get the name of the admin who restarted the round
		char clientName[64];
		GetClientName(client, clientName, sizeof(clientName));

		// Print a message to everyone explaining what happened
		PrintToChatAll("\x05%s has terminated the round!", clientName);
	}
	
	return Plugin_Handled;
}
