#if defined _nd_teampick_included
  #endinput
#endif
#define _nd_teampick_included

#include <nd_stocks>

native bool ND_PickedTeamsThisMap();
#define ND_PTTM_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_PickedTeamsThisMap") == FeatureStatus_Available)

stock bool ND_TeamsPickedThisMap() {
	return ND_PTTM_AVAILABLE() && ND_PickedTeamsThisMap();
}

stock bool ND_HasTPRunAccess(int client) {
	return ND_TeamsPickedThisMap() || HasRootAccess(client);
}

native int ND_GetTeamCaptain(int team);
#define ND_TP_GTC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamCaptain") == FeatureStatus_Available)

stock int GetTeamPickCaptain(int team) {
	return !ND_TP_GTC_AVAILABLE() ? -1 : ND_GetTeamCaptain(team);
}

native bool ND_GetPlayerPicked(int client);
#define NDTP_GPP_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetPlayerPicked") == FeatureStatus_Available)

stock bool ND_PlayerPicked(int client) {
	return NDTP_GPP_AVAILABLE() && ND_GetPlayerPicked(client);
}

native int ND_GetTPTeam(int client);
#define NDTP_GTPT_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTPTeam") == FeatureStatus_Available)

stock int ND_GetPickedTeam(int client) {
	return NDTP_GTPT_AVAILABLE() ? TEAM_SPEC : ND_GetTPTeam(client);
}
