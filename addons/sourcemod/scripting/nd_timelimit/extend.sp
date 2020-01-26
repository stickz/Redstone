public Action CMD_Extend(int client, int args)
{	
	callExtend(client);	
	return Plugin_Handled;
}

bool strEqualsExtend(int client, const char[] sArgs) 
{
	if (strcmp(sArgs, "extend", false) == 0)
	{
		callExtend(client);
		return true;
	}
	
	return false;
}

void PrintExtendToEnabled()
{
	for (int idx = 0; idx < MAXPLAYERS; idx++)
	{
		if (IsValidClient(idx) && option_timelimit_features[idx]) {
			PrintMessage(idx, "Extend Availible");	
		}
	}
}

void callExtend(int client)
{
	int team = GetClientTeam(client);
	
	if (ValidTeamCount(team) < g_Cvar[extendMinPlayers].IntValue)
		PrintMessage(client, "Six Required");
	
	else if (!g_Bool[enableExtend])
		PrintMessage(client, "Wait End");
		
	else if (g_Bool[hasExtended])
		PrintMessage(client, "Already Extended");
		
	else if (team < 2)
		PrintMessage(client, "On Team");
		
	else if (g_hasVotedEmpire[client] || g_hasVotedConsort[client])
		PrintMessage(client, "You Extended");
		
	else if (g_Bool[roundHasEnded])
		PrintMessage(client, "Round Ended");

	else
	{
		voteCount[team -2]++;
		
		switch (team)
		{
			case TEAM_CONSORT: g_hasVotedConsort[client] = true;
			case TEAM_EMPIRE: g_hasVotedEmpire[client] = true;
		}

		checkVotes(true, team, client);		
	}
}

void resetValues(int client)
{
	int team;
	
	if (g_hasVotedConsort[client])
	{
		team = TEAM_CONSORT;
		g_hasVotedConsort[client] = false;
	}
	
	else if (g_hasVotedEmpire[client])
	{
		team = TEAM_EMPIRE;
		g_hasVotedEmpire[client] = false;
	}	
	
	if (team > TEAM_SPEC)
	{
		voteCount[team - 2]--;
		if (ND_GetClientCount() < g_Cvar[extendMinPlayers].IntValue && !g_Bool[roundHasEnded] && !g_Bool[hasExtended] && g_Bool[enableExtend])
			checkVotes(false);		
	}
}

void checkVotes(bool display, int team = -1, int client = -1)
{
	float teamPercent = g_Cvar[extendPercentage].FloatValue / 100.0;
	
	float teamEmpireCount = ValidTeamCount(TEAM_EMPIRE) * teamPercent;
	float teamConsortCount = ValidTeamCount(TEAM_CONSORT) * teamPercent;
	float empireRemainder = teamEmpireCount - float(voteCount[TEAM_EMPIRE - 2]);
	float consortRemainder = teamConsortCount - float(voteCount[TEAM_CONSORT - 2]);		
			
	if (empireRemainder <= 0 && consortRemainder <= 0)
		extendTime();
		
	else if (display)
		displayVotes(team, empireRemainder, consortRemainder , client);
}

void extendTime()
{
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (!g_Bool[noTimeLimit])
	{
		int roundTime = g_Cvar[regularTimeLimit].IntValue; // the time we extend matches by
		
		if (	StrEqual(currentMap, ND_CustomMaps[ND_Corner], false) || 
			StrEqual(currentMap, ND_StockMaps[ND_Silo], false)) {
				roundTime = g_Cvar[extendedTimeLimit].IntValue;
		}		
			
		ServerCommand("mp_roundtime %d", roundTime);
	}
	else
		g_Integer[totalTimeLeft] = g_Cvar[extendTimeLimit].IntValue;		
		
	g_Bool[hasExtended] = true;
	g_Bool[justExtended] = true;
	PrintMessageAll("Round Extended");
}

void displayVotes(int team, float empireRemainder, float consortRemainder, int client)
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	if (empireRemainder >= 1 && consortRemainder >= 1) // Vertex typed extend: 5 con & 5 Emp required
		PrintToChatAll("\x05%t", "Extend Both", name, RoundToCeil(consortRemainder), RoundToCeil(empireRemainder));
	
	else if (team == TEAM_EMPIRE && empireRemainder >= 1) // Vertex typed extend: 5 empire required
		PrintToChatAll("\x05%t", "Extend Empire", name, RoundToCeil(empireRemainder));
	
	else if (team == TEAM_CONSORT && consortRemainder >= 1) // Vertex typed extend: 5 consort required
		PrintToChatAll("\x05%t", "Extend Consort", name, RoundToCeil(consortRemainder));
}
