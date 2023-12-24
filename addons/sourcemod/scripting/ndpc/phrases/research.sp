#define RESEARCH_NOT_FOUND -1

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

//A three dimensional array for to store reserach aliases
#define R_ALIAS_COUNT 3
char nd_research_aliases[REQUEST_RESEARCH_COUNT][R_ALIAS_COUNT][16];

int GetResearchByIndex(const char[] sArgs)
{
	// for normal requests (so they can't be overwritten by alaises
	for (int research = 0; research < REQUEST_RESEARCH_COUNT; research++) //for all the research
	{
		//if a research name is within the string
		if (StrIsWithin(sArgs, nd_request_research[research])) 
		{
			return research; //the index research in nd_request_research
		}
	}
	
	// for alais requests
	for (int research2 = 0; research2 < REQUEST_RESEARCH_COUNT; research2++)
	{
		if (StrIsWithinArray(sArgs, nd_research_aliases[research2], R_ALIAS_COUNT))
		{
			return research2; //the index research in nd_request_research
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

void createAliasesForResearch()
{
	nd_research_aliases[Advanced_Kits][0] = "kits";
	nd_research_aliases[Advanced_Kits][1] = "siege";
	
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
