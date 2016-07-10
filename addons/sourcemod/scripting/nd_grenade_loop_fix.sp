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

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_grenade_loop_fix/nd_grenade_loop_fix.txt"
#include "updater/standard.sp"

#pragma newdecls required

#define BYE_BYE_GRENADE_LOOP 	"0"
#define INVALID_USERID		0

Handle EarRingingConVar = INVALID_HANDLE;

public Plugin myinfo =
{
	name 			= "[ND] Grenade Loop Fix",
	author 			= "Stickz",
	description 		= "Fixes an issue with grenade lopping",
	version 		= "dummy",
	url 			= "https://github.com/stickz/Redstone/"
};	

public void OnPluginStart()
{
	if ((EarRingingConVar = FindConVar("dsp_player")) == INVALID_HANDLE)
		SetFailState("client convar dsp_player not found"); 
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnPluginEnd()
{
	CloseHandle(EarRingingConVar);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, TIMER_TellSoundToStopRingingEars, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);	
}

public Action TIMER_TellSoundToStopRingingEars(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid)
	
	if (client == INVALID_USERID) //invalid userid
		return Plugin_Handled;
	
	SendConVarValue(client, EarRingingConVar, BYE_BYE_GRENADE_LOOP);	
	return Plugin_Handled;
}
