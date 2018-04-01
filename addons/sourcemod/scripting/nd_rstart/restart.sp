#define INVALID_USERID	0
int curRoundCount = 1;
bool toWarmupRound = false;

void RegRestartCommand() 
{
	RegAdminCmd("sm_RestartRound", CMD_RestartRound, ADMFLAG_CUSTOM6, "Restarts the round when used");
	RegAdminCmd("sm_RestartWarmup", CMD_RestartWarmup, ADMFLAG_CUSTOM6, "Restarts the warmup when used");
}

/* Stop the round and instantly restart it again */
public Action CMD_RestartRound(int client, int args)
{
	if (!CanRestartRound(client))
		return Plugin_Handled;
	
	DoRoundRestart(client);	
	return Plugin_Handled;	
}

/* Stop the round and bring everyone back to warmup */
public Action CMD_RestartWarmup(int client, int args)
{
	if (!CanRestartRound(client))
		return Plugin_Handled;
	
	toWarmupRound = true; // Important: This boolean sends everyone to warmup
	
	DoRoundRestart(client);	
	return Plugin_Handled;	
}

bool CanRestartRound(int client)
{
	if (!ND_HasTPRunAccess(client))
	{
		PrintToChat(client, "\x05[xG] You only have team-pick access to this command!");
		return false;
	}
	
	if (!ND_RoundStarted())
	{
		PrintToChat(client, "\x05[xG] This command can only be used after round start!");
		return false;	
	}
	
	if (!ND_RoundRestartable())
	{
		PrintToChat(client, "\x05[xG] You must wait 60s after round start before using!");
		return false;	
	}

	return true;
}

void DoRoundRestart(int client)
{
	// Simulate round end, so other plugins get the message
	ND_SimulateRoundEnd();
	
	// Increment the round count and increase it
	curRoundCount += 1;
	ServerCommand("mp_maxrounds %d", curRoundCount);	

	// Delay ending the round, so other plugins have time to react
	CreateTimer(1.5, TIMER_PrepRoundRestart, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
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
	// Default time limit to unlimited, unless anther plugin changes it
	ServerCommand("mp_roundtime 0");
	
	// Set the round to start immediately without balancing
	if (!toWarmupRound) // If player chooses instant start
	{
		ServerCommand("mp_minplayers 1");
		PrintToChatAll("\x05The round will restart shortly!");
	}
	else
		PrintToChatAll("\x05The match will pause shortly!");
	
	// Default the next restart to warmup to false
	toWarmupRound = false;
	return Plugin_Handled;
}
