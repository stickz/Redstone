public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_PauseWarmup", Native_PauseWarmup);	
	return APLRes_Success;
}

public int Native_PauseWarmup(Handle plugin, int numParms) {
	return pauseWarmup;
}
