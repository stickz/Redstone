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
#include <nd_com_eng>
#include <nd_rounds>
#include <nd_print>
#include <nd_entities>

enum Bools
{
	enableSurrender,
	hasSurrendered
};

int voteCount[2];
bool g_Bool[Bools];
bool g_commanderVoted[2] = {false, ...};
bool g_hasVotedEmpire[MAXPLAYERS+1] = {false, ... };
bool g_hasVotedConsort[MAXPLAYERS+1] = {false, ... };
Handle SurrenderDelayTimer = INVALID_HANDLE;

ConVar cvarMinPlayers;
ConVar cvarSurrenderPercent;
ConVar cvarEarlySurrenderPer;
ConVar cvarSurrenderTimeout;
ConVar cvarLowBunkerHealth;

public Plugin myinfo =
{
	name = "[ND] Surrender Features",
	author = "Stickz",
	description = "Creates an alternative method for surrendering.",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_surrender", CMD_Surrender);
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	
	cvarMinPlayers		= CreateConVar("sm_surrender_minp", "4", "Set's the minimum number of team players required to surrender.");
	cvarSurrenderPercent 	= CreateConVar("sm_surrender_percent", "51", "Set's the percentage required to surrender.");
	cvarEarlySurrenderPer	= CreateConVar("sm_surrender_early", "80", "Set's the percentage for early surrender.");
	cvarSurrenderTimeout	= CreateConVar("sm_surrender_timeout", "8", "Set's how many minutes after round start before a team can surrender");
	cvarLowBunkerHealth	= CreateConVar("sm_surrender_bh", "10000", "Sets the min bunker health required to surrender");
	
	LoadTranslations("nd_common.phrases"); // for all chat messages
	LoadTranslations("nd_surrender.phrases"); // for all chat messages
	LoadTranslations("numbers.phrases"); // for one,two,three etc.
	
	AddUpdaterLibrary(); //add updater support
	AutoExecConfig(true, "nd_surrender"); // for plugin convars
}

public void ND_OnRoundStarted()
{
	for (int i = 0; i < 2; i++)
	{
		voteCount[i] = 0;
		g_commanderVoted[i] = false;
	}
	
	float surrenderSeconds = cvarSurrenderTimeout.FloatValue * 60;
	SurrenderDelayTimer = CreateTimer(surrenderSeconds, TIMER_surrenderDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_Bool[enableSurrender] = false;
	g_Bool[hasSurrendered] = false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		g_hasVotedEmpire[client] = false;
		g_hasVotedConsort[client] = false;
	}
}

public void ND_OnRoundEnded() {
	if (!g_Bool[enableSurrender] && SurrenderDelayTimer != INVALID_HANDLE)
		CloseHandle(SurrenderDelayTimer);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client)
	{
		if (StrContains(sArgs, "surrender", false) == 0)
		{
			callSurrender(client);		
			return Plugin_Handled;			
		}
	}
	
	return Plugin_Continue;
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

bool bunkerHealthTooLow(int team)
{
	int bunkerEnt = ND_GetTeamBunkerEntity(team);	
	return bunkerEnt != ENTITY_NOT_FOUND && ND_GetBuildingHealth(bunkerEnt) < cvarLowBunkerHealth.IntValue; 
}

void callSurrender(int client)
{
	int team = GetClientTeam(client);
	
	if (g_Bool[hasSurrendered])
		PrintMessage(client, "Team Surrendered");
	
	else if (team < 2)
		PrintMessage(client, "On Team");
	
	else if (g_hasVotedEmpire[client] || g_hasVotedConsort[client])
		PrintMessage(client, "Already Voted");

	else if (ND_RoundEnded())
		PrintMessage(client, "Round End Usage");

	else if (!ND_RoundStarted()) 
		PrintMessage(client, "Round Start Usage");
		
	else if (bunkerHealthTooLow(team))
		PrintMessage(client, "Low Bunker Health");

	else
	{			
		int teamIDX = team - 2;		
		voteCount[teamIDX]++;
		
		if (ND_IsCommander(client))
			g_commanderVoted[teamIDX] = true;
		
		switch (team)
		{
			case TEAM_CONSORT: g_hasVotedConsort[client] = true;
			case TEAM_EMPIRE: g_hasVotedEmpire[client] = true;
		}
		
		checkSurrender(team, true, client);
	}
}

void checkSurrender(int team, bool showVotes = false, int client = -1)
{
	int teamCount = RED_GetTeamCount(team);
	
	// Check if we're using the early surrender percentage requirement or not
	float surrenderPer = g_Bool[enableSurrender] ? cvarSurrenderPercent.FloatValue : cvarEarlySurrenderPer.FloatValue;
	
	float teamFloat = teamCount * (surrenderPer / 100.0);
	float minTeamFoat = cvarMinPlayers.FloatValue;

	if (teamFloat < minTeamFoat)
		teamFloat = minTeamFoat;
		
	int rTeamCount = !g_commanderVoted[team - 2] ? RoundToCeil(teamFloat) : RoundToFloor(teamFloat);
	int Remainder = rTeamCount - voteCount[team -2];

	if (Remainder <= 0)
		endGame(team);

	else if (showVotes)
		displayVotes(team, Remainder, client);
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
		if (!ND_RoundEnded() && !g_Bool[hasSurrendered])
			checkSurrender(team);
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

	char number[16];
	Format(number, sizeof(number), NumberInEnglish(Remainder));

	for (int idx = 1; idx <= MaxClients; idx++)
	{
		char transNum[16];
		Format(transNum, sizeof(transNum), "%T", number, idx);

		if (IsValidClient(idx) && GetClientTeam(idx) == team)
			PrintToChat(idx, "\x05%t", "Typed Surrender", name, transNum);
	}
}
