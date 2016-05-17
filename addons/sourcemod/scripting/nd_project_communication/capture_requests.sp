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
	if (STRING_STARTS_WITH == StrContains(sArgs, "capture", false))
	{
		for (new resource = 0; resource < REQUEST_CAPTURE_COUNT; resource++)
		{
			if (StrContains(sArgs, nd_request_capture[resource], false) > IS_WITHIN_STRING)
			{
				PrintCaptureRequest(client, nd_request_capture[resource]);
				return true;
			}
		}
		
		PrintToChat(client, "\x04%t \x05%t.", "Translate Tag", "No Translate Keyword");
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
			if (IsValidClient(idx) && GetClientTeam(client) == team)
			{
				decl String:resource[64];
				Format(resource, sizeof(resource), "%T", rName, idx);
				
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Capture Request", idx, cName, resource);
				
				PrintToChat(idx, "\x04%t \x05%s", "Translate Tag", ToPrint); 
			}
		}
	}
}
