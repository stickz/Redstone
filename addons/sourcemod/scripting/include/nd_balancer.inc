#if defined _nd_balancer_included
  #endinput
#endif
#define _nd_balancer_included

/**
 * Called when the team difference changes
 *
 * @noreturn
 */
forward OnTeamDiffUpdated();

/**
 * Retreive the team difference on the server
 * Positive for Consort and negative for Empire
 *
 * @return the skill difference on the teams
 */
native float GetTeamDifference();

/**
 * Retreive the average skill on the server
 * Currently on a scale of 1-80 level and 80-120 enhanced skill
 *
 * @return the average skill as a float value
 */
native float GetAverageSkill();

#define GAS_AVAILBLE() (GetFeatureStatus(FeatureType_Native, "GetAverageSkill") == FeatureStatus_Available)

/**
 * Run the warmup team balancer
 *
 */
native void WB_BalanceTeams();

#define BT_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "WB_BalanceTeams") == FeatureStatus_Available)

/**
 * Refresh the team balancer cache
 *
 */
native void RefreshTBCache();

#define RTBC_AVAILIBLE() (GetFeatureStatus(FeatureType_Native, "RefreshTBCache") == FeatureStatus_Available)

public SharedPlugin:__pl_balancer =
{
	name = "nd_balance",
	file = "nd_team_balancer.smx",
	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_balancer_SetNTVOptional()
{
	MarkNativeAsOptional("GetAverageSkill");
	MarkNativeAsOptional("WB_BalanceTeams");
	MarkNativeAsOptional("RefreshTBCache");
}
#endif
