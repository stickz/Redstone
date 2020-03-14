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
native float ND_GetEnhancedAverage(float avr = 0.7, float med = 0.3);

#define ND_GED_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamDifference") == FeatureStatus_Available)
native float ND_GetTeamDifference();

stock float ND_GetCeilingSD(float ceiling)
{
	if (!ND_GPS_AVAILBLE())
		return 0.0;
	
	float skill = 0.0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			// Limit the player skill to the ceiling;
			float pSkill = ND_GetPlayerSkill(client);
			if (pSkill > ceiling)
				pSkill = ceiling;
			
			// Add or subtract the skill from the total
			switch (GetClientTeam(client))
			{
				case 2: skill += pSkill;
				case 3: skill -= pSkill;			
			}		
		}
	}
	
	return skill;
}

stock int ND_GetSkillDiffPercent()
{
	// Get the team difference and the enhanced average
	float teamDiff = ND_GetTeamDifference();
	float average = ND_GetEnhancedAverage();
	
	// If the team difference is negative, make it possible
	if (teamDiff < 0)
		teamDiff *= -1;
	
	// If there is 1 player, set average to teamdiff
	if (average < 0)
		average = teamDiff;
	
	// Calculate the difference percent and return it
	float totalFloat = teamDiff / average * 100.0
	return RoundFloat(totalFloat);
}
