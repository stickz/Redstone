#define BUILDING_NOT_FOUND -1

// A list of buildings by their translation phrase
#define REQUEST_BUILDING_COUNT 16
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
	"Repeater",
	"Assembler",
	"Bunker"
};

int GetBuildingByIndex(const char[] sArgs)
{
	//for normal requests (so they can't be overwritten by alaises
	for (int building = 0; building < REQUEST_BUILDING_COUNT; building++) //for all the buildings
	{
		//if a building name or it's alias is within the string
		if (StrIsWithin(sArgs, nd_request_building[building])) 
		{
			return building; //the index building in nd_request_building
		}
	}
	
	return BUILDING_NOT_FOUND;
}

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
	Assembler,
	Command_Bunker
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
	
	nd_building_aliases[Relay_Tower][0] = "tower";
	
	nd_building_aliases[Wireless_Repeater][0] = "wr";
	
	nd_building_aliases[Assembler][0] = "ass";
	
	nd_building_aliases[Command_Bunker][0] = "bunk";
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
