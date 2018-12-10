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
 * Checks wether the round started this Map or not
 * Works incase SimulateRoundEnd() is fired
 *
 * @return True or False 	Round Started this map.
 */
native bool ND_RoundStartedThisMap();

#define NDRSTM_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundStartedThisMap") == FeatureStatus_Available)

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

/**
 * Checks wether the round can be restarted yet or not
 * 
 * Is the round currently in progress?
 * Has it started more than 60s ago?
 * Is the round not already restarting?
 *
 * @return True or False 	Round Restartable.
 */
native bool ND_RoundRestartable();

#define NDRR_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_RoundStarted") == FeatureStatus_Available)

/**
 * Cause the round to be restarted if possible. Check ND_RoundRestartable() first.
 *
 * Plugins must wait 60s after round start before using this feature
 * Time-limit killing is used to restart. It requires a 60s buffer.
 *
 * If toWarmup is set true, the round will pause for manual restart.
 * If toWarmup is set false, the round will restart immediately.
 *
 * @throws Native error If the round is not restartable
 * @param toWarmup true or false
 * @noreturn
 */
native void ND_RestartRound(bool toWarmup);

/* Round engine forwards */
forward void ND_OnPreRoundStart();
forward void ND_OnRoundStarted();
forward void ND_OnRoundEnded();

// Only fires if the round has started this map
forward void ND_OnRoundEndedEX();

// Simulate the round ending to contact other plugins
native void ND_SimulateRoundEnd();

// Start the round and contact other plugins beforehand
native void ND_PerformRoundStart();
