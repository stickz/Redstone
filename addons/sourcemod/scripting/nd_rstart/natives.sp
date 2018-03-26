public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PauseWarmup", Native_PauseWarmup);
	CreateNative("ND_TeamPickMode", Native_GetTeamPickMode);
	
	/* Must natives as optional for this plugin,
	 * To prevent round start interface
	 */
	MarkNativeAsOptional("ND_PickedTeamsThisMap");
	MarkNativeAsOptional("WB2_BalanceTeams");
	MarkNativeAsOptional("WB2_GetBalanceData");
	MarkNativeAsOptional("ND_WarmupCompleted");
	
	return APLRes_Success;
}

public int Native_PauseWarmup(Handle plugin, int numParms) {
	return pauseWarmup;
}

public int Native_GetTeamPickMode(Handle plugin, int numParms) {
	return currentlyPicking;
}
