#define MAX_CAPTURE_SPACECOUNT 3

bool CheckCaptureRequest(int client, const char[] sArgs)
{
	if (!g_Enable[CaptureReqs].BoolValue)
		return false; //don't use this feature if not enabled
		
	//If the spacecount is greater than the required amount for capture requests
	if (GetStringSpaceCount(sArgs) > MAX_CAPTURE_SPACECOUNT)
		return false;
	
	if (StrStartsWith(sArgs, "capture")) //if the string starts with capture
	{
		int resource = GetCaptureByIndex(sArgs);
		
		if (foundInChatMessage(resource))
		{
			int compass = GetCompassByIndex(sArgs);
			
			if (foundInChatMessage(compass))
			{
				PrintExtendedCaptureRequest(client, nd_request_capture[resource], nd_request_compass[compass]);
				return true;
			}
		
			PrintSimpleCaptureRequest(client, nd_request_capture[resource]);
			return true;
		}

		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintSimpleCaptureRequest(int client, const char[] rName)
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
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Capture Request", idx, cName, resource);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag",
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}

void PrintExtendedCaptureRequest(int client, const char[] rName, const char[] lName)
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
				
				char compass[32];
				Format(compass, sizeof(compass), "%T", lName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Extended Capture Request", idx, cName, compass, resource);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag",
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}
