#if defined _nd_com_eng_included_
  #endinput
#endif
#define _nd_com_eng_included_

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

stock bool ND_InCommanderMode(int clientIDX)
{
	return ND_IICM_AVAILABLE() && ND_IsInCommanderMode(clientIDX);
}