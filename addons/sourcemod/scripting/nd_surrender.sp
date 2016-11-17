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

#include <sdktools>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_surrender/nd_surrender.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_redstone>

enum Bools
{
	enableSurrender,
	hasSurrendered,
	roundHasEnded
};

int voteCount[2];
bool g_Bool[Bools];
bool g_hasVotedEmpire[MAXPLAYERS+1] = {false, ... };
bool g_hasVotedConsort[MAXPLAYERS+1] = {false, ... };
Handle SurrenderDelayTimer = INVALID_HANDLE;

#define TEAM_SPEC			1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE			3

#define SURRENDER_MIN_PLAYERS 4

#define VERSION "1.1.4"

public Plugin myinfo =
{
	name = "Surrender Feature",	author = "Stickz",
	description = "Allow alternative methods of surrendering.",
	version = VERSION,
	url = "N/A"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_surrender", CMD_Surrender);
	AddCommandListener(PlayerJoinTeam, "jointeam");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundDone, EventHookMode_PostNoCopy);
	HookEvent("timeleft_5s", Event_RoundDone, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_surrender.phrases"); //for all chat messages
	LoadTranslations("numbers.phrases"); //for one,two,three etc.
	
	AddUpdaterLibrary(); //add updater support
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	voteCount[0] = 0;
	voteCount[1] = 0;
	
	//if (SurrenderDelayTimer != INVALID_HANDLE)
	//	CloseHandle(SurrenderDelayTimer);

	SurrenderDelayTimer = CreateTimer(480.0, TIMER_surrenderDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_Bool[enableSurrender] = false;
	g_Bool[hasSurrendered] = false;
	g_Bool[roundHasEnded] = false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		g_hasVotedEmpire[client] = false;
		g_hasVotedConsort[client] = false;	
	}
}

public Action Event_RoundDone(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Bool[roundHasEnded])
		roundEnd();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && StrContains(sArgs, "surrender", false) == 0)
	{
		callSurrender(client);		
		return Plugin_Handled;			
	}	
	
	return Plugin_Continue;
}

void roundEnd()
{
	if (!g_Bool[roundHasEnded])
	{
		if (!g_Bool[enableSurrender] && SurrenderDelayTimer != INVALID_HANDLE)
			CloseHandle(SurrenderDelayTimer);

		g_Bool[roundHasEnded] = true;
	}
}

public Action PlayerJoinTeam(int client, char[] command, int argc)
{
	resetValues(client);	
	return Plugin_Continue;
}

public Action CMD_Surrender(int client, int args)
{
	callSurrender(client);
	return Plugin_Handled;
}

public void OnClientDisconnect(int client) {
	resetValues(client);
}

public Action TIMER_surrenderDelay(Handle timer) {
	g_Bool[enableSurrender] = true;
}

public Action TIMER_DisplaySurrender(Handle timer, any team)
{
	switch (team)
	{
		case TEAM_CONSORT: PrintToChatAll("\x05%t!", "Consort Surrendered");
		case TEAM_EMPIRE: PrintToChatAll("\x05%t!", "Empire Surrendered");	
	}
}

void callSurrender(int client)
{
	int team = GetClientTeam(client);
	int teamCount = RED_GetTeamCount(team);
	
	if (teamCount < SURRENDER_MIN_PLAYERS)
		PrintToChat(client, "\x05[xG] %t!", "Four Required");

	else if (!g_Bool[enableSurrender])
		PrintToChat(client, "\x05[xG] %t", "Too Soon");
	
	else if (g_Bool[hasSurrendered])
		PrintToChat(client, "\x05[xG] %t!", "Team Surrendered");
	
	else if (team < 2)
		PrintToChat(client, "\x05[xG] %t!", "On Team");
	
	else if (g_hasVotedEmpire[client] || g_hasVotedConsort[client])
		PrintToChat(client, "\x05[xG] %t!", "You Surrendered");
	
	else if (g_Bool[roundHasEnded])
		PrintToChat(client, "\x05[xG] %t!", "Round Ended");

	else
	{
		int teamIDX = team -2;
		float teamFloat = teamCount * 0.51;
			
		if (teamFloat < 4.0)
			teamFloat = 4.0;
			
		voteCount[teamIDX]++;		
		
		int Remainder = RoundToCeil(teamFloat) - voteCount[teamIDX];
		
		if (Remainder <= 0)
			endGame(team);
		else
			displayVotes(team, Remainder, client);
		
		switch (team)
		{
			case TEAM_CONSORT: g_hasVotedConsort[client] = true;
			case TEAM_EMPIRE: g_hasVotedEmpire[client] = true;
		}
	}
}

void checkQuitSurrender(int team)
{
	float teamFloat = ValidTeamCount(team) * 0.51;
		
	int Remainder = RoundToCeil(teamFloat) - voteCount[team -2];
		
	if (Remainder <= 0)
		endGame(team);
}

void resetValues(int client)
{
	int team;
	
	if (g_hasVotedConsort[client])
	{
		team = TEAM_CONSORT;
		g_hasVotedConsort[client] = false;
	}
	else if (g_hasVotedEmpire[client])
	{
		team = TEAM_EMPIRE;
		g_hasVotedEmpire[client] = false;
	}
	
	if (team > TEAM_SPEC)
	{
		voteCount[team - 2]--;
		if (RED_ClientCount() < SURRENDER_MIN_PLAYERS && !g_Bool[roundHasEnded] && !g_Bool[hasSurrendered])
			checkQuitSurrender(TEAM_CONSORT);
	}
}

void endGame(int team)
{
	g_Bool[hasSurrendered] = true;
	ServerCommand("mp_roundtime 1");
	
	CreateTimer(0.5, TIMER_DisplaySurrender, team, TIMER_FLAG_NO_MAPCHANGE);	
}

void displayVotes(int team, int Remainder, int client)
{	
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	char number[32];
	Format(number, sizeof(number), NumberInEnglish(Remainder));
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (IsValidClient(idx) && GetClientTeam(idx) == team)
			PrintToChat(idx, "\x05%t", "Typed Surrender", name, number);
	}
}
