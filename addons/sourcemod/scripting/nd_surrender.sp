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
#include <autoexecconfig>
#include <smlib/math>

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
#include <nd_teampick>

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

/* Plugin ConVars */
ConVar cvarMinPlayers;
ConVar cvarMinComVoteVotes;
ConVar cvarMaxComVotePlys;

ConVar cvarSurrenderPercent;
ConVar cvarTPSurrenderPercent;
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
	CreatePluginConvars(); // for convars
	
	LoadTranslations("nd_common.phrases"); // for all chat messages
	LoadTranslations("nd_surrender.phrases"); // for all chat messages
	LoadTranslations("numbers.phrases"); // for one,two,three etc.
	
	AddUpdaterLibrary(); //add updater support
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_surrender");
	
	cvarMinPlayers		= 	AutoExecConfig_CreateConVar("sm_surrender_minp", "4", "Set's the minimum number of team players required to surrender.");
	cvarMinComVoteVotes	=	AutoExecConfig_CreateConVar("sm_surrender_minp_com", "5", "Specifies min vote count to always give commander two votes.");
	cvarMaxComVotePlys	=	AutoExecConfig_CreateConVar("sm_surrender_maxp_com", "4", "Specifies max team players to always give commander two votes.");
	
	cvarSurrenderPercent 	= 	AutoExecConfig_CreateConVar("sm_surrender_percent", "51", "Set's the regular percentage to surrender.");
	cvarTPSurrenderPercent 	= 	AutoExecConfig_CreateConVar("sm_surrender_percent_tp", "60", "Set's the teampick percentage to surrender.");
	cvarEarlySurrenderPer	= 	AutoExecConfig_CreateConVar("sm_surrender_early", "80", "Set's the percentage for early surrender.");
	
	cvarSurrenderTimeout	= 	AutoExecConfig_CreateConVar("sm_surrender_timeout", "8", "Set's how many minutes after round start before a team can surrender");
	cvarLowBunkerHealth	= 	AutoExecConfig_CreateConVar("sm_surrender_bh", "10000", "Sets the min bunker health required to surrender");
	
	AutoExecConfig_EC_File();
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
	
	// Set the surrender vote percentage
	int sValue = ND_TeamsPickedThisMap() ? cvarTPSurrenderPercent.IntValue : cvarSurrenderPercent.IntValue;
	ServerCommand("sm_cvar nd_commander_surrender_vote_threshold %d", sValue);	
}

public void ND_OnRoundEnded() 
{
	if (!g_Bool[enableSurrender] 	&& SurrenderDelayTimer != INVALID_HANDLE 
					&& IsValidHandle(SurrenderDelayTimer))
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

public Action TIMER_surrenderDelay(Handle timer) 
{
	g_Bool[enableSurrender] = true;
	return Plugin_Continue;
}

public Action TIMER_DisplaySurrender(Handle timer, any team)
{
	switch (team)
	{
		case TEAM_CONSORT: PrintToChatAll("\x05%t!", "Consort Surrendered");
		case TEAM_EMPIRE: PrintToChatAll("\x05%t!", "Empire Surrendered");	
	}
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_PickedTeamsThisMap");
	return APLRes_Success;
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

	// Get the team surrender percentage as a float. Clamp it to a minimum value.
	float teamFloat = Math_Min(teamCount * getSurrenderPercentage(), cvarMinPlayers.FloatValue);

	int rTeamCount = countTwoComVotes(team, teamCount, teamFloat) ? RoundToFloor(teamFloat) : RoundToCeil(teamFloat);
	int Remainder = rTeamCount - voteCount[team -2];

	if (Remainder <= 0)
		endGame(team);

	else if (showVotes)
		displayVotes(team, Remainder, client);
}

float getSurrenderPercentage()
{
	// Do we use the regular or team pick surrender vote percentage?
	float lateSurrenderPer =  ND_TeamsPickedThisMap() ? cvarTPSurrenderPercent.FloatValue : cvarSurrenderPercent.FloatValue;
	
	// Do we use the early game or late game surrender vote percentage?
	float finalSurrenderPer = g_Bool[enableSurrender] ? lateSurrenderPer : cvarEarlySurrenderPer.FloatValue;
	
	// Devide by 100 to convert percentage value to decimal
	return finalSurrenderPer / 100.0;
}

bool countTwoComVotes(int team, int teamCount, float voteCount2) 
{
	// Is the team count 4 or less? Or is the surrender vote count 5 or more? If so...
	// If the commander has voted, double the weight of their vote.
	if (	teamCount <= cvarMaxComVotePlys.IntValue || voteCount2 >= cvarMinComVoteVotes.FloatValue)
		return g_commanderVoted[team - 2];
	
	return false;
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
