// Called when a player is about to be locked spec
// Allows the action to be canceled by anther plugin
forward Action ND_OnPlayerLockSpec(int client, int team);

native bool ND_PlayerSpecLocked(int client);

#define ND_PSL_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "TB_TeamsLocked") == FeatureStatus_Available)

stock bool ND_PlySpecLock(int client) {
	return ND_PSL_AVAILIBLE() && ND_PlayerSpecLocked(client);
}
