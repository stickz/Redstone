#define REQUEST_CAPTURE_COUNT 5
new const String:nd_request_capture[REQUEST_CAPTURE_COUNT][] =
{
	"Prim",
	"East Sec",
	"West Sec",
	"Base Tert",
	"Tert"
};

bool:CheckCaptureRequest(client, const String:sArgs[])
{
	if (!g_Enable[CaptureReqs].BoolValue)
		return false; //don't use this feature if not enabled
	
	if (StrStartsWith(sArgs, "capture")) //if the string starts with capture
	{
		for (new resource = 0; resource < REQUEST_CAPTURE_COUNT; resource++) //for all the resoruce points
		{
			if (StrIsWithin(sArgs, nd_request_capture[resource])) //if a resource point is within the string
			{
				PrintCaptureRequest(client, nd_request_capture[resource]);
				return true;
			}
		}
		
		PrintToChat(client, "%s%t %s%t.", TAG_COLOUR, "Translate Tag", 
						  MESSAGE_COLOUR, "No Translate Keyword");
		return true;
	}
	
	return false;
}

PrintCaptureRequest(client, const String:rName[])
{
	if (IsValidClient(client))
	{
		new team = GetClientTeam(client);
		
		decl String:cName[64];
		GetClientName(client, cName, sizeof(cName));
		
		for (new idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, client))
			{
				decl String:resource[64];
				Format(resource, sizeof(resource), "%T", rName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Capture Request", idx, cName, resource);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}
