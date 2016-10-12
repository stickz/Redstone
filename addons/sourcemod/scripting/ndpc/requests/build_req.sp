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
					PrintComplexBuildingRequest(	team, pName,
									nd_request_building[building], 
									nd_request_location[location],
									nd_request_compass[compass]);
					return true;
				}
				
				PrintSpotBuildingRequest(	team, pName,
								nd_request_building[building], 
								nd_request_location[location]);
				return true;
			}
			//if a valid compass position is found
			else if (foundCompassName)
			{
				PrintCompassBuildingRequest(	team, pName, 
								nd_request_building[building], 
								nd_request_compass[compass]);
				return true;
			}
					
			PrintSimpleBuildingRequest(team, pName,	nd_request_building[building]);
			return true;
		}			
			
		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintSimpleBuildingRequest(int team, const char[] pName, const char[] bName)
{
	LOOP_TEAM(idx, team) 
	{
		char building[64];
		Format(building, sizeof(building), "%T", bName, idx);
				
		char ToPrint[128];
		Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, building);
				
		NDPC_PrintToChat(idx, pName, ToPrint);		
	}	
}

void PrintSpotBuildingRequest(int team, const char[] pName, const char[] bName, const char[] lName)
{
	LOOP_TEAM(idx, team) 
	{
		char building[64];
		Format(building, sizeof(building), "%T", bName, idx);
				
		char location[32];
		Format(location, sizeof(location), "%T", lName, idx);
				
		char ToPrint[128];
		Format(ToPrint, sizeof(ToPrint), "%T", "Spot Building Request", idx, building, location);
			
		NDPC_PrintToChat(idx, pName, ToPrint);		
	}	
}

void PrintCompassBuildingRequest(int team, const char[] pName, const char[] bName, const char[] cName)
{
	LOOP_TEAM(idx, team) 
	{
		char building[64];
		Format(building, sizeof(building), "%T", bName, idx);
				
		char compass[32];
		Format(compass, sizeof(compass), "%T", cName, idx);
				
		char ToPrint[128];
		Format(ToPrint, sizeof(ToPrint), "%T", "Compass Building Request", idx, building, compass);
								       
		NDPC_PrintToChat(idx, pName, ToPrint);		
	}	
}

void PrintComplexBuildingRequest(int team, const char[] pName, const char[] bName, const char[] lName, const char[] cName)
{
	LOOP_TEAM(idx, team) 
	{
		char building[64];
		Format(building, sizeof(building), "%T", bName, idx);
				
		char location[32];
		Format(location, sizeof(location), "%T", lName, idx);
				
		char compass[32];
		Format(compass, sizeof(compass), "%T", cName, idx);
				
		char ToPrint[128];
		Format(ToPrint, sizeof(ToPrint), "%T", "Complex Building Request", idx, building, location, compass);
								       
		NDPC_PrintToChat(idx, pName, ToPrint);		
	}
}
