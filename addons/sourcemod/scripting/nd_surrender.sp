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

enum Bools
{
	enableSurrender,
	hasSurrendered
};

int voteCount[2];
int teamBunkers[2];
bool g_Bool[Bools];
bool g_hasUsedVeto[2] = {false, ...};
bool g_hasVotedEmpire[MAXPLAYERS+1] = {false, ... };
bool g_hasVotedConsort[MAXPLAYERS+1] = {false, ... };
Handle SurrenderDelayTimer = INVALID_HANDLE;

ConVar cvarMinPlayers;
ConVar cvarSurrenderPercent;
ConVar cvarSurrenderTimeout;
ConVar cvarLowBunkerHealth;

#define PREFIX "\x05[xG]"

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
	RegConsoleCmd("sm_veto", CMD_Veto);
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	
	cvarMinPlayers		= CreateConVar("sm_surrender_minp", "4", "Set's the minimum number of team players required to surrender.");
	cvarSurrenderPercent 	= CreateConVar("sm_surrender_percent", "51", "Set's the percentage required to surrender.");
	cvarSurrenderTimeout	= CreateConVar("sm_surrender_timeout", "8", "Set's how many minutes after round start before a team can surrender");
	cvarLowBunkerHealth	= CreateConVar("sm_surrender_bh", "10000", "Sets the min bunker health required to surrender");
	
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
		g_hasUsedVeto[i] = false;
		teamBunkers[i] = -1;
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
	
	CreateTimer(1.5, TIMER_SetBunkerEnts, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnRoundEnded() {
	if (!g_Bool[enableSurrender] && SurrenderDelayTimer != INVALID_HANDLE)
		CloseHandle(SurrenderDelayTimer);
}

public Action CMD_Veto(int client, int args)
{
	callVeto(client);	
	return Plugin_Handled;
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
		else if (StrContains(sArgs, "veto", false) == 0)
		{
			callVeto(client);
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

public Action TIMER_SetBunkerEnts(Handle timer) {
	setBunkerEntityIndexs();
}

bool bunkerHealthTooLow(int team) {
	return GetEntProp(teamBunkers[team-2], Prop_Send, "m_iHealth") < cvarLowBunkerHealth.IntValue; 
}

void setBunkerEntityIndexs()
{	
	// loop through all entities finding the bunkers
	int loopEntity = INVALID_ENT_REFERENCE;
	while ((loopEntity = FindEntityByClassname(loopEntity, "struct_command_bunker")) != INVALID_ENT_REFERENCE)
	{
		// cache them, so we can find their health really quick later
		int team = GetEntProp(loopEntity, Prop_Send, "m_iTeamNum") - 2;
		teamBunkers[team] = loopEntity;	
	}
}

void callSurrender(int client)
{
	int team = GetClientTeam(client);
	int teamCount = RED_GetTeamCount(team);
	
	if (teamCount < cvarMinPlayers.IntValue)
		PrintMessage(client, "Four Required");

	else if (!g_Bool[enableSurrender])
		PrintMessage(client, "Too Soon");
	
	else if (g_Bool[hasSurrendered])
		PrintMessage(client, "Team Surrendered");
	
	else if (team < 2)
		PrintMessage(client, "On Team");
	
	else if (g_hasVotedEmpire[client] || g_hasVotedConsort[client])
		PrintMessage(client, "You Surrendered");
	
	else if (ND_RoundEnded())
		PrintMessage(client, "Round Ended");
	
	else if (bunkerHealthTooLow(team))
		PrintMessage(client, "Low Bunker Health");

	else
	{			
		voteCount[team -2]++;
		
		switch (team)
		{
			case TEAM_CONSORT: g_hasVotedConsort[client] = true;
			case TEAM_EMPIRE: g_hasVotedEmpire[client] = true;
		}
		
		checkSurrender(team, teamCount, true, client);
	}
}

void checkSurrender(int team, int teamCount, bool showVotes = false, int client = -1)
{
	float teamFloat = teamCount * (cvarSurrenderPercent.FloatValue / 100.0);	
	float minTeamFoat = cvarMinPlayers.FloatValue;
			
	if (teamFloat < minTeamFoat)
		teamFloat = minTeamFoat;
		
	int rTeamCount = g_hasUsedVeto[team - 2] ? RoundToCeil(teamFloat) : RoundToFloor(teamFloat);	
	int Remainder = rTeamCount - voteCount[team -2];
		
	if (Remainder <= 0)
		endGame(team);
	
	else if (showVotes)
		displayVotes(team, Remainder, client);	
}

void callVeto(int client)
{
	if (!ND_IsCommander(client))
	{
		PrintMessage(client, "Veto Commander Only");
		return;	
	}
	
	int team = GetClientTeam(client);
	int teamIDX = team -2;
	
	if (g_hasUsedVeto[teamIDX])
		PrintMessage(client, "Veto Already Used");
		
	else if (ND_RoundEnded())
		PrintMessage(client, "Round Ended");
		
	else
	{
		g_hasUsedVeto[teamIDX] = true;
		printVetoUsed(team);	
	}
}

void printVetoUsed(int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintMessage(client, "Commander Used Veto");
		}
	}
}

void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t!", PREFIX, phrase);
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
		int teamCount = RED_GetTeamCount(team);
		if (teamCount >= cvarMinPlayers.IntValue + 1 && !ND_RoundEnded() && !g_Bool[hasSurrendered])
			checkSurrender(team, teamCount);
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
	
	char number[16]
	Format(number, sizeof(number), NumberInEnglish(Remainder));

	for (int idx = 1; idx <= MaxClients; idx++)
	{
		char transNum[16];
		Format(transNum, sizeof(transNum), "%T", number, idx);
		
		if (IsValidClient(idx) && GetClientTeam(idx) == team)
			PrintToChat(idx, "\x05%t", "Typed Surrender", name, transNum);
	}
}
