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

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_grenade_loop_fix/nd_grenade_loop_fix.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>

#define INVALID_USERID		0

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
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	AddUpdaterLibrary(); //auto-updater
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, TIMER_TellSoundToStopRingingEars, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);	
}

public Action TIMER_TellSoundToStopRingingEars(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid)
	if (client == INVALID_USERID)
		return Plugin_Handled;
	
	FakeClientCommand(client, "dsp_player 0");	
	return Plugin_Handled;
}
