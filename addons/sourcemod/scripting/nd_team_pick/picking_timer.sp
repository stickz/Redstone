#define INVALID_USERID 0
bool lastTimerEnded = false;
bool noChoiceFound = false;
int PickTimeRemaining = 0;
Handle hPickTimerHandler = INVALID_HANDLE;

void ResetPickTimer(int client)
{
	if (lastTimerEnded)
		lastTimerEnded = false
	else if (hPickTimerHandler != INVALID_HANDLE)
		KillTimer(hPickTimerHandler, false);
	
	PickTimeRemaining = GetPickingTimeLimit();	
	hPickTimerHandler = CreateTimer(1.0, TIMER_CountdownPickTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_CountdownPickTime(Handle timer, any:userid)
{
	if (DebugTeamPicking)
		ConsoleToAdmins( "TIMER_CountdownPickTime(): iterated", "b");
	
	// Get the client from userid, if invalid stop timer
	int client = GetClientOfUserId(userid);
	if (client == INVALID_USERID)		
		return Plugin_Stop;
	
	// Decincrement and check if the timer has ran out
	if (--PickTimeRemaining <= 0)
	{
		if (DebugTeamPicking)
			ConsoleToAdmins( "TIMER_CountdownPickTime(): finished", "b");

		AutoSelectPlayer(client);
		lastTimerEnded = true;
		return Plugin_Stop;
	}

	// Display a countdown in the pickers server chat, when it's about to pick for them
	else if (PickTimeRemaining == 10 || (PickTimeRemaining <= 5 && PickTimeRemaining >= 1))
		PrintToChat(client, "\x05[xG] Auto-Select in %ds", PickTimeRemaining);
	
	if (DebugTeamPicking)
	{
		char message[64];
		Format(message, sizeof(message), "TIMER_CountdownPickTime(): counter: %d", PickTimeRemaining);		
		ConsoleToAdmins(message, "b");
	}

	return Plugin_Continue;
}

void AutoSelectPlayer(int picker)
{
	if (DebugTeamPicking)
		ConsoleToAdmins( "AutoSelectPlayer(): Started", "b");
	
	int playerToSelect = -1; float highestSkill = -2.0; float pSkill;
	for (int player = 0; player <= MaxClients; player++)
	{
		if (PlayerIsPickable(player))
		{
			pSkill = ND_GetPrecisePSkill(player);
			if (pSkill > highestSkill)
			{
				playerToSelect = player;
				highestSkill = pSkill;				
			}
		}
	}
	
	if (DebugTeamPicking)
		ConsoleToAdmins( "AutoSelectPlayer(): Searched", "b");
	
	// If we found a player, set their team and print their name
	if (playerToSelect != -1)
	{		
		if (DebugTeamPicking)
			ConsoleToAdmins( "AutoSelectPlayer(): Found player", "b");
		
		// Assign player to the team of the picker
		int team = GetClientTeam(picker);
		ChangeClientTeam(playerToSelect, team);
		
		// Print the auto assignment to server chat
		char playerName[64];
		GetClientName(playerToSelect, playerName, sizeof(playerName));		
		PrintToChatAll("%s was auto-selected to join %s!", playerName, ND_GetTeamName(team));
	}
	else 
	{
		noChoiceFound = true;
		if (DebugTeamPicking)
			ConsoleToAdmins( "AutoSelectPlayer(): Didn't find anybody", "b");
	}
}


