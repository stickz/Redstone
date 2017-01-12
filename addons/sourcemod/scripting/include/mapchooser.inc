#if defined _mapchooser_included_
  #endinput
#endif
#define _mapchooser_included_

/**
 * Checks if MapChooser will allow a vote
 *
 * @return			True if a vote can be held, or false if mapchooser is already holding a vote.
 */
native bool CanMapChooserStartVote();

/**
 * Initiates a MapChooser map vote
 *
 * Note: If no input array is specified mapchooser will use its internal list. This includes
 * any nominations and excluded maps (as per mapchoosers convars).
 *
 * @param when			MapChange consant of when the resulting mapchange should occur.
 * @param inputarray	ADT array list of maps to add to the vote.
 */
native InitiateMapChooserVote(MapChange:when, Handle:inputarray=INVALID_HANDLE);

/**
 * Checks if MapChooser's end of map vote has completed.
 *
 * @return			True if complete, false otherwise.
 */
native bool HasEndOfMapVoteFinished();

/**
 * Called when mapchooser starts a Map Vote.
 */
forward OnMapVoteStarted();

public SharedPlugin:__pl_mapchooser = 
{
	name = "mapchooser",
	file = "mapchooser.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_mapchooser_SetNTVOptional()
{
	MarkNativeAsOptional("CanMapChooserStartVote");
	MarkNativeAsOptional("InitiateMapChooserVote");
	MarkNativeAsOptional("HasEndOfMapVoteFinished");
}
