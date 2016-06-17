#define BUILDING_NOT_FOUND -1
#define LOCATION_NOT_FOUND -1
#define COMPASS_NOT_FOUND -1

#define REQUEST_BUILDING_COUNT 12
new const String:nd_request_building[REQUEST_BUILDING_COUNT][] =
{
	"Transport Gate",
	"MG Turret",
	"Power Station",
	"Supply Station",
	"Armory",
	"Artillery",
	"Radar Station",
	"FT Turret",
	"Sonic Turret",
	"Rocket Turret",
	"Wall",
	"Barrier"
};

GetBuildingByIndex(const String:sArgs[])
{
	for (new building = 0; building < REQUEST_BUILDING_COUNT; building++) //for all the buildings
	{
		if (StrIsWithin(sArgs, nd_request_building[building])) //if a building name is within the string
		{
			return building;
		}
	}
	
	return BUILDING_NOT_FOUND;
}

#define REQUEST_LOCATION_COUNT 5
new const String:nd_request_location[REQUEST_LOCATION_COUNT][] =
{
	"Roof",
	"Base",
	"Prim",
	"Pos",
	"Sec"
};

GetSpotByIndex(const String:sArgs[])
{
	for (new location = 0; location < REQUEST_LOCATION_COUNT; location++) //for all the building spots
	{
		if (StrIsWithin(sArgs, nd_request_location[location])) //if a location is within the string
		{
			return location;	
		}
	}

	return LOCATION_NOT_FOUND;
}

#define REQUEST_COMPASS_COUNT 6
new const String:nd_request_compass[REQUEST_COMPASS_COUNT][] =
{
	"North",
	"South",
	"East",
	"West",
	"Left,
	"Right"
};

GetCompassByIndex(const String:sArgs[])
{
	for (new compass = 0; compass < REQUEST_COMPASS_COUNT; compass++) //for all the compass locations
	{
		if (StrIsWithin(sArgs, nd_request_compass[compass])) //if a location is within the string
		{
			return compass;	
		}
	}

	return COMPASS_NOT_FOUND;
}

bool:CheckBuildingRequest(client, const String:sArgs[])
{
	if (!g_Enable[BuildingReqs].BoolValue) 
		return false; //don't use feature if not enabled

	if (StrStartsWith(sArgs, "request")) //if string starts with request
	{
		new building = GetBuildingByIndex(sArgs);
		
		if (building != BUILDING_NOT_FOUND)
		{
			new location = GetSpotByIndex(sArgs);
			new compass = GetCompassByIndex(sArgs);
			
			if (location != LOCATION_NOT_FOUND)
			{
				PrintSpotBuildingRequest(client, nd_request_building[building], nd_request_location[location]);
				return true;
				
				if (compass != COMPASS_NOT_FOUND)
				{
					PrintComplexBuildingRequest(client, 	nd_request_building[building], 
										nd_request_location[location],
										nd_request_compass[compass]);
					return true;
				}
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

PrintSimpleBuildingRequest(client, const String:bName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, cName, building);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}

PrintSpotBuildingRequest(client, const String:bName[], const String:lName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:location[32];
				Format(location, sizeof(location), "%T", lName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Extended Spot Request", idx, cName, building, location);
			
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}

PrintCompassBuildingRequest(client, const String:bName[], const String:cName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:compass[32];
				Format(compass, sizeof(compass), "%T", clName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Compass Building Request", 
								       idx, cName, building, compass);
								       
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint);
			}
		}
	}
}

PrintComplexBuildingRequest(client, const String:bName[], const String:lName[], const String:cName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:location[32];
				Format(location, sizeof(location), "%T", lName, idx);
				
				decl String:compass[32];
				Format(compass, sizeof(compass), "%T", clName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Complex Building Request", 
								       idx, cName, building, location, compass);
								       
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint);
			}
		}
	}
}
