#if defined _nd_com_dep_included_
  #endinput
#endif
#define _nd_com_dep_included_

#define ND_COM_DEP_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "ND_IsCommanderDeprioritised") == FeatureStatus_Available)

native bool ND_IsCommanderDeprioritised(int client);

stock bool ND_IsComDeprioritised(int client)
{
	return ND_COM_DEP_AVAILBLE() && ND_IsCommanderDeprioritised(client);
}