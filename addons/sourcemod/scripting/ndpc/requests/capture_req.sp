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
		// print capture message, return false if keyword not found
		return cPrintChatMessage(client, team, pName, sArgs);
	}
	
	return false;
}

bool cPrintChatMessage(int client, int team, const char[] pName, const char[] sArgs)
{
	int resource = GetCaptureByIndex(sArgs);
		
	if (foundInChatMessage(resource))
	{
		int compass = GetCompassByIndex(sArgs);	
		int location = GetSpotByIndexCAP(sArgs);
		
		if (foundInChatMessage(compass))
			NDPC_PrintRequestS2(team, pName, "Compass Capture Request",
							nd_request_capture[resource], 
							nd_request_compass[compass]);
		else if (foundInChatMessage(location))
			NDPC_PrintRequestS2(team, pName, "Location Capture Request",
							nd_request_capture[resource], 
							nd_request_location_ex[location]);		
		else		
			NDPC_PrintRequestS1(team, pName, "Simple Capture Request",
							nd_request_capture[resource]);
		return true;
	}
	else if (StrIsWithin(sArgs, "res") || StrIsWithin(sArgs, "point") || StrIsWithin(sArgs, "income"))
	{
		NDPC_PrintRequestS0(team, pName, "Generic Capture Request");
		return true;	
	}
	else
	{
		NoTranslationFound(client, sArgs);
		return false;	
	}
}
