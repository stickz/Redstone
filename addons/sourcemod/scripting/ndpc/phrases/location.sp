#define LOCATION_NOT_FOUND -1
#define COMPASS_NOT_FOUND -1

// A list of locations by their translation phrase
#define REQUEST_LOCATION_COUNT 15
char nd_request_location[REQUEST_LOCATION_COUNT][] =
{
	"Base",
	"Bulldozer",
	"Courtyard",
	"Forward",
	"Garage",
	"Helicopter",
	"Pos",
	"Prime",
	"Roof",
	"Sec"
	"Silo",
	"Stairs",
	"Statue",
	"Truck",
	"Tunnel",
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
