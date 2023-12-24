/* Natives */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_TriggerMapVote", Native_TriggerMapVote);
	
	MarkNativeAsOptional("ND_WarmupCompleted");
	MarkNativeAsOptional("ND_TeamPickMode");
	
	MarkNativeAsOptional("ND_PickedTeamsThisMap");
	
	return APLRes_Success;
}

public Native_TriggerMapVote(Handle plugin, int numParms)
{
	if (IsVoteInProgress())
		return false;	
	
	StartAndSetupMapVoter();
	return true;
}