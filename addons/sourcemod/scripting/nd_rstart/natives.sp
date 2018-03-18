public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PauseWarmup", Native_PauseWarmup);
	CreateNative("ND_TeamPickMode", Native_GetTeamPickMode);
	return APLRes_Success;
}

public int Native_PauseWarmup(Handle plugin, int numParms) {
	return pauseWarmup;
}

public int Native_GetTeamPickMode(Handle plugin, int numParms) {
	return currentlyPicking;
}
