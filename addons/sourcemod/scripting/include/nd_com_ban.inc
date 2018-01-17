#if defined _nd_com_ban_included_
  #endinput
#endif
#define _nd_com_ban_included_

native bool ND_IsCommanderBanned(int client);
#define ND_COMB_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsCommanderBanned") == FeatureStatus_Available)
