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

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_round_engine/nd_round_engine.txt"
#include "updater/standard.sp"

new bool:roundStarted = false;
new bool:mapStarted = false;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	AddUpdaterLibrary(); //auto-updater
}

public OnMapStart()
{
	mapStarted = true;
}

public OnMapEnd()
{
	roundStarted = false;
	mapStarted = false;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundStarted = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundStarted = false;
}

/* Natives */
functag NativeCall public(Handle:plugin, numParams);

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ND_RoundStarted", Native_GetRoundStarted);
	CreateNative("ND_MapStarted", Native_GetMapStarted)
	return APLRes_Success;
}

public Native_GetRoundStarted(Handle:plugin, numParams)
{
	return _:roundStarted;
}

public Native_GetMapStarted(Handle:plugin, numParams)
{
	return _:mapStarted;
}
