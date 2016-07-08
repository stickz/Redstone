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
native int ND_GetClientEXP();