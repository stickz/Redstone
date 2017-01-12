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
	author = "AlliedModders LLC, Stickz",
	description = "Automated Map Voting",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

/* Plugin ConVars */
ConVar g_Cvar_NoVoteMode;
ConVar g_Cvar_VoteDuration;
ConVar g_Cvar_RunOff;
ConVar g_Cvar_RunOffPercent;

Handle g_RetryTimer = INVALID_HANDLE;

/* Data Handles */
Menu g_VoteMenu;

bool g_HasVoteStarted;
bool g_WaitingForVote;
bool g_MapVoteCompleted;
bool g_ChangeMapAtRoundEnd;
bool g_ChangeMapInProgress;

new MapChange:g_ChangeTime;

Handle g_MapVoteStartedForward = null;

public void OnPluginStart()
{
	LoadTranslations("mapchooser.phrases");
	LoadTranslations("common.phrases");
	
	g_Cvar_NoVoteMode 	= CreateConVar("sm_mapvote_novote", "1", "Specifies whether or not MapChooser should pick a map if no votes are received.", _, true, 0.0, true, 1.0);
	g_Cvar_VoteDuration 	= CreateConVar("sm_mapvote_voteduration", "20", "Specifies how long the mapvote should be available for.", _, true, 5.0);
	g_Cvar_RunOff 		= CreateConVar("sm_mapvote_runoff", "0", "Hold run of votes if winning choice is less than a certain margin", _, true, 0.0, true, 1.0);
	g_Cvar_RunOffPercent 	= CreateConVar("sm_mapvote_runoffpercent", "50", "If winning choice has less than this percent of votes, hold a runoff", _, true, 0.0, true, 100.0);
	
	RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");

	AutoExecConfig(true, "mapchooser");	

	g_MapVoteStartedForward = CreateGlobalForward("OnMapVoteStarted", ET_Ignore);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("mapchooser");	
	
	CreateNative("InitiateMapChooserVote", Native_InitiateVote);
	CreateNative("CanMapChooserStartVote", Native_CanVoteStart);
	CreateNative("HasEndOfMapVoteFinished", Native_CheckVoteDone);

	return APLRes_Success;
}

public void OnConfigsExecuted() {
	g_MapVoteCompleted = false;
}

public void OnMapEnd()
{
	g_HasVoteStarted = false;
	g_WaitingForVote = false;
	g_ChangeMapAtRoundEnd = false;
	g_ChangeMapInProgress = false;
	
	g_RetryTimer = null;
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

public Action Timer_StartMapVote(Handle timer, Handle data)
{
	g_WaitingForVote = false;
	g_RetryTimer = null;
	
	if (!GetArraySize(g_MapList) || g_MapVoteCompleted || g_HasVoteStarted)
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

	/* No input given - Don't do anything */
	if (inputlist == null)
		return;

	else //We were given a list of maps to start the vote with
	{
		char map[PLATFORM_MAX_PATH];
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

bool CanVoteStart() {
	return !(g_WaitingForVote || g_HasVoteStarted);
}

/* native InitiateMapChooserVote(); */
public Native_InitiateVote(Handle plugin, int numParams)
{
	new MapChange:when = MapChange:GetNativeCell(1);
	new Handle:inputarray = Handle:GetNativeCell(2);
	
	LogAction(-1, -1, "Starting map vote because outside request");
	InitiateVote(when, inputarray);
}

public Native_CanVoteStart(Handle plugin, int numParams) {
	return CanVoteStart();	
}

public Native_CheckVoteDone(Handle plugin, int numParams) {
	return g_MapVoteCompleted;
}
