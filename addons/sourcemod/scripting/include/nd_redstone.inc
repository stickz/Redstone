#if defined _nd_redstone_included_
  #endinput
#endif
#define _nd_redstone_included_

/**
 * Gets the client count on the server from Redstone
 * Excludes AFK spectators who are not currently playing
 *
 * Returns the client count (excluding afk spec) integer
 *
 * @return Integer client count.
 */
native int RED_ClientCount();

#define RED_CC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_ClientCount") == FeatureStatus_Available)


/**
 * Gets wheter the client is valid or not from Redstone
 * Excludes AFK spectators who are not currently playing
 *
 * Returns if the client is valid or not
 *
 * @parm1 ClientIDX 'index of client'
 * @return bool true false.
 */
native bool RED_ValidClient(int ClientIDX);

#define RED_VC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_ValidClient") == FeatureStatus_Available)

stock bool RED_IsValidClient(int ClientIDX)
{
	return RED_VC_AVAILABLE() && RED_ValidClient(ClientIDX);
}

native bool RED_ValidCIndex(int ClientIDX);

#define RED_VCI_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_ValidCIndex") == FeatureStatus_Available)

stock bool RED_IsValidCIndex(int ClientIDX)
{
	return RED_VCI_AVAILABLE() && RED_ValidCIndex(int ClientIDX);
}

stock int RED_GetTeamCount(int team)
{
	if (!RED_VC_AVAILABLE())
		return ValidTeamCount(team);
		
	int clientCount = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (RED_ValidClient(client) && GetClientTeam(client) == team)
		{
			clientCount++;
		}	
	}
	
	return clientCount;
}

stock int RED_OnTeamCount()
{
	if (!RED_VC_AVAILABLE())
		return OnTeamCount();
		
	int clientCount = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (RED_ValidClient(client) && GetClientTeam(client) > TEAM_SPEC)
		{
			clientCount++;
		}	
	}
	
	return clientCount;
}
