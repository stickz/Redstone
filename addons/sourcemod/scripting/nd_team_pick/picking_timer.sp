#define INVALID_USERID 0
#define NO_PLAYERS_LEFT 0
bool lastTimerEnded = false;
bool noChoiceFound = false;
int PickTimeRemaining = 0;
Handle hPickTimerHandler = INVALID_HANDLE;

void ResetPickTimer(int client)
{
	if (lastTimerEnded)
		lastTimerEnded = false
	else if (hPickTimerHandler != INVALID_HANDLE && IsValidHandle(hPickTimerHandler))
		KillTimer(hPickTimerHandler, false);
	
	PickTimeRemaining = GetPickingTimeLimit();	
	hPickTimerHandler = CreateTimer(1.0, TIMER_CountdownPickTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_CountdownPickTime(Handle timer, any:userid)
{
	if (DebugTeamPicking)
		ConsoleToAdmins( "TIMER_CountdownPickTime(): iterated", "b");
	
	// If the team pick was stopped, kill the timer
	if (!g_bPickStarted)
		return Plugin_Stop;
	
	// Get the client from userid, if invalid stop timer
	int client = GetClientOfUserId(userid);
	if (client == INVALID_USERID)		
		return Plugin_Stop;
	
	if (DebugTeamPicking)
		ConsoleToAdmins( "TIMER_CountdownPickTime(): valid client", "b");
	
	// Get the spectator team count, if zero stop the timer
	int specCount = DebugTeamPicking ? ValidTeamCountEx(TEAM_SPEC) : RED_GetTeamCount(TEAM_SPEC);
	if (specCount == NO_PLAYERS_LEFT)
		return Plugin_Stop;
	
	if (DebugTeamPicking)
		ConsoleToAdmins( "TIMER_CountdownPickTime(): spectators left", "b");
	
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
	else if (DisplayPickWarning())
		PrintToChat(client, "\x05[xG] %t.", "Auto Select", PickTimeRemaining);
	
	if (DebugTeamPicking)
	{
		char message[64];
		Format(message, sizeof(message), "TIMER_CountdownPickTime(): counter: %d", PickTimeRemaining);		
		ConsoleToAdmins(message, "b");
	}

	return Plugin_Continue;
}

bool DisplayPickWarning()
{
	switch (PickTimeRemaining) {
		case 10, 5, 4, 3, 2, 1: return true;	
	}
	
	return false;
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
		PrintAutoSelected(playerToSelect, team);
	}
	else 
	{
		noChoiceFound = true;
		if (DebugTeamPicking)
			ConsoleToAdmins( "AutoSelectPlayer(): Didn't find anybody", "b");
	}
}

void PrintAutoSelected(int player, int team)
{
	char playerName[64];
	GetClientName(player, playerName, sizeof(playerName));
	
	char teamName[32];
	Format(teamName, sizeof(teamName), ND_GetTeamName(team));
	
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "%t", "Auto Selected Join", playerName, teamName);
		}
	}		
}


