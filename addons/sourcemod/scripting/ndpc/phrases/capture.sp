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
