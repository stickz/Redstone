#if defined _nd_balancer_included
  #endinput
#endif
#define _nd_balancer_included

/**
 * Called when the team balancer places someone onto a team
 */
forward void TB_OnTeamPlacement(int client, int team);
