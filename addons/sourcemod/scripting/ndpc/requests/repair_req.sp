#define MAX_REPAIR_SPACECOUNT 4

bool CheckRepairRequest(int client, int team, int spacesCount, const char[] pName, const char[] sArgs)
{
	//If repair requests are disabled on the server end, don't use them
	if (!g_Enable[RepairReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for repair requests
	if (spacesCount > MAX_REPAIR_SPACECOUNT)
		return false;	
	
	//If the chat messages starts with the word "repair"
	if (StrStartsWith(sArgs, "repair"))
	{	
		//Get the building the user is asking for
		int building = GetBuildingByIndexEx(sArgs);
		int compass = GetCompassByIndex(sArgs);
		int location = GetSpotByIndex(sArgs);
		
		bool foundCompass = foundInChatMessage(compass);
		bool foundLocation = foundInChatMessage(location);
		
		//If a valid building name or alasis is found
		if (foundInChatMessage(building))
		{
			// if building + compass name is found
			if (foundCompass)
			{			
				// if building + compass + location name is found
				if (foundLocation)
				{
					PrintExtendedRepairRequest(	team, pName,
									nd_request_building[building], 
									nd_request_compass[compass], 
									nd_request_location[location]);
					return true;
				}
				
				Print_CompassBuilding_RepairRequest(	team, pName, 
									nd_request_building[building], 
									nd_request_compass[compass]);
				return true;
			}
			
			// if building + location name is found
			else if (foundLocation)
			{
				Print_LocationBuilding_RepairRequest(	team, pName, 
									nd_request_building[building], 
									nd_request_location[location]);
				return true;			
			}
			
			// if just the building name is found
			PrintBuildingRepairRequest(team, pName, nd_request_building[building]);
			return true;
		}
		// if compass name is found
		else if (foundCompass)
		{
			// if compass + location name is found
			if (foundLocation)
			{
				Print_CompassLocation_RepairRequest(	team, pName, 
									nd_request_compass[compass], 
									nd_request_location[location]);
				return true;
			}
			
			//if just the compass name is found
			PrintCompassRepairRequest(team, pName, nd_request_compass[compass]);
			return true;
		}
		// if just the location name is found
		else if (foundLocation)
		{
			PrintLocationRepairRequest(team, pName, nd_request_location[location]);
			return true;		
		}			
		
		// if no repair keywords are found
		NoTranslationFound(client, sArgs);
		return true;
	}	
		
	return false;
}

void PrintBuildingRepairRequest(int team, const char[] pName, const char[] bName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{
			char building[64];
			Format(building, sizeof(building), "%T", bName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Building Repair Request", idx, building);
			
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}
}

void Print_CompassBuilding_RepairRequest(int team, const char[] pName, const char[] bName, const char[] cName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char building[64];
			Format(building, sizeof(building), "%T", bName, idx);
			
			char compass[64];
			Format(compass, sizeof(compass), "%T", cName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Build Comp Repair Request", idx, compass, building);
			
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}	
}

void PrintCompassRepairRequest(int team, const char[] pName, const char[] cName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char compass[64];
			Format(compass, sizeof(compass), "%T", cName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Compass Repair Request", idx, compass);
				
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}	
}

void Print_CompassLocation_RepairRequest(int team, const char[] pName, const char[] cName, const char[] lName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char compass[64];
			Format(compass, sizeof(compass), "%T", cName, idx);
				
			char location[64];
			Format(location, sizeof(location), "%T", lName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Comp Loc Repair Request", idx, compass, location);
				
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}
}

void PrintLocationRepairRequest(int team, const char[] pName, const char[] lName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char location[64];
			Format(location, sizeof(location), "%T", lName, idx);
			
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Location Repair Request", idx, location);
				
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}	
}

void Print_LocationBuilding_RepairRequest(int team, const char[] pName, const char[] bName, const char[] lName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char building[64];
			Format(building, sizeof(building), "%T", bName, idx)				
				
			char location[64];
			Format(location, sizeof(location), "%T", lName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Build Loc Repair Request", idx, building, location);
				
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}	
}

void PrintExtendedRepairRequest(int team, const char[] pName, const char[] bName, const char[] cName, const char[] lName)
{
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{				
			char building[64];
			Format(building, sizeof(building), "%T", bName, idx);
			
			char compass[64];
			Format(compass, sizeof(compass), "%T", cName, idx);
			
			char location[64];
			Format(location, sizeof(location), "%T", lName, idx);
			
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Extended Repair Request", idx, building, compass, location);
	
			NDPC_PrintToChat(idx, pName, ToPrint); 
		}
	}	
}
