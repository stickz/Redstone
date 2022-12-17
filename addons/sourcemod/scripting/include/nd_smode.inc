#if defined _nd_smode_included_
  #endinput
#endif

#define _nd_smode_included_

#define SERVER_MODE_REGULAR 0
#define SERVER_MODE_MAPTEST 1

// Returns the server mode, see defines above
native int ND_GetServerMode();

// Check if the native available before calling it
#define ND_SMODE_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetServerMode") == FeatureStatus_Available)

stock int ND_GetServerModeEx() {
	return !ND_SMODE_AVAILABLE() ? SERVER_MODE_REGULAR : ND_GetServerMode();
}
