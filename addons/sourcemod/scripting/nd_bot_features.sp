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
#include <nd_commands>
#include <nd_spec>

bool disableBots = false;
float timerDuration = 1.5;

#include "nd_bot_feat/convars.sp"
#include "nd_bot_feat/commands.sp"

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
	CreatePluginConvars(); // convars.sp
	RegisterPluginCMDS(); // commands.sp
	AddUpdaterLibrary(); //auto-updater
	
	AddCommandListener(PlayerJoinTeam, "jointeam");
	
	// Late-Loading Support
	if (ND_MapStarted())
		SetBotValues();
}

public void OnMapStart() {
	SetBotValues();
}

void SetBotValues()
{
	SetBotDisableValues(); // convars.sp
	SetBotReductionValues(); // convars.sp	
}

public void OnMapEnd() 
{
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

public void AFKM_OnClientAFK(int client) {
	CheckBotCounts(client);
}

public void ND_OnPlayerLockSpecPost(int client, int team) {
	CheckBotCounts(client);
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
		CreateTimer(0.5, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);
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
			int posOverBalance = getPositiveOverBalance();	
			if (posOverBalance >= 1)
			{				
				quota = getBotFillerQuota(posOverBalance); // Get number of bots to fill
				
				// Boost server slots if quota extends cap and team difference is 2+
				toggleBooster(quota >= GetDynamicSlotCount()-2 && posOverBalance >= 2);
				
				// Create a timer after envoking bot quota, to switch bots to the fill team
				CreateTimer(timerDuration, TIMER_CheckAndSwitchFiller, _, TIMER_FLAG_NO_MAPCHANGE);	
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

//Turn 32 slots on or off for bot quota
void toggleBooster(bool state)
{	
	// Exit function if the state is not changing
	if (visibleBoosted == state)
		return;
	
	visibleBoosted = state;
	timerDuration = visibleBoosted ? 5.0 : 1.5
	
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
	toggleBooster(false);
	ServerCommand("bot_quota 0");
	ServerCommand("mp_limitteams 1");
}

int getBotFillerQuota(int plyDiff)
{
	// Set bot count to player count difference * x - 1.
	// Team count offset required to fill the quota properly.
	int total = OnTeamCount() + RoundPowToNearest(float(plyDiff), g_cvar[BotDiffMult].FloatValue);
	
	// Add the spectator count becuase it takes away one bot by default
	int specCount = ValidTeamCount(TEAM_SPEC);
	total += specCount;
	
	// Set a ceiling to be returned, leave two connecting slots
	int max = 30 - ValidTeamCount(TEAM_UNASSIGNED) - specCount;
	return total > max ? max : total;
}

int getBotModulusQuota()
{	
	// Get max quota and the current spectator & team count
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	int specCount = ValidTeamCount(TEAM_SPEC);
	
	// Caculate the value for the bot cvar. Adjust bot value to offset the spectators
	int botAmount = maxQuota - botReductionValue + specCount;
	
	// If the bot value is greater than max, we must use the max instead
	int totalCount = maxQuota - specCount - ValidTeamCount(TEAM_UNASSIGNED);
	if (botAmount >= totalCount)
		botAmount = totalCount;
		
	// If required, modulate the bot count so the number is even on the scoreboard
	return botAmount % 2 != specCount % 2 ? botAmount - 1 : botAmount;
}

bool boostBots()
{
	bool boost = g_cvar[BoostBots].BoolValue;
	toggleBooster(boost);
	return boost;
}

bool CheckShutOffBots()
{	
	// Get the empire, consort and total on team count
	int empireCount = RED_GetTeamCount(TEAM_EMPIRE);
	int consortCount = RED_GetTeamCount(TEAM_CONSORT);	
	
	// If total count on one or both teams is reached, disable bots
	bool isTotalDisable = (empireCount + consortCount) >= totalDisable;
	return isTotalDisable || empireCount >= teamDisable || consortCount >= teamDisable;
}

public Action TIMER_CheckAndSwitchFiller(Handle timer)
{
	CheckAndSwitchFiller();
	return Plugin_Handled;
}

void CheckAndSwitchFiller()
{
	int teamLessPlys = getTeamLessPlayers();	
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
	MarkNativeAsOptional("ND_PlayerSpecLocked");
	RegPluginLibrary("afkmanager");
}
