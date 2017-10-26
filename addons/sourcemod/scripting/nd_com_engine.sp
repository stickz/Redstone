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
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_com_engine/nd_com_engine.txt"
#include "updater/standard.sp"

#include <sdktools>
#include <nd_stocks>
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo = 
{
	name 		= "[ND] Commander Engine",
	author		= "stickz",
	description 	= "Provides additional natives to be used by plugins",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"	
};

bool InCommanderMode[2] = {false, ...};
int TeamCommander[2] = {-1, ...};

Handle g_OnCommanderResignForward;
Handle g_OnCommanderMutinyForward;
Handle g_OnCommanderPromotedForward;
Handle g_OnCommanderStateChangeForward;

public void OnPluginStart()
{
	HookEvent("player_entered_commander_mode", Event_CommanderModeEnter);
	HookEvent("player_left_commander_mode", Event_CommanderModeLeft);
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	g_OnCommanderResignForward = CreateGlobalForward("ND_OnCommanderResigned", ET_Event, Param_Cell, Param_Cell);
	g_OnCommanderMutinyForward = CreateGlobalForward("ND_OnCommanderMutiny", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_OnCommanderPromotedForward = CreateGlobalForward("ND_OnCommanderPromoted", ET_Ignore, Param_Cell, Param_Cell);
	g_OnCommanderStateChangeForward = CreateGlobalForward("ND_OnCommanderStateChanged", ET_Ignore, Param_Cell);
	
	AddCommandListener(startmutiny, "startmutiny");
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Event_CommanderModeEnter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	InCommanderMode[team - 2] = true;
	CommanderStateChangeForward(team);
	return Plugin_Continue;
}

public Action Event_CommanderModeLeft(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	if (team-2 > 0) 
	{	
		InCommanderMode[team-2] = false;
		CommanderStateChangeForward(team);	
	}
	
	return Plugin_Continue;
}

public Action Event_CommanderPromo(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("teamid");
	TeamCommander[team-2] = client;
	
	/* Fire a forward when a commander is promoted */
	Action dummy;
	Call_StartForward(g_OnCommanderPromotedForward);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_Finish(dummy);
	
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 2; i++)
	{
		InCommanderMode[i] = false;
		TeamCommander[i] = -1;	
	}
}

public Action startmutiny(int client, const char[] command, int argc)
{
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;
	
	int team = GetClientTeam(client);
	if (team < 2) //team != TEAM_CONSORT && team != TEAM_EMPIRE
		return Plugin_Continue;
		
	int teamIDX = team - 2;	
	if (TeamCommander[teamIDX] == -1)
		return Plugin_Continue;

	if (TeamCommander[teamIDX] == client) // When the commander resigns
	{
		/* Push a commander resigned forward for other plugins */
		Action blockResign;
		Call_StartForward(g_OnCommanderResignForward);
		Call_PushCell(client);
		Call_PushCell(team);
		
		/* Does the plugin want to block the commander from resigning? */
		Call_Finish(blockResign);
		
		if (blockResign == Plugin_Continue)
			TeamCommander[teamIDX] = -1; // Mark on the engine the commander resigned

		return blockResign;
	}
	
	/* Push a commander mutiny forward for other plugins */
	Action blockMutiny;
	Call_StartForward(g_OnCommanderMutinyForward);
	Call_PushCell(client);
	Call_PushCell(TeamCommander[teamIDX]);
	Call_PushCell(team);
	
	/* Does the plugin want to block the commander munity */
	Call_Finish(blockMutiny);	
	return blockMutiny;
}

void CommanderStateChangeForward(int team)
{
	Action dummy;
	Call_StartForward(g_OnCommanderStateChangeForward);
	Call_PushCell(team);
	Call_Finish(dummy);
}

/* Natives */
typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsInCommanderMode", Native_InCommanderMode);
	CreateNative("ND_GetTeamCommander", Native_GetTeamCommander);
	CreateNative("ND_IsCommanderClient", Native_IsCommanderClient);
	return APLRes_Success;
}

public int Native_InCommanderMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int team = GetClientTeam(client) - 2;
	
	return team > 0 && InCommanderMode[team];
}

public int Native_GetTeamCommander(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	return TeamCommander[team - 2];
}

/* 
 * This can also be done with a stock function, 
 * but less abstraction will be present for future purpases,
 * what if a team can have two commanders in the future?
 */
public int Native_IsCommanderClient(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return TeamCommander[0] == client || TeamCommander[1] == client;
}
