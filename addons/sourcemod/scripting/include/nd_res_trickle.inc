#if defined _nd_res_trickle_included
  #endinput
#endif
#define _nd_res_trickle_included

// Add trickle resources to a tertiary
// Returns true on success, false on failure
native bool ND_AddTertiaryResources(int entity, int team, int amount);

// Sets trickle resources to a tertiary
// Returns true on success, false on failure
native bool ND_SetTertiaryResources(int entity, int team, int amount);

// Gets trickle resources to a tertiary
// Returns resources on success, -1 on failure
native int ND_GetTertiaryResources(int entity, int team);
