#if defined _nd_fskill_included
  #endinput
#endif
#define _nd_fskill_included

native float ND_GetPlayerSkill(int client);
native float ND_GetCommanderSkill(int client);
native int ND_GetPlayerLevel(int client);

native float ND_GetSkillMedian();
native float ND_GetSkillAverage();
native float ND_GetTeamSkillAverage(int team);

#define ND_GEA_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetEnhancedAverage") == FeatureStatus_Available)
native float ND_GetEnhancedAverage();

native float ND_GetTeamDifference();