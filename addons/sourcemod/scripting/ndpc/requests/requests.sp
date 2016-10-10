#define BUILDING_NOT_FOUND -1
#define LOCATION_NOT_FOUND -1
#define COMPASS_NOT_FOUND -1

// A list of buildings by their translation phrase
#define REQUEST_BUILDING_COUNT 15
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
	"Assembler"
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

// A list of locations by their translation phrase
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
			return location; //index of the location in nd_request_location 	
		}
	}

	return LOCATION_NOT_FOUND;
}

//A list of compass positions by their translation phrase
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
			return compass;	//the index of compass in nd_request_compass
		}
	}

	return COMPASS_NOT_FOUND;
}

#define REQUEST_CAPTURE_COUNT 4
char nd_request_capture[REQUEST_CAPTURE_COUNT][] =
{
	"Prim",
	"Sec",
	"Base Tert",
	"Tert"
};

int GetCaptureByIndex(const char[] sArgs)
{
	for (int resource = 0; resource < REQUEST_CAPTURE_COUNT; resource++) //for all the building spots
	{
		if (StrIsWithin(sArgs, nd_request_capture[resource])) //if a location is within the string
		{
			return resource; //index of the location in nd_request_location 	
		}
	}

	return LOCATION_NOT_FOUND;
}

int GetStringSpaceCount(const char[] sArgs)
{
	int spaceCount = 0;
	
	for (int idx = 0; idx < strlen(sArgs); idx++)
	{
		if (IsCharSpace(sArgs[idx]))
			spaceCount++;
	}
	
	return spaceCount;
}

/* Wrapper for printing a translation to client chat */
void NDPC_PrintToChat(int client, const char[] sArgs)
{
	PrintToChat(client, "%s%t %s%s", TAG_COLOUR, "Translate Tag", MESSAGE_COLOUR, sArgs);
}
