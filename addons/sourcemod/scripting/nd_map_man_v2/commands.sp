bool mapListCooldown[MAXPLAYERS + 1] = {false, ...};

void CreateCommands()
{
	RegAdminCmd("sm_TriggerMapVote", CMD_TriggerMapVote, ADMFLAG_KICK, "Triggers a map vote");
	RegAdminCmd("sm_FakeMapVote", CMD_FakeMapVote, ADMFLAG_KICK, "Triggers a fake map vote");
	RegAdminCmd("sm_AddMapExclude", CMD_AddMapExclude, ADMFLAG_KICK, "Adds a map exclude");	
	RegAdminCmd("sm_WriteMapExcludes", CMD_WriteMapExcludes, ADMFLAG_KICK, "Writes map excludes");
	RegAdminCmd("sm_PrintMapExcludes", CMD_PrintMapExcludes, ADMFLAG_KICK, "Prints map excludes");	
	RegAdminCmd("sm_ReadMapExcludes", CMD_ReadMapExcludes, ADMFLAG_KICK, "Read map excludes");
	
	RegConsoleCmd("sm_ListPreviousMaps", CMD_ListPreviousMaps, "lists the previous maps in client console");
}

public Action CMD_ListPreviousMaps(int client, int args)
{
	if (mapListCooldown[client])
	{
		PrintToChat(client, "\x05[xG] %t", "Wait Map List", cvarMapListCooldown.IntValue);
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x05[xG] %t", "Prev Maps Listed");	
	PrintSpacer(client);
	PrintToConsole(client, "--> Previous Maps Played <---");
	
	int number;
	char mapName[32];
	
	int store = g_PreviousMapList.Length - 1;
	for (int idx = store; idx >= 0; idx--)
	{
		number = store - idx + 1;
		g_PreviousMapList.GetString(idx, mapName, sizeof(mapName));
		
		PrintToConsole(client, "%d. %s", number, mapName);	
	}
	PrintSpacer(client);
	
	mapListCooldown[client] = true;
	float time = cvarMapListCooldown.FloatValue;
	CreateTimer(time, TIMER_MapListCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}

public Action TIMER_MapListCooldown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid)
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	mapListCooldown[client] = false;
	return Plugin_Handled;
}

public Action CMD_ReadMapExcludes(int client, int args)
{
	ReadTextFile();	
	return Plugin_Handled;
}

public Action CMD_AddMapExclude(int client, int args)
{
	if (args != 1)
	{
		PrintToChat(client, "\x05[xG] Incorrect arg count");
		return Plugin_Handled;
	}
	
	char MapArg[50];
	GetCmdArg(1, MapArg, sizeof(MapArg));
	PushArrayString(g_PreviousMapList, MapArg);
	
	WriteTextFile();
	ParseExcludedMaps();
	
	PrintToChat(client, "\x05[xG] %s added to excludes", MapArg);
	return Plugin_Handled;
}

public Action CMD_TriggerMapVote(int client, int args)
{
	if (IsVoteInProgress())
	{
		PrintToChat(client, "\x05[xG] Vote in Progress");
		return Plugin_Handled;
	}
	
	if (!TestVoteDelay(client))
		return Plugin_Handled;		
	
	StartAndSetupMapVoter();
	return Plugin_Handled;
}

public Action CMD_FakeMapVote(int client, int args)
{
	StartAndSetupMapVoter();
	return Plugin_Handled;
}

public Action CMD_WriteMapExcludes(int client, int args)
{
	PrintToChat(client, "\x05[xG] Maps written to the text file");
	
	WriteTextFile();
	return Plugin_Handled;
}

public Action CMD_PrintMapExcludes(int client, int args)
{
	for (int idx = 0; idx < GetArraySize(g_PreviousMapList); idx++)
	{
		char lastMap[32];
		GetArrayString(g_PreviousMapList, idx, lastMap, sizeof(lastMap));
		
		PrintToChat(client, "\x05[xG] This is index %d", idx);
		PrintToChat(client, "\x05[xG] The value here is %s", lastMap);	
	}
	
	return Plugin_Handled;
}