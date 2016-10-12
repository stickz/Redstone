#define MAX_CAPTURE_SPACECOUNT 3

bool CheckCaptureRequest(int client, int team, int spacesCount, const char[] pName, const char[] sArgs)
{
	if (!g_Enable[CaptureReqs].BoolValue)
		return false; //don't use this feature if not enabled
		
	//If the spacecount is greater than the required amount for capture requests
	if (spacesCount > MAX_CAPTURE_SPACECOUNT)
		return false;
	
	if (StrStartsWith(sArgs, "capture")) //if the string starts with capture
	{
		int resource = GetCaptureByIndex(sArgs);
		
		if (foundInChatMessage(resource))
		{
			int compass = GetCompassByIndex(sArgs);
			
			if (foundInChatMessage(compass))
			{
				PrintExtendedCaptureRequest(	client, team, pName,
								nd_request_capture[resource], 
								nd_request_compass[compass]);
				return true;
			}
		
			PrintSimpleCaptureRequest(client, team, pName, nd_request_capture[resource]);
			return true;
		}

		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintSimpleCaptureRequest(int client, int team, const char[] pName, const char[] rName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{
			char resource[64];
			Format(resource, sizeof(resource), "%T", rName, idx);
			
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Simple Capture Request", idx, resource);
				
			NDPC_PrintToChat(idx, pName, ToPrint);
		}
	}
}

void PrintExtendedCaptureRequest(int client, int team, const char[] pName, const char[] rName, const char[] lName)
{		
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{
			char resource[64];
			Format(resource, sizeof(resource), "%T", rName, idx);
				
			char compass[32];
			Format(compass, sizeof(compass), "%T", lName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Extended Capture Request", idx, compass, resource);
				
			NDPC_PrintToChat(idx, pName, ToPrint);
		}
	}	
}
