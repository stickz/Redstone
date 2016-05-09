//To Update Later
#define REQUEST_BUILDING_COUNT 12
new const String:nd_request_building[REQUEST_BUILDING_COUNT][] =
{
	"Transport Gate",
	"MG Turret",
	"Power Station",
	"Supply Station",
	"Armory",
	"Artillery",
	"Radar Station",
	"Flamethrower Turret",
	"Sonic Turret",
	"Rocket Turret",
	"Wall",
	"Barrier"
};

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client)
	{
		if (STRING_STARTS_WITH == StrContains(sArgs, "request", false))
		{
			new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
			SetCmdReplySource(old);
			
			for (new idx = 0; idx < REQUEST_BUILDING_COUNT; idx++)
			{
				if (StrContains(sArgs, nd_request_building[idx], false) > IS_WITHIN_STRING)
				{
					PrintSimpleBuildingRequest(client, nd_request_building[idx]);
					return Plugin_Stop; 
				}
			}
			
			PrintToChat(client, "/x04(Translator) /x05No translation keyword found.");
			return Plugin_Stop; 
		}
	}
	
	return Plugin_Continue;
}

PrintSimpleBuildingRequest(client, const String:bName[])
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
				decl String:ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Building Request", idx, cName, bName);
				
				PrintToChat(idx, "/x04(Translator) /x05%s", ToPrint); 
			}
		}
	}
}
