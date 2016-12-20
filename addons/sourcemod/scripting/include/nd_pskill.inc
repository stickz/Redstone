/* Forwards and natives for the player skill calculation plugin
 */

forward void GameME_OnSkillCalculated(int client, float skill);
forward void SteamWorks_OnSkillCalculated(int client, float skill);

native float GameME_GetFinalSkill(int client);
native float SteamWorks_GetFinalSkill(int client);

#define GM_GFS_LOADED() (GetFeatureStatus(FeatureType_Native, "GameME_GetFinalSkill") == FeatureStatus_Available)
#define SW_GFS_LOADED() (GetFeatureStatus(FeatureType_Native, "SteamWorks_GetFinalSkill") == FeatureStatus_Available)