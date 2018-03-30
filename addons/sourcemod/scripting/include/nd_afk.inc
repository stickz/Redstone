
#define ND_IPMA_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsPlayerMarkedAFK") == FeatureStatus_Available)
native bool ND_IsPlayerMarkedAFK(int client);

stock bool ND_IsMarkedAFK(int client) {
	return ND_IPMA_AVAILABLE() && ND_IsPlayerMarkedAFK(client);	
}
