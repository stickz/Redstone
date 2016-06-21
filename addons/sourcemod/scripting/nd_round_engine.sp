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
	name 		= "[ND] Round Engine",
	author 		= "Stickz",
	description 	= "LL and Proceduralization Support",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_round_engine/nd_round_engine.txt"
#include "updater/standard.sp"

bool roundStarted = false;
bool roundEnded = false;
bool mapStarted = false;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart()
{
	mapStarted = true;
}

public void OnMapEnd()
{
	roundStarted = false;
	mapStarted = false;
	roundEnded = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	roundStarted = true;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	roundStarted = false;
	roundEnded = true;
}

/* Natives */
functag NativeCall public(Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_RoundStarted", Native_GetRoundStarted);
	CreateNative("ND_RoundEnded", Native_GetRoundEnded);
	CreateNative("ND_MapStarted", Native_GetMapStarted)
	return APLRes_Success;
}

public int Native_GetRoundStarted(Handle plugin, int numParams)
{
	return _:roundStarted;
}

public int Native_GetRoundEnded(Handle plugin, int numParams)
{
	return _:roundEnded;
}

public int Native_GetMapStarted(Handle plugin, int numParams)
{
	return _:mapStarted;
}
