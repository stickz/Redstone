#define LOCATION_NOT_FOUND -1
#define COMPASS_NOT_FOUND -1

// A list of locations by their translation phrase
#define REQUEST_LOCATION_COUNT 16
char nd_request_location[REQUEST_LOCATION_COUNT][] = {
	"Base",
	"Bulldozer",
	"Courtyard",
	"Forward",
	"Garage",
	"Helicopter",
	"Pos",
	"Prim",
	"Roof",
	"Sec",
	"Silo",
	"Stairs",
	"Statue",
	"Truck",
	"Tunnel",
	"Tert"
};

// A enumerated list of buildings for array indexing
enum {
	Base,
	Bulldozer,
	Courtyard,
	Forward,
	Garage,
	Helicopter,
	Position,
	Prime,
	Roof,
	Secondary,
	Silo,
	Stairs,
	Statue,
	Truck,
	Tunnel,
	Tert
}

/* To learn how to create new alaises go here. It's already between explained.
 * https://github.com/stickz/Redstone/blob/master/addons/sourcemod/scripting/ndpc/phrases/building.sp
 */
 
//A three dimensional array for to store location aliases
#define L_ALIAS_COUNT 3
char nd_location_aliases[REQUEST_LOCATION_COUNT][L_ALIAS_COUNT][16];

void createAliasesForLocations()
{
	nd_location_aliases[Bulldozer][0] = "bull";
	nd_location_aliases[Bulldozer][1] = "dozer";
	
	nd_location_aliases[Courtyard][0] = "court";
	nd_location_aliases[Courtyard][1] = "yard";
	
	nd_location_aliases[Helicopter][0] = "heli";
	nd_location_aliases[Helicopter][1] = "copter";
	nd_location_aliases[Helicopter][2] = "chopper";
}

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

int GetSpotByIndexEx(const char[] sArgs)
{
	int index = GetSpotByIndex(sArgs);
	if (index != LOCATION_NOT_FOUND) { return index; }	

	// After normal building requests, do aliases
	for (int location = 0; location < REQUEST_LOCATION_COUNT; location++)
	{
		if (StrIsWithinArray(sArgs, nd_location_aliases[location], L_ALIAS_COUNT))
		{
			return location;  //the index location in nd_request_location
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
