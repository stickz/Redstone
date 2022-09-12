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
#include <nd_fskill>
#include <nd_redstone>
#include <nd_com_eng>
#include <nd_rounds>
#include <nd_print>
#include <nd_com_dep>
#include <nd_com_ban>
#include <nd_entities>
#include <nd_teampick>
#include <autoexecconfig>

#define INVALID_CLIENT 0

public Plugin myinfo =
{
	name = "[ND] Commander Restrictions",
	author = "Stickz",
	description = "Sets conditions for players to apply for commander",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
}

enum struct Bools
{
	bool relaxedRestrictions;
	bool timeOut;
};

enum struct convars
{
	ConVar eRestrictions;
	ConVar aRestrictDisable;
	ConVar tRestrictDisableDelay;
	ConVar tRestrictWarningDelay;
	
	ConVar cRestrictMinSkill;
	ConVar cRestrictMaxSkill;
	
	ConVar cLowRestrictTeam;
	ConVar cLowRestrictTotal;
	ConVar cHighRestrictTeam;
	ConVar cHighRestrictTotal;
};

convars g_cvar;
Bools g_Bool;

public void OnPluginStart()
{
	CreatePluginConvars(); // Create plugin convars
	
	AddCommandListener(view_as<CommandListener>(Command_Apply), "applyforcommander");
	
	LoadTranslations("nd_common.phrases");
	LoadTranslations("nd_commander_restrictions.phrases");
	
	AutoExecConfig(true, "nd_commander_restrictions");
	
	AddUpdaterLibrary(); //auto-updater
}

void CreatePluginConvars()
{
	AutoExecConfig_Setup("nd_commander_restrictions");
	
	g_cvar.eRestrictions 			= 	AutoExecConfig_CreateConVar("sm_restrict_enable", "1", "0 to disable the restrictions, 1 to enable restrictions.");
	g_cvar.aRestrictDisable 		= 	AutoExecConfig_CreateConVar("sm_restrict_disable", "45", "Sets the skill average to disable all restrictions");	
	g_cvar.tRestrictDisableDelay 	=	AutoExecConfig_CreateConVar("sm_restrict_disable_delay", "120", "Sets the delay to disable commander restricts if nobody applies");
	g_cvar.tRestrictWarningDelay 	=	AutoExecConfig_CreateConVar("sm_restrict_warn_delay", "105", "Sets the delay to display the warning about restricts disabling soon");
	
	g_cvar.cRestrictMinSkill 		= 	AutoExecConfig_CreateConVar("sm_restrict_skill_low", "15", "Sets the minimum skill threshold required to command");
	g_cvar.cRestrictMaxSkill		=	AutoExecConfig_CreateConVar("sm_restrict_skill_high", "45", "Sets the maximum skill threshold required to command");
	
	g_cvar.cLowRestrictTeam		= 	AutoExecConfig_CreateConVar("sm_restrict_low_team", "6", "Sets number of players on team to enable commander restrictions");
	g_cvar.cLowRestrictTotal		=	AutoExecConfig_CreateConVar("sm_restrict_low_total", "10", "Sets number of players on server to enable commander restrictions");
	g_cvar.cHighRestrictTeam		=	AutoExecConfig_CreateConVar("sm_restrict_high_team", "12", "Sets number of players on team to enable high command requirements");
	g_cvar.cHighRestrictTotal		=	AutoExecConfig_CreateConVar("sm_restrict_high_total", "16", "Sets number of players on server to enable high command requirements");	
	
	AutoExecConfig_EC_File();	
}

public void ND_OnRoundStarted() 
{
	CreateTimer(g_cvar.tRestrictDisableDelay.FloatValue, TIMER_DisableRestrictions, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvar.tRestrictWarningDelay.FloatValue, TIMER_DisplayComWarning, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart() 
{
	g_Bool.timeOut = false;
	g_Bool.relaxedRestrictions = false;
}

public Action TIMER_DisableRestrictions(Handle timer)
{	
	/* If both teams don't have an commander */
	if (ND_GetCommanderCount() != 2)
	{
		g_Bool.timeOut = true;
		g_Bool.relaxedRestrictions = true;
		//ServerCommand("nd_commander_mutiny_vote_threshold 65.0");
		if (RED_OnTeamCount() >= g_cvar.cLowRestrictTeam.IntValue)
			PrintToChatAll("%s %t!", PREFIX, "Restrictions Relaxed"); //Commander restrictions relaxed
			//PrintToChatAll("\x05[xG] Commander restrictions lifted! Mutiny threshold set to 70%! (no commander)");
	}
}

public Action TIMER_DisplayComWarning(Handle timer) {
	if (g_cvar.eRestrictions.BoolValue && ND_GetCommanderCount() != 2 && RED_OnTeamCount() >= g_cvar.cLowRestrictTeam.IntValue)
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
	
	if (g_cvar.eRestrictions.BoolValue)
	{	
		// If the commander is not depriotized and the average skill on the server is too low for restricts, disable them.
		bool isDeprioritised = ND_IsCommanderDeprioritised(client)
		if (!isDeprioritised && ND_RoundStarted() && DisableRestrictionsBySkill())
			return Plugin_Continue;
		
		// Get the client count both on a team and on the server
		int onTeamCount = RED_OnTeamCount();
		int onServerCount = ND_GetClientCount();
		
		// If both the onTeamCount and onServerCount is less than the threshold, disable commander restrictions
		if (onTeamCount < g_cvar.cLowRestrictTeam.IntValue && onServerCount < g_cvar.cLowRestrictTotal.IntValue)
			return Plugin_Continue;
			
		// If commander restrictions relax because nobody else applys, allow all applications
		if (g_Bool.timeOut)
			return Plugin_Continue;
		
		// If the client is depriotized don't allow commander applications yet
		if (isDeprioritised)
		{
			PrintMessage(client, "Commander Deprioritised");
			return Plugin_Handled;
		}
		
		// Get the client of the client
		int clientLevel = ND_RetreiveLevel(client);	
		int clientSkill = ND_GetRoundedPSkill(client);
		
		// If the client has no skill and the level is not loaded yet
		// Tell the client they need to spawn before applying
		if (clientSkill <= 1 && clientLevel <= 1)
		{
			PrintToChat(client, "%s %t.", PREFIX, "Spawn Before Apply");
			return Plugin_Handled;			
		}

		// If we're using higher skill commander restrictions, check the player and skill thresholds
		if (onTeamCount >= g_cvar.cHighRestrictTeam.IntValue || onServerCount >= g_cvar.cHighRestrictTotal.IntValue)
		{
			if (clientSkill <= g_cvar.cRestrictMaxSkill.IntValue && clientLevel <= g_cvar.cRestrictMaxSkill.IntValue)
			{
				PrintMessage(client, "Fifty Five Required");
				return Plugin_Handled;				
			}			
		}
		
		// If we're using lower skill commander restrictions, check the player and skill thresholds
		else if (onTeamCount >= g_cvar.cLowRestrictTeam.IntValue || onServerCount >= g_cvar.cLowRestrictTotal.IntValue)
		{
			if (clientSkill <= g_cvar.cRestrictMinSkill.IntValue && clientLevel <= g_cvar.cRestrictMinSkill.IntValue)
			{
				PrintMessage(client, "Bellow Ten");
				return Plugin_Handled;				
			}			
		}
	}
	
	return Plugin_Continue;
}

bool DisableRestrictionsBySkill() {		
	return ND_GEA_AVAILBLE() ? ND_GetEnhancedAverage() < g_cvar.aRestrictDisable.IntValue : true;
}

public Action ND_OnCommanderResigned(int client, int team)
{
	if (GetConVarBool(g_cvar.eRestrictions) && !g_Bool.relaxedRestrictions)
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
	
	// Make nd_fskill optional
	MarkNativeAsOptional("ND_GetTeamDifference");
	MarkNativeAsOptional("ND_GetPlayerSkill");
	MarkNativeAsOptional("ND_GetEnhancedAverage");
	MarkNativeAsOptional("ND_GetCommanderSkill");
	MarkNativeAsOptional("ND_GetPlayerLevel");
	MarkNativeAsOptional("ND_GetSkillMedian");
	MarkNativeAsOptional("ND_GetSkillAverage");
	MarkNativeAsOptional("ND_GetTeamSkillAverage");
	
	return APLRes_Success;
}
