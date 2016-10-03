#define BUILDING_NOT_FOUND -1
#define LOCATION_NOT_FOUND -1
#define COMPASS_NOT_FOUND -1

#define REQUEST_BUILDING_COUNT 14
char nd_request_building[REQUEST_BUILDING_COUNT][] =
{
	"Transport",
	"MG",
	"Power",
	"Supply",
	"Armory",
	"Artillery",
	"Radar",
	"Flame",
	"Sonic",
	"Rocket",
	"Wall",
	"Barrier",
	"Relay",
	"Repeater"
};

int GetBuildingByIndex(const char[] sArgs)
{
	for (int building = 0; building < REQUEST_BUILDING_COUNT; building++) //for all the buildings
	{
		if (StrIsWithin(sArgs, nd_request_building[building])) //if a building name is within the string
		{
			return building;
		}
	}
	
	return BUILDING_NOT_FOUND;
}

#define REQUEST_LOCATION_COUNT 5
char nd_request_location[REQUEST_LOCATION_COUNT][] =
{
	"Roof",
	"Base",
	"Prim",
	"Pos",
	"Sec"
};

int GetSpotByIndex(const char[] sArgs)
{
	for (int location = 0; location < REQUEST_LOCATION_COUNT; location++) //for all the building spots
	{
		if (StrIsWithin(sArgs, nd_request_location[location])) //if a location is within the string
		{
			return location;	
		}
	}

	return LOCATION_NOT_FOUND;
}

#define REQUEST_COMPASS_COUNT 6
char nd_request_compass[REQUEST_COMPASS_COUNT][] =
{
	"North",
	"South",
	"East",
	"West",
	"Left",
	"Right"
};

int GetCompassByIndex(const char[] sArgs)
{
	for (int compass = 0; compass < REQUEST_COMPASS_COUNT; compass++) //for all the compass locations
	{
		if (StrIsWithin(sArgs, nd_request_compass[compass])) //if a location is within the string
		{
			return compass;	
		}
	}

	return COMPASS_NOT_FOUND;
}

bool CheckBuildingRequest(int client, const char[] sArgs)
{
	if (!g_Enable[BuildingReqs].BoolValue) 
		return false; //don't use feature if not enabled

	if (StrStartsWith(sArgs, "build")) //if string starts with build
	{
		int building = GetBuildingByIndex(sArgs);
		
		if (building != BUILDING_NOT_FOUND)
		{
			int location = GetSpotByIndex(sArgs);
			int compass = GetCompassByIndex(sArgs);
			
			if (location != LOCATION_NOT_FOUND)
			{
				if (compass != COMPASS_NOT_FOUND)
				{
					PrintComplexBuildingRequest(client, 	nd_request_building[building], 
										nd_request_location[location],
										nd_request_compass[compass]);
					return true;
				}
				
				PrintSpotBuildingRequest(client, nd_request_building[building], nd_request_location[location]);
				return true;
			}
			else if (compass != COMPASS_NOT_FOUND)
			{
				PrintCompassBuildingRequest(client, nd_request_building[building], nd_request_compass[compass]);
				return true;
			}
					
			PrintSimpleBuildingRequest(client, nd_request_building[building]);
			return true;
		}
			
		PrintToChat(client, "%s%t %s%t.", TAG_COLOUR, "Translate Tag", 
					 	  MESSAGE_COLOUR, "No Translate Keyword");
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
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
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
			
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
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
								       
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint);
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
								       
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint);
			}
		}
	}
}
