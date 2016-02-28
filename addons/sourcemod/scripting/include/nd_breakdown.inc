#if defined _nd_breakdown_included
  #endinput
#endif
#define _nd_breakdown_included

/* Main and Subclass enums for the following prop ents
 * "m_iPlayerClass"
 * "m_iPlayerSubclass"
 * "m_iDesiredPlayerClass"
 * m_iDesiredPlayerSubclass"
 */
enum MainClasses
{
	mAssault,
	mExo,
	mStealth,
	mSupport
}

enum aSubClasses
{
	aInfantry,
	aGrenadier,
	aSniper
}

enum eSubClasses
{
	eSuppression,
	eSiege_Kit
}

enum seSubClasses
{
	seAssassin,
	seSniper,
	seSabateur
}

enum suSubClasses
{
	suMedic,
	suEngineer,
	suBBQ
}

/**
 * Retreive the number of snipers on an given team
 *
 * If an invlaid teamIDX is sent, will return -1.
 *
 * @param teamIDX  		The index of the team.
 * @return        		The number of sniper class clients.
 */
native GetSniperCount(teamIDX);
