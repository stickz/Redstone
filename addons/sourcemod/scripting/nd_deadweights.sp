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
#include <nd_stocks>
#include <nd_research>

#undef REQUIRE_PLUGIN
#tryinclude <nd_balancer>
#tryinclude <nd_commander>
#tryinclude <nd_breakdown>
#define REQUIRE_PLUGIN

#define DEBUG 0
#define VERSION "1.0.3"

public Plugin:myinfo =
{
	name = "[ND] Dead Weights",
	author = "stickz",
	description = "Allows assigning players to exo seige kit",
    	version = VERSION
}

new 	Handle:eDeadWeights = INVALID_HANDLE,
	Handle:pDeadWeightArray = INVALID_HANDLE,
	bool:player_forced_seige[MAXPLAYERS + 1] = {false,...},
	bool:advancedKitsAvailable[2] = {false, ...};
	
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/master/updater/nd_deadweights/nd_deadweights.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	eDeadWeights = CreateConVar("sm_enable_deadweights", "1", "Sets wetheir to allow commanders to set their own limits.");
	
	RegAdminCmd("sm_SetPlayerSiege", CMD_SetPlayerClass, ADMFLAG_GENERIC, "!SetPlayerSeige <player>");
	RegConsoleCmd("sm_LockSeige", CMD_LockPlayerSeige, "!LockSeige <player>");
	
	HookEvent("player_changeclass", Event_SetClass, EventHookMode_Pre);
	HookEvent("player_death", Event_SetClass, EventHookMode_Post);
	HookEvent("research_complete", Event_ResearchComplete);
	
	pDeadWeightArray = CreateArray(23);
	
	AddUpdaterLibrary();
	
	LoadTranslations("nd_dead_weight.phrases");
}

public OnMapStart()
{
	ClearArray(pDeadWeightArray);
	
	advancedKitsAvailable[0] = false;
	advancedKitsAvailable[1] = false;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
			ResetVars(client);
	}
}

public OnClientAuthorized(client)
{	
	ResetVars(client);
	
	/* retrieve client steam-id and store in array */
	decl String:gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (FindStringInArray(pDeadWeightArray, gAuth) != -1)
		player_forced_seige[client] = true;	
}

public OnClientDisconnect(client)
{
	ResetVars(client);
}

public Action:CMD_LockPlayerSeige(client, args) 
{
	if (!GetConVarBool(eDeadWeights))
	{
		PrintToChat(client, "\x05[xG] %t", "Disabled Feature"); //This feature is currently disabled.
		return Plugin_Handled;	
	}
	
	if (!IsValidClient(client))
		return Plugin_Handled; 
	
	if (args != 1) 
	{
		PrintToChat(client, "/x05[xG] %t", "Proper Usage");
	 	return Plugin_Handled;
	}
	
	new client_team = GetClientTeam(client);
	if (client_team < 2)
		return Plugin_Handled;  

	if (!NDC_IsCommander(client)) 
	{
		PrintToChat(client, "\x05[xG] %t", "Only Commanders"); //Player Seige locking is available only for Commander
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	new target = FindTarget(client, targetArg);
	if (target == -1)
	{
		PrintToChat(client, "/x05[xG] %t", "Cannot Find Player");
	 	return Plugin_Handled;
	}
	
	if (player_forced_seige[target])	
	{
		SeigeLockPlayer(client, target, false);
		return Plugin_Handled;	
	}
	
	if (!CanLockSeige(target))
	{
		PrintToChat(client, "\x05[xG] %t", "Cannot Lock"); //This player cannot be locked seige.
		return Plugin_Handled;	
	}	
	
	SeigeLockPlayer(client, target, false);
	return Plugin_Handled;
}

public Action:CMD_SetPlayerClass(client, args) 
{
	if (!IsValidClient(client))
		return Plugin_Handled; 
		
	if (args != 1) 
	{
		ReplyToCommand(client, "[xG] Usage: !SetPlayerSeige <player>"); 
	 	return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	new target = FindTarget(client, targetArg);
	if (target == -1)
	{
		PrintToChat(client, "/x05[xG] %t", "Cannot Find Player");
	 	return Plugin_Handled;
	}
	
	SeigeLockPlayer(client, target);	
	return Plugin_Handled;
}

public Action:Event_SetClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEventInt(event, "subclass");
	new subclass = GetEventInt(event, "subclass");
	
	if (player_forced_seige[client])
	{
		if (advancedKitsAvailable[GetClientTeam(client) - 2])
		{
			if (!PlayerIsSeige(class, subclass))
			{
				SetPlayerSeige(client);
				return Plugin_Continue;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_ResearchComplete(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new team = GetEventInt(event, "teamid");
	new researchID = GetEventInt(event, "researchid");
	
	#if DEBUG == 1
	decl String:message[64];
	Format(message, sizeof(message), "Research id %d complete", researchID);
	PrintToAdmins(message, "a");
	#endif

	if (researchID == RESEARCH_ADVANCED_KITS)
		advancedKitsAvailable[team - 2] = true;
	
	return Plugin_Continue;
}

bool:PlayerIsSeige(class, subclass)
{
	return class == MAIN_CLASS_EXO && subclass == EXO_CLASS_SEIGE_KIT;	
}

bool:CanLockSeige(target)
{
	return true;
}

SetPlayerSeige(client)
{
	SetEntProp(client, Prop_Send, "m_iPlayerClass", MAIN_CLASS_EXO);
	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", EXO_CLASS_SEIGE_KIT);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", MAIN_CLASS_EXO);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", EXO_CLASS_SEIGE_KIT);
	SetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);

	PrintToChat(client, "\x05[xG] %t.", "Locked Siege");
}

SeigeLockPlayer(admin, target, bool:AdminUsed = true)
{
	player_forced_seige[target] = !player_forced_seige[target];
	
	/* retrieve client steam-id and store in array */
	decl String:gAuth[32];
	GetClientAuthId(target, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (player_forced_seige[target])
	{
		PrintToChat(admin, "\x05[xG] %t.", "Enabled Seige Lock");
		PrintToChat(target, "\x05[xG] %t.", AdminUsed ? "Admin Lock Enabled" : "Commander Lock Enabled");
		PushArrayString(pDeadWeightArray, gAuth);
	}
	else
	{
		PrintToChat(admin, "\x05[xG] %t.", "Disabled Seige Lock");
		PrintToChat(target, "\x05[xG] %t.", AdminUsed ? "Admin Lock Disibled" : "Commander Lock Disbled");
		
		new ArrayIndex = FindStringInArray(pDeadWeightArray, gAuth);
		if (ArrayIndex != -1)
			RemoveFromArray(pDeadWeightArray, ArrayIndex);		
	}
}

ResetVars(client)
{
	player_forced_seige[client] = false;
}
