#if defined _nd_turret_eng_included
  #endinput
#endif
#define _nd_turret_eng_included

#define NGTC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTurretCount") == FeatureStatus_Available)
native int ND_GetTurretCount();

stock int ND_TurretCount() {
	return !NGTC_AVAILABLE() ? 0 : ND_GetTurretCount();
}

#define NGTTC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamTurretCount") == FeatureStatus_Available)
native int ND_GetTeamTurretCount(int team);

stock int ND_TeamTurretCount(int team) {
	return !NGTTC_AVAILABLE() ? 0 : ND_GetTeamTurretCount(team);
}
