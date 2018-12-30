#if defined _nd_team_eng_included_
  #endinput
#endif
#define _nd_team_eng_included_

/**
 * Called when the team count changes by any plugin feature
 * 
 * @Param1 The client which triggered the change.
 * @Param2 If the client is presumed to be valid during the event.
 */
forward void ND_OnPlayerTeamChanged(int client, bool valid);
