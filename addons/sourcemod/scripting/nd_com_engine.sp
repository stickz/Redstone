#pragma newdecls required

#include <sourcemod>

bool InCommanderMode[2] = {false, ...};

public void OnPluginStart()
{
	HookEvent("player_entered_commander_mode", Event_CommanderModeEnter);
	HookEvent("player_left_commander_mode", Event_CommanderModeLeft);
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