#if defined _SWGM_included
 #endinput
#endif
#define _SWGM_included

enum Status
{
	UNASSIGNED = 0,
	NO_GROUP,
	MEMBER,
	OFFICER,
	LEAVER
};

/**
 *	Called when player checked. 
 *
 *	@param iClient			Player index.
 *	@param IsMember			In group ?
 *	@param IsOfficer		Admin/Officer ?
 *	@noreturn
*/
forward void SWGM_OnJoinGroup(int iClient, bool IsMember, bool IsOfficer);

/**
 *	Called when player checked again and he leaved the group. 
 *
 *	@param iClient			Player index.
 *	@noreturn
*/
forward void SWGM_OnLeaveGroup(int iClient);

/**
 *  Check is player in group.
 *
 *  @param iClient          Player index.
 *  @return                 true if in group, else false.
 *  @error                  Invalid client index, client not in game, or client bot.
 */
native bool SWGM_InGroup(int iClient);
#define SWGM_IG_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "SWGM_InGroup") == FeatureStatus_Available)

stock bool SWGM_IsInGroup(int iClient, bool bDefault) {
	return !SWGM_IG_AVAILIBLE() ? bDefault : SWGM_InGroup(iClient);
}

/**
 *  Check is player in group and officer.
 *
 *  @param iClient          Player index.
 *  @return                 true if in group, else false.
 *  @error                  Invalid client index, client not in game, or client bot.
 */
native bool SWGM_InGroupOfficer(int iClient);

/**
 *  Return player status.
 *
 *  @param iClient          Player index.
 *  @return                 Status.
 *  @error                  Invalid client index, client not in game, or client bot.
 */
native Status SWGM_GetPlayerStatus(int iClient);

/**
 *  Check specific player.
 *
 *  @param iClient          Player index.
 *  @error                  Invalid client index, client not in game, or client bot.
 *  @noreturn
 */
native void SWGM_CheckPlayer(int iClient);

/**
 *  Check all players.
 *
 *  @noreturn
 */
native void SWGM_CheckPlayers();

public SharedPlugin __pl_SWGM= 
{
	name = "SWGM",
	file = "nd_swgm.smx",
	required = 0
};

public __pl_SWGM_SetNTVOptional()
{
	MarkNativeAsOptional("SWGM_InGroup");
	MarkNativeAsOptional("SWGM_InGroupOfficer");
	MarkNativeAsOptional("SWGM_GetPlayerStatus");
	MarkNativeAsOptional("SWGM_CheckPlayer");
	MarkNativeAsOptional("SWGM_CheckPlayers");
}
