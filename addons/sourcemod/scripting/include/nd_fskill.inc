#if defined _nd_fskill_included
  #endinput
#endif
#define _nd_fskill_included

native float ND_GetPlayerSkill(int client);
native int ND_GetPlayerLevel(int client);

#define ND_GSA_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetSkillAverage") == FeatureStatus_Available)
native float ND_GetSkillAverage();

#define ND_GSM_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetSkillMedian") == FeatureStatus_Available)
native float ND_GetSkillMedian();

#define ND_GEA_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetEnhancedAverage") == FeatureStatus_Available)
native float ND_GetEnhancedAverage();

native float ND_GetTeamSkillAverage(int team);

native float ND_GetTeamDifference();
