void RegisterCommands()
{
	RegConsoleCmd("sm_teamdiff", CMD_TeamDiff);
	RegConsoleCmd("sm_stacked", CMD_TeamDiff);
	RegConsoleCmd("sm_diff", CMD_TeamDiff);
}

/* Check the skill difference between both teams */
public Action CMD_TeamDiff(int client, int args)
{
	if (!ND_RoundStarted())
	{
		PrintToChat(client, "\x05[TB] %t!", "Teamdiff Round Wait");
		return Plugin_Handled;
	}
	
	/* Get the team difference */
	float teamDiff = ND_GetTeamDifference();
	
	/* Get which team is stacked */
	char stackedTeam[16];
	Format(stackedTeam, sizeof(stackedTeam), "%T", teamDiff > 0 ? "Consortium" : "Empire", client);
	
	/* Convert teamdiff to positive, if it's negative */
	if (teamDiff < 0)
		teamDiff *= -1;
	
	/* Cache varriables to cleanup printing */
	float average = ND_GetEnhancedAverage();
	float fpSkill = ND_GetPlayerSkill(client);
	
	if (average <= 60)
	{
		int td = RoundFloat(teamDiff);
		int pSkill = RoundFloat(fpSkill);
		int rAvg = RoundFloat(average);
		PrintToChat(client, "\x05[TB] %s +%d/%d %t! Your Skill: %d/%d!", 
							stackedTeam, td, rAvg, "Skill", pSkill, rAvg);
	}
	else
	{
		int diff = RoundFloat(teamDiff / average * 100);
		int skill = RoundFloat(fpSkill / average * 100);
		PrintToChat(client, "\x05[TB] %s +%d Percent! Your Skill: %d Percent!", 
							stackedTeam, diff, skill);
	}
						
	return Plugin_Handled;
}