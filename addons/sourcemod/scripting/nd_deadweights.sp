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
#include <nd_classes>
#include <nd_com_eng>
#include <nd_breakdown>

#define DEBUG 0
#define PREFIX "\x05[xG]"

//Version is auto-filled by the travis builder
public Plugin myinfo =
{
	name 		= "[ND] Dead Weights",
	author 		= "stickz",
	description 	= "Allows assigning players to exo seige kit",
    	version 	= "dummy",
    	url     	= "https://github.com/stickz/Redstone/"
}

ConVar eDeadWeights;
ArrayList pDeadWeightArray;
bool player_forced_seige[MAXPLAYERS + 1] = {false,...};
bool advancedKitsAvailable[2] = {false, ...};
	
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_deadweights/nd_deadweights.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	eDeadWeights = CreateConVar("sm_enable_deadweights", "1", "Sets wetheir to allow commanders to set their own limits.");
	
	RegAdminCmd("sm_SetPlayerSiege", CMD_SetPlayerClass, ADMFLAG_GENERIC, "!SetPlayerSeige <player>");
	RegConsoleCmd("sm_LockSeige", CMD_LockPlayerSeige, "!LockSeige <player>");
	
	HookEvent("player_changeclass", Event_SetClass, EventHookMode_Pre);
	HookEvent("player_death", Event_SetClass, EventHookMode_Post);
	HookEvent("research_complete", Event_ResearchComplete);
	
	pDeadWeightArray = new ArrayList(23);
	
	AddUpdaterLibrary(); //add updater support
	
	LoadTranslations("common.phrases"); //required for FindTarget
	LoadTranslations("nd_dead_weight.phrases");
}

public void OnMapStart()
{
	pDeadWeightArray.Clear();
	
	advancedKitsAvailable[0] = false;
	advancedKitsAvailable[1] = false;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
			ResetVars(client);
	}
}

public void OnClientAuthorized(int client)
{	
	ResetVars(client);
	
	/* retrieve client steam-id and store in array */
	decl String:gAuth[32];
	GetClientAuthId(client, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (FindStringInArray(pDeadWeightArray, gAuth) != -1)
		player_forced_seige[client] = true;	
}

public void OnClientDisconnect(client)
{
	ResetVars(client);
}

public Action CMD_LockPlayerSeige(int client, int args) 
{
	if (!eDeadWeights.BoolValue)
	{
		PrintToChat(client, "%s %t", PREFIX, "Disabled Feature"); //This feature is currently disabled.
		return Plugin_Handled;	
	}
	
	if (!IsValidClient(client))
		return Plugin_Handled; 
	
	if (args != 1) 
	{
		PrintToChat(client, "%s %t", PREFIX, "Proper Usage");
	 	return Plugin_Handled;
	}
	
	int client_team = GetClientTeam(client);
	if (client_team < 2)
		return Plugin_Handled;  

	if (!ND_IsCommander(client))
	{
		PrintToChat(client, "%s %t", PREFIX, "Only Commanders"); //Player Seige locking is available only for Commander
		return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	int target = FindTarget(client, targetArg);
	if (target == -1)
	{
		PrintToChat(client, "%s %t", PREFIX, "Cannot Find Player");
	 	return Plugin_Handled;
	}
	
	if (player_forced_seige[target])	
	{
		SeigeLockPlayer(client, target, false);
		return Plugin_Handled;	
	}
	
	/*if (!CanLockSeige(target))
	{
		PrintToChat(client, "%s %t", PREFIX, "Cannot Lock"); //This player cannot be locked seige.
		return Plugin_Handled;	
	}*/	
	
	SeigeLockPlayer(client, target, false);
	return Plugin_Handled;
}

public Action CMD_SetPlayerClass(int client, int args) 
{
	if (!IsValidClient(client))
		return Plugin_Handled; 
		
	if (args != 1) 
	{
		ReplyToCommand(client, "[xG] Usage: !SetPlayerSeige <player>"); 
	 	return Plugin_Handled;
	}
	
	// Try to find a target player
	char targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	int target = FindTarget(client, targetArg);
	if (target == -1)
	{
		PrintToChat(client, "%s %t", PREFIX, "Cannot Find Player");
	 	return Plugin_Handled;
	}
	
	SeigeLockPlayer(client, target);	
	return Plugin_Handled;
}

public Action Event_SetClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int class = event.GetInt("subclass");
	int subclass = event.GetInt("subclass");
	
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

public Action Event_ResearchComplete(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("teamid");
	int researchID = event.GetInt("researchid");
	
	#if DEBUG == 1
	decl String:message[64];
	Format(message, sizeof(message), "Research id %d complete", researchID);
	PrintToAdmins(message, "a");
	#endif

	if (researchID == RESEARCH_ADVANCED_KITS)
		advancedKitsAvailable[team - 2] = true;
	
	return Plugin_Continue;
}

bool PlayerIsSeige(int class, int subclass)
{
	return class == MAIN_CLASS_EXO && subclass == EXO_CLASS_SEIGE_KIT;	
}

/*bool CanLockSeige(int target)
{
	return true;
}*/

void SetPlayerSeige(int client)
{
	ResetClass(client, MAIN_CLASS_EXO, EXO_CLASS_SEIGE_KIT, 0);
	PrintToChat(client, "%s %t.", PREFIX, "Locked Siege");
}

void SeigeLockPlayer(int admin, int target, bool AdminUsed = true)
{
	player_forced_seige[target] = !player_forced_seige[target];
	
	/* retrieve client steam-id and store in array */
	char gAuth[32];
	GetClientAuthId(target, AuthId_Steam2, gAuth, sizeof(gAuth));
	
	if (player_forced_seige[target])
	{
		PrintToChat(admin, "%s %t.", PREFIX, "Enabled Seige Lock");
		PrintToChat(target, "%s %t.", PREFIX, AdminUsed ? "Admin Lock Enabled" : "Commander Lock Enabled");
		pDeadWeightArray.PushString(gAuth);
	}
	else
	{
		PrintToChat(admin, "%s %t.", PREFIX, "Disabled Seige Lock");
		PrintToChat(target, "%s %t.", PREFIX, AdminUsed ? "Admin Lock Disibled" : "Commander Lock Disbled");
		
		int ArrayIndex = pDeadWeightArray.FindString(gAuth);
		if (ArrayIndex != -1)
			pDeadWeightArray.Erase(ArrayIndex);		
	}
}

void ResetVars(client)
{
	player_forced_seige[client] = false;
}
