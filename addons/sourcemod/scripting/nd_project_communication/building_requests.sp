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
	if (STRING_STARTS_WITH == StrContains(sArgs, "request", false))
	{
		for (new building = 0; building < REQUEST_BUILDING_COUNT; building++)
		{
			if (StrContains(sArgs, nd_request_building[building], false) > IS_WITHIN_STRING)
			{
				for (new location = 0; location < REQUEST_LOCATION_COUNT; location++)
				{
					if (StrContains(sArgs, nd_request_location[location], false) > IS_WITHIN_STRING)
					{
						PrintExtendedBuildingRequest(client, nd_request_building[building], nd_request_location[location]);
						return true;	
					}
				}
					
				PrintSimpleBuildingRequest(client, nd_request_building[building]);
				return true;
			}
		}
			
		PrintToChat(client, "\x04(Translator) \x05No translation keyword found.");
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
			if (IsValidClient(idx) && GetClientTeam(client) == team)
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, cName, building);
				
				PrintToChat(idx, "\x04(Translator) \x05%s", ToPrint); 
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
			if (IsValidClient(idx) && GetClientTeam(client) == team)
			{
				decl String:building[64];
				Format(building, sizeof(building), "%T", bName, idx);
				
				decl String:location[64];
				Format(location, sizeof(location), "%T", lName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Extended Building Request", idx, cName, building, location);
			
				PrintToChat(idx, "\x04(Translator) \x05%s", ToPrint); 
			}
		}
	}
}
