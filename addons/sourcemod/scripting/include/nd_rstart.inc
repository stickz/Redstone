#if defined _nd_rstart_included_
  #endinput
#endif
#define _nd_rstart_included_

native bool ND_PauseWarmup();
#define ND_PW_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_PauseWarmup") == FeatureStatus_Available)

stock bool ND_PauseWarmupRound() {
	return ND_PW_AVAILABLE() && ND_PauseWarmup();
}

/* Ask the warmup plugin if TeamPick mode is running */
native bool ND_TeamPickMode();
#define ND_TPM_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_TeamPickMode") == FeatureStatus_Available)

stock bool IsTeamPickRunning() {
	return !ND_TPM_AVAILABLE() ? true : ND_TeamPickMode();
}

stock bool HasTeamPickAccess(int client) {
	return IsTeamPickRunning() || HasRootAccess(client);
}
