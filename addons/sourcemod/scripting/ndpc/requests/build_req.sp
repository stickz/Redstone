#define MAX_BUILDING_SPACECOUNT 4

// A enumerated list of building for indexing from an array
enum {
	Transport_Gate = 0,
	MG_Turrent,
	Power_Plant,
	Supply_Station,
	Armory,
	Artillery,
	Radar_Station,
	Flame_Turret,
	Sonic_Turret,
	Rocket_Turret,
	Wall,
	Barrier,
	Relay_Tower,
	Wireless_Repeater,
	Assembler
};

//A three dimensional array for to store building aliases
#define B_ALIAS_COUNT 3
char nd_building_aliases[REQUEST_BUILDING_COUNT][B_ALIAS_COUNT][16];

/* How to add new building aliases to the plugin
 *
 * Step 1: Find the exact building name from the enum on line 26.
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
	/* Transport Gate */
	nd_building_aliases[Transport_Gate][0] = "gate";
	nd_building_aliases[Transport_Gate][1] = "tg";
	nd_building_aliases[Transport_Gate][2] = "spawn";
	
	/* Machine Gun Turret */
	nd_building_aliases[MG_Turrent][0] = "machine";
	nd_building_aliases[MG_Turrent][1] = "gun";
	
	/* Power Plant */
	nd_building_aliases[Power_Plant][0] = "plant";
	nd_building_aliases[Power_Plant][1] = "pp";
	
	/* Etc */	
	
	nd_building_aliases[Supply_Station][0] = "sup";
	
	nd_building_aliases[Armory][0] = "arm";
	
	nd_building_aliases[Artillery][0] = "arty";
	
	nd_building_aliases[Flame_Turret][0] = "ft";
	
	nd_building_aliases[Sonic_Turret][0] = "son";
	
	nd_building_aliases[Rocket_Turret][0] = "rt";	
	
	nd_building_aliases[Assembler][0] = "ass";
}

int GetBuildingByIndexEx(const char[] sArgs)
{
	int index = GetBuildingByIndex(sArgs);
	if (index != BUILDING_NOT_FOUND) { return index; }
	
	// After normal building requests, do aliases
	for (int building2 = 0; building2 < REQUEST_BUILDING_COUNT; building2++)
	{
		if (StrIsWithinArray(sArgs, nd_building_aliases[building2], B_ALIAS_COUNT))
		{
			return building2;  //the index building in nd_request_building
		}
	}
	
	return BUILDING_NOT_FOUND;
}

// Check if the user is inputing a building request in chat
bool CheckBuildingRequest(int client, const char[] sArgs)
{
	//If building requests are disabled on the server end, don't use them
	if (!g_Enable[BuildingReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for building requests
	if (GetStringSpaceCount(sArgs) > MAX_BUILDING_SPACECOUNT)
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
