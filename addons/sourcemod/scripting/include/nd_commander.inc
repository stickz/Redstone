#if defined _nd_commander_included
  #endinput
#endif
#define _nd_commander_included

/**
 * Retreive the team of the commander
 *
 * If client is not a commander, will return -1.
 *
 * @param clientIDX  	The index of the client.
 * @return        		The team number of the commander 
 *						or -1 if the person is not a commander.
 */
 
#define NOT_COMMANDER -1
#define CONSORT_COMMANDER 2
#define EMPIRE_COMMANDER 3 
 
native GetCommanderTeam(clientIDX);

#define GCT_LOADED() (GetFeatureStatus(FeatureType_Native, "GetCommanderTeam") == FeatureStatus_Available)

stock bool:NDC_IsCommander(client)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
		return GameRules_GetPropEnt("m_hCommanders", GetClientTeam(client) - 2) == client;
	
	return GetCommanderTeam(client) != NOT_COMMANDER;	
}

stock bool:NDC_IsCommanderOnTeam(client, team)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
	{
		new clientTeam = GetClientTeam(client);
		return clientTeam == team && GameRules_GetPropEnt("m_hCommanders", clientTeam - 2) == client;
	}
		
	return GetCommanderTeam(client) == team;
}

public SharedPlugin:__pl_commander =
{
	name = "nd_commander",
	file = "nd_commander_restrictions.smx",
	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_commander_SetNTVOptional()
{
	MarkNativeAsOptional("GetCommanderTeam");
}
#endif