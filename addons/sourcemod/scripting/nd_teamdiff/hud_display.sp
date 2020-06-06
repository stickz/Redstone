Handle cookie_team_difference_hints = INVALID_HANDLE;
bool option_team_diff_hints[MAXPLAYERS + 1] = {true,...}; //off by default

void loadHudDisplayFeature()
{
	cookie_team_difference_hints = RegClientCookie("TeamDiff Hints On/Off", "", CookieAccess_Protected);
	int info;
	SetCookieMenuItem(CookieMenuHandler_TeamDiffHints, view_as<any>(info), "TeamDiff Hints");
}

public Action TIMER_UpdateTeamDiffHint(Handle Timer)
{
	if (!ND_GEA_AVAILBLE() || !ND_GED_AVAILBLE())
		return Plugin_Stop;
	
	displayTeamDiffUpdate();
	return Plugin_Continue;
}

public int CookieMenuHandler_TeamDiffHints(int client, CookieMenuAction action, int info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			char status[10];
			Format(status, sizeof(status), "%T", option_team_diff_hints[client] ? "On" : "Off", client);		
			Format(buffer, maxlen, "%T: %s", "Cookie TeamDiff Hints", client, status);		
		}
		
		case CookieMenuAction_SelectOption:
		{
			option_team_diff_hints[client] = !option_team_diff_hints[client];		
			SetClientCookie(client, cookie_team_difference_hints, option_team_diff_hints[client] ? "On" : "Off");		
			ShowCookieMenu(client);		
		}	
	}
}

public void OnClientCookiesCached(int client) {
	option_team_diff_hints[client] = GetCookieTeamDiffHints(client);
}

bool GetCookieTeamDiffHints(int client)
{
	char buffer[10];
	GetClientCookie(client, cookie_team_difference_hints, buffer, sizeof(buffer));
	
	return StrEqual(buffer, "On");
}

void displayTeamDiffUpdate()
{	
	/* Get the team difference */
	float teamDiff = ND_GetTeamDifference();
	
	/* Get average skill, if not availible fill in junk */
	float average = ND_GetEnhancedAverage();	
	if (average < 0)
		average = teamDiff;
	
	/* Get which team is has more skill, ensure teamdiff is a positve number */
	char stackedTeam[12];
	if (teamDiff > 0)
		Format(stackedTeam, sizeof(stackedTeam), "Consort"); 
	else
	{
		Format(stackedTeam, sizeof(stackedTeam), "Empire");
		teamDiff *= -1; // Convert to positive		
	}
	
	/* Calc difference and convert to a percentage */
	float totalFloat = teamDiff / average * 100.0;	
	int diffPercent = RoundFloat(totalFloat);
	
	/* Build the difference string ex. Empire +78% or Consort +21% */
	char hudText[24];	
	Format(hudText, sizeof(hudText), "%s +%d%", stackedTeam, diffPercent);
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (option_team_diff_hints[idx] && RED_IsValidClient(idx) && isOnTeam(idx))
		{
			if (!IsPlayerAlive(idx))
			{
				PrintHintText(idx, "");
				continue;
			}
		
			PrintHintText(idx, "%s", hudText);
		}
	}
}
