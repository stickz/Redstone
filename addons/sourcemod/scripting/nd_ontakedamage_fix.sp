#include <sourcemod>
#include <sdktools>
#include <nd_commander>

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_BlockGizmo, EventHookMode_Pre);
	HookEvent("player_spawn", Event_BlockGizmo, EventHookMode_Pre);
	HookEvent("structure_damage_sparse", Event_StructDamageSparse, EventHookMode_Pre);
	
	AddCommandListener(CommandListener:CMD_JoinClass, "joinclass");	
	AddCommandListener(CommandListener:CMD_JoinSquad, "joinsquad");
}

public Action:Event_BlockGizmo(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CheckGizmoReset(GetClientOfUserId(GetEventInt(event, "userid")));	
	return Plugin_Continue;
}

public Action:Event_StructDamageSparse(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	if (NDC_IsCommander(client) && HasGizmo(client))
		CheckGizmoReset(client);
		
	return Plugin_Continue;
}

public Action:CMD_JoinClass(client, args)
{
	CheckGizmoReset(client);	
	return Plugin_Continue;
}

public Action:CMD_JoinSquad(client, args)
{
	if (NDC_IsCommander(client))
		return Plugin_Handled;
		
	return Plugin_Continue; 
}

CheckGizmoReset(client)
{
	if (NDC_IsCommander(client))
	{
		SetEntProp(client, Prop_Send, "m_iActiveGizmo", 0);
		SetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);
		
		/*new propValues[2];		
		propValues[0] = GetEntProp(client, Prop_Send, "m_iActiveGizmo", 0);
		propValues[1] =	GetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);			
		PrintToChatAll("debug: prop values 1: %d , 2: %d", propValues[0], propValues[1]);*/
	}
}

bool:HasGizmo(client)
{
	return 	GetEntProp(client, Prop_Send, "m_iActiveGizmo", 0) != 0 || 
			GetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0) != 0;
}