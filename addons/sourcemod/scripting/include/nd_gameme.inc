#if defined _nd_gameme_included
  #endinput
#endif
#define _nd_gameme_included

/**
 * Called when Player Statistics are queried from gameme
 *
 * Faster than OnPlayerStatsQueriedEx but client *may* not be authorized
 * Use OnPlayerStatsQueriedEx instead if the client needs to be authorized
 *
 * @param client  		The index of the player we just queried.
 * @param rank  		The rank of the player we just queried.
 * @param skill  		The skill of the player we just queried.
 *
 * @noreturn
 */
//forward GameME_OnPlayerStatsQueried(client, rank, skill);

/**
 * Called when Player Statistics are queried from gameme and the client is authorized
 *
 * Slower than OnPlayerStatsQueried but client is authorized for steamid retreival
 *
 * @param client  		The index of the player we just queried.
 * @param rank  		The rank of the player we just queried.
 * @param skill  		The skill of the player we just queried.
 *
 * @noreturn
 */
//forward GameME_OnPlayerStatsQueriedEx(client, rank, skill);

#define GAMEME_TYPE_REGULAR 0
#define GAMEME_TYPE_ROOKIE 	1
#define GAMEME_TYPE_VETERN 	2

/**
 * Retreive the server of type we're running
 *
 * See server types in constants above
 *
 * @return        			The type of server.
 */
native GameME_GetServerType();

#define GST_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetServerType") == FeatureStatus_Available)

stock bool:RegularServerType()
{
	return GST_LOADED() && GameME_GetServerType() == GAMEME_TYPE_REGULAR;
}

/**
 * Retreive the cached gameme client skill value
 *
 * If data is not cached, will return 0
 *
 * @param client			The index of the team.
 * @return        			The skill value of the client.
 */
native GameME_GetClientSkill(client);

/**
 * Retreive the cached gameme client rank value
 *
 * If data is not cached, will return 0
 *
 * @param client	 		The index of the team.
 * @return        			The rank value of the client.
 */
native GameME_GetClientRank(client);

/**
 * Check if the redstone server considers the client an vetern player.
 *
 * @param clientIDX  	The index of the client.
 * @return        		Is the client in the ranked database?
 */
native bool:GameME_RankedClient(clientIDX);
