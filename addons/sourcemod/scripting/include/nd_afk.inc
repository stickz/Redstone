
#define ND_IPMA_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "GameME_GetFinalSkill") == FeatureStatus_Available)
native bool ND_IsPlayerMarkedAfk(int client);

stock boolean ND_IsMarkedAfk(int client) {
	return ND_IPMA_AVAILABLE() && ND_IsPlayerMarkedAfk(client);	
}

stock boolean ND_IsMarkedAFK(int client) {
	return ND_IPMA_AVAILABLE() && ND_IsPlayerMarkedAfk(client);	
}