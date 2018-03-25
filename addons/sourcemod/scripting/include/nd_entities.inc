#define ENTITY_NOT_FOUND -1

native int ND_GetTeamEntity(int team);
native int ND_GetPlayerManagerEntity();
native int ND_GetTeamBunkerEntity(int team);


/** 
 * Retreives the bunker distance from a given position
 *
 * @param team		Team index of Bunker.
 * @param pos[3]	X,Y,Z vector position
 *
 * @return		The distance the vector is from the team's bunker
 */ 
stock float ND_GetBunkerDistance(int team, float pos[3]) 
{
	// Get the bunker entity based on the team
	int bunker = ND_GetTeamBunkerEntity(team);
	
	float bunkerPos[3]; // Get the position of the bunker
	GetEntPropVector(bunker, Prop_Send, "m_vecOrigin", bunkerPos);
	
	// Return distance between inputted and bunker position
	return GetVectorDistance(pos, bunkerPos);	
}

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

/** 
 * Retreives the current resources of a given team index
 *
 * @param team			team index.
 * @return			The resources of the team.
 */ 
stock int ND_GetCurrentResources(int team) {
	return GetEntProp(ND_GetTeamEntity(team), Prop_Send, "m_iResourcePoints");
}

/** 
 * Retreives the total resources spent by a given team index
 *
 * @param team			team index.
 * @return			The resources of the team.
 */ 
stock int ND_GetSpentResources(int team) {
	return GetEntProp(ND_GetTeamEntity(team), Prop_Send, "m_iExpendedResources");
}


/** 
 * Retreives the total resources accumulated by a given team index
 *
 * @param team			team index.
 * @return			The resources of the team.
 */ 
stock int ND_GetAccumulatedResources(int team) 
{
	int teamEntity = ND_GetTeamEntity(team);
	return 	GetEntProp(teamEntity, Prop_Send, "m_iResourcePoints") +
		GetEntProp(teamEntity, Prop_Send, "m_iExpendedResources");
}

/** 
 * Retreives the building health of a given entity
 *
 * @param entity		entity index.
 * @return			The health of the building.
 */ 
stock int ND_GetBuildingHealth(int entity) {
 	return GetEntProp(entity, Prop_Send, "m_iHealth");
}
