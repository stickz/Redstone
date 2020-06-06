#if defined _nd_resource_eng_included
  #endinput
#endif
#define _nd_resource_eng_included

forward void ND_OnResPointsCached();
forward void ND_OnPrimeDepleted(int entity);
forward void ND_OnTertairySpawned(int entity, int trigger);

native bool ND_ResPointsCached();
native bool ND_IsPrimeDepleted();

#define ND_RES_IPD_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsPrimeDepleted") == FeatureStatus_Available)

stock bool ND_PrimeDepleted() {
	return ND_RES_IPD_AVAILABLE() && ND_IsPrimeDepleted(); 
}

// Note: Also see nd_entities for the same primary resource entity
native int ND_GetPrimaryPoint();

// Returns of list of secondary resource points on the map
native ArrayList ND_GetSecondaryList();

// Returns a list of tertiary resource points on the map
native ArrayList ND_GetTertiaryList();

native void ND_SpawnTertiaryPoint(float[] origin);
native void ND_RemoveTertiaryPoint(char[] rtName, char[] trigName);

// Returns how many secondaries are on the map
native int ND_GetSecondaryCount();

// Returns a secondary entity at a given array index between 0 and sec count - 1
native int ND_GetSecondaryEnt(int entity);