#include <sourcemod>

public Plugin:myinfo = 
{
	name 		= "[ND] Disconnect Messages",
	author 		= "stickz",
	description = "N/A",
	version 	= "1.0.1",
	url 		= "N/A"
};

public OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnected, EventHookMode_Pre);
}

public Event_PlayerDisconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:steam_id[32];
	GetEventString(event, "networkid", steam_id, sizeof(steam_id));
	
	if (strncmp(steam_id, "STEAM_", 6) == 0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));		
		
		decl String:clientName[64];
		GetClientName(client, clientName, sizeof(clientName))
		
		decl String:reason[64];
		GetEventString(event, "reason", reason, sizeof(reason));
		
		if(StrContains(reason, "timed out", false) != -1)
			PrintToChatAll("\x05%s lost connection", clientName);	
	}
}
