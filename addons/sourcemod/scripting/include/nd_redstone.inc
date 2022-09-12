#if defined _nd_redstone_included_
  #endinput
#endif
#define _nd_redstone_included_

#include <nd_stocks>

/**
 * Get's if the client is marked as a donator
 *
 * @parm1 ClientIDX 'index of client'
 * @return bool true false.
 */
native bool RED_Donator(int ClientIDX);

#define RED_D_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_Donator") == FeatureStatus_Available)

stock bool RED_IsDonator(int ClientIDX) {
	return RED_D_AVAILABLE() && RED_Donator(ClientIDX);
}

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

stock bool RED_IsValidClient(int ClientIDX) {
	return RED_VC_AVAILABLE() && RED_ValidClient(ClientIDX);
}

native bool RED_ValidCIndex(int ClientIDX);

#define RED_VCI_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_ValidCIndex") == FeatureStatus_Available)

stock bool RED_IsValidCIndex(int ClientIDX) {
	return RED_VCI_AVAILABLE() && RED_ValidCIndex(ClientIDX);
}

/**
 * Gets the client count on the server from Redstone
 * Excludes AFK spectators who are not currently playing
 */
stock int RED_ValidClientCount()
{
	int clientCount = 0;
	
	for (int ix = 1; ix <= MaxClients; ix++) 
		if (RED_ValidClient(ix))
			clientCount++;
			
	return clientCount;
}

stock int ND_GetClientCount() {
	return RED_VC_AVAILABLE() ? RED_ValidClientCount() : ValidClientCount();
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

#define RED_LOOP_CLIENTS(%1) for (int %1=RED_Client_GetNext(); %1 >= 1 && %1 <= MaxClients; %1=RED_Client_GetNext(++%1))
stock int RED_Client_GetNext(int index = 1) {
	for (int client = index; client <= MaxClients; client++) {
		if (RED_IsValidClient(client))
			return client;
	}

	return -1;
}
