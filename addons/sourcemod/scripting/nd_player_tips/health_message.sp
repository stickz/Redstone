bool DisplayedHealthWarning[MAXPLAYERS+1] = { false, ... };

void ResetDisplayedHealth() {
	for (int client = 1; client <= MaxClients; client++) {
		DisplayedHealthWarning[client] = false;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!ND_RoundStarted())
		return Plugin_Continue;		
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && option_player_tips[client] && !DisplayedHealthWarning[client])
	{
		int team = GetClientTeam(client);
		if (isOnTeam(client) && LowAverageHealth(team) && GetMedicCount(team) < 2 && RED_GetTeamCount(team) >= 8)
		{
			PrintMessage(client, "Low Team Health");		
			DisplayedHealthWarning[client] = true;
		}
	}
	
	
	return Plugin_Continue;
}

bool LowAverageHealth(int team)
{
	float totalPercent = 0.0;
	int healthCount = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == team)
		{
			int maxHealth = ND_GetMaxHealth(client);
			int currentHealth = GetClientHealth(client);
			
			totalPercent = float(currentHealth) / float(maxHealth);
			healthCount++;
		}
	}
	
	return totalPercent / float(healthCount) <= 0.6;
}

int GetMedicCount(int team) {
	return NDB_GetUnitCount(team, view_as<int>(uMedic));	
}