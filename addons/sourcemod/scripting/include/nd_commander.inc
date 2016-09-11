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
native int GetCommanderTeam(clientIDX);

#define GCT_LOADED() (GetFeatureStatus(FeatureType_Native, "GetCommanderTeam") == FeatureStatus_Available)

stock bool NDC_IsCommander(client)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
		return GameRules_GetPropEnt("m_hCommanders", GetClientTeam(client) - 2) == client;
	
	return GetCommanderTeam(client) != NOT_COMMANDER;	
}

stock bool NDC_IsCommanderOnTeam(client, team)
{
	/* Use the intensive method if we cannot use the faster method */
	if (!GCT_LOADED())
	{
		int clientTeam = GetClientTeam(client);
		return clientTeam == team && GameRules_GetPropEnt("m_hCommanders", clientTeam - 2) == client;
	}
		
	return GetCommanderTeam(client) == team;
}

stock NDC_GetCommanderOn(team)
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsValidClient(client) && NDC_IsCommanderOnTeam(client, team))
			return client;
			
	return -1;
}

stock NDC_GetCommanderBy(client)
{
	return ND_GetCommanderOn(GetClientTeam(client));
}
