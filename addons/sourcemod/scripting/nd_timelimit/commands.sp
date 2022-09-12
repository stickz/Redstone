void regConsoleCommands()
{
	RegConsoleCmd("sm_timeleft", CMD_Time);
	RegConsoleCmd("sm_time", CMD_Time);	
	RegConsoleCmd("sm_extend", CMD_Extend);	
}	

public Action CMD_Time(int client, int args) 
{
	printTime(client);
	return Plugin_Continue;
}

bool strEqualsTime(int client, const char[] sArgs)
{
	for (int idx = 0; idx < TIMELIMIT_COMMANDS_SIZE; idx++)
		if (strcmp(sArgs, nd_timelimit_commands[idx], false) == 0)
		{
			printTime(client);
			return true;
		}
		
	return false;
}

void printTime(int client)
{
	if (!g_Bool.noTimeLimit)
		PrintMessage(client, "Regular Time");
		
	else if (g_Bool.startedCountdown)
		PrintToChat(client, "\x05[xG] There are %d minutes remaining!", g_Integer.totalTimeLeft);
	
	else if (ND_RoundStarted())
		PrintMessage(client, "Time Disabled");
}
