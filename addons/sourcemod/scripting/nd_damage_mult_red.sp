#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_stocks>
#include <nd_research_eng>
#include <nd_entities>
#include <nd_rounds>
#include <nd_print>

public Plugin myinfo =
{
	name 		= "[ND] RED Damage Multiplers",
	author 		= "Stickz",
	description 	= "Creates new damage multiplers for better game balance",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto-Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_damage_mult_red/nd_damage_mult_red.txt"
#include "updater/standard.sp"

float InfantryBoostRedMults[2] = { 1.0, ...};
float InfantryBoostRedCooldown[2] = { 135.0, ... };

int IBRedChargesLeft[MAXPLAYERS+1] = { 3, ... };
int InfantryBoostLevel[2] = { 0, ...};

#include "nd_damage_red/convars.sp"
#include "nd_damage_red/damage_methods.sp"
#include "nd_damage_red/damage_events.sp"
#include "nd_damage_red/damage_hooks.sp"

public void OnPluginStart()
{
	AddUpdaterLibrary(); //auto-updater
	
	CreateRedConVars();
	HookConVarChanges();
	
	LoadTranslations("nd_damage_mult_red.phrases");
	
	// Account for plugin late-loading
	if (ND_RoundStarted())
	{
		HookEntitiesDamaged(true);
		UpdateConVarCache();	
	}
}

public void OnInfantryBoostResearched(int team, int level) 
{
	// Notify team of weapon damage values by displaying in console
	PrintMessageTeam(team, "Weapon Damage Console");
	
	// Get the new values for RED damage percentage and cooldowns
	float percentRed = BaseHelper.RED_InfantryBoostMult(level);
	float cooldownRed = BaseHelper.RED_InfantryBoostCooldown(level);
	
	// Print team red damage increase at each level to console	
	int increaseRed = RoundFloat((percentRed - 1.0) * 100.0);
	int delayRed = RoundFloat(cooldownRed);
	PrintConsoleTeamTI2(team, "RED Damage Increase", increaseRed, delayRed);
	
	// Update IB multiplier for fast lookup purposes
	InfantryBoostRedMults[team-2] = percentRed;	
	InfantryBoostRedCooldown[team-2] = cooldownRed;
	InfantryBoostLevel[team-2] = level;
}

public void ND_OnRoundStarted()
{
	ResetResearchMults();
	HookEntitiesDamaged();
	UpdateConVarCache();
}

public void ND_OnRoundEndedEX() {
	UnHookEntitiesDamaged();
	ResetResearchMults();
}

void ResetResearchMults() 
{
	for (int i = 0; i < 2; i++)
	{
		InfantryBoostRedMults[i] = gFloat_RedMult[red_ib0_base_mult];
		InfantryBoostRedCooldown[i] = gFloat_RedCooldown[red_ib0_base_mult];
		InfantryBoostLevel[i] = 0;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		IBRedChargesLeft[client] = 3;
	}
}

void DecreaseRedCharges(int client, int team)
{
	// If the round is not started, don't decrease the charge count
	if (!ND_RoundStarted())
		return;
	
	// Decrease the number of red charges left by 1
	IBRedChargesLeft[client]--;
	
	// Let the client know the cooldown has started once their charges reach 0
	if (InfantryBoostLevel[team-2] > 0 && IBRedChargesLeft[client] == 0)
		PrintMessage(client, "Red Cooldown Started");	
	
	// Start the cooldown timer to restore the client charges after x number of seconds
	float duration = InfantryBoostRedCooldown[team-2];
	CreateTimer(duration, TIMER_RedChargeCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	
}

public Action TIMER_RedChargeCooldown(Handle timer, any:UserId)
{
	// If the client userid is invalid - exit
	int client = GetClientOfUserId(UserId);
	if (client == INVALID_USERID || !IsValidClient(client))
		return Plugin_Continue;
	
	// If the charge count is 3, the round must have ended - exit
	if (IBRedChargesLeft[client] == 3)
		return Plugin_Continue;
	
	// Restore 1 red charge
	IBRedChargesLeft[client]++;
	
	// The charges left is 3, let the client know the cooldown is complete
	if (IBRedChargesLeft[client] == 3)
	{
		// Only display the message if the team has researched infantry boost
		int team = GetClientTeam(client);
		if (InfantryBoostLevel[team-2] > 0)
			PrintMessage(client, "Red Cooldown Complete");

		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}
