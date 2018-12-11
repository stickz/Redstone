#if defined _nd_restart_included_
  #endinput
#endif
#define _nd_restart_included_

/**
 * Gets wether rock the vote is currently enabled or not
 *
 * Returns the enable status of rtv
 *
 * @return true or false rtv-timeout.
 */
native bool ND_GetRestartStatus();

#define NDS_RESTART_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetRestartStatus") == FeatureStatus_Available)

/**
 * Sets the enable status of rock the vote
 * Pass ether true or false as a perimeter
 *
 * @param1 true or false
 * @noreturn
 */
native void ND_ToogleRestartStatus(bool state);

#define NDT_RESTART_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_ToogleRestartStatus") == FeatureStatus_Available)
