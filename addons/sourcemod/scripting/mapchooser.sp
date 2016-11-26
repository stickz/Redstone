#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include <nextmap>

//Nuclear Dawn includes
#include <nd_redstone>
#include <nd_stocks>

public Plugin myinfo =
{
	name = "MapChooser",
	author = "AlliedModders LLC",
	description = "Automated Map Voting",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

/* Plugin ConVars */
ConVar g_Cvar_StartTime;
ConVar g_Cvar_ExcludeMaps;
ConVar g_Cvar_IncludeMaps;
ConVar g_Cvar_NoVoteMode;
ConVar g_Cvar_EndOfMapVote;
ConVar g_Cvar_VoteDuration;
ConVar g_Cvar_RunOff;
ConVar g_Cvar_RunOffPercent;

Handle g_VoteTimer = INVALID_HANDLE;
Handle g_RetryTimer = INVALID_HANDLE;

/* Data Handles */
Handle g_MapList = null;
Handle g_NominateList = null;
Handle g_NominateOwners = null;
Handle g_OldMapList = null;
Handle g_NextMapList = null;
Menu g_VoteMenu;

bool g_HasVoteStarted;
bool g_WaitingForVote;
bool g_MapVoteCompleted;
bool g_ChangeMapAtRoundEnd;
bool g_ChangeMapInProgress;
int g_mapFileSerial = -1;

new MapChange:g_ChangeTime;

Handle g_NominationsResetForward = null;
Handle g_MapVoteStartedForward = null;

public void OnPluginStart()
{
	LoadTranslations("mapchooser.phrases");
	LoadTranslations("common.phrases");
	
	int arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);
	g_NominateList = CreateArray(arraySize);
	g_NominateOwners = CreateArray(1);
	g_OldMapList = CreateArray(arraySize);
	g_NextMapList = CreateArray(arraySize);
	
	g_Cvar_EndOfMapVote = CreateConVar("sm_mapvote_endvote", "1", "Specifies if MapChooser should run an end of map vote", _, true, 0.0, true, 1.0);
	g_Cvar_StartTime = CreateConVar("sm_mapvote_start", "3.0", "Specifies when to start the vote based on time remaining.", _, true, 1.0);
	g_Cvar_ExcludeMaps = CreateConVar("sm_mapvote_exclude", "5", "Specifies how many past maps to exclude from the vote.", _, true, 0.0);
	g_Cvar_IncludeMaps = CreateConVar("sm_mapvote_include", "5", "Specifies how many maps to include in the vote.", _, true, 2.0, true, 6.0);
	g_Cvar_NoVoteMode = CreateConVar("sm_mapvote_novote", "1", "Specifies whether or not MapChooser should pick a map if no votes are received.", _, true, 0.0, true, 1.0);
	g_Cvar_VoteDuration = CreateConVar("sm_mapvote_voteduration", "20", "Specifies how long the mapvote should be available for.", _, true, 5.0);
	g_Cvar_RunOff = CreateConVar("sm_mapvote_runoff", "0", "Hold run of votes if winning choice is less than a certain margin", _, true, 0.0, true, 1.0);
	g_Cvar_RunOffPercent = CreateConVar("sm_mapvote_runoffpercent", "50", "If winning choice has less than this percent of votes, hold a runoff", _, true, 0.0, true, 100.0);
	
	RegAdminCmd("sm_mapvote", Command_Mapvote, ADMFLAG_CHANGEMAP, "sm_mapvote - Forces MapChooser to attempt to run a map vote now.");
	RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");

	AutoExecConfig(true, "mapchooser");	

	g_NominationsResetForward = CreateGlobalForward("OnNominationRemoved", ET_Ignore, Param_String, Param_Cell);
	g_MapVoteStartedForward = CreateGlobalForward("OnMapVoteStarted", ET_Ignore);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("mapchooser");	
	
	CreateNative("NominateMap", Native_NominateMap);
	CreateNative("RemoveNominationByMap", Native_RemoveNominationByMap);
	CreateNative("RemoveNominationByOwner", Native_RemoveNominationByOwner);
	CreateNative("InitiateMapChooserVote", Native_InitiateVote);
	CreateNative("CanMapChooserStartVote", Native_CanVoteStart);
	CreateNative("HasEndOfMapVoteFinished", Native_CheckVoteDone);
	CreateNative("GetExcludeMapList", Native_GetExcludeMapList);
	CreateNative("GetNominatedMapList", Native_GetNominatedMapList);
	CreateNative("EndOfMapVoteEnabled", Native_EndOfMapVoteEnabled);

	return APLRes_Success;
}

public void OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					 g_mapFileSerial, 
					 "mapchooser",
					 MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		!= null)
		
	{
		if (g_mapFileSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
	
	CreateNextVote();
	SetupTimeleftTimer();
	
	g_MapVoteCompleted = false;
	
	ClearArray(g_NominateList);
	ClearArray(g_NominateOwners);
}

public void OnMapEnd()
{
	g_HasVoteStarted = false;
	g_WaitingForVote = false;
	g_ChangeMapAtRoundEnd = false;
	g_ChangeMapInProgress = false;
	
	g_VoteTimer = null;
	g_RetryTimer = null;
	
	char map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	PushArrayString(g_OldMapList, map);
				
	if (GetArraySize(g_OldMapList) > g_Cvar_ExcludeMaps.IntValue)
		RemoveFromArray(g_OldMapList, 0);
}

public void OnClientDisconnect(int client)
{
	int index = FindValueInArray(g_NominateOwners, client);
	
	if (index == -1)
		return;
	
	char oldmap[PLATFORM_MAX_PATH];
	GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));
	Call_StartForward(g_NominationsResetForward);
	Call_PushString(oldmap);
	Call_PushCell(GetArrayCell(g_NominateOwners, index));
	Call_Finish();
	
	RemoveFromArray(g_NominateOwners, index);
	RemoveFromArray(g_NominateList, index);
}

public Action Command_SetNextmap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setnextmap <map>");
		return Plugin_Handled;
	}

	char map[PLATFORM_MAX_PATH];
	GetCmdArg(1, map, sizeof(map));

	if (!IsMapValid(map))
	{
		ReplyToCommand(client, "[SM] %t", "Map was not found", map);
		return Plugin_Handled;
	}

	ShowActivity(client, "%t", "Changed Next Map", map);
	LogAction(client, -1, "\"%L\" changed nextmap to \"%s\"", client, map);

	SetNextMap(map);
	g_MapVoteCompleted = true;

	return Plugin_Handled;
}

public void OnMapTimeLeftChanged()
{
	if (GetArraySize(g_MapList))
	{
		SetupTimeleftTimer();
	}
}

void SetupTimeleftTimer()
{
	int time;
	if (GetMapTimeLeft(time) && time > 0)
	{
		int startTime = g_Cvar_StartTime.IntValue * 60;
		if (time - startTime < 0 && g_Cvar_EndOfMapVote.BoolValue && !g_MapVoteCompleted && !g_HasVoteStarted)
			InitiateVote(MapChange_MapEnd, null);		

		else
		{
			if (g_VoteTimer != null)
			{
				KillTimer(g_VoteTimer);
				g_VoteTimer = null;
			}	
			
			//g_VoteTimer = CreateTimer(float(time - startTime), Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
			Handle data;
			g_VoteTimer = CreateDataTimer(float(time - startTime), Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(data, _:MapChange_MapEnd);
			WritePackCell(data, _:INVALID_HANDLE);
			ResetPack(data);
		}		
	}
}

public Action:Timer_StartMapVote(Handle:timer, Handle:data)
{
	if (timer == g_RetryTimer)
	{
		g_WaitingForVote = false;
		g_RetryTimer = null;
	}
	
	else
		g_VoteTimer = null;
	
	if (!GetArraySize(g_MapList) || !g_Cvar_EndOfMapVote.BoolValue || g_MapVoteCompleted || g_HasVoteStarted)
		return Plugin_Stop;
	
	new MapChange:mapChange = MapChange:ReadPackCell(data);
	new Handle:hndl = Handle:ReadPackCell(data);

	InitiateVote(mapChange, hndl);

	return Plugin_Stop;
}

/* You ask, why don't you just use team_score event? And I answer... Because CSS doesn't. */
public Event_RoundEnd(Event event, const String:name[], bool:dontBroadcast)
{
	if (g_ChangeMapAtRoundEnd)
	{
		g_ChangeMapAtRoundEnd = false;

		float delayTime = ND_GetClientCount() < 12 ? 8.0 : 16.0;		
		CreateTimer(delayTime, Timer_ChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_ChangeMapInProgress = true;
	}
	
	if (!GetArraySize(g_MapList) || g_HasVoteStarted || g_MapVoteCompleted)
		return;
}

public Action Command_Mapvote(int client, int args)
{
	InitiateVote(MapChange_MapEnd, null);
	return Plugin_Handled;	
}

/**
 * Starts a new map vote
 *
 * @param when			When the resulting map change should occur.
 * @param inputlist		Optional list of maps to use for the vote, otherwise an internal list of nominations + random maps will be used.
 * @param noSpecials	Block special vote options like extend/nochange (upgrade this to bitflags instead?)
 */
InitiateVote(MapChange:when, Handle:inputlist=null)
{
	g_WaitingForVote = true;
	
	if (IsVoteInProgress())
	{
		// Can't start a vote, try again in 5 seconds.
		//g_RetryTimer = CreateTimer(5.0, Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
		
		Handle data;
		g_RetryTimer = CreateDataTimer(5.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, _:when);
		WritePackCell(data, _:inputlist);
		ResetPack(data);
		return;
	}
	
	/* If the main map vote has completed (and chosen result) and its currently changing (not a delayed change) we block further attempts */
	if (g_MapVoteCompleted && g_ChangeMapInProgress)
		return;
	
	g_ChangeTime = when;
	
	g_WaitingForVote = false;
		
	g_HasVoteStarted = true;
	g_VoteMenu = new Menu(Handler_MapVoteMenu, MenuAction:MENU_ACTIONS_ALL);
	g_VoteMenu.SetTitle("Vote Nextmap");
	g_VoteMenu.VoteResultCallback = Handler_MapVoteFinished;

	/* Call OnMapVoteStarted() Forward */
	Call_StartForward(g_MapVoteStartedForward);
	Call_Finish();
	
	/**
	 * TODO: Make a proper decision on when to clear the nominations list.
	 * Currently it clears when used, and stays if an external list is provided.
	 * Is this the right thing to do? External lists will probably come from places
	 * like sm_mapvote from the adminmenu in the future.
	 */
	 
	char map[PLATFORM_MAX_PATH];
	
	/* No input given - User our internal nominations and maplist */
	if (inputlist == null)
	{
		int nominateCount = GetArraySize(g_NominateList);
		int voteSize = g_Cvar_IncludeMaps.IntValue;
		
		/* Smaller of the two - It should be impossible for nominations to exceed the size though (cvar changed mid-map?) */
		int nominationsToAdd = nominateCount >= voteSize ? voteSize : nominateCount;
		
		
		for (int i = 0; i < nominationsToAdd; i++)
		{
			GetArrayString(g_NominateList, i, map, sizeof(map));
			g_VoteMenu.AddItem(map, map);
			RemoveStringFromArray(g_NextMapList, map);
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();
		}
		
		/* Clear out the rest of the nominations array */
		for (int i = nominationsToAdd; i < nominateCount; i++)
		{
			GetArrayString(g_NominateList, i, map, sizeof(map));
			/* These maps shouldn't be excluded from the vote as they weren't really nominated at all */
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();			
		}
		
		/* There should currently be 'nominationsToAdd' unique maps in the vote */
		
		int i = nominationsToAdd;
		new count = 0;
		new availableMaps = GetArraySize(g_NextMapList);
		
		while (i < voteSize)
		{
			if (count >= availableMaps)
			{
				//Run out of maps, this will have to do.
				break;
			}
			
			GetArrayString(g_NextMapList, count, map, sizeof(map));
			count++;
			
			/* Insert the map and increment our count */
			g_VoteMenu.AddItem(map, map);
			i++;
		}
		
		/* Wipe out our nominations list - Nominations have already been informed of this */
		ClearArray(g_NominateOwners);
		ClearArray(g_NominateList);
	}
	else //We were given a list of maps to start the vote with
	{
		for (int i = 0; i < GetArraySize(inputlist); i++)
		{
			GetArrayString(inputlist, i, map, sizeof(map));
			
			if (IsMapValid(map))
				g_VoteMenu.AddItem(map, map);
		}
	}
	
	/* There are no maps we could vote for. Don't show anything. */
	if (g_VoteMenu.ItemCount == 0)
	{
		g_HasVoteStarted = false;
		delete g_VoteMenu;
		g_VoteMenu = null;
		return;
	}
	
	int voteDuration = g_Cvar_VoteDuration.IntValue;

	g_VoteMenu.ExitButton = false;
	g_VoteMenu.DisplayVoteToAll(voteDuration);
}

public Handler_VoteFinishedGeneric(Menu menu,
						   num_votes, 
						   num_clients,
						   const client_info[][2], 
						   num_items,
						   const item_info[][2])
{
	char map[PLATFORM_MAX_PATH];
	menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], map, sizeof(map));

	
	if (g_ChangeTime == MapChange_MapEnd)
		SetNextMap(map);

	else if (g_ChangeTime == MapChange_Instant)
	{
		Handle data;
		CreateDataTimer(2.0, Timer_ChangeMap, data);
		WritePackString(data, map);
		g_ChangeMapInProgress = false;
	}
	else // MapChange_RoundEnd
	{
		SetNextMap(map);
		g_ChangeMapAtRoundEnd = true;
	}
		
	g_HasVoteStarted = false;
	g_MapVoteCompleted = true;
}

public Handler_MapVoteFinished(Menu menu,
						   int num_votes, 
						   int num_clients,
						   const client_info[][2], 
						   int num_items,
						   const item_info[][2])
{
	if (g_Cvar_RunOff.BoolValue && num_items > 1)
	{
		float winningvotes = float(item_info[0][VOTEINFO_ITEM_VOTES]);
		float required = num_votes * (g_Cvar_RunOffPercent.FloatValue / 100.0);
		
		if (winningvotes < required)
		{
			/* Insufficient Winning margin - Lets do a runoff */
			g_VoteMenu = CreateMenu(Handler_MapVoteMenu, MenuAction:MENU_ACTIONS_ALL);
			g_VoteMenu.SetTitle("Runoff Vote Nextmap");
			SetVoteResultCallback(g_VoteMenu, Handler_VoteFinishedGeneric);

			char map[PLATFORM_MAX_PATH];
			char info1[PLATFORM_MAX_PATH];
			char info2[PLATFORM_MAX_PATH];
			
			menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], map, sizeof(map), _, info1, sizeof(info1));
			g_VoteMenu.AddItem(map, info1);
			menu.GetItem(item_info[1][VOTEINFO_ITEM_INDEX], map, sizeof(map), _, info2, sizeof(info2));
			g_VoteMenu.AddItem(map, info2);
			
			int voteDuration = g_Cvar_VoteDuration.IntValue;
			g_VoteMenu.ExitButton = false;
			g_VoteMenu.DisplayVoteToAll(voteDuration);
					
			return;
		}
	}
	
	Handler_VoteFinishedGeneric(menu, num_votes, num_clients, client_info, num_items, item_info);
}

public Handler_MapVoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			g_VoteMenu = null;
			delete menu;
		}
		
		case MenuAction_Display:
		{
	 		char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "Vote Nextmap", param1);

			Panel panel = Panel:param2;
			panel.SetTitle(buffer);
		}		
		
		case MenuAction_VoteCancel:
		{
			// If we receive 0 votes, pick at random.
			if (param1 == VoteCancel_NoVotes && g_Cvar_NoVoteMode.BoolValue)
			{
				int count = menu.ItemCount;
				char map[PLATFORM_MAX_PATH];
				menu.GetItem(0, map, sizeof(map));

				// Get a random map from the list.
				int item = GetRandomInt(0, count - 1);
				menu.GetItem(item, map, sizeof(map));					

				SetNextMap(map);
				g_MapVoteCompleted = true;
			}
			else {} // We were actually cancelled. I guess we do nothing.
			
			g_HasVoteStarted = false;
		}
	}
	
	return 0;
}

public Action Timer_ChangeMap(Handle hTimer, Handle dp)
{
	g_ChangeMapInProgress = false;
	
	char map[PLATFORM_MAX_PATH];
	
	if (dp == null)
	{
		if (!GetNextMap(map, sizeof(map)))
		{
			//No passed map and no set nextmap. fail!
			return Plugin_Stop;	
		}
	}
	else
	{
		ResetPack(dp);
		ReadPackString(dp, map, sizeof(map));		
	}
	
	ForceChangeLevel(map, "Map Vote");
	
	return Plugin_Stop;
}

bool RemoveStringFromArray(Handle array, char[] str)
{
	int index = FindStringInArray(array, str);
	if (index != -1)
	{
		RemoveFromArray(array, index);
		return true;
	}
	
	return false;
}

void CreateNextVote()
{
	ClearArray(g_NextMapList);
	
	char map[PLATFORM_MAX_PATH];
	Handle tempMaps = CloneArray(g_MapList);
	
	GetCurrentMap(map, sizeof(map));
	RemoveStringFromArray(tempMaps, map);
	
	if (g_Cvar_ExcludeMaps.IntValue && GetArraySize(tempMaps) > g_Cvar_ExcludeMaps.IntValue)
	{
		for (int i = 0; i < GetArraySize(g_OldMapList); i++)
		{
			GetArrayString(g_OldMapList, i, map, sizeof(map));
			RemoveStringFromArray(tempMaps, map);
		}	
	}

	int limit = (g_Cvar_IncludeMaps.IntValue < GetArraySize(tempMaps) ? g_Cvar_IncludeMaps.IntValue : GetArraySize(tempMaps));
	for (int i = 0; i < limit; i++)
	{
		int b = GetRandomInt(0, GetArraySize(tempMaps) - 1);
		GetArrayString(tempMaps, b, map, sizeof(map));		
		PushArrayString(g_NextMapList, map);
		RemoveFromArray(tempMaps, b);
	}
	
	delete tempMaps;
}

bool CanVoteStart() {
	return !(g_WaitingForVote || g_HasVoteStarted);
}

NominateResult:InternalNominateMap(char[] map, bool force, int owner)
{
	if (!IsMapValid(map))
		return Nominate_InvalidMap;
	
	/* Map already in the vote */
	if (FindStringInArray(g_NominateList, map) != -1)
		return Nominate_AlreadyInVote;
	
	int index;

	/* Look to replace an existing nomination by this client - Nominations made with owner = 0 aren't replaced */
	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();
		
		SetArrayString(g_NominateList, index, map);
		return Nominate_Replaced;
	}
	
	/* Too many nominated maps. */
	if (GetArraySize(g_NominateList) >= g_Cvar_IncludeMaps.IntValue && !force)
		return Nominate_VoteFull;
	
	PushArrayString(g_NominateList, map);
	PushArrayCell(g_NominateOwners, owner);
	
	while (GetArraySize(g_NominateList) > g_Cvar_IncludeMaps.IntValue)
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, 0, oldmap, sizeof(oldmap));
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(GetArrayCell(g_NominateOwners, 0));
		Call_Finish();
		
		RemoveFromArray(g_NominateList, 0);
		RemoveFromArray(g_NominateOwners, 0);
	}
	
	return Nominate_Added;
}

/* Add natives to allow nominate and initiate vote to be call */

/* native  bool:NominateMap(const char[] map, bool force, &NominateError:error); */
public Native_NominateMap(Handle plugin, int numParams)
{
	int len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
		return false;
	
	len++;
	
	char[] map = new char[len];
	GetNativeString(1, map, len);
	
	return _:InternalNominateMap(map, GetNativeCell(2), GetNativeCell(3));
}

bool InternalRemoveNominationByMap(char[] map)
{	
	for (int i = 0; i < GetArraySize(g_NominateList); i++)
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, i, oldmap, sizeof(oldmap));

		if(strcmp(map, oldmap, false) == 0)
		{
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(oldmap);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();

			RemoveFromArray(g_NominateList, i);
			RemoveFromArray(g_NominateOwners, i);

			return true;
		}
	}
	
	return false;
}

/* native  bool:RemoveNominationByMap(const String:map[]); */
public Native_RemoveNominationByMap(Handle plugin, int numParams)
{
	int len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
		return false;
	
	len++;
	
	char[] map = new char[len];
	GetNativeString(1, map, len);
	
	return _:InternalRemoveNominationByMap(map);
}

bool InternalRemoveNominationByOwner(int owner)
{	
	int index;

	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));

		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();

		RemoveFromArray(g_NominateList, index);
		RemoveFromArray(g_NominateOwners, index);

		return true;
	}
	
	return false;
}

/* native  bool:RemoveNominationByOwner(owner); */
public Native_RemoveNominationByOwner(Handle plugin, int numParams)
{	
	return _:InternalRemoveNominationByOwner(GetNativeCell(1));
}

/* native InitiateMapChooserVote(); */
public Native_InitiateVote(Handle plugin, int numParams)
{
	new MapChange:when = MapChange:GetNativeCell(1);
	new Handle:inputarray = Handle:GetNativeCell(2);
	
	LogAction(-1, -1, "Starting map vote because outside request");
	InitiateVote(when, inputarray);
}

public Native_CanVoteStart(Handle plugin, int numParams)
{
	return CanVoteStart();	
}

public Native_CheckVoteDone(Handle plugin, int numParams)
{
	return g_MapVoteCompleted;
}

public Native_EndOfMapVoteEnabled(Handle plugin, int numParams)
{
	return g_Cvar_EndOfMapVote.BoolValue;
}

public Native_GetExcludeMapList(Handle plugin, int numParams)
{
	new Handle:array = Handle:GetNativeCell(1);
	
	if (array == null)
		return;	

	int size = GetArraySize(g_OldMapList);
	char map[PLATFORM_MAX_PATH];
	
	for (int i = 0; i < size; i++)
	{
		GetArrayString(g_OldMapList, i, map, sizeof(map));
		PushArrayString(array, map);	
	}
	
	return;
}

public Native_GetNominatedMapList(Handle plugin, int numParams)
{
	new Handle:maparray = Handle:GetNativeCell(1);
	new Handle:ownerarray = Handle:GetNativeCell(2);
	
	if (maparray == null)
		return;

	char map[PLATFORM_MAX_PATH];

	for (int i = 0; i < GetArraySize(g_NominateList); i++)
	{
		GetArrayString(g_NominateList, i, map, sizeof(map));
		PushArrayString(maparray, map);

		// If the optional parameter for an owner list was passed, then we need to fill that out as well
		if(ownerarray != null)
		{
			int index = GetArrayCell(g_NominateOwners, i);
			PushArrayCell(ownerarray, index);
		}
	}

	return;
}