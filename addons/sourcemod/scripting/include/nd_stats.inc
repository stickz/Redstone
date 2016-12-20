#if defined _nd_stats_included_
  #endinput
#endif
#define _nd_stats_included_

/**
 * Retreive the cached client expereince
 * Does not work until after OnClientPutInServer()
 * 
 * Returns the client expereince or -1 on failure
 *
 * @return integer 			Client Expereince
 */
native int ND_GetClientEXP(int client);

#define ND_GCE_LOADED() (GetFeatureStatus(FeatureType_Native, "ND_GetClientEXP") == FeatureStatus_Available)

stock bool ND_EXPAvailible(int client) {
	return ND_GCE_LOADED() && ND_GetClientEXP(client) > 0;
}

forward void ND_OnClientExpRetrieved(int client, int exp);
