#if defined _nd_mvote_included_
  #endinput
#endif
#define _nd_mvote_included_

native bool ND_TriggerMapVote();

// Checks if the ND_GetMapVoteList() native function is available
#define ND_MVOTE_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_TriggerMapVote") == FeatureStatus_Available)