#define ENTITY_NOT_FOUND -1

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
