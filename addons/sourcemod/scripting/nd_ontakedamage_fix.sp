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
#include <sdktools>
#include <nd_breakdown>
#include <nd_commander>

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetCommanderTeam");
	MarkNativeAsOptional("GetSniperCount");
	MarkNativeAsOptional("GetStealthCount");
	MarkNativeAsOptional("GetAntiStructureCount");
}

//This is a comment to force a plugin rebuild
//Version is auto-filled by the travis builder
public Plugin:myinfo =
{
	name 		= "[ND] Damage Fixes",
	author 		= "stickz",
	description 	= "Fixes critical issues with ND damage calculations",
    	version 	= "dummy",
    	url     	= "https://github.com/stickz/Redstone/"
}

#define NO_GIZMO 0

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_ontakedamage_fix/nd_ontakedamage_fix.txt"
#include "updater/standard.sp"

ConVar UseClassRefresh;

#define PROP_REFRESH_COUNT 4
new const String:PropRefreshName[PROP_REFRESH_COUNT][] = {
	"m_iPlayerClass",
	"m_iPlayerSubclass",
	"m_iDesiredPlayerClass",
	"m_iDesiredPlayerSubclass"
};

new String:DesiredClass[2][PROP_REFRESH_COUNT];
new bool:ClassReset[2] = { false , ...};

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

	AddCommandListener(CommandListener:CMD_JoinSquad, "joinsquad");
	
	AddUpdaterLibrary(); //for updater support
	
	UseClassRefresh = CreateConVar("sm_otdf_refresh", "0", "Use class refresh feature");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CheckGizmoReset(GetClientOfUserId(GetEventInt(event, "userid"))); // CheckGizmoReset(client)
	return Plugin_Continue;
}

public Action:Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (UseClassRefresh.BoolValue && NDC_IsCommander(client)) {
		if (!ClassReset[GetClientTeam(client) - 2])
			ResetClass(client);
		else 
			RefreshClass(client);
	}
	
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
		ResetGizmos(client);
		
		/*new propValues[2];		
		propValues[0] = GetEntProp(client, Prop_Send, "m_iActiveGizmo", 0);
		propValues[1] =	GetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);			
		PrintToChatAll("debug: prop values 1: %d , 2: %d", propValues[0], propValues[1]);*/
	}
}

ResetGizmos(client)
{
	SetEntProp(client, Prop_Send, "m_iActiveGizmo", NO_GIZMO);
	SetEntProp(client, Prop_Send, "m_iDesiredGizmo", NO_GIZMO);
}

RefreshClass(client)
{
	new tI = GetClientTeam(client) - 2;
	for (new s = 0; s < PROP_REFRESH_COUNT; s++) {
		SetEntProp(client, Prop_Send, DesiredClass[tI][s], 0);
	}

	ResetGizmos(client);
	ClassReset[tI] = false;
	
	PrintToChat(client, "\x05[xG] Your desired class has been succesfully set.");
}

ResetClass(client) 
{
	SetEntProp(client, Prop_Send, "m_iPlayerClass", MAIN_CLASS_ASSAULT);
    	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", ASSAULT_CLASS_INFANTRY);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", MAIN_CLASS_ASSAULT);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", ASSAULT_CLASS_INFANTRY);
	
	ResetGizmos(client);
	SetWantedClass(client);
	ClassReset[GetClientTeam(client) - 2] = true;
	
	PrintToChat(client, "\x05[xG] Please trigger a change class again.");
}

SetWantedClass(client) 
{
	new tI = GetClientTeam(client) - 2;
	for (new g = 0; g < PROP_REFRESH_COUNT; g++) {
		DesiredClass[tI][g] = GetEntProp(client, Prop_Send, PropRefreshName[g], 0);
	}
}
