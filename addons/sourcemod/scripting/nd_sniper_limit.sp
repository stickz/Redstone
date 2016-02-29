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

#define MIN_VALUE 1
#define LOW_LIMIT 2
#define MED_LIMIT 3
#define HIGH_LIMIT 4

#define PLUGIN_VERSION "1.1.9"
#define DEBUG 0

#define TEAM_CON 2
#define TEAM_EMP 3

#define ASSAULT_CLASS 0
#define ASSAULT_INFANTRY 0
#define ASSAULT_MARKSMAN 2

#define SNIPER_CLASS 2
#define SNIPER_SNIPER 1

#define m_iDesiredPlayerClass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerClass"))
#define m_iDesiredPlayerSubclass(%1) (GetEntProp(%1, Prop_Send, "m_iDesiredPlayerSubclass"))

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/master/updater/nd_sniper_limit/nd_sniper_limit.txt"
#include "updater/standard.sp"

enum Bools
{
	pluginEnabled,
	allowComanders,
	empireSetLimit,
	consortSetLimit
};

enum Integers
{
	newConsortLimit,
	newEmpireLimit
};

new Handle:eCommanders = INVALID_HANDLE,
	g_Integer[Integers],
	bool:g_Bool[Bools];

public Plugin:myinfo = {
	name = "Sniper Limiter",
	author = "yed_, edited by Stickz",
	description = "Limit the number of snipers in the team",
	version = PLUGIN_VERSION,
	url = "https://github.com/yedpodtrzitko/ndix/"
}

public OnPluginStart() 
{
	eCommanders = CreateConVar("sm_maxsnipers_commander_ussage", "1", "Sets wetheir to allow commanders to set their own limits.");
	
	CreateConVar("sm_maxsnipers_version", PLUGIN_VERSION, "ND Maxsnipers Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_maxsnipers_admin", CMD_ChangeSnipersLimit, ADMFLAG_GENERIC, "!maxsnipers_admin <team> <amount>");
	RegConsoleCmd("sm_maxsnipers", CMD_ChangeTeamSnipersLimit, "Change the maximum number of snipers in the team: !maxsnipers <amount>");

	HookEvent("player_changeclass", Event_SetClass, EventHookMode_Pre);
	//HookEvent("player_death", Event_SetClass, EventHookMode_Post);
	
	AddUpdaterLibrary();
	
	LoadTranslations("nd_sniper_limit.phrases");
}

public OnMapStart() {
	g_Bool[allowComanders] = GetConVarBool(eCommanders);
	g_Bool[empireSetLimit] = false;
	g_Bool[consortSetLimit] = false;
}

public Action:Event_SetClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    	new cls = GetEventInt(event, "class");
    	new subcls = GetEventInt(event, "subclass");

	if (IsSniperClass(cls, subcls)) 
	{
        	if (IsTooMuchSnipers(client)) 
		{
	            	ResetClass(client);
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
    	new team = StringToInt(strteam);

    	decl String:strvalue[32];
	GetCmdArg(2, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);

    	ChangeSnipersLimit(client, team+2, value);
    	return Plugin_Handled;
}

public Action:CMD_ChangeTeamSnipersLimit(client, args) 
{	
	if (!g_Bool[allowComanders])
	{
		PrintToChat(client, "\x05[xG] %t", "Commander Disabled"); //commander setting of sniper limits are disabled
        	return Plugin_Handled;
    	}

    	if (!IsValidClient(client))
        	return Plugin_Handled;    

    	new client_team = GetClientTeam(client);

    	if (client_team < 2)
		return Plugin_Handled;    

    	if (!args) 
	{
        	PrintToChat(client, "[xG] %t", "Proper Usage");
        	return Plugin_Handled;
    	}

    	if (!NDC_IsCommander(client)) 
	{
        	PrintToChat(client, "\x05[xG] %t", "Only Commanders"); //snipers limiting is available only for Commander
        	return Plugin_Handled;
	 }

    	decl String:strvalue[32];
	GetCmdArg(1, strvalue, sizeof(strvalue));
	new value = StringToInt(strvalue);

	ChangeSnipersLimit(client, client_team, value);
	return Plugin_Handled;
}

// HELPER FUNCTIONS
bool:IsTooMuchSnipers(client) 
{
	new clientTeam = GetClientTeam(client);	
	new clientCount = ValidTeamCount(client);
	new sniperCount = GetSniperCount(clientTeam);

	if (!hasSetSniperLimit(clientTeam))
		return 	clientCount < 6  &&  sniperCount >= LOW_LIMIT || 
			clientCount < 13 &&  sniperCount >= MED_LIMIT ||
			                     sniperCount >= HIGH_LIMIT;
	else
		return 	clientTeam == TEAM_CON && sniperCount >= g_Integer[newConsortLimit] ||
			clientTeam == TEAM_EMP && sniperCount >= g_Integer[newEmpireLimit];
}

bool:hasSetSniperLimit(team)
{
	#if DEBUG == 1
	new bool:value = team == TEAM_CON && g_Bool[consortSetLimit] || team == TEAM_EMP && g_Bool[empireSetLimit];
	if (value)
		PrintToChatAll("[xG] set sniper limit detected");
	else
		PrintToChatAll("[xG] no set sniper limit detected");
	#endif
	return team == TEAM_CON && g_Bool[consortSetLimit] || team == TEAM_EMP && g_Bool[empireSetLimit];
}

bool:IsSniperClass(class, subclass) 
{
	return (class == ASSAULT_CLASS && subclass == ASSAULT_MARKSMAN) || (class == SNIPER_CLASS && subclass == SNIPER_SNIPER)
}

ResetClass(client) 
{
	SetEntProp(client, Prop_Send, "m_iPlayerClass", ASSAULT_CLASS);
    	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", ASSAULT_INFANTRY);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", ASSAULT_CLASS);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", ASSAULT_INFANTRY);
	SetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);

    	PrintToChat(client, "\x05[xG] %t.", "Limit Reached");
}

ChangeSnipersLimit(client, team, value)
{
	if (value > 10)
        value = 10;

	else if (value < MIN_VALUE)
        value = MIN_VALUE;
		
	decl String:teamName[16];
	switch (team)
	{
		case TEAM_EMP:
		{
			Format(teamName, sizeof(teamName), "%t", "Empire"); 
			g_Integer[newEmpireLimit] = value;
			g_Bool[empireSetLimit] = true;
		}
		case TEAM_CON: 
		{
			Format(teamName, sizeof(teamName), "%t", "Consortium");
			g_Integer[newConsortLimit] = value;
			g_Bool[consortSetLimit] = true;
		}
		default: 
		{		
			PrintToChat(client, "\x05[xG] %t", "Invalid Team"); 
			return;
		}
	}
	
	PrintToChat(client, "\x05[xG] %s's sniper limit was changed to %i.", teamName, value);
}
