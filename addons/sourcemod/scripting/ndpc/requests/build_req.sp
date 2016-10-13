#define MAX_BUILDING_SPACECOUNT 4

// Check if the user is inputing a building request in chat
bool CheckBuildingRequest(int client, int team, int spacesCount, const char[] pName, const char[] sArgs)
{
	//If building requests are disabled on the server end, don't use them
	if (!g_Enable[BuildingReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for building requests
	if (spacesCount > MAX_BUILDING_SPACECOUNT)
		return false;

	//If the chat messages starts with the word "build"
	if (StrStartsWith(sArgs, "build"))
	{
		//print a translated building request
		bPrintMessage(client, team, pName, sArgs);
		return true;
	}
	
	return false;
}

void bPrintMessage(int client, int team, const char[] pName, const char[] sArgs)
{
	//Get the building the user is asking for
	int building = GetBuildingByIndexEx(sArgs);
		
	//If a valid building name or alasis is found
	if (foundInChatMessage(building))
	{
		//optionally, check if the user is asking for a location or compass
		int location = GetSpotByIndex(sArgs);
		int compass = GetCompassByIndex(sArgs);
			
		bool foundCompassName = foundInChatMessage(compass);
			
		//If a valid location is found
		if (foundInChatMessage(location))
		{
			//if a valid compass position is found
			if (foundCompassName)
				NDPC_PrintRequestS3(team, pName, "Complex Building Request",
								nd_request_building[building], 
								nd_request_location[location],
								nd_request_compass[compass]);		
			else 			
				NDPC_PrintRequestS2(team, pName, "Spot Building Request",
								nd_request_building[building], 
								nd_request_location[location]);			
		}
		//if a valid compass position is found
		else if (foundCompassName)
			NDPC_PrintRequestS2(team, pName, "Compass Building Request"
							nd_request_building[building], 
							nd_request_compass[compass]);
		else 				
			NDPC_PrintRequestS1(team, pName, "Simple Building Request", 
							nd_request_building[building]);		
	} 
	
	else 			
		NoTranslationFound(client, sArgs);		
}
