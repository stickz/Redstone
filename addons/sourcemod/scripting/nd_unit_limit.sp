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
#include <nd_stocks>

#undef REQUIRE_PLUGIN
#tryinclude <nd_commander>
#define REQUIRE_PLUGIN

#define TYPE_SNIPER 	0
#define TYPE_STEALTH 	1
#define TYPE_STRUCTURE 	2

#define MIN_SNIPER_VALUE		1
#define MIN_STEALTH_LOW_VALUE 		2
#define MIN_STEALTH_HIGH_VALUE 		2
#define MIN_ANTI_STRUCTURE_VALUE	4

#define MIN_ANTI_STRUCTURE_PER 	60

#define LOW_LIMIT 	2
#define MED_LIMIT 	3
#define HIGH_LIMIT 	4

#define DEBUG 0

#define m_iDesiredPlayerClass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerClass"))
#define m_iDesiredPlayerSubclass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerSubclass"))

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_unit_limit/nd_unit_limit.txt"
#include "updater/standard.sp"

new Handle:eCommanders = INVALID_HANDLE,
	UnitLimit[2][3],
	bool:SetLimit[2][3],
	bool:roundStarted = false;

//Version is auto-filled by the travis builder
public Plugin:myinfo = 
{
	name		= "[ND] Unit Limiter",
	author 		= "stickz, yed_",
	description 	= "Limit the number of units by class type on a team",
	version		= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
}

public OnPluginStart() 
{
	eCommanders = CreateConVar("sm_allow_commander_setting", "1", "Sets wetheir to allow commanders to set their own limits.");
	
	RegAdminCmd("sm_maxsnipers_admin", CMD_ChangeSnipersLimit, ADMFLAG_GENERIC, "!maxsnipers_admin <team> <amount>");
	
	RegConsoleCmd("sm_maxsnipers", CMD_ChangeTeamSnipersLimit, "Change the maximum number of snipers in the team: !maxsnipers <amount>");
	RegConsoleCmd("sm_maxsniper", CMD_ChangeTeamSnipersLimit, "Change the maximum number of snipers in the team: !maxsnipers <amount>");
	
	RegConsoleCmd("sm_maxstealths", CMD_ChangeTeamStealthLimit, "Change the maximum number of stealth in the team: !maxsteaths <amount>");
	RegConsoleCmd("sm_maxstealth", CMD_ChangeTeamStealthLimit, "Change the maximum number of stealth in the team: !maxsteaths <amount>");
	
	RegConsoleCmd("sm_MaxAntiStructures", CMD_ChangeTeamAntiStructureLimit, "Change the maximum percent of antistrcture in the team: !MaxAntiStructure <amount>");
	RegConsoleCmd("sm_MaxAntiStructure", CMD_ChangeTeamAntiStructureLimit, "Change the maximum percent of antistrcture in the team: !MaxAntiStructure <amount>");

	HookEvent("player_changeclass", Event_SetClass, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	AddUpdaterLibrary();
	
	LoadTranslations("nd_unit_limit.phrases");
	LoadTranslations("numbers.phrases");
}

public OnMapStart() 
{
	for (new x = 0; x < 2; x++)
	{
		for (new y = 0; y < 2; y++)
		{
			UnitLimit[x][y] = -1;
			SetLimit[x][y] = false;
		}
	}
}

public OnMapEnd()
{
	roundStarted = false;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundStarted = true;
}

public Action:Event_SetClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!roundStarted)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    	new cls = GetEventInt(event, "class");
    	new subcls = GetEventInt(event, "subclass");

	if (IsSniperClass(cls, subcls)) 
	{
        	if (IsTooMuchSnipers(client)) 
		{
	            	ResetClass(client);
	            	PrintToChat(client, "\x05[xG] %t.", "Sniper Limit Reached");
	            	return Plugin_Continue;
        	}
	}
	
	else if (IsStealthClass(cls))
	{
		if (IsTooMuchStealth(client)) 
		{
	            	ResetClass(client);
	            	PrintToChat(client, "\x05[xG] %t.", "Stealth Limit Reached");
	            	return Plugin_Continue;
        	}
	}
	
	else if (IsAntiStructure(cls, subcls))
	{
		if (IsTooMuchAntiStructure(client)) 
		{
	            	ResetClass(client);
	            	PrintToChat(client, "\x05[xG] %t.", "AntiStructure Limit Reached");
	            	return Plugin_Continue;
        	}
	}

	return Plugin_Continue;
}

// CHANGE LIMIT
public Action:CMD_ChangeSnipersLimit(client, args) 
{
	if (!IsValidClient(client))
        	return Plugin_Handled;    

	if (args != 2) 
	{
		PrintToChat(client, "\x05[xG] %t", "Invalid Args");
	 	return Plugin_Handled;
	}

	decl String:strteam[32];
	GetCmdArg(1, strteam, sizeof(strteam));
    	new team = StringToInt(strteam) + 2;
    	
    	if (team < 2)
    	{
    		PrintToChat(client, "\x05[xG] %t", "Invalid Team"); 
    		return Plugin_Handled;
    	}

    	decl String:strvalue[32];
	GetCmdArg(2, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);

    	SetUnitLimit(client, team, TYPE_SNIPER, value);
    	return Plugin_Handled;
}

public Action:CMD_ChangeTeamSnipersLimit(client, args) 
{	
	if (CheckCommonFailure(client, TYPE_SNIPER, args))
		return Plugin_Handled;

    	decl String:strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);
	
	if (value > 10)
        	value = 10;

	else if (value < MIN_SNIPER_VALUE)
        	value = MIN_SNIPER_VALUE;
        	
        SetUnitLimit(client, GetClientTeam(client), TYPE_SNIPER, value);
	return Plugin_Handled;
}

public Action:CMD_ChangeTeamStealthLimit(client, args) 
{
	if (CheckCommonFailure(client, TYPE_STEALTH, args))
		return Plugin_Handled;
	
	decl String:strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);
	
	if (value > 10)
        	value = 10;

	else if (value < MIN_STEALTH_LOW_VALUE)
        	value = MIN_STEALTH_LOW_VALUE;
        	
        SetUnitLimit(client, GetClientTeam(client), TYPE_STEALTH, value);
	return Plugin_Handled;
}

public Action:CMD_ChangeTeamAntiStructureLimit(client, args) 
{
	if (CheckCommonFailure(client, TYPE_STRUCTURE, args))
		return Plugin_Handled;
	
	decl String:strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);
	
	if (value > 100)
        	value = 100;

	else if (value < MIN_ANTI_STRUCTURE_PER)
        	value = MIN_ANTI_STRUCTURE_PER;
        	
        SetUnitLimit(client, GetClientTeam(client), TYPE_STRUCTURE, value);
	return Plugin_Handled;
}

bool:CheckCommonFailure(client, type, args)
{
	if (!GetConVarBool(eCommanders))
	{
		PrintToChat(client, "\x05[xG] %t", "Commander Disabled"); //commander setting of sniper limits are disabled
        	return true;
    	}

    	if (!IsValidClient(client))
        	return true;    

    	new client_team = GetClientTeam(client);

    	if (client_team < 2)
    	{
    		PrintToChat(client, "\x05[xG] %t", "Invalid Team"); 
		return true;
	}
	
	if (!args) 
	{
        	switch (type)
        	{
        		case TYPE_SNIPER: 	PrintToChat(client, "[xG] %t", "Proper Sniper Usage");
        		case TYPE_STEALTH:	PrintToChat(client, "[xG] %t", "Proper Stealth Usage");
        		case TYPE_STRUCTURE: 	PrintToChat(client, "[xG] %t", "Proper Structure Usage");
        	}

        	return true;
    	}
    	
    	if (!NDC_IsCommander(client)) 
	{
		PrintToChat(client, "\x05[xG] %t", "Only Commanders"); //snipers limiting is available only for Commander
		return true;
	}
	
	return false;
}

// HELPER FUNCTIONS
bool:IsTooMuchSnipers(client) 
{
	new clientTeam = GetClientTeam(client);	
	new clientCount = ValidTeamCount(client);
	new sniperCount = GetSniperCount(clientTeam);
	new teamIDX = clientTeam - 2;

	if (!SetLimit[teamIDX][TYPE_SNIPER])
		return 	clientCount < 6  &&  sniperCount >= LOW_LIMIT || 
			clientCount < 13 &&  sniperCount >= MED_LIMIT ||
			                     sniperCount >= HIGH_LIMIT;
	else
		return sniperCount >= UnitLimit[teamIDX][TYPE_SNIPER];
}

bool:IsTooMuchStealth(client)
{
	new clientTeam = GetClientTeam(client);	
	new teamIDX = clientTeam - 2;
	
	if (!SetLimit[teamIDX][TYPE_STEALTH])
		return false;
		
	new stealthCount = GetStealthCount(clientTeam);
	new unitLimit = UnitLimit[teamIDX][TYPE_STEALTH];
	
	new stealthMin = GetMinStealthValue(clientTeam);
	new stealthLimit = stealthMin > unitLimit ? stealthMin : unitLimit;
	
	return stealthCount >= stealthLimit;
}

bool:IsTooMuchAntiStructure(client)
{
	new clientTeam = GetClientTeam(client);	
	new teamIDX = clientTeam - 2;
	
	if (!SetLimit[teamIDX][TYPE_STRUCTURE])
		return false;
	
	new Float:AntiStructureFloat = float(GetAntiStructureCount(clientTeam));
	new Float:teamFloat = float(ValidTeamCount(clientTeam));
	new Float:AntiStructurePercent = ((AntiStructureFloat / teamFloat) * 100.0);
	
	new percentLimit = UnitLimit[clientTeam - 2][TYPE_STRUCTURE];
	
	return percentLimit >= AntiStructurePercent && AntiStructureFloat > MIN_ANTI_STRUCTURE_VALUE;
}

bool:IsAntiStructure(class, subClass)
{
	return (class == MAIN_CLASS_EXO && subClass == EXO_CLASS_SEIGE_KIT)
	    || (class == MAIN_CLASS_SUPPORT && subClass == SUPPORT_CLASS_BBQ);
	    // Don't account for sabeuters or grenadiers becuase they are a mixed unit
}

GetMinStealthValue(team)
{
	return ValidTeamCount(team) < 7 ? MIN_STEALTH_LOW_VALUE : MIN_STEALTH_HIGH_VALUE; 
}

ResetClass(client) 
{
	SetEntProp(client, Prop_Send, "m_iPlayerClass", MAIN_CLASS_ASSAULT);
    	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", ASSAULT_CLASS_INFANTRY);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", MAIN_CLASS_ASSAULT);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", ASSAULT_CLASS_INFANTRY);
	SetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);
}

SetUnitLimit(commander, team, type, value)
{
	new teamIDX = team - 2;
	
	UnitLimit[teamIDX][type] = value;
	SetLimit[teamIDX][type] = true;
	
	PrintLimitSet(commander, team, type, value);
}

stock String:GetTypeName(type)
{
	new String:typeName[32];
	
	switch (type)
        {
        	case TYPE_SNIPER: 	typeName = "Sniper";
        	case TYPE_STEALTH:	typeName = "Stealth"; 
        	case TYPE_STRUCTURE: 	typeName = "Anti-Structure";
        }
        
        return typeName;
}

stock String:GetLimitPhrase(type)
{
	new String:LimitPhrase[32];
	
	switch (type)
        {
        	case TYPE_SNIPER: 	LimitPhrase = "Set Sniper Limit";
        	case TYPE_STEALTH:	LimitPhrase = "Set Stealth Limit"; 
        	case TYPE_STRUCTURE: 	LimitPhrase = "Set Structure Limit";
        }
        
        return LimitPhrase;
}

PrintLimitSet(commander, team, type, limit)
{
	if (type == TYPE_STRUCTURE)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == team)
			{
				PrintToChat(client, "\x05[xG] %t.", "Set Structure Limit", limit);
			}
		}
	}
	else
	{
		decl String:Phrase[32];
		Format(Phrase, sizeof(Phrase), GetLimitPhrase(type));
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == team)
			{
				decl String:TranslatedLimit[32];
				Format(TranslatedLimit, sizeof(TranslatedLimit), "%T", NumberInEnglish(limit), client);
				
				decl String:Message[64];
				Format(Message, sizeof(Message), "\x05[xG] %T.", Phrase, client, TranslatedLimit);
				PrintToChat(client, Message);
			}
		}
	}
}
