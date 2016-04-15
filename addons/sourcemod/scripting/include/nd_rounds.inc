#if defined _nd_rounds_included_
  #endinput
#endif
#define _nd_rounds_included_

/**
 * Checks wether the round is currently started or not
 * Works for ussage OnPluginStart() when for late loading
 *
 * @return True or False 	Round Started.
 */
native bool:ND_RoundStarted();

#define TDS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundStarted") == FeatureStatus_Available)