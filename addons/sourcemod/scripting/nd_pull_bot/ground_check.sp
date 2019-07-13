float coords[MAXPLAYERS+1][2];

void RegBotGroundCheck() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));	
	if (IsFakeClient(client))
	{
		// Get the position of the bot
		float pos[3];
		GetClientEyePosition(client, pos);
		
		// Update the new coordinates of the bot.
		coords[client][0] = pos[0];
		coords[client][1] = pos[1];
		
		// Wait 8 seconds before checking, so bots can capture resources (if required)
		CreateTimer(gCheck_SpawnDelay.FloatValue, Timer_CheckBot, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action Timer_CheckBot(Handle timer, any userid) 
{
	// Get the bot index, return if invalid
	int client = GetClientOfUserId(userid);	
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	// Get the position of the bot
	float pos[3];
	GetClientEyePosition(client, pos);
	
	// If the bot is stuck in the ground, teleport them up
	if (coords[client][0] == pos[0] && coords[client][1] == pos[1]) 
	{
		pos[2] += 20.0;		
		
		// Get the bunker distance from the bot position
		float bunkerDistance = ND_GetBunkerDistance(GetClientTeam(client), pos);
		
		// Teleport bot out, if they're close to the bunker (base spawn)
		if (bunkerDistance < gCheck_BunkerDistance.FloatValue)
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Continue;
}
