#if defined _nd_access_included_
  #endinput
#endif
#define _nd_access_included_

#include <nd_swgm>
#include <nd_rstart>

bool ND_HasTeamPickAccess(int client)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return false;
	}

 	if (!HasTeamPickAccess(client))
	{
		ReplyToCommand(client, "[SM] You only have team-pick access to this command!");
		return false;
	}

 	return true;
}
