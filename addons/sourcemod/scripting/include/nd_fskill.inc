#if defined _nd_fskill_included
  #endinput
#endif
#define _nd_fskill_included

native float ND_GetPlayerSkill(int client);
native int ND_GetPlayerLevel(int client);

native float ND_GetSkillAverage();
native float ND_GetTeamSkillAverage(int team);

native float ND_GetTeamDifference();