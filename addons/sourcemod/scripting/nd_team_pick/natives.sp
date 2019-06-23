public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PickedTeamsThisMap", Native_GetPickedTeamsThisMap);
	CreateNative("ND_GetTeamCaptain", Native_GetTeamCaptainThisMap);
	CreateNative("ND_GetPlayerPicked", Native_GetPlayerPickedThisMap);
	MarkNativeAsOptional("ND_IsPlayerMarkedAFK");
	return APLRes_Success;
}

public int Native_GetTeamCaptainThisMap(Handle plugin, int numParms)
{
	int team = GetNativeCell(1)-2;
	return team_captain[team];
}

public int Native_GetPickedTeamsThisMap(Handle plugin, int numParms) {
	return g_bPickedThisMap;
}

public int Native_GetPlayerPickedThisMap(Handle plugin, int numParms) 
{
	int client = GetNativeCell(1);
	
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));	
	return PlayersPicked.FindString(gAuth) != -1;
}
