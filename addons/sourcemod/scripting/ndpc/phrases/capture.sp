#define RESOURCE_NOT_FOUND -1

#define REQUEST_CAPTURE_COUNT 3
char nd_request_capture[REQUEST_CAPTURE_COUNT][] =
{
	"Prim",
	"Sec",
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

	return RESOURCE_NOT_FOUND;
}
