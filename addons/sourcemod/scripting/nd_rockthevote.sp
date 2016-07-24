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

#include <sourcemod>
#include <mapchooser>
#include <nd_stocks>

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_rockthevote/nd_rockthevote.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <nd_rounds>
#include <nd_redstone>

enum Bools
{
	enableRTV,
	hasPassedRTV
};

#define TEAM_SPEC		1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE		3

#define RTV_MAX_PLAYERS 	8
#define RTV_COMMANDS_SIZE 	3

#define PREFIX "\x05[xG]"

const char nd_rtv_commands[RTV_COMMANDS_SIZE][] = 
{
	"rtv",
	"change map",
	"changemap"
};

int voteCount;	
bool g_Bool[Bools];
bool g_hasVoted[MAXPLAYERS+1] = {false, ... };
Handle RtvDisableTimer = INVALID_HANDLE;

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
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_rockthevote.phrases");
	LoadTranslations("numbers.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	if (ND_RoundStarted()) 
	{
		StartRTVDisableTimer();
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
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
				//new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
				//SetCmdReplySource(old);
				
				callRockTheVote(client);
				return Plugin_Handled;				
			}
		}
	}	
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Bool[enableRTV] && RtvDisableTimer != INVALID_HANDLE)
		CloseHandle(RtvDisableTimer);
}

public void OnMapStart()
{
	voteCount 		= 0;
	g_Bool[enableRTV] 	= true;
	g_Bool[hasPassedRTV] 	= false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		g_hasVoted[client] = false;	
	}
}

public Action CMD_RockTheVote(int client, int args)
{
	callRockTheVote(client);
	return Plugin_Handled;
}

public void OnClientDisconnected(int client)
{
	resetValues(client);
}

public Action TIMER_DisableRTV(Handle timer)
{
	g_Bool[enableRTV] = false;
}

void callRockTheVote(int client)
{
	int clientCount = RED_CC_AVAILABLE() ? RED_ClientCount() : ValidClientCount(); 
	
	if (!g_Bool[enableRTV])
	{
		if (clientCount > RTV_MAX_PLAYERS)
			PrintToChat(client, "%s %t", PREFIX, "Too Late");
	}
	
	else if (g_Bool[hasPassedRTV])
		PrintToChat(client, "%s %t!", PREFIX, "Already Passed");	

	else if (g_hasVoted[client])
		PrintToChat(client, "%s %t!", PREFIX, "Already RTVed");
	
	else if (ND_RoundEnded())
		PrintToChat(client, "%s %t!", PREFIX, "Round Ended");
		
	else if (!ND_RoundStarted())
		PrintToChat(client, "%s %t!", PREFIX, "Round Start");

	else
	{
		voteCount++;		
		g_hasVoted[client] = true;
		
		checkForPass(clientCount, true, client);
	}
}

void checkForPass(int clientCount, bool display = false, int client = -1)
{
	float countFloat = clientCount * 0.51;
	int Remainder = RoundToNearest(countFloat) - voteCount;
		
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
		checkForPass(ValidClientCount(true));
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

void StartRTVDisableTimer()
{
	RtvDisableTimer = CreateTimer(480.0, TIMER_DisableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}
