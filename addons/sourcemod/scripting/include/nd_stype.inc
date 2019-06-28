#if defined _nd_stype_included_
  #endinput
#endif

#define _nd_stype_included_

#define SERVER_TYPE_DISABLE	0
#define SERVER_TYPE_STABLE 	1
#define SERVER_TYPE_BETA	2
#define SERVER_TYPE_ALPHA	3
#define SERVER_TYPE_VANILLA	4

enum ND_Server_Types {
	ND_SType_Disable,
	ND_SType_Stable,
	ND_SType_Beta,
	ND_SType_Alpha,
	ND_SType_Vanilla
};

// Returns the server type, see defines above
native int ND_GetServerType();

// Check if the native availible before calling it
#define ND_STYPE_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetServerType") == FeatureStatus_Available)

stock int ND_GetServerTypeEx(ND_Server_Types SType = ND_SType_Stable ) {
	return !ND_STYPE_AVAILABLE() ? view_as<int>(SType) : ND_GetServerType();
}
