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
native bool RED_IsValidClient(int ClientIDX);

#define RED_IVC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RED_IsValidClient") == FeatureStatus_Available)