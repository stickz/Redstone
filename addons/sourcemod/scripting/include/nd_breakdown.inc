#if defined _nd_breakdown_included
  #endinput
#endif
#define _nd_breakdown_included

/* Main and Subclass constants for the following prop ents
 * "m_iPlayerClass"
 * "m_iPlayerSubclass"
 * "m_iDesiredPlayerClass"
 * m_iDesiredPlayerSubclass"
 */
 
#define MAIN_CLASS_ASSAULT 	0
#define MAIN_CLASS_EXO 		1
#define MAIN_CLASS_STEALTH	2
#define	MAIN_CLASS_SUPPORT	3

#define ASSAULT_CLASS_INFANTRY	0
#define ASSAULT_CLASS_GRENADIER	1
#define	ASSAULT_CLASS_SNIPER	2

#define EXO_CLASS_SUPRESSION	0
#define EXO_CLASS_SEIGE_KIT		1

#define	STEALTH_CLASS_ASSASSIN	0
#define	STEALTH_CLASS_SNIPER	1
#define STEALTH_CLASS_SABATEUR 	2

#define SUPPORT_CLASS_MEDIC		0
#define SUPPORT_CLASS_ENGINEER	1
#define SUPPORT_CLASS_BBQ		2

/* Player class stock functions */
stock bool:IsSniperClass(class, subClass) 
{
      return 	   (class == MAIN_CLASS_ASSAULT && subClass == ASSAULT_CLASS_SNIPER) 
	        || (class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_SNIPER)
}

stock bool:IsStealthClass(class)
{
      return class == MAIN_CLASS_STEALTH;
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

/**
 * Retreive the number of stealth on an given team
 *
 * If an invlaid teamIDX is sent, will return -1.
 *
 * @param teamIDX  		The index of the team.
 * @return        		The number of stealth class clients.
 */
native GetStealthCount(teamIDX);

/**
 * Retreive the number of anti-structure on an given team
 *
 * If an invlaid teamIDX is sent, will return -1.
 *
 * @param teamIDX  		The index of the team.
 * @return        		The number of anti-structure based clients.
 */
native GetAntiStructureCount(teamIDX);

#if !defined REQUIRE_PLUGIN
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetSniperCount");
	MarkNativeAsOptional("GetStealthCount");
	MarkNativeAsOptional("GetAntiStructureCount");
}
#endif
