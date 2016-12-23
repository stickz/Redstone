#if defined _nd_rounds_included_
  #endinput
#endif
#define _nd_rounds_included_

/**
 * Checks wether the round is currently started or not
 * Works for usage OnPluginStart() when for late loading
 *
 * Returns false during the first set of loading on server start
 * However, this condiction is not actually a late load.
 *
 * @return True or False 	Round Started.
 */
native bool ND_RoundStarted();

#define NDRS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundStarted") == FeatureStatus_Available)

/**
 * Checks wether the round is currently ended or not
 * Works for usage OnPluginStart() when for late loading
 *
 * Returns false during the first set of loading on server start
 * However, this condiction is not actually a late load.
 *
 * @return True or False 	Round Started.
 */
native bool ND_RoundEnded();

#define NDRE_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundEnded") == FeatureStatus_Available)

/**
 * Checks wether the map is currently started or not
 * Works for usage OnPluginStart() when for late loading
 *
 * Returns false during the first set of loading on server start
 * However, this condiction is not actually a late load.
 *
 * @return True or False 	Map Started.
 */
native bool ND_MapStarted();

#define NDMS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundStarted") == FeatureStatus_Available)

/* Round engine forwards */
forward void ND_OnRoundStart();
forward void ND_OnRoundStarted();

forward void ND_OnRoundEnd();
forward void ND_OnRoundEnded();
