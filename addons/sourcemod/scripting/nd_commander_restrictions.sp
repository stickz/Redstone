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
#pragma newdecls required

#include <nd_stocks>
#include <nd_fskill>
#include <nd_redstone>
#include <nd_gameme>
#include <nd_com_eng>
#include <nd_rounds>
#include <nd_print>
#include <nd_com_dep>
#include <nd_com_ban>
#include <nd_entities>
#include <nd_teampick>

#define INVALID_CLIENT 0

public Plugin myinfo =
{
	name = "[ND] Commander Restrictions",
	author = "Stickz",
	description = "Sets conditions for players to apply for commander",
	version = "dummy",
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
	
	AddCommandListener(view_as<CommandListener>(Command_Apply), "applyforcommander");
	
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_commander_restrictions.phrases");
	
	AutoExecConfig(true, "nd_commander_restrictions");
	
	AddUpdaterLibrary(); //auto-updater
}

public void ND_OnRoundStarted() {
	CreateTimer(105.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(90.0, TIMER_DisplayComWarning, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart() {
	g_Bool[timeOut] = false;
	g_Bool[relaxedRestrictions] = false;
}

public Action TIMER_DisableRestrictions(Handle timer)
{	
	/* If both teams don't have an commander */
	if (ND_GetCommanderCount() != 2)
	{
		g_Bool[timeOut] = true;
		g_Bool[relaxedRestrictions] = true;
		//ServerCommand("nd_commander_mutiny_vote_threshold 65.0");
		if (RED_OnTeamCount() >= g_cvar[disRestrictions].IntValue)
			PrintToChatAll("%s %t!", PREFIX, "Restrictions Relaxed"); //Commander restrictions relaxed
			//PrintToChatAll("\x05[xG] Commander restrictions lifted! Mutiny threshold set to 70%! (no commander)");
	}
}

public Action TIMER_DisplayComWarning(Handle timer) {
	if (g_cvar[eRestrictions].BoolValue && ND_GetCommanderCount() != 2 && RED_OnTeamCount() >= g_cvar[disRestrictions].IntValue)
		PrintToChatAll("%s %t!", PREFIX, "Last Chance Apply");
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
	
	// Check if the commander is banned, if so don't let them apply
	if (ND_COMB_AVAILABLE() && ND_IsCommanderBanned(client))
	{	
		PrintToChat(client, "You are banned from using commander.");
		return Plugin_Handled;
	}
	
	// Check if we picked teams this map, if so disable commander restrictions
	if (ND_PickedTeamsThisMap())
		return Plugin_Continue;
	
	if (g_cvar[eRestrictions].BoolValue)
	{	
		bool isDeprioritised = ND_IsCommanderDeprioritised(client)
		if (!isDeprioritised)
		{
			#if defined _nd_gameme_included
			if (GM_RC_LOADED() && GameME_RankedClient(client))
				return Plugin_Continue;
			#endif

			if (ND_RoundStarted() && DisableRestrictionsBySkill())
				return Plugin_Continue;
		}

		int count = RED_OnTeamCount();
		if (count < g_cvar[disRestrictions].IntValue)
			return Plugin_Continue;
			
		if (g_Bool[timeOut])
			return Plugin_Continue;
						
		int clientLevel = ND_RetreiveLevel(client);		
		switch(clientLevel)
		{
			case 0,1:
			{
				#if defined _nd_gameme_included
				if (GameME_SkillAvailible(client) && GameME_GetClientSkill(client) > g_cvar[cRestrictSkillL].IntValue)
					return Plugin_Continue;
					
				else
				{
					PrintMessage(client, "Spawn Before Apply");
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
					PrintMessage(client, "Bellow Ten");
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
				if (isDeprioritised)
				{
					PrintMessage(client, "Commander Deprioritised");
					return Plugin_Handled;
				}
				
				else if (count > g_cvar[cHighPlayerRestrict].IntValue)
				{
					if (clientLevel < g_cvar[cHighPlayerLevel].IntValue)
					{
						PrintMessage(client, "Fifty Five Required");
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
			}		
		}
	}
	return Plugin_Continue;
}

bool DisableRestrictionsBySkill() {		
	return ND_GEA_AVAILBLE() ? ND_GetEnhancedAverage() < g_cvar[aRestrictDisable].IntValue : true;
}

public Action ND_OnCommanderResigned(int client, int team)
{
	if (GetConVarBool(g_cvar[eRestrictions]) && !g_Bool[relaxedRestrictions])
		CreateTimer(60.0, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_PickedTeamsThisMap");
	
	MarkNativeAsOptional("SourceComms_SetClientMute");
	MarkNativeAsOptional("SourceComms_SetClientGag");
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	MarkNativeAsOptional("SourceComms_GetClientGagType");
	return APLRes_Success;
}
