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

enum Bools
{
	enableRTV,
	hasPassedRTV
};

#define TEAM_SPEC		1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE		3

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

ConVar cvarMinPlayers;
ConVar cvarTimeWindow;
ConVar cvarPercentPass;
ConVar cvarPercentPassEx;

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
	
	LoadTranslations("nd_rockthevote.phrases");
	LoadTranslations("numbers.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	CreatePluginConvars(); // create convars
	
	// Late loading support for plugin
	if (ND_RoundStarted()) {
		StartRTVDisableTimer();
	}
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
	
	for (int client = 1; client <= MaxClients; client++) {
		g_hasVoted[client] = false;	
	}
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

void callRockTheVote(int client)
{
	if (g_Bool[hasPassedRTV])
		PrintMessage(client, "Already Passed");	

	else if (g_hasVoted[client])
		PrintMessage(client, "Already RTVed");
	
	else if (ND_RoundEnded())
		PrintMessage(client, "Round Ended");
		
	else if (!ND_RoundStarted())
		PrintMessage(client, "Round Start");

	else
	{
		voteCount++;		
		g_hasVoted[client] = true;
		checkForPass(true, client);
	}
}

void checkForPass(bool display = false, int client = -1)
{	
	// Set percentage required to pass before or after the timeout
	float passPercent = g_Bool[enableRTV] ? cvarPercentPass.FloatValue : cvarPercentPassEx.FloatValue;
	
	// Get the client count on the server. Try Redstone native first.
	int clientCount = RED_CC_AVAILABLE() ? RED_ClientCount() : ValidClientCount(); 
	
	// Calculate the number of players for pass, based on player counts
	float countFloat = clientCount * (passPercent / 100.0);

	/* Set min votes for rtv or percentage (which ever is greater) */
	int rCount = RoundToNearest(countFloat);
	int mCount = cvarMinPlayers.IntValue;
	
	// Are we are instant rtv map? If so, don't enforce min count
	int reqVotes = rCount > mCount || InstantRTVMap() ? rCount : mCount;
	
	int Remainder = reqVotes - voteCount;
		
	if (Remainder <= 0)
		prepMapChange();
		
	else if (display)
		displayVotes(Remainder, client);
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
	
	if (!CanMapChooserStartVote())
	{
		PrintToChatAll("%s %t", PREFIX, "RTV Wait"); //Pending map change due to successful rtv vote.		
		CreateTimer(1.0, Timer_DelayMapChange, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
		FiveSecondChange();
}

public Action Timer_DelayMapChange(Handle timer)
{
	if (!CanMapChooserStartVote())
		return Plugin_Continue;
			
	else
	{
		FiveSecondChange();
		return Plugin_Stop;
	}
}

void FiveSecondChange()
{
	ServerCommand("mp_roundtime 1");
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
	cvarPercentPass	= CreateConVar("sm_rtv_percent", "51", "Set's percent of players required to change the map");
	cvarPercentPassEx = CreateConVar("sm_rtv_per_after", "70", "Set's percent of players required to change the map after timeout");
	
	AutoExecConfig(true, "nd_rockthevote");
}

bool InstantRTVMap()
{
	// Specify the maps for no min player requirements to RTV
	int RTV_INSTANT_SIZE 6
	char nd_rtv_instant_maps[RTV_INSTANT_SIZE][] =
	{
		ND_CustomMaps[ND_Mars],
		ND_CustomMaps[ND_Sandbrick],
		ND_CustomMaps[ND_Nuclear],
		ND_CustomMaps[ND_Submarine],
		ND_CustomMaps[ND_Rock],
		ND_StockMaps[ND_Oilfield]
	};
	
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	
	for (int i = 0; i < RTV_INSTANT_SIZE; i++)
	{
		if (StrEqual(curMap, nd_rtv_instant_maps[i], false))
			return true;
	}

	return false;
}

/* Natives */
typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_GetRtvStatus", Native_GetRtvStatus);
	CreateNative("ND_ToogleRtvStatus", Native_ToogleRtvStatus);
	return APLRes_Success;
}

public int Native_GetRtvStatus(Handle plugin, int numParams) {
	return g_Bool[enableRTV];
}

public int Native_ToogleRtvStatus(Handle plugin, int numParams) {
	g_Bool[enableRTV] = GetNativeCell(1);
}
