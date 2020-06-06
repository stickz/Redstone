#if defined _nd_res_trickle_included
  #endinput
#endif
#define _nd_res_trickle_included

// Fires when a resource point first starts fracking
// 
forward void ND_OnResFrackStarted(int resType, float delay, int interval, int amount);

// Add trickle resources to a tertiary
// Returns true on success, false on failure
native bool ND_AddTertiaryResources(int entity, int team, int amount);

// Sets trickle resources to a tertiary
// Returns true on success, false on failure
native bool ND_SetTertiaryResources(int entity, int team, int amount);

// Gets trickle resources to a tertiary
// Returns resources on success, -1 on failure
native int ND_GetTertiaryResources(int entity, int team);

// Add trickle resources to a secondary
// Returns true on success, false on failure
native bool ND_AddSecondaryResources(int entity, int team, int amount);

// Sets trickle resources to a secondary
// Returns true on success, false on failure
native bool ND_SetSecondaryResources(int entity, int team, int amount);

// Gets trickle resources to a secondary
// Returns resources on success, -1 on failure
native int ND_GetSecondaryResources(int entity, int team);

// Add trickle resources to primary
// Returns true on success, false on failure
native bool ND_AddPrimaryResources(int team, int amount);

// Sets trickle resources to primary
// Returns true on success, false on failure
native bool ND_SetPrimaryResources(int team, int amount);

// Gets trickle resources to primary
// Returns resources on success, -1 on failure
native int ND_GetPrimaryResources(int team);

#define ND_RES_TGET_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTertiaryResources") == FeatureStatus_Available)
#define ND_RES_SGET_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetSecondaryResources") == FeatureStatus_Available)
#define ND_RES_PGET_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetPrimaryResources") == FeatureStatus_Available)