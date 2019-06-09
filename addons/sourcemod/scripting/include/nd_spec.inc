// Called when a player is about to be locked spec
// Allows the action to be canceled by anther plugin
forward Action ND_OnPlayerLockSpec(int client, int team);

// Called after the player is locked in spectator
forward void ND_OnPlayerLockSpecPost(int client, int team);

native bool ND_PlayerSpecLocked(int client);

#define ND_PSL_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "ND_PlayerSpecLocked") == FeatureStatus_Available)

stock bool ND_PlySpecLock(int client) {
	return ND_PSL_AVAILIBLE() && ND_PlayerSpecLocked(client);
}

native bool ND_AdminSpecLocked(int client);

#define ND_ASL_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "ND_AdminSpecLocked") == FeatureStatus_Available)

stock bool ND_AdminSpecLock(int client) {
	return ND_ASL_AVAILIBLE() && ND_AdminSpecLocked(client);
}
