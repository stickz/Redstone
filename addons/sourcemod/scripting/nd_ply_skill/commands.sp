void RegisterCommands()
{
	RegConsoleCmd("sm_DumpFSkillData", CMD_DumpClientFSkill);
	RegConsoleCmd("sm_DumpSkillValues", CMD_DumpClientFSkill);
}

public Action CMD_DumpClientFSkill(int client, int args)
{
	dumpClientValues(client, true);
	PrintToChat(client, "See output in console.");
	return Plugin_Handled;
}

void dumpClientValues(int player, bool showJunk = false)
{
	if (showJunk)
	{
		PrintSpacer(player);
		PrintToConsole(player, "eSPMav: %d, cSPMav: %d, AVL: %d", getSPMaverage(TEAM_EMPIRE), getSPMaverage(TEAM_CONSORT), RoundFloat(lastAverage));
	}
	
	PrintSpacer(player); PrintSpacer(player);
	PrintToConsole(player, "--> Player FSkill Values <--");
	PrintToConsole(player, "Format: Name, Skill, ScorePerMinute * 100, SessionTime");
	PrintSpacer(player);
	
	for (int team = 0; team < 4; team++)
	{
		if (RED_GetTeamCount(team) > 0)
		{
			PrintToConsole(player, "Team %s:", ND_GetTeamName(team));
			dumpClientsOnTeam(team, player);
			PrintSpacer(player);
		}
	}
}

void dumpClientsOnTeam(int team, int player)
{
	float linearClientRank;
	
	char Name[32];
	RED_LOOP_CLIENTS(client)
	{
		if (GetClientTeam(client) == team)
		{
			linearClientRank = GetSkillLevel(client);
			
			GetClientName(client, Name, sizeof(Name));
			PrintToConsole(player, "Name: %s, Skill: %d, SPM: %d, CT: %d", Name, RoundFloat(linearClientRank), scorePerMinute[client], connectionTime[client]);	
		}
	}
}

void PrintSpacer(int player) {
	PrintToConsole(player, "");
}