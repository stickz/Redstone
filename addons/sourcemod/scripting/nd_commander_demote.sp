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

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_demote/nd_commander_demote.txt"
#include "updater/standard.sp"

#include <sourcemod>
#include <sdktools>
#include <sourcecomms>
#include <nd_stocks>
#include <autoexecconfig>

#pragma newdecls required

#include <nd_com_eng>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_print>
#include <nd_fskill>
#include <nd_com_dep>
#include <nd_struct_eng>

#define INVALID_CLIENT 0

public Plugin myinfo =
{
	name = "[ND] Commander Demote",
	author = "Stickz",
	description = "Allows demoting a commander through chat",
	version = "rebuild",
	url = "https://github.com/stickz/Redstone/"
}

int voteCount[2];
bool g_hasBeenDemoted[MAXPLAYERS+1];
bool g_hasVoted[2][MAXPLAYERS+1];

ConVar tNoBuildDemoteTime;
ConVar tNoBunkerDemoteTime;
ConVar cDemotePercentage;
ConVar cDemoteMinValue;
ConVar cDemotePercentEx;
ConVar cDemoteVetSkill;

#define DEMOTE_SCOUNT 2
char nd_demote_strings[DEMOTE_SCOUNT][] = {
	"demote",
	"mutiny"	
};

ArrayList g_DemotedSteamIdList;

public void OnPluginStart()
{
	CreatePluginConvars(); // for convars
	RegPluginCommands(); // for commands
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	AddCommandListener(view_as<CommandListener>(Command_Apply), "applyforcommander");

	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_commander_restrictions.phrases");
	
	g_DemotedSteamIdList = new ArrayList(MaxClients+1);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnClientAuthorized(int client)
{	
	/* retrieve client steam-id and check if client has been demoted */
	char gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (g_DemotedSteamIdList.FindString(gAuth) != -1)
		g_hasBeenDemoted[client] = true;	
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_commander_demote");
	
	tNoBuildDemoteTime 	= 	AutoExecConfig_CreateConVar("sm_demote_build", "150", "How long should we demote the commander, after not building anything");
	tNoBunkerDemoteTime 	= 	AutoExecConfig_CreateConVar("sm_demote_bunker", "180", "How long should we demote the commander, after not entering the bunker");
	cDemotePercentage	= 	AutoExecConfig_CreateConVar("sm_demote_percent", "51", "Specifies the percent rounded to nearest required for demotion");
	cDemotePercentEx	=	AutoExecConfig_CreateConVar("sm_demote_percentex", "60", "Specifies the percent demote a veteran commander");
	cDemoteMinValue		= 	AutoExecConfig_CreateConVar("sm_demote_vmin", "3", "Specifies the minimum number of votes required, regardless of percentage");
	cDemoteVetSkill		=	AutoExecConfig_CreateConVar("sm_demote_vet", "100", "Specifies the minimum commander skill to be a veteran");

	AutoExecConfig_EC_File();
}

void RegPluginCommands()
{
	RegConsoleCmd("sm_mutiny", CMD_Demote);
	RegConsoleCmd("sm_demote", CMD_Demote);
	
	RegConsoleCmd("sm_unmutiny", CMD_UnDemote);
	RegConsoleCmd("sm_undemote", CMD_UnDemote);
}

void resetForGameStart()
{
	for (int i = 0; i < 2; i++) {
		voteCount[i] = 0;
	}

	for (int client = 1; client <= MaxClients; client++)
	{		
		g_hasVoted[0][client] = false;
		g_hasVoted[1][client] = false;
		g_hasBeenDemoted[client] = false;		
	}
	
	g_DemotedSteamIdList.Clear();
}

public void OnMapStart() {
	ServerCommand("nd_commander_mutiny_vote_threshold 51.0");
}

public void ND_OnRoundStarted() {
	resetForGameStart();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client)
	{
		for (int i = 0; i < DEMOTE_SCOUNT; i++)
		{
			if (StrEqual(sArgs, nd_demote_strings[i], false))
			{
				callMutiny(client, GetClientTeam(client));				
				return Plugin_Handled;					
			}			
		}
	}
	
	return Plugin_Continue;
}

public void ND_OnCommanderFirstEnterChair(int client, int team) {
	CreateTimer(tNoBuildDemoteTime.FloatValue, TIMER_CheckBuildDemote, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_BothCommandersPromoted(int consort, int empire)
{
	CreateTimer(tNoBunkerDemoteTime.FloatValue, TIMER_CheckChairDemote, GetClientUserId(consort), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(tNoBunkerDemoteTime.FloatValue, TIMER_CheckChairDemote, GetClientUserId(empire), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Apply(int client, const char[] command, int argc)
{
	if (g_hasBeenDemoted[client])
	{
		PrintMessage(client, "Demotion Reapply");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action PlayerJoinTeam(int client, char[] command, int argc)
{
	resetValues(client);	
	return Plugin_Continue;
}

public Action CMD_Demote(int client, int args)
{
	callMutiny(client, GetClientTeam(client));
	return Plugin_Handled;
}

public Action CMD_UnDemote(int client, int args)
{
	//ReverseMutiny(client, GetClientTeam(client));
	PrintToChat(client, "\x05[xG] This feature is incomplete but coming soon!");
	return Plugin_Handled;
}

public void OnClientDisconnect(int client) {
	resetValues(client);
}

public Action TIMER_CheckChairDemote(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);	
	if (client == INVALID_CLIENT)
		return Plugin_Handled;
		
	if (ND_IsCommander(client))
	{
		int team = GetClientTeam(client);
		if (team > 1 && !ND_HasEnteredCommanderMode(client))
			demoteCommander(team);	
	}		
		
	return Plugin_Handled;
}

public Action TIMER_CheckBuildDemote(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);	
	if (client == INVALID_CLIENT)
		return Plugin_Handled;
		
	if (ND_IsCommander(client))
	{
		int team = GetClientTeam(client);
		if (team > 1 && !ND_TeamPlacedStructure(team, true))
			demoteCommander(team);	
	}		
		
	return Plugin_Handled;
}


public Action ND_OnCommanderResigned(int client, int team)
{
	resetVotes(team);
	return Plugin_Continue;
}

public Action ND_OnCommanderMutiny(int client, int commander, int team)
{
	callMutiny(client, team);	
	return Plugin_Handled;
}

void callMutiny(int client, int team)
{
	int teamIDX = team - 2;
	int com = ND_GetCommanderOnTeam(team);
	
	if (com == -1) //The team you're trying to demote has no commander
		PrintMessage(client, "No Commander");
	
	else if (CheckCommandAccess(com, "mutiny_immunity", ADMFLAG_GENERIC, true))
		return; //Server adminisators can't be demoted, to prevent conflicts of interest with moderation
	
	else if (team < 2)
		PrintMessage(client, "On Team"); //You must be on a team, to vote commander demote
		
	else if (g_hasVoted[teamIDX][client])
		PrintMessage(client, "Already Voted"); //You've already voted to demote the commander
	
	else if (ND_RoundEnded())
		PrintMessage(client, "Round End Usage"); //You cannot demote after the round has ended
	
	else if (!ND_RoundStarted())
		PrintMessage(client, "Round Start Usage"); //You cannot demote before the round has started
	
	else if (g_hasBeenDemoted[client] && voteCount[teamIDX] == 0)
		PrintMessage(client, "Demote First"); //You cannot cast the first demote vote after demotion
		
	#if defined _sourcecomms_included
	else if (IsSourceCommSilenced(client) && voteCount[teamIDX] == 0)
		PrintMessage(client, "Silence First"); //You cannot cast the first demote vote while silenced
	#endif
	
	else
		castDemoteVote(team, teamIDX, client, com); //Cast the vote to demote the commander
}

void castDemoteVote(int team, int teamIDX, int client, int commander)
{
	voteCount[teamIDX]++;
		
	/* Get the number of votes required for demote, and round to nereast */
	int minPercent = IncreaseDemotePercent(commander) ? cDemotePercentEx.IntValue : cDemotePercentage.IntValue;			 
	int demotePercent = RoundToNearest(float(RED_GetTeamCount(team)) * float(minPercent / 100.0));
	
	/* Enforce a minium number of votes required for demote, regardless of percent */
	int minDemoteCount = cDemoteMinValue.IntValue;
	int demoteCount = minDemoteCount > demotePercent ? minDemoteCount : demotePercent;

	/* Get the remainder of votes needed to demote the commander */
	int Remainder = demoteCount - voteCount[teamIDX];
		
	if (Remainder <= 0)
		demoteCommander(team);
	else
		displayVotes(team, Remainder, client);
			
	g_hasVoted[teamIDX][client] = true;
}

bool IncreaseDemotePercent(int commander) {
	return ND_GetCommanderSkill(commander) > cDemoteVetSkill.IntValue && !ND_IsCommanderDeprioritised(commander);
}

void demoteCommander(int team)
{	
	int commander = ND_GetTeamCommander(team);

	if (commander != NO_COMMANDER)
	{
		/* Demote the commadner */
		FakeClientCommand(commander, "startmutiny");
		FakeClientCommand(commander, "rtsview");
		
		/* Store for mutiny restrictions */
		g_hasBeenDemoted[commander] = true;
		
		/* Push SteamID to ArrayList in-case of disconnect */
		char gAuth[32];
		GetClientAuthId(commander, AuthId_Steam2, gAuth, sizeof(gAuth));
		g_DemotedSteamIdList.PushString(gAuth);
						
		/* Let the team know the demote was succesful */
		PrintCommanderDemoted(team);
	}
}

void PrintCommanderDemoted(int team)
{
	for (int client = 0; client <= MAXPLAYERS; client++)
	{
		if (RED_IsValidClient(client) && GetClientTeam(client) == team)
		{
			PrintMessage(client, "Commander Demoted");
		}
	}
}

void resetValues(int client)
{	
	for (int team = 0; team < 2; team++)
	{
		if (g_hasVoted[team][client])
		{
			g_hasVoted[team][client] = false;
			voteCount[team]--;
		}
	}
	
	g_hasBeenDemoted[client] = false;
}

void resetVotes(int team)
{
	int teamIDX = team - 2;
	
	for (int client = 0; client <= MAXPLAYERS; client++) {
		g_hasVoted[teamIDX][client] = false;			
	}
	
	voteCount[teamIDX] = 0;
}

void displayVotes(int team, int remainder, int client)
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (RED_IsValidClient(idx) && GetClientTeam(idx) == team)
			PrintToChat(idx, "\x05 %t", "Demote Vote", name, remainder);
	}
}
