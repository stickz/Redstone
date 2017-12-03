#if defined _nd_mlist_included_
  #endinput
#endif
#define _nd_mlist_included_

// Returns a list of maps to display in map vote
native ArrayList ND_GetMapVoteList();

// Checks if the ND_GetMapVoteList() native function is available
#define ND_MLIST_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetMapVoteList") == FeatureStatus_Available)