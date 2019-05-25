public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PickedTeamsThisMap", Native_GetPickedTeamsThisMap);
	CreateNative("ND_GetTeamCaptain", Native_GetTeamCaptainThisMap);
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
