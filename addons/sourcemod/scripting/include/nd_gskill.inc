/* Forwards and natives for the player skill calculation plugin
 */

forward void GameME_OnSkillCalculated(int client, float skill);

native float GameME_GetFinalSkill(int client);
native float GameME_GetSkillBase(int client);

#define GM_GFS_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetFinalSkill") == FeatureStatus_Available)
#define GM_GSB_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetSkillBase") == FeatureStatus_Available)
  
