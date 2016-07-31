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

#define RED_CC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsInCommanderMode") == FeatureStatus_Available)