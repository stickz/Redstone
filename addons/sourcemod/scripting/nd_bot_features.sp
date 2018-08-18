/* Key Defintions
 * Modulous Quota: When team counts are less than 8 by default, bots are blasted.
 * Filler Quota: When lots of people are on teams, fill player count differences with bots
 */

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_slots>
#include <nd_swgm>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_bot_features/nd_bot_features.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <nd_redstone>
#include <nd_balancer>
#include <nd_rounds>
#include <nd_maps>
#include <nd_turret_eng>
#include <nd_commands>

#include "nd_bot_feat/convars.sp"
//functions required to create a modulous bot quota
//simply calling getBotModulusQuota() will return the integer
#include "nd_bot_feat/modulus_quota.sp"

bool disableBots = false;

public Plugin myinfo =
{
	name = "[ND] Bot Features",
	author = "Stickz",
	description = "Give more control over the bots on the server",
	version = "dummy",
	url = "https://github.com/stickz/Redstone/"
};

public void OnClientDisconnect_Post(int client) {
	checkCount();
}
	
public void OnPluginStart()
{
	CreatePluginConvars(); //convars.sp
	AddCommandListener(PlayerJoinTeam, "jointeam");
	RegConsoleCmd("sm_DisableBots", CMD_DisableBots, "Disables bots until round end");

	AutoExecConfig(true, "nd_bot_features");	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapEnd() {
	disableBots = false;
	SignalMapChange();	
}

public Action PlayerJoinTeam(int client, char[] command, int argc) {
	CheckBotCounts(client);
}

public void TB_OnTeamPlacement(int client, int team) {
	CheckBotCounts(client);
}

public void ND_OnClientTeamSet(int client, int team) {
	CheckBotCounts(client);
}

public Action CMD_DisableBots(int client, int args)
{
	if (!SWMG_OfficerOrRoot(client))
	{
		ReplyToCommand(client, "You must be a RedstoneND officer to use this command!");
		return Plugin_Handled;
	}
	
	disableBots = !disableBots;
	
	if (disableBots)
	{
		PrintToChat(client, "Server bots disabled until round end.");
		SignalMapChange(); // Disable booster and set bot count to 0
	}
	else
	{
		PrintToChat(client, "Server bots have been re-enabled.");
		InitializeServerBots(); // Add the bots back in before the next update
	}
	
	return Plugin_Handled;
}

public Action TIMER_CC(Handle timer)
{
	checkCount();
	return Plugin_Handled;
}

public void ND_OnRoundEnded() {
	disableBots = false;
	SignalMapChange();
}

void CheckBotCounts(int client)
{
	if (IsValidClient(client)) {
		CreateTimer(0.1, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void checkCount()
{
	if (ND_RoundStarted() && !disableBots)
	{
		int quota = 0;
	
		// Team count means the requirement for modulous bot quota
		if (RED_OnTeamCount() < GetBotShutOffCount())
		{
			if(boostBots())
				quota += getBotModulusQuota();

			else
			{
				quota += g_cvar[BotCount].IntValue;
				ServerCommand("mp_limitteams %d", g_cvar[BotOverblance].IntValue);
			}
		}
		
		// The plugin to get the server slot is available
		else if (GDSC_AVAILABLE())
		{	
			// If one team has less players than the other
			int teamLessPlys = getTeamLessPlayers();			
			if (teamLessPlys != TEAM_NONE)
			{
				int dynamicSlots = GetDynamicSlotCount() - 2; // Get the bot count to fill empty team slots
				int teamCount = OnTeamCount(); // Team count, with bot filter
				quota = getBotFillerQuota(teamCount, ValidClientCount() < dynamicSlots);		

				if (quota >= dynamicSlots && getPositiveOverBalance() >= 2)
				{
					quota = getBotFillerQuota(teamCount);

					if (!visibleBoosted)
						toggleBooster(true, false);
				}
				else if (visibleBoosted)
					toggleBooster(false);
					
				CreateTimer(0.3, TIMER_CheckAndSwitchFiller, teamLessPlys, TIMER_FLAG_NO_MAPCHANGE);			
			}
			else { quota = 0; } // Otherwise, set filler quota to 0
		}
		
		// If the server slots are boosted to 32, disable that feature
		else if (visibleBoosted)
			toggleBooster(false);
				
		ServerCommand("bot_quota %d", quota);
	}
}

public void ND_OnRoundStarted() {
	InitializeServerBots();
}

void InitializeServerBots()
{
	int quota = 0;	
	
	// Team count means the requirement for modulous bot quota
	// Decide which type of modulous quota we're using (boosted or regular)
	if (RED_OnTeamCount() < GetBotShutOffCount())
		quota = boostBots() ? getBotModulusQuota() : g_cvar[BotCount].IntValue;
	
	ServerCommand("bot_quota %d", quota);
}

bool boostBots()
{
	if (g_cvar[BoostBots].BoolValue && TDS_AVAILABLE())
	{
		if (!visibleBoosted)
			toggleBooster(true);
		
		return true;
	}

	return false;
}

//Turn 32 slots on or off for bot quota
void toggleBooster(bool state, bool teamCaps = true)
{	
	visibleBoosted = state;
	
	if (TDS_AVAILABLE())
		ToggleDynamicSlots(!state);
		
	else
	{
		PrintToChatAll("\x05[xG] ToggleDynamicSlots() is broken. Please notify a server admin.");
		ServerCommand("sv_visiblemaxplayers 32");
	}
		
	//Unlock team joining when bots are blasting
	if (teamCaps)
		ServerCommand("mp_limitteams %d", state ? g_cvar[BotOverblance].IntValue : g_cvar[RegOverblance].IntValue);
}

//Disable the 32 slots (if activate) when the map changes
void SignalMapChange()
{
	if (visibleBoosted)
		toggleBooster(false);	

	ServerCommand("bot_quota 0");
}

//When teams have two or more less players
int getBotFillerQuota(int teamCount, bool addSpectators = false)
{
	// Set bot count to team difference * 2 minus 1 bot.
	// Team count offset required to fill the quota properly.
	int total = teamCount + getPositiveOverBalance() * 2 - 1;
	
	/* Notice: It's assumed this code will only call ValidTeamCount() once for performance reasons */
	if (addSpectators)
		total += ValidTeamCount(TEAM_SPEC);		
	
	// Set a ceiling of 29 to be returned
	return total > 29 ? 29 : total;
}

public Action TIMER_CheckAndSwitchFiller(Handle timer, any team)
{
	CheckAndSwitchFiller(team);
	return Plugin_Handled;
}

void CheckAndSwitchFiller(int teamLessPlys)
{
	for (int bot = 1; bot < MaxClients; bot++)
	{
		if (IsFakeClient(bot) && IsClientInGame(bot) && GetClientTeam(bot) != teamLessPlys)
		{
			ChangeClientTeam(bot, TEAM_SPEC);
			ChangeClientTeam(bot, teamLessPlys);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ND_GetTurretCount");
	MarkNativeAsOptional("ND_GetTeamTurretCount");
}
