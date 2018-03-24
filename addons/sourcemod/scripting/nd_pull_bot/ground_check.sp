float coords[MAXPLAYERS+1][2];

void RegBotGroundCheck() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
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

		// Get the bunker belonging to the bot team
		int team = GetClientTeam(client);
		int bunker = ND_GetTeamBunkerEntity(team);
		
		// To Do: Cache bunker position in the entity engine
		// Note: nd_commander_checklist also references this		
		float bunkerPos[3]; // Get the position of the bunker
		GetEntPropVector(bunker, Prop_Send, "m_vecOrigin", bunkerPos);			
		
		// Teleport bot out, if they're close to the bunker (base spawn)
		if (GetVectorDistance(pos, bunkerPos) < gCheck_BunkerDistance.FloatValue)
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Continue;
}
