public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PickedTeamsThisMap", Native_GetPickedTeamsThisMap);
	MarkNativeAsOptional("ND_IsPlayerMarkedAFK");
	return APLRes_Success;
}

public int Native_GetPickedTeamsThisMap(Handle plugin, int numParms) {
	return g_bPickedThisMap;
}
