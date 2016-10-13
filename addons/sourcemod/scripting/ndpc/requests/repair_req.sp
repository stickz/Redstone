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
		repPrintMessage(client, team, pName, sArgs);
		return true;
	}	
		
	return false;
}

void repPrintMessage(int client, int team, const char[] pName, const char[] sArgs)
{
	//Get the building the user is asking for
	int building = GetBuildingByIndexEx(sArgs);
	int compass = GetCompassByIndex(sArgs);
	int location = GetSpotByIndex(sArgs);
		
	bool foundCompass = foundInChatMessage(compass);
	bool foundLocation = foundInChatMessage(location);
		
	// if a valid building name or alasis is found
	if (foundInChatMessage(building))
	{
		// if building + compass name is found
		if (foundCompass)
		{			
			// if building + compass + location name is found
			if (foundLocation)
				NDPC_PrintRequestS3(team, pName, "Extended Repair Request",
								nd_request_building[building], 
								nd_request_compass[compass], 
								nd_request_location[location]);
			else				
				NDPC_PrintRequestS2(team, pName, "Build Comp Repair Request", 
								nd_request_building[building], 
								nd_request_compass[compass]);	
		}
			
		// if building + location name is found
		else if (foundLocation)
			NDPC_PrintRequestS2(team, pName, "Build Loc Repair Request",
							nd_request_building[building], 
							nd_request_location[location]);					
		// if just the building name is found
		else			
			NDPC_PrintRequestS1(team, pName, "Building Repair Request",
							nd_request_building[building]);
	}	
	
	// if compass name is found
	else if (foundCompass)
	{
		// if compass + location name is found
		if (foundLocation)
			NDPC_PrintRequestS2( team, pName, "Comp Loc Repair Request",
							nd_request_compass[compass], 
							nd_request_location[location]);
		//if just the compass name is found
		else			
			NDPC_PrintRequestS1(team, pName, "Compass Repair Request",
							nd_request_compass[compass]);
	}
	
	// if just the location name is found
	else if (foundLocation)
		NDPC_PrintRequestS1(team, pName, "Location Repair Request",
						nd_request_location[location]);
	// if no repair keywords are found
	else
		NoTranslationFound(client, sArgs);		
}
