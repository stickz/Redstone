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

#include <sdktools>
#include <nd_com_eng>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_unit_limit/nd_unit_limit.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <sourcemod>
#include <nd_stocks>
#include <nd_print>

#include <nd_breakdown>
#include <nd_rounds>
#include <nd_classes>

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
#define PREFIX "\x05[xG]"

#define m_iDesiredPlayerClass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerClass"))
#define m_iDesiredPlayerSubclass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerSubclass"))

ConVar eCommanders;

int UnitLimit[2][3];
bool SetLimit[2][3];
	
/* Adstract limiting commands, adjust arrays to add more */
#define SNIPER_LIMIT_COMMANDS 5
char sniper_command[SNIPER_LIMIT_COMMANDS][] =
{
	"sm_maxsnipers",
	"sm_maxsniper",
	"sm_sniperlimit",
	"sm_limitsniper",
	"sm_limitsnipers"
};
#define STEALTH_LIMIT_COMMANDS 5
char stealth_command[STEALTH_LIMIT_COMMANDS][] =
{
	"sm_maxstealths",
	"sm_maxstealth",
	"sm_stealthlimit",
	"sm_limitstealth",
	"sm_limitstealths"
};
#define STRUCTURE_LIMIT_COMMANDS 5
char structure_command[STRUCTURE_LIMIT_COMMANDS][] =
{
	"sm_MaxAntiStructures",
	"sm_MaxAntiStructure",
	"sm_AntiStructureLimit",
	"sm_LimitAntiStructure",
	"sm_LimitAntiStructures"
};

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name		= "[ND] Unit Limiter",
	author 		= "stickz, yed_",
	description 	= "Limit the number of units by class type on a team",
	version		= "rebuild",
	url 		= "https://github.com/stickz/Redstone/"
}

public void OnPluginStart() 
{
	eCommanders = CreateConVar("sm_allow_commander_setting", "1", "Sets wetheir to allow commanders to set their own limits.");
	HookEvent("player_changeclass", Event_SelectClass, EventHookMode_Pre);
	
	RegisterCommands(); //register unit limit commands
	AddUpdaterLibrary(); //add updater support
	
	LoadTranslations("nd_unit_limit.phrases");
	LoadTranslations("numbers.phrases");
}

void RegisterCommands()
{
	RegAdminCmd("sm_maxsnipers_admin", CMD_ChangeSnipersLimit, ADMFLAG_GENERIC, "!maxsnipers_admin <team> <amount>");
	
	for (int sniper = 0; sniper < SNIPER_LIMIT_COMMANDS; sniper++) { //for sniper commands
		RegConsoleCmd(sniper_command[sniper], CMD_ChangeTeamSnipersLimit, "Set maximum number of snipers");
	}
	
	for (int stealth = 0; stealth < STEALTH_LIMIT_COMMANDS; stealth++) { //for stealth commands
		RegConsoleCmd(stealth_command[stealth], CMD_ChangeTeamStealthLimit, "Set maximum number of stealth");
	}
	
	for (int structure = 0; structure < STRUCTURE_LIMIT_COMMANDS; structure++) { //for structure commands
		RegConsoleCmd(structure_command[structure], CMD_ChangeTeamAntiStructureLimit, "Set maximum percent of anti-structure"); 
	}
}

public void OnMapStart() {
	ResetUnitLimits();
}

void ResetUnitLimits()
{
	for (int x = 0; x < 2; x++)
	{
		for (int y = 0; y < 2; y++)
		{
			UnitLimit[x][y] = -1;
			SetLimit[x][y] = false;
		}
	}
}

public Action Event_SelectClass(Event event, const char[] name, bool dontBroadcast)
{
	if (!ND_RoundStarted())
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
    	int cls = event.GetInt("class");
    	int subcls = event.GetInt("subclass");

	if (IsSniperClass(cls, subcls)) 
	{
        	if (IsTooMuchSnipers(client)) 
		{
	            	ResetPlayerClass(client);
	            	PrintMessage(client, "Sniper Limit Reached");
	            	return Plugin_Continue;
        	}
	}
	
	else if (IsStealthClass(cls))
	{
		if (IsTooMuchStealth(client)) 
		{
	            	ResetPlayerClass(client);
	            	PrintMessage(client, "Stealth Limit Reached");
	            	return Plugin_Continue;
        	}
	}
	
	else if (IsAntiStructure(cls, subcls))
	{
		if (IsTooMuchAntiStructure(client)) 
		{
	            	ResetPlayerClass(client);
	            	PrintMessage(client, "AntiStructure Limit Reached");
	            	return Plugin_Continue;
        	}
	}

	return Plugin_Continue;
}

// CHANGE LIMIT
public Action CMD_ChangeSnipersLimit(int client, int args) 
{
	if (!IsValidClient(client))
        	return Plugin_Handled;    

	if (args != 2) 
	{
		PrintMessage(client, "Invalid Args");
	 	return Plugin_Handled;
	}

	char strteam[32];
	GetCmdArg(1, strteam, sizeof(strteam));	
    	int team = StringToInt(strteam) + 2;
    	
    	if (IsInvalidTeam(client, team))
		return Plugin_Handled;

    	char strvalue[32];
	GetCmdArg(2, strvalue, sizeof(strvalue));
	int value = StringToInt(strvalue);

    	SetUnitLimit(team, TYPE_SNIPER, value);
    	return Plugin_Handled;
}

public Action CMD_ChangeTeamSnipersLimit(int client, int args) 
{	
	if (CheckCommonFailure(client, TYPE_SNIPER, args))
		return Plugin_Handled;

    	char strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	int value = StringToInt(strvalue);
	
	if (value > 10)
        	value = 10;

	else if (value < MIN_SNIPER_VALUE)
        	value = MIN_SNIPER_VALUE;
        	
        SetUnitLimit(GetClientTeam(client), TYPE_SNIPER, value);
	return Plugin_Handled;
}

public Action CMD_ChangeTeamStealthLimit(int client, int args) 
{
	if (CheckCommonFailure(client, TYPE_STEALTH, args))
		return Plugin_Handled;
	
	char strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	int value = StringToInt(strvalue);
	
	if (value > 10)
        	value = 10;

	else if (value < MIN_STEALTH_LOW_VALUE)
        	value = MIN_STEALTH_LOW_VALUE;
        	
        SetUnitLimit(GetClientTeam(client), TYPE_STEALTH, value);
	return Plugin_Handled;
}

public Action CMD_ChangeTeamAntiStructureLimit(int client, int args) 
{
	if (CheckCommonFailure(client, TYPE_STRUCTURE, args))
		return Plugin_Handled;
	
	char strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	int value = StringToInt(strvalue);
	
	if (value > 100)
        	value = 100;

	else if (value < MIN_ANTI_STRUCTURE_PER)
        	value = MIN_ANTI_STRUCTURE_PER;
        	
        SetUnitLimit(GetClientTeam(client), TYPE_STRUCTURE, value);
	return Plugin_Handled;
}

bool CheckCommonFailure(int client, int type, int args)
{
	if (!eCommanders.BoolValue)
	{
		PrintMessage(client, "Commander Disabled"); //commander setting of sniper limits are disabled
        	return true;
    	}

    	if (!IsValidClient(client))
        	return true;    

    	int team = GetClientTeam(client);
	
	if (IsInvalidTeam(client, team))
		return true;
	
	if (!args) 
	{
        	switch (type)
        	{
        		case TYPE_SNIPER: 	PrintToChat(client, "%s %t", PREFIX, "Proper Sniper Usage");
        		case TYPE_STEALTH:	PrintToChat(client, "%s %t", PREFIX, "Proper Stealth Usage");
        		case TYPE_STRUCTURE: 	PrintToChat(client, "%s %t", PREFIX, "Proper Structure Usage");
        	}

        	return true;
    	}
    	
    	if (!ND_IsCommander(client)) 
	{
		PrintMessage(client, "Only Commanders"); //snipers limiting is available only for Commander
		return true;
	}
	
	return false;
}

bool IsInvalidTeam(int client, int team) 
{
	if (team < 2)
	{
		PrintMessage(client, "Invalid Team"); 
		return true;
	}
	
	return false
}

// HELPER FUNCTIONS
bool IsTooMuchSnipers(int client) 
{
	int clientTeam = GetClientTeam(client);	
	int clientCount = ValidTeamCount(client);
	int sniperCount = GetSniperCount(clientTeam);
	int teamIDX = clientTeam - 2;

	if (!SetLimit[teamIDX][TYPE_SNIPER])
		return 	clientCount < 6  &&  sniperCount >= LOW_LIMIT || 
			clientCount < 13 &&  sniperCount >= MED_LIMIT ||
			                     sniperCount >= HIGH_LIMIT;

	int sniperLimit = UnitLimit[teamIDX][TYPE_SNIPER];
	return sniperLimit == 1 & clientCount >= 10 ? 2 : sniperLimit;
}

bool IsTooMuchStealth(int client)
{
	int clientTeam = GetClientTeam(client);	
	int teamIDX = clientTeam - 2;
	
	if (!SetLimit[teamIDX][TYPE_STEALTH])
		return false;
		
	int stealthCount = GetStealthCount(clientTeam);
	int unitLimit = UnitLimit[teamIDX][TYPE_STEALTH];
	
	int stealthMin = GetMinStealthValue(clientTeam);
	int stealthLimit = stealthMin > unitLimit ? stealthMin : unitLimit;
	
	return stealthCount >= stealthLimit;
}

bool IsTooMuchAntiStructure(int client)
{
	int clientTeam = GetClientTeam(client);	
	int teamIDX = clientTeam - 2;
	
	if (!SetLimit[teamIDX][TYPE_STRUCTURE])
		return false;
	
	float AntiStructureFloat = float(GetAntiStructureCount(clientTeam));
	float teamFloat = float(ValidTeamCount(clientTeam));
	float AntiStructurePercent = (AntiStructureFloat / teamFloat) * 100.0;
	
	int percentLimit = UnitLimit[clientTeam - 2][TYPE_STRUCTURE];
	
	return AntiStructurePercent >= percentLimit && AntiStructureFloat > MIN_ANTI_STRUCTURE_VALUE;
}

bool IsAntiStructure(int class, int subClass)
{
	return (class == MAIN_CLASS_EXO && subClass == EXO_CLASS_SEIGE_KIT)
	    || (class == MAIN_CLASS_SUPPORT && subClass == SUPPORT_CLASS_BBQ);
	    // Don't account for sabeuters or grenadiers becuase they are a mixed unit
}

int GetMinStealthValue(int team) {
	return ValidTeamCount(team) < 7 ? MIN_STEALTH_LOW_VALUE : MIN_STEALTH_HIGH_VALUE; 
}

void ResetPlayerClass(int client) {
	ResetClass(client, MAIN_CLASS_ASSAULT, ASSAULT_CLASS_INFANTRY, 0);
}

void SetUnitLimit(int team, int type, int value)
{
	int teamIDX = team - 2;
	
	UnitLimit[teamIDX][type] = value;
	SetLimit[teamIDX][type] = true;
	
	PrintLimitSet(team, type, value);
}

stock char GetLimitPhrase(int type)
{
	char LimitPhrase[32];
	
	switch (type)
        {
        	case TYPE_SNIPER: 	LimitPhrase = "Set Sniper Limit";
        	case TYPE_STEALTH:	LimitPhrase = "Set Stealth Limit"; 
        	case TYPE_STRUCTURE: 	LimitPhrase = "Set Structure Limit";
        }
        
        return LimitPhrase;
}

void PrintLimitSet(int team, int type, int limit)
{
	if (type == TYPE_STRUCTURE)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == team)
			{
				PrintToChat(client, "%s %t.", PREFIX, "Set Structure Limit", limit);
			}
		}
	}
	else
	{
		char Phrase[32];
		Format(Phrase, sizeof(Phrase), GetLimitPhrase(type));
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == team)
			{
				char TranslatedLimit[32];
				Format(TranslatedLimit, sizeof(TranslatedLimit), "%T", NumberInEnglish(limit), client);
				
				char Message[64];
				Format(Message, sizeof(Message), "%s %T.", PREFIX, Phrase, client, TranslatedLimit);
				PrintToChat(client, Message);
			}
		}
	}
}
