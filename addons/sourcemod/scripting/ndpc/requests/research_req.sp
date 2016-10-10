#define RESEARCH_NOT_FOUND -1
#define MAX_RESEARCH_SPACECOUNT 3
#define R_ALIAS_COUNT 3

#define REQUEST_RESEARCH_COUNT 7
char nd_request_research[REQUEST_RESEARCH_COUNT][] = {
	"Advanced Kits",
	"Field Tactics",
	"Commander Abilities",
	"Power Modulation",
	"Advanced Manufacturing",
	"Infantry Boost",
	"Structure Reinforcement"
};

//A three dimensional array for to store building aliases
#define R_ALIAS_COUNT 3
char nd_research_aliases[REQUEST_RESEARCH_COUNT][R_ALIAS_COUNT][16];

int GetResearchByIndex(const char[] sArgs)
{
	// for normal requests (so they can't be overwritten by alaises
	for (int research = 0; research < REQUEST_BUILDING_COUNT; research++) //for all the research
	{
		//if a research name is within the string
		if (StrIsWithin(sArgs, nd_request_research[research])) 
		{
			return research; //the index research in nd_request_research
		}
	}
	
	// for alais requests
	for (int research2 = 0; research2 < REQUEST_BUILDING_COUNT; research2++)
	{
		if (StrIsWithinArray(sArgs, nd_research_aliases[research2], R_ALIAS_COUNT))
		{
			return research; //the index research in nd_request_research
		}
	}
	
	return RESEARCH_NOT_FOUND;	
}

enum {
	Advanced_Kits = 0,
	Field_Tactics,
	Commander_Abilities,
	Power_Modulation,
	Advanced_Manufacturing,
	Infantry_Boost,
	Structure_Reinforcement
}

createAliasesForResearch()
{
	nd_research_aliases[Advanced_Kits][0] = "kits";
	
	nd_research_aliases[Field_Tactics][0] = "field";
	nd_research_aliases[Field_Tactics][1] = "feild";
	nd_research_aliases[Field_Tactics][2] = "tact";
	
	nd_research_aliases[Commander_Abilities][0] = "Abilit";
	
	nd_research_aliases[Power_Modulation][0] = "mod";
	
	nd_research_aliases[Advanced_Manufacturing][0] = "man";
	
	nd_research_aliases[Infantry_Boost][0] = "ib";
	nd_research_aliases[Infantry_Boost][1] = "infantry";
	nd_research_aliases[Infantry_Boost][2] = "boost";
	
	nd_research_aliases[Structure_Reinforcement][0] = "struct";
	nd_research_aliases[Structure_Reinforcement][1] = "rein";
}

bool CheckResearchRequest(int client, const char[] sArgs)
{
	//If research requests are disabled on the server end, don't use them
	if (!g_Enable[ResearchReqs].BoolValue) 
		return false;
	
	//If the spacecount is greater than the required amount for research requests
	if (GetStringSpaceCount(sArgs) > MAX_RESEARCH_SPACECOUNT)
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
		}
	}
}

void PrintSimpleResearchRequest(int client, const char[] rName)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		char pName[64];
		GetClientName(client, pName, sizeof(pName));
		
		for (int idx = 0; idx <= MaxClients; idx++)
		{
			if (IsOnTeam(idx, team))
			{
				char research[64];
				Format(research, sizeof(research), "%T", rName, idx);
				
				char ToPrint[128];
				Format(ToPrint, sizeof(ToPrint), "%T", "Simple Research Request", idx, pName, research);
				
				PrintToChat(idx, "%s%t %s%s", TAG_COLOUR, "Translate Tag", 
							      MESSAGE_COLOUR, ToPrint); 
			}
		}
	}
}