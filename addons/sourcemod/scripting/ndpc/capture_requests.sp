#define REQUEST_CAPTURE_COUNT 5
char nd_request_capture[REQUEST_CAPTURE_COUNT][] =
{
	"Prim",
	"East Sec",
	"West Sec",
	"Base Tert",
	"Tert"
};

bool CheckCaptureRequest(int client, const char[] sArgs)
{
	if (!g_Enable[CaptureReqs].BoolValue)
		return false; //don't use this feature if not enabled
	
	if (StrStartsWith(sArgs, "capture")) //if the string starts with capture
	{
		for (int resource = 0; resource < REQUEST_CAPTURE_COUNT; resource++) //for all the resoruce points
		{
			if (StrIsWithin(sArgs, nd_request_capture[resource])) //if a resource point is within the string
			{
				PrintCaptureRequest(client, nd_request_capture[resource]);
				return true;
			}
		}
		
		NoTranslationFound(client, sArgs);
		return true;
	}
	
	return false;
}

void PrintCaptureRequest(int client, const char[] rName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char resource[64];
				Format(resource, sizeof(resource), "%T", rName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Capture Request", idx, cName, resource);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag",
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}
