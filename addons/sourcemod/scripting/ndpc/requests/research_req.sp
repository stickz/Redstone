#define MAX_RESEARCH_SPACECOUNT 3

bool CheckResearchRequest(int client, int spacesCount, const char[] sArgs)
{
	//If research requests are disabled on the server end, don't use them
	if (!g_Enable[ResearchReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for research requests
	if (spacesCount > MAX_RESEARCH_SPACECOUNT)
		return false;	
		
	//If the chat messages starts with the word "research"
	if (StrStartsWith(sArgs, "research"))
	{	
		//Get the research the user is asking for
		int research = GetResearchByIndex(sArgs);
		
		//If a valid research name or alasis is found
		if (foundInChatMessage(research))
		{
			PrintSimpleResearchRequest(client, nd_request_research[research]);
			return true;
		}
		
		NoTranslationFound(client, sArgs);
		return true;
	}	
		
	return false;
}

void PrintSimpleResearchRequest(int client, const char[] rName)
{
	int team = GetClientTeam(client);
		
	for (int idx = 0; idx <= MaxClients; idx++)
	{
		if (IsOnTeam(idx, team))
		{
			char research[64];
			Format(research, sizeof(research), "%T", rName, idx);
				
			char ToPrint[128];
			Format(ToPrint, sizeof(ToPrint), "%T", "Simple Research Request", idx, research);
				
			NDPC_PrintToChat(idx, team, ToPrint); 
		}
	}
}
