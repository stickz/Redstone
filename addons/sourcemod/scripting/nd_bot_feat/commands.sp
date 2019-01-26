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
	// Print the physical player difference from 1-5 for bot counts
	PrintToConsole(client, "--> Physical Player Difference <--");	
	float phys = g_cvar[BotDiffMult].FloatValue;	
	for (int pNum = 1; pNum <= 5; pNum++)
	{
		int value = RoundPowToNearest(float(num), phys);
		PrintToConsole(client, "Round: %d ^ %.2f = %d", pNum, phys, value);
	}
	
	// Print a spacer in console, before starting the next section
	PrintToConsole(client, "");
	
	// Print the skill percent difference from 1-5 for bot counts
	PrintToConsole(client, "--> Skill Percent Difference <--");	
	float skill = g_cvar[BotSkillMult].FloatValue;
	for (int sNum = 1; sNum <= 5; sNum++)
	{
		int value = RoundPowToNearest(float(num), skill);
		PrintToConsole(client, "Round: %d% ^ %.2f = %d", sNum*100, skill, value);
	}

	return Plugin_Handled;
}
