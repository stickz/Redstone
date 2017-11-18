#if defined _nd_research_eng_included
  #endinput
#endif
#define _nd_research_eng_included

#include <nd_research>

// Single level research only sends team as a cell
forward void OnFieldTacticsResearched(int team);
forward void OnPowerModResearched(int team);
forward void OnAdvancedKitsResearched(int team);
forward void OnAdvancedManufacturingResearched(int team);

// Multiple level research sends team and level as a cell
forward void OnCommanderAbilitiesResearched(int team, int level);
forward void OnInfantryBoostResearched(int team, int level);
forward void OnStructureReinResearched(int team, int level);

/* Get if an item has been researched (return true or false)
 * Will return true if multi-teired research is level 1 or higher
 *
 * Enum is tagged, but has a requirement to use only the first...
 * item for multi-teired research to save computing resources.
 *
 * Consider using ND_GetItemResearchLevel() for multi-teired research
 */
native bool ND_ItemHasBeenResearched(ND_ResearchItems item);

/* Gets the research level of an item.
 * 
 * If the research has not been started, will return 0
 * Returns 1 for single-teired research when completed
 *
 * Enum is tagged, but has a requirement to use only the first...
 * item for multi-teired research to save computing resources.
 */
native int ND_GetItemResearchLevel(ND_ResearchItems item);