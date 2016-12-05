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
#include <sourcecomms>

#include <nd_stocks>
#include <nd_redstone>
#include <nd_balancer>
#include <nd_gameme>

#define VERSION "1.3"

#define INVALID_CLIENT 0

public Plugin myinfo =
{
	name = "[ND] Commander Restrictions",
	author = "Stickz",
	description = "Sets conditions for players to apply for commander",
	version = VERSION,
	url = "N/A"
}

enum Bools
{
	enableDemote,
	roundHasEnded,
	roundHasStarted,
	relaxedRestrictions,
	timeOut
};

enum convars
{
	ConVar:eRestrictions,
	ConVar:cRestrictMinLevel,
	ConVar:cHighPlayerRestrict,
	ConVar:cHighPlayerLevel,
	ConVar:aRestrictDisable,
	ConVar:cRestrictSkillL,
	ConVar:cRestrictSkillH,
	ConVar:disRestrictions
};

ConVar g_cvar[convars];
int commander[2];

bool g_Bool[Bools];
bool g_isCommander[MAXPLAYERS+1] = {false, ...};

public void OnPluginStart()
{
	g_cvar[eRestrictions] 		= 	CreateConVar("sm_commander_restrictions", "1", "0 to disable the restrictions, 1 to enable restrictions.");
	g_cvar[cRestrictMinLevel] 	= 	CreateConVar("sm_commander_level", "10", "Sets the minimum level threshold required to command");
	g_cvar[cHighPlayerRestrict]	=	CreateConVar("sm_restrict_highply", "18", "Sets the amount of players for high command requirements");
	g_cvar[cHighPlayerLevel]	=	CreateConVar("sm_restrict_highlvl", "40", "Sets the maximum threshold required to command");
	g_cvar[aRestrictDisable] 	= 	CreateConVar("sm_restrict_disable", "35", "Sets the skill average to disable all restrictions");
	g_cvar[cRestrictSkillL]		=	CreateConVar("sm_commander_lskill", "5000", "Sets the minimum skill threshold required to command");
	g_cvar[cRestrictSkillH]		=	CreateConVar("sm_commander_hskill", "15000", "Sets the maximum skill threshold required to command");
	g_cvar[disRestrictions]		= 	CreateConVar("sm_restrict_enable", "8", "Sets number of players on team to enable commadner restrictions");
	
	AddCommandListener(CommandListener:Command_Apply, "applyforcommander");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	HookEvent("promoted_to_commander", Event_CommanderPromo);
	
	LoadTranslations("nd_commander_restrictions.phrases");
	
	AutoExecConfig(true, "nd_commander_restrictions");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(105.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_Bool[roundHasStarted] = true;
	g_Bool[roundHasEnded] = false;
}

void resetForGameStart()
{
	g_Bool[timeOut] = false;	
	
	commander[0] = -1;
	commander[1] = -1;

	for (int client = 1; client <= MaxClients; client++)
	{
		g_isCommander[client] = false;
	}
}

public void OnMapStart()
{
	resetForGameStart();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{		
	g_Bool[roundHasStarted] = false;
	g_Bool[relaxedRestrictions] = false;
	g_Bool[roundHasEnded] = true;
	g_Bool[timeOut] = false;
}

public Action Event_CommanderPromo(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "teamid") -2;
	
	commander[team] = client;
	g_isCommander[client] = true;
}

public Action TIMER_DisableRestrictions(Handle timer)
{	
	/* If both teams don't have an commander */
	if (getCommanderCount() != 2)
	{
		g_Bool[timeOut] = true;
		g_Bool[relaxedRestrictions] = true;
		ServerCommand("nd_commander_mutiny_vote_threshold 65.0");
		if (RED_OnTeamCount() > 10)
			PrintToChatAll("\x05[xG] %t!", "Restrictions Relaxed"); //Commander restrictions relaxed
			//PrintToChatAll("\x05[xG] Commander restrictions lifted! Mutiny threshold set to 70%! (no commander)");
	}
}

public Action Command_Apply(int client, const char[] command, int argc)
{
	#if defined _sourcecomms_included
	if (IsSourceCommSilenced(client))
	{
		PrintToChat(client, "\x05[xG] %t!", "Silence Command"); //You cannot command while silenced
		return Plugin_Handled;
	}
	#endif
	
	if (g_cvar[eRestrictions].BoolValue)
	{	
		#if defined _nd_gameme_included
		if (GM_RC_LOADED() && GameME_RankedClient(client))
			return Plugin_Continue;
		#endif
		
		#if defined _nd_balancer_included
		if (g_Bool[roundHasStarted] && GAS_AVAILBLE() && GetAverageSkill() < g_cvar[aRestrictDisable].IntValue)
			return Plugin_Continue;
		#endif

		int count = RED_OnTeamCount();

		if (count < g_cvar[disRestrictions].IntValue)
			return Plugin_Continue;		
			
		int clientLevel = RetreiveLevel(client);
		
		switch(clientLevel)
		{
			case 0,1:
			{
				#if defined _nd_gameme_included
				if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) > g_cvar[cRestrictSkillL].IntValue)
					return Plugin_Continue;
					
				else
				{
					PrintToChat(client, "\x05[xG] %t.", "Spawn Before Apply");
					return Plugin_Handled;					
				}
				
				#else
				PrintToChat(client, "\x05[xG] %t.", "Spawn Before Apply");
				return Plugin_Handled;				
				#endif				
			}
			case 2,3,4,5,6,7,8,9:
			{
				if (count > g_cvar[cRestrictMinLevel].IntValue)
				{
					PrintToChat(client, "\x05[xG] %t.", "Bellow Ten");
					return Plugin_Handled;	
				}
				
				#if defined _nd_gameme_included
				int lowSkill = g_cvar[cRestrictSkillL].IntValue;			
				if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) < lowSkill)
				{
					PrintToChat(client, "\x05[xG] %t!", "Skill Required", lowSkill);
					return Plugin_Handled;				
				}
				#endif
			}
			default:
			{
				if (g_Bool[timeOut])
					return Plugin_Continue;			
				
				if (count > g_cvar[cHighPlayerRestrict].IntValue)
				{
					if (clientLevel < g_cvar[cHighPlayerLevel].IntValue)
					{
						PrintToChat(client, "\x05[xG] %t.", "Fifty Five Required");
						return Plugin_Handled;
					}
					
					#if defined _nd_gameme_included
					int highSkill = g_cvar[cRestrictSkillH].IntValue;					
					if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) < highSkill)
					{
						PrintToChat(client, "\x05[xG] %t!", "Skill Required", highSkill);
						return Plugin_Handled;	
					}
					#endif
				}
				
				else if (clientLevel < count)
				{
					PrintToChat(client, "\x05[xG] %t.", "Total Level");
					return Plugin_Handled;
				}
			}		
		}
	}
	return Plugin_Continue;
}

public Action startmutiny(int client, const char[] command, int argc)
{
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;
	
	int team = GetClientTeam(client);
	if (team < 2) //team != TEAM_CONSORT && team != TEAM_EMPIRE
		return Plugin_Continue;
	
	int teamIDX = team - 2;
	
	if (commander[teamIDX] == -1)
		return Plugin_Continue;
	
	if (g_isCommander[client])
	{
		setCommanderStatus(false, client, teamIDX);
		
		if (GetConVarBool(g_cvar[eRestrictions]) && !g_Bool[relaxedRestrictions])
			CreateTimer(60.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

void setCommanderStatus(bool status, int client, int teamIDX)
{
	g_isCommander[client] = status;	
	commander[teamIDX] = status ? client : -1;
}

int getCommanderCount()
{
	int commanderCount;
	
	for (int client = 1; client <= MaxClients; client++)
		if (RED_IsValidClient(client))
		{
			if (client == commander[0] || client == commander[1])
				commanderCount++;
		}
			
	return commanderCount;
}

int getCommanderTeam(int client) {
	return g_isCommander[client] ? GetClientTeam(client) : -1;
}

functag NativeCall public(Handle:plugin, numParams);

/* Natives */
public Native_GetCommanderTeam(Handle:plugin, numParams)
{
	/* Retrieve the parameter */
	new client = GetNativeCell(1);
	return getCommanderTeam(client);
}

public Native_GetCommanderClient(Handle:plugin, numParams)
{
	/* Retrieve the parameter */
	new team = GetNativeCell(1);
	return commander[team - 2];
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("GetCommanderTeam", Native_GetCommanderTeam);
   CreateNative("GetCommanderClient", Native_GetCommanderClient);

   return APLRes_Success;
}
