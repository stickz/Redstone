#include <sourcemod>

new bool:roundStarted = false;
new bool:mapStarted = false;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
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