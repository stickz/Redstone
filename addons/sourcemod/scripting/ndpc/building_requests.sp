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

enum {
	Transport_Gate = 0,
	MG_Turrent,
	Power_Plant,
	Supply_Station,
	Artillery,
	Radar_Station,
	Flame_Turret,
	Sonic_Turret,
	Rocket_Turret,
	Wall,
	Barrier,
	Relay_Tower,
	Wireless_Repeater
};

#define B_ALIAS_COUNT 3
char nd_building_aliases[REQUEST_BUILDING_COUNT][B_ALIAS_COUNT][16];

/* How to add new building aliases to the plugin
 *
 * Step 1: Find the exact building name from the enum on line 24.
 *
 * Step 2: Write out a new alias in 'void createAliasesForBuildings()'
 * Example: nd_building_aliases[Transport_Gate]
 *
 * Step 3: Increment the second number by 1 (use 0 if no aliases are present)
 * Example1: nd_building_aliases[Transport_Gate][3]
 * Example2: nd_building_aliases[Wireless_Repeater][0]
 *
 * Step 4: Add the alias to the string you just created
 * Example: nd_building_aliases[Transport_Gate][2] = "spawn";
 *
 * Step 5: If [number] + 1 is greater than B_ALIAS_COUNT on line 40, change B_ALIAS_COUNT; otherwise DO NOT touch it.
 * Example: nd_building_aliases[Transport_Gate][3]
 * #define B_ALIAS_COUNT 4
 */

void createAliasesForBuildings()
{
	nd_building_aliases[Transport_Gate][0] = "gate";
	nd_building_aliases[Transport_Gate][1] = "tg";
	nd_building_aliases[Transport_Gate][2] = "spawn";
	
	nd_building_aliases[MG_Turrent][0] = "machine";
	nd_building_aliases[MG_Turrent][1] = "gun";
	
	nd_building_aliases[Power_Plant][0] = "plant";
	nd_building_aliases[Power_Plant][1] = "pp";
	
	nd_building_aliases[Supply_Station][0] = "sup";
	
	nd_building_aliases[Artillery][0] = "arty";
	
	nd_building_aliases[Flame_Turret][0] = "ft";
	
	nd_building_aliases[Sonic_Turret][0] = "son";
	
	nd_building_aliases[Rocket_Turret][0] = "rt";	
}

int GetBuildingByIndex(const char[] sArgs)
{
	for (int building = 0; building < REQUEST_BUILDING_COUNT; building++) //for all the buildings
	{
		//if a building name or it's alias is within the string
		if (	StrIsWithin(sArgs, nd_request_building[building]) || 
			StrIsWithinArray(sArgs, nd_building_aliases[building], B_ALIAS_COUNT)) {
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
