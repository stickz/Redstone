native int ND_GetTeamEntity(int team);
native int ND_GetPlayerManagerEntity();
native int ND_GetTeamBunkerEntity(int team);

/** 
 * Retreives the level of a given client index
 *
 * @param client		Client index.
 * @return			The level of the client or some value less than 2 (if not loaded)
 */ 
stock int ND_RetreiveLevel(int client) {
	return GetEntProp(ND_GetPlayerManagerEntity(), Prop_Send, "m_iPlayerRank", 1, client);
}

/** 
 * Retreives the current score of a given client index
 *
 * @param client		Client index.
 * @return			The score of the client.
 */ 
stock int ND_RetrieveScore(int client) {
	return GetEntProp(ND_GetPlayerManagerEntity(), Prop_Send, "m_iScore", 1, client);
}
