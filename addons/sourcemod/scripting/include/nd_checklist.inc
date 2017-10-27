native bool ND_CheckListComplete(int client);
#define ND_CheckC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_CheckListComplete") == FeatureStatus_Available)

stock bool ND_CheckListDone(int client) {
	return !ND_CheckC_AVAILABLE() ? true : ND_CheckListComplete(client);
}

native bool ND_CheckListDisabled(int client);
#define ND_CheckD_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_CheckListDisabled") == FeatureStatus_Available)

stock bool ND_CheckListOff(int client) {
	return !ND_CheckD_AVAILABLE() ? true : ND_CheckListDisabled(client);
}