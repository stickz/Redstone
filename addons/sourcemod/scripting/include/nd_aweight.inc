#if defined _nd_aweight_included_
  #endinput
#endif
#define _nd_aweight_included_

#define ND_AWEIGHT_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetSkillFloor") == FeatureStatus_Available)

native int ND_GetSkillFloor(int client);

stock int ND_GetSkillFloorEx(int client)
{
	return !ND_AWEIGHT_AVAILABLE() ? -1 : ND_GetSkillFloor(client);
}