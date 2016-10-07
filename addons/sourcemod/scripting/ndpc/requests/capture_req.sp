bool CheckCaptureRequest(int client, const char[] sArgs)
{
	if (!g_Enable[CaptureReqs].BoolValue)
		return false; //don't use this feature if not enabled
	
	if (StrStartsWith(sArgs, "capture")) //if the string starts with capture
	{
		int resource = GetCaptureByIndex(sArgs);
		
		if (foundInChatMessage(resource))
		{
			int compass = GetCompassByIndex(sArgs);
			
			if (foundInChatMessage(compass))
			{
				// To Do: Make a new phrase to include compass position in chat requests
				PrintCaptureRequest(client, nd_request_capture[resource]);
				return true;
			}
		
			PrintCaptureRequest(client, nd_request_capture[resource]);
			return true;
		}

		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintCaptureRequest(int client, const char[] rName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char resource[64];
				Format(resource, sizeof(resource), "%T", rName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Capture Request", idx, cName, resource);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag",
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}