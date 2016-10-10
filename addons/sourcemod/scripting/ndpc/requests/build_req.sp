#define MAX_BUILDING_SPACECOUNT 4

// Check if the user is inputing a building request in chat
bool CheckBuildingRequest(int client, int spacesCount, const char[] sArgs)
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
				{
					PrintComplexBuildingRequest(client, 	nd_request_building[building], 
										nd_request_location[location],
										nd_request_compass[compass]);
					return true;
				}
				
				PrintSpotBuildingRequest(client, nd_request_building[building], nd_request_location[location]);
				return true;
			}
			//if a valid compass position is found
			else if (foundCompassName)
			{
				PrintCompassBuildingRequest(client, nd_request_building[building], nd_request_compass[compass]);
				return true;
			}
					
			PrintSimpleBuildingRequest(client, nd_request_building[building]);
			return true;
		}			
			
		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintSimpleBuildingRequest(int client, const char[] bName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, pName, building);
				
				NPDC_PrintToChat(idx, ToPrint);
			}
		}
	}
}

void PrintSpotBuildingRequest(int client, const char[] bName, const char[] lName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				char location[32];
				Format(location, sizeof(location), "%T", lName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Spot Building Request", idx, pName, building, location);
			
				NPDC_PrintToChat(idx, ToPrint); 
			}
		}
	}
}

void PrintCompassBuildingRequest(int client, const char[] bName, const char[] cName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				char compass[32];
				Format(compass, sizeof(compass), "%T", cName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Compass Building Request", 
								       idx, pName, building, compass);
								       
				NPDC_PrintToChat(idx, ToPrint);
			}
		}
	}
}

void PrintComplexBuildingRequest(int client, const char[] bName, const char[] lName, const char[] cName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				char location[32];
				Format(location, sizeof(location), "%T", lName, idx);
				
				char compass[32];
				Format(compass, sizeof(compass), "%T", cName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Complex Building Request", 
								       idx, pName, building, location, compass);
								       
				NPDC_PrintToChat(idx, ToPrint);
			}
		}
	}
}
