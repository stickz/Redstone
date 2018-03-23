#define fMaxDistance 300.0

void RegPullBotCommand() {
	RegConsoleCmd("sm_PullBot", Command_pull);
}

public Action Command_pull(client, args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

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
			if(GetVectorDistance(vecOrigin, vecPos) < fMaxDistance) 
			{
				TeleportEntity(target, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "bot moved");
			}
			
			else
				PrintToChat(client, "bot too far");
		}
	}	
	CloseHandle(hTrace);
	
	return Plugin_Handled;
}

public bool TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity < MaxClients && IsFakeClient(entity);
}