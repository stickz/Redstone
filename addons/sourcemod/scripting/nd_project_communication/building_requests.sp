//To Update Later
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
	"Flamethrower Turret",
	"Sonic Turret",
	"Rocket Turret",
	"Wall",
	"Barrier"
};

#define REQUEST_LOCATION_COUNT 7
new const String:nd_request_location[REQUEST_LOCATION_COUNT][] =
{
	"Roof",
	"Base Tert",
	"Base",
	"Prim",
	"Pos",
	"East Sec",
	"West Sec"
};

bool:CheckBuildingRequest(client, const String:sArgs[])
{
	if (!g_Enable[BuildingReqs].BoolValue) 
		return false; //don't use feature if not enabled

	if (StrStartsWith(sArgs, "request")) //if string starts with request
	{
		for (new building = 0; building < REQUEST_BUILDING_COUNT; building++) //for all the buildings
		{
			if (StrIsWithin(sArgs, nd_request_building[building])) //if a building name is within the string
			{
				for (new location = 0; location < REQUEST_LOCATION_COUNT; location++) //for all the locations
				{
					if (StrIsWithin(sArgs, nd_request_location[location])) //if a location is within the string
					{
						PrintExtendedBuildingRequest(client, nd_request_building[building], nd_request_location[location]);
						return true;	
					}
				}
					
				PrintSimpleBuildingRequest(client, nd_request_building[building]);
				return true;
			}
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

PrintExtendedBuildingRequest(client, const String:bName[], const String:lName[])
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
				
				decl String:location[64];
				Format(location, sizeof(location), "%T", lName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Extended Building Request", idx, cName, building, location);
			
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}
