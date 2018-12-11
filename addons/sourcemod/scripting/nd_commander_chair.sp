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
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_chair/nd_commander_chair.txt"
#include "updater/standard.sp"

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <autoexecconfig>

#pragma newdecls required

#include <nd_com_eng>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_print>

public Plugin myinfo =
{
	name = "[ND] Commander Chair",
	author = "Stickz",
	description = "Blocks entering chair until both team gets a commander",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

ConVar cvarMinTeam;
ConVar cvarMinTotal;
ConVar cvarMaxTime;
ConVar cvarSelectMin;
ConVar cvarSelectMax;

bool ChairWaitTimeElapsed = false;

Handle BunkerDelayTimer = INVALID_HANDLE;

public void OnPluginStart()
{
	CreatePluginConvars(); // for convars	

	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_commander_chair.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	// If the plugin loads late, disable the chair waiting
	ChairWaitTimeElapsed = ND_RoundStarted();
}

public void ND_OnPreRoundStart()
{
	// If we have enough players, set commander selection time to min; otherwise, set it to max.
	int selectTime = RED_OnTeamCount() >= cvarMinPlys.IntValue ? cvarSelectMin.IntValue : cvarSelectMax.IntValue;
	ServerCommand("sm_cvar nd_commander_election_time %d", selectTime);
}

public void ND_OnRoundStarted() 
{
	ChairWaitTimeElapsed = false;
	BunkerDelayTimer = CreateTimer(cvarMaxTime.FloatValue, TIMER_EnterChairDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void ND_OnRoundEnded() 
{
	if (BunkerDelayTimer != INVALID_HANDLE && IsValidHandle(BunkerDelayTimer))
		CloseHandle(BunkerDelayTimer);
}

public void ND_BothCommandersPromoted(int consort, int empire)
{
	// Show early chair unlock message
	if (!ChairWaitTimeElapsed)
		PrintMessageAll("Chair Unlocked");
}

public Action TIMER_EnterChairDelay(Handle timer) 
{
	ChairWaitTimeElapsed = true;
	
	// Show chair lock expire message, if commanders aren't selected in-time
	if (!ND_InitialCommandersReady(true))
		PrintMessageAll("Wait Enter Expired");
}

public Action ND_OnCommanderEnterChair(int client, int team)
{	
	if (!ChairWaitTimeElapsed && ChairBlockThresholdReached() && !ND_InitialCommandersReady(true))
	{
		PrintMessage(client, "Wait Enter Chair");
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

bool ChairBlockThresholdReached()
{
	return 	RED_OnTeamCount() >= cvarMinTeam.IntValue || 
		ND_GetClientCount() >= cvarMinTotal.IntValue;
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_commander_chair");
	
	cvarMinTeam		=	AutoExecConfig_CreateConVar("sm_chair_block_team", "8", "Min number of players on a team required to block the command chair");
	cvarMinTotal		=	AutoExecConfig_CreateConVar("sm_chair_block_total", "12", "Min number of total players required to block the command chair");
	cvarMaxTime		= 	AutoExecConfig_CreateConVar("sm_chair_max", "120", "How long should we block chair if nobody applies for commander?");
	cvarSelectMin		=	AutoExecConfig_CreateConVar("sm_chair_select_min", "15", "Duration to wait to select commanders, with chair blocking");
	cvarSelectMax		=	AutoExecConfig_CreateConVar("sm_chair_select_max", "30", "Duration to wait to select commanders, without chair blocks");
	
	AutoExecConfig_EC_File();
}
