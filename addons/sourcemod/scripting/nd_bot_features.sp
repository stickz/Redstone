/* Key Defintions
 * Modulous Quota: When team counts are less than 8 by default, bots are blasted.
 * Filler Quota: When lots of people are on teams, fill player count differences with bots
 */

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_slots>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_bot_features/nd_bot_features.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <nd_redstone>
#include <nd_balancer>
#include <nd_rounds>
#include <nd_maps>

#include "nd_bot_feat/convars.sp"
//functions required to create a modulous bot quota
//simply calling getBotModulusQuota() will return the integer
#include "nd_bot_feat/modulus_quota.sp"

public Plugin myinfo =
{
	name = "[ND] Bot Features",
	author = "Stickz",
	description = "Give more control over the bots on the server",
	version = "push",
	url = "https://github.com/stickz/Redstone/"
};

public void OnClientDisconnect_Post(int client) {
	checkCount();
}
	
public void OnPluginStart()
{
	CreatePluginConvars(); //convars.sp
	AddCommandListener(PlayerJoinTeam, "jointeam");

	AutoExecConfig(true, "nd_bot_features");	
	AddUpdaterLibrary(); //auto-updater
}

public void OnMapEnd() {
	SignalMapChange();	
}

public Action PlayerJoinTeam(int client, char[] command, int argc) {
	CheckBotCounts(client);
}

public void TB_OnTeamPlacement(int client, int team) {
	CheckBotCounts(client);
}

void CheckBotCounts(int client)
{
	if (IsValidClient(client)) {
		CreateTimer(0.1, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TIMER_CC(Handle timer)
{
	checkCount();
	return Plugin_Handled;
}

public void ND_OnRoundEnded() {
	SignalMapChange();
}

void checkCount()
{
	if (ND_RoundStarted())
	{
		int quota = 0;
		
		int teamCount = RED_OnTeamCount();
		
		// Team count means the requirement for modulous bot quota
		if (teamCount < GetBotShutOffCount())
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
			// Get the bot count to fill empty team slots
			int dynamicSlots = GetDynamicSlotCount() - 2;
			bool excludeSpecs = RED_ClientCount() < dynamicSlots;
			quota = getBotFillerQuota(teamCount, !excludeSpecs, excludeSpecs);		
			
			if (quota >= dynamicSlots && getPositiveOverBalance() >= 3)
			{
				quota = getBotFillerQuota(teamCount, true);
				
				if (!visibleBoosted)
					toggleBooster(true, false);
			}
		}
		
		// If the server slots are boosted to 32, disable that feature
		else if (visibleBoosted)
			toggleBooster(false);
				
		ServerCommand("bot_quota %d", quota);
	}
}

public void ND_OnRoundStarted()
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
int getBotFillerQuota(int teamCount, bool excludeSpectators = false, bool addSpectators = false) 
{
	if (ValidTeamCount(TEAM_EMPIRE) == ValidTeamCount(TEAM_CONSORT))
		return 0;
		
	int total = teamCount + getPositiveOverBalance();
		
	/* Notice: It's assumed this code will only call ValidTeamCount() once for performance reasons */
	if (addSpectators)
		total += ValidTeamCount(TEAM_SPEC);
		
	if (excludeSpectators)
		total -= ValidTeamCount(TEAM_SPEC);

	return total;
}
