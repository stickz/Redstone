#if defined _nd_redstone_included_
  #endinput
#endif
#define _nd_redstone_included_

#include <sdktools>
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
 * Gets the client count on the server from Redstone
 * Excludes AFK spectators who are not currently playing
 */
stock int RED_ValidClientCount()
{
	int clientCount = 0;

	for (int ix = 1; ix <= MaxClients; ix++)
		if (IsValidClient(ix))
			clientCount++;

	return clientCount;
}

stock int ND_GetClientCount() {
	return ValidClientCount();
}

stock int RED_GetTeamCount(int team)
{
	return ValidTeamCount(team);
}

stock int RED_OnTeamCount()
{
	return OnTeamCount();
}

#define RED_LOOP_CLIENTS(%1) for (int %1=RED_Client_GetNext(); %1 >= 1 && %1 <= MaxClients; %1=RED_Client_GetNext(++%1))
stock int RED_Client_GetNext(int index = 1) {
	for (int client = index; client <= MaxClients; client++) {
		if (IsValidClient(client))
			return client;
	}

	return -1;
}
