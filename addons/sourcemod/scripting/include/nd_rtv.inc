#if defined _nd_rtv_included_
  #endinput
#endif
#define _nd_rtv_included_

/**
 * Gets wether rock the vote is currently enabled or not
 *
 * Returns the enable status of rtv
 *
 * @return true or false rtv-timeout.
 */
native bool ND_GetRtvStatus();

#define ND_GRS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetRtvStatus") == FeatureStatus_Available)

/**
 * Sets the enable status of rock the vote
 * Pass ether true or false as a perimeter
 *
 * @param1 true or false
 * @noreturn
 */
native void ND_ToogleRtvStatus(bool state);

#define ND_TRS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_ToogleRtvStatus") == FeatureStatus_Available)
