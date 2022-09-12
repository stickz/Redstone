#if defined _nd_research_included
  #endinput
#endif
#define _nd_research_included

#define RESEARCH_INCOMPLETE 0
#define RESEARCH_COMPLETE 	1

enum ND_ResearchItems: {
	Advanced_Kits = 1,
	Field_Tactics,
	Commander_Abilities,
	Power_Modulation,
	Advanced_Manufacturing,
	Commander_Abilities_Two,
	Commander_Abilities_Three,
	Infantry_Boost,
	Infantry_Boost_Two,
	Infantry_Boost_Three,
	Structure_Reinforcement,
	Structure_Reinforcement_Two,
	Structure_Reinforcement_Three,
	ND_ResearchItemsSize
}

stock int item(ND_ResearchItems item) {
	return view_as<int>(item);
}

#define RESEARCH_ADVANCED_KITS					1
#define RESEARCH_FIELD_TACTICS 					2
#define RESEARCH_COMMANDER_ABILITIES_ONE 		3
#define RESEARCH_POWER_MODULATION 				4
#define RESEARCH_ADVANCED_MANUFACTURING 		5
#define RESEARCH_COMMANDER_ABILITIES_TWO 		6
#define RESEARCH_COMMANDER_ABILITIES_THREE 		7
#define RESEARCH_INFANTRY_BOOST_ONE 			8
#define RESEARCH_INFANTRY_BOOST_TWO 			9
#define RESEARCH_INFANTRY_BOOST_THREE 			10
#define RESEARCH_STRUCTURE_REINFORCEMENT_ONE 	11
#define RESEARCH_STRUCTURE_REINFORCEMENT_TWO 	12
#define RESEARCH_STRUCTURE_REINFORCEMENT_THREE 	13
