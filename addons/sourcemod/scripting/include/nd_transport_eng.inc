#if defined _nd_transport_eng_included
  #endinput
#endif
#define _nd_transport_eng_included

#define NGTGC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamTGCache") == FeatureStatus_Available)
native int ND_GetTeamTGCache(int team);

// Attempt to use the transport gate cache before searching entities
// Constantly looking up this value is a too intensive operation
stock int ND_TeamTGCount(int team) {
	return !NGTGC_AVAILABLE() ? ND_GetTransportCount(team) : ND_GetTeamTGCache(team);
}

stock int ND_GetTransportCount(int team)
{
	int loopEntity = INVALID_ENT_REFERENCE;
	int gates[TEAM_COUNT] = { 0, ... };
	
	while ((loopEntity = FindEntityByClassname(loopEntity, STRUCT_TRANSPORT)) != INVALID_ENT_REFERENCE)
	{
		int team = GetEntProp(loopEntity, Prop_Send, "m_iTeamNum");
		gates[team]++;
	}
	
	return gates[team];
}