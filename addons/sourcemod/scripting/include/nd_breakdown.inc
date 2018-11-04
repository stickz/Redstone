#if defined _nd_breakdown_included
  #endinput
#endif
#define _nd_breakdown_included

enum ND_ClassBreakdown
{
	uCombat = 0,
	uSnipers,
	uAntiStructure,
	uStealth,
	uMedic,
	uEngineer
}

/**
 * Retreive the number of units on a given team
 *
 * @error Invalid team index sent; Use TEAM_EMPIRE or TEAM_CONSORT
 *
 * @param teamIDX  		The index of the team.
 * @param unitType		The type of unit to retreive.
 * @return        		The number of class unit clients. */
native int NDB_GetUnitCount(int teamIDX, int unitType);

/**
 * Retreive the number of Anti-Structure units on a given team
 *
 * @error Invalid team index sent; Use TEAM_EMPIRE or TEAM_CONSORT
 *
 * @param teamIDX  		The index of the team.
 * @param includeSabs		Do we include saboteurs in the count?
 * @return        		The number of class unit clients. */
native int NDB_GetAntiStructureCount(int teamIDX, bool includeSabs);
