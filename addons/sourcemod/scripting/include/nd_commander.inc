#if defined _nd_commander_included
  #endinput
#endif
#define _nd_commander_included

#define NOT_COMMANDER -1
#define CONSORT_COMMANDER 2
#define EMPIRE_COMMANDER 3 

/**
 * Retreive the team of the commander
 *
 * If client is not a commander, will return -1.
 *
 * @param clientIDX  		The index of the client.
 * @return        		The team number of the commander 
 *				or -1 if the person is not a commander.
 */
native int GetCommanderTeam(int clientIDX);

#define GCT_LOADED() (GetFeatureStatus(FeatureType_Native, "GetCommanderTeam") == FeatureStatus_Available)

stock bool NDC_IsCommander(int client)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
		return GameRules_GetPropEnt("m_hCommanders", GetClientTeam(client) - 2) == client;
	
	return GetCommanderTeam(client) != NOT_COMMANDER;	
}


stock bool NDC_IsCommanderOnTeam(int client, int team)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
	{
		int clientTeam = GetClientTeam(client);
		return clientTeam == team && GameRules_GetPropEnt("m_hCommanders", clientTeam - 2) == client;
	}
		
	return GetCommanderTeam(client) == team;
}

/* */
native int GetCommanderClient(int team);

#define GetCC_LOADED() (GetFeatureStatus(FeatureType_Native, "GetCommanderClient") == FeatureStatus_Available)

stock int GetCommanderByClient(int client)
{
	return GameRules_GetPropEnt("m_hCommanders", GetClientTeam(client) - 2);
}

stock bool ND_TeamHasCommander(int team)
{
	return GetCC_LOADED() && GetCommanderClient(team) > -1;
}