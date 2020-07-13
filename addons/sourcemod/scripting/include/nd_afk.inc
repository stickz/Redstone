
#define ND_IPMA_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsPlayerMarkedAFK") == FeatureStatus_Available)
native bool ND_IsPlayerMarkedAFK(int client);

stock bool ND_IsMarkedAFK(int client) {
	return ND_IPMA_AVAILABLE() && ND_IsPlayerMarkedAFK(client);	
}

#define ND_IPCA_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsPlayerCheckedAFK") == FeatureStatus_Available)
native bool ND_IsPlayerCheckedAFK(int client);

stock bool ND_IsCheckedAFK(int client) {
	return ND_IPCA_AVAILABLE() && ND_IsPlayerCheckedAFK(client);
}