void RegisterPluginCMDS()
{
	RegConsoleCmd("sm_DisableBots", CMD_DisableBots, "Disables bots until round end");
	RegConsoleCmd("sm_botpow", CMD_GetBotPow, "Checks bot pow for player difference");
}

public Action CMD_DisableBots(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	disableBots = !disableBots;
	
	if (disableBots)
	{
		PrintToChat(client, "Server bots disabled until round end.");
		SignalMapChange(); // Disable booster and set bot count to 0
	}
	else
	{
		PrintToChat(client, "Server bots have been re-enabled.");
		InitializeServerBots(); // Add the bots back in before the next update
	}
	
	return Plugin_Handled;
}

public Action CMD_GetBotPow(int client, int args)
{
	float exp = g_cvar[BotDiffMult].FloatValue;
	
	for (int num = 1; num <= 5; num++)
	{
		int value = GetBotCountByPow(float(num), exp);
		PrintToConsole(client, "Round: %d ^ %f = %d", num, exp, value);
	}

	return Plugin_Handled;
}
