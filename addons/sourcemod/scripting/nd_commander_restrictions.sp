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

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_commander_restrictions/nd_commander_restrictions.txt"
#include "updater/standard.sp"

#include <sourcemod>
#include <sdktools>
#include <sourcecomms>

#include <nd_stocks>
#include <nd_redstone>
#include <nd_balancer>
#include <nd_gameme>
#include <nd_com_eng>
#include <nd_rounds>

#define INVALID_CLIENT 0
#define PREFIX "\x05[xG]"

public Plugin myinfo =
{
	name = "[ND] Commander Restrictions",
	author = "Stickz",
	description = "Sets conditions for players to apply for commander",
	version = "rebuild",
	url = "https://github.com/stickz/Redstone/"
}

enum Bools
{
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
bool g_Bool[Bools];

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
	
	LoadTranslations("nd_commander_restrictions.phrases");
	
	AutoExecConfig(true, "nd_commander_restrictions");
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(105.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart() {
	g_Bool[timeOut] = false;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{		
	g_Bool[relaxedRestrictions] = false;
	g_Bool[timeOut] = false;
}

public Action TIMER_DisableRestrictions(Handle timer)
{	
	/* If both teams don't have an commander */
	if (ND_GetCommanderCount() != 2)
	{
		g_Bool[timeOut] = true;
		g_Bool[relaxedRestrictions] = true;
		ServerCommand("nd_commander_mutiny_vote_threshold 65.0");
		if (RED_OnTeamCount() > 10)
			PrintToChatAll("%s %t!", PREFIX, "Restrictions Relaxed"); //Commander restrictions relaxed
			//PrintToChatAll("\x05[xG] Commander restrictions lifted! Mutiny threshold set to 70%! (no commander)");
	}
}

public Action Command_Apply(int client, const char[] command, int argc)
{
	#if defined _sourcecomms_included
	if (IsSourceCommSilenced(client))
	{
		PrintToChat(client, "%s %t!", PREFIX, "Silence Command"); //You cannot command while silenced
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
		if (ND_RoundStarted() && GAS_AVAILBLE() && GetAverageSkill() < g_cvar[aRestrictDisable].IntValue)
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
					PrintToChat(client, "%s %t.", PREFIX, "Spawn Before Apply");
					return Plugin_Handled;					
				}
				
				#else
				PrintToChat(client, "%s %t.", PREFIX, "Spawn Before Apply");
				return Plugin_Handled;				
				#endif				
			}
			case 2,3,4,5,6,7,8,9:
			{
				if (count > g_cvar[cRestrictMinLevel].IntValue)
				{
					PrintToChat(client, "%s %t.", PREFIX, "Bellow Ten");
					return Plugin_Handled;	
				}
				
				#if defined _nd_gameme_included
				int lowSkill = g_cvar[cRestrictSkillL].IntValue;			
				if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) < lowSkill)
				{
					PrintToChat(client, "%s %t!", PREFIX, "Skill Required", lowSkill);
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
						PrintToChat(client, "%s %t.", PREFIX, "Fifty Five Required");
						return Plugin_Handled;
					}
					
					#if defined _nd_gameme_included
					int highSkill = g_cvar[cRestrictSkillH].IntValue;					
					if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) < highSkill)
					{
						PrintToChat(client, "%s %t!", PREFIX, "Skill Required", highSkill);
						return Plugin_Handled;	
					}
					#endif
				}
				
				else if (clientLevel < count)
				{
					PrintToChat(client, "%s %t.", PREFIX, "Total Level");
					return Plugin_Handled;
				}
			}		
		}
	}
	return Plugin_Continue;
}

public Action ND_OnCommanderResigned(int client, int team)
{
	if (GetConVarBool(g_cvar[eRestrictions]) && !g_Bool[relaxedRestrictions])
		CreateTimer(60.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
		
	PrintToAdmins("heyo! the commander resigned", "a");		
	return Plugin_Continue;
}
