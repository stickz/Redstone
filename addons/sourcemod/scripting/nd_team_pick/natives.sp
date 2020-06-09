public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PickedTeamsThisMap", Native_GetPickedTeamsThisMap);
	CreateNative("ND_GetTeamCaptain", Native_GetTeamCaptainThisMap);
	CreateNative("ND_GetPlayerPicked", Native_GetPlayerPickedThisMap);
	CreateNative("ND_GetTPTeam", Native_GetPlayerPickedTeamThisMap);
	CreateNative("ND_CurrentPicking", Native_GetCurrentlyPicking);
	
	// Make the afk marker plugin optional
	MarkNativeAsOptional("ND_IsPlayerMarkedAFK");
	
	// Make the warmup plugin optional
	MarkNativeAsOptional("ND_WarmupCompleted");
	
	return APLRes_Success;
}

public int Native_GetTeamCaptainThisMap(Handle plugin, int numParms)
{
	int team = GetNativeCell(1)-2;
	return team_captain[team];
}

public int Native_GetPickedTeamsThisMap(Handle plugin, int numParms) {
	return _:g_bPickedThisMap;
}

public int Native_GetPlayerPickedThisMap(Handle plugin, int numParms) 
{
	int client = GetNativeCell(1);
	
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));	
	return PickedConsort.FindString(gAuth) != -1 || PickedEmpire.FindString(gAuth) != -1;
}

public int Native_GetPlayerPickedTeamThisMap(Handle plugin, int numParms) 
{
	int client = GetNativeCell(1);
	
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));	
	
	if (PickedConsort.FindString(gAuth) != -1)
		return TEAM_CONSORT;
	
	else if (PickedEmpire.FindString(gAuth) != -1)
		return TEAM_EMPIRE;
	
	return TEAM_SPEC;	
}

public int Native_GetCurrentlyPicking(Handle plugin, int numParms) {
	return _:g_bEnabled;
}