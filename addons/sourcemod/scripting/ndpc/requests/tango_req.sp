#define MAX_TANGO_SPACECOUNT 4

// Check if the user is inputing a building request in chat
bool CheckTangoRequest(int client, int team, int spacesCount, const char[] pName, const char[] sArgs)
{
	//If building requests are disabled on the server end, don't use them
	if (!g_Enable[TangoReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for tango requests
	if (spacesCount > MAX_TANGO_SPACECOUNT)
		return false;
	
	//If the chat messages starts with the word tango"
	if (StrStartsWith(sArgs, "tango"))
	{
		//print a translated building request
		taPrintMessage(client, team, pName, sArgs);
		return true;	
	}
	
	return false;
}

void taPrintMessage(int client, int team, const char[] pName, const char[] sArgs)
{
	//Get the phrases the user is asking for
	int building = GetBuildingByIndexEx(sArgs);
	int location = GetSpotByIndexEx(sArgs);
	int compass = GetCompassByIndex(sArgs);
	
	//Cache the result of wether or not a phrase type is found
	bool foundCompassName = foundInChatMessage(compass);
	bool foundLocationName = foundInChatMessage(location);
	
	//If a valid building name or alasis is found
	if (foundInChatMessage(building))
	{
		//If a valid location is found
		if (foundLocationName)
		{
			//if a valid compass position is found
			if (foundCompassName)
				NDPC_PrintRequestS3(team, pName, "Complex Tango Request",
								nd_request_building[building], 
								nd_request_location[location],
								nd_request_compass[compass]);		
			else 			
				NDPC_PrintRequestS2(team, pName, "Spot Tango Request",
								nd_request_building[building], 
								nd_request_location[location]);			
		}
		//if a valid compass position is found
		else if (foundCompassName)
			NDPC_PrintRequestS2(team, pName, "Compass Tango Request",
							nd_request_building[building], 
							nd_request_compass[compass]);
		else 				
			NDPC_PrintRequestS1(team, pName, "Tango Building", 
							nd_request_building[building]);		
	}
	
	else if (foundCompassName)
		NDPC_PrintRequestS1(team, pName, "Tango Compass", 
						nd_request_compass[compass]);	
	else if (foundLocationName)
		NDPC_PrintRequestS1(team, pName, "Tango Location", 
						nd_request_location[location]);	
	else 			
		NoTranslationFound(client, sArgs);
}
