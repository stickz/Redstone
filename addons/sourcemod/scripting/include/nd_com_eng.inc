#if defined _nd_com_eng_included_
  #endinput
#endif
#define _nd_com_eng_included_

#define NO_COMMANDER -1

/**
 * Gets if the commander has commander mode.
 * At least once this round.
 *
 * Accepts the input of any client on a team
 * Then checks if their commander has entered rts_view
 *
 * @parm1 clientIDX
 * @return bool (true, false).
 */

native bool ND_EnteredCommanderMode(int clientIDX);
	
#define ND_ECM_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_EnteredCommanderMode") == FeatureStatus_Available)
	
stock bool ND_HasEnteredCommanderMode(int clientIDX) {
	return ND_ECM_AVAILABLE() && ND_EnteredCommanderMode(clientIDX);
}

/**
 * Gets if the commander is in commander mode
 *
 * Accepts the input of any client on a team
 * Then checks if their commander is in rts_view
 *
 * @parm1 clientIDX
 * @return bool (true, false).
 */

native bool ND_IsInCommanderMode(int clientIDX);

#define ND_IICM_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsInCommanderMode") == FeatureStatus_Available)

stock bool ND_InCommanderMode(int clientIDX) {
	return ND_IICM_AVAILABLE() && ND_IsInCommanderMode(clientIDX);
}

/**
 * Gets the commander on a given team
 *
 * Accepts input of etheir team consort or empire
 *
 * @parm1 teamIDX consort or empire
 * @return clientIDX of commander.
 */
native int ND_GetTeamCommander(int teamIDX);
#define ND_GTC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_GetTeamCommander") == FeatureStatus_Available)

stock int ND_GetCommanderOnTeam(int teamIDX) {
	return !ND_GTC_AVAILABLE() ? -1 : ND_GetTeamCommander(teamIDX);
}

stock bool ND_TeamHasCommander(int teamIDX) {
	return ND_GetCommanderOnTeam(teamIDX) != -1;	
}

stock int ND_GetCommanderCount()
{
	int count = 0;
	
	// For team consort and team empire
	for (int team = 2; team < 4; team++)
	{
		if (ND_TeamHasCommander(team))
		{
			count++;	
		}
	}
	
	return count;
}

/**
 * Gets if a given client is a commander
 *
 * Accepts the input of any client on a team
 *
 * @parm1 clientIDX
 * @return bool (true, false).
 */
native bool ND_IsCommanderClient(int clientIDX);
#define ND_ICC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsCommanderClient") == FeatureStatus_Available)

stock bool ND_IsCommander(int clientIDX) {
	return ND_ICC_AVAILABLE() && ND_IsCommanderClient(clientIDX);
}

/* A few forwards */
forward Action ND_OnCommanderResigned(int client, int team);
forward Action ND_OnCommanderMutiny(int client, int commander, int team);
forward void ND_OnCommanderPromoted(int client, int team);
forward void ND_OnCommanderStateChanged(int team);
