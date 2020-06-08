/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <mapchooser>
#include <nextmap>
#include <nd_warmup>
#include <nd_mvote>

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_rockthevote/nd_rockthevote.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_rounds>
#include <nd_redstone>
#include <nd_print>
#include <nd_maps>
#include <mapchooser>

enum Bools
{
	enableRTV,
	hasPassedRTV,
	hasMapVoteStarted
};

#define RTV_COMMANDS_SIZE 	3

char nd_rtv_commands[RTV_COMMANDS_SIZE][] = 
{
	"rtv",
	"change map",
	"changemap"
};

int voteCount;	

bool g_Bool[Bools];
bool g_hasVoted[MAXPLAYERS+1] = {false, ... };
bool isInsRTVMap = false;
bool isUnpopularRTVMap = false;

ConVar cvarMinPlayers;
ConVar cvarTimeWindow;
ConVar cvarPercentPass;
ConVar cvarPercentPassEX;
ConVar cvarPercentPassAfter;
ConVar cvarPercentPassAfterEX;

public Plugin myinfo =
{
	name 		= "[ND] Rock the Vote",
	author 		= "Stickz",
	description 	= "Vote to change map on ND",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_rtv", CMD_RockTheVote);
	RegConsoleCmd("sm_changemap", CMD_RockTheVote);
	
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_rockthevote.phrases");
	LoadTranslations("numbers.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	CreatePluginConvars(); // create convars
	
	// Late loading support for plugin
	if (ND_RoundStarted()) {
		StartRTVDisableTimer();
	}
}

public void OnMapVoteStarted() {
	g_Bool[hasMapVoteStarted] = true;
}

public void ND_OnRoundStarted() {
	StartRTVDisableTimer();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client)
	{
		for (int idx = 0; idx < RTV_COMMANDS_SIZE; idx++)
		{
			if (strcmp(sArgs, nd_rtv_commands[idx], false) == 0) 
			{
				callRockTheVote(client);
				return Plugin_Handled;				
			}
		}
	}	
	return Plugin_Continue;
}

public void OnMapStart()
{
	voteCount 		= 0;
	g_Bool[enableRTV] 	= true;
	g_Bool[hasPassedRTV] 	= false;
	g_Bool[hasMapVoteStarted] = false;
	
	for (int client = 1; client <= MaxClients; client++) {
		g_hasVoted[client] = false;	
	}
	
	// Get the name of the current map
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Check if the current map can be rtv'd with a min of 1 vote
	isInsRTVMap = ND_IsInstantRTVMap(currentMap);
	
	// Check if the current map is unpopular and can be rtv'd with a lower percentage
	isUnpopularRTVMap = ND_IsUnpopularRTVMap(currentMap);
}

public Action CMD_RockTheVote(int client, int args)
{
	callRockTheVote(client);
	return Plugin_Handled;
}

public void OnClientDisconnected(int client) {
	resetValues(client);
}

public Action TIMER_DisableRTV(Handle timer) {
	g_Bool[enableRTV] = false;
}

public Action TIMER_ChangeMapNow(Handle timer)
{
	/* Change level to the next map,
	 * If next map retrieval fails, 
	 * Try to end the round asap
	 */

	char nextMap[64];
	if (GetNextMap(nextMap, sizeof(nextMap)))	
		ServerCommand("changelevel %s", nextMap);
	else
		ServerCommand("mp_roundtime 1");

	return Plugin_Handled;
}

void callRockTheVote(int client)
{
	if (g_Bool[hasPassedRTV])
		PrintMessage(client, "Already Passed");	

	else if (g_hasVoted[client])
		PrintMessage(client, "Already Voted");
	
	else if (ND_RoundEnded())
		PrintMessage(client, "Round End Usage");
		
	else if (!ND_WarmupComplete() || !ND_RoundStarted())
		PrintMessage(client, "Round Start Usage");

	else
	{
		voteCount++;		
		g_hasVoted[client] = true;
		checkForPass(true, client);
	}
}

void checkForPass(bool display = false, int client = -1)
{	
	// Get the client count and modify pass percentage if required
	int clientCount = ND_GetClientCount();
	
	// Get the pass percentage. Force higher timeout percent if clientCount <= 8.
	float passPercent = getPassPercentage(clientCount <= 8);
	
	// Get the client count on the server. Try Redstone native first.
	// Calculate the number of players for pass, based on player counts
	float countFloat = clientCount * (passPercent / 100.0);

	/* Set min votes for rtv or percentage (which ever is greater) */
	int rCount = RoundToNearest(countFloat);
	int mCount = cvarMinPlayers.IntValue;
	
	// Allow rtv to pass with 100% of the client count bellow min players
	if (mCount > clientCount)
		mCount = clientCount;
	
	// Are we are instant rtv map? If so, don't enforce min count
	int reqVotes = (rCount > mCount || isInsRTVMap) ? rCount : mCount;
	
	int Remainder = reqVotes - voteCount;
		
	if (Remainder <= 0)
		prepMapChange();
		
	else if (display)
		displayVotes(Remainder, client);
}

float getPassPercentage(bool forceTimeout)
{
	// Set percentage required to pass AFTER timeout for popular and unpopular maps
	if (!g_Bool[enableRTV] || isUnpopularRTVMap && forceTimeout)
		return isUnpopularRTVMap ? cvarPercentPassAfterEX.FloatValue : cvarPercentPassAfter.FloatValue;
	
	// Set percentage required to pass BEFORE timeout for popular and unpopular maps
	return isUnpopularRTVMap ? cvarPercentPassEX.FloatValue : cvarPercentPass.FloatValue;
}

void resetValues(int client)
{
	if (g_hasVoted[client])
	{
		g_hasVoted[client] = false;
		checkForPass();
	}
}

void prepMapChange()
{
	g_Bool[hasPassedRTV] = true;
	
	if (!g_Bool[hasMapVoteStarted])
	{
		PrintToChatAll("%s %t", PREFIX, "RTV Wait"); //Pending map change due to successful rtv vote.
		CreateTimer(0.5, Timer_StartMapVoteASAP, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	else if (!HasEndOfMapVoteFinished() && !CanMapChooserStartVote())
	{
		PrintToChatAll("%s %t", PREFIX, "RTV Wait"); //Pending map change due to successful rtv vote.		
		CreateTimer(0.5, Timer_DelayMapChange, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	else
		ChangeMap();
}

public Action Timer_StartMapVoteASAP(Handle timer)
{
	if (!ND_TriggerMapVote())
		return Plugin_Continue;
		
	else if (HasEndOfMapVoteFinished())
	{
		ChangeMap(0.5);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_DelayMapChange(Handle timer)
{
	if (!CanMapChooserStartVote())
		return Plugin_Continue;
			
	else
	{
		ChangeMap();
		return Plugin_Stop;
	}
}

void ChangeMap(float when = 4.5)
{
	ND_SimulateRoundEnd();
	CreateTimer(when, TIMER_ChangeMapNow, _, TIMER_FLAG_NO_MAPCHANGE);
	
	PrintToChatAll("%s %t", PREFIX, "RTV Changing"); //RTV Successful: Map will change in five seconds.
}

void displayVotes(int Remainder, int client)
{	
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	PrintToChatAll("\x05%t", "Typed Change Map", name, NumberInEnglish(Remainder));
}

void StartRTVDisableTimer() {
	CreateTimer((cvarTimeWindow.FloatValue * 60), TIMER_DisableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}

void CreatePluginConvars()
{
	cvarMinPlayers	= CreateConVar("sm_rtv_minp", "4", "Set's the min players to pass rtv regardless of player count.");
	cvarTimeWindow	= CreateConVar("sm_rtv_time", "8", "Set's how many minutes after round start players have to rtv");
	cvarPercentPass	= CreateConVar("sm_rtv_percent", "51", "Set's normal percent to change the map");
	cvarPercentPassEX = CreateConVar("sm_rtv_percent_ex", "40", "Set's adnormal percent to change the map");
	cvarPercentPassAfter = CreateConVar("sm_rtv_per_after", "60", "Set's normal percent to change the map after timeout");
	cvarPercentPassAfterEX = CreateConVar("sm_rtv_per_after_ex", "51", "Set's adnormal percent to change the map after timeout");
	
	AutoExecConfig(true, "nd_rockthevote");
}

/* Natives */
//typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetRtvStatus", Native_GetRtvStatus);
	CreateNative("ND_ToogleRtvStatus", Native_ToogleRtvStatus);
	
	// Make nd_warmup native optional
	MarkNativeAsOptional("ND_WarmupCompleted");
	
	return APLRes_Success;
}

public int Native_GetRtvStatus(Handle plugin, int numParams) {
	return g_Bool[enableRTV];
}

public int Native_ToogleRtvStatus(Handle plugin, int numParams) {
	g_Bool[enableRTV] = GetNativeCell(1);
}
