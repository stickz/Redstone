#define MAX_RESEARCH_SPACECOUNT 3

bool CheckResearchRequest(int client, int team, int spacesCount, const char[] pName, const char[] sArgs)
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
		// print research message, return false if not found
		return resPrintMessage(client, team, pName, sArgs);
	}	
		
	return false;
}

bool resPrintMessage(int client, int team, const char[] pName, const char[] sArgs)
{
	//Get the research the user is asking for
	int research = GetResearchByIndex(sArgs);
		
	//If a valid research name or alasis is found
	if (foundInChatMessage(research))
	{
		NDPC_PrintRequestS1(team, pName, "Simple Research Request", 
						nd_request_research[research]);
		return true;					
	}
	else
	{
		NoTranslationFound(client, sArgs);
		return false;	
	}
}
