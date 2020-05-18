/* Key Defintions
 * Modulous Quota: When team counts are less than 8 by default, bots are blasted.
 * Filler Quota: When lots of people are on teams, fill player count differences with bots
 */

#include <sourcemod>
#include <sdktools>
#include <nd_stocks>
#include <nd_slots>
#include <nd_swgm>
#include <nd_fskill>
#include <smlib/math>

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_bot_features/nd_bot_features.txt"
#include "updater/standard.sp"

#pragma newdecls required
#include <nd_team_eng>
#include <nd_transport_eng>
#include <nd_redstone>
#include <nd_rounds>
#include <nd_maps>

bool disableBots = false;
bool isSwitchingBots = false;
float timerDuration = 1.5;

#define FILL_AVR 0.85
#define FILL_MED 0.15

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

public void OnPluginStart()
{
	CreatePluginConvars(); // convars.sp
	RegisterPluginCMDS(); // commands.sp
	AddUpdaterLibrary(); //auto-updater
	
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
	isSwitchingBots = false;
	SignalMapChange();	
}

public void ND_OnPlayerTeamChanged(int client, bool valid) 
{
	if (valid)
		CreateTimer(0.5, TIMER_CC, _, TIMER_FLAG_NO_MAPCHANGE);

	else if (!IsClientConnected(client))
		checkCount();
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

void checkCount()
{
	if (ND_RoundStarted() && !disableBots)
	{
		int quota = 0;
	
		// Team count means the requirement for modulous bot quota
		if (!CheckShutOffBots())
			quota += boostBots() ? getBotModulusQuota() : g_cvar[BotCount].IntValue;
		
		// The plugin to get the server slot is available
		else if (GDSC_AVAILABLE() && g_cvar[EnableFillerQuota].BoolValue)
		{	
			// Get team count difference and team skill difference multiplier
			int posOverBalance = getPositiveOverBalance();
			float teamDiffMult = getTeamDiffMult();
			
			// If one team has less players than the other
			if (posOverBalance >= 1)
			{				
				quota = getBotFillerQuota(posOverBalance, teamDiffMult); // Get number of bots to fill
				
				// Create a timer after envoking bot quota, to switch bots to the fill team
				CreateTimer(timerDuration, TIMER_CheckAndSwitchFiller, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			// If both teams have the same number of players and one team has 150%+ more skill
			else if (teamDiffMult * 100.0 >= g_cvar[BotEvenPlysEnable].FloatValue)
			{
				quota = getBotEvenQuota(teamDiffMult); // Get number of bots to fill
				
				// Create a timer after envoking bot quota, to switch bots to the fill team
				CreateTimer(timerDuration, TIMER_CheckAndSwitchEven, _, TIMER_FLAG_NO_MAPCHANGE)			
			}
			
			// Otherwise, set filler quota to 0
			else { quota = 0; }
			
			// Boost server slots if quota extends cap and team difference is 2+
			toggleBooster(quota >= GetDynamicSlotCount()-2 && posOverBalance >= 2);
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
	timerDuration = visibleBoosted ? 5.0 : 3.0;
	
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
	//ServerCommand("bot_quota 0");
	ServerCommand("mp_limitteams 1");
}

int getBotFillerQuota(int plyDiff, float teamDiffMult)
{
	// Get the team count offset to properly fill the bot quota
	int specCount = ValidTeamCount(TEAM_SPEC);
	int teamCount = GetOnTeamCount(specCount);
	
	// Set bot count to player count difference ^ x or skill difference ^ x 
	int add	= RoundPowToNearest(float(plyDiff), g_cvar[BotDiffMult].FloatValue);
	int physical = teamCount + Math_Max(add, 3);
	
	// Set a ceiling to be returned, leave two connecting slots	
	// Determine the maximum bot count to use. Skill difference or player difference.
	// Limit the bot count to the maximum available on the server. (if required)
	return Math_Max(physical, GetMaxBotCount(specCount));
}

int getBotEvenQuota(float teamDiffMult)
{
	// Get the team count offset to fill the bot quota and set bot count to skill difference ^ x
	int specCount = ValidTeamCount(TEAM_SPEC);
	int add = RoundPowToNearest(teamDiffMult, g_cvar[BotEvenSkillMult].FloatValue);
	int skill = GetOnTeamCount(specCount) + Math_Max(add, 3);
	
	// Set a ceiling to be returned, leave two connecting slots
	return Math_Max(skill, GetMaxBotCount(specCount));
}

int GetMaxBotCount(int specCount) {
	return g_cvar[BoosterQuota].IntValue - ValidTeamCount(TEAM_UNASSIGNED) - specCount;
}

int GetOnTeamCount(int specCount) {
	return OnTeamCount() + specCount;
}

float getBotSkillMult()
{
	float average = ND_GetEnhancedAverage();
	int increase = g_cvar[BotSkillIncrease].IntValue;
	
	return average >= increase ? g_cvar[BotSkillMultHigh].FloatValue
				   : g_cvar[BotSkillMultLow].FloatValue;
}

float getTeamDiffMult()
{
	// Return zero if teamdiff or average is not availible.
	if (!ND_GEA_AVAILBLE() || !ND_GED_AVAILBLE())
		return 0.0;
		
	// Retrieve the team difference and average
	float teamDiff = ND_GetTeamDifference();
	float average = ND_GetEnhancedAverage(FILL_AVR, FILL_MED);
	
	// Return zero if team with less players has more skill or one team has no players
	if (getStackedTeam(teamDiff) == getTeamLessPlayers() || average < 0.0)
		return 0.0;
		
	// Otherwise, team / average. Convert teamDiff to positive number if required.
	return teamDiff < 0 ? teamDiff * -1.0 / average : teamDiff / average;
}

int getBotModulusQuota()
{	
	// Get max quota and the current spectator & team count
	int maxQuota = g_cvar[BoosterQuota].IntValue;
	int specCount = ValidTeamCount(TEAM_SPEC);
	
	// Caculate number of bots for the map. Adjust bot value to offset the spectators
	int reduce = Math_Min(botReductionValue - specCount, 0);
	
	// If the bot value is greater than max, we must use the max instead
	int totalCount = maxQuota - specCount - ValidTeamCount(TEAM_UNASSIGNED);
	int botAmount = Math_Max(maxQuota - reduce + specCount, totalCount);
		
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
	// Recreate the timer, if bots are already in the procress of being switched
	if (isSwitchingBots)
	{
		// Create a cooldown before bots can be switched again, so they don't end up in spectator
		CreateTimer(timerDuration, TIMER_CooldownSwitchingBots, _, TIMER_FLAG_NO_MAPCHANGE);
		
		// Recreate the existing timer, to run after the bot cooldown has expired
		CreateTimer(timerDuration, TIMER_CheckAndSwitchFiller, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	
	// Don't switch bots if we're using Modulous Quota
	if (!CheckShutOffBots())
		return Plugin_Handled;
	
	int teamLessPlys = getTeamLessPlayers();
	SwitchBotsToTeam(teamLessPlys);
	return Plugin_Handled;
}

public Action TIMER_CheckAndSwitchEven(Handle timer)
{
	// Recreate the timer, if bots are already in the procress of being switched
	if (isSwitchingBots)
	{
		// Create a cooldown before bots can be switched again, so they don't end up in spectator
		CreateTimer(timerDuration, TIMER_CooldownSwitchingBots, _, TIMER_FLAG_NO_MAPCHANGE);
		
		// Recreate the existing timer, to run after the bot cooldown has expired
		CreateTimer(timerDuration, TIMER_CheckAndSwitchEven, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	
	// Don't switch bots if we're using Modulous Quota
	if (!CheckShutOffBots())
		return Plugin_Handled;
	
	float teamDiff = ND_GetTeamDifference();
	int teamLessSkill = getLeastStackedTeam(teamDiff);
	
	SwitchBotsToTeam(teamLessSkill);
	return Plugin_Handled;
}

public Action TIMER_CooldownSwitchingBots(Handle timer)
{
	isSwitchingBots = false;
	return Plugin_Handled;
}

void SwitchBotsToTeam(int team)
{
	bool switchedBot = false;
	isSwitchingBots = true;
	
	for (int bot = 1; bot < MaxClients; bot++)
	{
		if (IsClientConnected(bot) && IsClientInGame(bot) && IsFakeClient(bot) && GetClientTeam(bot) != team)
		{
			ChangeClientTeam(bot, TEAM_SPEC);
			ChangeClientTeam(bot, team);
			
			// Mark switched bot, and force them to spawn after 8s
			switchedBot = true;
		}
	}
	
	// Create a cooldown before bots can be switched again, so they don't end up in spectator
	CreateTimer(timerDuration, TIMER_CooldownSwitchingBots, _, TIMER_FLAG_NO_MAPCHANGE);
}
