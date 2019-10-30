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

int curRoundCount = 1;

bool roundStarted = false;
bool roundStartedThisMap = false;
bool roundCanBeRestarted = false;
bool roundRestartPending = false;
bool roundShowRestartMsg = false;
bool roundEnded = false;
bool mapStarted = false;

Handle g_OnRoundStartedForward;
Handle g_OnRoundStartEXForward;
Handle g_OnRoundEndedForward;
Handle g_OnRoundEndedEXForward;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	g_OnRoundStartedForward = CreateGlobalForward("ND_OnRoundStarted", ET_Ignore);
	g_OnRoundStartEXForward = CreateGlobalForward("ND_OnPreRoundStart", ET_Ignore);
	g_OnRoundEndedForward = CreateGlobalForward("ND_OnRoundEnded", ET_Ignore);
	g_OnRoundEndedEXForward = CreateGlobalForward("ND_OnRoundEndedEX", ET_Ignore);
	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapStart() 
{
	mapStarted = true;
	curRoundCount = 1;
	ServerCommand("mp_maxrounds 1"); // Reset max rounds to 1
}

public void OnMapEnd()
{
	roundStarted = false;
	roundStartedThisMap = false;
	roundRestartPending = false;
	roundShowRestartMsg = false;
	mapStarted = false;
	roundEnded = false;
}

void DelayRoundRestart()
{
	roundCanBeRestarted = false;
	CreateTimer(60.0, TIMER_RoundRestartAvailible, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_RoundRestartAvailible(Handle timer)
{
	roundCanBeRestarted = true;
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	DelayRoundRestart();
	
	if (roundShowRestartMsg)
	{
		roundShowRestartMsg = false;
		PrintToChatAll("\x05The round has succesfully restarted!");
	}
	
	roundEnded = false;
	roundRestartPending = false;
	
	roundStarted = true;
	roundStartedThisMap = true;

	Action dummy;
	Call_StartForward(g_OnRoundStartedForward);
	Call_Finish(dummy);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	roundStarted = false;
	roundEnded = true;
	
	Action dummy;
	Call_StartForward(g_OnRoundEndedForward);
	Call_Finish(dummy);
	
	if (roundStartedThisMap)
	{
		Call_StartForward(g_OnRoundEndedEXForward);
		Call_Finish(dummy);
	}		
}

/* Natives */
//functag NativeCall public(Handle plugin, int numParams);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ND_RoundStart", Native_GetRoundStarted);
	CreateNative("ND_RoundStarted", Native_GetRoundStarted);
	
	CreateNative("ND_RoundStartedThisMap", Native_GetRoundStartedEX);
	CreateNative("ND_RoundRestartable", Native_GetRoundRestartable);

	CreateNative("ND_RoundEnd", Native_GetRoundEnded);
	CreateNative("ND_RoundEnded", Native_GetRoundEnded);

	CreateNative("ND_MapStarted", Native_GetMapStarted)
	
	CreateNative("ND_PerformRoundStart", Native_FireRoundStart);
	CreateNative("ND_SimulateRoundEnd", Native_FireRoundEnd);
	CreateNative("ND_RestartRound", Native_FireRoundRestart);
	return APLRes_Success;
}

public int Native_GetRoundStarted(Handle plugin, int numParams) {
	return _:roundStarted;
}

public int Native_GetRoundStartedEX(Handle plugin, int numParams) {
	return _:roundStartedThisMap;
}

public int Native_GetRoundEnded(Handle plugin, int numParams) {
	return _:roundEnded;
}

public int Native_GetMapStarted(Handle plugin, int numParams) {
	return _:mapStarted;
}

public int Native_GetRoundRestartable(Handle plugin, int numParams) {
	return _:(roundStarted && roundCanBeRestarted && !roundRestartPending);
}

public int Native_FireRoundStart(Handle plugin, int numParams)
{
	Action dummy;
	Call_StartForward(g_OnRoundStartEXForward);
	Call_Finish(dummy);
	
	ServerCommand("mp_minplayers 1");
}

public int Native_FireRoundEnd(Handle plugin, int numParams) {
	Event_RoundEnd(null, "", false);
}

/* Round restart logic with native */
public int Native_FireRoundRestart(Handle plugin, int numParams) 
{
	if (!roundStarted) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Restart Failure: Round not started");
	}
	
	if (!roundCanBeRestarted) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Restart Failure: Started less than 60s ago");
	}
	
	if (roundRestartPending) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Restart Failure: Restart already in-progress");
	}
		
	// Get wether to return to the warmup round
	bool toWarmup = GetNativeCell(1);
	
	// Tell the engine round restart is pending
	roundRestartPending = true;
	
	// Simulate round end by sending to plugins
	Event_RoundEnd(null, "", false);
	
	// Increment the round count and increase it
	curRoundCount += 1;
	ServerCommand("mp_maxrounds %d", curRoundCount);
	
	CreateTimer(1.5, TIMER_PrepRoundRestart, toWarmup, TIMER_FLAG_NO_MAPCHANGE);
}
public Action TIMER_PrepRoundRestart(Handle timer, any toWarmup)
{	
	// End the round by sending the timelimit to 1 minute
	ServerCommand("mp_roundtime 1");
	
	// Delay the round start, so the server has time to react
	CreateTimer(1.5, TIMER_EngageRoundRestart, toWarmup, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}
public Action TIMER_EngageRoundRestart(Handle timer, any toWarmup)
{
	// Default time limit to unlimited, unless anther plugin changes it
	ServerCommand("mp_roundtime 0");
	
	// Set the round to start immediately without balancing
	if (!toWarmup)
	{
		roundShowRestartMsg = true;
		ServerCommand("mp_minplayers 1");
		PrintToChatAll("\x05The round will restart shortly!");
	}
	else
		PrintToChatAll("\x05The match will pause shortly!");	

	return Plugin_Handled;
}
