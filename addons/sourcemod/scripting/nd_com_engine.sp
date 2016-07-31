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

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_com_engine/nd_com_engine.txt"
#include "updater/standard.sp"

bool InCommanderMode[2] = {false, ...};

public void OnPluginStart()
{
	HookEvent("player_entered_commander_mode", Event_CommanderModeEnter);
	HookEvent("player_left_commander_mode", Event_CommanderModeLeft);
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Event_CommanderModeEnter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	InCommanderMode[GetClientTeam(client) - 2] = true;	
	return Plugin_Continue;
}

public Action Event_CommanderModeLeft(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	InCommanderMode[GetClientTeam(client) - 2] = false;	
	return Plugin_Continue;
}


/* Natives */
typedef NativeCall = function int (Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_IsInCommanderMode", Native_InCommanderMode);
	return APLRes_Success;
}

public int Native_InCommanderMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return InCommanderMode[GetClientTeam(client) - 2];
}
