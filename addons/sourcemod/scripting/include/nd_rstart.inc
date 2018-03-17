#if defined _nd_rstart_included_
  #endinput
#endif
#define _nd_rstart_included_

native bool ND_PauseWarmup();
#define ND_PW_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_PauseWarmup") == FeatureStatus_Available)

stoock bool ND_PauseWarmupRound() {
	return ND_PW_AVAILABLE() && ND_PauseWarmup();
}
