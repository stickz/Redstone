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
native int GameME_GetServerType();

#define GST_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetServerType") == FeatureStatus_Available)

stock bool RegularServerType()
{
	//assume true of native int is not availible
	bool gstLoaded = GST_LOADED();
	return gstLoaded && GameME_GetServerType() == GAMEME_TYPE_REGULAR || !gstLoaded;
}

stock bool RookieServerType() {
	return GST_LOADED() && GameME_GetServerType() == GAMEME_TYPE_ROOKIE;
}
stock bool CompetitiveServerType() {
	return GST_LOADED() && GameME_GetServerType() == GAMEME_TYPE_VETERN;
}

/**
 * Retreive the cached gameme client skill value
 *
 * If data is not cached, will return 0
 *
 * @param client			The index of the client.
 * @return        			The skill value of the client.
 */
native int GameME_GetClientSkill(int client);

#define GCS_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientSkill") == FeatureStatus_Available)

stock bool GameME_SkillAvailible(int client) {
	return GCS_LOADED() && GameME_GetClientSkill(client) > 0;
}

/**
 * Retreive the cached gameme client rank value
 *
 * If data is not cached, will return 0
 *
 * @param client	 		The index of the client.
 * @return        			The rank value of the client.
 */
native int GameME_GetClientRank(int client);

/**
 * Retreive the cached gameme client death value
 *
 * If data is not cached, will return 0
 *
 * @param client	 		The index of the client.
 * @return        			The amount of death the client.
 */
native int GameME_GetClientDeaths(int client);

#define GCD_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientKills") == FeatureStatus_Available)

stock bool GameME_Deaths_Availible(int client) {
	return GCD_LOADED() && GameME_GetClientDeaths(client) > 0;
}

/**
 * Retreive the cached gameme client kill value
 *
 * If data is not cached, will return 0
 *
 * @param client	 		The index of the client.
 * @return        			The amount of kills the client.
 */
native int GameME_GetClientKills(int client);

#define GM_GCC_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientKills") == FeatureStatus_Available)

stock bool GameME_Kills_Availible(int client) {
	return GM_GCC_LOADED() && GameME_GetClientKills(client) > 0;
}

/**
 * Retreive the cached gameme client headshot value
 *
 * If data is not cached, will return 0
 *
 * @param client	 		The index of the client.
 * @return        			The amount of kills the client.
 */
native int GameME_GetClientHeadshots(int client);

#define GM_GCH_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientHeadshots") == FeatureStatus_Available)

stock bool GameME_Headshots_Availible(int client) {
	return GM_GCH_LOADED() && GameME_GetClientHeadshots(client) > 0;
}

/**
 * Check if the redstone server considers the client an vetern player.
 *
 * @param clientIDX  	The index of the client.
 * @return        		Is the client in the ranked database?
 */
native bool GameME_RankedClient(int clientIDX);

#define GM_RC_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_RankedClient") == FeatureStatus_Available)

/**
 * Retreive the cached gameme client kdr
 *
 * If data is not cached, will return 0.0
 *
 * @param client			The index of the team.
 * @return        			The kdr of the client.
 */
native float GameME_GetClientKDR(int clientIDX)

#define GCK_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientKDR") == FeatureStatus_Available)

stock bool GameME_KDR_Availible(int client) {
	return GCK_LOADED() && GameME_GetClientKDR(client) > 0.0;
}

/**
 * Retreive the cached gameme client hpk
 *
 * If data is not cached, will return 0.0
 *
 * @param client			The index of the team.
 * @return        			The hpk of the client.
 */
native float GameME_GetClientHPK(int clientIDX)

#define GCH_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetClientHPK") == FeatureStatus_Available)

stock bool GameME_HPK_Availible(int client) {
	return GCH_LOADED() && GameME_GetClientHPK(client) > 0.0;
}

forward void GameME_OnClientDataQueried(int client, int skill, float kdr, float hpk);