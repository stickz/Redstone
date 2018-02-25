#if defined _nd_fskill_included
  #endinput
#endif
#define _nd_fskill_included

native float ND_GetPlayerSkill(int client);
#define ND_GPS_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetPlayerSkill") == FeatureStatus_Available)

stock int ND_GetRoundedPSkill(int client) {
	return !ND_GPS_AVAILBLE() ? 0 : RoundFloat(ND_GetPlayerSkill(client));
}

stock float ND_GetPrecisePSkill(int client) {
	return !ND_GPS_AVAILBLE() ? 0.0 : ND_GetPlayerSkill(client);
}

native float ND_GetCommanderSkill(int client);
#define ND_GCS_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetCommanderSkill") == FeatureStatus_Available)

stock int ND_GetRoundedCSkill(int client) {
	return !ND_GCS_AVAILBLE() ? 0 : RoundFloat(ND_GetCommanderSkill(client));
}

stock float ND_GetPreciseCSkill(int client) {
	return !ND_GCS_AVAILBLE() ? 0.0 : ND_GetCommanderSkill(client);
}

native int ND_GetPlayerLevel(int client);

#define ND_GSM_AVAILBLE2() (GetFeatureStatus(FeatureType_Native, "ND_GetSkillMedian") == FeatureStatus_Available)
native float ND_GetSkillMedian();
native float ND_GetSkillAverage();
native float ND_GetTeamSkillAverage(int team);

#define ND_GEA_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetEnhancedAverage") == FeatureStatus_Available)
native float ND_GetEnhancedAverage();

#define ND_GED_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamDifference") == FeatureStatus_Available)
native float ND_GetTeamDifference();
