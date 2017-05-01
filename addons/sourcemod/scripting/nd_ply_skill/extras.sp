float GetTeamSkillAverage(int team)
{
	float average = 0.0;
	int count = 0;
	
	RED_LOOP_CLIENTS(client)
	{
		if (GetClientTeam(client) == team && !ND_IsCommander(client))
		{
			average += GetSkillLevel(client);
			count++;			
		}
	}
	
	return average / float(count);
}

float GetTeamSkillTotal(int team)
{
	float total = 0.0;
	
	RED_LOOP_CLIENTS(client)
	{
		if (GetClientTeam(client) == team)
		{
			total += GetSkillLevel(client);			
		}
	}

	return total;
}

float GetTeamDifference() {
	return GetTeamSkillTotal(TEAM_CONSORT) - GetTeamSkillTotal(TEAM_EMPIRE);	
}