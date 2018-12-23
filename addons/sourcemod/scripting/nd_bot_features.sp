/* Key Defintions
 * Modulous Quota: When team counts are less than 8 by default, bots are blasted.
 * Filler Quota: When lots of people are on teams, fill player count differences with bots
 */

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_slots>
#include <nd_swgm>

#undef REQUIRE_PLUGIN
#include <afk_manager>
#define REQUIRE_PLUGIN

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
#include <nd_spec>

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
	CheckBotCounts(client, 0.5);
}

public void AFKM_OnClientAFK(int client) {
	CheckBotCounts(client);
}

public void ND_OnPlayerLockSpecPost(int client, int team) {
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

void CheckBotCounts(int client, float duration = 0.1)
{
	if (IsValidClient(client)) {
		CreateTimer(duration, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void checkCount()
{
	if (ND_RoundStarted() && !disableBots)
	{
		int quota = 0;
	
		// Team count means the requirement for modulous bot quota
		if (!CheckShutOffBots())
			quota += boostBots() ? getBotModulusQuota() : g_cvar[BotCount].IntValue;
		
		// The plugin to get the server slot is available
		else if (GDSC_AVAILABLE())
		{	
			// If one team has less players than the other
			int teamLessPlys = getTeamLessPlayers();			
			if (teamLessPlys != TEAM_NONE)
			{
				int posOverBalance = getPositiveOverBalance(); // The player difference between the two teams				
				int dynamicSlots = GetDynamicSlotCount() - 2; // Get the bot count to fill empty team slots
				int teamCount = OnTeamCount(); // Team count, with bot filter
				quota = getBotFillerQuota(teamCount, posOverBalance);
				
				float timerDuration = 1.5;
				if (quota >= dynamicSlots && posOverBalance >= 2)
				{
					quota = getBotFillerQuota(teamCount, posOverBalance);
					
					if (!visibleBoosted)
						toggleBooster(true);
				}
	
				else if (visibleBoosted)
				{
					toggleBooster(false);
					timerDuration = 5.0;
				}
				
				CreateTimer(timerDuration, TIMER_CheckAndSwitchFiller, teamLessPlys, TIMER_FLAG_NO_MAPCHANGE);	
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
	if (!CheckShutOffBots())
		quota = boostBots() ? getBotModulusQuota() : g_cvar[BotCount].IntValue;
	
	ServerCommand("bot_quota %d", quota);
	ServerCommand("mp_limitteams %d", g_cvar[RegOverblance].IntValue);
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
void toggleBooster(bool state)
{	
	visibleBoosted = state;
	
	if (TDS_AVAILABLE())
		ToggleDynamicSlots(!state);
		
	else
	{
		PrintToChatAll("\x05[xG] ToggleDynamicSlots() is broken. Please notify a server admin.");
		ServerCommand("sv_visiblemaxplayers 32");
	}
}

//Disable the 32 slots (if activate) when the map changes
void SignalMapChange()
{
	if (visibleBoosted)
		toggleBooster(false);	

	ServerCommand("bot_quota 0");
	ServerCommand("mp_limitteams 1");
}

//When teams have two or more less players
int getBotFillerQuota(int teamCount, int plyDiff)
{
	// Set bot count to player count difference * x - 1.
	// Team count offset required to fill the quota properly.
	int total = teamCount + GetBotCountByPow(plyDiff, g_cvar[BotDiffMult].FloatValue);
	
	// Add the spectator count becuase it takes away one bot by default
	total += ValidTeamCount(TEAM_SPEC);
	
	// Set a ceiling of 29 to be returned
	return total > 29 ? 29 : total;
}

int GetBotCountByPow(int diff, float exp) {
	return RoundToNearest(Pow(diff, exp));
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
		if (IsClientConnected(bot) && IsClientInGame(bot) && IsFakeClient(bot) && GetClientTeam(bot) != teamLessPlys)
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
	MarkNativeAsOptional("ND_PlayerSpecLocked");
	RegPluginLibrary("afkmanager");
}
