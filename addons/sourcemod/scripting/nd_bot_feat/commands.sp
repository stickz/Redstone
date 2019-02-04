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
		int value = RoundPowToNearest(float(pNum), phys);
		PrintToConsole(client, "Round: %d ^ %.2f = %d", pNum, phys, value);
	}
	
	// Print a spacer in console, before starting the next section
	PrintToConsole(client, "");
	
	// Print the high skill percent difference from 100% to 500% for uneven bot counts
	PrintToConsole(client, "--> Low Uneven Skill Percent Difference <--");
	WriteConsoleSkillValues(client, g_cvar[BotSkillMultLow].FloatValue);
	
	// Print a spacer in console, before starting the next section
	PrintToConsole(client, "");
	
	// Print the high skill percent difference from 100% to 500% for uneven bot counts
	PrintToConsole(client, "--> High Uneven Skill Percent Difference <--");
	WriteConsoleSkillValues(client, g_cvar[BotSkillMultHigh].FloatValue);
	
	// Print a spacer in console, before starting the next section
	PrintToConsole(client, "");
	
	// Print the skill percent difference from 150% to 400% for even bot counts
	PrintToConsole(client, "--> Even Skill Percent Difference <--");
	WriteConsoleSkillValues(client, g_cvar[BotEvenSkillMult].FloatValue);
	
	// Print a spacer in console, before starting the next section
	PrintToConsole(client, "");

	return Plugin_Handled;
}

void WriteConsoleSkillValues(int client, float mult)
{
	// How to solve exponential equations
	// 5 ^ x = 9 --> x = Logarithm(9, 5)
	// x ^ 5 = 9 --> x = Pow(9, 1/5)
	
	for (int base = 1; base <= 10; base++)
	{
		float value = Pow(float(base), 1.0 / mult) * 100.0;
		PrintToConsole(client, "Round: %d% ^ %.2f = %d", RoundToNearest(value), mult, base);
	}
}
