bool CanPullBot[MAXPLAYERS+1] = { true , ... };

void RegPullBotCommand() {
	RegConsoleCmd("sm_PullBot", Command_pull);
	RegConsoleCmd("sm_MoveBot", Command_pull);
}

void ResetPullCooldowns() {
	for (int client = 1; client <= MaxClients; client++)
		CanPullBot[client] = true;
}

public Action Command_pull(client, args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
		
	if (!CanPullBot[client])
	{
		// To Do: Move this phrase "Please wait %d seconds for this feature" to nd_common.phrases
		PrintMessageTI1(client, "Pull Retry Delay", mBot_RetryDelay.IntValue);			     
		return Plugin_Handled;
	}

    	// Get the angle the player is looking
	float vecAngles[3];
	GetClientEyeAngles(client, vecAngles);
	
	// Get the location position the player is looking
	float vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);	
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(hTrace)) 
	{
		//This is the first function i ever saw that anything comes before the handle
		float vecPos[3];
		TR_GetEndPosition(vecPos, hTrace);
		
		int target = TR_GetEntityIndex(hTrace);
		if (target > 0 && IsFakeClient(target)) 
		{
			float botDistance = GetVectorDistance(vecOrigin, vecPos);
			float maxDistance = mBot_MaxDistance.FloatValue;
			if(botDistance < maxDistance) 
			{
				TeleportEntity(target, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				PrintMessage(client, "Bot Pull Successful");
			}
			
			else
			{
				int units = botDistance - maxDistance; 
				PrintMessageTI1(client, "Bot Too Far", units);
			}
		}
		else
			PrintMessage(client, "Bot Not Found");
	}	
	CloseHandle(hTrace);
	
	// Create cooldown before the client can pull a bot again
	CanPullBot[client] = false;
	CreateTimer(mBot_RetryDelay.FloatValue, PullBotCooldown, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action PullBotCooldown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	CanPullBot[client] = true;	
	return Plugin_Continue;
}

public bool TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity < MaxClients && IsFakeClient(entity);
}
